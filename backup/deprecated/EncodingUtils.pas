unit EncodingUtils;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Math, System.Character,
  System.StrUtils, System.Diagnostics, System.Generics.Collections, Winapi.Windows;

type
  /// <summary>
  /// 编码检测结果
  /// </summary>
  TEncodingDetectionResult = record
    Encoding: TEncoding;
    Name: string;
    Confidence: Double;
    HasBOM: Boolean;
    BOMSize: Integer;
  end;

  /// <summary>
  /// 编码统计信息
  /// </summary>
  TEncodingStats = record
    TotalBytes: Integer;
    ASCIIBytes: Integer;
    ValidBytes: Integer;
    InvalidBytes: Integer;
    ProcessingTime: Int64; // 处理时间（毫秒）
    MaxConsecutiveValidSeq: Integer; // 最长连续有效UTF-8序列
  end;

  /// <summary>
  /// 文件信息
  /// </summary>
  TFileInfo = record
    Size: Int64;
    ModifiedTime: TDateTime;
  end;

  /// <summary>
  /// 编码处理工具类
  /// </summary>
  TEncodingUtils = class
  private
    class var FLogCallback: TProc<string>;
    class var FEncodingCache: TDictionary<string, TEncodingDetectionResult>;
    class var FCacheEnabled: Boolean;

    /// <summary>
    /// 记录日志
    /// </summary>
    class procedure Log(const Msg: string); static;

    /// <summary>
    /// 检测UTF-8编码
    /// </summary>
    class function IsValidUTF8(const Buffer: TBytes; var Stats: TEncodingStats): Double; static;

    /// <summary>
    /// 检测ASCII编码
    /// </summary>
    class function IsASCII(const Buffer: TBytes): Double; static;

    /// <summary>
    /// 检测中文编码（GBK/GB2312）
    /// </summary>
    class function IsChineseEncoding(const Buffer: TBytes): Double; static;

    /// <summary>
    /// 检测日文编码（Shift-JIS）
    /// </summary>
    class function IsJapaneseEncoding(const Buffer: TBytes): Double; static;

    /// <summary>
    /// 检测韩文编码（EUC-KR）
    /// </summary>
    class function IsKoreanEncoding(const Buffer: TBytes): Double; static;

    /// <summary>
    /// 获取文件信息
    /// </summary>
    class function GetFileInfo(const FileName: string): TFileInfo; static;

    /// <summary>
    /// 获取系统语言环境
    /// </summary>
    class function GetSystemLanguage: string; static;

    /// <summary>
    /// 检测Big5编码
    /// </summary>
    class function IsBig5Encoding(const Buffer: TBytes): Double; static;

  public
    /// <summary>
    /// 设置日志回调
    /// </summary>
    class procedure SetLogCallback(ALogCallback: TProc<string>); static;

    /// <summary>
    /// 启用编码检测缓存
    /// </summary>
    class procedure EnableCache(Enable: Boolean = True); static;

    /// <summary>
    /// 清除编码检测缓存
    /// </summary>
    class procedure ClearCache; static;

    /// <summary>
    /// 比较两个编码对象是否相等
    /// </summary>
    class function AreEncodingsEqual(Encoding1, Encoding2: TEncoding): Boolean; static;

    /// <summary>
    /// 将编码对象转换为描述性字符串
    /// </summary>
    class function EncodingToString(Encoding: TEncoding): string; static;

    /// <summary>
    /// 从字符串解析编码对象
    /// </summary>
    class function StringToEncoding(const EncodingName: string): TEncoding; static;

    /// <summary>
    /// 获取编码的代码页
    /// </summary>
    class function GetCodePageFromEncoding(Encoding: TEncoding): Integer; static;

    /// <summary>
    /// 从代码页获取编码对象
    /// </summary>
    class function GetEncodingFromCodePage(CodePage: Integer): TEncoding; static;

    /// <summary>
    /// 获取编码的字节顺序标记(BOM)
    /// </summary>
    class function GetBOMBytes(Encoding: TEncoding): TBytes; static;

    /// <summary>
    /// 检查字节数组是否包含BOM
    /// </summary>
    class function HasBOM(const Bytes: TBytes): Boolean; overload; static;

    /// <summary>
    /// 检查字节数组是否包含BOM，并返回BOM大小
    /// </summary>
    class function HasBOM(const Bytes: TBytes; out BOMSize: Integer): Boolean; overload; static;

    /// <summary>
    /// 检查编码是否为Unicode编码
    /// </summary>
    class function IsUnicodeEncoding(Encoding: TEncoding): Boolean; static;

    /// <summary>
    /// 获取当前系统的ANSI编码
    /// </summary>
    class function GetAnsiEncoding: TEncoding; static;

    /// <summary>
    /// 通过BOM检测字节数组的编码
    /// </summary>
    class function DetectByteOrderMark(const Bytes: TBytes): TEncoding; static;

    /// <summary>
    /// 从文件中检测BOM并返回对应的编码
    /// </summary>
    class function DetectByteOrderMarkFromFile(const FileName: string): TEncoding; static;

    /// <summary>
    /// 从文件中删除BOM并写入目标文件
    /// </summary>
    class procedure StripByteOrderMark(const SourceFileName, TargetFileName: string); static;

    /// <summary>
    /// 向文件添加BOM
    /// </summary>
    class procedure AddByteOrderMark(const FileName: string; Encoding: TEncoding); static;

    /// <summary>
    /// 检测文件编码
    /// </summary>
    class function DetectFileEncoding(const FileName: string): TEncodingDetectionResult; static;

    /// <summary>
    /// 检测内存中的数据编码
    /// </summary>
    class function DetectBufferEncoding(const Buffer: TBytes): TEncodingDetectionResult; static;

    /// <summary>
    /// 检测流中的数据编码
    /// </summary>
    class function DetectStreamEncoding(Stream: TStream): TEncodingDetectionResult; static;

    /// <summary>
    /// 转换文件编码
    /// </summary>
    class function ConvertFileEncoding(const SourceFile, TargetFile: string;
      SourceEncoding, TargetEncoding: TEncoding; WithBOM: Boolean = False): Boolean; static;

    /// <summary>
    /// 添加BOM到字节数组
    /// </summary>
    class function AddBOMToBytes(const Buffer: TBytes; Encoding: TEncoding): TBytes; static;

    /// <summary>
    /// 从字节数组中移除BOM
    /// </summary>
    class function RemoveBOMFromBytes(const Buffer: TBytes; Encoding: TEncoding): TBytes; static;

    /// <summary>
    /// 获取编码名称
    /// </summary>
    class function GetEncodingName(Encoding: TEncoding): string; static;

    /// <summary>
    /// 获取编码代码页
    /// </summary>
    class function GetEncodingCodePage(const EncodingName: string): Integer; static;
  end;

implementation

{ TEncodingUtils }

class constructor TEncodingUtils.Create;
begin
  FCacheEnabled := False;
  FEncodingCache := nil;
end;

class destructor TEncodingUtils.Destroy;
begin
  if FEncodingCache <> nil then
    FreeAndNil(FEncodingCache);
end;

class procedure TEncodingUtils.SetLogCallback(ALogCallback: TProc<string>);
begin
  FLogCallback := ALogCallback;
end;

class procedure TEncodingUtils.EnableCache(Enable: Boolean);
begin
  FCacheEnabled := Enable;

  // 如果启用缓存但缓存字典尚未创建，则创建它
  if FCacheEnabled and (FEncodingCache = nil) then
    FEncodingCache := TDictionary<string, TEncodingDetectionResult>.Create;
end;

class procedure TEncodingUtils.ClearCache;
begin
  if FEncodingCache <> nil then
    FEncodingCache.Clear;
end;

class procedure TEncodingUtils.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

class procedure TEncodingUtils.AddByteOrderMark(const FileName: string; Encoding: TEncoding);
var
  SourceStream, TempStream: TFileStream;
  TempFileName: string;
  BOMBytes: TBytes;
  Buffer: TBytes;
  BytesRead: Integer;
begin
  if not FileExists(FileName) then
    Exit;

  BOMBytes := Encoding.GetPreamble;
  if Length(BOMBytes) = 0 then
    Exit; // 没有BOM可添加

  TempFileName := FileName + '.temp';

  SourceStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    TempStream := TFileStream.Create(TempFileName, fmCreate);
    try
      // 首先写入BOM
      TempStream.WriteBuffer(BOMBytes[0], Length(BOMBytes));

      // 复制原始文件内容
      SetLength(Buffer, 4096);
      repeat
        BytesRead := SourceStream.Read(Buffer[0], Length(Buffer));
        if BytesRead > 0 then
          TempStream.WriteBuffer(Buffer[0], BytesRead);
      until BytesRead = 0;
    finally
      TempStream.Free;
    end;
  finally
    SourceStream.Free;
  end;

  // 删除原始文件并重命名临时文件
  if FileExists(FileName) then
    DeleteFile(PChar(FileName));
  RenameFile(PChar(TempFileName), PChar(FileName));
end;

