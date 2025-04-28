unit ControllerEncodingEnhanced;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  Vcl.Dialogs, UtilsEncodingDetect, UtilsEncodingDetect2;

type
  TEncodingConversionResult = (
    ecrSuccess,        // 转换成功
    ecrFailure,        // 转换失败
    ecrSkipped,        // 文件被跳过（如编码未变）
    ecrSourceNotFound, // 源文件不存在
    ecrNoAccess,       // 无法访问文件
    ecrNoChange,       // 无需更改
    ecrBackupFailed    // 备份失败
  );

  TEncodingConversionOption = (
    ecoCreateBackup,      // 创建备份文件
    ecoAddBOM,            // 添加BOM标记
    ecoForceConversion,   // 强制转换即使编码相同
    ecoRecursive,         // 递归处理子目录
    ecoSkipBinaryFiles    // 跳过二进制文件
  );
  TEncodingConversionOptions = set of TEncodingConversionOption;

  // 编码转换过程的回调类型
  TEncodingConversionCallback = reference to procedure(
    const FileName: string;
    const Message: string;
    const Progress: Integer;
    const Total: Integer);

  // 文件编码信息记录
  TFileEncodingInfo = record
    FileName: string;
    DetectionResult: TEncodingDetectionResult;
  end;

  // 增强的编码控制器类
  TEncodingControllerEnhanced = class
  private
    FEncodingDetector: TEncodingDetector2;
    FConversionOptions: TEncodingConversionOptions;
    FBackupExtension: string;
    FTargetEncoding: TEncoding;
    FTargetEncodingName: string;
    FBatchProgress: Integer;
    FBatchTotal: Integer;
    FBatchResults: TDictionary<string, TEncodingConversionResult>;
    FOnProgress: TEncodingConversionCallback;
    FLastError: string;

    // 内部方法
    function DoCreateBackup(const FileName: string): Boolean;
    function DoConvertSingleFile(
      const SourceFile, TargetFile: string;
      TargetEncoding: TEncoding;
      AddBOM: Boolean): TEncodingConversionResult;
    function IsBinaryFile(const FileName: string): Boolean;
    procedure ReportProgress(
      const FileName: string;
      const Message: string;
      CurrentProgress: Integer = -1);
  
  public
    constructor Create;
    destructor Destroy; override;

    // 属性
    property ConversionOptions: TEncodingConversionOptions 
      read FConversionOptions write FConversionOptions;
    property BackupExtension: string read FBackupExtension write FBackupExtension;
    property TargetEncoding: TEncoding read FTargetEncoding write FTargetEncoding;
    property TargetEncodingName: string read FTargetEncodingName write FTargetEncodingName;
    property OnProgress: TEncodingConversionCallback read FOnProgress write FOnProgress;
    property LastError: string read FLastError;
    property BatchResults: TDictionary<string, TEncodingConversionResult> read FBatchResults;

    // 方法
    
    // 检测单个文件的编码
    function DetectFileEncoding(const FileName: string): TEncodingDetectionResult;
    
    // 批量检测文件编码
    function DetectFilesEncoding(
      const FileNames: TArray<string>): TArray<TFileEncodingInfo>;
    
    // 转换单个文件编码
    function ConvertSingleFile(
      const SourceFile: string;
      TargetEncoding: TEncoding = nil;
      const TargetFile: string = '';
      AddBOM: Boolean = False): TEncodingConversionResult;
    
    // 按编码名称转换单个文件
    function ConvertSingleFileByName(
      const SourceFile: string;
      const TargetEncodingName: string = '';
      AddBOM: Boolean = False;
      UpdateCallback: TProc<string> = nil): TEncodingConversionResult;
    
    // 批量转换文件编码
    function ConvertFiles(
      const FileNames: TArray<string>;
      TargetEncoding: TEncoding = nil;
      AddBOM: Boolean = False): Integer;
    
    // 按编码名称批量转换文件
    function ConvertFilesByName(
      const FileNames: TArray<string>;
      const TargetEncodingName: string = '';
      AddBOM: Boolean = False): Integer;
    
    // 递归处理目录
    function ProcessDirectory(
      const Directory: string;
      const FileMask: string = '*.*';
      TargetEncoding: TEncoding = nil;
      AddBOM: Boolean = False): Integer;
    
    // 获取支持的编码列表
    class function GetSupportedEncodings: TArray<TEncoding>;
    
    // 获取支持的编码名称列表
    class function GetSupportedEncodingNames: TArray<string>;
    
    // 从名称获取编码实例
    class function GetEncodingByName(const EncodingName: string): TEncoding;
    
    // 获取编码结果描述
    class function GetResultDescription(
      Result: TEncodingConversionResult): string;
  end;

