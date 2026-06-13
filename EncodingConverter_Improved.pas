unit EncodingConverter_Improved;

interface

uses
  System.SysUtils, System.Classes, System.Math, Winapi.Windows, System.IOUtils, 
  System.SyncObjs, UtilsTypes, UtilsPathSecurity,
  UtilsEncodingBOM_Improved, UtilsEncodingUTF8Detector_Improved,
  ChineseEncodingDetector_Improved, UTF8BOMConverter_Improved, UtilsEncodingHelper;

type
  /// <summary>

  /// </summary>
  TEncodingConversionErrorType = (
    ecetNone,
    ecetInvalidSequence,
    ecetUnmappableChar,
    ecetIncompleteSequence,
    ecetIOError,
    ecetUnknownError
  );

  /// <summary>

  /// </summary>
  TEncodingErrorHandlingStrategy = (
    eehsThrow,
    eehsReplace,
    eehsSkip,
    eehsReport
  );

  /// <summary>

  /// </summary>
  TEncodingConversionError = record
    ErrorType: TEncodingConversionErrorType;
    Position: Int64;
    ByteValue: Byte;
    ErrorMessage: string;
  end;

  /// <summary>

  /// </summary>
  TEncodingConversionResult = record
    Success: Boolean;
    SourceEncoding: string;
    TargetEncoding: string;
    BytesProcessed: Int64;
    ErrorCount: Integer;
    Errors: array of TEncodingConversionError;
    HasBOM: Boolean;
    OutputData: TBytes;
  end;

  /// <summary>

  /// </summary>
  TEncodingConversionOptions = record
    AddBOM: Boolean;
    ErrorHandling: TEncodingErrorHandlingStrategy;
    ReplacementChar: WideChar;
    DetectSourceEncoding: Boolean;
    MaxErrorCount: Integer;
  end;

  /// <summary>

  /// </summary>
  TStreamingProgressCallback = reference to procedure(
    BytesProcessed: Int64;
    TotalBytes: Int64;
    var Cancel: Boolean
  );

  /// <summary>

  /// </summary>
  TEncodingConverter_Improved = class
  private
    /// <summary>

    /// </summary>
    class function GetCodePage(const EncodingName: string): Integer;

    /// <summary>

    /// </summary>
    class function DetectFileEncoding(const FileName: string): string;

    /// <summary>

    /// </summary>
    class procedure AddError(var ConvResult: TEncodingConversionResult; ErrorType: TEncodingConversionErrorType; Position: Int64; ByteValue: Byte; const ErrorMessage: string);

    /// <summary>

    /// </summary>
    class function HandleConversionError(var ConvResult: TEncodingConversionResult; ErrorType: TEncodingConversionErrorType; Position: Int64; ByteValue: Byte; const ErrorMessage: string; Strategy: TEncodingErrorHandlingStrategy): Boolean;

    /// <summary>

    /// </summary>
    class function DecodeBufferToUnicode(const Buffer: TBytes; const EncodingName: string): UnicodeString;

    /// <summary>

    /// </summary>
    class function IsFileAccessible(const FileName: string; out UseTemp: Boolean): Boolean;

  public
    /// <summary>

    /// </summary>
    class function CreateDefaultOptions: TEncodingConversionOptions;

    /// <summary>

    /// </summary>
    class function ConvertFile(const SourceFileName, TargetFileName: string; const SourceEncoding, TargetEncoding: string; const Options: TEncodingConversionOptions): TEncodingConversionResult;

    /// <summary>

    /// </summary>
    class function ConvertBuffer(const Buffer: TBytes; const SourceEncoding, TargetEncoding: string; const Options: TEncodingConversionOptions): TEncodingConversionResult;

    /// <summary>

    /// </summary>
    class function ConvertStream(const SourceStream, TargetStream: TStream; const SourceEncoding, TargetEncoding: string; const Options: TEncodingConversionOptions): TEncodingConversionResult;

    /// <summary>

    /// </summary>
    class function BatchConvertFiles(const FileNames: TArray<string>; const TargetDir: string; const TargetEncoding: string; const Options: TEncodingConversionOptions): TArray<TEncodingConversionResult>;

    /// <summary>

    /// </summary>
    class function ValidateConversion(const SourceFileName, TargetFileName: string): Boolean;

    /// <summary>


    /// </summary>
    class function ValidateConversionIntegrity(
      const SourceBuffer: TBytes;
      const SourceEncoding: string;
      const ConversionResult: TEncodingConversionResult): Boolean;

    /// <summary>


    /// </summary>


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

        W := Word(P[0] or (P[1] shl 8))
      else

        W := Word((P[0] shl 8) or P[1]);
      Result[i+1] := WideChar(W);
      Inc(P, 2);
    end;
    Exit;
  end;


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

        W := Word(P[0] or (P[1] shl 8))
      else

        W := Word((P[2] shl 8) or P[3]);
      Result[i+1] := WideChar(W);
      Inc(P, 4);
    end;
    Exit;
  end;


  DestLength := MultiByteToWideChar(CodePage, 0, Source, SourceLength, nil, 0);

  if DestLength <= 0 then
  begin
    Result := '';
    Exit;
  end;

  SetLength(Result, DestLength);
  MultiByteToWideChar(CodePage, 0, Source, SourceLength, PWideChar(Result), DestLength);
