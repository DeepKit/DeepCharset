program TestUTF8BOMConverter;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  UTF8BOMConverter_Simple;

var
  TestFileName: string;
  Success: Boolean;

procedure CreateTestFile(const FileName: string; WithBOM: Boolean);
var
  Stream: TFileStream;
  Content: string;
  Buffer: TBytes;
  BOM: TBytes;
begin
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    // 添加BOM（如果需要）
    if WithBOM then
    begin
      SetLength(BOM, 3);
      BOM[0] := $EF;
      BOM[1] := $BB;
      BOM[2] := $BF;
      Stream.WriteBuffer(BOM[0], 3);
    end;

    // 添加一些测试内容
    Content := '这是一个测试文件。' + #13#10 +
               'This is a test file.' + #13#10 +
               '1234567890';

    // 写入内容
    Buffer := TEncoding.UTF8.GetBytes(Content);
    Stream.WriteBuffer(Buffer[0], Length(Buffer));
  finally
    Stream.Free;
  end;
end;

procedure DisplayFileInfo(const FileName: string);
var
  HasBOM: Boolean;
  Stream: TFileStream;
  Buffer: TBytes;
  I: Integer;
begin
  Writeln('文件信息: ' + FileName);

  if not FileExists(FileName) then
  begin
    Writeln('  文件不存在');
    Exit;
  end;

  HasBOM := TUTF8BOMConverter.HasUTF8BOM(FileName);
  Writeln('  有BOM: ' + BoolToStr(HasBOM, True));

  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    Writeln('  文件大小: ' + IntToStr(Stream.Size) + ' 字节');

    // 读取前10个字节（或更少）
    SetLength(Buffer, Min(10, Stream.Size));
    if Length(Buffer) > 0 then
    begin
      Stream.ReadBuffer(Buffer[0], Length(Buffer));

      Write('  前' + IntToStr(Length(Buffer)) + '个字节: ');
      for I := 0 to Length(Buffer) - 1 do
        Write('$' + IntToHex(Buffer[I], 2) + ' ');
      Writeln;
    end;
  finally
    Stream.Free;
  end;
end;

begin
  try
    // 创建临时测试文件名
    TestFileName := ChangeFileExt(ParamStr(0), '.test.txt');

    // 测试1：创建带BOM的文件，然后移除BOM
    Writeln('测试1：创建带BOM的文件，然后移除BOM');
    CreateTestFile(TestFileName, True);
    DisplayFileInfo(TestFileName);

    Writeln('移除BOM...');
    Success := TUTF8BOMConverter.RemoveUTF8BOM(TestFileName);
    if Success then
      Writeln('  操作成功')
    else
      Writeln('  操作失败');
    DisplayFileInfo(TestFileName);
    Writeln;

    // 测试2：创建不带BOM的文件，然后添加BOM
    Writeln('测试2：创建不带BOM的文件，然后添加BOM');
    CreateTestFile(TestFileName, False);
    DisplayFileInfo(TestFileName);

    Writeln('添加BOM...');
    Success := TUTF8BOMConverter.AddUTF8BOM(TestFileName);
    if Success then
      Writeln('  操作成功')
    else
      Writeln('  操作失败');
    DisplayFileInfo(TestFileName);
    Writeln;

    // 测试3：转换为UTF-8并添加BOM
    Writeln('测试3：转换为UTF-8并添加BOM');
    CreateTestFile(TestFileName, False);
    DisplayFileInfo(TestFileName);

    Writeln('转换为UTF-8并添加BOM...');
    Success := TUTF8BOMConverter.ConvertToUTF8WithBOM(TestFileName);
    if Success then
      Writeln('  操作成功')
    else
      Writeln('  操作失败');
    DisplayFileInfo(TestFileName);
    Writeln;

    // 测试4：转换为UTF-8并移除BOM
    Writeln('测试4：转换为UTF-8并移除BOM');
    CreateTestFile(TestFileName, True);
    DisplayFileInfo(TestFileName);

    Writeln('转换为UTF-8并移除BOM...');
    Success := TUTF8BOMConverter.ConvertToUTF8WithoutBOM(TestFileName);
    if Success then
      Writeln('  操作成功')
    else
      Writeln('  操作失败');
    DisplayFileInfo(TestFileName);
    Writeln;

    // 删除测试文件
    if FileExists(TestFileName) then
      DeleteFile(TestFileName);

    Writeln('所有测试完成，按任意键退出...');
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
