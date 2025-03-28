unit UtilsUTF8;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Math, Winapi.Windows;

// 检查UTF-8编码是否有效
function IsValidUTF8(Buffer: PByte; Size: Integer): Boolean;


// 检测文件编码
function DetectEncoding(const FileName: string): string;
function DetectTextEncoding(const FileName: string): TEncoding;

// 将文件转换为UTF-8编码
function ConvertFileToUTF8(const FileName: string; const OutputFileName: string = ''): Boolean;

// 将文件夹中的所有文件转换为UTF-8编码
function ConvertFolderToUTF8(const FolderPath: string; Recursive: Boolean = True): Integer;

// 批量转换文件为UTF-8
function BatchConvertToUTF8(const Files: TArray<string>): Integer;

// 从字节数组中检测编码
function DetectEncodingFromBytes(const Bytes: TBytes; out Encoding: TEncoding): Boolean;

// 获取文本前面的BOM（字节顺序标记）
function GetBOMFromBytes(const Bytes: TBytes; MaxLength: Integer = 4): TBytes;

implementation


// 检查UTF-8编码是否有效
function IsValidUTF8(Buffer: PByte; Size: Integer): Boolean;
var
  i, CharLen: Integer;
  ValidSequences, TotalBytes: Integer;
begin
  Result := True;
  i := 0;
  ValidSequences := 0;
  TotalBytes := 0;
  
  while i < Size do
  begin
    Inc(TotalBytes);
    
    // 单字节 ASCII (0-127)
    if Buffer[i] < $80 then
    begin
      Inc(i);
      Continue;
    end;
    
    // 检查首字节
    if Buffer[i] < $C0 then
    begin
      // 无效的UTF-8序列（连续字节出现在首位）
      Result := False;
      Exit;
    end
    
    // 2字节序列 (192-223)
    else if Buffer[i] < $E0 then
      CharLen := 2
      
    // 3字节序列 (224-239)
    else if Buffer[i] < $F0 then
      CharLen := 3
      
    // 4字节序列 (240-247)
    else if Buffer[i] < $F8 then
      CharLen := 4
      
    // 无效的UTF-8首字节
    else
    begin
      Result := False;
      Exit;
    end;
    
    // 确保有足够的字节
    if i + CharLen > Size then
    begin
      Result := False;
      Exit;
    end;
    
    // 检查连续字节 (128-191)
    for var j := 1 to CharLen - 1 do
    begin
      if (Buffer[i + j] < $80) or (Buffer[i + j] >= $C0) then
      begin
        Result := False;
        Exit;
      end;
    end;
    
    Inc(ValidSequences);
    Inc(i, CharLen);
  end;
  
  // 确保文件包含足够的有效UTF-8序列
  Result := (TotalBytes > 0) and (ValidSequences > 0);
end;


// 检测文件编码
function DetectEncoding(const FileName: string): string;
var
  Bytes: TBytes;
  Encoding: TEncoding;
  HasBOM: Boolean;
begin
  Bytes := TFile.ReadAllBytes(FileName);
  HasBOM := DetectEncodingFromBytes(Bytes, Encoding);
  
  if Encoding = TEncoding.UTF8 then
  begin
    if HasBOM then
      Result := 'UTF-8 BOM'
    else
      Result := 'UTF-8'
  end
  else if Encoding = TEncoding.ASCII then
    Result := 'ANSI'
  else
    Result := Encoding.EncodingName;
end;

function DetectTextEncoding(const FileName: string): TEncoding;
var
  Stream: TFileStream;
  Buffer: TBytes;
  Encoding: TEncoding;
begin
  Result := TEncoding.Default;
  
  if not FileExists(FileName) then
    Exit;
    
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Buffer, Min(Stream.Size, 1024));
    if Length(Buffer) > 0 then
      Stream.ReadBuffer(Buffer[0], Length(Buffer));
      
    if DetectEncodingFromBytes(Buffer, Encoding) then
      Result := Encoding
    else
      Result := TEncoding.Default;
  finally
    Stream.Free;
  end;
end;

// 将文件转换为UTF-8编码
function ConvertFileToUTF8(const FileName: string; const OutputFileName: string = ''): Boolean;
var
  SourceStream, DestStream: TFileStream;
  Buffer: TBytes;
  SourceEncoding: TEncoding;
  OutputPath: string;
