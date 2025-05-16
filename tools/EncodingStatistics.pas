unit EncodingStatistics;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  TByteFrequency = record
    ByteValue: Byte;
    Count: Integer;
    Percentage: Double;
  end;
  
  TByteFrequencyArray = array of TByteFrequency;

  TEncodingFeature = record
    Name: string;
    Value: Double;
  end;
  
  TEncodingFeatureArray = array of TEncodingFeature;

  TEncodingStatistics = class
  private
    FByteFrequencies: array[0..255] of Integer;
    FTotalBytes: Int64;
    FEncodingFeatures: TDictionary<string, Double>;

    procedure ResetFrequencies;
    procedure CalculateFrequencies(const Buffer: TBytes);
    procedure AnalyzeNGrams(const Buffer: TBytes);
    procedure AnalyzeCharacterSet(const Buffer: TBytes);
    procedure AnalyzeLanguageFeatures(const Buffer: TBytes);
  
  public
    constructor Create;
    destructor Destroy; override;
    
    // 字节频率统计
    procedure AnalyzeBuffer(const Buffer: TBytes);
    procedure AnalyzeFile(const FileName: string);
    procedure AnalyzeStream(Stream: TStream);
    
    // 获取统计结果
    function GetByteFrequencies: TByteFrequencyArray;
    function GetTopNFrequencies(N: Integer): TByteFrequencyArray;
    function GetEncodingFeatures: TEncodingFeatureArray;
    
    // 编码匹配评分
    function CalculateUTF8Score: Double;
    function CalculateGBKScore: Double;
    function CalculateBig5Score: Double;
    function CalculateASCIIScore: Double;
    
    // 辅助功能
    function ExportStatisticsToCSV: string;
    procedure SaveStatisticsToFile(const FileName: string);
  end;

implementation

{ TEncodingStatistics }

constructor TEncodingStatistics.Create;
begin
  inherited;
  FEncodingFeatures := TDictionary<string, Double>.Create;
  ResetFrequencies;
end;

destructor TEncodingStatistics.Destroy;
begin
  FEncodingFeatures.Free;
  inherited;
end;

procedure TEncodingStatistics.ResetFrequencies;
var
  i: Integer;
begin
  for i := 0 to 255 do
    FByteFrequencies[i] := 0;
    
  FTotalBytes := 0;
  FEncodingFeatures.Clear;
end;

procedure TEncodingStatistics.AnalyzeBuffer(const Buffer: TBytes);
begin
  ResetFrequencies;
  if Length(Buffer) = 0 then
    Exit;
    
  // 计算字节频率
  CalculateFrequencies(Buffer);
  
  // 分析n-gram
  AnalyzeNGrams(Buffer);
  
  // 分析字符集特征
  AnalyzeCharacterSet(Buffer);
  
  // 分析语言特征
  AnalyzeLanguageFeatures(Buffer);
end;

procedure TEncodingStatistics.AnalyzeFile(const FileName: string);
var
  Stream: TFileStream;
begin
  if not FileExists(FileName) then
    raise Exception.CreateFmt('文件不存在: %s', [FileName]);
    
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    AnalyzeStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TEncodingStatistics.AnalyzeStream(Stream: TStream);
var
  Buffer: TBytes;
  BytesRead: Integer;
  ChunkSize: Integer;
begin
  ResetFrequencies;
  
  // 设置分析块大小
  ChunkSize := 8192; // 8KB
  SetLength(Buffer, ChunkSize);
  
  // 保存起始位置
  Stream.Position := 0;
  
  repeat
    BytesRead := Stream.Read(Buffer[0], ChunkSize);
    if BytesRead > 0 then
    begin
      SetLength(Buffer, BytesRead);
      CalculateFrequencies(Buffer);
      Inc(FTotalBytes, BytesRead);
    end;
  until BytesRead < ChunkSize;
  
  // 如果有足够的数据，进行更深层次的分析
  if FTotalBytes > 0 then
  begin
    // 重置流位置
    Stream.Position := 0;
    
    // 读取有限量的数据进行深度分析
    // 限制分析大小，避免内存过度使用
    const MaxAnalysisSize = 1024 * 1024; // 1MB
    SetLength(Buffer, Min(FTotalBytes, MaxAnalysisSize));
    Stream.ReadBuffer(Buffer[0], Length(Buffer));
    
    // 分析n-gram
    AnalyzeNGrams(Buffer);
    
    // 分析字符集特征
    AnalyzeCharacterSet(Buffer);
    
    // 分析语言特征
    AnalyzeLanguageFeatures(Buffer);
  end;
