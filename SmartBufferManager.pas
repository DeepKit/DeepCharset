unit SmartBufferManager;

interface

uses
  SysUtils, Classes, Generics.Collections, SyncObjs, ThreadSafeMemoryPool;

type
  /// <summary>
  /// 缓冲区分配策略
  /// </summary>
  TBufferStrategy = (
    /// <summary>
    /// 静态策略：始终分配固定大小的缓冲区
    /// </summary>
    bsStatic,
    
    /// <summary>
    /// 自适应策略：根据历史使用情况调整缓冲区大小
    /// </summary>
    bsAdaptive,
    
    /// <summary>
    /// 渐进式策略：以较小的缓冲区开始，逐渐增加
    /// </summary>
    bsProgressive
  );

  /// <summary>
  /// 智能缓冲区统计信息
  /// </summary>
  TBufferStatistics = record
    /// <summary>
    /// 已分配缓冲区数
    /// </summary>
    AllocatedBuffers: Integer;
    
    /// <summary>
    /// 最大缓冲区大小
    /// </summary>
    MaxBufferSize: Integer;
    
    /// <summary>
    /// 最小缓冲区大小
    /// </summary>
    MinBufferSize: Integer;
    
    /// <summary>
    /// 平均缓冲区大小
    /// </summary>
    AvgBufferSize: Integer;
    
    /// <summary>
    /// 缓冲区调整次数
    /// </summary>
    ResizeCount: Integer;
    
    /// <summary>
    /// 缓冲区溢出次数
    /// </summary>
    OverflowCount: Integer;
    
    /// <summary>
    /// 内存利用率(%)
    /// </summary>
    MemoryUtilization: Double;
    
    /// <summary>
    /// 总内存使用量(字节)
    /// </summary>
    TotalMemoryUsage: Int64;
  end;

  /// <summary>
  /// 缓冲区信息
  /// </summary>
  TBufferInfo = record
    /// <summary>
    /// 缓冲区指针
    /// </summary>
    Buffer: Pointer;
    
    /// <summary>
    /// 缓冲区大小
    /// </summary>
    Size: Integer;
    
    /// <summary>
    /// 当前位置
    /// </summary>
    Position: Integer;
    
    /// <summary>
    /// 实际使用的字节数
    /// </summary>
    UsedBytes: Integer;
    
    /// <summary>
    /// 缓冲区ID
    /// </summary>
    BufferID: Integer;
    
    /// <summary>
    /// 创建时间
    /// </summary>
    CreatedTime: TDateTime;
    
    /// <summary>
    /// 能否调整大小
    /// </summary>
    CanResize: Boolean;
  end;

  /// <summary>
  /// 缓冲区错误类型
  /// </summary>
  EBufferError = class(Exception);

  /// <summary>
  /// 智能缓冲区管理器
  /// </summary>
  TSmartBufferManager = class
  private
    FLock: TCriticalSection;
    FMemoryPool: TThreadSafeMemoryPool;
    FStrategy: TBufferStrategy;
    FDefaultBufferSize: Integer;
    FMaxBufferSize: Integer;
    FMinBufferSize: Integer;
    FGrowthFactor: Double;
    FActiveBuffers: TDictionary<Integer, TBufferInfo>;
    FNextBufferID: Integer;
    FStatistics: TBufferStatistics;
    FBufferHistory: TList<Integer>;
    FMaxHistorySize: Integer;
    
    procedure UpdateStatistics;
    function CalculateOptimalSize(RecentUsage: Integer): Integer;
    function AdjustBufferSize(const Buffer: TBufferInfo; RequiredSize: Integer): TBufferInfo;
    procedure AddToHistory(Size: Integer);
    function GetAverageHistorySize: Integer;
  public
    /// <summary>
    /// 创建智能缓冲区管理器
    /// </summary>
    /// <param name="MemoryPool">线程安全内存池</param>
    /// <param name="DefaultSize">默认缓冲区大小(字节)</param>
    /// <param name="Strategy">缓冲区策略</param>
    constructor Create(MemoryPool: TThreadSafeMemoryPool; DefaultSize: Integer = 8192; 
                       Strategy: TBufferStrategy = bsAdaptive);
    
    /// <summary>
    /// 销毁缓冲区管理器
    /// </summary>
    destructor Destroy; override;
    
    /// <summary>
    /// 请求一个新的缓冲区
    /// </summary>
    /// <param name="InitialSize">初始大小(字节)</param>
    /// <returns>缓冲区ID</returns>
    function RequestBuffer(InitialSize: Integer = 0): Integer;
    
    /// <summary>
    /// 释放缓冲区
    /// </summary>
    /// <param name="BufferID">缓冲区ID</param>
    /// <returns>成功返回True</returns>
    function ReleaseBuffer(BufferID: Integer): Boolean;
    
    /// <summary>
    /// 释放所有缓冲区
    /// </summary>
    procedure ReleaseAllBuffers;
    
    /// <summary>
    /// 写入数据到缓冲区
    /// </summary>
    /// <param name="BufferID">缓冲区ID</param>
    /// <param name="Data">数据指针</param>
    /// <param name="Size">数据大小(字节)</param>
    /// <returns>写入的字节数</returns>
    function WriteToBuffer(BufferID: Integer; Data: Pointer; Size: Integer): Integer;
    
    /// <summary>
    /// 从缓冲区读取数据
    /// </summary>
    /// <param name="BufferID">缓冲区ID</param>
    /// <param name="Data">目标内存指针</param>
    /// <param name="Size">要读取的字节数</param>
    /// <returns>实际读取的字节数</returns>
    function ReadFromBuffer(BufferID: Integer; Data: Pointer; Size: Integer): Integer;
    
    /// <summary>
    /// 重置缓冲区位置
    /// </summary>
    /// <param name="BufferID">缓冲区ID</param>
    /// <param name="Position">新位置</param>
    /// <returns>成功返回True</returns>
    function SeekBuffer(BufferID: Integer; Position: Integer): Boolean;
    
    /// <summary>
    /// 清空缓冲区
    /// </summary>
    /// <param name="BufferID">缓冲区ID</param>
    /// <returns>成功返回True</returns>
    function ClearBuffer(BufferID: Integer): Boolean;
    
    /// <summary>
    /// 获取缓冲区信息
    /// </summary>
    /// <param name="BufferID">缓冲区ID</param>
    /// <returns>缓冲区信息</returns>
    function GetBufferInfo(BufferID: Integer): TBufferInfo;
    
    /// <summary>
    /// 调整缓冲区大小
    /// </summary>
    /// <param name="BufferID">缓冲区ID</param>
    /// <param name="NewSize">新大小(字节)</param>
    /// <returns>成功返回True</returns>
    function ResizeBuffer(BufferID: Integer; NewSize: Integer): Boolean;
    
    /// <summary>
    /// 获取统计信息
    /// </summary>
    /// <returns>缓冲区统计信息</returns>
    function GetStatistics: TBufferStatistics;
    
    /// <summary>
    /// 获取统计信息文本
    /// </summary>
    /// <returns>格式化的统计信息文本</returns>
    function GetStatisticsText: string;
    
    /// <summary>
    /// 重置统计信息
    /// </summary>
    procedure ResetStatistics;
    
    /// <summary>
    /// 缓冲区分配策略
    /// </summary>
    property Strategy: TBufferStrategy read FStrategy write FStrategy;
    
    /// <summary>
    /// 缓冲区默认大小(字节)
    /// </summary>
    property DefaultBufferSize: Integer read FDefaultBufferSize write FDefaultBufferSize;
    
    /// <summary>
    /// 缓冲区最大大小(字节)
    /// </summary>
    property MaxBufferSize: Integer read FMaxBufferSize write FMaxBufferSize;
    
    /// <summary>
    /// 缓冲区最小大小(字节)
    /// </summary>
    property MinBufferSize: Integer read FMinBufferSize write FMinBufferSize;
    
    /// <summary>
    /// 缓冲区增长因子
    /// </summary>
    property GrowthFactor: Double read FGrowthFactor write FGrowthFactor;
  end;

