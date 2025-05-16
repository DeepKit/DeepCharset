program TestUTF8BOMConverterProject;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  UTF8BOMConverter_Enhanced in 'UTF8BOMConverter_Enhanced.pas',
  TestUTF8BOMConverter in 'TestUTF8BOMConverter.pas';

begin
  try
    Writeln('开始执行UTF8BOMConverter增强版测试...');
    Writeln;
    
    TTestUTF8BOMConverter.RunAllTests;
    
    Writeln;
    Writeln('测试完成，按任意键退出...');
    Readln;
  except
    on E: Exception do
    begin
      Writeln('出现错误: ' + E.Message);
      Readln;
    end;
  end;
end. 