end;

procedure TEncodingStatistics.CalculateFrequencies(const Buffer: TBytes);
var
  i: Integer;
begin
  for i := 0 to Length(Buffer) - 1 do
    Inc(FByteFrequencies[Buffer[i]]);
    
  Inc(FTotalBytes, Length(Buffer));
end;

procedure TEncodingStatistics.AnalyzeNGrams(const Buffer: TBytes);
var
  BigramCounts: array[0..65535] of Integer;
  Bigram: Word;
  i, TotalBigrams: Integer;
  TopBigrams: array[1..5] of record
    Bigram: Word;
    Count: Integer;
  end;
  j, MinIndex: Integer;
  TempBigram, TempCount: Integer;
begin
  // 初始化
  FillChar(BigramCounts, SizeOf(BigramCounts), 0);
  FillChar(TopBigrams, SizeOf(TopBigrams), 0);
  
  // 计算双字节频率
  TotalBigrams := 0;
  for i := 0 to Length(Buffer) - 2 do
  begin
    Bigram := Buffer[i] shl 8 + Buffer[i + 1];
    Inc(BigramCounts[Bigram]);
    Inc(TotalBigrams);
  end;
  
  // 找出频率最高的5个双字节
  for i := 0 to 65535 do
  begin
    if BigramCounts[i] > 0 then
    begin
      // 寻找最小值的位置
      MinIndex := 1;
      for j := 2 to 5 do
        if TopBigrams[j].Count < TopBigrams[MinIndex].Count then
          MinIndex := j;
          
      // 如果当前bigram比最小值大，替换它
      if BigramCounts[i] > TopBigrams[MinIndex].Count then
      begin
        TopBigrams[MinIndex].Bigram := i;
        TopBigrams[MinIndex].Count := BigramCounts[i];
      end;
    end;
  end;
  
  // 冒泡排序，按计数降序排列
  for i := 1 to 4 do
    for j := 1 to 5 - i do
      if TopBigrams[j].Count < TopBigrams[j + 1].Count then
      begin
        TempBigram := TopBigrams[j].Bigram;
        TempCount := TopBigrams[j].Count;
        TopBigrams[j].Bigram := TopBigrams[j + 1].Bigram;
        TopBigrams[j].Count := TopBigrams[j + 1].Count;
        TopBigrams[j + 1].Bigram := TempBigram;
        TopBigrams[j + 1].Count := TempCount;
      end;
      
  // 保存特征数据
  for i := 1 to 5 do
  begin
    if TotalBigrams > 0 then
      FEncodingFeatures.AddOrSetValue(Format('TopBigram%d', [i]), 
        TopBigrams[i].Count / TotalBigrams);
    FEncodingFeatures.AddOrSetValue(Format('TopBigramValue%d', [i]), 
      TopBigrams[i].Bigram);
  end;
end;

procedure TEncodingStatistics.AnalyzeCharacterSet(const Buffer: TBytes);
var
  i: Integer;
  ASCIICount, HighBitCount: Integer;
  ValidUTF8Sequences, InvalidUTF8Sequences: Integer;
  ValidGBKSequences, InvalidGBKSequences: Integer;
  ValidBig5Sequences, InvalidBig5Sequences: Integer;
