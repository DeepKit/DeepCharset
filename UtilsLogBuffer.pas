unit UtilsLogBuffer;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs,
  System.DateUtils, System.TypInfo, Winapi.Windows;

type
  /// <summary>
  /// 日志缓冲区类型
  /// </summary>
  TLogBufferType = (lbtNone, lbtMemory, lbtFile, lbtBoth);

  /// <summary>
  /// 日志缓冲区模式
  /// </summary>
  TLogBufferMode = (lbmImmediate, lbmBuffered, lbmBatch);

  /// <summary>
  /// 日志文件轮换模式
  /// </summary>
  TLogRotationMode = (lrmNone, lrmSize, lrmDaily, lrmWeekly, lrmMonthly);

  /// <summary>
  /// 日志缓冲区配置
  /// </summary>
  TLogBufferConfig = record
    BufferType: TLogBufferType;     // 缓冲区类型
    BufferMode: TLogBufferMode;     // 缓冲区模式
    MaxBufferSize: Integer;         // 最大缓冲区大小
    FlushInterval: Integer;         // 刷新间隔（毫秒）
    LogFilePath: string;            // 日志文件路径
    AppendToFile: Boolean;          // 是否追加到文件
    EnableTimestamp: Boolean;       // 是否启用时间戳
    EnableThreadId: Boolean;        // 是否启用线程ID
    EnableLogLevel: Boolean;        // 是否启用日志级别
    MinLogLevel: Integer;           // 最小日志级别
    RotationMode: TLogRotationMode; // 日志文件轮换模式
    MaxLogFileSize: Int64;          // 最大日志文件大小（字节）
    MaxLogFiles: Integer;           // 最大日志文件数量
  end;

  /// <summary>
  /// 日志级别
  /// </summary>
  TLogLevel = (llDebug, llInfo, llWarning, llError, llFatal);

  /// <summary>
  /// 日志条目
  /// </summary>
  TLogEntry = record
    Timestamp: TDateTime;           // 时间戳
    ThreadId: Cardinal;             // 线程ID
    LogLevel: TLogLevel;            // 日志级别
    Message: string;                // 日志消息
  end;

  /// <summary>
  /// 日志缓冲区
  /// </summary>
  TLogBuffer = class
  private
    FConfig: TLogBufferConfig;      // 配置
    FBuffer: TList<TLogEntry>;      // 内存缓冲区
    FLogFile: TStreamWriter;        // 日志文件
    FLock: TCriticalSection;        // 线程同步锁
    FLogCallback: TProc<string>;    // 日志回调
    FEnabled: Boolean;              // 是否启用
    FLastFlushTime: TDateTime;      // 上次刷新时间
    FLastRotationDate: TDateTime;   // 上次轮换日期
    FCurrentLogFileSize: Int64;     // 当前日志文件大小

    procedure FlushBuffer;          // 刷新缓冲区
    function FormatLogEntry(const Entry: TLogEntry): string; // 格式化日志条目
    procedure CheckRotation;        // 检查是否需要轮换日志文件
    procedure RotateLogFile;        // 轮换日志文件
    function GetRotatedFileName: string; // 获取轮换后的文件名

  public
    constructor Create(const AConfig: TLogBufferConfig; ALogCallback: TProc<string> = nil);
    destructor Destroy; override;

    /// <summary>
    /// 获取默认配置
    /// </summary>
    class function GetDefaultConfig: TLogBufferConfig; static;

    /// <summary>
    /// 添加日志
    /// </summary>
    procedure Log(const Msg: string; LogLevel: TLogLevel = llInfo);

    /// <summary>
    /// 添加调试日志
    /// </summary>
    procedure Debug(const Msg: string);

    /// <summary>
    /// 添加信息日志
    /// </summary>
    procedure Info(const Msg: string);

    /// <summary>
    /// 添加警告日志
    /// </summary>
    procedure Warning(const Msg: string);

    /// <summary>
    /// 添加错误日志
    /// </summary>
    procedure Error(const Msg: string);

    /// <summary>
    /// 添加致命错误日志
    /// </summary>
    procedure Fatal(const Msg: string);

    /// <summary>
    /// 启用日志缓冲区
    /// </summary>
    procedure Enable;

    /// <summary>
    /// 禁用日志缓冲区
    /// </summary>
    procedure Disable;

    /// <summary>
    /// 清空缓冲区
    /// </summary>
    procedure Clear;

    /// <summary>
    /// 强制刷新缓冲区
    /// </summary>
    procedure Flush;

    /// <summary>
    /// 开始批处理模式
    /// </summary>
    procedure BeginBatch;

    /// <summary>
    /// 结束批处理模式
    /// </summary>
    procedure EndBatch;

    /// <summary>
    /// 获取缓冲区统计信息
    /// </summary>
    function GetStats: string;

    /// <summary>
    /// 配置
    /// </summary>
    property Config: TLogBufferConfig read FConfig write FConfig;

    /// <summary>
    /// 是否启用
    /// </summary>
    property Enabled: Boolean read FEnabled;
  end;

