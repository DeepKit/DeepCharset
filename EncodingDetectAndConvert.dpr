program EncodingDetectAndConvert;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Diagnostics,
  System.IOUtils,
  UtilsEncodingDetect2,
  UtilsEncodingConverter;

var
  Command: string;
  SourceFile, TargetFile, EncodingName: string;
  Detector: TEncodingDetector2;
  Converter: TEncodingConverter;
  Result: TEncodingDetectionResult;
  ConvResult: TEncodingConversionResult;
  TargetEncoding: TEncoding;
  i: Integer;
  StartTime: TStopwatch;
  ElapsedMs: Int64;

// 显示帮助信息
procedure ShowHelp;
begin
  Writeln('编码检测与转换工具');
  Writeln('-------------------');
  Writeln('用法:');
  Writeln('  detect <文件路径>                   - 检测文件编码');
  Writeln('  detect <目录路径>                   - 检测目录中所有文件编码');
  Writeln('  convert <源文件> <目标文件> [编码]   - 转换文件编码');
  Writeln('  convertdir <源目录> <目标目录> [编码] - 转换目录中所有文件编码');
  Writeln('  list                               - 列出支持的编码');
  Writeln('  help                               - 显示此帮助');
  Writeln('');
  Writeln('示例:');
  Writeln('  detect sample.txt                  - 检测sample.txt的编码');
  Writeln('  convert source.txt target.txt utf-8 - 将source.txt转换为UTF-8编码并保存为target.txt');
  Writeln('  convert source.txt target.txt      - 默认转换为UTF-8编码');
  Writeln('  convertdir c:\source d:\target utf-8 - 将c:\source目录下所有文件转换为UTF-8编码并保存至d:\target');
end;

// 列出支持的编码
procedure ListEncodings;
var
  Names: TArray<string>;
begin
  Writeln('支持的编码:');
  Writeln('----------');
  
  Names := TEncodingDetector2.GetSupportedEncodingNames;
  for i := 0 to High(Names) do
    Writeln(Format('  %s', [Names[i]]));
    
  Writeln('');
  Writeln('注意: 转换时可以指定以上任一编码名称（不区分大小写）');
end;

// 检测单个文件编码
procedure DetectFile(const FileName: string);
begin
  if not FileExists(FileName) then
  begin
    Writeln(Format('错误: 文件不存在 - %s', [FileName]));
    Exit;
  end;
  
  StartTime := TStopwatch.StartNew;
  Result := Detector.DetectFileEncoding(FileName);
  ElapsedMs := StartTime.ElapsedMilliseconds;
  
  Writeln(Format('文件: %s', [FileName]));
  Writeln(Format('编码: %s', [Result.EncodingName]));
  Writeln(Format('置信度: %.1f%%', [Result.Confidence * 100]));
  Writeln(Format('BOM: %s', [BoolToStr(Result.HasBOM, True)]));
  if Result.LanguageHint <> '' then
    Writeln(Format('语言: %s', [Result.LanguageHint]));
  if Result.Description <> '' then
    Writeln(Format('描述: %s', [Result.Description]));
  Writeln(Format('检测方法: %s', [Result.DetectionMethod]));
  Writeln(Format('耗时: %d ms', [ElapsedMs]));
  Writeln('');
end;

// 检测目录中所有文件编码
procedure DetectDirectory(const DirPath: string);
var
  Files: TArray<string>;
  TotalFiles, DetectedFiles: Integer;
