program ImprovedEncodingDetect;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.StrUtils,
  System.Character,
  System.Math,
  Winapi.Windows;

const
  // 最小样本大小
  MIN_SAMPLE_SIZE = 4096;
  // 最大样本大小
  MAX_SAMPLE_SIZE = 65536;

type
  TEncodingInfo = record
    Encoding: TEncoding;
    Name: string;
    Confidence: Double;
    HasBOM: Boolean;
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
function IsValidUTF8(const Buffer: TBytes): Double;
var
  I, Count: Integer;
  ByteCount: Integer;
  ValidSequences, InvalidSequences: Integer;
begin
  I := 0;
  ValidSequences := 0;
  InvalidSequences := 0;
  Count := Length(Buffer);

  while I < Count do
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
      if (I + ByteCount <= Count) and
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
      if (I + ByteCount <= Count) and
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
      if (I + ByteCount <= Count) and
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

  if (ValidSequences + InvalidSequences) > 0 then
    Result := ValidSequences / (ValidSequences + InvalidSequences)
  else
    Result := 0;
end;

// 检测ASCII编码
function IsASCII(const Buffer: TBytes): Double;
var
  I, Count: Integer;
  ASCIICount: Integer;
begin
  Count := Length(Buffer);
  ASCIICount := 0;

  for I := 0 to Count - 1 do
    if Buffer[I] < $80 then
      Inc(ASCIICount);

  if Count > 0 then
    Result := ASCIICount / Count
  else
    Result := 0;

  // 如果全是ASCII，但文件很小，可能是其他编码
  if (Result = 1.0) and (Count < 20) then
    Result := 0.8;
end;

// 检测中文编码（GBK/GB2312）
function IsChineseEncoding(const Buffer: TBytes): Double;
var
  I, Count: Integer;
  ValidPairs, InvalidPairs, TotalChars: Integer;
  ChineseCharCount, ASCIICount: Integer;
  FrequentChars: Integer;
  CharFrequency: array[0..255] of Integer;
  SecondByteFrequency: array[0..255] of Integer;
begin
  Count := Length(Buffer);
  ValidPairs := 0;
  InvalidPairs := 0;
  ChineseCharCount := 0;
  ASCIICount := 0;
  TotalChars := 0;
  FrequentChars := 0;
  I := 0;

  // 初始化频率统计数组
  FillChar(CharFrequency, SizeOf(CharFrequency), 0);
  FillChar(SecondByteFrequency, SizeOf(SecondByteFrequency), 0);

  // 第一遍：统计字节频率
  for I := 0 to Count - 1 do
  begin
    Inc(CharFrequency[Buffer[I]]);
    Inc(TotalChars);

    if Buffer[I] < $80 then
      Inc(ASCIICount);
  end;

  // 第二遍：检测中文编码特征
  I := 0;
  while I < Count - 1 do
  begin
    // GBK/GB2312的第一个字节范围
    if (Buffer[I] >= $81) and (Buffer[I] <= $FE) then
    begin
      // GBK/GB2312的第二个字节范围
      if (I + 1 < Count) and
         (((Buffer[I + 1] >= $40) and (Buffer[I + 1] <= $7E)) or
          ((Buffer[I + 1] >= $80) and (Buffer[I + 1] <= $FE))) then
      begin
        Inc(ValidPairs);
        Inc(ChineseCharCount);
        Inc(SecondByteFrequency[Buffer[I + 1]]);

        // 检测常用汉字区域
        if ((Buffer[I] >= $B0) and (Buffer[I] <= $D7)) and
           ((Buffer[I + 1] >= $A1) and (Buffer[I + 1] <= $FE)) then
          Inc(FrequentChars);
      end
      else
        Inc(InvalidPairs);
      Inc(I, 2);
    end
    else
      Inc(I);
  end;

  // 计算基本置信度
  if (ValidPairs + InvalidPairs) > 0 then
    Result := ValidPairs / (ValidPairs + InvalidPairs)
  else
    Result := 0;

  // 调整置信度
  // 1. 如果中文字符比例过低，降低置信度
  if (TotalChars > 0) and (ChineseCharCount / TotalChars < 0.1) then
    Result := Result * 0.8;

  // 2. 如果常用汉字区域字符比例较高，提高置信度
  if (ChineseCharCount > 0) and (FrequentChars / ChineseCharCount > 0.3) then
    Result := Result * 1.2;

  // 3. 如果第二字节分布符合中文特征，提高置信度
  var SecondByteDistribution := 0.0;
  var SecondByteCount := 0;
  for I := $40 to $FE do
  begin
    if SecondByteFrequency[I] > 0 then
      Inc(SecondByteCount);
  end;

  if (ChineseCharCount > 0) and (SecondByteCount > 10) then
    Result := Result * 1.1;

  // 确保置信度不超过1.0
  if Result > 1.0 then
    Result := 1.0;
end;

// 检测日文编码（Shift-JIS）
function IsJapaneseEncoding(const Buffer: TBytes): Double;
var
  I, Count: Integer;
  ValidPairs, InvalidPairs, TotalChars: Integer;
  JapaneseCharCount, ASCIICount, KanaCount: Integer;
  HiraganaCount, KatakanaCount: Integer;
  CharFrequency: array[0..255] of Integer;
  SecondByteFrequency: array[0..255] of Integer;
