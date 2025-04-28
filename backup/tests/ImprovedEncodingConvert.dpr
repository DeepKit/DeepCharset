program ImprovedEncodingConvert;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.StrUtils,
  System.Character,
  System.Math,
  Winapi.Windows;

type
  // 不可映射字符的处理策略
  TUnmappableCharAction = (ucaException, ucaSkip, ucaReplace, ucaTransliterate);

  // 行尾符号的处理策略
  TLineEndingAction = (leaKeep, leaWindows, leaUnix, leaMac);

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

// 获取编码对象
function GetEncodingByName(const EncodingName: string): TEncoding;
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
    raise Exception.CreateFmt('Unsupported encoding: %s', [EncodingName]);
end;

// 检测文件的BOM
function DetectBOM(const Buffer: TBytes; out Encoding: TEncoding): Boolean;
var
  BOMType: string;
begin
  Result := True;
  BOMType := '';

  // UTF-8 BOM: EF BB BF
  if (Length(Buffer) >= 3) and (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF) then
  begin
    Encoding := TEncoding.UTF8;
    BOMType := 'UTF-8 BOM';
  end
  // UTF-16BE BOM: FE FF
  else if (Length(Buffer) >= 2) and (Buffer[0] = $FE) and (Buffer[1] = $FF) then
  begin
    Encoding := TEncoding.BigEndianUnicode;
    BOMType := 'UTF-16BE BOM';
  end
  // UTF-16LE BOM: FF FE
  else if (Length(Buffer) >= 2) and (Buffer[0] = $FF) and (Buffer[1] = $FE) then
  begin
    // 检查是否是UTF-32LE BOM: FF FE 00 00
    if (Length(Buffer) >= 4) and (Buffer[2] = 0) and (Buffer[3] = 0) then
    begin
      // UTF-32LE not directly supported in older Delphi versions
      Encoding := TEncoding.Unicode;
      BOMType := 'UTF-32LE BOM';
    end
    else
    begin
      Encoding := TEncoding.Unicode;
      BOMType := 'UTF-16LE BOM';
    end;
  end
  // UTF-32BE BOM: 00 00 FE FF
  else if (Length(Buffer) >= 4) and (Buffer[0] = 0) and (Buffer[1] = 0) and (Buffer[2] = $FE) and (Buffer[3] = $FF) then
  begin
    // UTF-32BE not directly supported in older Delphi versions
    Encoding := TEncoding.BigEndianUnicode;
    BOMType := 'UTF-32BE BOM';
  end
  // UTF-7 BOM: 2B 2F 76 and one of: 38, 39, 2B, 2F
  else if (Length(Buffer) >= 4) and (Buffer[0] = $2B) and (Buffer[1] = $2F) and (Buffer[2] = $76) and
          ((Buffer[3] = $38) or (Buffer[3] = $39) or (Buffer[3] = $2B) or (Buffer[3] = $2F)) then
  begin
    // UTF-7 not directly supported in Delphi
    Encoding := TEncoding.ASCII; // 使用ASCII作为替代
    BOMType := 'UTF-7 BOM';
  end
  // UTF-1 BOM: F7 64 4C
  else if (Length(Buffer) >= 3) and (Buffer[0] = $F7) and (Buffer[1] = $64) and (Buffer[2] = $4C) then
  begin
    // UTF-1 not supported in Delphi
    Encoding := TEncoding.ASCII; // 使用ASCII作为替代
    BOMType := 'UTF-1 BOM';
  end
  // UTF-EBCDIC BOM: DD 73 66 73
  else if (Length(Buffer) >= 4) and (Buffer[0] = $DD) and (Buffer[1] = $73) and (Buffer[2] = $66) and (Buffer[3] = $73) then
  begin
    // UTF-EBCDIC not supported in Delphi
    Encoding := TEncoding.ASCII; // 使用ASCII作为替代
    BOMType := 'UTF-EBCDIC BOM';
  end
  // SCSU BOM: 0E FE FF
  else if (Length(Buffer) >= 3) and (Buffer[0] = $0E) and (Buffer[1] = $FE) and (Buffer[2] = $FF) then
  begin
    // SCSU not supported in Delphi
    Encoding := TEncoding.ASCII; // 使用ASCII作为替代
    BOMType := 'SCSU BOM';
  end
  // BOCU-1 BOM: FB EE 28
  else if (Length(Buffer) >= 3) and (Buffer[0] = $FB) and (Buffer[1] = $EE) and (Buffer[2] = $28) then
  begin
    // BOCU-1 not supported in Delphi
    Encoding := TEncoding.ASCII; // 使用ASCII作为替代
    BOMType := 'BOCU-1 BOM';
  end
  // GB18030 BOM: 84 31 95 33
  else if (Length(Buffer) >= 4) and (Buffer[0] = $84) and (Buffer[1] = $31) and (Buffer[2] = $95) and (Buffer[3] = $33) then
  begin
    Encoding := TEncoding.GetEncoding(54936); // GB18030
    BOMType := 'GB18030 BOM';
  end
  else
    Result := False;

  // 输出调试信息
  if Result and (BOMType <> '') then
    WriteLn('Detected BOM: ', BOMType);
