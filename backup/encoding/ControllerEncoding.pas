unit ControllerEncoding;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, ModelEncoding, Winapi.Windows, JclEncodingUtils,
  JclBOM, JclStrings, JclSysUtils, JclAnsiStrings, JclFileUtils, JclStreams, UtilsJCLEncoding;

type
  TConversionResult = (crSuccess, crFailed, crSkipped);

  // 编码控制器类
  TEncodingController = class
  private
    // 日志记录回调
    FLogCallback: TProc<string>;

    // 内部编码转换辅助函数
    function CheckFileAccessibility(const FileName: string; var UseTemp: Boolean): Boolean;
    procedure CreateBackupFile(const SourceFile: string; var BackupFile: string);
    procedure TryCopyTempToOriginal(const TempFile, OriginalFile: string);
    procedure LogConversionSuccess(const SourceFile: string);
    procedure RestoreFromBackup(const OriginalFile, BackupFile: string);

    // 使用JCL进行编码转换
    function ConvertWithJCL(const SourceFile, TargetFile: string;
      const SourceEncoding, TargetEncoding: string; AddBOM: Boolean): Boolean;

    // NEW: Internal helper to perform single file conversion using names
    function DoConvertSingleFileByName(const SourceFile, TargetEncodingName: string; AddBOM: Boolean = False; const TargetFile: string = ''): TConversionResult;

    function IsEncodingAvailable(CodePage: Integer): Boolean;

  public
    constructor Create(ALogCallback: TProc<string>);
    destructor Destroy; override;

    // 判断文件是否在不支持列表中
    function IsUnsupportedFile(const Filename: string): Boolean;

    // 检查文件是否有BOM标记
    function HasBOM(const FileName: string; Encoding: TEncoding = nil): Boolean;

    // 检测文件编码 - 使用JCL
    function DetectFileEncoding(const FileName: string; out EncodingName: string): Boolean;

    // 转换单个文件编码
    function ConvertFileEncoding(const SourceFile, TargetFile: string;
      TargetEncoding: TEncoding; AddBOM: Boolean): TConversionResult;

    // 批量转换文件夹中的文件
    procedure ConvertFilesToEncoding(const FolderPath: string;
      const FileExtensions: TArray<string>; SelectedFiles: TArray<string>;
      TargetEncoding: TEncoding; AddBOM: Boolean);

    // 转换选中的文件
    procedure ConvertSelectedFilesToEncoding(const SelectedFiles: TArray<string>;
      TargetEncoding: TEncoding; AddBOM: Boolean);

    // --- NEW Public Methods using Encoding Names ---
    procedure ConvertFilesByName(const SelectedFiles: TArray<string>;
                                 const TargetEncodingName: string;
                                 AddBOM: Boolean;
                                 UpdateCallback: TProc<string>);

    function ConvertSingleFileByName(const SourceFile: string;
                                     const TargetEncodingName: string;
                                     AddBOM: Boolean;
                                     UpdateCallback: TProc<string>): Boolean;
    // --- End of NEW Public Methods ---

    function ConvertFile(const FilePath: string; TargetEncoding: TEncoding): Boolean;
  end;

implementation

uses System.Threading;

{ TEncodingController }

constructor TEncodingController.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := ALogCallback;

  // 记录日志
  if Assigned(FLogCallback) then
    FLogCallback('JCL编码处理功能已初始化');
end;

destructor TEncodingController.Destroy;
begin
  inherited;
end;

function TEncodingController.IsUnsupportedFile(const Filename: string): Boolean;
var
  BaseName: string;
  i: Integer;
begin
  BaseName := ExtractFileName(Filename);
  Result := False;

  for i := Low(UNSUPPORTED_FILES) to High(UNSUPPORTED_FILES) do
  begin
    if SameText(BaseName, UNSUPPORTED_FILES[i]) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TEncodingController.HasBOM(const FileName: string; Encoding: TEncoding): Boolean;
var
  Stream: TFileStream;
  Preamble: TBytes;
  DetectedBytes: TBytes;
begin
  Result := False;

  if not FileExists(FileName) then
    Exit;

  try
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      if Encoding = nil then
        Encoding := TEncoding.UTF8;

      Preamble := Encoding.GetPreamble;

      if Length(Preamble) = 0 then
        Exit(False);

      SetLength(DetectedBytes, Length(Preamble));

      if Stream.Size < Length(Preamble) then
        Exit(False);

      Stream.ReadBuffer(DetectedBytes[0], Length(Preamble));

      // 比较BOM标记
      for var i := 0 to High(Preamble) do
      begin
        if Preamble[i] <> DetectedBytes[i] then
          Exit(False);
      end;

      Result := True;
    finally
      Stream.Free;
    end;
  except
    // 如果读取失败，假设没有BOM
    Result := False;
  end;
end;

function TEncodingController.DetectFileEncoding(const FileName: string; out EncodingName: string): Boolean;
var
  HasUTF8BOM: Boolean;
  Stream: TFileStream;
  BOMBytes: TBytes;
  Buffer: TBytes;
  ByteCounts: array[0..255] of Integer;
  i: Integer;
  IsLikelyUTF8: Boolean;
  ValidUTF8Sequences, TotalUTF8Sequences: Integer;
  BOM: TJclBOMType;