begin
  // 初始化计数器
  ASCIICount := 0;
  HighBitCount := 0;
  ValidUTF8Sequences := 0;
  InvalidUTF8Sequences := 0;
  ValidGBKSequences := 0;
  InvalidGBKSequences := 0;
  ValidBig5Sequences := 0;
  InvalidBig5Sequences := 0;

  // 计算ASCII和高位字节的数量
  for i := 0 to Length(Buffer) - 1 do
  begin
    if Buffer[i] <= $7F then
      Inc(ASCIICount)
    else
      Inc(HighBitCount);
  end;

  // 分析UTF-8序列
  i := 0;
  while i < Length(Buffer) do
  begin
    if Buffer[i] <= $7F then
    begin
      // ASCII范围，单字节
      Inc(i);
    end
    else if (Buffer[i] >= $C2) and (Buffer[i] <= $DF) then
    begin
      // 2字节序列：110xxxxx 10xxxxxx
      if (i + 1 < Length(Buffer)) and ((Buffer[i + 1] and $C0) = $80) then
      begin
        Inc(ValidUTF8Sequences);
        Inc(i, 2);
      end
      else
      begin
        Inc(InvalidUTF8Sequences);
        Inc(i);
      end;
    end
    else if (Buffer[i] >= $E0) and (Buffer[i] <= $EF) then
    begin
      // 3字节序列：1110xxxx 10xxxxxx 10xxxxxx
      if (i + 2 < Length(Buffer)) and 
         ((Buffer[i + 1] and $C0) = $80) and
         ((Buffer[i + 2] and $C0) = $80) then
      begin
        Inc(ValidUTF8Sequences);
        Inc(i, 3);
      end
      else
      begin
        Inc(InvalidUTF8Sequences);
        Inc(i);
      end;
    end
    else if (Buffer[i] >= $F0) and (Buffer[i] <= $F7) then
    begin
      // 4字节序列：11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
      if (i + 3 < Length(Buffer)) and 
         ((Buffer[i + 1] and $C0) = $80) and
         ((Buffer[i + 2] and $C0) = $80) and
         ((Buffer[i + 3] and $C0) = $80) then
      begin
        Inc(ValidUTF8Sequences);
        Inc(i, 4);
      end
      else
      begin
        Inc(InvalidUTF8Sequences);
        Inc(i);
      end;
    end
    else
    begin
      // 无效的UTF-8起始字节
      Inc(InvalidUTF8Sequences);
      Inc(i);
    end;
  end;

  // 分析GBK序列 (简化版)
  i := 0;
  while i < Length(Buffer) - 1 do
  begin
    if (Buffer[i] >= $81) and (Buffer[i] <= $FE) and
       (Buffer[i + 1] >= $40) and (Buffer[i + 1] <= $FE) and
       (Buffer[i + 1] <> $7F) then
    begin
      Inc(ValidGBKSequences);
      Inc(i, 2);
    end
    else if Buffer[i] > $7F then
    begin
      Inc(InvalidGBKSequences);
      Inc(i);
    end
    else
      Inc(i);
  end;

  // 分析Big5序列 (简化版)
  i := 0;
  while i < Length(Buffer) - 1 do
  begin
    if ((Buffer[i] >= $A1) and (Buffer[i] <= $F9)) and
       (((Buffer[i + 1] >= $40) and (Buffer[i + 1] <= $7E)) or
        ((Buffer[i + 1] >= $A1) and (Buffer[i + 1] <= $FE))) then
    begin
      Inc(ValidBig5Sequences);
      Inc(i, 2);
    end
    else if Buffer[i] > $7F then
    begin
      Inc(InvalidBig5Sequences);
      Inc(i);
    end
    else
      Inc(i);
  end;

  // 保存特征数据
  if FTotalBytes > 0 then
  begin
    FEncodingFeatures.AddOrSetValue('ASCIIRatio', ASCIICount / FTotalBytes);
    FEncodingFeatures.AddOrSetValue('HighBitRatio', HighBitCount / FTotalBytes);
  end;

  if ValidUTF8Sequences + InvalidUTF8Sequences > 0 then
    FEncodingFeatures.AddOrSetValue('UTF8ValidRatio', 
      ValidUTF8Sequences / (ValidUTF8Sequences + InvalidUTF8Sequences));

  if ValidGBKSequences + InvalidGBKSequences > 0 then
    FEncodingFeatures.AddOrSetValue('GBKValidRatio', 
      ValidGBKSequences / (ValidGBKSequences + InvalidGBKSequences));

  if ValidBig5Sequences + InvalidBig5Sequences > 0 then
    FEncodingFeatures.AddOrSetValue('Big5ValidRatio', 
      ValidBig5Sequences / (ValidBig5Sequences + InvalidBig5Sequences));
end;

procedure TEncodingStatistics.AnalyzeLanguageFeatures(const Buffer: TBytes);
var
  ChineseCharCount, JapaneseCharCount, KoreanCharCount: Integer;
  CyrillicCharCount, LatinCharCount: Integer;
  SpecialCharCount: Integer;
  CharCount: Integer;
  i: Integer;
