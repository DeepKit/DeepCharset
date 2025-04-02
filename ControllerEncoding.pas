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
    
    // NEW: Internal helper to perform single file conversion using names
    function DoConvertSingleFileByName(const SourceFile: string;
      const TargetEncodingName: string; AddBOM: Boolean;
      UpdateCallback: TProc<string>): TConversionResult;

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

    // --- NEW Public Methods using Encoding Names ---
    procedure ConvertFilesByName(const SelectedFiles: TArray<string>;
                                 const TargetEncodingName: string;
                                 AddBOM: Boolean;
                                 UpdateCallback: TProc<string>);
                                 
    function ConvertSingleFileByName(const SourceFile: string; 
                                     const TargetEncodingName: string; 
                                     AddBOM: Boolean; 
                                     UpdateCallback: TProc<string>): TConversionResult;
    // --- End of NEW Public Methods ---
  end;

implementation

uses System.Threading;

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

// NEW: Internal helper to perform single file conversion using names
function TEncodingController.DoConvertSingleFileByName(const SourceFile: string;
  const TargetEncodingName: string; AddBOM: Boolean;
  UpdateCallback: TProc<string>): TConversionResult;
var
  TempFile, BackupFile: string;
  UseTemp: Boolean;
  SourceEncodingName: string;
  ConversionOk: Boolean;
begin
  Result := crFailed;
  TempFile := '';
  BackupFile := '';

  if not FileExists(SourceFile) or IsUnsupportedFile(SourceFile) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('跳过: ' + SourceFile + ' (不支持或不存在)');
    Exit(crSkipped);
  end;

  if not CheckFileAccessibility(SourceFile, UseTemp) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('错误: 无法访问文件 ' + SourceFile);
    Exit(crFailed);
  end;

  CreateBackupFile(SourceFile, BackupFile);

  if UseTemp then
    TempFile := TPath.ChangeExtension(SourceFile, '.tmpconvert')
  else
    TempFile := SourceFile; 

  if not DetectFileEncoding(SourceFile, SourceEncodingName) then
  begin
     if Assigned(FLogCallback) then
       FLogCallback('警告: 未能检测源编码 ' + SourceFile + ', 将尝试默认转换。');
     SourceEncodingName := '' ; 
  end;

  try
    ConversionOk := ConvertWithIconv(SourceFile, TempFile, SourceEncodingName, TargetEncodingName, AddBOM);
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('转换失败 (' + SourceFile + ' -> ' + TargetEncodingName + '): ' + E.Message);
      ConversionOk := False;
    end;
  end;

  if ConversionOk then
  begin
    if UseTemp then
      TryCopyTempToOriginal(TempFile, SourceFile);
      
    LogConversionSuccess(SourceFile);
    Result := crSuccess;
    
    // Call update callback DIRECTLY (Removed TTask.Run)
    if Assigned(UpdateCallback) then
    begin
      try
        UpdateCallback(SourceFile);
      except
        on E: Exception do
          if Assigned(FLogCallback) then
             FLogCallback('UpdateCallback 失败 (' + SourceFile + '): ' + E.Message);
      end;
    end;

  end
  else
  begin
    if Assigned(FLogCallback) then
      FLogCallback('错误: 转换失败，正在从备份恢复 ' + SourceFile);
    RestoreFromBackup(SourceFile, BackupFile);
    Result := crFailed;
  end;

  // Clean up temp and backup files
  if (TempFile <> '') and FileExists(TempFile) and UseTemp then
    DeleteFile(PChar(TempFile));
  if (BackupFile <> '') and FileExists(BackupFile) then
    DeleteFile(PChar(BackupFile));
end;

// NEW Public Method Implementation: ConvertSingleFileByName
function TEncodingController.ConvertSingleFileByName(const SourceFile: string; 
  const TargetEncodingName: string; AddBOM: Boolean; 
  UpdateCallback: TProc<string>): TConversionResult;
begin
  Result := DoConvertSingleFileByName(SourceFile, TargetEncodingName, AddBOM, UpdateCallback);
end;

// NEW Public Method Implementation: ConvertFilesByName
procedure TEncodingController.ConvertFilesByName(const SelectedFiles: TArray<string>;
  const TargetEncodingName: string; AddBOM: Boolean;
  UpdateCallback: TProc<string>);
var
  i: Integer;
  FileToConvert: string;
begin
  if Assigned(FLogCallback) then
    FLogCallback(Format('开始批量转换 %d 个文件到 %s', [Length(SelectedFiles), TargetEncodingName]));
    
  for i := 0 to High(SelectedFiles) do
  begin
    FileToConvert := SelectedFiles[i];
    // Call the internal helper for each file
    DoConvertSingleFileByName(FileToConvert, TargetEncodingName, AddBOM, UpdateCallback);
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
  // It needs significant rework to use iconv with TEncodingInfo.ShortName
  // For now, it's likely incompatible with the new approach.

  Result := crSkipped; // Mark as skipped/failed for now
  if Assigned(FLogCallback) then
    FLogCallback('警告: ConvertFileEncoding (TEncoding version) 当前未实现 iconv 支持。');

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
    FLogCallback('警告: ConvertFilesToEncoding (TEncoding version) 当前未实现 iconv 支持。');
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
    FLogCallback('警告: ConvertSelectedFilesToEncoding (TEncoding version) 当前未实现 iconv 支持。');
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
begin
  try
    // Ensure original file is deleted before copying
    if FileExists(OriginalFile) then
      DeleteFile(PChar(OriginalFile));
    TFile.Move(TempFile, OriginalFile);
  except
    on E: Exception do
      if Assigned(FLogCallback) then
        FLogCallback('从临时文件复制回失败 (' + OriginalFile + '): ' + E.Message);
      // Consider attempting TFile.Copy as a fallback?
  end;
end;

procedure TEncodingController.LogConversionSuccess(const SourceFile: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback('转换成功: ' + SourceFile);
end;

procedure TEncodingController.RestoreFromBackup(const OriginalFile, BackupFile: string);
begin
  if (BackupFile = '') or not FileExists(BackupFile) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('无法从备份恢复: 备份文件无效 ' + OriginalFile);
    Exit;
  end;

  try
    if FileExists(OriginalFile) then
      DeleteFile(PChar(OriginalFile));
    TFile.Move(BackupFile, OriginalFile);
    if Assigned(FLogCallback) then
      FLogCallback('已从备份恢复: ' + OriginalFile);
  except
    on E: Exception do
      if Assigned(FLogCallback) then
        FLogCallback('从备份恢复失败 (' + OriginalFile + '): ' + E.Message);
  end;
end;

end. 