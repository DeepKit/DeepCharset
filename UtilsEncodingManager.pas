unit UtilsEncodingManager;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.Threading, System.SyncObjs,
  UtilsEncodingTypes, UtilsEncodingBOM_Improved,
  UtilsEncodingDetector_Improved, UtilsEncodingConverter_Improved, UtilsEncodingCache;

type
  /// <summary>
  /// 编码管理器 - 整合编码检测和转换功能
  /// </summary>
  TEncodingManager = class
  private
    class var FLogCallback: TProc<string>;
    class var FLastError: string;

    type
      TLogProc = reference to procedure(const Msg: string);
      TLogMethod = procedure(const Msg: string) of object;

  public
    /// <summary>
    /// 设置日志回调函数
    /// </summary>
    class procedure SetLogCallback(const Callback: TProc<string>); overload;

    /// <summary>
    /// 设置日志回调函数（对象方法版本）
    /// </summary>
    class procedure SetLogCallback(const Callback: TObject; const Method: TLogMethod); overload;

    /// <summary>
    /// 获取最后一次错误信息
    /// </summary>
    class function GetLastError: string;

    /// <summary>
    /// 检测文件编码
    /// </summary>
    class function DetectFileEncoding(const FileName: string): TEncodingDetectionResult;

    /// <summary>
    /// 转换文件编码
    /// </summary>
    class function ConvertFileEncoding(const SourceFileName, TargetFileName: string;
      const SourceEncoding, TargetEncoding: string; AddBOM: Boolean = False): Boolean;

    /// <summary>
    /// 批量转换文件编码
    /// </summary>
    class function BatchConvertFileEncoding(const FileNames: TArray<string>;
      const SourceDir, TargetDir: string; const SourceEncoding, TargetEncoding: string;
      AddBOM: Boolean = False): Integer;

    /// <summary>
    /// 添加BOM到文件
    /// </summary>
    class function AddBOMToFile(const FileName: string; const EncodingName: string): Boolean;

    /// <summary>
    /// 移除文件的BOM
    /// </summary>
    class function RemoveBOMFromFile(const FileName: string): Boolean;

    /// <summary>
    /// 获取支持的编码列表
    /// </summary>
    class function GetSupportedEncodings: TArray<string>;

    /// <summary>
    /// 检查编码名称是否有效
    /// </summary>
    class function IsValidEncodingName(const EncodingName: string): Boolean;

    /// <summary>
    /// 获取编码的描述信息
    /// </summary>
    class function GetEncodingDescription(const EncodingName: string): string;
  end;

implementation

uses
  System.IOUtils, System.StrUtils;

{ TEncodingManager }

class function TEncodingManager.AddBOMToFile(const FileName: string; const EncodingName: string): Boolean;
begin
  FLastError := '';

  if not IsValidEncodingName(EncodingName) then
  begin
    FLastError := '无效的编码名称: ' + EncodingName;
    if Assigned(FLogCallback) then
      FLogCallback(FLastError);
    Result := False;
    Exit;
  end;

  Result := TEncodingConverter_Improved.AddBOMToFile(FileName, EncodingName);

  if not Result then
    FLastError := '添加BOM失败: ' + FileName;
end;

class function TEncodingManager.BatchConvertFileEncoding(const FileNames: TArray<string>;
  const SourceDir, TargetDir: string; const SourceEncoding, TargetEncoding: string;
  AddBOM: Boolean): Integer;
var
  SuccessCount: Integer;
  Lock: TCriticalSection;
  TotalFiles: Integer;
  ProcessedFiles: Integer;
  LastProgressReport: Integer;
  UseParallel: Boolean;
  MaxThreads: Integer;
