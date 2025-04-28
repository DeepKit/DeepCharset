unit TestUTF8Detection;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes, System.IOUtils,
  UtilsEncodingTypes, UtilsEncodingUTF8Detector, UtilsEncodingUTF8Validator;

type
  [TestFixture]
  TUTF8DetectionTests = class
  private
    FUTF8Detector: TUTF8EncodingDetector;
    FUTF8Validator: TUTF8Validator;
    FTestFilesDir: string;

    procedure CreateTestFile(const FileName: string; const Content: TBytes);
    procedure CreateTestFileWithText(const FileName: string; const Text: string; Encoding: TEncoding);
    procedure DeleteTestFile(const FileName: string);
    function GetTestFilePath(const FileName: string): string;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    // 基本ASCII文本测试
    [Test]
    procedure TestValidateASCIIText;

    // 带BOM的UTF-8文本测试
    [Test]
    procedure TestValidateUTF8WithBOM;

    // 不带BOM的UTF-8文本测试
    [Test]
    procedure TestValidateUTF8WithoutBOM;

    // 混合中英文UTF-8文本测试
    [Test]
    procedure TestValidateMixedChineseEnglishUTF8;

    // 特殊字符UTF-8文本测试
    [Test]
    procedure TestValidateSpecialCharsUTF8;

    // 无效UTF-8序列测试
    [Test]
    procedure TestValidateInvalidUTF8Sequence;

    // 过长UTF-8序列测试
    [Test]
    procedure TestValidateOverlongUTF8Sequence;

    // UTF-8代理对测试
    [Test]
    procedure TestValidateUTF8Surrogate;

    // UTF-8边界值测试
    [Test]
    procedure TestValidateUTF8Boundaries;

    // UTF-8性能测试
    [Test]
    [Category('Performance')]
    procedure TestUTF8DetectionPerformance;

    // UTF-8与其他编码区分测试
    [Test]
    procedure TestDistinguishUTF8FromOtherEncodings;

    // UTF-8文件检测测试
    [Test]
    procedure TestValidateUTF8File;

    // UTF-8流检测测试
    [Test]
    procedure TestValidateUTF8Stream;
  end;

implementation

uses
  System.Diagnostics, System.Math;

{ TUTF8DetectionTests }

procedure TUTF8DetectionTests.Setup;
begin
  FUTF8Detector := TUTF8EncodingDetector.Create;
  FUTF8Validator := TUTF8Validator.Create;

  // 创建测试文件目录
  FTestFilesDir := TPath.Combine(TPath.GetTempPath, 'UTF8Tests');
  if not DirectoryExists(FTestFilesDir) then
    ForceDirectories(FTestFilesDir);
end;

procedure TUTF8DetectionTests.TearDown;
begin
  FUTF8Detector.Free;
  FUTF8Validator.Free;

  // 清理测试文件目录
  if DirectoryExists(FTestFilesDir) then
  begin
    for var FileName in TDirectory.GetFiles(FTestFilesDir) do
      DeleteFile(FileName);
    RemoveDir(FTestFilesDir);
  end;
end;

procedure TUTF8DetectionTests.CreateTestFile(const FileName: string; const Content: TBytes);
var
  FilePath: string;
begin
  FilePath := GetTestFilePath(FileName);
  TFile.WriteAllBytes(FilePath, Content);
end;

procedure TUTF8DetectionTests.CreateTestFileWithText(const FileName: string; const Text: string; Encoding: TEncoding);
var
  FilePath: string;
  Content: TBytes;
begin
  FilePath := GetTestFilePath(FileName);
  Content := Encoding.GetBytes(Text);
  TFile.WriteAllBytes(FilePath, Content);
end;

procedure TUTF8DetectionTests.DeleteTestFile(const FileName: string);
var
  FilePath: string;
begin
  FilePath := GetTestFilePath(FileName);
  if FileExists(FilePath) then
    TFile.Delete(FilePath);
end;

function TUTF8DetectionTests.GetTestFilePath(const FileName: string): string;
begin
  Result := TPath.Combine(FTestFilesDir, FileName);
end;

procedure TUTF8DetectionTests.TestValidateASCIIText;
var
  ASCIIText: string;
  Buffer: TBytes;
  Stats: TEncodingStats;
  Confidence: Double;
