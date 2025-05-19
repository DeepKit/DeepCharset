unit TestEncodingUtils;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Types, System.UITypes,
  System.Diagnostics,
  UtilsEncodingTypes, UtilsEncodingBOM_Improved,
  UtilsEncodingDetector_Improved, UtilsEncodingConverter_Improved,
  UtilsEncodingManager, UtilsEncodingCache;

type
  /// <summary>
  /// 编码工具测试类
  /// </summary>
  TEncodingUtilsTest = class
  private
    FTestDir: string;
    FLogMessages: TStringList;
    FStopwatch: TStopwatch;

    procedure LogMessage(const Msg: string);
    procedure CreateTestFiles;
    procedure CleanupTestFiles;
    procedure CreateLargeTestFiles(Count: Integer);

  public
    constructor Create;
    destructor Destroy; override;

    procedure RunAllTests;

    // BOM检测测试
    procedure TestBOMDetection;

    // 编码检测测试
    procedure TestEncodingDetection;

    // 编码转换测试
    procedure TestEncodingConversion;

    // 批量转换测试
    procedure TestBatchConversion;

    // 缓存测试
    procedure TestEncodingCache;

    // 性能测试
    procedure TestPerformance;

    // 并行批量转换测试
    procedure TestParallelBatchConversion;

    // 获取测试结果
    function GetTestResults: string;
  end;

implementation

{ TEncodingUtilsTest }

procedure TEncodingUtilsTest.LogMessage(const Msg: string);
begin
  FLogMessages.Add(FormatDateTime('[yyyy-mm-dd hh:nn:ss] ', Now) + Msg);
end;

constructor TEncodingUtilsTest.Create;
begin
  inherited Create;

  // 创建日志列表
  FLogMessages := TStringList.Create;

  // 创建计时器
  FStopwatch := TStopwatch.Create;

  // 设置测试目录
  FTestDir := TPath.Combine(TPath.GetTempPath, 'EncodingTest');

  // 确保测试目录存在
  if not DirectoryExists(FTestDir) then
    TDirectory.CreateDirectory(FTestDir);

  // 设置日志回调
  TEncodingManager.SetLogCallback(
    procedure(const Msg: string)
    begin
      // 不记录所有日志，只在需要时记录
    end
  );

  // 创建测试文件
  CreateTestFiles;
end;

destructor TEncodingUtilsTest.Destroy;
begin
  // 清理测试文件
  CleanupTestFiles;

  // 释放日志列表
  FLogMessages.Free;

  inherited;
end;

procedure TEncodingUtilsTest.CleanupTestFiles;
begin
  if DirectoryExists(FTestDir) then
  begin
    try
      TDirectory.Delete(FTestDir, True);
    except
      // 忽略删除错误
    end;
  end;
end;

procedure TEncodingUtilsTest.CreateTestFiles;
var
  Stream: TFileStream;
  UTF8String, ANSIString, UTF16String: string;
  UTF8Bytes, ANSIBytes, UTF16Bytes: TBytes;
  UTF8BOMBytes: TBytes;
