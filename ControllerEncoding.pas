unit ControllerEncoding;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, ModelEncoding, UtilsUTF8, Winapi.Windows, UtilsIconv;

type
  // 编码控制器类
  TEncodingController = class
  private
    // 日志记录回调
    FLogCallback: TProc<string>;
    
    // iconv库封装器
    FIconvHelper: TIconvHelper;
    
    // 内部编码转换辅助函数
    function CheckFileAccessibility(const FileName: string; var UseTemp: Boolean): Boolean;
    procedure CreateBackupFile(const SourceFile: string; var BackupFile: string);
    procedure TryCopyTempToOriginal(const TempFile, OriginalFile: string);
    procedure LogConversionSuccess(const SourceFile: string);
    procedure RestoreFromBackup(const OriginalFile, BackupFile: string);
    
    // 使用iconv进行编码转换
    function ConvertWithIconv(const SourceFile, TargetFile: string;
      const SourceEncoding, TargetEncoding: string; AddBOM: Boolean): Boolean;
    
  public
    constructor Create(ALogCallback: TProc<string>);
    destructor Destroy; override;
    
    // 判断文件是否在不支持列表中
    function IsUnsupportedFile(const Filename: string): Boolean;
    
    // 检查文件是否有BOM标记
    function HasBOM(const FileName: string; Encoding: TEncoding = nil): Boolean;
    
    // 检测文件编码 - 使用iconv
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
  end;

implementation

{ TEncodingController }

constructor TEncodingController.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := ALogCallback;
  
  // 创建iconv帮助器
  FIconvHelper := TIconvHelper.Create;
  
  // 记录日志
  if Assigned(FLogCallback) then
    FLogCallback('iconv库已初始化');
end;

destructor TEncodingController.Destroy;
begin
  // 释放iconv帮助器
  FIconvHelper.Free;
  
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
begin
  // 使用iconv库检测文件编码
  try
    if not FileExists(FileName) then
    begin
      EncodingName := '';
      Result := False;
      Exit;
    end;
    
    // 调用iconv的编码检测方法
    Result := FIconvHelper.DetectFileEncoding(FileName, EncodingName);
    
    if Result and Assigned(FLogCallback) then
      FLogCallback('iconv检测到文件编码: ' + FileName + ' -> ' + EncodingName);
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('编码检测出错: ' + E.Message);
      EncodingName := '';
      Result := False;
    end;
  end;
end;

function TEncodingController.ConvertWithIconv(const SourceFile, TargetFile: string;
  const SourceEncoding, TargetEncoding: string; AddBOM: Boolean): Boolean;
var
  SourceContent, TargetContent: TBytes;
  BOM: TBytes;
  BOMStream: TFileStream;
begin
  Result := False;
  
  try
    if not FileExists(SourceFile) then
      Exit;
      
    // 读取源文件内容
    SourceContent := TFile.ReadAllBytes(SourceFile);
    
    // 使用iconv进行编码转换
    if FIconvHelper.ConvertEncoding(SourceContent, SourceEncoding, TargetEncoding, TargetContent) then
    begin
      // 写入目标文件，考虑BOM
      if AddBOM then
      begin
        if TargetEncoding = 'UTF-8' then
          BOM := TEncoding.UTF8.GetPreamble
        else if (TargetEncoding = 'UTF-16LE') or (TargetEncoding = 'UTF-16') then
          BOM := TEncoding.Unicode.GetPreamble
        else if TargetEncoding = 'UTF-16BE' then
          BOM := TEncoding.BigEndianUnicode.GetPreamble
        else
          SetLength(BOM, 0);
          
        if Length(BOM) > 0 then
        begin
          // 先创建文件并写入BOM
          BOMStream := TFileStream.Create(TargetFile, fmCreate);
          try
            BOMStream.WriteBuffer(BOM[0], Length(BOM));
            BOMStream.WriteBuffer(TargetContent[0], Length(TargetContent));
          finally
            BOMStream.Free;
          end;
        end else
          TFile.WriteAllBytes(TargetFile, TargetContent);
      end else
        TFile.WriteAllBytes(TargetFile, TargetContent);
        
      Result := True;
    end;
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('iconv转换出错: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TEncodingController.ConvertFileEncoding(const SourceFile, TargetFile: string; 
  TargetEncoding: TEncoding; AddBOM: Boolean): TConversionResult;
