unit JclEncodingUtils;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, System.IOUtils,
  JclBOM, JclStrings, JclStringConversions, JclFileUtils, JclStreams;

type
  // 编码统计信息结构体
  TEncodingStats = record
    ValidSequences: Integer;
    InvalidSequences: Integer;
    ASCIICount: Integer;
    TotalBytes: Integer;
    ValidRatio: Double;
    MaxConsecutiveValid: Integer;
  end;

const
  // 代码页常量
  CP_ANSI = 0;  // 使用GetACP获取
  CP_UTF16LE = 1200;
  CP_UTF16BE = 1201;
  CP_UTF32LE = 12000;
  CP_UTF32BE = 12001;
  CP_ASCII = 20127;
  CP_ISO_8859_1 = 28591;
  CP_GBK = 936;
  CP_BIG5 = 950;
  CP_SHIFT_JIS = 932;
  CP_GB18030 = 54936;
  CP_EUC_JP = 20932;
  CP_EUC_KR = 949;
  CP_ISO_8859_2 = 28592; // 中欧
  CP_ISO_8859_5 = 28595; // 西里尔文
  CP_ISO_8859_6 = 28596; // 阿拉伯文
  CP_ISO_8859_7 = 28597; // 希腊文
  CP_ISO_8859_8 = 28598; // 希伯来文
  CP_ISO_8859_9 = 28599; // 土耳其文
  CP_WINDOWS_1250 = 1250; // 中欧
  CP_WINDOWS_1251 = 1251; // 西里尔文
  CP_WINDOWS_1252 = 1252; // 西欧
  CP_WINDOWS_1253 = 1253; // 希腊文
  CP_WINDOWS_1254 = 1254; // 土耳其文
  CP_WINDOWS_1255 = 1255; // 希伯来文
  CP_WINDOWS_1256 = 1256; // 阿拉伯文
  CP_WINDOWS_1257 = 1257; // 波罗的海文
  CP_WINDOWS_1258 = 1258; // 越南文

  // 编码名称常量
  ENCODING_ANSI = 'ANSI';
  ENCODING_UTF8 = 'UTF-8';
  ENCODING_UTF8_BOM = 'UTF-8 with BOM';
  ENCODING_UTF16_LE = 'UTF-16LE';
  ENCODING_UTF16_BE = 'UTF-16BE';
  ENCODING_UTF32_LE = 'UTF-32LE';
  ENCODING_UTF32_BE = 'UTF-32BE';
  ENCODING_GBK = 'GBK';
  ENCODING_GB2312 = 'GB2312';
  ENCODING_BIG5 = 'BIG5';
  ENCODING_ASCII = 'ASCII';
  ENCODING_SHIFT_JIS = 'Shift-JIS';
  ENCODING_EUC_JP = 'EUC-JP';
  ENCODING_EUC_KR = 'EUC-KR';
  ENCODING_ISO_8859_1 = 'ISO-8859-1';
  ENCODING_ISO_8859_2 = 'ISO-8859-2';
  ENCODING_ISO_8859_5 = 'ISO-8859-5';
  ENCODING_ISO_8859_6 = 'ISO-8859-6';
  ENCODING_ISO_8859_7 = 'ISO-8859-7';
  ENCODING_ISO_8859_8 = 'ISO-8859-8';
  ENCODING_ISO_8859_9 = 'ISO-8859-9';
  ENCODING_WINDOWS_1250 = 'Windows-1250';
  ENCODING_WINDOWS_1251 = 'Windows-1251';
  ENCODING_WINDOWS_1252 = 'Windows-1252';
  ENCODING_WINDOWS_1253 = 'Windows-1253';
  ENCODING_WINDOWS_1254 = 'Windows-1254';
  ENCODING_WINDOWS_1255 = 'Windows-1255';
  ENCODING_WINDOWS_1256 = 'Windows-1256';
  ENCODING_WINDOWS_1257 = 'Windows-1257';
  ENCODING_WINDOWS_1258 = 'Windows-1258';

// 编码检测辅助函数
function IsUTF8Valid(const Buffer: TBytes; Size: Integer): Boolean;
function IsGBKString(const Buffer: TBytes; Size: Integer): Boolean;
function IsBig5String(const Buffer: TBytes; Size: Integer): Boolean;
function IsShiftJISString(const Buffer: TBytes; Size: Integer): Boolean;
function IsEUCKRString(const Buffer: TBytes; Size: Integer): Boolean;
function IsDoubleByteEncoding(const Buffer: TBytes; Size: Integer;
  FirstByteRange, SecondByteRange: array of Byte; out Stats: TEncodingStats): Boolean;

// 检测文件编码
function DetectFileEncoding(const FileName: string): string;

// 获取编码的代码页
function GetEncodingCodePage(const EncodingName: string): Integer;

// 转换文件编码
function ConvertFile(const SourceFileName, TargetFileName: string;
  SourceCodePage, TargetCodePage: Integer): Boolean;

// 带BOM选项的转换文件编码
function ConvertFileWithBOM(const SourceFileName, TargetFileName: string;
  SourceCodePage, TargetCodePage: Integer; AddBOM: Boolean = False): Boolean;

// 按编码名称转换文件
function ConvertFileByName(const SourceFileName, TargetFileName: string;
  const SourceEncodingName, TargetEncodingName: string; AddBOM: Boolean = False): Boolean;

// 直接将文件转换为UTF-8 BOM格式
function ConvertFileToUTF8BOM(const SourceFileName, TargetFileName: string): Boolean;

implementation

// 检查是否是有效的UTF-8编码
// 增强版UTF-8检测函数
function IsUTF8Valid(const Buffer: TBytes; Size: Integer): Boolean;
var
  i, ValidSequences, TotalSequences, NonASCIICount, InvalidSequences: Integer;
  HasHighBit, HasChineseChars, HasJapaneseChars, HasKoreanChars: Boolean;
  UTF8Ratio, InvalidRatio: Double;
  DebugMsg: string;
  ChineseCharCount, JapaneseCharCount, KoreanCharCount: Integer;
  ConsecutiveValidSeq: Integer;
  MaxConsecutiveValidSeq: Integer;
