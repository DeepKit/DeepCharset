unit EncodingAdapters;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  UtilsTypes,
  InterfacesEncoding,
  UtilsEncodingUTF8Detector_Improved,
  ChineseEncodingDetector_Improved,
  JapaneseEncodingDetector_Improved,
  KoreanEncodingDetector_Improved,
  EncodingConverter_Improved;

type
  { IEncodingDetectionResult ÊÊÅäÆ÷ }
  TEncodingDetectionResultAdapter = class(TInterfacedObject, IEncodingDetectionResult)
  private
    FEncoding: string;
    FConfidence: Double;
    FHasBOM: Boolean;
    FDetails: string;
    function GetEncoding: string;
    function GetConfidence: Double;
    function GetHasBOM: Boolean;
    function GetDetails: string;
  public
    constructor Create(const AEncoding: string; AConfidence: Double; AHasBOM: Boolean; const ADetails: string);
  end;

  { IEncodingConversionResult ÊÊÅäÆ÷ }
  TEncodingConversionResultAdapter = class(TInterfacedObject, IEncodingConversionResult)
  private
    FInner: TEncodingConversionResult;
    FErrorMessage: string;
    function GetSuccess: Boolean;
    function GetSourceEncoding: string;
    function GetTargetEncoding: string;
    function GetBytesProcessed: Int64;
    function GetErrorCount: Integer;
    function GetOutputData: TBytes;
    function GetErrorMessage: string;
  public
    constructor Create(const AResult: TEncodingConversionResult);
  end;

  { IEncodingConversionOptions ÊÊÅäÆ÷ }
  TEncodingConversionOptionsAdapter = class(TInterfacedObject, IEncodingConversionOptions)
  private
    FOptions: TEncodingConversionOptions;
    function GetAddBOM: Boolean;
    procedure SetAddBOM(const Value: Boolean);
    function GetDetectSourceEncoding: Boolean;
    procedure SetDetectSourceEncoding(const Value: Boolean);
    function GetMaxErrorCount: Integer;
    procedure SetMaxErrorCount(const Value: Integer);
  public
    constructor Create(const AOptions: TEncodingConversionOptions); overload;
    constructor CreateDefault; overload;
    function ToRecord: TEncodingConversionOptions;
  end;

  { Í¨ÓÃ±àÂë×ª»»Æ÷ÊÊÅäÆ÷ }
  TEncodingConverterAdapter = class(TInterfacedObject, IEncodingConverter)
  private
    function ConvertBuffer(const Buffer: TBytes;
                           const SourceEncoding, TargetEncoding: string;
                           const Options: IEncodingConversionOptions): IEncodingConversionResult;
    function ConvertFile(const SourceFileName, TargetFileName: string;
                         const SourceEncoding, TargetEncoding: string;
                         const Options: IEncodingConversionOptions): IEncodingConversionResult;
    function ConvertStream(const SourceStream, TargetStream: TStream;
                           const SourceEncoding, TargetEncoding: string;
                           const Options: IEncodingConversionOptions): IEncodingConversionResult;
    function BatchConvertFiles(const FileNames: TArray<string>;
                               const TargetDir: string;
                               const TargetEncoding: string;
                               const Options: IEncodingConversionOptions): TArray<IEncodingConversionResult>;
    function GetName: string;
  public
    class function OptionsFromInterface(const Options: IEncodingConversionOptions): TEncodingConversionOptions; static;
  end;

  { UTF-8 ¼ì²âÆ÷ÊÊÅäÆ÷ }
  TUTF8EncodingDetectorAdapter = class(TInterfacedObject, IEncodingDetector)
  private
    FMinConfidence: Double;
    function DetectBuffer(const Buffer: TBytes): IEncodingDetectionResult;
    function DetectFile(const FileName: string): IEncodingDetectionResult;
    function DetectStream(const Stream: TStream): IEncodingDetectionResult;
    function GetName: string;
    function GetMinConfidence: Double;
    procedure SetMinConfidence(const Value: Double);
  public
    constructor Create;
  end;

  { ÖÐÎÄ±àÂë¼ì²âÆ÷ÊÊÅäÆ÷ }
  TChineseEncodingDetectorAdapter = class(TInterfacedObject, IEncodingDetector)
  private
    FMinConfidence: Double;
    function DetectBuffer(const Buffer: TBytes): IEncodingDetectionResult;
    function DetectFile(const FileName: string): IEncodingDetectionResult;
    function DetectStream(const Stream: TStream): IEncodingDetectionResult;
    function GetName: string;
    function GetMinConfidence: Double;
    procedure SetMinConfidence(const Value: Double);
  public
    constructor Create;
  end;

  { ÈÕÎÄ±àÂë¼ì²âÆ÷ÊÊÅäÆ÷ }
  TJapaneseEncodingDetectorAdapter = class(TInterfacedObject, IEncodingDetector)
  private
    FMinConfidence: Double;
    function DetectBuffer(const Buffer: TBytes): IEncodingDetectionResult;
    function DetectFile(const FileName: string): IEncodingDetectionResult;
    function DetectStream(const Stream: TStream): IEncodingDetectionResult;
    function GetName: string;
    function GetMinConfidence: Double;
    procedure SetMinConfidence(const Value: Double);
  public
    constructor Create;
  end;

  { º«ÎÄ±àÂë¼ì²âÆ÷ÊÊÅäÆ÷ }
  TKoreanEncodingDetectorAdapter = class(TInterfacedObject, IEncodingDetector)
  private
    FMinConfidence: Double;
    function DetectBuffer(const Buffer: TBytes): IEncodingDetectionResult;
    function DetectFile(const FileName: string): IEncodingDetectionResult;
    function DetectStream(const Stream: TStream): IEncodingDetectionResult;
    function GetName: string;
    function GetMinConfidence: Double;
    procedure SetMinConfidence(const Value: Double);
  public
    constructor Create;
  end;

  { ±àÂë¼ì²âÆ÷¹¤³§ÊµÏÖ }
  TEncodingDetectorFactory = class(TInterfacedObject, IEncodingDetectorFactory)
  private
    FCreators: TDictionary<string, TFunc<IEncodingDetector>>;
  public
    constructor Create;
    destructor Destroy; override;
    function CreateDetector(const DetectorType: string): IEncodingDetector;
    procedure RegisterDetector(const DetectorType: string; const Creator: TFunc<IEncodingDetector>);
    function GetRegisteredTypes: TArray<string>;
  end;

  { ±àÂë×ª»»Æ÷¹¤³§ÊµÏÖ }
  TEncodingConverterFactory = class(TInterfacedObject, IEncodingConverterFactory)
  public
    function CreateConverter: IEncodingConverter;
    function CreateOptions: IEncodingConversionOptions;
  end;

