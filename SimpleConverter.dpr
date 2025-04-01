program SimpleConverter;
{$APPTYPE CONSOLE}

uses
  System.SysUtils, 
  System.IOUtils,
  System.Classes;

var
  LogFile: TextFile;

// 输出日志
procedure Log(const Msg: string);
begin
  Writeln(Msg);
  
  try
    Writeln(LogFile, FormatDateTime('[yyyy-mm-dd hh:nn:ss] ', Now) + Msg);
  except
    // 忽略日志文件错误
  end;
end;

// 主函数
var
  FromDir, ToDir: string;
  Files: TArray<string>;
  I: Integer;
  SourceFile, DestFile: string;
  FileName: string;
  Content: TBytes;
  UTF8Content: string;
  Encoding: TEncoding;
begin
  try
    try
      // 初始化日志
      AssignFile(LogFile, 'simple_convert.log');
      Rewrite(LogFile);
      
      Log('编码转换工具开始');
      
      // 设置目录
      FromDir := IncludeTrailingPathDelimiter(GetCurrentDir) + 'tests\from';
      ToDir := IncludeTrailingPathDelimiter(GetCurrentDir) + 'tests\to';
      
      Log('源目录: ' + FromDir);
      Log('目标目录: ' + ToDir);
      
      // 检查源目录
      if not DirectoryExists(FromDir) then
      begin
        Log('错误: 源目录不存在!');
        Exit;
      end;
      
      // 确保目标目录存在
      if not DirectoryExists(ToDir) then
      begin
        try
          ForceDirectories(ToDir);
          Log('创建目标目录: ' + ToDir);
        except
          on E: Exception do
          begin
            Log('错误: 创建目标目录失败: ' + E.Message);
            Exit;
          end;
        end;
      end;
      
      // 获取文件列表
      Files := TDirectory.GetFiles(FromDir);
      Log('找到' + IntToStr(Length(Files)) + '个文件');
      
      // 处理每个文件
      for I := 0 to Length(Files) - 1 do
      begin
        SourceFile := Files[I];
        FileName := ExtractFileName(SourceFile);
        DestFile := IncludeTrailingPathDelimiter(ToDir) + 'utf8_' + FileName;
        
        Log('处理文件: ' + FileName);
        
        try
          // 读取文件
          Content := TFile.ReadAllBytes(SourceFile);
          Log('  文件大小: ' + IntToStr(Length(Content)) + ' 字节');
          
          // 选择编码 - 基于文件名
          Encoding := nil;
          
          if Pos('utf8', LowerCase(FileName)) > 0 then
            Encoding := TEncoding.UTF8
          else if Pos('gbk', LowerCase(FileName)) > 0 then
            Encoding := TEncoding.GetEncoding(936)
          else if Pos('big5', LowerCase(FileName)) > 0 then
            Encoding := TEncoding.GetEncoding(950)
          else if (Pos('shift', LowerCase(FileName)) > 0) or (Pos('sjis', LowerCase(FileName)) > 0) then
            Encoding := TEncoding.GetEncoding(932)
          else if Pos('euc', LowerCase(FileName)) > 0 then
            Encoding := TEncoding.GetEncoding(949)
          else if Pos('iso', LowerCase(FileName)) > 0 then
            Encoding := TEncoding.GetEncoding(28591)
          else if Pos('koi', LowerCase(FileName)) > 0 then
            Encoding := TEncoding.GetEncoding(20866);
            
          if Assigned(Encoding) then
          begin
            // 转换为UTF-8
            UTF8Content := Encoding.GetString(Content);
            
            // 写入UTF-8文件
            TFile.WriteAllText(DestFile, UTF8Content, TEncoding.UTF8);
            
            Log('  成功转换为UTF-8，保存到: ' + ExtractFileName(DestFile));
          end
          else
          begin
            // 未知编码，直接复制
            TFile.Copy(SourceFile, DestFile, True);
            Log('  未识别编码，直接复制文件');
          end;
        except
          on E: Exception do
            Log('  错误处理文件: ' + E.Message);
        end;
        
        Log('');
      end;
      
      Log('转换完成!');
    except
      on E: Exception do
        Log('程序异常: ' + E.Message);
    end;
  finally
    // 关闭日志文件
    try
      CloseFile(LogFile);
    except
      // 忽略关闭错误
    end;
    
    Writeln('');
    Writeln('按回车键退出...');
    Readln;
  end;
end. 