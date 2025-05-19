unit UtilsEncodingTypes;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, System.Generics.Collections,
  System.Math, System.IOUtils, Winapi.Windows;

// 在此定义一个类型别名，以区分自定义的编码枚举类型和系统的TEncoding类
type
  TEncodingClass = System.SysUtils.TEncoding;

  // 定义Windows API类型
  {$IFNDEF UNICODE}
  LANGID = Word;
  {$ENDIF}

// 编码常量定义
const
  // 编码名称常量
  ENCODING_UNKNOWN = 'Unknown';
  ENCODING_ANSI = 'ANSI';
  ENCODING_ASCII = 'ASCII';
  ENCODING_UTF8 = 'UTF-8';
  ENCODING_UTF8_BOM = 'UTF-8 BOM';
  ENCODING_UTF16_LE = 'UTF-16 LE';
  ENCODING_UTF16_BE = 'UTF-16 BE';
  ENCODING_UTF32_LE = 'UTF-32 LE';
  ENCODING_UTF32_BE = 'UTF-32 BE';
  ENCODING_GB18030 = 'GB18030';
  ENCODING_GB2312 = 'GB2312';
  ENCODING_GBK = 'GBK';
  ENCODING_BIG5 = 'Big5';
  ENCODING_SHIFT_JIS = 'Shift-JIS';
  ENCODING_EUC_JP = 'EUC-JP';
  ENCODING_ISO2022_JP = 'ISO-2022-JP';
  ENCODING_EUC_KR = 'EUC-KR';
  ENCODING_ISO_2022_KR = 'ISO-2022-KR';
  ENCODING_WINDOWS_1251 = 'Windows-1251';
  ENCODING_WINDOWS_1252 = 'Windows-1252';
  ENCODING_WINDOWS_1253 = 'Windows-1253';
  ENCODING_WINDOWS_1254 = 'Windows-1254';
  ENCODING_WINDOWS_1255 = 'Windows-1255';
  ENCODING_WINDOWS_1256 = 'Windows-1256';
  ENCODING_WINDOWS_1257 = 'Windows-1257';
  ENCODING_WINDOWS_1258 = 'Windows-1258';
  ENCODING_KOI8_R = 'KOI8-R';
  ENCODING_KOI8_U = 'KOI8-U';
  ENCODING_EUC_TW = 'EUC-TW';
  ENCODING_CP949 = 'CP949';
  ENCODING_BINARY = 'Binary';

  // 代码页常量
  CP_UTF8 = 65001;
  CP_UTF16_LE = 1200;
  CP_UTF16_BE = 1201;
  CP_UTF32_LE = 12000;
  CP_UTF32_BE = 12001;
  CP_GBK = 936;
  CP_GB2312 = 20936;
  CP_GB18030 = 54936;
  CP_BIG5 = 950;
  CP_SHIFT_JIS = 932;
  CP_EUC_JP = 51932;
  CP_ISO_2022_JP = 50220;
  CP_EUC_KR = 949;
  CP_ISO_2022_KR = 50225;

  // BOM 定义 - 移至implementation部分，避免重复定义

  // ISO-2022-JP 转义序列
  ISO2022_JP_ASCII    = #$1B'(B';    // ESC (B - ASCII
  ISO2022_JP_JISX0201 = #$1B'(J';    // ESC (J - JIS X 0201-1976 片假名
  ISO2022_JP_JISX0208 = #$1B'$B';    // ESC $B - JIS X 0208-1983
  ISO2022_JP_JISX0212 = #$1B'$(D';   // ESC $(D - JIS X 0212-1990

  // 编码检测常量
  MIN_CONFIDENCE = 0.6;        // 最小置信度
  MAX_TEXT_SAMPLE = 16384;     // 最大文本样本大小（16KB）
  MIN_TEXT_SAMPLE = 256;       // 最小文本样本大小（256字节）
  MAX_DETECTION_TIME = 1000;   // 最大检测时间（毫秒）

  // 文件类型常量
  TEXT_FILE_EXTENSIONS: array[0..19] of string = (
    '.txt', '.log', '.csv', '.xml', '.html', '.htm', '.json', '.js', '.css',
    '.pas', '.dpr', '.dfm', '.c', '.cpp', '.h', '.hpp', '.cs', '.java', '.py', '.rb'
  );

  BINARY_FILE_EXTENSIONS: array[0..19] of string = (
    '.exe', '.dll', '.obj', '.bin', '.o', '.a', '.so', '.lib', '.pdb', '.com',
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.ico', '.zip', '.rar', '.7z', '.tar'
  );

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
  /// 编码类型枚举
  /// </summary>
  TEncodingType = (
    etUnknown,    // 未知编码
    etANSI,       // ANSI编码
    etASCII,      // ASCII编码
    etUTF8,       // UTF-8编码（无BOM）
    etUTF8BOM,    // UTF-8编码（有BOM）
    etUTF16LE,    // UTF-16 Little Endian编码
    etUTF16BE,    // UTF-16 Big Endian编码
    etUTF32LE,    // UTF-32 Little Endian编码
    etUTF32BE,    // UTF-32 Big Endian编码
    etGBK,        // GBK编码
    etGB2312,     // GB2312编码
    etGB18030,    // GB18030编码
    etBig5,       // Big5编码
    etShiftJIS,   // Shift-JIS编码
    etEUCJP,      // EUC-JP编码
    etEUCKR,      // EUC-KR编码
    etBinary      // 二进制文件
  );

  /// <summary>
  /// 编码检测方法枚举
  /// </summary>
  TEncodingDetectionMethod = (
    edmBOM,                // 通过BOM检测
    edmASCII,              // 纯ASCII检测
    edmFileType,           // 文件类型判断
    edmUTF8Validation,     // UTF-8有效性检测
    edmChineseCharacters,  // 中文字符检测
    edmJapaneseCharacters, // 日文字符检测
    edmKoreanCharacters,   // 韩文字符检测
    edmSystemLanguage,     // 系统语言环境判断
    edmFileName,           // 文件名判断
    edmStatistical,        // 统计分析
    edmHeuristic,          // 启发式规则
    edmUserHistory,        // 用户历史记录
    edmUnknown             // 未知方法
  );

  /// <summary>
  /// 编码转换类型枚举
  /// </summary>
  TEncodingConversionType = (
    ectSameEncoding,       // 相同编码（无需转换）
    ectAddBOM,             // 添加BOM
    ectRemoveBOM,          // 移除BOM
    ectANSIToUTF8,         // ANSI到UTF-8
    ectUTF8ToANSI,         // UTF-8到ANSI
    ectANSIToUTF16LE,      // ANSI到UTF-16 LE
    ectUTF16LEToANSI,      // UTF-16 LE到ANSI
    ectUTF8ToUTF16LE,      // UTF-8到UTF-16 LE
    ectUTF16LEToUTF8,      // UTF-16 LE到UTF-8
    ectOther               // 其他转换
  );

  /// <summary>
  /// BOM检测结果记录
  /// </summary>
  TBOMDetectionResult = record
    BOMType: Integer;      // BOM类型
    BOMLength: Integer;    // BOM长度（字节数）
    Encoding: string;      // 对应的编码名称
    CodePage: Integer;     // 对应的代码页
  end;

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
  /// 编码转换结果记录
  /// </summary>
  TEncodingConversionResult = record
    Success: Boolean;           // 是否成功
    ErrorMessage: string;       // 错误信息
    SourceEncoding: string;     // 源编码
    TargetEncoding: string;     // 目标编码
    BytesProcessed: Int64;      // 处理的字节数
    ElapsedTime: Int64;         // 耗时(毫秒)
  end;

// BOM类型常量
const
  BOM_NONE = 0;      // 无BOM
  BOM_UTF8 = 1;      // UTF-8 BOM (EF BB BF)
  BOM_UTF16LE = 2;   // UTF-16 Little Endian BOM (FF FE)
  BOM_UTF16BE = 3;   // UTF-16 Big Endian BOM (FE FF)
  BOM_UTF32LE = 4;   // UTF-32 Little Endian BOM (FF FE 00 00)
  BOM_UTF32BE = 5;   // UTF-32 Big Endian BOM (00 00 FE FF)

implementation

// BOM 字节数组常量
const
  UTF8_BOM: array[0..2] of Byte = ($EF, $BB, $BF);
  UTF16_LE_BOM: array[0..1] of Byte = ($FF, $FE);
  UTF16_BE_BOM: array[0..1] of Byte = ($FE, $FF);
  UTF32_LE_BOM: array[0..3] of Byte = ($FF, $FE, $00, $00);
  UTF32_BE_BOM: array[0..3] of Byte = ($00, $00, $FE, $FF);

end.