implementation

uses
  UtilsEncodingConfig;

{ TEncodingDetectionResultAdapter }

constructor TEncodingDetectionResultAdapter.Create(const AEncoding: string; AConfidence: Double;
  AHasBOM: Boolean; const ADetails: string);
begin
  inherited Create;
  FEncoding := AEncoding;
  FConfidence := AConfidence;
  FHasBOM := AHasBOM;
  FDetails := ADetails;
end;

function TEncodingDetectionResultAdapter.GetConfidence: Double;
begin
  Result := FConfidence;
end;

function TEncodingDetectionResultAdapter.GetDetails: string;
begin
  Result := FDetails;
end;

function TEncodingDetectionResultAdapter.GetEncoding: string;
begin
  Result := FEncoding;
end;

function TEncodingDetectionResultAdapter.GetHasBOM: Boolean;
begin
  Result := FHasBOM;
end;

{ TEncodingConversionResultAdapter }

constructor TEncodingConversionResultAdapter.Create(const AResult: TEncodingConversionResult);
var
  i: Integer;
  Msgs: TStringList;
begin
  inherited Create;
  FInner := AResult;
  FErrorMessage := '';

  if FInner.ErrorCount > 0 then
  begin
    Msgs := TStringList.Create;
    try
      for i := 0 to FInner.ErrorCount - 1 do
        Msgs.Add(FInner.Errors[i].ErrorMessage);
      FErrorMessage := Msgs.Text.TrimRight;
    finally
      Msgs.Free;
    end;
  end;
