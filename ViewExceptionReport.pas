unit ViewExceptionReport;

{
  异常报告对话框
  用于显示详细的异常信息和调用栈
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls;

type
  TExceptionReportForm = class(TForm)
    PanelTop: TPanel;
    PanelBottom: TPanel;
    PanelCenter: TPanel;
    LabelTitle: TLabel;
    ImageIcon: TImage;
    MemoDetails: TMemo;
    btnClose: TButton;
    btnCopyToClipboard: TButton;
    btnSaveToFile: TButton;
    PageControl1: TPageControl;
    TabSheetException: TTabSheet;
    TabSheetStackTrace: TTabSheet;
    TabSheetSystem: TTabSheet;
    MemoException: TMemo;
    MemoStackTrace: TMemo;
    MemoSystemInfo: TMemo;
    SaveDialog1: TSaveDialog;
    procedure btnCloseClick(Sender: TObject);
    procedure btnCopyToClipboardClick(Sender: TObject);
    procedure btnSaveToFileClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FExceptionMessage: string;
    FStackTrace: string;
    FSystemInfo: string;
    FFullReport: string;
  public
    procedure SetExceptionInfo(const ExceptionMsg, StackTrace, SystemInfo: string);
    class procedure ShowReport(const ExceptionMsg, StackTrace, SystemInfo: string);
  end;

var
  ExceptionReportForm: TExceptionReportForm;

implementation

{$WARN IMPLICIT_STRING_CAST OFF}

uses
  Vcl.Clipbrd, System.IOUtils, UtilsJclException;

{$R *.dfm}

procedure TExceptionReportForm.FormCreate(Sender: TObject);
begin
  // 设置窗体属性
  Caption := '异常报告';
  Position := poScreenCenter;
  BorderStyle := bsDialog;
  Width := 700;
  Height := 500;
  
  // 设置控件
  LabelTitle.Caption := '程序发生了一个未处理的上常';
  LabelTitle.Font.Size := 12;
  LabelTitle.Font.Style := [fsBold];
  
  btnClose.Caption := '关闭';
  btnCopyToClipboard.Caption := '复制到剪贴板';
  btnSaveToFile.Caption := '保存到文件...';
  
  // 设置 PageControl
  TabSheetException.Caption := '上常信息';
  TabSheetStackTrace.Caption := '调用栈';
  TabSheetSystem.Caption := '系统信息';
  
  // 设置 Memo 属性
  MemoException.ReadOnly := True;
  MemoException.ScrollBars := ssVertical;
  MemoException.Font.Name := 'Courier New';
  MemoException.Font.Size := 9;
  
  MemoStackTrace.ReadOnly := True;
  MemoStackTrace.ScrollBars := ssVertical;
  MemoStackTrace.Font.Name := 'Courier New';
  MemoStackTrace.Font.Size := 9;
  
  MemoSystemInfo.ReadOnly := True;
  MemoSystemInfo.ScrollBars := ssVertical;
  MemoSystemInfo.Font.Name := 'Courier New';
  MemoSystemInfo.Font.Size := 9;
  
  // 设置保存对话框
  SaveDialog1.Filter := '文本文件 (*.txt)|*.txt|日志文件 (*.log)|*.log|所有文件 (*.*)|*.*';
  SaveDialog1.DefaultExt := 'txt';
  {$WARN IMPLICIT_STRING_CAST OFF}
  SaveDialog1.FileName := 'ExceptionReport_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.txt';
  {$WARN IMPLICIT_STRING_CAST ON}
end;

procedure TExceptionReportForm.SetExceptionInfo(const ExceptionMsg, StackTrace, SystemInfo: string);
begin
  FExceptionMessage := ExceptionMsg;
  FStackTrace := StackTrace;
  FSystemInfo := SystemInfo;
  
  // 组合完整报告
  {$WARN IMPLICIT_STRING_CAST OFF}
  FFullReport := '========================================' + sLineBreak +
                 '上常报告' + sLineBreak +
                 '========================================' + sLineBreak +
                 '时间: ' + DateTimeToStr(Now) + sLineBreak +
                 sLineBreak +
                 ExceptionMsg + sLineBreak +
                 sLineBreak +
                 StackTrace + sLineBreak +
                 sLineBreak +
                 SystemInfo + sLineBreak +
                 '========================================';
  {$WARN IMPLICIT_STRING_CAST ON}
  
  // 设置各个 Memo 的内容
  MemoException.Lines.Text := ExceptionMsg;
  MemoStackTrace.Lines.Text := StackTrace;
  MemoSystemInfo.Lines.Text := SystemInfo;
  MemoDetails.Lines.Text := FFullReport;
end;

procedure TExceptionReportForm.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TExceptionReportForm.btnCopyToClipboardClick(Sender: TObject);
begin
  try
    Clipboard.AsText := FFullReport;
    {$WARN IMPLICIT_STRING_CAST OFF}
    ShowMessage('上常报告已复制到剪贴板');
    {$WARN IMPLICIT_STRING_CAST ON}
  except
    on E: Exception do
    begin
      {$WARN IMPLICIT_STRING_CAST OFF}
      ShowMessage('复制失败: ' + E.Message);
      {$WARN IMPLICIT_STRING_CAST ON}
    end;
  end;
end;

procedure TExceptionReportForm.btnSaveToFileClick(Sender: TObject);
begin
  if SaveDialog1.Execute then
  begin
    try
      TFile.WriteAllText(SaveDialog1.FileName, FFullReport, TEncoding.UTF8);
      {$WARN IMPLICIT_STRING_CAST OFF}
      ShowMessage('上常报告已保存到: ' + SaveDialog1.FileName);
      {$WARN IMPLICIT_STRING_CAST ON}
    except
      on E: Exception do
      begin
        {$WARN IMPLICIT_STRING_CAST OFF}
        ShowMessage('保存失败: ' + E.Message);
        {$WARN IMPLICIT_STRING_CAST ON}
      end;
    end;
  end;
end;

class procedure TExceptionReportForm.ShowReport(const ExceptionMsg, StackTrace, SystemInfo: string);
var
  Form: TExceptionReportForm;
begin
  Form := TExceptionReportForm.Create(nil);
  try
    Form.SetExceptionInfo(ExceptionMsg, StackTrace, SystemInfo);
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

end.
