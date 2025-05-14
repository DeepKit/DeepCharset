program TestUTF8Detection;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  UTF8BOMConverter_Simple in 'UTF8BOMConverter_Simple.pas';

var
  FileName: string;
  HasBOM: Boolean;
  IsUTF8: Boolean;
begin
  try
    if ParamCount < 1 then
    begin
      Writeln('用法: TestUTF8Detection.exe <文件路径>');
      Exit;
    end;

    FileName := ParamStr(1);
    if not FileExists(FileName) then
    begin
      Writeln('文件不存在: ', FileName);
      Exit;
    end;

    Writeln('测试文件: ', FileName);

    // 使用UTF8BOMConverter_Simple中的IsUTF8File函数
    IsUTF8 := TUTF8BOMConverter.IsUTF8File(FileName, HasBOM);

    Writeln('检测结果:');
    Writeln('  是否UTF-8: ', BoolToStr(IsUTF8, True));
    Writeln('  是否有BOM: ', BoolToStr(HasBOM, True));

    Writeln('按任意键退出...');
    Readln;
  except
    on E: Exception do
    begin
      Writeln('发生错误: ', E.Message);
      Readln;
    end;
  end;
end.
