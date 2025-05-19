unit UtilsEncodingDetector_Improved;

interface

uses
  System.SysUtils, System.Classes, System.Math, Winapi.Windows,
  UtilsEncodingTypes, UtilsEncodingBOM_Improved, UtilsEncodingCache;

type
  /// <summary>
  /// 编码检测结果记录
  /// </summary>
  TEncodingDetectionResult = record
    Encoding: string;        // 检测到的编码名称
    HasBOM: Boolean;         // 是否有BOM
    Confidence: Double;      // 置信度 (0.0-1.0)
    DetectionMethod: string; // 检测方法
    ElapsedTime: Int64;      // 检测耗时(毫秒)
  end;

  /// <summary>
  /// 改进的编码检测器
  /// </summary>
  TEncodingDetector_Improved = class
  private
    class var FLogCallback: TProc<string>;

    /// <summary>
    /// 添加检测结果到缓存
    /// </summary>
    class procedure AddToCache(const FileName: string; const DetectionResult: TEncodingDetectionResult); static;

    /// <summary>
    /// 检测文件是否是UTF-8编码
    /// </summary>
    class function IsUTF8File(const Buffer: TBytes; Size: Integer; out Confidence: Double): Boolean;

    /// <summary>
    /// 检测文件是否是GBK编码
    /// </summary>
    class function IsGBKFile(const Buffer: TBytes; Size: Integer; out Confidence: Double): Boolean;

    /// <summary>
    /// 检测文件是否是Big5编码
    /// </summary>
    class function IsBig5File(const Buffer: TBytes; Size: Integer; out Confidence: Double): Boolean;

    /// <summary>
    /// 检测文件是否是Shift-JIS编码
    /// </summary>
    class function IsShiftJISFile(const Buffer: TBytes; Size: Integer; out Confidence: Double): Boolean;

    /// <summary>
    /// 检测文件是否是EUC-KR编码
    /// </summary>
    class function IsEUCKRFile(const Buffer: TBytes; Size: Integer; out Confidence: Double): Boolean;

    /// <summary>
    /// 检测文件是否是纯ASCII编码
    /// </summary>
    class function IsASCIIFile(const Buffer: TBytes; Size: Integer): Boolean;

    /// <summary>
    /// 根据文件扩展名判断可能的编码
    /// </summary>
    class function GetEncodingByFileExt(const FileExt: string): string;

    /// <summary>
    /// 根据系统语言环境判断可能的编码
    /// </summary>
    class function GetEncodingBySystemLanguage: string;

  public
    /// <summary>
    /// 设置日志回调函数
    /// </summary>
    class procedure SetLogCallback(const Callback: TProc<string>);

    /// <summary>
    /// 检测文件编码
    /// </summary>
    class function DetectFileEncoding(const FileName: string): TEncodingDetectionResult;

    /// <summary>
    /// 检测字节数组的编码
    /// </summary>
    class function DetectBufferEncoding(const Buffer: TBytes; Size: Integer; const FileExt: string = ''): TEncodingDetectionResult;
  end;

implementation

uses
  System.DateUtils, System.StrUtils;

{ TEncodingDetector_Improved }

class function TEncodingDetector_Improved.DetectBufferEncoding(const Buffer: TBytes; Size: Integer; const FileExt: string): TEncodingDetectionResult;
var
  BOMResult: TBOMDetectionResult;
  UTF8Confidence, GBKConfidence, Big5Confidence, ShiftJISConfidence, EUCKRConfidence: Double;
  StartTime: TDateTime;