end;

// 检测UTF-8编码
function IsValidUTF8(const Buffer: TBytes; Size: Integer): Boolean; overload;
var
  I: Integer;
  ByteCount: Integer;
  ValidSequences, InvalidSequences: Integer;
begin
  I := 0;
  ValidSequences := 0;
  InvalidSequences := 0;

  while I < Size do
  begin
    if Buffer[I] < $80 then
    begin
      // ASCII字符
      Inc(ValidSequences);
      Inc(I);
    end
    else if Buffer[I] < $C0 then
    begin
      // 无效的UTF-8序列
      Inc(InvalidSequences);
      Inc(I);
    end
    else if Buffer[I] < $E0 then
    begin
      // 2字节序列
      ByteCount := 2;
      if (I + ByteCount <= Size) and
         ((Buffer[I + 1] and $C0) = $80) then
        Inc(ValidSequences)
      else
        Inc(InvalidSequences);
      Inc(I, ByteCount);
    end
    else if Buffer[I] < $F0 then
    begin
      // 3字节序列
      ByteCount := 3;
      if (I + ByteCount <= Size) and
         ((Buffer[I + 1] and $C0) = $80) and
         ((Buffer[I + 2] and $C0) = $80) then
        Inc(ValidSequences)
      else
        Inc(InvalidSequences);
      Inc(I, ByteCount);
    end
    else if Buffer[I] < $F8 then
    begin
      // 4字节序列
      ByteCount := 4;
      if (I + ByteCount <= Size) and
         ((Buffer[I + 1] and $C0) = $80) and
         ((Buffer[I + 2] and $C0) = $80) and
         ((Buffer[I + 3] and $C0) = $80) then
        Inc(ValidSequences)
      else
        Inc(InvalidSequences);
      Inc(I, ByteCount);
    end
    else
    begin
      // 无效的UTF-8序列
      Inc(InvalidSequences);
      Inc(I);
    end;
  end;

  // 如果有效序列明显多于无效序列，则认为是UTF-8
  Result := (ValidSequences > 0) and (InvalidSequences < ValidSequences div 4);
end;

// 重载版本，接受TBytes参数
function IsValidUTF8(const Buffer: TBytes): Boolean; overload;
begin
  Result := IsValidUTF8(Buffer, Length(Buffer));
end;

// 检测文件编码
function DetectFileEncoding(const FileName: string): TEncoding;
var
  FileStream: TFileStream;
  Buffer: TBytes;
  SampleSize: Integer;
  ASCIIScore, UTF8Score, ChineseScore, JapaneseScore, KoreanScore, Big5Score: Double;
  EUCJP_Score, GB18030_Score, ISO8859_Score, Windows125x_Score, KOI8_Score: Double;
