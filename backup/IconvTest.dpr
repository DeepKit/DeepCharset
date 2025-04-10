program IconvTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  UtilsIconv in 'UtilsIconv.pas';

var
  IconvHelper: TIconvHelper;
  SourceFile, TargetFile: string;
  DetectedEncoding: string;

begin
  try
    WriteLn('iconv库测试程序');
    WriteLn('----------------');
    
    // 显示当前目录
    WriteLn('当前目录: ', GetCurrentDir);
    WriteLn('DLL路径: ', ExtractFilePath(ParamStr(0)) + 'libiconv-2.dll');
    WriteLn;
    
    // 检查DLL文件是否存在
    if not FileExists('libiconv-2.dll') then
    begin
      WriteLn('错误: libiconv-2.dll文件不存在！');
      Exit;
    end;
    
    WriteLn('创建TIconvHelper实例...');
    IconvHelper := TIconvHelper.Create;
    try
      WriteLn('TIconvHelper创建成功！');
      WriteLn;
      
      // 列出支持的编码
      WriteLn('支持的编码列表：');
      for var Encoding in IconvHelper.GetSupportedEncodings do
      begin
        WriteLn(Format('- %s (CodePage: %d, Category: %d)',
          [Encoding.Name, Encoding.CodePage, Ord(Encoding.Category)]));
      end;
      WriteLn;
      
      // 测试文件编码检测
      SourceFile := 'test.txt';
      if FileExists(SourceFile) then
      begin
        WriteLn('检测文件编码: ', SourceFile);
        if IconvHelper.DetectFileEncoding(SourceFile, DetectedEncoding) then
          WriteLn('检测到的编码: ', DetectedEncoding)
        else
          WriteLn('无法检测文件编码');
        WriteLn;
        
        // 测试编码转换
        TargetFile := 'test_utf8.txt';
        WriteLn('转换文件编码到UTF-8...');
        if IconvHelper.ConvertFileEncoding(SourceFile, TargetFile, DetectedEncoding, 'UTF-8') then
          WriteLn('转换成功！')
        else
          WriteLn('转换失败！');
      end
      else
      begin
        // 创建测试文件
        WriteLn('创建测试文件...');
        var TestContent := 'Hello, 世界！';
        TFile.WriteAllText(SourceFile, TestContent, TEncoding.UTF8);
        WriteLn('测试文件已创建: ', SourceFile);
      end;
      
    finally
      IconvHelper.Free;
    end;
    
    WriteLn;
    WriteLn('测试完成。按任意键退出...');
    ReadLn;
    
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      ReadLn;
    end;
  end;
end. 