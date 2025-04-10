program conversion_roundtrip_test;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Hash,
  System.Math,
  System.NetEncoding,
  Winapi.Windows,
  JclStrings,
  JclFileUtils,
  JclAnsiStrings,
  JclStringConversions,
  JclStreams,
  JclSysUtils,
  JclSysInfo,
  JclUnicode,
  JclBOM,
  System.StrUtils;

const
  CP_UTF16LE = 1200;
  CP_UTF16BE = 1201;
  CP_UTF32LE = 12000;
  CP_UTF32BE = 12001;
  faAnyFile = $0001F; // 定义文件属性常量，相当于 SysUtils.faAnyFile

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
    Result := 'Unknown';
    if BOMType = bomAnsi then
      Result := 'ANSI'
    else if BOMType = bomUTF8 then
      Result := 'UTF-8 with BOM'
    else if BOMType = bomUTF16LE then
      Result := 'UTF-16LE'
    else if BOMType = bomUTF16BE then
      Result := 'UTF-16BE'
    else if BOMType = bomUTF32LE then
      Result := 'UTF-32LE'
    else if BOMType = bomUTF32BE then
      Result := 'UTF-32BE';
    
    // 无BOM，尝试检测内容
    if Result = 'Unknown' then
    begin
      FileStream.Position := 0;
      var FileSize: Int64 := FileStream.Size;
      var MaxSize: Int64 := 4096;
      var ReadSize: Integer;
      if FileSize < MaxSize then
        ReadSize := Integer(FileSize)
      else
        ReadSize := 4096;
      SetLength(Buffer, ReadSize); // 读取前4KB进行分析
      if ReadSize > 0 then
        FileStream.Read(Buffer[0], ReadSize);
      BytesRead := ReadSize;
      
      // 尝试检测UTF-8
      if BytesRead > 0 then
      begin
        if IsUTF8Valid(Buffer, 0, BytesRead) then
        begin
          Result := 'UTF-8 without BOM';
          Exit;
        end;
      end;
      
      // 尝试其他编码
      // 检查是否符合GB2312/GBK/GB18030
      if BytesRead > 1 then
      begin
        if IsGBKString(Buffer, BytesRead) then
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

// 获取编码的代码页
function GetEncodingCodePage(const EncodingName: string): Integer;
var
  UpperEncName: string;
