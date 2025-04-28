unit UtilsEncodingDetect2;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.IOUtils,
  JclBOM, JclStrings, JclFileUtils, JclStreams, Winapi.Windows;

type
  // 编码检测结果记录
  TEncodingDetectResult = record
    EncodingName: string;    // 编码名称
    Confidence: Double;      // 置信度 (0.0-1.0)
    HasBOM: Boolean;         // 是否有BOM
    LanguageHint: string;    // 语言提示
  end;

  // 增强版编码检测结果记录
  TEncodingDetectionResult = record
    DetectedEncoding: TEncoding; // 检测到的编码
    EncodingName: string;        // 编码名称
    Confidence: Double;          // 置信度 (0.0-1.0)
    HasBOM: Boolean;             // 是否有BOM
    Description: string;         // 描述
    LanguageHint: string;        // 语言提示
    DetectionMethod: string;     // 检测方法
  end;

  // 编码检测算法
  TEncodingDetectionAlgorithm = (
    edaBOM,           // BOM检测
    edaStatistical,   // 统计分析
    edaPattern,       // 模式匹配
    edaHeuristic,     // 启发式方法
    edaCombined       // 组合方法
  );

  // 编码检测选项
  TEncodingDetectionOptions = record
    MaxScanSize: Integer;             // 最大扫描大小
    MinConfidence: Double;            // 最小置信度
    PreferredEncoding: TEncoding;     // 首选编码
    DefaultEncoding: TEncoding;       // 默认编码
    AlgorithmPriority: set of TEncodingDetectionAlgorithm; // 算法优先级
    EnableChineseDetection: Boolean;  // 启用中文编码检测
    EnableJapaneseDetection: Boolean; // 启用日文编码检测
    EnableKoreanDetection: Boolean;   // 启用韩文编码检测
  end;

  // 增强版编码检测器类
  TEncodingDetector2 = class
  private
    FOptions: TEncodingDetectionOptions;
    FLastError: string;
    
    // 内部检测方法
    function DetectByBOM(const Buffer: TBytes): TEncodingDetectionResult;
    function DetectByStatisticalAnalysis(const Buffer: TBytes): TEncodingDetectionResult;
    function DetectByPattern(const Buffer: TBytes): TEncodingDetectionResult;
    function DetectChineseEncoding(const Buffer: TBytes): TEncodingDetectionResult;
    function DetectJapaneseEncoding(const Buffer: TBytes): TEncodingDetectionResult;
    function DetectKoreanEncoding(const Buffer: TBytes): TEncodingDetectionResult;
    function DetectMiddleEasternEncoding(const Buffer: TBytes): TEncodingDetectionResult;
    function DetectSouthAsianEncoding(const Buffer: TBytes): TEncodingDetectionResult;
    function DetectEuropeanEncoding(const Buffer: TBytes): TEncodingDetectionResult;
    function DetectIBMEncoding(const Buffer: TBytes): TEncodingDetectionResult;
    function CombineResults(const Results: array of TEncodingDetectionResult): TEncodingDetectionResult;
    
    // 中文编码分析
    function AnalyzeChineseBytes(const Buffer: TBytes; 
                                out GB2312Count, GBKCount, GB18030Count: Integer): Double;
    function IsValidGB18030Sequence(const Buffer: TBytes; Pos: Integer; out SequenceLen: Integer): Boolean;
    function IsValidGBKSequence(const Buffer: TBytes; Pos: Integer; out SequenceLen: Integer): Boolean;
    function IsValidGB2312Sequence(const Buffer: TBytes; Pos: Integer; out SequenceLen: Integer): Boolean;
    
    // 日文编码分析
    function AnalyzeJapaneseBytes(const Buffer: TBytes;
                                 out ShiftJISCount, EUCJPCount: Integer): Double;
    function IsValidShiftJISSequence(const Buffer: TBytes; Pos: Integer; out SequenceLen: Integer): Boolean;
    function IsValidEUCJPSequence(const Buffer: TBytes; Pos: Integer; out SequenceLen: Integer): Boolean;
    
    // 韩文编码分析
    function AnalyzeKoreanBytes(const Buffer: TBytes;
                               out EUCKRCount: Integer): Double;
    function IsValidEUCKRSequence(const Buffer: TBytes; Pos: Integer; out SequenceLen: Integer): Boolean;
    
    // 在DetectByPattern方法中添加对新增编码的检测支持
    function DetectByPattern(const Buffer: TBytes): TEncodingDetectionResult;
    
    // 在类声明中添加对Windows代码页编码的检测方法
    function DetectWindowsCodePage(const Buffer: TBytes): TEncodingDetectionResult;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 属性
    property Options: TEncodingDetectionOptions read FOptions write FOptions;
    property LastError: string read FLastError;
    
    // 编码检测方法
    function DetectFileEncoding(const FileName: string): TEncodingDetectionResult;
    function DetectStreamEncoding(Stream: TStream): TEncodingDetectionResult;
    function DetectBytesEncoding(const Bytes: TBytes): TEncodingDetectionResult;
    
    // 编码工具方法
    class function GetSupportedEncodings: TArray<TEncoding>;
    class function GetSupportedEncodingNames: TArray<string>;
    class function GetEncodingByName(const EncodingName: string): TEncoding;
    class function GetEncodingFriendlyName(Encoding: TEncoding): string;
  end;

implementation

{ TEncodingDetector2 }

constructor TEncodingDetector2.Create;
begin
  inherited Create;
  
  // 设置默认选项
  FOptions.MaxScanSize := 64 * 1024; // 默认扫描64KB
  FOptions.MinConfidence := 0.6;     // 最小置信度60%
  FOptions.PreferredEncoding := nil;
  FOptions.DefaultEncoding := TEncoding.ANSI;
  FOptions.AlgorithmPriority := [edaBOM, edaStatistical, edaPattern, edaCombined];
  FOptions.EnableChineseDetection := True;  // 启用中文编码检测
  FOptions.EnableJapaneseDetection := True; // 启用日文编码检测
  FOptions.EnableKoreanDetection := True;   // 启用韩文编码检测
end;

destructor TEncodingDetector2.Destroy;
begin
  inherited;
end;

function TEncodingDetector2.DetectFileEncoding(const FileName: string): TEncodingDetectionResult;
var
  Stream: TFileStream;
  Buffer: TBytes;
begin
  // 初始化结果
  Result.DetectedEncoding := nil;
  Result.EncodingName := 'Unknown';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.Description := '';
  Result.LanguageHint := '';
  Result.DetectionMethod := '';
  
  if not FileExists(FileName) then
  begin
    Result.Description := '文件不存在';
    Exit;
  end;
  
  try
    // 打开文件
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      // 读取部分文件内容进行检测
      SetLength(Buffer, Min(Stream.Size, FOptions.MaxScanSize));
      if Length(Buffer) > 0 then
        Stream.ReadBuffer(Buffer[0], Length(Buffer));
      
      // 使用字节检测方法
      Result := DetectBytesEncoding(Buffer);
      
      // 如果没有检测到语言提示，根据文件扩展名推测
      if (Result.LanguageHint = '') then
      begin
        var Ext := LowerCase(ExtractFileExt(FileName));
        
        if (Ext = '.c') or (Ext = '.cpp') or (Ext = '.h') or (Ext = '.hpp') or
           (Ext = '.cs') or (Ext = '.java') or (Ext = '.js') or (Ext = '.ts') or
           (Ext = '.php') or (Ext = '.py') or (Ext = '.rb') then
          Result.LanguageHint := '程序代码'
        else if (Ext = '.html') or (Ext = '.htm') or (Ext = '.xml') or 
                (Ext = '.css') or (Ext = '.svg') then
          Result.LanguageHint := 'Web标记'
        else if (Ext = '.txt') or (Ext = '.md') or (Ext = '.log') then
          Result.LanguageHint := '文本文件'
        else if (Ext = '.json') or (Ext = '.yaml') or (Ext = '.yml') or 
                (Ext = '.ini') or (Ext = '.toml') then
          Result.LanguageHint := '配置文件';
      end;
    finally
      Stream.Free;
    end;
  except
    on E: Exception do
    begin
      FLastError := E.Message;
      Result.DetectedEncoding := nil;
      Result.EncodingName := 'Error';
      Result.Confidence := 0;
      Result.HasBOM := False;
      Result.Description := 'Error: ' + E.Message;
    end;
  end;
end;

function TEncodingDetector2.DetectStreamEncoding(Stream: TStream): TEncodingDetectionResult;
var
  SavedPosition: Int64;
  Buffer: TBytes;
  ReadSize: Integer;
begin
  // 保存当前流位置
  SavedPosition := Stream.Position;
  Stream.Position := 0;
  
  try
    // 读取数据进行检测
    SetLength(Buffer, Min(Stream.Size, FOptions.MaxScanSize));
    if Length(Buffer) > 0 then
      ReadSize := Stream.Read(Buffer[0], Length(Buffer))
    else
      ReadSize := 0;
      
    SetLength(Buffer, ReadSize);
    
    // 使用内部检测函数处理
    Result := DetectBytesEncoding(Buffer);
  finally
    // 恢复流位置
    Stream.Position := SavedPosition;
  end;