begin
  // 初始化计数器
  ChineseCharCount := 0;
  JapaneseCharCount := 0;
  KoreanCharCount := 0;
  CyrillicCharCount := 0;
  LatinCharCount := 0;
  SpecialCharCount := 0;
  CharCount := 0;

  // 基于UTF-8编码的简单语言检测
  // 注意：这是一个简化的实现，真实场景需要更复杂的逻辑
  i := 0;
  while i < Length(Buffer) do
  begin
    if Buffer[i] <= $7F then
    begin
      // ASCII范围
      if (Buffer[i] >= $41) and (Buffer[i] <= $5A) or
         (Buffer[i] >= $61) and (Buffer[i] <= $7A) then
        Inc(LatinCharCount);
        
      Inc(i);
      Inc(CharCount);
    end
    else if (i + 2 < Length(Buffer)) and 
            (Buffer[i] and $F0 = $E0) and 
            ((Buffer[i + 1] and $C0) = $80) and 
            ((Buffer[i + 2] and $C0) = $80) then
    begin
      // 可能是中文、日文、韩文的3字节UTF-8序列
      if (Buffer[i] = $E4) and (Buffer[i + 1] >= $B8) and (Buffer[i + 1] <= $BF) or
         (Buffer[i] = $E5) and (Buffer[i + 1] >= $80) and (Buffer[i + 1] <= $BF) or
         (Buffer[i] = $E6) and (Buffer[i + 1] >= $80) and (Buffer[i + 1] <= $BF) or
         (Buffer[i] = $E7) and (Buffer[i + 1] >= $80) and (Buffer[i + 1] <= $BF) or
         (Buffer[i] = $E8) and (Buffer[i + 1] >= $80) and (Buffer[i + 1] <= $BF) or
         (Buffer[i] = $E9) and (Buffer[i + 1] >= $80) and (Buffer[i + 1] <= $BE) then
        Inc(ChineseCharCount)
      else if (Buffer[i] = $E3) and 
              ((Buffer[i + 1] >= $81) and (Buffer[i + 1] <= $83)) then
        Inc(JapaneseCharCount)
      else if (Buffer[i] = $EA) and 
              ((Buffer[i + 1] >= $B0) and (Buffer[i + 1] <= $BF)) or
              (Buffer[i] = $EB) and 
              ((Buffer[i + 1] >= $80) and (Buffer[i + 1] <= $BF)) then
        Inc(KoreanCharCount)
      else if (Buffer[i] = $D0) or (Buffer[i] = $D1) then
        Inc(CyrillicCharCount);
        
      Inc(i, 3);
      Inc(CharCount);
    end
    else if (i + 1 < Length(Buffer)) and 
            ((Buffer[i] and $E0) = $C0) and 
            ((Buffer[i + 1] and $C0) = $80) then
    begin
      // 2字节UTF-8序列，可能是Latin扩展或Cyrillic
      if (Buffer[i] = $C3) or (Buffer[i] = $C4) or (Buffer[i] = $C5) then
        Inc(LatinCharCount)
      else if (Buffer[i] = $D0) or (Buffer[i] = $D1) then
        Inc(CyrillicCharCount);
        
      Inc(i, 2);
      Inc(CharCount);
    end
    else if (i + 3 < Length(Buffer)) and 
            ((Buffer[i] and $F8) = $F0) and 
            ((Buffer[i + 1] and $C0) = $80) and 
            ((Buffer[i + 2] and $C0) = $80) and 
            ((Buffer[i + 3] and $C0) = $80) then
    begin
      // 4字节UTF-8序列，可能是表情符号或罕见字符
      Inc(SpecialCharCount);
      Inc(i, 4);
      Inc(CharCount);
    end
    else
    {
      // 无法识别的序列
      Inc(i);
    }
    begin
      // 无法识别的序列，尝试前进一个字节
      Inc(i);
      // 不计入字符计数
    end;
  end;

  // 保存语言特征数据
  if CharCount > 0 then
  begin
    FEncodingFeatures.AddOrSetValue('ChineseRatio', ChineseCharCount / CharCount);
    FEncodingFeatures.AddOrSetValue('JapaneseRatio', JapaneseCharCount / CharCount);
    FEncodingFeatures.AddOrSetValue('KoreanRatio', KoreanCharCount / CharCount);
    FEncodingFeatures.AddOrSetValue('CyrillicRatio', CyrillicCharCount / CharCount);
    FEncodingFeatures.AddOrSetValue('LatinRatio', LatinCharCount / CharCount);
    FEncodingFeatures.AddOrSetValue('SpecialCharRatio', SpecialCharCount / CharCount);
  end;
