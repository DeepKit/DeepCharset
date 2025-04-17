program TestEncodingFeatures;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  JclBOM,
  JclEncodingUtils,
  ControllerEncoding;

const
  TEST_DIR = '..\TestFiles\';
  OUTPUT_DIR = '..\TestFiles\output\';

procedure TestFileConversion(EncodingController: TEncodingController; const SourceFile, TargetEncoding: string; AddBOM: Boolean);
var
  TargetFile: string;
  Success: Boolean;
  StartTime, EndTime: TDateTime;
  ElapsedMs: Int64;
  SourceEncoding: string;
begin
  // 确保输出目录存在
  if not DirectoryExists(OUTPUT_DIR) then
    CreateDir(OUTPUT_DIR);
    
  TargetFile := OUTPUT_DIR + ExtractFileName(SourceFile);
  
  // 检测源文件编码
  if EncodingController.DetectFileEncoding(SourceFile, SourceEncoding) then
    WriteLn('源文件编码: ', SourceFile, ' -> ', SourceEncoding)
  else
    WriteLn('无法检测源文件编码: ', SourceFile);
  
  // 转换文件
  WriteLn('开始转换: ', SourceFile, ' -> ', TargetEncoding, ' (BOM: ', BoolToStr(AddBOM, True), ')');
  StartTime := Now;
  Success := EncodingController.ConvertSingleFileByName(SourceFile, TargetEncoding, AddBOM,
    procedure(const FilePath: string)
    begin
      WriteLn('转换回调: ', FilePath);
    end);
  EndTime := Now;
  ElapsedMs := MilliSecondsBetween(EndTime, StartTime);
  
  // 输出结果
  if Success then
  begin
    WriteLn('转换成功: ', SourceFile, ' (耗时: ', ElapsedMs, 'ms)');
    
    // 检测目标文件编码
    if EncodingController.DetectFileEncoding(TargetFile, SourceEncoding) then
      WriteLn('目标文件编码: ', TargetFile, ' -> ', SourceEncoding)
    else
      WriteLn('无法检测目标文件编码: ', TargetFile);
  end
  else
    WriteLn('转换失败: ', SourceFile);
    
  WriteLn('-----------------------------------');
end;

procedure TestBatchConversion(EncodingController: TEncodingController; const TargetEncoding: string; AddBOM: Boolean);
var
  Files: TStringDynArray;
  SelectedFiles: TArray<string>;
  i, SuccessCount: Integer;
  StartTime, EndTime: TDateTime;
  ElapsedMs: Int64;
begin
  // 获取所有测试文件
  Files := TDirectory.GetFiles(TEST_DIR, '*.txt');
  SetLength(SelectedFiles, Length(Files));
  for i := 0 to High(Files) do
    SelectedFiles[i] := Files[i];
  
  // 确保输出目录存在
  if not DirectoryExists(OUTPUT_DIR) then
    CreateDir(OUTPUT_DIR);
  
  // 批量转换
  WriteLn('开始批量转换 ', Length(SelectedFiles), ' 个文件到 ', TargetEncoding, ' (BOM: ', BoolToStr(AddBOM, True), ')');
  StartTime := Now;
  SuccessCount := 0;
  
  EncodingController.ConvertFilesByName(SelectedFiles, TargetEncoding, AddBOM,
    procedure(const FilePath: string)
    begin
      Inc(SuccessCount);
      WriteLn('已转换: ', ExtractFileName(FilePath));
    end);
  
  EndTime := Now;
  ElapsedMs := MilliSecondsBetween(EndTime, StartTime);
  
  // 输出结果
  WriteLn('批量转换完成: 成功 ', SuccessCount, '/', Length(SelectedFiles), ' 个文件 (总耗时: ', ElapsedMs, 'ms)');
  WriteLn('-----------------------------------');
end;

procedure TestLargeFilePerformance(EncodingController: TEncodingController; const SourceFile, TargetEncoding: string; AddBOM: Boolean);
var
  TargetFile: string;
  Success: Boolean;
  StartTime, EndTime: TDateTime;
  ElapsedMs: Int64;
  FileSize: Int64;
begin
  // 确保输出目录存在
  if not DirectoryExists(OUTPUT_DIR) then
    CreateDir(OUTPUT_DIR);
    
  TargetFile := OUTPUT_DIR + ExtractFileName(SourceFile);
  FileSize := TFile.GetSize(SourceFile);
  
  // 转换大文件
  WriteLn(Format('开始转换大文件: %s (%.2f MB) -> %s', 
    [SourceFile, FileSize / (1024 * 1024), TargetEncoding]));
  
  StartTime := Now;
  Success := EncodingController.ConvertSingleFileByName(SourceFile, TargetEncoding, AddBOM,
    procedure(const FilePath: string)
    begin
      WriteLn('转换回调: ', FilePath);
    end);
  EndTime := Now;
  ElapsedMs := MilliSecondsBetween(EndTime, StartTime);
  
  // 输出结果
  if Success then
    WriteLn(Format('大文件转换成功: %s (%.2f MB, 耗时: %d ms, 速度: %.2f MB/s)', 
      [SourceFile, FileSize / (1024 * 1024), ElapsedMs, 
       (FileSize / (1024 * 1024)) / (ElapsedMs / 1000)]))
  else
    WriteLn('大文件转换失败: ', SourceFile);
    
  WriteLn('-----------------------------------');
end;

var
  EncodingController: TEncodingController;
begin
  try
    // 设置控制台编码为UTF-8
    SetConsoleOutputCP(65001);
    
    WriteLn('开始测试编码检测和转换功能...');
    
    // 创建编码控制器
    EncodingController := TEncodingController.Create(
      procedure(const LogMsg: string)
      begin
        WriteLn('日志: ', LogMsg);
      end);
    try
      // 测试损坏文件处理
      WriteLn('===== 测试损坏文件处理 =====');
      TestFileConversion(EncodingController, TEST_DIR + 'corrupted_file.txt', 'UTF-8', True);
      
      // 测试混合编码文件处理
      WriteLn('===== 测试混合编码文件处理 =====');
      TestFileConversion(EncodingController, TEST_DIR + 'mixed_encoding.txt', 'UTF-8', True);
      TestFileConversion(EncodingController, TEST_DIR + 'mixed_encoding_new.txt', 'UTF-8', True);
      
      // 测试大文件处理性能
      WriteLn('===== 测试大文件处理性能 =====');
      TestLargeFilePerformance(EncodingController, TEST_DIR + 'large_file_5mb.txt', 'UTF-8', True);
      TestLargeFilePerformance(EncodingController, TEST_DIR + 'large_file_20mb.txt', 'UTF-8', True);
      
      // 测试批量转换功能
      WriteLn('===== 测试批量转换功能 =====');
      TestBatchConversion(EncodingController, 'UTF-8', True);
    finally
      EncodingController.Free;
    end;
    
    WriteLn('所有测试完成。');
    WriteLn('按任意键退出...');
    ReadLn;
  except
    on E: Exception do
    begin
      WriteLn('发生错误: ', E.Message);
      ReadLn;
    end;
  end;
end.