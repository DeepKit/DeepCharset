unit SynEditWrapper;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  SynEdit;

type
  TSynEditHelper = class(TSynEdit)
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

constructor TSynEditHelper.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // 在这里添加任何需要的初始化代码
end;

end. 