class function TEncodingUtils.AreEncodingsEqual(Encoding1, Encoding2: TEncoding): Boolean;
begin
  // 处理nil情况
  if (Encoding1 = nil) and (Encoding2 = nil) then
    Result := True
  else if (Encoding1 = nil) or (Encoding2 = nil) then
    Result := False
  else
    // 比较编码的代码页
    Result := Encoding1.CodePage = Encoding2.CodePage;
end;

class function TEncodingUtils.DetectByteOrderMark(const Bytes: TBytes): TEncoding;
var
  UTF8BOM, UTF16LEBOM, UTF16BEBOM: TBytes;
  i: Integer;
  Match: Boolean;
begin
  Result := nil;

  // 检查是否有足够的字节来检测BOM
  if Length(Bytes) = 0 then
    Exit;

  // 获取各种编码的BOM
  UTF8BOM := TEncoding.UTF8.GetPreamble;
  UTF16LEBOM := TEncoding.Unicode.GetPreamble;
  UTF16BEBOM := TEncoding.BigEndianUnicode.GetPreamble;

  // 检查UTF-8 BOM
  if Length(Bytes) >= Length(UTF8BOM) then
  begin
    Match := True;
    for i := 0 to Length(UTF8BOM) - 1 do
      if Bytes[i] <> UTF8BOM[i] then
      begin
        Match := False;
        Break;
      end;

    if Match then
    begin
      Result := TEncoding.UTF8;
      Exit;
    end;
  end;

  // 检查UTF-16LE BOM
  if Length(Bytes) >= Length(UTF16LEBOM) then
  begin
    Match := True;
    for i := 0 to Length(UTF16LEBOM) - 1 do
      if Bytes[i] <> UTF16LEBOM[i] then
      begin
        Match := False;
        Break;
      end;

    if Match then
    begin
      Result := TEncoding.Unicode;
      Exit;
    end;
  end;

  // 检查UTF-16BE BOM
  if Length(Bytes) >= Length(UTF16BEBOM) then
  begin
    Match := True;
    for i := 0 to Length(UTF16BEBOM) - 1 do
      if Bytes[i] <> UTF16BEBOM[i] then
      begin
        Match := False;
        Break;
      end;

    if Match then
    begin
      Result := TEncoding.BigEndianUnicode;
      Exit;
    end;
  end;
end;

class function TEncodingUtils.DetectByteOrderMarkFromFile(const FileName: string): TEncoding;
var
  Stream: TFileStream;
  Buffer: TBytes;
  BufferSize: Integer;
begin
  Result := nil;

  if not FileExists(FileName) then
    Exit;

  // 初始化缓冲区
  BufferSize := 4; // 足够检测所有BOM类型
  SetLength(Buffer, BufferSize);

  // 读取文件的前几个字节
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    if Stream.Size = 0 then
      Exit;

    if Stream.Size < BufferSize then
      BufferSize := Stream.Size;

    Stream.ReadBuffer(Buffer[0], BufferSize);
  finally
    Stream.Free;
  end;

  // 检测BOM
  Result := DetectByteOrderMark(Buffer);
end;

class function TEncodingUtils.EncodingToString(Encoding: TEncoding): string;
begin
  if Encoding = nil then
    Result := 'Unknown'
  else if Encoding = TEncoding.UTF8 then
    Result := 'UTF-8'
  else if Encoding = TEncoding.Unicode then
    Result := 'UTF-16LE'
  else if Encoding = TEncoding.BigEndianUnicode then
    Result := 'UTF-16BE'
  else if Encoding = TEncoding.ASCII then
    Result := 'ASCII'
  else if Encoding = TEncoding.Default then
    Result := 'Default'
  else
    Result := Format('CodePage %d', [Encoding.CodePage]);
end;

class function TEncodingUtils.GetAnsiEncoding: TEncoding;
begin
  // 返回当前系统的ANSI编码
  // 在Windows上，这通常是代码页为1252的西欧编码，但可能因系统区域设置而异
  Result := TEncoding.GetEncoding(GetACP);
end;

class function TEncodingUtils.GetBOMBytes(Encoding: TEncoding): TBytes;
begin
  if Encoding = nil then
    SetLength(Result, 0)
  else
    Result := Encoding.GetPreamble;
end;

class function TEncodingUtils.GetCodePageFromEncoding(Encoding: TEncoding): Integer;
begin
  if Encoding = nil then
    Result := 0
  else
    Result := Encoding.CodePage;
end;

class function TEncodingUtils.GetEncodingFromCodePage(CodePage: Integer): TEncoding;
begin
  Result := nil;

  // 处理常见的代码页
  case CodePage of
    0: Result := nil;
    20127: Result := TEncoding.ASCII;
    1200: Result := TEncoding.Unicode;
    1201: Result := TEncoding.BigEndianUnicode;
    65001: Result := TEncoding.UTF8;
    else
      try
        // 尝试获取指定代码页的编码
        Result := TEncoding.GetEncoding(CodePage);
      except
        // 无效的代码页
        Result := nil;
      end;
  end;
end;

class function TEncodingUtils.HasBOM(const Bytes: TBytes): Boolean;
begin
  Result := DetectByteOrderMark(Bytes) <> nil;
end;

class function TEncodingUtils.HasBOM(const Bytes: TBytes; out BOMSize: Integer): Boolean;
var
  Encoding: TEncoding;
begin
  Encoding := DetectByteOrderMark(Bytes);
  Result := Encoding <> nil;

  if Result then
    BOMSize := Length(Encoding.GetPreamble)
  else
    BOMSize := 0;
end;

class function TEncodingUtils.IsUnicodeEncoding(Encoding: TEncoding): Boolean;
begin
  Result := False;

  if Encoding = nil then
    Exit;

  // 检查是否为Unicode编码
  Result := (Encoding = TEncoding.UTF8) or
            (Encoding = TEncoding.Unicode) or
            (Encoding = TEncoding.BigEndianUnicode) or
            (Encoding.CodePage = 65001) or // UTF-8
            (Encoding.CodePage = 1200) or  // UTF-16LE
            (Encoding.CodePage = 1201);    // UTF-16BE
end;

class procedure TEncodingUtils.StripByteOrderMark(const SourceFileName, TargetFileName: string);
var
  SourceStream, TargetStream: TFileStream;
  SourceBytes: TBytes;
  SourceSize: Int64;
  BOMSize: Integer;
  Encoding: TEncoding;
begin
  if not FileExists(SourceFileName) then
    Exit;

  // 检测源文件的BOM
  Encoding := DetectByteOrderMarkFromFile(SourceFileName);

  if Encoding = nil then
  begin
    // 没有BOM，直接复制文件
    TFile.Copy(SourceFileName, TargetFileName, True);
    Exit;
  end;

  // 获取BOM大小
  BOMSize := Length(Encoding.GetPreamble);

  // 打开源文件
  SourceStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyWrite);
  try
    SourceSize := SourceStream.Size;

    // 如果文件太小，不处理
    if SourceSize <= BOMSize then
      Exit;

    // 创建目标文件
    TargetStream := TFileStream.Create(TargetFileName, fmCreate);
    try
      // 跳过BOM
      SourceStream.Position := BOMSize;

      // 读取剩余内容
      SetLength(SourceBytes, SourceSize - BOMSize);
      SourceStream.ReadBuffer(SourceBytes[0], Length(SourceBytes));

      // 写入目标文件
      TargetStream.WriteBuffer(SourceBytes[0], Length(SourceBytes));
    finally
      TargetStream.Free;
    end;
  finally
    SourceStream.Free;
  end;
end;

