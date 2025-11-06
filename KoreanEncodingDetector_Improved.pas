unit KoreanEncodingDetector_Improved;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, System.Math, UtilsTypes;

type
  /// <summary>
  /// 韩文编码检测结果记录
  /// </summary>
  TKoreanEncodingResult = record
    Encoding: string;           // 检测到的编码
    Confidence: Double;         // 置信度 (0.0-1.0)
    HasBOM: Boolean;            // 是否有BOM
    EUCKRConfidence: Double;    // EUC-KR置信度
    UHCConfidence: Double;      // UHC置信度
    ISO2022KRConfidence: Double; // ISO-2022-KR置信度
  end;

  /// <summary>
  /// 改进的韩文编码检测器
  /// </summary>
  TKoreanEncodingDetector_Improved = class
  private
    const
      MIN_CONFIDENCE = 0.75;    // 最小置信度
      MAX_TEXT_SAMPLE = 16 * 1024; // 最大采样大小 (16KB)

    /// <summary>
    /// 检查是否是有效的EUC-KR序列
    /// </summary>
    class function IsValidEUCKRSequence(const Buffer: TBytes; Start: Integer; out ByteCount: Integer): Boolean;

    /// <summary>
    /// 检查是否是有效的UHC序列
    /// </summary>
    class function IsValidUHCSequence(const Buffer: TBytes; Start: Integer; out ByteCount: Integer): Boolean;

    /// <summary>
    /// 检查是否是有效的ISO-2022-KR序列
    /// </summary>
    class function IsValidISO2022KRSequence(const Buffer: TBytes; Start: Integer; out ByteCount: Integer): Boolean;

    /// <summary>
    /// 分析EUC-KR编码特征
    /// </summary>
    class function AnalyzeEUCKRFeatures(const Buffer: TBytes): Double;

    /// <summary>
    /// 分析UHC编码特征
    /// </summary>
    class function AnalyzeUHCFeatures(const Buffer: TBytes): Double;

    /// <summary>
    /// 分析ISO-2022-KR编码特征
    /// </summary>
    class function AnalyzeISO2022KRFeatures(const Buffer: TBytes): Double;

    /// <summary>
    /// 分析韩文编码频率特征
    /// </summary>
    class procedure AnalyzeKoreanFrequency(const Buffer: TBytes; out EUCKRScore, UHCScore, ISO2022KRScore: Double);

  public
    /// <summary>
    /// 检测文件的韩文编码
    /// </summary>
    class function DetectFile(const FileName: string): TKoreanEncodingResult;

    /// <summary>
    /// 检测字节数组的韩文编码
    /// </summary>
    class function DetectBuffer(const Buffer: TBytes): TKoreanEncodingResult;

    /// <summary>
    /// 检测流的韩文编码
    /// </summary>
    class function DetectStream(const Stream: TStream): TKoreanEncodingResult;
  end;

implementation

uses
  UtilsEncodingBOM_Improved, UtilsEncodingUTF8Detector_Improved;

{ TKoreanEncodingDetector_Improved }

class procedure TKoreanEncodingDetector_Improved.AnalyzeKoreanFrequency(
  const Buffer: TBytes; out EUCKRScore, UHCScore, ISO2022KRScore: Double);
var
  ByteFreq: array[0..255] of Integer;
  TotalBytes, KoreanBytes: Integer;
  i: Integer;
