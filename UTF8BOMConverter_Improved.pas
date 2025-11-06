unit UTF8BOMConverter_Improved;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, UtilsTypes,
  UtilsEncodingBOM_Improved, UtilsEncodingUTF8Detector_Improved;

type
  /// <summary>
  /// UTF-8 BOM转换结果记录
  /// </summary>
  TUTF8BOMConversionResult = record
    Success: Boolean;           // 转换是否成功
    OriginalEncoding: string;   // 原始编码
    TargetEncoding: string;     // 目标编码
    HasBOM: Boolean;            // 是否有BOM
    BytesProcessed: Int64;      // 处理的字节数
    ErrorMessage: string;       // 错误信息
  end;

  /// <summary>
  /// 改进的UTF-8 BOM转换�?
  /// </summary>
  TUTF8BOMConverter_Improved = class
  private
    const
      UTF8_BOM: array[0..2] of Byte = ($EF, $BB, $BF);

    /// <summary>
    /// 检查文件是否是UTF-8编码
    /// </summary>
    class function IsUTF8File(const FileName: string; out HasBOM: Boolean): Boolean;


    /// <summary>
    /// 添加UTF-8 BOM到字节数�?
    /// </summary>
    class function AddUTF8BOM(const Buffer: TBytes): TBytes;

    /// <summary>
    /// 移除UTF-8 BOM
    /// </summary>
    class function RemoveUTF8BOM(const Buffer: TBytes): TBytes;

  public
    /// <summary>
    /// 将文件转换为UTF-8+BOM编码
    /// </summary>
    class function ConvertToUTF8WithBOM(const SourceFileName, TargetFileName: string): TUTF8BOMConversionResult;

    /// <summary>
    /// 将文件转换为UTF-8无BOM编码
    /// </summary>
    class function ConvertToUTF8WithoutBOM(const SourceFileName, TargetFileName: string): TUTF8BOMConversionResult;

    /// <summary>
    /// 添加UTF-8 BOM到文�?
    /// </summary>
    class function AddBOMToUTF8File(const SourceFileName, TargetFileName: string): TUTF8BOMConversionResult;

    /// <summary>
    /// 从UTF-8文件中移除BOM
    /// </summary>
    class function RemoveBOMFromUTF8File(const SourceFileName, TargetFileName: string): TUTF8BOMConversionResult;

    /// <summary>
    /// 检查文件是否有UTF-8 BOM
    /// </summary>
    class function HasUTF8BOM(const FileName: string): Boolean;
  end;

implementation

const
  // 本地定义未知编码常量，避免依赖旧的 UtilsEncodingTypes
  ENCODING_UNKNOWN = 'Unknown';

// 从指定代码页的字符串转换为Unicode字符�?
function StringToUnicodeString(const Source: PAnsiChar; CodePage: Integer; SourceLength: Integer): UnicodeString;
var
  DestLength: Integer;
begin
  if (Source = nil) or (SourceLength <= 0) then
  begin
    Result := '';
    Exit;
  end;

  // 获取所需的Unicode字符�?
  DestLength := MultiByteToWideChar(CodePage, 0, Source, SourceLength, nil, 0);

  if DestLength <= 0 then
  begin
    Result := '';
    Exit;
  end;

  // 设置结果字符串长�?
  SetLength(Result, DestLength);

  // 执行转换
  MultiByteToWideChar(CodePage, 0, Source, SourceLength, PWideChar(Result), DestLength);
end;

{ TUTF8BOMConverter_Improved }

class function TUTF8BOMConverter_Improved.AddBOMToUTF8File(const SourceFileName, TargetFileName: string): TUTF8BOMConversionResult;
var
  SourceStream, TargetStream: TFileStream;
  Buffer: TBytes;
  HasBOM: Boolean;
  BOMResult: TBOMDetectionResult;