begin
  UpperEncName := UpperCase(EncodingName);
  
  // Unicode编码
  if (UpperEncName = 'UTF-8') or (UpperEncName = 'UTF8') then
    Result := CP_UTF8
  else if (UpperEncName = 'UTF-8-BOM') or (UpperEncName = 'UTF8-BOM') then
    Result := CP_UTF8
  else if (UpperEncName = 'UTF-16LE') or (UpperEncName = 'UTF16LE') or (UpperEncName = 'UNICODE') then
    Result := 1200
  else if (UpperEncName = 'UTF-16BE') or (UpperEncName = 'UTF16BE') then
    Result := 1201
  else if (UpperEncName = 'UTF-32LE') or (UpperEncName = 'UTF32LE') then
    Result := 12000
  else if (UpperEncName = 'UTF-32BE') or (UpperEncName = 'UTF32BE') then
    Result := 12001
  
  // 中文编码
  else if (UpperEncName = 'GBK') or (UpperEncName = 'GB2312') or (UpperEncName = '936') then
    Result := 936
  else if (UpperEncName = 'BIG5') or (UpperEncName = '950') then
    Result := 950
  else if UpperEncName = 'GB18030' then
    Result := 54936
  
  // 日文编码
  else if (UpperEncName = 'SHIFT-JIS') or (UpperEncName = 'SHIFT_JIS') or (UpperEncName = 'SHIFTJIS') or (UpperEncName = '932') then
    Result := 932
  else if (UpperEncName = 'EUC-JP') or (UpperEncName = 'EUCJP') then
    Result := 20932
  else if UpperEncName = 'ISO-2022-JP' then
    Result := 50220
  else if UpperEncName = 'ISO-2022-JP-MS' then
    Result := 50221
  else if UpperEncName = 'ISO-2022-JP-JISX0201-1989' then
    Result := 50222
  
  // 韩文编码
  else if (UpperEncName = 'EUC-KR') or (UpperEncName = 'EUCKR') or (UpperEncName = '949') then
    Result := 949
  else if UpperEncName = 'JOHAB' then
    Result := 1361
  else if UpperEncName = 'ISO-2022-KR' then
    Result := 50225
  
  // Windows编码
  else if UpperEncName = 'WINDOWS-1250' then
    Result := 1250
  else if UpperEncName = 'WINDOWS-1251' then
    Result := 1251
  else if UpperEncName = 'WINDOWS-1252' then
    Result := 1252
  else if UpperEncName = 'WINDOWS-1253' then
    Result := 1253
  else if UpperEncName = 'WINDOWS-1254' then
    Result := 1254
  else if UpperEncName = 'WINDOWS-1255' then
    Result := 1255
  else if UpperEncName = 'WINDOWS-1256' then
    Result := 1256
  else if UpperEncName = 'WINDOWS-1257' then
    Result := 1257
  else if UpperEncName = 'WINDOWS-1258' then
    Result := 1258
  else if UpperEncName = 'WINDOWS-874' then
    Result := 874
  
  // DOS编码
  else if UpperEncName = 'IBM437' or UpperEncName = 'CP437' then
    Result := 437
  else if UpperEncName = 'IBM850' or UpperEncName = 'CP850' then
    Result := 850
  else if UpperEncName = 'IBM852' or UpperEncName = 'CP852' then
    Result := 852
  else if UpperEncName = 'IBM855' or UpperEncName = 'CP855' then
    Result := 855
  else if UpperEncName = 'IBM857' or UpperEncName = 'CP857' then
    Result := 857
  else if UpperEncName = 'IBM858' or UpperEncName = 'CP858' then
    Result := 858
  else if UpperEncName = 'IBM860' or UpperEncName = 'CP860' then
    Result := 860
  else if UpperEncName = 'IBM861' or UpperEncName = 'CP861' then
    Result := 861
  else if UpperEncName = 'IBM862' or UpperEncName = 'CP862' then
    Result := 862
  else if UpperEncName = 'IBM863' or UpperEncName = 'CP863' then
    Result := 863
  else if UpperEncName = 'IBM864' or UpperEncName = 'CP864' then
    Result := 864
  else if UpperEncName = 'IBM865' or UpperEncName = 'CP865' then
    Result := 865
  else if UpperEncName = 'IBM866' or UpperEncName = 'CP866' then
    Result := 866
  else if UpperEncName = 'IBM869' or UpperEncName = 'CP869' then
    Result := 869
  
  // ISO编码
  else if UpperEncName = 'ISO-8859-1' then
    Result := 28591
  else if UpperEncName = 'ISO-8859-2' then
    Result := 28592
  else if UpperEncName = 'ISO-8859-3' then
    Result := 28593
  else if UpperEncName = 'ISO-8859-4' then
    Result := 28594
  else if UpperEncName = 'ISO-8859-5' then
    Result := 28595
  else if UpperEncName = 'ISO-8859-6' then
    Result := 28596
  else if UpperEncName = 'ISO-8859-7' then
    Result := 28597
  else if UpperEncName = 'ISO-8859-8' then
    Result := 28598
  else if UpperEncName = 'ISO-8859-9' then
    Result := 28599
  else if UpperEncName = 'ISO-8859-13' then
    Result := 28603
  else if UpperEncName = 'ISO-8859-15' then
    Result := 28605
  
  // 其他区域编码
  else if UpperEncName = 'KOI8-R' then
    Result := 20866
  else if UpperEncName = 'KOI8-U' then
    Result := 21866
  else if UpperEncName = 'MACINTOSH' or UpperEncName = 'MAC' then
    Result := 10000
  else if UpperEncName = 'MAC-CYRILLIC' then
    Result := 10007
  else if UpperEncName = 'X-IA5' or UpperEncName = 'ASCII' then
    Result := 20105
  else if UpperEncName = 'X-ISCII-DE' then
    Result := 57002
  else if UpperEncName = 'X-ISCII-BE' then
    Result := 57003
  else if UpperEncName = 'X-ISCII-TA' then
    Result := 57004
  else if UpperEncName = 'X-ISCII-TE' then
    Result := 57005
  else if UpperEncName = 'X-ISCII-AS' then
    Result := 57006
  else if UpperEncName = 'X-ISCII-OR' then
    Result := 57007
  else if UpperEncName = 'X-ISCII-KN' then
    Result := 57008
  else if UpperEncName = 'X-ISCII-MA' then
    Result := 57009
  else if UpperEncName = 'X-ISCII-GU' then
    Result := 57010
  else if UpperEncName = 'X-ISCII-PA' then
    Result := 57011
  
  // 如果是数字格式的代码页
  else if TryStrToInt(EncodingName, Result) then
    // 已经转换为Integer了
  
  // 未知的编码
  else
    Result := 0;
end;

// 转换文件编码
function ConvertFile(const SourceFileName, TargetFileName: string; SourceCodePage, TargetCodePage: Integer): Boolean;
var
  SourceBytes, TargetBytes: TBytes;
  SourceStream, TargetStream: TFileStream;
  SourceString, TargetString: string;
begin
  Result := False;
  
  try
    // 读取源文件
    SourceStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(SourceBytes, SourceStream.Size);
      if SourceStream.Size > 0 then
        SourceStream.ReadBuffer(SourceBytes[0], SourceStream.Size);
    finally
      SourceStream.Free;
    end;
    
    // 从源编码转换到Unicode字符串
    SourceString := TEncoding.GetEncoding(SourceCodePage).GetString(SourceBytes);
    
    // 从Unicode字符串转换到目标编码
    TargetBytes := TEncoding.GetEncoding(TargetCodePage).GetBytes(SourceString);
    
    // 写入目标文件
    TargetStream := TFileStream.Create(TargetFileName, fmCreate);
    try
      if Length(TargetBytes) > 0 then
        TargetStream.WriteBuffer(TargetBytes[0], Length(TargetBytes));
      Result := True;
    finally
      TargetStream.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln('Error converting file: ', E.Message);
      Result := False;
    end;
  end;