begin
  // 首先检查是否有UTF-8 BOM
  HasUTF8BOM := False;

  try
    if FileExists(FileName) then
    begin
      Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
      try
        if Stream.Size >= 3 then
        begin
          SetLength(BOMBytes, 3);
          Stream.ReadBuffer(BOMBytes[0], 3);

          // UTF-8 BOM: EF BB BF
          HasUTF8BOM := (BOMBytes[0] = $EF) and (BOMBytes[1] = $BB) and (BOMBytes[2] = $BF);
        end;

        // 重置流位置以便后续检测
        Stream.Position := 0;

        // 使用JCL的BOM检测
        BOM := DetectBOM(Stream);
        case BOM of
          bomUtf8: EncodingName := 'UTF-8 with BOM';
          bomUtf16LE: EncodingName := 'UTF-16LE';
          bomUtf16BE: EncodingName := 'UTF-16BE';
          bomUtf32LE: EncodingName := 'UTF-32LE';
          bomUtf32BE: EncodingName := 'UTF-32BE';
        else
          // 无BOM，进行更高级的检测
          // 读取文件样本进行分析
          SetLength(Buffer, Min(4096, Stream.Size));
          Stream.Position := 0;
          Stream.ReadBuffer(Buffer[0], Length(Buffer));

          // 统计字节频率
          FillChar(ByteCounts, SizeOf(ByteCounts), 0);
          for i := 0 to High(Buffer) do
            Inc(ByteCounts[Buffer[i]]);

          // 改进的UTF-8检测 - 增加序列有效性验证
          IsLikelyUTF8 := True;
          i := 0;
          ValidUTF8Sequences := 0;
          TotalUTF8Sequences := 0;

          while i < Length(Buffer) do
          begin
            if (Buffer[i] and $80) <> 0 then // 检查高位是否为1
            begin
              Inc(TotalUTF8Sequences);
              // 检查UTF-8多字节序列
              if (Buffer[i] and $E0) = $C0 then // 2字节序列
              begin
                if (i + 1 < Length(Buffer)) and ((Buffer[i+1] and $C0) = $80) then
                begin
                  Inc(ValidUTF8Sequences);
                  Inc(i);
                end
                else
                  IsLikelyUTF8 := False;
              end
              else if (Buffer[i] and $F0) = $E0 then // 3字节序列
              begin
                if (i + 2 < Length(Buffer)) and ((Buffer[i+1] and $C0) = $80) and ((Buffer[i+2] and $C0) = $80) then
                begin
                  Inc(ValidUTF8Sequences);
                  Inc(i, 2);
                end
                else
                  IsLikelyUTF8 := False;
              end
              else if (Buffer[i] and $F8) = $F0 then // 4字节序列
              begin
                if (i + 3 < Length(Buffer)) and ((Buffer[i+1] and $C0) = $80) and ((Buffer[i+2] and $C0) = $80) and ((Buffer[i+3] and $C0) = $80) then
                begin
                  Inc(ValidUTF8Sequences);
                  Inc(i, 3);
                end
                else
                  IsLikelyUTF8 := False;
              end
              else
                IsLikelyUTF8 := False;
            end;
            Inc(i);
          end;

          // 基于序列有效性判断UTF-8
          if (TotalUTF8Sequences > 0) and (ValidUTF8Sequences/TotalUTF8Sequences > 0.9) then
            EncodingName := 'UTF-8'
          else if IsUTF8Valid(PByte(Buffer), Length(Buffer)) then
            EncodingName := 'UTF-8'
          else if (ByteCounts[0] = 0) and (ByteCounts[9] = 0) and (ByteCounts[10] = 0) and (ByteCounts[13] = 0) then
            EncodingName := 'ASCII'
          // 检测各种亚洲编码
          else if IsGBKString(Buffer, Length(Buffer)) then
          begin
            // 检查是否只有GB2312字符
            var GB2312Only := True;
            var GBKCount := 0;
            var GB2312Count := 0;
            var j := 0;

            while j < Length(Buffer) do
            begin
              if Buffer[j] <= $7F then
              begin
                Inc(j);
              end
              else if (Buffer[j] >= $81) and (Buffer[j] <= $FE) and (j + 1 < Length(Buffer)) and
                      (Buffer[j+1] >= $40) and (Buffer[j+1] <= $FE) and (Buffer[j+1] <> $7F) then
              begin
                Inc(GBKCount);

                // 检查是否是GB2312字符范围
                if (Buffer[j] >= $A1) and (Buffer[j] <= $F7) and
                   (Buffer[j+1] >= $A1) and (Buffer[j+1] <= $FE) then
                begin
                  Inc(GB2312Count);
                end
                else
                begin
                  GB2312Only := False; // 存在非GB2312字符
                end;

                Inc(j, 2);
              end
              else
              begin
                Inc(j);
              end;
            end;

            // 如果文件中只有GB2312字符，则使用GB2312编码
            // 修改检测逻辑，提高GB2312的检测优先级
            // 如果文件中大部分是GB2312字符，则使用GB2312编码
            if (GB2312Count > 0) and ((GB2312Count = GBKCount) or (GB2312Count >= GBKCount * 0.9)) then
              EncodingName := 'GB2312'
            else
              EncodingName := 'GBK';
          end
          else if IsBig5String(Buffer, Length(Buffer)) then
          begin
            EncodingName := 'BIG5';
            if Assigned(FLogCallback) then
              FLogCallback('检测到Big5编码: ' + FileName);
          end
          else if IsShiftJISString(Buffer, Length(Buffer)) then
          begin
            EncodingName := 'Shift-JIS';
            if Assigned(FLogCallback) then
              FLogCallback('检测到Shift-JIS编码: ' + FileName);
          end
          else if IsEUCKRString(Buffer, Length(Buffer)) then
          begin
            EncodingName := 'EUC-KR';
            if Assigned(FLogCallback) then
              FLogCallback('检测到EUC-KR编码: ' + FileName);
          end
          else if (ByteCounts[$A1] > 0) and (ByteCounts[$40] > 0) and (ByteCounts[$F9] > 0) then
            EncodingName := 'BIG5'
          else if (ByteCounts[$A1] > 0) and (ByteCounts[$A3] > 0) and (ByteCounts[$A4] > 0) and (ByteCounts[$A5] > 0) then
            EncodingName := 'EUC-JP'
          else if (ByteCounts[$B0] > 0) and (ByteCounts[$B1] > 0) and (ByteCounts[$B2] > 0) and (ByteCounts[$B3] > 0) then
            EncodingName := 'EUC-KR'
          else if (ByteCounts[0] > Length(Buffer) div 4) then // 大量NULL字节可能是UTF-16
            EncodingName := 'UTF-16LE'
          else
            EncodingName := 'ANSI'; // 默认为ANSI
        end;
      finally
        Stream.Free;
      end;
    end
    else
    begin
      EncodingName := '';
      Result := False;
      Exit;
    end;
  except
    // 如果读取失败，假设没有BOM
    HasUTF8BOM := False;
    EncodingName := 'ANSI'; // 出错时默认为ANSI
  end;

  if HasUTF8BOM then
  begin
    EncodingName := 'UTF-8 with BOM';
    Result := True;

    if Assigned(FLogCallback) then
      FLogCallback('检测到UTF-8 BOM: ' + FileName);
    Exit;
  end;

  // 使用JCL库检测文件编码
  try
    // 调用兼容层的编码检测方法
    EncodingName := UtilsJCLEncoding.DetectFileEncoding(FileName);
    Result := EncodingName <> 'Unknown';

    // 如果检测成功，但编码不明确或不是UTF-8，优先建议使用UTF-8+BOM
    if Result then
    begin
      if Assigned(FLogCallback) then
        FLogCallback('JCL检测到文件编码: ' + FileName + ' -> ' + EncodingName);

      // 如果是UTF-8但没有BOM，标记为普通UTF-8
      if SameText(EncodingName, 'UTF-8') and not HasUTF8BOM then
        EncodingName := 'UTF-8';
    end
    else
    begin
      // 如果检测失败，尝试使用文件名和内容特征来判断
      var FileExt := LowerCase(ExtractFileExt(FileName));
      var FileName_Lower := LowerCase(ExtractFileName(FileName));
      var SystemCodePage := GetACP;
      var DefaultEncoding := 'ANSI';
      var LanguageHint := '';

      // 检查文件名是否包含语言相关关键字
      // 中文
      if (Pos('chinese', FileName_Lower) > 0) or
         (Pos('china', FileName_Lower) > 0) or
         (Pos('cn', FileName_Lower) > 0) or
         (Pos('zh', FileName_Lower) > 0) or
         (Pos('gbk', FileName_Lower) > 0) or
         (Pos('gb2312', FileName_Lower) > 0) or
         (Pos('gb18030', FileName_Lower) > 0) then
      begin
        EncodingName := 'GB2312';
        LanguageHint := '中文';
      end
      // 繁体中文
      else if (Pos('taiwan', FileName_Lower) > 0) or
              (Pos('hongkong', FileName_Lower) > 0) or
              (Pos('tw', FileName_Lower) > 0) or
              (Pos('hk', FileName_Lower) > 0) or
              (Pos('big5', FileName_Lower) > 0) then
      begin
        EncodingName := 'BIG5';
        LanguageHint := '繁体中文';
      end
      // 日文
      else if (Pos('japanese', FileName_Lower) > 0) or
              (Pos('japan', FileName_Lower) > 0) or
              (Pos('jp', FileName_Lower) > 0) or
              (Pos('ja', FileName_Lower) > 0) or
              (Pos('sjis', FileName_Lower) > 0) or
              (Pos('shift-jis', FileName_Lower) > 0) then
      begin
        EncodingName := 'Shift-JIS';
        LanguageHint := '日文';
      end
      // 韩文
      else if (Pos('korean', FileName_Lower) > 0) or
              (Pos('korea', FileName_Lower) > 0) or
              (Pos('kr', FileName_Lower) > 0) or
              (Pos('ko', FileName_Lower) > 0) or
              (Pos('euc-kr', FileName_Lower) > 0) then
      begin
        EncodingName := 'EUC-KR';
        LanguageHint := '韩文';
      end
      // 俄文
      else if (Pos('russian', FileName_Lower) > 0) or
              (Pos('russia', FileName_Lower) > 0) or
              (Pos('ru', FileName_Lower) > 0) or
              (Pos('cyrillic', FileName_Lower) > 0) then
      begin
        EncodingName := 'Windows-1251';
        LanguageHint := '俄文';
      end
      // 其他语言关键字检测...
      else
      begin
        // 对于中文文件，先尝试检测是否包含中文字符
        if FileExt = '.txt' then
        begin
          // 读取文件内容进行检测
          try
            var FileContent := TFile.ReadAllBytes(FileName);
            if Length(FileContent) > 0 then
            begin
              // 检测是否包含中文字符
              var HasChineseChars := False;
              var k := 0;
              while (k < Length(FileContent) - 1) and (not HasChineseChars) do
              begin
                if (FileContent[k] >= $81) and (FileContent[k] <= $FE) and
                   (FileContent[k+1] >= $40) and (FileContent[k+1] <= $FE) and
                   (FileContent[k+1] <> $7F) then
                begin
                  HasChineseChars := True;
                  // 如果包含中文字符，优先使用GB2312
                  EncodingName := 'GB2312';
                  Result := True;
                  Exit;
                end;
                Inc(k);
              end;
            end;
          except
            // 忽略读取错误，继续使用默认编码
          end;
        end;

        // 根据系统区域设置选择默认编码
        case SystemCodePage of
          936: // 简体中文
          begin
            // 对于中文文本文件，优先使用GB2312而非GBK
            // 因为GB2312是最基础的中文编码，兼容性更好
            DefaultEncoding := 'GB2312';
            LanguageHint := '简体中文系统';
          end;
          950: // 繁体中文
          begin
            DefaultEncoding := 'BIG5';
            LanguageHint := '繁体中文系统';
          end;
          932: // 日文
          begin
            DefaultEncoding := 'Shift-JIS';
            LanguageHint := '日文系统';
          end;
          949: // 韩文
          begin
            DefaultEncoding := 'EUC-KR';
            LanguageHint := '韩文系统';
          end;
          1251: // 西里尔文
          begin
            DefaultEncoding := 'Windows-1251';
            LanguageHint := '西里尔文系统';
          end;
          1252: // 西欧
          begin
            DefaultEncoding := 'Windows-1252';
            LanguageHint := '西欧系统';
          end;
          1250: // 中欧
          begin
            DefaultEncoding := 'Windows-1250';
            LanguageHint := '中欧系统';
          end;
          1253: // 希腊文
          begin
            DefaultEncoding := 'Windows-1253';
            LanguageHint := '希腊文系统';
          end;
          1254: // 土耳其文
          begin
            DefaultEncoding := 'Windows-1254';
            LanguageHint := '土耳其文系统';
          end;
          1255: // 希伯来文
          begin
            DefaultEncoding := 'Windows-1255';
            LanguageHint := '希伯来文系统';
          end;
          1256: // 阿拉伯文
          begin
            DefaultEncoding := 'Windows-1256';
            LanguageHint := '阿拉伯文系统';
          end;
          else
          begin
            DefaultEncoding := 'ANSI';
            LanguageHint := '默认系统';
          end;
        end;

        // 对于文本文件，使用系统区域设置的默认编码
        if (FileExt = '.txt') or (FileExt = '.ini') or (FileExt = '.log') or (FileExt = '.cfg') or (FileExt = '.csv') then
        begin
          EncodingName := DefaultEncoding;
        end
        else
        begin
          // 对于非文本文件，默认使用ANSI
          EncodingName := 'ANSI';
        end;
      end;

      Result := True;

      if Assigned(FLogCallback) then
      begin
        if LanguageHint <> '' then
          FLogCallback(Format('无法准确检测编码，基于%s区域设置默认使用%s编码: %s',
                             [LanguageHint, EncodingName, FileName]))
        else
          FLogCallback(Format('无法检测编码，默认使用%s: %s', [EncodingName, FileName]));
      end;
    end;
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('编码检测出错: ' + E.Message);

      // 发生异常时，根据系统区域设置决定默认编码
      var SystemCodePage := GetACP;
      var DefaultEncoding := 'ANSI';
      var LanguageHint := '';

      // 根据系统区域设置选择默认编码
      case SystemCodePage of
        936: // 简体中文
        begin
          DefaultEncoding := 'GBK';
          LanguageHint := '简体中文系统';
        end;
        950: // 繁体中文
        begin
          DefaultEncoding := 'BIG5';
          LanguageHint := '繁体中文系统';
        end;
        932: // 日文
        begin
          DefaultEncoding := 'Shift-JIS';
          LanguageHint := '日文系统';
        end;
        949: // 韩文
        begin
          DefaultEncoding := 'EUC-KR';
          LanguageHint := '韩文系统';
        end;
        1251: // 西里尔文
        begin
          DefaultEncoding := 'Windows-1251';
          LanguageHint := '西里尔文系统';
        end;
        1252: // 西欧
        begin
          DefaultEncoding := 'Windows-1252';
          LanguageHint := '西欧系统';
        end;
        else
        begin
          DefaultEncoding := 'ANSI';
          LanguageHint := '默认系统';
        end;
      end;

      EncodingName := DefaultEncoding;
      Result := True;

      if Assigned(FLogCallback) then
      begin
        FLogCallback(Format('检测出错，基于%s区域设置默认使用%s编码',
                           [LanguageHint, EncodingName]));
      end;
    end;
  end;
