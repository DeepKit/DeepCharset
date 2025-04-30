unit EncodingComparisonDotNet;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, 
  System.NetEncoding, System.Hash, System.JSON,
  Winapi.Windows, Winapi.Messages,
  System.Runtime.InteropServices;

type
  /// <summary>
  /// 编码比较功能的核心实现类
  /// 使用.NET Framework提供的编码处理功能
  /// </summary>
  TDotNetEncodingComparison = class
  private
    // 检查编码名称是否有效
    function IsValidEncoding(const AEncoding: string): Boolean;
    
    // 获取编码对应的代码页
    function GetCodePage(const AEncoding: string): Integer;
    
    // 通过BOM判断编码
    function DetectEncodingFromBOM(const AFilePath: string): string;
    
    // 通过内容启发式判断编码
    function DetectEncodingHeuristic(const AFilePath: string): string;
    
    // 读取文件内容为字节数组
    function ReadFileBytes(const AFilePath: string): TBytes;
    
    // 将字节数组写入文件
    procedure WriteFileBytes(const AFilePath: string; const ABytes: TBytes);

    // 获取文件内容差异
    function GetContentDifferences(const ASourceFile, ATargetFile: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    
    /// <summary>
    /// 检测文件编码
    /// </summary>
    /// <param name="AFilePath">文件路径</param>
    /// <returns>检测到的编码名称</returns>
    function DetectEncodingFromFile(const AFilePath: string): string;
    
    /// <summary>
    /// 转换文件编码
    /// </summary>
    /// <param name="ASourceFile">源文件路径</param>
    /// <param name="ATargetFile">目标文件路径</param>
    /// <param name="ASourceEncoding">源文件编码</param>
    /// <param name="ATargetEncoding">目标文件编码</param>
    /// <returns>转换是否成功</returns>
    function ConvertFile(const ASourceFile, ATargetFile, 
      ASourceEncoding, ATargetEncoding: string): Boolean;
    
    /// <summary>
    /// 转换文本编码
    /// </summary>
    /// <param name="AText">源文本</param>
    /// <param name="ASourceEncoding">源文本编码</param>
    /// <param name="ATargetEncoding">目标文本编码</param>
    /// <returns>转换后的文本</returns>
    function ConvertText(const AText, ASourceEncoding, ATargetEncoding: string): string;
    
    /// <summary>
    /// 比较两个文件内容是否一致
    /// </summary>
    /// <param name="AFile1">第一个文件路径</param>
    /// <param name="AFile2">第二个文件路径</param>
    /// <returns>是否一致</returns>
    function CompareFiles(const AFile1, AFile2: string): Boolean;
    
    /// <summary>
    /// 获取两个文件的差异报告
    /// </summary>
    /// <param name="AFile1">第一个文件路径</param>
    /// <param name="AFile2">第二个文件路径</param>
    /// <returns>差异报告</returns>
    function GetFileDifferences(const AFile1, AFile2: string): string;
  end;

implementation

{ TDotNetEncodingComparison }

constructor TDotNetEncodingComparison.Create;
begin
  inherited;
  // 初始化代码
end;

destructor TDotNetEncodingComparison.Destroy;
begin
  // 清理代码
  inherited;
end;

function TDotNetEncodingComparison.IsValidEncoding(const AEncoding: string): Boolean;
begin
  // 检查是否为有效编码
  Result := (AEncoding = 'UTF-8') or
            (AEncoding = 'UTF-16LE') or
            (AEncoding = 'UTF-16BE') or
            (AEncoding = 'UTF-32LE') or
            (AEncoding = 'UTF-32BE') or
            (AEncoding = 'ANSI') or
            (AEncoding = 'ASCII');
end;

function TDotNetEncodingComparison.GetCodePage(const AEncoding: string): Integer;
begin
  // 返回编码对应的代码页
  if AEncoding = 'UTF-8' then
    Result := CP_UTF8
  else if AEncoding = 'UTF-16LE' then
    Result := 1200
  else if AEncoding = 'UTF-16BE' then
    Result := 1201
  else if AEncoding = 'UTF-32LE' then
    Result := 12000
  else if AEncoding = 'UTF-32BE' then
    Result := 12001
  else if AEncoding = 'ASCII' then
    Result := 20127
  else if AEncoding = 'ANSI' then
    Result := GetACP // 获取当前ANSI代码页
  else
    Result := CP_UTF8; // 默认使用UTF-8
end;

function TDotNetEncodingComparison.DetectEncodingFromBOM(const AFilePath: string): string;
var
  FileStream: TFileStream;
  Buffer: TBytes;
  BytesRead: Integer;
begin
  Result := '';
  
  if not FileExists(AFilePath) then
    Exit;
    
  SetLength(Buffer, 4);
  FileStream := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyNone);
  try
    // 读取文件开头的4个字节以检测BOM
    BytesRead := FileStream.Read(Buffer[0], 4);
    
    if BytesRead >= 3 then
    begin
      // 检测UTF-8 BOM (EF BB BF)
      if (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF) then
        Result := 'UTF-8'
      // 检测UTF-16LE BOM (FF FE)
      else if (Buffer[0] = $FF) and (Buffer[1] = $FE) and (BytesRead >= 4) and (Buffer[2] <> 0) and (Buffer[3] <> 0) then
        Result := 'UTF-16LE'
      // 检测UTF-16BE BOM (FE FF)
      else if (Buffer[0] = $FE) and (Buffer[1] = $FF) then
        Result := 'UTF-16BE'
      // 检测UTF-32LE BOM (FF FE 00 00)
      else if (Buffer[0] = $FF) and (Buffer[1] = $FE) and (Buffer[2] = $00) and (Buffer[3] = $00) then
        Result := 'UTF-32LE'
      // 检测UTF-32BE BOM (00 00 FE FF)
      else if (Buffer[0] = $00) and (Buffer[1] = $00) and (Buffer[2] = $FE) and (Buffer[3] = $FF) then
        Result := 'UTF-32BE';
    end;
  finally
    FileStream.Free;
  end;