begin
  if not DirectoryExists(DirPath) then
  begin
    Writeln(Format('错误: 目录不存在 - %s', [DirPath]));
    Exit;
  end;
  
  Writeln(Format('正在扫描目录: %s', [DirPath]));
  Files := TDirectory.GetFiles(DirPath, '*.*', TSearchOption.soAllDirectories);
  TotalFiles := Length(Files);
  DetectedFiles := 0;
  
  Writeln(Format('找到 %d 个文件', [TotalFiles]));
  Writeln('');
  
  for i := 0 to TotalFiles - 1 do
  begin
    try
      Result := Detector.DetectFileEncoding(Files[i]);
      Inc(DetectedFiles);
      
      Writeln(Format('[%d/%d] %s', [i+1, TotalFiles, ExtractFileName(Files[i])]));
      Writeln(Format('  编码: %s (%.1f%% 置信度)%s', 
        [Result.EncodingName, Result.Confidence * 100, 
         IfThen(Result.HasBOM, ' [BOM]', '')]));
      if Result.LanguageHint <> '' then
        Writeln(Format('  语言: %s', [Result.LanguageHint]));
    except
      on E: Exception do
        Writeln(Format('[%d/%d] %s - 错误: %s', 
          [i+1, TotalFiles, ExtractFileName(Files[i]), E.Message]));
    end;
  end;
  
  Writeln('');
  Writeln(Format('成功检测 %d/%d 个文件', [DetectedFiles, TotalFiles]));
end;

