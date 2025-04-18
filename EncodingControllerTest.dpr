program EncodingControllerTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  UtilsEncodingDetect2 in 'UtilsEncodingDetect2.pas',
  ControllerEncodingEnhanced in 'ControllerEncodingEnhanced.pas';

const
  TestDirName = 'EncodingTests';
  
type
  TTestResult = record
    TestName: string;
    Passed: Boolean;
    Message: string;
  end;

var
  TestResults: array of TTestResult;
  TotalTests, PassedTests: Integer;

procedure AddTestResult(const TestName: string; Passed: Boolean; const Message: string);
var
  NewResult: TTestResult;
begin
  NewResult.TestName := TestName;
  NewResult.Passed := Passed;
  NewResult.Message := Message;
  
  SetLength(TestResults, Length(TestResults) + 1);
  TestResults[Length(TestResults) - 1] := NewResult;
  
  Inc(TotalTests);
  if Passed then
    Inc(PassedTests);
end;

procedure PrintTestReport;
var
  i: Integer;
begin
  Writeln;
  Writeln('======= 测试报告 =======');
  Writeln;
  
  for i := 0 to High(TestResults) do
  begin
    if TestResults[i].Passed then
      Write('[通过] ')
    else
      Write('[失败] ');
      
    Writeln(TestResults[i].TestName);
    Writeln('     ', TestResults[i].Message);
    Writeln;
  end;
  
  Writeln(Format('测试结果: %d/%d 通过 (%.1f%%)', 
    [PassedTests, TotalTests, (PassedTests / TotalTests) * 100]));
    
  Writeln('=======================');
end;

function CreateTestDirectory: string;
var
  TestDir: string;
begin
  TestDir := IncludeTrailingPathDelimiter(GetCurrentDir) + TestDirName;
  
  if DirectoryExists(TestDir) then
    TDirectory.Delete(TestDir, True);
    
  ForceDirectories(TestDir);
  Result := TestDir;
end;

procedure CreateTestFiles(const TestDir: string);
var
  TestFile1, TestFile2, TestFile3, TestFile4: string;
  Utf8Bom, Utf8NoBom, Ansi, Utf16LE: TEncoding;
  Stream: TFileStream;
  Content: string;
  Buffer: TBytes;
begin
  TestFile1 := TestDir + '\test_utf8bom.txt';
  TestFile2 := TestDir + '\test_utf8nobom.txt';
  TestFile3 := TestDir + '\test_ansi.txt';
  TestFile4 := TestDir + '\test_utf16le.txt';
  
  // 准备编码
  Utf8Bom := TEncoding.UTF8;
  Utf8NoBom := TEncoding.GetEncoding(65001, EncodingStreamNoBOM);
  Ansi := TEncoding.ANSI;
  Utf16LE := TEncoding.Unicode;
  
  // 测试内容 - 包含中英文混合
  Content := '这是一个测试文件，包含中文和English混合内容。' + sLineBreak + 
             '第二行也有一些特殊字符: !@#$%^&*()_+{}:"<>?';

  // 使用UTF-8 BOM创建文件
  Buffer := Utf8Bom.GetPreamble + Utf8Bom.GetBytes(Content);
  TFile.WriteAllBytes(TestFile1, Buffer);
  
  // 使用UTF-8 无BOM创建文件
  Buffer := Utf8NoBom.GetBytes(Content);
  TFile.WriteAllBytes(TestFile2, Buffer);
  
  // 使用ANSI创建文件
  Buffer := Ansi.GetBytes(Content);
  TFile.WriteAllBytes(TestFile3, Buffer);
  
  // 使用UTF-16LE创建文件
  Buffer := Utf16LE.GetPreamble + Utf16LE.GetBytes(Content);
  TFile.WriteAllBytes(TestFile4, Buffer);
  
  Writeln('创建测试文件:');
  Writeln('  * ', TestFile1, ' (UTF-8 带BOM)');
  Writeln('  * ', TestFile2, ' (UTF-8 无BOM)');
  Writeln('  * ', TestFile3, ' (ANSI)');
  Writeln('  * ', TestFile4, ' (UTF-16LE)');
  Writeln;
end;

procedure TestEncodingDetection(const TestDir: string);
var
  Controller: TEncodingControllerEnhanced;
  Files: TArray<string>;
  Results: TArray<TFileEncodingInfo>;
  i: Integer;
  AllCorrect: Boolean;
