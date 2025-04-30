unit UtilsEncodingBOM_Improved;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, UtilsEncodingTypes;

type
  /// <summary>
  /// BOM类型枚举
  /// </summary>
  TBOMType = (
    bomNone,      // 无BOM
    bomUTF8,      // UTF-8 BOM (EF BB BF)
    bomUTF16LE,   // UTF-16 Little Endian BOM (FF FE)
    bomUTF16BE,   // UTF-16 Big Endian BOM (FE FF)
    bomUTF32LE,   // UTF-32 Little Endian BOM (FF FE 00 00)
    bomUTF32BE    // UTF-32 Big Endian BOM (00 00 FE FF)
  );

  /// <summary>
  /// BOM检测结果记录
  /// </summary>
  TBOMDetectionResult = record
    BOMType: TBOMType;     // BOM类型
    BOMSize: Integer;      // BOM大小（字节数）
    Encoding: string;      // 对应的编码名称
    CodePage: Integer;     // 对应的代码页
  end;

  /// <summary>
  /// 改进的BOM检测器
  /// </summary>
  TEncodingBOMDetector_Improved = class
  private
    const
      // BOM标记定义
      UTF8_BOM: array[0..2] of Byte = ($EF, $BB, $BF);
      UTF16LE_BOM: array[0..1] of Byte = ($FF, $FE);
      UTF16BE_BOM: array[0..1] of Byte = ($FE, $FF);
      UTF32LE_BOM: array[0..3] of Byte = ($FF, $FE, $00, $00);
      UTF32BE_BOM: array[0..3] of Byte = ($00, $00, $FE, $FF);

  public
    /// <summary>
    /// 检测字节数组中的BOM
    /// </summary>
    class function DetectBOM(const Buffer: TBytes): TBOMDetectionResult;
    
    /// <summary>
    /// 检测文件中的BOM
    /// </summary>
    class function DetectBOMFromFile(const FileName: string): TBOMDetectionResult;
    
    /// <summary>
    /// 检测流中的BOM
    /// </summary>
    class function DetectBOMFromStream(const Stream: TStream): TBOMDetectionResult;
    
    /// <summary>
    /// 添加BOM到字节数组
    /// </summary>
    class function AddBOM(const Buffer: TBytes; BOMType: TBOMType): TBytes;
    
    /// <summary>
    /// 移除字节数组中的BOM
    /// </summary>
    class function RemoveBOM(const Buffer: TBytes): TBytes;
    
    /// <summary>
    /// 获取BOM对应的编码名称
    /// </summary>
    class function BOMTypeToEncodingName(BOMType: TBOMType): string;
    
    /// <summary>
    /// 获取BOM对应的代码页
    /// </summary>
    class function BOMTypeToCodePage(BOMType: TBOMType): Integer;
    
    /// <summary>
    /// 获取BOM的大小（字节数）
    /// </summary>
    class function GetBOMSize(BOMType: TBOMType): Integer;
    
    /// <summary>
    /// 获取BOM的字节数组
    /// </summary>
    class function GetBOMBytes(BOMType: TBOMType): TBytes;
  end;

implementation

{ TEncodingBOMDetector_Improved }

class function TEncodingBOMDetector_Improved.AddBOM(const Buffer: TBytes; BOMType: TBOMType): TBytes;
var
  BOMBytes: TBytes;
  BOMSize: Integer;
begin
  // 获取BOM字节
  BOMBytes := GetBOMBytes(BOMType);
  BOMSize := Length(BOMBytes);
  
  // 如果是无BOM类型，直接返回原始缓冲区
  if BOMType = bomNone then
  begin
    Result := Copy(Buffer);
    Exit;
  end;
  
  // 创建新的缓冲区，包含BOM和原始数据
  SetLength(Result, BOMSize + Length(Buffer));
  
  // 复制BOM
  if BOMSize > 0 then
    Move(BOMBytes[0], Result[0], BOMSize);
    
  // 复制原始数据
  if Length(Buffer) > 0 then
    Move(Buffer[0], Result[BOMSize], Length(Buffer));
end;

