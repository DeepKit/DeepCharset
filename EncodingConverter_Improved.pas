unit EncodingConverter_Improved;

interface

uses
  System.SysUtils, System.Classes, System.Math, Winapi.Windows, System.IOUtils, 
  System.SyncObjs, UtilsTypes, UtilsPathSecurity,
  UtilsEncodingBOM_Improved, UtilsEncodingUTF8Detector_Improved,
  ChineseEncodingDetector_Improved, UTF8BOMConverter_Improved, UtilsEncodingHelper;

type
  /// <summary>
  /// 编码转换错误类型
  /// </summary>
  TEncodingConversionErrorType = (
    ecetNone,              // 无错??
    ecetInvalidSequence,   // 无效序列
    ecetUnmappableChar,    // 无法映射的字??
    ecetIncompleteSequence, // 不完整序??
    ecetIOError,           // IO错误
    ecetUnknownError       // 未知错误
  );

  /// <summary>
  /// 编码转换错误处理策略
  /// </summary>
  TEncodingErrorHandlingStrategy = (
    eehsThrow,             // 抛出异常
    eehsReplace,           // 替换为替代字??
    eehsSkip,              // 跳过错误
    eehsReport             // 报告错误但继??
  );

  /// <summary>
  /// 编码转换错误信息
  /// </summary>
  TEncodingConversionError = record
    ErrorType: TEncodingConversionErrorType;  // 错误类型
    Position: Int64;                         // 错误位置
    ByteValue: Byte;                         // 错误字节??
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
    MaxErrorCount: Integer;                  // 最大错误数量
  end;

  /// <summary>
  /// 流式转换进度回调
  /// </summary>
  TStreamingProgressCallback = reference to procedure(
    BytesProcessed: Int64;   // 已处理字节数
    TotalBytes: Int64;       // 总字节数
    var Cancel: Boolean      // 设为True取消转换
  );

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
    /// 检测文件编??
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
    /// 将指定编码的字节缓冲区解码为 Unicode 字符串
    /// </summary>
    class function DecodeBufferToUnicode(const Buffer: TBytes; const EncodingName: string): UnicodeString;

    /// <summary>
    /// 检查文件是否可以写??
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
    /// 转换流编??
    /// </summary>
    class function ConvertStream(const SourceStream, TargetStream: TStream; const SourceEncoding, TargetEncoding: string; const Options: TEncodingConversionOptions): TEncodingConversionResult;

    /// <summary>
    /// 批量转换文件编码
    /// </summary>
    class function BatchConvertFiles(const FileNames: TArray<string>; const TargetDir: string; const TargetEncoding: string; const Options: TEncodingConversionOptions): TArray<TEncodingConversionResult>;

    /// <summary>
    /// 验证转换结果（基于文件级别的粗粒度校验）
    /// </summary>
    class function ValidateConversion(const SourceFileName, TargetFileName: string): Boolean;

    /// <summary>
    /// 验证编码转换结果的完整性（内容校验）
    /// 注意：该方法主要用于测试与自检场景，可能开销较大。
    /// </summary>
    class function ValidateConversionIntegrity(
      const SourceBuffer: TBytes;
      const SourceEncoding: string;
      const ConversionResult: TEncodingConversionResult): Boolean;

    /// <summary>
    /// 流式转换大文件（内存友好，支持>2GB文件）
    /// Bug #16 修复：避免一次性加载整个文件到内存
    /// </summary>
    /// <param name="SourceFileName">源文件路径</param>
    /// <param name="TargetFileName">目标文件路径</param>
    /// <param name="SourceEncoding">源编码（空字符串表示自动检测）</param>
    /// <param name="TargetEncoding">目标编码</param>
    /// <param name="Options">转换选项</param>
    /// <param name="ProgressCallback">进度回调（可选）</param>
    /// <returns>转换结果</returns>
    class function ConvertFileStreaming(
      const SourceFileName, TargetFileName: string;
      const SourceEncoding, TargetEncoding: string;
      const Options: TEncodingConversionOptions;
      const ProgressCallback: TStreamingProgressCallback = nil): TEncodingConversionResult;
  end;

implementation

uses
  UtilsBOMCleaner, UtilsTempFileSecurity, EncodingExceptions;

{$WARN IMPLICIT_STRING_CAST OFF}

const
  DEBUG_CONVERT_TRACE: Boolean = False;

var
  CodePageCache: array[0..31] of record
    Name: string;
    CodePage: Integer;
  end;
  CodePageCacheCount: Integer = 0;
  CodePageCacheLock: TCriticalSection;

function _TraceFilePath: string;
begin
  // 写入到与自测一致的 tmp_tests 目录，便于统一查看
  var Root := ExtractFilePath(ParamStr(0));
  var Dir := TPath.GetFullPath(TPath.Combine(Root, '..\tmp_tests'));
  ForceDirectories(Dir);
  Result := TPath.Combine(Dir, 'convert_trace.txt');
end;

procedure _Trace(const S: string);
begin
  if not DEBUG_CONVERT_TRACE then Exit;
  try
    TFile.AppendAllText(_TraceFilePath, FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' ' + S + sLineBreak, TEncoding.UTF8);
  except
    // 忽略日志写入错误
  end;
end;

function _BytesHeadHex(const B: TBytes; Count: Integer): string;
var i, L: Integer;
begin
  Result := '';
  L := Length(B); if Count < L then L := Count;
  for i := 0 to L-1 do
  begin
    Result := Result + IntToHex(B[i], 2);
    if i < L-1 then Result := Result + ' ';
  end;
end;

// 从指定代码页的字符串转换为Unicode字符串
function StringToUnicodeString(const Source: PAnsiChar; CodePage: Integer; SourceLength: Integer): UnicodeString;
var
  DestLength: Integer;
  i, CharCount: Integer;
  P: PByte;
  W: Word;
