unit TestEncodingDetection;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, UtilsEncodingTypes,
  UtilsEncodingBOM_Improved, UtilsEncodingUTF8Detector_Improved,
  ChineseEncodingDetector_Improved, UTF8BOMConverter_Improved,
  EncodingConverter_Improved;

type
  /// <summary>
  /// 编码检测测试类
  /// </summary>
  TEncodingDetectionTest = class
  private
    /// <summary>
    /// 创建测试文件
    /// </summary>
    class function CreateTestFile(const FileName: string; const Content: string; CodePage: Integer; AddBOM: Boolean = False): Boolean;
    
    /// <summary>
    /// 测试UTF-8检测
    /// </summary>
    class function TestUTF8Detection: Boolean;
    
    /// <summary>
    /// 测试中文编码检测
    /// </summary>
    class function TestChineseEncodingDetection: Boolean;
    
    /// <summary>
    /// 测试BOM检测
    /// </summary>
    class function TestBOMDetection: Boolean;
    
    /// <summary>
    /// 测试UTF-8 BOM转换
    /// </summary>
    class function TestUTF8BOMConversion: Boolean;
    
    /// <summary>
    /// 测试编码转换
    /// </summary>
    class function TestEncodingConversion: Boolean;
    
  public
    /// <summary>
    /// 运行所有测试
    /// </summary>
    class function RunAllTests: Boolean;
    
    /// <summary>
    /// 测试文件编码检测
    /// </summary>
    class function TestFileEncodingDetection(const FileName: string): string;
  end;

implementation

{ TEncodingDetectionTest }

class function TEncodingDetectionTest.CreateTestFile(const FileName: string; const Content: string; CodePage: Integer; AddBOM: Boolean): Boolean;
var
  FileStream: TFileStream;
  Buffer: TBytes;
  BOMBytes: TBytes;
begin
  Result := False;
  
  try
    // 创建文件
    FileStream := TFileStream.Create(FileName, fmCreate);
    try
      // 添加BOM（如果需要）
      if AddBOM then
      begin
        case CodePage of
          65001: // UTF-8
            begin
              SetLength(BOMBytes, 3);
              BOMBytes[0] := $EF;
              BOMBytes[1] := $BB;
              BOMBytes[2] := $BF;
            end;
          1200: // UTF-16 LE
            begin
              SetLength(BOMBytes, 2);
              BOMBytes[0] := $FF;
              BOMBytes[1] := $FE;
            end;
          1201: // UTF-16 BE
            begin
              SetLength(BOMBytes, 2);
              BOMBytes[0] := $FE;
              BOMBytes[1] := $FF;
            end;
          12000: // UTF-32 LE
            begin
              SetLength(BOMBytes, 4);
              BOMBytes[0] := $FF;
              BOMBytes[1] := $FE;
              BOMBytes[2] := $00;
              BOMBytes[3] := $00;
            end;
          12001: // UTF-32 BE
            begin
              SetLength(BOMBytes, 4);
              BOMBytes[0] := $00;
              BOMBytes[1] := $00;
              BOMBytes[2] := $FE;
              BOMBytes[3] := $FF;
            end;
        end;
        
        if Length(BOMBytes) > 0 then
          FileStream.WriteBuffer(BOMBytes[0], Length(BOMBytes));
      end;
      
      // 转换内容为指定编码
      case CodePage of
        65001: // UTF-8
          begin
            var UTF8Str := UTF8Encode(Content);
            SetLength(Buffer, Length(UTF8Str));
            if Length(UTF8Str) > 0 then
              Move(UTF8Str[1], Buffer[0], Length(UTF8Str));
          end;
        1200, 1201: // UTF-16
          begin
            var WideStr := Content;
            SetLength(Buffer, Length(WideStr) * 2);
            if Length(WideStr) > 0 then
              Move(WideStr[1], Buffer[0], Length(WideStr) * 2);
          end;
        else // ANSI or other
          begin
            var AnsiStr := UnicodeStringToString(Content, CodePage);
            SetLength(Buffer, Length(AnsiStr));
            if Length(AnsiStr) > 0 then
              Move(AnsiStr[1], Buffer[0], Length(AnsiStr));
          end;
      end;
      
      // 写入内容
      if Length(Buffer) > 0 then
        FileStream.WriteBuffer(Buffer[0], Length(Buffer));
        
      Result := True;
    finally
      FileStream.Free;
    end;
  except
    Result := False;
  end;
