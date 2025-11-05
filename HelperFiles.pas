unit HelperFiles;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, Vcl.Dialogs, Vcl.Controls,
  System.Math, System.StrUtils, System.Generics.Collections, Vcl.Forms, System.TypInfo,
  System.DateUtils, Winapi.Windows,
  UtilsTypes, ModelEncoding,
  UtilsEncodingTypes,
  UtilsEncodingBOM_Improved,
  UtilsEncodingUTF8Detector_Improved,
  ChineseEncodingDetector_Improved,
  EncodingConverter_Improved;

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
      TargetEncoding: System.SysUtils.TEncoding; AddBOM: Boolean): Boolean;

    // 批量转换文件
    function BatchConvert(const Files: TArray<string>;
      TargetEncoding: System.SysUtils.TEncoding; AddBOM: Boolean): Integer;

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

  // 添加最大文本文件大小常量 (10MB) - 增加以支持更大文件
  MAX_TEXT_FILE_SIZE = 10 * 1024 * 1024;
  // 添加二进制检测阈值 (超过5%的字节是二进制则判定为二进制文件)
  BINARY_THRESHOLD = 0.05;
  // 最小有效文本文件大小 (10字节)
  MIN_TEXT_FILE_SIZE = 10;
  // 每次读取的缓冲区大小 - 增加到64KB以提高性能
  BUFFER_SIZE = 64 * 1024;

{ TFileHelper }

constructor TFileHelper.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := ALogCallback;

  if Assigned(FLogCallback) then
    FLogCallback('File helper initialized with improved encoding detection');
end;

destructor TFileHelper.Destroy;
begin
  inherited;
end;

function TFileHelper.BatchConvert(const Files: TArray<string>;
  TargetEncoding: System.SysUtils.TEncoding; AddBOM: Boolean): Integer;
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
  TargetEncoding: System.SysUtils.TEncoding; AddBOM: Boolean): Boolean;
var
  SourceEncoding: string;
  TargetEncodingName: string;
  HasBOM: Boolean;
  StartTime: TDateTime;
  ElapsedTime: Int64;
  Options: TEncodingConversionOptions;
  ConvResult: TEncodingConversionResult;
  CP: Integer;
begin
  Result := False;
  StartTime := Now;

  try
    // 检查是否为正常文本文件
    if not IsNormalTextFile(SourceFile) then
    begin
      if Assigned(FLogCallback) then
        FLogCallback('Skip non-text file: ' + SourceFile);
      Exit;
    end;

    // 检测源文件编码
    SourceEncoding := DetectFileEncoding(SourceFile, HasBOM);
    if (SourceEncoding = ENCODING_UNKNOWN) then
    begin
      if Assigned(FLogCallback) then
      begin
        FLogCallback('Cannot detect file encoding: ' + SourceFile);
      end;
      Exit;
    end;

    // 确定目标编码名称（与 EncodingConverter_Improved 保持一致）
    TargetEncodingName := ENCODING_ANSI; // 默认 ANSI

    if Assigned(TargetEncoding) then
    begin
      if TargetEncoding is System.SysUtils.TUTF8Encoding then
      begin
        if AddBOM then
          TargetEncodingName := ENCODING_UTF8_BOM
        else
          TargetEncodingName := ENCODING_UTF8;
      end
      else if TargetEncoding is System.SysUtils.TUnicodeEncoding then
        TargetEncodingName := ENCODING_UTF16_LE
      else if TargetEncoding is System.SysUtils.TBigEndianUnicodeEncoding then
        TargetEncodingName := ENCODING_UTF16_BE
      else
        TargetEncodingName := ENCODING_ANSI;
    end;

    // 使用改进的编码转换器执行转换
    Options := TEncodingConverter_Improved.CreateDefaultOptions;
    Options.AddBOM := AddBOM;
    Options.DetectSourceEncoding := True;

    ConvResult := TEncodingConverter_Improved.ConvertFile(
      SourceFile, TargetFile, '', TargetEncodingName, Options);

    if ConvResult.Success then
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
      begin
        if ConvResult.ErrorCount > 0 then
          FLogCallback(Format('编码转换失败: %s', [ConvResult.Errors[High(ConvResult.Errors)].ErrorMessage]))
        else
          FLogCallback('Encoding conversion failed');
      end;
    end;
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('Conversion exception: ' + SourceFile + ' - ' + E.Message);
      Result := False;
    end;
  end;
end;

