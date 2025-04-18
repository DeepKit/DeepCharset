unit FormEncodingConversionExample;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Buttons,
  System.IOUtils, System.Types, UtilsEncodingDetect2, ControllerEncodingEnhanced;

type
  TfrmEncodingConversion = class(TForm)
    pnlTop: TPanel;
    pnlCenter: TPanel;
    pnlBottom: TPanel;
    btnSelectFiles: TButton;
    lblFiles: TLabel;
    lstFiles: TListBox;
    mmoLog: TMemo;
    cboTargetEncoding: TComboBox;
    lblTargetEncoding: TLabel;
    chkAddBOM: TCheckBox;
    btnDetectEncodings: TButton;
    btnConvertFiles: TButton;
    dlgOpen: TOpenDialog;
    ProgressBar: TProgressBar;
    chkCreateBackup: TCheckBox;
    edtBackupExt: TEdit;
    lblBackupExt: TLabel;
    btnClear: TButton;
    chkForceConversion: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSelectFilesClick(Sender: TObject);
    procedure btnDetectEncodingsClick(Sender: TObject);
    procedure btnConvertFilesClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
  private
    FEncodingController: TEncodingControllerEx;
    FSelectedFiles: TArray<string>;
    
    procedure LogMessage(const Msg: string);
    procedure UpdateProgress(const FileName: string; Current, Total: Integer);
    procedure PopulateEncodingComboBox;
    function GetSelectedFiles: TArray<string>;
    function GetConversionOptions: TConversionOptions;
  public
    { Public declarations }
  end;

var
  frmEncodingConversion: TfrmEncodingConversion;

implementation

{$R *.dfm}

procedure TfrmEncodingConversion.FormCreate(Sender: TObject);
begin
  FEncodingController := TEncodingControllerEx.Create(LogMessage);
  PopulateEncodingComboBox;
  
  // 默认选择UTF-8
  cboTargetEncoding.ItemIndex := 0;
  
  // 默认备份设置
  chkCreateBackup.Checked := True;
  edtBackupExt.Text := '.bak';
  
  // 清空记录
  mmoLog.Clear;
  LogMessage('准备就绪。请选择文件进行编码检测或转换。');
end;

procedure TfrmEncodingConversion.FormDestroy(Sender: TObject);
begin
  FEncodingController.Free;
end;

procedure TfrmEncodingConversion.PopulateEncodingComboBox;
var
  Encodings: TArray<string>;
  I: Integer;
begin
  cboTargetEncoding.Items.Clear;
  
  Encodings := FEncodingController.GetSupportedEncodings;
  for I := 0 to High(Encodings) do
    cboTargetEncoding.Items.Add(Encodings[I]);
end;

procedure TfrmEncodingConversion.LogMessage(const Msg: string);
begin
  mmoLog.Lines.Add(Format('[%s] %s', [FormatDateTime('hh:nn:ss', Now), Msg]));
  // 滚动到最后
  SendMessage(mmoLog.Handle, WM_VSCROLL, SB_BOTTOM, 0);
  Application.ProcessMessages;
end;

procedure TfrmEncodingConversion.UpdateProgress(const FileName: string; Current, Total: Integer);
begin
  ProgressBar.Min := 0;
  ProgressBar.Max := Total;
  ProgressBar.Position := Current;
  lblFiles.Caption := Format('处理文件 %d/%d: %s', [Current, Total, ExtractFileName(FileName)]);
  Application.ProcessMessages;
end;

function TfrmEncodingConversion.GetSelectedFiles: TArray<string>;
var
  I: Integer;
begin
  SetLength(Result, lstFiles.Items.Count);
  for I := 0 to lstFiles.Items.Count - 1 do
    Result[I] := lstFiles.Items[I];
end;

function TfrmEncodingConversion.GetConversionOptions: TConversionOptions;
begin
  Result.CreateBackup := chkCreateBackup.Checked;
  Result.BackupExtension := edtBackupExt.Text;
  Result.OverwriteTarget := True; // 总是覆盖目标文件
  Result.ForceConversion := chkForceConversion.Checked;
end;

procedure TfrmEncodingConversion.btnSelectFilesClick(Sender: TObject);
var
  I: Integer;
begin
  if dlgOpen.Execute then
  begin
    lstFiles.Items.Clear;
    for I := 0 to dlgOpen.Files.Count - 1 do
      lstFiles.Items.Add(dlgOpen.Files[I]);
      
    LogMessage(Format('已选择 %d 个文件', [dlgOpen.Files.Count]));
  end;
end;

procedure TfrmEncodingConversion.btnClearClick(Sender: TObject);
begin
  lstFiles.Items.Clear;
  mmoLog.Clear;
  LogMessage('已清空文件列表和日志。');
end;

procedure TfrmEncodingConversion.btnDetectEncodingsClick(Sender: TObject);
var
  Files: TArray<string>;
  I: Integer;
  DetectResult: TEncodingDetectResult;
  Status: string;
begin
  Files := GetSelectedFiles;
  
  if Length(Files) = 0 then
  begin
    ShowMessage('请先选择要检测的文件');
    Exit;
  end;
  
  LogMessage('开始检测文件编码...');
  
  for I := 0 to High(Files) do
  begin
    UpdateProgress(Files[I], I + 1, Length(Files));
    
    DetectResult := FEncodingController.DetectFileEncoding(Files[I]);
    
    // 格式化检测结果
    Status := Format('文件: %s - 编码: %s (置信度: %.2f%%)', 
      [ExtractFileName(Files[I]), DetectResult.EncodingName, DetectResult.Confidence * 100]);
      
    if DetectResult.HasBOM then
      Status := Status + ' [有BOM]';
      
    if DetectResult.LanguageHint <> '' then
      Status := Status + Format(' [语言提示: %s]', [DetectResult.LanguageHint]);
      
    LogMessage(Status);
  end;
  
  LogMessage('编码检测完成。');
  ProgressBar.Position := 0;
  lblFiles.Caption := Format('已检测 %d 个文件的编码', [Length(Files)]);
end;

procedure TfrmEncodingConversion.btnConvertFilesClick(Sender: TObject);
var
  Files: TArray<string>;
  TargetEncoding: string;
  AddBOM: Boolean;
  Options: TConversionOptions;
  SuccessCount: Integer;
begin
  Files := GetSelectedFiles;
  
  if Length(Files) = 0 then
  begin
    ShowMessage('请先选择要转换的文件');
    Exit;
  end;
  
  if cboTargetEncoding.ItemIndex < 0 then
  begin
    ShowMessage('请选择目标编码');
    Exit;
  end;
  
  TargetEncoding := cboTargetEncoding.Items[cboTargetEncoding.ItemIndex];
  AddBOM := chkAddBOM.Checked;
  Options := GetConversionOptions;
  
  LogMessage(Format('开始转换 %d 个文件到 %s 编码%s...', 
    [Length(Files), TargetEncoding, IfThen(AddBOM, ' (添加BOM)', '')]));
    
  // 执行批量转换，传入进度回调  
  SuccessCount := FEncodingController.ConvertFiles(
    Files, TargetEncoding, AddBOM, Options, UpdateProgress);
    
  // 显示总结
  LogMessage(Format('转换完成: 总计 %d 个文件, 成功 %d 个', [Length(Files), SuccessCount]));
  
  // 重置进度条
  ProgressBar.Position := 0;
  lblFiles.Caption := Format('已完成 %d/%d 个文件的转换', [SuccessCount, Length(Files)]);
end;

end. 