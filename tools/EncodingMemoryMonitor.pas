unit EncodingMemoryMonitor;

{
  EncodingMemoryMonitor.pas
  实现内存占用监控功能
  
  作为improve.md中任务2.3.2的实现
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Diagnostics;

type
  /// <summary>
  /// 内存使用信息
  /// </summary>
  TMemoryUsageInfo = record
    TotalPhysical: UInt64;       // 总物理内存（字节）
    AvailablePhysical: UInt64;   // 可用物理内存（字节）
    TotalVirtual: UInt64;        // 总虚拟内存（字节）
    AvailableVirtual: UInt64;    // 可用虚拟内存（字节）
    ProcessMemory: UInt64;       // 进程内存使用（字节）
    HeapAllocated: UInt64;       // 堆内存分配（字节）
    HeapCommitted: UInt64;       // 堆内存提交（字节）
    
    constructor Create(ATotalPhysical, AAvailablePhysical, ATotalVirtual, AAvailableVirtual, 
      AProcessMemory, AHeapAllocated, AHeapCommitted: UInt64);
  end;
  
  /// <summary>
  /// 内存使用记录
  /// </summary>
  TMemoryUsageRecord = record
    Timestamp: TDateTime;        // 时间戳
    UsageInfo: TMemoryUsageInfo; // 内存使用信息
    
    constructor Create(const AUsageInfo: TMemoryUsageInfo);
  end;
  
  /// <summary>
  /// 内存占用监控器
  /// </summary>
  TEncodingMemoryMonitor = class
  private
    FLogCallback: TProc<string>;
    FRecords: TList<TMemoryUsageRecord>;
    FMonitorTimer: TTimer;
    FMonitorInterval: Integer;
    FIsMonitoring: Boolean;
    
    procedure Log(const Msg: string);
    procedure OnMonitorTimer(Sender: TObject);
    function GetCurrentMemoryUsage: TMemoryUsageInfo;
  public
    constructor Create(ALogCallback: TProc<string> = nil);
    destructor Destroy; override;
    
    /// <summary>
    /// 开始监控内存占用
    /// </summary>
    procedure StartMonitoring(Interval: Integer = 1000);
    
    /// <summary>
    /// 停止监控内存占用
    /// </summary>
    procedure StopMonitoring;
    
    /// <summary>
    /// 获取当前内存使用信息
    /// </summary>
    function GetMemoryUsage: TMemoryUsageInfo;
    
    /// <summary>
    /// 获取内存使用记录
    /// </summary>
    function GetMemoryUsageRecords: TArray<TMemoryUsageRecord>;
    
    /// <summary>
    /// 清除内存使用记录
    /// </summary>
    procedure ClearRecords;
    
    /// <summary>
    /// 生成内存使用报告
    /// </summary>
    function GenerateReport: string;
    
    /// <summary>
    /// 保存内存使用报告到文件
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
  Winapi.Windows, System.Math, System.IOUtils;

{ TMemoryUsageInfo }

constructor TMemoryUsageInfo.Create(ATotalPhysical, AAvailablePhysical, ATotalVirtual, AAvailableVirtual, 
  AProcessMemory, AHeapAllocated, AHeapCommitted: UInt64);
begin
  TotalPhysical := ATotalPhysical;
  AvailablePhysical := AAvailablePhysical;
  TotalVirtual := ATotalVirtual;
  AvailableVirtual := AAvailableVirtual;
  ProcessMemory := AProcessMemory;
  HeapAllocated := AHeapAllocated;
  HeapCommitted := AHeapCommitted;
end;

{ TMemoryUsageRecord }

constructor TMemoryUsageRecord.Create(const AUsageInfo: TMemoryUsageInfo);
begin
  Timestamp := Now;
  UsageInfo := AUsageInfo;
end;

{ TEncodingMemoryMonitor }

constructor TEncodingMemoryMonitor.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := ALogCallback;
  FRecords := TList<TMemoryUsageRecord>.Create;
  FMonitorTimer := TTimer.Create(nil);
  FMonitorTimer.Enabled := False;
  FMonitorTimer.OnTimer := OnMonitorTimer;
  FMonitorInterval := 1000;
  FIsMonitoring := False;
end;

destructor TEncodingMemoryMonitor.Destroy;
begin
  StopMonitoring;
  FMonitorTimer.Free;
  FRecords.Free;
  inherited;
end;

procedure TEncodingMemoryMonitor.ClearRecords;
begin
  FRecords.Clear;
  Log('清除内存使用记录');
end;

function TEncodingMemoryMonitor.GenerateReport: string;
var
  SB: TStringBuilder;
  Record: TMemoryUsageRecord;
  MaxProcessMemory, MinProcessMemory, AvgProcessMemory: UInt64;
  MaxHeapAllocated, MinHeapAllocated, AvgHeapAllocated: UInt64;
  TotalProcessMemory, TotalHeapAllocated: UInt64;
  I: Integer;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('# 内存占用监控报告');
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
      MaxProcessMemory := 0;
      MinProcessMemory := High(UInt64);
      TotalProcessMemory := 0;
      
      MaxHeapAllocated := 0;
      MinHeapAllocated := High(UInt64);
      TotalHeapAllocated := 0;
      
      for Record in FRecords do
      begin
        // 进程内存
        MaxProcessMemory := Max(MaxProcessMemory, Record.UsageInfo.ProcessMemory);
        MinProcessMemory := Min(MinProcessMemory, Record.UsageInfo.ProcessMemory);
        TotalProcessMemory := TotalProcessMemory + Record.UsageInfo.ProcessMemory;
        
        // 堆内存
        MaxHeapAllocated := Max(MaxHeapAllocated, Record.UsageInfo.HeapAllocated);
        MinHeapAllocated := Min(MinHeapAllocated, Record.UsageInfo.HeapAllocated);
        TotalHeapAllocated := TotalHeapAllocated + Record.UsageInfo.HeapAllocated;
      end;
      
      AvgProcessMemory := TotalProcessMemory div FRecords.Count;
      AvgHeapAllocated := TotalHeapAllocated div FRecords.Count;
      
      // 内存使用统计
      SB.AppendLine('## 2. 内存使用统计');
      SB.AppendLine('');
      SB.AppendLine('### 2.1 进程内存使用');
      SB.AppendLine('');
      SB.AppendLine(Format('- 最大值: %s', [TPath.GetFileSize(MaxProcessMemory)]));
      SB.AppendLine(Format('- 最小值: %s', [TPath.GetFileSize(MinProcessMemory)]));
      SB.AppendLine(Format('- 平均值: %s', [TPath.GetFileSize(AvgProcessMemory)]));
      SB.AppendLine('');
      
      SB.AppendLine('### 2.2 堆内存分配');
      SB.AppendLine('');
      SB.AppendLine(Format('- 最大值: %s', [TPath.GetFileSize(MaxHeapAllocated)]));
      SB.AppendLine(Format('- 最小值: %s', [TPath.GetFileSize(MinHeapAllocated)]));
      SB.AppendLine(Format('- 平均值: %s', [TPath.GetFileSize(AvgHeapAllocated)]));
      SB.AppendLine('');
      
      // 详细记录
      SB.AppendLine('## 3. 详细记录');
      SB.AppendLine('');
      SB.AppendLine('| 时间 | 进程内存 | 堆分配 | 堆提交 | 可用物理内存 | 可用虚拟内存 |');
      SB.AppendLine('|------|----------|--------|--------|--------------|--------------|');
      
      for I := 0 to Min(99, FRecords.Count - 1) do
      begin
        Record := FRecords[I];
        
        SB.AppendLine(Format('| %s | %s | %s | %s | %s | %s |', 
          [FormatDateTime('hh:nn:ss.zzz', Record.Timestamp), 
           TPath.GetFileSize(Record.UsageInfo.ProcessMemory), 
           TPath.GetFileSize(Record.UsageInfo.HeapAllocated), 
           TPath.GetFileSize(Record.UsageInfo.HeapCommitted), 
           TPath.GetFileSize(Record.UsageInfo.AvailablePhysical), 
           TPath.GetFileSize(Record.UsageInfo.AvailableVirtual)]));
      end;
      
      // 如果记录太多，显示省略信息
      if FRecords.Count > 100 then
        SB.AppendLine(Format('| ... | ... | ... | ... | ... | ... | 还有 %d 条记录未显示 |', [FRecords.Count - 100]));
      
      SB.AppendLine('');
      
      // 内存使用建议
      SB.AppendLine('## 4. 内存使用建议');
      SB.AppendLine('');
      
      // 根据内存使用情况给出建议
      if MaxHeapAllocated > 100 * 1024 * 1024 then
      begin
        SB.AppendLine('- 内存使用较高，建议检查是否存在内存泄漏或大对象未释放的情况。');
        SB.AppendLine('- 考虑使用流式处理或分块处理大文件，避免一次性加载整个文件到内存。');
      end
      else if MaxHeapAllocated > 50 * 1024 * 1024 then
      begin
        SB.AppendLine('- 内存使用适中，但仍有优化空间。');
        SB.AppendLine('- 考虑在处理大文件时使用流式处理或分块处理。');
      end
      else
      begin
        SB.AppendLine('- 内存使用良好，继续保持。');
      end;
      
      SB.AppendLine('');
      SB.AppendLine('- 定期调用 `FreeAndNil` 释放不再使用的对象。');
      SB.AppendLine('- 使用 `try...finally` 块确保资源正确释放。');
      SB.AppendLine('- 考虑使用内存池或对象池管理频繁创建和销毁的小对象。');
    end
    else
    begin
      SB.AppendLine('没有内存使用记录。');
    end;
    
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TEncodingMemoryMonitor.GetCurrentMemoryUsage: TMemoryUsageInfo;
var
  MemoryStatus: TMemoryStatusEx;
  ProcessMemoryCounters: TProcessMemoryCounters;
  HeapStatus: THeapStatus;
begin
  // 获取系统内存信息
  FillChar(MemoryStatus, SizeOf(MemoryStatus), 0);
  MemoryStatus.dwLength := SizeOf(MemoryStatus);
  GlobalMemoryStatusEx(MemoryStatus);
  
  // 获取进程内存信息
  FillChar(ProcessMemoryCounters, SizeOf(ProcessMemoryCounters), 0);
  ProcessMemoryCounters.cb := SizeOf(ProcessMemoryCounters);
  GetProcessMemoryInfo(GetCurrentProcess, @ProcessMemoryCounters, SizeOf(ProcessMemoryCounters));
  
  // 获取堆内存信息
  HeapStatus := GetHeapStatus;
  
  // 创建内存使用信息
  Result := TMemoryUsageInfo.Create(
    MemoryStatus.ullTotalPhys,
    MemoryStatus.ullAvailPhys,
    MemoryStatus.ullTotalVirtual,
    MemoryStatus.ullAvailVirtual,
    ProcessMemoryCounters.WorkingSetSize,
    HeapStatus.TotalAllocated,
    HeapStatus.TotalCommitted);
end;

function TEncodingMemoryMonitor.GetMemoryUsage: TMemoryUsageInfo;
begin
  Result := GetCurrentMemoryUsage;
  
  Log(Format('获取内存使用信息: 进程内存=%s, 堆分配=%s', 
    [TPath.GetFileSize(Result.ProcessMemory), TPath.GetFileSize(Result.HeapAllocated)]));
end;

function TEncodingMemoryMonitor.GetMemoryUsageRecords: TArray<TMemoryUsageRecord>;
begin
  Result := FRecords.ToArray;
end;

procedure TEncodingMemoryMonitor.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

procedure TEncodingMemoryMonitor.OnMonitorTimer(Sender: TObject);
var
  UsageInfo: TMemoryUsageInfo;
  Record: TMemoryUsageRecord;
begin
  // 获取当前内存使用信息
  UsageInfo := GetCurrentMemoryUsage;
  
  // 创建记录
  Record := TMemoryUsageRecord.Create(UsageInfo);
  
  // 添加到记录列表
  FRecords.Add(Record);
  
  Log(Format('记录内存使用: 进程内存=%s, 堆分配=%s', 
    [TPath.GetFileSize(UsageInfo.ProcessMemory), TPath.GetFileSize(UsageInfo.HeapAllocated)]));
end;

procedure TEncodingMemoryMonitor.SaveReportToFile(const FilePath: string);
var
  Report: string;
begin
  Report := GenerateReport;
  TFile.WriteAllText(FilePath, Report);
  
  Log(Format('保存内存使用报告到文件: %s', [FilePath]));
end;

procedure TEncodingMemoryMonitor.StartMonitoring(Interval: Integer);
begin
  if FIsMonitoring then
    Exit;
  
  // 设置监控间隔
  FMonitorInterval := Interval;
  FMonitorTimer.Interval := Interval;
  
  // 清除现有记录
  ClearRecords;
  
  // 启动定时器
  FMonitorTimer.Enabled := True;
  FIsMonitoring := True;
  
  Log(Format('开始监控内存占用: 间隔=%d毫秒', [Interval]));
end;

procedure TEncodingMemoryMonitor.StopMonitoring;
begin
  if not FIsMonitoring then
    Exit;
  
  // 停止定时器
  FMonitorTimer.Enabled := False;
  FIsMonitoring := False;
  
  Log('停止监控内存占用');
end;

end.
