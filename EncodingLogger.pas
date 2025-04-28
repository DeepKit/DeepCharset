unit EncodingLogger;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs;

type
  TLogLevel = (llInfo, llWarning, llError, llDebug);

  TLogEvent = procedure(const ATimestamp: TDateTime; ALevel: TLogLevel;
    const AMessage, ADetails: string) of object;

  /// <summary>
  /// 日志记录接口
  /// </summary>
  ILogger = interface
    ['{F5A2D9F1-492B-4D7A-9C3A-D5B6B1EF7BAE}']
    procedure Log(ALevel: TLogLevel; const AMessage: string; const ADetails: string = '');
    procedure Info(const AMessage: string; const AArgs: array of const); overload;
    procedure Info(const AMessage: string; const ADetails: string = ''); overload;
    procedure Warning(const AMessage: string; const AArgs: array of const); overload;
    procedure Warning(const AMessage: string; const ADetails: string = ''); overload;
    procedure Error(const AMessage: string; const AArgs: array of const); overload;
    procedure Error(const AMessage: string; const ADetails: string = ''); overload;
    procedure Debug(const AMessage: string; const AArgs: array of const); overload;
    procedure Debug(const AMessage: string; const ADetails: string = ''); overload;
  end;

  TLogListener = class
  private
    FOnLogEvent: TLogEvent;
  public
    constructor Create(AOnLogEvent: TLogEvent);
    property OnLogEvent: TLogEvent read FOnLogEvent;
  end;

  TEncodingLogger = class(TInterfacedObject, ILogger)
  private
    class var FInstance: TEncodingLogger;
    class constructor Create;
    class destructor Destroy;
  private
    FEnabled: Boolean;
    FListeners: TList<TLogListener>;
    FLock: TCriticalSection;
    FLogToFile: Boolean;
    FLogFileName: string;
    FFileWriter: TStreamWriter;

    function GetLogFileName: string;
    procedure SetLogFileName(const Value: string);
    procedure InitFileWriter;
    procedure CloseFileWriter;
    procedure WriteLogToFile(const ATimestamp: TDateTime; ALevel: TLogLevel;
      const AMessage, ADetails: string);
    function LogLevelToString(ALevel: TLogLevel): string;
  public
    constructor Create;
    destructor Destroy; override;

    // ILogger 接口实现
    procedure Log(ALevel: TLogLevel; const AMessage: string; const ADetails: string = '');
    procedure Info(const AMessage: string; const AArgs: array of const); overload;
    procedure Info(const AMessage: string; const ADetails: string = ''); overload;
    procedure Warning(const AMessage: string; const AArgs: array of const); overload;
    procedure Warning(const AMessage: string; const ADetails: string = ''); overload;
    procedure Error(const AMessage: string; const AArgs: array of const); overload;
    procedure Error(const AMessage: string; const ADetails: string = ''); overload;
    procedure Debug(const AMessage: string; const AArgs: array of const); overload;
    procedure Debug(const AMessage: string; const ADetails: string = ''); overload;

    // 兼容旧接口
    procedure LogInfo(const AMessage: string; const ADetails: string = '');
    procedure LogWarning(const AMessage: string; const ADetails: string = '');
    procedure LogError(const AMessage: string; const ADetails: string = '');
    procedure LogDebug(const AMessage: string; const ADetails: string = '');

    function AddListener(AListener: TLogListener): Integer;
    procedure RemoveListener(AListener: TLogListener); overload;
    procedure RemoveListener(AIndex: Integer); overload;
    procedure ClearListeners;

    property Enabled: Boolean read FEnabled write FEnabled;
    property LogToFile: Boolean read FLogToFile write FLogToFile;
    property LogFileName: string read GetLogFileName write SetLogFileName;

    class property Instance: TEncodingLogger read FInstance;
  end;

implementation

uses
  System.IOUtils;

{ TLogListener }

constructor TLogListener.Create(AOnLogEvent: TLogEvent);
begin
  inherited Create;
  FOnLogEvent := AOnLogEvent;
end;

{ TEncodingLogger }

class constructor TEncodingLogger.Create;
begin
  FInstance := TEncodingLogger.Create;
end;

class destructor TEncodingLogger.Destroy;
begin
  FreeAndNil(FInstance);
end;

constructor TEncodingLogger.Create;
begin
  inherited Create;
  FEnabled := True;
  FListeners := TList<TLogListener>.Create;
  FLock := TCriticalSection.Create;
  FLogToFile := False;
  FLogFileName := '';
end;

destructor TEncodingLogger.Destroy;
begin
  CloseFileWriter;
  ClearListeners;
  FListeners.Free;
  FLock.Free;
  inherited;
end;

function TEncodingLogger.AddListener(AListener: TLogListener): Integer;
begin
  FLock.Enter;
  try
    Result := FListeners.Add(AListener);
  finally
    FLock.Leave;
  end;
end;

procedure TEncodingLogger.ClearListeners;
var
  I: Integer;
begin
  FLock.Enter;
  try
    for I := 0 to FListeners.Count - 1 do
      FListeners[I].Free;
    FListeners.Clear;
  finally
    FLock.Leave;
  end;
end;

procedure TEncodingLogger.CloseFileWriter;
begin
  FLock.Enter;
  try
    if Assigned(FFileWriter) then
    begin
      FFileWriter.Flush;
      FreeAndNil(FFileWriter);
    end;
  finally
    FLock.Leave;
  end;
