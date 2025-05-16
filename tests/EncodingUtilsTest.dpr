program EncodingUtilsTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  UtilsEncodingConstants in 'UtilsEncodingConstants.pas',
  UtilsEncodingTypes in 'UtilsEncodingTypes.pas',
  UtilsEncodingDetect2 in 'UtilsEncodingDetect2.pas',
  UtilsEncodingSpecialChars in 'UtilsEncodingSpecialChars.pas',
  EncodingRoundTripValidator in 'EncodingRoundTripValidator.pas',
  UTF8BOMConverter_Advanced in 'UTF8BOMConverter_Advanced.pas',
  TestUTF8BOMConverter in 'TestUTF8BOMConverter.pas';

begin
  try
    RunTestUTF8BOMConverter;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end. 