implementation

uses
  UtilsShared, UtilsLogFile;

{ TEncodingControllerEnhanced }

constructor TEncodingControllerEnhanced.Create;
begin
  inherited Create;
  FEncodingDetector := TEncodingDetector2.Create;
  FBatchResults := TDictionary<string, TEncodingConversionResult>.Create;
  FConversionOptions := [ecoCreateBackup, ecoAddBOM, ecoSkipBinaryFiles];
  FBackupExtension := '.bak';
  FTargetEncoding := TEncoding.UTF8;
  FTargetEncodingName := 'UTF-8';
  FBatchProgress := 0;
  FBatchTotal := 0;
  FLastError := '';
end;

destructor TEncodingControllerEnhanced.Destroy;
begin
  FEncodingDetector.Free;
  FBatchResults.Free;
  inherited;
end;

function TEncodingControllerEnhanced.DetectFileEncoding(
  const FileName: string): TEncodingDetectionResult;
begin
  if not FileExists(FileName) then
  begin
    Result.DetectedEncoding := nil;
    Result.EncodingName := 'Unknown';
    Result.Confidence := 0;
    Result.HasBOM := False;
    Result.Description := '文件不存在';
    Exit;
  end;
  
  try
    Result := FEncodingDetector.DetectFileEncoding(FileName);
  except
    on E: Exception do
    begin
      Result.DetectedEncoding := nil;
      Result.EncodingName := 'Error';
      Result.Confidence := 0;
      Result.HasBOM := False;
      Result.Description := '检测出错: ' + E.Message;
      FLastError := E.Message;
    end;
  end;
end;

function TEncodingControllerEnhanced.DetectFilesEncoding(
  const FileNames: TArray<string>): TArray<TFileEncodingInfo>;
var
  i: Integer;
begin
  SetLength(Result, Length(FileNames));
  FBatchTotal := Length(FileNames);
  FBatchProgress := 0;
  
  for i := 0 to High(FileNames) do
  begin
    FBatchProgress := i + 1;
    
    Result[i].FileName := FileNames[i];
    Result[i].DetectionResult := DetectFileEncoding(FileNames[i]);
    
    ReportProgress(
      FileNames[i],
      Format('检测编码: %s', [Result[i].DetectionResult.EncodingName]));
  end;
end;

function TEncodingControllerEnhanced.ConvertSingleFile(
  const SourceFile: string;
  TargetEncoding: TEncoding;
  const TargetFile: string;
  AddBOM: Boolean): TEncodingConversionResult;
var
  ActualTargetFile: string;
  SourceEncoding: TEncoding;
  DetectionResult: TEncodingDetectionResult;
  NeedBackup: Boolean;
