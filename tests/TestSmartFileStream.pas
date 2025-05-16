unit TestSmartFileStream;

interface

uses
  SysUtils, Classes, SyncObjs, 
  SmartFileStream, MemoryPoolManager;

procedure TestSmartFileStreamBasicFunctionality;
procedure TestMemoryPoolAllocation;
procedure TestLargeFileProcessing;
procedure TestAsyncFileProcessing;
procedure TestCancellation;
procedure RunAllTests;

implementation

var
  TestFiles: array[0..1] of string = (
    'TestData\TestFiles\LargeFile.txt',
    'TestData\TestFiles\Output.txt'
  );

procedure PrepareTestFiles;
var
  FS: TFileStream;
  Buffer: array of Byte;
  i, j: Integer;
  TotalSize: Int64;
begin
  // 确保测试目录存在
  if not DirectoryExists('TestData\TestFiles') then
    ForceDirectories('TestData\TestFiles');
    
  // 创建一个10MB的测试文件
  TotalSize := 10 * 1024 * 1024; // 10MB
  SetLength(Buffer, 1024); // 1KB缓冲区
  
  FS := TFileStream.Create(TestFiles[0], fmCreate);
  try
    for i := 0 to (TotalSize div Length(Buffer)) - 1 do
    begin
      // 填充缓冲区
      for j := 0 to Length(Buffer) - 1 do
        Buffer[j] := Byte((i + j) mod 256);
      
      FS.WriteBuffer(Buffer[0], Length(Buffer));
    end;
  finally
    FS.Free;
  end;
  
  WriteLn('测试文件已准备完毕');
end;

procedure OnProgressUpdate(const Progress: TFileProcessProgress);
begin
  WriteLn(Format('进度: %.2f%% - 已处理: %d/%d 字节, 耗时: %d ms', 
    [Progress.CompletionPercentage * 100, 
     Progress.ProcessedBytes, 
     Progress.TotalBytes,
     Progress.ElapsedTimeMs]));
end;

procedure TestSmartFileStreamBasicFunctionality;
var
  SmartStream: TSmartFileStream;
  Result: Boolean;
begin
  WriteLn('测试基本功能...');
  
  SmartStream := TSmartFileStream.Create(64 * 1024, 4);
  try
    SmartStream.SetFiles(TestFiles[0], TestFiles[1]);
    SmartStream.OnProgress := OnProgressUpdate;
    
    Result := SmartStream.ProcessFile(
      function(const Chunk: TMemoryChunk; ChunkIndex: Integer; var ChunkResult: TChunkProcessResult): Boolean
      begin
        // 简单复制数据
        Move(Chunk.Data^, Chunk.Data^, Chunk.Size);
        ChunkResult.Success := True;
        Result := True;
      end);
      
    if Result then
      WriteLn('基本功能测试通过')
    else
      WriteLn('基本功能测试失败');
  finally
    SmartStream.Free;
  end;
end;

procedure TestMemoryPoolAllocation;
var
  Pool: TMemoryPool;
  Chunks: array of TMemoryChunk;
  i: Integer;
begin
  WriteLn('测试内存池分配...');
  
  Pool := TMemoryPool.Create(64 * 1024, 10);
  try
    SetLength(Chunks, 10);
    
    // 分配所有块
    for i := 0 to 9 do
    begin
      Chunks[i] := Pool.AllocateChunk;
      if Chunks[i].Data = nil then
      begin
        WriteLn(Format('分配第%d个块失败', [i+1]));
        Exit;
      end else
        WriteLn(Format('成功分配块 #%d', [i+1]));
    end;
    
    // 释放所有块
    for i := 0 to 9 do
      Pool.ReleaseChunk(Chunks[i]);
      
    WriteLn('所有块已释放');
    
    // 再次分配一个块测试
    Chunks[0] := Pool.AllocateChunk;
    if Chunks[0].Data <> nil then
      WriteLn('重新分配测试通过')
    else
      WriteLn('重新分配测试失败');
      
    Pool.ReleaseChunk(Chunks[0]);
  finally
    Pool.Free;
  end;
  
  WriteLn('内存池测试完成');
end;

procedure TestLargeFileProcessing;
var
  SmartStream: TSmartFileStream;
  StartTime: Cardinal;
  EndTime: Cardinal;
  Result: Boolean;