end;

function TEncodingDetector2.DetectByBOM(const Buffer: TBytes): TEncodingDetectionResult;
var
  PreambleSize: Integer;
  DetectedEncoding: TEncoding;
begin
  Result.DetectedEncoding := nil;
  Result.EncodingName := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.Description := '';
  Result.LanguageHint := '';
  Result.DetectionMethod := 'BOM';
  
  if Length(Buffer) < 2 then
    Exit;
  
  // 使用TEncoding.GetBufferEncoding进行BOM检测
  DetectedEncoding := TEncoding.Default;
  PreambleSize := TEncoding.GetBufferEncoding(Buffer, DetectedEncoding);
  Result.DetectedEncoding := DetectedEncoding;
  Result.HasBOM := PreambleSize > 0;
  
  if Result.DetectedEncoding = TEncoding.UTF8 then
  begin
    Result.EncodingName := 'UTF-8';
    Result.Confidence := 1.0;
    Result.Description := 'UTF-8 with BOM detected';
  end
  else if Result.DetectedEncoding = TEncoding.Unicode then
  begin
    // 检测是否为UTF-32LE (FF FE 00 00)
    if (Length(Buffer) >= 4) and (Buffer[0] = $FF) and (Buffer[1] = $FE) and 
       (Buffer[2] = 0) and (Buffer[3] = 0) then
    begin
      Result.EncodingName := 'UTF-32LE';
      Result.Description := 'UTF-32LE with BOM detected';
    end
    else
    begin
      Result.EncodingName := 'UTF-16LE';
      Result.Description := 'UTF-16LE with BOM detected';
    end;
    Result.Confidence := 1.0;
  end
  else if Result.DetectedEncoding = TEncoding.BigEndianUnicode then
  begin
    // 检测是否为UTF-32BE (00 00 FE FF)
    if (Length(Buffer) >= 4) and (Buffer[0] = 0) and (Buffer[1] = 0) and 
       (Buffer[2] = $FE) and (Buffer[3] = $FF) then
    begin
      Result.EncodingName := 'UTF-32BE';
      Result.Description := 'UTF-32BE with BOM detected';
    end
    else
    begin
      Result.EncodingName := 'UTF-16BE';
      Result.Description := 'UTF-16BE with BOM detected';
    end;
    Result.Confidence := 1.0;
  end
  else
  begin
    // 没有检测到BOM
    Result.DetectedEncoding := nil;
  end;
end;

function TEncodingDetector2.DetectByStatisticalAnalysis(const Buffer: TBytes): TEncodingDetectionResult;
var
  i: Integer;
  ZeroBytes, NonZeroBytes: Integer;
  HasHighBit: Integer;
  Utf8Sequences, ValidUtf8Sequences: Integer;
  Utf16EvenBytes, Utf16OddBytes: Integer;
  Confidence: Double;
begin
  Result.DetectedEncoding := nil;
  Result.EncodingName := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.Description := '';
  Result.LanguageHint := '';
  Result.DetectionMethod := 'Statistical';
  
  if Length(Buffer) = 0 then
    Exit;
  
  // 初始化统计计数器
  ZeroBytes := 0;
  NonZeroBytes := 0;
  HasHighBit := 0;
  Utf8Sequences := 0;
  ValidUtf8Sequences := 0;
  Utf16EvenBytes := 0;
  Utf16OddBytes := 0;
  
  // 统计各类字节特征
  for i := 0 to Length(Buffer) - 1 do
  begin
    if Buffer[i] = 0 then
    begin
      Inc(ZeroBytes);
      
      // 奇偶位置零字节计数（用于UTF-16检测）
      if i mod 2 = 0 then
        Inc(Utf16EvenBytes)
      else
        Inc(Utf16OddBytes);
    end
    else
    begin
      Inc(NonZeroBytes);
      
      // 统计高位字节（大于127的字节）
      if Buffer[i] >= $80 then
      begin
        Inc(HasHighBit);
        
        // 检测UTF-8多字节序列
        if (Buffer[i] and $E0) = $C0 then // 2字节序列开始
        begin
          Inc(Utf8Sequences);
          if (i + 1 < Length(Buffer)) and ((Buffer[i + 1] and $C0) = $80) then
            Inc(ValidUtf8Sequences);
        end
        else if (Buffer[i] and $F0) = $E0 then // 3字节序列开始
        begin
          Inc(Utf8Sequences);
          if (i + 2 < Length(Buffer)) and 
             ((Buffer[i + 1] and $C0) = $80) and
             ((Buffer[i + 2] and $C0) = $80) then
            Inc(ValidUtf8Sequences);
        end
        else if (Buffer[i] and $F8) = $F0 then // 4字节序列开始
        begin
          Inc(Utf8Sequences);
          if (i + 3 < Length(Buffer)) and
             ((Buffer[i + 1] and $C0) = $80) and
             ((Buffer[i + 2] and $C0) = $80) and
             ((Buffer[i + 3] and $C0) = $80) then
            Inc(ValidUtf8Sequences);
        end;
      end;
    end;
  end;
  
  // 检测纯ASCII
  if (HasHighBit = 0) and (NonZeroBytes > 0) then
  begin
    Result.DetectedEncoding := TEncoding.ASCII;
    Result.EncodingName := 'ASCII';
    Result.Confidence := 1.0;
    Result.Description := 'ASCII detected (100%)';
    Exit;
  end;
  
  // 检测UTF-8
  if (HasHighBit > 0) and (Utf8Sequences > 0) then
  begin
    Confidence := ValidUtf8Sequences / Max(1, Utf8Sequences);
    if Confidence > 0.75 then
    begin
      Result.DetectedEncoding := TEncoding.UTF8;
      Result.EncodingName := 'UTF-8';
      Result.Confidence := Confidence;
      Result.Description := Format('UTF-8 detected (%.1f%% valid sequences)', [Confidence * 100]);
      Exit;
    end;
  end;
  
  // 检测UTF-16LE/BE
  if Length(Buffer) >= 4 then
  begin
    // UTF-16LE特征：偶数位置多零字节
    if (Utf16EvenBytes > Utf16OddBytes * 5) and (ZeroBytes > Length(Buffer) / 5) then
    begin
      Result.DetectedEncoding := TEncoding.Unicode;
      Result.EncodingName := 'UTF-16LE';
      Result.Confidence := 0.8;
      Result.Description := 'UTF-16LE detected (statistical)';
      Exit;
    end
    
    // UTF-16BE特征：奇数位置多零字节
    else if (Utf16OddBytes > Utf16EvenBytes * 5) and (ZeroBytes > Length(Buffer) / 5) then
    begin
      Result.DetectedEncoding := TEncoding.BigEndianUnicode;
      Result.EncodingName := 'UTF-16BE';
      Result.Confidence := 0.8;
      Result.Description := 'UTF-16BE detected (statistical)';
      Exit;
    end;
  end;
  
  // 默认为ANSI（没有足够证据支持其他编码）
  Result.DetectedEncoding := TEncoding.ANSI;
  Result.EncodingName := 'ANSI';
  Result.Confidence := 0.5;
  Result.Description := 'ANSI detected (default)';
end;

function TEncodingDetector2.DetectByPattern(const Buffer: TBytes): TEncodingDetectionResult;
var
  I, Len: Integer;
  DoubleByteCount, SingleByteCount: Integer;
  DOS437Count, DOS850Count, DOS860Count, DOS865Count: Integer;
  EUCTWCount: Integer;
  Confidence: Double;
