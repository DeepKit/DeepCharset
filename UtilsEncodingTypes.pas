unit UtilsEncodingTypes;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, System.Generics.Collections,
  System.TimeSpan, System.Diagnostics, System.Math, System.IOUtils, UtilsEncodingConstants;

// 在此定义一个类型别名，以区分自定义的编码枚举类型和系统的TEncoding类
type
  TEncodingClass = System.SysUtils.TEncoding;

type
  /// <summary>
  /// Represents various encoding types supported by the system
  /// </summary>
  TEncoding = (
    // Standard encodings
    ASCII,       // ASCII (7-bit)
    ANSI,        // ANSI/Windows codepage
    UTF8,        // UTF-8
    UTF16LE,     // UTF-16 Little Endian (Windows Unicode)
    UTF16BE,     // UTF-16 Big Endian
    UTF32LE,     // UTF-32 Little Endian
    UTF32BE,     // UTF-32 Big Endian

    // Chinese encodings
    GB18030,     // GB18030 (superset of GB2312 and GBK)
    GB2312,      // GB2312
    GBK,         // GBK
    Big5,        // Big5 (Traditional Chinese)
    HZGB2312,    // HZ-GB-2312

    // Japanese encodings
    ShiftJIS,    // Shift-JIS
    EUC_JP,      // EUC-JP
    ISO2022JP,   // ISO-2022-JP

    // Korean encodings
    EUC_KR,      // EUC-KR
    UHC,         // Unified Hangul Code
    ISO2022KR,   // ISO-2022-KR

    // Cyrillic encodings
    Windows1251, // Windows-1251
    KOI8R,       // KOI8-R
    ISO8859_5,   // ISO-8859-5

    // Other ISO encodings
    ISO8859_1,   // ISO-8859-1 (Latin-1)
    ISO8859_2,   // ISO-8859-2 (Latin-2)
    ISO8859_3,   // ISO-8859-3 (Latin-3)
    ISO8859_4,   // ISO-8859-4 (Latin-4)
    ISO8859_6,   // ISO-8859-6 (Arabic)
    ISO8859_7,   // ISO-8859-7 (Greek)
    ISO8859_8,   // ISO-8859-8 (Hebrew)
    ISO8859_9,   // ISO-8859-9 (Turkish)
    ISO8859_10,  // ISO-8859-10 (Nordic)
    ISO8859_13,  // ISO-8859-13 (Baltic)
    ISO8859_14,  // ISO-8859-14 (Celtic)
    ISO8859_15,  // ISO-8859-15 (Latin-9)
    ISO8859_16,  // ISO-8859-16 (Latin-10)

    // Windows code pages
    Windows1250, // Windows-1250 (Central European)
    Windows1252, // Windows-1252 (Latin-1)
    Windows1253, // Windows-1253 (Greek)
    Windows1254, // Windows-1254 (Turkish)
    Windows1255, // Windows-1255 (Hebrew)
    Windows1256, // Windows-1256 (Arabic)
    Windows1257, // Windows-1257 (Baltic)
    Windows1258, // Windows-1258 (Vietnamese)

    // Other
    Binary,      // Binary (no encoding)
    Custom       // Custom encoding (user-defined)
  );


  /// <summary>
  /// 支持的编码类型
  /// </summary>
  TEncodingType = (
    etUnknown,    // 未知编码
    etASCII,      // ASCII编码
    etUTF8,       // UTF-8编码
    etUTF16LE,    // UTF-16 Little Endian
    etUTF16BE,    // UTF-16 Big Endian
    etUTF32LE,    // UTF-32 Little Endian
    etUTF32BE,    // UTF-32 Big Endian
    etGBK,        // GBK编码
    etGB18030,    // GB18030编码
    etBig5,       // Big5编码
    etShiftJIS,   // Shift-JIS编码
    etEUCJP,      // EUC-JP编码
    etEUCKR,      // EUC-KR编码
    etISO88591,   // ISO-8859-1编码
    etISO88592,   // ISO-8859-2编码
    etISO88595,   // ISO-8859-5编码
    etISO88597,   // ISO-8859-7编码
    etISO88599,   // ISO-8859-9编码
    etWindows1250,// Windows-1250编码
    etWindows1251,// Windows-1251编码
    etWindows1252,// Windows-1252编码
    etWindows1253,// Windows-1253编码
    etWindows1254,// Windows-1254编码
    etWindows1255,// Windows-1255编码
    etWindows1256,// Windows-1256编码
    etWindows1257,// Windows-1257编码
    etWindows1258 // Windows-1258编码
  );

  // Forward declarations
  TEncodingInfo = record
    Encoding: string;     // 编码名称
    Confidence: Double;   // 置信度
    IsValid: Boolean;     // 是否有效
    BOM: TBytes;          // BOM字节
  end;

  /// <summary>
  /// 编码检测器接口
  /// </summary>
  IEncodingDetector = interface
    ['{F21A3B45-C8D7-42E6-B9A1-6D58E4F0A429}']
    function DetectEncoding(const AFilePath: string): TEncodingInfo;
    function DetectEncodingFromBytes(const ABytes: TBytes): TEncodingInfo;
    function DetectEncodingFromStream(AStream: TStream): TEncodingInfo;
    function GetName: string;
    property Name: string read GetName;
  end;

  /// <summary>
  /// Source-target encoding pair
  /// </summary>
  TEncodingPair = record
    SourceEncoding: TEncoding;
    TargetEncoding: TEncoding;
  end;

  /// <summary>
  /// Byte order mark (BOM) definition
  /// </summary>
  TBOM = record
    Bytes: TBytes;
    Encoding: TEncodingClass;
    Name: string;
  end;

  /// <summary>
  /// Types of content for encoding detection heuristics
  /// </summary>
  TContentType = (
    ctUnknown, // Unknown content type
    ctText,    // Text content
    ctBinary,  // Binary content
    ctMixed    // Mixed content (e.g., XML with binary parts)
  );

  /// <summary>
  /// Language hints for encoding detection
  /// </summary>
  TLanguageHint = (
    lhUnknown,  // Unknown language
    lhLatin,    // Latin languages (English, French, etc.)
    lhChinese,  // Chinese
    lhJapanese, // Japanese
    lhKorean,   // Korean
    lhRussian,  // Russian
    lhGreek,    // Greek
    lhArabic,   // Arabic
    lhHebrew    // Hebrew
  );

  /// <summary>
  /// File size categories for optimization strategies
  /// </summary>
  TFileSizeCategory = (
    fscSmall,   // Small files (<100KB)
    fscMedium,  // Medium files (100KB-5MB)
    fscLarge,   // Large files (5MB-100MB)
    fscVeryLarge // Very large files (>100MB)
  );

  /// <summary>
  /// Analysis level for encoding detection
  /// </summary>
  TAnalysisLevel = (
    alMinimal,  // Minimal analysis (fast but less accurate)
    alNormal,   // Normal analysis (balanced)
    alDeep,     // Deep analysis (slower but more accurate)
    alExhaustive // Exhaustive analysis (slowest but most accurate)
  );

  /// <summary>
  /// Confidence information for encoding detection
  /// </summary>
  TEncodingConfidence = record
    Encoding: TEncoding;
    Confidence: Double;        // 0.0 to 1.0
    SecondaryEncoding: TEncoding;
    SecondaryConfidence: Double;
    HasBOM: Boolean;
    ConflictingEvidence: Boolean;
    AdditionalInfo: string;
  end;

  /// <summary>
  /// Error information for encoding validation
  /// </summary>
  TEncodingValidationError = record
    ErrorPosition: Int64;
    ErrorType: string;
    Description: string;
    InvalidBytes: TBytes;
    Severity: Integer; // 1-10, with 10 being most severe
  end;

  /// <summary>
  /// Result of encoding detection
  /// </summary>
  TEncodingDetectionInfo = record
    EncodingName: string;
    Encoding: TEncoding;
    Confidence: Double;
    HasBOM: Boolean;
    BOMSize: Integer;
    DetectionTime: Int64; // in milliseconds
    ValidationErrors: TArray<TEncodingValidationError>;
    ErrorCount: Integer;
    ValidCodePoints: Integer;
    InvalidCodePoints: Integer;
    AdditionalInfo: string;
    LanguageHint: TLanguageHint;
  end;

  /// <summary>
  /// Result of encoding conversion
  /// </summary>
  TEncodingConversionResult = record
    Success: Boolean;
    SourceEncoding: TEncoding;
    TargetEncoding: TEncoding;
    ElapsedTime: Int64; // in milliseconds
    ProcessedBytes: Int64;
    OutputBytes: Int64;
    ErrorCount: Integer;
    RepairCount: Integer;
    ErrorDetails: string;
  end;

  /// <summary>
  /// Performance metrics for encoding operations
  /// </summary>
  TConversionMetrics = record
    ElapsedTime: Int64;    // in milliseconds
    InputSize: Int64;      // in bytes
    OutputSize: Int64;     // in bytes
    BytesPerSecond: Int64; // throughput
    Success: Boolean;      // operation success
  end;

  /// <summary>
  /// Extended error diagnostic for encoding operations
  /// </summary>
  TEncodingErrorDiagnostic = record
    ErrorType: string;
    Position: Int64;
    Description: string;
    InvalidBytes: TBytes;
    InvalidCodePoint: Integer;
    SurroundingText: string;
    SuggestedFix: string;
    Severity: Integer; // 1-10
    ErrorCategory: string;
  end;

  /// <summary>
  /// Statistics for encoding detection and validation
  /// </summary>
  TEncodingStats = record
    TotalBytes: Integer;
    ASCIICount: Integer;
    ValidSequences: Integer;
    InvalidSequences: Integer;
    OverlongSequences: Integer;
    SurrogateCodePoints: Integer;
    OutOfRangeCodePoints: Integer;
    ControlCharCount: Integer;
    ExtendedASCIICount: Integer;
    MultiByteCount: Integer;
    MaxSequenceLength: Integer;
    Diagnostics: TArray<string>;
    ProcessingTime: Int64; // 修改为Int64，替代TTimeSpan
  end;

  /// <summary>
  /// A set of ordered byte statistics used for encoding detection
  /// </summary>
  TByteDistribution = record
    ByteCounts: array[0..255] of Integer;
    Total: Integer;
    ZeroBytes: Integer;
    ControlChars: Integer;
    ExtendedASCII: Integer;
    AsciiLetters: Integer;
    AsciiDigits: Integer;
    ValidUTF8Sequences: Integer;
    InvalidUTF8Sequences: Integer;
    PotentialUTF16Markers: Integer;
    NullBytes: Integer;
  end;

  /// <summary>
  /// A statistical fingerprint of typical encoding patterns
  /// </summary>
  TEncodingFingerprint = record
    EncodingName: string;
    Encoding: TEncoding;
    BytePatterns: TArray<TBytes>;
    CommonSequences: TArray<TBytes>;
    CharacterFrequencies: TArray<Double>;
    NullByteFrequency: Double;
    ControlCharFrequency: Double;
    AsciiRatio: Double;
    ValidSequenceRatio: Double;
  end;

  /// <summary>
  /// Types of invalid UTF-8 sequences
  /// </summary>
  TInvalidSequenceType = (
    istUnknown,            // Unknown error
    istInvalidFirstByte,   // Invalid first byte
    istInvalidContinuation,// Invalid continuation byte
    istIncompleteSequence, // Incomplete sequence
    istOverlongEncoding,   // Overlong encoding
    istSurrogateCodePoint, // Surrogate code point
    istInvalidCodePoint,   // Invalid code point
    istOutOfRange          // Code point out of range
  );

  /// <summary>
  /// Error severity levels
  /// </summary>
  TErrorSeverity = (
    esNone,     // No error
    esWarning,  // Warning
    esError,    // Error
    esFatal     // Fatal error
  );

  /// <summary>
  /// Repair strategies for invalid sequences
  /// </summary>
  TRepairStrategy = (
    rsNone,               // No repair
    rsSkipByte,           // Skip the invalid byte
    rsSkipSequence,       // Skip the entire sequence
    rsSubstituteCharacter,// Replace with a substitute character
    rsSubstituteSequence, // Replace with a substitute sequence
    rsNormalize           // Normalize the sequence
  );

  /// <summary>
  /// Diagnostic information for invalid UTF-8 sequences
  /// </summary>
  TInvalidSequenceDiagnostic = record
    ErrorType: TInvalidSequenceType;  // Type of error
    Description: string;              // Error description
    ErrorPosition: Int64;             // Position of the error
    InvalidCodePoint: UInt32;         // Invalid code point
    Severity: TErrorSeverity;         // Error severity
    RepairStrategy: TRepairStrategy;  // Repair strategy
  end;

  /// <summary>
  /// Progress information for lengthy operations
  /// </summary>
  TProgressInfo = record
    OperationType: string;  // e.g., 'Detection', 'Conversion'
    Current: Int64;         // Current position
    Total: Int64;           // Total size/items
    PercentComplete: Double; // 0-100
    CurrentItem: string;    // Current file/item
    ElapsedTime: Int64;     // in milliseconds
    EstimatedTimeRemaining: Int64; // in milliseconds
    CurrentSpeed: Double;   // bytes per second
    StatusMessage: string;  // Message to display
  end;

  // 编码分析结果
  TEncodingAnalysisResult = record
    UTF8Match: Double;    // UTF-8匹配度
    GBKMatch: Double;     // GBK匹配度
    Big5Match: Double;    // Big5匹配度
    IsValid: Boolean;     // 是否有效
  end;

  // 编码特征
  TEncodingFeature = record
    Name: string;         // 特征名称
    Weight: Double;       // 权重
    Pattern: string;      // 特征模式
  end;

  // 编码特征数组
  TEncodingFeatures = array of TEncodingFeature;

