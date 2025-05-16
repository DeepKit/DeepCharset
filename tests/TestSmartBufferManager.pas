unit TestSmartBufferManager;

interface

uses
  TestFramework, SysUtils, Classes, Math, Windows,
  SmartBufferManager, ThreadSafeMemoryPool;

type
  TTestSmartBufferManager = class(TTestCase)
  private
    FMemoryPool: TThreadSafeMemoryPool;
    FBufferManager: TSmartBufferManager;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestCreateBufferManager;
    procedure TestRequestAndReleaseBuffer;
    procedure TestBufferSizeLimits;
    procedure TestStaticStrategy;
    procedure TestAdaptiveStrategy;
    procedure TestProgressiveStrategy;
    procedure TestStatistics;
    procedure TestReleaseAllBuffers;
    procedure TestLargeFileHandling;
    procedure TestMultipleBuffers;
  end;

  TBufferTestThread = class(TThread)
  private
    FBufferManager: TSmartBufferManager;
    FBufferSize: Integer;
    FOperationCount: Integer;
    FSuccess: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(BufferManager: TSmartBufferManager; BufferSize, OperationCount: Integer);
    property Success: Boolean read FSuccess;
  end;

implementation

{ TTestSmartBufferManager }

procedure TTestSmartBufferManager.SetUp;
begin
  inherited;
  FMemoryPool := TThreadSafeMemoryPool.Create;
  FBufferManager := TSmartBufferManager.Create(FMemoryPool);
end;

procedure TTestSmartBufferManager.TearDown;
begin
  FBufferManager.Free;
  FMemoryPool.Free;
  inherited;
end;

procedure TTestSmartBufferManager.TestCreateBufferManager;
begin
  // 测试默认构造函数
  var Manager := TSmartBufferManager.Create;
  try
    CheckEquals(busAdaptive, Manager.Strategy, '默认策略应该是自适应的');
    CheckEquals(8192, Manager.DefaultBufferSize, '默认缓冲区大小应该是8KB');
  finally
    Manager.Free;
  end;
  
  // 测试使用自定义内存池
  var Pool := TThreadSafeMemoryPool.Create;
  try
    var CustomPoolManager := TSmartBufferManager.Create(Pool);
    try
      CheckNotNull(CustomPoolManager, '应该能够用自定义内存池创建管理器');
    finally
      CustomPoolManager.Free;
    end;
  finally
    Pool.Free;
  end;
end;

procedure TTestSmartBufferManager.TestRequestAndReleaseBuffer;
var
  BufferResult: TBufferRequestResult;
  TestData: string;
  PData: PChar;
begin
  // 请求一个缓冲区
  BufferResult := FBufferManager.RequestBuffer(1000);
  
  try
    // 检查缓冲区是否分配成功
    CheckNotNull(BufferResult.Buffer, '缓冲区分配应该成功');
    CheckTrue(BufferResult.Size >= 1000, '缓冲区大小应该至少是请求的大小');
    CheckTrue(BufferResult.FromPool, '缓冲区应该来自内存池');
    CheckTrue(BufferResult.BufferId > 0, '缓冲区ID应该是正数');
    
    // 测试写入数据到缓冲区
    TestData := '这是测试数据';
    PData := BufferResult.Buffer;
    Move(PChar(TestData)^, PData^, Length(TestData) * SizeOf(Char));
    
    // 验证数据
    SetLength(TestData, Length(TestData));
    CheckEquals(TestData, PChar(BufferResult.Buffer), '缓冲区数据应该匹配写入的数据');
    
    // 检查统计信息更新
    var Stats := FBufferManager.GetStatistics;
    CheckTrue(Stats.TotalAllocated > 0, '总分配内存应该更新');
    CheckTrue(Stats.TotalBuffersCreated > 0, '创建的缓冲区总数应该更新');
    CheckTrue(Stats.CurrentAllocated > 0, '当前已分配应该更新');
  finally
    // 释放缓冲区
    FBufferManager.ReleaseBuffer(BufferResult);
  end;
  
  // 检查缓冲区是否正确释放
  CheckNull(BufferResult.Buffer, '释放后缓冲区指针应该为nil');
  CheckEquals(0, BufferResult.Size, '释放后缓冲区大小应该为0');
  CheckFalse(BufferResult.FromPool, '释放后FromPool标志应该为False');
  CheckEquals(0, BufferResult.BufferId, '释放后缓冲区ID应该为0');
  
  // 检查统计信息更新
  var Stats := FBufferManager.GetStatistics;
  CheckTrue(Stats.TotalBuffersReleased > 0, '释放的缓冲区总数应该更新');