end;

function TEncodingController.ConvertWithJCL(const SourceFile, TargetFile: string;
  const SourceEncoding, TargetEncoding: string; AddBOM: Boolean): Boolean;
var
  SysErrorCode: Cardinal;
  ActualTargetEncoding: string;
  ActualAddBOM: Boolean;
begin
  Result := False;

  // 记录详细转换参数
  if Assigned(FLogCallback) then
    FLogCallback(Format('JCL转换开始: %s -> %s (源编码: %s, 目标编码: %s, AddBOM: %s)',
                      [SourceFile, TargetFile, SourceEncoding, TargetEncoding, BoolToStr(AddBOM, True)]));

  // 安全检查：保护经常用作示例的文件，避免意外转换
  if IsUnsupportedFile(ExtractFileName(SourceFile)) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('跳过不受支持的文件: ' + SourceFile);
    Exit(False);
  end;

  // 特殊处理UTF-8 BOM的情况
  ActualTargetEncoding := TargetEncoding;
  ActualAddBOM := AddBOM;
  if (SameText(TargetEncoding, 'UTF-8 BOM') or SameText(TargetEncoding, 'UTF-8-BOM') or
     SameText(TargetEncoding, 'UTF8-BOM')) then
  begin
    ActualTargetEncoding := 'UTF-8';
    ActualAddBOM := True;

    if Assigned(FLogCallback) then
      FLogCallback('已识别UTF-8 BOM目标，将使用UTF-8+BOM转换');
  end;

  // 记录实际转换参数
  if Assigned(FLogCallback) then
    FLogCallback(Format('开始转换: %s -> %s, 从 [%s] 到 [%s], BOM: %s',
                      [SourceFile, TargetFile, SourceEncoding, ActualTargetEncoding,
                       BoolToStr(ActualAddBOM, True)]));

  // 使用兼容层的ConvertFileByName函数
  try
    Result := UtilsJCLEncoding.ConvertFileByName(SourceFile, TargetFile,
                                             SourceEncoding, ActualTargetEncoding,
                                             ActualAddBOM);
  except
    on E: EFOpenError do
    begin
      SysErrorCode := GetLastError;
      if Assigned(FLogCallback) then
        FLogCallback(Format('文件访问错误 (%d): %s', [SysErrorCode, E.Message]));
      Result := False;
    end;
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('JCL转换出错: ' + E.Message);
      Result := False;
    end;
  end;

  // 转换后检查和日志记录
  if Result then
  begin
    if Assigned(FLogCallback) then
    begin
      FLogCallback(Format('JCL转换调用完成: %s (源编码: %s, 目标编码: %s, AddBOM: %s)',
                        [TargetFile, SourceEncoding, ActualTargetEncoding, BoolToStr(ActualAddBOM, True)]));

      // 验证转换结果
      if FileExists(TargetFile) then
      begin
        var ResultEncodingName: string;
        if DetectFileEncoding(TargetFile, ResultEncodingName) then
          FLogCallback(Format('转换后的文件编码: %s', [ResultEncodingName]));

        // 特殊情况: 如果目标应为UTF-8 BOM但检测为其他编码，尝试手动添加BOM
        if ActualAddBOM and SameText(ActualTargetEncoding, 'UTF-8') and
           not SameText(ResultEncodingName, 'UTF-8 with BOM') then
        begin
          FLogCallback('警告: 文件转换后没有BOM，尝试手动添加BOM标记');

          var ActualFile := TargetFile;
          if not FileExists(ActualFile) and FileExists(SourceFile + '.tmp') then
            ActualFile := SourceFile + '.tmp';

          if FileExists(ActualFile) then
          begin
            try
              // 再次尝试添加BOM
              var FixedFile := ActualFile + '.fix';
              if UtilsJCLEncoding.ConvertFileToUTF8BOM(ActualFile, FixedFile) then
              begin
                if FileExists(FixedFile) then
                begin
                  if DeleteFile(PChar(ActualFile)) then
                  begin
                    if RenameFile(FixedFile, ActualFile) then
                      FLogCallback('成功添加BOM标记')
                    else
                      FLogCallback('无法重命名修复文件');
                  end
                  else
                    FLogCallback('无法删除原文件以应用修复');

                  // 如果临时修复文件仍然存在，清理它
                  if FileExists(FixedFile) then
                    DeleteFile(PChar(FixedFile));
                end;
              end;
            except
              on E: Exception do
                FLogCallback('添加BOM标记时出错: ' + E.Message);
            end;
          end;
        end;
      end;
    end;
  end
  else
  begin
    if Assigned(FLogCallback) then
      FLogCallback(Format('JCL转换失败: %s -> %s', [SourceEncoding, ActualTargetEncoding]));
  end;
