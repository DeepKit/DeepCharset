unit ControllerEncoding;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Math, System.TypInfo, System.DateUtils,
  ModelEncoding, Winapi.Windows, HelperFiles, UtilsTypes, UtilsPathSecurity, UtilsTempFileSecurity,
  UtilsEncodingBOM_Improved, UtilsEncodingUTF8Detector_Improved,
  ChineseEncodingDetector_Improved, JapaneseEncodingDetector_Improved, KoreanEncodingDetector_Improved,
  UTF8BOMConverter_Improved, EncodingConverter_Improved;

type
  TEncodingConversionResultType = (crSuccess, crFailed, crSkipped);


  TEncodingController = class
  private

    FLogCallback: TProc<string>;


    FTempPath: string;


    FFileHelper: TFileHelper;


    procedure Log(const Msg: string);


    function DetectFileEncoding(const FileName: string; out HasBOM: Boolean): string;

  public
    constructor Create(ALogCallback: TProc<string>);
    destructor Destroy; override;


    function IsUnsupportedFile(const Filename: string): Boolean;


    function ConvertSingleFile(const FileName, TargetEncoding: string; WithBOM: Boolean;
      OnSuccess: TProc<string> = nil): Boolean;


    procedure ConvertFiles(const FileNames: TArray<string>; const TargetEncoding: string;
      WithBOM: Boolean; OnSuccess: TProc<string> = nil);
  end;

implementation

uses
  UtilsEncodingConfig;

{$WARN IMPLICIT_STRING_CAST OFF}

const

  UNSUPPORTED_FILES: array[0..5] of string = (
    'desktop.ini', 'thumbs.db', 'ntuser.dat', 'pagefile.sys', 'hiberfil.sys', 'swapfile.sys'
  );

{ TEncodingController }

constructor TEncodingController.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := ALogCallback;
  FTempPath := TTempFileSecurityManager.GetTempDirectory;


  FFileHelper := TFileHelper.Create(ALogCallback);

  // Log initialization in English to avoid mojibake
  Log(string('Encoding controller initialized'));
end;

destructor TEncodingController.Destroy;
begin

  if Assigned(FFileHelper) then
    FFileHelper.Free;

  inherited;
end;

procedure TEncodingController.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

function TEncodingController.DetectFileEncoding(const FileName: string; out HasBOM: Boolean): string;
var
  JapaneseResult: TJapaneseEncodingResult;
  KoreanResult: TKoreanEncodingResult;
  FileStream: TFileStream;
  Buffer: TBytes;
  DetectionInfo: TEncodingDetectionInfo;
  FileExt: string;
  StartTime: TDateTime;
  ElapsedTime: Int64;
  BOMResult: TBOMDetectionResult;
  UTF8Result: TUTF8DetectionResult;
  ChineseResult: TChineseEncodingResult;
