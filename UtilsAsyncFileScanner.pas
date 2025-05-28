unit UtilsAsyncFileScanner;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  System.Threading, System.SyncObjs, Vcl.ComCtrls, Vcl.Controls, Vcl.Forms,
  Vcl.ExtCtrls, Vcl.StdCtrls, System.DateUtils, System.Math, Winapi.Windows,
  HelperFiles;

type
  /// <summary>
  /// 文件扫描状态
  /// </summary>
  TFileScanStatus = (
    fssNotStarted,    // 未开始
    fssScanning,      // 扫描中
    fssPaused,        // 暂停
    fssCompleted,     // 完成
    fssCancelled,     // 取消
    fssError          // 错误
  );

  /// <summary>
  /// 文件扫描进度信息
  /// </summary>
  TFileScanProgress = record
    TotalFiles: Integer;           // 总文件数
    ScannedFiles: Integer;         // 已扫描文件数
    CurrentFile: string;           // 当前扫描的文件
    ElapsedTime: Int64;            // 已用时间（毫秒）
    EstimatedTimeRemaining: Int64; // 预计剩余时间（毫秒）
    Status: TFileScanStatus;       // 扫描状态
    ErrorMessage: string;          // 错误信息
  end;

  /// <summary>
  /// 文件扫描结果
  /// </summary>
  TFileScanResult = record
    FileName: string;              // 文件名
    Encoding: string;              // 编码
    HasBOM: Boolean;               // 是否有BOM
    FileSize: Int64;               // 文件大小
    ScanTime: Int64;               // 扫描时间（毫秒）
    ErrorMessage: string;          // 错误信息
  end;

  /// <summary>
  /// 文件扫描选项
  /// </summary>
  TFileScanOptions = record
    IncludeSubdirs: Boolean;       // 是否包含子目录
    FileExtensions: TArray<string>; // 文件扩展名过滤
    MaxThreads: Integer;           // 最大线程数
    BatchSize: Integer;            // 批处理大小
    ScanTimeout: Integer;          // 扫描超时（毫秒）
  end;

  /// <summary>
  /// 文件扫描回调
  /// </summary>
  TFileScanCallback = reference to procedure(const Progress: TFileScanProgress);

  /// <summary>
  /// 文件扫描结果回调
  /// </summary>
  TFileScanResultCallback = reference to procedure(const Result: TFileScanResult);

  /// <summary>
  /// 异步文件扫描器
  /// </summary>
  TAsyncFileScanner = class
  private
    FFileHelper: TFileHelper;
    FFolder: string;
    FOptions: TFileScanOptions;
    FStatus: TFileScanStatus;
    FProgress: TFileScanProgress;
    FResults: TList<TFileScanResult>;
    FLock: TCriticalSection;
    FTask: ITask;
    FStartTime: TDateTime;
    FProgressCallback: TFileScanCallback;
    FResultCallback: TFileScanResultCallback;
    FLogCallback: TProc<string>;
    FCancelEvent: TEvent;
    FPauseEvent: TEvent;
    FResumeEvent: TEvent;
    FUIUpdateTimer: TTimer;
    FProgressBar: TProgressBar;
    FStatusLabel: TLabel;

    procedure Log(const Msg: string);
    procedure UpdateProgress(const CurrentFile: string; Increment: Boolean = True);
    procedure UpdateUI(Sender: TObject);
    procedure ScanFolder;
    procedure ScanFile(const FileName: string);
    procedure ProcessBatch(const Files: TArray<string>; StartIndex, EndIndex: Integer);
    function GetDefaultOptions: TFileScanOptions;
    function EstimateTimeRemaining: Int64;
  public
    /// <summary>
    /// 创建异步文件扫描器
    /// </summary>
    constructor Create(AFileHelper: TFileHelper; const ALogCallback: TProc<string> = nil);

    /// <summary>
    /// 销毁异步文件扫描器
    /// </summary>
    destructor Destroy; override;

    /// <summary>
    /// 开始扫描
    /// </summary>
    procedure Start(const AFolder: string; const AOptions: TFileScanOptions;
      AProgressCallback: TFileScanCallback = nil;
      AResultCallback: TFileScanResultCallback = nil);

    /// <summary>
    /// 暂停扫描
    /// </summary>
    procedure Pause;

    /// <summary>
    /// 恢复扫描
    /// </summary>
    procedure Resume;

    /// <summary>
    /// 取消扫描
    /// </summary>
    procedure Cancel;

    /// <summary>
    /// 等待扫描完成
    /// </summary>
    function WaitForCompletion(Timeout: Cardinal = INFINITE): Boolean;

    /// <summary>
    /// 获取扫描结果
    /// </summary>
    function GetResults: TArray<TFileScanResult>;

    /// <summary>
    /// 获取扫描进度
    /// </summary>
    function GetProgress: TFileScanProgress;

    /// <summary>
    /// 获取默认选项
    /// </summary>
    class function DefaultOptions: TFileScanOptions; static;

    /// <summary>
    /// 绑定UI控件
    /// </summary>
    procedure BindUI(AProgressBar: TProgressBar; AStatusLabel: TLabel);

    /// <summary>
    /// 解绑UI控件
    /// </summary>
    procedure UnbindUI;

    /// <summary>
    /// 扫描文件
    /// </summary>
    procedure ScanFiles(const FolderPath: string; Extensions: TStringList; IncludeSubdirs: Boolean; Files: TStringList);

    /// <summary>
    /// 扫描文件扩展名
    /// </summary>
    procedure ScanFileExtensions(const FolderPath: string; IncludeSubdirs: Boolean; Files: TStringList);

    /// <summary>
    /// 扫描状态
    /// </summary>
    property Status: TFileScanStatus read FStatus;

    /// <summary>
    /// 扫描结果
    /// </summary>
    property Results: TList<TFileScanResult> read FResults;
  end;