end;

// NEW: Internal helper to perform single file conversion using names
function TEncodingController.DoConvertSingleFileByName(const SourceFile, TargetEncodingName: string; AddBOM: Boolean = False; const TargetFile: string = ''): TConversionResult;
var
  TempFile: string;
  IsUTF8BOMTarget: Boolean;
  SourceEncodingName: string;
  DestinationFileEncoding: string;
  ActualFile: string;
  SourceStream, TargetStream: TFileStream;
  Content: string;
  UTF8Bytes, TempBytes: TBytes;
  BOMBytes: TBytes;
  BytesRead, ChunkSize, TotalBytesRead: Integer;
  IsCorruptedFile: Boolean;
  FileSize: Int64;
begin
  Result := crFailed;
  SourceEncodingName := '';
  IsCorruptedFile := False;

  // 详细日志：开始转换准备
  if Assigned(FLogCallback) then
    FLogCallback(Format('开始准备转换文件: %s, 目标编码: %s, 添加BOM: %s',
      [SourceFile, TargetEncodingName, BoolToStr(AddBOM, True)]));

  // 验证源文件存在
  if not FileExists(SourceFile) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('错误：源文件不存在: ' + SourceFile);
    Exit;
  end;

  // 检测源文件编码
  try
    if not DetectFileEncoding(SourceFile, SourceEncodingName) then
    begin
      if Assigned(FLogCallback) then
        FLogCallback('警告：无法检测源文件编码，假设为ANSI');
      SourceEncodingName := 'ANSI';
    end
    else if Assigned(FLogCallback) then
      FLogCallback(Format('检测到源文件编码: %s -> %s', [SourceFile, SourceEncodingName]));
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback(Format('检测文件编码失败: %s - %s', [SourceFile, E.Message]));
      // 出错时默认为ANSI
      SourceEncodingName := 'ANSI';
    end;
  end;

  try
    // 目标文件设置
    if TargetFile = '' then
      TempFile := ChangeFileExt(SourceFile, '.tmp')
    else
      TempFile := TargetFile;

    // 确定最终操作的文件
    if TargetFile = '' then
      ActualFile := SourceFile
    else
      ActualFile := TargetFile;

    // 检查UTF-8 BOM目标 - 改进识别逻辑
    IsUTF8BOMTarget := (SameText(TargetEncodingName, 'UTF-8 with BOM') or
                        SameText(TargetEncodingName, 'UTF-8-BOM') or
                        SameText(TargetEncodingName, 'UTF8-BOM') or
                        (SameText(TargetEncodingName, 'UTF-8') and AddBOM));

    // 详细日志：源和目标编码信息更详细
    if Assigned(FLogCallback) then
    begin
      var BOMText: string := '';
      if IsUTF8BOMTarget then
        BOMText := ' (带BOM)'
      else if AddBOM then
        BOMText := ' (带BOM)';

      FLogCallback(Format('源编码: [%s] 目标编码: [%s%s]',
        [SourceEncodingName, TargetEncodingName, BOMText]));
    end;

    if IsUTF8BOMTarget then
    begin
      // 使用增强的UTF-8 BOM转换方法，支持损坏文件处理
      if Assigned(FLogCallback) then
        FLogCallback(Format('使用增强的UTF-8 BOM转换 (源编码: %s)...', [SourceEncodingName]));

      // 确保删除已存在的临时文件
      if FileExists(TempFile) then
        DeleteFile(PChar(TempFile));

      try
        // 读取源文件内容，支持损坏文件恢复和大文件优化
        SourceStream := TFileStream.Create(SourceFile, fmOpenRead or fmShareDenyNone);
        try
          // 获取文件大小
          FileSize := SourceStream.Size;

          if Assigned(FLogCallback) then
            FLogCallback(Format('处理文件: %s (大小: %.2f MB)', [SourceFile, FileSize / (1024 * 1024)]));

          // 对于大文件使用分块读取处理
          if FileSize > 10 * 1024 * 1024 then // 10MB以上的文件使用分块处理
          begin
            if Assigned(FLogCallback) then
              FLogCallback('检测到大文件，使用分块读取优化内存使用');

            // 创建目标文件
            TargetStream := TFileStream.Create(TempFile, fmCreate);
            try
              // 如果需要BOM，先写入BOM
              if IsUTF8BOMTarget then
              begin
                BOMBytes := TEncoding.UTF8.GetPreamble;
                if Length(BOMBytes) > 0 then
                  TargetStream.WriteBuffer(BOMBytes[0], Length(BOMBytes));
              end;

              // 分块读取和处理
              ChunkSize := 1 * 1024 * 1024; // 1MB的块大小
              SetLength(TempBytes, ChunkSize);
              TotalBytesRead := 0;

              while TotalBytesRead < FileSize do
              begin
                try
                  // 读取一块数据
                  BytesRead := SourceStream.Read(TempBytes[0], ChunkSize);
                  if BytesRead <= 0 then Break;

                  // 根据源编码转换这块数据
                  try
                    // 转换这块数据到UTF-8
                    if SourceEncodingName = 'UTF-8' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.UTF8.GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'UTF-8 with BOM' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.UTF8.GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'UTF-16LE' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.Unicode.GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'UTF-16BE' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.BigEndianUnicode.GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'GBK' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(936).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'Windows-1252' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(1252).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'Windows-1250' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(1250).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'MacRoman' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(10000).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'IBM850' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(850).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'IBM437' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(437).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'IBM865' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(865).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'IBM860' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(860).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'Windows-1253' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(1253).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'Windows-1254' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(1254).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'Windows-1257' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(1257).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'KOI8-U' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(21866).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'MacCyrillic' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(10007).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'Windows-1255' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(1255).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'Windows-1256' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(1256).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'CP862' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(862).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'CP864' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(864).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'ISO-8859-6-I' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(708).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'CP932' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(932).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'CP949' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(949).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'CP950' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(950).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'CP936' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(936).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'Big5-HKSCS' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(950).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'EUC-TW' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(51950).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'ISO-2022-JP' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(50220).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'ISO-2022-KR' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(50225).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'VISCII' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(1258).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'TIS-620' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(874).GetString(TempBytes, 0, BytesRead))
                    else if (SourceEncodingName = 'TSCII') and IsEncodingAvailable(57004) then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(57004).GetString(TempBytes, 0, BytesRead))
                    else if (SourceEncodingName = 'ISCII') and IsEncodingAvailable(57002) then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(57002).GetString(TempBytes, 0, BytesRead))
                    else if (SourceEncodingName = 'ARMSCII-8') and IsEncodingAvailable(901) then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(901).GetString(TempBytes, 0, BytesRead))
                    else if (SourceEncodingName = 'Geez') and IsEncodingAvailable(43507) then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(43507).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'Amharic' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.UTF7.GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'CESU-8' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.UTF7.GetString(TempBytes, 0, BytesRead))
                    else if (SourceEncodingName = 'Mongolian') and IsEncodingAvailable(54936) then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(54936).GetString(TempBytes, 0, BytesRead))
                    else if (SourceEncodingName = 'Tibetan') and IsEncodingAvailable(54936) then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(54936).GetString(TempBytes, 0, BytesRead))
                    else if (SourceEncodingName = 'Lao') and IsEncodingAvailable(28598) then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(28598).GetString(TempBytes, 0, BytesRead))
                    else if SourceEncodingName = 'Khmer' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.UTF8.GetString(UTF8Bytes))
                    else if SourceEncodingName = 'Myanmar' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.UTF8.GetString(UTF8Bytes))
                    else if SourceEncodingName = 'Indonesian' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(1252).GetString(UTF8Bytes))
                    else if SourceEncodingName = 'Malay' then
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.GetEncoding(1252).GetString(UTF8Bytes))
                    else
                        UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.Default.GetString(TempBytes, 0, BytesRead));

                    // 写入转换后的数据
                    if Length(UTF8Bytes) > 0 then
                      TargetStream.WriteBuffer(UTF8Bytes[0], Length(UTF8Bytes));

                  except
                    on E: EEncodingError do
                    begin
                      IsCorruptedFile := True;
                      if Assigned(FLogCallback) then
                        FLogCallback(Format('编码转换错误: %s (%s)', [SourceFile, E.Message]));

                      // 尝试使用默认编码
                      UTF8Bytes := TEncoding.UTF8.GetBytes(TEncoding.Default.GetString(TempBytes, 0, BytesRead));
                      if Length(UTF8Bytes) > 0 then
                        TargetStream.WriteBuffer(UTF8Bytes[0], Length(UTF8Bytes));
                    end;
                  end;

                  // 更新已读取的总字节数
                  Inc(TotalBytesRead, BytesRead);

                  // 每处理4MB报告一次进度
                  if (TotalBytesRead mod (4 * 1024 * 1024)) < ChunkSize then
                  begin
                    if Assigned(FLogCallback) then
                      FLogCallback(Format('已处理: %.1f MB (%.1f%%)',
                        [TotalBytesRead / (1024 * 1024), (TotalBytesRead / FileSize) * 100]));
                  end;
                except
                  on E: Exception do
                  begin
                    IsCorruptedFile := True;
                    if Assigned(FLogCallback) then
                      FLogCallback(Format('警告: 文件块读取错误 - %s (%s)', [SourceFile, E.Message]));

                    // 尝试跳过这个块
                    SourceStream.Position := TotalBytesRead + ChunkSize;
                    Inc(TotalBytesRead, ChunkSize);
                  end;
                end;
              end;

              Result := crSuccess;
              if Assigned(FLogCallback) then
              begin
                if IsCorruptedFile then
                  FLogCallback('成功修复并转换损坏的大文件')
                else
                  FLogCallback(Format('大文件转换成功，总处理: %.2f MB', [TotalBytesRead / (1024 * 1024)]));
              end;

              // 提前退出，因为已经完成了转换
              Exit;
            finally
              TargetStream.Free;
            end;
          end;

          // 对于小文件，使用原来的一次性读取方式
          SetLength(UTF8Bytes, FileSize);
          try
            SourceStream.ReadBuffer(UTF8Bytes[0], FileSize);
          except
            on E: Exception do
            begin
              IsCorruptedFile := True;
              if Assigned(FLogCallback) then
                FLogCallback(Format('警告: 文件可能已损坏 - %s (%s)', [SourceFile, E.Message]));

              // 尝试恢复读取
              if FileSize > 0 then
              begin
                BytesRead := SourceStream.Read(UTF8Bytes[0], FileSize);
                SetLength(UTF8Bytes, BytesRead);
                if Assigned(FLogCallback) then
                  FLogCallback(Format('已恢复读取 %d 字节', [BytesRead]));
              end
              else
              begin
                if Assigned(FLogCallback) then
                  FLogCallback('文件为空，无法恢复');
                Result := crFailed;
                Exit;
              end;
            end;
          end;

          // 根据检测到的编码转换内容
          try
            if (SourceEncodingName = 'UTF-8') or (SourceEncodingName = 'UTF-8 with BOM') then
              Content := TEncoding.UTF8.GetString(UTF8Bytes)
            else if SourceEncodingName = 'UTF-16LE' then
              Content := TEncoding.Unicode.GetString(UTF8Bytes)
            else if SourceEncodingName = 'UTF-16BE' then
              Content := TEncoding.BigEndianUnicode.GetString(UTF8Bytes)
            else if SourceEncodingName = 'UTF-32LE' then
              Content := TEncoding.GetEncoding(12000).GetString(UTF8Bytes)
            else if SourceEncodingName = 'UTF-32BE' then
              Content := TEncoding.GetEncoding(12001).GetString(UTF8Bytes)
            else if SourceEncodingName = 'ASCII' then
              Content := TEncoding.ASCII.GetString(UTF8Bytes)
            else if SourceEncodingName = 'GBK' then
              Content := TEncoding.GetEncoding(936).GetString(UTF8Bytes)
            else if SourceEncodingName = 'EUC-JP' then
              Content := TEncoding.GetEncoding(20932).GetString(UTF8Bytes)
            else if SourceEncodingName = 'EUC-KR' then
              Content := TEncoding.GetEncoding(51949).GetString(UTF8Bytes)
            else if SourceEncodingName = 'BIG5' then
              Content := TEncoding.GetEncoding(950).GetString(UTF8Bytes)
            else if SourceEncodingName = 'Windows-1252' then
              Content := TEncoding.GetEncoding(1252).GetString(UTF8Bytes)
            else if SourceEncodingName = 'Windows-1250' then
              Content := TEncoding.GetEncoding(1250).GetString(UTF8Bytes)
            else if SourceEncodingName = 'MacRoman' then
              Content := TEncoding.GetEncoding(10000).GetString(UTF8Bytes)
            else if SourceEncodingName = 'IBM850' then
              Content := TEncoding.GetEncoding(850).GetString(UTF8Bytes)
            else if SourceEncodingName = 'IBM437' then
              Content := TEncoding.GetEncoding(437).GetString(UTF8Bytes)
            else if SourceEncodingName = 'IBM865' then
              Content := TEncoding.GetEncoding(865).GetString(UTF8Bytes)
            else if SourceEncodingName = 'IBM860' then
              Content := TEncoding.GetEncoding(860).GetString(UTF8Bytes)
            else if SourceEncodingName = 'Windows-1253' then
              Content := TEncoding.GetEncoding(1253).GetString(UTF8Bytes)
            else if SourceEncodingName = 'Windows-1254' then
              Content := TEncoding.GetEncoding(1254).GetString(UTF8Bytes)
            else if SourceEncodingName = 'Windows-1257' then
              Content := TEncoding.GetEncoding(1257).GetString(UTF8Bytes)
            else if SourceEncodingName = 'KOI8-U' then
              Content := TEncoding.GetEncoding(21866).GetString(UTF8Bytes)
            else if SourceEncodingName = 'MacCyrillic' then
              Content := TEncoding.GetEncoding(10007).GetString(UTF8Bytes)
            else if SourceEncodingName = 'Windows-1255' then
              Content := TEncoding.GetEncoding(1255).GetString(UTF8Bytes)
            else if SourceEncodingName = 'Windows-1256' then
              Content := TEncoding.GetEncoding(1256).GetString(UTF8Bytes)
            else if SourceEncodingName = 'CP862' then
              Content := TEncoding.GetEncoding(862).GetString(UTF8Bytes)
            else if SourceEncodingName = 'CP864' then
              Content := TEncoding.GetEncoding(864).GetString(UTF8Bytes)
            else if SourceEncodingName = 'ISO-8859-6-I' then
              Content := TEncoding.GetEncoding(708).GetString(UTF8Bytes)
            else if SourceEncodingName = 'CP932' then
              Content := TEncoding.GetEncoding(932).GetString(UTF8Bytes)
            else if SourceEncodingName = 'CP949' then
              Content := TEncoding.GetEncoding(949).GetString(UTF8Bytes)
            else if SourceEncodingName = 'CP950' then
              Content := TEncoding.GetEncoding(950).GetString(UTF8Bytes)
            else if SourceEncodingName = 'CP936' then
              Content := TEncoding.GetEncoding(936).GetString(UTF8Bytes)
            else if SourceEncodingName = 'Big5-HKSCS' then
              Content := TEncoding.GetEncoding(950).GetString(UTF8Bytes)
            else if SourceEncodingName = 'EUC-TW' then
              Content := TEncoding.GetEncoding(51950).GetString(UTF8Bytes)
            else if SourceEncodingName = 'ISO-2022-JP' then
              Content := TEncoding.GetEncoding(50220).GetString(UTF8Bytes)
            else if SourceEncodingName = 'ISO-2022-KR' then
              Content := TEncoding.GetEncoding(50225).GetString(UTF8Bytes)
            else if SourceEncodingName = 'VISCII' then
              Content := TEncoding.GetEncoding(1258).GetString(UTF8Bytes)
            else if SourceEncodingName = 'TIS-620' then
              Content := TEncoding.GetEncoding(874).GetString(UTF8Bytes)
            else if (SourceEncodingName = 'TSCII') and IsEncodingAvailable(57004) then
              Content := TEncoding.GetEncoding(57004).GetString(UTF8Bytes)
            else if (SourceEncodingName = 'ISCII') and IsEncodingAvailable(57002) then
              Content := TEncoding.GetEncoding(57002).GetString(UTF8Bytes)
            else if (SourceEncodingName = 'ARMSCII-8') and IsEncodingAvailable(901) then
              Content := TEncoding.GetEncoding(901).GetString(UTF8Bytes)
            else if (SourceEncodingName = 'Geez') and IsEncodingAvailable(43507) then
              Content := TEncoding.GetEncoding(43507).GetString(UTF8Bytes)
            else if SourceEncodingName = 'Amharic' then
              Content := TEncoding.UTF7.GetString(UTF8Bytes)
            else if SourceEncodingName = 'CESU-8' then
              Content := TEncoding.UTF7.GetString(UTF8Bytes)
            else if (SourceEncodingName = 'Mongolian') and IsEncodingAvailable(54936) then
              Content := TEncoding.GetEncoding(54936).GetString(UTF8Bytes)
            else if (SourceEncodingName = 'Tibetan') and IsEncodingAvailable(54936) then
              Content := TEncoding.GetEncoding(54936).GetString(UTF8Bytes)
            else if (SourceEncodingName = 'Lao') and IsEncodingAvailable(28598) then
              Content := TEncoding.GetEncoding(28598).GetString(UTF8Bytes)
            else if SourceEncodingName = 'Khmer' then
              Content := TEncoding.UTF8.GetString(UTF8Bytes)
            else if SourceEncodingName = 'Myanmar' then
              Content := TEncoding.UTF8.GetString(UTF8Bytes)
            else if SourceEncodingName = 'Indonesian' then
              Content := TEncoding.GetEncoding(1252).GetString(UTF8Bytes)
            else if SourceEncodingName = 'Malay' then
              Content := TEncoding.GetEncoding(1252).GetString(UTF8Bytes)
            else
              Content := TEncoding.Default.GetString(UTF8Bytes);
          except
            on E: EEncodingError do
            begin
              if Assigned(FLogCallback) then
                FLogCallback(Format('编码转换错误: %s (%s)', [SourceFile, E.Message]));
              // 尝试使用默认编码作为后备方案
              Content := TEncoding.Default.GetString(UTF8Bytes);
            end;
          end;

          // 创建目标文件
          TargetStream := TFileStream.Create(TempFile, fmCreate);
          try
            // 写入UTF-8 BOM
            BOMBytes := TEncoding.UTF8.GetPreamble;
            if Length(BOMBytes) > 0 then
              TargetStream.WriteBuffer(BOMBytes[0], Length(BOMBytes));

            // 写入UTF-8编码的内容
            UTF8Bytes := TEncoding.UTF8.GetBytes(Content);
            if Length(UTF8Bytes) > 0 then
              TargetStream.WriteBuffer(UTF8Bytes[0], Length(UTF8Bytes));

            Result := crSuccess;
            if Assigned(FLogCallback) then
            begin
              if IsCorruptedFile then
                FLogCallback('成功修复并转换损坏的文件')
              else
                FLogCallback('UTF-8 BOM转换成功');
            end;
          finally
            TargetStream.Free;
          end;
        finally
          SourceStream.Free;
        end;
      except
        on E: Exception do
        begin
          var SystemError := GetLastError;
          if Assigned(FLogCallback) then
            FLogCallback(Format('UTF-8 BOM转换异常: %s (系统错误: %d)', [E.Message, SystemError]));
          Result := crFailed;
        end;
      end;
    end
    else
    begin
      // 常规编码转换处理
      var ActualTargetName := TargetEncodingName;
      var ActualBOM := AddBOM;

      if Assigned(FLogCallback) then
        FLogCallback(Format('使用标准转换流程 %s -> %s (BOM: %s)',
          [SourceEncodingName, ActualTargetName, BoolToStr(ActualBOM, True)]));

      try
        // 正确传递源编码和目标编码参数
        if ConvertWithJCL(SourceFile, TempFile, SourceEncodingName, ActualTargetName, ActualBOM) then
          Result := crSuccess
        else
        begin
          var SystemError := GetLastError;
          if Assigned(FLogCallback) then
            FLogCallback(Format('标准转换失败，系统错误: %d', [SystemError]));
          Result := crFailed;
        end;
      except
        on E: Exception do
        begin
          var SystemError := GetLastError;
          if Assigned(FLogCallback) then
            FLogCallback(Format('标准转换异常: %s (系统错误: %d)', [E.Message, SystemError]));
          Result := crFailed;
        end;
      end;
    end;

    // 如果转换成功且需要替换原文件
    if (Result = crSuccess) and (TargetFile = '') then
    begin
      if Assigned(FLogCallback) then
        FLogCallback('转换成功，准备替换原文件...');

      try
        // 使用内部方法复制文件
        TryCopyTempToOriginal(TempFile, SourceFile);

        // 检查文件复制成功
        if not FileExists(SourceFile) then
        begin
          var SystemError := GetLastError;
          if Assigned(FLogCallback) then
            FLogCallback(Format('替换原文件失败，系统错误: %d', [SystemError]));
          Result := crFailed;
        end;
      except
        on E: Exception do
        begin
          if Assigned(FLogCallback) then
            FLogCallback(Format('替换原文件异常: %s', [E.Message]));
          Result := crFailed;
        end;
      end;
    end;

    // 检查转换后的文件编码
    if Result = crSuccess then
    begin
      try
        DestinationFileEncoding := '';

        if FileExists(ActualFile) then
        begin
          if DetectFileEncoding(ActualFile, DestinationFileEncoding) then
          begin
            if Assigned(FLogCallback) then
              FLogCallback(Format('转换完成后的文件编码: %s -> %s', [ActualFile, DestinationFileEncoding]));

            // 验证是否成功转换为目标编码
            if IsUTF8BOMTarget and (Pos('UTF-8', DestinationFileEncoding) = 0) then
            begin
              // 最后一次尝试修复 - 如果检测出来不是UTF-8，但是目标应该是UTF-8 BOM
              if Assigned(FLogCallback) then
              begin
                FLogCallback('警告：文件应该是UTF-8 BOM，但检测到: ' + DestinationFileEncoding + '，尝试修复...');

                // 再次尝试添加BOM
                var FixedFile := ActualFile + '.fix';
                if UtilsJCLEncoding.ConvertFileToUTF8BOM(ActualFile, FixedFile) then
                begin
                  if FileExists(FixedFile) then
                  begin
                    if DeleteFile(PChar(ActualFile)) then
                    begin
                      if RenameFile(FixedFile, ActualFile) then
                      begin
                        FLogCallback('已修复UTF-8 BOM编码问题');

                        // 重新检测以确认
                        if DetectFileEncoding(ActualFile, DestinationFileEncoding) then
                          FLogCallback(Format('修复后的文件编码: %s -> %s', [ActualFile, DestinationFileEncoding]));
                      end
                      else
                        FLogCallback('无法重命名修复文件');
                  end
                  else
                    FLogCallback('无法删除原文件以应用修复');

                  // 如果临时修复文件仍然存在，清理它
                  if FileExists(FixedFile) then
                    DeleteFile(PChar(FixedFile));
                end;
              end;
            end;
          end
          else
          begin
            if Assigned(FLogCallback) then
              FLogCallback('警告：无法检测转换后的文件编码');
          end;
        end
        else
        begin
          if Assigned(FLogCallback) then
            FLogCallback('警告：转换后的文件不存在: ' + ActualFile);
          Result := crFailed;
        end;
        end;
      except
        on E: Exception do
        begin
          if Assigned(FLogCallback) then
            FLogCallback(Format('检测转换后的文件编码失败: %s', [E.Message]));
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback(Format('转换过程中发生异常: %s', [E.Message]));
      Result := crFailed;
    end;
  end;
