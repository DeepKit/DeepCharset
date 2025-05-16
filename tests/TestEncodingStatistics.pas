unit TestEncodingStatistics;

interface

uses
  System.SysUtils, System.Classes,
  DUnitX.TestFramework,
  EncodingStatistics;

type
  [TestFixture]
  TEncodingStatisticsTests = class
  private
    FStatistics: TEncodingStatistics;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    // 基础测试
    [Test]
    procedure TestCreateAndDestroy;
    
    // 分析测试
    [Test]
    procedure TestAnalyzeEmptyBuffer;
    [Test]
    procedure TestAnalyzeASCIIBuffer;
    [Test]
    procedure TestAnalyzeUTF8Buffer;
    [Test]
    procedure TestAnalyzeGBKBuffer;
    [Test]
    procedure TestAnalyzeBig5Buffer;
    [Test]
    procedure TestAnalyzeMixedBuffer;
    
    // 评分测试
    [Test]
    procedure TestCalculateScoreForASCII;
    [Test]
    procedure TestCalculateScoreForUTF8;
    [Test]
    procedure TestCalculateScoreForGBK;
    [Test]
    procedure TestCalculateScoreForBig5;
    
    // 辅助函数测试
    [Test]
    procedure TestGetTopNFrequencies;
    [Test]
    procedure TestExportStatisticsToCSV;
    
    // 文件和流测试
    [Test]
    procedure TestAnalyzeStream;
    [Test]
    procedure TestAnalyzeFile;
    [Test]
    procedure TestAnalyzeFileNotFound;
    
    // 辅助方法
    procedure GenerateTestFile(const FileName: string; const Encoding: TEncoding);
  end;

implementation

procedure TEncodingStatisticsTests.Setup;
begin
  FStatistics := TEncodingStatistics.Create;
end;

procedure TEncodingStatisticsTests.TearDown;
begin
  FStatistics.Free;
  FStatistics := nil;
end;

procedure TEncodingStatisticsTests.TestCreateAndDestroy;
begin
  // 测试基本的创建和销毁，确保不会发生异常
  var Stats := TEncodingStatistics.Create;
  try
    // 确保创建没有问题
    Assert.IsNotNull(Stats);
  finally
    Stats.Free;
  end;
end;

procedure TEncodingStatisticsTests.TestAnalyzeEmptyBuffer;
begin
  // 测试分析空缓冲区，确保不会引发异常
  var Buffer: TBytes := [];
  Assert.WillNotRaiseAny(
    procedure
    begin
      FStatistics.AnalyzeBuffer(Buffer);
    end
  );
  
  // 检查结果
  var Freqs := FStatistics.GetByteFrequencies;
  Assert.AreEqual(256, Length(Freqs), '频率数组应该包含256项');
  
  // 所有频率应该为0
  for var i := 0 to 255 do
  begin
    Assert.AreEqual(0, Freqs[i].Count, Format('字节0x%2.2X的计数应为0', [i]));
    Assert.AreEqual(0, Freqs[i].Percentage, Format('字节0x%2.2X的百分比应为0', [i]));
  end;
end;

procedure TEncodingStatisticsTests.TestAnalyzeASCIIBuffer;
var
  Buffer: TBytes;
  ByteFreqs: TByteFrequencyArray;
begin
  // 创建一个纯ASCII测试缓冲区
  SetLength(Buffer, 100);
  for var i := 0 to 99 do
    Buffer[i] := 65 + (i mod 26); // A-Z循环
    
  // 分析
  FStatistics.AnalyzeBuffer(Buffer);
  
  // 检查结果
  ByteFreqs := FStatistics.GetTopNFrequencies(26);
  Assert.AreEqual(26, Length(ByteFreqs), '应该获取26个最常见字节');
  
  // 检查ASCII字符的频率
  for var i := 0 to 25 do
  begin
    Assert.AreEqual(4, ByteFreqs[i].Count, 
      Format('字符%s的计数应该是4', [Char(65 + i)]));
    Assert.AreEqual(4.0, ByteFreqs[i].Percentage, 
      Format('字符%s的百分比应该是4%%', [Char(65 + i)]));
  end;
  
  // 检查ASCII得分
  Assert.AreEqual(1.0, FStatistics.CalculateASCIIScore, 'ASCII得分应该是1.0');
  Assert.IsTrue(FStatistics.CalculateUTF8Score > 0.8, 'UTF-8得分应该大于0.8');
  Assert.IsTrue(FStatistics.CalculateGBKScore < 0.5, 'GBK得分应该小于0.5');
  Assert.IsTrue(FStatistics.CalculateBig5Score < 0.5, 'Big5得分应该小于0.5');
