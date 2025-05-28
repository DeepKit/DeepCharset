unit UtilsEncodingUTF8Improved;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.Hash;

type
  // UTF-8检测结果结构
  TUTF8DetectionResult = record
    IsUTF8: Boolean;        // 是否是UTF-8编码
    Confidence: Double;     // 置信度 (0.0-1.0)
    ValidSequences: Integer; // 有效的UTF-8序列数
    InvalidSequences: Integer; // 无效的UTF-8序列数
    TotalSequences: Integer;  // 总序列数
    NonASCIICount: Integer;   // 非ASCII字符数
    ChineseCharCount: Integer; // 中文字符数
    JapaneseCharCount: Integer; // 日文字符数
    KoreanCharCount: Integer;   // 韩文字符数
    MaxConsecutiveValidSeq: Integer; // 最长连续有效序列
    HasHighBit: Boolean;     // 是否包含高位字节
  end;

  // UTF-8检测选项
  TUTF8DetectionOptions = record
    MinConfidence: Double;   // 最小置信度 (默认0.7)
    MinNonASCIIChars: Integer; // 最小非ASCII字符数 (默认3)
    MinChineseChars: Integer;  // 最小中文字符数 (默认2)
    MinConsecutiveValidSeq: Integer; // 最小连续有效序列 (默认5)
    UseStatisticalAnalysis: Boolean; // 是否使用统计分析 (默认True)
    UseLanguageHeuristics: Boolean;  // 是否使用语言启发式 (默认True)
    UseFileExtensionHints: Boolean;  // 是否使用文件扩展名提示 (默认True)
  end;

// 高级UTF-8检测函数
function IsUTF8ImprovedValid(const Buffer: TBytes; Size: Integer): Boolean; overload;
function IsUTF8ImprovedValid(const Buffer: TBytes; Size: Integer; out DetectionResult: TUTF8DetectionResult): Boolean; overload;
function IsUTF8ImprovedValid(const Buffer: TBytes; Size: Integer; const Options: TUTF8DetectionOptions; out DetectionResult: TUTF8DetectionResult): Boolean; overload;

// 基于文件扩展名的UTF-8检测辅助函数
function IsUTF8PreferredForFileType(const FileExt: string): Boolean;

// 基于文件内容哈希的UTF-8检测缓存
function GetUTF8DetectionFromCache(const FileHash: string; out DetectionResult: TUTF8DetectionResult): Boolean;
procedure AddUTF8DetectionToCache(const FileHash: string; const DetectionResult: TUTF8DetectionResult);
procedure ClearUTF8DetectionCache;

// 计算文件内容的哈希值
function CalculateFileContentHash(const FileName: string): string; overload;
function CalculateFileContentHash(const Buffer: TBytes; Size: Integer): string; overload;

implementation

uses
  System.Generics.Collections, System.IOUtils;

var
  // UTF-8检测缓存
  UTF8DetectionCache: TDictionary<string, TUTF8DetectionResult>;

// 默认UTF-8检测选项
function GetDefaultUTF8DetectionOptions: TUTF8DetectionOptions;
begin
  Result.MinConfidence := 0.7;
  Result.MinNonASCIIChars := 3;
  Result.MinChineseChars := 2;
  Result.MinConsecutiveValidSeq := 5;
  Result.UseStatisticalAnalysis := True;
  Result.UseLanguageHeuristics := True;
  Result.UseFileExtensionHints := True;
end;

// 简化版UTF-8检测函数
function IsUTF8ImprovedValid(const Buffer: TBytes; Size: Integer): Boolean;
var
  DetectionResult: TUTF8DetectionResult;
begin
  Result := IsUTF8ImprovedValid(Buffer, Size, DetectionResult);
end;

// 带结果的UTF-8检测函数
function IsUTF8ImprovedValid(const Buffer: TBytes; Size: Integer; out DetectionResult: TUTF8DetectionResult): Boolean;
var
  Options: TUTF8DetectionOptions;
begin
  Options := GetDefaultUTF8DetectionOptions;
  Result := IsUTF8ImprovedValid(Buffer, Size, Options, DetectionResult);
end;

