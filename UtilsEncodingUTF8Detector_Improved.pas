unit UtilsEncodingUTF8Detector_Improved;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, System.Math, UtilsTypes;

type
  /// <summary>
  /// UTF-8检测结果记录
  /// </summary>
  TUTF8DetectionResult = record
    IsUTF8: Boolean;           // 是否是UTF-8编码
    HasBOM: Boolean;           // 是否有BOM
    Confidence: Double;        // 置信度 (0.0-1.0)
    ValidByteCount: Int64;     // 有效字节数
    InvalidByteCount: Int64;   // 无效字节数
    TotalByteCount: Int64;     // 总字节数
    ChineseCharCount: Integer; // 中文字符数
    JapaneseCharCount: Integer; // 日文字符数
    KoreanCharCount: Integer;  // 韩文字符数
    MaxConsecutiveValid: Integer; // 最长连续有效序列
  end;

  /// <summary>
  /// 改进的UTF-8编码检测器
  /// </summary>
  TUTF8EncodingDetector_Improved = class
  private
    const
      MIN_UTF8_CONFIDENCE = 0.80; // 最小UTF-8置信度 (提高阈值，减少误判)
      MAX_TEXT_SAMPLE = 16 * 1024; // 最大采样大小 (16KB)
      UTF8_BOM: array[0..2] of Byte = ($EF, $BB, $BF); // UTF-8 BOM标记

    /// <summary>
    /// 检查字节序列是否是有效的UTF-8
    /// </summary>
    class function ValidateUTF8Sequence(const Buffer: TBytes; out ValidCount, InvalidCount: Int64): Boolean;

    /// <summary>
    /// 检查是否是有效的UTF-8字符序列
    /// </summary>
    class function IsValidUTF8Sequence(const Bytes: TBytes; Start: Integer; out ByteCount: Integer): Boolean;

    /// <summary>
    /// 根据字节分布统计推测是否为UTF-8
    /// </summary>
    class function AnalyzeByteDistribution(const Buffer: TBytes): Double;

    /// <summary>
    /// 字符序列频率分析
    /// </summary>
    class function AnalyzeSequenceFrequency(const Buffer: TBytes): Double;

    /// <summary>
    /// 分析亚洲语言特征
    /// </summary>
    class function AnalyzeAsianLanguageFeatures(const Buffer: TBytes; out ChineseCount, JapaneseCount, KoreanCount: Integer): Double;

    /// <summary>
    /// 检查是否含有UTF-8签名(BOM)
    /// </summary>
    class function HasUTF8BOM(const Buffer: TBytes): Boolean; overload;

  public
    /// <summary>
    /// 检测文件是否是UTF-8编码
    /// </summary>
    class function DetectFile(const FileName: string): TUTF8DetectionResult;

    /// <summary>
    /// 检测字节数组是否是UTF-8编码
    /// </summary>
    class function DetectBuffer(const Buffer: TBytes): TUTF8DetectionResult;

    /// <summary>
    /// 检测流是否是UTF-8编码
    /// </summary>
    class function DetectStream(const Stream: TStream): TUTF8DetectionResult;

    /// <summary>
    /// 检查是否含有UTF-8签名(BOM)
    /// </summary>
    class function HasUTF8BOM(const FileName: string): Boolean; overload;
  end;

implementation

{ TUTF8EncodingDetector_Improved }

class function TUTF8EncodingDetector_Improved.AnalyzeAsianLanguageFeatures(
  const Buffer: TBytes; out ChineseCount, JapaneseCount, KoreanCount: Integer): Double;
var
  i: Integer;
