unit SimpleEncodingDetector;

interface

uses
  System.SysUtils, System.Classes, System.Math;

type
  TEncodingDetectionResult = record
    EncodingName: string;
    Confidence: Double;
    HasBOM: Boolean;
    Description: string;
  end;

  TSimpleEncodingDetector = class
  public
    function DetectFileEncoding(const FileName: string): TEncodingDetectionResult;
    function DetectBytesEncoding(const Bytes: TBytes): TEncodingDetectionResult;
  end;

implementation

function TSimpleEncodingDetector.DetectFileEncoding(const FileName: string): TEncodingDetectionResult;
var
  Stream: TFileStream;
  Buffer: TBytes;
begin
  // 初始化结果
  Result.EncodingName := 'Unknown';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.Description := '';

  if not FileExists(FileName) then
  begin
    Result.Description := '文件不存在';
    Exit;
  end;

  try
    // 打开文件
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      // 读取部分文件内容进行检测
      SetLength(Buffer, Min(Stream.Size, 64 * 1024)); // 最多读取64KB
      if Length(Buffer) > 0 then
        Stream.ReadBuffer(Buffer[0], Length(Buffer));

      // 使用字节检测方法
      Result := DetectBytesEncoding(Buffer);
    finally
      Stream.Free;
    end;
  except
    on E: Exception do
    begin
      Result.EncodingName := 'Error';
      Result.Confidence := 0;
      Result.HasBOM := False;
      Result.Description := 'Error: ' + E.Message;
    end;
  end;
end;

function TSimpleEncodingDetector.DetectBytesEncoding(const Bytes: TBytes): TEncodingDetectionResult;
var
  PreambleSize: Integer;
  DetectedEncoding: TEncoding;
  I, ZeroBytes, NonZeroBytes, HighBitBytes: Integer;
  Utf8Sequences, ValidUtf8Sequences: Integer;
  Utf16EvenZeros, Utf16OddZeros: Integer;
  GBKCount, ShiftJISCount: Integer;
  Confidence: Double;
  IsUtf16LE: Boolean;
