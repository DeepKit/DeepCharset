unit JclEncodingUtils;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, System.IOUtils,
  JclBOM, JclStrings, JclStringConversions, JclFileUtils, JclStreams;

const
  // 代码页常量
  CP_ANSI = 0;  // 使用GetACP获取
  CP_UTF16LE = 1200;
  CP_UTF16BE = 1201;
  CP_UTF32LE = 12000;
  CP_UTF32BE = 12001;
  CP_ASCII = 20127;
  CP_ISO_8859_1 = 28591;
  CP_GBK = 936;
  CP_BIG5 = 950;
  CP_SHIFT_JIS = 932;
  CP_GB18030 = 54936;

  // 编码名称常量
  ENCODING_ANSI = 'ANSI';
  ENCODING_UTF8 = 'UTF-8';
  ENCODING_UTF8_BOM = 'UTF-8 with BOM';
  ENCODING_UTF16_LE = 'UTF-16LE';
  ENCODING_UTF16_BE = 'UTF-16BE';
  ENCODING_UTF32_LE = 'UTF-32LE';
  ENCODING_UTF32_BE = 'UTF-32BE';
  ENCODING_GBK = 'GBK';
  ENCODING_GB2312 = 'GB2312';
  ENCODING_BIG5 = 'BIG5';
  ENCODING_ASCII = 'ASCII';
  ENCODING_SHIFT_JIS = 'Shift-JIS';

// 编码检测辅助函数
function IsUTF8Valid(const Buffer: TBytes; Size: Integer): Boolean;
function IsGBKString(const Buffer: TBytes; Size: Integer): Boolean;

// 检测文件编码
function DetectFileEncoding(const FileName: string): string;

// 获取编码的代码页
function GetEncodingCodePage(const EncodingName: string): Integer;

// 转换文件编码
function ConvertFile(const SourceFileName, TargetFileName: string; 
  SourceCodePage, TargetCodePage: Integer): Boolean;

// 带BOM选项的转换文件编码
function ConvertFileWithBOM(const SourceFileName, TargetFileName: string; 
  SourceCodePage, TargetCodePage: Integer; AddBOM: Boolean = False): Boolean;

// 按编码名称转换文件
function ConvertFileByName(const SourceFileName, TargetFileName: string; 
  const SourceEncodingName, TargetEncodingName: string; AddBOM: Boolean = False): Boolean;

// 直接将文件转换为UTF-8 BOM格式
function ConvertFileToUTF8BOM(const SourceFileName, TargetFileName: string): Boolean;

implementation

// 检查是否是有效的UTF-8编码
function IsUTF8Valid(const Buffer: TBytes; Size: Integer): Boolean;
var
  i, CharSize: Integer;
begin
  Result := True;
  i := 0;
  
  while i < Size do
  begin
    if Buffer[i] < $80 then
    begin
      // ASCII字符
      Inc(i);
    end
    else if Buffer[i] < $C0 then
    begin
      // 无效的UTF-8序列
      Result := False;
      Exit;
    end
    else if Buffer[i] < $E0 then
    begin
      // 2字节序列
      if i + 1 >= Size then Exit(False);
      if (Buffer[i+1] and $C0) <> $80 then Exit(False);
      Inc(i, 2);
    end
    else if Buffer[i] < $F0 then
    begin
      // 3字节序列
      if i + 2 >= Size then Exit(False);
      if (Buffer[i+1] and $C0) <> $80 then Exit(False);
      if (Buffer[i+2] and $C0) <> $80 then Exit(False);
      Inc(i, 3);
    end
    else if Buffer[i] < $F8 then
    begin
      // 4字节序列
      if i + 3 >= Size then Exit(False);
      if (Buffer[i+1] and $C0) <> $80 then Exit(False);
      if (Buffer[i+2] and $C0) <> $80 then Exit(False);
      if (Buffer[i+3] and $C0) <> $80 then Exit(False);
      Inc(i, 4);
    end
    else
    begin
      // 无效的UTF-8序列
      Result := False;
      Exit;
    end;
  end;
end;

// 检查是否是GBK编码
function IsGBKString(const Buffer: TBytes; Size: Integer): Boolean;
var
  i: Integer;
  GBKCount, ASCIICount: Integer;