begin
  // 创建纯ASCII文本
  ASCIIText := 'This is a simple ASCII text with numbers 123456789 and symbols !@#$%^&*()';
  Buffer := TEncoding.ASCII.GetBytes(ASCIIText);

  // 使用UTF-8检测器验证
  Confidence := FUTF8Detector.ValidateUTF8ContentImproved(Buffer, Stats);

  // ASCII文本应该被识别为有效的UTF-8
  Assert.IsTrue(Confidence > 0.9, 'ASCII文本应该被识别为有效的UTF-8，但置信度为' + FloatToStr(Confidence));
  Assert.AreEqual(0, Stats.InvalidSequences, 'ASCII文本不应包含无效的UTF-8序列');

  // 使用UTF-8验证器验证
  Assert.IsTrue(FUTF8Validator.ValidateUTF8Content(Buffer, Length(Buffer)), 'UTF-8验证器应该将ASCII文本识别为有效的UTF-8');
end;

procedure TUTF8DetectionTests.TestValidateUTF8WithBOM;
var
  UTF8Text: string;
  Buffer, BufferWithBOM: TBytes;
  Stats: TEncodingStats;
  Confidence: Double;
begin
  // 创建UTF-8文本
  UTF8Text := 'This is a UTF-8 text with BOM';
  Buffer := TEncoding.UTF8.GetBytes(UTF8Text);

  // 添加BOM
  SetLength(BufferWithBOM, Length(Buffer) + 3);
  BufferWithBOM[0] := $EF;
  BufferWithBOM[1] := $BB;
  BufferWithBOM[2] := $BF;
  Move(Buffer[0], BufferWithBOM[3], Length(Buffer));

  // 使用UTF-8检测器验证
  Confidence := FUTF8Detector.ValidateUTF8ContentImproved(BufferWithBOM, Stats);

  // 带BOM的UTF-8文本应该被识别为有效的UTF-8
  Assert.IsTrue(Confidence > 0.9, '带BOM的UTF-8文本应该被识别为有效的UTF-8，但置信度为' + FloatToStr(Confidence));
  Assert.AreEqual(0, Stats.InvalidSequences, '带BOM的UTF-8文本不应包含无效的UTF-8序列');

  // 使用UTF-8验证器验证
  Assert.IsTrue(FUTF8Validator.ValidateUTF8Content(BufferWithBOM, Length(BufferWithBOM)), 'UTF-8验证器应该将带BOM的UTF-8文本识别为有效的UTF-8');
end;

procedure TUTF8DetectionTests.TestValidateUTF8WithoutBOM;
var
  UTF8Text: string;
  Buffer: TBytes;
  Stats: TEncodingStats;
  Confidence: Double;
begin
  // 创建不带BOM的UTF-8文本
  UTF8Text := 'This is a UTF-8 text without BOM';
  Buffer := TEncoding.UTF8.GetBytes(UTF8Text);

  // 使用UTF-8检测器验证
  Confidence := FUTF8Detector.ValidateUTF8ContentImproved(Buffer, Stats);

  // 不带BOM的UTF-8文本应该被识别为有效的UTF-8
  Assert.IsTrue(Confidence > 0.9, '不带BOM的UTF-8文本应该被识别为有效的UTF-8，但置信度为' + FloatToStr(Confidence));
  Assert.AreEqual(0, Stats.InvalidSequences, '不带BOM的UTF-8文本不应包含无效的UTF-8序列');

  // 使用UTF-8验证器验证
  Assert.IsTrue(FUTF8Validator.ValidateUTF8Content(Buffer, Length(Buffer)), 'UTF-8验证器应该将不带BOM的UTF-8文本识别为有效的UTF-8');
end;

procedure TUTF8DetectionTests.TestValidateMixedChineseEnglishUTF8;
var
  MixedText: string;
  Buffer: TBytes;
  Stats: TEncodingStats;
  Confidence: Double;
begin
  // 创建混合中英文的UTF-8文本
  MixedText := 'This is a mixed text with Chinese characters: 你好，世界！这是一个UTF-8编码的文本。';
  Buffer := TEncoding.UTF8.GetBytes(MixedText);

  // 使用UTF-8检测器验证
  Confidence := FUTF8Detector.ValidateUTF8ContentImproved(Buffer, Stats);

  // 混合中英文的UTF-8文本应该被识别为有效的UTF-8
  Assert.IsTrue(Confidence > 0.9, '混合中英文的UTF-8文本应该被识别为有效的UTF-8，但置信度为' + FloatToStr(Confidence));
  Assert.AreEqual(0, Stats.InvalidSequences, '混合中英文的UTF-8文本不应包含无效的UTF-8序列');

  // 使用UTF-8验证器验证
  Assert.IsTrue(FUTF8Validator.ValidateUTF8Content(Buffer, Length(Buffer)), 'UTF-8验证器应该将混合中英文的UTF-8文本识别为有效的UTF-8');