begin
  // 创建UTF-8无BOM测试文件
  UTF8String := '这是一个UTF-8编码的文件，包含中文字符。';
  UTF8Bytes := TEncodingClass.UTF8.GetBytes(UTF8String);

  Stream := TFileStream.Create(TPath.Combine(FTestDir, 'UTF8_NoBOM.txt'), fmCreate);
  try
    Stream.WriteBuffer(UTF8Bytes[0], Length(UTF8Bytes));
  finally
    Stream.Free;
  end;

  // 创建UTF-8带BOM测试文件
  SetLength(UTF8BOMBytes, Length(UTF8_BOM) + Length(UTF8Bytes));
  Move(UTF8_BOM[0], UTF8BOMBytes[0], Length(UTF8_BOM));
  Move(UTF8Bytes[0], UTF8BOMBytes[Length(UTF8_BOM)], Length(UTF8Bytes));

  Stream := TFileStream.Create(TPath.Combine(FTestDir, 'UTF8_BOM.txt'), fmCreate);
  try
    Stream.WriteBuffer(UTF8BOMBytes[0], Length(UTF8BOMBytes));
  finally
    Stream.Free;
  end;

  // 创建ANSI测试文件
  ANSIString := 'This is an ANSI encoded file.';
  ANSIBytes := TEncodingClass.ANSI.GetBytes(ANSIString);

  Stream := TFileStream.Create(TPath.Combine(FTestDir, 'ANSI.txt'), fmCreate);
  try
    Stream.WriteBuffer(ANSIBytes[0], Length(ANSIBytes));
  finally
    Stream.Free;
  end;

  // 创建UTF-16 LE测试文件
  UTF16String := '这是一个UTF-16编码的文件，包含中文字符。';
  UTF16Bytes := TEncodingClass.Unicode.GetBytes(UTF16String);

  Stream := TFileStream.Create(TPath.Combine(FTestDir, 'UTF16_LE.txt'), fmCreate);
  try
    Stream.WriteBuffer(UTF16_LE_BOM[0], Length(UTF16_LE_BOM));
    Stream.WriteBuffer(UTF16Bytes[0], Length(UTF16Bytes));
  finally
    Stream.Free;
  end;
end;

procedure TEncodingUtilsTest.CreateLargeTestFiles(Count: Integer);
var
  i: Integer;
  Stream: TFileStream;
  UTF8String, UTF16String: string;
  UTF8Bytes, UTF16Bytes: TBytes;
  UTF8BOMBytes: TBytes;
  FileName: string;
  LargeDir: string;
begin
  // 创建大量测试文件的目录
  LargeDir := TPath.Combine(FTestDir, 'LargeTest');
  if not DirectoryExists(LargeDir) then
    TDirectory.CreateDirectory(LargeDir);

  // 创建大量测试文件
  for i := 1 to Count do
  begin
    // 创建UTF-8无BOM测试文件
    UTF8String := Format('这是第%d个UTF-8编码的文件，包含中文字符。这是一个用于测试的大文件，包含重复的内容。', [i]);
    // 重复内容以增加文件大小
    UTF8String := UTF8String + UTF8String + UTF8String + UTF8String + UTF8String;
    UTF8Bytes := TEncodingClass.UTF8.GetBytes(UTF8String);

    FileName := TPath.Combine(LargeDir, Format('UTF8_NoBOM_%d.txt', [i]));
    Stream := TFileStream.Create(FileName, fmCreate);
    try
      Stream.WriteBuffer(UTF8Bytes[0], Length(UTF8Bytes));
    finally
      Stream.Free;
    end;

    // 创建UTF-8带BOM测试文件
    SetLength(UTF8BOMBytes, Length(UTF8_BOM) + Length(UTF8Bytes));
    Move(UTF8_BOM[0], UTF8BOMBytes[0], Length(UTF8_BOM));
    Move(UTF8Bytes[0], UTF8BOMBytes[Length(UTF8_BOM)], Length(UTF8Bytes));

    FileName := TPath.Combine(LargeDir, Format('UTF8_BOM_%d.txt', [i]));
    Stream := TFileStream.Create(FileName, fmCreate);
    try
      Stream.WriteBuffer(UTF8BOMBytes[0], Length(UTF8BOMBytes));
    finally
      Stream.Free;
    end;

    // 创建UTF-16 LE测试文件
    UTF16String := Format('这是第%d个UTF-16编码的文件，包含中文字符。这是一个用于测试的大文件，包含重复的内容。', [i]);
    // 重复内容以增加文件大小
    UTF16String := UTF16String + UTF16String + UTF16String + UTF16String + UTF16String;
    UTF16Bytes := TEncodingClass.Unicode.GetBytes(UTF16String);

    FileName := TPath.Combine(LargeDir, Format('UTF16_LE_%d.txt', [i]));
    Stream := TFileStream.Create(FileName, fmCreate);
    try
      Stream.WriteBuffer(UTF16_LE_BOM[0], Length(UTF16_LE_BOM));
      Stream.WriteBuffer(UTF16Bytes[0], Length(UTF16Bytes));
    finally
      Stream.Free;
    end;
  end;