const
  EncodingNames: array[TEncoding] of string = (
    'ASCII',       // ASCII
    'ANSI',        // ANSI
    'UTF-8',       // UTF8
    'UTF-16LE',    // UTF16LE
    'UTF-16BE',    // UTF16BE
    'UTF-32LE',    // UTF32LE
    'UTF-32BE',    // UTF32BE
    'GB18030',     // GB18030
    'GB2312',      // GB2312
    'GBK',         // GBK
    'Big5',        // Big5
    'HZ-GB-2312',  // HZGB2312
    'Shift-JIS',   // ShiftJIS
    'EUC-JP',      // EUC_JP
    'ISO-2022-JP', // ISO2022JP
    'EUC-KR',      // EUC_KR
    'UHC',         // UHC
    'ISO-2022-KR', // ISO2022KR
    'Windows-1251', // Windows1251
    'KOI8-R',      // KOI8R
    'ISO-8859-5',  // ISO8859_5
    'ISO-8859-1',  // ISO8859_1
    'ISO-8859-2',  // ISO8859_2
    'ISO-8859-3',  // ISO8859_3
    'ISO-8859-4',  // ISO8859_4
    'ISO-8859-6',  // ISO8859_6
    'ISO-8859-7',  // ISO8859_7
    'ISO-8859-8',  // ISO8859_8
    'ISO-8859-9',  // ISO8859_9
    'ISO-8859-10', // ISO8859_10
    'ISO-8859-13', // ISO8859_13
    'ISO-8859-14', // ISO8859_14
    'ISO-8859-15', // ISO8859_15
    'ISO-8859-16', // ISO8859_16
    'Windows-1250', // Windows1250
    'Windows-1252', // Windows1252
    'Windows-1253', // Windows1253
    'Windows-1254', // Windows1254
    'Windows-1255', // Windows1255
    'Windows-1256', // Windows1256
    'Windows-1257', // Windows1257
    'Windows-1258', // Windows1258
    'Binary',      // Binary
    'Custom'       // Custom
  );

  // 默认编码特征
  DEFAULT_FEATURES: array[0..2] of TEncodingFeature = (
    (Name: 'UTF-8'; Weight: 1.0; Pattern: 'UTF-8'),
    (Name: 'GBK'; Weight: 1.0; Pattern: 'GBK'),
    (Name: 'Big5'; Weight: 1.0; Pattern: 'Big5')
  );

