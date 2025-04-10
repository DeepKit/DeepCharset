program AutoConverter;
{$APPTYPE CONSOLE}

uses
  System.SysUtils, 
  System.IOUtils,
  System.Classes,
  Winapi.Windows;

const
  LOG_FILE = 'convert_log.txt';

// 写入日志文件并显示到控制台
procedure WriteToLog(const Msg: string);
var
  Stream: TStreamWriter;
begin
  try
    Writeln(Msg);  // 显示到控制台
    if FileExists(LOG_FILE) then
      Stream := TStreamWriter.Create(LOG_FILE, True, TEncoding.UTF8)
    else
      Stream := TStreamWriter.Create(LOG_FILE, False, TEncoding.UTF8);
    try
      Stream.WriteLine(FormatDateTime('[yyyy-mm-dd hh:nn:ss] ', Now) + Msg);
    finally
      Stream.Free;
    end;
  except
    on E: Exception do
      Writeln('日志写入错误: ', E.Message);
  end;
end;

// 检查目录权限
function CheckDirectoryAccess(const Dir: string): Boolean;
var
  TestFile: string;
begin
  Result := False;
  try
    // 检查目录是否存在
    if not DirectoryExists(Dir) then
    begin
      WriteToLog('目录不存在: ' + Dir);
      Exit;
    end;
    
    // 尝试创建测试文件
    TestFile := IncludeTrailingPathDelimiter(Dir) + 'test.tmp';
    try
      TFile.WriteAllText(TestFile, 'test');
      TFile.Delete(TestFile);
      Result := True;
      WriteToLog('目录权限检查通过: ' + Dir);
    except
      on E: Exception do
        WriteToLog('目录权限检查失败: ' + Dir + ' - ' + E.Message);
    end;
  except
    on E: Exception do
      WriteToLog('目录访问检查错误: ' + E.Message);
  end;
end;

// 处理文件
procedure ProcessFile(const SourceFile, DestFile: string);
var
  Content: TBytes;
  EncodingName: string;
  SourceEncoding: TEncoding;
  Converted: Boolean;
begin
  try
    WriteToLog('处理: ' + ExtractFileName(SourceFile));
    
    // 检查源文件是否存在
    if not FileExists(SourceFile) then
    begin
      WriteToLog('错误: 源文件不存在 - ' + SourceFile);
      Exit;
    end;
    
    // 读取文件内容
    Content := TFile.ReadAllBytes(SourceFile);
    WriteToLog('  大小: ' + IntToStr(Length(Content)) + ' 字节');
    
    // 设置编码
    Converted := False;
    EncodingName := LowerCase(ExtractFileName(SourceFile));
    
    // 测试各种编码
    if Pos('gbk', EncodingName) > 0 then
    begin
      SourceEncoding := TEncoding.GetEncoding(936); // GBK
      TFile.WriteAllText(DestFile, SourceEncoding.GetString(Content), TEncoding.UTF8);
      Converted := True;
      WriteToLog('  GBK -> UTF-8 转换完成');
    end
    else if Pos('big5', EncodingName) > 0 then
    begin
      SourceEncoding := TEncoding.GetEncoding(950); // Big5
      TFile.WriteAllText(DestFile, SourceEncoding.GetString(Content), TEncoding.UTF8);
      Converted := True;
      WriteToLog('  BIG5 -> UTF-8 转换完成');
    end
    else if Pos('shift', EncodingName) > 0 then
    begin
      SourceEncoding := TEncoding.GetEncoding(932); // Shift-JIS
      TFile.WriteAllText(DestFile, SourceEncoding.GetString(Content), TEncoding.UTF8);
      Converted := True;
      WriteToLog('  Shift-JIS -> UTF-8 转换完成');
    end
    else if Pos('euc', EncodingName) > 0 then
    begin
      SourceEncoding := TEncoding.GetEncoding(949); // EUC-KR
      TFile.WriteAllText(DestFile, SourceEncoding.GetString(Content), TEncoding.UTF8);
      Converted := True;
      WriteToLog('  EUC-KR -> UTF-8 转换完成');
    end
    else if Pos('iso', EncodingName) > 0 then
    begin
      SourceEncoding := TEncoding.GetEncoding(28591); // ISO-8859-1
      TFile.WriteAllText(DestFile, SourceEncoding.GetString(Content), TEncoding.UTF8);
      Converted := True;
      WriteToLog('  ISO-8859-1 -> UTF-8 转换完成');
    end
    else if Pos('koi', EncodingName) > 0 then
    begin
      SourceEncoding := TEncoding.GetEncoding(20866); // KOI8-R
      TFile.WriteAllText(DestFile, SourceEncoding.GetString(Content), TEncoding.UTF8);
      Converted := True;
      WriteToLog('  KOI8-R -> UTF-8 转换完成');
    end;
    
    // 处理未匹配的情况
    if not Converted then
    begin
      TFile.Copy(SourceFile, DestFile, True);
      WriteToLog('  未识别编码，文件已复制');
    end;
    
    // 验证目标文件是否创建成功
    if FileExists(DestFile) then
      WriteToLog('  目标文件创建成功: ' + DestFile)
    else
      WriteToLog('  警告: 目标文件创建失败');
      
  except
    on E: Exception do
      WriteToLog('  错误: ' + E.Message);
  end;
