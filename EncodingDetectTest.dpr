program EncodingDetectTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Diagnostics,
  System.JSON,
  UtilsEncodingDetect2;

var
  Params: TStringList;
  FileName: string;
  UseJson: Boolean;
  EncodingDetector: TEncodingDetector2;
  Result: TEncodingDetectionResult;
  StopWatch: TStopwatch;
  ElapsedTime: Int64;
  JsonOutput: TJSONObject;
  i: Integer;

begin
  try
    // 初始化参数
    Params := TStringList.Create;
    try
      for i := 1 to ParamCount do
        Params.Add(ParamStr(i));
      
      // 检查是否要使用JSON输出
      UseJson := (Params.IndexOf('--json') >= 0) or (Params.IndexOf('-j') >= 0);
      
      // 从参数中获取文件名
      FileName := '';
      for i := 0 to Params.Count - 1 do
      begin
        if not (Params[i].StartsWith('-')) and FileExists(Params[i]) then
        begin
          FileName := Params[i];
          Break;
        end;
      end;
      
      // 如果没有找到有效文件名，提示并退出
      if FileName = '' then
      begin
        if UseJson then
        begin
          JsonOutput := TJSONObject.Create;
          try
            JsonOutput.AddPair('success', TJSONBool.Create(False));
            JsonOutput.AddPair('error', '未指定有效的文件路径');
            Writeln(JsonOutput.ToJSON);
          finally
            JsonOutput.Free;
          end;
        end
        else
        begin
          Writeln('用法: EncodingDetectTest <文件路径> [--json|-j]');
          Writeln('选项:');
          Writeln('  --json, -j  以JSON格式输出结果');
          Writeln('示例:');
          Writeln('  EncodingDetectTest sample.txt');
          Writeln('  EncodingDetectTest sample.txt --json');
        end;
        
        Exit;
      end;
    finally
      Params.Free;
    end;

    // 创建编码检测器
    EncodingDetector := TEncodingDetector2.Create;
    
    try
      // 检测文件编码
      if not UseJson then
        Writeln('正在检测文件编码: ', FileName);
      
      // 使用计时器测量性能
      StopWatch := TStopwatch.StartNew;
      Result := EncodingDetector.DetectFileEncoding(FileName);
      StopWatch.Stop;
      ElapsedTime := StopWatch.ElapsedMilliseconds;
      
      // 输出结果
      if UseJson then
      begin
        JsonOutput := TJSONObject.Create;
        try
          JsonOutput.AddPair('success', TJSONBool.Create(True));
          JsonOutput.AddPair('encoding', Result.EncodingName);
          JsonOutput.AddPair('confidence', TJSONNumber.Create(Result.Confidence));
          JsonOutput.AddPair('has_bom', TJSONBool.Create(Result.HasBOM));
          if Result.Description <> '' then
            JsonOutput.AddPair('description', Result.Description);
          JsonOutput.AddPair('elapsed_ms', TJSONNumber.Create(ElapsedTime));
          
          Writeln(JsonOutput.ToJSON);
        finally
          JsonOutput.Free;
        end;
      end
      else
      begin
        Writeln('Encoding: ', Result.EncodingName);
        Writeln('Confidence: ', Result.Confidence * 100, '%');
        Writeln('Has BOM: ', BoolToStr(Result.HasBOM, True));
        if Result.Description <> '' then
          Writeln('Description: ', Result.Description);
        Writeln('Time: ', ElapsedTime, 'ms');
      end;
    finally
      EncodingDetector.Free;
    end;
  except
    on E: Exception do
    begin
      if UseJson then
      begin
        JsonOutput := TJSONObject.Create;
        try
          JsonOutput.AddPair('success', TJSONBool.Create(False));
          JsonOutput.AddPair('error', E.Message);
          Writeln(JsonOutput.ToJSON);
        finally
          JsonOutput.Free;
        end;
      end
      else
        Writeln(E.ClassName, ': ', E.Message);
    end;
  end;
end.