/// <summary>
/// Gets the name of an encoding
/// </summary>
function GetEncodingName(AEncoding: TEncoding): string;

/// <summary>
/// Creates a BOM from bytes
/// </summary>
function CreateBOM(const ABytes: TBytes; AEncoding: TEncodingClass; const AName: string): TBOM;

/// <summary>
/// Gets default BOMs for various encodings
/// </summary>
function GetDefaultBOMs: TArray<TBOM>;

/// <summary>
/// Detects BOM in a byte array
/// </summary>
function DetectBOM(const ABytes: TBytes): TBOM;

/// <summary>
/// Gets a byte array with the BOM for the specified encoding
/// </summary>
function GetBOMBytes(AEncoding: TEncodingClass): TBytes;

/// <summary>
/// Determines if an encoding uses Big Endian byte order
/// </summary>
function IsBigEndianEncoding(AEncoding: TEncoding): Boolean;

/// <summary>
/// Determines if an encoding is a Unicode variant
/// </summary>
function IsUnicodeEncoding(AEncoding: TEncoding): Boolean;

// 编码常量
const
  ENCODING_UNKNOWN = 'UNKNOWN';
  ENCODING_ANSI = 'ANSI';
  ENCODING_UTF8 = 'UTF-8';
  ENCODING_UTF16LE = 'UTF-16LE';
  ENCODING_UTF16BE = 'UTF-16BE';
  ENCODING_UTF32LE = 'UTF-32LE';
  ENCODING_UTF32BE = 'UTF-32BE';
  ENCODING_GBK = 'GBK';
  ENCODING_GB18030 = 'GB18030';
  ENCODING_GB2312 = 'GB2312';
  ENCODING_BIG5 = 'Big5';
  ENCODING_SHIFT_JIS = 'Shift-JIS';
  ENCODING_EUC_JP = 'EUC-JP';
  ENCODING_ISO_2022_JP = 'ISO-2022-JP';
  ENCODING_EUC_KR = 'EUC-KR';
  ENCODING_UHC = 'UHC';
  ENCODING_ISO_2022_KR = 'ISO-2022-KR';

