unit EncodingDetectorUnit;

interface

procedure RunAutomatedTests;
function DetectFileEncoding(const FileName: string): string;
function ConvertFileEncoding(const SourceFileName, TargetFileName: string; 
  SourceEncoding, TargetEncoding: string): Boolean;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils,
  JclStrings, JclAnsiStrings, JclFileUtils, JclStringConversions;

type
  TEncodingTestResult = record
    FileName: string;
    DetectedEncoding: string;
    HasBOM: Boolean;
    FileSize: Int64;
    FilePath: string;
  end;
  
  TConversionTestResult = record
    SourceFile: string;
    TargetFile: string;
    SourceEncoding: string;
    TargetEncoding: string;
    Success: Boolean;
    ErrorMessage: string;
  end;

// 检测文件编码
function DetectFileEncoding(const FileName: string): string;
var
  FileStream: TFileStream;
  BOMLen: Integer;
  BOMType: TJclBOMType;
  Buffer: TBytes;
  CharSetDetected: string;
  ConvertedContent: WideString;
  ReadLen: Integer;
  CP: Word;
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

// 获取编码对应的代码页
function GetEncodingCodePage(const EncodingName: string): Integer;
var
  UpperName: string;
begin
  UpperName := UpperCase(EncodingName);
  
  // 常见编码与代码页的映射
  if (Pos('UTF-8', UpperName) > 0) or (UpperName = 'UTF8') then
    Result := CP_UTF8
  else if (Pos('UTF-16LE', UpperName) > 0) or (UpperName = 'UTF16LE') or (UpperName = 'UNICODE') then
    Result := 1200 // CP_UTF16LE
  else if (Pos('UTF-16BE', UpperName) > 0) or (UpperName = 'UTF16BE') then
    Result := 1201 // CP_UTF16BE
  else if (UpperName = 'GB2312') then
    Result := 936
  else if (UpperName = 'GBK') or (Pos('GBK', UpperName) > 0) then
    Result := 936
  else if (UpperName = 'GB18030') then
    Result := 54936
  else if (UpperName = 'BIG5') then
    Result := 950
  else if (Pos('SHIFT-JIS', UpperName) > 0) or (Pos('SHIFT_JIS', UpperName) > 0) or (Pos('SHIFTJIS', UpperName) > 0) then
    Result := 932
  else if (Pos('EUC-KR', UpperName) > 0) or (Pos('EUC_KR', UpperName) > 0) or (Pos('EUCKR', UpperName) > 0) then
    Result := 949
  else if (Pos('ISO-8859-1', UpperName) > 0) or (Pos('ISO8859-1', UpperName) > 0) or (Pos('LATIN1', UpperName) > 0) then
    Result := 1252
  else if (Pos('WINDOWS-1251', UpperName) > 0) or (Pos('WINDOWS1251', UpperName) > 0) or (Pos('CP1251', UpperName) > 0) then
    Result := 1251
  else if (UpperName = 'ANSI') then
    Result := GetACP
  else
    Result := 0; // 未知编码
end;

// 转换文件编码
function ConvertFileEncoding(const SourceFileName, TargetFileName: string; 
  SourceEncoding, TargetEncoding: string): Boolean;
var
  SourceStream, TargetStream: TStream;
  SourceBytes, TargetBytes: TBytes;
  SourceString: WideString;
  SourceCP, TargetCP: Integer;
  BOMBytes: TBytes;
  SourceBOM: TJclBOMType;
  SourceBOMLen: Integer;
