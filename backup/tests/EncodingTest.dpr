program EncodingTest;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  TestRunner in 'TestRunner.pas',
  UtilsEncodingTypes in 'UtilsEncodingTypes.pas',
  UtilsEncodingBase in 'UtilsEncodingBase.pas',
  UtilsEncodingBOM in 'UtilsEncodingBOM.pas',
  UtilsEncodingDetector in 'UtilsEncodingDetector.pas',
  UtilsEncodingConverter in 'UtilsEncodingConverter.pas',
  UtilsEncodingUTF32Converter in 'UtilsEncodingUTF32Converter.pas',
  UtilsEncodingUTF16Converter in 'UtilsEncodingUTF16Converter.pas',
  UtilsEncodingScheduler in 'UtilsEncodingScheduler.pas',
  UtilsBatchEncodingManager in 'UtilsBatchEncodingManager.pas',
  UtilsEncodingAnalyzer in 'UtilsEncodingAnalyzer.pas',
  UtilsEncodingOptimizer in 'UtilsEncodingOptimizer.pas',
  UtilsLogs in 'UtilsLogs.pas',
  TestEncodingBOM in 'TestEncodingBOM.pas',
  TestEncodingDetector in 'TestEncodingDetector.pas',
  TestEncodingJobs in 'TestEncodingJobs.pas',
  TestBatchEncodingManager in 'TestBatchEncodingManager.pas',
  TestUTF32Converter in 'TestUTF32Converter.pas',
  TestUTF16Converter in 'TestUTF16Converter.pas';

begin
  try
    // Test runner implementation is in TestRunner.pas
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end. 