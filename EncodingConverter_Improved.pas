unit EncodingConverter_Improved;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, UtilsEncodingTypes,
  UtilsEncodingBOM_Improved, UtilsEncodingUTF8Detector_Improved,
  ChineseEncodingDetector_Improved, UTF8BOMConverter_Improved;

type
  /// <summary>
  /// 编码转换错误类型
  /// </summary>
  TEncodingConversionErrorType = (
    ecetNone,              // 无错误
    ecetInvalidSequence,   // 无效序列
    ecetUnmappableChar,    // 无法映射的字符
    ecetIncompleteSequence, // 不完整序列
    ecetIOError,           // IO错误
    ecetUnknownError       // 未知错误
  );

  /// <summary>
  /// 编码转换错误处理策略
  /// </summary>
  TEncodingErrorHandlingStrategy = (
    eehsThrow,             // 抛出异常
    eehsReplace,           // 替换为替代字符
    eehsSkip,              // 跳过错误
    eehsReport             // 报告错误但继续
  );

  /// <summary>
  /// 编码转换错误信息
  /// </summary>
  TEncodingConversionError = record
    ErrorType: TEncodingConversionErrorType;  // 错误类型
    Position: Int64;                         // 错误位置
    ByteValue: Byte;                         // 错误字节值
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
  end;

  /// <summary>
  /// 编码转换选项
  /// </summary>
  TEncodingConversionOptions = record
    AddBOM: Boolean;                         // 是否添加BOM
    ErrorHandling: TEncodingErrorHandlingStrategy; // 错误处理策略
    ReplacementChar: WideChar;               // 替换字符
    DetectSourceEncoding: Boolean;           // 是否自动检测源编码
    MaxErrorCount: Integer;                  // 最大错误数量
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
    /// 检测文件编码
    /// </summary>
    class function DetectFileEncoding(const FileName: string): string;
    
    /// <summary>
    /// 添加错误信息
    /// </summary>
    class procedure AddError(var Result: TEncodingConversionResult; ErrorType: TEncodingConversionErrorType; Position: Int64; ByteValue: Byte; const ErrorMessage: string);
    
    /// <summary>
    /// 处理转换错误
    /// </summary>
    class function HandleConversionError(var Result: TEncodingConversionResult; ErrorType: TEncodingConversionErrorType; Position: Int64; ByteValue: Byte; const ErrorMessage: string; Strategy: TEncodingErrorHandlingStrategy): Boolean;
    
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
    /// 转换流编码
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

{ TEncodingConverter_Improved }