end;

class function TEncodingDetectionTest.RunAllTests: Boolean;
var
  TestResults: array[1..5] of Boolean;
  TestNames: array[1..5] of string;
  i: Integer;
  SuccessCount: Integer;
begin
  // 设置测试名称
  TestNames[1] := 'UTF-8检测测试';
  TestNames[2] := '中文编码检测测试';
  TestNames[3] := 'BOM检测测试';
  TestNames[4] := 'UTF-8 BOM转换测试';
  TestNames[5] := '编码转换测试';
  
  // 运行测试
  TestResults[1] := TestUTF8Detection;
  TestResults[2] := TestChineseEncodingDetection;
  TestResults[3] := TestBOMDetection;
  TestResults[4] := TestUTF8BOMConversion;
  TestResults[5] := TestEncodingConversion;
  
  // 输出测试结果
  WriteLn('编码检测和转换测试结果:');
  WriteLn('----------------------------------------');
  
  SuccessCount := 0;
  for i := 1 to 5 do
  begin
    if TestResults[i] then
      Inc(SuccessCount);
      
    WriteLn(Format('%s: %s', [TestNames[i], BoolToStr(TestResults[i], '通过', '失败')]));
  end;
  
  WriteLn('----------------------------------------');
  WriteLn(Format('总结: %d/%d 测试通过', [SuccessCount, 5]));
  
  Result := (SuccessCount = 5);
end;

class function TEncodingDetectionTest.TestBOMDetection: Boolean;
const
  TEST_FILE_PREFIX = 'test_bom_';
var
  TestFiles: array[1..5] of string;
  ExpectedResults: array[1..5] of TBOMType;
  i: Integer;
  BOMResult: TBOMDetectionResult;
  Success: Boolean;
begin
  // 创建测试文件
  TestFiles[1] := TEST_FILE_PREFIX + 'utf8.txt';
  TestFiles[2] := TEST_FILE_PREFIX + 'utf16le.txt';
  TestFiles[3] := TEST_FILE_PREFIX + 'utf16be.txt';
  TestFiles[4] := TEST_FILE_PREFIX + 'utf32le.txt';
  TestFiles[5] := TEST_FILE_PREFIX + 'utf32be.txt';
  
  ExpectedResults[1] := bomUTF8;
  ExpectedResults[2] := bomUTF16LE;
  ExpectedResults[3] := bomUTF16BE;
  ExpectedResults[4] := bomUTF32LE;
  ExpectedResults[5] := bomUTF32BE;
  
  // 创建测试文件
  CreateTestFile(TestFiles[1], '这是UTF-8测试文件', 65001, True);
  CreateTestFile(TestFiles[2], '这是UTF-16LE测试文件', 1200, True);
  CreateTestFile(TestFiles[3], '这是UTF-16BE测试文件', 1201, True);
  CreateTestFile(TestFiles[4], '这是UTF-32LE测试文件', 12000, True);
  CreateTestFile(TestFiles[5], '这是UTF-32BE测试文件', 12001, True);
  
  // 测试BOM检测
  Success := True;
  for i := 1 to 5 do
  begin
    BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromFile(TestFiles[i]);
    
    if BOMResult.BOMType <> ExpectedResults[i] then
    begin
      WriteLn(Format('BOM检测失败: %s, 期望: %d, 实际: %d', [TestFiles[i], Ord(ExpectedResults[i]), Ord(BOMResult.BOMType)]));
      Success := False;
    end;
  end;
  
  // 清理测试文件
  for i := 1 to 5 do
  begin
    if FileExists(TestFiles[i]) then
      DeleteFile(TestFiles[i]);
  end;
  
  Result := Success;
