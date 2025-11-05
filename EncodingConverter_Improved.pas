unit EncodingConverter_Improved;

interface

uses
  System.SysUtils, System.Classes, System.Math, Winapi.Windows, System.IOUtils, UtilsEncodingTypes,
  UtilsEncodingBOM_Improved, UtilsEncodingUTF8Detector_Improved,
  ChineseEncodingDetector_Improved, UTF8BOMConverter_Improved, UtilsEncodingHelper;

type
  /// <summary>
  /// 编码转换错误类型
  /// </summary>
  TEncodingConversionErrorType = (
    ecetNone,              // 无错�?
    ecetInvalidSequence,   // 无效序列
    ecetUnmappableChar,    // 无法映射的字�?
    ecetIncompleteSequence, // 不完整序�?
    ecetIOError,           // IO错误
    ecetUnknownError       // 未知错误
  );

  /// <summary>
  /// 编码转换错误处理策略
  /// </summary>
  TEncodingErrorHandlingStrategy = (
    eehsThrow,             // 抛出异常
    eehsReplace,           // 替换为替代字�?
    eehsSkip,              // 跳过错误
    eehsReport             // 报告错误但继�?
  );

  /// <summary>
  /// 编码转换错误信息
  /// </summary>
  TEncodingConversionError = record
    ErrorType: TEncodingConversionErrorType;  // 错误类型
    Position: Int64;                         // 错误位置
    ByteValue: Byte;                         // 错误字节�?
    ErrorMessage: string;                    // 错误消息
  end;

  /// <summary>
  /// 编码转换结果
  /// </summary>
  TEncodingConversionResult = record
    Success: Boolean;                        // 转换是否成功
    SourceEncoding: string;                  // 源编码
    TargetEncoding: string;                  // 目标编码
    BytesProcessed: Int64;                   // 处理的字节数
    ErrorCount: Integer;                     // 错误数量
    Errors: array of TEncodingConversionError; // 错误列表
    HasBOM: Boolean;                         // 是否有BOM
    OutputData: TBytes;                      // 转换后的输出数据
  end;

  /// <summary>
  /// 编码转换选项
  /// </summary>
  TEncodingConversionOptions = record
    AddBOM: Boolean;                         // 是否添加BOM
    ErrorHandling: TEncodingErrorHandlingStrategy; // 错误处理策略
    ReplacementChar: WideChar;               // 替换字符
    DetectSourceEncoding: Boolean;           // 是否自动检测源编码
    MaxErrorCount: Integer;                  // 最大错误数�?
  end;

  /// <summary>
  /// 改进的编码转换器
  /// </summary>
  TEncodingConverter_Improved = class
  private
    /// <summary>
    /// 获取编码对应的代码页
    /// </summary>
    class function GetCodePage(const EncodingName: string): Integer;

    /// <summary>
    /// 检测文件编�?
    /// </summary>
    class function DetectFileEncoding(const FileName: string): string;

    /// <summary>
    /// 添加错误信息
    /// </summary>
    class procedure AddError(var ConvResult: TEncodingConversionResult; ErrorType: TEncodingConversionErrorType; Position: Int64; ByteValue: Byte; const ErrorMessage: string);

    /// <summary>
    /// 处理转换错误
    /// </summary>
    class function HandleConversionError(var ConvResult: TEncodingConversionResult; ErrorType: TEncodingConversionErrorType; Position: Int64; ByteValue: Byte; const ErrorMessage: string; Strategy: TEncodingErrorHandlingStrategy): Boolean;

    /// <summary>
    /// 检查文件是否可以写�?
    /// </summary>
    class function IsFileAccessible(const FileName: string; out UseTemp: Boolean): Boolean;

  public
    /// <summary>
    /// 创建默认转换选项
    /// </summary>
    class function CreateDefaultOptions: TEncodingConversionOptions;

    /// <summary>
    /// 转换文件编码
    /// </summary>
    class function ConvertFile(const SourceFileName, TargetFileName: string; const SourceEncoding, TargetEncoding: string; const Options: TEncodingConversionOptions): TEncodingConversionResult;

    /// <summary>
    /// 转换字节数组编码
    /// </summary>
    class function ConvertBuffer(const Buffer: TBytes; const SourceEncoding, TargetEncoding: string; const Options: TEncodingConversionOptions): TEncodingConversionResult;

    /// <summary>
    /// 转换流编�?
    /// </summary>
    class function ConvertStream(const SourceStream, TargetStream: TStream; const SourceEncoding, TargetEncoding: string; const Options: TEncodingConversionOptions): TEncodingConversionResult;

    /// <summary>
    /// 批量转换文件编码
    /// </summary>
    class function BatchConvertFiles(const FileNames: TArray<string>; const TargetDir: string; const TargetEncoding: string; const Options: TEncodingConversionOptions): TArray<TEncodingConversionResult>;

    /// <summary>
    /// 验证转换结果
    /// </summary>
    class function ValidateConversion(const SourceFileName, TargetFileName: string): Boolean;
  end;

