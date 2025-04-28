unit ImprovedEncodingConverter;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.Character, System.StrUtils,
  System.Diagnostics, System.Generics.Collections, Winapi.Windows,
  UtilsEncodingConverter, UtilsEncodingTypes;

type
  // 不可映射字符的处理策略
  TUnmappableCharAction = (
    ucaException,     // 抛出异常
    ucaSkip,          // 跳过不可映射字符
    ucaReplace,       // 替换为指定字符
    ucaTransliterate  // 尝试音译
  );

  // 行尾符号的处理策略
  TLineEndingAction = (
    leaKeep,          // 保持原样
    leaWindows,       // 转换为Windows格式 (CRLF)
    leaUnix,          // 转换为Unix格式 (LF)
    leaMac            // 转换为Mac格式 (CR)
  );

  // 不可映射字符的信息
  TUnmappableCharInfo = record
    Character: WideChar;
    CodePoint: Integer;
    Position: Integer;
    ReplacedWith: string;
  end;

  // 转换结果
  TConversionResult = record
    Success: Boolean;
    SourceEncoding: string;
    TargetEncoding: string;
    ErrorMessage: string;
    ElapsedTime: Cardinal;
    UnmappableCharsCount: Integer;
    UnmappableCharsLog: array of TUnmappableCharInfo;
    LineEndingReplaceCount: Integer;
    procedure AddUnmappableChar(Character: WideChar; CodePoint, Position: Integer; ReplacedWith: string);
  end;

  // 改进版编码转换器类
  TImprovedEncodingConverter = class(TBaseEncodingConverter)
  private
    FUnmappableCharAction: TUnmappableCharAction;
    FReplaceChar: WideChar;
    FLineEndingAction: TLineEndingAction;
    FMockResult: TBytes;
    FUseMock: Boolean;

    // 获取编码对象
    function GetEncodingByName(const EncodingName: string): TEncoding;

    // 获取编码名称
    function GetEncodingName(Encoding: TEncoding): string;

    // 处理不可映射字符
    function HandleUnmappableChar(Character: WideChar; Position: Integer;
      var Result: TConversionResult): string;

    // 转换行尾符号
    function ConvertLineEndings(const Text: string; var ReplaceCount: Integer): string;
    
  protected
    function InternalConvert(const ASource: TBytes): TBytes; override;
    
  public
    constructor Create;
    destructor Destroy; override;

    // 用于测试的Mock方法
    procedure SetMockResult(const AMockResult: TBytes);
    procedure ClearMockResult;

    // 转换文件编码
    function ConvertFileEncoding(const SourceFileName, TargetFileName: string;
      SourceEncoding, TargetEncoding: TEncoding; AddBOM: Boolean = True): TConversionResult; overload;

    // 转换文件编码（使用编码名称）
    function ConvertFileEncoding(const SourceFileName, TargetFileName: string;
      const SourceEncodingName, TargetEncodingName: string; AddBOM: Boolean = True): TConversionResult; overload;

    // 转换内存中的数据编码
    function ConvertBufferEncoding(const SourceBuffer: TBytes; SourceEncoding, TargetEncoding: TEncoding;
      AddBOM: Boolean = True): TBytes; overload;

    // 转换内存中的数据编码（使用编码名称）
    function ConvertBufferEncoding(const SourceBuffer: TBytes;
      const SourceEncodingName, TargetEncodingName: string; AddBOM: Boolean = True): TBytes; overload;

    // 转换字符串编码
    function ConvertStringEncoding(const SourceString: string; SourceEncoding, TargetEncoding: TEncoding): string; overload;

    // 转换字符串编码（使用编码名称）
    function ConvertStringEncoding(const SourceString: string;
      const SourceEncodingName, TargetEncodingName: string): string; overload;

    // 实现IEncodingConverter接口的ConvertFile方法
    function ConvertFile(const ASourceFile, ATargetFile: string): Boolean; override;

    // 获取转换器名称
    function GetName: string; override;

    // 属性
    property UnmappableCharAction: TUnmappableCharAction read FUnmappableCharAction write FUnmappableCharAction;
    property ReplaceChar: WideChar read FReplaceChar write FReplaceChar;
    property LineEndingAction: TLineEndingAction read FLineEndingAction write FLineEndingAction;
  end;

// 全局函数，方便直接调用
function ConvertFileEncoding(const SourceFileName, TargetFileName: string;
  const SourceEncodingName, TargetEncodingName: string; AddBOM: Boolean = True): TConversionResult;

function ConvertBufferEncoding(const SourceBuffer: TBytes;
  const SourceEncodingName, TargetEncodingName: string; AddBOM: Boolean = True): TBytes;

function ConvertStringEncoding(const SourceString: string;
  const SourceEncodingName, TargetEncodingName: string): string;

