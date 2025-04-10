program FileEncodingTool;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes, 
  System.IOUtils,
  Winapi.Windows;

// 设置控制台编码
procedure SetConsoleOutputCP(CodePage: UINT);
begin
  SetConsoleCP(CodePage);
  SetConsoleOutputCP(CodePage);
end;

// 写日志
procedure Log(const Msg: string);
begin
  WriteLn(Msg);
end;

// 检测文件名中包含的编码类型
function DetectEncodingFromFileName(const FileName: string): string;
const
  ENCODINGS: array[0..6] of string = (
    'UTF-8', 'GBK', 'BIG5', 'SHIFT-JIS', 'EUC-KR', 'ISO-8859-1', 'KOI8-R'
  );
var
  FileNameLower: string;
  i: Integer;
begin
  Result := 'Unknown';
  FileNameLower := LowerCase(FileName);
  
  for i := 0 to High(ENCODINGS) do
  begin
    if Pos(LowerCase(ENCODINGS[i]), FileNameLower) > 0 then
    begin
      Result := ENCODINGS[i];
      Exit;
    end;
  end;
end;

// 转换文件编码
procedure ConvertFileEncoding(const SourceFile, DestFile: string; const DetectedEncoding: string);
var
  SourceData: TBytes;
  UTF8Content: string;
  Encoding: TEncoding;
begin
  Log('转换文件: ' + ExtractFileName(SourceFile));
  Log('目标文件: ' + ExtractFileName(DestFile));
  Log('检测编码: ' + DetectedEncoding);
  
  try
    // 读取源文件
    SourceData := TFile.ReadAllBytes(SourceFile);
    Log('源文件大小: ' + IntToStr(Length(SourceData)) + ' 字节');
    
    // 设置编码对象
    Encoding := nil;
    if SameText(DetectedEncoding, 'UTF-8') then
      Encoding := TEncoding.UTF8
    else if SameText(DetectedEncoding, 'GBK') then
      Encoding := TEncoding.GetEncoding(936)
    else if SameText(DetectedEncoding, 'BIG5') then
      Encoding := TEncoding.GetEncoding(950)
    else if SameText(DetectedEncoding, 'SHIFT-JIS') then
      Encoding := TEncoding.GetEncoding(932)
    else if SameText(DetectedEncoding, 'EUC-KR') then
      Encoding := TEncoding.GetEncoding(949)
    else if SameText(DetectedEncoding, 'ISO-8859-1') then
      Encoding := TEncoding.GetEncoding(28591)
    else if SameText(DetectedEncoding, 'KOI8-R') then
      Encoding := TEncoding.GetEncoding(20866);
    
    // 转换编码
    if Assigned(Encoding) then
    begin
      // 获取UTF-8内容
      UTF8Content := Encoding.GetString(SourceData);
      
      // 写入目标文件
      TFile.WriteAllText(DestFile, UTF8Content, TEncoding.UTF8);
      
      Log('转换成功! 内容长度: ' + IntToStr(Length(UTF8Content)) + ' 字符');
      if Length(UTF8Content) > 0 then
      begin
        Log('内容预览:');
        if Length(UTF8Content) > 100 then
          Log(Copy(UTF8Content, 1, 100) + '...')
        else
          Log(UTF8Content);
      end;
    end
    else
    begin
      // 未知编码直接复制
      TFile.Copy(SourceFile, DestFile, True);
      Log('未识别编码，已直接复制文件');
    end;
  except
    on E: Exception do
    begin
      Log('转换失败: ' + E.Message);
    end;
  end;
  
  Log('');
end;

// 处理目录中的所有文件
procedure ProcessDirectory(const SourceDir, DestDir: string);
var
  Files: TArray<string>;
  FileName: string;
  DestFile: string;
  Encoding: string;
  i: Integer;
begin
  // 检查目录
  if not DirectoryExists(SourceDir) then
  begin
    Log('错误: 源目录不存在 - ' + SourceDir);
    Exit;
  end;
  
  // 创建目标目录
  if not DirectoryExists(DestDir) then
  begin
    try
      ForceDirectories(DestDir);
      Log('已创建目标目录: ' + DestDir);
    except
      on E: Exception do
      begin
        Log('错误: 无法创建目标目录 - ' + E.Message);
        Exit;
      end;
    end;
  end;
  
  // 获取文件列表
  Files := TDirectory.GetFiles(SourceDir);
  Log('找到' + IntToStr(Length(Files)) + '个文件');
  
  // 处理每个文件
  for i := 0 to Length(Files) - 1 do
  begin
    FileName := ExtractFileName(Files[i]);
    DestFile := TPath.Combine(DestDir, TPath.GetFileNameWithoutExtension(FileName) + '_utf8' + TPath.GetExtension(FileName));
    Encoding := DetectEncodingFromFileName(FileName);
    
    ConvertFileEncoding(Files[i], DestFile, Encoding);
  end;
end;

var
  TestsDir, FromDir, ToDir: string;
begin
  try
    // 设置控制台编码为UTF-8
    SetConsoleOutputCP(CP_UTF8);
    
    Log('============================');
    Log('   文件编码转换工具 v1.0');
    Log('============================');
    
    // 设置目录
    TestsDir := TPath.Combine(GetCurrentDir, 'tests');
    FromDir := TPath.Combine(TestsDir, 'from');
    ToDir := TPath.Combine(TestsDir, 'to');
    
    Log('当前目录: ' + GetCurrentDir);
    Log('源目录: ' + FromDir);
    Log('目标目录: ' + ToDir);
    Log('');
    
    // 开始处理
    Log('开始处理...');
    ProcessDirectory(FromDir, ToDir);
    
    Log('处理完成!');
  except
    on E: Exception do
      Log('发生异常: ' + E.Message);
  end;
  
  Log('');
  Log('按回车键退出...');
  ReadLn;
end. 