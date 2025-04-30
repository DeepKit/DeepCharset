unit SmartMemoryPool;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.Generics.Collections;

type
  // 内存块状态
  TMemoryBlockState = (
    mbsFree,     // 空闲
    mbsUsed,     // 使用中
    mbsReserved  // 已预留
  );

  // 内存块定义
  PMemoryBlock = ^TMemoryBlock;
  TMemoryBlock = record
    // 内存块管理数据
    Next: PMemoryBlock;      // 下一个块
    Prev: PMemoryBlock;      // 上一个块
    Size: NativeUInt;        // 块大小
    State: TMemoryBlockState;// 块状态
    PoolIndex: Integer;      // 所属池索引
    // 引用计数和使用信息
    RefCount: Integer;       // 引用计数
    UseCount: Integer;       // 使用次数
    LastUseTime: TDateTime;  // 最后使用时间
    Tag: Integer;            // 用户标记
    // 实际数据缓冲区
    Data: Pointer;           // 指向数据缓冲区开始位置
  end;

  // 内存池配置
  TMemoryPoolConfig = record
    MinBlockSize: NativeUInt;       // 最小块大小
    MaxBlockSize: NativeUInt;       // 最大块大小
    InitialCapacity: NativeUInt;    // 初始容量
    GrowthFactor: Single;           // 增长因子
    MaxCapacity: NativeUInt;        // 最大容量
    UseThreadSafety: Boolean;       // 是否线程安全
    EnableDefragmentation: Boolean; // 是否启用碎片整理
    EnableCaching: Boolean;         // 是否启用缓存
    AutoShrink: Boolean;            // 是否自动收缩
    ShrinkThreshold: Single;        // 收缩阈值 (0.0-1.0)
    
    // 构造函数
    constructor Create(
      AMinBlockSize: NativeUInt = 4096;                // 4KB
      AMaxBlockSize: NativeUInt = 1024 * 1024 * 10;    // 10MB
      AInitialCapacity: NativeUInt = 1024 * 1024;      // 1MB
      AGrowthFactor: Single = 1.5;
      AMaxCapacity: NativeUInt = 1024 * 1024 * 1024;   // 1GB
      AUseThreadSafety: Boolean = True;
      AEnableDefragmentation: Boolean = True;
      AEnableCaching: Boolean = True;
      AAutoShrink: Boolean = True;
      AShrinkThreshold: Single = 0.5
    );
  end;

  // 内存池统计信息
  TMemoryPoolStats = record
    TotalBlockCount: Integer;         // 总块数
    FreeBlockCount: Integer;          // 空闲块数
    UsedBlockCount: Integer;          // 使用中块数
    ReservedBlockCount: Integer;      // 预留块数
    TotalMemorySize: NativeUInt;      // 总内存大小
    UsedMemorySize: NativeUInt;       // 已用内存大小
    FreeMemorySize: NativeUInt;       // 空闲内存大小
    Fragmentation: Single;            // 碎片化率
    PeakMemoryUsage: NativeUInt;      // 峰值内存使用
    AllocCount: Int64;                // 分配次数
    FreeCount: Int64;                 // 释放次数
    ResizeCount: Int64;               // 调整大小次数
    CacheHits: Int64;                 // 缓存命中
    CacheMisses: Int64;               // 缓存未命中
  end;

  // 内存块句柄
  TMemoryBlockHandle = type Integer;

  // 内存池接口
  IMemoryPool = interface
    ['{B8A9E3D5-F12D-4A8F-AE82-BF1F3FCB9712}']
    // 基础操作
    function Allocate(Size: NativeUInt): TMemoryBlockHandle;
    function AllocateAndCopy(const Buffer; Size: NativeUInt): TMemoryBlockHandle;
    function Reallocate(Handle: TMemoryBlockHandle; NewSize: NativeUInt): TMemoryBlockHandle;
    procedure Release(var Handle: TMemoryBlockHandle);
    
    // 访问函数
    function GetBlockData(Handle: TMemoryBlockHandle): Pointer;
    function GetBlockSize(Handle: TMemoryBlockHandle): NativeUInt;
    function AddRef(Handle: TMemoryBlockHandle): Integer;
    
    // 池管理
    procedure Clear;
    procedure Defragment;
    procedure Shrink;
    function GetStats: TMemoryPoolStats;
    procedure SetMaxCapacity(Value: NativeUInt);
    
    // 属性
    property BlockData[Handle: TMemoryBlockHandle]: Pointer read GetBlockData;
    property BlockSize[Handle: TMemoryBlockHandle]: NativeUInt read GetBlockSize;
  end;

  // 智能内存池管理器
  TSmartMemoryPool = class(TInterfacedObject, IMemoryPool)
  private
    // 块管理
    FBlocks: TList<PMemoryBlock>;
    FFreeBlocks: TList<PMemoryBlock>;  // 按大小排序的空闲块
    FCurrentCapacity: NativeUInt;
    FPeakUsage: NativeUInt;
    
    // 统计信息
    FAllocCount: Int64;
    FFreeCount: Int64;
    FResizeCount: Int64;
    FCacheHits: Int64;
    FCacheMisses: Int64;
    
    // 配置
    FConfig: TMemoryPoolConfig;
    
    // 线程安全
    FLock: TCriticalSection;
    
    // 缓存最近使用的块
    FRecentlyUsedBlocks: TDictionary<NativeUInt, TList<PMemoryBlock>>;
    
    // 块查找和管理
    function FindBlock(Handle: TMemoryBlockHandle): PMemoryBlock;
    function CreateBlock(Size: NativeUInt): PMemoryBlock;
    function FindFreeBlock(Size: NativeUInt): PMemoryBlock;
    procedure AddToFreeList(Block: PMemoryBlock);
    procedure RemoveFromFreeList(Block: PMemoryBlock);
    procedure SplitBlock(Block: PMemoryBlock; Size: NativeUInt);
    procedure MergeAdjacentBlocks(Block: PMemoryBlock);
    
    // 辅助函数
    function NextValidHandle: TMemoryBlockHandle;
    procedure UpdateStats;
  public
    constructor Create(const Config: TMemoryPoolConfig); overload;
    constructor Create; overload;
    destructor Destroy; override;
    
    // IMemoryPool 接口实现
    function Allocate(Size: NativeUInt): TMemoryBlockHandle;
    function AllocateAndCopy(const Buffer; Size: NativeUInt): TMemoryBlockHandle;
    function Reallocate(Handle: TMemoryBlockHandle; NewSize: NativeUInt): TMemoryBlockHandle;
    procedure Release(var Handle: TMemoryBlockHandle);
    
    function GetBlockData(Handle: TMemoryBlockHandle): Pointer;
    function GetBlockSize(Handle: TMemoryBlockHandle): NativeUInt;
    function AddRef(Handle: TMemoryBlockHandle): Integer;
    
    procedure Clear;
    procedure Defragment;
    procedure Shrink;
    function GetStats: TMemoryPoolStats;
    procedure SetMaxCapacity(Value: NativeUInt);
  end;