end;

procedure TUTF8DetectionTests.TestValidateSpecialCharsUTF8;
var
  SpecialText: string;
  Buffer: TBytes;
  Stats: TEncodingStats;
  Confidence: Double;
begin
  // 创建包含特殊字符的UTF-8文本
  SpecialText := 'Special characters: ☺☻♥♦♣♠•◘○◙♂♀♪♫☼►◄↕‼¶§▬↨↑↓→←∟↔▲▼' +
                 'Emoji: 😀😁😂🤣😃😄😅😆😉😊😋😎😍😘🥰😗😙😚☺️🙂🤗🤩🤔🤨';
  Buffer := TEncoding.UTF8.GetBytes(SpecialText);

  // 使用UTF-8检测器验证
  Confidence := FUTF8Detector.ValidateUTF8ContentImproved(Buffer, Stats);

  // 包含特殊字符的UTF-8文本应该被识别为有效的UTF-8
  Assert.IsTrue(Confidence > 0.9, '包含特殊字符的UTF-8文本应该被识别为有效的UTF-8，但置信度为' + FloatToStr(Confidence));
  Assert.AreEqual(0, Stats.InvalidSequences, '包含特殊字符的UTF-8文本不应包含无效的UTF-8序列');

  // 使用UTF-8验证器验证
  Assert.IsTrue(FUTF8Validator.ValidateUTF8Content(Buffer, Length(Buffer)), 'UTF-8验证器应该将包含特殊字符的UTF-8文本识别为有效的UTF-8');
end;

procedure TUTF8DetectionTests.TestValidateInvalidUTF8Sequence;
var
  Buffer: TBytes;
  Stats: TEncodingStats;
  Confidence: Double;
begin
  // 创建包含无效UTF-8序列的缓冲区
  // 0xC0 0x80 是一个无效的UTF-8序列（过长编码）
  SetLength(Buffer, 4);
  Buffer[0] := Ord('A');
  Buffer[1] := $C0;
  Buffer[2] := $80;
  Buffer[3] := Ord('B');

  // 使用UTF-8检测器验证
  Confidence := FUTF8Detector.ValidateUTF8ContentImproved(Buffer, Stats);

  // 包含无效序列的缓冲区应该被识别为部分有效的UTF-8
  Assert.IsTrue(Confidence < 0.9, '包含无效序列的缓冲区不应该被识别为完全有效的UTF-8');
  Assert.IsTrue(Stats.InvalidSequences > 0, '应该检测到无效的UTF-8序列');

  // 使用UTF-8验证器验证
  Assert.IsFalse(FUTF8Validator.ValidateUTF8Content(Buffer, Length(Buffer)), 'UTF-8验证器应该将包含无效序列的缓冲区识别为无效的UTF-8');
end;

procedure TUTF8DetectionTests.TestValidateOverlongUTF8Sequence;
var
  Buffer: TBytes;
  Stats: TEncodingStats;
  Confidence: Double;
begin
  // 创建包含过长UTF-8序列的缓冲区
  // 0xE0 0x80 0x80 是字符 U+0000 的过长编码
  SetLength(Buffer, 5);
  Buffer[0] := Ord('A');
  Buffer[1] := $E0;
  Buffer[2] := $80;
  Buffer[3] := $80;
  Buffer[4] := Ord('B');

  // 使用UTF-8检测器验证
  Confidence := FUTF8Detector.ValidateUTF8ContentImproved(Buffer, Stats);

  // 包含过长序列的缓冲区应该被识别为部分有效的UTF-8
  Assert.IsTrue(Confidence < 0.9, '包含过长序列的缓冲区不应该被识别为完全有效的UTF-8');
  Assert.IsTrue(Stats.OverlongSequences > 0, '应该检测到过长的UTF-8序列');

  // 使用UTF-8验证器验证
  Assert.IsFalse(FUTF8Validator.ValidateUTF8Content(Buffer, Length(Buffer)), 'UTF-8验证器应该将包含过长序列的缓冲区识别为无效的UTF-8');
end;

procedure TUTF8DetectionTests.TestValidateUTF8Surrogate;
var
  Buffer: TBytes;
  Stats: TEncodingStats;
  Confidence: Double;
