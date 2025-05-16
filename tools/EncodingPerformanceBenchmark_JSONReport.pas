function TEncodingPerformanceBenchmark.GenerateJSONReport(const Result: TPerformanceBenchmarkResult; 
  const Options: TBenchmarkReportOptions): string;
var
  Json: TJSONObject;
  PerformanceData: TDictionary<string, TList<TPerformanceTestResult>>;
  MemoryData: TList<TMemoryUsageRecord>;
  CPUData: TList<TCPUUsageRecord>;
  TimeData: TDictionary<TTimeMeasureType, TList<TTimeMeasureRecord>>;
  Operation: string;
  ResultsList: TList<TPerformanceTestResult>;
  MeasureType: TTimeMeasureType;
  TimeList: TList<TTimeMeasureRecord>;
  PerformanceArray, MemoryArray, CPUArray, TimeArray: TJSONArray;
  OperationJson, MemoryJson, CPUJson, TimeJson: TJSONObject;
begin
  Json := TJSONObject.Create;
  PerformanceData := TDictionary<string, TList<TPerformanceTestResult>>.Create;
  MemoryData := TList<TMemoryUsageRecord>.Create;
  CPUData := TList<TCPUUsageRecord>.Create;
  TimeData := TDictionary<TTimeMeasureType, TList<TTimeMeasureRecord>>.Create;
  
  try
    // 添加基本信息
    Json.AddPair('testName', Result.TestName);
    Json.AddPair('testDescription', Result.TestDescription);
    Json.AddPair('testDate', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Result.TestDate));
    Json.AddPair('testDuration', TJSONNumber.Create(Result.TestDuration));
    Json.AddPair('generatedAt', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now));
    
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
      PerformanceArray := TJSONArray.Create;
      
      for Operation in PerformanceData.Keys do
      begin
        ResultsList := PerformanceData[Operation];
        
        OperationJson := TJSONObject.Create;
        OperationJson.AddPair('operation', Operation);
        OperationJson.AddPair('testCount', TJSONNumber.Create(ResultsList.Count));
        
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
        
        OperationJson.AddPair('averageExecutionTime', TJSONNumber.Create(AvgTime));
        OperationJson.AddPair('minExecutionTime', TJSONNumber.Create(MinTime));
        OperationJson.AddPair('maxExecutionTime', TJSONNumber.Create(MaxTime));
        OperationJson.AddPair('averageMemoryUsage', TJSONNumber.Create(AvgMemory));
        
        // 添加详细结果
        var DetailsArray := TJSONArray.Create;
        
        for var PerfResult in ResultsList do
        begin
          var DetailJson := TJSONObject.Create;
          DetailJson.AddPair('fileSize', TJSONNumber.Create(PerfResult.FileSize));
          DetailJson.AddPair('fileSizeCategory', GetEnumName(TypeInfo(TFileSizeCategory), Ord(PerfResult.FileSizeCategory)));
          DetailJson.AddPair('executionTime', TJSONNumber.Create(PerfResult.ExecutionTime));
          DetailJson.AddPair('memoryUsage', TJSONNumber.Create(PerfResult.MemoryUsage));
          DetailJson.AddPair('cpuUsage', TJSONNumber.Create(PerfResult.CPUUsage));
          
          DetailsArray.Add(DetailJson);
        end;
        
        OperationJson.AddPair('details', DetailsArray);
        PerformanceArray.Add(OperationJson);
      end;
      
      Json.AddPair('performanceResults', PerformanceArray);
    end;
    
    // 内存使用情况
    if Options.IncludeMemoryUsage and (MemoryData.Count > 0) then
    begin
      MemoryArray := TJSONArray.Create;
      
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
        
        // 添加详细记录
        MemoryJson := TJSONObject.Create;
        MemoryJson.AddPair('timestamp', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', MemRecord.Timestamp));
        MemoryJson.AddPair('processMemory', TJSONNumber.Create(MemRecord.UsageInfo.ProcessMemory));
        MemoryJson.AddPair('heapAllocated', TJSONNumber.Create(MemRecord.UsageInfo.HeapAllocated));
        MemoryJson.AddPair('heapCommitted', TJSONNumber.Create(MemRecord.UsageInfo.HeapCommitted));
        MemoryJson.AddPair('availablePhysical', TJSONNumber.Create(MemRecord.UsageInfo.AvailablePhysical));
        MemoryJson.AddPair('availableVirtual', TJSONNumber.Create(MemRecord.UsageInfo.AvailableVirtual));
        
        MemoryArray.Add(MemoryJson);
      end;
      
      var AvgProcessMemory := TotalProcessMemory div MemoryData.Count;
      var AvgHeapMemory := TotalHeapMemory div MemoryData.Count;
      
      var MemoryStatsJson := TJSONObject.Create;
      MemoryStatsJson.AddPair('maxProcessMemory', TJSONNumber.Create(MaxProcessMemory));
      MemoryStatsJson.AddPair('minProcessMemory', TJSONNumber.Create(MinProcessMemory));
      MemoryStatsJson.AddPair('avgProcessMemory', TJSONNumber.Create(AvgProcessMemory));
      MemoryStatsJson.AddPair('maxHeapMemory', TJSONNumber.Create(MaxHeapMemory));
      MemoryStatsJson.AddPair('minHeapMemory', TJSONNumber.Create(MinHeapMemory));
      MemoryStatsJson.AddPair('avgHeapMemory', TJSONNumber.Create(AvgHeapMemory));
      
      Json.AddPair('memoryStats', MemoryStatsJson);
      Json.AddPair('memoryRecords', MemoryArray);
    end;
    
    // CPU使用率
    if Options.IncludeCPUUsage and (CPUData.Count > 0) then
    begin
      CPUArray := TJSONArray.Create;
      
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
        
        // 添加详细记录
        CPUJson := TJSONObject.Create;
        CPUJson.AddPair('timestamp', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', CPURecord.Timestamp));
        CPUJson.AddPair('totalUsage', TJSONNumber.Create(CPURecord.UsageInfo.TotalUsage));
        CPUJson.AddPair('processUsage', TJSONNumber.Create(CPURecord.UsageInfo.ProcessUsage));
        CPUJson.AddPair('threadUsage', TJSONNumber.Create(CPURecord.UsageInfo.ThreadUsage));
        CPUJson.AddPair('processorCount', TJSONNumber.Create(CPURecord.UsageInfo.ProcessorCount));
        
        CPUArray.Add(CPUJson);
      end;
      
      var AvgTotalUsage := TotalTotalUsage / CPUData.Count;
      var AvgProcessUsage := TotalProcessUsage / CPUData.Count;
      
      var CPUStatsJson := TJSONObject.Create;
      CPUStatsJson.AddPair('maxTotalUsage', TJSONNumber.Create(MaxTotalUsage));
      CPUStatsJson.AddPair('minTotalUsage', TJSONNumber.Create(MinTotalUsage));
      CPUStatsJson.AddPair('avgTotalUsage', TJSONNumber.Create(AvgTotalUsage));
      CPUStatsJson.AddPair('maxProcessUsage', TJSONNumber.Create(MaxProcessUsage));
      CPUStatsJson.AddPair('minProcessUsage', TJSONNumber.Create(MinProcessUsage));
      CPUStatsJson.AddPair('avgProcessUsage', TJSONNumber.Create(AvgProcessUsage));
      
      Json.AddPair('cpuStats', CPUStatsJson);
      Json.AddPair('cpuRecords', CPUArray);
    end;
    
    // 时间分析
    if Options.IncludeTimeAnalysis and (Result.TimeRecords.Length > 0) then
    begin
      TimeArray := TJSONArray.Create;
      
      // 按类型统计时间
      var TimeStatsArray := TJSONArray.Create;
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
          
          var TypeStatsJson := TJSONObject.Create;
          TypeStatsJson.AddPair('type', TypeName);
          TypeStatsJson.AddPair('count', TJSONNumber.Create(TimeList.Count));
          TypeStatsJson.AddPair('totalTime', TJSONNumber.Create(TypeTotalTime));
          TypeStatsJson.AddPair('avgTime', TJSONNumber.Create(AvgTime));
          TypeStatsJson.AddPair('minTime', TJSONNumber.Create(MinTime));
          TypeStatsJson.AddPair('maxTime', TJSONNumber.Create(MaxTime));
          TypeStatsJson.AddPair('percentage', TJSONNumber.Create(Percentage));
          
          TimeStatsArray.Add(TypeStatsJson);
        end;
      end;
      
      Json.AddPair('timeStats', TimeStatsArray);
      
      // 添加详细记录
      for var TimeRecord in Result.TimeRecords do
      begin
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
        
        TimeJson := TJSONObject.Create;
        TimeJson.AddPair('operation', TimeRecord.OperationName);
        TimeJson.AddPair('type', TypeName);
        TimeJson.AddPair('startTime', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', TimeRecord.StartTime));
        TimeJson.AddPair('endTime', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', TimeRecord.EndTime));
        TimeJson.AddPair('elapsedMilliseconds', TJSONNumber.Create(TimeRecord.ElapsedMilliseconds));
        
        TimeArray.Add(TimeJson);
      end;
      
      Json.AddPair('timeRecords', TimeArray);
    end;
    
    // 优化建议
    if Options.IncludeRecommendations then
    begin
      var RecommendationsJson := TJSONObject.Create;
      
      // 查找最慢的操作
      var SlowestOperation := '';
      var MaxAvgTime := 0.0;
      
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
      
      if SlowestOperation <> '' then
        RecommendationsJson.AddPair('slowestOperation', SlowestOperation);
      
      // 查找内存使用最多的操作
      var HighestMemoryOperation := '';
      var MaxAvgMemory := 0;
      
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
      
      if HighestMemoryOperation <> '' then
        RecommendationsJson.AddPair('highestMemoryOperation', HighestMemoryOperation);
      
      // 检查CPU使用率
      var HighCPUUsage := False;
      if CPUData.Count > 0 then
      begin
        var TotalProcessUsage := 0.0;
        for var CPURecord in CPUData do
          TotalProcessUsage := TotalProcessUsage + CPURecord.UsageInfo.ProcessUsage;
        
        var AvgProcessUsage := TotalProcessUsage / CPUData.Count;
        
        HighCPUUsage := AvgProcessUsage > 50;
      end;
      
      RecommendationsJson.AddPair('highCPUUsage', TJSONBool.Create(HighCPUUsage));
      
      // 检查内存使用
      var LargeMemoryUsage := False;
      if MemoryData.Count > 0 then
      begin
        var MaxProcessMemory := 0;
        for var MemRecord in MemoryData do
          MaxProcessMemory := Max(MaxProcessMemory, MemRecord.UsageInfo.ProcessMemory);
        
        LargeMemoryUsage := MaxProcessMemory > 100 * 1024 * 1024; // 100MB
      end;
      
      RecommendationsJson.AddPair('largeMemoryUsage', TJSONBool.Create(LargeMemoryUsage));
      
      // 检查文件IO时间
      var LongFileIOTime := False;
      TimeList := TimeData[tmtFileIO];
      if TimeList.Count > 0 then
      begin
        var TotalTime := 0;
        for var TimeRecord in TimeList do
          TotalTime := TotalTime + TimeRecord.ElapsedMilliseconds;
        
        var AvgTime := TotalTime / TimeList.Count;
        
        LongFileIOTime := AvgTime > 100; // 100ms
      end;
      
      RecommendationsJson.AddPair('longFileIOTime', TJSONBool.Create(LongFileIOTime));
      
      Json.AddPair('recommendations', RecommendationsJson);
    end;
    
    Result := Json.ToString;
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
    Json.Free;
  end;
end;
