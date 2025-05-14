program TestDetectionReportApp;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  EncodingTestSampleLoader in 'EncodingTestSampleLoader.pas',
  EncodingTestSampleManager in 'EncodingTestSampleManager.pas',
  EncodingTestStatistics in 'EncodingTestStatistics.pas',
  EncodingConfidenceValidator in 'EncodingConfidenceValidator.pas',
  EncodingDetectionReportGenerator in 'EncodingDetectionReportGenerator.pas';

procedure LogMessage(const Msg: string);
begin
  Writeln(Msg);
end;

procedure GenerateTestData(SampleManager: TEncodingTestSampleManager);
var
  DetectionResult: TEncodingDetectionResult;
  ConversionResult: TEncodingConversionResult;
  Samples: TArray<TEncodingSampleMetadata>;
  Sample: TEncodingSampleMetadata;
  I: Integer;
begin
  // 加载测试样本
  SampleManager.LoadSamples('test\samples');
  
  // 获取所有样本
  Samples := SampleManager.SampleLoader.GetCollection.GetAllSamples;
  
  // 生成随机检测结果
  Randomize;
  for I := 0 to Length(Samples) - 1 do
  begin
    Sample := Samples[I];
    
    // 生成检测结果
    DetectionResult := TEncodingDetectionResult.Create(
      Sample.KnownEncoding,                // 检测编码（假设检测正确）
      Random * 0.5 + 0.5,                  // 置信度（0.5-1.0）
      Random(100) + 10,                    // 检测时间（10-110毫秒）
      True,                                // 是否正确
      '');                                 // 错误信息
    
    // 添加检测结果
    SampleManager.AddDetectionResult(Sample.FilePath, DetectionResult);
    
    // 生成转换结果
    ConversionResult := TEncodingConversionResult.Create(
      Sample.KnownEncoding,                // 源编码
      'UTF-8',                             // 目标编码
      Random(200) + 50,                    // 转换时间（50-250毫秒）
      Random(10) > 1,                      // 是否成功（90%成功率）
      IfThen(Random(10) > 1, '', 'Error converting file')); // 错误信息
    
    // 添加转换结果
    SampleManager.AddConversionResult(Sample.FilePath, ConversionResult);
  end;
  
  // 添加一些错误的检测结果
  if Length(Samples) > 0 then
  begin
    Sample := Samples[0];
    
    // 生成错误的检测结果
    DetectionResult := TEncodingDetectionResult.Create(
      'ANSI',                              // 检测编码（错误）
      Random * 0.3 + 0.2,                  // 置信度（0.2-0.5）
      Random(100) + 10,                    // 检测时间（10-110毫秒）
      False,                               // 是否正确
      'Incorrect encoding detected');      // 错误信息
    
    // 添加检测结果
    SampleManager.AddDetectionResult(Sample.FilePath, DetectionResult);
  end;
end;

begin
  try
    Writeln('编码检测正确率报告生成器测试程序');
    Writeln('========================================');
    
    var SampleManager := TEncodingTestSampleManager.Create(LogMessage);
    try
      // 生成测试数据
      Writeln('生成测试数据...');
      GenerateTestData(SampleManager);
      
      // 创建报告生成器
      var ReportGenerator := TEncodingDetectionReportGenerator.Create(SampleManager, LogMessage);
      try
        // 创建报告选项
        var Options := TReportContentOptions.Create(True);
        
        // 生成Markdown报告
        Writeln('生成Markdown报告...');
        ReportGenerator.SaveReportToFile('test\detection_report.md', rfMarkdown, Options);
        
        // 生成HTML报告
        Writeln('生成HTML报告...');
        ReportGenerator.SaveReportToFile('test\detection_report.html', rfHTML, Options);
        
        // 生成CSV报告
        Writeln('生成CSV报告...');
        ReportGenerator.SaveReportToFile('test\detection_report.csv', rfCSV, Options);
        
        // 生成JSON报告
        Writeln('生成JSON报告...');
        ReportGenerator.SaveReportToFile('test\detection_report.json', rfJSON, Options);
        
        Writeln('报告生成完成！');
      finally
        ReportGenerator.Free;
      end;
    finally
      SampleManager.Free;
    end;
    
    Writeln('========================================');
    Writeln('按任意键退出...');
    Readln;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Readln;
    end;
  end;
end.
