program JCLEncodingTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  JclStrings,
  JclStringConversions,
  JclFileUtils;

const
  TEST_DIR = '.\tests\files\';

type
  TEncodingInfo = record
    EncodingName: string;
    CodePage: Integer;
  end;
  
  TEncodingTestResults = record
    FileName: string;
    DetectedEncoding: string;
    CodePage: Integer;
    Success: Boolean;
  end;

function GetEncodingName(CodePage: Integer): string;
begin
  case CodePage of
    0: Result := '未知';
    1200: Result := 'UTF-16LE'; 
    1201: Result := 'UTF-16BE';
    12000: Result := 'UTF-32LE';
    12001: Result := 'UTF-32BE';
    20127: Result := 'ASCII';
    28591: Result := 'ISO-8859-1';
    65000: Result := 'UTF-7';
    65001: Result := 'UTF-8';
    936: Result := 'GBK/GB2312';
    950: Result := 'BIG5';
    932: Result := 'Shift-JIS';
    949: Result := 'EUC-KR';
    1250: Result := 'Windows-1250';
    1251: Result := 'Windows-1251';
    1252: Result := 'Windows-1252';
    1253: Result := 'Windows-1253';
    1254: Result := 'Windows-1254';
    1255: Result := 'Windows-1255';
    1256: Result := 'Windows-1256';
    1257: Result := 'Windows-1257';
    1258: Result := 'Windows-1258';
    else Result := 'CodePage-' + IntToStr(CodePage);
  end;
end;

// 检测文件编码，使用JCL库
function DetectFileEncoding(const FileName: string; out CodePage: Integer): string;
var
  FileStream: TFileStream;
  Buffer: TBytes;
  BytesRead: Integer;
  BOMCP: Integer;
  BOMLead: PChar;
  BOMLength: Integer;
begin
  Result := 'Unknown';
  CodePage := 0;
  
  if not FileExists(FileName) then
    Exit;

  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    // 检查文件大小
    if FileStream.Size = 0 then
    begin
      Result := 'Empty File';
      Exit;
    end;

    // 读取前4KB进行分析
    BytesRead := Min(FileStream.Size, 4096);
    SetLength(Buffer, BytesRead);
    FileStream.ReadBuffer(Buffer[0], BytesRead);
    
    // 首先检测BOM
    BOMCP := DetectUTFBOMCodePage(Buffer, BOMLength);
    if BOMCP <> 0 then
    begin
      CodePage := BOMCP;
      Result := GetEncodingName(BOMCP);
      if BOMCP = 65001 then
        Result := Result + ' with BOM';
      Exit;
    end;
    
    // 检测UTF-8（不带BOM）
    if IsUTF8Valid(@Buffer[0], BytesRead) then
    begin
      CodePage := 65001;
      Result := 'UTF-8 without BOM';
      Exit;
    end;
    
    // 检测UTF-16LE/BE（不带BOM）
    if (BytesRead >= 2) and IsUTF16Valid(@Buffer[0], BytesRead, False) then
    begin
      CodePage := 1200; // UTF-16LE
      Result := 'UTF-16LE without BOM';
      Exit;
    end;
    
    if (BytesRead >= 2) and IsUTF16Valid(@Buffer[0], BytesRead, True) then
    begin
      CodePage := 1201; // UTF-16BE
      Result := 'UTF-16BE without BOM';
      Exit;
    end;
    
    // 尝试检测GBK/GB2312
    // 这里使用简单规则：大部分字节的值超过0x7F，且每两个字节构成一个汉字
    // 更准确的检测需要实现字符集统计分析
    if BytesRead > 20 then
    begin
      var HighByteCount: Integer := 0;
      for var i := 0 to BytesRead - 1 do
        if Buffer[i] > $7F then
          Inc(HighByteCount);
      
      if (HighByteCount > BytesRead div 4) and (HighByteCount < BytesRead div 2) then
      begin
        CodePage := 936; // GBK/GB2312
        Result := 'GBK/GB2312 (估计)';
        Exit;
      end;
    end;
    
    // 如果没有检测到明确的编码，默认使用系统ANSI代码页
    CodePage := GetACP;
    Result := 'ANSI (CP' + IntToStr(CodePage) + ')';
  finally
    FileStream.Free;
  end;
