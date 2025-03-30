unit HelperSynMD;

interface

uses
  System.SysUtils, System.Classes, Vcl.Graphics, SynEdit, SynEditHighlighter;

type
  // 自定义Markdown语法高亮器
  TSynMDSyn = class(TSynCustomHighlighter)
  private
    // 高亮属性
    FTitleAttri: TSynHighlighterAttributes;
    FBoldAttri: TSynHighlighterAttributes;
    FItalicAttri: TSynHighlighterAttributes;
    FCodeAttri: TSynHighlighterAttributes;
    FListAttri: TSynHighlighterAttributes;
    FLinkAttri: TSynHighlighterAttributes;
    FQuoteAttri: TSynHighlighterAttributes;
    FHeadingAttri: TSynHighlighterAttributes;
    FSpaceAttri: TSynHighlighterAttributes;
    FDefaultAttri: TSynHighlighterAttributes;
    
    // 当前状态
    FTokenPos: Integer;
    FTokenLen: Integer;
    FLine: PChar;
    FLineLen: Integer;
    FRun: Integer;
    
    // 当前的Token类型
    FTokenID: Integer;
    
    // Helper methods
    function IsHeadingLine: Boolean;
    function IsBold: Boolean;
    function IsItalic: Boolean;
    function IsCode: Boolean;
    function IsList: Boolean;
    function IsLink: Boolean;
    function IsQuote: Boolean;
    
    procedure DoHeading;
    procedure DoIdentifier;
  protected
    function GetDefaultAttribute(Index: Integer): TSynHighlighterAttributes; override;
    function GetEol: Boolean; override;
    function GetTokenAttribute: TSynHighlighterAttributes; override;
    function GetTokenKind: Integer; override;
    function IsFilterStored: Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    // 核心分析函数
    procedure Next; override;
    function GetToken: string; override;
    procedure SetLine(const NewValue: string; LineNumber: Integer); override;

    procedure ResetRange; override;
    procedure SetRange(Value: Pointer); override;
    function GetRange: Pointer; override;
    
    // 高亮器属性
    class function GetLanguageName: string; override;
    class function GetFriendlyLanguageName: string; override;
    
  published
    property TitleAttri: TSynHighlighterAttributes read FTitleAttri write FTitleAttri;
    property BoldAttri: TSynHighlighterAttributes read FBoldAttri write FBoldAttri;
    property ItalicAttri: TSynHighlighterAttributes read FItalicAttri write FItalicAttri;
    property CodeAttri: TSynHighlighterAttributes read FCodeAttri write FCodeAttri;
    property ListAttri: TSynHighlighterAttributes read FListAttri write FListAttri;
    property LinkAttri: TSynHighlighterAttributes read FLinkAttri write FLinkAttri;
    property QuoteAttri: TSynHighlighterAttributes read FQuoteAttri write FQuoteAttri;
    property HeadingAttri: TSynHighlighterAttributes read FHeadingAttri write FHeadingAttri;
    property SpaceAttri: TSynHighlighterAttributes read FSpaceAttri write FSpaceAttri;
    property DefaultAttri: TSynHighlighterAttributes read FDefaultAttri write FDefaultAttri;
  end;

implementation

uses
  Winapi.Windows;

// Token类型常量
const
  tkDefault  = 0;
  tkHeading  = 1;
  tkBold     = 2;
  tkItalic   = 3;
  tkCode     = 4;
  tkList     = 5;
  tkLink     = 6;
  tkQuote    = 7;
  tkSpace    = 8;
  tkTitle    = 9;

{ TSynMDSyn }

constructor TSynMDSyn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  
  // 创建并配置属性
  FDefaultAttri := TSynHighlighterAttributes.Create('Default', 'Default');
  FDefaultAttri.Foreground := clBlack;
  AddAttribute(FDefaultAttri);
  
  FTitleAttri := TSynHighlighterAttributes.Create('Title', '标题');
  FTitleAttri.Foreground := clBlue;
  FTitleAttri.Style := [fsBold];
  AddAttribute(FTitleAttri);
  
  FBoldAttri := TSynHighlighterAttributes.Create('Bold', '粗体');
  FBoldAttri.Style := [fsBold];
  AddAttribute(FBoldAttri);
  
  FItalicAttri := TSynHighlighterAttributes.Create('Italic', '斜体');
  FItalicAttri.Style := [fsItalic];
  AddAttribute(FItalicAttri);
  
  FCodeAttri := TSynHighlighterAttributes.Create('Code', '代码');
  FCodeAttri.Foreground := clTeal;
  FCodeAttri.Background := clWhite;
  AddAttribute(FCodeAttri);
  
  FListAttri := TSynHighlighterAttributes.Create('List', '列表');
  FListAttri.Foreground := clMaroon;
  AddAttribute(FListAttri);
  
  FLinkAttri := TSynHighlighterAttributes.Create('Link', '链接');
  FLinkAttri.Foreground := clPurple;
  FLinkAttri.Style := [fsUnderline];
  AddAttribute(FLinkAttri);
  
  FQuoteAttri := TSynHighlighterAttributes.Create('Quote', '引用');
  FQuoteAttri.Foreground := clGreen;
  FQuoteAttri.Style := [fsItalic];
  AddAttribute(FQuoteAttri);
  
  FHeadingAttri := TSynHighlighterAttributes.Create('Heading', '标题');
  FHeadingAttri.Foreground := clBlue;
  FHeadingAttri.Style := [fsBold];
  AddAttribute(FHeadingAttri);
  
  FSpaceAttri := TSynHighlighterAttributes.Create('Space', '空格');
  AddAttribute(FSpaceAttri);
  
  // 设置过滤器
  SetAttributesOnChange(@DefHighlightChange);