implementation

// 添加不可映射字符信息
procedure TConversionResult.AddUnmappableChar(Character: WideChar; CodePoint, Position: Integer; ReplacedWith: string);
begin
  Inc(UnmappableCharsCount);
  SetLength(UnmappableCharsLog, UnmappableCharsCount);

  with UnmappableCharsLog[UnmappableCharsCount - 1] do
  begin
    Character := Character;
    CodePoint := CodePoint;
    Position := Position;
    ReplacedWith := ReplacedWith;
  end;
end;

// 全局函数实现
function ConvertFileEncoding(const SourceFileName, TargetFileName: string;
  const SourceEncodingName, TargetEncodingName: string; AddBOM: Boolean = True): TConversionResult;
var
  Converter: TImprovedEncodingConverter;
begin
  Converter := TImprovedEncodingConverter.Create;
  try
    Result := Converter.ConvertFileEncoding(SourceFileName, TargetFileName,
      SourceEncodingName, TargetEncodingName, AddBOM);
  finally
    Converter.Free;
  end;
end;

function ConvertBufferEncoding(const SourceBuffer: TBytes;
  const SourceEncodingName, TargetEncodingName: string; AddBOM: Boolean = True): TBytes;
var
  Converter: TImprovedEncodingConverter;
begin
  Converter := TImprovedEncodingConverter.Create;
  try
    Result := Converter.ConvertBufferEncoding(SourceBuffer,
      SourceEncodingName, TargetEncodingName, AddBOM);
  finally
    Converter.Free;
  end;
end;

function ConvertStringEncoding(const SourceString: string;
  const SourceEncodingName, TargetEncodingName: string): string;
var
  Converter: TImprovedEncodingConverter;
begin
  Converter := TImprovedEncodingConverter.Create;
  try
    Result := Converter.ConvertStringEncoding(SourceString,
      SourceEncodingName, TargetEncodingName);
  finally
    Converter.Free;
  end;
end;

{ TImprovedEncodingConverter }

constructor TImprovedEncodingConverter.Create;
begin
  inherited Create;
  FUnmappableCharAction := ucaReplace;
  FReplaceChar := '?';
  FLineEndingAction := leaKeep;
  FUseMock := False;
end;

destructor TImprovedEncodingConverter.Destroy;
begin
  if FUseMock then
    SetLength(FMockResult, 0);
  inherited;
end;

procedure TImprovedEncodingConverter.SetMockResult(const AMockResult: TBytes);
begin
  FMockResult := AMockResult;
  FUseMock := True;
end;

procedure TImprovedEncodingConverter.ClearMockResult;
begin
  SetLength(FMockResult, 0);
  FUseMock := False;
end;

function TImprovedEncodingConverter.ConvertFile(const ASourceFile, ATargetFile: string): Boolean;
var
  TargetEncoding: TTargetEncoding;
begin
  // 从继承的属性中获取目标编码
  TargetEncoding.Encoding := GetTargetEncoding;
  TargetEncoding.Name := GetTargetEncoding.EncodingName;
  TargetEncoding.CodePage := GetTargetEncoding.CodePage;
  TargetEncoding.HasBOM := True; // 默认添加BOM

  // 调用原有的方法
  var ConvResult := ConvertFileEncoding(ASourceFile, ATargetFile, 
    GetSourceEncoding, GetTargetEncoding, TargetEncoding.HasBOM);
    
  Result := ConvResult.Success;
  
  if not Result then
    SetLastError(ConvResult.ErrorMessage);
end;

function TImprovedEncodingConverter.GetName: string;
begin
  Result := 'ImprovedEncodingConverter';
end;

function TImprovedEncodingConverter.InternalConvert(const ASource: TBytes): TBytes;
begin
  if FUseMock then
  begin
    // 如果启用了Mock，直接返回Mock结果
    Result := FMockResult;
  end
  else
  begin
    // 使用标准转换
    Result := ConvertBufferEncoding(ASource, SourceEncoding, TargetEncoding, True);
  end;
end;

function TImprovedEncodingConverter.GetEncodingByName(const EncodingName: string): TEncoding;
var
  LowerName: string;
