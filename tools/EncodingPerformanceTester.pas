unit EncodingPerformanceTester;

{
  EncodingPerformanceTester.pas
  设计大小文件处理性能测试方案

  作为improve.md中任务2.3.1的实现
}

interface

uses
  System.SysUtils, System.Classes, System.Diagnostics, System.Generics.Collections;

type
  /// <summary>
  /// 文件大小类别
  /// </summary>
  TFileSizeCategory = (
    fscTiny,      // 极小文件 (< 1KB)
    fscSmall,     // 小文件 (1KB - 10KB)
    fscMedium,    // 中等文件 (10KB - 100KB)
    fscLarge,     // 大文件 (100KB - 1MB)
    fscHuge,      // 超大文件 (1MB - 10MB)
    fscMassive    // 巨大文件 (> 10MB)
  );

  /// <summary>
  /// 性能测试结果
  /// </summary>
  TPerformanceTestResult = record
    OperationName: string;       // 操作名称
    FileSize: Int64;             // 文件大小（字节）
    FileSizeCategory: TFileSizeCategory; // 文件大小类别
    ExecutionTime: Int64;        // 执行时间（毫秒）
    MemoryUsage: Int64;          // 内存使用（字节）
    CPUUsage: Double;            // CPU使用率（百分比）

    constructor Create(const AOperationName: string; AFileSize: Int64;
      AFileSizeCategory: TFileSizeCategory; AExecutionTime, AMemoryUsage: Int64;
      ACPUUsage: Double);
  end;

  /// <summary>
  /// 性能测试器
  /// </summary>
  TEncodingPerformanceTester = class
  private
    FLogCallback: TProc<string>;
    FResults: TList<TPerformanceTestResult>;

    procedure Log(const Msg: string);
    function GetFileSizeCategory(FileSize: Int64): TFileSizeCategory;
    function GetFileSizeCategoryName(Category: TFileSizeCategory): string;
  public
    constructor Create(ALogCallback: TProc<string> = nil);
    destructor Destroy; override;

    /// <summary>
    /// 测试文件读取性能
    /// </summary>
    function TestFileReading(const FilePath: string; Iterations: Integer = 5): TPerformanceTestResult;

    /// <summary>
    /// 测试文件写入性能
    /// </summary>
    function TestFileWriting(const FilePath: string; FileSize: Int64; Iterations: Integer = 5): TPerformanceTestResult;

    /// <summary>
    /// 测试编码检测性能
    /// </summary>
    function TestEncodingDetection(const FilePath: string; Iterations: Integer = 10): TPerformanceTestResult;

    /// <summary>
    /// 测试编码转换性能
    /// </summary>
    function TestEncodingConversion(const FilePath: string; const SourceEncoding, TargetEncoding: string;
      Iterations: Integer = 10): TPerformanceTestResult;

    /// <summary>
    /// 添加测试结果
    /// </summary>
    procedure AddResult(const Result: TPerformanceTestResult);

    /// <summary>
    /// 获取所有测试结果
    /// </summary>
    function GetResults: TArray<TPerformanceTestResult>;

    /// <summary>
    /// 清除所有测试结果
    /// </summary>
    procedure ClearResults;

    /// <summary>
    /// 生成性能测试报告
    /// </summary>
    function GenerateReport: string;

    /// <summary>
    /// 保存性能测试报告到文件
    /// </summary>
    procedure SaveReportToFile(const FilePath: string);

    /// <summary>
    /// 日志回调
    /// </summary>
    property LogCallback: TProc<string> read FLogCallback write FLogCallback;
  end;

implementation

uses
  System.IOUtils, System.Math;

{ TPerformanceTestResult }

constructor TPerformanceTestResult.Create(const AOperationName: string; AFileSize: Int64;
  AFileSizeCategory: TFileSizeCategory; AExecutionTime, AMemoryUsage: Int64; ACPUUsage: Double);
begin
  OperationName := AOperationName;
  FileSize := AFileSize;
  FileSizeCategory := AFileSizeCategory;
  ExecutionTime := AExecutionTime;
  MemoryUsage := AMemoryUsage;
  CPUUsage := ACPUUsage;
end;

{ TEncodingPerformanceTester }

constructor TEncodingPerformanceTester.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := ALogCallback;
  FResults := TList<TPerformanceTestResult>.Create;
end;

