unit LargeFileProcessor;

interface

uses
  SysUtils, Classes, Generics.Collections, Windows, SyncObjs;

const
  /// <summary>
  /// 默认缓冲块大小：1 MB
  /// </summary>
  DEFAULT_BLOCK_SIZE = 1024 * 1024;
  
  /// <summary>
  /// 默认最大内存使用：256 MB
  /// </summary>
  DEFAULT_MAX_MEMORY = 256 * 1024 * 1024;

type
  /// <summary>
  /// 流处理回调函数
  /// </summary>
  TStreamProcessCallback = reference to function(
    const Buffer: Pointer;
    BufferSize: Integer;
    BlockIndex: Integer;
    IsLastBlock: Boolean): Boolean;
  
  /// <summary>
  /// 处理结果
  /// </summary>
  TProcessResult = record
    /// <summary>
    /// 是否成功
    /// </summary>
    Success: Boolean;
    
    /// <summary>
    /// 处理的总字节数
    /// </summary>
    TotalBytesProcessed: Int64;
    
    /// <summary>
    /// 处理的块数
    /// </summary>
    BlocksProcessed: Integer;
    
    /// <summary>
    /// 错误消息（如果有）
    /// </summary>
    ErrorMessage: string;
    
    /// <summary>
    /// 处理时间（毫秒）
    /// </summary>
    ProcessTimeMs: Int64;
    
    /// <summary>
    /// 峰值内存使用（字节）
    /// </summary>
    PeakMemoryUsed: Int64;
  end;
  
  /// <summary>
  /// 内存使用级别
  /// </summary>
  TMemoryUsageLevel = (
    /// <summary>
    /// 最低内存使用，但最慢性能
    /// </summary>
    mulMinimum,
    
    /// <summary>
    /// 低内存使用
    /// </summary>
    mulLow,
    
    /// <summary>
    /// 平衡内存使用和性能
    /// </summary>
    mulBalanced,
    
    /// <summary>
    /// 高性能，但高内存使用
    /// </summary>
    mulHigh,
    
    /// <summary>
    /// 最高性能，最高内存使用
    /// </summary>
    mulMaximum
  );
  
  /// <summary>
  /// 大文件处理器异常
  /// </summary>
  ELargeFileProcessorError = class(Exception);
  
  /// <summary>
  /// 进度事件信息
  /// </summary>
  TProgressInfo = record
    /// <summary>
    /// 当前位置
    /// </summary>
    Position: Int64;
    
    /// <summary>
    /// 总大小
    /// </summary>
    Size: Int64;
    
    /// <summary>
    /// 处理的块索引
    /// </summary>
    BlockIndex: Integer;
    
    /// <summary>
    /// 当前处理的百分比 (0-100)
    /// </summary>
    PercentComplete: Byte;
    
    /// <summary>
    /// 估计剩余时间（秒）
    /// </summary>
    EstimatedTimeRemaining: Int64;
    
    /// <summary>
    /// 处理速度（字节/秒）
    /// </summary>
    ProcessingSpeed: Int64;
  end;
  
  /// <summary>
  /// 进度通知事件
  /// </summary>
  TProgressEvent = procedure(Sender: TObject; const Progress: TProgressInfo) of object;
  
  /// <summary>
  /// 大文件处理器
  /// </summary>
  TLargeFileProcessor = class
  private
    FBlockSize: Integer;
    FMaxMemory: Int64;
    FParallelProcessing: Boolean;
    FMemoryUsageLevel: TMemoryUsageLevel;
    FBuffer: Pointer;
    FBufferSize: Integer;
    FCancelled: Boolean;
    FOnProgress: TProgressEvent;
    FProgressInterval: Integer;
    FStartTime: Int64;
    FLastProgressTime: Int64;
    FLastPosition: Int64;
    
    function GetMemoryManagerStats: TMemoryManagerState;
    function CalculateOptimalBlockSize(FileSize: Int64): Integer;
    procedure UpdateProgress(const CurrentPosition, TotalSize: Int64;
                           BlockIndex: Integer);
    function GetFreeSysMemory: Int64;
  protected
    /// <summary>
    /// 处理单个数据块
    /// </summary>
    /// <param name="Buffer">数据缓冲区</param>
    /// <param name="BufferSize">缓冲区大小</param>
    /// <param name="BlockIndex">块索引</param>
    /// <param name="IsLastBlock">是否是最后一个块</param>
    /// <param name="Callback">回调函数</param>
    /// <returns>是否成功处理</returns>
    function ProcessDataBlock(Buffer: Pointer; BufferSize: Integer;
                            BlockIndex: Integer; IsLastBlock: Boolean;
                            Callback: TStreamProcessCallback): Boolean; virtual;
  public
    /// <summary>
    /// 创建大文件处理器
    /// </summary>
    constructor Create;
    
    /// <summary>
    /// 销毁大文件处理器
    /// </summary>
    destructor Destroy; override;
    
    /// <summary>
    /// 处理流数据
    /// </summary>
    /// <param name="Stream">输入流</param>
    /// <param name="Callback">处理回调</param>
    /// <returns>处理结果</returns>
    function ProcessStream(Stream: TStream; Callback: TStreamProcessCallback): TProcessResult;
    
    /// <summary>
    /// 处理文件
    /// </summary>
    /// <param name="FileName">文件名</param>
    /// <param name="Callback">处理回调</param>
    /// <returns>处理结果</returns>
    function ProcessFile(const FileName: string; Callback: TStreamProcessCallback): TProcessResult;
    
    /// <summary>
    /// 复制大文件，优化内存使用
    /// </summary>
    /// <param name="SourceFileName">源文件名</param>
    /// <param name="DestFileName">目标文件名</param>
    /// <param name="Transform">可选的转换回调</param>
    /// <returns>处理结果</returns>
    function CopyLargeFile(const SourceFileName, DestFileName: string;
                          Transform: TStreamProcessCallback = nil): TProcessResult;
    
    /// <summary>
    /// 取消处理操作
    /// </summary>
    procedure Cancel;
    
    /// <summary>
    /// 设置内存使用级别（自动调整块大小）
    /// </summary>
    /// <param name="Level">内存使用级别</param>
    procedure SetMemoryUsageLevel(Level: TMemoryUsageLevel);
    
    /// <summary>
    /// 块大小
    /// </summary>
    property BlockSize: Integer read FBlockSize write FBlockSize;
    
    /// <summary>
    /// 最大内存使用（字节）
    /// </summary>
    property MaxMemory: Int64 read FMaxMemory write FMaxMemory;
    
    /// <summary>
    /// 是否使用并行处理
    /// </summary>
    property ParallelProcessing: Boolean read FParallelProcessing write FParallelProcessing;
    
    /// <summary>
    /// 内存使用级别
    /// </summary>
    property MemoryUsageLevel: TMemoryUsageLevel read FMemoryUsageLevel;
    
    /// <summary>
    /// 进度更新事件
    /// </summary>
    property OnProgress: TProgressEvent read FOnProgress write FOnProgress;
    
    /// <summary>
    /// 进度通知间隔（毫秒）
    /// </summary>
    property ProgressInterval: Integer read FProgressInterval write FProgressInterval;
  end;