end;

function TDotNetEncodingComparison.DetectEncodingHeuristic(const AFilePath: string): string;
var
  FileBytes: TBytes;
  HasHighBit: Boolean;
  HasNullBytes: Boolean;
  NullPattern: Integer;
  I: Integer;
begin
  // 读取文件内容
  FileBytes := ReadFileBytes(AFilePath);
  
  // 如果文件为空，返回空字符串
  if Length(FileBytes) = 0 then
  begin
    Result := '';
    Exit;
  end;
  
  // 初始化检测变量
  HasHighBit := False;
  HasNullBytes := False;
  NullPattern := -1; // -1=无模式, 0=无NULL字节, 1=偶数位NULL, 2=奇数位NULL
  
  // 扫描文件内容
  for I := 0 to Min(Length(FileBytes) - 1, 4000) do
  begin
    // 检查高位字节（可能是非ASCII编码）
    if FileBytes[I] >= $80 then
      HasHighBit := True;
      
    // 检查NULL字节（可能是UTF-16或UTF-32）
    if FileBytes[I] = 0 then
    begin
      HasNullBytes := True;
      
      if NullPattern = -1 then
      begin
        if I mod 2 = 0 then
          NullPattern := 2  // 偶数位置为NULL，可能是UTF-16BE
        else
          NullPattern := 1; // 奇数位置为NULL，可能是UTF-16LE
      end;
    end;
  end;
  
  // 分析结果
  if HasNullBytes then
  begin
    // UTF-16/UTF-32 检测
    if NullPattern = 1 then
      Result := 'UTF-16LE'
    else if NullPattern = 2 then
      Result := 'UTF-16BE'
    else
      Result := 'UTF-8'; // 默认认为是UTF-8
  end
  else if HasHighBit then
    Result := 'UTF-8' // 有高位字节但无NULL字节，可能是UTF-8
  else
    Result := 'ASCII'; // 纯ASCII
