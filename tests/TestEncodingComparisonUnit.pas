unit TestEncodingComparisonUnit;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  TestFramework, 
  EncodingComparisonDotNet, TestStandardSamples;

type
  /// <summary>
  /// 编码比较功能的测试用例
  /// </summary>
  TEncodingComparisonTest = class(TTestCase)
  private
    FEncodingComparison: TDotNetEncodingComparison;
    FSamplesManager: TStandardSamplesManager;
    FTestDir: string;
    FSamplesDir: string;
    FResultsDir: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基本功能测试
    procedure TestDetectEncoding;
    procedure TestConvertFile;
    procedure TestConvertText;
    procedure TestCompareFiles;
    procedure TestGetFileDifferences;
    
    // 特定编码转换测试
    procedure TestUTF8ToUTF16Conversion;
    procedure TestUTF16ToUTF8Conversion;
    procedure TestANSIToUTF8Conversion;
    
    // 特殊情况测试
    procedure TestEmptyFileConversion;
    procedure TestLargeFileConversion;
    procedure TestSpecialCharsConversion;
    
    // 边界条件测试
    procedure TestFileNotExistsHandling;
    procedure TestInvalidEncodingHandling;
  end;

implementation

{ TEncodingComparisonTest }

procedure TEncodingComparisonTest.SetUp;
begin
  inherited;
  
  // 设置测试目录
  FTestDir := TPath.Combine(ExtractFilePath(ParamStr(0)), 'EncodingTests');
  FSamplesDir := TPath.Combine(FTestDir, 'Samples');
  FResultsDir := TPath.Combine(FTestDir, 'Results');
  
  // 确保目录存在
  ForceDirectories(FTestDir);
  ForceDirectories(FSamplesDir);
  ForceDirectories(FResultsDir);
  
  // 创建测试对象
  FEncodingComparison := TDotNetEncodingComparison.Create;
  FSamplesManager := TStandardSamplesManager.Create(FSamplesDir);
  
  // 创建标准测试集
  FSamplesManager.CreateStandardTestSet;
end;

procedure TEncodingComparisonTest.TearDown;
begin
  // 释放测试对象
  FEncodingComparison.Free;
  FSamplesManager.Free;
  
  inherited;
end;

procedure TEncodingComparisonTest.TestDetectEncoding;
var
  SampleInfo: TSampleInfo;
  Samples: TArray<TSampleInfo>;
  DetectedEncoding: string;
  I: Integer;
begin
  // 获取所有样本
  Samples := FSamplesManager.GetAllSamples;
  
  for I := 0 to Length(Samples) - 1 do
  begin
    SampleInfo := Samples[I];
    
    // 尝试检测编码
    DetectedEncoding := FEncodingComparison.DetectEncodingFromFile(SampleInfo.FilePath);
    
    // 检查是否成功检测
    CheckNotEquals('', DetectedEncoding, '无法检测文件编码: ' + SampleInfo.FileName);
    
    // 对于UTF-8和UTF-16编码，检查是否正确检测
    if (SampleInfo.Encoding = 'UTF-8') or 
       (SampleInfo.Encoding = 'UTF-16LE') or 
       (SampleInfo.Encoding = 'UTF-16BE') then
    begin
      CheckEquals(SampleInfo.Encoding, DetectedEncoding, 
        Format('编码检测错误: 文件 %s, 预期 %s, 实际 %s', 
        [SampleInfo.FileName, SampleInfo.Encoding, DetectedEncoding]));
    end;
  end;
end;

procedure TEncodingComparisonTest.TestConvertFile;
var
  SampleInfo: TSampleInfo;
  UTF8Samples: TArray<TSampleInfo>;
  SourceFilePath, TargetFilePath: string;
  Result: Boolean;
  I: Integer;
begin
  // 获取UTF-8编码的样本
  UTF8Samples := FSamplesManager.GetSamplesByEncoding('UTF-8');
  
  for I := 0 to Length(UTF8Samples) - 1 do
  begin
    SampleInfo := UTF8Samples[I];
    
    // 设置源文件和目标文件路径
    SourceFilePath := SampleInfo.FilePath;
    TargetFilePath := TPath.Combine(FResultsDir, 'Converted_' + SampleInfo.FileName);
    
    // 测试UTF-8到UTF-16LE的转换
    Result := FEncodingComparison.ConvertFile(SourceFilePath, TargetFilePath, 'UTF-8', 'UTF-16LE');
    
    // 验证转换成功
    Check(Result, '文件转换失败: ' + SampleInfo.FileName);
    Check(FileExists(TargetFilePath), '目标文件未创建: ' + TargetFilePath);
    
    // 检测转换后的文件编码
    CheckEquals('UTF-16LE', FEncodingComparison.DetectEncodingFromFile(TargetFilePath),
      '转换后的文件编码不正确: ' + TargetFilePath);
  end;