begin
  // 初始化
  EUCKRScore := 0;
  UHCScore := 0;
  ISO2022KRScore := 0;

  if Length(Buffer) = 0 then
    Exit;

  // 统计字节频率
  FillChar(ByteFreq, SizeOf(ByteFreq), 0);
  for i := 0 to Length(Buffer) - 1 do
    Inc(ByteFreq[Buffer[i]]);

  // 计算总字节数
  TotalBytes := Length(Buffer);

  // 计算韩文字节数（高位字节）
  KoreanBytes := 0;
  for i := $80 to $FF do
    Inc(KoreanBytes, ByteFreq[i]);

  // 如果没有韩文字节，则返回
  if KoreanBytes = 0 then
    Exit;

  // 计算EUC-KR特征得分
  var EUCKRLeadingBytes := 0;
  for i := $A1 to $FE do
    Inc(EUCKRLeadingBytes, ByteFreq[i]);

  var EUCKRTrailingBytes := 0;
  for i := $A1 to $FE do
    Inc(EUCKRTrailingBytes, ByteFreq[i]);

  if EUCKRLeadingBytes > 0 then
    EUCKRScore := Min(1.0, EUCKRLeadingBytes / KoreanBytes * 2);

  // 计算UHC特征得分
  var UHCLeadingBytes := 0;
  for i := $81 to $FE do
    Inc(UHCLeadingBytes, ByteFreq[i]);

  var UHCTrailingBytes := 0;
  for i := $41 to $FE do
    Inc(UHCTrailingBytes, ByteFreq[i]);

  if UHCLeadingBytes > 0 then
    UHCScore := Min(1.0, UHCLeadingBytes / KoreanBytes * 2);

  // 计算ISO-2022-KR特征得分
  var ISO2022KREscapeSeq := 0;
  for i := 0 to Length(Buffer) - 4 do
  begin
    if (Buffer[i] = $1B) and (Buffer[i+1] = $24) and (Buffer[i+2] = $29) and (Buffer[i+3] = $43) then
      Inc(ISO2022KREscapeSeq);
  end;

  if ISO2022KREscapeSeq > 0 then
    ISO2022KRScore := Min(1.0, ISO2022KREscapeSeq / 10);
end;

class function TKoreanEncodingDetector_Improved.AnalyzeEUCKRFeatures(const Buffer: TBytes): Double;
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
    if IsValidEUCKRSequence(Buffer, i, ByteCount) then
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

  // 计算EUC-KR特征得分
  if (ValidCount + InvalidCount) = 0 then
    Result := 0
  else
    Result := ValidCount / (ValidCount + InvalidCount);

  // 如果有连续的长EUC-KR序列，提高得分
  if MaxConsecutiveValid >= 5 then
    Result := Result * 1.2;

  // 限制得分在0-1范围内
  Result := Max(0, Min(1.0, Result));
end;

class function TKoreanEncodingDetector_Improved.AnalyzeISO2022KRFeatures(const Buffer: TBytes): Double;
var
  i, ByteCount, ValidCount, InvalidCount: Integer;
  ConsecutiveValidCount, MaxConsecutiveValid: Integer;
  EscapeSeqCount: Integer;
begin
  ValidCount := 0;
  InvalidCount := 0;
  ConsecutiveValidCount := 0;
  MaxConsecutiveValid := 0;
  EscapeSeqCount := 0;

  i := 0;
  while i < Length(Buffer) do
  begin
    if IsValidISO2022KRSequence(Buffer, i, ByteCount) then
    begin
      Inc(ValidCount);
      Inc(ConsecutiveValidCount);
      Inc(i, ByteCount);

      // 检查是否是转义序列
      if (ByteCount >= 4) and (Buffer[i-ByteCount] = $1B) then
        Inc(EscapeSeqCount);
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

  // 计算ISO-2022-KR特征得分
  if (ValidCount + InvalidCount) = 0 then
    Result := 0
  else
    Result := ValidCount / (ValidCount + InvalidCount);

  // 如果有转义序列，提高得分
  if EscapeSeqCount > 0 then
    Result := Result * (1.0 + Min(0.5, EscapeSeqCount / 10));

  // 限制得分在0-1范围内
  Result := Max(0, Min(1.0, Result));
end;

class function TKoreanEncodingDetector_Improved.AnalyzeUHCFeatures(const Buffer: TBytes): Double;
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
    if IsValidUHCSequence(Buffer, i, ByteCount) then
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

  // 计算UHC特征得分
  if (ValidCount + InvalidCount) = 0 then
    Result := 0
  else
    Result := ValidCount / (ValidCount + InvalidCount);

  // 如果有连续的长UHC序列，提高得分
  if MaxConsecutiveValid >= 5 then
    Result := Result * 1.2;

  // 限制得分在0-1范围内
  Result := Max(0, Min(1.0, Result));
end;

