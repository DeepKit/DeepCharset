program TestConsistencyReportApp;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  EncodingCycleConverter in 'EncodingCycleConverter.pas',
  EncodingTextComparator in 'EncodingTextComparator.pas',
  EncodingDifferenceAnalyzer in 'EncodingDifferenceAnalyzer.pas',
  EncodingIrreversibleHandler in 'EncodingIrreversibleHandler.pas',
  EncodingConsistencyReportGenerator in 'EncodingConsistencyReportGenerator.pas';

procedure LogMessage(const Msg: string);
begin
  Writeln(Msg);
end;

procedure GenerateTestData(var CycleResults: TArray<TCycleConversionResult>);
var
  SourceEncodings, IntermediateEncodings: TArray<string>;
  SourceEncoding, IntermediateEncoding: string;
  I, J: Integer;
  IsReversible: Boolean;
  DifferenceCount: Integer;
  SourceSize, IntermediateSize, ResultSize: Integer;
  ConversionTime: Int64;
  Result: TCycleConversionResult;
begin
  // 定义测试用的编码
  SourceEncodings := ['UTF-8', 'UTF-8 with BOM', 'GBK', 'GB18030', 'Big5', 'Shift-JIS', 'EUC-KR', 'ISO-8859-1'];
  IntermediateEncodings := ['UTF-8', 'UTF-8 with BOM', 'GBK', 'GB18030', 'Big5', 'Shift-JIS', 'EUC-KR', 'ISO-8859-1', 'ASCII'];
  
  // 创建测试结果数组
  SetLength(CycleResults, Length(SourceEncodings) * Length(IntermediateEncodings));
  
  // 生成测试数据
  Randomize;
  I := 0;
  for SourceEncoding in SourceEncodings do
  begin
    for IntermediateEncoding in IntermediateEncodings do
    begin
      // 根据编码对确定是否可逆
      if (SourceEncoding = IntermediateEncoding) or
         ((SourceEncoding = 'UTF-8') and (IntermediateEncoding = 'UTF-8 with BOM')) or
         ((SourceEncoding = 'UTF-8 with BOM') and (IntermediateEncoding = 'UTF-8')) then
        IsReversible := True
      else if (IntermediateEncoding = 'ASCII') and (SourceEncoding <> 'ASCII') then
        IsReversible := False
      else
        IsReversible := Random(10) > 3; // 70%的概率可逆
      
      // 生成差异数据
      if IsReversible then
        DifferenceCount := 0
      else
        DifferenceCount := Random(200);
      
      // 生成大小数据
      SourceSize := Random(10000) + 1000;
      IntermediateSize := SourceSize + Random(1000) - 500;
      ResultSize := SourceSize + Random(1000) - 500;
      
      // 生成转换时间
      ConversionTime := Random(500) + 50;
      
      // 创建结果
      Result := TCycleConversionResult.Create(
        SourceEncoding, IntermediateEncoding, IsReversible, DifferenceCount,
        SourceSize, IntermediateSize, ResultSize, ConversionTime);
      
      // 添加到结果数组
      CycleResults[I] := Result;
      Inc(I);
    end;
  end;
end;

begin
  try
    Writeln('转码一致性报告生成器测试程序');
    Writeln('========================================');
    
    // 生成测试数据
    var CycleResults: TArray<TCycleConversionResult>;
    Writeln('生成测试数据...');
    GenerateTestData(CycleResults);
    Writeln(Format('生成了 %d 个测试结果', [Length(CycleResults)]));
    
    // 创建报告生成器
    var ReportGenerator := TEncodingConsistencyReportGenerator.Create(LogMessage);
    try
      // 创建报告选项
      var Options := TReportContentOptions.Create(True);
      
      // 生成Markdown报告
      Writeln('生成Markdown报告...');
      ReportGenerator.SaveReportToFile('test\consistency_report.md', CycleResults, rfMarkdown, Options);
      
      // 生成HTML报告
      Writeln('生成HTML报告...');
      ReportGenerator.SaveReportToFile('test\consistency_report.html', CycleResults, rfHTML, Options);
      
      // 生成CSV报告
      Writeln('生成CSV报告...');
      ReportGenerator.SaveReportToFile('test\consistency_report.csv', CycleResults, rfCSV, Options);
      
      // 生成JSON报告
      Writeln('生成JSON报告...');
      ReportGenerator.SaveReportToFile('test\consistency_report.json', CycleResults, rfJSON, Options);
      
      Writeln('报告生成完成！');
    finally
      ReportGenerator.Free;
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
