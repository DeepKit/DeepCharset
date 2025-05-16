unit EncodingConsistencyReportGenerator;

{
  EncodingConsistencyReportGenerator.pas
  创建转码一致性报告格式

  作为improve.md中任务2.2.5的实现
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Math,
  System.JSON, EncodingCycleConverter, EncodingTextComparator,
  EncodingDifferenceAnalyzer, EncodingIrreversibleHandler;

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
    IncludeEncodingPairs: Boolean;        // 包含编码对信息
    IncludeDifferenceAnalysis: Boolean;   // 包含差异分析
    IncludeIrreversibleInfo: Boolean;     // 包含不可逆信息
    IncludeDetailedResults: Boolean;      // 包含详细结果
    IncludeCharts: Boolean;               // 包含图表（仅HTML格式）

    constructor Create(AIncludeAll: Boolean);
  end;

  /// <summary>
  /// 转码一致性报告生成器
  /// </summary>
  TEncodingConsistencyReportGenerator = class
  private
    FLogCallback: TProc<string>;

    procedure Log(const Msg: string);
    function GenerateMarkdownReport(const CycleResults: TArray<TCycleConversionResult>;
      const Options: TReportContentOptions): string;
    function GenerateHTMLReport(const CycleResults: TArray<TCycleConversionResult>;
      const Options: TReportContentOptions): string;
    function GenerateCSVReport(const CycleResults: TArray<TCycleConversionResult>;
      const Options: TReportContentOptions): string;
    function GenerateJSONReport(const CycleResults: TArray<TCycleConversionResult>;
      const Options: TReportContentOptions): string;
    function GenerateChartScript(const CycleResults: TArray<TCycleConversionResult>): string;
  public
    constructor Create(ALogCallback: TProc<string> = nil);

    /// <summary>
    /// 生成报告
    /// </summary>
    function GenerateReport(const CycleResults: TArray<TCycleConversionResult>;
      Format: TReportFormat; const Options: TReportContentOptions): string;

    /// <summary>
    /// 保存报告到文件
    /// </summary>
    procedure SaveReportToFile(const FilePath: string;
      const CycleResults: TArray<TCycleConversionResult>;
      Format: TReportFormat; const Options: TReportContentOptions);

    /// <summary>
    /// 日志回调
    /// </summary>
    property LogCallback: TProc<string> read FLogCallback write FLogCallback;
  end;

implementation

uses
  System.IOUtils, System.StrUtils;

{ TReportContentOptions }

constructor TReportContentOptions.Create(AIncludeAll: Boolean);
begin
  IncludeOverallStatistics := AIncludeAll;
  IncludeEncodingPairs := AIncludeAll;
  IncludeDifferenceAnalysis := AIncludeAll;
  IncludeIrreversibleInfo := AIncludeAll;
  IncludeDetailedResults := AIncludeAll;
  IncludeCharts := AIncludeAll;
end;

{ TEncodingConsistencyReportGenerator }

constructor TEncodingConsistencyReportGenerator.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := ALogCallback;
end;

procedure TEncodingConsistencyReportGenerator.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

function TEncodingConsistencyReportGenerator.GenerateReport(const CycleResults: TArray<TCycleConversionResult>;
  Format: TReportFormat; const Options: TReportContentOptions): string;
begin
  case Format of
    rfMarkdown: Result := GenerateMarkdownReport(CycleResults, Options);
    rfHTML: Result := GenerateHTMLReport(CycleResults, Options);
    rfCSV: Result := GenerateCSVReport(CycleResults, Options);
    rfJSON: Result := GenerateJSONReport(CycleResults, Options);
  else
    Result := GenerateMarkdownReport(CycleResults, Options);
  end;

  Log(Format('生成了%s格式的转码一致性报告', [GetEnumName(TypeInfo(TReportFormat), Ord(Format))]));
end;

procedure TEncodingConsistencyReportGenerator.SaveReportToFile(const FilePath: string;
  const CycleResults: TArray<TCycleConversionResult>;
  Format: TReportFormat; const Options: TReportContentOptions);
var
  Report: string;
  FileExt: string;
begin
  Report := GenerateReport(CycleResults, Format, Options);

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

  Log(Format('保存了转码一致性报告到文件: %s', [FilePath]));
end;

function TEncodingConsistencyReportGenerator.GenerateMarkdownReport(const CycleResults: TArray<TCycleConversionResult>;
  const Options: TReportContentOptions): string;
var
  SB: TStringBuilder;
  Result: TCycleConversionResult;
  TotalTests, ReversibleCount, IrreversibleCount: Integer;
  TotalDifferenceCount, TotalSourceSize, TotalIntermediateSize, TotalResultSize: Int64;
  TotalConversionTime: Int64;
  AverageReversibilityRate, AverageDifferencePercentage: Double;
  IrreversibleHandler: TEncodingIrreversibleHandler;
  EncodingPairs: TDictionary<string, Integer>;
  EncodingPair: string;
  Count: Integer;
begin
  SB := TStringBuilder.Create;
  EncodingPairs := TDictionary<string, Integer>.Create;
  IrreversibleHandler := TEncodingIrreversibleHandler.Create(FLogCallback);

  try
    SB.AppendLine('# 转码一致性报告');
    SB.AppendLine('');
    SB.AppendLine('生成时间: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    SB.AppendLine('');

    // 计算统计数据
    TotalTests := Length(CycleResults);
    ReversibleCount := 0;
    IrreversibleCount := 0;
    TotalDifferenceCount := 0;
    TotalSourceSize := 0;
    TotalIntermediateSize := 0;
    TotalResultSize := 0;
    TotalConversionTime := 0;

    for Result in CycleResults do
    begin
      if Result.IsReversible then
        Inc(ReversibleCount)
      else
        Inc(IrreversibleCount);

      TotalDifferenceCount := TotalDifferenceCount + Result.DifferenceCount;
      TotalSourceSize := TotalSourceSize + Result.SourceSize;
      TotalIntermediateSize := TotalIntermediateSize + Result.IntermediateSize;
      TotalResultSize := TotalResultSize + Result.ResultSize;
      TotalConversionTime := TotalConversionTime + Result.ConversionTime;

      // 统计编码对
      EncodingPair := Format('%s→%s→%s', [Result.SourceEncoding, Result.IntermediateEncoding, Result.SourceEncoding]);
      if EncodingPairs.ContainsKey(EncodingPair) then
        EncodingPairs[EncodingPair] := EncodingPairs[EncodingPair] + 1
      else
        EncodingPairs.Add(EncodingPair, 1);
    end;

    // 计算平均值
    if TotalTests > 0 then
    begin
      AverageReversibilityRate := ReversibleCount / TotalTests;
      if TotalSourceSize > 0 then
        AverageDifferencePercentage := (TotalDifferenceCount / TotalSourceSize) * 100
      else
        AverageDifferencePercentage := 0;
    end
    else
    begin
      AverageReversibilityRate := 0;
      AverageDifferencePercentage := 0;
    end;

    // 整体统计
    if Options.IncludeOverallStatistics then
    begin
      SB.AppendLine('## 1. 整体统计');
      SB.AppendLine('');
      SB.AppendLine(Format('- 总测试数: %d', [TotalTests]));
      SB.AppendLine(Format('- 可逆转换数: %d', [ReversibleCount]));
      SB.AppendLine(Format('- 不可逆转换数: %d', [IrreversibleCount]));
      SB.AppendLine(Format('- 可逆率: %.2f%%', [AverageReversibilityRate * 100]));
      SB.AppendLine(Format('- 总差异字符数: %d', [TotalDifferenceCount]));
      SB.AppendLine(Format('- 平均差异百分比: %.2f%%', [AverageDifferencePercentage]));
      SB.AppendLine(Format('- 总转换时间: %d 毫秒', [TotalConversionTime]));
      SB.AppendLine(Format('- 平均转换时间: %.2f 毫秒', [TotalConversionTime / Max(1, TotalTests)]));
      SB.AppendLine('');
    end;

    // 编码对信息
    if Options.IncludeEncodingPairs then
    begin
      SB.AppendLine('## 2. 编码对信息');
      SB.AppendLine('');
      SB.AppendLine('| 编码转换路径 | 测试次数 | 可逆率 | 已知不可逆 |');
      SB.AppendLine('|--------------|----------|--------|------------|');

      for EncodingPair in EncodingPairs.Keys do
      begin
        Count := EncodingPairs[EncodingPair];

        // 计算该编码对的可逆率
        var ReversiblePairCount := 0;
        for Result in CycleResults do
        begin
          var ResultPair := Format('%s→%s→%s', [Result.SourceEncoding, Result.IntermediateEncoding, Result.SourceEncoding]);
          if (ResultPair = EncodingPair) and Result.IsReversible then
            Inc(ReversiblePairCount);
        end;

        var ReversibilityRate := 0.0;
        if Count > 0 then
          ReversibilityRate := ReversiblePairCount / Count;

        // 检查是否是已知的不可逆编码对
        var SourceEncoding := '';
        var IntermediateEncoding := '';

        // 解析编码对
        var EncodingParts := EncodingPair.Split(['→']);
        if Length(EncodingParts) >= 2 then
        begin
          SourceEncoding := EncodingParts[0];
          IntermediateEncoding := EncodingParts[1];
        end;

        var IsKnownIrreversible := IrreversibleHandler.IsKnownIrreversiblePair(SourceEncoding, IntermediateEncoding);

        SB.AppendLine(Format('| %s | %d | %.2f%% | %s |',
          [EncodingPair, Count, ReversibilityRate * 100,
           IfThen(IsKnownIrreversible, '是', '否')]));
      end;

      SB.AppendLine('');
    end;

    // 详细结果
    if Options.IncludeDetailedResults then
    begin
      SB.AppendLine('## 3. 详细结果');
      SB.AppendLine('');
      SB.AppendLine('| 源编码 | 中间编码 | 可逆 | 差异字符数 | 差异百分比 | 源大小 | 中间大小 | 结果大小 | 转换时间(毫秒) |');
      SB.AppendLine('|--------|----------|------|------------|------------|--------|----------|----------|----------------|');

      for Result in CycleResults do
      begin
        // 计算差异百分比
        var DifferencePercentage := 0.0;
        if Result.SourceSize > 0 then
          DifferencePercentage := (Result.DifferenceCount / Result.SourceSize) * 100;

        SB.AppendLine(Format('| %s | %s | %s | %d | %.2f%% | %d | %d | %d | %d |',
          [Result.SourceEncoding, Result.IntermediateEncoding,
           IfThen(Result.IsReversible, '是', '否'),
           Result.DifferenceCount, DifferencePercentage,
           Result.SourceSize, Result.IntermediateSize, Result.ResultSize,
           Result.ConversionTime]));
      end;

      SB.AppendLine('');
    end;

    // 不可逆信息
    if Options.IncludeIrreversibleInfo then
    begin
      SB.AppendLine('## 4. 不可逆转换分析');
      SB.AppendLine('');

      if IrreversibleCount > 0 then
      begin
        SB.AppendLine('### 4.1 不可逆编码对');
        SB.AppendLine('');
        SB.AppendLine('| 源编码 | 中间编码 | 差异字符数 | 差异百分比 | 可能原因 |');
        SB.AppendLine('|--------|----------|------------|------------|----------|');

        for Result in CycleResults do
        begin
          if not Result.IsReversible then
          begin
            // 计算差异百分比
            var DifferencePercentage := 0.0;
            if Result.SourceSize > 0 then
              DifferencePercentage := (Result.DifferenceCount / Result.SourceSize) * 100;

            // 获取编码对信息
            var PairInfo := IrreversibleHandler.GetEncodingPairInfo(Result.SourceEncoding, Result.IntermediateEncoding);

            // 生成可能原因描述
            var ReasonDesc := '';
            if PairInfo.IsIrreversible then
              ReasonDesc := PairInfo.Description
            else
              ReasonDesc := '未知原因';

            SB.AppendLine(Format('| %s | %s | %d | %.2f%% | %s |',
              [Result.SourceEncoding, Result.IntermediateEncoding,
               Result.DifferenceCount, DifferencePercentage, ReasonDesc]));
          end;
        end;

        SB.AppendLine('');

        SB.AppendLine('### 4.2 处理建议');
        SB.AppendLine('');
        SB.AppendLine('对于不可逆转换，建议采取以下措施：');
        SB.AppendLine('');
        SB.AppendLine('1. 尽量使用支持更广泛字符集的编码，如UTF-8或UTF-16。');
        SB.AppendLine('2. 对于必须使用特定编码的情况，保留原始文件的备份。');
        SB.AppendLine('3. 在转换前检查文本内容，确保不包含目标编码无法表示的字符。');
        SB.AppendLine('4. 对于重要文档，转换后进行人工审核，确保内容正确。');
        SB.AppendLine('');
      end
      else
      begin
        SB.AppendLine('所有测试的转换都是可逆的，无需特别处理。');
        SB.AppendLine('');
      end;
    end;

    // 差异分析
    if Options.IncludeDifferenceAnalysis and (TotalDifferenceCount > 0) then
    begin
      SB.AppendLine('## 5. 差异分析');
      SB.AppendLine('');
      SB.AppendLine('### 5.1 差异分布');
      SB.AppendLine('');

      // 按差异数量排序
      var SortedResults := TArray<TCycleConversionResult>(CycleResults);
      TArray.Sort<TCycleConversionResult>(SortedResults,
        function(const Left, Right: TCycleConversionResult): Integer
        begin
          Result := Right.DifferenceCount - Left.DifferenceCount;
        end);

      SB.AppendLine('| 差异范围 | 转换数 | 百分比 |');
      SB.AppendLine('|----------|--------|--------|');

      var NoDiffCount := 0;
      var SmallDiffCount := 0;
      var MediumDiffCount := 0;
      var LargeDiffCount := 0;

      for Result in SortedResults do
      begin
        if Result.DifferenceCount = 0 then
          Inc(NoDiffCount)
        else if Result.DifferenceCount < 10 then
          Inc(SmallDiffCount)
        else if Result.DifferenceCount < 100 then
          Inc(MediumDiffCount)
        else
          Inc(LargeDiffCount);
      end;

      if TotalTests > 0 then
      begin
        SB.AppendLine(Format('| 无差异 (0) | %d | %.2f%% |',
          [NoDiffCount, (NoDiffCount / TotalTests) * 100]));
        SB.AppendLine(Format('| 小差异 (1-9) | %d | %.2f%% |',
          [SmallDiffCount, (SmallDiffCount / TotalTests) * 100]));
        SB.AppendLine(Format('| 中等差异 (10-99) | %d | %.2f%% |',
          [MediumDiffCount, (MediumDiffCount / TotalTests) * 100]));
        SB.AppendLine(Format('| 大差异 (100+) | %d | %.2f%% |',
          [LargeDiffCount, (LargeDiffCount / TotalTests) * 100]));
      end;

      SB.AppendLine('');
    end;

    System.Result := SB.ToString;
  finally
    IrreversibleHandler.Free;
    EncodingPairs.Free;
    SB.Free;
  end;
end;

function TEncodingConsistencyReportGenerator.GenerateCSVReport(const CycleResults: TArray<TCycleConversionResult>;
  const Options: TReportContentOptions): string;
var
  SB: TStringBuilder;
  Result: TCycleConversionResult;
begin
  SB := TStringBuilder.Create;
  try
    // 添加CSV头部
    SB.AppendLine('源编码,中间编码,可逆,差异字符数,差异百分比,源大小,中间大小,结果大小,转换时间(毫秒)');

    // 添加详细结果
    for Result in CycleResults do
    begin
      // 计算差异百分比
      var DifferencePercentage := 0.0;
      if Result.SourceSize > 0 then
        DifferencePercentage := (Result.DifferenceCount / Result.SourceSize) * 100;

      // 添加CSV行
      SB.AppendLine(Format('"%s","%s",%s,%d,%.2f,%d,%d,%d,%d',
        [Result.SourceEncoding, Result.IntermediateEncoding,
         IfThen(Result.IsReversible, '是', '否'),
         Result.DifferenceCount, DifferencePercentage,
         Result.SourceSize, Result.IntermediateSize, Result.ResultSize,
         Result.ConversionTime]));
    end;

    System.Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TEncodingConsistencyReportGenerator.GenerateJSONReport(const CycleResults: TArray<TCycleConversionResult>;
  const Options: TReportContentOptions): string;
var
  Json: TJSONObject;
  ResultsArray: TJSONArray;
  ResultJson: TJSONObject;
  StatsJson: TJSONObject;
  Result: TCycleConversionResult;
  TotalTests, ReversibleCount, IrreversibleCount: Integer;
  TotalDifferenceCount, TotalSourceSize, TotalIntermediateSize, TotalResultSize: Int64;
  TotalConversionTime: Int64;
  AverageReversibilityRate, AverageDifferencePercentage: Double;
begin
  Json := TJSONObject.Create;
  try
    // 添加报告生成时间
    Json.AddPair('generatedAt', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now));

    // 计算统计数据
    TotalTests := Length(CycleResults);
    ReversibleCount := 0;
    IrreversibleCount := 0;
    TotalDifferenceCount := 0;
    TotalSourceSize := 0;
    TotalIntermediateSize := 0;
    TotalResultSize := 0;
    TotalConversionTime := 0;

    for Result in CycleResults do
    begin
      if Result.IsReversible then
        Inc(ReversibleCount)
      else
        Inc(IrreversibleCount);

      TotalDifferenceCount := TotalDifferenceCount + Result.DifferenceCount;
      TotalSourceSize := TotalSourceSize + Result.SourceSize;
      TotalIntermediateSize := TotalIntermediateSize + Result.IntermediateSize;
      TotalResultSize := TotalResultSize + Result.ResultSize;
      TotalConversionTime := TotalConversionTime + Result.ConversionTime;
    end;

    // 计算平均值
    if TotalTests > 0 then
    begin
      AverageReversibilityRate := ReversibleCount / TotalTests;
      if TotalSourceSize > 0 then
        AverageDifferencePercentage := (TotalDifferenceCount / TotalSourceSize) * 100
      else
        AverageDifferencePercentage := 0;
    end
    else
    begin
      AverageReversibilityRate := 0;
      AverageDifferencePercentage := 0;
    end;

    // 添加整体统计
    if Options.IncludeOverallStatistics then
    begin
      StatsJson := TJSONObject.Create;
      StatsJson.AddPair('totalTests', TJSONNumber.Create(TotalTests));
      StatsJson.AddPair('reversibleCount', TJSONNumber.Create(ReversibleCount));
      StatsJson.AddPair('irreversibleCount', TJSONNumber.Create(IrreversibleCount));
      StatsJson.AddPair('reversibilityRate', TJSONNumber.Create(AverageReversibilityRate));
      StatsJson.AddPair('totalDifferenceCount', TJSONNumber.Create(TotalDifferenceCount));
      StatsJson.AddPair('averageDifferencePercentage', TJSONNumber.Create(AverageDifferencePercentage));
      StatsJson.AddPair('totalConversionTime', TJSONNumber.Create(TotalConversionTime));
      StatsJson.AddPair('averageConversionTime', TJSONNumber.Create(TotalConversionTime / Max(1, TotalTests)));

      Json.AddPair('statistics', StatsJson);
    end;

    // 添加详细结果
    ResultsArray := TJSONArray.Create;

    for Result in CycleResults do
    begin
      ResultJson := TJSONObject.Create;
      ResultJson.AddPair('sourceEncoding', Result.SourceEncoding);
      ResultJson.AddPair('intermediateEncoding', Result.IntermediateEncoding);
      ResultJson.AddPair('isReversible', TJSONBool.Create(Result.IsReversible));
      ResultJson.AddPair('differenceCount', TJSONNumber.Create(Result.DifferenceCount));

      // 计算差异百分比
      var DifferencePercentage := 0.0;
      if Result.SourceSize > 0 then
        DifferencePercentage := (Result.DifferenceCount / Result.SourceSize) * 100;

      ResultJson.AddPair('differencePercentage', TJSONNumber.Create(DifferencePercentage));
      ResultJson.AddPair('sourceSize', TJSONNumber.Create(Result.SourceSize));
      ResultJson.AddPair('intermediateSize', TJSONNumber.Create(Result.IntermediateSize));
      ResultJson.AddPair('resultSize', TJSONNumber.Create(Result.ResultSize));
      ResultJson.AddPair('conversionTime', TJSONNumber.Create(Result.ConversionTime));

      if Result.ErrorMessage <> '' then
        ResultJson.AddPair('errorMessage', Result.ErrorMessage);

      ResultsArray.Add(ResultJson);
    end;

    Json.AddPair('results', ResultsArray);

    System.Result := Json.ToString;
  finally
    Json.Free;
  end;
end;

function TEncodingConsistencyReportGenerator.GenerateHTMLReport(const CycleResults: TArray<TCycleConversionResult>;
  const Options: TReportContentOptions): string;
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
    SB.AppendLine('  <title>转码一致性报告</title>');
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
    SB.AppendLine('    .reversible { color: green; }');
    SB.AppendLine('    .irreversible { color: red; }');
    SB.AppendLine('  </style>');

    // 如果包含图表，添加Chart.js库
    if Options.IncludeCharts then
    begin
      SB.AppendLine('  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>');
    end;

    SB.AppendLine('</head>');
    SB.AppendLine('<body>');

    // 生成Markdown内容并转换为HTML
    MarkdownContent := GenerateMarkdownReport(CycleResults, Options);

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

    // 添加可逆/不可逆样式
    MarkdownContent := StringReplace(MarkdownContent, '>是<', ' class="reversible">是<', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, '>否<', ' class="irreversible">否<', [rfReplaceAll]);

    // 添加内容
    SB.AppendLine(MarkdownContent);

    // 如果包含图表，添加图表
    if Options.IncludeCharts then
    begin
      SB.AppendLine('<h2>6. 图表</h2>');

      // 添加可逆率图表
      SB.AppendLine('<h3>6.1 编码对可逆率</h3>');
      SB.AppendLine('<div class="chart-container">');
      SB.AppendLine('  <canvas id="reversibilityChart"></canvas>');
      SB.AppendLine('</div>');

      // 添加差异分布图表
      SB.AppendLine('<h3>6.2 差异分布</h3>');
      SB.AppendLine('<div class="chart-container">');
      SB.AppendLine('  <canvas id="differenceChart"></canvas>');
      SB.AppendLine('</div>');

      // 添加图表脚本
      ChartScript := GenerateChartScript(CycleResults);
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

function TEncodingConsistencyReportGenerator.GenerateChartScript(const CycleResults: TArray<TCycleConversionResult>): string;
var
  SB: TStringBuilder;
  EncodingPairs: TDictionary<string, TList<TCycleConversionResult>>;
  EncodingPair: string;
  ResultsList: TList<TCycleConversionResult>;
  Result: TCycleConversionResult;
  EncodingPairLabels, ReversibilityRates: TStringList;
  NoDiffCount, SmallDiffCount, MediumDiffCount, LargeDiffCount: Integer;
  I: Integer;
begin
  SB := TStringBuilder.Create;
  EncodingPairs := TDictionary<string, TList<TCycleConversionResult>>.Create;
  EncodingPairLabels := TStringList.Create;
  ReversibilityRates := TStringList.Create;

  try
    // 按编码对分组
    for Result in CycleResults do
    begin
      EncodingPair := Format('%s→%s', [Result.SourceEncoding, Result.IntermediateEncoding]);

      if not EncodingPairs.TryGetValue(EncodingPair, ResultsList) then
      begin
        ResultsList := TList<TCycleConversionResult>.Create;
        EncodingPairs.Add(EncodingPair, ResultsList);
      end;

      ResultsList.Add(Result);
    end;

    // 计算每个编码对的可逆率
    for EncodingPair in EncodingPairs.Keys do
    begin
      ResultsList := EncodingPairs[EncodingPair];

      var TotalCount := ResultsList.Count;
      var ReversibleCount := 0;

      for Result in ResultsList do
      begin
        if Result.IsReversible then
          Inc(ReversibleCount);
      end;

      var ReversibilityRate := 0.0;
      if TotalCount > 0 then
        ReversibilityRate := (ReversibleCount / TotalCount) * 100;

      EncodingPairLabels.Add(EncodingPair);
      ReversibilityRates.Add(Format('%.2f', [ReversibilityRate]));
    end;

    // 计算差异分布
    NoDiffCount := 0;
    SmallDiffCount := 0;
    MediumDiffCount := 0;
    LargeDiffCount := 0;

    for Result in CycleResults do
    begin
      if Result.DifferenceCount = 0 then
        Inc(NoDiffCount)
      else if Result.DifferenceCount < 10 then
        Inc(SmallDiffCount)
      else if Result.DifferenceCount < 100 then
        Inc(MediumDiffCount)
      else
        Inc(LargeDiffCount);
    end;

    // 生成可逆率图表脚本
    SB.AppendLine('document.addEventListener("DOMContentLoaded", function() {');
    SB.AppendLine('  // 可逆率图表');
    SB.AppendLine('  var reversibilityCtx = document.getElementById("reversibilityChart").getContext("2d");');
    SB.AppendLine('  var reversibilityChart = new Chart(reversibilityCtx, {');
    SB.AppendLine('    type: "bar",');
    SB.AppendLine('    data: {');

    // 添加标签
    SB.Append('      labels: [');
    for I := 0 to EncodingPairLabels.Count - 1 do
    begin
      if I > 0 then
        SB.Append(', ');
      SB.Append('"' + EncodingPairLabels[I] + '"');
    end;
    SB.AppendLine('],');

    // 添加数据集
    SB.AppendLine('      datasets: [{');
    SB.AppendLine('        label: "可逆率(%)",');
    SB.AppendLine('        backgroundColor: "rgba(54, 162, 235, 0.5)",');
    SB.AppendLine('        borderColor: "rgba(54, 162, 235, 1)",');
    SB.AppendLine('        borderWidth: 1,');

    // 添加可逆率数据
    SB.Append('        data: [');
    for I := 0 to ReversibilityRates.Count - 1 do
    begin
      if I > 0 then
        SB.Append(', ');
      SB.Append(ReversibilityRates[I]);
    end;
    SB.AppendLine(']');
    SB.AppendLine('      }]');
    SB.AppendLine('    },');

    // 添加选项
    SB.AppendLine('    options: {');
    SB.AppendLine('      responsive: true,');
    SB.AppendLine('      title: {');
    SB.AppendLine('        display: true,');
    SB.AppendLine('        text: "编码对可逆率"');
    SB.AppendLine('      },');
    SB.AppendLine('      scales: {');
    SB.AppendLine('        yAxes: [{');
    SB.AppendLine('          ticks: {');
    SB.AppendLine('            beginAtZero: true,');
    SB.AppendLine('            max: 100');
    SB.AppendLine('          }');
    SB.AppendLine('        }]');
    SB.AppendLine('      }');
    SB.AppendLine('    }');
    SB.AppendLine('  });');
    SB.AppendLine('');

    // 生成差异分布图表脚本
    SB.AppendLine('  // 差异分布图表');
    SB.AppendLine('  var differenceCtx = document.getElementById("differenceChart").getContext("2d");');
    SB.AppendLine('  var differenceChart = new Chart(differenceCtx, {');
    SB.AppendLine('    type: "pie",');
    SB.AppendLine('    data: {');
    SB.AppendLine('      labels: ["无差异 (0)", "小差异 (1-9)", "中等差异 (10-99)", "大差异 (100+)"],');
    SB.AppendLine('      datasets: [{');
    SB.AppendLine('        data: [' + IntToStr(NoDiffCount) + ', ' + IntToStr(SmallDiffCount) + ', ' +
      IntToStr(MediumDiffCount) + ', ' + IntToStr(LargeDiffCount) + '],');
    SB.AppendLine('        backgroundColor: [');
    SB.AppendLine('          "rgba(75, 192, 192, 0.5)",');
    SB.AppendLine('          "rgba(54, 162, 235, 0.5)",');
    SB.AppendLine('          "rgba(255, 206, 86, 0.5)",');
    SB.AppendLine('          "rgba(255, 99, 132, 0.5)"');
    SB.AppendLine('        ],');
    SB.AppendLine('        borderColor: [');
    SB.AppendLine('          "rgba(75, 192, 192, 1)",');
    SB.AppendLine('          "rgba(54, 162, 235, 1)",');
    SB.AppendLine('          "rgba(255, 206, 86, 1)",');
    SB.AppendLine('          "rgba(255, 99, 132, 1)"');
    SB.AppendLine('        ],');
    SB.AppendLine('        borderWidth: 1');
    SB.AppendLine('      }]');
    SB.AppendLine('    },');
    SB.AppendLine('    options: {');
    SB.AppendLine('      responsive: true,');
    SB.AppendLine('      title: {');
    SB.AppendLine('        display: true,');
    SB.AppendLine('        text: "差异分布"');
    SB.AppendLine('      }');
    SB.AppendLine('    }');
    SB.AppendLine('  });');
    SB.AppendLine('});');

    Result := SB.ToString;
  finally
    // 清理资源
    for ResultsList in EncodingPairs.Values do
      ResultsList.Free;

    EncodingPairs.Free;
    EncodingPairLabels.Free;
    ReversibilityRates.Free;
    SB.Free;
  end;
end;