begin
  ChineseCount := 0;
  JapaneseCount := 0;
  KoreanCount := 0;

  // 分析亚洲语言特征
  i := 0;
  while i < Length(Buffer) - 2 do
  begin
    // 检查是否是中文UTF-8编码模式 (常见汉字范围)
    if (i + 2 < Length(Buffer)) and
       (Buffer[i] >= $E4) and (Buffer[i] <= $E9) and
       ((Buffer[i+1] and $C0) = $80) and
       ((Buffer[i+2] and $C0) = $80) then
    begin
      Inc(ChineseCount);
      Inc(i, 3);
      Continue;
    end;

    // 检查是否是日文UTF-8编码模式 (平假名、片假名范围)
    if (i + 2 < Length(Buffer)) and
       (((Buffer[i] = $E3) and (Buffer[i+1] >= $81) and (Buffer[i+1] <= $83)) or
        ((Buffer[i] = $E3) and (Buffer[i+1] >= $82) and (Buffer[i+1] <= $83))) and
       ((Buffer[i+2] and $C0) = $80) then
    begin
      Inc(JapaneseCount);
      Inc(i, 3);
      Continue;
    end;

    // 检查是否是韩文UTF-8编码模式 (韩文音节范围)
    if (i + 2 < Length(Buffer)) and
       (Buffer[i] = $EA) and
       (Buffer[i+1] >= $B0) and (Buffer[i+1] <= $BF) and
       ((Buffer[i+2] and $C0) = $80) then
    begin
      Inc(KoreanCount);
      Inc(i, 3);
      Continue;
    end;

    Inc(i);
  end;

  // 计算亚洲语言特征置信度
  if (ChineseCount + JapaneseCount + KoreanCount) > 0 then
    Result := Min(0.95, (ChineseCount + JapaneseCount + KoreanCount) / 10)
  else
    Result := 0;
end;

class function TUTF8EncodingDetector_Improved.AnalyzeByteDistribution(const Buffer: TBytes): Double;
var
  ByteCount: array[0..255] of Integer;
  HighBitCount, ContinuationByteCount: Integer;
  ExpectedContinuationBytes, ActualContinuationBytes: Integer;
  i: Integer;
  DistributionScore: Double;
begin
  // 初始化字节计数
  FillChar(ByteCount, SizeOf(ByteCount), 0);

  // 统计每个字节的出现次数
  for i := 0 to Length(Buffer) - 1 do
    Inc(ByteCount[Buffer[i]]);

  // 计算高位字节的数量
  HighBitCount := 0;
  for i := 128 to 255 do
    Inc(HighBitCount, ByteCount[i]);

  // 如果没有高位字节，则是纯ASCII (也是有效的UTF-8)
  if HighBitCount = 0 then
    Exit(1.0);

  // 计算后续字节的数量
  ContinuationByteCount := 0;
  for i := $80 to $BF do
    Inc(ContinuationByteCount, ByteCount[i]);

  // 计算期望的后续字节数量
  ExpectedContinuationBytes := 0;
  for i := $C0 to $DF do // 2字节序列
    Inc(ExpectedContinuationBytes, ByteCount[i]);

  for i := $E0 to $EF do // 3字节序列
    Inc(ExpectedContinuationBytes, ByteCount[i] * 2);

  for i := $F0 to $F7 do // 4字节序列
    Inc(ExpectedContinuationBytes, ByteCount[i] * 3);

  ActualContinuationBytes := ContinuationByteCount;

  // 计算分布得分
  if ExpectedContinuationBytes = 0 then
    DistributionScore := 0
  else
    DistributionScore := Min(1.0, ActualContinuationBytes / ExpectedContinuationBytes);

  // 如果后续字节数量与期望值相差太大，则可能不是UTF-8
  if Abs(ActualContinuationBytes - ExpectedContinuationBytes) > (HighBitCount * 0.3) then
    DistributionScore := DistributionScore * 0.5;

  Result := DistributionScore;
end;

class function TUTF8EncodingDetector_Improved.AnalyzeSequenceFrequency(const Buffer: TBytes): Double;
var
  CommonChineseUTF8Start: array of Byte;
  CommonChineseUTF8Matches, PotentialMatches: Integer;
  i: Integer;
  FrequencyScore: Double;
begin
  // 常见中文汉字在UTF-8中的首字节特征
  CommonChineseUTF8Start := [$E4, $E5, $E6, $E7, $E8, $E9];

  // 计算与常见中文UTF-8编码模式匹配的次数
  CommonChineseUTF8Matches := 0;
  PotentialMatches := 0;

  for i := 0 to Length(Buffer) - 3 do
  begin
    // 检查是否是潜在的中文UTF-8序列首字节
    var IsCommonChineseStart := False;
    for var j := 0 to High(CommonChineseUTF8Start) do
    begin
      if Buffer[i] = CommonChineseUTF8Start[j] then
      begin
        IsCommonChineseStart := True;
        Break;
      end;
    end;

    if IsCommonChineseStart then
    begin
      Inc(PotentialMatches);

      if ((Buffer[i+1] and $C0) = $80) and // 第二个字节是10xxxxxx
         ((Buffer[i+2] and $C0) = $80) then // 第三个字节是10xxxxxx
      begin
        Inc(CommonChineseUTF8Matches);
      end;
    end;
  end;

  // 计算频率得分
  if PotentialMatches = 0 then
    FrequencyScore := 0
  else
    FrequencyScore := CommonChineseUTF8Matches / PotentialMatches;

  Result := FrequencyScore;
