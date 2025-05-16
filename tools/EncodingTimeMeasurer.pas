unit EncodingTimeMeasurer;

{
  EncodingTimeMeasurer.pas
  添加处理时间测量功能
  
  作为improve.md中任务2.3.3的实现
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Diagnostics;

type
  /// <summary>
  /// 时间测量类型
  /// </summary>
  TTimeMeasureType = (
    tmtTotal,            // 总时间
    tmtFileIO,           // 文件IO时间
    tmtEncoding,         // 编码处理时间
    tmtDetection,        // 编码检测时间
    tmtConversion,       // 编码转换时间
    tmtUI,               // UI更新时间
    tmtOther             // 其他时间
  );
  
  /// <summary>
  /// 时间测量记录
  /// </summary>
  TTimeMeasureRecord = record
    OperationName: string;       // 操作名称
    MeasureType: TTimeMeasureType; // 测量类型
    StartTime: TDateTime;        // 开始时间
    EndTime: TDateTime;          // 结束时间
    ElapsedMilliseconds: Int64;  // 耗时（毫秒）
    
    constructor Create(const AOperationName: string; AMeasureType: TTimeMeasureType;
      AStartTime, AEndTime: TDateTime; AElapsedMilliseconds: Int64);
  end;
  
  /// <summary>
  /// 时间测量会话
  /// </summary>
  TTimeMeasureSession = class
  private
    FOperationName: string;
    FMeasureType: TTimeMeasureType;
    FStartTime: TDateTime;
    FStopwatch: TStopwatch;
    FIsRunning: Boolean;
    
    function GetElapsedMilliseconds: Int64;
  public
    constructor Create(const AOperationName: string; AMeasureType: TTimeMeasureType);
    
    /// <summary>
    /// 开始测量
    /// </summary>
    procedure Start;
    
    /// <summary>
    /// 停止测量
    /// </summary>
    procedure Stop;
    
    /// <summary>
    /// 重置测量
    /// </summary>
    procedure Reset;
    
    /// <summary>
    /// 创建测量记录
    /// </summary>
    function CreateRecord: TTimeMeasureRecord;
    
    /// <summary>
    /// 操作名称
    /// </summary>
    property OperationName: string read FOperationName;
    
    /// <summary>
    /// 测量类型
    /// </summary>
    property MeasureType: TTimeMeasureType read FMeasureType;
    
    /// <summary>
    /// 开始时间
    /// </summary>
    property StartTime: TDateTime read FStartTime;
    
    /// <summary>
    /// 耗时（毫秒）
    /// </summary>
    property ElapsedMilliseconds: Int64 read GetElapsedMilliseconds;
    
    /// <summary>
    /// 是否正在运行
    /// </summary>
    property IsRunning: Boolean read FIsRunning;
  end;
  
  /// <summary>
  /// 处理时间测量器
  /// </summary>
  TEncodingTimeMeasurer = class
  private
    FLogCallback: TProc<string>;
    FRecords: TList<TTimeMeasureRecord>;
    FActiveSessions: TDictionary<string, TTimeMeasureSession>;
    
    procedure Log(const Msg: string);
    function GetMeasureTypeName(MeasureType: TTimeMeasureType): string;
  public
    constructor Create(ALogCallback: TProc<string> = nil);
    destructor Destroy; override;
    
    /// <summary>
    /// 开始测量
    /// </summary>
    function StartMeasure(const OperationName: string; MeasureType: TTimeMeasureType = tmtTotal): TTimeMeasureSession;
    
    /// <summary>
    /// 停止测量
    /// </summary>
    function StopMeasure(const OperationName: string): TTimeMeasureRecord;
    
    /// <summary>
    /// 添加测量记录
    /// </summary>
    procedure AddRecord(const Record: TTimeMeasureRecord);
    
    /// <summary>
    /// 获取测量记录
    /// </summary>
    function GetRecords: TArray<TTimeMeasureRecord>;
    
    /// <summary>
    /// 获取指定操作的测量记录
    /// </summary>
    function GetRecordsByOperation(const OperationName: string): TArray<TTimeMeasureRecord>;
    
    /// <summary>
    /// 获取指定类型的测量记录
    /// </summary>
    function GetRecordsByType(MeasureType: TTimeMeasureType): TArray<TTimeMeasureRecord>;
    
    /// <summary>
    /// 清除测量记录
    /// </summary>
    procedure ClearRecords;
    
    /// <summary>
    /// 生成时间测量报告
    /// </summary>
    function GenerateReport: string;
    
    /// <summary>
    /// 保存时间测量报告到文件
    /// </summary>
    procedure SaveReportToFile(const FilePath: string);
    
    /// <summary>
    /// 日志回调
    /// </summary>
    property LogCallback: TProc<string> read FLogCallback write FLogCallback;
  end;

implementation

uses
  System.DateUtils, System.Math, System.IOUtils;

{ TTimeMeasureRecord }

constructor TTimeMeasureRecord.Create(const AOperationName: string; AMeasureType: TTimeMeasureType;
  AStartTime, AEndTime: TDateTime; AElapsedMilliseconds: Int64);
begin
  OperationName := AOperationName;
  MeasureType := AMeasureType;
  StartTime := AStartTime;
  EndTime := AEndTime;
  ElapsedMilliseconds := AElapsedMilliseconds;
end;

{ TTimeMeasureSession }

constructor TTimeMeasureSession.Create(const AOperationName: string; AMeasureType: TTimeMeasureType);
begin
  inherited Create;
  FOperationName := AOperationName;
  FMeasureType := AMeasureType;
  FStopwatch := TStopwatch.Create;
  FIsRunning := False;
end;

function TTimeMeasureSession.CreateRecord: TTimeMeasureRecord;
var
  EndTime: TDateTime;
begin
  if FIsRunning then
    EndTime := Now
  else
    EndTime := FStartTime + FStopwatch.Elapsed;
  
  Result := TTimeMeasureRecord.Create(
    FOperationName, FMeasureType, FStartTime, EndTime, GetElapsedMilliseconds);
end;

function TTimeMeasureSession.GetElapsedMilliseconds: Int64;
begin
  Result := FStopwatch.ElapsedMilliseconds;
end;

procedure TTimeMeasureSession.Reset;
begin
  FStopwatch.Reset;
  FIsRunning := False;
end;

procedure TTimeMeasureSession.Start;
begin
  if not FIsRunning then
  begin
    FStartTime := Now;
    FStopwatch.Reset;
    FStopwatch.Start;
    FIsRunning := True;
  end;
end;

procedure TTimeMeasureSession.Stop;
begin
  if FIsRunning then
  begin
    FStopwatch.Stop;
    FIsRunning := False;
  end;
end;

{ TEncodingTimeMeasurer }

constructor TEncodingTimeMeasurer.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := ALogCallback;
  FRecords := TList<TTimeMeasureRecord>.Create;
  FActiveSessions := TDictionary<string, TTimeMeasureSession>.Create;
end;

destructor TEncodingTimeMeasurer.Destroy;
var
  Session: TTimeMeasureSession;
begin
  // 停止所有活动会话
  for Session in FActiveSessions.Values do
  begin
    Session.Stop;
    Session.Free;
  end;
  
  FActiveSessions.Free;
  FRecords.Free;
  inherited;
end;

procedure TEncodingTimeMeasurer.AddRecord(const Record: TTimeMeasureRecord);
begin
  FRecords.Add(Record);
  
  Log(Format('添加时间测量记录: %s (%s), 耗时=%d毫秒', 
    [Record.OperationName, GetMeasureTypeName(Record.MeasureType), Record.ElapsedMilliseconds]));
end;

procedure TEncodingTimeMeasurer.ClearRecords;
begin
  FRecords.Clear;
  Log('清除时间测量记录');
end;

function TEncodingTimeMeasurer.GenerateReport: string;
var
  SB: TStringBuilder;
  Record: TTimeMeasureRecord;
  OperationStats: TDictionary<string, TDictionary<TTimeMeasureType, TList<TTimeMeasureRecord>>>;
  TypeStats: TDictionary<TTimeMeasureType, TList<TTimeMeasureRecord>>;
  OperationName: string;
  MeasureType: TTimeMeasureType;
  RecordsList: TList<TTimeMeasureRecord>;
  TotalTime, AvgTime, MinTime, MaxTime: Int64;
  I: Integer;
begin
  SB := TStringBuilder.Create;
  OperationStats := TDictionary<string, TDictionary<TTimeMeasureType, TList<TTimeMeasureRecord>>>.Create;
  TypeStats := TDictionary<TTimeMeasureType, TList<TTimeMeasureRecord>>.Create;
  
  try
    SB.AppendLine('# 处理时间测量报告');
    SB.AppendLine('');
    SB.AppendLine('生成时间: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    SB.AppendLine('');
    
    // 初始化统计数据
    for MeasureType := Low(TTimeMeasureType) to High(TTimeMeasureType) do
      TypeStats.Add(MeasureType, TList<TTimeMeasureRecord>.Create);
    
    // 按操作和类型分组
    for Record in FRecords do
    begin
      // 按类型分组
      TypeStats[Record.MeasureType].Add(Record);
      
      // 按操作和类型分组
      var TypeDict: TDictionary<TTimeMeasureType, TList<TTimeMeasureRecord>>;
      if not OperationStats.TryGetValue(Record.OperationName, TypeDict) then
      begin
        TypeDict := TDictionary<TTimeMeasureType, TList<TTimeMeasureRecord>>.Create;
        for MeasureType := Low(TTimeMeasureType) to High(TTimeMeasureType) do
          TypeDict.Add(MeasureType, TList<TTimeMeasureRecord>.Create);
        
        OperationStats.Add(Record.OperationName, TypeDict);
      end;
      
      TypeDict[Record.MeasureType].Add(Record);
    end;
    
    // 总体统计
    SB.AppendLine('## 1. 总体统计');
    SB.AppendLine('');
    SB.AppendLine(Format('- 记录数: %d', [FRecords.Count]));
    SB.AppendLine(Format('- 操作数: %d', [OperationStats.Count]));
    SB.AppendLine('');
    
    // 按测量类型统计
    SB.AppendLine('## 2. 按测量类型统计');
    SB.AppendLine('');
    
    for MeasureType := Low(TTimeMeasureType) to High(TTimeMeasureType) do
    begin
      RecordsList := TypeStats[MeasureType];
      
      if RecordsList.Count > 0 then
      begin
        SB.AppendLine(Format('### 2.%d %s', [Ord(MeasureType) + 1, GetMeasureTypeName(MeasureType)]));
        SB.AppendLine('');
        
        // 计算统计数据
        TotalTime := 0;
        MinTime := High(Int64);
        MaxTime := 0;
        
        for Record in RecordsList do
        begin
          TotalTime := TotalTime + Record.ElapsedMilliseconds;
          MinTime := Min(MinTime, Record.ElapsedMilliseconds);
          MaxTime := Max(MaxTime, Record.ElapsedMilliseconds);
        end;
        
        AvgTime := TotalTime div RecordsList.Count;
        
        SB.AppendLine(Format('- 记录数: %d', [RecordsList.Count]));
        SB.AppendLine(Format('- 总时间: %d 毫秒', [TotalTime]));
        SB.AppendLine(Format('- 平均时间: %d 毫秒', [AvgTime]));
        SB.AppendLine(Format('- 最小时间: %d 毫秒', [MinTime]));
        SB.AppendLine(Format('- 最大时间: %d 毫秒', [MaxTime]));
        SB.AppendLine('');
      end;
    end;
    
    // 按操作统计
    SB.AppendLine('## 3. 按操作统计');
    SB.AppendLine('');
    
    I := 1;
    for OperationName in OperationStats.Keys do
    begin
      var TypeDict := OperationStats[OperationName];
      
      SB.AppendLine(Format('### 3.%d %s', [I, OperationName]));
      SB.AppendLine('');
      
      // 计算总时间
      var TotalRecords := 0;
      var OperationTotalTime := 0;
      
      for MeasureType := Low(TTimeMeasureType) to High(TTimeMeasureType) do
      begin
        RecordsList := TypeDict[MeasureType];
        TotalRecords := TotalRecords + RecordsList.Count;
        
        for Record in RecordsList do
          OperationTotalTime := OperationTotalTime + Record.ElapsedMilliseconds;
      end;
      
      SB.AppendLine(Format('- 记录数: %d', [TotalRecords]));
      SB.AppendLine(Format('- 总时间: %d 毫秒', [OperationTotalTime]));
      SB.AppendLine('');
      
      // 按类型统计
      SB.AppendLine('| 测量类型 | 记录数 | 总时间(毫秒) | 平均时间(毫秒) | 最小时间(毫秒) | 最大时间(毫秒) |');
      SB.AppendLine('|----------|--------|--------------|----------------|----------------|----------------|');
      
      for MeasureType := Low(TTimeMeasureType) to High(TTimeMeasureType) do
      begin
        RecordsList := TypeDict[MeasureType];
        
        if RecordsList.Count > 0 then
        begin
          // 计算统计数据
          TotalTime := 0;
          MinTime := High(Int64);
          MaxTime := 0;
          
          for Record in RecordsList do
          begin
            TotalTime := TotalTime + Record.ElapsedMilliseconds;
            MinTime := Min(MinTime, Record.ElapsedMilliseconds);
            MaxTime := Max(MaxTime, Record.ElapsedMilliseconds);
          end;
          
          AvgTime := TotalTime div RecordsList.Count;
          
          SB.AppendLine(Format('| %s | %d | %d | %d | %d | %d |', 
            [GetMeasureTypeName(MeasureType), RecordsList.Count, TotalTime, AvgTime, MinTime, MaxTime]));
        end;
      end;
      
      SB.AppendLine('');
      Inc(I);
    end;
    
    // 详细记录
    SB.AppendLine('## 4. 详细记录');
    SB.AppendLine('');
    SB.AppendLine('| 操作 | 测量类型 | 开始时间 | 结束时间 | 耗时(毫秒) |');
    SB.AppendLine('|------|----------|----------|----------|------------|');
    
    for I := 0 to Min(99, FRecords.Count - 1) do
    begin
      Record := FRecords[I];
      
      SB.AppendLine(Format('| %s | %s | %s | %s | %d |', 
        [Record.OperationName, 
         GetMeasureTypeName(Record.MeasureType), 
         FormatDateTime('hh:nn:ss.zzz', Record.StartTime), 
         FormatDateTime('hh:nn:ss.zzz', Record.EndTime), 
         Record.ElapsedMilliseconds]));
    end;
    
    // 如果记录太多，显示省略信息
    if FRecords.Count > 100 then
      SB.AppendLine(Format('| ... | ... | ... | ... | ... | 还有 %d 条记录未显示 |', [FRecords.Count - 100]));
    
    SB.AppendLine('');
    
    // 性能建议
    SB.AppendLine('## 5. 性能建议');
    SB.AppendLine('');
    
    // 查找最耗时的操作
    var MaxAvgTime := 0;
    var SlowestOperation := '';
    var SlowestType := tmtTotal;
    
    for OperationName in OperationStats.Keys do
    begin
      var TypeDict := OperationStats[OperationName];
      
      for MeasureType := Low(TTimeMeasureType) to High(TTimeMeasureType) do
      begin
        RecordsList := TypeDict[MeasureType];
        
        if RecordsList.Count > 0 then
        begin
          TotalTime := 0;
          for Record in RecordsList do
            TotalTime := TotalTime + Record.ElapsedMilliseconds;
          
          AvgTime := TotalTime div RecordsList.Count;
          
          if AvgTime > MaxAvgTime then
          begin
            MaxAvgTime := AvgTime;
            SlowestOperation := OperationName;
            SlowestType := MeasureType;
          end;
        end;
      end;
    end;
    
    if SlowestOperation <> '' then
    begin
      SB.AppendLine(Format('- 最耗时的操作是 "%s" 的 "%s"，平均耗时 %d 毫秒。', 
        [SlowestOperation, GetMeasureTypeName(SlowestType), MaxAvgTime]));
      SB.AppendLine('  建议优先优化此操作的性能。');
      SB.AppendLine('');
    end;
    
    // 文件IO优化建议
    var FileIORecords := TypeStats[tmtFileIO];
    if FileIORecords.Count > 0 then
    begin
      TotalTime := 0;
      for Record in FileIORecords do
        TotalTime := TotalTime + Record.ElapsedMilliseconds;
      
      AvgTime := TotalTime div FileIORecords.Count;
      
      if AvgTime > 100 then
      begin
        SB.AppendLine('- 文件IO操作平均耗时较长，建议考虑以下优化：');
        SB.AppendLine('  - 使用缓冲读写');
        SB.AppendLine('  - 减少文件打开/关闭次数');
        SB.AppendLine('  - 使用内存映射文件处理大文件');
        SB.AppendLine('');
      end;
    end;
    
    // 编码处理优化建议
    var EncodingRecords := TypeStats[tmtEncoding];
    if EncodingRecords.Count > 0 then
    begin
      TotalTime := 0;
      for Record in EncodingRecords do
        TotalTime := TotalTime + Record.ElapsedMilliseconds;
      
      AvgTime := TotalTime div EncodingRecords.Count;
      
      if AvgTime > 50 then
      begin
        SB.AppendLine('- 编码处理平均耗时较长，建议考虑以下优化：');
        SB.AppendLine('  - 使用更高效的编码算法');
        SB.AppendLine('  - 优化字符串处理逻辑');
        SB.AppendLine('  - 考虑使用并行处理');
        SB.AppendLine('');
      end;
    end;
    
    Result := SB.ToString;
  finally
    // 清理资源
    for RecordsList in TypeStats.Values do
      RecordsList.Free;
    
    TypeStats.Free;
    
    for var TypeDict in OperationStats.Values do
    begin
      for RecordsList in TypeDict.Values do
        RecordsList.Free;
      
      TypeDict.Free;
    end;
    
    OperationStats.Free;
    SB.Free;
  end;
end;

function TEncodingTimeMeasurer.GetMeasureTypeName(MeasureType: TTimeMeasureType): string;
begin
  case MeasureType of
    tmtTotal: Result := '总时间';
    tmtFileIO: Result := '文件IO';
    tmtEncoding: Result := '编码处理';
    tmtDetection: Result := '编码检测';
    tmtConversion: Result := '编码转换';
    tmtUI: Result := 'UI更新';
    tmtOther: Result := '其他';
  else
    Result := '未知';
  end;
end;

function TEncodingTimeMeasurer.GetRecords: TArray<TTimeMeasureRecord>;
begin
  Result := FRecords.ToArray;
end;

function TEncodingTimeMeasurer.GetRecordsByOperation(const OperationName: string): TArray<TTimeMeasureRecord>;
var
  ResultList: TList<TTimeMeasureRecord>;
  Record: TTimeMeasureRecord;
begin
  ResultList := TList<TTimeMeasureRecord>.Create;
  try
    for Record in FRecords do
    begin
      if Record.OperationName = OperationName then
        ResultList.Add(Record);
    end;
    
    Result := ResultList.ToArray;
  finally
    ResultList.Free;
  end;
end;

function TEncodingTimeMeasurer.GetRecordsByType(MeasureType: TTimeMeasureType): TArray<TTimeMeasureRecord>;
var
  ResultList: TList<TTimeMeasureRecord>;
  Record: TTimeMeasureRecord;
begin
  ResultList := TList<TTimeMeasureRecord>.Create;
  try
    for Record in FRecords do
    begin
      if Record.MeasureType = MeasureType then
        ResultList.Add(Record);
    end;
    
    Result := ResultList.ToArray;
  finally
    ResultList.Free;
  end;
end;

procedure TEncodingTimeMeasurer.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

procedure TEncodingTimeMeasurer.SaveReportToFile(const FilePath: string);
var
  Report: string;
begin
  Report := GenerateReport;
  TFile.WriteAllText(FilePath, Report);
  
  Log(Format('保存时间测量报告到文件: %s', [FilePath]));
end;

function TEncodingTimeMeasurer.StartMeasure(const OperationName: string; MeasureType: TTimeMeasureType): TTimeMeasureSession;
var
  SessionKey: string;
  Session: TTimeMeasureSession;
begin
  // 创建会话键
  SessionKey := Format('%s_%d', [OperationName, Ord(MeasureType)]);
  
  // 检查是否已存在会话
  if FActiveSessions.TryGetValue(SessionKey, Session) then
  begin
    // 如果会话已存在但未运行，则重新启动
    if not Session.IsRunning then
      Session.Start;
  end
  else
  begin
    // 创建新会话
    Session := TTimeMeasureSession.Create(OperationName, MeasureType);
    Session.Start;
    FActiveSessions.Add(SessionKey, Session);
  end;
  
  Log(Format('开始测量: %s (%s)', [OperationName, GetMeasureTypeName(MeasureType)]));
  
  Result := Session;
end;

function TEncodingTimeMeasurer.StopMeasure(const OperationName: string): TTimeMeasureRecord;
var
  SessionKey: string;
  Session: TTimeMeasureSession;
  MeasureType: TTimeMeasureType;
begin
  // 查找并停止所有与操作名称匹配的会话
  for MeasureType := Low(TTimeMeasureType) to High(TTimeMeasureType) do
  begin
    SessionKey := Format('%s_%d', [OperationName, Ord(MeasureType)]);
    
    if FActiveSessions.TryGetValue(SessionKey, Session) then
    begin
      // 停止会话
      Session.Stop;
      
      // 创建记录
      Result := Session.CreateRecord;
      
      // 添加到记录列表
      AddRecord(Result);
      
      // 从活动会话中移除
      FActiveSessions.Remove(SessionKey);
      Session.Free;
      
      Log(Format('停止测量: %s (%s), 耗时=%d毫秒', 
        [OperationName, GetMeasureTypeName(MeasureType), Result.ElapsedMilliseconds]));
      
      // 返回总时间记录
      if MeasureType = tmtTotal then
        Exit;
    end;
  end;
  
  // 如果没有找到总时间记录，则返回空记录
  Result := TTimeMeasureRecord.Create('', tmtTotal, 0, 0, 0);
end;

end.
