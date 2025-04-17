program TestIconv;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes;

const
  TEST_DIR = 'test_files';

// 创建测试文件
procedure CreateTestFiles;
var
  Dir: string;
  UTF8File, GB2312File: string;
  UTF8Bytes, GB2312Bytes: TBytes;
  UTF8Stream, GB2312Stream: TFileStream;
begin
  WriteLn('===== 创建测试文件 =====');
  
  // 创建测试目录
  Dir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + TEST_DIR);
  if not DirectoryExists(Dir) then
    ForceDirectories(Dir);
    
  // 创建UTF-8文件
  UTF8File := Dir + 'utf8_test.txt';
  WriteLn('创建UTF-8测试文件: ', UTF8File);
  
  // UTF-8文本内容
  var TextContent := '这是一个UTF-8编码的测试文件。' + sLineBreak + 
                     'This is a UTF-8 encoded test file.' + sLineBreak + 
                     '这包含了中文和英文字符。';
  UTF8Bytes := TEncoding.UTF8.GetBytes(TextContent);
  
  // 写入UTF-8 BOM和内容  
  UTF8Stream := TFileStream.Create(UTF8File, fmCreate);
  try
    // 写入UTF-8 BOM
    UTF8Stream.WriteBuffer(TEncoding.UTF8.GetPreamble, Length(TEncoding.UTF8.GetPreamble));
    // 写入UTF-8内容
    UTF8Stream.WriteBuffer(UTF8Bytes, Length(UTF8Bytes));
  finally
    UTF8Stream.Free;
  end;
  
  // 创建GB2312文件
  GB2312File := Dir + 'gb2312_test.txt';
  WriteLn('创建GB2312测试文件: ', GB2312File);
  
  // 从UTF-8转换为GB2312
  var GB2312Encoding := TEncoding.GetEncoding(936);
  GB2312Bytes := TEncoding.Convert(TEncoding.UTF8, GB2312Encoding, UTF8Bytes);
  
  // 写入GB2312内容
  GB2312Stream := TFileStream.Create(GB2312File, fmCreate);
  try
    GB2312Stream.WriteBuffer(GB2312Bytes, Length(GB2312Bytes));
  finally
    GB2312Stream.Free;
  end;
  
  WriteLn('测试文件创建完成');
  WriteLn;
end;

// 检测文件编码
procedure DetectFileEncoding;
var
  Dir: string;
  Files: TArray<string>;
  FilePath: string;
  i, j: Integer;
  Encoding: string;
  Buffer: TBytes;
  ChineseChars: Integer;
  IsGB2312, HasHighASCII: Boolean;
begin
  WriteLn('===== 检测文件编码 =====');
  
  Dir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + TEST_DIR);
  Files := TDirectory.GetFiles(Dir, '*.txt');
  
  for i := 0 to Length(Files) - 1 do
  begin
    FilePath := Files[i];
    WriteLn('检测文件编码: ', ExtractFileName(FilePath));
    
    // 读取文件内容用于分析
    Buffer := TFile.ReadAllBytes(FilePath);
    
    if Length(Buffer) >= 3 then
    begin
      // 检测UTF-8 BOM
      if (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF) then
      begin
        Encoding := 'UTF-8 (带BOM)';
      end
      else
      begin
        // 检测是否为GB2312/GBK编码
        ChineseChars := 0;
        HasHighASCII := False;
        IsGB2312 := True;
        
        j := 0;
        while j < Length(Buffer) - 1 do
        begin
          // 检查ASCII字符
          if Buffer[j] < $80 then
          begin
            Inc(j);
            Continue;
          end;
          
          HasHighASCII := True;
          
          // 检查是否符合GB2312/GBK编码模式
          // 首字节范围: $81-$FE
          // 次字节范围: $40-$7E, $80-$FE
          if (j+1 < Length(Buffer)) and
             (Buffer[j] >= $81) and (Buffer[j] <= $FE) and
             (((Buffer[j+1] >= $40) and (Buffer[j+1] <= $7E)) or
              ((Buffer[j+1] >= $80) and (Buffer[j+1] <= $FE))) then
          begin
            Inc(ChineseChars);
            Inc(j, 2);
          end
          else
          begin
            IsGB2312 := False;
            Inc(j);
          end;
        end;
        
        // 判断编码
        if IsGB2312 and HasHighASCII and (ChineseChars > 0) then
          Encoding := 'GB2312/GBK'
        else if HasHighASCII then
          Encoding := '未知编码 (可能含有非ASCII字符)'
        else
          Encoding := 'ASCII文本';
      end;
    end
    else
      Encoding := '文件太小，无法检测';
      
    WriteLn('  编码: ', Encoding);
  end;
  WriteLn;
end;

// 读取并显示文件内容
procedure ShowFileContent;
var
  Dir: string;
  Files: TArray<string>;
  FilePath: string;
  i: Integer;
  Content: string;
begin
  WriteLn('===== 显示文件内容 =====');
  
  Dir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + TEST_DIR);
  Files := TDirectory.GetFiles(Dir, '*.txt');
  
  for i := 0 to Length(Files) - 1 do
  begin
    FilePath := Files[i];
    WriteLn('文件内容: ', ExtractFileName(FilePath));
    
    try
      // 尝试读取为UTF8
      Content := TFile.ReadAllText(FilePath, TEncoding.UTF8);
      WriteLn('  (UTF-8编码解析): ', Copy(Content, 1, 50), '...');
    except
      on E: Exception do
        WriteLn('  UTF-8读取失败: ', E.Message);
    end;
    
    try
      // 尝试读取为GB2312
      Content := TFile.ReadAllText(FilePath, TEncoding.GetEncoding(936));
      WriteLn('  (GB2312编码解析): ', Copy(Content, 1, 50), '...');
    except
      on E: Exception do
        WriteLn('  GB2312读取失败: ', E.Message);
    end;
    
    WriteLn;
  end;
end;

begin
  try
    WriteLn('===== 编码测试程序 =====');
    WriteLn;
    
    // 创建测试文件
    CreateTestFiles;
    
    // 检测文件编码
    DetectFileEncoding;
    
    // 显示文件内容
    ShowFileContent;
    
    WriteLn('测试完成。按任意键退出...');
    Readln;
  except
    on E: Exception do
    begin
      WriteLn('测试过程中发生错误: ', E.Message);
      WriteLn('按任意键退出...');
      Readln;
    end;
  end;
end. 