begin
  // 初始化结�?
  Result.Success := False;
  Result.OriginalEncoding := ENCODING_UNKNOWN;
  Result.TargetEncoding := ENCODING_UTF8_BOM;
  Result.HasBOM := False;
  Result.BytesProcessed := 0;
  Result.ErrorMessage := '';

  // 检查源文件是否存在
  if not FileExists(SourceFileName) then
  begin
    Result.ErrorMessage := '源文件不存在';
    Exit;
  end;

  try
    // 检查源文件是否是UTF-8编码
    if not IsUTF8File(SourceFileName, HasBOM) then
    begin
      Result.ErrorMessage := '源文件不是UTF-8编码';
      Exit;
    end;

    // 设置原始编码
    if HasBOM then
      Result.OriginalEncoding := ENCODING_UTF8_BOM
    else
      Result.OriginalEncoding := ENCODING_UTF8;

    Result.HasBOM := HasBOM;

    // 如果已经有BOM，并且源文件和目标文件相同，则不需要处�?
    if HasBOM and (SourceFileName = TargetFileName) then
    begin
      Result.Success := True;
      Result.BytesProcessed := 0;
      Exit;
    end;

    // 读取源文�?
    SourceStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyNone);
    try
      // 检测BOM
      BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromStream(SourceStream);

      // 读取文件内容
      SourceStream.Position := BOMResult.BOMLength; // 跳过BOM（如果有�?
      SetLength(Buffer, SourceStream.Size - BOMResult.BOMLength);

      if Length(Buffer) > 0 then
        SourceStream.ReadBuffer(Buffer[0], Length(Buffer));

      // 检查是否已经有BOM
      var AlreadyHasBOM := (Length(Buffer) >= 3) and
                         (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF);

      // 添加BOM（如果需要）
      var BufferWithBOM: TBytes;
      if AlreadyHasBOM then
        BufferWithBOM := Copy(Buffer)
      else
        BufferWithBOM := AddUTF8BOM(Buffer);

      // 写入目标文件
      TargetStream := TFileStream.Create(TargetFileName, fmCreate);
      try
        if Length(BufferWithBOM) > 0 then
          TargetStream.WriteBuffer(BufferWithBOM[0], Length(BufferWithBOM));

        Result.Success := True;
        Result.BytesProcessed := Length(BufferWithBOM);
      finally
        TargetStream.Free;
      end;
    finally
      SourceStream.Free;
    end;
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
    end;
  end;
end;

class function TUTF8BOMConverter_Improved.AddUTF8BOM(const Buffer: TBytes): TBytes;
begin
  // 使用BOM检测器的AddBOM方法
  Result := TEncodingBOMDetector_Improved.AddBOM(Buffer, 1);
end;

class function TUTF8BOMConverter_Improved.ConvertToUTF8WithBOM(const SourceFileName, TargetFileName: string): TUTF8BOMConversionResult;
var
  SourceStream, TargetStream: TFileStream;
  Buffer, ConvertedBuffer: TBytes;
  SourceEncoding: string;
  BOMResult: TBOMDetectionResult;
  UTF8Result: TUTF8DetectionResult;