begin
  LowerName := LowerCase(EncodingName);

  // Unicode编码
  if (LowerName = 'utf-8') or (LowerName = 'utf8') then
    Result := TEncoding.UTF8
  else if (LowerName = 'utf-16') or (LowerName = 'utf16') or (LowerName = 'unicode') then
    Result := TEncoding.Unicode
  else if (LowerName = 'utf-16le') or (LowerName = 'utf16le') then
    Result := TEncoding.Unicode
  else if (LowerName = 'utf-16be') or (LowerName = 'utf16be') then
    Result := TEncoding.BigEndianUnicode
  else if (LowerName = 'utf-32') or (LowerName = 'utf32') then
    // UTF-32 not directly supported in older Delphi versions
    Result := TEncoding.Unicode
  else if (LowerName = 'utf-32le') or (LowerName = 'utf32le') then
    // UTF-32LE not directly supported in older Delphi versions
    Result := TEncoding.Unicode
  else if (LowerName = 'utf-32be') or (LowerName = 'utf32be') then
    // UTF-32BE not directly supported in older Delphi versions
    Result := TEncoding.BigEndianUnicode
  else if (LowerName = 'ascii') then
    Result := TEncoding.ASCII
  else if (LowerName = 'ansi') or (LowerName = 'windows-1252') then
    Result := TEncoding.ANSI

  // 中文编码
  else if (LowerName = 'gbk') or (LowerName = 'gb2312') or (LowerName = 'cp936') then
    Result := TEncoding.GetEncoding(936)
  else if (LowerName = 'gb18030') then
    Result := TEncoding.GetEncoding(54936)
  else if (LowerName = 'big5') or (LowerName = 'big-5') or (LowerName = 'cp950') then
    Result := TEncoding.GetEncoding(950)

  // 日文编码
  else if (LowerName = 'shift-jis') or (LowerName = 'shiftjis') or (LowerName = 'sjis') or (LowerName = 'cp932') then
    Result := TEncoding.GetEncoding(932)
  else if (LowerName = 'euc-jp') or (LowerName = 'eucjp') or (LowerName = 'cp51932') then
    Result := TEncoding.GetEncoding(51932)
  else if (LowerName = 'iso-2022-jp') then
    Result := TEncoding.GetEncoding(50220)

  // 韩文编码
  else if (LowerName = 'euc-kr') or (LowerName = 'euckr') or (LowerName = 'cp949') then
    Result := TEncoding.GetEncoding(949)
  else if (LowerName = 'iso-2022-kr') then
    Result := TEncoding.GetEncoding(50225)
  else if (LowerName = 'johab') or (LowerName = 'cp1361') then
    Result := TEncoding.GetEncoding(1361)

  // 泰文编码
  else if (LowerName = 'tis-620') or (LowerName = 'cp874') then
    Result := TEncoding.GetEncoding(874)

  // 越南文编码
  else if (LowerName = 'windows-1258') or (LowerName = 'cp1258') then
    Result := TEncoding.GetEncoding(1258)

  // ISO-8859系列
  else if (LowerName = 'iso-8859-1') or (LowerName = 'iso88591') or (LowerName = 'latin1') then
    Result := TEncoding.GetEncoding(28591)
  else if (LowerName = 'iso-8859-2') or (LowerName = 'iso88592') or (LowerName = 'latin2') then
    Result := TEncoding.GetEncoding(28592)
  else if (LowerName = 'iso-8859-3') or (LowerName = 'iso88593') or (LowerName = 'latin3') then
    Result := TEncoding.GetEncoding(28593)
  else if (LowerName = 'iso-8859-4') or (LowerName = 'iso88594') or (LowerName = 'latin4') then
    Result := TEncoding.GetEncoding(28594)
  else if (LowerName = 'iso-8859-5') or (LowerName = 'iso88595') or (LowerName = 'cyrillic') then
    Result := TEncoding.GetEncoding(28595)
  else if (LowerName = 'iso-8859-6') or (LowerName = 'iso88596') or (LowerName = 'arabic') then
    Result := TEncoding.GetEncoding(28596)
  else if (LowerName = 'iso-8859-7') or (LowerName = 'iso88597') or (LowerName = 'greek') then
    Result := TEncoding.GetEncoding(28597)
  else if (LowerName = 'iso-8859-8') or (LowerName = 'iso88598') or (LowerName = 'hebrew') then
    Result := TEncoding.GetEncoding(28598)
  else if (LowerName = 'iso-8859-9') or (LowerName = 'iso88599') or (LowerName = 'latin5') then
    Result := TEncoding.GetEncoding(28599)
  else if (LowerName = 'iso-8859-13') or (LowerName = 'iso885913') or (LowerName = 'latin7') then
    Result := TEncoding.GetEncoding(28603)
  else if (LowerName = 'iso-8859-15') or (LowerName = 'iso885915') or (LowerName = 'latin9') then
    Result := TEncoding.GetEncoding(28605)

  // Windows系列
  else if (LowerName = 'windows-1250') or (LowerName = 'cp1250') then
    Result := TEncoding.GetEncoding(1250)
  else if (LowerName = 'windows-1251') or (LowerName = 'cp1251') then
    Result := TEncoding.GetEncoding(1251)
  else if (LowerName = 'windows-1253') or (LowerName = 'cp1253') then
    Result := TEncoding.GetEncoding(1253)
  else if (LowerName = 'windows-1254') or (LowerName = 'cp1254') then
    Result := TEncoding.GetEncoding(1254)
  else if (LowerName = 'windows-1255') or (LowerName = 'cp1255') then
    Result := TEncoding.GetEncoding(1255)
  else if (LowerName = 'windows-1256') or (LowerName = 'cp1256') then
    Result := TEncoding.GetEncoding(1256)
  else if (LowerName = 'windows-1257') or (LowerName = 'cp1257') then
    Result := TEncoding.GetEncoding(1257)

  // 俄语编码
  else if (LowerName = 'koi8-r') or (LowerName = 'koi8r') then
    Result := TEncoding.GetEncoding(20866)
  else if (LowerName = 'koi8-u') or (LowerName = 'koi8u') then
    Result := TEncoding.GetEncoding(21866)

  // 其他编码
  else if (LowerName = 'ibm437') or (LowerName = 'cp437') or (LowerName = 'dos-us') then
    Result := TEncoding.GetEncoding(437)
  else if (LowerName = 'ibm850') or (LowerName = 'cp850') or (LowerName = 'dos-latin1') then
    Result := TEncoding.GetEncoding(850)
  else if (LowerName = 'ibm852') or (LowerName = 'cp852') or (LowerName = 'dos-latin2') then
    Result := TEncoding.GetEncoding(852)
  else if (LowerName = 'ibm866') or (LowerName = 'cp866') or (LowerName = 'dos-cyrillic') then
    Result := TEncoding.GetEncoding(866)
  else if (LowerName = 'macintosh') or (LowerName = 'mac') or (LowerName = 'macroman') then
    Result := TEncoding.GetEncoding(10000)
  else
    raise Exception.CreateFmt('不支持的编码: %s', [EncodingName]);
