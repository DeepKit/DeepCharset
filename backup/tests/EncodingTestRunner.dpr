program EncodingTestRunner;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.DateUtils,
  EncodingUtils in 'EncodingUtils.pas';

type
  TTestMode = (tmDetect, tmConvert, tmBoth);

var
  TestFiles: TArray<string>;
  FileName, TargetFileName: string;
  Result: TEncodingDetectionResult;
  StartTime, EndTime: TDateTime;
  ElapsedTime: Int64;
  TestMode: TTestMode;
  TargetEncoding: TEncoding;
  WithBOM: Boolean;
  ConversionSuccess: Boolean;

var
  LogFile: TextFile;
  LogEnabled: Boolean = False;

procedure LogMessage(const Msg: string);
begin
  Writeln(Msg);

  if LogEnabled then
  begin
    try
      Writeln(LogFile, Format('[%s] %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), Msg]));
      Flush(LogFile);
    except
      // 忽略日志写入错误
    end;
  end;
end;

procedure InitializeLog(const LogFileName: string = 'encoding_test.log');
begin
  try
    AssignFile(LogFile, LogFileName);
    if FileExists(LogFileName) then
      Append(LogFile)
    else
      Rewrite(LogFile);

    LogEnabled := True;
    LogMessage('日志初始化成功');
    LogMessage('测试开始时间: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    LogMessage('----------------------------------------');
  except
    on E: Exception do
    begin
      LogEnabled := False;
      Writeln('初始化日志文件失败: ', E.Message);
    end;
  end;
end;

procedure CloseLog;
begin
  if LogEnabled then
  begin
    try
      LogMessage('----------------------------------------');
      LogMessage('测试结束时间: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
      CloseFile(LogFile);
    except
      // 忽略日志关闭错误
    end;
  end;
end;

type
  TPerformanceStats = record
    TotalTime: Int64;
    Count: Integer;
    MinTime: Int64;
    MaxTime: Int64;
    AvgTime: Double;
    procedure AddSample(Time: Int64);
    procedure Reset;
    function ToString: string;
  end;

var
  DetectionStats: TPerformanceStats;
  ConversionStats: TPerformanceStats;

procedure TPerformanceStats.AddSample(Time: Int64);
begin
  if Count = 0 then
  begin
    MinTime := Time;
    MaxTime := Time;
  end
  else
  begin
    if Time < MinTime then MinTime := Time;
    if Time > MaxTime then MaxTime := Time;
  end;

  TotalTime := TotalTime + Time;
  Inc(Count);
  AvgTime := TotalTime / Count;
end;

procedure TPerformanceStats.Reset;
begin
  TotalTime := 0;
  Count := 0;
  MinTime := 0;
  MaxTime := 0;
  AvgTime := 0;
end;

function TPerformanceStats.ToString: string;
begin
  if Count = 0 then
    Result := '无性能数据'
  else
    Result := Format('总时间: %d ms, 平均时间: %.2f ms, 最小时间: %d ms, 最大时间: %d ms, 样本数: %d',
      [TotalTime, AvgTime, MinTime, MaxTime, Count]);
end;

procedure RunDetectionTest(const FileName: string);
var
  Result: TEncodingDetectionResult;
  StartTime, EndTime: TDateTime;
  ElapsedTime: Int64;
begin
  try
    StartTime := Now;
    Result := TEncodingUtils.DetectFileEncoding(FileName);
    EndTime := Now;
    ElapsedTime := MilliSecondsBetween(EndTime, StartTime);

    // 更新性能统计
    DetectionStats.AddSample(ElapsedTime);

    Writeln(Format('文件: %s', [ExtractFileName(FileName)]));
    Writeln(Format('编码: %s', [Result.Name]));
    Writeln(Format('置信度: %.2f', [Result.Confidence]));
    Writeln(Format('BOM: %s', [BoolToStr(Result.HasBOM, True)]));
    Writeln(Format('检测耗时: %d 毫秒', [ElapsedTime]));
    Writeln('');

    // 记录日志
    LogMessage(Format('检测文件: %s, 编码: %s, 置信度: %.2f, BOM: %s, 耗时: %d ms',
      [FileName, Result.Name, Result.Confidence, BoolToStr(Result.HasBOM, True), ElapsedTime]));
  except
    on E: Exception do
    begin
      Writeln('检测文件编码时出错: ', E.Message);
      LogMessage(Format('检测文件编码时出错: %s - %s', [FileName, E.Message]));
    end;
  end;
end;

procedure RunConversionTest(const SourceFile, TargetFile: string; TargetEncoding: TEncoding; WithBOM: Boolean);
var
  StartTime, EndTime: TDateTime;
  ElapsedTime: Int64;
  Success: Boolean;
  SourceSize, TargetSize: Int64;
  SourceInfo: TEncodingDetectionResult;
begin
  try
    // 获取源文件大小
    with TFileStream.Create(SourceFile, fmOpenRead or fmShareDenyNone) do
    try
      SourceSize := Size;
    finally
      Free;
    end;

    // 检测源文件编码
    SourceInfo := TEncodingUtils.DetectFileEncoding(SourceFile);

    // 执行转换
    StartTime := Now;
    Success := TEncodingUtils.ConvertFileEncoding(SourceFile, TargetFile, TargetEncoding, WithBOM);
    EndTime := Now;
    ElapsedTime := MilliSecondsBetween(EndTime, StartTime);

    // 更新性能统计
    ConversionStats.AddSample(ElapsedTime);

    // 获取目标文件大小
    if Success and FileExists(TargetFile) then
    begin
      with TFileStream.Create(TargetFile, fmOpenRead or fmShareDenyNone) do
      try
        TargetSize := Size;
      finally
        Free;
      end;
    end
    else
      TargetSize := 0;

    // 输出结果
    Writeln(Format('源文件: %s', [ExtractFileName(SourceFile)]));
    Writeln(Format('源编码: %s', [SourceInfo.Name]));
    Writeln(Format('源文件大小: %d 字节', [SourceSize]));
    Writeln(Format('目标文件: %s', [ExtractFileName(TargetFile)]));
    Writeln(Format('目标编码: %s', [TEncodingUtils.GetEncodingName(TargetEncoding)]));
    Writeln(Format('目标文件大小: %d 字节', [TargetSize]));
    Writeln(Format('添加BOM: %s', [BoolToStr(WithBOM, True)]));
    Writeln(Format('转换结果: %s', [BoolToStr(Success, True)]));
    Writeln(Format('转换耗时: %d 毫秒', [ElapsedTime]));
    Writeln('');

    // 记录日志
    LogMessage(Format('转换文件: %s -> %s, 源编码: %s, 目标编码: %s, BOM: %s, 结果: %s, 耗时: %d ms, 大小: %d -> %d 字节',
      [SourceFile, TargetFile, SourceInfo.Name, TEncodingUtils.GetEncodingName(TargetEncoding),
       BoolToStr(WithBOM, True), BoolToStr(Success, True), ElapsedTime, SourceSize, TargetSize]));
  except
    on E: Exception do
    begin
      Writeln('转换文件编码时出错: ', E.Message);
      LogMessage(Format('转换文件编码时出错: %s -> %s - %s', [SourceFile, TargetFile, E.Message]));
    end;
  end;
end;

procedure OutputPerformanceReport;
begin
  Writeln('');
  Writeln('性能统计报告');
  Writeln('============');
  Writeln('编码检测: ', DetectionStats.ToString);
  Writeln('编码转换: ', ConversionStats.ToString);
  Writeln('');

  LogMessage('性能统计报告');
  LogMessage('============');
  LogMessage('编码检测: ' + DetectionStats.ToString);
  LogMessage('编码转换: ' + ConversionStats.ToString);
end;

begin
  try
    // 初始化性能统计
    DetectionStats.Reset;
    ConversionStats.Reset;

    // 初始化日志
    InitializeLog;

    // 设置日志回调
    TEncodingUtils.SetLogCallback(LogMessage);

    // 启用缓存
    TEncodingUtils.EnableCache(True);

    // 解析命令行参数
    if ParamCount < 1 then
    begin
      Writeln('用法:');
      Writeln('  EncodingTestRunner detect <文件路径>');
      Writeln('  EncodingTestRunner convert <源文件> <目标文件> <目标编码> [添加BOM]');
      Writeln('  EncodingTestRunner batch <目录路径> <目标编码> [添加BOM]');
      Writeln('');
      Writeln('示例:');
      Writeln('  EncodingTestRunner detect test.txt');
      Writeln('  EncodingTestRunner convert source.txt target.txt utf-8 true');
      Writeln('  EncodingTestRunner batch ./testfiles utf-8 true');
      Exit;
    end;

    // 根据命令行参数确定测试模式
    if LowerCase(ParamStr(1)) = 'detect' then
    begin
      if ParamCount < 2 then
      begin
        Writeln('错误: 缺少文件路径参数');
        Exit;
      end;

      FileName := ParamStr(2);
      if not FileExists(FileName) then
      begin
        Writeln('错误: 文件不存在 - ', FileName);
        Exit;
      end;

      Writeln('开始检测文件编码...');
      Writeln('');
      RunDetectionTest(FileName);
    end
    else if LowerCase(ParamStr(1)) = 'convert' then
    begin
      if ParamCount < 4 then
      begin
        Writeln('错误: 缺少参数');
        Exit;
      end;

      FileName := ParamStr(2);
      if not FileExists(FileName) then
      begin
        Writeln('错误: 源文件不存在 - ', FileName);
        Exit;
      end;

      TargetFileName := ParamStr(3);

      try
        TargetEncoding := TEncodingUtils.StringToEncoding(ParamStr(4));
      except
        on E: Exception do
        begin
          Writeln('错误: 无效的目标编码 - ', ParamStr(4));
          Writeln(E.Message);
          Exit;
        end;
      end;

      WithBOM := True;
      if ParamCount >= 5 then
        WithBOM := StrToBoolDef(ParamStr(5), True);

      Writeln('开始转换文件编码...');
      Writeln('');
      RunConversionTest(FileName, TargetFileName, TargetEncoding, WithBOM);
    end
    else if LowerCase(ParamStr(1)) = 'batch' then
    begin
      if ParamCount < 3 then
      begin
        Writeln('错误: 缺少参数');
        Exit;
      end;

      var DirPath := ParamStr(2);
      if not DirectoryExists(DirPath) then
      begin
        Writeln('错误: 目录不存在 - ', DirPath);
        Exit;
      end;

      try
        TargetEncoding := TEncodingUtils.StringToEncoding(ParamStr(3));
      except
        on E: Exception do
        begin
          Writeln('错误: 无效的目标编码 - ', ParamStr(3));
          Writeln(E.Message);
          Exit;
        end;
      end;

      WithBOM := True;
      if ParamCount >= 4 then
        WithBOM := StrToBoolDef(ParamStr(4), True);

      // 获取目录中的所有文本文件
      TestFiles := TDirectory.GetFiles(DirPath, '*.txt;*.md;*.xml;*.html;*.json;*.js;*.css;*.pas;*.dpr', TSearchOption.soAllDirectories);

      Writeln('找到 ', Length(TestFiles), ' 个测试文件');
      Writeln('开始批量检测和转换...');
      Writeln('');

      for FileName in TestFiles do
      begin
        Writeln('处理文件: ', ExtractFileName(FileName));

        // 检测编码
        RunDetectionTest(FileName);

        // 转换编码
        TargetFileName := ChangeFileExt(FileName, '.converted' + ExtractFileExt(FileName));
        RunConversionTest(FileName, TargetFileName, TargetEncoding, WithBOM);

        Writeln('----------------------------------------');
      end;
    end
    else
    begin
      Writeln('错误: 无效的命令 - ', ParamStr(1));
      Writeln('有效的命令: detect, convert, batch');
    end;

    // 输出性能报告
    OutputPerformanceReport;

    // 清除缓存
    TEncodingUtils.ClearCache;

    // 关闭日志
    CloseLog;

    Writeln('测试完成，结果已记录到日志文件中');
    Writeln('按任意键退出...');
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
