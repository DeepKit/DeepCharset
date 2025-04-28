unit TestEncodingDetector;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes, System.IOUtils,
  UtilsEncodingDetector, UtilsEncodingTypes, TestEncodingStandardDataSet;

type
  [TestFixture]
  TTestEncodingDetector = class
  private
    FDetector: TEncodingDetector;
    FDataGenerator: TTestDataGenerator;
    
    procedure TestBOMDetection(const Encoding: string; const BOM: TBytes);
    procedure TestEncodingDetection(const Encoding: string; const Size: Integer);
    procedure TestInvalidEncoding;
    
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    [Test]
    procedure TestUTF8BOM;
    [Test]
    procedure TestUTF16LEBOM;
    [Test]
    procedure TestUTF16BEBOM;
    [Test]
    procedure TestUTF32LEBOM;
    [Test]
    procedure TestUTF32BEBOM;
    
    [Test]
    procedure TestUTF8Detection;
    [Test]
    procedure TestGBKDetection;
    [Test]
    procedure TestBig5Detection;
    [Test]
    procedure TestShiftJISDetection;
    [Test]
    procedure TestEUCKRDetection;
    
    [Test]
    procedure TestInvalidEncodingDetection;
    [Test]
    procedure TestEmptyFileDetection;
    [Test]
    procedure TestLargeFileDetection;
  end;

implementation

{ TTestEncodingDetector }

procedure TTestEncodingDetector.Setup;
begin
  FDetector := TEncodingDetector.Create;
  FDataGenerator := TTestDataGenerator.Create;
end;

procedure TTestEncodingDetector.TearDown;
begin
  FDetector.Free;
  FDataGenerator.Free;
  FDataGenerator.Cleanup;
end;

procedure TTestEncodingDetector.TestBOMDetection(const Encoding: string; const BOM: TBytes);
var
  FilePath: string;
  Result: TEncodingInfo;
begin
  // 创建带BOM的测试文件
  FilePath := FDataGenerator.GenerateFileWithBOM(Encoding, BOM, 1024);
  
  try
    // 检测编码
    Result := FDetector.DetectEncoding(FilePath);
    
    // 验证结果
    Assert.IsTrue(Result.IsValid, 'BOM检测失败');
    Assert.AreEqual(Encoding, Result.Encoding, '编码不匹配');
    Assert.IsTrue(Result.Confidence = 1.0, '置信度不是1.0');
    Assert.IsTrue(Length(Result.BOM) = Length(BOM), 'BOM长度不匹配');
    Assert.IsTrue(CompareMem(@Result.BOM[0], @BOM[0], Length(BOM)), 'BOM内容不匹配');
  finally
    if FileExists(FilePath) then
      DeleteFile(FilePath);
  end;
end;

procedure TTestEncodingDetector.TestEncodingDetection(const Encoding: string; const Size: Integer);
var
  FilePath: string;
  Result: TEncodingInfo;
begin
  // 创建测试文件
  FilePath := FDataGenerator.GenerateChineseFile(Encoding, Size);
  
  try
    // 检测编码
    Result := FDetector.DetectEncoding(FilePath);
    
    // 验证结果
    Assert.IsTrue(Result.IsValid, '编码检测失败');
    Assert.AreEqual(Encoding, Result.Encoding, '编码不匹配');
    Assert.IsTrue(Result.Confidence > 0.5, '置信度过低');
  finally
    if FileExists(FilePath) then
      DeleteFile(FilePath);
  end;
end;

procedure TTestEncodingDetector.TestInvalidEncoding;
var
  FilePath: string;
  Result: TEncodingInfo;
begin
  // 创建无效编码的测试文件
  FilePath := FDataGenerator.GenerateInvalidEncodingFile;
  
  try
    // 检测编码
    Result := FDetector.DetectEncoding(FilePath);
    
    // 验证结果
    Assert.IsFalse(Result.IsValid, '不应检测到有效编码');
    Assert.AreEqual('Unknown', Result.Encoding, '编码不是Unknown');
    Assert.IsTrue(Result.Confidence = 0, '置信度不是0');
  finally
    if FileExists(FilePath) then
      DeleteFile(FilePath);
  end;
end;

procedure TTestEncodingDetector.TestUTF8BOM;
begin
  TestBOMDetection('UTF-8', [$EF, $BB, $BF]);
end;

procedure TTestEncodingDetector.TestUTF16LEBOM;
begin
  TestBOMDetection('UTF-16LE', [$FF, $FE]);
end;

procedure TTestEncodingDetector.TestUTF16BEBOM;
begin
  TestBOMDetection('UTF-16BE', [$FE, $FF]);
end;

procedure TTestEncodingDetector.TestUTF32LEBOM;
begin
  TestBOMDetection('UTF-32LE', [$FF, $FE, $00, $00]);
end;

procedure TTestEncodingDetector.TestUTF32BEBOM;
begin
  TestBOMDetection('UTF-32BE', [$00, $00, $FE, $FF]);
end;

procedure TTestEncodingDetector.TestUTF8Detection;
begin
  TestEncodingDetection('UTF-8', 1024);
end;

procedure TTestEncodingDetector.TestGBKDetection;
begin
  TestEncodingDetection('GBK', 1024);
end;

procedure TTestEncodingDetector.TestBig5Detection;
begin
  TestEncodingDetection('Big5', 1024);
end;

procedure TTestEncodingDetector.TestShiftJISDetection;
begin
  TestEncodingDetection('Shift-JIS', 1024);
end;

procedure TTestEncodingDetector.TestEUCKRDetection;
begin
  TestEncodingDetection('EUC-KR', 1024);
end;

procedure TTestEncodingDetector.TestInvalidEncodingDetection;
begin
  TestInvalidEncoding;
end;

procedure TTestEncodingDetector.TestEmptyFileDetection;
var
  FilePath: string;
  Result: TEncodingInfo;
begin
  // 创建空文件
  FilePath := FDataGenerator.GenerateEmptyFile;
  
  try
    // 检测编码
    Result := FDetector.DetectEncoding(FilePath);
    
    // 验证结果
    Assert.IsFalse(Result.IsValid, '不应检测到有效编码');
    Assert.AreEqual('Unknown', Result.Encoding, '编码不是Unknown');
    Assert.IsTrue(Result.Confidence = 0, '置信度不是0');
  finally
    if FileExists(FilePath) then
      DeleteFile(FilePath);
  end;
end;

procedure TTestEncodingDetector.TestLargeFileDetection;
begin
  TestEncodingDetection('UTF-8', 10 * 1024 * 1024);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestEncodingDetector);
end. 