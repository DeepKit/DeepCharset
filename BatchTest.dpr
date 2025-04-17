program BatchTest;

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.IOUtils;

// 测试单个文件
procedure TestFile(const FileName: string);
var
  Command, OutputFileName: string;
  ExitCode: Integer;
begin
  WriteLn('测试文件: ', FileName);

  // 构建输出文件名
  OutputFileName := ChangeFileExt(FileName, '_utf8bom' + ExtractFileExt(FileName));

  // 删除可能存在的旧输出文件
  if FileExists(OutputFileName) then
    DeleteFile(PChar(OutputFileName));

  // 构建命令行
  Command := 'EncodingTest.exe "' + FileName + '"';

  // 执行命令
  ExitCode := 0;
  WriteLn('执行命令: ', Command);
  ExitCode := 0;
  WinExec(PAnsiChar(AnsiString(Command)), SW_SHOW);

  // 检查结果
  if FileExists(OutputFileName) then
  begin
    WriteLn('转换成功: ', OutputFileName);
    WriteLn('文件大小: ', TFile.GetSize(OutputFileName), ' 字节');

    // 检查文件是否以UTF-8 BOM开头
    var Stream := TFileStream.Create(OutputFileName, fmOpenRead);
    try
      if Stream.Size >= 3 then
      begin
        var BOM: array[0..2] of Byte;
        Stream.ReadBuffer(BOM, 3);

        if (BOM[0] = $EF) and (BOM[1] = $BB) and (BOM[2] = $BF) then
          WriteLn('文件包含UTF-8 BOM')
        else
          WriteLn('警告: 文件不包含UTF-8 BOM');
      end
      else
        WriteLn('警告: 文件太小，无法检查BOM');
    finally
      Stream.Free;
    end;
  end
  else
    WriteLn('错误: 转换失败，输出文件不存在');

  WriteLn;
end;

var
  SearchRec: TSearchRec;
  TestDir: string;
begin
  try
    // 设置控制台编码为UTF-8，以便正确显示中文
    SetConsoleOutputCP(65001);

    WriteLn('批量编码测试程序');
    WriteLn('=============');
    WriteLn;

    // 测试目录
    TestDir := 'tests\from';

    // 测试所有测试文件
    if FindFirst(TestDir + '\*.txt', faAnyFile, SearchRec) = 0 then
    begin
      repeat
        // 跳过已经转换过的文件
        if Pos('_utf8bom', SearchRec.Name) = 0 then
          TestFile(TestDir + '\' + SearchRec.Name);
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;

    WriteLn('所有测试完成!');
    WriteLn('按任意键退出...');
    ReadLn;
  except
    on E: Exception do
    begin
      WriteLn('发生错误: ', E.Message);
      ReadLn;
    end;
  end;
end.