end;

function TEncodingConversionResultAdapter.GetBytesProcessed: Int64;
begin
  Result := FInner.BytesProcessed;
end;

function TEncodingConversionResultAdapter.GetErrorCount: Integer;
begin
  Result := FInner.ErrorCount;
end;

function TEncodingConversionResultAdapter.GetErrorMessage: string;
begin
  Result := FErrorMessage;
end;

function TEncodingConversionResultAdapter.GetOutputData: TBytes;
begin
  Result := FInner.OutputData;
end;

function TEncodingConversionResultAdapter.GetSourceEncoding: string;
begin
  Result := FInner.SourceEncoding;
end;

function TEncodingConversionResultAdapter.GetSuccess: Boolean;
begin
  Result := FInner.Success;
end;

function TEncodingConversionResultAdapter.GetTargetEncoding: string;
begin
  Result := FInner.TargetEncoding;
end;

{ TEncodingConversionOptionsAdapter }

constructor TEncodingConversionOptionsAdapter.Create(const AOptions: TEncodingConversionOptions);
begin
  inherited Create;
  FOptions := AOptions;
end;

constructor TEncodingConversionOptionsAdapter.CreateDefault;
begin
  inherited Create;
  FOptions := TEncodingConverter_Improved.CreateDefaultOptions;
end;

function TEncodingConversionOptionsAdapter.GetAddBOM: Boolean;
begin
  Result := FOptions.AddBOM;
end;

function TEncodingConversionOptionsAdapter.GetDetectSourceEncoding: Boolean;
begin
  Result := FOptions.DetectSourceEncoding;
end;

function TEncodingConversionOptionsAdapter.GetMaxErrorCount: Integer;
begin
  Result := FOptions.MaxErrorCount;
end;

procedure TEncodingConversionOptionsAdapter.SetAddBOM(const Value: Boolean);
begin
  FOptions.AddBOM := Value;
end;

procedure TEncodingConversionOptionsAdapter.SetDetectSourceEncoding(const Value: Boolean);
begin
  FOptions.DetectSourceEncoding := Value;
end;

procedure TEncodingConversionOptionsAdapter.SetMaxErrorCount(const Value: Integer);
begin
  FOptions.MaxErrorCount := Value;
end;

function TEncodingConversionOptionsAdapter.ToRecord: TEncodingConversionOptions;
begin
  Result := FOptions;
end;

{ TEncodingConverterAdapter }

class function TEncodingConverterAdapter.OptionsFromInterface(
  const Options: IEncodingConversionOptions): TEncodingConversionOptions;
var
  Adapter: TEncodingConversionOptionsAdapter;
begin
  if Options = nil then
  begin
    Result := TEncodingConverter_Improved.CreateDefaultOptions;
    Exit;
  end;

  // ÓÅÏÈ³¢ÊÔ½«½Ó¿Ú×ª»»ÎªÎÒÃÇ×Ô¼ºµÄÊÊÅäÆ÷ÀàÐÍ
  if TObject(Options) is TEncodingConversionOptionsAdapter then
  begin
    Adapter := TEncodingConversionOptionsAdapter(TObject(Options));
    Result := Adapter.ToRecord;
  end
  else
  begin
    // ¶µµ×£ºÍ¨¹ý½Ó¿ÚÊôÐÔ¹¹Ôì¼ÇÂ¼
    Result := TEncodingConverter_Improved.CreateDefaultOptions;
    Result.AddBOM := Options.AddBOM;
    Result.DetectSourceEncoding := Options.DetectSourceEncoding;
    Result.MaxErrorCount := Options.MaxErrorCount;
  end;