begin
  // 创建包含UTF-8编码的代理对的缓冲区
  // 0xED 0xA0 0x80 是代理对范围内的字符 U+D800
  SetLength(Buffer, 5);
  Buffer[0] := Ord('A');
  Buffer[1] := $ED;
  Buffer[2] := $A0;
  Buffer[3] := $80;
  Buffer[4] := Ord('B');

  // 使用UTF-8检测器验证
  Confidence := FUTF8Detector.ValidateUTF8ContentImproved(Buffer, Stats);

  // 包含代理对的缓冲区应该被识别为部分有效的UTF-8
  Assert.IsTrue(Confidence < 0.9, '包含代理对的缓冲区不应该被识别为完全有效的UTF-8');
  Assert.IsTrue(Stats.SurrogateCodePoints > 0, '应该检测到UTF-8编码的代理对');

  // 使用UTF-8验证器验证
  Assert.IsFalse(FUTF8Validator.ValidateUTF8Content(Buffer, Length(Buffer)), 'UTF-8验证器应该将包含代理对的缓冲区识别为无效的UTF-8');
end;

procedure TUTF8DetectionTests.TestValidateUTF8Boundaries;
var
  Buffer: TBytes;
  Stats: TEncodingStats;
  Confidence: Double;
  I: Integer;
begin
  // 测试边界值
  // 创建包含各种边界值的UTF-8序列
  SetLength(Buffer, 16);

  // 最大有效码点 U+10FFFF (F4 8F BF BF)
  I := 0;
  Buffer[I] := $F4; Inc(I);
  Buffer[I] := $8F; Inc(I);
  Buffer[I] := $BF; Inc(I);
  Buffer[I] := $BF; Inc(I);

  // 最小2字节序列 U+0080 (C2 80)
  Buffer[I] := $C2; Inc(I);
  Buffer[I] := $80; Inc(I);

  // 最大2字节序列 U+07FF (DF BF)
  Buffer[I] := $DF; Inc(I);
  Buffer[I] := $BF; Inc(I);

  // 最小3字节序列 U+0800 (E0 A0 80)
  Buffer[I] := $E0; Inc(I);
  Buffer[I] := $A0; Inc(I);
  Buffer[I] := $80; Inc(I);

  // 最大3字节序列 U+FFFF (EF BF BF)
  Buffer[I] := $EF; Inc(I);
  Buffer[I] := $BF; Inc(I);
  Buffer[I] := $BF; Inc(I);

  // 最小4字节序列 U+10000 (F0 90 80 80)
  Buffer[I] := $F0; Inc(I);
  Buffer[I] := $90; Inc(I);
  Buffer[I] := $80; Inc(I);
  Buffer[I] := $80; Inc(I);

  // 使用UTF-8检测器验证
  Confidence := FUTF8Detector.ValidateUTF8ContentImproved(Buffer, Stats);

  // 边界值序列应该被识别为有效的UTF-8
  Assert.IsTrue(Confidence > 0.9, '边界值序列应该被识别为有效的UTF-8，但置信度为' + FloatToStr(Confidence));
  Assert.AreEqual(0, Stats.InvalidSequences, '边界值序列不应包含无效的UTF-8序列');

  // 使用UTF-8验证器验证
  Assert.IsTrue(FUTF8Validator.ValidateUTF8Content(Buffer, Length(Buffer)), 'UTF-8验证器应该将边界值序列识别为有效的UTF-8');
end;

procedure TUTF8DetectionTests.TestUTF8DetectionPerformance;
var
  LargeText: string;
  Buffer: TBytes;
  Stats: TEncodingStats;
  Confidence: Double;
  StopWatch: TStopwatch;
  I: Integer;
  ExecutionTime: Int64;
begin
  // 创建大型UTF-8文本进行性能测试
  LargeText := '';
  for I := 1 to 1000 do
    LargeText := LargeText + 'This is a large UTF-8 text for performance testing. ' +
                 '这是一个用于性能测试的大型UTF-8文本。' +
                 'Special characters: ☺☻♥♦♣♠•◘○◙♂♀♪♫☼►◄↕‼¶§▬↨↑↓→←∟↔▲▼' +
                 'Emoji: 😀😁😂🤣😃😄😅😆😉😊😋😎😍😘🥰😗😙😚☺️🙂🤗🤩🤔🤨';

  Buffer := TEncoding.UTF8.GetBytes(LargeText);

  // 测量性能
  StopWatch := TStopwatch.StartNew;
  Confidence := FUTF8Detector.ValidateUTF8ContentImproved(Buffer, Stats);
  StopWatch.Stop;
  ExecutionTime := StopWatch.ElapsedMilliseconds;

  // 验证结果
  Assert.IsTrue(Confidence > 0.9, '大型UTF-8文本应该被识别为有效的UTF-8');

  // 记录性能数据
  Status(Format('UTF-8检测性能测试: 处理 %d 字节用时 %d 毫秒，每秒处理 %.2f MB',
    [Length(Buffer), ExecutionTime, (Length(Buffer) / 1024 / 1024) / (ExecutionTime / 1000)]));
