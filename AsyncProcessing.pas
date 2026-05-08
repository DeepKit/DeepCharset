unit AsyncProcessing;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs;

type
  TFileTask = record
    SourceFile: string;
    TargetFile: string;
    SourceEncoding: string; // empty for auto
    TargetEncoding: string;
    AddBOM: Boolean;
    StreamingMode: Integer; // -1 auto, 0 non-streaming, 1 streaming
  end;

  TProgressEvent = procedure(const FileName: string; Pct: Integer) of object;

  TAsyncFileProcessor = class(TThread)
  private
    FQueue: TQueue<TFileTask>;
    FLock: TObject;
    FEvent: TEvent;
    FCancelled: Boolean;
    FOnProgress: TProgressEvent;
    procedure DoOnProgress(const FileName: string; Pct: Integer);
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Enqueue(const Task: TFileTask);
    procedure Cancel;
    procedure StopAndWait(TimeoutMS: Cardinal = INFINITE);
    property OnProgress: TProgressEvent read FOnProgress write FOnProgress;
  end;

implementation

uses
  EncodingConverter_Improved;

{ TAsyncFileProcessor }

constructor TAsyncFileProcessor.Create;
begin
  inherited Create(True);
  FQueue := TQueue<TFileTask>.Create;
  FLock := TObject.Create;
  FEvent := TEvent.Create(nil, False, False, '');
  FreeOnTerminate := False;
  FCancelled := False;
  // 由调用方显式 Start，避免重复启动
end;

destructor TAsyncFileProcessor.Destroy;
begin
  FEvent.Free;
  FQueue.Free;
  inherited;
end;

procedure TAsyncFileProcessor.Cancel;
begin
  TMonitor.Enter(FLock);
  try
    FCancelled := True;
    FEvent.SetEvent;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TAsyncFileProcessor.DoOnProgress(const FileName: string; Pct: Integer);
begin
  if Assigned(FOnProgress) then
  begin
    // marshal to main thread for UI safety
    TThread.Queue(nil,
      procedure
      begin
        if Assigned(FOnProgress) then
          FOnProgress(FileName, Pct);
      end);
  end;
end;

procedure TAsyncFileProcessor.Enqueue(const Task: TFileTask);
begin
  TMonitor.Enter(FLock);
  try
    FQueue.Enqueue(Task);
    FEvent.SetEvent;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TAsyncFileProcessor.Execute;
var
  Task: TFileTask;
  Options: TEncodingConversionOptions;
  LocalCancelled: Boolean;
  LastPct: Integer;
  UseStreaming: Boolean;
begin
  while not Terminated do
  begin
    // wait for task
    if FEvent.WaitFor(100) = wrTimeout then
    begin
      // check cancel
      TMonitor.Enter(FLock);
      try
        LocalCancelled := FCancelled;
      finally
        TMonitor.Exit(FLock);
      end;
      if LocalCancelled then Exit;
      Continue;
    end;

    // fetch task
    TMonitor.Enter(FLock);
    try
      if FQueue.Count > 0 then
        Task := FQueue.Dequeue
      else
        Continue;
    finally
      TMonitor.Exit(FLock);
    end;

    // process task
    LastPct := -1;
    Options := TEncodingConverter_Improved.CreateDefaultOptions;
    Options.AddBOM := Task.AddBOM;
    Options.DetectSourceEncoding := Task.SourceEncoding = '';

    try
      // 决定是否使用流式
      if Task.StreamingMode = 0 then
        UseStreaming := False
      else if Task.StreamingMode = 1 then
        UseStreaming := True
      else
        UseStreaming := True; // UI 路径默认流式

      if UseStreaming then
      begin
        TEncodingConverter_Improved.ConvertFileStreamingWithProgress(
          Task.SourceFile,
          Task.TargetFile,
          Task.SourceEncoding,
          Task.TargetEncoding,
          Options,
          procedure(P: Integer)
          begin
            // respond to cancellation quickly
            TMonitor.Enter(FLock);
            try
              if FCancelled then
                System.SysUtils.Abort;
            finally
              TMonitor.Exit(FLock);
            end;
            if P <> LastPct then
            begin
              LastPct := P;
              DoOnProgress(Task.SourceFile, P);
            end;
          end
        );
      end
      else
      begin
        // 非流式：一次性转换，直接报告 0 -> 100
        DoOnProgress(Task.SourceFile, 0);
        TEncodingConverter_Improved.ConvertFile(
          Task.SourceFile,
          Task.TargetFile,
          Task.SourceEncoding,
          Task.TargetEncoding,
          Options
        );
        DoOnProgress(Task.SourceFile, 100);
      end;
    except
      on E: EAbort do
      begin
        // cancelled
        Exit;
      end;
      on E: Exception do
      begin
        // swallow per-file errors, continue with next
      end;
    end;
  end;
end;

procedure TAsyncFileProcessor.StopAndWait(TimeoutMS: Cardinal);
begin
  Terminate;
  FEvent.SetEvent;
  WaitFor;
end;

end.