end;

class function TUTF8EncodingDetector_Improved.DetectBuffer(const Buffer: TBytes): TUTF8DetectionResult;
var
  ValidCount, InvalidCount: Int64;
  DistributionConfidence, FrequencyConfidence, AsianLanguageConfidence, FinalConfidence: Double;
  ChineseCount, JapaneseCount, KoreanCount, MaxConsecutiveValid: Integer;
begin
  // 初始化结果
  Result.IsUTF8 := False;
  Result.HasBOM := False;
  Result.Confidence := 0.0;
  Result.ValidByteCount := 0;
  Result.InvalidByteCount := 0;
  Result.TotalByteCount := Length(Buffer);
  Result.ChineseCharCount := 0;
  Result.JapaneseCharCount := 0;
  Result.KoreanCharCount := 0;
  Result.MaxConsecutiveValid := 0;

  if Length(Buffer) = 0 then
    Exit;

  // 检查BOM
  Result.HasBOM := HasUTF8BOM(Buffer);

  // 如果有BOM，直接确认为UTF-8
  if Result.HasBOM then
  begin
    Result.IsUTF8 := True;
    Result.Confidence := 1.0;
    Result.ValidByteCount := Length(Buffer);
    Exit;
  end;

  // 验证UTF-8序列
  Result.IsUTF8 := ValidateUTF8Sequence(Buffer, ValidCount, InvalidCount);
  Result.ValidByteCount := ValidCount;
  Result.InvalidByteCount := InvalidCount;

  // 计算基本置信度
  var BasicConfidence := 0.0;
  if (ValidCount + InvalidCount) > 0 then
    BasicConfidence := ValidCount / (ValidCount + InvalidCount);

  // 进行字节分布分析
  DistributionConfidence := AnalyzeByteDistribution(Buffer);

  // 进行序列频率分析
  FrequencyConfidence := AnalyzeSequenceFrequency(Buffer);

  // 分析亚洲语言特征
  AsianLanguageConfidence := AnalyzeAsianLanguageFeatures(Buffer, ChineseCount, JapaneseCount, KoreanCount);
  Result.ChineseCharCount := ChineseCount;
  Result.JapaneseCharCount := JapaneseCount;
  Result.KoreanCharCount := KoreanCount;

  // 计算最长连续有效序列
  MaxConsecutiveValid := 0;
  var CurrentConsecutive := 0;
  var i := 0;
  while i < Length(Buffer) do
  begin
    var ByteCount := 0;
    if IsValidUTF8Sequence(Buffer, i, ByteCount) then
    begin
      Inc(CurrentConsecutive);
      Inc(i, ByteCount);
    end
    else
    begin
      MaxConsecutiveValid := Max(MaxConsecutiveValid, CurrentConsecutive);
      CurrentConsecutive := 0;
      Inc(i);
    end;
  end;
  MaxConsecutiveValid := Max(MaxConsecutiveValid, CurrentConsecutive);
  Result.MaxConsecutiveValid := MaxConsecutiveValid;

  // 综合计算最终置信度
  if AsianLanguageConfidence > 0.5 then
    // 如果有明显的亚洲语言特征，提高权重
    FinalConfidence := 0.5 * BasicConfidence + 0.25 * DistributionConfidence + 0.15 * FrequencyConfidence + 0.1 * AsianLanguageConfidence
  else
    FinalConfidence := 0.6 * BasicConfidence + 0.25 * DistributionConfidence + 0.15 * FrequencyConfidence;

  // 对于纯ASCII文本，降低UTF-8置信度，因为它们也可能是ANSI编码
  var AsciiCount := 0;
  for var j := 0 to Length(Buffer) - 1 do
    if Buffer[j] < $80 then
      Inc(AsciiCount);

  if (Length(Buffer) > 0) and (AsciiCount / Length(Buffer) > 0.95) then
    FinalConfidence := FinalConfidence * 0.9;

  // 根据最长连续有效序列调整置信度
  if MaxConsecutiveValid >= 10 then
    FinalConfidence := FinalConfidence * 1.1;

  // 限制最终置信度在0-1范围内
  Result.Confidence := Max(0, Min(1.0, FinalConfidence));

  // 根据置信度调整最终结果
  if Result.Confidence >= MIN_UTF8_CONFIDENCE then
    Result.IsUTF8 := True
  else
    Result.IsUTF8 := False;
