program TestIconv;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Math,
  Winapi.Windows;

const
  // 支持的编码类型
  ENCODING_TYPES: array[0..6] of string = (
    'UTF-8', 'GBK', 'BIG5', 'SHIFT-JIS', 'EUC-KR', 'ISO-8859-1', 'KOI8-R'
  );
  
var
  LogFile: TextFile;
  
// 设置控制台编码
procedure SetConsoleOutputCP(CodePage: UINT);
begin
  SetConsoleCP(CodePage);
  SetConsoleOutputCP(CodePage);
end;

// 仅写入文件，不输出到控制台
procedure WriteLog(const Msg: string);
begin
  WriteLn(LogFile, FormatDateTime('[yyyy-mm-dd hh:nn:ss] ', Now) + Msg);
  Flush(LogFile);
  WriteLn(Msg); // 同时输出到控制台
end;

// 确保目录存在
function EnsureDirectoryExists(const Path: string): Boolean;
begin
  Result := DirectoryExists(Path);
  if not Result then
  begin
    try
      Result := ForceDirectories(Path);
      if Result then
        WriteLog('创建目录成功: ' + Path)
      else
        WriteLog('创建目录失败: ' + Path);
    except
      on E: Exception do
      begin
        Result := False;
        WriteLog('创建目录出错: ' + Path + ' - ' + E.Message);
      end;
    end;
  end;
end;

// 获取磁盘空间信息
function GetDiskFreeSpace(const Path: string): Int64;
var
  FreeAvailable, TotalSpace: Int64;
begin
  Result := -1;
  if GetDiskFreeSpaceEx(PChar(Path), FreeAvailable, TotalSpace, nil) then
    Result := FreeAvailable;
end;

// 检查目录是否可写
function IsDirectoryWritable(const Dir: string): Boolean;
var
  TestFile: string;
  TestHandle: THandle;
begin
  Result := False;
  if not DirectoryExists(Dir) then Exit;
  
  TestFile := IncludeTrailingPathDelimiter(Dir) + 'test_write_' + FormatDateTime('hhnnss', Now) + '.tmp';
  
  try
    TestHandle := CreateFile(
      PChar(TestFile),
      GENERIC_READ or GENERIC_WRITE,
      0,
      nil,
      CREATE_ALWAYS,
      FILE_ATTRIBUTE_TEMPORARY or FILE_FLAG_DELETE_ON_CLOSE,
      0);
      
    Result := (TestHandle <> INVALID_HANDLE_VALUE);
    
    if Result then
      CloseHandle(TestHandle);
  except
    Result := False;
  end;
end;

function GetLastErrorAsString: string;
var
  ErrorCode: Cardinal;
  Len: Integer;
  Buffer: array [0..255] of Char;
begin
  ErrorCode := GetLastError;
  Len := FormatMessage(
    FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_IGNORE_INSERTS,
    nil,
    ErrorCode,
    0,
    Buffer,
    Length(Buffer),
    nil);
  SetString(Result, Buffer, Len);
  Result := Trim(Result);
  Result := Format('错误代码: %d, 错误信息: %s', [ErrorCode, Result]);
end;

var
  LogLines: TStringList;
  
procedure Log(const Msg: string);
begin
  Writeln(Msg);
  if Assigned(LogLines) then
    LogLines.Add(Msg);
end;

function SafeWriteTextFile(const FileName: string; const Content: string): Boolean;
var
  FileStream: TFileStream;
  Buffer: TBytes;
begin
  Result := False;
  try
    // 尝试使用低级API直接创建文件
    FileStream := TFileStream.Create(FileName, fmCreate);
    try
      if Content <> '' then
      begin
        Buffer := TEncoding.UTF8.GetBytes(Content);
        FileStream.WriteBuffer(Buffer, Length(Buffer));
      end;
      Result := True;
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      Log('写入文件失败: ' + FileName);
      Log('错误: ' + E.Message);
      Log('系统错误: ' + GetLastErrorAsString);
    end;
  end;
end;

// 显示文件内容的前N行
procedure ShowFileContent(const FileName: string; Lines: Integer = 5);
var
  FileStream: TFileStream;
  Reader: TStreamReader;
  Line: string;
  Count: Integer;
begin
  WriteLog('读取文件: ' + ExtractFileName(FileName));

  try
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      Reader := TStreamReader.Create(FileStream, TEncoding.Default, True);
      try
        Count := 0;
        WriteLog('文件内容预览:');
        WriteLog('----------------------------------------');
        while (not Reader.EndOfStream) and (Count < Lines) do
        begin
          Line := Reader.ReadLine;
          WriteLog('> ' + Line);
          Inc(Count);
        end;
        if not Reader.EndOfStream then
          WriteLog('... (更多内容省略) ...');
        WriteLog('----------------------------------------');
      finally
        Reader.Free;
      end;
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
      WriteLog('读取文件失败: ' + E.Message);
  end;
