unit UtilsJclException;

{
  JCL 异常追踪系统
  功能：
  - 全局异常捕获和追踪
  - 详细的调用栈信息
  - 异常日志自动保存
  - 系统信息收集
  
  依赖：JEDI Code Library (JCL) 2024.12
}

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows
  {$IFDEF USE_JCL}
  , JclDebug
  {$ENDIF}
  ;

type
  /// <summary>
  /// JCL 异常处理器类
  /// 提供全局异常追踪和详细的调试信息
  /// </summary>
  TJclExceptionHandler = class
  private
    FLogFile: string;
    FEnabled: Boolean;
    FLogPath: string;
    FAutoSave: Boolean;
    
    procedure InitializeJCL;
    procedure ShutdownJCL;
    function FormatExceptionInfo(E: Exception): string;
    function GetSystemInfo: string;
    procedure WriteToLogFile(const Text: string);
  public
    constructor Create(const LogPath: string = '');
    destructor Destroy; override;
    
    /// <summary>启用异常追踪</summary>
    procedure Enable;
    
    /// <summary>禁用异常追踪</summary>
    procedure Disable;
    
    /// <summary>保存异常报告到文件</summary>
    procedure SaveExceptionReport(E: Exception; const AdditionalInfo: string = '');
    
    /// <summary>获取当前调用栈信息</summary>
    function GetStackTrace: string;
    
    /// <summary>获取最后一次异常的详细信息</summary>
    function GetLastExceptionInfo: string;
    
    /// <summary>清空异常日志文件</summary>
    procedure ClearLogFile;
    
    property Enabled: Boolean read FEnabled;
    property LogFile: string read FLogFile;
    property AutoSave: Boolean read FAutoSave write FAutoSave;
  end;

/// <summary>全局异常处理器实例</summary>
function ExceptionHandler: TJclExceptionHandler;

{$IFDEF USE_JCL}
/// <summary>格式化调用栈信息</summary>
function FormatStackTrace(const StackInfo: TJclStackInfoList): string;
{$ENDIF}

implementation

{$WARN IMPLICIT_STRING_CAST OFF}

uses
  System.IOUtils, System.DateUtils;

var
  GExceptionHandler: TJclExceptionHandler = nil;

function ExceptionHandler: TJclExceptionHandler;
begin
  if not Assigned(GExceptionHandler) then
    GExceptionHandler := TJclExceptionHandler.Create;
  Result := GExceptionHandler;
end;

{$IFDEF USE_JCL}
function FormatStackTrace(const StackInfo: TJclStackInfoList): string;
var
  i: Integer;
  Info: TJclLocationInfo;
  Builder: TStringBuilder;
begin
  Builder := TStringBuilder.Create;
  try
    Builder.AppendLine('调用栈信息:');
    Builder.AppendLine('----------------------------------------');
    
    for i := 0 to StackInfo.Count - 1 do
    begin
      Info := StackInfo.Items[i];
      Builder.AppendFormat('[%d] %s', [i, Info.UnitName]);
      
      if Info.ProcedureName <> '' then
        Builder.AppendFormat('.%s', [Info.ProcedureName]);
        
      if Info.LineNumber > 0 then
        Builder.AppendFormat(' (Line %d)', [Info.LineNumber]);
        
      if Info.SourceName <> '' then
        Builder.AppendFormat(' in %s', [Info.SourceName]);
        
      Builder.AppendLine;
    end;
    
    Builder.AppendLine('----------------------------------------');
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;
{$ENDIF}

{ TJclExceptionHandler }

constructor TJclExceptionHandler.Create(const LogPath: string);
begin
  inherited Create;
  
  FEnabled := False;
  FAutoSave := True;
  
  // 设置日志路径
  if LogPath <> '' then
    FLogPath := LogPath
  else
    FLogPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Logs');
    
  // 确保日志目录存在
  if not TDirectory.Exists(FLogPath) then
    TDirectory.CreateDirectory(FLogPath);
    
  // 生成日志文件名（带时间戳）
  FLogFile := TPath.Combine(FLogPath, 
    Format('Exception_%s.log', [FormatDateTime('yyyymmdd_hhnnss', Now)]));
