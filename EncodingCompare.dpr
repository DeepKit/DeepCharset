program EncodingCompare;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Diagnostics,
  ControllerEncoding;

var
  EncodingController: TEncodingController;
  FileName: string;
  EncodingName: string;
  StopWatch: TStopwatch;
  ElapsedTime: Int64;
  OutputFile: TextFile;
  PythonCmd: string;

procedure LogMessage(const Msg: string);
begin
  Writeln(Msg);
end;

function RunPythonDetect(const FilePath: string): string;
var
  PythonOutput: TStringList;
  Command: string;
  OutputFileName: string;
begin
  Result := 'Unknown';
  
  // 创建临时输出文件名
  OutputFileName := ChangeFileExt(ExtractFileName(FilePath), '.chardet.txt');
  
  // 构建Python命令
  Command := Format('python detect_encoding.py "%s" > "%s"', [FilePath, OutputFileName]);
  
  // 执行命令
  if System.SysUtils.ExecuteProcess(Command, '', []) = 0 then
  begin
    // 读取输出文件
    PythonOutput := TStringList.Create;
    try
      if FileExists(OutputFileName) then
      begin
        PythonOutput.LoadFromFile(OutputFileName);
        
        // 解析输出，查找编码信息
        for var i := 0 to PythonOutput.Count - 1 do
        begin
          if PythonOutput[i].StartsWith('编码:') then
          begin
            Result := Trim(Copy(PythonOutput[i], 6, Length(PythonOutput[i])));
            Break;
          end;
        end;
        
        // 删除临时文件
        DeleteFile(OutputFileName);
      end;
    finally
      PythonOutput.Free;
    end;
  end;
end;

begin
  try
    // 检查命令行参数
    if ParamCount < 1 then
    begin
      Writeln('用法: EncodingCompare.exe <文件路径>');
      Exit;
    end;

    FileName := ParamStr(1);
    if not FileExists(FileName) then
    begin
      Writeln('错误: 文件不存在 - ', FileName);
      Exit;
    end;

    // 创建输出文件
    AssignFile(OutputFile, 'encoding_compare_results.csv');
    if FileExists('encoding_compare_results.csv') then
      Append(OutputFile)
    else
    begin
      Rewrite(OutputFile);
      Writeln(OutputFile, '文件,Delphi检测结果,Python检测结果,是否一致,耗时(ms)');
    end;

    // 创建编码控制器
    EncodingController := TEncodingController.Create;
    try
      EncodingController.SetLogCallback(LogMessage);

      // 检测文件编码
      Writeln('正在检测文件编码: ', FileName);
      
      // 使用我们的程序检测
      StopWatch := TStopwatch.StartNew;
      if EncodingController.DetectFileEncoding(FileName, EncodingName) then
      begin
        StopWatch.Stop;
        ElapsedTime := StopWatch.ElapsedMilliseconds;
        Writeln('Delphi检测结果: ', EncodingName);
        Writeln('耗时: ', ElapsedTime, 'ms');
      end
      else
      begin
        StopWatch.Stop;
        ElapsedTime := StopWatch.ElapsedMilliseconds;
        EncodingName := '检测失败';
        Writeln('Delphi编码检测失败');
        Writeln('耗时: ', ElapsedTime, 'ms');
      end;
      
      // 使用Python的chardet检测
      Writeln('正在使用Python chardet检测...');
      var PythonResult := RunPythonDetect(FileName);
      Writeln('Python检测结果: ', PythonResult);
      
      // 比较结果
      var IsMatch := CompareText(EncodingName, PythonResult) = 0;
      Writeln('结果是否一致: ', BoolToStr(IsMatch, True));
      
      // 保存结果到CSV
      Writeln(OutputFile, Format('"%s",%s,%s,%s,%d', 
        [FileName, EncodingName, PythonResult, BoolToStr(IsMatch, True), ElapsedTime]));
    finally
      EncodingController.Free;
      CloseFile(OutputFile);
    end;

    // 等待用户按键
    Writeln;
    Writeln('按任意键退出...');
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
