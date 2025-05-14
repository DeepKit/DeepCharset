unit UtilsEncodingSpecialChars;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.IOUtils,
  Winapi.Windows, UtilsEncodingConstants;

type
  /// <summary>
  /// 特殊字符类型
  /// </summary>
  TSpecialCharType = (
    sctChinese,        // 中文字符
    sctJapanese,       // 日文字符
    sctKorean,         // 韩文字符
    sctPunctuation,    // 标点符号
    sctMathSymbol,     // 数学符号
    sctCurrency,       // 货币符号
    sctEmoji,          // 表情符号
    sctTechnical,      // 技术符号
    sctDiacritical,    // 变音符号
    sctOther           // 其他特殊字符
  );

  /// <summary>
  /// 特殊字符信息
  /// </summary>
  TSpecialCharInfo = record
    Character: string;
    CharType: TSpecialCharType;
    UnicodeValue: Integer;
    Description: string;
    constructor Create(const ACharacter: string; ACharType: TSpecialCharType; AUnicodeValue: Integer; const ADescription: string);
  end;

  /// <summary>
  /// 特殊字符验证结果
  /// </summary>
  TSpecialCharValidationResult = record
    Success: Boolean;
    TotalChars: Integer;
    MatchedChars: Integer;
    MismatchedChars: Integer;
    ErrorChars: TArray<string>;
    DetailedMessage: string;
    constructor Create(ASuccess: Boolean; ATotalChars, AMatchedChars, AMismatchedChars: Integer; const AErrorChars: TArray<string>; const ADetailedMessage: string);
  end;

  /// <summary>
  /// 特殊字符验证器
  /// </summary>
  TSpecialCharValidator = class
  private
    FSpecialChars: TDictionary<string, TSpecialCharInfo>;
    FLastErrorMessage: string;
    
    procedure InitializeSpecialChars;
    function GetTotalSpecialChars: Integer;
    function GetSpecialCharsList: TArray<TSpecialCharInfo>;
    function CompareBuffers(const Source, Target: TBytes; SourceEncoding, TargetEncoding: string): TSpecialCharValidationResult;
  public
    constructor Create;
    destructor Destroy; override;
    
    /// <summary>
    /// 验证编码转换后特殊字符是否保持完整
    /// </summary>
    function ValidateSpecialChars(const SourceFile, TargetFile: string; SourceEncoding, TargetEncoding: string): TSpecialCharValidationResult;
    
    /// <summary>
    /// 验证缓冲区中特殊字符是否保持完整
    /// </summary>
    function ValidateBuffers(const SourceBuffer, TargetBuffer: TBytes; SourceEncoding, TargetEncoding: string): TSpecialCharValidationResult;
    
    /// <summary>
    /// 生成标准特殊字符测试文件
    /// </summary>
    function GenerateTestFile(const FileName: string; Encoding: string; IncludeTypes: TArray<TSpecialCharType>): Boolean;
    
    /// <summary>
    /// 获取指定类型的特殊字符列表
    /// </summary>
    function GetSpecialCharsByType(CharType: TSpecialCharType): TArray<TSpecialCharInfo>;
    
    /// <summary>
    /// 获取最后一次错误信息
    /// </summary>
    function GetLastError: string;
    
    property LastErrorMessage: string read FLastErrorMessage;
    property TotalSpecialChars: Integer read GetTotalSpecialChars;
    property SpecialCharsList: TArray<TSpecialCharInfo> read GetSpecialCharsList;
  end;

implementation

// 构造函数
constructor TSpecialCharInfo.Create(const ACharacter: string; ACharType: TSpecialCharType; AUnicodeValue: Integer; const ADescription: string);
begin
  Character := ACharacter;
  CharType := ACharType;
  UnicodeValue := AUnicodeValue;
  Description := ADescription;
end;

constructor TSpecialCharValidationResult.Create(ASuccess: Boolean; ATotalChars, AMatchedChars, AMismatchedChars: Integer; const AErrorChars: TArray<string>; const ADetailedMessage: string);
begin
  Success := ASuccess;
  TotalChars := ATotalChars;
  MatchedChars := AMatchedChars;
  MismatchedChars := AMismatchedChars;
  ErrorChars := AErrorChars;
  DetailedMessage := ADetailedMessage;