end;

destructor TJclExceptionHandler.Destroy;
begin
  if FEnabled then
    Disable;
  inherited;
end;

procedure TJclExceptionHandler.InitializeJCL;
begin
  // 初始化 JCL 异常追踪
  try
    // JCL 异常追踪已在主程序中启用
    // 这里只需记录日志
  except
    on E: Exception do
      WriteToLogFile('初始化 JCL 失败: ' + E.Message);
  end;
end;

procedure TJclExceptionHandler.ShutdownJCL;
begin
  try
    // JCL 异常追踪会在主程序退出时自动关闭
    // 这里只需记录日志
  except
    on E: Exception do
      WriteToLogFile('关闭 JCL 失败: ' + E.Message);
  end;
end;

procedure TJclExceptionHandler.Enable;
begin
  if not FEnabled then
  begin
    InitializeJCL;
    FEnabled := True;
    WriteToLogFile('========================================');
    WriteToLogFile('JCL 异常追踪系统已启用');
    {$WARN IMPLICIT_STRING_CAST OFF}
    WriteToLogFile('时间: ' + DateTimeToStr(Now));
    WriteToLogFile(GetSystemInfo);
    {$WARN IMPLICIT_STRING_CAST ON}
    WriteToLogFile('========================================');
  end;
end;

procedure TJclExceptionHandler.Disable;
begin
  if FEnabled then
  begin
    WriteToLogFile('========================================');
    {$WARN IMPLICIT_STRING_CAST OFF}
    WriteToLogFile('JCL 异常追踪系统已禁用');
    {$WARN IMPLICIT_STRING_CAST ON}
    {$WARN IMPLICIT_STRING_CAST OFF}
    WriteToLogFile('时间: ' + DateTimeToStr(Now));
    WriteToLogFile('========================================');
    {$WARN IMPLICIT_STRING_CAST ON}
    ShutdownJCL;
    FEnabled := False;
  end;
end;

function TJclExceptionHandler.FormatExceptionInfo(E: Exception): string;
var
  Builder: TStringBuilder;
  {$IFDEF USE_JCL}
  StackList: TJclStackInfoList;
  {$ENDIF}
begin
  Builder := TStringBuilder.Create;
  try
    Builder.AppendLine('========================================');
    Builder.AppendLine('上常信息');
    Builder.AppendLine('========================================');
    {$WARN IMPLICIT_STRING_CAST OFF}
    Builder.AppendFormat('时间: %s', [DateTimeToStr(Now)]).AppendLine;
    Builder.AppendFormat('上常类型: %s', [E.ClassName]).AppendLine;
    Builder.AppendFormat('上常消息: %s', [E.Message]).AppendLine;
    {$WARN IMPLICIT_STRING_CAST ON}
    
    {$IFDEF USE_JCL}
    // 获取 JCL 调用栈
    StackList := JclGetExceptionStackList(E);
    if Assigned(StackList) then
    begin
      Builder.AppendLine;
      Builder.Append(FormatStackTrace(StackList));
    end
    else
    {$ENDIF}
    begin
      Builder.AppendLine;
      Builder.AppendLine('调用栈信息不可用');
    end;
    
    Builder.AppendLine('========================================');
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

function TJclExceptionHandler.GetSystemInfo: string;
var
  Builder: TStringBuilder;
  MemStatus: TMemoryStatusEx;