begin
  if (Source = nil) or (SourceLength <= 0) then
  begin
    Result := '';
    Exit;
  end;

  // 专门处理 UTF-16LE/UTF-16BE，避免依赖底层 API 对 1200/1201 的支持差异
  if (CodePage = 1200) or (CodePage = 1201) then
  begin
    CharCount := SourceLength div SizeOf(WideChar);
    if CharCount <= 0 then
    begin
      Result := '';
      Exit;
    end;

    SetLength(Result, CharCount);
    P := PByte(Source);
    for i := 0 to CharCount - 1 do
    begin
      if CodePage = 1200 then
        // UTF-16LE: 低字节在前
        W := Word(P[0] or (P[1] shl 8))
      else
        // UTF-16BE: 高字节在前
        W := Word((P[0] shl 8) or P[1]);
      Result[i+1] := WideChar(W);
      Inc(P, 2);
    end;
    Exit;
  end;

  // 专门处理 UTF-32LE/UTF-32BE（这里的文件是本项目写出的，每个 32bit 低 16bit 存实际字符）
  if (CodePage = 12000) or (CodePage = 12001) then
  begin
    CharCount := SourceLength div 4;
    if CharCount <= 0 then
    begin
      Result := '';
      Exit;
    end;

    SetLength(Result, CharCount);
    P := PByte(Source);
    for i := 0 to CharCount - 1 do
    begin
      if CodePage = 12000 then
        // UTF-32LE: 低两个字节是 UTF-16 单元
        W := Word(P[0] or (P[1] shl 8))
      else
        // UTF-32BE: 高两个字节承载 UTF-16 单元（文件写入时高 16bit 始终为 0）
        W := Word((P[2] shl 8) or P[3]);
      Result[i+1] := WideChar(W);
      Inc(P, 4);
    end;
    Exit;
  end;

  // 其他代码页仍然走 MultiByteToWideChar
  DestLength := MultiByteToWideChar(CodePage, 0, Source, SourceLength, nil, 0);

  if DestLength <= 0 then
  begin
    Result := '';
    Exit;
  end;

  SetLength(Result, DestLength);
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

// 使用 TEncoding 进行编码转换（用于 ISO-2022 等基于转义序列的编码，
// MultiByteToWideChar 对这类代码页支持不佳）
function ConvertViaTEncoding(const Buffer: TBytes; SourceCodePage, TargetCodePage: Integer): TBytes;
var
  SrcEnc, TgtEnc: TEncoding;
  WideStr: UnicodeString;
  TmpBuf: TBytes;
begin
  SetLength(Result, 0);
  SrcEnc := nil;
  TgtEnc := nil;
  try
    SrcEnc := TEncoding.GetEncoding(SourceCodePage);
    WideStr := SrcEnc.GetString(Buffer);

    if TargetCodePage = 65001 then
      TgtEnc := TEncoding.UTF8
    else
      TgtEnc := TEncoding.GetEncoding(TargetCodePage);

    TmpBuf := TgtEnc.GetBytes(WideStr);
    Result := TmpBuf;
  finally
    if Assigned(SrcEnc) then FreeAndNil(SrcEnc);
    if Assigned(TgtEnc) and (TgtEnc <> TEncoding.UTF8) then FreeAndNil(TgtEnc);
  end;
end;

class function TEncodingConverter_Improved.DecodeBufferToUnicode(const Buffer: TBytes;
  const EncodingName: string): UnicodeString;
var
  CP: Integer;
  AnsiBuf: AnsiString;
begin
  if Length(Buffer) = 0 then
  begin
    Result := '';
    Exit;
  end;

  CP := GetCodePage(EncodingName);
  if CP = 0 then
  begin
    // 无法解析编码时返回空字符串，由调用方决定如何处理
    Result := '';
    Exit;
  end;

  SetLength(AnsiBuf, Length(Buffer));
  if Length(Buffer) > 0 then
    Move(Buffer[0], AnsiBuf[1], Length(Buffer));

  Result := StringToUnicodeString(PAnsiChar(AnsiBuf), CP, Length(AnsiBuf));
end;

{ TEncodingConverter_Improved }

