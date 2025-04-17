unit ControllerEncodingOptimized;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  ModelEncoding, Winapi.Windows, JclEncodingUtils, UtilsEncodingDetect;

type
  // 批量转换配置结构体
  TBatchConversionConfig = record
    TargetEncoding: string;     // 目标编码名称
    AddBOM: Boolean;            // 是否添加BOM
    IncludeSubdirs: Boolean;    // 是否包含子目录
    FileExtensions: TArray<string>; // 文件扩展名过滤
    Name: string;               // 配置名称
  end;

  // 编码控制器类 - 优化版
  TEncodingControllerOptimized = class
  private
    // 日志记录回调
    FLogCallback: TProc<string>;
    // 编码检测器
    FEncodingDetector: TEncodingDetector;
    // 保存的批量转换配置
    FConversionConfigs: TDictionary<string, TBatchConversionConfig>;
    
    // 内部编码转换辅助函数
    function CheckFileAccessibility(const FileName: string; var UseTemp: Boolean): Boolean;
    procedure CreateBackupFile(const SourceFile: string; var BackupFile: string);
    procedure TryCopyTempToOriginal(const TempFile, OriginalFile: string);
    procedure LogConversionSuccess(const SourceFile: string);
    procedure RestoreFromBackup(const OriginalFile, BackupFile: string);
    
    // 使用JCL进行编码转换
    function ConvertWithJCL(const SourceFile, TargetFile: string;
      const SourceEncoding, TargetEncoding: string; AddBOM: Boolean): Boolean;
    
    // 内部辅助函数，使用编码名称执行单个文件转换
    function DoConvertSingleFileByName(const SourceFile, TargetEncodingName: string; 
      AddBOM: Boolean = False; const TargetFile: string = ''): TConversionResult;

    // 性能监控
    procedure StartPerformanceMonitor(const Operation: string);
    procedure EndPerformanceMonitor(const Operation: string);

  public
    constructor Create(ALogCallback: TProc<string>);
    destructor Destroy; override;
    
    // 判断文件是否在不支持列表中
    function IsUnsupportedFile(const Filename: string): Boolean;
    
    // 检查文件是否有BOM标记
    function HasBOM(const FileName: string): Boolean;
    
    // 检测文件编码 - 使用优化的检测算法
    function DetectFileEncoding(const FileName: string; out EncodingName: string): Boolean;
    
    // 转换单个文件编码
    function ConvertFileEncoding(const SourceFile, TargetFile: string; 
      const TargetEncodingName: string; AddBOM: Boolean): TConversionResult;
      
    // 批量转换文件夹中的文件
    procedure ConvertFilesToEncoding(const FolderPath: string; 
      const FileExtensions: TArray<string>; IncludeSubdirs: Boolean;
      const TargetEncodingName: string; AddBOM: Boolean;
      UpdateCallback: TProc<string, Integer, Integer> = nil);
      
    // 转换选中的文件
    procedure ConvertSelectedFilesToEncoding(const SelectedFiles: TArray<string>;
      const TargetEncodingName: string; AddBOM: Boolean;
      UpdateCallback: TProc<string, Integer, Integer> = nil);

    // 批量转换配置管理
    procedure SaveConversionConfig(const ConfigName: string; const Config: TBatchConversionConfig);
    function LoadConversionConfig(const ConfigName: string; out Config: TBatchConversionConfig): Boolean;
    procedure DeleteConversionConfig(const ConfigName: string);
    function GetAllConfigNames: TArray<string>;
    
    // 属性
    property EncodingDetector: TEncodingDetector read FEncodingDetector;
  end;

implementation

uses 
  System.Diagnostics, System.Math;

var
  // 性能监控数据
  PerformanceData: TDictionary<string, TStopwatch>;

{ TEncodingControllerOptimized }