end;

function TDotNetEncodingComparison.ReadFileBytes(const AFilePath: string): TBytes;
var
  FileStream: TFileStream;
begin
  SetLength(Result, 0);
  
  if not FileExists(AFilePath) then
    Exit;
    
  FileStream := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Result, FileStream.Size);
    if Length(Result) > 0 then
      FileStream.ReadBuffer(Result[0], Length(Result));
  finally
    FileStream.Free;
  end;
end;

procedure TDotNetEncodingComparison.WriteFileBytes(const AFilePath: string; const ABytes: TBytes);
var
  FileStream: TFileStream;
begin
  if Length(ABytes) = 0 then
  begin
    // 创建空文件
    FileStream := TFileStream.Create(AFilePath, fmCreate);
    FileStream.Free;
    Exit;
  end;
  
  // 创建目录（如果不存在）
  ForceDirectories(ExtractFilePath(AFilePath));
  
  // 写入文件
  FileStream := TFileStream.Create(AFilePath, fmCreate);
  try
    if Length(ABytes) > 0 then
      FileStream.WriteBuffer(ABytes[0], Length(ABytes));
  finally
    FileStream.Free;
  end;
end;

function TDotNetEncodingComparison.DetectEncodingFromFile(const AFilePath: string): string;
begin
  if not FileExists(AFilePath) then
  begin
    Result := '';
    Exit;
  end;
  
  // 首先尝试通过BOM检测
  Result := DetectEncodingFromBOM(AFilePath);
  
  // 如果没有BOM，使用启发式方法
  if Result = '' then
    Result := DetectEncodingHeuristic(AFilePath);
end;

function TDotNetEncodingComparison.ConvertFile(
  const ASourceFile, ATargetFile, ASourceEncoding, ATargetEncoding: string): Boolean;
var
  SourceBytes, TargetBytes: TBytes;
  SourceText, TargetText: string;
  SourceCP, TargetCP: Integer;
begin
  Result := False;
  
  // 检查参数
  if (not FileExists(ASourceFile)) or 
     (not IsValidEncoding(ASourceEncoding)) or 
     (not IsValidEncoding(ATargetEncoding)) then
    Exit;
  
  try
    // 读取源文件
    SourceBytes := ReadFileBytes(ASourceFile);
    if Length(SourceBytes) = 0 then
    begin
      // 如果源文件为空，创建空的目标文件
      WriteFileBytes(ATargetFile, SourceBytes);
      Result := True;
      Exit;
    end;
    
    // 获取编码代码页
    SourceCP := GetCodePage(ASourceEncoding);
    TargetCP := GetCodePage(ATargetEncoding);
    
    // 转换为Unicode字符串
    if ASourceEncoding = 'UTF-8' then
      SourceText := TEncoding.UTF8.GetString(SourceBytes)
    else if ASourceEncoding = 'UTF-16LE' then
      SourceText := TEncoding.Unicode.GetString(SourceBytes)
    else if ASourceEncoding = 'UTF-16BE' then
      SourceText := TEncoding.BigEndianUnicode.GetString(SourceBytes)
    else if ASourceEncoding = 'ASCII' then
      SourceText := TEncoding.ASCII.GetString(SourceBytes)
    else
    begin
      // ANSI或其他编码使用MultiByteToWideChar
      SetLength(SourceText, MultiByteToWideChar(SourceCP, 0, PAnsiChar(@SourceBytes[0]), 
        Length(SourceBytes), nil, 0));
      if Length(SourceText) > 0 then
        MultiByteToWideChar(SourceCP, 0, PAnsiChar(@SourceBytes[0]), 
          Length(SourceBytes), PWideChar(SourceText), Length(SourceText));
    end;
    
    // 从Unicode转换为目标编码
    if ATargetEncoding = 'UTF-8' then
      TargetBytes := TEncoding.UTF8.GetBytes(SourceText)
    else if ATargetEncoding = 'UTF-16LE' then
      TargetBytes := TEncoding.Unicode.GetBytes(SourceText)
    else if ATargetEncoding = 'UTF-16BE' then
      TargetBytes := TEncoding.BigEndianUnicode.GetBytes(SourceText)
    else if ATargetEncoding = 'ASCII' then
      TargetBytes := TEncoding.ASCII.GetBytes(SourceText)
    else
    begin
      // ANSI或其他编码使用WideCharToMultiByte
      SetLength(TargetBytes, WideCharToMultiByte(TargetCP, 0, PWideChar(SourceText), 
        Length(SourceText), nil, 0, nil, nil));
      if Length(TargetBytes) > 0 then
        WideCharToMultiByte(TargetCP, 0, PWideChar(SourceText), 
          Length(SourceText), PAnsiChar(@TargetBytes[0]), Length(TargetBytes), nil, nil);
    end;
    
    // 写入目标文件
    WriteFileBytes(ATargetFile, TargetBytes);
    Result := True;
  except
    on E: Exception do
    begin
      // 转换失败
      Result := False;
    end;
  end;