begin
  // 初始化结�?
  Result.Success := False;
  Result.OriginalEncoding := ENCODING_UNKNOWN;
  Result.TargetEncoding := ENCODING_UTF8_BOM;
  Result.HasBOM := False;
  Result.BytesProcessed := 0;
  Result.ErrorMessage := '';

  // 检查源文件是否存在
  if not FileExists(SourceFileName) then
  begin
    Result.ErrorMessage := '源文件不存在';
    Exit;
  end;

  try
    // 检测源文件编码
    UTF8Result := TUTF8EncodingDetector_Improved.DetectFile(SourceFileName);
    BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromFile(SourceFileName);

    // 设置原始编码
    if BOMResult.BOMType <> 0 then
      SourceEncoding := BOMResult.Encoding
    else if UTF8Result.IsUTF8 then
      SourceEncoding := ENCODING_UTF8
    else
      SourceEncoding := ENCODING_ANSI;

    Result.OriginalEncoding := SourceEncoding;
    Result.HasBOM := (BOMResult.BOMType = 1);

    // 如果已经是UTF-8+BOM，并且源文件和目标文件相同，则不需要处�?
    if (CompareText(SourceEncoding, ENCODING_UTF8_BOM) = 0) and (SourceFileName = TargetFileName) then
    begin
      Result.Success := True;
      Result.BytesProcessed := 0;
      Exit;
    end;

    // 读取源文�?
    SourceStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyNone);
    try
      // 读取文件内容
      SourceStream.Position := BOMResult.BOMLength; // 跳过BOM（如果有�?
      SetLength(Buffer, SourceStream.Size - BOMResult.BOMLength);

      if Length(Buffer) > 0 then
        SourceStream.ReadBuffer(Buffer[0], Length(Buffer));

      // 根据源编码进行转�?
      if (CompareText(SourceEncoding, ENCODING_UTF8) = 0) or (CompareText(SourceEncoding, ENCODING_UTF8_BOM) = 0) then
      begin
        // 已经是UTF-8，检查是否已经有BOM
        var HasBOM := (Length(Buffer) >= 3) and
                     (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF);

        if HasBOM then
          // 已经有BOM，直接使用原始缓冲区
          ConvertedBuffer := Copy(Buffer)
        else
          // 没有BOM，添加BOM
          ConvertedBuffer := AddUTF8BOM(Buffer);
      end
      else
      begin
        // 需要从其他编码转换为UTF-8
        var WideStr: UnicodeString;
        var UTF8Str: UTF8String;

        if Length(Buffer) > 0 then
        begin
          var SourceCodePage := 0;

          if CompareText(SourceEncoding, ENCODING_ANSI) = 0 then
            SourceCodePage := GetACP() // 使用系统默认ANSI代码页
          else if CompareText(SourceEncoding, ENCODING_GBK) = 0 then
            SourceCodePage := 936 // GBK代码页
          else if CompareText(SourceEncoding, ENCODING_BIG5) = 0 then
            SourceCodePage := 950 // Big5代码页
          else
            SourceCodePage := TEncodingBOMDetector_Improved.BOMTypeToCodePage(BOMResult.BOMType);

          if SourceCodePage = 0 then
            SourceCodePage := GetACP(); // 默认使用系统ANSI代码页

          // 从源编码转换为Unicode
          WideStr := StringToUnicodeString(PAnsiChar(@Buffer[0]), SourceCodePage, Length(Buffer));

          // 从Unicode转换为UTF-8
          UTF8Str := UTF8Encode(WideStr);

          // 创建UTF-8字节数组
          SetLength(ConvertedBuffer, Length(UTF8Str));
          if Length(UTF8Str) > 0 then
            Move(UTF8Str[1], ConvertedBuffer[0], Length(UTF8Str));

          // 添加BOM
          ConvertedBuffer := AddUTF8BOM(ConvertedBuffer);
        end
        else
        begin
          // 空文件，只添加BOM
          SetLength(ConvertedBuffer, 3);
          ConvertedBuffer[0] := UTF8_BOM[0];
          ConvertedBuffer[1] := UTF8_BOM[1];
          ConvertedBuffer[2] := UTF8_BOM[2];
        end;
      end;

      // 写入目标文件
      TargetStream := TFileStream.Create(TargetFileName, fmCreate);
      try
        if Length(ConvertedBuffer) > 0 then
          TargetStream.WriteBuffer(ConvertedBuffer[0], Length(ConvertedBuffer));

        Result.Success := True;
        Result.BytesProcessed := Length(ConvertedBuffer);
      finally
        TargetStream.Free;
      end;
    finally
      SourceStream.Free;
    end;
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
    end;
  end;
end;

class function TUTF8BOMConverter_Improved.ConvertToUTF8WithoutBOM(const SourceFileName, TargetFileName: string): TUTF8BOMConversionResult;
var
  SourceStream, TargetStream: TFileStream;
  Buffer, ConvertedBuffer: TBytes;
  SourceEncoding: string;
  BOMResult: TBOMDetectionResult;
  UTF8Result: TUTF8DetectionResult;