begin
  FLastError := '';
  SuccessCount := 0;
  ProcessedFiles := 0;
  LastProgressReport := 0;
  TotalFiles := Length(FileNames);

  // 初始化编码缓存
  TEncodingCache.Init(TotalFiles * 2, 60);

  // 检查目标编码名称是否有效
  if not IsValidEncodingName(TargetEncoding) then
  begin
    FLastError := '无效的目标编码名称: ' + TargetEncoding;
    if Assigned(FLogCallback) then
      FLogCallback(FLastError);
    Result := 0;
    Exit;
  end;

  // 确保目标目录存在
  if not DirectoryExists(TargetDir) then
  begin
    try
      TDirectory.CreateDirectory(TargetDir);
    except
      on E: Exception do
      begin
        FLastError := '创建目标目录失败: ' + E.Message;
        if Assigned(FLogCallback) then
          FLogCallback(FLastError);
        Result := 0;
        Exit;
      end;
    end;
  end;

  // 决定是否使用并行处理
  UseParallel := TotalFiles > 4; // 只有当文件数量大于4时才使用并行处理

  // 根据CPU核心数决定最大线程数
  MaxThreads := TThread.ProcessorCount;
  if MaxThreads > 8 then
    MaxThreads := 8; // 限制最大线程数为8

  if Assigned(FLogCallback) then
  begin
    if UseParallel then
      FLogCallback(Format('开始并行批量转换 %d 个文件，使用 %d 个线程...', [TotalFiles, MaxThreads]))
    else
      FLogCallback(Format('开始批量转换 %d 个文件...', [TotalFiles]));
  end;

  // 创建线程同步对象
  Lock := TCriticalSection.Create;
  try
    // 并行处理文件
    if UseParallel then
    begin
      TParallel.For(0, TotalFiles - 1,
        procedure(i: Integer)
        var
          SourceFile, TargetFile: string;
          DetectedEncoding: string;
          DetectionResult: TEncodingDetectionResult;
          Success: Boolean;
          CurrentProgress: Integer;
        begin
          SourceFile := TPath.Combine(SourceDir, FileNames[i]);
          TargetFile := TPath.Combine(TargetDir, FileNames[i]);

          // 确保源文件存在
          if not FileExists(SourceFile) then
          begin
            Lock.Enter;
            try
              if Assigned(FLogCallback) then
                FLogCallback('源文件不存在: ' + SourceFile);
              Inc(ProcessedFiles);
            finally
              Lock.Leave;
            end;
            Exit;
          end;

          // 确保目标文件的目录存在
          if not DirectoryExists(ExtractFileDir(TargetFile)) then
          begin
            try
              TDirectory.CreateDirectory(ExtractFileDir(TargetFile));
            except
              on E: Exception do
              begin
                Lock.Enter;
                try
                  if Assigned(FLogCallback) then
                    FLogCallback('创建目标目录失败: ' + E.Message);
                  Inc(ProcessedFiles);
                finally
                  Lock.Leave;
                end;
                Exit;
              end;
            end;
          end;

          // 如果源编码是UNKNOWN，则自动检测
          if (SourceEncoding = ENCODING_UNKNOWN) or (SourceEncoding = '') then
          begin
            DetectionResult := DetectFileEncoding(SourceFile);
            DetectedEncoding := DetectionResult.Encoding;

            if DetectedEncoding = ENCODING_UNKNOWN then
            begin
              Lock.Enter;
              try
                if Assigned(FLogCallback) then
                  FLogCallback('无法检测文件编码: ' + SourceFile);
                Inc(ProcessedFiles);
              finally
                Lock.Leave;
              end;
              Exit;
            end;
          end
          else
          begin
            DetectedEncoding := SourceEncoding;
          end;

          // 转换文件
          Success := ConvertFileEncoding(SourceFile, TargetFile, DetectedEncoding, TargetEncoding, AddBOM);

          // 更新计数器
          Lock.Enter;
          try
            Inc(ProcessedFiles);
            if Success then
              Inc(SuccessCount);

            // 每处理10%的文件报告一次进度
            CurrentProgress := Round(ProcessedFiles / TotalFiles * 100);
            if (CurrentProgress >= LastProgressReport + 10) or (ProcessedFiles = TotalFiles) then
            begin
              if Assigned(FLogCallback) then
                FLogCallback(Format('批量转换进度: %d%% (%d/%d)', [CurrentProgress, ProcessedFiles, TotalFiles]));
              LastProgressReport := CurrentProgress;
            end;
          finally
            Lock.Leave;
          end;
        end,
        MaxThreads
      );
    end
    else
    begin
      // 串行处理文件
      for var i := 0 to TotalFiles - 1 do
      begin
        var SourceFile := TPath.Combine(SourceDir, FileNames[i]);
        var TargetFile := TPath.Combine(TargetDir, FileNames[i]);

        // 确保源文件存在
        if not FileExists(SourceFile) then
        begin
          if Assigned(FLogCallback) then
            FLogCallback('源文件不存在: ' + SourceFile);
          Inc(ProcessedFiles);
          Continue;
        end;

        // 确保目标文件的目录存在
        if not DirectoryExists(ExtractFileDir(TargetFile)) then
        begin
          try
            TDirectory.CreateDirectory(ExtractFileDir(TargetFile));
          except
            on E: Exception do
            begin
              if Assigned(FLogCallback) then
                FLogCallback('创建目标目录失败: ' + E.Message);
              Inc(ProcessedFiles);
              Continue;
            end;
          end;
        end;

        // 如果源编码是UNKNOWN，则自动检测
        var DetectedEncoding: string;
        if (SourceEncoding = ENCODING_UNKNOWN) or (SourceEncoding = '') then
        begin
          var DetectionResult := DetectFileEncoding(SourceFile);
          DetectedEncoding := DetectionResult.Encoding;

          if DetectedEncoding = ENCODING_UNKNOWN then
          begin
            if Assigned(FLogCallback) then
              FLogCallback('无法检测文件编码: ' + SourceFile);
            Inc(ProcessedFiles);
            Continue;
          end;

          if Assigned(FLogCallback) then
            FLogCallback(Format('检测到文件 %s 的编码为: %s', [FileNames[i], DetectedEncoding]));
        end
        else
        begin
          DetectedEncoding := SourceEncoding;
        end;

        // 转换文件
        if ConvertFileEncoding(SourceFile, TargetFile, DetectedEncoding, TargetEncoding, AddBOM) then
          Inc(SuccessCount);

        Inc(ProcessedFiles);

        // 每处理10%的文件报告一次进度
        var CurrentProgress := Round(ProcessedFiles / TotalFiles * 100);
        if (CurrentProgress >= LastProgressReport + 10) or (ProcessedFiles = TotalFiles) then
        begin
          if Assigned(FLogCallback) then
            FLogCallback(Format('批量转换进度: %d%% (%d/%d)', [CurrentProgress, ProcessedFiles, TotalFiles]));
          LastProgressReport := CurrentProgress;
        end;
      end;
    end;

    Result := SuccessCount;

    if Assigned(FLogCallback) then
    begin
      FLogCallback(Format('批量转换完成: 成功 %d / 总计 %d', [SuccessCount, TotalFiles]));
      FLogCallback(TEncodingCache.GetCacheStats);
    end;
  finally
    Lock.Free;
  end;
