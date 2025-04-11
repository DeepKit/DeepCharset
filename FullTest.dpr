program FullTest;

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

  // 测试用例类型
  TTestCase = record
    Name: string;
    SourceEncoding: TEncoding;
    TargetEncodingName: string;
    AddBOM: Boolean;
    Content: string;
  end;

var
  EncodingController: TEncodingController;
  LogHandler: TLogHandler;
  TestDir: string;
  TestFile: string;
  EncodingName: string;
  Success: Boolean;
  TestCases: array of TTestCase;
  I: Integer;

procedure TLogHandler.LogCallback(const Msg: string);
begin
  Writeln(Msg);
end;

procedure CreateTestFile(const FileName: string; const Content: string; Encoding: TEncoding);
begin
  TFile.WriteAllText(FileName, Content, Encoding);
end;

procedure InitializeTestCases;
var
  UTF8NoBOM: TEncoding;
begin
  UTF8NoBOM := TEncoding.GetEncoding(65001); // UTF-8 without BOM
  
  SetLength(TestCases, 6);
  
  // 测试用例 1: UTF-8 带 BOM -> ANSI
  TestCases[0].Name := 'UTF-8 带 BOM -> ANSI';
  TestCases[0].SourceEncoding := TEncoding.UTF8;
  TestCases[0].TargetEncodingName := 'ANSI';
  TestCases[0].AddBOM := False;
  TestCases[0].Content := '这是一个 UTF-8 带 BOM 的测试文件';
  
  // 测试用例 2: ANSI -> UTF-8 带 BOM
  TestCases[1].Name := 'ANSI -> UTF-8 带 BOM';
  TestCases[1].SourceEncoding := TEncoding.Default;
  TestCases[1].TargetEncodingName := 'UTF-8 with BOM';
  TestCases[1].AddBOM := True;
  TestCases[1].Content := 'This is an ANSI test file';
  
  // 测试用例 3: UTF-8 不带 BOM -> UTF-8 带 BOM
  TestCases[2].Name := 'UTF-8 不带 BOM -> UTF-8 带 BOM';
  TestCases[2].SourceEncoding := UTF8NoBOM;
  TestCases[2].TargetEncodingName := 'UTF-8 with BOM';
  TestCases[2].AddBOM := True;
  TestCases[2].Content := '这是一个 UTF-8 不带 BOM 的测试文件';
  
  // 测试用例 4: UTF-16 LE -> UTF-8 带 BOM
  TestCases[3].Name := 'UTF-16 LE -> UTF-8 带 BOM';
  TestCases[3].SourceEncoding := TEncoding.Unicode;
  TestCases[3].TargetEncodingName := 'UTF-8 with BOM';
  TestCases[3].AddBOM := True;
  TestCases[3].Content := '这是一个 UTF-16 LE 的测试文件';
  
  // 测试用例 5: UTF-16 BE -> UTF-8 带 BOM
  TestCases[4].Name := 'UTF-16 BE -> UTF-8 带 BOM';
  TestCases[4].SourceEncoding := TEncoding.BigEndianUnicode;
  TestCases[4].TargetEncodingName := 'UTF-8 with BOM';
  TestCases[4].AddBOM := True;
  TestCases[4].Content := '这是一个 UTF-16 BE 的测试文件';
  
  // 测试用例 6: UTF-8 带 BOM -> UTF-16 LE
  TestCases[5].Name := 'UTF-8 带 BOM -> UTF-16 LE';
  TestCases[5].SourceEncoding := TEncoding.UTF8;
  TestCases[5].TargetEncodingName := 'UTF-16 LE';
  TestCases[5].AddBOM := True;
  TestCases[5].Content := '这是一个 UTF-8 带 BOM 的测试文件，将转换为 UTF-16 LE';
end;

begin
  try
    // 创建测试目录
    TestDir := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'TestFiles');
    if not DirectoryExists(TestDir) then
      ForceDirectories(TestDir);
      
    // 初始化测试用例
    InitializeTestCases;
    
    // 创建日志处理器
    LogHandler := TLogHandler.Create;
    
    // 创建编码控制器，使用方法引用作为回调
    EncodingController := TEncodingController.Create(LogHandler.LogCallback);
    try
      Writeln('开始运行全面测试...');
      Writeln('');
      
      // 运行所有测试用例
      for I := 0 to High(TestCases) do
      begin
        Writeln('测试用例 ' + IntToStr(I + 1) + ': ' + TestCases[I].Name);
        
        // 创建测试文件
        TestFile := TPath.Combine(TestDir, 'test_' + IntToStr(I + 1) + '.txt');
        CreateTestFile(TestFile, TestCases[I].Content, TestCases[I].SourceEncoding);
        
        // 检测源文件编码
        Success := EncodingController.DetectFileEncoding(TestFile, EncodingName);
        Writeln('  源文件编码: ' + EncodingName);
        
        // 转换文件
        Success := EncodingController.ConvertSingleFileByName(
          TestFile, 
          TestCases[I].TargetEncodingName, 
          TestCases[I].AddBOM, 
          nil);
        Writeln('  转换结果: ' + BoolToStr(Success, True));
        
        // 检测转换后的编码
        Success := EncodingController.DetectFileEncoding(TestFile, EncodingName);
        Writeln('  转换后编码: ' + EncodingName);
        Writeln('');
      end;
      
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
