unit ViewMainCode;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids;

type
  TForm1 = class(TForm)
    StringGrid1: TStringGrid;
    procedure btnShowContentClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.btnShowContentClick(Sender: TObject);
begin
  ShowMessage('Simplified version');
end;

end.
