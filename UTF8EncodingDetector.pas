unit UTF8EncodingDetector;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils;

type
  // UTF-8检测结果类型
  TUTF8DetectionResult = record
    IsUTF8: Boolean;        // 是否是UTF-8编码
    HasBOM: Boolean;        // 是否有BOM
    Confidence: Double;     // 置信度(0.0-1.0)
    ValidByteCount: Int64;  // 有效UTF-8字节数
    InvalidByteCount: Int64; // 无效UTF-8字节数
    TotalByteCount: Int64;  // 总字节数
  end;

  // UTF-8编码检测器
  TUTF8EncodingDetector = class
  private
    class var FUTF8BOM: TBytes;
    class constructor Create;

    // 检查是否含有UTF-8签名(BOM)
    class function HasUTF8BOM(const Buffer: TBytes): Boolean; overload;
    
    // 高级UTF-8有效性检查
    class function ValidateUTF8Sequence(const Buffer: TBytes; 
      out ValidCount, InvalidCount: Int64): Boolean;
    
    // 根据字节分布统计推测是否为UTF-8
    class function AnalyzeByteDistribution(const Buffer: TBytes): Double;
    
    // 字符序列频率分析
    class function AnalyzeSequenceFrequency(const Buffer: TBytes): Double;

    // 检查UTF8序列有效性
    function IsValidUTF8Sequence(const Bytes: TBytes; Start: Integer; var ByteCount: Integer): Boolean;
    // 分析文本统计特征
    function AnalyzeTextCharacteristics(const Stream: TStream): Double;
  public
    // 检测文件是否是UTF-8编码
    class function DetectFile(const FileName: string): TUTF8DetectionResult;
    
    // 检测字节数组是否是UTF-8编码
    class function DetectBuffer(const Buffer: TBytes): TUTF8DetectionResult;
    
    // 检测字符串是否是有效的UTF-8
    class function IsValidUTF8String(const Str: string): Boolean;
    
    // 检查是否含有UTF-8签名(BOM)
    class function HasUTF8BOM(const FileName: string): Boolean; overload;
    
    // 获取编码检测的详细报告
    class function GetDetailedReport(const FileName: string): string;

    // 检测内存流是否为UTF8编码
    function IsUTF8Encoded(const Stream: TStream): Boolean;
    // 检测内存块是否为UTF8编码
    function IsUTF8EncodedBytes(const Bytes: TBytes): Boolean;
    // 检测文件是否为UTF8编码
    function IsUTF8EncodedFile(const FileName: string): Boolean;
    // 获取UTF8文本的置信度
    function GetUTF8Confidence(const Stream: TStream): Double;
  end;

implementation

uses
  System.Math;
  
const
  // UTF8检测参数
  MIN_UTF8_CONFIDENCE = 0.85;  // 最小置信度
  MAX_TEXT_SAMPLE = 1024 * 16; // 最大采样大小
  
{ TUTF8EncodingDetector }

class constructor TUTF8EncodingDetector.Create;
begin
  // 初始化UTF-8 BOM常量
  FUTF8BOM := TEncoding.UTF8.GetPreamble;
end;

class function TUTF8EncodingDetector.HasUTF8BOM(const FileName: string): Boolean;
var
  FileStream: TFileStream;
  Buffer: TBytes;
begin
  Result := False;
  
  if not FileExists(FileName) then
    Exit;
    
  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    if FileStream.Size < Length(FUTF8BOM) then
      Exit;
      
    SetLength(Buffer, Length(FUTF8BOM));
    FileStream.ReadBuffer(Buffer, Length(FUTF8BOM));
    
    Result := HasUTF8BOM(Buffer);
  finally
    FileStream.Free;
  end;
end;

class function TUTF8EncodingDetector.HasUTF8BOM(const Buffer: TBytes): Boolean;
var
  i: Integer;
begin
  Result := False;
  
  if Length(Buffer) < Length(FUTF8BOM) then
    Exit;
    
  Result := True;
  for i := 0 to Length(FUTF8BOM) - 1 do
    if Buffer[i] <> FUTF8BOM[i] then
    begin
      Result := False;
      Break;
    end;
end;

