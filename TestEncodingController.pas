unit TestEncodingController;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  DUnitX.TestFramework, ControllerEncoding;

type
  [TestFixture]
  TEncodingControllerTests = class
  private
    FEncodingController: TEncodingController;
    FTestFilesDir: string;
    FTempDir: string;
    FLogMessages: TStringList;
    
    procedure LogCallback(const Msg: string);
    procedure CreateTestFile(const FileName: string; const Content: string; Encoding: TEncoding);
    procedure CleanupTestFiles;
    
  public
    [Setup]
    procedure Setup;
    
    [TearDown]
    procedure TearDown;
    
    [Test]
    procedure TestDetectFileEncoding_UTF8WithBOM;
    
    [Test]
    procedure TestDetectFileEncoding_UTF8WithoutBOM;
    
    [Test]
    procedure TestDetectFileEncoding_ANSI;
    
    [Test]
    procedure TestConvertSingleFile_ANSIToUTF8WithBOM;
    
    [Test]
    procedure TestConvertSingleFile_UTF8WithoutBOMToUTF8WithBOM;
    
    [Test]
    procedure TestConvertSingleFile_UTF8WithBOMToANSI;
    
    [Test]
    procedure TestConvertMultipleFiles;
    
    [Test]
    procedure TestErrorHandling_NonExistentFile;
    
    [Test]
    procedure TestErrorHandling_InvalidEncoding;
  end;

implementation

{ TEncodingControllerTests }

procedure TEncodingControllerTests.Setup;
begin
  // 创建日志记录列表
  FLogMessages := TStringList.Create;
  
  // 创建编码控制器实例，传入日志回调
  FEncodingController := TEncodingController.Create(LogCallback);
  
  // 设置测试文件目录
  FTestFilesDir := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'TestFiles');
  FTempDir := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'TestTemp');
  
  // 确保测试目录存在
  if not DirectoryExists(FTestFilesDir) then
    ForceDirectories(FTestFilesDir);
    
  if not DirectoryExists(FTempDir) then
    ForceDirectories(FTempDir);
    
  // 清理可能存在的旧测试文件
  CleanupTestFiles;
end;

procedure TEncodingControllerTests.TearDown;
begin
  // 清理测试文件
  CleanupTestFiles;
  
  // 释放资源
  FEncodingController.Free;
  FLogMessages.Free;
end;

procedure TEncodingControllerTests.LogCallback(const Msg: string);
begin
  // 记录日志消息
  FLogMessages.Add(Msg);
end;

procedure TEncodingControllerTests.CreateTestFile(const FileName: string; 
  const Content: string; Encoding: TEncoding);
var
  FullPath: string;
begin
  FullPath := TPath.Combine(FTestFilesDir, FileName);
  TFile.WriteAllText(FullPath, Content, Encoding);
end;

procedure TEncodingControllerTests.CleanupTestFiles;
var
  Files: TStringDynArray;
  File_: string;
begin
  // 删除测试文件目录中的所有文件
  if DirectoryExists(FTestFilesDir) then
  begin
    Files := TDirectory.GetFiles(FTestFilesDir);
    for File_ in Files do
    begin
      DeleteFile(File_);
    end;
  end;
  
  // 删除临时目录中的所有文件
  if DirectoryExists(FTempDir) then
  begin
    Files := TDirectory.GetFiles(FTempDir);
    for File_ in Files do
    begin
      DeleteFile(File_);
    end;
  end;
end;

procedure TEncodingControllerTests.TestDetectFileEncoding_UTF8WithBOM;
var
  FileName: string;
  EncodingName: string;
  Result: Boolean;
begin
  // 准备
  FileName := 'utf8_with_bom.txt';
  CreateTestFile(FileName, '这是一个UTF-8带BOM的测试文件', TEncoding.UTF8); // Delphi的TEncoding.UTF8默认带BOM
  
  // 执行
  Result := FEncodingController.DetectFileEncoding(TPath.Combine(FTestFilesDir, FileName), EncodingName);
  
  // 验证
  Assert.IsTrue(Result, '应该成功检测文件编码');
  Assert.AreEqual('UTF-8 with BOM', EncodingName, '应该检测为UTF-8 with BOM');
end;

procedure TEncodingControllerTests.TestDetectFileEncoding_UTF8WithoutBOM;
var
  FileName: string;
  EncodingName: string;
  Result: Boolean;
  UTF8NoBOM: TEncoding;