// 内存池管理器
procedure InitializeMemoryPools;
procedure FinalizeMemoryPools;
function GlobalMemoryPool: IMemoryPool;

implementation

uses
  System.Math, System.DateUtils;

var
  GMemoryPool: IMemoryPool = nil;
  GMemoryPoolLock: TCriticalSection = nil;

// 全局内存池访问函数
function GlobalMemoryPool: IMemoryPool;
begin
  if GMemoryPool = nil then
  begin
    GMemoryPoolLock.Enter;
    try
      if GMemoryPool = nil then
      begin
        GMemoryPool := TSmartMemoryPool.Create;
      end;
    finally
      GMemoryPoolLock.Leave;
    end;
  end;
  Result := GMemoryPool;
end;

procedure InitializeMemoryPools;
begin
  if GMemoryPoolLock = nil then
    GMemoryPoolLock := TCriticalSection.Create;
end;

procedure FinalizeMemoryPools;
begin
  GMemoryPool := nil;
  FreeAndNil(GMemoryPoolLock);
end;

{ TMemoryPoolConfig }

constructor TMemoryPoolConfig.Create(
  AMinBlockSize: NativeUInt;
  AMaxBlockSize: NativeUInt;
  AInitialCapacity: NativeUInt;
  AGrowthFactor: Single;
  AMaxCapacity: NativeUInt;
  AUseThreadSafety: Boolean;
  AEnableDefragmentation: Boolean;
  AEnableCaching: Boolean;
  AAutoShrink: Boolean;
  AShrinkThreshold: Single);