end;

// 主程序
var
  FromDir, ToDir: string;
  Files: TArray<string>;
  DestFile: string;
  I: Integer;
begin
  try
    // 设置控制台输出编码为UTF-8
    SetConsoleOutputCP(CP_UTF8);
    
    // 清除现有日志文件
    if FileExists(LOG_FILE) then
      DeleteFile(LOG_FILE);
    
    WriteToLog('=== 自动编码转换工具 ===');
    
    // 设置目录
    FromDir := ExpandFileName(GetCurrentDir + PathDelim + 'tests' + PathDelim + 'from');
    ToDir := ExpandFileName(GetCurrentDir + PathDelim + 'tests' + PathDelim + 'to');
    
    WriteToLog('当前目录: ' + GetCurrentDir);
    WriteToLog('源目录: ' + FromDir);
    WriteToLog('目标目录: ' + ToDir);
    
    // 检查源目录
    if not DirectoryExists(FromDir) then
    begin
      WriteToLog('错误: 源目录不存在! - ' + FromDir);
      Exit;
    end;
    
    // 检查目录权限
    if not CheckDirectoryAccess(FromDir) then
    begin
      WriteToLog('错误: 无法访问源目录! - ' + FromDir);
      Exit;
    end;
    
    // 确保目标目录存在并可写
    try
      if not DirectoryExists(ToDir) then
      begin
        ForceDirectories(ToDir);
        WriteToLog('创建目标目录成功');
      end;
      
      if not CheckDirectoryAccess(ToDir) then
      begin
        WriteToLog('错误: 无法访问目标目录! - ' + ToDir);
        Exit;
      end;
    except
      on E: Exception do
      begin
        WriteToLog('错误: 无法创建或访问目标目录 - ' + E.Message);
        Exit;
      end;
    end;
    
    // 获取所有文件
    try
      Files := TDirectory.GetFiles(FromDir);
      WriteToLog('找到 ' + IntToStr(Length(Files)) + ' 个文件');
      
      // 处理各个文件
      for I := 0 to Length(Files) - 1 do
      begin
        WriteToLog('处理第 ' + IntToStr(I + 1) + '/' + IntToStr(Length(Files)) + ' 个文件');
        DestFile := ToDir + PathDelim + 'utf8_' + ExtractFileName(Files[I]);
        ProcessFile(Files[I], DestFile);
      end;
    except
      on E: Exception do
        WriteToLog('文件处理错误: ' + E.Message);
    end;
    
    WriteToLog('所有文件处理完成');
    
    // 等待用户按任意键退出
    Write('按任意键退出...');
    Readln;
  except
    on E: Exception do
      WriteToLog('程序异常: ' + E.Message);
  end;
end. 