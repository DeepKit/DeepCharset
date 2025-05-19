unit UtilsEncodingConverter_Improved;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows,
  UtilsEncodingTypes, UtilsEncodingBOM_Improved, UtilsEncodingDetector_Improved;

type
  /// <summary>
  /// 编码转换结果记录
  /// </summary>
  TEncodingConversionResult = record
    Success: Boolean;           // 是否成功
    ErrorMessage: string;       // 错误信息
    SourceEncoding: string;     // 源编码
    TargetEncoding: string;     // 目标编码
    BytesProcessed: Int64;      // 处理的字节数
    ElapsedTime: Int64;         // 耗时(毫秒)
  end;

  /// <summary>
  /// 改进的编码转换器
  /// </summary>
  TEncodingConverter_Improved = class
  private
    class var FLogCallback: TProc<string>;

    /// <summary>
    /// 获取编码对应的代码页
    /// </summary>
    class function GetCodePageFromEncodingName(const EncodingName: string): Integer;

  public
    /// <summary>
    /// 设置日志回调函数
    /// </summary>
    class procedure SetLogCallback(const Callback: TProc<string>);

    /// <summary>
    /// 转换文件编码
    /// </summary>
    class function ConvertFileEncoding(const SourceFileName, TargetFileName: string;
      const SourceEncoding, TargetEncoding: string; AddBOM: Boolean = False): TEncodingConversionResult;

    /// <summary>
    /// 转换字节数组编码
    /// </summary>
    class function ConvertBufferEncoding(const SourceBuffer: TBytes;
      const SourceEncoding, TargetEncoding: string; AddBOM: Boolean = False): TBytes;

    /// <summary>
    /// 添加BOM到文件
    /// </summary>
    class function AddBOMToFile(const FileName: string; const EncodingName: string): Boolean;

    /// <summary>
    /// 移除文件的BOM
    /// </summary>
    class function RemoveBOMFromFile(const FileName: string): Boolean;
  end;

implementation

uses
  System.DateUtils;

{ TEncodingConverter_Improved }

class function TEncodingConverter_Improved.AddBOMToFile(const FileName: string; const EncodingName: string): Boolean;
var
  FileStream: TFileStream;
  Buffer: TBytes;
  BOMType: TBOMType;
  BOMBytes: TBytes;
  TempFileName: string;
  RetryCount: Integer;
  MaxRetries: Integer;
  RetryDelay: Integer;
