unit SmartFileStream;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  SmartMemoryPool;

type
  // 文件流处理状态
  TFileProcessingState = (
    fpsIdle,        // 空闲状态
    fpsReading,     // 读取中
    fpsWriting,     // 写入中
    fpsProcessing,  // 处理中
    fpsComplete     // 完成
  );

  // 区块处理结果
  TChunkProcessResult = record
    Success: Boolean;         // 处理是否成功
    ErrorCode: Integer;       // 错误码
    ErrorMessage: string;     // 错误信息
    BytesProcessed: Int64;    // 处理的字节数
    ChunkIndex: Integer;      // 区块索引
    ElapsedTime: TDateTime;   // 处理耗时
  end;

  // 文件处理进度信息
  TFileProcessProgress = record
    TotalBytes: Int64;          // 总字节数
    ProcessedBytes: Int64;      // 已处理字节数
    TotalChunks: Integer;       // 总区块数
    ProcessedChunks: Integer;   // 已处理区块数
    CurrentChunkIndex: Integer; // 当前处理区块索引
    State: TFileProcessingState; // 当前状态
    ElapsedTime: TDateTime;     // 已用时间
    EstimatedTimeRemaining: TDateTime; // 预计剩余时间
    PercentComplete: Double;    // 完成百分比

    // 构造初始化
    constructor Create(ATotalBytes: Int64);
  end;

  // 区块处理函数类型
  TChunkProcessorFunc = reference to function(
    const ChunkData: Pointer; 
    ChunkSize: Integer; 
    ChunkIndex: Integer;
    var OutputData: Pointer;
    var OutputSize: Integer): TChunkProcessResult;

  // 处理进度回调函数
  TProgressCallback = reference to procedure(const Progress: TFileProcessProgress);

  // 错误回调函数
  TErrorCallback = reference to procedure(
    const ErrorMessage: string; 
    ErrorCode: Integer; 
    ChunkIndex: Integer);

  // 智能大文件流处理器
  TSmartFileStream = class
  private
    // 内存管理
    FMemoryPool: IMemoryPool;
    FChunkSize: Integer;
    FMaxConcurrentChunks: Integer;
    FOwnMemoryPool: Boolean;
    
    // 文件管理
    FSourceFile: string;
    FTargetFile: string;
    FTempFile: string;
    FSourceStream: TStream;
    FTargetStream: TStream;
    FOwnStreams: Boolean;
    
    // 状态管理
    FState: TFileProcessingState;
    FProgress: TFileProcessProgress;
    FCancelRequested: Boolean;
    FErrorOccurred: Boolean;
    FLastError: string;
    FLastErrorCode: Integer;
    
    // 回调函数
    FOnProgress: TProgressCallback;
    FOnError: TErrorCallback;
    FOnComplete: TNotifyEvent;
    
    // 缓存的区块信息
    FChunks: TList<TMemoryBlockHandle>;
    FChunkResults: TDictionary<Integer, TChunkProcessResult>;
    
    // 内部方法
    procedure UpdateProgress(BytesProcessed: Int64; ChunkIndex: Integer);
    procedure ReportError(const ErrorMessage: string; ErrorCode: Integer; ChunkIndex: Integer);
    procedure ReportComplete;
    function CreateTempFileName: string;
    procedure CleanupChunks;
  public
    // 构造函数
    constructor Create(AChunkSize: Integer = 1024 * 1024; // 1MB
                      AMaxConcurrentChunks: Integer = 10;
                      AMemoryPool: IMemoryPool = nil); overload;
    constructor Create(const ASourceFile, ATargetFile: string;
                      AChunkSize: Integer = 1024 * 1024;
                      AMaxConcurrentChunks: Integer = 10;
                      AMemoryPool: IMemoryPool = nil); overload;
    constructor Create(ASourceStream, ATargetStream: TStream;
                      AOwnStreams: Boolean = False;
                      AChunkSize: Integer = 1024 * 1024;
                      AMaxConcurrentChunks: Integer = 10;
                      AMemoryPool: IMemoryPool = nil); overload;
    destructor Destroy; override;
    
    // 文件路径设置
    procedure SetFiles(const ASourceFile, ATargetFile: string);
    
    // 流设置
    procedure SetStreams(ASourceStream, ATargetStream: TStream; AOwnStreams: Boolean = False);
    
    // 区块大小设置
    procedure SetChunkSize(AChunkSize: Integer);
    
    // 取消处理
    procedure Cancel;
    
    // 同步处理
    function ProcessFile(const Processor: TChunkProcessorFunc): Boolean;
    
    // 异步处理（简单实现，实际项目中可能需要使用线程池或任务队列）
    procedure ProcessFileAsync(const Processor: TChunkProcessorFunc);
    
    // 属性
    property ChunkSize: Integer read FChunkSize write SetChunkSize;
    property MaxConcurrentChunks: Integer read FMaxConcurrentChunks write FMaxConcurrentChunks;
    property State: TFileProcessingState read FState;
    property Progress: TFileProcessProgress read FProgress;
    property MemoryPool: IMemoryPool read FMemoryPool;
    property CancelRequested: Boolean read FCancelRequested;
    property ErrorOccurred: Boolean read FErrorOccurred;
    property LastError: string read FLastError;
    property LastErrorCode: Integer read FLastErrorCode;
    
    // 事件
    property OnProgress: TProgressCallback read FOnProgress write FOnProgress;
    property OnError: TErrorCallback read FOnError write FOnError;
    property OnComplete: TNotifyEvent read FOnComplete write FOnComplete;
  end;