begin
  // 初始化结�?
  Result.Success := False;
  Result.OriginalEncoding := ENCODING_UNKNOWN;
  Result.TargetEncoding := ENCODING_UTF8;
  Result.HasBOM := False;
  Result.BytesProcessed := 0;
  Result.ErrorMessage := '';

  // 检查源文件是否存在
  if not FileExists(SourceFileName) then
  begin
    Result.ErrorMessage := '源文件不存在';
    Exit;
  end;

  try
    // 检测源文件编码
    UTF8Result := TUTF8EncodingDetector_Improved.DetectFile(SourceFileName);
    BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromFile(SourceFileName);

    // 设置原始编码
    if BOMResult.BOMType <> 0 then
      SourceEncoding := BOMResult.Encoding
    else if UTF8Result.IsUTF8 then
      SourceEncoding := ENCODING_UTF8
    else
      SourceEncoding := ENCODING_ANSI;

    Result.OriginalEncoding := SourceEncoding;
    Result.HasBOM := (BOMResult.BOMType = 1);

    // 如果已经是UTF-8无BOM，并且源文件和目标文件相同，则不需要处�?
    if (CompareText(SourceEncoding, ENCODING_UTF8) = 0) and (SourceFileName = TargetFileName) then
    begin
      Result.Success := True;
      Result.BytesProcessed := 0;
      Exit;
    end;

    // 读取源文�?
    SourceStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyNone);
    try
      // 读取文件内容
      SourceStream.Position := BOMResult.BOMLength; // 跳过BOM（如果有�?
      SetLength(Buffer, SourceStream.Size - BOMResult.BOMLength);

      if Length(Buffer) > 0 then
        SourceStream.ReadBuffer(Buffer[0], Length(Buffer));

      // 根据源编码进行转�?
      if (CompareText(SourceEncoding, ENCODING_UTF8) = 0) or (CompareText(SourceEncoding, ENCODING_UTF8_BOM) = 0) then
      begin
        // 已经是UTF-8，检查是否有BOM
        var HasBOM := (Length(Buffer) >= 3) and
                     (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF);

        if HasBOM then
          // 有BOM，移除BOM
          ConvertedBuffer := RemoveUTF8BOM(Buffer)
        else
          // 没有BOM，直接使用原始缓冲区
          ConvertedBuffer := Copy(Buffer);
      end
      else
      begin
        // 需要从其他编码转换为UTF-8
        var WideStr: UnicodeString;
        var UTF8Str: UTF8String;

        if Length(Buffer) > 0 then
        begin
          var SourceCodePage := 0;

          if CompareText(SourceEncoding, ENCODING_ANSI) = 0 then
            SourceCodePage := GetACP() // 使用系统默认ANSI代码页
          else if CompareText(SourceEncoding, ENCODING_GBK) = 0 then
            SourceCodePage := 936 // GBK代码页
          else if CompareText(SourceEncoding, ENCODING_BIG5) = 0 then
            SourceCodePage := 950 // Big5代码页
          else
            SourceCodePage := TEncodingBOMDetector_Improved.BOMTypeToCodePage(BOMResult.BOMType);

          if SourceCodePage = 0 then
            SourceCodePage := GetACP(); // 默认使用系统ANSI代码页

          // 从源编码转换为Unicode
          WideStr := StringToUnicodeString(PAnsiChar(@Buffer[0]), SourceCodePage, Length(Buffer));

          // 从Unicode转换为UTF-8
          UTF8Str := UTF8Encode(WideStr);

          // 创建UTF-8字节数组
          SetLength(ConvertedBuffer, Length(UTF8Str));
          if Length(UTF8Str) > 0 then
            Move(UTF8Str[1], ConvertedBuffer[0], Length(UTF8Str));
        end
        else
        begin
          // 空文件
          SetLength(ConvertedBuffer, 0);
        end;
      end;

      // 写入目标文件
      TargetStream := TFileStream.Create(TargetFileName, fmCreate);
      try
        if Length(ConvertedBuffer) > 0 then
          TargetStream.WriteBuffer(ConvertedBuffer[0], Length(ConvertedBuffer));

        Result.Success := True;
        Result.BytesProcessed := Length(ConvertedBuffer);
      finally
        TargetStream.Free;
      end;
    finally
      SourceStream.Free;
    end;
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
    end;
  end;
end;