begin
  Writeln('测试1: 编码检测功能');
  Writeln('-----------------');
  
  Controller := TEncodingControllerEnhanced.Create;
  try
    Files := TDirectory.GetFiles(TestDir);
    Results := Controller.DetectFilesEncoding(Files);
    
    Writeln('检测结果:');
    AllCorrect := True;
    
    for i := 0 to High(Results) do
    begin
      Writeln(Format('  * %s -> %s (置信度: %.1f%%, BOM: %s)', 
        [ExtractFileName(Results[i].FileName),
         Results[i].DetectionResult.EncodingName,
         Results[i].DetectionResult.Confidence * 100,
         BoolToStr(Results[i].DetectionResult.HasBOM, True)]));
         
      // 验证结果
      if ExtractFileName(Results[i].FileName) = 'test_utf8bom.txt' then
      begin
        if (Results[i].DetectionResult.EncodingName <> 'UTF-8') or 
           (not Results[i].DetectionResult.HasBOM) then
          AllCorrect := False;
      end
      else if ExtractFileName(Results[i].FileName) = 'test_utf8nobom.txt' then
      begin
        if (Results[i].DetectionResult.EncodingName <> 'UTF-8') or 
           (Results[i].DetectionResult.HasBOM) then
          AllCorrect := False;
      end
      else if ExtractFileName(Results[i].FileName) = 'test_utf16le.txt' then
      begin
        if (Results[i].DetectionResult.EncodingName <> 'UTF-16') or 
           (not Results[i].DetectionResult.HasBOM) then
          AllCorrect := False;
      end;
    end;
    
    if AllCorrect then
      AddTestResult('编码检测', True, '所有文件的编码都被正确检测')
    else
      AddTestResult('编码检测', False, '有些文件的编码检测结果不正确');
    
  finally
    Controller.Free;
  end;
  
  Writeln;
end;

procedure TestSingleFileConversion(const TestDir: string);
var
  Controller: TEncodingControllerEnhanced;
  SourceFile, TargetFile: string;
  Result: TEncodingConversionResult;
  DetectResult1, DetectResult2: TEncodingDetectResult;
  Success: Boolean;
begin
  Writeln('测试2: 单文件编码转换');
  Writeln('-------------------');
  
  Controller := TEncodingControllerEnhanced.Create;
  try
    SourceFile := TestDir + '\test_ansi.txt';
    TargetFile := TestDir + '\test_ansi_converted.txt';
    
    // 检测源文件编码
    DetectResult1 := Controller.DetectFileEncoding(SourceFile);
    
    Writeln('源文件: ', ExtractFileName(SourceFile));
    Writeln('  编码: ', DetectResult1.EncodingName);
    Writeln('  有BOM: ', BoolToStr(DetectResult1.HasBOM, True));
    
    // 转换为UTF-8
    Writeln('正在转换为UTF-8 (带BOM)...');
    Result := Controller.ConvertSingleFile(SourceFile, TEncoding.UTF8, TargetFile, True);
    
    // 检测转换后的文件
    if FileExists(TargetFile) then
    begin
      DetectResult2 := Controller.DetectFileEncoding(TargetFile);
      Writeln('转换结果: ', Controller.GetResultDescription(Result));
      Writeln('转换后文件:');
      Writeln('  编码: ', DetectResult2.EncodingName);
      Writeln('  有BOM: ', BoolToStr(DetectResult2.HasBOM, True));
      
      Success := (Result = ecrSuccess) and 
                (DetectResult2.EncodingName = 'UTF-8') and 
                DetectResult2.HasBOM;
                
      if Success then
        AddTestResult('单文件转换', True, '文件成功从ANSI转换为UTF-8 (带BOM)')
      else
        AddTestResult('单文件转换', False, 
          Format('文件转换失败或结果不符合预期: %s, 编码: %s, BOM: %s',
            [Controller.GetResultDescription(Result),
             DetectResult2.EncodingName,
             BoolToStr(DetectResult2.HasBOM, True)]));
    end
    else
    begin
      Writeln('转换失败: 目标文件不存在');
      AddTestResult('单文件转换', False, '转换失败: 目标文件不存在');
    end;
    
  finally
    Controller.Free;
  end;
  
  Writeln;
end;

procedure TestBatchConversion(const TestDir: string);
var
  Controller: TEncodingControllerEnhanced;
  Files: TArray<string>;
  TargetDir: string;
  ConvertedCount, i: Integer;
  Results: TArray<TFileEncodingInfo>;
  AllUTF8WithBOM: Boolean;
