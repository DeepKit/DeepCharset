unit ViewSynEdit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  System.IOUtils, System.Math, SynEdit, SynEditHighlighter, SynHighlighterXML, SynHighlighterHTML;

type
  TForm2 = class(TForm)
    Panel1: TPanel;
    btnClose: TButton;
    lblFileInfo: TLabel;
    SynEdit1: TSynEdit;
    procedure FormCreate(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    { Private declarations }
    FHighlighterXML: TSynXMLSyn;
    FHighlighterHTML: TSynHTMLSyn;
    procedure ApplyHighlighter(const FileName: string);
  public
    { Public declarations }
    procedure LoadFile(const FileName: string; Encoding: TEncoding);
    procedure SetFileInfo(const FileName, EncodingName: string; HasBOM: Boolean);
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  // 初始化语法高亮
  FHighlighterXML := TSynXMLSyn.Create(Self);
  FHighlighterHTML := TSynHTMLSyn.Create(Self);
  
  // 设置SynEdit基本属性
  SynEdit1.Gutter.ShowLineNumbers := True;
  SynEdit1.Font.Name := 'Consolas';
  SynEdit1.Font.Size := 10;
  SynEdit1.Options := SynEdit1.Options + [eoTabsToSpaces];
  SynEdit1.TabWidth := 2;
  
  // 设置窗体属性
  Position := poScreenCenter;
end;

procedure TForm2.ApplyHighlighter(const FileName: string);
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(FileName));
  
  // 先清除当前高亮
  SynEdit1.Highlighter := nil;
  
  // 根据文件扩展名应用对应的语法高亮
  if (Ext = '.xml') or (Ext = '.svg') or (Ext = '.config') then
    SynEdit1.Highlighter := FHighlighterXML
  else if (Ext = '.html') or (Ext = '.htm') then
    SynEdit1.Highlighter := FHighlighterHTML;
end;

procedure TForm2.LoadFile(const FileName: string; Encoding: TEncoding);
var
  Stream: TFileStream;
  Reader: TStreamReader;
  Content: string;
  MaxReadSize: Int64;
  IsBinary: Boolean;
  Buffer: TBytes;
  NonTextChars: Integer;
  i: Integer;
begin
  try
    // 检查文件是否存在
    if not FileExists(FileName) then
      raise Exception.Create('文件不存在');
      
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      // 判断是否为二进制文件（通过检查前1024字节）
      IsBinary := False;
      MaxReadSize := System.Math.Min(Stream.Size, 1024);
      if MaxReadSize > 0 then
      begin
        SetLength(Buffer, MaxReadSize);
        Stream.ReadBuffer(Buffer[0], MaxReadSize);
        Stream.Position := 0;
        
        // 检查是否包含二进制字符
        for i := 0 to High(Buffer) do
          if (Buffer[i] < 7) or ((Buffer[i] > 14) and (Buffer[i] < 32) and (Buffer[i] <> 9)) then
          begin
            IsBinary := True;
            Break;
          end;
      end;
      
      if IsBinary then
      begin
        // 显示二进制文件信息
        SynEdit1.Lines.Clear;
        SynEdit1.Lines.Add('(二进制文件，不显示内容)');
        
        Caption := ExtractFileName(FileName) + ' [二进制文件]';
        Exit;
      end;
      
      // 读取文本文件
      Stream.Position := 0;
      Reader := TStreamReader.Create(Stream, Encoding, True);
      try
        Content := Reader.ReadToEnd;
        
        // 设置编辑器内容
        SynEdit1.Lines.Text := Content;
        SynEdit1.Modified := False; // 标记为未修改
        
        // 应用语法高亮
        ApplyHighlighter(FileName);
        
        // 检查内容是否包含大量乱码
        NonTextChars := 0;
        for i := 1 to System.Math.Min(Length(Content), 1000) do
        begin
          // 检查是否为可见ASCII字符、空白字符或中文字符
          if (Ord(Content[i]) < 32) and not (Content[i] in [#9, #10, #13]) then
            Inc(NonTextChars)
          else if (Ord(Content[i]) > 126) and (Ord(Content[i]) < $4E00) then
            Inc(NonTextChars)
          else if (Ord(Content[i]) > $9FFF) then
            Inc(NonTextChars);
        end;
            
        if (Length(Content) > 0) and ((NonTextChars / System.Math.Min(Length(Content), 1000)) > 0.3) then
          raise Exception.Create('文件可能使用了不支持的编码，或包含乱码');
      finally
        Reader.Free;
      end;
    finally
      Stream.Free;
    end;
    
    // 设置窗口标题
    Caption := ExtractFileName(FileName);
  except
    on E: Exception do
      raise Exception.Create('加载文件失败: ' + E.Message);
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