implementation

uses
  Math;

{ TSmartBufferManager }

constructor TSmartBufferManager.Create(MemoryPool: TThreadSafeMemoryPool;
  DefaultSize: Integer; Strategy: TBufferStrategy);
begin
  inherited Create;
  
  if MemoryPool = nil then
    raise EBufferError.Create('内存池不能为空');
    
  FMemoryPool := MemoryPool;
  FLock := TCriticalSection.Create;
  
  // 初始化参数
  if DefaultSize <= 0 then
    DefaultSize := 8192;
    
  FDefaultBufferSize := DefaultSize;
  FMinBufferSize := 1024;
  FMaxBufferSize := 16 * 1024 * 1024; // 16MB
  FGrowthFactor := 1.5;
  FStrategy := Strategy;
  
  // 初始化容器
  FActiveBuffers := TDictionary<Integer, TBufferInfo>.Create;
  FBufferHistory := TList<Integer>.Create;
  FMaxHistorySize := 100;
  
  // 初始化ID计数器
  FNextBufferID := 1;
  
  // 初始化统计信息
  FillChar(FStatistics, SizeOf(FStatistics), 0);
  FStatistics.MinBufferSize := MaxInt;
end;

destructor TSmartBufferManager.Destroy;
begin
  // 释放所有缓冲区
  ReleaseAllBuffers;
  
  // 释放容器
  FActiveBuffers.Free;
  FBufferHistory.Free;
  
  // 释放同步对象
  FLock.Free;
  
  inherited;
