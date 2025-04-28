unit TestBOMDetector;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.SyncObjs,
  DUnitX.TestFramework, DUnitX.DUnitCompatibility,
  UtilsEncodingBOM, UtilsEncodingTypes, UtilsEncodingConstants;

type
  [TestFixture]
  TTestBOMDetector = class
  private
    FAsyncEvent: TEvent;
    FAsyncDetectionInfo: TEncodingDetectionInfo;
    FAsyncSuccess: Boolean;
    
    procedure OnBOMDetected(Success: Boolean; const DetectionInfo: TEncodingDetectionInfo);
  public
    [Setup]
    procedure Setup;
    
    [TearDown]
    procedure TearDown;
    
    [Test]
    [TestCase('UTF8BOM', 'utf-8-bom,3,EF BB BF')]
    [TestCase('UTF16LE', 'utf-16le,2,FF FE')]
    [TestCase('UTF16BE', 'utf-16be,2,FE FF')]
    [TestCase('UTF32LE', 'utf-32le,4,FF FE 00 00')]
    [TestCase('UTF32BE', 'utf-32be,4,00 00 FE FF')]
    procedure TestDetectBOM(const EncodingName: string; ExpectedSize: Integer; const HexValues: string);
    
    [Test]
    procedure TestDetectBOMWithEmptyBuffer;
    
    [Test]
    procedure TestDetectBOMWithInvalidBuffer;
    
    [Test]
    procedure TestBOMLength;
    
    [Test]
    procedure TestBOMAddRemove;
    
    [Test]
    procedure TestEncodingSupportsBOM;
    
    [Test]
    procedure TestGetBOMSize;
    
    [Test]
    procedure TestIsValidBOM;
    
    [Test]
    procedure TestDetectBOMAsync;
    
    [Test]
    procedure TestDetectMultipleBOMs;
    
    [Test]
    procedure TestPerformance;
    
    [Test]
    procedure TestLoggingFeatures;
    
    [Test]
    procedure TestLoggerIntegration;
    
    [Test]
    procedure TestFastValidateUTF8;
    
    [Test]
    procedure TestFastDetectBOM;
  end;

implementation

uses
  System.Diagnostics, System.StrUtils, System.IO;

procedure TTestBOMDetector.Setup;
begin
  FAsyncEvent := TEvent.Create;
end;

procedure TTestBOMDetector.TearDown;
begin
  FAsyncEvent.Free;
end;

procedure TTestBOMDetector.OnBOMDetected(Success: Boolean; const DetectionInfo: TEncodingDetectionInfo);
begin
  FAsyncSuccess := Success;
  FAsyncDetectionInfo := DetectionInfo;
  FAsyncEvent.SetEvent;
end;

procedure TTestBOMDetector.TestDetectBOM(const EncodingName: string; ExpectedSize: Integer; const HexValues: string);
var
  Buffer: TBytes;
  DetectionInfo: TEncodingDetectionInfo;
  Success: Boolean;
  HexParts: TStringDynArray;
  I: Integer;
begin
  // 准备测试数据
  HexParts := SplitString(HexValues, ' ');
  SetLength(Buffer, Length(HexParts));
  
  for I := 0 to Length(HexParts) - 1 do
    Buffer[I] := StrToInt('$' + HexParts[I]);
    
  // 添加一些额外的数据
  SetLength(Buffer, Length(Buffer) + 20);
  for I := Length(HexParts) to Length(Buffer) - 1 do
    Buffer[I] := Byte(I mod 256);
    
  // 执行测试
  Success := TBOMDetector.DetectBOM(Buffer, DetectionInfo);
  
  // 验证结果
  Assert.IsTrue(Success, 'BOM检测应该成功');
  Assert.AreEqual(EncodingName, DetectionInfo.EncodingName, '编码名称应匹配');
  Assert.AreEqual(ExpectedSize, DetectionInfo.BOMSize, 'BOM大小应匹配');
  Assert.IsTrue(DetectionInfo.HasBOM, '应该检测到BOM');
  Assert.AreEqual(1.0, DetectionInfo.Confidence, 0.001, 'BOM检测置信度应为1.0');
end;

procedure TTestBOMDetector.TestDetectBOMWithEmptyBuffer;
var
  Buffer: TBytes;
  DetectionInfo: TEncodingDetectionInfo;
  Success: Boolean;