end;

procedure TTestSmartBufferManager.TestBufferSizeLimits;
begin
  // 设置自定义缓冲区大小限制
  FBufferManager.SetBufferSizeLimits(4096, 1024, 16384);
  
  // 请求小于最小值的缓冲区
  var SmallBuffer := FBufferManager.RequestBuffer(500);
  try
    CheckTrue(SmallBuffer.Size >= 1024, '缓冲区大小应该至少是最小限制');
  finally
    FBufferManager.ReleaseBuffer(SmallBuffer);
  end;
  
  // 请求大于最大值的缓冲区
  var LargeBuffer := FBufferManager.RequestBuffer(20000);
  try
    CheckTrue(LargeBuffer.Size <= 16384, '缓冲区大小应该不超过最大限制');
    CheckTrue(LargeBuffer.Size >= 16384, '缓冲区大小应该至少满足请求');
  finally
    FBufferManager.ReleaseBuffer(LargeBuffer);
  end;
  
  // 测试无效参数
  try
    FBufferManager.SetBufferSizeLimits(500, 1000, 100);
    Fail('应该抛出异常，因为默认大小不在范围内');
  except
    on E: Exception do
      CheckTrue(True, '无效参数应该引发异常');
  end;
end;

procedure TTestSmartBufferManager.TestStaticStrategy;
var
  Buffer1, Buffer2: TBufferRequestResult;
begin
  // 设置静态策略
  FBufferManager.Strategy := busStatic;
  
  // 设置自定义默认大小
  FBufferManager.SetBufferSizeLimits(4096, 1024, 16384);
  
  // 请求两个不同大小的缓冲区
  Buffer1 := FBufferManager.RequestBuffer(2000);
  Buffer2 := FBufferManager.RequestBuffer(8000);
  
  try
    // 在静态策略下，应该都使用默认大小（或满足请求的最小大小）
    CheckEquals(4096, Buffer1.Size, '静态策略下应该使用默认大小');
    CheckTrue(Buffer2.Size >= 8000, '静态策略下应该满足请求的最小大小');
  finally
    FBufferManager.ReleaseBuffer(Buffer1);
    FBufferManager.ReleaseBuffer(Buffer2);
  end;
end;

procedure TTestSmartBufferManager.TestAdaptiveStrategy;
var
  SmallBuffer, LargeBuffer: TBufferRequestResult;
begin
  // 设置自适应策略
  FBufferManager.Strategy := busAdaptive;
  
  // 设置较大的文件大小（模拟大文件）
  FBufferManager.SetTotalFileSize(200 * 1024 * 1024); // 200MB
  
  // 请求缓冲区
  SmallBuffer := FBufferManager.RequestBuffer(1000);
  LargeBuffer := FBufferManager.RequestBuffer(20000);
  
  try
    // 在自适应策略下，应该根据文件大小调整缓冲区
    CheckTrue(LargeBuffer.Size > SmallBuffer.Size, '大请求应该得到更大的缓冲区');
    CheckTrue(SmallBuffer.Size >= 1000, '小缓冲区应该满足请求');
    CheckTrue(LargeBuffer.Size >= 20000, '大缓冲区应该满足请求');
  finally
    FBufferManager.ReleaseBuffer(SmallBuffer);
    FBufferManager.ReleaseBuffer(LargeBuffer);
  end;
  
  // 测试未知文件大小
  FBufferManager.SetTotalFileSize(-1);
  var DefaultBuffer := FBufferManager.RequestBuffer(2000);
  try
    CheckTrue(DefaultBuffer.Size >= 2000, '未知文件大小应该使用默认大小');
  finally
    FBufferManager.ReleaseBuffer(DefaultBuffer);
  end;
end;