end;

class function TEncodingDetectionTest.TestChineseEncodingDetection: Boolean;
const
  TEST_FILE_PREFIX = 'test_chinese_';
var
  TestFiles: array[1..4] of string;
  ExpectedResults: array[1..4] of string;
  i: Integer;
  ChineseResult: TChineseEncodingResult;
  Success: Boolean;
begin
  // 创建测试文件
  TestFiles[1] := TEST_FILE_PREFIX + 'gbk.txt';
  TestFiles[2] := TEST_FILE_PREFIX + 'gb18030.txt';
  TestFiles[3] := TEST_FILE_PREFIX + 'big5.txt';
  TestFiles[4] := TEST_FILE_PREFIX + 'gb2312.txt';
  
  ExpectedResults[1] := ENCODING_GBK;
  ExpectedResults[2] := ENCODING_GB18030;
  ExpectedResults[3] := ENCODING_BIG5;
  ExpectedResults[4] := ENCODING_GB2312;
  
  // 创建测试文件
  CreateTestFile(TestFiles[1], '这是GBK测试文件', 936);
  CreateTestFile(TestFiles[2], '这是GB18030测试文件', 54936);
  CreateTestFile(TestFiles[3], '這是Big5測試文件', 950);
  CreateTestFile(TestFiles[4], '这是GB2312测试文件', 936);
  
  // 测试中文编码检测
  Success := True;
  for i := 1 to 4 do
  begin
    ChineseResult := TChineseEncodingDetector_Improved.DetectFile(TestFiles[i]);
    
    if ChineseResult.Encoding <> ExpectedResults[i] then
    begin
      WriteLn(Format('中文编码检测失败: %s, 期望: %s, 实际: %s', [TestFiles[i], ExpectedResults[i], ChineseResult.Encoding]));
      Success := False;
    end;
  end;
  
  // 清理测试文件
  for i := 1 to 4 do
  begin
    if FileExists(TestFiles[i]) then
      DeleteFile(TestFiles[i]);
  end;
  
  Result := Success;
end;

class function TEncodingDetectionTest.TestEncodingConversion: Boolean;
const
  TEST_FILE_PREFIX = 'test_conversion_';
var
  SourceFiles, TargetFiles: array[1..5] of string;
  SourceEncodings, TargetEncodings: array[1..5] of string;
  i: Integer;
  ConversionResult: TEncodingConversionResult;
  Options: TEncodingConversionOptions;
  Success: Boolean;
