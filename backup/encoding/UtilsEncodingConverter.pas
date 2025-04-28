unit UtilsEncodingConverter;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.IOUtils,
  UtilsEncodingDetect2, JclStrings, JclFileUtils, Winapi.Windows;

type
  // 转换结果记录
  TEncodingConversionResult = record
    Success: Boolean;
    SourceEncoding: TEncoding;
    TargetEncoding: TEncoding;
    SourceSize: Int64;
    TargetSize: Int64;
    ErrorMessage: string;
    Description: string;
  end;

  // 转换选项
  TEncodingConversionOptions = record
    AutoDetectSource: Boolean;      // 自动检测源编码
    MinConfidence: Double;          // 自动检测的最小置信度
    DefaultSourceEncoding: TEncoding; // 默认源编码
    AddBOM: Boolean;                // 是否添加BOM
    OverwriteTarget: Boolean;       // 覆盖目标文件
    CreateBackup: Boolean;          // 创建备份
    BackupExtension: string;        // 备份文件扩展名
    MaxBufferSize: Integer;         // 最大缓冲区大小
  end;

  // 转换进度回调
  TConversionProgressCallback = reference to procedure(const FileName: string; 
                                                     Position, Total: Int64; 
                                                     var Cancel: Boolean);

  // 编码转换器类
  TEncodingConverter = class
  private
    FDetector: TEncodingDetector2;
    FOptions: TEncodingConversionOptions;
    FLastError: string;
    FLastResult: TEncodingConversionResult;
    FProgressCallback: TConversionProgressCallback;

    // 内部转换方法
    function InternalConvertBytes(const SourceBytes: TBytes; 
                                SourceEncoding, TargetEncoding: TEncoding;
                                AddBOM: Boolean): TBytes;
    function InternalConvertStream(SourceStream, TargetStream: TStream;
                                 SourceEncoding, TargetEncoding: TEncoding;
                                 AddBOM: Boolean): Boolean;
    function DetectEncoding(const Stream: TStream): TEncoding;
    function GetDefaultEncoding: TEncoding;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 属性
    property Options: TEncodingConversionOptions read FOptions write FOptions;
    property LastError: string read FLastError;
    property LastResult: TEncodingConversionResult read FLastResult;
    property ProgressCallback: TConversionProgressCallback read FProgressCallback write FProgressCallback;
    
    // 转换方法
    function ConvertFile(const SourceFileName, TargetFileName: string;
                         SourceEncoding: TEncoding = nil;
                         TargetEncoding: TEncoding = nil): TEncodingConversionResult;
    function ConvertStream(SourceStream, TargetStream: TStream;
                          SourceEncoding: TEncoding = nil;
                          TargetEncoding: TEncoding = nil): TEncodingConversionResult;
    function ConvertString(const SourceString: string;
                          SourceEncoding: TEncoding = nil;
                          TargetEncoding: TEncoding = nil): string;
    function ConvertBytes(const SourceBytes: TBytes;
                         SourceEncoding: TEncoding = nil;
                         TargetEncoding: TEncoding = nil): TBytes;
                         
    // 批量转换
    function ConvertFiles(const SourceFiles: TArray<string>; 
                         const TargetDirectory: string;
                         TargetEncoding: TEncoding = nil): Integer;
                         
    // 工具方法
    class function DetectFileEncoding(const FileName: string): TEncoding;
    class function GetEncodingName(Encoding: TEncoding): string;
  end;

implementation

constructor TEncodingConverter.Create;
begin
  inherited Create;
  
  // 创建编码检测器
  FDetector := TEncodingDetector2.Create;
  
  // 设置默认选项
  FOptions.AutoDetectSource := True;
  FOptions.MinConfidence := 0.6;
  FOptions.DefaultSourceEncoding := TEncoding.ANSI;
  FOptions.AddBOM := True;
  FOptions.OverwriteTarget := True;
  FOptions.CreateBackup := False;
  FOptions.BackupExtension := '.bak';
  FOptions.MaxBufferSize := 1024 * 1024; // 1MB缓冲区
end;

