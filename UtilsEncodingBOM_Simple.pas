unit UtilsEncodingBOM_Simple;

interface

uses
  System.SysUtils, System.Classes, System.Math,
  UtilsEncodingTypes, UtilsEncodingLogger;

type
  // 简化版BOM检测器类
  TBOMDetector = class
  private
    class var FLogger: TEncodingLogger;

    // 内部方法：记录BOM检测日志
    class procedure LogBOMDetection(const Buffer: TBytes; const DetectionInfo: TEncodingDetectionInfo; TimeTakenMS: Int64 = 0);

  public
    class constructor Create;
    class destructor Destroy;

    /// <summary>
    /// 检测缓冲区中是否包含BOM标记，并返回相应的编码信息
    /// </summary>
    class function DetectBOM(const Buffer: TBytes; out DetectionInfo: TEncodingDetectionInfo): Boolean;

    /// <summary>
    /// 获取指定编码的BOM标记
    /// </summary>
    class function GetBOMForEncoding(const EncodingName: string): TBytes;

    /// <summary>
    /// 添加BOM标记到缓冲区
    /// </summary>
    class function AddBOM(const Buffer: TBytes; const EncodingName: string): TBytes;

    /// <summary>
    /// 从缓冲区移除BOM标记
    /// </summary>
    class function RemoveBOM(const Buffer: TBytes; out DetectedEncoding: string): TBytes;

    /// <summary>
    /// 设置日志记录器
    /// </summary>
    class procedure SetLogger(Logger: TEncodingLogger);
  end;

implementation

uses
  Winapi.Windows;

{ TBOMDetector }

class constructor TBOMDetector.Create;
begin
  if not Assigned(FLogger) then
    FLogger := TEncodingLogger.Create;
end;

class destructor TBOMDetector.Destroy;
begin
  // 不要释放FLogger，因为它可能是外部传入的
end;

class procedure TBOMDetector.SetLogger(Logger: TEncodingLogger);
begin
  if Assigned(Logger) then
    FLogger := Logger;
end;

class procedure TBOMDetector.LogBOMDetection(const Buffer: TBytes; const DetectionInfo: TEncodingDetectionInfo; TimeTakenMS: Int64 = 0);
begin
  if not Assigned(FLogger) then
    Exit;

  // 使用增强的Logger.LogInfo方法
  FLogger.LogInfo(Format('BOMDetector: 检测到编码 %s, BOM大小: %d, 置信度: %.2f, 耗时: %d ms',
    [DetectionInfo.EncodingName, DetectionInfo.BOMSize, DetectionInfo.Confidence, TimeTakenMS]));
end;

class function TBOMDetector.DetectBOM(const Buffer: TBytes; out DetectionInfo: TEncodingDetectionInfo): Boolean;
begin
  Result := True;
  // 初始化TEncodingDetectionInfo记录
  DetectionInfo.EncodingName := 'Unknown';
  DetectionInfo.Encoding := TEncoding.ASCII;
  DetectionInfo.Confidence := 0.0;
  DetectionInfo.HasBOM := False;
  DetectionInfo.BOMSize := 0;
  DetectionInfo.DetectionTime := 0;
  DetectionInfo.ErrorCount := 0;
  DetectionInfo.ValidCodePoints := 0;
  DetectionInfo.InvalidCodePoints := 0;
  DetectionInfo.AdditionalInfo := '';
  DetectionInfo.LanguageHint := TLanguageHint.lhUnknown;
  DetectionInfo.HasBOM := True;
  DetectionInfo.Confidence := 1.0; // BOM检测的置信度为100%

  try
    // 确保缓冲区至少有1个字节
    if Length(Buffer) = 0 then
    begin
      Result := False;
      DetectionInfo.HasBOM := False;
      DetectionInfo.BOMSize := 0;
      Exit;
    end;

    // UTF-8 BOM: EF BB BF
    if (Length(Buffer) >= 3) and (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF) then
    begin
      DetectionInfo.EncodingName := 'UTF-8 with BOM';
      DetectionInfo.BOMSize := 3;
      LogBOMDetection(Buffer, DetectionInfo);
      Exit;
    end;

    // UTF-16LE BOM: FF FE
    if (Length(Buffer) >= 2) and (Buffer[0] = $FF) and (Buffer[1] = $FE) then
    begin
      // 检查是否是UTF-32LE BOM: FF FE 00 00
      if (Length(Buffer) >= 4) and (Buffer[2] = 0) and (Buffer[3] = 0) then
      begin
        DetectionInfo.EncodingName := 'UTF-32LE';
        DetectionInfo.BOMSize := 4;
      end
      else
      begin
        DetectionInfo.EncodingName := 'UTF-16LE';
        DetectionInfo.BOMSize := 2;
      end;
      LogBOMDetection(Buffer, DetectionInfo);
      Exit;
    end;

    // UTF-16BE BOM: FE FF
    if (Length(Buffer) >= 2) and (Buffer[0] = $FE) and (Buffer[1] = $FF) then
    begin
      DetectionInfo.EncodingName := 'UTF-16BE';
      DetectionInfo.BOMSize := 2;
      LogBOMDetection(Buffer, DetectionInfo);
      Exit;
    end;

    // UTF-32BE BOM: 00 00 FE FF
    if (Length(Buffer) >= 4) and (Buffer[0] = 0) and (Buffer[1] = 0) and (Buffer[2] = $FE) and (Buffer[3] = $FF) then
    begin
      DetectionInfo.EncodingName := 'UTF-32BE';
      DetectionInfo.BOMSize := 4;
      LogBOMDetection(Buffer, DetectionInfo);
      Exit;
    end;

    // 没有检测到BOM
    Result := False;
    DetectionInfo.HasBOM := False;
    DetectionInfo.BOMSize := 0;

    LogBOMDetection(Buffer, DetectionInfo);
  except
    on E: Exception do
    begin
      if Assigned(FLogger) then
        FLogger.LogError('BOM检测失败: ' + E.Message);
      Result := False;
      DetectionInfo.HasBOM := False;
      DetectionInfo.BOMSize := 0;
    end;
  end;
