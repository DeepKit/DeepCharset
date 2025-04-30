unit UtilsEncodingDetect2;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.Generics.Collections,
  Winapi.Windows, UtilsEncodingConstants, UtilsEncodingTypes;

type
  /// <summary>
  /// 编码检测结果记录
  /// </summary>
  TEncodingDetectionResult = record
    Encoding: string;
    Confidence: Double;
    HasBOM: Boolean;
    constructor Create(const AEncoding: string; AConfidence: Double; AHasBOM: Boolean);
  end;

  /// <summary>
  /// 编码检测器类型
  /// </summary>
  TEncodingDetectorType = (
    edtBOM,           // BOM检测器
    edtUTF8,          // UTF-8检测器
    edtGB18030,       // GB18030检测器
    edtGBK,           // GBK检测器
    edtBig5,          // Big5检测器
    edtShiftJIS,      // Shift-JIS检测器
    edtStatistic,     // 统计分析检测器
    edtANSI,          // ANSI检测器
    edtFrequency,     // 频率分析检测器
    edtHeuristic      // 启发式检测器
  );

  /// <summary>
  /// 增强型编码检测器
  /// </summary>
  TEncodingDetector2 = class
  private
    FLastErrorMessage: string;
    FEncodingCache: TDictionary<string, TEncodingDetectionResult>;
    FMaxSampleSize: Integer;
    FMinConfidence: Double;
    
    function CheckBOM(const Buffer: TBytes): TEncodingDetectionResult;
    function CheckUTF8(const Buffer: TBytes): TEncodingDetectionResult;
    function CheckGB18030(const Buffer: TBytes): TEncodingDetectionResult;
    function CheckGBK(const Buffer: TBytes): TEncodingDetectionResult;
    function CheckBig5(const Buffer: TBytes): TEncodingDetectionResult;
    function CheckShiftJIS(const Buffer: TBytes): TEncodingDetectionResult;
    function CheckANSI(const Buffer: TBytes): TEncodingDetectionResult;
    function AnalyzeByteFrequency(const Buffer: TBytes): TEncodingDetectionResult;
    function PerformHeuristicCheck(const Buffer: TBytes): TEncodingDetectionResult;
    
    function GetSampleBuffer(const FileName: string; out Buffer: TBytes): Boolean;
    function TakeFileSample(const Stream: TStream; out Buffer: TBytes): Boolean;
    
    function ExecuteDetectionPipeline(const Buffer: TBytes): TEncodingDetectionResult;
    function CombineResults(const Results: TArray<TEncodingDetectionResult>): TEncodingDetectionResult;
  public
    constructor Create;
    destructor Destroy; override;
    
    /// <summary>
    /// 检测文件编码
    /// </summary>
    function DetectFileEncoding(const FileName: string): TEncodingDetectionResult;
    
    /// <summary>
    /// 检测缓冲区编码
    /// </summary>
    function DetectBufferEncoding(const Buffer: TBytes): TEncodingDetectionResult;
    
    /// <summary>
    /// 检测流编码
    /// </summary>
    function DetectStreamEncoding(const Stream: TStream): TEncodingDetectionResult;
    
    /// <summary>
    /// 清除编码缓存
    /// </summary>
    procedure ClearCache;
    
    /// <summary>
    /// 获取最后一次错误信息
    /// </summary>
    function GetLastError: string;
    
    /// <summary>
    /// 设置最大采样大小
    /// </summary>
    procedure SetMaxSampleSize(SampleSize: Integer);
    
    /// <summary>
    /// 设置最小置信度阈值
    /// </summary>
    procedure SetMinConfidence(Confidence: Double);
    
    property LastErrorMessage: string read FLastErrorMessage;
    property MaxSampleSize: Integer read FMaxSampleSize write SetMaxSampleSize;
    property MinConfidence: Double read FMinConfidence write SetMinConfidence;
  end;

implementation

// 构造函数
constructor TEncodingDetectionResult.Create(const AEncoding: string; AConfidence: Double; AHasBOM: Boolean);
begin
  Encoding := AEncoding;
  Confidence := AConfidence;
  HasBOM := AHasBOM;
end;