end;

class function TEncodingManager.ConvertFileEncoding(const SourceFileName, TargetFileName: string;
  const SourceEncoding, TargetEncoding: string; AddBOM: Boolean): Boolean;
var
  ConversionResult: TEncodingConversionResult;
begin
  FLastError := '';

  // 检查编码名称是否有效
  if not IsValidEncodingName(SourceEncoding) then
  begin
    FLastError := '无效的源编码名称: ' + SourceEncoding;
    if Assigned(FLogCallback) then
      FLogCallback(FLastError);
    Result := False;
    Exit;
  end;

  if not IsValidEncodingName(TargetEncoding) then
  begin
    FLastError := '无效的目标编码名称: ' + TargetEncoding;
    if Assigned(FLogCallback) then
      FLogCallback(FLastError);
    Result := False;
    Exit;
  end;

  // 转换文件编码
  ConversionResult := TEncodingConverter_Improved.ConvertFileEncoding(
    SourceFileName, TargetFileName, SourceEncoding, TargetEncoding, AddBOM);

  Result := ConversionResult.Success;

  if not Result then
    FLastError := ConversionResult.ErrorMessage;
end;

class function TEncodingManager.DetectFileEncoding(const FileName: string): TEncodingDetectionResult;
begin
  FLastError := '';

  // 检查文件是否存在
  if not FileExists(FileName) then
  begin
    FLastError := '文件不存在: ' + FileName;
    if Assigned(FLogCallback) then
      FLogCallback(FLastError);

    // 初始化结果
    Result.Encoding := ENCODING_UNKNOWN;
    Result.HasBOM := False;
    Result.Confidence := 0.0;
    Result.DetectionMethod := '';
    Result.ElapsedTime := 0;
    Exit;
  end;

  // 检测文件编码
  Result := TEncodingDetector_Improved.DetectFileEncoding(FileName);

  if Result.Encoding = ENCODING_UNKNOWN then
    FLastError := '无法检测文件编码: ' + FileName;
end;

