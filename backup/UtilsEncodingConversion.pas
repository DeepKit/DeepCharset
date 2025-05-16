unit UtilsEncodingConversion;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, UtilsEncodingConstants;

/// <summary>
/// 将字符串从指定代码页转换为Unicode字符串
/// </summary>
function StringToUnicodeString(const Source: PAnsiChar; CodePage: Integer; SourceLength: Integer): UnicodeString;

/// <summary>
/// 将Unicode字符串转换为指定代码页的字符串
/// </summary>
function UnicodeStringToString(const Source: UnicodeString; CodePage: Integer): AnsiString;

/// <summary>
/// 获取编码对应的代码页
/// </summary>
function GetEncodingCodePage(const EncodingName: string): Integer;

implementation

function StringToUnicodeString(const Source: PAnsiChar; CodePage: Integer; SourceLength: Integer): UnicodeString;
var
  WideLen: Integer;
  WideStr: UnicodeString;
begin
  if (Source = nil) or (SourceLength <= 0) then
    Exit('');

  // 计算所需的Unicode字符数
  WideLen := MultiByteToWideChar(CodePage, 0, Source, SourceLength, nil, 0);
  if WideLen <= 0 then
    raise Exception.CreateFmt('无法将代码页 %d 的字符串转换为Unicode: %d', [CodePage, GetLastError]);

  // 分配Unicode字符串
  SetLength(WideStr, WideLen);

  // 执行转换
  if MultiByteToWideChar(CodePage, 0, Source, SourceLength, PWideChar(WideStr), WideLen) <> WideLen then
    raise Exception.CreateFmt('转换代码页 %d 的字符串到Unicode失败: %d', [CodePage, GetLastError]);

  Result := WideStr;
end;

function UnicodeStringToString(const Source: UnicodeString; CodePage: Integer): AnsiString;
var
  ByteLen: Integer;
  ByteStr: AnsiString;
begin
  if Source = '' then
    Exit('');

  // 计算所需的字节数
  ByteLen := WideCharToMultiByte(CodePage, 0, PWideChar(Source), Length(Source), nil, 0, nil, nil);
  if ByteLen <= 0 then
    raise Exception.CreateFmt('无法将Unicode字符串转换为代码页 %d: %d', [CodePage, GetLastError]);

  // 分配字节字符串
  SetLength(ByteStr, ByteLen);

  // 执行转换
  if WideCharToMultiByte(CodePage, 0, PWideChar(Source), Length(Source), PAnsiChar(ByteStr), ByteLen, nil, nil) <> ByteLen then
    raise Exception.CreateFmt('转换Unicode字符串到代码页 %d 失败: %d', [CodePage, GetLastError]);

  Result := ByteStr;
end;

function GetEncodingCodePage(const EncodingName: string): Integer;
var
  NormalizedName: string;
begin
  // 标准化编码名称
  NormalizedName := EncodingName.ToLower.Replace('-', '').Replace('_', '').Replace(' ', '');

  // 返回对应的代码页
  if (NormalizedName = 'ascii') then
    Result := CP_ASCII
  else if (NormalizedName = 'utf8') or (NormalizedName = 'utf8withoutbom') then
    Result := CP_UTF8
  else if (NormalizedName = 'utf8withbom') then
    Result := CP_UTF8
  else if (NormalizedName = 'utf16le') or (NormalizedName = 'utf16') or (NormalizedName = 'unicode') then
    Result := CP_UTF16LE
  else if (NormalizedName = 'utf16be') then
    Result := CP_UTF16BE
  else if (NormalizedName = 'utf32le') or (NormalizedName = 'utf32') then
    Result := CP_UTF32LE
  else if (NormalizedName = 'utf32be') then
    Result := CP_UTF32BE
  else if (NormalizedName = 'gb18030') then
    Result := CP_GB18030
  else if (NormalizedName = 'gb2312') then
    Result := CP_GBK
  else if (NormalizedName = 'gbk') then
    Result := CP_GBK
  else if (NormalizedName = 'big5') then
    Result := CP_BIG5
  else if (NormalizedName = 'shiftjis') or (NormalizedName = 'sjis') then
    Result := CP_SHIFT_JIS
  else if (NormalizedName = 'eucjp') then
    Result := CP_EUC_JP
  else if (NormalizedName = 'euckr') then
    Result := CP_EUC_KR
  else if (NormalizedName = 'windows1250') then
    Result := 1250  // Windows-1250 (中欧)
  else if (NormalizedName = 'windows1251') then
    Result := 1251  // Windows-1251 (西里尔文)
  else if (NormalizedName = 'windows1252') or (NormalizedName = 'ansi') then
    Result := 1252  // Windows-1252 (西欧)
  else if (NormalizedName = 'windows1253') then
    Result := 1253  // Windows-1253 (希腊文)
  else if (NormalizedName = 'windows1254') then
    Result := 1254  // Windows-1254 (土耳其文)
  else if (NormalizedName = 'windows1255') then
    Result := 1255  // Windows-1255 (希伯来文)
  else if (NormalizedName = 'windows1256') then
    Result := 1256  // Windows-1256 (阿拉伯文)
  else if (NormalizedName = 'windows1257') then
    Result := 1257  // Windows-1257 (波罗的海文)
  else if (NormalizedName = 'windows1258') then
    Result := 1258  // Windows-1258 (越南文)
  else if (NormalizedName = 'iso88591') or (NormalizedName = 'latin1') then
    Result := CP_ISO_8859_1 // ISO-8859-1 (西欧)
  else if (NormalizedName = 'iso88592') or (NormalizedName = 'latin2') then
    Result := 28592 // ISO-8859-2 (中欧)
  else if (NormalizedName = 'iso88593') or (NormalizedName = 'latin3') then
    Result := 28593 // ISO-8859-3 (南欧)
  else if (NormalizedName = 'iso88594') or (NormalizedName = 'latin4') then
    Result := 28594 // ISO-8859-4 (北欧)
  else if (NormalizedName = 'iso88595') then
    Result := 28595 // ISO-8859-5 (西里尔文)
  else if (NormalizedName = 'iso88596') then
    Result := 28596 // ISO-8859-6 (阿拉伯文)
  else if (NormalizedName = 'iso88597') then
    Result := 28597 // ISO-8859-7 (希腊文)
  else if (NormalizedName = 'iso88598') then
    Result := 28598 // ISO-8859-8 (希伯来文)
  else if (NormalizedName = 'iso88599') then
    Result := 28599 // ISO-8859-9 (土耳其文)
  else if (NormalizedName = 'koi8r') then
    Result := 20866 // KOI8-R (俄文)
  else if (NormalizedName = 'koi8u') then
    Result := 21866 // KOI8-U (乌克兰文)
  else
    Result := GetACP; // 默认使用系统ANSI代码页
end;

end.