implementation

{ TAsyncFileScanner }

constructor TAsyncFileScanner.Create(AFileHelper: TFileHelper; const ALogCallback: TProc<string>);
begin
  inherited Create;

  FFileHelper := AFileHelper;
  FLogCallback := ALogCallback;
  FStatus := fssNotStarted;
  FResults := TList<TFileScanResult>.Create;
  FLock := TCriticalSection.Create;

  // 创建手动重置事件
  FCancelEvent := TEvent.Create(nil, True, False, '');
  FCancelEvent.SetEvent;
  FCancelEvent.ResetEvent;

  FPauseEvent := TEvent.Create(nil, True, False, '');
  FPauseEvent.SetEvent;
  FPauseEvent.ResetEvent;

  FResumeEvent := TEvent.Create(nil, True, False, '');
  FResumeEvent.SetEvent;

  // 初始化进度信息
  FillChar(FProgress, SizeOf(FProgress), 0);
  FProgress.Status := fssNotStarted;

  // 创建UI更新定时器
  FUIUpdateTimer := TTimer.Create(nil);
  FUIUpdateTimer.Enabled := False;
  FUIUpdateTimer.Interval := 100; // 100毫秒更新一次UI
  FUIUpdateTimer.OnTimer := UpdateUI;
end;

destructor TAsyncFileScanner.Destroy;
begin
  try
    // 停止UI更新定时器
    if Assigned(FUIUpdateTimer) then
    begin
      FUIUpdateTimer.Enabled := False;
      FUIUpdateTimer.OnTimer := nil;
    end;

    // 解绑UI控件
    UnbindUI;

    // 取消正在进行的扫描
    Cancel;

    // 等待任务完成，使用更长的超时时间
    if Assigned(FTask) then
    begin
      try
        if not FTask.Wait(2000) then
        begin
          Log('警告: 无法等待扫描任务完成，任务可能仍在后台运行');
          // 不再等待，继续释放其他资源
        end;
      except
        on E: Exception do
        begin
          Log('等待扫描任务完成时出错: ' + E.Message);
          // 继续释放其他资源
        end;
      end;
    end;

    // 释放资源，使用try-finally确保所有资源都被释放
    try
      // 释放UI更新定时器
      if Assigned(FUIUpdateTimer) then
        FreeAndNil(FUIUpdateTimer);
    finally
      try
        // 释放同步对象
        if Assigned(FCancelEvent) then
          FreeAndNil(FCancelEvent);
      finally
        try
          if Assigned(FPauseEvent) then
            FreeAndNil(FPauseEvent);
        finally
          try
            if Assigned(FResumeEvent) then
              FreeAndNil(FResumeEvent);
          finally
            try
              if Assigned(FLock) then
                FreeAndNil(FLock);
            finally
              if Assigned(FResults) then
                FreeAndNil(FResults);
            end;
          end;
        end;
      end;
    end;
  except
    on E: Exception do
      // 在这里我们不能使用Log，因为它可能依赖于已经释放的对象
      OutputDebugString(PChar('TAsyncFileScanner.Destroy异常: ' + E.Message));
  end;

  // 调用继承的Destroy
  try
    inherited;
  except
    on E: Exception do
      OutputDebugString(PChar('TAsyncFileScanner.inherited Destroy异常: ' + E.Message));
  end;