end;

function TEncodingStatistics.GetByteFrequencies: TByteFrequencyArray;
var
  i, Index: Integer;
begin
  SetLength(Result, 256);
  
  // 填充频率数组
  for i := 0 to 255 do
  begin
    Result[i].ByteValue := i;
    Result[i].Count := FByteFrequencies[i];
    if FTotalBytes > 0 then
      Result[i].Percentage := FByteFrequencies[i] / FTotalBytes * 100
    else
      Result[i].Percentage := 0;
  end;
  
  // 按频率降序排序
  for i := 0 to 254 do
    for Index := 0 to 254 - i do
      if Result[Index].Count < Result[Index + 1].Count then
      begin
        // 交换
        var Temp := Result[Index];
        Result[Index] := Result[Index + 1];
        Result[Index + 1] := Temp;
      end;
end;

function TEncodingStatistics.GetTopNFrequencies(N: Integer): TByteFrequencyArray;
var
  AllFrequencies: TByteFrequencyArray;
begin
  // 获取所有频率并按降序排列
  AllFrequencies := GetByteFrequencies;
  
  // 返回前N个
  SetLength(Result, Min(N, 256));
  Move(AllFrequencies[0], Result[0], SizeOf(TByteFrequency) * Length(Result));
end;

function TEncodingStatistics.GetEncodingFeatures: TEncodingFeatureArray;
var
  Keys: TArray<string>;
  i: Integer;
begin
  Keys := FEncodingFeatures.Keys.ToArray;
  SetLength(Result, Length(Keys));
  
  for i := 0 to High(Keys) do
  begin
    Result[i].Name := Keys[i];
    Result[i].Value := FEncodingFeatures[Keys[i]];
  end;
end;

function TEncodingStatistics.CalculateUTF8Score: Double;
var
  UTF8ValidRatio: Double;
  ASCIIRatio: Double;
  HighBitRatio: Double;
  Score: Double;
begin
  // 默认得分
  Score := 0;
  
  // 获取UTF-8相关特征
  if not FEncodingFeatures.TryGetValue('UTF8ValidRatio', UTF8ValidRatio) then
    UTF8ValidRatio := 0;
    
  if not FEncodingFeatures.TryGetValue('ASCIIRatio', ASCIIRatio) then
    ASCIIRatio := 0;
    
  if not FEncodingFeatures.TryGetValue('HighBitRatio', HighBitRatio) then
    HighBitRatio := 0;
    
  // 计算得分：
  // 1. 如果文件全是ASCII（高位字节比例为0），则可能是UTF-8
  if HighBitRatio = 0 then
    Score := 0.85  // 不是100%，因为ASCII也可能是其他编码
  // 2. 如果有高位字节，需要检查UTF-8序列有效性
  else if UTF8ValidRatio > 0 then
  begin
    // UTF-8有效序列比例越高，得分越高
    Score := UTF8ValidRatio;
    
    // 根据ASCII比例微调
    if ASCIIRatio > 0.5 then
      Score := Score * 0.9 + 0.1;  // 如果大多是ASCII，适当提高得分
  end;
  
  Result := Score;
end;

function TEncodingStatistics.CalculateGBKScore: Double;
var
  GBKValidRatio: Double;
  ASCIIRatio: Double;
  ChineseRatio: Double;
  Score: Double;
begin
  // 默认得分
  Score := 0;
  
  // 获取GBK相关特征
  if not FEncodingFeatures.TryGetValue('GBKValidRatio', GBKValidRatio) then
    GBKValidRatio := 0;
    
  if not FEncodingFeatures.TryGetValue('ASCIIRatio', ASCIIRatio) then
    ASCIIRatio := 0;
    
  if not FEncodingFeatures.TryGetValue('ChineseRatio', ChineseRatio) then
    ChineseRatio := 0;
    
  // 计算得分：
  // 1. 如果文件全是ASCII，不太可能是专门的GBK
  if ASCIIRatio >= 0.98 then
    Score := 0.2
  // 2. 如果有效GBK序列比例高，得分高
  else if GBKValidRatio > 0 then
  begin
    Score := GBKValidRatio;
    
    // 如果检测到中文字符比例高，提高得分
    if ChineseRatio > 0.3 then
      Score := Score * 0.7 + 0.3;
      
    // 如果ASCII比例过高，降低得分
    if ASCIIRatio > 0.7 then
      Score := Score * 0.7;
  end;
  
  Result := Score;