procedure TTestSmartBufferManager.TestProgressiveStrategy;
var
  Buffer1, Buffer2, Buffer3: TBufferRequestResult;
begin
  // 设置渐进式策略
  FBufferManager.Strategy := busProgressive;
  
  // 设置文件大小和进度
  FBufferManager.SetTotalFileSize(100 * 1024 * 1024); // 100MB
  
  // 测试不同进度下的缓冲区大小
  FBufferManager.UpdateProcessedBytes(10 * 1024 * 1024); // 10% 进度
  Buffer1 := FBufferManager.RequestBuffer(1000);
  
  FBufferManager.UpdateProcessedBytes(40 * 1024 * 1024); // 40% 进度
  Buffer2 := FBufferManager.RequestBuffer(1000);
  
  FBufferManager.UpdateProcessedBytes(80 * 1024 * 1024); // 80% 进度
  Buffer3 := FBufferManager.RequestBuffer(1000);
  
  try
    // 在渐进式策略下，随着进度增加，缓冲区应该变大
    CheckTrue(Buffer2.Size >= Buffer1.Size, '40%进度的缓冲区应该大于等于10%进度的');
    CheckTrue(Buffer3.Size >= Buffer2.Size, '80%进度的缓冲区应该大于等于40%进度的');
  finally
    FBufferManager.ReleaseBuffer(Buffer1);
    FBufferManager.ReleaseBuffer(Buffer2);
    FBufferManager.ReleaseBuffer(Buffer3);
  end;
end;

procedure TTestSmartBufferManager.TestStatistics;
var
  Buffer: TBufferRequestResult;
  Stats1, Stats2: TBufferStatistics;
begin
  // 获取初始统计信息
  Stats1 := FBufferManager.GetStatistics;
  
  // 分配一个缓冲区
  Buffer := FBufferManager.RequestBuffer(10000);
  
  // 获取分配后的统计信息
  Stats2 := FBufferManager.GetStatistics;
  
  // 检查统计信息更新
  CheckTrue(Stats2.TotalAllocated > Stats1.TotalAllocated, '总分配内存应该增加');
  CheckTrue(Stats2.CurrentAllocated > Stats1.CurrentAllocated, '当前已分配应该增加');
  CheckTrue(Stats2.TotalBuffersCreated > Stats1.TotalBuffersCreated, '创建的缓冲区总数应该增加');
  
  // 释放缓冲区
  FBufferManager.ReleaseBuffer(Buffer);
  
  // 获取释放后的统计信息
  var Stats3 := FBufferManager.GetStatistics;
  
  // 检查统计信息更新
  CheckTrue(Stats3.CurrentAllocated < Stats2.CurrentAllocated, '当前已分配应该减少');
  CheckTrue(Stats3.TotalBuffersReleased > Stats2.TotalBuffersReleased, '释放的缓冲区总数应该增加');
  
  // 测试统计信息文本
  var StatsText := FBufferManager.GetStatisticsText;
  CheckTrue(Length(StatsText) > 0, '统计信息文本不应该为空');
end;

procedure TTestSmartBufferManager.TestReleaseAllBuffers;
var
  Buffer1, Buffer2, Buffer3: TBufferRequestResult;
  Stats1, Stats2: TBufferStatistics;
begin
  // 分配多个缓冲区
  Buffer1 := FBufferManager.RequestBuffer(1000);
  Buffer2 := FBufferManager.RequestBuffer(2000);
  Buffer3 := FBufferManager.RequestBuffer(3000);
  
  // 获取分配后的统计信息
  Stats1 := FBufferManager.GetStatistics;
  
  // 释放所有缓冲区
  FBufferManager.ReleaseAllBuffers;
  
  // 获取释放后的统计信息
  Stats2 := FBufferManager.GetStatistics;
  
  // 检查统计信息更新
  CheckEquals(0, Stats2.CurrentAllocated, '所有缓冲区释放后，当前已分配应该为0');
  CheckTrue(Stats2.TotalBuffersReleased >= Stats1.TotalBuffersReleased + 3, '释放的缓冲区总数应该增加至少3');
  
  // 检查缓冲区是否已释放
  CheckNull(Buffer1.Buffer, '缓冲区1应该已释放');
  CheckNull(Buffer2.Buffer, '缓冲区2应该已释放');
  CheckNull(Buffer3.Buffer, '缓冲区3应该已释放');