end;

procedure TEncodingComparisonTest.TestConvertText;
const
  TEST_TEXT = '这是一个编码转换测试。This is an encoding conversion test.';
var
  UTF8Bytes, UTF16Bytes: TBytes;
  ConvertedText: string;
begin
  // UTF-8 到 UTF-16LE 的文本转换
  ConvertedText := FEncodingComparison.ConvertText(TEST_TEXT, 'UTF-8', 'UTF-16LE');
  
  // 检查转换后的文本不为空
  CheckNotEquals('', ConvertedText, 'UTF-8 到 UTF-16LE 的文本转换失败');
  
  // 验证转换后的文本内容与原文相同（忽略编码差异）
  CheckEquals(TEST_TEXT, ConvertedText, '转换后的文本内容与原文不一致');
  
  // UTF-16LE 到 UTF-8 的文本转换
  ConvertedText := FEncodingComparison.ConvertText(TEST_TEXT, 'UTF-16LE', 'UTF-8');
  
  // 检查转换后的文本不为空
  CheckNotEquals('', ConvertedText, 'UTF-16LE 到 UTF-8 的文本转换失败');
  
  // 验证转换后的文本内容与原文相同（忽略编码差异）
  CheckEquals(TEST_TEXT, ConvertedText, '转换后的文本内容与原文不一致');
end;

procedure TEncodingComparisonTest.TestCompareFiles;
var
  SampleInfo: TSampleInfo;
  Samples: TArray<TSampleInfo>;
  SourceFilePath, TargetFilePath: string;
  IsIdentical: Boolean;
  I: Integer;
begin
  // 获取所有样本
  Samples := FSamplesManager.GetAllSamples;
  
  for I := 0 to Length(Samples) - 1 do
  begin
    SampleInfo := Samples[I];
    
    // 设置源文件和目标文件路径
    SourceFilePath := SampleInfo.FilePath;
    TargetFilePath := TPath.Combine(FResultsDir, 'Copy_' + SampleInfo.FileName);
    
    // 复制文件
    TFile.Copy(SourceFilePath, TargetFilePath, True);
    
    // 比较文件
    IsIdentical := FEncodingComparison.CompareFiles(SourceFilePath, TargetFilePath);
    
    // 验证相同文件比较结果为True
    Check(IsIdentical, Format('相同文件比较失败: %s 和 %s', [SourceFilePath, TargetFilePath]));
    
    // 修改目标文件内容
    if FileExists(TargetFilePath) and (TFile.GetSize(TargetFilePath) > 0) then
    begin
      // 向文件末尾添加一些内容以改变其内容
      with TStreamWriter.Create(TargetFilePath, True) do
      try
        WriteLine('Modified content');
      finally
        Free;
      end;
      
      // 比较修改后的文件
      IsIdentical := FEncodingComparison.CompareFiles(SourceFilePath, TargetFilePath);
      
      // 验证不同文件比较结果为False
      Check(not IsIdentical, Format('不同文件比较失败: %s 和 %s', [SourceFilePath, TargetFilePath]));
    end;
  end;
end;

procedure TEncodingComparisonTest.TestGetFileDifferences;
var
  SampleInfo: TSampleInfo;
  SourceFilePath, TargetFilePath: string;
  DifferenceReport: string;