begin
  // 初始化结果
  Result.DetectedEncoding := nil;
  Result.EncodingName := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.Description := '';
  Result.LanguageHint := '';
  Result.DetectionMethod := '模式匹配';
  
  Len := Length(Buffer);
  if Len < 10 then Exit; // 太短的文本不适合模式匹配
  
  // 初始化计数器
  DoubleByteCount := 0;
  SingleByteCount := 0;
  DOS437Count := 0;
  DOS850Count := 0;
  DOS860Count := 0;
  DOS865Count := 0;
  EUCTWCount := 0;
  
  // 分析字节模式
  for I := 0 to Len - 2 do
  begin
    // 检查双字节序列
    if (Buffer[I] >= $80) and (Buffer[I+1] >= $30) then
      Inc(DoubleByteCount);
      
    // 检查单字节字符
    if (Buffer[I] >= $20) and (Buffer[I] <= $7F) then
      Inc(SingleByteCount);
    
    // DOS 437编码特征（美国DOS编码）
    if Buffer[I] in [$80..$9F] then
      Inc(DOS437Count);
      
    // DOS 850编码特征（西欧DOS编码）
    if Buffer[I] in [$80..$9F, $A0..$CF] then
      Inc(DOS850Count);
      
    // DOS 860编码特征（葡萄牙语DOS编码）
    if Buffer[I] in [$80..$8F, $90..$9F, $A0..$AF] then
      Inc(DOS860Count);
      
    // DOS 865编码特征（北欧DOS编码）
    if Buffer[I] in [$80..$8F, $90..$9F, $A0..$AF] then
      Inc(DOS865Count);
      
    // EUC-TW编码特征
    if (I < Len - 3) and (Buffer[I] = $8E) and (Buffer[I+1] >= $A1) and 
       (Buffer[I+1] <= $FE) and (Buffer[I+2] >= $A1) and (Buffer[I+2] <= $FE) then
      Inc(EUCTWCount);
  end;
  
  // 分析DOS编码
  if DOS437Count > 10 then
    begin
    Confidence := Min(1.0, DOS437Count / (Len * 0.05));
    if (Confidence > Result.Confidence) and (Confidence > 0.3) then
    begin
      Result.DetectedEncoding := TEncoding.GetEncoding(437);
      Result.EncodingName := 'IBM437';
      Result.Confidence := Confidence;
      Result.Description := Format('检测到IBM437 (DOS美国)编码 (特征字符: %d)', [DOS437Count]);
      Result.LanguageHint := '美国DOS';
    end;
  end;
  
  if DOS850Count > 10 then
  begin
    Confidence := Min(1.0, DOS850Count / (Len * 0.05));
    if (Confidence > Result.Confidence) and (Confidence > 0.3) then
    begin
      Result.DetectedEncoding := TEncoding.GetEncoding(850);
      Result.EncodingName := 'IBM850';
      Result.Confidence := Confidence;
      Result.Description := Format('检测到IBM850 (DOS西欧)编码 (特征字符: %d)', [DOS850Count]);
      Result.LanguageHint := '西欧DOS';
    end;
  end;
  
  if DOS860Count > 10 then
    begin
    Confidence := Min(1.0, DOS860Count / (Len * 0.05));
    if (Confidence > Result.Confidence) and (Confidence > 0.3) then
      begin
      Result.DetectedEncoding := TEncoding.GetEncoding(860);
      Result.EncodingName := 'IBM860';
      Result.Confidence := Confidence;
      Result.Description := Format('检测到IBM860 (DOS葡萄牙语)编码 (特征字符: %d)', [DOS860Count]);
      Result.LanguageHint := '葡萄牙语DOS';
    end;
  end;
  
  if DOS865Count > 10 then
  begin
    Confidence := Min(1.0, DOS865Count / (Len * 0.05));
    if (Confidence > Result.Confidence) and (Confidence > 0.3) then
    begin
      Result.DetectedEncoding := TEncoding.GetEncoding(865);
      Result.EncodingName := 'IBM865';
      Result.Confidence := Confidence;
      Result.Description := Format('检测到IBM865 (DOS北欧)编码 (特征字符: %d)', [DOS865Count]);
      Result.LanguageHint := '北欧DOS';
      end;
    end;
    
  // 检测EUC-TW编码
  if EUCTWCount > 5 then
    begin
    Confidence := Min(1.0, EUCTWCount / (Len * 0.02));
    if (Confidence > Result.Confidence) and (Confidence > 0.3) then
    begin
      Result.DetectedEncoding := TEncoding.GetEncoding(20000); // 使用EUC-TW代码页
      Result.EncodingName := 'EUC-TW';
      Result.Confidence := Confidence;
      Result.Description := Format('检测到EUC-TW (台湾)编码 (特征字符序列: %d)', [EUCTWCount]);
      Result.LanguageHint := '台湾繁体中文';
    end;
  end;
  
  // 其他检测逻辑...
end;

function TEncodingDetector2.CombineResults(const Results: array of TEncodingDetectionResult): TEncodingDetectionResult;
var
  i, BestIndex: Integer;
  BestConfidence: Double;
begin
  // 初始化
  Result.DetectedEncoding := nil;
  Result.EncodingName := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.Description := '';
  Result.LanguageHint := '';
  Result.DetectionMethod := 'Combined';
  
  // 找出最高置信度的结果
  BestIndex := -1;
  BestConfidence := 0;
  
  for i := 0 to High(Results) do
  begin
    // BOM检测总是优先（如果置信度足够高）
    if (Results[i].DetectionMethod = 'BOM') and (Results[i].Confidence > 0.9) then
    begin
      Result := Results[i];
      Exit;
    end;
    
    // 否则，选择置信度最高的结果
    if (Results[i].DetectedEncoding <> nil) and (Results[i].Confidence > BestConfidence) then
    begin
      BestConfidence := Results[i].Confidence;
      BestIndex := i;
    end;
  end;
  
  // 如果找到了最佳结果
  if BestIndex >= 0 then
    Result := Results[BestIndex]
  else
  begin
    // 没有找到明确的结果，使用默认编码
    Result.DetectedEncoding := FOptions.DefaultEncoding;
    Result.EncodingName := GetEncodingFriendlyName(FOptions.DefaultEncoding);
    Result.Confidence := 0.3;
    Result.Description := 'Default encoding (no clear detection)';
  end;
end;

function TEncodingDetector2.DetectBytesEncoding(const Bytes: TBytes): TEncodingDetectionResult;
var
  Results: array of TEncodingDetectionResult;
  I, ResultCount: Integer;
begin
  // 初始化结果
  Result.DetectedEncoding := nil;
  Result.EncodingName := 'Unknown';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.Description := '';
  Result.LanguageHint := '';
  Result.DetectionMethod := '';
  
  // 检查空字节
  if (Length(Bytes) = 0) then
  begin
    Result.Description := '空文件';
    if Assigned(FOptions.DefaultEncoding) then
    begin
      Result.DetectedEncoding := FOptions.DefaultEncoding;
      Result.EncodingName := GetEncodingFriendlyName(Result.DetectedEncoding);
      Result.Confidence := 1.0; // 确定性为100%
      Result.Description := '空文件，使用默认编码';
    end;
    Exit;
  end;
  
  // 预分配结果数组
  SetLength(Results, 10); // 可能的最大结果数
  ResultCount := 0;
  
  // 1. 首先检查BOM
  if edaBOM in FOptions.AlgorithmPriority then
  begin
    var BOMResult := DetectByBOM(Bytes);
    if BOMResult.Confidence > 0 then
    begin
      Results[ResultCount] := BOMResult;
      Inc(ResultCount);
      
      // 如果BOM检测可信度很高，可以直接返回
      if BOMResult.Confidence > 0.95 then
  begin
    Result := BOMResult;
    Exit;
      end;
    end;
  end;
  
  // 2. 统计分析
  if edaStatistical in FOptions.AlgorithmPriority then
  begin
    var StatResult := DetectByStatisticalAnalysis(Bytes);
    if StatResult.Confidence > 0 then
  begin
    Results[ResultCount] := StatResult;
    Inc(ResultCount);
    end;
  end;
  
  // 3. 模式匹配
  if edaPattern in FOptions.AlgorithmPriority then
  begin
    var PatternResult := DetectByPattern(Bytes);
    if PatternResult.Confidence > 0 then
  begin
    Results[ResultCount] := PatternResult;
    Inc(ResultCount);
    end;
  end;
  
  // 4. 针对特定语言的检测
  if FOptions.EnableChineseDetection then
  begin
    var ChineseResult := DetectChineseEncoding(Bytes);
    if ChineseResult.Confidence > 0 then
    begin
      Results[ResultCount] := ChineseResult;
      Inc(ResultCount);
    end;
  end;
  
  if FOptions.EnableJapaneseDetection then
  begin
    var JapaneseResult := DetectJapaneseEncoding(Bytes);
    if JapaneseResult.Confidence > 0 then
    begin
      Results[ResultCount] := JapaneseResult;
      Inc(ResultCount);
    end;
  end;
  
  if FOptions.EnableKoreanDetection then
  begin
    var KoreanResult := DetectKoreanEncoding(Bytes);
    if KoreanResult.Confidence > 0 then
    begin
      Results[ResultCount] := KoreanResult;
      Inc(ResultCount);
    end;
  end;
  
  // 新增的区域编码检测
  var MiddleEasternResult := DetectMiddleEasternEncoding(Bytes);
  if MiddleEasternResult.Confidence > 0 then
  begin
    Results[ResultCount] := MiddleEasternResult;
    Inc(ResultCount);
  end;
  
  var SouthAsianResult := DetectSouthAsianEncoding(Bytes);
  if SouthAsianResult.Confidence > 0 then
  begin
    Results[ResultCount] := SouthAsianResult;
    Inc(ResultCount);
  end;
  
  var EuropeanResult := DetectEuropeanEncoding(Bytes);
  if EuropeanResult.Confidence > 0 then
  begin
    Results[ResultCount] := EuropeanResult;
    Inc(ResultCount);
  end;
  
  var IBMResult := DetectIBMEncoding(Bytes);
  if IBMResult.Confidence > 0 then
  begin
    Results[ResultCount] := IBMResult;
    Inc(ResultCount);
  end;
  
  // 调整结果数组大小
  SetLength(Results, ResultCount);
  
  // 5. 如果有多个结果，合并它们
  if ResultCount > 0 then
  begin
    if edaCombined in FOptions.AlgorithmPriority then
      Result := CombineResults(Results)
    else
      Result := Results[0]; // 使用第一个结果
      
    // 如果首选编码存在，且在结果中有一定置信度，优先选择它
    if Assigned(FOptions.PreferredEncoding) then
    begin
      for I := 0 to ResultCount - 1 do
      begin
        if (Results[I].DetectedEncoding = FOptions.PreferredEncoding) and 
           (Results[I].Confidence >= FOptions.MinConfidence * 0.8) then // 给首选编码一点优惠
        begin
          Result := Results[I];
          Result.Description := Result.Description + ' (首选编码)';
          Break;
        end;
      end;
    end;
  end
  else
  begin
    // 没有找到任何匹配的编码，使用默认编码
    if Assigned(FOptions.DefaultEncoding) then
    begin
      Result.DetectedEncoding := FOptions.DefaultEncoding;
      Result.EncodingName := GetEncodingFriendlyName(Result.DetectedEncoding);
      Result.Confidence := 0.1; // 很低的置信度
      Result.Description := '找不到匹配的编码，使用默认编码';
      Result.DetectionMethod := '默认值';
    end;
  end;
  
  // 在原有代码中的其他区域编码检测后添加这段代码：
  var WindowsCodePageResult := DetectWindowsCodePage(Bytes);
  if WindowsCodePageResult.Confidence > 0 then
  begin
    Results[ResultCount] := WindowsCodePageResult;
    Inc(ResultCount);
  end;