begin
  StartTime := Now;

  // 初始化结果
  Result.Encoding := ENCODING_UNKNOWN;
  Result.HasBOM := False;
  Result.Confidence := 0.0;
  Result.DetectionMethod := '';
  Result.ElapsedTime := 0;

  // 检查缓冲区是否为空
  if (Size <= 0) or (Length(Buffer) = 0) then
    Exit;

  // 首先检测BOM
  BOMResult := TEncodingBOMDetector_Improved.DetectBOM(Buffer);

  // 如果检测到BOM，直接返回结果
  if BOMResult.BOMType <> bomNone then
  begin
    Result.Encoding := BOMResult.Encoding;
    Result.HasBOM := True;
    Result.Confidence := 1.0;
    Result.DetectionMethod := 'BOM检测';
    Result.ElapsedTime := MilliSecondsBetween(StartTime, Now);
    Exit;
  end;

  // 检查是否是纯ASCII文件
  if IsASCIIFile(Buffer, Size) then
  begin
    Result.Encoding := ENCODING_UTF8; // ASCII是UTF-8的子集
    Result.HasBOM := False;
    Result.Confidence := 1.0;
    Result.DetectionMethod := '纯ASCII';
    Result.ElapsedTime := MilliSecondsBetween(StartTime, Now);
    Exit;
  end;

  // 根据文件扩展名判断可能的编码
  if FileExt <> '' then
  begin
    var EncodingByExt := GetEncodingByFileExt(FileExt);
    if EncodingByExt <> ENCODING_UNKNOWN then
    begin
      Result.Encoding := EncodingByExt;
      Result.HasBOM := False;
      Result.Confidence := 0.9;
      Result.DetectionMethod := '文件类型判断';
      Result.ElapsedTime := MilliSecondsBetween(StartTime, Now);
      Exit;
    end;
  end;

  // 检测各种编码的可能性
  var IsUTF8 := IsUTF8File(Buffer, Size, UTF8Confidence);
  var IsGBK := IsGBKFile(Buffer, Size, GBKConfidence);
  var IsBig5 := IsBig5File(Buffer, Size, Big5Confidence);
  var IsShiftJIS := IsShiftJISFile(Buffer, Size, ShiftJISConfidence);
  var IsEUCKR := IsEUCKRFile(Buffer, Size, EUCKRConfidence);

  // 输出调试信息
  if Assigned(FLogCallback) then
  begin
    FLogCallback(Format('编码检测置信度: UTF8=%.2f, GBK=%.2f, Big5=%.2f, ShiftJIS=%.2f, EUCKR=%.2f',
      [UTF8Confidence, GBKConfidence, Big5Confidence, ShiftJISConfidence, EUCKRConfidence]));
  end;

  // 找出置信度最高的编码
  var MaxConfidence := Max(UTF8Confidence, Max(GBKConfidence, Max(Big5Confidence, Max(ShiftJISConfidence, EUCKRConfidence))));

  if MaxConfidence >= MIN_CONFIDENCE then
  begin
    if UTF8Confidence = MaxConfidence then
    begin
      Result.Encoding := ENCODING_UTF8;
      Result.Confidence := UTF8Confidence;
      Result.DetectionMethod := 'UTF-8检测';
    end
    else if GBKConfidence = MaxConfidence then
    begin
      Result.Encoding := ENCODING_GBK;
      Result.Confidence := GBKConfidence;
      Result.DetectionMethod := 'GBK检测';
    end
    else if Big5Confidence = MaxConfidence then
    begin
      Result.Encoding := ENCODING_BIG5;
      Result.Confidence := Big5Confidence;
      Result.DetectionMethod := 'Big5检测';
    end
    else if ShiftJISConfidence = MaxConfidence then
    begin
      Result.Encoding := ENCODING_SHIFT_JIS;
      Result.Confidence := ShiftJISConfidence;
      Result.DetectionMethod := '日文编码检测';
    end
    else if EUCKRConfidence = MaxConfidence then
    begin
      Result.Encoding := ENCODING_EUC_KR;
      Result.Confidence := EUCKRConfidence;
      Result.DetectionMethod := '韩文编码检测';
    end;
  end
  else
  begin
    // 如果所有编码的置信度都不够高，则根据系统语言环境判断
    Result.Encoding := GetEncodingBySystemLanguage;
    Result.Confidence := 0.5;
    Result.DetectionMethod := '系统语言判断';
  end;

  Result.HasBOM := False;
  Result.ElapsedTime := MilliSecondsBetween(StartTime, Now);
end;

class function TEncodingDetector_Improved.DetectFileEncoding(const FileName: string): TEncodingDetectionResult;
var
  FileStream: TFileStream;
  Buffer: TBytes;
  BytesRead: Integer;
  FileExt: string;
  StartTime: TDateTime;
  BOMResult: TBOMDetectionResult;
  FileSize: Int64;
  EndBuffer: TBytes;
  EndResult: TEncodingDetectionResult;
  IsBinaryFile: Boolean;
