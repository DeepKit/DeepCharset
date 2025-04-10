unit ViewSynEdit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  System.IOUtils, System.Generics.Collections, System.Math, System.StrUtils,
  SynEdit, SynEditHighlighter, SynHighlighterPas, SynHighlighterCpp, SynHighlighterCss, SynHighlighterJava,
  SynHighlighterJScript, SynHighlighterHTML, SynHighlighterXML, SynHighlighterSQL,
  SynHighlighterPython, SynHighlighterPHP, SynHighlighterIni, SynHighlighterPerl,
  SynHighlighterVB, SynHighlighterAsm, SynHighlighterRuby,
  SynHighlighterJSON, SynHighlighterBat, SynEditCodeFolding,
  JclEncodingUtils;

type
  TSynEditForm = class(TForm)
    SynEdit: TSynEdit;
    Panel1: TPanel;
    lblFileName: TLabel;
    lblEncoding: TLabel;
    lblBOM: TLabel;
    SynPasSyn1: TSynPasSyn;
    SynCppSyn1: TSynCppSyn;
    SynCSSyn1: TSynCssSyn;
    SynJavaSyn1: TSynJavaSyn;
    SynJScriptSyn1: TSynJScriptSyn;
    SynHTMLSyn1: TSynHTMLSyn;
    SynXMLSyn1: TSynXMLSyn;
    SynSQLSyn1: TSynSQLSyn;
    SynPythonSyn1: TSynPythonSyn;
    SynPHPSyn1: TSynPHPSyn;
    SynIniSyn1: TSynIniSyn;
    SynPerlSyn1: TSynPerlSyn;
    SynVBSyn1: TSynVBSyn;
    SynAsmSyn1: TSynAsmSyn;
    SynRubySyn1: TSynRubySyn;
    SynJSONSyn1: TSynJSONSyn;
    SynBatSyn1: TSynBatSyn;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    procedure ApplyHighlighter(const FileName: string);
    procedure LogMessage(const Msg: string);
  public
    procedure LoadFile(const FileName: string; Encoding: TEncoding = nil);
    procedure SetFileInfo(const FileName, DetectedEncoding: string; HasBOM: Boolean);
  end;

var
  SynEditForm: TSynEditForm;

implementation

{$R *.dfm}

procedure TSynEditForm.FormCreate(Sender: TObject);
begin
  // 设置窗体属性
  Position := poDefaultPosOnly; // 使窗体位置由代码控制
  FormStyle := fsStayOnTop;     // 保持在其他窗体之上
  KeyPreview := True;           // 允许窗体接收所有键盘事件
  
  // 设置SynEdit的属性
  SynEdit.Font.Name := 'Consolas';
  SynEdit.Font.Size := 10;
  SynEdit.ScrollBars := ssBoth;
  SynEdit.WordWrap := False;
  SynEdit.ReadOnly := True;
  SynEdit.Gutter.ShowLineNumbers := True;
  SynEdit.UseCodeFolding := True;
  
  // 记录初始化日志
  LogMessage('SynEdit窗体已初始化');
end;

procedure TSynEditForm.FormDestroy(Sender: TObject);
begin
  // 所有组件都由表单自动释放
end;

procedure TSynEditForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // 设置关闭时的行为
  Action := caHide; // 隐藏而非释放，因为我们使用全局变量SynEditForm
end;

procedure TSynEditForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // Esc键关闭窗体
  if Key = VK_ESCAPE then
  begin
    Close;
    Key := 0;
  end
  // Ctrl++/Ctrl+= 增大字体
  else if ((Key = 187) or (Key = 107) or (Key = VK_ADD)) and (ssCtrl in Shift) then
  begin
    SynEdit.Font.Size := SynEdit.Font.Size + 1;
    Key := 0;
  end
  // Ctrl+- 减小字体
  else if ((Key = 189) or (Key = 109) or (Key = VK_SUBTRACT)) and (ssCtrl in Shift) then
  begin
    if SynEdit.Font.Size > 8 then
    begin
      SynEdit.Font.Size := SynEdit.Font.Size - 1;
    end;
    Key := 0;
  end
  // Ctrl+0 恢复默认字体大小
  else if ((Key = Ord('0')) or (Key = VK_NUMPAD0)) and (ssCtrl in Shift) then
  begin
    SynEdit.Font.Size := 10; // 恢复默认大小
    Key := 0;
  end;
end;

