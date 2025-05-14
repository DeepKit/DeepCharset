unit EncodingComparisonWindows;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows;

type
  /// <summary>
  /// 与Windows API对比的编码转换类
  /// </summary>
  TWindowsEncodingComparison = class
  private
    // 获取代码页
    function GetCodePage(const AEncoding: string): Cardinal;
    
    // 判断编码是否需要BOM
    function NeedsBOM(const AEncoding: string): Boolean;
    
    // 计算文件MD5哈希
    function CalculateMD5(const AFilePath: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    
    /// <summary>
    /// 使用Windows API转换文件编码
    /// </summary>
    function ConvertFile(const ASourceFile, ATargetFile: string; 
      const ASourceEncoding, ATargetEncoding: string; 
      AAddBOM: Boolean = False): Boolean;
    
    /// <summary>
    /// 使用Windows API转换文本编码
    /// </summary>
    function ConvertText(const ASourceText: string; const ASourceEncoding, ATargetEncoding: string; 
      AAddBOM: Boolean = False): string;
    
    /// <summary>
    /// 比较两个文件的内容是否相同
    /// </summary>
    function CompareFiles(const AFile1, AFile2: string): Boolean;
    
    /// <summary>
    /// 获取两个文件的差异报告
    /// </summary>
    function GetFileDifferences(const AFile1, AFile2: string): string;
  end;

implementation

uses
  System.Hash, System.NetEncoding;

{ TWindowsEncodingComparison }

constructor TWindowsEncodingComparison.Create;
begin
  inherited Create;
end;

destructor TWindowsEncodingComparison.Destroy;
begin
  inherited;
end;

function TWindowsEncodingComparison.GetCodePage(const AEncoding: string): Cardinal;
begin
  if SameText(AEncoding, 'UTF-8') then
    Result := CP_UTF8
  else if SameText(AEncoding, 'UTF-16LE') or SameText(AEncoding, 'Unicode') then
    Result := 1200
  else if SameText(AEncoding, 'UTF-16BE') then
    Result := 1201
  else if SameText(AEncoding, 'ASCII') then
    Result := 20127
  else if SameText(AEncoding, 'GBK') or SameText(AEncoding, 'GB2312') then
    Result := 936
  else if SameText(AEncoding, 'GB18030') then
    Result := 54936
  else if SameText(AEncoding, 'Big5') then
    Result := 950
  else
    Result := CP_ACP; // 默认使用系统ANSI代码页
end;

function TWindowsEncodingComparison.NeedsBOM(const AEncoding: string): Boolean;
begin
  Result := SameText(AEncoding, 'UTF-8') or 
            SameText(AEncoding, 'UTF-16LE') or 
            SameText(AEncoding, 'Unicode') or 
            SameText(AEncoding, 'UTF-16BE');
end;

function TWindowsEncodingComparison.CalculateMD5(const AFilePath: string): string;
var
  FileStream: TFileStream;
begin
  if FileExists(AFilePath) then
  begin
    FileStream := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyNone);
    try
      Result := THashMD5.GetHashStringFromStream(FileStream);
    finally
      FileStream.Free;
    end;
  end
  else
    Result := '';
end;

function TWindowsEncodingComparison.ConvertFile(const ASourceFile, ATargetFile: string;
  const ASourceEncoding, ATargetEncoding: string; AAddBOM: Boolean): Boolean;
var
  SourceCodePage, TargetCodePage: Cardinal;
  SourceStream, TargetStream: TFileStream;
  SourceText, TargetText: string;
  SourceBytes, TargetBytes: TBytes;
  WideText: WideString;
  Flags: DWORD;
  BOM: TBytes;
  SkipBOM: Integer;
