program GenerateSpecialTestFiles;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Winapi.Windows;

const
  TEST_DIR = 'TestFiles\';

procedure GenerateCorruptedFile(const FileName: string);
var
  Stream: TFileStream;
  Buffer: TBytes;
  i: Integer;
begin
  WriteLn('生成损坏文件: ', FileName);
  
  // 创建随机损坏的二进制数据
  SetLength(Buffer, 1024);
  Randomize;
  for i := 0 to High(Buffer) do
    Buffer[i] := Random(256);
  
  // 在随机位置插入一些有效的文本
  var ValidText := '这是一段有效的中文文本，用于测试损坏文件的处理能力';
  var TextBytes := TEncoding.UTF8.GetBytes(ValidText);
  var StartPos := Random(Length(Buffer) - Length(TextBytes));
  
  // 复制有效文本到随机位置
  if Length(TextBytes) > 0 then
    Move(TextBytes[0], Buffer[StartPos], Length(TextBytes));
  
  // 写入文件
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    Stream.WriteBuffer(Buffer[0], Length(Buffer));
  finally
    Stream.Free;
  end;
  
  WriteLn('损坏文件已生成: ', FileName);
end;

procedure GenerateMixedEncodingFile(const FileName: string);
var
  UTF8Content, GBKContent: string;
  UTF8Bytes, GBKBytes, FinalBytes: TBytes;
  UTF8BOM: TBytes;
begin
  WriteLn('生成混合编码文件: ', FileName);
  
  // 准备UTF-8和GBK内容
  UTF8Content := '这是UTF-8编码部分，包含特殊字符：★☆♠♣♥♦' + #13#10;
  GBKContent := '这是GBK编码部分，包含中文字符' + #13#10;
  
  // 转换为字节
  UTF8Bytes := TEncoding.UTF8.GetBytes(UTF8Content);
  GBKBytes := TEncoding.GetEncoding(936).GetBytes(GBKContent);
  
  // UTF-8 BOM
  UTF8BOM := TBytes.Create($EF, $BB, $BF);
  
  // 合并所有字节
  SetLength(FinalBytes, Length(UTF8BOM) + Length(UTF8Bytes) + Length(GBKBytes));
  
  // 复制UTF-8 BOM
  if Length(UTF8BOM) > 0 then
    Move(UTF8BOM[0], FinalBytes[0], Length(UTF8BOM));
  
  // 复制UTF-8内容
  if Length(UTF8Bytes) > 0 then
    Move(UTF8Bytes[0], FinalBytes[Length(UTF8BOM)], Length(UTF8Bytes));
  
  // 复制GBK内容
  if Length(GBKBytes) > 0 then
    Move(GBKBytes[0], FinalBytes[Length(UTF8BOM) + Length(UTF8Bytes)], Length(GBKBytes));
  
  // 写入文件
  TFile.WriteAllBytes(FileName, FinalBytes);
  
  WriteLn('混合编码文件已生成: ', FileName);
end;

procedure GenerateLargeFile(const FileName: string; SizeMB: Integer);
var
  Stream: TFileStream;
  Buffer: TBytes;
  i, j: Integer;
  Content: string;
begin
  WriteLn(Format('生成大文件: %s (%d MB)', [FileName, SizeMB]));
  
  // 创建基本内容
  Content := '这是大文件测试内容，用于测试大文件处理性能。包含重复文本：';
  for i := 1 to 10 do
    Content := Content + '第' + IntToStr(i) + '段重复内容。';
  Content := Content + #13#10;
  
  // 转换为UTF-8字节
  Buffer := TEncoding.UTF8.GetBytes(Content);
  
  // 创建文件流
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    // 写入UTF-8 BOM
    var BOM := TEncoding.UTF8.GetPreamble;
    if Length(BOM) > 0 then
      Stream.WriteBuffer(BOM[0], Length(BOM));
    
    // 重复写入内容直到达到指定大小
    var TargetSize := SizeMB * 1024 * 1024; // MB转换为字节
    while Stream.Size < TargetSize do
    begin
      if Length(Buffer) > 0 then
        Stream.WriteBuffer(Buffer[0], Length(Buffer));
    end;
  finally
    Stream.Free;
  end;
  
  WriteLn(Format('大文件已生成: %s (实际大小: %.2f MB)', 
    [FileName, TFile.GetSize(FileName) / (1024 * 1024)]));
end;

begin
  try
    // 设置控制台编码为UTF-8
    SetConsoleOutputCP(65001);
    
    WriteLn('开始生成特殊测试文件...');
    
    // 确保测试目录存在
    if not DirectoryExists(TEST_DIR) then
      CreateDir(TEST_DIR);
    
    // 生成损坏文件
    GenerateCorruptedFile(TEST_DIR + 'corrupted_file.txt');
    
    // 生成混合编码文件
    GenerateMixedEncodingFile(TEST_DIR + 'mixed_encoding_new.txt');
    
    // 生成大文件 (5MB)
    GenerateLargeFile(TEST_DIR + 'large_file_5mb.txt', 5);
    
    // 生成超大文件 (20MB)
    GenerateLargeFile(TEST_DIR + 'large_file_20mb.txt', 20);
    
    WriteLn('所有测试文件已生成完成。');
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