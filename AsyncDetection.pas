unit AsyncDetection;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs, System.IOUtils, System.Math, UtilsTypes;

type
  TDetectedFile = record
    FilePath: string;
    Encoding: string;
    HasBOM: Boolean;
  end;
  TBatchDetectedEvent = procedure(const Results: TArray<TDetectedFile>) of object;

  TAsyncEncodingDetector = class(TThread)
  private
    FQueue: TQueue<string>;
    FLock: TObject;
    FEvent: TEvent;
    FCancelled: Boolean;
    FBatch: TList<TDetectedFile>;
    FOnBatch: TBatchDetectedEvent;
    FBatchSize: Integer;
    FFlushIntervalMS: Cardinal;
    FDelivery: TArray<TDetectedFile>;
    procedure FlushBatch;
    procedure DeliverBatch;
    function DetectFileEncoding(const FileName: string; out HasBOM: Boolean): string;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Enqueue(const FilePath: string);
    procedure Cancel;
    procedure StopAndWait;
    procedure FlushNow; // 主线程请求立即交付当前批次
    property OnBatch: TBatchDetectedEvent read FOnBatch write FOnBatch;
    property BatchSize: Integer read FBatchSize write FBatchSize;
    property FlushIntervalMS: Cardinal read FFlushIntervalMS write FFlushIntervalMS;
  end;

implementation

uses
  UtilsEncodingBOM_Improved,
  UtilsEncodingUTF8Detector_Improved,
  ChineseEncodingDetector_Improved,
  JapaneseEncodingDetector_Improved,
  KoreanEncodingDetector_Improved;

{ TAsyncEncodingDetector }

constructor TAsyncEncodingDetector.Create;
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FQueue := TQueue<string>.Create;
  FBatch := TList<TDetectedFile>.Create;
  FLock := TObject.Create;
  FEvent := TEvent.Create(nil, False, False, '');
  FCancelled := False;
  FBatchSize := 64;
  FFlushIntervalMS := 200;
  // 由调用方显式 Start，避免重复启动
end;

destructor TAsyncEncodingDetector.Destroy;
begin
  FEvent.Free;
  FBatch.Free;
  FQueue.Free;
  FLock.Free;
  inherited;
end;

procedure TAsyncEncodingDetector.Cancel;
begin
  TMonitor.Enter(FLock);
  try
    FCancelled := True;
    FEvent.SetEvent;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TAsyncEncodingDetector.Enqueue(const FilePath: string);
begin
  TMonitor.Enter(FLock);
  try
    FQueue.Enqueue(FilePath);
    FEvent.SetEvent;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TAsyncEncodingDetector.StopAndWait;
begin
  Terminate;
  FEvent.SetEvent;
  WaitFor;
end;

procedure TAsyncEncodingDetector.FlushNow;
begin
  // 主线程调用：触发一次批量交付
  FlushBatch;
end;

function TAsyncEncodingDetector.DetectFileEncoding(const FileName: string; out HasBOM: Boolean): string;
var
  BOMResult: TBOMDetectionResult;
  UTF8Result: TUTF8DetectionResult;
  ChineseResult: TChineseEncodingResult;
  JapaneseResult: TJapaneseEncodingResult;
  KoreanResult: TKoreanEncodingResult;
  Buffer: TBytes;
  FS: TFileStream;
begin
  Result := 'ANSI';
  HasBOM := False;
  if not FileExists(FileName) then Exit;
  try
    BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromFile(FileName);
    if BOMResult.BOMType <> 0 then
    begin
      Result := string(BOMResult.Encoding);
      HasBOM := True;
      Exit;
    end;
    // 无 BOM，读前 4MB 进行检测
    FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      SetLength(Buffer, Min(FS.Size, 4 * 1024 * 1024));
      if Length(Buffer) > 0 then
        FS.ReadBuffer(Buffer[0], Length(Buffer));
    finally
      FS.Free;
    end;
    UTF8Result := TUTF8EncodingDetector_Improved.DetectBuffer(Buffer);
    if UTF8Result.IsUTF8 then
    begin
      Result := 'UTF-8';
      HasBOM := False;
      Exit;
    end;
    // Japanese
    JapaneseResult := TJapaneseEncodingDetector_Improved.DetectBuffer(Buffer);
    if (JapaneseResult.Confidence >= 0.75) and (JapaneseResult.Encoding <> ENCODING_ANSI) and (JapaneseResult.Encoding <> ENCODING_UNKNOWN) then
    begin
      Result := string(JapaneseResult.Encoding);
      HasBOM := JapaneseResult.HasBOM;
      Exit;
    end;
    // Korean
    KoreanResult := TKoreanEncodingDetector_Improved.DetectBuffer(Buffer);
    if (KoreanResult.Confidence >= 0.75) and (KoreanResult.Encoding <> ENCODING_ANSI) and (KoreanResult.Encoding <> ENCODING_UNKNOWN) then
    begin
      Result := string(KoreanResult.Encoding);
      HasBOM := KoreanResult.HasBOM;
      Exit;
    end;
    // Chinese fallback
    ChineseResult := TChineseEncodingDetector_Improved.DetectBuffer(Buffer);
    if ChineseResult.Encoding <> '' then
    begin
      Result := string(ChineseResult.Encoding);
      HasBOM := ChineseResult.HasBOM;
    end
    else
    begin
      Result := 'ANSI';
      HasBOM := False;
    end;
  except
    // ignore detection errors
  end;
end;

procedure TAsyncEncodingDetector.DeliverBatch;
begin
  if Assigned(FOnBatch) and (Length(FDelivery) > 0) then
    FOnBatch(FDelivery);
  SetLength(FDelivery, 0);
end;

procedure TAsyncEncodingDetector.FlushBatch;
var
  Arr: TArray<TDetectedFile>;
begin
  if (FBatch.Count = 0) or not Assigned(FOnBatch) then Exit;
  SetLength(Arr, FBatch.Count);
  for var i := 0 to FBatch.Count - 1 do
    Arr[i] := FBatch[i];
  FBatch.Clear;
  FDelivery := Arr;
  // 使用同步调用保证兼容性
  Synchronize(DeliverBatch);
end;

procedure TAsyncEncodingDetector.Execute;
var
  FN: string;
  LocalCancelled: Boolean;
  LastFlush: Cardinal;
  NowTick: Cardinal;
  Info: TDetectedFile;
begin
  LastFlush := GetTickCount;
  while not Terminated do
  begin
    if FEvent.WaitFor(100) = wrTimeout then
    begin
      // periodic flush
      NowTick := GetTickCount;
      if (NowTick - LastFlush >= FFlushIntervalMS) then
      begin
        FlushBatch;
        LastFlush := NowTick;
      end;
      Continue;
    end;
    // check cancel
    TMonitor.Enter(FLock);
    try
      LocalCancelled := FCancelled;
      if (not LocalCancelled) and (FQueue.Count > 0) then
        FN := FQueue.Dequeue
      else
        FN := '';
    finally
      TMonitor.Exit(FLock);
    end;
    if LocalCancelled then
    begin
      // 若用户取消，确保交付当前已累积的批次再退出
      FlushBatch;
      Exit;
    end;
    if FN = '' then
      Continue;
    // detect
    Info.FilePath := FN;
    Info.Encoding := DetectFileEncoding(FN, Info.HasBOM);
    FBatch.Add(Info);
    if FBatch.Count >= FBatchSize then
    begin
      FlushBatch;
      LastFlush := GetTickCount;
    end;
  end;
  // thread terminating, flush remaining
  FlushBatch;
end;

end.
