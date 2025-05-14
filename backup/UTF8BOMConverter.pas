unit UTF8BOMConverter;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, System.Math,
  UtilsEncodingBOM_Simple, UtilsEncodingTypes, UtilsEncodingLogger;

type
  /// <summary>
  /// 专门用于UTF-8到UTF-8+BOM转换的转换器
  /// </summary>
  TUTF8BOMConverter = class
  private
    FLogger: TEncodingLogger;
    FBOMDetector: TBOMDetector;

  public
    constructor Create(Logger: TEncodingLogger = nil);
    destructor Destroy; override;

    /// <summary>
    /// 添加BOM到UTF-8缓冲区
    /// </summary>
    function AddBOMToBuffer(const Buffer: TBytes): TBytes;

    /// <summary>
    /// 移除BOM从缓冲区
    /// </summary>
    function RemoveBOMFromBuffer(const Buffer: TBytes): TBytes;

    /// <summary>
    /// 添加BOM到UTF-8文件
    /// </summary>
    function AddBOMToFile(const SourceFile, TargetFile: string): Boolean;

    /// <summary>
    /// 移除BOM从文件
    /// </summary>
    function RemoveBOMFromFile(const SourceFile, TargetFile: string): Boolean;

    /// <summary>
    /// 检查文件是否有BOM
    /// </summary>
    function HasBOM(const FileName: string): Boolean;

    /// <summary>
    /// 设置日志记录器
    /// </summary>
    procedure SetLogger(Logger: TEncodingLogger);
  end;

implementation

{ TUTF8BOMConverter }

constructor TUTF8BOMConverter.Create(Logger: TEncodingLogger);
begin
  inherited Create;

  if Logger = nil then
    FLogger := TEncodingLogger.Create
  else
    FLogger := Logger;

  FBOMDetector := TBOMDetector.Create;
  FBOMDetector.SetLogger(FLogger);
end;

destructor TUTF8BOMConverter.Destroy;
begin
  FBOMDetector.Free;

  if FLogger <> nil then
    FLogger.Free;

  inherited;
end;

function TUTF8BOMConverter.AddBOMToBuffer(const Buffer: TBytes): TBytes;
var
  DetectionInfo: TEncodingDetectionInfo;
begin
  // 检查是否已经有BOM
  if FBOMDetector.DetectBOM(Buffer, DetectionInfo) then
  begin
    // 如果已经是UTF-8 BOM，直接返回原始缓冲区
    if DetectionInfo.EncodingName = 'UTF-8 with BOM' then
    begin
      FLogger.LogInfo('缓冲区已经有UTF-8 BOM，无需添加');
      Result := Copy(Buffer, 0, Length(Buffer));
      Exit;
    end
    else
    begin
      // 如果是其他编码的BOM，先移除
      FLogger.LogInfo(Format('缓冲区有%s BOM，先移除', [DetectionInfo.EncodingName]));
      var TempBuffer: TBytes;
      var DetectedEncoding: string;
      TempBuffer := FBOMDetector.RemoveBOM(Buffer, DetectedEncoding);

      // 然后添加UTF-8 BOM
      Result := FBOMDetector.AddBOM(TempBuffer, 'UTF-8');
    end;
  end
  else
  begin
    // 没有BOM，直接添加UTF-8 BOM
    Result := FBOMDetector.AddBOM(Buffer, 'UTF-8');
    FLogger.LogInfo(Format('添加UTF-8 BOM到缓冲区，大小从%d字节变为%d字节',
      [Length(Buffer), Length(Result)]));
  end;
end;

function TUTF8BOMConverter.RemoveBOMFromBuffer(const Buffer: TBytes): TBytes;
var
  DetectedEncoding: string;
begin
  // 移除BOM
  Result := FBOMDetector.RemoveBOM(Buffer, DetectedEncoding);

  if DetectedEncoding <> '' then
    FLogger.LogInfo(Format('从%s编码的缓冲区移除BOM', [DetectedEncoding]))
  else
    FLogger.LogInfo('缓冲区没有BOM，返回原始缓冲区');
end;

function TUTF8BOMConverter.AddBOMToFile(const SourceFile, TargetFile: string): Boolean;
var
  SourceStream, TargetStream: TFileStream;
  Buffer, ResultBuffer: TBytes;
  StartTime, EndTime: TDateTime;
  ElapsedTime: Int64;