end;

function TSmartBufferManager.RequestBuffer(InitialSize: Integer): Integer;
var
  BufferInfo: TBufferInfo;
  TargetSize: Integer;
begin
  // 确定缓冲区大小
  if InitialSize <= 0 then
    TargetSize := FDefaultBufferSize
  else
    TargetSize := Max(InitialSize, FMinBufferSize);
    
  // 根据策略调整大小
  case FStrategy of
    bsStatic:
      TargetSize := FDefaultBufferSize;
      
    bsAdaptive:
      TargetSize := Max(CalculateOptimalSize(InitialSize), TargetSize);
      
    bsProgressive:
      if InitialSize <= 0 then
        TargetSize := FMinBufferSize;
  end;
  
  // 确保不超过最大限制
  TargetSize := Min(TargetSize, FMaxBufferSize);
  
  FLock.Enter;
  try
    // 创建新缓冲区
    FillChar(BufferInfo, SizeOf(BufferInfo), 0);
    BufferInfo.Buffer := FMemoryPool.GetMemory(TargetSize);
    
    if BufferInfo.Buffer = nil then
      raise EBufferError.CreateFmt('无法分配大小为 %d 字节的缓冲区', [TargetSize]);
      
    BufferInfo.Size := TargetSize;
    BufferInfo.Position := 0;
    BufferInfo.UsedBytes := 0;
    BufferInfo.BufferID := FNextBufferID;
    BufferInfo.CreatedTime := Now;
    BufferInfo.CanResize := True;
    
    // 添加到活动缓冲区
    FActiveBuffers.Add(BufferInfo.BufferID, BufferInfo);
    
    // 更新历史
    AddToHistory(TargetSize);
    
    // 更新统计信息
    Inc(FStatistics.AllocatedBuffers);
    Inc(FStatistics.TotalMemoryUsage, TargetSize);
    
    if TargetSize > FStatistics.MaxBufferSize then
      FStatistics.MaxBufferSize := TargetSize;
      
    if TargetSize < FStatistics.MinBufferSize then
      FStatistics.MinBufferSize := TargetSize;
      
    // 更新结果和ID计数器
    Result := BufferInfo.BufferID;
    Inc(FNextBufferID);
    
    // 更新统计信息
    UpdateStatistics;
  finally
    FLock.Leave;
  end;
end;

function TSmartBufferManager.ReleaseBuffer(BufferID: Integer): Boolean;
var
  BufferInfo: TBufferInfo;
begin
  Result := False;
  
  FLock.Enter;
  try
    if not FActiveBuffers.TryGetValue(BufferID, BufferInfo) then
      Exit;
      
    // 释放内存
    if BufferInfo.Buffer <> nil then
      FMemoryPool.FreeMemory(BufferInfo.Buffer);
      
    // 更新统计信息
    Dec(FStatistics.AllocatedBuffers);
    Dec(FStatistics.TotalMemoryUsage, BufferInfo.Size);
    
    // 从活动列表中移除
    FActiveBuffers.Remove(BufferID);
    
    Result := True;
    
    // 更新统计信息
    UpdateStatistics;
  finally
    FLock.Leave;
  end;
end;

procedure TSmartBufferManager.ReleaseAllBuffers;
var
  Pair: TPair<Integer, TBufferInfo>;
