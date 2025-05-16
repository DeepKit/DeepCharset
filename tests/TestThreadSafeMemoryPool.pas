unit TestThreadSafeMemoryPool;

interface

uses
  TestFramework, Classes, SysUtils, SyncObjs, ThreadSafeMemoryPool;

type
  TTestThreadSafeMemoryPool = class(TTestCase)
  private
    FMemoryPool: TThreadSafeMemoryPool;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestCreateMemoryPool;
    procedure TestGetAndFreeMemory;
    procedure TestMultipleSizes;
    procedure TestPoolStatistics;
    procedure TestSetPoolConfiguration;
    procedure TestMultiThreadAccess;
  end;

  TTestThreadAccess = class(TThread)
  private
    FMemoryPool: TThreadSafeMemoryPool;
    FAllocationCount: Integer;
    FMaxSize: Integer;
    FPointers: array of Pointer;
    FSuccess: Boolean;
  public
    constructor Create(AMemoryPool: TThreadSafeMemoryPool; AAllocationCount, AMaxSize: Integer);
    destructor Destroy; override;
    procedure Execute; override;
    property Success: Boolean read FSuccess;
  end;

implementation

{ TTestThreadSafeMemoryPool }

procedure TTestThreadSafeMemoryPool.SetUp;
begin
  FMemoryPool := TThreadSafeMemoryPool.Create;
end;

procedure TTestThreadSafeMemoryPool.TearDown;
begin
  FMemoryPool.Free;
end;

procedure TTestThreadSafeMemoryPool.TestCreateMemoryPool;
begin
  // 测试内存池创建
  CheckNotNull(FMemoryPool, '内存池对象应该被成功创建');
  
  // 测试默认大小配置正确
  CheckEquals(4, Length(FMemoryPool.DefaultSizes), '默认应配置4种大小的内存池');
  CheckEquals(32, FMemoryPool.DefaultSizes[0], '第一个池大小应为32字节');
  CheckEquals(64, FMemoryPool.DefaultSizes[1], '第二个池大小应为64字节');
  CheckEquals(128, FMemoryPool.DefaultSizes[2], '第三个池大小应为128字节');
  CheckEquals(256, FMemoryPool.DefaultSizes[3], '第四个池大小应为256字节');
end;

procedure TTestThreadSafeMemoryPool.TestGetAndFreeMemory;
var
  Ptr1, Ptr2: Pointer;
  Size: Integer;
begin
  // 测试从池中获取内存
  Size := 32;
  Ptr1 := FMemoryPool.GetMemory(Size);
  CheckNotNull(Ptr1, Format('从池中获取%d字节的内存应成功', [Size]));
  
  // 测试再次获取
  Ptr2 := FMemoryPool.GetMemory(Size);
  CheckNotNull(Ptr2, Format('第二次从池中获取%d字节的内存应成功', [Size]));
  
  // 确保获取的是不同的内存块
  CheckNotEquals(NativeUInt(Ptr1), NativeUInt(Ptr2), '两次获取的内存块不应相同');
  
  // 测试释放内存
  FMemoryPool.FreeMemory(Ptr1);
  FMemoryPool.FreeMemory(Ptr2);
  
  // 测试从池中获取大于最大池大小的内存
  Size := 1024;
  Ptr1 := FMemoryPool.GetMemory(Size);
  CheckNotNull(Ptr1, Format('获取%d字节的内存（大于池大小）应使用GetMem成功', [Size]));
  
  // 释放大内存
  FMemoryPool.FreeMemory(Ptr1);
end;

procedure TTestThreadSafeMemoryPool.TestMultipleSizes;
var
  Ptrs: array[0..3] of Pointer;
  Sizes: array[0..3] of Integer;
  I: Integer;
begin
  // 测试不同大小的内存分配
  Sizes[0] := 16;  // 小于最小池
  Sizes[1] := 48;  // 32-64池
  Sizes[2] := 96;  // 64-128池
  Sizes[3] := 200; // 128-256池
  
  for I := 0 to 3 do
  begin
    Ptrs[I] := FMemoryPool.GetMemory(Sizes[I]);
    CheckNotNull(Ptrs[I], Format('获取%d字节的内存应成功', [Sizes[I]]));
    
    // 测试写入数据
    FillChar(Ptrs[I]^, Sizes[I], I + 1);
    
    // 验证第一个字节
    CheckEquals(I + 1, Byte(Ptrs[I]^), Format('内存块应被正确写入值%d', [I + 1]));
  end;
  
  // 测试释放所有内存
  for I := 0 to 3 do
    FMemoryPool.FreeMemory(Ptrs[I]);
end;

procedure TTestThreadSafeMemoryPool.TestPoolStatistics;
var
  Stats: string;
  I: Integer;
  Ptrs: array[0..9] of Pointer;
begin
  // 分配一些内存块
  for I := 0 to 9 do
    Ptrs[I] := FMemoryPool.GetMemory(32);
    
  // 获取并检查统计信息
  Stats := FMemoryPool.GetPoolStatistics;
  CheckNotEquals('', Stats, '应返回非空的统计信息');
  
  // 检查统计信息中是否包含关键信息
  CheckTrue(Pos('内存池统计信息', Stats) > 0, '统计信息应包含标题');
  CheckTrue(Pos('块大小: 32', Stats) > 0, '统计信息应包含32字节池的信息');
  
  // 释放所有内存
  for I := 0 to 9 do
    FMemoryPool.FreeMemory(Ptrs[I]);