begin
  // 准备空缓冲区
  SetLength(Buffer, 0);
  
  // 执行测试
  Success := TBOMDetector.DetectBOM(Buffer, DetectionInfo);
  
  // 验证结果
  Assert.IsFalse(Success, '空缓冲区不应该检测到BOM');
  Assert.AreEqual(ENCODING_UNKNOWN, DetectionInfo.EncodingName, '未知编码应该返回');
  Assert.IsFalse(DetectionInfo.HasBOM, '不应该有BOM');
  Assert.AreEqual(0, DetectionInfo.BOMSize, 'BOM大小应该为0');
end;

procedure TTestBOMDetector.TestDetectBOMWithInvalidBuffer;
var
  Buffer: TBytes;
  DetectionInfo: TEncodingDetectionInfo;
  Success: Boolean;
  I: Integer;
begin
  // 准备一个没有BOM的随机缓冲区
  SetLength(Buffer, 100);
  for I := 0 to Length(Buffer) - 1 do
    Buffer[I] := Byte(Random(256));
    
  // 确保前几个字节不会被错误识别为BOM
  if Length(Buffer) >= 4 then
  begin
    Buffer[0] := $AA; // 不是BOM的一部分
    Buffer[1] := $BB;
    Buffer[2] := $CC;
    Buffer[3] := $DD;
  end;
  
  // 执行测试
  Success := TBOMDetector.DetectBOM(Buffer, DetectionInfo);
  
  // 验证结果
  Assert.IsFalse(Success, '随机缓冲区不应该检测到BOM');
  Assert.AreEqual(ENCODING_UNKNOWN, DetectionInfo.EncodingName, '未知编码应该返回');
  Assert.IsFalse(DetectionInfo.HasBOM, '不应该有BOM');
  Assert.AreEqual(0, DetectionInfo.BOMSize, 'BOM大小应该为0');
end;

procedure TTestBOMDetector.TestBOMLength;
begin
  // 验证各种编码的BOM大小
  Assert.AreEqual(3, TBOMDetector.GetBOMSize(ENCODING_UTF8_BOM), 'UTF-8 BOM应该是3字节');
  Assert.AreEqual(3, TBOMDetector.GetBOMSize(ENCODING_UTF8), 'UTF-8 BOM应该是3字节');
  Assert.AreEqual(2, TBOMDetector.GetBOMSize(ENCODING_UTF16_LE), 'UTF-16LE BOM应该是2字节');
  Assert.AreEqual(2, TBOMDetector.GetBOMSize(ENCODING_UTF16_BE), 'UTF-16BE BOM应该是2字节');
  Assert.AreEqual(4, TBOMDetector.GetBOMSize(ENCODING_UTF32_LE), 'UTF-32LE BOM应该是4字节');
  Assert.AreEqual(4, TBOMDetector.GetBOMSize(ENCODING_UTF32_BE), 'UTF-32BE BOM应该是4字节');
  Assert.AreEqual(0, TBOMDetector.GetBOMSize(ENCODING_ASCII), 'ASCII不应该有BOM');
  Assert.AreEqual(0, TBOMDetector.GetBOMSize(ENCODING_GBK), 'GBK不应该有BOM');
end;

procedure TTestBOMDetector.TestBOMAddRemove;
var
  OrigBuffer, WithBOM, NoBOM: TBytes;
  DetectedEncoding: string;
  DetectionInfo: TEncodingDetectionInfo;
  I: Integer;
begin
  // 准备一些测试数据
  SetLength(OrigBuffer, 50);
  for I := 0 to Length(OrigBuffer) - 1 do
    OrigBuffer[I] := Byte(65 + (I mod 26)); // ASCII字母
    
  // 测试添加UTF-8 BOM
  WithBOM := TBOMDetector.AddBOM(OrigBuffer, ENCODING_UTF8_BOM);
  
  // 验证添加了BOM
  Assert.IsTrue(TBOMDetector.DetectBOM(WithBOM, DetectionInfo), '应该检测到BOM');
  Assert.AreEqual(ENCODING_UTF8_BOM, DetectionInfo.EncodingName, '应该是UTF-8 BOM');
  
  // 测试移除BOM
  NoBOM := TBOMDetector.RemoveBOM(WithBOM, DetectedEncoding);
  
  // 验证BOM被移除
  Assert.AreEqual(ENCODING_UTF8_BOM, DetectedEncoding, '检测到的编码应该是UTF-8 BOM');
  Assert.AreEqual(Length(OrigBuffer), Length(NoBOM), '移除BOM后长度应该与原始缓冲区相同');
  
  // 验证移除BOM后的内容与原始内容相同
  for I := 0 to Length(OrigBuffer) - 1 do
    Assert.AreEqual(OrigBuffer[I], NoBOM[I], '字节应该匹配');
    
  // 测试不支持BOM的编码
  WithBOM := TBOMDetector.AddBOM(OrigBuffer, ENCODING_ASCII);
  Assert.AreEqual(Length(OrigBuffer), Length(WithBOM), '不支持BOM的编码不应该添加BOM');