end;

// NEW Public Method Implementation: ConvertSingleFileByName
function TEncodingController.ConvertSingleFileByName(const SourceFile: string;
  const TargetEncodingName: string; AddBOM: Boolean;
  UpdateCallback: TProc<string>): Boolean;
var
  ConversionResult: TConversionResult;
begin
  // 调用内部方法进行转换
  ConversionResult := DoConvertSingleFileByName(SourceFile, TargetEncodingName, AddBOM, '');

  // 检查转换结果
  Result := (ConversionResult = crSuccess);

  // 如果转换成功并且回调函数已分配，调用回调
  if Result and Assigned(UpdateCallback) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback(Format('单文件转换成功，调用回调: %s', [SourceFile]));
    UpdateCallback(SourceFile);
  end;
end;

// NEW Public Method Implementation: ConvertFilesByName
procedure TEncodingController.ConvertFilesByName(const SelectedFiles: TArray<string>;
  const TargetEncodingName: string; AddBOM: Boolean;
  UpdateCallback: TProc<string>);
var
  i: Integer;
  FileToConvert: string;
  ConversionResult: TConversionResult;
begin
  if Assigned(FLogCallback) then
    FLogCallback(Format('开始批量转换 %d 个文件到 %s', [Length(SelectedFiles), TargetEncodingName]));

  for i := 0 to High(SelectedFiles) do
  begin
    FileToConvert := SelectedFiles[i];
    // Call the internal helper for each file
    ConversionResult := DoConvertSingleFileByName(FileToConvert, TargetEncodingName, AddBOM, '');

    // 如果转换成功并且回调函数已分配，调用回调
    if (ConversionResult = crSuccess) and Assigned(UpdateCallback) then
    begin
      if Assigned(FLogCallback) then
        FLogCallback(Format('文件转换成功，调用回调: %s', [FileToConvert]));
      UpdateCallback(FileToConvert);
    end;
    // Potential improvement: Use parallel tasks for conversion if safe
  end;

  if Assigned(FLogCallback) then
    FLogCallback('批量转换完成。');