class procedure TEncodingConverter_Improved.AddError(var ConvResult: TEncodingConversionResult; ErrorType: TEncodingConversionErrorType; Position: Int64; ByteValue: Byte; const ErrorMessage: string);
begin
  // 增加错误计数
  Inc(ConvResult.ErrorCount);

  // 添加错误信息到错误列??
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
    // 构建目标文件??
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
begin
  // 初始化结??
  _Trace(Format('[ConvertStream] begin src="%s" tgt="%s" detectSrc=%s',
    [SourceEncoding, TargetEncoding, BoolToStr(Options.DetectSourceEncoding, True)]));
  _Trace(Format('[ConvertBuffer] begin src="%s" tgt="%s" addBOM=%s detectSrc=%s len=%d head=%s',
    [SourceEncoding, TargetEncoding, BoolToStr(Options.AddBOM, True), BoolToStr(Options.DetectSourceEncoding, True), Length(Buffer), _BytesHeadHex(Buffer, 24)]));
  Result.Success := False;
  Result.SourceEncoding := SourceEncoding;
  Result.TargetEncoding := TargetEncoding;
  Result.BytesProcessed := 0;
  Result.ErrorCount := 0;
  SetLength(Result.Errors, 0);
  Result.HasBOM := False;

  // 显式初始化 BOM 检测结果，防止在未执行检测时误用
  BOMResult.BOMType := 0;
  BOMResult.BOMLength := 0;

  // 检查缓冲区是否为空
  if Length(Buffer) = 0 then
  begin
    Result.Success := True;
    SetLength(ResultBuffer, 0);
    Result.OutputData := ResultBuffer;
    Result.BytesProcessed := 0;
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
        // 显式转换
        ActualSourceEncoding := string(BOMResult.Encoding);
        Result.HasBOM := True;
        _Trace(Format('[ConvertBuffer] BOM detected type=%d enc=%s', [BOMResult.BOMType, ActualSourceEncoding]));
      end
      else
      begin
        // 检测UTF-8
        UTF8Result := TUTF8EncodingDetector_Improved.DetectBuffer(Buffer);

        if UTF8Result.IsUTF8 then
          ActualSourceEncoding := ENCODING_UTF8
        else
        begin
          // 检测中文编??
          ChineseResult := TChineseEncodingDetector_Improved.DetectBuffer(Buffer);
          // 显式转换
          ActualSourceEncoding := string(ChineseResult.Encoding);
        end;
        _Trace(Format('[ConvertBuffer] Detect src enc=%s utf8=%s conf=%.3f', [ActualSourceEncoding, BoolToStr(UTF8Result.IsUTF8, True), UTF8Result.Confidence]));
      end;
    end
    else
      ActualSourceEncoding := SourceEncoding;

    Result.SourceEncoding := ActualSourceEncoding;
    _Trace('[ConvertStream] ActualSourceEncoding=' + ActualSourceEncoding);

    // 获取源编码和目标编码的代码页
    SourceCodePage := GetCodePage(ActualSourceEncoding);
    TargetCodePage := GetCodePage(TargetEncoding);
    _Trace(Format('[ConvertBuffer] CodePages src=%d tgt=%d', [SourceCodePage, TargetCodePage]));

    // 快速路径：源编码和目标编码相同
    // 非 UTF-8 家族：可以直接透传缓冲区，避免重复转换
    var IsUTF8Family := (SourceCodePage = 65001) or (TargetCodePage = 65001);
    if (SourceCodePage = TargetCodePage) and not IsUTF8Family and not Options.AddBOM then
    begin
      ResultBuffer := Buffer;
      Result.Success := True;
      Result.BytesProcessed := Length(ResultBuffer);
      Result.OutputData := ResultBuffer;
      _Trace(Format('[ConvertBuffer] fast path same codepage=%d len=%d', [SourceCodePage, Length(ResultBuffer)]));
      Exit;
    end;

    // 非 UTF-8 同码页 + AddBOM：检测并去除源 BOM，再根据需要写入目标 BOM
    if (SourceCodePage = TargetCodePage) and not IsUTF8Family and Options.AddBOM then
    begin
      // 始终检测源 BOM（即使 DetectSourceEncoding=False），以便正确剥离
      var SrcBOM := TEncodingBOMDetector_Improved.DetectBOM(Buffer);
      if SrcBOM.BOMType <> 0 then
      begin
        // 剥离已有的源 BOM，仅保留纯载荷
        SetLength(ResultBuffer, Length(Buffer) - SrcBOM.BOMLength);
        if Length(ResultBuffer) > 0 then
          Move(Buffer[SrcBOM.BOMLength], ResultBuffer[0], Length(ResultBuffer));
      end
      else
        ResultBuffer := Copy(Buffer);

      // 根据 AddBOM 在首部写入恰好一个目标 BOM
      var TargetBOMType := 0;
      case TargetCodePage of
        1200:  TargetBOMType := 2;  // UTF-16 LE
        1201:  TargetBOMType := 3;  // UTF-16 BE
        12000: TargetBOMType := 4;  // UTF-32 LE
        12001: TargetBOMType := 5;  // UTF-32 BE
      end;
      if TargetBOMType <> 0 then
      begin
        ResultBuffer := TEncodingBOMDetector_Improved.AddBOM(ResultBuffer, TargetBOMType);
        Result.HasBOM := True;
      end;

      Result.Success := True;
      Result.BytesProcessed := Length(ResultBuffer);
      Result.OutputData := ResultBuffer;
      _Trace(Format('[ConvertBuffer] same-CP AddBOM path cp=%d srcBOM=%d outLen=%d',
        [TargetCodePage, SrcBOM.BOMType, Length(ResultBuffer)]));
      Exit;
    end;

    // UTF-8 / UTF-8-BOM 同码页快速路径：统一交给 BOM 清理器处理
    if (SourceCodePage = TargetCodePage) and IsUTF8Family then
    begin
      var EnsureBOM := CompareText(TargetEncoding, ENCODING_UTF8_BOM) = 0;
      ResultBuffer := TBOMCleaner.CleanUTF8Artifacts(Buffer, EnsureBOM);
      Result.Success := True;
      Result.BytesProcessed := Length(ResultBuffer);
      Result.OutputData := ResultBuffer;
      Result.HasBOM := EnsureBOM;
      _Trace(Format('[ConvertBuffer] UTF8-family fast path ensureBOM=%s len=%d',
        [BoolToStr(EnsureBOM, True), Length(ResultBuffer)]));
      Exit;
    end;

    // 准备源缓冲区，跳过BOM（如果有）
    // 即使 DetectSourceEncoding=False 也需要检测 BOM 以便正确剥离，
    // 否则后续转换会将源 BOM 当作普通数据导致 BOM 重复或内容损坏。
    if BOMResult.BOMType = 0 then
      BOMResult := TEncodingBOMDetector_Improved.DetectBOM(Buffer);
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
      // ISO-2022 变体代码页（50220/50221/50222）使用转义序列，
      // MultiByteToWideChar 对其支持不佳，改用 TEncoding 路径
      var IsISO2022Variant := (SourceCodePage = 50220) or (SourceCodePage = 50221) or
                              (SourceCodePage = 50222) or (TargetCodePage = 50220) or
                              (TargetCodePage = 50221) or (TargetCodePage = 50222);
      if IsISO2022Variant then
      begin
        try
          ResultBuffer := ConvertViaTEncoding(SourceBuffer, SourceCodePage, TargetCodePage);
          _Trace(Format('[ConvertBuffer] ISO-2022 TEncoding path srcCP=%d tgtCP=%d outLen=%d',
            [SourceCodePage, TargetCodePage, Length(ResultBuffer)]));
        except
          on E: Exception do
          begin
            HandleConversionError(Result, ecetInvalidSequence, 0, 0, E.Message, Options.ErrorHandling);
            SetLength(ResultBuffer, 0);
          end;
        end;
      end
      else
      begin
      // 尝试使用快速路径进行转换（无第三方依赖）
      var UseFast := TEncodingHelper.TryConvertFast(
        SourceBuffer, SourceCodePage, TargetCodePage, ResultBuffer);
      _Trace(Format('[ConvertBuffer] TryConvertFast=%s srcLen=%d outLen=%d', [BoolToStr(UseFast, True), Length(SourceBuffer), Length(ResultBuffer)]));
      if not UseFast then
      begin
        // 快速路径失败，使用标准转换方法
        // 从源编码转换为Unicode
        try
          WideStr := StringToUnicodeString(PAnsiChar(@SourceBuffer[0]), SourceCodePage, Length(SourceBuffer));
          {$IFDEF DEBUG_CONVERT_TRACE}
          AppendToFile('tmp_tests\convert_trace.txt', Format('ConvertBuffer: SourceCodePage=%d, Length(SourceBuffer)=%d, WideStr=%s', [SourceCodePage, Length(SourceBuffer), WideStr]));
          {$ENDIF}
        except
          // 源缓冲区到 Unicode 解码失败，视为转换异常
          on E: EEncodingException do
          begin
            HandleConversionError(Result, ecetInvalidSequence, 0, 0, E.Message, Options.ErrorHandling);
            {$IFDEF DEBUG_CONVERT_TRACE}
            AppendToFile('tmp_tests\convert_trace.txt', Format('ConvertBuffer: Exception=%s', [E.Message]));
            {$ENDIF}

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
      end; // ISO-2022 else block
    end
    else
      SetLength(ResultBuffer, 0);

    // 添加BOM（如果需要）——基于目标代码页判断，避免依赖字符串比较
    if Options.AddBOM and (Length(ResultBuffer) > 0) then
    begin
      var BOMType: Integer := 0;

      case TargetCodePage of
        65001:  BOMType := 1;  // UTF-8
        1200:   BOMType := 2;  // UTF-16 LE
        1201:   BOMType := 3;  // UTF-16 BE
        12000:  BOMType := 4;  // UTF-32 LE
        12001:  BOMType := 5;  // UTF-32 BE
      else
        BOMType := 0;
      end;

      if BOMType <> 0 then
      begin
        ResultBuffer := TEncodingBOMDetector_Improved.AddBOM(ResultBuffer, BOMType);
        Result.HasBOM := True;
        _Trace(Format('[ConvertBuffer] AddBOM type=%d', [BOMType]));
      end;
    end;

    // 强保障：当目标编码为 UTF-8 with BOM 时，确保输出前缀包含 EF BB BF
    if (CompareText(TargetEncoding, ENCODING_UTF8_BOM) = 0) and (Length(ResultBuffer) > 0) then
    begin
      var NeedAdd := True;
      if Length(ResultBuffer) >= 3 then
        NeedAdd := not ((ResultBuffer[0] = $EF) and (ResultBuffer[1] = $BB) and (ResultBuffer[2] = $BF));
      if NeedAdd then
      begin
        ResultBuffer := TEncodingBOMDetector_Improved.AddBOM(ResultBuffer, 1);
        Result.HasBOM := True;
      end
      else
        Result.HasBOM := True;
    end;

    // 使用统一 BOM 清理器规范化 UTF-8 / UTF-8-BOM 输出
    if (CompareText(TargetEncoding, ENCODING_UTF8) = 0) and (Length(ResultBuffer) > 0) then
    begin
      ResultBuffer := TBOMCleaner.CleanUTF8Artifacts(ResultBuffer, False);
      Result.HasBOM := False;
    end
    else if (CompareText(TargetEncoding, ENCODING_UTF8_BOM) = 0) and (Length(ResultBuffer) > 0) then
    begin
      ResultBuffer := TBOMCleaner.CleanUTF8Artifacts(ResultBuffer, True);
      Result.HasBOM := True;
    end;

    // 设置转换结果
    Result.Success := True;
    Result.BytesProcessed := Length(ResultBuffer);
    Result.OutputData := ResultBuffer;
    _Trace(Format('[ConvertBuffer] end outLen=%d', [Length(ResultBuffer)]));
  except
    on E: Exception do
    begin
      Result.Success := False;
      AddError(Result, ecetUnknownError, 0, 0, E.Message);
      _Trace('[ConvertBuffer] exception: ' + E.Message);
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
  FileAttrsSet: TFileAttributes;