begin
  MinBlockSize := AMinBlockSize;
  MaxBlockSize := AMaxBlockSize;
  InitialCapacity := AInitialCapacity;
  GrowthFactor := AGrowthFactor;
  MaxCapacity := AMaxCapacity;
  UseThreadSafety := AUseThreadSafety;
  EnableDefragmentation := AEnableDefragmentation;
  EnableCaching := AEnableCaching;
  AutoShrink := AAutoShrink;
  ShrinkThreshold := AShrinkThreshold;
end;

{ TSmartMemoryPool }

constructor TSmartMemoryPool.Create(const Config: TMemoryPoolConfig);
begin
  inherited Create;
  
  FConfig := Config;
  FBlocks := TList<PMemoryBlock>.Create;
  FFreeBlocks := TList<PMemoryBlock>.Create;
  FRecentlyUsedBlocks := TDictionary<NativeUInt, TList<PMemoryBlock>>.Create;
  
  if FConfig.UseThreadSafety then
    FLock := TCriticalSection.Create;
    
  // 初始化容量
  FCurrentCapacity := 0;
  FPeakUsage := 0;
  
  // 初始化统计信息
  FAllocCount := 0;
  FFreeCount := 0;
  FResizeCount := 0;
  FCacheHits := 0;
  FCacheMisses := 0;
end;

constructor TSmartMemoryPool.Create;
begin
  Create(TMemoryPoolConfig.Create);
end;

destructor TSmartMemoryPool.Destroy;
begin
  Clear;
  
  // 清理缓存
  for var Pair in FRecentlyUsedBlocks do
    Pair.Value.Free;
  FRecentlyUsedBlocks.Free;
  
  FBlocks.Free;
  FFreeBlocks.Free;
  
  if Assigned(FLock) then
    FLock.Free;
    
  inherited;
end;

function TSmartMemoryPool.Allocate(Size: NativeUInt): TMemoryBlockHandle;
var
  Block: PMemoryBlock;
  ActualSize: NativeUInt;
begin
  Result := 0;
  
  if Size = 0 then
    Exit;
  
  // 调整大小到最小块
  ActualSize := Max(Size, FConfig.MinBlockSize);
  
  // 线程安全保护
  if Assigned(FLock) then FLock.Enter;
  try
    // 尝试从缓存中找到合适的块
    if FConfig.EnableCaching then
    begin
      // 简化版：仅按大小精确匹配
      if FRecentlyUsedBlocks.ContainsKey(ActualSize) and 
         (FRecentlyUsedBlocks[ActualSize].Count > 0) then
      begin
        var CachedBlocks := FRecentlyUsedBlocks[ActualSize];
        Block := CachedBlocks[CachedBlocks.Count - 1];
        CachedBlocks.Delete(CachedBlocks.Count - 1);
        Inc(FCacheHits);
        
        // 更新块信息
        Block.State := mbsUsed;
        Block.RefCount := 1;
        Block.UseCount := Block.UseCount + 1;
        Block.LastUseTime := Now;
        
        Result := TMemoryBlockHandle(Block);
        Exit;
      end;
      Inc(FCacheMisses);
    end;
    
    // 尝试找到空闲块
    Block := FindFreeBlock(ActualSize);
    
    // 如果找不到适合的块，创建新块
    if Block = nil then
    begin
      Block := CreateBlock(ActualSize);
      if Block = nil then
        Exit;  // 内存分配失败
    end
    else
    begin
      // 如果块比需要的大太多，拆分它
      if (Block.Size > ActualSize) and 
         (Block.Size - ActualSize >= FConfig.MinBlockSize * 2) then
      begin
        SplitBlock(Block, ActualSize);
      end;
      
      // 从空闲列表中移除
      RemoveFromFreeList(Block);
    end;
    
    // 更新块信息
    Block.State := mbsUsed;
    Block.RefCount := 1;
    Block.UseCount := 1;
    Block.LastUseTime := Now;
    
    // 更新统计信息
    Inc(FAllocCount);
    FPeakUsage := Max(FPeakUsage, FCurrentCapacity - GetStats.FreeMemorySize);
    
    Result := TMemoryBlockHandle(Block);
  finally
    if Assigned(FLock) then FLock.Leave;
  end;