begin
  StartTime := Now;

  // 初始化结果
  Result.Encoding := ENCODING_UNKNOWN;
  Result.HasBOM := False;
  Result.Confidence := 0.0;
  Result.DetectionMethod := '';
  Result.ElapsedTime := 0;

  // 检查文件是否存在
  if not FileExists(FileName) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('文件不存在: ' + FileName);
    Exit;
  end;

  // 尝试从缓存中获取结果
  var CachedResult: TEncodingDetectionResult;
  if TEncodingCache.GetCacheItem(FileName, CachedResult) then
  begin
    Result := CachedResult;
    if Assigned(FLogCallback) then
      FLogCallback(Format('从缓存中获取文件 %s 的编码: %s (置信度: %.2f, 方法: %s)',
        [ExtractFileName(FileName), Result.Encoding, Result.Confidence, Result.DetectionMethod]));
    Exit;
  end;

  // 首先检查BOM（这是最快的检测方法）
  BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromFile(FileName);
  if BOMResult.BOMType <> bomNone then
  begin
    Result.Encoding := BOMResult.Encoding;
    Result.HasBOM := True;
    Result.Confidence := 1.0;
    Result.DetectionMethod := 'BOM检测';
    Result.ElapsedTime := MilliSecondsBetween(StartTime, Now);

    // 添加到缓存
    AddToCache(FileName, Result);

    if Assigned(FLogCallback) then
      FLogCallback(Format('通过BOM检测到文件 %s 的编码为: %s (耗时: %d ms)',
        [ExtractFileName(FileName), Result.Encoding, Result.ElapsedTime]));
    Exit;
  end;

  // 获取文件扩展名
  FileExt := LowerCase(ExtractFileExt(FileName));

  // 检查是否是二进制文件类型
  IsBinaryFile := False;

  // 使用常见二进制文件扩展名列表检查
  IsBinaryFile := (FileExt = '.exe') or (FileExt = '.dll') or (FileExt = '.obj') or
     (FileExt = '.bin') or (FileExt = '.o') or (FileExt = '.a') or
     (FileExt = '.so') or (FileExt = '.lib') or (FileExt = '.pdb') or
     (FileExt = '.com') or (FileExt = '.sys') or (FileExt = '.ocx') or
     // 图像文件
     (FileExt = '.ico') or (FileExt = '.bmp') or (FileExt = '.jpg') or
     (FileExt = '.jpeg') or (FileExt = '.png') or (FileExt = '.gif') or
     (FileExt = '.tif') or (FileExt = '.tiff') or (FileExt = '.webp') or
     (FileExt = '.svg') or (FileExt = '.psd') or (FileExt = '.ai') or
     // 压缩文件
     (FileExt = '.zip') or (FileExt = '.rar') or (FileExt = '.7z') or (FileExt = '.tar') or
     (FileExt = '.gz') or (FileExt = '.bz2') or (FileExt = '.xz') or (FileExt = '.cab') or
     // 文档文件
     (FileExt = '.pdf') or (FileExt = '.doc') or (FileExt = '.docx') or
     (FileExt = '.xls') or (FileExt = '.xlsx') or (FileExt = '.ppt') or
     (FileExt = '.pptx') or (FileExt = '.odt') or (FileExt = '.ods') or
     // 数据库文件
     (FileExt = '.db') or (FileExt = '.sqlite') or (FileExt = '.mdb') or
     (FileExt = '.accdb') or (FileExt = '.frm') or (FileExt = '.dbf') or
     // 音视频文件
     (FileExt = '.mp3') or (FileExt = '.mp4') or (FileExt = '.avi') or
     (FileExt = '.mov') or (FileExt = '.wmv') or (FileExt = '.flv') or
     (FileExt = '.wav') or (FileExt = '.ogg') or (FileExt = '.flac') or
     // Delphi特有的二进制文件
     (FileExt = '.dcu') or (FileExt = '.bpl') or (FileExt = '.dcp') or
     (FileExt = '.dcpil') or (FileExt = '.dcuil') or (FileExt = '.drc') or
     (FileExt = '.res') or (FileExt = '.rsm') or (FileExt = '.map') or
     (FileExt = '.tds') or (FileExt = '.jdbg') or (FileExt = '.dsk') or
     (FileExt = '.local') or (FileExt = '.identcache') or
     (FileExt = '.stat') or (FileExt = '.otares') or (FileExt = '.deployproj') or
     // 其他常见二进制文件
     (FileExt = '.class') or (FileExt = '.jar') or (FileExt = '.war') or
     (FileExt = '.pyc') or (FileExt = '.pyo') or (FileExt = '.swf') or
     (FileExt = '.fla') or (FileExt = '.ttf') or (FileExt = '.woff') or
     (FileExt = '.woff2') or (FileExt = '.eot');

  if IsBinaryFile then
  begin
    Result.Encoding := ENCODING_BINARY;
    Result.HasBOM := False;
    Result.Confidence := 1.0;
    Result.DetectionMethod := '二进制文件类型';
    Result.ElapsedTime := MilliSecondsBetween(StartTime, Now);

    // 添加到缓存
    AddToCache(FileName, Result);

    if Assigned(FLogCallback) then
      FLogCallback(Format('检测到文件 %s 的编码为: %s (%s) (耗时: %d ms)',
        [ExtractFileName(FileName), Result.Encoding, Result.DetectionMethod, Result.ElapsedTime]));
    Exit;
  end;

  try
    // 打开文件
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      // 获取文件大小
      FileSize := FileStream.Size;

      // 检查文件是否为空
      if FileSize = 0 then
      begin
        Result.Encoding := ENCODING_UNKNOWN;
        Result.HasBOM := False;
        Result.Confidence := 0.0;
        Result.DetectionMethod := '空文件';
        Result.ElapsedTime := MilliSecondsBetween(StartTime, Now);

        // 添加到缓存
        AddToCache(FileName, Result);

        if Assigned(FLogCallback) then
          FLogCallback('文件为空: ' + FileName);
        Exit;
      end;

      // 对于大文件，采用更高效的检测策略
      if FileSize > MAX_TEXT_SAMPLE * 2 then
      begin
        // 读取文件开头部分
        SetLength(Buffer, MAX_TEXT_SAMPLE);
        FileStream.Position := 0;
        BytesRead := FileStream.Read(Buffer[0], MAX_TEXT_SAMPLE);

        // 使用缓冲区检测编码
        Result := DetectBufferEncoding(Buffer, BytesRead, FileExt);

        // 如果置信度不高，再读取文件结尾部分进行检测
        if Result.Confidence < 0.8 then
        begin
          SetLength(EndBuffer, MAX_TEXT_SAMPLE);
          FileStream.Position := Max(0, FileSize - MAX_TEXT_SAMPLE);
          BytesRead := FileStream.Read(EndBuffer[0], MAX_TEXT_SAMPLE);

          EndResult := DetectBufferEncoding(EndBuffer, BytesRead, FileExt);

          // 如果结尾部分的置信度更高，使用结尾部分的结果
          if EndResult.Confidence > Result.Confidence then
            Result := EndResult;

          // 如果两次检测结果不同但置信度相近，优先选择UTF-8
          if (Result.Encoding <> EndResult.Encoding) and
             (Abs(Result.Confidence - EndResult.Confidence) < 0.2) then
          begin
            if (Result.Encoding = ENCODING_UTF8) or (EndResult.Encoding = ENCODING_UTF8) then
            begin
              Result.Encoding := ENCODING_UTF8;
              Result.Confidence := Max(Result.Confidence, EndResult.Confidence);
              Result.DetectionMethod := '综合检测';
            end;
          end;
        end;
      end
      else
      begin
        // 对于小文件，读取整个文件
        SetLength(Buffer, FileSize);
        FileStream.Position := 0;
        BytesRead := FileStream.Read(Buffer[0], FileSize);

        // 使用缓冲区检测编码
        Result := DetectBufferEncoding(Buffer, BytesRead, FileExt);
      end;

      // 更新耗时
      Result.ElapsedTime := MilliSecondsBetween(StartTime, Now);

      // 添加到缓存
      AddToCache(FileName, Result);

      // 记录日志
      if Assigned(FLogCallback) then
        FLogCallback(Format('检测到文件 %s 的编码为: %s (置信度: %.2f, 方法: %s, 耗时: %d ms)',
          [ExtractFileName(FileName), Result.Encoding, Result.Confidence, Result.DetectionMethod, Result.ElapsedTime]));
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      Result.Encoding := ENCODING_UNKNOWN;
      Result.HasBOM := False;
      Result.Confidence := 0.0;
      Result.DetectionMethod := '检测失败';
      Result.ElapsedTime := MilliSecondsBetween(StartTime, Now);

      if Assigned(FLogCallback) then
        FLogCallback(Format('检测文件编码失败: %s - %s', [FileName, E.Message]));
    end;
  end;
