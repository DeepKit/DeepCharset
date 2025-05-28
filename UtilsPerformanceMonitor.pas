unit UtilsPerformanceMonitor;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, Winapi.Windows, System.Diagnostics;

type
  /// <summary>
  /// 性能监控器
  /// </summary>
  TPerformanceMonitor = class
  private
    FStartTime: TDateTime;
    FStopwatch: TStopwatch;
    FMemoryUsageStart: Cardinal;
    FMemoryUsagePeak: Cardinal;
    FOperationName: string;
    FLogCallback: TProc<string>;
    
    function GetCurrentMemoryUsage: Cardinal;
    procedure UpdatePeakMemory;
    
  public
    constructor Create(const OperationName: string; LogCallback: TProc<string> = nil);
    destructor Destroy; override;
    
    /// <summary>
    /// 开始监控
    /// </summary>
    procedure Start;
    
    /// <summary>
    /// 停止监控并输出结果
    /// </summary>
    procedure Stop;
    
    /// <summary>
    /// 获取当前经过的时间（毫秒）
    /// </summary>
    function GetElapsedMilliseconds: Int64;
    
    /// <summary>
    /// 获取内存使用情况
    /// </summary>
    function GetMemoryInfo: string;
    
    /// <summary>
    /// 记录检查点
    /// </summary>
    procedure Checkpoint(const CheckpointName: string);
    
    property OperationName: string read FOperationName;
    property ElapsedMilliseconds: Int64 read GetElapsedMilliseconds;
  end;

  /// <summary>
  /// 性能监控管理器
  /// </summary>
  TPerformanceManager = class
  private
    class var FInstance: TPerformanceManager;
    FMonitors: TList<TPerformanceMonitor>;
    FLogCallback: TProc<string>;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    class function Instance: TPerformanceManager;
    class procedure ReleaseInstance;
    
    /// <summary>
    /// 设置日志回调
    /// </summary>
    procedure SetLogCallback(LogCallback: TProc<string>);
    
    /// <summary>
    /// 创建性能监控器
    /// </summary>
    function CreateMonitor(const OperationName: string): TPerformanceMonitor;
    
    /// <summary>
    /// 移除性能监控器
    /// </summary>
    procedure RemoveMonitor(Monitor: TPerformanceMonitor);
    
    /// <summary>
    /// 获取所有活动监控器的摘要
    /// </summary>
    function GetActiveMonitorsSummary: string;
  end;

implementation

{ TPerformanceMonitor }

constructor TPerformanceMonitor.Create(const OperationName: string; LogCallback: TProc<string>);
begin
  inherited Create;
  FOperationName := OperationName;
  FLogCallback := LogCallback;
  FStopwatch := TStopwatch.Create;
  FMemoryUsageStart := GetCurrentMemoryUsage;
  FMemoryUsagePeak := FMemoryUsageStart;
end;

destructor TPerformanceMonitor.Destroy;
begin
  if FStopwatch.IsRunning then
    Stop;
  inherited;
end;

function TPerformanceMonitor.GetCurrentMemoryUsage: Cardinal;
var
  MemInfo: TMemoryManagerState;
  SmallBlockTypeState: TSmallBlockTypeState;
begin
  GetMemoryManagerState(MemInfo);
  Result := MemInfo.TotalAllocatedMediumBlockSize + MemInfo.TotalAllocatedLargeBlockSize;
  
  for var I := Low(MemInfo.SmallBlockTypeStates) to High(MemInfo.SmallBlockTypeStates) do
  begin
    SmallBlockTypeState := MemInfo.SmallBlockTypeStates[I];
    Inc(Result, SmallBlockTypeState.UseableBlockSize * SmallBlockTypeState.AllocatedBlockCount);
  end;
end;

procedure TPerformanceMonitor.UpdatePeakMemory;
var
  CurrentMemory: Cardinal;
begin
  CurrentMemory := GetCurrentMemoryUsage;
  if CurrentMemory > FMemoryUsagePeak then
    FMemoryUsagePeak := CurrentMemory;
end;

procedure TPerformanceMonitor.Start;
begin
  FStartTime := Now;
  FMemoryUsageStart := GetCurrentMemoryUsage;
  FMemoryUsagePeak := FMemoryUsageStart;
  FStopwatch.Start;
  
  if Assigned(FLogCallback) then
    FLogCallback(Format('性能监控开始: %s', [FOperationName]));
