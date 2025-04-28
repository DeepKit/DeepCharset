program EncodingTestRunner;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, Winapi.Windows,
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,

  // Model
  ModelEncoding in 'ModelEncoding.pas',

  // Utils
  UtilsEncodingMemory in 'UtilsEncodingMemory.pas',
  UtilsEncodingTypes in 'UtilsEncodingTypes.pas',
  UtilsEncodingConstants in 'UtilsEncodingConstants.pas',
  UtilsEncodingLogger in 'UtilsEncodingLogger.pas',

  // Tests
  SimpleUTF8Test in 'SimpleUTF8Test.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
  Logger: ITestLogger;

begin
  try
    // 设置控制台输出编码为UTF-8
    SetConsoleOutputCP(65001);

    WriteLn('Encoding Test Runner');

    // 创建测试运行器
    Runner := TDUnitX.CreateRunner;
    Runner.UseRTTI := True;

    // 添加控制台日志记录器
    Logger := TDUnitXConsoleLogger.Create(True);
    Runner.AddLogger(Logger);

    // 运行测试
    Results := Runner.Execute;

    // 显示测试结果
    WriteLn('');
    WriteLn('Test Results:');
    WriteLn('  Total: ', Results.TestCount);
    WriteLn('  Passed: ', Results.PassCount);
    WriteLn('  Failed: ', Results.FailureCount);
    WriteLn('  Errors: ', Results.ErrorCount);
    WriteLn('  Ignored: ', Results.IgnoredCount);
    WriteLn('');
    WriteLn('Press any key to exit...');
    ReadLn;
  except
    on E: Exception do
      WriteLn(E.ClassName, ': ', E.Message);
  end;
end.