begin
  if Size <= 0 then
    Exit(False);

  ValidSequences := 0;
  TotalSequences := 0;
  NonASCIICount := 0;
  InvalidSequences := 0;
  HasHighBit := False;
  HasChineseChars := False;
  HasJapaneseChars := False;
  HasKoreanChars := False;
  ChineseCharCount := 0;
  JapaneseCharCount := 0;
  KoreanCharCount := 0;
  ConsecutiveValidSeq := 0;
  MaxConsecutiveValidSeq := 0;
  i := 0;

  // 检查文件头部是否有中文字符
  // 如果文件开头就是中文字符，则很可能是UTF-8
  if (Size >= 3) and
     ((Buffer[0] >= $E0) and (Buffer[0] <= $EF)) and
     ((Buffer[1] >= $80) and (Buffer[1] <= $BF)) and
     ((Buffer[2] >= $80) and (Buffer[2] <= $BF)) then
  begin
    // 文件开头就是中文字符，很可能是UTF-8
    HasHighBit := True;
    Inc(NonASCIICount);
    HasChineseChars := True;
    Inc(ChineseCharCount);
  end;

  while i < Size do
  begin
    Inc(TotalSequences);

    if Buffer[i] < $80 then
    begin
      // ASCII字符
      Inc(ValidSequences);
      Inc(ConsecutiveValidSeq);
      Inc(i);
    end
    else if Buffer[i] < $C0 then
    begin
      // 无效的UTF-8序列，但不立即返回失败
      Inc(i);
      HasHighBit := True;
      Inc(NonASCIICount);
      Inc(InvalidSequences);
      ConsecutiveValidSeq := 0;
    end
    else if Buffer[i] < $E0 then
    begin
      // 2字节序列
      HasHighBit := True;
      Inc(NonASCIICount);
      if (i + 1 < Size) and ((Buffer[i+1] and $C0) = $80) then
      begin
        Inc(ValidSequences);
        Inc(ConsecutiveValidSeq);
        Inc(i, 2);
      end
      else
      begin
        Inc(i);
        Inc(InvalidSequences);
        ConsecutiveValidSeq := 0;
      end;
    end
    else if Buffer[i] < $F0 then
    begin
      // 3字节序列 - 中文字符通常在这里
      HasHighBit := True;
      Inc(NonASCIICount);
      if (i + 2 < Size) and
         ((Buffer[i+1] and $C0) = $80) and
         ((Buffer[i+2] and $C0) = $80) then
      begin
        Inc(ValidSequences);
        Inc(ConsecutiveValidSeq);

        // 检测是否是中文字符
        if (Buffer[i] >= $E4) and (Buffer[i] <= $E9) then
        begin
          HasChineseChars := True;
          Inc(ChineseCharCount);
        end
        // 检测是否是日文字符
        else if (Buffer[i] = $E3) and (Buffer[i+1] >= $81) and (Buffer[i+1] <= $83) then
        begin
          HasJapaneseChars := True;
          Inc(JapaneseCharCount);
        end
        // 检测是否是韩文字符
        else if (Buffer[i] = $EA) and (Buffer[i+1] >= $B0) and (Buffer[i+1] <= $BF) then
        begin
          HasKoreanChars := True;
          Inc(KoreanCharCount);
        end;

        Inc(i, 3);
      end
      else
      begin
        Inc(i);
        Inc(InvalidSequences);
        ConsecutiveValidSeq := 0;
      end;
    end
    else if Buffer[i] < $F8 then
    begin
      // 4字节序列
      HasHighBit := True;
      Inc(NonASCIICount);
      if (i + 3 < Size) and
         ((Buffer[i+1] and $C0) = $80) and
         ((Buffer[i+2] and $C0) = $80) and
         ((Buffer[i+3] and $C0) = $80) then
      begin
        Inc(ValidSequences);
        Inc(ConsecutiveValidSeq);
        Inc(i, 4);
      end
      else
      begin
        Inc(i);
        Inc(InvalidSequences);
        ConsecutiveValidSeq := 0;
      end;
    end
    else
    begin
      // 无效的UTF-8序列，但不立即返回失败
      Inc(i);
      HasHighBit := True;
      Inc(NonASCIICount);
      Inc(InvalidSequences);
      ConsecutiveValidSeq := 0;
    end;

    // 记录最长的连续有效序列
    if ConsecutiveValidSeq > MaxConsecutiveValidSeq then
      MaxConsecutiveValidSeq := ConsecutiveValidSeq;

    // 如果已经检查了足够多的字节，并且有足够多的有效UTF-8序列，则提前返回
    if (i > 100) and (ValidSequences > 10) and (NonASCIICount > 5) then
    begin
      if (ValidSequences / NonASCIICount) >= 0.9 then
        Exit(True);
    end;
  end;

  // 如果没有高位字节，则不能确定是UTF-8
  if not HasHighBit then
    Exit(False);

  // 如果非ASCII字符很少，则不足以判断
  if NonASCIICount < 3 then
    Exit(False);

  // 计算有效UTF-8序列的比例
  if NonASCIICount > 0 then
    UTF8Ratio := ValidSequences / NonASCIICount
  else
    UTF8Ratio := 0;

  // 计算无效序列的比例
  if NonASCIICount > 0 then
    InvalidRatio := InvalidSequences / NonASCIICount
  else
    InvalidRatio := 0;

  // 输出调试信息
  DebugMsg := string(Format('UTF8检测: 有效=%d, 无效=%d, 非ASCII=%d, 比例=%.2f, 中=%d, 日=%d, 韩=%d, 最长连续=%d',
                   [ValidSequences, InvalidSequences, NonASCIICount, UTF8Ratio,
                    ChineseCharCount, JapaneseCharCount, KoreanCharCount, MaxConsecutiveValidSeq]));
  OutputDebugString(PWideChar(DebugMsg));

  // 判断条件：
  // 1. 有效序列比例足够高
  // 2. 存在中文/日文/韩文字符
  // 3. 最长连续有效序列足够长
  Result := (UTF8Ratio >= 0.7) or // 有效序列比例足够高
            ((UTF8Ratio >= 0.5) and (MaxConsecutiveValidSeq >= 10)) or // 有连续长序列
            ((UTF8Ratio >= 0.5) and (HasChineseChars or HasJapaneseChars or HasKoreanChars)) or // 存在亚洲语言字符
            (ChineseCharCount >= 3) or // 存在多个中文字符
            (JapaneseCharCount >= 3) or // 存在多个日文字符
            (KoreanCharCount >= 3); // 存在多个韩文字符
end;

// 通用的双字节编码检测函数
function IsDoubleByteEncoding(const Buffer: TBytes; Size: Integer;
  FirstByteRange, SecondByteRange: array of Byte; out Stats: TEncodingStats): Boolean;
var
  i: Integer;
  ValidCount, ASCIICount, InvalidCount: Integer;
  ValidRatio: Double;
  ConsecutiveValidChars, MaxConsecutiveValidChars: Integer;
  IsFirstByteValid, IsSecondByteValid: Boolean;