end;

function TSmartMemoryPool.AllocateAndCopy(const Buffer; Size: NativeUInt): TMemoryBlockHandle;
var
  Dest: Pointer;
begin
  Result := Allocate(Size);
  if Result <> 0 then
  begin
    Dest := GetBlockData(Result);
    if (Dest <> nil) and (Size > 0) then
    begin
      Move(Buffer, Dest^, Size);
    end;
  end;
end;

function TSmartMemoryPool.Reallocate(Handle: TMemoryBlockHandle; NewSize: NativeUInt): TMemoryBlockHandle;
var
  OldBlock, NewBlock: PMemoryBlock;
  CopySize: NativeUInt;
begin
  Result := 0;
  
  if Handle = 0 then
  begin
    Result := Allocate(NewSize);
    Exit;
  end;
  
  if NewSize = 0 then
  begin
    Release(Handle);
    Exit;
  end;
  
  // 线程安全保护
  if Assigned(FLock) then FLock.Enter;
  try
    OldBlock := FindBlock(Handle);
    if OldBlock = nil then
      Exit;
      
    // 如果大小相同，直接返回当前块
    if OldBlock.Size = NewSize then
    begin
      Result := Handle;
      Exit;
    end;
    
    // 更新统计信息
    Inc(FResizeCount);
    
    // 如果新大小更小，可以考虑拆分块
    if NewSize < OldBlock.Size then
    begin
      // 如果差距足够大，拆分块
      if (OldBlock.Size - NewSize) >= (FConfig.MinBlockSize * 2) then
      begin
        SplitBlock(OldBlock, NewSize);
      end;
      Result := Handle;
      Exit;
    end;
    
    // 尝试与下一个块合并
    if (OldBlock.Next <> nil) and (OldBlock.Next.State = mbsFree) and
       (OldBlock.Size + OldBlock.Next.Size >= NewSize) then
    begin
      // 从空闲列表中移除下一个块
      RemoveFromFreeList(OldBlock.Next);
      
      // 合并块
      OldBlock.Size := OldBlock.Size + OldBlock.Next.Size;
      
      // 更新链接
      if OldBlock.Next.Next <> nil then
        OldBlock.Next.Next.Prev := OldBlock;
      OldBlock.Next := OldBlock.Next.Next;
      
      // 如果新大小小于合并后的大小，考虑再次拆分
      if (OldBlock.Size - NewSize) >= (FConfig.MinBlockSize * 2) then
      begin
        SplitBlock(OldBlock, NewSize);
      end;
      
      Result := Handle;
      Exit;
    end;
    
    // 分配新块并复制数据
    NewBlock := PMemoryBlock(Allocate(NewSize));
    if NewBlock = nil then
    begin
      Result := Handle;  // 失败时返回原始块
      Exit;
    end;
    
    // 复制数据
    CopySize := Min(OldBlock.Size, NewSize);
    Move(OldBlock.Data^, NewBlock.Data^, CopySize);
    
    // 释放旧块
    PMemoryBlockHandle(Handle)^ := 0;
    Release(Handle);
    
    Result := TMemoryBlockHandle(NewBlock);
  finally
    if Assigned(FLock) then FLock.Leave;
  end;
