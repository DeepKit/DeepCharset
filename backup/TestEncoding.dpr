program TestEncoding;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  UtilsUTF8 in 'UtilsUTF8.pas',
  HelperFiles in 'HelperFiles.pas';

procedure LogMessage(const Msg: string);
begin
  WriteLn('LOG: ', Msg);
end;

procedure TestEncodingDetection;
var
  FileHelper: TFileHelper;
  TestDir, FilePath: string;
  HasBOM: Boolean;
  EncodingStr: string;
  Files: TArray<string>;
  i: Integer;
begin
  WriteLn('===== 编码检测测试 =====');
  
  // 创建文件帮助类 - 使用LogMessage过程
  FileHelper := TFileHelper.Create(LogMessage);
  
  try
    TestDir := TPath.Combine(GetCurrentDir, 'test_files');
    if not TDirectory.Exists(TestDir) then
    begin
      WriteLn('错误: 测试目录不存在，请先运行test_encoding.ps1脚本');
      Exit;
    end;
    
    // 获取所有测试文件
    Files := TDirectory.GetFiles(TestDir);
    
    for i := 0 to High(Files) do
    begin
      FilePath := Files[i];
      EncodingStr := FileHelper.DetectFileEncoding(FilePath, HasBOM);
      
      WriteLn('文件: ', ExtractFileName(FilePath));
      WriteLn('  检测编码: ', EncodingStr);
      WriteLn('  有BOM: ', BoolToStr(HasBOM, True));
      WriteLn;
    end;
  finally
    FileHelper.Free;
  end;
end;

procedure TestEncodingConversion;
var
  FileHelper: TFileHelper;
  TestDir, SourceFile, TargetFile: string;
  Success: Boolean;
  TestFiles: TArray<string>;
  OutDir: string;
  GB2312Encoding: TEncoding;
begin
  WriteLn('===== 编码转换测试 =====');
  
  // 创建文件帮助类 - 使用LogMessage过程
  FileHelper := TFileHelper.Create(LogMessage);
  
  try
    TestDir := TPath.Combine(GetCurrentDir, 'test_files');
    OutDir := TPath.Combine(TestDir, 'converted');
    
    // 确保输出目录存在
    if not TDirectory.Exists(OutDir) then
      TDirectory.CreateDirectory(OutDir);
    
    // 测试UTF-8转换
    SourceFile := TPath.Combine(TestDir, 'gb2312.txt');
    TargetFile := TPath.Combine(OutDir, 'gb2312_to_utf8.txt');
    WriteLn('转换 GB2312 -> UTF-8: ', ExtractFileName(SourceFile), ' -> ', ExtractFileName(TargetFile));
    Success := FileHelper.ConvertFile(SourceFile, TargetFile, TEncoding.UTF8, True);
    WriteLn('  结果: ', BoolToStr(Success, True));
    
    // 测试GB2312转换
    GB2312Encoding := TEncoding.GetEncoding(936);
    SourceFile := TPath.Combine(TestDir, 'utf8_bom.txt');
    TargetFile := TPath.Combine(OutDir, 'utf8_to_gb2312.txt');
    WriteLn('转换 UTF-8 -> GB2312: ', ExtractFileName(SourceFile), ' -> ', ExtractFileName(TargetFile));
    Success := FileHelper.ConvertFile(SourceFile, TargetFile, GB2312Encoding, False);
    WriteLn('  结果: ', BoolToStr(Success, True));
    
    // 再次检测转换后的文件编码
    WriteLn;
    WriteLn('检测转换后的文件编码:');
    TestFiles := TDirectory.GetFiles(OutDir);
    
    for var FilePath in TestFiles do
    begin
      var HasBOM: Boolean;
      var EncodingStr := FileHelper.DetectFileEncoding(FilePath, HasBOM);
      
      WriteLn('文件: ', ExtractFileName(FilePath));
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
    WriteLn('文件编码检测和转换测试程序');
    WriteLn('==========================');
    WriteLn;
    
    TestEncodingDetection;
    WriteLn;
    TestEncodingConversion;
    
    WriteLn;
    WriteLn('测试完成，按任意键退出...');
    ReadLn;
  except
    on E: Exception do
    begin
      WriteLn('ERROR: ', E.Message);
      ReadLn;
    end;
  end;
end. 