unit UtilsEncodingBOM_Improved;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, UtilsTypes;

type

  /// <summary>
  /// BOM检测结果记??
  /// </summary>
  TBOMDetectionResult = record
    BOMType: Integer;      // BOM类型
    BOMLength: Integer;    // BOM长度（字节数??
    Encoding: string;      // 对应的编码名??
    CodePage: Integer;     // 对应的代码页
  end;

  /// <summary>
  /// 改进的BOM检测器
  /// </summary>
  TEncodingBOMDetector_Improved = class
  private
    // 使用UtilsEncodingConstants中定义的BOM常量

  public
    /// <summary>
    /// 检测字节数组中的BOM
    /// </summary>
    class function DetectBOM(const Buffer: TBytes): TBOMDetectionResult;

    /// <summary>
    /// 检测文件中的BOM（优化：仅读取文件头部）
    /// </summary>
    class function DetectBOMFromFile(const FileName: string): TBOMDetectionResult;

    /// <summary>
    /// 检测流中的BOM
    /// </summary>
    class function DetectBOMFromStream(const Stream: TStream): TBOMDetectionResult;

    /// <summary>
    /// 添加BOM到字节数??
    /// </summary>
    class function AddBOM(const Buffer: TBytes; BOMType: Integer): TBytes;

    /// <summary>
    /// 移除字节数组中的BOM
    /// </summary>
    class function RemoveBOM(const Buffer: TBytes): TBytes;

    /// <summary>
    /// 获取BOM对应的编码名??
    /// </summary>
    class function BOMTypeToEncodingName(BOMType: Integer): string;

    /// <summary>
    /// 获取BOM对应的代码页
    /// </summary>
    class function BOMTypeToCodePage(BOMType: Integer): Integer;

    /// <summary>
    /// 获取BOM的长度（字节数）
    /// </summary>
    class function GetBOMLength(BOMType: Integer): Integer;

    /// <summary>
    /// 获取BOM的字节数??
    /// </summary>
    class function GetBOMBytes(BOMType: Integer): TBytes;
  end;

implementation

const
  // 本地定义未知编码常量，避免依赖 UtilsEncodingTypes
  ENCODING_UNKNOWN = 'Unknown';
  // BOM 字节数组
  BOM_UTF8: array[0..2] of Byte = ($EF, $BB, $BF);
  BOM_UTF16_LE: array[0..1] of Byte = ($FF, $FE);
  BOM_UTF16_BE: array[0..1] of Byte = ($FE, $FF);
  BOM_UTF32_LE: array[0..3] of Byte = ($FF, $FE, $00, $00);
  BOM_UTF32_BE: array[0..3] of Byte = ($00, $00, $FE, $FF);

{ TEncodingBOMDetector_Improved }

class function TEncodingBOMDetector_Improved.AddBOM(const Buffer: TBytes; BOMType: Integer): TBytes;
var
  BOMBytes: TBytes;
begin
  // 获取BOM字节
  BOMBytes := GetBOMBytes(BOMType);
  var BOMLength := Length(BOMBytes);

  // 如果是无BOM类型，直接返回原始缓冲区
  if BOMType = 0 then
  begin
    Result := Copy(Buffer);
    Exit;
  end;

  // 创建新的缓冲区，包含BOM和原始数??
  SetLength(Result, BOMLength + Length(Buffer));

  // 复制BOM
  if BOMLength > 0 then
    Move(BOMBytes[0], Result[0], BOMLength);

  // 复制原始数据
  if Length(Buffer) > 0 then
    Move(Buffer[0], Result[BOMLength], Length(Buffer));
end;

class function TEncodingBOMDetector_Improved.BOMTypeToCodePage(BOMType: Integer): Integer;
begin
  case BOMType of
    1:    Result := 65001; // UTF-8
    2:    Result := 1200;  // UTF-16 LE
    3:    Result := 1201;  // UTF-16 BE
    4:    Result := 12000; // UTF-32 LE
    5:    Result := 12001; // UTF-32 BE
    else  Result := 0;     // 未知
  end;
end;

class function TEncodingBOMDetector_Improved.BOMTypeToEncodingName(BOMType: Integer): string;
begin
  case BOMType of
    1:    Result := ENCODING_UTF8_BOM;
    2:    Result := ENCODING_UTF16_LE;
    3:    Result := ENCODING_UTF16_BE;
    4:    Result := ENCODING_UTF32_LE;
    5:    Result := ENCODING_UTF32_BE;
    else  Result := ENCODING_UNKNOWN;
  end;
end;