begin
  Count := Length(Buffer);
  ValidPairs := 0;
  InvalidPairs := 0;
  JapaneseCharCount := 0;
  ASCIICount := 0;
  KanaCount := 0;
  HiraganaCount := 0;
  KatakanaCount := 0;
  TotalChars := 0;
  I := 0;

  // 初始化频率统计数组
  FillChar(CharFrequency, SizeOf(CharFrequency), 0);
  FillChar(SecondByteFrequency, SizeOf(SecondByteFrequency), 0);

  // 第一遍：统计字节频率
  for I := 0 to Count - 1 do
  begin
    Inc(CharFrequency[Buffer[I]]);
    Inc(TotalChars);

    if Buffer[I] < $80 then
      Inc(ASCIICount)
    // 半角片假名区域
    else if (Buffer[I] >= $A1) and (Buffer[I] <= $DF) then
      Inc(KanaCount);
  end;

  // 第二遍：检测日文编码特征
  I := 0;
  while I < Count - 1 do
  begin
    // Shift-JIS的第一个字节范围
    if ((Buffer[I] >= $81) and (Buffer[I] <= $9F)) or
       ((Buffer[I] >= $E0) and (Buffer[I] <= $FC)) then
    begin
      // Shift-JIS的第二个字节范围
      if (I + 1 < Count) and
         (((Buffer[I + 1] >= $40) and (Buffer[I + 1] <= $7E)) or
          ((Buffer[I + 1] >= $80) and (Buffer[I + 1] <= $FC))) then
      begin
        Inc(ValidPairs);
        Inc(JapaneseCharCount);
        Inc(SecondByteFrequency[Buffer[I + 1]]);

        // 检测平假名区域（$82区）
        if (Buffer[I] = $82) and
           ((Buffer[I + 1] >= $9F) and (Buffer[I + 1] <= $F1)) then
          Inc(HiraganaCount);

        // 检测片假名区域（$83区）
        if (Buffer[I] = $83) and
           ((Buffer[I + 1] >= $40) and (Buffer[I + 1] <= $96)) then
          Inc(KatakanaCount);
      end
      else
        Inc(InvalidPairs);
      Inc(I, 2);
    end
    else
      Inc(I);
  end;

  // 计算基本置信度
  if (ValidPairs + InvalidPairs) > 0 then
    Result := ValidPairs / (ValidPairs + InvalidPairs)
  else
    Result := 0;

  // 调整置信度
  // 1. 如果日文字符比例过低，降低置信度
  if (TotalChars > 0) and (JapaneseCharCount / TotalChars < 0.1) then
    Result := Result * 0.8;

  // 2. 如果存在平假名或片假名，提高置信度
  if (JapaneseCharCount > 0) and ((HiraganaCount > 0) or (KatakanaCount > 0) or (KanaCount > 0)) then
    Result := Result * 1.2;

  // 3. 如果平假名和片假名都存在，这是强有力的日文标志
  if (HiraganaCount > 0) and (KatakanaCount > 0) then
    Result := Result * 1.1;

  // 4. 如果第二字节分布符合日文特征，提高置信度
  var SecondByteCount := 0;
  for I := $40 to $FC do
  begin
    if SecondByteFrequency[I] > 0 then
      Inc(SecondByteCount);
  end;

  if (JapaneseCharCount > 0) and (SecondByteCount > 10) then
    Result := Result * 1.1;

  // 确保置信度不超过1.0
  if Result > 1.0 then
    Result := 1.0;
end;

// 检测韩文编码（EUC-KR）
function IsKoreanEncoding(const Buffer: TBytes): Double;
var
  I, Count: Integer;
  ValidPairs, InvalidPairs, TotalChars: Integer;
  KoreanCharCount, ASCIICount: Integer;
  HangulCount: Integer;
  CharFrequency: array[0..255] of Integer;
  FirstByteFrequency: array[0..255] of Integer;
  SecondByteFrequency: array[0..255] of Integer;
begin
  Count := Length(Buffer);
  ValidPairs := 0;
  InvalidPairs := 0;
  KoreanCharCount := 0;
  ASCIICount := 0;
  HangulCount := 0;
  TotalChars := 0;
  I := 0;

  // 初始化频率统计数组
  FillChar(CharFrequency, SizeOf(CharFrequency), 0);
  FillChar(FirstByteFrequency, SizeOf(FirstByteFrequency), 0);
  FillChar(SecondByteFrequency, SizeOf(SecondByteFrequency), 0);

  // 第一遍：统计字节频率
  for I := 0 to Count - 1 do
  begin
    Inc(CharFrequency[Buffer[I]]);
    Inc(TotalChars);

    if Buffer[I] < $80 then
      Inc(ASCIICount);
  end;

  // 第二遍：检测韩文编码特征
  I := 0;
  while I < Count - 1 do
  begin
    // EUC-KR的第一个字节范围
    if (Buffer[I] >= $A1) and (Buffer[I] <= $FE) then
    begin
      // EUC-KR的第二个字节范围
      if (I + 1 < Count) and (Buffer[I + 1] >= $A1) and (Buffer[I + 1] <= $FE) then
      begin
        Inc(ValidPairs);
        Inc(KoreanCharCount);
        Inc(FirstByteFrequency[Buffer[I]]);
        Inc(SecondByteFrequency[Buffer[I + 1]]);

        // 检测韩文谷歌区域
        if ((Buffer[I] >= $B0) and (Buffer[I] <= $C8)) then
          Inc(HangulCount);
      end
      else
        Inc(InvalidPairs);
      Inc(I, 2);
    end
    // 检测KS X 1001编码的另一种形式（CP949）
    else if (Buffer[I] >= $81) and (Buffer[I] <= $FE) then
    begin
      if (I + 1 < Count) and
         (((Buffer[I + 1] >= $41) and (Buffer[I + 1] <= $5A)) or
          ((Buffer[I + 1] >= $61) and (Buffer[I + 1] <= $7A)) or
          ((Buffer[I + 1] >= $81) and (Buffer[I + 1] <= $FE))) then
      begin
        Inc(ValidPairs);
        Inc(KoreanCharCount);
        Inc(FirstByteFrequency[Buffer[I]]);
        Inc(SecondByteFrequency[Buffer[I + 1]]);
      end
      else
        Inc(InvalidPairs);
      Inc(I, 2);
    end
    else
      Inc(I);
  end;

  // 计算基本置信度
  if (ValidPairs + InvalidPairs) > 0 then
    Result := ValidPairs / (ValidPairs + InvalidPairs)
  else
    Result := 0;

  // 调整置信度
  // 1. 如果韩文字符比例过低，降低置信度
  if (TotalChars > 0) and (KoreanCharCount / TotalChars < 0.1) then
    Result := Result * 0.8;

  // 2. 如果韩文谷歌区域字符比例较高，提高置信度
  if (KoreanCharCount > 0) and (HangulCount / KoreanCharCount > 0.3) then
    Result := Result * 1.2;

  // 3. 分析第一字节分布
  var FirstByteCount := 0;
  for I := $A1 to $FE do
  begin
    if FirstByteFrequency[I] > 0 then
      Inc(FirstByteCount);
  end;

  // 如果第一字节分布广泛，提高置信度
  if (KoreanCharCount > 0) and (FirstByteCount > 5) then
    Result := Result * 1.1;

  // 4. 分析第二字节分布
  var SecondByteCount := 0;
  for I := $A1 to $FE do
  begin
    if SecondByteFrequency[I] > 0 then
      Inc(SecondByteCount);
  end;

  // 如果第二字节分布广泛，提高置信度
  if (KoreanCharCount > 0) and (SecondByteCount > 10) then
    Result := Result * 1.1;

  // 确保置信度不超过1.0
  if Result > 1.0 then
    Result := 1.0;
