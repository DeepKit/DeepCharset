unit ControllerEncoding;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, ModelEncoding, UtilsUTF8, Winapi.Windows;

type
  // 编码控制器类
  TEncodingController = class
  private
    // 日志记录回调
    FLogCallback: TProc<string>;
    
    // 内部编码转换辅助函数
    function CheckFileAccessibility(const FileName: string; var UseTemp: Boolean): Boolean;
    function CreateTemporaryFileCopy(const SourceFile, TempFile: string): Boolean;
    function DetectSourceCodePage(const FileName: string; SourceEncoding: TEncoding): Integer;
    procedure HandleGB2312Encoding(SourceCodePage: Integer; var SourceEncoding: TEncoding);
    function ShouldSkipConversion(const SourceFile, TargetFile: string; 
      SourceEncoding, TargetEncoding: TEncoding; AddBOM, UseTemp: Boolean): Boolean;
    procedure CreateBackupFile(const SourceFile: string; var BackupFile: string);
    function ReadFileContent(const FileName: string; var Buffer: TBytes): Boolean;
    function ProcessFileContent(const Buffer: TBytes; const FileName: string;
      var SourceEncoding: TEncoding; SourceCodePage: Integer): string;
    procedure HandleLineEndings(const FileName: string; var Content: string);
    function WriteConvertedContent(const Content: string; const TargetPath: string; 
      TargetEncoding: TEncoding; AddBOM: Boolean): Boolean;
    procedure TryCopyTempToOriginal(const TempFile, OriginalFile: string);
    procedure LogConversionSuccess(const SourceFile: string; SourceCodePage, TargetCodePage: Integer; AddBOM: Boolean);
    procedure RestoreFromBackup(const OriginalFile, BackupFile: string);
    
  public
    constructor Create(ALogCallback: TProc<string>);
    
    // 判断文件是否在不支持列表中
    function IsUnsupportedFile(const Filename: string): Boolean;
    
    // 检查文件是否有BOM标记
    function HasBOM(const FileName: string; Encoding: TEncoding = nil): Boolean;
    
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

function TEncodingController.CreateTemporaryFileCopy(const SourceFile, TempFile: string): Boolean;
begin
  try
    TFile.Copy(SourceFile, TempFile, True);
    Result := True;
  except
    if Assigned(FLogCallback) then
      FLogCallback('创建临时文件副本失败: ' + SourceFile);
    Result := False;
  end;
end;

function TEncodingController.DetectSourceCodePage(const FileName: string; SourceEncoding: TEncoding): Integer;
begin
  try
    if SourceEncoding = TEncoding.UTF8 then
      Result := 65001
    else if SourceEncoding = TEncoding.Unicode then
      Result := 1200
    else if SourceEncoding = TEncoding.BigEndianUnicode then
      Result := 1201
    else if SourceEncoding = TEncoding.ASCII then
      Result := 20127
    else if SourceEncoding = TEncoding.UTF7 then
      Result := 65000
    else if SourceEncoding = nil then
      Result := 0
    else
      Result := SourceEncoding.CodePage;
  except
    Result := 0; // 未知代码页
  end;
end;

procedure TEncodingController.HandleGB2312Encoding(SourceCodePage: Integer; var SourceEncoding: TEncoding);
begin
  // 特殊处理GB2312编码
  if SourceCodePage = 936 then
  begin
    try
      SourceEncoding := TEncoding.GetEncoding(936);
    except
      if Assigned(FLogCallback) then
        FLogCallback('警告: 无法创建GB2312编码，将使用默认编码');
    end;
  end;
end;

function TEncodingController.ShouldSkipConversion(const SourceFile, TargetFile: string; 
  SourceEncoding, TargetEncoding: TEncoding; AddBOM, UseTemp: Boolean): Boolean;
var
  SourceBOM, TargetBOM: Boolean;
