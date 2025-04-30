unit ThreadSafeMemoryPool;

interface

uses
  SysUtils, Classes, SyncObjs, Generics.Collections, Windows;

const
  /// <summary>
  /// 默认固定大小块的数量
  /// </summary>
  DEFAULT_POOL_SIZE = 32;
  
  /// <summary>
  /// 默认块大小（字节）
  /// </summary>
  DEFAULT_BLOCK_SIZE = 4096;
  
  /// <summary>
  /// 默认最大内存使用（字节）
  /// </summary>
  DEFAULT_MAX_MEMORY = 32 * 1024 * 1024; // 32 MB

type
  /// <summary>
  /// 内存块信息
  /// </summary>
  TMemoryBlockInfo = record
    /// <summary>
    /// 内存指针
    /// </summary>
    Memory: Pointer;
    
    /// <summary>
    /// 块大小
    /// </summary>
    Size: Integer;
    
    /// <summary>
    /// 是否已分配
    /// </summary>
    Allocated: Boolean;
    
    /// <summary>
    /// 分配时间戳
    /// </summary>
    AllocTimestamp: Int64;
    
    /// <summary>
    /// 最后访问时间戳
    /// </summary>
    LastAccessTime: Int64;
    
    /// <summary>
    /// 分配计数
    /// </summary>
    AllocCount: Integer;
  end;
  
  /// <summary>
  /// 内存池统计信息
  /// </summary>
  TMemoryPoolStats = record
    /// <summary>
    /// 总内存大小（字节）
    /// </summary>
    TotalMemory: Int64;
    
    /// <summary>
    /// 已分配内存大小（字节）
    /// </summary>
    AllocatedMemory: Int64;
    
    /// <summary>
    /// 空闲内存大小（字节）
    /// </summary>
    FreeMemory: Int64;
    
    /// <summary>
    /// 总块数
    /// </summary>
    TotalBlocks: Integer;
    
    /// <summary>
    /// 已分配块数
    /// </summary>
    AllocatedBlocks: Integer;
    
    /// <summary>
    /// 空闲块数
    /// </summary>
    FreeBlocks: Integer;
    
    /// <summary>
    /// 调整大小操作次数
    /// </summary>
    ResizeOperations: Integer;
    
    /// <summary>
    /// 缓存命中次数
    /// </summary>
    CacheHits: Integer;
    
    /// <summary>
    /// 缓存未命中次数
    /// </summary>
    CacheMisses: Integer;
    
    /// <summary>
    /// 内存池创建时间
    /// </summary>
    CreationTime: TDateTime;
    
    /// <summary>
    /// 最大内存使用（字节）
    /// </summary>
    PeakMemoryUsage: Int64;
    
    /// <summary>
    /// 分配操作总数
    /// </summary>
    TotalAllocations: Int64;
    
    /// <summary>
    /// 释放操作总数
    /// </summary>
    TotalReleases: Int64;
  end;
  
  /// <summary>
  /// 内存池异常
  /// </summary>
  EMemoryPoolError = class(Exception);
  
  /// <summary>
  /// 块大小类别
  /// </summary>
  TBlockSizeCategory = (
    /// <summary>
    /// 小块 (0-4 KB)
    /// </summary>
    bscSmall,
    
    /// <summary>
    /// 中块 (4-64 KB)
    /// </summary>
    bscMedium,
    
    /// <summary>
    /// 大块 (64 KB-1 MB)
    /// </summary>
    bscLarge,
    
    /// <summary>
    /// 特大块 (> 1 MB)
    /// </summary>
    bscExtraLarge
  );
  
  /// <summary>
  /// 线程安全的内存池
  /// </summary>
  TThreadSafeMemoryPool = class
  private
    FLock: TCriticalSection;
    FFixedSizeBlocks: TList<TMemoryBlockInfo>;
    FDynamicBlocks: TDictionary<Pointer, TMemoryBlockInfo>;
    FPoolSize: Integer;
    FBlockSize: Integer;
    FMaxMemoryUsage: Int64;
    FCurrentMemoryUsage: Int64;
    FStats: TMemoryPoolStats;
    FAutoShrink: Boolean;
    FAutoShrinkInterval: Cardinal;
    FLastShrinkTime: Cardinal;
    
    function GetBlockSizeCategory(Size: Integer): TBlockSizeCategory;
    function FindFixedSizeBlock: Integer;
    procedure InternalFreeBlock(const BlockInfo: TMemoryBlockInfo);
    procedure UpdateStats;
    procedure CheckAutoShrink;
  public
    /// <summary>
    /// 创建内存池
    /// </summary>
    /// <param name="PoolSize">固定大小块的数量</param>
    /// <param name="BlockSize">块大小（字节）</param>
    /// <param name="MaxMemory">最大内存使用（字节）</param>
    constructor Create(PoolSize: Integer = DEFAULT_POOL_SIZE;
                     BlockSize: Integer = DEFAULT_BLOCK_SIZE;
                     MaxMemory: Int64 = DEFAULT_MAX_MEMORY);
    
    /// <summary>
    /// 销毁内存池
    /// </summary>
    destructor Destroy; override;
    
    /// <summary>
    /// 分配内存块
    /// </summary>
    /// <param name="Size">请求的大小（字节）</param>
    /// <returns>内存指针</returns>
    function Allocate(Size: Integer): Pointer;
    
    /// <summary>
    /// 释放内存块
    /// </summary>
    /// <param name="P">内存指针</param>
    procedure Release(P: Pointer);
    
    /// <summary>
    /// 调整内存块大小
    /// </summary>
    /// <param name="P">原内存指针</param>
    /// <param name="NewSize">新大小（字节）</param>
    /// <returns>新内存指针</returns>
    function Reallocate(P: Pointer; NewSize: Integer): Pointer;
    
    /// <summary>
    /// 清空内存池
    /// </summary>
    procedure Clear;
    
    /// <summary>
    /// 收缩内存池
    /// </summary>
    /// <param name="Force">强制收缩所有未使用的块</param>
    /// <returns>释放的内存大小（字节）</returns>
    function Shrink(Force: Boolean = False): Int64;
    
    /// <summary>
    /// 获取内存池统计信息
    /// </summary>
    /// <returns>统计信息</returns>
    function GetStats: TMemoryPoolStats;
    
    /// <summary>
    /// 获取指定指针的内存块信息
    /// </summary>
    /// <param name="P">内存指针</param>
    /// <returns>内存块信息</returns>
    function GetBlockInfo(P: Pointer): TMemoryBlockInfo;
    
    /// <summary>
    /// 自动收缩
    /// </summary>
    property AutoShrink: Boolean read FAutoShrink write FAutoShrink;
    
    /// <summary>
    /// 自动收缩间隔（毫秒）
    /// </summary>
    property AutoShrinkInterval: Cardinal read FAutoShrinkInterval write FAutoShrinkInterval;
    
    /// <summary>
    /// 最大内存使用（字节）
    /// </summary>
    property MaxMemoryUsage: Int64 read FMaxMemoryUsage write FMaxMemoryUsage;
    
    /// <summary>
    /// 当前内存使用（字节）
    /// </summary>
    property CurrentMemoryUsage: Int64 read FCurrentMemoryUsage;
  end;
  
  /// <summary>
  /// 全局内存池管理器
  /// </summary>
  TMemoryPoolManager = class
  private
    class var FInstance: TMemoryPoolManager;
    FCritSect: TCriticalSection;
    FPools: TObjectDictionary<string, TThreadSafeMemoryPool>;
    
    constructor Create;
    class function GetInstance: TMemoryPoolManager; static;
  public
    /// <summary>
    /// 销毁内存池管理器
    /// </summary>
    destructor Destroy; override;
    
    /// <summary>
    /// 获取或创建命名内存池
    /// </summary>
    /// <param name="PoolName">内存池名称</param>
    /// <param name="CreateIfNotExists">如果不存在是否创建</param>
    /// <param name="PoolSize">池大小</param>
    /// <param name="BlockSize">块大小</param>
    /// <param name="MaxMemory">最大内存</param>
    /// <returns>内存池实例</returns>
    function GetPool(const PoolName: string; 
                    CreateIfNotExists: Boolean = True;
                    PoolSize: Integer = DEFAULT_POOL_SIZE;
                    BlockSize: Integer = DEFAULT_BLOCK_SIZE;
                    MaxMemory: Int64 = DEFAULT_MAX_MEMORY): TThreadSafeMemoryPool;
    
    /// <summary>
    /// 释放命名内存池
    /// </summary>
    /// <param name="PoolName">内存池名称</param>
    procedure ReleasePool(const PoolName: string);
    
    /// <summary>
    /// 收缩所有内存池
    /// </summary>
    /// <param name="Force">强制收缩所有未使用的块</param>
    /// <returns>释放的内存大小（字节）</returns>
    function ShrinkAllPools(Force: Boolean = False): Int64;
    
    /// <summary>
    /// 获取所有内存池名称
    /// </summary>
    /// <returns>内存池名称列表</returns>
    function GetPoolNames: TArray<string>;
    
    /// <summary>
    /// 获取指定内存池的统计信息
    /// </summary>
    /// <param name="PoolName">内存池名称</param>
    /// <returns>统计信息</returns>
    function GetPoolStats(const PoolName: string): TMemoryPoolStats;
    
    /// <summary>
    /// 获取全局内存池统计信息
    /// </summary>
    /// <returns>所有内存池的统计信息</returns>
    function GetGlobalStats: TMemoryPoolStats;
    
    /// <summary>
    /// 默认内存池名称
    /// </summary>
    const DefaultPoolName = 'Default';
    
    /// <summary>
    /// 全局内存池实例
    /// </summary>
    class property Instance: TMemoryPoolManager read GetInstance;
  end;