end;

class procedure TEncodingDetector_Improved.AddToCache(const FileName: string; const DetectionResult: TEncodingDetectionResult);
var
  CacheResult: UtilsEncodingTypes.TEncodingDetectionResult;
begin
  CacheResult.Encoding := DetectionResult.Encoding;
  CacheResult.HasBOM := DetectionResult.HasBOM;
  CacheResult.Confidence := DetectionResult.Confidence;
  CacheResult.DetectionMethod := DetectionResult.DetectionMethod;
  CacheResult.ElapsedTime := DetectionResult.ElapsedTime;
  TEncodingCache.AddCacheItem(FileName, CacheResult);
end;

class procedure TEncodingDetector_Improved.SetLogCallback(const Callback: TProc<string>);
begin
  FLogCallback := Callback;
end;

class function TEncodingDetector_Improved.GetEncodingByFileExt(const FileExt: string): string;
begin
  // 对于特定类型的文件，优先考虑UTF-8
  if (FileExt = '.pas') or (FileExt = '.dpr') or (FileExt = '.dfm') then
  begin
    Result := ENCODING_UTF8;
    Exit;
  end;

  // 其他常见编程语言源代码文件
  if (FileExt = '.cs') or (FileExt = '.java') or (FileExt = '.js') or
     (FileExt = '.ts') or (FileExt = '.py') or (FileExt = '.rb') or
     (FileExt = '.php') or (FileExt = '.go') or (FileExt = '.swift') or
     (FileExt = '.kt') or (FileExt = '.scala') or (FileExt = '.rs') or
     (FileExt = '.c') or (FileExt = '.cpp') or (FileExt = '.h') or
     (FileExt = '.hpp') or (FileExt = '.m') or (FileExt = '.mm') then
  begin
    Result := ENCODING_UTF8;
    Exit;
  end;

  // Web相关文件
  if (FileExt = '.html') or (FileExt = '.htm') or (FileExt = '.css') or
     (FileExt = '.xml') or (FileExt = '.json') or (FileExt = '.svg') or
     (FileExt = '.jsx') or (FileExt = '.tsx') or (FileExt = '.vue') or
     (FileExt = '.less') or (FileExt = '.scss') or (FileExt = '.sass') or
     (FileExt = '.yaml') or (FileExt = '.yml') then
  begin
    Result := ENCODING_UTF8;
    Exit;
  end;

  // 配置文件
  if (FileExt = '.ini') or (FileExt = '.conf') or (FileExt = '.config') or
     (FileExt = '.properties') or (FileExt = '.toml') or (FileExt = '.env') or
     (FileExt = '.cfg') or (FileExt = '.rc') or (FileExt = '.reg') then
  begin
    Result := ENCODING_UTF8;
    Exit;
  end;

  // 纯文本文件
  if (FileExt = '.txt') or (FileExt = '.log') or (FileExt = '.csv') or
     (FileExt = '.tsv') or (FileExt = '.md') or (FileExt = '.rst') or
     (FileExt = '.adoc') or (FileExt = '.asc') or (FileExt = '.text') then
  begin
    Result := ENCODING_UTF8;
    Exit;
  end;

  // 默认返回未知
  Result := ENCODING_UNKNOWN;