end;

procedure TSmartMemoryPool.Release(var Handle: TMemoryBlockHandle);
var
  Block: PMemoryBlock;
begin
  if Handle = 0 then
    Exit;
    
  // 线程安全保护
  if Assigned(FLock) then FLock.Enter;
  try
    Block := FindBlock(Handle);
    if Block = nil then
      Exit;
    
    // 减少引用计数
    Dec(Block.RefCount);
    if Block.RefCount > 0 then
      Exit;
    
    // 更新统计信息
    Inc(FFreeCount);
    
    // 如果启用缓存，考虑保留块以备将来使用
    if FConfig.EnableCaching then
    begin
      // 简化版：按大小缓存最近使用的块
      if not FRecentlyUsedBlocks.ContainsKey(Block.Size) then
        FRecentlyUsedBlocks.Add(Block.Size, TList<PMemoryBlock>.Create);
        
      // 限制缓存大小
      if FRecentlyUsedBlocks[Block.Size].Count < 5 then  // 每个大小最多缓存5个块
      begin
        FRecentlyUsedBlocks[Block.Size].Add(Block);
        Block.State := mbsReserved;
        Handle := 0;
        Exit;
      end;
    end;
    
    // 将块标记为空闲
    Block.State := mbsFree;
    Block.RefCount := 0;
    
    // 添加到空闲列表
    AddToFreeList(Block);
    
    // 尝试合并相邻的空闲块
    if FConfig.EnableDefragmentation then
      MergeAdjacentBlocks(Block);
    
    // 如果启用自动收缩，检查是否需要收缩池
    if FConfig.AutoShrink then
    begin
      var Stats := GetStats;
      if (Stats.FreeMemorySize / FCurrentCapacity) > FConfig.ShrinkThreshold then
        Shrink;
    end;
    
    Handle := 0;
  finally
    if Assigned(FLock) then FLock.Leave;
  end;
end;

function TSmartMemoryPool.GetBlockData(Handle: TMemoryBlockHandle): Pointer;
var
  Block: PMemoryBlock;
begin
  Result := nil;
  
  if Handle = 0 then
    Exit;
    
  // 线程安全保护
  if Assigned(FLock) then FLock.Enter;
  try
    Block := FindBlock(Handle);
    if (Block <> nil) and (Block.State = mbsUsed) then
      Result := Block.Data;
  finally
    if Assigned(FLock) then FLock.Leave;
  end;
end;

function TSmartMemoryPool.GetBlockSize(Handle: TMemoryBlockHandle): NativeUInt;
var
  Block: PMemoryBlock;
begin
  Result := 0;
  
  if Handle = 0 then
    Exit;
    
  // 线程安全保护
  if Assigned(FLock) then FLock.Enter;
  try
    Block := FindBlock(Handle);
    if (Block <> nil) and (Block.State = mbsUsed) then
      Result := Block.Size;
  finally
    if Assigned(FLock) then FLock.Leave;
  end;
end;

function TSmartMemoryPool.AddRef(Handle: TMemoryBlockHandle): Integer;
var
  Block: PMemoryBlock;
begin
  Result := 0;
  
  if Handle = 0 then
    Exit;
    
  // 线程安全保护
  if Assigned(FLock) then FLock.Enter;
  try
    Block := FindBlock(Handle);
    if (Block <> nil) and (Block.State = mbsUsed) then
    begin
      Inc(Block.RefCount);
      Result := Block.RefCount;
    end;
  finally
    if Assigned(FLock) then FLock.Leave;
  end;
end;

procedure TSmartMemoryPool.Clear;
var
  I: Integer;
  Block: PMemoryBlock;
