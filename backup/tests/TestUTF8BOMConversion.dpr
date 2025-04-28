program TestUTF8BOMConversion;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.DateUtils,
  UtilsEncodingBOM,
  UtilsEncodingLogger,
  UTF8BOMConverter;

var
  Logger: TEncodingLogger;
  Converter: TUTF8BOMConverter;
  SourceFile, TargetFile: string;
  Success: Boolean;
  StartTime, EndTime: TDateTime;
  ElapsedTime: Int64;

procedure LogMessage(const Msg: string);
begin
  Writeln(Msg);
end;

procedure TestAddBOM(const SourceFile, TargetFile: string);
begin
  Writeln('测试添加BOM到UTF-8文件');
  Writeln('----------------------');
  Writeln(Format('源文件: %s', [SourceFile]));
  Writeln(Format('目标文件: %s', [TargetFile]));
  Writeln('');
  
  // 检查源文件是否存在
  if not FileExists(SourceFile) then
  begin
    Writeln('错误: 源文件不存在');
    Exit;
  end;
  
  // 检查源文件是否有BOM
  Writeln('检查源文件是否有BOM...');
  if Converter.HasBOM(SourceFile) then
    Writeln('源文件已经有BOM')
  else
    Writeln('源文件没有BOM');
  Writeln('');
  
  // 添加BOM
  Writeln('添加BOM到文件...');
  StartTime := Now;
  Success := Converter.AddBOMToFile(SourceFile, TargetFile);
  EndTime := Now;
  ElapsedTime := MilliSecondsBetween(EndTime, StartTime);
  
  if Success then
  begin
    Writeln('添加BOM成功');
    Writeln(Format('耗时: %d 毫秒', [ElapsedTime]));
    
    // 检查目标文件是否有BOM
    Writeln('');
    Writeln('检查目标文件是否有BOM...');
    if Converter.HasBOM(TargetFile) then
      Writeln('目标文件有BOM')
    else
      Writeln('错误: 目标文件没有BOM');
  end
  else
    Writeln('添加BOM失败');
  
  Writeln('');
end;

procedure TestRemoveBOM(const SourceFile, TargetFile: string);
begin
  Writeln('测试从文件移除BOM');
  Writeln('----------------');
  Writeln(Format('源文件: %s', [SourceFile]));
  Writeln(Format('目标文件: %s', [TargetFile]));
  Writeln('');
  
  // 检查源文件是否存在
  if not FileExists(SourceFile) then
  begin
    Writeln('错误: 源文件不存在');
    Exit;
  end;
  
  // 检查源文件是否有BOM
  Writeln('检查源文件是否有BOM...');
  if Converter.HasBOM(SourceFile) then
    Writeln('源文件有BOM')
  else
    Writeln('源文件没有BOM');
  Writeln('');
  
  // 移除BOM
  Writeln('从文件移除BOM...');
  StartTime := Now;
  Success := Converter.RemoveBOMFromFile(SourceFile, TargetFile);
  EndTime := Now;
  ElapsedTime := MilliSecondsBetween(EndTime, StartTime);
  
  if Success then
  begin
    Writeln('移除BOM成功');
    Writeln(Format('耗时: %d 毫秒', [ElapsedTime]));
    
    // 检查目标文件是否有BOM
    Writeln('');
    Writeln('检查目标文件是否有BOM...');
    if Converter.HasBOM(TargetFile) then
      Writeln('错误: 目标文件仍然有BOM')
    else
      Writeln('目标文件没有BOM');
  end
  else
    Writeln('移除BOM失败');
  
  Writeln('');
end;

procedure TestBatchConversion(const SourceDir, TargetDir: string);
var
  Files: TArray<string>;
  I: Integer;
  SourceFile, TargetFile: string;
  SuccessCount, FailureCount: Integer;
  TotalTime: Int64;