end;

class function TEncodingDetector_Improved.GetEncodingBySystemLanguage: string;
var
  LangID: Word; // LANGID is a Word
begin
  LangID := GetSystemDefaultLangID;

  // 根据系统语言环境判断
  if (LangID = $0804) or // 简体中文
     (LangID = $0404) or // 繁体中文
     (LangID = $0c04) then // 香港中文
    Result := ENCODING_GBK
  else if (LangID = $0411) then // 日文
    Result := ENCODING_SHIFT_JIS
  else if (LangID = $0412) then // 韩文
    Result := ENCODING_EUC_KR
  else
    Result := ENCODING_UTF8;
end;

class function TEncodingDetector_Improved.IsASCIIFile(const Buffer: TBytes; Size: Integer): Boolean;
var
  i: Integer;
begin
  Result := True;

  for i := 0 to Size - 1 do
  begin
    if Buffer[i] > 127 then
    begin
      Result := False;
      Exit;
    end;
  end;
end;

class function TEncodingDetector_Improved.IsUTF8File(const Buffer: TBytes; Size: Integer; out Confidence: Double): Boolean;
var
  i: Integer;
  ValidSequences, InvalidSequences: Integer;
  NonASCIICount: Integer;
  UTF8Ratio: Double;
  ChineseCharCount, JapaneseCharCount, KoreanCharCount: Integer;
  ConsecutiveValidSeq, MaxConsecutiveValidSeq: Integer;
  HasChineseChars, HasJapaneseChars, HasKoreanChars: Boolean;
  MaxSampleSize: Integer;