end;

// 检测Big5编码
function IsBig5Encoding(const Buffer: TBytes): Double;
var
  I, Count: Integer;
  ValidPairs, InvalidPairs, TotalChars: Integer;
  ChineseCharCount, ASCIICount: Integer;
  CommonCharCount: Integer;
  CharFrequency: array[0..255] of Integer;
  FirstByteFrequency: array[0..255] of Integer;
  SecondByteFrequency: array[0..255] of Integer;
begin
  Count := Length(Buffer);
  ValidPairs := 0;
  InvalidPairs := 0;
  ChineseCharCount := 0;
  ASCIICount := 0;
  CommonCharCount := 0;
  TotalChars := 0;
  I := 0;

  // 初始化频率统计数组
  FillChar(CharFrequency, SizeOf(CharFrequency), 0);
  FillChar(FirstByteFrequency, SizeOf(FirstByteFrequency), 0);
  FillChar(SecondByteFrequency, SizeOf(SecondByteFrequency), 0);

  // 第一遍：统计字节频率
  for I := 0 to Count - 1 do
  begin
    Inc(CharFrequency[Buffer[I]]);
    Inc(TotalChars);

    if Buffer[I] < $80 then
      Inc(ASCIICount);
  end;

  // 第二遍：检测Big5编码特征
  I := 0;
  while I < Count - 1 do
  begin
    // Big5的第一个字节范围
    if (Buffer[I] >= $A1) and (Buffer[I] <= $F9) then
    begin
      // Big5的第二个字节范围
      if (I + 1 < Count) and
         (((Buffer[I + 1] >= $40) and (Buffer[I + 1] <= $7E)) or
          ((Buffer[I + 1] >= $A1) and (Buffer[I + 1] <= $FE))) then
      begin
        Inc(ValidPairs);
        Inc(ChineseCharCount);
        Inc(FirstByteFrequency[Buffer[I]]);
        Inc(SecondByteFrequency[Buffer[I + 1]]);

        // 检测常用繁体字区域
        if ((Buffer[I] >= $A4) and (Buffer[I] <= $C6)) and
           ((Buffer[I + 1] >= $40) and (Buffer[I + 1] <= $7E)) then
          Inc(CommonCharCount);
      end
      else
        Inc(InvalidPairs);
      Inc(I, 2);
    end
    // 检测Big5-HKSCS扩展区域
    else if (Buffer[I] >= $81) and (Buffer[I] <= $A0) then
    begin
      if (I + 1 < Count) and
         (((Buffer[I + 1] >= $40) and (Buffer[I + 1] <= $7E)) or
          ((Buffer[I + 1] >= $A1) and (Buffer[I + 1] <= $FE))) then
      begin
        Inc(ValidPairs);
        Inc(ChineseCharCount);
        Inc(FirstByteFrequency[Buffer[I]]);
        Inc(SecondByteFrequency[Buffer[I + 1]]);
      end
      else
        Inc(InvalidPairs);
      Inc(I, 2);
    end
    else
      Inc(I);
  end;

  // 计算基本置信度
  if (ValidPairs + InvalidPairs) > 0 then
    Result := ValidPairs / (ValidPairs + InvalidPairs)
  else
    Result := 0;

  // 调整置信度
  // 1. 如果中文字符比例过低，降低置信度
  if (TotalChars > 0) and (ChineseCharCount / TotalChars < 0.1) then
    Result := Result * 0.8;

  // 2. 如果常用繁体字区域字符比例较高，提高置信度
  if (ChineseCharCount > 0) and (CommonCharCount / ChineseCharCount > 0.3) then
    Result := Result * 1.2;

  // 3. 分析第一字节分布
  var FirstByteCount := 0;
  for I := $A1 to $F9 do
  begin
    if FirstByteFrequency[I] > 0 then
      Inc(FirstByteCount);
  end;

  // 如果第一字节分布广泛，提高置信度
  if (ChineseCharCount > 0) and (FirstByteCount > 5) then
    Result := Result * 1.1;

  // 4. 分析第二字节分布
  var SecondByteCount := 0;
  for I := $40 to $7E do
  begin
    if SecondByteFrequency[I] > 0 then
      Inc(SecondByteCount);
  end;
  for I := $A1 to $FE do
  begin
    if SecondByteFrequency[I] > 0 then
      Inc(SecondByteCount);
  end;

  // 如果第二字节分布广泛，提高置信度
  if (ChineseCharCount > 0) and (SecondByteCount > 10) then
    Result := Result * 1.1;

  // 确保置信度不超过1.0
  if Result > 1.0 then
    Result := 1.0;
end;

// 检测EUC-JP编码
function IsEUCJPEncoding(const Buffer: TBytes): Double;
var
  I, Count: Integer;
  ValidPairs, InvalidPairs, TotalChars: Integer;
  JapaneseCharCount, ASCIICount, KanaCount: Integer;
  JIS0208Count, JIS0212Count: Integer;
  CharFrequency: array[0..255] of Integer;
  FirstByteFrequency: array[0..255] of Integer;
  SecondByteFrequency: array[0..255] of Integer;
