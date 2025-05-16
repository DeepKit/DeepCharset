unit EncodingPerformanceBenchmark;

{
  EncodingPerformanceBenchmark.pas
  创建性能基准报告格式

  作为improve.md中任务2.3.5的实现
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Math,
  EncodingPerformanceTester, EncodingMemoryMonitor, EncodingTimeMeasurer, EncodingCPUMonitor;

type
  /// <summary>
  /// 性能基准测试结果
  /// </summary>
  TPerformanceBenchmarkResult = record
    TestName: string;                // 测试名称
    TestDescription: string;         // 测试描述
    TestDate: TDateTime;             // 测试日期
    TestDuration: Int64;             // 测试持续时间（毫秒）

    // 性能测试结果
    PerformanceResults: TArray<TPerformanceTestResult>;

    // 内存监控结果
    MemoryRecords: TArray<TMemoryUsageRecord>;

    // 时间测量结果
    TimeRecords: TArray<TTimeMeasureRecord>;

    // CPU监控结果
    CPURecords: TArray<TCPUUsageRecord>;

    constructor Create(const ATestName, ATestDescription: string; ATestDate: TDateTime;
      ATestDuration: Int64; const APerformanceResults: TArray<TPerformanceTestResult>;
      const AMemoryRecords: TArray<TMemoryUsageRecord>; const ATimeRecords: TArray<TTimeMeasureRecord>;
      const ACPURecords: TArray<TCPUUsageRecord>);
  end;

  /// <summary>
  /// 报告格式类型
  /// </summary>
  TBenchmarkReportFormat = (brfMarkdown, brfHTML, brfJSON);

  /// <summary>
  /// 报告内容选项
  /// </summary>
  TBenchmarkReportOptions = record
    IncludePerformanceResults: Boolean;  // 包含性能测试结果
    IncludeMemoryUsage: Boolean;         // 包含内存使用情况
    IncludeTimeAnalysis: Boolean;        // 包含时间分析
    IncludeCPUUsage: Boolean;            // 包含CPU使用率
    IncludeCharts: Boolean;              // 包含图表（仅HTML格式）
    IncludeRecommendations: Boolean;     // 包含优化建议

    constructor Create(AIncludeAll: Boolean);
  end;

  /// <summary>
  /// 性能基准报告生成器
  /// </summary>
  TEncodingPerformanceBenchmark = class
  private
    FLogCallback: TProc<string>;
    FResults: TList<TPerformanceBenchmarkResult>;

    procedure Log(const Msg: string);
    function GenerateMarkdownReport(const Result: TPerformanceBenchmarkResult;
      const Options: TBenchmarkReportOptions): string;
    function GenerateHTMLReport(const Result: TPerformanceBenchmarkResult;
      const Options: TBenchmarkReportOptions): string;
    function GenerateJSONReport(const Result: TPerformanceBenchmarkResult;
      const Options: TBenchmarkReportOptions): string;
    function GenerateChartScript(const Result: TPerformanceBenchmarkResult): string;
    function GenerateRecommendations(const Result: TPerformanceBenchmarkResult): string;
  var
    SB: TStringBuilder;
    PerformanceData: TDictionary<string, TList<TPerformanceTestResult>>;
    MemoryData: TList<TMemoryUsageRecord>;
    CPUData: TList<TCPUUsageRecord>;
    TimeData: TDictionary<TTimeMeasureType, TList<TTimeMeasureRecord>>;
    Operation: string;
    ResultsList: TList<TPerformanceTestResult>;
    MeasureType: TTimeMeasureType;
    TimeList: TList<TTimeMeasureRecord>;
    SlowestOperation: string;
    MaxAvgTime: Double;
    HighestMemoryOperation: string;
    MaxAvgMemory: Int64;
    HighCPUUsage: Boolean;
    LargeMemoryUsage: Boolean;
    LongFileIOTime: Boolean;
  begin
    SB := TStringBuilder.Create;
    PerformanceData := TDictionary<string, TList<TPerformanceTestResult>>.Create;
    MemoryData := TList<TMemoryUsageRecord>.Create;
    CPUData := TList<TCPUUsageRecord>.Create;
    TimeData := TDictionary<TTimeMeasureType, TList<TTimeMeasureRecord>>.Create;

    try
      // 初始化时间测量类型字典
      for MeasureType := Low(TTimeMeasureType) to High(TTimeMeasureType) do
        TimeData.Add(MeasureType, TList<TTimeMeasureRecord>.Create);

      // 按操作分组性能测试结果
      for var PerfResult in Result.PerformanceResults do
      begin
        if not PerformanceData.TryGetValue(PerfResult.OperationName, ResultsList) then
        begin
          ResultsList := TList<TPerformanceTestResult>.Create;
          PerformanceData.Add(PerfResult.OperationName, ResultsList);
        end;

        ResultsList.Add(PerfResult);
      end;

      // 添加内存记录
      for var MemRecord in Result.MemoryRecords do
        MemoryData.Add(MemRecord);

      // 添加CPU记录
      for var CPURecord in Result.CPURecords do
        CPUData.Add(CPURecord);

      // 按类型分组时间测量记录
      for var TimeRecord in Result.TimeRecords do
        TimeData[TimeRecord.MeasureType].Add(TimeRecord);

      // 查找最慢的操作
      SlowestOperation := '';
      MaxAvgTime := 0;

      for Operation in PerformanceData.Keys do
      begin
        ResultsList := PerformanceData[Operation];

        var TotalTime := 0;
        for var PerfResult in ResultsList do
          TotalTime := TotalTime + PerfResult.ExecutionTime;

        var AvgTime := TotalTime / ResultsList.Count;

        if AvgTime > MaxAvgTime then
        begin
          MaxAvgTime := AvgTime;
          SlowestOperation := Operation;
        end;
      end;

      // 查找内存使用最多的操作
      HighestMemoryOperation := '';
      MaxAvgMemory := 0;

      for Operation in PerformanceData.Keys do
      begin
        ResultsList := PerformanceData[Operation];

        var TotalMemory := 0;
        for var PerfResult in ResultsList do
          TotalMemory := TotalMemory + PerfResult.MemoryUsage;

        var AvgMemory := TotalMemory div ResultsList.Count;

        if AvgMemory > MaxAvgMemory then
        begin
          MaxAvgMemory := AvgMemory;
          HighestMemoryOperation := Operation;
        end;
      end;

      // 检查CPU使用率
      HighCPUUsage := False;
      if CPUData.Count > 0 then
      begin
        var TotalProcessUsage := 0.0;
        for var CPURecord in CPUData do
          TotalProcessUsage := TotalProcessUsage + CPURecord.UsageInfo.ProcessUsage;

        var AvgProcessUsage := TotalProcessUsage / CPUData.Count;

        HighCPUUsage := AvgProcessUsage > 50;
      end;

      // 检查内存使用
      LargeMemoryUsage := False;
      if MemoryData.Count > 0 then
      begin
        var MaxProcessMemory := 0;
        for var MemRecord in MemoryData do
          MaxProcessMemory := Max(MaxProcessMemory, MemRecord.UsageInfo.ProcessMemory);

        LargeMemoryUsage := MaxProcessMemory > 100 * 1024 * 1024; // 100MB
      end;

      // 检查文件IO时间
      LongFileIOTime := False;
      TimeList := TimeData[tmtFileIO];
      if TimeList.Count > 0 then
      begin
        var TotalTime := 0;
        for var TimeRecord in TimeList do
          TotalTime := TotalTime + TimeRecord.ElapsedMilliseconds;

        var AvgTime := TotalTime / TimeList.Count;

        LongFileIOTime := AvgTime > 100; // 100ms
      end;

      // 生成建议
      SB.AppendLine('### 5.1 性能瓶颈');
      SB.AppendLine('');

      if SlowestOperation <> '' then
        SB.AppendLine(Format('- 最慢的操作是 "%s"，平均执行时间为 %.2f 毫秒。', [SlowestOperation, MaxAvgTime]));

      if HighestMemoryOperation <> '' then
        SB.AppendLine(Format('- 内存使用最多的操作是 "%s"，平均内存使用为 %s。',
          [HighestMemoryOperation, TPath.GetFileSize(MaxAvgMemory)]));

      if HighCPUUsage then
        SB.AppendLine('- CPU使用率较高，可能存在CPU密集型操作。');

      if LargeMemoryUsage then
        SB.AppendLine('- 内存使用较大，可能存在内存泄漏或大对象未释放的情况。');

      if LongFileIOTime then
        SB.AppendLine('- 文件IO操作耗时较长，可能影响整体性能。');

      SB.AppendLine('');

      SB.AppendLine('### 5.2 优化建议');
      SB.AppendLine('');

      // 根据性能瓶颈给出建议
      if SlowestOperation <> '' then
      begin
        SB.AppendLine(Format('#### 优化 "%s" 操作', [SlowestOperation]));
        SB.AppendLine('');
        SB.AppendLine('- 使用性能分析工具（如AQTime）定位具体的性能瓶颈。');
        SB.AppendLine('- 考虑使用缓存机制减少重复计算。');
        SB.AppendLine('- 检查是否存在不必要的循环或递归。');
        SB.AppendLine('- 考虑使用并行处理提高性能。');
        SB.AppendLine('');
      end;

      if HighestMemoryOperation <> '' then
      begin
        SB.AppendLine(Format('#### 优化 "%s" 的内存使用', [HighestMemoryOperation]));
        SB.AppendLine('');
        SB.AppendLine('- 使用内存分析工具（如FastMM）检查内存泄漏。');
        SB.AppendLine('- 及时释放不再使用的对象和资源。');
        SB.AppendLine('- 考虑使用流式处理或分块处理大文件。');
        SB.AppendLine('- 优化数据结构，减少内存占用。');
        SB.AppendLine('');
      end;

      if HighCPUUsage then
      begin
        SB.AppendLine('#### 优化CPU使用');
        SB.AppendLine('');
        SB.AppendLine('- 使用异步处理或后台线程处理CPU密集型任务。');
        SB.AppendLine('- 避免在主线程中执行耗时操作。');
        SB.AppendLine('- 考虑使用线程池管理并发任务。');
        SB.AppendLine('- 优化算法复杂度，减少CPU负担。');
        SB.AppendLine('');
      end;

      if LongFileIOTime then
      begin
        SB.AppendLine('#### 优化文件IO');
        SB.AppendLine('');
        SB.AppendLine('- 使用缓冲读写提高IO性能。');
        SB.AppendLine('- 减少文件打开/关闭次数。');
        SB.AppendLine('- 考虑使用内存映射文件处理大文件。');
        SB.AppendLine('- 使用异步IO操作避免阻塞。');
        SB.AppendLine('');
      end;

      SB.AppendLine('### 5.3 通用优化建议');
      SB.AppendLine('');
      SB.AppendLine('- 定期调用 `FreeAndNil` 释放不再使用的对象。');
      SB.AppendLine('- 使用 `try...finally` 块确保资源正确释放。');
      SB.AppendLine('- 考虑使用内存池或对象池管理频繁创建和销毁的小对象。');
      SB.AppendLine('- 对于大文件处理，使用流式处理或分块处理，避免一次性加载整个文件到内存。');
      SB.AppendLine('- 使用异步处理或多线程处理提高并发性能。');
      SB.AppendLine('- 优化数据结构和算法，减少时间和空间复杂度。');

      Result := SB.ToString;
    finally
      // 清理资源
      for ResultsList in PerformanceData.Values do
        ResultsList.Free;

      PerformanceData.Free;
      MemoryData.Free;
      CPUData.Free;

      for TimeList in TimeData.Values do
        TimeList.Free;

      TimeData.Free;
      SB.Free;
    end;
  end;
  public
    constructor Create(ALogCallback: TProc<string> = nil);
    destructor Destroy; override;

    /// <summary>
    /// 添加基准测试结果
    /// </summary>
    procedure AddResult(const Result: TPerformanceBenchmarkResult);

    /// <summary>
    /// 获取基准测试结果
    /// </summary>
    function GetResults: TArray<TPerformanceBenchmarkResult>;

    /// <summary>
    /// 清除基准测试结果
    /// </summary>
    procedure ClearResults;

    /// <summary>
    /// 生成基准测试报告
    /// </summary>
    function GenerateReport(const Result: TPerformanceBenchmarkResult;
      Format: TBenchmarkReportFormat; const Options: TBenchmarkReportOptions): string;

    /// <summary>
    /// 保存基准测试报告到文件
    /// </summary>
    procedure SaveReportToFile(const FilePath: string; const Result: TPerformanceBenchmarkResult;
      Format: TBenchmarkReportFormat; const Options: TBenchmarkReportOptions);

    /// <summary>
    /// 日志回调
    /// </summary>
    property LogCallback: TProc<string> read FLogCallback write FLogCallback;
  end;

implementation

uses
  System.IOUtils, System.JSON, System.DateUtils;

{ TPerformanceBenchmarkResult }

constructor TPerformanceBenchmarkResult.Create(const ATestName, ATestDescription: string; ATestDate: TDateTime;
  ATestDuration: Int64; const APerformanceResults: TArray<TPerformanceTestResult>;
  const AMemoryRecords: TArray<TMemoryUsageRecord>; const ATimeRecords: TArray<TTimeMeasureRecord>;
  const ACPURecords: TArray<TCPUUsageRecord>);
begin
  TestName := ATestName;
  TestDescription := ATestDescription;
  TestDate := ATestDate;
  TestDuration := ATestDuration;
  PerformanceResults := APerformanceResults;
  MemoryRecords := AMemoryRecords;
  TimeRecords := ATimeRecords;
  CPURecords := ACPURecords;
end;

{ TBenchmarkReportOptions }

constructor TBenchmarkReportOptions.Create(AIncludeAll: Boolean);
begin
  IncludePerformanceResults := AIncludeAll;
  IncludeMemoryUsage := AIncludeAll;
  IncludeTimeAnalysis := AIncludeAll;
  IncludeCPUUsage := AIncludeAll;
  IncludeCharts := AIncludeAll;
  IncludeRecommendations := AIncludeAll;
end;

{ TEncodingPerformanceBenchmark }

constructor TEncodingPerformanceBenchmark.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := ALogCallback;
  FResults := TList<TPerformanceBenchmarkResult>.Create;
end;

destructor TEncodingPerformanceBenchmark.Destroy;
begin
  FResults.Free;
  inherited;
end;

procedure TEncodingPerformanceBenchmark.AddResult(const Result: TPerformanceBenchmarkResult);
begin
  FResults.Add(Result);

  Log(Format('添加基准测试结果: %s, 测试日期=%s, 测试持续时间=%d毫秒',
    [Result.TestName, FormatDateTime('yyyy-mm-dd hh:nn:ss', Result.TestDate), Result.TestDuration]));
end;

procedure TEncodingPerformanceBenchmark.ClearResults;
begin
  FResults.Clear;
  Log('清除基准测试结果');
end;

function TEncodingPerformanceBenchmark.GenerateMarkdownReport(const Result: TPerformanceBenchmarkResult;
  const Options: TBenchmarkReportOptions): string;
var
  SB: TStringBuilder;
  PerformanceData: TDictionary<string, TList<TPerformanceTestResult>>;
  MemoryData: TList<TMemoryUsageRecord>;
  CPUData: TList<TCPUUsageRecord>;
  TimeData: TDictionary<TTimeMeasureType, TList<TTimeMeasureRecord>>;
  Operation: string;
  ResultsList: TList<TPerformanceTestResult>;
  MeasureType: TTimeMeasureType;
  TimeList: TList<TTimeMeasureRecord>;
  I: Integer;
begin
  SB := TStringBuilder.Create;
  PerformanceData := TDictionary<string, TList<TPerformanceTestResult>>.Create;
  MemoryData := TList<TMemoryUsageRecord>.Create;
  CPUData := TList<TCPUUsageRecord>.Create;
  TimeData := TDictionary<TTimeMeasureType, TList<TTimeMeasureRecord>>.Create;

  try
    SB.AppendLine('# 编码性能基准测试报告');
    SB.AppendLine('');
    SB.AppendLine(Format('- 测试名称: %s', [Result.TestName]));
    SB.AppendLine(Format('- 测试描述: %s', [Result.TestDescription]));
    SB.AppendLine(Format('- 测试日期: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Result.TestDate)]));
    SB.AppendLine(Format('- 测试持续时间: %d 毫秒', [Result.TestDuration]));
    SB.AppendLine('');

    // 初始化时间测量类型字典
    for MeasureType := Low(TTimeMeasureType) to High(TTimeMeasureType) do
      TimeData.Add(MeasureType, TList<TTimeMeasureRecord>.Create);

    // 按操作分组性能测试结果
    for var PerfResult in Result.PerformanceResults do
    begin
      if not PerformanceData.TryGetValue(PerfResult.OperationName, ResultsList) then
      begin
        ResultsList := TList<TPerformanceTestResult>.Create;
        PerformanceData.Add(PerfResult.OperationName, ResultsList);
      end;

      ResultsList.Add(PerfResult);
    end;

    // 添加内存记录
    for var MemRecord in Result.MemoryRecords do
      MemoryData.Add(MemRecord);

    // 添加CPU记录
    for var CPURecord in Result.CPURecords do
      CPUData.Add(CPURecord);

    // 按类型分组时间测量记录
    for var TimeRecord in Result.TimeRecords do
      TimeData[TimeRecord.MeasureType].Add(TimeRecord);

    // 性能测试结果
    if Options.IncludePerformanceResults and (PerformanceData.Count > 0) then
    begin
      SB.AppendLine('## 1. 性能测试结果');
      SB.AppendLine('');

      I := 1;
      for Operation in PerformanceData.Keys do
      begin
        ResultsList := PerformanceData[Operation];

        SB.AppendLine(Format('### 1.%d %s', [I, Operation]));
        SB.AppendLine('');

        // 计算统计数据
        var TotalTime := 0;
        var TotalMemory := 0;
        var MinTime := High(Integer);
        var MaxTime := 0;

        for var PerfResult in ResultsList do
        begin
          TotalTime := TotalTime + PerfResult.ExecutionTime;
          TotalMemory := TotalMemory + PerfResult.MemoryUsage;
          MinTime := Min(MinTime, PerfResult.ExecutionTime);
          MaxTime := Max(MaxTime, PerfResult.ExecutionTime);
        end;

        var AvgTime := TotalTime / ResultsList.Count;
        var AvgMemory := TotalMemory / ResultsList.Count;

        SB.AppendLine(Format('- 测试次数: %d', [ResultsList.Count]));
        SB.AppendLine(Format('- 平均执行时间: %.2f 毫秒', [AvgTime]));
        SB.AppendLine(Format('- 最小执行时间: %d 毫秒', [MinTime]));
        SB.AppendLine(Format('- 最大执行时间: %d 毫秒', [MaxTime]));
        SB.AppendLine(Format('- 平均内存使用: %s', [TPath.GetFileSize(Round(AvgMemory))]));
        SB.AppendLine('');

        // 详细结果表格
        SB.AppendLine('| 文件大小 | 文件大小类别 | 执行时间(毫秒) | 内存使用 | CPU使用率(%) |');
        SB.AppendLine('|----------|--------------|----------------|----------|--------------|');

        for var PerfResult in ResultsList do
        begin
          SB.AppendLine(Format('| %s | %s | %d | %s | %.2f |',
            [TPath.GetFileSize(PerfResult.FileSize),
             GetEnumName(TypeInfo(TFileSizeCategory), Ord(PerfResult.FileSizeCategory)),
             PerfResult.ExecutionTime,
             TPath.GetFileSize(PerfResult.MemoryUsage),
             PerfResult.CPUUsage]));
        end;

        SB.AppendLine('');
        Inc(I);
      end;
    end;

    // 内存使用情况
    if Options.IncludeMemoryUsage and (MemoryData.Count > 0) then
    begin
      SB.AppendLine('## 2. 内存使用情况');
      SB.AppendLine('');

      // 计算统计数据
      var MaxProcessMemory := 0;
      var MinProcessMemory := High(UInt64);
      var TotalProcessMemory := 0;
      var MaxHeapMemory := 0;
      var MinHeapMemory := High(UInt64);
      var TotalHeapMemory := 0;

      for var MemRecord in MemoryData do
      begin
        MaxProcessMemory := Max(MaxProcessMemory, MemRecord.UsageInfo.ProcessMemory);
        MinProcessMemory := Min(MinProcessMemory, MemRecord.UsageInfo.ProcessMemory);
        TotalProcessMemory := TotalProcessMemory + MemRecord.UsageInfo.ProcessMemory;

        MaxHeapMemory := Max(MaxHeapMemory, MemRecord.UsageInfo.HeapAllocated);
        MinHeapMemory := Min(MinHeapMemory, MemRecord.UsageInfo.HeapAllocated);
        TotalHeapMemory := TotalHeapMemory + MemRecord.UsageInfo.HeapAllocated;
      end;

      var AvgProcessMemory := TotalProcessMemory div MemoryData.Count;
      var AvgHeapMemory := TotalHeapMemory div MemoryData.Count;

      SB.AppendLine('### 2.1 进程内存使用');
      SB.AppendLine('');
      SB.AppendLine(Format('- 最大值: %s', [TPath.GetFileSize(MaxProcessMemory)]));
      SB.AppendLine(Format('- 最小值: %s', [TPath.GetFileSize(MinProcessMemory)]));
      SB.AppendLine(Format('- 平均值: %s', [TPath.GetFileSize(AvgProcessMemory)]));
      SB.AppendLine('');

      SB.AppendLine('### 2.2 堆内存使用');
      SB.AppendLine('');
      SB.AppendLine(Format('- 最大值: %s', [TPath.GetFileSize(MaxHeapMemory)]));
      SB.AppendLine(Format('- 最小值: %s', [TPath.GetFileSize(MinHeapMemory)]));
      SB.AppendLine(Format('- 平均值: %s', [TPath.GetFileSize(AvgHeapMemory)]));
      SB.AppendLine('');

      // 内存使用趋势
      SB.AppendLine('### 2.3 内存使用趋势');
      SB.AppendLine('');
      SB.AppendLine('| 时间 | 进程内存 | 堆内存 | 堆提交 | 可用物理内存 |');
      SB.AppendLine('|------|----------|--------|--------|--------------|');

      for I := 0 to Min(19, MemoryData.Count - 1) do
      begin
        var MemRecord := MemoryData[I];

        SB.AppendLine(Format('| %s | %s | %s | %s | %s |',
          [FormatDateTime('hh:nn:ss.zzz', MemRecord.Timestamp),
           TPath.GetFileSize(MemRecord.UsageInfo.ProcessMemory),
           TPath.GetFileSize(MemRecord.UsageInfo.HeapAllocated),
           TPath.GetFileSize(MemRecord.UsageInfo.HeapCommitted),
           TPath.GetFileSize(MemRecord.UsageInfo.AvailablePhysical)]));
      end;

      // 如果记录太多，显示省略信息
      if MemoryData.Count > 20 then
        SB.AppendLine(Format('| ... | ... | ... | ... | ... | 还有 %d 条记录未显示 |', [MemoryData.Count - 20]));

      SB.AppendLine('');
    end;

    // 时间分析
    if Options.IncludeTimeAnalysis and (Result.TimeRecords.Length > 0) then
    begin
      SB.AppendLine('## 3. 时间分析');
      SB.AppendLine('');

      // 按类型统计时间
      SB.AppendLine('### 3.1 按类型统计时间');
      SB.AppendLine('');
      SB.AppendLine('| 测量类型 | 记录数 | 总时间(毫秒) | 平均时间(毫秒) | 占比(%) |');
      SB.AppendLine('|----------|--------|--------------|----------------|---------|');

      var TotalAllTime := 0;
      for MeasureType := Low(TTimeMeasureType) to High(TTimeMeasureType) do
      begin
        TimeList := TimeData[MeasureType];

        if TimeList.Count > 0 then
        begin
          var TypeTotalTime := 0;
          for var TimeRecord in TimeList do
            TypeTotalTime := TypeTotalTime + TimeRecord.ElapsedMilliseconds;

          TotalAllTime := TotalAllTime + TypeTotalTime;
        end;
      end;

      for MeasureType := Low(TTimeMeasureType) to High(TTimeMeasureType) do
      begin
        TimeList := TimeData[MeasureType];

        if TimeList.Count > 0 then
        begin
          var TypeTotalTime := 0;
          var MinTime := High(Int64);
          var MaxTime := 0;

          for var TimeRecord in TimeList do
          begin
            TypeTotalTime := TypeTotalTime + TimeRecord.ElapsedMilliseconds;
            MinTime := Min(MinTime, TimeRecord.ElapsedMilliseconds);
            MaxTime := Max(MaxTime, TimeRecord.ElapsedMilliseconds);
          end;

          var AvgTime := TypeTotalTime / TimeList.Count;
          var Percentage := 0.0;

          if TotalAllTime > 0 then
            Percentage := (TypeTotalTime / TotalAllTime) * 100;

          var TypeName := '';
          case MeasureType of
            tmtTotal: TypeName := '总时间';
            tmtFileIO: TypeName := '文件IO';
            tmtEncoding: TypeName := '编码处理';
            tmtDetection: TypeName := '编码检测';
            tmtConversion: TypeName := '编码转换';
            tmtUI: TypeName := 'UI更新';
            tmtOther: TypeName := '其他';
          end;

          SB.AppendLine(Format('| %s | %d | %d | %.2f | %.2f |',
            [TypeName, TimeList.Count, TypeTotalTime, AvgTime, Percentage]));
        end;
      end;

      SB.AppendLine('');

      // 详细时间记录
      SB.AppendLine('### 3.2 详细时间记录');
      SB.AppendLine('');
      SB.AppendLine('| 操作 | 测量类型 | 开始时间 | 结束时间 | 耗时(毫秒) |');
      SB.AppendLine('|------|----------|----------|----------|------------|');

      for I := 0 to Min(19, Length(Result.TimeRecords) - 1) do
      begin
        var TimeRecord := Result.TimeRecords[I];

        var TypeName := '';
        case TimeRecord.MeasureType of
          tmtTotal: TypeName := '总时间';
          tmtFileIO: TypeName := '文件IO';
          tmtEncoding: TypeName := '编码处理';
          tmtDetection: TypeName := '编码检测';
          tmtConversion: TypeName := '编码转换';
          tmtUI: TypeName := 'UI更新';
          tmtOther: TypeName := '其他';
        end;

        SB.AppendLine(Format('| %s | %s | %s | %s | %d |',
          [TimeRecord.OperationName,
           TypeName,
           FormatDateTime('hh:nn:ss.zzz', TimeRecord.StartTime),
           FormatDateTime('hh:nn:ss.zzz', TimeRecord.EndTime),
           TimeRecord.ElapsedMilliseconds]));
      end;

      // 如果记录太多，显示省略信息
      if Length(Result.TimeRecords) > 20 then
        SB.AppendLine(Format('| ... | ... | ... | ... | ... | 还有 %d 条记录未显示 |', [Length(Result.TimeRecords) - 20]));

      SB.AppendLine('');
    end;

    // CPU使用率
    if Options.IncludeCPUUsage and (CPUData.Count > 0) then
    begin
      SB.AppendLine('## 4. CPU使用率');
      SB.AppendLine('');

      // 计算统计数据
      var MaxTotalUsage := 0.0;
      var MinTotalUsage := 100.0;
      var TotalTotalUsage := 0.0;
      var MaxProcessUsage := 0.0;
      var MinProcessUsage := 100.0;
      var TotalProcessUsage := 0.0;

      for var CPURecord in CPUData do
      begin
        MaxTotalUsage := Max(MaxTotalUsage, CPURecord.UsageInfo.TotalUsage);
        MinTotalUsage := Min(MinTotalUsage, CPURecord.UsageInfo.TotalUsage);
        TotalTotalUsage := TotalTotalUsage + CPURecord.UsageInfo.TotalUsage;

        MaxProcessUsage := Max(MaxProcessUsage, CPURecord.UsageInfo.ProcessUsage);
        MinProcessUsage := Min(MinProcessUsage, CPURecord.UsageInfo.ProcessUsage);
        TotalProcessUsage := TotalProcessUsage + CPURecord.UsageInfo.ProcessUsage;
      end;

      var AvgTotalUsage := TotalTotalUsage / CPUData.Count;
      var AvgProcessUsage := TotalProcessUsage / CPUData.Count;

      SB.AppendLine('### 4.1 总体CPU使用率');
      SB.AppendLine('');
      SB.AppendLine(Format('- 最大值: %.2f%%', [MaxTotalUsage]));
      SB.AppendLine(Format('- 最小值: %.2f%%', [MinTotalUsage]));
      SB.AppendLine(Format('- 平均值: %.2f%%', [AvgTotalUsage]));
      SB.AppendLine('');

      SB.AppendLine('### 4.2 进程CPU使用率');
      SB.AppendLine('');
      SB.AppendLine(Format('- 最大值: %.2f%%', [MaxProcessUsage]));
      SB.AppendLine(Format('- 最小值: %.2f%%', [MinProcessUsage]));
      SB.AppendLine(Format('- 平均值: %.2f%%', [AvgProcessUsage]));
      SB.AppendLine('');

      // CPU使用率趋势
      SB.AppendLine('### 4.3 CPU使用率趋势');
      SB.AppendLine('');
      SB.AppendLine('| 时间 | 总体CPU使用率 | 进程CPU使用率 | 线程CPU使用率 | 处理器数量 |');
      SB.AppendLine('|------|--------------|--------------|--------------|------------|');

      for I := 0 to Min(19, CPUData.Count - 1) do
      begin
        var CPURecord := CPUData[I];

        SB.AppendLine(Format('| %s | %.2f%% | %.2f%% | %.2f%% | %d |',
          [FormatDateTime('hh:nn:ss.zzz', CPURecord.Timestamp),
           CPURecord.UsageInfo.TotalUsage,
           CPURecord.UsageInfo.ProcessUsage,
           CPURecord.UsageInfo.ThreadUsage,
           CPURecord.UsageInfo.ProcessorCount]));
      end;

      // 如果记录太多，显示省略信息
      if CPUData.Count > 20 then
        SB.AppendLine(Format('| ... | ... | ... | ... | ... | 还有 %d 条记录未显示 |', [CPUData.Count - 20]));

      SB.AppendLine('');
    end;

    // 优化建议
    if Options.IncludeRecommendations then
    begin
      SB.AppendLine('## 5. 优化建议');
      SB.AppendLine('');
      SB.AppendLine(GenerateRecommendations(Result));
    end;

    System.Result := SB.ToString;
  finally
    // 清理资源
    for ResultsList in PerformanceData.Values do
      ResultsList.Free;

    PerformanceData.Free;
    MemoryData.Free;
    CPUData.Free;

    for TimeList in TimeData.Values do
      TimeList.Free;

    TimeData.Free;
    SB.Free;
  end;
end;

function TEncodingPerformanceBenchmark.GenerateMarkdownReport(const Result: TPerformanceBenchmarkResult;
  const Options: TBenchmarkReportOptions): string;
var
  SB: TStringBuilder;
  PerformanceData: TDictionary<string, TList<TPerformanceTestResult>>;
  MemoryData: TList<TMemoryUsageRecord>;
  CPUData: TList<TCPUUsageRecord>;
  TimeData: TDictionary<TTimeMeasureType, TList<TTimeMeasureRecord>>;
  Operation: string;
  ResultsList: TList<TPerformanceTestResult>;
  MeasureType: TTimeMeasureType;
  TimeList: TList<TTimeMeasureRecord>;
  I: Integer;
begin
  SB := TStringBuilder.Create;
  PerformanceData := TDictionary<string, TList<TPerformanceTestResult>>.Create;
  MemoryData := TList<TMemoryUsageRecord>.Create;
  CPUData := TList<TCPUUsageRecord>.Create;
  TimeData := TDictionary<TTimeMeasureType, TList<TTimeMeasureRecord>>.Create;

  try
    SB.AppendLine('# 编码性能基准测试报告');
    SB.AppendLine('');
    SB.AppendLine(Format('- 测试名称: %s', [Result.TestName]));
    SB.AppendLine(Format('- 测试描述: %s', [Result.TestDescription]));
    SB.AppendLine(Format('- 测试日期: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Result.TestDate)]));
    SB.AppendLine(Format('- 测试持续时间: %d 毫秒', [Result.TestDuration]));
    SB.AppendLine('');

    // 初始化时间测量类型字典
    for MeasureType := Low(TTimeMeasureType) to High(TTimeMeasureType) do
      TimeData.Add(MeasureType, TList<TTimeMeasureRecord>.Create);

    // 按操作分组性能测试结果
    for var PerfResult in Result.PerformanceResults do
    begin
      if not PerformanceData.TryGetValue(PerfResult.OperationName, ResultsList) then
      begin
        ResultsList := TList<TPerformanceTestResult>.Create;
        PerformanceData.Add(PerfResult.OperationName, ResultsList);
      end;

      ResultsList.Add(PerfResult);
    end;

    // 添加内存记录
    for var MemRecord in Result.MemoryRecords do
      MemoryData.Add(MemRecord);

    // 添加CPU记录
    for var CPURecord in Result.CPURecords do
      CPUData.Add(CPURecord);

    // 按类型分组时间测量记录
    for var TimeRecord in Result.TimeRecords do
      TimeData[TimeRecord.MeasureType].Add(TimeRecord);

    // 性能测试结果
    if Options.IncludePerformanceResults and (PerformanceData.Count > 0) then
    begin
      SB.AppendLine('## 1. 性能测试结果');
      SB.AppendLine('');

      I := 1;
      for Operation in PerformanceData.Keys do
      begin
        ResultsList := PerformanceData[Operation];

        SB.AppendLine(Format('### 1.%d %s', [I, Operation]));
        SB.AppendLine('');

        // 计算统计数据
        var TotalTime := 0;
        var TotalMemory := 0;
        var MinTime := High(Integer);
        var MaxTime := 0;

        for var PerfResult in ResultsList do
        begin
          TotalTime := TotalTime + PerfResult.ExecutionTime;
          TotalMemory := TotalMemory + PerfResult.MemoryUsage;
          MinTime := Min(MinTime, PerfResult.ExecutionTime);
          MaxTime := Max(MaxTime, PerfResult.ExecutionTime);
        end;

        var AvgTime := TotalTime / ResultsList.Count;
        var AvgMemory := TotalMemory / ResultsList.Count;

        SB.AppendLine(Format('- 测试次数: %d', [ResultsList.Count]));
        SB.AppendLine(Format('- 平均执行时间: %.2f 毫秒', [AvgTime]));
        SB.AppendLine(Format('- 最小执行时间: %d 毫秒', [MinTime]));
        SB.AppendLine(Format('- 最大执行时间: %d 毫秒', [MaxTime]));
        SB.AppendLine(Format('- 平均内存使用: %s', [TPath.GetFileSize(Round(AvgMemory))]));
        SB.AppendLine('');

        // 详细结果表格
        SB.AppendLine('| 文件大小 | 文件大小类别 | 执行时间(毫秒) | 内存使用 | CPU使用率(%) |');
        SB.AppendLine('|----------|--------------|----------------|----------|--------------|');

        for var PerfResult in ResultsList do
        begin
          SB.AppendLine(Format('| %s | %s | %d | %s | %.2f |',
            [TPath.GetFileSize(PerfResult.FileSize),
             GetEnumName(TypeInfo(TFileSizeCategory), Ord(PerfResult.FileSizeCategory)),
             PerfResult.ExecutionTime,
             TPath.GetFileSize(PerfResult.MemoryUsage),
             PerfResult.CPUUsage]));
        end;

        SB.AppendLine('');
        Inc(I);
      end;
    end;

    // 内存使用情况
    if Options.IncludeMemoryUsage and (MemoryData.Count > 0) then
    begin
      SB.AppendLine('## 2. 内存使用情况');
      SB.AppendLine('');

      // 计算统计数据
      var MaxProcessMemory := 0;
      var MinProcessMemory := High(UInt64);
      var TotalProcessMemory := 0;
      var MaxHeapMemory := 0;
      var MinHeapMemory := High(UInt64);
      var TotalHeapMemory := 0;

      for var MemRecord in MemoryData do
      begin
        MaxProcessMemory := Max(MaxProcessMemory, MemRecord.UsageInfo.ProcessMemory);
        MinProcessMemory := Min(MinProcessMemory, MemRecord.UsageInfo.ProcessMemory);
        TotalProcessMemory := TotalProcessMemory + MemRecord.UsageInfo.ProcessMemory;

        MaxHeapMemory := Max(MaxHeapMemory, MemRecord.UsageInfo.HeapAllocated);
        MinHeapMemory := Min(MinHeapMemory, MemRecord.UsageInfo.HeapAllocated);
        TotalHeapMemory := TotalHeapMemory + MemRecord.UsageInfo.HeapAllocated;
      end;

      var AvgProcessMemory := TotalProcessMemory div MemoryData.Count;
      var AvgHeapMemory := TotalHeapMemory div MemoryData.Count;

      SB.AppendLine('### 2.1 进程内存使用');
      SB.AppendLine('');
      SB.AppendLine(Format('- 最大值: %s', [TPath.GetFileSize(MaxProcessMemory)]));
      SB.AppendLine(Format('- 最小值: %s', [TPath.GetFileSize(MinProcessMemory)]));
      SB.AppendLine(Format('- 平均值: %s', [TPath.GetFileSize(AvgProcessMemory)]));
      SB.AppendLine('');

      SB.AppendLine('### 2.2 堆内存使用');
      SB.AppendLine('');
      SB.AppendLine(Format('- 最大值: %s', [TPath.GetFileSize(MaxHeapMemory)]));
      SB.AppendLine(Format('- 最小值: %s', [TPath.GetFileSize(MinHeapMemory)]));
      SB.AppendLine(Format('- 平均值: %s', [TPath.GetFileSize(AvgHeapMemory)]));
      SB.AppendLine('');

      // 内存使用趋势
      SB.AppendLine('### 2.3 内存使用趋势');
      SB.AppendLine('');
      SB.AppendLine('| 时间 | 进程内存 | 堆内存 | 堆提交 | 可用物理内存 |');
      SB.AppendLine('|------|----------|--------|--------|--------------|');

      for I := 0 to Min(19, MemoryData.Count - 1) do
      begin
        var MemRecord := MemoryData[I];

        SB.AppendLine(Format('| %s | %s | %s | %s | %s |',
          [FormatDateTime('hh:nn:ss.zzz', MemRecord.Timestamp),
           TPath.GetFileSize(MemRecord.UsageInfo.ProcessMemory),
           TPath.GetFileSize(MemRecord.UsageInfo.HeapAllocated),
           TPath.GetFileSize(MemRecord.UsageInfo.HeapCommitted),
           TPath.GetFileSize(MemRecord.UsageInfo.AvailablePhysical)]));
      end;

      // 如果记录太多，显示省略信息
      if MemoryData.Count > 20 then
        SB.AppendLine(Format('| ... | ... | ... | ... | ... | 还有 %d 条记录未显示 |', [MemoryData.Count - 20]));

      SB.AppendLine('');
    end;

    // 时间分析
    if Options.IncludeTimeAnalysis and (Result.TimeRecords.Length > 0) then
    begin
      SB.AppendLine('## 3. 时间分析');
      SB.AppendLine('');

      // 按类型统计时间
      SB.AppendLine('### 3.1 按类型统计时间');
      SB.AppendLine('');
      SB.AppendLine('| 测量类型 | 记录数 | 总时间(毫秒) | 平均时间(毫秒) | 占比(%) |');
      SB.AppendLine('|----------|--------|--------------|----------------|---------|');

      var TotalAllTime := 0;
      for MeasureType := Low(TTimeMeasureType) to High(TTimeMeasureType) do
      begin
        TimeList := TimeData[MeasureType];

        if TimeList.Count > 0 then
        begin
          var TypeTotalTime := 0;
          for var TimeRecord in TimeList do
            TypeTotalTime := TypeTotalTime + TimeRecord.ElapsedMilliseconds;

          TotalAllTime := TotalAllTime + TypeTotalTime;
        end;
      end;

      for MeasureType := Low(TTimeMeasureType) to High(TTimeMeasureType) do
      begin
        TimeList := TimeData[MeasureType];

        if TimeList.Count > 0 then
        begin
          var TypeTotalTime := 0;
          var MinTime := High(Int64);
          var MaxTime := 0;

          for var TimeRecord in TimeList do
          begin
            TypeTotalTime := TypeTotalTime + TimeRecord.ElapsedMilliseconds;
            MinTime := Min(MinTime, TimeRecord.ElapsedMilliseconds);
            MaxTime := Max(MaxTime, TimeRecord.ElapsedMilliseconds);
          end;

          var AvgTime := TypeTotalTime / TimeList.Count;
          var Percentage := 0.0;

          if TotalAllTime > 0 then
            Percentage := (TypeTotalTime / TotalAllTime) * 100;

          var TypeName := '';
          case MeasureType of
            tmtTotal: TypeName := '总时间';
            tmtFileIO: TypeName := '文件IO';
            tmtEncoding: TypeName := '编码处理';
            tmtDetection: TypeName := '编码检测';
            tmtConversion: TypeName := '编码转换';
            tmtUI: TypeName := 'UI更新';
            tmtOther: TypeName := '其他';
          end;

          SB.AppendLine(Format('| %s | %d | %d | %.2f | %.2f |',
            [TypeName, TimeList.Count, TypeTotalTime, AvgTime, Percentage]));
        end;
      end;

      SB.AppendLine('');

      // 详细时间记录
      SB.AppendLine('### 3.2 详细时间记录');
      SB.AppendLine('');
      SB.AppendLine('| 操作 | 测量类型 | 开始时间 | 结束时间 | 耗时(毫秒) |');
      SB.AppendLine('|------|----------|----------|----------|------------|');

      for I := 0 to Min(19, Length(Result.TimeRecords) - 1) do
      begin
        var TimeRecord := Result.TimeRecords[I];

        var TypeName := '';
        case TimeRecord.MeasureType of
          tmtTotal: TypeName := '总时间';
          tmtFileIO: TypeName := '文件IO';
          tmtEncoding: TypeName := '编码处理';
          tmtDetection: TypeName := '编码检测';
          tmtConversion: TypeName := '编码转换';
          tmtUI: TypeName := 'UI更新';
          tmtOther: TypeName := '其他';
        end;

        SB.AppendLine(Format('| %s | %s | %s | %s | %d |',
          [TimeRecord.OperationName,
           TypeName,
           FormatDateTime('hh:nn:ss.zzz', TimeRecord.StartTime),
           FormatDateTime('hh:nn:ss.zzz', TimeRecord.EndTime),
           TimeRecord.ElapsedMilliseconds]));
      end;

      // 如果记录太多，显示省略信息
      if Length(Result.TimeRecords) > 20 then
        SB.AppendLine(Format('| ... | ... | ... | ... | ... | 还有 %d 条记录未显示 |', [Length(Result.TimeRecords) - 20]));

      SB.AppendLine('');
    end;

    // CPU使用率
    if Options.IncludeCPUUsage and (CPUData.Count > 0) then
    begin
      SB.AppendLine('## 4. CPU使用率');
      SB.AppendLine('');

      // 计算统计数据
      var MaxTotalUsage := 0.0;
      var MinTotalUsage := 100.0;
      var TotalTotalUsage := 0.0;
      var MaxProcessUsage := 0.0;
      var MinProcessUsage := 100.0;
      var TotalProcessUsage := 0.0;

      for var CPURecord in CPUData do
      begin
        MaxTotalUsage := Max(MaxTotalUsage, CPURecord.UsageInfo.TotalUsage);
        MinTotalUsage := Min(MinTotalUsage, CPURecord.UsageInfo.TotalUsage);
        TotalTotalUsage := TotalTotalUsage + CPURecord.UsageInfo.TotalUsage;

        MaxProcessUsage := Max(MaxProcessUsage, CPURecord.UsageInfo.ProcessUsage);
        MinProcessUsage := Min(MinProcessUsage, CPURecord.UsageInfo.ProcessUsage);
        TotalProcessUsage := TotalProcessUsage + CPURecord.UsageInfo.ProcessUsage;
      end;

      var AvgTotalUsage := TotalTotalUsage / CPUData.Count;
      var AvgProcessUsage := TotalProcessUsage / CPUData.Count;

      SB.AppendLine('### 4.1 总体CPU使用率');
      SB.AppendLine('');
      SB.AppendLine(Format('- 最大值: %.2f%%', [MaxTotalUsage]));
      SB.AppendLine(Format('- 最小值: %.2f%%', [MinTotalUsage]));
      SB.AppendLine(Format('- 平均值: %.2f%%', [AvgTotalUsage]));
      SB.AppendLine('');

      SB.AppendLine('### 4.2 进程CPU使用率');
      SB.AppendLine('');
      SB.AppendLine(Format('- 最大值: %.2f%%', [MaxProcessUsage]));
      SB.AppendLine(Format('- 最小值: %.2f%%', [MinProcessUsage]));
      SB.AppendLine(Format('- 平均值: %.2f%%', [AvgProcessUsage]));
      SB.AppendLine('');

      // CPU使用率趋势
      SB.AppendLine('### 4.3 CPU使用率趋势');
      SB.AppendLine('');
      SB.AppendLine('| 时间 | 总体CPU使用率 | 进程CPU使用率 | 线程CPU使用率 | 处理器数量 |');
      SB.AppendLine('|------|--------------|--------------|--------------|------------|');

      for I := 0 to Min(19, CPUData.Count - 1) do
      begin
        var CPURecord := CPUData[I];

        SB.AppendLine(Format('| %s | %.2f%% | %.2f%% | %.2f%% | %d |',
          [FormatDateTime('hh:nn:ss.zzz', CPURecord.Timestamp),
           CPURecord.UsageInfo.TotalUsage,
           CPURecord.UsageInfo.ProcessUsage,
           CPURecord.UsageInfo.ThreadUsage,
           CPURecord.UsageInfo.ProcessorCount]));
      end;

      // 如果记录太多，显示省略信息
      if CPUData.Count > 20 then
        SB.AppendLine(Format('| ... | ... | ... | ... | ... | 还有 %d 条记录未显示 |', [CPUData.Count - 20]));

      SB.AppendLine('');
    end;

    // 优化建议
    if Options.IncludeRecommendations then
    begin
      SB.AppendLine('## 5. 优化建议');
      SB.AppendLine('');
      SB.AppendLine(GenerateRecommendations(Result));
    end;

    System.Result := SB.ToString;
  finally
    // 清理资源
    for ResultsList in PerformanceData.Values do
      ResultsList.Free;

    PerformanceData.Free;
    MemoryData.Free;
    CPUData.Free;

    for TimeList in TimeData.Values do
      TimeList.Free;

    TimeData.Free;
    SB.Free;
  end;
end;

function TEncodingPerformanceBenchmark.GenerateChartScript(const Result: TPerformanceBenchmarkResult): string;
var
  SB: TStringBuilder;
  PerformanceData: TDictionary<string, TList<TPerformanceTestResult>>;
  MemoryData: TList<TMemoryUsageRecord>;
  CPUData: TList<TCPUUsageRecord>;
  TimeData: TDictionary<TTimeMeasureType, TList<TTimeMeasureRecord>>;
  Operation: string;
  ResultsList: TList<TPerformanceTestResult>;
  MeasureType: TTimeMeasureType;
  TimeList: TList<TTimeMeasureRecord>;
  I: Integer;
begin
  SB := TStringBuilder.Create;
  PerformanceData := TDictionary<string, TList<TPerformanceTestResult>>.Create;
  MemoryData := TList<TMemoryUsageRecord>.Create;
  CPUData := TList<TCPUUsageRecord>.Create;
  TimeData := TDictionary<TTimeMeasureType, TList<TTimeMeasureRecord>>.Create;

  try
    // 初始化时间测量类型字典
    for MeasureType := Low(TTimeMeasureType) to High(TTimeMeasureType) do
      TimeData.Add(MeasureType, TList<TTimeMeasureRecord>.Create);

    // 按操作分组性能测试结果
    for var PerfResult in Result.PerformanceResults do
    begin
      if not PerformanceData.TryGetValue(PerfResult.OperationName, ResultsList) then
      begin
        ResultsList := TList<TPerformanceTestResult>.Create;
        PerformanceData.Add(PerfResult.OperationName, ResultsList);
      end;

      ResultsList.Add(PerfResult);
    end;

    // 添加内存记录
    for var MemRecord in Result.MemoryRecords do
      MemoryData.Add(MemRecord);

    // 添加CPU记录
    for var CPURecord in Result.CPURecords do
      CPUData.Add(CPURecord);

    // 按类型分组时间测量记录
    for var TimeRecord in Result.TimeRecords do
      TimeData[TimeRecord.MeasureType].Add(TimeRecord);

    // 生成图表脚本
    SB.AppendLine('document.addEventListener("DOMContentLoaded", function() {');

    // 性能测试图表
    if PerformanceData.Count > 0 then
    begin
      SB.AppendLine('  // 性能测试图表');
      SB.AppendLine('  var performanceCtx = document.getElementById("performanceChart").getContext("2d");');
      SB.AppendLine('  var performanceChart = new Chart(performanceCtx, {');
      SB.AppendLine('    type: "bar",');
      SB.AppendLine('    data: {');

      // 添加标签
      SB.Append('      labels: [');
      I := 0;
      for Operation in PerformanceData.Keys do
      begin
        if I > 0 then
          SB.Append(', ');
        SB.Append('"' + Operation + '"');
        Inc(I);
      end;
      SB.AppendLine('],');

      // 添加数据集
      SB.AppendLine('      datasets: [{');
      SB.AppendLine('        label: "平均执行时间(毫秒)",');
      SB.AppendLine('        backgroundColor: "rgba(54, 162, 235, 0.5)",');
      SB.AppendLine('        borderColor: "rgba(54, 162, 235, 1)",');
      SB.AppendLine('        borderWidth: 1,');

      // 添加执行时间数据
      SB.Append('        data: [');
      I := 0;
      for Operation in PerformanceData.Keys do
      begin
        ResultsList := PerformanceData[Operation];

        if I > 0 then
          SB.Append(', ');

        var TotalTime := 0;
        for var PerfResult in ResultsList do
          TotalTime := TotalTime + PerfResult.ExecutionTime;

        var AvgTime := TotalTime / ResultsList.Count;
        SB.Append(Format('%.2f', [AvgTime]));

        Inc(I);
      end;
      SB.AppendLine(']');
      SB.AppendLine('      }]');
      SB.AppendLine('    },');

      // 添加选项
      SB.AppendLine('    options: {');
      SB.AppendLine('      responsive: true,');
      SB.AppendLine('      title: {');
      SB.AppendLine('        display: true,');
      SB.AppendLine('        text: "操作执行时间"');
      SB.AppendLine('      },');
      SB.AppendLine('      scales: {');
      SB.AppendLine('        yAxes: [{');
      SB.AppendLine('          ticks: {');
      SB.AppendLine('            beginAtZero: true');
      SB.AppendLine('          }');
      SB.AppendLine('        }]');
      SB.AppendLine('      }');
      SB.AppendLine('    }');
      SB.AppendLine('  });');
      SB.AppendLine('');
    end;

    // 内存使用图表
    if MemoryData.Count > 0 then
    begin
      SB.AppendLine('  // 内存使用图表');
      SB.AppendLine('  var memoryCtx = document.getElementById("memoryChart").getContext("2d");');
      SB.AppendLine('  var memoryChart = new Chart(memoryCtx, {');
      SB.AppendLine('    type: "line",');
      SB.AppendLine('    data: {');

      // 添加标签
      SB.Append('      labels: [');
      for I := 0 to Min(99, MemoryData.Count - 1) do
      begin
        if I > 0 then
          SB.Append(', ');
        SB.Append('"' + FormatDateTime('hh:nn:ss', MemoryData[I].Timestamp) + '"');
      end;
      SB.AppendLine('],');

      // 添加数据集
      SB.AppendLine('      datasets: [{');
      SB.AppendLine('        label: "进程内存(MB)",');
      SB.AppendLine('        backgroundColor: "rgba(75, 192, 192, 0.2)",');
      SB.AppendLine('        borderColor: "rgba(75, 192, 192, 1)",');
      SB.AppendLine('        borderWidth: 1,');
      SB.AppendLine('        fill: false,');

      // 添加内存使用数据
      SB.Append('        data: [');
      for I := 0 to Min(99, MemoryData.Count - 1) do
      begin
        if I > 0 then
          SB.Append(', ');
        SB.Append(Format('%.2f', [MemoryData[I].UsageInfo.ProcessMemory / (1024 * 1024)]));
      end;
      SB.AppendLine(']');
      SB.AppendLine('      }, {');
      SB.AppendLine('        label: "堆内存(MB)",');
      SB.AppendLine('        backgroundColor: "rgba(255, 99, 132, 0.2)",');
      SB.AppendLine('        borderColor: "rgba(255, 99, 132, 1)",');
      SB.AppendLine('        borderWidth: 1,');
      SB.AppendLine('        fill: false,');

      // 添加堆内存数据
      SB.Append('        data: [');
      for I := 0 to Min(99, MemoryData.Count - 1) do
      begin
        if I > 0 then
          SB.Append(', ');
        SB.Append(Format('%.2f', [MemoryData[I].UsageInfo.HeapAllocated / (1024 * 1024)]));
      end;
      SB.AppendLine(']');
      SB.AppendLine('      }]');
      SB.AppendLine('    },');

      // 添加选项
      SB.AppendLine('    options: {');
      SB.AppendLine('      responsive: true,');
      SB.AppendLine('      title: {');
      SB.AppendLine('        display: true,');
      SB.AppendLine('        text: "内存使用情况"');
      SB.AppendLine('      },');
      SB.AppendLine('      scales: {');
      SB.AppendLine('        yAxes: [{');
      SB.AppendLine('          ticks: {');
      SB.AppendLine('            beginAtZero: true');
      SB.AppendLine('          }');
      SB.AppendLine('        }]');
      SB.AppendLine('      }');
      SB.AppendLine('    }');
      SB.AppendLine('  });');
      SB.AppendLine('');
    end;

    // CPU使用率图表
    if CPUData.Count > 0 then
    begin
      SB.AppendLine('  // CPU使用率图表');
      SB.AppendLine('  var cpuCtx = document.getElementById("cpuChart").getContext("2d");');
      SB.AppendLine('  var cpuChart = new Chart(cpuCtx, {');
      SB.AppendLine('    type: "line",');
      SB.AppendLine('    data: {');

      // 添加标签
      SB.Append('      labels: [');
      for I := 0 to Min(99, CPUData.Count - 1) do
      begin
        if I > 0 then
          SB.Append(', ');
        SB.Append('"' + FormatDateTime('hh:nn:ss', CPUData[I].Timestamp) + '"');
      end;
      SB.AppendLine('],');

      // 添加数据集
      SB.AppendLine('      datasets: [{');
      SB.AppendLine('        label: "总体CPU使用率(%)",');
      SB.AppendLine('        backgroundColor: "rgba(54, 162, 235, 0.2)",');
      SB.AppendLine('        borderColor: "rgba(54, 162, 235, 1)",');
      SB.AppendLine('        borderWidth: 1,');
      SB.AppendLine('        fill: false,');

      // 添加总体CPU使用率数据
      SB.Append('        data: [');
      for I := 0 to Min(99, CPUData.Count - 1) do
      begin
        if I > 0 then
          SB.Append(', ');
        SB.Append(Format('%.2f', [CPUData[I].UsageInfo.TotalUsage]));
      end;
      SB.AppendLine(']');
      SB.AppendLine('      }, {');
      SB.AppendLine('        label: "进程CPU使用率(%)",');
      SB.AppendLine('        backgroundColor: "rgba(255, 206, 86, 0.2)",');
      SB.AppendLine('        borderColor: "rgba(255, 206, 86, 1)",');
      SB.AppendLine('        borderWidth: 1,');
      SB.AppendLine('        fill: false,');

      // 添加进程CPU使用率数据
      SB.Append('        data: [');
      for I := 0 to Min(99, CPUData.Count - 1) do
      begin
        if I > 0 then
          SB.Append(', ');
        SB.Append(Format('%.2f', [CPUData[I].UsageInfo.ProcessUsage]));
      end;
      SB.AppendLine(']');
      SB.AppendLine('      }]');
      SB.AppendLine('    },');

      // 添加选项
      SB.AppendLine('    options: {');
      SB.AppendLine('      responsive: true,');
      SB.AppendLine('      title: {');
      SB.AppendLine('        display: true,');
      SB.AppendLine('        text: "CPU使用率"');
      SB.AppendLine('      },');
      SB.AppendLine('      scales: {');
      SB.AppendLine('        yAxes: [{');
      SB.AppendLine('          ticks: {');
      SB.AppendLine('            beginAtZero: true,');
      SB.AppendLine('            max: 100');
      SB.AppendLine('          }');
      SB.AppendLine('        }]');
      SB.AppendLine('      }');
      SB.AppendLine('    }');
      SB.AppendLine('  });');
      SB.AppendLine('');
    end;

    // 时间测量图表
    if TimeData.Count > 0 then
    begin
      SB.AppendLine('  // 时间测量图表');
      SB.AppendLine('  var timeCtx = document.getElementById("timeChart").getContext("2d");');
      SB.AppendLine('  var timeChart = new Chart(timeCtx, {');
      SB.AppendLine('    type: "pie",');
      SB.AppendLine('    data: {');

      // 添加标签
      SB.Append('      labels: [');
      I := 0;
      for MeasureType := Low(TTimeMeasureType) to High(TTimeMeasureType) do
      begin
        TimeList := TimeData[MeasureType];

        if TimeList.Count > 0 then
        begin
          if I > 0 then
            SB.Append(', ');

          case MeasureType of
            tmtTotal: SB.Append('"总时间"');
            tmtFileIO: SB.Append('"文件IO"');
            tmtEncoding: SB.Append('"编码处理"');
            tmtDetection: SB.Append('"编码检测"');
            tmtConversion: SB.Append('"编码转换"');
            tmtUI: SB.Append('"UI更新"');
            tmtOther: SB.Append('"其他"');
          end;

          Inc(I);
        end;
      end;
      SB.AppendLine('],');

      // 添加数据集
      SB.AppendLine('      datasets: [{');
      SB.AppendLine('        backgroundColor: [');
      SB.AppendLine('          "rgba(54, 162, 235, 0.5)",');
      SB.AppendLine('          "rgba(255, 99, 132, 0.5)",');
      SB.AppendLine('          "rgba(255, 206, 86, 0.5)",');
      SB.AppendLine('          "rgba(75, 192, 192, 0.5)",');
      SB.AppendLine('          "rgba(153, 102, 255, 0.5)",');
      SB.AppendLine('          "rgba(255, 159, 64, 0.5)",');
      SB.AppendLine('          "rgba(199, 199, 199, 0.5)"');
      SB.AppendLine('        ],');
      SB.AppendLine('        borderColor: [');
      SB.AppendLine('          "rgba(54, 162, 235, 1)",');
      SB.AppendLine('          "rgba(255, 99, 132, 1)",');
      SB.AppendLine('          "rgba(255, 206, 86, 1)",');
      SB.AppendLine('          "rgba(75, 192, 192, 1)",');
      SB.AppendLine('          "rgba(153, 102, 255, 1)",');
      SB.AppendLine('          "rgba(255, 159, 64, 1)",');
      SB.AppendLine('          "rgba(199, 199, 199, 1)"');
      SB.AppendLine('        ],');

      // 添加时间测量数据
      SB.Append('        data: [');
      I := 0;
      for MeasureType := Low(TTimeMeasureType) to High(TTimeMeasureType) do
      begin
        TimeList := TimeData[MeasureType];

        if TimeList.Count > 0 then
        begin
          if I > 0 then
            SB.Append(', ');

          var TotalTime := 0;
          for var TimeRecord in TimeList do
            TotalTime := TotalTime + TimeRecord.ElapsedMilliseconds;

          SB.Append(IntToStr(TotalTime));

          Inc(I);
        end;
      end;
      SB.AppendLine(']');
      SB.AppendLine('      }]');
      SB.AppendLine('    },');

      // 添加选项
      SB.AppendLine('    options: {');
      SB.AppendLine('      responsive: true,');
      SB.AppendLine('      title: {');
      SB.AppendLine('        display: true,');
      SB.AppendLine('        text: "时间分布"');
      SB.AppendLine('      }');
      SB.AppendLine('    }');
      SB.AppendLine('  });');
      SB.AppendLine('');
    end;

    SB.AppendLine('});');

    System.Result := SB.ToString;
  finally
    // 清理资源
    for ResultsList in PerformanceData.Values do
      ResultsList.Free;

    PerformanceData.Free;
    MemoryData.Free;
    CPUData.Free;

    for TimeList in TimeData.Values do
      TimeList.Free;

    TimeData.Free;
    SB.Free;
  end;
end;
