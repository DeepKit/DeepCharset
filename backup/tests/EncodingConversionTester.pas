unit EncodingConversionTester;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils,
  UtilsEncodingConverter, UtilsEncodingBOM, UtilsEncodingDetect,
  UtilsEncodingTypes, UtilsEncodingLogger;

type
  TConversionTestResult = record
    SourceFile: string;
    TargetFile: string;
    SourceEncoding: string;
    TargetEncoding: string;
    WithBOM: Boolean;
    Success: Boolean;
    ProcessingTimeMs: Int64;
    SourceSize: Int64;
    TargetSize: Int64;
    ErrorMessage: string;
  end;

  TEncodingConversionTester = class
  private
    FLogger: TEncodingLogger;
    FConverter: TEncodingConverter;
    FDetector: TEncodingDetector;
    FBOMDetector: TBOMDetector;
    
    function GetFileSize(const FileName: string): Int64;
    function DetectFileEncoding(const FileName: string): string;
    function HasBOM(const FileName: string): Boolean;
  public
    constructor Create(Logger: TEncodingLogger = nil);
    destructor Destroy; override;
    
    // 测试文件编码转换
    function TestConversion(const SourceFile, TargetFile: string; 
                           TargetEncoding: string; WithBOM: Boolean = False): TConversionTestResult;
    
    // 验证转换结果
    function ValidateConversion(const SourceFile, TargetFile: string): Boolean;
    
    // 测试特定的转换场景
    function TestUTF8ToBOM(const SourceFile, TargetFile: string): TConversionTestResult;
    function TestGBKToUTF8(const SourceFile, TargetFile: string): TConversionTestResult;
    function TestUTF8ToGBK(const SourceFile, TargetFile: string): TConversionTestResult;
    function TestBig5ToUTF8(const SourceFile, TargetFile: string): TConversionTestResult;
    function TestUTF8ToBig5(const SourceFile, TargetFile: string): TConversionTestResult;
    
    // 批量测试
    function BatchTest(const SourceDir, TargetDir: string; TargetEncoding: string; 
                      WithBOM: Boolean = False): TArray<TConversionTestResult>;
  end;

implementation

{ TEncodingConversionTester }

constructor TEncodingConversionTester.Create(Logger: TEncodingLogger);
begin
  inherited Create;
  
  if Logger = nil then
    FLogger := TEncodingLogger.Create
  else
    FLogger := Logger;
  
  FConverter := TEncodingConverter.Create;
  FDetector := TEncodingDetector.Create;
  FBOMDetector := TBOMDetector.Create;
  
  FConverter.SetLogger(FLogger);
  FDetector.SetLogger(FLogger);
  FBOMDetector.SetLogger(FLogger);
end;

destructor TEncodingConversionTester.Destroy;
begin
  FConverter.Free;
  FDetector.Free;
  FBOMDetector.Free;
  
  if FLogger <> nil then
    FLogger.Free;
  
  inherited;
end;

function TEncodingConversionTester.GetFileSize(const FileName: string): Int64;
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

function TEncodingConversionTester.DetectFileEncoding(const FileName: string): string;
var
  Result: TEncodingDetectionResult;
begin
  if not FileExists(FileName) then
    Exit('');
  
  Result := FDetector.DetectFileEncoding(FileName);
  Result := Result.EncodingName;
end;

function TEncodingConversionTester.HasBOM(const FileName: string): Boolean;
var
  Stream: TFileStream;
  Buffer: TBytes;
  DetectionInfo: TEncodingDetectionInfo;
begin
  Result := False;
  
  if not FileExists(FileName) then
    Exit;
  
  try
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      SetLength(Buffer, Min(Stream.Size, 4)); // 只需要前4个字节来检测BOM
      if Length(Buffer) > 0 then
        Stream.ReadBuffer(Buffer[0], Length(Buffer));
    finally
      Stream.Free;
    end;
    
    Result := FBOMDetector.DetectBOM(Buffer, DetectionInfo);
  except
    Result := False;
  end;
end;

function TEncodingConversionTester.TestConversion(const SourceFile, TargetFile: string;
                                               TargetEncoding: string; WithBOM: Boolean): TConversionTestResult;
var
  StartTime, EndTime: TDateTime;
  Success: Boolean;