begin
  // 检查源文件是否存在
  if not FileExists(SourceFile) then
  begin
    FLastError := '源文件不存在';
    ReportProgress(SourceFile, FLastError);
    Result := ecrSourceNotFound;
    Exit;
  end;
  
  // 如果目标编码为nil，使用默认目标编码
  if TargetEncoding = nil then
    TargetEncoding := FTargetEncoding;
  
  // 检查是否是二进制文件
  if (ecoSkipBinaryFiles in FConversionOptions) and IsBinaryFile(SourceFile) then
  begin
    FLastError := '跳过二进制文件';
    ReportProgress(SourceFile, FLastError);
    Result := ecrSkipped;
    Exit;
  end;
  
  // 检测源文件编码
  DetectionResult := DetectFileEncoding(SourceFile);
  
  // 如果无法检测到源编码，使用ANSI作为默认值
  if DetectionResult.DetectedEncoding = nil then
    SourceEncoding := TEncoding.ANSI
  else
    SourceEncoding := DetectionResult.DetectedEncoding;
  
  // 如果源编码和目标编码相同且没有设置强制转换选项，则跳过
  if (SourceEncoding = TargetEncoding) and
     not (ecoForceConversion in FConversionOptions) then
  begin
    // 仅在有BOM差异时才需要转换
    if not (AddBOM xor DetectionResult.HasBOM) then
    begin
      ReportProgress(SourceFile, '源文件编码已经是目标编码，无需转换');
      Result := ecrNoChange;
      Exit;
    end;
  end;
  
  // 确定目标文件
  if TargetFile = '' then
    ActualTargetFile := SourceFile
  else
    ActualTargetFile := TargetFile;
  
  // 如果需要，创建备份
  NeedBackup := (ActualTargetFile = SourceFile) and
               (ecoCreateBackup in FConversionOptions);
  
  if NeedBackup and not DoCreateBackup(SourceFile) then
  begin
    FLastError := '无法创建备份文件';
    ReportProgress(SourceFile, FLastError);
    Result := ecrBackupFailed;
    Exit;
  end;
  
  // 执行转换
  Result := DoConvertSingleFile(SourceFile, ActualTargetFile, TargetEncoding, AddBOM);
  
  // 报告进度
  case Result of
    ecrSuccess: ReportProgress(SourceFile, 
                  Format('成功转换为 %s', [FEncodingDetector.GetEncodingFriendlyName(TargetEncoding)]));
    ecrFailure: ReportProgress(SourceFile, 
                  Format('转换失败: %s', [FLastError]));
    else 
      ReportProgress(SourceFile, 
        Format('转换结果: %s', [GetResultDescription(Result)]));
  end;
end;

function TEncodingControllerEnhanced.ConvertSingleFileByName(
  const SourceFile, TargetEncodingName: string;
  AddBOM: Boolean;
  UpdateCallback: TProc<string>): TEncodingConversionResult;
var
  LocalTargetEncodingName: string;
  TargetEncoding: TEncoding;
  OldCallback: TEncodingConversionCallback;
  LocalCallback: TEncodingConversionCallback;
begin
  // 如果未指定目标编码名称，使用默认值
  if TargetEncodingName = '' then
    LocalTargetEncodingName := FTargetEncodingName
  else
    LocalTargetEncodingName := TargetEncodingName;
  
  // 获取目标编码实例
  TargetEncoding := GetEncodingByName(LocalTargetEncodingName);
  
  // 保存原回调并设置临时回调
  OldCallback := FOnProgress;
  if Assigned(UpdateCallback) then
  begin
    LocalCallback := 
      procedure(const FileName: string; const Message: string;
                const Progress, Total: Integer)
      begin
        UpdateCallback(Message);
        if Assigned(OldCallback) then
          OldCallback(FileName, Message, Progress, Total);
      end;
    FOnProgress := LocalCallback;
  end;
  
  try
    // 执行转换
    Result := ConvertSingleFile(SourceFile, TargetEncoding, '', AddBOM);
  finally
    // 恢复原回调
    FOnProgress := OldCallback;
  end;
end;

function TEncodingControllerEnhanced.ConvertFiles(
  const FileNames: TArray<string>;
  TargetEncoding: TEncoding;
  AddBOM: Boolean): Integer;
var
  i: Integer;
  Result: TEncodingConversionResult;
  SuccessCount: Integer;
begin
  FBatchResults.Clear;
  FBatchTotal := Length(FileNames);
  FBatchProgress := 0;
  SuccessCount := 0;
  
  for i := 0 to High(FileNames) do
  begin
    FBatchProgress := i + 1;
    
    // 转换单个文件
    Result := ConvertSingleFile(
      FileNames[i],
      TargetEncoding,
      '',  // 使用原文件名
      AddBOM);
    
    // 记录结果
    FBatchResults.Add(FileNames[i], Result);
    
    // 计算成功数量
    if Result = ecrSuccess then
      Inc(SuccessCount);
  end;
  
  // 返回成功转换的文件数量
  Result := SuccessCount;
end;

function TEncodingControllerEnhanced.ConvertFilesByName(
  const FileNames: TArray<string>;
  const TargetEncodingName: string;
  AddBOM: Boolean): Integer;
var
  LocalTargetEncodingName: string;
  TargetEncoding: TEncoding;