// 完整的UTF-8检测函数
function IsUTF8ImprovedValid(const Buffer: TBytes; Size: Integer; const Options: TUTF8DetectionOptions; out DetectionResult: TUTF8DetectionResult): Boolean;
var
  i, ValidSeqs, TotalSeqs, NonASCIICount, InvalidSeqs: Integer;
  UTF8Ratio: Double;
  ChineseCount, JapaneseCount, KoreanCount: Integer;
  ConsecutiveValidSeq, MaxConsecutiveValidSeq: Integer;
  HasChineseChars, HasJapaneseChars, HasKoreanChars: Boolean;
  HasHighBitFlag: Boolean;
begin
  // 初始化结果
  FillChar(DetectionResult, SizeOf(DetectionResult), 0);
  DetectionResult.IsUTF8 := False;
  DetectionResult.Confidence := 0.0;

  // 检查输入有效性
  if (Size <= 0) or (Length(Buffer) < Size) then
    Exit(False);

  // 初始化计数器
  ValidSeqs := 0;
  TotalSeqs := 0;
  NonASCIICount := 0;
  InvalidSeqs := 0;
  ChineseCount := 0;
  JapaneseCount := 0;
  KoreanCount := 0;
  ConsecutiveValidSeq := 0;
  MaxConsecutiveValidSeq := 0;
  HasChineseChars := False;
  HasJapaneseChars := False;
  HasKoreanChars := False;
  HasHighBitFlag := False;

  // 检查文件头部是否有中文字符
  if (Size >= 3) and
     ((Buffer[0] >= $E0) and (Buffer[0] <= $EF)) and
     ((Buffer[1] >= $80) and (Buffer[1] <= $BF)) and
     ((Buffer[2] >= $80) and (Buffer[2] <= $BF)) then
  begin
    HasHighBitFlag := True;
    Inc(NonASCIICount);
    HasChineseChars := True;
    Inc(ChineseCount);
  end;

  // 分析UTF-8序列
  i := 0;
  while i < Size do
  begin
    Inc(TotalSeqs);

    if Buffer[i] < $80 then
    begin
      // ASCII字符
      Inc(ValidSeqs);
      Inc(ConsecutiveValidSeq);
      Inc(i);
    end
    else if Buffer[i] < $C0 then
    begin
      // 无效的UTF-8序列
      Inc(i);
      HasHighBitFlag := True;
      Inc(NonASCIICount);
      Inc(InvalidSeqs);
      ConsecutiveValidSeq := 0;
    end
    else if Buffer[i] < $E0 then
    begin
      // 2字节序列
      HasHighBitFlag := True;
      Inc(NonASCIICount);
      if (i + 1 < Size) and ((Buffer[i+1] and $C0) = $80) then
      begin
        Inc(ValidSeqs);
        Inc(ConsecutiveValidSeq);
        Inc(i, 2);
      end
      else
      begin
        Inc(i);
        Inc(InvalidSeqs);
        ConsecutiveValidSeq := 0;
      end;
    end
    else if Buffer[i] < $F0 then
    begin
      // 3字节序列 - 可能是中文、日文或韩文字符
      HasHighBitFlag := True;
      Inc(NonASCIICount);
      if (i + 2 < Size) and
         ((Buffer[i+1] and $C0) = $80) and
         ((Buffer[i+2] and $C0) = $80) then
      begin
        Inc(ValidSeqs);
        Inc(ConsecutiveValidSeq);

        // 检测中文字符 (CJK统一汉字)
        if (Buffer[i] = $E4) and (Buffer[i+1] >= $B8) and (Buffer[i+1] <= $BF) or
           (Buffer[i] >= $E5) and (Buffer[i] <= $E9) and (Buffer[i+1] >= $80) and (Buffer[i+1] <= $BF) or
           (Buffer[i] = $EA) and (Buffer[i+1] >= $80) and (Buffer[i+1] < $A0) then
        begin
          Inc(ChineseCount);
          HasChineseChars := True;
        end
        // 检测日文字符 (平假名和片假名)
        else if (Buffer[i] = $E3) and
                (((Buffer[i+1] = $81) and (Buffer[i+2] >= $81) and (Buffer[i+2] <= $BF)) or
                 ((Buffer[i+1] = $82) and (Buffer[i+2] >= $80) and (Buffer[i+2] <= $9F)) or
                 ((Buffer[i+1] = $82) and (Buffer[i+2] >= $A0) and (Buffer[i+2] <= $BF)) or
                 ((Buffer[i+1] = $83) and (Buffer[i+2] >= $80) and (Buffer[i+2] <= $B6))) then
        begin
          Inc(JapaneseCount);
          HasJapaneseChars := True;
        end
        // 检测韩文字符 (谚文)
        else if (Buffer[i] = $EA) and (Buffer[i+1] >= $B0) and (Buffer[i+1] <= $BF) or
                (Buffer[i] = $EB) and (Buffer[i+1] >= $80) and (Buffer[i+1] <= $BF) or
                (Buffer[i] = $EC) and (Buffer[i+1] >= $80) and (Buffer[i+1] <= $BF) or
                (Buffer[i] = $ED) and (Buffer[i+1] >= $80) and (Buffer[i+1] < $A0) then
        begin
          Inc(KoreanCount);
          HasKoreanChars := True;
        end;

        Inc(i, 3);
      end
      else
      begin
        Inc(i);
        Inc(InvalidSeqs);
        ConsecutiveValidSeq := 0;
      end;
    end
    else if Buffer[i] < $F8 then
    begin
      // 4字节序列
      HasHighBitFlag := True;
      Inc(NonASCIICount);
      if (i + 3 < Size) and
         ((Buffer[i+1] and $C0) = $80) and
         ((Buffer[i+2] and $C0) = $80) and
         ((Buffer[i+3] and $C0) = $80) then
      begin
        Inc(ValidSeqs);
        Inc(ConsecutiveValidSeq);
        Inc(i, 4);
      end
      else
      begin
        Inc(i);
        Inc(InvalidSeqs);
        ConsecutiveValidSeq := 0;
      end;
    end
    else
    begin
      // 无效的UTF-8序列
      Inc(i);
      HasHighBitFlag := True;
      Inc(NonASCIICount);
      Inc(InvalidSeqs);
      ConsecutiveValidSeq := 0;
    end;

    // 记录最长的连续有效序列
    if ConsecutiveValidSeq > MaxConsecutiveValidSeq then
      MaxConsecutiveValidSeq := ConsecutiveValidSeq;
  end;

  // 填充结果结构
  DetectionResult.ValidSequences := ValidSeqs;
  DetectionResult.InvalidSequences := InvalidSeqs;
  DetectionResult.TotalSequences := TotalSeqs;
  DetectionResult.NonASCIICount := NonASCIICount;
  DetectionResult.ChineseCharCount := ChineseCount;
  DetectionResult.JapaneseCharCount := JapaneseCount;
  DetectionResult.KoreanCharCount := KoreanCount;
  DetectionResult.MaxConsecutiveValidSeq := MaxConsecutiveValidSeq;
  DetectionResult.HasHighBit := HasHighBitFlag;

  // 如果没有高位字节，则不能确定是UTF-8
  if not HasHighBitFlag then
  begin
    DetectionResult.IsUTF8 := False;
    DetectionResult.Confidence := 0.0;
    Exit(False);
  end;

  // 如果非ASCII字符很少，则不足以判断
  if NonASCIICount < Options.MinNonASCIIChars then
  begin
    DetectionResult.IsUTF8 := False;
    DetectionResult.Confidence := 0.0;
    Exit(False);
  end;

  // 计算有效UTF-8序列的比例
  if NonASCIICount > 0 then
    UTF8Ratio := ValidSeqs / NonASCIICount
  else
    UTF8Ratio := 0;

  // 计算置信度
  DetectionResult.Confidence := UTF8Ratio;

  // 如果有足够多的中文字符，提高置信度
  if ChineseCount >= Options.MinChineseChars then
    DetectionResult.Confidence := DetectionResult.Confidence + 0.1;

  // 如果有足够长的连续有效序列，提高置信度
  if MaxConsecutiveValidSeq >= Options.MinConsecutiveValidSeq then
    DetectionResult.Confidence := DetectionResult.Confidence + 0.1;

  // 确保置信度在0-1范围内
  DetectionResult.Confidence := Min(1.0, DetectionResult.Confidence);

  // 判断是否是UTF-8
  DetectionResult.IsUTF8 := (DetectionResult.Confidence >= Options.MinConfidence) or
                   (UTF8Ratio >= 0.8) or
                   ((UTF8Ratio >= 0.6) and (MaxConsecutiveValidSeq >= Options.MinConsecutiveValidSeq)) or
                   ((UTF8Ratio >= 0.6) and (HasChineseChars or HasJapaneseChars or HasKoreanChars)) or
                   (ChineseCount >= Options.MinChineseChars) or
                   (JapaneseCount >= Options.MinChineseChars) or
                   (KoreanCount >= Options.MinChineseChars);

  // 返回结果
  Exit(DetectionResult.IsUTF8);
