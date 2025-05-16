program TestEncodingIntegrationMain;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  UtilsEncodingTypes in 'UtilsEncodingTypes.pas',
  UtilsEncodingBOM_Improved in 'UtilsEncodingBOM_Improved.pas',
  UtilsEncodingUTF8Detector_Improved in 'UtilsEncodingUTF8Detector_Improved.pas',
  ChineseEncodingDetector_Improved in 'ChineseEncodingDetector_Improved.pas',
  UTF8BOMConverter_Improved in 'UTF8BOMConverter_Improved.pas',
  EncodingConverter_Improved in 'EncodingConverter_Improved.pas',
  TestEncodingIntegration in 'TestEncodingIntegration.pas';

var
  TestResult: Boolean;

begin
  try
    WriteLn('编码集成测试程序');
    WriteLn('----------------------------------------');
    
    // 运行集成测试
    TestResult := TEncodingIntegrationTest.RunIntegrationTests;
    
    if TestResult then
      WriteLn('所有集成测试通过!')
    else
      WriteLn('集成测试失败!');
    
    WriteLn('按任意键退出...');
    ReadLn;
  except
    on E: Exception do
    begin
      WriteLn(E.ClassName, ': ', E.Message);
      ReadLn;
    end;
  end;
end.