end;

class function TUTF8EncodingDetector_Improved.DetectFile(const FileName: string): TUTF8DetectionResult;
var
  FileStream: TFileStream;
  Buffer: TBytes;
  ReadSize: Int64;
const
  MAX_READ_SIZE = 16 * 1024 * 1024; // 最多读取16MB
begin
  // 初始化默认结果
  Result.IsUTF8 := False;
  Result.HasBOM := False;
  Result.Confidence := 0.0;
  Result.ValidByteCount := 0;
  Result.InvalidByteCount := 0;
  Result.TotalByteCount := 0;
  Result.ChineseCharCount := 0;
  Result.JapaneseCharCount := 0;
  Result.KoreanCharCount := 0;
  Result.MaxConsecutiveValid := 0;

  if not FileExists(FileName) then
    Exit;

  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    Result.TotalByteCount := FileStream.Size;

    // 对于空文件，默认不是UTF-8
    if FileStream.Size = 0 then
      Exit;

    // 首先检查BOM
    Result.HasBOM := HasUTF8BOM(FileName);

    // 如果有BOM，直接确认为UTF-8
    if Result.HasBOM then
    begin
      Result.IsUTF8 := True;
      Result.Confidence := 1.0;
      Result.ValidByteCount := FileStream.Size;
      Exit;
    end;

    // 读取文件内容进行深入分析
    FileStream.Position := 0;

    // 限制读取大小，避免处理过大的文件
    ReadSize := Min(FileStream.Size, MAX_READ_SIZE);
    SetLength(Buffer, ReadSize);
    FileStream.ReadBuffer(Buffer[0], ReadSize);

    // 分析缓冲区
    Result := DetectBuffer(Buffer);

    // 调整总字节数
    Result.TotalByteCount := FileStream.Size;
  finally
    FileStream.Free;
  end;
end;

class function TUTF8EncodingDetector_Improved.DetectStream(const Stream: TStream): TUTF8DetectionResult;
var
  Buffer: TBytes;
  Position: Int64;
  ReadSize: Int64;
begin
  // 初始化默认结果
  Result.IsUTF8 := False;
  Result.HasBOM := False;
  Result.Confidence := 0.0;
  Result.ValidByteCount := 0;
  Result.InvalidByteCount := 0;
  Result.TotalByteCount := 0;
  Result.ChineseCharCount := 0;
  Result.JapaneseCharCount := 0;
  Result.KoreanCharCount := 0;
  Result.MaxConsecutiveValid := 0;

  if Stream = nil then
    Exit;

  // 保存当前流位置
  Position := Stream.Position;

  try
    Result.TotalByteCount := Stream.Size;

    // 对于空流，默认不是UTF-8
    if Stream.Size = 0 then
      Exit;

    // 重置流位置
    Stream.Position := 0;

    // 读取流内容进行分析
    ReadSize := Min(Stream.Size, MAX_TEXT_SAMPLE);
    SetLength(Buffer, ReadSize);
    Stream.ReadBuffer(Buffer[0], ReadSize);

    // 分析缓冲区
    Result := DetectBuffer(Buffer);

    // 调整总字节数
    Result.TotalByteCount := Stream.Size;
  finally
    // 恢复流位置
    Stream.Position := Position;
  end;
end;

class function TUTF8EncodingDetector_Improved.HasUTF8BOM(const Buffer: TBytes): Boolean;
begin
  Result := (Length(Buffer) >= 3) and
            (Buffer[0] = UTF8_BOM[0]) and
            (Buffer[1] = UTF8_BOM[1]) and
            (Buffer[2] = UTF8_BOM[2]);
end;

class function TUTF8EncodingDetector_Improved.HasUTF8BOM(const FileName: string): Boolean;
var
  FileStream: TFileStream;
  Buffer: array[0..2] of Byte;
  BytesRead: Integer;
begin
  Result := False;

  if not FileExists(FileName) then
    Exit;

  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    // 读取前3个字节
    BytesRead := FileStream.Read(Buffer, 3);

    // 检查是否是UTF-8 BOM
    Result := (BytesRead = 3) and
              (Buffer[0] = UTF8_BOM[0]) and
              (Buffer[1] = UTF8_BOM[1]) and
              (Buffer[2] = UTF8_BOM[2]);
  finally
    FileStream.Free;
  end;
end;