end;

class function TAsyncFileScanner.DefaultOptions: TFileScanOptions;
begin
  Result.IncludeSubdirs := False;
  Result.FileExtensions := [];
  Result.MaxThreads := TThread.ProcessorCount;
  Result.BatchSize := 100;
  Result.ScanTimeout := 30000; // 30秒
end;

function TAsyncFileScanner.EstimateTimeRemaining: Int64;
var
  ElapsedTime: Int64;
  ProcessedFiles: Integer;
  RemainingFiles: Integer;
  ProcessingRate: Double;
begin
  Result := 0;

  FLock.Enter;
  try
    ElapsedTime := FProgress.ElapsedTime;
    ProcessedFiles := FProgress.ScannedFiles;
    RemainingFiles := FProgress.TotalFiles - ProcessedFiles;
  finally
    FLock.Leave;
  end;

  // 避免除零错误
  if (ElapsedTime <= 0) or (ProcessedFiles <= 0) then
    Exit(0);

  // 计算处理速率（文件/毫秒）
  ProcessingRate := ProcessedFiles / ElapsedTime;

  // 计算剩余时间（毫秒）
  if ProcessingRate > 0 then
    Result := Round(RemainingFiles / ProcessingRate)
  else
    Result := 0;
end;

function TAsyncFileScanner.GetDefaultOptions: TFileScanOptions;
begin
  Result := DefaultOptions;
end;

function TAsyncFileScanner.GetProgress: TFileScanProgress;
begin
  FLock.Enter;
  try
    Result := FProgress;
  finally
    FLock.Leave;
  end;
end;

function TAsyncFileScanner.GetResults: TArray<TFileScanResult>;
begin
  FLock.Enter;
  try
    SetLength(Result, FResults.Count);
    for var i := 0 to FResults.Count - 1 do
      Result[i] := FResults[i];
  finally
    FLock.Leave;
  end;
end;

procedure TAsyncFileScanner.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

procedure TAsyncFileScanner.Pause;
begin
  if FStatus = fssScanning then
  begin
    FLock.Enter;
    try
      FStatus := fssPaused;
      FProgress.Status := fssPaused;
      FPauseEvent.SetEvent;
      FResumeEvent.ResetEvent;
    finally
      FLock.Leave;
    end;

    Log('扫描已暂停');
  end;
end;

procedure TAsyncFileScanner.ProcessBatch(const Files: TArray<string>; StartIndex, EndIndex: Integer);
var
  i: Integer;
begin
  for i := StartIndex to EndIndex do
  begin
    // 检查是否取消
    if FCancelEvent.WaitFor(0) = wrSignaled then
      Exit;

    // 检查是否暂停
    if FPauseEvent.WaitFor(0) = wrSignaled then
    begin
      // 等待恢复
      FResumeEvent.WaitFor(INFINITE);
    end;

    // 扫描文件
    if (i >= 0) and (i < Length(Files)) then
      ScanFile(Files[i]);
  end;
end;

procedure TAsyncFileScanner.Resume;
begin
  if FStatus = fssPaused then
  begin
    FLock.Enter;
    try
      FStatus := fssScanning;
      FProgress.Status := fssScanning;
      FPauseEvent.ResetEvent;
      FResumeEvent.SetEvent;
    finally
      FLock.Leave;
    end;

    Log('扫描已恢复');
  end;
end;

procedure TAsyncFileScanner.ScanFile(const FileName: string);
var
  StartTime: TDateTime;
  ElapsedTime: Int64;
  Result: TFileScanResult;
  FileInfo: TSearchRec;