/// <summary>
/// Determines if an encoding is a multi-byte encoding
/// </summary>
function IsMultiByteEncoding(AEncoding: TEncoding): Boolean;

/// <summary>
/// Converts the name of an encoding to TEncoding
/// </summary>
function EncodingFromName(const AName: string): TEncoding;

/// <summary>
/// Returns an encoding from an IANA charset name
/// </summary>
function EncodingFromIANACharset(const ACharset: string): TEncoding;

/// <summary>
/// Returns an encoding from a Windows codepage
/// </summary>
function EncodingFromCodePage(ACodePage: Integer): TEncoding;

/// <summary>
/// Gets the default encoding for a language hint
/// </summary>
function GetDefaultEncodingForLanguage(ALanguageHint: TLanguageHint): TEncoding;

/// <summary>
/// Error severity levels
/// </summary>
function ErrorSeverityToString(Severity: TErrorSeverity): string;

/// <summary>
/// Base abstract encoding detector class
/// </summary>
type
  TEncodingDetector = class abstract
  private
    FName: string;
    FDescription: string;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    function DetectEncoding(const ABytes: TBytes): TEncodingDetectionInfo; virtual; abstract;
    function DetectEncodingFromBytes(const ABytes: TBytes): TEncodingDetectionInfo; virtual;
    function DetectEncodingFromStream(AStream: TStream): TEncodingDetectionInfo; virtual;
    function GetName: string; virtual;

    property Name: string read GetName;
    property Description: string read FDescription write FDescription;
  end;

