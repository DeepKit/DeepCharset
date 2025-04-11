program TestTransSuccess;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  ControllerEncoding in 'ControllerEncoding.pas',
  ModelEncoding in 'ModelEncoding.pas',
  TestEncodingController in 'TestEncodingController.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
  Logger: ITestLogger;
  NUnitLogger: ITestLogger;

begin
  try
    // 创建测试运行器
    Runner := TDUnitX.CreateRunner;
    
    // 添加控制台日志记录器
    Logger := TDUnitXConsoleLogger.Create(true);
    Runner.AddLogger(Logger);
    
    // 添加NUnit XML日志记录器
    NUnitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    Runner.AddLogger(NUnitLogger);
    
    // 运行所有注册的测试
    Results := Runner.Execute;
    
    // 输出测试结果摘要
    Writeln('');
    Writeln('测试运行完成');
    Writeln('总测试数: ' + IntToStr(Results.TestCount));
    Writeln('通过: ' + IntToStr(Results.PassCount));
    Writeln('失败: ' + IntToStr(Results.FailCount));
    Writeln('错误: ' + IntToStr(Results.ErrorCount));
    Writeln('忽略: ' + IntToStr(Results.IgnoredCount));
    
    // 等待用户按键
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('按回车键继续...');
      System.Readln;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  
  // 如果有失败或错误，返回非零退出代码
  if (Results.FailCount > 0) or (Results.ErrorCount > 0) then
    ExitCode := 1
  else
    ExitCode := 0;
end.