var
  TempFile, BackupFile: string;
  UseTemp: Boolean;
  SourceCodePage, TargetCodePage: Integer;
  SourceEncodingName, TargetEncodingName: string;
begin
  Result := crFailed;
  
  // 文件不存在或在不支持列表中
  if not FileExists(SourceFile) or IsUnsupportedFile(SourceFile) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('跳过: ' + SourceFile + ' (不支持的文件类型或文件不存在)');
    Result := crSkipped;
    Exit;
  end;
  
  // 检查输入参数
  if not Assigned(TargetEncoding) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('错误: 目标编码不能为nil');
    Exit;
  end;
  
  // 检查文件访问权限
  if not CheckFileAccessibility(SourceFile, UseTemp) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('错误: 无法访问文件: ' + SourceFile);
    Exit;
  end;
  
  TempFile := SourceFile + '.tmp';
  BackupFile := '';
  
  try
    // 使用iconv检测源文件编码
    if not DetectFileEncoding(SourceFile, SourceEncodingName) then
    begin
      if Assigned(FLogCallback) then
        FLogCallback('警告: 无法检测文件编码: ' + SourceFile);
      SourceEncodingName := 'UTF-8'; // 默认假设UTF-8
    end;
    
    // 获取目标编码名称
    if TargetEncoding = TEncoding.UTF8 then
      TargetEncodingName := 'UTF-8'
    else if TargetEncoding = TEncoding.Unicode then
      TargetEncodingName := 'UTF-16LE'
    else if TargetEncoding = TEncoding.BigEndianUnicode then
      TargetEncodingName := 'UTF-16BE'
    else if TargetEncoding = TEncoding.ASCII then
      TargetEncodingName := 'ASCII'
    else
      TargetEncodingName := 'UTF-8'; // 默认UTF-8
    
    // 记录源和目标编码信息
    if Assigned(FLogCallback) then
      FLogCallback('转换文件: ' + SourceFile + ' 从 ' + SourceEncodingName + ' 到 ' + TargetEncodingName);
    
    // 创建临时文件进行转换
    if UseTemp then
    begin
      // 使用iconv直接转换文件
      if ConvertWithIconv(SourceFile, TempFile, SourceEncodingName, TargetEncodingName, AddBOM) then
      begin
        // 转换成功，将临时文件复制到目标位置
        if SourceFile = TargetFile then
        begin
          // 创建备份
          CreateBackupFile(SourceFile, BackupFile);
          
          // 复制临时文件到原始位置
          TryCopyTempToOriginal(TempFile, SourceFile);
          
          // 尝试获取代码页信息用于日志
          SourceCodePage := 0;
          TargetCodePage := 0;
          
          try
            if SourceEncodingName = 'UTF-8' then
              SourceCodePage := 65001
            else if SourceEncodingName = 'UTF-16LE' then
              SourceCodePage := 1200
            else if SourceEncodingName = 'UTF-16BE' then
              SourceCodePage := 1201;
              
            if TargetEncodingName = 'UTF-8' then
              TargetCodePage := 65001
            else if TargetEncodingName = 'UTF-16LE' then
              TargetCodePage := 1200
            else if TargetEncodingName = 'UTF-16BE' then
              TargetCodePage := 1201;
          except
            // 忽略代码页解析错误
          end;
          
          // 记录转换成功
          LogConversionSuccess(SourceFile);
          Result := crSuccess;
        end
        else
        begin
          // 目标文件与源文件不同，直接转换
          if ConvertWithIconv(SourceFile, TargetFile, SourceEncodingName, TargetEncodingName, AddBOM) then
          begin
            // 记录转换成功
            if Assigned(FLogCallback) then
              FLogCallback('转换成功: ' + SourceFile + ' → ' + TargetFile);
            Result := crSuccess;
          end;
        end;
        
        // 删除临时文件
        if FileExists(TempFile) then
        begin
          try
            TFile.Delete(TempFile);
          except
            // 忽略临时文件删除失败
          end;
        end;
      end;
    end
    else
    begin
      // 不需要临时文件的情况，直接转换
      if ConvertWithIconv(SourceFile, TargetFile, SourceEncodingName, TargetEncodingName, AddBOM) then
      begin
        // 记录转换成功
        if Assigned(FLogCallback) then
          FLogCallback('转换成功: ' + SourceFile + ' → ' + TargetFile);
        Result := crSuccess;
      end;
    end;
  except
    on E: Exception do
    begin
      // 转换失败，恢复备份
      if (BackupFile <> '') and FileExists(BackupFile) then
        RestoreFromBackup(SourceFile, BackupFile);
        
      if Assigned(FLogCallback) then
        FLogCallback('转换失败: ' + SourceFile + ' - ' + E.Message);
    end;
  end;
