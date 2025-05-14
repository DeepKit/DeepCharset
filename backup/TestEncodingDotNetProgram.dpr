program TestEncodingDotNetProgram;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.IOUtils,
  TestEncodingDotNet in 'TestEncodingDotNet.pas',
  TestEncodingConfig in 'TestEncodingConfig.pas',
  TestStandardSamples in 'TestStandardSamples.pas',
  EncodingComparisonDotNet in 'EncodingComparisonDotNet.pas';

var
  TestDir: string;
  EncodingTest: TEncodingDotNetTest;
  Results: TStringList;
  
begin
  try
    // 设置测试目录
    TestDir := TPath.Combine(ExtractFilePath(ParamStr(0)), 'EncodingTests');
    WriteLn('测试目录: ' + TestDir);
    WriteLn;
    
    WriteLn('开始.NET编码测试...');
    WriteLn('==================================');
    WriteLn;
    
    // 创建并运行测试
    EncodingTest := TEncodingDotNetTest.Create(TestDir);
    try
      // 运行所有测试
      EncodingTest.RunAllTests;
      
      // 获取并显示测试结果摘要
      Results := EncodingTest.GetResults;
      try
        WriteLn('测试完成！');
        WriteLn;
        WriteLn('结果摘要:');
        WriteLn(Results.Text);
        
        WriteLn('结果已保存到: ' + TestDir);
      finally
        Results.Free;
      end;
    finally
      EncodingTest.Free;
    end;
    
    WriteLn('按任意键退出...');
    ReadLn;
  except
    on E: Exception do
    begin
      WriteLn('错误: ' + E.Message);
      ReadLn;
    end;
  end;
end. 