begin
  ValidSequences := 0;
  InvalidSequences := 0;
  NonASCIICount := 0;
  ChineseCharCount := 0;
  JapaneseCharCount := 0;
  KoreanCharCount := 0;
  ConsecutiveValidSeq := 0;
  MaxConsecutiveValidSeq := 0;
  HasChineseChars := False;
  HasJapaneseChars := False;
  HasKoreanChars := False;

  // 对于大文件，只检测前16KB的内容
  MaxSampleSize := Min(Size, MAX_TEXT_SAMPLE);

  i := 0;
  while i < MaxSampleSize do
  begin
    if Buffer[i] <= $7F then
    begin
      // ASCII范围
      Inc(i);
      Continue;
    end;

    Inc(NonASCIICount);

    // 检查UTF-8多字节序列
    if (Buffer[i] and $E0) = $C0 then // 2字节序列
    begin
      if (i + 1 < MaxSampleSize) and ((Buffer[i+1] and $C0) = $80) then
      begin
        Inc(ValidSequences);
        Inc(ConsecutiveValidSeq);

        // 检查是否是日文字符
        if (Buffer[i] = $E3) and (i + 2 < MaxSampleSize) and
           (Buffer[i+1] >= $81) and (Buffer[i+1] <= $8F) then
        begin
          Inc(JapaneseCharCount);
          HasJapaneseChars := True;
        end;

        Inc(i, 2);
      end
      else
      begin
        Inc(InvalidSequences);
        ConsecutiveValidSeq := 0;
        Inc(i);
      end;
    end
    else if (Buffer[i] and $F0) = $E0 then // 3字节序列
    begin
      if (i + 2 < MaxSampleSize) and
         ((Buffer[i+1] and $C0) = $80) and
         ((Buffer[i+2] and $C0) = $80) then
      begin
        Inc(ValidSequences);
        Inc(ConsecutiveValidSeq);

        // 检查是否是中文字符
        if (Buffer[i] >= $E4) and (Buffer[i] <= $E9) then
        begin
          Inc(ChineseCharCount);
          HasChineseChars := True;

          // 提前退出：如果已经找到足够多的中文字符，可以确定是UTF-8
          if ChineseCharCount >= 5 then
          begin
            Confidence := 0.9;
            Result := True;
            Exit;
          end;
        end
        // 检查是否是日文字符
        else if (Buffer[i] = $E3) and
                (Buffer[i+1] >= $80) and (Buffer[i+1] <= $BF) then
        begin
          Inc(JapaneseCharCount);
          HasJapaneseChars := True;

          // 提前退出：如果已经找到足够多的日文字符，可以确定是UTF-8
          if JapaneseCharCount >= 5 then
          begin
            Confidence := 0.9;
            Result := True;
            Exit;
          end;
        end
        // 检查是否是韩文字符
        else if (Buffer[i] = $EA) and
                (Buffer[i+1] >= $B0) and (Buffer[i+1] <= $BF) then
        begin
          Inc(KoreanCharCount);
          HasKoreanChars := True;

          // 提前退出：如果已经找到足够多的韩文字符，可以确定是UTF-8
          if KoreanCharCount >= 5 then
          begin
            Confidence := 0.9;
            Result := True;
            Exit;
          end;
        end;

        Inc(i, 3);
      end
      else
      begin
        Inc(InvalidSequences);
        ConsecutiveValidSeq := 0;
        Inc(i);
      end;
    end
    else if (Buffer[i] and $F8) = $F0 then // 4字节序列
    begin
      if (i + 3 < MaxSampleSize) and
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
        Inc(InvalidSequences);
        ConsecutiveValidSeq := 0;
        Inc(i);
      end;
    end
    else
    begin
      Inc(InvalidSequences);
      ConsecutiveValidSeq := 0;
      Inc(i);
    end;

    // 更新最长连续有效序列
    if ConsecutiveValidSeq > MaxConsecutiveValidSeq then
      MaxConsecutiveValidSeq := ConsecutiveValidSeq;

    // 提前退出：如果已经有足够长的连续有效序列，可以确定是UTF-8
    if (MaxConsecutiveValidSeq >= 10) and (ValidSequences > 20) then
    begin
      Confidence := 0.9;
      Result := True;
      Exit;
    end;

    // 提前退出：如果无效序列太多，可能不是UTF-8
    if (ValidSequences > 10) and (InvalidSequences > ValidSequences * 2) then
    begin
      Confidence := 0.1;
      Result := False;
      Exit;
    end;
  end;

  // 计算有效序列的比例
  if (ValidSequences + InvalidSequences) > 0 then
    UTF8Ratio := ValidSequences / (ValidSequences + InvalidSequences)
  else
    UTF8Ratio := 0;

  // 计算置信度
  if UTF8Ratio >= 0.9 then
    Confidence := 0.9
  else if (UTF8Ratio >= 0.7) and (MaxConsecutiveValidSeq >= 5) then
    Confidence := 0.8
  else if (UTF8Ratio >= 0.5) and (HasChineseChars or HasJapaneseChars or HasKoreanChars) then
    Confidence := 0.7
  else if ChineseCharCount >= 3 then
    Confidence := 0.6
  else if UTF8Ratio >= 0.5 then
    Confidence := 0.5
  else
    Confidence := UTF8Ratio;

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

class function TEncodingDetector_Improved.IsGBKFile(const Buffer: TBytes; Size: Integer; out Confidence: Double): Boolean;
var
  i: Integer;
  ValidCount, InvalidCount: Integer;
  ValidRatio: Double;
  ConsecutiveValidChars, MaxConsecutiveValidChars: Integer;
  IsFirstByteValid, IsSecondByteValid: Boolean;