class function TEncodingBOMDetector_Improved.DetectBOM(const Buffer: TBytes): TBOMDetectionResult;
begin
  // 初始化结??
  Result.BOMType := 0;
  Result.BOMLength := 0;
  Result.Encoding := ENCODING_UNKNOWN;
  Result.CodePage := 0;

  // 检查缓冲区是否为空
  if Length(Buffer) = 0 then
    Exit;

  // 检查UTF-32 BE BOM (00 00 FE FF)
  if (Length(Buffer) >= 4) and
     (Buffer[0] = BOM_UTF32_BE[0]) and
     (Buffer[1] = BOM_UTF32_BE[1]) and
     (Buffer[2] = BOM_UTF32_BE[2]) and
     (Buffer[3] = BOM_UTF32_BE[3]) then
  begin
    Result.BOMType := 5;
    Result.BOMLength := 4;
    Result.Encoding := ENCODING_UTF32_BE;
    Result.CodePage := 12001;
    Exit;
  end;

  // 检查UTF-32 LE BOM (FF FE 00 00)
  if (Length(Buffer) >= 4) and
     (Buffer[0] = BOM_UTF32_LE[0]) and
     (Buffer[1] = BOM_UTF32_LE[1]) and
     (Buffer[2] = BOM_UTF32_LE[2]) and
     (Buffer[3] = BOM_UTF32_LE[3]) then
  begin
    Result.BOMType := 4;
    Result.BOMLength := 4;
    Result.Encoding := ENCODING_UTF32_LE;
    Result.CodePage := 12000;
    Exit;
  end;

  // 检查UTF-16 BE BOM (FE FF)
  if (Length(Buffer) >= 2) and
     (Buffer[0] = BOM_UTF16_BE[0]) and
     (Buffer[1] = BOM_UTF16_BE[1]) then
  begin
    Result.BOMType := 3;
    Result.BOMLength := 2;
    Result.Encoding := ENCODING_UTF16_BE;
    Result.CodePage := 1201;
    Exit;
  end;

  // 检查UTF-16 LE BOM (FF FE)
  if (Length(Buffer) >= 2) and
     (Buffer[0] = BOM_UTF16_LE[0]) and
     (Buffer[1] = BOM_UTF16_LE[1]) then
  begin
    Result.BOMType := 2;
    Result.BOMLength := 2;
    Result.Encoding := ENCODING_UTF16_LE;
    Result.CodePage := 1200;
    Exit;
  end;

  // 检查UTF-8 BOM (EF BB BF)
  if (Length(Buffer) >= 3) and
     (Buffer[0] = BOM_UTF8[0]) and
     (Buffer[1] = BOM_UTF8[1]) and
     (Buffer[2] = BOM_UTF8[2]) then
  begin
    Result.BOMType := 1;
    Result.BOMLength := 3;
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
begin
  // 检查文件是否存在
  if not FileExists(FileName) then
  begin
    Result.BOMType := 0;
    Result.BOMLength := 0;
    Result.Encoding := ENCODING_UNKNOWN;
    Result.CodePage := 0;
    Exit;
  end;

  // 优化：仅读取文件头部 4 字节用于 BOM 检测
  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Buffer, 4);
    BytesRead := FileStream.Read(Buffer[0], 4);
    SetLength(Buffer, BytesRead);
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
  MAX_BOM_LENGTH = 4;
begin
  // 初始化结??
  Result.BOMType := 0;
  Result.BOMLength := 0;
  Result.Encoding := ENCODING_UNKNOWN;
  Result.CodePage := 0;

  // 检查流是否有效
  if Stream = nil then
    Exit;

  // 保存当前流位??
  Position := Stream.Position;

  try
    // 重置流位??
    Stream.Position := 0;

    // 读取足够检测BOM的字??
    SetLength(Buffer, MAX_BOM_LENGTH);
    BytesRead := Stream.Read(Buffer[0], MAX_BOM_LENGTH);

    // 如果流太小，调整缓冲区大??
    if BytesRead < MAX_BOM_LENGTH then
      SetLength(Buffer, BytesRead);

    // 检测BOM
    Result := DetectBOM(Buffer);
  finally
    // 恢复流位??
    Stream.Position := Position;
  end;
end;

class function TEncodingBOMDetector_Improved.GetBOMBytes(BOMType: Integer): TBytes;
begin
  case BOMType of
    1: // UTF-8
      begin
        SetLength(Result, 3);
        Result[0] := BOM_UTF8[0];
        Result[1] := BOM_UTF8[1];
        Result[2] := BOM_UTF8[2];
      end;
    2: // UTF-16 LE
      begin
        SetLength(Result, 2);
        Result[0] := BOM_UTF16_LE[0];
        Result[1] := BOM_UTF16_LE[1];
      end;
    3: // UTF-16 BE
      begin
        SetLength(Result, 2);
        Result[0] := BOM_UTF16_BE[0];
        Result[1] := BOM_UTF16_BE[1];
      end;
    4: // UTF-32 LE
      begin
        SetLength(Result, 4);
        Result[0] := BOM_UTF32_LE[0];
        Result[1] := BOM_UTF32_LE[1];
        Result[2] := BOM_UTF32_LE[2];
        Result[3] := BOM_UTF32_LE[3];
      end;
    5: // UTF-32 BE
      begin
        SetLength(Result, 4);
        Result[0] := BOM_UTF32_BE[0];
        Result[1] := BOM_UTF32_BE[1];
        Result[2] := BOM_UTF32_BE[2];
        Result[3] := BOM_UTF32_BE[3];
      end;
    else
      SetLength(Result, 0);
  end;
end;

class function TEncodingBOMDetector_Improved.GetBOMLength(BOMType: Integer): Integer;
begin
  case BOMType of
    1:    Result := 3; // UTF-8
    2:    Result := 2; // UTF-16 LE
    3:    Result := 2; // UTF-16 BE
    4:    Result := 4; // UTF-32 LE
    5:    Result := 4; // UTF-32 BE
    else  Result := 0;
  end;
end;

class function TEncodingBOMDetector_Improved.RemoveBOM(const Buffer: TBytes): TBytes;
var
  BOMResult: TBOMDetectionResult;
begin
  // 检测BOM
  BOMResult := DetectBOM(Buffer);

  // 如果没有BOM，直接返回原始缓冲区
  if BOMResult.BOMType = 0 then
  begin
    Result := Copy(Buffer);
    Exit;
  end;

  // 创建新的缓冲区，不包含BOM
  SetLength(Result, Length(Buffer) - BOMResult.BOMLength);

  // 复制BOM之后的数??
  if Length(Result) > 0 then
    Move(Buffer[BOMResult.BOMLength], Result[0], Length(Result));
end;

end.
