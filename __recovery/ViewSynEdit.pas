unit ViewSynEdit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  System.IOUtils, System.Math, SynEdit, SynEditHighlighter,
  SynHighlighterXML, SynHighlighterHTML, SynHighlighterPas, SynHighlighterJava,
  SynHighlighterCpp, SynHighlighterPython, SynHighlighterCS, SynHighlighterSQL,
  SynHighlighterJScript, SynHighlighterCSS, SynHighlighterJSON, SynHighlighterIni,
  SynHighlighterBat, SynHighlighterVB, SynHighlighterPerl, SynHighlighterPHP,
  SynHighlighterTeX, SynHighlighterRuby;

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
    FHighlighterPas: TSynPasSyn;
    FHighlighterJava: TSynJavaSyn;
    FHighlighterCpp: TSynCppSyn;
    FHighlighterPython: TSynPythonSyn;
    FHighlighterCS: TSynCSSyn;
    FHighlighterSQL: TSynSQLSyn;
    FHighlighterJS: TSynJScriptSyn;
    FHighlighterCSS: TSynCssSyn;
    FHighlighterJSON: TSynJSONSyn;
    FHighlighterIni: TSynIniSyn;
    FHighlighterBat: TSynBatSyn;
    FHighlighterVB: TSynVBSyn;
    FHighlighterPerl: TSynPerlSyn;
    FHighlighterPHP: TSynPHPSyn;
    FHighlighterTeX: TSynTeXSyn;
    FHighlighterRuby: TSynRubySyn;
    procedure ApplyHighlighter(const FileName: string);
    procedure CheckHighlightersStatus;
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
  try
    // 初始化语法高亮器
    FHighlighterXML := TSynXMLSyn.Create(Self);
    FHighlighterHTML := TSynHTMLSyn.Create(Self);
    FHighlighterPas := TSynPasSyn.Create(Self);
    
    // 特别确保Pascal高亮器正确配置
    if Assigned(FHighlighterPas) then
    begin
      FHighlighterPas.KeyAttri.Foreground := clBlue;
      FHighlighterPas.StringAttri.Foreground := clRed;
      FHighlighterPas.CommentAttri.Foreground := clGreen;
      FHighlighterPas.NumberAttri.Foreground := clMaroon;
      OutputDebugString(PChar('Pascal高亮器初始化成功'));
    end
    else
      OutputDebugString(PChar('警告: Pascal高亮器创建失败'));
    
    FHighlighterJava := TSynJavaSyn.Create(Self);
    FHighlighterCpp := TSynCppSyn.Create(Self);
    FHighlighterPython := TSynPythonSyn.Create(Self);
    FHighlighterCS := TSynCSSyn.Create(Self);
    FHighlighterSQL := TSynSQLSyn.Create(Self);
    FHighlighterJS := TSynJScriptSyn.Create(Self);
    FHighlighterCSS := TSynCssSyn.Create(Self);
    FHighlighterJSON := TSynJSONSyn.Create(Self);
    FHighlighterIni := TSynIniSyn.Create(Self);
    FHighlighterBat := TSynBatSyn.Create(Self);
    FHighlighterVB := TSynVBSyn.Create(Self);
    FHighlighterPerl := TSynPerlSyn.Create(Self);
    FHighlighterPHP := TSynPHPSyn.Create(Self);
    FHighlighterTeX := TSynTeXSyn.Create(Self);
    FHighlighterRuby := TSynRubySyn.Create(Self);
    
    // 设置SynEdit基本属性
    SynEdit1.Gutter.ShowLineNumbers := True;
    SynEdit1.Font.Name := 'Consolas';
    SynEdit1.Font.Size := 10;
    SynEdit1.Options := SynEdit1.Options + [eoTabsToSpaces];
    SynEdit1.TabWidth := 2;
    
    // 设置窗体属性
    Position := poScreenCenter;
    
    // 检查高亮器状态
    CheckHighlightersStatus;
  except
    on E: Exception do
      ShowMessage('初始化高亮器失败: ' + E.Message);
  end;
end;