class function TEncodingUtils.StringToEncoding(const EncodingName: string): TEncoding;
begin
  Result := nil;

  // Unicode编码
  if EncodingName = 'UTF-8' then
    Result := TEncoding.UTF8
  else if (EncodingName = 'UTF-16LE') or (EncodingName = 'Unicode') then
    Result := TEncoding.Unicode
  else if (EncodingName = 'UTF-16BE') or (EncodingName = 'BigEndianUnicode') then
    Result := TEncoding.BigEndianUnicode
  else if EncodingName = 'UTF-32LE' then
    Result := TEncoding.GetEncoding(12000)
  else if EncodingName = 'UTF-32BE' then
    Result := TEncoding.GetEncoding(12001)
  else if EncodingName = 'UTF-7' then
    Result := TEncoding.GetEncoding(65000)

  // 基本编码
  else if EncodingName = 'ASCII' then
    Result := TEncoding.ASCII
  else if EncodingName = 'Default' then
    Result := TEncoding.Default
  else if EncodingName = 'ANSI' then
    Result := TEncoding.GetEncoding(GetACP)

  // 中文编码
  else if (EncodingName = 'GBK') or (EncodingName = 'GB2312') then
    Result := TEncoding.GetEncoding(936)
  else if EncodingName = 'Big5' then
    Result := TEncoding.GetEncoding(950)
  else if EncodingName = 'GB18030' then
    Result := TEncoding.GetEncoding(54936)
  else if EncodingName = 'BIG5_HKSCS' then
    Result := TEncoding.GetEncoding(950) // 使用Big5作为基础
  else if EncodingName = 'CP936' then
    Result := TEncoding.GetEncoding(936)
  else if EncodingName = 'CP950' then
    Result := TEncoding.GetEncoding(950)
  else if EncodingName = 'EUC_TW' then
    Result := TEncoding.GetEncoding(20000) // 尝试使用EUC-TW

  // 日文编码
  else if (EncodingName = 'Shift-JIS') or (EncodingName = 'SHIFT_JIS') then
    Result := TEncoding.GetEncoding(932)
  else if EncodingName = 'EUC_JP' then
    Result := TEncoding.GetEncoding(20932)
  else if EncodingName = 'CP932' then
    Result := TEncoding.GetEncoding(932)
  else if EncodingName = 'ISO_2022_JP' then
    Result := TEncoding.GetEncoding(50220)

  // 韩文编码
  else if (EncodingName = 'EUC_KR') or (EncodingName = 'EUC-KR') then
    Result := TEncoding.GetEncoding(949)
  else if EncodingName = 'CP949' then
    Result := TEncoding.GetEncoding(949)
  else if EncodingName = 'ISO_2022_KR' then
    Result := TEncoding.GetEncoding(50225)

  // Windows编码
  else if EncodingName = 'WINDOWS1250' then
    Result := TEncoding.GetEncoding(1250)
  else if EncodingName = 'WINDOWS1251' then
    Result := TEncoding.GetEncoding(1251)
  else if EncodingName = 'WINDOWS1252' then
    Result := TEncoding.GetEncoding(1252)
  else if EncodingName = 'WINDOWS1253' then
    Result := TEncoding.GetEncoding(1253)
  else if EncodingName = 'WINDOWS1254' then
    Result := TEncoding.GetEncoding(1254)
  else if EncodingName = 'WINDOWS1255' then
    Result := TEncoding.GetEncoding(1255)
  else if EncodingName = 'WINDOWS1256' then
    Result := TEncoding.GetEncoding(1256)
  else if EncodingName = 'WINDOWS1257' then
    Result := TEncoding.GetEncoding(1257)
  else if EncodingName = 'WINDOWS1258' then
    Result := TEncoding.GetEncoding(1258)

  // ISO编码
  else if EncodingName = 'ISO8859_1' then
    Result := TEncoding.GetEncoding(28591)
  else if EncodingName = 'ISO8859_2' then
    Result := TEncoding.GetEncoding(28592)
  else if EncodingName = 'ISO8859_3' then
    Result := TEncoding.GetEncoding(28593)
  else if EncodingName = 'ISO8859_4' then
    Result := TEncoding.GetEncoding(28594)
  else if EncodingName = 'ISO8859_5' then
    Result := TEncoding.GetEncoding(28595)
  else if EncodingName = 'ISO8859_6' then
    Result := TEncoding.GetEncoding(28596)
  else if EncodingName = 'ISO8859_7' then
    Result := TEncoding.GetEncoding(28597)
  else if EncodingName = 'ISO8859_8' then
    Result := TEncoding.GetEncoding(28598)
  else if EncodingName = 'ISO8859_9' then
    Result := TEncoding.GetEncoding(28599)
  else if EncodingName = 'ISO8859_10' then
    Result := TEncoding.GetEncoding(28600)
  else if EncodingName = 'ISO8859_11' then
    Result := TEncoding.GetEncoding(28601)
  else if EncodingName = 'ISO8859_13' then
    Result := TEncoding.GetEncoding(28603)
  else if EncodingName = 'ISO8859_14' then
    Result := TEncoding.GetEncoding(28604)
  else if EncodingName = 'ISO8859_15' then
    Result := TEncoding.GetEncoding(28605)
  else if EncodingName = 'ISO8859_16' then
    Result := TEncoding.GetEncoding(28606)
  else if EncodingName = 'ISO_8859_6_I' then
    Result := TEncoding.GetEncoding(28596) // 使用ISO8859_6作为基础

  // DOS/OEM编码
  else if EncodingName = 'IBM437' then
    Result := TEncoding.GetEncoding(437)
  else if EncodingName = 'IBM850' then
    Result := TEncoding.GetEncoding(850)
  else if EncodingName = 'IBM860' then
    Result := TEncoding.GetEncoding(860)
  else if EncodingName = 'IBM865' then
    Result := TEncoding.GetEncoding(865)
  else if EncodingName = 'CP862' then
    Result := TEncoding.GetEncoding(862)
  else if EncodingName = 'CP864' then
    Result := TEncoding.GetEncoding(864)

  // 其他区域编码
  else if EncodingName = 'KOI8R' then
    Result := TEncoding.GetEncoding(20866)
  else if EncodingName = 'KOI8U' then
    Result := TEncoding.GetEncoding(21866)
  else if EncodingName = 'MACROMAN' then
    Result := TEncoding.GetEncoding(10000)
  else if EncodingName = 'MACCYRILLIC' then
    Result := TEncoding.GetEncoding(10007)
  else if EncodingName = 'VISCII' then
    Result := TEncoding.GetEncoding(1258) // 使用Windows-1258作为替代
  else if EncodingName = 'TIS_620' then
    Result := TEncoding.GetEncoding(874)
  else if EncodingName = 'TSCII' then
    Result := TEncoding.GetEncoding(GetACP) // 使用系统默认编码作为替代
  else if EncodingName = 'ISCII' then
    Result := TEncoding.GetEncoding(GetACP) // 使用系统默认编码作为替代
  else if EncodingName = 'ARMSCII_8' then
    Result := TEncoding.GetEncoding(GetACP) // 使用系统默认编码作为替代
  else if EncodingName = 'CESU_8' then
    Result := TEncoding.UTF8 // 使用UTF-8作为替代

  // 代码页格式
  else if EncodingName.StartsWith('CodePage ') then
  begin
    // 尝试解析格式为"CodePage XXXXX"的字符串
    try
      Result := GetEncodingFromCodePage(StrToInt(Copy(EncodingName, 10, Length(EncodingName))));
    except
      Result := nil;
    end;
  end;

  // 如果找不到匹配的编码，尝试使用系统默认编码
  if Result = nil then
    Result := TEncoding.Default;
end;

class function TEncodingUtils.GetEncodingCodePage(const EncodingName: string): Integer;
begin
  var Encoding := StringToEncoding(EncodingName);
  if Encoding <> nil then
  begin
    Result := Encoding.CodePage;
    if (Result <> 1200) and (Result <> 1201) and (Result <> 65001) then
      Encoding.Free;
  end
  else
    Result := 0;
end;

class function TEncodingUtils.IsASCII(const Buffer: TBytes): Double;
var
  i, ASCIICount: Integer;
begin
  if Length(Buffer) = 0 then
    Exit(0);

  ASCIICount := 0;
  for i := 0 to Length(Buffer) - 1 do
    if Buffer[i] < 128 then
      Inc(ASCIICount);

  Result := ASCIICount / Length(Buffer);
end;

class function TEncodingUtils.IsValidUTF8(const Buffer: TBytes; var Stats: TEncodingStats): Double;
var
  i, ValidSequences, InvalidSequences, MultiByteSequences, ChineseSequences: Integer;
  JapaneseSequences, KoreanSequences: Integer;
  TotalBytes, BytesProcessed, ASCIICount: Integer;
  HasNonASCII, HasChineseChars, HasJapaneseChars, HasKoreanChars: Boolean;
  // 检查是否有特殊的UTF-8标记字符
  HasUTF8Markers: Boolean;
  // 连续有效UTF-8序列计数
  ConsecutiveValidSeq, MaxConsecutiveValidSeq: Integer;
  // 文件扩展名提示
  FileExtension: string;
  // 代码点值
  CodePoint: UInt32;