class function TUTF8EncodingDetector.ValidateUTF8Sequence(const Buffer: TBytes;
  out ValidCount, InvalidCount: Int64): Boolean;
var
  i, len, ExpectedLen: Integer;
  IsValid: Boolean;
begin
  ValidCount := 0;
  InvalidCount := 0;
  len := Length(Buffer);

  i := 0;
  while i < len do
  begin
    // 检查单个字节 (ASCII范围)
    if (Buffer[i] and $80) = 0 then
    begin
      Inc(ValidCount);
      Inc(i);
      Continue;
    end;
    
    // 确定UTF-8序列的预期长度
    if (Buffer[i] and $E0) = $C0 then
      ExpectedLen := 2       // 110xxxxx 10xxxxxx
    else if (Buffer[i] and $F0) = $E0 then
      ExpectedLen := 3       // 1110xxxx 10xxxxxx 10xxxxxx
    else if (Buffer[i] and $F8) = $F0 then
      ExpectedLen := 4       // 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
    else
    begin
      // 无效的首字节
      Inc(InvalidCount);
      Inc(i);
      Continue;
    end;
    
    // 检查后续字节是否都是10xxxxxx形式
    IsValid := True;
    if i + ExpectedLen - 1 >= len then
    begin
      // 字节不足
      Inc(InvalidCount);
      Inc(i);
      Continue;
    end;
    
    for var j := 1 to ExpectedLen - 1 do
    begin
      if (Buffer[i + j] and $C0) <> $80 then
      begin
        IsValid := False;
        Break;
      end;
    end;
    
    if IsValid then
    begin
      Inc(ValidCount, ExpectedLen);
      Inc(i, ExpectedLen);
    end
    else
    begin
      Inc(InvalidCount);
      Inc(i);
    end;
  end;
  
  // 如果至少90%的字节是有效的UTF-8字节，则认为是UTF-8编码
  Result := (ValidCount > 0) and (ValidCount / (ValidCount + InvalidCount) >= 0.9);
end;

class function TUTF8EncodingDetector.AnalyzeByteDistribution(const Buffer: TBytes): Double;
var
  ByteCount: array[0..255] of Integer;
  AsciiCount, HighBitCount: Integer;
  MultiBytePatterns: Integer;
  i: Integer;
begin
  // 初始化字节计数
  FillChar(ByteCount, SizeOf(ByteCount), 0);
  
  // 统计每个字节的出现次数
  for i := 0 to Length(Buffer) - 1 do
    Inc(ByteCount[Buffer[i]]);
    
  // 计算ASCII字符和高位字节的数量
  AsciiCount := 0;
  for i := 0 to 127 do
    Inc(AsciiCount, ByteCount[i]);
    
  HighBitCount := 0;
  for i := 128 to 255 do
    Inc(HighBitCount, ByteCount[i]);
    
  // 统计多字节模式
  MultiBytePatterns := 0;
  // 计算首字节模式(110xxxxx, 1110xxxx, 11110xxx)的数量
  for i := 192 to 223 do // 110xxxxx
    Inc(MultiBytePatterns, ByteCount[i]);
  for i := 224 to 239 do // 1110xxxx
    Inc(MultiBytePatterns, ByteCount[i]);
  for i := 240 to 247 do // 11110xxx
    Inc(MultiBytePatterns, ByteCount[i]);
    
  // 计算后续字节模式(10xxxxxx)的数量
  var ContinuationBytes := 0;
  for i := 128 to 191 do // 10xxxxxx
    Inc(ContinuationBytes, ByteCount[i]);
    
  // 对于UTF-8编码，后续字节应该比首字节多(每个多字节序列有1个首字节和1-3个后续字节)
  if (MultiBytePatterns = 0) or (ContinuationBytes = 0) then
    Result := 0.0
  else if ContinuationBytes < MultiBytePatterns then
    Result := 0.3
  else
  begin
    // 理想情况下，后续字节数应该略大于首字节数的2倍(平均每个字符是3字节)
    var ExpectedRatio := 2.0;
    var ActualRatio := ContinuationBytes / MultiBytePatterns;
    
    if ActualRatio > 0.5 * ExpectedRatio then
      Result := 0.7 + 0.3 * (1.0 - Abs(ActualRatio - ExpectedRatio) / ExpectedRatio)
    else
      Result := 0.5;
  end;
