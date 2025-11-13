unit EncodingConverter_Improved;

interface

uses
  System.SysUtils, System.Classes, System.Math, Winapi.Windows, System.IOUtils, UtilsTypes,
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

    // TODO: 实现编码转换结果完整性校验
    {$MESSAGE HINT '待实现: ValidateConversionIntegrity'}
    (*
    /// <summary>
    /// 验证编码转换结果的完整性（内容校验）
    /// </summary>
    class function ValidateConversionIntegrity(
      const SourceBuffer: TBytes;
      const SourceEncoding: string;
      const ConversionResult: TEncodingConversionResult): Boolean;
    *)
  end;

implementation

{$WARN IMPLICIT_STRING_CAST OFF}

const
  DEBUG_CONVERT_TRACE: Boolean = False;

var
  CodePageCache: array[0..31] of record
    Name: string;
    CodePage: Integer;
  end;
  CodePageCacheCount: Integer = 0;

function _TraceFilePath: string;
begin
  // 写入到与自测一致的 tmp_tests 目录，便于统一查看
  var Root := ExtractFilePath(ParamStr(0));
  var Dir := TPath.Combine(Root, '..\tmp_tests');
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
begin
  // 初始化结�?
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
          // 检测中文编�?
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

    // 快速路径：源编码和目标编码相同，且不需要添加 BOM
    // 对于 UTF-8/UTF-8 with BOM，不能直接透传，仍需执行内嵌 BOM 清理/规范化
    var IsUTF8Family := (SourceCodePage = 65001) or (TargetCodePage = 65001);
    if (SourceCodePage = TargetCodePage) and not Options.AddBOM and not IsUTF8Family then
    begin
      ResultBuffer := Buffer;

      // 目标为 UTF-8（无 BOM）：移除所有位置的 EF BB BF
      if (CompareText(TargetEncoding, ENCODING_UTF8) = 0) then
      begin
        var j := 0;
        while j <= Length(ResultBuffer) - 3 do
        begin
          if (ResultBuffer[j] = $EF) and (ResultBuffer[j+1] = $BB) and (ResultBuffer[j+2] = $BF) then
          begin
            var Tail := Length(ResultBuffer) - (j + 3);
            if Tail > 0 then
              System.Move(ResultBuffer[j+3], ResultBuffer[j], Tail);
            SetLength(ResultBuffer, Length(ResultBuffer) - 3);
            Continue;
          end;
          Inc(j);
        end;

        // 同时移除被误作 ANSI 后再转 UTF-8 的 6 字节序列：C3 AF C2 BB C2 BF（对应 "ï»¿"）
        j := 0;
        while j <= Length(ResultBuffer) - 6 do
        begin
          if (ResultBuffer[j] = $C3) and (ResultBuffer[j+1] = $AF) and
             (ResultBuffer[j+2] = $C2) and (ResultBuffer[j+3] = $BB) and
             (ResultBuffer[j+4] = $C2) and (ResultBuffer[j+5] = $BF) then
          begin
            var Tail6 := Length(ResultBuffer) - (j + 6);
            if Tail6 > 0 then
              System.Move(ResultBuffer[j+6], ResultBuffer[j], Tail6);
            SetLength(ResultBuffer, Length(ResultBuffer) - 6);
            Continue;
          end;
          Inc(j);
        end;
      end
      // 目标为 UTF-8 with BOM：确保仅首部一个 BOM，清理内部 BOM
      else if (CompareText(TargetEncoding, ENCODING_UTF8_BOM) = 0) then
      begin
        // 确保首部有 BOM
        var Leading := (Length(ResultBuffer) >= 3) and (ResultBuffer[0]=$EF) and (ResultBuffer[1]=$BB) and (ResultBuffer[2]=$BF);
        if not Leading then
          ResultBuffer := TEncodingBOMDetector_Improved.AddBOM(ResultBuffer, 1);
        // 清除内部 BOM
        var i := 3;
        while i <= Length(ResultBuffer) - 3 do
        begin
          if (ResultBuffer[i] = $EF) and (ResultBuffer[i+1] = $BB) and (ResultBuffer[i+2] = $BF) then
          begin
            var Tail := Length(ResultBuffer) - (i + 3);
            if Tail > 0 then
              System.Move(ResultBuffer[i+3], ResultBuffer[i], Tail);
            SetLength(ResultBuffer, Length(ResultBuffer) - 3);
            Continue;
          end;
          Inc(i);
        end;
        Result.HasBOM := True;
      end;

      // 同时清除内部的 6 字节序列 C3 AF C2 BB C2 BF（从索引3开始）
      var i6 := 3;
      while i6 <= Length(ResultBuffer) - 6 do
      begin
        if (ResultBuffer[i6] = $C3) and (ResultBuffer[i6+1] = $AF) and
           (ResultBuffer[i6+2] = $C2) and (ResultBuffer[i6+3] = $BB) and
           (ResultBuffer[i6+4] = $C2) and (ResultBuffer[i6+5] = $BF) then
        begin
          var Tail6 := Length(ResultBuffer) - (i6 + 6);
          if Tail6 > 0 then
            System.Move(ResultBuffer[i6+6], ResultBuffer[i6], Tail6);
          SetLength(ResultBuffer, Length(ResultBuffer) - 6);
          Continue;
        end;
        Inc(i6);
      end;

      Result.Success := True;
      Result.BytesProcessed := Length(ResultBuffer);
      Result.OutputData := ResultBuffer;
      _Trace(Format('[ConvertBuffer] same-codepage normalized, outLen=%d', [Length(ResultBuffer)]));
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
        _Trace('[ConvertBuffer] Fast path: same codepage, direct copy (non-UTF8)');
        Result.OutputData := Copy(Buffer);
        Result.Success := True;
        Result.BytesProcessed := Length(Buffer);
        Exit;
      end;
    end
    else if (SourceCodePage = TargetCodePage) and not Options.AddBOM and IsUTF8Family then
    begin
      _Trace('[ConvertBuffer] UTF-8 same codepage: apply cleaning');
      // UTF-8 同编码仍需清理内嵌 BOM
      var BufferWithoutBOM := TEncodingBOMDetector_Improved.RemoveBOM(Buffer);
      Result.OutputData := BufferWithoutBOM;
      Exit;
    end;

    // 准备源缓冲区，跳过BOM（如果有）
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
          on E: Exception do
          begin
            // 记录错误但继续处理
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

    // 规范化：当目标为 UTF-8 with BOM，确保BOM只出现在文件开头，移除其它位置的BOM（例如被错误插入到第一个字符之后）
    if (CompareText(TargetEncoding, ENCODING_UTF8_BOM) = 0) and (Length(ResultBuffer) > 0) then
    begin
      // 确保开头存在BOM
      var HasLeadingBOM := (Length(ResultBuffer) >= 3) and
                           (ResultBuffer[0] = $EF) and (ResultBuffer[1] = $BB) and (ResultBuffer[2] = $BF);
      if not HasLeadingBOM then
      begin
        ResultBuffer := TEncodingBOMDetector_Improved.AddBOM(ResultBuffer, 1);
      end;

      // 移除除开头外的任何 UTF-8 BOM 片段，防止出现“u<EF BB BF>nit”这类显示异常
      // 简单线性扫描：从索引3开始查找 EF BB BF，遇到则删除这3个字节
      var i := 3; // 跳过文件开头的BOM
      while i <= Length(ResultBuffer) - 3 do
      begin
        if (ResultBuffer[i] = $EF) and (ResultBuffer[i+1] = $BB) and (ResultBuffer[i+2] = $BF) then
        begin
          // 删除这3个字节
          var TailLen := Length(ResultBuffer) - (i + 3);
          if TailLen > 0 then
            System.Move(ResultBuffer[i+3], ResultBuffer[i], TailLen);
          SetLength(ResultBuffer, Length(ResultBuffer) - 3);
          // 不递增 i，继续检查当前位置，直到无残留
          Continue;
        end;
        Inc(i);
      end;
    end;

    // 规范化：当目标为 UTF-8（无 BOM）时，移除内容中任何位置的 EF BB BF 片段，避免出现 "u<EF BB BF>nit"。
    if (CompareText(TargetEncoding, ENCODING_UTF8) = 0) and (Length(ResultBuffer) > 0) then
    begin
      var j := 0;
      while j <= Length(ResultBuffer) - 3 do
      begin
        if (ResultBuffer[j] = $EF) and (ResultBuffer[j+1] = $BB) and (ResultBuffer[j+2] = $BF) then
        begin
          var Tail := Length(ResultBuffer) - (j + 3);
          if Tail > 0 then
            System.Move(ResultBuffer[j+3], ResultBuffer[j], Tail);
          SetLength(ResultBuffer, Length(ResultBuffer) - 3);
          Continue;
        end;
        Inc(j);
      end;
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
    // 检测源文件编�?
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
      on E: Exception do
      begin
        AddError(Result, ecetIOError, 0, 0, '无法读取源文�? ' + string(E.Message));
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

    // 最终保障：针对 UTF-8 目标，做一次文件级规范化，移除内部 BOM（以及可能的 "ï»¿" 六字节序列）
    if (CompareText(TargetEncoding, ENCODING_UTF8) = 0) and (Length(OutputBuffer) > 0) then
    begin
      var k := 0;
      while k <= Length(OutputBuffer) - 3 do
      begin
        if (OutputBuffer[k] = $EF) and (OutputBuffer[k+1] = $BB) and (OutputBuffer[k+2] = $BF) then
        begin
          var Tail := Length(OutputBuffer) - (k + 3);
          if Tail > 0 then System.Move(OutputBuffer[k+3], OutputBuffer[k], Tail);
          SetLength(OutputBuffer, Length(OutputBuffer) - 3);
          Continue;
        end;
        Inc(k);
      end;
      // 移除可能的 C3 AF C2 BB C2 BF 序列
      k := 0;
      while k <= Length(OutputBuffer) - 6 do
      begin
        if (OutputBuffer[k] = $C3) and (OutputBuffer[k+1] = $AF) and (OutputBuffer[k+2] = $C2) and (OutputBuffer[k+3] = $BB) and (OutputBuffer[k+4] = $C2) and (OutputBuffer[k+5] = $BF) then
        begin
          var Tail6 := Length(OutputBuffer) - (k + 6);
          if Tail6 > 0 then System.Move(OutputBuffer[k+6], OutputBuffer[k], Tail6);
          SetLength(OutputBuffer, Length(OutputBuffer) - 6);
          Continue;
        end;
        Inc(k);
      end;
    end
    else if (CompareText(TargetEncoding, ENCODING_UTF8_BOM) = 0) and (Length(OutputBuffer) > 0) then
    begin
      // 确保首部保留一个 BOM
      var Leading := (Length(OutputBuffer) >= 3) and (OutputBuffer[0]=$EF) and (OutputBuffer[1]=$BB) and (OutputBuffer[2]=$BF);
      if not Leading then
        OutputBuffer := TEncodingBOMDetector_Improved.AddBOM(OutputBuffer, 1);
      // 清除内部 BOM（索引3开始）
      var p := 3;
      while p <= Length(OutputBuffer) - 3 do
      begin
        if (OutputBuffer[p] = $EF) and (OutputBuffer[p+1] = $BB) and (OutputBuffer[p+2] = $BF) then
        begin
          var TailB := Length(OutputBuffer) - (p + 3);
          if TailB > 0 then System.Move(OutputBuffer[p+3], OutputBuffer[p], TailB);
          SetLength(OutputBuffer, Length(OutputBuffer) - 3);
          Continue;
        end;
        Inc(p);
      end;
      // 清除内部 "ï»¿" 六字节序列（索引3开始）
      p := 3;
      while p <= Length(OutputBuffer) - 6 do
      begin
        if (OutputBuffer[p] = $C3) and (OutputBuffer[p+1] = $AF) and (OutputBuffer[p+2] = $C2) and (OutputBuffer[p+3] = $BB) and (OutputBuffer[p+4] = $C2) and (OutputBuffer[p+5] = $BF) then
        begin
          var Tail6b := Length(OutputBuffer) - (p + 6);
          if Tail6b > 0 then System.Move(OutputBuffer[p+6], OutputBuffer[p], Tail6b);
          SetLength(OutputBuffer, Length(OutputBuffer) - 6);
          Continue;
        end;
        Inc(p);
      end;
    end;

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
            AddError(Result, ecetIOError, 0, 0, '替换文件时发生异�? ' + string(E.Message));
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
        // 显式转换
        ActualSourceEncoding := string(BOMResult.Encoding);
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
    // 恢复流位�?
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
      // 检测中文编�?
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
begin
  NameU := Trim(EncodingName);
  if NameU = '' then
    Exit(GetACP());

  // 查找缓存
  for i := 0 to CodePageCacheCount - 1 do
    if SameText(CodePageCache[i].Name, NameU) then
      Exit(CodePageCache[i].CodePage);

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

  // 添加到缓存
  if (Result <> 0) and (CodePageCacheCount < Length(CodePageCache)) then
  begin
    CodePageCache[CodePageCacheCount].Name := NameU;
    CodePageCache[CodePageCacheCount].CodePage := Result;
    Inc(CodePageCacheCount);
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