class function TEncodingBOMDetector_Improved.BOMTypeToCodePage(BOMType: TBOMType): Integer;
begin
  case BOMType of
    bomUTF8:    Result := 65001; // UTF-8
    bomUTF16LE: Result := 1200;  // UTF-16 LE
    bomUTF16BE: Result := 1201;  // UTF-16 BE
    bomUTF32LE: Result := 12000; // UTF-32 LE
    bomUTF32BE: Result := 12001; // UTF-32 BE
    else        Result := 0;     // 未知
  end;
end;

class function TEncodingBOMDetector_Improved.BOMTypeToEncodingName(BOMType: TBOMType): string;
begin
  case BOMType of
    bomUTF8:    Result := ENCODING_UTF8_BOM;
    bomUTF16LE: Result := ENCODING_UTF16_LE;
    bomUTF16BE: Result := ENCODING_UTF16_BE;
    bomUTF32LE: Result := ENCODING_UTF32_LE;
    bomUTF32BE: Result := ENCODING_UTF32_BE;
    else        Result := ENCODING_UNKNOWN;
  end;
end;

class function TEncodingBOMDetector_Improved.DetectBOM(const Buffer: TBytes): TBOMDetectionResult;
begin
  // 初始化结果
  Result.BOMType := bomNone;
  Result.BOMSize := 0;
  Result.Encoding := ENCODING_UNKNOWN;
  Result.CodePage := 0;
  
  // 检查缓冲区是否为空
  if Length(Buffer) = 0 then
    Exit;
    
  // 检查UTF-32 BE BOM (00 00 FE FF)
  if (Length(Buffer) >= 4) and
     (Buffer[0] = UTF32BE_BOM[0]) and
     (Buffer[1] = UTF32BE_BOM[1]) and
     (Buffer[2] = UTF32BE_BOM[2]) and
     (Buffer[3] = UTF32BE_BOM[3]) then
  begin
    Result.BOMType := bomUTF32BE;
    Result.BOMSize := 4;
    Result.Encoding := ENCODING_UTF32_BE;
    Result.CodePage := 12001;
    Exit;
  end;
  
  // 检查UTF-32 LE BOM (FF FE 00 00)
  if (Length(Buffer) >= 4) and
     (Buffer[0] = UTF32LE_BOM[0]) and
     (Buffer[1] = UTF32LE_BOM[1]) and
     (Buffer[2] = UTF32LE_BOM[2]) and
     (Buffer[3] = UTF32LE_BOM[3]) then
  begin
    Result.BOMType := bomUTF32LE;
    Result.BOMSize := 4;
    Result.Encoding := ENCODING_UTF32_LE;
    Result.CodePage := 12000;
    Exit;
  end;
  
  // 检查UTF-16 BE BOM (FE FF)
  if (Length(Buffer) >= 2) and
     (Buffer[0] = UTF16BE_BOM[0]) and
     (Buffer[1] = UTF16BE_BOM[1]) then
  begin
    Result.BOMType := bomUTF16BE;
    Result.BOMSize := 2;
    Result.Encoding := ENCODING_UTF16_BE;
    Result.CodePage := 1201;
    Exit;
  end;
  
  // 检查UTF-16 LE BOM (FF FE)
  if (Length(Buffer) >= 2) and
     (Buffer[0] = UTF16LE_BOM[0]) and
     (Buffer[1] = UTF16LE_BOM[1]) then
  begin
    Result.BOMType := bomUTF16LE;
    Result.BOMSize := 2;
    Result.Encoding := ENCODING_UTF16_LE;
    Result.CodePage := 1200;
    Exit;
  end;
  
  // 检查UTF-8 BOM (EF BB BF)
  if (Length(Buffer) >= 3) and
     (Buffer[0] = UTF8_BOM[0]) and
     (Buffer[1] = UTF8_BOM[1]) and
     (Buffer[2] = UTF8_BOM[2]) then
  begin
    Result.BOMType := bomUTF8;
    Result.BOMSize := 3;
    Result.Encoding := ENCODING_UTF8_BOM;
    Result.CodePage := 65001;
    Exit;
  end;
end;

class function TEncodingBOMDetector_Improved.DetectBOMFromFile(const FileName: string): TBOMDetectionResult;
var
  FileStream: TFileStream;
  Buffer: TBytes;
  BytesRead: Integer;
const
  MAX_BOM_SIZE = 4;