begin
  // 获取一个非空样本
  for SampleInfo in FSamplesManager.GetSamplesByType(stPureText) do
  begin
    if SampleInfo.FileSize > 0 then
      Break;
  end;
  
  // 设置源文件和目标文件路径
  SourceFilePath := SampleInfo.FilePath;
  TargetFilePath := TPath.Combine(FResultsDir, 'Modified_' + SampleInfo.FileName);
  
  // 复制并修改文件
  TFile.Copy(SourceFilePath, TargetFilePath, True);
  with TStreamWriter.Create(TargetFilePath, True) do
  try
    WriteLine('这是添加的新内容，用于测试差异比较功能。');
    WriteLine('This is new content added for testing difference comparison.');
  finally
    Free;
  end;
  
  // 获取文件差异报告
  DifferenceReport := FEncodingComparison.GetFileDifferences(SourceFilePath, TargetFilePath);
  
  // 检查差异报告不为空
  CheckNotEquals('', DifferenceReport, '差异报告生成失败');
  
  // 检查差异报告中包含文件大小信息
  Check(Pos('文件大小', DifferenceReport) > 0, '差异报告中缺少文件大小信息');
  
  // 检查报告中包含内容差异信息
  Check(Pos('内容差异', DifferenceReport) > 0, '差异报告中缺少内容差异信息');
end;

procedure TEncodingComparisonTest.TestUTF8ToUTF16Conversion;
var
  UTF8Samples: TArray<TSampleInfo>;
  SourceFilePath, TargetFilePath: string;
  Result: Boolean;
  I: Integer;
begin
  // 获取UTF-8编码的样本
  UTF8Samples := FSamplesManager.GetSamplesByEncoding('UTF-8');
  
  for I := 0 to Min(Length(UTF8Samples) - 1, 2) do // 测试最多三个样本
  begin
    // 设置源文件和目标文件路径
    SourceFilePath := UTF8Samples[I].FilePath;
    TargetFilePath := TPath.Combine(FResultsDir, 'UTF8ToUTF16_' + UTF8Samples[I].FileName);
    
    // 执行转换
    Result := FEncodingComparison.ConvertFile(SourceFilePath, TargetFilePath, 'UTF-8', 'UTF-16LE');
    
    // 验证转换成功
    Check(Result, 'UTF-8 到 UTF-16LE 转换失败: ' + UTF8Samples[I].FileName);
    
    // 检测转换后的文件编码
    CheckEquals('UTF-16LE', FEncodingComparison.DetectEncodingFromFile(TargetFilePath),
      '转换后的文件编码不正确: ' + TargetFilePath);
  end;
end;

procedure TEncodingComparisonTest.TestUTF16ToUTF8Conversion;
var
  UTF16Samples: TArray<TSampleInfo>;
  SourceFilePath, TargetFilePath: string;
  Result: Boolean;
  I: Integer;
begin
  // 获取UTF-16LE编码的样本
  UTF16Samples := FSamplesManager.GetSamplesByEncoding('UTF-16LE');
  
  for I := 0 to Min(Length(UTF16Samples) - 1, 2) do // 测试最多三个样本
  begin
    // 设置源文件和目标文件路径
    SourceFilePath := UTF16Samples[I].FilePath;
    TargetFilePath := TPath.Combine(FResultsDir, 'UTF16ToUTF8_' + UTF16Samples[I].FileName);
    
    // 执行转换
    Result := FEncodingComparison.ConvertFile(SourceFilePath, TargetFilePath, 'UTF-16LE', 'UTF-8');
    
    // 验证转换成功
    Check(Result, 'UTF-16LE 到 UTF-8 转换失败: ' + UTF16Samples[I].FileName);
    
    // 检测转换后的文件编码
    CheckEquals('UTF-8', FEncodingComparison.DetectEncodingFromFile(TargetFilePath),
      '转换后的文件编码不正确: ' + TargetFilePath);
  end;
end;

procedure TEncodingComparisonTest.TestANSIToUTF8Conversion;
var
  ANSISamples: TArray<TSampleInfo>;
  SourceFilePath, TargetFilePath: string;
  Result: Boolean;
  I: Integer;
begin
  // 获取ANSI编码的样本
  ANSISamples := FSamplesManager.GetSamplesByEncoding('ANSI');
  
  for I := 0 to Min(Length(ANSISamples) - 1, 2) do // 测试最多三个样本
  begin
    // 设置源文件和目标文件路径
    SourceFilePath := ANSISamples[I].FilePath;
    TargetFilePath := TPath.Combine(FResultsDir, 'ANSIToUTF8_' + ANSISamples[I].FileName);
    
    // 执行转换
    Result := FEncodingComparison.ConvertFile(SourceFilePath, TargetFilePath, 'ANSI', 'UTF-8');
    
    // 验证转换成功
    Check(Result, 'ANSI 到 UTF-8 转换失败: ' + ANSISamples[I].FileName);
    
    // 检测转换后的文件编码
    CheckEquals('UTF-8', FEncodingComparison.DetectEncodingFromFile(TargetFilePath),
      '转换后的文件编码不正确: ' + TargetFilePath);
  end;
