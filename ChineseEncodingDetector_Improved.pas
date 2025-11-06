unit ChineseEncodingDetector_Improved;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, System.Math, UtilsTypes;

type
  /// <summary>
  /// 中文编码检测结果记录
  /// </summary>
  TChineseEncodingResult = record
    Encoding: string;           // 检测到的编码
    Confidence: Double;         // 置信度 (0.0-1.0)
    HasBOM: Boolean;            // 是否有BOM
    GBKConfidence: Double;      // GBK置信度
    GB18030Confidence: Double;  // GB18030置信度
    Big5Confidence: Double;     // Big5置信度
    GB2312Confidence: Double;   // GB2312置信度
    UTF8Confidence: Double;     // UTF-8置信度
  end;

  /// <summary>
  /// 改进的中文编码检测器
  /// </summary>
  TChineseEncodingDetector_Improved = class
  private
    const
      MIN_CONFIDENCE = 0.75;    // 最小置信度（提高阈值，减少误判）
      MAX_TEXT_SAMPLE = 16 * 1024; // 最大采样大小 (16KB)

    /// <summary>
    /// 检查是否是有效的GBK序列
    /// </summary>
    class function IsValidGBKSequence(const Buffer: TBytes; Start: Integer; out ByteCount: Integer): Boolean;

    /// <summary>
    /// 检查是否是有效的GB18030序列
    /// </summary>
    class function IsValidGB18030Sequence(const Buffer: TBytes; Start: Integer; out ByteCount: Integer): Boolean;

    /// <summary>
    /// 检查是否是有效的Big5序列
    /// </summary>
    class function IsValidBig5Sequence(const Buffer: TBytes; Start: Integer; out ByteCount: Integer): Boolean;

    /// <summary>
    /// 检查是否是有效的GB2312序列
    /// </summary>
    class function IsValidGB2312Sequence(const Buffer: TBytes; Start: Integer; out ByteCount: Integer): Boolean;

    /// <summary>
    /// 分析GBK编码特征
    /// </summary>
    class function AnalyzeGBKFeatures(const Buffer: TBytes): Double;

    /// <summary>
    /// 分析GB18030编码特征
    /// </summary>
    class function AnalyzeGB18030Features(const Buffer: TBytes): Double;

    /// <summary>
    /// 分析Big5编码特征
    /// </summary>
    class function AnalyzeBig5Features(const Buffer: TBytes): Double;

    /// <summary>
    /// 分析GB2312编码特征
    /// </summary>
    class function AnalyzeGB2312Features(const Buffer: TBytes): Double;

    /// <summary>
    /// 分析中文编码频率特征
    /// </summary>
    class procedure AnalyzeChineseFrequency(const Buffer: TBytes; out GBKScore, GB18030Score, Big5Score, GB2312Score: Double);

  public
    /// <summary>
    /// 检测文件的中文编码
    /// </summary>
    class function DetectFile(const FileName: string): TChineseEncodingResult;

    /// <summary>
    /// 检测字节数组的中文编码
    /// </summary>
    class function DetectBuffer(const Buffer: TBytes): TChineseEncodingResult;

    /// <summary>
    /// 检测流的中文编码
    /// </summary>
    class function DetectStream(const Stream: TStream): TChineseEncodingResult;
  end;

implementation

uses
  UtilsEncodingBOM_Improved, UtilsEncodingUTF8Detector_Improved;

const
  // 本地定义未知编码常量，避免依赖 UtilsEncodingTypes
  ENCODING_UNKNOWN = 'Unknown';

{ TChineseEncodingDetector_Improved }

class procedure TChineseEncodingDetector_Improved.AnalyzeChineseFrequency(
  const Buffer: TBytes; out GBKScore, GB18030Score, Big5Score, GB2312Score: Double);
var
  ByteFreq: array[0..255] of Integer;
  TotalBytes, ChineseBytes: Integer;
  i: Integer;