begin
  Result := False;
  MaxRetries := 3;  // 最大重试次数
  RetryDelay := 100; // 重试延迟（毫秒）

  // 检查文件是否存在
  if not FileExists(FileName) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('文件不存在: ' + FileName);
    Exit;
  end;

  // 确定BOM类型
  if EncodingName = ENCODING_UTF8 then
    BOMType := bomUTF8
  else if EncodingName = ENCODING_UTF16_LE then
    BOMType := bomUTF16LE
  else if EncodingName = ENCODING_UTF16_BE then
    BOMType := bomUTF16BE
  else if EncodingName = ENCODING_UTF32_LE then
    BOMType := bomUTF32LE
  else if EncodingName = ENCODING_UTF32_BE then
    BOMType := bomUTF32BE
  else
  begin
    if Assigned(FLogCallback) then
      FLogCallback('不支持的编码: ' + EncodingName);
    Exit;
  end;

  // 获取BOM字节
  BOMBytes := TEncodingBOMDetector_Improved.GetBOMBytes(BOMType);

  // 创建临时文件名
  TempFileName := FileName + '.tmp';

  try
    // 检查文件是否已经有BOM
    var BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromFile(FileName);
    if BOMResult.BOMType <> bomNone then
    begin
      if Assigned(FLogCallback) then
        FLogCallback('文件已经有BOM: ' + FileName);
      Result := True;
      Exit;
    end;

    // 读取文件内容
    RetryCount := 0;
    while RetryCount < MaxRetries do
    begin
      try
        FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
        try
          // 读取文件内容
          SetLength(Buffer, FileStream.Size);
          if FileStream.Size > 0 then
            FileStream.ReadBuffer(Buffer[0], FileStream.Size);
          Break; // 成功读取，跳出循环
        finally
          FileStream.Free;
        end;
      except
        on E: Exception do
        begin
          Inc(RetryCount);
          if RetryCount >= MaxRetries then
          begin
            if Assigned(FLogCallback) then
              FLogCallback('读取文件失败: ' + E.Message);
            Exit;
          end;

          // 记录重试信息
          if Assigned(FLogCallback) then
            FLogCallback(Format('读取文件失败，正在重试(%d/%d): %s', [RetryCount, MaxRetries, E.Message]));

          // 延迟一段时间后重试
          Sleep(RetryDelay);
        end;
      end;
    end;

    // 写入临时文件
    RetryCount := 0;
    while RetryCount < MaxRetries do
    begin
      try
        FileStream := TFileStream.Create(TempFileName, fmCreate);
        try
          // 写入BOM
          if Length(BOMBytes) > 0 then
            FileStream.WriteBuffer(BOMBytes[0], Length(BOMBytes));

          // 写入原始内容
          if Length(Buffer) > 0 then
            FileStream.WriteBuffer(Buffer[0], Length(Buffer));

          Break; // 成功写入，跳出循环
        finally
          FileStream.Free;
        end;
      except
        on E: Exception do
        begin
          Inc(RetryCount);
          if RetryCount >= MaxRetries then
          begin
            if Assigned(FLogCallback) then
              FLogCallback('创建临时文件失败: ' + E.Message);
            Exit;
          end;

          // 记录重试信息
          if Assigned(FLogCallback) then
            FLogCallback(Format('创建临时文件失败，正在重试(%d/%d): %s', [RetryCount, MaxRetries, E.Message]));

          // 延迟一段时间后重试
          Sleep(RetryDelay);
        end;
      end;
    end;

    // 替换原文件
    RetryCount := 0;
    while RetryCount < MaxRetries do
    begin
      try
        // 删除原文件
        if not DeleteFile(PChar(FileName)) then
        begin
          Inc(RetryCount);
          if RetryCount >= MaxRetries then
          begin
            if Assigned(FLogCallback) then
              FLogCallback('无法删除原文件: ' + FileName);
            DeleteFile(PChar(TempFileName)); // 清理临时文件
            Exit;
          end;

          // 记录重试信息
          if Assigned(FLogCallback) then
            FLogCallback(Format('删除原文件失败，正在重试(%d/%d)', [RetryCount, MaxRetries]));

          // 延迟一段时间后重试
          Sleep(RetryDelay);
          Continue;
        end;

        // 重命名临时文件
        if not RenameFile(TempFileName, FileName) then
        begin
          Inc(RetryCount);
          if RetryCount >= MaxRetries then
          begin
            if Assigned(FLogCallback) then
              FLogCallback('无法重命名临时文件: ' + TempFileName);
            Exit;
          end;

          // 记录重试信息
          if Assigned(FLogCallback) then
            FLogCallback(Format('重命名临时文件失败，正在重试(%d/%d)', [RetryCount, MaxRetries]));

          // 延迟一段时间后重试
          Sleep(RetryDelay);
          Continue;
        end;

        // 成功替换文件
        Result := True;

        if Assigned(FLogCallback) then
          FLogCallback('成功添加BOM到文件: ' + FileName);

        Break; // 成功完成，跳出循环
      except
        on E: Exception do
        begin
          Inc(RetryCount);
          if RetryCount >= MaxRetries then
          begin
            if Assigned(FLogCallback) then
              FLogCallback('替换文件失败: ' + E.Message);
            // 尝试清理临时文件
            try
              if FileExists(TempFileName) then
                DeleteFile(PChar(TempFileName));
            except
              // 忽略清理临时文件时的错误
            end;
            Exit;
          end;

          // 记录重试信息
          if Assigned(FLogCallback) then
            FLogCallback(Format('替换文件失败，正在重试(%d/%d): %s', [RetryCount, MaxRetries, E.Message]));

          // 延迟一段时间后重试
          Sleep(RetryDelay);
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('添加BOM失败: ' + E.Message);
      Result := False;

      // 尝试清理临时文件
      try
        if FileExists(TempFileName) then
          DeleteFile(PChar(TempFileName));
      except
        // 忽略清理临时文件时的错误
      end;
    end;
  end;
end;

class function TEncodingConverter_Improved.ConvertBufferEncoding(const SourceBuffer: TBytes;
  const SourceEncoding, TargetEncoding: string; AddBOM: Boolean): TBytes;