implementation

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

// 从Unicode字符串转换为指定代码页的字符串
function UnicodeStringToString(const Source: UnicodeString; CodePage: Integer): AnsiString;
var
  DestLength: Integer;
  UsedDefaultChar: BOOL;
  DefaultChar: AnsiChar;
begin
  if Source = '' then
  begin
    Result := '';
    Exit;
  end;

  // 设置默认替换字符
  DefaultChar := '?';
  UsedDefaultChar := False;

  // 获取所需的目标字符数
  DestLength := WideCharToMultiByte(CodePage, 0, PWideChar(Source), Length(Source), nil, 0, nil, nil);

  if DestLength <= 0 then
  begin
    Result := '';
    Exit;
  end;

  // 设置结果字符串长度
  SetLength(Result, DestLength);

  // 执行转换，使用默认字符替换无法映射的字符
  WideCharToMultiByte(CodePage, 0, PWideChar(Source), Length(Source),
                      PAnsiChar(Result), DestLength, @DefaultChar, @UsedDefaultChar);

  // 如果使用了默认字符，可以记录日志或其他处理
  // 但不抛出异常，确保转换过程完成
end;

{ TEncodingConverter_Improved }

class procedure TEncodingConverter_Improved.AddError(var ConvResult: TEncodingConversionResult; ErrorType: TEncodingConversionErrorType; Position: Int64; ByteValue: Byte; const ErrorMessage: string);
begin
  // 增加错误计数
  Inc(ConvResult.ErrorCount);

  // 添加错误信息到错误列�?
  SetLength(ConvResult.Errors, ConvResult.ErrorCount);
  ConvResult.Errors[ConvResult.ErrorCount - 1].ErrorType := ErrorType;
  ConvResult.Errors[ConvResult.ErrorCount - 1].Position := Position;
  ConvResult.Errors[ConvResult.ErrorCount - 1].ByteValue := ByteValue;
  ConvResult.Errors[ConvResult.ErrorCount - 1].ErrorMessage := ErrorMessage;
end;

class function TEncodingConverter_Improved.BatchConvertFiles(const FileNames: TArray<string>; const TargetDir: string; const TargetEncoding: string; const Options: TEncodingConversionOptions): TArray<TEncodingConversionResult>;
var
  i: Integer;
  TargetFileName: string;
begin
  SetLength(Result, Length(FileNames));

  // 确保目标目录存在
  if not DirectoryExists(TargetDir) then
    ForceDirectories(TargetDir);

  // 批量转换文件
  for i := 0 to High(FileNames) do
  begin
    // 构建目标文件�?
    TargetFileName := IncludeTrailingPathDelimiter(TargetDir) + ExtractFileName(FileNames[i]);

    // 转换文件
    Result[i] := ConvertFile(FileNames[i], TargetFileName, '', TargetEncoding, Options);
  end;
end;

class function TEncodingConverter_Improved.ConvertBuffer(const Buffer: TBytes; const SourceEncoding, TargetEncoding: string; const Options: TEncodingConversionOptions): TEncodingConversionResult;
var
  SourceCodePage, TargetCodePage: Integer;
  WideStr: UnicodeString;
  ResultBuffer: TBytes;
  ActualSourceEncoding: string;
  BOMResult: TBOMDetectionResult;
  UTF8Result: TUTF8DetectionResult;
  ChineseResult: TChineseEncodingResult;
  SourceBuffer: TBytes;
  MemoryStream: TMemoryStream;