implementation

{ TLogBuffer }

procedure TLogBuffer.BeginBatch;
begin
  FLock.Enter;
  try
    FConfig.BufferMode := lbmBatch;
  finally
    FLock.Leave;
  end;
end;

procedure TLogBuffer.Clear;
begin
  FLock.Enter;
  try
    FBuffer.Clear;
  finally
    FLock.Leave;
  end;
end;

constructor TLogBuffer.Create(const AConfig: TLogBufferConfig; ALogCallback: TProc<string>);
begin
  inherited Create;

  // 初始化配置
  FConfig := AConfig;

  // 初始化缓冲区
  FBuffer := TList<TLogEntry>.Create;

  // 初始化线程同步锁
  FLock := TCriticalSection.Create;

  // 设置日志回调
  FLogCallback := ALogCallback;

  // 初始化日志文件
  if (FConfig.BufferType = lbtFile) or (FConfig.BufferType = lbtBoth) then
  begin
    try
      if FConfig.AppendToFile and FileExists(FConfig.LogFilePath) then
      begin
        FLogFile := TStreamWriter.Create(FConfig.LogFilePath, True, TEncoding.UTF8);
        // 获取当前日志文件大小
        var FileInfo := TFileStream.Create(FConfig.LogFilePath, fmOpenRead or fmShareDenyNone);
        try
          FCurrentLogFileSize := FileInfo.Size;
        finally
          FileInfo.Free;
        end;
      end
      else
      begin
        FLogFile := TStreamWriter.Create(FConfig.LogFilePath, False, TEncoding.UTF8);
        FCurrentLogFileSize := 0;
      end;

      FLogFile.AutoFlush := False;
    except
      on E: Exception do
      begin
        if Assigned(FLogCallback) then
          FLogCallback('无法创建日志文件: ' + FConfig.LogFilePath + ' - ' + E.Message);
        FLogFile := nil;
        FCurrentLogFileSize := 0;
      end;
    end;
  end;

  // 设置启用状态
  FEnabled := True;

  // 设置上次刷新时间
  FLastFlushTime := Now;

  // 设置上次轮换日期
  FLastRotationDate := Date;
end;

procedure TLogBuffer.Debug(const Msg: string);
begin
  Log(Msg, llDebug);
end;

destructor TLogBuffer.Destroy;
begin
  // 刷新缓冲区
  Flush;

  // 释放日志文件
  if Assigned(FLogFile) then
    FreeAndNil(FLogFile);

  // 释放缓冲区
  FreeAndNil(FBuffer);

  // 释放线程同步锁
  FreeAndNil(FLock);

  inherited;
end;

procedure TLogBuffer.Disable;
begin
  FLock.Enter;
  try
    FEnabled := False;
  finally
    FLock.Leave;
  end;
end;

procedure TLogBuffer.Enable;
begin
  FLock.Enter;
  try
    FEnabled := True;
  finally
    FLock.Leave;
  end;
end;

procedure TLogBuffer.EndBatch;
begin
  FLock.Enter;
  try
    FConfig.BufferMode := lbmBuffered;
    Flush;
  finally
    FLock.Leave;
  end;
end;

procedure TLogBuffer.Error(const Msg: string);
begin
  Log(Msg, llError);
end;

procedure TLogBuffer.Fatal(const Msg: string);
begin
  Log(Msg, llFatal);