implementation

uses
  DateUtils;

{ TThreadSafeMemoryPool }

constructor TThreadSafeMemoryPool.Create(PoolSize, BlockSize: Integer; MaxMemory: Int64);
var
  I: Integer;
  Block: TMemoryBlockInfo;
begin
  inherited Create;
  
  // 验证参数
  if PoolSize <= 0 then
    PoolSize := DEFAULT_POOL_SIZE;
    
  if BlockSize <= 0 then
    BlockSize := DEFAULT_BLOCK_SIZE;
    
  if MaxMemory <= 0 then
    MaxMemory := DEFAULT_MAX_MEMORY;
    
  // 初始化成员
  FLock := TCriticalSection.Create;
  FFixedSizeBlocks := TList<TMemoryBlockInfo>.Create;
  FDynamicBlocks := TDictionary<Pointer, TMemoryBlockInfo>.Create;
  
  FPoolSize := PoolSize;
  FBlockSize := BlockSize;
  FMaxMemoryUsage := MaxMemory;
  FCurrentMemoryUsage := 0;
  FAutoShrink := True;
  FAutoShrinkInterval := 60000; // 1分钟
  FLastShrinkTime := GetTickCount;
  
  // 初始化统计信息
  FillChar(FStats, SizeOf(FStats), 0);
  FStats.CreationTime := Now;
  
  // 预分配固定大小块
  for I := 0 to FPoolSize - 1 do
  begin
    // 创建新的内存块
    Block.Memory := AllocMem(FBlockSize);
    Block.Size := FBlockSize;
    Block.Allocated := False;
    Block.AllocTimestamp := 0;
    Block.LastAccessTime := 0;
    Block.AllocCount := 0;
    
    // 添加到列表
    FFixedSizeBlocks.Add(Block);
    
    // 更新内存使用
    Inc(FCurrentMemoryUsage, FBlockSize);
  end;
  
  // 更新统计信息
  UpdateStats;