implementation

uses
  System.DateUtils, System.Math, System.Threading, System.IOUtils;

{ TFileProcessProgress }

constructor TFileProcessProgress.Create(ATotalBytes: Int64);
begin
  TotalBytes := ATotalBytes;
  ProcessedBytes := 0;
  TotalChunks := 0;
  ProcessedChunks := 0;
  CurrentChunkIndex := -1;
  State := fpsIdle;
  ElapsedTime := 0;
  EstimatedTimeRemaining := 0;
  PercentComplete := 0;
end;

{ TSmartFileStream }

constructor TSmartFileStream.Create(AChunkSize, AMaxConcurrentChunks: Integer;
  AMemoryPool: IMemoryPool);
begin
  inherited Create;
  
  // 初始化内存池
  if AMemoryPool = nil then
  begin
    FMemoryPool := GlobalMemoryPool;
    FOwnMemoryPool := False;
  end
  else
  begin
    FMemoryPool := AMemoryPool;
    FOwnMemoryPool := False;
  end;
  
  // 初始化参数
  FChunkSize := Max(65536, AChunkSize); // 最小64KB
  FMaxConcurrentChunks := Max(1, AMaxConcurrentChunks);
  
  // 初始化状态
  FState := fpsIdle;
  FCancelRequested := False;
  FErrorOccurred := False;
  FLastError := '';
  FLastErrorCode := 0;
  
  // 初始化缓存
  FChunks := TList<TMemoryBlockHandle>.Create;
  FChunkResults := TDictionary<Integer, TChunkProcessResult>.Create;
  
  // 初始化进度信息
  FProgress := TFileProcessProgress.Create(0);
end;

constructor TSmartFileStream.Create(const ASourceFile, ATargetFile: string;
  AChunkSize, AMaxConcurrentChunks: Integer; AMemoryPool: IMemoryPool);
begin
  Create(AChunkSize, AMaxConcurrentChunks, AMemoryPool);
  SetFiles(ASourceFile, ATargetFile);
end;

constructor TSmartFileStream.Create(ASourceStream, ATargetStream: TStream;
  AOwnStreams: Boolean; AChunkSize, AMaxConcurrentChunks: Integer;
  AMemoryPool: IMemoryPool);
begin
  Create(AChunkSize, AMaxConcurrentChunks, AMemoryPool);
  SetStreams(ASourceStream, ATargetStream, AOwnStreams);
end;

destructor TSmartFileStream.Destroy;
begin
  // 清理资源
  CleanupChunks;
  
  // 释放流
  if FOwnStreams then
  begin
    FreeAndNil(FSourceStream);
    FreeAndNil(FTargetStream);
  end;
  
  // 删除临时文件
  if FileExists(FTempFile) then
    TFile.Delete(FTempFile);
  
  // 释放集合
  FreeAndNil(FChunks);
  FreeAndNil(FChunkResults);
  
  inherited;