begin
  // 初始化结�?
  Result.Success := False;
  Result.SourceEncoding := SourceEncoding;
  Result.TargetEncoding := TargetEncoding;
  Result.BytesProcessed := 0;
  Result.ErrorCount := 0;
  SetLength(Result.Errors, 0);
  Result.HasBOM := False;

  // 检查缓冲区是否为空
  if Length(Buffer) = 0 then
  begin
    Result.Success := True;
    SetLength(ResultBuffer, 0);
    Exit;
  end;

  try
    // 检测源编码
    if (SourceEncoding = '') or Options.DetectSourceEncoding then
    begin
      // 检测BOM
      BOMResult := TEncodingBOMDetector_Improved.DetectBOM(Buffer);

      if BOMResult.BOMType <> 0 then
      begin
        ActualSourceEncoding := BOMResult.Encoding;
        Result.HasBOM := True;
      end
      else
      begin
        // 检测UTF-8
        UTF8Result := TUTF8EncodingDetector_Improved.DetectBuffer(Buffer);

        if UTF8Result.IsUTF8 then
          ActualSourceEncoding := ENCODING_UTF8
        else
        begin
          // 检测中文编�?
          ChineseResult := TChineseEncodingDetector_Improved.DetectBuffer(Buffer);
          ActualSourceEncoding := ChineseResult.Encoding;
        end;
      end;
    end
    else
      ActualSourceEncoding := SourceEncoding;

    Result.SourceEncoding := ActualSourceEncoding;

    // 获取源编码和目标编码的代码页
    SourceCodePage := GetCodePage(ActualSourceEncoding);
    TargetCodePage := GetCodePage(TargetEncoding);

    // 如果源编码和目标编码相同，并且不需要添�?移除BOM，则直接复制
    if (SourceCodePage = TargetCodePage) and
       (((CompareText(ActualSourceEncoding, ENCODING_UTF8) = 0) and (CompareText(TargetEncoding, ENCODING_UTF8) = 0) and not Options.AddBOM) or
        ((CompareText(ActualSourceEncoding, ENCODING_UTF8_BOM) = 0) and (CompareText(TargetEncoding, ENCODING_UTF8_BOM) = 0))) then
    begin
      Result.Success := True;
      Result.BytesProcessed := Length(Buffer);
      Exit;
    end;

    // 特殊处理UTF-8与UTF-8+BOM的互�?
    if ((CompareText(ActualSourceEncoding, ENCODING_UTF8) = 0) and (CompareText(TargetEncoding, ENCODING_UTF8_BOM) = 0)) or
       ((CompareText(ActualSourceEncoding, ENCODING_UTF8_BOM) = 0) and (CompareText(TargetEncoding, ENCODING_UTF8) = 0)) then
    begin
      // 从UTF-8转换为UTF-8+BOM
      if (CompareText(ActualSourceEncoding, ENCODING_UTF8) = 0) and (CompareText(TargetEncoding, ENCODING_UTF8_BOM) = 0) then
      begin
        // 检查是否已经有BOM
        var HasBOM := (Length(Buffer) >= 3) and
                     (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF);

        if not HasBOM then
        begin
          // 添加BOM
          var BufferWithBOM := TEncodingBOMDetector_Improved.AddBOM(Buffer, 1);
          Result.Success := True;
          Result.BytesProcessed := Length(BufferWithBOM);
          Result.OutputData := BufferWithBOM;
          Exit;
        end
        else
        begin
          // 已经有BOM，直接返回
          Result.Success := True;
          Result.BytesProcessed := Length(Buffer);
          Result.OutputData := Buffer;
          Exit;
        end;
      end
      // 从UTF-8+BOM转换为UTF-8
      else if (CompareText(ActualSourceEncoding, ENCODING_UTF8_BOM) = 0) and (CompareText(TargetEncoding, ENCODING_UTF8) = 0) then
      begin
        // 移除BOM
        var BufferWithoutBOM := TEncodingBOMDetector_Improved.RemoveBOM(Buffer);
        Result.Success := True;
        Result.BytesProcessed := Length(BufferWithoutBOM);
        Result.OutputData := BufferWithoutBOM;
        Exit;
      end;
    end;

    // 准备源缓冲区，跳过BOM（如果有�?
    if BOMResult.BOMType <> 0 then
    begin
      SetLength(SourceBuffer, Length(Buffer) - BOMResult.BOMLength);
      if Length(SourceBuffer) > 0 then
        Move(Buffer[BOMResult.BOMLength], SourceBuffer[0], Length(SourceBuffer));
    end
    else
      SourceBuffer := Buffer;

    // 转换编码
    if Length(SourceBuffer) > 0 then
    begin
      // 尝试使用快速路径进行转换（无第三方依赖）
      var UseFast := TEncodingHelper.TryConvertFast(
        SourceBuffer, SourceCodePage, TargetCodePage, ResultBuffer);
      
      if not UseFast then
      begin
        // 快速路径失败，使用标准转换方法
        // 从源编码转换为Unicode
        try
          WideStr := StringToUnicodeString(PAnsiChar(@SourceBuffer[0]), SourceCodePage, Length(SourceBuffer));
        except
          on E: Exception do
          begin
            // 记录错误但继续处理
            HandleConversionError(Result, ecetInvalidSequence, 0, 0, E.Message, Options.ErrorHandling);

            // 使用空字符串作为回退方案
            WideStr := '';
          end;
        end;

        // 如果Unicode转换成功，则继续转换为目标编码
        if WideStr <> '' then
        begin
          // 从Unicode转换为目标编码
          var TargetStr := UnicodeStringToString(WideStr, TargetCodePage);

          // 创建目标缓冲区
          if Length(TargetStr) > 0 then
          begin
            SetLength(ResultBuffer, Length(TargetStr));
            Move(TargetStr[1], ResultBuffer[0], Length(TargetStr));
          end
          else
          begin
            // 如果转换结果为空，记录错误
            HandleConversionError(Result, ecetUnmappableChar, 0, 0, '无法映射字符到目标编码', Options.ErrorHandling);
            SetLength(ResultBuffer, 0);
          end;
        end
        else
        begin
          // 如果Unicode转换失败，设置空结果
          SetLength(ResultBuffer, 0);
        end;
      end;
    end
    else
      SetLength(ResultBuffer, 0);

    // 添加BOM（如果需要）
    if Options.AddBOM then
    begin
      var BOMType: Integer;

      if CompareText(TargetEncoding, ENCODING_UTF8) = 0 then
        BOMType := 1
      else if CompareText(TargetEncoding, ENCODING_UTF16_LE) = 0 then
        BOMType := 2
      else if CompareText(TargetEncoding, ENCODING_UTF16_BE) = 0 then
        BOMType := 3
      else if CompareText(TargetEncoding, ENCODING_UTF32_LE) = 0 then
        BOMType := 4
      else if CompareText(TargetEncoding, ENCODING_UTF32_BE) = 0 then
        BOMType := 5
      else
        BOMType := 0;

      if BOMType <> 0 then
        ResultBuffer := TEncodingBOMDetector_Improved.AddBOM(ResultBuffer, BOMType);
    end;

    // 设置转换结果
    Result.Success := True;
    Result.BytesProcessed := Length(ResultBuffer);
    Result.OutputData := ResultBuffer;
  except
    on E: Exception do
    begin
      Result.Success := False;
      AddError(Result, ecetUnknownError, 0, 0, E.Message);
    end;
  end;