end;


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


  DefaultChar := '?';
  UsedDefaultChar := False;


  DestLength := WideCharToMultiByte(CodePage, 0, PWideChar(Source), Length(Source), nil, 0, nil, nil);

  if DestLength <= 0 then
  begin
    Result := '';
    Exit;
  end;


  SetLength(Result, DestLength);


  WideCharToMultiByte(CodePage, 0, PWideChar(Source), Length(Source),
                      PAnsiChar(Result), DestLength, @DefaultChar, @UsedDefaultChar);


end;


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

  Inc(ConvResult.ErrorCount);


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


  if not DirectoryExists(TargetDir) then
    ForceDirectories(TargetDir);


  for i := 0 to High(FileNames) do
  begin

    TargetFileName := IncludeTrailingPathDelimiter(TargetDir) + ExtractFileName(FileNames[i]);


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


  BOMResult.BOMType := 0;
  BOMResult.BOMLength := 0;


  if Length(Buffer) = 0 then
  begin
    Result.Success := True;
    SetLength(ResultBuffer, 0);
    Result.OutputData := ResultBuffer;
    Result.BytesProcessed := 0;
    Exit;
  end;

  try

    if (SourceEncoding = '') or Options.DetectSourceEncoding then
    begin

      BOMResult := TEncodingBOMDetector_Improved.DetectBOM(Buffer);

      if BOMResult.BOMType <> 0 then
      begin

        ActualSourceEncoding := string(BOMResult.Encoding);
        Result.HasBOM := True;
        _Trace(Format('[ConvertBuffer] BOM detected type=%d enc=%s', [BOMResult.BOMType, ActualSourceEncoding]));
      end
      else
      begin

        UTF8Result := TUTF8EncodingDetector_Improved.DetectBuffer(Buffer);

        if UTF8Result.IsUTF8 then
          ActualSourceEncoding := ENCODING_UTF8
        else
        begin

          ChineseResult := TChineseEncodingDetector_Improved.DetectBuffer(Buffer);

          ActualSourceEncoding := string(ChineseResult.Encoding);
        end;
        _Trace(Format('[ConvertBuffer] Detect src enc=%s utf8=%s conf=%.3f', [ActualSourceEncoding, BoolToStr(UTF8Result.IsUTF8, True), UTF8Result.Confidence]));
      end;
    end
    else
      ActualSourceEncoding := SourceEncoding;

    Result.SourceEncoding := ActualSourceEncoding;
    _Trace('[ConvertStream] ActualSourceEncoding=' + ActualSourceEncoding);


    SourceCodePage := GetCodePage(ActualSourceEncoding);
    TargetCodePage := GetCodePage(TargetEncoding);
    _Trace(Format('[ConvertBuffer] CodePages src=%d tgt=%d', [SourceCodePage, TargetCodePage]));


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


    if (SourceCodePage = TargetCodePage) and not IsUTF8Family and Options.AddBOM then
    begin

      var SrcBOM := TEncodingBOMDetector_Improved.DetectBOM(Buffer);
      if SrcBOM.BOMType <> 0 then
      begin

        SetLength(ResultBuffer, Length(Buffer) - SrcBOM.BOMLength);
        if Length(ResultBuffer) > 0 then
          Move(Buffer[SrcBOM.BOMLength], ResultBuffer[0], Length(ResultBuffer));
      end
      else
        ResultBuffer := Copy(Buffer);


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


    if Length(SourceBuffer) > 0 then
    begin


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

      var UseFast := TEncodingHelper.TryConvertFast(
        SourceBuffer, SourceCodePage, TargetCodePage, ResultBuffer);
      _Trace(Format('[ConvertBuffer] TryConvertFast=%s srcLen=%d outLen=%d', [BoolToStr(UseFast, True), Length(SourceBuffer), Length(ResultBuffer)]));
      if not UseFast then
      begin


        try
          WideStr := StringToUnicodeString(PAnsiChar(@SourceBuffer[0]), SourceCodePage, Length(SourceBuffer));
          {$IFDEF DEBUG_CONVERT_TRACE}
          AppendToFile('tmp_tests\convert_trace.txt', Format('ConvertBuffer: SourceCodePage=%d, Length(SourceBuffer)=%d, WideStr=%s', [SourceCodePage, Length(SourceBuffer), WideStr]));
          {$ENDIF}
        except

          on E: EEncodingException do
          begin
            HandleConversionError(Result, ecetInvalidSequence, 0, 0, E.Message, Options.ErrorHandling);
            {$IFDEF DEBUG_CONVERT_TRACE}
            AppendToFile('tmp_tests\convert_trace.txt', Format('ConvertBuffer: Exception=%s', [E.Message]));
            {$ENDIF}


            WideStr := '';
          end;
        end;


        if WideStr <> '' then
        begin

          var TargetStr := UnicodeStringToString(WideStr, TargetCodePage);


          if Length(TargetStr) > 0 then
          begin
            SetLength(ResultBuffer, Length(TargetStr));
            Move(TargetStr[1], ResultBuffer[0], Length(TargetStr));
          end
          else
          begin

            HandleConversionError(Result, ecetUnmappableChar, 0, 0, '', Options.ErrorHandling);
            SetLength(ResultBuffer, 0);
          end;
        end
        else
        begin

          SetLength(ResultBuffer, 0);
        end;
      end;
      end; // ISO-2022 else block
    end
    else
      SetLength(ResultBuffer, 0);


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

  Result.Success := False;
  Result.SourceEncoding := SourceEncoding;
  Result.TargetEncoding := TargetEncoding;
  Result.BytesProcessed := 0;
  Result.ErrorCount := 0;
  SetLength(Result.Errors, 0);
  Result.HasBOM := False;
  MaxRetry := 5;


  if not TPathSecurityValidator.IsPathSafe(SourceFileName) then
  begin
    AddError(Result, ecetIOError, 0, 0, '');
    Exit;
  end;

  if not TPathSecurityValidator.IsPathSafe(TargetFileName) then
  begin
    AddError(Result, ecetIOError, 0, 0, '');
    Exit;
  end;


  if not FileExists(SourceFileName) then
  begin
    AddError(Result, ecetIOError, 0, 0, '');
    Exit;
  end;


  TempFileName := TTempFileSecurityManager.GetSecureTempFileInDir(ExtractFilePath(TargetFileName));
  TTempFileSecurityManager.RegisterTempFile(TempFileName);

  try

    if (SourceEncoding = '') or Options.DetectSourceEncoding then
      ActualSourceEncoding := DetectFileEncoding(SourceFileName)
    else
      ActualSourceEncoding := SourceEncoding;

    Result.SourceEncoding := ActualSourceEncoding;

    // v2.0.1 P1.1: 大文件自动走流式路径（>16 MB）
    try
      SourceStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyNone);
      try
        var FileSize := SourceStream.Size;
        if FileSize > 16 * 1024 * 1024 then
        begin
          // 文件超过 16 MB，委托给流式处理方法
          SourceStream.Free;
          SourceStream := nil;
          TTempFileSecurityManager.UnregisterTempFile(TempFileName);
          if FileExists(TempFileName) then
            TTempFileSecurityManager.SecureDeleteFile(TempFileName);
          Result := ConvertFileStreaming(SourceFileName, TargetFileName,
            ActualSourceEncoding, TargetEncoding, Options, nil);
          Exit;
        end;
        // 正常路径：一次性读取
        SetLength(Buffer, FileSize);
        if FileSize > 0 then
          SourceStream.ReadBuffer(Buffer[0], FileSize);
      finally
        if Assigned(SourceStream) then
          SourceStream.Free;
      end;
    except
      on E: EEncodingException do
      begin
        AddError(Result, ecetIOError, 0, 0, '' + string(E.Message));
        Exit;
      end;
      on E: Exception do
      begin
        AddError(Result, ecetIOError, 0, 0, '' + string(E.Message));
        Exit;
      end;
    end;


    _Trace(Format('[ConvertStream] read src bytes=%d', [Length(Buffer)]));
    Result := ConvertBuffer(Buffer, ActualSourceEncoding, TargetEncoding, Options);
    _Trace(Format('[ConvertStream] ConvertBuffer success=%s outLen=%d', [BoolToStr(Result.Success, True), Length(Result.OutputData)]));


    if not Result.Success then
      Exit;


    OutputBuffer := Result.OutputData;


    // v2.0.1 P1.2: BOM-only 文件清理后输出为空是正常行为，不应报错
    if (Length(Buffer) > 0) and (Length(OutputBuffer) = 0) then
    begin
      // 检查源文件是否仅含 BOM（3/4 字节），清理后为空是预期行为
      var IsBOMOnly := False;
      if Length(Buffer) <= 4 then
      begin
        var SrcBOM := TEncodingBOMDetector_Improved.DetectBOM(Buffer);
        if (SrcBOM.BOMType <> 0) and (SrcBOM.BOMLength >= Length(Buffer)) then
          IsBOMOnly := True;
      end;

      if not IsBOMOnly then
      begin
        AddError(Result, ecetUnknownError, 0, 0, '');
        Result.Success := False;
        Exit;
      end;
      // BOM-only: 允许写入空文件（或仅含目标 BOM 的文件）
    end;


    try
      FileAttrsSet := TFile.GetAttributes(SourceFileName);
    except

    end;


    try

      TFile.WriteAllBytes(TempFileName, OutputBuffer);
    except
      on E: Exception do
      begin
        AddError(Result, ecetIOError, 0, 0, '' + E.Message);
        Exit;
      end;
    end;


    RetryCount := 0;
    Success := False;

    repeat
      Inc(RetryCount);

      try

        if (SourceFileName <> TargetFileName) and FileExists(TargetFileName) then
        begin
          if not DeleteFile(PChar(TargetFileName)) then
          begin
            ErrCode := GetLastError;


            if (ErrCode = ERROR_SHARING_VIOLATION) or (ErrCode = ERROR_ACCESS_DENIED) then
            begin
              if RetryCount < MaxRetry then
              begin
                Sleep(500 * RetryCount);
                Continue;
              end;
            end;


            AddError(Result, ecetIOError, 0, 0, Format('', [ErrCode]));
            Result.Success := False;
            Exit;
          end;
        end;


        if SourceFileName = TargetFileName then
        begin

          var BackupFileName := ChangeFileExt(SourceFileName, '.backup_' + FormatDateTime('hhnnsszzz', Now));
          

          if FileExists(SourceFileName) then
          begin

            try
              if TFileAttribute.faReadOnly in FileAttrsSet then
              begin
                var NewAttrs := FileAttrsSet - [TFileAttribute.faReadOnly];
                TFile.SetAttributes(SourceFileName, NewAttrs);
              end;
            except

            end;


            if not RenameFile(SourceFileName, BackupFileName) then
            begin
              ErrCode := GetLastError;


              if (ErrCode = ERROR_SHARING_VIOLATION) or (ErrCode = ERROR_ACCESS_DENIED) then
              begin
                if RetryCount < MaxRetry then
                begin
                  Sleep(500 * RetryCount);
                  Continue;
                end;
              end;


              AddError(Result, ecetIOError, 0, 0, Format('', [ErrCode]));
              Result.Success := False;
              Exit;
            end;
          end;


          if RenameFile(TempFileName, TargetFileName) then
          begin
            Success := True;
            Result.Success := True;
            

            if FileExists(BackupFileName) then
            begin
              try
                DeleteFile(PChar(BackupFileName));
              except

              end;
            end;
            
            Break;
          end
          else
          begin

            ErrCode := GetLastError;
            
            if FileExists(BackupFileName) then
            begin
              try

                RenameFile(BackupFileName, SourceFileName);
                AddError(Result, ecetIOError, 0, 0, Format('', [ErrCode]));
              except
                on E: Exception do
                  AddError(Result, ecetIOError, 0, 0, Format('', [string(E.Message)]));
              end;
            end
            else
            begin
              AddError(Result, ecetIOError, 0, 0, Format('', [ErrCode]));
            end;
            
            Result.Success := False;
            Exit;
          end;
        end
        else
        begin

          if RenameFile(TempFileName, TargetFileName) then
          begin
            Success := True;
            Result.Success := True;
            Break;
          end;
        end;
        

        if not Success then
        begin
          ErrCode := GetLastError;


          if (ErrCode = ERROR_SHARING_VIOLATION) or (ErrCode = ERROR_ACCESS_DENIED) then
          begin
            if RetryCount < MaxRetry then
            begin
              Sleep(500 * RetryCount);
              Continue;
            end;
          end;


          AddError(Result, ecetIOError, 0, 0, Format('', [ErrCode]));
          Result.Success := False;
          Exit;
        end;
      except
        on E: Exception do
        begin

          if RetryCount < MaxRetry then
          begin
            Sleep(500 * RetryCount);
            Continue;
          end
          else
          begin
            AddError(Result, ecetIOError, 0, 0, '' + string(E.Message));
            Result.Success := False;
            Exit;
          end;
        end;
      end;
    until RetryCount >= MaxRetry;


    if not Success then
    begin
      AddError(Result, ecetIOError, 0, 0, '');
      Result.Success := False;
      Exit;
    end;


    try
      TFile.SetAttributes(TargetFileName, FileAttrsSet);
    except

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

  Result.Success := False;
  Result.SourceEncoding := SourceEncoding;
  Result.TargetEncoding := TargetEncoding;
  Result.BytesProcessed := 0;
  Result.ErrorCount := 0;
  SetLength(Result.Errors, 0);
  Result.HasBOM := False;


  if (SourceStream = nil) or (TargetStream = nil) then
  begin
    AddError(Result, ecetIOError, 0, 0, '');
    Exit;
  end;


  Position := SourceStream.Position;

  try

    if (SourceEncoding = '') or Options.DetectSourceEncoding then
    begin

      SourceStream.Position := 0;


      BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromStream(SourceStream);

      if BOMResult.BOMType <> 0 then
      begin

        ActualSourceEncoding := string(BOMResult.Encoding);
        Result.HasBOM := True;
      end
      else
      begin

        SourceStream.Position := 0;
        SetLength(Buffer, SourceStream.Size);
        if SourceStream.Size > 0 then
          SourceStream.ReadBuffer(Buffer[0], SourceStream.Size);


        var UTF8Result := TUTF8EncodingDetector_Improved.DetectBuffer(Buffer);

        if UTF8Result.IsUTF8 then
          ActualSourceEncoding := ENCODING_UTF8
        else
        begin

          var ChineseResult := TChineseEncodingDetector_Improved.DetectBuffer(Buffer);

          ActualSourceEncoding := string(ChineseResult.Encoding);
        end;
      end;
    end
    else
      ActualSourceEncoding := SourceEncoding;

    Result.SourceEncoding := ActualSourceEncoding;


    SourceStream.Position := 0;
    SetLength(Buffer, SourceStream.Size);
    if SourceStream.Size > 0 then
      SourceStream.ReadBuffer(Buffer[0], SourceStream.Size);


    Result := ConvertBuffer(Buffer, ActualSourceEncoding, TargetEncoding, Options);


    if (Length(Buffer) > 0) and (Length(Result.OutputData) = 0) then
    begin
      AddError(Result, ecetUnknownError, 0, 0, '');
      Result.Success := False;
      Exit;
    end;


    if Result.Success then
    begin
      TargetStream.Position := 0;
      TargetStream.Size := 0;
      if Length(Result.OutputData) > 0 then
        TargetStream.WriteBuffer(Result.OutputData[0], Length(Result.OutputData));
    end;
  finally

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

  BOMResult := TEncodingBOMDetector_Improved.DetectBOMFromFile(FileName);

  if BOMResult.BOMType <> 0 then

    Result := string(BOMResult.Encoding)
  else
  begin

    UTF8Result := TUTF8EncodingDetector_Improved.DetectFile(FileName);

    if UTF8Result.IsUTF8 then
      Result := ENCODING_UTF8
    else
    begin

      ChineseResult := TChineseEncodingDetector_Improved.DetectFile(FileName);

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


  CodePageCacheLock.Enter;
  try

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

    Result := UtilsTypes.GetEncodingCodePage(NameU);


  if (Result <> 0) and (CodePageCacheCount < Length(CodePageCache)) then
  begin
    CodePageCacheLock.Enter;
    try

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

  AddError(ConvResult, ErrorType, Position, ByteValue, ErrorMessage);


  case Strategy of
    eehsThrow:
      begin
        ConvResult.Success := False;
        Result := False;
      end;
    eehsReplace, eehsSkip, eehsReport:
      begin

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


  if not FileExists(FileName) then
    Exit;


  FileMode := GENERIC_READ or GENERIC_WRITE;
  FileHandle := CreateFile(
    PChar(FileName),
    FileMode,
    0,
    nil,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0);

  if FileHandle <> INVALID_HANDLE_VALUE then
  begin

    CloseHandle(FileHandle);
    Result := True;
  end
  else
  begin

    ErrCode := GetLastError;


    if (ErrCode = ERROR_SHARING_VIOLATION) or (ErrCode = ERROR_ACCESS_DENIED) then
    begin

      FileMode := GENERIC_READ;
      FileHandle := CreateFile(
        PChar(FileName),
        FileMode,
        FILE_SHARE_READ,
        nil,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
        0);

      if FileHandle <> INVALID_HANDLE_VALUE then
      begin

        CloseHandle(FileHandle);
        Result := True;
        UseTemp := True;
      end
      else
      begin

        Result := False;
      end;
    end
    else
    begin

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


  if not (FileExists(SourceFileName) and FileExists(TargetFileName)) then
    Exit;

  try

    SourceEncoding := DetectFileEncoding(SourceFileName);
    TargetEncoding := DetectFileEncoding(TargetFileName);


    SourceStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyNone);
    try
      TargetStream := TFileStream.Create(TargetFileName, fmOpenRead or fmShareDenyNone);
      try

        SourceBOMResult := TEncodingBOMDetector_Improved.DetectBOMFromStream(SourceStream);
        TargetBOMResult := TEncodingBOMDetector_Improved.DetectBOMFromStream(TargetStream);


        SourceStream.Position := SourceBOMResult.BOMLength;
        SetLength(SourceBuffer, SourceStream.Size - SourceBOMResult.BOMLength);
        if Length(SourceBuffer) > 0 then
          SourceStream.ReadBuffer(SourceBuffer[0], Length(SourceBuffer));

        TargetStream.Position := TargetBOMResult.BOMLength;
        SetLength(TargetBuffer, TargetStream.Size - TargetBOMResult.BOMLength);
        if Length(TargetBuffer) > 0 then
          TargetStream.ReadBuffer(TargetBuffer[0], Length(TargetBuffer));


        if CompareText(SourceEncoding, TargetEncoding) = 0 then
        begin

          Result := (Length(SourceBuffer) = Length(TargetBuffer));

          if Result and (Length(SourceBuffer) > 0) then
            Result := CompareMem(@SourceBuffer[0], @TargetBuffer[0], Length(SourceBuffer));
        end
        else
        begin


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


  if not ConversionResult.Success then
    Exit;


  if (Length(SourceBuffer) = 0) and (Length(ConversionResult.OutputData) = 0) then
  begin
    Result := True;
    Exit;
  end;


  if SourceEncoding <> '' then
    EffectiveSourceEncoding := SourceEncoding
  else
    EffectiveSourceEncoding := ConversionResult.SourceEncoding;


  try

    SrcBOM := TEncodingBOMDetector_Improved.DetectBOM(SourceBuffer);
    if SrcBOM.BOMType <> 0 then
    begin
      SetLength(SrcPayload, Length(SourceBuffer) - SrcBOM.BOMLength);
      if Length(SrcPayload) > 0 then
        Move(SourceBuffer[SrcBOM.BOMLength], SrcPayload[0], Length(SrcPayload));
    end
    else
      SrcPayload := SourceBuffer;


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

    Exit;
  end;


  if (Length(SourceBuffer) > 0) and (SourceChars = '') then
    Exit;
  if (Length(ConversionResult.OutputData) > 0) and (TargetChars = '') then
    Exit;


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
  CHUNK_SIZE = 64 * 1024;
  MAX_LOOKAHEAD = 6;
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

  Result.Success := False;
  Result.SourceEncoding := SourceEncoding;
  Result.TargetEncoding := TargetEncoding;
  Result.BytesProcessed := 0;
  Result.ErrorCount := 0;
  SetLength(Result.Errors, 0);
  Result.HasBOM := False;
  SetLength(Result.OutputData, 0);
  Cancel := False;
  BOMWritten := False;
  SetLength(Remainder, 0);


  if not TPathSecurityValidator.IsPathSafe(SourceFileName) then
  begin
    AddError(Result, ecetIOError, 0, 0, '');
    Exit;
  end;

  if not TPathSecurityValidator.IsPathSafe(TargetFileName) then
  begin
    AddError(Result, ecetIOError, 0, 0, '');
    Exit;
  end;


  if not FileExists(SourceFileName) then
  begin
    AddError(Result, ecetIOError, 0, 0, '');
    Exit;
  end;


  TempFileName := TTempFileSecurityManager.GetSecureTempFileInDir(ExtractFilePath(TargetFileName));
  TTempFileSecurityManager.RegisterTempFile(TempFileName);

  try

    if (SourceEncoding = '') or Options.DetectSourceEncoding then
      ActualSourceEncoding := DetectFileEncoding(SourceFileName)
    else
      ActualSourceEncoding := SourceEncoding;

    Result.SourceEncoding := ActualSourceEncoding;
    SourceCodePage := GetCodePage(ActualSourceEncoding);
    TargetCodePage := GetCodePage(TargetEncoding);


    try
      FileAttrsSet := TFile.GetAttributes(SourceFileName);
    except

    end;


    try
      SourceStream := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyNone);
    except
      on E: Exception do
      begin
        AddError(Result, ecetIOError, 0, 0, '' + E.Message);
        Exit;
      end;
    end;

    try
      TotalSize := SourceStream.Size;
      TotalProcessed := 0;


      var SrcBOM := TEncodingBOMDetector_Improved.DetectBOMFromStream(SourceStream);
      if SrcBOM.BOMType <> 0 then
      begin
        SourceStream.Position := SrcBOM.BOMLength;
        Result.HasBOM := True;
      end;


      try
        TargetStream := TFileStream.Create(TempFileName, fmCreate or fmShareDenyWrite);
      except
        on E: Exception do
        begin
          AddError(Result, ecetIOError, 0, 0, '' + E.Message);
          Exit;
        end;
      end;

      try

        if Options.AddBOM then
        begin
          var TargetBOMType := 0;
          var TargetCP := GetCodePage(TargetEncoding);

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


        SetLength(Buffer, CHUNK_SIZE + MAX_LOOKAHEAD);

        while SourceStream.Position < TotalSize do
        begin

          if Cancel then
          begin
            AddError(Result, ecetUnknownError, TotalProcessed, 0, '');
            Result.Success := False;
            Exit;
          end;


          ChunkSize := Min(CHUNK_SIZE, TotalSize - SourceStream.Position);
          

          ActualRead := SourceStream.Read(Buffer[Length(Remainder)], ChunkSize);
          if ActualRead <= 0 then
            Break;


          if Length(Remainder) > 0 then
          begin
            Move(Buffer[Length(Remainder)], Buffer[Length(Remainder)], ActualRead);
            Move(Remainder[0], Buffer[0], Length(Remainder));
            ActualRead := ActualRead + Length(Remainder);
            SetLength(Remainder, 0);
          end;


          SplitPos := ActualRead;
          if (SourceStream.Position < TotalSize) and (SourceCodePage = CP_UTF8) then
          begin

            for i := ActualRead - 1 downto Max(0, ActualRead - MAX_LOOKAHEAD) do
            begin
              // UTF-8 continuation byte: 10xxxxxx
              if (Buffer[i] and $C0) <> $80 then
              begin

                if Buffer[i] >= $80 then
                begin
                  var ExpectedLen := 1;
                  if (Buffer[i] and $E0) = $C0 then ExpectedLen := 2
                  else if (Buffer[i] and $F0) = $E0 then ExpectedLen := 3
                  else if (Buffer[i] and $F8) = $F0 then ExpectedLen := 4;
                  

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

            if (ActualRead > 0) and (Buffer[ActualRead - 1] >= $81) then
              SplitPos := ActualRead - 1;
          end;


          if SplitPos < ActualRead then
          begin
            SetLength(Remainder, ActualRead - SplitPos);
            Move(Buffer[SplitPos], Remainder[0], Length(Remainder));
            ActualRead := SplitPos;
          end;


          if ActualRead > 0 then
          begin
            SetLength(ChunkOutput, 0);
            

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

            TotalProcessed := TotalProcessed + ActualRead;
          end;


          if Assigned(ProgressCallback) then
            ProgressCallback(TotalProcessed, TotalSize, Cancel);
        end;


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


    if SourceFileName = TargetFileName then
    begin

      try
        if TFileAttribute.faReadOnly in FileAttrsSet then
          TFile.SetAttributes(SourceFileName, FileAttrsSet - [TFileAttribute.faReadOnly]);
      except
      end;

      if not DeleteFile(PChar(SourceFileName)) then
      begin
        AddError(Result, ecetIOError, 0, 0, '');
        Exit;
      end;

      if not RenameFile(TempFileName, TargetFileName) then
      begin
        AddError(Result, ecetIOError, 0, 0, '');
        Exit;
      end;
    end
    else
    begin

      if FileExists(TargetFileName) then
      begin
        if not DeleteFile(PChar(TargetFileName)) then
        begin
          AddError(Result, ecetIOError, 0, 0, '');
          Exit;
        end;
      end;

      if not RenameFile(TempFileName, TargetFileName) then
      begin
        AddError(Result, ecetIOError, 0, 0, '');
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
      AddError(Result, ecetUnknownError, 0, 0, '' + E.Message);
    end;
  end;


  if FileExists(TempFileName) then
  begin
    TTempFileSecurityManager.SecureDeleteFile(TempFileName);
    TTempFileSecurityManager.UnregisterTempFile(TempFileName);
  end;
end;

initialization

  CodePageCacheLock := TCriticalSection.Create;

finalization

  if Assigned(CodePageCacheLock) then
    FreeAndNil(CodePageCacheLock);

end.