begin
  if Length(Buffer) = 0 then
    Exit(0);

  TotalBytes := Length(Buffer);
  BytesProcessed := 0;
  ValidSequences := 0;
  InvalidSequences := 0;
  MultiByteSequences := 0;
  ChineseSequences := 0; // 专门计数中文字符序列
  JapaneseSequences := 0; // 专门计数日文字符序列
  KoreanSequences := 0; // 专门计数韩文字符序列
  ASCIICount := 0;
  HasNonASCII := False;
  HasChineseChars := False;
  HasJapaneseChars := False;
  HasKoreanChars := False;
  HasUTF8Markers := False;
  ConsecutiveValidSeq := 0;
  MaxConsecutiveValidSeq := 0;
  FileExtension := '';

  // 检查文件内容中是否有UTF-8特有的标记
  // 例如：常见的UTF-8文件头部标记、XML声明、HTML文档类型等
  if TotalBytes > 20 then
  begin
    // 检查常见的UTF-8标记
    // 1. 检查XML声明
    if (TotalBytes > 5) and
       (Buffer[0] = Ord('<')) and (Buffer[1] = Ord('?')) and
       (Buffer[2] = Ord('x')) and (Buffer[3] = Ord('m')) and
       (Buffer[4] = Ord('l')) then
    begin
      HasUTF8Markers := True;
      Log('检测到XML声明，可能是UTF-8编码');
    end;

    // 2. 检查HTML文档类型
    if (TotalBytes > 9) and
       (Buffer[0] = Ord('<')) and (Buffer[1] = Ord('!')) and
       (Buffer[2] = Ord('D')) and (Buffer[3] = Ord('O')) and
       (Buffer[4] = Ord('C')) and (Buffer[5] = Ord('T')) and
       (Buffer[6] = Ord('Y')) and (Buffer[7] = Ord('P')) and
       (Buffer[8] = Ord('E')) then
    begin
      HasUTF8Markers := True;
      Log('检测到HTML DOCTYPE声明，可能是UTF-8编码');
    end;

    // 3. 检查Markdown标记
    if (TotalBytes > 2) and
       (Buffer[0] = Ord('#')) and (Buffer[1] = Ord(' ')) then
    begin
      HasUTF8Markers := True;
      FileExtension := '.md';
      Log('检测到Markdown标记，可能是UTF-8编码');
    end;

    // 4. 检查JSON标记
    if (TotalBytes > 2) and
       (Buffer[0] = Ord('{')) and (Buffer[1] = Ord('"')) then
    begin
      HasUTF8Markers := True;
      FileExtension := '.json';
      Log('检测到JSON标记，可能是UTF-8编码');
    end;

    // 5. 检查常见中文UTF-8标记
    if (TotalBytes > 10) then
    begin
      // 检查"我是"的UTF-8编码 (E6 88 91 E6 98 AF)
      for i := 0 to TotalBytes - 6 do
      begin
        if (Buffer[i] = $E6) and (Buffer[i+1] = $88) and (Buffer[i+2] = $91) and
           (Buffer[i+3] = $E6) and (Buffer[i+4] = $98) and (Buffer[i+5] = $AF) then
        begin
          HasUTF8Markers := True;
          HasChineseChars := True;
          Log('检测到中文UTF-8标记"我是"，可能是UTF-8编码');
          Break;
        end;
      end;
    end;
  end;

  i := 0;
  while i < TotalBytes do
  begin
    if Buffer[i] < $80 then
    begin
      // ASCII字符
      Inc(ValidSequences);
      Inc(ASCIICount);
      Inc(ConsecutiveValidSeq);
      Inc(i);
    end
    else if Buffer[i] < $C0 then
    begin
      // 无效的UTF-8序列（连续字节出现在首位）
      HasNonASCII := True;
      Inc(InvalidSequences);
      ConsecutiveValidSeq := 0;
      Inc(i);
    end
    else if (Buffer[i] and $E0) = $C0 then
    begin
      // 2字节序列
      HasNonASCII := True;
      if (i + 1 < TotalBytes) and ((Buffer[i + 1] and $C0) = $80) then
      begin
        // 检查过长编码 (Overlong Encoding)
        CodePoint := ((Buffer[i] and $1F) shl 6) or (Buffer[i + 1] and $3F);
        if CodePoint < $80 then
        begin
          // 过长编码，应该使用单字节表示
          Inc(InvalidSequences);
          ConsecutiveValidSeq := 0;
        end
        else
        begin
          Inc(ValidSequences);
          Inc(MultiByteSequences);
          Inc(ConsecutiveValidSeq);
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
    else if (Buffer[i] and $F0) = $E0 then
    begin
      // 3字节序列 - 可能是中文、日文或韩文字符
      HasNonASCII := True;
      if (i + 2 < TotalBytes) and
         ((Buffer[i + 1] and $C0) = $80) and
         ((Buffer[i + 2] and $C0) = $80) then
      begin
        // 计算Unicode码点
        CodePoint := ((Buffer[i] and $0F) shl 12) or
                     ((Buffer[i + 1] and $3F) shl 6) or
                     (Buffer[i + 2] and $3F);

        // 检查过长编码
        if CodePoint < $800 then
        begin
          // 过长编码，应该使用2字节表示
          Inc(InvalidSequences);
          ConsecutiveValidSeq := 0;
        end
        // 检查代理对范围 (U+D800-U+DFFF)，这在UTF-8中是不允许的
        else if (CodePoint >= $D800) and (CodePoint <= $DFFF) then
        begin
          Inc(InvalidSequences);
          ConsecutiveValidSeq := 0;
        end
        else
        begin
          // 检查是否是中文字符范围
          // 中文Unicode范围大致为：\u4E00-\u9FFF
          if (CodePoint >= $4E00) and (CodePoint <= $9FFF) then
          begin
            Inc(ChineseSequences);
            HasChineseChars := True;
          end
          // 检查是否是日文平假名/片假名范围
          // 日文平假名：\u3040-\u309F，片假名：\u30A0-\u30FF
          else if ((CodePoint >= $3040) and (CodePoint <= $309F)) or
                  ((CodePoint >= $30A0) and (CodePoint <= $30FF)) then
          begin
            Inc(JapaneseSequences);
            HasJapaneseChars := True;
          end
          // 检查是否是韩文范围
          // 韩文：\uAC00-\uD7AF
          else if (CodePoint >= $AC00) and (CodePoint <= $D7AF) then
          begin
            Inc(KoreanSequences);
            HasKoreanChars := True;
          end;

          Inc(ValidSequences);
          Inc(MultiByteSequences);
          Inc(ConsecutiveValidSeq);
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
    else if (Buffer[i] and $F8) = $F0 then
    begin
      // 4字节序列
      HasNonASCII := True;
      if (i + 3 < TotalBytes) and
         ((Buffer[i + 1] and $C0) = $80) and
         ((Buffer[i + 2] and $C0) = $80) and
         ((Buffer[i + 3] and $C0) = $80) then
      begin
        // 计算Unicode码点
        CodePoint := ((Buffer[i] and $07) shl 18) or
                     ((Buffer[i + 1] and $3F) shl 12) or
                     ((Buffer[i + 2] and $3F) shl 6) or
                     (Buffer[i + 3] and $3F);

        // 检查过长编码
        if CodePoint < $10000 then
        begin
          // 过长编码，应该使用3字节表示
          Inc(InvalidSequences);
          ConsecutiveValidSeq := 0;
        end
        // 检查超出Unicode范围的值 (> U+10FFFF)
        else if CodePoint > $10FFFF then
        begin
          Inc(InvalidSequences);
          ConsecutiveValidSeq := 0;
        end
        else
        begin
          Inc(ValidSequences);
          Inc(MultiByteSequences);
          Inc(ConsecutiveValidSeq);
        end;
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
      // 无效的UTF-8序列
      HasNonASCII := True;
      Inc(InvalidSequences);
      ConsecutiveValidSeq := 0;
      Inc(i);
    end;

    // 更新最长连续有效序列
    if ConsecutiveValidSeq > MaxConsecutiveValidSeq then
      MaxConsecutiveValidSeq := ConsecutiveValidSeq;

    // 如果已经检查了足够多的字节，并且有足够多的有效UTF-8序列，则提前返回
    if (i > 100) and (ValidSequences > 10) and (MultiByteSequences > 5) and (InvalidSequences = 0) then
    begin
      Log('提前返回：检测到足够多的有效UTF-8序列');
      Result := 0.98;

      // 更新统计信息
      Stats.TotalBytes := TotalBytes;
      Stats.ValidBytes := i;
      Stats.InvalidBytes := InvalidSequences;
      Stats.ASCIIBytes := ASCIICount;
      Stats.MaxConsecutiveValidSeq := MaxConsecutiveValidSeq;

      Exit;
    end;

    Inc(BytesProcessed);
  end;

  // 更新统计信息
  Stats.TotalBytes := TotalBytes;
  Stats.ValidBytes := BytesProcessed - InvalidSequences;
  Stats.InvalidBytes := InvalidSequences;
  Stats.ASCIIBytes := ASCIICount;
  Stats.MaxConsecutiveValidSeq := MaxConsecutiveValidSeq;

  // 计算置信度
  if (ValidSequences + InvalidSequences) > 0 then
    Result := ValidSequences / (ValidSequences + InvalidSequences)
  else
    Result := 0;

  // 如果没有高位字节，则不能确定是UTF-8
  if not HasNonASCII then
  begin
    // 如果有UTF-8标记，则更可能是UTF-8
    if HasUTF8Markers then
    begin
      Result := 0.9;
      Log('纯ASCII文件，但检测到UTF-8标记，置信度：' + FloatToStr(Result));
    end
    else if FileExtension = '.md' then
    begin
      Result := 0.85;
      Log('纯ASCII的Markdown文件，置信度：' + FloatToStr(Result));
    end
    else if FileExtension = '.json' then
    begin
      Result := 0.85;
      Log('纯ASCII的JSON文件，置信度：' + FloatToStr(Result));
    end
    else
    begin
      // 纯ASCII文件，默认为UTF-8的可能性较高，但不是100%
      Result := 0.8;
      Log('纯ASCII文件，置信度：' + FloatToStr(Result));
    end;
  end
  // 如果没有无效序列，则提高置信度
  else if InvalidSequences = 0 then
  begin
    // 如果有中文字符，几乎肯定是UTF-8
    if HasChineseChars and (ChineseSequences > 0) then
    begin
      Result := 0.98;
      Log('检测到中文UTF-8字符序列: ' + IntToStr(ChineseSequences) + '个，置信度：' + FloatToStr(Result));
    end
    // 如果有日文字符，几乎肯定是UTF-8
    else if HasJapaneseChars and (JapaneseSequences > 0) then
    begin
      Result := 0.95;
      Log('检测到日文UTF-8字符序列: ' + IntToStr(JapaneseSequences) + '个，置信度：' + FloatToStr(Result));
    end
    // 如果有韩文字符，几乎肯定是UTF-8
    else if HasKoreanChars and (KoreanSequences > 0) then
    begin
      Result := 0.95;
      Log('检测到韩文UTF-8字符序列: ' + IntToStr(KoreanSequences) + '个，置信度：' + FloatToStr(Result));
    end
    // 如果有多字节序列，则更可能是UTF-8
    else if MultiByteSequences > 0 then
    begin
      // 多字节序列越多，越可能是UTF-8
      if MultiByteSequences >= 5 then
        Result := 0.98
      else
        Result := 0.90 + (MultiByteSequences * 0.01);

      Log('检测到' + IntToStr(MultiByteSequences) + '个多字节UTF-8序列，置信度：' + FloatToStr(Result));
    end;
  end;

  // 如果有无效序列但比例很小，可能是UTF-8文件中混入了少量其他编码
  if (InvalidSequences > 0) and (InvalidSequences < TotalBytes div 50) and (MultiByteSequences > 5) then
  begin
    Result := Max(Result, 0.85);
    Log('检测到少量无效UTF-8序列，但多字节序列较多，置信度：' + FloatToStr(Result));
  end;

  // 对于纯ASCII文件，如果文件大小超过一定阈值，更可能是UTF-8
  if (not HasNonASCII) and (TotalBytes > 1024) and (ASCIICount > TotalBytes * 0.95) then
  begin
    Result := Max(Result, 0.8);
    Log('大型纯ASCII文件，置信度：' + FloatToStr(Result));
  end;

  // 对于.md文件特殊处理，因为它们通常是UTF-8
  if (FileExtension = '.md') and (MultiByteSequences > 0) and (Result > 0.7) then
  begin
    Result := Max(Result, 0.9);
    Log('Markdown文件，置信度提高到：' + FloatToStr(Result));
  end;

  // 如果是纯ASCII的.md文件，几乎肯定是UTF-8
  if (FileExtension = '.md') and (not HasNonASCII) and (ASCIICount > TotalBytes * 0.95) then
  begin
    Result := 0.95;
    Log('纯ASCII的Markdown文件，置信度：' + FloatToStr(Result));
  end;

  // 如果检测到中文字符，强烈倾向于UTF-8
  if HasChineseChars and (ChineseSequences > 0) then
  begin
    // 中文字符在UTF-8中是3字节序列，在GBK中是2字节序列
    // 如果检测到有效的UTF-8中文字符序列，几乎肯定是UTF-8
    Result := Max(Result, 0.95);
    Log('文件包含中文字符，更可能是UTF-8编码，置信度：' + FloatToStr(Result));
  end;

  // 如果最长连续有效序列足够长，提高置信度
  if MaxConsecutiveValidSeq >= 10 then
  begin
    Result := Max(Result, 0.9);
    Log('检测到长连续有效UTF-8序列：' + IntToStr(MaxConsecutiveValidSeq) + '，置信度：' + FloatToStr(Result));
  end
  else if MaxConsecutiveValidSeq >= 5 then
  begin
    Result := Max(Result, 0.85);
    Log('检测到中等长度连续有效UTF-8序列：' + IntToStr(MaxConsecutiveValidSeq) + '，置信度：' + FloatToStr(Result));
  end;

  // 输出详细的检测信息
  Log(Format('UTF-8检测结果：有效序列=%d，无效序列=%d，多字节序列=%d，中文=%d，日文=%d，韩文=%d，最长连续=%d，置信度=%.2f',
             [ValidSequences, InvalidSequences, MultiByteSequences, ChineseSequences,
              JapaneseSequences, KoreanSequences, MaxConsecutiveValidSeq, Result]));