begin
  StartTime := Now;

  try
    // 初始化结果
    Result.FileName := FileName;
    Result.Encoding := 'Unknown';
    Result.HasBOM := False;
    Result.FileSize := 0;
    Result.ScanTime := 0;
    Result.ErrorMessage := '';

    // 获取文件大小
    try
      // 使用 TFileStream 获取文件大小
      var FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
      try
        Result.FileSize := FileStream.Size;
      finally
        FileStream.Free;
      end;
    except
      on E: Exception do
      begin
        // 如果 TFileStream 方法失败，尝试使用 FileOpen
        try
          var FileHandle := FileOpen(FileName, fmOpenRead or fmShareDenyNone);
          if FileHandle > 0 then
          begin
            try
              Result.FileSize := FileSeek(FileHandle, 0, 2);
              FileSeek(FileHandle, 0, 0); // 重置文件指针
            finally
              FileClose(FileHandle);
            end;
          end;
        except
          on E2: Exception do
            Log('获取文件大小失败: ' + FileName + ' - ' + E2.Message);
        end;
      end;
    end;

    // 检测文件编码
    try
      Result.Encoding := FFileHelper.DetectFileEncoding(FileName, Result.HasBOM);
    except
      on E: Exception do
      begin
        Result.ErrorMessage := E.Message;
        Log('检测文件编码失败: ' + FileName + ' - ' + E.Message);
      end;
    end;

    // 计算扫描时间
    ElapsedTime := MilliSecondsBetween(StartTime, Now);
    Result.ScanTime := ElapsedTime;

    // 更新进度
    UpdateProgress(FileName);

    // 添加结果
    FLock.Enter;
    try
      FResults.Add(Result);
    finally
      FLock.Leave;
    end;

    // 回调结果
    if Assigned(FResultCallback) then
      FResultCallback(Result);
  except
    on E: Exception do
    begin
      Log('扫描文件异常: ' + FileName + ' - ' + E.Message);

      // 更新进度
      UpdateProgress(FileName);
    end;
  end;
end;

procedure TAsyncFileScanner.ScanFolder;
var
  Files: TArray<string>;
  BatchCount, BatchSize, i, StartIndex, EndIndex: Integer;
  Tasks: array of ITask;
begin
  try
    // 重置取消和暂停事件
    FCancelEvent.ResetEvent;
    FPauseEvent.ResetEvent;
    FResumeEvent.SetEvent;

    // 更新状态
    FLock.Enter;
    try
      FStatus := fssScanning;
      FProgress.Status := fssScanning;
      FStartTime := Now;
    finally
      FLock.Leave;
    end;

    // 获取文件列表
    Log('开始扫描文件夹: ' + FFolder);
    Files := FFileHelper.GetFilesInFolder(FFolder, FOptions.FileExtensions, FOptions.IncludeSubdirs);

    // 更新总文件数
    FLock.Enter;
    try
      FProgress.TotalFiles := Length(Files);
      FProgress.ScannedFiles := 0;
    finally
      FLock.Leave;
    end;

    Log(Format('找到 %d 个文件', [Length(Files)]));

    // 如果没有文件，直接完成
    if Length(Files) = 0 then
    begin
      FLock.Enter;
      try
        FStatus := fssCompleted;
        FProgress.Status := fssCompleted;
        FProgress.ElapsedTime := MilliSecondsBetween(FStartTime, Now);
      finally
        FLock.Leave;
      end;

      Log('扫描完成: 没有找到文件');
      Exit;
    end;

    // 计算批次数量和大小
    BatchSize := FOptions.BatchSize;
    if BatchSize <= 0 then
      BatchSize := 100;

    BatchCount := (Length(Files) + BatchSize - 1) div BatchSize;

    // 限制线程数量
    var ThreadCount := Min(FOptions.MaxThreads, BatchCount);
    if ThreadCount <= 0 then
      ThreadCount := TThread.ProcessorCount;

    // 创建任务数组
    SetLength(Tasks, ThreadCount);

    // 启动UI更新定时器
    FUIUpdateTimer.Enabled := True;

    Log(Format('开始扫描 %d 个文件 (使用 %d 个线程, %d 个批次, 每批次 %d 个文件)',
      [Length(Files), ThreadCount, BatchCount, BatchSize]));

    // 创建并启动任务
    for i := 0 to ThreadCount - 1 do
    begin
      // 计算当前批次的起始和结束索引
      var TaskStartIndex := i * (Length(Files) div ThreadCount);
      var TaskEndIndex := (i + 1) * (Length(Files) div ThreadCount) - 1;

      // 最后一个线程处理剩余的文件
      if i = ThreadCount - 1 then
        TaskEndIndex := Length(Files) - 1;

      // 创建任务处理函数
      Tasks[i] := TTask.Create(
        procedure
        begin
          try
            ProcessBatch(Files, TaskStartIndex, TaskEndIndex);
          except
            on E: Exception do
              Log('批处理任务异常: ' + E.Message);
          end;
        end
      );
    end;

    // 等待所有任务完成
    TTask.WaitForAll(Tasks);

    // 停止UI更新定时器
    FUIUpdateTimer.Enabled := False;

    // 更新最终状态
    FLock.Enter;
    try
      if FCancelEvent.WaitFor(0) = wrSignaled then
      begin
        FStatus := fssCancelled;
        FProgress.Status := fssCancelled;
      end
      else
      begin
        FStatus := fssCompleted;
        FProgress.Status := fssCompleted;
      end;

      FProgress.ElapsedTime := MilliSecondsBetween(FStartTime, Now);
      FProgress.EstimatedTimeRemaining := 0;
    finally
      FLock.Leave;
    end;

    // 最后更新一次UI
    UpdateUI(nil);

    // 记录日志
    Log(Format('扫描完成: 共扫描 %d 个文件, 耗时 %d 毫秒',
      [FProgress.ScannedFiles, FProgress.ElapsedTime]));
  except
    on E: Exception do
    begin
      // 更新错误状态
      FLock.Enter;
      try
        FStatus := fssError;
        FProgress.Status := fssError;
        FProgress.ErrorMessage := E.Message;
        FProgress.ElapsedTime := MilliSecondsBetween(FStartTime, Now);
      finally
        FLock.Leave;
      end;

      Log('扫描异常: ' + E.Message);
    end;
  end;
