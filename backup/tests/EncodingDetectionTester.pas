unit EncodingDetectionTester;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils,
  UtilsEncodingBOM, UtilsEncodingUTF8Detector, UtilsEncodingDetect,
  UtilsEncodingTypes, UtilsEncodingLogger;

type
  TDetectionTestResult = record
    FileName: string;
    DetectedEncoding: string;
    Confidence: Double;
    HasBOM: Boolean;
    ProcessingTimeMs: Int64;
    FileSize: Int64;
  end;

  TEncodingDetectionTester = class
  private
    FLogger: TEncodingLogger;
    FBOMDetector: TBOMDetector;
    FUTF8Detector: TUTF8EncodingDetector;
    FEncodingDetector: TEncodingDetector;
    
    function GetFileSize(const FileName: string): Int64;
  public
    constructor Create(Logger: TEncodingLogger = nil);
    destructor Destroy; override;
    
    // 使用BOM检测器测试文件
    function TestWithBOMDetector(const FileName: string): TDetectionTestResult;
    
    // 使用UTF-8检测器测试文件
    function TestWithUTF8Detector(const FileName: string): TDetectionTestResult;
    
    // 使用编码检测器测试文件
    function TestWithEncodingDetector(const FileName: string): TDetectionTestResult;
    
    // 比较不同检测器的结果
    function CompareDetectors(const FileName: string): TArray<TDetectionTestResult>;
    
    // 验证检测结果
    function ValidateDetection(const FileName: string; ExpectedEncoding: string): Boolean;
  end;

implementation

{ TEncodingDetectionTester }

constructor TEncodingDetectionTester.Create(Logger: TEncodingLogger);
begin
  inherited Create;
  
  if Logger = nil then
    FLogger := TEncodingLogger.Create
  else
    FLogger := Logger;
  
  FBOMDetector := TBOMDetector.Create;
  FUTF8Detector := TUTF8EncodingDetector.Create;
  FEncodingDetector := TEncodingDetector.Create;
  
  FBOMDetector.SetLogger(FLogger);
  FUTF8Detector.SetLogger(FLogger);
  FEncodingDetector.SetLogger(FLogger);
end;

destructor TEncodingDetectionTester.Destroy;
begin
  FBOMDetector.Free;
  FUTF8Detector.Free;
  FEncodingDetector.Free;
  
  if FLogger <> nil then
    FLogger.Free;
  
  inherited;
end;

function TEncodingDetectionTester.GetFileSize(const FileName: string): Int64;
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

function TEncodingDetectionTester.TestWithBOMDetector(const FileName: string): TDetectionTestResult;
var
  Buffer: TBytes;
  DetectionInfo: TEncodingDetectionInfo;
  StartTime, EndTime: TDateTime;
  Stream: TFileStream;
begin
  Result.FileName := FileName;
  Result.DetectedEncoding := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.ProcessingTimeMs := 0;
  Result.FileSize := GetFileSize(FileName);
  
  if not FileExists(FileName) then
    Exit;
  
  try
    // 读取文件内容
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      SetLength(Buffer, Stream.Size);
      Stream.ReadBuffer(Buffer[0], Stream.Size);
    finally
      Stream.Free;
    end;
    
    // 使用BOM检测器检测编码
    StartTime := Now;
    if FBOMDetector.DetectBOM(Buffer, DetectionInfo) then
    begin
      Result.DetectedEncoding := DetectionInfo.EncodingName;
      Result.Confidence := 1.0; // BOM检测的置信度为100%
      Result.HasBOM := True;
    end
    else
    begin
      Result.DetectedEncoding := 'Unknown';
      Result.Confidence := 0;
      Result.HasBOM := False;
    end;
    EndTime := Now;
    
    Result.ProcessingTimeMs := MilliSecondsBetween(EndTime, StartTime);
    
    FLogger.LogInfo(Format('BOM检测: %s, 编码: %s, BOM: %s, 耗时: %d ms',
      [FileName, Result.DetectedEncoding, BoolToStr(Result.HasBOM, True), Result.ProcessingTimeMs]));
  except
    on E: Exception do
    begin
      FLogger.LogError(Format('BOM检测出错: %s - %s', [FileName, E.Message]));
      Result.DetectedEncoding := 'Error: ' + E.Message;
    end;
  end;
end;

function TEncodingDetectionTester.TestWithUTF8Detector(const FileName: string): TDetectionTestResult;
var
  Buffer: TBytes;
  Stats: TEncodingStats;
  Confidence: Double;
  StartTime, EndTime: TDateTime;
  Stream: TFileStream;
