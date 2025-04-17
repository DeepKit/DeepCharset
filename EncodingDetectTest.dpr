program EncodingDetectTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Diagnostics,
  UtilsEncodingDetect in 'UtilsEncodingDetect.pas';

const
  TEST_FILES_DIR = 'TestFiles';
  
var
  Detector: TEncodingDetector;
  Files: TArray<string>;
  FileName: string;
  Result: TEncodingDetectResult;
  StopWatch: TStopwatch;
  TotalTime: Int64;
  SuccessCount: Integer;
  
procedure LogMessage(const Msg: string);
begin
  WriteLn(Msg);
end;

begin
  try
    WriteLn('===== 编码检测优化测试程序 =====');
    WriteLn('测试目标: 优化无BOM文件的检测算法，特别是亚洲语言编码');
    WriteLn;
    
    // 创建编码检测器
    Detector := TEncodingDetector.Create(LogMessage);
    try
      // 启用性能日志
      Detector.PerformanceLog := True;
      
      // 获取测试文件列表
      if DirectoryExists(TEST_FILES_DIR) then
        Files := TDirectory.GetFiles(TEST_FILES_DIR)
      else
      begin
        WriteLn('错误: 测试文件目录不存在: ', TEST_FILES_DIR);
        Exit;
      end;
      
      WriteLn(Format('找到 %d 个测试文件', [Length(Files)]));
      WriteLn;
      WriteLn('开始测试...');
      WriteLn('--------------------------------------------');
      
      // 开始计时
      StopWatch := TStopwatch.StartNew;
      TotalTime := 0;
      SuccessCount := 0;
      
      // 测试每个文件
      for FileName in Files do
      begin
        // 跳过非文本文件
        if not SameText(ExtractFileExt(FileName), '.txt') and
           not SameText(ExtractFileExt(FileName), '.md') and
           not SameText(ExtractFileExt(FileName), '.pas') and
           not SameText(ExtractFileExt(FileName), '.dpr') and
           not SameText(ExtractFileExt(FileName), '.java') and
           not SameText(ExtractFileExt(FileName), '.js') and
           not SameText(ExtractFileExt(FileName), '.html') and
           not SameText(ExtractFileExt(FileName), '.xml') and
           not SameText(ExtractFileExt(FileName), '.json') and
           not SameText(ExtractFileExt(FileName), '.css') then
          Continue;
        
        WriteLn('测试文件: ', ExtractFileName(FileName));
        
        // 检测文件编码
        Result := Detector.DetectFileEncoding(FileName);
        
        // 输出结果
        WriteLn(Format('  检测结果: %s (置信度: %d%%, 耗时: %d ms)', 
                      [Result.EncodingName, Result.Confidence, Result.ProcessTimeMs]));
        WriteLn(Format('  BOM: %s', [BoolToStr(Result.HasBOM, True)]));
        
        // 统计
        Inc(TotalTime, Result.ProcessTimeMs);
        if Result.Confidence >= 70 then
          Inc(SuccessCount);
          
        WriteLn('--------------------------------------------');
      end;
      
      // 停止计时
      StopWatch.Stop;
      
      // 输出统计信息
      WriteLn;
      WriteLn('===== 测试统计 =====');
      WriteLn(Format('总文件数: %d', [Length(Files)]));
      WriteLn(Format('成功检测数 (置信度>=70%%): %d (%.1f%%)', 
                    [SuccessCount, (SuccessCount / Length(Files)) * 100]));
      WriteLn(Format('总耗时: %d ms', [StopWatch.ElapsedMilliseconds]));
      WriteLn(Format('平均每文件耗时: %.2f ms', [TotalTime / Length(Files)]));
      WriteLn;
      WriteLn('测试完成!');
    finally
      Detector.Free;
    end;
    
    // 等待用户按键退出
    WriteLn('按任意键退出...');
    ReadLn;
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      ReadLn;
    end;
  end;
end.