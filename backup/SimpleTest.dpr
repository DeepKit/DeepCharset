program SimpleTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils;

begin
  try
    Writeln('简单测试程序');
    Writeln('当前目录: ' + GetCurrentDir);
    
    if DirectoryExists('tests\from') then
    begin
      Writeln('tests\from 目录存在');
      for var FileName in TDirectory.GetFiles('tests\from') do
      begin
        Writeln('- ' + ExtractFileName(FileName));
      end;
    end
    else
    begin
      Writeln('tests\from 目录不存在');
      if not DirectoryExists('tests') then
      begin
        Writeln('创建 tests 目录');
        ForceDirectories('tests');
      end;
      
      Writeln('创建 tests\from 目录');
      ForceDirectories('tests\from');
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  
  Writeln('按Enter键退出...');
  Readln;
end.