end;

procedure TTestBOMDetector.TestEncodingSupportsBOM;
begin
  // 测试支持BOM的编码
  Assert.IsTrue(TBOMDetector.EncodingSupportsBOM(ENCODING_UTF8), 'UTF-8应该支持BOM');
  Assert.IsTrue(TBOMDetector.EncodingSupportsBOM(ENCODING_UTF8_BOM), 'UTF-8 BOM应该支持BOM');
  Assert.IsTrue(TBOMDetector.EncodingSupportsBOM(ENCODING_UTF16_LE), 'UTF-16LE应该支持BOM');
  Assert.IsTrue(TBOMDetector.EncodingSupportsBOM(ENCODING_UTF16_BE), 'UTF-16BE应该支持BOM');
  Assert.IsTrue(TBOMDetector.EncodingSupportsBOM(ENCODING_UTF32_LE), 'UTF-32LE应该支持BOM');
  Assert.IsTrue(TBOMDetector.EncodingSupportsBOM(ENCODING_UTF32_BE), 'UTF-32BE应该支持BOM');
  
  // 测试不支持BOM的编码
  Assert.IsFalse(TBOMDetector.EncodingSupportsBOM(ENCODING_ASCII), 'ASCII不应该支持BOM');
  Assert.IsFalse(TBOMDetector.EncodingSupportsBOM(ENCODING_GBK), 'GBK不应该支持BOM');
  Assert.IsFalse(TBOMDetector.EncodingSupportsBOM(ENCODING_BIG5), 'Big5不应该支持BOM');
  Assert.IsFalse(TBOMDetector.EncodingSupportsBOM(ENCODING_SHIFT_JIS), 'Shift-JIS不应该支持BOM');
end;

procedure TTestBOMDetector.TestGetBOMSize;
begin
  // 这个测试在TestBOMLength中已经完成，这里是为了代码覆盖率
  Assert.AreEqual(3, TBOMDetector.GetBOMSize(ENCODING_UTF8), 'UTF-8 BOM应该是3字节');
end;

procedure TTestBOMDetector.TestIsValidBOM;
var
  Buffer: TBytes;
  I: Integer;
begin
  // 测试UTF-8 BOM
  SetLength(Buffer, 10);
  Buffer[0] := $EF;
  Buffer[1] := $BB;
  Buffer[2] := $BF;
  
  // 填充剩余字节
  for I := 3 to Length(Buffer) - 1 do
    Buffer[I] := Byte(I);
    
  // 测试有效的BOM
  Assert.IsTrue(TBOMDetector.IsValidBOM(Buffer, ENCODING_UTF8_BOM), 'UTF-8 BOM应该被识别为有效');
  
  // 测试无效的BOM
  Buffer[0] := $EE; // 修改第一个字节
  Assert.IsFalse(TBOMDetector.IsValidBOM(Buffer, ENCODING_UTF8_BOM), '修改后的BOM应该被识别为无效');
  
  // 测试不支持BOM的编码
  Assert.IsFalse(TBOMDetector.IsValidBOM(Buffer, ENCODING_ASCII), 'ASCII不支持BOM，应该返回false');
end;

procedure TTestBOMDetector.TestDetectBOMAsync;
var
  Buffer: TBytes;
  Task: ITask;
  Success: Boolean;
