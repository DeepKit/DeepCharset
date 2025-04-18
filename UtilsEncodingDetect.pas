unit UtilsEncodingDetect;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.Types, Winapi.Windows,
  JclBOM, JclStrings, JclStringConversions, JclFileUtils, JclStreams;

type
  // 编码检测结果结构体
  TEncodingDetectResult = record
    EncodingName: string;     // 编码名称
    Confidence: Integer;      // 置信度 (0-100)
    HasBOM: Boolean;          // 是否有BOM
    LanguageHint: string;     // 语言提示
    ProcessTimeMs: Integer;   // 处理时间(毫秒)
  end;

  // 编码检测统计信息
  TEncodingStats = record
    TotalBytes: Integer;      // 总字节数
    ASCIICount: Integer;      // ASCII字符数
    NonASCIICount: Integer;   // 非ASCII字符数
    ValidSequences: Integer;  // 有效序列数
    InvalidSequences: Integer; // 无效序列数
    ChineseChars: Integer;    // 中文字符数
    JapaneseChars: Integer;   // 日文字符数
    KoreanChars: Integer;     // 韩文字符数
    MaxConsecutiveValid: Integer; // 最长连续有效序列
  end;

  // 编码检测器类
  TEncodingDetector = class
  private
    FLogCallback: TProc<string>;
    FLastError: string;
    FPerformanceLog: Boolean;

    // 内部检测方法
    function DetectBOMEncoding(const Stream: TStream; out BOMLength: Integer): string;
    function DetectUTF8Encoding(const Buffer: TBytes; Size: Integer; out Stats: TEncodingStats): Boolean;
    function DetectGBKEncoding(const Buffer: TBytes; Size: Integer; out Stats: TEncodingStats): Boolean;
    function DetectBig5Encoding(const Buffer: TBytes; Size: Integer; out Stats: TEncodingStats): Boolean;
    function DetectShiftJISEncoding(const Buffer: TBytes; Size: Integer; out Stats: TEncodingStats): Boolean;
    function DetectEUCJPEncoding(const Buffer: TBytes; Size: Integer; out Stats: TEncodingStats): Boolean;
    function DetectEUCKREncoding(const Buffer: TBytes; Size: Integer; out Stats: TEncodingStats): Boolean;

    // 基于文件扩展名的编码提示
    function GetEncodingHintByFileExt(const FileName: string): string;

    // 日志记录
    procedure LogMessage(const Msg: string);
    procedure LogStats(const Prefix: string; const Stats: TEncodingStats);

  public
    constructor Create(ALogCallback: TProc<string> = nil);
    destructor Destroy; override;

    // 主要检测方法
    function DetectFileEncoding(const FileName: string): TEncodingDetectResult;
    function DetectStreamEncoding(Stream: TStream): TEncodingDetectResult;
    function DetectBufferEncoding(const Buffer: TBytes; Size: Integer): TEncodingDetectResult;

    // 辅助方法
    function HasBOM(const FileName: string): Boolean;
    function GetEncodingName(CodePage: Integer; HasBOM: Boolean = False): string;

    // 属性
    property LastError: string read FLastError;
    property PerformanceLog: Boolean read FPerformanceLog write FPerformanceLog;
  end;

implementation

uses
  System.Diagnostics, System.IOUtils, System.StrUtils;

{ TEncodingDetector }

constructor TEncodingDetector.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := ALogCallback;
  FLastError := '';
  FPerformanceLog := False;
  LogMessage('编码检测器已初始化');
end;

destructor TEncodingDetector.Destroy;
begin
  inherited;
end;