end;

class function TEncodingUtils.IsChineseEncoding(const Buffer: TBytes): Double;
var
  i, ChineseCount, TotalCount: Integer;
begin
  if Length(Buffer) < 2 then
    Exit(0);

  ChineseCount := 0;
  TotalCount := 0;

  i := 0;
  while i < Length(Buffer) - 1 do
  begin
    // GBK/GB2312的特征：第一个字节在$81-$FE范围，第二个字节在$40-$FE范围
    if (Buffer[i] >= $81) and (Buffer[i] <= $FE) and
       (Buffer[i + 1] >= $40) and (Buffer[i + 1] <= $FE) then
    begin
      Inc(ChineseCount);
      Inc(i, 2);
    end
    else
      Inc(i);

    Inc(TotalCount);
  end;

  if TotalCount > 0 then
    Result := ChineseCount / TotalCount
  else
    Result := 0;

  // 如果中文字符比例较高，提高置信度
  if Result > 0.3 then
    Result := Result + 0.2;
end;

class function TEncodingUtils.IsBig5Encoding(const Buffer: TBytes): Double;
var
  i, Big5Count, TotalCount: Integer;
begin
  if Length(Buffer) < 2 then
    Exit(0);

  Big5Count := 0;
  TotalCount := 0;

  i := 0;
  while i < Length(Buffer) - 1 do
  begin
    // Big5的特征：第一个字节在$A1-$F9范围，第二个字节在$40-$FE范围
    if (Buffer[i] >= $A1) and (Buffer[i] <= $F9) and
       (Buffer[i + 1] >= $40) and (Buffer[i + 1] <= $FE) then
    begin
      Inc(Big5Count);
      Inc(i, 2);
    end
    else
      Inc(i);

    Inc(TotalCount);
  end;

  if TotalCount > 0 then
    Result := Big5Count / TotalCount
  else
    Result := 0;

  // 如果Big5字符比例较高，提高置信度
  if Result > 0.3 then
    Result := Result + 0.2;
end;

class function TEncodingUtils.IsJapaneseEncoding(const Buffer: TBytes): Double;
var
  i, JapaneseCount, TotalCount: Integer;
begin
  if Length(Buffer) < 2 then
    Exit(0);

  JapaneseCount := 0;
  TotalCount := 0;

  i := 0;
  while i < Length(Buffer) - 1 do
  begin
    // Shift-JIS的特征：第一个字节在$81-$9F或$E0-$FC范围，第二个字节在$40-$FC范围
    if ((Buffer[i] >= $81) and (Buffer[i] <= $9F) or
        (Buffer[i] >= $E0) and (Buffer[i] <= $FC)) and
       (Buffer[i + 1] >= $40) and (Buffer[i + 1] <= $FC) then
    begin
      Inc(JapaneseCount);
      Inc(i, 2);
    end
    else
      Inc(i);

    Inc(TotalCount);
  end;

  if TotalCount > 0 then
    Result := JapaneseCount / TotalCount
  else
    Result := 0;

  // 如果日文字符比例较高，提高置信度
  if Result > 0.3 then
    Result := Result + 0.2;
end;

class function TEncodingUtils.IsKoreanEncoding(const Buffer: TBytes): Double;
var
  i, KoreanCount, TotalCount: Integer;
begin
  if Length(Buffer) < 2 then
    Exit(0);

  KoreanCount := 0;
  TotalCount := 0;

  i := 0;
  while i < Length(Buffer) - 1 do
  begin
    // EUC-KR的特征：第一个字节在$A1-$FE范围，第二个字节在$A1-$FE范围
    if (Buffer[i] >= $A1) and (Buffer[i] <= $FE) and
       (Buffer[i + 1] >= $A1) and (Buffer[i + 1] <= $FE) then
    begin
      Inc(KoreanCount);
      Inc(i, 2);
    end
    else
      Inc(i);

    Inc(TotalCount);
  end;

  if TotalCount > 0 then
    Result := KoreanCount / TotalCount
  else
    Result := 0;

  // 如果韩文字符比例较高，提高置信度
  if Result > 0.3 then
    Result := Result + 0.2;
end;

class function TEncodingUtils.GetFileInfo(const FileName: string): TFileInfo;
var
  FileAttrs: TWin32FileAttributeData;
  FileTime: TFileTime;
  SystemTime: TSystemTime;
begin
  // 初始化结果
  Result.Size := 0;
  Result.ModifiedTime := 0;

  // 检查文件是否存在
  if not FileExists(FileName) then
    Exit;

  // 获取文件属性
  if GetFileAttributesEx(PChar(FileName), GetFileExInfoStandard, @FileAttrs) then
  begin
    // 获取文件大小
    Result.Size := Int64(FileAttrs.nFileSizeLow) or (Int64(FileAttrs.nFileSizeHigh) shl 32);

    // 获取文件修改时间
    FileTime := FileAttrs.ftLastWriteTime;
    FileTimeToSystemTime(FileTime, SystemTime);
    Result.ModifiedTime := SystemTimeToDateTime(SystemTime);
  end;