begin
  if Size <= 0 then
    Exit(False);

  ValidCount := 0;
  ASCIICount := 0;
  InvalidCount := 0;
  ConsecutiveValidChars := 0;
  MaxConsecutiveValidChars := 0;
  i := 0;

  while i < Size do
  begin
    if Buffer[i] <= $7F then
    begin
      // ASCII范围
      Inc(ASCIICount);
      Inc(i);
      // 连续双字节字符计数重置
      ConsecutiveValidChars := 0;
    end
    else
    begin
      // 检查是否是有效的双字节字符
      IsFirstByteValid := False;
      for var j := 0 to Length(FirstByteRange) div 2 - 1 do
      begin
        if (Buffer[i] >= FirstByteRange[j*2]) and (Buffer[i] <= FirstByteRange[j*2+1]) then
        begin
          IsFirstByteValid := True;
          Break;
        end;
      end;

      if IsFirstByteValid and (i + 1 < Size) then
      begin
        IsSecondByteValid := False;
        for var j := 0 to Length(SecondByteRange) div 2 - 1 do
        begin
          if (Buffer[i+1] >= SecondByteRange[j*2]) and (Buffer[i+1] <= SecondByteRange[j*2+1]) then
          begin
            IsSecondByteValid := True;
            Break;
          end;
        end;

        if IsSecondByteValid then
        begin
          // 有效的双字节字符
          Inc(ValidCount);
          Inc(ConsecutiveValidChars);
          if ConsecutiveValidChars > MaxConsecutiveValidChars then
            MaxConsecutiveValidChars := ConsecutiveValidChars;
          Inc(i, 2);
          Continue;
        end;
      end;

      // 不是有效的双字节字符
      Inc(InvalidCount);
      Inc(i);
      ConsecutiveValidChars := 0;
    end;
  end;

  // 计算有效字符的比例
  if (ValidCount + InvalidCount) > 0 then
    ValidRatio := ValidCount / (ValidCount + InvalidCount)
  else
    ValidRatio := 0;

  // 填充统计信息
  Stats.ValidSequences := ValidCount;
  Stats.ASCIICount := ASCIICount;
  Stats.InvalidSequences := InvalidCount;
  Stats.ValidRatio := ValidRatio;
  Stats.MaxConsecutiveValid := MaxConsecutiveValidChars;
  Stats.TotalBytes := Size;

  // 判断条件：存在有效字符且比例足够高
  Result := (ValidCount > 0) and
            ((ValidRatio >= 0.6) or (MaxConsecutiveValidChars >= 3));
end;

// 检查是否是GBK或GB2312编码
function IsGBKString(const Buffer: TBytes; Size: Integer): Boolean;
var
  Stats: TEncodingStats;
  GBKFirstByteRange: array[0..1] of Byte;
  GBKSecondByteRange: array[0..3] of Byte;
  GB2312FirstByteRange: array[0..1] of Byte;
  GB2312SecondByteRange: array[0..1] of Byte;
  GB2312Stats: TEncodingStats;
  DebugMsg: string;
  IsGB2312Only: Boolean;
begin
  if Size <= 0 then
    Exit(False);

  // GBK编码范围
  GBKFirstByteRange[0] := $81; GBKFirstByteRange[1] := $FE;
  GBKSecondByteRange[0] := $40; GBKSecondByteRange[1] := $7E;
  GBKSecondByteRange[2] := $80; GBKSecondByteRange[3] := $FE;

  // GB2312编码范围
  GB2312FirstByteRange[0] := $A1; GB2312FirstByteRange[1] := $F7;
  GB2312SecondByteRange[0] := $A1; GB2312SecondByteRange[1] := $FE;

  // 检测GBK
  Result := IsDoubleByteEncoding(Buffer, Size, GBKFirstByteRange, GBKSecondByteRange, Stats);

  // 如果是GBK，再检测是否是GB2312
  if Result then
  begin
    IsDoubleByteEncoding(Buffer, Size, GB2312FirstByteRange, GB2312SecondByteRange, GB2312Stats);
    IsGB2312Only := (GB2312Stats.ValidSequences > 0) and (GB2312Stats.ValidSequences = Stats.ValidSequences);

    // 输出调试信息
    DebugMsg := string(Format('GBK/GB2312检测: GBK=%d, GB2312=%d, ASCII=%d, 无效=%d, 比例=%.2f, 连续=%d',
                     [Stats.ValidSequences, GB2312Stats.ValidSequences, Stats.ASCIICount,
                      Stats.InvalidSequences, Stats.ValidRatio, Stats.MaxConsecutiveValid]));
    OutputDebugString(PWideChar(DebugMsg));

    // 如果文件中只有GB2312字符，则在调试信息中标记
    if IsGB2312Only then
    begin
      DebugMsg := '文件只包含GB2312字符，应该使用GB2312编码';
      OutputDebugString(PWideChar(DebugMsg));
    end;
  end;
end;

// 检测是否为Big5编码
function IsBig5String(const Buffer: TBytes; Size: Integer): Boolean;
var
  Stats: TEncodingStats;
  Big5FirstByteRange: array[0..1] of Byte;
  Big5SecondByteRange: array[0..3] of Byte;
  DebugMsg: string;
begin
  if Size <= 0 then
    Exit(False);

  // Big5编码范围
  Big5FirstByteRange[0] := $A1; Big5FirstByteRange[1] := $F9;
  Big5SecondByteRange[0] := $40; Big5SecondByteRange[1] := $7E;
  Big5SecondByteRange[2] := $A1; Big5SecondByteRange[3] := $FE;

  // 检测Big5
  Result := IsDoubleByteEncoding(Buffer, Size, Big5FirstByteRange, Big5SecondByteRange, Stats);

  if Result then
  begin
    // 输出调试信息
    DebugMsg := string(Format('Big5检测: 有效=%d, ASCII=%d, 无效=%d, 比例=%.2f, 连续=%d',
                     [Stats.ValidSequences, Stats.ASCIICount, Stats.InvalidSequences,
                      Stats.ValidRatio, Stats.MaxConsecutiveValid]));
    OutputDebugString(PWideChar(DebugMsg));
  end;
end;

// 检测是否为Shift-JIS编码
function IsShiftJISString(const Buffer: TBytes; Size: Integer): Boolean;
var
  Stats: TEncodingStats;
  SJISFirstByteRange: array[0..3] of Byte;
  SJISSecondByteRange: array[0..3] of Byte;
  DebugMsg: string;
begin
  if Size <= 0 then
    Exit(False);

  // Shift-JIS编码范围
  SJISFirstByteRange[0] := $81; SJISFirstByteRange[1] := $9F;
  SJISFirstByteRange[2] := $E0; SJISFirstByteRange[3] := $FC;
  SJISSecondByteRange[0] := $40; SJISSecondByteRange[1] := $7E;
  SJISSecondByteRange[2] := $80; SJISSecondByteRange[3] := $FC;

  // 检测Shift-JIS
  Result := IsDoubleByteEncoding(Buffer, Size, SJISFirstByteRange, SJISSecondByteRange, Stats);

  if Result then
  begin
    // 输出调试信息
    DebugMsg := string(Format('Shift-JIS检测: 有效=%d, ASCII=%d, 无效=%d, 比例=%.2f, 连续=%d',
                     [Stats.ValidSequences, Stats.ASCIICount, Stats.InvalidSequences,
                      Stats.ValidRatio, Stats.MaxConsecutiveValid]));
    OutputDebugString(PWideChar(DebugMsg));
  end;