begin
  // 初始化结果
  Result.Success := False;
  Result.SourceEncoding := SourceEncoding;
  Result.TargetEncoding := TargetEncoding;
  Result.BytesProcessed := 0;
  Result.ErrorCount := 0;
  SetLength(Result.Errors, 0);
  Result.HasBOM := False;
  MaxRetry := 5; // 增加最大重试次数

  // P0-3: 路径安全验证
  if not TPathSecurityValidator.IsPathSafe(SourceFileName) then
  begin
    AddError(Result, ecetIOError, 0, 0, '源文件路径不安全');
    Exit;
  end;

  if not TPathSecurityValidator.IsPathSafe(TargetFileName) then
  begin
    AddError(Result, ecetIOError, 0, 0, '目标文件路径不安全');
    Exit;
  end;

  // 检查源文件是否存在
  if not FileExists(SourceFileName) then
  begin
    AddError(Result, ecetIOError, 0, 0, '源文件不存在');
    Exit;
  end;

  // Bug #11 修复：直接在目标目录生成临时文件，避免跨卷重命名问题
  TempFileName := TTempFileSecurityManager.GetSecureTempFileInDir(ExtractFilePath(TargetFileName));
  TTempFileSecurityManager.RegisterTempFile(TempFileName);

  try
    // 检测源文件编??
    if (SourceEncoding = '') or Options.DetectSourceEncoding then
      ActualSourceEncoding := DetectFileEncoding(SourceFileName)
    else
      ActualSourceEncoding := SourceEncoding;

    Result.SourceEncoding := ActualSourceEncoding;

    // 读取源文件内容（读取完整文件，避免截断）
    try
      SourceStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyNone);
      try
        // 读取整个文件
        var ReadSize := SourceStream.Size;
        SetLength(Buffer, ReadSize);
        if ReadSize > 0 then
          SourceStream.ReadBuffer(Buffer[0], ReadSize);
      finally
        SourceStream.Free;
      end;
    except
      on E: EEncodingException do
      begin
        AddError(Result, ecetIOError, 0, 0, '无法读取源文件: ' + string(E.Message));
        Exit;
      end;
      on E: Exception do
      begin
        AddError(Result, ecetIOError, 0, 0, '无法读取源文件: ' + string(E.Message));
        Exit;
      end;
    end;

    // 转换缓冲区
    _Trace(Format('[ConvertStream] read src bytes=%d', [Length(Buffer)]));
    Result := ConvertBuffer(Buffer, ActualSourceEncoding, TargetEncoding, Options);
    _Trace(Format('[ConvertStream] ConvertBuffer success=%s outLen=%d', [BoolToStr(Result.Success, True), Length(Result.OutputData)]));

    // 检查转换是否成功
    if not Result.Success then
      Exit;

    // 直接使用 ConvertBuffer 返回的转换结果
    OutputBuffer := Result.OutputData;


    // 【关键修复】仅当源非空而输出为空时阻止写入，避免丢失数据；允许空文件
    if (Length(Buffer) > 0) and (Length(OutputBuffer) = 0) then
    begin
      AddError(Result, ecetUnknownError, 0, 0, '转换后的数据为空，拒绝写入文件以防止数据丢失');
      Result.Success := False;
      Exit;
    end;

    // 保存文件属性（使用跨平台 API）
    try
      FileAttrsSet := TFile.GetAttributes(SourceFileName);
    except
      // 忽略获取文件属性的错误
    end;

    // 写入临时文件
    try
      // 使用完全独立的方法写入文??
      TFile.WriteAllBytes(TempFileName, OutputBuffer);
    except
      on E: Exception do
      begin
        AddError(Result, ecetIOError, 0, 0, '写入临时文件失败: ' + E.Message);
        Exit;
      end;
    end;

    // 尝试多次替换原文??
    RetryCount := 0;
    Success := False;

    repeat
      Inc(RetryCount);

      try
        // 如果目标文件存在且与源文件不同，先尝试删??
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

        // 【关键修复】如果源文件和目标文件相同，使用更安全的替换策略
        if SourceFileName = TargetFileName then
        begin
          // 创建备份文件名（使用时间戳确保唯一性）
          var BackupFileName := ChangeFileExt(SourceFileName, '.backup_' + FormatDateTime('hhnnsszzz', Now));
          
          // 先将源文件重命名为备份文件
          if FileExists(SourceFileName) then
          begin
            // 先尝试修改文件属性为普通文件
            try
              if TFileAttribute.faReadOnly in FileAttrsSet then
              begin
                var NewAttrs := FileAttrsSet - [TFileAttribute.faReadOnly];
                TFile.SetAttributes(SourceFileName, NewAttrs);
              end;
            except
              // 忽略修改属性的错误
            end;

            // 重命名源文件为备份文件
            if not RenameFile(SourceFileName, BackupFileName) then
            begin
              ErrCode := GetLastError;

              // 如果是文件被占用错误，等待后重试
              if (ErrCode = ERROR_SHARING_VIOLATION) or (ErrCode = ERROR_ACCESS_DENIED) then
              begin
                if RetryCount < MaxRetry then
                begin
                  Sleep(500 * RetryCount);
                  Continue;
                end;
              end;

              // 无法重命名源文件
              AddError(Result, ecetIOError, 0, 0, Format('无法重命名源文件为备份文件，错误码: %d', [ErrCode]));
              Result.Success := False;
              Exit;
            end;
          end;

          // 重命名临时文件为目标文件
          if RenameFile(TempFileName, TargetFileName) then
          begin
            Success := True;
            Result.Success := True;
            
            // 成功后删除备份文件
            if FileExists(BackupFileName) then
            begin
              try
                DeleteFile(PChar(BackupFileName));
              except
                // 忽略删除备份文件的错误
              end;
            end;
            
            Break;
          end
          else
          begin
            // 重命名失败，尝试恢复备份文件
            ErrCode := GetLastError;
            
            if FileExists(BackupFileName) then
            begin
              try
                // 恢复原文件
                RenameFile(BackupFileName, SourceFileName);
                AddError(Result, ecetIOError, 0, 0, Format('重命名临时文件失败，已恢复原文件，错误码: %d', [ErrCode]));
              except
                on E: Exception do
                  AddError(Result, ecetIOError, 0, 0, Format('重命名临时文件失败且无法恢复原文件: %s', [string(E.Message)]));
              end;
            end
            else
            begin
              AddError(Result, ecetIOError, 0, 0, Format('重命名临时文件失败，错误码: %d', [ErrCode]));
            end;
            
            Result.Success := False;
            Exit;
          end;
        end
        else
        begin
          // 源文件和目标文件不同，直接重命名临时文件
          if RenameFile(TempFileName, TargetFileName) then
          begin
            Success := True;
            Result.Success := True;
            Break;
          end;
        end;
        
        // 如果重命名失败（针对不同文件的情况）
        if not Success then
        begin
          ErrCode := GetLastError;

          // 如果是文件被占用错误，等待后重试
          if (ErrCode = ERROR_SHARING_VIOLATION) or (ErrCode = ERROR_ACCESS_DENIED) then
          begin
            if RetryCount < MaxRetry then
            begin
              Sleep(500 * RetryCount);
              Continue;
            end;
          end;

          // 达到最大重试次数或其他错误
          AddError(Result, ecetIOError, 0, 0, Format('无法重命名临时文件，错误码: %d', [ErrCode]));
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
            AddError(Result, ecetIOError, 0, 0, '替换文件时发生异?? ' + string(E.Message));
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

    // 尝试恢复文件属性
    try
      TFile.SetAttributes(TargetFileName, FileAttrsSet);
    except
      // 忽略设置文件属性的错误
    end;
  except
    on E: EEncodingException do
    begin
      Result.Success := False;
      AddError(Result, ecetUnknownError, 0, 0, E.Message);
    end;
    on E: Exception do
    begin
      Result.Success := False;
      AddError(Result, ecetUnknownError, 0, 0, E.Message);
    end;
  end;

  // 确保临时文件被安全删除并从注册表中移除
  if TempFileName <> '' then
  begin
    if FileExists(TempFileName) then
      TTempFileSecurityManager.SecureDeleteFile(TempFileName);
    TTempFileSecurityManager.UnregisterTempFile(TempFileName);
  end;