end;

function TEncodingConverterAdapter.BatchConvertFiles(const FileNames: TArray<string>;
  const TargetDir, TargetEncoding: string;
  const Options: IEncodingConversionOptions): TArray<IEncodingConversionResult>;
var
  RecOptions: TEncodingConversionOptions;
  RawResults: TArray<TEncodingConversionResult>;
  i: Integer;
begin
  RecOptions := OptionsFromInterface(Options);
  RawResults := TEncodingConverter_Improved.BatchConvertFiles(FileNames, TargetDir, TargetEncoding, RecOptions);
  SetLength(Result, Length(RawResults));
  for i := 0 to High(RawResults) do
    Result[i] := TEncodingConversionResultAdapter.Create(RawResults[i]);
end;

function TEncodingConverterAdapter.ConvertBuffer(const Buffer: TBytes;
  const SourceEncoding, TargetEncoding: string;
  const Options: IEncodingConversionOptions): IEncodingConversionResult;
var
  RecOptions: TEncodingConversionOptions;
  Raw: TEncodingConversionResult;
begin
  RecOptions := OptionsFromInterface(Options);
  Raw := TEncodingConverter_Improved.ConvertBuffer(Buffer, SourceEncoding, TargetEncoding, RecOptions);
  Result := TEncodingConversionResultAdapter.Create(Raw);
end;

function TEncodingConverterAdapter.ConvertFile(const SourceFileName,
  TargetFileName, SourceEncoding, TargetEncoding: string;
  const Options: IEncodingConversionOptions): IEncodingConversionResult;
var
  RecOptions: TEncodingConversionOptions;
  Raw: TEncodingConversionResult;
begin
  RecOptions := OptionsFromInterface(Options);
  Raw := TEncodingConverter_Improved.ConvertFile(SourceFileName, TargetFileName, SourceEncoding, TargetEncoding, RecOptions);
  Result := TEncodingConversionResultAdapter.Create(Raw);
end;

function TEncodingConverterAdapter.ConvertStream(const SourceStream,
  TargetStream: TStream; const SourceEncoding, TargetEncoding: string;
  const Options: IEncodingConversionOptions): IEncodingConversionResult;
var
  RecOptions: TEncodingConversionOptions;
  Raw: TEncodingConversionResult;
begin
  RecOptions := OptionsFromInterface(Options);
  Raw := TEncodingConverter_Improved.ConvertStream(SourceStream, TargetStream, SourceEncoding, TargetEncoding, RecOptions);
  Result := TEncodingConversionResultAdapter.Create(Raw);
end;

function TEncodingConverterAdapter.GetName: string;
begin
  Result := 'DefaultEncodingConverter';
end;

{ TUTF8EncodingDetectorAdapter }

constructor TUTF8EncodingDetectorAdapter.Create;
begin
  inherited Create;
  FMinConfidence := TEncodingDetectionConfig.MinUTF8Confidence;
end;

function TUTF8EncodingDetectorAdapter.DetectBuffer(
  const Buffer: TBytes): IEncodingDetectionResult;
var
  R: TUTF8DetectionResult;
  Enc: string;
  Details: string;
begin
  R := TUTF8EncodingDetector_Improved.DetectBuffer(Buffer);
  if R.IsUTF8 then
    Enc := ENCODING_UTF8
  else
    Enc := ENCODING_ANSI;

  Details := Format('UTF8 Conf=%.3f; Valid=%d; Invalid=%d; Len=%d',
    [R.Confidence, R.ValidByteCount, R.InvalidByteCount, R.TotalByteCount]);

  Result := TEncodingDetectionResultAdapter.Create(Enc, R.Confidence, R.HasBOM, Details);