implementation

function GetEncodingName(AEncoding: TEncoding): string;
begin
  if Ord(AEncoding) <= Ord(High(TEncoding)) then
    Result := EncodingNames[AEncoding]
  else
    Result := 'Unknown';
end;

function CreateBOM(const ABytes: TBytes; AEncoding: TEncodingClass; const AName: string): TBOM;
begin
  Result.Bytes := ABytes;
  Result.Encoding := AEncoding;
  Result.Name := AName;
end;

function GetDefaultBOMs: TArray<TBOM>;
begin
  SetLength(Result, 5);

  // UTF-8 BOM
  Result[0].Bytes := TBytes.Create($EF, $BB, $BF);
  Result[0].Encoding := TEncodingClass.UTF8;
  Result[0].Name := 'UTF-8';

  // UTF-16 LE BOM
  Result[1].Bytes := TBytes.Create($FF, $FE);
  Result[1].Encoding := TEncodingClass.Unicode;
  Result[1].Name := 'UTF-16LE';

  // UTF-16 BE BOM
  Result[2].Bytes := TBytes.Create($FE, $FF);
  Result[2].Encoding := TEncodingClass.BigEndianUnicode;
  Result[2].Name := 'UTF-16BE';

  // UTF-32 LE BOM
  Result[3].Bytes := TBytes.Create($FF, $FE, $00, $00);
  Result[3].Encoding := TEncodingClass.GetEncoding(12000);
  Result[3].Name := 'UTF-32LE';

  // UTF-32 BE BOM
  Result[4].Bytes := TBytes.Create($00, $00, $FE, $FF);
  Result[4].Encoding := TEncodingClass.GetEncoding(12001);
  Result[4].Name := 'UTF-32BE';
