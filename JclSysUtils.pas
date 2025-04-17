unit JclSysUtils;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows;

// 获取当前ANSI代码页
function GetACP: Cardinal;

// 没有需要实现的功能，此单元只是为了满足引用需求

implementation

// 获取当前ANSI代码页
function GetACP: Cardinal;
begin
  Result := GetACP;
end;

end.