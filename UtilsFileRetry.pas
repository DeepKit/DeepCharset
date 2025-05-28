unit UtilsFileRetry;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, Winapi.Windows, System.Math;

type
  // 文件操作类型
  TFileOperation = (foRead, foWrite, foDelete, foRename, foMove, foCopy);

  // 重试策略
  TRetryStrategy = (rsFixed, rsExponential, rsLinear);

  // 重试配置
  TRetryConfig = record
    MaxRetries: Integer;        // 最大重试次数
    InitialDelay: Integer;      // 初始延迟（毫秒）
    MaxDelay: Integer;          // 最大延迟（毫秒）
    Strategy: TRetryStrategy;   // 重试策略
    LogCallback: TProc<string>; // 日志回调
  end;

  // 文件操作结果
  TFileOperationResult = record
    Success: Boolean;           // 操作是否成功
    ErrorMessage: string;       // 错误信息
    RetryCount: Integer;        // 重试次数
    TotalTime: Int64;           // 总耗时（毫秒）
  end;

  // 文件操作函数类型
  TFileOperationFunc = reference to function: Boolean;

// 获取默认重试配置
function GetDefaultRetryConfig: TRetryConfig;

// 使用重试机制执行文件操作
function ExecuteWithRetry(const Operation: TFileOperationFunc;
  const OperationType: TFileOperation; const FileName: string;
  const Config: TRetryConfig): TFileOperationResult;

// 安全打开文件（带重试）
function SafeOpenFile(const FileName: string; Mode: Word;
  const Config: TRetryConfig): TFileStream;

// 安全保存文件（带重试）
function SafeSaveFile(const FileName, Content: string;
  const Config: TRetryConfig): TFileOperationResult;

// 安全复制文件（带重试）
function SafeCopyFile(const SourceFile, TargetFile: string;
  const Config: TRetryConfig): TFileOperationResult;

// 安全删除文件（带重试）
function SafeDeleteFile(const FileName: string;
  const Config: TRetryConfig): TFileOperationResult;

// 安全重命名文件（带重试）
function SafeRenameFile(const OldName, NewName: string;
  const Config: TRetryConfig): TFileOperationResult;

// 检查文件是否被锁定
function IsFileLocked(const FileName: string): Boolean;

// 等待文件解锁
function WaitForFileUnlock(const FileName: string; TimeoutMs: Integer;
  const LogCallback: TProc<string> = nil): Boolean;

implementation

// 获取默认重试配置
function GetDefaultRetryConfig: TRetryConfig;
begin
  Result.MaxRetries := 5;
  Result.InitialDelay := 100;
  Result.MaxDelay := 5000;
  Result.Strategy := rsExponential;
  Result.LogCallback := nil;
end;

// 计算下一次重试延迟
function CalculateDelay(const Config: TRetryConfig; RetryCount: Integer): Integer;
begin
  case Config.Strategy of
    rsFixed:
      Result := Config.InitialDelay;

    rsLinear:
      Result := Config.InitialDelay * (RetryCount + 1);

    rsExponential:
      Result := Config.InitialDelay * (1 shl RetryCount);

    else
      Result := Config.InitialDelay;
  end;

  // 确保不超过最大延迟
  if Result > Config.MaxDelay then
    Result := Config.MaxDelay;
end;

// 使用重试机制执行文件操作
function ExecuteWithRetry(const Operation: TFileOperationFunc;
  const OperationType: TFileOperation; const FileName: string;
  const Config: TRetryConfig): TFileOperationResult;
var
  RetryCount: Integer;
  Delay: Integer;
  StartTime: TDateTime;
  OperationTypeStr: string;
  LastError: string;
begin
  // 初始化结果
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.RetryCount := 0;

  // 记录开始时间
  StartTime := Now;

  // 获取操作类型字符串
  case OperationType of
    foRead: OperationTypeStr := '读取';
    foWrite: OperationTypeStr := '写入';
    foDelete: OperationTypeStr := '删除';
    foRename: OperationTypeStr := '重命名';
    foMove: OperationTypeStr := '移动';
    foCopy: OperationTypeStr := '复制';
  end;

  // 尝试执行操作
  for RetryCount := 0 to Config.MaxRetries do
  begin
    try
      // 执行操作
      if Operation() then
      begin
        Result.Success := True;
        Result.RetryCount := RetryCount;
        Result.TotalTime := MilliSecondsBetween(StartTime, Now);

        // 记录日志（如果有重试）
        if (RetryCount > 0) and Assigned(Config.LogCallback) then
          Config.LogCallback(Format('文件%s操作成功: %s (重试次数: %d, 总耗时: %d ms)',
            [OperationTypeStr, FileName, RetryCount, Result.TotalTime]));

        Exit;
      end;
    except
      on E: Exception do
      begin
        LastError := E.Message;

        // 记录日志
        if Assigned(Config.LogCallback) then
          Config.LogCallback(Format('文件%s操作失败: %s - %s (尝试次数: %d)',
            [OperationTypeStr, FileName, E.Message, RetryCount + 1]));

        // 如果已达到最大重试次数，则退出
        if RetryCount >= Config.MaxRetries then
          Break;

        // 计算延迟时间
        Delay := CalculateDelay(Config, RetryCount);

        // 记录重试日志
        if Assigned(Config.LogCallback) then
          Config.LogCallback(Format('将在 %d ms 后重试文件%s操作: %s',
            [Delay, OperationTypeStr, FileName]));

        // 等待
        Sleep(Delay);
      end;
    end;
  end;

  // 操作失败
  Result.Success := False;
  Result.ErrorMessage := LastError;
  Result.RetryCount := Config.MaxRetries;
  Result.TotalTime := MilliSecondsBetween(StartTime, Now);

  // 记录最终失败日志
  if Assigned(Config.LogCallback) then
    Config.LogCallback(Format('文件%s操作最终失败: %s - %s (重试次数: %d, 总耗时: %d ms)',
      [OperationTypeStr, FileName, LastError, Result.RetryCount, Result.TotalTime]));
