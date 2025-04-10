program simple_encoding_test;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Winapi.Windows,
  JclBOM,
  JclStreams,
  JclStringConversions;

// 获取BOM字节
function GetBOMBytes(BOMType: TJclBOMType): TBytes;
begin
  case BOMType of
    bomUTF8:     begin SetLength(Result, 3); Result[0] := $EF; Result[1] := $BB; Result[2] := $BF; end;
    bomUTF16LE:  begin SetLength(Result, 2); Result[0] := $FF; Result[1] := $FE; end;
    bomUTF16BE:  begin SetLength(Result, 2); Result[0] := $FE; Result[1] := $FF; end;
    bomUTF32LE:  begin SetLength(Result, 4); Result[0] := $FF; Result[1] := $FE; Result[2] := $00; Result[3] := $00; end;
    bomUTF32BE:  begin SetLength(Result, 4); Result[0] := $00; Result[1] := $00; Result[2] := $FE; Result[3] := $FF; end;
    else         SetLength(Result, 0);
  end;
end;

// 从字节数组转换为Unicode字符串
function ConvertFromBytes(const Bytes: TBytes; CodePage: Integer): string;
var
  Len: Integer;
  WideStr: WideString;
  LocalBytes: TBytes;
begin
  if Length(Bytes) = 0 then
    Exit('');
  
  // 创建本地副本以避免修改常量参数
  SetLength(LocalBytes, Length(Bytes));
  if Length(Bytes) > 0 then
    Move(Bytes[0], LocalBytes[0], Length(Bytes));
  
  case CodePage of
    // 对于Unicode编码的特殊处理
    CP_UTF8:
      Result := TEncoding.UTF8.GetString(LocalBytes);
    
    1200: // UTF-16LE
      begin
        if Length(LocalBytes) mod 2 <> 0 then
          SetLength(LocalBytes, Length(LocalBytes) - 1); // 确保长度是偶数
        if Length(LocalBytes) > 0 then
          Result := TEncoding.Unicode.GetString(LocalBytes)
        else
          Result := '';
      end;
    
    1201: // UTF-16BE
      begin
        if Length(LocalBytes) mod 2 <> 0 then
          SetLength(LocalBytes, Length(LocalBytes) - 1); // 确保长度是偶数
        var SwappedBytes: TBytes;
        SetLength(SwappedBytes, Length(LocalBytes));
        for var i := 0 to (Length(LocalBytes) div 2) - 1 do
        begin
          SwappedBytes[i*2] := LocalBytes[i*2+1];
          SwappedBytes[i*2+1] := LocalBytes[i*2];
        end;
        if Length(SwappedBytes) > 0 then
          Result := TEncoding.Unicode.GetString(SwappedBytes)
        else
          Result := '';
      end;
      
    12000, 12001: // UTF-32
      Result := ''; // 需要更复杂的UTF-32处理
    
    // 对于其他代码页，使用Windows API
    else
      begin
        if Length(LocalBytes) = 0 then
          Exit('');
        
        // 获取宽字符所需的长度
        Len := MultiByteToWideChar(CodePage, 0, PAnsiChar(@LocalBytes[0]), Length(LocalBytes), nil, 0);
        if Len <= 0 then
          raise Exception.Create('Cannot convert from codepage ' + IntToStr(CodePage));
        
        // 分配足够的内存并执行转换
        SetLength(WideStr, Len);
        MultiByteToWideChar(CodePage, 0, PAnsiChar(@LocalBytes[0]), Length(LocalBytes), PWideChar(WideStr), Len);
        
        // 返回Unicode字符串
        Result := string(WideStr);
      end;
  end;
end;

// 将Unicode字符串转换为字节数组
function ConvertToBytes(const Str: string; CodePage: Integer): TBytes;
var
  Len: Integer;