begin
  // 初始化结果
  Result.EncodingName := 'Unknown';
  Result.Confidence := 0;
  Result.HasBOM := False;
  Result.Description := '';

  if Length(Bytes) < 2 then
    Exit;

  // 检查BOM
  if (Length(Bytes) >= 2) and (Bytes[0] = $FF) and (Bytes[1] = $FE) then
  begin
    Result.EncodingName := 'UTF-16LE';
    Result.Confidence := 1.0;
    Result.HasBOM := True;
    Result.Description := 'UTF-16LE with BOM';
    Exit;
  end;

  // 检查UTF-16LE特征
  if Length(Bytes) >= 4 then
  begin
    Utf16EvenZeros := 0;
    Utf16OddZeros := 0;
    IsUtf16LE := True;

    // 统计偶数位置和奇数位置的零字节
    for I := 0 to (Length(Bytes) div 2) - 1 do
    begin
      if Bytes[I * 2] = 0 then
        Inc(Utf16EvenZeros);
      if Bytes[I * 2 + 1] = 0 then
        Inc(Utf16OddZeros);
        
      // 检查是否符合UTF-16LE的字节序模式
      if (Bytes[I * 2] > $00) and (Bytes[I * 2 + 1] > $20) then
        IsUtf16LE := False;
    end;

    // UTF-16LE通常在偶数位置有较多的零字节
    if (Utf16EvenZeros > Utf16OddZeros * 2) and IsUtf16LE then
    begin
      Result.EncodingName := 'UTF-16LE';
      Result.Confidence := 0.9;
      Result.HasBOM := False;
      Result.Description := 'UTF-16LE without BOM';
      Exit;
    end;
  end;

  // 检查空字节
  if Length(Bytes) = 0 then
  begin
    Result.Description := '空文件';
    Exit;
  end;

  // 1. 首先检查BOM
  DetectedEncoding := nil;
  PreambleSize := TEncoding.GetBufferEncoding(Bytes, DetectedEncoding);
  Result.HasBOM := PreambleSize > 0;

  if Result.HasBOM then
  begin
    if DetectedEncoding = TEncoding.UTF8 then
    begin
      Result.EncodingName := 'UTF-8';
      Result.Confidence := 1.0;
      Result.Description := 'UTF-8 with BOM detected';
      Exit;
    end
    else if DetectedEncoding = TEncoding.Unicode then
    begin
      // 检测是否为UTF-32LE (FF FE 00 00)
      if (Length(Bytes) >= 4) and (Bytes[0] = $FF) and (Bytes[1] = $FE) and
         (Bytes[2] = 0) and (Bytes[3] = 0) then
      begin
        Result.EncodingName := 'UTF-32LE';
        Result.Description := 'UTF-32LE with BOM detected';
      end
      else
      begin
        Result.EncodingName := 'UTF-16LE';
        Result.Description := 'UTF-16LE with BOM detected';
      end;
      Result.Confidence := 1.0;
      Exit;
    end
    else if DetectedEncoding = TEncoding.BigEndianUnicode then
    begin
      // 检测是否为UTF-32BE (00 00 FE FF)
      if (Length(Bytes) >= 4) and (Bytes[0] = 0) and (Bytes[1] = 0) and
         (Bytes[2] = $FE) and (Bytes[3] = $FF) then
      begin
        Result.EncodingName := 'UTF-32BE';
        Result.Description := 'UTF-32BE with BOM detected';
      end
      else
      begin
        Result.EncodingName := 'UTF-16BE';
        Result.Description := 'UTF-16BE with BOM detected';
      end;
      Result.Confidence := 1.0;
      Exit;
    end;
  end;

  // 2. 统计分析
  ZeroBytes := 0;
  NonZeroBytes := 0;
  HighBitBytes := 0;
  Utf8Sequences := 0;
  ValidUtf8Sequences := 0;
  Utf16EvenZeros := 0;
  Utf16OddZeros := 0;
  GBKCount := 0;
  ShiftJISCount := 0;

  for I := 0 to Length(Bytes) - 1 do
  begin
    if Bytes[I] = 0 then
    begin
      Inc(ZeroBytes);

      // 奇偶位置零字节计数（用于UTF-16检测）
      if I mod 2 = 0 then
        Inc(Utf16EvenZeros)
      else
        Inc(Utf16OddZeros);
    end
    else
    begin
      Inc(NonZeroBytes);

      // 统计高位字节（大于127的字节）
      if Bytes[I] >= $80 then
      begin
        Inc(HighBitBytes);

        // 检测UTF-8多字节序列
        if (Bytes[I] and $E0) = $C0 then // 2字节序列开始
        begin
          Inc(Utf8Sequences);
          if (I + 1 < Length(Bytes)) and ((Bytes[I + 1] and $C0) = $80) then
            Inc(ValidUtf8Sequences);
        end
        else if (Bytes[I] and $F0) = $E0 then // 3字节序列开始
        begin
          Inc(Utf8Sequences);
          if (I + 2 < Length(Bytes)) and
             ((Bytes[I + 1] and $C0) = $80) and
             ((Bytes[I + 2] and $C0) = $80) then
            Inc(ValidUtf8Sequences);
        end
        else if (Bytes[I] and $F8) = $F0 then // 4字节序列开始
        begin
          Inc(Utf8Sequences);
          if (I + 3 < Length(Bytes)) and
             ((Bytes[I + 1] and $C0) = $80) and
             ((Bytes[I + 2] and $C0) = $80) and
             ((Bytes[I + 3] and $C0) = $80) then
            Inc(ValidUtf8Sequences);
        end;

        // 检测GBK特征
        if (I < Length(Bytes) - 1) and
           (((Bytes[I] >= $81) and (Bytes[I] <= $FE)) and
            ((Bytes[I+1] >= $40) and (Bytes[I+1] <= $FE) and (Bytes[I+1] <> $7F))) then
          Inc(GBKCount);

        // 检测Shift-JIS特征
        if (I < Length(Bytes) - 1) and
           ((((Bytes[I] >= $81) and (Bytes[I] <= $9F)) or
             ((Bytes[I] >= $E0) and (Bytes[I] <= $FC))) and
            (((Bytes[I+1] >= $40) and (Bytes[I+1] <= $7E)) or
             ((Bytes[I+1] >= $80) and (Bytes[I+1] <= $FC)))) then
          Inc(ShiftJISCount);
      end;
    end;
  end;

  // 检测纯ASCII
  if (HighBitBytes = 0) and (NonZeroBytes > 0) then
  begin
    Result.EncodingName := 'ASCII';
    Result.Confidence := 1.0;
    Result.Description := 'ASCII detected (100%)';
    Exit;
  end;

  // 检测UTF-8
  if (HighBitBytes > 0) and (Utf8Sequences > 0) then
  begin
    Confidence := ValidUtf8Sequences / Max(1, Utf8Sequences);
    if Confidence > 0.75 then
    begin
      Result.EncodingName := 'UTF-8';
      Result.Confidence := Max(0.8, Confidence);
      Result.Description := Format('UTF-8 detected (%.1f%% valid sequences)', [Confidence * 100]);
      Exit;
    end;
  end;

  // 检测UTF-16LE/BE
  if Length(Bytes) >= 4 then
  begin
    // UTF-16LE特征：偶数位置多零字节
    if (Utf16EvenZeros > Utf16OddZeros * 5) and (ZeroBytes > Length(Bytes) / 5) then
    begin
      Result.EncodingName := 'UTF-16LE';
      Result.Confidence := 0.9;
      Result.Description := 'UTF-16LE detected (statistical)';
      Exit;
    end

    // UTF-16BE特征：奇数位置多零字节
    else if (Utf16OddZeros > Utf16EvenZeros * 5) and (ZeroBytes > Length(Bytes) / 5) then
    begin
      Result.EncodingName := 'UTF-16BE';
      Result.Confidence := 0.9;
      Result.Description := 'UTF-16BE detected (statistical)';
      Exit;
    end;
  end;

  // 检测GBK/GB18030
  if GBKCount > 10 then
  begin
    Confidence := Min(1.0, GBKCount / (Length(Bytes) * 0.3));
    if Confidence > 0.5 then
    begin
      Result.EncodingName := 'GBK';
      Result.Confidence := Max(0.75, Confidence);
      Result.Description := Format('GBK/GB18030 detected (%.1f%% confidence)', [Confidence * 100]);
      Exit;
    end;
  end;

  // 检测Shift-JIS
  if ShiftJISCount > 10 then
  begin
    Confidence := Min(1.0, ShiftJISCount / (Length(Bytes) * 0.3));
    if Confidence > 0.5 then
    begin
      Result.EncodingName := 'Shift-JIS';
      Result.Confidence := Max(0.75, Confidence);
      Result.Description := Format('Shift-JIS detected (%.1f%% confidence)', [Confidence * 100]);
      Exit;
    end;
  end;

  // 默认为ANSI（没有足够证据支持其他编码）
  Result.EncodingName := 'ANSI';
  Result.Confidence := 0.7;
  Result.Description := 'ANSI detected (default)';
end;

end.
