unit ViewSynEdit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.IOUtils,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Buttons, Vcl.Menus, System.UITypes, Vcl.Clipbrd;

type
  TSynEditForm = class(TForm)
    Memo: TMemo;
    StatusBar: TStatusBar;
    PanelTop: TPanel;
    LabelFileName: TLabel;
    LabelEncoding: TLabel;
    LabelFileSize: TLabel;
    PanelButtons: TPanel;
    btnClose: TButton;
    btnCopy: TButton;
    btnWordWrap: TSpeedButton;
    PopupMenu: TPopupMenu;
    MenuItemCopy: TMenuItem;
    MenuItemSelectAll: TMenuItem;
    N1: TMenuItem;
    MenuItemWordWrap: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnCloseClick(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure btnWordWrapClick(Sender: TObject);
    procedure MenuItemCopyClick(Sender: TObject);
    procedure MenuItemSelectAllClick(Sender: TObject);
    procedure MenuItemWordWrapClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure MemoChange(Sender: TObject);
  private
    FFileName: string;
    FFileEncoding: TEncoding;
    FEncodingName: string;
    FHasBOM: Boolean;
    FLineCount: Integer;
    FCharCount: Integer;

    procedure SetFileInfoBasic(const FileName: string);
    procedure UpdateStatusBar;
    procedure UpdateEncodingInfo(const EncodingName: string; HasBOM: Boolean);
  public
    procedure LoadFile(const FileName: string);
    procedure LoadFileWithEncoding(const FileName: string; Encoding: TEncoding;
      const DetectedEncoding: string; HasBOM: Boolean);
    procedure SetFileInfo(const FileName, EncodingName: string; HasBOM: Boolean);
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

  // 创建顶部面板
  PanelTop := TPanel.Create(Self);
  PanelTop.Parent := Self;
  PanelTop.Align := alTop;
  PanelTop.Height := 60;
  PanelTop.BevelOuter := bvNone;
  PanelTop.ParentBackground := False;
  PanelTop.Color := clBtnFace;

  // 创建文件信息标签
  LabelFileName := TLabel.Create(Self);
  LabelFileName.Parent := PanelTop;
  LabelFileName.Left := 10;
  LabelFileName.Top := 10;
  LabelFileName.AutoSize := True;
  LabelFileName.Caption := '文件名: ';
  LabelFileName.Font.Style := [fsBold];

  LabelEncoding := TLabel.Create(Self);
  LabelEncoding.Parent := PanelTop;
  LabelEncoding.Left := 10;
  LabelEncoding.Top := 30;
  LabelEncoding.AutoSize := True;
  LabelEncoding.Caption := '编码: ';

  LabelFileSize := TLabel.Create(Self);
  LabelFileSize.Parent := PanelTop;
  LabelFileSize.Left := 400;
  LabelFileSize.Top := 10;
  LabelFileSize.AutoSize := True;
  LabelFileSize.Caption := '文件大小: ';

  // 创建按钮面板
  PanelButtons := TPanel.Create(Self);
  PanelButtons.Parent := Self;
  PanelButtons.Align := alBottom;
  PanelButtons.Height := 40;
  PanelButtons.BevelOuter := bvNone;
  PanelButtons.ParentBackground := False;
  PanelButtons.Color := clBtnFace;

  // 创建按钮
  btnClose := TButton.Create(Self);
  btnClose.Parent := PanelButtons;
  btnClose.Caption := '关闭';
  btnClose.Width := 80;
  btnClose.Height := 30;
  btnClose.Left := 700;
  btnClose.Top := 5;
  btnClose.Anchors := [akRight, akTop];
  btnClose.OnClick := btnCloseClick;

  btnCopy := TButton.Create(Self);
  btnCopy.Parent := PanelButtons;
  btnCopy.Caption := '复制';
  btnCopy.Width := 80;
  btnCopy.Height := 30;
  btnCopy.Left := 610;
  btnCopy.Top := 5;
  btnCopy.Anchors := [akRight, akTop];
  btnCopy.OnClick := btnCopyClick;

  btnWordWrap := TSpeedButton.Create(Self);
  btnWordWrap.Parent := PanelButtons;
  btnWordWrap.Caption := '自动换行';
  btnWordWrap.Width := 100;
  btnWordWrap.Height := 30;
  btnWordWrap.Left := 500;
  btnWordWrap.Top := 5;
  btnWordWrap.GroupIndex := 1;
  btnWordWrap.AllowAllUp := True;
  btnWordWrap.OnClick := btnWordWrapClick;

  // 创建状态栏
  StatusBar := TStatusBar.Create(Self);
  StatusBar.Parent := Self;
  StatusBar.SimplePanel := False;
  StatusBar.Panels.Add.Width := 200;  // 行数
  StatusBar.Panels.Add.Width := 200;  // 字符数
  StatusBar.Panels.Add.Width := 200;  // 光标位置

  // 创建并设置Memo
  Memo := TMemo.Create(Self);
  Memo.Parent := Self;
  Memo.Align := alClient;
  Memo.ScrollBars := ssBoth;
  Memo.ReadOnly := True;
  Memo.Font.Name := 'Consolas';
  Memo.Font.Size := 10;
  Memo.WordWrap := False;
  Memo.PopupMenu := PopupMenu;
  Memo.OnChange := MemoChange;

  // 创建弹出菜单
  PopupMenu := TPopupMenu.Create(Self);

  MenuItemCopy := TMenuItem.Create(Self);
  MenuItemCopy.Caption := '复制';
  MenuItemCopy.OnClick := MenuItemCopyClick;
  PopupMenu.Items.Add(MenuItemCopy);

  MenuItemSelectAll := TMenuItem.Create(Self);
  MenuItemSelectAll.Caption := '全选';
  MenuItemSelectAll.OnClick := MenuItemSelectAllClick;
  PopupMenu.Items.Add(MenuItemSelectAll);

  N1 := TMenuItem.Create(Self);
  N1.Caption := '-';
  PopupMenu.Items.Add(N1);

  MenuItemWordWrap := TMenuItem.Create(Self);
  MenuItemWordWrap.Caption := '自动换行';
  MenuItemWordWrap.OnClick := MenuItemWordWrapClick;
  PopupMenu.Items.Add(MenuItemWordWrap);

  KeyPreview := True;

  // 初始化变量
  FLineCount := 0;
  FCharCount := 0;
  FEncodingName := '';
  FHasBOM := False;

  // 更新状态栏
  UpdateStatusBar;
end;

procedure TSynEditForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // ESC关闭窗口
  if Key = VK_ESCAPE then
    Close;

  // Ctrl+A 全选
  if (Key = Ord('A')) and (ssCtrl in Shift) then
  begin
    Memo.SelectAll;
    Key := 0;
  end;

  // Ctrl+C 复制
  if (Key = Ord('C')) and (ssCtrl in Shift) then
  begin
    if Memo.SelLength > 0 then
      Clipboard.AsText := Memo.SelText;
    Key := 0;
  end;
end;

procedure TSynEditForm.FormResize(Sender: TObject);
begin
  // 调整按钮位置
  btnClose.Left := PanelButtons.Width - btnClose.Width - 10;
  btnCopy.Left := btnClose.Left - btnCopy.Width - 10;
  btnWordWrap.Left := btnCopy.Left - btnWordWrap.Width - 10;
end;

procedure TSynEditForm.LoadFile(const FileName: string);
begin
  if not FileExists(FileName) then
    raise Exception.CreateFmt('文件不存在: %s', [FileName]);

  try
    FFileName := FileName;
    Memo.Lines.LoadFromFile(FileName);
    SetFileInfoBasic(FileName);

    // 更新行数和字符数
    FLineCount := Memo.Lines.Count;
    FCharCount := Length(Memo.Text);
    UpdateStatusBar;
  except
    on E: Exception do
      raise Exception.CreateFmt('无法加载文件 %s: %s', [FileName, E.Message]);
  end;
end;

procedure TSynEditForm.LoadFileWithEncoding(const FileName: string; Encoding: TEncoding;
  const DetectedEncoding: string; HasBOM: Boolean);
var
  FileStream: TFileStream;
  Buffer: TBytes;
  Content: string;
begin
  if not FileExists(FileName) then
    raise Exception.CreateFmt('文件不存在: %s', [FileName]);

  try
    FFileName := FileName;
    FFileEncoding := Encoding;
    FEncodingName := DetectedEncoding;
    FHasBOM := HasBOM;

    // 使用指定的编码读取文件
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(Buffer, FileStream.Size);
      if FileStream.Size > 0 then
        FileStream.ReadBuffer(Buffer[0], FileStream.Size);

      // 转换为字符串
      if Encoding = nil then
        Content := TEncoding.Default.GetString(Buffer)
      else
        Content := Encoding.GetString(Buffer);

      // 设置到Memo
      Memo.Text := Content;
    finally
      FileStream.Free;
    end;

    // 设置文件信息
    SetFileInfo(FileName, DetectedEncoding, HasBOM);

    // 更新行数和字符数
    FLineCount := Memo.Lines.Count;
    FCharCount := Length(Memo.Text);
    UpdateStatusBar;
  except
    on E: Exception do
      raise Exception.CreateFmt('无法加载文件 %s: %s', [FileName, E.Message]);
  end;
end;

procedure TSynEditForm.MemoChange(Sender: TObject);
begin
  // 更新行数和字符数
  FLineCount := Memo.Lines.Count;
  FCharCount := Length(Memo.Text);
  UpdateStatusBar;
end;

procedure TSynEditForm.MenuItemCopyClick(Sender: TObject);
begin
  btnCopyClick(Sender);
end;

procedure TSynEditForm.MenuItemSelectAllClick(Sender: TObject);
begin
  Memo.SelectAll;
end;

procedure TSynEditForm.MenuItemWordWrapClick(Sender: TObject);
begin
  btnWordWrapClick(Sender);
  MenuItemWordWrap.Checked := Memo.WordWrap;
end;

procedure TSynEditForm.SetFileInfoBasic(const FileName: string);
var
  FileSize: Int64;
  FileExt: string;
begin
  try
    FileExt := ExtractFileExt(FileName);
    FileSize := TFile.GetSize(FileName);

    // 更新窗体标题
    Caption := Format('文件查看器 - %s', [ExtractFileName(FileName)]);

    // 更新文件信息标签
    LabelFileName.Caption := Format('文件名: %s', [ExtractFileName(FileName)]);
    LabelFileSize.Caption := Format('文件大小: %.2f KB (%d 字节)', [FileSize / 1024, FileSize]);

    // 更新编码信息
    UpdateEncodingInfo('未知', False);
  except
    // 忽略错误
    Caption := Format('文件查看器 - %s', [ExtractFileName(FileName)]);
    LabelFileName.Caption := Format('文件名: %s', [ExtractFileName(FileName)]);
    LabelFileSize.Caption := '文件大小: 未知';
    UpdateEncodingInfo('未知', False);
  end;
end;

procedure TSynEditForm.SetFileInfo(const FileName, EncodingName: string; HasBOM: Boolean);
var
  FileSize: Int64;
  FileExt: string;
begin
  try
    FileExt := ExtractFileExt(FileName);
    FileSize := TFile.GetSize(FileName);

    // 更新窗体标题
    Caption := Format('文件查看器 - %s', [ExtractFileName(FileName)]);

    // 更新文件信息标签
    LabelFileName.Caption := Format('文件名: %s', [ExtractFileName(FileName)]);
    LabelFileSize.Caption := Format('文件大小: %.2f KB (%d 字节)', [FileSize / 1024, FileSize]);

    // 更新编码信息
    UpdateEncodingInfo(EncodingName, HasBOM);
  except
    // 忽略错误
    Caption := Format('文件查看器 - %s', [ExtractFileName(FileName)]);
    LabelFileName.Caption := Format('文件名: %s', [ExtractFileName(FileName)]);
    LabelFileSize.Caption := '文件大小: 未知';
    UpdateEncodingInfo(EncodingName, HasBOM);
  end;
end;

procedure TSynEditForm.UpdateEncodingInfo(const EncodingName: string; HasBOM: Boolean);
begin
  FEncodingName := EncodingName;
  FHasBOM := HasBOM;

  if HasBOM then
    LabelEncoding.Caption := Format('编码: %s (带BOM)', [EncodingName])
  else
    LabelEncoding.Caption := Format('编码: %s', [EncodingName]);
end;

procedure TSynEditForm.UpdateStatusBar;
begin
  // 更新状态栏信息
  StatusBar.Panels[0].Text := Format('行数: %d', [FLineCount]);
  StatusBar.Panels[1].Text := Format('字符数: %d', [FCharCount]);

  // 更新光标位置
  if Memo.SelStart >= 0 then
  begin
    var Line, Col: Integer;
    Line := SendMessage(Memo.Handle, EM_LINEFROMCHAR, Memo.SelStart, 0) + 1;
    Col := Memo.SelStart - SendMessage(Memo.Handle, EM_LINEINDEX, Line - 1, 0) + 1;
    StatusBar.Panels[2].Text := Format('行: %d, 列: %d', [Line, Col]);
  end
  else
    StatusBar.Panels[2].Text := '';
end;

procedure TSynEditForm.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TSynEditForm.btnCopyClick(Sender: TObject);
begin
  if Memo.SelLength > 0 then
    Clipboard.AsText := Memo.SelText
  else
    Clipboard.AsText := Memo.Text;
end;

procedure TSynEditForm.btnWordWrapClick(Sender: TObject);
begin
  Memo.WordWrap := not Memo.WordWrap;
  btnWordWrap.Down := Memo.WordWrap;

  if Memo.WordWrap then
  begin
    Memo.ScrollBars := ssVertical;
    btnWordWrap.Caption := '关闭换行';
  end
  else
  begin
    Memo.ScrollBars := ssBoth;
    btnWordWrap.Caption := '自动换行';
  end;

  // 更新菜单项状态
  if Assigned(MenuItemWordWrap) then
    MenuItemWordWrap.Checked := Memo.WordWrap;
end;

end.
