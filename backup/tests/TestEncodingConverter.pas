unit TestEncodingConverter;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes, System.IOUtils,
  UtilsEncodingConverter, UtilsEncodingTypes, TestEncodingStandardDataSet;

type
  [TestFixture]
  TTestEncodingConverter = class
  private
    FConverter: TEncodingConverter;
    FDataGenerator: TTestDataGenerator;
    
    procedure TestConversion(const SourceEncoding, TargetEncoding: string);
    procedure TestInvalidEncoding(const SourceEncoding, TargetEncoding: string);
    procedure TestLargeFileConversion(const SourceEncoding, TargetEncoding: string);
    
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    [Test]
    procedure TestUTF8ToGBK;
    [Test]
    procedure TestGBKToUTF8;
    [Test]
    procedure TestBig5ToUTF8;
    [Test]
    procedure TestUTF8ToBig5;
    [Test]
    procedure TestAutoDetectEncoding;
    [Test]
    procedure TestInvalidEncodingHandling;
    [Test]
    procedure TestLargeFileConversion;
    [Test]
    procedure TestBatchConversion;
  end;

implementation

{ TTestEncodingConverter }

procedure TTestEncodingConverter.Setup;
begin
  FConverter := TEncodingConverter.Create;
  FDataGenerator := TTestDataGenerator.Create;
end;

procedure TTestEncodingConverter.TearDown;
begin
  FConverter.Free;
  FDataGenerator.Free;
  FDataGenerator.Cleanup;
end;

procedure TTestEncodingConverter.TestConversion(const SourceEncoding, TargetEncoding: string);
var
  SourceFile, TargetFile: string;
  Result: TEncodingConversionResult;
begin
  // 生成测试文件
  SourceFile := FDataGenerator.GenerateChineseFile(SourceEncoding, 1024);
  TargetFile := TPath.ChangeExtension(SourceFile, '.converted');
  
  try
    // 设置编码
    FConverter.SourceEncoding := SourceEncoding;
    FConverter.TargetEncoding := TargetEncoding;
    
    // 执行转换
    Result := FConverter.ConvertFile(SourceFile, TargetFile);
    
    // 验证结果
    Assert.IsTrue(Result.Success, '转换失败');
    Assert.AreEqual(SourceEncoding, Result.SourceEncoding, '源编码不匹配');
    Assert.AreEqual(TargetEncoding, Result.TargetEncoding, '目标编码不匹配');
    Assert.IsTrue(Result.ErrorCount = 0, '存在转换错误');
    Assert.IsTrue(FileExists(TargetFile), '目标文件未创建');
    
    // 验证文件内容
    Assert.IsTrue(TFile.GetSize(TargetFile) > 0, '目标文件为空');
  finally
    if FileExists(SourceFile) then
      DeleteFile(SourceFile);
    if FileExists(TargetFile) then
      DeleteFile(TargetFile);
  end;
end;

procedure TTestEncodingConverter.TestInvalidEncoding(const SourceEncoding, TargetEncoding: string);
var
  SourceFile, TargetFile: string;
  Result: TEncodingConversionResult;
begin
  // 生成无效编码的测试文件
  SourceFile := FDataGenerator.GenerateInvalidEncodingFile;
  TargetFile := TPath.ChangeExtension(SourceFile, '.converted');
  
  try
    // 设置编码
    FConverter.SourceEncoding := SourceEncoding;
    FConverter.TargetEncoding := TargetEncoding;
    
    // 执行转换
    Result := FConverter.ConvertFile(SourceFile, TargetFile);
    
    // 验证结果
    Assert.IsTrue(Result.Success, '转换失败');
    Assert.IsTrue(Result.ErrorCount > 0, '未检测到无效编码');
    Assert.IsTrue(FileExists(TargetFile), '目标文件未创建');
    
    // 验证文件内容
    Assert.IsTrue(TFile.GetSize(TargetFile) > 0, '目标文件为空');
  finally
    if FileExists(SourceFile) then
      DeleteFile(SourceFile);
    if FileExists(TargetFile) then
      DeleteFile(TargetFile);
  end;
end;

procedure TTestEncodingConverter.TestLargeFileConversion(const SourceEncoding, TargetEncoding: string);
var
  SourceFile, TargetFile: string;
  Result: TEncodingConversionResult;
  StartTime: TDateTime;