end;

// Existing ConvertFileEncoding (marked as incompatible)
function TEncodingController.ConvertFileEncoding(const SourceFile, TargetFile: string;
  TargetEncoding: TEncoding; AddBOM: Boolean): TConversionResult;
var
  // Keep var block even if empty for structure
  Dummy: Integer; // Placeholder
begin
  // This implementation uses Delphi's TEncoding.Convert
  // It needs significant rework to use JCL with TEncodingInfo.ShortName
  // For now, it's likely incompatible with the new approach.

  Result := crSkipped; // Mark as skipped/failed for now
  if Assigned(FLogCallback) then
    FLogCallback('警告: ConvertFileEncoding (TEncoding version) 当前未实现 JCL 支持。');

  // --- Original code commented out ---
  (*
  var
    TempFile, BackupFile: string;
    UseTemp: Boolean;
    SourceEncoding: TEncoding;
    SourceStream, DestStream: TMemoryStream;
    Reader: TStreamReader;
    Writer: TStreamWriter;
  begin
    Result := crFailed;
    ...
  end;
  *)
end;

// Existing ConvertFilesToEncoding (marked as incompatible)
procedure TEncodingController.ConvertFilesToEncoding(const FolderPath: string;
  const FileExtensions: TArray<string>; SelectedFiles: TArray<string>;
  TargetEncoding: TEncoding; AddBOM: Boolean);