end;

function DetectBOM(const ABytes: TBytes): TBOM;
var
  BOMs: TArray<TBOM>;
  BOM: TBOM;
  j: Integer;
  Match: Boolean;
begin
  // Default to no BOM
  Result.Encoding := TEncodingClass.Default;
  Result.Name := '';
  SetLength(Result.Bytes, 0);

  // Get all known BOMs
  BOMs := GetDefaultBOMs;

  // Check if bytes start with any known BOM
  for BOM in BOMs do
  begin
    if Length(ABytes) < Length(BOM.Bytes) then
      Continue;

    Match := True;
    for j := 0 to High(BOM.Bytes) do
    begin
      if ABytes[j] <> BOM.Bytes[j] then
      begin
        Match := False;
        Break;
      end;
    end;

    if Match then
    begin
      Result := BOM;
      Exit;
    end;
  end;
end;

function GetBOMBytes(AEncoding: TEncodingClass): TBytes;
var
  BOMs: TArray<TBOM>;
  BOM: TBOM;
begin
  SetLength(Result, 0);

  BOMs := GetDefaultBOMs;

  for BOM in BOMs do
  begin
    if BOM.Encoding = AEncoding then
    begin
      Result := BOM.Bytes;
      Exit;
    end;
  end;
end;

function IsBigEndianEncoding(AEncoding: TEncoding): Boolean;
begin
  Result := (AEncoding = TEncoding.UTF16BE) or (AEncoding = TEncoding.UTF32BE);
end;

function IsUnicodeEncoding(AEncoding: TEncoding): Boolean;
begin
  Result := (AEncoding = TEncoding.UTF8) or
            (AEncoding = TEncoding.UTF16LE) or
            (AEncoding = TEncoding.UTF16BE) or
            (AEncoding = TEncoding.UTF32LE) or
            (AEncoding = TEncoding.UTF32BE);
end;

function IsMultiByteEncoding(AEncoding: TEncoding): Boolean;
begin
  Result := (AEncoding = TEncoding.UTF8) or
            (AEncoding = TEncoding.GB18030) or
            (AEncoding = TEncoding.GB2312) or
            (AEncoding = TEncoding.GBK) or
            (AEncoding = TEncoding.Big5) or
            (AEncoding = TEncoding.ShiftJIS) or
            (AEncoding = TEncoding.EUC_JP) or
            (AEncoding = TEncoding.EUC_KR);