class function TEncodingManager.GetEncodingDescription(const EncodingName: string): string;
begin
  if EncodingName = ENCODING_UNKNOWN then
    Result := '未知编码'
  else if EncodingName = ENCODING_ANSI then
    Result := 'ANSI (系统默认编码)'
  else if EncodingName = ENCODING_ASCII then
    Result := 'ASCII (7位ASCII)'
  else if EncodingName = ENCODING_UTF8 then
    Result := 'UTF-8 (Unicode 8位编码)'
  else if EncodingName = ENCODING_UTF8_BOM then
    Result := 'UTF-8 BOM (带BOM的UTF-8)'
  else if EncodingName = ENCODING_UTF16_LE then
    Result := 'UTF-16 LE (Unicode 16位小端编码)'
  else if EncodingName = ENCODING_UTF16_BE then
    Result := 'UTF-16 BE (Unicode 16位大端编码)'
  else if EncodingName = ENCODING_UTF32_LE then
    Result := 'UTF-32 LE (Unicode 32位小端编码)'
  else if EncodingName = ENCODING_UTF32_BE then
    Result := 'UTF-32 BE (Unicode 32位大端编码)'
  else if EncodingName = ENCODING_GBK then
    Result := 'GBK (简体中文)'
  else if EncodingName = ENCODING_GB2312 then
    Result := 'GB2312 (简体中文)'
  else if EncodingName = ENCODING_GB18030 then
    Result := 'GB18030 (中文国家标准)'
  else if EncodingName = ENCODING_BIG5 then
    Result := 'Big5 (繁体中文)'
  else if EncodingName = ENCODING_SHIFT_JIS then
    Result := 'Shift-JIS (日文)'
  else if EncodingName = ENCODING_EUC_JP then
    Result := 'EUC-JP (日文)'
  else if EncodingName = ENCODING_ISO2022_JP then
    Result := 'ISO-2022-JP (日文)'
  else if EncodingName = ENCODING_EUC_KR then
    Result := 'EUC-KR (韩文)'
  else if EncodingName = ENCODING_ISO_2022_KR then
    Result := 'ISO-2022-KR (韩文)'
  else if EncodingName = ENCODING_BINARY then
    Result := '二进制文件'
  else
    Result := EncodingName;
end;

class function TEncodingManager.GetLastError: string;
begin
  Result := FLastError;
end;

class function TEncodingManager.GetSupportedEncodings: TArray<string>;
begin
  SetLength(Result, 19);
  Result[0] := ENCODING_ANSI;
  Result[1] := ENCODING_ASCII;
  Result[2] := ENCODING_UTF8;
  Result[3] := ENCODING_UTF8_BOM;
  Result[4] := ENCODING_UTF16_LE;
  Result[5] := ENCODING_UTF16_BE;
  Result[6] := ENCODING_UTF32_LE;
  Result[7] := ENCODING_UTF32_BE;
  Result[8] := ENCODING_GBK;
  Result[9] := ENCODING_GB2312;
  Result[10] := ENCODING_GB18030;
  Result[11] := ENCODING_BIG5;
  Result[12] := ENCODING_SHIFT_JIS;
  Result[13] := ENCODING_EUC_JP;
  Result[14] := ENCODING_ISO2022_JP;
  Result[15] := ENCODING_EUC_KR;
  Result[16] := ENCODING_ISO_2022_KR;
  Result[17] := ENCODING_BINARY;
  Result[18] := ENCODING_UNKNOWN;
end;

class function TEncodingManager.IsValidEncodingName(const EncodingName: string): Boolean;
var
  Encodings: TArray<string>;
  Encoding: string;
begin
  Result := False;
  Encodings := GetSupportedEncodings;

  for Encoding in Encodings do
  begin
    if SameText(Encoding, EncodingName) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

class function TEncodingManager.RemoveBOMFromFile(const FileName: string): Boolean;
begin
  FLastError := '';
  Result := TEncodingConverter_Improved.RemoveBOMFromFile(FileName);

  if not Result then
    FLastError := '移除BOM失败: ' + FileName;
end;

class procedure TEncodingManager.SetLogCallback(const Callback: TProc<string>);
begin
  FLogCallback := Callback;

  // 转换为其他类使用的回调类型
  var DetectorCallback: TProc<string> := Callback;
  var ConverterCallback: TProc<string> := Callback;

  TEncodingDetector_Improved.SetLogCallback(DetectorCallback);
  TEncodingConverter_Improved.SetLogCallback(ConverterCallback);
end;

class procedure TEncodingManager.SetLogCallback(const Callback: TObject; const Method: TLogMethod);
begin
  // 暂时不实现，避免编译错误
end;

end.