end;

destructor TSynMDSyn.Destroy;
begin
  inherited;
end;

function TSynMDSyn.GetDefaultAttribute(Index: Integer): TSynHighlighterAttributes;
begin
  case Index of
    SYN_ATTR_IDENTIFIER: Result := FDefaultAttri;
    SYN_ATTR_WHITESPACE: Result := FSpaceAttri;
    SYN_ATTR_KEYWORD: Result := FHeadingAttri;
    SYN_ATTR_STRING: Result := FLinkAttri;
    SYN_ATTR_COMMENT: Result := FQuoteAttri;
  else
    Result := nil;
  end;
end;

function TSynMDSyn.GetEol: Boolean;
begin
  Result := (FRun > FLineLen);
end;

function TSynMDSyn.GetTokenAttribute: TSynHighlighterAttributes;
begin
  case FTokenID of
    tkDefault: Result := FDefaultAttri;
    tkHeading: Result := FHeadingAttri;
    tkBold: Result := FBoldAttri;
    tkItalic: Result := FItalicAttri;
    tkCode: Result := FCodeAttri;
    tkList: Result := FListAttri;
    tkLink: Result := FLinkAttri;
    tkQuote: Result := FQuoteAttri;
    tkSpace: Result := FSpaceAttri;
    tkTitle: Result := FTitleAttri;
  else
    Result := FDefaultAttri;
  end;
end;

function TSynMDSyn.GetTokenKind: Integer;
begin
  Result := FTokenID;
end;

class function TSynMDSyn.GetLanguageName: string;
begin
  Result := 'Markdown';
end;

class function TSynMDSyn.GetFriendlyLanguageName: string;
begin
  Result := 'Markdown';
end;

function TSynMDSyn.IsFilterStored: Boolean;
begin
  Result := False;
end;

procedure TSynMDSyn.Next;
begin
  FTokenPos := FRun;
  
  // 检测行首的特殊标记
  if FRun = 0 then
  begin
    if IsHeadingLine then
    begin
      DoHeading;
      Exit;
    end;
    
    if IsQuote then
    begin
      FTokenID := tkQuote;
      // 跳过引用标记 >
      Inc(FRun);
      while (FRun <= FLineLen) and (FLine[FRun] = ' ') do Inc(FRun);
      FTokenLen := FRun - FTokenPos;
      Exit;
    end;
    
    if IsList then
    begin
      FTokenID := tkList;
      // 跳过列表标记 * - +
      Inc(FRun);
      while (FRun <= FLineLen) and (FLine[FRun] = ' ') do Inc(FRun);
      FTokenLen := FRun - FTokenPos;
      Exit;
    end;
  end;
  
  // 处理空格
  if (FRun <= FLineLen) and (FLine[FRun] = ' ') then
  begin
    FTokenID := tkSpace;
    while (FRun <= FLineLen) and (FLine[FRun] = ' ') do Inc(FRun);
    FTokenLen := FRun - FTokenPos;
    Exit;
  end;
  
  // 检测粗体
  if IsBold then
  begin
    FTokenID := tkBold;
    // 跳过 **
    Inc(FRun, 2);
    while (FRun <= FLineLen) and not ((FRun+1 <= FLineLen) and (FLine[FRun] = '*') and (FLine[FRun+1] = '*')) do
      Inc(FRun);
    // 跳过结束的 **
    if (FRun+1 <= FLineLen) then
      Inc(FRun, 2);
    FTokenLen := FRun - FTokenPos;
    Exit;
  end;
  
  // 检测斜体
  if IsItalic then
  begin
    FTokenID := tkItalic;
    // 跳过 *
    Inc(FRun);
    while (FRun <= FLineLen) and (FLine[FRun] <> '*') do
      Inc(FRun);
    // 跳过结束的 *
    if (FRun <= FLineLen) then
      Inc(FRun);
    FTokenLen := FRun - FTokenPos;
    Exit;
  end;
  
  // 检测代码块
  if IsCode then
  begin
    FTokenID := tkCode;
    // 跳过 `
    Inc(FRun);
    while (FRun <= FLineLen) and (FLine[FRun] <> '`') do
      Inc(FRun);
    // 跳过结束的 `
    if (FRun <= FLineLen) then
      Inc(FRun);
    FTokenLen := FRun - FTokenPos;
    Exit;
  end;
  
  // 检测链接
  if IsLink then
  begin
    FTokenID := tkLink;
    // 处理[text](url)格式
    Inc(FRun);
    // 跳过[text]部分
    while (FRun <= FLineLen) and (FLine[FRun] <> ']') do
      Inc(FRun);
    if (FRun <= FLineLen) then Inc(FRun);
    
    // 如果是后接(url)，则继续处理
    if (FRun <= FLineLen) and (FLine[FRun] = '(') then
    begin
      Inc(FRun);
      while (FRun <= FLineLen) and (FLine[FRun] <> ')') do
        Inc(FRun);
      if (FRun <= FLineLen) then Inc(FRun);
    end;
    
    FTokenLen := FRun - FTokenPos;
    Exit;
  end;
  
  // 默认处理（普通文本）
  DoIdentifier;