end;

// 检查文件是否被锁定
function IsFileLocked(const FileName: string): Boolean;
var
  FileHandle: THandle;
begin
  Result := False;

  if not FileExists(FileName) then
    Exit;

  FileHandle := CreateFile(
    PChar(FileName),
    GENERIC_READ or GENERIC_WRITE,
    0, // 不共享
    nil,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0);

  Result := (FileHandle = INVALID_HANDLE_VALUE);

  if not Result then
    CloseHandle(FileHandle);
end;

// 等待文件解锁
function WaitForFileUnlock(const FileName: string; TimeoutMs: Integer;
  const LogCallback: TProc<string> = nil): Boolean;
var
  StartTime: TDateTime;
  ElapsedMs: Integer;
  WaitInterval: Integer;
begin
  StartTime := Now;
  WaitInterval := 100; // 初始等待间隔为100毫秒

  while IsFileLocked(FileName) do
  begin
    ElapsedMs := MilliSecondsBetween(StartTime, Now);

    // 如果超时，则返回失败
    if ElapsedMs >= TimeoutMs then
    begin
      if Assigned(LogCallback) then
        LogCallback(Format('等待文件解锁超时: %s (已等待 %d ms)', [FileName, ElapsedMs]));
      Exit(False);
    end;

    // 记录等待日志
    if Assigned(LogCallback) then
      LogCallback(Format('文件被锁定，等待解锁: %s (已等待 %d ms)', [FileName, ElapsedMs]));

    // 等待一段时间
    Sleep(WaitInterval);

    // 增加等待间隔，但不超过1秒
    WaitInterval := Min(WaitInterval * 2, 1000);
  end;

  Result := True;
end;

// 安全打开文件（带重试）
function SafeOpenFile(const FileName: string; Mode: Word;
  const Config: TRetryConfig): TFileStream;
var
  OpResult: TFileOperationResult;
  FileStream: TFileStream;
begin
  FileStream := nil;

  OpResult := ExecuteWithRetry(
    function: Boolean
    begin
      try
        FileStream := TFileStream.Create(FileName, Mode);
        Result := True;
      except
        Result := False;
      end;
    end,
    foRead,
    FileName,
    Config
  );

  if not OpResult.Success then
    raise Exception.Create('无法打开文件: ' + FileName + ' - ' + OpResult.ErrorMessage);

  Result := FileStream;
end;

// 安全保存文件（带重试）
function SafeSaveFile(const FileName, Content: string;
  const Config: TRetryConfig): TFileOperationResult;
begin
  Result := ExecuteWithRetry(
    function: Boolean
    var
      FileStream: TFileStream;
      Buffer: TBytes;
    begin
      try
        // 确保目录存在
        ForceDirectories(ExtractFilePath(FileName));

        // 创建文件
        FileStream := TFileStream.Create(FileName, fmCreate);
        try
          // 写入内容
          Buffer := TEncoding.UTF8.GetBytes(Content);
          FileStream.WriteBuffer(Buffer[0], Length(Buffer));
          Result := True;
        finally
          FileStream.Free;
        end;
      except
        Result := False;
      end;
    end,
    foWrite,
    FileName,
    Config
  );
end;

// 安全复制文件（带重试）
function SafeCopyFile(const SourceFile, TargetFile: string;
  const Config: TRetryConfig): TFileOperationResult;
begin
  Result := ExecuteWithRetry(
    function: Boolean
    begin
      try
        // 确保目标目录存在
        ForceDirectories(ExtractFilePath(TargetFile));

        // 复制文件
        Result := CopyFile(PWideChar(SourceFile), PWideChar(TargetFile), False);
      except
        Result := False;
      end;
    end,
    foCopy,
    SourceFile + ' -> ' + TargetFile,
    Config
  );
end;

// 安全删除文件（带重试）
function SafeDeleteFile(const FileName: string;
  const Config: TRetryConfig): TFileOperationResult;
begin
  Result := ExecuteWithRetry(
    function: Boolean
    begin
      try
        Result := DeleteFile(PWideChar(FileName));
      except
        Result := False;
      end;
    end,
    foDelete,
    FileName,
    Config
  );
end;

// 安全重命名文件（带重试）
function SafeRenameFile(const OldName, NewName: string;
  const Config: TRetryConfig): TFileOperationResult;
begin
  Result := ExecuteWithRetry(
    function: Boolean
    begin
      try
        // 确保目标目录存在
        ForceDirectories(ExtractFilePath(NewName));

        // 重命名文件
        Result := RenameFile(OldName, NewName);
      except
        Result := False;
      end;
    end,
    foRename,
    OldName + ' -> ' + NewName,
    Config
  );
end;

end.