end;

// 中东文字编码检测
function TEncodingDetector2.DetectMiddleEasternEncoding(const Buffer: TBytes): TEncodingDetectionResult;
var
  I, ArabicCount, HebrewCount, WindowsArabicCount, WindowsHebrewCount: Integer;
  Confidence: Double;
begin
  // 初始化结果
  Result.DetectedEncoding := nil;
  Result.EncodingName := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.Description := '';
  Result.LanguageHint := '';
  Result.DetectionMethod := '中东编码启发式检测';
  
  ArabicCount := 0;
  HebrewCount := 0;
  WindowsArabicCount := 0;
  WindowsHebrewCount := 0;
  
  // 分析所有字节
  for I := 0 to Length(Buffer) - 1 do
  begin
    // ISO-8859-6 阿拉伯语特征范围
    if (Buffer[I] >= $A1) and (Buffer[I] <= $F2) then
      Inc(ArabicCount);
      
    // ISO-8859-8 希伯来语特征范围
    if (Buffer[I] >= $E0) and (Buffer[I] <= $FA) then
      Inc(HebrewCount);
      
    // Windows-1256 阿拉伯语特征
    if (Buffer[I] in [$81, $8D, $8F, $90, $9D, $9E, $9F, $C1..$C3, $C5..$CF]) then
      Inc(WindowsArabicCount);
      
    // Windows-1255 希伯来语特征
    if (Buffer[I] in [$C0..$C9, $CB..$D8]) then
      Inc(WindowsHebrewCount);
  end;
  
  // 根据计数决定最可能的编码
  if Length(Buffer) > 0 then
  begin
    // 检查阿拉伯语编码
    if ArabicCount > 0 then
    begin
      Confidence := Min(1.0, ArabicCount / (Length(Buffer) * 0.1));
      
      if WindowsArabicCount > ArabicCount * 0.2 then
      begin
        // 更可能是Windows-1256
        Result.DetectedEncoding := TEncoding.GetEncoding(1256);
        Result.EncodingName := 'Windows-1256';
        Result.Confidence := Confidence * 0.8;
        Result.LanguageHint := '阿拉伯语';
        Result.Description := Format('检测到Windows-1256阿拉伯语编码 (特征字符: %d)', [WindowsArabicCount]);
      end
      else
      begin
        // 更可能是ISO-8859-6
        Result.DetectedEncoding := TEncoding.GetEncoding(28596);
        Result.EncodingName := 'ISO-8859-6';
        Result.Confidence := Confidence * 0.7;
        Result.LanguageHint := '阿拉伯语';
        Result.Description := Format('检测到ISO-8859-6阿拉伯语编码 (特征字符: %d)', [ArabicCount]);
      end;
    end
    
    // 检查希伯来语编码
    else if HebrewCount > 0 then
    begin
      Confidence := Min(1.0, HebrewCount / (Length(Buffer) * 0.1));
      
      if WindowsHebrewCount > HebrewCount * 0.2 then
      begin
        // 更可能是Windows-1255
        Result.DetectedEncoding := TEncoding.GetEncoding(1255);
        Result.EncodingName := 'Windows-1255';
        Result.Confidence := Confidence * 0.8;
        Result.LanguageHint := '希伯来语';
        Result.Description := Format('检测到Windows-1255希伯来语编码 (特征字符: %d)', [WindowsHebrewCount]);
      end
      else
      begin
        // 更可能是ISO-8859-8
        Result.DetectedEncoding := TEncoding.GetEncoding(28598);
        Result.EncodingName := 'ISO-8859-8';
        Result.Confidence := Confidence * 0.7;
        Result.LanguageHint := '希伯来语';
        Result.Description := Format('检测到ISO-8859-8希伯来语编码 (特征字符: %d)', [HebrewCount]);
      end;
    end;
  end;
end;

// 南亚和东南亚编码检测
function TEncodingDetector2.DetectSouthAsianEncoding(const Buffer: TBytes): TEncodingDetectionResult;
var
  I, ThaiCount, VietnameseCount, IndianCount: Integer;
  Confidence: Double;
begin
  // 初始化结果
  Result.DetectedEncoding := nil;
  Result.EncodingName := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.Description := '';
  Result.LanguageHint := '';
  Result.DetectionMethod := '南亚和东南亚编码启发式检测';
  
  ThaiCount := 0;
  VietnameseCount := 0;
  IndianCount := 0;
  
  // 分析所有字节
  for I := 0 to Length(Buffer) - 1 do
  begin
    // TIS-620/Windows-874 泰语特征范围
    if (Buffer[I] >= $A1) and (Buffer[I] <= $FB) then
      Inc(ThaiCount);
      
    // VISCII 越南语特征
    if (Buffer[I] in [$A1..$FE]) and (I < Length(Buffer) - 1) and 
       (Buffer[I+1] >= $20) and (Buffer[I+1] <= $7F) then
      Inc(VietnameseCount);
      
    // ISCII系列印度语言特征
    if (Buffer[I] >= $A0) and (Buffer[I] <= $F7) then
      Inc(IndianCount);
  end;
  
  // 根据计数决定最可能的编码
  if Length(Buffer) > 0 then
  begin
    // 检查泰语编码
    if ThaiCount > Length(Buffer) * 0.05 then
    begin
      Confidence := Min(1.0, ThaiCount / (Length(Buffer) * 0.1));
      Result.DetectedEncoding := TEncoding.GetEncoding(874);
      Result.EncodingName := 'Windows-874';
      Result.Confidence := Confidence * 0.7;
      Result.LanguageHint := '泰语';
      Result.Description := Format('检测到Windows-874/TIS-620泰语编码 (特征字符: %d)', [ThaiCount]);
    end
    // 检查越南语编码
    else if VietnameseCount > Length(Buffer) * 0.03 then
    begin
      Confidence := Min(1.0, VietnameseCount / (Length(Buffer) * 0.08));
      Result.DetectedEncoding := TEncoding.GetEncoding(1258); // 使用Windows-1258作为近似
      Result.EncodingName := 'VISCII/Windows-1258';
      Result.Confidence := Confidence * 0.6;
      Result.LanguageHint := '越南语';
      Result.Description := Format('可能是越南语编码 (特征字符: %d)', [VietnameseCount]);
    end
    // 检查印度语系编码
    else if IndianCount > Length(Buffer) * 0.05 then
    begin
      Confidence := Min(1.0, IndianCount / (Length(Buffer) * 0.1));
      // 我们无法确定具体是哪种ISCII变体，因此使用一个通用描述
      Result.DetectedEncoding := TEncoding.GetEncoding(57002); // 使用ISCII-Devanagari作为代表
      Result.EncodingName := 'ISCII';
      Result.Confidence := Confidence * 0.5;
      Result.LanguageHint := '印度语系';
      Result.Description := Format('可能是印度语系ISCII编码 (特征字符: %d)', [IndianCount]);
    end;
  end;
end;

// 欧洲编码检测
function TEncodingDetector2.DetectEuropeanEncoding(const Buffer: TBytes): TEncodingDetectionResult;
var
  I, Latin1Count, Latin2Count, CyrillicCount, GreekCount, TurkishCount: Integer;
  Latin1Conf, Latin2Conf, CyrillicConf, GreekConf, TurkishConf: Double;