end;

procedure TEncodingStatisticsTests.TestAnalyzeUTF8Buffer;
var
  Buffer: TBytes;
  Utf8String: UTF8String;
begin
  // 创建一个包含中文字符的UTF-8字符串
  Utf8String := UTF8String('这是一个UTF-8编码的测试字符串');
  SetLength(Buffer, Length(Utf8String));
  Move(Utf8String[1], Buffer[0], Length(Utf8String));
  
  // 分析
  FStatistics.AnalyzeBuffer(Buffer);
  
  // 检查UTF-8得分应该高于其他编码
  var UTF8Score := FStatistics.CalculateUTF8Score;
  var GBKScore := FStatistics.CalculateGBKScore;
  var Big5Score := FStatistics.CalculateBig5Score;
  var ASCIIScore := FStatistics.CalculateASCIIScore;
  
  Assert.IsTrue(UTF8Score > GBKScore, 'UTF-8得分应高于GBK得分');
  Assert.IsTrue(UTF8Score > Big5Score, 'UTF-8得分应高于Big5得分');
  Assert.IsTrue(UTF8Score > ASCIIScore, 'UTF-8得分应高于ASCII得分');
  Assert.IsTrue(UTF8Score > 0.7, 'UTF-8得分应大于0.7');
end;

procedure TEncodingStatisticsTests.GenerateTestFile(const FileName: string; const Encoding: TEncoding);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Add('这是第一行测试文本');
    SL.Add('这是第二行测试文本');
    SL.Add('This is English text line');
    SL.Add('这是混合English的行');
    SL.Add('包含特殊字符：!@#$%^&*()_+');
    
    SL.Encoding := Encoding;
    SL.SaveToFile(FileName);
  finally
    SL.Free;
  end;
end;

procedure TEncodingStatisticsTests.TestAnalyzeGBKBuffer;
begin
  // 由于GBK分析需要实际的GBK编码数据，我们生成一个临时文件进行测试
  var TempFile := 'temp_gbk_test.txt';
  GenerateTestFile(TempFile, TEncoding.GetEncoding(936)); // 936是GBK代码页
  
  try
    // 分析文件
    FStatistics.AnalyzeFile(TempFile);
    
    // GBK文件中应该有比较高的GBK有效序列比例
    var GBKScore := FStatistics.CalculateGBKScore;
    Assert.IsTrue(GBKScore > 0.5, 'GBK得分应大于0.5');
  finally
    // 删除临时文件
    if FileExists(TempFile) then
      DeleteFile(TempFile);
  end;
end;

procedure TEncodingStatisticsTests.TestAnalyzeBig5Buffer;
begin
  // 由于Big5分析需要实际的Big5编码数据，我们生成一个临时文件进行测试
  var TempFile := 'temp_big5_test.txt';
  GenerateTestFile(TempFile, TEncoding.GetEncoding(950)); // 950是Big5代码页
  
  try
    // 分析文件
    FStatistics.AnalyzeFile(TempFile);
    
    // Big5文件中应该有较高的Big5有效序列比例
    var Big5Score := FStatistics.CalculateBig5Score;
    // 注意：由于简体中文字符在Big5中可能没有对应，这里得分可能不会很高
    Assert.IsTrue(Big5Score > 0.3, 'Big5得分应大于0.3');
  finally
    // 删除临时文件
    if FileExists(TempFile) then
      DeleteFile(TempFile);
  end;
end;

procedure TEncodingStatisticsTests.TestAnalyzeMixedBuffer;
var
  Buffer1, Buffer2, MixedBuffer: TBytes;
  Utf8String: UTF8String;
  AsciiString: AnsiString;