var
  SourceCP, TargetCP: Integer;
  WideStr: WideString;
  SourceBOMType, TargetBOMType: TBOMType;
  SourceBOMResult: TBOMDetectionResult;
  SourceBufferWithoutBOM: TBytes;
begin
  // 初始化结果
  SetLength(Result, 0);

  // 检查源缓冲区是否为空
  if Length(SourceBuffer) = 0 then
    Exit;

  // 获取源编码和目标编码的代码页
  SourceCP := GetCodePageFromEncodingName(SourceEncoding);
  TargetCP := GetCodePageFromEncodingName(TargetEncoding);

  // 检查编码是否支持
  if (SourceCP = 0) or (TargetCP = 0) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback(Format('不支持的编码: 源=%s, 目标=%s', [SourceEncoding, TargetEncoding]));
    Exit;
  end;

  try
    // 检测源缓冲区的BOM
    SourceBOMResult := TEncodingBOMDetector_Improved.DetectBOM(SourceBuffer);

    // 如果源缓冲区有BOM，移除它
    if SourceBOMResult.BOMType <> bomNone then
      SourceBufferWithoutBOM := TEncodingBOMDetector_Improved.RemoveBOM(SourceBuffer)
    else
      SourceBufferWithoutBOM := SourceBuffer;

    // 将源缓冲区转换为Unicode
    if (SourceEncoding = ENCODING_UTF16_LE) or (SourceEncoding = ENCODING_UTF16_BE) then
    begin
      // 如果源编码已经是UTF-16，直接使用
      SetLength(WideStr, Length(SourceBufferWithoutBOM) div 2);
      if Length(SourceBufferWithoutBOM) > 0 then
        Move(SourceBufferWithoutBOM[0], WideStr[1], Length(SourceBufferWithoutBOM));
    end
    else
    begin
      // 其他编码需要转换为Unicode
      // 先计算需要的缓冲区大小
      var CharsNeeded := MultiByteToWideChar(
        SourceCP,
        0,
        @SourceBufferWithoutBOM[0],
        Length(SourceBufferWithoutBOM),
        nil,
        0);

      if CharsNeeded = 0 then
      begin
        if Assigned(FLogCallback) then
          FLogCallback('计算Unicode缓冲区大小失败');
        Exit;
      end;

      SetLength(WideStr, CharsNeeded);

      if Length(SourceBufferWithoutBOM) > 0 then
      begin
        var CharsWritten := MultiByteToWideChar(
          SourceCP,
          0,
          @SourceBufferWithoutBOM[0],
          Length(SourceBufferWithoutBOM),
          PWideChar(WideStr),
          Length(WideStr));

        if CharsWritten = 0 then
        begin
          if Assigned(FLogCallback) then
            FLogCallback('转换到Unicode失败');
          Exit;
        end;
      end;
    end;

    // 将Unicode转换为目标编码
    if TargetEncoding = ENCODING_UTF16_LE then
    begin
      // 如果目标是UTF-16 LE，直接使用Unicode字符串
      SetLength(Result, Length(WideStr) * SizeOf(WideChar));
      if Length(WideStr) > 0 then
      begin
        Move(WideStr[1], Result[0], Length(WideStr) * SizeOf(WideChar));
        if Assigned(FLogCallback) then
          FLogCallback(Format('转换为UTF-16 LE: 源长度=%d, 目标长度=%d', [Length(SourceBufferWithoutBOM), Length(Result)]));
      end;
    end
    else if TargetEncoding = ENCODING_UTF16_BE then
    begin
      // 如果目标是UTF-16 BE，需要交换字节顺序
      SetLength(Result, Length(WideStr) * SizeOf(WideChar));
      if Length(WideStr) > 0 then
      begin
        for var i := 0 to Length(WideStr) - 1 do
        begin
          Result[i * 2] := Byte(Word(WideStr[i + 1]) shr 8);
          Result[i * 2 + 1] := Byte(Word(WideStr[i + 1]));
        end;
        if Assigned(FLogCallback) then
          FLogCallback(Format('转换为UTF-16 BE: 源长度=%d, 目标长度=%d', [Length(SourceBufferWithoutBOM), Length(Result)]));
      end;
    end
    else
    begin
      // 其他编码需要从Unicode转换
      var BytesNeeded := WideCharToMultiByte(
        TargetCP,
        0,
        PWideChar(WideStr),
        Length(WideStr),
        nil,
        0,
        nil,
        nil);

      if BytesNeeded = 0 then
      begin
        if Assigned(FLogCallback) then
          FLogCallback('计算目标缓冲区大小失败');
        Exit;
      end;

      SetLength(Result, BytesNeeded);

      var BytesWritten := WideCharToMultiByte(
        TargetCP,
        0,
        PWideChar(WideStr),
        Length(WideStr),
        @Result[0],
        Length(Result),
        nil,
        nil);

      if BytesWritten = 0 then
      begin
        if Assigned(FLogCallback) then
          FLogCallback('转换到目标编码失败');
        SetLength(Result, 0);
        Exit;
      end;

      SetLength(Result, BytesWritten);

      if Assigned(FLogCallback) then
        FLogCallback(Format('转换到其他编码: 源长度=%d, 目标长度=%d', [Length(SourceBufferWithoutBOM), Length(Result)]));
    end;

    // 如果需要添加BOM
    if AddBOM then
    begin
      // 确定目标BOM类型
      if TargetEncoding = ENCODING_UTF8 then
        TargetBOMType := bomUTF8
      else if TargetEncoding = ENCODING_UTF16_LE then
        TargetBOMType := bomUTF16LE
      else if TargetEncoding = ENCODING_UTF16_BE then
        TargetBOMType := bomUTF16BE
      else if TargetEncoding = ENCODING_UTF32_LE then
        TargetBOMType := bomUTF32LE
      else if TargetEncoding = ENCODING_UTF32_BE then
        TargetBOMType := bomUTF32BE
      else
        TargetBOMType := bomNone;

      // 添加BOM
      if TargetBOMType <> bomNone then
        Result := TEncodingBOMDetector_Improved.AddBOM(Result, TargetBOMType);
    end;
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('转换编码失败: ' + E.Message);
      SetLength(Result, 0);
    end;
  end;