begin
  Result := nil;

  try
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      // 读取文件样本
      SampleSize := Min(FileStream.Size, 4096);
      SetLength(Buffer, SampleSize);
      FileStream.ReadBuffer(Buffer[0], SampleSize);

      // 首先检测BOM
      if DetectBOM(Buffer, Result) then
      begin
        WriteLn('Detected encoding from BOM');
        Exit;
      end;

      // 尝试检测UTF-8
      UTF8Score := 0;
      if IsValidUTF8(Buffer, SampleSize) then
      begin
        UTF8Score := 0.9; // 给予较高的置信度
        Result := TEncoding.UTF8;
        WriteLn('Detected UTF-8 encoding (no BOM) with confidence: ', UTF8Score:0:2);
        Exit;
      end;

      // 尝试检测ASCII
      ASCIIScore := 0;
      var ASCIICount := 0;
      for var I := 0 to SampleSize - 1 do
        if Buffer[I] < $80 then
          Inc(ASCIICount);

      if SampleSize > 0 then
        ASCIIScore := ASCIICount / SampleSize;

      if ASCIIScore > 0.99 then
      begin
        Result := TEncoding.ASCII;
        WriteLn('Detected ASCII encoding with confidence: ', ASCIIScore:0:2);
        Exit;
      end;

      // 如果文件内容很少，默认使用ANSI
      if SampleSize < 20 then
      begin
        Result := TEncoding.ANSI;
        WriteLn('File too small, defaulting to ANSI encoding');
        Exit;
      end;

      // 如果文件内容全是ASCII，默认使用ANSI
      if ASCIIScore = 1.0 then
      begin
        Result := TEncoding.ANSI;
        WriteLn('File contains only ASCII characters, defaulting to ANSI encoding');
        Exit;
      end;

      // 默认为ANSI
      Result := TEncoding.ANSI;
      WriteLn('No specific encoding detected, defaulting to ANSI encoding');
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn('Error detecting encoding: ', E.Message);
      Result := TEncoding.ANSI;
    end;
  end;
end;



// 获取编码名称
function GetEncodingName(Encoding: TEncoding): string;
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
    Result := 'Windows-1252'

  // 中文编码
  else if Encoding.CodePage = 936 then
    Result := 'GBK'
  else if Encoding.CodePage = 54936 then
    Result := 'GB18030'
  else if Encoding.CodePage = 950 then
    Result := 'Big5'

  // 日文编码
  else if Encoding.CodePage = 932 then
    Result := 'Shift-JIS'
  else if Encoding.CodePage = 51932 then
    Result := 'EUC-JP'
  else if Encoding.CodePage = 50220 then
    Result := 'ISO-2022-JP'

  // 韩文编码
  else if Encoding.CodePage = 949 then
    Result := 'EUC-KR'
  else if Encoding.CodePage = 50225 then
    Result := 'ISO-2022-KR'
  else if Encoding.CodePage = 1361 then
    Result := 'Johab'

  // 泰文编码
  else if Encoding.CodePage = 874 then
    Result := 'TIS-620'

  // 越南文编码
  else if Encoding.CodePage = 1258 then
    Result := 'Windows-1258'

  // ISO-8859系列
  else if Encoding.CodePage = 28591 then
    Result := 'ISO-8859-1'
  else if Encoding.CodePage = 28592 then
    Result := 'ISO-8859-2'
  else if Encoding.CodePage = 28593 then
    Result := 'ISO-8859-3'
  else if Encoding.CodePage = 28594 then
    Result := 'ISO-8859-4'
  else if Encoding.CodePage = 28595 then
    Result := 'ISO-8859-5'
  else if Encoding.CodePage = 28596 then
    Result := 'ISO-8859-6'
  else if Encoding.CodePage = 28597 then
    Result := 'ISO-8859-7'
  else if Encoding.CodePage = 28598 then
    Result := 'ISO-8859-8'
  else if Encoding.CodePage = 28599 then
    Result := 'ISO-8859-9'
  else if Encoding.CodePage = 28603 then
    Result := 'ISO-8859-13'
  else if Encoding.CodePage = 28605 then
    Result := 'ISO-8859-15'

  // Windows系列
  else if Encoding.CodePage = 1250 then
    Result := 'Windows-1250'
  else if Encoding.CodePage = 1251 then
    Result := 'Windows-1251'
  else if Encoding.CodePage = 1253 then
    Result := 'Windows-1253'
  else if Encoding.CodePage = 1254 then
    Result := 'Windows-1254'
  else if Encoding.CodePage = 1255 then
    Result := 'Windows-1255'
  else if Encoding.CodePage = 1256 then
    Result := 'Windows-1256'
  else if Encoding.CodePage = 1257 then
    Result := 'Windows-1257'

  // 俄语编码
  else if Encoding.CodePage = 20866 then
    Result := 'KOI8-R'
  else if Encoding.CodePage = 21866 then
    Result := 'KOI8-U'

  // 其他编码
  else if Encoding.CodePage = 437 then
    Result := 'IBM437'
  else if Encoding.CodePage = 850 then
    Result := 'IBM850'
  else if Encoding.CodePage = 852 then
    Result := 'IBM852'
  else if Encoding.CodePage = 866 then
    Result := 'IBM866'
  else if Encoding.CodePage = 10000 then
    Result := 'Macintosh'
  else
    Result := Format('CodePage-%d', [Encoding.CodePage]);