constructor TEncodingDetector2.Create;
begin
  inherited Create;
  FEncodingCache := TDictionary<string, TEncodingDetectionResult>.Create;
  FMaxSampleSize := 10 * 1024 * 1024; // 默认采样10MB
  FMinConfidence := 0.7; // 默认最小置信度0.7
  FLastErrorMessage := '';
end;

destructor TEncodingDetector2.Destroy;
begin
  FEncodingCache.Free;
  inherited;
end;

function TEncodingDetector2.GetLastError: string;
begin
  Result := FLastErrorMessage;
end;

procedure TEncodingDetector2.SetMaxSampleSize(SampleSize: Integer);
begin
  FMaxSampleSize := Max(1024, SampleSize); // 至少1KB
end;

procedure TEncodingDetector2.SetMinConfidence(Confidence: Double);
begin
  FMinConfidence := EnsureRange(Confidence, 0.1, 0.99);
end;

procedure TEncodingDetector2.ClearCache;
begin
  FEncodingCache.Clear;
end;

// 检测文件编码的主函数
function TEncodingDetector2.DetectFileEncoding(const FileName: string): TEncodingDetectionResult;
var
  Buffer: TBytes;
  CacheKey: string;
begin
  FLastErrorMessage := '';
  
  // 检查文件是否存在
  if not FileExists(FileName) then
  begin
    FLastErrorMessage := '文件不存在: ' + FileName;
    Result := TEncodingDetectionResult.Create(ENCODING_UNKNOWN, 0, False);
    Exit;
  end;
  
  // 检查缓存
  CacheKey := FileName + '|' + IntToStr(FileAge(FileName));
  if FEncodingCache.TryGetValue(CacheKey, Result) then
    Exit;
  
  // 获取文件采样
  if not GetSampleBuffer(FileName, Buffer) then
  begin
    Result := TEncodingDetectionResult.Create(ENCODING_UNKNOWN, 0, False);
    Exit;
  end;
  
  // 进行编码检测
  Result := ExecuteDetectionPipeline(Buffer);
  
  // 缓存结果
  FEncodingCache.AddOrSetValue(CacheKey, Result);
end;

// 检测缓冲区编码的函数
function TEncodingDetector2.DetectBufferEncoding(const Buffer: TBytes): TEncodingDetectionResult;
begin
  FLastErrorMessage := '';
  
  if Length(Buffer) = 0 then
  begin
    FLastErrorMessage := '空缓冲区';
    Result := TEncodingDetectionResult.Create(ENCODING_UNKNOWN, 0, False);
    Exit;
  end;
  
  Result := ExecuteDetectionPipeline(Buffer);
end;

// 检测流编码的函数
function TEncodingDetector2.DetectStreamEncoding(const Stream: TStream): TEncodingDetectionResult;
var
  Buffer: TBytes;
begin
  FLastErrorMessage := '';
  
  if Stream = nil then
  begin
    FLastErrorMessage := '无效的流对象';
    Result := TEncodingDetectionResult.Create(ENCODING_UNKNOWN, 0, False);
    Exit;
  end;
  
  if Stream.Size = 0 then
  begin
    FLastErrorMessage := '空流';
    Result := TEncodingDetectionResult.Create(ENCODING_UNKNOWN, 0, False);
    Exit;
  end;
  
  // 获取流采样
  if not TakeFileSample(Stream, Buffer) then
  begin
    Result := TEncodingDetectionResult.Create(ENCODING_UNKNOWN, 0, False);
    Exit;
  end;
  
  Result := ExecuteDetectionPipeline(Buffer);
end;

// 从文件中获取采样缓冲区
function TEncodingDetector2.GetSampleBuffer(const FileName: string; out Buffer: TBytes): Boolean;
var
  Stream: TFileStream;
begin
  Result := False;
  
  try
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      Result := TakeFileSample(Stream, Buffer);
    finally
      Stream.Free;
    end;
  except
    on E: Exception do
    begin
      FLastErrorMessage := '无法读取文件: ' + E.Message;
      Result := False;
    end;
  end;
end;

// 从流中获取采样缓冲区
function TEncodingDetector2.TakeFileSample(const Stream: TStream; out Buffer: TBytes): Boolean;
var
  OldPosition: Int64;
  SampleSize: Integer;