begin
  WriteLn('测试大文件处理...');
  
  StartTime := GetTickCount;
  
  SmartStream := TSmartFileStream.Create(256 * 1024, 8);
  try
    SmartStream.SetFiles(TestFiles[0], TestFiles[1]);
    SmartStream.OnProgress := OnProgressUpdate;
    
    Result := SmartStream.ProcessFile(
      function(const Chunk: TMemoryChunk; ChunkIndex: Integer; var ChunkResult: TChunkProcessResult): Boolean
      var
        i: Integer;
      begin
        // 模拟一些处理
        for i := 0 to Chunk.Size - 1 do
          PByte(Cardinal(Chunk.Data) + Cardinal(i))^ := 
            PByte(Cardinal(Chunk.Data) + Cardinal(i))^ xor $FF;
            
        ChunkResult.Success := True;
        ChunkResult.BytesProcessed := Chunk.Size;
        Result := True;
      end);
      
    EndTime := GetTickCount;
    
    if Result then
      WriteLn(Format('大文件处理测试通过，耗时: %d ms', [EndTime - StartTime]))
    else
      WriteLn('大文件处理测试失败');
  finally
    SmartStream.Free;
  end;
end;

var
  AsyncCompleted: Boolean;
  AsyncEvent: TEvent;

procedure OnAsyncComplete(const Result: Boolean);
begin
  AsyncCompleted := Result;
  AsyncEvent.SetEvent;
end;

procedure TestAsyncFileProcessing;
begin
  WriteLn('测试异步文件处理...');
  
  AsyncEvent := TEvent.Create(nil, True, False, '');
  AsyncCompleted := False;
  
  try
    var SmartStream := TSmartFileStream.Create(128 * 1024, 4);
    try
      SmartStream.SetFiles(TestFiles[0], TestFiles[1]);
      SmartStream.OnProgress := OnProgressUpdate;
      
      SmartStream.ProcessFileAsync(
        function(const Chunk: TMemoryChunk; ChunkIndex: Integer; var ChunkResult: TChunkProcessResult): Boolean
        begin
          // 简单复制
          Move(Chunk.Data^, Chunk.Data^, Chunk.Size);
          ChunkResult.Success := True;
          Result := True;
        end,
        OnAsyncComplete);
        
      WriteLn('等待异步处理完成...');
      if AsyncEvent.WaitFor(30000) = wrSignaled then
      begin
        if AsyncCompleted then
          WriteLn('异步处理测试通过')
        else
          WriteLn('异步处理测试失败');
      end
      else
        WriteLn('异步处理超时');
    finally
      SmartStream.Free;
    end;
  finally
    AsyncEvent.Free;
  end;
end;

procedure TestCancellation;
var
  SmartStream: TSmartFileStream;
  CancelThread: TThread;
begin
  WriteLn('测试取消操作...');
  
  SmartStream := TSmartFileStream.Create(64 * 1024, 4);
  try
    SmartStream.SetFiles(TestFiles[0], TestFiles[1]);
    SmartStream.OnProgress := OnProgressUpdate;
    
    // 创建一个线程在处理开始后取消操作
    CancelThread := TThread.CreateAnonymousThread(
      procedure
      begin
        Sleep(500); // 等待500毫秒
        WriteLn('取消操作...');
        SmartStream.Cancel;
      end);
      
    CancelThread.Start;
    
    if not SmartStream.ProcessFile(
      function(const Chunk: TMemoryChunk; ChunkIndex: Integer; var ChunkResult: TChunkProcessResult): Boolean
      begin
        // 模拟较慢的处理过程
        Sleep(100);
        ChunkResult.Success := True;
        Result := True;
      end) then
      WriteLn('取消测试通过 - 处理已被中断')
    else
      WriteLn('取消测试失败 - 处理未被中断');
      
    CancelThread.WaitFor;
    CancelThread.Free;
  finally
    SmartStream.Free;
  end;
end;

procedure RunAllTests;
begin
  WriteLn('开始SmartFileStream测试...');
  WriteLn('------------------------');
  
  try
    PrepareTestFiles;
    
    TestSmartFileStreamBasicFunctionality;
    WriteLn;
    
    TestMemoryPoolAllocation;
    WriteLn;
    
    TestLargeFileProcessing;
    WriteLn;
    
    TestAsyncFileProcessing;
    WriteLn;
    
    TestCancellation;
    
    WriteLn('------------------------');
    WriteLn('所有测试完成');
  except
    on E: Exception do
      WriteLn('测试过程中发生错误: ', E.Message);
  end;
end;

end. 