program EdgeCaseTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  ControllerEncoding in 'ControllerEncoding.pas',
  ModelEncoding in 'ModelEncoding.pas';

type
  // 日志回调类
  TLogHandler = class
  public
    procedure LogCallback(const Msg: string);
  end;

  // 测试用例类型
  TTestProc = reference to procedure;

  TEdgeCaseTest = record
    Name: string;
    Setup: TTestProc;
    Execute: TTestProc;
    Verify: TTestProc;
    Cleanup: TTestProc;
  end;

var
  EncodingController: TEncodingController;
  LogHandler: TLogHandler;
  TestDir: string;
  EdgeCases: array of TEdgeCaseTest;
  I: Integer;
  EmptyFile: string;
  HugeFile: string;
  LockedFile: string;
  ReadOnlyFile: string;
  InvalidEncodingFile: string;
  MixedEncodingFile: string;
  FileStream: TFileStream;
  TestResult: Boolean;

procedure TLogHandler.LogCallback(const Msg: string);
begin
  Writeln(Msg);
end;

// 创建空文件
procedure CreateEmptyFile;
begin
  EmptyFile := TPath.Combine(TestDir, 'empty.txt');
  TFile.WriteAllText(EmptyFile, '');
  Writeln('创建空文件: ' + EmptyFile);
end;

// 创建超大文件
procedure CreateHugeFile;
var
  Stream: TFileStream;
  Buffer: array of Byte;
  I: Integer;
  Size: Int64;
begin
  HugeFile := TPath.Combine(TestDir, 'huge.txt');
  Size := 10 * 1024 * 1024; // 10MB

  Stream := TFileStream.Create(HugeFile, fmCreate);
  try
    SetLength(Buffer, 1024);
    for I := 0 to 1023 do
      Buffer[I] := Byte(I mod 256);

    for I := 0 to (Size div 1024) - 1 do
      Stream.WriteBuffer(Buffer[0], 1024);
  finally
    Stream.Free;
  end;

  Writeln('创建超大文件: ' + HugeFile + ' (' + IntToStr(Size) + ' 字节)');
end;

// 创建被锁定的文件
procedure CreateLockedFile;
begin
  LockedFile := TPath.Combine(TestDir, 'locked.txt');
  TFile.WriteAllText(LockedFile, '这是一个将被锁定的文件');

  // 以独占方式打开文件，模拟文件被锁定
  FileStream := TFileStream.Create(LockedFile, fmOpenReadWrite or fmShareExclusive);

  Writeln('创建并锁定文件: ' + LockedFile);
end;

// 创建只读文件
procedure CreateReadOnlyFile;
begin
  ReadOnlyFile := TPath.Combine(TestDir, 'readonly.txt');
  TFile.WriteAllText(ReadOnlyFile, '这是一个只读文件');

  // 设置文件为只读
  TFile.SetAttributes(ReadOnlyFile, TFile.GetAttributes(ReadOnlyFile) + [TFileAttribute.faReadOnly]);

  Writeln('创建只读文件: ' + ReadOnlyFile);
end;

// 创建无效编码的文件
procedure CreateInvalidEncodingFile;
var
  Stream: TFileStream;
  Buffer: array of Byte;
  I: Integer;
begin
  InvalidEncodingFile := TPath.Combine(TestDir, 'invalid_encoding.txt');

  Stream := TFileStream.Create(InvalidEncodingFile, fmCreate);
  try
    // 创建一些无效的UTF-8序列
    SetLength(Buffer, 10);
    Buffer[0] := $C0; // 无效的UTF-8起始字节
    Buffer[1] := $AF;
    Buffer[2] := $E0; // 不完整的UTF-8序列
    Buffer[3] := $80;
    Buffer[4] := $FF; // 无效的UTF-8字节
    Buffer[5] := $FE; // 无效的UTF-8字节
    Buffer[6] := $C1; // 无效的UTF-8起始字节
    Buffer[7] := $BF;
    Buffer[8] := $F5; // 超出UTF-8范围
    Buffer[9] := $80;

    Stream.WriteBuffer(Buffer[0], 10);
  finally
    Stream.Free;
  end;

  Writeln('创建无效编码文件: ' + InvalidEncodingFile);
end;

// 创建混合编码的文件
procedure CreateMixedEncodingFile;
var
  Stream: TFileStream;
  UTF8Bytes, ANSIBytes: TBytes;
begin
  MixedEncodingFile := TPath.Combine(TestDir, 'mixed_encoding.txt');

  // 获取UTF-8和ANSI编码的字节
  UTF8Bytes := TEncoding.UTF8.GetBytes('这是UTF-8编码的文本');
  ANSIBytes := TEncoding.Default.GetBytes('This is ANSI encoded text');

  Stream := TFileStream.Create(MixedEncodingFile, fmCreate);
  try
    // 先写入UTF-8内容
    Stream.WriteBuffer(UTF8Bytes[0], Length(UTF8Bytes));
    // 再写入ANSI内容
    Stream.WriteBuffer(ANSIBytes[0], Length(ANSIBytes));
  finally
    Stream.Free;
  end;

  Writeln('创建混合编码文件: ' + MixedEncodingFile);
