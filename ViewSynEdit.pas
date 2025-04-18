unit ViewSynEdit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.IOUtils;

type
  TSynEditForm = class(TForm)
    Memo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FFileName: string;
    FFileEncoding: TEncoding;
    procedure SetFileInfo(const FileName: string);
  public
    procedure LoadFile(const FileName: string);
  end;

var
  SynEditForm: TSynEditForm;

implementation

{$R *.dfm}

procedure TSynEditForm.FormCreate(Sender: TObject);
begin
  Width := 800;
  Height := 600;
  Position := poScreenCenter;
  Caption := '文件查看器';

  // 创建并设置Memo
  Memo := TMemo.Create(Self);
  Memo.Parent := Self;
  Memo.Align := alClient;
  Memo.ScrollBars := ssBoth;
  Memo.ReadOnly := True;
  Memo.Font.Name := 'Consolas';
  Memo.Font.Size := 10;
  Memo.WordWrap := False;
  
  KeyPreview := True;
end;

procedure TSynEditForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // ESC关闭窗口
  if Key = VK_ESCAPE then
    Close;
end;

procedure TSynEditForm.LoadFile(const FileName: string);
begin
  if not FileExists(FileName) then
    raise Exception.CreateFmt('文件不存在: %s', [FileName]);

  try
    FFileName := FileName;
    Memo.Lines.LoadFromFile(FileName);
    SetFileInfo(FileName);
  except
    on E: Exception do
      raise Exception.CreateFmt('无法加载文件 %s: %s', [FileName, E.Message]);
  end;
end;

procedure TSynEditForm.SetFileInfo(const FileName: string);
var
  FileSize: Int64;
  FileExt: string;
begin
  try
    FileExt := ExtractFileExt(FileName);
    FileSize := TFile.GetSize(FileName);
    
    Caption := Format('文件查看器 - %s (%s, %.2f KB)',
      [ExtractFileName(FileName), FileExt, FileSize / 1024]);
  except
    // 忽略错误
    Caption := Format('文件查看器 - %s', [ExtractFileName(FileName)]);
  end;
end;

end.