end;

// 基于文件扩展名的UTF-8检测辅助函数
function IsUTF8PreferredForFileType(const FileExt: string): Boolean;
const
  UTF8PreferredExtensions: array[0..29] of string = (
    '.pas', '.dpr', '.dfm', '.cpp', '.h', '.hpp', '.cs', '.java', '.js',
    '.ts', '.py', '.rb', '.php', '.html', '.htm', '.xml', '.json', '.css',
    '.md', '.txt', '.ini', '.conf', '.config', '.properties', '.toml',
    '.yaml', '.yml', '.go', '.swift', '.rs'
  );
var
  LowerExt: string;
  i: Integer;
begin
  LowerExt := LowerCase(FileExt);

  for i := Low(UTF8PreferredExtensions) to High(UTF8PreferredExtensions) do
    if LowerExt = UTF8PreferredExtensions[i] then
      Exit(True);

  Result := False;
end;

// 计算文件内容的哈希值
function CalculateFileContentHash(const FileName: string): string;
var
  FileStream: TFileStream;
  Buffer: TBytes;
  FileSize: Int64;
  ReadSize: Integer;
begin
  Result := '';

  if not FileExists(FileName) then
    Exit;

  try
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      FileSize := FileStream.Size;

      // 只读取文件的前32KB用于哈希计算
      if FileSize > 32 * 1024 then
        ReadSize := 32 * 1024
      else
        ReadSize := Integer(FileSize);

      SetLength(Buffer, ReadSize);
      FileStream.Read(Buffer[0], ReadSize);

      Result := CalculateFileContentHash(Buffer, ReadSize);
    finally
      FileStream.Free;
    end;
  except
    // 忽略异常，返回空字符串
  end;