begin
  if Str = '' then
  begin
    SetLength(Result, 0);
    Exit;
  end;
  
  case CodePage of
    // 对于Unicode编码的特殊处理
    CP_UTF8:
      Result := TEncoding.UTF8.GetBytes(Str);
      
    1200: // UTF-16LE
      Result := TEncoding.Unicode.GetBytes(Str);
      
    1201: // UTF-16BE
      begin
        var TempBytes := TEncoding.Unicode.GetBytes(Str);
        SetLength(Result, Length(TempBytes));
        for var i := 0 to (Length(TempBytes) div 2) - 1 do
        begin
          Result[i*2] := TempBytes[i*2+1];
          Result[i*2+1] := TempBytes[i*2];
        end;
      end;
      
    12000, 12001: // UTF-32
      SetLength(Result, 0); // 需要更复杂的UTF-32处理
      
    // 对于其他代码页，使用Windows API
    else
      begin
        if Str = '' then
        begin
          SetLength(Result, 0);
          Exit;
        end;
          
        // 获取多字节所需的长度
        Len := WideCharToMultiByte(CodePage, 0, PWideChar(Str), Length(Str), nil, 0, nil, nil);
        if Len <= 0 then
          raise Exception.Create('Cannot convert to codepage ' + IntToStr(CodePage));
          
        // 分配足够的内存并执行转换
        SetLength(Result, Len);
        WideCharToMultiByte(CodePage, 0, PWideChar(Str), Length(Str), @Result[0], Len, nil, nil);
      end;
  end;
end;

// 将文件从一种编码转换为另一种编码
function ConvertFileEncoding(const SourceFile, TargetFile: string; 
                            SourceCP, TargetCP: Integer; AddBOM: Boolean = False): Boolean;
var
  SourceBytes, TargetBytes: TBytes;
  SourceString: string;
  Stream: TFileStream;
