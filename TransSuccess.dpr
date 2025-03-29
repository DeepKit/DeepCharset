program TransSuccess;

uses
  Vcl.Forms,
  ViewMainCode in 'ViewMainCode.pas' {Form1},
  UtilsUTF8 in 'UtilsUTF8.pas',
  UtilsTypes in 'UtilsTypes.pas',
  ModelLanguage in 'ModelLanguage.pas',
  HelperLanguage in 'HelperLanguage.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  
  // 初始化语言管理器
  TForm1.Initialize;
  
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