end;

function TDotNetEncodingComparison.ConvertText(
  const AText, ASourceEncoding, ATargetEncoding: string): string;
var
  SourceBytes, TargetBytes: TBytes;
  SourceCP, TargetCP: Integer;
  TempWideStr: string;
begin
  Result := '';
  
  // 检查参数
  if (AText = '') or 
     (not IsValidEncoding(ASourceEncoding)) or 
     (not IsValidEncoding(ATargetEncoding)) then
    Exit;
  
  try
    // 获取编码代码页
    SourceCP := GetCodePage(ASourceEncoding);
    TargetCP := GetCodePage(ATargetEncoding);
    
    // 如果源编码和目标编码相同，直接返回
    if ASourceEncoding = ATargetEncoding then
    begin
      Result := AText;
      Exit;
    end;
    
    // 将文本转换为字节数组
    if ASourceEncoding = 'UTF-8' then
      SourceBytes := TEncoding.UTF8.GetBytes(AText)
    else if ASourceEncoding = 'UTF-16LE' then
      SourceBytes := TEncoding.Unicode.GetBytes(AText)
    else if ASourceEncoding = 'UTF-16BE' then
      SourceBytes := TEncoding.BigEndianUnicode.GetBytes(AText)
    else if ASourceEncoding = 'ASCII' then
      SourceBytes := TEncoding.ASCII.GetBytes(AText)
    else
    begin
      // ANSI编码使用WideCharToMultiByte
      SetLength(SourceBytes, WideCharToMultiByte(SourceCP, 0, PWideChar(AText), 
        Length(AText), nil, 0, nil, nil));
      if Length(SourceBytes) > 0 then
        WideCharToMultiByte(SourceCP, 0, PWideChar(AText), 
          Length(AText), PAnsiChar(@SourceBytes[0]), Length(SourceBytes), nil, nil);
    end;
    
    // 将字节数组转换为Unicode字符串
    if ASourceEncoding = 'UTF-8' then
      TempWideStr := TEncoding.UTF8.GetString(SourceBytes)
    else if ASourceEncoding = 'UTF-16LE' then
      TempWideStr := TEncoding.Unicode.GetString(SourceBytes)
    else if ASourceEncoding = 'UTF-16BE' then
      TempWideStr := TEncoding.BigEndianUnicode.GetString(SourceBytes)
    else if ASourceEncoding = 'ASCII' then
      TempWideStr := TEncoding.ASCII.GetString(SourceBytes)
    else
    begin
      // ANSI编码使用MultiByteToWideChar
      SetLength(TempWideStr, MultiByteToWideChar(SourceCP, 0, PAnsiChar(@SourceBytes[0]), 
        Length(SourceBytes), nil, 0));
      if Length(TempWideStr) > 0 then
        MultiByteToWideChar(SourceCP, 0, PAnsiChar(@SourceBytes[0]), 
          Length(SourceBytes), PWideChar(TempWideStr), Length(TempWideStr));
    end;
    
    // 从Unicode转换为目标编码
    if ATargetEncoding = 'UTF-8' then
      TargetBytes := TEncoding.UTF8.GetBytes(TempWideStr)
    else if ATargetEncoding = 'UTF-16LE' then
      TargetBytes := TEncoding.Unicode.GetBytes(TempWideStr)
    else if ATargetEncoding = 'UTF-16BE' then
      TargetBytes := TEncoding.BigEndianUnicode.GetBytes(TempWideStr)
    else if ATargetEncoding = 'ASCII' then
      TargetBytes := TEncoding.ASCII.GetBytes(TempWideStr)
    else
    begin
      // ANSI编码使用WideCharToMultiByte
      SetLength(TargetBytes, WideCharToMultiByte(TargetCP, 0, PWideChar(TempWideStr), 
        Length(TempWideStr), nil, 0, nil, nil));
      if Length(TargetBytes) > 0 then
        WideCharToMultiByte(TargetCP, 0, PWideChar(TempWideStr), 
          Length(TempWideStr), PAnsiChar(@TargetBytes[0]), Length(TargetBytes), nil, nil);
    end;
    
    // 将字节数组转换回字符串
    if ATargetEncoding = 'UTF-8' then
      Result := TEncoding.UTF8.GetString(TargetBytes)
    else if ATargetEncoding = 'UTF-16LE' then
      Result := TEncoding.Unicode.GetString(TargetBytes)
    else if ATargetEncoding = 'UTF-16BE' then
      Result := TEncoding.BigEndianUnicode.GetString(TargetBytes)
    else if ATargetEncoding = 'ASCII' then
      Result := TEncoding.ASCII.GetString(TargetBytes)
    else
    begin
      // ANSI编码使用MultiByteToWideChar
      SetLength(Result, MultiByteToWideChar(TargetCP, 0, PAnsiChar(@TargetBytes[0]), 
        Length(TargetBytes), nil, 0));
      if Length(Result) > 0 then
        MultiByteToWideChar(TargetCP, 0, PAnsiChar(@TargetBytes[0]), 
          Length(TargetBytes), PWideChar(Result), Length(Result));
    end;
  except
    on E: Exception do
    begin
      // 转换失败，返回空字符串
      Result := '';
    end;
  end;
