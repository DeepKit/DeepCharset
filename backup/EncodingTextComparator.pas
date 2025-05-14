unit EncodingTextComparator;

{
  EncodingTextComparator.pas
  实现原文和转码后文本比较功能
  
  作为improve.md中任务2.2.2的实现
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Math;

type
  /// <summary>
  /// 文本比较结果
  /// </summary>
  TTextComparisonResult = record
    IsIdentical: Boolean;          // 是否完全相同
    DifferenceCount: Integer;      // 差异字符数
    DifferencePercentage: Double;  // 差异百分比
    SourceLength: Integer;         // 源文本长度
    TargetLength: Integer;         // 目标文本长度
    LengthDifference: Integer;     // 长度差异
    
    constructor Create(AIsIdentical: Boolean; ADifferenceCount, ASourceLength, ATargetLength: Integer);
  end;
  
  /// <summary>
  /// 文本比较器
  /// </summary>
  TEncodingTextComparator = class
  private
    FLogCallback: TProc<string>;
    
    procedure Log(const Msg: string);
    function CalculateDifferencePercentage(DifferenceCount, TotalCount: Integer): Double;
  public
    constructor Create(ALogCallback: TProc<string> = nil);
    
    /// <summary>
    /// 比较两个文本文件
    /// </summary>
    function CompareTextFiles(const SourceFilePath, TargetFilePath: string): TTextComparisonResult;
    
    /// <summary>
    /// 比较两个文本字符串
    /// </summary>
    function CompareTextStrings(const SourceText, TargetText: string): TTextComparisonResult;
    
    /// <summary>
    /// 比较两个字节数组
    /// </summary>
    function CompareByteArrays(const SourceBytes, TargetBytes: TBytes): TTextComparisonResult;
    
    /// <summary>
    /// 日志回调
    /// </summary>
    property LogCallback: TProc<string> read FLogCallback write FLogCallback;
  end;

implementation

uses
  System.IOUtils;

{ TTextComparisonResult }

constructor TTextComparisonResult.Create(AIsIdentical: Boolean; ADifferenceCount, ASourceLength, ATargetLength: Integer);
begin
  IsIdentical := AIsIdentical;
  DifferenceCount := ADifferenceCount;
  SourceLength := ASourceLength;
  TargetLength := ATargetLength;
  LengthDifference := ATargetLength - ASourceLength;
  
  if ASourceLength > 0 then
    DifferencePercentage := (ADifferenceCount / ASourceLength) * 100
  else
    DifferencePercentage := 0;
end;

{ TEncodingTextComparator }

constructor TEncodingTextComparator.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := ALogCallback;
end;

function TEncodingTextComparator.CalculateDifferencePercentage(DifferenceCount, TotalCount: Integer): Double;
begin
  if TotalCount > 0 then
    Result := (DifferenceCount / TotalCount) * 100
  else
    Result := 0;
end;

function TEncodingTextComparator.CompareByteArrays(const SourceBytes, TargetBytes: TBytes): TTextComparisonResult;
var
  MinLength, I: Integer;
  DifferenceCount: Integer;
  IsIdentical: Boolean;
begin
  DifferenceCount := 0;
  
  // 比较长度
  if Length(SourceBytes) <> Length(TargetBytes) then
    Inc(DifferenceCount, Abs(Length(SourceBytes) - Length(TargetBytes)));
  
  // 比较内容
  MinLength := Min(Length(SourceBytes), Length(TargetBytes));
  for I := 0 to MinLength - 1 do
  begin
    if SourceBytes[I] <> TargetBytes[I] then
      Inc(DifferenceCount);
  end;
  
  IsIdentical := DifferenceCount = 0;
  
  Result := TTextComparisonResult.Create(
    IsIdentical, DifferenceCount, Length(SourceBytes), Length(TargetBytes));
  
  Log(Format('比较字节数组: 相同=%s, 差异字符数=%d, 差异百分比=%.2f%%', 
    [BoolToStr(IsIdentical, True), DifferenceCount, Result.DifferencePercentage]));
end;

function TEncodingTextComparator.CompareTextFiles(const SourceFilePath, TargetFilePath: string): TTextComparisonResult;
var
  SourceBytes, TargetBytes: TBytes;
begin
  try
    // 读取文件内容
    SourceBytes := TFile.ReadAllBytes(SourceFilePath);
    TargetBytes := TFile.ReadAllBytes(TargetFilePath);
    
    // 比较字节数组
    Result := CompareByteArrays(SourceBytes, TargetBytes);
    
    Log(Format('比较文件: %s 和 %s', [ExtractFileName(SourceFilePath), ExtractFileName(TargetFilePath)]));
  except
    on E: Exception do
    begin
      Log(Format('比较文件失败: %s', [E.Message]));
      Result := TTextComparisonResult.Create(False, 0, 0, 0);
    end;
  end;
end;

function TEncodingTextComparator.CompareTextStrings(const SourceText, TargetText: string): TTextComparisonResult;
var
  MinLength, I: Integer;
  DifferenceCount: Integer;
  IsIdentical: Boolean;
begin
  DifferenceCount := 0;
  
  // 比较长度
  if Length(SourceText) <> Length(TargetText) then
    Inc(DifferenceCount, Abs(Length(SourceText) - Length(TargetText)));
  
  // 比较内容
  MinLength := Min(Length(SourceText), Length(TargetText));
  for I := 1 to MinLength do
  begin
    if SourceText[I] <> TargetText[I] then
      Inc(DifferenceCount);
  end;
  
  IsIdentical := DifferenceCount = 0;
  
  Result := TTextComparisonResult.Create(
    IsIdentical, DifferenceCount, Length(SourceText), Length(TargetText));
  
  Log(Format('比较文本字符串: 相同=%s, 差异字符数=%d, 差异百分比=%.2f%%', 
    [BoolToStr(IsIdentical, True), DifferenceCount, Result.DifferencePercentage]));
end;

procedure TEncodingTextComparator.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

end.
