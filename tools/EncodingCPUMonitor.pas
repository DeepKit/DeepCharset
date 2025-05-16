unit EncodingCPUMonitor;

{
  EncodingCPUMonitor.pas
  实现CPU利用率监控

  作为improve.md中任务2.3.4的实现
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  /// <summary>
  /// CPU使用率信息
  /// </summary>
  TCPUUsageInfo = record
    ProcessorCount: Integer;     // 处理器数量
    TotalUsage: Double;          // 总体CPU使用率（百分比）
    ProcessUsage: Double;        // 进程CPU使用率（百分比）
    ThreadUsage: Double;         // 线程CPU使用率（百分比）
    KernelTime: UInt64;          // 内核时间（100纳秒为单位）
    UserTime: UInt64;            // 用户时间（100纳秒为单位）
    IdleTime: UInt64;            // 空闲时间（100纳秒为单位）

    constructor Create(AProcessorCount: Integer; ATotalUsage, AProcessUsage, AThreadUsage: Double;
      AKernelTime, AUserTime, AIdleTime: UInt64);
  end;

  /// <summary>
  /// CPU使用率记录
  /// </summary>
  TCPUUsageRecord = record
    Timestamp: TDateTime;        // 时间戳
    UsageInfo: TCPUUsageInfo;    // CPU使用率信息

    constructor Create(const AUsageInfo: TCPUUsageInfo);
  end;

  /// <summary>
  /// CPU利用率监控器
  /// </summary>
  TEncodingCPUMonitor = class
  private
    FLogCallback: TProc<string>;
    FRecords: TList<TCPUUsageRecord>;
    FMonitorTimer: TTimer;
    FMonitorInterval: Integer;
    FIsMonitoring: Boolean;

    // 上一次测量的时间信息
    FLastProcessorTime: UInt64;
    FLastProcessTime: UInt64;
    FLastThreadTime: UInt64;
    FLastKernelTime: UInt64;
    FLastUserTime: UInt64;
    FLastIdleTime: UInt64;

    procedure Log(const Msg: string);
    procedure OnMonitorTimer(Sender: TObject);
    function GetCurrentCPUUsage: TCPUUsageInfo;
    function GetProcessorTime: UInt64;
    function GetProcessTime: UInt64;
    function GetThreadTime: UInt64;
    function GetSystemTimes(out KernelTime, UserTime, IdleTime: UInt64): Boolean;
  public
    constructor Create(ALogCallback: TProc<string> = nil);
    destructor Destroy; override;

    /// <summary>
    /// 开始监控CPU利用率
    /// </summary>
    procedure StartMonitoring(Interval: Integer = 1000);

    /// <summary>
    /// 停止监控CPU利用率
    /// </summary>
    procedure StopMonitoring;

    /// <summary>
    /// 获取当前CPU使用率信息
    /// </summary>
    function GetCPUUsage: TCPUUsageInfo;

    /// <summary>
    /// 获取CPU使用率记录
    /// </summary>
    function GetCPUUsageRecords: TArray<TCPUUsageRecord>;

    /// <summary>
    /// 清除CPU使用率记录
    /// </summary>
    procedure ClearRecords;

    /// <summary>
    /// 生成CPU使用率报告
    /// </summary>
    function GenerateReport: string;

    /// <summary>
    /// 保存CPU使用率报告到文件
    /// </summary>
    procedure SaveReportToFile(const FilePath: string);

    /// <summary>
    /// 监控间隔（毫秒）
    /// </summary>
    property MonitorInterval: Integer read FMonitorInterval write FMonitorInterval;

    /// <summary>
    /// 是否正在监控
    /// </summary>
    property IsMonitoring: Boolean read FIsMonitoring;

    /// <summary>
    /// 日志回调
    /// </summary>
    property LogCallback: TProc<string> read FLogCallback write FLogCallback;
  end;

implementation

uses
  Winapi.Windows, System.Math, System.IOUtils, System.DateUtils;

{ TCPUUsageInfo }

constructor TCPUUsageInfo.Create(AProcessorCount: Integer; ATotalUsage, AProcessUsage, AThreadUsage: Double;
  AKernelTime, AUserTime, AIdleTime: UInt64);
begin
  ProcessorCount := AProcessorCount;
  TotalUsage := ATotalUsage;
  ProcessUsage := AProcessUsage;
  ThreadUsage := AThreadUsage;
  KernelTime := AKernelTime;
  UserTime := AUserTime;
  IdleTime := AIdleTime;
end;

{ TCPUUsageRecord }

constructor TCPUUsageRecord.Create(const AUsageInfo: TCPUUsageInfo);
begin
  Timestamp := Now;
  UsageInfo := AUsageInfo;
end;

{ TEncodingCPUMonitor }

constructor TEncodingCPUMonitor.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := ALogCallback;
  FRecords := TList<TCPUUsageRecord>.Create;
  FMonitorTimer := TTimer.Create(nil);
  FMonitorTimer.Enabled := False;
  FMonitorTimer.OnTimer := OnMonitorTimer;
  FMonitorInterval := 1000;
  FIsMonitoring := False;

  // 初始化时间信息
  FLastProcessorTime := 0;
  FLastProcessTime := 0;
  FLastThreadTime := 0;
  FLastKernelTime := 0;
  FLastUserTime := 0;
  FLastIdleTime := 0;
end;

destructor TEncodingCPUMonitor.Destroy;
begin
  StopMonitoring;
  FMonitorTimer.Free;
  FRecords.Free;
  inherited;
end;

procedure TEncodingCPUMonitor.ClearRecords;
begin
  FRecords.Clear;
  Log('清除CPU使用率记录');
end;

function TEncodingCPUMonitor.GenerateReport: string;
var
  SB: TStringBuilder;
  Record: TCPUUsageRecord;
  MaxTotalUsage, MinTotalUsage, AvgTotalUsage: Double;
  MaxProcessUsage, MinProcessUsage, AvgProcessUsage: Double;
  MaxThreadUsage, MinThreadUsage, AvgThreadUsage: Double;
  TotalTotalUsage, TotalProcessUsage, TotalThreadUsage: Double;
  I: Integer;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('# CPU利用率监控报告');
    SB.AppendLine('');
    SB.AppendLine('生成时间: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    SB.AppendLine('');

    // 总体统计
    SB.AppendLine('## 1. 总体统计');
    SB.AppendLine('');
    SB.AppendLine(Format('- 记录数: %d', [FRecords.Count]));
    SB.AppendLine(Format('- 监控间隔: %d 毫秒', [FMonitorInterval]));
    SB.AppendLine('');

    // 计算统计数据
    if FRecords.Count > 0 then
    begin
      MaxTotalUsage := 0;
      MinTotalUsage := 100;
      TotalTotalUsage := 0;

      MaxProcessUsage := 0;
      MinProcessUsage := 100;
      TotalProcessUsage := 0;

      MaxThreadUsage := 0;
      MinThreadUsage := 100;
      TotalThreadUsage := 0;

      for Record in FRecords do
      begin
        // 总体CPU使用率
        MaxTotalUsage := Max(MaxTotalUsage, Record.UsageInfo.TotalUsage);
        MinTotalUsage := Min(MinTotalUsage, Record.UsageInfo.TotalUsage);
        TotalTotalUsage := TotalTotalUsage + Record.UsageInfo.TotalUsage;

        // 进程CPU使用率
        MaxProcessUsage := Max(MaxProcessUsage, Record.UsageInfo.ProcessUsage);
        MinProcessUsage := Min(MinProcessUsage, Record.UsageInfo.ProcessUsage);
        TotalProcessUsage := TotalProcessUsage + Record.UsageInfo.ProcessUsage;

        // 线程CPU使用率
        MaxThreadUsage := Max(MaxThreadUsage, Record.UsageInfo.ThreadUsage);
        MinThreadUsage := Min(MinThreadUsage, Record.UsageInfo.ThreadUsage);
        TotalThreadUsage := TotalThreadUsage + Record.UsageInfo.ThreadUsage;
      end;

      AvgTotalUsage := TotalTotalUsage / FRecords.Count;
      AvgProcessUsage := TotalProcessUsage / FRecords.Count;
      AvgThreadUsage := TotalThreadUsage / FRecords.Count;

      // CPU使用率统计
      SB.AppendLine('## 2. CPU使用率统计');
      SB.AppendLine('');
      SB.AppendLine('### 2.1 总体CPU使用率');
      SB.AppendLine('');
      SB.AppendLine(Format('- 最大值: %.2f%%', [MaxTotalUsage]));
      SB.AppendLine(Format('- 最小值: %.2f%%', [MinTotalUsage]));
      SB.AppendLine(Format('- 平均值: %.2f%%', [AvgTotalUsage]));
      SB.AppendLine('');

      SB.AppendLine('### 2.2 进程CPU使用率');
      SB.AppendLine('');
      SB.AppendLine(Format('- 最大值: %.2f%%', [MaxProcessUsage]));
      SB.AppendLine(Format('- 最小值: %.2f%%', [MinProcessUsage]));
      SB.AppendLine(Format('- 平均值: %.2f%%', [AvgProcessUsage]));
      SB.AppendLine('');

      SB.AppendLine('### 2.3 线程CPU使用率');
      SB.AppendLine('');
      SB.AppendLine(Format('- 最大值: %.2f%%', [MaxThreadUsage]));
      SB.AppendLine(Format('- 最小值: %.2f%%', [MinThreadUsage]));
      SB.AppendLine(Format('- 平均值: %.2f%%', [AvgThreadUsage]));
      SB.AppendLine('');

      // 详细记录
      SB.AppendLine('## 3. 详细记录');
      SB.AppendLine('');
      SB.AppendLine('| 时间 | 总体CPU使用率 | 进程CPU使用率 | 线程CPU使用率 | 处理器数量 |');
      SB.AppendLine('|------|--------------|--------------|--------------|------------|');

      for I := 0 to Min(99, FRecords.Count - 1) do
      begin
        Record := FRecords[I];

        SB.AppendLine(Format('| %s | %.2f%% | %.2f%% | %.2f%% | %d |',
          [FormatDateTime('hh:nn:ss.zzz', Record.Timestamp),
           Record.UsageInfo.TotalUsage,
           Record.UsageInfo.ProcessUsage,
           Record.UsageInfo.ThreadUsage,
           Record.UsageInfo.ProcessorCount]));
      end;

      // 如果记录太多，显示省略信息
      if FRecords.Count > 100 then
        SB.AppendLine(Format('| ... | ... | ... | ... | ... | 还有 %d 条记录未显示 |', [FRecords.Count - 100]));

      SB.AppendLine('');

      // CPU使用率建议
      SB.AppendLine('## 4. CPU使用率建议');
      SB.AppendLine('');

      // 根据CPU使用率给出建议
      if AvgProcessUsage > 80 then
      begin
        SB.AppendLine('- 进程CPU使用率较高，建议检查是否存在CPU密集型操作或死循环。');
        SB.AppendLine('- 考虑优化算法或使用并行处理来减轻CPU负担。');
      end
      else if AvgProcessUsage > 50 then
      begin
        SB.AppendLine('- 进程CPU使用率适中，但仍有优化空间。');
        SB.AppendLine('- 考虑使用异步处理或后台线程处理CPU密集型任务。');
      end
      else
      begin
        SB.AppendLine('- 进程CPU使用率良好，继续保持。');
      end;

      SB.AppendLine('');
      SB.AppendLine('- 避免在主线程中执行CPU密集型操作，以免影响UI响应。');
      SB.AppendLine('- 考虑使用线程池管理并发任务，避免创建过多线程。');
      SB.AppendLine('- 对于大文件处理，考虑分块处理以减轻CPU负担。');
    end
    else
    begin
      SB.AppendLine('没有CPU使用率记录。');
    end;

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TEncodingCPUMonitor.GetCPUUsage: TCPUUsageInfo;
begin
  Result := GetCurrentCPUUsage;

  Log(Format('获取CPU使用率信息: 总体=%.2f%%, 进程=%.2f%%, 线程=%.2f%%',
    [Result.TotalUsage, Result.ProcessUsage, Result.ThreadUsage]));
end;

function TEncodingCPUMonitor.GetCPUUsageRecords: TArray<TCPUUsageRecord>;
begin
  Result := FRecords.ToArray;
end;

function TEncodingCPUMonitor.GetCurrentCPUUsage: TCPUUsageInfo;
var
  ProcessorCount: Integer;
  CurrentProcessorTime, DeltaProcessorTime: UInt64;
  CurrentProcessTime, DeltaProcessTime: UInt64;
  CurrentThreadTime, DeltaThreadTime: UInt64;
  CurrentKernelTime, CurrentUserTime, CurrentIdleTime: UInt64;
  DeltaKernelTime, DeltaUserTime, DeltaIdleTime: UInt64;
  TotalUsage, ProcessUsage, ThreadUsage: Double;
begin
  // 获取处理器数量
  ProcessorCount := System.CPUCount;

  // 获取当前时间信息
  CurrentProcessorTime := GetProcessorTime;
  CurrentProcessTime := GetProcessTime;
  CurrentThreadTime := GetThreadTime;
  GetSystemTimes(CurrentKernelTime, CurrentUserTime, CurrentIdleTime);

  // 计算时间差
  if (FLastProcessorTime > 0) and (FLastProcessTime > 0) and (FLastThreadTime > 0) and
     (FLastKernelTime > 0) and (FLastUserTime > 0) and (FLastIdleTime > 0) then
  begin
    DeltaProcessorTime := CurrentProcessorTime - FLastProcessorTime;
    DeltaProcessTime := CurrentProcessTime - FLastProcessTime;
    DeltaThreadTime := CurrentThreadTime - FLastThreadTime;
    DeltaKernelTime := CurrentKernelTime - FLastKernelTime;
    DeltaUserTime := CurrentUserTime - FLastUserTime;
    DeltaIdleTime := CurrentIdleTime - FLastIdleTime;

    // 计算CPU使用率
    if DeltaProcessorTime > 0 then
    begin
      // 总体CPU使用率
      TotalUsage := 100.0 - (DeltaIdleTime * 100.0 / (DeltaKernelTime + DeltaUserTime));

      // 进程CPU使用率
      ProcessUsage := DeltaProcessTime * 100.0 / DeltaProcessorTime / ProcessorCount;

      // 线程CPU使用率
      ThreadUsage := DeltaThreadTime * 100.0 / DeltaProcessorTime / ProcessorCount;
    end
    else
    begin
      TotalUsage := 0;
      ProcessUsage := 0;
      ThreadUsage := 0;
    end;
  end
  else
  begin
    TotalUsage := 0;
    ProcessUsage := 0;
    ThreadUsage := 0;
  end;

  // 更新上一次时间信息
  FLastProcessorTime := CurrentProcessorTime;
  FLastProcessTime := CurrentProcessTime;
  FLastThreadTime := CurrentThreadTime;
  FLastKernelTime := CurrentKernelTime;
  FLastUserTime := CurrentUserTime;
  FLastIdleTime := CurrentIdleTime;

  // 创建CPU使用率信息
  Result := TCPUUsageInfo.Create(
    ProcessorCount, TotalUsage, ProcessUsage, ThreadUsage,
    CurrentKernelTime, CurrentUserTime, CurrentIdleTime);
end;

function TEncodingCPUMonitor.GetProcessorTime: UInt64;
var
  SystemInfo: TSystemInfo;
  ProcessorCount: Integer;
begin
  // 获取处理器数量
  GetSystemInfo(SystemInfo);
  ProcessorCount := SystemInfo.dwNumberOfProcessors;

  // 返回处理器时间（处理器数量 * 100纳秒）
  Result := GetTickCount64 * 10000 * ProcessorCount;
end;

function TEncodingCPUMonitor.GetProcessTime: UInt64;
var
  CreationTime, ExitTime, KernelTime, UserTime: TFileTime;
begin
  // 获取进程时间
  if GetProcessTimes(GetCurrentProcess, CreationTime, ExitTime, KernelTime, UserTime) then
  begin
    // 合并内核时间和用户时间
    Result := UInt64(KernelTime.dwLowDateTime) or (UInt64(KernelTime.dwHighDateTime) shl 32) +
              UInt64(UserTime.dwLowDateTime) or (UInt64(UserTime.dwHighDateTime) shl 32);
  end
  else
    Result := 0;
end;

function TEncodingCPUMonitor.GetSystemTimes(out KernelTime, UserTime, IdleTime: UInt64): Boolean;
var
  KernelFT, UserFT, IdleFT: TFileTime;
begin
  // 获取系统时间
  Result := Winapi.Windows.GetSystemTimes(IdleFT, KernelFT, UserFT);

  if Result then
  begin
    // 转换为UInt64
    IdleTime := UInt64(IdleFT.dwLowDateTime) or (UInt64(IdleFT.dwHighDateTime) shl 32);
    KernelTime := UInt64(KernelFT.dwLowDateTime) or (UInt64(KernelFT.dwHighDateTime) shl 32);
    UserTime := UInt64(UserFT.dwLowDateTime) or (UInt64(UserFT.dwHighDateTime) shl 32);
  end
  else
  begin
    IdleTime := 0;
    KernelTime := 0;
    UserTime := 0;
  end;
end;

function TEncodingCPUMonitor.GetThreadTime: UInt64;
var
  CreationTime, ExitTime, KernelTime, UserTime: TFileTime;
begin
  // 获取线程时间
  if GetThreadTimes(GetCurrentThread, CreationTime, ExitTime, KernelTime, UserTime) then
  begin
    // 合并内核时间和用户时间
    Result := UInt64(KernelTime.dwLowDateTime) or (UInt64(KernelTime.dwHighDateTime) shl 32) +
              UInt64(UserTime.dwLowDateTime) or (UInt64(UserTime.dwHighDateTime) shl 32);
  end
  else
    Result := 0;
end;

procedure TEncodingCPUMonitor.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

procedure TEncodingCPUMonitor.OnMonitorTimer(Sender: TObject);
var
  UsageInfo: TCPUUsageInfo;
  Record: TCPUUsageRecord;
begin
  // 获取当前CPU使用率信息
  UsageInfo := GetCurrentCPUUsage;

  // 创建记录
  Record := TCPUUsageRecord.Create(UsageInfo);

  // 添加到记录列表
  FRecords.Add(Record);

  Log(Format('记录CPU使用率: 总体=%.2f%%, 进程=%.2f%%, 线程=%.2f%%',
    [UsageInfo.TotalUsage, UsageInfo.ProcessUsage, UsageInfo.ThreadUsage]));
end;

procedure TEncodingCPUMonitor.SaveReportToFile(const FilePath: string);
var
  Report: string;
begin
  Report := GenerateReport;
  TFile.WriteAllText(FilePath, Report);

  Log(Format('保存CPU使用率报告到文件: %s', [FilePath]));
end;

procedure TEncodingCPUMonitor.StartMonitoring(Interval: Integer);
begin
  if FIsMonitoring then
    Exit;

  // 设置监控间隔
  FMonitorInterval := Interval;
  FMonitorTimer.Interval := Interval;

  // 清除现有记录
  ClearRecords;

  // 初始化时间信息
  GetCurrentCPUUsage;

  // 启动定时器
  FMonitorTimer.Enabled := True;
  FIsMonitoring := True;

  Log(Format('开始监控CPU利用率: 间隔=%d毫秒', [Interval]));
end;

procedure TEncodingCPUMonitor.StopMonitoring;
begin
  if not FIsMonitoring then
    Exit;

  // 停止定时器
  FMonitorTimer.Enabled := False;
  FIsMonitoring := False;

  Log('停止监控CPU利用率');
end;