begin
  Builder := TStringBuilder.Create;
  try
    Builder.AppendLine('系统信息:');
    Builder.AppendLine('----------------------------------------');
    
    // 操作系统信息
    {$WARN IMPLICIT_STRING_CAST OFF}
    Builder.AppendFormat('OS 版本: Windows %d.%d', 
      [Win32MajorVersion, Win32MinorVersion]).AppendLine;
    Builder.AppendFormat('构建号: %d', [Win32BuildNumber]).AppendLine;
    {$WARN IMPLICIT_STRING_CAST ON}
    
    // 内存信息
    MemStatus.dwLength := SizeOf(MemStatus);
    if GlobalMemoryStatusEx(MemStatus) then
    begin
      Builder.AppendFormat('物理内存: %d MB / %d MB', 
        [(MemStatus.ullTotalPhys - MemStatus.ullAvailPhys) div (1024 * 1024),
         MemStatus.ullTotalPhys div (1024 * 1024)]).AppendLine;
      Builder.AppendFormat('虚拟内存: %d MB / %d MB', 
        [(MemStatus.ullTotalVirtual - MemStatus.ullAvailVirtual) div (1024 * 1024),
         MemStatus.ullTotalVirtual div (1024 * 1024)]).AppendLine;
    end;
    
    // 应用程序信息
    {$WARN IMPLICIT_STRING_CAST OFF}
    Builder.AppendFormat('程序路径: %s', [ParamStr(0)]).AppendLine;
    Builder.AppendFormat('工作目录: %s', [GetCurrentDir]).AppendLine;
    {$WARN IMPLICIT_STRING_CAST ON}
    Builder.AppendLine('----------------------------------------');
    
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

procedure TJclExceptionHandler.WriteToLogFile(const Text: string);
var
  FileStream: TFileStream;
  Writer: TStreamWriter;
  FileMode: Word;
begin
  try
    // 如果文件存在则追加，否则创建新文件
    if TFile.Exists(FLogFile) then
      FileMode := fmOpenWrite or fmShareDenyWrite
    else
      FileMode := fmCreate or fmShareDenyWrite;
      
    FileStream := TFileStream.Create(FLogFile, FileMode);
    try
      // 定位到文件末尾
      if FileMode = (fmOpenWrite or fmShareDenyWrite) then
        FileStream.Seek(0, soEnd);
        
      Writer := TStreamWriter.Create(FileStream, TEncoding.UTF8);
      try
        Writer.WriteLine(Text);
      finally
        Writer.Free;
      end;
    finally
      FileStream.Free;
    end;
  except
    // 写入日志失败时不抛出异常，避免递归
  end;
end;

procedure TJclExceptionHandler.SaveExceptionReport(E: Exception; 
  const AdditionalInfo: string);
var
  Report: string;
begin
  if not FEnabled then
    Exit;
    
  try
    Report := FormatExceptionInfo(E);
    
    if AdditionalInfo <> '' then
    begin
      Report := Report + sLineBreak + '附加信息:' + sLineBreak + 
                AdditionalInfo + sLineBreak;
    end;
    
    WriteToLogFile(Report);
  except
    // 异常处理器本身不应该抛出异常
  end;
end;

function TJclExceptionHandler.GetStackTrace: string;
{$IFDEF USE_JCL}
var
  StackList: TJclStackInfoList;
{$ENDIF}
begin
  Result := '';
  
  if not FEnabled then
    Exit;
  
  {$IFDEF USE_JCL}
  try
    StackList := JclCreateStackList(False, 0, nil);
    if Assigned(StackList) then
    try
      Result := FormatStackTrace(StackList);
    finally
      StackList.Free;
    end;
  except
    {$WARN IMPLICIT_STRING_CAST OFF}
    Result := '获取调用栈失败';
    {$WARN IMPLICIT_STRING_CAST ON}
  end;
  {$ELSE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  Result := '调用栈信息不可用（未启用 JCL）';
  {$WARN IMPLICIT_STRING_CAST ON}
  {$ENDIF}
end;

function TJclExceptionHandler.GetLastExceptionInfo: string;
begin
  Result := '';
  
  if not FEnabled then
    Exit;
    
  try
    if TFile.Exists(FLogFile) then
      Result := TFile.ReadAllText(FLogFile, TEncoding.UTF8);
  except
    Result := '无法读取异常日志文件';
  end;
end;

procedure TJclExceptionHandler.ClearLogFile;
begin
  try
    if TFile.Exists(FLogFile) then
      TFile.Delete(FLogFile);
  except
    // 忽略删除失败
  end;
end;

initialization
  // 自动创建全局实例
  GExceptionHandler := nil;

finalization
  // 自动释放全局实例
  if Assigned(GExceptionHandler) then
  begin
    GExceptionHandler.Free;
    GExceptionHandler := nil;
  end;

end.