end;

// 检测是否为EUC-KR编码
function IsEUCKRString(const Buffer: TBytes; Size: Integer): Boolean;
var
  Stats: TEncodingStats;
  EUCKRFirstByteRange: array[0..1] of Byte;
  EUCKRSecondByteRange: array[0..1] of Byte;
  DebugMsg: string;
begin
  if Size <= 0 then
    Exit(False);

  // EUC-KR编码范围
  EUCKRFirstByteRange[0] := $A1; EUCKRFirstByteRange[1] := $FE;
  EUCKRSecondByteRange[0] := $A1; EUCKRSecondByteRange[1] := $FE;

  // 检测EUC-KR
  Result := IsDoubleByteEncoding(Buffer, Size, EUCKRFirstByteRange, EUCKRSecondByteRange, Stats);

  if Result then
  begin
    // 输出调试信息
    DebugMsg := string(Format('EUC-KR检测: 有效=%d, ASCII=%d, 无效=%d, 比例=%.2f, 连续=%d',
                     [Stats.ValidSequences, Stats.ASCIICount, Stats.InvalidSequences,
                      Stats.ValidRatio, Stats.MaxConsecutiveValid]));
    OutputDebugString(PWideChar(DebugMsg));
  end;
end;


// 基于字符频率的编码检测
function DetectEncodingByFrequency(const Buffer: TBytes; Size: Integer): string;
var
  i: Integer;
  FreqMap: array[0..255] of Integer;
  MaxFreq, SecondMaxFreq: Integer;
  MaxIndex, SecondMaxIndex: Integer;
  DebugMsg: string;
begin
  Result := '';

  if Size <= 10 then
    Exit;

  // 初始化频率数组
  for i := 0 to 255 do
    FreqMap[i] := 0;

  // 统计字节频率
  for i := 0 to Size - 1 do
    Inc(FreqMap[Buffer[i]]);

  // 找出频率最高的两个字节
  MaxFreq := 0;
  SecondMaxFreq := 0;
  MaxIndex := 0;
  SecondMaxIndex := 0;

  for i := 0 to 255 do
  begin
    if FreqMap[i] > MaxFreq then
    begin
      SecondMaxFreq := MaxFreq;
      SecondMaxIndex := MaxIndex;
      MaxFreq := FreqMap[i];
      MaxIndex := i;
    end
    else if FreqMap[i] > SecondMaxFreq then
    begin
      SecondMaxFreq := FreqMap[i];
      SecondMaxIndex := i;
    end;
  end;

  // 输出调试信息
  DebugMsg := string(Format('频率检测: 最高=%d (0x%2.2X), 第二=%d (0x%2.2X)',
                   [MaxFreq, MaxIndex, SecondMaxFreq, SecondMaxIndex]));
  OutputDebugString(PWideChar(DebugMsg));

  // 基于频率特征判断编码
  // 如果最高频率的字节是空格或常见ASCII字符
  if (MaxIndex = $20) or (MaxIndex = $0A) or (MaxIndex = $0D) then
  begin
    // 如果第二高频率的字节也是ASCII范围
    if SecondMaxIndex < $80 then
      Result := 'ASCII'
    else
      Result := '';
  end
  // 如果最高频率的字节是0，可能是UTF-16
  else if (MaxIndex = $00) and (SecondMaxFreq > Size div 10) then
    Result := 'UTF-16LE'
  // 如果最高频率的字节在中文常用字节范围
  else if (MaxIndex >= $B0) and (MaxIndex <= $F7) then
    Result := 'GBK'
  else
    Result := '';
end;





// 检测是否为Windows-1251（西里尔文）编码
function IsWindows1251String(const Buffer: TBytes; Size: Integer): Boolean;
var
  i: Integer;
  CyrillicCount, ASCIICount: Integer;
  CyrillicRatio: Double;
begin
  if Size <= 0 then
    Exit(False);

  CyrillicCount := 0;
  ASCIICount := 0;
  i := 0;

  while i < Size do
  begin
    if Buffer[i] <= $7F then
    begin
      // ASCII范围
      Inc(ASCIICount);
    end
    else if (Buffer[i] >= $C0) then // 西里尔字符范围 ($C0-$FF)
    begin
      // 西里尔字符范围
      Inc(CyrillicCount);
    end;

    Inc(i);
  end;

  // 计算西里尔字符的比例
  if (CyrillicCount + ASCIICount) > 0 then
    CyrillicRatio := CyrillicCount / (CyrillicCount + ASCIICount)
  else
    CyrillicRatio := 0;

  // 输出调试信息
  var DebugMsg := string(Format('Windows-1251检测: 西里尔=%d, ASCII=%d, 比例=%.2f',
                   [CyrillicCount, ASCIICount, CyrillicRatio]));
  OutputDebugString(PWideChar(DebugMsg));

  // 如果文本中包含足够多的西里尔字符，认为是Windows-1251编码
  Result := (CyrillicCount > 5) and (CyrillicRatio >= 0.1);
end;

// 基于语言特征的编码检测
function DetectEncodingByLanguage(const Buffer: TBytes; Size: Integer): string;
var
  i: Integer;
  ChineseCount, JapaneseCount, KoreanCount: Integer;
  DebugMsg: string;
begin
  Result := '';

  if Size <= 10 then
    Exit;

  ChineseCount := 0;
  JapaneseCount := 0;
  KoreanCount := 0;
  i := 0;

  while i < Size - 1 do
  begin
    // 检测中文字符范围
    if (i + 1 < Size) and (Buffer[i] >= $B0) and (Buffer[i] <= $F7) and
       (Buffer[i+1] >= $A1) and (Buffer[i+1] <= $FE) then
    begin
      Inc(ChineseCount);
      Inc(i, 2);
    end
    // 检测日文字符范围
    else if (i + 1 < Size) and (Buffer[i] >= $81) and (Buffer[i] <= $9F) and
            (Buffer[i+1] >= $40) and (Buffer[i+1] <= $FC) then
    begin
      Inc(JapaneseCount);
      Inc(i, 2);
    end
    // 检测韩文字符范围
    else if (i + 1 < Size) and (Buffer[i] >= $A1) and (Buffer[i] <= $FE) and
            (Buffer[i+1] >= $A1) and (Buffer[i+1] <= $FE) then
    begin
      Inc(KoreanCount);
      Inc(i, 2);
    end
    else
      Inc(i);
  end;

  // 输出调试信息
  DebugMsg := string(Format('语言检测: 中文=%d, 日文=%d, 韩文=%d',
                   [ChineseCount, JapaneseCount, KoreanCount]));
  OutputDebugString(PWideChar(DebugMsg));

  // 基于语言特征判断编码
  if (ChineseCount > JapaneseCount) and (ChineseCount > KoreanCount) and (ChineseCount > 5) then
    Result := 'GBK'
  else if (JapaneseCount > ChineseCount) and (JapaneseCount > KoreanCount) and (JapaneseCount > 5) then
    Result := 'Shift-JIS'
  else if (KoreanCount > ChineseCount) and (KoreanCount > JapaneseCount) and (KoreanCount > 5) then
    Result := 'EUC-KR'
  else
    Result := '';
