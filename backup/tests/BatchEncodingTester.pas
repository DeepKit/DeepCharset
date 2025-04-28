unit BatchEncodingTester;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, System.IOUtils,
  EncodingDetectionTester, EncodingConversionTester,
  UtilsEncodingLogger;

type
  TBatchTestResult = record
    DirectoryPath: string;
    FilesProcessed: Integer;
    DetectionSuccessCount: Integer;
    DetectionFailureCount: Integer;
    ConversionSuccessCount: Integer;
    ConversionFailureCount: Integer;
    TotalDetectionTimeMs: Int64;
    TotalConversionTimeMs: Int64;
    TotalSourceSize: Int64;
    TotalTargetSize: Int64;
  end;

  TBatchEncodingTester = class
  private
    FLogger: TEncodingLogger;
    FDetectionTester: TEncodingDetectionTester;
    FConversionTester: TEncodingConversionTester;
    
    function GetFileSize(const FileName: string): Int64;
  public
    constructor Create(Logger: TEncodingLogger = nil);
    destructor Destroy; override;
    
    // 批量检测目录中的文件编码
    function BatchDetect(const DirectoryPath: string; const FileMask: string = '*.*'): TBatchTestResult;
    
    // 批量转换目录中的文件编码
    function BatchConvert(const SourceDir, TargetDir: string; TargetEncoding: string; 
                         WithBOM: Boolean = False; const FileMask: string = '*.*'): TBatchTestResult;
    
    // 生成批量测试报告
    procedure GenerateReport(const ReportFile: string; const Result: TBatchTestResult);
    
    // 比较不同检测器的结果
    procedure CompareDetectors(const DirectoryPath: string; const FileMask: string = '*.*');
    
    // 测试特定的转换场景
    procedure TestUTF8ToBOM(const SourceDir, TargetDir: string; const FileMask: string = '*.*');
    procedure TestGBKToUTF8(const SourceDir, TargetDir: string; const FileMask: string = '*.*');
    procedure TestUTF8ToGBK(const SourceDir, TargetDir: string; const FileMask: string = '*.*');
  end;

implementation

{ TBatchEncodingTester }

constructor TBatchEncodingTester.Create(Logger: TEncodingLogger);
begin
  inherited Create;
  
  if Logger = nil then
    FLogger := TEncodingLogger.Create
  else
    FLogger := Logger;
  
  FDetectionTester := TEncodingDetectionTester.Create(FLogger);
  FConversionTester := TEncodingConversionTester.Create(FLogger);
end;

destructor TBatchEncodingTester.Destroy;
begin
  FDetectionTester.Free;
  FConversionTester.Free;
  
  if FLogger <> nil then
    FLogger.Free;
  
  inherited;
end;

function TBatchEncodingTester.GetFileSize(const FileName: string): Int64;
begin
  Result := 0;
  
  if FileExists(FileName) then
  begin
    with TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone) do
    try
      Result := Size;
    finally
      Free;
    end;
  end;
end;

function TBatchEncodingTester.BatchDetect(const DirectoryPath: string; const FileMask: string): TBatchTestResult;
var
  Files: TArray<string>;
  I: Integer;
  DetectionResult: TDetectionTestResult;
begin
  // 初始化结果
  Result.DirectoryPath := DirectoryPath;
  Result.FilesProcessed := 0;
  Result.DetectionSuccessCount := 0;
  Result.DetectionFailureCount := 0;
  Result.ConversionSuccessCount := 0;
  Result.ConversionFailureCount := 0;
  Result.TotalDetectionTimeMs := 0;
  Result.TotalConversionTimeMs := 0;
  Result.TotalSourceSize := 0;
  Result.TotalTargetSize := 0;
  
  if not DirectoryExists(DirectoryPath) then
  begin
    FLogger.LogError(Format('目录不存在: %s', [DirectoryPath]));
    Exit;
  end;
  
  // 获取目录中的所有文件
  Files := TDirectory.GetFiles(DirectoryPath, FileMask, TSearchOption.soAllDirectories);
  Result.FilesProcessed := Length(Files);
  
  FLogger.LogInfo(Format('批量检测开始: %s, 文件数: %d', [DirectoryPath, Length(Files)]));
  
  for I := 0 to Length(Files) - 1 do
  begin
    try
      // 检测文件编码
      DetectionResult := FDetectionTester.TestWithEncodingDetector(Files[I]);
      
      // 更新统计信息
      if DetectionResult.DetectedEncoding <> '' then
        Inc(Result.DetectionSuccessCount)
      else
        Inc(Result.DetectionFailureCount);
      
      Result.TotalDetectionTimeMs := Result.TotalDetectionTimeMs + DetectionResult.ProcessingTimeMs;
      Result.TotalSourceSize := Result.TotalSourceSize + DetectionResult.FileSize;
      
      FLogger.LogInfo(Format('检测文件 %d/%d: %s, 编码: %s, 置信度: %.2f, BOM: %s, 耗时: %d ms',
        [I+1, Length(Files), ExtractFileName(Files[I]), DetectionResult.DetectedEncoding, 
         DetectionResult.Confidence, BoolToStr(DetectionResult.HasBOM, True), 
         DetectionResult.ProcessingTimeMs]));
    except
      on E: Exception do
      begin
        Inc(Result.DetectionFailureCount);
        FLogger.LogError(Format('检测文件出错: %s - %s', [Files[I], E.Message]));
      end;
    end;
  end;
  
  FLogger.LogInfo(Format('批量检测完成: 成功: %d, 失败: %d, 总耗时: %d ms, 总大小: %d 字节',
    [Result.DetectionSuccessCount, Result.DetectionFailureCount, 
     Result.TotalDetectionTimeMs, Result.TotalSourceSize]));