end;

class function TUTF8EncodingDetector.AnalyzeSequenceFrequency(const Buffer: TBytes): Double;
var
  CommonChineseUTF8Start: array of Byte;
  CommonChineseUTF8Matches: Integer;
  i: Integer;
begin
  // 常见中文汉字在UTF-8中的首字节特征
  CommonChineseUTF8Start := [$E4, $E5, $E6, $E7, $E8, $E9];
  
  // 计算与常见中文UTF-8编码模式匹配的次数
  CommonChineseUTF8Matches := 0;
  
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
    
    if IsCommonChineseStart and
       ((Buffer[i+1] and $C0) = $80) and // 第二个字节是10xxxxxx
       ((Buffer[i+2] and $C0) = $80) then // 第三个字节是10xxxxxx
    begin
      Inc(CommonChineseUTF8Matches);
    end;
  end;
  
  // 根据中文UTF-8模式的匹配频率计算置信度
  if Length(Buffer) <= 3 then
    Result := 0.0
  else if CommonChineseUTF8Matches > 0 then
    Result := 0.8
  else
    Result := 0.0;
end;

class function TUTF8EncodingDetector.DetectBuffer(const Buffer: TBytes): TUTF8DetectionResult;
var
  ValidCount, InvalidCount: Int64;
  DistributionConfidence, FrequencyConfidence, FinalConfidence: Double;
begin
  // 初始化结果
  Result.IsUTF8 := False;
  Result.HasBOM := False;
  Result.Confidence := 0.0;
  Result.ValidByteCount := 0;
  Result.InvalidByteCount := 0;
  Result.TotalByteCount := Length(Buffer);
  
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
  var BasicConfidence := ValidCount / (ValidCount + InvalidCount);
  
  // 进行字节分布分析
  DistributionConfidence := AnalyzeByteDistribution(Buffer);
  
  // 进行序列频率分析
  FrequencyConfidence := AnalyzeSequenceFrequency(Buffer);
  
  // 综合计算最终置信度
  if FrequencyConfidence > 0.5 then
    FinalConfidence := 0.7 * BasicConfidence + 0.2 * DistributionConfidence + 0.1 * FrequencyConfidence
  else
    FinalConfidence := 0.8 * BasicConfidence + 0.2 * DistributionConfidence;
    
  Result.Confidence := FinalConfidence;
  
  // 根据置信度调整最终结果
  if not Result.IsUTF8 and (FinalConfidence > 0.9) then
    Result.IsUTF8 := True
  else if Result.IsUTF8 and (FinalConfidence < 0.5) then
    Result.IsUTF8 := False;
end;

class function TUTF8EncodingDetector.DetectFile(const FileName: string): TUTF8DetectionResult;
var
  FileStream: TFileStream;
  Buffer: TBytes;
  ReadSize: Int64;
const
  MAX_READ_SIZE = 8 * 1024 * 1024; // 最多读取8MB
begin
  // 初始化默认结果
  Result.IsUTF8 := False;
  Result.HasBOM := False;
  Result.Confidence := 0.0;
  Result.ValidByteCount := 0;
  Result.InvalidByteCount := 0;
  Result.TotalByteCount := 0;
  
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
    FileStream.ReadBuffer(Buffer, ReadSize);
    
    // 分析缓冲区
    Result := DetectBuffer(Buffer);
    
    // 调整总字节数
    Result.TotalByteCount := FileStream.Size;
  finally
    FileStream.Free;
  end;
end;

class function TUTF8EncodingDetector.IsValidUTF8String(const Str: string): Boolean;
var
  Buffer: TBytes;
  ValidCount, InvalidCount: Int64;
begin
  // 将字符串转换为UTF-8字节数组
  Buffer := TEncoding.UTF8.GetBytes(Str);
  
  // 验证UTF-8序列
  Result := ValidateUTF8Sequence(Buffer, ValidCount, InvalidCount);
end;