begin
  // 准备
  FileName := 'utf8_without_bom.txt';
  UTF8NoBOM := TEncoding.GetEncoding(65001); // UTF-8 without BOM
  try
    CreateTestFile(FileName, '这是一个UTF-8不带BOM的测试文件', UTF8NoBOM);
    
    // 执行
    Result := FEncodingController.DetectFileEncoding(TPath.Combine(FTestFilesDir, FileName), EncodingName);
    
    // 验证
    Assert.IsTrue(Result, '应该成功检测文件编码');
    Assert.AreEqual('UTF-8', EncodingName, '应该检测为UTF-8（不带BOM）');
  finally
    UTF8NoBOM.Free;
  end;
end;

procedure TEncodingControllerTests.TestDetectFileEncoding_ANSI;
var
  FileName: string;
  EncodingName: string;
  Result: Boolean;
  ANSIEncoding: TEncoding;
begin
  // 准备
  FileName := 'ansi.txt';
  ANSIEncoding := TEncoding.GetEncoding(0); // Default ANSI codepage
  try
    CreateTestFile(FileName, 'This is an ANSI test file', ANSIEncoding);
    
    // 执行
    Result := FEncodingController.DetectFileEncoding(TPath.Combine(FTestFilesDir, FileName), EncodingName);
    
    // 验证
    Assert.IsTrue(Result, '应该成功检测文件编码');
    Assert.AreEqual('ANSI', EncodingName, '应该检测为ANSI');
  finally
    ANSIEncoding.Free;
  end;
end;

procedure TEncodingControllerTests.TestConvertSingleFile_ANSIToUTF8WithBOM;
var
  SourceFile, TargetFile: string;
  ANSIEncoding: TEncoding;
  Content: string;
  Success: Boolean;
  EncodingName: string;
begin
  // 准备
  SourceFile := TPath.Combine(FTestFilesDir, 'ansi_source.txt');
  TargetFile := TPath.Combine(FTempDir, 'utf8_target.txt');
  
  ANSIEncoding := TEncoding.GetEncoding(0); // Default ANSI codepage
  try
    // 创建ANSI测试文件
    TFile.WriteAllText(SourceFile, 'This is an ANSI test file for conversion', ANSIEncoding);
    
    // 执行转换
    Success := FEncodingController.ConvertSingleFileByName(SourceFile, 'UTF-8 with BOM', True, nil);
    
    // 验证
    Assert.IsTrue(Success, '转换应该成功');
    Assert.IsTrue(FileExists(SourceFile), '源文件应该仍然存在');
    
    // 检查转换后的文件编码
    Result := FEncodingController.DetectFileEncoding(SourceFile, EncodingName);
    Assert.IsTrue(Result, '应该能够检测转换后的文件编码');
    Assert.AreEqual('UTF-8 with BOM', EncodingName, '文件应该已转换为UTF-8 with BOM');
    
    // 检查内容是否正确
    Content := TFile.ReadAllText(SourceFile);
    Assert.AreEqual('This is an ANSI test file for conversion', Content, '文件内容应该保持不变');
  finally
    ANSIEncoding.Free;
  end;
end;

procedure TEncodingControllerTests.TestConvertSingleFile_UTF8WithoutBOMToUTF8WithBOM;
var
  SourceFile: string;
  UTF8NoBOM: TEncoding;
  Success: Boolean;
  EncodingName: string;
begin
  // 准备
  SourceFile := TPath.Combine(FTestFilesDir, 'utf8_nobom_source.txt');
  
  UTF8NoBOM := TEncoding.GetEncoding(65001); // UTF-8 without BOM
  try
    // 创建UTF-8不带BOM的测试文件
    TFile.WriteAllText(SourceFile, '这是一个UTF-8不带BOM的测试文件', UTF8NoBOM);
    
    // 执行转换
    Success := FEncodingController.ConvertSingleFileByName(SourceFile, 'UTF-8 with BOM', True, nil);
    
    // 验证
    Assert.IsTrue(Success, '转换应该成功');
    
    // 检查转换后的文件编码
    Result := FEncodingController.DetectFileEncoding(SourceFile, EncodingName);
    Assert.IsTrue(Result, '应该能够检测转换后的文件编码');
    Assert.AreEqual('UTF-8 with BOM', EncodingName, '文件应该已转换为UTF-8 with BOM');
  finally
    UTF8NoBOM.Free;
  end;
end;

procedure TEncodingControllerTests.TestConvertSingleFile_UTF8WithBOMToANSI;
var
  SourceFile: string;
  Success: Boolean;
  EncodingName: string;