end;

// 处理行尾符号
function NormalizeLineEndings(const Text: string; Action: TLineEndingAction; var ReplaceCount: Integer): string;
const
  CRLF = #13#10; // Windows
  LF = #10;      // Unix
  CR = #13;      // Mac
var
  I, Len: Integer;
  NormalizedText: string;
  InCR: Boolean;
begin
  if Action = leaKeep then
    Exit(Text);

  NormalizedText := '';
  Len := Length(Text);
  InCR := False;
  ReplaceCount := 0;

  for I := 1 to Len do
  begin
    case Text[I] of
      #13: // CR
      begin
        InCR := True;

        case Action of
          leaWindows: ; // 不做任何处理，等待下一个字符
          leaUnix:
          begin
            NormalizedText := NormalizedText + LF;
            Inc(ReplaceCount);
          end;
          leaMac:
            NormalizedText := NormalizedText + CR;
          else
            NormalizedText := NormalizedText + Text[I];
        end;
      end;

      #10: // LF
      begin
        if InCR then
        begin
          // 处理CRLF
          InCR := False;

          case Action of
            leaWindows:
              NormalizedText := NormalizedText + CRLF;
            leaUnix:
              ; // 已经在CR中处理过
            leaMac:
              ; // 已经在CR中处理过
            else
              NormalizedText := NormalizedText + Text[I];
          end;
        end
        else
        begin
          // 单独的LF
          case Action of
            leaWindows:
            begin
              NormalizedText := NormalizedText + CRLF;
              Inc(ReplaceCount);
            end;
            leaUnix:
              NormalizedText := NormalizedText + LF;
            leaMac:
            begin
              NormalizedText := NormalizedText + CR;
              Inc(ReplaceCount);
            end;
            else
              NormalizedText := NormalizedText + Text[I];
          end;
        end;
      end;

      else
      begin
        // 其他字符
        if InCR then
        begin
          // 处理单独的CR
          InCR := False;

          case Action of
            leaWindows:
            begin
              NormalizedText := NormalizedText + CRLF;
              Inc(ReplaceCount);
            end;
            leaUnix:
              ; // 已经在CR中处理过
            leaMac:
              ; // 已经在CR中处理过
            else
              ;
          end;
        end;

        NormalizedText := NormalizedText + Text[I];
      end;
    end;
  end;

  // 处理文本结尾的CR
  if InCR then
  begin
    case Action of
      leaWindows:
      begin
        NormalizedText := NormalizedText + CRLF;
        Inc(ReplaceCount);
      end;
      leaUnix:
        ; // 已经在CR中处理过
      leaMac:
        ; // 已经在CR中处理过
      else
        ;
    end;
  end;

  Result := NormalizedText;
