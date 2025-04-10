unit SimpleView;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.IOUtils;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  ShowMessage('Hello, World!');
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Caption := 'Simple Delphi App';
  Memo1.Lines.Add('Application started at ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
  
  // 测试使用System.IOUtils
  Memo1.Lines.Add('Current Directory: ' + TPath.GetDirectoryName(Application.ExeName));
  
  // 检查System.IOUtils.DirectoryExists是否正常工作
  if System.IOUtils.DirectoryExists(ExtractFilePath(Application.ExeName)) then
    Memo1.Lines.Add('Application directory exists');
end;

end. 