end;

procedure TAsyncFileScanner.Start(const AFolder: string; const AOptions: TFileScanOptions;
  AProgressCallback: TFileScanCallback; AResultCallback: TFileScanResultCallback);
begin
  // 如果已经在扫描，先取消
  if (FStatus = fssScanning) or (FStatus = fssPaused) then
    Cancel;

  // 等待任务完成
  if Assigned(FTask) then
  begin
    try
      if not FTask.Wait(1000) then
        Log('警告: 无法等待上一个扫描任务完成');
    except
      on E: Exception do
        Log('等待上一个扫描任务完成时出错: ' + E.Message);
    end;
  end;

  // 清空结果
  FLock.Enter;
  try
    FResults.Clear;
    FillChar(FProgress, SizeOf(FProgress), 0);
    FProgress.Status := fssNotStarted;
    FFolder := AFolder;
    FOptions := AOptions;
    FProgressCallback := AProgressCallback;
    FResultCallback := AResultCallback;
  finally
    FLock.Leave;
  end;

  // 创建并启动任务
  FTask := TTask.Create(
    procedure
    begin
      try
        ScanFolder;
      except
        on E: Exception do
          Log('任务执行异常: ' + E.Message);
      end;
    end
  );

  Log('开始扫描任务: ' + AFolder);
end;

procedure TAsyncFileScanner.UpdateProgress(const CurrentFile: string; Increment: Boolean);
begin
  FLock.Enter;
  try
    // 更新当前文件
    FProgress.CurrentFile := CurrentFile;

    // 增加已扫描文件数
    if Increment then
      Inc(FProgress.ScannedFiles);

    // 更新已用时间
    FProgress.ElapsedTime := MilliSecondsBetween(FStartTime, Now);

    // 更新预计剩余时间
    FProgress.EstimatedTimeRemaining := EstimateTimeRemaining;
  finally
    FLock.Leave;
  end;

  // 回调进度
  if Assigned(FProgressCallback) then
    FProgressCallback(FProgress);
end;

procedure TAsyncFileScanner.UpdateUI(Sender: TObject);
var
  Progress: TFileScanProgress;
begin
  // 获取当前进度
  Progress := GetProgress;

  // 更新进度条
  if Assigned(FProgressBar) and (Progress.TotalFiles > 0) then
  begin
    FProgressBar.Max := Progress.TotalFiles;
    FProgressBar.Position := Progress.ScannedFiles;
  end;

  // 更新状态标签
  if Assigned(FStatusLabel) then
  begin
    case Progress.Status of
      fssNotStarted: FStatusLabel.Caption := '准备扫描...';
      fssScanning: FStatusLabel.Caption := Format('正在扫描 (%d/%d): %s',
                     [Progress.ScannedFiles, Progress.TotalFiles, ExtractFileName(Progress.CurrentFile)]);
      fssPaused: FStatusLabel.Caption := Format('已暂停 (%d/%d)',
                   [Progress.ScannedFiles, Progress.TotalFiles]);
      fssCompleted: FStatusLabel.Caption := Format('扫描完成: %d 个文件 (耗时: %d 毫秒)',
                      [Progress.ScannedFiles, Progress.ElapsedTime]);
      fssCancelled: FStatusLabel.Caption := Format('扫描已取消 (%d/%d)',
                      [Progress.ScannedFiles, Progress.TotalFiles]);
      fssError: FStatusLabel.Caption := Format('扫描出错: %s', [Progress.ErrorMessage]);
    end;
  end;