end;

function TBatchEncodingTester.BatchConvert(const SourceDir, TargetDir: string;
                                        TargetEncoding: string; WithBOM: Boolean;
                                        const FileMask: string): TBatchTestResult;
var
  Files: TArray<string>;
  I: Integer;
  SourceFile, TargetFile: string;
  ConversionResult: TConversionTestResult;
begin
  // 初始化结果
  Result.DirectoryPath := SourceDir;
  Result.FilesProcessed := 0;
  Result.DetectionSuccessCount := 0;
  Result.DetectionFailureCount := 0;
  Result.ConversionSuccessCount := 0;
  Result.ConversionFailureCount := 0;
  Result.TotalDetectionTimeMs := 0;
  Result.TotalConversionTimeMs := 0;
  Result.TotalSourceSize := 0;
  Result.TotalTargetSize := 0;
  
  if not DirectoryExists(SourceDir) then
  begin
    FLogger.LogError(Format('源目录不存在: %s', [SourceDir]));
    Exit;
  end;
  
  // 确保目标目录存在
  if not DirectoryExists(TargetDir) then
    ForceDirectories(TargetDir);
  
  // 获取源目录中的所有文件
  Files := TDirectory.GetFiles(SourceDir, FileMask, TSearchOption.soAllDirectories);
  Result.FilesProcessed := Length(Files);
  
  FLogger.LogInfo(Format('批量转换开始: %s -> %s, 目标编码: %s, BOM: %s, 文件数: %d',
    [SourceDir, TargetDir, TargetEncoding, BoolToStr(WithBOM, True), Length(Files)]));
  
  for I := 0 to Length(Files) - 1 do
  begin
    try
      SourceFile := Files[I];
      TargetFile := StringReplace(SourceFile, SourceDir, TargetDir, [rfIgnoreCase]);
      
      // 确保目标文件的目录存在
      ForceDirectories(ExtractFilePath(TargetFile));
      
      // 转换文件编码
      ConversionResult := FConversionTester.TestConversion(SourceFile, TargetFile, TargetEncoding, WithBOM);
      
      // 更新统计信息
      if ConversionResult.Success then
        Inc(Result.ConversionSuccessCount)
      else
        Inc(Result.ConversionFailureCount);
      
      Result.TotalConversionTimeMs := Result.TotalConversionTimeMs + ConversionResult.ProcessingTimeMs;
      Result.TotalSourceSize := Result.TotalSourceSize + ConversionResult.SourceSize;
      Result.TotalTargetSize := Result.TotalTargetSize + ConversionResult.TargetSize;
      
      FLogger.LogInfo(Format('转换文件 %d/%d: %s -> %s, 结果: %s, 耗时: %d ms',
        [I+1, Length(Files), ExtractFileName(SourceFile), ExtractFileName(TargetFile), 
         BoolToStr(ConversionResult.Success, True), ConversionResult.ProcessingTimeMs]));
    except
      on E: Exception do
      begin
        Inc(Result.ConversionFailureCount);
        FLogger.LogError(Format('转换文件出错: %s - %s', [Files[I], E.Message]));
      end;
    end;
  end;
  
  FLogger.LogInfo(Format('批量转换完成: 成功: %d, 失败: %d, 总耗时: %d ms, 总大小: %d -> %d 字节',
    [Result.ConversionSuccessCount, Result.ConversionFailureCount, 
     Result.TotalConversionTimeMs, Result.TotalSourceSize, Result.TotalTargetSize]));
end;

procedure TBatchEncodingTester.GenerateReport(const ReportFile: string; const Result: TBatchTestResult);
var
  Report: TStringList;
