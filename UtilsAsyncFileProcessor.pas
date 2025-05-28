unit UtilsAsyncFileProcessor;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.SyncObjs,
  System.Generics.Collections, System.DateUtils, Vcl.Forms, Vcl.Controls,
  HelperFiles, ControllerEncoding, UtilsTypes;

type
  /// <summary>
  /// 文件扫描结果
  /// </summary>
  TFileScanResult = record
    FileName: string;
    FullPath: string;
    Encoding: string;
    HasBOM: Boolean;
    FileSize: Int64;
    ScanTime: TDateTime;
  end;

  /// <summary>
  /// 扫描进度信息
  /// </summary>
  TFileScanProgress = record
    TotalFiles: Integer;
    ProcessedFiles: Integer;
    CurrentFile: string;
    ElapsedTime: Integer; // 毫秒
    EstimatedTimeRemaining: Integer; // 毫秒
    FilesPerSecond: Double;
  end;

  /// <summary>
  /// 批量转换结果
  /// </summary>
  TBatchConversionResult = record
    TotalFiles: Integer;
    SuccessCount: Integer;
    FailCount: Integer;
    SkippedCount: Integer;
    ElapsedTime: Integer; // 毫秒
    Errors: TArray<string>;
  end;

  /// <summary>
  /// 进度回调类型
  /// </summary>
  TProgressCallback = reference to procedure(const Progress: TFileScanProgress);
  TFileResultCallback = reference to procedure(const Result: TFileScanResult);
  TConversionProgressCallback = reference to procedure(const Progress: TBatchConversionResult);

  // 前向声明
  TAsyncFileProcessor = class;

  /// <summary>
  /// 工作线程类
  /// </summary>
  TAsyncWorkerThread = class(TThread)
  private
    FProcessor: TAsyncFileProcessor;
    FWorkType: Integer; // 0=扫描, 1=转换
    FFolderPath: string;
    FFileExtensions: TArray<string>;
    FIncludeSubdirs: Boolean;
    FFiles: TArray<string>;
    FTargetEncoding: string;
    FWithBOM: Boolean;
    FProgressCallback: TProgressCallback;
    FFileResultCallback: TFileResultCallback;
    FConversionProgressCallback: TConversionProgressCallback;
  protected
    procedure Execute; override;
  public
    constructor Create(Processor: TAsyncFileProcessor);
  end;

  /// <summary>
  /// 异步文件处理器
  /// </summary>
  TAsyncFileProcessor = class
  private
    FThread: TThread;
    FCancelled: Boolean;
    FResults: TList<TFileScanResult>;
    FProgress: TFileScanProgress;
    FIsRunning: Boolean;
    FLock: TCriticalSection;
    FLogCallback: TProc<string>;

    // 内部方法
    procedure DoFileScan(const FolderPath: string; const FileExtensions: TArray<string>;
      IncludeSubdirs: Boolean; ProgressCallback: TProgressCallback;
      FileResultCallback: TFileResultCallback);
    procedure DoBatchConversion(const Files: TArray<string>; const TargetEncoding: string;
      WithBOM: Boolean; ProgressCallback: TConversionProgressCallback);

  public
    constructor Create(LogCallback: TProc<string>);
    destructor Destroy; override;

    /// <summary>
    /// 异步扫描文件夹
    /// </summary>
    procedure ScanFolderAsync(const FolderPath: string; const FileExtensions: TArray<string>;
      IncludeSubdirs: Boolean; ProgressCallback: TProgressCallback = nil;
      FileResultCallback: TFileResultCallback = nil);

    /// <summary>
    /// 异步批量转换文件
    /// </summary>
    procedure ConvertFilesAsync(const Files: TArray<string>; const TargetEncoding: string;
      WithBOM: Boolean; ProgressCallback: TConversionProgressCallback = nil);

    /// <summary>
    /// 取消当前操作
    /// </summary>
    procedure Cancel;

    /// <summary>
    /// 等待操作完成
    /// </summary>
    procedure WaitForCompletion(TimeoutMs: Integer = 5000);

    /// <summary>
    /// 获取扫描结果
    /// </summary>
    function GetResults: TArray<TFileScanResult>;

    /// <summary>
    /// 获取当前进度
    /// </summary>
    function GetProgress: TFileScanProgress;

    /// <summary>
    /// 检查是否正在运行
    /// </summary>
    property IsRunning: Boolean read FIsRunning;
  end;

  /// <summary>
  /// 进度条控制器
  /// </summary>
  TProgressController = class
  private
    FProgressBar: TObject; // 实际上是TProgressBar，但为了避免依赖VCL，使用TObject
    FLabel: TObject; // 实际上是TLabel
    FCancelButton: TObject; // 实际上是TButton
    FOnCancel: TNotifyEvent;

  public
    constructor Create(ProgressBar, StatusLabel, CancelButton: TObject);

    /// <summary>
    /// 更新进度
    /// </summary>
    procedure UpdateProgress(const Progress: TFileScanProgress);

    /// <summary>
    /// 更新转换进度
    /// </summary>
    procedure UpdateConversionProgress(const Progress: TBatchConversionResult);

    /// <summary>
    /// 显示进度控件
    /// </summary>
    procedure Show;

    /// <summary>
    /// 隐藏进度控件
    /// </summary>
    procedure Hide;

    /// <summary>
    /// 设置取消回调
    /// </summary>
    property OnCancel: TNotifyEvent read FOnCancel write FOnCancel;
  end;

