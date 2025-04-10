unit JclAnsiStrings;

interface

uses
  System.SysUtils, System.Classes;

// AnsiString处理函数
function StrLen(const S: PAnsiChar): Cardinal;
function StrCopy(Dest: PAnsiChar; const Source: PAnsiChar): PAnsiChar;

implementation

// 获取字符串长度
function StrLen(const S: PAnsiChar): Cardinal;
begin
  Result := System.SysUtils.StrLen(S);
end;

// 复制字符串
function StrCopy(Dest: PAnsiChar; const Source: PAnsiChar): PAnsiChar;
begin
  Result := System.SysUtils.StrCopy(Dest, Source);
end;

end.