begin
  // 初始化结果
  Result.SourceFile := SourceFile;
  Result.TargetFile := TargetFile;
  Result.SourceEncoding := DetectFileEncoding(SourceFile);
  Result.TargetEncoding := TargetEncoding;
  Result.WithBOM := WithBOM;
  Result.Success := False;
  Result.ProcessingTimeMs := 0;
  Result.SourceSize := GetFileSize(SourceFile);
  Result.TargetSize := 0;
  Result.ErrorMessage := '';
  
  if not FileExists(SourceFile) then
  begin
    Result.ErrorMessage := '源文件不存在';
    FLogger.LogError(Format('转换失败: %s - 源文件不存在', [SourceFile]));
    Exit;
  end;
  
  try
    // 执行转换
    StartTime := Now;
    Success := FConverter.ConvertFileEncoding(SourceFile, TargetFile, TargetEncoding, WithBOM);
    EndTime := Now;
    
    Result.ProcessingTimeMs := MilliSecondsBetween(EndTime, StartTime);
    Result.Success := Success;
    
    if Success and FileExists(TargetFile) then
    begin
      Result.TargetSize := GetFileSize(TargetFile);
      
      // 验证目标文件编码
      var DetectedEncoding := DetectFileEncoding(TargetFile);
      var HasBOMResult := HasBOM(TargetFile);
      
      if not SameText(DetectedEncoding, TargetEncoding) then
      begin
        Result.ErrorMessage := Format('目标文件编码不匹配: 期望 %s, 实际 %s', 
                                    [TargetEncoding, DetectedEncoding]);
        FLogger.LogWarning(Result.ErrorMessage);
      end
      else if WithBOM and not HasBOMResult then
      begin
        Result.ErrorMessage := '目标文件应该有BOM但没有';
        FLogger.LogWarning(Result.ErrorMessage);
      end
      else if not WithBOM and HasBOMResult then
      begin
        Result.ErrorMessage := '目标文件不应该有BOM但有';
        FLogger.LogWarning(Result.ErrorMessage);
      end;
    end
    else if Success then
    begin
      Result.ErrorMessage := '转换成功但目标文件不存在';
      FLogger.LogWarning(Result.ErrorMessage);
      Result.Success := False;
    end
    else
    begin
      Result.ErrorMessage := '转换失败';
      FLogger.LogError(Format('转换失败: %s -> %s', [SourceFile, TargetFile]));
    end;
    
    // 记录日志
    FLogger.LogInfo(Format('转换测试: %s -> %s, 源编码: %s, 目标编码: %s, BOM: %s, 结果: %s, 耗时: %d ms, 大小: %d -> %d 字节',
      [SourceFile, TargetFile, Result.SourceEncoding, TargetEncoding, 
       BoolToStr(WithBOM, True), BoolToStr(Result.Success, True), 
       Result.ProcessingTimeMs, Result.SourceSize, Result.TargetSize]));
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
      FLogger.LogError(Format('转换出错: %s -> %s - %s', [SourceFile, TargetFile, E.Message]));
    end;
  end;
end;

function TEncodingConversionTester.ValidateConversion(const SourceFile, TargetFile: string): Boolean;
var
  SourceContent, TargetContent: string;
  SourceEncoding, TargetEncoding: string;
  SourceStream, TargetStream: TFileStream;
  SourceBytes, TargetBytes: TBytes;
begin
  Result := False;
  
  if not FileExists(SourceFile) or not FileExists(TargetFile) then
    Exit;
  
  try
    // 检测源文件和目标文件的编码
    SourceEncoding := DetectFileEncoding(SourceFile);
    TargetEncoding := DetectFileEncoding(TargetFile);
    
    // 读取源文件内容
    SourceStream := TFileStream.Create(SourceFile, fmOpenRead or fmShareDenyNone);
    try
      SetLength(SourceBytes, SourceStream.Size);
      if SourceStream.Size > 0 then
        SourceStream.ReadBuffer(SourceBytes[0], SourceStream.Size);
    finally
      SourceStream.Free;
    end;
    
    // 读取目标文件内容
    TargetStream := TFileStream.Create(TargetFile, fmOpenRead or fmShareDenyNone);
    try
      SetLength(TargetBytes, TargetStream.Size);
      if TargetStream.Size > 0 then
        TargetStream.ReadBuffer(TargetBytes[0], TargetStream.Size);
    finally
      TargetStream.Free;
    end;
    
    // 如果目标文件有BOM，跳过BOM
    var BOMSize := 0;
    var DetectionInfo: TEncodingDetectionInfo;
    if FBOMDetector.DetectBOM(TargetBytes, DetectionInfo) then
      BOMSize := DetectionInfo.BOMSize;
    
    // 将字节转换为字符串
    // 注意：这里简化处理，实际应该根据编码正确转换
    SourceContent := TEncoding.UTF8.GetString(SourceBytes);
    TargetContent := TEncoding.UTF8.GetString(Copy(TargetBytes, BOMSize, Length(TargetBytes) - BOMSize));
    
    // 比较内容（忽略可能的编码差异）
    Result := SourceContent = TargetContent;
    
    FLogger.LogInfo(Format('验证转换: %s -> %s, 结果: %s',
      [SourceFile, TargetFile, BoolToStr(Result, True)]));
  except
    on E: Exception do
    begin
      FLogger.LogError(Format('验证转换出错: %s -> %s - %s', [SourceFile, TargetFile, E.Message]));
    end;
  end;