begin
  // 创建一个UTF-8部分
  Utf8String := UTF8String('这是UTF-8编码的部分');
  SetLength(Buffer1, Length(Utf8String));
  Move(Utf8String[1], Buffer1[0], Length(Utf8String));
  
  // 创建一个ASCII部分
  AsciiString := AnsiString('This is ASCII part');
  SetLength(Buffer2, Length(AsciiString));
  Move(AsciiString[1], Buffer2[0], Length(AsciiString));
  
  // 合并缓冲区
  SetLength(MixedBuffer, Length(Buffer1) + Length(Buffer2));
  Move(Buffer1[0], MixedBuffer[0], Length(Buffer1));
  Move(Buffer2[0], MixedBuffer[Length(Buffer1)], Length(Buffer2));
  
  // 分析
  FStatistics.AnalyzeBuffer(MixedBuffer);
  
  // 检查特征
  var Features := FStatistics.GetEncodingFeatures;
  var HasASCIIRatio := False;
  var ASCIIRatio := 0.0;
  
  for var i := 0 to High(Features) do
  begin
    if Features[i].Name = 'ASCIIRatio' then
    begin
      HasASCIIRatio := True;
      ASCIIRatio := Features[i].Value;
      Break;
    end;
  end;
  
  Assert.IsTrue(HasASCIIRatio, '应该有ASCIIRatio特征');
  Assert.IsTrue((ASCIIRatio > 0.3) and (ASCIIRatio < 0.7), 
    Format('ASCII比例应在0.3到0.7之间，实际为%.2f', [ASCIIRatio]));
end;

procedure TEncodingStatisticsTests.TestCalculateScoreForASCII;
var
  Buffer: TBytes;
  AsciiString: AnsiString;
begin
  // 创建一个纯ASCII字符串
  AsciiString := AnsiString('This is a test string with only ASCII characters: 0123456789!@#$%^&*()');
  SetLength(Buffer, Length(AsciiString));
  Move(AsciiString[1], Buffer[0], Length(AsciiString));
  
  // 分析
  FStatistics.AnalyzeBuffer(Buffer);
  
  // 检查得分
  Assert.AreEqual(1.0, FStatistics.CalculateASCIIScore, 'ASCII得分应为1.0');
  // ASCII也是有效的UTF-8
  Assert.IsTrue(FStatistics.CalculateUTF8Score > 0.8, 'UTF-8得分应大于0.8');
  // ASCII不太可能是专门的GBK或Big5
  Assert.IsTrue(FStatistics.CalculateGBKScore < 0.5, 'GBK得分应小于0.5');
  Assert.IsTrue(FStatistics.CalculateBig5Score < 0.5, 'Big5得分应小于0.5');
end;

procedure TEncodingStatisticsTests.TestCalculateScoreForUTF8;
var
  Buffer: TBytes;
  Utf8String: UTF8String;
begin
  // 创建一个包含多语言字符的UTF-8字符串
  Utf8String := UTF8String('这是中文，This is English, Это русский, これは日本語です, 이것은 한국어입니다');
  SetLength(Buffer, Length(Utf8String));
  Move(Utf8String[1], Buffer[0], Length(Utf8String));
  
  // 分析
  FStatistics.AnalyzeBuffer(Buffer);
  
  // 检查得分
  Assert.IsTrue(FStatistics.CalculateUTF8Score > 0.7, 'UTF-8得分应大于0.7');
  Assert.IsTrue(FStatistics.CalculateUTF8Score > FStatistics.CalculateGBKScore, 
    'UTF-8得分应高于GBK得分');
  Assert.IsTrue(FStatistics.CalculateUTF8Score > FStatistics.CalculateBig5Score, 
    'UTF-8得分应高于Big5得分');
end;