class function TUTF8BOMConverter_Improved.HasUTF8BOM(const FileName: string): Boolean;
var
  BOMResult: TBOMDetectionResult;
begin
  BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromFile(FileName);
  Result := (BOMResult.BOMType = 1);
end;


class function TUTF8BOMConverter_Improved.IsUTF8File(const FileName: string; out HasBOM: Boolean): Boolean;
var
  UTF8Result: TUTF8DetectionResult;
begin
  UTF8Result := TUTF8EncodingDetector_Improved.DetectFile(FileName);
  HasBOM := UTF8Result.HasBOM;
  Result := UTF8Result.IsUTF8;
end;

class function TUTF8BOMConverter_Improved.RemoveBOMFromUTF8File(const SourceFileName, TargetFileName: string): TUTF8BOMConversionResult;
var
  SourceStream, TargetStream: TFileStream;
  Buffer: TBytes;
  HasBOM: Boolean;
  BOMResult: TBOMDetectionResult;
begin
  // 初始化结�?
  Result.Success := False;
  Result.OriginalEncoding := ENCODING_UNKNOWN;
  Result.TargetEncoding := ENCODING_UTF8;
  Result.HasBOM := False;
  Result.BytesProcessed := 0;
  Result.ErrorMessage := '';

  // 检查源文件是否存在
  if not FileExists(SourceFileName) then
  begin
    Result.ErrorMessage := '源文件不存在';
    Exit;
  end;

  try
    // 检查源文件是否是UTF-8编码
    if not IsUTF8File(SourceFileName, HasBOM) then
    begin
      Result.ErrorMessage := '源文件不是UTF-8编码';
      Exit;
    end;

    // 设置原始编码
    if HasBOM then
      Result.OriginalEncoding := ENCODING_UTF8_BOM
    else
      Result.OriginalEncoding := ENCODING_UTF8;

    Result.HasBOM := HasBOM;

    // 如果没有BOM，并且源文件和目标文件相同，则不需要处�?
    if (not HasBOM) and (SourceFileName = TargetFileName) then
    begin
      Result.Success := True;
      Result.BytesProcessed := 0;
      Exit;
    end;

    // 读取源文�?
    SourceStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyNone);
    try
      // 检测BOM
      BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromStream(SourceStream);

      // 读取文件内容
      SourceStream.Position := 0;
      SetLength(Buffer, SourceStream.Size);

      if Length(Buffer) > 0 then
        SourceStream.ReadBuffer(Buffer[0], Length(Buffer));

      // 检查是否有BOM
      var FileHasBOM := (Length(Buffer) >= 3) and
                   (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF);

      // 移除BOM（如果有�?
      var BufferWithoutBOM: TBytes;
      if FileHasBOM then
        BufferWithoutBOM := RemoveUTF8BOM(Buffer)
      else
        BufferWithoutBOM := Copy(Buffer);

      // 写入目标文件
      TargetStream := TFileStream.Create(TargetFileName, fmCreate);
      try
        if Length(BufferWithoutBOM) > 0 then
          TargetStream.WriteBuffer(BufferWithoutBOM[0], Length(BufferWithoutBOM));

        Result.Success := True;
        Result.BytesProcessed := Length(Buffer);
      finally
        TargetStream.Free;
      end;
    finally
      SourceStream.Free;
    end;
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
    end;
  end;
end;

class function TUTF8BOMConverter_Improved.RemoveUTF8BOM(const Buffer: TBytes): TBytes;
var
  HasBOM: Boolean;
begin
  // 检查是否有BOM
  HasBOM := (Length(Buffer) >= 3) and
            (Buffer[0] = UTF8_BOM[0]) and
            (Buffer[1] = UTF8_BOM[1]) and
            (Buffer[2] = UTF8_BOM[2]);

  if HasBOM then
  begin
    // 移除BOM
    SetLength(Result, Length(Buffer) - 3);
    if Length(Result) > 0 then
      Move(Buffer[3], Result[0], Length(Result));
  end
  else
  begin
    // 没有BOM，直接返回原始缓冲区
    Result := Copy(Buffer);
  end;
end;

end.