begin
  // 初始化结果
  Result.DetectedEncoding := nil;
  Result.EncodingName := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.Description := '';
  Result.LanguageHint := '';
  Result.DetectionMethod := '欧洲编码启发式检测';
  
  Latin1Count := 0;
  Latin2Count := 0;
  CyrillicCount := 0;
  GreekCount := 0;
  TurkishCount := 0;
  
  // 分析所有字节
  for I := 0 to Length(Buffer) - 1 do
  begin
    // ISO-8859-1 西欧特征范围
    if (Buffer[I] >= $A0) and (Buffer[I] <= $FF) then
      Inc(Latin1Count);
      
    // ISO-8859-2 中欧特征字符
    if Buffer[I] in [$A1, $A3, $A5, $A9, $AB, $AD, $AE, $B1, $B3, $B5, $B9, $BB, $BC, $BE, 
                     $C0..$C6, $C8..$CF, $D0..$D6, $D8..$DF, $E0..$E6, $E8..$EF, $F0..$F6, $F8..$FE] then
      Inc(Latin2Count);
      
    // ISO-8859-5 或 Windows-1251 西里尔字母特征
    if Buffer[I] in [$A8, $B8, $C0..$FF] then
      Inc(CyrillicCount);
      
    // ISO-8859-7 或 Windows-1253 希腊语特征
    if Buffer[I] in [$A1, $A2, $AF, $B6, $B8..$BA, $BC..$BE, $C1..$F2] then
      Inc(GreekCount);
      
    // ISO-8859-9 或 Windows-1254 土耳其语特征
    if Buffer[I] in [$D0, $DD, $DE, $F0, $FD, $FE] then
      Inc(TurkishCount);
  end;
  
  // 计算每种编码的置信度
  if Length(Buffer) > 0 then
  begin
    Latin1Conf := Min(1.0, Latin1Count / (Length(Buffer) * 0.15));
    Latin2Conf := Min(1.0, Latin2Count / (Length(Buffer) * 0.1));
    CyrillicConf := Min(1.0, CyrillicCount / (Length(Buffer) * 0.15));
    GreekConf := Min(1.0, GreekCount / (Length(Buffer) * 0.1));
    TurkishConf := Min(1.0, TurkishCount / (Length(Buffer) * 0.05));
    
    // 比较找出最高置信度的编码
    if (CyrillicConf > Latin1Conf) and (CyrillicConf > Latin2Conf) and 
       (CyrillicConf > GreekConf) and (CyrillicConf > TurkishConf) then
    begin
      // 西里尔字母编码
      if CyrillicConf > 0.1 then // 至少要有一定的置信度
      begin
        Result.DetectedEncoding := TEncoding.GetEncoding(1251); // 优先选择Windows-1251
        Result.EncodingName := 'Windows-1251';
        Result.Confidence := CyrillicConf * 0.8;
        Result.LanguageHint := '俄语或其他斯拉夫语系';
        Result.Description := Format('检测到Windows-1251西里尔字母编码 (特征字符: %d)', [CyrillicCount]);
      end;
    end
    else if (GreekConf > Latin1Conf) and (GreekConf > Latin2Conf) and 
            (GreekConf > CyrillicConf) and (GreekConf > TurkishConf) then
    begin
      // 希腊语编码
      if GreekConf > 0.1 then
      begin
        Result.DetectedEncoding := TEncoding.GetEncoding(1253); // 优先选择Windows-1253
        Result.EncodingName := 'Windows-1253';
        Result.Confidence := GreekConf * 0.8;
        Result.LanguageHint := '希腊语';
        Result.Description := Format('检测到Windows-1253希腊语编码 (特征字符: %d)', [GreekCount]);
      end;
    end
    else if (TurkishConf > 0.2) and (TurkishConf > Latin1Conf * 0.8) then
    begin
      // 土耳其语编码
      Result.DetectedEncoding := TEncoding.GetEncoding(1254); // 优先选择Windows-1254
      Result.EncodingName := 'Windows-1254';
      Result.Confidence := TurkishConf * 0.7;
      Result.LanguageHint := '土耳其语';
      Result.Description := Format('检测到Windows-1254土耳其语编码 (特征字符: %d)', [TurkishCount]);
    end
    else if (Latin2Conf > 0.2) and (Latin2Conf > Latin1Conf * 0.8) then
    begin
      // 中欧编码
      Result.DetectedEncoding := TEncoding.GetEncoding(1250); // 优先选择Windows-1250
      Result.EncodingName := 'Windows-1250';
      Result.Confidence := Latin2Conf * 0.7;
      Result.LanguageHint := '中欧语言';
      Result.Description := Format('检测到Windows-1250中欧编码 (特征字符: %d)', [Latin2Count]);
    end
    else if Latin1Conf > 0.1 then
    begin
      // 西欧编码
      Result.DetectedEncoding := TEncoding.GetEncoding(1252); // 优先选择Windows-1252
      Result.EncodingName := 'Windows-1252';
      Result.Confidence := Latin1Conf * 0.6; // 较低的置信度，因为容易混淆
      Result.LanguageHint := '西欧语言';
      Result.Description := Format('检测到Windows-1252西欧编码 (特征字符: %d)', [Latin1Count]);
    end;
  end;
end;

// IBM/EBCDIC编码检测
function TEncodingDetector2.DetectIBMEncoding(const Buffer: TBytes): TEncodingDetectionResult;
var
  I, EBCDICCount: Integer;
  Confidence: Double;
  HasEBCDICSignature: Boolean;
begin
  // 初始化结果
  Result.DetectedEncoding := nil;
  Result.EncodingName := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.Description := '';
  Result.LanguageHint := '';
  Result.DetectionMethod := 'IBM/EBCDIC编码检测';
  
  EBCDICCount := 0;
  HasEBCDICSignature := False;
  
  // EBCDIC特征：大量字节在$40-$FE范围内，且$00-$3F范围内的字节很少
  // 检查EBCDIC的特征性序列
  if (Length(Buffer) > 3) and
     (Buffer[0] = $C5) and (Buffer[1] = $C2) and (Buffer[2] = $C3) and (Buffer[3] = $C4) then
    HasEBCDICSignature := True;
    
  // 分析所有字节
  for I := 0 to Length(Buffer) - 1 do
  begin
    // EBCDIC字符范围
    if (Buffer[I] >= $40) and (Buffer[I] <= $FE) then
      Inc(EBCDICCount);
  end;
  
  // 根据特征判断是否为EBCDIC编码
  if (Length(Buffer) > 0) and
     ((HasEBCDICSignature) or (EBCDICCount > Length(Buffer) * 0.7)) then
  begin
    Confidence := Min(1.0, EBCDICCount / Length(Buffer));
    
    if HasEBCDICSignature then
      Confidence := Confidence * 1.2; // 提高签名匹配的置信度
      
    // 选择最常见的EBCDIC变体
    Result.DetectedEncoding := TEncoding.GetEncoding(37); // IBM037/EBCDIC-US
    Result.EncodingName := 'EBCDIC-US';
    Result.Confidence := Min(0.9, Confidence); // 限制最高置信度为90%
    Result.Description := Format('检测到EBCDIC编码 (特征字符: %d%s)', 
                                [EBCDICCount, IfThen(HasEBCDICSignature, ', 有特征序列', '')]);
    Result.LanguageHint := 'IBM大型机';
  end;
end;

class function TEncodingDetector2.GetSupportedEncodings: TArray<TEncoding>;
begin
  SetLength(Result, 5);
  Result[0] := TEncoding.ANSI;
  Result[1] := TEncoding.ASCII;
  Result[2] := TEncoding.UTF8;
  Result[3] := TEncoding.Unicode;      // UTF-16LE
  Result[4] := TEncoding.BigEndianUnicode; // UTF-16BE
end;

class function TEncodingDetector2.GetSupportedEncodingNames: TArray<string>;
begin
  SetLength(Result, 32); // 扩展为更多编码
  
  // Unicode编码族
  Result[0] := 'UTF-8';
  Result[1] := 'UTF-8 with BOM';
  Result[2] := 'UTF-16LE';
  Result[3] := 'UTF-16BE';
  Result[4] := 'UTF-32LE';
  Result[5] := 'UTF-32BE';
  
  // 西欧和通用编码
  Result[6] := 'ASCII';
  Result[7] := 'ANSI';
  Result[8] := 'ISO-8859-1';  // 西欧
  Result[9] := 'ISO-8859-2';  // 中欧
  Result[10] := 'ISO-8859-3'; // 南欧
  Result[11] := 'ISO-8859-4'; // 北欧
  Result[12] := 'ISO-8859-5'; // 西里尔字母
  Result[13] := 'ISO-8859-6'; // 阿拉伯语
  Result[14] := 'ISO-8859-7'; // 希腊语
  Result[15] := 'ISO-8859-8'; // 希伯来语
  Result[16] := 'ISO-8859-9'; // 土耳其语
  Result[17] := 'ISO-8859-10'; // 北欧语言
  Result[18] := 'ISO-8859-11'; // 泰语
  Result[19] := 'ISO-8859-13'; // 波罗的海语言
  Result[20] := 'ISO-8859-14'; // 凯尔特语
  Result[21] := 'ISO-8859-15'; // 带欧元符号的西欧
  Result[22] := 'ISO-8859-16'; // 东南欧
  
  // 亚洲语言编码
  Result[23] := 'GBK';        // 简体中文
  Result[24] := 'GB18030';    // 简体中文扩展
  Result[25] := 'GB2312';     // 简体中文基础
  Result[26] := 'Big5';       // 繁体中文
  Result[27] := 'Shift-JIS';  // 日文
  Result[28] := 'EUC-JP';     // 日文扩展
  Result[29] := 'EUC-KR';     // 韩文
  Result[30] := 'KOI8-R';     // 俄文
  Result[31] := 'Windows-1251'; // 西里尔字母(俄文)