begin
  // 线程安全保护
  if Assigned(FLock) then FLock.Enter;
  try
    // 释放所有块
    for I := FBlocks.Count - 1 downto 0 do
    begin
      Block := FBlocks[I];
      
      // 释放数据缓冲区
      if Block.Data <> nil then
        FreeMem(Block.Data);
        
      // 释放块结构
      Dispose(Block);
      
      FBlocks.Delete(I);
    end;
    
    // 清空空闲列表
    FFreeBlocks.Clear;
    
    // 清空缓存
    for var Pair in FRecentlyUsedBlocks do
      Pair.Value.Clear;
      
    // 重置容量
    FCurrentCapacity := 0;
    
    // 重置统计信息
    FPeakUsage := 0;
  finally
    if Assigned(FLock) then FLock.Leave;
  end;
end;

procedure TSmartMemoryPool.Defragment;
var
  I: Integer;
  Block: PMemoryBlock;
  WasMerged: Boolean;
begin
  if not FConfig.EnableDefragmentation then
    Exit;
    
  // 线程安全保护
  if Assigned(FLock) then FLock.Enter;
  try
    // 对每个空闲块尝试合并
    repeat
      WasMerged := False;
      
      for I := 0 to FFreeBlocks.Count - 1 do
      begin
        Block := FFreeBlocks[I];
        
        // 尝试与相邻块合并
        if MergeAdjacentBlocks(Block) then
        begin
          WasMerged := True;
          Break;  // 从头开始，因为列表已经改变
        end;
      end;
    until not WasMerged;
  finally
    if Assigned(FLock) then FLock.Leave;
  end;
end;

procedure TSmartMemoryPool.Shrink;
var
  Stats: TMemoryPoolStats;
  TargetCapacity: NativeUInt;
  I: Integer;
  Block: PMemoryBlock;
begin
  // 线程安全保护
  if Assigned(FLock) then FLock.Enter;
  try
    // 获取当前统计信息
    Stats := GetStats;
    
    // 确定目标容量
    TargetCapacity := Max(
      FConfig.InitialCapacity,
      Stats.UsedMemorySize * 1.2  // 保留20%的余量
    );
    
    // 如果已用容量比目标容量小很多，则释放一些内存
    if FCurrentCapacity > TargetCapacity then
    begin
      // 首先整理碎片
      Defragment;
      
      // 尝试释放空闲块
      for I := FFreeBlocks.Count - 1 downto 0 do
      begin
        Block := FFreeBlocks[I];
        
        // 只释放大块
        if Block.Size >= FConfig.MinBlockSize * 4 then
        begin
          // 从空闲列表中移除
          FFreeBlocks.Delete(I);
          
          // 从块列表中移除
          FBlocks.Remove(Block);
          
          // 更新邻接块的链接
          if Block.Prev <> nil then
            Block.Prev.Next := Block.Next;
          if Block.Next <> nil then
            Block.Next.Prev := Block.Prev;
            
          // 减少总容量
          Dec(FCurrentCapacity, Block.Size);
          
          // 释放内存
          if Block.Data <> nil then
            FreeMem(Block.Data);
            
          // 释放块结构
          Dispose(Block);
          
          // 如果收缩到目标容量，则退出
          if FCurrentCapacity <= TargetCapacity then
            Break;
        end;
      end;
    end;
  finally
    if Assigned(FLock) then FLock.Leave;
  end;
end;

function TSmartMemoryPool.GetStats: TMemoryPoolStats;
var
  I: Integer;
  Block: PMemoryBlock;