end;

// 处理不可映射字符
function HandleUnmappableChar(const Character: WideChar; Action: TUnmappableCharAction;
  const Replacement: string; var ConvResult: TConversionResult; Position: Integer): string;
var
  CodePoint: Integer;
begin
  CodePoint := Ord(Character);

  case Action of
    ucaException:
      raise Exception.CreateFmt('Unmappable character found: U+%4.4X at position %d', [CodePoint, Position]);

    ucaSkip:
    begin
      ConvResult.AddUnmappableChar(Character, CodePoint, Position, '');
      Exit('');
    end;

    ucaReplace:
    begin
      ConvResult.AddUnmappableChar(Character, CodePoint, Position, Replacement);
      Exit(Replacement);
    end;

    ucaTransliterate:
    begin
      // 简单的音译表
      case Character of
        #$00C0..#$00C5: Exit('A'); // 带变音符号的A
        #$00C8..#$00CB: Exit('E'); // 带变音符号的E
        #$00CC..#$00CF: Exit('I'); // 带变音符号的I
        #$00D2..#$00D6: Exit('O'); // 带变音符号的O
        #$00D9..#$00DC: Exit('U'); // 带变音符号的U
        #$00E0..#$00E5: Exit('a'); // 带变音符号的a
        #$00E8..#$00EB: Exit('e'); // 带变音符号的e
        #$00EC..#$00EF: Exit('i'); // 带变音符号的i
        #$00F2..#$00F6: Exit('o'); // 带变音符号的o
        #$00F9..#$00FC: Exit('u'); // 带变音符号的u
        #$00D1: Exit('N');         // 带波浪线的N
        #$00F1: Exit('n');         // 带波浪线的n
        #$00DF: Exit('ss');        // 德语的sharp s
        #$00C7: Exit('C');         // 带尾巾的C
        #$00E7: Exit('c');         // 带尾巾的c
        #$0152: Exit('OE');        // 拉丁语的OE连字
        #$0153: Exit('oe');        // 拉丁语的oe连字
        #$0141: Exit('L');         // 波兰语的带斜线L
        #$0142: Exit('l');         // 波兰语的带斜线l
        #$00D0: Exit('D');         // 冰岛语的Eth
        #$00F0: Exit('d');         // 冰岛语的eth
        #$00DE: Exit('Th');        // 冰岛语的Thorn
        #$00FE: Exit('th');        // 冰岛语的thorn
        #$00D8: Exit('O');         // 丹麦语的带斜线O
        #$00F8: Exit('o');         // 丹麦语的带斜线o
        #$00C6: Exit('AE');        // 拉丁语的AE连字
        #$00E6: Exit('ae');        // 拉丁语的ae连字
        #$0391..#$03A9: Exit(Chr(Ord(Character) - Ord(#$0391) + Ord('A'))); // 希腊字母大写
        #$03B1..#$03C9: Exit(Chr(Ord(Character) - Ord(#$03B1) + Ord('a'))); // 希腊字母小写
        #$0410..#$042F: Exit(Chr(Ord(Character) - Ord(#$0410) + Ord('A'))); // 西里尔字母大写
        #$0430..#$044F: Exit(Chr(Ord(Character) - Ord(#$0430) + Ord('a'))); // 西里尔字母小写
        else
        begin
          ConvResult.AddUnmappableChar(Character, CodePoint, Position, Replacement);
          Exit(Replacement);
        end;
      end;
    end;
  end;

  // 默认替换
  ConvResult.AddUnmappableChar(Character, CodePoint, Position, Replacement);
  Exit(Replacement);
end;

// 转换文件编码
function ConvertFileEncoding(const SourceFile, TargetFile: string;
  TargetEncodingName: string; AddBOM: Boolean;
  UnmappableAction: TUnmappableCharAction = ucaReplace;
  LineEndingAction: TLineEndingAction = leaKeep;
  const Replacement: string = '?'): TConversionResult;