begin
  // 初始化
  GBKScore := 0;
  GB18030Score := 0;
  Big5Score := 0;
  GB2312Score := 0;

  if Length(Buffer) = 0 then
    Exit;

  // 统计字节频率
  FillChar(ByteFreq, SizeOf(ByteFreq), 0);
  for i := 0 to Length(Buffer) - 1 do
    Inc(ByteFreq[Buffer[i]]);

  // 计算总字节数
  TotalBytes := Length(Buffer);

  // 计算中文字节数（高位字节）
  ChineseBytes := 0;
  for i := $80 to $FF do
    Inc(ChineseBytes, ByteFreq[i]);

  // 如果没有中文字节，则返回
  if ChineseBytes = 0 then
    Exit;

  // 计算GBK特征得分
  var GBKLeadingBytes := 0;
  for i := $81 to $FE do
    Inc(GBKLeadingBytes, ByteFreq[i]);

  if GBKLeadingBytes > 0 then
    GBKScore := Min(1.0, GBKLeadingBytes / ChineseBytes * 2);

  // 计算GB18030特征得分
  var GB18030FourByteLeading := 0;
  for i := $81 to $FE do
    Inc(GB18030FourByteLeading, ByteFreq[i]);

  var GB18030FourByteSecond := 0;
  for i := $30 to $39 do
    Inc(GB18030FourByteSecond, ByteFreq[i]);

  var GB18030FourByteThird := 0;
  for i := $81 to $FE do
    Inc(GB18030FourByteThird, ByteFreq[i]);

  var GB18030FourByteFourth := 0;
  for i := $30 to $39 do
    Inc(GB18030FourByteFourth, ByteFreq[i]);

  if (GB18030FourByteLeading > 0) and (GB18030FourByteSecond > 0) and
     (GB18030FourByteThird > 0) and (GB18030FourByteFourth > 0) then
    GB18030Score := Min(1.0, (GB18030FourByteLeading + GB18030FourByteSecond +
                              GB18030FourByteThird + GB18030FourByteFourth) / (ChineseBytes * 2));

  // 计算Big5特征得分
  var Big5LeadingBytes := 0;
  for i := $A1 to $F9 do
    Inc(Big5LeadingBytes, ByteFreq[i]);

  if Big5LeadingBytes > 0 then
    Big5Score := Min(1.0, Big5LeadingBytes / ChineseBytes * 2);

  // 计算GB2312特征得分
  var GB2312LeadingBytes := 0;
  for i := $A1 to $F7 do
    Inc(GB2312LeadingBytes, ByteFreq[i]);

  if GB2312LeadingBytes > 0 then
    GB2312Score := Min(1.0, GB2312LeadingBytes / ChineseBytes * 2);
end;

class function TChineseEncodingDetector_Improved.AnalyzeBig5Features(const Buffer: TBytes): Double;
var
  i, ByteCount, ValidCount, InvalidCount: Integer;
  ConsecutiveValidCount, MaxConsecutiveValid: Integer;
begin
  ValidCount := 0;
  InvalidCount := 0;
  ConsecutiveValidCount := 0;
  MaxConsecutiveValid := 0;

  i := 0;
  while i < Length(Buffer) do
  begin
    if IsValidBig5Sequence(Buffer, i, ByteCount) then
    begin
      Inc(ValidCount);
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

  // 计算Big5特征得分
  if (ValidCount + InvalidCount) = 0 then
    Result := 0
  else
    Result := ValidCount / (ValidCount + InvalidCount);

  // 如果有连续的长Big5序列，提高得分
  if MaxConsecutiveValid >= 5 then
    Result := Result * 1.2;

  // 限制得分在0-1范围内
  Result := Max(0, Min(1.0, Result));
end;

class function TChineseEncodingDetector_Improved.AnalyzeGB18030Features(const Buffer: TBytes): Double;
var
  i, ByteCount, ValidCount, InvalidCount: Integer;
  ConsecutiveValidCount, MaxConsecutiveValid: Integer;
begin
  ValidCount := 0;
  InvalidCount := 0;
  ConsecutiveValidCount := 0;
  MaxConsecutiveValid := 0;

  i := 0;
  while i < Length(Buffer) do
  begin
    if IsValidGB18030Sequence(Buffer, i, ByteCount) then
    begin
      Inc(ValidCount);
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

  // 计算GB18030特征得分
  if (ValidCount + InvalidCount) = 0 then
    Result := 0
  else
    Result := ValidCount / (ValidCount + InvalidCount);

  // 如果有连续的长GB18030序列，提高得分
  if MaxConsecutiveValid >= 5 then
    Result := Result * 1.2;

  // 限制得分在0-1范围内
  Result := Max(0, Min(1.0, Result));
end;