end;

destructor TThreadSafeMemoryPool.Destroy;
begin
  // 清空内存池
  Clear;
  
  // 释放资源
  FreeAndNil(FDynamicBlocks);
  FreeAndNil(FFixedSizeBlocks);
  FreeAndNil(FLock);
  
  inherited;
end;

function TThreadSafeMemoryPool.Allocate(Size: Integer): Pointer;
var
  BlockInfo: TMemoryBlockInfo;
  BlockIndex: Integer;
  CurrentTime: Int64;
begin
  Result := nil;
  CurrentTime := GetTickCount64;
  
  // 至少分配1字节
  if Size <= 0 then
    Size := 1;
    
  FLock.Enter;
  try
    // 检查是否可以使用固定大小块
    if Size <= FBlockSize then
    begin
      // 尝试找到可用的固定大小块
      BlockIndex := FindFixedSizeBlock;
      
      if BlockIndex >= 0 then
      begin
        // 更新块信息
        BlockInfo := FFixedSizeBlocks[BlockIndex];
        BlockInfo.Allocated := True;
        BlockInfo.AllocTimestamp := CurrentTime;
        BlockInfo.LastAccessTime := CurrentTime;
        BlockInfo.AllocCount := BlockInfo.AllocCount + 1;
        
        // 将更新后的信息写回列表
        FFixedSizeBlocks[BlockIndex] := BlockInfo;
        
        // 返回内存指针
        Result := BlockInfo.Memory;
        
        // 更新统计信息
        Inc(FStats.CacheHits);
        Inc(FStats.TotalAllocations);
      end
      else
      begin
        // 没有可用的固定大小块，需要分配新的内存
        Inc(FStats.CacheMisses);
      end;
    end;
    
    // 如果无法使用固定大小块，则分配动态块
    if Result = nil then
    begin
      // 检查是否超过最大内存限制
      if FCurrentMemoryUsage + Size > FMaxMemoryUsage then
      begin
        // 尝试收缩内存池以释放空间
        Shrink(True);
        
        // 再次检查是否有足够的空间
        if FCurrentMemoryUsage + Size > FMaxMemoryUsage then
          raise EMemoryPoolError.CreateFmt('内存池超出最大内存限制 (%d 字节)', [FMaxMemoryUsage]);
      end;
      
      // 分配新的内存块
      BlockInfo.Memory := AllocMem(Size);
      BlockInfo.Size := Size;
      BlockInfo.Allocated := True;
      BlockInfo.AllocTimestamp := CurrentTime;
      BlockInfo.LastAccessTime := CurrentTime;
      BlockInfo.AllocCount := 1;
      
      // 添加到动态块字典
      FDynamicBlocks.Add(BlockInfo.Memory, BlockInfo);
      
      // 更新内存使用
      Inc(FCurrentMemoryUsage, Size);
      
      // 返回内存指针
      Result := BlockInfo.Memory;
      
      // 更新统计信息
      Inc(FStats.TotalAllocations);
    end;
    
    // 更新峰值内存使用
    if FCurrentMemoryUsage > FStats.PeakMemoryUsage then
      FStats.PeakMemoryUsage := FCurrentMemoryUsage;
      
    // 更新统计信息
    UpdateStats;
    
    // 检查是否需要自动收缩
    CheckAutoShrink;
    
  finally
    FLock.Leave;
  end;
