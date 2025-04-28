program EncodingCommandLineTool;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  ModelEncoding in 'ModelEncoding.pas',
  EncodingUtils in 'EncodingUtils.pas',
  EncodingLogger in 'EncodingLogger.pas',
  EncodingConfig in 'EncodingConfig.pas',
  BatchEncodingConverter in 'BatchEncodingConverter.pas',
  EncodingCommandLine in 'EncodingCommandLine.pas';

procedure HandleCtrlC(Sig: Integer); stdcall;
begin
  WriteLn(#13#10'操作被用户中断!');
  ExitCode := 2;
  Halt(2);
end;

begin
  try
    // 设置Ctrl+C处理程序
    SetConsoleCtrlHandler(@HandleCtrlC, True);
    
    // 运行命令行工具
    RunEncodingTool;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end. 