begin
  // 如果未指定目标编码名称，使用默认值
  if TargetEncodingName = '' then
    LocalTargetEncodingName := FTargetEncodingName
  else
    LocalTargetEncodingName := TargetEncodingName;
  
  // 获取目标编码实例
  TargetEncoding := GetEncodingByName(LocalTargetEncodingName);
  
  // 执行批量转换
  Result := ConvertFiles(FileNames, TargetEncoding, AddBOM);
end;

function TEncodingControllerEnhanced.ProcessDirectory(
  const Directory: string;
  const FileMask: string;
  TargetEncoding: TEncoding;
  AddBOM: Boolean): Integer;
var
  FileList: TArray<string>;
  FoundFiles: TArray<string>;
  DirList: TArray<string>;
  Dir: string;
  SuccessCount: Integer;
  TempCount: Integer;
begin
  // 检查目录是否存在
  if not DirectoryExists(Directory) then
  begin
    FLastError := '目录不存在: ' + Directory;
    Result := 0;
    Exit;
  end;
  
  // 获取符合掩码的文件
  FileList := TDirectory.GetFiles(Directory, FileMask);
  SuccessCount := 0;
  
  // 处理当前目录中的文件
  if Length(FileList) > 0 then
  begin
    ReportProgress('', Format('处理目录: %s', [Directory]));
    TempCount := ConvertFiles(FileList, TargetEncoding, AddBOM);
    Inc(SuccessCount, TempCount);
  end;
  
  // 如果需要递归处理子目录
  if ecoRecursive in FConversionOptions then
  begin
    DirList := TDirectory.GetDirectories(Directory);
    for Dir in DirList do
    begin
      TempCount := ProcessDirectory(Dir, FileMask, TargetEncoding, AddBOM);
      Inc(SuccessCount, TempCount);
    end;
  end;
  
  Result := SuccessCount;
end;

function TEncodingControllerEnhanced.DoCreateBackup(
  const FileName: string): Boolean;
var
  BackupFileName: string;
begin
  BackupFileName := FileName + FBackupExtension;
  
  // 如果备份文件已存在，先删除
  if FileExists(BackupFileName) then
  begin
    try
      TFile.Delete(BackupFileName);
    except
      on E: Exception do
      begin
        FLastError := '无法删除已存在的备份文件: ' + E.Message;
        Exit(False);
      end;
    end;
  end;
  
  // 创建备份
  try
    TFile.Copy(FileName, BackupFileName);
    Result := True;
  except
    on E: Exception do
    begin
      FLastError := '创建备份失败: ' + E.Message;
      Result := False;
    end;
  end;
end;

function TEncodingControllerEnhanced.DoConvertSingleFile(
  const SourceFile, TargetFile: string;
  TargetEncoding: TEncoding;
  AddBOM: Boolean): TEncodingConversionResult;
var
  SourceContent: TBytes;
  DetectionResult: TEncodingDetectionResult;
  SourceEncoding: TEncoding;
  TempStr: string;
  TargetContent: TBytes;
begin
  try
    // 读取源文件内容
    SourceContent := TFile.ReadAllBytes(SourceFile);
    
    // 检测源文件编码
    DetectionResult := FEncodingDetector.DetectBytesEncoding(SourceContent);
    
    // 如果无法检测到源编码，使用ANSI作为默认值
    if DetectionResult.DetectedEncoding = nil then
      SourceEncoding := TEncoding.ANSI
    else
      SourceEncoding := DetectionResult.DetectedEncoding;
    
    // 解码内容为字符串
    if DetectionResult.HasBOM then
    begin
      // 跳过BOM
      var PreambleSize: Integer := TEncoding.GetBufferEncoding(
        SourceContent, SourceEncoding);
      TempStr := SourceEncoding.GetString(
        SourceContent, PreambleSize, Length(SourceContent) - PreambleSize);
    end
    else
      TempStr := SourceEncoding.GetString(SourceContent);
    
    // 使用目标编码重新编码内容
    if AddBOM then
      TargetContent := TargetEncoding.GetPreamble + TargetEncoding.GetBytes(TempStr)
    else
      TargetContent := TargetEncoding.GetBytes(TempStr);
    
    // 写入目标文件
    TFile.WriteAllBytes(TargetFile, TargetContent);
    
    Result := ecrSuccess;
  except
    on E: Exception do
    begin
      FLastError := '转换失败: ' + E.Message;
      Result := ecrFailure;
      
      // 记录错误
      LogWriteLine('编码转换错误: ' + E.Message);
      LogWriteLine('  源文件: ' + SourceFile);
      LogWriteLine('  目标文件: ' + TargetFile);
      LogWriteLine('  目标编码: ' + FEncodingDetector.GetEncodingFriendlyName(TargetEncoding));
    end;
  end;