end;

constructor TSpecialCharValidator.Create;
begin
  inherited Create;
  FSpecialChars := TDictionary<string, TSpecialCharInfo>.Create;
  FLastErrorMessage := '';
  InitializeSpecialChars;
end;

destructor TSpecialCharValidator.Destroy;
begin
  FSpecialChars.Free;
  inherited;
end;

procedure TSpecialCharValidator.InitializeSpecialChars;
begin
  // 中文字符
  FSpecialChars.Add('你', TSpecialCharInfo.Create('你', sctChinese, $4F60, '中文-你'));
  FSpecialChars.Add('好', TSpecialCharInfo.Create('好', sctChinese, $597D, '中文-好'));
  FSpecialChars.Add('世', TSpecialCharInfo.Create('世', sctChinese, $4E16, '中文-世'));
  FSpecialChars.Add('界', TSpecialCharInfo.Create('界', sctChinese, $754C, '中文-界'));
  
  // 日文字符
  FSpecialChars.Add('あ', TSpecialCharInfo.Create('あ', sctJapanese, $3042, '日文-あ'));
  FSpecialChars.Add('い', TSpecialCharInfo.Create('い', sctJapanese, $3044, '日文-い'));
  FSpecialChars.Add('う', TSpecialCharInfo.Create('う', sctJapanese, $3046, '日文-う'));
  FSpecialChars.Add('え', TSpecialCharInfo.Create('え', sctJapanese, $3048, '日文-え'));
  FSpecialChars.Add('お', TSpecialCharInfo.Create('お', sctJapanese, $304A, '日文-お'));
  
  // 韩文字符
  FSpecialChars.Add('안', TSpecialCharInfo.Create('안', sctKorean, $C548, '韩文-안'));
  FSpecialChars.Add('녕', TSpecialCharInfo.Create('녕', sctKorean, $B155, '韩文-녕'));
  FSpecialChars.Add('하', TSpecialCharInfo.Create('하', sctKorean, $D558, '韩文-하'));
  FSpecialChars.Add('세', TSpecialCharInfo.Create('세', sctKorean, $C138, '韩文-세'));
  FSpecialChars.Add('요', TSpecialCharInfo.Create('요', sctKorean, $C694, '韩文-요'));
  
  // 标点符号
  FSpecialChars.Add('……', TSpecialCharInfo.Create('……', sctPunctuation, $2026, '标点-省略号'));
  FSpecialChars.Add('—', TSpecialCharInfo.Create('—', sctPunctuation, $2014, '标点-破折号'));
  FSpecialChars.Add('"', TSpecialCharInfo.Create('"', sctPunctuation, $201C, '标点-左双引号'));
  FSpecialChars.Add('"', TSpecialCharInfo.Create('"', sctPunctuation, $201D, '标点-右双引号'));
  FSpecialChars.Add('《', TSpecialCharInfo.Create('《', sctPunctuation, $300A, '标点-左书名号'));
  FSpecialChars.Add('》', TSpecialCharInfo.Create('》', sctPunctuation, $300B, '标点-右书名号'));
  
  // 数学符号
  FSpecialChars.Add('≠', TSpecialCharInfo.Create('≠', sctMathSymbol, $2260, '数学-不等号'));
  FSpecialChars.Add('≤', TSpecialCharInfo.Create('≤', sctMathSymbol, $2264, '数学-小于等于'));
  FSpecialChars.Add('≥', TSpecialCharInfo.Create('≥', sctMathSymbol, $2265, '数学-大于等于'));
  FSpecialChars.Add('∞', TSpecialCharInfo.Create('∞', sctMathSymbol, $221E, '数学-无穷大'));
  FSpecialChars.Add('π', TSpecialCharInfo.Create('π', sctMathSymbol, $03C0, '数学-圆周率'));
  
  // 货币符号
  FSpecialChars.Add('￥', TSpecialCharInfo.Create('￥', sctCurrency, $FFE5, '货币-人民币'));
  FSpecialChars.Add('$', TSpecialCharInfo.Create('$', sctCurrency, $0024, '货币-美元'));
  FSpecialChars.Add('€', TSpecialCharInfo.Create('€', sctCurrency, $20AC, '货币-欧元'));
  FSpecialChars.Add('£', TSpecialCharInfo.Create('£', sctCurrency, $00A3, '货币-英镑'));
  FSpecialChars.Add('¥', TSpecialCharInfo.Create('¥', sctCurrency, $00A5, '货币-日元'));
  
  // 表情符号
  FSpecialChars.Add('☺', TSpecialCharInfo.Create('☺', sctEmoji, $263A, '表情-笑脸'));
  FSpecialChars.Add('☹', TSpecialCharInfo.Create('☹', sctEmoji, $2639, '表情-悲伤'));
  FSpecialChars.Add('♥', TSpecialCharInfo.Create('♥', sctEmoji, $2665, '表情-爱心'));
  FSpecialChars.Add('♦', TSpecialCharInfo.Create('♦', sctEmoji, $2666, '表情-方块'));
  FSpecialChars.Add('♣', TSpecialCharInfo.Create('♣', sctEmoji, $2663, '表情-梅花'));
  
  // 技术符号
  FSpecialChars.Add('©', TSpecialCharInfo.Create('©', sctTechnical, $00A9, '技术-版权'));
  FSpecialChars.Add('®', TSpecialCharInfo.Create('®', sctTechnical, $00AE, '技术-注册商标'));
  FSpecialChars.Add('™', TSpecialCharInfo.Create('™', sctTechnical, $2122, '技术-商标'));
  FSpecialChars.Add('§', TSpecialCharInfo.Create('§', sctTechnical, $00A7, '技术-章节'));
  FSpecialChars.Add('¶', TSpecialCharInfo.Create('¶', sctTechnical, $00B6, '技术-段落'));
  
  // 变音符号
  FSpecialChars.Add('á', TSpecialCharInfo.Create('á', sctDiacritical, $00E1, '变音-a尖音'));
  FSpecialChars.Add('é', TSpecialCharInfo.Create('é', sctDiacritical, $00E9, '变音-e尖音'));
  FSpecialChars.Add('í', TSpecialCharInfo.Create('í', sctDiacritical, $00ED, '变音-i尖音'));
  FSpecialChars.Add('ñ', TSpecialCharInfo.Create('ñ', sctDiacritical, $00F1, '变音-n波浪'));
  FSpecialChars.Add('ü', TSpecialCharInfo.Create('ü', sctDiacritical, $00FC, '变音-u分音'));
  
  // 其他特殊字符
  FSpecialChars.Add('±', TSpecialCharInfo.Create('±', sctOther, $00B1, '其他-正负号'));
  FSpecialChars.Add('µ', TSpecialCharInfo.Create('µ', sctOther, $00B5, '其他-微符号'));
  FSpecialChars.Add('°', TSpecialCharInfo.Create('°', sctOther, $00B0, '其他-度数'));
  FSpecialChars.Add('№', TSpecialCharInfo.Create('№', sctOther, $2116, '其他-编号'));
  FSpecialChars.Add('→', TSpecialCharInfo.Create('→', sctOther, $2192, '其他-箭头'));