procedure TEncodingDetector.LogMessage(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

procedure TEncodingDetector.LogStats(const Prefix: string; const Stats: TEncodingStats);
begin
  if not Assigned(FLogCallback) or not FPerformanceLog then
    Exit;

  FLogCallback(Format('%s - 统计: 总字节=%d, ASCII=%d, 非ASCII=%d, 有效序列=%d, 无效序列=%d, ' +
                      '中文=%d, 日文=%d, 韩文=%d, 最长连续有效=%d',
                      [Prefix, Stats.TotalBytes, Stats.ASCIICount, Stats.NonASCIICount,
                       Stats.ValidSequences, Stats.InvalidSequences,
                       Stats.ChineseChars, Stats.JapaneseChars, Stats.KoreanChars,
                       Stats.MaxConsecutiveValid]));
end;

function TEncodingDetector.GetEncodingHintByFileExt(const FileName: string): string;
var
  FileExt: string;
begin
  Result := '';
  FileExt := LowerCase(ExtractFileExt(FileName));

  // 基于文件扩展名的编码提示
  if (FileExt = '.pas') or (FileExt = '.dpr') or (FileExt = '.dfm') or
     (FileExt = '.cpp') or (FileExt = '.h') or (FileExt = '.hpp') or
     (FileExt = '.cs') or (FileExt = '.java') or (FileExt = '.js') or
     (FileExt = '.ts') or (FileExt = '.py') or (FileExt = '.rb') or
     (FileExt = '.php') or (FileExt = '.html') or (FileExt = '.htm') or
     (FileExt = '.xml') or (FileExt = '.json') or (FileExt = '.css') or
     (FileExt = '.md') or (FileExt = '.txt') or (FileExt = '.ini') then
  begin
    Result := 'UTF-8';
  end
  else if (FileExt = '.bat') or (FileExt = '.cmd') then
  begin
    Result := 'ANSI';
  end;

  // 可以根据需要添加更多的文件类型提示
end;

function TEncodingDetector.DetectBOMEncoding(const Stream: TStream; out BOMLength: Integer): string;
var
  BOMBytes: TBytes;
  OriginalPosition: Int64;
begin
  Result := '';
  BOMLength := 0;

  // 保存原始位置
  OriginalPosition := Stream.Position;

  try
    // 读取可能的BOM
    SetLength(BOMBytes, 4);
    Stream.Position := 0;
    Stream.ReadBuffer(BOMBytes[0], 4);

    // 检查UTF-8 BOM (EF BB BF)
    if (BOMBytes[0] = $EF) and (BOMBytes[1] = $BB) and (BOMBytes[2] = $BF) then
    begin
      Result := 'UTF-8 with BOM';
      BOMLength := 3;
    end
    // 检查UTF-16LE BOM (FF FE)
    else if (BOMBytes[0] = $FF) and (BOMBytes[1] = $FE) and (BOMBytes[2] <> $00) then
    begin
      Result := 'UTF-16LE';
      BOMLength := 2;
    end
    // 检查UTF-16BE BOM (FE FF)
    else if (BOMBytes[0] = $FE) and (BOMBytes[1] = $FF) then
    begin
      Result := 'UTF-16BE';
      BOMLength := 2;
    end
    // 检查UTF-32LE BOM (FF FE 00 00)
    else if (BOMBytes[0] = $FF) and (BOMBytes[1] = $FE) and (BOMBytes[2] = $00) and (BOMBytes[3] = $00) then
    begin
      Result := 'UTF-32LE';
      BOMLength := 4;
    end
    // 检查UTF-32BE BOM (00 00 FE FF)
    else if (BOMBytes[0] = $00) and (BOMBytes[1] = $00) and (BOMBytes[2] = $FE) and (BOMBytes[3] = $FF) then
    begin
      Result := 'UTF-32BE';
      BOMLength := 4;
    end;
  finally
    // 恢复原始位置
    Stream.Position := OriginalPosition;
  end;
end;

function TEncodingDetector.DetectUTF8Encoding(const Buffer: TBytes; Size: Integer; out Stats: TEncodingStats): Boolean;
var
  i: Integer;
  ConsecutiveValidSeq: Integer;
begin
  // 初始化统计信息
  FillChar(Stats, SizeOf(Stats), 0);
  Stats.TotalBytes := Size;
  ConsecutiveValidSeq := 0;
  i := 0;

  while i < Size do
  begin
    if Buffer[i] < $80 then
    begin
      // ASCII字符
      Inc(Stats.ASCIICount);
      Inc(Stats.ValidSequences);
      Inc(ConsecutiveValidSeq);
      Inc(i);
    end
    else if Buffer[i] < $C0 then
    begin
      // 无效的UTF-8序列
      Inc(Stats.NonASCIICount);
      Inc(Stats.InvalidSequences);
      ConsecutiveValidSeq := 0;
      Inc(i);
    end
    else if Buffer[i] < $E0 then
    begin
      // 2字节序列
      Inc(Stats.NonASCIICount);
      if (i + 1 < Size) and ((Buffer[i+1] and $C0) = $80) then
      begin
        Inc(Stats.ValidSequences);
        Inc(ConsecutiveValidSeq);
        Inc(i, 2);
      end
      else
      begin
        Inc(Stats.InvalidSequences);
        ConsecutiveValidSeq := 0;
        Inc(i);
      end;
    end
    else if Buffer[i] < $F0 then
    begin
      // 3字节序列 - 可能是中文、日文或韩文字符
      Inc(Stats.NonASCIICount);
      if (i + 2 < Size) and ((Buffer[i+1] and $C0) = $80) and ((Buffer[i+2] and $C0) = $80) then
      begin
        Inc(Stats.ValidSequences);
        Inc(ConsecutiveValidSeq);

        // 检测中文字符范围
        if (Buffer[i] >= $E4) and (Buffer[i] <= $E9) then
          Inc(Stats.ChineseChars)
        // 检测日文字符范围
        else if (Buffer[i] = $E3) and (Buffer[i+1] >= $81) and (Buffer[i+1] <= $83) then
          Inc(Stats.JapaneseChars)
        // 检测韩文字符范围
        else if (Buffer[i] = $EA) and (Buffer[i+1] >= $B0) and (Buffer[i+1] <= $BF) then
          Inc(Stats.KoreanChars);

        Inc(i, 3);
      end
      else
      begin
        Inc(Stats.InvalidSequences);
        ConsecutiveValidSeq := 0;
        Inc(i);
      end;
    end
    else if Buffer[i] < $F8 then
    begin
      // 4字节序列
      Inc(Stats.NonASCIICount);
      if (i + 3 < Size) and ((Buffer[i+1] and $C0) = $80) and
         ((Buffer[i+2] and $C0) = $80) and ((Buffer[i+3] and $C0) = $80) then
      begin
        Inc(Stats.ValidSequences);
        Inc(ConsecutiveValidSeq);
        Inc(i, 4);
      end
      else
      begin
        Inc(Stats.InvalidSequences);
        ConsecutiveValidSeq := 0;
        Inc(i);
      end;
    end
    else
    begin
      // 无效的UTF-8序列
      Inc(Stats.NonASCIICount);
      Inc(Stats.InvalidSequences);
      ConsecutiveValidSeq := 0;
      Inc(i);
    end;

    // 更新最长连续有效序列
    if ConsecutiveValidSeq > Stats.MaxConsecutiveValid then
      Stats.MaxConsecutiveValid := ConsecutiveValidSeq;
  end;

  // 判断是否为UTF-8编码的条件
  // 1. 如果没有非ASCII字符，则不能确定是UTF-8
  if Stats.NonASCIICount = 0 then
    Exit(False);

  // 2. 如果非ASCII字符很少，则需要更严格的判断
  if Stats.NonASCIICount < 5 then
    Exit(Stats.InvalidSequences = 0);

  // 3. 计算有效序列比例
  var ValidRatio: Double := 0;
  if Stats.NonASCIICount > 0 then
    ValidRatio := Stats.ValidSequences / Stats.NonASCIICount;

  // 4. 综合判断
  Result := (ValidRatio >= 0.8) or // 有效序列比例足够高
            ((ValidRatio >= 0.6) and (Stats.MaxConsecutiveValid >= 10)) or // 有连续长序列
            ((ValidRatio >= 0.6) and ((Stats.ChineseChars >= 3) or (Stats.JapaneseChars >= 3) or (Stats.KoreanChars >= 3))) or // 存在亚洲语言字符
            (Stats.ChineseChars >= 5) or // 存在多个中文字符
            (Stats.JapaneseChars >= 5) or // 存在多个日文字符
            (Stats.KoreanChars >= 5); // 存在多个韩文字符
end;

function TEncodingDetector.DetectGBKEncoding(const Buffer: TBytes; Size: Integer; out Stats: TEncodingStats): Boolean;
var
  i: Integer;
  GBKRatio: Double;
begin
  // 初始化统计信息
  FillChar(Stats, SizeOf(Stats), 0);
  Stats.TotalBytes := Size;
  i := 0;

  while i < Size do
  begin
    if Buffer[i] <= $7F then
    begin
      // ASCII范围
      Inc(Stats.ASCIICount);
      Inc(i);
    end
    else if (Buffer[i] >= $81) and (Buffer[i] <= $FE) and (i + 1 < Size) and
            (Buffer[i+1] >= $40) and (Buffer[i+1] <= $FE) and (Buffer[i+1] <> $7F) then
    begin
      // 标准GBK字符
      Inc(Stats.NonASCIICount);
      Inc(Stats.ValidSequences);
      Inc(Stats.ChineseChars);
      Inc(i, 2);
    end
    else
    begin
      // 不是有效的GBK
      Inc(Stats.NonASCIICount);
      Inc(Stats.InvalidSequences);
      Inc(i);
    end;
  end;

  // 计算GBK字符的比例
  if Stats.NonASCIICount > 0 then
    GBKRatio := Stats.ValidSequences / Stats.NonASCIICount
  else
    GBKRatio := 0;

  // 判断是否为GBK编码
  Result := (Stats.ChineseChars >= 3) and (GBKRatio >= 0.6);
end;

function TEncodingDetector.DetectBig5Encoding(const Buffer: TBytes; Size: Integer; out Stats: TEncodingStats): Boolean;
var
  i: Integer;
  Big5Ratio: Double;
begin
  // 初始化统计信息
  FillChar(Stats, SizeOf(Stats), 0);
  Stats.TotalBytes := Size;
  i := 0;

  while i < Size do
  begin
    if Buffer[i] <= $7F then
    begin
      // ASCII范围
      Inc(Stats.ASCIICount);
      Inc(i);
    end
    else if (Buffer[i] >= $A1) and (Buffer[i] <= $F9) and (i + 1 < Size) and
            (((Buffer[i+1] >= $40) and (Buffer[i+1] <= $7E)) or
             ((Buffer[i+1] >= $A1) and (Buffer[i+1] <= $FE))) then
    begin
      // 标准Big5字符
      Inc(Stats.NonASCIICount);
      Inc(Stats.ValidSequences);
      Inc(Stats.ChineseChars); // Big5主要用于繁体中文
      Inc(i, 2);
    end
    else
    begin
      // 不是有效的Big5
      Inc(Stats.NonASCIICount);
      Inc(Stats.InvalidSequences);
      Inc(i);
    end;
  end;

  // 计算Big5字符的比例
  if Stats.NonASCIICount > 0 then
    Big5Ratio := Stats.ValidSequences / Stats.NonASCIICount
  else
    Big5Ratio := 0;

  // 判断是否为Big5编码
  Result := (Stats.ChineseChars >= 3) and (Big5Ratio >= 0.6);
end;

function TEncodingDetector.DetectShiftJISEncoding(const Buffer: TBytes; Size: Integer; out Stats: TEncodingStats): Boolean;
var
  i: Integer;
  ShiftJISRatio: Double;
begin
  // 初始化统计信息
  FillChar(Stats, SizeOf(Stats), 0);
  Stats.TotalBytes := Size;
  i := 0;

  while i < Size do
  begin
    if Buffer[i] <= $7F then
    begin
      // ASCII范围
      Inc(Stats.ASCIICount);
      Inc(i);
    end
    else if (((Buffer[i] >= $81) and (Buffer[i] <= $9F)) or
             ((Buffer[i] >= $E0) and (Buffer[i] <= $FC))) and
            (i + 1 < Size) and
            ((Buffer[i+1] >= $40) and (Buffer[i+1] <= $FC) and
             (Buffer[i+1] <> $7F)) then
    begin
      // 标准Shift-JIS字符
      Inc(Stats.NonASCIICount);
      Inc(Stats.ValidSequences);
      Inc(Stats.JapaneseChars);
      Inc(i, 2);
    end
    else
    begin
      // 不是有效的Shift-JIS
      Inc(Stats.NonASCIICount);
      Inc(Stats.InvalidSequences);
      Inc(i);
    end;
  end;

  // 计算Shift-JIS字符的比例
  if Stats.NonASCIICount > 0 then
    ShiftJISRatio := Stats.ValidSequences / Stats.NonASCIICount
  else
    ShiftJISRatio := 0;

  // 判断是否为Shift-JIS编码
  Result := (Stats.JapaneseChars >= 3) and (ShiftJISRatio >= 0.6);
end;

function TEncodingDetector.DetectEUCJPEncoding(const Buffer: TBytes; Size: Integer; out Stats: TEncodingStats): Boolean;
var
  i: Integer;
  EUCJPRatio: Double;
begin
  // 初始化统计信息
  FillChar(Stats, SizeOf(Stats), 0);
  Stats.TotalBytes := Size;
  i := 0;

  while i < Size do
  begin
    if Buffer[i] <= $7F then
    begin
      // ASCII范围
      Inc(Stats.ASCIICount);
      Inc(i);
    end
    else if (Buffer[i] = $8E) and (i + 1 < Size) and
            (Buffer[i+1] >= $A1) and (Buffer[i+1] <= $DF) then
    begin
      // EUC-JP 半角片假名
      Inc(Stats.NonASCIICount);
      Inc(Stats.ValidSequences);
      Inc(Stats.JapaneseChars);
      Inc(i, 2);
    end
    else if (Buffer[i] = $8F) and (i + 2 < Size) and
            (Buffer[i+1] >= $A1) and (Buffer[i+1] <= $FE) and
            (Buffer[i+2] >= $A1) and (Buffer[i+2] <= $FE) then
    begin
      // EUC-JP 补充字符
      Inc(Stats.NonASCIICount);
      Inc(Stats.ValidSequences);
      Inc(Stats.JapaneseChars);
      Inc(i, 3);
    end
    else if (Buffer[i] >= $A1) and (Buffer[i] <= $FE) and
            (i + 1 < Size) and
            (Buffer[i+1] >= $A1) and (Buffer[i+1] <= $FE) then
    begin
      // EUC-JP 基本字符
      Inc(Stats.NonASCIICount);
      Inc(Stats.ValidSequences);
      Inc(Stats.JapaneseChars);
      Inc(i, 2);
    end
    else
    begin
      // 不是有效的EUC-JP
      Inc(Stats.NonASCIICount);
      Inc(Stats.InvalidSequences);
      Inc(i);
    end;
  end;

  // 计算EUC-JP字符的比例
  if Stats.NonASCIICount > 0 then
    EUCJPRatio := Stats.ValidSequences / Stats.NonASCIICount
  else
    EUCJPRatio := 0;

  // 判断是否为EUC-JP编码
  Result := (Stats.JapaneseChars >= 3) and (EUCJPRatio >= 0.6);
end;

function TEncodingDetector.DetectEUCKREncoding(const Buffer: TBytes; Size: Integer; out Stats: TEncodingStats): Boolean;
var
  i: Integer;
  EUCKRRatio: Double;
begin
  // 初始化统计信息
  FillChar(Stats, SizeOf(Stats), 0);
  Stats.TotalBytes := Size;
  i := 0;

  while i < Size do
  begin
    if Buffer[i] <= $7F then
    begin
      // ASCII范围
      Inc(Stats.ASCIICount);
      Inc(i);
    end
    else if (Buffer[i] >= $A1) and (Buffer[i] <= $FE) and
            (i + 1 < Size) and
            (Buffer[i+1] >= $A1) and (Buffer[i+1] <= $FE) then
    begin
      // 标准EUC-KR字符
      Inc(Stats.NonASCIICount);
      Inc(Stats.ValidSequences);
      Inc(Stats.KoreanChars);
      Inc(i, 2);
    end
    else
    begin
      // 不是有效的EUC-KR
      Inc(Stats.NonASCIICount);
      Inc(Stats.InvalidSequences);
      Inc(i);
    end;
  end;

  // 计算EUC-KR字符的比例
  if Stats.NonASCIICount > 0 then
    EUCKRRatio := Stats.ValidSequences / Stats.NonASCIICount
  else
    EUCKRRatio := 0;

  // 判断是否为EUC-KR编码
  Result := (Stats.KoreanChars >= 3) and (EUCKRRatio >= 0.6);
end;

function TEncodingDetector.HasBOM(const FileName: string): Boolean;
var
  Stream: TFileStream;
  BOMLength: Integer;
  EncodingName: string;
begin
  Result := False;

  if not FileExists(FileName) then
    Exit;

  try
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      EncodingName := DetectBOMEncoding(Stream, BOMLength);
      Result := BOMLength > 0;
    finally
      Stream.Free;
    end;
  except
    on E: Exception do
    begin
      FLastError := E.Message;
      Result := False;
    end;
  end;
end;

function TEncodingDetector.GetEncodingName(CodePage: Integer; HasBOM: Boolean): string;
begin
  case CodePage of
    0: Result := '未知';
    1200: Result := 'UTF-16LE';
    1201: Result := 'UTF-16BE';
    12000: Result := 'UTF-32LE';
    12001: Result := 'UTF-32BE';
    20127: Result := 'ASCII';
    28591: Result := 'ISO-8859-1';
    65000: Result := 'UTF-7';
    65001:
      begin
        if HasBOM then
          Result := 'UTF-8 with BOM'
        else
          Result := 'UTF-8';
      end;
    932: Result := 'Shift-JIS';
    936: Result := 'GBK';
    950: Result := 'Big5';
    949: Result := 'EUC-KR';
    51932: Result := 'EUC-JP';
    54936: Result := 'GB18030';
    else
      Result := Format('CP%d', [CodePage]);
  end;
end;

function TEncodingDetector.DetectFileEncoding(const FileName: string): TEncodingDetectResult;
var
  Stream: TFileStream;
  StopWatch: TStopwatch;
begin
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  Result.EncodingName := '未知';
  Result.Confidence := 0;
  Result.HasBOM := False;

  if not FileExists(FileName) then
  begin
    FLastError := '文件不存在: ' + FileName;
    Exit;
  end;

  // 开始计时
  StopWatch := TStopwatch.StartNew;

  try
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      Result := DetectStreamEncoding(Stream);

      // 添加文件扩展名提示
      Result.LanguageHint := GetEncodingHintByFileExt(FileName);

      // 如果检测结果不确定，但有文件扩展名提示，则使用提示
      if (Result.Confidence < 60) and (Result.LanguageHint <> '') then
      begin
        Result.EncodingName := Result.LanguageHint;
        Result.Confidence := 70;
        LogMessage(Format('基于文件扩展名提示使用编码: %s', [Result.EncodingName]));
      end;
    finally
      Stream.Free;
    end;
  except
    on E: Exception do
    begin
      FLastError := E.Message;
      LogMessage('检测文件编码时出错: ' + E.Message);
    end;
  end;

  // 停止计时并记录处理时间
  StopWatch.Stop;
  Result.ProcessTimeMs := StopWatch.ElapsedMilliseconds;

  if FPerformanceLog then
    LogMessage(Format('文件编码检测完成: %s, 耗时: %d ms', [FileName, Result.ProcessTimeMs]));
end;

function TEncodingDetector.DetectStreamEncoding(Stream: TStream): TEncodingDetectResult;
var
  Buffer: TBytes;
  BOMLength: Integer;
  BytesRead: Integer;
  SampleSize: Integer;
  UTF8Stats, GBKStats, Big5Stats, ShiftJISStats, EUCJPStats, EUCKRStats: TEncodingStats;
  UTF8Score, GBKScore, Big5Score, ShiftJISScore, EUCJPScore, EUCKRScore: Integer;
  IsUTF8, IsGBK, IsBig5, IsShiftJIS, IsEUCJP, IsEUCKR: Boolean;
begin
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  Result.EncodingName := '未知';
  Result.Confidence := 0;
  Result.HasBOM := False;

  // 检查流是否有效
  if (Stream = nil) or (Stream.Size = 0) then
  begin
    FLastError := '无效的流或空流';
    Exit;
  end;

  // 首先检测BOM
  Result.EncodingName := DetectBOMEncoding(Stream, BOMLength);
  if BOMLength > 0 then
  begin
    Result.HasBOM := True;
    Result.Confidence := 100; // BOM检测是100%可信的
    LogMessage(Format('检测到BOM: %s', [Result.EncodingName]));
    Exit;
  end;

  // 如果没有BOM，读取文件样本进行分析
  // 对于大文件，只读取前面的一部分进行分析
  SampleSize := Min(4096, Stream.Size);
  SetLength(Buffer, SampleSize);

  // 保存当前位置
  var OriginalPosition := Stream.Position;
  try
    // 从文件开头读取样本
    Stream.Position := 0;
    BytesRead := Stream.Read(Buffer[0], SampleSize);

    // 如果读取失败或读取的字节太少，无法进行分析
    if BytesRead < 10 then
    begin
      Result.EncodingName := 'ASCII'; // 假设是ASCII
      Result.Confidence := 50;
      Exit;
    end;

    // 检测各种编码
    IsUTF8 := DetectUTF8Encoding(Buffer, BytesRead, UTF8Stats);
    IsGBK := DetectGBKEncoding(Buffer, BytesRead, GBKStats);
    IsBig5 := DetectBig5Encoding(Buffer, BytesRead, Big5Stats);
    IsShiftJIS := DetectShiftJISEncoding(Buffer, BytesRead, ShiftJISStats);
    IsEUCJP := DetectEUCJPEncoding(Buffer, BytesRead, EUCJPStats);
    IsEUCKR := DetectEUCKREncoding(Buffer, BytesRead, EUCKRStats);

    // 记录统计信息
    if FPerformanceLog then
    begin
      LogStats('UTF-8', UTF8Stats);
      LogStats('GBK', GBKStats);
      LogStats('Big5', Big5Stats);
      LogStats('Shift-JIS', ShiftJISStats);
      LogStats('EUC-JP', EUCJPStats);
      LogStats('EUC-KR', EUCKRStats);
    end;

    // 计算各编码的得分
    UTF8Score := 0;
    GBKScore := 0;
    Big5Score := 0;
    ShiftJISScore := 0;
    EUCJPScore := 0;
    EUCKRScore := 0;

    // UTF-8得分计算
    if IsUTF8 then
    begin
      UTF8Score := 70; // 基础分

      // 根据有效序列比例增加分数
      if UTF8Stats.NonASCIICount > 0 then
      begin
        var ValidRatio := UTF8Stats.ValidSequences / UTF8Stats.NonASCIICount;
        if ValidRatio > 0.95 then
          Inc(UTF8Score, 20)
        else if ValidRatio > 0.9 then
          Inc(UTF8Score, 15)
        else if ValidRatio > 0.8 then
          Inc(UTF8Score, 10);
      end;

      // 根据连续有效序列长度增加分数
      if UTF8Stats.MaxConsecutiveValid > 20 then
        Inc(UTF8Score, 10)
      else if UTF8Stats.MaxConsecutiveValid > 10 then
        Inc(UTF8Score, 5);

      // 根据亚洲语言字符数量增加分数
      if (UTF8Stats.ChineseChars > 10) or (UTF8Stats.JapaneseChars > 10) or (UTF8Stats.KoreanChars > 10) then
        Inc(UTF8Score, 10)
      else if (UTF8Stats.ChineseChars > 5) or (UTF8Stats.JapaneseChars > 5) or (UTF8Stats.KoreanChars > 5) then
        Inc(UTF8Score, 5);
    end;

    // GBK得分计算
    if IsGBK then
    begin
      GBKScore := 70; // 基础分

      // 根据中文字符数量增加分数
      if GBKStats.ChineseChars > 20 then
        Inc(GBKScore, 20)
      else if GBKStats.ChineseChars > 10 then
        Inc(GBKScore, 15)
      else if GBKStats.ChineseChars > 5 then
        Inc(GBKScore, 10);

      // 根据有效序列比例增加分数
      if GBKStats.NonASCIICount > 0 then
      begin
        var ValidRatio := GBKStats.ValidSequences / GBKStats.NonASCIICount;
        if ValidRatio > 0.9 then
          Inc(GBKScore, 10)
        else if ValidRatio > 0.8 then
          Inc(GBKScore, 5);
      end;
    end;

    // Big5得分计算
    if IsBig5 then
    begin
      Big5Score := 70; // 基础分

      // 根据中文字符数量增加分数
      if Big5Stats.ChineseChars > 20 then
        Inc(Big5Score, 20)
      else if Big5Stats.ChineseChars > 10 then
        Inc(Big5Score, 15)
      else if Big5Stats.ChineseChars > 5 then
        Inc(Big5Score, 10);

      // 根据有效序列比例增加分数
      if Big5Stats.NonASCIICount > 0 then
      begin
        var ValidRatio := Big5Stats.ValidSequences / Big5Stats.NonASCIICount;
        if ValidRatio > 0.9 then
          Inc(Big5Score, 10)
        else if ValidRatio > 0.8 then
          Inc(Big5Score, 5);
      end;
    end;

    // Shift-JIS得分计算
    if IsShiftJIS then
    begin
      ShiftJISScore := 70; // 基础分

      // 根据日文字符数量增加分数
      if ShiftJISStats.JapaneseChars > 20 then
        Inc(ShiftJISScore, 20)
      else if ShiftJISStats.JapaneseChars > 10 then
        Inc(ShiftJISScore, 15)
      else if ShiftJISStats.JapaneseChars > 5 then
        Inc(ShiftJISScore, 10);

      // 根据有效序列比例增加分数
      if ShiftJISStats.NonASCIICount > 0 then
      begin
        var ValidRatio := ShiftJISStats.ValidSequences / ShiftJISStats.NonASCIICount;
        if ValidRatio > 0.9 then
          Inc(ShiftJISScore, 10)
        else if ValidRatio > 0.8 then
          Inc(ShiftJISScore, 5);
      end;
    end;

    // EUC-JP得分计算
    if IsEUCJP then
    begin
      EUCJPScore := 70; // 基础分

      // 根据日文字符数量增加分数
      if EUCJPStats.JapaneseChars > 20 then
        Inc(EUCJPScore, 20)
      else if EUCJPStats.JapaneseChars > 10 then
        Inc(EUCJPScore, 15)
      else if EUCJPStats.JapaneseChars > 5 then
        Inc(EUCJPScore, 10);

      // 根据有效序列比例增加分数
      if EUCJPStats.NonASCIICount > 0 then
      begin
        var ValidRatio := EUCJPStats.ValidSequences / EUCJPStats.NonASCIICount;
        if ValidRatio > 0.9 then
          Inc(EUCJPScore, 10)
        else if ValidRatio > 0.8 then
          Inc(EUCJPScore, 5);
      end;
    end;

    // EUC-KR得分计算
    if IsEUCKR then
    begin
      EUCKRScore := 70; // 基础分

      // 根据韩文字符数量增加分数
      if EUCKRStats.KoreanChars > 20 then
        Inc(EUCKRScore, 20)
      else if EUCKRStats.KoreanChars > 10 then
        Inc(EUCKRScore, 15)
      else if EUCKRStats.KoreanChars > 5 then
        Inc(EUCKRScore, 10);

      // 根据有效序列比例增加分数
      if EUCKRStats.NonASCIICount > 0 then
      begin
        var ValidRatio := EUCKRStats.ValidSequences / EUCKRStats.NonASCIICount;
        if ValidRatio > 0.9 then
          Inc(EUCKRScore, 10)
        else if ValidRatio > 0.8 then
          Inc(EUCKRScore, 5);
      end;
    end;

    // 如果全是ASCII字符，则判断为ASCII
    if (UTF8Stats.NonASCIICount = 0) and (BytesRead > 0) then
    begin
      Result.EncodingName := 'ASCII';
      Result.Confidence := 90;
      LogMessage('检测到纯ASCII文本');
      Exit;
    end;

    // 找出得分最高的编码
    var MaxScore := Max(Max(Max(UTF8Score, GBKScore), Max(Big5Score, ShiftJISScore)), Max(EUCJPScore, EUCKRScore));

    if MaxScore = 0 then
    begin
      // 如果所有编码得分都为0，则假设为ANSI
      Result.EncodingName := 'ANSI';
      Result.Confidence := 50;
    end
    else if MaxScore = UTF8Score then
    begin
      Result.EncodingName := 'UTF-8';
      Result.Confidence := UTF8Score;
    end
    else if MaxScore = GBKScore then
    begin
      Result.EncodingName := 'GBK';
      Result.Confidence := GBKScore;
    end
    else if MaxScore = Big5Score then
    begin
      Result.EncodingName := 'Big5';
      Result.Confidence := Big5Score;
    end
    else if MaxScore = ShiftJISScore then
    begin
      Result.EncodingName := 'Shift-JIS';
      Result.Confidence := ShiftJISScore;
    end
    else if MaxScore = EUCJPScore then
    begin
      Result.EncodingName := 'EUC-JP';
      Result.Confidence := EUCJPScore;
    end
    else if MaxScore = EUCKRScore then
    begin
      Result.EncodingName := 'EUC-KR';
      Result.Confidence := EUCKRScore;
    end;

    LogMessage(Format('检测到编码: %s, 置信度: %d%%', [Result.EncodingName, Result.Confidence]));
  finally
    // 恢复原始位置
    Stream.Position := OriginalPosition;
  end;
end;

function TEncodingDetector.DetectBufferEncoding(const Buffer: TBytes; Size: Integer): TEncodingDetectResult;
var
  MemStream: TMemoryStream;
begin
  // 使用内存流包装缓冲区，然后调用DetectStreamEncoding
  MemStream := TMemoryStream.Create;
  try
    if Size > 0 then
      MemStream.WriteBuffer(Buffer[0], Size);
    MemStream.Position := 0;
    Result := DetectStreamEncoding(MemStream);
  finally
    MemStream.Free;
  end;
end;

end.