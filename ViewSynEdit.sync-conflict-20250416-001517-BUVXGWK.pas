unit ViewSynEdit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  System.IOUtils, System.Generics.Collections, System.Math, System.StrUtils;

type
  TSynEditForm = class(TForm)
    Memo: TMemo;
    Panel1: TPanel;
    lblFileName: TLabel;
    lblEncoding: TLabel;
    lblBOM: TLabel;
    procedure FormCreate(Sender: TObject);
  private
    procedure ApplyHighlighter(const FileName: string);
  public
    procedure LoadFile(const FileName: string; Encoding: TEncoding);
    procedure SetFileInfo(const FileName, DetectedEncoding: string; HasBOM: Boolean);
  end;

var
  SynEditForm: TSynEditForm;

implementation

{$R *.dfm}

procedure TSynEditForm.FormCreate(Sender: TObject);
begin
  // 设置Memo的属性
  Memo.Font.Name := 'Consolas';
  Memo.Font.Size := 10;
  Memo.ScrollBars := ssBoth;
  Memo.WordWrap := False;
  Memo.ReadOnly := True;
end;

procedure TSynEditForm.ApplyHighlighter(const FileName: string);
begin
  // TMemo不支持语法高亮
end;

procedure TSynEditForm.LoadFile(const FileName: string; Encoding: TEncoding);
var
  FileStream: TFileStream;
  Buffer: TBytes;
  Size: Integer;
begin
  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    Size := FileStream.Size;
    SetLength(Buffer, Size);
    FileStream.ReadBuffer(Buffer[0], Size);
    
    // 使用指定的编码读取文件内容
    Memo.Text := Encoding.GetString(Buffer);
  finally
    FileStream.Free;
  end;
end;

procedure TSynEditForm.SetFileInfo(const FileName, DetectedEncoding: string; HasBOM: Boolean);
begin
  lblFileName.Caption := Format('文件: %s', [ExtractFileName(FileName)]);
  lblEncoding.Caption := Format('编码: %s', [DetectedEncoding]);
  lblBOM.Caption := Format('BOM: %s', [BoolToStr(HasBOM, True)]);
end;

end. 