procedure TEncodingStatisticsTests.TestCalculateScoreForGBK;
begin
  // 使用临时文件测试GBK得分
  var TempFile := 'temp_gbk_score_test.txt';
  GenerateTestFile(TempFile, TEncoding.GetEncoding(936)); // 936是GBK代码页
  
  try
    // 分析文件
    FStatistics.AnalyzeFile(TempFile);
    
    // GBK得分应该相对较高
    var GBKScore := FStatistics.CalculateGBKScore;
    var UTF8Score := FStatistics.CalculateUTF8Score;
    
    // 注意：由于GBK和UTF-8都能表示中文，得分可能比较接近
    Assert.IsTrue(GBKScore > 0.5, Format('GBK得分应大于0.5，实际为%.2f', [GBKScore]));
    // 输出得分以便调试
    System.WriteLn(Format('GBK得分: %.2f, UTF-8得分: %.2f', [GBKScore, UTF8Score]));
  finally
    // 删除临时文件
    if FileExists(TempFile) then
      DeleteFile(TempFile);
  end;
end;

procedure TEncodingStatisticsTests.TestCalculateScoreForBig5;
begin
  // 使用临时文件测试Big5得分
  var TempFile := 'temp_big5_score_test.txt';
  GenerateTestFile(TempFile, TEncoding.GetEncoding(950)); // 950是Big5代码页
  
  try
    // 分析文件
    FStatistics.AnalyzeFile(TempFile);
    
    // Big5得分应该相对较高
    var Big5Score := FStatistics.CalculateBig5Score;
    
    // 注意：由于使用的是简体中文测试文本，在Big5编码中得分可能不会很高
    Assert.IsTrue(Big5Score > 0.3, Format('Big5得分应大于0.3，实际为%.2f', [Big5Score]));
  finally
    // 删除临时文件
    if FileExists(TempFile) then
      DeleteFile(TempFile);
  end;
end;

procedure TEncodingStatisticsTests.TestGetTopNFrequencies;
var
  Buffer: TBytes;
  TopFreqs: TByteFrequencyArray;
begin
  // 创建一个具有已知频率的缓冲区
  SetLength(Buffer, 100);
  // 'A' 出现40次
  for var i := 0 to 39 do
    Buffer[i] := 65; // 'A'
  // 'B' 出现30次
  for var i := 40 to 69 do
    Buffer[i] := 66; // 'B'
  // 'C' 出现20次
  for var i := 70 to 89 do
    Buffer[i] := 67; // 'C'
  // 'D' 出现10次
  for var i := 90 to 99 do
    Buffer[i] := 68; // 'D'
    
  // 分析缓冲区
  FStatistics.AnalyzeBuffer(Buffer);
  
  // 获取前3个频率最高的字节
  TopFreqs := FStatistics.GetTopNFrequencies(3);
  Assert.AreEqual(3, Length(TopFreqs), '应该获取3个最常见字节');
  
  // 验证结果
  Assert.AreEqual(65, TopFreqs[0].ByteValue, '第一个应该是A (65)');
  Assert.AreEqual(40, TopFreqs[0].Count, 'A应该出现40次');
  Assert.AreEqual(40.0, TopFreqs[0].Percentage, 'A的百分比应该是40%');
  
  Assert.AreEqual(66, TopFreqs[1].ByteValue, '第二个应该是B (66)');
  Assert.AreEqual(30, TopFreqs[1].Count, 'B应该出现30次');
  Assert.AreEqual(30.0, TopFreqs[1].Percentage, 'B的百分比应该是30%');
  
  Assert.AreEqual(67, TopFreqs[2].ByteValue, '第三个应该是C (67)');
  Assert.AreEqual(20, TopFreqs[2].Count, 'C应该出现20次');
  Assert.AreEqual(20.0, TopFreqs[2].Percentage, 'C的百分比应该是20%');
end;

procedure TEncodingStatisticsTests.TestExportStatisticsToCSV;
var
  Buffer: TBytes;
  CSV: string;
  Lines: TArray<string>;
