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
  HasNulls: Boolean;
  NullPosition: Integer;
  i: Integer;
begin
  Result.DetectedEncoding := nil;
  Result.EncodingName := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.Description := '';
  Result.LanguageHint := '';
  Result.DetectionMethod := 'Pattern';
  
  if Length(Buffer) = 0 then
    Exit;
  
  // 检查零字节模式
  HasNulls := False;
  NullPosition := -1;
  
  for i := 0 to Min(Length(Buffer) - 1, 1000) do
  begin
    if Buffer[i] = 0 then
    begin
      HasNulls := True;
      NullPosition := i;
      Break;
    end;
  end;
  
  // 零字节在偶数位置，可能是UTF-16LE
  if HasNulls and (NullPosition >= 0) and (NullPosition mod 2 = 0) then
  begin
    // 进一步检查是否符合UTF-16LE模式
    var ConsistentPattern := True;
    var CheckCount := 0;
    
    // 检查更多样本
    for i := NullPosition to Min(Length(Buffer) - 2, NullPosition + 100) do
    begin
      if i mod 2 = 0 then
      begin
        if Buffer[i] <> 0 then
        begin
          ConsistentPattern := False;
          Break;
        end;
        Inc(CheckCount);
        if CheckCount >= 5 then Break; // 检查足够多的样本
      end;
    end;
    
    if ConsistentPattern and (CheckCount >= 3) then
    begin
      Result.DetectedEncoding := TEncoding.Unicode;
      Result.EncodingName := 'UTF-16LE';
      Result.Confidence := 0.85;
      Result.Description := 'UTF-16LE detected (pattern)';
      Exit;
    end;
  end;
  
  // 默认返回空结果
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
  BOMResult, StatResult, PatternResult, ChineseResult, JapaneseResult, KoreanResult: TEncodingDetectionResult;
  Results: array of TEncodingDetectionResult;
  ResultCount: Integer;
begin
  // 初始化结果
  Result.DetectedEncoding := nil;
  Result.EncodingName := 'Unknown';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.Description := '';
  Result.LanguageHint := '';
  Result.DetectionMethod := '';
  
  if Length(Bytes) = 0 then
    Exit;
  
  // 1. 检测BOM
  BOMResult := DetectByBOM(Bytes);
  
  // 如果BOM检测成功且置信度高，直接返回结果
  if (BOMResult.DetectedEncoding <> nil) and (BOMResult.Confidence > 0.9) then
  begin
    Result := BOMResult;
    Exit;
  end;
  
  // 2. 进行多种检测方法
  ResultCount := 1; // BOM结果已经有了
  SetLength(Results, 6); // 预先分配6个结果空间
  Results[0] := BOMResult;
  
  // 统计分析方法
  StatResult := DetectByStatisticalAnalysis(Bytes);
  if StatResult.DetectedEncoding <> nil then
  begin
    Results[ResultCount] := StatResult;
    Inc(ResultCount);
  end;
  
  // 模式匹配方法
  PatternResult := DetectByPattern(Bytes);
  if PatternResult.DetectedEncoding <> nil then
  begin
    Results[ResultCount] := PatternResult;
    Inc(ResultCount);
  end;
  
  // 中文编码检测
  if FOptions.EnableChineseDetection then
  begin
    ChineseResult := DetectChineseEncoding(Bytes);
    if ChineseResult.DetectedEncoding <> nil then
    begin
      Results[ResultCount] := ChineseResult;
      Inc(ResultCount);
    end;
  end;
  
  // 日文编码检测
  if FOptions.EnableJapaneseDetection then
  begin
    JapaneseResult := DetectJapaneseEncoding(Bytes);
    if JapaneseResult.DetectedEncoding <> nil then
    begin
      Results[ResultCount] := JapaneseResult;
      Inc(ResultCount);
    end;
  end;
  
  // 韩文编码检测
  if FOptions.EnableKoreanDetection then
  begin
    KoreanResult := DetectKoreanEncoding(Bytes);
    if KoreanResult.DetectedEncoding <> nil then
    begin
      Results[ResultCount] := KoreanResult;
      Inc(ResultCount);
    end;
  end;
  
  // 3. 组合所有结果
  SetLength(Results, ResultCount);
  Result := CombineResults(Results);
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

end. 