function TFileHelper.DetectFileEncoding(const FileName: string; out HasBOM: Boolean): string;
var
  StartTime: TDateTime;
  ElapsedTime: Int64;
  BOMResult: TBOMDetectionResult;
  UTF8Result: TUTF8DetectionResult;
  CNResult: TChineseEncodingResult;
begin
  StartTime := Now;

  try
    // 首先检查文件是否存在
    if not FileExists(FileName) then
    begin
      if Assigned(FLogCallback) then
        FLogCallback(Format('文件不存在: %s', [FileName]));
      Result := ENCODING_UNKNOWN;
      HasBOM := False;
      Exit;
    end;

    // 1) BOM 检测（优先且最快）
    BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromFile(FileName);
    if BOMResult.BOMType <> 0 then
    begin
      Result := BOMResult.Encoding;
      HasBOM := True;
      // 不再记录每个文件的日志，减少性能开销
      Exit;
    end;

    // 2) UTF-8 检测
    UTF8Result := TUTF8EncodingDetector_Improved.DetectFile(FileName);
    if UTF8Result.IsUTF8 then
    begin
      Result := ENCODING_UTF8;
      HasBOM := UTF8Result.HasBOM;
      Exit;
    end;

    // 3) 中文编码综合检测（GBK/GB18030/Big5/GB2312）
    CNResult := TChineseEncodingDetector_Improved.DetectFile(FileName);
    if CNResult.Encoding <> ENCODING_UNKNOWN then
    begin
      Result := CNResult.Encoding;
      HasBOM := CNResult.HasBOM;
      Exit;
    end;

    // 4) 默认回退到 ANSI
    Result := ENCODING_ANSI;
    HasBOM := False;
  except
    on E: Exception do
    begin
      // 如果检测失败，使用默认值
      Result := ENCODING_UNKNOWN;
      HasBOM := False;

      // 只记录严重错误，避免日志过多
      // 不再记录每个文件的检测失败信息
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
        FLogCallback('Created directory: ' + Path);
    except
      on E: Exception do
      begin
        if Assigned(FLogCallback) then
          FLogCallback('Create directory failed: ' + Path + ' - ' + E.Message);
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
      FLogCallback('Error: Provided directory path is empty');
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
        FLogCallback('Path format error: ' + E.Message);
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
        FLogCallback('Directory does not exist: ' + SafePath);
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
            FLogCallback('Failed to get file list: ' + E.Message);
          Exit;
        end;
      end;

      if Assigned(FLogCallback) then
        FLogCallback('Found ' + IntToStr(Length(Files)) + ' files, extracting extensions');

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
          FLogCallback('No file extensions found');
        Exit;
      end;

      // 转换为数组
      try
        SetLength(Result, Extensions.Count);
        for i := 0 to Extensions.Count - 1 do
          Result[i] := Extensions[i];

        if Assigned(FLogCallback) then
          FLogCallback('Got ' + IntToStr(Extensions.Count) + ' distinct file extensions');
      except
        on E: Exception do
        begin
          if Assigned(FLogCallback) then
            FLogCallback('Error converting extensions to array: ' + E.Message);
          SetLength(Result, 0);
        end;
      end;
    except
      on E: Exception do
      begin
        if Assigned(FLogCallback) then
          FLogCallback('Error getting file extensions: ' + E.Message);
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
    FLogCallback('Start searching files: ' + FolderPath +
                 ', include subdirectories: ' + BoolToStr(IncludeSubdirs, True) +
                 ', extensions: ' + IntToStr(Length(Extensions)));

  FilteredFiles := TList<string>.Create;
  try
    // 使用SearchOption参数来控制是否搜索子目录
    Files := TDirectory.GetFiles(FolderPath, '*.*', SearchOption);

    if Assigned(FLogCallback) then
      FLogCallback('Found ' + IntToStr(Length(Files)) + ' files');

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
      FLogCallback('After filtering: ' + IntToStr(FilteredFiles.Count) + ' files match');

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
        FLogCallback('Skip non-text file: ' + FileName + ' (binary ratio: ' +
                     FormatFloat('0.00%', BinaryRatio * 100) + ')');

    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      // 如果无法读取文件，认为它不是正常文本文件
      if Assigned(FLogCallback) then
        FLogCallback('Cannot analyze file: ' + FileName + ' - ' + E.Message);
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
      FLogCallback('Root directory found: ' + Result);
  end
  else
  begin
    // 如果没有找到ini目录，则使用当前目录
    Result := ExeDir;
    if Assigned(FLogCallback) then
      FLogCallback('INI directory not found, use application directory as root: ' + Result);
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
