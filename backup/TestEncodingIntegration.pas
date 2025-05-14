unit TestEncodingIntegration;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, UtilsEncodingTypes,
  UtilsEncodingBOM_Improved, UtilsEncodingUTF8Detector_Improved,
  ChineseEncodingDetector_Improved, UTF8BOMConverter_Improved,
  EncodingConverter_Improved;

type
  /// <summary>
  /// 编码集成测试类
  /// </summary>
  TEncodingIntegrationTest = class
  private
    /// <summary>
    /// 创建测试目录
    /// </summary>
    class function CreateTestDirectory(const DirName: string): Boolean;
    
    /// <summary>
    /// 创建测试文件
    /// </summary>
    class function CreateTestFile(const FileName: string; const Content: string; CodePage: Integer; AddBOM: Boolean = False): Boolean;
    
    /// <summary>
    /// 测试批量转换
    /// </summary>
    class function TestBatchConversion: Boolean;
    
    /// <summary>
    /// 测试编码检测和转换集成
    /// </summary>
    class function TestDetectionAndConversion: Boolean;
    
    /// <summary>
    /// 测试错误处理
    /// </summary>
    class function TestErrorHandling: Boolean;
    
  public
    /// <summary>
    /// 运行集成测试
    /// </summary>
    class function RunIntegrationTests: Boolean;
  end;

implementation

{ TEncodingIntegrationTest }