implementation

uses
  Vcl.StdCtrls, Vcl.ComCtrls;

{ TAsyncFileProcessor }

constructor TAsyncFileProcessor.Create(LogCallback: TProc<string>);
begin
  inherited Create;
  FResults := TList<TFileScanResult>.Create;
  FLock := TCriticalSection.Create;
  FLogCallback := LogCallback;
  FIsRunning := False;
  FCancelled := False;

  // 初始化进度
  FillChar(FProgress, SizeOf(FProgress), 0);
end;

destructor TAsyncFileProcessor.Destroy;
begin
  // 取消正在运行的任务
  Cancel;

  // 等待任务完成
  WaitForCompletion(3000); // 最多等待3秒

  // 释放资源
  FResults.Free;
  FLock.Free;

  inherited;
end;

procedure TAsyncFileProcessor.DoFileScan(const FolderPath: string; const FileExtensions: TArray<string>;
  IncludeSubdirs: Boolean; ProgressCallback: TProgressCallback; FileResultCallback: TFileResultCallback);
var
  FileHelper: TFileHelper;
  Files: TArray<string>;
  I: Integer;
  Result: TFileScanResult;
  StartTime: TDateTime;
  HasBOM: Boolean;
begin
  if Assigned(FLogCallback) then
    FLogCallback('开始异步文件扫描: ' + FolderPath);

  StartTime := Now;

  // 创建文件助手
  FileHelper := TFileHelper.Create(FLogCallback);
  try
    // 获取文件列表
    Files := FileHelper.GetFilesInFolder(FolderPath, FileExtensions, IncludeSubdirs);

    FLock.Enter;
    try
      FProgress.TotalFiles := Length(Files);
      FProgress.ProcessedFiles := 0;
    finally
      FLock.Leave;
    end;

    // 处理每个文件
    for I := 0 to High(Files) do
    begin
      // 检查取消标志
      if FCancelled then
      begin
        if Assigned(FLogCallback) then
          FLogCallback('文件扫描被用户取消');
        Break;
      end;

      // 扫描文件
      Result.FileName := ExtractFileName(Files[I]);
      Result.FullPath := Files[I];
      Result.ScanTime := Now;

      try
        if FileExists(Files[I]) then
        begin
          var TempStream := TFileStream.Create(Files[I], fmOpenRead or fmShareDenyNone);
          try
            Result.FileSize := TempStream.Size;
          finally
            TempStream.Free;
          end;
        end
        else
          Result.FileSize := 0;
        Result.Encoding := FileHelper.DetectFileEncoding(Files[I], HasBOM);
        Result.HasBOM := HasBOM;
      except
        on E: Exception do
        begin
          Result.Encoding := 'Error: ' + E.Message;
          Result.HasBOM := False;
          Result.FileSize := 0;
        end;
      end;

      // 添加到结果列表
      FLock.Enter;
      try
        FResults.Add(Result);
        Inc(FProgress.ProcessedFiles);
        FProgress.CurrentFile := Result.FileName;
        FProgress.ElapsedTime := MilliSecondsBetween(Now, StartTime);

        // 计算速度和预估时间
        if FProgress.ElapsedTime > 0 then
        begin
          FProgress.FilesPerSecond := FProgress.ProcessedFiles / (FProgress.ElapsedTime / 1000);
          if FProgress.FilesPerSecond > 0 then
            FProgress.EstimatedTimeRemaining := Round((FProgress.TotalFiles - FProgress.ProcessedFiles) / FProgress.FilesPerSecond * 1000);
        end;
      finally
        FLock.Leave;
      end;

      // 调用回调
      if Assigned(FileResultCallback) then
      begin
        var TempResult := Result;
        TThread.Synchronize(TThread.CurrentThread,
          procedure
          begin
            FileResultCallback(TempResult);
          end
        );
      end;

      if Assigned(ProgressCallback) then
      begin
        var TempProgress := FProgress;
        TThread.Synchronize(TThread.CurrentThread,
          procedure
          begin
            ProgressCallback(TempProgress);
          end
        );
      end;
    end;

  finally
    FileHelper.Free;
    FIsRunning := False;

    if Assigned(FLogCallback) then
      FLogCallback(Format('文件扫描完成: 处理了 %d 个文件，耗时 %d 毫秒',
        [FProgress.ProcessedFiles, FProgress.ElapsedTime]));
  end;
