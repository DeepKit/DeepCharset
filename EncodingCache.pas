unit EncodingCache;

interface

uses
  System.SysUtils, System.Generics.Collections, System.IOUtils;

type
  TEncodingCacheEntry = record
    Encoding: string;
    HasBOM: Boolean;
    LastWriteTime: TDateTime;
  end;

  TEncodingCache = class
  private
    FMap: TDictionary<string, TEncodingCacheEntry>;
    FLock: TObject;
  public
    constructor Create;
    destructor Destroy; override;
    function TryGet(const FileName: string; out Entry: TEncodingCacheEntry): Boolean;
    procedure Put(const FileName: string; const Encoding: string; HasBOM: Boolean; LastWriteTime: TDateTime);
    class function Instance: TEncodingCache;
  end;

implementation

var
  GCache: TEncodingCache;

{ TEncodingCache }

constructor TEncodingCache.Create;
begin
  inherited Create;
  FMap := TDictionary<string, TEncodingCacheEntry>.Create;
  FLock := TObject.Create;
end;

destructor TEncodingCache.Destroy;
begin
  FMap.Free;
  inherited;
end;

class function TEncodingCache.Instance: TEncodingCache;
begin
  if GCache = nil then
    GCache := TEncodingCache.Create;
  Result := GCache;
end;

procedure TEncodingCache.Put(const FileName: string; const Encoding: string; HasBOM: Boolean; LastWriteTime: TDateTime);
var
  Entry: TEncodingCacheEntry;
begin
  TMonitor.Enter(FLock);
  try
    Entry.Encoding := Encoding;
    Entry.HasBOM := HasBOM;
    Entry.LastWriteTime := LastWriteTime;
    FMap.AddOrSetValue(FileName, Entry);
  finally
    TMonitor.Exit(FLock);
  end;
end;

function TEncodingCache.TryGet(const FileName: string; out Entry: TEncodingCacheEntry): Boolean;
begin
  TMonitor.Enter(FLock);
  try
    Result := FMap.TryGetValue(FileName, Entry);
  finally
    TMonitor.Exit(FLock);
  end;
end;

initialization
  GCache := nil;

finalization
  FreeAndNil(GCache);

end.
