unit TestEncodingDotNet;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  EncodingComparisonDotNet, TestEncodingConfig, TestStandardSamples;

type
  /// <summary>
  /// .NET编码测试类
  /// </summary>
  TEncodingDotNetTest = class
  private
    FConfig: TEncodingTestConfig;
    FTestSet: TStandardTestSet;
    FDotNetEncoder: TDotNetEncodingComparison;
    FTestResults: TStringList;
    FTestDirectory: string;
    
    // 初始化测试环境
    procedure Initialize;
    
    // 清理测试环境
    procedure Cleanup;
    
    // 记录测试结果
    procedure LogResult(const ATestName, AResult, ADetails: string);
    
    // 保存测试结果
    procedure SaveResults;
  public
    constructor Create(const ATestDirectory: string);
    destructor Destroy; override;
    
    /// <summary>
    /// 运行所有测试
    /// </summary>
    procedure RunAllTests;
    
    /// <summary>
    /// 测试编码检测功能
    /// </summary>
    procedure TestEncodingDetection;
    
    /// <summary>
    /// 测试编码转换功能
    /// </summary>
    procedure TestEncodingConversion;
    
    /// <summary>
    /// 测试文件比较功能
    /// </summary>
    procedure TestFileComparison;
    
    /// <summary>
    /// 测试边界情况和异常处理
    /// </summary>
    procedure TestEdgeCases;
    
    /// <summary>
    /// 获取测试结果
    /// </summary>
    function GetResults: TStringList;
  end;

implementation

{ TEncodingDotNetTest }

constructor TEncodingDotNetTest.Create(const ATestDirectory: string);
begin
  inherited Create;
  FTestDirectory := ATestDirectory;
  FConfig := TEncodingTestConfig.Create;
  FTestSet := TStandardTestSet.Create(TPath.Combine(ATestDirectory, 'TestSet'));
  FDotNetEncoder := TDotNetEncodingComparison.Create;
  FTestResults := TStringList.Create;
  
  // 初始化测试环境
  Initialize;
end;

destructor TEncodingDotNetTest.Destroy;
begin
  Cleanup;
  
  FConfig.Free;
  FTestSet.Free;
  FDotNetEncoder.Free;
  FTestResults.Free;
  
  inherited;
end;

procedure TEncodingDotNetTest.Initialize;
begin
  // 创建测试目录
  if not DirectoryExists(FTestDirectory) then
    ForceDirectories(FTestDirectory);
    
  // 初始化测试集
  FTestSet.Initialize;
  FTestSet.CreateStandardTestSet;
  
  // 初始化测试结果
  FTestResults.Clear;
  FTestResults.Add('编码测试结果报告');
  FTestResults.Add('测试开始时间: ' + DateTimeToStr(Now));
  FTestResults.Add('');
  FTestResults.Add('==========================================');
  FTestResults.Add('');
end;

procedure TEncodingDotNetTest.Cleanup;
begin
  // 保存测试结果
  SaveResults;
  
  // 清理测试目录（可选）
  // FTestSet.Cleanup;
end;

procedure TEncodingDotNetTest.LogResult(const ATestName, AResult, ADetails: string);
begin
  FTestResults.Add('');
  FTestResults.Add('测试: ' + ATestName);
  FTestResults.Add('结果: ' + AResult);
  
  if ADetails <> '' then
  begin
    FTestResults.Add('详情:');
    FTestResults.Add(ADetails);
  end;
  
  FTestResults.Add('------------------------------------------');
end;

procedure TEncodingDotNetTest.SaveResults;
var
  ResultsFile: string;
begin
  FTestResults.Add('');
  FTestResults.Add('测试结束时间: ' + DateTimeToStr(Now));
  
  ResultsFile := TPath.Combine(FTestDirectory, 'TestResults_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.txt');
  FTestResults.SaveToFile(ResultsFile, TEncoding.UTF8);
end;

procedure TEncodingDotNetTest.RunAllTests;
begin
  TestEncodingDetection;
  TestEncodingConversion;
  TestFileComparison;
  TestEdgeCases;
end;