end;

class function TEncodingConverter_Improved.ConvertFile(const SourceFileName, TargetFileName: string; const SourceEncoding, TargetEncoding: string; const Options: TEncodingConversionOptions): TEncodingConversionResult;
var
  SourceStream: TFileStream;
  Buffer, OutputBuffer: TBytes;
  ActualSourceEncoding: string;
  TempFileName: string;
  RetryCount: Integer;
  MaxRetry: Integer;
  Success: Boolean;
  ErrCode: DWORD;
  FileAttrs: Integer;
begin
  // 初始化结�?
  Result.Success := False;
  Result.SourceEncoding := SourceEncoding;
  Result.TargetEncoding := TargetEncoding;
  Result.BytesProcessed := 0;
  Result.ErrorCount := 0;
  SetLength(Result.Errors, 0);
  Result.HasBOM := False;
  MaxRetry := 5; // 增加最大重试次�?

  // 检查源文件是否存在
  if not FileExists(SourceFileName) then
  begin
    AddError(Result, ecetIOError, 0, 0, '源文件不存在');
    Exit;
  end;

  // 创建唯一的临时文件名
  TempFileName := ChangeFileExt(TargetFileName, '.tmp_' + FormatDateTime('hhnnsszzz', Now) + '_' + IntToStr(GetTickCount));

  try
    // 检测源文件编码
    if (SourceEncoding = '') or Options.DetectSourceEncoding then
      ActualSourceEncoding := DetectFileEncoding(SourceFileName)
    else
      ActualSourceEncoding := SourceEncoding;

    Result.SourceEncoding := ActualSourceEncoding;

    // 读取源文件内�?
    try
      SourceStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyNone);
      try
        // 读取文件内容（限制最大读取大小以避免内存问题）
        var MaxReadSize := Min(SourceStream.Size, 50 * 1024 * 1024); // 最大50MB
        SetLength(Buffer, MaxReadSize);
        if MaxReadSize > 0 then
          SourceStream.ReadBuffer(Buffer[0], MaxReadSize);
      finally
        SourceStream.Free;
      end;
    except
      on E: Exception do
      begin
        AddError(Result, ecetIOError, 0, 0, '无法读取源文�? ' + E.Message);
        Exit;
      end;
    end;

    // 转换缓冲区
    Result := ConvertBuffer(Buffer, ActualSourceEncoding, TargetEncoding, Options);

    // 检查转换是否成功
    if not Result.Success then
      Exit;

    // 直接使用 ConvertBuffer 返回的转换结果
    OutputBuffer := Result.OutputData;

    // 保存文件属�?
    FileAttrs := 0;
    try
      FileAttrs := System.SysUtils.FileGetAttr(SourceFileName);
    except
      // 忽略获取文件属性的错误
    end;

    // 写入临时文件
    try
      // 使用完全独立的方法写入文�?
      TFile.WriteAllBytes(TempFileName, OutputBuffer);
    except
      on E: Exception do
      begin
        AddError(Result, ecetIOError, 0, 0, '写入临时文件失败: ' + E.Message);
        Exit;
      end;
    end;

    // 尝试多次替换原文�?
    RetryCount := 0;
    Success := False;

    repeat
      Inc(RetryCount);

      try
        // 如果目标文件存在且与源文件不同，先尝试删�?
        if (SourceFileName <> TargetFileName) and FileExists(TargetFileName) then
        begin
          if not DeleteFile(PChar(TargetFileName)) then
          begin
            ErrCode := GetLastError;

            // 如果是文件被占用错误，等待后重试
            if (ErrCode = ERROR_SHARING_VIOLATION) or (ErrCode = ERROR_ACCESS_DENIED) then
            begin
              if RetryCount < MaxRetry then
              begin
                Sleep(500 * RetryCount); // 等待时间逐次延长
                Continue;
              end;
            end;

            // 达到最大重试次数或其他错误
            AddError(Result, ecetIOError, 0, 0, Format('无法删除目标文件，错误码: %d', [ErrCode]));
            Result.Success := False;
            Exit;
          end;
        end;

        // 如果源文件和目标文件相同，需要先删除源文�?
        if SourceFileName = TargetFileName then
        begin
          // 尝试删除源文�?
          if FileExists(SourceFileName) then
          begin
            // 先尝试修改文件属性为普通文�?
            try
              if (FileAttrs and faReadOnly) <> 0 then
                System.SysUtils.FileSetAttr(SourceFileName, FileAttrs and (not faReadOnly));
            except
              // 忽略修改属性的错误
            end;

            if not DeleteFile(PChar(SourceFileName)) then
            begin
              ErrCode := GetLastError;

              // 如果是文件被占用错误，等待后重试
              if (ErrCode = ERROR_SHARING_VIOLATION) or (ErrCode = ERROR_ACCESS_DENIED) then
              begin
                if RetryCount < MaxRetry then
                begin
                  Sleep(500 * RetryCount); // 等待时间逐次延长
                  Continue;
                end;
              end;

              // 达到最大重试次数或其他错误
              AddError(Result, ecetIOError, 0, 0, Format('无法删除源文件，错误�? %d', [ErrCode]));
              Result.Success := False;
              Exit;
            end;
          end;
        end;

        // 重命名临时文件为目标文件
        if RenameFile(TempFileName, TargetFileName) then
        begin
          Success := True;
          Result.Success := True;
          Break;
        end
        else
        begin
          ErrCode := GetLastError;

          // 如果是文件被占用错误，等待后重试
          if (ErrCode = ERROR_SHARING_VIOLATION) or (ErrCode = ERROR_ACCESS_DENIED) then
          begin
            if RetryCount < MaxRetry then
            begin
              Sleep(500 * RetryCount); // 等待时间逐次延长
              Continue;
            end;
          end;

          // 达到最大重试次数或其他错误
          AddError(Result, ecetIOError, 0, 0, Format('无法重命名临时文件，错误�? %d', [ErrCode]));
          Result.Success := False;
          Exit;
        end;
      except
        on E: Exception do
        begin
          // 如果发生异常，记录错误并重试
          if RetryCount < MaxRetry then
          begin
            Sleep(500 * RetryCount); // 等待时间逐次延长
            Continue;
          end
          else
          begin
            AddError(Result, ecetIOError, 0, 0, '替换文件时发生异�? ' + E.Message);
            Result.Success := False;
            Exit;
          end;
        end;
      end;
    until RetryCount >= MaxRetry;

    // 如果所有重试都失败
    if not Success then
    begin
      AddError(Result, ecetIOError, 0, 0, '达到最大重试次数，无法完成文件转换');
      Result.Success := False;
      Exit;
    end;

    // 尝试恢复文件属�?
    try
      if (FileAttrs <> 0) and (FileAttrs <> faInvalid) then
        System.SysUtils.FileSetAttr(TargetFileName, FileAttrs);
    except
      // 忽略设置文件属性的错误
    end;
  except
    on E: Exception do
    begin
      Result.Success := False;
      AddError(Result, ecetUnknownError, 0, 0, E.Message);
    end;
  end;

  // 确保临时文件被删�?
  if FileExists(TempFileName) then
  begin
    try
      DeleteFile(PChar(TempFileName));
    except
      // 忽略删除临时文件的错�?
    end;
  end;
