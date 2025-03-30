unit ViewSynEdit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, SynEdit, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Buttons,
  SynEditHighlighter, SynHighlighterXML, SynHighlighterHTML, SynHighlighterJSON, SynHighlighterIni,
  System.IOUtils;

type
  TForm2 = class(TForm)
    Panel1: TPanel;
    SynEdit1: TSynEdit;
    btnClose: TButton;
    lblFileInfo: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    { Private declarations }
    FSynXMLSyn: TSynXMLSyn;
    FSynHTMLSyn: TSynHTMLSyn;
    FSynJSONSyn: TSynJSONSyn;
    FSynIniSyn: TSynIniSyn;
    procedure ApplySyntaxHighlighter(const FileName: string);
  public
    { Public declarations }
    procedure LoadFile(const FileName: string; Encoding: TEncoding);
    procedure SetFileInfo(const FileName, EncodingName: string; HasBOM: Boolean);
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.ApplySyntaxHighlighter(const FileName: string);
var
  Ext: string;
begin
  // 默认不使用语法高亮
  SynEdit1.Highlighter := nil;
  
  // 根据文件扩展名应用合适的语法高亮
  Ext := LowerCase(ExtractFileExt(FileName));
  
  if (Ext = '.xml') or (Ext = '.svg') then
    SynEdit1.Highlighter := FSynXMLSyn
  else if (Ext = '.html') or (Ext = '.htm') then
    SynEdit1.Highlighter := FSynHTMLSyn
  else if (Ext = '.json') then
    SynEdit1.Highlighter := FSynJSONSyn
  else if (Ext = '.ini') or (Ext = '.conf') then
    SynEdit1.Highlighter := FSynIniSyn;
end;

procedure TForm2.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  // 创建语法高亮器
  FSynXMLSyn := TSynXMLSyn.Create(Self);
  FSynHTMLSyn := TSynHTMLSyn.Create(Self);
  FSynJSONSyn := TSynJSONSyn.Create(Self);
  FSynIniSyn := TSynIniSyn.Create(Self);
  
  // 初始化SynEdit
  SynEdit1.Gutter.ShowLineNumbers := True;
  SynEdit1.Options := SynEdit1.Options + [eoShowScrollHint, eoTabsToSpaces];
  SynEdit1.WantTabs := False;
  SynEdit1.TabWidth := 2;
end;

procedure TForm2.LoadFile(const FileName: string; Encoding: TEncoding);
begin
  try
    // 读取文件内容
    SynEdit1.Lines.LoadFromFile(FileName, Encoding);
    
    // 应用语法高亮
    ApplySyntaxHighlighter(FileName);
    
    // 设置窗口标题
    Caption := ExtractFileName(FileName);
  except
    on E: Exception do
      ShowMessage('无法加载文件: ' + E.Message);
  end;
end;

procedure TForm2.SetFileInfo(const FileName, EncodingName: string; HasBOM: Boolean);
var
  FileSize: Int64;
  BOMStr: string;
begin
  // 获取文件大小
  if FileExists(FileName) then
    FileSize := TFile.GetSize(FileName)
  else
    FileSize := 0;
    
  // BOM状态文本
  if HasBOM then
    BOMStr := '有BOM'
  else
    BOMStr := '无BOM';
    
  // 设置信息标签
  lblFileInfo.Caption := Format('文件: %s | 大小: %d 字节 | 编码: %s (%s) | 行数: %d', 
    [ExtractFileName(FileName), FileSize, EncodingName, BOMStr, SynEdit1.Lines.Count]);
end;

end.