end;

procedure TEncodingComparisonTest.TestEmptyFileConversion;
var
  EmptySamples: TArray<TSampleInfo>;
  SourceFilePath, TargetFilePath: string;
  Result: Boolean;
  I: Integer;
begin
  // 获取空文本样本
  EmptySamples := FSamplesManager.GetSamplesByType(stEdgeCases);
  
  for I := 0 to Length(EmptySamples) - 1 do
  begin
    // 找到空文本样本
    if (EmptySamples[I].FileSize = 0) or (Pos('空文本', EmptySamples[I].Description) > 0) then
    begin
      // 设置源文件和目标文件路径
      SourceFilePath := EmptySamples[I].FilePath;
      TargetFilePath := TPath.Combine(FResultsDir, 'Empty_Converted_' + EmptySamples[I].FileName);
      
      // 执行转换
      Result := FEncodingComparison.ConvertFile(SourceFilePath, TargetFilePath, 'UTF-8', 'UTF-16LE');
      
      // 验证转换成功
      Check(Result, '空文件转换失败: ' + EmptySamples[I].FileName);
      
      // 检查目标文件已创建
      Check(FileExists(TargetFilePath), '空文件转换后目标文件未创建: ' + TargetFilePath);
      
      // 检查目标文件为空（或几乎为空，可能包含BOM）
      Check(TFile.GetSize(TargetFilePath) <= 4, '转换后的空文件不为空: ' + TargetFilePath);
      
      Break; // 找到一个空文本样本后退出循环
    end;
  end;
end;

procedure TEncodingComparisonTest.TestLargeFileConversion;
var
  LargeSamples: TArray<TSampleInfo>;
  SourceFilePath, TargetFilePath: string;
  Result: Boolean;
  I: Integer;
begin
  // 获取超长文本样本
  LargeSamples := FSamplesManager.GetSamplesByType(stEdgeCases);
  
  for I := 0 to Length(LargeSamples) - 1 do
  begin
    // 找到超长文本样本
    if (LargeSamples[I].FileSize > 10000) or (Pos('超长', LargeSamples[I].Description) > 0) then
    begin
      // 设置源文件和目标文件路径
      SourceFilePath := LargeSamples[I].FilePath;
      TargetFilePath := TPath.Combine(FResultsDir, 'Large_Converted_' + LargeSamples[I].FileName);
      
      // 执行转换
      Result := FEncodingComparison.ConvertFile(SourceFilePath, TargetFilePath, 'UTF-8', 'UTF-16LE');
      
      // 验证转换成功
      Check(Result, '大文件转换失败: ' + LargeSamples[I].FileName);
      
      // 检查目标文件已创建
      Check(FileExists(TargetFilePath), '大文件转换后目标文件未创建: ' + TargetFilePath);
      
      // 检查目标文件大小合理（UTF-16LE通常比UTF-8大）
      Check(TFile.GetSize(TargetFilePath) > LargeSamples[I].FileSize, 
        '转换后的大文件大小不合理: ' + TargetFilePath);
      
      Break; // 找到一个超长文本样本后退出循环
    end;
  end;
end;

procedure TEncodingComparisonTest.TestSpecialCharsConversion;
var
  SpecialCharsSamples: TArray<TSampleInfo>;
  SourceFilePath, TargetFilePath, BackConvertPath: string;
  SourceText, ConvertedText, BackConvertedText: string;
  Result: Boolean;
  I: Integer;
