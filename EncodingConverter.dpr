program EncodingConverter;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Diagnostics,
  System.JSON,
  ControllerEncoding,
  ModelEncoding;

var
  EncodingController: TEncodingController;
  SourceFile, TargetFile, EncodingName: string;
  AddBOM: Boolean;
  StopWatch: TStopwatch;
  Verbose: Boolean;
  Success: Boolean;

procedure PrintUsage;
begin
  Writeln('用法: EncodingConverter.exe <源文件> <目标文件> --encoding <编码> [--add-bom|--no-bom] [--verbose]');
  Writeln('参数:');
  Writeln('  <源文件>      要转换的源文件路径');
  Writeln('  <目标文件>    转换后的目标文件路径');
  Writeln('  --encoding    目标编码 (utf-8, utf-16, gbk, gb18030, big5等)');
  Writeln('  --add-bom     添加BOM标记 (仅适用于UTF编码)');
  Writeln('  --no-bom      不添加BOM标记');
  Writeln('  --verbose     输出详细日志');
end;

function NormalizeEncodingName(const Name: string): string;
begin
  Result := LowerCase(Name);
  
  // 标准化编码名称
  if Result = 'utf8' then
    Result := 'utf-8'
  else if Result = 'utf16' then
    Result := 'utf-16'
  else if Result = 'utf16-le' then
    Result := 'utf-16-le'
  else if Result = 'utf16-be' then
    Result := 'utf-16-be'
  else if Result = 'utf32' then
    Result := 'utf-32'
  else if Result = 'utf32-le' then
    Result := 'utf-32-le'
  else if Result = 'utf32-be' then
    Result := 'utf-32-be';
end;

procedure LogMessage(const Msg: string);
begin
  if Verbose then
    Writeln(Msg);
end;

begin
  try
    // 默认值
    AddBOM := False;
    Verbose := False;
    EncodingName := '';
    
    // 检查命令行参数
    if ParamCount < 4 then
    begin
      PrintUsage;
      Exit;
    end;

    // 解析必需参数
    SourceFile := ParamStr(1);
    TargetFile := ParamStr(2);
    
    // 解析可选参数
    for var i := 3 to ParamCount do
    begin
      if SameText(ParamStr(i), '--encoding') and (i < ParamCount) then
        EncodingName := NormalizeEncodingName(ParamStr(i+1))
      else if SameText(ParamStr(i), '--add-bom') then
        AddBOM := True
      else if SameText(ParamStr(i), '--no-bom') then
        AddBOM := False
      else if SameText(ParamStr(i), '--verbose') then
        Verbose := True;
    end;
    
    // 检查必需参数
    if not FileExists(SourceFile) then
    begin
      Writeln('错误: 源文件不存在 - ', SourceFile);
      Exit;
    end;
    
    if EncodingName = '' then
    begin
      Writeln('错误: 未指定目标编码');
      PrintUsage;
      Exit;
    end;
    
    // 确保目标目录存在
    ForceDirectories(ExtractFilePath(TargetFile));
    
    // 创建编码控制器，使用匿名方法传递日志函数
    EncodingController := TEncodingController.Create(
      procedure(const Msg: string)
      begin
        LogMessage(Msg);
      end
    );
    
    try
      if Verbose then
      begin
        Writeln('正在转换文件编码:');
        Writeln('  源文件: ', SourceFile);
        Writeln('  目标文件: ', TargetFile);
        Writeln('  目标编码: ', EncodingName);
        Writeln('  添加BOM: ', BoolToStr(AddBOM, True));
      end;
      
      // 使用计时器测量性能
      StopWatch := TStopwatch.StartNew;
      
      // 执行转换
      Success := EncodingController.ConvertSingleFileByName(
        SourceFile, EncodingName, AddBOM, 
        procedure(const Msg: string)
        begin
          LogMessage(Msg);
        end
      );
      
      // 复制到目标路径 (ConvertSingleFileByName生成的是临时文件)
      if Success then
      begin
        try
          TFile.Copy(SourceFile + '.tmp', TargetFile, True);
          if FileExists(SourceFile + '.tmp') then
            TFile.Delete(SourceFile + '.tmp');
        except
          on E: Exception do
          begin
            Writeln('错误: 复制转换结果失败 - ', E.Message);
            Exit;
          end;
        end;
      end;

      StopWatch.Stop;
      
      // 输出结果
      if Success then
      begin
        if Verbose then
        begin
          Writeln('转换成功!');
          Writeln('耗时: ', StopWatch.ElapsedMilliseconds, 'ms');
        end;
      end
      else
      begin
        Writeln('错误: 转换失败');
        ExitCode := 1;
      end;
    finally
      EncodingController.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln('错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end. 