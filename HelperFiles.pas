unit HelperFiles;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, Vcl.Dialogs, Vcl.Controls,
  System.Math, System.StrUtils, System.Generics.Collections, Vcl.Forms, System.TypInfo,
  UtilsTypes, ModelEncoding, JclBOM, JclEncodingUtils, UTF8BOMConverter_Simple;

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

    // 判断文件是否是正常的文本文件
    function IsNormalTextFile(const FileName: string): Boolean;

    // 文件路径处理
    function PathWithSeparator(const Path: string): string;

    // 检查路径是否存在，不存在则创建
    function EnsurePathExists(const Path: string): Boolean;

    // 获取用户文档路径
    function GetMyDocumentsPath: string;

    // 获取应用程序根目录
    function GetRootDir: string;

    // 获取选中的文件
    function GetSelectedFilesInFolder(const FolderPath: string;
      const Extensions: TStringList;
      const FilterFunc: TFileFilterFunc = nil;
      const IncludeSubDirs: Boolean = False): TArray<string>;

    // 检测文件编码
    function DetectFileEncoding(const FileName: string; out HasBOM: Boolean): string;
  end;

implementation

uses
  Winapi.Windows, Winapi.ShlObj;

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
begin
  Extensions := TStringList.Create;
  try
    Extensions.Sorted := True;
    Extensions.Duplicates := TDuplicates.dupIgnore;

    // 安全检查：确保目录存在
    if not DirectoryExists(FolderPath) then
    begin
      if Assigned(FLogCallback) then
        FLogCallback('目录不存在: ' + FolderPath);
      SetLength(Result, 0);
      Exit;
    end;

    try
      // 仅搜索当前目录，不再使用soAllDirectories
      Files := TDirectory.GetFiles(FolderPath, '*.*', TSearchOption.soTopDirectoryOnly);

      if Assigned(FLogCallback) then
        FLogCallback('找到 ' + IntToStr(Length(Files)) + ' 个文件，正在提取扩展名');

      for i := 0 to High(Files) do
      begin
        Ext := ExtractFileExt(Files[i]);
        if Ext <> '' then
          Extensions.Add(Ext);
      end;

      SetLength(Result, Extensions.Count);
      for i := 0 to Extensions.Count - 1 do
        Result[i] := Extensions[i];

      if Assigned(FLogCallback) then
        FLogCallback('成功获取 ' + IntToStr(Extensions.Count) + ' 个不同的文件扩展名');
    except
      on E: Exception do
      begin
        if Assigned(FLogCallback) then
          FLogCallback('获取文件扩展名出错: ' + E.Message);
        SetLength(Result, 0);
      end;
    end;
  finally
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
  BytesRead, i, TotalBytes, BinaryCount: Integer;
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
     (Ext = '.ico') or (Ext = '.bmp') or (Ext = '.jpg') or
     (Ext = '.jpeg') or (Ext = '.png') or (Ext = '.gif') or
     (Ext = '.tif') or (Ext = '.tiff') or (Ext = '.zip') or
     (Ext = '.rar') or (Ext = '.7z') or (Ext = '.tar') or
     (Ext = '.gz') or (Ext = '.pdf') or (Ext = '.doc') or
     (Ext = '.docx') or (Ext = '.xls') or (Ext = '.xlsx') or
     (Ext = '.ppt') or (Ext = '.pptx') or (Ext = '.db') or
     (Ext = '.sqlite') or (Ext = '.mdb') or (Ext = '.accdb') then
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
      TotalBytes := 0;
      BinaryCount := 0;

      // 检查前4KB数据
      BytesRead := FileStream.Read(Buffer[0], BUFFER_SIZE);
      TotalBytes := BytesRead;

      // 检查每个字节是否为二进制数据
      for i := 0 to BytesRead - 1 do
      begin
        // ASCII控制字符(除了制表符、换行和回车)通常不会出现在文本文件中
        if (Buffer[i] < 9) or ((Buffer[i] > 13) and (Buffer[i] < 32)) then
          Inc(BinaryCount);
      end;

      // 计算二进制字节占比
      if TotalBytes > 0 then
        BinaryRatio := BinaryCount / TotalBytes
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

function TFileHelper.DetectFileEncoding(const FileName: string; out HasBOM: Boolean): string;
var
  FileStream: TFileStream;
  BOMType: TJclBOMType;
  IsUTF8: Boolean;
  FileExt: string;
begin
  // 记录日志
  if Assigned(FLogCallback) then
    FLogCallback(Format('检测文件编码: %s', [FileName]));

  // 获取文件扩展名
  FileExt := LowerCase(ExtractFileExt(FileName));
  if Assigned(FLogCallback) then
    FLogCallback(Format('文件扩展名: %s', [FileExt]));

  try
    // 首先检查是否有BOM
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      BOMType := JclBOM.DetectBOM(FileStream);
      HasBOM := BOMType <> JclBOM.bomAnsi;

      if Assigned(FLogCallback) then
        FLogCallback(Format('BOM检测结果: %s', [GetEnumName(TypeInfo(TJclBOMType), Ord(BOMType))]));

      // 根据BOM确定编码
      case BOMType of
        bomUTF8: Result := 'UTF-8 with BOM';
        bomUTF16LE: Result := 'UTF-16LE';
        bomUTF16BE: Result := 'UTF-16BE';
        bomUTF32LE: Result := 'UTF-32LE';
        bomUTF32BE: Result := 'UTF-32BE';
        else
          // 对于特定的文本文件类型，优先考虑UTF-8
          if (FileExt = '.md') or (FileExt = '.txt') or (FileExt = '.json') or
             (FileExt = '.xml') or (FileExt = '.html') or (FileExt = '.htm') or
             (FileExt = '.css') or (FileExt = '.js') or (FileExt = '.ts') or
             (FileExt = '.yaml') or (FileExt = '.yml') then
          begin
            // 使用改进的UTF-8检测器
            if Assigned(FLogCallback) then
              FLogCallback('文件类型适合UTF-8，使用改进的UTF-8检测器');

            IsUTF8 := TUTF8BOMConverter.IsUTF8File(FileName, HasBOM);

            if Assigned(FLogCallback) then
              FLogCallback(Format('UTF-8检测结果: %s', [BoolToStr(IsUTF8, True)]));

            if IsUTF8 then
              Result := 'UTF-8'
            else
              // 如果不是UTF-8，使用JCL的检测函数
              Result := JclEncodingUtils.DetectFileEncoding(FileName);
          end
          else
          begin
            // 对于其他类型的文件，先使用JCL的检测函数
            if Assigned(FLogCallback) then
              FLogCallback('使用JCL编码检测函数');

            Result := JclEncodingUtils.DetectFileEncoding(FileName);

            // 如果JCL检测为ANSI，再尝试使用UTF-8检测器
            if (Result = 'ANSI') or (Result = '') then
            begin
              if Assigned(FLogCallback) then
                FLogCallback('JCL检测为ANSI，尝试使用UTF-8检测器');

              IsUTF8 := TUTF8BOMConverter.IsUTF8File(FileName, HasBOM);

              if Assigned(FLogCallback) then
                FLogCallback(Format('UTF-8检测结果: %s', [BoolToStr(IsUTF8, True)]));

              if IsUTF8 then
                Result := 'UTF-8';
            end;
          end;
      end;

      // 记录详细日志
      if Assigned(FLogCallback) then
        FLogCallback(Format('检测到文件 %s 的编码为: %s (BOM: %s)',
          [ExtractFileName(FileName), Result, BoolToStr(HasBOM, True)]));
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

end.