begin
  Count := Length(Buffer);
  ValidPairs := 0;
  InvalidPairs := 0;
  JapaneseCharCount := 0;
  ASCIICount := 0;
  KanaCount := 0;
  JIS0208Count := 0;
  JIS0212Count := 0;
  TotalChars := 0;
  I := 0;

  // 初始化频率统计数组
  FillChar(CharFrequency, SizeOf(CharFrequency), 0);
  FillChar(FirstByteFrequency, SizeOf(FirstByteFrequency), 0);
  FillChar(SecondByteFrequency, SizeOf(SecondByteFrequency), 0);

  // 第一遍：统计字节频率
  for I := 0 to Count - 1 do
  begin
    Inc(CharFrequency[Buffer[I]]);
    Inc(TotalChars);

    if Buffer[I] < $80 then
      Inc(ASCIICount);
  end;

  // 第二遍：检测EUC-JP编码特征
  I := 0;
  while I < Count - 1 do
  begin
    // JIS X 0208（基本集）
    if (Buffer[I] >= $A1) and (Buffer[I] <= $FE) then
    begin
      if (I + 1 < Count) and (Buffer[I + 1] >= $A1) and (Buffer[I + 1] <= $FE) then
      begin
        Inc(ValidPairs);
        Inc(JapaneseCharCount);
        Inc(JIS0208Count);
        Inc(FirstByteFrequency[Buffer[I]]);
        Inc(SecondByteFrequency[Buffer[I + 1]]);
      end
      else
        Inc(InvalidPairs);
      Inc(I, 2);
    end
    // 半角片假名（JIS X 0201片假名）
    else if Buffer[I] = $8E then
    begin
      if (I + 1 < Count) and (Buffer[I + 1] >= $A1) and (Buffer[I + 1] <= $DF) then
      begin
        Inc(ValidPairs);
        Inc(JapaneseCharCount);
        Inc(KanaCount);
      end
      else
        Inc(InvalidPairs);
      Inc(I, 2);
    end
    // JIS X 0212-1990（补充集）
    else if Buffer[I] = $8F then
    begin
      if (I + 2 < Count) and (Buffer[I + 1] >= $A1) and (Buffer[I + 1] <= $FE) and
         (Buffer[I + 2] >= $A1) and (Buffer[I + 2] <= $FE) then
      begin
        Inc(ValidPairs);
        Inc(JapaneseCharCount);
        Inc(JIS0212Count);
      end
      else
        Inc(InvalidPairs);
      Inc(I, 3);
    end
    else
      Inc(I);
  end;

  // 计算基本置信度
  if (ValidPairs + InvalidPairs) > 0 then
    Result := ValidPairs / (ValidPairs + InvalidPairs)
  else
    Result := 0;

  // 调整置信度
  // 1. 如果日文字符比例过低，降低置信度
  if (TotalChars > 0) and (JapaneseCharCount / TotalChars < 0.1) then
    Result := Result * 0.8;

  // 2. 如果存在片假名，提高置信度
  if (JapaneseCharCount > 0) and (KanaCount > 0) then
    Result := Result * 1.2;

  // 3. 如果存在JIS X 0212字符，这是强有力的EUC-JP标志
  if (JIS0212Count > 0) then
    Result := Result * 1.3;

  // 4. 分析第一字节分布
  var FirstByteCount := 0;
  for I := $A1 to $FE do
  begin
    if FirstByteFrequency[I] > 0 then
      Inc(FirstByteCount);
  end;

  // 如果第一字节分布广泛，提高置信度
  if (JIS0208Count > 0) and (FirstByteCount > 5) then
    Result := Result * 1.1;

  // 5. 分析第二字节分布
  var SecondByteCount := 0;
  for I := $A1 to $FE do
  begin
    if SecondByteFrequency[I] > 0 then
      Inc(SecondByteCount);
  end;

  // 如果第二字节分布广泛，提高置信度
  if (JIS0208Count > 0) and (SecondByteCount > 10) then
    Result := Result * 1.1;

  // 确保置信度不超过1.0
  if Result > 1.0 then
    Result := 1.0;
end;

// 检测GB18030编码
function IsGB18030Encoding(const Buffer: TBytes): Double;
var
  I, Count: Integer;
  ValidPairs, InvalidPairs, TotalChars: Integer;
  ChineseCharCount, ASCIICount: Integer;
  TwoByteCount, FourByteCount: Integer;
  CommonCharCount: Integer;
  CharFrequency: array[0..255] of Integer;
  FirstByteFrequency: array[0..255] of Integer;
  SecondByteFrequency: array[0..255] of Integer;
begin
  Count := Length(Buffer);
  ValidPairs := 0;
  InvalidPairs := 0;
  ChineseCharCount := 0;
  ASCIICount := 0;
  TwoByteCount := 0;
  FourByteCount := 0;
  CommonCharCount := 0;
  TotalChars := 0;
  I := 0;

  // 初始化频率统计数组
  FillChar(CharFrequency, SizeOf(CharFrequency), 0);
  FillChar(FirstByteFrequency, SizeOf(FirstByteFrequency), 0);
  FillChar(SecondByteFrequency, SizeOf(SecondByteFrequency), 0);

  // 第一遍：统计字节频率
  for I := 0 to Count - 1 do
  begin
    Inc(CharFrequency[Buffer[I]]);
    Inc(TotalChars);

    if Buffer[I] < $80 then
      Inc(ASCIICount);
  end;

  // 第二遍：检测GB18030编码特征
  I := 0;
  while I < Count - 1 do
  begin
    // GB18030的第一个字节范围
    if (Buffer[I] >= $81) and (Buffer[I] <= $FE) then
    begin
      // 两字节序列
      if (I + 1 < Count) and
         (((Buffer[I + 1] >= $40) and (Buffer[I + 1] <= $7E)) or
          ((Buffer[I + 1] >= $80) and (Buffer[I + 1] <= $FE))) then
      begin
        Inc(ValidPairs);
        Inc(ChineseCharCount);
        Inc(TwoByteCount);
        Inc(FirstByteFrequency[Buffer[I]]);
        Inc(SecondByteFrequency[Buffer[I + 1]]);

        // 检测常用汉字区域
        if ((Buffer[I] >= $B0) and (Buffer[I] <= $D7)) and
           (((Buffer[I + 1] >= $A1) and (Buffer[I + 1] <= $FE)) or
            ((Buffer[I + 1] >= $40) and (Buffer[I + 1] <= $7E))) then
          Inc(CommonCharCount);

        Inc(I, 2);
      end
      // 四字节序列（GB18030特有）
      else if (I + 3 < Count) and
              (Buffer[I + 1] >= $30) and (Buffer[I + 1] <= $39) and
              (Buffer[I + 2] >= $81) and (Buffer[I + 2] <= $FE) and
              (Buffer[I + 3] >= $30) and (Buffer[I + 3] <= $39) then
      begin
        Inc(ValidPairs);
        Inc(ChineseCharCount);
        Inc(FourByteCount);
        Inc(I, 4);
      end
      else
      begin
        Inc(InvalidPairs);
        Inc(I);
      end;
    end
    else
      Inc(I);
  end;

  // 计算基本置信度
  if (ValidPairs + InvalidPairs) > 0 then
    Result := ValidPairs / (ValidPairs + InvalidPairs)
  else
    Result := 0;

  // 调整置信度
  // 1. 如果中文字符比例过低，降低置信度
  if (TotalChars > 0) and (ChineseCharCount / TotalChars < 0.1) then
    Result := Result * 0.8;

  // 2. 如果常用汉字区域字符比例较高，提高置信度
  if (ChineseCharCount > 0) and (CommonCharCount / ChineseCharCount > 0.3) then
    Result := Result * 1.1;

  // 3. 如果存在四字节序列，这是强有力的GB18030标志
  if (FourByteCount > 0) then
    Result := Result * 1.5;

  // 4. 分析第一字节分布
  var FirstByteCount := 0;
  for I := $81 to $FE do
  begin
    if FirstByteFrequency[I] > 0 then
      Inc(FirstByteCount);
  end;

  // 如果第一字节分布广泛，提高置信度
  if (ChineseCharCount > 0) and (FirstByteCount > 5) then
    Result := Result * 1.1;

  // 5. 分析第二字节分布
  var SecondByteCount := 0;
  for I := $40 to $7E do
  begin
    if SecondByteFrequency[I] > 0 then
      Inc(SecondByteCount);
  end;
  for I := $80 to $FE do
  begin
    if SecondByteFrequency[I] > 0 then
      Inc(SecondByteCount);
  end;

  // 如果第二字节分布广泛，提高置信度
  if (ChineseCharCount > 0) and (SecondByteCount > 10) then
    Result := Result * 1.1;

  // 确保置信度不超过1.0
  if Result > 1.0 then
    Result := 1.0;