end;

// 测试空文件转换
procedure TestEmptyFileConversion;
var
  Success: Boolean;
  EncodingName: string;
begin
  Writeln('测试空文件转换...');

  // 尝试转换空文件
  Success := EncodingController.ConvertSingleFileByName(EmptyFile, 'UTF-8 with BOM', True, nil);

  // 检查结果
  Writeln('  转换结果: ' + BoolToStr(Success, True));

  // 检查转换后的编码
  if Success then
  begin
    Success := EncodingController.DetectFileEncoding(EmptyFile, EncodingName);
    Writeln('  转换后编码: ' + EncodingName);
  end;

  TestResult := Success;
end;

// 测试超大文件转换
procedure TestHugeFileConversion;
var
  Success: Boolean;
  EncodingName: string;
  StartTime, EndTime: TDateTime;
  ElapsedSecs: Double;
begin
  Writeln('测试超大文件转换...');

  // 记录开始时间
  StartTime := Now;

  // 尝试转换超大文件
  Success := EncodingController.ConvertSingleFileByName(HugeFile, 'UTF-8 with BOM', True, nil);

  // 记录结束时间
  EndTime := Now;
  ElapsedSecs := (EndTime - StartTime) * 24 * 60 * 60;

  // 检查结果
  Writeln('  转换结果: ' + BoolToStr(Success, True));
  Writeln('  耗时: ' + FormatFloat('0.000', ElapsedSecs) + ' 秒');

  // 检查转换后的编码
  if Success then
  begin
    Success := EncodingController.DetectFileEncoding(HugeFile, EncodingName);
    Writeln('  转换后编码: ' + EncodingName);
  end;

  TestResult := Success;
end;

// 测试锁定文件转换
procedure TestLockedFileConversion;
var
  Success: Boolean;
begin
  Writeln('测试锁定文件转换...');

  // 尝试转换被锁定的文件
  Success := EncodingController.ConvertSingleFileByName(LockedFile, 'UTF-8 with BOM', True, nil);

  // 检查结果
  Writeln('  转换结果: ' + BoolToStr(Success, True));

  // 预期结果是失败
  TestResult := not Success;
end;

// 测试只读文件转换
procedure TestReadOnlyFileConversion;
var
  Success: Boolean;
  EncodingName: string;
begin
  Writeln('测试只读文件转换...');

  // 尝试转换只读文件
  Success := EncodingController.ConvertSingleFileByName(ReadOnlyFile, 'UTF-8 with BOM', True, nil);

  // 检查结果
  Writeln('  转换结果: ' + BoolToStr(Success, True));

  // 检查转换后的编码
  if Success then
  begin
    Success := EncodingController.DetectFileEncoding(ReadOnlyFile, EncodingName);
    Writeln('  转换后编码: ' + EncodingName);
  end;

  TestResult := Success;
end;

// 测试无效编码文件转换
procedure TestInvalidEncodingFileConversion;
var
  Success: Boolean;
  EncodingName: string;
begin
  Writeln('测试无效编码文件转换...');

  // 尝试检测无效编码文件
  Success := EncodingController.DetectFileEncoding(InvalidEncodingFile, EncodingName);
  Writeln('  检测结果: ' + BoolToStr(Success, True));
  if Success then
    Writeln('  检测到的编码: ' + EncodingName);

  // 尝试转换无效编码文件
  Success := EncodingController.ConvertSingleFileByName(InvalidEncodingFile, 'UTF-8 with BOM', True, nil);

  // 检查结果
  Writeln('  转换结果: ' + BoolToStr(Success, True));

  // 我们期望程序能够处理无效编码的文件，即使检测可能不准确
  TestResult := Success;
end;

// 测试混合编码文件转换
procedure TestMixedEncodingFileConversion;
var
  Success: Boolean;
  EncodingName: string;
begin
  Writeln('测试混合编码文件转换...');

  // 尝试检测混合编码文件
  Success := EncodingController.DetectFileEncoding(MixedEncodingFile, EncodingName);
  Writeln('  检测结果: ' + BoolToStr(Success, True));
  if Success then
    Writeln('  检测到的编码: ' + EncodingName);

  // 尝试转换混合编码文件
  Success := EncodingController.ConvertSingleFileByName(MixedEncodingFile, 'UTF-8 with BOM', True, nil);

  // 检查结果
  Writeln('  转换结果: ' + BoolToStr(Success, True));

  // 检查转换后的编码
  if Success then
  begin
    Success := EncodingController.DetectFileEncoding(MixedEncodingFile, EncodingName);
    Writeln('  转换后编码: ' + EncodingName);
  end;

  TestResult := Success;
end;

// 测试无效的目标编码
procedure TestInvalidTargetEncoding;
var
  Success: Boolean;