implementation

uses
  Math, DateUtils, IOUtils;

{ TLargeFileProcessor }

constructor TLargeFileProcessor.Create;
begin
  inherited Create;
  FBlockSize := DEFAULT_BLOCK_SIZE;
  FMaxMemory := DEFAULT_MAX_MEMORY;
  FParallelProcessing := True;
  FMemoryUsageLevel := mulBalanced;
  FBuffer := nil;
  FBufferSize := 0;
  FCancelled := False;
  FProgressInterval := 250; // 250ms 进度更新间隔
end;

destructor TLargeFileProcessor.Destroy;
begin
  // 确保释放缓冲区
  if FBuffer <> nil then
  begin
    FreeMem(FBuffer);
    FBuffer := nil;
  end;
  
  inherited;
end;

function TLargeFileProcessor.CalculateOptimalBlockSize(FileSize: Int64): Integer;
var
  FreeMem: Int64;
  SystemMem: Int64;
  AvailableMem: Int64;
begin
  // 获取系统可用内存
  FreeMem := GetFreeSysMemory;
  SystemMem := Min(FreeMem div 2, FMaxMemory); // 最多使用可用内存的一半或者最大内存限制
  
  // 根据内存使用级别调整
  case FMemoryUsageLevel of
    mulMinimum: AvailableMem := SystemMem div 8;
    mulLow: AvailableMem := SystemMem div 4;
    mulBalanced: AvailableMem := SystemMem div 2;
    mulHigh: AvailableMem := SystemMem * 3 div 4;
    mulMaximum: AvailableMem := SystemMem;
  end;
  
  // 如果文件很小，直接一次性读取
  if FileSize <= AvailableMem then
    Result := Integer(FileSize)
  else
  begin
    // 计算合适的块大小，确保至少有几个块
    Result := Integer(Min(AvailableMem, FileSize div 10));
    
    // 确保块大小不小于默认值的十分之一
    if Result < (DEFAULT_BLOCK_SIZE div 10) then
      Result := DEFAULT_BLOCK_SIZE div 10;
      
    // 确保块大小不大于最大内存的八分之一（为其他操作预留空间）
    if Result > (AvailableMem div 8) then
      Result := Integer(AvailableMem div 8);
  end;