begin
  // 创建测试文件
  SourceFiles[1] := TEST_FILE_PREFIX + 'utf8.txt';
  SourceFiles[2] := TEST_FILE_PREFIX + 'gbk.txt';
  SourceFiles[3] := TEST_FILE_PREFIX + 'big5.txt';
  SourceFiles[4] := TEST_FILE_PREFIX + 'utf16le.txt';
  SourceFiles[5] := TEST_FILE_PREFIX + 'ansi.txt';
  
  TargetFiles[1] := TEST_FILE_PREFIX + 'utf8_to_utf8bom.txt';
  TargetFiles[2] := TEST_FILE_PREFIX + 'gbk_to_utf8.txt';
  TargetFiles[3] := TEST_FILE_PREFIX + 'big5_to_utf8.txt';
  TargetFiles[4] := TEST_FILE_PREFIX + 'utf16le_to_utf8.txt';
  TargetFiles[5] := TEST_FILE_PREFIX + 'ansi_to_utf8.txt';
  
  SourceEncodings[1] := ENCODING_UTF8;
  SourceEncodings[2] := ENCODING_GBK;
  SourceEncodings[3] := ENCODING_BIG5;
  SourceEncodings[4] := ENCODING_UTF16_LE;
  SourceEncodings[5] := ENCODING_ANSI;
  
  TargetEncodings[1] := ENCODING_UTF8_BOM;
  TargetEncodings[2] := ENCODING_UTF8;
  TargetEncodings[3] := ENCODING_UTF8;
  TargetEncodings[4] := ENCODING_UTF8;
  TargetEncodings[5] := ENCODING_UTF8;
  
  // 创建测试文件
  CreateTestFile(SourceFiles[1], '这是UTF-8测试文件', 65001);
  CreateTestFile(SourceFiles[2], '这是GBK测试文件', 936);
  CreateTestFile(SourceFiles[3], '這是Big5測試文件', 950);
  CreateTestFile(SourceFiles[4], '这是UTF-16LE测试文件', 1200, True);
  CreateTestFile(SourceFiles[5], '这是ANSI测试文件', GetACP());
  
  // 创建转换选项
  Options := TEncodingConverter_Improved.CreateDefaultOptions;
  Options.AddBOM := True;
  
  // 测试编码转换
  Success := True;
  for i := 1 to 5 do
  begin
    ConversionResult := TEncodingConverter_Improved.ConvertFile(SourceFiles[i], TargetFiles[i], SourceEncodings[i], TargetEncodings[i], Options);
    
    if not ConversionResult.Success then
    begin
      WriteLn(Format('编码转换失败: %s -> %s, 错误: %d', [SourceFiles[i], TargetFiles[i], ConversionResult.ErrorCount]));
      Success := False;
    end;
    
    // 验证转换结果
    if not TEncodingConverter_Improved.ValidateConversion(SourceFiles[i], TargetFiles[i]) then
    begin
      WriteLn(Format('编码转换验证失败: %s -> %s', [SourceFiles[i], TargetFiles[i]]));
      Success := False;
    end;
  end;
  
  // 清理测试文件
  for i := 1 to 5 do
  begin
    if FileExists(SourceFiles[i]) then
      DeleteFile(SourceFiles[i]);
    if FileExists(TargetFiles[i]) then
      DeleteFile(TargetFiles[i]);
  end;
  
  Result := Success;
end;

class function TEncodingDetectionTest.TestFileEncodingDetection(const FileName: string): string;
var
  BOMResult: TBOMDetectionResult;
  UTF8Result: TUTF8DetectionResult;
  ChineseResult: TChineseEncodingResult;
begin
  // 检测BOM
  BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromFile(FileName);
  
  if BOMResult.BOMType <> bomNone then
    Result := BOMResult.Encoding
  else
  begin
    // 检测UTF-8
    UTF8Result := TUTF8EncodingDetector_Improved.DetectFile(FileName);
    
    if UTF8Result.IsUTF8 then
      Result := ENCODING_UTF8
    else
    begin
      // 检测中文编码
      ChineseResult := TChineseEncodingDetector_Improved.DetectFile(FileName);
      Result := ChineseResult.Encoding;
    end;
  end;
end;

class function TEncodingDetectionTest.TestUTF8BOMConversion: Boolean;
const
  TEST_FILE_PREFIX = 'test_utf8bom_';
var
  SourceFiles, TargetFiles: array[1..2] of string;
  i: Integer;
  ConversionResult: TUTF8BOMConversionResult;
  Success: Boolean;
