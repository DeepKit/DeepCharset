unit UtilsBufferPool;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  TBufferPoolStats = record
    TotalCreated: Integer;
    InUse: Integer;
    PeakInUse: Integer;
    AcquireCount: Integer;
    ReleaseCount: Integer;
    PoolCount: Integer;
  end;

  TEncodingBufferPool = class
  private
    FPool: TList<TBytes>;
    FLock: TObject;
    FMaxPoolSize: Integer;
    FTotalCreated: Integer;
    FInUse: Integer;
    FPeakInUse: Integer;
    FAcquireCount: Integer;
    FReleaseCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function AcquireBuffer(ASize: Integer): TBytes;
    procedure ReleaseBuffer(var ABuffer: TBytes);
    function GetStats: TBufferPoolStats;
    property MaxPoolSize: Integer read FMaxPoolSize write FMaxPoolSize;
  end;

  TStreamPool = class
  private
    FPool: TObjectList<TMemoryStream>;
    FLock: TObject;
  public
    constructor Create;
    destructor Destroy; override;
    function Acquire: TMemoryStream;
    procedure Release(AStream: TMemoryStream);
  end;

var
  GlobalBufferPool: TEncodingBufferPool;
  GlobalStreamPool: TStreamPool;

function GetBufferPoolStats: TBufferPoolStats;

implementation

{ TEncodingBufferPool }

constructor TEncodingBufferPool.Create;
begin
  inherited Create;
  FPool := TList<TBytes>.Create;
  FLock := TObject.Create;
  FMaxPoolSize := 128;
  FTotalCreated := 0;
  FInUse := 0;
  FPeakInUse := 0;
  FAcquireCount := 0;
  FReleaseCount := 0;
end;

destructor TEncodingBufferPool.Destroy;
begin
  FPool.Free;
  FLock.Free;
  inherited;
end;

function TEncodingBufferPool.AcquireBuffer(ASize: Integer): TBytes;
var
  I: Integer;
  Buf: TBytes;
begin
  TMonitor.Enter(FLock);
  try
    if FPool.Count > 0 then
    begin
      // Pop last
      I := FPool.Count - 1;
      Buf := FPool.Items[I];
      FPool.Delete(I);
      if Length(Buf) < ASize then
        SetLength(Buf, ASize);
      Result := Buf;
      Inc(FAcquireCount);
      Inc(FInUse);
      if FInUse > FPeakInUse then FPeakInUse := FInUse;
      Exit;
    end;
  finally
    TMonitor.Exit(FLock);
  end;
  SetLength(Result, ASize);
  TMonitor.Enter(FLock);
  try
    Inc(FTotalCreated);
    Inc(FAcquireCount);
    Inc(FInUse);
    if FInUse > FPeakInUse then FPeakInUse := FInUse;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TEncodingBufferPool.ReleaseBuffer(var ABuffer: TBytes);
begin
  if Length(ABuffer) = 0 then Exit;
  TMonitor.Enter(FLock);
  try
    if FInUse > 0 then Dec(FInUse);
    Inc(FReleaseCount);
    if FPool.Count < FMaxPoolSize then
      FPool.Add(ABuffer);
  finally
    TMonitor.Exit(FLock);
  end;
  SetLength(ABuffer, 0);
end;

function TEncodingBufferPool.GetStats: TBufferPoolStats;
begin
  TMonitor.Enter(FLock);
  try
    Result.TotalCreated := FTotalCreated;
    Result.InUse := FInUse;
    Result.PeakInUse := FPeakInUse;
    Result.AcquireCount := FAcquireCount;
    Result.ReleaseCount := FReleaseCount;
    Result.PoolCount := FPool.Count;
  finally
    TMonitor.Exit(FLock);
  end;
end;

function GetBufferPoolStats: TBufferPoolStats;
begin
  if Assigned(GlobalBufferPool) then
    Result := GlobalBufferPool.GetStats
  else
    FillChar(Result, SizeOf(Result), 0);
end;

{ TStreamPool }

constructor TStreamPool.Create;
begin
  inherited Create;
  FPool := TObjectList<TMemoryStream>.Create(True);
  FLock := TObject.Create;
end;

destructor TStreamPool.Destroy;
begin
  FPool.Free;
  FLock.Free;
  inherited;
end;

function TStreamPool.Acquire: TMemoryStream;
begin
  TMonitor.Enter(FLock);
  try
    if FPool.Count > 0 then
    begin
      Result := FPool.Extract(FPool.Last);
      Result.Clear;
      Exit;
    end;
  finally
    TMonitor.Exit(FLock);
  end;
  Result := TMemoryStream.Create;
end;

procedure TStreamPool.Release(AStream: TMemoryStream);
begin
  if AStream = nil then Exit;
  AStream.Clear;
  TMonitor.Enter(FLock);
  try
    FPool.Add(AStream);
  finally
    TMonitor.Exit(FLock);
  end;
end;

initialization
  GlobalBufferPool := TEncodingBufferPool.Create;
  GlobalStreamPool := TStreamPool.Create;

finalization
  GlobalStreamPool.Free;
  GlobalBufferPool.Free;

end.