class function TChineseEncodingDetector_Improved.AnalyzeGB2312Features(const Buffer: TBytes): Double;
var
  i, ByteCount, ValidCount, InvalidCount: Integer;
  ConsecutiveValidCount, MaxConsecutiveValid: Integer;
begin
  ValidCount := 0;
  InvalidCount := 0;
  ConsecutiveValidCount := 0;
  MaxConsecutiveValid := 0;

  i := 0;
  while i < Length(Buffer) do
  begin
    if IsValidGB2312Sequence(Buffer, i, ByteCount) then
    begin
      Inc(ValidCount);
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

  // 计算GB2312特征得分
  if (ValidCount + InvalidCount) = 0 then
    Result := 0
  else
    Result := ValidCount / (ValidCount + InvalidCount);

  // 如果有连续的长GB2312序列，提高得分
  if MaxConsecutiveValid >= 5 then
    Result := Result * 1.2;

  // 限制得分在0-1范围内
  Result := Max(0, Min(1.0, Result));
end;

class function TChineseEncodingDetector_Improved.AnalyzeGBKFeatures(const Buffer: TBytes): Double;
var
  i, ByteCount, ValidCount, InvalidCount: Integer;
  ConsecutiveValidCount, MaxConsecutiveValid: Integer;
begin
  ValidCount := 0;
  InvalidCount := 0;
  ConsecutiveValidCount := 0;
  MaxConsecutiveValid := 0;

  i := 0;
  while i < Length(Buffer) do
  begin
    if IsValidGBKSequence(Buffer, i, ByteCount) then
    begin
      Inc(ValidCount);
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

  // 计算GBK特征得分
  if (ValidCount + InvalidCount) = 0 then
    Result := 0
  else
    Result := ValidCount / (ValidCount + InvalidCount);

  // 如果有连续的长GBK序列，提高得分
  if MaxConsecutiveValid >= 5 then
    Result := Result * 1.2;

  // 限制得分在0-1范围内
  Result := Max(0, Min(1.0, Result));
end;

class function TChineseEncodingDetector_Improved.DetectBuffer(const Buffer: TBytes): TChineseEncodingResult;
var
  BOMResult: TBOMDetectionResult;
  UTF8Result: TUTF8DetectionResult;
  GBKScore, GB18030Score, Big5Score, GB2312Score: Double;
  FreqGBKScore, FreqGB18030Score, FreqBig5Score, FreqGB2312Score: Double;
  FinalGBKScore, FinalGB18030Score, FinalBig5Score, FinalGB2312Score: Double;
