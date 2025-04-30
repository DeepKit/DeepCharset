program TestCPUMonitorApp;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.IOUtils,
  EncodingCPUMonitor in 'EncodingCPUMonitor.pas';

procedure LogMessage(const Msg: string);
begin
  Writeln(Msg);
end;

procedure SimulateCPULoad(Duration: Integer);
var
  StartTime: TDateTime;
  X: Double;
  I: Integer;
begin
  StartTime := Now;
  
  Writeln(Format('模拟CPU负载: %d毫秒...', [Duration]));
  
  // 执行CPU密集型操作
  while MilliSecondsBetween(Now, StartTime) < Duration do
  begin
    // 执行一些计算
    for I := 1 to 1000000 do
    begin
      X := Sqrt(I) * Sin(I) * Cos(I);
      if X < 0 then
        X := -X;
    end;
  end;
end;

procedure RunCPUMonitorTest;
var
  Monitor: TEncodingCPUMonitor;
  I: Integer;
begin
  // 创建CPU监控器
  Monitor := TEncodingCPUMonitor.Create(LogMessage);
  try
    // 开始监控
    Writeln('开始CPU利用率监控...');
    Monitor.StartMonitoring(500); // 每500毫秒记录一次
    
    // 模拟不同的CPU负载
    for I := 1 to 5 do
    begin
      // 模拟低负载
      Sleep(1000);
      
      // 模拟中负载
      SimulateCPULoad(1000);
      
      // 模拟高负载
      SimulateCPULoad(2000);
      
      // 模拟空闲
      Sleep(1000);
    end;
    
    // 停止监控
    Monitor.StopMonitoring;
    Writeln('停止CPU利用率监控');
    
    // 生成报告
    Writeln('生成CPU利用率报告...');
    Monitor.SaveReportToFile('test\cpu_usage_report.md');
    
    Writeln('CPU利用率监控测试完成！');
  finally
    Monitor.Free;
  end;
end;

begin
  try
    Writeln('CPU利用率监控测试程序');
    Writeln('========================================');
    
    // 创建测试目录
    if not DirectoryExists('test') then
      ForceDirectories('test');
    
    // 运行CPU监控测试
    Writeln('是否运行CPU利用率监控测试？(Y/N)');
    if UpperCase(ReadLn) = 'Y' then
      RunCPUMonitorTest;
    
    Writeln('========================================');
    Writeln('按任意键退出...');
    Readln;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Readln;
    end;
  end;
end.