begin
  // 初始化结果
  Result.BOMType := bomNone;
  Result.BOMSize := 0;
  Result.Encoding := ENCODING_UNKNOWN;
  Result.CodePage := 0;
  
  // 检查文件是否存在
  if not FileExists(FileName) then
    Exit;
    
  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    // 读取足够检测BOM的字节
    SetLength(Buffer, MAX_BOM_SIZE);
    BytesRead := FileStream.Read(Buffer[0], MAX_BOM_SIZE);
    
    // 如果文件太小，调整缓冲区大小
    if BytesRead < MAX_BOM_SIZE then
      SetLength(Buffer, BytesRead);
      
    // 检测BOM
    Result := DetectBOM(Buffer);
  finally
    FileStream.Free;
  end;
end;

class function TEncodingBOMDetector_Improved.DetectBOMFromStream(const Stream: TStream): TBOMDetectionResult;
var
  Buffer: TBytes;
  Position: Int64;
  BytesRead: Integer;
const
  MAX_BOM_SIZE = 4;
begin
  // 初始化结果
  Result.BOMType := bomNone;
  Result.BOMSize := 0;
  Result.Encoding := ENCODING_UNKNOWN;
  Result.CodePage := 0;
  
  // 检查流是否有效
  if Stream = nil then
    Exit;
    
  // 保存当前流位置
  Position := Stream.Position;
  
  try
    // 重置流位置
    Stream.Position := 0;
    
    // 读取足够检测BOM的字节
    SetLength(Buffer, MAX_BOM_SIZE);
    BytesRead := Stream.Read(Buffer[0], MAX_BOM_SIZE);
    
    // 如果流太小，调整缓冲区大小
    if BytesRead < MAX_BOM_SIZE then
      SetLength(Buffer, BytesRead);
      
    // 检测BOM
    Result := DetectBOM(Buffer);
  finally
    // 恢复流位置
    Stream.Position := Position;
  end;
end;

class function TEncodingBOMDetector_Improved.GetBOMBytes(BOMType: TBOMType): TBytes;
begin
  case BOMType of
    bomUTF8:
      begin
        SetLength(Result, 3);
        Result[0] := UTF8_BOM[0];
        Result[1] := UTF8_BOM[1];
        Result[2] := UTF8_BOM[2];
      end;
    bomUTF16LE:
      begin
        SetLength(Result, 2);
        Result[0] := UTF16LE_BOM[0];
        Result[1] := UTF16LE_BOM[1];
      end;
    bomUTF16BE:
      begin
        SetLength(Result, 2);
        Result[0] := UTF16BE_BOM[0];
        Result[1] := UTF16BE_BOM[1];
      end;
    bomUTF32LE:
      begin
        SetLength(Result, 4);
        Result[0] := UTF32LE_BOM[0];
        Result[1] := UTF32LE_BOM[1];
        Result[2] := UTF32LE_BOM[2];
        Result[3] := UTF32LE_BOM[3];
      end;
    bomUTF32BE:
      begin
        SetLength(Result, 4);
        Result[0] := UTF32BE_BOM[0];
        Result[1] := UTF32BE_BOM[1];
        Result[2] := UTF32BE_BOM[2];
        Result[3] := UTF32BE_BOM[3];
      end;
    else
      SetLength(Result, 0);
  end;
end;

class function TEncodingBOMDetector_Improved.GetBOMSize(BOMType: TBOMType): Integer;
begin
  case BOMType of
    bomUTF8:    Result := 3;
    bomUTF16LE: Result := 2;
    bomUTF16BE: Result := 2;
    bomUTF32LE: Result := 4;
    bomUTF32BE: Result := 4;
    else        Result := 0;
  end;
end;

class function TEncodingBOMDetector_Improved.RemoveBOM(const Buffer: TBytes): TBytes;
var
  BOMResult: TBOMDetectionResult;
begin
  // 检测BOM
  BOMResult := DetectBOM(Buffer);
  
  // 如果没有BOM，直接返回原始缓冲区
  if BOMResult.BOMType = bomNone then
  begin
    Result := Copy(Buffer);
    Exit;
  end;
  
  // 创建新的缓冲区，不包含BOM
  SetLength(Result, Length(Buffer) - BOMResult.BOMSize);
  
  // 复制BOM之后的数据
  if Length(Result) > 0 then
    Move(Buffer[BOMResult.BOMSize], Result[0], Length(Result));
end;

end.