begin
  Result := False;
  
  if not FileExists(ASourceFile) then
    Exit;
  
  try
    SourceCodePage := GetCodePage(ASourceEncoding);
    TargetCodePage := GetCodePage(ATargetEncoding);
    
    // 读取源文件
    SourceStream := TFileStream.Create(ASourceFile, fmOpenRead or fmShareDenyNone);
    try
      SetLength(SourceBytes, SourceStream.Size);
      if SourceStream.Size > 0 then
        SourceStream.ReadBuffer(SourceBytes[0], SourceStream.Size);
    finally
      SourceStream.Free;
    end;
    
    // 检查BOM并跳过（如果有）
    SkipBOM := 0;
    if SameText(ASourceEncoding, 'UTF-8') and (Length(SourceBytes) >= 3) then
    begin
      if (SourceBytes[0] = $EF) and (SourceBytes[1] = $BB) and (SourceBytes[2] = $BF) then
        SkipBOM := 3;
    end
    else if (SameText(ASourceEncoding, 'UTF-16LE') or SameText(ASourceEncoding, 'Unicode')) and (Length(SourceBytes) >= 2) then
    begin
      if (SourceBytes[0] = $FF) and (SourceBytes[1] = $FE) then
        SkipBOM := 2;
    end
    else if SameText(ASourceEncoding, 'UTF-16BE') and (Length(SourceBytes) >= 2) then
    begin
      if (SourceBytes[0] = $FE) and (SourceBytes[1] = $FF) then
        SkipBOM := 2;
    end;
    
    // 源字节转换为宽字符
    SetLength(WideText, (Length(SourceBytes) - SkipBOM) div 2 + 1);
    if SourceCodePage = 1200 then // UTF-16LE
    begin
      Move(SourceBytes[SkipBOM], WideText[1], Length(SourceBytes) - SkipBOM);
    end
    else
    begin
      Flags := 0;
      MultiByteToWideChar(SourceCodePage, Flags, 
        @SourceBytes[SkipBOM], Length(SourceBytes) - SkipBOM, 
        PWideChar(WideText), Length(WideText));
    end;
    
    // 宽字符转换为目标字节
    if TargetCodePage = 1200 then // UTF-16LE
    begin
      SetLength(TargetBytes, Length(WideText) * 2);
      Move(WideText[1], TargetBytes[0], Length(TargetBytes));
    end
    else
    begin
      var WideCharCount := Length(WideText);
      var TargetByteCount := WideCharToMultiByte(TargetCodePage, 0, 
        PWideChar(WideText), WideCharCount, nil, 0, nil, nil);
      
      SetLength(TargetBytes, TargetByteCount);
      WideCharToMultiByte(TargetCodePage, 0, 
        PWideChar(WideText), WideCharCount, 
        @TargetBytes[0], TargetByteCount, nil, nil);
    end;
    
    // 创建目标文件
    TargetStream := TFileStream.Create(ATargetFile, fmCreate);
    try
      // 添加BOM（如果需要）
      if AAddBOM and NeedsBOM(ATargetEncoding) then
      begin
        if SameText(ATargetEncoding, 'UTF-8') then
        begin
          SetLength(BOM, 3);
          BOM[0] := $EF;
          BOM[1] := $BB;
          BOM[2] := $BF;
          TargetStream.WriteBuffer(BOM[0], 3);
        end
        else if SameText(ATargetEncoding, 'UTF-16LE') or SameText(ATargetEncoding, 'Unicode') then
        begin
          SetLength(BOM, 2);
          BOM[0] := $FF;
          BOM[1] := $FE;
          TargetStream.WriteBuffer(BOM[0], 2);
        end
        else if SameText(ATargetEncoding, 'UTF-16BE') then
        begin
          SetLength(BOM, 2);
          BOM[0] := $FE;
          BOM[1] := $FF;
          TargetStream.WriteBuffer(BOM[0], 2);
        end;
      end;
      
      // 写入转换后的内容
      if Length(TargetBytes) > 0 then
        TargetStream.WriteBuffer(TargetBytes[0], Length(TargetBytes));
      
      Result := True;
    finally
      TargetStream.Free;
    end;
  except
    Result := False;
  end;
end;

function TWindowsEncodingComparison.ConvertText(const ASourceText: string;
  const ASourceEncoding, ATargetEncoding: string; AAddBOM: Boolean): string;
var
  SourceCodePage, TargetCodePage: Cardinal;
  SourceBytes, TargetBytes, ResultBytes: TBytes;
  WideText: WideString;
  Flags: DWORD;
  Encoding: TEncoding;
