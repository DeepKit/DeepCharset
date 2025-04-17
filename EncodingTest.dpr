program EncodingTest;

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  JclBOM in 'JclBOM.pas',
  JclEncodingUtils in 'JclEncodingUtils.pas';

procedure DumpFileBytes(const FileName: string; Count: Integer);
var
  FileStream: TFileStream;
  Buffer: TBytes;
  i: Integer;
begin
  try
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      SetLength(Buffer, Count);
      FileStream.Read(Buffer[0], Min(Count, FileStream.Size));

      WriteLn('文件前', Count, '个字节:');
      for i := 0 to Min(Count - 1, Length(Buffer) - 1) do
      begin
        Write(IntToHex(Buffer[i], 2), ' ');
        if (i + 1) mod 16 = 0 then
          WriteLn;
      end;
      WriteLn;
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
      WriteLn('读取文件字节出错: ', E.Message);
  end;
end;

var
  SourceFile, TargetFile: string;
  DetectedEncoding: string;
  Success: Boolean;

begin
  try
    // 设置控制台编码为UTF-8，以便正确显示中文
    SetConsoleOutputCP(65001);

    WriteLn('编码检测和转换测试程序');
    WriteLn('=====================');
    WriteLn;

    if ParamCount < 1 then
    begin
      WriteLn('用法: EncodingTest.exe <源文件> [目标文件]');
      WriteLn('如果未指定目标文件，将在源文件同目录下创建一个带有 _utf8bom 后缀的文件');
      Exit;
    end;

    SourceFile := ParamStr(1);

    if not FileExists(SourceFile) then
    begin
      WriteLn('错误: 源文件不存在: ', SourceFile);
      Exit;
    end;

    // 显示文件的二进制内容
    DumpFileBytes(SourceFile, 32);
    WriteLn;

    // 检测源文件编码
    WriteLn('检测文件编码: ', SourceFile);
    DetectedEncoding := DetectFileEncoding(SourceFile);
    WriteLn('检测到的编码: ', DetectedEncoding);
    WriteLn;

    // 设置目标文件名
    if ParamCount >= 2 then
      TargetFile := ParamStr(2)
    else
      TargetFile := ChangeFileExt(SourceFile, '_utf8bom' + ExtractFileExt(SourceFile));

    // 转换为UTF-8 BOM
    WriteLn('转换文件为UTF-8 BOM: ', SourceFile, ' -> ', TargetFile);
    Success := ConvertFileToUTF8BOM(SourceFile, TargetFile);
    
    // 验证转换结果
    if Success then
    begin
      // 读取原始文件和转换后文件内容进行比较
      var OriginalContent := TFile.ReadAllText(SourceFile, TEncoding.GetEncoding(DetectedEncoding));
      var ConvertedContent := TFile.ReadAllText(TargetFile, TEncoding.UTF8);
      
      if OriginalContent = ConvertedContent then
        WriteLn('验证成功: 转换前后内容一致')
      else
      begin
        WriteLn('验证失败: 转换前后内容不一致');
        WriteLn('差异位置: ', FindFirstDiffPos(OriginalContent, ConvertedContent));
        Success := False;
      end;

    if Success then
    begin
      WriteLn('转换成功!');

      // 显示转换后文件的二进制内容
      DumpFileBytes(TargetFile, 32);
      WriteLn;

      // 检测转换后的文件编码
      DetectedEncoding := DetectFileEncoding(TargetFile);
      WriteLn('转换后的文件编码: ', DetectedEncoding);
    end
    else
      WriteLn('转换失败!');

    WriteLn;
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