end;

procedure TAsyncFileScanner.BindUI(AProgressBar: TProgressBar; AStatusLabel: TLabel);
begin
  FProgressBar := AProgressBar;
  FStatusLabel := AStatusLabel;

  // 初始化UI
  if Assigned(FProgressBar) then
  begin
    FProgressBar.Min := 0;
    FProgressBar.Max := 100;
    FProgressBar.Position := 0;
  end;

  if Assigned(FStatusLabel) then
    FStatusLabel.Caption := '准备扫描...';
end;

procedure TAsyncFileScanner.Cancel;
begin
  // 即使不在扫描或暂停状态，也尝试取消任何可能的操作
  FLock.Enter;
  try
    // 设置状态为已取消
    FStatus := fssCancelled;
    FProgress.Status := fssCancelled;

    // 触发取消事件
    FCancelEvent.SetEvent;

    // 如果暂停了，恢复以便可以取消
    FPauseEvent.ResetEvent;
    FResumeEvent.SetEvent;
  finally
    FLock.Leave;
  end;

  // 等待任务完成
  if Assigned(FTask) then
  begin
    try
      // 只等待短时间，不阻塞UI
      if not FTask.Wait(500) then
        Log('警告: 取消操作可能需要更长时间完成');
    except
      on E: Exception do
        Log('取消扫描时出错: ' + E.Message);
    end;
  end;

  Log('扫描已取消');
end;

procedure TAsyncFileScanner.ScanFiles(const FolderPath: string; Extensions: TStringList; IncludeSubdirs: Boolean; Files: TStringList);
var
  ExtArray: TArray<string>;
  Results: TArray<TFileScanResult>;
  i: Integer;
begin
  // 将TStringList转换为TArray<string>
  SetLength(ExtArray, Extensions.Count);
  for i := 0 to Extensions.Count - 1 do
    ExtArray[i] := Extensions[i];

  // 创建选项
  var Options := DefaultOptions;
  Options.IncludeSubdirs := IncludeSubdirs;
  Options.FileExtensions := ExtArray;

  // 清空结果列表
  if Assigned(Files) then
    Files.Clear;

  // 开始扫描
  Start(FolderPath, Options);

  // 等待扫描完成
  WaitForCompletion(30000); // 等待最多30秒

  // 获取结果
  Results := GetResults;

  // 将结果添加到文件列表
  if Assigned(Files) then
  begin
    for i := 0 to Length(Results) - 1 do
      Files.Add(Results[i].FileName);
  end;
end;

procedure TAsyncFileScanner.ScanFileExtensions(const FolderPath: string; IncludeSubdirs: Boolean; Files: TStringList);
var
  Options: TFileScanOptions;
  Results: TArray<TFileScanResult>;
  i: Integer;
begin
  // 创建选项
  Options := DefaultOptions;
  Options.IncludeSubdirs := IncludeSubdirs;
  Options.FileExtensions := []; // 不过滤扩展名

  // 清空结果列表
  if Assigned(Files) then
    Files.Clear;

  // 开始扫描
  Start(FolderPath, Options);

  // 等待扫描完成
  WaitForCompletion(30000); // 等待最多30秒

  // 获取结果
  Results := GetResults;

  // 将结果添加到文件列表
  if Assigned(Files) then
  begin
    for i := 0 to Length(Results) - 1 do
      Files.Add(Results[i].FileName);
  end;
end;

procedure TAsyncFileScanner.UnbindUI;
begin
  FProgressBar := nil;
  FStatusLabel := nil;
end;

function TAsyncFileScanner.WaitForCompletion(Timeout: Cardinal): Boolean;
begin
  Result := False;

  // 如果任务未分配，则认为已完成
  if not Assigned(FTask) then
    Exit(True);

  // 如果状态已经是完成、取消或错误，则认为已完成
  if (FStatus = fssCompleted) or (FStatus = fssCancelled) or (FStatus = fssError) then
    Exit(True);

  // 等待任务完成
  try
    Result := FTask.Wait(Timeout);

    // 如果等待超时，记录日志
    if not Result then
      Log('等待扫描完成超时');
  except
    on E: Exception do
    begin
      Log('等待扫描完成时出错: ' + E.Message);
      Result := False;
    end;
  end;
end;

end.