begin
  try
    SourceCodePage := GetCodePage(ASourceEncoding);
    TargetCodePage := GetCodePage(ATargetEncoding);
    
    // 假设源字符串是UTF-16LE（Delphi字符串的内部表示）
    SetLength(WideText, Length(ASourceText));
    if Length(ASourceText) > 0 then
      Move(ASourceText[1], WideText[1], Length(ASourceText) * 2);
    
    // 宽字符转换为目标字节
    var WideCharCount := Length(WideText);
    var TargetByteCount := WideCharToMultiByte(TargetCodePage, 0, 
      PWideChar(WideText), WideCharCount, nil, 0, nil, nil);
    
    SetLength(TargetBytes, TargetByteCount);
    if TargetByteCount > 0 then
    begin
      WideCharToMultiByte(TargetCodePage, 0, 
        PWideChar(WideText), WideCharCount, 
        @TargetBytes[0], TargetByteCount, nil, nil);
    end;
    
    // 添加BOM（如果需要）
    if AAddBOM and NeedsBOM(ATargetEncoding) then
    begin
      if SameText(ATargetEncoding, 'UTF-8') then
      begin
        SetLength(ResultBytes, Length(TargetBytes) + 3);
        ResultBytes[0] := $EF;
        ResultBytes[1] := $BB;
        ResultBytes[2] := $BF;
        if Length(TargetBytes) > 0 then
          Move(TargetBytes[0], ResultBytes[3], Length(TargetBytes));
      end
      else if SameText(ATargetEncoding, 'UTF-16LE') or SameText(ATargetEncoding, 'Unicode') then
      begin
        SetLength(ResultBytes, Length(TargetBytes) + 2);
        ResultBytes[0] := $FF;
        ResultBytes[1] := $FE;
        if Length(TargetBytes) > 0 then
          Move(TargetBytes[0], ResultBytes[2], Length(TargetBytes));
      end
      else if SameText(ATargetEncoding, 'UTF-16BE') then
      begin
        SetLength(ResultBytes, Length(TargetBytes) + 2);
        ResultBytes[0] := $FE;
        ResultBytes[1] := $FF;
        if Length(TargetBytes) > 0 then
          Move(TargetBytes[0], ResultBytes[2], Length(TargetBytes));
      end
      else
        ResultBytes := TargetBytes;
    end
    else
      ResultBytes := TargetBytes;
    
    // 转换字节回Delphi字符串（UTF-16LE）
    if TargetCodePage = 1200 then // UTF-16LE
    begin
      SetLength(Result, Length(ResultBytes) div 2);
      if Length(ResultBytes) > 0 then
        Move(ResultBytes[0], Result[1], Length(ResultBytes));
    end
    else
    begin
      Flags := 0;
      var ResultWideCharCount := MultiByteToWideChar(TargetCodePage, Flags, 
        @ResultBytes[0], Length(ResultBytes), nil, 0);
      
      SetLength(Result, ResultWideCharCount);
      if ResultWideCharCount > 0 then
      begin
        MultiByteToWideChar(TargetCodePage, Flags, 
          @ResultBytes[0], Length(ResultBytes), 
          PWideChar(Result), ResultWideCharCount);
      end;
    end;
  except
    Result := '';
  end;
end;

function TWindowsEncodingComparison.CompareFiles(const AFile1, AFile2: string): Boolean;
var
  MD5File1, MD5File2: string;
begin
  MD5File1 := CalculateMD5(AFile1);
  MD5File2 := CalculateMD5(AFile2);
  
  Result := (MD5File1 <> '') and (MD5File2 <> '') and (MD5File1 = MD5File2);
end;

function TWindowsEncodingComparison.GetFileDifferences(const AFile1,
  AFile2: string): string;
var
  Stream1, Stream2: TFileStream;
  Bytes1, Bytes2: TBytes;
  DiffCount, MaxDiffs: Integer;
  I, MinLen: Integer;
  HexVal1, HexVal2: string;
begin
  Result := '';
  
  if not FileExists(AFile1) or not FileExists(AFile2) then
  begin
    Result := '文件不存在，无法比较差异';
    Exit;
  end;
  
  try
    // 读取文件1内容
    Stream1 := TFileStream.Create(AFile1, fmOpenRead or fmShareDenyNone);
    try
      SetLength(Bytes1, Stream1.Size);
      if Stream1.Size > 0 then
        Stream1.ReadBuffer(Bytes1[0], Stream1.Size);
    finally
      Stream1.Free;
    end;
    
    // 读取文件2内容
    Stream2 := TFileStream.Create(AFile2, fmOpenRead or fmShareDenyNone);
    try
      SetLength(Bytes2, Stream2.Size);
      if Stream2.Size > 0 then
        Stream2.ReadBuffer(Bytes2[0], Stream2.Size);
    finally
      Stream2.Free;
    end;
    
    // 比较文件大小
    if Length(Bytes1) <> Length(Bytes2) then
      Result := Result + Format('文件大小不同: 文件1 = %d 字节, 文件2 = %d 字节' + sLineBreak, 
        [Length(Bytes1), Length(Bytes2)]);
    
    // 比较内容
    DiffCount := 0;
    MaxDiffs := 10; // 最多显示10个差异
    MinLen := Min(Length(Bytes1), Length(Bytes2));
    
    for I := 0 to MinLen - 1 do
    begin
      if Bytes1[I] <> Bytes2[I] then
      begin
        Inc(DiffCount);
        
        if DiffCount <= MaxDiffs then
        begin
          HexVal1 := IntToHex(Bytes1[I], 2);
          HexVal2 := IntToHex(Bytes2[I], 2);
          
          Result := Result + Format('位置 %d: 文件1 = 0x%s, 文件2 = 0x%s' + sLineBreak, 
            [I, HexVal1, HexVal2]);
        end;
      end;
    end;
    
    if DiffCount > MaxDiffs then
      Result := Result + Format('... 共 %d 个差异，已截断显示' + sLineBreak, [DiffCount]);
    
    if DiffCount = 0 and Length(Bytes1) = Length(Bytes2) then
      Result := '文件内容完全相同';
  except
    on E: Exception do
      Result := '比较文件时出错: ' + E.Message;
  end;
end;

end. 