begin
  Result := False;
  
  if not FileExists(SourceFileName) then
    Exit;
    
  // 解析编码名称为代码页
  SourceCP := GetEncodingCodePage(SourceEncoding);
  TargetCP := GetEncodingCodePage(TargetEncoding);
  
  if (SourceCP = 0) or (TargetCP = 0) then
    Exit;
  
  try
    SourceStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyNone);
    try
      // 检测BOM
      SourceBOM := DetectBOM(SourceStream);
      SourceBOMLen := GetBOMLength(SourceBOM);
      
      // 跳过BOM
      SourceStream.Position := SourceBOMLen;
      
      // 读取源文件内容
      SetLength(SourceBytes, SourceStream.Size - SourceBOMLen);
      if Length(SourceBytes) > 0 then
        SourceStream.ReadBuffer(SourceBytes[0], Length(SourceBytes));
      
      // 根据源编码将内容转换为WideString
      case SourceCP of
        CP_UTF8:
          SourceString := UTF8ToWideString(PAnsiChar(SourceBytes), Length(SourceBytes));
        CP_UTF16LE, 1200:
          begin
            SetLength(SourceString, Length(SourceBytes) div 2);
            if Length(SourceString) > 0 then
              Move(SourceBytes[0], SourceString[1], Length(SourceBytes));
          end;
        else
          SourceString := StringToWideStringEx(PAnsiChar(SourceBytes), SourceCP, Length(SourceBytes));
      end;
      
      // 将WideString转换为目标编码的字节
      case TargetCP of
        CP_UTF8:
          begin
            TargetBytes := TEncoding.UTF8.GetBytes(SourceString);
          end;
        CP_UTF16LE, 1200:
          begin
            SetLength(TargetBytes, Length(SourceString) * 2);
            if Length(SourceString) > 0 then
              Move(SourceString[1], TargetBytes[0], Length(TargetBytes));
          end;
        else
          begin
            // 使用JCL转换为ANSI编码
            TargetBytes := TEncoding.GetEncoding(TargetCP).GetBytes(SourceString);
          end;
      end;
      
      // 创建目标文件并写入BOM (如果需要)
      TargetStream := TFileStream.Create(TargetFileName, fmCreate);
      try
        // 添加BOM (如果目标格式需要)
        if (TargetCP = CP_UTF8) and (Pos('BOM', UpperCase(TargetEncoding)) > 0) then
        begin
          BOMBytes := TEncoding.UTF8.GetPreamble;
          if Length(BOMBytes) > 0 then
            TargetStream.WriteBuffer(BOMBytes[0], Length(BOMBytes));
        end
        else if (TargetCP = CP_UTF16LE) or (TargetCP = 1200) then
        begin
          BOMBytes := TEncoding.Unicode.GetPreamble;
          if Length(BOMBytes) > 0 then
            TargetStream.WriteBuffer(BOMBytes[0], Length(BOMBytes));
        end
        else if (TargetCP = CP_UTF16BE) or (TargetCP = 1201) then
        begin
          BOMBytes := TEncoding.BigEndianUnicode.GetPreamble;
          if Length(BOMBytes) > 0 then
            TargetStream.WriteBuffer(BOMBytes[0], Length(BOMBytes));
        end;
        
        // 写入转换后的内容
        if Length(TargetBytes) > 0 then
          TargetStream.WriteBuffer(TargetBytes[0], Length(TargetBytes));
          
        Result := True;
      finally
        TargetStream.Free;
      end;
    finally
      SourceStream.Free;
    end;
  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;
end;

// 测试编码转换
procedure TestEncodingConversion(var MD: TStringList);
var
  TestFiles: TArray<string>;
  TestEncodings: TArray<string>;
  SourceFile, TargetFile: string;
  SourceEncoding, TargetEncoding: string;
  Success: Boolean;
  I, J: Integer;
  Results: TArray<TConversionTestResult>;
  TestDir: string;
  TestFolder: string;
  FileInfo: TSearchRec;