end;

function TImprovedEncodingConverter.GetEncodingName(Encoding: TEncoding): string;
begin
  // Unicode编码
  if Encoding = TEncoding.UTF8 then
    Result := 'UTF-8'
  else if Encoding = TEncoding.Unicode then
    Result := 'UTF-16LE'
  else if Encoding = TEncoding.BigEndianUnicode then
    Result := 'UTF-16BE'
  // UTF-32 encodings handled as UTF-16 in this implementation
  else if Encoding = TEncoding.ASCII then
    Result := 'ASCII'
  else if Encoding = TEncoding.ANSI then
    Result := 'ANSI'
  else
  begin
    // 根据代码页获取名称
    case Encoding.CodePage of
      936: Result := 'GBK';
      54936: Result := 'GB18030';
      950: Result := 'Big5';
      932: Result := 'Shift-JIS';
      51932: Result := 'EUC-JP';
      949: Result := 'EUC-KR';
      28591: Result := 'ISO-8859-1';
      1252: Result := 'Windows-1252';
      20866: Result := 'KOI8-R';
      else
        Result := 'CodePage-' + IntToStr(Encoding.CodePage);
    end;
  end;
end;

function TImprovedEncodingConverter.HandleUnmappableChar(Character: WideChar; Position: Integer;
  var Result: TConversionResult): string;
begin
  case FUnmappableCharAction of
    ucaException:
      raise Exception.CreateFmt('无法映射字符 %s (U+%04X) 在位置 %d',
        [Character, Ord(Character), Position]);

    ucaSkip:
      begin
        Result.AddUnmappableChar(Character, Ord(Character), Position, '');
        Exit('');
      end;

    ucaReplace:
      begin
        Result.AddUnmappableChar(Character, Ord(Character), Position, FReplaceChar);
        Exit(FReplaceChar);
      end;

    ucaTransliterate:
      begin
        // 简单的音译实现，可以根据需要扩展
        var Transliterated := '';

        // 中文常见字符音译
        case Ord(Character) of
          $4E00..$9FFF: Transliterated := '[CJK]'; // 中日韩统一表意文字
          $3400..$4DBF: Transliterated := '[CJK-A]'; // 中日韩统一表意文字扩展A
          $20000..$2A6DF: Transliterated := '[CJK-B]'; // 中日韩统一表意文字扩展B
          $2A700..$2B73F: Transliterated := '[CJK-C]'; // 中日韩统一表意文字扩展C
          $2B740..$2B81F: Transliterated := '[CJK-D]'; // 中日韩统一表意文字扩展D
          $2B820..$2CEAF: Transliterated := '[CJK-E]'; // 中日韩统一表意文字扩展E
          $2CEB0..$2EBEF: Transliterated := '[CJK-F]'; // 中日韩统一表意文字扩展F

          // 日文假名
          $3040..$309F: Transliterated := '[Hiragana]';
          $30A0..$30FF: Transliterated := '[Katakana]';

          // 韩文
          $AC00..$D7AF: Transliterated := '[Hangul]';

          // 西里尔字母
          $0400..$04FF: Transliterated := '[Cyrillic]';

          // 希腊字母
          $0370..$03FF: Transliterated := '[Greek]';

          // 阿拉伯字母
          $0600..$06FF: Transliterated := '[Arabic]';

          // 希伯来字母
          $0590..$05FF: Transliterated := '[Hebrew]';

          // 泰文
          $0E00..$0E7F: Transliterated := '[Thai]';

          else
            Transliterated := FReplaceChar;
        end;

        Result.AddUnmappableChar(Character, Ord(Character), Position, Transliterated);
        Exit(Transliterated);
      end;

    else
      begin
        Result.AddUnmappableChar(Character, Ord(Character), Position, FReplaceChar);
        Exit(FReplaceChar);
      end;
  end;
