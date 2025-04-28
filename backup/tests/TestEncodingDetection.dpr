program TestEncodingDetection;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  EncodingTest in 'EncodingTest.pas',
  UtilsEncodingDetect2 in 'UtilsEncodingDetect2.pas';

var
  TestDir: string;
  Test: TEncodingTest;

begin
  try
    // 设置测试目录
    TestDir := TPath.Combine(ExtractFilePath(ParamStr(0)), 'test_files');
    if not TDirectory.Exists(TestDir) then
      TDirectory.CreateDirectory(TestDir);
      
    WriteLn('开始编码检测测试...');
    WriteLn('测试目录: ', TestDir);
    WriteLn;
    
    // 创建测试实例
    Test := TEncodingTest.Create(TestDir);
    try
      // 运行基本测试
      WriteLn('运行基本编码检测测试...');
      Test.RunTests;
      WriteLn('基本测试完成，请查看 encoding_test_report.md');
      WriteLn;
      
      // 运行批量测试
      WriteLn('运行批量转换测试...');
      Test.RunBatchTests;
      WriteLn('批量测试完成，请查看 batch_test_report.md');
      WriteLn;
      
      // 运行性能测试
      WriteLn('运行性能测试...');
      Test.RunPerformanceTests;
      WriteLn('性能测试完成，请查看 performance_test_report.md');
      WriteLn;
      
      // 运行Python对比测试
      WriteLn('运行Python对比测试...');
      WriteLn('对比测试完成，请查看 comparison_report.md');
      WriteLn;
      
      WriteLn('所有测试完成！');
      WriteLn('请查看测试目录下的报告文件以获取详细结果。');
    finally
      Test.Free;
    end;
    
    Write('按任意键退出...');
    ReadLn;
  except
    on E: Exception do
    begin
      WriteLn('测试过程中出错：');
      WriteLn(E.ClassName, ': ', E.Message);
      ReadLn;
    end;
  end;
end. 