end;

procedure TThreadSafeMemoryPool.Release(P: Pointer);
var
  I: Integer;
  Found: Boolean;
  BlockInfo: TMemoryBlockInfo;
begin
  if P = nil then
    Exit;
    
  FLock.Enter;
  try
    // 首先在固定大小块中查找
    Found := False;
    
    for I := 0 to FFixedSizeBlocks.Count - 1 do
    begin
      BlockInfo := FFixedSizeBlocks[I];
      
      if BlockInfo.Memory = P then
      begin
        // 找到了，标记为未分配
        BlockInfo.Allocated := False;
        BlockInfo.LastAccessTime := GetTickCount64;
        
        // 将更新后的信息写回列表
        FFixedSizeBlocks[I] := BlockInfo;
        
        // 标记为已找到
        Found := True;
        
        // 更新统计信息
        Inc(FStats.TotalReleases);
        Break;
      end;
    end;
    
    // 如果不在固定大小块中，则检查动态块
    if not Found then
    begin
      if FDynamicBlocks.TryGetValue(P, BlockInfo) then
      begin
        // 从动态块字典中移除
        FDynamicBlocks.Remove(P);
        
        // 更新内存使用
        Dec(FCurrentMemoryUsage, BlockInfo.Size);
        
        // 释放内存
        FreeMem(BlockInfo.Memory);
        
        // 更新统计信息
        Inc(FStats.TotalReleases);
        
        // 标记为已找到
        Found := True;
      end;
    end;
    
    // 如果未找到，则抛出异常
    if not Found then
      raise EMemoryPoolError.CreateFmt('尝试释放未分配的内存指针 (0x%p)', [P]);
      
    // 更新统计信息
    UpdateStats;
    
    // 检查是否需要自动收缩
    CheckAutoShrink;
    
  finally
    FLock.Leave;
  end;
