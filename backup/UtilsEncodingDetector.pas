unit UtilsEncodingDetector;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Math,
  UtilsEncodingTypes, ChineseEncodingFeatureDB;

type
  TEncodingDetector = class
  private
    FFeatureDB: TChineseEncodingFeatureDB;
    FMinConfidence: Double;
    FMaxSampleSize: Integer;
    
    function AnalyzeFileContent(const FileName: string): TEncodingAnalysisResult;
    function CalculateEncodingConfidence(const Result: TEncodingAnalysisResult): Double;
    function IsValidEncoding(const Result: TEncodingAnalysisResult): Boolean;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 检测文件编码
    function DetectEncoding(const FileName: string): TEncodingInfo;
    
    // 配置选项
    property MinConfidence: Double read FMinConfidence write FMinConfidence;
    property MaxSampleSize: Integer read FMaxSampleSize write FMaxSampleSize;
  end;

implementation

{ TEncodingDetector }

constructor TEncodingDetector.Create;
begin
  inherited;
  FFeatureDB := TChineseEncodingFeatureDB.Create;
  FMinConfidence := 0.8;  // 默认最小置信度
  FMaxSampleSize := 1024 * 1024;  // 默认最大采样大小1MB
end;

destructor TEncodingDetector.Destroy;
begin
  FFeatureDB.Free;
  inherited;
end;

function TEncodingDetector.AnalyzeFileContent(const FileName: string): TEncodingAnalysisResult;
var
  Stream: TFileStream;
  Buffer: TBytes;
  Size: Integer;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    Size := Min(Stream.Size, FMaxSampleSize);
    SetLength(Buffer, Size);
    Stream.ReadBuffer(Buffer[0], Size);
    
    // 使用特征数据库分析内容
    Result := FFeatureDB.AnalyzeContent(Buffer);
  finally
    Stream.Free;
  end;
end;

function TEncodingDetector.CalculateEncodingConfidence(const Result: TEncodingAnalysisResult): Double;
var
  TotalWeight: Double;
  WeightedSum: Double;
begin
  TotalWeight := 0;
  WeightedSum := 0;
  
  // 计算特征匹配度
  if Result.UTF8Match > 0 then
  begin
    TotalWeight := TotalWeight + 1;
    WeightedSum := WeightedSum + Result.UTF8Match;
  end;
  
  if Result.GBKMatch > 0 then
  begin
    TotalWeight := TotalWeight + 1;
    WeightedSum := WeightedSum + Result.GBKMatch;
  end;
  
  if Result.Big5Match > 0 then
  begin
    TotalWeight := TotalWeight + 1;
    WeightedSum := WeightedSum + Result.Big5Match;
  end;
  
  if TotalWeight > 0 then
    Result := WeightedSum / TotalWeight
  else
    Result := 0;
end;

function TEncodingDetector.IsValidEncoding(const Result: TEncodingAnalysisResult): Boolean;
begin
  // 检查是否有足够的特征匹配
  Result := (Result.UTF8Match > 0) or (Result.GBKMatch > 0) or (Result.Big5Match > 0);
end;

function TEncodingDetector.DetectEncoding(const FileName: string): TEncodingInfo;
var
  AnalysisResult: TEncodingAnalysisResult;
  Confidence: Double;
begin
  // 分析文件内容
  AnalysisResult := AnalyzeFileContent(FileName);
  
  // 计算置信度
  Confidence := CalculateEncodingConfidence(AnalysisResult);
  
  // 确定最可能的编码
  if Confidence >= FMinConfidence then
  begin
    if AnalysisResult.UTF8Match >= AnalysisResult.GBKMatch then
      Result.Encoding := 'UTF-8'
    else if AnalysisResult.GBKMatch >= AnalysisResult.Big5Match then
      Result.Encoding := 'GBK'
    else
      Result.Encoding := 'Big5';
      
    Result.Confidence := Confidence;
    Result.IsValid := True;
  end
  else
  begin
    Result.Encoding := 'Unknown';
    Result.Confidence := Confidence;
    Result.IsValid := False;
  end;
end;

end. 