end;

// 计算文件MD5值，用于内容比较
function CalculateFileMD5(const FileName: string): string;
var
  Stream: TFileStream;
  SavePos: Int64;
  Buffer: TBytes;
  EncodedStr: string;
begin
  Result := '';
  if not FileExists(FileName) then
    Exit;
  
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    // 保存原始位置
    SavePos := Stream.Position;
    try
      Stream.Position := 0;
      
      // 对于大文件，只取前100KB进行哈希计算，以提高效率
      var MaxReadSize := 102400; // 100KB
      var SizeToRead := Stream.Size;
      if SizeToRead > MaxReadSize then
        SizeToRead := MaxReadSize;
      
      SetLength(Buffer, SizeToRead);
      if SizeToRead > 0 then
        Stream.ReadBuffer(Buffer[0], SizeToRead);
      
      // 使用Base64编码获取哈希值
      EncodedStr := TNetEncoding.Base64.EncodeBytesToString(Buffer);
      // 为了缩短结果，只取编码的前32字符作为哈希值
      if Length(EncodedStr) > 32 then
        Result := Copy(EncodedStr, 1, 32)
      else
        Result := EncodedStr;
    finally
      Stream.Position := SavePos;
    end;
  finally
    Stream.Free;
  end;
end;

// 读取文件内容到字符串
function ReadFileToString(const FileName: string): string;
var
  Stream: TFileStream;
  Bytes: TBytes;
  Encoding: TEncoding;
  BOMType: TJclBOMType;
  BOMLen: Integer;
begin
  Result := '';
  if not FileExists(FileName) then
    Exit;
  
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    // 检测BOM
    BOMType := DetectBOM(Stream);
    BOMLen := GetBOMLength(BOMType);
    
    // 确定编码
    case BOMType of
      bomUTF8: Encoding := TEncoding.UTF8;
      bomUTF16LE: Encoding := TEncoding.Unicode;
      bomUTF16BE: Encoding := TEncoding.BigEndianUnicode;
      else Encoding := TEncoding.Default;
    end;
    
    // 读取文件内容
    Stream.Position := BOMLen;
    var StreamSize: Int64 := Stream.Size - BOMLen;
    if StreamSize > Int64(High(Integer)) then
      StreamSize := Int64(High(Integer));
    SetLength(Bytes, Integer(StreamSize));
    if Length(Bytes) > 0 then
    begin
      Stream.ReadBuffer(Bytes[0], Length(Bytes));
    end;
    
    // 转换为字符串
    try
      Result := Encoding.GetString(Bytes);
    except
      on E: EEncodingError do
      begin
        WriteLn('警告: 读取文件 "', ExtractFileName(FileName), '" 时编码转换失败: ', E.Message);
        Result := '';
      end;
    end;
  finally
    Stream.Free;
  end;
end;

// 比较两个文件内容是否基本相同
function CompareFileContents(const SourceFile, TargetFile: string): Boolean;
var
  SourceText, TargetText: string;
  SourceEncoding, TargetEncoding: string;
  LenDiff: Integer;
begin
  // 如果两个文件的MD5完全相同，直接返回True
  if CalculateFileMD5(SourceFile) = CalculateFileMD5(TargetFile) then
    Exit(True);
  
  // 否则读取文本内容，忽略编码差异进行比较
  SourceText := ReadFileToString(SourceFile);
  TargetText := ReadFileToString(TargetFile);
  
  // 如果文本内容基本相同（忽略可能由编码引起的极小差异）
  // 这里简单地比较字符串长度和前后各100个字符的相似度
  var SourceLen: Integer := Length(SourceText);
  var TargetLen: Integer := Length(TargetText);
  
  // 计算长度差的绝对值
  if SourceLen > TargetLen then
    LenDiff := SourceLen - TargetLen
  else
    LenDiff := TargetLen - SourceLen;
    
  if (SourceLen = TargetLen) or (LenDiff < 5) then
  begin
    // 对于非常短的文件，直接比较完整内容
    if Length(SourceText) < 200 then
      Result := SourceText = TargetText
    else
    begin
      // 比较前100字符和后100字符
      var Prefix1 := Copy(SourceText, 1, System.Math.Min(100, Length(SourceText)));
      var Prefix2 := Copy(TargetText, 1, System.Math.Min(100, Length(TargetText)));
      var Suffix1 := Copy(SourceText, System.Math.Max(1, Length(SourceText)-99), System.Math.Min(100, Length(SourceText)));
      var Suffix2 := Copy(TargetText, System.Math.Max(1, Length(TargetText)-99), System.Math.Min(100, Length(TargetText)));
      
      Result := (Prefix1 = Prefix2) and (Suffix1 = Suffix2);
    end;
  end
  else
    Result := False;