begin

  if Assigned(FFileHelper) then
  begin

    Result := string(FFileHelper.DetectFileEncoding(FileName, HasBOM));
    Log(Format('Detected encoding by FileHelper for %s: %s (BOM: %s)',
      [ExtractFileName(FileName), Result, BoolToStr(HasBOM, True)]));
    Exit;
  end;

  // Fallback: use improved detection algorithm
  Log(Format('Detecting file encoding (improved): %s', [FileName]));

  // Get file extension
  FileExt := LowerCase(ExtractFileExt(FileName));
  Log(Format('File extension: %s', [FileExt]));


  try

    StartTime := Now;

    // Check file existence first
    if not FileExists(FileName) then
    begin
      Log(Format('File not found: %s', [FileName]));
      Result := 'Unknown';
      HasBOM := False;
      Exit;
    end;


    try
      FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
      try

        SetLength(Buffer, Min(FileStream.Size, FILE_READ_LIMIT));
        if Length(Buffer) > 0 then
          FileStream.ReadBuffer(Buffer[0], Length(Buffer));
      finally
        FileStream.Free;
      end;
    except
      on E: Exception do
      begin
        Log(Format('Read file failed: %s - %s', [FileName, E.Message]));
        Result := 'ANSI';
        HasBOM := False;
        Exit;
      end;
    end;


    BOMResult := TEncodingBOMDetector_Improved.DetectBOM(Buffer);
    if BOMResult.BOMType <> 0 then
    begin


      Result := string(BOMResult.Encoding);
      HasBOM := True;

      // Detailed log
      ElapsedTime := MilliSecondsBetween(StartTime, Now);
      Log(Format('BOM detected: %s, elapsed: %d ms',
        [Result, ElapsedTime]));
    end
    else
    begin

      UTF8Result := TUTF8EncodingDetector_Improved.DetectBuffer(Buffer);
      if UTF8Result.IsUTF8 then
      begin

        Result := 'UTF-8';
        HasBOM := False;

        // Detailed log
        ElapsedTime := MilliSecondsBetween(StartTime, Now);
        Log(Format('UTF-8 detected: confidence: %.2f, valid: %d, invalid: %d, elapsed: %d ms',
          [UTF8Result.Confidence, UTF8Result.ValidByteCount,
           UTF8Result.InvalidByteCount, ElapsedTime]));
      end
      else
      begin

        JapaneseResult := TJapaneseEncodingDetector_Improved.DetectBuffer(Buffer);

        if (JapaneseResult.Confidence >= TEncodingDetectionConfig.MinJapaneseConfidence) and (JapaneseResult.Encoding <> ENCODING_ANSI) and (JapaneseResult.Encoding <> ENCODING_UNKNOWN) then
        begin


          Result := string(JapaneseResult.Encoding);
          HasBOM := JapaneseResult.HasBOM;

          // Detailed log
          ElapsedTime := MilliSecondsBetween(Now, StartTime);
          Log(Format('Japanese encoding detected: %s, confidence: %.2f, elapsed: %d ms',
            [Result, JapaneseResult.Confidence, ElapsedTime]));
        end
        else
        begin

          KoreanResult := TKoreanEncodingDetector_Improved.DetectBuffer(Buffer);

          if (KoreanResult.Confidence >= TEncodingDetectionConfig.MinKoreanConfidence) and (KoreanResult.Encoding <> ENCODING_ANSI) and (KoreanResult.Encoding <> ENCODING_UNKNOWN) then
          begin


            Result := string(KoreanResult.Encoding);
            HasBOM := KoreanResult.HasBOM;

            // Detailed log
            ElapsedTime := MilliSecondsBetween(Now, StartTime);
            Log(Format('Korean encoding detected: %s, confidence: %.2f, elapsed: %d ms',
              [Result, KoreanResult.Confidence, ElapsedTime]));
          end
          else
          begin

            Result := 'ANSI';
            HasBOM := False;

            // Detailed log
            ElapsedTime := MilliSecondsBetween(Now, StartTime);
            Log(Format('Encoding not determined, using default: %s, elapsed: %d ms',
              [Result, ElapsedTime]));
          end;
        end;
      end;
    end;

    // Final result
    Log(Format('Detected encoding for %s: %s (BOM: %s)',
      [ExtractFileName(FileName), Result, BoolToStr(HasBOM, True)]));
  except
    on E: Exception do
    begin

      Result := 'ANSI';
      HasBOM := False;

      // Error log
      Log(Format('Detect encoding failed: %s - %s', [FileName, E.Message]));
    end;
  end;
end;

function TEncodingController.IsUnsupportedFile(const Filename: string): Boolean;
var
  BaseName: string;
  i: Integer;
begin
  BaseName := ExtractFileName(Filename);
  Result := False;

  for i := Low(UNSUPPORTED_FILES) to High(UNSUPPORTED_FILES) do
  begin
    if SameText(BaseName, UNSUPPORTED_FILES[i]) then
    begin
      Result := True;
      Log(Format(string('File %s is in unsupported list, skipped'), [BaseName]));
      Break;
    end;
  end;
end;

function TEncodingController.ConvertSingleFile(const FileName, TargetEncoding: string;
  WithBOM: Boolean; OnSuccess: TProc<string> = nil): Boolean;
var
  SourceEncodingName: string;
  HasBOM: Boolean;
  Options: TEncodingConversionOptions;
  ConversionResult: TEncodingConversionResult;
  FinalTargetEncoding: string;