constructor TEncodingControllerOptimized.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := ALogCallback;
  FEncodingDetector := TEncodingDetector.Create(ALogCallback);
  FConversionConfigs := TDictionary<string, TBatchConversionConfig>.Create;
  
  // 初始化性能监控
  if not Assigned(PerformanceData) then
    PerformanceData := TDictionary<string, TStopwatch>.Create;
  
  // 记录日志
  if Assigned(FLogCallback) then
    FLogCallback('优化版编码处理功能已初始化');
end;

destructor TEncodingControllerOptimized.Destroy;
begin
  FEncodingDetector.Free;
  FConversionConfigs.Free;
  inherited;
end;

procedure TEncodingControllerOptimized.StartPerformanceMonitor(const Operation: string);
var
  StopWatch: TStopwatch;
begin
  if not PerformanceData.TryGetValue(Operation, StopWatch) then
  begin
    StopWatch := TStopwatch.Create;
    PerformanceData.Add(Operation, StopWatch);
  end;
  
  StopWatch.Reset;
  StopWatch.Start;
end;

procedure TEncodingControllerOptimized.EndPerformanceMonitor(const Operation: string);
var
  StopWatch: TStopwatch;
begin
  if PerformanceData.TryGetValue(Operation, StopWatch) then
  begin
    StopWatch.Stop;
    if Assigned(FLogCallback) then
      FLogCallback(Format('性能监控: %s 耗时 %d ms', [Operation, StopWatch.ElapsedMilliseconds]));
  end;
end;

function TEncodingControllerOptimized.IsUnsupportedFile(const Filename: string): Boolean;
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

function TEncodingControllerOptimized.HasBOM(const FileName: string): Boolean;
begin
  Result := FEncodingDetector.HasBOM(FileName);
end;

function TEncodingControllerOptimized.DetectFileEncoding(const FileName: string; out EncodingName: string): Boolean;
var
  DetectResult: TEncodingDetectResult;
begin
  StartPerformanceMonitor('DetectFileEncoding');
  try
    DetectResult := FEncodingDetector.DetectFileEncoding(FileName);
    EncodingName := DetectResult.EncodingName;
    Result := (DetectResult.Confidence > 0);
    
    if Result and Assigned(FLogCallback) then
      FLogCallback(Format('检测到文件编码: %s -> %s (置信度: %d%%)', 
                         [FileName, EncodingName, DetectResult.Confidence]));
  finally
    EndPerformanceMonitor('DetectFileEncoding');
  end;
end;

function TEncodingControllerOptimized.CheckFileAccessibility(const FileName: string; var UseTemp: Boolean): Boolean;
var
  FileHandle: THandle;
  FileMode: DWORD;
begin
  Result := False;
  UseTemp := False;
  
  if not FileExists(FileName) then
    Exit;
  
  // 尝试以读写模式打开文件
  FileMode := GENERIC_READ or GENERIC_WRITE;
  FileHandle := CreateFile(
    PChar(FileName),
    FileMode,
    0, // 不共享
    nil,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0);
  
  if FileHandle <> INVALID_HANDLE_VALUE then
  begin
    // 文件可以以读写模式打开
    CloseHandle(FileHandle);
    Result := True;
  end
  else
  begin
    // 尝试以只读模式打开
    FileMode := GENERIC_READ;
    FileHandle := CreateFile(
      PChar(FileName),
      FileMode,
      FILE_SHARE_READ, // 允许其他进程读取
      nil,
      OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL,
      0);
    
    if FileHandle <> INVALID_HANDLE_VALUE then
    begin
      // 文件可以以只读模式打开，需要使用临时文件
      CloseHandle(FileHandle);
      Result := True;
      UseTemp := True;
      
      if Assigned(FLogCallback) then
        FLogCallback('文件为只读模式，将使用临时文件: ' + FileName);
    end
    else
    begin
      // 文件无法打开
      if Assigned(FLogCallback) then
        FLogCallback('无法访问文件: ' + FileName);
    end;
  end;
end;