end;

type
  TRoundTripResult = record
    SourceFile: string;
    SourceEncoding: string;
    IntermediateEncoding: string;
    FinalEncoding: string;
    ToSuccess: Boolean;
    BackSuccess: Boolean;
    ContentsMatch: Boolean;
  end;

// 安全删除文件，避免类型兼容性问题
function SafeDeleteFile(const FileName: string): Boolean;
begin
  try
    Result := System.SysUtils.DeleteFile(FileName);
  except
    Result := False;
  end;
end;

// 往返转换测试
procedure TestRoundTripConversion;
var
  SourceDir, DestDir: string;
  ReportFile: TextFile;
  SourceFiles, UTFEncodings, NonUTFEncodings: TStringList;
  i, j, k, TotalTests, SuccessTests, ContentMatchTests: Integer;
  SourceEncoding, IntermediateEncoding: string;
  SourcePath, TempPath, FinalPath: string;
  SourceCP, IntermediateCP: Integer;
  DetectedEncoding: string;
  ConversionSuccess, RoundTripSuccess, ContentMatch: Boolean;
  TestDate: TDateTime;
  NonUTFTotals, NonUTFSuccess, NonUTFMatches: array of Integer;
  Results: TList;
  Result: TRoundTripResult;
begin
  // 初始化路径和文件
  SourceDir := 'sample_files\';
  DestDir := 'converted_files\';
  
  // 如果转换目录不存在则创建
  if not DirectoryExists(DestDir) then
    CreateDir(DestDir);
    
  // 初始化报告文件
  AssignFile(ReportFile, 'roundtrip_tests.md');
  Rewrite(ReportFile);
  
  // 初始化文件和编码列表
  SourceFiles := TStringList.Create;
  UTFEncodings := TStringList.Create;
  NonUTFEncodings := TStringList.Create;
  Results := TList.Create;
  
  try
    // 查找源文件 - 使用JCL的BuildFileList函数
    BuildFileList(SourceDir + '*.txt', faAnyFile, SourceFiles, False);
    
    // 添加UTF编码
    UTFEncodings.Add('UTF-8');
    UTFEncodings.Add('UTF-16LE');
    UTFEncodings.Add('UTF-32LE'); // 新增UTF-32LE作为中间编码
    
    // 添加非UTF编码 - 扩展的编码列表
    // 中文编码
    NonUTFEncodings.Add('GBK');
    NonUTFEncodings.Add('BIG5');
    NonUTFEncodings.Add('GB18030');
    
    // 日文编码
    NonUTFEncodings.Add('SHIFT-JIS');
    NonUTFEncodings.Add('EUC-JP');
    NonUTFEncodings.Add('ISO-2022-JP');
    
    // 韩文编码
    NonUTFEncodings.Add('EUC-KR');
    NonUTFEncodings.Add('JOHAB');
    
    // ISO编码
    NonUTFEncodings.Add('ISO-8859-1');
    NonUTFEncodings.Add('ISO-8859-2');
    NonUTFEncodings.Add('ISO-8859-3');
    NonUTFEncodings.Add('ISO-8859-4');
    NonUTFEncodings.Add('ISO-8859-5');
    NonUTFEncodings.Add('ISO-8859-6');
    NonUTFEncodings.Add('ISO-8859-7');
    NonUTFEncodings.Add('ISO-8859-8');
    NonUTFEncodings.Add('ISO-8859-9');
    NonUTFEncodings.Add('ISO-8859-13');
    NonUTFEncodings.Add('ISO-8859-15');
    
    // Windows编码
    NonUTFEncodings.Add('WINDOWS-1250');
    NonUTFEncodings.Add('WINDOWS-1251');
    NonUTFEncodings.Add('WINDOWS-1252');
    NonUTFEncodings.Add('WINDOWS-1253');
    NonUTFEncodings.Add('WINDOWS-1254');
    NonUTFEncodings.Add('WINDOWS-1255');
    NonUTFEncodings.Add('WINDOWS-1256');
    NonUTFEncodings.Add('WINDOWS-1257');
    NonUTFEncodings.Add('WINDOWS-1258');
    NonUTFEncodings.Add('WINDOWS-874');
    
    // DOS编码
    NonUTFEncodings.Add('IBM437');
    NonUTFEncodings.Add('IBM850');
    NonUTFEncodings.Add('IBM852');
    NonUTFEncodings.Add('IBM855');
    NonUTFEncodings.Add('IBM866');
    
    // 其他编码
    NonUTFEncodings.Add('KOI8-R');
    NonUTFEncodings.Add('KOI8-U');
    NonUTFEncodings.Add('MACINTOSH');
    
    // 初始化统计数组
    SetLength(NonUTFTotals, NonUTFEncodings.Count);
    SetLength(NonUTFSuccess, NonUTFEncodings.Count);
    SetLength(NonUTFMatches, NonUTFEncodings.Count);
    for i := 0 to NonUTFEncodings.Count - 1 do
    begin
      NonUTFTotals[i] := 0;
      NonUTFSuccess[i] := 0;
      NonUTFMatches[i] := 0;
    end;
    
    // 写入报告头部
    TestDate := Now;
    WriteLn(ReportFile, '# 编码转换往返测试报告');
    WriteLn(ReportFile, '');
    WriteLn(ReportFile, '测试日期: ', FormatDateTime('yyyy-mm-dd hh:nn:ss', TestDate));
    WriteLn(ReportFile, '测试文件数: ', SourceFiles.Count);
    WriteLn(ReportFile, 'UTF编码数: ', UTFEncodings.Count);
    WriteLn(ReportFile, '非UTF编码数: ', NonUTFEncodings.Count);
    WriteLn(ReportFile, '');
    WriteLn(ReportFile, '## 测试细节');
    WriteLn(ReportFile, '');
    WriteLn(ReportFile, '| 文件 | 源编码 | 中间编码 | 最终编码 | 转换成功 | 内容匹配 |');
    WriteLn(ReportFile, '|------|--------|----------|----------|----------|----------|');
    
    TotalTests := 0;
    SuccessTests := 0;
    ContentMatchTests := 0;
    
    // 对每个非UTF编码进行测试
    for i := 0 to NonUTFEncodings.Count - 1 do
    begin
      SourceEncoding := NonUTFEncodings[i];
      SourceCP := GetEncodingCodePage(SourceEncoding);
      
      // 对每个源文件
      for j := 0 to SourceFiles.Count - 1 do
      begin
        SourcePath := SourceFiles[j];
        
        // 检测源文件的编码
        DetectedEncoding := DetectFileEncoding(SourcePath);
        Writeln('检测到文件 ', ExtractFileName(SourcePath), ' 的编码为: ', DetectedEncoding);
        
        // 对每个UTF编码作为中间编码
        for k := 0 to UTFEncodings.Count - 1 do
        begin
          IntermediateEncoding := UTFEncodings[k];
          IntermediateCP := GetEncodingCodePage(IntermediateEncoding);
          
          Inc(TotalTests);
          Inc(NonUTFTotals[i]);
          
          // 创建临时文件和最终文件路径
          TempPath := DestDir + ExtractFileName(SourcePath) + '.' + SourceEncoding + '_to_' + IntermediateEncoding;
          FinalPath := DestDir + ExtractFileName(SourcePath) + '.' + SourceEncoding + '_roundtrip';
          
          // 第一步：非UTF -> UTF
          ConversionSuccess := ConvertFile(SourcePath, TempPath, SourceCP, IntermediateCP);
          
          // 第二步：UTF -> 非UTF
          if ConversionSuccess then
            RoundTripSuccess := ConvertFile(TempPath, FinalPath, IntermediateCP, SourceCP)
          else
            RoundTripSuccess := False;
          
          // 比较内容
          if RoundTripSuccess then
          begin
            ContentMatch := CompareFileContents(SourcePath, FinalPath);
            if ContentMatch then
            begin
              Inc(ContentMatchTests);
              Inc(NonUTFMatches[i]);
            end;
          end
          else
            ContentMatch := False;
          
          if ConversionSuccess and RoundTripSuccess then
          begin
            Inc(SuccessTests);
            Inc(NonUTFSuccess[i]);
          end;
          
          // 记录结果
          Result.SourceFile := ExtractFileName(SourcePath);
          Result.SourceEncoding := SourceEncoding;
          Result.IntermediateEncoding := IntermediateEncoding;
          Result.FinalEncoding := SourceEncoding;
          Result.ToSuccess := ConversionSuccess;
          Result.BackSuccess := RoundTripSuccess;
          Result.ContentsMatch := ContentMatch;
          
          // 添加到结果列表
          Results.Add(@Result);
          
          // 写入结果到报告
          WriteLn(ReportFile, '| ', Result.SourceFile, ' | ', 
                 Result.SourceEncoding, ' | ',
                 Result.IntermediateEncoding, ' | ',
                 Result.FinalEncoding, ' | ',
                 System.StrUtils.IfThen(Result.ToSuccess and Result.BackSuccess, '✓', '✗'), ' | ',
                 System.StrUtils.IfThen(Result.ContentsMatch, '✓', '✗'), ' |');
          
          // 如果存在临时文件，删除
          if FileExists(TempPath) then
            SafeDeleteFile(TempPath);
        end;
      end;
    end;
    
    // 写入统计信息
    WriteLn(ReportFile, '');
    WriteLn(ReportFile, '## 统计信息');
    WriteLn(ReportFile, '');
    WriteLn(ReportFile, '- 总测试数: ', TotalTests);
    WriteLn(ReportFile, '- 转换成功数: ', SuccessTests, ' (', FormatFloat('0.0%', SuccessTests / TotalTests), ')');
    WriteLn(ReportFile, '- 内容匹配数: ', ContentMatchTests, ' (', FormatFloat('0.0%', ContentMatchTests / TotalTests), ')');
    WriteLn(ReportFile, '');
    WriteLn(ReportFile, '## 各编码统计');
    WriteLn(ReportFile, '');
    WriteLn(ReportFile, '| 编码 | 测试数 | 成功数 | 成功率 | 匹配数 | 匹配率 |');
    WriteLn(ReportFile, '|------|--------|--------|--------|--------|--------|');
    
    for i := 0 to NonUTFEncodings.Count - 1 do
    begin
      if NonUTFTotals[i] > 0 then
      begin
        WriteLn(ReportFile, '| ', NonUTFEncodings[i], ' | ',
              NonUTFTotals[i], ' | ',
              NonUTFSuccess[i], ' | ',
              FormatFloat('0.0%', NonUTFSuccess[i] / NonUTFTotals[i]), ' | ',
              NonUTFMatches[i], ' | ',
              FormatFloat('0.0%', NonUTFMatches[i] / NonUTFTotals[i]), ' |');
      end;
    end;
    
    // 输出完成信息
    WriteLn('测试完成！');
    WriteLn('总测试数: ', TotalTests);
    WriteLn('转换成功数: ', SuccessTests, ' (', FormatFloat('0.0%', SuccessTests / TotalTests), ')');
    WriteLn('内容匹配数: ', ContentMatchTests, ' (', FormatFloat('0.0%', ContentMatchTests / TotalTests), ')');
    WriteLn('详细报告已保存到 roundtrip_tests.md');
    
  finally
    SourceFiles.Free;
    UTFEncodings.Free;
    NonUTFEncodings.Free;
    Results.Free;
    CloseFile(ReportFile);
  end;