end;

function TImprovedEncodingConverter.ConvertLineEndings(const Text: string; var ReplaceCount: Integer): string;
const
  CR = #13;
  LF = #10;
  CRLF = CR + LF;
var
  I, Len: Integer;
  ResultText: string;
  CurrentChar, NextChar: Char;
begin
  if FLineEndingAction = leaKeep then
  begin
    ReplaceCount := 0;
    Exit(Text);
  end;

  Len := Length(Text);
  ResultText := '';
  ReplaceCount := 0;

  I := 1;
  while I <= Len do
  begin
    CurrentChar := Text[I];

    // 检查是否是行尾符号
    if (CurrentChar = CR) or (CurrentChar = LF) then
    begin
      // 检查是否是CRLF序列
      if (CurrentChar = CR) and (I < Len) then
      begin
        NextChar := Text[I + 1];
        if NextChar = LF then
        begin
          // 这是一个CRLF序列
          case FLineEndingAction of
            leaWindows: ResultText := ResultText + CRLF;
            leaUnix: begin ResultText := ResultText + LF; Inc(ReplaceCount); end;
            leaMac: begin ResultText := ResultText + CR; Inc(ReplaceCount); end;
          end;
          Inc(I, 2);
          Continue;
        end;
      end;

      // 单个CR或LF
      case FLineEndingAction of
        leaWindows:
          begin
            ResultText := ResultText + CRLF;
            Inc(ReplaceCount);
          end;
        leaUnix:
          begin
            ResultText := ResultText + LF;
            if CurrentChar = CR then Inc(ReplaceCount);
          end;
        leaMac:
          begin
            ResultText := ResultText + CR;
            if CurrentChar = LF then Inc(ReplaceCount);
          end;
      end;

      Inc(I);
    end
    else
    begin
      // 普通字符
      ResultText := ResultText + CurrentChar;
      Inc(I);
    end;
  end;

  Result := ResultText;
end;

function TImprovedEncodingConverter.ConvertFileEncoding(const SourceFileName, TargetFileName: string;
  SourceEncoding, TargetEncoding: TEncoding; AddBOM: Boolean): TConversionResult;
var
  SourceStream, TargetStream: TFileStream;
  SourceBuffer, TargetBuffer: TBytes;
  SourceText, TargetText: string;
  LineEndingReplaceCount: Integer;
  StopWatch: TStopwatch;
  I, Position: Integer;
  SourceChar: WideChar;
  TargetChar: string;
