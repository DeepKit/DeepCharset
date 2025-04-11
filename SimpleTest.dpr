program SimpleTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Rtti,
  ControllerEncoding in 'ControllerEncoding.pas',
  ModelEncoding in 'ModelEncoding.pas';

type
  // 日志回调类
  TLogHandler = class
  public
    procedure LogCallback(const Msg: string);
  end;

var
  EncodingController: TEncodingController;
  LogHandler: TLogHandler;
  TestDir: string;
  TestFile: string;
  EncodingName: string;
  Success: Boolean;

procedure TLogHandler.LogCallback(const Msg: string);
begin
  Writeln(Msg);
end;

procedure CreateTestFile(const FileName: string; const Content: string; Encoding: TEncoding);
begin
  TFile.WriteAllText(FileName, Content, Encoding);
end;

begin
  try
    // 创建测试目录
    TestDir := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'TestFiles');
    if not DirectoryExists(TestDir) then
      ForceDirectories(TestDir);

    // 创建日志处理器
    LogHandler := TLogHandler.Create;

    // 创建编码控制器，使用方法引用作为回调
    EncodingController := TEncodingController.Create(LogHandler.LogCallback);
    try
      // 测试 1: 创建并检测 UTF-8 带 BOM 的文件
      TestFile := TPath.Combine(TestDir, 'utf8_with_bom.txt');
      CreateTestFile(TestFile, '这是一个UTF-8带BOM的测试文件', TEncoding.UTF8);

      Writeln('测试 1: 检测 UTF-8 带 BOM 的文件');
      Success := EncodingController.DetectFileEncoding(TestFile, EncodingName);
      Writeln('  检测结果: ' + BoolToStr(Success, True));
      Writeln('  编码: ' + EncodingName);
      Writeln;

      // 测试 2: 将 UTF-8 带 BOM 转换为 ANSI
      Writeln('测试 2: 将 UTF-8 带 BOM 转换为 ANSI');
      Success := EncodingController.ConvertSingleFileByName(TestFile, 'ANSI', False, nil);
      Writeln('  转换结果: ' + BoolToStr(Success, True));

      // 检查转换后的编码
      Success := EncodingController.DetectFileEncoding(TestFile, EncodingName);
      Writeln('  转换后编码: ' + EncodingName);
      Writeln;

      // 测试 3: 将 ANSI 转换为 UTF-8 带 BOM
      Writeln('测试 3: 将 ANSI 转换为 UTF-8 带 BOM');
      Success := EncodingController.ConvertSingleFileByName(TestFile, 'UTF-8 with BOM', True, nil);
      Writeln('  转换结果: ' + BoolToStr(Success, True));

      // 检查转换后的编码
      Success := EncodingController.DetectFileEncoding(TestFile, EncodingName);
      Writeln('  转换后编码: ' + EncodingName);
      Writeln;

      Writeln('所有测试完成！');
      Writeln('按任意键退出...');
      Readln;
    finally
      EncodingController.Free;
      LogHandler.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln('发生错误: ' + E.Message);
      Readln;
    end;
  end;
end.