begin
  Result.FileName := FileName;
  Result.DetectedEncoding := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.ProcessingTimeMs := 0;
  Result.FileSize := GetFileSize(FileName);
  
  if not FileExists(FileName) then
    Exit;
  
  try
    // 读取文件内容
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      SetLength(Buffer, Stream.Size);
      Stream.ReadBuffer(Buffer[0], Stream.Size);
    finally
      Stream.Free;
    end;
    
    // 检查BOM
    var DetectionInfo: TEncodingDetectionInfo;
    if FBOMDetector.DetectBOM(Buffer, DetectionInfo) and (DetectionInfo.EncodingName = 'UTF-8') then
    begin
      Result.DetectedEncoding := 'UTF-8';
      Result.Confidence := 1.0;
      Result.HasBOM := True;
      Result.ProcessingTimeMs := 0;
      Exit;
    end;
    
    // 使用UTF-8检测器检测编码
    StartTime := Now;
    Confidence := FUTF8Detector.ValidateUTF8ContentImproved(Buffer, Stats);
    EndTime := Now;
    
    Result.ProcessingTimeMs := MilliSecondsBetween(EndTime, StartTime);
    
    if Confidence > 0.5 then
    begin
      Result.DetectedEncoding := 'UTF-8';
      Result.Confidence := Confidence;
      Result.HasBOM := False;
    end
    else
    begin
      Result.DetectedEncoding := 'Not UTF-8';
      Result.Confidence := 1.0 - Confidence;
      Result.HasBOM := False;
    end;
    
    FLogger.LogInfo(Format('UTF-8检测: %s, 编码: %s, 置信度: %.2f, 耗时: %d ms',
      [FileName, Result.DetectedEncoding, Result.Confidence, Result.ProcessingTimeMs]));
  except
    on E: Exception do
    begin
      FLogger.LogError(Format('UTF-8检测出错: %s - %s', [FileName, E.Message]));
      Result.DetectedEncoding := 'Error: ' + E.Message;
    end;
  end;
end;

function TEncodingDetectionTester.TestWithEncodingDetector(const FileName: string): TDetectionTestResult;
var
  DetectionResult: TEncodingDetectionResult;
  StartTime, EndTime: TDateTime;
begin
  Result.FileName := FileName;
  Result.DetectedEncoding := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.ProcessingTimeMs := 0;
  Result.FileSize := GetFileSize(FileName);
  
  if not FileExists(FileName) then
    Exit;
  
  try
    // 使用编码检测器检测编码
    StartTime := Now;
    DetectionResult := FEncodingDetector.DetectFileEncoding(FileName);
    EndTime := Now;
    
    Result.ProcessingTimeMs := MilliSecondsBetween(EndTime, StartTime);
    Result.DetectedEncoding := DetectionResult.EncodingName;
    Result.Confidence := DetectionResult.Confidence;
    Result.HasBOM := DetectionResult.HasBOM;
    
    FLogger.LogInfo(Format('编码检测: %s, 编码: %s, 置信度: %.2f, BOM: %s, 耗时: %d ms',
      [FileName, Result.DetectedEncoding, Result.Confidence, BoolToStr(Result.HasBOM, True), Result.ProcessingTimeMs]));
  except
    on E: Exception do
    begin
      FLogger.LogError(Format('编码检测出错: %s - %s', [FileName, E.Message]));
      Result.DetectedEncoding := 'Error: ' + E.Message;
    end;
  end;
end;

function TEncodingDetectionTester.CompareDetectors(const FileName: string): TArray<TDetectionTestResult>;
begin
  SetLength(Result, 3);
  
  Result[0] := TestWithBOMDetector(FileName);
  Result[1] := TestWithUTF8Detector(FileName);
  Result[2] := TestWithEncodingDetector(FileName);
  
  FLogger.LogInfo(Format('检测器比较: %s', [FileName]));
  FLogger.LogInfo(Format('  BOM检测器: %s, 置信度: %.2f, BOM: %s, 耗时: %d ms',
    [Result[0].DetectedEncoding, Result[0].Confidence, BoolToStr(Result[0].HasBOM, True), Result[0].ProcessingTimeMs]));
  FLogger.LogInfo(Format('  UTF-8检测器: %s, 置信度: %.2f, BOM: %s, 耗时: %d ms',
    [Result[1].DetectedEncoding, Result[1].Confidence, BoolToStr(Result[1].HasBOM, True), Result[1].ProcessingTimeMs]));
  FLogger.LogInfo(Format('  编码检测器: %s, 置信度: %.2f, BOM: %s, 耗时: %d ms',
    [Result[2].DetectedEncoding, Result[2].Confidence, BoolToStr(Result[2].HasBOM, True), Result[2].ProcessingTimeMs]));
end;

function TEncodingDetectionTester.ValidateDetection(const FileName: string; ExpectedEncoding: string): Boolean;
var
  Result1, Result2, Result3: TDetectionTestResult;
begin
  Result1 := TestWithBOMDetector(FileName);
  Result2 := TestWithUTF8Detector(FileName);
  Result3 := TestWithEncodingDetector(FileName);
  
  // 如果BOM检测器检测到BOM，则以BOM检测结果为准
  if Result1.HasBOM then
    Result := SameText(Result1.DetectedEncoding, ExpectedEncoding)
  // 如果期望编码是UTF-8，则以UTF-8检测器结果为准
  else if SameText(ExpectedEncoding, 'UTF-8') then
    Result := SameText(Result2.DetectedEncoding, 'UTF-8')
  // 否则以编码检测器结果为准
  else
    Result := SameText(Result3.DetectedEncoding, ExpectedEncoding);
  
  FLogger.LogInfo(Format('验证检测: %s, 期望编码: %s, 结果: %s',
    [FileName, ExpectedEncoding, BoolToStr(Result, True)]));
end;

end.