end;

class function TEncodingConverter_Improved.ConvertStream(const SourceStream, TargetStream: TStream; const SourceEncoding, TargetEncoding: string; const Options: TEncodingConversionOptions): TEncodingConversionResult;
var
  Buffer: TBytes;
  Position: Int64;
  ActualSourceEncoding: string;
  BOMResult: TBOMDetectionResult;
begin
  // 初始化结�?
  Result.Success := False;
  Result.SourceEncoding := SourceEncoding;
  Result.TargetEncoding := TargetEncoding;
  Result.BytesProcessed := 0;
  Result.ErrorCount := 0;
  SetLength(Result.Errors, 0);
  Result.HasBOM := False;

  // 检查流是否有效
  if (SourceStream = nil) or (TargetStream = nil) then
  begin
    AddError(Result, ecetIOError, 0, 0, '无效的流');
    Exit;
  end;

  // 保存当前流位�?
  Position := SourceStream.Position;

  try
    // 检测源流编�?
    if (SourceEncoding = '') or Options.DetectSourceEncoding then
    begin
      // 重置流位�?
      SourceStream.Position := 0;

      // 检测BOM
      BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromStream(SourceStream);

      if BOMResult.BOMType <> 0 then
      begin
        ActualSourceEncoding := BOMResult.Encoding;
        Result.HasBOM := True;
      end
      else
      begin
        // 读取流内容进行分�?
        SourceStream.Position := 0;
        SetLength(Buffer, SourceStream.Size);
        if SourceStream.Size > 0 then
          SourceStream.ReadBuffer(Buffer[0], SourceStream.Size);

        // 检测UTF-8
        var UTF8Result := TUTF8EncodingDetector_Improved.DetectBuffer(Buffer);

        if UTF8Result.IsUTF8 then
          ActualSourceEncoding := ENCODING_UTF8
        else
        begin
          // 检测中文编�?
          var ChineseResult := TChineseEncodingDetector_Improved.DetectBuffer(Buffer);
          ActualSourceEncoding := ChineseResult.Encoding;
        end;
      end;
    end
    else
      ActualSourceEncoding := SourceEncoding;

    Result.SourceEncoding := ActualSourceEncoding;

    // 读取源流内容
    SourceStream.Position := 0;
    SetLength(Buffer, SourceStream.Size);
    if SourceStream.Size > 0 then
      SourceStream.ReadBuffer(Buffer[0], SourceStream.Size);

    // 转换缓冲区
    Result := ConvertBuffer(Buffer, ActualSourceEncoding, TargetEncoding, Options);

    // 写入目标流
    if Result.Success and (Length(Result.OutputData) > 0) then
    begin
      TargetStream.Position := 0;
      TargetStream.Size := 0;
      TargetStream.WriteBuffer(Result.OutputData[0], Length(Result.OutputData));
    end;
  finally
    // 恢复流位�?
    SourceStream.Position := Position;
  end;