begin
  Result := False;
  
  try
    OldPosition := Stream.Position;
    try
      Stream.Position := 0;
      
      SampleSize := Min(Stream.Size, FMaxSampleSize);
      SetLength(Buffer, SampleSize);
      
      if SampleSize > 0 then
        Stream.ReadBuffer(Buffer[0], SampleSize);
      
      Result := True;
    finally
      Stream.Position := OldPosition;
    end;
  except
    on E: Exception do
    begin
      FLastErrorMessage := '采样失败: ' + E.Message;
      Result := False;
    end;
  end;
end;

// 执行检测管道
function TEncodingDetector2.ExecuteDetectionPipeline(const Buffer: TBytes): TEncodingDetectionResult;
var
  BOMResult, UTF8Result, GB18030Result, GBKResult, Big5Result, 
  ShiftJISResult, ANSIResult, FrequencyResult, HeuristicResult: TEncodingDetectionResult;
  AllResults: TArray<TEncodingDetectionResult>;
begin
  // 首先检查BOM
  BOMResult := CheckBOM(Buffer);
  if (BOMResult.Encoding <> ENCODING_UNKNOWN) and (BOMResult.Confidence > 0.9) then
  begin
    Result := BOMResult;
    Exit;
  end;
  
  // 接下来检查UTF-8
  UTF8Result := CheckUTF8(Buffer);
  if (UTF8Result.Encoding = ENCODING_UTF8) and (UTF8Result.Confidence > 0.9) then
  begin
    Result := UTF8Result;
    Exit;
  end;
  
  // 然后检查其他编码
  GB18030Result := CheckGB18030(Buffer);
  GBKResult := CheckGBK(Buffer);
  Big5Result := CheckBig5(Buffer);
  ShiftJISResult := CheckShiftJIS(Buffer);
  ANSIResult := CheckANSI(Buffer);
  FrequencyResult := AnalyzeByteFrequency(Buffer);
  HeuristicResult := PerformHeuristicCheck(Buffer);
  
  // 合并所有结果
  SetLength(AllResults, 9);
  AllResults[0] := BOMResult;
  AllResults[1] := UTF8Result;
  AllResults[2] := GB18030Result;
  AllResults[3] := GBKResult;
  AllResults[4] := Big5Result;
  AllResults[5] := ShiftJISResult;
  AllResults[6] := ANSIResult;
  AllResults[7] := FrequencyResult;
  AllResults[8] := HeuristicResult;
  
  Result := CombineResults(AllResults);
end;

// 检查BOM
function TEncodingDetector2.CheckBOM(const Buffer: TBytes): TEncodingDetectionResult;
var
  Length: Integer;
begin
  Length := System.Length(Buffer);
  
  // 检查UTF-8 BOM: EF BB BF
  if (Length >= 3) and (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF) then
    Exit(TEncodingDetectionResult.Create(ENCODING_UTF8_BOM, 1.0, True));
  
  // 检查UTF-16 LE BOM: FF FE
  if (Length >= 2) and (Buffer[0] = $FF) and (Buffer[1] = $FE) then
  begin
    // 检查UTF-32 LE BOM: FF FE 00 00
    if (Length >= 4) and (Buffer[2] = $00) and (Buffer[3] = $00) then
      Exit(TEncodingDetectionResult.Create(ENCODING_UTF32_LE, 1.0, True))
    else
      Exit(TEncodingDetectionResult.Create(ENCODING_UTF16_LE, 1.0, True));
  end;
  
  // 检查UTF-16 BE BOM: FE FF
  if (Length >= 2) and (Buffer[0] = $FE) and (Buffer[1] = $FF) then
    Exit(TEncodingDetectionResult.Create(ENCODING_UTF16_BE, 1.0, True));
  
  // 检查UTF-32 BE BOM: 00 00 FE FF
  if (Length >= 4) and (Buffer[0] = $00) and (Buffer[1] = $00) and 
     (Buffer[2] = $FE) and (Buffer[3] = $FF) then
    Exit(TEncodingDetectionResult.Create(ENCODING_UTF32_BE, 1.0, True));
  
  // 没有找到BOM
  Result := TEncodingDetectionResult.Create(ENCODING_UNKNOWN, 0.0, False);