end;

function TUTF8EncodingDetectorAdapter.DetectFile(
  const FileName: string): IEncodingDetectionResult;
var
  R: TUTF8DetectionResult;
  Enc: string;
  Details: string;
begin
  R := TUTF8EncodingDetector_Improved.DetectFile(FileName);
  if R.IsUTF8 then
    Enc := ENCODING_UTF8
  else
    Enc := ENCODING_ANSI;

  Details := Format('UTF8 Conf=%.3f; Valid=%d; Invalid=%d; Len=%d',
    [R.Confidence, R.ValidByteCount, R.InvalidByteCount, R.TotalByteCount]);

  Result := TEncodingDetectionResultAdapter.Create(Enc, R.Confidence, R.HasBOM, Details);
end;

function TUTF8EncodingDetectorAdapter.DetectStream(
  const Stream: TStream): IEncodingDetectionResult;
var
  R: TUTF8DetectionResult;
  Enc: string;
  Details: string;
begin
  R := TUTF8EncodingDetector_Improved.DetectStream(Stream);
  if R.IsUTF8 then
    Enc := ENCODING_UTF8
  else
    Enc := ENCODING_ANSI;

  Details := Format('UTF8 Conf=%.3f; Valid=%d; Invalid=%d; Len=%d',
    [R.Confidence, R.ValidByteCount, R.InvalidByteCount, R.TotalByteCount]);

  Result := TEncodingDetectionResultAdapter.Create(Enc, R.Confidence, R.HasBOM, Details);
end;

function TUTF8EncodingDetectorAdapter.GetMinConfidence: Double;
begin
  Result := FMinConfidence;
end;

function TUTF8EncodingDetectorAdapter.GetName: string;
begin
  Result := 'UTF8';
end;

procedure TUTF8EncodingDetectorAdapter.SetMinConfidence(const Value: Double);
begin
  FMinConfidence := Value;
end;

{ TChineseEncodingDetectorAdapter }

constructor TChineseEncodingDetectorAdapter.Create;
begin
  inherited Create;
  FMinConfidence := TEncodingDetectionConfig.MinChineseConfidence;
end;

function TChineseEncodingDetectorAdapter.DetectBuffer(
  const Buffer: TBytes): IEncodingDetectionResult;
var
  R: TChineseEncodingResult;
  Details: string;
begin
  R := TChineseEncodingDetector_Improved.DetectBuffer(Buffer);
  Details := Format('GBK=%.3f; GB18030=%.3f; Big5=%.3f; GB2312=%.3f; UTF8=%.3f',
    [R.GBKConfidence, R.GB18030Confidence, R.Big5Confidence, R.GB2312Confidence, R.UTF8Confidence]);
  Result := TEncodingDetectionResultAdapter.Create(R.Encoding, R.Confidence, R.HasBOM, Details);
end;

function TChineseEncodingDetectorAdapter.DetectFile(
  const FileName: string): IEncodingDetectionResult;
var
  R: TChineseEncodingResult;
  Details: string;
begin
  R := TChineseEncodingDetector_Improved.DetectFile(FileName);
  Details := Format('GBK=%.3f; GB18030=%.3f; Big5=%.3f; GB2312=%.3f; UTF8=%.3f',
    [R.GBKConfidence, R.GB18030Confidence, R.Big5Confidence, R.GB2312Confidence, R.UTF8Confidence]);
  Result := TEncodingDetectionResultAdapter.Create(R.Encoding, R.Confidence, R.HasBOM, Details);
end;

function TChineseEncodingDetectorAdapter.DetectStream(
  const Stream: TStream): IEncodingDetectionResult;
var
  R: TChineseEncodingResult;
  Details: string;