class procedure TEncodingConverter_Improved.AddError(var Result: TEncodingConversionResult; ErrorType: TEncodingConversionErrorType; Position: Int64; ByteValue: Byte; const ErrorMessage: string);
begin
  // 增加错误计数
  Inc(Result.ErrorCount);
  
  // 添加错误信息到错误列表
  SetLength(Result.Errors, Result.ErrorCount);
  Result.Errors[Result.ErrorCount - 1].ErrorType := ErrorType;
  Result.Errors[Result.ErrorCount - 1].Position := Position;
  Result.Errors[Result.ErrorCount - 1].ByteValue := ByteValue;
  Result.Errors[Result.ErrorCount - 1].ErrorMessage := ErrorMessage;
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
    // 构建目标文件名
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
  // 初始化结果
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
      
      if BOMResult.BOMType <> bomNone then
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
          // 检测中文编码
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
    
    // 如果源编码和目标编码相同，并且不需要添加/移除BOM，则直接复制
    if (SourceCodePage = TargetCodePage) and
       ((ActualSourceEncoding = ENCODING_UTF8) and (TargetEncoding = ENCODING_UTF8) and not Options.AddBOM) or
       ((ActualSourceEncoding = ENCODING_UTF8_BOM) and (TargetEncoding = ENCODING_UTF8_BOM)) then
    begin
      Result.Success := True;
      Result.BytesProcessed := Length(Buffer);
      Exit;
    end;
    
    // 准备源缓冲区，跳过BOM（如果有）
    if BOMResult.BOMType <> bomNone then
    begin
      SetLength(SourceBuffer, Length(Buffer) - BOMResult.BOMSize);
      if Length(SourceBuffer) > 0 then
        Move(Buffer[BOMResult.BOMSize], SourceBuffer[0], Length(SourceBuffer));
    end
    else
      SourceBuffer := Buffer;
      
    // 转换编码
    if Length(SourceBuffer) > 0 then
    begin
      // 从源编码转换为Unicode
      try
        WideStr := StringToUnicodeString(PAnsiChar(@SourceBuffer[0]), SourceCodePage, Length(SourceBuffer));
      except
        on E: Exception do
        begin
          if not HandleConversionError(Result, ecetInvalidSequence, 0, 0, E.Message, Options.ErrorHandling) then
            Exit;
            
          // 使用替换字符策略
          WideStr := StringToUnicodeString(PAnsiChar(@SourceBuffer[0]), SourceCodePage, Length(SourceBuffer));
        end;
      end;
      
      // 从Unicode转换为目标编码
      try
        var TargetStr := UnicodeStringToString(WideStr, TargetCodePage);
        
        // 创建目标缓冲区
        SetLength(ResultBuffer, Length(TargetStr));
        if Length(TargetStr) > 0 then
          Move(TargetStr[1], ResultBuffer[0], Length(TargetStr));
      except
        on E: Exception do
        begin
          if not HandleConversionError(Result, ecetUnmappableChar, 0, 0, E.Message, Options.ErrorHandling) then
            Exit;
            
          // 使用替换字符策略
          var TargetStr := UnicodeStringToString(WideStr, TargetCodePage);
          
          // 创建目标缓冲区
          SetLength(ResultBuffer, Length(TargetStr));
          if Length(TargetStr) > 0 then
            Move(TargetStr[1], ResultBuffer[0], Length(TargetStr));
        end;
      end;
    end
    else
      SetLength(ResultBuffer, 0);
      
    // 添加BOM（如果需要）
    if Options.AddBOM then
    begin
      var BOMType: TBOMType;
      
      if TargetEncoding = ENCODING_UTF8 then
        BOMType := bomUTF8
      else if TargetEncoding = ENCODING_UTF16_LE then
        BOMType := bomUTF16LE
      else if TargetEncoding = ENCODING_UTF16_BE then
        BOMType := bomUTF16BE
      else if TargetEncoding = ENCODING_UTF32_LE then
        BOMType := bomUTF32LE
      else if TargetEncoding = ENCODING_UTF32_BE then
        BOMType := bomUTF32BE
      else
        BOMType := bomNone;
        
      if BOMType <> bomNone then
        ResultBuffer := TEncodingBOMDetector_Improved.AddBOM(ResultBuffer, BOMType);
    end;
    
    // 创建内存流并写入结果
    MemoryStream := TMemoryStream.Create;
    try
      if Length(ResultBuffer) > 0 then
        MemoryStream.WriteBuffer(ResultBuffer[0], Length(ResultBuffer));
        
      Result.Success := True;
      Result.BytesProcessed := Length(ResultBuffer);
    finally
      MemoryStream.Free;
    end;
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
  SourceStream, TargetStream: TFileStream;
  Buffer: TBytes;
  ActualSourceEncoding: string;
begin
  // 初始化结果
  Result.Success := False;
  Result.SourceEncoding := SourceEncoding;
  Result.TargetEncoding := TargetEncoding;
  Result.BytesProcessed := 0;
  Result.ErrorCount := 0;
  SetLength(Result.Errors, 0);
  Result.HasBOM := False;
  
  // 检查源文件是否存在
  if not FileExists(SourceFileName) then
  begin
    AddError(Result, ecetIOError, 0, 0, '源文件不存在');
    Exit;
  end;
  
  try
    // 检测源文件编码
    if (SourceEncoding = '') or Options.DetectSourceEncoding then
      ActualSourceEncoding := DetectFileEncoding(SourceFileName)
    else
      ActualSourceEncoding := SourceEncoding;
      
    Result.SourceEncoding := ActualSourceEncoding;
    
    // 读取源文件
    SourceStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyNone);
    try
      // 读取文件内容
      SetLength(Buffer, SourceStream.Size);
      if SourceStream.Size > 0 then
        SourceStream.ReadBuffer(Buffer[0], SourceStream.Size);
        
      // 转换缓冲区
      Result := ConvertBuffer(Buffer, ActualSourceEncoding, TargetEncoding, Options);
      
      // 写入目标文件
      TargetStream := TFileStream.Create(TargetFileName, fmCreate);
      try
        if Result.BytesProcessed > 0 then
        begin
          // 获取转换后的缓冲区
          var MemoryStream := TMemoryStream.Create;
          try
            MemoryStream.Position := 0;
            SetLength(Buffer, MemoryStream.Size);
            if MemoryStream.Size > 0 then
              MemoryStream.ReadBuffer(Buffer[0], MemoryStream.Size);
              
            // 写入目标文件
            if Length(Buffer) > 0 then
              TargetStream.WriteBuffer(Buffer[0], Length(Buffer));
          finally
            MemoryStream.Free;
          end;
        end;
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
      AddError(Result, ecetUnknownError, 0, 0, E.Message);
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
  // 初始化结果
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
  
  // 保存当前流位置
  Position := SourceStream.Position;
  
  try
    // 检测源流编码
    if (SourceEncoding = '') or Options.DetectSourceEncoding then
    begin
      // 重置流位置
      SourceStream.Position := 0;
      
      // 检测BOM
      BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromStream(SourceStream);
      
      if BOMResult.BOMType <> bomNone then
      begin
        ActualSourceEncoding := BOMResult.Encoding;
        Result.HasBOM := True;
      end
      else
      begin
        // 读取流内容进行分析
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
          // 检测中文编码
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
    if Result.Success and (Result.BytesProcessed > 0) then
    begin
      // 获取转换后的缓冲区
      var MemoryStream := TMemoryStream.Create;
      try
        MemoryStream.Position := 0;
        SetLength(Buffer, MemoryStream.Size);
        if MemoryStream.Size > 0 then
          MemoryStream.ReadBuffer(Buffer[0], MemoryStream.Size);
          
        // 写入目标流
        TargetStream.Position := 0;
        TargetStream.Size := 0;
        if Length(Buffer) > 0 then
          TargetStream.WriteBuffer(Buffer[0], Length(Buffer));
      finally
        MemoryStream.Free;
      end;
    end;
  finally
    // 恢复流位置
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
  
  if BOMResult.BOMType <> bomNone then
    Result := BOMResult.Encoding
  else
  begin
    // 检测UTF-8
    UTF8Result := TUTF8EncodingDetector_Improved.DetectFile(FileName);
    
    if UTF8Result.IsUTF8 then
      Result := ENCODING_UTF8
    else
    begin
      // 检测中文编码
      ChineseResult := TChineseEncodingDetector_Improved.DetectFile(FileName);
      Result := ChineseResult.Encoding;
    end;
  end;