begin
  FLock.Enter;
  try
    for Pair in FActiveBuffers.ToArray do
    begin
      if Pair.Value.Buffer <> nil then
        FMemoryPool.FreeMemory(Pair.Value.Buffer);
    end;
    
    // 清空活动缓冲区
    FActiveBuffers.Clear;
    
    // 重置统计信息
    FillChar(FStatistics, SizeOf(FStatistics), 0);
    FStatistics.MinBufferSize := MaxInt;
    
    // 清空历史
    FBufferHistory.Clear;
  finally
    FLock.Leave;
  end;
end;

function TSmartBufferManager.WriteToBuffer(BufferID: Integer; Data: Pointer;
  Size: Integer): Integer;
var
  BufferInfo: TBufferInfo;
  RemainingSpace: Integer;
  RequiredSize: Integer;
begin
  Result := 0;
  
  if (Data = nil) or (Size <= 0) then
    Exit;
    
  FLock.Enter;
  try
    if not FActiveBuffers.TryGetValue(BufferID, BufferInfo) then
      Exit;
      
    // 计算剩余空间
    RemainingSpace := BufferInfo.Size - BufferInfo.Position;
    
    // 如果空间不足，尝试调整缓冲区大小
    if RemainingSpace < Size then
    begin
      if not BufferInfo.CanResize then
      begin
        // 缓冲区不可调整大小时，只写入可用空间
        Result := Min(Size, RemainingSpace);
        Inc(FStatistics.OverflowCount);
      end
      else
      begin
        // 计算新的缓冲区大小
        RequiredSize := BufferInfo.Position + Size;
        BufferInfo := AdjustBufferSize(BufferInfo, RequiredSize);
        
        // 如果调整失败，只写入可用空间
        if BufferInfo.Size - BufferInfo.Position < Size then
        begin
          Result := Min(Size, BufferInfo.Size - BufferInfo.Position);
          Inc(FStatistics.OverflowCount);
        end
        else
          Result := Size;
          
        // 更新缓冲区信息
        FActiveBuffers[BufferID] := BufferInfo;
      end;
    end
    else
      Result := Size;
      
    // 写入数据
    if Result > 0 then
    begin
      Move(Data^, Pointer(NativeUInt(BufferInfo.Buffer) + BufferInfo.Position)^, Result);
      Inc(BufferInfo.Position, Result);
      BufferInfo.UsedBytes := Max(BufferInfo.UsedBytes, BufferInfo.Position);
      FActiveBuffers[BufferID] := BufferInfo;
    end;
    
    // 更新统计信息
    UpdateStatistics;
  finally
    FLock.Leave;
  end;
end;

function TSmartBufferManager.ReadFromBuffer(BufferID: Integer; Data: Pointer;
  Size: Integer): Integer;
var
  BufferInfo: TBufferInfo;
  AvailableData: Integer;
begin
  Result := 0;
  
  if (Data = nil) or (Size <= 0) then
    Exit;
    
  FLock.Enter;
  try
    if not FActiveBuffers.TryGetValue(BufferID, BufferInfo) then
      Exit;
      
    // 计算可用数据量
    AvailableData := BufferInfo.UsedBytes - BufferInfo.Position;
    
    if AvailableData <= 0 then
      Exit;
      
    // 确定读取大小
    Result := Min(Size, AvailableData);
    
    // 读取数据
    Move(Pointer(NativeUInt(BufferInfo.Buffer) + BufferInfo.Position)^, Data^, Result);
    Inc(BufferInfo.Position, Result);
    FActiveBuffers[BufferID] := BufferInfo;
  finally
    FLock.Leave;
  end;
end;

function TSmartBufferManager.SeekBuffer(BufferID: Integer; Position: Integer): Boolean;
var
  BufferInfo: TBufferInfo;
begin
  Result := False;
  
  FLock.Enter;
  try
    if not FActiveBuffers.TryGetValue(BufferID, BufferInfo) then
      Exit;
      
    // 验证位置
    if (Position < 0) or (Position > BufferInfo.Size) then
      Exit;
      
    // 更新位置
    BufferInfo.Position := Position;
    FActiveBuffers[BufferID] := BufferInfo;
    
    Result := True;
  finally
    FLock.Leave;
  end;
end;

function TSmartBufferManager.ClearBuffer(BufferID: Integer): Boolean;
var
  BufferInfo: TBufferInfo;