begin
  Writeln('测试批量添加BOM');
  Writeln('-------------');
  Writeln(Format('源目录: %s', [SourceDir]));
  Writeln(Format('目标目录: %s', [TargetDir]));
  Writeln('');
  
  // 检查源目录是否存在
  if not DirectoryExists(SourceDir) then
  begin
    Writeln('错误: 源目录不存在');
    Exit;
  end;
  
  // 确保目标目录存在
  if not DirectoryExists(TargetDir) then
    ForceDirectories(TargetDir);
  
  // 获取源目录中的所有文本文件
  Files := TDirectory.GetFiles(SourceDir, '*.txt;*.md;*.xml;*.html;*.json;*.js;*.css;*.pas;*.dpr', TSearchOption.soAllDirectories);
  
  Writeln(Format('找到 %d 个文件', [Length(Files)]));
  Writeln('');
  
  SuccessCount := 0;
  FailureCount := 0;
  TotalTime := 0;
  
  for I := 0 to Length(Files) - 1 do
  begin
    SourceFile := Files[I];
    TargetFile := StringReplace(SourceFile, SourceDir, TargetDir, [rfIgnoreCase]);
    
    // 确保目标文件的目录存在
    ForceDirectories(ExtractFilePath(TargetFile));
    
    Writeln(Format('处理文件 %d/%d: %s', [I+1, Length(Files), ExtractFileName(SourceFile)]));
    
    // 添加BOM
    StartTime := Now;
    Success := Converter.AddBOMToFile(SourceFile, TargetFile);
    EndTime := Now;
    ElapsedTime := MilliSecondsBetween(EndTime, StartTime);
    
    TotalTime := TotalTime + ElapsedTime;
    
    if Success then
    begin
      Inc(SuccessCount);
      Writeln(Format('  添加BOM成功，耗时: %d 毫秒', [ElapsedTime]));
      
      // 检查目标文件是否有BOM
      if Converter.HasBOM(TargetFile) then
        Writeln('  目标文件有BOM')
      else
        Writeln('  警告: 目标文件没有BOM');
    end
    else
    begin
      Inc(FailureCount);
      Writeln('  添加BOM失败');
    end;
    
    Writeln('');
  end;
  
  Writeln('批量处理完成');
  Writeln(Format('成功: %d', [SuccessCount]));
  Writeln(Format('失败: %d', [FailureCount]));
  Writeln(Format('总耗时: %d 毫秒', [TotalTime]));
  Writeln(Format('平均耗时: %.2f 毫秒/文件', [TotalTime / Length(Files)]));
  Writeln('');
end;

begin
  try
    // 创建日志记录器
    Logger := TEncodingLogger.Create;
    Logger.SetLogCallback(LogMessage);
    
    // 创建转换器
    Converter := TUTF8BOMConverter.Create(Logger);
    
    try
      // 解析命令行参数
      if ParamCount < 1 then
      begin
        Writeln('用法:');
        Writeln('  TestUTF8BOMConversion add <源文件> <目标文件>');
        Writeln('  TestUTF8BOMConversion remove <源文件> <目标文件>');
        Writeln('  TestUTF8BOMConversion batch <源目录> <目标目录>');
        Writeln('');
        Writeln('示例:');
        Writeln('  TestUTF8BOMConversion add test.txt test_bom.txt');
        Writeln('  TestUTF8BOMConversion remove test_bom.txt test_nobom.txt');
        Writeln('  TestUTF8BOMConversion batch ./testfiles ./testfiles_bom');
        Exit;
      end;
      
      // 根据命令行参数执行相应的操作
      if LowerCase(ParamStr(1)) = 'add' then
      begin
        if ParamCount < 3 then
        begin
          Writeln('错误: 缺少参数');
          Exit;
        end;
        
        TestAddBOM(ParamStr(2), ParamStr(3));
      end
      else if LowerCase(ParamStr(1)) = 'remove' then
      begin
        if ParamCount < 3 then
        begin
          Writeln('错误: 缺少参数');
          Exit;
        end;
        
        TestRemoveBOM(ParamStr(2), ParamStr(3));
      end
      else if LowerCase(ParamStr(1)) = 'batch' then
      begin
        if ParamCount < 3 then
        begin
          Writeln('错误: 缺少参数');
          Exit;
        end;
        
        TestBatchConversion(ParamStr(2), ParamStr(3));
      end
      else
      begin
        Writeln('错误: 无效的命令 - ', ParamStr(1));
        Writeln('有效的命令: add, remove, batch');
      end;
    finally
      Converter.Free;
      Logger.Free;
    end;
    
    Writeln('按任意键退出...');
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
