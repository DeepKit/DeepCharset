unit HelperFiles;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, Vcl.Dialogs, Vcl.Controls,
  System.Math, System.StrUtils, System.Generics.Collections, Vcl.Forms, System.TypInfo,
  System.DateUtils, Winapi.Windows,
  UtilsTypes, ModelEncoding, JclBOM, JclEncodingUtils;

type
  TFileFilterFunc = reference to function(const FilePath: string): Boolean;

  // 文件辅助类
  TFileHelper = class
  private
    FLogCallback: TProc<string>;

  public
    constructor Create(ALogCallback: TProc<string>);
    destructor Destroy; override;

    // 获取文件扩展名列表
    function GetFileExtensions(const FolderPath: string): TArray<string>;

    // 获取指定文件夹中的文件
    function GetFilesInFolder(const FolderPath: string;
      const Extensions: TArray<string> = nil; IncludeSubdirs: Boolean = False): TArray<string>;

    // 检测文件编码
    function DetectFileEncoding(const FileName: string; out HasBOM: Boolean): string;

    // 判断文件是否是正常的文本文件
    function IsNormalTextFile(const FileName: string): Boolean;

    // 转换文件编码
    function ConvertFile(const SourceFile, TargetFile: string;
      TargetEncoding: TEncoding; AddBOM: Boolean): Boolean;

    // 批量转换文件
    function BatchConvert(const Files: TArray<string>;
      TargetEncoding: TEncoding; AddBOM: Boolean): Integer;

    // 文件路径处理
    function PathWithSeparator(const Path: string): string;

    // 检查路径是否存在，不存在则创建
    function EnsurePathExists(const Path: string): Boolean;

    // 获取用户文档路径
    function GetMyDocumentsPath: string;

    // 获取应用程序根目录
    function GetRootDir: string;

    function GetSelectedFilesInFolder(const FolderPath: string;
      const Extensions: TStringList;
      const FilterFunc: TFileFilterFunc = nil;
      const IncludeSubDirs: Boolean = False): TArray<string>;
  end;

implementation

uses
  Winapi.ShlObj;

const
  CSIDL_PERSONAL = $0005; // My Documents

  // 添加最大文本文件大小常量 (5MB)
  MAX_TEXT_FILE_SIZE = 5 * 1024 * 1024;
  // 添加二进制检测阈值 (超过5%的字节是二进制则判定为二进制文件)
  BINARY_THRESHOLD = 0.05;
  // 最小有效文本文件大小 (10字节)
  MIN_TEXT_FILE_SIZE = 10;
  // 每次读取的缓冲区大小
  BUFFER_SIZE = 4096;

{ TFileHelper }

constructor TFileHelper.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := ALogCallback;

  if Assigned(FLogCallback) then
    FLogCallback('文件助手已初始化，使用改进的编码检测支持');
end;

destructor TFileHelper.Destroy;
begin
  inherited;
end;

function TFileHelper.BatchConvert(const Files: TArray<string>;
  TargetEncoding: TEncoding; AddBOM: Boolean): Integer;
var
  i: Integer;
begin
  Result := 0;

  if Length(Files) = 0 then
    Exit;

  for i := 0 to High(Files) do
  begin
    if ConvertFile(Files[i], Files[i], TargetEncoding, AddBOM) then
      Inc(Result);
  end;
end;

function TFileHelper.ConvertFile(const SourceFile, TargetFile: string;
  TargetEncoding: TEncoding; AddBOM: Boolean): Boolean;
var
  SourceEncoding: string;
  TargetEncodingName: string;
  HasBOM: Boolean;
  StartTime: TDateTime;
  ElapsedTime: Int64;
begin
  Result := False;
  StartTime := Now;

  try
    // 检查是否为正常文本文件
    if not IsNormalTextFile(SourceFile) then
    begin
      if Assigned(FLogCallback) then
        FLogCallback('跳过非文本文件: ' + SourceFile);
      Exit;
    end;

    // 检测源文件编码
    SourceEncoding := DetectFileEncoding(SourceFile, HasBOM);
    if (SourceEncoding = 'Unknown') or (SourceEncoding = 'Binary') then
    begin
      if Assigned(FLogCallback) then
      begin
        if SourceEncoding = 'Binary' then
          FLogCallback('跳过二进制文件: ' + SourceFile)
        else
          FLogCallback('无法检测文件编码: ' + SourceFile);
      end;
      Exit;
    end;

    // 确定目标编码名称
    TargetEncodingName := 'ANSI'; // 默认为ANSI

    if Assigned(TargetEncoding) then
    begin
      case TargetEncoding.CodePage of
        65001: begin
          if AddBOM then
            TargetEncodingName := 'UTF-8 BOM'
          else
            TargetEncodingName := 'UTF-8';
        end;
        936: TargetEncodingName := 'GBK';
        950: TargetEncodingName := 'Big5';
        1200: TargetEncodingName := 'UTF-16 LE';
        1201: TargetEncodingName := 'UTF-16 BE';
      end;
    end;

    // 使用JclEncodingUtils进行转换
    if JclEncodingUtils.ConvertFileByName(SourceFile, TargetFile, SourceEncoding, TargetEncodingName, AddBOM) then
    begin
      Result := True;
      ElapsedTime := MilliSecondsBetween(StartTime, Now);

      if Assigned(FLogCallback) then
        FLogCallback(Format('成功转换: %s -> %s (耗时: %d ms)',
          [SourceFile, TargetEncodingName, ElapsedTime]));
    end
    else
    begin
      if Assigned(FLogCallback) then
        FLogCallback('编码转换失败');
    end;
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('转换异常: ' + SourceFile + ' - ' + E.Message);
      Result := False;
    end;
  end;
