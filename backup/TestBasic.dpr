program TestBasic;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  UtilsUTF8 in 'UtilsUTF8.pas';

var
  TestDir: string;

procedure CreateTestFiles;
var
  UTF8Text, GB2312Text, UTF8WithBOMText: string;
  UTF8Encoding, UTF8WithBOMEncoding, GB2312Encoding: TEncoding;
begin
  // 准备测试目录
  TestDir := TPath.Combine(GetCurrentDir, 'test_files');
  if not TDirectory.Exists(TestDir) then
    TDirectory.CreateDirectory(TestDir);
  
  // 准备测试文本
  UTF8Text := '这是UTF-8编码的文本，测试中文和英文English';
  UTF8WithBOMText := '这是带BOM的UTF-8编码文本，测试中文和英文English';
  GB2312Text := '这是GB2312编码的文本，测试中文和英文English';
  
  // 创建UTF-8无BOM文件
  UTF8Encoding := TEncoding.UTF8;
  TFile.WriteAllText(TPath.Combine(TestDir, 'utf8_nobom.txt'), UTF8Text, UTF8Encoding);
  
  // 创建UTF-8带BOM文件
  UTF8WithBOMEncoding := TEncoding.GetEncoding(65001); // UTF-8
  TFile.WriteAllText(TPath.Combine(TestDir, 'utf8_bom.txt'), UTF8WithBOMText, UTF8WithBOMEncoding);
  
  // 创建GB2312文件
  GB2312Encoding := TEncoding.GetEncoding(936); // GB2312/GBK
  TFile.WriteAllText(TPath.Combine(TestDir, 'gb2312.txt'), GB2312Text, GB2312Encoding);
  
  WriteLn('已创建测试文件:');
  WriteLn('- UTF-8 (无BOM): ', TPath.Combine(TestDir, 'utf8_nobom.txt'));
  WriteLn('- UTF-8 (有BOM): ', TPath.Combine(TestDir, 'utf8_bom.txt'));
  WriteLn('- GB2312: ', TPath.Combine(TestDir, 'gb2312.txt'));
end;

procedure TestEncodingDetection;
var
  Files: TArray<string>;
  i: Integer;
  HasBOM: Boolean;
  EncodingStr: string;
begin
  WriteLn;
  WriteLn('测试文件编码检测:');
  
  Files := TDirectory.GetFiles(TestDir);
  
  for i := 0 to High(Files) do
  begin
    HasBOM := False;
    EncodingStr := DetectEncoding(Files[i], HasBOM);
    
    WriteLn('文件: ', ExtractFileName(Files[i]));
    WriteLn('  检测编码: ', EncodingStr);
    WriteLn('  有BOM: ', BoolToStr(HasBOM, True));
    WriteLn;
  end;
end;

procedure TestFileConversion;
var
  SourceUTF8, SourceGB2312: string;
  TargetUTF8, TargetGB2312: string;
  Success: Boolean;
begin
  WriteLn;
  WriteLn('测试文件转换:');
  
  // 设置源文件和目标文件路径
  SourceGB2312 := TPath.Combine(TestDir, 'gb2312.txt');
  SourceUTF8 := TPath.Combine(TestDir, 'utf8_bom.txt');
  TargetUTF8 := TPath.Combine(TestDir, 'converted_to_utf8.txt');
  TargetGB2312 := TPath.Combine(TestDir, 'converted_to_gb2312.txt');
  
  // 测试GB2312 -> UTF-8转换
  WriteLn('测试 GB2312 -> UTF-8 转换:');
  WriteLn('源文件: ', ExtractFileName(SourceGB2312));
  WriteLn('目标文件: ', ExtractFileName(TargetUTF8));
  
  Success := ConvertFileToUTF8(SourceGB2312, TargetUTF8);
  WriteLn('转换结果: ', BoolToStr(Success, True));
  
  if Success and FileExists(TargetUTF8) then
  begin
    WriteLn('转换成功，目标文件已创建');
    WriteLn('目标文件大小: ', TFile.GetSize(TargetUTF8), ' 字节');
  end
  else
    WriteLn('转换失败或目标文件未创建');
  
  // 测试UTF-8 -> GB2312转换
  WriteLn;
  WriteLn('测试 UTF-8 -> GB2312 转换:');
  WriteLn('源文件: ', ExtractFileName(SourceUTF8));
  WriteLn('目标文件: ', ExtractFileName(TargetGB2312));
  
  Success := ConvertFileToGB2312(SourceUTF8, TargetGB2312);
  WriteLn('转换结果: ', BoolToStr(Success, True));
  
  if Success and FileExists(TargetGB2312) then
  begin
    WriteLn('转换成功，目标文件已创建');
    WriteLn('目标文件大小: ', TFile.GetSize(TargetGB2312), ' 字节');
  end
  else
    WriteLn('转换失败或目标文件未创建');
end;

procedure TestConvertedFiles;
var
  ConvFiles: TArray<string>;
  i: Integer;
  HasBOM: Boolean;
  EncodingStr: string;
begin
  WriteLn;
  WriteLn('检测转换后的文件:');
  
  ConvFiles := TDirectory.GetFiles(TestDir, 'converted_*');
  
  if Length(ConvFiles) = 0 then
  begin
    WriteLn('未找到已转换的文件');
    Exit;
  end;
  
  for i := 0 to High(ConvFiles) do
  begin
    HasBOM := False;
    EncodingStr := DetectEncoding(ConvFiles[i], HasBOM);
    
    WriteLn('文件: ', ExtractFileName(ConvFiles[i]));
    WriteLn('  检测编码: ', EncodingStr);
    WriteLn('  有BOM: ', BoolToStr(HasBOM, True));
    WriteLn;
  end;
end;

begin
  try
    WriteLn('基础编码测试程序');
    WriteLn('================');
    
    CreateTestFiles;
    TestEncodingDetection;
    TestFileConversion;
    TestConvertedFiles;
    
    WriteLn;
    WriteLn('测试完成!');
  except
    on E: Exception do
    begin
      WriteLn('ERROR: ', E.Message);
    end;
  end;
end. 