begin
  // 准备
  SourceFile := TPath.Combine(FTestFilesDir, 'utf8_bom_source.txt');
  
  // 创建UTF-8带BOM的测试文件
  TFile.WriteAllText(SourceFile, 'This is a UTF-8 with BOM test file', TEncoding.UTF8);
  
  // 执行转换
  Success := FEncodingController.ConvertSingleFileByName(SourceFile, 'ANSI', False, nil);
  
  // 验证
  Assert.IsTrue(Success, '转换应该成功');
  
  // 检查转换后的文件编码
  Result := FEncodingController.DetectFileEncoding(SourceFile, EncodingName);
  Assert.IsTrue(Result, '应该能够检测转换后的文件编码');
  Assert.AreEqual('ANSI', EncodingName, '文件应该已转换为ANSI');
end;

procedure TEncodingControllerTests.TestConvertMultipleFiles;
var
  Files: TArray<string>;
  CallbackCount: Integer;
  I: Integer;
  EncodingName: string;
begin
  // 准备
  SetLength(Files, 3);
  Files[0] := TPath.Combine(FTestFilesDir, 'multi_test1.txt');
  Files[1] := TPath.Combine(FTestFilesDir, 'multi_test2.txt');
  Files[2] := TPath.Combine(FTestFilesDir, 'multi_test3.txt');
  
  // 创建测试文件
  TFile.WriteAllText(Files[0], 'Test file 1', TEncoding.ASCII);
  TFile.WriteAllText(Files[1], 'Test file 2', TEncoding.ASCII);
  TFile.WriteAllText(Files[2], 'Test file 3', TEncoding.ASCII);
  
  // 重置日志
  FLogMessages.Clear;
  CallbackCount := 0;
  
  // 执行批量转换
  FEncodingController.ConvertFilesByName(Files, 'UTF-8 with BOM', True, 
    procedure(const FileName: string)
    begin
      Inc(CallbackCount);
    end);
  
  // 验证
  Assert.AreEqual(3, CallbackCount, '应该为3个文件都调用了回调');
  
  // 检查所有文件是否都已转换
  for I := 0 to High(Files) do
  begin
    Assert.IsTrue(FileExists(Files[I]), Format('文件 %s 应该存在', [Files[I]]));
    Result := FEncodingController.DetectFileEncoding(Files[I], EncodingName);
    Assert.IsTrue(Result, Format('应该能够检测文件 %s 的编码', [Files[I]]));
    Assert.AreEqual('UTF-8 with BOM', EncodingName, Format('文件 %s 应该已转换为UTF-8 with BOM', [Files[I]]));
  end;
end;

procedure TEncodingControllerTests.TestErrorHandling_NonExistentFile;
var
  NonExistentFile: string;
  Success: Boolean;
  EncodingName: string;
begin
  // 准备
  NonExistentFile := TPath.Combine(FTestFilesDir, 'non_existent.txt');
  
  // 确保文件不存在
  if FileExists(NonExistentFile) then
    DeleteFile(NonExistentFile);
  
  // 重置日志
  FLogMessages.Clear;
  
  // 执行
  Success := FEncodingController.ConvertSingleFileByName(NonExistentFile, 'UTF-8 with BOM', True, nil);
  Result := FEncodingController.DetectFileEncoding(NonExistentFile, EncodingName);
  
  // 验证
  Assert.IsFalse(Success, '对不存在的文件的转换应该失败');
  Assert.IsFalse(Result, '对不存在的文件的编码检测应该失败');
  Assert.IsTrue(FLogMessages.Count > 0, '应该记录错误日志');
  Assert.IsTrue(FLogMessages.Text.Contains('不存在'), '日志应该包含"不存在"信息');
end;

procedure TEncodingControllerTests.TestErrorHandling_InvalidEncoding;
var
  SourceFile: string;
  Success: Boolean;
begin
  // 准备
  SourceFile := TPath.Combine(FTestFilesDir, 'test_invalid_encoding.txt');
  TFile.WriteAllText(SourceFile, 'Test file', TEncoding.ASCII);
  
  // 重置日志
  FLogMessages.Clear;
  
  // 执行 - 使用无效的编码名称
  Success := FEncodingController.ConvertSingleFileByName(SourceFile, 'INVALID_ENCODING', True, nil);
  
  // 验证
  Assert.IsFalse(Success, '使用无效编码名称的转换应该失败');
  Assert.IsTrue(FLogMessages.Count > 0, '应该记录错误日志');
end;

initialization
  TDUnitX.RegisterTestFixture(TEncodingControllerTests);
end.