end;

// 测试转换功能
function ConvertEncoding(const SourceFileName, TargetFileName: string; 
                         SourceCodePage, TargetCodePage: Integer; AddBOM: Boolean = False): Boolean;
var
  SourceBytes, TargetBytes: TBytes;
  SourceString: UnicodeString;
  SourceStream, TargetStream: TFileStream;
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
    
    // 处理BOM（如果存在）
    var BOMLength: Integer := 0;
    var BOMCP := DetectUTFBOMCodePage(SourceBytes, BOMLength);
    if (BOMCP <> 0) and (BOMCP = SourceCodePage) then
      // 如果检测到的BOM与指定的源编码匹配，移除BOM
      SourceBytes := Copy(SourceBytes, BOMLength + 1, Length(SourceBytes) - BOMLength);
    
    // 从源编码转换到Unicode字符串
    if SourceCodePage = 1200 then // UTF-16LE
    begin
      SetLength(SourceString, Length(SourceBytes) div 2);
      Move(SourceBytes[0], SourceString[1], Length(SourceBytes));
    end
    else if SourceCodePage = 1201 then // UTF-16BE
    begin
      // 需要交换字节序
      SetLength(SourceString, Length(SourceBytes) div 2);
      for var i := 0 to Length(SourceString) - 1 do
      begin
        var b1 := SourceBytes[i*2];
        var b2 := SourceBytes[i*2+1];
        SourceString[i+1] := Char((b1 shl 8) or b2);
      end;
    end
    else
    begin
      // 使用JCL函数将其他编码转换为Unicode
      SourceString := StringToUnicodeStringEx(PAnsiChar(@SourceBytes[0]), 
                                             SourceCodePage, 
                                             Length(SourceBytes));
    end;
    
    // 从Unicode字符串转换到目标编码
    if TargetCodePage = 1200 then // UTF-16LE
    begin
      SetLength(TargetBytes, Length(SourceString) * 2);
      Move(SourceString[1], TargetBytes[0], Length(TargetBytes));
    end
    else if TargetCodePage = 1201 then // UTF-16BE
    begin
      // 需要交换字节序
      SetLength(TargetBytes, Length(SourceString) * 2);
      for var i := 0 to Length(SourceString) - 1 do
      begin
        var ch := Word(SourceString[i+1]);
        TargetBytes[i*2] := Byte(ch shr 8);
        TargetBytes[i*2+1] := Byte(ch and $FF);
      end;
    end
    else
    begin
      // 使用JCL函数将Unicode转换为其他编码
      var AnsiStr := UnicodeStringToStringEx(SourceString, TargetCodePage);
      SetLength(TargetBytes, Length(AnsiStr));
      if Length(AnsiStr) > 0 then
        Move(AnsiStr[1], TargetBytes[0], Length(AnsiStr));
    end;
    
    // 添加BOM（如果需要）
    if AddBOM then
    begin
      var BOMBytes: TBytes;
      case TargetCodePage of
        65001: BOMBytes := [$EF, $BB, $BF]; // UTF-8 BOM
        1200: BOMBytes := [$FF, $FE];       // UTF-16LE BOM
        1201: BOMBytes := [$FE, $FF];       // UTF-16BE BOM
        12000: BOMBytes := [$FF, $FE, $00, $00]; // UTF-32LE BOM
        12001: BOMBytes := [$00, $00, $FE, $FF]; // UTF-32BE BOM
      end;
      
      if Length(BOMBytes) > 0 then
      begin
        var NewBytes: TBytes;
        SetLength(NewBytes, Length(BOMBytes) + Length(TargetBytes));
        Move(BOMBytes[0], NewBytes[0], Length(BOMBytes));
        Move(TargetBytes[0], NewBytes[Length(BOMBytes)], Length(TargetBytes));
        TargetBytes := NewBytes;
      end;
    end;
    
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
      Writeln('转换错误: ' + E.Message);
      Result := False;
    end;
  end;
end;

// 测试检测文件编码功能
procedure TestDetectEncoding;
var
  Files: TStringDynArray;
  i: Integer;
  DetectedEncoding: string;
  CodePage: Integer;
  Results: array of TEncodingTestResults;
