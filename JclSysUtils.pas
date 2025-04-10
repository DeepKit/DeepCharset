unit JclSysUtils;

interface

uses
  System.SysUtils, System.Classes;

// 获取当前ANSI代码页
function GetACP: Cardinal;

// 没有需要实现的功能，此单元只是为了满足引用需求

implementation

// 获取当前ANSI代码页
function GetACP: Cardinal;
begin
  Result := System.SysUtils.DefaultSystemCodePage;
end;

end. 