class function TUTF8EncodingDetector_Improved.IsValidUTF8Sequence(const Bytes: TBytes; Start: Integer; out ByteCount: Integer): Boolean;
begin
  ByteCount := 0;
  Result := False;

  // 确保起始位置有效
  if (Start < 0) or (Start >= Length(Bytes)) then
    Exit;

  // ASCII字符 (0-127)
  if Bytes[Start] < $80 then
  begin
    ByteCount := 1;
    Result := True;
    Exit;
  end;

  // 检查UTF-8多字节序列
  if (Bytes[Start] and $E0) = $C0 then // 2字节序列: 110xxxxx 10xxxxxx
  begin
    // 确保有足够的字节
    if Start + 1 >= Length(Bytes) then
      Exit;

    // 检查第二个字节是否符合UTF-8格式
    if (Bytes[Start+1] and $C0) = $80 then
    begin
      // 检查是否是过长编码 (Overlong Encoding)
      if (Bytes[Start] < $C2) then
        Exit;

      ByteCount := 2;
      Result := True;
    end;
  end
  else if (Bytes[Start] and $F0) = $E0 then // 3字节序列: 1110xxxx 10xxxxxx 10xxxxxx
  begin
    // 确保有足够的字节
    if Start + 2 >= Length(Bytes) then
      Exit;

    // 检查后续字节是否符合UTF-8格式
    if ((Bytes[Start+1] and $C0) = $80) and
       ((Bytes[Start+2] and $C0) = $80) then
    begin
      // 检查是否是过长编码或代理对区域
      if ((Bytes[Start] = $E0) and (Bytes[Start+1] < $A0)) or // 过长编码
         ((Bytes[Start] = $ED) and (Bytes[Start+1] >= $A0)) then // 代理对区域
        Exit;

      ByteCount := 3;
      Result := True;
    end;
  end
  else if (Bytes[Start] and $F8) = $F0 then // 4字节序列: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
  begin
    // 确保有足够的字节
    if Start + 3 >= Length(Bytes) then
      Exit;

    // 检查后续字节是否符合UTF-8格式
    if ((Bytes[Start+1] and $C0) = $80) and
       ((Bytes[Start+2] and $C0) = $80) and
       ((Bytes[Start+3] and $C0) = $80) then
    begin
      // 检查是否是过长编码或超出Unicode范围
      if ((Bytes[Start] = $F0) and (Bytes[Start+1] < $90)) or // 过长编码
         ((Bytes[Start] = $F4) and (Bytes[Start+1] >= $90)) then // 超出Unicode范围
        Exit;

      ByteCount := 4;
      Result := True;
    end;
  end;
end;

class function TUTF8EncodingDetector_Improved.ValidateUTF8Sequence(const Buffer: TBytes; out ValidCount, InvalidCount: Int64): Boolean;
var
  i, ByteCount: Integer;
  ConsecutiveValidCount, MaxConsecutiveValid: Integer;
begin
  ValidCount := 0;
  InvalidCount := 0;
  ConsecutiveValidCount := 0;
  MaxConsecutiveValid := 0;

  i := 0;
  while i < Length(Buffer) do
  begin
    if IsValidUTF8Sequence(Buffer, i, ByteCount) then
    begin
      Inc(ValidCount, ByteCount);
      Inc(ConsecutiveValidCount);
      Inc(i, ByteCount);
    end
    else
    begin
      Inc(InvalidCount);
      MaxConsecutiveValid := Max(MaxConsecutiveValid, ConsecutiveValidCount);
      ConsecutiveValidCount := 0;
      Inc(i);
    end;
  end;

  MaxConsecutiveValid := Max(MaxConsecutiveValid, ConsecutiveValidCount);

  // 如果至少95%的字节是有效的UTF-8字节，则认为是UTF-8编码（提高阈值，减少误判）
  Result := (ValidCount > 0) and (ValidCount / (ValidCount + InvalidCount) >= 0.95);

  // 如果有连续的长UTF-8序列，也认为是UTF-8
  if (not Result) and (MaxConsecutiveValid >= 15) then // 提高连续序列长度要求
    Result := True;

  // 如果文件很小且全是ASCII，不要轻易判断为UTF-8
  if (ValidCount + InvalidCount < 100) and (ValidCount = Length(Buffer)) and (Length(Buffer) > 0) then
  begin
    var AsciiCount := 0;
    for var j := 0 to Length(Buffer) - 1 do
      if Buffer[j] < $80 then
        Inc(AsciiCount);

    if AsciiCount = Length(Buffer) then
      Result := False; // 纯ASCII小文件，不判断为UTF-8
  end;
end;

end.
