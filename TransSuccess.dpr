program TransSuccess;

{$R *.res}


uses
  Vcl.Forms,
  System.SysUtils,
  JclBOM,
  JclStrings,
  JclStringConversions,
  JclFileUtils,
  JclStreams,
  ViewMainCode in 'ViewMainCode.pas' {Form1},
  ModelEncoding in 'ModelEncoding.pas',
  UtilsTypes in 'UtilsTypes.pas',
  ControllerEncoding in 'ControllerEncoding.pas',
  HelperFiles in 'HelperFiles.pas',
  HelperUI in 'HelperUI.pas',
  ModelConfig in 'ModelConfig.pas',
  HelperLanguage in 'HelperLanguage.pas',
  ViewSynEdit in 'ViewSynEdit.pas' {SynEditForm},
  ControllerLanguage in 'ControllerLanguage.pas',
  UtilsEncodingTypes in 'UtilsEncodingTypes.pas',
  UtilsEncodingLogger in 'UtilsEncodingLogger.pas',

  UtilsEncodingBOM_Improved in 'UtilsEncodingBOM_Improved.pas',
  UtilsEncodingUTF8Detector_Improved in 'UtilsEncodingUTF8Detector_Improved.pas',
  ChineseEncodingDetector_Improved in 'ChineseEncodingDetector_Improved.pas',
  JapaneseEncodingDetector_Improved in 'JapaneseEncodingDetector_Improved.pas',
  KoreanEncodingDetector_Improved in 'KoreanEncodingDetector_Improved.pas',
  EncodingConverter_Improved in 'EncodingConverter_Improved.pas',
  UTF8BOMConverter_Improved in 'UTF8BOMConverter_Improved.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'TransSuccess - 文件编码转换工具';

  Application.CreateForm(TForm1, Form1);
  // 不需要预先创建SynEditForm，在需要时再创建
  // Application.CreateForm(TSynEditForm, SynEditForm);
  Application.Run;
end.