procedure TForm2.ApplyHighlighter(const FileName: string);
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(FileName));
  
  // 先清除当前高亮
  SynEdit1.Highlighter := nil;
  
  // 调试信息
  OutputDebugString(PChar('正在为文件应用高亮: ' + FileName + ' 扩展名: ' + Ext));
  
  // Delphi/Pascal
  if (Ext = '.pas') or (Ext = '.dpr') or (Ext = '.dpk') or (Ext = '.inc') 
    or (Ext = '.dfm') or (Ext = '.fmx') then
  begin
    SynEdit1.Highlighter := FHighlighterPas;
    OutputDebugString(PChar('应用Pascal高亮器'));
    if FHighlighterPas = nil then
      OutputDebugString(PChar('警告: Pascal高亮器为nil'));
  end
    
  // XML相关
  else if (Ext = '.xml') or (Ext = '.svg') or (Ext = '.config') or (Ext = '.xsd') 
    or (Ext = '.xsl') or (Ext = '.xslt') or (Ext = '.dtd') or (Ext = '.resx') 
    or (Ext = '.manifest') then
    SynEdit1.Highlighter := FHighlighterXML
    
  // HTML相关
  else if (Ext = '.html') or (Ext = '.htm') or (Ext = '.shtml') or (Ext = '.xhtml') then
    SynEdit1.Highlighter := FHighlighterHTML
    
  // Java
  else if (Ext = '.java') or (Ext = '.jav') then
    SynEdit1.Highlighter := FHighlighterJava
    
  // C/C++
  else if (Ext = '.c') or (Ext = '.cpp') or (Ext = '.cc') or (Ext = '.h') 
    or (Ext = '.hpp') or (Ext = '.hh') or (Ext = '.cxx') or (Ext = '.hxx') then
    SynEdit1.Highlighter := FHighlighterCpp
    
  // Python
  else if (Ext = '.py') or (Ext = '.pyw') or (Ext = '.pyc') or (Ext = '.pyd') 
    or (Ext = '.pyo') then
    SynEdit1.Highlighter := FHighlighterPython
    
  // C#
  else if (Ext = '.cs') then
    SynEdit1.Highlighter := FHighlighterCS
    
  // SQL
  else if (Ext = '.sql') or (Ext = '.ddl') or (Ext = '.dml') or (Ext = '.pls') 
    or (Ext = '.pks') or (Ext = '.pkb') then
    SynEdit1.Highlighter := FHighlighterSQL
    
  // JavaScript
  else if (Ext = '.js') or (Ext = '.jsx') or (Ext = '.mjs') then
    SynEdit1.Highlighter := FHighlighterJS
    
  // CSS
  else if (Ext = '.css') or (Ext = '.scss') or (Ext = '.sass') or (Ext = '.less') then
    SynEdit1.Highlighter := FHighlighterCSS
    
  // JSON
  else if (Ext = '.json') then
    SynEdit1.Highlighter := FHighlighterJSON
    
  // INI files
  else if (Ext = '.ini') or (Ext = '.inf') or (Ext = '.conf') or (Ext = '.cfg') 
    or (Ext = '.properties') then
    SynEdit1.Highlighter := FHighlighterIni
    
  // Batch files
  else if (Ext = '.bat') or (Ext = '.cmd') then
    SynEdit1.Highlighter := FHighlighterBat
    
  // Visual Basic
  else if (Ext = '.vb') or (Ext = '.bas') or (Ext = '.vbs') or (Ext = '.frm') 
    or (Ext = '.cls') then
    SynEdit1.Highlighter := FHighlighterVB
    
  // Perl
  else if (Ext = '.pl') or (Ext = '.pm') or (Ext = '.perl') then
    SynEdit1.Highlighter := FHighlighterPerl
    
  // PHP
  else if (Ext = '.php') or (Ext = '.php3') or (Ext = '.php4') or (Ext = '.php5') 
    or (Ext = '.phtml') then
    SynEdit1.Highlighter := FHighlighterPHP
    
  // TeX/LaTeX
  else if (Ext = '.tex') or (Ext = '.latex') or (Ext = '.sty') or (Ext = '.cls') 
    or (Ext = '.ltx') then
    SynEdit1.Highlighter := FHighlighterTeX
    
  // Ruby
  else if (Ext = '.rb') or (Ext = '.rbw') or (Ext = '.rake') or (Ext = '.gemspec') then
    SynEdit1.Highlighter := FHighlighterRuby;
  
  // 为标题添加语言信息
  if SynEdit1.Highlighter <> nil then
  begin
    Caption := ExtractFileName(FileName) + ' - [' + SynEdit1.Highlighter.LanguageName + ']';
    OutputDebugString(PChar('成功应用高亮器: ' + SynEdit1.Highlighter.LanguageName));
  end
  else
  begin
    Caption := ExtractFileName(FileName);
    OutputDebugString(PChar('未应用任何高亮器'));
  end;
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
  Ext: string;
begin
  try
    // 检查文件是否存在
    if not FileExists(FileName) then
      raise Exception.Create('文件不存在');
      
    // 获取文件扩展名
    Ext := LowerCase(ExtractFileExt(FileName));
    OutputDebugString(PChar('加载文件: ' + FileName + ' 扩展名: ' + Ext));
      
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
        
        // 特殊处理Pascal文件
        if (Ext = '.pas') and (SynEdit1.Highlighter = nil) then
        begin
          OutputDebugString(PChar('特殊处理Pascal文件'));
          if Assigned(FHighlighterPas) then
          begin
            SynEdit1.Highlighter := FHighlighterPas;
            Caption := ExtractFileName(FileName) + ' - [Object Pascal]';
            OutputDebugString(PChar('手动设置Pascal高亮器'));
          end;
        end;
        
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
    if SynEdit1.Highlighter = nil then
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

procedure TForm2.CheckHighlightersStatus;
var
  Log: string;
begin
  Log := 'SynEdit组件状态:';
  if Assigned(SynEdit1) then
    Log := Log + ' SynEdit正常'
  else
    Log := Log + ' SynEdit未正确加载!';
    
  Log := Log + #13#10 + '高亮器状态:';
  if Assigned(FHighlighterPas) then
    Log := Log + ' Pascal高亮器正常'
  else
    Log := Log + ' Pascal高亮器未加载!';
    
  if Assigned(FHighlighterXML) then
    Log := Log + ' XML高亮器正常'
  else
    Log := Log + ' XML高亮器未加载!';
    
  OutputDebugString(PChar(Log));
  
  // 测试基本高亮是否有效
  try
    // 测试Pascal高亮器
    if Assigned(FHighlighterPas) then
    begin
      SynEdit1.Lines.Clear;
      SynEdit1.Lines.Add('procedure Test;');
      SynEdit1.Lines.Add('begin');
      SynEdit1.Lines.Add('  ShowMessage(''Hello'');');
      SynEdit1.Lines.Add('end;');
      
      SynEdit1.Highlighter := FHighlighterPas;
      Application.ProcessMessages;
      
      if SynEdit1.Highlighter = FHighlighterPas then
        OutputDebugString(PChar('Pascal高亮器应用成功'))
      else
        OutputDebugString(PChar('警告: Pascal高亮器应用失败!'));
    end;
  except
    on E: Exception do
      OutputDebugString(PChar('测试高亮器时出错: ' + E.Message));
  end;
end;

end. 