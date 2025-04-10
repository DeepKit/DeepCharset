program sample_test;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  JclStrings,
  JclFileUtils,
  JclAnsiStrings,
  JclStringConversions;

// 检测文件编码
function DetectFileEncoding(const FileName: string): string;
var
  FileStream: TFileStream;
  BOMLen: Integer;
  BOMType: TJclBOMType;
  Buffer: TBytes;
  BytesRead: Integer;
begin
  Result := 'Unknown';
  
  if not FileExists(FileName) then
    Exit;

  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    // 首先检测BOM
    BOMType := DetectBOM(FileStream);
    BOMLen := GetBOMLength(BOMType);
    
    // 根据BOM返回编码
    case BOMType of
      bomAnsi: Result := 'ANSI';
      bomUTF8: Result := 'UTF-8 with BOM';
      bomUTF16LE: Result := 'UTF-16LE';
      bomUTF16BE: Result := 'UTF-16BE';
      bomUTF32LE: Result := 'UTF-32LE';
      bomUTF32BE: Result := 'UTF-32BE';
    else
      // 无BOM，尝试检测内容
      FileStream.Position := 0;
      SetLength(Buffer, Min(FileStream.Size, 4096)); // 读取前4KB进行分析
      BytesRead := FileStream.Read(Buffer[0], Length(Buffer));
      SetLength(Buffer, BytesRead);
      
      // 尝试检测UTF-8
      if IsUTF8Valid(Buffer, 0, BytesRead) and BytesRead > 0 then
      begin
        Result := 'UTF-8 without BOM';
        Exit;
      end;
      
      // 尝试其他编码
      // 检查是否符合GB2312/GBK/GB18030
      if BytesRead > 1 then
      begin
        if IsGBKString(PAnsiChar(Buffer), BytesRead) then
        begin
          Result := 'GBK/GB2312';
          Exit;
        end;
      end;
      
      // 默认假设为ANSI/CP系列
      Result := 'ANSI (CP' + IntToStr(GetACP) + ')';
    end;
  finally
    FileStream.Free;
  end;
end;

// 测试目录中的文件
procedure TestFiles(const DirName: string; var Markdown: TStringList);
var
  FileList: TStringDynArray;
  FileName: string;
  I: Integer;
  HasBOM: Boolean;
  FileInfo: TFileInfo;
begin
  Markdown.Add('### ' + DirName + ' 目录');
  Markdown.Add('');
  Markdown.Add('| 文件名 | 检测到的编码 | 是否有BOM | 文件大小 |');
  Markdown.Add('|--------|--------------|-----------|----------|');
  
  if not DirectoryExists(DirName) then
  begin
    Markdown.Add('| 目录不存在 | - | - | - |');
    Markdown.Add('');
    Exit;
  end;
  
  try
    FileList := TDirectory.GetFiles(DirName);
    
    // 仅测试前15个文件（如果文件很多的话）
    for I := 0 to Min(14, Length(FileList) - 1) do
    begin
      FileName := FileList[I];
      HasBOM := DetectBOM(FileName) <> bomAnsi;
      FileInfo := GetFileInfo(FileName);
      
      // 添加到Markdown
      Markdown.Add(Format('| %s | %s | %s | %d 字节 |', 
        [ExtractFileName(FileName), DetectFileEncoding(FileName), 
         BoolToStr(HasBOM, '是', '否'), FileInfo.Size]));
    end;
    
    Markdown.Add('');
  except
    on E: Exception do
    begin
      Markdown.Add('| 处理目录时出错 | ' + E.Message + ' | - | - |');
      Markdown.Add('');
    end;
  end;
end;

var
  MD: TStringList;
  TestDirs: array[0..2] of string;
  Dir: string;
begin
  try
    WriteLn('开始测试文件编码检测...');
    
    TestDirs[0] := 'files';
    TestDirs[1] := 'from';
    TestDirs[2] := 'UcsExamples';
    
    MD := TStringList.Create;
    try
      MD.Add('# 文件编码检测测试结果');
      MD.Add('');
      MD.Add('使用JCL库对不同目录中的文件进行编码检测测试。');
      MD.Add('');
      
      for Dir in TestDirs do
        TestFiles(Dir, MD);
      
      MD.SaveToFile('tests.md', TEncoding.UTF8);
      
      WriteLn('测试完成，结果已保存到tests.md文件中');
    finally
      MD.Free;
    end;
    
    WriteLn('按任意键退出...');
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end. 