begin
  // 创建一个简单的测试缓冲区
  SetLength(Buffer, 10);
  for var i := 0 to 9 do
    Buffer[i] := 65 + i; // A-J
    
  // 分析
  FStatistics.AnalyzeBuffer(Buffer);
  
  // 导出为CSV
  CSV := FStatistics.ExportStatisticsToCSV;
  Assert.IsNotEmpty(CSV, 'CSV不应为空');
  
  // 检查CSV格式
  Lines := CSV.Split([#13#10, #10, #13]);
  Assert.IsTrue(Length(Lines) > 3, '应该有多行数据');
  Assert.IsTrue(Lines[0].StartsWith('统计类型'), '第一行应该包含标题');
  Assert.IsTrue(Lines[1].StartsWith('TotalBytes'), '应该包含总字节数');
  
  // 检查是否包含字节频率
  var HasByteFreq := False;
  for var Line in Lines do
  begin
    if Line.StartsWith('ByteFreq') then
    begin
      HasByteFreq := True;
      Break;
    end;
  end;
  Assert.IsTrue(HasByteFreq, 'CSV应该包含字节频率数据');
  
  // 检查是否包含编码得分
  var HasScore := False;
  for var Line in Lines do
  begin
    if Line.StartsWith('Score') then
    begin
      HasScore := True;
      Break;
    end;
  end;
  Assert.IsTrue(HasScore, 'CSV应该包含编码得分数据');
end;

procedure TEncodingStatisticsTests.TestAnalyzeStream;
var
  Stream: TMemoryStream;
  Buffer: TBytes;
begin
  // 创建一个内存流
  Stream := TMemoryStream.Create;
  try
    // 写入一些数据
    SetLength(Buffer, 26);
    for var i := 0 to 25 do
      Buffer[i] := 65 + i; // A-Z
    Stream.WriteBuffer(Buffer[0], Length(Buffer));
    
    // 重置流位置
    Stream.Position := 0;
    
    // 分析流
    FStatistics.AnalyzeStream(Stream);
    
    // 验证结果
    var ByteFreqs := FStatistics.GetByteFrequencies;
    for var i := 0 to 25 do
    begin
      var Index := -1;
      // 查找字节在结果数组中的位置
      for var j := 0 to 255 do
      begin
        if ByteFreqs[j].ByteValue = 65 + i then
        begin
          Index := j;
          Break;
        end;
      end;
      
      Assert.IsTrue(Index >= 0, Format('应找到字节%d', [65 + i]));
      Assert.AreEqual(1, ByteFreqs[Index].Count, Format('字节%d应出现1次', [65 + i]));
    end;
  finally
    Stream.Free;
  end;
end;

procedure TEncodingStatisticsTests.TestAnalyzeFile;
begin
  // 生成一个测试文件
  var TempFile := 'temp_analyze_file_test.txt';
  var SL := TStringList.Create;
  try
    // 写入一些数据
    SL.Add('This is a test file.');
    SL.Add('It contains some ASCII text.');
    SL.SaveToFile(TempFile);
    
    // 分析文件
    FStatistics.AnalyzeFile(TempFile);
    
    // 验证结果
    Assert.IsTrue(FStatistics.CalculateASCIIScore > 0.9, 'ASCII得分应大于0.9');
    
    // 检查导出的CSV
    var CSV := FStatistics.ExportStatisticsToCSV;
    Assert.IsNotEmpty(CSV, 'CSV不应为空');
    
    // 保存统计数据到文件
    var StatsFile := 'temp_stats.csv';
    FStatistics.SaveStatisticsToFile(StatsFile);
    
    // 验证统计文件存在
    Assert.IsTrue(FileExists(StatsFile), '统计文件应存在');
    
    // 删除统计文件
    if FileExists(StatsFile) then
      DeleteFile(StatsFile);
  finally
    SL.Free;
    // 删除临时文件
    if FileExists(TempFile) then
      DeleteFile(TempFile);
  end;
end;

procedure TEncodingStatisticsTests.TestAnalyzeFileNotFound;
begin
  // 测试不存在的文件
  var NonExistentFile := 'this_file_does_not_exist.txt';
  
  // 确保文件不存在
  if FileExists(NonExistentFile) then
    DeleteFile(NonExistentFile);
    
  // 预期会抛出异常
  Assert.WillRaise(
    procedure
    begin
      FStatistics.AnalyzeFile(NonExistentFile);
    end,
    EFileNotFoundException
  );
end;

initialization
  TDUnitX.RegisterTestFixture(TEncodingStatisticsTests);
end. 