end;

function TThreadSafeMemoryPool.Reallocate(P: Pointer; NewSize: Integer): Pointer;
var
  OldSize: Integer;
  I: Integer;
  Found: Boolean;
  BlockInfo: TMemoryBlockInfo;
begin
  Result := nil;
  
  // 至少分配1字节
  if NewSize <= 0 then
    NewSize := 1;
    
  // 如果指针为nil，则相当于新分配
  if P = nil then
  begin
    Result := Allocate(NewSize);
    Exit;
  end;
  
  FLock.Enter;
  try
    // 首先在固定大小块中查找
    Found := False;
    OldSize := 0;
    
    for I := 0 to FFixedSizeBlocks.Count - 1 do
    begin
      BlockInfo := FFixedSizeBlocks[I];
      
      if BlockInfo.Memory = P then
      begin
        // 记录旧大小
        OldSize := BlockInfo.Size;
        
        // 如果新大小小于或等于块大小，可以继续使用该块
        if NewSize <= FBlockSize then
        begin
          // 更新块信息
          BlockInfo.LastAccessTime := GetTickCount64;
          
          // 将更新后的信息写回列表
          FFixedSizeBlocks[I] := BlockInfo;
          
          // 返回原指针
          Result := P;
        end
        else
        begin
          // 新大小超过块大小，需要分配新的动态块
          // 先标记为未分配
          BlockInfo.Allocated := False;
          BlockInfo.LastAccessTime := GetTickCount64;
          
          // 将更新后的信息写回列表
          FFixedSizeBlocks[I] := BlockInfo;
        end;
        
        // 标记为已找到
        Found := True;
        Break;
      end;
    end;
    
    // 如果不在固定大小块中，则检查动态块
    if not Found then
    begin
      if FDynamicBlocks.TryGetValue(P, BlockInfo) then
      begin
        // 记录旧大小
        OldSize := BlockInfo.Size;
        
        // 从动态块字典中移除
        FDynamicBlocks.Remove(P);
        
        // 更新内存使用
        Dec(FCurrentMemoryUsage, BlockInfo.Size);
        
        // 标记为已找到
        Found := True;
      end;
    end;
    
    // 如果未找到，则抛出异常
    if not Found then
      raise EMemoryPoolError.CreateFmt('尝试重新分配未分配的内存指针 (0x%p)', [P]);
      
    // 如果尚未分配新内存，则现在分配
    if Result = nil then
    begin
      // 分配新内存
      Result := Allocate(NewSize);
      
      if Result <> nil then
      begin
        // 复制旧数据到新内存
        Move(P^, Result^, Min(OldSize, NewSize));
        
        // 如果是动态块，释放旧内存
        if OldSize > FBlockSize then
          FreeMem(P);
      end;
    end;
    
    // 更新统计信息
    Inc(FStats.ResizeOperations);
    UpdateStats;
    
  finally
    FLock.Leave;
  end;
end;

procedure TThreadSafeMemoryPool.Clear;
var
  I: Integer;
  BlockInfo: TMemoryBlockInfo;
  AllBlocks: TList<TMemoryBlockInfo>;