end;

class function TEncodingConverter_Improved.ConvertFileEncoding(const SourceFileName, TargetFileName: string;
  const SourceEncoding, TargetEncoding: string; AddBOM: Boolean): TEncodingConversionResult;
var
  SourceBuffer, TargetBuffer: TBytes;
  SourceStream, TargetStream: TFileStream;
  StartTime: TDateTime;
  TempFileName: string;
  RetryCount: Integer;
  MaxRetries: Integer;
  RetryDelay: Integer;
  SourceDir, TargetDir: string;
begin
  StartTime := Now;
  MaxRetries := 3;  // 最大重试次数
  RetryDelay := 100; // 重试延迟（毫秒）

  // 初始化结果
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.SourceEncoding := SourceEncoding;
  Result.TargetEncoding := TargetEncoding;
  Result.BytesProcessed := 0;
  Result.ElapsedTime := 0;

  // 检查源文件是否存在
  if not FileExists(SourceFileName) then
  begin
    Result.ErrorMessage := '源文件不存在: ' + SourceFileName;
    if Assigned(FLogCallback) then
      FLogCallback(Result.ErrorMessage);
    Exit;
  end;

  // 确保目标目录存在
  TargetDir := ExtractFileDir(TargetFileName);
  if (TargetDir <> '') and not DirectoryExists(TargetDir) then
  begin
    try
      ForceDirectories(TargetDir);
    except
      on E: Exception do
      begin
        Result.ErrorMessage := '创建目标目录失败: ' + E.Message;
        if Assigned(FLogCallback) then
          FLogCallback(Result.ErrorMessage);
        Exit;
      end;
    end;
  end;

  // 创建临时文件名
  TempFileName := ChangeFileExt(TargetFileName, '.tmp');

  try
    // 读取源文件（使用共享模式，允许其他进程读取）
    RetryCount := 0;
    while RetryCount < MaxRetries do
    begin
      try
        SourceStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyNone);
        try
          SetLength(SourceBuffer, SourceStream.Size);
          if SourceStream.Size > 0 then
            SourceStream.ReadBuffer(SourceBuffer[0], SourceStream.Size);
          Break; // 成功读取，跳出循环
        finally
          SourceStream.Free;
        end;
      except
        on E: Exception do
        begin
          Inc(RetryCount);
          if RetryCount >= MaxRetries then
          begin
            Result.ErrorMessage := '读取源文件失败: ' + E.Message;
            if Assigned(FLogCallback) then
              FLogCallback(Result.ErrorMessage);
            Exit;
          end;

          // 记录重试信息
          if Assigned(FLogCallback) then
            FLogCallback(Format('读取源文件失败，正在重试(%d/%d): %s', [RetryCount, MaxRetries, E.Message]));

          // 延迟一段时间后重试
          Sleep(RetryDelay);
        end;
      end;
    end;

    // 转换编码
    TargetBuffer := ConvertBufferEncoding(SourceBuffer, SourceEncoding, TargetEncoding, AddBOM);

    // 检查转换结果
    if Length(TargetBuffer) = 0 then
    begin
      Result.ErrorMessage := '编码转换失败';
      if Assigned(FLogCallback) then
        FLogCallback(Result.ErrorMessage);
      Exit;
    end;

    // 创建临时文件
    RetryCount := 0;
    while RetryCount < MaxRetries do
    begin
      try
        // 确保临时文件目录存在
        TargetDir := ExtractFileDir(TempFileName);
        if (TargetDir <> '') and not DirectoryExists(TargetDir) then
          ForceDirectories(TargetDir);

        // 创建临时文件
        TargetStream := TFileStream.Create(TempFileName, fmCreate);
        try
          // 写入转换后的内容
          if Length(TargetBuffer) > 0 then
            TargetStream.WriteBuffer(TargetBuffer[0], Length(TargetBuffer));
          Break; // 成功写入，跳出循环
        finally
          TargetStream.Free;
        end;
      except
        on E: Exception do
        begin
          Inc(RetryCount);
          if RetryCount >= MaxRetries then
          begin
            Result.ErrorMessage := '创建临时文件失败: ' + E.Message;
            if Assigned(FLogCallback) then
              FLogCallback(Result.ErrorMessage);
            Exit;
          end;

          // 记录重试信息
          if Assigned(FLogCallback) then
            FLogCallback(Format('创建临时文件失败，正在重试(%d/%d): %s', [RetryCount, MaxRetries, E.Message]));

          // 延迟一段时间后重试
          Sleep(RetryDelay);
        end;
      end;
    end;

    // 替换目标文件
    RetryCount := 0;
    while RetryCount < MaxRetries do
    begin
      try
        // 如果目标文件已存在，先删除
        if FileExists(TargetFileName) then
        begin
          if not DeleteFile(PChar(TargetFileName)) then
          begin
            Inc(RetryCount);
            if RetryCount >= MaxRetries then
            begin
              Result.ErrorMessage := '无法删除已存在的目标文件: ' + TargetFileName;
              if Assigned(FLogCallback) then
                FLogCallback(Result.ErrorMessage);
              DeleteFile(PChar(TempFileName)); // 清理临时文件
              Exit;
            end;

            // 记录重试信息
            if Assigned(FLogCallback) then
              FLogCallback(Format('删除目标文件失败，正在重试(%d/%d)', [RetryCount, MaxRetries]));

            // 延迟一段时间后重试
            Sleep(RetryDelay);
            Continue;
          end;
        end;

        // 重命名临时文件为目标文件
        if not RenameFile(TempFileName, TargetFileName) then
        begin
          Inc(RetryCount);
          if RetryCount >= MaxRetries then
          begin
            Result.ErrorMessage := '无法重命名临时文件: ' + TempFileName;
            if Assigned(FLogCallback) then
              FLogCallback(Result.ErrorMessage);
            DeleteFile(PChar(TempFileName)); // 清理临时文件
            Exit;
          end;

          // 记录重试信息
          if Assigned(FLogCallback) then
            FLogCallback(Format('重命名临时文件失败，正在重试(%d/%d)', [RetryCount, MaxRetries]));

          // 延迟一段时间后重试
          Sleep(RetryDelay);
          Continue;
        end;

        // 成功替换文件
        Result.Success := True;
        Result.BytesProcessed := Length(SourceBuffer);
        Result.ElapsedTime := MilliSecondsBetween(StartTime, Now);

        if Assigned(FLogCallback) then
          FLogCallback(Format('成功转换文件编码: %s -> %s (耗时: %d ms)',
            [SourceFileName, TargetFileName, Result.ElapsedTime]));

        Break; // 成功完成，跳出循环
      except
        on E: Exception do
        begin
          Inc(RetryCount);
          if RetryCount >= MaxRetries then
          begin
            Result.ErrorMessage := '替换目标文件失败: ' + E.Message;
            if Assigned(FLogCallback) then
              FLogCallback(Result.ErrorMessage);
            // 尝试清理临时文件
            try
              if FileExists(TempFileName) then
                DeleteFile(PChar(TempFileName));
            except
              // 忽略清理临时文件时的错误
            end;
            Exit;
          end;

          // 记录重试信息
          if Assigned(FLogCallback) then
            FLogCallback(Format('替换目标文件失败，正在重试(%d/%d): %s', [RetryCount, MaxRetries, E.Message]));

          // 延迟一段时间后重试
          Sleep(RetryDelay);
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      Result.ErrorMessage := '转换文件编码失败: ' + E.Message;
      if Assigned(FLogCallback) then
        FLogCallback(Result.ErrorMessage);

      // 尝试清理临时文件
      try
        if FileExists(TempFileName) then
          DeleteFile(PChar(TempFileName));
      except
        // 忽略清理临时文件时的错误
      end;
    end;
  end;