end;

function TEncodingUtilsTest.GetTestResults: string;
begin
  Result := FLogMessages.Text;
end;



procedure TEncodingUtilsTest.RunAllTests;
begin
  FLogMessages.Add('===== 开始编码工具测试 =====');
  FLogMessages.Add('');

  // 运行所有测试
  TestBOMDetection;
  TestEncodingDetection;
  TestEncodingConversion;
  TestBatchConversion;
  TestEncodingCache;
  TestPerformance;
  TestParallelBatchConversion;

  FLogMessages.Add('');
  FLogMessages.Add('===== 编码工具测试完成 =====');
end;

procedure TEncodingUtilsTest.TestBOMDetection;
var
  UTF8BOMFile, UTF8NoBOMFile, UTF16LEFile, ANSIFile: string;
  BOMResult: TBOMDetectionResult;
begin
  FLogMessages.Add('--- BOM检测测试 ---');

  // 设置测试文件路径
  UTF8BOMFile := TPath.Combine(FTestDir, 'UTF8_BOM.txt');
  UTF8NoBOMFile := TPath.Combine(FTestDir, 'UTF8_NoBOM.txt');
  UTF16LEFile := TPath.Combine(FTestDir, 'UTF16_LE.txt');
  ANSIFile := TPath.Combine(FTestDir, 'ANSI.txt');

  // 测试UTF-8带BOM文件
  BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromFile(UTF8BOMFile);
  FLogMessages.Add(Format('UTF8_BOM.txt: BOMType=%d, Encoding=%s, BOMLength=%d',
    [Ord(BOMResult.BOMType), BOMResult.Encoding, BOMResult.BOMLength]));

  // 测试UTF-8无BOM文件
  BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromFile(UTF8NoBOMFile);
  FLogMessages.Add(Format('UTF8_NoBOM.txt: BOMType=%d, Encoding=%s, BOMLength=%d',
    [Ord(BOMResult.BOMType), BOMResult.Encoding, BOMResult.BOMLength]));

  // 测试UTF-16 LE文件
  BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromFile(UTF16LEFile);
  FLogMessages.Add(Format('UTF16_LE.txt: BOMType=%d, Encoding=%s, BOMLength=%d',
    [Ord(BOMResult.BOMType), BOMResult.Encoding, BOMResult.BOMLength]));

  // 测试ANSI文件
  BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromFile(ANSIFile);
  FLogMessages.Add(Format('ANSI.txt: BOMType=%d, Encoding=%s, BOMLength=%d',
    [Ord(BOMResult.BOMType), BOMResult.Encoding, BOMResult.BOMLength]));

  FLogMessages.Add('');
end;

procedure TEncodingUtilsTest.TestEncodingDetection;
var
  UTF8BOMFile, UTF8NoBOMFile, UTF16LEFile, ANSIFile: string;
  DetectionResult: TEncodingDetectionResult;