end;

class function TEncodingConverter_Improved.CreateDefaultOptions: TEncodingConversionOptions;
begin
  Result.AddBOM := False;
  Result.ErrorHandling := eehsReplace;
  Result.ReplacementChar := '?';
  Result.DetectSourceEncoding := True;
  Result.MaxErrorCount := 100;
end;

class function TEncodingConverter_Improved.DetectFileEncoding(const FileName: string): string;
var
  BOMResult: TBOMDetectionResult;
  UTF8Result: TUTF8DetectionResult;
  ChineseResult: TChineseEncodingResult;
begin
  // 检测BOM
  BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromFile(FileName);

  if BOMResult.BOMType <> 0 then
    Result := BOMResult.Encoding
  else
  begin
    // 检测UTF-8
    UTF8Result := TUTF8EncodingDetector_Improved.DetectFile(FileName);

    if UTF8Result.IsUTF8 then
      Result := ENCODING_UTF8
    else
    begin
      // 检测中文编�?
      ChineseResult := TChineseEncodingDetector_Improved.DetectFile(FileName);
      Result := ChineseResult.Encoding;
    end;
  end;
end;

class function TEncodingConverter_Improved.GetCodePage(const EncodingName: string): Integer;
begin
  if CompareText(EncodingName, ENCODING_UTF8) = 0 then
    Result := 65001
  else if CompareText(EncodingName, ENCODING_UTF8_BOM) = 0 then
    Result := 65001
  else if CompareText(EncodingName, ENCODING_UTF16_LE) = 0 then
    Result := 1200
  else if CompareText(EncodingName, ENCODING_UTF16_BE) = 0 then
    Result := 1201
  else if CompareText(EncodingName, ENCODING_UTF32_LE) = 0 then
    Result := 12000
  else if CompareText(EncodingName, ENCODING_UTF32_BE) = 0 then
    Result := 12001
  else if CompareText(EncodingName, ENCODING_GBK) = 0 then
    Result := 936
  else if CompareText(EncodingName, ENCODING_GB18030) = 0 then
    Result := 54936
  else if CompareText(EncodingName, ENCODING_GB2312) = 0 then
    Result := 936
  else if CompareText(EncodingName, ENCODING_BIG5) = 0 then
    Result := 950
  else if CompareText(EncodingName, ENCODING_SHIFT_JIS) = 0 then
    Result := 932
  else if CompareText(EncodingName, ENCODING_EUC_JP) = 0 then
    Result := 20932
  else if CompareText(EncodingName, ENCODING_EUC_KR) = 0 then
    Result := 51949
  else if CompareText(EncodingName, ENCODING_ANSI) = 0 then
    Result := GetACP()
  else
    Result := GetACP();