end;

procedure TSmartFileStream.SetFiles(const ASourceFile, ATargetFile: string);
begin
  // 设置文件路径
  FSourceFile := ASourceFile;
  FTargetFile := ATargetFile;
  
  // 释放现有流
  if FOwnStreams then
  begin
    FreeAndNil(FSourceStream);
    FreeAndNil(FTargetStream);
  end;
  
  // 创建新流
  FSourceStream := TFileStream.Create(FSourceFile, fmOpenRead or fmShareDenyWrite);
  
  // 目标文件可能不存在，需要创建
  if FileExists(FTargetFile) then
    FTargetStream := TFileStream.Create(FTargetFile, fmCreate or fmShareDenyWrite)
  else
    FTargetStream := TFileStream.Create(FTargetFile, fmCreate);
    
  // 设置拥有流的标志
  FOwnStreams := True;
  
  // 更新进度信息
  FProgress := TFileProcessProgress.Create(FSourceStream.Size);
  FProgress.TotalChunks := Ceil(FSourceStream.Size / FChunkSize);
end;

procedure TSmartFileStream.SetStreams(ASourceStream, ATargetStream: TStream;
  AOwnStreams: Boolean);
begin
  // 释放现有流
  if FOwnStreams then
  begin
    FreeAndNil(FSourceStream);
    FreeAndNil(FTargetStream);
  end;
  
  // 设置新流
  FSourceStream := ASourceStream;
  FTargetStream := ATargetStream;
  FOwnStreams := AOwnStreams;
  
  // 清空文件路径
  FSourceFile := '';
  FTargetFile := '';
  
  // 更新进度信息
  FProgress := TFileProcessProgress.Create(FSourceStream.Size);
  FProgress.TotalChunks := Ceil(FSourceStream.Size / FChunkSize);
end;

procedure TSmartFileStream.SetChunkSize(AChunkSize: Integer);
begin
  // 确保区块大小有效
  FChunkSize := Max(65536, AChunkSize); // 最小64KB
  
  // 更新总区块数
  if FSourceStream <> nil then
    FProgress.TotalChunks := Ceil(FSourceStream.Size / FChunkSize);
end;

procedure TSmartFileStream.Cancel;
begin
  FCancelRequested := True;
end;

procedure TSmartFileStream.CleanupChunks;
var
  I: Integer;
  Handle: TMemoryBlockHandle;
begin
  // 释放所有内存块
  for I := 0 to FChunks.Count - 1 do
  begin
    Handle := FChunks[I];
    if Handle <> 0 then
      FMemoryPool.Release(Handle);
  end;
  
  // 清空列表
  FChunks.Clear;
  FChunkResults.Clear;
end;

function TSmartFileStream.CreateTempFileName: string;
begin
  Result := TPath.GetTempFileName;
end;

procedure TSmartFileStream.UpdateProgress(BytesProcessed: Int64; ChunkIndex: Integer);
var
  ElapsedSecs: Double;
  Remaining: Double;
begin
  // 更新进度信息
  Inc(FProgress.ProcessedBytes, BytesProcessed);
  Inc(FProgress.ProcessedChunks);
  FProgress.CurrentChunkIndex := ChunkIndex;
  
  // 计算完成百分比
  if FProgress.TotalBytes > 0 then
    FProgress.PercentComplete := (FProgress.ProcessedBytes / FProgress.TotalBytes) * 100
  else
    FProgress.PercentComplete := 0;
    
  // 计算预计剩余时间
  ElapsedSecs := MilliSecondsBetween(Now, FProgress.ElapsedTime) / 1000;
  
  if (FProgress.ProcessedBytes > 0) and (ElapsedSecs > 0) then
  begin
    Remaining := (ElapsedSecs / FProgress.ProcessedBytes) * 
                (FProgress.TotalBytes - FProgress.ProcessedBytes);
                
    FProgress.EstimatedTimeRemaining := Remaining / SecsPerDay;
  end;
  
  // 调用进度回调
  if Assigned(FOnProgress) then
    FOnProgress(FProgress);
end;