end;

function TSpecialCharValidator.GetTotalSpecialChars: Integer;
begin
  Result := FSpecialChars.Count;
end;

function TSpecialCharValidator.GetSpecialCharsList: TArray<TSpecialCharInfo>;
var
  I: Integer;
  CharInfo: TSpecialCharInfo;
begin
  SetLength(Result, FSpecialChars.Count);
  I := 0;
  for CharInfo in FSpecialChars.Values do
  begin
    Result[I] := CharInfo;
    Inc(I);
  end;
end;

function TSpecialCharValidator.GetSpecialCharsByType(CharType: TSpecialCharType): TArray<TSpecialCharInfo>;
var
  TempList: TList<TSpecialCharInfo>;
  CharInfo: TSpecialCharInfo;
begin
  TempList := TList<TSpecialCharInfo>.Create;
  try
    for CharInfo in FSpecialChars.Values do
      if CharInfo.CharType = CharType then
        TempList.Add(CharInfo);
    
    SetLength(Result, TempList.Count);
    for var I := 0 to TempList.Count - 1 do
      Result[I] := TempList[I];
  finally
    TempList.Free;
  end;
end;

function TSpecialCharValidator.GetLastError: string;
begin
  Result := FLastErrorMessage;
end;

function TSpecialCharValidator.ValidateSpecialChars(const SourceFile, TargetFile: string; SourceEncoding, TargetEncoding: string): TSpecialCharValidationResult;
var
  SourceBuffer, TargetBuffer: TBytes;