end;

class function TEncodingDetector2.GetEncodingByName(const EncodingName: string): TEncoding;
var
  NormalizedName: string;
begin
  NormalizedName := LowerCase(EncodingName);
  
  // 基础和Unicode编码
  if (NormalizedName = 'ansi') then
    Result := TEncoding.ANSI
  else if (NormalizedName = 'ascii') then
    Result := TEncoding.ASCII
  else if (NormalizedName = 'utf-8') or (NormalizedName = 'utf8') then
    Result := TEncoding.UTF8
  else if (NormalizedName = 'utf-8 with bom') or (NormalizedName = 'utf8-bom') or 
          (NormalizedName = 'utf-8-bom') then
    Result := TEncoding.UTF8 // BOM会在转换时处理
  else if (NormalizedName = 'utf-16') or (NormalizedName = 'utf16') or 
          (NormalizedName = 'utf-16le') or (NormalizedName = 'utf16le') then
    Result := TEncoding.Unicode
  else if (NormalizedName = 'utf-16be') or (NormalizedName = 'utf16be') then
    Result := TEncoding.BigEndianUnicode
  else if (NormalizedName = 'utf-32le') or (NormalizedName = 'utf32le') then
  begin
    try
      Result := TEncoding.GetEncoding(12000); // UTF-32LE代码页
    except
      Result := TEncoding.Unicode; // 降级为UTF-16LE
    end;
  end
  else if (NormalizedName = 'utf-32be') or (NormalizedName = 'utf32be') then
  begin
    try
      Result := TEncoding.GetEncoding(12001); // UTF-32BE代码页
    except
      Result := TEncoding.BigEndianUnicode; // 降级为UTF-16BE
    end;
  end
  
  // 中文编码
  else if (NormalizedName = 'gbk') then
  begin
    try
      Result := TEncoding.GetEncoding(936); // GBK代码页
    except
      Result := TEncoding.ANSI;
    end;
  end
  else if (NormalizedName = 'gb2312') then
  begin
    try
      Result := TEncoding.GetEncoding(936); // GB2312使用同一代码页
    except
      Result := TEncoding.ANSI;
    end;
  end
  else if (NormalizedName = 'gb18030') then
  begin
    try
      Result := TEncoding.GetEncoding(54936); // GB18030代码页
    except
      try
        Result := TEncoding.GetEncoding(936); // 降级为GBK
      except
        Result := TEncoding.ANSI;
      end;
    end;
  end
  else if (NormalizedName = 'big5') then
  begin
    try
      Result := TEncoding.GetEncoding(950); // Big5代码页
    except
      Result := TEncoding.ANSI;
    end;
  end
  
  // 日韩编码
  else if (NormalizedName = 'shift-jis') or (NormalizedName = 'shiftjis') then
  begin
    try
      Result := TEncoding.GetEncoding(932); // Shift-JIS代码页
    except
      Result := TEncoding.ANSI;
    end;
  end
  else if (NormalizedName = 'euc-jp') or (NormalizedName = 'eucjp') then
  begin
    try
      Result := TEncoding.GetEncoding(20932); // EUC-JP代码页
    except
      Result := TEncoding.ANSI;
    end;
  end
  else if (NormalizedName = 'euc-kr') or (NormalizedName = 'euckr') then
  begin
    try
      Result := TEncoding.GetEncoding(51949); // EUC-KR代码页
    except
      Result := TEncoding.ANSI;
    end;
  end
  
  // ISO-8859系列
  else if NormalizedName.StartsWith('iso-8859-') or NormalizedName.StartsWith('iso8859-') then
  begin
    var ISONumber := 1; // 默认ISO-8859-1
    
    // 提取ISO编号
    if Length(NormalizedName) > 9 then
    begin
      var NumStr := Copy(NormalizedName, 10, Length(NormalizedName) - 9);
      TryStrToInt(NumStr, ISONumber);
    end;
    
    // 转换ISO编号到代码页
    var CodePage := 28590 + ISONumber; // ISO-8859-1 = 28591, ISO-8859-2 = 28592, 等等
    
    try
      Result := TEncoding.GetEncoding(CodePage);
    except
      Result := TEncoding.ANSI; // 如果不支持则降级
    end;
  end
  
  // 斯拉夫语系
  else if (NormalizedName = 'koi8-r') or (NormalizedName = 'koi8r') then
  begin
    try
      Result := TEncoding.GetEncoding(20866); // KOI8-R代码页
    except
      Result := TEncoding.ANSI;
    end;
  end
  else if (NormalizedName = 'windows-1251') or (NormalizedName = 'cp1251') then
  begin
    try
      Result := TEncoding.GetEncoding(1251); // Windows-1251代码页
    except
      Result := TEncoding.ANSI;
    end;
  end
  
  // 默认返回ANSI
  else
    Result := TEncoding.ANSI; 
end;

class function TEncodingDetector2.GetEncodingFriendlyName(Encoding: TEncoding): string;
begin
  if Encoding = nil then
    Result := 'Unknown'
  else if Encoding = TEncoding.ANSI then
    Result := 'ANSI'
  else if Encoding = TEncoding.ASCII then
    Result := 'ASCII'
  else if Encoding = TEncoding.UTF8 then
    Result := 'UTF-8'
  else if Encoding = TEncoding.Unicode then
    Result := 'UTF-16LE'
  else if Encoding = TEncoding.BigEndianUnicode then
    Result := 'UTF-16BE'
  else if Encoding.CodePage = 12000 then
    Result := 'UTF-32LE'
  else if Encoding.CodePage = 12001 then
    Result := 'UTF-32BE'
  else if Encoding.CodePage = 936 then
    Result := 'GBK/GB2312'
  else if Encoding.CodePage = 54936 then
    Result := 'GB18030'
  else if Encoding.CodePage = 950 then
    Result := 'Big5'
  else if Encoding.CodePage = 932 then
    Result := 'Shift-JIS'
  else if Encoding.CodePage = 20932 then
    Result := 'EUC-JP'
  else if Encoding.CodePage = 51949 then
    Result := 'EUC-KR'
  else if Encoding.CodePage = 20866 then
    Result := 'KOI8-R'
  else if Encoding.CodePage = 1251 then
    Result := 'Windows-1251'
  // ISO-8859系列
  else if (Encoding.CodePage >= 28591) and (Encoding.CodePage <= 28599) then
    Result := Format('ISO-8859-%d', [Encoding.CodePage - 28590])
  else if (Encoding.CodePage >= 28600) and (Encoding.CodePage <= 28606) then
    Result := Format('ISO-8859-%d', [Encoding.CodePage - 28590])
  else
    Result := Format('CodePage %d', [Encoding.CodePage]);
end;

// 中文编码分析 - 检查是否是有效的GB18030四字节序列
function TEncodingDetector2.IsValidGB18030Sequence(const Buffer: TBytes; Pos: Integer; out SequenceLen: Integer): Boolean;
begin
  SequenceLen := 0;
  Result := False;
  
  // 检查是否有足够的字节
  if Pos + 3 >= Length(Buffer) then
    Exit;
    
  // GB18030四字节序列：第1字节($81-$FE)，第2字节($30-$39)，第3字节($81-$FE)，第4字节($30-$39)
  if (Buffer[Pos] >= $81) and (Buffer[Pos] <= $FE) and
     (Buffer[Pos+1] >= $30) and (Buffer[Pos+1] <= $39) and
     (Buffer[Pos+2] >= $81) and (Buffer[Pos+2] <= $FE) and
     (Buffer[Pos+3] >= $30) and (Buffer[Pos+3] <= $39) then
  begin
    SequenceLen := 4;
    Result := True;
  end;
end;

// 中文编码分析 - 检查是否是有效的GBK双字节序列
function TEncodingDetector2.IsValidGBKSequence(const Buffer: TBytes; Pos: Integer; out SequenceLen: Integer): Boolean;
begin
  SequenceLen := 0;
  Result := False;
  
  // 检查是否有足够的字节
  if Pos + 1 >= Length(Buffer) then
    Exit;
    
  // GBK双字节序列：第1字节($81-$FE)，第2字节($40-$FE，排除$7F)
  if (Buffer[Pos] >= $81) and (Buffer[Pos] <= $FE) and
     (Buffer[Pos+1] >= $40) and (Buffer[Pos+1] <= $FE) and
     (Buffer[Pos+1] <> $7F) then
  begin
    SequenceLen := 2;
    Result := True;
  end;