begin
  Result := False;
  
  FLock.Enter;
  try
    if not FActiveBuffers.TryGetValue(BufferID, BufferInfo) then
      Exit;
      
    // 清空缓冲区
    FillChar(BufferInfo.Buffer^, BufferInfo.Size, 0);
    BufferInfo.Position := 0;
    BufferInfo.UsedBytes := 0;
    FActiveBuffers[BufferID] := BufferInfo;
    
    Result := True;
  finally
    FLock.Leave;
  end;
end;

function TSmartBufferManager.GetBufferInfo(BufferID: Integer): TBufferInfo;
begin
  FillChar(Result, SizeOf(Result), 0);
  
  FLock.Enter;
  try
    if not FActiveBuffers.TryGetValue(BufferID, Result) then
      Result.BufferID := -1;
  finally
    FLock.Leave;
  end;
end;

function TSmartBufferManager.ResizeBuffer(BufferID: Integer; NewSize: Integer): Boolean;
var
  BufferInfo: TBufferInfo;
begin
  Result := False;
  
  if NewSize <= 0 then
    Exit;
    
  FLock.Enter;
  try
    if not FActiveBuffers.TryGetValue(BufferID, BufferInfo) then
      Exit;
      
    // 如果不可调整大小，直接返回
    if not BufferInfo.CanResize then
      Exit;
      
    // 如果新大小小于最小值，使用最小值
    NewSize := Max(NewSize, FMinBufferSize);
    
    // 如果新大小大于最大值，使用最大值
    NewSize := Min(NewSize, FMaxBufferSize);
    
    // 如果大小相同，无需调整
    if NewSize = BufferInfo.Size then
    begin
      Result := True;
      Exit;
    end;
    
    // 调整缓冲区大小
    BufferInfo := AdjustBufferSize(BufferInfo, NewSize);
    
    // 更新缓冲区信息
    FActiveBuffers[BufferID] := BufferInfo;
    
    // 更新统计信息
    Inc(FStatistics.ResizeCount);
    UpdateStatistics;
    
    Result := True;
  finally
    FLock.Leave;
  end;
end;

function TSmartBufferManager.GetStatistics: TBufferStatistics;
begin
  FLock.Enter;
  try
    Result := FStatistics;
  finally
    FLock.Leave;
  end;
end;

function TSmartBufferManager.GetStatisticsText: string;
var
  Stats: TBufferStatistics;
begin
  Stats := GetStatistics;
  
  Result := '缓冲区统计信息:' + sLineBreak;
  Result := Result + '分配缓冲区数: ' + IntToStr(Stats.AllocatedBuffers) + sLineBreak;
  Result := Result + '最大缓冲区大小: ' + IntToStr(Stats.MaxBufferSize) + ' 字节' + sLineBreak;
  Result := Result + '最小缓冲区大小: ' + IntToStr(Stats.MinBufferSize) + ' 字节' + sLineBreak;
  Result := Result + '平均缓冲区大小: ' + IntToStr(Stats.AvgBufferSize) + ' 字节' + sLineBreak;
  Result := Result + '调整次数: ' + IntToStr(Stats.ResizeCount) + sLineBreak;
  Result := Result + '溢出次数: ' + IntToStr(Stats.OverflowCount) + sLineBreak;
  Result := Result + '总内存使用量: ' + IntToStr(Stats.TotalMemoryUsage) + ' 字节' + sLineBreak;
  Result := Result + '内存利用率: ' + FormatFloat('0.00', Stats.MemoryUtilization) + '%';
end;

procedure TSmartBufferManager.ResetStatistics;
begin
  FLock.Enter;
  try
    FStatistics.ResizeCount := 0;
    FStatistics.OverflowCount := 0;
    
    // 保留当前缓冲区数量和内存使用情况
    FStatistics.AvgBufferSize := 0;
    
    // 重新计算最大和最小值
    FStatistics.MaxBufferSize := 0;
    FStatistics.MinBufferSize := MaxInt;
    
    // 更新现有缓冲区的统计信息
    UpdateStatistics;
  finally
    FLock.Leave;
  end;
end;

procedure TSmartBufferManager.UpdateStatistics;
var
  Pair: TPair<Integer, TBufferInfo>;
  TotalSize, UsedSize: Int64;
  Count: Integer;
  Size: Integer;