end;

function TLargeFileProcessor.GetFreeSysMemory: Int64;
var
  MemoryStatus: TMemoryStatusEx;
begin
  MemoryStatus.dwLength := SizeOf(MemoryStatus);
  if GlobalMemoryStatusEx(MemoryStatus) then
    Result := MemoryStatus.ullAvailPhys
  else
    Result := 0;
end;

function TLargeFileProcessor.GetMemoryManagerStats: TMemoryManagerState;
begin
  GetMemoryManagerState(Result);
end;

procedure TLargeFileProcessor.SetMemoryUsageLevel(Level: TMemoryUsageLevel);
begin
  FMemoryUsageLevel := Level;
  
  // 根据级别调整内存参数
  case Level of
    mulMinimum:
      begin
        FBlockSize := 256 * 1024; // 256 KB
        FMaxMemory := 64 * 1024 * 1024; // 64 MB
        FParallelProcessing := False;
      end;
    mulLow:
      begin
        FBlockSize := 512 * 1024; // 512 KB
        FMaxMemory := 128 * 1024 * 1024; // 128 MB
        FParallelProcessing := False;
      end;
    mulBalanced:
      begin
        FBlockSize := DEFAULT_BLOCK_SIZE;
        FMaxMemory := DEFAULT_MAX_MEMORY;
        FParallelProcessing := True;
      end;
    mulHigh:
      begin
        FBlockSize := 2 * 1024 * 1024; // 2 MB
        FMaxMemory := 512 * 1024 * 1024; // 512 MB
        FParallelProcessing := True;
      end;
    mulMaximum:
      begin
        FBlockSize := 4 * 1024 * 1024; // 4 MB
        FMaxMemory := 1024 * 1024 * 1024; // 1 GB
        FParallelProcessing := True;
      end;
  end;
end;

function TLargeFileProcessor.ProcessDataBlock(Buffer: Pointer; 
                                            BufferSize: Integer;
                                            BlockIndex: Integer; 
                                            IsLastBlock: Boolean;
                                            Callback: TStreamProcessCallback): Boolean;
begin
  Result := True;
  
  if Assigned(Callback) then
    Result := Callback(Buffer, BufferSize, BlockIndex, IsLastBlock);
end;

procedure TLargeFileProcessor.UpdateProgress(const CurrentPosition, 
                                           TotalSize: Int64;
                                           BlockIndex: Integer);
var
  CurrentTime: Int64;
  ElapsedTime: Int64;
  TimeFromStart: Int64;
  Progress: TProgressInfo;
  Speed: Int64;
