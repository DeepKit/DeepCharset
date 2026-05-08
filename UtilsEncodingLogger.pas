unit UtilsEncodingLogger;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, System.SyncObjs,
  UtilsTypes, ModelEncoding;

type
  // 基本日志接口
  ILogger = interface
    ['{F8A9D1E3-B7C4-4A5F-9D2A-8E6B7D8F3E1D}']
    procedure LogInfo(const AMsg: string);
    procedure LogWarning(const AMsg: string);
    procedure LogError(const AMsg: string);
    procedure LogDebug(const AMsg: string);
  end;

  TEncodingLogLevel = (
    ellVerbose,    // Detailed debug information
    ellInfo,       // General operational information
    ellWarning,    // Warning conditions
    ellError,      // Error conditions
    ellPerformance // Performance measurements
  );

  TEncodingLogCategory = (
    elcDetection,     // Encoding detection
    elcConversion,    // Encoding conversion
    elcValidation,    // Content validation
    elcIO,            // File I/O operations
    elcConfiguration, // Configuration settings
    elcStatistics     // Statistical information
  );

  TEncodingLogTarget = (
    eltConsole,    // Log to console
    eltFile,       // Log to file
    eltMemory,     // Keep in memory only
    eltEvent,      // Trigger events
    eltCustom      // Custom target
  );

  TEncodingLogFormat = (
    elfSimple,     // Simple text format
    elfDetailed,   // Detailed text with timestamp
    elfJSON,       // JSON format
    elfXML,        // XML format
    elfCSV         // CSV format
  );

  TEncodingLogEntry = class
  private
    FTimestamp: TDateTime;
    FLevel: TEncodingLogLevel;
    FCategory: TEncodingLogCategory;
    FMessage: string;
    FSourceFile: string;
    FSourceLine: Integer;
    FThreadID: TThreadID;
    FAdditionalInfo: TDictionary<string, string>;
    FDuration: Int64; // Duration in milliseconds
  public
    constructor Create(ALevel: TEncodingLogLevel; ACategory: TEncodingLogCategory;
                      const AMessage: string);
    destructor Destroy; override;

    procedure AddInfo(const AKey, AValue: string);
    function FormatToString(AFormat: TEncodingLogFormat): string;

    property Timestamp: TDateTime read FTimestamp;
    property Level: TEncodingLogLevel read FLevel;
    property Category: TEncodingLogCategory read FCategory;
    property Message: string read FMessage;
    property SourceFile: string read FSourceFile write FSourceFile;
    property SourceLine: Integer read FSourceLine write FSourceLine;
    property ThreadID: TThreadID read FThreadID;
    property Duration: Int64 read FDuration write FDuration;
    property AdditionalInfo: TDictionary<string, string> read FAdditionalInfo;
  end;

  TEncodingLogListener = class
  public
    procedure OnLog(AEntry: TEncodingLogEntry); virtual; abstract;
    function IsInterestedIn(ALevel: TEncodingLogLevel; ACategory: TEncodingLogCategory): Boolean; virtual;
  end;

  TEncodingFileLogger = class(TEncodingLogListener)
  private
    FFilePath: string;
    FFormat: TEncodingLogFormat;
    FFlushInterval: Integer; // in seconds
    FLastFlush: TDateTime;
    FLogFile: TextFile;
    FBuffer: TStringList;
    FLock: TCriticalSection;
    FMaxFileSize: Int64;
    FMaxLogFiles: Integer;
    FAutoRotate: Boolean;

    procedure RotateLogFileIfNeeded;
    procedure FlushBufferIfNeeded(AForce: Boolean = False);
  public
    constructor Create(const AFilePath: string; AFormat: TEncodingLogFormat = elfDetailed);
    destructor Destroy; override;

    procedure OnLog(AEntry: TEncodingLogEntry); override;

    property FilePath: string read FFilePath;
    property Format: TEncodingLogFormat read FFormat write FFormat;
    property FlushInterval: Integer read FFlushInterval write FFlushInterval;
    property MaxFileSize: Int64 read FMaxFileSize write FMaxFileSize;
    property MaxLogFiles: Integer read FMaxLogFiles write FMaxLogFiles;
    property AutoRotate: Boolean read FAutoRotate write FAutoRotate;
  end;

  TEncodingConsoleLogger = class(TEncodingLogListener)
  private
    FColorized: Boolean;
    FFormat: TEncodingLogFormat;
  public
    constructor Create(AColorized: Boolean = True; AFormat: TEncodingLogFormat = elfSimple);

    procedure OnLog(AEntry: TEncodingLogEntry); override;

    property Colorized: Boolean read FColorized write FColorized;
    property Format: TEncodingLogFormat read FFormat write FFormat;
  end;

  TEncodingLogEvent = procedure(Sender: TObject; AEntry: TEncodingLogEntry) of object;

  TEncodingEventLogger = class(TEncodingLogListener)
  private
    FOnLogEvent: TEncodingLogEvent;
  public
    constructor Create(AOnLog: TEncodingLogEvent);

    procedure OnLog(AEntry: TEncodingLogEntry); override;

    property OnLogEvent: TEncodingLogEvent read FOnLogEvent write FOnLogEvent;
  end;

  TEncodingLogger = class(TInterfacedObject, ILogger)
  private
    FListeners: TObjectList<TEncodingLogListener>;
    FLock: TCriticalSection;
    FMinLevel: TEncodingLogLevel;
    FIncludeCategories: set of TEncodingLogCategory;
    FExcludeCategories: set of TEncodingLogCategory;
    FEnabled: Boolean;
    FPerformanceThreshold: Int64; // in milliseconds
    FEntryPool: TList<TEncodingLogEntry>;
    FMaxPoolSize: Integer;

    function GetLogEntry: TEncodingLogEntry;
    procedure ReturnLogEntry(AEntry: TEncodingLogEntry);
    function ShouldLog(ALevel: TEncodingLogLevel; ACategory: TEncodingLogCategory): Boolean;
    function FormatMessage(const AMsg: string; const AArgs: array of const): string;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddListener(AListener: TEncodingLogListener);
    procedure RemoveListener(AListener: TEncodingLogListener);
    procedure ClearListeners;

    // ILogger implementation
    procedure LogInfo(const AMsg: string);
    procedure LogWarning(const AMsg: string);
    procedure LogError(const AMsg: string);
    procedure LogDebug(const AMsg: string);

    // Enhanced logging methods
    procedure Log(ALevel: TEncodingLogLevel; ACategory: TEncodingLogCategory;
                 const AMsg: string; const AArgs: array of const);
    procedure LogFormat(ALevel: TEncodingLogLevel; ACategory: TEncodingLogCategory;
                       const AMsg: string; const AArgs: array of const);
    procedure LogVerbose(ACategory: TEncodingLogCategory; const AMsg: string);
    procedure LogInfoCat(ACategory: TEncodingLogCategory; const AMsg: string);
    procedure LogWarningCat(ACategory: TEncodingLogCategory; const AMsg: string);
    procedure LogErrorCat(ACategory: TEncodingLogCategory; const AMsg: string);
    procedure LogPerformance(ACategory: TEncodingLogCategory; const AOperation: string;
                            ADuration: Int64; const AAdditionalInfo: string = '');

    // Performance timing methods
    function StartTiming(ACategory: TEncodingLogCategory; const AOperation: string): TDateTime;
    procedure EndTiming(ACategory: TEncodingLogCategory; const AOperation: string;
                       AStartTime: TDateTime; const AAdditionalInfo: string = '');

    // Property accessors
    property MinLevel: TEncodingLogLevel read FMinLevel write FMinLevel;
    property Enabled: Boolean read FEnabled write FEnabled;
    property PerformanceThreshold: Int64 read FPerformanceThreshold write FPerformanceThreshold;
  end;

  // Helper functions
  function EncodingLogLevelToStr(ALevel: TEncodingLogLevel): string;
  function EncodingLogCategoryToStr(ACategory: TEncodingLogCategory): string;
  function StrToEncodingLogLevel(const AStr: string): TEncodingLogLevel;
  function StrToEncodingLogCategory(const AStr: string): TEncodingLogCategory;

