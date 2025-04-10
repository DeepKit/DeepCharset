program EncodingConverter;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Diagnostics,
  Winapi.Windows;

const
  // 支持的编码类型
  ENCODING_TYPES: array[0..6] of string = (
    'UTF-8', 'GBK', 'BIG5', 'SHIFT-JIS', 'EUC-KR', 'ISO-8859-1', 'KOI8-R'
  );
  
  // 超时设置（毫秒）
  TIMEOUT_GLOBAL = 60000;  // 全局超时：1分钟
  TIMEOUT_FILE_OP = 5000;  // 文件操作超时：5秒
  TIMEOUT_CONVERT = 2000;  // 单个转换超时：2秒

// 日志文件
var
  LogFileName: string = 'encoding_convert.log';
  StopWatch: TStopwatch;
  IsTimedOut: Boolean = False;

// 设置控制台输出编码
procedure SetConsoleOutputEncoding;
begin
  SetConsoleCP(CP_UTF8);
  SetConsoleOutputCP(CP_UTF8);
end;

// 向日志文件追加内容
procedure WriteLog(const Msg: string);
var
  LogFile: TextFile;
begin
  AssignFile(LogFile, LogFileName);
  if FileExists(LogFileName) then
    Append(LogFile)
  else
    Rewrite(LogFile);
  try
    WriteLn(LogFile, FormatDateTime('[yyyy-mm-dd hh:nn:ss.zzz] ', Now) + Msg);
  finally
    CloseFile(LogFile);
  end;
  
  // 输出到控制台
  WriteLn(Msg);
end;

// 检查是否超时
function CheckTimeout(Timeout: Int64): Boolean;
begin
  Result := StopWatch.ElapsedMilliseconds > Timeout;
  if Result and not IsTimedOut then
  begin
    IsTimedOut := True;
    WriteLog('警告：操作已超时（' + IntToStr(StopWatch.ElapsedMilliseconds) + 'ms）');
  end;
end;

// 检测文件编码并转换
procedure ConvertFile(const SourceFile: string; const DestDir: string);
var
  SourceData: TBytes;
  DetectedEncoding: string;
  DestFile: string;
  UTF8Content: string;
  DefaultEncoding: TEncoding;
  i: Integer;
  FileName: string;
  FileTimer: TStopwatch;
begin
  if CheckTimeout(TIMEOUT_GLOBAL) then Exit;
  
  FileTimer := TStopwatch.StartNew;
  FileName := ExtractFileName(SourceFile);
  WriteLog('处理文件: ' + FileName);
  
  // 读取源文件内容
  try
    SourceData := TFile.ReadAllBytes(SourceFile);
    if CheckTimeout(TIMEOUT_GLOBAL) or (FileTimer.ElapsedMilliseconds > TIMEOUT_FILE_OP) then
    begin
      WriteLog('  读取文件超时');
      Exit;
    end;
    WriteLog('  文件大小: ' + IntToStr(Length(SourceData)) + ' 字节');
  except
    on E: Exception do
    begin
      WriteLog('  读取源文件失败: ' + E.Message);
      Exit;
    end;
  end;
  
  // 根据文件名推测编码
  DetectedEncoding := 'Unknown';
  for i := 0 to High(ENCODING_TYPES) do
  begin
    if Pos(LowerCase(ENCODING_TYPES[i]), LowerCase(FileName)) > 0 then
    begin
      DetectedEncoding := ENCODING_TYPES[i];
      Break;
    end;
  end;
  
  WriteLog('  推测编码: ' + DetectedEncoding);
  
  // 创建目标文件名
  DestFile := TPath.Combine(DestDir, TPath.GetFileNameWithoutExtension(FileName) + '_utf8' + TPath.GetExtension(FileName));
  
  // 如果检测到编码则转换
  if DetectedEncoding <> 'Unknown' then
  begin
    try
      // 根据检测到的编码创建对应的编码对象
      DefaultEncoding := nil;
      
      if SameText(DetectedEncoding, 'UTF-8') then
        DefaultEncoding := TEncoding.UTF8
      else if SameText(DetectedEncoding, 'GBK') then
        DefaultEncoding := TEncoding.GetEncoding(936)  // GBK代码页
      else if SameText(DetectedEncoding, 'BIG5') then
        DefaultEncoding := TEncoding.GetEncoding(950) // Big5代码页
      else if SameText(DetectedEncoding, 'SHIFT-JIS') then
        DefaultEncoding := TEncoding.GetEncoding(932) // Shift-JIS代码页
      else if SameText(DetectedEncoding, 'EUC-KR') then
        DefaultEncoding := TEncoding.GetEncoding(949) // EUC-KR代码页
      else if SameText(DetectedEncoding, 'ISO-8859-1') then
        DefaultEncoding := TEncoding.GetEncoding(28591) // ISO-8859-1代码页
      else if SameText(DetectedEncoding, 'KOI8-R') then
        DefaultEncoding := TEncoding.GetEncoding(20866); // KOI8-R代码页
      
      if Assigned(DefaultEncoding) then
      begin
        // 转换为UTF-8
        FileTimer.Reset;
        FileTimer.Start;
        UTF8Content := DefaultEncoding.GetString(SourceData);
        
        if CheckTimeout(TIMEOUT_GLOBAL) or (FileTimer.ElapsedMilliseconds > TIMEOUT_CONVERT) then
        begin
          WriteLog('  编码转换超时');
          Exit;
        end;
        
        // 将UTF-8内容写入目标文件
        FileTimer.Reset;
        FileTimer.Start;
        TFile.WriteAllText(DestFile, UTF8Content, TEncoding.UTF8);
        
        if CheckTimeout(TIMEOUT_GLOBAL) or (FileTimer.ElapsedMilliseconds > TIMEOUT_FILE_OP) then
        begin
          WriteLog('  写入文件超时');
          Exit;
        end;
        
        WriteLog('  转换成功: ' + DestFile);
        WriteLog('  字符数: ' + IntToStr(Length(UTF8Content)));
        
        // 尝试显示部分内容
        if Length(UTF8Content) > 0 then
        begin
          WriteLog('  内容预览:');
          if Length(UTF8Content) > 100 then
            WriteLog('  ' + Copy(UTF8Content, 1, 100) + '...')
          else
            WriteLog('  ' + UTF8Content);
        end;
      end
      else
      begin
        WriteLog('  未能创建编码对象: ' + DetectedEncoding);
        // 直接复制文件
        FileTimer.Reset;
        FileTimer.Start;
        TFile.Copy(SourceFile, DestFile, True);
        
        if CheckTimeout(TIMEOUT_GLOBAL) or (FileTimer.ElapsedMilliseconds > TIMEOUT_FILE_OP) then
        begin
          WriteLog('  复制文件超时');
          Exit;
        end;
        
        WriteLog('  已直接复制文件');
      end;
    except
      on E: Exception do
      begin
        WriteLog('  转换失败: ' + E.Message);
        try
          // 直接二进制复制
          FileTimer.Reset;
          FileTimer.Start;
          TFile.Copy(SourceFile, DestFile, True);
          
          if CheckTimeout(TIMEOUT_GLOBAL) or (FileTimer.ElapsedMilliseconds > TIMEOUT_FILE_OP) then
          begin
            WriteLog('  复制文件超时');
            Exit;
          end;
          
          WriteLog('  已直接复制文件');
        except
          on E2: Exception do
            WriteLog('  复制也失败: ' + E2.Message);
        end;
      end;
    end;
  end
  else
  begin
    // 对于未知编码，直接复制
    try
      FileTimer.Reset;
      FileTimer.Start;
      TFile.Copy(SourceFile, DestFile, True);
      
      if CheckTimeout(TIMEOUT_GLOBAL) or (FileTimer.ElapsedMilliseconds > TIMEOUT_FILE_OP) then
      begin
        WriteLog('  复制文件超时');
        Exit;
      end;
      
      WriteLog('  未识别编码，已直接复制文件');
    except
      on E: Exception do
        WriteLog('  复制失败: ' + E.Message);
    end;
  end;
  
  WriteLog('');