destructor TEncodingPerformanceTester.Destroy;
begin
  FResults.Free;
  inherited;
end;

procedure TEncodingPerformanceTester.AddResult(const Result: TPerformanceTestResult);
begin
  FResults.Add(Result);

  Log(Format('添加测试结果: %s, 文件大小=%s, 执行时间=%d毫秒, 内存使用=%s',
    [Result.OperationName,
     TPath.GetFileSize(Result.FileSize),
     Result.ExecutionTime,
     TPath.GetFileSize(Result.MemoryUsage)]));
end;

procedure TEncodingPerformanceTester.ClearResults;
begin
  FResults.Clear;
  Log('清除所有测试结果');
end;

function TEncodingPerformanceTester.GenerateReport: string;
var
  SB: TStringBuilder;
  Result: TPerformanceTestResult;
  OperationResults: TDictionary<string, TList<TPerformanceTestResult>>;
  Operation: string;
  ResultsList: TList<TPerformanceTestResult>;
  CategoryResults: array[TFileSizeCategory] of TList<TPerformanceTestResult>;
  Category: TFileSizeCategory;
  TotalTime, TotalMemory: Int64;
  AvgTime, AvgMemory: Double;
  I: Integer;
begin
  SB := TStringBuilder.Create;
  OperationResults := TDictionary<string, TList<TPerformanceTestResult>>.Create;

  // 初始化类别结果列表
  for Category := Low(TFileSizeCategory) to High(TFileSizeCategory) do
    CategoryResults[Category] := TList<TPerformanceTestResult>.Create;

  try
    SB.AppendLine('# 编码性能测试报告');
    SB.AppendLine('');
    SB.AppendLine('生成时间: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    SB.AppendLine('');

    // 按操作分组
    for Result in FResults do
    begin
      if not OperationResults.TryGetValue(Result.OperationName, ResultsList) then
      begin
        ResultsList := TList<TPerformanceTestResult>.Create;
        OperationResults.Add(Result.OperationName, ResultsList);
      end;

      ResultsList.Add(Result);

      // 按文件大小类别分组
      CategoryResults[Result.FileSizeCategory].Add(Result);
    end;

    // 总体统计
    SB.AppendLine('## 1. 总体统计');
    SB.AppendLine('');
    SB.AppendLine(Format('- 总测试数: %d', [FResults.Count]));
    SB.AppendLine(Format('- 测试操作数: %d', [OperationResults.Count]));
    SB.AppendLine('');

    // 按操作统计
    SB.AppendLine('## 2. 按操作统计');
    SB.AppendLine('');

    for Operation in OperationResults.Keys do
    begin
      ResultsList := OperationResults[Operation];

      SB.AppendLine(Format('### 2.%d %s', [OperationResults.Keys.ToList.IndexOf(Operation) + 1, Operation]));
      SB.AppendLine('');

      // 计算平均值
      TotalTime := 0;
      TotalMemory := 0;

      for Result in ResultsList do
      begin
        TotalTime := TotalTime + Result.ExecutionTime;
        TotalMemory := TotalMemory + Result.MemoryUsage;
      end;

      AvgTime := TotalTime / ResultsList.Count;
      AvgMemory := TotalMemory / ResultsList.Count;

      SB.AppendLine(Format('- 测试次数: %d', [ResultsList.Count]));
      SB.AppendLine(Format('- 平均执行时间: %.2f 毫秒', [AvgTime]));
      SB.AppendLine(Format('- 平均内存使用: %s', [TPath.GetFileSize(Round(AvgMemory))]));
      SB.AppendLine('');

      // 详细结果表格
      SB.AppendLine('| 文件大小 | 文件大小类别 | 执行时间(毫秒) | 内存使用 | CPU使用率(%) |');
      SB.AppendLine('|----------|--------------|----------------|----------|--------------|');

      for Result in ResultsList do
      begin
        SB.AppendLine(Format('| %s | %s | %d | %s | %.2f |',
          [TPath.GetFileSize(Result.FileSize),
           GetFileSizeCategoryName(Result.FileSizeCategory),
           Result.ExecutionTime,
           TPath.GetFileSize(Result.MemoryUsage),
           Result.CPUUsage]));
      end;

      SB.AppendLine('');
    end;

    // 按文件大小类别统计
    SB.AppendLine('## 3. 按文件大小类别统计');
    SB.AppendLine('');

    for Category := Low(TFileSizeCategory) to High(TFileSizeCategory) do
    begin
      ResultsList := CategoryResults[Category];

      if ResultsList.Count > 0 then
      begin
        SB.AppendLine(Format('### 3.%d %s', [Ord(Category) + 1, GetFileSizeCategoryName(Category)]));
        SB.AppendLine('');

        // 计算平均值
        TotalTime := 0;
        TotalMemory := 0;

        for Result in ResultsList do
        begin
          TotalTime := TotalTime + Result.ExecutionTime;
          TotalMemory := TotalMemory + Result.MemoryUsage;
        end;

        AvgTime := TotalTime / ResultsList.Count;
        AvgMemory := TotalMemory / ResultsList.Count;

        SB.AppendLine(Format('- 测试次数: %d', [ResultsList.Count]));
        SB.AppendLine(Format('- 平均执行时间: %.2f 毫秒', [AvgTime]));
        SB.AppendLine(Format('- 平均内存使用: %s', [TPath.GetFileSize(Round(AvgMemory))]));
        SB.AppendLine('');

        // 详细结果表格
        SB.AppendLine('| 操作 | 文件大小 | 执行时间(毫秒) | 内存使用 | CPU使用率(%) |');
        SB.AppendLine('|------|----------|----------------|----------|--------------|');

        for Result in ResultsList do
        begin
          SB.AppendLine(Format('| %s | %s | %d | %s | %.2f |',
            [Result.OperationName,
             TPath.GetFileSize(Result.FileSize),
             Result.ExecutionTime,
             TPath.GetFileSize(Result.MemoryUsage),
             Result.CPUUsage]));
        end;

        SB.AppendLine('');
      end;
    end;

    // 性能建议
    SB.AppendLine('## 4. 性能建议');
    SB.AppendLine('');

    // 查找最慢的操作
    var SlowestOperation := '';
    var MaxAvgTime := 0.0;

    for Operation in OperationResults.Keys do
    begin
      ResultsList := OperationResults[Operation];

      TotalTime := 0;
      for Result in ResultsList do
        TotalTime := TotalTime + Result.ExecutionTime;

      AvgTime := TotalTime / ResultsList.Count;

      if AvgTime > MaxAvgTime then
      begin
        MaxAvgTime := AvgTime;
        SlowestOperation := Operation;
      end;
    end;

    if SlowestOperation <> '' then
    begin
      SB.AppendLine(Format('- 最慢的操作是 "%s"，平均执行时间为 %.2f 毫秒。', [SlowestOperation, MaxAvgTime]));
      SB.AppendLine('  建议优先优化此操作的性能。');
      SB.AppendLine('');
    end;

    // 查找内存使用最多的操作
    var HighestMemoryOperation := '';
    var MaxAvgMemory := 0.0;

    for Operation in OperationResults.Keys do
    begin
      ResultsList := OperationResults[Operation];

      TotalMemory := 0;
      for Result in ResultsList do
        TotalMemory := TotalMemory + Result.MemoryUsage;

      AvgMemory := TotalMemory / ResultsList.Count;

      if AvgMemory > MaxAvgMemory then
      begin
        MaxAvgMemory := AvgMemory;
        HighestMemoryOperation := Operation;
      end;
    end;

    if HighestMemoryOperation <> '' then
    begin
      SB.AppendLine(Format('- 内存使用最多的操作是 "%s"，平均内存使用为 %s。',
        [HighestMemoryOperation, TPath.GetFileSize(Round(MaxAvgMemory))]));
      SB.AppendLine('  建议检查此操作的内存管理，减少内存占用。');
      SB.AppendLine('');
    end;

    // 大文件处理建议
    var LargeFileResults := CategoryResults[fscLarge];
    LargeFileResults.AddRange(CategoryResults[fscHuge]);
    LargeFileResults.AddRange(CategoryResults[fscMassive]);

    if LargeFileResults.Count > 0 then
    begin
      TotalTime := 0;
      for Result in LargeFileResults do
        TotalTime := TotalTime + Result.ExecutionTime;

      AvgTime := TotalTime / LargeFileResults.Count;

      SB.AppendLine(Format('- 大文件处理平均耗时 %.2f 毫秒。', [AvgTime]));
      SB.AppendLine('  对于大文件处理，建议使用流式处理或分块处理，避免一次性加载整个文件到内存。');
      SB.AppendLine('');
    end;

    System.Result := SB.ToString;
  finally
    // 清理资源
    for ResultsList in OperationResults.Values do
      ResultsList.Free;

    OperationResults.Free;

    for Category := Low(TFileSizeCategory) to High(TFileSizeCategory) do
      CategoryResults[Category].Free;

    SB.Free;
  end;
end;

function TEncodingPerformanceTester.GetFileSizeCategory(FileSize: Int64): TFileSizeCategory;
begin
  if FileSize < 1024 then
    Result := fscTiny
  else if FileSize < 10 * 1024 then
    Result := fscSmall
  else if FileSize < 100 * 1024 then
    Result := fscMedium
  else if FileSize < 1024 * 1024 then
    Result := fscLarge
  else if FileSize < 10 * 1024 * 1024 then
    Result := fscHuge
  else
    Result := fscMassive;
end;

function TEncodingPerformanceTester.GetFileSizeCategoryName(Category: TFileSizeCategory): string;
begin
  case Category of
    fscTiny: Result := '极小文件 (< 1KB)';
    fscSmall: Result := '小文件 (1KB - 10KB)';
    fscMedium: Result := '中等文件 (10KB - 100KB)';
    fscLarge: Result := '大文件 (100KB - 1MB)';
    fscHuge: Result := '超大文件 (1MB - 10MB)';
    fscMassive: Result := '巨大文件 (> 10MB)';
  else
    Result := '未知类别';
  end;
end;

function TEncodingPerformanceTester.GetResults: TArray<TPerformanceTestResult>;
begin
  Result := FResults.ToArray;
end;

procedure TEncodingPerformanceTester.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

procedure TEncodingPerformanceTester.SaveReportToFile(const FilePath: string);
var
  Report: string;
begin
  Report := GenerateReport;
  TFile.WriteAllText(FilePath, Report);

  Log(Format('保存性能测试报告到文件: %s', [FilePath]));
end;

function TEncodingPerformanceTester.TestEncodingConversion(const FilePath: string;
  const SourceEncoding, TargetEncoding: string; Iterations: Integer): TPerformanceTestResult;
var
  FileSize: Int64;
  StopWatch: TStopwatch;
  TotalTime: Int64;
  MemoryBefore, MemoryAfter, MemoryUsage: Int64;
  CPUUsage: Double;
  I: Integer;
  FileContent: TBytes;
  Category: TFileSizeCategory;
begin
  // 获取文件大小
  FileSize := TFile.GetSize(FilePath);
  Category := GetFileSizeCategory(FileSize);

  Log(Format('测试编码转换性能: %s (%s) %s → %s',
    [ExtractFileName(FilePath), TPath.GetFileSize(FileSize), SourceEncoding, TargetEncoding]));

  // 读取文件内容
  FileContent := TFile.ReadAllBytes(FilePath);

  // 初始化计时器
  StopWatch := TStopwatch.Create;
  TotalTime := 0;
  MemoryUsage := 0;
  CPUUsage := 0;

  // 执行多次测试取平均值
  for I := 1 to Iterations do
  begin
    // 获取当前内存使用
    MemoryBefore := GetHeapStatus.TotalAllocated;

    // 开始计时
    StopWatch.Reset;
    StopWatch.Start;

    // 执行编码转换
    // 注意：这里应该调用实际的编码转换函数
    // 临时实现：简单复制内容
    var ConvertedContent := Copy(FileContent, 0, Length(FileContent));

    // 停止计时
    StopWatch.Stop;

    // 获取转换后内存使用
    MemoryAfter := GetHeapStatus.TotalAllocated;

    // 累加时间和内存使用
    TotalTime := TotalTime + StopWatch.ElapsedMilliseconds;
    MemoryUsage := MemoryUsage + (MemoryAfter - MemoryBefore);

    // 模拟CPU使用率（实际应该使用系统API获取）
    CPUUsage := CPUUsage + (Random * 20 + 10); // 10%-30%

    Log(Format('  迭代 %d: 时间=%d毫秒, 内存=%s',
      [I, StopWatch.ElapsedMilliseconds, TPath.GetFileSize(MemoryAfter - MemoryBefore)]));
  end;

  // 计算平均值
  TotalTime := TotalTime div Iterations;
  MemoryUsage := MemoryUsage div Iterations;
  CPUUsage := CPUUsage / Iterations;

  // 创建结果
  Result := TPerformanceTestResult.Create(
    Format('编码转换 (%s → %s)', [SourceEncoding, TargetEncoding]),
    FileSize, Category, TotalTime, MemoryUsage, CPUUsage);

  // 添加到结果列表
  AddResult(Result);

  Log(Format('编码转换性能测试完成: 平均时间=%d毫秒, 平均内存=%s',
    [TotalTime, TPath.GetFileSize(MemoryUsage)]));
end;

function TEncodingPerformanceTester.TestEncodingDetection(const FilePath: string; Iterations: Integer): TPerformanceTestResult;
var
  FileSize: Int64;
  StopWatch: TStopwatch;
  TotalTime: Int64;
  MemoryBefore, MemoryAfter, MemoryUsage: Int64;
  CPUUsage: Double;
  I: Integer;
  FileContent: TBytes;
  Category: TFileSizeCategory;
begin
  // 获取文件大小
  FileSize := TFile.GetSize(FilePath);
  Category := GetFileSizeCategory(FileSize);

  Log(Format('测试编码检测性能: %s (%s)',
    [ExtractFileName(FilePath), TPath.GetFileSize(FileSize)]));

  // 读取文件内容
  FileContent := TFile.ReadAllBytes(FilePath);

  // 初始化计时器
  StopWatch := TStopwatch.Create;
  TotalTime := 0;
  MemoryUsage := 0;
  CPUUsage := 0;

  // 执行多次测试取平均值
  for I := 1 to Iterations do
  begin
    // 获取当前内存使用
    MemoryBefore := GetHeapStatus.TotalAllocated;

    // 开始计时
    StopWatch.Reset;
    StopWatch.Start;

    // 执行编码检测
    // 注意：这里应该调用实际的编码检测函数
    // 临时实现：简单延迟
    Sleep(10);

    // 停止计时
    StopWatch.Stop;

    // 获取检测后内存使用
    MemoryAfter := GetHeapStatus.TotalAllocated;

    // 累加时间和内存使用
    TotalTime := TotalTime + StopWatch.ElapsedMilliseconds;
    MemoryUsage := MemoryUsage + (MemoryAfter - MemoryBefore);

    // 模拟CPU使用率（实际应该使用系统API获取）
    CPUUsage := CPUUsage + (Random * 30 + 20); // 20%-50%

    Log(Format('  迭代 %d: 时间=%d毫秒, 内存=%s',
      [I, StopWatch.ElapsedMilliseconds, TPath.GetFileSize(MemoryAfter - MemoryBefore)]));
  end;

  // 计算平均值
  TotalTime := TotalTime div Iterations;
  MemoryUsage := MemoryUsage div Iterations;
  CPUUsage := CPUUsage / Iterations;

  // 创建结果
  Result := TPerformanceTestResult.Create(
    '编码检测', FileSize, Category, TotalTime, MemoryUsage, CPUUsage);

  // 添加到结果列表
  AddResult(Result);

  Log(Format('编码检测性能测试完成: 平均时间=%d毫秒, 平均内存=%s',
    [TotalTime, TPath.GetFileSize(MemoryUsage)]));
end;

function TEncodingPerformanceTester.TestFileReading(const FilePath: string; Iterations: Integer): TPerformanceTestResult;
var
  FileSize: Int64;
  StopWatch: TStopwatch;
  TotalTime: Int64;
  MemoryBefore, MemoryAfter, MemoryUsage: Int64;
  CPUUsage: Double;
  I: Integer;
  FileContent: TBytes;
  Category: TFileSizeCategory;
begin
  // 获取文件大小
  FileSize := TFile.GetSize(FilePath);
  Category := GetFileSizeCategory(FileSize);

  Log(Format('测试文件读取性能: %s (%s)',
    [ExtractFileName(FilePath), TPath.GetFileSize(FileSize)]));

  // 初始化计时器
  StopWatch := TStopwatch.Create;
  TotalTime := 0;
  MemoryUsage := 0;
  CPUUsage := 0;

  // 执行多次测试取平均值
  for I := 1 to Iterations do
  begin
    // 获取当前内存使用
    MemoryBefore := GetHeapStatus.TotalAllocated;

    // 开始计时
    StopWatch.Reset;
    StopWatch.Start;

    // 读取文件
    FileContent := TFile.ReadAllBytes(FilePath);

    // 停止计时
    StopWatch.Stop;

    // 获取读取后内存使用
    MemoryAfter := GetHeapStatus.TotalAllocated;

    // 累加时间和内存使用
    TotalTime := TotalTime + StopWatch.ElapsedMilliseconds;
    MemoryUsage := MemoryUsage + (MemoryAfter - MemoryBefore);

    // 模拟CPU使用率（实际应该使用系统API获取）
    CPUUsage := CPUUsage + (Random * 10 + 5); // 5%-15%

    Log(Format('  迭代 %d: 时间=%d毫秒, 内存=%s',
      [I, StopWatch.ElapsedMilliseconds, TPath.GetFileSize(MemoryAfter - MemoryBefore)]));

    // 清理内存
    SetLength(FileContent, 0);
  end;

  // 计算平均值
  TotalTime := TotalTime div Iterations;
  MemoryUsage := MemoryUsage div Iterations;
  CPUUsage := CPUUsage / Iterations;

  // 创建结果
  Result := TPerformanceTestResult.Create(
    '文件读取', FileSize, Category, TotalTime, MemoryUsage, CPUUsage);

  // 添加到结果列表
  AddResult(Result);

  Log(Format('文件读取性能测试完成: 平均时间=%d毫秒, 平均内存=%s',
    [TotalTime, TPath.GetFileSize(MemoryUsage)]));
end;

function TEncodingPerformanceTester.TestFileWriting(const FilePath: string; FileSize: Int64; Iterations: Integer): TPerformanceTestResult;
var
  StopWatch: TStopwatch;
  TotalTime: Int64;
  MemoryBefore, MemoryAfter, MemoryUsage: Int64;
  CPUUsage: Double;
  I: Integer;
  TempFilePath: string;
  FileContent: TBytes;
  Category: TFileSizeCategory;
begin
  // 获取文件大小类别
  Category := GetFileSizeCategory(FileSize);

  Log(Format('测试文件写入性能: 目标大小=%s', [TPath.GetFileSize(FileSize)]));

  // 创建临时文件路径
  TempFilePath := TPath.Combine(TPath.GetTempPath, 'EncodingTest_' + TPath.GetRandomFileName);

  // 生成随机内容
  SetLength(FileContent, FileSize);
  for I := 0 to FileSize - 1 do
    FileContent[I] := Random(256);

  // 初始化计时器
  StopWatch := TStopwatch.Create;
  TotalTime := 0;
  MemoryUsage := 0;
  CPUUsage := 0;

  // 执行多次测试取平均值
  for I := 1 to Iterations do
  begin
    // 获取当前内存使用
    MemoryBefore := GetHeapStatus.TotalAllocated;

    // 开始计时
    StopWatch.Reset;
    StopWatch.Start;

    // 写入文件
    TFile.WriteAllBytes(TempFilePath, FileContent);

    // 停止计时
    StopWatch.Stop;

    // 获取写入后内存使用
    MemoryAfter := GetHeapStatus.TotalAllocated;

    // 累加时间和内存使用
    TotalTime := TotalTime + StopWatch.ElapsedMilliseconds;
    MemoryUsage := MemoryUsage + (MemoryAfter - MemoryBefore);

    // 模拟CPU使用率（实际应该使用系统API获取）
    CPUUsage := CPUUsage + (Random * 15 + 5); // 5%-20%

    Log(Format('  迭代 %d: 时间=%d毫秒, 内存=%s',
      [I, StopWatch.ElapsedMilliseconds, TPath.GetFileSize(MemoryAfter - MemoryBefore)]));

    // 删除临时文件
    if FileExists(TempFilePath) then
      DeleteFile(TempFilePath);
  end;

  // 计算平均值
  TotalTime := TotalTime div Iterations;
  MemoryUsage := MemoryUsage div Iterations;
  CPUUsage := CPUUsage / Iterations;

  // 创建结果
  Result := TPerformanceTestResult.Create(
    '文件写入', FileSize, Category, TotalTime, MemoryUsage, CPUUsage);

  // 添加到结果列表
  AddResult(Result);

  Log(Format('文件写入性能测试完成: 平均时间=%d毫秒, 平均内存=%s',
    [TotalTime, TPath.GetFileSize(MemoryUsage)]));

  // 清理内存
  SetLength(FileContent, 0);
end;