destructor TEncodingConverter.Destroy;
begin
  FDetector.Free;
  inherited;
end;

function TEncodingConverter.DetectEncoding(const Stream: TStream): TEncoding;
var
  DetectionResult: TEncodingDetectionResult;
begin
  // 检测流编码
  DetectionResult := FDetector.DetectStreamEncoding(Stream);
  
  // 如果置信度足够高，使用检测结果
  if (DetectionResult.DetectedEncoding <> nil) and 
     (DetectionResult.Confidence >= FOptions.MinConfidence) then
    Result := DetectionResult.DetectedEncoding
  else
    Result := FOptions.DefaultSourceEncoding;
end;

function TEncodingConverter.GetDefaultEncoding: TEncoding;
begin
  // 返回系统默认编码
  Result := TEncoding.Default;
end;

function TEncodingConverter.InternalConvertBytes(const SourceBytes: TBytes;
                                              SourceEncoding, TargetEncoding: TEncoding;
                                              AddBOM: Boolean): TBytes;
var
  SourceString: string;
begin
  try
    // 解码源字节为字符串
    SourceString := SourceEncoding.GetString(SourceBytes);
    
    // 编码字符串为目标字节
    if AddBOM then
      Result := TargetEncoding.GetPreamble + TargetEncoding.GetBytes(SourceString)
    else
      Result := TargetEncoding.GetBytes(SourceString);
  except
    on E: Exception do
    begin
      FLastError := E.Message;
      SetLength(Result, 0);
    end;
  end;
end;

function TEncodingConverter.InternalConvertStream(SourceStream, TargetStream: TStream;
                                               SourceEncoding, TargetEncoding: TEncoding;
                                               AddBOM: Boolean): Boolean;
var
  SourceSize, ChunkSize, TotalRead: Int64;
  Buffer, ConvertedBuffer: TBytes;
  ReadSize: Integer;
  Cancel: Boolean;
begin
  Result := False;
  SourceSize := SourceStream.Size;
  ChunkSize := Min(SourceSize, FOptions.MaxBufferSize);
  TotalRead := 0;
  Cancel := False;
  
  try
    // 如果需要添加BOM，先写入BOM
    if AddBOM then
    begin
      Buffer := TargetEncoding.GetPreamble;
      if Length(Buffer) > 0 then
        TargetStream.WriteBuffer(Buffer[0], Length(Buffer));
    end;
    
    // 重置源流位置
    SourceStream.Position := 0;
    
    // 分块读取和转换
    SetLength(Buffer, ChunkSize);
    
    while TotalRead < SourceSize do
    begin
      ReadSize := SourceStream.Read(Buffer[0], ChunkSize);
      if ReadSize <= 0 then
        Break;
        
      // 调整实际读取的大小
      SetLength(Buffer, ReadSize);
      
      // 转换当前块
      ConvertedBuffer := InternalConvertBytes(Buffer, SourceEncoding, TargetEncoding, False);
      
      // 写入转换后的块
      if Length(ConvertedBuffer) > 0 then
        TargetStream.WriteBuffer(ConvertedBuffer[0], Length(ConvertedBuffer));
      
      // 更新进度
      Inc(TotalRead, ReadSize);
      
      // 调用进度回调
      if Assigned(FProgressCallback) then
      begin
        FProgressCallback('', TotalRead, SourceSize, Cancel);
        if Cancel then
          Exit(False);
      end;
      
      // 为下一块准备缓冲区
      SetLength(Buffer, ChunkSize);
    end;
    
    Result := True;
  except
    on E: Exception do
    begin
      FLastError := E.Message;
      Result := False;
    end;
  end;
end;

function TEncodingConverter.ConvertFile(const SourceFileName, TargetFileName: string;
                                     SourceEncoding: TEncoding = nil;
                                     TargetEncoding: TEncoding = nil): TEncodingConversionResult;
var
  SourceStream, TargetStream: TStream;
  DetectedSourceEncoding: TEncoding;
  UseSourceEncoding, UseTargetEncoding: TEncoding;
  BackupFileName: string;
  Cancel: Boolean;
