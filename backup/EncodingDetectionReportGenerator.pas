unit EncodingDetectionReportGenerator;

{
  EncodingDetectionReportGenerator.pas
  编码检测正确率报告生成器

  作为improve.md中任务2.1.5的实现
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Math,
  System.JSON, System.IOUtils, EncodingTestSampleManager,
  EncodingTestStatistics, EncodingConfidenceValidator;

type
  /// <summary>
  /// 报告格式类型
  /// </summary>
  TReportFormat = (rfMarkdown, rfHTML, rfCSV, rfJSON);

  /// <summary>
  /// 报告内容选项
  /// </summary>
  TReportContentOptions = record
    IncludeOverallStatistics: Boolean;    // 包含整体统计
    IncludeEncodingDistribution: Boolean; // 包含编码分布
    IncludeConfidenceIntervals: Boolean;  // 包含置信度区间
    IncludeConfusionMatrix: Boolean;      // 包含混淆矩阵
    IncludeDetailedResults: Boolean;      // 包含详细结果
    IncludeCharts: Boolean;               // 包含图表（仅HTML格式）

    constructor Create(AIncludeAll: Boolean);
  end;

  /// <summary>
  /// 编码检测正确率报告生成器
  /// </summary>
  TEncodingDetectionReportGenerator = class
  private
    FSampleManager: TEncodingTestSampleManager;
    FStatistics: TEncodingTestStatistics;
    FConfidenceValidator: TEncodingConfidenceValidator;
    FLogCallback: TProc<string>;

    procedure Log(const Msg: string);
    function GenerateMarkdownReport(const Options: TReportContentOptions): string;
    function GenerateHTMLReport(const Options: TReportContentOptions): string;
    function GenerateCSVReport(const Options: TReportContentOptions): string;
    function GenerateJSONReport(const Options: TReportContentOptions): string;
    function GenerateChartScript: string;
  public
    constructor Create(ASampleManager: TEncodingTestSampleManager; ALogCallback: TProc<string> = nil);
    destructor Destroy; override;

    /// <summary>
    /// 生成报告
    /// </summary>
    function GenerateReport(Format: TReportFormat; const Options: TReportContentOptions): string;

    /// <summary>
    /// 保存报告到文件
    /// </summary>
    procedure SaveReportToFile(const FilePath: string; Format: TReportFormat; const Options: TReportContentOptions);

    /// <summary>
    /// 样本管理器
    /// </summary>
    property SampleManager: TEncodingTestSampleManager read FSampleManager;

    /// <summary>
    /// 统计分析器
    /// </summary>
    property Statistics: TEncodingTestStatistics read FStatistics;

    /// <summary>
    /// 置信度验证器
    /// </summary>
    property ConfidenceValidator: TEncodingConfidenceValidator read FConfidenceValidator;

    /// <summary>
    /// 日志回调
    /// </summary>
    property LogCallback: TProc<string> read FLogCallback write FLogCallback;
  end;

implementation

{ TReportContentOptions }

constructor TReportContentOptions.Create(AIncludeAll: Boolean);
begin
  IncludeOverallStatistics := AIncludeAll;
  IncludeEncodingDistribution := AIncludeAll;
  IncludeConfidenceIntervals := AIncludeAll;
  IncludeConfusionMatrix := AIncludeAll;
  IncludeDetailedResults := AIncludeAll;
  IncludeCharts := AIncludeAll;
end;

{ TEncodingDetectionReportGenerator }

constructor TEncodingDetectionReportGenerator.Create(ASampleManager: TEncodingTestSampleManager; ALogCallback: TProc<string>);
begin
  inherited Create;
  FSampleManager := ASampleManager;
  FStatistics := TEncodingTestStatistics.Create(ASampleManager, ALogCallback);
  FConfidenceValidator := TEncodingConfidenceValidator.Create(ASampleManager, ALogCallback);
  FLogCallback := ALogCallback;
end;

destructor TEncodingDetectionReportGenerator.Destroy;
begin
  FConfidenceValidator.Free;
  FStatistics.Free;
  inherited;
end;

procedure TEncodingDetectionReportGenerator.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

function TEncodingDetectionReportGenerator.GenerateReport(Format: TReportFormat; const Options: TReportContentOptions): string;
begin
  case Format of
    rfMarkdown: Result := GenerateMarkdownReport(Options);
    rfHTML: Result := GenerateHTMLReport(Options);
    rfCSV: Result := GenerateCSVReport(Options);
    rfJSON: Result := GenerateJSONReport(Options);
  else
    Result := GenerateMarkdownReport(Options);
  end;

  Log(Format('生成了%s格式的检测正确率报告', [GetEnumName(TypeInfo(TReportFormat), Ord(Format))]));
end;

procedure TEncodingDetectionReportGenerator.SaveReportToFile(const FilePath: string; Format: TReportFormat; const Options: TReportContentOptions);
var
  Report: string;
  FileExt: string;
begin
  Report := GenerateReport(Format, Options);

  // 确保文件扩展名与格式匹配
  FileExt := ExtractFileExt(FilePath);
  if FileExt = '' then
  begin
    case Format of
      rfMarkdown: FileExt := '.md';
      rfHTML: FileExt := '.html';
      rfCSV: FileExt := '.csv';
      rfJSON: FileExt := '.json';
    end;

    TFile.WriteAllText(ChangeFileExt(FilePath, FileExt), Report);
  end
  else
    TFile.WriteAllText(FilePath, Report);

  Log(Format('保存了检测正确率报告到文件: %s', [FilePath]));
end;

function TEncodingDetectionReportGenerator.GenerateMarkdownReport(const Options: TReportContentOptions): string;
var
  SB: TStringBuilder;
  DetectionStats: TEncodingDetectionStatistics;
  ConfidenceIntervals: TArray<TConfidenceIntervalStatistics>;
  ConfusionMatrix: TDictionary<string, TDictionary<string, Integer>>;
  OverallValidation: TConfidenceValidationResult;
  Interval: TConfidenceIntervalStatistics;
  KnownEncoding, DetectedEncoding: string;
  InnerDict: TDictionary<string, Integer>;
  DetectedEncodings: TList<string>;
  SamplePath: string;
  DetectionResult: TEncodingDetectionResult;
  Sample: TEncodingSampleMetadata;
  Encoding: string;
  Count: Integer;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('# 编码检测正确率报告');
    SB.AppendLine('');
    SB.AppendLine('生成时间: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    SB.AppendLine('');

    // 整体统计
    if Options.IncludeOverallStatistics then
    begin
      SB.AppendLine('## 1. 整体统计');
      SB.AppendLine('');

      DetectionStats := FStatistics.CalculateDetectionStatistics;
      try
        SB.AppendLine(Format('- 总样本数: %d', [DetectionStats.TotalSamples]));
        SB.AppendLine(Format('- 正确检测数: %d', [DetectionStats.CorrectDetections]));
        SB.AppendLine(Format('- 错误检测数: %d', [DetectionStats.IncorrectDetections]));
        SB.AppendLine(Format('- 正确率: %.2f%%', [DetectionStats.AccuracyRate * 100]));
        SB.AppendLine(Format('- 平均置信度: %.2f', [DetectionStats.AverageConfidence]));
        SB.AppendLine(Format('- 平均检测时间: %.2f 毫秒', [DetectionStats.AverageDetectionTime]));
        SB.AppendLine('');

        // 置信度验证
        OverallValidation := FConfidenceValidator.ValidateOverallConfidence;
        SB.AppendLine('### 1.1 置信度验证');
        SB.AppendLine('');
        SB.AppendLine(Format('- 期望正确率: %.2f%%', [OverallValidation.ExpectedAccuracy * 100]));
        SB.AppendLine(Format('- 实际正确率: %.2f%%', [OverallValidation.ActualAccuracy * 100]));
        SB.AppendLine(Format('- 偏差: %.2f%%', [OverallValidation.Deviation * 100]));
        SB.AppendLine(Format('- 偏差百分比: %.2f%%', [OverallValidation.DeviationPercentage]));
        SB.AppendLine(Format('- 验证结果: %s', [IfThen(OverallValidation.IsValid, '有效', '无效')]));
        SB.AppendLine('');
      finally
        DetectionStats.Free;
      end;
    end;

    // 编码分布
    if Options.IncludeEncodingDistribution then
    begin
      SB.AppendLine('## 2. 编码分布');
      SB.AppendLine('');

      DetectionStats := FStatistics.CalculateDetectionStatistics;
      try
        SB.AppendLine('| 编码 | 样本数 | 百分比 | 正确数 | 正确率 |');
        SB.AppendLine('|------|--------|--------|--------|--------|');

        for Encoding in DetectionStats.EncodingDistribution.Keys do
        begin
          Count := DetectionStats.EncodingDistribution[Encoding];

          // 计算该编码的正确检测数
          var CorrectCount := 0;
          for SamplePath in FSampleManager.FDetectionResults.Keys do
          begin
            if FSampleManager.GetDetectionResult(SamplePath, DetectionResult) and
               (DetectionResult.DetectedEncoding = Encoding) and
               DetectionResult.IsCorrect then
              Inc(CorrectCount);
          end;

          // 计算正确率
          var AccuracyRate := 0.0;
          if Count > 0 then
            AccuracyRate := CorrectCount / Count;

          SB.AppendLine(Format('| %s | %d | %.2f%% | %d | %.2f%% |',
            [Encoding, Count, Count / DetectionStats.TotalSamples * 100,
             CorrectCount, AccuracyRate * 100]));
        end;
        SB.AppendLine('');
      finally
        DetectionStats.Free;
      end;
    end;

    // 置信度区间
    if Options.IncludeConfidenceIntervals then
    begin
      SB.AppendLine('## 3. 置信度区间');
      SB.AppendLine('');

      ConfidenceIntervals := FStatistics.CalculateConfidenceIntervalStatistics;

      SB.AppendLine('| 置信度区间 | 样本数 | 正确数 | 正确率 |');
      SB.AppendLine('|------------|--------|--------|--------|');

      for Interval in ConfidenceIntervals do
      begin
        SB.AppendLine(Format('| %s | %d | %d | %.2f%% |',
          [Interval.Interval, Interval.SampleCount, Interval.CorrectCount,
           Interval.AccuracyRate * 100]));
      end;
      SB.AppendLine('');
    end;

    // 混淆矩阵
    if Options.IncludeConfusionMatrix then
    begin
      SB.AppendLine('## 4. 混淆矩阵');
      SB.AppendLine('');

      ConfusionMatrix := FStatistics.CalculateConfusionMatrix;
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
    end;

    // 详细结果
    if Options.IncludeDetailedResults then
    begin
      SB.AppendLine('## 5. 详细结果');
      SB.AppendLine('');

      SB.AppendLine('| 样本 | 已知编码 | 检测编码 | 置信度 | 耗时(毫秒) | 结果 |');
      SB.AppendLine('|------|----------|----------|--------|------------|------|');

      for SamplePath in FSampleManager.FDetectionResults.Keys do
      begin
        if FSampleManager.GetDetectionResult(SamplePath, DetectionResult) then
        begin
          // 获取已知编码
          var KnownEncoding := '';
          for Sample in FSampleManager.SampleLoader.GetCollection.GetAllSamples do
          begin
            if Sample.FilePath = SamplePath then
            begin
              KnownEncoding := Sample.KnownEncoding;
              Break;
            end;
          end;

          SB.AppendLine(Format('| %s | %s | %s | %.2f | %d | %s |',
            [ExtractFileName(SamplePath), KnownEncoding, DetectionResult.DetectedEncoding,
             DetectionResult.ConfidenceScore, DetectionResult.DetectionTime,
             IfThen(DetectionResult.IsCorrect, '正确', '错误')]));
        end;
      end;

      SB.AppendLine('');
    end;

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TEncodingDetectionReportGenerator.GenerateHTMLReport(const Options: TReportContentOptions): string;
var
  SB: TStringBuilder;
  MarkdownContent: string;
  ChartScript: string;
begin
  SB := TStringBuilder.Create;
  try
    // 生成HTML头部
    SB.AppendLine('<!DOCTYPE html>');
    SB.AppendLine('<html lang="zh-CN">');
    SB.AppendLine('<head>');
    SB.AppendLine('  <meta charset="UTF-8">');
    SB.AppendLine('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    SB.AppendLine('  <title>编码检测正确率报告</title>');
    SB.AppendLine('  <style>');
    SB.AppendLine('    body { font-family: Arial, sans-serif; line-height: 1.6; margin: 0; padding: 20px; color: #333; }');
    SB.AppendLine('    h1 { color: #2c3e50; border-bottom: 2px solid #eee; padding-bottom: 10px; }');
    SB.AppendLine('    h2 { color: #3498db; margin-top: 30px; }');
    SB.AppendLine('    h3 { color: #2980b9; }');
    SB.AppendLine('    table { border-collapse: collapse; width: 100%; margin: 20px 0; }');
    SB.AppendLine('    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }');
    SB.AppendLine('    th { background-color: #f2f2f2; }');
    SB.AppendLine('    tr:nth-child(even) { background-color: #f9f9f9; }');
    SB.AppendLine('    .chart-container { width: 100%; height: 400px; margin: 20px 0; }');
    SB.AppendLine('    .correct { color: green; }');
    SB.AppendLine('    .incorrect { color: red; }');
    SB.AppendLine('  </style>');

    // 如果包含图表，添加Chart.js库
    if Options.IncludeCharts then
    begin
      SB.AppendLine('  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>');
    end;

    SB.AppendLine('</head>');
    SB.AppendLine('<body>');

    // 生成Markdown内容并转换为HTML
    MarkdownContent := GenerateMarkdownReport(Options);

    // 简单的Markdown到HTML转换（仅支持基本格式）
    // 标题转换
    MarkdownContent := StringReplace(MarkdownContent, '# ', '<h1>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, '## ', '<h2>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, '### ', '<h3>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, #13#10'<h1>', '</p>'#13#10'<h1>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, #13#10'<h2>', '</p>'#13#10'<h2>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, #13#10'<h3>', '</p>'#13#10'<h3>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, '<h1>', '<h1>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, '<h2>', '<h2>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, '<h3>', '<h3>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, #13#10, '</h1>'#13#10'<p>', [rfReplaceAll, rfIgnoreCase], 1);
    MarkdownContent := StringReplace(MarkdownContent, #13#10, '</h2>'#13#10'<p>', [rfReplaceAll, rfIgnoreCase], 1);
    MarkdownContent := StringReplace(MarkdownContent, #13#10, '</h3>'#13#10'<p>', [rfReplaceAll, rfIgnoreCase], 1);

    // 列表转换
    MarkdownContent := StringReplace(MarkdownContent, #13#10'- ', #13#10'<li>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, '<li>', '</p>'#13#10'<ul>'#13#10'<li>', [rfReplaceAll], 1);
    MarkdownContent := StringReplace(MarkdownContent, #13#10#13#10, #13#10'</li>'#13#10'</ul>'#13#10'<p>', [rfReplaceAll]);

    // 表格转换
    MarkdownContent := StringReplace(MarkdownContent, '|---', '<tr><th>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, '---|', '</th></tr>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, '| ', '<tr><td>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, ' |', '</td></tr>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, ' | ', '</td><td>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, '<tr><td>', '</p>'#13#10'<table>'#13#10'<tr><td>', [rfReplaceAll], 1);
    MarkdownContent := StringReplace(MarkdownContent, #13#10#13#10, #13#10'</table>'#13#10'<p>', [rfReplaceAll]);

    // 添加正确/错误样式
    MarkdownContent := StringReplace(MarkdownContent, '>正确<', ' class="correct">正确<', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, '>错误<', ' class="incorrect">错误<', [rfReplaceAll]);

    // 添加内容
    SB.AppendLine(MarkdownContent);

    // 如果包含图表，添加图表
    if Options.IncludeCharts then
    begin
      SB.AppendLine('<h2>6. 图表</h2>');

      // 添加正确率图表
      SB.AppendLine('<h3>6.1 编码分布与正确率</h3>');
      SB.AppendLine('<div class="chart-container">');
      SB.AppendLine('  <canvas id="encodingChart"></canvas>');
      SB.AppendLine('</div>');

      // 添加置信度区间图表
      SB.AppendLine('<h3>6.2 置信度区间与正确率</h3>');
      SB.AppendLine('<div class="chart-container">');
      SB.AppendLine('  <canvas id="confidenceChart"></canvas>');
      SB.AppendLine('</div>');

      // 添加图表脚本
      ChartScript := GenerateChartScript;
      SB.AppendLine('<script>');
      SB.AppendLine(ChartScript);
      SB.AppendLine('</script>');
    end;

    // 添加页脚
    SB.AppendLine('<footer>');
    SB.AppendLine('  <p>生成时间: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '</p>');
    SB.AppendLine('</footer>');

    SB.AppendLine('</body>');
    SB.AppendLine('</html>');

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TEncodingDetectionReportGenerator.GenerateCSVReport(const Options: TReportContentOptions): string;
var
  SB: TStringBuilder;
  SamplePath: string;
  DetectionResult: TEncodingDetectionResult;
  Sample: TEncodingSampleMetadata;
begin
  SB := TStringBuilder.Create;
  try
    // 添加CSV头部
    SB.AppendLine('样本文件,已知编码,检测编码,置信度,检测时间(毫秒),是否正确');

    // 添加详细结果
    for SamplePath in FSampleManager.FDetectionResults.Keys do
    begin
      if FSampleManager.GetDetectionResult(SamplePath, DetectionResult) then
      begin
        // 获取已知编码
        var KnownEncoding := '';
        for Sample in FSampleManager.SampleLoader.GetCollection.GetAllSamples do
        begin
          if Sample.FilePath = SamplePath then
          begin
            KnownEncoding := Sample.KnownEncoding;
            Break;
          end;
        end;

        // 添加CSV行
        SB.AppendLine(Format('"%s","%s","%s",%.2f,%d,%s',
          [ExtractFileName(SamplePath), KnownEncoding, DetectionResult.DetectedEncoding,
           DetectionResult.ConfidenceScore, DetectionResult.DetectionTime,
           IfThen(DetectionResult.IsCorrect, '正确', '错误')]));
      end;
    end;

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TEncodingDetectionReportGenerator.GenerateJSONReport(const Options: TReportContentOptions): string;
var
  Json: TJSONObject;
  SamplesArray: TJSONArray;
  SampleJson: TJSONObject;
  StatsJson: TJSONObject;
  DetectionStats: TEncodingDetectionStatistics;
  ConfidenceIntervals: TArray<TConfidenceIntervalStatistics>;
  IntervalsArray: TJSONArray;
  IntervalJson: TJSONObject;
  SamplePath: string;
  DetectionResult: TEncodingDetectionResult;
  Sample: TEncodingSampleMetadata;
  Interval: TConfidenceIntervalStatistics;
begin
  Json := TJSONObject.Create;
  try
    // 添加报告生成时间
    Json.AddPair('generatedAt', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now));

    // 添加整体统计
    if Options.IncludeOverallStatistics then
    begin
      DetectionStats := FStatistics.CalculateDetectionStatistics;
      try
        StatsJson := TJSONObject.Create;
        StatsJson.AddPair('totalSamples', TJSONNumber.Create(DetectionStats.TotalSamples));
        StatsJson.AddPair('correctDetections', TJSONNumber.Create(DetectionStats.CorrectDetections));
        StatsJson.AddPair('incorrectDetections', TJSONNumber.Create(DetectionStats.IncorrectDetections));
        StatsJson.AddPair('accuracyRate', TJSONNumber.Create(DetectionStats.AccuracyRate));
        StatsJson.AddPair('averageConfidence', TJSONNumber.Create(DetectionStats.AverageConfidence));
        StatsJson.AddPair('averageDetectionTime', TJSONNumber.Create(DetectionStats.AverageDetectionTime));

        Json.AddPair('statistics', StatsJson);
      finally
        DetectionStats.Free;
      end;
    end;

    // 添加置信度区间
    if Options.IncludeConfidenceIntervals then
    begin
      ConfidenceIntervals := FStatistics.CalculateConfidenceIntervalStatistics;

      IntervalsArray := TJSONArray.Create;
      for Interval in ConfidenceIntervals do
      begin
        IntervalJson := TJSONObject.Create;
        IntervalJson.AddPair('interval', Interval.Interval);
        IntervalJson.AddPair('sampleCount', TJSONNumber.Create(Interval.SampleCount));
        IntervalJson.AddPair('correctCount', TJSONNumber.Create(Interval.CorrectCount));
        IntervalJson.AddPair('accuracyRate', TJSONNumber.Create(Interval.AccuracyRate));

        IntervalsArray.Add(IntervalJson);
      end;

      Json.AddPair('confidenceIntervals', IntervalsArray);
    end;

    // 添加详细结果
    if Options.IncludeDetailedResults then
    begin
      SamplesArray := TJSONArray.Create;

      for SamplePath in FSampleManager.FDetectionResults.Keys do
      begin
        if FSampleManager.GetDetectionResult(SamplePath, DetectionResult) then
        begin
          // 获取已知编码
          var KnownEncoding := '';
          for Sample in FSampleManager.SampleLoader.GetCollection.GetAllSamples do
          begin
            if Sample.FilePath = SamplePath then
            begin
              KnownEncoding := Sample.KnownEncoding;
              Break;
            end;
          end;

          SampleJson := TJSONObject.Create;
          SampleJson.AddPair('fileName', ExtractFileName(SamplePath));
          SampleJson.AddPair('filePath', SamplePath);
          SampleJson.AddPair('knownEncoding', KnownEncoding);
          SampleJson.AddPair('detectedEncoding', DetectionResult.DetectedEncoding);
          SampleJson.AddPair('confidenceScore', TJSONNumber.Create(DetectionResult.ConfidenceScore));
          SampleJson.AddPair('detectionTime', TJSONNumber.Create(DetectionResult.DetectionTime));
          SampleJson.AddPair('isCorrect', TJSONBool.Create(DetectionResult.IsCorrect));

          SamplesArray.Add(SampleJson);
        end;
      end;

      Json.AddPair('samples', SamplesArray);
    end;

    Result := Json.ToString;
  finally
    Json.Free;
  end;
end;

function TEncodingDetectionReportGenerator.GenerateChartScript: string;
var
  SB: TStringBuilder;
  DetectionStats: TEncodingDetectionStatistics;
  ConfidenceIntervals: TArray<TConfidenceIntervalStatistics>;
  Encodings, EncodingSamples, EncodingCorrect, EncodingAccuracy: TStringList;
  Intervals, IntervalSamples, IntervalCorrect, IntervalAccuracy: TStringList;
  Encoding: string;
  Count, CorrectCount: Integer;
  Interval: TConfidenceIntervalStatistics;
  I: Integer;
begin
  SB := TStringBuilder.Create;
  Encodings := TStringList.Create;
  EncodingSamples := TStringList.Create;
  EncodingCorrect := TStringList.Create;
  EncodingAccuracy := TStringList.Create;
  Intervals := TStringList.Create;
  IntervalSamples := TStringList.Create;
  IntervalCorrect := TStringList.Create;
  IntervalAccuracy := TStringList.Create;

  try
    // 收集编码分布数据
    DetectionStats := FStatistics.CalculateDetectionStatistics;
    try
      for Encoding in DetectionStats.EncodingDistribution.Keys do
      begin
        Count := DetectionStats.EncodingDistribution[Encoding];
        Encodings.Add(Encoding);
        EncodingSamples.Add(IntToStr(Count));

        // 计算该编码的正确检测数
        CorrectCount := 0;
        for var SamplePath in FSampleManager.FDetectionResults.Keys do
        begin
          var DetectionResult: TEncodingDetectionResult;
          if FSampleManager.GetDetectionResult(SamplePath, DetectionResult) and
             (DetectionResult.DetectedEncoding = Encoding) and
             DetectionResult.IsCorrect then
            Inc(CorrectCount);
        end;

        EncodingCorrect.Add(IntToStr(CorrectCount));

        // 计算正确率
        var AccuracyRate := 0.0;
        if Count > 0 then
          AccuracyRate := CorrectCount / Count;

        EncodingAccuracy.Add(Format('%.2f', [AccuracyRate * 100]));
      end;
    finally
      DetectionStats.Free;
    end;

    // 收集置信度区间数据
    ConfidenceIntervals := FStatistics.CalculateConfidenceIntervalStatistics;
    for Interval in ConfidenceIntervals do
    begin
      Intervals.Add(Interval.Interval);
      IntervalSamples.Add(IntToStr(Interval.SampleCount));
      IntervalCorrect.Add(IntToStr(Interval.CorrectCount));
      IntervalAccuracy.Add(Format('%.2f', [Interval.AccuracyRate * 100]));
    end;

    // 生成编码分布图表脚本
    SB.AppendLine('document.addEventListener("DOMContentLoaded", function() {');
    SB.AppendLine('  // 编码分布图表');
    SB.AppendLine('  var encodingCtx = document.getElementById("encodingChart").getContext("2d");');
    SB.AppendLine('  var encodingChart = new Chart(encodingCtx, {');
    SB.AppendLine('    type: "bar",');
    SB.AppendLine('    data: {');

    // 添加标签
    SB.Append('      labels: [');
    for I := 0 to Encodings.Count - 1 do
    begin
      if I > 0 then
        SB.Append(', ');
      SB.Append('"' + Encodings[I] + '"');
    end;
    SB.AppendLine('],');

    // 添加数据集
    SB.AppendLine('      datasets: [{');
    SB.AppendLine('        label: "样本数",');
    SB.AppendLine('        backgroundColor: "rgba(54, 162, 235, 0.5)",');
    SB.AppendLine('        borderColor: "rgba(54, 162, 235, 1)",');
    SB.AppendLine('        borderWidth: 1,');

    // 添加样本数据
    SB.Append('        data: [');
    for I := 0 to EncodingSamples.Count - 1 do
    begin
      if I > 0 then
        SB.Append(', ');
      SB.Append(EncodingSamples[I]);
    end;
    SB.AppendLine('],');
    SB.AppendLine('        yAxisID: "y-axis-1"');
    SB.AppendLine('      }, {');
    SB.AppendLine('        label: "正确率(%)",');
    SB.AppendLine('        backgroundColor: "rgba(255, 99, 132, 0.5)",');
    SB.AppendLine('        borderColor: "rgba(255, 99, 132, 1)",');
    SB.AppendLine('        borderWidth: 1,');
    SB.AppendLine('        type: "line",');

    // 添加正确率数据
    SB.Append('        data: [');
    for I := 0 to EncodingAccuracy.Count - 1 do
    begin
      if I > 0 then
        SB.Append(', ');
      SB.Append(EncodingAccuracy[I]);
    end;
    SB.AppendLine('],');
    SB.AppendLine('        yAxisID: "y-axis-2"');
    SB.AppendLine('      }]');
    SB.AppendLine('    },');

    // 添加选项
    SB.AppendLine('    options: {');
    SB.AppendLine('      responsive: true,');
    SB.AppendLine('      title: {');
    SB.AppendLine('        display: true,');
    SB.AppendLine('        text: "编码分布与正确率"');
    SB.AppendLine('      },');
    SB.AppendLine('      scales: {');
    SB.AppendLine('        yAxes: [{');
    SB.AppendLine('          type: "linear",');
    SB.AppendLine('          display: true,');
    SB.AppendLine('          position: "left",');
    SB.AppendLine('          id: "y-axis-1",');
    SB.AppendLine('          ticks: {');
    SB.AppendLine('            beginAtZero: true');
    SB.AppendLine('          }');
    SB.AppendLine('        }, {');
    SB.AppendLine('          type: "linear",');
    SB.AppendLine('          display: true,');
    SB.AppendLine('          position: "right",');
    SB.AppendLine('          id: "y-axis-2",');
    SB.AppendLine('          ticks: {');
    SB.AppendLine('            beginAtZero: true,');
    SB.AppendLine('            max: 100');
    SB.AppendLine('          },');
    SB.AppendLine('          gridLines: {');
    SB.AppendLine('            drawOnChartArea: false');
    SB.AppendLine('          }');
    SB.AppendLine('        }]');
    SB.AppendLine('      }');
    SB.AppendLine('    }');
    SB.AppendLine('  });');
    SB.AppendLine('');

    // 生成置信度区间图表脚本
    SB.AppendLine('  // 置信度区间图表');
    SB.AppendLine('  var confidenceCtx = document.getElementById("confidenceChart").getContext("2d");');
    SB.AppendLine('  var confidenceChart = new Chart(confidenceCtx, {');
    SB.AppendLine('    type: "bar",');
    SB.AppendLine('    data: {');

    // 添加标签
    SB.Append('      labels: [');
    for I := 0 to Intervals.Count - 1 do
    begin
      if I > 0 then
        SB.Append(', ');
      SB.Append('"' + Intervals[I] + '"');
    end;
    SB.AppendLine('],');

    // 添加数据集
    SB.AppendLine('      datasets: [{');
    SB.AppendLine('        label: "样本数",');
    SB.AppendLine('        backgroundColor: "rgba(54, 162, 235, 0.5)",');
    SB.AppendLine('        borderColor: "rgba(54, 162, 235, 1)",');
    SB.AppendLine('        borderWidth: 1,');

    // 添加样本数据
    SB.Append('        data: [');
    for I := 0 to IntervalSamples.Count - 1 do
    begin
      if I > 0 then
        SB.Append(', ');
      SB.Append(IntervalSamples[I]);
    end;
    SB.AppendLine('],');
    SB.AppendLine('        yAxisID: "y-axis-1"');
    SB.AppendLine('      }, {');
    SB.AppendLine('        label: "正确率(%)",');
    SB.AppendLine('        backgroundColor: "rgba(255, 99, 132, 0.5)",');
    SB.AppendLine('        borderColor: "rgba(255, 99, 132, 1)",');
    SB.AppendLine('        borderWidth: 1,');
    SB.AppendLine('        type: "line",');

    // 添加正确率数据
    SB.Append('        data: [');
    for I := 0 to IntervalAccuracy.Count - 1 do
    begin
      if I > 0 then
        SB.Append(', ');
      SB.Append(IntervalAccuracy[I]);
    end;
    SB.AppendLine('],');
    SB.AppendLine('        yAxisID: "y-axis-2"');
    SB.AppendLine('      }]');
    SB.AppendLine('    },');

    // 添加选项
    SB.AppendLine('    options: {');
    SB.AppendLine('      responsive: true,');
    SB.AppendLine('      title: {');
    SB.AppendLine('        display: true,');
    SB.AppendLine('        text: "置信度区间与正确率"');
    SB.AppendLine('      },');
    SB.AppendLine('      scales: {');
    SB.AppendLine('        yAxes: [{');
    SB.AppendLine('          type: "linear",');
    SB.AppendLine('          display: true,');
    SB.AppendLine('          position: "left",');
    SB.AppendLine('          id: "y-axis-1",');
    SB.AppendLine('          ticks: {');
    SB.AppendLine('            beginAtZero: true');
    SB.AppendLine('          }');
    SB.AppendLine('        }, {');
    SB.AppendLine('          type: "linear",');
    SB.AppendLine('          display: true,');
    SB.AppendLine('          position: "right",');
    SB.AppendLine('          id: "y-axis-2",');
    SB.AppendLine('          ticks: {');
    SB.AppendLine('            beginAtZero: true,');
    SB.AppendLine('            max: 100');
    SB.AppendLine('          },');
    SB.AppendLine('          gridLines: {');
    SB.AppendLine('            drawOnChartArea: false');
    SB.AppendLine('          }');
    SB.AppendLine('        }]');
    SB.AppendLine('      }');
    SB.AppendLine('    }');
    SB.AppendLine('  });');
    SB.AppendLine('});');

    Result := SB.ToString;
  finally
    Encodings.Free;
    EncodingSamples.Free;
    EncodingCorrect.Free;
    EncodingAccuracy.Free;
    Intervals.Free;
    IntervalSamples.Free;
    IntervalCorrect.Free;
    IntervalAccuracy.Free;
    SB.Free;
  end;
end;