begin
  // 准备UTF-8 BOM数据
  SetLength(Buffer, 10);
  Buffer[0] := $EF;
  Buffer[1] := $BB;
  Buffer[2] := $BF;
  
  // 重置事件和结果
  FAsyncEvent.ResetEvent;
  FAsyncSuccess := False;
  FAsyncDetectionInfo.Clear;
  
  // 执行异步检测
  Task := TBOMDetector.DetectBOMAsync(Buffer, OnBOMDetected);
  
  // 等待异步操作完成
  Success := FAsyncEvent.WaitFor(5000) = wrSignaled;
  
  // 验证结果
  Assert.IsTrue(Success, '异步操作应该在超时前完成');
  Assert.IsTrue(FAsyncSuccess, '异步BOM检测应该成功');
  Assert.AreEqual(ENCODING_UTF8_BOM, FAsyncDetectionInfo.EncodingName, '异步检测应该识别为UTF-8 BOM');
  Assert.AreEqual(3, FAsyncDetectionInfo.BOMSize, 'BOM大小应该是3字节');
end;

procedure TTestBOMDetector.TestDetectMultipleBOMs;
var
  Buffer: TBytes;
  DetectionInfo: TEncodingDetectionInfo;
  Success: Boolean;
begin
  // 创建一个缓冲区，包含多个连续的BOM
  SetLength(Buffer, 20);
  
  // 添加UTF-8 BOM
  Buffer[0] := $EF;
  Buffer[1] := $BB;
  Buffer[2] := $BF;
  
  // 添加UTF-16LE BOM
  Buffer[3] := $FF;
  Buffer[4] := $FE;
  
  // 添加UTF-16BE BOM
  Buffer[5] := $FE;
  Buffer[6] := $FF;
  
  // 剩余部分填充随机数据
  for var I := 7 to Length(Buffer) - 1 do
    Buffer[I] := Byte(I);
    
  // 执行检测，应该只识别第一个BOM
  Success := TBOMDetector.DetectBOM(Buffer, DetectionInfo);
  
  // 验证结果
  Assert.IsTrue(Success, 'BOM检测应该成功');
  Assert.AreEqual(ENCODING_UTF8_BOM, DetectionInfo.EncodingName, '应该只识别第一个BOM (UTF-8)');
  Assert.AreEqual(3, DetectionInfo.BOMSize, 'BOM大小应该是3字节');
end;

procedure TTestBOMDetector.TestPerformance;
var
  Buffer: TBytes;
  DetectionInfo: TEncodingDetectionInfo;
  StopWatch: TStopwatch;
  I, J, IterationCount: Integer;
  TotalTime: Int64;
begin
  // 准备测试数据
  SetLength(Buffer, 1024); // 1KB 数据
  
  // 添加UTF-8 BOM
  Buffer[0] := $EF;
  Buffer[1] := $BB;
  Buffer[2] := $BF;
  
  // 填充剩余部分
  for I := 3 to Length(Buffer) - 1 do
    Buffer[I] := Byte(I mod 256);
    
  // 测试性能
  IterationCount := 10000; // 执行10000次
  TotalTime := 0;
  
  for J := 1 to IterationCount do
  begin
    StopWatch := TStopwatch.StartNew;
    TBOMDetector.DetectBOM(Buffer, DetectionInfo);
    StopWatch.Stop;
    TotalTime := TotalTime + StopWatch.ElapsedTicks;
    
    // 验证检测结果正确
    Assert.AreEqual(ENCODING_UTF8_BOM, DetectionInfo.EncodingName, '应该检测为UTF-8 BOM');
  end;
  
  // 输出平均耗时
  var AvgMicroseconds := (TotalTime * 1000000) div (IterationCount * TStopwatch.Frequency);
  
  // 确保足够快（平均每次小于某个阈值，如50微秒）
  Assert.IsTrue(AvgMicroseconds < 50, Format('BOM检测平均耗时应该小于50微秒，实际为%d微秒', [AvgMicroseconds]));
end;

procedure TTestBOMDetector.TestLoggingFeatures;
var
  Logger: TLogger;
  TempLogFile: string;
  Buffer: TBytes;
  DetectionInfo: TEncodingDetectionInfo;
  LogContent: string;