begin
  FLock.Enter;
  try
    // 创建所有块的列表
    AllBlocks := TList<TMemoryBlockInfo>.Create;
    try
      // 添加所有固定大小块
      for I := 0 to FFixedSizeBlocks.Count - 1 do
        AllBlocks.Add(FFixedSizeBlocks[I]);
        
      // 添加所有动态块
      for BlockInfo in FDynamicBlocks.Values do
        AllBlocks.Add(BlockInfo);
        
      // 清空列表和字典
      FFixedSizeBlocks.Clear;
      FDynamicBlocks.Clear;
      
      // 释放所有内存
      for BlockInfo in AllBlocks do
        FreeMem(BlockInfo.Memory);
        
    finally
      AllBlocks.Free;
    end;
    
    // 重置内存使用
    FCurrentMemoryUsage := 0;
    
    // 重置统计信息
    FillChar(FStats, SizeOf(FStats), 0);
    FStats.CreationTime := Now;
    
    // 重新分配固定大小块
    for I := 0 to FPoolSize - 1 do
    begin
      // 创建新的内存块
      BlockInfo.Memory := AllocMem(FBlockSize);
      BlockInfo.Size := FBlockSize;
      BlockInfo.Allocated := False;
      BlockInfo.AllocTimestamp := 0;
      BlockInfo.LastAccessTime := 0;
      BlockInfo.AllocCount := 0;
      
      // 添加到列表
      FFixedSizeBlocks.Add(BlockInfo);
      
      // 更新内存使用
      Inc(FCurrentMemoryUsage, FBlockSize);
    end;
    
    // 更新统计信息
    UpdateStats;
    
  finally
    FLock.Leave;
  end;
end;

function TThreadSafeMemoryPool.Shrink(Force: Boolean): Int64;
var
  I: Integer;
  BlockInfo: TMemoryBlockInfo;
  CurrentTime: Int64;
  TimeSinceLastAccess: Int64;
  TotalFreed: Int64;
  ToRemove: TList<Pointer>;
begin
  Result := 0;
  CurrentTime := GetTickCount64;
  
  FLock.Enter;
  try
    // 创建要移除的动态块列表
    ToRemove := TList<Pointer>.Create;
    try
      // 遍历所有动态块
      for BlockInfo in FDynamicBlocks do
      begin
        // 计算自上次访问以来的时间（毫秒）
        TimeSinceLastAccess := CurrentTime - BlockInfo.Value.LastAccessTime;
        
        // 如果强制收缩或者超过5分钟未访问，则释放
        if Force or (TimeSinceLastAccess > 300000) then
        begin
          // 添加到要移除的列表
          ToRemove.Add(BlockInfo.Key);
          
          // 累计释放的内存
          Inc(TotalFreed, BlockInfo.Value.Size);
        end;
      end;
      
      // 移除并释放选中的动态块
      for I := 0 to ToRemove.Count - 1 do
      begin
        if FDynamicBlocks.TryGetValue(ToRemove[I], BlockInfo) then
        begin
          // 释放内存
          FreeMem(BlockInfo.Memory);
          
          // 从字典中移除
          FDynamicBlocks.Remove(ToRemove[I]);
          
          // 更新内存使用
          Dec(FCurrentMemoryUsage, BlockInfo.Size);
        end;
      end;
      
    finally
      ToRemove.Free;
    end;
    
    // 更新最后收缩时间
    FLastShrinkTime := CurrentTime;
    
    // 更新统计信息
    UpdateStats;
    
    // 返回释放的内存量
    Result := TotalFreed;
    
  finally
    FLock.Leave;
  end;
end;

function TThreadSafeMemoryPool.GetStats: TMemoryPoolStats;
begin
  FLock.Enter;
  try
    Result := FStats;
  finally
    FLock.Leave;
  end;
end;

function TThreadSafeMemoryPool.GetBlockInfo(P: Pointer): TMemoryBlockInfo;
var
  I: Integer;
  Found: Boolean;