end;

function TEncodingLogger.GetLogFileName: string;
begin
  FLock.Enter;
  try
    if FLogFileName = '' then
      FLogFileName := TPath.Combine(TPath.GetDocumentsPath,
        'EncodingConverter_' + FormatDateTime('yyyymmdd', Now) + '.log');
    Result := FLogFileName;
  finally
    FLock.Leave;
  end;
end;

procedure TEncodingLogger.InitFileWriter;
var
  LogDir: string;
begin
  CloseFileWriter;

  FLock.Enter;
  try
    if FLogToFile and (FLogFileName <> '') then
    begin
      LogDir := ExtractFilePath(FLogFileName);
      if not DirectoryExists(LogDir) then
        ForceDirectories(LogDir);

      // 以追加方式打开日志文件
      FFileWriter := TStreamWriter.Create(FLogFileName, True, TEncoding.UTF8);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TEncodingLogger.Log(ALevel: TLogLevel; const AMessage, ADetails: string);
var
  Timestamp: TDateTime;
  I: Integer;
begin
  if not FEnabled then Exit;

  Timestamp := Now;

  FLock.Enter;
  try
    // 写入文件
    if FLogToFile then
    begin
      if not Assigned(FFileWriter) then
        InitFileWriter;

      if Assigned(FFileWriter) then
        WriteLogToFile(Timestamp, ALevel, AMessage, ADetails);
    end;

    // 通知监听器
    for I := 0 to FListeners.Count - 1 do
    begin
      if Assigned(FListeners[I].OnLogEvent) then
        FListeners[I].OnLogEvent(Timestamp, ALevel, AMessage, ADetails);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TEncodingLogger.LogDebug(const AMessage, ADetails: string);
begin
  Log(llDebug, AMessage, ADetails);
end;

procedure TEncodingLogger.LogError(const AMessage, ADetails: string);
begin
  Log(llError, AMessage, ADetails);
end;

procedure TEncodingLogger.LogInfo(const AMessage, ADetails: string);
begin
  Log(llInfo, AMessage, ADetails);
end;

function TEncodingLogger.LogLevelToString(ALevel: TLogLevel): string;
begin
  case ALevel of
    llInfo: Result := '信息';
    llWarning: Result := '警告';
    llError: Result := '错误';
    llDebug: Result := '调试';
  else
    Result := '';
  end;
end;

procedure TEncodingLogger.LogWarning(const AMessage, ADetails: string);
begin
  Log(llWarning, AMessage, ADetails);
end;

procedure TEncodingLogger.RemoveListener(AListener: TLogListener);
var
  Index: Integer;
begin
  FLock.Enter;
  try
    Index := FListeners.IndexOf(AListener);
    if Index >= 0 then
    begin
      FListeners[Index].Free;
      FListeners.Delete(Index);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TEncodingLogger.RemoveListener(AIndex: Integer);
begin
  FLock.Enter;
  try
    if (AIndex >= 0) and (AIndex < FListeners.Count) then
    begin
      FListeners[AIndex].Free;
      FListeners.Delete(AIndex);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TEncodingLogger.SetLogFileName(const Value: string);
begin
  FLock.Enter;
  try
    if FLogFileName <> Value then
    begin
      FLogFileName := Value;
      if FLogToFile then
        InitFileWriter;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TEncodingLogger.WriteLogToFile(const ATimestamp: TDateTime; ALevel: TLogLevel;
  const AMessage, ADetails: string);
var
  LogLine: string;
begin
  if not Assigned(FFileWriter) then Exit;

  try
    LogLine := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', ATimestamp) +
      ' [' + LogLevelToString(ALevel) + '] ' + AMessage;

    if ADetails <> '' then
      LogLine := LogLine + ' - ' + ADetails;

    FFileWriter.WriteLine(LogLine);
    FFileWriter.Flush;
  except
    // 忽略日志写入错误
  end;
end;

// ILogger 接口实现
procedure TEncodingLogger.Info(const AMessage: string; const AArgs: array of const);
begin
  LogInfo(Format(AMessage, AArgs));
end;

procedure TEncodingLogger.Info(const AMessage: string; const ADetails: string);
begin
  LogInfo(AMessage, ADetails);
end;

procedure TEncodingLogger.Warning(const AMessage: string; const AArgs: array of const);
begin
  LogWarning(Format(AMessage, AArgs));
end;

procedure TEncodingLogger.Warning(const AMessage: string; const ADetails: string);
begin
  LogWarning(AMessage, ADetails);
end;

procedure TEncodingLogger.Error(const AMessage: string; const AArgs: array of const);
begin
  LogError(Format(AMessage, AArgs));
end;

procedure TEncodingLogger.Error(const AMessage: string; const ADetails: string);
begin
  LogError(AMessage, ADetails);
end;

procedure TEncodingLogger.Debug(const AMessage: string; const AArgs: array of const);
begin
  LogDebug(Format(AMessage, AArgs));
end;

procedure TEncodingLogger.Debug(const AMessage: string; const ADetails: string);
begin
  LogDebug(AMessage, ADetails);
end;

// 全局 Logger 变量
var
  Logger: ILogger;

initialization
  Logger := TEncodingLogger.Instance;

end.