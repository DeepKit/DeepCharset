program EncodingCompareTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  ControllerEncoding;

var
  EncodingController: TEncodingController;
  FileName: string;
  EncodingName: string;

procedure LogMessage(const Msg: string);
begin
  Writeln(Msg);
end;

begin
  try
    // 检查命令行参数
    if ParamCount < 1 then
    begin
      Writeln('用法: EncodingCompareTest.exe <文件路径>');
      Exit;
    end;

    FileName := ParamStr(1);
    if not FileExists(FileName) then
    begin
      Writeln('错误: 文件不存在 - ', FileName);
      Exit;
    end;

    // 创建编码控制器
    EncodingController := TEncodingController.Create;
    try
      EncodingController.SetLogCallback(LogMessage);

      // 检测文件编码
      Writeln('正在检测文件编码: ', FileName);
      if EncodingController.DetectFileEncoding(FileName, EncodingName) then
      begin
        Writeln('检测结果: ', EncodingName);
      end
      else
      begin
        Writeln('编码检测失败');
      end;
    finally
      EncodingController.Free;
    end;

    // 等待用户按键
    Writeln;
    Writeln('按任意键退出...');
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