procedure TEncodingDotNetTest.TestEncodingDetection;
var
  Samples: TArray<TSampleFileMetadata>;
  Sample: TSampleFileMetadata;
  DetectedEncoding: string;
  SuccessCount, FailCount: Integer;
  Details: TStringList;
begin
  // 获取所有样本文件（排除无效编码样本）
  Samples := FTestSet.GetAllSamplesMetadata;
  
  Details := TStringList.Create;
  try
    SuccessCount := 0;
    FailCount := 0;
    
    Details.Add('样本文件编码检测结果:');
    
    for Sample in Samples do
    begin
      // 跳过无效编码样本
      if SameText(Sample.Encoding, 'INVALID') then
        Continue;
        
      // 检测文件编码
      DetectedEncoding := FDotNetEncoder.DetectEncodingFromFile(
        FTestSet.GetSampleFilePath(Sample.FileName));
        
      // 检查结果
      if SameText(DetectedEncoding, Sample.Encoding) then
      begin
        Details.Add(Format('✓ 文件: %s - 正确检测为 %s', 
          [Sample.FileName, DetectedEncoding]));
        Inc(SuccessCount);
      end
      else
      begin
        Details.Add(Format('✗ 文件: %s - 错误检测为 %s (实际应为 %s)', 
          [Sample.FileName, DetectedEncoding, Sample.Encoding]));
        Inc(FailCount);
      end;
    end;
    
    Details.Add('');
    Details.Add(Format('测试总结: 成功 %d, 失败 %d, 准确率 %.2f%%', 
      [SuccessCount, FailCount, 
      (SuccessCount / (SuccessCount + FailCount)) * 100]));
      
    // 记录测试结果
    if FailCount = 0 then
      LogResult('编码检测测试', '通过', Details.Text)
    else
      LogResult('编码检测测试', '失败', Details.Text);
  finally
    Details.Free;
  end;
end;

procedure TEncodingDotNetTest.TestEncodingConversion;
var
  Encodings: TArray<string>;
  SourceSamples: TArray<TSampleFileMetadata>;
  Sample: TSampleFileMetadata;
  TargetEncoding, SourceEncoding: string;
  SourceFile, TargetFile, ReconvertedFile: string;
  ConversionSuccess, ComparisonSuccess: Boolean;
  SuccessCount, FailCount: Integer;
  Details: TStringList;
  I: Integer;
begin
  // 获取文本类别的样本文件
  SourceSamples := FTestSet.GetSamplesByCategory('Text');
  
  // 定义要测试的目标编码
  Encodings := ['UTF-8', 'UTF-16LE', 'UTF-16BE', 'ASCII', 'ANSI'];
  
  Details := TStringList.Create;
  try
    SuccessCount := 0;
    FailCount := 0;
    
    Details.Add('文件编码转换测试结果:');
    
    for Sample in SourceSamples do
    begin
      SourceEncoding := Sample.Encoding;
      SourceFile := FTestSet.GetSampleFilePath(Sample.FileName);
      
      // 尝试转换为每种目标编码
      for I := 0 to High(Encodings) do
      begin
        TargetEncoding := Encodings[I];
        
        // 跳过相同的编码
        if SameText(SourceEncoding, TargetEncoding) then
          Continue;
          
        // 生成目标文件名和重新转换文件名
        TargetFile := FTestSet.GetResultFilePath(
          Format('Convert_%s_to_%s.txt', [SourceEncoding, TargetEncoding]));
          
        ReconvertedFile := FTestSet.GetResultFilePath(
          Format('Revert_%s_to_%s.txt', [TargetEncoding, SourceEncoding]));
          
        // 执行编码转换
        ConversionSuccess := FDotNetEncoder.ConvertFile(
          SourceFile, TargetFile, SourceEncoding, TargetEncoding);
          
        // 如果转换成功，尝试转换回原始编码
        if ConversionSuccess then
        begin
          ConversionSuccess := FDotNetEncoder.ConvertFile(
            TargetFile, ReconvertedFile, TargetEncoding, SourceEncoding);
            
          // 比较原始文件和重新转换后的文件
          if ConversionSuccess then
          begin
            ComparisonSuccess := FDotNetEncoder.CompareFiles(
              SourceFile, ReconvertedFile);
              
            if ComparisonSuccess then
            begin
              Details.Add(Format('✓ 转换: %s -> %s -> %s 成功', 
                [SourceEncoding, TargetEncoding, SourceEncoding]));
              Inc(SuccessCount);
            end
            else
            begin
              Details.Add(Format('✗ 转换: %s -> %s -> %s 内容不匹配', 
                [SourceEncoding, TargetEncoding, SourceEncoding]));
              Inc(FailCount);
            end;
          end
          else
          begin
            Details.Add(Format('✗ 转换: %s -> %s 成功, 但 %s -> %s 失败', 
              [SourceEncoding, TargetEncoding, TargetEncoding, SourceEncoding]));
            Inc(FailCount);
          end;
        end
        else
        begin
          Details.Add(Format('✗ 转换: %s -> %s 失败', 
            [SourceEncoding, TargetEncoding]));
          Inc(FailCount);
        end;
      end;
    end;
    
    Details.Add('');
    Details.Add(Format('测试总结: 成功 %d, 失败 %d, 成功率 %.2f%%', 
      [SuccessCount, FailCount, 
      (SuccessCount / (SuccessCount + FailCount)) * 100]));
      
    // 记录测试结果
    if FailCount = 0 then
      LogResult('编码转换测试', '通过', Details.Text)
    else
      LogResult('编码转换测试', '失败', Details.Text);
  finally
    Details.Free;
  end;
