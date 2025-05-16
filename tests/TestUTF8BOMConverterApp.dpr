program TestUTF8BOMConverterApp;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  TestUTF8BOMConverter in 'TestUTF8BOMConverter.pas',
  UTF8BOMConverter_Enhanced in 'UTF8BOMConverter_Enhanced.pas',
  UTF8EncodingDetector in 'UTF8EncodingDetector.pas';

var
  Test: TUTFConversionTest;
begin
  try
    // 显示程序标题
    WriteLn('UTF-8 BOM转换器测试程序');
    WriteLn('=======================');
    WriteLn;
    
    // 创建测试类并运行测试
    Test := TUTFConversionTest.Create;
    try
      Test.RunAllTests;
    finally
      Test.Free;
    end;
    
    // 等待用户按键
    WriteLn;
    WriteLn('按任意键退出...');
    ReadLn;
  except
    on E: Exception do
    begin
      WriteLn('测试过程中发生错误：' + E.Message);
      ReadLn;
    end;
  end;
end. 