end;

procedure TPerformanceMonitor.Stop;
var
  ElapsedMs: Int64;
  MemoryInfo: string;
begin
  if not FStopwatch.IsRunning then
    Exit;
    
  FStopwatch.Stop;
  UpdatePeakMemory;
  
  ElapsedMs := FStopwatch.ElapsedMilliseconds;
  MemoryInfo := GetMemoryInfo;
  
  if Assigned(FLogCallback) then
  begin
    FLogCallback(Format('性能监控结束: %s', [FOperationName]));
    FLogCallback(Format('  耗时: %d ms', [ElapsedMs]));
    FLogCallback(Format('  内存: %s', [MemoryInfo]));
  end;
end;

function TPerformanceMonitor.GetElapsedMilliseconds: Int64;
begin
  Result := FStopwatch.ElapsedMilliseconds;
end;

function TPerformanceMonitor.GetMemoryInfo: string;
var
  CurrentMemory: Cardinal;
  MemoryDiff: Integer;
begin
  UpdatePeakMemory;
  CurrentMemory := GetCurrentMemoryUsage;
  MemoryDiff := Integer(CurrentMemory) - Integer(FMemoryUsageStart);
  
  Result := Format('起始: %s, 当前: %s, 峰值: %s, 变化: %s',
    [FormatFloat('#,##0', FMemoryUsageStart / 1024),
     FormatFloat('#,##0', CurrentMemory / 1024),
     FormatFloat('#,##0', FMemoryUsagePeak / 1024),
     FormatFloat('+#,##0;-#,##0', MemoryDiff / 1024)]) + ' KB';
end;

procedure TPerformanceMonitor.Checkpoint(const CheckpointName: string);
begin
  UpdatePeakMemory;
  
  if Assigned(FLogCallback) then
  begin
    FLogCallback(Format('检查点 [%s]: %s', [CheckpointName, FOperationName]));
    FLogCallback(Format('  已耗时: %d ms', [GetElapsedMilliseconds]));
    FLogCallback(Format('  内存: %s', [GetMemoryInfo]));
  end;
end;

{ TPerformanceManager }

constructor TPerformanceManager.Create;
begin
  inherited Create;
  FMonitors := TList<TPerformanceMonitor>.Create;
end;

destructor TPerformanceManager.Destroy;
var
  Monitor: TPerformanceMonitor;
begin
  // 清理所有监控器
  for Monitor in FMonitors do
    Monitor.Free;
  FMonitors.Free;
  inherited;
end;

class function TPerformanceManager.Instance: TPerformanceManager;
begin
  if not Assigned(FInstance) then
    FInstance := TPerformanceManager.Create;
  Result := FInstance;
end;

class procedure TPerformanceManager.ReleaseInstance;
begin
  if Assigned(FInstance) then
  begin
    FInstance.Free;
    FInstance := nil;
  end;
end;

procedure TPerformanceManager.SetLogCallback(LogCallback: TProc<string>);
begin
  FLogCallback := LogCallback;
end;

function TPerformanceManager.CreateMonitor(const OperationName: string): TPerformanceMonitor;
begin
  Result := TPerformanceMonitor.Create(OperationName, FLogCallback);
  FMonitors.Add(Result);
end;

procedure TPerformanceManager.RemoveMonitor(Monitor: TPerformanceMonitor);
begin
  if Assigned(Monitor) then
  begin
    FMonitors.Remove(Monitor);
    Monitor.Free;
  end;
end;

function TPerformanceManager.GetActiveMonitorsSummary: string;
var
  Monitor: TPerformanceMonitor;
  Summary: TStringList;
begin
  Summary := TStringList.Create;
  try
    Summary.Add(Format('活动监控器数量: %d', [FMonitors.Count]));
    
    for Monitor in FMonitors do
    begin
      if Monitor.FStopwatch.IsRunning then
      begin
        Summary.Add(Format('  %s: %d ms, %s',
          [Monitor.OperationName, Monitor.GetElapsedMilliseconds, Monitor.GetMemoryInfo]));
      end;
    end;
    
    Result := Summary.Text;
  finally
    Summary.Free;
  end;
end;

initialization

finalization
  TPerformanceManager.ReleaseInstance;

end.