begin
  TotalSize := 0;
  UsedSize := 0;
  Count := 0;
  
  for Pair in FActiveBuffers do
  begin
    Size := Pair.Value.Size;
    Inc(TotalSize, Size);
    Inc(UsedSize, Pair.Value.UsedBytes);
    Inc(Count);
    
    if Size > FStatistics.MaxBufferSize then
      FStatistics.MaxBufferSize := Size;
      
    if (Size < FStatistics.MinBufferSize) and (Size > 0) then
      FStatistics.MinBufferSize := Size;
  end;
  
  FStatistics.AllocatedBuffers := Count;
  FStatistics.TotalMemoryUsage := TotalSize;
  
  // 计算平均缓冲区大小
  if Count > 0 then
    FStatistics.AvgBufferSize := Round(TotalSize / Count)
  else
    FStatistics.AvgBufferSize := 0;
    
  // 计算内存利用率
  if TotalSize > 0 then
    FStatistics.MemoryUtilization := (UsedSize / TotalSize) * 100
  else
    FStatistics.MemoryUtilization := 0;
end;

function TSmartBufferManager.CalculateOptimalSize(RecentUsage: Integer): Integer;
var
  AvgSize: Integer;
begin
  // 如果有具体的使用大小，将其增加一定比例
  if RecentUsage > 0 then
    Result := Round(RecentUsage * FGrowthFactor)
  else
  begin
    // 否则基于历史大小
    AvgSize := GetAverageHistorySize;
    
    if AvgSize > 0 then
      Result := AvgSize
    else
      Result := FDefaultBufferSize;
  end;
  
  // 确保在限制范围内
  Result := Max(Min(Result, FMaxBufferSize), FMinBufferSize);
end;

function TSmartBufferManager.AdjustBufferSize(const Buffer: TBufferInfo;
  RequiredSize: Integer): TBufferInfo;
var
  NewSize: Integer;
  NewBuffer: Pointer;
begin
  Result := Buffer;
  
  // 已经足够大
  if Buffer.Size >= RequiredSize then
    Exit;
    
  // 根据策略计算新大小
  case FStrategy of
    bsStatic:
      // 静态策略不调整大小，但如果需要的空间超过当前大小，使用所需的大小
      NewSize := Max(Buffer.Size, RequiredSize);
      
    bsAdaptive:
      // 自适应策略根据需求调整，但增加一些余量
      NewSize := Round(RequiredSize * FGrowthFactor);
      
    bsProgressive:
      // 渐进式策略每次加倍，直到满足需求
      NewSize := Buffer.Size;
      while NewSize < RequiredSize do
        NewSize := Round(NewSize * FGrowthFactor);
  end;
  
  // 确保不超过最大大小
  NewSize := Min(NewSize, FMaxBufferSize);
  
  // 确保新大小足够大
  if NewSize < RequiredSize then
    NewSize := RequiredSize;
    
  // 分配新缓冲区
  NewBuffer := FMemoryPool.GetMemory(NewSize);
  
  if NewBuffer = nil then
    Exit;
    
  try
    // 复制原缓冲区数据
    Move(Buffer.Buffer^, NewBuffer^, Buffer.UsedBytes);
    
    // 释放原缓冲区
    FMemoryPool.FreeMemory(Buffer.Buffer);
    
    // 更新统计信息
    Dec(FStatistics.TotalMemoryUsage, Buffer.Size);
    Inc(FStatistics.TotalMemoryUsage, NewSize);
    Inc(FStatistics.ResizeCount);
    
    // 更新历史
    AddToHistory(NewSize);
    
    // 更新结果
    Result.Buffer := NewBuffer;
    Result.Size := NewSize;
  except
    // 出错时释放新分配的内存并保持原状
    FMemoryPool.FreeMemory(NewBuffer);
  end;
end;

procedure TSmartBufferManager.AddToHistory(Size: Integer);
begin
  if Size <= 0 then
    Exit;
    
  // 添加到历史
  FBufferHistory.Add(Size);
  
  // 如果超过最大历史大小，移除最旧的
  while FBufferHistory.Count > FMaxHistorySize do
    FBufferHistory.Delete(0);
end;

function TSmartBufferManager.GetAverageHistorySize: Integer;
var
  I, Total, Count: Integer;
begin
  Total := 0;
  Count := FBufferHistory.Count;
  
  if Count = 0 then
  begin
    Result := 0;
    Exit;
  end;
  
  // 计算所有历史大小的平均值
  for I := 0 to Count - 1 do
    Inc(Total, FBufferHistory[I]);
    
  Result := Round(Total / Count);
end;

end. 