end;

procedure TAsyncFileProcessor.DoBatchConversion(const Files: TArray<string>; const TargetEncoding: string;
  WithBOM: Boolean; ProgressCallback: TConversionProgressCallback);
var
  EncodingController: TEncodingController;
  I: Integer;
  Progress: TBatchConversionResult;
  StartTime: TDateTime;
  ErrorList: TList<string>;
begin
  if Assigned(FLogCallback) then
    FLogCallback('开始异步批量转换');

  StartTime := Now;
  ErrorList := TList<string>.Create;

  // 初始化进度
  Progress.TotalFiles := Length(Files);
  Progress.SuccessCount := 0;
  Progress.FailCount := 0;
  Progress.SkippedCount := 0;
  Progress.ElapsedTime := 0;

  // 创建编码控制器
  EncodingController := TEncodingController.Create(FLogCallback);
  try
    // 处理每个文件
    for I := 0 to High(Files) do
    begin
      // 检查取消标志
      if FCancelled then
      begin
        if Assigned(FLogCallback) then
          FLogCallback('批量转换被用户取消');
        Break;
      end;

      try
        // 转换文件
        if EncodingController.ConvertSingleFile(Files[I], TargetEncoding, WithBOM) then
          Inc(Progress.SuccessCount)
        else
        begin
          Inc(Progress.FailCount);
          ErrorList.Add(Format('转换失败: %s', [ExtractFileName(Files[I])]));
        end;
      except
        on E: Exception do
        begin
          Inc(Progress.FailCount);
          ErrorList.Add(Format('转换异常: %s - %s', [ExtractFileName(Files[I]), E.Message]));
        end;
      end;

      // 更新进度
      Progress.ElapsedTime := MilliSecondsBetween(Now, StartTime);

      // 调用进度回调
      if Assigned(ProgressCallback) and ((I mod 5 = 0) or (I = High(Files))) then
      begin
        // 复制错误列表
        SetLength(Progress.Errors, ErrorList.Count);
        for var J := 0 to ErrorList.Count - 1 do
          Progress.Errors[J] := ErrorList[J];

        var TempProgress := Progress;
        TThread.Synchronize(TThread.CurrentThread,
          procedure
          begin
            ProgressCallback(TempProgress);
          end
        );
      end;
    end;

  finally
    EncodingController.Free;
    ErrorList.Free;
    FIsRunning := False;

    if Assigned(FLogCallback) then
      FLogCallback(Format('批量转换完成: 成功 %d, 失败 %d, 耗时 %d 毫秒',
        [Progress.SuccessCount, Progress.FailCount, Progress.ElapsedTime]));
  end;
end;

procedure TAsyncFileProcessor.ScanFolderAsync(const FolderPath: string; const FileExtensions: TArray<string>;
  IncludeSubdirs: Boolean; ProgressCallback: TProgressCallback; FileResultCallback: TFileResultCallback);
var
  WorkerThread: TAsyncWorkerThread;
begin
  // 取消之前的任务
  Cancel;

  // 清空结果
  FLock.Enter;
  try
    FResults.Clear;
    FillChar(FProgress, SizeOf(FProgress), 0);
  finally
    FLock.Leave;
  end;

  // 重置取消标志
  FCancelled := False;
  FIsRunning := True;

  // 创建工作线程
  WorkerThread := TAsyncWorkerThread.Create(Self);
  WorkerThread.FWorkType := 0; // 扫描
  WorkerThread.FFolderPath := FolderPath;
  WorkerThread.FFileExtensions := FileExtensions;
  WorkerThread.FIncludeSubdirs := IncludeSubdirs;
  WorkerThread.FProgressCallback := ProgressCallback;
  WorkerThread.FFileResultCallback := FileResultCallback;

  FThread := WorkerThread;
  WorkerThread.Start;
end;

procedure TAsyncFileProcessor.ConvertFilesAsync(const Files: TArray<string>; const TargetEncoding: string;
  WithBOM: Boolean; ProgressCallback: TConversionProgressCallback);
var
  WorkerThread: TAsyncWorkerThread;
