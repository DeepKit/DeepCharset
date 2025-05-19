program EncodingUtilsTest;

{$APPTYPE CONSOLE}

//{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  UtilsEncodingTypes in 'UtilsEncodingTypes.pas',
  UtilsEncodingBOM_Improved in 'UtilsEncodingBOM_Improved.pas',
  UtilsEncodingDetector_Improved in 'UtilsEncodingDetector_Improved.pas',
  UtilsEncodingConverter_Improved in 'UtilsEncodingConverter_Improved.pas',
  UtilsEncodingManager in 'UtilsEncodingManager.pas',
  TestEncodingUtils in 'TestEncodingUtils.pas';

var
  Test: TEncodingUtilsTest;
  Results: string;

begin
  // 设置控制台输出编码为UTF-8
  SetConsoleOutputCP(CP_UTF8);

  try
    // 创建测试对象
    Test := TEncodingUtilsTest.Create;
    try
      // 运行所有测试
      Test.RunAllTests;

      // 获取测试结果
      Results := Test.GetTestResults;

      // 输出测试结果
      WriteLn(Results);

      // 保存测试结果到文件
      with TStringList.Create do
      try
        Text := Results;
        SaveToFile('TestResults.log');
      finally
        Free;
      end;

      // 等待用户按键
      WriteLn;
      WriteLn('测试完成，按任意键退出...');
      ReadLn;
    finally
      // 释放测试对象
      Test.Free;
    end;
  except
    on E: Exception do
      WriteLn(E.ClassName, ': ', E.Message);
  end;
end.