begin
  FLastErrorMessage := '';
  
  // 检查文件是否存在
  if not FileExists(SourceFile) then
  begin
    FLastErrorMessage := '源文件不存在: ' + SourceFile;
    Result := TSpecialCharValidationResult.Create(False, 0, 0, 0, [], FLastErrorMessage);
    Exit;
  end;
  
  if not FileExists(TargetFile) then
  begin
    FLastErrorMessage := '目标文件不存在: ' + TargetFile;
    Result := TSpecialCharValidationResult.Create(False, 0, 0, 0, [], FLastErrorMessage);
    Exit;
  end;
  
  try
    // 读取文件内容
    SourceBuffer := TFile.ReadAllBytes(SourceFile);
    TargetBuffer := TFile.ReadAllBytes(TargetFile);
    
    // 验证特殊字符
    Result := ValidateBuffers(SourceBuffer, TargetBuffer, SourceEncoding, TargetEncoding);
  except
    on E: Exception do
    begin
      FLastErrorMessage := '验证特殊字符时发生错误: ' + E.Message;
      Result := TSpecialCharValidationResult.Create(False, 0, 0, 0, [], FLastErrorMessage);
    end;
  end;
end;

function TSpecialCharValidator.ValidateBuffers(const SourceBuffer, TargetBuffer: TBytes; SourceEncoding, TargetEncoding: string): TSpecialCharValidationResult;
begin
  FLastErrorMessage := '';
  
  if (Length(SourceBuffer) = 0) or (Length(TargetBuffer) = 0) then
  begin
    FLastErrorMessage := '缓冲区为空';
    Result := TSpecialCharValidationResult.Create(False, 0, 0, 0, [], FLastErrorMessage);
    Exit;
  end;
  
  try
    // 比较源和目标缓冲区中的特殊字符
    Result := CompareBuffers(SourceBuffer, TargetBuffer, SourceEncoding, TargetEncoding);
  except
    on E: Exception do
    begin
      FLastErrorMessage := '验证缓冲区特殊字符时发生错误: ' + E.Message;
      Result := TSpecialCharValidationResult.Create(False, 0, 0, 0, [], FLastErrorMessage);
    end;
  end;
end;

function TSpecialCharValidator.CompareBuffers(const Source, Target: TBytes; SourceEncoding, TargetEncoding: string): TSpecialCharValidationResult;
var
  SourceText, TargetText: string;
  TotalChars, MatchedChars, MismatchedChars: Integer;
  ErrorChars: TList<string>;
  DetailedMessage: TStringBuilder;
  SpecialChar: string;
  SourceContains, TargetContains: Boolean;