begin
  FillChar(Result, SizeOf(Result), 0);
  
  // 线程安全保护
  if Assigned(FLock) then FLock.Enter;
  try
    // 计算各种统计数据
    Result.TotalBlockCount := FBlocks.Count;
    Result.FreeBlockCount := FFreeBlocks.Count;
    Result.TotalMemorySize := FCurrentCapacity;
    Result.PeakMemoryUsage := FPeakUsage;
    Result.AllocCount := FAllocCount;
    Result.FreeCount := FFreeCount;
    Result.ResizeCount := FResizeCount;
    Result.CacheHits := FCacheHits;
    Result.CacheMisses := FCacheMisses;
    
    // 计算使用中/预留块数和内存大小
    for I := 0 to FBlocks.Count - 1 do
    begin
      Block := FBlocks[I];
      case Block.State of
        mbsUsed:
          begin
            Inc(Result.UsedBlockCount);
            Inc(Result.UsedMemorySize, Block.Size);
          end;
        mbsReserved:
          begin
            Inc(Result.ReservedBlockCount);
            Inc(Result.UsedMemorySize, Block.Size);
          end;
      end;
    end;
    
    // 计算空闲内存大小
    Result.FreeMemorySize := Result.TotalMemorySize - Result.UsedMemorySize;
    
    // 计算碎片化率
    if Result.FreeMemorySize > 0 then
      Result.Fragmentation := Result.FreeBlockCount / (Result.TotalBlockCount * 1.0);
  finally
    if Assigned(FLock) then FLock.Leave;
  end;
end;

procedure TSmartMemoryPool.SetMaxCapacity(Value: NativeUInt);
begin
  // 线程安全保护
  if Assigned(FLock) then FLock.Enter;
  try
    FConfig.MaxCapacity := Value;
  finally
    if Assigned(FLock) then FLock.Leave;
  end;
end;

// 私有辅助方法

function TSmartMemoryPool.FindBlock(Handle: TMemoryBlockHandle): PMemoryBlock;
begin
  Result := PMemoryBlock(Handle);
  
  // 验证块属于此池
  if (Result <> nil) and (FBlocks.IndexOf(Result) >= 0) then
    Exit
  else
    Result := nil;
end;

function TSmartMemoryPool.CreateBlock(Size: NativeUInt): PMemoryBlock;
var
  Block: PMemoryBlock;
  BlockData: Pointer;
begin
  Result := nil;
  
  // 检查是否超过最大容量
  if FCurrentCapacity + Size > FConfig.MaxCapacity then
    Exit;
    
  // 分配块结构
  New(Block);
  if Block = nil then
    Exit;
    
  // 分配数据缓冲区
  try
    GetMem(BlockData, Size);
  except
    Dispose(Block);
    Exit;
  end;
  
  // 初始化块
  Block.Next := nil;
  Block.Prev := nil;
  Block.Size := Size;
  Block.State := mbsFree;
  Block.PoolIndex := FBlocks.Count;
  Block.RefCount := 0;
  Block.UseCount := 0;
  Block.LastUseTime := 0;
  Block.Tag := 0;
  Block.Data := BlockData;
  
  // 将块添加到列表
  FBlocks.Add(Block);
  
  // 更新总容量
  Inc(FCurrentCapacity, Size);
  
  Result := Block;
end;

function TSmartMemoryPool.FindFreeBlock(Size: NativeUInt): PMemoryBlock;
var
  I: Integer;
  Block: PMemoryBlock;
  BestFitBlock: PMemoryBlock;
  BestFitSize: NativeUInt;
begin
  Result := nil;
  
  // 使用最佳匹配算法
  BestFitBlock := nil;
  BestFitSize := High(NativeUInt);
  
  for I := 0 to FFreeBlocks.Count - 1 do
  begin
    Block := FFreeBlocks[I];
    
    // 找到大小足够且最接近需要大小的块
    if (Block.Size >= Size) and (Block.Size < BestFitSize) then
    begin
      BestFitBlock := Block;
      BestFitSize := Block.Size;
      
      // 如果找到完全匹配，立即返回
      if Block.Size = Size then
      begin
        Result := Block;
        Exit;
      end;
    end;
  end;
  
  Result := BestFitBlock;
end;

procedure TSmartMemoryPool.AddToFreeList(Block: PMemoryBlock);
var
  I: Integer;
begin
  // 按大小升序插入
  for I := 0 to FFreeBlocks.Count - 1 do
  begin
    if FFreeBlocks[I].Size > Block.Size then
    begin
      FFreeBlocks.Insert(I, Block);
      Exit;
    end;
  end;
  
  // 如果没有找到合适的位置，则添加到末尾
  FFreeBlocks.Add(Block);