begin
  Result := False;

  if not FileExists(SourceFile) then
  begin
    FLogger.LogError(Format('源文件不存在: %s', [SourceFile]));
    Exit;
  end;

  StartTime := Now;

  try
    // 读取源文件
    SourceStream := TFileStream.Create(SourceFile, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(Buffer, SourceStream.Size);
      if SourceStream.Size > 0 then
        SourceStream.ReadBuffer(Buffer[0], SourceStream.Size);
    finally
      SourceStream.Free;
    end;

    // 添加BOM
    ResultBuffer := AddBOMToBuffer(Buffer);

    // 写入目标文件
    TargetStream := TFileStream.Create(TargetFile, fmCreate);
    try
      if Length(ResultBuffer) > 0 then
        TargetStream.WriteBuffer(ResultBuffer[0], Length(ResultBuffer));
    finally
      TargetStream.Free;
    end;

    EndTime := Now;
    ElapsedTime := MilliSecondsBetween(EndTime, StartTime);

    FLogger.LogInfo(Format('添加UTF-8 BOM到文件: %s -> %s, 耗时: %d ms',
      [SourceFile, TargetFile, ElapsedTime]));

    Result := True;
  except
    on E: Exception do
    begin
      FLogger.LogError(Format('添加UTF-8 BOM到文件时出错: %s -> %s - %s',
        [SourceFile, TargetFile, E.Message]));
    end;
  end;
end;

function TUTF8BOMConverter.RemoveBOMFromFile(const SourceFile, TargetFile: string): Boolean;
var
  SourceStream, TargetStream: TFileStream;
  Buffer, ResultBuffer: TBytes;
  StartTime, EndTime: TDateTime;
  ElapsedTime: Int64;
  DetectedEncoding: string;
begin
  Result := False;

  if not FileExists(SourceFile) then
  begin
    FLogger.LogError(Format('源文件不存在: %s', [SourceFile]));
    Exit;
  end;

  StartTime := Now;

  try
    // 读取源文件
    SourceStream := TFileStream.Create(SourceFile, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(Buffer, SourceStream.Size);
      if SourceStream.Size > 0 then
        SourceStream.ReadBuffer(Buffer[0], SourceStream.Size);
    finally
      SourceStream.Free;
    end;

    // 移除BOM
    ResultBuffer := FBOMDetector.RemoveBOM(Buffer, DetectedEncoding);

    // 写入目标文件
    TargetStream := TFileStream.Create(TargetFile, fmCreate);
    try
      if Length(ResultBuffer) > 0 then
        TargetStream.WriteBuffer(ResultBuffer[0], Length(ResultBuffer));
    finally
      TargetStream.Free;
    end;

    EndTime := Now;
    ElapsedTime := MilliSecondsBetween(EndTime, StartTime);

    if DetectedEncoding <> '' then
      FLogger.LogInfo(Format('从%s编码的文件移除BOM: %s -> %s, 耗时: %d ms',
        [DetectedEncoding, SourceFile, TargetFile, ElapsedTime]))
    else
      FLogger.LogInfo(Format('文件没有BOM: %s -> %s, 耗时: %d ms',
        [SourceFile, TargetFile, ElapsedTime]));

    Result := True;
  except
    on E: Exception do
    begin
      FLogger.LogError(Format('从文件移除BOM时出错: %s -> %s - %s',
        [SourceFile, TargetFile, E.Message]));
    end;
  end;
end;

function TUTF8BOMConverter.HasBOM(const FileName: string): Boolean;
var
  Stream: TFileStream;
  Buffer: TBytes;
  DetectionInfo: TEncodingDetectionInfo;
begin
  Result := False;

  if not FileExists(FileName) then
    Exit;

  try
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      // 只读取前4个字节，足够检测BOM
      SetLength(Buffer, Min(Stream.Size, 4));
      if Length(Buffer) > 0 then
        Stream.ReadBuffer(Buffer[0], Length(Buffer));
    finally
      Stream.Free;
    end;

    // 检测BOM
    Result := FBOMDetector.DetectBOM(Buffer, DetectionInfo);

    if Result then
      FLogger.LogInfo(Format('文件有%s BOM: %s', [DetectionInfo.EncodingName, FileName]))
    else
      FLogger.LogInfo(Format('文件没有BOM: %s', [FileName]));
  except
    on E: Exception do
    begin
      FLogger.LogError(Format('检测文件BOM时出错: %s - %s', [FileName, E.Message]));
    end;
  end;
end;

procedure TUTF8BOMConverter.SetLogger(Logger: TEncodingLogger);
begin
  if FLogger <> nil then
    FLogger.Free;

  FLogger := Logger;

  if FBOMDetector <> nil then
    FBOMDetector.SetLogger(FLogger);
end;

end.
