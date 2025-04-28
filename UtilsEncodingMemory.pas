unit UtilsEncodingMemory;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.Math, System.Generics.Collections
  {$IFDEF MSWINDOWS}
  , Vcl.Forms, Winapi.Windows
  {$ENDIF};

type
  // 内存块结构
  TMemoryBlock = record
    Data: TBytes;
    Size: Integer;
    InUse: Boolean;
  end;

  // 内存池管理器
  TMemoryPool = class
  private
    FBlocks: TArray<TMemoryBlock>;
    FMaxBlockSize: Integer;
    FMinBlockSize: Integer;
    FTotalSize: Integer;
    FMaxTotalSize: Integer;

    function FindFreeBlock(Size: Integer): Integer;

  protected
    procedure CompactBlocks; virtual;

  public
    constructor Create(MaxBlockSize: Integer = 1024 * 1024; // 1MB
                      MinBlockSize: Integer = 4096;         // 4KB
                      MaxTotalSize: Integer = 10 * 1024 * 1024); // 10MB
    destructor Destroy; override;

    function AllocateBuffer(Size: Integer): TBytes; virtual;
    procedure ReleaseBuffer(var Buffer: TBytes); virtual;
    procedure Clear; virtual;

    property TotalSize: Integer read FTotalSize;
  end;

  // 线程安全的内存池
  TThreadSafeMemoryPool = class(TMemoryPool)
  private
    FLock: TCriticalSection;
  protected
    procedure CompactBlocks; override;
  public
    constructor Create(MaxBlockSize: Integer = 1024 * 1024;
                      MinBlockSize: Integer = 4096;
                      MaxTotalSize: Integer = 10 * 1024 * 1024); reintroduce;
    destructor Destroy; override;
    function AllocateBuffer(Size: Integer): TBytes; override;
    procedure ReleaseBuffer(var Buffer: TBytes); override;
    procedure Clear; override;
  end;

  TMemoryManager = class
  private
    FBufferSize: Integer;
    FBufferPool: TObjectList<TMemoryStream>;
    FLock: TCriticalSection;

    procedure InitializeBufferPool;
    function GetBufferFromPool: TMemoryStream;
    procedure ReturnBufferToPool(Stream: TMemoryStream);

  public
    constructor Create;
    destructor Destroy; override;

    function GetCurrentMemoryUsage: NativeUInt;
    procedure ForceGarbageCollection;
    procedure PreallocateBuffers(Count: Integer);
    procedure ClearBufferPool;

    property BufferSize: Integer read FBufferSize write FBufferSize;
  end;

  TMemoryChunkReader = class
  private
    FStream: TStream;
    FChunkSize: Integer;
    FBuffer: TMemoryStream;
    FPosition: Int64;
    FMemoryManager: TMemoryManager;

  public
    constructor Create(Stream: TStream; ChunkSize: Integer = 1024 * 1024); // 默认1MB
    destructor Destroy; override;

    function ReadChunk: Boolean;
    procedure Reset;

    property Buffer: TMemoryStream read FBuffer;
    property Position: Int64 read FPosition;
  end;

implementation

{ TMemoryPool }

constructor TMemoryPool.Create(MaxBlockSize, MinBlockSize, MaxTotalSize: Integer);
begin
  inherited Create;
  FMaxBlockSize := MaxBlockSize;
  FMinBlockSize := MinBlockSize;
  FMaxTotalSize := MaxTotalSize;
  FTotalSize := 0;
  SetLength(FBlocks, 0);
end;

destructor TMemoryPool.Destroy;
begin
  Clear;
  inherited;
end;