begin
  Writeln('开始测试JCL编码检测功能...');
  Writeln;
  
  // 获取所有测试文件
  Files := FindFiles(TEST_DIR + '*.*', faAnyFile - faDirectory);
  SetLength(Results, Length(Files));
  
  for i := 0 to Length(Files) - 1 do
  begin
    DetectedEncoding := DetectFileEncoding(Files[i], CodePage);
    
    Results[i].FileName := ExtractFileName(Files[i]);
    Results[i].DetectedEncoding := DetectedEncoding;
    Results[i].CodePage := CodePage;
    Results[i].Success := True; // 这里需要手动验证
    
    Writeln(Format('文件: %s, 检测到编码: %s (CodePage: %d)', 
      [Results[i].FileName, Results[i].DetectedEncoding, Results[i].CodePage]));
  end;
  
  if Length(Files) = 0 then
    Writeln('未找到测试文件。请将测试文件放在 ' + TEST_DIR + ' 目录下。');
    
  Writeln;
  Writeln('编码检测测试完成。');
end;

// 测试编码转换功能
procedure TestConversion;
const
  SOURCE_FILE = TEST_DIR + 'utf8_test.txt';
  TARGET_FILE = TEST_DIR + 'converted_';
var
  TargetEncodings: array of TEncodingInfo;
  i: Integer;
  Success: Boolean;
begin
  // 定义目标编码
  SetLength(TargetEncodings, 8);
  TargetEncodings[0].EncodingName := 'UTF-8';
  TargetEncodings[0].CodePage := 65001;
  TargetEncodings[1].EncodingName := 'UTF-8_BOM';
  TargetEncodings[1].CodePage := 65001;
  TargetEncodings[2].EncodingName := 'UTF-16LE';
  TargetEncodings[2].CodePage := 1200;
  TargetEncodings[3].EncodingName := 'UTF-16BE';
  TargetEncodings[3].CodePage := 1201;
  TargetEncodings[4].EncodingName := 'GBK';
  TargetEncodings[4].CodePage := 936;
  TargetEncodings[5].EncodingName := 'BIG5';
  TargetEncodings[5].CodePage := 950;
  TargetEncodings[6].EncodingName := 'Shift-JIS';
  TargetEncodings[6].CodePage := 932;
  TargetEncodings[7].EncodingName := 'Windows-1252';
  TargetEncodings[7].CodePage := 1252;
  
  Writeln('开始测试JCL编码转换功能...');
  Writeln('源文件: ' + SOURCE_FILE);
  Writeln;
  
  if not FileExists(SOURCE_FILE) then
  begin
    Writeln('源文件不存在，请确认路径是否正确。');
    Exit;
  end;
  
  var SourceCP: Integer;
  var SourceEncoding := DetectFileEncoding(SOURCE_FILE, SourceCP);
  Writeln('源文件编码: ' + SourceEncoding + ' (CodePage: ' + IntToStr(SourceCP) + ')');
  Writeln;
  
  for i := 0 to Length(TargetEncodings) - 1 do
  begin
    var TargetFile := TARGET_FILE + TargetEncodings[i].EncodingName + '.txt';
    var AddBOM := (TargetEncodings[i].CodePage = 65001) and (TargetEncodings[i].EncodingName = 'UTF-8_BOM')
                  or (TargetEncodings[i].CodePage = 1200) 
                  or (TargetEncodings[i].CodePage = 1201);
    
    Success := ConvertEncoding(SOURCE_FILE, TargetFile, SourceCP, 
                              TargetEncodings[i].CodePage, AddBOM);
    
    if Success then
      Writeln(Format('转换到 %s 成功, 输出文件: %s', 
        [TargetEncodings[i].EncodingName, ExtractFileName(TargetFile)]))
    else
      Writeln(Format('转换到 %s 失败', [TargetEncodings[i].EncodingName]));
  end;
  
  Writeln;
  Writeln('编码转换测试完成。');
end;

// 主函数
begin
  try
    Writeln('====== JCL编码检测与转换测试 ======');
    Writeln;
    
    TestDetectEncoding;
    Writeln;
    TestConversion;
    
    Writeln;
    Writeln('测试完成，按任意键退出...');
    Readln;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Readln;
    end;
  end;
end. 