begin
  // 初始化结果
  Result.Encoding := ENCODING_UNKNOWN;
  Result.Confidence := 0.0;
  Result.HasBOM := False;
  Result.GBKConfidence := 0.0;
  Result.GB18030Confidence := 0.0;
  Result.Big5Confidence := 0.0;
  Result.GB2312Confidence := 0.0;
  Result.UTF8Confidence := 0.0;

  if Length(Buffer) = 0 then
    Exit;

  // 检测BOM
  BOMResult := TEncodingBOMDetector_Improved.DetectBOM(Buffer);

  // 如果有BOM，直接返回对应的编码
  if BOMResult.BOMType <> 0 then
  begin
    Result.Encoding := BOMResult.Encoding;
    Result.Confidence := 1.0;
    Result.HasBOM := True;
    Exit;
  end;

  // 检测UTF-8
  UTF8Result := TUTF8EncodingDetector_Improved.DetectBuffer(Buffer);
  Result.UTF8Confidence := UTF8Result.Confidence;

  // 如果是UTF-8，直接返回
  if UTF8Result.IsUTF8 then
  begin
    Result.Encoding := ENCODING_UTF8;
    Result.Confidence := UTF8Result.Confidence;
    Result.HasBOM := UTF8Result.HasBOM;
    Exit;
  end;

  // 分析中文编码特征
  GBKScore := AnalyzeGBKFeatures(Buffer);
  GB18030Score := AnalyzeGB18030Features(Buffer);
  Big5Score := AnalyzeBig5Features(Buffer);
  GB2312Score := AnalyzeGB2312Features(Buffer);

  // 分析中文编码频率特征
  AnalyzeChineseFrequency(Buffer, FreqGBKScore, FreqGB18030Score, FreqBig5Score, FreqGB2312Score);

  // 综合计算最终得分（调整权重，提高准确度）
  FinalGBKScore := 0.65 * GBKScore + 0.35 * FreqGBKScore;
  FinalGB18030Score := 0.65 * GB18030Score + 0.35 * FreqGB18030Score;
  FinalBig5Score := 0.65 * Big5Score + 0.35 * FreqBig5Score;
  FinalGB2312Score := 0.65 * GB2312Score + 0.35 * FreqGB2312Score;

  // 对于GBK和GB18030，它们有重叠部分，需要特殊处理
  if (FinalGBKScore > 0.6) and (FinalGB18030Score > 0.6) then
  begin
    // 如果检测到四字节序列，优先考虑GB18030
    var HasFourByteSequence := False;
    for var i := 0 to Length(Buffer) - 4 do
    begin
      if (i + 3 < Length(Buffer)) and
         (Buffer[i] >= $81) and (Buffer[i] <= $FE) and
         (Buffer[i+1] >= $30) and (Buffer[i+1] <= $39) and
         (Buffer[i+2] >= $81) and (Buffer[i+2] <= $FE) and
         (Buffer[i+3] >= $30) and (Buffer[i+3] <= $39) then
      begin
        HasFourByteSequence := True;
        Break;
      end;
    end;

    if HasFourByteSequence then
      FinalGB18030Score := FinalGB18030Score * 1.2
    else
      FinalGBKScore := FinalGBKScore * 1.1;
  end;

  // 对于Big5，检查是否有特征字节
  var HasBig5SpecificBytes := False;
  for var i := 0 to Length(Buffer) - 2 do
  begin
    if (i + 1 < Length(Buffer)) and
       (((Buffer[i] >= $C6) and (Buffer[i] <= $C8)) or
        ((Buffer[i] >= $F9) and (Buffer[i] <= $FE))) and
       (((Buffer[i+1] >= $40) and (Buffer[i+1] <= $7E)) or
        ((Buffer[i+1] >= $A1) and (Buffer[i+1] <= $FE))) then
    begin
      HasBig5SpecificBytes := True;
      Break;
    end;
  end;

  if HasBig5SpecificBytes then
    FinalBig5Score := FinalBig5Score * 1.2;

  // 保存置信度
  Result.GBKConfidence := FinalGBKScore;
  Result.GB18030Confidence := FinalGB18030Score;
  Result.Big5Confidence := FinalBig5Score;
  Result.GB2312Confidence := FinalGB2312Score;

  // 确定最可能的编码
  var MaxScore := Max(Max(FinalGBKScore, FinalGB18030Score), Max(FinalBig5Score, FinalGB2312Score));

  if MaxScore < MIN_CONFIDENCE then
  begin
    // 如果所有中文编码的置信度都不够高，则返回ANSI
    Result.Encoding := ENCODING_ANSI;
    Result.Confidence := 0.5;
  end
  else
  begin
    // 检查是否有明显的台湾地区特征（繁体中文）
    var HasTaiwanFeature := False;
    var TaiwanSpecificChars := 0;

    // 检查Big5特有的字符组合
    for var i := 0 to Length(Buffer) - 2 do
    begin
      if (i + 1 < Length(Buffer)) and
         (Buffer[i] = $A4) and (Buffer[i+1] >= $40) and (Buffer[i+1] <= $7E) then
      begin
        Inc(TaiwanSpecificChars);
      end;
    end;

    if TaiwanSpecificChars > 5 then
      HasTaiwanFeature := True;

    // 检查是否有明显的大陆地区特征（简体中文）
    var HasMainlandFeature := False;
    var MainlandSpecificChars := 0;

    // 检查GBK特有的字符组合
    for var i := 0 to Length(Buffer) - 2 do
    begin
      if (i + 1 < Length(Buffer)) and
         (Buffer[i] = $D6) and (Buffer[i+1] >= $D0) and (Buffer[i+1] <= $D9) then
      begin
        Inc(MainlandSpecificChars);
      end;
    end;

    if MainlandSpecificChars > 5 then
      HasMainlandFeature := True;

    // 根据地区特征和置信度确定编码
    if HasTaiwanFeature and (FinalBig5Score >= MIN_CONFIDENCE) then
    begin
      Result.Encoding := ENCODING_BIG5;
      Result.Confidence := Max(FinalBig5Score, 0.85);
    end
    else if HasMainlandFeature and (FinalGB18030Score >= MIN_CONFIDENCE) then
    begin
      Result.Encoding := ENCODING_GB18030;
      Result.Confidence := Max(FinalGB18030Score, 0.85);
    end
    else if HasMainlandFeature and (FinalGBKScore >= MIN_CONFIDENCE) then
    begin
      Result.Encoding := ENCODING_GBK;
      Result.Confidence := Max(FinalGBKScore, 0.85);
    end
    else if FinalGBKScore >= MaxScore then
    begin
      Result.Encoding := ENCODING_GBK;
      Result.Confidence := FinalGBKScore;
    end
    else if FinalGB18030Score >= MaxScore then
    begin
      Result.Encoding := ENCODING_GB18030;
      Result.Confidence := FinalGB18030Score;
    end
    else if FinalBig5Score >= MaxScore then
    begin
      Result.Encoding := ENCODING_BIG5;
      Result.Confidence := FinalBig5Score;
    end
    else if FinalGB2312Score >= MaxScore then
    begin
      Result.Encoding := ENCODING_GB2312;
      Result.Confidence := FinalGB2312Score;
    end;
  end;