begin
  // 取消之前的任务
  Cancel;

  // 重置取消标志
  FCancelled := False;
  FIsRunning := True;

  // 创建工作线程
  WorkerThread := TAsyncWorkerThread.Create(Self);
  WorkerThread.FWorkType := 1; // 转换
  WorkerThread.FFiles := Files;
  WorkerThread.FTargetEncoding := TargetEncoding;
  WorkerThread.FWithBOM := WithBOM;
  WorkerThread.FConversionProgressCallback := ProgressCallback;

  FThread := WorkerThread;
  WorkerThread.Start;
end;

procedure TAsyncFileProcessor.Cancel;
begin
  FCancelled := True;
  if Assigned(FLogCallback) then
    FLogCallback('已请求取消当前操作');
end;

procedure TAsyncFileProcessor.WaitForCompletion(TimeoutMs: Integer);
var
  StartTime: TDateTime;
begin
  if Assigned(FThread) then
  begin
    StartTime := Now;
    while FIsRunning and (MilliSecondsBetween(Now, StartTime) < TimeoutMs) do
    begin
      Sleep(100);
      Application.ProcessMessages;
    end;

    if FIsRunning then
    begin
      FThread.Terminate;
      FThread.WaitFor;
    end;
  end;
end;

function TAsyncFileProcessor.GetResults: TArray<TFileScanResult>;
begin
  FLock.Enter;
  try
    Result := FResults.ToArray;
  finally
    FLock.Leave;
  end;
end;

function TAsyncFileProcessor.GetProgress: TFileScanProgress;
begin
  FLock.Enter;
  try
    Result := FProgress;
  finally
    FLock.Leave;
  end;
end;

{ TProgressController }

constructor TProgressController.Create(ProgressBar, StatusLabel, CancelButton: TObject);
begin
  inherited Create;
  FProgressBar := ProgressBar;
  FLabel := StatusLabel;
  FCancelButton := CancelButton;
end;

procedure TProgressController.UpdateProgress(const Progress: TFileScanProgress);
begin
  if Assigned(FProgressBar) and (FProgressBar is TProgressBar) then
  begin
    with TProgressBar(FProgressBar) do
    begin
      Max := Progress.TotalFiles;
      Position := Progress.ProcessedFiles;
    end;
  end;

  if Assigned(FLabel) and (FLabel is TLabel) then
  begin
    with TLabel(FLabel) do
    begin
      Caption := Format('正在扫描: %s (%d/%d) - %.1f 文件/秒',
        [Progress.CurrentFile, Progress.ProcessedFiles, Progress.TotalFiles, Progress.FilesPerSecond]);
    end;
  end;
end;

procedure TProgressController.UpdateConversionProgress(const Progress: TBatchConversionResult);
begin
  if Assigned(FProgressBar) and (FProgressBar is TProgressBar) then
  begin
    with TProgressBar(FProgressBar) do
    begin
      Max := Progress.TotalFiles;
      Position := Progress.SuccessCount + Progress.FailCount + Progress.SkippedCount;
    end;
  end;

  if Assigned(FLabel) and (FLabel is TLabel) then
  begin
    with TLabel(FLabel) do
    begin
      Caption := Format('转换进度: 成功 %d, 失败 %d, 跳过 %d (共 %d)',
        [Progress.SuccessCount, Progress.FailCount, Progress.SkippedCount, Progress.TotalFiles]);
    end;
  end;
end;

procedure TProgressController.Show;
begin
  if Assigned(FProgressBar) and (FProgressBar is TControl) then
    TControl(FProgressBar).Visible := True;

  if Assigned(FLabel) and (FLabel is TControl) then
    TControl(FLabel).Visible := True;

  if Assigned(FCancelButton) and (FCancelButton is TControl) then
    TControl(FCancelButton).Visible := True;
end;

procedure TProgressController.Hide;
begin
  if Assigned(FProgressBar) and (FProgressBar is TControl) then
    TControl(FProgressBar).Visible := False;

  if Assigned(FLabel) and (FLabel is TControl) then
    TControl(FLabel).Visible := False;

  if Assigned(FCancelButton) and (FCancelButton is TControl) then
    TControl(FCancelButton).Visible := False;
end;

{ TAsyncWorkerThread }

constructor TAsyncWorkerThread.Create(Processor: TAsyncFileProcessor);
begin
  inherited Create(True); // 创建时挂起，需要手动调用Start
  FProcessor := Processor;
  FreeOnTerminate := True;
end;

procedure TAsyncWorkerThread.Execute;
begin
  try
    case FWorkType of
      0: // 扫描
        FProcessor.DoFileScan(FFolderPath, FFileExtensions, FIncludeSubdirs, FProgressCallback, FFileResultCallback);
      1: // 转换
        FProcessor.DoBatchConversion(FFiles, FTargetEncoding, FWithBOM, FConversionProgressCallback);
    end;
  finally
    FProcessor.FIsRunning := False;
  end;
end;

end.