end;

function TFileHelper.DetectFileEncoding(const FileName: string; out HasBOM: Boolean): string;
var
  StartTime: TDateTime;
  ElapsedTime: Int64;
  FileStream: TFileStream;
  Buffer: TBytes;
  BytesRead: Integer;
  FileExt: string;
  BOMType: TJclBOMType;
  IsUTF8, IsGBK, IsBig5: Boolean;
  ChineseCharCount: Integer;
  i: Integer;
  HasHighBit: Boolean;
begin
  StartTime := Now;

  try
    // 首先检查文件是否存在
    if not FileExists(FileName) then
    begin
      if Assigned(FLogCallback) then
        FLogCallback(Format('文件不存在: %s', [FileName]));
      Result := 'Unknown';
      HasBOM := False;
      Exit;
    end;

    // 获取文件扩展名，用于辅助判断
    FileExt := LowerCase(ExtractFileExt(FileName));

    // 跳过已知的二进制文件类型
    if (FileExt = '.exe') or (FileExt = '.dll') or (FileExt = '.obj') or
       (FileExt = '.bin') or (FileExt = '.o') or (FileExt = '.a') or
       (FileExt = '.so') or (FileExt = '.lib') or (FileExt = '.pdb') or
       (FileExt = '.com') or (FileExt = '.sys') or (FileExt = '.ocx') or
       // 图像文件
       (FileExt = '.ico') or (FileExt = '.bmp') or (FileExt = '.jpg') or
       (FileExt = '.jpeg') or (FileExt = '.png') or (FileExt = '.gif') or
       (FileExt = '.tif') or (FileExt = '.tiff') or (FileExt = '.webp') or
       (FileExt = '.svg') or (FileExt = '.psd') or (FileExt = '.ai') or
       // 压缩文件
       (FileExt = '.zip') or (FileExt = '.rar') or (FileExt = '.7z') or (FileExt = '.tar') or
       (FileExt = '.gz') or (FileExt = '.bz2') or (FileExt = '.xz') or (FileExt = '.cab') or
       // 文档文件
       (FileExt = '.pdf') or (FileExt = '.doc') or (FileExt = '.docx') or
       (FileExt = '.xls') or (FileExt = '.xlsx') or (FileExt = '.ppt') or
       (FileExt = '.pptx') or (FileExt = '.odt') or (FileExt = '.ods') or
       // 数据库文件
       (FileExt = '.db') or (FileExt = '.sqlite') or (FileExt = '.mdb') or
       (FileExt = '.accdb') or (FileExt = '.frm') or (FileExt = '.dbf') or
       // 音视频文件
       (FileExt = '.mp3') or (FileExt = '.mp4') or (FileExt = '.avi') or
       (FileExt = '.mov') or (FileExt = '.wmv') or (FileExt = '.flv') or
       (FileExt = '.wav') or (FileExt = '.ogg') or (FileExt = '.flac') or
       // Delphi特有的二进制文件
       (FileExt = '.dcu') or (FileExt = '.bpl') or (FileExt = '.dcp') or
       (FileExt = '.dcpil') or (FileExt = '.dcuil') or (FileExt = '.drc') or
       (FileExt = '.res') or (FileExt = '.rsm') or (FileExt = '.map') or
       (FileExt = '.tds') or (FileExt = '.jdbg') or (FileExt = '.dsk') or
       (FileExt = '.~*') or (FileExt = '.local') or (FileExt = '.identcache') or
       (FileExt = '.stat') or (FileExt = '.otares') or (FileExt = '.deployproj') or
       // 其他常见二进制文件
       (FileExt = '.class') or (FileExt = '.jar') or (FileExt = '.war') or
       (FileExt = '.pyc') or (FileExt = '.pyo') or (FileExt = '.o') or
       (FileExt = '.swf') or (FileExt = '.fla') or (FileExt = '.ttf') or
       (FileExt = '.woff') or (FileExt = '.woff2') or (FileExt = '.eot') then
    begin
      Result := 'Binary';
      HasBOM := False;

      // 记录日志
      ElapsedTime := MilliSecondsBetween(StartTime, Now);
      if Assigned(FLogCallback) then
        FLogCallback(Format('检测到文件 %s 的编码为: %s (二进制文件) (耗时: %d ms)',
          [ExtractFileName(FileName), Result, ElapsedTime]));
      Exit;
    end;

    // 打开文件
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      // 首先检测BOM
      BOMType := JclBOM.DetectBOM(FileStream);

      // 根据BOM返回编码
      case BOMType of
        bomUTF8: Result := 'UTF-8 BOM';
        bomUTF16LE: Result := 'UTF-16 LE';
        bomUTF16BE: Result := 'UTF-16 BE';
        bomUTF32LE: Result := 'UTF-32 LE';
        bomUTF32BE: Result := 'UTF-32 BE';
        else Result := 'Unknown';
      end;

      // 如果有BOM，直接返回结果
      if Result <> 'Unknown' then
      begin
        HasBOM := True;

        // 记录日志
        ElapsedTime := MilliSecondsBetween(StartTime, Now);
        if Assigned(FLogCallback) then
          FLogCallback(Format('检测到文件 %s 的编码为: %s (BOM检测) (耗时: %d ms)',
            [ExtractFileName(FileName), Result, ElapsedTime]));
        Exit;
      end;

      // 无BOM，尝试检测内容
      FileStream.Position := 0;
      var FileSize: Int64 := FileStream.Size;
      var MaxSize: Int64 := 32768; // 增加到32KB以提高准确性
      var ReadSize: Integer;
      if FileSize < MaxSize then
        ReadSize := Integer(FileSize)
      else
        ReadSize := Integer(MaxSize);

      SetLength(Buffer, ReadSize);
      if ReadSize > 0 then
        BytesRead := FileStream.Read(Buffer[0], ReadSize)
      else
        BytesRead := 0;

      // 如果文件为空或者过小，则返回ANSI
      if BytesRead <= 10 then
      begin
        Result := 'ANSI';
        HasBOM := False;

        // 记录日志
        ElapsedTime := MilliSecondsBetween(StartTime, Now);
        if Assigned(FLogCallback) then
          FLogCallback(Format('检测到文件 %s 的编码为: %s (文件过小) (耗时: %d ms)',
            [ExtractFileName(FileName), Result, ElapsedTime]));
        Exit;
      end;

      // 对于特定类型的文件，优先考虑UTF-8
      if (FileExt = '.pas') or (FileExt = '.dpr') or (FileExt = '.dfm') or
         (FileExt = '.cpp') or (FileExt = '.h') or (FileExt = '.hpp') or
         (FileExt = '.cs') or (FileExt = '.java') or (FileExt = '.js') or
         (FileExt = '.ts') or (FileExt = '.py') or (FileExt = '.rb') or
         (FileExt = '.php') or (FileExt = '.html') or (FileExt = '.htm') or
         (FileExt = '.xml') or (FileExt = '.json') or (FileExt = '.css') or
         (FileExt = '.md') or (FileExt = '.txt') or (FileExt = '.ini') then
      begin
        // 对于常见的源代码文件，几乎可以确定是UTF-8
        if (FileExt = '.pas') or (FileExt = '.dpr') or (FileExt = '.dfm') then
        begin
          Result := 'UTF-8';
          HasBOM := False;

          // 记录日志
          ElapsedTime := MilliSecondsBetween(StartTime, Now);
          if Assigned(FLogCallback) then
            FLogCallback(Format('检测到文件 %s 的编码为: %s (Delphi源码文件) (耗时: %d ms)',
              [ExtractFileName(FileName), Result, ElapsedTime]));
          Exit;
        end
        // 其他常见编程语言源代码文件
        else if (FileExt = '.cs') or (FileExt = '.java') or (FileExt = '.js') or
                (FileExt = '.ts') or (FileExt = '.py') or (FileExt = '.rb') or
                (FileExt = '.php') or (FileExt = '.go') or (FileExt = '.swift') or
                (FileExt = '.kt') or (FileExt = '.scala') or (FileExt = '.rs') or
                (FileExt = '.c') or (FileExt = '.cpp') or (FileExt = '.h') or
                (FileExt = '.hpp') or (FileExt = '.m') or (FileExt = '.mm') then
        begin
          Result := 'UTF-8';
          HasBOM := False;

          // 记录日志
          ElapsedTime := MilliSecondsBetween(StartTime, Now);
          if Assigned(FLogCallback) then
            FLogCallback(Format('检测到文件 %s 的编码为: %s (编程语言源码文件) (耗时: %d ms)',
              [ExtractFileName(FileName), Result, ElapsedTime]));
          Exit;
        end
        // Web相关文件
        else if (FileExt = '.html') or (FileExt = '.htm') or (FileExt = '.css') or
                (FileExt = '.xml') or (FileExt = '.json') or (FileExt = '.svg') or
                (FileExt = '.jsx') or (FileExt = '.tsx') or (FileExt = '.vue') or
                (FileExt = '.less') or (FileExt = '.scss') or (FileExt = '.sass') or
                (FileExt = '.yaml') or (FileExt = '.yml') then
        begin
          Result := 'UTF-8';
          HasBOM := False;

          // 记录日志
          ElapsedTime := MilliSecondsBetween(StartTime, Now);
          if Assigned(FLogCallback) then
            FLogCallback(Format('检测到文件 %s 的编码为: %s (Web相关文件) (耗时: %d ms)',
              [ExtractFileName(FileName), Result, ElapsedTime]));
          Exit;
        end
        // 配置文件
        else if (FileExt = '.ini') or (FileExt = '.conf') or (FileExt = '.config') or
                (FileExt = '.properties') or (FileExt = '.toml') or (FileExt = '.env') or
                (FileExt = '.cfg') or (FileExt = '.rc') or (FileExt = '.reg') then
        begin
          Result := 'UTF-8';
          HasBOM := False;

          // 记录日志
          ElapsedTime := MilliSecondsBetween(StartTime, Now);
          if Assigned(FLogCallback) then
            FLogCallback(Format('检测到文件 %s 的编码为: %s (配置文件) (耗时: %d ms)',
              [ExtractFileName(FileName), Result, ElapsedTime]));
          Exit;
        end
        // 纯文本文件
        else if (FileExt = '.txt') or (FileExt = '.log') or (FileExt = '.csv') or
                (FileExt = '.tsv') or (FileExt = '.md') or (FileExt = '.rst') or
                (FileExt = '.adoc') or (FileExt = '.asc') or (FileExt = '.text') then
        begin
          Result := 'UTF-8';
          HasBOM := False;

          // 记录日志
          ElapsedTime := MilliSecondsBetween(StartTime, Now);
          if Assigned(FLogCallback) then
            FLogCallback(Format('检测到文件 %s 的编码为: %s (纯文本文件) (耗时: %d ms)',
              [ExtractFileName(FileName), Result, ElapsedTime]));
          Exit;
        end;

        // 检查是否是有效的UTF-8
        IsUTF8 := JclEncodingUtils.IsUTF8Valid(Buffer, BytesRead);

        // 如果是有效的UTF-8，直接返回
        if IsUTF8 then
        begin
          Result := 'UTF-8';
          HasBOM := False;

          // 记录日志
          ElapsedTime := MilliSecondsBetween(StartTime, Now);
          if Assigned(FLogCallback) then
            FLogCallback(Format('检测到文件 %s 的编码为: %s (文件类型优先) (耗时: %d ms)',
              [ExtractFileName(FileName), Result, ElapsedTime]));
          Exit;
        end;
      end;

      // 检查是否有非ASCII字符
      HasHighBit := False;
      for i := 0 to BytesRead - 1 do
      begin
        if Buffer[i] > $7F then
        begin
          HasHighBit := True;
          Break;
        end;
      end;

      // 如果全是ASCII字符，则返回UTF-8（因为ASCII是UTF-8的子集）
      if not HasHighBit then
      begin
        Result := 'UTF-8';
        HasBOM := False;

        // 记录日志
        ElapsedTime := MilliSecondsBetween(StartTime, Now);
        if Assigned(FLogCallback) then
          FLogCallback(Format('检测到文件 %s 的编码为: %s (纯ASCII) (耗时: %d ms)',
            [ExtractFileName(FileName), Result, ElapsedTime]));
        Exit;
      end;

      // 检测是否为UTF-8
      IsUTF8 := JclEncodingUtils.IsUTF8Valid(Buffer, BytesRead);

      // 检测是否为GBK
      IsGBK := JclEncodingUtils.IsGBKString(Buffer, BytesRead);

      // 检测是否为Big5
      IsBig5 := JclEncodingUtils.IsBig5String(Buffer, BytesRead);

      // 检测是否为日文编码（Shift-JIS）
      var IsShiftJIS := False;
      if BytesRead > 20 then
      begin
        // 简单检测：如果文件中包含日文特有的字符范围，可能是Shift-JIS
        for i := 0 to BytesRead - 2 do
        begin
          if (i + 1 < BytesRead) and
             (((Buffer[i] >= $81) and (Buffer[i] <= $9F)) or
              ((Buffer[i] >= $E0) and (Buffer[i] <= $FC))) and
             (((Buffer[i+1] >= $40) and (Buffer[i+1] <= $7E)) or
              ((Buffer[i+1] >= $80) and (Buffer[i+1] <= $FC))) then
          begin
            IsShiftJIS := True;
            Break;
          end;
        end;
      end;

      // 检测是否为韩文编码（EUC-KR）
      var IsEUCKR := False;
      if BytesRead > 20 then
      begin
        // 简单检测：如果文件中包含韩文特有的字符范围，可能是EUC-KR
        for i := 0 to BytesRead - 2 do
        begin
          if (i + 1 < BytesRead) and
             (Buffer[i] >= $B0) and (Buffer[i] <= $C8) and
             (Buffer[i+1] >= $A1) and (Buffer[i+1] <= $FE) then
          begin
            IsEUCKR := True;
            Break;
          end;
        end;
      end;

      // 如果只有UTF-8有效，则返回UTF-8
      if IsUTF8 and not IsGBK and not IsBig5 then
      begin
        Result := 'UTF-8';
        HasBOM := False;

        // 记录日志
        ElapsedTime := MilliSecondsBetween(StartTime, Now);
        if Assigned(FLogCallback) then
          FLogCallback(Format('检测到文件 %s 的编码为: %s (仅UTF-8有效) (耗时: %d ms)',
            [ExtractFileName(FileName), Result, ElapsedTime]));
        Exit;
      end;

      // 如果只有GBK有效，则返回GBK
      if IsGBK and not IsUTF8 and not IsBig5 then
      begin
        Result := 'GBK';
        HasBOM := False;

        // 记录日志
        ElapsedTime := MilliSecondsBetween(StartTime, Now);
        if Assigned(FLogCallback) then
          FLogCallback(Format('检测到文件 %s 的编码为: %s (仅GBK有效) (耗时: %d ms)',
            [ExtractFileName(FileName), Result, ElapsedTime]));
        Exit;
      end;

      // 如果只有Big5有效，则返回Big5
      if IsBig5 and not IsUTF8 and not IsGBK then
      begin
        Result := 'Big5';
        HasBOM := False;

        // 记录日志
        ElapsedTime := MilliSecondsBetween(StartTime, Now);
        if Assigned(FLogCallback) then
          FLogCallback(Format('检测到文件 %s 的编码为: %s (仅Big5有效) (耗时: %d ms)',
            [ExtractFileName(FileName), Result, ElapsedTime]));
        Exit;
      end;

      // 如果检测到Shift-JIS编码
      if IsShiftJIS and not IsUTF8 then
      begin
        Result := 'Shift-JIS';
        HasBOM := False;

        // 记录日志
        ElapsedTime := MilliSecondsBetween(StartTime, Now);
        if Assigned(FLogCallback) then
          FLogCallback(Format('检测到文件 %s 的编码为: %s (日文编码) (耗时: %d ms)',
            [ExtractFileName(FileName), Result, ElapsedTime]));
        Exit;
      end;

      // 如果检测到EUC-KR编码
      if IsEUCKR and not IsUTF8 then
      begin
        Result := 'EUC-KR';
        HasBOM := False;

        // 记录日志
        ElapsedTime := MilliSecondsBetween(StartTime, Now);
        if Assigned(FLogCallback) then
          FLogCallback(Format('检测到文件 %s 的编码为: %s (韩文编码) (耗时: %d ms)',
            [ExtractFileName(FileName), Result, ElapsedTime]));
        Exit;
      end;

      // 如果UTF-8和GBK都有效，需要进一步判断
      if IsUTF8 and IsGBK then
      begin
        // 检查文件名中的语言特征
        var FileName_NoPath := ExtractFileName(FileName);
        var HasNonASCII := False;
        var SystemLangID := GetSystemDefaultLangID;

        // 检查文件名是否包含非ASCII字符
        for i := 1 to Length(FileName_NoPath) do
        begin
          if Ord(FileName_NoPath[i]) > 127 then
          begin
            HasNonASCII := True;
            Break;
          end;
        end;

        // 如果文件名包含非ASCII字符，根据系统语言环境判断
        if HasNonASCII then
        begin
          // 中文系统
          if (SystemLangID = $0804) or // 简体中文
             (SystemLangID = $0404) or // 繁体中文
             (SystemLangID = $0c04) then // 香港中文
          begin
            // 如果文件名中包含中文特征（如"汉字"、"中文"等）
            if (Pos('汉字', FileName_NoPath) > 0) or
               (Pos('中文', FileName_NoPath) > 0) or
               (Pos('简体', FileName_NoPath) > 0) or
               (Pos('繁体', FileName_NoPath) > 0) or
               (Pos('中国', FileName_NoPath) > 0) then
            begin
              Result := 'GBK';
              HasBOM := False;

              // 记录日志
              ElapsedTime := MilliSecondsBetween(StartTime, Now);
              if Assigned(FLogCallback) then
                FLogCallback(Format('检测到文件 %s 的编码为: %s (中文文件名) (耗时: %d ms)',
                  [ExtractFileName(FileName), Result, ElapsedTime]));
              Exit;
            end;
          end
          // 日文系统
          else if (SystemLangID = $0411) then // 日文
          begin
            // 如果文件名中包含日文特征（如"日本語"等）
            if (Pos('日本', FileName_NoPath) > 0) or
               (Pos('にほん', FileName_NoPath) > 0) or
               (Pos('ニホン', FileName_NoPath) > 0) then
            begin
              Result := 'Shift-JIS';
              HasBOM := False;

              // 记录日志
              ElapsedTime := MilliSecondsBetween(StartTime, Now);
              if Assigned(FLogCallback) then
                FLogCallback(Format('检测到文件 %s 的编码为: %s (日文文件名) (耗时: %d ms)',
                  [ExtractFileName(FileName), Result, ElapsedTime]));
              Exit;
            end;
          end
          // 韩文系统
          else if (SystemLangID = $0412) then // 韩文
          begin
            // 如果文件名中包含韩文特征（如"한국어"等）
            if (Pos('한국', FileName_NoPath) > 0) or
               (Pos('조선', FileName_NoPath) > 0) then
            begin
              Result := 'EUC-KR';
              HasBOM := False;

              // 记录日志
              ElapsedTime := MilliSecondsBetween(StartTime, Now);
              if Assigned(FLogCallback) then
                FLogCallback(Format('检测到文件 %s 的编码为: %s (韩文文件名) (耗时: %d ms)',
                  [ExtractFileName(FileName), Result, ElapsedTime]));
              Exit;
            end;
          end;
        end;

        // 检查中文字符
        ChineseCharCount := 0;
        for i := 0 to BytesRead - 3 do
        begin
          // 检测是否是中文字符的UTF-8编码模式
          if (Buffer[i] >= $E4) and (Buffer[i] <= $E9) and
             (i + 1 < BytesRead) and ((Buffer[i+1] and $C0) = $80) and
             (i + 2 < BytesRead) and ((Buffer[i+2] and $C0) = $80) then
          begin
            Inc(ChineseCharCount);
            if ChineseCharCount >= 3 then
              Break;
          end;
        end;

        // 如果有足够多的中文字符，优先考虑UTF-8
        if ChineseCharCount >= 3 then
        begin
          Result := 'UTF-8';
          HasBOM := False;

          // 记录日志
          ElapsedTime := MilliSecondsBetween(StartTime, Now);
          if Assigned(FLogCallback) then
            FLogCallback(Format('检测到文件 %s 的编码为: %s (中文字符判断) (耗时: %d ms)',
              [ExtractFileName(FileName), Result, ElapsedTime]));
          Exit;
        end;

        // 对于特定类型的文件，优先考虑UTF-8
        if (FileExt = '.pas') or (FileExt = '.dpr') or (FileExt = '.dfm') or
           (FileExt = '.cpp') or (FileExt = '.h') or (FileExt = '.hpp') or
           (FileExt = '.cs') or (FileExt = '.java') or (FileExt = '.js') or
           (FileExt = '.ts') or (FileExt = '.py') or (FileExt = '.rb') or
           (FileExt = '.php') or (FileExt = '.html') or (FileExt = '.htm') or
           (FileExt = '.xml') or (FileExt = '.json') or (FileExt = '.css') or
           (FileExt = '.md') or (FileExt = '.txt') or (FileExt = '.ini') then
        begin
          Result := 'UTF-8';
          HasBOM := False;

          // 记录日志
          ElapsedTime := MilliSecondsBetween(StartTime, Now);
          if Assigned(FLogCallback) then
            FLogCallback(Format('检测到文件 %s 的编码为: %s (文件类型优先) (耗时: %d ms)',
              [ExtractFileName(FileName), Result, ElapsedTime]));
          Exit;
        end;

        // 根据系统语言环境决定
        var SystemLangID2 := GetSystemDefaultLangID;
        if (SystemLangID2 = $0804) or // 简体中文
           (SystemLangID2 = $0404) or // 繁体中文
           (SystemLangID2 = $0c04) then // 香港中文
        begin
          Result := 'GBK';
          HasBOM := False;
        end
        else
        begin
          Result := 'UTF-8';
          HasBOM := False;
        end;

        // 记录日志
        ElapsedTime := MilliSecondsBetween(StartTime, Now);
        if Assigned(FLogCallback) then
          FLogCallback(Format('检测到文件 %s 的编码为: %s (系统语言判断) (耗时: %d ms)',
            [ExtractFileName(FileName), Result, ElapsedTime]));
        Exit;
      end;

      // 如果所有检测都无效，则返回系统默认编码
      Result := 'ANSI';
      HasBOM := False;

      // 记录日志
      ElapsedTime := MilliSecondsBetween(StartTime, Now);
      if Assigned(FLogCallback) then
        FLogCallback(Format('检测到文件 %s 的编码为: %s (默认) (耗时: %d ms)',
          [ExtractFileName(FileName), Result, ElapsedTime]));
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      // 如果检测失败，使用默认值
      Result := 'ANSI';
      HasBOM := False;

      // 记录错误
      if Assigned(FLogCallback) then
        FLogCallback(Format('检测文件编码失败: %s - %s', [FileName, E.Message]));
    end;
  end;