end;

function TDotNetEncodingComparison.CompareFiles(const AFile1, AFile2: string): Boolean;
var
  File1Bytes, File2Bytes: TBytes;
  I: Integer;
begin
  Result := False;
  
  // 检查文件是否存在
  if (not FileExists(AFile1)) or (not FileExists(AFile2)) then
    Exit;
  
  // 读取文件内容
  File1Bytes := ReadFileBytes(AFile1);
  File2Bytes := ReadFileBytes(AFile2);
  
  // 比较文件大小
  if Length(File1Bytes) <> Length(File2Bytes) then
    Exit;
  
  // 比较文件内容
  for I := 0 to Length(File1Bytes) - 1 do
  begin
    if File1Bytes[I] <> File2Bytes[I] then
      Exit;
  end;
  
  // 文件内容完全一致
  Result := True;
end;

function TDotNetEncodingComparison.GetContentDifferences(
  const ASourceFile, ATargetFile: string): string;
var
  SourceText, TargetText: TStringList;
  DiffCount, I: Integer;
  MaxLinesToShow: Integer;
begin
  Result := '';
  SourceText := TStringList.Create;
  TargetText := TStringList.Create;
  try
    // 尝试读取文件内容
    try
      SourceText.LoadFromFile(ASourceFile);
    except
      Result := Result + '无法读取源文件内容。' + sLineBreak;
    end;
    
    try
      TargetText.LoadFromFile(ATargetFile);
    except
      Result := Result + '无法读取目标文件内容。' + sLineBreak;
    end;
    
    // 比较行数
    Result := Result + Format('源文件行数: %d, 目标文件行数: %d', 
      [SourceText.Count, TargetText.Count]) + sLineBreak;
    
    // 查找不同的行
    DiffCount := 0;
    MaxLinesToShow := 10; // 最多显示10行差异
    
    for I := 0 to Min(SourceText.Count, TargetText.Count) - 1 do
    begin
      if SourceText[I] <> TargetText[I] then
      begin
        Inc(DiffCount);
        
        if DiffCount <= MaxLinesToShow then
        begin
          Result := Result + Format('行 %d 不同:', [I + 1]) + sLineBreak;
          Result := Result + '源: ' + SourceText[I] + sLineBreak;
          Result := Result + '目标: ' + TargetText[I] + sLineBreak;
        end;
      end;
    end;
    
    // 如果有更多差异，显示摘要
    if DiffCount > MaxLinesToShow then
      Result := Result + Format('... 还有 %d 处差异未显示', [DiffCount - MaxLinesToShow]) + sLineBreak;
    
    // 检查其中一个文件是否有额外的行
    if SourceText.Count > TargetText.Count then
      Result := Result + Format('源文件比目标文件多 %d 行', [SourceText.Count - TargetText.Count]) + sLineBreak
    else if TargetText.Count > SourceText.Count then
      Result := Result + Format('目标文件比源文件多 %d 行', [TargetText.Count - SourceText.Count]) + sLineBreak;
    
  finally
    SourceText.Free;
    TargetText.Free;
  end;
