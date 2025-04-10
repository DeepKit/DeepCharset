unit JclStringConversions;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows;

// 将UTF-8编码的字符串转换为宽字符串
function UTF8ToWideString(const S: PAnsiChar; Len: Integer): WideString;

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

end. 