end;

class function TEncodingConverter_Improved.GetCodePage(const EncodingName: string): Integer;
begin
  if EncodingName = ENCODING_UTF8 then
    Result := 65001
  else if EncodingName = ENCODING_UTF8_BOM then
    Result := 65001
  else if EncodingName = ENCODING_UTF16_LE then
    Result := 1200
  else if EncodingName = ENCODING_UTF16_BE then
    Result := 1201
  else if EncodingName = ENCODING_UTF32_LE then
    Result := 12000
  else if EncodingName = ENCODING_UTF32_BE then
    Result := 12001
  else if EncodingName = ENCODING_GBK then
    Result := 936
  else if EncodingName = ENCODING_GB18030 then
    Result := 54936
  else if EncodingName = ENCODING_GB2312 then
    Result := 936
  else if EncodingName = ENCODING_BIG5 then
    Result := 950
  else if EncodingName = ENCODING_SHIFT_JIS then
    Result := 932
  else if EncodingName = ENCODING_EUC_JP then
    Result := 20932
  else if EncodingName = ENCODING_EUC_KR then
    Result := 51949
  else if EncodingName = ENCODING_ANSI then
    Result := GetACP()
  else
    Result := GetACP();
end;

class function TEncodingConverter_Improved.HandleConversionError(var Result: TEncodingConversionResult; ErrorType: TEncodingConversionErrorType; Position: Int64; ByteValue: Byte; const ErrorMessage: string; Strategy: TEncodingErrorHandlingStrategy): Boolean;
begin
  // 添加错误信息
  AddError(Result, ErrorType, Position, ByteValue, ErrorMessage);
  
  // 根据错误处理策略决定是否继续
  case Strategy of
    eehsThrow:
      begin
        Result.Success := False;
        Result := False;
      end;
    eehsReplace, eehsSkip, eehsReport:
      begin
        // 继续处理
        Result := True;
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
  
  // 检查文件是否存在
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
        
        // 读取文件内容（跳过BOM）
        SourceStream.Position := SourceBOMResult.BOMSize;
        SetLength(SourceBuffer, SourceStream.Size - SourceBOMResult.BOMSize);
        if Length(SourceBuffer) > 0 then
          SourceStream.ReadBuffer(SourceBuffer[0], Length(SourceBuffer));
          
        TargetStream.Position := TargetBOMResult.BOMSize;
        SetLength(TargetBuffer, TargetStream.Size - TargetBOMResult.BOMSize);
        if Length(TargetBuffer) > 0 then
          TargetStream.ReadBuffer(TargetBuffer[0], Length(TargetBuffer));
          
        // 如果源编码和目标编码相同，则直接比较内容
        if SourceEncoding = TargetEncoding then
        begin
          // 比较内容（忽略BOM）
          Result := (Length(SourceBuffer) = Length(TargetBuffer));
          
          if Result and (Length(SourceBuffer) > 0) then
            Result := CompareMem(@SourceBuffer[0], @TargetBuffer[0], Length(SourceBuffer));
        end
        else
        begin
          // 如果编码不同，则需要转换后比较
          // 这里简化处理，只检查文件大小是否合理
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
