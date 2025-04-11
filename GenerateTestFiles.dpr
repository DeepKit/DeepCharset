program GenerateTestFiles;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  System.IOUtils,
  TestFileGenerator in 'TestFileGenerator.pas';

begin
  try
    Writeln('正在生成测试文件...');
    TTestFileGenerator.GenerateTestFiles(TPath.GetDirectoryName(ParamStr(0)));
    Writeln('测试文件生成完成！');
    Writeln('文件保存在: ' + TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'TestFiles'));
    Writeln('按任意键退出...');
    Readln;
  except
    on E: Exception do
    begin
      Writeln('生成测试文件时出错: ' + E.Message);
      Readln;
    end;
  end;
end.