end;

procedure TTestThreadSafeMemoryPool.TestSetPoolConfiguration;
var
  NewSizes: array[0..2] of Integer;
  NewInitCounts: array[0..2] of Integer;
  NewGrowSizes: array[0..2] of Integer;
  NewMaxCounts: array[0..2] of Integer;
begin
  // 设置新的池配置
  NewSizes[0] := 128;
  NewSizes[1] := 256;
  NewSizes[2] := 512;
  
  NewInitCounts[0] := 100;
  NewInitCounts[1] := 50;
  NewInitCounts[2] := 25;
  
  NewGrowSizes[0] := 50;
  NewGrowSizes[1] := 25;
  NewGrowSizes[2] := 10;
  
  NewMaxCounts[0] := 1000;
  NewMaxCounts[1] := 500;
  NewMaxCounts[2] := 250;
  
  // 应用新配置
  FMemoryPool.SetPoolConfiguration(NewSizes, NewInitCounts, NewGrowSizes, NewMaxCounts);
  
  // 验证配置已应用
  CheckEquals(3, Length(FMemoryPool.DefaultSizes), '应更新为3种大小的内存池');
  CheckEquals(128, FMemoryPool.DefaultSizes[0], '第一个池大小应为128字节');
  CheckEquals(256, FMemoryPool.DefaultSizes[1], '第二个池大小应为256字节');
  CheckEquals(512, FMemoryPool.DefaultSizes[2], '第三个池大小应为512字节');
  
  // 测试使用新配置的内存池分配
  var Ptr := FMemoryPool.GetMemory(200);
  CheckNotNull(Ptr, '在新配置下应能分配200字节内存');
  FMemoryPool.FreeMemory(Ptr);
end;

procedure TTestThreadSafeMemoryPool.TestMultiThreadAccess;
const
  THREAD_COUNT = 5;
  ALLOC_COUNT = 100;
  MAX_SIZE = 200;
var
  Threads: array[0..THREAD_COUNT-1] of TTestThreadAccess;
  I: Integer;
begin
  // 创建多个线程同时访问内存池
  for I := 0 to THREAD_COUNT-1 do
    Threads[I] := TTestThreadAccess.Create(FMemoryPool, ALLOC_COUNT, MAX_SIZE);
  
  // 等待所有线程完成
  for I := 0 to THREAD_COUNT-1 do
  begin
    Threads[I].WaitFor;
    CheckTrue(Threads[I].Success, Format('线程%d应成功完成内存操作', [I]));
    Threads[I].Free;
  end;
end;

{ TTestThreadAccess }

constructor TTestThreadAccess.Create(AMemoryPool: TThreadSafeMemoryPool; 
  AAllocationCount, AMaxSize: Integer);
begin
  inherited Create(False);
  FMemoryPool := AMemoryPool;
  FAllocationCount := AAllocationCount;
  FMaxSize := AMaxSize;
  SetLength(FPointers, FAllocationCount);
  FSuccess := False;
  FreeOnTerminate := False;
end;

destructor TTestThreadAccess.Destroy;
var
  I: Integer;
begin
  // 确保释放所有内存
  for I := 0 to FAllocationCount - 1 do
    if FPointers[I] <> nil then
      FMemoryPool.FreeMemory(FPointers[I]);
  
  inherited;
end;

procedure TTestThreadAccess.Execute;
var
  I, Size: Integer;
begin
  try
    // 随机分配和释放内存
    for I := 0 to FAllocationCount - 1 do
    begin
      // 随机大小，至少1字节
      Size := Random(FMaxSize) + 1;
      FPointers[I] := FMemoryPool.GetMemory(Size);
      
      if FPointers[I] = nil then
        Exit; // 分配失败
        
      // 写入内存以测试可用性
      FillChar(FPointers[I]^, Size, I mod 256);
      
      // 模拟一些工作
      Sleep(Random(5));
    end;
    
    // 随机释放一半内存
    for I := 0 to FAllocationCount div 2 - 1 do
    begin
      var Index := Random(FAllocationCount);
      if FPointers[Index] <> nil then
      begin
        FMemoryPool.FreeMemory(FPointers[Index]);
        FPointers[Index] := nil;
      end;
    end;
    
    // 再次分配已释放的空间
    for I := 0 to FAllocationCount - 1 do
    begin
      if FPointers[I] = nil then
      begin
        Size := Random(FMaxSize) + 1;
        FPointers[I] := FMemoryPool.GetMemory(Size);
        
        if FPointers[I] = nil then
          Exit; // 分配失败
          
        // 写入内存以测试可用性
        FillChar(FPointers[I]^, Size, (I + 100) mod 256);
      end;
    end;
    
    // 全部成功
    FSuccess := True;
  except
    // 异常情况
    FSuccess := False;
  end;
end;

initialization
  RegisterTest(TTestThreadSafeMemoryPool.Suite);
end. 