begin
  // 如果没有进度事件或者不需要更新，则退出
  if not Assigned(FOnProgress) then
    Exit;
    
  CurrentTime := GetTickCount64;
  
  // 检查是否需要更新进度（间隔控制）
  if (CurrentTime - FLastProgressTime) < Cardinal(FProgressInterval) then
    Exit;
    
  // 计算进度信息
  FillChar(Progress, SizeOf(Progress), 0);
  Progress.Position := CurrentPosition;
  Progress.Size := TotalSize;
  Progress.BlockIndex := BlockIndex;
  
  // 计算百分比
  if TotalSize > 0 then
    Progress.PercentComplete := Min(100, Byte((CurrentPosition * 100) div TotalSize))
  else
    Progress.PercentComplete := 0;
    
  // 计算处理速度和估计剩余时间
  TimeFromStart := CurrentTime - FStartTime;
  if TimeFromStart > 0 then
  begin
    // 字节/秒
    Speed := (CurrentPosition * 1000) div TimeFromStart;
    Progress.ProcessingSpeed := Speed;
    
    // 估计剩余时间（秒）
    if Speed > 0 then
      Progress.EstimatedTimeRemaining := (TotalSize - CurrentPosition) div Speed
    else
      Progress.EstimatedTimeRemaining := 0;
  end;
  
  // 触发进度事件
  FOnProgress(Self, Progress);
  
  // 更新上次进度时间和位置
  FLastProgressTime := CurrentTime;
  FLastPosition := CurrentPosition;
end;

function TLargeFileProcessor.ProcessStream(Stream: TStream; 
                                         Callback: TStreamProcessCallback): TProcessResult;
var
  StartPos: Int64;
  CurrentPos: Int64;
  TotalSize: Int64;
  BlocksRead: Integer;
  BytesRead: Integer;
  MM: TMemoryManagerState;
  OptimalBlockSize: Integer;
  IsLastBlock: Boolean;
  StartTime: Int64;
begin
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  Result.Success := True;
  
  if not Assigned(Stream) then
  begin
    Result.Success := False;
    Result.ErrorMessage := '无效的流对象';
    Exit;
  end;
  
  if not Assigned(Callback) then
  begin
    Result.Success := False;
    Result.ErrorMessage := '回调函数未指定';
    Exit;
  end;
  
  StartTime := GetTickCount64;
  FStartTime := StartTime;
  FLastProgressTime := 0;
  FLastPosition := 0;
  
  try
    // 获取流大小
    StartPos := Stream.Position;
    TotalSize := Stream.Size - StartPos;
    
    // 计算最佳块大小
    OptimalBlockSize := CalculateOptimalBlockSize(TotalSize);
    
    // 分配缓冲区
    if (FBuffer <> nil) and (FBufferSize <> OptimalBlockSize) then
    begin
      FreeMem(FBuffer);
      FBuffer := nil;
    end;
    
    if FBuffer = nil then
    begin
      try
        FBuffer := GetMemory(OptimalBlockSize);
        FBufferSize := OptimalBlockSize;
      except
        on E: Exception do
        begin
          Result.Success := False;
          Result.ErrorMessage := Format('内存分配失败: %s', [E.Message]);
          Exit;
        end;
      end;
    end;
    
    // 重置取消标志
    FCancelled := False;
    BlocksRead := 0;
    
    // 读取和处理数据块
    repeat
      // 检查是否取消
      if FCancelled then
      begin
        Result.Success := False;
        Result.ErrorMessage := '操作已取消';
        Break;
      end;
      
      // 读取一个数据块
      BytesRead := Stream.Read(FBuffer^, FBufferSize);
      
      if BytesRead > 0 then
      begin
        // 更新计数器
        Inc(BlocksRead);
        
        // 检查是否是最后一个块
        CurrentPos := Stream.Position;
        IsLastBlock := (CurrentPos >= Stream.Size);
        
        // 处理数据块
        if not ProcessDataBlock(FBuffer, BytesRead, BlocksRead - 1, IsLastBlock, Callback) then
        begin
          Result.Success := False;
          Result.ErrorMessage := '回调函数返回失败状态';
          Break;
        end;
        
        // 更新处理字节数
        Result.TotalBytesProcessed := Result.TotalBytesProcessed + BytesRead;
        
        // 更新进度
        UpdateProgress(Result.TotalBytesProcessed, TotalSize, BlocksRead - 1);
      end;
    until BytesRead = 0;
    
    // 设置结果
    Result.BlocksProcessed := BlocksRead;
    Result.ProcessTimeMs := GetTickCount64 - StartTime;
    
    // 获取峰值内存使用
    MM := GetMemoryManagerStats;
    Result.PeakMemoryUsed := MM.TotalAllocatedMediumBlockSize + 
                           MM.TotalAllocatedLargeBlockSize;
    
    // 最终进度更新（确保显示100%）
    if Result.Success and Assigned(FOnProgress) then
      UpdateProgress(TotalSize, TotalSize, BlocksRead);
    
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := Format('处理流时发生错误: %s', [E.Message]);
    end;
  end;
