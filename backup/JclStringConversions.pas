unit JclStringConversions;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows;

// 将UTF-8编码的字符串转换为宽字符串
function UTF8ToWideString(const S: PAnsiChar; Len: Integer): WideString;

// 将指定代码页的字符串转换为Unicode字符串
function StringToUnicodeString(const S: PAnsiChar; CodePage: Cardinal; Len: Integer = -1): WideString;

// 扩展版本的字符串转换，支持更多代码页
function StringToUnicodeStringEx(const S: PAnsiChar; CodePage: Cardinal; Len: Integer = -1): UnicodeString;

// 将Unicode字符串转换为指定代码页的字符串
function UnicodeStringToStringEx(const WS: UnicodeString; CodePage: Cardinal): AnsiString;

// 代码页常量
const
  CP_UTF8 = 65001;

implementation

// 将UTF-8编码的字符串转换为宽字符串
function UTF8ToWideString(const S: PAnsiChar; Len: Integer): WideString;
var
  InputLength, OutputLength: Integer;
  TempBuffer: array of WideChar;
begin
  if (S = nil) or (Len <= 0) then
  begin
    Result := '';
    Exit;
  end;

  InputLength := Len;
  OutputLength := Winapi.Windows.MultiByteToWideChar(CP_UTF8, 0, S, InputLength, nil, 0);
  
  if OutputLength > 0 then
  begin
    SetLength(TempBuffer, OutputLength);
    Winapi.Windows.MultiByteToWideChar(CP_UTF8, 0, S, InputLength, @TempBuffer[0], OutputLength);
    SetLength(Result, OutputLength);
    Move(TempBuffer[0], PWideChar(Result)^, OutputLength * SizeOf(WideChar));
  end
  else
    Result := '';
end;

// 将指定代码页的字符串转换为Unicode字符串
function StringToUnicodeString(const S: PAnsiChar; CodePage: Cardinal; Len: Integer = -1): WideString;
var
  InputLength, OutputLength: Integer;
  TempBuffer: array of WideChar;
begin
  if (S = nil) then
  begin
    Result := '';
    Exit;
  end;

  if Len < 0 then
    InputLength := StrLen(S)
  else
    InputLength := Len;
    
  if InputLength = 0 then
  begin
    Result := '';
    Exit;
  end;

  OutputLength := Winapi.Windows.MultiByteToWideChar(CodePage, 0, S, InputLength, nil, 0);
  
  if OutputLength > 0 then
  begin
    SetLength(TempBuffer, OutputLength);
    Winapi.Windows.MultiByteToWideChar(CodePage, 0, S, InputLength, @TempBuffer[0], OutputLength);
    SetLength(Result, OutputLength);
    Move(TempBuffer[0], PWideChar(Result)^, OutputLength * SizeOf(WideChar));
  end
  else
    Result := '';
end;

// 扩展版本的字符串转换，支持更多代码页
function StringToUnicodeStringEx(const S: PAnsiChar; CodePage: Cardinal; Len: Integer = -1): UnicodeString;
begin
  Result := StringToUnicodeString(S, CodePage, Len);
end;

// 将Unicode字符串转换为指定代码页的字符串
function UnicodeStringToStringEx(const WS: UnicodeString; CodePage: Cardinal): AnsiString;
var
  InputLength, OutputLength: Integer;
  TempBuffer: array of AnsiChar;
begin
  InputLength := Length(WS);
  
  if InputLength = 0 then
  begin
    Result := '';
    Exit;
  end;
  
  OutputLength := Winapi.Windows.WideCharToMultiByte(CodePage, 0, PWideChar(WS), InputLength, 
                                                   nil, 0, nil, nil);
  
  if OutputLength > 0 then
  begin
    SetLength(TempBuffer, OutputLength);
    Winapi.Windows.WideCharToMultiByte(CodePage, 0, PWideChar(WS), InputLength, 
                                       @TempBuffer[0], OutputLength, nil, nil);
    SetLength(Result, OutputLength);
    Move(TempBuffer[0], PAnsiChar(Result)^, OutputLength);
  end
  else
    Result := '';
end;

end. 