end;

procedure TSynMDSyn.DoHeading;
begin
  FTokenID := tkHeading;
  // 跳过 # 符号和空格
  while (FRun <= FLineLen) and ((FLine[FRun] = '#') or (FLine[FRun] = ' ')) do
    Inc(FRun);
  FTokenLen := FRun - FTokenPos;
end;

procedure TSynMDSyn.DoIdentifier;
begin
  FTokenID := tkDefault;
  while (FRun <= FLineLen) do
  begin
    // 遇到特殊字符就停止
    if (FLine[FRun] = '*') or (FLine[FRun] = '`') or 
       (FLine[FRun] = '[') or (FLine[FRun] = '#') or 
       (FLine[FRun] = '>') or (FLine[FRun] = ' ') then
      Break;
    Inc(FRun);
  end;
  FTokenLen := FRun - FTokenPos;
end;

function TSynMDSyn.GetToken: string;
var
  Len: Integer;
begin
  Len := FTokenLen;
  SetString(Result, (FLine + FTokenPos), Len);
end;

procedure TSynMDSyn.GetTokenEx(out TokenStart: PChar; out TokenLength: Integer);
begin
  TokenStart := FLine + FTokenPos;
  TokenLength := FTokenLen;
end;

function TSynMDSyn.IsHeadingLine: Boolean;
begin
  Result := (FRun <= FLineLen) and (FLine[FRun] = '#');
end;

function TSynMDSyn.IsBold: Boolean;
begin
  Result := (FRun+1 <= FLineLen) and 
            (FLine[FRun] = '*') and 
            (FLine[FRun+1] = '*');
end;

function TSynMDSyn.IsItalic: Boolean;
begin
  Result := (FRun <= FLineLen) and 
            (FLine[FRun] = '*') and 
            not ((FRun+1 <= FLineLen) and (FLine[FRun+1] = '*'));
end;

function TSynMDSyn.IsCode: Boolean;
begin
  Result := (FRun <= FLineLen) and (FLine[FRun] = '`');
end;

function TSynMDSyn.IsList: Boolean;
begin
  Result := (FRun <= FLineLen) and 
           ((FLine[FRun] = '*') or (FLine[FRun] = '-') or (FLine[FRun] = '+')) and
           ((FRun+1 <= FLineLen) and (FLine[FRun+1] = ' '));
end;

function TSynMDSyn.IsLink: Boolean;
begin
  Result := (FRun <= FLineLen) and (FLine[FRun] = '[');
end;

function TSynMDSyn.IsQuote: Boolean;
begin
  Result := (FRun <= FLineLen) and (FLine[FRun] = '>');
end;

procedure TSynMDSyn.ResetRange;
begin
  // Reset range is simple for Markdown
end;

function TSynMDSyn.GetRange: Pointer;
begin
  Result := nil;
end;

procedure TSynMDSyn.SetRange(Value: Pointer);
begin
  // No ranges needed for Markdown
end;

procedure TSynMDSyn.SetLine(const NewValue: string; LineNumber: Integer);
begin
  FLine := PChar(NewValue);
  FLineLen := Length(NewValue);
  FRun := 0;
  FTokenPos := 0;
  FTokenLen := 0;
  Next;
end;

initialization
  // 注册
  RegisterPlaceableHighlighter(TSynMDSyn);

end. 