begin
  MD.Add('## 编码转换测试');
  MD.Add('');
  MD.Add('以下是从不同编码向其他编码转换的测试结果:');
  MD.Add('');
  MD.Add('| 源文件 | 源编码 | 目标编码 | 转换结果 |');
  MD.Add('|--------|--------|----------|----------|');
  
  // 源文件目录
  TestDir := 'from';
  TestFolder := ExtractFilePath(ParamStr(0)) + TestDir;
  
  // 测试的编码类型
  TestEncodings := ['UTF-8 with BOM', 'UTF-8 without BOM', 'UTF-16LE', 'UTF-16BE', 'GBK', 'GB2312'];
  
  // 获取测试文件
  TestFiles := [];
  if DirectoryExists(TestDir) then
  begin
    if FindFirst(TestDir + '\*.*', faAnyFile, FileInfo) = 0 then
    begin
      repeat
        if (FileInfo.Attr and faDirectory) = 0 then
          TestFiles := TestFiles + [TestDir + '\' + FileInfo.Name];
      until FindNext(FileInfo) <> 0;
      FindClose(FileInfo);
    end;
  end;
  
  // 如果找不到测试文件，使用一些示例文件
  if Length(TestFiles) = 0 then
  begin
    if DirectoryExists('UcsExamples') then
    begin
      if FindFirst('UcsExamples\*.*', faAnyFile, FileInfo) = 0 then
      begin
        repeat
          if (FileInfo.Attr and faDirectory) = 0 then
            TestFiles := TestFiles + ['UcsExamples\' + FileInfo.Name];
          if Length(TestFiles) >= 5 then Break; // 最多取5个文件测试
        until FindNext(FileInfo) <> 0;
        FindClose(FileInfo);
      end;
    end;
  end;
  
  Results := [];
  
  // 为每个测试文件和编码组合创建转换测试
  for I := 0 to Min(4, Length(TestFiles) - 1) do // 仅测试前5个文件
  begin
    SourceFile := TestFiles[I];
    SourceEncoding := DetectFileEncoding(SourceFile);
    
    for J := 0 to Length(TestEncodings) - 1 do
    begin
      TargetEncoding := TestEncodings[J];
      if TargetEncoding <> SourceEncoding then
      begin
        TargetFile := 'to\' + ExtractFileName(SourceFile) + '.' + TargetEncoding + '.txt';
        
        // 确保目标目录存在
        if not DirectoryExists('to') then
          CreateDir('to');
        
        var Result: TConversionTestResult;
        Result.SourceFile := ExtractFileName(SourceFile);
        Result.TargetFile := ExtractFileName(TargetFile);
        Result.SourceEncoding := SourceEncoding;
        Result.TargetEncoding := TargetEncoding;
        
        try
          Result.Success := ConvertFileEncoding(SourceFile, TargetFile, SourceEncoding, TargetEncoding);
          Result.ErrorMessage := '';
        except
          on E: Exception do
          begin
            Result.Success := False;
            Result.ErrorMessage := E.Message;
          end;
        end;
        
        Results := Results + [Result];
        
        // 添加到Markdown
        MD.Add(Format('| %s | %s | %s | %s |', 
          [Result.SourceFile, Result.SourceEncoding, Result.TargetEncoding, 
           IfThen(Result.Success, '成功', '失败' + IfThen(Result.ErrorMessage <> '', ' - ' + Result.ErrorMessage, ''))]));
      end;
    end;
  end;
  
  MD.Add('');
end;

// 测试编码检测
procedure TestEncodingDetection(var MD: TStringList);
var
  TestDirs: array[0..2] of string;
  Dir, FileName: string;
  FileList: TStringDynArray;
  TestResults: TArray<TEncodingTestResult>;
  TestResult: TEncodingTestResult;
  FileInfo: TFileInfo;
  I: Integer;
begin
  TestDirs[0] := 'files';
  TestDirs[1] := 'from';
  TestDirs[2] := 'UcsExamples';
  
  MD.Add('# 文件编码检测和转换测试结果');
  MD.Add('');
  MD.Add('本测试使用JCL库检测和转换各种编码格式的文件。');
  MD.Add('');
  MD.Add('## 编码检测测试');
  MD.Add('');
  
  TestResults := [];
  
  for Dir in TestDirs do
  begin
    MD.Add('### ' + Dir + ' 目录');
    MD.Add('');
    MD.Add('| 文件名 | 检测到的编码 | 是否有BOM | 文件大小 |');
    MD.Add('|--------|--------------|-----------|----------|');
    
    if not DirectoryExists(Dir) then
    begin
      MD.Add('| 目录不存在 | - | - | - |');
      MD.Add('');
      Continue;
    end;
    
    try
      FileList := TDirectory.GetFiles(Dir);
      
      // 仅测试前20个文件（如果文件很多的话）
      for I := 0 to Min(19, Length(FileList) - 1) do
      begin
        FileName := FileList[I];
        TestResult.FileName := ExtractFileName(FileName);
        TestResult.FilePath := FileName;
        TestResult.DetectedEncoding := DetectFileEncoding(FileName);
        TestResult.HasBOM := DetectBOM(FileName) <> bomAnsi;
        
        // 获取文件大小
        FileInfo := GetFileInfo(FileName);
        TestResult.FileSize := FileInfo.Size;
        
        TestResults := TestResults + [TestResult];
        
        // 添加到Markdown
        MD.Add(Format('| %s | %s | %s | %d 字节 |', 
          [TestResult.FileName, TestResult.DetectedEncoding, 
           BoolToStr(TestResult.HasBOM, '是', '否'), TestResult.FileSize]));
      end;
      
      MD.Add('');
    except
      on E: Exception do
      begin
        MD.Add('| 处理目录时出错 | ' + E.Message + ' | - | - |');
        MD.Add('');
      end;
    end;
  end;
end;

// 运行自动测试
procedure RunAutomatedTests;
var
  MD: TStringList;
begin
  MD := TStringList.Create;
  try
    // 测试编码检测
    TestEncodingDetection(MD);
    
    // 测试编码转换
    TestEncodingConversion(MD);
    
    // 保存测试结果到Markdown文件
    MD.SaveToFile('tests.md', TEncoding.UTF8);
  finally
    MD.Free;
  end;
end;

end. 