end;

function TEncodingStatistics.CalculateBig5Score: Double;
var
  Big5ValidRatio: Double;
  ASCIIRatio: Double;
  ChineseRatio: Double;
  Score: Double;
begin
  // 默认得分
  Score := 0;
  
  // 获取Big5相关特征
  if not FEncodingFeatures.TryGetValue('Big5ValidRatio', Big5ValidRatio) then
    Big5ValidRatio := 0;
    
  if not FEncodingFeatures.TryGetValue('ASCIIRatio', ASCIIRatio) then
    ASCIIRatio := 0;
    
  if not FEncodingFeatures.TryGetValue('ChineseRatio', ChineseRatio) then
    ChineseRatio := 0;
    
  // 计算得分：
  // 1. 如果文件全是ASCII，不太可能是专门的Big5
  if ASCIIRatio >= 0.98 then
    Score := 0.2
  // 2. 如果有效Big5序列比例高，得分高
  else if Big5ValidRatio > 0 then
  begin
    Score := Big5ValidRatio;
    
    // 如果检测到中文字符比例高，提高得分
    if ChineseRatio > 0.3 then
      Score := Score * 0.7 + 0.3;
      
    // 如果ASCII比例过高，降低得分
    if ASCIIRatio > 0.7 then
      Score := Score * 0.7;
  end;
  
  Result := Score;
end;

function TEncodingStatistics.CalculateASCIIScore: Double;
var
  ASCIIRatio: Double;
begin
  // 获取ASCII比例
  if not FEncodingFeatures.TryGetValue('ASCIIRatio', ASCIIRatio) then
    ASCIIRatio := 0;
    
  // ASCII得分就是ASCII字符的比例
  Result := ASCIIRatio;
end;

function TEncodingStatistics.ExportStatisticsToCSV: string;
var
  SL: TStringList;
  ByteFreqs: TByteFrequencyArray;
  Features: TEncodingFeatureArray;
  i: Integer;
begin
  SL := TStringList.Create;
  try
    // 添加头部
    SL.Add('统计类型,值,说明');
    
    // 添加总字节数
    SL.Add(Format('TotalBytes,%d,总处理字节数', [FTotalBytes]));
    
    // 添加字节频率 (前10名)
    ByteFreqs := GetTopNFrequencies(10);
    for i := 0 to High(ByteFreqs) do
    begin
      SL.Add(Format('ByteFreq,0x%2.2X,%d,%.2f%%,字节0x%2.2X出现%d次，占比%.2f%%', 
        [ByteFreqs[i].ByteValue, ByteFreqs[i].Count, ByteFreqs[i].Percentage,
         ByteFreqs[i].ByteValue, ByteFreqs[i].Count, ByteFreqs[i].Percentage]));
    end;
    
    // 添加特征
    Features := GetEncodingFeatures;
    for i := 0 to High(Features) do
    begin
      SL.Add(Format('Feature,%s,%.6f,%s的值为%.6f', 
        [Features[i].Name, Features[i].Value, Features[i].Name, Features[i].Value]));
    end;
    
    // 添加编码得分
    SL.Add(Format('Score,UTF8,%.6f,UTF-8得分为%.6f', [CalculateUTF8Score, CalculateUTF8Score]));
    SL.Add(Format('Score,GBK,%.6f,GBK得分为%.6f', [CalculateGBKScore, CalculateGBKScore]));
    SL.Add(Format('Score,Big5,%.6f,Big5得分为%.6f', [CalculateBig5Score, CalculateBig5Score]));
    SL.Add(Format('Score,ASCII,%.6f,ASCII得分为%.6f', [CalculateASCIIScore, CalculateASCIIScore]));
    
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

procedure TEncodingStatistics.SaveStatisticsToFile(const FileName: string);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Text := ExportStatisticsToCSV;
    SL.SaveToFile(FileName);
  finally
    SL.Free;
  end;
end;

end. 