begin
  FillChar(Result, SizeOf(Result), 0);
  
  if P = nil then
    Exit;
    
  FLock.Enter;
  try
    // 首先在固定大小块中查找
    Found := False;
    
    for I := 0 to FFixedSizeBlocks.Count - 1 do
    begin
      if FFixedSizeBlocks[I].Memory = P then
      begin
        Result := FFixedSizeBlocks[I];
        Found := True;
        Break;
      end;
    end;
    
    // 如果不在固定大小块中，则检查动态块
    if not Found then
      FDynamicBlocks.TryGetValue(P, Result);
      
  finally
    FLock.Leave;
  end;
end;

function TThreadSafeMemoryPool.FindFixedSizeBlock: Integer;
var
  I: Integer;
begin
  Result := -1;
  
  // 遍历所有固定大小块
  for I := 0 to FFixedSizeBlocks.Count - 1 do
  begin
    if not FFixedSizeBlocks[I].Allocated then
    begin
      Result := I;
      Break;
    end;
  end;
end;

procedure TThreadSafeMemoryPool.InternalFreeBlock(const BlockInfo: TMemoryBlockInfo);
begin
  // 释放内存
  FreeMem(BlockInfo.Memory);
  
  // 更新内存使用
  Dec(FCurrentMemoryUsage, BlockInfo.Size);
end;

procedure TThreadSafeMemoryPool.UpdateStats;
var
  BlockInfo: TMemoryBlockInfo;
begin
  // 重置部分统计信息
  FStats.TotalMemory := FCurrentMemoryUsage;
  FStats.AllocatedMemory := 0;
  FStats.FreeMemory := 0;
  FStats.TotalBlocks := FFixedSizeBlocks.Count + FDynamicBlocks.Count;
  FStats.AllocatedBlocks := 0;
  FStats.FreeBlocks := 0;
  
  // 计算固定大小块的统计信息
  for BlockInfo in FFixedSizeBlocks do
  begin
    if BlockInfo.Allocated then
    begin
      Inc(FStats.AllocatedMemory, BlockInfo.Size);
      Inc(FStats.AllocatedBlocks);
    end
    else
    begin
      Inc(FStats.FreeMemory, BlockInfo.Size);
      Inc(FStats.FreeBlocks);
    end;
  end;
  
  // 添加动态块的统计信息
  for BlockInfo in FDynamicBlocks.Values do
  begin
    Inc(FStats.AllocatedMemory, BlockInfo.Size);
    Inc(FStats.AllocatedBlocks);
  end;
end;

procedure TThreadSafeMemoryPool.CheckAutoShrink;
var
  CurrentTime: Cardinal;
begin
  if not FAutoShrink then
    Exit;
    
  CurrentTime := GetTickCount;
  
  // 检查是否到达自动收缩间隔
  if (CurrentTime - FLastShrinkTime) >= FAutoShrinkInterval then
    Shrink(False);
end;

function TThreadSafeMemoryPool.GetBlockSizeCategory(Size: Integer): TBlockSizeCategory;
begin
  if Size <= 4 * 1024 then
    Result := bscSmall
  else if Size <= 64 * 1024 then
    Result := bscMedium
  else if Size <= 1024 * 1024 then
    Result := bscLarge
  else
    Result := bscExtraLarge;
end;

{ TMemoryPoolManager }

constructor TMemoryPoolManager.Create;
begin
  inherited Create;
  FCritSect := TCriticalSection.Create;
  FPools := TObjectDictionary<string, TThreadSafeMemoryPool>.Create([doOwnsValues]);
end;

destructor TMemoryPoolManager.Destroy;
begin
  FreeAndNil(FPools);
  FreeAndNil(FCritSect);
  inherited;
end;

class function TMemoryPoolManager.GetInstance: TMemoryPoolManager;
begin
  if FInstance = nil then
    FInstance := TMemoryPoolManager.Create;
    
  Result := FInstance;
end;

function TMemoryPoolManager.GetPool(const PoolName: string;
                                   CreateIfNotExists: Boolean;
                                   PoolSize: Integer;
                                   BlockSize: Integer;
                                   MaxMemory: Int64): TThreadSafeMemoryPool;