begin
  Result := False;
  
  if not FileExists(FileName) then
    Exit;
    
  // 确定输出文件名
  if OutputFileName = '' then
    OutputPath := FileName
  else
    OutputPath := OutputFileName;
    
  try
    // 读取源文件
    SourceStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      SetLength(Buffer, SourceStream.Size);
      if Length(Buffer) > 0 then
        SourceStream.ReadBuffer(Buffer[0], Length(Buffer));
    finally
      SourceStream.Free;
    end;
    
    // 检测源文件编码
    if not DetectEncodingFromBytes(Buffer, SourceEncoding) then
      SourceEncoding := TEncoding.Default;
      
    // 如果已经是UTF-8 BOM，且输出路径相同，则无需转换
    if (SourceEncoding = TEncoding.UTF8) and (OutputPath = FileName) then
    begin
      Result := True;
      Exit;
    end;
    
    // 转换并写入目标文件
    DestStream := TFileStream.Create(OutputPath, fmCreate);
    try
      // 写入UTF-8 BOM
      var UTF8BOM := TEncoding.UTF8.GetPreamble;
      if Length(UTF8BOM) > 0 then
        DestStream.WriteBuffer(UTF8BOM[0], Length(UTF8BOM));
      
      // 转换并写入内容
      var UTF8Bytes := TEncoding.UTF8.GetBytes(
        SourceEncoding.GetString(Buffer));
      if Length(UTF8Bytes) > 0 then
        DestStream.WriteBuffer(UTF8Bytes[0], Length(UTF8Bytes));
        
      Result := True;
    finally
      DestStream.Free;
    end;
  except
    Result := False;
  end;
end;

// 将文件夹中的所有文件转换为UTF-8编码
function ConvertFolderToUTF8(const FolderPath: string; Recursive: Boolean = True): Integer;
var
  FileList: TArray<string>;
  FileName: string;
  Option: TSearchOption;
begin
  Result := 0;
  
  if not System.SysUtils.DirectoryExists(FolderPath) then
    Exit;
    
  // 设置搜索选项
  if Recursive then
    Option := TSearchOption.soAllDirectories
  else
    Option := TSearchOption.soTopDirectoryOnly;
    
  try
    // 获取所有.pas和.dfm文件
    FileList := TDirectory.GetFiles(FolderPath, '*.pas', Option);
    for FileName in FileList do
    begin
      if ConvertFileToUTF8(FileName) then
        Inc(Result);
    end;
    
    FileList := TDirectory.GetFiles(FolderPath, '*.dfm', Option);
    for FileName in FileList do
    begin
      if ConvertFileToUTF8(FileName) then
        Inc(Result);
    end;
  except
    // 忽略错误，继续处理其他文件
  end;
end;

// 批量转换文件为UTF-8
function BatchConvertToUTF8(const Files: TArray<string>): Integer;
var
  FileName: string;
begin
  Result := 0;
  
  for FileName in Files do
  begin
    if FileExists(FileName) and ConvertFileToUTF8(FileName) then
      Inc(Result);
  end;
end;

// 从字节数组中检测编码
function DetectEncodingFromBytes(const Bytes: TBytes; out Encoding: TEncoding): Boolean;
var
  BOM: TBytes;
begin
  Result := True;
  
  if Length(Bytes) >= 2 then
  begin
    BOM := GetBOMFromBytes(Bytes);
    
    // UTF-8 BOM: EF BB BF
    if (Length(BOM) >= 3) and (BOM[0] = $EF) and (BOM[1] = $BB) and (BOM[2] = $BF) then
    begin
      Encoding := TEncoding.UTF8;
      Result := True;
    end
    // UTF-16 LE BOM: FF FE
    else if (Length(BOM) >= 2) and (BOM[0] = $FF) and (BOM[1] = $FE) then
    begin
      Encoding := TEncoding.Unicode;
      Result := True;
    end
    // UTF-16 BE BOM: FE FF
    else if (Length(BOM) >= 2) and (BOM[0] = $FE) and (BOM[1] = $FF) then
    begin
      Encoding := TEncoding.BigEndianUnicode;
      Result := True;
    end
    // UTF-32 LE BOM: FF FE 00 00
    else if (Length(BOM) >= 4) and (BOM[0] = $FF) and (BOM[1] = $FE) and (BOM[2] = $00) and (BOM[3] = $00) then
    begin
      Encoding := TEncoding.GetEncoding(12000); // UTF-32 LE
      Result := True;
    end
    // 如果没有BOM但内容符合UTF-8格式
    else if (Length(Bytes) > 0) and IsValidUTF8(@Bytes[0], Length(Bytes)) then
    begin
      Encoding := TEncoding.UTF8;
      Result := False; // 无BOM的UTF-8
    end
    // 默认使用ANSI编码
    else
    begin
      Encoding := TEncoding.Default;
      Result := False;
    end;
  end
  else
  begin
    Encoding := TEncoding.Default;
    Result := False;
  end;
end;

// 获取文本前面的BOM（字节顺序标记）
function GetBOMFromBytes(const Bytes: TBytes; MaxLength: Integer = 4): TBytes;
var
  BOMLength: Integer;
begin
  if Length(Bytes) = 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;
  
  BOMLength := Min(MaxLength, Length(Bytes));
  SetLength(Result, BOMLength);
  
  Move(Bytes[0], Result[0], BOMLength);
end;

end.