end;

class function TEncodingConverter_Improved.ConvertStream(const SourceStream, TargetStream: TStream; const SourceEncoding, TargetEncoding: string; const Options: TEncodingConversionOptions): TEncodingConversionResult;
var
  Buffer: TBytes;
  Position: Int64;
  ActualSourceEncoding: string;
  BOMResult: TBOMDetectionResult;
begin
  // 初始化结??
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

  // 保存当前流位??
  Position := SourceStream.Position;

  try
    // 检测源流编??
    if (SourceEncoding = '') or Options.DetectSourceEncoding then
    begin
      // 重置流位??
      SourceStream.Position := 0;

      // 检测BOM
      BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromStream(SourceStream);

      if BOMResult.BOMType <> 0 then
      begin
        // 显式转换
        ActualSourceEncoding := string(BOMResult.Encoding);
        Result.HasBOM := True;
      end
      else
      begin
        // 读取流内容进行分??
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
          // 检测中文编??
          var ChineseResult := TChineseEncodingDetector_Improved.DetectBuffer(Buffer);
          // 显式转换
          ActualSourceEncoding := string(ChineseResult.Encoding);
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

    // 保护：仅当源非空而输出为空时，判定为异常，防止静默丢失
    if (Length(Buffer) > 0) and (Length(Result.OutputData) = 0) then
    begin
      AddError(Result, ecetUnknownError, 0, 0, '流转换后的数据为空，已阻止写入以避免数据丢失');
      Result.Success := False;
      Exit;
    end;

    // 写入目标流（允许空流场景下写入空内容）
    if Result.Success then
    begin
      TargetStream.Position := 0;
      TargetStream.Size := 0;
      if Length(Result.OutputData) > 0 then
        TargetStream.WriteBuffer(Result.OutputData[0], Length(Result.OutputData));
    end;
  finally
    // 恢复流位??
    SourceStream.Position := Position;
  end;
  _Trace('[ConvertStream] end');
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
    // 显式转换，避免隐式 AnsiString -> string 告警
    Result := string(BOMResult.Encoding)
  else
  begin
    // 检测UTF-8
    UTF8Result := TUTF8EncodingDetector_Improved.DetectFile(FileName);

    if UTF8Result.IsUTF8 then
      Result := ENCODING_UTF8
    else
    begin
      // 检测中文编??
      ChineseResult := TChineseEncodingDetector_Improved.DetectFile(FileName);
      // 显式转换
      Result := string(ChineseResult.Encoding);
    end;
  end;
end;

class function TEncodingConverter_Improved.GetCodePage(const EncodingName: string): Integer;
var
  NameU: string;
  Num: Integer;
  i: Integer;
  CachedResult: Integer;
  Found: Boolean;