end;

class function TEncodingUtils.GetSystemLanguage: string;
var
  LangID: LANGID;
  LangCode: array[0..9] of Char;
begin
  // 获取系统默认语言ID
  LangID := GetUserDefaultLangID;

  // 获取语言代码
  GetLocaleInfo(LangID, LOCALE_SISO639LANGNAME, LangCode, Length(LangCode));
  Result := LangCode;

  // 记录日志
  Log('系统语言环境：' + Result);

  // 返回语言代码（如：en, zh, ja, ko等）
  Result := LowerCase(Result);
end;

class function TEncodingUtils.DetectBufferEncoding(const Buffer: TBytes): TEncodingDetectionResult;
var
  Stats: TEncodingStats;
  ASCIIScore, UTF8Score, ChineseScore, JapaneseScore, KoreanScore, Big5Score: Double;
  MaxScore: Double;
  ScoreArray: array of Double;
  EncodingArray: array of TEncoding;
  NameArray: array of string;
  i, MaxIndex: Integer;
  ASCIIRatio: Double;
  BOMSize: Integer;
  SystemLang: string;
begin
  // 初始化结果
  Result.Encoding := nil;
  Result.Name := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.BOMSize := 0;

  // 检查是否为空
  if Length(Buffer) = 0 then
  begin
    Result.Encoding := TEncoding.ASCII;
    Result.Name := 'ASCII';
    Result.Confidence := 1.0;
    Exit;
  end;

  // 首先检测BOM
  Result.HasBOM := HasBOM(Buffer, BOMSize);
  if Result.HasBOM then
  begin
    Result.Encoding := DetectByteOrderMark(Buffer);
    Result.Name := EncodingToString(Result.Encoding);
    Result.Confidence := 1.0;
    Result.BOMSize := BOMSize;
    Exit;
  end;

  // 检测ASCII
  ASCIIScore := IsASCII(Buffer);
  ASCIIRatio := ASCIIScore; // 保存ASCII比例，用于后续分析

  if ASCIIScore > 0.99 then
  begin
    Result.Encoding := TEncoding.ASCII;
    Result.Name := 'ASCII';
    Result.Confidence := ASCIIScore;
    Exit;
  end;

  // 检测UTF-8（无BOM）
  UTF8Score := IsValidUTF8(Buffer, Stats);

  // 检测中文编码
  ChineseScore := IsChineseEncoding(Buffer);

  // 检测日文编码
  JapaneseScore := IsJapaneseEncoding(Buffer);

  // 检测韩文编码
  KoreanScore := IsKoreanEncoding(Buffer);

  // 检测Big5编码
  Big5Score := IsBig5Encoding(Buffer);

  // 获取系统语言环境
  SystemLang := GetSystemLanguage;

  // 创建得分和编码数组
  SetLength(ScoreArray, 6);
  SetLength(EncodingArray, 6);
  SetLength(NameArray, 6);

  ScoreArray[0] := UTF8Score;
  EncodingArray[0] := TEncoding.UTF8;
  NameArray[0] := 'UTF-8';

  ScoreArray[1] := ChineseScore;
  EncodingArray[1] := TEncoding.GetEncoding(936); // GBK
  NameArray[1] := 'GBK';

  ScoreArray[2] := JapaneseScore;
  EncodingArray[2] := TEncoding.GetEncoding(932); // Shift-JIS
  NameArray[2] := 'Shift-JIS';

  ScoreArray[3] := KoreanScore;
  EncodingArray[3] := TEncoding.GetEncoding(949); // EUC-KR
  NameArray[3] := 'EUC-KR';

  ScoreArray[4] := Big5Score;
  EncodingArray[4] := TEncoding.GetEncoding(950); // Big5
  NameArray[4] := 'Big5';

  ScoreArray[5] := 0.3; // ANSI默认得分进一步降低，优先考虑其他编码
  EncodingArray[5] := TEncoding.Default;
  NameArray[5] := 'ANSI';

  // 根据系统语言环境调整得分
  if SystemLang = 'zh' then
  begin
    // 中文环境，提高中文编码得分
    ScoreArray[1] := ScoreArray[1] * 1.1; // GBK
    ScoreArray[4] := ScoreArray[4] * 1.1; // Big5
    Log('中文环境，提高中文编码得分');
  end
  else if SystemLang = 'ja' then
  begin
    // 日文环境，提高日文编码得分
    ScoreArray[2] := ScoreArray[2] * 1.1; // Shift-JIS
    Log('日文环境，提高日文编码得分');
  end
  else if SystemLang = 'ko' then
  begin
    // 韩文环境，提高韩文编码得分
    ScoreArray[3] := ScoreArray[3] * 1.1; // EUC-KR
    Log('韩文环境，提高韩文编码得分');
  end;

  // 找出得分最高的编码
  MaxScore := 0;
  MaxIndex := 0; // 默认为UTF-8，而不是ANSI

  for i := 0 to High(ScoreArray) do
  begin
    if ScoreArray[i] > MaxScore then
    begin
      MaxScore := ScoreArray[i];
      MaxIndex := i;
    end;
  end;

  // 特殊处理：如果ASCII比例很高，但不是纯ASCII，优先考虑UTF-8
  if (ASCIIRatio > 0.9) and (ASCIIRatio < 0.99) and (UTF8Score > 0.5) then
  begin
    Result.Encoding := TEncoding.UTF8;
    Result.Name := 'UTF-8';
    Result.Confidence := Max(UTF8Score, 0.8);
    Log('文件主要包含ASCII字符，优先考虑UTF-8编码');
  end
  // 特殊处理：如果UTF-8得分接近但不是最高，也优先考虑UTF-8
  else if (UTF8Score > 0.65) and (MaxScore - UTF8Score < 0.2) then
  begin
    Result.Encoding := TEncoding.UTF8;
    Result.Name := 'UTF-8';
    Result.Confidence := Max(UTF8Score, 0.75);
    Log('UTF-8得分接近最高得分，优先考虑UTF-8编码');
  end
  // 特殊处理：如果检测到中文字符，且UTF-8得分不低，优先考虑UTF-8
  else if (ChineseScore > 0.2) and (UTF8Score > 0.5) then
  begin
    Result.Encoding := TEncoding.UTF8;
    Result.Name := 'UTF-8';
    Result.Confidence := Max(UTF8Score, 0.85);
    Log('检测到中文字符，优先考虑UTF-8编码');
  end
  // 特殊处理：如果检测到日文或韩文字符，且UTF-8得分不低，优先考虑UTF-8
  else if ((JapaneseScore > 0.2) or (KoreanScore > 0.2)) and (UTF8Score > 0.5) then
  begin
    Result.Encoding := TEncoding.UTF8;
    Result.Name := 'UTF-8';
    Result.Confidence := Max(UTF8Score, 0.85);
    Log('检测到日文或韩文字符，优先考虑UTF-8编码');
  end
  // 特殊处理：如果最高得分不够高，且ASCII比例高，考虑使用UTF-8而非ANSI
  else if (MaxScore < 0.7) and (ASCIIRatio > 0.85) then
  begin
    Result.Encoding := TEncoding.UTF8;
    Result.Name := 'UTF-8';
    Result.Confidence := 0.8;
    Log('文件主要包含ASCII字符且无明确编码特征，默认使用UTF-8');
  end
  // 一般情况：使用得分最高的编码
  else if MaxScore > 0.6 then
  begin
    // 如果最高得分是ANSI，但UTF-8得分也不低，优先考虑UTF-8
    if (MaxIndex = 5) and (UTF8Score > 0.5) then
    begin
      Result.Encoding := TEncoding.UTF8;
      Result.Name := 'UTF-8';
      Result.Confidence := UTF8Score;
      Log('ANSI得分最高，但UTF-8得分也不低，优先考虑UTF-8编码');
    end
    else
    begin
      Result.Encoding := EncodingArray[MaxIndex];
      Result.Name := NameArray[MaxIndex];
      Result.Confidence := MaxScore;
    end;
  end
  else
  begin
    // 如果所有得分都不够高，默认使用UTF-8而非ANSI
    Result.Encoding := TEncoding.UTF8;
    Result.Name := 'UTF-8';
    Result.Confidence := 0.7; // 提高置信度
    Log('无法确定编码，默认使用UTF-8');
  end;

  // 对于混合编码文件的特殊处理
  if (Result.Confidence < 0.8) and (UTF8Score > 0.6) and (ASCIIRatio > 0.7) then
  begin
    // 如果置信度不高，但UTF-8得分和ASCII比例都较高，可能是混合编码文件
    // 优先使用UTF-8，因为它对ASCII兼容
    Result.Encoding := TEncoding.UTF8;
    Result.Name := 'UTF-8';
    Result.Confidence := Max(UTF8Score, 0.7);
  end
  // 对于中文和ASCII混合的文件
  else if (Result.Confidence < 0.8) and (ChineseScore > 0.3) and (ASCIIRatio > 0.6) then
  begin
    // 如果中文得分较高且ASCII比例也高，可能是中文和ASCII混合的文件
    // 优先使用GBK，因为它对ASCII兼容
    Result.Encoding := TEncoding.GetEncoding(936); // GBK
    Result.Name := 'GBK';
    Result.Confidence := Max(ChineseScore + 0.2, 0.7);
  end
  // 对于日文和ASCII混合的文件
  else if (Result.Confidence < 0.8) and (JapaneseScore > 0.3) and (ASCIIRatio > 0.6) then
  begin
    // 如果日文得分较高且ASCII比例也高，可能是日文和ASCII混合的文件
    // 优先使用Shift-JIS，因为它对ASCII兼容
    Result.Encoding := TEncoding.GetEncoding(932); // Shift-JIS
    Result.Name := 'Shift-JIS';
    Result.Confidence := Max(JapaneseScore + 0.2, 0.7);
  end
  // 对于韩文和ASCII混合的文件
  else if (Result.Confidence < 0.8) and (KoreanScore > 0.3) and (ASCIIRatio > 0.6) then
  begin
    // 如果韩文得分较高且ASCII比例也高，可能是韩文和ASCII混合的文件
    // 优先使用EUC-KR，因为它对ASCII兼容
    Result.Encoding := TEncoding.GetEncoding(949); // EUC-KR
    Result.Name := 'EUC-KR';
    Result.Confidence := Max(KoreanScore + 0.2, 0.7);
  end;