end;

class function TEncodingConverter_Improved.GetCodePageFromEncodingName(const EncodingName: string): Integer;
begin
  if EncodingName = ENCODING_UTF8 then
    Result := CP_UTF8
  else if EncodingName = ENCODING_UTF8_BOM then
    Result := CP_UTF8
  else if EncodingName = ENCODING_UTF16_LE then
    Result := CP_UTF16_LE
  else if EncodingName = ENCODING_UTF16_BE then
    Result := CP_UTF16_BE
  else if EncodingName = ENCODING_UTF32_LE then
    Result := CP_UTF32_LE
  else if EncodingName = ENCODING_UTF32_BE then
    Result := CP_UTF32_BE
  else if EncodingName = ENCODING_GBK then
    Result := CP_GBK
  else if EncodingName = ENCODING_GB2312 then
    Result := CP_GB2312
  else if EncodingName = ENCODING_GB18030 then
    Result := CP_GB18030
  else if EncodingName = ENCODING_BIG5 then
    Result := CP_BIG5
  else if EncodingName = ENCODING_SHIFT_JIS then
    Result := CP_SHIFT_JIS
  else if EncodingName = ENCODING_EUC_JP then
    Result := CP_EUC_JP
  else if EncodingName = ENCODING_ISO2022_JP then
    Result := CP_ISO_2022_JP
  else if EncodingName = ENCODING_EUC_KR then
    Result := CP_EUC_KR
  else if EncodingName = ENCODING_ISO_2022_KR then
    Result := CP_ISO_2022_KR
  else if EncodingName = ENCODING_ANSI then
    Result := GetACP() // 获取系统默认ANSI代码页
  else
    Result := 0; // 未知编码