begin
  // 获取特殊字符样本
  SpecialCharsSamples := FSamplesManager.GetSamplesByType(stSpecialChars);
  
  for I := 0 to Min(Length(SpecialCharsSamples) - 1, 2) do // 测试最多三个样本
  begin
    // 设置源文件和目标文件路径
    SourceFilePath := SpecialCharsSamples[I].FilePath;
    TargetFilePath := TPath.Combine(FResultsDir, 'Special_UTF16_' + SpecialCharsSamples[I].FileName);
    BackConvertPath := TPath.Combine(FResultsDir, 'Special_UTF8_' + SpecialCharsSamples[I].FileName);
    
    // 读取源文件文本
    SourceText := TFile.ReadAllText(SourceFilePath);
    
    // 执行UTF-8到UTF-16LE的转换
    Result := FEncodingComparison.ConvertFile(SourceFilePath, TargetFilePath, 'UTF-8', 'UTF-16LE');
    
    // 验证转换成功
    Check(Result, '特殊字符UTF-8到UTF-16LE转换失败: ' + SpecialCharsSamples[I].FileName);
    
    // 执行UTF-16LE到UTF-8的转换
    Result := FEncodingComparison.ConvertFile(TargetFilePath, BackConvertPath, 'UTF-16LE', 'UTF-8');
    
    // 验证转换成功
    Check(Result, '特殊字符UTF-16LE到UTF-8转换失败: ' + SpecialCharsSamples[I].FileName);
    
    // 读取转换回来的文本
    BackConvertedText := TFile.ReadAllText(BackConvertPath);
    
    // 验证转换前后的文本内容一致（忽略可能的BOM差异）
    CheckEquals(Length(SourceText), Length(BackConvertedText), 
      '转换前后的文本长度不一致: ' + SpecialCharsSamples[I].FileName);
    
    // 检查特殊字符是否仍然存在（简单检查是否包含表情符号或特殊符号）
    Check((Pos('😀', BackConvertedText) > 0) or (Pos('€', BackConvertedText) > 0) or
          (Pos('∞', BackConvertedText) > 0) or (Pos('™', BackConvertedText) > 0),
          '转换后的文本丢失了特殊字符: ' + SpecialCharsSamples[I].FileName);
  end;
end;

procedure TEncodingComparisonTest.TestFileNotExistsHandling;
var
  NonExistentFile: string;
  TargetFilePath: string;
  Result: Boolean;
begin
  // 设置不存在的文件路径
  NonExistentFile := TPath.Combine(FTestDir, 'NonExistentFile.txt');
  TargetFilePath := TPath.Combine(FResultsDir, 'Output.txt');
  
  // 确保文件确实不存在
  if FileExists(NonExistentFile) then
    TFile.Delete(NonExistentFile);
  
  // 测试文件检测功能
  CheckEquals('', FEncodingComparison.DetectEncodingFromFile(NonExistentFile),
    '不存在文件的编码检测应返回空字符串');
  
  // 测试文件转换功能
  Result := FEncodingComparison.ConvertFile(NonExistentFile, TargetFilePath, 'UTF-8', 'UTF-16LE');
  Check(not Result, '不存在文件的转换应返回失败');
  
  // 测试文件比较功能
  Result := FEncodingComparison.CompareFiles(NonExistentFile, TargetFilePath);
  Check(not Result, '不存在文件的比较应返回失败');
  
  // 测试差异报告功能
  CheckNotEquals('', FEncodingComparison.GetFileDifferences(NonExistentFile, TargetFilePath),
    '不存在文件的差异报告应包含错误信息');
end;

procedure TEncodingComparisonTest.TestInvalidEncodingHandling;
var
  SampleInfo: TSampleInfo;
  SourceFilePath, TargetFilePath: string;
  Result: Boolean;
begin
  // 获取一个UTF-8样本
  for SampleInfo in FSamplesManager.GetSamplesByEncoding('UTF-8') do
  begin
    if SampleInfo.FileSize > 0 then
      Break;
  end;
  
  // 设置源文件和目标文件路径
  SourceFilePath := SampleInfo.FilePath;
  TargetFilePath := TPath.Combine(FResultsDir, 'Invalid_' + SampleInfo.FileName);
  
  // 测试无效源编码
  Result := FEncodingComparison.ConvertFile(SourceFilePath, TargetFilePath, 'INVALID_ENCODING', 'UTF-8');
  Check(not Result, '无效源编码的转换应返回失败');
  
  // 测试无效目标编码
  Result := FEncodingComparison.ConvertFile(SourceFilePath, TargetFilePath, 'UTF-8', 'INVALID_ENCODING');
  Check(not Result, '无效目标编码的转换应返回失败');
  
  // 测试无效文本转换
  CheckEquals('', FEncodingComparison.ConvertText('测试文本', 'INVALID_ENCODING', 'UTF-8'),
    '无效编码的文本转换应返回空字符串');
end;

initialization
  // 注册测试套件
  RegisterTest(TEncodingComparisonTest.Suite);
end. 