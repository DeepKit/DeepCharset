unit UtilsEncodingTypes;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, System.Generics.Collections,
  System.Math, System.IOUtils, Winapi.Windows, UtilsTypes;

// �ڴ˶���һ�����ͱ������������Զ���ı���ö�����ͺ�ϵͳ��TEncoding��
type
  TEncodingClass = System.SysUtils.TEncoding;

  // ����Windows API����
  {$IFNDEF UNICODE}
  LANGID = Word;
  {$ENDIF}

// ���볣������
const
  // �������Ƴ�����ͳһת���� UtilsTypes������ȫ��Ŀһ�£�
  ENCODING_UNKNOWN        = 'Unknown';
  ENCODING_ANSI           = UtilsTypes.ENCODING_ANSI;
  ENCODING_ASCII          = UtilsTypes.ENCODING_ASCII;
  ENCODING_UTF8           = UtilsTypes.ENCODING_UTF8;
  ENCODING_UTF8_BOM       = UtilsTypes.ENCODING_UTF8_BOM;     // 'UTF-8 with BOM'
  ENCODING_UTF16_LE       = UtilsTypes.ENCODING_UTF16_LE;     // 'UTF-16LE'
  ENCODING_UTF16_BE       = UtilsTypes.ENCODING_UTF16_BE;     // 'UTF-16BE'
  ENCODING_UTF32_LE       = UtilsTypes.ENCODING_UTF32_LE;     // 'UTF-32LE'
  ENCODING_UTF32_BE       = UtilsTypes.ENCODING_UTF32_BE;     // 'UTF-32BE'
  ENCODING_GB18030        = UtilsTypes.ENCODING_GB18030;
  ENCODING_GB2312         = UtilsTypes.ENCODING_GB2312;
  ENCODING_GBK            = UtilsTypes.ENCODING_GBK;
  ENCODING_BIG5           = UtilsTypes.ENCODING_BIG5;         // 'BIG5'
  ENCODING_SHIFT_JIS      = UtilsTypes.ENCODING_SHIFT_JIS;
  ENCODING_EUC_JP         = UtilsTypes.ENCODING_EUC_JP;
  ENCODING_ISO2022_JP     = UtilsTypes.ENCODING_ISO_2022_JP;  // ���Ʋ�ͬ���ַ���һ��
  ENCODING_EUC_KR         = UtilsTypes.ENCODING_EUC_KR;
  ENCODING_ISO_2022_KR    = UtilsTypes.ENCODING_ISO_2022_KR;
  ENCODING_WINDOWS_1251   = 'Windows-1251';
  ENCODING_WINDOWS_1252   = 'Windows-1252';
  ENCODING_WINDOWS_1253   = 'Windows-1253';
  ENCODING_WINDOWS_1254   = 'Windows-1254';
  ENCODING_WINDOWS_1255   = 'Windows-1255';
  ENCODING_WINDOWS_1256   = 'Windows-1256';
  ENCODING_WINDOWS_1257   = 'Windows-1257';
  ENCODING_WINDOWS_1258   = 'Windows-1258';
  ENCODING_KOI8_R         = 'KOI8-R';
  ENCODING_KOI8_U         = 'KOI8-U';
  ENCODING_EUC_TW         = 'EUC-TW';
  ENCODING_CP949          = 'CP949';
  ENCODING_BINARY         = 'Binary';

  // ����ҳ����
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

  // BOM ���� - ����implementation���֣������ظ�����

  // ISO-2022-JP ת������
  ISO2022_JP_ASCII    = #$1B'(B';    // ESC (B - ASCII
  ISO2022_JP_JISX0201 = #$1B'(J';    // ESC (J - JIS X 0201-1976 Ƭ����
  ISO2022_JP_JISX0208 = #$1B'$B';    // ESC $B - JIS X 0208-1983
  ISO2022_JP_JISX0212 = #$1B'$(D';   // ESC $(D - JIS X 0212-1990

  // �����ⳣ��
  MIN_CONFIDENCE = 0.6;        // ��С���Ŷ�
  MAX_TEXT_SAMPLE = 16384;     // ����ı�������С��16KB��
  MIN_TEXT_SAMPLE = 256;       // ��С�ı�������С��256�ֽڣ�
  MAX_DETECTION_TIME = 1000;   // �����ʱ�䣨���룩

  // �ļ����ͳ���
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
  /// ��������ö��
  /// </summary>
  TEncodingType = (
    etUnknown,    // δ֪����
    etANSI,       // ANSI����
    etASCII,      // ASCII����
    etUTF8,       // UTF-8���루��BOM��
    etUTF8BOM,    // UTF-8���루��BOM��
    etUTF16LE,    // UTF-16 Little Endian����
    etUTF16BE,    // UTF-16 Big Endian����
    etUTF32LE,    // UTF-32 Little Endian����
    etUTF32BE,    // UTF-32 Big Endian����
    etGBK,        // GBK����
    etGB2312,     // GB2312����
    etGB18030,    // GB18030����
    etBig5,       // Big5����
    etShiftJIS,   // Shift-JIS����
    etEUCJP,      // EUC-JP����
    etEUCKR,      // EUC-KR����
    etBinary      // �������ļ�
  );

  /// <summary>
  /// �����ⷽ��ö��
  /// </summary>
  TEncodingDetectionMethod = (
    edmBOM,                // ͨ��BOM���
    edmASCII,              // ��ASCII���
    edmFileType,           // �ļ������ж�
    edmUTF8Validation,     // UTF-8��Ч�Լ��
    edmChineseCharacters,  // �����ַ����
    edmJapaneseCharacters, // �����ַ����
    edmKoreanCharacters,   // �����ַ����
    edmSystemLanguage,     // ϵͳ���Ի����ж�
    edmFileName,           // �ļ����ж�
    edmStatistical,        // ͳ�Ʒ���
    edmHeuristic,          // ���ʽ����
    edmUserHistory,        // �û���ʷ��¼
    edmUnknown             // δ֪����
  );

  /// <summary>
  /// ����ת������ö��
  /// </summary>
  TEncodingConversionType = (
    ectSameEncoding,       // ��ͬ���루����ת����
    ectAddBOM,             // ���BOM
    ectRemoveBOM,          // �Ƴ�BOM
    ectANSIToUTF8,         // ANSI��UTF-8
    ectUTF8ToANSI,         // UTF-8��ANSI
    ectANSIToUTF16LE,      // ANSI��UTF-16 LE
    ectUTF16LEToANSI,      // UTF-16 LE��ANSI
    ectUTF8ToUTF16LE,      // UTF-8��UTF-16 LE
    ectUTF16LEToUTF8,      // UTF-16 LE��UTF-8
    ectOther               // ����ת��
  );

  /// <summary>
  /// BOM�������¼
  /// </summary>
  TBOMDetectionResult = record
    BOMType: Integer;      // BOM����
    BOMLength: Integer;    // BOM���ȣ��ֽ�����
    Encoding: string;      // ��Ӧ�ı�������
    CodePage: Integer;     // ��Ӧ�Ĵ���ҳ
  end;

  /// <summary>
  /// ����������¼
  /// </summary>
  TEncodingDetectionResult = record
    Encoding: string;        // ��⵽�ı�������
    HasBOM: Boolean;         // �Ƿ���BOM
    Confidence: Double;      // ���Ŷ� (0.0-1.0)
    DetectionMethod: string; // ��ⷽ��
    ElapsedTime: Int64;      // ����ʱ(����)
  end;

  /// <summary>
  /// ����ת�������¼
  /// </summary>
  TEncodingConversionResult = record
    Success: Boolean;           // �Ƿ�ɹ�
    ErrorMessage: string;       // ������Ϣ
    SourceEncoding: string;     // Դ����
    TargetEncoding: string;     // Ŀ�����
    BytesProcessed: Int64;      // ������ֽ���
    ElapsedTime: Int64;         // ��ʱ(����)
  end;

// BOM���ͳ���
const
  BOM_NONE = 0;      // ��BOM
  BOM_UTF8 = 1;      // UTF-8 BOM (EF BB BF)
  BOM_UTF16LE = 2;   // UTF-16 Little Endian BOM (FF FE)
  BOM_UTF16BE = 3;   // UTF-16 Big Endian BOM (FE FF)
  BOM_UTF32LE = 4;   // UTF-32 Little Endian BOM (FF FE 00 00)
  BOM_UTF32BE = 5;   // UTF-32 Big Endian BOM (00 00 FE FF)

implementation

// BOM �ֽ����鳣��
const
  UTF8_BOM: array[0..2] of Byte = ($EF, $BB, $BF);
  UTF16_LE_BOM: array[0..1] of Byte = ($FF, $FE);
  UTF16_BE_BOM: array[0..1] of Byte = ($FE, $FF);
  UTF32_LE_BOM: array[0..3] of Byte = ($FF, $FE, $00, $00);
  UTF32_BE_BOM: array[0..3] of Byte = ($00, $00, $FE, $FF);

end.
