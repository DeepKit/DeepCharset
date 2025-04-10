program JCLEncodingDetector;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  JclStrings,
  JclFileUtils,
  JclAnsiStrings,
  EncodingDetectorUnit in 'EncodingDetectorUnit.pas';

begin
  try
    WriteLn('开始测试编码检测和转换功能...');
    WriteLn('测试结果将写入tests.md文件');
    
    // 运行自动测试并将结果写入文件
    RunAutomatedTests;
    
    WriteLn('测试完成，请查看tests.md文件获取测试结果');
    WriteLn('按任意键退出...');
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end. 