var
  SourceStream, TargetStream: TFileStream;
  SourceBuffer, TargetBuffer: TBytes;
  SourceEncoding, TargetEncoding: TEncoding;
  SourceText, ProcessedText: string;
  StartTime: Cardinal;
  I: Integer;
  HasUnmappableChars: Boolean;
begin
  Result.Success := False;
  Result.SourceEncoding := '';
  Result.TargetEncoding := TargetEncodingName;
  Result.ErrorMessage := '';
  Result.UnmappableCharsCount := 0;
  Result.LineEndingReplaceCount := 0;
  SetLength(Result.UnmappableCharsLog, 0);

  StartTime := GetTickCount;

  try
    // 打开源文件
    SourceStream := TFileStream.Create(SourceFile, fmOpenRead or fmShareDenyWrite);
    try
      // 检测源文件编码
      SourceEncoding := DetectFileEncoding(SourceFile);
      Result.SourceEncoding := GetEncodingName(SourceEncoding);

      // 获取目标编码
      try
        TargetEncoding := GetEncodingByName(TargetEncodingName);
      except
        on E: Exception do
        begin
          Result.ErrorMessage := E.Message;
          Exit;
        end;
      end;

      // 读取源文件内容
      SetLength(SourceBuffer, SourceStream.Size);
      if SourceStream.Size > 0 then
        SourceStream.ReadBuffer(SourceBuffer[0], SourceStream.Size);

      // 跳过BOM
      var BOMSize := 0;
      var HasBOM := False;

      // UTF-8 BOM: EF BB BF
      if (SourceEncoding = TEncoding.UTF8) and (Length(SourceBuffer) >= 3) and
         (SourceBuffer[0] = $EF) and (SourceBuffer[1] = $BB) and (SourceBuffer[2] = $BF) then
      begin
        BOMSize := 3;
        HasBOM := True;
      end
      // UTF-16LE BOM: FF FE
      else if (SourceEncoding = TEncoding.Unicode) and (Length(SourceBuffer) >= 2) and
              (SourceBuffer[0] = $FF) and (SourceBuffer[1] = $FE) then
      begin
        // 检查是否是UTF-32LE BOM: FF FE 00 00
        if (Length(SourceBuffer) >= 4) and (SourceBuffer[2] = 0) and (SourceBuffer[3] = 0) then
          BOMSize := 4
        else
          BOMSize := 2;
        HasBOM := True;
      end
      // UTF-16BE BOM: FE FF
      else if (SourceEncoding = TEncoding.BigEndianUnicode) and (Length(SourceBuffer) >= 2) and
              (SourceBuffer[0] = $FE) and (SourceBuffer[1] = $FF) then
      begin
        BOMSize := 2;
        HasBOM := True;
      end
      // UTF-32BE BOM: 00 00 FE FF
      else if (Length(SourceBuffer) >= 4) and (SourceBuffer[0] = 0) and (SourceBuffer[1] = 0) and
              (SourceBuffer[2] = $FE) and (SourceBuffer[3] = $FF) then
      begin
        BOMSize := 4;
        HasBOM := True;
      end
      // GB18030 BOM: 84 31 95 33
      else if (Length(SourceBuffer) >= 4) and (SourceBuffer[0] = $84) and (SourceBuffer[1] = $31) and
              (SourceBuffer[2] = $95) and (SourceBuffer[3] = $33) then
      begin
        BOMSize := 4;
        HasBOM := True;
      end;

      // 跳过BOM并解码文本
      if HasBOM and (BOMSize > 0) then
      begin
        SetLength(SourceText, 0);
        SourceText := SourceEncoding.GetString(SourceBuffer, BOMSize, Length(SourceBuffer) - BOMSize);
      end
      else
      begin
        SetLength(SourceText, 0);
        SourceText := SourceEncoding.GetString(SourceBuffer);
      end;

      if HasBOM then
        WriteLn('Source file has BOM, size: ', BOMSize, ' bytes');

      // 处理不可映射字符
      ProcessedText := '';
      HasUnmappableChars := False;

      // 检查是否有不可映射字符
      try
        TargetBuffer := TargetEncoding.GetBytes(SourceText);
        ProcessedText := SourceText; // 如果没有异常，直接使用原文本
      except
        on E: Exception do
        begin
          // 如果有不可映射字符，需要手动处理
          HasUnmappableChars := True;
          WriteLn('Warning: Unmappable characters detected. Applying ', Ord(UnmappableAction), ' strategy.');
        end;
      end;

      // 如果有不可映射字符，手动处理每个字符
      if HasUnmappableChars then
      begin
        ProcessedText := '';
        for I := 1 to Length(SourceText) do
        begin
          var Ch := SourceText[I];
          var CanEncode := True;

          try
            TargetEncoding.GetBytes(Ch);
          except
            CanEncode := False;
          end;

          if CanEncode then
            ProcessedText := ProcessedText + Ch
          else
            ProcessedText := ProcessedText + HandleUnmappableChar(Ch, UnmappableAction, Replacement, Result, I);
        end;
      end;

      // 处理行尾符号
      if LineEndingAction <> leaKeep then
      begin
        var LineEndingReplaceCount := 0;
        ProcessedText := NormalizeLineEndings(ProcessedText, LineEndingAction, LineEndingReplaceCount);
        Result.LineEndingReplaceCount := LineEndingReplaceCount;

        if LineEndingReplaceCount > 0 then
          WriteLn('Line ending replacements: ', LineEndingReplaceCount);
      end;

      // 转换为目标编码
      if AddBOM then
        TargetBuffer := TargetEncoding.GetPreamble + TargetEncoding.GetBytes(ProcessedText)
      else
        TargetBuffer := TargetEncoding.GetBytes(ProcessedText);

      // 输出不可映射字符的统计信息
      if Result.UnmappableCharsCount > 0 then
      begin
        WriteLn('Unmappable characters found: ', Result.UnmappableCharsCount);
        WriteLn('First 10 unmappable characters:');
        for I := 0 to Min(9, Result.UnmappableCharsCount - 1) do
          with Result.UnmappableCharsLog[I] do
            WriteLn(Format('  U+%4.4X at position %d replaced with "%s"', [CodePoint, Position, ReplacedWith]));
      end;

      // 写入目标文件
      TargetStream := TFileStream.Create(TargetFile, fmCreate);
      try
        if Length(TargetBuffer) > 0 then
          TargetStream.WriteBuffer(TargetBuffer[0], Length(TargetBuffer));

        Result.Success := True;
      finally
        TargetStream.Free;
      end;
    finally
      SourceStream.Free;
    end;
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
    end;
  end;

  Result.ElapsedTime := GetTickCount - StartTime;