begin
  ErrorChars := TList<string>.Create;
  DetailedMessage := TStringBuilder.Create;
  try
    // 将源缓冲区转换为字符串
    case SourceEncoding of
      ENCODING_UTF8, ENCODING_UTF8_BOM:
        SourceText := TEncoding.UTF8.GetString(Source);
      ENCODING_UTF16_LE:
        SourceText := TEncoding.Unicode.GetString(Source);
      ENCODING_UTF16_BE:
        SourceText := TEncoding.BigEndianUnicode.GetString(Source);
      ENCODING_GB18030, ENCODING_GBK:
        SourceText := GetTextFromAnsiBytes(Source, 936); // 936 = GBK/GB18030
      ENCODING_BIG5:
        SourceText := GetTextFromAnsiBytes(Source, 950); // 950 = Big5
      else
        SourceText := TEncoding.Default.GetString(Source);
    end;
    
    // 将目标缓冲区转换为字符串
    case TargetEncoding of
      ENCODING_UTF8, ENCODING_UTF8_BOM:
        TargetText := TEncoding.UTF8.GetString(Target);
      ENCODING_UTF16_LE:
        TargetText := TEncoding.Unicode.GetString(Target);
      ENCODING_UTF16_BE:
        TargetText := TEncoding.BigEndianUnicode.GetString(Target);
      ENCODING_GB18030, ENCODING_GBK:
        TargetText := GetTextFromAnsiBytes(Target, 936); // 936 = GBK/GB18030
      ENCODING_BIG5:
        TargetText := GetTextFromAnsiBytes(Target, 950); // 950 = Big5
      else
        TargetText := TEncoding.Default.GetString(Target);
    end;
    
    // 统计特殊字符出现情况
    TotalChars := 0;
    MatchedChars := 0;
    MismatchedChars := 0;
    
    DetailedMessage.AppendLine('特殊字符验证详情:');
    DetailedMessage.AppendLine('----------------------------');
    
    for SpecialChar in FSpecialChars.Keys do
    begin
      Inc(TotalChars);
      
      SourceContains := SourceText.Contains(SpecialChar);
      TargetContains := TargetText.Contains(SpecialChar);
      
      if SourceContains and TargetContains then
      begin
        Inc(MatchedChars);
        DetailedMessage.AppendLine(Format('字符 "%s"(U+%4.4X): 匹配成功', [SpecialChar, FSpecialChars[SpecialChar].UnicodeValue]));
      end
      else if SourceContains and not TargetContains then
      begin
        Inc(MismatchedChars);
        ErrorChars.Add(SpecialChar);
        DetailedMessage.AppendLine(Format('字符 "%s"(U+%4.4X): 源文件中存在，目标文件中丢失', [SpecialChar, FSpecialChars[SpecialChar].UnicodeValue]));
      end;
    end;
    
    DetailedMessage.AppendLine('----------------------------');
    DetailedMessage.AppendLine(Format('总计: %d 特殊字符，%d 匹配，%d 不匹配', [TotalChars, MatchedChars, MismatchedChars]));
    
    // 根据匹配情况生成结果
    if MismatchedChars = 0 then
      Result := TSpecialCharValidationResult.Create(True, TotalChars, MatchedChars, MismatchedChars, 
                                                   ErrorChars.ToArray, DetailedMessage.ToString)
    else
      Result := TSpecialCharValidationResult.Create(False, TotalChars, MatchedChars, MismatchedChars, 
                                                   ErrorChars.ToArray, DetailedMessage.ToString);
  finally
    ErrorChars.Free;
    DetailedMessage.Free;
  end;
end;

function TSpecialCharValidator.GenerateTestFile(const FileName: string; Encoding: string; IncludeTypes: TArray<TSpecialCharType>): Boolean;
var
  Content: TStringBuilder;
  FileStream: TFileStream;
  Buffer: TBytes;
  BOM: TBytes;
  CharInfo: TSpecialCharInfo;
  IncludeType: Boolean;
  I: Integer;