end;

// 检测文件编码
function DetectFileEncoding(const FileName: string): string;
var
  FileStream: TFileStream;
  BOMLen: Integer;
  BOMType: TJclBOMType;
  Buffer: TBytes;
  BytesRead: Integer;
  IsUTF8, IsGBK: Boolean;
  UTF8Score, GBKScore: Double;
  FileExt: string;
begin
  Result := 'Unknown';

  if not FileExists(FileName) then
    Exit;

  // 获取文件扩展名，用于辅助判断
  FileExt := LowerCase(ExtractFileExt(FileName));

  // 对于特定类型的文件，默认使用UTF-8
  if (FileExt = '.pas') or (FileExt = '.dpr') or (FileExt = '.dfm') or
     (FileExt = '.cpp') or (FileExt = '.h') or (FileExt = '.hpp') or
     (FileExt = '.cs') or (FileExt = '.java') or (FileExt = '.js') or
     (FileExt = '.ts') or (FileExt = '.py') or (FileExt = '.rb') or
     (FileExt = '.php') or (FileExt = '.html') or (FileExt = '.htm') or
     (FileExt = '.xml') or (FileExt = '.json') or (FileExt = '.css') or
     (FileExt = '.md') or (FileExt = '.txt') or (FileExt = '.ini') then
  begin
    // 优先检测BOM，如果没有BOM则假设为UTF-8
  end;

  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    // 首先检测BOM
    BOMType := DetectBOM(FileStream);
    BOMLen := GetBOMLength(BOMType);

    // 根据BOM返回编码
    case BOMType of
      bomAnsi: Result := ENCODING_ANSI;
      bomUTF8: Result := ENCODING_UTF8_BOM;
      bomUTF16LE: Result := ENCODING_UTF16_LE;
      bomUTF16BE: Result := ENCODING_UTF16_BE;
      bomUTF32LE: Result := ENCODING_UTF32_LE;
      bomUTF32BE: Result := ENCODING_UTF32_BE;
    end;

    // 如果有BOM，直接返回结果
    if Result <> 'Unknown' then
      Exit;

    // 无BOM，尝试检测内容
    FileStream.Position := 0;
    var FileSize: Int64 := FileStream.Size;
    var MaxSize: Int64 := 16384; // 增加到16KB以提高准确性
    var ReadSize: Integer;
    if FileSize < MaxSize then
      ReadSize := Integer(FileSize)
    else
      ReadSize := Integer(MaxSize);

    SetLength(Buffer, ReadSize);
    if ReadSize > 0 then
      FileStream.Read(Buffer[0], ReadSize);
    BytesRead := ReadSize;

    // 如果文件为空或者过小，则返回ANSI
    if BytesRead <= 10 then
    begin
      Result := ENCODING_ANSI;
      Exit;
    end;

    // 检查文件头部是否有中文字符
    var ChineseCharCount := 0;
    var i := 0;
    while (i < BytesRead - 2) do
    begin
      // 检查是否是中文字符的UTF-8编码模式
      if (Buffer[i] >= $E0) and (Buffer[i] <= $EF) and
         (i + 1 < BytesRead) and ((Buffer[i+1] and $C0) = $80) and
         (i + 2 < BytesRead) and ((Buffer[i+2] and $C0) = $80) then
      begin
        Inc(ChineseCharCount);
        Inc(i, 3);
      end
      else
        Inc(i);

      // 如果找到足够多的中文字符，则认为是UTF-8
      if ChineseCharCount >= 2 then
      begin
        Result := ENCODING_UTF8;
        var DebugMsg := Format('检测到%d个中文字符，判断为UTF-8', [ChineseCharCount]);
        OutputDebugString(PWideChar(DebugMsg));
        Exit;
      end;
    end;

    // 检测是否为UTF-8
    IsUTF8 := IsUTF8Valid(Buffer, BytesRead);

    // 检测是否为GBK
    IsGBK := IsGBKString(Buffer, BytesRead);

    // 输出调试信息
    var DebugMsg := string(Format('文件: %s, IsUTF8=%s, IsGBK=%s',
                     [ExtractFileName(FileName),
                      BoolToStr(IsUTF8, True),
                      BoolToStr(IsGBK, True)]));
    OutputDebugString(PWideChar(DebugMsg));

    // 如果只有UTF-8有效，则返回UTF-8
    if IsUTF8 and not IsGBK then
    begin
      Result := ENCODING_UTF8;
      Exit;
    end;

    // 如果只有GBK有效，则返回GBK
    if IsGBK and not IsUTF8 then
    begin
      Result := ENCODING_GBK;
      Exit;
    end;

    // 如果两者都有效，则需要进一步判断
    if IsUTF8 and IsGBK then
    begin
      // 对于特定类型的文件，优先考虑UTF-8
      if (FileExt = '.pas') or (FileExt = '.dpr') or (FileExt = '.dfm') or
         (FileExt = '.cpp') or (FileExt = '.h') or (FileExt = '.hpp') or
         (FileExt = '.cs') or (FileExt = '.java') or (FileExt = '.js') or
         (FileExt = '.ts') or (FileExt = '.py') or (FileExt = '.rb') or
         (FileExt = '.php') or (FileExt = '.html') or (FileExt = '.htm') or
         (FileExt = '.xml') or (FileExt = '.json') or (FileExt = '.css') or
         (FileExt = '.md') or (FileExt = '.txt') or (FileExt = '.ini') then
      begin
        Result := ENCODING_UTF8;
      end
      else
      begin
        // 对于其他类型的文件，根据系统语言环境决定
        var LangID := GetSystemDefaultLangID;
        if (LangID = $0804) or // 简体中文
           (LangID = $0404) or // 繁体中文
           (LangID = $0c04) then // 香港中文
          Result := ENCODING_GBK
        else
          Result := ENCODING_UTF8;
      end;
      Exit;
    end;

    // 尝试检测是否为Big5
    var IsBig5 := IsBig5String(Buffer, BytesRead);

    // 如果只有Big5有效，则返回Big5
    if IsBig5 and not IsUTF8 and not IsGBK then
    begin
      Result := ENCODING_BIG5;
      Exit;
    end;

    // 尝试检测是否为Shift-JIS
    var IsShiftJIS := IsShiftJISString(Buffer, BytesRead);

    // 如果只有Shift-JIS有效，则返回Shift-JIS
    if IsShiftJIS and not IsUTF8 and not IsGBK and not IsBig5 then
    begin
      Result := ENCODING_SHIFT_JIS;
      Exit;
    end;

    // 尝试检测是否为EUC-KR
    var IsEUCKR := IsEUCKRString(Buffer, BytesRead);

    // 如果只有EUC-KR有效，则返回EUC-KR
    if IsEUCKR and not IsUTF8 and not IsGBK and not IsBig5 and not IsShiftJIS then
    begin
      Result := 'EUC-KR';
      Exit;
    end;

    // 尝试检测是否为Windows-1251
    var IsWindows1251 := IsWindows1251String(Buffer, BytesRead);

    // 如果只有Windows-1251有效，则返回Windows-1251
    if IsWindows1251 and not IsUTF8 and not IsGBK and not IsBig5 and not IsShiftJIS and not IsEUCKR then
    begin
      Result := 'Windows-1251';
      Exit;
    end;

    // 尝试使用频率检测
    var FreqResult := DetectEncodingByFrequency(Buffer, BytesRead);
    if FreqResult <> '' then
    begin
      if FreqResult = 'GBK' then
        Result := ENCODING_GBK
      else if FreqResult = 'UTF-16LE' then
        Result := ENCODING_UTF16_LE
      else if FreqResult = 'ASCII' then
        Result := ENCODING_ANSI;

      var FreqDebugMsg := string(Format('频率检测结果: %s', [FreqResult]));
      OutputDebugString(PWideChar(FreqDebugMsg));
      Exit;
    end;

    // 尝试使用语言特征检测
    var LangResult := DetectEncodingByLanguage(Buffer, BytesRead);
    if LangResult <> '' then
    begin
      if LangResult = 'GBK' then
        Result := ENCODING_GBK
      else if LangResult = 'Shift-JIS' then
        Result := 'Shift-JIS'
      else if LangResult = 'EUC-KR' then
        Result := 'EUC-KR';

      var LangDebugMsg := string(Format('语言特征检测结果: %s', [LangResult]));
      OutputDebugString(PWideChar(LangDebugMsg));
      Exit;
    end;

    // 如果所有检测都无效，则返回系统默认编码
    Result := 'ANSI (CP' + IntToStr(GetACP) + ')';
  finally
    FileStream.Free;
  end;