begin
  CachedResult := 0;
  Found := False;
  NameU := Trim(EncodingName);
  if NameU = '' then
    Exit(GetACP());

  // 线程安全：在读取缓存时加锁
  CodePageCacheLock.Enter;
  try
    // 查找缓存
    Found := False;
    for i := 0 to CodePageCacheCount - 1 do
      if SameText(CodePageCache[i].Name, NameU) then
      begin
        CachedResult := CodePageCache[i].CodePage;
        Found := True;
        Break;
      end;
  finally
    CodePageCacheLock.Leave;
  end;

  if Found then
    Exit(CachedResult);

  // 兼容 'CPxxxx' 形式
  if (Length(NameU) > 2) and SameText(Copy(NameU, 1, 2), 'CP') then
  begin
    if TryStrToInt(Copy(NameU, 3, MaxInt), Num) then
      Exit(Num);
  end;

  if CompareText(NameU, ENCODING_UTF8) = 0 then
    Result := 65001
  else if CompareText(NameU, ENCODING_UTF8_BOM) = 0 then
    Result := 65001
  else if CompareText(NameU, ENCODING_UTF16_LE) = 0 then
    Result := 1200
  else if CompareText(NameU, ENCODING_UTF16_BE) = 0 then
    Result := 1201
  else if CompareText(NameU, ENCODING_UTF32_LE) = 0 then
    Result := 12000
  else if CompareText(NameU, ENCODING_UTF32_BE) = 0 then
    Result := 12001
  else if CompareText(NameU, ENCODING_GBK) = 0 then
    Result := 936
  else if CompareText(NameU, ENCODING_GB18030) = 0 then
    Result := 54936
  else if CompareText(NameU, ENCODING_GB2312) = 0 then
    Result := 936
  else if CompareText(NameU, ENCODING_BIG5) = 0 then
    Result := 950
  else if CompareText(NameU, ENCODING_SHIFT_JIS) = 0 then
    Result := 932
  else if CompareText(NameU, ENCODING_EUC_JP) = 0 then
    Result := 20932
  else if CompareText(NameU, ENCODING_EUC_KR) = 0 then
    Result := 51949
  else if CompareText(NameU, ENCODING_ANSI) = 0 then
    Result := GetACP()
  else if TryStrToInt(NameU, Num) then
    Result := Num
  else
    // 统一回退到 UtilsTypes.GetEncodingCodePage 处理更多别名
    Result := UtilsTypes.GetEncodingCodePage(NameU);

  // 线程安全：在写入缓存时加锁
  if (Result <> 0) and (CodePageCacheCount < Length(CodePageCache)) then
  begin
    CodePageCacheLock.Enter;
    try
      // 双重检查：避免多线程重复添加
      Found := False;
      for i := 0 to CodePageCacheCount - 1 do
        if SameText(CodePageCache[i].Name, NameU) then
        begin
          Found := True;
          Break;
        end;
      
      if not Found and (CodePageCacheCount < Length(CodePageCache)) then
      begin
        CodePageCache[CodePageCacheCount].Name := NameU;
        CodePageCache[CodePageCacheCount].CodePage := Result;
        Inc(CodePageCacheCount);
      end;
    finally
      CodePageCacheLock.Leave;
    end;
  end;
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

  // 检查文件是否存??
  if not FileExists(FileName) then
    Exit;

  // 尝试以读写模式打开文件
  FileMode := GENERIC_READ or GENERIC_WRITE;
  FileHandle := CreateFile(
    PChar(FileName),
    FileMode,
    0, // 不共??
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
        // 文件可以以只读模式打开，需要使用临时文??
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

  // 检查文件是否存??
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

        // 读取文件内容（跳过BOM??
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
          // 比较内容（忽略BOM??
          Result := (Length(SourceBuffer) = Length(TargetBuffer));

          if Result and (Length(SourceBuffer) > 0) then
            Result := CompareMem(@SourceBuffer[0], @TargetBuffer[0], Length(SourceBuffer));
        end
        else
        begin
          // 如果编码不同，则需要转换后比较
          // 这里简化处理，只检查文件大小是否合??
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

class function TEncodingConverter_Improved.ValidateConversionIntegrity(
  const SourceBuffer: TBytes;
  const SourceEncoding: string;
  const ConversionResult: TEncodingConversionResult): Boolean;
var
  EffectiveSourceEncoding: string;
  SourceChars, TargetChars: UnicodeString;
  SrcBOM, OutBOM: TBOMDetectionResult;
  SrcPayload, OutPayload: TBytes;

  function IsValidUTF8Payload(const Buf: TBytes): Boolean;
  var
    WideLen: Integer;
  begin
    if Length(Buf) = 0 then
      Exit(True);
    WideLen := MultiByteToWideChar(65001, MB_ERR_INVALID_CHARS,
      PAnsiChar(@Buf[0]), Length(Buf), nil, 0);
    Result := WideLen > 0;
  end;
begin
  Result := False;

  // 仅在转换成功时才进行完整性验证
  if not ConversionResult.Success then
    Exit;

  // 空输入/输出视为通过（例如空文件转换）
  if (Length(SourceBuffer) = 0) and (Length(ConversionResult.OutputData) = 0) then
  begin
    Result := True;
    Exit;
  end;

  // 如果调用方未提供 SourceEncoding，则回退到 ConversionResult.SourceEncoding
  if SourceEncoding <> '' then
    EffectiveSourceEncoding := SourceEncoding
  else
    EffectiveSourceEncoding := ConversionResult.SourceEncoding;

  // 1. 字符数量验证（基于解码到 Unicode 的字符数，忽略前导 BOM）
  try
    // 源缓冲区：去除前导 BOM 后再解码
    SrcBOM := TEncodingBOMDetector_Improved.DetectBOM(SourceBuffer);
    if SrcBOM.BOMType <> 0 then
    begin
      SetLength(SrcPayload, Length(SourceBuffer) - SrcBOM.BOMLength);
      if Length(SrcPayload) > 0 then
        Move(SourceBuffer[SrcBOM.BOMLength], SrcPayload[0], Length(SrcPayload));
    end
    else
      SrcPayload := SourceBuffer;

    // 目标缓冲区：同样忽略前导 BOM
    OutBOM := TEncodingBOMDetector_Improved.DetectBOM(ConversionResult.OutputData);
    if OutBOM.BOMType <> 0 then
    begin
      SetLength(OutPayload, Length(ConversionResult.OutputData) - OutBOM.BOMLength);
      if Length(OutPayload) > 0 then
        Move(ConversionResult.OutputData[OutBOM.BOMLength], OutPayload[0], Length(OutPayload));
    end
    else
      OutPayload := ConversionResult.OutputData;

    SourceChars := DecodeBufferToUnicode(SrcPayload, EffectiveSourceEncoding);
    TargetChars := DecodeBufferToUnicode(OutPayload, ConversionResult.TargetEncoding);
  except
    // 解码异常视为完整性失败
    Exit;
  end;

  // 如果缓冲区非空但解码结果为空，也视为失败
  if (Length(SourceBuffer) > 0) and (SourceChars = '') then
    Exit;
  if (Length(ConversionResult.OutputData) > 0) and (TargetChars = '') then
    Exit;

  // 严格 UTF-8 验证：如果源是 UTF-8（含 BOM 变体），使用 Windows API 检查是否存在非法序列
  if GetCodePage(EffectiveSourceEncoding) = 65001 then
  begin
    if not IsValidUTF8Payload(SrcPayload) then
      Exit(False);
  end;

  if (SourceChars <> '') and (TargetChars <> '') then
  begin
    if Length(SourceChars) <> Length(TargetChars) then
      Exit(False);
    if SourceChars <> TargetChars then
      Exit(False);
  end;

  Result := True;
end;

class function TEncodingConverter_Improved.ConvertFileStreaming(
  const SourceFileName, TargetFileName: string;
  const SourceEncoding, TargetEncoding: string;
  const Options: TEncodingConversionOptions;
  const ProgressCallback: TStreamingProgressCallback): TEncodingConversionResult;
const
  CHUNK_SIZE = 64 * 1024;  // 64KB 块大小
  MAX_LOOKAHEAD = 6;       // 多字节字符最大回看字节数（UTF-8最多6字节，实际为4）
var
  SourceStream: TFileStream;
  TargetStream: TFileStream;
  Buffer, ChunkOutput, Remainder: TBytes;
  TempFileName: string;
  ActualSourceEncoding: string;
  TotalSize, TotalProcessed: Int64;
  ChunkSize, ActualRead: Integer;
  Cancel: Boolean;
  SourceCodePage, TargetCodePage: Integer;
  WideStr: UnicodeString;
  BOMWritten: Boolean;
  FileAttrsSet: TFileAttributes;
  i, SplitPos: Integer;
begin
  // 初始化结果
  Result.Success := False;
  Result.SourceEncoding := SourceEncoding;
  Result.TargetEncoding := TargetEncoding;
  Result.BytesProcessed := 0;
  Result.ErrorCount := 0;
  SetLength(Result.Errors, 0);
  Result.HasBOM := False;
  SetLength(Result.OutputData, 0);  // 流式处理不返回完整输出
  Cancel := False;
  BOMWritten := False;
  SetLength(Remainder, 0);

  // 路径安全验证
  if not TPathSecurityValidator.IsPathSafe(SourceFileName) then
  begin
    AddError(Result, ecetIOError, 0, 0, '源文件路径不安全');
    Exit;
  end;

  if not TPathSecurityValidator.IsPathSafe(TargetFileName) then
  begin
    AddError(Result, ecetIOError, 0, 0, '目标文件路径不安全');
    Exit;
  end;

  // 检查源文件是否存在
  if not FileExists(SourceFileName) then
  begin
    AddError(Result, ecetIOError, 0, 0, '源文件不存在');
    Exit;
  end;

  // Bug #11 修复：直接在目标目录生成临时文件，避免跨卷重命名问题
  TempFileName := TTempFileSecurityManager.GetSecureTempFileInDir(ExtractFilePath(TargetFileName));
  TTempFileSecurityManager.RegisterTempFile(TempFileName);

  try
    // 检测源文件编码（仅读取文件头部）
    if (SourceEncoding = '') or Options.DetectSourceEncoding then
      ActualSourceEncoding := DetectFileEncoding(SourceFileName)
    else
      ActualSourceEncoding := SourceEncoding;

    Result.SourceEncoding := ActualSourceEncoding;
    SourceCodePage := GetCodePage(ActualSourceEncoding);
    TargetCodePage := GetCodePage(TargetEncoding);

    // 保存源文件属性
    try
      FileAttrsSet := TFile.GetAttributes(SourceFileName);
    except
      // 忽略获取文件属性的错误
    end;

    // 打开源文件
    try
      SourceStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyNone);
    except
      on E: Exception do
      begin
        AddError(Result, ecetIOError, 0, 0, '无法打开源文件: ' + E.Message);
        Exit;
      end;
    end;

    try
      TotalSize := SourceStream.Size;
      TotalProcessed := 0;

      // 跳过源文件的 BOM
      var SrcBOM := TEncodingBOMDetector_Improved.DetectBOMFromStream(SourceStream);
      if SrcBOM.BOMType <> 0 then
      begin
        SourceStream.Position := SrcBOM.BOMLength;
        Result.HasBOM := True;
      end;

      // 创建目标临时文件
      try
        TargetStream := TFileStream.Create(TempFileName, fmCreate or fmShareDenyWrite);
      except
        on E: Exception do
        begin
          AddError(Result, ecetIOError, 0, 0, '无法创建临时文件: ' + E.Message);
          Exit;
        end;
      end;

      try
        // 写入目标 BOM（如果需要）
        if Options.AddBOM then
        begin
          var TargetBOMType := 0;
          var TargetCP := GetCodePage(TargetEncoding);
          // 根据目标编码确定 BOM 类型
          if TargetCP = CP_UTF8 then TargetBOMType := 1      // UTF-8
          else if TargetCP = 1200 then TargetBOMType := 2    // UTF-16 LE
          else if TargetCP = 1201 then TargetBOMType := 3    // UTF-16 BE
          else if TargetCP = 12000 then TargetBOMType := 4   // UTF-32 LE
          else if TargetCP = 12001 then TargetBOMType := 5;  // UTF-32 BE
          
          if TargetBOMType > 0 then
          begin
            var TargetBOM := TEncodingBOMDetector_Improved.GetBOMBytes(TargetBOMType);
            if Length(TargetBOM) > 0 then
            begin
              TargetStream.WriteBuffer(TargetBOM[0], Length(TargetBOM));
              BOMWritten := True;
            end;
          end;
        end;

        // 分块读取和转换
        SetLength(Buffer, CHUNK_SIZE + MAX_LOOKAHEAD);

        while SourceStream.Position < TotalSize do
        begin
          // 检查取消
          if Cancel then
          begin
            AddError(Result, ecetUnknownError, TotalProcessed, 0, '用户取消转换');
            Result.Success := False;
            Exit;
          end;

          // 计算本次读取大小
          ChunkSize := Min(CHUNK_SIZE, TotalSize - SourceStream.Position);
          
          // 读取数据块
          ActualRead := SourceStream.Read(Buffer[Length(Remainder)], ChunkSize);
          if ActualRead <= 0 then
            Break;

          // 合并上次剩余的不完整字节
          if Length(Remainder) > 0 then
          begin
            Move(Buffer[Length(Remainder)], Buffer[Length(Remainder)], ActualRead);
            Move(Remainder[0], Buffer[0], Length(Remainder));
            ActualRead := ActualRead + Length(Remainder);
            SetLength(Remainder, 0);
          end;

          // 查找安全的分割点（避免截断多字节字符）
          SplitPos := ActualRead;
          if (SourceStream.Position < TotalSize) and (SourceCodePage = CP_UTF8) then
          begin
            // UTF-8: 从末尾向前找到完整字符边界
            for i := ActualRead - 1 downto Max(0, ActualRead - MAX_LOOKAHEAD) do
            begin
              // UTF-8 continuation byte: 10xxxxxx
              if (Buffer[i] and $C0) <> $80 then
              begin
                // 检查是否是多字节序列的开始
                if Buffer[i] >= $80 then
                begin
                  var ExpectedLen := 1;
                  if (Buffer[i] and $E0) = $C0 then ExpectedLen := 2
                  else if (Buffer[i] and $F0) = $E0 then ExpectedLen := 3
                  else if (Buffer[i] and $F8) = $F0 then ExpectedLen := 4;
                  
                  // 如果序列不完整，在此处分割
                  if i + ExpectedLen > ActualRead then
                  begin
                    SplitPos := i;
                    Break;
                  end;
                end;
                Break;
              end;
            end;
          end
          else if (SourceStream.Position < TotalSize) and ((SourceCodePage = 936) or (SourceCodePage = 950)) then
          begin
            // GBK/Big5: 双字节编码，检查最后一个字节是否是高字节
            if (ActualRead > 0) and (Buffer[ActualRead - 1] >= $81) then
              SplitPos := ActualRead - 1;
          end;

          // 保存剩余的不完整字节
          if SplitPos < ActualRead then
          begin
            SetLength(Remainder, ActualRead - SplitPos);
            Move(Buffer[SplitPos], Remainder[0], Length(Remainder));
            ActualRead := SplitPos;
          end;

          // 转换当前块
          if ActualRead > 0 then
          begin
            SetLength(ChunkOutput, 0);
            
            // 解码为 Unicode
            if SourceCodePage = CP_UTF8 then
              WideStr := TEncodingHelper.UTF8ToUnicode(Copy(Buffer, 0, ActualRead))
            else if SourceCodePage = 1200 then
            begin
              SetLength(WideStr, ActualRead div 2);
              if Length(WideStr) > 0 then
                Move(Buffer[0], WideStr[1], ActualRead);
            end
            else
              WideStr := TEncodingHelper.AnsiToUnicode(Copy(Buffer, 0, ActualRead), SourceCodePage);

            // 编码为目标格式
            if TargetCodePage = CP_UTF8 then
              ChunkOutput := TEncodingHelper.UnicodeToUTF8(WideStr)
            else if TargetCodePage = 1200 then
            begin
              SetLength(ChunkOutput, Length(WideStr) * 2);
              if Length(WideStr) > 0 then
                Move(WideStr[1], ChunkOutput[0], Length(ChunkOutput));
            end
            else
              ChunkOutput := TEncodingHelper.UnicodeToAnsi(WideStr, TargetCodePage);

            // 写入目标文件
            if Length(ChunkOutput) > 0 then
              TargetStream.WriteBuffer(ChunkOutput[0], Length(ChunkOutput));

            TotalProcessed := TotalProcessed + ActualRead;
          end;

          // 进度回调
          if Assigned(ProgressCallback) then
            ProgressCallback(TotalProcessed, TotalSize, Cancel);
        end;

        // 处理最后剩余的字节
        if Length(Remainder) > 0 then
        begin
          if SourceCodePage = CP_UTF8 then
            WideStr := TEncodingHelper.UTF8ToUnicode(Remainder)
          else
            WideStr := TEncodingHelper.AnsiToUnicode(Remainder, SourceCodePage);

          if TargetCodePage = CP_UTF8 then
            ChunkOutput := TEncodingHelper.UnicodeToUTF8(WideStr)
          else if TargetCodePage = 1200 then
          begin
            SetLength(ChunkOutput, Length(WideStr) * 2);
            if Length(WideStr) > 0 then
              Move(WideStr[1], ChunkOutput[0], Length(ChunkOutput));
          end
          else
            ChunkOutput := TEncodingHelper.UnicodeToAnsi(WideStr, TargetCodePage);

          if Length(ChunkOutput) > 0 then
            TargetStream.WriteBuffer(ChunkOutput[0], Length(ChunkOutput));

          TotalProcessed := TotalProcessed + Length(Remainder);
        end;

      finally
        TargetStream.Free;
      end;

    finally
      SourceStream.Free;
    end;

    // 替换目标文件
    if SourceFileName = TargetFileName then
    begin
      // 同文件替换：先删除源文件，再重命名临时文件
      try
        if TFileAttribute.faReadOnly in FileAttrsSet then
          TFile.SetAttributes(SourceFileName, FileAttrsSet - [TFileAttribute.faReadOnly]);
      except
      end;

      if not DeleteFile(PChar(SourceFileName)) then
      begin
        AddError(Result, ecetIOError, 0, 0, '无法删除源文件');
        Exit;
      end;

      if not RenameFile(TempFileName, TargetFileName) then
      begin
        AddError(Result, ecetIOError, 0, 0, '无法重命名临时文件');
        Exit;
      end;
    end
    else
    begin
      // 不同文件：删除已存在的目标文件，重命名临时文件
      if FileExists(TargetFileName) then
      begin
        if not DeleteFile(PChar(TargetFileName)) then
        begin
          AddError(Result, ecetIOError, 0, 0, '无法删除目标文件');
          Exit;
        end;
      end;

      if not RenameFile(TempFileName, TargetFileName) then
      begin
        AddError(Result, ecetIOError, 0, 0, '无法重命名临时文件');
        Exit;
      end;
    end;

    TTempFileSecurityManager.UnregisterTempFile(TempFileName);
    Result.Success := True;
    Result.BytesProcessed := TotalProcessed;
    Result.TargetEncoding := TargetEncoding;

  except
    on E: Exception do
    begin
      AddError(Result, ecetUnknownError, 0, 0, '流式转换失败: ' + E.Message);
    end;
  end;

  // 清理临时文件
  if FileExists(TempFileName) then
  begin
    TTempFileSecurityManager.SecureDeleteFile(TempFileName);
    TTempFileSecurityManager.UnregisterTempFile(TempFileName);
  end;
end;

initialization
  // 线程安全：初始化代码页缓存锁
  CodePageCacheLock := TCriticalSection.Create;

finalization
  // 线程安全：释放代码页缓存锁
  if Assigned(CodePageCacheLock) then
    FreeAndNil(CodePageCacheLock);

end.