end;

class function TEncodingUtils.DetectFileEncoding(const FileName: string): TEncodingDetectionResult;
var
  FileStream: TFileStream;
  Buffer, SmallBuffer, LargeBuffer: TBytes;
  SampleSize, FileSize: Integer;
  SmallResult, LargeResult: TEncodingDetectionResult;
  FileExt: string;
  FileInfo: TFileInfo;
begin
  // 初始化结果
  Result.Encoding := nil;
  Result.Name := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.BOMSize := 0;

  // 检查缓存
  if FCacheEnabled and (FEncodingCache <> nil) then
  begin
    // 获取文件信息（大小和修改时间）
    FileInfo := GetFileInfo(FileName);

    // 创建缓存键（文件名+大小+修改时间）
    var CacheKey := FileName + '|' + IntToStr(FileInfo.Size) + '|' + DateTimeToStr(FileInfo.ModifiedTime);

    // 尝试从缓存中获取结果
    if FEncodingCache.TryGetValue(CacheKey, Result) then
    begin
      Log('从缓存中获取编码检测结果：' + Result.Name + '，置信度：' + FloatToStr(Result.Confidence));
      Exit;
    end;
  end;

  try
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      FileSize := FileStream.Size;

      // 对于非常小的文件，读取整个文件
      if FileSize <= 4096 then
      begin
        SampleSize := FileSize;
        SetLength(Buffer, SampleSize);
        if SampleSize > 0 then
          FileStream.ReadBuffer(Buffer[0], SampleSize);

        // 使用缓冲区检测编码
        Result := DetectBufferEncoding(Buffer);

        // 对于小文件，考虑文件扩展名作为额外的提示
        FileExt := LowerCase(ExtractFileExt(FileName));

        // 文本文件
        if (FileExt = '.txt') and (Result.Confidence < 0.8) then
        begin
          // 文本文件更可能是ANSI或UTF-8
          if Result.Encoding = TEncoding.Default then // ANSI
            Result.Confidence := Max(Result.Confidence, 0.7)
          else if Result.Encoding = TEncoding.UTF8 then // UTF-8
            Result.Confidence := Max(Result.Confidence, 0.7);
        end
        // Markdown文件
        else if (FileExt = '.md') then
        begin
          // Markdown文件几乎总是UTF-8
          if Result.Encoding = TEncoding.UTF8 then // 已检测为UTF-8
            Result.Confidence := Max(Result.Confidence, 0.98)
          else if Result.Confidence < 0.95 then
          begin
            // 如果检测结果不是UTF-8或置信度不高，强制使用UTF-8
            // 这是因为Markdown文件几乎总是UTF-8编码
            Result.Encoding := TEncoding.UTF8;
            Result.Name := 'UTF-8';
            Result.Confidence := 0.98;
            Log('文件扩展名为.md，强制使用UTF-8编码');
          end;
        end
        // XML和HTML文件
        else if (FileExt = '.xml') or (FileExt = '.html') or (FileExt = '.htm') or
                (FileExt = '.xhtml') or (FileExt = '.svg') or (FileExt = '.xsl') or
                (FileExt = '.xslt') or (FileExt = '.rss') or (FileExt = '.atom') then
        begin
          // XML和HTML文件更可能是UTF-8
          if Result.Encoding = TEncoding.UTF8 then // 已检测为UTF-8
            Result.Confidence := Max(Result.Confidence, 0.95)
          else if Result.Confidence < 0.9 then
          begin
            // 如果检测结果不是UTF-8或置信度不高，强制使用UTF-8
            // 这是因为XML和HTML文件通常是UTF-8编码
            Result.Encoding := TEncoding.UTF8;
            Result.Name := 'UTF-8';
            Result.Confidence := 0.9;
            Log('文件扩展名为XML或HTML相关，优先使用UTF-8编码');
          end;
        end
        // JSON文件
        else if (FileExt = '.json') or (FileExt = '.jsonld') or (FileExt = '.geojson') then
        begin
          // JSON文件通常是UTF-8
          if Result.Encoding = TEncoding.UTF8 then // 已检测为UTF-8
            Result.Confidence := Max(Result.Confidence, 0.95)
          else if Result.Confidence < 0.9 then
          begin
            // 如果检测结果不是UTF-8或置信度不高，强制使用UTF-8
            // 这是因为JSON文件几乎总是UTF-8编码
            Result.Encoding := TEncoding.UTF8;
            Result.Name := 'UTF-8';
            Result.Confidence := 0.95;
            Log('文件扩展名为JSON相关，强制使用UTF-8编码');
          end;
        end
        // JavaScript和CSS文件
        else if (FileExt = '.js') or (FileExt = '.css') or (FileExt = '.ts') or
                (FileExt = '.jsx') or (FileExt = '.tsx') or (FileExt = '.less') or
                (FileExt = '.scss') or (FileExt = '.sass') then
        begin
          // Web相关文件通常是UTF-8
          if Result.Encoding = TEncoding.UTF8 then // UTF-8
            Result.Confidence := Max(Result.Confidence, 0.8);
        end
        // 源代码文件
        else if (FileExt = '.c') or (FileExt = '.cpp') or (FileExt = '.h') or
                (FileExt = '.hpp') or (FileExt = '.cs') or (FileExt = '.java') or
                (FileExt = '.py') or (FileExt = '.rb') or (FileExt = '.php') or
                (FileExt = '.go') or (FileExt = '.swift') or (FileExt = '.rs') or
                (FileExt = '.pas') or (FileExt = '.dpr') then
        begin
          // 源代码文件通常是UTF-8或ANSI
          if Result.Encoding = TEncoding.UTF8 then // UTF-8
            Result.Confidence := Max(Result.Confidence, 0.75)
          else if Result.Encoding = TEncoding.Default then // ANSI
            Result.Confidence := Max(Result.Confidence, 0.7);
        end
        // 配置文件
        else if (FileExt = '.ini') or (FileExt = '.conf') or (FileExt = '.config') or
                (FileExt = '.properties') or (FileExt = '.yml') or (FileExt = '.yaml') or
                (FileExt = '.toml') then
        begin
          // 配置文件通常是UTF-8或ANSI
          if Result.Encoding = TEncoding.UTF8 then // UTF-8
            Result.Confidence := Max(Result.Confidence, 0.75)
          else if Result.Encoding = TEncoding.Default then // ANSI
            Result.Confidence := Max(Result.Confidence, 0.7);
        end
        // 中文相关文件
        else if (FileExt = '.chn') or (FileExt = '.cht') or (FileExt = '.gb') or
                (FileExt = '.big5') then
        begin
          // 中文相关文件可能是GBK或Big5
          if (Result.Name = 'GBK') or (Result.Name = 'GB2312') or (Result.Name = 'GB18030') then
            Result.Confidence := Max(Result.Confidence, 0.8)
          else if Result.Name = 'Big5' then
            Result.Confidence := Max(Result.Confidence, 0.8);
        end
        // 日文相关文件
        else if (FileExt = '.jpn') or (FileExt = '.sjis') then
        begin
          // 日文相关文件可能是Shift-JIS
          if Result.Name = 'Shift-JIS' then
            Result.Confidence := Max(Result.Confidence, 0.8);
        end
        // 韩文相关文件
        else if (FileExt = '.kor') or (FileExt = '.euc') then
        begin
          // 韩文相关文件可能是EUC-KR
          if Result.Name = 'EUC-KR' then
            Result.Confidence := Max(Result.Confidence, 0.8);
        end;
      end
      else
      begin
        // 对于大文件，使用两种采样策略

        // 1. 读取文件开头的4KB
        SetLength(SmallBuffer, Min(FileSize, 4096));
        if Length(SmallBuffer) > 0 then
        begin
          FileStream.Position := 0;
          FileStream.ReadBuffer(SmallBuffer[0], Length(SmallBuffer));
        end;

        // 2. 读取文件的多个部分，总计最多128KB
        SampleSize := Min(FileSize, 131072); // 128KB
        SetLength(LargeBuffer, SampleSize);

        if SampleSize > 0 then
        begin
          // 读取文件开头、中间和结尾的部分
          if FileSize <= SampleSize then
          begin
            // 如果文件小于采样大小，直接读取整个文件
            FileStream.Position := 0;
            FileStream.ReadBuffer(LargeBuffer[0], FileSize);
          end
          else
          begin
            // 读取文件开头的1/3采样
            FileStream.Position := 0;
            FileStream.ReadBuffer(LargeBuffer[0], SampleSize div 3);

            // 读取文件中间的1/3采样
            FileStream.Position := (FileSize - SampleSize div 3) div 2;
            FileStream.ReadBuffer(LargeBuffer[SampleSize div 3], SampleSize div 3);

            // 读取文件结尾的1/3采样
            FileStream.Position := FileSize - SampleSize div 3;
            FileStream.ReadBuffer(LargeBuffer[2 * (SampleSize div 3)], SampleSize div 3);
          end;
        end;

        // 分别检测两个样本
        SmallResult := DetectBufferEncoding(SmallBuffer);
        LargeResult := DetectBufferEncoding(LargeBuffer);

        // 如果两个结果一致，使用大样本的结果
        if AreEncodingsEqual(SmallResult.Encoding, LargeResult.Encoding) then
        begin
          Result := LargeResult;
          // 提高置信度
          Result.Confidence := Min(1.0, Result.Confidence + 0.1);
        end
        else
        begin
          // 如果结果不一致，可能是混合编码文件
          // 优先使用大样本的结果，但降低置信度
          Result := LargeResult;
          Result.Confidence := Max(0.5, Result.Confidence - 0.2);

          // 如果小样本检测到BOM，优先使用小样本结果
          if SmallResult.HasBOM then
          begin
            Result := SmallResult;
            Result.Confidence := 1.0; // BOM是确定的标志
          end
          // 如果小样本是UTF-8且置信度高，也优先使用小样本
          else if (SmallResult.Encoding = TEncoding.UTF8) and (SmallResult.Confidence > 0.9) then
          begin
            Result := SmallResult;
          end;
        end;
      end;
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      // 出错时使用默认编码
      Result.Encoding := TEncoding.Default;
      Result.Name := 'ANSI';
      Result.Confidence := 0;
      Log('检测文件编码时出错: ' + E.Message);
    end;
  end;

  // 将结果添加到缓存
  if FCacheEnabled and (FEncodingCache <> nil) and (Result.Confidence > 0) then
  begin
    // 获取文件信息（大小和修改时间）
    FileInfo := GetFileInfo(FileName);

    // 创建缓存键（文件名+大小+修改时间）
    var CacheKey := FileName + '|' + IntToStr(FileInfo.Size) + '|' + DateTimeToStr(FileInfo.ModifiedTime);

    // 添加到缓存
    FEncodingCache.AddOrSetValue(CacheKey, Result);
    Log('将编码检测结果添加到缓存：' + Result.Name + '，置信度：' + FloatToStr(Result.Confidence));
  end;