begin
  // 初始化结果
  FillChar(FLastResult, SizeOf(FLastResult), 0);
  FLastResult.Success := False;
  
  // 验证源文件存在
  if not FileExists(SourceFileName) then
  begin
    FLastError := '源文件不存在';
    FLastResult.ErrorMessage := FLastError;
    Result := FLastResult;
    Exit;
  end;
  
  // 决定使用哪个源编码
  if (SourceEncoding = nil) and FOptions.AutoDetectSource then
  begin
    // 自动检测源文件编码
    SourceStream := TFileStream.Create(SourceFileName, fmOpenRead);
    try
      DetectedSourceEncoding := DetectEncoding(SourceStream);
      UseSourceEncoding := DetectedSourceEncoding;
    finally
      SourceStream.Free;
    end;
  end
  else if SourceEncoding <> nil then
    UseSourceEncoding := SourceEncoding
  else
    UseSourceEncoding := FOptions.DefaultSourceEncoding;
  
  // 决定使用哪个目标编码
  if TargetEncoding <> nil then
    UseTargetEncoding := TargetEncoding
  else
    UseTargetEncoding := TEncoding.UTF8; // 默认转换为UTF-8
  
  try
    // 创建源流
    SourceStream := TFileStream.Create(SourceFileName, fmOpenRead);
    try
      // 处理目标文件
      if FileExists(TargetFileName) then
      begin
        if not FOptions.OverwriteTarget then
        begin
          FLastError := '目标文件已存在且不允许覆盖';
          FLastResult.ErrorMessage := FLastError;
          Result := FLastResult;
          Exit;
        end;
        
        // 如果需要创建备份
        if FOptions.CreateBackup then
        begin
          BackupFileName := TargetFileName + FOptions.BackupExtension;
          if FileExists(BackupFileName) then
            DeleteFile(BackupFileName);
          
          if not RenameFile(TargetFileName, BackupFileName) then
          begin
            FLastError := '无法创建备份文件';
            FLastResult.ErrorMessage := FLastError;
            Result := FLastResult;
            Exit;
          end;
        end;
      end;
      
      // 创建目标流
      TargetStream := TFileStream.Create(TargetFileName, fmCreate);
      try
        FLastResult.SourceEncoding := UseSourceEncoding;
        FLastResult.TargetEncoding := UseTargetEncoding;
        FLastResult.SourceSize := SourceStream.Size;
        
        // 调用进度回调初始化
        Cancel := False;
        if Assigned(FProgressCallback) then
          FProgressCallback(ExtractFileName(SourceFileName), 0, SourceStream.Size, Cancel);
        
        if Cancel then
        begin
          FLastError := '用户取消';
          FLastResult.ErrorMessage := FLastError;
          Result := FLastResult;
          Exit;
        end;
        
        // 执行转换
        if InternalConvertStream(SourceStream, TargetStream, 
                                UseSourceEncoding, UseTargetEncoding, 
                                FOptions.AddBOM) then
        begin
          FLastResult.Success := True;
          FLastResult.TargetSize := TargetStream.Size;
          FLastResult.Description := Format('成功将文件从%s转换为%s编码', 
            [TEncodingDetector2.GetEncodingFriendlyName(UseSourceEncoding),
             TEncodingDetector2.GetEncodingFriendlyName(UseTargetEncoding)]);
        end
        else
        begin
          FLastResult.ErrorMessage := FLastError;
        end;
      finally
        TargetStream.Free;
      end;
    finally
      SourceStream.Free;
    end;
    
    // 调用进度回调完成
    if Assigned(FProgressCallback) and FLastResult.Success then
    begin
      Cancel := False;
      FProgressCallback(ExtractFileName(SourceFileName), 
                       FLastResult.SourceSize, FLastResult.SourceSize, Cancel);
    end;
    
    Result := FLastResult;
  except
    on E: Exception do
    begin
      FLastError := E.Message;
      FLastResult.ErrorMessage := FLastError;
      Result := FLastResult;
    end;
  end;
end;

function TEncodingConverter.ConvertStream(SourceStream, TargetStream: TStream;
                                       SourceEncoding: TEncoding = nil;
                                       TargetEncoding: TEncoding = nil): TEncodingConversionResult;