end;

class function TChineseEncodingDetector_Improved.DetectFile(const FileName: string): TChineseEncodingResult;
var
  FileStream: TFileStream;
  Buffer: TBytes;
  ReadSize: Int64;
const
  MAX_READ_SIZE = 16 * 1024 * 1024; // 最多读取16MB
begin
  // 初始化默认结果
  Result.Encoding := ENCODING_UNKNOWN;
  Result.Confidence := 0.0;
  Result.HasBOM := False;
  Result.GBKConfidence := 0.0;
  Result.GB18030Confidence := 0.0;
  Result.Big5Confidence := 0.0;
  Result.GB2312Confidence := 0.0;
  Result.UTF8Confidence := 0.0;

  if not FileExists(FileName) then
    Exit;

  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    // 对于空文件，默认返回ANSI
    if FileStream.Size = 0 then
    begin
      Result.Encoding := ENCODING_ANSI;
      Result.Confidence := 1.0;
      Exit;
    end;

    // 读取文件内容进行分析
    FileStream.Position := 0;

    // 限制读取大小，避免处理过大的文件
    ReadSize := Min(FileStream.Size, MAX_READ_SIZE);
    SetLength(Buffer, ReadSize);
    FileStream.ReadBuffer(Buffer[0], ReadSize);

    // 分析缓冲区
    Result := DetectBuffer(Buffer);
  finally
    FileStream.Free;
  end;
end;

class function TChineseEncodingDetector_Improved.DetectStream(const Stream: TStream): TChineseEncodingResult;
var
  Buffer: TBytes;
  Position: Int64;
  ReadSize: Int64;
begin
  // 初始化默认结果
  Result.Encoding := ENCODING_UNKNOWN;
  Result.Confidence := 0.0;
  Result.HasBOM := False;
  Result.GBKConfidence := 0.0;
  Result.GB18030Confidence := 0.0;
  Result.Big5Confidence := 0.0;
  Result.GB2312Confidence := 0.0;
  Result.UTF8Confidence := 0.0;

  if Stream = nil then
    Exit;

  // 保存当前流位置
  Position := Stream.Position;

  try
    // 对于空流，默认返回ANSI
    if Stream.Size = 0 then
    begin
      Result.Encoding := ENCODING_ANSI;
      Result.Confidence := 1.0;
      Exit;
    end;

    // 重置流位置
    Stream.Position := 0;

    // 读取流内容进行分析
    ReadSize := Min(Stream.Size, MAX_TEXT_SAMPLE);
    SetLength(Buffer, ReadSize);
    Stream.ReadBuffer(Buffer[0], ReadSize);

    // 分析缓冲区
    Result := DetectBuffer(Buffer);
  finally
    // 恢复流位置
    Stream.Position := Position;
  end;
end;

