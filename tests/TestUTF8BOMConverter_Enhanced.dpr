program TestUTF8BOMConverter_Enhanced;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.IOUtils,
  UTF8BOMConverter_Enhanced in 'UTF8BOMConverter_Enhanced.pas';

const
  TEST_FOLDER = 'UTF8TestFiles';
  
procedure LogTestResult(const TestName, FileName: string; Result: Boolean);
begin
  if Result then
    Writeln(TestName, ' 成功: ', FileName)
  else
    Writeln(TestName, ' 失败: ', FileName);
end;

procedure PrepareTestFolder;
begin
  // 确保测试文件夹存在
  if not DirectoryExists(TEST_FOLDER) then
    CreateDir(TEST_FOLDER);
    
  // 创建测试文件
  TFile.WriteAllText(TPath.Combine(TEST_FOLDER, 'ascii.txt'), 'This is ASCII text');
  
  // 创建UTF-8无BOM测试文件
  var utf8NoBom := 'UTF8文本无BOM测试 - 中文内容';
  TFile.WriteAllText(TPath.Combine(TEST_FOLDER, 'utf8-no-bom.txt'), utf8NoBom, TEncoding.UTF8);
  
  // 创建UTF-8带BOM测试文件时使用带BOM的UTF8编码
  var utf8WithBom := '带BOM的UTF-8文本测试 - 包含中文字符';
  var utf8Encoding := TUTF8Encoding.Create(true); // true表示使用BOM
  try
    TFile.WriteAllText(TPath.Combine(TEST_FOLDER, 'utf8-with-bom.txt'), utf8WithBom, utf8Encoding);
  finally
    utf8Encoding.Free;
  end;
  
  // 创建一个ANSI文本文件
  var ansiText := '这是ANSI编码的文本';
  TFile.WriteAllText(TPath.Combine(TEST_FOLDER, 'ansi.txt'), ansiText, TEncoding.Default);
  
  Writeln('测试文件已准备完毕');
end;

procedure TestHasUTF8BOM;
begin
  Writeln('== 测试检测UTF-8 BOM功能 ==');
  
  var fileName := TPath.Combine(TEST_FOLDER, 'utf8-with-bom.txt');
  LogTestResult('检测带BOM的UTF8文件', fileName, TUTF8BOMConverter.HasUTF8BOM(fileName));
  
  fileName := TPath.Combine(TEST_FOLDER, 'utf8-no-bom.txt');
  LogTestResult('检测无BOM的UTF8文件', fileName, not TUTF8BOMConverter.HasUTF8BOM(fileName));
  
  fileName := TPath.Combine(TEST_FOLDER, 'ascii.txt');
  LogTestResult('检测ASCII文件', fileName, not TUTF8BOMConverter.HasUTF8BOM(fileName));
  
  fileName := TPath.Combine(TEST_FOLDER, 'ansi.txt');
  LogTestResult('检测ANSI文件', fileName, not TUTF8BOMConverter.HasUTF8BOM(fileName));
  
  Writeln;
end;

procedure TestAddUTF8BOM;
begin
  Writeln('== 测试添加UTF-8 BOM功能 ==');
  
  // 复制无BOM的UTF8文件用于测试
  var srcFile := TPath.Combine(TEST_FOLDER, 'utf8-no-bom.txt');
  var destFile := TPath.Combine(TEST_FOLDER, 'utf8-no-bom-add.txt');
  TFile.Copy(srcFile, destFile, true);
  
  // 添加BOM
  LogTestResult('添加BOM到UTF8无BOM文件', destFile, TUTF8BOMConverter.AddUTF8BOM(destFile));
  
  // 验证是否成功添加
  LogTestResult('验证已添加的BOM', destFile, TUTF8BOMConverter.HasUTF8BOM(destFile));
  
  // 测试对已有BOM的文件添加BOM（不应该有变化）
  var withBomFile := TPath.Combine(TEST_FOLDER, 'utf8-with-bom.txt');
  LogTestResult('添加BOM到已有BOM的文件', withBomFile, TUTF8BOMConverter.AddUTF8BOM(withBomFile));
  
  Writeln;
end;

procedure TestRemoveUTF8BOM;
begin
  Writeln('== 测试移除UTF-8 BOM功能 ==');
  
  // 复制带BOM的UTF8文件用于测试
  var srcFile := TPath.Combine(TEST_FOLDER, 'utf8-with-bom.txt');
  var destFile := TPath.Combine(TEST_FOLDER, 'utf8-with-bom-remove.txt');
  TFile.Copy(srcFile, destFile, true);
  
  // 移除BOM
  LogTestResult('从UTF8文件移除BOM', destFile, TUTF8BOMConverter.RemoveUTF8BOM(destFile));
  
  // 验证是否成功移除
  LogTestResult('验证BOM已被移除', destFile, not TUTF8BOMConverter.HasUTF8BOM(destFile));
  
  // 测试对无BOM的文件移除BOM（不应该有变化）
  var noBomFile := TPath.Combine(TEST_FOLDER, 'utf8-no-bom.txt');
  LogTestResult('从无BOM文件移除BOM', noBomFile, TUTF8BOMConverter.RemoveUTF8BOM(noBomFile));
  
  Writeln;