procedure TEncodingControllerOptimized.CreateBackupFile(const SourceFile: string; var BackupFile: string);
begin
  BackupFile := SourceFile + '.bak';
  
  // 如果备份文件已存在，先删除
  if FileExists(BackupFile) then
    DeleteFile(PChar(BackupFile));
  
  // 创建备份
  if not CopyFile(PChar(SourceFile), PChar(BackupFile), False) then
  begin
    var ErrorCode := GetLastError;
    if Assigned(FLogCallback) then
      FLogCallback(Format('创建备份文件失败 (错误码: %d): %s', [ErrorCode, BackupFile]));
    BackupFile := '';
  end
  else if Assigned(FLogCallback) then
    FLogCallback('已创建备份文件: ' + BackupFile);
end;

procedure TEncodingControllerOptimized.TryCopyTempToOriginal(const TempFile, OriginalFile: string);
var
  ErrorCode: Cardinal;
begin
  if not FileExists(TempFile) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('临时文件不存在，无法复制: ' + TempFile);
    Exit;
  end;
  
  // 尝试删除原文件
  if FileExists(OriginalFile) then
  begin
    if not DeleteFile(PChar(OriginalFile)) then
    begin
      ErrorCode := GetLastError;
      if Assigned(FLogCallback) then
        FLogCallback(Format('无法删除原文件 (错误码: %d): %s', [ErrorCode, OriginalFile]));
      Exit;
    end;
  end;
  
  // 复制临时文件到原文件
  if not CopyFile(PChar(TempFile), PChar(OriginalFile), False) then
  begin
    ErrorCode := GetLastError;
    if Assigned(FLogCallback) then
      FLogCallback(Format('复制临时文件失败 (错误码: %d): %s -> %s', 
                         [ErrorCode, TempFile, OriginalFile]));
  end
  else
  begin
    if Assigned(FLogCallback) then
      FLogCallback('成功将临时文件复制到原文件: ' + OriginalFile);
    
    // 删除临时文件
    DeleteFile(PChar(TempFile));
  end;
end;