implementation

const
  LOG_CATEGORY_NAMES: array[TEncodingLogCategory] of string = (
    'Detection', 'Conversion', 'Validation', 'IO', 'Configuration', 'Statistics'
  );

  LOG_LEVEL_NAMES: array[TEncodingLogLevel] of string = (
    'VERBOSE', 'INFO', 'WARNING', 'ERROR', 'PERFORMANCE'
  );

{ Helper functions }

function EncodingLogLevelToStr(ALevel: TEncodingLogLevel): string;
begin
  Result := LOG_LEVEL_NAMES[ALevel];
end;

function EncodingLogCategoryToStr(ACategory: TEncodingLogCategory): string;
begin
  Result := LOG_CATEGORY_NAMES[ACategory];
end;

function StrToEncodingLogLevel(const AStr: string): TEncodingLogLevel;
var
  I: TEncodingLogLevel;
begin
  for I := Low(TEncodingLogLevel) to High(TEncodingLogLevel) do
    if SameText(AStr, LOG_LEVEL_NAMES[I]) then
      Exit(I);
  Result := ellInfo; // Default
end;

function StrToEncodingLogCategory(const AStr: string): TEncodingLogCategory;
var
  I: TEncodingLogCategory;
begin
  for I := Low(TEncodingLogCategory) to High(TEncodingLogCategory) do
    if SameText(AStr, LOG_CATEGORY_NAMES[I]) then
      Exit(I);
  Result := elcDetection; // Default