var
  UseSourceEncoding, UseTargetEncoding: TEncoding;
  StartPos: Int64;
begin
  // 初始化结果
  FillChar(FLastResult, SizeOf(FLastResult), 0);
  FLastResult.Success := False;
  
  // 检查流
  if (SourceStream = nil) or (TargetStream = nil) then
  begin
    FLastError := '源流或目标流为nil';
    FLastResult.ErrorMessage := FLastError;
    Result := FLastResult;
    Exit;
  end;
  
  // 决定使用哪个源编码
  if (SourceEncoding = nil) and FOptions.AutoDetectSource then
  begin
    // 保存当前位置
    StartPos := SourceStream.Position;
    
    // 自动检测编码
    UseSourceEncoding := DetectEncoding(SourceStream);
    
    // 恢复位置
    SourceStream.Position := StartPos;
  end
  else if SourceEncoding <> nil then
    UseSourceEncoding := SourceEncoding
  else
    UseSourceEncoding := FOptions.DefaultSourceEncoding;
  
  // 决定使用哪个目标编码
  if TargetEncoding <> nil then
    UseTargetEncoding := TargetEncoding
  else
    UseTargetEncoding := TEncoding.UTF8; // 默认转换为UTF-8
  
  try
    FLastResult.SourceEncoding := UseSourceEncoding;
    FLastResult.TargetEncoding := UseTargetEncoding;
    FLastResult.SourceSize := SourceStream.Size - SourceStream.Position;
    
    // 执行转换
    if InternalConvertStream(SourceStream, TargetStream, 
                             UseSourceEncoding, UseTargetEncoding, 
                             FOptions.AddBOM) then
    begin
      FLastResult.Success := True;
      FLastResult.TargetSize := TargetStream.Size - TargetStream.Position;
      FLastResult.Description := Format('成功从%s转换为%s编码', 
        [TEncodingDetector2.GetEncodingFriendlyName(UseSourceEncoding),
         TEncodingDetector2.GetEncodingFriendlyName(UseTargetEncoding)]);
    end
    else
    begin
      FLastResult.ErrorMessage := FLastError;
    end;
    
    Result := FLastResult;
  except
    on E: Exception do
    begin
      FLastError := E.Message;
      FLastResult.ErrorMessage := FLastError;
      Result := FLastResult;
    end;
  end;
end;

function TEncodingConverter.ConvertString(const SourceString: string;
                                       SourceEncoding: TEncoding = nil;
                                       TargetEncoding: TEncoding = nil): string;
var
  SourceBytes, ResultBytes: TBytes;
  UseSourceEncoding, UseTargetEncoding: TEncoding;
begin
  // 决定使用哪个源编码
  if SourceEncoding <> nil then
    UseSourceEncoding := SourceEncoding
  else
    UseSourceEncoding := TEncoding.Default;
  
  // 决定使用哪个目标编码
  if TargetEncoding <> nil then
    UseTargetEncoding := TargetEncoding
  else
    UseTargetEncoding := TEncoding.UTF8;
  
  try
    // 获取源字符串的字节表示
    SourceBytes := UseSourceEncoding.GetBytes(SourceString);
    
    // 转换字节
    ResultBytes := InternalConvertBytes(SourceBytes, UseSourceEncoding, 
                                       UseTargetEncoding, False);
    
    // 解码为字符串
    if Length(ResultBytes) > 0 then
      Result := UseTargetEncoding.GetString(ResultBytes)
    else
      Result := '';
      
    // 设置结果
    FLastResult.Success := True;
    FLastResult.SourceEncoding := UseSourceEncoding;
    FLastResult.TargetEncoding := UseTargetEncoding;
    FLastResult.SourceSize := Length(SourceBytes);
    FLastResult.TargetSize := Length(ResultBytes);
  except
    on E: Exception do
    begin
      FLastError := E.Message;
      FLastResult.Success := False;
      FLastResult.ErrorMessage := FLastError;
      Result := '';
    end;
  end;
end;