class function TUTF8EncodingDetector.GetDetailedReport(const FileName: string): string;
var
  Result: TUTF8DetectionResult;
  SB: TStringBuilder;
begin
  Result := DetectFile(FileName);
  
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('UTF-8编码检测详细报告:');
    SB.AppendLine('文件名: ' + FileName);
    SB.AppendLine('文件大小: ' + IntToStr(Result.TotalByteCount) + ' 字节');
    SB.AppendLine('');
    
    if Result.HasBOM then
      SB.AppendLine('UTF-8 BOM: 存在')
    else
      SB.AppendLine('UTF-8 BOM: 不存在');
      
    SB.AppendLine('');
    SB.AppendLine('检测结果: ' + IfThen(Result.IsUTF8, '是UTF-8编码', '不是UTF-8编码'));
    SB.AppendLine('置信度: ' + FormatFloat('0.00%', Result.Confidence * 100));
    SB.AppendLine('');
    
    if Result.ValidByteCount + Result.InvalidByteCount > 0 then
    begin
      SB.AppendLine('有效UTF-8字节: ' + IntToStr(Result.ValidByteCount) + 
        ' (' + FormatFloat('0.00%', Result.ValidByteCount / (Result.ValidByteCount + Result.InvalidByteCount) * 100) + ')');
      SB.AppendLine('无效UTF-8字节: ' + IntToStr(Result.InvalidByteCount) + 
        ' (' + FormatFloat('0.00%', Result.InvalidByteCount / (Result.ValidByteCount + Result.InvalidByteCount) * 100) + ')');
    end;
    
    SB.AppendLine('');
    if Result.IsUTF8 then
    begin
      if Result.HasBOM then
        SB.AppendLine('建议: 文件已是带BOM的UTF-8编码，无需转换。')
      else
        SB.AppendLine('建议: 文件是UTF-8编码但不带BOM，可考虑添加BOM以确保兼容性。');
    end
    else
    begin
      SB.AppendLine('建议: 文件不是UTF-8编码，可考虑转换为UTF-8编码以提高兼容性。');
    end;
    
    System.Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TUTF8EncodingDetector.AnalyzeTextCharacteristics(const Stream: TStream): Double;
var
  Position: Int64;
  Bytes: TBytes;
  I, ValidSeqCount, InvalidSeqCount, AsciiCount, NonAsciiCount: Integer;
  ByteCount: Integer;
begin
  // 保存当前流位置
  Position := Stream.Position;
  
  try
    // 重置流位置
    Stream.Position := 0;
    
    // 读取采样数据
    SetLength(Bytes, Min(Stream.Size, MAX_TEXT_SAMPLE));
    Stream.ReadBuffer(Bytes[0], Length(Bytes));
    
    // 初始化计数器
    ValidSeqCount := 0;
    InvalidSeqCount := 0;
    AsciiCount := 0;
    NonAsciiCount := 0;
    
    // 分析字节序列
    I := 0;
    while I < Length(Bytes) do
    begin
      // ASCII字符 (0-127)
      if Bytes[I] < $80 then
      begin
        Inc(AsciiCount);
        Inc(I);
        Continue;
      end;
      
      // 非ASCII字符
      Inc(NonAsciiCount);
      
      // 检查是否为有效的UTF-8多字节序列
      if IsValidUTF8Sequence(Bytes, I, ByteCount) then
      begin
        Inc(ValidSeqCount);
        Inc(I, ByteCount);
      end
      else
      begin
        Inc(InvalidSeqCount);
        Inc(I);
      end;
    end;
    
    // 计算UTF-8置信度
    if (ValidSeqCount + InvalidSeqCount) = 0 then
    begin
      // 纯ASCII文本 (也是有效的UTF-8)
      Result := 1.0;
    end
    else
    begin
      // 根据有效序列比例计算置信度
      Result := ValidSeqCount / (ValidSeqCount + InvalidSeqCount);
      
      // 如果非ASCII字符太少（<5%），降低置信度
      if (NonAsciiCount > 0) and (NonAsciiCount < Length(Bytes) * 0.05) then
        Result := Result * 0.9;
    end;
  finally
    // 恢复流位置
    Stream.Position := Position;
  end;
end;