begin
  Writeln('测试无效的目标编码...');

  // 尝试使用无效的目标编码
  Success := EncodingController.ConvertSingleFileByName(
    TPath.Combine(TestDir, 'utf8_with_bom.txt'),
    'INVALID_ENCODING',
    True,
    nil);

  // 检查结果
  Writeln('  转换结果: ' + BoolToStr(Success, True));

  // 预期结果是失败
  TestResult := not Success;
end;

// 初始化测试用例
procedure InitializeEdgeCases;
begin
  SetLength(EdgeCases, 6);

  // 测试用例1: 空文件
  EdgeCases[0].Name := '空文件测试';
  EdgeCases[0].Setup := CreateEmptyFile;
  EdgeCases[0].Execute := TestEmptyFileConversion;
  EdgeCases[0].Verify := nil;
  EdgeCases[0].Cleanup := nil;

  // 测试用例2: 超大文件
  EdgeCases[1].Name := '超大文件测试';
  EdgeCases[1].Setup := CreateHugeFile;
  EdgeCases[1].Execute := TestHugeFileConversion;
  EdgeCases[1].Verify := nil;
  EdgeCases[1].Cleanup := nil;

  // 测试用例3: 锁定文件
  EdgeCases[2].Name := '锁定文件测试';
  EdgeCases[2].Setup := CreateLockedFile;
  EdgeCases[2].Execute := TestLockedFileConversion;
  EdgeCases[2].Verify := nil;
  EdgeCases[2].Cleanup := procedure begin if Assigned(FileStream) then FileStream.Free; end;

  // 测试用例4: 只读文件
  EdgeCases[3].Name := '只读文件测试';
  EdgeCases[3].Setup := CreateReadOnlyFile;
  EdgeCases[3].Execute := TestReadOnlyFileConversion;
  EdgeCases[3].Verify := nil;
  EdgeCases[3].Cleanup := nil;

  // 测试用例5: 无效编码文件
  EdgeCases[4].Name := '无效编码文件测试';
  EdgeCases[4].Setup := CreateInvalidEncodingFile;
  EdgeCases[4].Execute := TestInvalidEncodingFileConversion;
  EdgeCases[4].Verify := nil;
  EdgeCases[4].Cleanup := nil;

  // 测试用例6: 混合编码文件
  EdgeCases[5].Name := '混合编码文件测试';
  EdgeCases[5].Setup := CreateMixedEncodingFile;
  EdgeCases[5].Execute := TestMixedEncodingFileConversion;
  EdgeCases[5].Verify := nil;
  EdgeCases[5].Cleanup := nil;
end;

// 清理测试文件
procedure CleanupTestFiles;
var
  Files: TArray<string>;
  File_: string;
begin
  if DirectoryExists(TestDir) then
  begin
    Files := TDirectory.GetFiles(TestDir);
    for File_ in Files do
    begin
      try
        if (File_ = ReadOnlyFile) and FileExists(ReadOnlyFile) then
          TFile.SetAttributes(ReadOnlyFile, TFile.GetAttributes(ReadOnlyFile) - [TFileAttribute.faReadOnly]);
        DeleteFile(File_);
      except
        on E: Exception do
          Writeln('警告: 无法删除文件 ' + File_ + ': ' + E.Message);
      end;
    end;
  end;
end;

begin
  try
    // 创建测试目录
    TestDir := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'TestFiles');
    if not DirectoryExists(TestDir) then
      ForceDirectories(TestDir);

    // 清理可能存在的旧测试文件
    CleanupTestFiles;

    // 创建日志处理器
    LogHandler := TLogHandler.Create;

    // 创建编码控制器
    EncodingController := TEncodingController.Create(LogHandler.LogCallback);

    try
      // 初始化测试用例
      InitializeEdgeCases;

      Writeln('开始运行边缘情况测试...');
      Writeln('');

      // 运行所有测试用例
      for I := 0 to High(EdgeCases) do
      begin
        Writeln('测试用例 ' + IntToStr(I + 1) + ': ' + EdgeCases[I].Name);

        // 设置测试环境
        if Assigned(EdgeCases[I].Setup) then
          EdgeCases[I].Setup();

        // 执行测试
        TestResult := False;
        if Assigned(EdgeCases[I].Execute) then
          EdgeCases[I].Execute();

        // 验证结果
        if Assigned(EdgeCases[I].Verify) then
          EdgeCases[I].Verify();

        // 清理测试环境
        if Assigned(EdgeCases[I].Cleanup) then
          EdgeCases[I].Cleanup();

        if TestResult then
          Writeln('  测试结果: 通过')
        else
          Writeln('  测试结果: 失败');
        Writeln('');
      end;

      Writeln('所有测试完成！');
      Writeln('按任意键退出...');
      Readln;
    finally
      // 释放资源
      EncodingController.Free;
      LogHandler.Free;

      // 清理测试文件
      CleanupTestFiles;
    end;
  except
    on E: Exception do
    begin
      Writeln('发生错误: ' + E.Message);
      Readln;
    end;
  end;
end.