end;

function TEncodingController.CheckFileAccessibility(const FileName: string; var UseTemp: Boolean): Boolean;
var
  FileHandle: THandle;
begin
  Result := True;
  UseTemp := False;
  
  if not FileExists(FileName) then
    Exit(False);
    
  try
    // 尝试以独占模式打开文件
    FileHandle := FileOpen(FileName, fmOpenReadWrite);
    if FileHandle = THandle(-1) then
    begin
      // 文件可能被其他进程锁定，使用临时文件
      UseTemp := True;
    end
    else
      FileClose(FileHandle);
  except
    // 如果出现异常，也使用临时文件
    UseTemp := True;
  end;
end;

procedure TEncodingController.CreateBackupFile(const SourceFile: string; var BackupFile: string);
begin
  BackupFile := SourceFile + '.bak';
  try
    if FileExists(BackupFile) then
      TFile.Delete(BackupFile);
    TFile.Copy(SourceFile, BackupFile);
  except
    BackupFile := '';
    if Assigned(FLogCallback) then
      FLogCallback('警告: 无法创建备份文件: ' + SourceFile);
  end;
end;

procedure TEncodingController.TryCopyTempToOriginal(const TempFile, OriginalFile: string);
var
  RetryCount: Integer;
begin
  RetryCount := 0;
  
  while RetryCount < 3 do
  begin
    try
      TFile.Copy(TempFile, OriginalFile, True);
      Break;
    except
      Inc(RetryCount);
      
      if RetryCount >= 3 then
      begin
        if Assigned(FLogCallback) then
          FLogCallback('错误: 无法将临时文件复制到原始位置: ' + OriginalFile);
        raise;
      end;
      
      // 等待一段时间后重试
      Sleep(100);
    end;
  end;
end;

procedure TEncodingController.LogConversionSuccess(const SourceFile: string);
begin
  // 记录日志
  if Assigned(FLogCallback) then
    FLogCallback('✓ 转换成功: ' + ExtractFileName(SourceFile));
end;

procedure TEncodingController.RestoreFromBackup(const OriginalFile, BackupFile: string);
begin
  try
    if FileExists(BackupFile) then
    begin
      TFile.Copy(BackupFile, OriginalFile, True);
      TFile.Delete(BackupFile);
      
      if Assigned(FLogCallback) then
        FLogCallback('已从备份还原: ' + OriginalFile);
    end;
  except
    if Assigned(FLogCallback) then
      FLogCallback('无法从备份还原: ' + OriginalFile);
  end;
end;

procedure TEncodingController.ConvertFilesToEncoding(const FolderPath: string;
  const FileExtensions: TArray<string>; SelectedFiles: TArray<string>;
  TargetEncoding: TEncoding; AddBOM: Boolean);
var
  Files: TArray<string>;
  FilePath: string;
  Count, Total: Integer;
  Extensions: string;
