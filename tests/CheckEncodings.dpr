program CheckEncodings;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Diagnostics,
  ControllerEncoding;

type
  TLogProc = reference to procedure(const Msg: string);

var
  EncodingController: TEncodingController;
  DirPath: string;
  OutputFile: string;
  ResultFile: TextFile;

procedure LogMessage(const Msg: string);
begin
  Writeln(Msg);
end;

procedure ProcessFile(const FilePath: string);
var
  EncodingName: string;
  StopWatch: TStopwatch;
  ElapsedTime: Int64;
begin
  // 检测文件编码
  StopWatch := TStopwatch.StartNew;
  ElapsedTime := 0;
  if EncodingController.DetectFileEncoding(FilePath, EncodingName) then
  begin
    StopWatch.Stop;
    ElapsedTime := StopWatch.ElapsedMilliseconds;
    Writeln('文件: ', FilePath);
    Writeln('编码: ', EncodingName);
    Writeln('耗时: ', ElapsedTime, 'ms');
    Writeln(StringOfChar('-', 50));

    // 写入结果到CSV
    Writeln(ResultFile, Format('"%s","%s",%d', [FilePath, EncodingName, ElapsedTime]));
  end
  else
  begin
    StopWatch.Stop;
    Writeln('文件: ', FilePath);
    Writeln('编码检测失败');
    Writeln('耗时: ', ElapsedTime, 'ms');
    Writeln(StringOfChar('-', 50));

    // 写入结果到CSV
    Writeln(ResultFile, Format('"%s","检测失败",%d', [FilePath, ElapsedTime]));
  end;
end;

procedure ProcessDirectory(const DirPath: string);
var
  Files: TArray<string>;
  FilePath: string;
  Ext: string;
begin
  // 获取目录中的所有文件
  Files := TDirectory.GetFiles(DirPath, '*.*', TSearchOption.soAllDirectories);

  for FilePath in Files do
  begin
    // 只处理文本文件
    Ext := ExtractFileExt(FilePath).ToLower();
    if (Ext = '.txt') or (Ext = '.csv') or (Ext = '.ini') or (Ext = '.log') or
       (Ext = '.xml') or (Ext = '.json') or (Ext = '.htm') or (Ext = '.html') or
       (Ext = '.css') or (Ext = '.js') or (Ext = '.md') then
      ProcessFile(FilePath);
  end;
end;

begin
  try
    // 检查命令行参数
    if ParamCount < 1 then
    begin
      Writeln('用法: CheckEncodings.exe <目录路径> [输出CSV文件]');
      Exit;
    end;

    DirPath := ParamStr(1);
    if not DirectoryExists(DirPath) then
    begin
      Writeln('错误: 目录不存在 - ', DirPath);
      Exit;
    end;

    // 如果未指定输出文件，则使用默认名称
    if ParamCount >= 2 then
      OutputFile := ParamStr(2)
    else
      OutputFile := 'delphi_encoding_results.csv';

    // 创建输出文件
    AssignFile(ResultFile, OutputFile);
    Rewrite(ResultFile);
    Writeln(ResultFile, '文件,编码,耗时(ms)');

    // 创建编码控制器
    EncodingController := TEncodingController.Create(LogMessage);
    try
      Writeln('开始检测目录中的文件编码: ', DirPath);
      Writeln('结果将保存到: ', OutputFile);
      Writeln(StringOfChar('-', 50));

      // 处理目录
      ProcessDirectory(DirPath);

      Writeln('编码检测完成!');
    finally
      EncodingController.Free;
      CloseFile(ResultFile);
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