begin
  Result := False;
  Content := TStringBuilder.Create;
  try
    Content.AppendLine('特殊字符测试文件');
    Content.AppendLine('编码: ' + Encoding);
    Content.AppendLine('生成时间: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    Content.AppendLine('');
    
    // 按类型添加特殊字符
    for CharInfo in FSpecialChars.Values do
    begin
      IncludeType := False;
      for I := 0 to Length(IncludeTypes) - 1 do
        if CharInfo.CharType = IncludeTypes[I] then
        begin
          IncludeType := True;
          Break;
        end;
      
      if IncludeType or (Length(IncludeTypes) = 0) then
        Content.AppendLine(Format('%s (U+%4.4X): %s', [CharInfo.Character, CharInfo.UnicodeValue, CharInfo.Description]));
    end;
    
    try
      FileStream := TFileStream.Create(FileName, fmCreate);
      try
        // 根据编码添加BOM
        if (Encoding = ENCODING_UTF8_BOM) or (Encoding = 'utf-8-bom') then
        begin
          SetLength(BOM, 3);
          BOM[0] := $EF;
          BOM[1] := $BB;
          BOM[2] := $BF;
          FileStream.WriteBuffer(BOM[0], 3);
        end
        else if (Encoding = ENCODING_UTF16_LE) or (Encoding = 'utf-16le') then
        begin
          SetLength(BOM, 2);
          BOM[0] := $FF;
          BOM[1] := $FE;
          FileStream.WriteBuffer(BOM[0], 2);
        end
        else if (Encoding = ENCODING_UTF16_BE) or (Encoding = 'utf-16be') then
        begin
          SetLength(BOM, 2);
          BOM[0] := $FE;
          BOM[1] := $FF;
          FileStream.WriteBuffer(BOM[0], 2);
        end;
        
        // 将内容转换为指定编码
        case Encoding of
          ENCODING_UTF8, ENCODING_UTF8_BOM, 'utf-8', 'utf-8-bom':
            Buffer := TEncoding.UTF8.GetBytes(Content.ToString);
          ENCODING_UTF16_LE, 'utf-16le':
            Buffer := TEncoding.Unicode.GetBytes(Content.ToString);
          ENCODING_UTF16_BE, 'utf-16be':
            Buffer := TEncoding.BigEndianUnicode.GetBytes(Content.ToString);
          ENCODING_GB18030, ENCODING_GBK, 'gb18030', 'gbk':
            Buffer := GetBytesFromTextAnsi(Content.ToString, 936); // 936 = GBK/GB18030
          ENCODING_BIG5, 'big5':
            Buffer := GetBytesFromTextAnsi(Content.ToString, 950); // 950 = Big5
          else
            Buffer := TEncoding.Default.GetBytes(Content.ToString);
        end;
        
        // 写入内容
        if Length(Buffer) > 0 then
          FileStream.WriteBuffer(Buffer[0], Length(Buffer));
        
        Result := True;
      finally
        FileStream.Free;
      end;
    except
      on E: Exception do
      begin
        FLastErrorMessage := '生成测试文件时发生错误: ' + E.Message;
        Result := False;
      end;
    end;
  finally
    Content.Free;
  end;
end;

// 辅助函数: 从指定代码页的字节数组中获取字符串
function GetTextFromAnsiBytes(const Bytes: TBytes; CodePage: Integer): string;
var
  WideText: WideString;
  WideLen: Integer;
begin
  if Length(Bytes) = 0 then
    Exit('');
  
  // 计算需要的宽字符数量
  WideLen := MultiByteToWideChar(CodePage, 0, @Bytes[0], Length(Bytes), nil, 0);
  if WideLen <= 0 then
    Exit('');
  
  // 分配宽字符数组并转换
  SetLength(WideText, WideLen);
  MultiByteToWideChar(CodePage, 0, @Bytes[0], Length(Bytes), PWideChar(WideText), WideLen);
  
  Result := string(WideText);
end;

// 辅助函数: 将字符串转换为指定代码页的字节数组
function GetBytesFromTextAnsi(const Text: string; CodePage: Integer): TBytes;
var
  ByteLen: Integer;
begin
  if Text = '' then
    Exit(nil);
  
  // 计算需要的字节数量
  ByteLen := WideCharToMultiByte(CodePage, 0, PWideChar(Text), Length(Text), nil, 0, nil, nil);
  if ByteLen <= 0 then
    Exit(nil);
  
  // 分配字节数组并转换
  SetLength(Result, ByteLen);
  WideCharToMultiByte(CodePage, 0, PWideChar(Text), Length(Text), @Result[0], ByteLen, nil, nil);
end;

end. 