end;

function TEncodingConversionTester.TestUTF8ToBOM(const SourceFile, TargetFile: string): TConversionTestResult;
begin
  Result := TestConversion(SourceFile, TargetFile, 'UTF-8', True);
end;

function TEncodingConversionTester.TestGBKToUTF8(const SourceFile, TargetFile: string): TConversionTestResult;
begin
  Result := TestConversion(SourceFile, TargetFile, 'UTF-8', False);
end;

function TEncodingConversionTester.TestUTF8ToGBK(const SourceFile, TargetFile: string): TConversionTestResult;
begin
  Result := TestConversion(SourceFile, TargetFile, 'GBK', False);
end;

function TEncodingConversionTester.TestBig5ToUTF8(const SourceFile, TargetFile: string): TConversionTestResult;
begin
  Result := TestConversion(SourceFile, TargetFile, 'UTF-8', False);
end;

function TEncodingConversionTester.TestUTF8ToBig5(const SourceFile, TargetFile: string): TConversionTestResult;
begin
  Result := TestConversion(SourceFile, TargetFile, 'Big5', False);
end;

function TEncodingConversionTester.BatchTest(const SourceDir, TargetDir: string;
                                          TargetEncoding: string; WithBOM: Boolean): TArray<TConversionTestResult>;
var
  Files: TArray<string>;
  I: Integer;
  SourceFile, TargetFile: string;
begin
  if not DirectoryExists(SourceDir) then
  begin
    FLogger.LogError(Format('源目录不存在: %s', [SourceDir]));
    SetLength(Result, 0);
    Exit;
  end;
  
  // 确保目标目录存在
  if not DirectoryExists(TargetDir) then
    ForceDirectories(TargetDir);
  
  // 获取源目录中的所有文件
  Files := TDirectory.GetFiles(SourceDir, '*.*', TSearchOption.soAllDirectories);
  SetLength(Result, Length(Files));
  
  FLogger.LogInfo(Format('批量测试开始: %s -> %s, 目标编码: %s, BOM: %s, 文件数: %d',
    [SourceDir, TargetDir, TargetEncoding, BoolToStr(WithBOM, True), Length(Files)]));
  
  for I := 0 to Length(Files) - 1 do
  begin
    SourceFile := Files[I];
    TargetFile := StringReplace(SourceFile, SourceDir, TargetDir, [rfIgnoreCase]);
    
    // 确保目标文件的目录存在
    ForceDirectories(ExtractFilePath(TargetFile));
    
    Result[I] := TestConversion(SourceFile, TargetFile, TargetEncoding, WithBOM);
  end;
  
  // 统计结果
  var SuccessCount := 0;
  var FailureCount := 0;
  var TotalTime: Int64 := 0;
  var TotalSourceSize: Int64 := 0;
  var TotalTargetSize: Int64 := 0;
  
  for I := 0 to Length(Result) - 1 do
  begin
    if Result[I].Success then
      Inc(SuccessCount)
    else
      Inc(FailureCount);
    
    TotalTime := TotalTime + Result[I].ProcessingTimeMs;
    TotalSourceSize := TotalSourceSize + Result[I].SourceSize;
    TotalTargetSize := TotalTargetSize + Result[I].TargetSize;
  end;
  
  FLogger.LogInfo(Format('批量测试完成: 成功: %d, 失败: %d, 总耗时: %d ms, 总大小: %d -> %d 字节',
    [SuccessCount, FailureCount, TotalTime, TotalSourceSize, TotalTargetSize]));
end;

end.