end;

// 中文编码分析 - 检查是否是有效的GB2312双字节序列
function TEncodingDetector2.IsValidGB2312Sequence(const Buffer: TBytes; Pos: Integer; out SequenceLen: Integer): Boolean;
begin
  SequenceLen := 0;
  Result := False;
  
  // 检查是否有足够的字节
  if Pos + 1 >= Length(Buffer) then
    Exit;
    
  // GB2312双字节序列：第1字节($A1-$F7)，第2字节($A1-$FE)
  if (Buffer[Pos] >= $A1) and (Buffer[Pos] <= $F7) and
     (Buffer[Pos+1] >= $A1) and (Buffer[Pos+1] <= $FE) then
  begin
    SequenceLen := 2;
    Result := True;
  end;
end;

// 分析中文字节序列，统计各种编码的计数
function TEncodingDetector2.AnalyzeChineseBytes(const Buffer: TBytes; 
                                               out GB2312Count, GBKCount, GB18030Count: Integer): Double;
var
  i, SequenceLen: Integer;
  ValidSequenceCount, TotalHighBitCount: Integer;
begin
  GB2312Count := 0;
  GBKCount := 0;
  GB18030Count := 0;
  ValidSequenceCount := 0;
  TotalHighBitCount := 0;
  
  i := 0;
  while i < Length(Buffer) do
  begin
    // 跳过ASCII字符
    if Buffer[i] <= $7F then
    begin
      Inc(i);
      Continue;
    end;
    
    Inc(TotalHighBitCount);
    
    // 检测GB18030四字节序列
    if IsValidGB18030Sequence(Buffer, i, SequenceLen) then
    begin
      Inc(GB18030Count);
      Inc(ValidSequenceCount);
      Inc(i, 4);
      Continue;
    end
    
    // 检测GB2312双字节序列（它也是GBK的子集）
    else if IsValidGB2312Sequence(Buffer, i, SequenceLen) then
    begin
      Inc(GB2312Count);
      Inc(ValidSequenceCount);
      Inc(i, 2);
      Continue;
    end
    
    // 检测其他GBK双字节序列
    else if IsValidGBKSequence(Buffer, i, SequenceLen) then
    begin
      Inc(GBKCount);
      Inc(ValidSequenceCount);
      Inc(i, 2);
      Continue;
    end;
    
    // 无效序列，移动一个字节
    Inc(i);
  end;
  
  // 计算有效序列占高位字节的比例，作为检测准确度的指标
  if TotalHighBitCount > 0 then
    Result := ValidSequenceCount / TotalHighBitCount
  else
    Result := 0.0;
end;

// 专门检测中文编码
function TEncodingDetector2.DetectChineseEncoding(const Buffer: TBytes): TEncodingDetectionResult;
var
  GB2312Count, GBKCount, GB18030Count: Integer;
  Confidence: Double;
  TotalValid: Integer;
begin
  Result.DetectedEncoding := nil;
  Result.EncodingName := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.Description := '';
  Result.LanguageHint := '';
  Result.DetectionMethod := 'Chinese';
  
  // 分析中文字节序列
  Confidence := AnalyzeChineseBytes(Buffer, GB2312Count, GBKCount, GB18030Count);
  TotalValid := GB2312Count + GBKCount + GB18030Count;
  
  // 没有发现任何有效的中文编码序列
  if TotalValid = 0 then
    Exit;
  
  Result.LanguageHint := '中文';
  
  // 判断使用哪种中文编码
  if GB18030Count > 0 then
  begin
    try
      Result.DetectedEncoding := TEncoding.GetEncoding(54936); // GB18030
      Result.EncodingName := 'GB18030';
      Result.Confidence := Max(0.7, Min(0.95, Confidence));
      Result.Description := Format('GB18030 detected (%d sequences)', [TotalValid]);
    except
      Result.DetectedEncoding := TEncoding.GetEncoding(936); // 回退到GBK
      Result.EncodingName := 'GBK';
      Result.Confidence := Max(0.6, Min(0.9, Confidence));
      Result.Description := 'GBK detected (GB18030 not supported)';
    end;
  end
  else if GBKCount > 0 then
  begin
    try
      Result.DetectedEncoding := TEncoding.GetEncoding(936); // GBK
      Result.EncodingName := 'GBK';
      Result.Confidence := Max(0.7, Min(0.95, Confidence));
      Result.Description := Format('GBK detected (%d sequences)', [TotalValid]);
    except
      Result.DetectedEncoding := TEncoding.ANSI;
      Result.EncodingName := 'ANSI';
      Result.Confidence := Max(0.5, Min(0.8, Confidence));
      Result.Description := 'ANSI detected (GBK not supported)';
    end;
  end
  else if GB2312Count > 0 then
  begin
    try
      Result.DetectedEncoding := TEncoding.GetEncoding(936); // GB2312属于GBK子集
      Result.EncodingName := 'GB2312';
      Result.Confidence := Max(0.7, Min(0.95, Confidence));
      Result.Description := Format('GB2312 detected (%d sequences)', [TotalValid]);
    except
      Result.DetectedEncoding := TEncoding.ANSI;
      Result.EncodingName := 'ANSI';
      Result.Confidence := Max(0.5, Min(0.8, Confidence));
      Result.Description := 'ANSI detected (GB2312 not supported)';
    end;
  end;
end;

// 日文编码分析 - 检查是否是有效的Shift-JIS序列
function TEncodingDetector2.IsValidShiftJISSequence(const Buffer: TBytes; Pos: Integer; out SequenceLen: Integer): Boolean;
begin
  SequenceLen := 0;
  Result := False;
  
  // 检查是否有足够的字节
  if Pos + 1 >= Length(Buffer) then
    Exit;
    
  // Shift-JIS序列：第1字节($81-$9F, $E0-$EF)，第2字节($40-$7E, $80-$9E)
  if (Buffer[Pos] >= $81) and (Buffer[Pos] <= $9F) or
     (Buffer[Pos] >= $E0) and (Buffer[Pos] <= $EF) then
  begin
    if (Buffer[Pos+1] >= $40) and (Buffer[Pos+1] <= $7E) or
       (Buffer[Pos+1] >= $80) and (Buffer[Pos+1] <= $9E) then
    begin
      SequenceLen := 2;
      Result := True;
    end;
  end;
end;

// 日文编码分析 - 检查是否是有效的EUC-JP序列
function TEncodingDetector2.IsValidEUCJPSequence(const Buffer: TBytes; Pos: Integer; out SequenceLen: Integer): Boolean;
begin
  SequenceLen := 0;
  Result := False;
  
  // 检查是否有足够的字节
  if Pos + 1 >= Length(Buffer) then
    Exit;
    
  // EUC-JP序列：第1字节($A1-$DF)，第2字节($A1-$FE)
  if (Buffer[Pos] >= $A1) and (Buffer[Pos] <= $DF) then
  begin
    if (Buffer[Pos+1] >= $A1) and (Buffer[Pos+1] <= $FE) then
    begin
      SequenceLen := 2;
      Result := True;
    end;
  end;
end;

// 分析日文字节序列，统计各种编码的计数
function TEncodingDetector2.AnalyzeJapaneseBytes(const Buffer: TBytes;
                                                 out ShiftJISCount, EUCJPCount: Integer): Double;
var
  i, SequenceLen: Integer;
  ValidSequenceCount: Integer;
begin
  ShiftJISCount := 0;
  EUCJPCount := 0;
  ValidSequenceCount := 0;
  
  for i := 0 to Length(Buffer) - 1 do
  begin
    // 检测Shift-JIS序列
    if IsValidShiftJISSequence(Buffer, i, SequenceLen) then
    begin
      Inc(ShiftJISCount);
      Inc(ValidSequenceCount);
      Inc(i, 2);
      Continue;
    end;
    
    // 检测EUC-JP序列
    if IsValidEUCJPSequence(Buffer, i, SequenceLen) then
    begin
      Inc(EUCJPCount);
      Inc(ValidSequenceCount);
      Inc(i, 2);
      Continue;
    end;
  end;
  
  // 计算有效序列占总序列的比例，作为检测准确度的指标
  if Length(Buffer) > 0 then
    Result := ValidSequenceCount / Length(Buffer)
  else
    Result := 0.0;
end;

// 专门检测日文编码
function TEncodingDetector2.DetectJapaneseEncoding(const Buffer: TBytes): TEncodingDetectionResult;
var
  ShiftJISCount, EUCJPCount: Integer;
  Confidence: Double;
