unit AsyncScanning;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.IOUtils, System.SyncObjs;

type
  TFileFoundEvent = procedure(const FilePath: string) of object;
  TScanProgressEvent = procedure(FoundCount: Integer) of object;
  TScanCompleteEvent = procedure(TotalFound: Integer; Cancelled: Boolean) of object;
  TScanTotalEvent = procedure(TotalToScan: Integer) of object;

  TAsyncFileScanner = class(TThread)
  private
    FRootDir: string;
    FExtensions: TArray<string>;
    FIncludeSubdirs: Boolean;
    FCancelled: Boolean;
    FFoundCount: Integer;
    FTotalCount: Integer;
    FExceededCap: Boolean;
    FEnableEstimate: Boolean;
    FCountCap: Integer;
    FOnFound: TFileFoundEvent;
    FOnProgress: TScanProgressEvent;
    FOnComplete: TScanCompleteEvent;
    FOnTotal: TScanTotalEvent;
    FLock: TObject;
    procedure DoFound(const FilePath: string);
    procedure DoProgress;
    procedure DoComplete(Cancelled: Boolean);
    procedure DoTotal;
    function MatchExtension(const FileName: string): Boolean;
    procedure ScanDir(const Dir: string);
    function CountDir(const Dir: string): Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const ARootDir: string; const AExtensions: TArray<string>; AIncludeSubdirs: Boolean);
    destructor Destroy; override;
    procedure Cancel;
    property OnFound: TFileFoundEvent read FOnFound write FOnFound;
    property OnProgress: TScanProgressEvent read FOnProgress write FOnProgress;
    property OnComplete: TScanCompleteEvent read FOnComplete write FOnComplete;
    property OnTotal: TScanTotalEvent read FOnTotal write FOnTotal;
    // 配置项
    property EnableEstimate: Boolean read FEnableEstimate write FEnableEstimate;
    property CountCap: Integer read FCountCap write FCountCap;
  end;

implementation

{ TAsyncFileScanner }

constructor TAsyncFileScanner.Create(const ARootDir: string; const AExtensions: TArray<string>; AIncludeSubdirs: Boolean);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FRootDir := ARootDir;
  FExtensions := Copy(AExtensions);
  FIncludeSubdirs := AIncludeSubdirs;
  FCancelled := False;
  FFoundCount := 0;
  FTotalCount := 0;
  FExceededCap := False;
  FEnableEstimate := True;
  FCountCap := 200000;
  FLock := TObject.Create;
  // 由调用方显式 Start，避免重复启动
end;

destructor TAsyncFileScanner.Destroy;
begin
  FLock.Free;
  inherited;
end;

procedure TAsyncFileScanner.Cancel;
begin
  TMonitor.Enter(FLock);
  try
    FCancelled := True;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TAsyncFileScanner.DoFound(const FilePath: string);
begin
  if Assigned(FOnFound) then
    TThread.Queue(nil,
      procedure
      begin
        if Assigned(FOnFound) then
          FOnFound(FilePath);
      end);
end;

procedure TAsyncFileScanner.DoProgress;
begin
  if Assigned(FOnProgress) then
    TThread.Queue(nil,
      procedure
      begin
        if Assigned(FOnProgress) then
          FOnProgress(FFoundCount);
      end);
end;

procedure TAsyncFileScanner.DoTotal;
begin
  if Assigned(FOnTotal) then
    TThread.Queue(nil,
      procedure
      begin
        if Assigned(FOnTotal) then
          FOnTotal(FTotalCount);
      end);
end;

procedure TAsyncFileScanner.DoComplete(Cancelled: Boolean);
begin
  if Assigned(FOnComplete) then
    TThread.Queue(nil,
      procedure
      begin
        if Assigned(FOnComplete) then
          FOnComplete(FFoundCount, Cancelled);
      end);
end;

function TAsyncFileScanner.MatchExtension(const FileName: string): Boolean;
var
  Ext: string;
  i: Integer;
begin
  if Length(FExtensions) = 0 then
    Exit(True);
  Ext := LowerCase(ExtractFileExt(FileName));
  for i := 0 to High(FExtensions) do
  begin
    if Ext = LowerCase(FExtensions[i]) then
      Exit(True);
  end;
  Result := False;
end;

procedure TAsyncFileScanner.ScanDir(const Dir: string);
var
  Files: TArray<string>;
  SubDirs: TArray<string>;
  FileName: string;
  Sub: string;
  Cancelled: Boolean;
begin
  TMonitor.Enter(FLock);
  Cancelled := FCancelled;
  TMonitor.Exit(FLock);
  if Cancelled or Terminated then Exit;

  // 当前目录文件
  try
    Files := TDirectory.GetFiles(Dir);
    for FileName in Files do
    begin
      TMonitor.Enter(FLock);
      Cancelled := FCancelled;
      TMonitor.Exit(FLock);
      if Cancelled or Terminated then Exit;
      if MatchExtension(FileName) then
      begin
        Inc(FFoundCount);
        DoFound(FileName);
        if (FFoundCount mod 100) = 0 then
          DoProgress;
      end;
    end;
  except
    // 忽略访问异常
  end;

  // 子目录
  if FIncludeSubdirs then
  begin
    try
      SubDirs := TDirectory.GetDirectories(Dir);
      for Sub in SubDirs do
      begin
        TMonitor.Enter(FLock);
        Cancelled := FCancelled;
        TMonitor.Exit(FLock);
        if Cancelled or Terminated then Exit;
        ScanDir(Sub);
      end;
    except
      // 忽略访问异常
    end;
  end;
end;

function TAsyncFileScanner.CountDir(const Dir: string): Integer;
var
  SR: TSearchRec;
  Res: Integer;
  Cancelled: Boolean;
begin
  Result := 0;
  // 统计当前目录文件
  Res := FindFirst(IncludeTrailingPathDelimiter(Dir) + '*.*', faAnyFile, SR);
  try
    while Res = 0 do
    begin
      if (SR.Name <> '.') and (SR.Name <> '..') then
      begin
        TMonitor.Enter(FLock);
        Cancelled := FCancelled;
        TMonitor.Exit(FLock);
        if Cancelled or Terminated then Exit;
        if (SR.Attr and faDirectory) = 0 then
        begin
          if MatchExtension(SR.Name) then
          begin
            Inc(Result);
            if (FCountCap > 0) and (Result >= FCountCap) then
            begin
              FExceededCap := True;
              Exit;
            end;
          end;
        end
        else if FIncludeSubdirs then
        begin
          Inc(Result, CountDir(IncludeTrailingPathDelimiter(Dir) + SR.Name));
          if (FCountCap > 0) and (Result >= FCountCap) then
          begin
            FExceededCap := True;
            Exit;
          end;
        end;
      end;
      Res := FindNext(SR);
    end;
  finally
    FindClose(SR);
  end;
end;

procedure TAsyncFileScanner.Execute;
var
  Cancelled: Boolean;
begin
  try
    if FRootDir <> '' then
    begin
      FExceededCap := False;
      if FEnableEstimate then
      begin
        FTotalCount := CountDir(FRootDir);
        if FExceededCap then
          FTotalCount := -1;
      end
      else
        FTotalCount := -1;
      DoTotal;
      ScanDir(FRootDir);
    end;
  finally
    TMonitor.Enter(FLock);
    Cancelled := FCancelled;
    TMonitor.Exit(FLock);
    DoProgress;
    DoComplete(Cancelled);
  end;
end;

end.
