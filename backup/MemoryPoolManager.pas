unit MemoryPoolManager;

interface

uses
  SysUtils, Classes, SyncObjs;

type
  /// <summary>
  /// 内存块结构，包含指向分配内存的指针和块大小
  /// </summary>
  TMemoryChunk = record
    Data: Pointer;    // 指向分配的内存块
    Size: Integer;    // 内存块大小
    IsInUse: Boolean; // 是否正在使用
    Tag: Integer;     // 用户自定义标记
  end;
  
  /// <summary>
  /// 内存块处理结果
  /// </summary>
  TChunkProcessResult = record
    Success: Boolean;        // 处理是否成功
    BytesProcessed: Integer; // 处理的字节数
    ErrorCode: Integer;      // 错误代码
    ErrorMessage: string;    // 错误消息
  end;

  /// <summary>
  /// 内存池类，管理内存块的分配和释放
  /// </summary>
  TMemoryPool = class
  private
    FChunkSize: Integer;        // 每个块的大小
    FPoolSize: Integer;         // 池中块的数量
    FManagedChunks: array of TMemoryChunk;  // 所有管理的内存块
    FAvailableCount: Integer;   // 可用块数量
    FCriticalSection: TCriticalSection; // 线程同步
    FTotalAllocated: Int64;     // 总共分配的内存
    FPeakUsage: Integer;        // 峰值使用数量
    
    procedure Initialize;
    procedure Cleanup;
  public
    constructor Create(ChunkSize: Integer; PoolSize: Integer);
    destructor Destroy; override;
    
    /// <summary>
    /// 从内存池分配一个内存块
    /// </summary>
    function AllocateChunk: TMemoryChunk;
    
    /// <summary>
    /// 将内存块释放回内存池
    /// </summary>
    procedure ReleaseChunk(var Chunk: TMemoryChunk);
    
    /// <summary>
    /// 获取当前可用块数量
    /// </summary>
    function GetAvailableCount: Integer;
    
    /// <summary>
    /// 获取统计信息
    /// </summary>
    procedure GetStats(out TotalAllocated: Int64; out PeakUsage: Integer);
    
    /// <summary>
    /// 清空内存池中所有数据（保留分配）
    /// </summary>
    procedure ResetChunks;
    
    property ChunkSize: Integer read FChunkSize;
    property PoolSize: Integer read FPoolSize;
  end;

  /// <summary>
  /// 内存池管理器，管理多个不同大小的内存池
  /// </summary>
  TMemoryPoolManager = class
  private
    FPools: array of TMemoryPool;
    FLock: TCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    
    /// <summary>
    /// 创建指定大小和容量的内存池
    /// </summary>
    function CreatePool(ChunkSize, PoolSize: Integer): Integer;
    
    /// <summary>
    /// 根据索引获取内存池
    /// </summary>
    function GetPool(Index: Integer): TMemoryPool;
    
    /// <summary>
    /// 从最合适的内存池分配内存块
    /// </summary>
    function AllocateChunk(MinSize: Integer): TMemoryChunk;
    
    /// <summary>
    /// 释放内存块
    /// </summary>
    procedure ReleaseChunk(var Chunk: TMemoryChunk);
    
    /// <summary>
    /// 清理所有池
    /// </summary>
    procedure ReleaseAllPools;
  end;

implementation

{ TMemoryPool }

constructor TMemoryPool.Create(ChunkSize, PoolSize: Integer);
begin
  inherited Create;
  
  if ChunkSize <= 0 then
    raise Exception.Create('内存块大小必须大于0');
    
  if PoolSize <= 0 then
    raise Exception.Create('内存池大小必须大于0');
    
  FChunkSize := ChunkSize;
  FPoolSize := PoolSize;
  FCriticalSection := TCriticalSection.Create;
  
  Initialize;
end;

destructor TMemoryPool.Destroy;
begin
  Cleanup;
  FCriticalSection.Free;
  inherited;
end;

procedure TMemoryPool.Initialize;
var
  i: Integer;
begin
  // 分配内存块数组
  SetLength(FManagedChunks, FPoolSize);
  FAvailableCount := FPoolSize;
  FTotalAllocated := 0;
  FPeakUsage := 0;
  
  // 初始化每个内存块
  for i := 0 to FPoolSize - 1 do
  begin
    // 分配内存
    FManagedChunks[i].Data := GetMemory(FChunkSize);
    FManagedChunks[i].Size := FChunkSize;
    FManagedChunks[i].IsInUse := False;
    FManagedChunks[i].Tag := 0;
    
    Inc(FTotalAllocated, FChunkSize);
  end;
end;

procedure TMemoryPool.Cleanup;
var
  i: Integer;
begin
  if Length(FManagedChunks) > 0 then
  begin
    // 释放所有内存块
    for i := 0 to FPoolSize - 1 do
    begin
      if Assigned(FManagedChunks[i].Data) then
        FreeMemory(FManagedChunks[i].Data);
    end;
    
    // 清空数组
    SetLength(FManagedChunks, 0);
  end;
end;

function TMemoryPool.AllocateChunk: TMemoryChunk;
var
  i: Integer;