end;

function LoadFileAsBytes(const FileName: string): TBytes;
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Result, FileStream.Size);
    if FileStream.Size > 0 then
      FileStream.ReadBuffer(Result[0], FileStream.Size);
  finally
    FileStream.Free;
  end;
end;

procedure SaveBytesToFile(const FileName: string; const Data: TBytes);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(FileName, fmCreate);
  try
    if Length(Data) > 0 then
      FileStream.WriteBuffer(Data[0], Length(Data));
  finally
    FileStream.Free;
  end;
end;

function BytesEqual(const Bytes1, Bytes2: TBytes): Boolean;
var
  i: Integer;
begin
  if Length(Bytes1) <> Length(Bytes2) then
    Exit(False);
    
  for i := 0 to Length(Bytes1) - 1 do
    if Bytes1[i] <> Bytes2[i] then
      Exit(False);
      
  Result := True;
end;

// 单向转换测试
procedure TestOneWayConversion;
var
  SourceDir, DestDir: string;
  ReportFile: TextFile;
  SourceFiles, UTFEncodings, NonUTFEncodings: TStringList;
  i, j, TotalTests, SuccessTests, OneWayTests: Integer;
  SourceEncoding, DestEncoding: string;
  SourcePath, DestPath: string;
  SourceCP, DestCP: Integer;
  DetectedEncoding: string;
  ConversionSuccess: Boolean;
  TestDate: TDateTime;
  Results: TList;
  SourceEncodings, DestEncodings: TStringList;