end;

// 检查UTF-8 (不带BOM)
function TEncodingDetector2.CheckUTF8(const Buffer: TBytes): TEncodingDetectionResult;
var
  I, Length, InvalidSequences, ValidSequences, TotalNonASCII: Integer;
  IsValid: Boolean;
  Confidence: Double;
begin
  Length := System.Length(Buffer);
  
  if Length = 0 then
    Exit(TEncodingDetectionResult.Create(ENCODING_UNKNOWN, 0.0, False));
  
  // 如果是ASCII, 也归类为UTF-8
  if IsASCII(Buffer) then
    Exit(TEncodingDetectionResult.Create(ENCODING_UTF8, 1.0, False));
  
  // 验证UTF-8序列
  IsValid := True;
  InvalidSequences := 0;
  ValidSequences := 0;
  TotalNonASCII := 0;
  I := 0;
  
  while I < Length do
  begin
    if Buffer[I] <= $7F then
    begin
      // ASCII范围
      Inc(I);
    end
    else if (Buffer[I] >= $C2) and (Buffer[I] <= $DF) then
    begin
      // 2字节序列
      TotalNonASCII := TotalNonASCII + 1;
      
      if (I + 1 < Length) and ((Buffer[I + 1] and $C0) = $80) then
      begin
        Inc(ValidSequences);
        Inc(I, 2);
      end
      else
      begin
        Inc(InvalidSequences);
        Inc(I);
      end;
    end
    else if (Buffer[I] >= $E0) and (Buffer[I] <= $EF) then
    begin
      // 3字节序列
      TotalNonASCII := TotalNonASCII + 1;
      
      if (I + 2 < Length) and 
         ((Buffer[I + 1] and $C0) = $80) and
         ((Buffer[I + 2] and $C0) = $80) then
      begin
        // 特殊情况检查
        if (Buffer[I] = $E0) and ((Buffer[I + 1] < $A0) or (Buffer[I + 1] > $BF)) then
          Inc(InvalidSequences)
        else if (Buffer[I] = $ED) and ((Buffer[I + 1] < $80) or (Buffer[I + 1] > $9F)) then
          Inc(InvalidSequences)
        else
          Inc(ValidSequences);
          
        Inc(I, 3);
      end
      else
      begin
        Inc(InvalidSequences);
        Inc(I);
      end;
    end
    else if (Buffer[I] >= $F0) and (Buffer[I] <= $F7) then
    begin
      // 4字节序列
      TotalNonASCII := TotalNonASCII + 1;
      
      if (I + 3 < Length) and 
         ((Buffer[I + 1] and $C0) = $80) and
         ((Buffer[I + 2] and $C0) = $80) and
         ((Buffer[I + 3] and $C0) = $80) then
      begin
        // 特殊情况检查
        if (Buffer[I] = $F0) and ((Buffer[I + 1] < $90) or (Buffer[I + 1] > $BF)) then
          Inc(InvalidSequences)
        else if (Buffer[I] = $F4) and ((Buffer[I + 1] < $80) or (Buffer[I + 1] > $8F)) then
          Inc(InvalidSequences)
        else
          Inc(ValidSequences);
          
        Inc(I, 4);
      end
      else
      begin
        Inc(InvalidSequences);
        Inc(I);
      end;
    end
    else
    begin
      // 无效的UTF-8起始字节
      Inc(InvalidSequences);
      Inc(I);
    end;
  end;
  
  // 计算置信度
  if TotalNonASCII = 0 then
    Confidence := 0.5  // 纯ASCII内容
  else
    Confidence := ValidSequences / (ValidSequences + InvalidSequences);
  
  // UTF-8验证额外检查: 连续多字节序列的比例
  if (TotalNonASCII > 10) and (ValidSequences > InvalidSequences * 5) then
    Confidence := 0.95;
    
  // 进一步提高置信度的检查
  if (TotalNonASCII > 10) and (ValidSequences > 0) and (InvalidSequences = 0) then
    Confidence := 1.0;
  
  if Confidence >= 0.7 then
    Result := TEncodingDetectionResult.Create(ENCODING_UTF8, Confidence, False)
  else
    Result := TEncodingDetectionResult.Create(ENCODING_UNKNOWN, Confidence, False);
