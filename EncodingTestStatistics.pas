unit EncodingTestStatistics;

{
  EncodingTestStatistics.pas
  编码测试统计分析功能
  
  作为improve.md中任务2.1.3的实现
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Math,
  EncodingTestSampleManager;

type
  /// <summary>
  /// 编码检测统计信息
  /// </summary>
  TEncodingDetectionStatistics = record
    TotalSamples: Integer;                // 总样本数
    CorrectDetections: Integer;           // 正确检测数
    IncorrectDetections: Integer;         // 错误检测数
    AccuracyRate: Double;                 // 正确率
    AverageConfidence: Double;            // 平均置信度
    AverageDetectionTime: Double;         // 平均检测时间（毫秒）
    MinDetectionTime: Int64;              // 最小检测时间（毫秒）
    MaxDetectionTime: Int64;              // 最大检测时间（毫秒）
    EncodingDistribution: TDictionary<string, Integer>; // 编码分布
    
    constructor Create(ATotalSamples, ACorrectDetections: Integer);
    procedure Free;
  end;
  
  /// <summary>
  /// 编码转换统计信息
  /// </summary>
  TEncodingConversionStatistics = record
    TotalConversions: Integer;            // 总转换次数
    SuccessfulConversions: Integer;       // 成功转换次数
    FailedConversions: Integer;           // 失败转换次数
    SuccessRate: Double;                  // 成功率
    AverageConversionTime: Double;        // 平均转换时间（毫秒）
    MinConversionTime: Int64;             // 最小转换时间（毫秒）
    MaxConversionTime: Int64;             // 最大转换时间（毫秒）
    SourceEncodingDistribution: TDictionary<string, Integer>; // 源编码分布
    TargetEncodingDistribution: TDictionary<string, Integer>; // 目标编码分布
    
    constructor Create(ATotalConversions, ASuccessfulConversions: Integer);
    procedure Free;
  end;
  
  /// <summary>
  /// 置信度区间统计
  /// </summary>
  TConfidenceIntervalStatistics = record
    Interval: string;                     // 区间描述（如"0.0-0.1"）
    SampleCount: Integer;                 // 样本数
    CorrectCount: Integer;                // 正确数
    AccuracyRate: Double;                 // 正确率
    
    constructor Create(const AInterval: string; ASampleCount, ACorrectCount: Integer);
  end;
  
  /// <summary>
  /// 编码测试统计分析器
  /// </summary>
  TEncodingTestStatistics = class
  private
    FSampleManager: TEncodingTestSampleManager;
    FLogCallback: TProc<string>;
    
    procedure Log(const Msg: string);
  public
    constructor Create(ASampleManager: TEncodingTestSampleManager; ALogCallback: TProc<string> = nil);
    destructor Destroy; override;
    
    /// <summary>
    /// 计算编码检测统计信息
    /// </summary>
    function CalculateDetectionStatistics: TEncodingDetectionStatistics;
    
    /// <summary>
    /// 计算编码转换统计信息
    /// </summary>
    function CalculateConversionStatistics: TEncodingConversionStatistics;
    
    /// <summary>
    /// 计算置信度区间统计
    /// </summary>
    function CalculateConfidenceIntervalStatistics: TArray<TConfidenceIntervalStatistics>;
    
    /// <summary>
    /// 计算编码检测混淆矩阵
    /// </summary>
    function CalculateConfusionMatrix: TDictionary<string, TDictionary<string, Integer>>;
    
    /// <summary>
    /// 生成统计报告
    /// </summary>
    function GenerateStatisticsReport: string;
    
    /// <summary>
    /// 保存统计报告到文件
    /// </summary>
    procedure SaveStatisticsReportToFile(const FilePath: string);
    
    /// <summary>
    /// 样本管理器
    /// </summary>
    property SampleManager: TEncodingTestSampleManager read FSampleManager;
    
    /// <summary>
    /// 日志回调
    /// </summary>
    property LogCallback: TProc<string> read FLogCallback write FLogCallback;
  end;

implementation

{ TEncodingDetectionStatistics }

constructor TEncodingDetectionStatistics.Create(ATotalSamples, ACorrectDetections: Integer);
begin
  TotalSamples := ATotalSamples;
  CorrectDetections := ACorrectDetections;
  IncorrectDetections := ATotalSamples - ACorrectDetections;
  
  if ATotalSamples > 0 then
    AccuracyRate := ACorrectDetections / ATotalSamples
  else
    AccuracyRate := 0;
  
  AverageConfidence := 0;
  AverageDetectionTime := 0;
  MinDetectionTime := 0;
  MaxDetectionTime := 0;
  
  EncodingDistribution := TDictionary<string, Integer>.Create;
end;

procedure TEncodingDetectionStatistics.Free;
begin
  if Assigned(EncodingDistribution) then
    EncodingDistribution.Free;
end;

{ TEncodingConversionStatistics }

constructor TEncodingConversionStatistics.Create(ATotalConversions, ASuccessfulConversions: Integer);
begin
  TotalConversions := ATotalConversions;
  SuccessfulConversions := ASuccessfulConversions;
  FailedConversions := ATotalConversions - ASuccessfulConversions;
  
  if ATotalConversions > 0 then
    SuccessRate := ASuccessfulConversions / ATotalConversions
  else
    SuccessRate := 0;
  
  AverageConversionTime := 0;
  MinConversionTime := 0;
  MaxConversionTime := 0;
  
  SourceEncodingDistribution := TDictionary<string, Integer>.Create;
  TargetEncodingDistribution := TDictionary<string, Integer>.Create;
end;

procedure TEncodingConversionStatistics.Free;
begin
  if Assigned(SourceEncodingDistribution) then
    SourceEncodingDistribution.Free;
  
  if Assigned(TargetEncodingDistribution) then
    TargetEncodingDistribution.Free;
end;

{ TConfidenceIntervalStatistics }

constructor TConfidenceIntervalStatistics.Create(const AInterval: string; ASampleCount, ACorrectCount: Integer);
begin
  Interval := AInterval;
  SampleCount := ASampleCount;
  CorrectCount := ACorrectCount;
  
  if ASampleCount > 0 then
    AccuracyRate := ACorrectCount / ASampleCount
  else
    AccuracyRate := 0;
end;

{ TEncodingTestStatistics }

constructor TEncodingTestStatistics.Create(ASampleManager: TEncodingTestSampleManager; ALogCallback: TProc<string>);
begin
  inherited Create;
  FSampleManager := ASampleManager;
  FLogCallback := ALogCallback;
end;

destructor TEncodingTestStatistics.Destroy;
begin
  // 注意：不要释放FSampleManager，因为它是外部传入的
  inherited;
end;

function TEncodingTestStatistics.CalculateConfidenceIntervalStatistics: TArray<TConfidenceIntervalStatistics>;
var
  Intervals: TList<TConfidenceIntervalStatistics>;
  IntervalCounts, IntervalCorrectCounts: array[0..9] of Integer;
  SamplePath: string;
  DetectionResult: TEncodingDetectionResult;
  IntervalIndex: Integer;
  I: Integer;
begin
  Intervals := TList<TConfidenceIntervalStatistics>.Create;
  try
    // 初始化区间计数
    for I := 0 to 9 do
    begin
      IntervalCounts[I] := 0;
      IntervalCorrectCounts[I] := 0;
    end;
    
    // 统计每个区间的样本数和正确数
    for SamplePath in FSampleManager.FDetectionResults.Keys do
    begin
      if FSampleManager.GetDetectionResult(SamplePath, DetectionResult) then
      begin
        // 确定置信度区间
        IntervalIndex := Trunc(DetectionResult.ConfidenceScore * 10);
        if IntervalIndex >= 10 then
          IntervalIndex := 9;
        
        // 增加区间样本数
        Inc(IntervalCounts[IntervalIndex]);
        
        // 如果检测正确，增加区间正确数
        if DetectionResult.IsCorrect then
          Inc(IntervalCorrectCounts[IntervalIndex]);
      end;
    end;
    
    // 创建区间统计信息
    for I := 0 to 9 do
    begin
      if IntervalCounts[I] > 0 then
      begin
        Intervals.Add(TConfidenceIntervalStatistics.Create(
          Format('%.1f-%.1f', [I / 10, (I + 1) / 10]),
          IntervalCounts[I],
          IntervalCorrectCounts[I]));
      end;
    end;
    
    Result := Intervals.ToArray;
  finally
    Intervals.Free;
  end;
end;

function TEncodingTestStatistics.CalculateConfusionMatrix: TDictionary<string, TDictionary<string, Integer>>;
var
  Matrix: TDictionary<string, TDictionary<string, Integer>>;
  KnownEncodings, DetectedEncodings: TList<string>;
  SamplePath: string;
  DetectionResult: TEncodingDetectionResult;
  Sample: TEncodingSampleMetadata;
  KnownEncoding, DetectedEncoding: string;
  InnerDict: TDictionary<string, Integer>;
begin
  Matrix := TDictionary<string, TDictionary<string, Integer>>.Create;
  KnownEncodings := TList<string>.Create;
  DetectedEncodings := TList<string>.Create;
  
  try
    // 收集所有已知编码和检测到的编码
    for SamplePath in FSampleManager.FDetectionResults.Keys do
    begin
      if FSampleManager.GetDetectionResult(SamplePath, DetectionResult) then
      begin
        // 获取已知编码
        for Sample in FSampleManager.SampleLoader.GetCollection.GetAllSamples do
        begin
          if Sample.FilePath = SamplePath then
          begin
            KnownEncoding := Sample.KnownEncoding;
            if (KnownEncoding <> '') and (not KnownEncodings.Contains(KnownEncoding)) then
              KnownEncodings.Add(KnownEncoding);
            Break;
          end;
        end;
        
        // 获取检测到的编码
        DetectedEncoding := DetectionResult.DetectedEncoding;
        if (DetectedEncoding <> '') and (not DetectedEncodings.Contains(DetectedEncoding)) then
          DetectedEncodings.Add(DetectedEncoding);
      end;
    end;
    
    // 初始化混淆矩阵
    for KnownEncoding in KnownEncodings do
    begin
      InnerDict := TDictionary<string, Integer>.Create;
      for DetectedEncoding in DetectedEncodings do
        InnerDict.Add(DetectedEncoding, 0);
      
      Matrix.Add(KnownEncoding, InnerDict);
    end;
    
    // 填充混淆矩阵
    for SamplePath in FSampleManager.FDetectionResults.Keys do
    begin
      if FSampleManager.GetDetectionResult(SamplePath, DetectionResult) then
      begin
        // 获取已知编码
        KnownEncoding := '';
        for Sample in FSampleManager.SampleLoader.GetCollection.GetAllSamples do
        begin
          if Sample.FilePath = SamplePath then
          begin
            KnownEncoding := Sample.KnownEncoding;
            Break;
          end;
        end;
        
        // 获取检测到的编码
        DetectedEncoding := DetectionResult.DetectedEncoding;
        
        // 更新混淆矩阵
        if (KnownEncoding <> '') and (DetectedEncoding <> '') and
           Matrix.ContainsKey(KnownEncoding) and
           Matrix[KnownEncoding].ContainsKey(DetectedEncoding) then
        begin
          Matrix[KnownEncoding][DetectedEncoding] := Matrix[KnownEncoding][DetectedEncoding] + 1;
        end;
      end;
    end;
    
    Result := Matrix;
  finally
    KnownEncodings.Free;
    DetectedEncodings.Free;
  end;
end;

function TEncodingTestStatistics.CalculateConversionStatistics: TEncodingConversionStatistics;
var
  TotalConversions, SuccessfulConversions: Integer;
  TotalTime: Int64;
  SamplePath: string;
  ConversionResults: TArray<TEncodingConversionResult>;
  Result: TEncodingConversionResult;
begin
  TotalConversions := 0;
  SuccessfulConversions := 0;
  TotalTime := 0;
  
  // 创建统计信息
  System.Result := TEncodingConversionStatistics.Create(0, 0);
  
  // 统计转换结果
  for SamplePath in FSampleManager.FConversionResults.Keys do
  begin
    ConversionResults := FSampleManager.GetConversionResults(SamplePath);
    for Result in ConversionResults do
    begin
      Inc(TotalConversions);
      if Result.IsSuccessful then
        Inc(SuccessfulConversions);
      
      TotalTime := TotalTime + Result.ConversionTime;
      
      // 更新最小和最大转换时间
      if (System.Result.MinConversionTime = 0) or (Result.ConversionTime < System.Result.MinConversionTime) then
        System.Result.MinConversionTime := Result.ConversionTime;
      
      if Result.ConversionTime > System.Result.MaxConversionTime then
        System.Result.MaxConversionTime := Result.ConversionTime;
      
      // 更新源编码分布
      if System.Result.SourceEncodingDistribution.ContainsKey(Result.SourceEncoding) then
        System.Result.SourceEncodingDistribution[Result.SourceEncoding] := 
          System.Result.SourceEncodingDistribution[Result.SourceEncoding] + 1
      else
        System.Result.SourceEncodingDistribution.Add(Result.SourceEncoding, 1);
      
      // 更新目标编码分布
      if System.Result.TargetEncodingDistribution.ContainsKey(Result.TargetEncoding) then
        System.Result.TargetEncodingDistribution[Result.TargetEncoding] := 
          System.Result.TargetEncodingDistribution[Result.TargetEncoding] + 1
      else
        System.Result.TargetEncodingDistribution.Add(Result.TargetEncoding, 1);
    end;
  end;
  
  // 更新统计信息
  System.Result.TotalConversions := TotalConversions;
  System.Result.SuccessfulConversions := SuccessfulConversions;
  System.Result.FailedConversions := TotalConversions - SuccessfulConversions;
  
  if TotalConversions > 0 then
  begin
    System.Result.SuccessRate := SuccessfulConversions / TotalConversions;
    System.Result.AverageConversionTime := TotalTime / TotalConversions;
  end
  else
  begin
    System.Result.SuccessRate := 0;
    System.Result.AverageConversionTime := 0;
  end;
  
  Log(Format('计算了转换统计信息: 总转换次数=%d, 成功率=%.2f%%', 
    [TotalConversions, System.Result.SuccessRate * 100]));
end;

function TEncodingTestStatistics.CalculateDetectionStatistics: TEncodingDetectionStatistics;
var
  TotalSamples, CorrectDetections: Integer;
  TotalConfidence, TotalTime: Double;
  SamplePath: string;
  DetectionResult: TEncodingDetectionResult;
begin
  TotalSamples := 0;
  CorrectDetections := 0;
  TotalConfidence := 0;
  TotalTime := 0;
  
  // 创建统计信息
  System.Result := TEncodingDetectionStatistics.Create(0, 0);
  
  // 统计检测结果
  for SamplePath in FSampleManager.FDetectionResults.Keys do
  begin
    if FSampleManager.GetDetectionResult(SamplePath, DetectionResult) then
    begin
      Inc(TotalSamples);
      if DetectionResult.IsCorrect then
        Inc(CorrectDetections);
      
      TotalConfidence := TotalConfidence + DetectionResult.ConfidenceScore;
      TotalTime := TotalTime + DetectionResult.DetectionTime;
      
      // 更新最小和最大检测时间
      if (System.Result.MinDetectionTime = 0) or (DetectionResult.DetectionTime < System.Result.MinDetectionTime) then
        System.Result.MinDetectionTime := DetectionResult.DetectionTime;
      
      if DetectionResult.DetectionTime > System.Result.MaxDetectionTime then
        System.Result.MaxDetectionTime := DetectionResult.DetectionTime;
      
      // 更新编码分布
      if System.Result.EncodingDistribution.ContainsKey(DetectionResult.DetectedEncoding) then
        System.Result.EncodingDistribution[DetectionResult.DetectedEncoding] := 
          System.Result.EncodingDistribution[DetectionResult.DetectedEncoding] + 1
      else
        System.Result.EncodingDistribution.Add(DetectionResult.DetectedEncoding, 1);
    end;
  end;
  
  // 更新统计信息
  System.Result.TotalSamples := TotalSamples;
  System.Result.CorrectDetections := CorrectDetections;
  System.Result.IncorrectDetections := TotalSamples - CorrectDetections;
  
  if TotalSamples > 0 then
  begin
    System.Result.AccuracyRate := CorrectDetections / TotalSamples;
    System.Result.AverageConfidence := TotalConfidence / TotalSamples;
    System.Result.AverageDetectionTime := TotalTime / TotalSamples;
  end
  else
  begin
    System.Result.AccuracyRate := 0;
    System.Result.AverageConfidence := 0;
    System.Result.AverageDetectionTime := 0;
  end;
  
  Log(Format('计算了检测统计信息: 总样本数=%d, 正确率=%.2f%%', 
    [TotalSamples, System.Result.AccuracyRate * 100]));
end;

function TEncodingTestStatistics.GenerateStatisticsReport: string;
var
  SB: TStringBuilder;
  DetectionStats: TEncodingDetectionStatistics;
  ConversionStats: TEncodingConversionStatistics;
  ConfidenceIntervals: TArray<TConfidenceIntervalStatistics>;
  ConfusionMatrix: TDictionary<string, TDictionary<string, Integer>>;
  Interval: TConfidenceIntervalStatistics;
  KnownEncoding, DetectedEncoding: string;
  InnerDict: TDictionary<string, Integer>;
  DetectedEncodings: TList<string>;
  Encoding: string;
  Count: Integer;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('# 编码测试统计分析报告');
    SB.AppendLine('');
    SB.AppendLine('## 1. 编码检测统计');
    SB.AppendLine('');
    
    // 检测统计
    DetectionStats := CalculateDetectionStatistics;
    try
      SB.AppendLine(Format('- 总样本数: %d', [DetectionStats.TotalSamples]));
      SB.AppendLine(Format('- 正确检测数: %d', [DetectionStats.CorrectDetections]));
      SB.AppendLine(Format('- 错误检测数: %d', [DetectionStats.IncorrectDetections]));
      SB.AppendLine(Format('- 正确率: %.2f%%', [DetectionStats.AccuracyRate * 100]));
      SB.AppendLine(Format('- 平均置信度: %.2f', [DetectionStats.AverageConfidence]));
      SB.AppendLine(Format('- 平均检测时间: %.2f 毫秒', [DetectionStats.AverageDetectionTime]));
      SB.AppendLine(Format('- 最小检测时间: %d 毫秒', [DetectionStats.MinDetectionTime]));
      SB.AppendLine(Format('- 最大检测时间: %d 毫秒', [DetectionStats.MaxDetectionTime]));
      SB.AppendLine('');
      
      // 编码分布
      SB.AppendLine('### 1.1 编码分布');
      SB.AppendLine('');
      SB.AppendLine('| 编码 | 样本数 | 百分比 |');
      SB.AppendLine('|------|--------|--------|');
      
      for Encoding in DetectionStats.EncodingDistribution.Keys do
      begin
        Count := DetectionStats.EncodingDistribution[Encoding];
        SB.AppendLine(Format('| %s | %d | %.2f%% |', 
          [Encoding, Count, Count / DetectionStats.TotalSamples * 100]));
      end;
      SB.AppendLine('');
    finally
      DetectionStats.Free;
    end;
    
    // 置信度区间统计
    SB.AppendLine('### 1.2 置信度区间统计');
    SB.AppendLine('');
    SB.AppendLine('| 置信度区间 | 样本数 | 正确数 | 正确率 |');
    SB.AppendLine('|------------|--------|--------|--------|');
    
    ConfidenceIntervals := CalculateConfidenceIntervalStatistics;
    for Interval in ConfidenceIntervals do
    begin
      SB.AppendLine(Format('| %s | %d | %d | %.2f%% |', 
        [Interval.Interval, Interval.SampleCount, Interval.CorrectCount, 
         Interval.AccuracyRate * 100]));
    end;
    SB.AppendLine('');
    
    // 混淆矩阵
    SB.AppendLine('### 1.3 混淆矩阵');
    SB.AppendLine('');
    
    ConfusionMatrix := CalculateConfusionMatrix;
    try
      // 收集所有检测到的编码
      DetectedEncodings := TList<string>.Create;
      try
        for InnerDict in ConfusionMatrix.Values do
        begin
          for DetectedEncoding in InnerDict.Keys do
          begin
            if not DetectedEncodings.Contains(DetectedEncoding) then
              DetectedEncodings.Add(DetectedEncoding);
          end;
        end;
        
        // 生成混淆矩阵表头
        SB.Append('| 已知编码\\检测编码 |');
        for DetectedEncoding in DetectedEncodings do
          SB.Append(Format(' %s |', [DetectedEncoding]));
        SB.AppendLine('');
        
        // 生成分隔行
        SB.Append('|------------------|');
        for DetectedEncoding in DetectedEncodings do
          SB.Append('--------|');
        SB.AppendLine('');
        
        // 生成混淆矩阵内容
        for KnownEncoding in ConfusionMatrix.Keys do
        begin
          SB.Append(Format('| %s |', [KnownEncoding]));
          
          InnerDict := ConfusionMatrix[KnownEncoding];
          for DetectedEncoding in DetectedEncodings do
          begin
            if InnerDict.ContainsKey(DetectedEncoding) then
              SB.Append(Format(' %d |', [InnerDict[DetectedEncoding]]))
            else
              SB.Append(' 0 |');
          end;
          
          SB.AppendLine('');
        end;
      finally
        DetectedEncodings.Free;
      end;
    finally
      for InnerDict in ConfusionMatrix.Values do
        InnerDict.Free;
      ConfusionMatrix.Free;
    end;
    
    SB.AppendLine('');
    SB.AppendLine('## 2. 编码转换统计');
    SB.AppendLine('');
    
    // 转换统计
    ConversionStats := CalculateConversionStatistics;
    try
      SB.AppendLine(Format('- 总转换次数: %d', [ConversionStats.TotalConversions]));
      SB.AppendLine(Format('- 成功转换次数: %d', [ConversionStats.SuccessfulConversions]));
      SB.AppendLine(Format('- 失败转换次数: %d', [ConversionStats.FailedConversions]));
      SB.AppendLine(Format('- 成功率: %.2f%%', [ConversionStats.SuccessRate * 100]));
      SB.AppendLine(Format('- 平均转换时间: %.2f 毫秒', [ConversionStats.AverageConversionTime]));
      SB.AppendLine(Format('- 最小转换时间: %d 毫秒', [ConversionStats.MinConversionTime]));
      SB.AppendLine(Format('- 最大转换时间: %d 毫秒', [ConversionStats.MaxConversionTime]));
      SB.AppendLine('');
      
      // 源编码分布
      SB.AppendLine('### 2.1 源编码分布');
      SB.AppendLine('');
      SB.AppendLine('| 编码 | 次数 | 百分比 |');
      SB.AppendLine('|------|------|--------|');
      
      for Encoding in ConversionStats.SourceEncodingDistribution.Keys do
      begin
        Count := ConversionStats.SourceEncodingDistribution[Encoding];
        SB.AppendLine(Format('| %s | %d | %.2f%% |', 
          [Encoding, Count, Count / ConversionStats.TotalConversions * 100]));
      end;
      SB.AppendLine('');
      
      // 目标编码分布
      SB.AppendLine('### 2.2 目标编码分布');
      SB.AppendLine('');
      SB.AppendLine('| 编码 | 次数 | 百分比 |');
      SB.AppendLine('|------|------|--------|');
      
      for Encoding in ConversionStats.TargetEncodingDistribution.Keys do
      begin
        Count := ConversionStats.TargetEncodingDistribution[Encoding];
        SB.AppendLine(Format('| %s | %d | %.2f%% |', 
          [Encoding, Count, Count / ConversionStats.TotalConversions * 100]));
      end;
    finally
      ConversionStats.Free;
    end;
    
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure TEncodingTestStatistics.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

procedure TEncodingTestStatistics.SaveStatisticsReportToFile(const FilePath: string);
var
  Report: string;
begin
  Report := GenerateStatisticsReport;
  TFile.WriteAllText(FilePath, Report);
  
  Log(Format('保存了统计报告到文件: %s', [FilePath]));
end;

end.