begin
  R := TChineseEncodingDetector_Improved.DetectStream(Stream);
  Details := Format('GBK=%.3f; GB18030=%.3f; Big5=%.3f; GB2312=%.3f; UTF8=%.3f',
    [R.GBKConfidence, R.GB18030Confidence, R.Big5Confidence, R.GB2312Confidence, R.UTF8Confidence]);
  Result := TEncodingDetectionResultAdapter.Create(R.Encoding, R.Confidence, R.HasBOM, Details);
end;

function TChineseEncodingDetectorAdapter.GetMinConfidence: Double;
begin
  Result := FMinConfidence;
end;

function TChineseEncodingDetectorAdapter.GetName: string;
begin
  Result := 'Chinese';
end;

procedure TChineseEncodingDetectorAdapter.SetMinConfidence(const Value: Double);
begin
  FMinConfidence := Value;
end;

{ TJapaneseEncodingDetectorAdapter }

constructor TJapaneseEncodingDetectorAdapter.Create;
begin
  inherited Create;
  FMinConfidence := TEncodingDetectionConfig.MinJapaneseConfidence;
end;

function TJapaneseEncodingDetectorAdapter.DetectBuffer(
  const Buffer: TBytes): IEncodingDetectionResult;
var
  R: TJapaneseEncodingResult;
  Details: string;
begin
  R := TJapaneseEncodingDetector_Improved.DetectBuffer(Buffer);
  Details := Format('ShiftJIS=%.3f; EUC-JP=%.3f; ISO-2022-JP=%.3f',
    [R.ShiftJISConfidence, R.EUCJPConfidence, R.ISO2022JPConfidence]);
  Result := TEncodingDetectionResultAdapter.Create(R.Encoding, R.Confidence, R.HasBOM, Details);
end;

function TJapaneseEncodingDetectorAdapter.DetectFile(
  const FileName: string): IEncodingDetectionResult;
var
  R: TJapaneseEncodingResult;
  Details: string;
begin
  R := TJapaneseEncodingDetector_Improved.DetectFile(FileName);
  Details := Format('ShiftJIS=%.3f; EUC-JP=%.3f; ISO-2022-JP=%.3f',
    [R.ShiftJISConfidence, R.EUCJPConfidence, R.ISO2022JPConfidence]);
  Result := TEncodingDetectionResultAdapter.Create(R.Encoding, R.Confidence, R.HasBOM, Details);
end;

function TJapaneseEncodingDetectorAdapter.DetectStream(
  const Stream: TStream): IEncodingDetectionResult;
var
  R: TJapaneseEncodingResult;
  Details: string;
begin
  R := TJapaneseEncodingDetector_Improved.DetectStream(Stream);
  Details := Format('ShiftJIS=%.3f; EUC-JP=%.3f; ISO-2022-JP=%.3f',
    [R.ShiftJISConfidence, R.EUCJPConfidence, R.ISO2022JPConfidence]);
  Result := TEncodingDetectionResultAdapter.Create(R.Encoding, R.Confidence, R.HasBOM, Details);
end;

function TJapaneseEncodingDetectorAdapter.GetMinConfidence: Double;
begin
  Result := FMinConfidence;
end;

function TJapaneseEncodingDetectorAdapter.GetName: string;
begin
  Result := 'Japanese';
end;

procedure TJapaneseEncodingDetectorAdapter.SetMinConfidence(const Value: Double);
begin
  FMinConfidence := Value;
end;

{ TKoreanEncodingDetectorAdapter }

constructor TKoreanEncodingDetectorAdapter.Create;
begin
  inherited Create;
  FMinConfidence := TEncodingDetectionConfig.MinKoreanConfidence;
end;

function TKoreanEncodingDetectorAdapter.DetectBuffer(
  const Buffer: TBytes): IEncodingDetectionResult;
var
  R: TKoreanEncodingResult;
  Details: string;
begin
  R := TKoreanEncodingDetector_Improved.DetectBuffer(Buffer);
  Details := Format('EUC-KR=%.3f; UHC=%.3f; ISO-2022-KR=%.3f',
    [R.EUCKRConfidence, R.UHCConfidence, R.ISO2022KRConfidence]);
  Result := TEncodingDetectionResultAdapter.Create(R.Encoding, R.Confidence, R.HasBOM, Details);