end;

// 获取编码的代码页
function GetEncodingCodePage(const EncodingName: string): Integer;
var
  UpperEncName: string;
begin
  UpperEncName := UpperCase(EncodingName);

  // Unicode编码
  if (UpperEncName = 'UTF-8') or (UpperEncName = 'UTF8') then
    Result := CP_UTF8
  else if (UpperEncName = 'UTF-8-BOM') or (UpperEncName = 'UTF8-BOM') or
          (UpperEncName = 'UTF-8 WITH BOM') then
    Result := CP_UTF8
  else if (UpperEncName = 'UTF-16LE') or (UpperEncName = 'UTF16LE') or
          (UpperEncName = 'UNICODE') then
    Result := CP_UTF16LE
  else if (UpperEncName = 'UTF-16BE') or (UpperEncName = 'UTF16BE') then
    Result := CP_UTF16BE
  else if (UpperEncName = 'UTF-32LE') or (UpperEncName = 'UTF32LE') then
    Result := CP_UTF32LE
  else if (UpperEncName = 'UTF-32BE') or (UpperEncName = 'UTF32BE') then
    Result := CP_UTF32BE

  // 中文编码
  else if (UpperEncName = 'GBK') or (UpperEncName = 'GB2312') or
          (UpperEncName = '936') then
    Result := CP_GBK
  else if (UpperEncName = 'BIG5') or (UpperEncName = '950') then
    Result := CP_BIG5
  else if UpperEncName = 'GB18030' then
    Result := CP_GB18030

  // 如果是数字格式的代码页
  else if TryStrToInt(EncodingName, Result) then
    // 已经转换为Integer了

  // 未知的编码
  else
    Result := GetACP(); // 返回系统默认代码页
end;

// 转换文件编码
function ConvertFile(const SourceFileName, TargetFileName: string;
                    SourceCodePage, TargetCodePage: Integer): Boolean;
var
  SourceBytes, TargetBytes: TBytes;
  SourceStream, TargetStream: TFileStream;
  SourceString: string;
begin
  Result := False;

  try
    // 读取源文件
    SourceStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(SourceBytes, SourceStream.Size);
      if SourceStream.Size > 0 then
        SourceStream.ReadBuffer(SourceBytes[0], SourceStream.Size);
    finally
      SourceStream.Free;
    end;

    // 从源编码转换到Unicode字符串
    SourceString := TEncoding.GetEncoding(SourceCodePage).GetString(SourceBytes);

    // 从Unicode字符串转换到目标编码
    TargetBytes := TEncoding.GetEncoding(TargetCodePage).GetBytes(SourceString);

    // 写入目标文件
    TargetStream := TFileStream.Create(TargetFileName, fmCreate);
    try
      if Length(TargetBytes) > 0 then
        TargetStream.WriteBuffer(TargetBytes[0], Length(TargetBytes));
      Result := True;
    finally
      TargetStream.Free;
    end;
  except
    on E: Exception do
    begin
      // 处理错误
      Result := False;
    end;
  end;
end;

// 带BOM选项的转换文件编码
function ConvertFileWithBOM(const SourceFileName, TargetFileName: string;
                           SourceCodePage, TargetCodePage: Integer;
                           AddBOM: Boolean = False): Boolean;
var
  SourceBytes, TargetBytes, BOMBytes, FinalBytes: TBytes;
  SourceStream, TargetStream: TFileStream;
  SourceString: string;
  SourceEncoding, TargetEncoding: TEncoding;
  BOMLen: Integer;
  BOMType: TJclBOMType;
  TempBytes: TBytes;
  FileStream: TFileStream;