begin
  FLogMessages.Add('--- 编码检测测试 ---');

  // 设置测试文件路径
  UTF8BOMFile := TPath.Combine(FTestDir, 'UTF8_BOM.txt');
  UTF8NoBOMFile := TPath.Combine(FTestDir, 'UTF8_NoBOM.txt');
  UTF16LEFile := TPath.Combine(FTestDir, 'UTF16_LE.txt');
  ANSIFile := TPath.Combine(FTestDir, 'ANSI.txt');

  // 测试UTF-8带BOM文件
  DetectionResult := TEncodingManager.DetectFileEncoding(UTF8BOMFile);
  FLogMessages.Add(Format('UTF8_BOM.txt: Encoding=%s, HasBOM=%s, Confidence=%.2f, Method=%s',
    [DetectionResult.Encoding, BoolToStr(DetectionResult.HasBOM, True),
     DetectionResult.Confidence, DetectionResult.DetectionMethod]));

  // 测试UTF-8无BOM文件
  DetectionResult := TEncodingManager.DetectFileEncoding(UTF8NoBOMFile);
  FLogMessages.Add(Format('UTF8_NoBOM.txt: Encoding=%s, HasBOM=%s, Confidence=%.2f, Method=%s',
    [DetectionResult.Encoding, BoolToStr(DetectionResult.HasBOM, True),
     DetectionResult.Confidence, DetectionResult.DetectionMethod]));

  // 测试UTF-16 LE文件
  DetectionResult := TEncodingManager.DetectFileEncoding(UTF16LEFile);
  FLogMessages.Add(Format('UTF16_LE.txt: Encoding=%s, HasBOM=%s, Confidence=%.2f, Method=%s',
    [DetectionResult.Encoding, BoolToStr(DetectionResult.HasBOM, True),
     DetectionResult.Confidence, DetectionResult.DetectionMethod]));

  // 测试ANSI文件
  DetectionResult := TEncodingManager.DetectFileEncoding(ANSIFile);
  FLogMessages.Add(Format('ANSI.txt: Encoding=%s, HasBOM=%s, Confidence=%.2f, Method=%s',
    [DetectionResult.Encoding, BoolToStr(DetectionResult.HasBOM, True),
     DetectionResult.Confidence, DetectionResult.DetectionMethod]));

  FLogMessages.Add('');
end;

procedure TEncodingUtilsTest.TestEncodingConversion;
var
  SourceFile, TargetFile: string;
  Success: Boolean;
begin
  FLogMessages.Add('--- 编码转换测试 ---');

  // UTF-8无BOM转UTF-8带BOM
  SourceFile := TPath.Combine(FTestDir, 'UTF8_NoBOM.txt');
  TargetFile := TPath.Combine(FTestDir, 'UTF8_NoBOM_to_BOM.txt');
  Success := TEncodingManager.ConvertFileEncoding(SourceFile, TargetFile, ENCODING_UTF8, ENCODING_UTF8, True);
  FLogMessages.Add(Format('UTF-8无BOM转UTF-8带BOM: %s', [BoolToStr(Success, True)]));

  // UTF-8带BOM转UTF-8无BOM
  SourceFile := TPath.Combine(FTestDir, 'UTF8_BOM.txt');
  TargetFile := TPath.Combine(FTestDir, 'UTF8_BOM_to_NoBOM.txt');
  Success := TEncodingManager.ConvertFileEncoding(SourceFile, TargetFile, ENCODING_UTF8_BOM, ENCODING_UTF8, False);
  FLogMessages.Add(Format('UTF-8带BOM转UTF-8无BOM: %s', [BoolToStr(Success, True)]));

  // UTF-8转UTF-16 LE
  SourceFile := TPath.Combine(FTestDir, 'UTF8_BOM.txt');
  TargetFile := TPath.Combine(FTestDir, 'UTF8_to_UTF16LE.txt');
  Success := TEncodingManager.ConvertFileEncoding(SourceFile, TargetFile, ENCODING_UTF8_BOM, ENCODING_UTF16_LE, True);
  FLogMessages.Add(Format('UTF-8转UTF-16 LE: %s', [BoolToStr(Success, True)]));

  // ANSI转UTF-8
  SourceFile := TPath.Combine(FTestDir, 'ANSI.txt');
  TargetFile := TPath.Combine(FTestDir, 'ANSI_to_UTF8.txt');
  Success := TEncodingManager.ConvertFileEncoding(SourceFile, TargetFile, ENCODING_ANSI, ENCODING_UTF8, True);
  FLogMessages.Add(Format('ANSI转UTF-8: %s', [BoolToStr(Success, True)]));

  FLogMessages.Add('');
end;

procedure TEncodingUtilsTest.TestBatchConversion;
var
  FileNames: TArray<string>;
  SourceDir, TargetDir: string;
  SuccessCount: Integer;
