unit EncodingCycleConverter;

{
  EncodingCycleConverter.pas
  实现A→B→A循环转码测试流程
  
  作为improve.md中任务2.2.1的实现
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Math;

type
  /// <summary>
  /// 循环转码结果
  /// </summary>
  TCycleConversionResult = record
    SourceEncoding: string;        // 源编码
    IntermediateEncoding: string;  // 中间编码
    IsReversible: Boolean;         // 是否可逆
    DifferenceCount: Integer;      // 差异字符数
    DifferencePercentage: Double;  // 差异百分比
    SourceSize: Integer;           // 源文件大小（字节）
    IntermediateSize: Integer;     // 中间文件大小（字节）
    ResultSize: Integer;           // 结果文件大小（字节）
    ConversionTime: Int64;         // 转换耗时（毫秒）
    ErrorMessage: string;          // 错误信息（如果有）
    
    constructor Create(const ASourceEncoding, AIntermediateEncoding: string;
      AIsReversible: Boolean; ADifferenceCount: Integer; ASourceSize, AIntermediateSize, AResultSize: Integer;
      AConversionTime: Int64; const AErrorMessage: string = '');
  end;
  
  /// <summary>
  /// 循环转码测试器
  /// </summary>
  TEncodingCycleConverter = class
  private
    FLogCallback: TProc<string>;
    
    procedure Log(const Msg: string);
    function CompareContents(const SourceContent, ResultContent: TBytes): Integer;
    function CalculateDifferencePercentage(DifferenceCount, TotalCount: Integer): Double;
  public
    constructor Create(ALogCallback: TProc<string> = nil);
    
    /// <summary>
    /// 执行循环转码测试（A→B→A）
    /// </summary>
    function PerformCycleConversion(const SourceFilePath, TempFilePath: string;
      const SourceEncoding, IntermediateEncoding: string): TCycleConversionResult;
    
    /// <summary>
    /// 执行循环转码测试（内存版本）
    /// </summary>
    function PerformCycleConversionInMemory(const SourceContent: TBytes;
      const SourceEncoding, IntermediateEncoding: string): TCycleConversionResult;
    
    /// <summary>
    /// 批量执行循环转码测试
    /// </summary>
    function PerformBatchCycleConversion(const SourceFilePath: string;
      const IntermediateEncodings: TArray<string>): TArray<TCycleConversionResult>;
    
    /// <summary>
    /// 日志回调
    /// </summary>
    property LogCallback: TProc<string> read FLogCallback write FLogCallback;
  end;

implementation

uses
  System.Diagnostics, System.IOUtils;

{ TCycleConversionResult }

constructor TCycleConversionResult.Create(const ASourceEncoding, AIntermediateEncoding: string;
  AIsReversible: Boolean; ADifferenceCount: Integer; ASourceSize, AIntermediateSize, AResultSize: Integer;
  AConversionTime: Int64; const AErrorMessage: string);
begin
  SourceEncoding := ASourceEncoding;
  IntermediateEncoding := AIntermediateEncoding;
  IsReversible := AIsReversible;
  DifferenceCount := ADifferenceCount;
  SourceSize := ASourceSize;
  IntermediateSize := AIntermediateSize;
  ResultSize := AResultSize;
  ConversionTime := AConversionTime;
  ErrorMessage := AErrorMessage;
  
  if SourceSize > 0 then
    DifferencePercentage := (DifferenceCount / SourceSize) * 100
  else
    DifferencePercentage := 0;
end;

{ TEncodingCycleConverter }

constructor TEncodingCycleConverter.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := ALogCallback;
end;

function TEncodingCycleConverter.CalculateDifferencePercentage(DifferenceCount, TotalCount: Integer): Double;
begin
  if TotalCount > 0 then
    Result := (DifferenceCount / TotalCount) * 100
  else
    Result := 0;
end;

function TEncodingCycleConverter.CompareContents(const SourceContent, ResultContent: TBytes): Integer;
var
  MinLength, I: Integer;
begin
  Result := 0;
  
  // 比较长度
  if Length(SourceContent) <> Length(ResultContent) then
    Inc(Result, Abs(Length(SourceContent) - Length(ResultContent)));
  
  // 比较内容
  MinLength := Min(Length(SourceContent), Length(ResultContent));
  for I := 0 to MinLength - 1 do
  begin
    if SourceContent[I] <> ResultContent[I] then
      Inc(Result);
  end;
end;

procedure TEncodingCycleConverter.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

function TEncodingCycleConverter.PerformBatchCycleConversion(const SourceFilePath: string;
  const IntermediateEncodings: TArray<string>): TArray<TCycleConversionResult>;
var
  Results: TList<TCycleConversionResult>;
  SourceEncoding: string;
  IntermediateEncoding: string;
  TempFilePath: string;
  Result: TCycleConversionResult;
begin
  Results := TList<TCycleConversionResult>.Create;
  try
    // 获取源文件编码
    SourceEncoding := ''; // 这里应该调用编码检测函数
    if SourceEncoding = '' then
      SourceEncoding := 'UTF-8'; // 默认使用UTF-8
    
    // 创建临时文件路径
    TempFilePath := ChangeFileExt(SourceFilePath, '.temp' + ExtractFileExt(SourceFilePath));
    
    // 对每个中间编码执行循环转码测试
    for IntermediateEncoding in IntermediateEncodings do
    begin
      Log(Format('执行循环转码测试: %s → %s → %s', [SourceEncoding, IntermediateEncoding, SourceEncoding]));
      
      Result := PerformCycleConversion(SourceFilePath, TempFilePath, SourceEncoding, IntermediateEncoding);
      Results.Add(Result);
      
      Log(Format('测试结果: 可逆=%s, 差异字符数=%d, 差异百分比=%.2f%%', 
        [BoolToStr(Result.IsReversible, True), Result.DifferenceCount, Result.DifferencePercentage]));
    end;
    
    System.Result := Results.ToArray;
  finally
    Results.Free;
    
    // 删除临时文件
    if FileExists(TempFilePath) then
      DeleteFile(TempFilePath);
  end;
end;

function TEncodingCycleConverter.PerformCycleConversion(const SourceFilePath, TempFilePath: string;
  const SourceEncoding, IntermediateEncoding: string): TCycleConversionResult;
var
  SourceContent, IntermediateContent, ResultContent: TBytes;
  DifferenceCount: Integer;
  IsReversible: Boolean;
  SourceSize, IntermediateSize, ResultSize: Integer;
  StopWatch: TStopwatch;
  ErrorMsg: string;
begin
  StopWatch := TStopwatch.StartNew;
  ErrorMsg := '';
  
  try
    // 读取源文件内容
    SourceContent := TFile.ReadAllBytes(SourceFilePath);
    SourceSize := Length(SourceContent);
    
    // 第一次转换：源编码 → 中间编码
    try
      // 这里应该调用编码转换函数
      // IntermediateContent := ConvertEncoding(SourceContent, SourceEncoding, IntermediateEncoding);
      
      // 临时实现：直接复制内容
      IntermediateContent := Copy(SourceContent, 0, Length(SourceContent));
      IntermediateSize := Length(IntermediateContent);
      
      // 保存中间文件
      TFile.WriteAllBytes(TempFilePath, IntermediateContent);
    except
      on E: Exception do
      begin
        ErrorMsg := Format('第一次转换失败: %s', [E.Message]);
        Log(ErrorMsg);
        
        Result := TCycleConversionResult.Create(
          SourceEncoding, IntermediateEncoding, False, 0, SourceSize, 0, 0, 0, ErrorMsg);
        Exit;
      end;
    end;
    
    // 第二次转换：中间编码 → 源编码
    try
      // 这里应该调用编码转换函数
      // ResultContent := ConvertEncoding(IntermediateContent, IntermediateEncoding, SourceEncoding);
      
      // 临时实现：直接复制内容
      ResultContent := Copy(IntermediateContent, 0, Length(IntermediateContent));
      ResultSize := Length(ResultContent);
    except
      on E: Exception do
      begin
        ErrorMsg := Format('第二次转换失败: %s', [E.Message]);
        Log(ErrorMsg);
        
        Result := TCycleConversionResult.Create(
          SourceEncoding, IntermediateEncoding, False, 0, SourceSize, IntermediateSize, 0, 0, ErrorMsg);
        Exit;
      end;
    end;
    
    // 比较源内容和结果内容
    DifferenceCount := CompareContents(SourceContent, ResultContent);
    IsReversible := DifferenceCount = 0;
    
    // 停止计时
    StopWatch.Stop;
    
    // 创建结果
    Result := TCycleConversionResult.Create(
      SourceEncoding, IntermediateEncoding, IsReversible, DifferenceCount,
      SourceSize, IntermediateSize, ResultSize, StopWatch.ElapsedMilliseconds, ErrorMsg);
  except
    on E: Exception do
    begin
      ErrorMsg := Format('循环转码测试失败: %s', [E.Message]);
      Log(ErrorMsg);
      
      Result := TCycleConversionResult.Create(
        SourceEncoding, IntermediateEncoding, False, 0, 0, 0, 0, 0, ErrorMsg);
    end;
  end;
end;

function TEncodingCycleConverter.PerformCycleConversionInMemory(const SourceContent: TBytes;
  const SourceEncoding, IntermediateEncoding: string): TCycleConversionResult;
var
  IntermediateContent, ResultContent: TBytes;
  DifferenceCount: Integer;
  IsReversible: Boolean;
  SourceSize, IntermediateSize, ResultSize: Integer;
  StopWatch: TStopwatch;
  ErrorMsg: string;
begin
  StopWatch := TStopwatch.StartNew;
  ErrorMsg := '';
  
  try
    SourceSize := Length(SourceContent);
    
    // 第一次转换：源编码 → 中间编码
    try
      // 这里应该调用编码转换函数
      // IntermediateContent := ConvertEncoding(SourceContent, SourceEncoding, IntermediateEncoding);
      
      // 临时实现：直接复制内容
      IntermediateContent := Copy(SourceContent, 0, Length(SourceContent));
      IntermediateSize := Length(IntermediateContent);
    except
      on E: Exception do
      begin
        ErrorMsg := Format('第一次转换失败: %s', [E.Message]);
        Log(ErrorMsg);
        
        Result := TCycleConversionResult.Create(
          SourceEncoding, IntermediateEncoding, False, 0, SourceSize, 0, 0, 0, ErrorMsg);
        Exit;
      end;
    end;
    
    // 第二次转换：中间编码 → 源编码
    try
      // 这里应该调用编码转换函数
      // ResultContent := ConvertEncoding(IntermediateContent, IntermediateEncoding, SourceEncoding);
      
      // 临时实现：直接复制内容
      ResultContent := Copy(IntermediateContent, 0, Length(IntermediateContent));
      ResultSize := Length(ResultContent);
    except
      on E: Exception do
      begin
        ErrorMsg := Format('第二次转换失败: %s', [E.Message]);
        Log(ErrorMsg);
        
        Result := TCycleConversionResult.Create(
          SourceEncoding, IntermediateEncoding, False, 0, SourceSize, IntermediateSize, 0, 0, ErrorMsg);
        Exit;
      end;
    end;
    
    // 比较源内容和结果内容
    DifferenceCount := CompareContents(SourceContent, ResultContent);
    IsReversible := DifferenceCount = 0;
    
    // 停止计时
    StopWatch.Stop;
    
    // 创建结果
    Result := TCycleConversionResult.Create(
      SourceEncoding, IntermediateEncoding, IsReversible, DifferenceCount,
      SourceSize, IntermediateSize, ResultSize, StopWatch.ElapsedMilliseconds, ErrorMsg);
  except
    on E: Exception do
    begin
      ErrorMsg := Format('循环转码测试失败: %s', [E.Message]);
      Log(ErrorMsg);
      
      Result := TCycleConversionResult.Create(
        SourceEncoding, IntermediateEncoding, False, 0, 0, 0, 0, 0, ErrorMsg);
    end;
  end;
end;

end.