begin
  Result := False;

  try
    // 打开源文件流
    FileStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyWrite);
    try
      // 检测BOM类型
      BOMType := DetectBOM(FileStream);
      BOMLen := GetBOMLength(BOMType);

      // 重置文件指针
      FileStream.Position := 0;

      // 读取整个文件内容
      SetLength(SourceBytes, FileStream.Size);
      if FileStream.Size > 0 then
        FileStream.ReadBuffer(SourceBytes[0], FileStream.Size);
    finally
      FileStream.Free;
    end;

    // 如果检测到BOM，移除BOM
    if BOMLen > 0 then
    begin
      SetLength(TempBytes, Length(SourceBytes) - BOMLen);
      if Length(TempBytes) > 0 then
        Move(SourceBytes[BOMLen], TempBytes[0], Length(TempBytes));
      SourceBytes := TempBytes;
    end;

    // 创建源编码对象
    case SourceCodePage of
      CP_UTF8: SourceEncoding := TEncoding.UTF8;
      CP_UTF16LE: SourceEncoding := TEncoding.Unicode;
      CP_UTF16BE: SourceEncoding := TEncoding.BigEndianUnicode;
      else SourceEncoding := TEncoding.GetEncoding(SourceCodePage);
    end;

    // 创建目标编码对象
    case TargetCodePage of
      CP_UTF8: TargetEncoding := TEncoding.UTF8;
      CP_UTF16LE: TargetEncoding := TEncoding.Unicode;
      CP_UTF16BE: TargetEncoding := TEncoding.BigEndianUnicode;
      else TargetEncoding := TEncoding.GetEncoding(TargetCodePage);
    end;

    try
      // 从源编码转换到Unicode字符串
      SourceString := SourceEncoding.GetString(SourceBytes);

      // 从Unicode字符串转换到目标编码
      TargetBytes := TargetEncoding.GetBytes(SourceString);

      // 如果需要添加BOM
      if AddBOM then
      begin
        case TargetCodePage of
          CP_UTF8:     BOMBytes := TBytes.Create($EF, $BB, $BF);
          CP_UTF16LE:  BOMBytes := TBytes.Create($FF, $FE);
          CP_UTF16BE:  BOMBytes := TBytes.Create($FE, $FF);
          CP_UTF32LE:  BOMBytes := TBytes.Create($FF, $FE, $00, $00);
          CP_UTF32BE:  BOMBytes := TBytes.Create($00, $00, $FE, $FF);
          else         SetLength(BOMBytes, 0);
        end;

        if Length(BOMBytes) > 0 then
        begin
          SetLength(FinalBytes, Length(BOMBytes) + Length(TargetBytes));
          Move(BOMBytes[0], FinalBytes[0], Length(BOMBytes));
          if Length(TargetBytes) > 0 then
            Move(TargetBytes[0], FinalBytes[Length(BOMBytes)], Length(TargetBytes));
          TargetBytes := FinalBytes;
        end;
      end;

      // 写入目标文件
      TargetStream := TFileStream.Create(TargetFileName, fmCreate);
      try
        if Length(TargetBytes) > 0 then
          TargetStream.WriteBuffer(TargetBytes[0], Length(TargetBytes));
        Result := True;
      finally
        TargetStream.Free;
      end;
    finally
      // 释放编码对象
      if (SourceCodePage <> CP_UTF8) and (SourceCodePage <> CP_UTF16LE) and (SourceCodePage <> CP_UTF16BE) then
        SourceEncoding.Free;
      if (TargetCodePage <> CP_UTF8) and (TargetCodePage <> CP_UTF16LE) and (TargetCodePage <> CP_UTF16BE) then
        TargetEncoding.Free;
    end;
  except
    on E: Exception do
    begin
      // 处理错误
      OutputDebugString(PWideChar('ConvertFileWithBOM错误: ' + E.Message));
      Result := False;
    end;
  end;
end;

// 按编码名称转换文件
function ConvertFileByName(const SourceFileName, TargetFileName: string;
                          const SourceEncodingName, TargetEncodingName: string;
                          AddBOM: Boolean = False): Boolean;
var
  SourceCP, TargetCP: Integer;
begin
  // 获取源和目标代码页
  SourceCP := GetEncodingCodePage(SourceEncodingName);
  TargetCP := GetEncodingCodePage(TargetEncodingName);

  // 使用代码页版本的函数
  Result := ConvertFileWithBOM(SourceFileName, TargetFileName, SourceCP, TargetCP, AddBOM);
end;

// 直接将文件转换为UTF-8 BOM格式
function ConvertFileToUTF8BOM(const SourceFileName, TargetFileName: string): Boolean;
var
  SourceBytes, TargetBytes: TBytes;
  FileStream, TargetStream: TFileStream;
  BOMHeader: TBytes;
  SourceString: string;
  SourceEncoding: TEncoding;
  BOMType: TJclBOMType;
  BOMLen: Integer;
  DetectedEncodingName: string;
  SourceCodePage: Integer;
  TempBytes: TBytes;
  DebugMsg: string;