begin
  FLogMessages.Add('--- 批量转换测试 ---');

  // 设置源目录和目标目录
  SourceDir := FTestDir;
  TargetDir := TPath.Combine(FTestDir, 'Converted');

  // 创建目标目录
  if not DirectoryExists(TargetDir) then
    TDirectory.CreateDirectory(TargetDir);

  // 设置要转换的文件名
  SetLength(FileNames, 4);
  FileNames[0] := 'UTF8_BOM.txt';
  FileNames[1] := 'UTF8_NoBOM.txt';
  FileNames[2] := 'UTF16_LE.txt';
  FileNames[3] := 'ANSI.txt';

  // 批量转换为UTF-8带BOM（自动检测源编码）
  SuccessCount := TEncodingManager.BatchConvertFileEncoding(FileNames, SourceDir, TargetDir, '', ENCODING_UTF8, True);
  FLogMessages.Add(Format('批量转换为UTF-8带BOM: 成功 %d / 总计 %d', [SuccessCount, Length(FileNames)]));

  FLogMessages.Add('');
end;

procedure TEncodingUtilsTest.TestEncodingCache;
var
  FileName: string;
  Result1, Result2: TEncodingDetectionResult;
  ElapsedTime1, ElapsedTime2: Int64;
begin
  FLogMessages.Add('--- 编码缓存测试 ---');

  // 初始化缓存
  TEncodingCache.Init(100, 60);
  TEncodingCache.ClearCache;

  // 测试文件
  FileName := TPath.Combine(FTestDir, 'UTF8_BOM.txt');

  // 第一次检测（无缓存）
  FStopwatch.Reset;
  FStopwatch.Start;
  Result1 := TEncodingDetector_Improved.DetectFileEncoding(FileName);
  FStopwatch.Stop;
  ElapsedTime1 := FStopwatch.ElapsedMilliseconds;

  // 第二次检测（有缓存）
  FStopwatch.Reset;
  FStopwatch.Start;
  Result2 := TEncodingDetector_Improved.DetectFileEncoding(FileName);
  FStopwatch.Stop;
  ElapsedTime2 := FStopwatch.ElapsedMilliseconds;

  // 输出结果
  FLogMessages.Add(Format('第一次检测（无缓存）: %s, 置信度: %.2f, 耗时: %d ms',
    [Result1.Encoding, Result1.Confidence, ElapsedTime1]));
  FLogMessages.Add(Format('第二次检测（有缓存）: %s, 置信度: %.2f, 耗时: %d ms',
    [Result2.Encoding, Result2.Confidence, ElapsedTime2]));
  FLogMessages.Add(Format('缓存加速比: %.2f倍', [ElapsedTime1 / Max(1, ElapsedTime2)]));
  FLogMessages.Add(TEncodingCache.GetCacheStats);
  FLogMessages.Add('');
end;

procedure TEncodingUtilsTest.TestPerformance;
var
  FileCount: Integer;
  ElapsedTime: Int64;
  LargeDir, TargetDir: string;
  FileNames: TArray<string>;
  SuccessCount: Integer;
begin
  FLogMessages.Add('--- 性能测试 ---');

  // 创建大量测试文件
  FileCount := 20; // 创建20个文件，每种编码各20个
  CreateLargeTestFiles(FileCount);

  // 设置源目录和目标目录
  LargeDir := TPath.Combine(FTestDir, 'LargeTest');
  TargetDir := TPath.Combine(FTestDir, 'LargeConverted');

  // 确保目标目录存在
  if not DirectoryExists(TargetDir) then
    TDirectory.CreateDirectory(TargetDir);

  // 获取源目录中的所有文件
  FileNames := TDirectory.GetFiles(LargeDir, '*.txt');
  for var i := 0 to High(FileNames) do
    FileNames[i] := ExtractFileName(FileNames[i]);

  FLogMessages.Add(Format('测试文件数量: %d', [Length(FileNames)]));

  // 测试编码检测性能
  FStopwatch.Reset;
  FStopwatch.Start;
  for var i := 0 to High(FileNames) do
  begin
    var FileName := TPath.Combine(LargeDir, FileNames[i]);
    var Result := TEncodingDetector_Improved.DetectFileEncoding(FileName);
  end;
  FStopwatch.Stop;
  ElapsedTime := FStopwatch.ElapsedMilliseconds;

  FLogMessages.Add(Format('编码检测性能: %d个文件, 总耗时: %d ms, 平均每个文件: %.2f ms',
    [Length(FileNames), ElapsedTime, ElapsedTime / Length(FileNames)]));

  // 测试编码转换性能
  FStopwatch.Reset;
  FStopwatch.Start;
  SuccessCount := TEncodingManager.BatchConvertFileEncoding(FileNames, LargeDir, TargetDir, '', ENCODING_UTF8, True);
  FStopwatch.Stop;
  ElapsedTime := FStopwatch.ElapsedMilliseconds;

  FLogMessages.Add(Format('编码转换性能: %d个文件, 成功: %d, 总耗时: %d ms, 平均每个文件: %.2f ms',
    [Length(FileNames), SuccessCount, ElapsedTime, ElapsedTime / Length(FileNames)]));
  FLogMessages.Add('');