end;

// 检测ISO-8859系列编码
function IsISO8859Encoding(const Buffer: TBytes): Double;
var
  I, Count: Integer;
  ValidChars, InvalidChars, TotalChars: Integer;
  ASCIICount, ExtendedCount: Integer;
  ControlCount, LatinCount, CyrillicCount, ArabicCount, GreekCount, HebrewCount: Integer;
  CharFrequency: array[0..255] of Integer;
begin
  Count := Length(Buffer);
  ValidChars := 0;
  InvalidChars := 0;
  ASCIICount := 0;
  ExtendedCount := 0;
  ControlCount := 0;
  LatinCount := 0;
  CyrillicCount := 0;
  ArabicCount := 0;
  GreekCount := 0;
  HebrewCount := 0;
  TotalChars := 0;

  // 初始化频率统计数组
  FillChar(CharFrequency, SizeOf(CharFrequency), 0);

  // 统计字节频率
  for I := 0 to Count - 1 do
  begin
    Inc(CharFrequency[Buffer[I]]);
    Inc(TotalChars);

    // ISO-8859系列的字节范围
    if (Buffer[I] < $80) then
    begin
      Inc(ValidChars);
      Inc(ASCIICount);

      // 控制字符
      if (Buffer[I] < $20) or (Buffer[I] = $7F) then
        Inc(ControlCount);
    end
    else if (Buffer[I] >= $A0) and (Buffer[I] <= $FF) then
    begin
      Inc(ValidChars);
      Inc(ExtendedCount);

      // 检测拉丁字母区域（ISO-8859-1/2/3/4/9/15）
      if (Buffer[I] >= $C0) and (Buffer[I] <= $FF) then
        Inc(LatinCount);

      // 检测西里尔字母区域（ISO-8859-5）
      if (Buffer[I] >= $B0) and (Buffer[I] <= $F0) then
        Inc(CyrillicCount);

      // 检测阿拉伯字母区域（ISO-8859-6）
      if (Buffer[I] >= $C1) and (Buffer[I] <= $F2) then
        Inc(ArabicCount);

      // 检测希腊字母区域（ISO-8859-7）
      if (Buffer[I] >= $B4) and (Buffer[I] <= $F6) then
        Inc(GreekCount);

      // 检测希伯来字母区域（ISO-8859-8）
      if (Buffer[I] >= $E0) and (Buffer[I] <= $FA) then
        Inc(HebrewCount);
    end
    else
      Inc(InvalidChars);
  end;

  // 计算基本置信度
  if (ValidChars + InvalidChars) > 0 then
    Result := ValidChars / (ValidChars + InvalidChars)
  else
    Result := 0;

  // 调整置信度
  // 1. 如果有太多控制字符，降低置信度
  if (ASCIICount > 0) and (ControlCount / ASCIICount > 0.2) then
    Result := Result * 0.8;

  // 2. 如果没有扩展字符，降低置信度
  if (ExtendedCount = 0) and (TotalChars > 20) then
    Result := Result * 0.5;

  // 3. 根据不同语言特征调整置信度
  if (ExtendedCount > 0) then
  begin
    // 拉丁字母区域字符比例较高
    if (LatinCount / ExtendedCount > 0.5) then
      Result := Result * 1.2
    // 西里尔字母区域字符比例较高
    else if (CyrillicCount / ExtendedCount > 0.5) then
      Result := Result * 1.2
    // 阿拉伯字母区域字符比例较高
    else if (ArabicCount / ExtendedCount > 0.5) then
      Result := Result * 1.2
    // 希腊字母区域字符比例较高
    else if (GreekCount / ExtendedCount > 0.5) then
      Result := Result * 1.2
    // 希伯来字母区域字符比例较高
    else if (HebrewCount / ExtendedCount > 0.5) then
      Result := Result * 1.2;
  end;

  // 4. 分析字节分布
  var ExtendedByteCount := 0;
  for I := $A0 to $FF do
  begin
    if CharFrequency[I] > 0 then
      Inc(ExtendedByteCount);
  end;

  // 如果扩展字节分布广泛，提高置信度
  if (ExtendedCount > 0) and (ExtendedByteCount > 10) then
    Result := Result * 1.1;

  // 确保置信度不超过1.0
  if Result > 1.0 then
    Result := 1.0;
end;

// 检测Windows-125x系列编码
function IsWindows125xEncoding(const Buffer: TBytes): Double;
var
  I, Count: Integer;
  ValidChars, InvalidChars, TotalChars: Integer;
  ASCIICount, ExtendedCount, ControlCount: Integer;
  CyrillicCount, LatinCount, GreekCount, TurkishCount, ArabicCount, HebrewCount, BalticCount, VietnameseCount: Integer;
  CharFrequency: array[0..255] of Integer;