end;

class function TEncodingUtils.DetectStreamEncoding(Stream: TStream): TEncodingDetectionResult;
var
  Buffer: TBytes;
  SampleSize: Integer;
  OriginalPosition: Int64;
begin
  // 初始化结果
  Result.Encoding := nil;
  Result.Name := '';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.BOMSize := 0;

  try
    // 保存原始位置
    OriginalPosition := Stream.Position;

    // 读取流样本
    SampleSize := Min(Stream.Size - Stream.Position, 65536); // 最多读取64KB
    SetLength(Buffer, SampleSize);
    Stream.ReadBuffer(Buffer[0], SampleSize);

    // 检测编码
    Result := DetectBufferEncoding(Buffer);

    // 恢复原始位置
    Stream.Position := OriginalPosition;
  except
    on E: Exception do
    begin
      // 出错时使用默认编码
      Result.Encoding := TEncoding.Default;
      Result.Name := 'ANSI';
      Result.Confidence := 0;
      Log('检测流编码时出错: ' + E.Message);
    end;
  end;
end;

class function TEncodingUtils.AddBOMToBytes(const Buffer: TBytes; Encoding: TEncoding): TBytes;
var
  BOMBytes: TBytes;
begin
  if Encoding = nil then
  begin
    Result := Buffer;
    Exit;
  end;

  BOMBytes := Encoding.GetPreamble;
  if Length(BOMBytes) = 0 then
  begin
    Result := Buffer;
    Exit;
  end;

  SetLength(Result, Length(BOMBytes) + Length(Buffer));
  if Length(BOMBytes) > 0 then
    Move(BOMBytes[0], Result[0], Length(BOMBytes));
  if Length(Buffer) > 0 then
    Move(Buffer[0], Result[Length(BOMBytes)], Length(Buffer));
end;

class function TEncodingUtils.RemoveBOMFromBytes(const Buffer: TBytes; Encoding: TEncoding): TBytes;
var
  BOMBytes: TBytes;
  BOMLength: Integer;
begin
  if Encoding = nil then
  begin
    Result := Buffer;
    Exit;
  end;

  BOMBytes := Encoding.GetPreamble;
  BOMLength := Length(BOMBytes);
  if BOMLength = 0 then
  begin
    Result := Buffer;
    Exit;
  end;

  // 检查是否有BOM
  if (Length(Buffer) >= BOMLength) then
  begin
    var HasBOM := True;
    for var i := 0 to BOMLength - 1 do
      if Buffer[i] <> BOMBytes[i] then
      begin
        HasBOM := False;
        Break;
      end;

    if HasBOM then
    begin
      // 移除BOM
      SetLength(Result, Length(Buffer) - BOMLength);
      if Length(Result) > 0 then
        Move(Buffer[BOMLength], Result[0], Length(Result));
    end
    else
      Result := Buffer;
  end
  else
    Result := Buffer;
end;

class function TEncodingUtils.ConvertFileEncoding(const SourceFile, TargetFile: string;
  SourceEncoding, TargetEncoding: TEncoding; WithBOM: Boolean): Boolean;
var
  SourceBytes, TargetBytes: TBytes;
  SourceText: string;
  SourceBOMSize: Integer;
begin
  Result := False;

  if not FileExists(SourceFile) then
    Exit;

  try
    // 读取源文件
    SourceBytes := TFile.ReadAllBytes(SourceFile);

    // 如果源编码未指定，检测源文件编码
    if SourceEncoding = nil then
    begin
      var DetectionResult := DetectFileEncoding(SourceFile);
      SourceEncoding := DetectionResult.Encoding;
      SourceBOMSize := DetectionResult.BOMSize;
    end
    else
    begin
      // 检查源文件是否有BOM
      var HasBOM := HasBOM(SourceBytes, SourceBOMSize);
      if not HasBOM then
        SourceBOMSize := 0;
    end;

    // 如果目标编码未指定，使用UTF-8
    if TargetEncoding = nil then
      TargetEncoding := TEncoding.UTF8;

    // 从源编码转换到Unicode字符串
    if SourceBOMSize > 0 then
    begin
      // 跳过BOM
      var ContentBytes: TBytes;
      SetLength(ContentBytes, Length(SourceBytes) - SourceBOMSize);
      if Length(ContentBytes) > 0 then
        Move(SourceBytes[SourceBOMSize], ContentBytes[0], Length(ContentBytes));
      SourceText := SourceEncoding.GetString(ContentBytes);
    end
    else
      SourceText := SourceEncoding.GetString(SourceBytes);

    // 从Unicode字符串转换到目标编码
    TargetBytes := TargetEncoding.GetBytes(SourceText);

    // 如果需要添加BOM
    if WithBOM then
    begin
      var BOMBytes := TargetEncoding.GetPreamble;
      if Length(BOMBytes) > 0 then
      begin
        var FinalBytes: TBytes;
        SetLength(FinalBytes, Length(BOMBytes) + Length(TargetBytes));
        if Length(BOMBytes) > 0 then
          Move(BOMBytes[0], FinalBytes[0], Length(BOMBytes));
        if Length(TargetBytes) > 0 then
          Move(TargetBytes[0], FinalBytes[Length(BOMBytes)], Length(TargetBytes));
        TargetBytes := FinalBytes;
      end;
    end;

    // 写入目标文件
    TFile.WriteAllBytes(TargetFile, TargetBytes);

    Result := True;
  except
    on E: Exception do
    begin
      Log('转换文件编码时出错: ' + E.Message);
      Result := False;
    end;
  end;
end;

class function TEncodingUtils.GetEncodingName(Encoding: TEncoding): string;
begin
  Result := EncodingToString(Encoding);
end;

end.