begin
  // 初始化结果
  Result.Success := False;
  Result.SourceEncoding := GetEncodingName(SourceEncoding);
  Result.TargetEncoding := GetEncodingName(TargetEncoding);
  Result.ErrorMessage := '';
  Result.UnmappableCharsCount := 0;
  Result.LineEndingReplaceCount := 0;
  SetLength(Result.UnmappableCharsLog, 0);

  // 开始计时
  StopWatch := TStopwatch.StartNew;

  try
    // 读取源文件
    SourceStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyWrite);
    try
      // 读取整个文件
      SetLength(SourceBuffer, SourceStream.Size);
      if SourceStream.Size > 0 then
        SourceStream.ReadBuffer(SourceBuffer[0], SourceStream.Size);
    finally
      SourceStream.Free;
    end;

    // 检查BOM
    var BOMSize := 0;
    var HasBOM := False;
    var DetectedEncoding: TEncoding := nil;

    // 如果源编码是UTF-8，检查是否有BOM
    if (SourceEncoding = TEncoding.UTF8) and (Length(SourceBuffer) >= 3) then
    begin
      if (SourceBuffer[0] = $EF) and (SourceBuffer[1] = $BB) and (SourceBuffer[2] = $BF) then
      begin
        HasBOM := True;
        BOMSize := 3;
      end;
    end
    // 如果源编码是UTF-16LE，检查是否有BOM
    else if (SourceEncoding = TEncoding.Unicode) and (Length(SourceBuffer) >= 2) then
    begin
      if (SourceBuffer[0] = $FF) and (SourceBuffer[1] = $FE) then
      begin
        HasBOM := True;
        BOMSize := 2;
      end;
    end
    // 如果源编码是UTF-16BE，检查是否有BOM
    else if (SourceEncoding = TEncoding.BigEndianUnicode) and (Length(SourceBuffer) >= 2) then
    begin
      if (SourceBuffer[0] = $FE) and (SourceBuffer[1] = $FF) then
      begin
        HasBOM := True;
        BOMSize := 2;
      end;
    end;

    // 如果有BOM，跳过BOM
    if HasBOM and (BOMSize > 0) then
    begin
      var TempBuffer: TBytes;
      SetLength(TempBuffer, Length(SourceBuffer) - BOMSize);
      if Length(TempBuffer) > 0 then
        Move(SourceBuffer[BOMSize], TempBuffer[0], Length(TempBuffer));
      SourceBuffer := TempBuffer;
    end;

    // 将字节数组转换为字符串
    SourceText := SourceEncoding.GetString(SourceBuffer);

    // 处理行尾符号
    TargetText := ConvertLineEndings(SourceText, LineEndingReplaceCount);
    Result.LineEndingReplaceCount := LineEndingReplaceCount;

    // 处理不可映射字符
    if SourceEncoding <> TargetEncoding then
    begin
      // 如果源编码和目标编码不同，需要检查每个字符是否可以映射
      var ProcessedText := '';

      for I := 1 to Length(TargetText) do
      begin
        SourceChar := TargetText[I];
        Position := I;

        // 检查字符是否可以在目标编码中表示
        var TestBytes: TBytes;
        var CanEncode := True;

        try
          TestBytes := TargetEncoding.GetBytes(SourceChar);

          // 检查转换回来是否相同
          var TestChar := TargetEncoding.GetString(TestBytes);
          if TestChar <> SourceChar then
            CanEncode := False;
        except
          CanEncode := False;
        end;

        if CanEncode then
          ProcessedText := ProcessedText + SourceChar
        else
        begin
          // 处理不可映射字符
          TargetChar := HandleUnmappableChar(SourceChar, Position, Result);
          ProcessedText := ProcessedText + TargetChar;
        end;
      end;

      TargetText := ProcessedText;
    end;

    // 将处理后的字符串转换为字节数组
    TargetBuffer := TargetEncoding.GetBytes(TargetText);

    // 如果需要添加BOM
    if AddBOM then
    begin
      var BOMBytes: TBytes;

      // 根据目标编码添加适当的BOM
      if TargetEncoding = TEncoding.UTF8 then
      begin
        SetLength(BOMBytes, 3);
        BOMBytes[0] := $EF;
        BOMBytes[1] := $BB;
        BOMBytes[2] := $BF;
      end
      else if TargetEncoding = TEncoding.Unicode then
      begin
        SetLength(BOMBytes, 2);
        BOMBytes[0] := $FF;
        BOMBytes[1] := $FE;
      end
      else if TargetEncoding = TEncoding.BigEndianUnicode then
      begin
        SetLength(BOMBytes, 2);
        BOMBytes[0] := $FE;
        BOMBytes[1] := $FF;
      end;

      // 如果有BOM，将BOM添加到目标缓冲区前面
      if Length(BOMBytes) > 0 then
      begin
        var TempBuffer: TBytes;
        SetLength(TempBuffer, Length(BOMBytes) + Length(TargetBuffer));

        if Length(BOMBytes) > 0 then
          Move(BOMBytes[0], TempBuffer[0], Length(BOMBytes));

        if Length(TargetBuffer) > 0 then
          Move(TargetBuffer[0], TempBuffer[Length(BOMBytes)], Length(TargetBuffer));

        TargetBuffer := TempBuffer;
      end;
    end;

    // 写入目标文件
    TargetStream := TFileStream.Create(TargetFileName, fmCreate);
    try
      if Length(TargetBuffer) > 0 then
        TargetStream.WriteBuffer(TargetBuffer[0], Length(TargetBuffer));
    finally
      TargetStream.Free;
    end;

    // 设置结果
    Result.Success := True;
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
    end;
  end;

  // 停止计时
  StopWatch.Stop;
  Result.ElapsedTime := StopWatch.ElapsedMilliseconds;
end;

function TImprovedEncodingConverter.ConvertFileEncoding(const SourceFileName, TargetFileName: string;
  const SourceEncodingName, TargetEncodingName: string; AddBOM: Boolean): TConversionResult;
var
  SourceEncoding, TargetEncoding: TEncoding;
