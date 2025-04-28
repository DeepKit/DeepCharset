unit UtilsEncodingConstants;

interface

const
  // 编码常量定义
  ENCODING_UNKNOWN = 'unknown';
  ENCODING_ASCII = 'ascii';
  ENCODING_UTF8 = 'utf-8';
  ENCODING_UTF8_BOM = 'utf-8-bom';
  ENCODING_UTF16_LE = 'utf-16le';
  ENCODING_UTF16_BE = 'utf-16be';
  ENCODING_UTF32_LE = 'utf-32le';
  ENCODING_UTF32_BE = 'utf-32be';
  ENCODING_GB18030 = 'gb18030';
  ENCODING_GBK = 'gbk';
  ENCODING_BIG5 = 'big5';
  ENCODING_SHIFT_JIS = 'shift-jis';
  ENCODING_EUC_JP = 'euc-jp';
  ENCODING_EUC_KR = 'euc-kr';
  ENCODING_WINDOWS_1251 = 'windows-1251';
  ENCODING_WINDOWS_1252 = 'windows-1252';
  ENCODING_WINDOWS_1253 = 'windows-1253';
  ENCODING_WINDOWS_1254 = 'windows-1254';
  ENCODING_WINDOWS_1255 = 'windows-1255';
  ENCODING_KOI8_R = 'koi8-r';
  ENCODING_KOI8_U = 'koi8-u';
  ENCODING_ISO2022_JP = 'iso-2022-jp';
  ENCODING_EUC_TW = 'euc-tw';
  ENCODING_CP949 = 'cp949';
  ENCODING_WINDOWS_1256 = 'windows-1256';
  ENCODING_WINDOWS_1257 = 'windows-1257';
  ENCODING_WINDOWS_1258 = 'windows-1258';

  // BOM 定义
  UTF8_BOM: array[0..2] of Byte = ($EF, $BB, $BF);
  UTF16_LE_BOM: array[0..1] of Byte = ($FF, $FE);
  UTF16_BE_BOM: array[0..1] of Byte = ($FE, $FF);
  UTF32_LE_BOM: array[0..3] of Byte = ($FF, $FE, $00, $00);
  UTF32_BE_BOM: array[0..3] of Byte = ($00, $00, $FE, $FF);

  // ISO-2022-JP 转义序列
  ISO2022_JP_ASCII    = #$1B'(B';    // ESC (B - ASCII
  ISO2022_JP_JISX0201 = #$1B'(J';    // ESC (J - JIS X 0201-1976 片假名
  ISO2022_JP_JISX0208 = #$1B'$B';    // ESC $B - JIS X 0208-1983
  ISO2022_JP_JISX0212 = #$1B'$(D';   // ESC $(D - JIS X 0212-1990

implementation

end. 