end;

procedure TSmartMemoryPool.RemoveFromFreeList(Block: PMemoryBlock);
begin
  FFreeBlocks.Remove(Block);
end;

procedure TSmartMemoryPool.SplitBlock(Block: PMemoryBlock; Size: NativeUInt);
var
  NewBlock: PMemoryBlock;
  NewBlockData: Pointer;
  RemainingSize: NativeUInt;
begin
  // 确保块足够大，可以拆分
  if Block.Size <= Size + FConfig.MinBlockSize then
    Exit;
    
  // 计算剩余大小
  RemainingSize := Block.Size - Size;
  
  // 分配新块结构
  New(NewBlock);
  if NewBlock = nil then
    Exit;
    
  // 新块的数据指针计算
  NewBlockData := Pointer(NativeUInt(Block.Data) + Size);
  
  // 初始化新块
  NewBlock.Size := RemainingSize;
  NewBlock.State := mbsFree;
  NewBlock.PoolIndex := FBlocks.Count;
  NewBlock.RefCount := 0;
  NewBlock.UseCount := 0;
  NewBlock.LastUseTime := 0;
  NewBlock.Tag := 0;
  NewBlock.Data := NewBlockData;
  
  // 更新链接
  NewBlock.Next := Block.Next;
  NewBlock.Prev := Block;
  if Block.Next <> nil then
    Block.Next.Prev := NewBlock;
  Block.Next := NewBlock;
  
  // 更新原块大小
  Block.Size := Size;
  
  // 将新块添加到列表
  FBlocks.Add(NewBlock);
  
  // 将新块添加到空闲列表
  AddToFreeList(NewBlock);
end;

function TSmartMemoryPool.MergeAdjacentBlocks(Block: PMemoryBlock): Boolean;
var
  Merged: Boolean;
begin
  Result := False;
  Merged := False;
  
  // 只合并空闲块
  if Block.State <> mbsFree then
    Exit;
    
  // 尝试与前一个块合并
  if (Block.Prev <> nil) and (Block.Prev.State = mbsFree) then
  begin
    // 从空闲列表中移除两个块
    RemoveFromFreeList(Block);
    RemoveFromFreeList(Block.Prev);
    
    // 更新前一个块的大小
    Block.Prev.Size := Block.Prev.Size + Block.Size;
    
    // 更新链接
    Block.Prev.Next := Block.Next;
    if Block.Next <> nil then
      Block.Next.Prev := Block.Prev;
      
    // 从块列表中移除当前块
    FBlocks.Remove(Block);
    
    // 释放数据缓冲区（由于数据缓冲区是连续分配的，所以只需释放块结构）
    Dispose(Block);
    
    // 将前一个块添加回空闲列表
    AddToFreeList(Block.Prev);
    
    Merged := True;
    Result := True;
  end;
  
  // 尝试与下一个块合并
  if (not Merged) and (Block.Next <> nil) and (Block.Next.State = mbsFree) then
  begin
    // 从空闲列表中移除两个块
    RemoveFromFreeList(Block);
    RemoveFromFreeList(Block.Next);
    
    // 更新大小
    Block.Size := Block.Size + Block.Next.Size;
    
    // 更新链接
    if Block.Next.Next <> nil then
      Block.Next.Next.Prev := Block;
    var NextNext := Block.Next.Next;
    
    // 从块列表中移除下一个块
    FBlocks.Remove(Block.Next);
    
    // 释放下一个块的结构
    Dispose(Block.Next);
    
    // 更新链接
    Block.Next := NextNext;
    
    // 将当前块添加回空闲列表
    AddToFreeList(Block);
    
    Result := True;
  end;
end;

function TSmartMemoryPool.NextValidHandle: TMemoryBlockHandle;
begin
  Result := FBlocks.Count + 1;
end;

// 初始化和销毁
initialization
  InitializeMemoryPools;
  
finalization
  FinalizeMemoryPools;
  
end. 