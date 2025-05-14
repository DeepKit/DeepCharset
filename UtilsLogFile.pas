unit UtilsLogFile;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils;

// 日志写入函数
procedure LogWriteLine(const Message: string);

// 设置日志文件路径
procedure SetLogFilePath(const FilePath: string);

// 清空日志文件
procedure ClearLogFile;

// 获取日志文件路径
function GetLogFilePath: string;

implementation

var
  GLogFilePath: string = '';
  GLogFile: TextFile;
  GLogInitialized: Boolean = False;

// 初始化日志文件
procedure InitializeLog;
var
  LogDir: string;
begin
  if GLogInitialized then
    Exit;

  // 如果未设置日志文件路径，使用默认路径
  if GLogFilePath = '' then
  begin
    LogDir := TPath.Combine(TPath.GetDocumentsPath, 'TransSuccess');
    if not DirectoryExists(LogDir) then
      ForceDirectories(LogDir);
    GLogFilePath := TPath.Combine(LogDir, 'TransSuccess.log');
  end;

  // 初始化日志文件
  AssignFile(GLogFile, GLogFilePath);
  if not FileExists(GLogFilePath) then
    Rewrite(GLogFile)
  else
    Append(GLogFile);
  
  GLogInitialized := True;
end;

// 写入日志
procedure LogWriteLine(const Message: string);
begin
  try
    // 确保日志已初始化
    if not GLogInitialized then
      InitializeLog;

    // 写入日志
    WriteLn(GLogFile, Format('[%s] %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), Message]));
    Flush(GLogFile);
  except
    // 忽略日志写入错误
  end;
end;

// 设置日志文件路径
procedure SetLogFilePath(const FilePath: string);
begin
  // 如果日志已初始化，先关闭
  if GLogInitialized then
  begin
    CloseFile(GLogFile);
    GLogInitialized := False;
  end;

  // 设置新路径
  GLogFilePath := FilePath;
  
  // 重新初始化
  InitializeLog;
end;

// 清空日志文件
procedure ClearLogFile;
begin
  // 如果日志已初始化，先关闭
  if GLogInitialized then
  begin
    CloseFile(GLogFile);
    GLogInitialized := False;
  end;

  // 删除日志文件
  if FileExists(GLogFilePath) then
    DeleteFile(GLogFilePath);
  
  // 重新初始化
  InitializeLog;
end;

// 获取日志文件路径
function GetLogFilePath: string;
begin
  // 确保日志已初始化
  if not GLogInitialized then
    InitializeLog;
    
  Result := GLogFilePath;
end;

initialization
  // 在单元初始化时初始化日志
  InitializeLog;

finalization
  // 在单元结束时关闭日志文件
  if GLogInitialized then
    CloseFile(GLogFile);

end.