function TUTF8EncodingDetector.GetUTF8Confidence(const Stream: TStream): Double;
begin
  Result := AnalyzeTextCharacteristics(Stream);
end;

function TUTF8EncodingDetector.IsUTF8Encoded(const Stream: TStream): Boolean;
begin
  Result := GetUTF8Confidence(Stream) >= MIN_UTF8_CONFIDENCE;
end;

function TUTF8EncodingDetector.IsUTF8EncodedBytes(const Bytes: TBytes): Boolean;
var
  MemStream: TBytesStream;
begin
  MemStream := TBytesStream.Create(Bytes);
  try
    Result := IsUTF8Encoded(MemStream);
  finally
    MemStream.Free;
  end;
end;

function TUTF8EncodingDetector.IsUTF8EncodedFile(const FileName: string): Boolean;
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    Result := IsUTF8Encoded(FileStream);
  finally
    FileStream.Free;
  end;
end;

function TUTF8EncodingDetector.IsValidUTF8Sequence(const Bytes: TBytes; Start: Integer; var ByteCount: Integer): Boolean;
begin
  Result := False;
  ByteCount := 0;
  
  // 确保起始位置有效
  if (Start < 0) or (Start >= Length(Bytes)) then
    Exit;
  
  // 单字节ASCII (0xxxxxxx)
  if Bytes[Start] < $80 then
  begin
    ByteCount := 1;
    Result := True;
    Exit;
  end;
  
  // 检查无效的UTF-8起始字节 (10xxxxxx)
  if (Bytes[Start] and $C0) = $80 then
    Exit;
  
  // 2字节序列 (110xxxxx 10xxxxxx)
  if (Bytes[Start] and $E0) = $C0 then
  begin
    ByteCount := 2;
    // 检查第二个字节
    if (Start + 1 >= Length(Bytes)) or ((Bytes[Start + 1] and $C0) <> $80) then
      Exit;
    
    // 检查过长编码 (应使用单字节编码的值)
    if (Bytes[Start] and $1E) = 0 then
      Exit;
    
    Result := True;
    Exit;
  end;
  
  // 3字节序列 (1110xxxx 10xxxxxx 10xxxxxx)
  if (Bytes[Start] and $F0) = $E0 then
  begin
    ByteCount := 3;
    // 检查第二、三个字节
    if (Start + 2 >= Length(Bytes)) or 
       ((Bytes[Start + 1] and $C0) <> $80) or 
       ((Bytes[Start + 2] and $C0) <> $80) then
      Exit;
    
    // 检查过长编码
    if (Bytes[Start] = $E0) and ((Bytes[Start + 1] and $20) = 0) then
      Exit;
    
    // 检查代理区域编码 (U+D800-U+DFFF)，这些不应该在UTF-8中出现
    if (Bytes[Start] = $ED) and ((Bytes[Start + 1] and $20) <> 0) then
      Exit;
    
    Result := True;
    Exit;
  end;
  
  // 4字节序列 (11110xxx 10xxxxxx 10xxxxxx 10xxxxxx)
  if (Bytes[Start] and $F8) = $F0 then
  begin
    ByteCount := 4;
    // 检查第二、三、四个字节
    if (Start + 3 >= Length(Bytes)) or 
       ((Bytes[Start + 1] and $C0) <> $80) or 
       ((Bytes[Start + 2] and $C0) <> $80) or 
       ((Bytes[Start + 3] and $C0) <> $80) then
      Exit;
    
    // 检查过长编码
    if (Bytes[Start] = $F0) and ((Bytes[Start + 1] and $30) = 0) then
      Exit;
    
    // 检查超出Unicode范围的值 (> U+10FFFF)
    if (Bytes[Start] > $F4) or ((Bytes[Start] = $F4) and ((Bytes[Start + 1] and $30) <> 0)) then
      Exit;
    
    Result := True;
    Exit;
  end;
  
  // 5+字节序列 (在标准UTF-8中不使用)
  if (Bytes[Start] and $FC) = $F8 then
    Exit;
  
  // 6+字节序列 (在标准UTF-8中不使用)
  if (Bytes[Start] and $FE) = $FC then
    Exit;
end;

end. 