end;

function TFileHelper.EnsurePathExists(const Path: string): Boolean;
begin
  Result := True;

  if not DirectoryExists(Path) then
  begin
    try
      Result := ForceDirectories(Path);

      if Result and Assigned(FLogCallback) then
        FLogCallback('创建目录: ' + Path);
    except
      on E: Exception do
      begin
        if Assigned(FLogCallback) then
          FLogCallback('创建目录失败: ' + Path + ' - ' + E.Message);
        Result := False;
      end;
    end;
  end;
end;

function TFileHelper.GetFileExtensions(const FolderPath: string): TArray<string>;
var
  Files: TArray<string>;
  Extensions: TStringList;
  i: Integer;
  Ext: string;
  SafePath: string;
begin
  // 初始化返回值为空数组
  SetLength(Result, 0);

  // 安全检查：确保参数有效
  if FolderPath = '' then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('错误: 提供的目录路径为空');
    Exit;
  end;

  // 规范化路径
  try
    SafePath := ExcludeTrailingPathDelimiter(FolderPath);
    SafePath := IncludeTrailingPathDelimiter(SafePath);
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('路径格式化错误: ' + E.Message);
      Exit;
    end;
  end;

  // 创建扩展名列表
  Extensions := TStringList.Create;
  try
    Extensions.Sorted := True;
    Extensions.Duplicates := TDuplicates.dupIgnore;

    // 安全检查：确保目录存在
    if not DirectoryExists(SafePath) then
    begin
      if Assigned(FLogCallback) then
        FLogCallback('目录不存在: ' + SafePath);
      Exit;
    end;

    try
      // 仅搜索当前目录，不再使用soAllDirectories
      try
        Files := TDirectory.GetFiles(SafePath, '*.*', TSearchOption.soTopDirectoryOnly);
      except
        on E: Exception do
        begin
          if Assigned(FLogCallback) then
            FLogCallback('获取文件列表出错: ' + E.Message);
          Exit;
        end;
      end;

      if Assigned(FLogCallback) then
        FLogCallback('找到 ' + IntToStr(Length(Files)) + ' 个文件，正在提取扩展名');

      // 安全检查：确保文件列表有效
      if Length(Files) = 0 then
      begin
        if Assigned(FLogCallback) then
          FLogCallback('目录中没有文件');
        Exit;
      end;

      // 提取扩展名
      for i := 0 to High(Files) do
      begin
        try
          Ext := ExtractFileExt(Files[i]);
          if Ext <> '' then
            Extensions.Add(Ext);
        except
          on E: Exception do
          begin
            if Assigned(FLogCallback) then
              FLogCallback('处理文件扩展名出错: ' + Files[i] + ' - ' + E.Message);
            // 继续处理下一个文件
            Continue;
          end;
        end;
      end;

      // 安全检查：确保找到了扩展名
      if Extensions.Count = 0 then
      begin
        if Assigned(FLogCallback) then
          FLogCallback('未找到任何文件扩展名');
        Exit;
      end;

      // 转换为数组
      try
        SetLength(Result, Extensions.Count);
        for i := 0 to Extensions.Count - 1 do
          Result[i] := Extensions[i];

        if Assigned(FLogCallback) then
          FLogCallback('成功获取 ' + IntToStr(Extensions.Count) + ' 个不同的文件扩展名');
      except
        on E: Exception do
        begin
          if Assigned(FLogCallback) then
            FLogCallback('转换扩展名列表为数组时出错: ' + E.Message);
          SetLength(Result, 0);
        end;
      end;
    except
      on E: Exception do
      begin
        if Assigned(FLogCallback) then
          FLogCallback('获取文件扩展名出错: ' + E.Message);
        SetLength(Result, 0);
      end;
    end;
  finally
    // 确保释放资源
    if Assigned(Extensions) then
      Extensions.Free;
  end;