begin
  Result := False;

  try
    // 打开源文件
    FileStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyWrite);
    try
      // 检测BOM类型
      BOMType := DetectBOM(FileStream);
      BOMLen := GetBOMLength(BOMType);

      // 如果已经是UTF-8 BOM，直接复制
      if BOMType = bomUTF8 then
      begin
        FileStream.Free; // 先关闭文件

        if SourceFileName <> TargetFileName then
          TFile.Copy(SourceFileName, TargetFileName, True);
        Result := True;
        Exit;
      end;

      // 特殊处理：如果检测到的是UTF-8但没有BOM，我们需要确保添加BOM
      if (BOMType = bomAnsi) and (DetectFileEncoding(SourceFileName) = ENCODING_UTF8) then
      begin
        OutputDebugString('检测到UTF-8文件但没有BOM，将添加BOM...');

        // 直接读取文件内容并添加BOM
        var UTF8SourceBytes := TFile.ReadAllBytes(SourceFileName);
        var UTF8BOMHeader := TBytes.Create($EF, $BB, $BF);

        // 合并BOM和内容
        var UTF8FinalBytes: TBytes;
        SetLength(UTF8FinalBytes, Length(UTF8BOMHeader) + Length(UTF8SourceBytes));
        if Length(UTF8BOMHeader) > 0 then
          Move(UTF8BOMHeader[0], UTF8FinalBytes[0], Length(UTF8BOMHeader));
        if Length(UTF8SourceBytes) > 0 then
          Move(UTF8SourceBytes[0], UTF8FinalBytes[Length(UTF8BOMHeader)], Length(UTF8SourceBytes));

        // 写入目标文件
        try
          // 先检查目标文件是否可写
          if FileExists(TargetFileName) then
          begin
            // 尝试设置文件属性为可写
            {$IFDEF MSWINDOWS}
            if FileGetAttr(TargetFileName) and faReadOnly <> 0 then
              FileSetAttr(TargetFileName, FileGetAttr(TargetFileName) and not faReadOnly);
            {$ENDIF}

            // 删除已存在的文件
            DeleteFile(PChar(TargetFileName));
          end;

          // 写入新文件
          TFile.WriteAllBytes(TargetFileName, UTF8FinalBytes);
          Result := True;

          // 输出调试信息
          OutputDebugString(PWideChar(string(Format('成功添加BOM到UTF-8文件: %s, 大小: %d 字节',
                           [TargetFileName, Length(UTF8FinalBytes)]))));

          // 关闭文件流并退出
          FileStream.Free;
          Exit;
        except
          on E: Exception do
          begin
            // 捕获写入错误
            OutputDebugString(PWideChar(string(Format('添加BOM失败: %s - %s',
                           [TargetFileName, E.Message]))));
            // 继续执行，尝试使用标准方法
          end;
        end;
      end;

      // 重置文件指针
      FileStream.Position := 0;

      // 读取整个文件内容
      SetLength(SourceBytes, FileStream.Size);
      if FileStream.Size > 0 then
        FileStream.ReadBuffer(SourceBytes[0], FileStream.Size);
    finally
      FileStream.Free;
    end;

    // 检测源文件编码
    DetectedEncodingName := DetectFileEncoding(SourceFileName);
    OutputDebugString(PWideChar('检测到的编码: ' + DetectedEncodingName));

    // 确保目标路径存在
    var TargetPath := ExtractFilePath(TargetFileName);
    if (TargetPath <> '') and not DirectoryExists(TargetPath) then
      ForceDirectories(TargetPath);

    // 如果检测到BOM，移除BOM
    if BOMLen > 0 then
    begin
      SetLength(TempBytes, Length(SourceBytes) - BOMLen);
      if Length(TempBytes) > 0 then
        Move(SourceBytes[BOMLen], TempBytes[0], Length(TempBytes));
      SourceBytes := TempBytes;
    end;

    // 获取源编码的代码页
    SourceCodePage := GetEncodingCodePage(DetectedEncodingName);

    // 如果检测到的是ANSI，但文件包含中文字符，则尝试使用UTF-8
    if (DetectedEncodingName.StartsWith('ANSI')) then
    begin
      // 检查文件头部是否有中文字符
      var ChineseCharCount := 0;
      var i := 0;
      while (i < Length(SourceBytes) - 2) do
      begin
        // 检查是否是中文字符的UTF-8编码模式
        if (SourceBytes[i] >= $E0) and (SourceBytes[i] <= $EF) and
           (i + 1 < Length(SourceBytes)) and ((SourceBytes[i+1] and $C0) = $80) and
           (i + 2 < Length(SourceBytes)) and ((SourceBytes[i+2] and $C0) = $80) then
        begin
          Inc(ChineseCharCount);
          Inc(i, 3);
        end
        else
          Inc(i);

        // 如果找到足够多的中文字符，则认为是UTF-8
        if ChineseCharCount >= 2 then
        begin
          SourceCodePage := CP_UTF8;
          DebugMsg := string(Format('检测到%d个中文字符，判断为UTF-8', [ChineseCharCount]));
          OutputDebugString(PWideChar(DebugMsg));
          Break;
        end;
      end;
    end
    // 如果检测到的是GBK或Big5等亚洲编码，则使用相应的代码页
    else if (DetectedEncodingName = ENCODING_GBK) then
      SourceCodePage := CP_GBK
    else if (DetectedEncodingName = ENCODING_BIG5) then
      SourceCodePage := CP_BIG5
    else if (DetectedEncodingName = ENCODING_SHIFT_JIS) then
      SourceCodePage := CP_SHIFT_JIS
    else if (DetectedEncodingName = 'EUC-KR') then
      SourceCodePage := 949 // CP_EUC_KR
    // 如果是其他特殊编码，则尝试使用系统支持的代码页
    else if (DetectedEncodingName = 'Windows-1251') then
      SourceCodePage := 1251 // 西里尔文
    else if (DetectedEncodingName = 'Windows-1256') then
      SourceCodePage := 1256 // 阿拉伯文
    else if (DetectedEncodingName = 'Windows-1255') then
      SourceCodePage := 1255; // 希伯来文

    // 创建源编码对象
    case SourceCodePage of
      CP_UTF8: SourceEncoding := TEncoding.UTF8;
      CP_UTF16LE: SourceEncoding := TEncoding.Unicode;
      CP_UTF16BE: SourceEncoding := TEncoding.BigEndianUnicode;
      else SourceEncoding := TEncoding.GetEncoding(SourceCodePage);
    end;

    try
      // 从源编码转换到Unicode字符串
      SourceString := SourceEncoding.GetString(SourceBytes);

      // 输出调试信息
      DebugMsg := string(Format('源编码: %s, 代码页: %d, 内容长度: %d',
                       [DetectedEncodingName, SourceCodePage, Length(SourceString)]));
      OutputDebugString(PWideChar(DebugMsg));

      // 从Unicode字符串转换到UTF-8
      TargetBytes := TEncoding.UTF8.GetBytes(SourceString);

      // 添加UTF-8 BOM
      BOMHeader := TBytes.Create($EF, $BB, $BF);

      // 合并BOM和内容
      var FinalBytes: TBytes;
      SetLength(FinalBytes, Length(BOMHeader) + Length(TargetBytes));
      if Length(BOMHeader) > 0 then
        Move(BOMHeader[0], FinalBytes[0], Length(BOMHeader));
      if Length(TargetBytes) > 0 then
        Move(TargetBytes[0], FinalBytes[Length(BOMHeader)], Length(TargetBytes));

      // 写入目标文件
      try
        // 先检查目标文件是否可写
        if FileExists(TargetFileName) then
        begin
          // 尝试设置文件属性为可写
          {$IFDEF MSWINDOWS}
          if FileGetAttr(TargetFileName) and faReadOnly <> 0 then
            FileSetAttr(TargetFileName, FileGetAttr(TargetFileName) and not faReadOnly);
          {$ENDIF}

          // 删除已存在的文件
          DeleteFile(PChar(TargetFileName));
        end;

        TargetStream := TFileStream.Create(TargetFileName, fmCreate);
        try
          if Length(FinalBytes) > 0 then
            TargetStream.WriteBuffer(FinalBytes[0], Length(FinalBytes));
          Result := True;

          // 输出调试信息
          DebugMsg := string(Format('转换成功! 目标文件: %s, 大小: %d 字节',
                           [TargetFileName, Length(FinalBytes)]));
          OutputDebugString(PWideChar(DebugMsg));
        finally
          TargetStream.Free;
        end;
      except
        on E: Exception do
        begin
          // 捕获写入错误
          DebugMsg := string(Format('写入目标文件失败: %s - %s',
                           [TargetFileName, E.Message]));
          OutputDebugString(PWideChar(DebugMsg));
          Result := False;
        end;
      end;
    finally
      // 释放编码对象
      if (SourceCodePage <> CP_UTF8) and (SourceCodePage <> CP_UTF16LE) and (SourceCodePage <> CP_UTF16BE) then
        SourceEncoding.Free;
    end;
  except
    on E: Exception do
    begin
      // 捕获其他错误
      DebugMsg := string(Format('转换为UTF-8 BOM失败: %s - %s',
                       [SourceFileName, E.Message]));
      OutputDebugString(PWideChar(DebugMsg));
      Result := False;
    end;
  end;
end;

end.