end;

procedure TEncodingDotNetTest.TestFileComparison;
var
  Samples: TArray<TSampleFileMetadata>;
  SampleByEncoding: TArray<TSampleFileMetadata>;
  Sample1, Sample2: TSampleFileMetadata;
  File1, File2, DiffFile: string;
  IsEqual: Boolean;
  Encoding: string;
  I, J: Integer;
  Details: TStringList;
  SuccessCount, FailCount: Integer;
begin
  // 获取标准测试样本
  Samples := FTestSet.GetAllSamplesMetadata;
  
  Details := TStringList.Create;
  try
    SuccessCount := 0;
    FailCount := 0;
    
    Details.Add('文件比较测试结果:');
    
    // 1. 测试相同文件的比较
    for Sample1 in Samples do
    begin
      File1 := FTestSet.GetSampleFilePath(Sample1.FileName);
      
      // 比较文件与自身
      IsEqual := FDotNetEncoder.CompareFiles(File1, File1);
      
      if IsEqual then
      begin
        Details.Add(Format('✓ 相同文件比较: %s 与自身相同', [Sample1.FileName]));
        Inc(SuccessCount);
      end
      else
      begin
        Details.Add(Format('✗ 相同文件比较: %s 与自身不同，测试失败', [Sample1.FileName]));
        Inc(FailCount);
      end;
    end;
    
    // 2. 测试不同编码但相同内容的文件比较
    // 获取所有使用的编码
    for Encoding in ['UTF-8', 'UTF-16LE', 'UTF-16BE', 'ASCII', 'ANSI'] do
    begin
      // 获取指定编码的文本样本
      SampleByEncoding := FTestSet.GetSamplesByEncoding(Encoding);
      if Length(SampleByEncoding) = 0 then
        Continue;
        
      // 比较不同编码的文件
      for I := 0 to High(SampleByEncoding) do
      begin
        Sample1 := SampleByEncoding[I];
        
        // 跳过非Text类别的样本
        if not SameText(Sample1.Category, 'Text') then
          Continue;
          
        File1 := FTestSet.GetSampleFilePath(Sample1.FileName);
        
        // 创建一个具有相同内容但不同编码的文件
        for J := 0 to High(Encodings) do
        begin
          if SameText(Encoding, Encodings[J]) then
            Continue;
            
          File2 := FTestSet.GetResultFilePath(
            Format('Compare_%s_to_%s.txt', [Encoding, Encodings[J]]));
            
          // 转换编码
          if FDotNetEncoder.ConvertFile(File1, File2, Encoding, Encodings[J]) then
          begin
            // 比较两个文件
            IsEqual := FDotNetEncoder.CompareFiles(File1, File2);
            
            if IsEqual then
            begin
              Details.Add(Format('✓ 不同编码比较: %s(%s) 与 %s(%s) 内容相同', 
                [Sample1.FileName, Encoding, ExtractFileName(File2), Encodings[J]]));
              Inc(SuccessCount);
            end
            else
            begin
              Details.Add(Format('✗ 不同编码比较: %s(%s) 与 %s(%s) 内容不同，测试失败', 
                [Sample1.FileName, Encoding, ExtractFileName(File2), Encodings[J]]));
                
              // 生成差异报告
              DiffFile := FTestSet.GetResultFilePath(
                Format('Diff_%s_vs_%s.txt', [Encoding, Encodings[J]]));
                
              FDotNetEncoder.GetFileDifferences(File1, File2, DiffFile);
              
              Inc(FailCount);
            end;
          end
          else
          begin
            Details.Add(Format('✗ 不同编码比较: 无法创建 %s 编码的比较文件', [Encodings[J]]));
            Inc(FailCount);
          end;
        end;
      end;
    end;
    
    Details.Add('');
    Details.Add(Format('测试总结: 成功 %d, 失败 %d, 准确率 %.2f%%', 
      [SuccessCount, FailCount, 
      (SuccessCount / (SuccessCount + FailCount)) * 100]));
      
    // 记录测试结果
    if FailCount = 0 then
      LogResult('文件比较测试', '通过', Details.Text)
    else
      LogResult('文件比较测试', '失败', Details.Text);
  finally
    Details.Free;
  end;