begin
  Result := False;
  
  // 检查源文件和目标文件是否相同
  if (SourceFile = TargetFile) and not UseTemp then
  begin
    // 检查编码是否相同
    if SourceEncoding = TargetEncoding then
    begin
      // 检查BOM标记是否匹配
      SourceBOM := HasBOM(SourceFile, SourceEncoding);
      TargetBOM := AddBOM;
      
      if SourceBOM = TargetBOM then
      begin
        if Assigned(FLogCallback) then
          FLogCallback('跳过: ' + SourceFile + ' (编码已匹配)');
        Result := True;
      end;
    end;
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

function TEncodingController.ReadFileContent(const FileName: string; var Buffer: TBytes): Boolean;
begin
  try
    Buffer := TFile.ReadAllBytes(FileName);
    Result := True;
  except
    if Assigned(FLogCallback) then
      FLogCallback('读取文件失败: ' + FileName);
    Result := False;
  end;
end;

function TEncodingController.ProcessFileContent(const Buffer: TBytes; const FileName: string;
  var SourceEncoding: TEncoding; SourceCodePage: Integer): string;
begin
  try
    // 检测编码
    DetectEncodingFromBytes(Buffer, SourceEncoding);
    
    // 特殊处理GB2312
    HandleGB2312Encoding(SourceCodePage, SourceEncoding);
    
    // 从缓冲区读取文本
    Result := SourceEncoding.GetString(Buffer);
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('处理文件内容错误: ' + E.Message);
      Result := '';
    end;
  end;
end;

procedure TEncodingController.HandleLineEndings(const FileName: string; var Content: string);
var
  HasCR, HasLF, HasCRLF: Boolean;