begin
  try
    // 获取源编码和目标编码
    SourceEncoding := GetEncodingByName(SourceEncodingName);
    TargetEncoding := GetEncodingByName(TargetEncodingName);

    // 调用重载方法
    Result := ConvertFileEncoding(SourceFileName, TargetFileName, SourceEncoding, TargetEncoding, AddBOM);
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.SourceEncoding := SourceEncodingName;
      Result.TargetEncoding := TargetEncodingName;
      Result.ErrorMessage := E.Message;
      Result.UnmappableCharsCount := 0;
      Result.LineEndingReplaceCount := 0;
      SetLength(Result.UnmappableCharsLog, 0);
    end;
  end;
end;

function TImprovedEncodingConverter.ConvertBufferEncoding(const SourceBuffer: TBytes; SourceEncoding,
  TargetEncoding: TEncoding; AddBOM: Boolean): TBytes;
var
  SourceText, TargetText: string;
  LineEndingReplaceCount: Integer;
  I, Position: Integer;
  SourceChar: WideChar;
  TargetChar: string;
  ConversionResult: TConversionResult;
begin
  // 初始化结果
  SetLength(Result, 0);

  // 初始化转换结果
  ConversionResult.Success := False;
  ConversionResult.SourceEncoding := GetEncodingName(SourceEncoding);
  ConversionResult.TargetEncoding := GetEncodingName(TargetEncoding);
  ConversionResult.ErrorMessage := '';
  ConversionResult.UnmappableCharsCount := 0;
  ConversionResult.LineEndingReplaceCount := 0;
  SetLength(ConversionResult.UnmappableCharsLog, 0);

  try
    // 检查BOM
    var BOMSize := 0;
    var HasBOM := False;
    var DetectedEncoding: TEncoding := nil;
    var ProcessBuffer := SourceBuffer;

    // 如果源编码是UTF-8，检查是否有BOM
    if (SourceEncoding = TEncoding.UTF8) and (Length(SourceBuffer) >= 3) then
    begin
      if (SourceBuffer[0] = $EF) and (SourceBuffer[1] = $BB) and (SourceBuffer[2] = $BF) then
      begin
        HasBOM := True;
        BOMSize := 3;
      end;
    end
    // 如果源编码是UTF-16LE，检查是否有BOM
    else if (SourceEncoding = TEncoding.Unicode) and (Length(SourceBuffer) >= 2) then
    begin
      if (SourceBuffer[0] = $FF) and (SourceBuffer[1] = $FE) then
      begin
        HasBOM := True;
        BOMSize := 2;
      end;
    end
    // 如果源编码是UTF-16BE，检查是否有BOM
    else if (SourceEncoding = TEncoding.BigEndianUnicode) and (Length(SourceBuffer) >= 2) then
    begin
      if (SourceBuffer[0] = $FE) and (SourceBuffer[1] = $FF) then
      begin
        HasBOM := True;
        BOMSize := 2;
      end;
    end;

    // 如果有BOM，跳过BOM
    if HasBOM and (BOMSize > 0) then
    begin
      var TempBuffer: TBytes;
      SetLength(TempBuffer, Length(ProcessBuffer) - BOMSize);
      if Length(TempBuffer) > 0 then
        Move(ProcessBuffer[BOMSize], TempBuffer[0], Length(TempBuffer));
      ProcessBuffer := TempBuffer;
    end;

    // 将字节数组转换为字符串
    SourceText := SourceEncoding.GetString(ProcessBuffer);

    // 处理行尾符号
    TargetText := ConvertLineEndings(SourceText, LineEndingReplaceCount);
    ConversionResult.LineEndingReplaceCount := LineEndingReplaceCount;

    // 处理不可映射字符
    if SourceEncoding <> TargetEncoding then
    begin
      // 如果源编码和目标编码不同，需要检查每个字符是否可以映射
      var ProcessedText := '';

      for I := 1 to Length(TargetText) do
      begin
        SourceChar := TargetText[I];
        Position := I;

        // 检查字符是否可以在目标编码中表示
        var TestBytes: TBytes;
        var CanEncode := True;

        try
          TestBytes := TargetEncoding.GetBytes(SourceChar);

          // 检查转换回来是否相同
          var TestChar := TargetEncoding.GetString(TestBytes);
          if TestChar <> SourceChar then
            CanEncode := False;
        except
          CanEncode := False;
        end;

        if CanEncode then
          ProcessedText := ProcessedText + SourceChar
        else
        begin
          // 处理不可映射字符
          TargetChar := HandleUnmappableChar(SourceChar, Position, ConversionResult);
          ProcessedText := ProcessedText + TargetChar;
        end;
      end;

      TargetText := ProcessedText;
    end;

    // 将处理后的字符串转换为字节数组
    Result := TargetEncoding.GetBytes(TargetText);

    // 如果需要添加BOM
    if AddBOM then
    begin
      var BOMBytes: TBytes;

      // 根据目标编码添加适当的BOM
      if TargetEncoding = TEncoding.UTF8 then
      begin
        SetLength(BOMBytes, 3);
        BOMBytes[0] := $EF;
        BOMBytes[1] := $BB;
        BOMBytes[2] := $BF;
      end
      else if TargetEncoding = TEncoding.Unicode then
      begin
        SetLength(BOMBytes, 2);
        BOMBytes[0] := $FF;
        BOMBytes[1] := $FE;
      end
      else if TargetEncoding = TEncoding.BigEndianUnicode then
      begin
        SetLength(BOMBytes, 2);
        BOMBytes[0] := $FE;
        BOMBytes[1] := $FF;
      end;

      // 如果有BOM，将BOM添加到目标缓冲区前面
      if Length(BOMBytes) > 0 then
      begin
        var TempBuffer: TBytes;
        SetLength(TempBuffer, Length(BOMBytes) + Length(Result));

        if Length(BOMBytes) > 0 then
          Move(BOMBytes[0], TempBuffer[0], Length(BOMBytes));

        if Length(Result) > 0 then
          Move(Result[0], TempBuffer[Length(BOMBytes)], Length(Result));

        Result := TempBuffer;
      end;
    end;
  except
    on E: Exception do
    begin
      SetLength(Result, 0);
    end;
  end;