begin
  // 创建测试文件
  SourceFiles[1] := TEST_FILE_PREFIX + 'utf8.txt';
  SourceFiles[2] := TEST_FILE_PREFIX + 'utf8bom.txt';
  
  TargetFiles[1] := TEST_FILE_PREFIX + 'utf8_to_utf8bom.txt';
  TargetFiles[2] := TEST_FILE_PREFIX + 'utf8bom_to_utf8.txt';
  
  // 创建测试文件
  CreateTestFile(SourceFiles[1], '这是UTF-8测试文件', 65001);
  CreateTestFile(SourceFiles[2], '这是UTF-8 BOM测试文件', 65001, True);
  
  // 测试UTF-8 BOM转换
  Success := True;
  
  // 测试添加BOM
  ConversionResult := TUTF8BOMConverter_Improved.AddBOMToUTF8File(SourceFiles[1], TargetFiles[1]);
  
  if not ConversionResult.Success then
  begin
    WriteLn(Format('添加UTF-8 BOM失败: %s -> %s, 错误: %s', [SourceFiles[1], TargetFiles[1], ConversionResult.ErrorMessage]));
    Success := False;
  end;
  
  // 验证BOM添加结果
  if not TUTF8BOMConverter_Improved.HasUTF8BOM(TargetFiles[1]) then
  begin
    WriteLn(Format('添加UTF-8 BOM验证失败: %s', [TargetFiles[1]]));
    Success := False;
  end;
  
  // 测试移除BOM
  ConversionResult := TUTF8BOMConverter_Improved.RemoveBOMFromUTF8File(SourceFiles[2], TargetFiles[2]);
  
  if not ConversionResult.Success then
  begin
    WriteLn(Format('移除UTF-8 BOM失败: %s -> %s, 错误: %s', [SourceFiles[2], TargetFiles[2], ConversionResult.ErrorMessage]));
    Success := False;
  end;
  
  // 验证BOM移除结果
  if TUTF8BOMConverter_Improved.HasUTF8BOM(TargetFiles[2]) then
  begin
    WriteLn(Format('移除UTF-8 BOM验证失败: %s', [TargetFiles[2]]));
    Success := False;
  end;
  
  // 清理测试文件
  for i := 1 to 2 do
  begin
    if FileExists(SourceFiles[i]) then
      DeleteFile(SourceFiles[i]);
    if FileExists(TargetFiles[i]) then
      DeleteFile(TargetFiles[i]);
  end;
  
  Result := Success;
end;

class function TEncodingDetectionTest.TestUTF8Detection: Boolean;
const
  TEST_FILE_PREFIX = 'test_utf8_';
var
  TestFiles: array[1..3] of string;
  ExpectedResults: array[1..3] of Boolean;
  i: Integer;
  UTF8Result: TUTF8DetectionResult;
  Success: Boolean;
begin
  // 创建测试文件
  TestFiles[1] := TEST_FILE_PREFIX + 'ascii.txt';
  TestFiles[2] := TEST_FILE_PREFIX + 'utf8.txt';
  TestFiles[3] := TEST_FILE_PREFIX + 'utf8bom.txt';
  
  ExpectedResults[1] := True;  // ASCII也是有效的UTF-8
  ExpectedResults[2] := True;
  ExpectedResults[3] := True;
  
  // 创建测试文件
  CreateTestFile(TestFiles[1], 'This is ASCII test file', 0);
  CreateTestFile(TestFiles[2], '这是UTF-8测试文件', 65001);
  CreateTestFile(TestFiles[3], '这是UTF-8 BOM测试文件', 65001, True);
  
  // 测试UTF-8检测
  Success := True;
  for i := 1 to 3 do
  begin
    UTF8Result := TUTF8EncodingDetector_Improved.DetectFile(TestFiles[i]);
    
    if UTF8Result.IsUTF8 <> ExpectedResults[i] then
    begin
      WriteLn(Format('UTF-8检测失败: %s, 期望: %s, 实际: %s', [TestFiles[i], BoolToStr(ExpectedResults[i], True), BoolToStr(UTF8Result.IsUTF8, True)]));
      Success := False;
    end;
  end;
  
  // 清理测试文件
  for i := 1 to 3 do
  begin
    if FileExists(TestFiles[i]) then
      DeleteFile(TestFiles[i]);
  end;
  
  Result := Success;
end;

end.