class function TChineseEncodingDetector_Improved.IsValidBig5Sequence(const Buffer: TBytes; Start: Integer; out ByteCount: Integer): Boolean;
begin
  ByteCount := 0;
  Result := False;

  // 确保起始位置有效
  if (Start < 0) or (Start >= Length(Buffer)) then
    Exit;

  // ASCII字符 (0-127)
  if Buffer[Start] < $80 then
  begin
    ByteCount := 1;
    Result := True;
    Exit;
  end;

  // 检查Big5双字节序列
  if (Buffer[Start] >= $A1) and (Buffer[Start] <= $F9) then
  begin
    // 确保有足够的字节
    if Start + 1 >= Length(Buffer) then
      Exit;

    // 检查第二个字节是否符合Big5格式
    if ((Buffer[Start+1] >= $40) and (Buffer[Start+1] <= $7E)) or
       ((Buffer[Start+1] >= $A1) and (Buffer[Start+1] <= $FE)) then
    begin
      ByteCount := 2;
      Result := True;
    end;
  end;
end;

class function TChineseEncodingDetector_Improved.IsValidGB18030Sequence(const Buffer: TBytes; Start: Integer; out ByteCount: Integer): Boolean;
begin
  ByteCount := 0;
  Result := False;

  // 确保起始位置有效
  if (Start < 0) or (Start >= Length(Buffer)) then
    Exit;

  // ASCII字符 (0-127)
  if Buffer[Start] < $80 then
  begin
    ByteCount := 1;
    Result := True;
    Exit;
  end;

  // 检查GB18030双字节序列
  if (Buffer[Start] >= $81) and (Buffer[Start] <= $FE) then
  begin
    // 确保有足够的字节
    if Start + 1 >= Length(Buffer) then
      Exit;

    // 检查第二个字节是否符合GB18030双字节格式
    if ((Buffer[Start+1] >= $40) and (Buffer[Start+1] <= $7E)) or
       ((Buffer[Start+1] >= $80) and (Buffer[Start+1] <= $FE)) then
    begin
      ByteCount := 2;
      Result := True;
      Exit;
    end;

    // 检查GB18030四字节序列
    if (Buffer[Start+1] >= $30) and (Buffer[Start+1] <= $39) then
    begin
      // 确保有足够的字节
      if Start + 3 >= Length(Buffer) then
        Exit;

      // 检查第三、四个字节是否符合GB18030四字节格式
      if (Buffer[Start+2] >= $81) and (Buffer[Start+2] <= $FE) and
         (Buffer[Start+3] >= $30) and (Buffer[Start+3] <= $39) then
      begin
        ByteCount := 4;
        Result := True;
      end;
    end;
  end;
end;

class function TChineseEncodingDetector_Improved.IsValidGB2312Sequence(const Buffer: TBytes; Start: Integer; out ByteCount: Integer): Boolean;
begin
  ByteCount := 0;
  Result := False;

  // 确保起始位置有效
  if (Start < 0) or (Start >= Length(Buffer)) then
    Exit;

  // ASCII字符 (0-127)
  if Buffer[Start] < $80 then
  begin
    ByteCount := 1;
    Result := True;
    Exit;
  end;

  // 检查GB2312双字节序列
  if (Buffer[Start] >= $A1) and (Buffer[Start] <= $F7) then
  begin
    // 确保有足够的字节
    if Start + 1 >= Length(Buffer) then
      Exit;

    // 检查第二个字节是否符合GB2312格式
    if (Buffer[Start+1] >= $A1) and (Buffer[Start+1] <= $FE) then
    begin
      ByteCount := 2;
      Result := True;
    end;
  end;
end;

class function TChineseEncodingDetector_Improved.IsValidGBKSequence(const Buffer: TBytes; Start: Integer; out ByteCount: Integer): Boolean;
begin
  ByteCount := 0;
  Result := False;

  // 确保起始位置有效
  if (Start < 0) or (Start >= Length(Buffer)) then
    Exit;

  // ASCII字符 (0-127)
  if Buffer[Start] < $80 then
  begin
    ByteCount := 1;
    Result := True;
    Exit;
  end;

  // 检查GBK双字节序列
  if (Buffer[Start] >= $81) and (Buffer[Start] <= $FE) then
  begin
    // 确保有足够的字节
    if Start + 1 >= Length(Buffer) then
      Exit;

    // 检查第二个字节是否符合GBK格式
    if ((Buffer[Start+1] >= $40) and (Buffer[Start+1] <= $7E)) or
       ((Buffer[Start+1] >= $80) and (Buffer[Start+1] <= $FE)) then
    begin
      ByteCount := 2;
      Result := True;
    end;
  end;
end;

end.