begin
  // 创建临时日志文件
  TempLogFile := TPath.GetTempFileName;
  try
    // 创建自定义Logger
    Logger := TLogger.Create(TempLogFile, llDebug);
    try
      // 启用时间记录
      Logger.TimingEnabled := True;
      
      // 准备测试数据 - UTF-8 BOM
      SetLength(Buffer, 10);
      Buffer[0] := $EF;
      Buffer[1] := $BB;
      Buffer[2] := $BF;
      for var I := 3 to 9 do
        Buffer[I] := Byte(65 + I); // 一些ASCII字符
      
      // 设置BOM检测器使用我们的Logger
      TBOMDetector.SetLogger(Logger);
      
      // 执行BOM检测
      TBOMDetector.DetectBOM(Buffer, DetectionInfo);
      
      // 验证日志文件是否已创建且内容非空
      Assert.IsTrue(FileExists(TempLogFile), '日志文件应该被创建');
      LogContent := TFile.ReadAllText(TempLogFile);
      Assert.IsTrue(LogContent <> '', '日志内容不应为空');
      
      // 验证日志中包含BOM检测相关信息
      Assert.IsTrue(LogContent.Contains('检测到BOM'), '日志应包含BOM检测信息');
      Assert.IsTrue(LogContent.Contains('UTF-8'), '日志应包含编码信息');
      Assert.IsTrue(LogContent.Contains('EF BB BF'), '日志应包含BOM值');
      Assert.IsTrue(LogContent.Contains('耗时'), '日志应包含性能信息');
    finally
      Logger.Free;
    end;
  finally
    if FileExists(TempLogFile) then
      TFile.Delete(TempLogFile);
  end;
end;

procedure TTestBOMDetector.TestLoggerIntegration;
var
  MockLogger: TLogger;
  Buffer: TBytes;
  DetectionInfo: TEncodingDetectionInfo;
begin
  // 创建一个不写入文件的Logger
  MockLogger := TLogger.Create('');
  try
    // 设置日志记录级别为Debug
    MockLogger.LogLevel := llDebug;
    
    // 设置BOM检测器使用我们的Logger
    TBOMDetector.SetLogger(MockLogger);
    
    // 准备测试数据 - UTF-16LE BOM
    SetLength(Buffer, 10);
    Buffer[0] := $FF;
    Buffer[1] := $FE;
    for var I := 2 to 9 do
      Buffer[I] := Byte(65 + I); // 一些ASCII字符
    
    // 执行BOM检测
    TBOMDetector.DetectBOM(Buffer, DetectionInfo);
    
    // 验证检测结果
    Assert.AreEqual(ENCODING_UTF16_LE, DetectionInfo.EncodingName, '编码应为UTF-16LE');
    
    // 准备测试数据 - UTF-32BE BOM
    SetLength(Buffer, 10);
    Buffer[0] := $00;
    Buffer[1] := $00;
    Buffer[2] := $FE;
    Buffer[3] := $FF;
    
    // 执行BOM检测
    TBOMDetector.DetectBOM(Buffer, DetectionInfo);
    
    // 验证检测结果
    Assert.AreEqual(ENCODING_UTF32_BE, DetectionInfo.EncodingName, '编码应为UTF-32BE');
  finally
    MockLogger.Free;
    
    // 恢复默认Logger
    TBOMDetector.SetLogger(nil);
  end;
end;

procedure TTestBOMDetector.TestFastValidateUTF8;
var
  Buffer: TBytes;
  Valid: Boolean;
begin
  // 测试有效的UTF-8序列
  SetLength(Buffer, 20);
  
  // 添加ASCII字符 (单字节)
  Buffer[0] := $41; // 'A'
  Buffer[1] := $42; // 'B'
  Buffer[2] := $43; // 'C'
  
  // 添加2字节UTF-8序列 (拉丁字母附加符号)
  Buffer[3] := $C3;
  Buffer[4] := $A9; // é
  
  // 添加3字节UTF-8序列 (中文字符)
  Buffer[5] := $E4;
  Buffer[6] := $B8;
  Buffer[7] := $AD; // 中
  
  // 添加4字节UTF-8序列 (表情符号)
  Buffer[8] := $F0;
  Buffer[9] := $9F;
  Buffer[10] := $98;
  Buffer[11] := $81; // 😁
  
  // 添加更多ASCII字符
  for var I := 12 to 19 do
    Buffer[I] := $61 + Byte(I - 12); // a-h
  
  // 验证有效的UTF-8
  Valid := TBOMDetector.FastValidateUTF8(Buffer, 0, Length(Buffer));
  Assert.IsTrue(Valid, '有效的UTF-8序列应该被验证为有效');
  
  // 修改缓冲区使其包含无效序列
  Buffer[5] := $E4; // 开始一个3字节序列
  Buffer[6] := $B8;
  Buffer[7] := $FF; // 无效的UTF-8字节 (应该是10xxxxxx格式)
  
  // 验证无效的UTF-8
  Valid := TBOMDetector.FastValidateUTF8(Buffer, 0, Length(Buffer));
  Assert.IsFalse(Valid, '无效的UTF-8序列应该被验证为无效');
  
  // 测试空缓冲区
  SetLength(Buffer, 0);
  Valid := TBOMDetector.FastValidateUTF8(Buffer, 0, 0);
  Assert.IsTrue(Valid, '空缓冲区默认应该被验证为有效');
  
  // 测试只有ASCII的缓冲区
  SetLength(Buffer, 10);
  for var I := 0 to 9 do
    Buffer[I] := $61 + Byte(I); // a-j
  Valid := TBOMDetector.FastValidateUTF8(Buffer, 0, Length(Buffer));
  Assert.IsTrue(Valid, '纯ASCII缓冲区应该被验证为有效UTF-8');