procedure TSynEditForm.ApplyHighlighter(const FileName: string);
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(FileName));
  
  // 根据文件扩展名应用适当的语法高亮器
  if (Ext = '.pas') or (Ext = '.dpr') or (Ext = '.dpk') then
  begin
    SynEdit.Highlighter := SynPasSyn1;
  end
  else if (Ext = '.cpp') or (Ext = '.h') or (Ext = '.hpp') or (Ext = '.c') then
  begin
    SynEdit.Highlighter := SynCppSyn1;
  end
  else if (Ext = '.css') then
  begin
    SynEdit.Highlighter := SynCSSyn1;
  end
  else if (Ext = '.java') then
  begin
    SynEdit.Highlighter := SynJavaSyn1;
  end
  else if (Ext = '.js') then
  begin
    SynEdit.Highlighter := SynJScriptSyn1;
  end
  else if (Ext = '.html') or (Ext = '.htm') then
  begin
    SynEdit.Highlighter := SynHTMLSyn1;
  end
  else if (Ext = '.xml') or (Ext = '.xsd') or (Ext = '.xsl') or (Ext = '.xslt') then
  begin
    SynEdit.Highlighter := SynXMLSyn1;
  end
  else if (Ext = '.sql') then
  begin
    SynEdit.Highlighter := SynSQLSyn1;
  end
  else if (Ext = '.py') then
  begin
    SynEdit.Highlighter := SynPythonSyn1;
  end
  else if (Ext = '.php') then
  begin
    SynEdit.Highlighter := SynPHPSyn1;
  end
  else if (Ext = '.ini') or (Ext = '.inf') then
  begin
    SynEdit.Highlighter := SynIniSyn1;
  end
  else if (Ext = '.pl') or (Ext = '.pm') then
  begin
    SynEdit.Highlighter := SynPerlSyn1;
  end
  else if (Ext = '.vb') then
  begin
    SynEdit.Highlighter := SynVBSyn1;
  end
  else if (Ext = '.asm') then
  begin
    SynEdit.Highlighter := SynAsmSyn1;
  end
  else if (Ext = '.rb') then
  begin
    SynEdit.Highlighter := SynRubySyn1;
  end
  else if (Ext = '.json') then
  begin
    SynEdit.Highlighter := SynJSONSyn1;
  end
  else if (Ext = '.bat') or (Ext = '.cmd') then
  begin
    SynEdit.Highlighter := SynBatSyn1;
  end
  else
  begin
    SynEdit.Highlighter := nil; // 未知文件类型，不使用高亮
  end;
  
  // 确保立即重绘
  SynEdit.Invalidate;
end;

procedure TSynEditForm.LogMessage(const Msg: string);
begin
  // 使用更安全的方式记录日志，避免调用OutputDebugString可能引起的问题
  {$IFDEF DEBUG}
  // 仅在调试模式下输出到控制台
  WriteLn('[SynEdit] ' + Msg);
  {$ENDIF}
end;

procedure TSynEditForm.LoadFile(const FileName: string; Encoding: TEncoding = nil);
var
  DetectedEncoding: string;
  HasBOM: Boolean;
begin
  try
    // 直接使用SynEdit的Lines加载文件，简单可靠
    if Assigned(Encoding) then
      SynEdit.Lines.LoadFromFile(FileName, Encoding)
    else
      SynEdit.Lines.LoadFromFile(FileName);
    
    // 设置窗体标题
    Caption := ExtractFileName(FileName);
    
    // 首先清除现有高亮器
    SynEdit.Highlighter := nil;
    
    // 应用语法高亮
    ApplyHighlighter(FileName);
    
    // 检测文件编码
    DetectedEncoding := JclEncodingUtils.DetectFileEncoding(FileName);
    HasBOM := Pos('BOM', DetectedEncoding) > 0;
    
    // 设置文件信息
    SetFileInfo(FileName, DetectedEncoding, HasBOM);
    
  except
    on E: Exception do
    begin
      SynEdit.Text := '无法打开文件: ' + E.Message;
    end;
  end;
end;

procedure TSynEditForm.SetFileInfo(const FileName, DetectedEncoding: string; HasBOM: Boolean);
var
  BOMStr: string;
begin
  // 更新文件信息标签
  lblFileName.Caption := 'File: ' + ExtractFileName(FileName);
  lblEncoding.Caption := 'Encoding: ' + DetectedEncoding;
  
  if HasBOM then
    BOMStr := 'Yes'
  else
    BOMStr := 'No';
    
  lblBOM.Caption := 'BOM: ' + BOMStr;
end;

end.