begin
  FCriticalSection.Enter;
  try
    // 初始化返回值
    FillChar(Result, SizeOf(Result), 0);
    
    // 查找可用块
    for i := 0 to FPoolSize - 1 do
    begin
      if not FManagedChunks[i].IsInUse then
      begin
        FManagedChunks[i].IsInUse := True;
        Result := FManagedChunks[i];
        
        Dec(FAvailableCount);
        
        // 更新峰值使用量
        if FPoolSize - FAvailableCount > FPeakUsage then
          FPeakUsage := FPoolSize - FAvailableCount;
          
        Break;
      end;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TMemoryPool.ReleaseChunk(var Chunk: TMemoryChunk);
var
  i: Integer;
  Found: Boolean;
begin
  if Chunk.Data = nil then
    Exit;
    
  FCriticalSection.Enter;
  try
    Found := False;
    
    // 查找这个块并标记为可用
    for i := 0 to FPoolSize - 1 do
    begin
      if (FManagedChunks[i].Data = Chunk.Data) and FManagedChunks[i].IsInUse then
      begin
        FManagedChunks[i].IsInUse := False;
        FManagedChunks[i].Tag := 0;
        Inc(FAvailableCount);
        Found := True;
        Break;
      end;
    end;
    
    // 清空传入的块引用
    if Found then
    begin
      Chunk.Data := nil;
      Chunk.Size := 0;
      Chunk.IsInUse := False;
      Chunk.Tag := 0;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;

function TMemoryPool.GetAvailableCount: Integer;
begin
  FCriticalSection.Enter;
  try
    Result := FAvailableCount;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TMemoryPool.GetStats(out TotalAllocated: Int64; out PeakUsage: Integer);
begin
  FCriticalSection.Enter;
  try
    TotalAllocated := FTotalAllocated;
    PeakUsage := FPeakUsage;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TMemoryPool.ResetChunks;
var
  i: Integer;
begin
  FCriticalSection.Enter;
  try
    for i := 0 to FPoolSize - 1 do
    begin
      if Assigned(FManagedChunks[i].Data) then
        FillChar(FManagedChunks[i].Data^, FChunkSize, 0);
        
      FManagedChunks[i].IsInUse := False;
      FManagedChunks[i].Tag := 0;
    end;
    
    FAvailableCount := FPoolSize;
  finally
    FCriticalSection.Leave;
  end;
end;

{ TMemoryPoolManager }

constructor TMemoryPoolManager.Create;
begin
  inherited;
  FLock := TCriticalSection.Create;
  SetLength(FPools, 0);
end;

destructor TMemoryPoolManager.Destroy;
begin
  ReleaseAllPools;
  FLock.Free;
  inherited;
end;

function TMemoryPoolManager.CreatePool(ChunkSize, PoolSize: Integer): Integer;
var
  NewPool: TMemoryPool;
begin
  FLock.Enter;
  try
    NewPool := TMemoryPool.Create(ChunkSize, PoolSize);
    
    // 添加到池数组
    Result := Length(FPools);
    SetLength(FPools, Result + 1);
    FPools[Result] := NewPool;
  finally
    FLock.Leave;
  end;
end;

function TMemoryPoolManager.GetPool(Index: Integer): TMemoryPool;
begin
  Result := nil;
  
  FLock.Enter;
  try
    if (Index >= 0) and (Index < Length(FPools)) then
      Result := FPools[Index];
  finally
    FLock.Leave;
  end;
end;

function TMemoryPoolManager.AllocateChunk(MinSize: Integer): TMemoryChunk;
var
  i, BestIndex: Integer;
  BestSize: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  
  FLock.Enter;
  try
    // 找到最合适的内存池（足够大且浪费最少的）
    BestIndex := -1;
    BestSize := MaxInt;
    
    for i := 0 to Length(FPools) - 1 do
    begin
      if (FPools[i].ChunkSize >= MinSize) and 
         (FPools[i].ChunkSize < BestSize) and
         (FPools[i].GetAvailableCount > 0) then
      begin
        BestIndex := i;
        BestSize := FPools[i].ChunkSize;
      end;
    end;
    
    // 分配内存块
    if BestIndex >= 0 then
      Result := FPools[BestIndex].AllocateChunk;
  finally
    FLock.Leave;
  end;
end;

procedure TMemoryPoolManager.ReleaseChunk(var Chunk: TMemoryChunk);
var
  i: Integer;
  Found: Boolean;
begin
  if Chunk.Data = nil then
    Exit;
    
  FLock.Enter;
  try
    Found := False;
    
    // 查找包含此块的内存池
    for i := 0 to Length(FPools) - 1 do
    begin
      FPools[i].ReleaseChunk(Chunk);
      if Chunk.Data = nil then
      begin
        Found := True;
        Break;
      end;
    end;
    
    // 如果没有内存池认领此块，则直接释放内存
    if not Found and Assigned(Chunk.Data) then
    begin
      FreeMemory(Chunk.Data);
      Chunk.Data := nil;
      Chunk.Size := 0;
      Chunk.IsInUse := False;
      Chunk.Tag := 0;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TMemoryPoolManager.ReleaseAllPools;
var
  i: Integer;
begin
  FLock.Enter;
  try
    for i := 0 to Length(FPools) - 1 do
      FreeAndNil(FPools[i]);
      
    SetLength(FPools, 0);
  finally
    FLock.Leave;
  end;
end;

end. 