begin
  ValidCount := 0;
  InvalidCount := 0;
  ConsecutiveValidChars := 0;
  MaxConsecutiveValidChars := 0;
  i := 0;

  while i < Size do
  begin
    if Buffer[i] <= $7F then
    begin
      // ASCII范围
      Inc(i);
      // 连续双字节字符计数重置
      ConsecutiveValidChars := 0;
      Continue;
    end;

    // 检查是否是有效的GBK字符
    IsFirstByteValid := (Buffer[i] >= $81) and (Buffer[i] <= $FE);

    if IsFirstByteValid and (i + 1 < Size) then
    begin
      IsSecondByteValid := (Buffer[i+1] >= $40) and (Buffer[i+1] <= $FE) and (Buffer[i+1] <> $7F);

      if IsSecondByteValid then
      begin
        Inc(ValidCount);
        Inc(ConsecutiveValidChars);
        Inc(i, 2);
      end
      else
      begin
        Inc(InvalidCount);
        ConsecutiveValidChars := 0;
        Inc(i);
      end;
    end
    else
    begin
      Inc(InvalidCount);
      ConsecutiveValidChars := 0;
      Inc(i);
    end;

    // 更新最长连续有效字符
    if ConsecutiveValidChars > MaxConsecutiveValidChars then
      MaxConsecutiveValidChars := ConsecutiveValidChars;
  end;

  // 计算有效字符比例
  if (ValidCount + InvalidCount) > 0 then
    ValidRatio := ValidCount / (ValidCount + InvalidCount)
  else
    ValidRatio := 0;

  // 计算置信度
  if ValidRatio >= 0.9 then
    Confidence := 0.9
  else if (ValidRatio >= 0.7) and (MaxConsecutiveValidChars >= 5) then
    Confidence := 0.8
  else if ValidRatio >= 0.5 then
    Confidence := 0.6
  else
    Confidence := ValidRatio;

  // 判断条件
  Result := (ValidRatio >= 0.5) or (MaxConsecutiveValidChars >= 10);
end;

class function TEncodingDetector_Improved.IsBig5File(const Buffer: TBytes; Size: Integer; out Confidence: Double): Boolean;
var
  i: Integer;
  ValidCount, InvalidCount: Integer;
  ValidRatio: Double;
  ConsecutiveValidChars, MaxConsecutiveValidChars: Integer;
  IsFirstByteValid, IsSecondByteValid: Boolean;
begin
  ValidCount := 0;
  InvalidCount := 0;
  ConsecutiveValidChars := 0;
  MaxConsecutiveValidChars := 0;
  i := 0;

  while i < Size do
  begin
    if Buffer[i] <= $7F then
    begin
      // ASCII范围
      Inc(i);
      // 连续双字节字符计数重置
      ConsecutiveValidChars := 0;
      Continue;
    end;

    // 检查是否是有效的Big5字符
    IsFirstByteValid := (Buffer[i] >= $A1) and (Buffer[i] <= $F9);

    if IsFirstByteValid and (i + 1 < Size) then
    begin
      IsSecondByteValid := ((Buffer[i+1] >= $40) and (Buffer[i+1] <= $7E)) or
                           ((Buffer[i+1] >= $A1) and (Buffer[i+1] <= $FE));

      if IsSecondByteValid then
      begin
        Inc(ValidCount);
        Inc(ConsecutiveValidChars);
        Inc(i, 2);
      end
      else
      begin
        Inc(InvalidCount);
        ConsecutiveValidChars := 0;
        Inc(i);
      end;
    end
    else
    begin
      Inc(InvalidCount);
      ConsecutiveValidChars := 0;
      Inc(i);
    end;

    // 更新最长连续有效字符
    if ConsecutiveValidChars > MaxConsecutiveValidChars then
      MaxConsecutiveValidChars := ConsecutiveValidChars;
  end;

  // 计算有效字符比例
  if (ValidCount + InvalidCount) > 0 then
    ValidRatio := ValidCount / (ValidCount + InvalidCount)
  else
    ValidRatio := 0;

  // 计算置信度
  if ValidRatio >= 0.9 then
    Confidence := 0.9
  else if (ValidRatio >= 0.7) and (MaxConsecutiveValidChars >= 5) then
    Confidence := 0.8
  else if ValidRatio >= 0.5 then
    Confidence := 0.6
  else
    Confidence := ValidRatio;

  // 判断条件
  Result := (ValidRatio >= 0.5) or (MaxConsecutiveValidChars >= 10);
end;

class function TEncodingDetector_Improved.IsShiftJISFile(const Buffer: TBytes; Size: Integer; out Confidence: Double): Boolean;
var
  i: Integer;
  ValidCount, InvalidCount: Integer;
  ValidRatio: Double;
  ConsecutiveValidChars, MaxConsecutiveValidChars: Integer;
  IsFirstByteValid, IsSecondByteValid: Boolean;