end;

class function TBOMDetector.GetBOMForEncoding(const EncodingName: string): TBytes;
begin
  if SameText(EncodingName, 'UTF-8') or SameText(EncodingName, 'UTF-8 with BOM') then
  begin
    SetLength(Result, 3);
    Result[0] := $EF;
    Result[1] := $BB;
    Result[2] := $BF;
  end
  else if SameText(EncodingName, 'UTF-16LE') then
  begin
    SetLength(Result, 2);
    Result[0] := $FF;
    Result[1] := $FE;
  end
  else if SameText(EncodingName, 'UTF-16BE') then
  begin
    SetLength(Result, 2);
    Result[0] := $FE;
    Result[1] := $FF;
  end
  else if SameText(EncodingName, 'UTF-32LE') then
  begin
    SetLength(Result, 4);
    Result[0] := $FF;
    Result[1] := $FE;
    Result[2] := $00;
    Result[3] := $00;
  end
  else if SameText(EncodingName, 'UTF-32BE') then
  begin
    SetLength(Result, 4);
    Result[0] := $00;
    Result[1] := $00;
    Result[2] := $FE;
    Result[3] := $FF;
  end
  else
  begin
    SetLength(Result, 0);
    if Assigned(FLogger) then
      FLogger.LogWarning(Format('不支持的编码BOM: %s', [EncodingName]));
  end;
end;

class function TBOMDetector.AddBOM(const Buffer: TBytes; const EncodingName: string): TBytes;
var
  BOM: TBytes;
  DetectionInfo: TEncodingDetectionInfo;
begin
  // 检查是否已经有BOM
  if DetectBOM(Buffer, DetectionInfo) then
  begin
    // 如果已经有相同编码的BOM，直接返回原始缓冲区
    if SameText(DetectionInfo.EncodingName, EncodingName) or
       (SameText(DetectionInfo.EncodingName, 'UTF-8 with BOM') and SameText(EncodingName, 'UTF-8')) then
    begin
      if Assigned(FLogger) then
        FLogger.LogInfo(Format('缓冲区已经有%s BOM，无需添加', [DetectionInfo.EncodingName]));
      Result := Copy(Buffer, 0, Length(Buffer));
      Exit;
    end;

    // 如果有不同编码的BOM，先移除
    if Assigned(FLogger) then
      FLogger.LogInfo(Format('缓冲区有%s BOM，先移除再添加%s BOM', [DetectionInfo.EncodingName, EncodingName]));

    var TempBuffer: TBytes;
    var DetectedEncoding: string;
    TempBuffer := RemoveBOM(Buffer, DetectedEncoding);

    // 获取要添加的BOM
    BOM := GetBOMForEncoding(EncodingName);

    // 添加BOM
    SetLength(Result, Length(BOM) + Length(TempBuffer));
    if Length(BOM) > 0 then
      Move(BOM[0], Result[0], Length(BOM));
    if Length(TempBuffer) > 0 then
      Move(TempBuffer[0], Result[Length(BOM)], Length(TempBuffer));
  end
  else
  begin
    // 没有BOM，直接添加
    BOM := GetBOMForEncoding(EncodingName);

    SetLength(Result, Length(BOM) + Length(Buffer));
    if Length(BOM) > 0 then
      Move(BOM[0], Result[0], Length(BOM));
    if Length(Buffer) > 0 then
      Move(Buffer[0], Result[Length(BOM)], Length(Buffer));

    if Assigned(FLogger) then
      FLogger.LogInfo(Format('添加%s BOM到缓冲区，大小从%d字节变为%d字节',
        [EncodingName, Length(Buffer), Length(Result)]));
  end;
end;

class function TBOMDetector.RemoveBOM(const Buffer: TBytes; out DetectedEncoding: string): TBytes;
var
  DetectionInfo: TEncodingDetectionInfo;
begin
  DetectedEncoding := '';

  // 检测BOM
  if DetectBOM(Buffer, DetectionInfo) then
  begin
    // 有BOM，移除
    DetectedEncoding := DetectionInfo.EncodingName;

    // 复制BOM之后的内容
    SetLength(Result, Length(Buffer) - DetectionInfo.BOMSize);
    if Length(Result) > 0 then
      Move(Buffer[DetectionInfo.BOMSize], Result[0], Length(Result));

    if Assigned(FLogger) then
      FLogger.LogInfo(Format('从%s编码的缓冲区移除BOM，大小从%d字节变为%d字节',
        [DetectedEncoding, Length(Buffer), Length(Result)]));
  end
  else
  begin
    // 没有BOM，返回原始缓冲区
    Result := Copy(Buffer, 0, Length(Buffer));

    if Assigned(FLogger) then
      FLogger.LogInfo('缓冲区没有BOM，返回原始缓冲区');
  end;
end;

end.