end;

function TDotNetEncodingComparison.GetFileDifferences(const AFile1, AFile2: string): string;
var
  File1Size, File2Size: Int64;
  File1Encoding, File2Encoding: string;
begin
  Result := '';
  
  // 检查文件是否存在
  if not FileExists(AFile1) then
  begin
    Result := '错误: 文件不存在 - ' + AFile1 + sLineBreak;
    Exit;
  end;
  
  if not FileExists(AFile2) then
  begin
    Result := '错误: 文件不存在 - ' + AFile2 + sLineBreak;
    Exit;
  end;
  
  // 获取文件大小
  File1Size := TFile.GetSize(AFile1);
  File2Size := TFile.GetSize(AFile2);
  
  Result := '文件比较报告:' + sLineBreak;
  Result := Result + '文件1: ' + AFile1 + sLineBreak;
  Result := Result + '文件2: ' + AFile2 + sLineBreak;
  Result := Result + '-------------------------------' + sLineBreak;
  
  // 比较文件大小
  Result := Result + '文件大小:' + sLineBreak;
  Result := Result + Format('文件1: %d 字节', [File1Size]) + sLineBreak;
  Result := Result + Format('文件2: %d 字节', [File2Size]) + sLineBreak;
  
  if File1Size = File2Size then
    Result := Result + '文件大小相同。' + sLineBreak
  else
    Result := Result + Format('文件大小差异: %d 字节', [Abs(File1Size - File2Size)]) + sLineBreak;
  
  Result := Result + '-------------------------------' + sLineBreak;
  
  // 检测文件编码
  File1Encoding := DetectEncodingFromFile(AFile1);
  File2Encoding := DetectEncodingFromFile(AFile2);
  
  Result := Result + '文件编码:' + sLineBreak;
  Result := Result + '文件1: ' + File1Encoding + sLineBreak;
  Result := Result + '文件2: ' + File2Encoding + sLineBreak;
  
  if File1Encoding = File2Encoding then
    Result := Result + '文件编码相同。' + sLineBreak
  else
    Result := Result + '文件编码不同。' + sLineBreak;
  
  Result := Result + '-------------------------------' + sLineBreak;
  
  // 检查文件内容差异
  if CompareFiles(AFile1, AFile2) then
    Result := Result + '文件内容完全相同。' + sLineBreak
  else
  begin
    Result := Result + '文件内容有差异:' + sLineBreak;
    Result := Result + GetContentDifferences(AFile1, AFile2);
  end;
  
  Result := Result + '-------------------------------' + sLineBreak;
end;

end. 