end;

function EncodingFromName(const AName: string): TEncoding;
var
  i: TEncoding;
  NormalizedName: string;
begin
  Result := TEncoding.Binary; // Default

  // Normalize name for comparison
  NormalizedName := AName.ToLower.Replace('-', '').Replace('_', '');

  // Check all encoding names
  for i := Low(TEncoding) to High(TEncoding) do
  begin
    if NormalizedName = EncodingNames[i].ToLower.Replace('-', '').Replace('_', '') then
    begin
      Result := i;
      Exit;
    end;
  end;

  // Special cases and aliases
  if NormalizedName = 'unicode' then
    Result := TEncoding.UTF16LE
  else if NormalizedName = 'utf16' then
    Result := TEncoding.UTF16LE
  else if NormalizedName = 'utf32' then
    Result := TEncoding.UTF32LE
  else if NormalizedName = 'windows' then
    Result := TEncoding.ANSI;
end;

function EncodingFromIANACharset(const ACharset: string): TEncoding;
var
  NormalizedCharset: string;
begin
  NormalizedCharset := ACharset.ToLower.Replace('-', '').Replace('_', '');

  // Handle common IANA charsets
  if (NormalizedCharset = 'usascii') or (NormalizedCharset = 'ascii') then
    Result := TEncoding.ASCII
  else if (NormalizedCharset = 'utf8') then
    Result := TEncoding.UTF8
  else if (NormalizedCharset = 'utf16') or (NormalizedCharset = 'utf16le') then
    Result := TEncoding.UTF16LE
  else if (NormalizedCharset = 'utf16be') then
    Result := TEncoding.UTF16BE
  else if (NormalizedCharset = 'utf32') or (NormalizedCharset = 'utf32le') then
    Result := TEncoding.UTF32LE
  else if (NormalizedCharset = 'utf32be') then
    Result := TEncoding.UTF32BE
  else if (NormalizedCharset = 'gb18030') then
    Result := TEncoding.GB18030
  else if (NormalizedCharset = 'gb2312') then
    Result := TEncoding.GB2312
  else if (NormalizedCharset = 'gbk') then
    Result := TEncoding.GBK
  else if (NormalizedCharset = 'big5') then
    Result := TEncoding.Big5
  else if (NormalizedCharset = 'hzgb2312') then
    Result := TEncoding.HZGB2312
  else if (NormalizedCharset = 'shiftjis') or (NormalizedCharset = 'sjis') then
    Result := TEncoding.ShiftJIS
  else if (NormalizedCharset = 'eucjp') then
    Result := TEncoding.EUC_JP
  else if (NormalizedCharset = 'iso2022jp') then
    Result := TEncoding.ISO2022JP
  else if (NormalizedCharset = 'euckr') then
    Result := TEncoding.EUC_KR
  else if (NormalizedCharset = 'windows1251') then
    Result := TEncoding.Windows1251
  else if (NormalizedCharset = 'koi8r') then
    Result := TEncoding.KOI8R
  else if (NormalizedCharset = 'iso88591') or (NormalizedCharset = 'latin1') then
    Result := TEncoding.ISO8859_1
  else if (NormalizedCharset = 'iso88592') or (NormalizedCharset = 'latin2') then
    Result := TEncoding.ISO8859_2
  else if (NormalizedCharset = 'windows1252') then
    Result := TEncoding.Windows1252
  else
    Result := TEncoding.ANSI; // Default to ANSI if unknown
end;