end;

procedure TTestSmartBufferManager.TestLargeFileHandling;
var
  LargeBuffer: TBufferRequestResult;
begin
  // 设置自适应策略
  FBufferManager.Strategy := busAdaptive;
  
  // 设置大文件大小
  FBufferManager.SetTotalFileSize(500 * 1024 * 1024); // 500MB
  
  // 请求较大的缓冲区
  LargeBuffer := FBufferManager.RequestBuffer(50000);
  
  try
    // 检查是否分配了足够大的缓冲区
    CheckTrue(LargeBuffer.Size >= 50000, '应该分配足够大的缓冲区');
    
    // 检查是否不超过最大限制
    CheckTrue(LargeBuffer.Size <= FBufferManager.GetStatistics.MaxSingleAllocation, '不应该超过最大单次分配');
  finally
    FBufferManager.ReleaseBuffer(LargeBuffer);
  end;
end;

procedure TTestSmartBufferManager.TestMultipleBuffers;
var
  Buffers: array[0..9] of TBufferRequestResult;
  I: Integer;
begin
  // 分配多个缓冲区
  for I := 0 to 9 do
    Buffers[I] := FBufferManager.RequestBuffer(1000 * (I + 1));
    
  try
    // 检查是否所有缓冲区都分配成功
    for I := 0 to 9 do
    begin
      CheckNotNull(Buffers[I].Buffer, Format('缓冲区 %d 应该分配成功', [I]));
      CheckTrue(Buffers[I].Size >= 1000 * (I + 1), Format('缓冲区 %d 应该满足大小要求', [I]));
    end;
    
    // 检查缓冲区ID是否唯一
    for I := 0 to 8 do
      for var J := I + 1 to 9 do
        CheckNotEquals(Buffers[I].BufferId, Buffers[J].BufferId, Format('缓冲区 %d 和 %d 不应该有相同ID', [I, J]));
        
    // 检查统计信息
    var Stats := FBufferManager.GetStatistics;
    CheckEquals(10, Stats.TotalBuffersCreated, '应该创建10个缓冲区');
    CheckTrue(Stats.CurrentAllocated > 0, '当前已分配应该大于0');
  finally
    // 释放所有缓冲区
    for I := 0 to 9 do
      FBufferManager.ReleaseBuffer(Buffers[I]);
  end;
  
  // 检查释放后统计信息
  var Stats := FBufferManager.GetStatistics;
  CheckEquals(10, Stats.TotalBuffersReleased, '应该释放10个缓冲区');
  CheckEquals(0, Stats.CurrentAllocated, '所有缓冲区释放后，当前已分配应该为0');
end;

{ TBufferTestThread }

constructor TBufferTestThread.Create(BufferManager: TSmartBufferManager; BufferSize, OperationCount: Integer);
begin
  inherited Create(True);
  FBufferManager := BufferManager;
  FBufferSize := BufferSize;
  FOperationCount := OperationCount;
  FSuccess := False;
end;

procedure TBufferTestThread.Execute;
var
  I: Integer;
  Buffer: TBufferRequestResult;
  ErrorOccurred: Boolean;
begin
  ErrorOccurred := False;
  
  try
    for I := 1 to FOperationCount do
    begin
      // 分配缓冲区
      Buffer := FBufferManager.RequestBuffer(FBufferSize);
      
      try
        // 检查缓冲区是否有效
        if Buffer.Buffer = nil then
        begin
          ErrorOccurred := True;
          Break;
        end;
        
        // 写入数据到缓冲区
        FillChar(Buffer.Buffer^, Buffer.Size, I mod 256);
        
        // 模拟一些处理时间
        Sleep(Random(5));
      finally
        // 释放缓冲区
        FBufferManager.ReleaseBuffer(Buffer);
      end;
    end;
    
    FSuccess := not ErrorOccurred;
  except
    FSuccess := False;
  end;
end;

initialization
  RegisterTest(TTestSmartBufferManager.Suite);
end. 