begin
  Count := Length(Buffer);
  ValidChars := 0;
  InvalidChars := 0;
  ASCIICount := 0;
  ExtendedCount := 0;
  ControlCount := 0;
  CyrillicCount := 0;
  LatinCount := 0;
  GreekCount := 0;
  TurkishCount := 0;
  ArabicCount := 0;
  HebrewCount := 0;
  BalticCount := 0;
  VietnameseCount := 0;
  TotalChars := 0;

  // 初始化频率统计数组
  FillChar(CharFrequency, SizeOf(CharFrequency), 0);

  // 统计字节频率
  for I := 0 to Count - 1 do
  begin
    Inc(CharFrequency[Buffer[I]]);
    Inc(TotalChars);

    if (Buffer[I] < $80) then
    begin
      Inc(ASCIICount);

      // 控制字符
      if (Buffer[I] < $20) or (Buffer[I] = $7F) then
        Inc(ControlCount);
    end
    else
    begin
      Inc(ExtendedCount);

      // Windows-1250 (Central European)
      if ((Buffer[I] >= $8A) and (Buffer[I] <= $90)) or
         ((Buffer[I] >= $9A) and (Buffer[I] <= $9F)) or
         ((Buffer[I] >= $A1) and (Buffer[I] <= $AC)) or
         ((Buffer[I] >= $AE) and (Buffer[I] <= $BB)) or
         ((Buffer[I] >= $C0) and (Buffer[I] <= $FF)) then
        Inc(LatinCount);

      // Windows-1251 (Cyrillic)
      if ((Buffer[I] >= $C0) and (Buffer[I] <= $FF)) or
         ((Buffer[I] >= $80) and (Buffer[I] <= $8F)) or
         ((Buffer[I] >= $90) and (Buffer[I] <= $9F)) then
        Inc(CyrillicCount);

      // Windows-1252 (Western European)
      if ((Buffer[I] >= $80) and (Buffer[I] <= $9F)) or
         ((Buffer[I] >= $A0) and (Buffer[I] <= $FF)) then
        Inc(LatinCount);

      // Windows-1253 (Greek)
      if ((Buffer[I] >= $A0) and (Buffer[I] <= $AF)) or
         ((Buffer[I] >= $B0) and (Buffer[I] <= $D1)) or
         ((Buffer[I] >= $D3) and (Buffer[I] <= $FE)) then
        Inc(GreekCount);

      // Windows-1254 (Turkish)
      if ((Buffer[I] >= $80) and (Buffer[I] <= $9F)) or
         ((Buffer[I] >= $A0) and (Buffer[I] <= $CF)) or
         ((Buffer[I] >= $D0) and (Buffer[I] <= $FC)) or
         ((Buffer[I] >= $FE) and (Buffer[I] <= $FF)) then
        Inc(TurkishCount);

      // Windows-1255 (Hebrew)
      if ((Buffer[I] >= $E0) and (Buffer[I] <= $FA)) or
         ((Buffer[I] >= $C0) and (Buffer[I] <= $D9)) then
        Inc(HebrewCount);

      // Windows-1256 (Arabic)
      if ((Buffer[I] >= $C1) and (Buffer[I] <= $F2)) then
        Inc(ArabicCount);

      // Windows-1257 (Baltic)
      if ((Buffer[I] >= $80) and (Buffer[I] <= $9F)) or
         ((Buffer[I] >= $A0) and (Buffer[I] <= $FF)) then
        Inc(BalticCount);

      // Windows-1258 (Vietnamese)
      if ((Buffer[I] >= $80) and (Buffer[I] <= $9F)) or
         ((Buffer[I] >= $A0) and (Buffer[I] <= $FF)) then
        Inc(VietnameseCount);
    end;
  end;

  // 计算基本置信度
  // Windows-125x编码实际上包含所有字节值，所以需要额外的启发式规则
  if (TotalChars > 0) then
  begin
    var NonASCIIRatio := ExtendedCount / TotalChars;

    // 如果非ASCII字符比例在合理范围内，设置基本置信度
    if (NonASCIIRatio > 0.01) and (NonASCIIRatio < 0.5) then
      Result := 0.7
    else
      Result := 0.5;
  end
  else
    Result := 0;

  // 调整置信度
  // 1. 如果有太多控制字符，降低置信度
  if (ASCIICount > 0) and (ControlCount / ASCIICount > 0.2) then
    Result := Result * 0.8;

  // 2. 如果没有扩展字符，降低置信度
  if (ExtendedCount = 0) and (TotalChars > 20) then
    Result := Result * 0.5;

  // 3. 根据不同语言特征调整置信度
  if (ExtendedCount > 0) then
  begin
    // 西里尔字母区域字符比例较高（Windows-1251）
    if (CyrillicCount / ExtendedCount > 0.5) then
      Result := Result * 1.2
    // 拉丁字母区域字符比例较高（Windows-1250/1252）
    else if (LatinCount / ExtendedCount > 0.5) then
      Result := Result * 1.2
    // 希腊字母区域字符比例较高（Windows-1253）
    else if (GreekCount / ExtendedCount > 0.5) then
      Result := Result * 1.2
    // 土耳其字母区域字符比例较高（Windows-1254）
    else if (TurkishCount / ExtendedCount > 0.5) then
      Result := Result * 1.2
    // 希伯来字母区域字符比例较高（Windows-1255）
    else if (HebrewCount / ExtendedCount > 0.5) then
      Result := Result * 1.2
    // 阿拉伯字母区域字符比例较高（Windows-1256）
    else if (ArabicCount / ExtendedCount > 0.5) then
      Result := Result * 1.2
    // 波罗的海字母区域字符比例较高（Windows-1257）
    else if (BalticCount / ExtendedCount > 0.5) then
      Result := Result * 1.2
    // 越南字母区域字符比例较高（Windows-1258）
    else if (VietnameseCount / ExtendedCount > 0.5) then
      Result := Result * 1.2;
  end;

  // 4. 分析字节分布
  var ExtendedByteCount := 0;
  for I := $80 to $FF do
  begin
    if CharFrequency[I] > 0 then
      Inc(ExtendedByteCount);
  end;

  // 如果扩展字节分布广泛，提高置信度
  if (ExtendedCount > 0) and (ExtendedByteCount > 10) then
    Result := Result * 1.1;

  // 确保置信度不超过1.0
  if Result > 1.0 then
    Result := 1.0;
end;

// 检测KOI8系列编码
function IsKOI8Encoding(const Buffer: TBytes): Double;
var
  I, Count: Integer;
  ValidChars, InvalidChars, TotalChars: Integer;
  ASCIICount, ExtendedCount, ControlCount: Integer;
  CyrillicChars, UkrainianChars: Integer;
  CharFrequency: array[0..255] of Integer;