end;

procedure TLogBuffer.Flush;
begin
  FLock.Enter;
  try
    FlushBuffer;
  finally
    FLock.Leave;
  end;
end;

procedure TLogBuffer.CheckRotation;
var
  NeedRotation: Boolean;
  CurrentDate: TDateTime;
begin
  NeedRotation := False;

  // 检查是否需要轮换日志文件
  case FConfig.RotationMode of
    lrmNone:
      NeedRotation := False;

    lrmSize:
      NeedRotation := (FCurrentLogFileSize >= FConfig.MaxLogFileSize) and (FConfig.MaxLogFileSize > 0);

    lrmDaily:
      begin
        CurrentDate := Date;
        NeedRotation := Trunc(CurrentDate) > Trunc(FLastRotationDate);
      end;

    lrmWeekly:
      begin
        CurrentDate := Date;
        NeedRotation := (DayOfWeek(CurrentDate) = 1) and (DayOfWeek(FLastRotationDate) <> 1);
      end;

    lrmMonthly:
      begin
        CurrentDate := Date;
        NeedRotation := (MonthOf(CurrentDate) <> MonthOf(FLastRotationDate)) or
                        (YearOf(CurrentDate) <> YearOf(FLastRotationDate));
      end;
  end;

  // 如果需要轮换日志文件
  if NeedRotation then
    RotateLogFile;
end;

function TLogBuffer.GetRotatedFileName: string;
var
  BaseName, Ext, Dir: string;
  Timestamp: string;
begin
  // 分解日志文件路径
  Dir := ExtractFilePath(FConfig.LogFilePath);
  BaseName := ChangeFileExt(ExtractFileName(FConfig.LogFilePath), '');
  Ext := ExtractFileExt(FConfig.LogFilePath);

  // 生成时间戳
  case FConfig.RotationMode of
    lrmDaily, lrmWeekly, lrmMonthly:
      Timestamp := FormatDateTime('yyyy-mm-dd', Date);
    else
      Timestamp := FormatDateTime('yyyy-mm-dd_hh-nn-ss', Now);
  end;

  // 构建轮换后的文件名
  Result := Dir + BaseName + '_' + Timestamp + Ext;

  // 确保文件名唯一
  if FileExists(Result) then
  begin
    var i := 1;
    while FileExists(Dir + BaseName + '_' + Timestamp + '_' + IntToStr(i) + Ext) do
      Inc(i);
    Result := Dir + BaseName + '_' + Timestamp + '_' + IntToStr(i) + Ext;
  end;
end;

procedure TLogBuffer.RotateLogFile;
var
  RotatedFileName: string;
  OldFiles: TStringList;
  i: Integer;
begin
  // 如果日志文件不存在，直接返回
  if not Assigned(FLogFile) then
    Exit;

  try
    // 关闭当前日志文件
    FLogFile.Flush;
    FreeAndNil(FLogFile);

    // 获取轮换后的文件名
    RotatedFileName := GetRotatedFileName;

    // 重命名当前日志文件
    if FileExists(FConfig.LogFilePath) then
    begin
      try
        RenameFile(FConfig.LogFilePath, RotatedFileName);
      except
        on E: Exception do
        begin
          if Assigned(FLogCallback) then
            FLogCallback('轮换日志文件失败: ' + E.Message);
        end;
      end;
    end;

    // 创建新的日志文件
    FLogFile := TStreamWriter.Create(FConfig.LogFilePath, False, TEncoding.UTF8);
    FLogFile.AutoFlush := False;
    FCurrentLogFileSize := 0;

    // 更新上次轮换日期
    FLastRotationDate := Date;

    // 删除多余的日志文件
    if FConfig.MaxLogFiles > 0 then
    begin
      OldFiles := TStringList.Create;
      try
        // 获取所有日志文件
        var Dir := ExtractFilePath(FConfig.LogFilePath);
        var BaseName := ChangeFileExt(ExtractFileName(FConfig.LogFilePath), '');
        var Ext := ExtractFileExt(FConfig.LogFilePath);
        var SearchPattern := Dir + BaseName + '_*' + Ext;

        var SR: TSearchRec;
        if FindFirst(SearchPattern, faAnyFile, SR) = 0 then
        begin
          repeat
            OldFiles.Add(Dir + SR.Name);
          until FindNext(SR) <> 0;
          System.SysUtils.FindClose(SR);
        end;

        // 按修改日期排序
        OldFiles.Sort;

        // 删除多余的日志文件
        for i := FConfig.MaxLogFiles to OldFiles.Count - 1 do
        begin
          try
            System.SysUtils.DeleteFile(PWideChar(OldFiles[i]));
          except
            on E: Exception do
            begin
              if Assigned(FLogCallback) then
                FLogCallback('删除旧日志文件失败: ' + OldFiles[i] + ' - ' + E.Message);
            end;
          end;
        end;
      finally
        OldFiles.Free;
      end;
    end;

    // 记录日志轮换信息
    if Assigned(FLogCallback) then
      FLogCallback('日志文件已轮换: ' + RotatedFileName);
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('日志轮换过程中出错: ' + E.Message);
    end;
  end;
