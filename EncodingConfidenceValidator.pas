unit EncodingConfidenceValidator;

{
  EncodingConfidenceValidator.pas
  编码检测置信度评分验证功能
  
  作为improve.md中任务2.1.4的实现
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Math,
  EncodingTestSampleManager, EncodingTestStatistics;

type
  /// <summary>
  /// 置信度评分验证结果
  /// </summary>
  TConfidenceValidationResult = record
    IsValid: Boolean;                     // 是否有效
    ExpectedAccuracy: Double;             // 期望正确率
    ActualAccuracy: Double;               // 实际正确率
    Deviation: Double;                    // 偏差
    DeviationPercentage: Double;          // 偏差百分比
    SampleCount: Integer;                 // 样本数
    
    constructor Create(AIsValid: Boolean; AExpectedAccuracy, AActualAccuracy: Double; ASampleCount: Integer);
  end;
  
  /// <summary>
  /// 置信度区间验证结果
  /// </summary>
  TConfidenceIntervalValidationResult = record
    Interval: string;                     // 区间描述（如"0.0-0.1"）
    ValidationResult: TConfidenceValidationResult; // 验证结果
    
    constructor Create(const AInterval: string; const AValidationResult: TConfidenceValidationResult);
  end;
  
  /// <summary>
  /// 编码检测置信度评分验证器
  /// </summary>
  TEncodingConfidenceValidator = class
  private
    FSampleManager: TEncodingTestSampleManager;
    FStatistics: TEncodingTestStatistics;
    FLogCallback: TProc<string>;
    
    procedure Log(const Msg: string);
  public
    constructor Create(ASampleManager: TEncodingTestSampleManager; ALogCallback: TProc<string> = nil);
    destructor Destroy; override;
    
    /// <summary>
    /// 验证整体置信度评分
    /// </summary>
    function ValidateOverallConfidence: TConfidenceValidationResult;
    
    /// <summary>
    /// 验证置信度区间评分
    /// </summary>
    function ValidateConfidenceIntervals: TArray<TConfidenceIntervalValidationResult>;
    
    /// <summary>
    /// 验证特定编码的置信度评分
    /// </summary>
    function ValidateEncodingConfidence(const Encoding: string): TConfidenceValidationResult;
    
    /// <summary>
    /// 生成置信度评分验证报告
    /// </summary>
    function GenerateValidationReport: string;
    
    /// <summary>
    /// 保存置信度评分验证报告到文件
    /// </summary>
    procedure SaveValidationReportToFile(const FilePath: string);
    
    /// <summary>
    /// 样本管理器
    /// </summary>
    property SampleManager: TEncodingTestSampleManager read FSampleManager;
    
    /// <summary>
    /// 统计分析器
    /// </summary>
    property Statistics: TEncodingTestStatistics read FStatistics;
    
    /// <summary>
    /// 日志回调
    /// </summary>
    property LogCallback: TProc<string> read FLogCallback write FLogCallback;
  end;

implementation

{ TConfidenceValidationResult }

constructor TConfidenceValidationResult.Create(AIsValid: Boolean; AExpectedAccuracy, AActualAccuracy: Double; ASampleCount: Integer);
begin
  IsValid := AIsValid;
  ExpectedAccuracy := AExpectedAccuracy;
  ActualAccuracy := AActualAccuracy;
  SampleCount := ASampleCount;
  
  Deviation := AActualAccuracy - AExpectedAccuracy;
  if AExpectedAccuracy > 0 then
    DeviationPercentage := Deviation / AExpectedAccuracy * 100
  else
    DeviationPercentage := 0;
end;

{ TConfidenceIntervalValidationResult }

constructor TConfidenceIntervalValidationResult.Create(const AInterval: string; const AValidationResult: TConfidenceValidationResult);
begin
  Interval := AInterval;
  ValidationResult := AValidationResult;
end;

{ TEncodingConfidenceValidator }

constructor TEncodingConfidenceValidator.Create(ASampleManager: TEncodingTestSampleManager; ALogCallback: TProc<string>);
begin
  inherited Create;
  FSampleManager := ASampleManager;
  FStatistics := TEncodingTestStatistics.Create(ASampleManager, ALogCallback);
  FLogCallback := ALogCallback;
end;

destructor TEncodingConfidenceValidator.Destroy;
begin
  FStatistics.Free;
  inherited;
end;

function TEncodingConfidenceValidator.GenerateValidationReport: string;
var
  SB: TStringBuilder;
  OverallResult: TConfidenceValidationResult;
  IntervalResults: TArray<TConfidenceIntervalValidationResult>;
  IntervalResult: TConfidenceIntervalValidationResult;
  EncodingResults: TDictionary<string, TConfidenceValidationResult>;
  Encoding: string;
  Result: TConfidenceValidationResult;
  DetectionStats: TEncodingDetectionStatistics;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('# 编码检测置信度评分验证报告');
    SB.AppendLine('');
    SB.AppendLine('## 1. 整体置信度评分验证');
    SB.AppendLine('');
    
    // 整体置信度评分验证
    OverallResult := ValidateOverallConfidence;
    SB.AppendLine(Format('- 期望正确率: %.2f%%', [OverallResult.ExpectedAccuracy * 100]));
    SB.AppendLine(Format('- 实际正确率: %.2f%%', [OverallResult.ActualAccuracy * 100]));
    SB.AppendLine(Format('- 偏差: %.2f%%', [OverallResult.Deviation * 100]));
    SB.AppendLine(Format('- 偏差百分比: %.2f%%', [OverallResult.DeviationPercentage]));
    SB.AppendLine(Format('- 样本数: %d', [OverallResult.SampleCount]));
    SB.AppendLine(Format('- 验证结果: %s', [IfThen(OverallResult.IsValid, '有效', '无效')]));
    SB.AppendLine('');
    
    // 置信度区间验证
    SB.AppendLine('## 2. 置信度区间验证');
    SB.AppendLine('');
    SB.AppendLine('| 置信度区间 | 期望正确率 | 实际正确率 | 偏差 | 偏差百分比 | 样本数 | 验证结果 |');
    SB.AppendLine('|------------|------------|------------|------|------------|--------|----------|');
    
    IntervalResults := ValidateConfidenceIntervals;
    for IntervalResult in IntervalResults do
    begin
      SB.AppendLine(Format('| %s | %.2f%% | %.2f%% | %.2f%% | %.2f%% | %d | %s |', 
        [IntervalResult.Interval, 
         IntervalResult.ValidationResult.ExpectedAccuracy * 100, 
         IntervalResult.ValidationResult.ActualAccuracy * 100, 
         IntervalResult.ValidationResult.Deviation * 100, 
         IntervalResult.ValidationResult.DeviationPercentage, 
         IntervalResult.ValidationResult.SampleCount, 
         IfThen(IntervalResult.ValidationResult.IsValid, '有效', '无效')]));
    end;
    SB.AppendLine('');
    
    // 特定编码置信度验证
    SB.AppendLine('## 3. 特定编码置信度验证');
    SB.AppendLine('');
    SB.AppendLine('| 编码 | 期望正确率 | 实际正确率 | 偏差 | 偏差百分比 | 样本数 | 验证结果 |');
    SB.AppendLine('|------|------------|------------|------|------------|--------|----------|');
    
    EncodingResults := TDictionary<string, TConfidenceValidationResult>.Create;
    try
      // 获取所有检测到的编码
      DetectionStats := FStatistics.CalculateDetectionStatistics;
      try
        for Encoding in DetectionStats.EncodingDistribution.Keys do
        begin
          Result := ValidateEncodingConfidence(Encoding);
          EncodingResults.Add(Encoding, Result);
        end;
      finally
        DetectionStats.Free;
      end;
      
      // 生成特定编码置信度验证表格
      for Encoding in EncodingResults.Keys do
      begin
        Result := EncodingResults[Encoding];
        SB.AppendLine(Format('| %s | %.2f%% | %.2f%% | %.2f%% | %.2f%% | %d | %s |', 
          [Encoding, 
           Result.ExpectedAccuracy * 100, 
           Result.ActualAccuracy * 100, 
           Result.Deviation * 100, 
           Result.DeviationPercentage, 
           Result.SampleCount, 
           IfThen(Result.IsValid, '有效', '无效')]));
      end;
    finally
      EncodingResults.Free;
    end;
    
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure TEncodingConfidenceValidator.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

procedure TEncodingConfidenceValidator.SaveValidationReportToFile(const FilePath: string);
var
  Report: string;
begin
  Report := GenerateValidationReport;
  TFile.WriteAllText(FilePath, Report);
  
  Log(Format('保存了置信度评分验证报告到文件: %s', [FilePath]));
end;

function TEncodingConfidenceValidator.ValidateConfidenceIntervals: TArray<TConfidenceIntervalValidationResult>;
var
  Intervals: TList<TConfidenceIntervalValidationResult>;
  ConfidenceIntervals: TArray<TConfidenceIntervalStatistics>;
  Interval: TConfidenceIntervalStatistics;
  ValidationResult: TConfidenceValidationResult;
  ExpectedAccuracy: Double;
  IsValid: Boolean;
  MaxDeviation: Double;
begin
  Intervals := TList<TConfidenceIntervalValidationResult>.Create;
  try
    // 获取置信度区间统计
    ConfidenceIntervals := FStatistics.CalculateConfidenceIntervalStatistics;
    
    // 验证每个区间
    for Interval in ConfidenceIntervals do
    begin
      // 解析区间
      ExpectedAccuracy := StrToFloatDef(Interval.Interval.Split(['-'])[0], 0);
      
      // 计算最大允许偏差（样本数越少，允许的偏差越大）
      MaxDeviation := 0.1 + 0.2 / Sqrt(Max(1, Interval.SampleCount));
      
      // 验证结果
      IsValid := Abs(Interval.AccuracyRate - ExpectedAccuracy) <= MaxDeviation;
      
      // 创建验证结果
      ValidationResult := TConfidenceValidationResult.Create(
        IsValid, ExpectedAccuracy, Interval.AccuracyRate, Interval.SampleCount);
      
      // 添加到结果列表
      Intervals.Add(TConfidenceIntervalValidationResult.Create(Interval.Interval, ValidationResult));
    end;
    
    Result := Intervals.ToArray;
  finally
    Intervals.Free;
  end;
end;

function TEncodingConfidenceValidator.ValidateEncodingConfidence(const Encoding: string): TConfidenceValidationResult;
var
  SamplePath: string;
  DetectionResult: TEncodingDetectionResult;
  TotalSamples, CorrectSamples: Integer;
  TotalConfidence: Double;
  ExpectedAccuracy, ActualAccuracy: Double;
  IsValid: Boolean;
  MaxDeviation: Double;
begin
  TotalSamples := 0;
  CorrectSamples := 0;
  TotalConfidence := 0;
  
  // 统计特定编码的检测结果
  for SamplePath in FSampleManager.FDetectionResults.Keys do
  begin
    if FSampleManager.GetDetectionResult(SamplePath, DetectionResult) and
       (DetectionResult.DetectedEncoding = Encoding) then
    begin
      Inc(TotalSamples);
      if DetectionResult.IsCorrect then
        Inc(CorrectSamples);
      
      TotalConfidence := TotalConfidence + DetectionResult.ConfidenceScore;
    end;
  end;
  
  // 计算期望正确率和实际正确率
  if TotalSamples > 0 then
  begin
    ExpectedAccuracy := TotalConfidence / TotalSamples;
    ActualAccuracy := CorrectSamples / TotalSamples;
  end
  else
  begin
    ExpectedAccuracy := 0;
    ActualAccuracy := 0;
  end;
  
  // 计算最大允许偏差（样本数越少，允许的偏差越大）
  MaxDeviation := 0.1 + 0.2 / Sqrt(Max(1, TotalSamples));
  
  // 验证结果
  IsValid := Abs(ActualAccuracy - ExpectedAccuracy) <= MaxDeviation;
  
  // 创建验证结果
  Result := TConfidenceValidationResult.Create(
    IsValid, ExpectedAccuracy, ActualAccuracy, TotalSamples);
  
  Log(Format('验证了编码"%s"的置信度评分: 期望=%.2f%%, 实际=%.2f%%, 结果=%s', 
    [Encoding, ExpectedAccuracy * 100, ActualAccuracy * 100, 
     IfThen(IsValid, '有效', '无效')]));
end;

function TEncodingConfidenceValidator.ValidateOverallConfidence: TConfidenceValidationResult;
var
  DetectionStats: TEncodingDetectionStatistics;
  ExpectedAccuracy, ActualAccuracy: Double;
  IsValid: Boolean;
  MaxDeviation: Double;
begin
  // 获取检测统计信息
  DetectionStats := FStatistics.CalculateDetectionStatistics;
  try
    // 计算期望正确率和实际正确率
    ExpectedAccuracy := DetectionStats.AverageConfidence;
    ActualAccuracy := DetectionStats.AccuracyRate;
    
    // 计算最大允许偏差（样本数越少，允许的偏差越大）
    MaxDeviation := 0.05 + 0.1 / Sqrt(Max(1, DetectionStats.TotalSamples));
    
    // 验证结果
    IsValid := Abs(ActualAccuracy - ExpectedAccuracy) <= MaxDeviation;
    
    // 创建验证结果
    Result := TConfidenceValidationResult.Create(
      IsValid, ExpectedAccuracy, ActualAccuracy, DetectionStats.TotalSamples);
    
    Log(Format('验证了整体置信度评分: 期望=%.2f%%, 实际=%.2f%%, 结果=%s', 
      [ExpectedAccuracy * 100, ActualAccuracy * 100, 
       IfThen(IsValid, '有效', '无效')]));
  finally
    DetectionStats.Free;
  end;
end;

end.
