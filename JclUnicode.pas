unit JclUnicode;

interface

// 因为JCL库函数已在JclStrings单元中实现，该单元主要用于满足引用需求
// 但我们提供一些基本的Unicode处理函数

uses
  System.SysUtils, System.Classes, Winapi.Windows;

// 转换Unicode字符串为多字节编码
function UnicodeToMultiByte(const Source: UnicodeString; CodePage: Cardinal): RawByteString;

// 将单字节编码转换为Unicode
function MultiByteToUnicode(const Source: RawByteString; CodePage: Cardinal): UnicodeString;

// 字符串编码转换辅助函数
function ConvertCodePage(const Source: RawByteString; SrcCodePage, DestCodePage: Integer): RawByteString;

implementation

uses
  JclStrings;

// 转换Unicode字符串为多字节编码
function UnicodeToMultiByte(const Source: UnicodeString; CodePage: Cardinal): RawByteString;
begin
  Result := UnicodeStringToStringEx(Source, CodePage);
end;

// 将单字节编码转换为Unicode
function MultiByteToUnicode(const Source: RawByteString; CodePage: Cardinal): UnicodeString;
begin
  Result := StringToUnicodeStringEx(PAnsiChar(Source), CodePage, Length(Source));
end;

// 字符串编码转换辅助函数
function ConvertCodePage(const Source: RawByteString; SrcCodePage, DestCodePage: Integer): RawByteString;
var
  UnicodeStr: UnicodeString;
begin
  UnicodeStr := MultiByteToUnicode(Source, SrcCodePage);
  Result := UnicodeToMultiByte(UnicodeStr, DestCodePage);
end;

end. 