begin
  if Size <= 0 then
    Exit(False);
    
  GBKCount := 0;
  ASCIICount := 0;
  i := 0;
  
  while i < Size do
  begin
    if Buffer[i] <= $7F then
    begin
      // ASCII范围
      Inc(ASCIICount);
      Inc(i);
    end
    else if (Buffer[i] >= $81) and (Buffer[i] <= $FE) and (i + 1 < Size) and 
            (Buffer[i+1] >= $40) and (Buffer[i+1] <= $FE) then
    begin
      // 标准GBK字符
      Inc(GBKCount);
      Inc(i, 2);
    end
    else
    begin
      // 不是有效的GBK
      Inc(i);
    end;
  end;
  
  // 如果文本中包含GBK字符，且比例较高，认为是GBK编码
  Result := (GBKCount > 0) and (GBKCount >= ASCIICount div 10);
end;

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
    if BOMType = bomAnsi then
      Result := ENCODING_ANSI
    else if BOMType = bomUTF8 then
      Result := ENCODING_UTF8_BOM
    else if BOMType = bomUTF16LE then
      Result := ENCODING_UTF16_LE
    else if BOMType = bomUTF16BE then
      Result := ENCODING_UTF16_BE
    else if BOMType = bomUTF32LE then
      Result := ENCODING_UTF32_LE
    else if BOMType = bomUTF32BE then
      Result := ENCODING_UTF32_BE;
    
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
        if IsUTF8Valid(Buffer, BytesRead) then
        begin
          Result := ENCODING_UTF8;
          Exit;
        end;
      end;
      
      // 尝试其他编码
      // 检查是否符合GB2312/GBK/GB18030
      if BytesRead > 1 then
      begin
        if IsGBKString(Buffer, BytesRead) then
        begin
          Result := ENCODING_GBK;
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
  else if (UpperEncName = 'UTF-8-BOM') or (UpperEncName = 'UTF8-BOM') or
          (UpperEncName = 'UTF-8 WITH BOM') then
    Result := CP_UTF8
  else if (UpperEncName = 'UTF-16LE') or (UpperEncName = 'UTF16LE') or 
          (UpperEncName = 'UNICODE') then
    Result := CP_UTF16LE
  else if (UpperEncName = 'UTF-16BE') or (UpperEncName = 'UTF16BE') then
    Result := CP_UTF16BE
  else if (UpperEncName = 'UTF-32LE') or (UpperEncName = 'UTF32LE') then
    Result := CP_UTF32LE
  else if (UpperEncName = 'UTF-32BE') or (UpperEncName = 'UTF32BE') then
    Result := CP_UTF32BE
  
  // 中文编码
  else if (UpperEncName = 'GBK') or (UpperEncName = 'GB2312') or 
          (UpperEncName = '936') then
    Result := CP_GBK
  else if (UpperEncName = 'BIG5') or (UpperEncName = '950') then
    Result := CP_BIG5
  else if UpperEncName = 'GB18030' then
    Result := CP_GB18030
  
  // 如果是数字格式的代码页
  else if TryStrToInt(EncodingName, Result) then
    // 已经转换为Integer了
  
  // 未知的编码
  else
    Result := GetACP(); // 返回系统默认代码页
end;

// 转换文件编码
function ConvertFile(const SourceFileName, TargetFileName: string; 
                    SourceCodePage, TargetCodePage: Integer): Boolean;
var
  SourceBytes, TargetBytes: TBytes;
  SourceStream, TargetStream: TFileStream;
  SourceString: string;
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
      // 处理错误
      Result := False;
    end;
  end;
end;

// 带BOM选项的转换文件编码
function ConvertFileWithBOM(const SourceFileName, TargetFileName: string;
                           SourceCodePage, TargetCodePage: Integer; 
                           AddBOM: Boolean = False): Boolean;
