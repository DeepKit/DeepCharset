function TEncodingPerformanceBenchmark.GenerateHTMLReport(const Result: TPerformanceBenchmarkResult; 
  const Options: TBenchmarkReportOptions): string;
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
    SB.AppendLine('  <title>编码性能基准测试报告</title>');
    SB.AppendLine('  <style>');
    SB.AppendLine('    body { font-family: Arial, sans-serif; line-height: 1.6; margin: 0; padding: 20px; color: #333; }');
    SB.AppendLine('    h1 { color: #2c3e50; border-bottom: 2px solid #eee; padding-bottom: 10px; }');
    SB.AppendLine('    h2 { color: #3498db; margin-top: 30px; }');
    SB.AppendLine('    h3 { color: #2980b9; }');
    SB.AppendLine('    h4 { color: #27ae60; }');
    SB.AppendLine('    table { border-collapse: collapse; width: 100%; margin: 20px 0; }');
    SB.AppendLine('    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }');
    SB.AppendLine('    th { background-color: #f2f2f2; }');
    SB.AppendLine('    tr:nth-child(even) { background-color: #f9f9f9; }');
    SB.AppendLine('    .chart-container { width: 100%; height: 400px; margin: 20px 0; }');
    SB.AppendLine('    .summary { background-color: #f8f9fa; border-left: 4px solid #3498db; padding: 10px; margin: 20px 0; }');
    SB.AppendLine('    .recommendation { background-color: #f8f9fa; border-left: 4px solid #27ae60; padding: 10px; margin: 20px 0; }');
    SB.AppendLine('    .warning { background-color: #f8f9fa; border-left: 4px solid #e74c3c; padding: 10px; margin: 20px 0; }');
    SB.AppendLine('  </style>');
    
    // 如果包含图表，添加Chart.js库
    if Options.IncludeCharts then
    begin
      SB.AppendLine('  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>');
    end;
    
    SB.AppendLine('</head>');
    SB.AppendLine('<body>');
    
    // 生成Markdown内容并转换为HTML
    MarkdownContent := GenerateMarkdownReport(Result, Options);
    
    // 简单的Markdown到HTML转换（仅支持基本格式）
    // 标题转换
    MarkdownContent := StringReplace(MarkdownContent, '# ', '<h1>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, '## ', '<h2>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, '### ', '<h3>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, '#### ', '<h4>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, #13#10'<h1>', '</p>'#13#10'<h1>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, #13#10'<h2>', '</p>'#13#10'<h2>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, #13#10'<h3>', '</p>'#13#10'<h3>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, #13#10'<h4>', '</p>'#13#10'<h4>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, '<h1>', '<h1>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, '<h2>', '<h2>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, '<h3>', '<h3>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, '<h4>', '<h4>', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, #13#10, '</h1>'#13#10'<p>', [rfReplaceAll, rfIgnoreCase], 1);
    MarkdownContent := StringReplace(MarkdownContent, #13#10, '</h2>'#13#10'<p>', [rfReplaceAll, rfIgnoreCase], 1);
    MarkdownContent := StringReplace(MarkdownContent, #13#10, '</h3>'#13#10'<p>', [rfReplaceAll, rfIgnoreCase], 1);
    MarkdownContent := StringReplace(MarkdownContent, #13#10, '</h4>'#13#10'<p>', [rfReplaceAll, rfIgnoreCase], 1);
    
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
    
    // 添加样式类
    MarkdownContent := StringReplace(MarkdownContent, '<h2>1. 性能测试结果', '<h2 class="summary">1. 性能测试结果', [rfReplaceAll]);
    MarkdownContent := StringReplace(MarkdownContent, '<h2>5. 优化建议', '<h2 class="recommendation">5. 优化建议', [rfReplaceAll]);
    
    // 添加内容
    SB.AppendLine(MarkdownContent);
    
    // 如果包含图表，添加图表
    if Options.IncludeCharts then
    begin
      SB.AppendLine('<h2>6. 性能图表</h2>');
      
      // 添加性能测试图表
      if Options.IncludePerformanceResults then
      begin
        SB.AppendLine('<h3>6.1 性能测试结果</h3>');
        SB.AppendLine('<div class="chart-container">');
        SB.AppendLine('  <canvas id="performanceChart"></canvas>');
        SB.AppendLine('</div>');
      end;
      
      // 添加内存使用图表
      if Options.IncludeMemoryUsage then
      begin
        SB.AppendLine('<h3>6.2 内存使用情况</h3>');
        SB.AppendLine('<div class="chart-container">');
        SB.AppendLine('  <canvas id="memoryChart"></canvas>');
        SB.AppendLine('</div>');
      end;
      
      // 添加CPU使用率图表
      if Options.IncludeCPUUsage then
      begin
        SB.AppendLine('<h3>6.3 CPU使用率</h3>');
        SB.AppendLine('<div class="chart-container">');
        SB.AppendLine('  <canvas id="cpuChart"></canvas>');
        SB.AppendLine('</div>');
      end;
      
      // 添加时间分析图表
      if Options.IncludeTimeAnalysis then
      begin
        SB.AppendLine('<h3>6.4 时间分析</h3>');
        SB.AppendLine('<div class="chart-container">');
        SB.AppendLine('  <canvas id="timeChart"></canvas>');
        SB.AppendLine('</div>');
      end;
      
      // 添加图表脚本
      ChartScript := GenerateChartScript(Result);
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
