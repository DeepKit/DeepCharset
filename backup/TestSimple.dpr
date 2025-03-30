program TestSimple;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  Vcl.Dialogs,
  UtilsUTF8 in 'UtilsUTF8.pas',
  HelperFiles in 'HelperFiles.pas';

type
  TLogProc = reference to procedure(const Msg: string);

var
  SourcePath, TargetPath: string;

procedure CreateTestFiles;
var
  TestDir: string;
  UTF8Text, UTF8WithBOMText, GB2312Text: string;
  UTF8Encoding, UTF8WithBOMEncoding, GB2312Encoding: TEncoding;
begin
  TestDir := TPath.Combine(GetCurrentDir, 'test_files');
  if not TDirectory.Exists(TestDir) then
    TDirectory.CreateDirectory(TestDir);
    
  UTF8Text := '这是UTF-8编码的文本，测试中文和英文English';
  UTF8WithBOMText := '这是UTF-8+BOM编码的文本，测试中文和英文English';
  GB2312Text := '这是GB2312编码的文本，测试中文和英文English';
  
  // 创建UTF-8无BOM文件
  UTF8Encoding := TEncoding.UTF8;
  TFile.WriteAllText(TPath.Combine(TestDir, 'utf8_nobom.txt'), UTF8Text, UTF8Encoding);
  
  // 创建UTF-8有BOM文件
  UTF8WithBOMEncoding := TEncoding.GetEncoding(65001); // UTF-8
  TFile.WriteAllText(TPath.Combine(TestDir, 'utf8_bom.txt'), UTF8WithBOMText, UTF8WithBOMEncoding);
  
  // 创建GB2312文件
  GB2312Encoding := TEncoding.GetEncoding(936); // GB2312/GBK
  TFile.WriteAllText(TPath.Combine(TestDir, 'gb2312.txt'), GB2312Text, GB2312Encoding);
  
  WriteLn('已创建测试文件：');
  WriteLn('- UTF-8 (无BOM): ', TPath.Combine(TestDir, 'utf8_nobom.txt'));
  WriteLn('- UTF-8 (有BOM): ', TPath.Combine(TestDir, 'utf8_bom.txt'));
  WriteLn('- GB2312: ', TPath.Combine(TestDir, 'gb2312.txt'));
  
  SourcePath := TPath.Combine(TestDir, 'gb2312.txt');
  TargetPath := TPath.Combine(TestDir, 'converted_to_utf8.txt');
end;

procedure TestConversion;
var
  Success: Boolean;
begin
  WriteLn;
  WriteLn('测试文件转换:');
  WriteLn('源文件: ', ExtractFileName(SourcePath));
  WriteLn('目标文件: ', ExtractFileName(TargetPath));
  
  try
    // 测试UTF-8转换
    WriteLn('测试GB2312 -> UTF-8转换:');
    Success := ConvertFileToUTF8(SourcePath, TargetPath);
    WriteLn('转换结果: ', BoolToStr(Success, True));
    
    if Success and FileExists(TargetPath) then
    begin
      WriteLn('转换成功，目标文件已创建');
      WriteLn('目标文件大小: ', TFile.GetSize(TargetPath), ' 字节');
    end
    else
      WriteLn('转换失败或目标文件未创建');
      
    // 测试GB2312转换
    WriteLn;
    WriteLn('测试UTF-8 -> GB2312转换:');
    SourcePath := TPath.Combine(ExtractFilePath(SourcePath), 'utf8_bom.txt');
    TargetPath := TPath.Combine(ExtractFilePath(TargetPath), 'converted_to_gb2312.txt');
    WriteLn('源文件: ', ExtractFileName(SourcePath));
    WriteLn('目标文件: ', ExtractFileName(TargetPath));
    
    Success := ConvertFileToGB2312(SourcePath, TargetPath);
    WriteLn('转换结果: ', BoolToStr(Success, True));
    
    if Success and FileExists(TargetPath) then
    begin
      WriteLn('转换成功，目标文件已创建');
      WriteLn('目标文件大小: ', TFile.GetSize(TargetPath), ' 字节');
    end
    else
      WriteLn('转换失败或目标文件未创建');
  except
    on E: Exception do
      WriteLn('转换过程中出错: ', E.Message);
  end;
end;

procedure TestSimpleDetection;
var
  TestDir: string;
  Files: TArray<string>;
  i: Integer;
  FileName: string;
  Encoding: string;
  HasBOM: Boolean;
begin
  WriteLn;
  WriteLn('简单编码检测测试:');
  
  TestDir := TPath.Combine(GetCurrentDir, 'test_files');
  Files := TDirectory.GetFiles(TestDir);
  
  for i := 0 to High(Files) do
  begin
    FileName := Files[i];
    HasBOM := False;
    Encoding := DetectEncoding(FileName, HasBOM);
    
    WriteLn('文件: ', ExtractFileName(FileName));
    WriteLn('  检测编码: ', Encoding);
    WriteLn('  有BOM: ', BoolToStr(HasBOM, True));
    WriteLn;
  end;
end;

procedure LogMessage(const Msg: string);
begin
  WriteLn('[LOG] ', Msg);
end;

function GetLogCallback: TProc<string>;
begin
  Result := LogMessage;
end;

procedure TestHelperDetection;
var
  TestDir: string;
  Files: TArray<string>;
  FileHelper: TFileHelper;
  i: Integer;
  EncodingStr: string;
  HasBOM: Boolean;
begin
  WriteLn;
  WriteLn('Helper编码检测测试:');
  
  TestDir := TPath.Combine(GetCurrentDir, 'test_files');
  Files := TDirectory.GetFiles(TestDir);
  
  // 创建文件帮助类，使用普通过程作为回调
  FileHelper := TFileHelper.Create(GetLogCallback);
  
  try
    for i := 0 to High(Files) do
    begin
      EncodingStr := FileHelper.DetectFileEncoding(Files[i], HasBOM);
      
      WriteLn('文件: ', ExtractFileName(Files[i]));
      WriteLn('  检测编码: ', EncodingStr);
      WriteLn('  有BOM: ', BoolToStr(HasBOM, True));
      WriteLn;
    end;
  finally
    FileHelper.Free;
  end;
end;

begin
  try
    WriteLn('简单编码测试程序');
    WriteLn('================');
    
    CreateTestFiles;
    TestConversion;
    TestSimpleDetection;
    TestHelperDetection;
    
    WriteLn;
    WriteLn('测试完成!');
  except
    on E: Exception do
    begin
      WriteLn('ERROR: ', E.Message);
    end;
  end;
end. 