procedure TSmartFileStream.ReportError(const ErrorMessage: string; ErrorCode: Integer;
  ChunkIndex: Integer);
begin
  // 更新错误状态
  FErrorOccurred := True;
  FLastError := ErrorMessage;
  FLastErrorCode := ErrorCode;
  
  // 调用错误回调
  if Assigned(FOnError) then
    FOnError(ErrorMessage, ErrorCode, ChunkIndex);
end;

procedure TSmartFileStream.ReportComplete;
begin
  // 更新状态
  FState := fpsComplete;
  
  // 调用完成回调
  if Assigned(FOnComplete) then
    FOnComplete(Self);
end;

function TSmartFileStream.ProcessFile(const Processor: TChunkProcessorFunc): Boolean;
var
  Buffer: TMemoryBlockHandle;
  OutputHandle: TMemoryBlockHandle;
  ChunkIndex: Integer;
  BytesRead: Integer;
  StartTime: TDateTime;
  Result: TChunkProcessResult;
  ChunkData, OutputData: Pointer;
  OutputSize: Integer;
begin
  Result := False;
  
  // 检查参数
  if (FSourceStream = nil) or (FTargetStream = nil) or (not Assigned(Processor)) then
    Exit;
    
  try
    // 初始化状态
    FState := fpsReading;
    FCancelRequested := False;
    FErrorOccurred := False;
    FProgress.State := fpsReading;
    FProgress.ElapsedTime := Now;
    
    // 清理之前的区块
    CleanupChunks;
    
    // 重置流位置
    FSourceStream.Position := 0;
    FTargetStream.Position := 0;
    
    // 开始处理
    ChunkIndex := 0;
    StartTime := Now;
    
    while (FSourceStream.Position < FSourceStream.Size) and (not FCancelRequested) do
    begin
      // 分配内存
      Buffer := FMemoryPool.Allocate(FChunkSize);
      
      // 读取区块
      FState := fpsReading;
      FProgress.State := fpsReading;
      ChunkData := FMemoryPool.GetBlockData(Buffer);
      BytesRead := FSourceStream.Read(ChunkData^, FChunkSize);
      
      // 处理区块
      if BytesRead > 0 then
      begin
        FState := fpsProcessing;
        FProgress.State := fpsProcessing;
        
        // 初始化输出参数
        OutputData := nil;
        OutputSize := 0;
        
        // 调用处理函数
        Result := Processor(ChunkData, BytesRead, ChunkIndex, OutputData, OutputSize);
        
        // 检查结果
        if not Result.Success then
        begin
          ReportError(Result.ErrorMessage, Result.ErrorCode, ChunkIndex);
          Break;
        end;
        
        // 将处理结果写入目标流
        FState := fpsWriting;
        FProgress.State := fpsWriting;
        
        if OutputData <> nil then
        begin
          FTargetStream.Write(OutputData^, OutputSize);
          
          // 如果处理函数分配了内存，释放它
          if OutputData <> ChunkData then
          begin
            // 将其转换为内存块句柄并释放
            OutputHandle := FMemoryPool.Allocate(0); // 仅用于初始化
            PPointer(@OutputHandle)^ := OutputData;
            FMemoryPool.Release(OutputHandle);
          end;
        end
        else
        begin
          // 如果没有输出数据，直接写入原数据
          FTargetStream.Write(ChunkData^, BytesRead);
        end;
        
        // 更新进度
        UpdateProgress(BytesRead, ChunkIndex);
        
        // 保存处理结果
        FChunkResults.Add(ChunkIndex, Result);
      end;
      
      // 释放内存
      FMemoryPool.Release(Buffer);
      
      // 递增区块索引
      Inc(ChunkIndex);
    end;
    
    // 完成处理
    if not FCancelRequested and not FErrorOccurred then
    begin
      Result := True;
      ReportComplete;
    end;
    
  except
    on E: Exception do
    begin
      ReportError(E.Message, E.HelpContext, ChunkIndex);
      Result := False;
    end;
  end;
end;

procedure TSmartFileStream.ProcessFileAsync(const Processor: TChunkProcessorFunc);
begin
  // 创建异步任务
  TTask.Run(
    procedure
    begin
      ProcessFile(Processor);
    end
  );
end;

end. 