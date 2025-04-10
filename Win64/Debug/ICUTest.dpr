program ICUTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  UtilsICU in 'UtilsICU.pas';

var
  IcuHelper: TIcuHelper;
  SourceFile, TargetFile: string;
  DetectedEncoding: string;

begin
  try
    WriteLn('ICU库测试程序');
    WriteLn('----------------');
    
    // 显示当前目录
    WriteLn('当前目录: ', GetCurrentDir);
    WriteLn('DLL路径: ', ExtractFilePath(ParamStr(0)) + 'icuuc77.dll');
    WriteLn;
    
    // 检查DLL文件是否存在
    if not FileExists('icuuc77.dll') then
    begin
      WriteLn('错误: icuuc77.dll文件不存在！');
      WriteLn('请先运行setup.bat安装ICU库文件');
      Exit;
    end;
    
    if not FileExists('icuin77.dll') then
    begin
      WriteLn('错误: icuin77.dll文件不存在！');
      WriteLn('请先运行setup.bat安装ICU库文件');
      Exit;
    end;
    
    if not FileExists('icudt77.dll') then
    begin
      WriteLn('错误: icudt77.dll文件不存在！');
      WriteLn('请先运行setup.bat安装ICU库文件');
      Exit;
    end;
    
    WriteLn('创建TIcuHelper实例...');
    IcuHelper := TIcuHelper.Create;
    try
      WriteLn('TIcuHelper创建成功！');
      WriteLn;
      
      // 测试文件编码检测
      SourceFile := 'test.txt';
      if FileExists(SourceFile) then
      begin
        WriteLn('检测文件编码: ', SourceFile);
        if IcuHelper.DetectFileEncoding(SourceFile, DetectedEncoding) then
          WriteLn('检测到的编码: ', DetectedEncoding)
        else
          WriteLn('无法检测文件编码: ', IcuHelper.LastError);
        WriteLn;
        
        // 测试编码转换
        TargetFile := 'test_utf8.txt';
        WriteLn('转换文件编码到UTF-8...');
        
        var SourceBytes := TFile.ReadAllBytes(SourceFile);
        if IcuHelper.ConvertEncoding(SourceBytes, DetectedEncoding, 'UTF-8', True) then
        begin
          TFile.WriteAllBytes(TargetFile, SourceBytes);
          WriteLn('转换成功！');
        end
        else
          WriteLn('转换失败！错误: ', IcuHelper.LastError);
      end
      else
      begin
        WriteLn('测试文件 test.txt 不存在，创建一个简单的测试文件...');
        
        // 创建一个包含中文字符的测试文件
        var TestText: TBytes;
        var StrText: string;
        
        // 使用UTF-8字符串
        StrText := '你好, ICU!!';
        
        // 将字符串转换为UTF-8字节数组
        TestText := TEncoding.UTF8.GetBytes(StrText);
        
        TFile.WriteAllBytes('test.txt', TestText);
        WriteLn('创建测试文件成功，请重新运行程序测试！');
      end;
    finally
      IcuHelper.Free;
    end;
    
    WriteLn;
    WriteLn('按任意键退出...');
    Readln;
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      WriteLn('按任意键退出...');
      Readln;
    end;
  end;
end. 