end;

function TKoreanEncodingDetectorAdapter.DetectFile(
  const FileName: string): IEncodingDetectionResult;
var
  R: TKoreanEncodingResult;
  Details: string;
begin
  R := TKoreanEncodingDetector_Improved.DetectFile(FileName);
  Details := Format('EUC-KR=%.3f; UHC=%.3f; ISO-2022-KR=%.3f',
    [R.EUCKRConfidence, R.UHCConfidence, R.ISO2022KRConfidence]);
  Result := TEncodingDetectionResultAdapter.Create(R.Encoding, R.Confidence, R.HasBOM, Details);
end;

function TKoreanEncodingDetectorAdapter.DetectStream(
  const Stream: TStream): IEncodingDetectionResult;
var
  R: TKoreanEncodingResult;
  Details: string;
begin
  R := TKoreanEncodingDetector_Improved.DetectStream(Stream);
  Details := Format('EUC-KR=%.3f; UHC=%.3f; ISO-2022-KR=%.3f',
    [R.EUCKRConfidence, R.UHCConfidence, R.ISO2022KRConfidence]);
  Result := TEncodingDetectionResultAdapter.Create(R.Encoding, R.Confidence, R.HasBOM, Details);
end;

function TKoreanEncodingDetectorAdapter.GetMinConfidence: Double;
begin
  Result := FMinConfidence;
end;

function TKoreanEncodingDetectorAdapter.GetName: string;
begin
  Result := 'Korean';
end;

procedure TKoreanEncodingDetectorAdapter.SetMinConfidence(const Value: Double);
begin
  FMinConfidence := Value;
end;

{ TEncodingDetectorFactory }

constructor TEncodingDetectorFactory.Create;
begin
  inherited Create;
  FCreators := TDictionary<string, TFunc<IEncodingDetector>>.Create;

  // ×¢²áÄÚÖÃ¼ì²âÆ÷
  RegisterDetector('UTF8',
    function: IEncodingDetector
    begin
      Result := TUTF8EncodingDetectorAdapter.Create;
    end);

  RegisterDetector('Chinese',
    function: IEncodingDetector
    begin
      Result := TChineseEncodingDetectorAdapter.Create;
    end);

  RegisterDetector('Japanese',
    function: IEncodingDetector
    begin
      Result := TJapaneseEncodingDetectorAdapter.Create;
    end);

  RegisterDetector('Korean',
    function: IEncodingDetector
    begin
      Result := TKoreanEncodingDetectorAdapter.Create;
    end);
end;

destructor TEncodingDetectorFactory.Destroy;
begin
  FCreators.Free;
  inherited;
end;

function TEncodingDetectorFactory.CreateDetector(
  const DetectorType: string): IEncodingDetector;
var
  Creator: TFunc<IEncodingDetector>;
begin
  Result := nil;
  if FCreators.TryGetValue(DetectorType, Creator) then
    Result := Creator();
end;

function TEncodingDetectorFactory.GetRegisteredTypes: TArray<string>;
begin
  Result := FCreators.Keys.ToArray;
end;

procedure TEncodingDetectorFactory.RegisterDetector(const DetectorType: string;
  const Creator: TFunc<IEncodingDetector>);
begin
  if DetectorType = '' then
    Exit;
  FCreators.AddOrSetValue(DetectorType, Creator);
end;

{ TEncodingConverterFactory }

function TEncodingConverterFactory.CreateConverter: IEncodingConverter;
begin
  Result := TEncodingConverterAdapter.Create;
end;

function TEncodingConverterFactory.CreateOptions: IEncodingConversionOptions;
begin
  Result := TEncodingConversionOptionsAdapter.CreateDefault;
end;

end.
