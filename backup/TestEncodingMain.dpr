program TestEncodingMain;

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
  TestEncodingDetection in 'TestEncodingDetection.pas';

var
  TestResult: Boolean;
  FileName: string;

begin
  try
    WriteLn('编码检测和转换测试程序');
    WriteLn('----------------------------------------');
    
    if ParamCount = 0 then
    begin
      // 运行所有测试
      TestResult := TEncodingDetectionTest.RunAllTests;
      
      if TestResult then
        WriteLn('所有测试通过!')
      else
        WriteLn('测试失败!');
    end
    else
    begin
      // 检测指定文件的编码
      FileName := ParamStr(1);
      
      if FileExists(FileName) then
      begin
        var EncodingName := TEncodingDetectionTest.TestFileEncodingDetection(FileName);
        WriteLn(Format('文件: %s', [FileName]));
        WriteLn(Format('检测到的编码: %s', [EncodingName]));
        
        // 检测BOM
        var BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromFile(FileName);
        WriteLn(Format('BOM类型: %d', [Ord(BOMResult.BOMType)]));
        
        // 检测UTF-8
        var UTF8Result := TUTF8EncodingDetector_Improved.DetectFile(FileName);
        WriteLn(Format('UTF-8检测: IsUTF8=%s, 置信度=%.2f, 中文字符数=%d',
          [BoolToStr(UTF8Result.IsUTF8, True), UTF8Result.Confidence, UTF8Result.ChineseCharCount]));
        
        // 检测中文编码
        var ChineseResult := TChineseEncodingDetector_Improved.DetectFile(FileName);
        WriteLn(Format('中文编码检测: 编码=%s, 置信度=%.2f',
          [ChineseResult.Encoding, ChineseResult.Confidence]));
        WriteLn(Format('  GBK置信度=%.2f, GB18030置信度=%.2f, Big5置信度=%.2f, GB2312置信度=%.2f',
          [ChineseResult.GBKConfidence, ChineseResult.GB18030Confidence,
           ChineseResult.Big5Confidence, ChineseResult.GB2312Confidence]));
      end
      else
        WriteLn(Format('文件不存在: %s', [FileName]));
    end;
    
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