begin
  // 验证参数
  if not DirectoryExists(FolderPath) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('错误: 目录不存在: ' + FolderPath);
    Exit;
  end;
  
  if Length(FileExtensions) = 0 then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('错误: 未指定任何文件扩展名');
    Exit;
  end;
  
  // 记录操作信息
  Extensions := string.Join(', ', FileExtensions);
  if Assigned(FLogCallback) then
    FLogCallback('开始转换目录中的文件: ' + FolderPath);
    
  if Assigned(FLogCallback) then
    FLogCallback('文件类型: ' + Extensions);
    
  // 获取文件列表
  Files := SelectedFiles;
  if Length(Files) = 0 then
  begin
    Files := TDirectory.GetFiles(FolderPath, '*.*', TSearchOption.soTopDirectoryOnly);
    
    // 过滤文件扩展名
    var TempFiles: TArray<string> := [];
    for var FileName in Files do
    begin
      var Ext := LowerCase(ExtractFileExt(FileName));
      if Ext <> '' then
        Ext := Ext.Substring(1); // 移除点号
        
      for var AllowedExt in FileExtensions do
      begin
        if SameText(Ext, AllowedExt) then
        begin
          SetLength(TempFiles, Length(TempFiles) + 1);
          TempFiles[High(TempFiles)] := FileName;
          Break;
        end;
      end;
    end;
    
    Files := TempFiles;
  end;
  
  // 记录文件总数
  Total := Length(Files);
  Count := 0;
  
  if Assigned(FLogCallback) then
    FLogCallback('找到 ' + IntToStr(Total) + ' 个文件');
    
  // 开始转换每个文件
  for FilePath in Files do
  begin
    Inc(Count);
    
    if Assigned(FLogCallback) then
      FLogCallback('处理文件 ' + IntToStr(Count) + '/' + IntToStr(Total) + ': ' + ExtractFileName(FilePath));
      
    // 转换文件编码
    case ConvertFileEncoding(FilePath, FilePath, TargetEncoding, AddBOM) of
      crSuccess: 
        if Assigned(FLogCallback) then
          FLogCallback('✅ 成功转换: ' + ExtractFileName(FilePath));
      crSkipped: 
        if Assigned(FLogCallback) then
          FLogCallback('⏭️ 跳过: ' + ExtractFileName(FilePath));
      crFailed: 
        if Assigned(FLogCallback) then
          FLogCallback('❌ 转换失败: ' + ExtractFileName(FilePath));
    end;
  end;
  
  if Assigned(FLogCallback) then
    FLogCallback('转换完成');
end;

procedure TEncodingController.ConvertSelectedFilesToEncoding(const SelectedFiles: TArray<string>;
  TargetEncoding: TEncoding; AddBOM: Boolean);
var
  FilePath: string;
  Count, Total: Integer;
begin
  // 记录操作信息
  if Assigned(FLogCallback) then
    FLogCallback('开始转换选中的文件');
    
  // 记录文件总数
  Total := Length(SelectedFiles);
  Count := 0;
  
  if Assigned(FLogCallback) then
    FLogCallback('找到 ' + IntToStr(Total) + ' 个选中的文件');
    
  // 开始转换每个文件
  for FilePath in SelectedFiles do
  begin
    Inc(Count);
    
    if Assigned(FLogCallback) then
      FLogCallback('处理文件 ' + IntToStr(Count) + '/' + IntToStr(Total) + ': ' + ExtractFileName(FilePath));
      
    // 转换文件编码
    case ConvertFileEncoding(FilePath, FilePath, TargetEncoding, AddBOM) of
      crSuccess: 
        if Assigned(FLogCallback) then
          FLogCallback('✅ 成功转换: ' + ExtractFileName(FilePath));
      crSkipped: 
        if Assigned(FLogCallback) then
          FLogCallback('⏭️ 跳过: ' + ExtractFileName(FilePath));
      crFailed: 
        if Assigned(FLogCallback) then
          FLogCallback('❌ 转换失败: ' + ExtractFileName(FilePath));
    end;
  end;
  
  if Assigned(FLogCallback) then
    FLogCallback('转换完成');
end;

end. 