end;

// 转换目录中的所有文件
procedure ConvertDirectory(const SourceDir, DestDir: string);
var
  Files: TArray<string>;
  i: Integer;
begin
  if CheckTimeout(TIMEOUT_GLOBAL) then Exit;
  
  // 确保目录存在
  if not DirectoryExists(SourceDir) then
  begin
    WriteLog('源目录不存在: ' + SourceDir);
    Exit;
  end;
  
  // 创建目标目录
  if not DirectoryExists(DestDir) then
  begin
    try
      TDirectory.CreateDirectory(DestDir);
      WriteLog('创建目标目录: ' + DestDir);
    except
      on E: Exception do
      begin
        WriteLog('创建目标目录失败: ' + E.Message);
        Exit;
      end;
    end;
  end;
  
  // 获取所有文件
  try
    Files := TDirectory.GetFiles(SourceDir);
    if CheckTimeout(TIMEOUT_GLOBAL) then Exit;
    WriteLog('源目录中的文件数量: ' + IntToStr(Length(Files)));
  except
    on E: Exception do
    begin
      WriteLog('获取文件列表失败: ' + E.Message);
      Exit;
    end;
  end;
  
  // 转换每个文件
  for i := 0 to High(Files) do
  begin
    if CheckTimeout(TIMEOUT_GLOBAL) then Break;
    ConvertFile(Files[i], DestDir);
  end;
end;

var
  TestsDir, FromDir, ToDir: string;
begin
  try
    // 设置控制台编码为UTF-8
    SetConsoleOutputEncoding;
    
    WriteLn('编码转换工具启动...');
    StopWatch := TStopwatch.StartNew;
    
    // 设置工作目录
    TestsDir := TPath.Combine(GetCurrentDir, 'tests');
    if not DirectoryExists(TestsDir) then
      TestsDir := GetCurrentDir;
    
    FromDir := TPath.Combine(TestsDir, 'from');
    ToDir := TPath.Combine(TestsDir, 'to');
    
    WriteLog('=== 编码转换工具 ===');
    WriteLog('当前目录: ' + GetCurrentDir);
    WriteLog('测试目录: ' + TestsDir);
    WriteLog('源目录: ' + FromDir);
    WriteLog('目标目录: ' + ToDir);
    WriteLog('全局超时: ' + IntToStr(TIMEOUT_GLOBAL) + 'ms');
    
    // 执行转换
    WriteLog('');
    WriteLog('开始转换...');
    ConvertDirectory(FromDir, ToDir);
    
    // 检查是否因超时退出
    if IsTimedOut then
      WriteLog('处理因超时而中断')
    else
      WriteLog('转换完成');
      
    WriteLog('总耗时: ' + IntToStr(StopWatch.ElapsedMilliseconds) + 'ms');
  except
    on E: Exception do
      WriteLog('程序异常: ' + E.Message);
  end;
  
  WriteLn('');
  WriteLn('任务完成，详细日志请查看 ' + LogFileName);
  WriteLn('总运行时间: ' + IntToStr(StopWatch.ElapsedMilliseconds) + 'ms');
  WriteLn('按回车键退出...');
  ReadLn;
end. 