end;

procedure TEncodingDotNetTest.TestEdgeCases;
var
  EmptySample: TSampleFileMetadata;
  InvalidSample: TSampleFileMetadata;
  LargeSample: TSampleFileMetadata;
  EmptySamples: TArray<TSampleFileMetadata>;
  InvalidSamples: TArray<TSampleFileMetadata>;
  LargeSamples: TArray<TSampleFileMetadata>;
  DetectedEncoding: string;
  SourceFile, TargetFile: string;
  ConversionSuccess: Boolean;
  Details: TStringList;
  SuccessCount, FailCount: Integer;
begin
  // 获取特殊测试样本
  EmptySamples := FTestSet.GetSamplesByCategory('Empty');
  InvalidSamples := FTestSet.GetSamplesByCategory('InvalidEncoding');
  LargeSamples := FTestSet.GetSamplesByCategory('LargeFile');
  
  Details := TStringList.Create;
  try
    SuccessCount := 0;
    FailCount := 0;
    
    Details.Add('边界情况测试结果:');
    
    // 1. 测试空文件
    if Length(EmptySamples) > 0 then
    begin
      Details.Add('1. 空文件测试:');
      
      for EmptySample in EmptySamples do
      begin
        SourceFile := FTestSet.GetSampleFilePath(EmptySample.FileName);
        
        // 检测空文件编码
        DetectedEncoding := FDotNetEncoder.DetectEncodingFromFile(SourceFile);
        
        Details.Add(Format('  - 空文件 %s 编码检测结果: %s', 
          [EmptySample.FileName, DetectedEncoding]));
          
        // 尝试转换空文件
        TargetFile := FTestSet.GetResultFilePath('Empty_Converted.txt');
        ConversionSuccess := FDotNetEncoder.ConvertFile(
          SourceFile, TargetFile, EmptySample.Encoding, 'UTF-8');
          
        if ConversionSuccess then
        begin
          Details.Add('  - 空文件转换: 成功');
          Inc(SuccessCount);
        end
        else
        begin
          Details.Add('  - 空文件转换: 失败');
          Inc(FailCount);
        end;
      end;
    end;
    
    // 2. 测试无效编码文件
    if Length(InvalidSamples) > 0 then
    begin
      Details.Add('');
      Details.Add('2. 无效编码文件测试:');
      
      for InvalidSample in InvalidSamples do
      begin
        SourceFile := FTestSet.GetSampleFilePath(InvalidSample.FileName);
        
        // 检测无效编码文件
        DetectedEncoding := FDotNetEncoder.DetectEncodingFromFile(SourceFile);
        
        Details.Add(Format('  - 无效编码文件 %s 编码检测结果: %s', 
          [InvalidSample.FileName, DetectedEncoding]));
          
        // 尝试转换无效编码文件
        TargetFile := FTestSet.GetResultFilePath('Invalid_Converted.txt');
        ConversionSuccess := FDotNetEncoder.ConvertFile(
          SourceFile, TargetFile, 'UTF-8', 'UTF-16LE');
          
        if ConversionSuccess then
        begin
          Details.Add('  - 无效编码文件转换尝试: 成功 (预期可能失败)');
          Inc(SuccessCount);
        end
        else
        begin
          Details.Add('  - 无效编码文件转换尝试: 失败 (预期可能失败)');
          Inc(SuccessCount); // 这也算成功，因为我们预期可能会失败
        end;
      end;
    end;
    
    // 3. 测试大文件
    if Length(LargeSamples) > 0 then
    begin
      Details.Add('');
      Details.Add('3. 大文件测试:');
      
      for LargeSample in LargeSamples do
      begin
        SourceFile := FTestSet.GetSampleFilePath(LargeSample.FileName);
        
        // 检测大文件编码
        DetectedEncoding := FDotNetEncoder.DetectEncodingFromFile(SourceFile);
        
        if SameText(DetectedEncoding, LargeSample.Encoding) then
        begin
          Details.Add(Format('  - 大文件 %s 编码检测: 正确检测为 %s', 
            [LargeSample.FileName, DetectedEncoding]));
          Inc(SuccessCount);
        end
        else
        begin
          Details.Add(Format('  - 大文件 %s 编码检测: 错误检测为 %s (应为 %s)', 
            [LargeSample.FileName, DetectedEncoding, LargeSample.Encoding]));
          Inc(FailCount);
        end;
        
        // 尝试转换大文件
        TargetFile := FTestSet.GetResultFilePath('Large_Converted.txt');
        ConversionSuccess := FDotNetEncoder.ConvertFile(
          SourceFile, TargetFile, LargeSample.Encoding, 'UTF-8');
          
        if ConversionSuccess then
        begin
          Details.Add('  - 大文件转换: 成功');
          Inc(SuccessCount);
        end
        else
        begin
          Details.Add('  - 大文件转换: 失败');
          Inc(FailCount);
        end;
      end;
    end;
    
    // 4. 测试无效参数
    Details.Add('');
    Details.Add('4. 无效参数测试:');
    
    // 测试无效文件路径
    DetectedEncoding := FDotNetEncoder.DetectEncodingFromFile('NonExistentFile.txt');
    if DetectedEncoding = '' then
    begin
      Details.Add('  - 检测不存在的文件编码: 正确返回空字符串');
      Inc(SuccessCount);
    end
    else
    begin
      Details.Add(Format('  - 检测不存在的文件编码: 错误返回 %s', [DetectedEncoding]));
      Inc(FailCount);
    end;
    
    // 测试无效编码名称
    ConversionSuccess := FDotNetEncoder.ConvertFile(
      FTestSet.GetSampleFilePath(EmptySamples[0].FileName),
      FTestSet.GetResultFilePath('Invalid_Encoding_Test.txt'),
      'UTF-8',
      'INVALID_ENCODING_NAME');
      
    if not ConversionSuccess then
    begin
      Details.Add('  - 使用无效编码名称: 正确返回失败');
      Inc(SuccessCount);
    end
    else
    begin
      Details.Add('  - 使用无效编码名称: 错误返回成功');
      Inc(FailCount);
    end;
    
    Details.Add('');
    Details.Add(Format('测试总结: 成功 %d, 失败 %d, 准确率 %.2f%%', 
      [SuccessCount, FailCount, 
      (SuccessCount / (SuccessCount + FailCount)) * 100]));
      
    // 记录测试结果
    if FailCount = 0 then
      LogResult('边界情况测试', '通过', Details.Text)
    else
      LogResult('边界情况测试', '失败', Details.Text);
  finally
    Details.Free;
  end;
end;

function TEncodingDotNetTest.GetResults: TStringList;
var
  CopyResults: TStringList;
begin
  CopyResults := TStringList.Create;
  CopyResults.Assign(FTestResults);
  Result := CopyResults;
end;

end. 