begin
  Count := Length(Buffer);
  ValidChars := 0;
  InvalidChars := 0;
  ASCIICount := 0;
  ExtendedCount := 0;
  ControlCount := 0;
  CyrillicChars := 0;
  UkrainianChars := 0;
  TotalChars := 0;

  // 初始化频率统计数组
  FillChar(CharFrequency, SizeOf(CharFrequency), 0);

  // 统计字节频率
  for I := 0 to Count - 1 do
  begin
    Inc(CharFrequency[Buffer[I]]);
    Inc(TotalChars);

    // KOI8的字节范围
    if Buffer[I] < $80 then
    begin
      Inc(ValidChars);
      Inc(ASCIICount);

      // 控制字符
      if (Buffer[I] < $20) or (Buffer[I] = $7F) then
        Inc(ControlCount);
    end
    else if (Buffer[I] >= $80) and (Buffer[I] <= $BF) then
    begin
      Inc(ValidChars);
      Inc(ExtendedCount);
    end
    else if (Buffer[I] >= $C0) and (Buffer[I] <= $FF) then
    begin
      Inc(ValidChars);
      Inc(ExtendedCount);
      Inc(CyrillicChars);

      // KOI8-U特有的乌克兰字符
      if (Buffer[I] = $A4) or (Buffer[I] = $A6) or (Buffer[I] = $A7) or
         (Buffer[I] = $AD) or (Buffer[I] = $B4) or (Buffer[I] = $B6) or
         (Buffer[I] = $B7) or (Buffer[I] = $BD) then
        Inc(UkrainianChars);
    end
    else
      Inc(InvalidChars);
  end;

  // 计算基本置信度
  if (ValidChars + InvalidChars) > 0 then
    Result := ValidChars / (ValidChars + InvalidChars)
  else
    Result := 0;

  // 调整置信度
  // 1. 如果有太多控制字符，降低置信度
  if (ASCIICount > 0) and (ControlCount / ASCIICount > 0.2) then
    Result := Result * 0.8;

  // 2. 如果没有西里尔字符，降低置信度
  if (CyrillicChars = 0) and (TotalChars > 20) then
    Result := Result * 0.5;

  // 3. 如果有足够的西里尔字符，提高置信度
  if (TotalChars > 0) and (CyrillicChars > 0) and (CyrillicChars / TotalChars > 0.1) then
    Result := Result * 1.2;

  // 4. 如果有乌克兰特有字符，这可能是KOI8-U
  if (UkrainianChars > 0) then
    Result := Result * 1.1;

  // 5. 分析西里尔字节分布
  var CyrillicByteCount := 0;
  for I := $C0 to $FF do
  begin
    if CharFrequency[I] > 0 then
      Inc(CyrillicByteCount);
  end;

  // 如果西里尔字节分布广泛，提高置信度
  if (CyrillicChars > 0) and (CyrillicByteCount > 10) then
    Result := Result * 1.1;

  // 确保置信度不超过1.0
  if Result > 1.0 then
    Result := 1.0;
end;

// 检测文件编码
function DetectFileEncoding(const FileName: string): TEncodingInfo;
var
  FileStream: TFileStream;
  Buffer: TBytes;
  SampleSize: Integer;
  ASCIIScore, UTF8Score, ChineseScore, JapaneseScore, KoreanScore, Big5Score: Double;
  EUCJP_Score, GB18030_Score, ISO8859_Score, Windows125x_Score, KOI8_Score: Double;