end;

function TImprovedEncodingConverter.ConvertBufferEncoding(const SourceBuffer: TBytes;
  const SourceEncodingName, TargetEncodingName: string; AddBOM: Boolean): TBytes;
var
  SourceEncoding, TargetEncoding: TEncoding;
begin
  try
    // 获取源编码和目标编码
    SourceEncoding := GetEncodingByName(SourceEncodingName);
    TargetEncoding := GetEncodingByName(TargetEncodingName);

    // 调用重载方法
    Result := ConvertBufferEncoding(SourceBuffer, SourceEncoding, TargetEncoding, AddBOM);
  except
    on E: Exception do
    begin
      SetLength(Result, 0);
    end;
  end;
end;

function TImprovedEncodingConverter.ConvertStringEncoding(const SourceString: string; SourceEncoding,
  TargetEncoding: TEncoding): string;
var
  SourceBytes, TargetBytes: TBytes;
  LineEndingReplaceCount: Integer;
  I, Position: Integer;
  SourceChar: WideChar;
  TargetChar: string;
  ConversionResult: TConversionResult;
begin
  // 初始化结果
  Result := '';

  // 初始化转换结果
  ConversionResult.Success := False;
  ConversionResult.SourceEncoding := GetEncodingName(SourceEncoding);
  ConversionResult.TargetEncoding := GetEncodingName(TargetEncoding);
  ConversionResult.ErrorMessage := '';
  ConversionResult.UnmappableCharsCount := 0;
  ConversionResult.LineEndingReplaceCount := 0;
  SetLength(ConversionResult.UnmappableCharsLog, 0);

  try
    // 处理行尾符号
    var ProcessedText := ConvertLineEndings(SourceString, LineEndingReplaceCount);
    ConversionResult.LineEndingReplaceCount := LineEndingReplaceCount;

    // 处理不可映射字符
    if SourceEncoding <> TargetEncoding then
    begin
      // 如果源编码和目标编码不同，需要检查每个字符是否可以映射
      var FinalText := '';

      for I := 1 to Length(ProcessedText) do
      begin
        SourceChar := ProcessedText[I];
        Position := I;

        // 检查字符是否可以在目标编码中表示
        var TestBytes: TBytes;
        var CanEncode := True;

        try
          TestBytes := TargetEncoding.GetBytes(SourceChar);

          // 检查转换回来是否相同
          var TestChar := TargetEncoding.GetString(TestBytes);
          if TestChar <> SourceChar then
            CanEncode := False;
        except
          CanEncode := False;
        end;

        if CanEncode then
          FinalText := FinalText + SourceChar
        else
        begin
          // 处理不可映射字符
          TargetChar := HandleUnmappableChar(SourceChar, Position, ConversionResult);
          FinalText := FinalText + TargetChar;
        end;
      end;

      Result := FinalText;
    end
    else
      Result := ProcessedText;
  except
    on E: Exception do
    begin
      Result := '';
    end;
  end;
end;

function TImprovedEncodingConverter.ConvertStringEncoding(const SourceString: string;
  const SourceEncodingName, TargetEncodingName: string): string;
var
  SourceEncoding, TargetEncoding: TEncoding;
begin
  try
    // 获取源编码和目标编码
    SourceEncoding := GetEncodingByName(SourceEncodingName);
    TargetEncoding := GetEncodingByName(TargetEncodingName);

    // 调用重载方法
    Result := ConvertStringEncoding(SourceString, SourceEncoding, TargetEncoding);
  except
    on E: Exception do
    begin
      Result := '';
    end;
  end;
end;

end.