function TMemoryPool.FindFreeBlock(Size: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;

  // 首先尝试找到一个合适大小的空闲块
  for I := 0 to Length(FBlocks) - 1 do
  begin
    if (not FBlocks[I].InUse) and (FBlocks[I].Size >= Size) then
    begin
      Result := I;
      Break;
    end;
  end;

  // 如果没有找到合适的块，尝试压缩
  if Result = -1 then
  begin
    CompactBlocks;

    // 再次查找
    for I := 0 to Length(FBlocks) - 1 do
    begin
      if (not FBlocks[I].InUse) and (FBlocks[I].Size >= Size) then
      begin
        Result := I;
        Break;
      end;
    end;
  end;
end;

procedure TMemoryPool.CompactBlocks;
var
  I, J: Integer;
  ValidBlocks: TArray<TMemoryBlock>;
begin
  SetLength(ValidBlocks, 0);

  // 保留所有正在使用的块
  for I := 0 to Length(FBlocks) - 1 do
  begin
    if FBlocks[I].InUse then
    begin
      SetLength(ValidBlocks, Length(ValidBlocks) + 1);
      ValidBlocks[High(ValidBlocks)] := FBlocks[I];
    end;
  end;

  FBlocks := ValidBlocks;

  // 重新计算总大小
  FTotalSize := 0;
  for I := 0 to Length(FBlocks) - 1 do
    Inc(FTotalSize, FBlocks[I].Size);
end;

function TMemoryPool.AllocateBuffer(Size: Integer): TBytes;
var
  BlockIndex: Integer;
  NewBlock: TMemoryBlock;
begin
  // 确保请求的大小在有效范围内
  if Size < FMinBlockSize then
    Size := FMinBlockSize
  else if Size > FMaxBlockSize then
    raise EOutOfMemory.CreateFmt('请求的缓冲区大小(%d)超过最大限制(%d)',
      [Size, FMaxBlockSize]);

  // 查找可用块
  BlockIndex := FindFreeBlock(Size);

  // 如果没有找到合适的块，创建新块
  if BlockIndex = -1 then
  begin
    // 检查是否超过总大小限制
    if FTotalSize + Size > FMaxTotalSize then
    begin
      // 尝试压缩和清理
      CompactBlocks;

      // 如果仍然超过限制，抛出异常
      if FTotalSize + Size > FMaxTotalSize then
        raise EOutOfMemory.CreateFmt('内存池已满(当前:%d, 限制:%d)',
          [FTotalSize, FMaxTotalSize]);
    end;

    // 创建新块
    SetLength(NewBlock.Data, Size);
    NewBlock.Size := Size;
    NewBlock.InUse := True;

    SetLength(FBlocks, Length(FBlocks) + 1);
    FBlocks[High(FBlocks)] := NewBlock;
    Inc(FTotalSize, Size);

    Result := NewBlock.Data;
  end
  else
  begin
    // 使用现有块
    FBlocks[BlockIndex].InUse := True;
    Result := FBlocks[BlockIndex].Data;
  end;
end;

procedure TMemoryPool.ReleaseBuffer(var Buffer: TBytes);
var
  I: Integer;
begin
  // 查找并释放对应的块
  for I := 0 to Length(FBlocks) - 1 do
  begin
    if FBlocks[I].Data = Buffer then
    begin
      FBlocks[I].InUse := False;
      Break;
    end;
  end;

  // 清空传入的缓冲区
  SetLength(Buffer, 0);

  // 如果空闲块太多，进行压缩
  if Length(FBlocks) > 10 then
    CompactBlocks;
end;

procedure TMemoryPool.Clear;
begin
  SetLength(FBlocks, 0);
  FTotalSize := 0;
end;

{ TThreadSafeMemoryPool }

constructor TThreadSafeMemoryPool.Create(MaxBlockSize: Integer = 1024 * 1024;
                                          MinBlockSize: Integer = 4096;
                                          MaxTotalSize: Integer = 10 * 1024 * 1024);
begin
  inherited Create(MaxBlockSize, MinBlockSize, MaxTotalSize);
  FLock := TCriticalSection.Create;
end;

destructor TThreadSafeMemoryPool.Destroy;
begin
  FLock.Free;
  inherited;
end;

function TThreadSafeMemoryPool.AllocateBuffer(Size: Integer): TBytes;
begin
  FLock.Enter;
  try
    Result := inherited AllocateBuffer(Size);
  finally
    FLock.Leave;
  end;
end;

procedure TThreadSafeMemoryPool.ReleaseBuffer(var Buffer: TBytes);
begin
  FLock.Enter;
  try
    inherited ReleaseBuffer(Buffer);
  finally
    FLock.Leave;
  end;
end;

procedure TThreadSafeMemoryPool.Clear;
begin
  FLock.Enter;
  try
    inherited Clear;
  finally
    FLock.Leave;
  end;
end;

procedure TThreadSafeMemoryPool.CompactBlocks;
begin
  FLock.Enter;
  try
    inherited CompactBlocks;
  finally
    FLock.Leave;
  end;
end;

{ TMemoryManager }

constructor TMemoryManager.Create;
begin
  inherited;
  FLock := TCriticalSection.Create;
  FBufferPool := TObjectList<TMemoryStream>.Create;
  FBufferSize := 1024 * 1024; // 默认1MB
  InitializeBufferPool;
end;

destructor TMemoryManager.Destroy;
begin
  ClearBufferPool;
  FBufferPool.Free;
  FLock.Free;
  inherited;
end;

procedure TMemoryManager.InitializeBufferPool;
begin
  // 预分配10个缓冲区
  PreallocateBuffers(10);
end;

function TMemoryManager.GetBufferFromPool: TMemoryStream;
begin
  FLock.Enter;
  try
    if FBufferPool.Count > 0 then
    begin
      Result := FBufferPool[FBufferPool.Count - 1];
      FBufferPool.Delete(FBufferPool.Count - 1);
    end
    else
    begin
      Result := TMemoryStream.Create;
      Result.Size := FBufferSize;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TMemoryManager.ReturnBufferToPool(Stream: TMemoryStream);
begin
  FLock.Enter;
  try
    Stream.Position := 0;
    Stream.Size := FBufferSize;
    FBufferPool.Add(Stream);
  finally
    FLock.Leave;
  end;
end;

function TMemoryManager.GetCurrentMemoryUsage: NativeUInt;
begin
  Result := GetHeapStatus.TotalAllocated;
end;

procedure TMemoryManager.ForceGarbageCollection;
begin
  // 清理未使用的缓冲区
  while FBufferPool.Count > 10 do
    FBufferPool.Delete(FBufferPool.Count - 1);

  // 强制垃圾回收
  // 使用简单方法
  {$IFDEF MSWINDOWS}
  Application.ProcessMessages;
  {$ENDIF}
  // 触发垃圾回收
  // 使用简单方法
  Sleep(0);
end;

procedure TMemoryManager.PreallocateBuffers(Count: Integer);
var
  I: Integer;
  Stream: TMemoryStream;
begin
  FLock.Enter;
  try
    for I := 1 to Count do
    begin
      Stream := TMemoryStream.Create;
      Stream.Size := FBufferSize;
      FBufferPool.Add(Stream);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TMemoryManager.ClearBufferPool;
begin
  FLock.Enter;
  try
    FBufferPool.Clear;
  finally
    FLock.Leave;
  end;
end;

{ TMemoryChunkReader }

constructor TMemoryChunkReader.Create(Stream: TStream; ChunkSize: Integer);
begin
  inherited Create;
  FStream := Stream;
  FChunkSize := ChunkSize;
  FPosition := 0;
  FMemoryManager := TMemoryManager.Create;
  FBuffer := FMemoryManager.GetBufferFromPool;
end;

destructor TMemoryChunkReader.Destroy;
begin
  if FBuffer <> nil then
    FMemoryManager.ReturnBufferToPool(FBuffer);
  inherited;
end;

function TMemoryChunkReader.ReadChunk: Boolean;
var
  BytesRead: Integer;
begin
  Result := False;
  if FStream = nil then Exit;

  FBuffer.Clear;
  BytesRead := FStream.Read(FBuffer.Memory^, FChunkSize);
  if BytesRead > 0 then
  begin
    FBuffer.Size := BytesRead;
    Inc(FPosition, BytesRead);
    Result := True;
  end;
end;

procedure TMemoryChunkReader.Reset;
begin
  if FStream <> nil then
  begin
    FStream.Position := 0;
    FPosition := 0;
  end;
end;

end.