end;

class function TEncodingConverter_Improved.RemoveBOMFromFile(const FileName: string): Boolean;
var
  FileStream: TFileStream;
  Buffer: TBytes;
  BOMResult: TBOMDetectionResult;
  TempFileName: string;
  RetryCount: Integer;
  MaxRetries: Integer;
  RetryDelay: Integer;
begin
  Result := False;
  MaxRetries := 3;  // 最大重试次数
  RetryDelay := 100; // 重试延迟（毫秒）

  // 检查文件是否存在
  if not FileExists(FileName) then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('文件不存在: ' + FileName);
    Exit;
  end;

  // 检查文件是否有BOM
  BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromFile(FileName);
  if BOMResult.BOMType = bomNone then
  begin
    if Assigned(FLogCallback) then
      FLogCallback('文件没有BOM: ' + FileName);
    Result := True;
    Exit;
  end;

  // 创建临时文件名
  TempFileName := FileName + '.tmp';

  try
    // 读取文件内容
    RetryCount := 0;
    while RetryCount < MaxRetries do
    begin
      try
        FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
        try
          // 读取文件内容
          SetLength(Buffer, FileStream.Size);
          if FileStream.Size > 0 then
            FileStream.ReadBuffer(Buffer[0], FileStream.Size);
          Break; // 成功读取，跳出循环
        finally
          FileStream.Free;
        end;
      except
        on E: Exception do
        begin
          Inc(RetryCount);
          if RetryCount >= MaxRetries then
          begin
            if Assigned(FLogCallback) then
              FLogCallback('读取文件失败: ' + E.Message);
            Exit;
          end;

          // 记录重试信息
          if Assigned(FLogCallback) then
            FLogCallback(Format('读取文件失败，正在重试(%d/%d): %s', [RetryCount, MaxRetries, E.Message]));

          // 延迟一段时间后重试
          Sleep(RetryDelay);
        end;
      end;
    end;

    // 移除BOM
    Buffer := TEncodingBOMDetector_Improved.RemoveBOM(Buffer);

    // 写入临时文件
    RetryCount := 0;
    while RetryCount < MaxRetries do
    begin
      try
        FileStream := TFileStream.Create(TempFileName, fmCreate);
        try
          // 写入不带BOM的内容
          if Length(Buffer) > 0 then
            FileStream.WriteBuffer(Buffer[0], Length(Buffer));
          Break; // 成功写入，跳出循环
        finally
          FileStream.Free;
        end;
      except
        on E: Exception do
        begin
          Inc(RetryCount);
          if RetryCount >= MaxRetries then
          begin
            if Assigned(FLogCallback) then
              FLogCallback('创建临时文件失败: ' + E.Message);
            Exit;
          end;

          // 记录重试信息
          if Assigned(FLogCallback) then
            FLogCallback(Format('创建临时文件失败，正在重试(%d/%d): %s', [RetryCount, MaxRetries, E.Message]));

          // 延迟一段时间后重试
          Sleep(RetryDelay);
        end;
      end;
    end;

    // 替换原文件
    RetryCount := 0;
    while RetryCount < MaxRetries do
    begin
      try
        // 删除原文件
        if not DeleteFile(PChar(FileName)) then
        begin
          Inc(RetryCount);
          if RetryCount >= MaxRetries then
          begin
            if Assigned(FLogCallback) then
              FLogCallback('无法删除原文件: ' + FileName);
            DeleteFile(PChar(TempFileName)); // 清理临时文件
            Exit;
          end;

          // 记录重试信息
          if Assigned(FLogCallback) then
            FLogCallback(Format('删除原文件失败，正在重试(%d/%d)', [RetryCount, MaxRetries]));

          // 延迟一段时间后重试
          Sleep(RetryDelay);
          Continue;
        end;

        // 重命名临时文件
        if not RenameFile(TempFileName, FileName) then
        begin
          Inc(RetryCount);
          if RetryCount >= MaxRetries then
          begin
            if Assigned(FLogCallback) then
              FLogCallback('无法重命名临时文件: ' + TempFileName);
            Exit;
          end;

          // 记录重试信息
          if Assigned(FLogCallback) then
            FLogCallback(Format('重命名临时文件失败，正在重试(%d/%d)', [RetryCount, MaxRetries]));

          // 延迟一段时间后重试
          Sleep(RetryDelay);
          Continue;
        end;

        // 成功替换文件
        Result := True;

        if Assigned(FLogCallback) then
          FLogCallback('成功移除文件的BOM: ' + FileName);

        Break; // 成功完成，跳出循环
      except
        on E: Exception do
        begin
          Inc(RetryCount);
          if RetryCount >= MaxRetries then
          begin
            if Assigned(FLogCallback) then
              FLogCallback('替换文件失败: ' + E.Message);
            // 尝试清理临时文件
            try
              if FileExists(TempFileName) then
                DeleteFile(PChar(TempFileName));
            except
              // 忽略清理临时文件时的错误
            end;
            Exit;
          end;

          // 记录重试信息
          if Assigned(FLogCallback) then
            FLogCallback(Format('替换文件失败，正在重试(%d/%d): %s', [RetryCount, MaxRetries, E.Message]));

          // 延迟一段时间后重试
          Sleep(RetryDelay);
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      if Assigned(FLogCallback) then
        FLogCallback('移除BOM失败: ' + E.Message);
      Result := False;

      // 尝试清理临时文件
      try
        if FileExists(TempFileName) then
          DeleteFile(PChar(TempFileName));
      except
        // 忽略清理临时文件时的错误
      end;
    end;
  end;
end;

class procedure TEncodingConverter_Improved.SetLogCallback(const Callback: TProc<string>);
begin
  FLogCallback := Callback;
end;

end.