end;

{ TEncodingLogEntry }

constructor TEncodingLogEntry.Create(ALevel: TEncodingLogLevel;
  ACategory: TEncodingLogCategory; const AMessage: string);
begin
  FTimestamp := Now;
  FLevel := ALevel;
  FCategory := ACategory;
  FMessage := AMessage;
  FThreadID := TThread.CurrentThread.ThreadID;
  FAdditionalInfo := TDictionary<string, string>.Create;
  FDuration := 0;
end;

destructor TEncodingLogEntry.Destroy;
begin
  FAdditionalInfo.Free;
  inherited;
end;

procedure TEncodingLogEntry.AddInfo(const AKey, AValue: string);
begin
  FAdditionalInfo.AddOrSetValue(AKey, AValue);
end;

function TEncodingLogEntry.FormatToString(AFormat: TEncodingLogFormat): string;
var
  Key: string;
  SB: TStringBuilder;
begin
  case AFormat of
    elfSimple:
      Result := Format('[%s] [%s] %s', [
        EncodingLogLevelToStr(FLevel),
        EncodingLogCategoryToStr(FCategory),
        FMessage
      ]);

    elfDetailed:
      begin
        SB := TStringBuilder.Create;
        try
          SB.AppendFormat('%s [%s] [%s] [Thread:%d] %s', [
            FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', FTimestamp),
            EncodingLogLevelToStr(FLevel),
            EncodingLogCategoryToStr(FCategory),
            FThreadID,
            FMessage
          ]);

          if FDuration > 0 then
            SB.AppendFormat(' (Duration: %d ms)', [FDuration]);

          if FAdditionalInfo.Count > 0 then
          begin
            SB.Append(' {');
            for Key in FAdditionalInfo.Keys do
              SB.AppendFormat(' %s: %s;', [Key, FAdditionalInfo[Key]]);
            SB.Append(' }');
          end;

          Result := SB.ToString;
        finally
          SB.Free;
        end;
      end;

    elfJSON:
      begin
        SB := TStringBuilder.Create;
        try
          SB.Append('{');
          SB.AppendFormat('"timestamp":"%s",', [FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', FTimestamp)]);
          SB.AppendFormat('"level":"%s",', [EncodingLogLevelToStr(FLevel)]);
          SB.AppendFormat('"category":"%s",', [EncodingLogCategoryToStr(FCategory)]);
          SB.AppendFormat('"thread":%d,', [FThreadID]);
          SB.AppendFormat('"message":"%s"', [StringReplace(FMessage, '"', '\"', [rfReplaceAll])]);

          if FDuration > 0 then
            SB.AppendFormat(',"duration":%d', [FDuration]);

          if FSourceFile <> '' then
          begin
            SB.AppendFormat(',"source":"%s"', [StringReplace(FSourceFile, '\', '\\', [rfReplaceAll])]);
            SB.AppendFormat(',"line":%d', [FSourceLine]);
          end;

          if FAdditionalInfo.Count > 0 then
          begin
            SB.Append(',"info":{');
            var First := True;
            for Key in FAdditionalInfo.Keys do
            begin
              if not First then SB.Append(',');
              SB.AppendFormat('"%s":"%s"', [
                Key,
                StringReplace(FAdditionalInfo[Key], '"', '\"', [rfReplaceAll])
              ]);
              First := False;
            end;
            SB.Append('}');
          end;

          SB.Append('}');
          Result := SB.ToString;
        finally
          SB.Free;
        end;
      end;

    elfXML:
      begin
        SB := TStringBuilder.Create;
        try
          SB.AppendLine('<log>');
          SB.AppendFormat('  <timestamp>%s</timestamp>'+#13#10, [FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', FTimestamp)]);
          SB.AppendFormat('  <level>%s</level>'+#13#10, [EncodingLogLevelToStr(FLevel)]);
          SB.AppendFormat('  <category>%s</category>'+#13#10, [EncodingLogCategoryToStr(FCategory)]);
          SB.AppendFormat('  <thread>%d</thread>'+#13#10, [FThreadID]);
          SB.AppendFormat('  <message>%s</message>'+#13#10, [
            StringReplace(StringReplace(FMessage, '&', '&amp;', [rfReplaceAll]),
                         '<', '&lt;', [rfReplaceAll])
          ]);

          if FDuration > 0 then
            SB.AppendFormat('  <duration>%d</duration>'+#13#10, [FDuration]);

          if FSourceFile <> '' then
          begin
            SB.AppendLine('  <source>');
            SB.AppendFormat('    <file>%s</file>'+#13#10, [FSourceFile]);
            SB.AppendFormat('    <line>%d</line>'+#13#10, [FSourceLine]);
            SB.AppendLine('  </source>');
          end;

          if FAdditionalInfo.Count > 0 then
          begin
            SB.AppendLine('  <info>');
            for Key in FAdditionalInfo.Keys do
              SB.AppendFormat('    <item key="%s">%s</item>'+#13#10, [
                Key,
                StringReplace(StringReplace(FAdditionalInfo[Key], '&', '&amp;', [rfReplaceAll]),
                             '<', '&lt;', [rfReplaceAll])
              ]);
            SB.AppendLine('  </info>');
          end;

          SB.Append('</log>');
          Result := SB.ToString;
        finally
          SB.Free;
        end;
      end;

    elfCSV:
      begin
        // Basic CSV format: timestamp,level,category,thread,message,duration
        Result := Format('"%s","%s","%s","%d","%s"', [
          FormatDateTime('yyyy-mm-dd hh:nn:ss', FTimestamp),
          EncodingLogLevelToStr(FLevel),
          EncodingLogCategoryToStr(FCategory),
          FThreadID,
          StringReplace(FMessage, '"', '""', [rfReplaceAll])
        ]);

        if FDuration > 0 then
          Result := Result + Format(',%d', [FDuration])
        else
          Result := Result + ',';

        // Add file and line if available
        if FSourceFile <> '' then
          Result := Result + Format(',"%s",%d', [
            StringReplace(FSourceFile, '"', '""', [rfReplaceAll]),
            FSourceLine
          ])
        else
          Result := Result + ',,';
      end;
  end;
end;

{ TEncodingLogListener }

function TEncodingLogListener.IsInterestedIn(ALevel: TEncodingLogLevel;
  ACategory: TEncodingLogCategory): Boolean;
begin
  // By default, interested in all levels and categories
  Result := True;
end;

{ TEncodingFileLogger }

constructor TEncodingFileLogger.Create(const AFilePath: string;
  AFormat: TEncodingLogFormat);
begin
  FFilePath := AFilePath;
  FFormat := AFormat;
  FFlushInterval := 10; // 10 seconds by default
  FLastFlush := Now;
  FBuffer := TStringList.Create;
  FLock := TCriticalSection.Create;
  FMaxFileSize := 10 * 1024 * 1024; // 10 MB by default
  FMaxLogFiles := 5;
  FAutoRotate := True;

  // Create directory if it doesn't exist
  ForceDirectories(ExtractFilePath(FFilePath));
end;

destructor TEncodingFileLogger.Destroy;
begin
  // Flush any remaining entries
  FlushBufferIfNeeded(True);

  FBuffer.Free;
  FLock.Free;
  inherited;
end;

procedure TEncodingFileLogger.OnLog(AEntry: TEncodingLogEntry);
begin
  if not Assigned(AEntry) then
    Exit;

  FLock.Enter;
  try
    FBuffer.Add(AEntry.FormatToString(FFormat));
    FlushBufferIfNeeded;
  finally
    FLock.Leave;
  end;
end;

procedure TEncodingFileLogger.RotateLogFileIfNeeded;
var
  FileSize: Int64;
  I: Integer;
  NewName, BaseName, Ext: string;
begin
  if not FAutoRotate then
    Exit;

  if not FileExists(FFilePath) then
    Exit;

  FileSize := TFile.GetSize(FFilePath);
  if FileSize < FMaxFileSize then
    Exit;

  // Close file if open
  CloseFile(FLogFile);

  // Get base name and extension
  BaseName := ChangeFileExt(FFilePath, '');
  Ext := ExtractFileExt(FFilePath);

  // Delete oldest log file if we reached max
  NewName := BaseName + '.' + IntToStr(FMaxLogFiles) + Ext;
  if FileExists(NewName) then
    DeleteFile(NewName);

  // Rename existing log files
  for I := FMaxLogFiles - 1 downto 1 do
  begin
    NewName := BaseName + '.' + IntToStr(I) + Ext;
    if FileExists(NewName) then
      RenameFile(NewName, BaseName + '.' + IntToStr(I + 1) + Ext);
  end;

  // Rename current log to .1
  RenameFile(FFilePath, BaseName + '.1' + Ext);
end;

procedure TEncodingFileLogger.FlushBufferIfNeeded(AForce: Boolean);
var
  LogText: string;
begin
  // Check if it's time to flush or forced
  if not AForce and (Trunc((Now - FLastFlush) * 86400) < FFlushInterval) and (FBuffer.Count < 100) then
    Exit;

  if FBuffer.Count = 0 then
    Exit;

  // Rotate log file if needed
  RotateLogFileIfNeeded;

  try
    // Open file for append
    AssignFile(FLogFile, FFilePath);
    if FileExists(FFilePath) then
      Append(FLogFile)
    else
      Rewrite(FLogFile);

    // Write all buffered entries
    for LogText in FBuffer do
      WriteLn(FLogFile, LogText);

    // Clear buffer
    FBuffer.Clear;

    // Update last flush time
    FLastFlush := Now;
  finally
    CloseFile(FLogFile);
  end;
end;

{ TEncodingConsoleLogger }

constructor TEncodingConsoleLogger.Create(AColorized: Boolean;
  AFormat: TEncodingLogFormat);
begin
  FColorized := AColorized;
  FFormat := AFormat;
end;

procedure TEncodingConsoleLogger.OnLog(AEntry: TEncodingLogEntry);
begin
  if not Assigned(AEntry) then
    Exit;

  // In a real implementation, we would set console colors based on log level
  // We'll just output the formatted entry here
  WriteLn(AEntry.FormatToString(FFormat));
end;

{ TEncodingEventLogger }

constructor TEncodingEventLogger.Create(AOnLog: TEncodingLogEvent);
begin
  inherited Create;
  FOnLogEvent := AOnLog;
end;

procedure TEncodingEventLogger.OnLog(AEntry: TEncodingLogEntry);
begin
  if Assigned(FOnLogEvent) and Assigned(AEntry) then
    FOnLogEvent(Self, AEntry);
end;

{ TEncodingLogger }

constructor TEncodingLogger.Create;
begin
  FListeners := TObjectList<TEncodingLogListener>.Create(True);
  FLock := TCriticalSection.Create;
  FMinLevel := ellInfo;
  FIncludeCategories := [
    elcDetection, elcConversion, elcValidation, elcIO, elcConfiguration, elcStatistics
  ];
  FExcludeCategories := [];
  FEnabled := True;
  FPerformanceThreshold := 100; // 100ms default threshold
  FEntryPool := TObjectList<TEncodingLogEntry>.Create(True);
  FMaxPoolSize := 100;
end;

destructor TEncodingLogger.Destroy;
begin
  FListeners.Free;
  FLock.Free;
  FEntryPool.Free;
  inherited;
end;

procedure TEncodingLogger.AddListener(AListener: TEncodingLogListener);
begin
  if not Assigned(AListener) then
    Exit;

  FLock.Enter;
  try
    FListeners.Add(AListener);
  finally
    FLock.Leave;
  end;
end;

procedure TEncodingLogger.RemoveListener(AListener: TEncodingLogListener);
var
  I: Integer;
begin
  if not Assigned(AListener) then
    Exit;

  FLock.Enter;
  try
    for I := FListeners.Count - 1 downto 0 do
    begin
      if FListeners[I] = AListener then
      begin
        FListeners.Delete(I);
        Break;
      end;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TEncodingLogger.ClearListeners;
begin
  FLock.Enter;
  try
    FListeners.Clear;
  finally
    FLock.Leave;
  end;
end;

function TEncodingLogger.GetLogEntry: TEncodingLogEntry;
var
  Entry: TEncodingLogEntry;
  Index: Integer;
begin
  Entry := nil;
  FLock.Enter;
  try
    if FEntryPool.Count > 0 then
    begin
      Index := FEntryPool.Count - 1;
      Entry := FEntryPool[Index];
      FEntryPool.Delete(Index);
    end;
  finally
    FLock.Leave;
  end;

  if Entry = nil then
    Result := TEncodingLogEntry.Create(ellInfo, elcDetection, '')
  else
    Result := Entry;
end;

procedure TEncodingLogger.ReturnLogEntry(AEntry: TEncodingLogEntry);
begin
  if not Assigned(AEntry) then
    Exit;

  FLock.Enter;
  try
    if FEntryPool.Count < FMaxPoolSize then
    begin
      // Clear entry for reuse
      AEntry.FMessage := '';
      AEntry.FAdditionalInfo.Clear;
      AEntry.FDuration := 0;
      AEntry.FSourceFile := '';
      AEntry.FSourceLine := 0;

      FEntryPool.Add(AEntry);
    end
    else
      AEntry.Free;
  finally
    FLock.Leave;
  end;
end;

function TEncodingLogger.ShouldLog(ALevel: TEncodingLogLevel;
  ACategory: TEncodingLogCategory): Boolean;
begin
  // Skip if logging is disabled
  if not FEnabled then
    Exit(False);

  // Skip if level is below minimum
  if Ord(ALevel) < Ord(FMinLevel) then
    Exit(False);

  // Skip if category is excluded
  if ACategory in FExcludeCategories then
    Exit(False);

  // Skip if not in included categories and some categories are specified
  if (FIncludeCategories <> []) and not (ACategory in FIncludeCategories) then
    Exit(False);

  Result := True;
end;

function TEncodingLogger.FormatMessage(const AMsg: string;
  const AArgs: array of const): string;
begin
  if Length(AArgs) > 0 then
    Result := Format(AMsg, AArgs)
  else
    Result := AMsg;
end;

procedure TEncodingLogger.Log(ALevel: TEncodingLogLevel;
  ACategory: TEncodingLogCategory; const AMsg: string; const AArgs: array of const);
var
  Entry: TEncodingLogEntry;
  I: Integer;
  Listener: TEncodingLogListener;
begin
  if not ShouldLog(ALevel, ACategory) then
    Exit;

  Entry := GetLogEntry;
  try
    Entry.FTimestamp := Now;
    Entry.FLevel := ALevel;
    Entry.FCategory := ACategory;
    Entry.FMessage := FormatMessage(AMsg, AArgs);

    FLock.Enter;
    try
      for I := 0 to FListeners.Count - 1 do
      begin
        Listener := FListeners[I];
        if Assigned(Listener) and Listener.IsInterestedIn(ALevel, ACategory) then
          Listener.OnLog(Entry);
      end;
    finally
      FLock.Leave;
    end;
  finally
    ReturnLogEntry(Entry);
  end;
end;

procedure TEncodingLogger.LogFormat(ALevel: TEncodingLogLevel;
  ACategory: TEncodingLogCategory; const AMsg: string; const AArgs: array of const);
begin
  Log(ALevel, ACategory, AMsg, AArgs);
end;

procedure TEncodingLogger.LogVerbose(ACategory: TEncodingLogCategory;
  const AMsg: string);
begin
  Log(ellVerbose, ACategory, AMsg, []);
end;

procedure TEncodingLogger.LogInfoCat(ACategory: TEncodingLogCategory;
  const AMsg: string);
begin
  Log(ellInfo, ACategory, AMsg, []);
end;

procedure TEncodingLogger.LogWarningCat(ACategory: TEncodingLogCategory;
  const AMsg: string);
begin
  Log(ellWarning, ACategory, AMsg, []);
end;

procedure TEncodingLogger.LogErrorCat(ACategory: TEncodingLogCategory;
  const AMsg: string);
begin
  Log(ellError, ACategory, AMsg, []);
end;

procedure TEncodingLogger.LogInfo(const AMsg: string);
begin
  Log(ellInfo, elcDetection, AMsg, []);
end;

procedure TEncodingLogger.LogWarning(const AMsg: string);
begin
  Log(ellWarning, elcDetection, AMsg, []);
end;

procedure TEncodingLogger.LogError(const AMsg: string);
begin
  Log(ellError, elcDetection, AMsg, []);
end;

procedure TEncodingLogger.LogDebug(const AMsg: string);
begin
  Log(ellVerbose, elcDetection, AMsg, []);
end;

procedure TEncodingLogger.LogPerformance(ACategory: TEncodingLogCategory;
  const AOperation: string; ADuration: Int64; const AAdditionalInfo: string);
var
  Entry: TEncodingLogEntry;
  I: Integer;
  Listener: TEncodingLogListener;
begin
  // Skip if duration is below threshold
  if ADuration < FPerformanceThreshold then
    Exit;

  if not ShouldLog(ellPerformance, ACategory) then
    Exit;

  Entry := GetLogEntry;
  try
    Entry.FTimestamp := Now;
    Entry.FLevel := ellPerformance;
    Entry.FCategory := ACategory;
    Entry.FMessage := AOperation;
    Entry.FDuration := ADuration;

    if AAdditionalInfo <> '' then
      Entry.AddInfo('details', AAdditionalInfo);

    FLock.Enter;
    try
      for I := 0 to FListeners.Count - 1 do
      begin
        Listener := FListeners[I];
        if Assigned(Listener) and Listener.IsInterestedIn(ellPerformance, ACategory) then
          Listener.OnLog(Entry);
      end;
    finally
      FLock.Leave;
    end;
  finally
    ReturnLogEntry(Entry);
  end;
end;

function TEncodingLogger.StartTiming(ACategory: TEncodingLogCategory;
  const AOperation: string): TDateTime;
begin
  // Return current time for timing calculation
  Result := Now;

  // Log operation start if verbose logging is enabled
  if ShouldLog(ellVerbose, ACategory) then
    LogVerbose(ACategory, Format('Starting operation: %s', [AOperation]));
end;

procedure TEncodingLogger.EndTiming(ACategory: TEncodingLogCategory;
  const AOperation: string; AStartTime: TDateTime; const AAdditionalInfo: string);
var
  DurationMS: Int64;
begin
  // Calculate duration in milliseconds
  DurationMS := Trunc((Now - AStartTime) * 86400000);

  // Log performance info
  LogPerformance(ACategory, AOperation, DurationMS, AAdditionalInfo);
end;

end.