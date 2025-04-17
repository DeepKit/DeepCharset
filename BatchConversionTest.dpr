program BatchConversionTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Diagnostics,
  ModelEncoding in 'ModelEncoding.pas',
  UtilsEncodingDetect in 'UtilsEncodingDetect.pas',
  ControllerEncodingOptimized in 'ControllerEncodingOptimized.pas';

const
  TEST_FOLDER = 'TestFiles';
  
var
  Controller: TEncodingControllerOptimized;
  Config: TBatchConversionConfig;
  ConfigNames: TArray<string>;
  FolderPath: string;
  FileExtensions: TArray<string>;
  TargetEncoding: string;
  AddBOM: Boolean;
  IncludeSubdirs: Boolean;
  Command: string;
  
procedure LogMessage(const Msg: string);
begin
  WriteLn(Msg);
end;

procedure UpdateProgress(const FileName: string; Current, Total: Integer);
begin
  Write(#13, Format('处理文件: %s (%d/%d)', [FileName, Current, Total]));
end;

procedure ShowHelp;
begin
  WriteLn('批量编码转换测试程序 - 命令列表:');
  WriteLn('  detect <文件路径>       - 检测指定文件的编码');
  WriteLn('  convert <文件路径> <目标编码> [BOM]  - 转换单个文件编码');
  WriteLn('  batch <文件夹> <目标编码> [BOM] [子目录]  - 批量转换文件夹中的文件');
  WriteLn('  saveconfig <配置名>  - 保存当前批量转换配置');
  WriteLn('  loadconfig <配置名>  - 加载批量转换配置');
  WriteLn('  listconfigs          - 列出所有保存的配置');
  WriteLn('  testspecial          - 测试特殊场景（混合编码、损坏文件等）');
  WriteLn('  report <文件夹> <报告文件>  - 生成文件夹编码分析报告');
  WriteLn('  exit                 - 退出程序');
  WriteLn;
  WriteLn('支持的编码:');
  WriteLn('  UTF-8, UTF-8 with BOM, GBK, Big5, Shift-JIS, EUC-JP, EUC-KR, ASCII, ANSI');
  WriteLn;
end;

begin
  try
    WriteLn('===== 批量编码转换测试程序 =====');
    WriteLn('用于测试优化后的编码检测和批量转换功能');
    WriteLn;
    
    // 创建编码控制器
    Controller := TEncodingControllerOptimized.Create(LogMessage);
    try
      // 设置默认值
      FolderPath := TEST_FOLDER;
      FileExtensions := ['.txt', '.pas', '.dpr', '.dfm', '.java', '.js', '.html', '.xml', '.json', '.css'];
      TargetEncoding := 'UTF-8 with BOM';
      AddBOM := True;
      IncludeSubdirs := False;
      
      // 显示帮助信息
      ShowHelp;
      
      // 命令行循环
      while True do
      begin
        Write('> ');
        ReadLn(Command);
        Command := LowerCase(Trim(Command));
        
        if Command = 'exit' then
          Break
        else if Command = 'help' then
          ShowHelp
        else if StartsText('detect ', Command) then
        begin
          var FilePath := Trim(Copy(Command, 8, MaxInt));
          if FileExists(FilePath) then
          begin
            var EncodingName: string;
            if Controller.DetectFileEncoding(FilePath, EncodingName) then
              WriteLn(Format('文件编码: %s, BOM: %s', [EncodingName, BoolToStr(Controller.HasBOM(FilePath), True)]))
            else
              WriteLn('无法检测文件编码');
          end
          else
            WriteLn('文件不存在: ' + FilePath);
        end
        else if StartsText('convert ', Command) then
        begin
          var Params := TStringList.Create;
          try
            // 解析参数
            var ParamStr := Trim(Copy(Command, 9, MaxInt));
            var StartPos := 1;
            var InQuote := False;
            var Param := '';
            
            for var i := 1 to Length(ParamStr) do
            begin
              if ParamStr[i] = '"' then
                InQuote := not InQuote
              else if (ParamStr[i] = ' ') and not InQuote then
              begin
                if i > StartPos then
                begin
                  Param := Trim(Copy(ParamStr, StartPos, i - StartPos));
                  if (Length(Param) >= 2) and (Param[1] = '"') and (Param[Length(Param)] = '"') then
                    Param := Copy(Param, 2, Length(Param) - 2);
                  Params.Add(Param);
                end;
                StartPos := i + 1;
              end;
            end;
            
            if StartPos <= Length(ParamStr) then
            begin
              Param := Trim(Copy(ParamStr, StartPos, MaxInt));
              if (Length(Param) >= 2) and (Param[1] = '"') and (Param[Length(Param)] = '"') then
                Param := Copy(Param, 2, Length(Param) - 2);
              Params.Add(Param);
            end;
            
            // 执行转换
            if Params.Count >= 2 then
            begin
              var FilePath := Params[0];
              var TargetEnc := Params[1];
              var UseBOM := (Params.Count >= 3) and SameText(Params[2], 'true');
              
              if FileExists(FilePath) then
              begin
                var Result := Controller.ConvertFileEncoding(FilePath, '', TargetEnc, UseBOM);
                case Result of
                  crSuccess: WriteLn('转换成功');
                  crSkipped: WriteLn('跳过转换');
                  crFailed: WriteLn('转换失败');
                end;
              end
              else
                WriteLn('文件不存在: ' + FilePath);
            end
            else
              WriteLn('参数不足. 用法: convert <文件路径> <目标编码> [BOM]');
          finally
            Params.Free;
          end;
        end
        else if StartsText('batch ', Command) then
        begin
          var Params := TStringList.Create;
          try
            // 解析参数
            var ParamStr := Trim(Copy(Command, 7, MaxInt));
            var StartPos := 1;
            var InQuote := False;
            var Param := '';
            
            for var i := 1 to Length(ParamStr) do
            begin
              if ParamStr[i] = '"' then
                InQuote := not InQuote
              else if (ParamStr[i] = ' ') and not InQuote then
              begin
                if i > StartPos then
                begin
                  Param := Trim(Copy(ParamStr, StartPos, i - StartPos));
                  if (Length(Param) >= 2) and (Param[1] = '"') and (Param[Length(Param)] = '"') then
                    Param := Copy(Param, 2, Length(Param) - 2);
                  Params.Add(Param);
                end;
                StartPos := i + 1;
              end;
            end;
            
            if StartPos <= Length(ParamStr) then
            begin
              Param := Trim(Copy(ParamStr, StartPos, MaxInt));
              if (Length(Param) >= 2) and (Param[1] = '"') and (Param[Length(Param)] = '"') then
                Param := Copy(Param, 2, Length(Param) - 2);
              Params.Add(Param);
            end;
            
            // 执行批量转换
            if Params.Count >= 2 then
            begin
              var Folder := Params[0];
              var TargetEnc := Params[1];
              var UseBOM := (Params.Count >= 3) and SameText(Params[2], 'true');
              var UseSubdirs := (Params.Count >= 4) and SameText(Params[3], 'true');
              
              if DirectoryExists(Folder) then
              begin
                WriteLn(Format('开始批量转换文件夹: %s', [Folder]));
                WriteLn(Format('目标编码: %s, BOM: %s, 包含子目录: %s', 
                              [TargetEnc, BoolToStr(UseBOM, True), BoolToStr(UseSubdirs, True)]));
                
                // 保存当前设置到配置
                FolderPath := Folder;
                TargetEncoding := TargetEnc;
                AddBOM := UseBOM;
                IncludeSubdirs := UseSubdirs;
                
                // 执行批量转换
                Controller.ConvertFilesToEncoding(Folder, FileExtensions, UseSubdirs, 
                                                 TargetEnc, UseBOM, UpdateProgress);
                WriteLn;
                WriteLn('批量转换完成');
              end
              else
                WriteLn('文件夹不存在: ' + Folder);
            end
            else
              WriteLn('参数不足. 用法: batch <文件夹> <目标编码> [BOM] [子目录]');
          finally
            Params.Free;
          end;
        end
        else if StartsText('saveconfig ', Command) then
        begin
          var ConfigName := Trim(Copy(Command, 12, MaxInt));
          if ConfigName <> '' then
          begin
            // 创建配置
            Config.Name := ConfigName;
            Config.TargetEncoding := TargetEncoding;
            Config.AddBOM := AddBOM;
            Config.IncludeSubdirs := IncludeSubdirs;
            Config.FileExtensions := FileExtensions;
            
            // 保存配置
            Controller.SaveConversionConfig(ConfigName, Config);
            WriteLn('配置已保存: ' + ConfigName);
          end
          else
            WriteLn('请指定配置名称');
        end
        else if StartsText('loadconfig ', Command) then
        begin
          var ConfigName := Trim(Copy(Command, 12, MaxInt));
          if ConfigName <> '' then
          begin
            if Controller.LoadConversionConfig(ConfigName, Config) then
            begin
              // 应用配置
              TargetEncoding := Config.TargetEncoding;
              AddBOM := Config.AddBOM;
              IncludeSubdirs := Config.IncludeSubdirs;
              FileExtensions := Config.FileExtensions;
              
              WriteLn('配置已加载: ' + ConfigName);
              WriteLn(Format('目标编码: %s, BOM: %s, 包含子目录: %s', 
                            [TargetEncoding, BoolToStr(AddBOM, True), BoolToStr(IncludeSubdirs, True)]));
              
              Write('文件扩展名: ');
              for var i := 0 to High(FileExtensions) do
              begin
                if i > 0 then
                  Write(', ');
                Write(FileExtensions[i]);
              end;
              WriteLn;
            end
            else
              WriteLn('配置不存在: ' + ConfigName);
          end
          else
            WriteLn('请指定配置名称');
        end
        else if Command = 'listconfigs' then
        begin
          ConfigNames := Controller.GetAllConfigNames;
          if Length(ConfigNames) > 0 then
          begin
            WriteLn('保存的配置:');
            for var ConfigName in ConfigNames do
              WriteLn('  ' + ConfigName);
          end
          else
            WriteLn('没有保存的配置');
        end
        else if Command = 'testspecial' then
        begin
          WriteLn('开始测试特殊场景...');
          WriteLn('1. 测试混合编码文件处理');
          
          // 创建测试目录
          var TestDir := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'SpecialTest');
          if not DirectoryExists(TestDir) then
            CreateDir(TestDir);
            
          // 创建混合编码模拟文件
          var MixedFile := TPath.Combine(TestDir, 'mixed_encoding.txt');
          var Stream := TFileStream.Create(MixedFile, fmCreate);
          try
            // 写入UTF-8部分
            var UTF8Text := '这是UTF-8编码部分';
            var UTF8Bytes := TEncoding.UTF8.GetBytes(UTF8Text);
            Stream.WriteBuffer(UTF8Bytes[0], Length(UTF8Bytes));
            
            // 写入GBK部分
            var GBKText := '这是GBK编码部分';
            var GBKBytes := TEncoding.GetEncoding(936).GetBytes(GBKText);
            Stream.WriteBuffer(GBKBytes[0], Length(GBKBytes));
          finally
            Stream.Free;
          end;
          
          // 创建损坏的UTF-8文件
          var CorruptedFile := TPath.Combine(TestDir, 'corrupted_utf8.txt');
          Stream := TFileStream.Create(CorruptedFile, fmCreate);
          try
            // 写入有效UTF-8
            var ValidText := '有效的UTF-8文本';
            var ValidBytes := TEncoding.UTF8.GetBytes(ValidText);
            Stream.WriteBuffer(ValidBytes[0], Length(ValidBytes));
            
            // 写入无效UTF-8序列
            var InvalidBytes: TBytes;
            SetLength(InvalidBytes, 3);
            InvalidBytes[0] := $E0; // 开始一个3字节UTF-8序列
            InvalidBytes[1] := $80; // 有效的后续字节
            InvalidBytes[2] := $20; // 无效的后续字节（应该是10xxxxxx模式）
            Stream.WriteBuffer(InvalidBytes[0], Length(InvalidBytes));
            
            // 再写入有效UTF-8
            ValidText := '后面的有效UTF-8文本';
            ValidBytes := TEncoding.UTF8.GetBytes(ValidText);
            Stream.WriteBuffer(ValidBytes[0], Length(ValidBytes));
          finally
            Stream.Free;
          end;
          
          // 测试处理混合编码文件
          WriteLn('检测混合编码文件: ', MixedFile);
          var EncodingName: string;
          if Controller.DetectFileEncoding(MixedFile, EncodingName) then
            WriteLn('  检测到编码: ', EncodingName)
          else
            WriteLn('  无法确定编码');
            
          WriteLn('尝试转换混合编码文件到UTF-8...');
          var Result := Controller.ConvertFileEncoding(MixedFile, '', 'UTF-8 with BOM', True);
          case Result of
            crSuccess: WriteLn('  转换成功');
            crSkipped: WriteLn('  跳过转换');
            crFailed: WriteLn('  转换失败');
          end;
          
          // 测试处理损坏的UTF-8文件
          WriteLn('检测损坏的UTF-8文件: ', CorruptedFile);
          if Controller.DetectFileEncoding(CorruptedFile, EncodingName) then
            WriteLn('  检测到编码: ', EncodingName)
          else
            WriteLn('  无法确定编码');
            
          WriteLn('尝试修复并转换损坏的UTF-8文件...');
          Result := Controller.ConvertFileEncoding(CorruptedFile, '', 'UTF-8 with BOM', True);
          case Result of
            crSuccess: WriteLn('  转换成功');
            crSkipped: WriteLn('  跳过转换');
            crFailed: WriteLn('  转换失败');
          end;
          
          WriteLn('特殊场景测试完成');
        end
        else if StartsText('report ', Command) then
        begin
          var Params := TStringList.Create;
          try
            // 解析参数
            var ParamStr := Trim(Copy(Command, 8, MaxInt));
            var StartPos := 1;
            var InQuote := False;
            var Param := '';
            
            for var i := 1 to Length(ParamStr) do
            begin
              if ParamStr[i] = '"' then
                InQuote := not InQuote
              else if (ParamStr[i] = ' ') and not InQuote then
              begin
                if i > StartPos then
                begin
                  Param := Trim(Copy(ParamStr, StartPos, i - StartPos));
                  if (Length(Param) >= 2) and (Param[1] = '"') and (Param[Length(Param)] = '"') then
                    Param := Copy(Param, 2, Length(Param) - 2);
                  Params.Add(Param);
                end;
                StartPos := i + 1;
              end;
            end;
            
            if StartPos <= Length(ParamStr) then
            begin
              Param := Trim(Copy(ParamStr, StartPos, MaxInt));
              if (Length(Param) >= 2) and (Param[1] = '"') and (Param[Length(Param)] = '"') then
                Param := Copy(Param, 2, Length(Param) - 2);
              Params.Add(Param);
            end;
            
            // 生成报告
            if Params.Count >= 2 then
            begin
              var FolderPath := Params[0];
              var ReportFile := Params[1];
              
              if DirectoryExists(FolderPath) then
              begin
                WriteLn('开始分析文件夹: ', FolderPath);
                WriteLn('生成报告文件: ', ReportFile);
                
                // 获取所有文件
                var Files := TDirectory.GetFiles(FolderPath, '*.*', TSearchOption.soAllDirectories);
                WriteLn('找到 ', Length(Files), ' 个文件');
                
                // 创建报告文件
                var Report := TStringList.Create;
                try
                  Report.Add('# 文件编码分析报告');
                  Report.Add('生成时间: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
                  Report.Add('分析目录: ' + FolderPath);
                  Report.Add('文件总数: ' + IntToStr(Length(Files)));
                  Report.Add('');
                  Report.Add('## 编码分布统计');
                  
                  // 统计各种编码的数量
                  var EncodingStats := TDictionary<string, Integer>.Create;
                  try
                    var ProcessedCount := 0;
                    var FailedCount := 0;
                    
                    for var i := 0 to High(Files) do
                    begin
                      var FileName := Files[i];
                      var EncodingName: string;
                      
                      Write(#13, Format('分析文件: %d/%d', [i+1, Length(Files)]));
                      
                      if Controller.DetectFileEncoding(FileName, EncodingName) then
                      begin
                        Inc(ProcessedCount);
                        
                        // 添加BOM信息
                        if Controller.HasBOM(FileName) then
                          EncodingName := EncodingName + ' with BOM';
                          
                        // 更新统计
                        if EncodingStats.ContainsKey(EncodingName) then
                          EncodingStats[EncodingName] := EncodingStats[EncodingName] + 1
                        else
                          EncodingStats.Add(EncodingName, 1);
                      end
                      else
                        Inc(FailedCount);
                    end;
                    
                    WriteLn;
                    WriteLn('分析完成, 成功: ', ProcessedCount, ', 失败: ', FailedCount);
                    
                    // 添加统计到报告
                    Report.Add('| 编码类型 | 文件数量 | 百分比 |');
                    Report.Add('|---------|----------|--------|');
                    
                    var EncodingList := TList<string>.Create;
                    try
                      for var Encoding in EncodingStats.Keys do
                        EncodingList.Add(Encoding);
                        
                      // 按数量排序
                      EncodingList.Sort(TComparer<string>.Construct(
                        function(const Left, Right: string): Integer
                        begin
                          Result := -CompareValue(EncodingStats[Left], EncodingStats[Right]);
                        end));
                      
                      // 添加到报告
                      for var Encoding in EncodingList do
                      begin
                        var Count := EncodingStats[Encoding];
                        var Percent := (Count / ProcessedCount) * 100;
                        Report.Add(Format('| %s | %d | %.2f%% |', [Encoding, Count, Percent]));
                      end;
                    finally
                      EncodingList.Free;
                    end;
                    
                    // 保存报告
                    Report.SaveToFile(ReportFile, TEncoding.UTF8);
                    WriteLn('报告已保存到: ', ReportFile);
                  finally
                    EncodingStats.Free;
                  end;
                finally
                  Report.Free;
                end;
              end
              else
                WriteLn('文件夹不存在: ', FolderPath);
            end
            else
              WriteLn('参数不足. 用法: report <文件夹> <报告文件>');
          finally
            Params.Free;
          end;
        end
        else
          WriteLn('未知命令. 输入 "help" 查看帮助');
      end;
    finally
      Controller.Free;
    end;
  except
    on E: Exception do
      WriteLn(E.ClassName, ': ', E.Message);
  end;
end.