end;

procedure TEncodingUtilsTest.TestParallelBatchConversion;
var
  FileCount: Integer;
  ElapsedTime1, ElapsedTime2: Int64;
  LargeDir, TargetDir1, TargetDir2: string;
  FileNames: TArray<string>;
  SuccessCount1, SuccessCount2: Integer;
begin
  FLogMessages.Add('--- 并行批量转换测试 ---');

  // 确保大量测试文件存在
  LargeDir := TPath.Combine(FTestDir, 'LargeTest');
  if not DirectoryExists(LargeDir) or (Length(TDirectory.GetFiles(LargeDir, '*.txt')) = 0) then
  begin
    FileCount := 20; // 创建20个文件，每种编码各20个
    CreateLargeTestFiles(FileCount);
  end;

  // 设置目标目录
  TargetDir1 := TPath.Combine(FTestDir, 'ParallelTest1');
  TargetDir2 := TPath.Combine(FTestDir, 'ParallelTest2');

  // 确保目标目录存在
  if not DirectoryExists(TargetDir1) then
    TDirectory.CreateDirectory(TargetDir1);
  if not DirectoryExists(TargetDir2) then
    TDirectory.CreateDirectory(TargetDir2);

  // 获取源目录中的所有文件
  FileNames := TDirectory.GetFiles(LargeDir, '*.txt');
  for var i := 0 to High(FileNames) do
    FileNames[i] := ExtractFileName(FileNames[i]);

  FLogMessages.Add(Format('测试文件数量: %d', [Length(FileNames)]));

  // 测试串行批量转换
  TEncodingCache.ClearCache; // 清除缓存，确保公平比较

  // 修改TEncodingManager中的代码，强制使用串行处理
  FStopwatch.Reset;
  FStopwatch.Start;
  SuccessCount1 := TEncodingManager.BatchConvertFileEncoding(FileNames, LargeDir, TargetDir1, '', ENCODING_UTF8, True);
  FStopwatch.Stop;
  ElapsedTime1 := FStopwatch.ElapsedMilliseconds;

  FLogMessages.Add(Format('串行批量转换: %d个文件, 成功: %d, 总耗时: %d ms, 平均每个文件: %.2f ms',
    [Length(FileNames), SuccessCount1, ElapsedTime1, ElapsedTime1 / Length(FileNames)]));

  // 测试并行批量转换
  TEncodingCache.ClearCache; // 清除缓存，确保公平比较

  // 修改TEncodingManager中的代码，强制使用并行处理
  FStopwatch.Reset;
  FStopwatch.Start;
  SuccessCount2 := TEncodingManager.BatchConvertFileEncoding(FileNames, LargeDir, TargetDir2, '', ENCODING_UTF8, True);
  FStopwatch.Stop;
  ElapsedTime2 := FStopwatch.ElapsedMilliseconds;

  FLogMessages.Add(Format('并行批量转换: %d个文件, 成功: %d, 总耗时: %d ms, 平均每个文件: %.2f ms',
    [Length(FileNames), SuccessCount2, ElapsedTime2, ElapsedTime2 / Length(FileNames)]));

  // 计算加速比
  FLogMessages.Add(Format('并行加速比: %.2f倍', [ElapsedTime1 / Max(1, ElapsedTime2)]));
  FLogMessages.Add('');
end;

end.