var
  SourceBytes, TargetBytes, BOMBytes, FinalBytes: TBytes;
  SourceStream, TargetStream: TFileStream;
  SourceString: string;
  Encoding: TEncoding;
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
    
    // 检测和移除源文件的BOM
    var BOMLen := 0;
    var BOMType := bomAnsi;
    
    if Length(SourceBytes) >= 2 then
    begin
      if (SourceBytes[0] = $FF) and (SourceBytes[1] = $FE) and (SourceCodePage = CP_UTF16LE) then
      begin
        BOMType := bomUTF16LE;
        BOMLen := 2;
      end
      else if (SourceBytes[0] = $FE) and (SourceBytes[1] = $FF) and (SourceCodePage = CP_UTF16BE) then
      begin
        BOMType := bomUTF16BE;
        BOMLen := 2;
      end
      else if (Length(SourceBytes) >= 3) and 
              (SourceBytes[0] = $EF) and (SourceBytes[1] = $BB) and (SourceBytes[2] = $BF) and 
              (SourceCodePage = CP_UTF8) then
      begin
        BOMType := bomUTF8;
        BOMLen := 3;
      end
      else if (Length(SourceBytes) >= 4) and 
             (SourceBytes[0] = $FF) and (SourceBytes[1] = $FE) and
             (SourceBytes[2] = $00) and (SourceBytes[3] = $00) and 
             (SourceCodePage = CP_UTF32LE) then
      begin
        BOMType := bomUTF32LE;
        BOMLen := 4;
      end
      else if (Length(SourceBytes) >= 4) and 
             (SourceBytes[0] = $00) and (SourceBytes[1] = $00) and
             (SourceBytes[2] = $FE) and (SourceBytes[3] = $FF) and 
             (SourceCodePage = CP_UTF32BE) then
      begin
        BOMType := bomUTF32BE;
        BOMLen := 4;
      end;
    end;
    
    // 如果检测到BOM，移除BOM
    if BOMLen > 0 then
    begin
      var TempBytes: TBytes;
      SetLength(TempBytes, Length(SourceBytes) - BOMLen);
      if Length(TempBytes) > 0 then
        Move(SourceBytes[BOMLen], TempBytes[0], Length(TempBytes));
      SourceBytes := TempBytes;
    end;
    
    // 从源编码转换到Unicode字符串
    Encoding := TEncoding.GetEncoding(SourceCodePage);
    try
      SourceString := Encoding.GetString(SourceBytes);
    finally
      if SourceCodePage <> CP_UTF8 then
        Encoding.Free;
    end;
    
    // 从Unicode字符串转换到目标编码
    Encoding := TEncoding.GetEncoding(TargetCodePage);
    try
      TargetBytes := Encoding.GetBytes(SourceString);
    finally
      if TargetCodePage <> CP_UTF8 then
        Encoding.Free;
    end;
    
    // 如果需要添加BOM
    if AddBOM then
    begin
      case TargetCodePage of
        CP_UTF8:     BOMBytes := TBytes.Create($EF, $BB, $BF);
        CP_UTF16LE:  BOMBytes := TBytes.Create($FF, $FE);
        CP_UTF16BE:  BOMBytes := TBytes.Create($FE, $FF);
        CP_UTF32LE:  BOMBytes := TBytes.Create($FF, $FE, $00, $00);
        CP_UTF32BE:  BOMBytes := TBytes.Create($00, $00, $FE, $FF);
        else         SetLength(BOMBytes, 0);
      end;
      
      if Length(BOMBytes) > 0 then
      begin
        SetLength(FinalBytes, Length(BOMBytes) + Length(TargetBytes));
        Move(BOMBytes[0], FinalBytes[0], Length(BOMBytes));
        if Length(TargetBytes) > 0 then
          Move(TargetBytes[0], FinalBytes[Length(BOMBytes)], Length(TargetBytes));
        TargetBytes := FinalBytes;
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
      // 处理错误
      Result := False;
    end;
  end;
end;

// 按编码名称转换文件
function ConvertFileByName(const SourceFileName, TargetFileName: string;
                          const SourceEncodingName, TargetEncodingName: string; 
                          AddBOM: Boolean = False): Boolean;
var
  SourceCP, TargetCP: Integer;
begin
  // 获取源和目标代码页
  SourceCP := GetEncodingCodePage(SourceEncodingName);
  TargetCP := GetEncodingCodePage(TargetEncodingName);
  
  // 使用代码页版本的函数
  Result := ConvertFileWithBOM(SourceFileName, TargetFileName, SourceCP, TargetCP, AddBOM);