end;

function TLargeFileProcessor.ProcessFile(const FileName: string; 
                                       Callback: TStreamProcessCallback): TProcessResult;
var
  FileStream: TFileStream;
begin
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  
  // 验证文件存在
  if not TFile.Exists(FileName) then
  begin
    Result.Success := False;
    Result.ErrorMessage := Format('文件不存在: %s', [FileName]);
    Exit;
  end;
  
  try
    // 打开文件流
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      // 处理文件流
      Result := ProcessStream(FileStream, Callback);
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := Format('处理文件时发生错误: %s', [E.Message]);
    end;
  end;
end;

function TLargeFileProcessor.CopyLargeFile(const SourceFileName, 
                                         DestFileName: string;
                                         Transform: TStreamProcessCallback): TProcessResult;
var
  SourceStream: TFileStream;
  DestStream: TFileStream;
  TempDestName: string;
  CopyCallback: TStreamProcessCallback;
begin
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  
  // 验证源文件存在
  if not TFile.Exists(SourceFileName) then
  begin
    Result.Success := False;
    Result.ErrorMessage := Format('源文件不存在: %s', [SourceFileName]);
    Exit;
  end;
  
  // 创建临时目标文件名
  TempDestName := DestFileName + '.tmp';
  
  // 删除可能存在的临时文件
  if TFile.Exists(TempDestName) then
  begin
    try
      TFile.Delete(TempDestName);
    except
      on E: Exception do
      begin
        Result.Success := False;
        Result.ErrorMessage := Format('无法删除临时文件: %s', [E.Message]);
        Exit;
      end;
    end;
  end;
  
  SourceStream := nil;
  DestStream := nil;
  try
    // 打开源文件
    SourceStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyNone);
    
    // 创建目标文件
    DestStream := TFileStream.Create(TempDestName, fmCreate);
    
    // 创建复制回调
    CopyCallback := 
      function(const Buffer: Pointer; BufferSize: Integer; 
              BlockIndex: Integer; IsLastBlock: Boolean): Boolean
      var
        WriteResult: Boolean;
      begin
        // 如果有转换回调，先执行转换
        if Assigned(Transform) then
          WriteResult := Transform(Buffer, BufferSize, BlockIndex, IsLastBlock)
        else
          WriteResult := True;
          
        // 写入目标流
        if WriteResult then
        begin
          try
            DestStream.WriteBuffer(Buffer^, BufferSize);
            Result := True;
          except
            on E: Exception do
            begin
              Result := False;
            end;
          end;
        end
        else
          Result := False;
      end;
    
    // 处理复制
    Result := ProcessStream(SourceStream, CopyCallback);
    
    // 关闭流
    FreeAndNil(SourceStream);
    FreeAndNil(DestStream);
    
    // 如果成功，重命名临时文件为目标文件
    if Result.Success then
    begin
      try
        // 如果目标文件已存在，先删除
        if TFile.Exists(DestFileName) then
          TFile.Delete(DestFileName);
          
        // 重命名临时文件
        TFile.Move(TempDestName, DestFileName);
      except
        on E: Exception do
        begin
          Result.Success := False;
          Result.ErrorMessage := Format('重命名临时文件失败: %s', [E.Message]);
        end;
      end;
    end
    else
    begin
      // 删除临时文件
      if TFile.Exists(TempDestName) then
      begin
        try
          TFile.Delete(TempDestName);
        except
          // 忽略删除临时文件的错误
        end;
      end;
    end;
    
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := Format('复制文件时发生错误: %s', [E.Message]);
    end;
  end;
  
  // 确保释放流
  SourceStream.Free;
  DestStream.Free;
end;

procedure TLargeFileProcessor.Cancel;
begin
  FCancelled := True;
end;

end. 