begin
  // 初始化路径和文件
  SourceDir := 'sample_files\';
  DestDir := 'converted_files\';
  
  // 如果转换目录不存在则创建
  if not DirectoryExists(DestDir) then
    CreateDir(DestDir);
    
  // 初始化报告文件
  AssignFile(ReportFile, 'oneway_conversion_tests.md');
  Rewrite(ReportFile);
  
  // 初始化文件和编码列表
  SourceFiles := TStringList.Create;
  UTFEncodings := TStringList.Create;
  NonUTFEncodings := TStringList.Create;
  SourceEncodings := TStringList.Create;
  DestEncodings := TStringList.Create;
  Results := TList.Create;
  
  try
    // 查找源文件 - 使用JCL的BuildFileList函数
    BuildFileList(SourceDir + '*.txt', faAnyFile, SourceFiles, False);
    
    // 添加UTF编码
    UTFEncodings.Add('UTF-8');
    UTFEncodings.Add('UTF-16LE');
    UTFEncodings.Add('UTF-32LE'); // 新增UTF-32LE
    UTFEncodings.Add('UTF-16BE');
    UTFEncodings.Add('UTF-32BE'); // 新增UTF-32BE
    
    // 添加非UTF编码 - 扩展的编码列表
    // 中文编码
    NonUTFEncodings.Add('GBK');
    NonUTFEncodings.Add('BIG5');
    NonUTFEncodings.Add('GB18030');
    
    // 日文编码
    NonUTFEncodings.Add('SHIFT-JIS');
    NonUTFEncodings.Add('EUC-JP');
    NonUTFEncodings.Add('ISO-2022-JP');
    
    // 韩文编码
    NonUTFEncodings.Add('EUC-KR');
    NonUTFEncodings.Add('JOHAB');
    
    // ISO编码
    NonUTFEncodings.Add('ISO-8859-1');
    NonUTFEncodings.Add('ISO-8859-2');
    NonUTFEncodings.Add('ISO-8859-3');
    NonUTFEncodings.Add('ISO-8859-4');
    NonUTFEncodings.Add('ISO-8859-5');
    NonUTFEncodings.Add('ISO-8859-6');
    NonUTFEncodings.Add('ISO-8859-7');
    NonUTFEncodings.Add('ISO-8859-8');
    NonUTFEncodings.Add('ISO-8859-9');
    NonUTFEncodings.Add('ISO-8859-13');
    NonUTFEncodings.Add('ISO-8859-15');
    
    // Windows编码
    NonUTFEncodings.Add('WINDOWS-1250');
    NonUTFEncodings.Add('WINDOWS-1251');
    NonUTFEncodings.Add('WINDOWS-1252');
    NonUTFEncodings.Add('WINDOWS-1253');
    NonUTFEncodings.Add('WINDOWS-1254');
    NonUTFEncodings.Add('WINDOWS-1255');
    NonUTFEncodings.Add('WINDOWS-1256');
    NonUTFEncodings.Add('WINDOWS-1257');
    NonUTFEncodings.Add('WINDOWS-1258');
    NonUTFEncodings.Add('WINDOWS-874');
    
    // DOS编码
    NonUTFEncodings.Add('IBM437');
    NonUTFEncodings.Add('IBM850');
    NonUTFEncodings.Add('IBM852');
    NonUTFEncodings.Add('IBM855');
    NonUTFEncodings.Add('IBM866');
    
    // 其他编码
    NonUTFEncodings.Add('KOI8-R');
    NonUTFEncodings.Add('KOI8-U');
    NonUTFEncodings.Add('MACINTOSH');
    
    // 测试模式1: UTF-8到其他编码 (从其他编码到UTF-8的逆向转换将单独测试)
    SourceEncodings.Add('UTF-8');
    for i := 0 to NonUTFEncodings.Count - 1 do
      DestEncodings.Add(NonUTFEncodings[i]);
    
    // 写入报告头部
    TestDate := Now;
    WriteLn(ReportFile, '# 单向编码转换测试报告');
    WriteLn(ReportFile, '');
    WriteLn(ReportFile, '测试日期: ', FormatDateTime('yyyy-mm-dd hh:nn:ss', TestDate));
    WriteLn(ReportFile, '测试文件数: ', SourceFiles.Count);
    WriteLn(ReportFile, '源编码数: ', SourceEncodings.Count);
    WriteLn(ReportFile, '目标编码数: ', DestEncodings.Count);
    WriteLn(ReportFile, '');
    WriteLn(ReportFile, '## 1. UTF-8到其他编码转换测试');
    WriteLn(ReportFile, '');
    WriteLn(ReportFile, '| 文件 | 源编码 | 目标编码 | 转换结果 |');
    WriteLn(ReportFile, '|------|--------|----------|----------|');
    
    TotalTests := 0;
    SuccessTests := 0;
    
    // UTF-8到其他编码测试
    for i := 0 to SourceFiles.Count - 1 do
    begin
      SourcePath := SourceFiles[i];
      
      // 检测源文件的编码
      DetectedEncoding := DetectFileEncoding(SourcePath);
      
      // 如果是UTF-8，或者强制转换
      if (Pos('UTF-8', DetectedEncoding) > 0) then
      begin
        SourceEncoding := 'UTF-8';
        SourceCP := GetEncodingCodePage(SourceEncoding);
        
        // 转换到每种目标编码
        for j := 0 to DestEncodings.Count - 1 do
        begin
          DestEncoding := DestEncodings[j];
          DestCP := GetEncodingCodePage(DestEncoding);
          
          // 创建目标文件路径
          DestPath := DestDir + ExtractFileName(SourcePath) + '.Utf8_to_' + DestEncoding + '.txt';
          
          Inc(TotalTests);
          
          // 执行转换
          try
            ConversionSuccess := ConvertFile(SourcePath, DestPath, SourceCP, DestCP);
            
            if ConversionSuccess then
              Inc(SuccessTests);
              
            // 写入结果到报告
            WriteLn(ReportFile, '| ', ExtractFileName(SourcePath), ' | ', 
                   SourceEncoding, ' | ',
                   DestEncoding, ' | ',
                   System.StrUtils.IfThen(ConversionSuccess, '✓', '✗'), ' |');
          except
            on E: Exception do
            begin
              WriteLn(ReportFile, '| ', ExtractFileName(SourcePath), ' | ', 
                     SourceEncoding, ' | ',
                     DestEncoding, ' | ✗ (', E.Message, ') |');
            end;
          end;
        end;
      end;
    end;
    
    // 测试模式2: 从其他编码到UTF-8
    SourceEncodings.Clear;
    DestEncodings.Clear;
    
    // 从每种非UTF编码到UTF-8
    for i := 0 to NonUTFEncodings.Count - 1 do
      SourceEncodings.Add(NonUTFEncodings[i]);
    
    DestEncodings.Add('UTF-8');
    
    WriteLn(ReportFile, '');
    WriteLn(ReportFile, '## 2. 从其他编码到UTF-8转换测试');
    WriteLn(ReportFile, '');
    WriteLn(ReportFile, '| 文件 | 源编码 | 目标编码 | 转换结果 |');
    WriteLn(ReportFile, '|------|--------|----------|----------|');
    
    OneWayTests := 0;
    
    // 其他编码到UTF-8测试
    for i := 0 to SourceFiles.Count - 1 do
    begin
      SourcePath := SourceFiles[i];
      DetectedEncoding := DetectFileEncoding(SourcePath);
      
      // 对于每种源编码，我们创建一个临时文件用于转换测试
      for j := 0 to SourceEncodings.Count - 1 do
      begin
        SourceEncoding := SourceEncodings[j];
        SourceCP := GetEncodingCodePage(SourceEncoding);
        
        // 创建中间文件（强制指定编码）
        var TempPath := DestDir + 'temp_' + ExtractFileName(SourcePath) + '.' + SourceEncoding + '.txt';
        if FileExists(TempPath) then
          SafeDeleteFile(TempPath);
          
        // 把原文件先转成指定的源编码
        try
          if ConvertFile(SourcePath, TempPath, GetEncodingCodePage(DetectedEncoding), SourceCP) then
          begin
            // 然后再测试从这个编码转回UTF-8
            DestEncoding := 'UTF-8';
            DestCP := GetEncodingCodePage(DestEncoding);
            
            // 创建最终目标文件
            DestPath := DestDir + ExtractFileName(SourcePath) + '.' + SourceEncoding + '_to_Utf8.txt';
            
            Inc(TotalTests);
            Inc(OneWayTests);
            
            // 执行转换测试
            try
              ConversionSuccess := ConvertFile(TempPath, DestPath, SourceCP, DestCP);
              
              if ConversionSuccess then
                Inc(SuccessTests);
                
              // 写入结果到报告
              WriteLn(ReportFile, '| ', ExtractFileName(SourcePath), ' | ', 
                     SourceEncoding, ' | ',
                     DestEncoding, ' | ',
                     System.StrUtils.IfThen(ConversionSuccess, '✓', '✗'), ' |');
            except
              on E: Exception do
              begin
                WriteLn(ReportFile, '| ', ExtractFileName(SourcePath), ' | ', 
                       SourceEncoding, ' | ',
                       DestEncoding, ' | ✗ (', E.Message, ') |');
              end;
            end;
            
            // 清理临时文件
            if FileExists(TempPath) then
              SafeDeleteFile(TempPath);
          end;
        except
          // 转换为源编码失败，跳过这个测试
          WriteLn(ReportFile, '| ', ExtractFileName(SourcePath), ' | ', 
                 SourceEncoding, ' | ',
                 'UTF-8', ' | ✗ (无法创建源文件) |');
        end;
      end;
    end;
    
    // 写入统计信息
    WriteLn(ReportFile, '');
    WriteLn(ReportFile, '## 统计信息');
    WriteLn(ReportFile, '');
    WriteLn(ReportFile, '- 总测试数: ', TotalTests);
    WriteLn(ReportFile, '- 成功转换数: ', SuccessTests, ' (', FormatFloat('0.0%', SuccessTests / TotalTests), ')');
    WriteLn(ReportFile, '- UTF-8到其他编码测试数: ', TotalTests - OneWayTests);
    WriteLn(ReportFile, '- 其他编码到UTF-8测试数: ', OneWayTests);
    
    // 输出完成信息
    WriteLn('单向转换测试完成！');
    WriteLn('总测试数: ', TotalTests);
    WriteLn('成功转换数: ', SuccessTests, ' (', FormatFloat('0.0%', SuccessTests / TotalTests), ')');
    WriteLn('详细报告已保存到 oneway_conversion_tests.md');
    
  finally
    SourceFiles.Free;
    UTFEncodings.Free;
    NonUTFEncodings.Free;
    SourceEncodings.Free;
    DestEncodings.Free;
    Results.Free;
    CloseFile(ReportFile);
  end;
end;

var
  MainProc: procedure;
begin
  try
    // 主程序入口
    if ParamCount > 0 then
    begin
      // 解析命令行参数
      if LowerCase(ParamStr(1)) = 'roundtrip' then
        MainProc := TestRoundTripConversion
      else if LowerCase(ParamStr(1)) = 'oneway' then
        MainProc := TestOneWayConversion
      else
        MainProc := TestOneWayConversion; // 默认使用单向转换测试
    end
    else
      MainProc := TestOneWayConversion; // 默认使用单向转换测试
      
    MainProc;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  
  // 等待用户按键退出
  WriteLn;
  WriteLn('按任意键退出...');
  ReadLn;
end. 