end;

begin
  // 尝试设置控制台代码页为UTF-8
  try
    SetConsoleOutputCP(CP_UTF8);
  except
    // 忽略错误
  end;

  try
    // 打开日志文件
    AssignFile(LogFile, 'iconv_test.log');
    Rewrite(LogFile);
    
    WriteLog('=== 编码转换测试开始 ===');
    WriteLog('当前目录: ' + GetCurrentDir);
    
    // 设置测试目录
    var TestsDir := TPath.Combine(GetCurrentDir, 'tests');
    if not DirectoryExists(TestsDir) then
      TestsDir := GetCurrentDir; // 如果tests目录不存在，使用当前目录

    WriteLog('测试目录: ' + TestsDir);
    
    var FromDir := TPath.Combine(TestsDir, 'from');
    var ToDir := TPath.Combine(TestsDir, 'to');
    var BackDir := TPath.Combine(TestsDir, 'back');
    
    WriteLog('来源目录: ' + FromDir);
    WriteLog('目标目录: ' + ToDir);
    WriteLog('备份目录: ' + BackDir);
    
    // 先检查目录是否存在
    if not DirectoryExists(FromDir) then
    begin
      WriteLog('警告: 来源目录不存在! ' + FromDir);
      EnsureDirectoryExists(FromDir);
    end;
    
    EnsureDirectoryExists(ToDir);
    EnsureDirectoryExists(BackDir);
    
    // 列出源文件
    if DirectoryExists(FromDir) then
    begin
      WriteLog('');
      WriteLog('=== 源文件检测 ===');
      
      try
        var Files := TDirectory.GetFiles(FromDir);
        WriteLog('源文件数量: ' + IntToStr(Length(Files)));
        
        if Length(Files) > 0 then
        begin
          for var i := 0 to Length(Files) - 1 do
          begin
            var FileName := ExtractFileName(Files[i]);
            var FileSize := TFile.GetSize(Files[i]);
            WriteLog(Format('文件[%d]: %s (%d 字节)', [i, FileName, FileSize]));
            
            // 检测文件编码
            var DetectedEncoding := 'Unknown';
            for var encType in ENCODING_TYPES do
            begin
              if Pos(LowerCase(encType), LowerCase(FileName)) > 0 then
              begin
                DetectedEncoding := encType;
                Break;
              end;
            end;
            
            WriteLog('  推测编码: ' + DetectedEncoding);
            
            // 显示文件前几行内容
            ShowFileContent(Files[i], 3);
            WriteLog('');
          end;
        end
        else
          WriteLog('警告: 没有找到任何源文件');
      except
        on E: Exception do
          WriteLog('列出源文件时出错: ' + E.Message);
      end;
    end;
    
    // 测试简单复制
    WriteLog('');
    WriteLog('=== 文件复制测试 ===');
    
    if DirectoryExists(FromDir) and DirectoryExists(ToDir) then
    begin
      try
        var Files := TDirectory.GetFiles(FromDir);
        
        if Length(Files) > 0 then
        begin
          var SourceFile := Files[0];
          var DestFile := TPath.Combine(ToDir, ExtractFileName(SourceFile));
          
          WriteLog('复制文件: ' + ExtractFileName(SourceFile));
          WriteLog('  从: ' + SourceFile);
          WriteLog('  到: ' + DestFile);
          
          try
            TFile.Copy(SourceFile, DestFile, True);
            WriteLog('文件复制成功');
            
            if TFile.Exists(DestFile) then
            begin
              WriteLog('目标文件大小: ' + IntToStr(TFile.GetSize(DestFile)) + ' 字节');
              ShowFileContent(DestFile, 3);
            end;
          except
            on E: Exception do
              WriteLog('文件复制失败: ' + E.Message);
          end;
        end;
      except
        on E: Exception do
          WriteLog('文件复制测试出错: ' + E.Message);
      end;
    end;
    
    WriteLog('');
    WriteLog('=== 编码转换测试完成 ===');
  finally
    if TTextRec(LogFile).Mode <> fmClosed then
      CloseFile(LogFile);
  end;
  
  WriteLn('');
  WriteLn('测试完成，结果已保存至 iconv_test.log');
  WriteLn('按回车键退出...');
  ReadLn;
end. 