end;

// 计算缓冲区内容的哈希值
function CalculateFileContentHash(const Buffer: TBytes; Size: Integer): string;
var
  i: Integer;
  Hash: Cardinal;
begin
  // 使用简单的哈希算法
  Hash := 0;
  for i := 0 to Min(Size - 1, High(Buffer)) do
    Hash := ((Hash shl 5) or (Hash shr 27)) xor Buffer[i];
  Result := IntToHex(Hash, 8);
end;

// 从缓存中获取UTF-8检测结果
function GetUTF8DetectionFromCache(const FileHash: string; out DetectionResult: TUTF8DetectionResult): Boolean;
begin
  if not Assigned(UTF8DetectionCache) then
    Exit(False);

  Exit(UTF8DetectionCache.TryGetValue(FileHash, DetectionResult));
end;

// 添加UTF-8检测结果到缓存
procedure AddUTF8DetectionToCache(const FileHash: string; const DetectionResult: TUTF8DetectionResult);
begin
  if not Assigned(UTF8DetectionCache) then
    UTF8DetectionCache := TDictionary<string, TUTF8DetectionResult>.Create;

  // 如果缓存太大，清除一些条目
  if UTF8DetectionCache.Count > 1000 then
    ClearUTF8DetectionCache;

  // 添加或更新缓存
  if UTF8DetectionCache.ContainsKey(FileHash) then
    UTF8DetectionCache[FileHash] := DetectionResult
  else
    UTF8DetectionCache.Add(FileHash, DetectionResult);
end;

// 清除UTF-8检测缓存
procedure ClearUTF8DetectionCache;
begin
  if Assigned(UTF8DetectionCache) then
    UTF8DetectionCache.Clear;
end;

initialization
  UTF8DetectionCache := TDictionary<string, TUTF8DetectionResult>.Create;

finalization
  if Assigned(UTF8DetectionCache) then
    FreeAndNil(UTF8DetectionCache);

end.