class function TEncodingIntegrationTest.CreateTestDirectory(const DirName: string): Boolean;
begin
  Result := False;
  
  try
    // 如果目录已存在，先删除
    if DirectoryExists(DirName) then
    begin
      var SearchRec: TSearchRec;
      var FindResult := FindFirst(DirName + '\*.*', faAnyFile, SearchRec);
      
      try
        while FindResult = 0 do
        begin
          if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
            DeleteFile(DirName + '\' + SearchRec.Name);
            
          FindResult := FindNext(SearchRec);
        end;
      finally
        FindClose(SearchRec);
      end;
      
      RemoveDir(DirName);
    end;
    
    // 创建目录
    Result := ForceDirectories(DirName);
  except
    Result := False;
  end;
end;

class function TEncodingIntegrationTest.CreateTestFile(const FileName: string; const Content: string; CodePage: Integer; AddBOM: Boolean): Boolean;
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

class function TEncodingIntegrationTest.RunIntegrationTests: Boolean;
var
  TestResults: array[1..3] of Boolean;
  TestNames: array[1..3] of string;
  i: Integer;
  SuccessCount: Integer;
begin
  // 设置测试名称
  TestNames[1] := '编码检测和转换集成测试';
  TestNames[2] := '批量转换测试';
  TestNames[3] := '错误处理测试';
  
  // 运行测试
  TestResults[1] := TestDetectionAndConversion;
  TestResults[2] := TestBatchConversion;
  TestResults[3] := TestErrorHandling;
  
  // 输出测试结果
  WriteLn('编码集成测试结果:');
  WriteLn('----------------------------------------');
  
  SuccessCount := 0;
  for i := 1 to 3 do
  begin
    if TestResults[i] then
      Inc(SuccessCount);
      
    WriteLn(Format('%s: %s', [TestNames[i], BoolToStr(TestResults[i], '通过', '失败')]));
  end;
  
  WriteLn('----------------------------------------');
  WriteLn(Format('总结: %d/%d 测试通过', [SuccessCount, 3]));
  
  Result := (SuccessCount = 3);
end;

class function TEncodingIntegrationTest.TestBatchConversion: Boolean;
const
  TEST_DIR = 'test_batch';
  TARGET_DIR = 'test_batch_output';
var
  TestFiles: array[1..5] of string;
  FileNames: TArray<string>;
  Options: TEncodingConversionOptions;
  Results: TArray<TEncodingConversionResult>;
  i: Integer;
  Success: Boolean;
begin
  // 创建测试目录
  CreateTestDirectory(TEST_DIR);
  CreateTestDirectory(TARGET_DIR);
  
  // 创建测试文件
  TestFiles[1] := TEST_DIR + '\utf8.txt';
  TestFiles[2] := TEST_DIR + '\gbk.txt';
  TestFiles[3] := TEST_DIR + '\big5.txt';
  TestFiles[4] := TEST_DIR + '\utf16le.txt';
  TestFiles[5] := TEST_DIR + '\ansi.txt';
  
  CreateTestFile(TestFiles[1], '这是UTF-8测试文件', 65001);
  CreateTestFile(TestFiles[2], '这是GBK测试文件', 936);
  CreateTestFile(TestFiles[3], '這是Big5測試文件', 950);
  CreateTestFile(TestFiles[4], '这是UTF-16LE测试文件', 1200, True);
  CreateTestFile(TestFiles[5], '这是ANSI测试文件', GetACP());
  
  // 准备文件名数组
  SetLength(FileNames, 5);
  for i := 1 to 5 do
    FileNames[i-1] := TestFiles[i];
    
  // 创建转换选项
  Options := TEncodingConverter_Improved.CreateDefaultOptions;
  Options.AddBOM := True;
  
  // 执行批量转换
  Results := TEncodingConverter_Improved.BatchConvertFiles(FileNames, TARGET_DIR, ENCODING_UTF8_BOM, Options);
  
  // 验证结果
  Success := True;
  for i := 0 to High(Results) do
  begin
    if not Results[i].Success then
    begin
      WriteLn(Format('批量转换失败: %s, 错误: %d', [FileNames[i], Results[i].ErrorCount]));
      Success := False;
    end;
    
    // 验证转换结果
    var TargetFileName := TARGET_DIR + '\' + ExtractFileName(FileNames[i]);
    if not TEncodingConverter_Improved.ValidateConversion(FileNames[i], TargetFileName) then
    begin
      WriteLn(Format('批量转换验证失败: %s -> %s', [FileNames[i], TargetFileName]));
      Success := False;
    end;
  end;
  
  Result := Success;
end;

class function TEncodingIntegrationTest.TestDetectionAndConversion: Boolean;
const
  TEST_FILE_PREFIX = 'test_integration_';
var
  SourceFile, TargetFile: string;
  DetectedEncoding: string;
  ConversionResult: TEncodingConversionResult;
  Options: TEncodingConversionOptions;
  Success: Boolean;
begin
  // 创建测试文件
  SourceFile := TEST_FILE_PREFIX + 'source.txt';
  TargetFile := TEST_FILE_PREFIX + 'target.txt';
  
  CreateTestFile(SourceFile, '这是集成测试文件', 936); // GBK编码
  
  // 检测源文件编码
  DetectedEncoding := TEncodingConverter_Improved.DetectFileEncoding(SourceFile);
  
  // 创建转换选项
  Options := TEncodingConverter_Improved.CreateDefaultOptions;
  Options.AddBOM := True;
  
  // 执行转换
  ConversionResult := TEncodingConverter_Improved.ConvertFile(SourceFile, TargetFile, DetectedEncoding, ENCODING_UTF8_BOM, Options);
  
  // 验证结果
  Success := ConversionResult.Success;
  
  if not Success then
    WriteLn(Format('集成测试转换失败: %s -> %s, 错误: %d', [SourceFile, TargetFile, ConversionResult.ErrorCount]));
    
  // 验证转换结果
  if not TEncodingConverter_Improved.ValidateConversion(SourceFile, TargetFile) then
  begin
    WriteLn(Format('集成测试验证失败: %s -> %s', [SourceFile, TargetFile]));
    Success := False;
  end;
  
  // 清理测试文件
  if FileExists(SourceFile) then
    DeleteFile(SourceFile);
  if FileExists(TargetFile) then
    DeleteFile(TargetFile);
    
  Result := Success;
end;

class function TEncodingIntegrationTest.TestErrorHandling: Boolean;
const
  TEST_FILE_PREFIX = 'test_error_';
var
  SourceFile, TargetFile: string;
  Options: TEncodingConversionOptions;
  ConversionResult: TEncodingConversionResult;
  Success: Boolean;
begin
  // 创建测试文件
  SourceFile := TEST_FILE_PREFIX + 'source.txt';
  TargetFile := TEST_FILE_PREFIX + 'target.txt';
  
  // 创建一个包含无效UTF-8序列的文件
  var FileStream := TFileStream.Create(SourceFile, fmCreate);
  try
    var InvalidUTF8: array[0..3] of Byte = ($E0, $80, $80, $80); // 无效的UTF-8序列
    FileStream.WriteBuffer(InvalidUTF8, 4);
  finally
    FileStream.Free;
  end;
  
  // 创建转换选项
  Options := TEncodingConverter_Improved.CreateDefaultOptions;
  Options.ErrorHandling := eehsReplace;
  Options.ReplacementChar := '?';
  
  // 执行转换
  ConversionResult := TEncodingConverter_Improved.ConvertFile(SourceFile, TargetFile, ENCODING_UTF8, ENCODING_UTF8_BOM, Options);
  
  // 验证结果
  Success := ConversionResult.Success;
  
  if not Success then
    WriteLn(Format('错误处理测试失败: %s -> %s, 错误: %d', [SourceFile, TargetFile, ConversionResult.ErrorCount]));
    
  // 清理测试文件
  if FileExists(SourceFile) then
    DeleteFile(SourceFile);
  if FileExists(TargetFile) then
    DeleteFile(TargetFile);
    
  Result := Success;
end;

end.
