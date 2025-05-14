program TestPerformanceApp;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.IOUtils,
  EncodingPerformanceTester in 'EncodingPerformanceTester.pas';

procedure LogMessage(const Msg: string);
begin
  Writeln(Msg);
end;

procedure GenerateTestFiles;
var
  TestDir: string;
  FileSizes: array[0..5] of Int64;
  FileSize: Int64;
  FileName: string;
  FileContent: TBytes;
  I, J: Integer;
begin
  // 创建测试目录
  TestDir := 'test\performance';
  if not DirectoryExists(TestDir) then
    ForceDirectories(TestDir);
  
  // 定义测试文件大小
  FileSizes[0] := 512;                // 极小文件 (512B)
  FileSizes[1] := 5 * 1024;           // 小文件 (5KB)
  FileSizes[2] := 50 * 1024;          // 中等文件 (50KB)
  FileSizes[3] := 500 * 1024;         // 大文件 (500KB)
  FileSizes[4] := 5 * 1024 * 1024;    // 超大文件 (5MB)
  FileSizes[5] := 20 * 1024 * 1024;   // 巨大文件 (20MB)
  
  // 生成测试文件
  Randomize;
  for I := 0 to High(FileSizes) do
  begin
    FileSize := FileSizes[I];
    FileName := Format('%s\test_%s.bin', [TestDir, TPath.GetFileSize(FileSize).Replace(' ', '')]);
    
    // 检查文件是否已存在
    if FileExists(FileName) then
    begin
      Writeln(Format('测试文件已存在: %s', [FileName]));
      Continue;
    end;
    
    Writeln(Format('生成测试文件: %s (%s)', [FileName, TPath.GetFileSize(FileSize)]));
    
    // 生成随机内容
    SetLength(FileContent, FileSize);
    for J := 0 to FileSize - 1 do
      FileContent[J] := Random(256);
    
    // 写入文件
    TFile.WriteAllBytes(FileName, FileContent);
    
    // 清理内存
    SetLength(FileContent, 0);
  end;
end;

procedure RunPerformanceTests;
var
  Tester: TEncodingPerformanceTester;
  TestDir: string;
  Files: TArray<string>;
  FilePath: string;
  EncodingPairs: array of record
    Source: string;
    Target: string;
  end;
  I: Integer;
begin
  // 创建性能测试器
  Tester := TEncodingPerformanceTester.Create(LogMessage);
  try
    // 获取测试文件
    TestDir := 'test\performance';
    Files := TDirectory.GetFiles(TestDir, '*.bin');
    
    if Length(Files) = 0 then
    begin
      Writeln('没有找到测试文件，请先生成测试文件');
      Exit;
    end;
    
    // 定义编码对
    SetLength(EncodingPairs, 4);
    EncodingPairs[0].Source := 'UTF-8';
    EncodingPairs[0].Target := 'UTF-8 with BOM';
    EncodingPairs[1].Source := 'UTF-8';
    EncodingPairs[1].Target := 'GBK';
    EncodingPairs[2].Source := 'GBK';
    EncodingPairs[2].Target := 'UTF-8';
    EncodingPairs[3].Source := 'UTF-8 with BOM';
    EncodingPairs[3].Target := 'UTF-8';
    
    // 测试文件读取性能
    Writeln('');
    Writeln('测试文件读取性能...');
    for FilePath in Files do
      Tester.TestFileReading(FilePath);
    
    // 测试文件写入性能
    Writeln('');
    Writeln('测试文件写入性能...');
    for I := 0 to High(Files) do
    begin
      var FileSize := TFile.GetSize(Files[I]);
      Tester.TestFileWriting(Files[I], FileSize);
    end;
    
    // 测试编码检测性能
    Writeln('');
    Writeln('测试编码检测性能...');
    for FilePath in Files do
      Tester.TestEncodingDetection(FilePath);
    
    // 测试编码转换性能
    Writeln('');
    Writeln('测试编码转换性能...');
    for FilePath in Files do
    begin
      for I := 0 to High(EncodingPairs) do
        Tester.TestEncodingConversion(FilePath, EncodingPairs[I].Source, EncodingPairs[I].Target);
    end;
    
    // 生成性能测试报告
    Writeln('');
    Writeln('生成性能测试报告...');
    Tester.SaveReportToFile('test\performance_report.md');
    
    Writeln('性能测试完成！');
  finally
    Tester.Free;
  end;
end;

begin
  try
    Writeln('编码性能测试程序');
    Writeln('========================================');
    
    // 生成测试文件
    Writeln('是否生成测试文件？(Y/N)');
    if UpperCase(ReadLn) = 'Y' then
      GenerateTestFiles;
    
    // 运行性能测试
    Writeln('是否运行性能测试？(Y/N)');
    if UpperCase(ReadLn) = 'Y' then
      RunPerformanceTests;
    
    Writeln('========================================');
    Writeln('按任意键退出...');
    Readln;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Readln;
    end;
  end;
end.