end;

function TFileHelper.GetFilesInFolder(const FolderPath: string;
  const Extensions: TArray<string> = nil; IncludeSubdirs: Boolean = False): TArray<string>;
var
  Files: TArray<string>;
  FilteredFiles: TList<string>;
  i, j: Integer;
  Ext: string;
  IsMatch: Boolean;
  SearchOption: TSearchOption;
begin
  if not DirectoryExists(FolderPath) then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  // 根据参数决定是否搜索子目录
  if IncludeSubdirs then
    SearchOption := TSearchOption.soAllDirectories
  else
    SearchOption := TSearchOption.soTopDirectoryOnly;

  if Assigned(FLogCallback) then
    FLogCallback('开始搜索文件: ' + FolderPath +
                 ', 包含子目录: ' + BoolToStr(IncludeSubdirs, True) +
                 ', 扩展名: ' + Integer(Length(Extensions)).ToString + '个');

  FilteredFiles := TList<string>.Create;
  try
    // 使用SearchOption参数来控制是否搜索子目录
    Files := TDirectory.GetFiles(FolderPath, '*.*', SearchOption);

    if Assigned(FLogCallback) then
      FLogCallback('找到' + Integer(Length(Files)).ToString + '个文件');

    for i := 0 to High(Files) do
    begin
      if Length(Extensions) = 0 then
      begin
        FilteredFiles.Add(Files[i]);
      end
      else
      begin
        Ext := ExtractFileExt(Files[i]);
        IsMatch := False;

        for j := 0 to High(Extensions) do
        begin
          if SameText(Ext, Extensions[j]) then
          begin
            IsMatch := True;
            Break;
          end;
        end;

        if IsMatch then
          FilteredFiles.Add(Files[i]);
      end;
    end;

    SetLength(Result, FilteredFiles.Count);
    for i := 0 to FilteredFiles.Count - 1 do
      Result[i] := FilteredFiles[i];

    if Assigned(FLogCallback) then
      FLogCallback('筛选后有' + Integer(Length(Result)).ToString + '个符合条件的文件');

  finally
    FilteredFiles.Free;
  end;