// 转换文件编码
procedure ConvertFile(const SourcePath, TargetPath, Encoding: string);
begin
  if not FileExists(SourcePath) then
  begin
    Writeln(Format('错误: 源文件不存在 - %s', [SourcePath]));
    Exit;
  end;
  
  // 决定目标编码
  if Encoding <> '' then
    TargetEncoding := TEncodingDetector2.GetEncodingByName(Encoding)
  else
    TargetEncoding := TEncoding.UTF8;
    
  if TargetEncoding = nil then
  begin
    Writeln(Format('错误: 无效的编码名称 - %s', [Encoding]));
    Exit;
  end;
  
  Writeln(Format('正在转换文件: %s', [SourcePath]));
  Writeln(Format('目标编码: %s%s', 
    [TEncodingDetector2.GetEncodingFriendlyName(TargetEncoding),
     IfThen(Converter.Options.AddBOM, ' (带BOM)', '')]));
  
  StartTime := TStopwatch.StartNew;
  
  // 设置进度回调
  Converter.ProgressCallback := 
    procedure(const FileName: string; Position, Total: Int64; var Cancel: Boolean)
    begin
      if Total > 0 then
        Write(#13 + Format('进度: %.1f%%', [(Position / Total) * 100]))
      else
        Write(#13 + Format('进度: 已处理 %d 字节', [Position]));
    end;
  
  // 执行转换
  ConvResult := Converter.ConvertFile(SourcePath, TargetPath, nil, TargetEncoding);
  ElapsedMs := StartTime.ElapsedMilliseconds;
  
  Writeln('');
  if ConvResult.Success then
  begin
    Writeln('转换成功!');
    Writeln(Format('源文件大小: %d 字节', [ConvResult.SourceSize]));
    Writeln(Format('目标文件大小: %d 字节', [ConvResult.TargetSize]));
    Writeln(Format('源编码: %s', [TEncodingDetector2.GetEncodingFriendlyName(ConvResult.SourceEncoding)]));
    Writeln(Format('目标编码: %s', [TEncodingDetector2.GetEncodingFriendlyName(ConvResult.TargetEncoding)]));
    Writeln(Format('耗时: %d ms', [ElapsedMs]));
  end
  else
  begin
    Writeln('转换失败!');
    Writeln(Format('错误: %s', [ConvResult.ErrorMessage]));
  end;
end;

// 转换目录中所有文件编码
procedure ConvertDirectory(const SourceDir, TargetDir, Encoding: string);
var
  Files: TArray<string>;
  SuccessCount: Integer;
begin
  if not DirectoryExists(SourceDir) then
  begin
    Writeln(Format('错误: 源目录不存在 - %s', [SourceDir]));
    Exit;
  end;
  
  // 决定目标编码
  if Encoding <> '' then
    TargetEncoding := TEncodingDetector2.GetEncodingByName(Encoding)
  else
    TargetEncoding := TEncoding.UTF8;
    
  if TargetEncoding = nil then
  begin
    Writeln(Format('错误: 无效的编码名称 - %s', [Encoding]));
    Exit;
  end;
  
  Writeln(Format('正在扫描源目录: %s', [SourceDir]));
  Files := TDirectory.GetFiles(SourceDir, '*.*', TSearchOption.soAllDirectories);
  Writeln(Format('找到 %d 个文件', [Length(Files)]));
  Writeln(Format('目标目录: %s', [TargetDir]));
  Writeln(Format('目标编码: %s%s', 
    [TEncodingDetector2.GetEncodingFriendlyName(TargetEncoding),
     IfThen(Converter.Options.AddBOM, ' (带BOM)', '')]));
  
  // 设置进度回调
  Converter.ProgressCallback := 
    procedure(const FileName: string; Position, Total: Int64; var Cancel: Boolean)
    begin
      if FileName <> '' then
        Writeln(FileName);
    end;
  
  // 执行批量转换
  StartTime := TStopwatch.StartNew;
  SuccessCount := Converter.ConvertFiles(Files, TargetDir, TargetEncoding);
  ElapsedMs := StartTime.ElapsedMilliseconds;
  
  Writeln('');
  Writeln(Format('转换完成: %d/%d 个文件成功', [SuccessCount, Length(Files)]));
  Writeln(Format('总耗时: %d ms', [ElapsedMs]));
end;

begin
  try
    // 初始化检测器和转换器
    Detector := TEncodingDetector2.Create;
    Converter := TEncodingConverter.Create;
    
    try
      // 设置一些选项
      Detector.Options.EnableChineseDetection := True;
      Converter.Options.AddBOM := True;
      Converter.Options.AutoDetectSource := True;
      Converter.Options.MinConfidence := 0.6;
      Converter.Options.OverwriteTarget := True;
      
      // 解析命令行参数
      if ParamCount < 1 then
      begin
        ShowHelp;
        Exit;
      end;
      
      Command := LowerCase(ParamStr(1));
      
      // 处理各种命令
      if Command = 'help' then
      begin
        ShowHelp;
      end
      else if Command = 'list' then
      begin
        ListEncodings;
      end
      else if Command = 'detect' then
      begin
        if ParamCount < 2 then
        begin
          Writeln('错误: 缺少文件或目录路径参数');
          Exit;
        end;
        
        SourceFile := ParamStr(2);
        
        if DirectoryExists(SourceFile) then
          DetectDirectory(SourceFile)
        else
          DetectFile(SourceFile);
      end
      else if Command = 'convert' then
      begin
        if ParamCount < 3 then
        begin
          Writeln('错误: 缺少源文件或目标文件参数');
          Exit;
        end;
        
        SourceFile := ParamStr(2);
        TargetFile := ParamStr(3);
        
        if ParamCount >= 4 then
          EncodingName := ParamStr(4)
        else
          EncodingName := '';
          
        ConvertFile(SourceFile, TargetFile, EncodingName);
      end
      else if Command = 'convertdir' then
      begin
        if ParamCount < 3 then
        begin
          Writeln('错误: 缺少源目录或目标目录参数');
          Exit;
        end;
        
        SourceFile := ParamStr(2);
        TargetFile := ParamStr(3);
        
        if ParamCount >= 4 then
          EncodingName := ParamStr(4)
        else
          EncodingName := '';
          
        ConvertDirectory(SourceFile, TargetFile, EncodingName);
      end
      else
      begin
        Writeln(Format('错误: 未知命令 - %s', [Command]));
        Writeln('');
        ShowHelp;
      end;
    finally
      Detector.Free;
      Converter.Free;
    end;
  except
    on E: Exception do
      Writeln(Format('错误: %s', [E.Message]));
  end;
  
  // 等待按键退出
  Writeln('');
  Write('按任意键退出...');
  Readln;
end. 