end;

procedure TLogBuffer.FlushBuffer;
var
  i: Integer;
  FormattedLog: string;
  LogSize: Integer;
begin
  // 如果缓冲区为空，直接返回
  if FBuffer.Count = 0 then
    Exit;

  // 如果启用了文件日志
  if Assigned(FLogFile) and ((FConfig.BufferType = lbtFile) or (FConfig.BufferType = lbtBoth)) then
  begin
    try
      // 检查是否需要轮换日志文件
      CheckRotation;

      // 写入所有日志条目
      for i := 0 to FBuffer.Count - 1 do
      begin
        FormattedLog := FormatLogEntry(FBuffer[i]);
        FLogFile.WriteLine(FormattedLog);

        // 更新日志文件大小
        LogSize := Length(FormattedLog) + 2; // +2 for CRLF
        FCurrentLogFileSize := FCurrentLogFileSize + LogSize;
      end;

      // 刷新文件
      FLogFile.Flush;

      // 再次检查是否需要轮换日志文件
      CheckRotation;
    except
      on E: Exception do
      begin
        if Assigned(FLogCallback) then
          FLogCallback('写入日志文件失败: ' + E.Message);
      end;
    end;
  end;

  // 如果启用了内存日志
  if Assigned(FLogCallback) and ((FConfig.BufferType = lbtMemory) or (FConfig.BufferType = lbtBoth)) then
  begin
    try
      // 写入所有日志条目
      for i := 0 to FBuffer.Count - 1 do
      begin
        FormattedLog := FormatLogEntry(FBuffer[i]);
        FLogCallback(FormattedLog);
      end;
    except
      on E: Exception do
      begin
        // 忽略异常
      end;
    end;
  end;

  // 清空缓冲区
  FBuffer.Clear;

  // 更新上次刷新时间
  FLastFlushTime := Now;
end;

function TLogBuffer.FormatLogEntry(const Entry: TLogEntry): string;
var
  LogLevelStr: string;
begin
  // 格式化日志级别
  case Entry.LogLevel of
    llDebug: LogLevelStr := 'DEBUG';
    llInfo: LogLevelStr := 'INFO';
    llWarning: LogLevelStr := 'WARN';
    llError: LogLevelStr := 'ERROR';
    llFatal: LogLevelStr := 'FATAL';
  end;

  // 格式化日志条目
  Result := '';

  // 添加时间戳
  if FConfig.EnableTimestamp then
    Result := Result + FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Entry.Timestamp) + ' ';

  // 添加线程ID
  if FConfig.EnableThreadId then
    Result := Result + '[' + IntToStr(Entry.ThreadId) + '] ';

  // 添加日志级别
  if FConfig.EnableLogLevel then
    Result := Result + LogLevelStr + ': ';

  // 添加日志消息
  Result := Result + Entry.Message;
end;

class function TLogBuffer.GetDefaultConfig: TLogBufferConfig;
begin
  Result.BufferType := lbtBoth;
  Result.BufferMode := lbmBuffered;
  Result.MaxBufferSize := 1000;
  Result.FlushInterval := 1000;
  Result.LogFilePath := 'log.txt';
  Result.AppendToFile := True;
  Result.EnableTimestamp := True;
  Result.EnableThreadId := False;
  Result.EnableLogLevel := True;
  Result.MinLogLevel := Ord(llInfo);
  Result.RotationMode := lrmSize;
  Result.MaxLogFileSize := 10 * 1024 * 1024; // 10MB
  Result.MaxLogFiles := 5;