begin
  Result.DetectedEncoding := nil;
  Result.EncodingName := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.Description := '';
  Result.LanguageHint := '';
  Result.DetectionMethod := 'Japanese';
  
  // 分析日文字节序列
  Confidence := AnalyzeJapaneseBytes(Buffer, ShiftJISCount, EUCJPCount);
  
  // 没有发现任何有效的日文编码序列
  if (ShiftJISCount = 0) and (EUCJPCount = 0) then
    Exit;
  
  Result.LanguageHint := '日文';
  
  // 判断使用哪种日文编码
  if ShiftJISCount > 0 then
  begin
    try
      Result.DetectedEncoding := TEncoding.GetEncoding(932); // Shift-JIS
      Result.EncodingName := 'Shift-JIS';
      Result.Confidence := Max(0.7, Min(0.95, Confidence));
      Result.Description := Format('Shift-JIS detected (%d sequences)', [ShiftJISCount]);
    except
      Result.DetectedEncoding := TEncoding.ANSI;
      Result.EncodingName := 'ANSI';
      Result.Confidence := Max(0.5, Min(0.8, Confidence));
      Result.Description := 'ANSI detected (Shift-JIS not supported)';
    end;
  end
  else if EUCJPCount > 0 then
  begin
    try
      Result.DetectedEncoding := TEncoding.GetEncoding(20932); // EUC-JP
      Result.EncodingName := 'EUC-JP';
      Result.Confidence := Max(0.7, Min(0.95, Confidence));
      Result.Description := Format('EUC-JP detected (%d sequences)', [EUCJPCount]);
    except
      Result.DetectedEncoding := TEncoding.ANSI;
      Result.EncodingName := 'ANSI';
      Result.Confidence := Max(0.5, Min(0.8, Confidence));
      Result.Description := 'ANSI detected (EUC-JP not supported)';
    end;
  end;
end;

// 韩文编码分析 - 检查是否是有效的EUC-KR序列
function TEncodingDetector2.IsValidEUCKRSequence(const Buffer: TBytes; Pos: Integer; out SequenceLen: Integer): Boolean;
begin
  SequenceLen := 0;
  Result := False;
  
  // 检查是否有足够的字节
  if Pos + 1 >= Length(Buffer) then
    Exit;
    
  // EUC-KR序列：第1字节($A1-$FE)，第2字节($40-$7E, $80-$9F)
  if (Buffer[Pos] >= $A1) and (Buffer[Pos] <= $FE) then
  begin
    if (Buffer[Pos+1] >= $40) and (Buffer[Pos+1] <= $7E) or
       (Buffer[Pos+1] >= $80) and (Buffer[Pos+1] <= $9F) then
    begin
      SequenceLen := 2;
      Result := True;
    end;
  end;
end;

// 分析韩文字节序列，统计各种编码的计数
function TEncodingDetector2.AnalyzeKoreanBytes(const Buffer: TBytes;
                                               out EUCKRCount: Integer): Double;
var
  i, SequenceLen: Integer;
  ValidSequenceCount: Integer;
begin
  EUCKRCount := 0;
  ValidSequenceCount := 0;
  
  for i := 0 to Length(Buffer) - 1 do
  begin
    // 检测EUC-KR序列
    if IsValidEUCKRSequence(Buffer, i, SequenceLen) then
    begin
      Inc(EUCKRCount);
      Inc(ValidSequenceCount);
      Inc(i, 2);
      Continue;
    end;
  end;
  
  // 计算有效序列占总序列的比例，作为检测准确度的指标
  if Length(Buffer) > 0 then
    Result := ValidSequenceCount / Length(Buffer)
  else
    Result := 0.0;
end;

// 专门检测韩文编码
function TEncodingDetector2.DetectKoreanEncoding(const Buffer: TBytes): TEncodingDetectionResult;
var
  EUCKRCount: Integer;
  Confidence: Double;
begin
  Result.DetectedEncoding := nil;
  Result.EncodingName := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.Description := '';
  Result.LanguageHint := '';
  Result.DetectionMethod := 'Korean';
  
  // 分析韩文字节序列
  Confidence := AnalyzeKoreanBytes(Buffer, EUCKRCount);
  
  // 没有发现任何有效的韩文编码序列
  if EUCKRCount = 0 then
    Exit;
  
  Result.LanguageHint := '韩文';
  
  // 判断使用哪种韩文编码
  try
    Result.DetectedEncoding := TEncoding.GetEncoding(51949); // EUC-KR
    Result.EncodingName := 'EUC-KR';
    Result.Confidence := Max(0.7, Min(0.95, Confidence));
    Result.Description := Format('EUC-KR detected (%d sequences)', [EUCKRCount]);
  except
    Result.DetectedEncoding := TEncoding.ANSI;
    Result.EncodingName := 'ANSI';
    Result.Confidence := Max(0.5, Min(0.8, Confidence));
    Result.Description := 'ANSI detected (EUC-KR not supported)';
  end;
end;

// 添加方法实现
function TEncodingDetector2.DetectWindowsCodePage(const Buffer: TBytes): TEncodingDetectionResult;
var
  I, Len: Integer;
  CP932Count, CP949Count, CP950Count, CP936Count: Integer;
  Confidence: Double;
begin
  // 初始化结果
  Result.DetectedEncoding := nil;
  Result.EncodingName := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.Description := '';
  Result.LanguageHint := '';
  Result.DetectionMethod := 'Windows代码页检测';
  
  Len := Length(Buffer);
  if Len < 20 then Exit; // 太短的文本不适合检测
  
  // 初始化计数器
  CP932Count := 0;
  CP949Count := 0;
  CP950Count := 0;
  CP936Count := 0;
  
  // 分析字节模式
  for I := 0 to Len - 2 do
  begin
    // CP932 (日本Windows)特征
    if ((Buffer[I] >= $81) and (Buffer[I] <= $9F) or (Buffer[I] >= $E0) and (Buffer[I] <= $FC)) and
       ((Buffer[I+1] >= $40) and (Buffer[I+1] <= $FC)) then
      Inc(CP932Count);
      
    // CP949 (韩国Windows)特征
    if ((Buffer[I] >= $81) and (Buffer[I] <= $FE)) and
       ((Buffer[I+1] >= $41) and (Buffer[I+1] <= $FE)) then
      Inc(CP949Count);
      
    // CP950 (繁体中文Windows)特征
    if ((Buffer[I] >= $A1) and (Buffer[I] <= $FE)) and
       ((Buffer[I+1] >= $40) and (Buffer[I+1] <= $7E) or (Buffer[I+1] >= $A1) and (Buffer[I+1] <= $FE)) then
      Inc(CP950Count);
      
    // CP936 (简体中文Windows)特征
    if ((Buffer[I] >= $81) and (Buffer[I] <= $FE)) and
       ((Buffer[I+1] >= $40) and (Buffer[I+1] <= $7E) or (Buffer[I+1] >= $80) and (Buffer[I+1] <= $FE)) then
      Inc(CP936Count);
  end;
  
  // 依次检测各种代码页
  if CP932Count > 10 then
  begin
    Confidence := Min(1.0, CP932Count / (Len * 0.1));
    if Confidence > 0.3 then
    begin
      Result.DetectedEncoding := TEncoding.GetEncoding(932);
      Result.EncodingName := 'CP932';
      Result.Confidence := Confidence;
      Result.Description := Format('检测到CP932 (日本Windows)编码 (特征序列: %d)', [CP932Count]);
      Result.LanguageHint := '日语';
    end;
  end;
  
  if (CP949Count > 10) and (CP949Count > CP932Count) then
  begin
    Confidence := Min(1.0, CP949Count / (Len * 0.1));
    if Confidence > 0.3 then
    begin
      Result.DetectedEncoding := TEncoding.GetEncoding(949);
      Result.EncodingName := 'CP949';
      Result.Confidence := Confidence;
      Result.Description := Format('检测到CP949 (韩国Windows)编码 (特征序列: %d)', [CP949Count]);
      Result.LanguageHint := '韩语';
    end;
  end;
  
  if (CP950Count > 10) and (CP950Count > CP949Count) and (CP950Count > CP932Count) then
  begin
    Confidence := Min(1.0, CP950Count / (Len * 0.1));
    if Confidence > 0.3 then
    begin
      Result.DetectedEncoding := TEncoding.GetEncoding(950);
      Result.EncodingName := 'CP950';
      Result.Confidence := Confidence;
      Result.Description := Format('检测到CP950 (繁体中文Windows)编码 (特征序列: %d)', [CP950Count]);
      Result.LanguageHint := '繁体中文';
    end;
  end;
  
  if (CP936Count > 10) and (CP936Count > CP950Count) and (CP936Count > CP949Count) and (CP936Count > CP932Count) then
  begin
    Confidence := Min(1.0, CP936Count / (Len * 0.1));
    if Confidence > 0.3 then
    begin
      Result.DetectedEncoding := TEncoding.GetEncoding(936);
      Result.EncodingName := 'CP936';
      Result.Confidence := Confidence;
      Result.Description := Format('检测到CP936 (简体中文Windows)编码 (特征序列: %d)', [CP936Count]);
      Result.LanguageHint := '简体中文';
    end;
  end;
end;

end. 