begin
  ValidCount := 0;
  InvalidCount := 0;
  ConsecutiveValidChars := 0;
  MaxConsecutiveValidChars := 0;
  i := 0;

  while i < Size do
  begin
    if Buffer[i] <= $7F then
    begin
      // ASCII范围
      Inc(i);
      // 连续双字节字符计数重置
      ConsecutiveValidChars := 0;
      Continue;
    end;

    // 检查是否是有效的Shift-JIS字符
    IsFirstByteValid := ((Buffer[i] >= $81) and (Buffer[i] <= $9F)) or
                        ((Buffer[i] >= $E0) and (Buffer[i] <= $FC));

    if IsFirstByteValid and (i + 1 < Size) then
    begin
      IsSecondByteValid := ((Buffer[i+1] >= $40) and (Buffer[i+1] <= $7E)) or
                           ((Buffer[i+1] >= $80) and (Buffer[i+1] <= $FC));

      if IsSecondByteValid then
      begin
        Inc(ValidCount);
        Inc(ConsecutiveValidChars);
        Inc(i, 2);
      end
      else
      begin
        Inc(InvalidCount);
        ConsecutiveValidChars := 0;
        Inc(i);
      end;
    end
    else
    begin
      // 检查是否是半角片假名（Shift-JIS特有）
      if (Buffer[i] >= $A1) and (Buffer[i] <= $DF) then
      begin
        Inc(ValidCount);
        Inc(ConsecutiveValidChars);
      end
      else
      begin
        Inc(InvalidCount);
        ConsecutiveValidChars := 0;
      end;
      Inc(i);
    end;

    // 更新最长连续有效字符
    if ConsecutiveValidChars > MaxConsecutiveValidChars then
      MaxConsecutiveValidChars := ConsecutiveValidChars;
  end;

  // 计算有效字符比例
  if (ValidCount + InvalidCount) > 0 then
    ValidRatio := ValidCount / (ValidCount + InvalidCount)
  else
    ValidRatio := 0;

  // 计算置信度
  if ValidRatio >= 0.9 then
    Confidence := 0.9
  else if (ValidRatio >= 0.7) and (MaxConsecutiveValidChars >= 5) then
    Confidence := 0.8
  else if ValidRatio >= 0.5 then
    Confidence := 0.6
  else
    Confidence := ValidRatio;

  // 判断条件
  Result := (ValidRatio >= 0.5) or (MaxConsecutiveValidChars >= 10);
end;

class function TEncodingDetector_Improved.IsEUCKRFile(const Buffer: TBytes; Size: Integer; out Confidence: Double): Boolean;
var
  i: Integer;
  ValidCount, InvalidCount: Integer;
  ValidRatio: Double;
  ConsecutiveValidChars, MaxConsecutiveValidChars: Integer;
  IsFirstByteValid, IsSecondByteValid: Boolean;
begin
  ValidCount := 0;
  InvalidCount := 0;
  ConsecutiveValidChars := 0;
  MaxConsecutiveValidChars := 0;
  i := 0;

  while i < Size do
  begin
    if Buffer[i] <= $7F then
    begin
      // ASCII范围
      Inc(i);
      // 连续双字节字符计数重置
      ConsecutiveValidChars := 0;
      Continue;
    end;

    // 检查是否是有效的EUC-KR字符
    IsFirstByteValid := (Buffer[i] >= $A1) and (Buffer[i] <= $FE);

    if IsFirstByteValid and (i + 1 < Size) then
    begin
      IsSecondByteValid := (Buffer[i+1] >= $A1) and (Buffer[i+1] <= $FE);

      if IsSecondByteValid then
      begin
        Inc(ValidCount);
        Inc(ConsecutiveValidChars);
        Inc(i, 2);
      end
      else
      begin
        Inc(InvalidCount);
        ConsecutiveValidChars := 0;
        Inc(i);
      end;
    end
    else
    begin
      Inc(InvalidCount);
      ConsecutiveValidChars := 0;
      Inc(i);
    end;

    // 更新最长连续有效字符
    if ConsecutiveValidChars > MaxConsecutiveValidChars then
      MaxConsecutiveValidChars := ConsecutiveValidChars;
  end;

  // 计算有效字符比例
  if (ValidCount + InvalidCount) > 0 then
    ValidRatio := ValidCount / (ValidCount + InvalidCount)
  else
    ValidRatio := 0;

  // 计算置信度
  if ValidRatio >= 0.9 then
    Confidence := 0.9
  else if (ValidRatio >= 0.7) and (MaxConsecutiveValidChars >= 5) then
    Confidence := 0.8
  else if ValidRatio >= 0.5 then
    Confidence := 0.6
  else
    Confidence := ValidRatio;

  // 判断条件
  Result := (ValidRatio >= 0.5) or (MaxConsecutiveValidChars >= 10);
end;

end.