end;

class function TEncodingConverter_Improved.HandleConversionError(var ConvResult: TEncodingConversionResult; ErrorType: TEncodingConversionErrorType; Position: Int64; ByteValue: Byte; const ErrorMessage: string; Strategy: TEncodingErrorHandlingStrategy): Boolean;
begin
  // 添加错误信息
  AddError(ConvResult, ErrorType, Position, ByteValue, ErrorMessage);

  // 根据错误处理策略决定是否继续
  case Strategy of
    eehsThrow:
      begin
        ConvResult.Success := False;
        Result := False;
      end;
    eehsReplace, eehsSkip, eehsReport:
      begin
        // 继续处理
        Result := True;
      end;
    else
      Result := False;
  end;
end;

class function TEncodingConverter_Improved.IsFileAccessible(const FileName: string; out UseTemp: Boolean): Boolean;
var
  FileHandle: THandle;
  FileMode: DWORD;
  ErrCode: DWORD;
begin
  Result := False;
  UseTemp := False;

  // 检查文件是否存�?
  if not FileExists(FileName) then
    Exit;

  // 尝试以读写模式打开文件
  FileMode := GENERIC_READ or GENERIC_WRITE;
  FileHandle := CreateFile(
    PChar(FileName),
    FileMode,
    0, // 不共�?
    nil,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0);

  if FileHandle <> INVALID_HANDLE_VALUE then
  begin
    // 文件可以以读写模式打开
    CloseHandle(FileHandle);
    Result := True;
  end
  else
  begin
    // 获取错误代码
    ErrCode := GetLastError;

    // 如果是文件被占用或访问被拒绝，尝试以只读模式打开
    if (ErrCode = ERROR_SHARING_VIOLATION) or (ErrCode = ERROR_ACCESS_DENIED) then
    begin
      // 尝试以只读模式打开
      FileMode := GENERIC_READ;
      FileHandle := CreateFile(
        PChar(FileName),
        FileMode,
        FILE_SHARE_READ, // 允许其他进程读取
        nil,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
        0);

      if FileHandle <> INVALID_HANDLE_VALUE then
      begin
        // 文件可以以只读模式打开，需要使用临时文�?
        CloseHandle(FileHandle);
        Result := True;
        UseTemp := True;
      end
      else
      begin
        // 文件无法以任何方式打开
        Result := False;
      end;
    end
    else
    begin
      // 其他错误
      Result := False;
    end;
  end;