end;

function TLogBuffer.GetStats: string;
var
  RotationModeStr: string;
begin
  FLock.Enter;
  try
    // 获取轮换模式字符串
    case FConfig.RotationMode of
      lrmNone: RotationModeStr := '无';
      lrmSize: RotationModeStr := Format('按大小 (%d MB)', [FConfig.MaxLogFileSize div (1024 * 1024)]);
      lrmDaily: RotationModeStr := '每日';
      lrmWeekly: RotationModeStr := '每周';
      lrmMonthly: RotationModeStr := '每月';
    end;

    Result := Format('日志缓冲区统计信息:' + sLineBreak +
                     '- 缓冲区大小: %d/%d' + sLineBreak +
                     '- 缓冲区类型: %s' + sLineBreak +
                     '- 缓冲区模式: %s' + sLineBreak +
                     '- 刷新间隔: %d ms' + sLineBreak +
                     '- 上次刷新时间: %s' + sLineBreak +
                     '- 日志文件轮换: %s' + sLineBreak +
                     '- 当前日志文件大小: %.2f KB' + sLineBreak +
                     '- 上次轮换日期: %s' + sLineBreak +
                     '- 最大日志文件数: %d' + sLineBreak +
                     '- 启用状态: %s',
                     [FBuffer.Count, FConfig.MaxBufferSize,
                      GetEnumName(TypeInfo(TLogBufferType), Ord(FConfig.BufferType)),
                      GetEnumName(TypeInfo(TLogBufferMode), Ord(FConfig.BufferMode)),
                      FConfig.FlushInterval,
                      FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', FLastFlushTime),
                      RotationModeStr,
                      FCurrentLogFileSize / 1024,
                      FormatDateTime('yyyy-mm-dd', FLastRotationDate),
                      FConfig.MaxLogFiles,
                      BoolToStr(FEnabled, True)]);
  finally
    FLock.Leave;
  end;
end;

procedure TLogBuffer.Info(const Msg: string);
begin
  Log(Msg, llInfo);
end;

procedure TLogBuffer.Log(const Msg: string; LogLevel: TLogLevel);
var
  Entry: TLogEntry;
  NeedFlush: Boolean;
begin
  // 如果未启用，直接返回
  if not FEnabled then
    Exit;

  // 如果日志级别低于最小级别，直接返回
  if Ord(LogLevel) < FConfig.MinLogLevel then
    Exit;

  // 创建日志条目
  Entry.Timestamp := Now;
  Entry.ThreadId := TThread.CurrentThread.ThreadID;
  Entry.LogLevel := LogLevel;
  Entry.Message := Msg;

  // 线程安全操作
  FLock.Enter;
  try
    // 根据缓冲区模式处理日志
    case FConfig.BufferMode of
      lbmImmediate:
        begin
          // 立即输出日志
          if Assigned(FLogCallback) and ((FConfig.BufferType = lbtMemory) or (FConfig.BufferType = lbtBoth)) then
            FLogCallback(FormatLogEntry(Entry));

          if Assigned(FLogFile) and ((FConfig.BufferType = lbtFile) or (FConfig.BufferType = lbtBoth)) then
          begin
            FLogFile.WriteLine(FormatLogEntry(Entry));
            FLogFile.Flush;
          end;
        end;

      lbmBuffered, lbmBatch:
        begin
          // 添加到缓冲区
          FBuffer.Add(Entry);

          // 检查是否需要刷新缓冲区
          NeedFlush := (FConfig.BufferMode = lbmBuffered) and
                       ((FBuffer.Count >= FConfig.MaxBufferSize) or
                        (MilliSecondsBetween(FLastFlushTime, Now) >= FConfig.FlushInterval));

          if NeedFlush then
            FlushBuffer;
        end;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TLogBuffer.Warning(const Msg: string);
begin
  Log(Msg, llWarning);
end;

end.
