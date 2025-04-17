program EncodingTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  System.Types,
  ModelEncoding in 'ModelEncoding.pas',
  ControllerEncoding in 'ControllerEncoding.pas',
  UtilsIconv in 'UtilsIconv.pas',
  UtilsUTF8 in 'UtilsUTF8.pas';

var
  Controller: TEncodingController;
  SourceEncoding: string;
  SourceFiles: TStringDynArray;
  SourceDir, TargetDir, BackDir: string;
  LogProc: TProc<string>;

// 需要定义一个全局变量用于类型转换
procedure LogHandler(const Msg: string);
begin
  Writeln(Msg);
end;

begin
  try
    Writeln('===== 编码测试开始 =====');
    
    // 设置目录
    SourceDir := 'tests\from';
    TargetDir := 'tests\to';
    BackDir := 'tests\back';
    
    // 检查目录是否存在
    if not DirectoryExists(SourceDir) then
    begin
      Writeln('创建目录: ' + SourceDir);
      ForceDirectories(SourceDir);
    end;
    
    if not DirectoryExists(TargetDir) then
    begin
      Writeln('创建目录: ' + TargetDir);
      ForceDirectories(TargetDir);
    end;
    
    if not DirectoryExists(BackDir) then
    begin
      Writeln('创建目录: ' + BackDir);
      ForceDirectories(BackDir);
    end;
    
    // 使用TMethod和正确的方法创建回调
    LogProc := LogHandler;
    
    // 创建控制器
    Controller := TEncodingController.Create(LogProc);
    
    try
      // 列出源目录中的文件
      Writeln('查找测试文件:');
      
      if DirectoryExists(SourceDir) then
      begin
        SourceFiles := TDirectory.GetFiles(SourceDir);
        
        if Length(SourceFiles) = 0 then
          Writeln('  源目录为空')
        else
          for var FileName in SourceFiles do
          begin
            Writeln('- ' + ExtractFileName(FileName));
            
            // 检测编码
            if Controller.DetectFileEncoding(FileName, SourceEncoding) then
              Writeln('  编码: ' + SourceEncoding)
            else
              Writeln('  无法检测编码');
          end;
      end
      else
        Writeln('找不到源目录');
    finally
      Controller.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  
  Writeln('按Enter键退出...');
  Readln;
end. 