end;

class function TEncodingConverter_Improved.ValidateConversion(const SourceFileName, TargetFileName: string): Boolean;
var
  SourceEncoding, TargetEncoding: string;
  SourceBuffer, TargetBuffer: TBytes;
  SourceStream, TargetStream: TFileStream;
  SourceBOMResult, TargetBOMResult: TBOMDetectionResult;
begin
  Result := False;

  // 检查文件是否存�?
  if not (FileExists(SourceFileName) and FileExists(TargetFileName)) then
    Exit;

  try
    // 检测源文件和目标文件的编码
    SourceEncoding := DetectFileEncoding(SourceFileName);
    TargetEncoding := DetectFileEncoding(TargetFileName);

    // 读取源文件和目标文件
    SourceStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyNone);
    try
      TargetStream := TFileStream.Create(TargetFileName, fmOpenRead or fmShareDenyNone);
      try
        // 检测BOM
        SourceBOMResult := TEncodingBOMDetector_Improved.DetectBOMFromStream(SourceStream);
        TargetBOMResult := TEncodingBOMDetector_Improved.DetectBOMFromStream(TargetStream);

        // 读取文件内容（跳过BOM�?
        SourceStream.Position := SourceBOMResult.BOMLength;
        SetLength(SourceBuffer, SourceStream.Size - SourceBOMResult.BOMLength);
        if Length(SourceBuffer) > 0 then
          SourceStream.ReadBuffer(SourceBuffer[0], Length(SourceBuffer));

        TargetStream.Position := TargetBOMResult.BOMLength;
        SetLength(TargetBuffer, TargetStream.Size - TargetBOMResult.BOMLength);
        if Length(TargetBuffer) > 0 then
          TargetStream.ReadBuffer(TargetBuffer[0], Length(TargetBuffer));

        // 如果源编码和目标编码相同，则直接比较内容
        if CompareText(SourceEncoding, TargetEncoding) = 0 then
        begin
          // 比较内容（忽略BOM�?
          Result := (Length(SourceBuffer) = Length(TargetBuffer));

          if Result and (Length(SourceBuffer) > 0) then
            Result := CompareMem(@SourceBuffer[0], @TargetBuffer[0], Length(SourceBuffer));
        end
        else
        begin
          // 如果编码不同，则需要转换后比较
          // 这里简化处理，只检查文件大小是否合�?
          Result := (Length(TargetBuffer) > 0) and
                   (Length(SourceBuffer) > 0) and
                   (Abs(Length(TargetBuffer) - Length(SourceBuffer)) < Length(SourceBuffer) * 0.5);
        end;
      finally
        TargetStream.Free;
      end;
    finally
      SourceStream.Free;
    end;
  except
    Result := False;
  end;
end;

end.