begin
  // 检测行尾类型
  HasCR := Pos(#13, Content) > 0;
  HasLF := Pos(#10, Content) > 0;
  HasCRLF := Pos(#13#10, Content) > 0;
  
  // 保持原始行尾类型
  // 如果是混合类型，统一转换为CRLF
  if HasCR and HasLF and not HasCRLF then
  begin
    Content := StringReplace(Content, #13, '', [rfReplaceAll]);
    Content := StringReplace(Content, #10, #13#10, [rfReplaceAll]);
    if Assigned(FLogCallback) then
      FLogCallback('转换: ' + FileName + ' 行尾从混合模式转为CRLF');
  end;
end;

function TEncodingController.WriteConvertedContent(const Content: string; const TargetPath: string; 
  TargetEncoding: TEncoding; AddBOM: Boolean): Boolean;
var
  Stream: TFileStream;
  Preamble: TBytes;
  EncodedBytes: TBytes;
begin
  Result := False;
  
  try
    Stream := TFileStream.Create(TargetPath, fmCreate);
    try
      // 写入BOM（如果需要）
      if AddBOM then
      begin
        Preamble := TargetEncoding.GetPreamble;
        if Length(Preamble) > 0 then
          Stream.WriteBuffer(Preamble[0], Length(Preamble));
      end;
      
      // 编码并写入内容
      EncodedBytes := TargetEncoding.GetBytes(Content);
      if Length(EncodedBytes) > 0 then
        Stream.WriteBuffer(EncodedBytes[0], Length(EncodedBytes));
        
      Result := True;
    finally
      Stream.Free;
    end;
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('写入文件失败: ' + TargetPath + ', 错误: ' + E.Message);
    end;
  end;
end;

procedure TEncodingController.TryCopyTempToOriginal(const TempFile, OriginalFile: string);
begin
  try
    TFile.Copy(TempFile, OriginalFile, True);
    TFile.Delete(TempFile);
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('无法复制临时文件到原始文件: ' + E.Message);
    end;
  end;
end;

procedure TEncodingController.LogConversionSuccess(const SourceFile: string; SourceCodePage, TargetCodePage: Integer; AddBOM: Boolean);
var
  BOMStr: string;
begin
  if AddBOM then
    BOMStr := ' BOM'
  else
    BOMStr := '';
    
  if Assigned(FLogCallback) then
    FLogCallback('转换成功: ' + SourceFile + 
                 ' (从 CodePage-' + IntToStr(SourceCodePage) + 
                 ' 到 CodePage-' + IntToStr(TargetCodePage) + BOMStr + ')');
end;

procedure TEncodingController.RestoreFromBackup(const OriginalFile, BackupFile: string);
begin
  try
    if (BackupFile <> '') and FileExists(BackupFile) then
    begin
      TFile.Copy(BackupFile, OriginalFile, True);
      TFile.Delete(BackupFile);
    end;
  except
    if Assigned(FLogCallback) then
      FLogCallback('无法从备份恢复: ' + OriginalFile);
  end;
end;

function TEncodingController.ConvertFileEncoding(const SourceFile, TargetFile: string; 
  TargetEncoding: TEncoding; AddBOM: Boolean): TConversionResult;
var
  SourceEncoding: TEncoding;
  Buffer: TBytes;
  Content: string;
  BackupFile, TempFile: string;
  UseTemp: Boolean;
  TargetPath: string;
  SourceCodePage, TargetCodePage: Integer;
begin
  // 默认返回值
  Result := crFailed;
  
  // 检查文件是否存在
  if not FileExists(SourceFile) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('文件不存在: ' + SourceFile);
    Exit;
  end;
  
  // 检查是否不支持的文件
  if IsUnsupportedFile(SourceFile) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('跳过不支持的文件: ' + SourceFile);
    Result := crSkipped;
    Exit;
  end;
  
  // 初始化变量
  SourceEncoding := nil;
  BackupFile := '';
  TempFile := '';
  
  try
    // 检查文件可访问性
    if not CheckFileAccessibility(SourceFile, UseTemp) then
    begin
      if Assigned(FLogCallback) then
        FLogCallback('无法访问文件: ' + SourceFile);
      Exit;
    end;
    
    // 决定目标路径
    if UseTemp then
    begin
      TempFile := SourceFile + '.tmp';
      TargetPath := TempFile;
    end
    else if TargetFile <> '' then
      TargetPath := TargetFile
    else
      TargetPath := SourceFile;
    
    // 创建备份（如果目标是原文件）
    if TargetPath = SourceFile then
      CreateBackupFile(SourceFile, BackupFile);
    
    // 读取源文件内容
    if not ReadFileContent(SourceFile, Buffer) then
      Exit;
    
    // 处理文件内容
    // 这里先检测源编码
    DetectEncodingFromBytes(Buffer, SourceEncoding);
    SourceCodePage := DetectSourceCodePage(SourceFile, SourceEncoding);
    
    // 如果源编码和目标编码相同并且BOM标记也相同，跳过转换
    if ShouldSkipConversion(SourceFile, TargetPath, SourceEncoding, TargetEncoding, AddBOM, UseTemp) then
    begin
      Result := crSkipped;
      Exit;
    end;
    
    // 处理文件内容
    Content := ProcessFileContent(Buffer, SourceFile, SourceEncoding, SourceCodePage);
    if Content = '' then
      Exit;
    
    // 处理行尾
    HandleLineEndings(SourceFile, Content);
    
    // 写入转换后的内容
    if not WriteConvertedContent(Content, TargetPath, TargetEncoding, AddBOM) then
    begin
      // 如果写入失败，尝试从备份恢复
      RestoreFromBackup(SourceFile, BackupFile);
      Exit;
    end;
    
    // 如果使用了临时文件，复制回原始文件
    if UseTemp then
      TryCopyTempToOriginal(TempFile, SourceFile);
    
    // 获取目标编码代码页
    TargetCodePage := DetectSourceCodePage(TargetPath, TargetEncoding);
    
    // 记录成功日志
    LogConversionSuccess(SourceFile, SourceCodePage, TargetCodePage, AddBOM);
    
    // 设置成功结果
    Result := crSuccess;
  finally
    // 清理备份和临时文件
    try
      if (BackupFile <> '') and FileExists(BackupFile) then
        TFile.Delete(BackupFile);
      if (TempFile <> '') and FileExists(TempFile) then
        TFile.Delete(TempFile);
    except
      // 忽略清理错误
    end;
  end;
end;

procedure TEncodingController.ConvertFilesToEncoding(const FolderPath: string; 
  const FileExtensions: TArray<string>; SelectedFiles: TArray<string>; 
  TargetEncoding: TEncoding; AddBOM: Boolean);
var
  Files: TArray<string>;
  SuccessCount, FailCount, SkipCount: Integer;
  Result: TConversionResult;
  MatchesExtension: Boolean;
  i, j: Integer;
begin
  if not DirectoryExists(FolderPath) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('文件夹不存在: ' + FolderPath);
    Exit;
  end;
  
  // 如果有选中的文件，仅处理这些文件
  if Length(SelectedFiles) > 0 then
    Files := SelectedFiles
  else
  begin
    // 根据扩展名获取要处理的文件
    Files := TDirectory.GetFiles(FolderPath, '*.*', TSearchOption.soTopDirectoryOnly);
    
    // 过滤扩展名
    if Length(FileExtensions) > 0 then
    begin
      for i := Length(Files) - 1 downto 0 do
      begin
        MatchesExtension := False;
        for j := 0 to High(FileExtensions) do
        begin
          if SameText(ExtractFileExt(Files[i]), FileExtensions[j]) then
          begin
            MatchesExtension := True;
            Break;
          end;
        end;
        
        if not MatchesExtension then
        begin
          // 移除不匹配的文件
          Delete(Files, i, 1);
        end;
      end;
    end;
  end;
  
  // 初始化计数器
  SuccessCount := 0;
  FailCount := 0;
  SkipCount := 0;
  
  // 开始批量转换
  if Assigned(FLogCallback) then
    FLogCallback('开始转换' + IntToStr(Length(Files)) + '个文件...');
  
  for i := 0 to High(Files) do
  begin
    Result := ConvertFileEncoding(Files[i], '', TargetEncoding, AddBOM);
    
    case Result of
      crSuccess: Inc(SuccessCount);
      crFailed: Inc(FailCount);
      crSkipped: Inc(SkipCount);
    end;
  end;
  
  // 汇总结果
  if Assigned(FLogCallback) then
  begin
    FLogCallback('转换完成:');
    FLogCallback('  成功: ' + IntToStr(SuccessCount));
    FLogCallback('  失败: ' + IntToStr(FailCount));
    FLogCallback('  跳过: ' + IntToStr(SkipCount));
  end;
end;

procedure TEncodingController.ConvertSelectedFilesToEncoding(const SelectedFiles: TArray<string>;
  TargetEncoding: TEncoding; AddBOM: Boolean);
var
  i: Integer;
  Result: TConversionResult;
  SuccessCount, FailCount, SkipCount: Integer;
begin
  if Length(SelectedFiles) = 0 then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('未选择任何文件');
    Exit;
  end;
  
  // 初始化计数器
  SuccessCount := 0;
  FailCount := 0;
  SkipCount := 0;
  
  // 开始批量转换
  if Assigned(FLogCallback) then
    FLogCallback('开始转换' + IntToStr(Length(SelectedFiles)) + '个选定文件...');
  
  for i := 0 to High(SelectedFiles) do
  begin
    Result := ConvertFileEncoding(SelectedFiles[i], '', TargetEncoding, AddBOM);
    
    case Result of
      crSuccess: Inc(SuccessCount);
      crFailed: Inc(FailCount);
      crSkipped: Inc(SkipCount);
    end;
  end;
  
  // 汇总结果
  if Assigned(FLogCallback) then
  begin
    FLogCallback('转换完成:');
    FLogCallback('  成功: ' + IntToStr(SuccessCount));
    FLogCallback('  失败: ' + IntToStr(FailCount));
    FLogCallback('  跳过: ' + IntToStr(SkipCount));
  end;
end;

end. 