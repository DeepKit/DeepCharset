program TestRunner;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  TestFramework,
  TextTestRunner,
  TestsRegister,
  SmartBufferManager in 'SmartBufferManager.pas',
  TestSmartBufferManager in 'TestSmartBufferManager.pas';

begin
  try
    RegisterTests;
    with TextTestRunner.RunRegisteredTests do
      Free;
    Writeln('按回车键退出...');
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end. 