class function TKoreanEncodingDetector_Improved.DetectBuffer(const Buffer: TBytes): TKoreanEncodingResult;
var
  BOMResult: TBOMDetectionResult;
  UTF8Result: TUTF8DetectionResult;
  EUCKRScore, UHCScore, ISO2022KRScore: Double;
  FreqEUCKRScore, FreqUHCScore, FreqISO2022KRScore: Double;
  FinalEUCKRScore, FinalUHCScore, FinalISO2022KRScore: Double;
begin
  // 初始化结果
  Result.Encoding := ENCODING_UNKNOWN;
  Result.Confidence := 0.0;
  Result.HasBOM := False;
  Result.EUCKRConfidence := 0.0;
  Result.UHCConfidence := 0.0;
  Result.ISO2022KRConfidence := 0.0;

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

  // 如果是UTF-8，直接返回
  if UTF8Result.IsUTF8 then
  begin
    Result.Encoding := ENCODING_UTF8;
    Result.Confidence := UTF8Result.Confidence;
    Result.HasBOM := UTF8Result.HasBOM;
    Exit;
  end;

  // 分析韩文编码特征
  EUCKRScore := AnalyzeEUCKRFeatures(Buffer);
  UHCScore := AnalyzeUHCFeatures(Buffer);
  ISO2022KRScore := AnalyzeISO2022KRFeatures(Buffer);

  // 分析韩文编码频率特征
  AnalyzeKoreanFrequency(Buffer, FreqEUCKRScore, FreqUHCScore, FreqISO2022KRScore);

  // 综合计算最终得分
  FinalEUCKRScore := 0.65 * EUCKRScore + 0.35 * FreqEUCKRScore;
  FinalUHCScore := 0.65 * UHCScore + 0.35 * FreqUHCScore;
  FinalISO2022KRScore := 0.65 * ISO2022KRScore + 0.35 * FreqISO2022KRScore;

  // 检查是否有特征字节
  var HasEUCKRSpecificBytes := False;
  for var j := 0 to Length(Buffer) - 2 do
  begin
    if (j + 1 < Length(Buffer)) and
       (Buffer[j] >= $A1) and (Buffer[j] <= $FE) and
       (Buffer[j+1] >= $A1) and (Buffer[j+1] <= $FE) then
    begin
      HasEUCKRSpecificBytes := True;
      Break;
    end;
  end;

  if HasEUCKRSpecificBytes then
    FinalEUCKRScore := FinalEUCKRScore * 1.2;

  var HasUHCSpecificBytes := False;
  for var j := 0 to Length(Buffer) - 2 do
  begin
    if (j + 1 < Length(Buffer)) and
       (Buffer[j] >= $81) and (Buffer[j] <= $FE) and
       (((Buffer[j+1] >= $41) and (Buffer[j+1] <= $5A)) or
        ((Buffer[j+1] >= $61) and (Buffer[j+1] <= $7A)) or
        ((Buffer[j+1] >= $81) and (Buffer[j+1] <= $FE))) then
    begin
      HasUHCSpecificBytes := True;
      Break;
    end;
  end;

  if HasUHCSpecificBytes then
    FinalUHCScore := FinalUHCScore * 1.2;

  var HasISO2022KRSpecificBytes := False;
  for var j := 0 to Length(Buffer) - 4 do
  begin
    if (j + 3 < Length(Buffer)) and
       (Buffer[j] = $1B) and (Buffer[j+1] = $24) and (Buffer[j+2] = $29) and (Buffer[j+3] = $43) then
    begin
      HasISO2022KRSpecificBytes := True;
      Break;
    end;
  end;

  if HasISO2022KRSpecificBytes then
    FinalISO2022KRScore := FinalISO2022KRScore * 1.5;

  // 保存置信度
  Result.EUCKRConfidence := FinalEUCKRScore;
  Result.UHCConfidence := FinalUHCScore;
  Result.ISO2022KRConfidence := FinalISO2022KRScore;

  // 确定最可能的编码
  var MaxScore := Max(Max(FinalEUCKRScore, FinalUHCScore), FinalISO2022KRScore);

  if MaxScore < MIN_CONFIDENCE then
  begin
    // 如果所有韩文编码的置信度都不够高，则返回ANSI
    Result.Encoding := ENCODING_ANSI;
    Result.Confidence := 0.5;
  end
  else if FinalEUCKRScore >= MaxScore then
  begin
    Result.Encoding := ENCODING_EUC_KR;
    Result.Confidence := FinalEUCKRScore;
  end
  else if FinalUHCScore >= MaxScore then
  begin
    Result.Encoding := 'UHC';
    Result.Confidence := FinalUHCScore;
  end
  else if FinalISO2022KRScore >= MaxScore then
  begin
    Result.Encoding := ENCODING_ISO_2022_KR;
    Result.Confidence := FinalISO2022KRScore;
  end;