begin
  Result.Encoding := nil;
  Result.Name := '';
  Result.Confidence := 0;
  Result.HasBOM := False;

  try
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      // 读取文件样本
      SampleSize := Min(FileStream.Size, MAX_SAMPLE_SIZE);
      if SampleSize < MIN_SAMPLE_SIZE then
        SampleSize := Min(FileStream.Size, MIN_SAMPLE_SIZE);

      SetLength(Buffer, SampleSize);
      FileStream.ReadBuffer(Buffer[0], SampleSize);

      // 首先检测BOM
      if DetectBOM(Buffer, Result.Encoding) then
      begin
        Result.HasBOM := True;
        if Result.Encoding = TEncoding.UTF8 then
          Result.Name := 'UTF-8'
        else if Result.Encoding = TEncoding.Unicode then
          Result.Name := 'UTF-16LE'
        else if Result.Encoding = TEncoding.BigEndianUnicode then
          Result.Name := 'UTF-16BE';
        // UTF-32 encodings handled as UTF-16 in this implementation

        Result.Confidence := 1.0;
        Exit;
      end;

      // 检测ASCII
      ASCIIScore := IsASCII(Buffer);
      if ASCIIScore > 0.99 then
      begin
        Result.Encoding := TEncoding.ASCII;
        Result.Name := 'ASCII';
        Result.Confidence := ASCIIScore;
        Exit;
      end;

      // 检测UTF-8（无BOM）
      UTF8Score := IsValidUTF8(Buffer);

      // 检测中文编码
      ChineseScore := IsChineseEncoding(Buffer);

      // 检测日文编码
      JapaneseScore := IsJapaneseEncoding(Buffer);

      // 检测韩文编码
      KoreanScore := IsKoreanEncoding(Buffer);

      // 检测Big5编码
      Big5Score := IsBig5Encoding(Buffer);

      // 检测其他编码
      EUCJP_Score := IsEUCJPEncoding(Buffer);
      GB18030_Score := IsGB18030Encoding(Buffer);
      ISO8859_Score := IsISO8859Encoding(Buffer);
      Windows125x_Score := IsWindows125xEncoding(Buffer);
      KOI8_Score := IsKOI8Encoding(Buffer);

      // 选择得分最高的编码
      if (UTF8Score > 0.9) and (UTF8Score >= ChineseScore) and (UTF8Score >= JapaneseScore) and
         (UTF8Score >= KoreanScore) and (UTF8Score >= Big5Score) and (UTF8Score >= EUCJP_Score) and
         (UTF8Score >= GB18030_Score) and (UTF8Score >= ISO8859_Score) and (UTF8Score >= Windows125x_Score) and
         (UTF8Score >= KOI8_Score) then
      begin
        Result.Encoding := TEncoding.UTF8;
        Result.Name := 'UTF-8';
        Result.Confidence := UTF8Score;
      end
      else if (GB18030_Score > 0.7) and (GB18030_Score >= UTF8Score) and (GB18030_Score >= ChineseScore) and
              (GB18030_Score >= JapaneseScore) and (GB18030_Score >= KoreanScore) and (GB18030_Score >= Big5Score) and
              (GB18030_Score >= EUCJP_Score) and (GB18030_Score >= ISO8859_Score) and (GB18030_Score >= Windows125x_Score) and
              (GB18030_Score >= KOI8_Score) then
      begin
        Result.Encoding := TEncoding.GetEncoding(54936); // GB18030
        Result.Name := 'GB18030';
        Result.Confidence := GB18030_Score;
      end
      else if (ChineseScore > 0.7) and (ChineseScore >= UTF8Score) and (ChineseScore >= JapaneseScore) and
              (ChineseScore >= KoreanScore) and (ChineseScore >= Big5Score) and (ChineseScore >= EUCJP_Score) and
              (ChineseScore >= GB18030_Score) and (ChineseScore >= ISO8859_Score) and (ChineseScore >= Windows125x_Score) and
              (ChineseScore >= KOI8_Score) then
      begin
        Result.Encoding := TEncoding.GetEncoding(936); // GBK
        Result.Name := 'GBK';
        Result.Confidence := ChineseScore;
      end
      else if (JapaneseScore > 0.7) and (JapaneseScore >= UTF8Score) and (JapaneseScore >= ChineseScore) and
              (JapaneseScore >= KoreanScore) and (JapaneseScore >= Big5Score) and (JapaneseScore >= EUCJP_Score) and
              (JapaneseScore >= GB18030_Score) and (JapaneseScore >= ISO8859_Score) and (JapaneseScore >= Windows125x_Score) and
              (JapaneseScore >= KOI8_Score) then
      begin
        Result.Encoding := TEncoding.GetEncoding(932); // Shift-JIS
        Result.Name := 'Shift-JIS';
        Result.Confidence := JapaneseScore;
      end
      else if (EUCJP_Score > 0.7) and (EUCJP_Score >= UTF8Score) and (EUCJP_Score >= ChineseScore) and
              (EUCJP_Score >= JapaneseScore) and (EUCJP_Score >= KoreanScore) and (EUCJP_Score >= Big5Score) and
              (EUCJP_Score >= GB18030_Score) and (EUCJP_Score >= ISO8859_Score) and (EUCJP_Score >= Windows125x_Score) and
              (EUCJP_Score >= KOI8_Score) then
      begin
        Result.Encoding := TEncoding.GetEncoding(51932); // EUC-JP
        Result.Name := 'EUC-JP';
        Result.Confidence := EUCJP_Score;
      end
      else if (KoreanScore > 0.7) and (KoreanScore >= UTF8Score) and (KoreanScore >= ChineseScore) and
              (KoreanScore >= JapaneseScore) and (KoreanScore >= Big5Score) and (KoreanScore >= EUCJP_Score) and
              (KoreanScore >= GB18030_Score) and (KoreanScore >= ISO8859_Score) and (KoreanScore >= Windows125x_Score) and
              (KoreanScore >= KOI8_Score) then
      begin
        Result.Encoding := TEncoding.GetEncoding(949); // EUC-KR
        Result.Name := 'EUC-KR';
        Result.Confidence := KoreanScore;
      end
      else if (Big5Score > 0.7) and (Big5Score >= UTF8Score) and (Big5Score >= ChineseScore) and
              (Big5Score >= JapaneseScore) and (Big5Score >= KoreanScore) and (Big5Score >= EUCJP_Score) and
              (Big5Score >= GB18030_Score) and (Big5Score >= ISO8859_Score) and (Big5Score >= Windows125x_Score) and
              (Big5Score >= KOI8_Score) then
      begin
        Result.Encoding := TEncoding.GetEncoding(950); // Big5
        Result.Name := 'Big5';
        Result.Confidence := Big5Score;
      end
      else if (ISO8859_Score > 0.7) and (ISO8859_Score >= UTF8Score) and (ISO8859_Score >= ChineseScore) and
              (ISO8859_Score >= JapaneseScore) and (ISO8859_Score >= KoreanScore) and (ISO8859_Score >= Big5Score) and
              (ISO8859_Score >= EUCJP_Score) and (ISO8859_Score >= GB18030_Score) and (ISO8859_Score >= Windows125x_Score) and
              (ISO8859_Score >= KOI8_Score) then
      begin
        Result.Encoding := TEncoding.GetEncoding(28591); // ISO-8859-1
        Result.Name := 'ISO-8859-1';
        Result.Confidence := ISO8859_Score;
      end
      else if (Windows125x_Score > 0.7) and (Windows125x_Score >= UTF8Score) and (Windows125x_Score >= ChineseScore) and
              (Windows125x_Score >= JapaneseScore) and (Windows125x_Score >= KoreanScore) and (Windows125x_Score >= Big5Score) and
              (Windows125x_Score >= EUCJP_Score) and (Windows125x_Score >= GB18030_Score) and (Windows125x_Score >= ISO8859_Score) and
              (Windows125x_Score >= KOI8_Score) then
      begin
        Result.Encoding := TEncoding.GetEncoding(1252); // Windows-1252
        Result.Name := 'Windows-1252';
        Result.Confidence := Windows125x_Score;
      end
      else if (KOI8_Score > 0.7) and (KOI8_Score >= UTF8Score) and (KOI8_Score >= ChineseScore) and
              (KOI8_Score >= JapaneseScore) and (KOI8_Score >= KoreanScore) and (KOI8_Score >= Big5Score) and
              (KOI8_Score >= EUCJP_Score) and (KOI8_Score >= GB18030_Score) and (KOI8_Score >= ISO8859_Score) and
              (KOI8_Score >= Windows125x_Score) then
      begin
        Result.Encoding := TEncoding.GetEncoding(20866); // KOI8-R
        Result.Name := 'KOI8-R';
        Result.Confidence := KOI8_Score;
      end
      else
      begin
        // 默认为ANSI（系统默认编码）
        Result.Encoding := TEncoding.ANSI;
        Result.Name := 'ANSI';
        Result.Confidence := 0.5;
      end;
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      Result.Encoding := nil;
      Result.Name := 'Unknown';
      Result.Confidence := 0;
    end;
  end;
end;

var
  FileName: string;
  EncodingInfo: TEncodingInfo;
  ElapsedTime: Cardinal;

begin
  try
    // 检查命令行参数
    if ParamCount < 1 then
    begin
      WriteLn('Usage: ImprovedEncodingDetect <filename>');
      Exit;
    end;

    FileName := ParamStr(1);

    // 检测文件编码
    ElapsedTime := GetTickCount;
    EncodingInfo := DetectFileEncoding(FileName);
    ElapsedTime := GetTickCount - ElapsedTime;

    // 输出结果
    WriteLn('File: ', FileName);
    WriteLn('Encoding: ', EncodingInfo.Name);
    WriteLn('Confidence: ', Format('%.2f%%', [EncodingInfo.Confidence * 100]));
    WriteLn('Has BOM: ', BoolToStr(EncodingInfo.HasBOM, True));
    WriteLn('Detection Time: ', ElapsedTime, ' ms');
  except
    on E: Exception do
      WriteLn(E.ClassName, ': ', E.Message);
  end;
end.