end;

function TFileHelper.GetMyDocumentsPath: string;
var
  SpecialPath: array[0..MAX_PATH] of Char;
begin
  if SHGetFolderPath(0, CSIDL_PERSONAL, 0, 0, SpecialPath) = S_OK then
    Result := StrPas(SpecialPath)
  else
    Result := '';
end;

function TFileHelper.IsNormalTextFile(const FileName: string): Boolean;
var
  FileStream: TFileStream;
  Buffer: array of Byte;
  BytesRead, i, BinaryCount: Integer;
  FileSize: Int64;
  BinaryRatio: Double;
  Ext: string;
begin
  Result := False;

  // 检查文件是否存在
  if not FileExists(FileName) then
    Exit;

  // 获取文件扩展名
  Ext := LowerCase(ExtractFileExt(FileName));

  // 跳过已知的二进制文件类型
  if (Ext = '.exe') or (Ext = '.dll') or (Ext = '.obj') or
     (Ext = '.bin') or (Ext = '.o') or (Ext = '.a') or
     (Ext = '.so') or (Ext = '.lib') or (Ext = '.pdb') or
     (Ext = '.com') or (Ext = '.sys') or (Ext = '.ocx') or
     // 图像文件
     (Ext = '.ico') or (Ext = '.bmp') or (Ext = '.jpg') or
     (Ext = '.jpeg') or (Ext = '.png') or (Ext = '.gif') or
     (Ext = '.tif') or (Ext = '.tiff') or (Ext = '.webp') or
     (Ext = '.svg') or (Ext = '.psd') or (Ext = '.ai') or
     // 压缩文件
     (Ext = '.zip') or (Ext = '.rar') or (Ext = '.7z') or (Ext = '.tar') or
     (Ext = '.gz') or (Ext = '.bz2') or (Ext = '.xz') or (Ext = '.cab') or
     // 文档文件
     (Ext = '.pdf') or (Ext = '.doc') or (Ext = '.docx') or
     (Ext = '.xls') or (Ext = '.xlsx') or (Ext = '.ppt') or
     (Ext = '.pptx') or (Ext = '.odt') or (Ext = '.ods') or
     // 数据库文件
     (Ext = '.db') or (Ext = '.sqlite') or (Ext = '.mdb') or
     (Ext = '.accdb') or (Ext = '.frm') or (Ext = '.dbf') or
     // 音视频文件
     (Ext = '.mp3') or (Ext = '.mp4') or (Ext = '.avi') or
     (Ext = '.mov') or (Ext = '.wmv') or (Ext = '.flv') or
     (Ext = '.wav') or (Ext = '.ogg') or (Ext = '.flac') or
     // Delphi特有的二进制文件
     (Ext = '.dcu') or (Ext = '.bpl') or (Ext = '.dcp') or
     (Ext = '.dcpil') or (Ext = '.dcuil') or (Ext = '.drc') or
     (Ext = '.res') or (Ext = '.rsm') or (Ext = '.map') or
     (Ext = '.tds') or (Ext = '.jdbg') or (Ext = '.dsk') or
     (Ext = '.~*') or (Ext = '.local') or (Ext = '.identcache') or
     (Ext = '.stat') or (Ext = '.otares') or (Ext = '.deployproj') or
     // 其他常见二进制文件
     (Ext = '.class') or (Ext = '.jar') or (Ext = '.war') or
     (Ext = '.pyc') or (Ext = '.pyo') or (Ext = '.o') or
     (Ext = '.swf') or (Ext = '.fla') or (Ext = '.ttf') or
     (Ext = '.woff') or (Ext = '.woff2') or (Ext = '.eot') then
    Exit;

  try
    // 打开文件
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      // 获取文件大小
      FileSize := FileStream.Size;

      // 文件太大或太小，不是正常文本文件
      if (FileSize > MAX_TEXT_FILE_SIZE) or (FileSize < MIN_TEXT_FILE_SIZE) then
        Exit;

      // 分配缓冲区
      SetLength(Buffer, BUFFER_SIZE);

      // 初始化计数器
      BinaryCount := 0;

      // 检查前4KB数据
      BytesRead := FileStream.Read(Buffer[0], BUFFER_SIZE);

      // 检查每个字节是否为二进制数据
      for i := 0 to BytesRead - 1 do
      begin
        // ASCII控制字符(除了制表符、换行和回车)通常不会出现在文本文件中
        if (Buffer[i] < 9) or ((Buffer[i] > 13) and (Buffer[i] < 32)) then
          Inc(BinaryCount);
      end;

      // 计算二进制字节占比
      if BytesRead > 0 then
        BinaryRatio := BinaryCount / BytesRead
      else
        BinaryRatio := 0;

      // 如果二进制字节比例高于阈值，认为是二进制文件
      Result := BinaryRatio <= BINARY_THRESHOLD;

      // 记录分析结果
      if Assigned(FLogCallback) and not Result then
        FLogCallback('跳过非文本文件: ' + FileName + ' (二进制比例: ' +
                     FormatFloat('0.00%', BinaryRatio * 100) + ')');

    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      // 如果无法读取文件，认为它不是正常文本文件
      if Assigned(FLogCallback) then
        FLogCallback('无法分析文件: ' + FileName + ' - ' + E.Message);
      Result := False;
    end;
  end;