begin
  Report := TStringList.Create;
  try
    Report.Add('批量测试报告');
    Report.Add('============');
    Report.Add('');
    Report.Add(Format('测试时间: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
    Report.Add(Format('目录: %s', [Result.DirectoryPath]));
    Report.Add(Format('处理文件数: %d', [Result.FilesProcessed]));
    Report.Add('');
    
    Report.Add('检测结果:');
    Report.Add(Format('  成功: %d', [Result.DetectionSuccessCount]));
    Report.Add(Format('  失败: %d', [Result.DetectionFailureCount]));
    Report.Add(Format('  总耗时: %d ms', [Result.TotalDetectionTimeMs]));
    if Result.DetectionSuccessCount > 0 then
      Report.Add(Format('  平均耗时: %.2f ms/文件', [Result.TotalDetectionTimeMs / Result.DetectionSuccessCount]));
    Report.Add('');
    
    Report.Add('转换结果:');
    Report.Add(Format('  成功: %d', [Result.ConversionSuccessCount]));
    Report.Add(Format('  失败: %d', [Result.ConversionFailureCount]));
    Report.Add(Format('  总耗时: %d ms', [Result.TotalConversionTimeMs]));
    if Result.ConversionSuccessCount > 0 then
      Report.Add(Format('  平均耗时: %.2f ms/文件', [Result.TotalConversionTimeMs / Result.ConversionSuccessCount]));
    Report.Add('');
    
    Report.Add('文件大小:');
    Report.Add(Format('  源文件总大小: %d 字节', [Result.TotalSourceSize]));
    Report.Add(Format('  目标文件总大小: %d 字节', [Result.TotalTargetSize]));
    if (Result.TotalSourceSize > 0) and (Result.TotalTargetSize > 0) then
      Report.Add(Format('  大小比例: %.2f%%', [Result.TotalTargetSize / Result.TotalSourceSize * 100]));
    
    Report.SaveToFile(ReportFile);
    
    FLogger.LogInfo(Format('测试报告已保存到: %s', [ReportFile]));
  finally
    Report.Free;
  end;
end;

procedure TBatchEncodingTester.CompareDetectors(const DirectoryPath: string; const FileMask: string);
var
  Files: TArray<string>;
  I: Integer;
  Results: TArray<TDetectionTestResult>;
  Report: TStringList;
  ReportFile: string;
begin
  if not DirectoryExists(DirectoryPath) then
  begin
    FLogger.LogError(Format('目录不存在: %s', [DirectoryPath]));
    Exit;
  end;
  
  // 获取目录中的所有文件
  Files := TDirectory.GetFiles(DirectoryPath, FileMask, TSearchOption.soAllDirectories);
  
  FLogger.LogInfo(Format('检测器比较开始: %s, 文件数: %d', [DirectoryPath, Length(Files)]));
  
  // 创建报告
  Report := TStringList.Create;
  try
    Report.Add('检测器比较报告');
    Report.Add('==============');
    Report.Add('');
    Report.Add(Format('测试时间: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
    Report.Add(Format('目录: %s', [DirectoryPath]));
    Report.Add(Format('文件数: %d', [Length(Files)]));
    Report.Add('');
    Report.Add('文件,BOM检测器,UTF-8检测器,编码检测器,BOM检测时间(ms),UTF-8检测时间(ms),编码检测时间(ms)');
    
    for I := 0 to Length(Files) - 1 do
    begin
      try
        // 比较不同检测器的结果
        Results := FDetectionTester.CompareDetectors(Files[I]);
        
        // 添加到报告
        Report.Add(Format('%s,%s,%s,%s,%d,%d,%d',
          [ExtractFileName(Files[I]), Results[0].DetectedEncoding, Results[1].DetectedEncoding, 
           Results[2].DetectedEncoding, Results[0].ProcessingTimeMs, Results[1].ProcessingTimeMs, 
           Results[2].ProcessingTimeMs]));
        
        FLogger.LogInfo(Format('比较文件 %d/%d: %s', [I+1, Length(Files), ExtractFileName(Files[I])]));
      except
        on E: Exception do
        begin
          FLogger.LogError(Format('比较文件出错: %s - %s', [Files[I], E.Message]));
          Report.Add(Format('%s,Error,Error,Error,0,0,0', [ExtractFileName(Files[I])]));
        end;
      end;
    end;
    
    // 保存报告
    ReportFile := 'detector_comparison_report.csv';
    Report.SaveToFile(ReportFile);
    
    FLogger.LogInfo(Format('检测器比较完成，报告已保存到: %s', [ReportFile]));
  finally
    Report.Free;
  end;
end;

procedure TBatchEncodingTester.TestUTF8ToBOM(const SourceDir, TargetDir: string; const FileMask: string);
var
  Result: TBatchTestResult;
begin
  Result := BatchConvert(SourceDir, TargetDir, 'UTF-8', True, FileMask);
  GenerateReport('utf8_to_bom_report.txt', Result);
end;

procedure TBatchEncodingTester.TestGBKToUTF8(const SourceDir, TargetDir: string; const FileMask: string);
var
  Result: TBatchTestResult;
begin
  Result := BatchConvert(SourceDir, TargetDir, 'UTF-8', False, FileMask);
  GenerateReport('gbk_to_utf8_report.txt', Result);
end;

procedure TBatchEncodingTester.TestUTF8ToGBK(const SourceDir, TargetDir: string; const FileMask: string);
var
  Result: TBatchTestResult;
begin
  Result := BatchConvert(SourceDir, TargetDir, 'GBK', False, FileMask);
  GenerateReport('utf8_to_gbk_report.txt', Result);
end;

end.