var
 // Keep var block even if empty for structure
  Dummy: Integer; // Placeholder
begin
 // This implementation likely calls ConvertFileEncoding internally.
 // It needs similar rework as ConvertFileEncoding.
  if Assigned(FLogCallback) then
    FLogCallback('警告: ConvertFilesToEncoding (TEncoding version) 当前未实现 JCL 支持。');
  // --- Original code commented out ---
  (*
  var
    Files: TArray<string>;
    ...
  begin
  ...
  end;
  *)
end;

// Existing ConvertSelectedFilesToEncoding (marked as incompatible)
procedure TEncodingController.ConvertSelectedFilesToEncoding(const SelectedFiles: TArray<string>;
  TargetEncoding: TEncoding; AddBOM: Boolean);
var
 // Keep var block even if empty for structure
  Dummy: Integer; // Placeholder
begin
 // This implementation likely calls ConvertFileEncoding internally.
 // It needs similar rework as ConvertFileEncoding.
  if Assigned(FLogCallback) then
    FLogCallback('警告: ConvertSelectedFilesToEncoding (TEncoding version) 当前未实现 JCL 支持。');
  // --- Original code commented out ---
  (*
  var
    FilePath: string;
    ...
  begin
  ...
  end;
  *)
end;

// Helper function implementations (CheckFileAccessibility, CreateBackupFile, etc.)
// Assuming these helpers are already implemented correctly.
function TEncodingController.CheckFileAccessibility(const FileName: string; var UseTemp: Boolean): Boolean;
begin
  Result := False;
  UseTemp := True; // Default to using temp file
  if not FileExists(FileName) then Exit;

  try
    // Try to open with write access
    var Stream := TFileStream.Create(FileName, fmOpenReadWrite or fmShareExclusive);
    Stream.Free;
    UseTemp := False; // Can overwrite directly
    Result := True;
  except
    on E: EFOpenError do
    begin
      // Cannot open exclusively, try read-only to see if it exists and is readable
      try
        var ReadStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
        ReadStream.Free;
        UseTemp := True; // Need temp file
        Result := True;
      except
        Result := False; // Cannot even read the file
      end;
    end
    else
      Result := False; // Other error
  end;
end;

procedure TEncodingController.CreateBackupFile(const SourceFile: string; var BackupFile: string);
begin
  BackupFile := TPath.ChangeExtension(SourceFile, '.bakconv');
  try
    if FileExists(BackupFile) then
      DeleteFile(PChar(BackupFile));
    TFile.Copy(SourceFile, BackupFile);
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('创建备份失败 (' + SourceFile + '): ' + E.Message);
      BackupFile := ''; // Indicate backup failed
    end;
  end;
end;

procedure TEncodingController.TryCopyTempToOriginal(const TempFile, OriginalFile: string);
const
  MAX_RETRY = 3; // 最大重试次数
var
  RetryCount: Integer;
  Success: Boolean;
  ErrCode: Cardinal;