begin
  Result := False;


  var PathResult := TPathSecurityValidator.ValidatePath(FileName);
  if not PathResult.IsSafe then
  begin
    Log(Format(string('文件路径不安全: %s - 原因: %s'), [string(FileName), string(PathResult.ErrorMessage)]));
    Exit;
  end;


  if not FileExists(FileName) then
  begin
    Log(Format(string(''), [string(FileName)]));
    Exit;
  end;


  if IsUnsupportedFile(FileName) then
    Exit;


  SourceEncodingName := DetectFileEncoding(FileName, HasBOM);


  if SameText(TargetEncoding, 'UTF-8') and WithBOM then
    FinalTargetEncoding := ENCODING_UTF8_BOM
  else if SameText(TargetEncoding, 'UTF-8 with BOM') then
    FinalTargetEncoding := ENCODING_UTF8_BOM
  else if SameText(TargetEncoding, 'UTF-8-BOM') then
    FinalTargetEncoding := ENCODING_UTF8_BOM
  else if SameText(TargetEncoding, 'UTF8-BOM') then
    FinalTargetEncoding := ENCODING_UTF8_BOM
  else if SameText(TargetEncoding, 'UTF8BOM') then
    FinalTargetEncoding := ENCODING_UTF8_BOM
  else
    FinalTargetEncoding := TargetEncoding;


  Options := TEncodingConverter_Improved.CreateDefaultOptions;
  Options.AddBOM := WithBOM;
  Options.DetectSourceEncoding := False;


  Log(Format(string(''),
    [string(SourceEncodingName), string(FinalTargetEncoding), string(BoolToStr(WithBOM, True))]));

  try

    ConversionResult := TEncodingConverter_Improved.ConvertFile(
      FileName, FileName, SourceEncodingName, FinalTargetEncoding, Options);


    if ConversionResult.Success then
    begin
      Result := True;
      Log(Format(string(''),
        [string(ExtractFileName(FileName)), string(SourceEncodingName), string(FinalTargetEncoding)]));


      if Assigned(OnSuccess) then
        OnSuccess(FileName);
    end
    else
    begin
      Result := False;
      Log(Format(string(''),
        [string(ExtractFileName(FileName)), ConversionResult.ErrorCount]));


      for var i := 0 to ConversionResult.ErrorCount - 1 do
        Log(Format(string(''),
          [i+1, string(ConversionResult.Errors[i].ErrorMessage), ConversionResult.Errors[i].Position]));
    end;
  except
    on E: Exception do
    begin
      Result := False;
      Log(Format(string(''),
        [string(ExtractFileName(FileName)), string(E.Message)]));
    end;
  end;
end;

procedure TEncodingController.ConvertFiles(const FileNames: TArray<string>;
  const TargetEncoding: string; WithBOM: Boolean; OnSuccess: TProc<string> = nil);
var
  i, SuccessCount, FailCount, TotalCount: Integer;
  ProgressInterval, LastProgressReport: Integer;
  StartTime, EndTime: TDateTime;
  ElapsedSeconds: Double;
begin
  SuccessCount := 0;
  FailCount := 0;
  TotalCount := Length(FileNames);
  StartTime := Now;


  ProgressInterval := Max(1, Min(TotalCount div 20, 10));
  LastProgressReport := 0;

  Log(Format(string(''),
    [TotalCount, string(TargetEncoding), string(BoolToStr(WithBOM, True))]));

  for i := 0 to High(FileNames) do
  begin

    if ConvertSingleFile(FileNames[i], TargetEncoding, WithBOM, OnSuccess) then
      Inc(SuccessCount)
    else
      Inc(FailCount);


    if (i + 1 - LastProgressReport >= ProgressInterval) or (i = High(FileNames)) then
    begin
      LastProgressReport := i + 1;
      Log(Format(string(''),
        [i + 1, TotalCount, (i + 1) / TotalCount * 100, SuccessCount, FailCount]));
    end;
  end;


  EndTime := Now;
  ElapsedSeconds := (EndTime - StartTime) * 86400;


  Log('');
  Log(Format(string(''), [SuccessCount, TotalCount]));
  Log(Format(string(''), [TotalCount]));
  Log(Format(string(''), [SuccessCount, SuccessCount / TotalCount * 100]));
  Log(Format(string(''), [FailCount, FailCount / TotalCount * 100]));
  Log(Format(string(''),
    [ElapsedSeconds, ElapsedSeconds * 1000 / TotalCount]));


  if FailCount > 0 then
    Log('');
end;

end.