end;

procedure TUTF8DetectionTests.TestDistinguishUTF8FromOtherEncodings;
var
  UTF8Text, GBKText: string;
  UTF8Buffer, GBKBuffer: TBytes;
  Stats: TEncodingStats;
  UTF8Confidence, GBKConfidence: Double;
begin
  // 创建UTF-8文本
  UTF8Text := '这是UTF-8编码的中文文本。';
  UTF8Buffer := TEncoding.UTF8.GetBytes(UTF8Text);

  // 创建GBK文本
  GBKText := '这是GBK编码的中文文本。';
  GBKBuffer := TEncoding.GetEncoding(936).GetBytes(GBKText); // 936是GBK的代码页

  // 使用UTF-8检测器验证UTF-8文本
  UTF8Confidence := FUTF8Detector.ValidateUTF8ContentImproved(UTF8Buffer, Stats);

  // 使用UTF-8检测器验证GBK文本
  GBKConfidence := FUTF8Detector.ValidateUTF8ContentImproved(GBKBuffer, Stats);

  // UTF-8文本应该有较高的置信度，GBK文本应该有较低的置信度
  Assert.IsTrue(UTF8Confidence > 0.9, 'UTF-8文本应该被识别为有效的UTF-8');
  Assert.IsTrue(GBKConfidence < 0.5, 'GBK文本不应该被识别为有效的UTF-8');

  // 使用UTF-8验证器验证
  Assert.IsTrue(FUTF8Validator.ValidateUTF8Content(UTF8Buffer, Length(UTF8Buffer)), 'UTF-8验证器应该将UTF-8文本识别为有效的UTF-8');
  Assert.IsFalse(FUTF8Validator.ValidateUTF8Content(GBKBuffer, Length(GBKBuffer)), 'UTF-8验证器应该将GBK文本识别为无效的UTF-8');
end;

procedure TUTF8DetectionTests.TestValidateUTF8File;
var
  FileName: string;
  UTF8Text: string;
  Stats: TEncodingStats;
  Confidence: Double;
  FileBuffer: TBytes;
begin
  // 创建UTF-8测试文件
  FileName := 'utf8_test_file.txt';
  UTF8Text := 'This is a UTF-8 text file for testing. 这是一个用于测试的UTF-8文本文件。';
  CreateTestFileWithText(FileName, UTF8Text, TEncoding.UTF8);

  // 读取文件内容
  FileBuffer := TFile.ReadAllBytes(GetTestFilePath(FileName));

  // 使用UTF-8检测器验证
  Confidence := FUTF8Detector.ValidateUTF8ContentImproved(FileBuffer, Stats);

  // UTF-8文件应该被识别为有效的UTF-8
  Assert.IsTrue(Confidence > 0.9, 'UTF-8文件应该被识别为有效的UTF-8，但置信度为' + FloatToStr(Confidence));

  // 使用UTF-8验证器验证文件
  Assert.IsTrue(FUTF8Validator.ValidateUTF8Content(GetTestFilePath(FileName)), 'UTF-8验证器应该将UTF-8文件识别为有效的UTF-8');
end;

procedure TUTF8DetectionTests.TestValidateUTF8Stream;
var
  FileName: string;
  UTF8Text: string;
  FileStream: TFileStream;
begin
  // 创建UTF-8测试文件
  FileName := 'utf8_test_stream.txt';
  UTF8Text := 'This is a UTF-8 text file for stream testing. 这是一个用于流测试的UTF-8文本文件。';
  CreateTestFileWithText(FileName, UTF8Text, TEncoding.UTF8);

  // 创建文件流
  FileStream := TFileStream.Create(GetTestFilePath(FileName), fmOpenRead);
  try
    // 使用UTF-8验证器验证流
    Assert.IsTrue(FUTF8Validator.ValidateUTF8Content(FileStream), 'UTF-8验证器应该将UTF-8流识别为有效的UTF-8');
  finally
    FileStream.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TUTF8DetectionTests);
end.