end;

// 检查GB18030
function TEncodingDetector2.CheckGB18030(const Buffer: TBytes): TEncodingDetectionResult;
begin
  // GB18030检测逻辑
  // 此处应实现GB18030编码的检测算法
  Result := TEncodingDetectionResult.Create(ENCODING_UNKNOWN, 0.0, False);
end;

// 检查GBK
function TEncodingDetector2.CheckGBK(const Buffer: TBytes): TEncodingDetectionResult;
begin
  // GBK检测逻辑
  // 此处应实现GBK编码的检测算法
  Result := TEncodingDetectionResult.Create(ENCODING_UNKNOWN, 0.0, False);
end;

// 检查Big5
function TEncodingDetector2.CheckBig5(const Buffer: TBytes): TEncodingDetectionResult;
begin
  // Big5检测逻辑
  // 此处应实现Big5编码的检测算法
  Result := TEncodingDetectionResult.Create(ENCODING_UNKNOWN, 0.0, False);
end;

// 检查Shift-JIS
function TEncodingDetector2.CheckShiftJIS(const Buffer: TBytes): TEncodingDetectionResult;
begin
  // Shift-JIS检测逻辑
  // 此处应实现Shift-JIS编码的检测算法
  Result := TEncodingDetectionResult.Create(ENCODING_UNKNOWN, 0.0, False);
end;

// 检查ANSI
function TEncodingDetector2.CheckANSI(const Buffer: TBytes): TEncodingDetectionResult;
var
  Confidence: Double;
  ValidCount, TotalCount: Integer;
  I: Integer;
begin
  ValidCount := 0;
  TotalCount := 0;
  
  // ANSI检测逻辑
  for I := 0 to Length(Buffer) - 1 do
  begin
    if Buffer[I] < $80 then
      // ASCII字符，有效
      Inc(ValidCount)
    else if I < Length(Buffer) - 1 then
      // 检查非ASCII字符
      Inc(TotalCount);
  end;
  
  if TotalCount = 0 then
    Confidence := 0.5  // 纯ASCII，可能是ANSI也可能是UTF-8
  else
    Confidence := 0.7;  // 默认值
  
  Result := TEncodingDetectionResult.Create('ansi', Confidence, False);
end;

// 分析字节频率
function TEncodingDetector2.AnalyzeByteFrequency(const Buffer: TBytes): TEncodingDetectionResult;
begin
  // 字节频率分析逻辑
  // 此处应实现字节频率分析算法
  Result := TEncodingDetectionResult.Create(ENCODING_UNKNOWN, 0.0, False);
end;

// 执行启发式检查
function TEncodingDetector2.PerformHeuristicCheck(const Buffer: TBytes): TEncodingDetectionResult;
begin
  // 启发式检查逻辑
  // 此处应实现综合启发式分析算法
  Result := TEncodingDetectionResult.Create(ENCODING_UNKNOWN, 0.0, False);
end;

// 合并检测结果
function TEncodingDetector2.CombineResults(const Results: TArray<TEncodingDetectionResult>): TEncodingDetectionResult;
var
  BestEncoding: string;
  BestConfidence: Double;
  HasBOM: Boolean;
  I: Integer;
begin
  BestEncoding := ENCODING_UNKNOWN;
  BestConfidence := 0;
  HasBOM := False;
  
  // 找出置信度最高的结果
  for I := 0 to Length(Results) - 1 do
  begin
    if Results[I].Confidence > BestConfidence then
    begin
      BestEncoding := Results[I].Encoding;
      BestConfidence := Results[I].Confidence;
      HasBOM := Results[I].HasBOM;
    end;
  end;
  
  // 如果没有足够置信度的结果，默认使用ANSI
  if BestConfidence < FMinConfidence then
    Result := TEncodingDetectionResult.Create('ansi', 0.5, False)
  else
    Result := TEncodingDetectionResult.Create(BestEncoding, BestConfidence, HasBOM);
end;

// 辅助函数：检查是否为纯ASCII
function IsASCII(const Buffer: TBytes): Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := 0 to Length(Buffer) - 1 do
    if Buffer[I] > $7F then
    begin
      Result := False;
      Exit;
    end;
end;

end. 