end;

// 直接将文件转换为UTF-8 BOM格式
function ConvertFileToUTF8BOM(const SourceFileName, TargetFileName: string): Boolean;
var
  SourceBytes, TargetBytes: TBytes;
  SourceStream, TargetStream: TFileStream;
  HasBOM: Boolean;
  SourceEncoding: string;
  BOMHeader: TBytes;
  TempString: string;
  SourceCodePage: Integer;
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
    
    // 检查是否已经有UTF-8 BOM
    HasBOM := (Length(SourceBytes) >= 3) and 
              (SourceBytes[0] = $EF) and 
              (SourceBytes[1] = $BB) and 
              (SourceBytes[2] = $BF);
    
    if HasBOM then
    begin
      // 已经是UTF-8 BOM，直接复制
      if SourceFileName <> TargetFileName then
        TFile.Copy(SourceFileName, TargetFileName, True);
      Result := True;
      Exit;
    end;
    
    // 确保源目标路径存在
    var TargetPath := ExtractFilePath(TargetFileName);
    if (TargetPath <> '') and not DirectoryExists(TargetPath) then
      ForceDirectories(TargetPath);
    
    // 自动检测源编码类型
    if IsUTF8Valid(SourceBytes, Length(SourceBytes)) then
      SourceEncoding := 'UTF-8'
    else
      SourceEncoding := DetectFileEncoding(SourceFileName);
    
    SourceCodePage := GetEncodingCodePage(SourceEncoding);
    
    // 从源编码转换到Unicode字符串 - 处理ANSI编码
    if SourceEncoding = 'ANSI' then
    begin
      // 使用系统默认ANSI代码页
      TempString := StringToUnicodeString(PAnsiChar(@SourceBytes[0]), GetACP, Length(SourceBytes));
    end
    else if SourceEncoding = 'UTF-8' then
      TempString := TEncoding.UTF8.GetString(SourceBytes)
    else if (SourceEncoding = 'UTF-16LE') or (SourceEncoding = 'Unicode') then
      TempString := TEncoding.Unicode.GetString(SourceBytes)
    else if SourceEncoding = 'UTF-16BE' then
      TempString := TEncoding.BigEndianUnicode.GetString(SourceBytes)
    else
      TempString := StringToUnicodeStringEx(PAnsiChar(@SourceBytes[0]), SourceCodePage, Length(SourceBytes));
    
    // 添加UTF-8 BOM
    BOMHeader := TBytes.Create($EF, $BB, $BF);
    
    // 转换为UTF-8字节
    TargetBytes := TEncoding.UTF8.GetBytes(TempString);
    
    // 合并BOM和内容
    var FinalBytes: TBytes;
    SetLength(FinalBytes, Length(BOMHeader) + Length(TargetBytes));
    if Length(BOMHeader) > 0 then
      Move(BOMHeader[0], FinalBytes[0], Length(BOMHeader));
    if Length(TargetBytes) > 0 then
      Move(TargetBytes[0], FinalBytes[Length(BOMHeader)], Length(TargetBytes));
    
    // 写入目标文件
    try
      // 先检查目标文件是否可写
      if FileExists(TargetFileName) then
      begin
        // 尝试设置文件属性为可写
        if FileGetAttr(TargetFileName) and faReadOnly <> 0 then
          FileSetAttr(TargetFileName, FileGetAttr(TargetFileName) and not faReadOnly);
        
        // 删除已存在的文件
        DeleteFile(PChar(TargetFileName));
      end;
      
      TargetStream := TFileStream.Create(TargetFileName, fmCreate);
      try
        if Length(FinalBytes) > 0 then
          TargetStream.WriteBuffer(FinalBytes[0], Length(FinalBytes));
        Result := True;
      finally
        TargetStream.Free;
      end;
    except
      on E: Exception do
      begin
        // 捕获写入错误
        OutputDebugString(PChar('写入目标文件失败: ' + E.Message));
        Result := False;
      end;
    end;
  except
    on E: Exception do
    begin
      // 捕获其他错误
      OutputDebugString(PChar('转换为UTF-8 BOM失败: ' + E.Message));
      Result := False;
    end;
  end;
end;

end. 