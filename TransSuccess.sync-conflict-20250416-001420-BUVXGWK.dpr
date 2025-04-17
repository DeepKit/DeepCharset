program TransSuccess;

{$R *.res}

uses
  Vcl.Forms,
  System.SysUtils,
  ViewMainCode in 'ViewMainCode.pas' {MainForm},
  ModelEncoding in 'ModelEncoding.pas',
  UtilsTypes in 'UtilsTypes.pas',
  ControllerEncoding in 'ControllerEncoding.pas',
  HelperFiles in 'HelperFiles.pas',
  HelperUI in 'HelperUI.pas',
  ViewMemo in 'ViewMemo.pas' {MemoForm},
  ModelConfig in 'ModelConfig.pas',
  UtilsUTF8 in 'UtilsUTF8.pas',
  UtilsICU in 'UtilsICU.pas',
  HelperLanguage in 'HelperLanguage.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'TransSuccess - 高级编码转换工具';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