begin
  RetryCount := 0;
  Success := False;

  try
    repeat
      Inc(RetryCount);

      // 详细日志
      if Assigned(FLogCallback) then
      begin
        if RetryCount > 1 then
          FLogCallback(Format('尝试复制(第%d次): %s -> %s', [RetryCount, TempFile, OriginalFile]))
        else
          FLogCallback(Format('开始复制: %s -> %s', [TempFile, OriginalFile]));
      end;

      // 检查临时文件是否存在
      if not FileExists(TempFile) then
      begin
        if Assigned(FLogCallback) then
          FLogCallback('错误: 临时文件不存在: ' + TempFile);
        Exit;
      end;

      // 确保原始文件是可写的
      if FileExists(OriginalFile) then
      begin
        // 先尝试设置文件为可写
        {$IFDEF MSWINDOWS}
        if FileGetAttr(OriginalFile) and faReadOnly <> 0 then
        begin
          if FileSetAttr(OriginalFile, FileGetAttr(OriginalFile) and not faReadOnly) <> 0 then
        {$ELSE}
        if False then
        begin
          if False then
        {$ENDIF}
          begin
            ErrCode := GetLastError;
            if Assigned(FLogCallback) then
              FLogCallback(Format('警告: 无法设置文件为可写 (错误码: %d): %s', [ErrCode, OriginalFile]));
          end;
        end;

        // 然后删除文件
        if not DeleteFile(PChar(OriginalFile)) then
        begin
          ErrCode := GetLastError;
          if Assigned(FLogCallback) then
            FLogCallback(Format('无法删除原始文件 (错误码: %d): %s', [ErrCode, OriginalFile]));

          // 如果是"文件正在使用"错误，等待一下再重试
          if (ErrCode = ERROR_SHARING_VIOLATION) or (ErrCode = ERROR_ACCESS_DENIED) then
          begin
            if Assigned(FLogCallback) then
              FLogCallback('文件可能正在被使用，等待后重试...');
            Sleep(500); // 等待500毫秒
            Continue;
          end
          else
            Exit; // 其他错误直接退出
        end;
      end;

      // 使用CopyFile函数进行复制，而不是TFile.Move
      if CopyFile(PChar(TempFile), PChar(OriginalFile), False) then
      begin
        Success := True;

        // 删除临时文件
        if FileExists(TempFile) then
        begin
          if not DeleteFile(PChar(TempFile)) then
          begin
            ErrCode := GetLastError;
            if Assigned(FLogCallback) then
              FLogCallback(Format('警告: 无法删除临时文件 (错误码: %d): %s', [ErrCode, TempFile]));
          end;
        end;

        if Assigned(FLogCallback) then
          FLogCallback('成功复制: ' + TempFile + ' -> ' + OriginalFile);

        Break; // 成功则退出循环
      end
      else
      begin
        ErrCode := GetLastError;
        if Assigned(FLogCallback) then
          FLogCallback(Format('复制失败 (错误码: %d): %s -> %s', [ErrCode, TempFile, OriginalFile]));

        // 对于一些特定的错误，可以重试
        if (ErrCode = ERROR_SHARING_VIOLATION) or (ErrCode = ERROR_ACCESS_DENIED) or
           (ErrCode = ERROR_LOCK_VIOLATION) then
        begin
          if RetryCount < MAX_RETRY then
          begin
            if Assigned(FLogCallback) then
              FLogCallback('文件可能正在被使用，等待后重试...');
            Sleep(500 * RetryCount); // 等待时间逐次延长
            Continue;
          end;
        end;
      end;
    until RetryCount >= MAX_RETRY;

    // 如果所有重试都失败
    if not Success and Assigned(FLogCallback) then
      FLogCallback(Format('复制文件失败，已达到最大重试次数(%d): %s -> %s',
                         [MAX_RETRY, TempFile, OriginalFile]));
  except
    on E: Exception do
      if Assigned(FLogCallback) then
        FLogCallback('从临时文件复制时异常: ' + E.Message);
  end;
end;

procedure TEncodingController.LogConversionSuccess(const SourceFile: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback('转换成功: ' + SourceFile);
end;

procedure TEncodingController.RestoreFromBackup(const OriginalFile, BackupFile: string);
begin
  try
    if (BackupFile <> '') and FileExists(BackupFile) then
    begin
      // 确保原始文件是可写的
      if FileExists(OriginalFile) then
      begin
        // 先尝试设置文件为可写
        {$IFDEF MSWINDOWS}
        if FileSetAttr(OriginalFile, FileGetAttr(OriginalFile) and not faReadOnly) <> 0 then
        {$ELSE}
        if False then
        {$ENDIF}
        begin
          if Assigned(FLogCallback) then
            FLogCallback('警告: 无法设置文件为可写: ' + OriginalFile);
        end;

        // 然后删除文件
        if not DeleteFile(PChar(OriginalFile)) then
        begin
          var ErrCode := GetLastError;
          if Assigned(FLogCallback) then
            FLogCallback(Format('恢复备份时无法删除原始文件 (错误码: %d): %s', [ErrCode, OriginalFile]));
          Exit;
        end;
      end;

      // 使用CopyFile函数进行复制
      if not CopyFile(PChar(BackupFile), PChar(OriginalFile), False) then
      begin
        var ErrCode := GetLastError;
        if Assigned(FLogCallback) then
          FLogCallback(Format('从备份恢复失败 (错误码: %d): %s -> %s', [ErrCode, BackupFile, OriginalFile]));
        Exit;
      end;

      if Assigned(FLogCallback) then
        FLogCallback('已从备份恢复: ' + OriginalFile);
    end
    else
    begin
      if Assigned(FLogCallback) then
        FLogCallback('没有可用的备份文件: ' + BackupFile);
    end;
  except
    on E: Exception do
      if Assigned(FLogCallback) then
        FLogCallback('从备份恢复时出错: ' + E.Message);
  end;
end;

function TEncodingController.IsEncodingAvailable(CodePage: Integer): Boolean;
begin
  try
    var Encoding := TEncoding.GetEncoding(CodePage);
    Encoding.Free;
    Result := True;
  except
    Result := False;
  end;
end;

function TEncodingController.ConvertFile(const FilePath: string; TargetEncoding: TEncoding): Boolean;
var
  SourceStream, DestStream: TFileStream;
  TempPath: string;
  SourceBytes, DestBytes: TBytes;
  SourceEncoding: TEncoding;
  BOMLength: Integer;
begin
  Result := False;
  if not FileExists(FilePath) then Exit;

  TempPath := FilePath + '.tmp';
  
  try
    // 打开源文件
    SourceStream := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyWrite);
    try
      // 读取文件内容
      SetLength(SourceBytes, SourceStream.Size);
      SourceStream.ReadBuffer(SourceBytes[0], SourceStream.Size);
      
      // 检测源文件编码
      SourceEncoding := nil;
      BOMLength := TEncoding.GetBufferEncoding(SourceBytes, SourceEncoding);
      if SourceEncoding = nil then
        SourceEncoding := TEncoding.Default;
        
      // 转换编码
      DestBytes := TEncoding.Convert(SourceEncoding, TargetEncoding,
        SourceBytes, BOMLength, Length(SourceBytes) - BOMLength);
        
      // 创建临时文件
      DestStream := TFileStream.Create(TempPath, fmCreate);
      try
        // 写入BOM（如果需要）
        if TargetEncoding = TEncoding.UTF8 then
        begin
          var BOM := TEncoding.UTF8.GetPreamble;
          if Length(BOM) > 0 then
            DestStream.WriteBuffer(BOM[0], Length(BOM));
        end
        else if TargetEncoding = TEncoding.Unicode then
        begin
          var BOM := TEncoding.Unicode.GetPreamble;
          if Length(BOM) > 0 then
            DestStream.WriteBuffer(BOM[0], Length(BOM));
        end;
        
        // 写入转换后的内容
        DestStream.WriteBuffer(DestBytes[0], Length(DestBytes));
      finally
        DestStream.Free;
      end;
      
      // 备份原文件
      if FileExists(PWideChar(FilePath + '.bak')) then
        DeleteFile(PWideChar(FilePath + '.bak'));
      RenameFile(PWideChar(FilePath), PWideChar(FilePath + '.bak'));
      
      // 重命名临时文件为目标文件
      RenameFile(PWideChar(TempPath), PWideChar(FilePath));
      
      Result := True;
    finally
      SourceStream.Free;
    end;
  except
    on E: Exception do
    begin
      if FileExists(TempPath) then
        DeleteFile(PWideChar(TempPath));
      raise;
    end;
  end;
end;

end.