end;

procedure TestConvertToUTF8WithBOM;
begin
  Writeln('== 测试转换为UTF-8+BOM功能 ==');
  
  // 复制各种编码的文件用于测试
  var files: array[0..2] of string;
  files[0] := TPath.Combine(TEST_FOLDER, 'ansi-to-utf8bom.txt');
  files[1] := TPath.Combine(TEST_FOLDER, 'ascii-to-utf8bom.txt');
  files[2] := TPath.Combine(TEST_FOLDER, 'utf8nobom-to-utf8bom.txt');
  
  TFile.Copy(TPath.Combine(TEST_FOLDER, 'ansi.txt'), files[0], true);
  TFile.Copy(TPath.Combine(TEST_FOLDER, 'ascii.txt'), files[1], true);
  TFile.Copy(TPath.Combine(TEST_FOLDER, 'utf8-no-bom.txt'), files[2], true);
  
  // 转换所有文件为UTF-8+BOM
  for var i := 0 to High(files) do
  begin
    LogTestResult('转换为UTF-8+BOM', files[i], TUTF8BOMConverter.ConvertToUTF8WithBOM(files[i]));
    
    // 验证转换结果
    LogTestResult('验证UTF-8+BOM', files[i], TUTF8BOMConverter.HasUTF8BOM(files[i]));
  end;
  
  Writeln;
end;

procedure TestConvertToUTF8WithoutBOM;
begin
  Writeln('== 测试转换为UTF-8无BOM功能 ==');
  
  // 复制各种编码的文件用于测试
  var files: array[0..2] of string;
  files[0] := TPath.Combine(TEST_FOLDER, 'ansi-to-utf8nobom.txt');
  files[1] := TPath.Combine(TEST_FOLDER, 'ascii-to-utf8nobom.txt');
  files[2] := TPath.Combine(TEST_FOLDER, 'utf8bom-to-utf8nobom.txt');
  
  TFile.Copy(TPath.Combine(TEST_FOLDER, 'ansi.txt'), files[0], true);
  TFile.Copy(TPath.Combine(TEST_FOLDER, 'ascii.txt'), files[1], true);
  TFile.Copy(TPath.Combine(TEST_FOLDER, 'utf8-with-bom.txt'), files[2], true);
  
  // 转换所有文件为UTF-8无BOM
  for var i := 0 to High(files) do
  begin
    LogTestResult('转换为UTF-8无BOM', files[i], TUTF8BOMConverter.ConvertToUTF8WithoutBOM(files[i]));
    
    // 验证转换结果
    LogTestResult('验证UTF-8无BOM', files[i], not TUTF8BOMConverter.HasUTF8BOM(files[i]));
    
    // 验证文件仍能正确打开和读取
    try
      var content := TFile.ReadAllText(files[i]);
      LogTestResult('验证文件内容可读取', files[i], content <> '');
    except
      on E: Exception do
        Writeln('读取文件出错: ', files[i], ' - ', E.Message);
    end;
  end;
  
  Writeln;
end;

procedure TestDetectUTF8Encoding;
begin
  Writeln('== 测试UTF-8编码检测功能 ==');
  
  var files: array[0..3] of string;
  files[0] := TPath.Combine(TEST_FOLDER, 'ansi.txt');
  files[1] := TPath.Combine(TEST_FOLDER, 'ascii.txt');
  files[2] := TPath.Combine(TEST_FOLDER, 'utf8-no-bom.txt');
  files[3] := TPath.Combine(TEST_FOLDER, 'utf8-with-bom.txt');
  
  for var i := 0 to High(files) do
  begin
    var hasBom: Boolean;
    var isUTF8 := TUTF8BOMConverter.DetectUTF8Encoding(files[i], hasBom);
    
    Write('文件: ', files[i], ' - ');
    if isUTF8 then
    begin
      if hasBom then
        Writeln('检测为UTF-8编码（有BOM）')
      else
        Writeln('检测为UTF-8编码（无BOM）');
    end
    else
      Writeln('检测为非UTF-8编码');
  end;
  
  Writeln;
end;

begin
  try
    Writeln('UTF-8 BOM转换器增强版测试程序');
    Writeln('============================');
    Writeln;
    
    PrepareTestFolder;
    
    TestHasUTF8BOM;
    TestAddUTF8BOM;
    TestRemoveUTF8BOM;
    TestConvertToUTF8WithBOM;
    TestConvertToUTF8WithoutBOM;
    TestDetectUTF8Encoding;
    
    Writeln('所有测试完成');
    Writeln('按任意键退出...');
    Readln;
  except
    on E: Exception do
    begin
      Writeln('测试过程中发生错误: ', E.Message);
      Readln;
    end;
  end;
end. 