procedure TEncodingControllerOptimized.LogConversionSuccess(const SourceFile: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback('文件转换成功: ' + SourceFile);
end;

procedure TEncodingControllerOptimized.RestoreFromBackup(const OriginalFile, BackupFile: string);
begin
  if (BackupFile <> '') and FileExists(BackupFile) then
  begin
    // 删除可能已损坏的原文件
    if FileExists(OriginalFile) then
      DeleteFile(PChar(OriginalFile));
    
    // 恢复备份
    if CopyFile(PChar(BackupFile), PChar(OriginalFile), False) then
    begin
      if Assigned(FLogCallback) then
        FLogCallback('已从备份恢复文件: ' + OriginalFile);
      
      // 删除备份文件
      DeleteFile(PChar(BackupFile));
    end
    else
    begin
      var ErrorCode := GetLastError;
      if Assigned(FLogCallback) then
        FLogCallback(Format('从备份恢复失败 (错误码: %d): %s', [ErrorCode, OriginalFile]));
    end;
  end;
end;

function TEncodingControllerOptimized.ConvertWithJCL(const SourceFile, TargetFile: string;
  const SourceEncoding, TargetEncoding: string; AddBOM: Boolean): Boolean;
var
  SysErrorCode: Cardinal;
  ActualTargetEncoding: string;
begin
  Result := False;
  
  try
    if not FileExists(SourceFile) then
    begin
      if Assigned(FLogCallback) then
        FLogCallback('文件不存在: ' + SourceFile);
      Exit;
    end;
    
    // 检查文件是否可访问
    try
      var TestStream := TFileStream.Create(SourceFile, fmOpenRead or fmShareDenyNone);
      try
        // 只测试是否可以读取，不做实际操作
      finally
        TestStream.Free;
      end;
    except
      on E: Exception do
      begin
        if Assigned(FLogCallback) then
          FLogCallback('文件访问错误: ' + E.Message);
        Exit;
      end;
    end;
    
    // 特殊处理UTF-8 BOM的情况
    ActualTargetEncoding := TargetEncoding;
    if (SameText(TargetEncoding, 'UTF-8 with BOM') or SameText(TargetEncoding, 'UTF-8-BOM') or 
       SameText(TargetEncoding, 'UTF8-BOM')) then
    begin
      ActualTargetEncoding := 'UTF-8';
      AddBOM := True;
      
      if Assigned(FLogCallback) then
        FLogCallback('注意: 目标编码"' + TargetEncoding + '"已规范化为"UTF-8"并设置AddBOM=True');
    end;
    
    if Assigned(FLogCallback) then
      FLogCallback(Format('开始转换: %s -> %s, 从 [%s] 到 [%s], BOM: %s', 
                          [SourceFile, TargetFile, SourceEncoding, ActualTargetEncoding, 
                           BoolToStr(AddBOM, True)]));
    
    // 使用JclEncodingUtils的ConvertFileByName函数
    try
      Result := JclEncodingUtils.ConvertFileByName(SourceFile, TargetFile, 
                                               SourceEncoding, ActualTargetEncoding, AddBOM);
    except
      on E: EFOpenError do
      begin
        SysErrorCode := GetLastError;
        if Assigned(FLogCallback) then
          FLogCallback(Format('文件打开错误 (代码: %d): %s', [SysErrorCode, E.Message]));
        Result := False;
        Exit;
      end;
      on E: EFCreateError do
      begin
        SysErrorCode := GetLastError;
        if Assigned(FLogCallback) then
          FLogCallback(Format('文件创建错误 (代码: %d): %s', [SysErrorCode, E.Message]));
        Result := False;
        Exit;
      end;
      on E: EWriteError do
      begin
        SysErrorCode := GetLastError;
        if Assigned(FLogCallback) then
          FLogCallback(Format('文件写入错误 (代码: %d): %s', [SysErrorCode, E.Message]));
        Result := False;
        Exit;
      end;
      on E: Exception do
        raise; // 重新抛出其他异常
    end;
    
    if Result then
    begin
      if Assigned(FLogCallback) then
      begin
        FLogCallback(Format('JCL转换调用完成: %s (源编码: %s, 目标编码: %s, AddBOM: %s)', 
                           [TargetFile, SourceEncoding, ActualTargetEncoding, BoolToStr(AddBOM, True)]));
        
        // 验证转换结果
        var ResultEncodingName: string;
        if DetectFileEncoding(TargetFile, ResultEncodingName) then
        begin
          FLogCallback(Format('转换后的文件编码: %s -> %s', [TargetFile, ResultEncodingName]));
          
          // 特殊情况: 如果目标应为UTF-8 BOM但检测为其他编码，尝试手动添加BOM
          if AddBOM and SameText(ActualTargetEncoding, 'UTF-8') and 
             not SameText(ResultEncodingName, 'UTF-8 with BOM') then
          begin
            FLogCallback('检测到目标应为UTF-8 BOM但未成功添加BOM，尝试手动修复...');
            var TempFile := TargetFile + '.fix';
            
            try
              // 读取原文件内容
              var Content := TFile.ReadAllBytes(TargetFile);
              var BOMBytes := TBytes.Create($EF, $BB, $BF); // UTF-8 BOM
              
              // 检查是否已有BOM
              var HasBOMAlready := (Length(Content) >= 3) and 
                                   (Content[0] = $EF) and (Content[1] = $BB) and (Content[2] = $BF);
              
              if not HasBOMAlready then
              begin
                // 合并BOM和内容
                var FinalContent: TBytes;
                SetLength(FinalContent, Length(BOMBytes) + Length(Content));
                if Length(BOMBytes) > 0 then
                  Move(BOMBytes[0], FinalContent[0], Length(BOMBytes));
                if Length(Content) > 0 then
                  Move(Content[0], FinalContent[Length(BOMBytes)], Length(Content));
                
                // 写入修复后的文件
                TFile.WriteAllBytes(TempFile, FinalContent);
                
                // 替换原文件
                if FileExists(TempFile) then
                begin
                  // 删除原文件
                  DeleteFile(PChar(TargetFile));
                  if RenameFile(TempFile, TargetFile) then
                  begin
                    FLogCallback('成功手动添加UTF-8 BOM');
                    // 重新检测以确认
                    if DetectFileEncoding(TargetFile, ResultEncodingName) then
                      FLogCallback(Format('修复后的文件编码: %s -> %s', [TargetFile, ResultEncodingName]));
                  end
                  else
                  begin
                    SysErrorCode := GetLastError;
                    FLogCallback(Format('无法重命名修复文件 (错误码: %d)', [SysErrorCode]));
                    // 尝试直接复制
                    if CopyFile(PChar(TempFile), PChar(TargetFile), False) then
                    begin
                      FLogCallback('使用复制方式成功添加UTF-8 BOM');
                      DeleteFile(PChar(TempFile));
                    end;
                  end;
                end;
              end;
            except
              on E: Exception do
                FLogCallback('手动添加BOM失败: ' + E.Message);
            end;
          end;
        end
        else
          FLogCallback('无法检测转换后的文件编码');
      end;
    end
    else
    begin
      if Assigned(FLogCallback) then
        FLogCallback(Format('JCL转换失败: %s -> %s', [SourceEncoding, ActualTargetEncoding]));
    end;
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('转换过程中发生异常: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TEncodingControllerOptimized.DoConvertSingleFileByName(const SourceFile, TargetEncodingName: string; 
  AddBOM: Boolean; const TargetFile: string): TConversionResult;
var
  TempFile: string;
  BackupFile: string;
  UseTemp: Boolean;
  SourceEncodingName: string;
  ActualTargetFile: string;
begin
  Result := crFailed;
  BackupFile := '';
  
  StartPerformanceMonitor('ConvertSingleFile');
  try
    // 检查源文件是否存在
    if not FileExists(SourceFile) then
    begin
      if Assigned(FLogCallback) then
        FLogCallback('源文件不存在: ' + SourceFile);
      Exit;
    end;
    
    // 检查文件是否在不支持列表中
    if IsUnsupportedFile(SourceFile) then
    begin
      if Assigned(FLogCallback) then
        FLogCallback('文件类型不支持转换: ' + SourceFile);
      Result := crSkipped;
      Exit;
    end;
    
    // 检测源文件编码
    if not DetectFileEncoding(SourceFile, SourceEncodingName) then
    begin
      if Assigned(FLogCallback) then
        FLogCallback('无法检测源文件编码: ' + SourceFile);
      Exit;
    end;
    
    // 如果源编码与目标编码相同，且BOM设置也相同，则跳过
    var SourceHasBOM := HasBOM(SourceFile);
    if SameText(SourceEncodingName, TargetEncodingName) and (SourceHasBOM = AddBOM) then
    begin
      if Assigned(FLogCallback) then
        FLogCallback(Format('源文件已经是目标编码，跳过转换: %s [%s]', 
                           [SourceFile, SourceEncodingName]));
      Result := crSkipped;
      Exit;
    end;
    
    // 检查文件可访问性
    if not CheckFileAccessibility(SourceFile, UseTemp) then
    begin
      if Assigned(FLogCallback) then
        FLogCallback('文件无法访问: ' + SourceFile);
      Exit;
    end;
    
    // 确定目标文件
    if TargetFile <> '' then
    begin
      ActualTargetFile := TargetFile;
    end
    else if UseTemp then
    begin
      TempFile := ChangeFileExt(SourceFile, '.tmp');
      ActualTargetFile := TempFile;
      
      // 创建备份
      CreateBackupFile(SourceFile, BackupFile);
    end
    else
    begin
      // 直接覆盖源文件，先创建备份
      CreateBackupFile(SourceFile, BackupFile);
      ActualTargetFile := SourceFile;
    end;
    
    // 执行转换
    if ConvertWithJCL(SourceFile, ActualTargetFile, SourceEncodingName, TargetEncodingName, AddBOM) then
    begin
      // 如果使用了临时文件，复制回原文件
      if UseTemp then
        TryCopyTempToOriginal(TempFile, SourceFile);
      
      // 记录成功
      LogConversionSuccess(SourceFile);
      Result := crSuccess;
      
      // 如果有备份且转换成功，删除备份
      if (BackupFile <> '') and FileExists(BackupFile) then
        DeleteFile(PChar(BackupFile));
    end
    else
    begin
      // 转换失败，如果有备份，恢复备份
      if BackupFile <> '' then
        RestoreFromBackup(SourceFile, BackupFile);
      
      if Assigned(FLogCallback) then
        FLogCallback('转换失败: ' + SourceFile);
    end;
  except
    on E: Exception do
    begin
      // 发生异常，尝试恢复备份
      if BackupFile <> '' then
        RestoreFromBackup(SourceFile, BackupFile);
      
      if Assigned(FLogCallback) then
        FLogCallback('转换过程中发生异常: ' + E.Message);
    end;
  end;
  EndPerformanceMonitor('ConvertSingleFile');
end;

function TEncodingControllerOptimized.ConvertFileEncoding(const SourceFile, TargetFile: string; 
  const TargetEncodingName: string; AddBOM: Boolean): TConversionResult;
begin
  Result := DoConvertSingleFileByName(SourceFile, TargetEncodingName, AddBOM, TargetFile);
end;

procedure TEncodingControllerOptimized.ConvertFilesToEncoding(const FolderPath: string; 
  const FileExtensions: TArray<string>; IncludeSubdirs: Boolean;
  const TargetEncodingName: string; AddBOM: Boolean;
  UpdateCallback: TProc<string, Integer, Integer>);
var
  Files: TArray<string>;
  FilePath: string;
  SearchOption: TSearchOption;
  TotalFiles, ProcessedFiles: Integer;
  Result: TConversionResult;
begin
  if not DirectoryExists(FolderPath) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('文件夹不存在: ' + FolderPath);
    Exit;
  end;
  
  // 设置搜索选项
  if IncludeSubdirs then
    SearchOption := TSearchOption.soAllDirectories
  else
    SearchOption := TSearchOption.soTopDirectoryOnly;
  
  // 获取所有文件
  Files := [];
  for var Ext in FileExtensions do
  begin
    var FilesWithExt := TDirectory.GetFiles(FolderPath, '*' + Ext, SearchOption);
    for var File in FilesWithExt do
      Files := Files + [File];
  end;
  
  TotalFiles := Length(Files);
  ProcessedFiles := 0;
  
  if Assigned(FLogCallback) then
    FLogCallback(Format('开始批量转换 %d 个文件到 %s (AddBOM: %s)', 
                       [TotalFiles, TargetEncodingName, BoolToStr(AddBOM, True)]));
  
  // 转换每个文件
  for FilePath in Files do
  begin
    Inc(ProcessedFiles);
    
    // 更新进度
    if Assigned(UpdateCallback) then
      UpdateCallback(ExtractFileName(FilePath), ProcessedFiles, TotalFiles);
    
    // 转换文件
    Result := DoConvertSingleFileByName(FilePath, TargetEncodingName, AddBOM);
    
    // 记录结果
    case Result of
      crSuccess: 
        if Assigned(FLogCallback) then
          FLogCallback(Format('[%d/%d] 转换成功: %s', 
                             [ProcessedFiles, TotalFiles, ExtractFileName(FilePath)]));
      crSkipped: 
        if Assigned(FLogCallback) then
          FLogCallback(Format('[%d/%d] 跳过转换: %s', 
                             [ProcessedFiles, TotalFiles, ExtractFileName(FilePath)]));
      crFailed: 
        if Assigned(FLogCallback) then
          FLogCallback(Format('[%d/%d] 转换失败: %s', 
                             [ProcessedFiles, TotalFiles, ExtractFileName(FilePath)]));
    end;
  end;
  
  if Assigned(FLogCallback) then
    FLogCallback(Format('批量转换完成: 总计 %d 个文件', [TotalFiles]));
end;

procedure TEncodingControllerOptimized.ConvertSelectedFilesToEncoding(const SelectedFiles: TArray<string>;
  const TargetEncodingName: string; AddBOM: Boolean;
  UpdateCallback: TProc<string, Integer, Integer>);
var
  FilePath: string;
  TotalFiles, ProcessedFiles: Integer;
  Result: TConversionResult;
begin
  TotalFiles := Length(SelectedFiles);
  ProcessedFiles := 0;
  
  if TotalFiles = 0 then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('没有选择要转换的文件');
    Exit;
  end;
  
  if Assigned(FLogCallback) then
    FLogCallback(Format('开始转换 %d 个选中文件到 %s (AddBOM: %s)', 
                       [TotalFiles, TargetEncodingName, BoolToStr(AddBOM, True)]));
  
  // 转换每个文件
  for FilePath in SelectedFiles do
  begin
    Inc(ProcessedFiles);
    
    // 更新进度
    if Assigned(UpdateCallback) then
      UpdateCallback(ExtractFileName(FilePath), ProcessedFiles, TotalFiles);
    
    // 转换文件
    Result := DoConvertSingleFileByName(FilePath, TargetEncodingName, AddBOM);
    
    // 记录结果
    case Result of
      crSuccess: 
        if Assigned(FLogCallback) then
          FLogCallback(Format('[%d/%d] 转换成功: %s', 
                             [ProcessedFiles, TotalFiles, ExtractFileName(FilePath)]));
      crSkipped: 
        if Assigned(FLogCallback) then
          FLogCallback(Format('[%d/%d] 跳过转换: %s', 
                             [ProcessedFiles, TotalFiles, ExtractFileName(FilePath)]));
      crFailed: 
        if Assigned(FLogCallback) then
          FLogCallback(Format('[%d/%d] 转换失败: %s', 
                             [ProcessedFiles, TotalFiles, ExtractFileName(FilePath)]));
    end;
  end;
  
  if Assigned(FLogCallback) then
    FLogCallback(Format('选中文件转换完成: 总计 %d 个文件', [TotalFiles]));
end;

procedure TEncodingControllerOptimized.SaveConversionConfig(const ConfigName: string; const Config: TBatchConversionConfig);
var
  ConfigFile: string;
  IniFile: TIniFile;
  ExtensionsStr: string;
  i: Integer;
begin
  // 保存配置到INI文件
  ConfigFile := ChangeFileExt(ParamStr(0), '.ini');
  
  IniFile := TIniFile.Create(ConfigFile);
  try
    // 保存配置到INI文件的指定节
    IniFile.WriteString(ConfigName, 'TargetEncoding', Config.TargetEncoding);
    IniFile.WriteBool(ConfigName, 'AddBOM', Config.AddBOM);
    IniFile.WriteBool(ConfigName, 'IncludeSubdirs', Config.IncludeSubdirs);
    
    // 将扩展名数组转换为分号分隔的字符串
    ExtensionsStr := '';
    for i := 0 to High(Config.FileExtensions) do
    begin
      if i > 0 then
        ExtensionsStr := ExtensionsStr + ';';
      ExtensionsStr := ExtensionsStr + Config.FileExtensions[i];
    end;
    
    IniFile.WriteString(ConfigName, 'FileExtensions', ExtensionsStr);
    
    // 同时保存到内存字典
    if FConversionConfigs.ContainsKey(ConfigName) then
      FConversionConfigs.Remove(ConfigName);
      
    FConversionConfigs.Add(ConfigName, Config);
    
    if Assigned(FLogCallback) then
      FLogCallback('已保存转换配置: ' + ConfigName);
  finally
    IniFile.Free;
  end;
end;

function TEncodingControllerOptimized.LoadConversionConfig(const ConfigName: string; out Config: TBatchConversionConfig): Boolean;
var
  ConfigFile: string;
  IniFile: TIniFile;
  ExtensionsStr: string;
  ExtensionList: TStringList;
  i: Integer;
begin
  Result := False;
  
  // 首先尝试从内存字典中获取
  if FConversionConfigs.TryGetValue(ConfigName, Config) then
  begin
    Result := True;
    Exit;
  end;
  
  // 从INI文件加载配置
  ConfigFile := ChangeFileExt(ParamStr(0), '.ini');
  
  if not FileExists(ConfigFile) then
    Exit;
  
  IniFile := TIniFile.Create(ConfigFile);
  try
    // 检查配置是否存在
    if not IniFile.SectionExists(ConfigName) then
      Exit;
    
    // 读取配置
    Config.Name := ConfigName;
    Config.TargetEncoding := IniFile.ReadString(ConfigName, 'TargetEncoding', 'UTF-8');
    Config.AddBOM := IniFile.ReadBool(ConfigName, 'AddBOM', True);
    Config.IncludeSubdirs := IniFile.ReadBool(ConfigName, 'IncludeSubdirs', False);
    
    // 读取扩展名列表
    ExtensionsStr := IniFile.ReadString(ConfigName, 'FileExtensions', '.txt;.pas;.dpr;.dfm');
    
    // 解析扩展名列表
    ExtensionList := TStringList.Create;
    try
      ExtensionList.Delimiter := ';';
      ExtensionList.StrictDelimiter := True;
      ExtensionList.DelimitedText := ExtensionsStr;
      
      SetLength(Config.FileExtensions, ExtensionList.Count);
      for i := 0 to ExtensionList.Count - 1 do
        Config.FileExtensions[i] := ExtensionList[i];
    finally
      ExtensionList.Free;
    end;
    
    // 保存到内存字典
    if FConversionConfigs.ContainsKey(ConfigName) then
      FConversionConfigs.Remove(ConfigName);
      
    FConversionConfigs.Add(ConfigName, Config);
    
    Result := True;
    
    if Assigned(FLogCallback) then
      FLogCallback('已加载转换配置: ' + ConfigName);
  finally
    IniFile.Free;
  end;
end;

procedure TEncodingControllerOptimized.DeleteConversionConfig(const ConfigName: string);
var
  ConfigFile: string;
  IniFile: TIniFile;
begin
  // 从内存字典中删除
  if FConversionConfigs.ContainsKey(ConfigName) then
    FConversionConfigs.Remove(ConfigName);
  
  // 从INI文件中删除
  ConfigFile := ChangeFileExt(ParamStr(0), '.ini');
  
  if FileExists(ConfigFile) then
  begin
    IniFile := TIniFile.Create(ConfigFile);
    try
      if IniFile.SectionExists(ConfigName) then
      begin
        IniFile.EraseSection(ConfigName);
        
        if Assigned(FLogCallback) then
          FLogCallback('已删除转换配置: ' + ConfigName);
      end;
    finally
      IniFile.Free;
    end;
  end;
end;

function TEncodingControllerOptimized.GetAllConfigNames: TArray<string>;
var
  ConfigFile: string;
  IniFile: TIniFile;
  Sections: TStringList;
  i: Integer;
begin
  Result := [];
  
  // 从INI文件中获取所有配置名称
  ConfigFile := ChangeFileExt(ParamStr(0), '.ini');
  
  if FileExists(ConfigFile) then
  begin
    IniFile := TIniFile.Create(ConfigFile);
    Sections := TStringList.Create;
    try
      IniFile.ReadSections(Sections);
      
      SetLength(Result, Sections.Count);
      for i := 0 to Sections.Count - 1 do
        Result[i] := Sections[i];
    finally
      Sections.Free;
      IniFile.Free;
    end;
  end;
end;

end.