function EncodingFromCodePage(ACodePage: Integer): TEncoding;
begin
  case ACodePage of
    0:      Result := TEncoding.ASCII;    // ASCII
    65001:  Result := TEncoding.UTF8;     // UTF-8
    1200:   Result := TEncoding.UTF16LE;  // UTF-16LE
    1201:   Result := TEncoding.UTF16BE;  // UTF-16BE
    12000:  Result := TEncoding.UTF32LE;  // UTF-32LE
    12001:  Result := TEncoding.UTF32BE;  // UTF-32BE
    54936:  Result := TEncoding.GB18030;  // GB18030
    20936:  Result := TEncoding.GB2312;   // GB2312
    936:    Result := TEncoding.GBK;      // GBK
    950:    Result := TEncoding.Big5;     // Big5
    52936:  Result := TEncoding.HZGB2312; // HZ-GB-2312
    932:    Result := TEncoding.ShiftJIS; // Shift-JIS
    51932:  Result := TEncoding.EUC_JP;   // EUC-JP
    50220:  Result := TEncoding.ISO2022JP; // ISO-2022-JP
    949:    Result := TEncoding.EUC_KR;   // EUC-KR
    1251:   Result := TEncoding.Windows1251; // Windows-1251
    20866:  Result := TEncoding.KOI8R;    // KOI8-R
    28595:  Result := TEncoding.ISO8859_5; // ISO-8859-5
    28591:  Result := TEncoding.ISO8859_1; // ISO-8859-1
    28592:  Result := TEncoding.ISO8859_2; // ISO-8859-2
    1250:   Result := TEncoding.Windows1250; // Windows-1250
    1252:   Result := TEncoding.Windows1252; // Windows-1252
    1253:   Result := TEncoding.Windows1253; // Windows-1253
    1254:   Result := TEncoding.Windows1254; // Windows-1254
    1255:   Result := TEncoding.Windows1255; // Windows-1255
    1256:   Result := TEncoding.Windows1256; // Windows-1256
    1257:   Result := TEncoding.Windows1257; // Windows-1257
    1258:   Result := TEncoding.Windows1258; // Windows-1258
  else
    Result := TEncoding.ANSI; // Default to ANSI for unknown code pages
  end;
end;

function GetDefaultEncodingForLanguage(ALanguageHint: TLanguageHint): TEncoding;
begin
  case ALanguageHint of
    lhLatin:    Result := TEncoding.ISO8859_1;
    lhChinese:  Result := TEncoding.GB18030;
    lhJapanese: Result := TEncoding.ShiftJIS;
    lhKorean:   Result := TEncoding.EUC_KR;
    lhRussian:  Result := TEncoding.Windows1251;
    lhGreek:    Result := TEncoding.Windows1253;
    lhArabic:   Result := TEncoding.Windows1256;
    lhHebrew:   Result := TEncoding.Windows1255;
  else
    Result := TEncoding.UTF8; // Default to UTF-8 for unknown languages
  end;
end;

function ErrorSeverityToString(Severity: TErrorSeverity): string;
begin
  case Severity of
    esNone:    Result := 'None';
    esWarning: Result := 'Warning';
    esError:   Result := 'Error';
    esFatal:   Result := 'Fatal';
  else
    Result := 'Unknown';
  end;
end;

// TEncodingDetector 实现

constructor TEncodingDetector.Create;
begin
  inherited Create;
  FName := 'BaseDetector';
  FDescription := 'Base encoding detector';
end;

destructor TEncodingDetector.Destroy;
begin
  inherited;
end;

function TEncodingDetector.DetectEncodingFromBytes(const ABytes: TBytes): TEncodingDetectionInfo;
begin
  Result := DetectEncoding(ABytes);
end;

function TEncodingDetector.DetectEncodingFromStream(AStream: TStream): TEncodingDetectionInfo;
var
  Buffer: TBytes;
  SavedPosition: Int64;
  ReadBytes: Integer;
  SampleSize: Integer;
begin
  // 保存当前流位置
  SavedPosition := AStream.Position;
  try
    // 读取样本
    SampleSize := Min(AStream.Size - AStream.Position, 65536); // 最多读取64KB
    SetLength(Buffer, SampleSize);
    ReadBytes := AStream.Read(Buffer[0], SampleSize);
    if ReadBytes < SampleSize then
      SetLength(Buffer, ReadBytes);

    // 检测编码
    Result := DetectEncoding(Buffer);
  finally
    // 恢复流位置
    AStream.Position := SavedPosition;
  end;
end;

function TEncodingDetector.GetName: string;
begin
  Result := FName;
end;

end.