end;

function TEncodingControllerEnhanced.IsBinaryFile(
  const FileName: string): Boolean;
const
  MAX_CHECK_SIZE = 8192;  // 检查文件的前8KB
  BINARY_THRESHOLD = 0.1; // 如果二进制字符比例超过10%，认为是二进制文件
var
  FileStream: TFileStream;
  Buffer: TBytes;
  BytesRead, i: Integer;
  BinaryCount: Integer;
begin
  Result := False;
  
  // 检查特定类型的已知二进制文件扩展名
  var Ext := LowerCase(ExtractFileExt(FileName));
  if (Ext = '.exe') or (Ext = '.dll') or (Ext = '.obj') or
     (Ext = '.bin') or (Ext = '.com') or (Ext = '.sys') or
     (Ext = '.ico') or (Ext = '.bmp') or (Ext = '.jpg') or
     (Ext = '.jpeg') or (Ext = '.gif') or (Ext = '.png') or
     (Ext = '.zip') or (Ext = '.rar') or (Ext = '.7z') or
     (Ext = '.gz') or (Ext = '.tar') or (Ext = '.pdf') or
     (Ext = '.doc') or (Ext = '.xls') or (Ext = '.ppt') then
    Exit(True);
  
  try
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      if FileStream.Size = 0 then
        Exit(False); // 空文件当作文本文件处理
      
      SetLength(Buffer, Min(FileStream.Size, MAX_CHECK_SIZE));
      BytesRead := FileStream.Read(Buffer[0], Length(Buffer));
      
      // 统计二进制字符的比例
      BinaryCount := 0;
      for i := 0 to BytesRead - 1 do
      begin
        // 如果字符是控制字符（除了制表符、换行符和回车符）
        if (Buffer[i] < 32) and not (Buffer[i] in [9, 10, 13]) then
          Inc(BinaryCount);
      end;
      
      // 计算二进制字符比例
      Result := (BinaryCount / BytesRead) > BINARY_THRESHOLD;
    finally
      FileStream.Free;
    end;
  except
    // 如果出现异常，安全起见假设为文本文件
    Result := False;
  end;
end;

procedure TEncodingControllerEnhanced.ReportProgress(
  const FileName: string;
  const Message: string;
  CurrentProgress: Integer);
var
  Progress, Total: Integer;
begin
  // 确定进度值
  if CurrentProgress >= 0 then
    Progress := CurrentProgress
  else
    Progress := FBatchProgress;
  
  Total := FBatchTotal;
  
  // 调用进度回调
  if Assigned(FOnProgress) then
    FOnProgress(FileName, Message, Progress, Total);
  
  // 记录日志
  if FileName <> '' then
    LogWriteLine(Format('[编码转换] %s: %s', [FileName, Message]))
  else
    LogWriteLine(Format('[编码转换] %s', [Message]));
end;

class function TEncodingControllerEnhanced.GetSupportedEncodings: TArray<TEncoding>;
begin
  Result := TEncodingDetector2.GetSupportedEncodings;
end;

class function TEncodingControllerEnhanced.GetSupportedEncodingNames: TArray<string>;
begin
  Result := TEncodingDetector2.GetSupportedEncodingNames;
end;

class function TEncodingControllerEnhanced.GetEncodingByName(
  const EncodingName: string): TEncoding;
begin
  Result := TEncodingDetector2.GetEncodingByName(EncodingName);
end;

class function TEncodingControllerEnhanced.GetResultDescription(
  Result: TEncodingConversionResult): string;
begin
  case Result of
    ecrSuccess:        Exit('转换成功');
    ecrFailure:        Exit('转换失败');
    ecrSkipped:        Exit('文件被跳过');
    ecrSourceNotFound: Exit('源文件不存在');
    ecrNoAccess:       Exit('无法访问文件');
    ecrNoChange:       Exit('无需更改');
    ecrBackupFailed:   Exit('备份失败');
    else               Exit('未知结果');
  end;
end;

end. 