end;

procedure TTestBOMDetector.TestFastDetectBOM;
var
  Buffer: TBytes;
  EncodingName: string;
begin
  // 测试UTF-8 BOM
  SetLength(Buffer, 5);
  Buffer[0] := $EF;
  Buffer[1] := $BB;
  Buffer[2] := $BF;
  Buffer[3] := $41; // 'A'
  Buffer[4] := $42; // 'B'
  
  EncodingName := TBOMDetector.FastDetectBOM(Buffer);
  Assert.AreEqual(ENCODING_UTF8_BOM, EncodingName, '应该快速检测到UTF-8 BOM');
  
  // 测试UTF-16LE BOM
  SetLength(Buffer, 5);
  Buffer[0] := $FF;
  Buffer[1] := $FE;
  Buffer[2] := $41; // 'A' in UTF-16LE
  Buffer[3] := $00;
  Buffer[4] := $42; // 'B' in UTF-16LE
  
  EncodingName := TBOMDetector.FastDetectBOM(Buffer);
  Assert.AreEqual(ENCODING_UTF16_LE, EncodingName, '应该快速检测到UTF-16LE BOM');
  
  // 测试UTF-16BE BOM
  SetLength(Buffer, 5);
  Buffer[0] := $FE;
  Buffer[1] := $FF;
  Buffer[2] := $00;
  Buffer[3] := $41; // 'A' in UTF-16BE
  Buffer[4] := $00;
  
  EncodingName := TBOMDetector.FastDetectBOM(Buffer);
  Assert.AreEqual(ENCODING_UTF16_BE, EncodingName, '应该快速检测到UTF-16BE BOM');
  
  // 测试UTF-32LE BOM
  SetLength(Buffer, 8);
  Buffer[0] := $FF;
  Buffer[1] := $FE;
  Buffer[2] := $00;
  Buffer[3] := $00;
  Buffer[4] := $41; // 'A' in UTF-32LE
  Buffer[5] := $00;
  Buffer[6] := $00;
  Buffer[7] := $00;
  
  EncodingName := TBOMDetector.FastDetectBOM(Buffer);
  Assert.AreEqual(ENCODING_UTF32_LE, EncodingName, '应该快速检测到UTF-32LE BOM');
  
  // 测试UTF-32BE BOM
  SetLength(Buffer, 8);
  Buffer[0] := $00;
  Buffer[1] := $00;
  Buffer[2] := $FE;
  Buffer[3] := $FF;
  Buffer[4] := $00;
  Buffer[5] := $00;
  Buffer[6] := $00;
  Buffer[7] := $41; // 'A' in UTF-32BE
  
  EncodingName := TBOMDetector.FastDetectBOM(Buffer);
  Assert.AreEqual(ENCODING_UTF32_BE, EncodingName, '应该快速检测到UTF-32BE BOM');
  
  // 测试无BOM
  SetLength(Buffer, 5);
  Buffer[0] := $41; // 'A'
  Buffer[1] := $42; // 'B'
  Buffer[2] := $43; // 'C'
  Buffer[3] := $44; // 'D'
  Buffer[4] := $45; // 'E'
  
  EncodingName := TBOMDetector.FastDetectBOM(Buffer);
  Assert.AreEqual('', EncodingName, '无BOM应该返回空字符串');
  
  // 测试空缓冲区
  SetLength(Buffer, 0);
  EncodingName := TBOMDetector.FastDetectBOM(Buffer);
  Assert.AreEqual('', EncodingName, '空缓冲区应该返回空字符串');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestBOMDetector);

end. 