begin
  Writeln('测试3: 批量文件转换');
  Writeln('------------------');
  
  TargetDir := TestDir + '\BatchConverted';
  ForceDirectories(TargetDir);
  
  // 复制测试文件到目标目录
  Files := TDirectory.GetFiles(TestDir, '*.txt');
  for i := 0 to High(Files) do
  begin
    TFile.Copy(Files[i], TargetDir + '\' + ExtractFileName(Files[i]), True);
  end;
  
  Controller := TEncodingControllerEnhanced.Create;
  try
    // 设置转换选项
    Controller.ConversionOptions := [ecoAddBOM, ecoForceConversion];
    
    // 批量转换文件
    Files := TDirectory.GetFiles(TargetDir);
    Writeln(Format('转换 %d 个文件到 UTF-8 (带BOM)...', [Length(Files)]));
    
    ConvertedCount := Controller.ConvertFilesByName(Files, 'UTF-8', True);
    
    Writeln(Format('成功转换: %d/%d 个文件', [ConvertedCount, Length(Files)]));
    
    // 验证所有文件现在是否都是UTF-8 BOM
    Results := Controller.DetectFilesEncoding(Files);
    AllUTF8WithBOM := True;
    
    for i := 0 to High(Results) do
    begin
      Writeln(Format('  * %s -> %s (BOM: %s)', 
        [ExtractFileName(Results[i].FileName),
         Results[i].DetectionResult.EncodingName,
         BoolToStr(Results[i].DetectionResult.HasBOM, True)]));
         
      if (Results[i].DetectionResult.EncodingName <> 'UTF-8') or 
         (not Results[i].DetectionResult.HasBOM) then
        AllUTF8WithBOM := False;
    end;
    
    if (ConvertedCount = Length(Files)) and AllUTF8WithBOM then
      AddTestResult('批量文件转换', True, 
        Format('所有%d个文件都成功转换为UTF-8 (带BOM)', [Length(Files)]))
    else
      AddTestResult('批量文件转换', False, 
        Format('只有%d/%d个文件成功转换，或者不是所有文件都变成了UTF-8带BOM', 
        [ConvertedCount, Length(Files)]));
    
  finally
    Controller.Free;
  end;
  
  Writeln;
end;

procedure TestDirectoryProcessing(const TestDir: string);
var
  Controller: TEncodingControllerEnhanced;
  TargetDir, SubDir1, SubDir2: string;
  TestFile1, TestFile2, TestFile3: string;
  ProcessedCount: Integer;
  Files: TArray<string>;
  AllDirectories: TArray<string>;
  TotalExpectedFiles: Integer;
  AllUTF8: Boolean;
  Results: TArray<TFileEncodingInfo>;
  i: Integer;
begin
  Writeln('测试4: 目录递归处理');
  Writeln('------------------');
  
  // 创建嵌套目录结构
  TargetDir := TestDir + '\RecursiveTest';
  SubDir1 := TargetDir + '\SubDir1';
  SubDir2 := TargetDir + '\SubDir2';
  ForceDirectories(TargetDir);
  ForceDirectories(SubDir1);
  ForceDirectories(SubDir2);
  
  // 在每个目录中创建测试文件
  TestFile1 := TargetDir + '\root.txt';
  TestFile2 := SubDir1 + '\sub1.txt';
  TestFile3 := SubDir2 + '\sub2.txt';
  
  // 使用ANSI编码创建测试文件
  TFile.WriteAllText(TestFile1, '根目录测试文件', TEncoding.ANSI);
  TFile.WriteAllText(TestFile2, '子目录1测试文件', TEncoding.ANSI);
  TFile.WriteAllText(TestFile3, '子目录2测试文件', TEncoding.ANSI);
  
  Writeln('创建递归测试目录结构:');
  Writeln('  ', TargetDir);
  Writeln('  └── ', ExtractFileName(TestFile1));
  Writeln('  └── ', ExtractFileName(SubDir1));
  Writeln('      └── ', ExtractFileName(TestFile2));
  Writeln('  └── ', ExtractFileName(SubDir2));
  Writeln('      └── ', ExtractFileName(TestFile3));
  
  Controller := TEncodingControllerEnhanced.Create;
  try
    // 设置转换选项 - 启用递归处理
    Controller.ConversionOptions := [ecoAddBOM, ecoRecursive];
    
    // 处理目录
    Writeln('递归处理目录中的文件...');
    ProcessedCount := Controller.ProcessDirectory(TargetDir, '*.txt', TEncoding.UTF8, True);
    
    // 计算预期的文件数
    AllDirectories := TDirectory.GetDirectories(TargetDir, '*', TSearchOption.soAllDirectories);
    TotalExpectedFiles := 1; // 根目录的文件
    for i := 0 to High(AllDirectories) do
    begin
      Files := TDirectory.GetFiles(AllDirectories[i], '*.txt');
      Inc(TotalExpectedFiles, Length(Files));
    end;
    
    Writeln(Format('处理文件数: %d', [ProcessedCount]));
    
    // 验证所有文件是否都已转换为UTF-8
    Files := TDirectory.GetFiles(TargetDir, '*.txt', TSearchOption.soAllDirectories);
    Results := Controller.DetectFilesEncoding(Files);
    AllUTF8 := True;
    
    Writeln('检查转换结果:');
    for i := 0 to High(Results) do
    begin
      Writeln(Format('  * %s -> %s (BOM: %s)', 
        [ExtractFileName(Results[i].FileName),
         Results[i].DetectionResult.EncodingName,
         BoolToStr(Results[i].DetectionResult.HasBOM, True)]));
         
      if (Results[i].DetectionResult.EncodingName <> 'UTF-8') or
         (not Results[i].DetectionResult.HasBOM) then
        AllUTF8 := False;
    end;
    
    if (ProcessedCount = TotalExpectedFiles) and AllUTF8 and (Length(Files) = TotalExpectedFiles) then
      AddTestResult('目录递归处理', True, 
        Format('成功递归处理目录中的%d个文件', [TotalExpectedFiles]))
    else
      AddTestResult('目录递归处理', False, 
        Format('预期处理%d个文件，实际处理%d个文件，找到%d个文件',
        [TotalExpectedFiles, ProcessedCount, Length(Files)]));
    
  finally
    Controller.Free;
  end;
  
  Writeln;
end;

procedure TestBinaryFileDetection(const TestDir: string);
var
  Controller: TEncodingControllerEnhanced;
  TestBinaryFile: string;
  ExeFile: string;
  Result: TEncodingConversionResult;
  BinaryTest: Boolean;
  Stream: TFileStream;
  Buffer: TBytes;
  i: Integer;
begin
  Writeln('测试5: 二进制文件检测');
  Writeln('------------------');
  
  TestBinaryFile := TestDir + '\test_binary.bin';
  
  // 创建一个简单的二进制文件
  Stream := TFileStream.Create(TestBinaryFile, fmCreate);
  try
    // 填充一些二进制数据
    SetLength(Buffer, 1024);
    for i := 0 to High(Buffer) do
      Buffer[i] := Byte(i mod 256);
      
    Stream.WriteBuffer(Buffer[0], Length(Buffer));
  finally
    Stream.Free;
  end;
  
  Writeln('创建二进制测试文件: ', TestBinaryFile);
  
  Controller := TEncodingControllerEnhanced.Create;
  try
    // 设置跳过二进制文件选项
    Controller.ConversionOptions := [ecoAddBOM, ecoSkipBinaryFiles];
    
    // 尝试转换二进制文件
    Writeln('尝试转换二进制文件...');
    Result := Controller.ConvertSingleFile(TestBinaryFile, TEncoding.UTF8, TestBinaryFile + '.conv', True);
    
    Writeln('转换结果: ', Controller.GetResultDescription(Result));
    
    // 检查是否正确跳过了二进制文件
    BinaryTest := (Result = ecrSkipped);
    
    if BinaryTest then
      AddTestResult('二进制文件检测', True, '成功识别并跳过二进制文件')
    else
      AddTestResult('二进制文件检测', False, 
        '未能正确识别和跳过二进制文件，结果: ' + Controller.GetResultDescription(Result));
    
  finally
    Controller.Free;
  end;
  
  Writeln;
end;

begin
  try
    TotalTests := 0;
    PassedTests := 0;
    
    // 设置控制台编码为UTF-8以正确显示中文
    SetConsoleOutputCP(65001);
    
    Writeln('=================================');
    Writeln('  增强版编码控制器测试程序');
    Writeln('=================================');
    Writeln;
    
    // 创建测试目录和文件
    var TestDir := CreateTestDirectory;
    CreateTestFiles(TestDir);
    
    // 运行测试用例
    TestEncodingDetection(TestDir);
    TestSingleFileConversion(TestDir);
    TestBatchConversion(TestDir);
    TestDirectoryProcessing(TestDir);
    TestBinaryFileDetection(TestDir);
    
    // 打印测试报告
    PrintTestReport;
    
    // 等待用户按键
    Writeln('按任意键退出...');
    Readln;
    
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end. 