function TEncodingConverter.ConvertBytes(const SourceBytes: TBytes;
                                      SourceEncoding: TEncoding = nil;
                                      TargetEncoding: TEncoding = nil): TBytes;
var
  UseSourceEncoding, UseTargetEncoding: TEncoding;
begin
  // 决定使用哪个源编码
  if SourceEncoding <> nil then
    UseSourceEncoding := SourceEncoding
  else if FOptions.AutoDetectSource and (Length(SourceBytes) > 0) then
  begin
    // 创建一个内存流来检测编码
    var Stream := TBytesStream.Create(SourceBytes);
    try
      UseSourceEncoding := DetectEncoding(Stream);
    finally
      Stream.Free;
    end;
  end
  else
    UseSourceEncoding := FOptions.DefaultSourceEncoding;
  
  // 决定使用哪个目标编码
  if TargetEncoding <> nil then
    UseTargetEncoding := TargetEncoding
  else
    UseTargetEncoding := TEncoding.UTF8;
  
  try
    // 转换字节
    Result := InternalConvertBytes(SourceBytes, UseSourceEncoding, 
                                  UseTargetEncoding, FOptions.AddBOM);
    
    // 设置结果
    FLastResult.Success := Length(Result) > 0;
    FLastResult.SourceEncoding := UseSourceEncoding;
    FLastResult.TargetEncoding := UseTargetEncoding;
    FLastResult.SourceSize := Length(SourceBytes);
    FLastResult.TargetSize := Length(Result);
    
    if not FLastResult.Success then
      FLastResult.ErrorMessage := FLastError;
  except
    on E: Exception do
    begin
      FLastError := E.Message;
      FLastResult.Success := False;
      FLastResult.ErrorMessage := FLastError;
      SetLength(Result, 0);
    end;
  end;
end;

function TEncodingConverter.ConvertFiles(const SourceFiles: TArray<string>; 
                                      const TargetDirectory: string;
                                      TargetEncoding: TEncoding = nil): Integer;
var
  i: Integer;
  SourceFile, TargetFile: string;
  Result1: TEncodingConversionResult;
  Cancel: Boolean;
begin
  Result := 0;
  
  // 确保目标目录存在
  if not DirectoryExists(TargetDirectory) then
  begin
    try
      ForceDirectories(TargetDirectory);
    except
      on E: Exception do
      begin
        FLastError := Format('无法创建目标目录: %s - %s', [TargetDirectory, E.Message]);
        Exit(0);
      end;
    end;
  end;
  
  // 依次转换每个文件
  for i := 0 to High(SourceFiles) do
  begin
    SourceFile := SourceFiles[i];
    
    // 生成目标文件路径
    TargetFile := IncludeTrailingPathDelimiter(TargetDirectory) + 
                 ExtractFileName(SourceFile);
    
    // 调用进度回调
    if Assigned(FProgressCallback) then
    begin
      Cancel := False;
      FProgressCallback(Format('正在处理 %d/%d: %s', [i+1, Length(SourceFiles), 
                              ExtractFileName(SourceFile)]), 
                       i, Length(SourceFiles), Cancel);
      if Cancel then
        Break;
    end;
    
    // 转换文件
    Result1 := ConvertFile(SourceFile, TargetFile, nil, TargetEncoding);
    
    // 统计成功数量
    if Result1.Success then
      Inc(Result);
  end;
end;

class function TEncodingConverter.DetectFileEncoding(const FileName: string): TEncoding;
var
  Detector: TEncodingDetector2;
  Result1: TEncodingDetectionResult;
begin
  Result := nil;
  
  if not FileExists(FileName) then
    Exit;
  
  Detector := TEncodingDetector2.Create;
  try
    Result1 := Detector.DetectFileEncoding(FileName);
    if Result1.DetectedEncoding <> nil then
      Result := Result1.DetectedEncoding
    else
      Result := TEncoding.Default;
  finally
    Detector.Free;
  end;
end;

class function TEncodingConverter.GetEncodingName(Encoding: TEncoding): string;
begin
  Result := TEncodingDetector2.GetEncodingFriendlyName(Encoding);
end;

end. 