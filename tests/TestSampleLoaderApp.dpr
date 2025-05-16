program TestSampleLoaderApp;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  EncodingTestSampleLoader in 'EncodingTestSampleLoader.pas',
  TestEncodingTestSampleLoader in 'TestEncodingTestSampleLoader.pas';

begin
  try
    Writeln('编码测试样本批量加载功能测试程序');
    Writeln('========================================');
    
    var Tests := TEncodingTestSampleLoaderTests.Create;
    try
      Tests.RunAllTests;
    finally
      Tests.Free;
    end;
    
    Writeln('========================================');
    Writeln('按任意键退出...');
    Readln;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Readln;
    end;
  end;
end.