var
  PoolExists: Boolean;
begin
  Result := nil;
  
  FCritSect.Enter;
  try
    // 检查池是否存在
    PoolExists := FPools.TryGetValue(PoolName, Result);
    
    // 如果不存在且需要创建
    if (not PoolExists) and CreateIfNotExists then
    begin
      // 创建新的内存池
      Result := TThreadSafeMemoryPool.Create(PoolSize, BlockSize, MaxMemory);
      
      // 添加到字典
      FPools.Add(PoolName, Result);
    end;
  finally
    FCritSect.Leave;
  end;
end;

procedure TMemoryPoolManager.ReleasePool(const PoolName: string);
begin
  FCritSect.Enter;
  try
    // 从字典中移除将自动释放内存池
    FPools.Remove(PoolName);
  finally
    FCritSect.Leave;
  end;
end;

function TMemoryPoolManager.ShrinkAllPools(Force: Boolean): Int64;
var
  Pool: TThreadSafeMemoryPool;
begin
  Result := 0;
  
  FCritSect.Enter;
  try
    // 收缩所有内存池
    for Pool in FPools.Values do
      Inc(Result, Pool.Shrink(Force));
  finally
    FCritSect.Leave;
  end;
end;

function TMemoryPoolManager.GetPoolNames: TArray<string>;
var
  List: TList<string>;
  Name: string;
begin
  List := TList<string>.Create;
  try
    FCritSect.Enter;
    try
      // 收集所有池名称
      for Name in FPools.Keys do
        List.Add(Name);
    finally
      FCritSect.Leave;
    end;
    
    // 转换为数组
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function TMemoryPoolManager.GetPoolStats(const PoolName: string): TMemoryPoolStats;
var
  Pool: TThreadSafeMemoryPool;
begin
  FillChar(Result, SizeOf(Result), 0);
  
  FCritSect.Enter;
  try
    // 尝试获取指定的内存池
    if FPools.TryGetValue(PoolName, Pool) then
      Result := Pool.GetStats;
  finally
    FCritSect.Leave;
  end;
end;

function TMemoryPoolManager.GetGlobalStats: TMemoryPoolStats;
var
  Pool: TThreadSafeMemoryPool;
  PoolStats: TMemoryPoolStats;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.CreationTime := Now;
  
  FCritSect.Enter;
  try
    // 合并所有内存池的统计信息
    for Pool in FPools.Values do
    begin
      PoolStats := Pool.GetStats;
      
      // 累加统计数据
      Inc(Result.TotalMemory, PoolStats.TotalMemory);
      Inc(Result.AllocatedMemory, PoolStats.AllocatedMemory);
      Inc(Result.FreeMemory, PoolStats.FreeMemory);
      Inc(Result.TotalBlocks, PoolStats.TotalBlocks);
      Inc(Result.AllocatedBlocks, PoolStats.AllocatedBlocks);
      Inc(Result.FreeBlocks, PoolStats.FreeBlocks);
      Inc(Result.ResizeOperations, PoolStats.ResizeOperations);
      Inc(Result.CacheHits, PoolStats.CacheHits);
      Inc(Result.CacheMisses, PoolStats.CacheMisses);
      Inc(Result.TotalAllocations, PoolStats.TotalAllocations);
      Inc(Result.TotalReleases, PoolStats.TotalReleases);
      
      // 更新峰值内存使用
      if PoolStats.PeakMemoryUsage > Result.PeakMemoryUsage then
        Result.PeakMemoryUsage := PoolStats.PeakMemoryUsage;
        
      // 更新创建时间（取最早的）
      if (Result.CreationTime = 0) or 
         (PoolStats.CreationTime < Result.CreationTime) then
        Result.CreationTime := PoolStats.CreationTime;
    end;
  finally
    FCritSect.Leave;
  end;
end;

initialization
  // 不在这里初始化单例实例，而是在第一次请求时创建

finalization
  // 释放单例实例
  if TMemoryPoolManager.FInstance <> nil then
    FreeAndNil(TMemoryPoolManager.FInstance);

end. 