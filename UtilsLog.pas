unit UtilsLog;

interface

uses
  System.SysUtils, System.Classes;

type
  TUtilsLog = class
  public
    class procedure AddLog(const Msg: string); overload;
    class procedure AddLog(const Msg: string; const Args: array of const); overload;
  end;

implementation

uses
  Vcl.Forms, Winapi.Windows;

{ TUtilsLog }

class procedure TUtilsLog.AddLog(const Msg: string);
begin
  // 这里可以根据需要实现日志记录逻辑
  // 例如：写入文件、显示在界面上等
  OutputDebugString(PChar(FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz ', Now) + Msg));
end;

class procedure TUtilsLog.AddLog(const Msg: string; const Args: array of const);
begin
  AddLog(Format(Msg, Args));
end;

end. 