end;

class function TKoreanEncodingDetector_Improved.DetectFile(const FileName: string): TKoreanEncodingResult;
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
  Result.EUCKRConfidence := 0.0;
  Result.UHCConfidence := 0.0;
  Result.ISO2022KRConfidence := 0.0;

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

class function TKoreanEncodingDetector_Improved.DetectStream(const Stream: TStream): TKoreanEncodingResult;
var
  Buffer: TBytes;
  Position: Int64;
  ReadSize: Int64;
begin
  // 初始化默认结果
  Result.Encoding := ENCODING_UNKNOWN;
  Result.Confidence := 0.0;
  Result.HasBOM := False;
  Result.EUCKRConfidence := 0.0;
  Result.UHCConfidence := 0.0;
  Result.ISO2022KRConfidence := 0.0;

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

class function TKoreanEncodingDetector_Improved.IsValidEUCKRSequence(const Buffer: TBytes; Start: Integer; out ByteCount: Integer): Boolean;
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

  // 检查EUC-KR双字节序列
  if (Buffer[Start] >= $A1) and (Buffer[Start] <= $FE) then
  begin
    // 确保有足够的字节
    if Start + 1 >= Length(Buffer) then
      Exit;

    // 检查第二个字节是否符合EUC-KR格式
    if (Buffer[Start+1] >= $A1) and (Buffer[Start+1] <= $FE) then
    begin
      ByteCount := 2;
      Result := True;
      Exit;
    end;
  end;
end;

class function TKoreanEncodingDetector_Improved.IsValidISO2022KRSequence(const Buffer: TBytes; Start: Integer; out ByteCount: Integer): Boolean;
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

  // 检查ISO-2022-KR转义序列
  if Buffer[Start] = $1B then
  begin
    // 确保有足够的字节
    if Start + 3 >= Length(Buffer) then
      Exit;

    // 检查是否是韩文模式转义序列
    if (Buffer[Start+1] = $24) and (Buffer[Start+2] = $29) and (Buffer[Start+3] = $43) then
    begin
      ByteCount := 4;
      Result := True;
      Exit;
    end;
  end;

  // 在韩文模式下的字符
  // 注意：这里简化处理，实际上需要跟踪当前模式
  if (Buffer[Start] >= $21) and (Buffer[Start] <= $7E) then
  begin
    // 确保有足够的字节
    if Start + 1 >= Length(Buffer) then
      Exit;

    // 检查第二个字节是否符合ISO-2022-KR韩文模式格式
    if (Buffer[Start+1] >= $21) and (Buffer[Start+1] <= $7E) then
    begin
      ByteCount := 2;
      Result := True;
      Exit;
    end;
  end;
end;

class function TKoreanEncodingDetector_Improved.IsValidUHCSequence(const Buffer: TBytes; Start: Integer; out ByteCount: Integer): Boolean;
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

  // 检查UHC双字节序列
  if (Buffer[Start] >= $81) and (Buffer[Start] <= $FE) then
  begin
    // 确保有足够的字节
    if Start + 1 >= Length(Buffer) then
      Exit;

    // 检查第二个字节是否符合UHC格式
    if ((Buffer[Start+1] >= $41) and (Buffer[Start+1] <= $5A)) or
       ((Buffer[Start+1] >= $61) and (Buffer[Start+1] <= $7A)) or
       ((Buffer[Start+1] >= $81) and (Buffer[Start+1] <= $FE)) then
    begin
      ByteCount := 2;
      Result := True;
      Exit;
    end;
  end;
end;

end.