end;

function TFileHelper.PathWithSeparator(const Path: string): string;
begin
  Result := IncludeTrailingPathDelimiter(Path);
end;

function TFileHelper.GetRootDir: string;
var
  ExeDir, ParentDir, GrandParentDir: string;
  IniDirPath: string;
begin
  // 1. 取得执行文件目录
  ExeDir := ExtractFilePath(Application.ExeName);
  ExeDir := ExcludeTrailingPathDelimiter(ExeDir);

  // 2. 回退两级
  ParentDir := ExtractFilePath(ExcludeTrailingPathDelimiter(ExeDir));
  ParentDir := ExcludeTrailingPathDelimiter(ParentDir);

  GrandParentDir := ExtractFilePath(ExcludeTrailingPathDelimiter(ParentDir));
  GrandParentDir := ExcludeTrailingPathDelimiter(GrandParentDir);

  // 3. 若找到子目录 .\ini
  IniDirPath := GrandParentDir + '\ini';

  if DirectoryExists(IniDirPath) then
  begin
    Result := GrandParentDir;
    if Assigned(FLogCallback) then
      FLogCallback('找到根目录: ' + Result);
  end
  else
  begin
    // 如果没有找到ini目录，则使用当前目录
    Result := ExeDir;
    if Assigned(FLogCallback) then
      FLogCallback('未找到ini目录，使用当前目录作为根目录: ' + Result);
  end;
end;

function TFileHelper.GetSelectedFilesInFolder(const FolderPath: string;
  const Extensions: TStringList; const FilterFunc: TFileFilterFunc = nil;
  const IncludeSubDirs: Boolean = False): TArray<string>;
var
  SearchOption: TSearchOption;
  Files: TArray<string>;
  i: Integer;
  FileList: TList<string>;
begin
  FileList := TList<string>.Create;
  try
    if IncludeSubDirs then
      SearchOption := TSearchOption.soAllDirectories
    else
      SearchOption := TSearchOption.soTopDirectoryOnly;

    // 获取所有文件
    Files := TDirectory.GetFiles(FolderPath, '*.*', SearchOption);

    // 过滤文件
    for i := 0 to High(Files) do
    begin
      if (Extensions.IndexOf(ExtractFileExt(Files[i])) >= 0) and
         ((not Assigned(FilterFunc)) or FilterFunc(Files[i])) then
      begin
        FileList.Add(Files[i]);
      end;
    end;

    Result := FileList.ToArray;
  finally
    FileList.Free;
  end;
end;

end.