begin
  // 生成大文件
  SourceFile := FDataGenerator.GenerateChineseFile(SourceEncoding, 10 * 1024 * 1024);
  TargetFile := TPath.ChangeExtension(SourceFile, '.converted');
  
  try
    // 设置编码
    FConverter.SourceEncoding := SourceEncoding;
    FConverter.TargetEncoding := TargetEncoding;
    
    // 记录开始时间
    StartTime := Now;
    
    // 执行转换
    Result := FConverter.ConvertFile(SourceFile, TargetFile);
    
    // 验证结果
    Assert.IsTrue(Result.Success, '转换失败');
    Assert.IsTrue(Result.ElapsedTime < 5000, '大文件转换时间过长');
    Assert.IsTrue(FileExists(TargetFile), '目标文件未创建');
    Assert.IsTrue(TFile.GetSize(TargetFile) > 0, '目标文件为空');
  finally
    if FileExists(SourceFile) then
      DeleteFile(SourceFile);
    if FileExists(TargetFile) then
      DeleteFile(TargetFile);
  end;
end;

procedure TTestEncodingConverter.TestUTF8ToGBK;
begin
  TestConversion('UTF-8', 'GBK');
end;

procedure TTestEncodingConverter.TestGBKToUTF8;
begin
  TestConversion('GBK', 'UTF-8');
end;

procedure TTestEncodingConverter.TestBig5ToUTF8;
begin
  TestConversion('Big5', 'UTF-8');
end;

procedure TTestEncodingConverter.TestUTF8ToBig5;
begin
  TestConversion('UTF-8', 'Big5');
end;

procedure TTestEncodingConverter.TestAutoDetectEncoding;
var
  SourceFile, TargetFile: string;
  Result: TEncodingConversionResult;
begin
  // 生成测试文件
  SourceFile := FDataGenerator.GenerateChineseFile('UTF-8', 1024);
  TargetFile := TPath.ChangeExtension(SourceFile, '.converted');
  
  try
    // 不设置源编码，让转换器自动检测
    FConverter.SourceEncoding := '';
    FConverter.TargetEncoding := 'GBK';
    
    // 执行转换
    Result := FConverter.ConvertFile(SourceFile, TargetFile);
    
    // 验证结果
    Assert.IsTrue(Result.Success, '转换失败');
    Assert.AreEqual('UTF-8', Result.SourceEncoding, '自动检测编码失败');
    Assert.IsTrue(FileExists(TargetFile), '目标文件未创建');
  finally
    if FileExists(SourceFile) then
      DeleteFile(SourceFile);
    if FileExists(TargetFile) then
      DeleteFile(TargetFile);
  end;
end;

procedure TTestEncodingConverter.TestInvalidEncodingHandling;
begin
  TestInvalidEncoding('UTF-8', 'GBK');
end;

procedure TTestEncodingConverter.TestLargeFileConversion;
begin
  TestLargeFileConversion('UTF-8', 'GBK');
end;

procedure TTestEncodingConverter.TestBatchConversion;
var
  SourceFiles: TArray<string>;
  TargetFiles: TArray<string>;
  i: Integer;
  Result: TEncodingConversionResult;
begin
  // 生成多个测试文件
  SourceFiles := FDataGenerator.GenerateBatchFiles('UTF-8', 10);
  SetLength(TargetFiles, Length(SourceFiles));
  
  try
    // 设置编码
    FConverter.SourceEncoding := 'UTF-8';
    FConverter.TargetEncoding := 'GBK';
    
    // 批量转换
    for i := 0 to High(SourceFiles) do
    begin
      TargetFiles[i] := TPath.ChangeExtension(SourceFiles[i], '.converted');
      Result := FConverter.ConvertFile(SourceFiles[i], TargetFiles[i]);
      
      // 验证每个文件转换结果
      Assert.IsTrue(Result.Success, Format('文件 %s 转换失败', [SourceFiles[i]]));
      Assert.IsTrue(FileExists(TargetFiles[i]), Format('目标文件 %s 未创建', [TargetFiles[i]]));
    end;
  finally
    // 清理文件
    for i := 0 to High(SourceFiles) do
    begin
      if FileExists(SourceFiles[i]) then
        DeleteFile(SourceFiles[i]);
      if FileExists(TargetFiles[i]) then
        DeleteFile(TargetFiles[i]);
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestEncodingConverter);
end. 