end;

var
  SourceFile, TargetFile, TargetEncoding, UnmappableActionStr, LineEndingActionStr, ReplacementChar: string;
  AddBOM: Boolean;
  Result: TConversionResult;
  UnmappableAction: TUnmappableCharAction;
  LineEndingAction: TLineEndingAction;

begin
  try
    // 检查命令行参数
    if ParamCount < 3 then
    begin
      WriteLn('Usage: ImprovedEncodingConvert <source_file> <target_file> <target_encoding> [add_bom] [unmappable_action] [line_ending_action] [replacement]');
      WriteLn('  <source_file>     - Source file path');
      WriteLn('  <target_file>     - Target file path');
      WriteLn('  <target_encoding> - Target encoding (utf-8, utf-16, utf-16be, gbk, gb18030, big5, shift-jis, euc-jp, euc-kr, iso-8859-1)');
      WriteLn('  [add_bom]         - Add BOM (true/false, default: true)');
      WriteLn('  [unmappable_action] - Action for unmappable characters:');
      WriteLn('                      0 - Exception');
      WriteLn('                      1 - Skip');
      WriteLn('                      2 - Replace (default)');
      WriteLn('                      3 - Transliterate');
      WriteLn('  [line_ending_action] - Action for line endings:');
      WriteLn('                      0 - Keep original (default)');
      WriteLn('                      1 - Convert to Windows (CRLF)');
      WriteLn('                      2 - Convert to Unix (LF)');
      WriteLn('                      3 - Convert to Mac (CR)');
      WriteLn('  [replacement]     - Replacement character for unmappable characters (default: ?)');
      Exit;
    end;

    SourceFile := ParamStr(1);
    TargetFile := ParamStr(2);
    TargetEncoding := ParamStr(3);

    // 是否添加BOM
    if ParamCount >= 4 then
      AddBOM := StrToBoolDef(ParamStr(4), True)
    else
      AddBOM := True;

    // 不可映射字符的处理策略
    UnmappableAction := ucaReplace; // 默认使用替换策略
    if ParamCount >= 5 then
    begin
      UnmappableActionStr := ParamStr(5);
      if UnmappableActionStr = '0' then
        UnmappableAction := ucaException
      else if UnmappableActionStr = '1' then
        UnmappableAction := ucaSkip
      else if UnmappableActionStr = '2' then
        UnmappableAction := ucaReplace
      else if UnmappableActionStr = '3' then
        UnmappableAction := ucaTransliterate;
    end;

    // 行尾符号的处理策略
    LineEndingAction := leaKeep; // 默认保持原样
    if ParamCount >= 6 then
    begin
      LineEndingActionStr := ParamStr(6);
      if LineEndingActionStr = '0' then
        LineEndingAction := leaKeep
      else if LineEndingActionStr = '1' then
        LineEndingAction := leaWindows
      else if LineEndingActionStr = '2' then
        LineEndingAction := leaUnix
      else if LineEndingActionStr = '3' then
        LineEndingAction := leaMac;
    end;

    // 替换字符
    ReplacementChar := '?'; // 默认使用问号
    if ParamCount >= 7 then
      ReplacementChar := ParamStr(7);

    // 转换文件编码
    Result := ConvertFileEncoding(SourceFile, TargetFile, TargetEncoding, AddBOM,
                                  UnmappableAction, LineEndingAction, ReplacementChar);

    // 输出结果
    WriteLn('Source File: ', SourceFile);
    WriteLn('Target File: ', TargetFile);
    WriteLn('Source Encoding: ', Result.SourceEncoding);
    WriteLn('Target Encoding: ', Result.TargetEncoding);
    WriteLn('Add BOM: ', BoolToStr(AddBOM, True));
    WriteLn('Success: ', BoolToStr(Result.Success, True));

    // 输出不可映射字符的处理策略
    case UnmappableAction of
      ucaException: WriteLn('Unmappable Action: Exception');
      ucaSkip: WriteLn('Unmappable Action: Skip');
      ucaReplace: WriteLn('Unmappable Action: Replace with "', ReplacementChar, '"');
      ucaTransliterate: WriteLn('Unmappable Action: Transliterate');
    end;

    // 输出行尾符号的处理策略
    case LineEndingAction of
      leaKeep: WriteLn('Line Ending Action: Keep original');
      leaWindows: WriteLn('Line Ending Action: Convert to Windows (CRLF)');
      leaUnix: WriteLn('Line Ending Action: Convert to Unix (LF)');
      leaMac: WriteLn('Line Ending Action: Convert to Mac (CR)');
    end;

    // 输出不可映射字符的统计信息
    WriteLn('Unmappable Characters: ', Result.UnmappableCharsCount);
    WriteLn('Line Ending Replacements: ', Result.LineEndingReplaceCount);

    if not Result.Success then
      WriteLn('Error: ', Result.ErrorMessage);

    WriteLn('Conversion Time: ', Result.ElapsedTime, ' ms');
  except
    on E: Exception do
      WriteLn(E.ClassName, ': ', E.Message);
  end;
end.