begin
  Result := False;
  try
    // 读取源文件
    Stream := TFileStream.Create(SourceFile, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(SourceBytes, Stream.Size);
      if Stream.Size > 0 then
        Stream.ReadBuffer(SourceBytes[0], Stream.Size);
    finally
      Stream.Free;
    end;
    
    // 转换为Unicode字符串
    try
      SourceString := ConvertFromBytes(SourceBytes, SourceCP);
    except
      on E: Exception do
      begin
        WriteLn('从源编码转换失败: ', E.Message);
        Exit;
      end;
    end;
    
    // 转换为目标编码字节
    try
      TargetBytes := ConvertToBytes(SourceString, TargetCP);
    except
      on E: Exception do
      begin
        WriteLn('转换到目标编码失败: ', E.Message);
        Exit;
      end;
    end;
    
    // 可选：添加BOM
    if AddBOM then
    begin
      var BOMBytes: TBytes;
      case TargetCP of
        CP_UTF8:     BOMBytes := GetBOMBytes(bomUTF8);
        1200:        BOMBytes := GetBOMBytes(bomUTF16LE);
        1201:        BOMBytes := GetBOMBytes(bomUTF16BE);
        12000:       BOMBytes := GetBOMBytes(bomUTF32LE);
        12001:       BOMBytes := GetBOMBytes(bomUTF32BE);
        else         SetLength(BOMBytes, 0);
      end;
      
      if Length(BOMBytes) > 0 then
      begin
        var NewBytes: TBytes;
        SetLength(NewBytes, Length(BOMBytes) + Length(TargetBytes));
        if Length(BOMBytes) > 0 then
          Move(BOMBytes[0], NewBytes[0], Length(BOMBytes));
        if Length(TargetBytes) > 0 then
          Move(TargetBytes[0], NewBytes[Length(BOMBytes)], Length(TargetBytes));
        TargetBytes := NewBytes;
      end;
    end;
    
    // 写入目标文件
    Stream := TFileStream.Create(TargetFile, fmCreate);
    try
      if Length(TargetBytes) > 0 then
        Stream.WriteBuffer(TargetBytes[0], Length(TargetBytes));
      Result := True;
    finally
      Stream.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn('转换过程中出错: ', E.Message);
      Result := False;
    end;
  end;
end;

// 获取编码代码页
function GetEncodingCodePage(const EncodingName: string): Integer;
var
  UpperEncName: string;
begin
  UpperEncName := UpperCase(EncodingName);
  
  // Unicode编码
  if (UpperEncName = 'UTF-8') or (UpperEncName = 'UTF8') then
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
  
  // 韩文编码
  else if (UpperEncName = 'EUC-KR') or (UpperEncName = 'EUCKR') or (UpperEncName = '949') then
    Result := 949
  
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
  
  // 如果是数字格式的代码页
  else if TryStrToInt(EncodingName, Result) then
    // 已经转换为Integer了
  
  // 未知的编码
  else
    Result := GetACP(); // 默认当前系统ANSI代码页
end;

// 检测文件编码
function DetectFileEncoding(const FileName: string): string;
var
  FileStream: TFileStream;
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

// 主程序
procedure RunEncodingTest;
var
  SourceFile, TargetFile: string;
  SourceEncoding, TargetEncoding: string;
  SourceCP, TargetCP: Integer;
  Success: Boolean;
  AddBOM: Boolean;
begin
  // 打印帮助信息
  if (ParamCount < 3) then
  begin
    WriteLn('使用方法: simple_encoding_test.exe <源文件> <源编码> <目标编码> [addBOM]');
    WriteLn('示例:');
    WriteLn('  simple_encoding_test.exe example.txt UTF-8 GBK');
    WriteLn('  simple_encoding_test.exe example.txt GBK UTF-8 addBOM');
    WriteLn;
    WriteLn('支持的编码:');
    WriteLn('  Unicode: UTF-8, UTF-16LE, UTF-16BE, UTF-32LE, UTF-32BE');
    WriteLn('  中文: GBK, BIG5, GB18030');
    WriteLn('  日文: SHIFT-JIS, EUC-JP');
    WriteLn('  韩文: EUC-KR');
    WriteLn('  西欧: ISO-8859-1, WINDOWS-1252');
    WriteLn('  其他: ISO-8859-2, ISO-8859-7, ISO-8859-15, WINDOWS-1250, WINDOWS-1251, ...');
    Exit;
  end;
  
  // 获取参数
  SourceFile := ParamStr(1);
  SourceEncoding := ParamStr(2);
  TargetEncoding := ParamStr(3);
  AddBOM := False;
  if (ParamCount >= 4) and (UpperCase(ParamStr(4)) = 'ADDBOM') then
    AddBOM := True;
  
  // 检查源文件
  if not FileExists(SourceFile) then
  begin
    WriteLn('错误: 源文件不存在: ', SourceFile);
    Exit;
  end;
  
  // 创建目标文件名
  TargetFile := ChangeFileExt(SourceFile, '') + '.' + TargetEncoding + ExtractFileExt(SourceFile);
  
  // 获取编码代码页
  SourceCP := GetEncodingCodePage(SourceEncoding);
  TargetCP := GetEncodingCodePage(TargetEncoding);
  
  // 检测源文件实际编码
  WriteLn('检测到源文件 "', ExtractFileName(SourceFile), '" 的编码: ', DetectFileEncoding(SourceFile));
  WriteLn('指定的源编码: ', SourceEncoding, ' (CP: ', SourceCP, ')');
  WriteLn('指定的目标编码: ', TargetEncoding, ' (CP: ', TargetCP, ')');
  
  // 执行转换
  WriteLn('正在转换...');
  Success := ConvertFileEncoding(SourceFile, TargetFile, SourceCP, TargetCP, AddBOM);
  
  // 显示结果
  if Success then
  begin
    WriteLn('转换成功!');
    WriteLn('源文件: ', SourceFile);
    WriteLn('目标文件: ', TargetFile);
    WriteLn('目标文件检测到的编码: ', DetectFileEncoding(TargetFile));
  end
  else
    WriteLn('转换失败!');
end;

begin
  try
    RunEncodingTest;
    
    WriteLn;
    WriteLn('按任意键退出...');
    ReadLn;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end. 