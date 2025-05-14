unit EncodingTestSampleManager;

{
  EncodingTestSampleManager.pas
  测试样本管理器，用于管理测试样本和测试结果
  
  作为improve.md中任务2.1.2的实现
}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  System.JSON, EncodingTestSampleLoader;

type
  /// <summary>
  /// 编码检测结果
  /// </summary>
  TEncodingDetectionResult = record
    DetectedEncoding: string;      // 检测到的编码
    ConfidenceScore: Double;       // 置信度评分（0-1）
    DetectionTime: Int64;          // 检测耗时（毫秒）
    IsCorrect: Boolean;            // 是否正确（与已知编码比较）
    ErrorMessage: string;          // 错误信息（如果有）
    
    constructor Create(const ADetectedEncoding: string; AConfidenceScore: Double;
      ADetectionTime: Int64; AIsCorrect: Boolean; const AErrorMessage: string = '');
  end;
  
  /// <summary>
  /// 编码转换结果
  /// </summary>
  TEncodingConversionResult = record
    SourceEncoding: string;        // 源编码
    TargetEncoding: string;        // 目标编码
    ConversionTime: Int64;         // 转换耗时（毫秒）
    IsSuccessful: Boolean;         // 是否成功
    ErrorMessage: string;          // 错误信息（如果有）
    
    constructor Create(const ASourceEncoding, ATargetEncoding: string;
      AConversionTime: Int64; AIsSuccessful: Boolean; const AErrorMessage: string = '');
  end;
  
  /// <summary>
  /// 测试样本管理器
  /// </summary>
  TEncodingTestSampleManager = class
  private
    FSampleLoader: TEncodingTestSampleLoader;
    FDetectionResults: TDictionary<string, TEncodingDetectionResult>;
    FConversionResults: TDictionary<string, TList<TEncodingConversionResult>>;
    FLogCallback: TProc<string>;
    
    procedure Log(const Msg: string);
  public
    constructor Create(ALogCallback: TProc<string> = nil);
    destructor Destroy; override;
    
    /// <summary>
    /// 加载测试样本
    /// </summary>
    procedure LoadSamples(const Directory: string; Recursive: Boolean = False);
    
    /// <summary>
    /// 加载测试样本元数据
    /// </summary>
    procedure LoadSampleMetadata(const FilePath: string);
    
    /// <summary>
    /// 保存测试样本元数据
    /// </summary>
    procedure SaveSampleMetadata(const FilePath: string);
    
    /// <summary>
    /// 添加编码检测结果
    /// </summary>
    procedure AddDetectionResult(const SamplePath: string; const Result: TEncodingDetectionResult);
    
    /// <summary>
    /// 添加编码转换结果
    /// </summary>
    procedure AddConversionResult(const SamplePath: string; const Result: TEncodingConversionResult);
    
    /// <summary>
    /// 获取编码检测结果
    /// </summary>
    function GetDetectionResult(const SamplePath: string; out Result: TEncodingDetectionResult): Boolean;
    
    /// <summary>
    /// 获取编码转换结果
    /// </summary>
    function GetConversionResults(const SamplePath: string): TArray<TEncodingConversionResult>;
    
    /// <summary>
    /// 清除所有结果
    /// </summary>
    procedure ClearResults;
    
    /// <summary>
    /// 保存检测结果到文件
    /// </summary>
    procedure SaveDetectionResultsToFile(const FilePath: string);
    
    /// <summary>
    /// 保存转换结果到文件
    /// </summary>
    procedure SaveConversionResultsToFile(const FilePath: string);
    
    /// <summary>
    /// 加载检测结果从文件
    /// </summary>
    procedure LoadDetectionResultsFromFile(const FilePath: string);
    
    /// <summary>
    /// 加载转换结果从文件
    /// </summary>
    procedure LoadConversionResultsFromFile(const FilePath: string);
    
    /// <summary>
    /// 生成检测结果统计报告
    /// </summary>
    function GenerateDetectionReport: string;
    
    /// <summary>
    /// 生成转换结果统计报告
    /// </summary>
    function GenerateConversionReport: string;
    
    /// <summary>
    /// 获取样本加载器
    /// </summary>
    property SampleLoader: TEncodingTestSampleLoader read FSampleLoader;
    
    /// <summary>
    /// 日志回调
    /// </summary>
    property LogCallback: TProc<string> read FLogCallback write FLogCallback;
  end;

implementation

{ TEncodingDetectionResult }

constructor TEncodingDetectionResult.Create(const ADetectedEncoding: string;
  AConfidenceScore: Double; ADetectionTime: Int64; AIsCorrect: Boolean;
  const AErrorMessage: string);
begin
  DetectedEncoding := ADetectedEncoding;
  ConfidenceScore := AConfidenceScore;
  DetectionTime := ADetectionTime;
  IsCorrect := AIsCorrect;
  ErrorMessage := AErrorMessage;
end;

{ TEncodingConversionResult }

constructor TEncodingConversionResult.Create(const ASourceEncoding,
  ATargetEncoding: string; AConversionTime: Int64; AIsSuccessful: Boolean;
  const AErrorMessage: string);
begin
  SourceEncoding := ASourceEncoding;
  TargetEncoding := ATargetEncoding;
  ConversionTime := AConversionTime;
  IsSuccessful := AIsSuccessful;
  ErrorMessage := AErrorMessage;
end;

{ TEncodingTestSampleManager }

constructor TEncodingTestSampleManager.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FSampleLoader := TEncodingTestSampleLoader.Create(ALogCallback);
  FDetectionResults := TDictionary<string, TEncodingDetectionResult>.Create;
  FConversionResults := TDictionary<string, TList<TEncodingConversionResult>>.Create;
  FLogCallback := ALogCallback;
end;

destructor TEncodingTestSampleManager.Destroy;
begin
  ClearResults;
  FDetectionResults.Free;
  FConversionResults.Free;
  FSampleLoader.Free;
  inherited;
end;

procedure TEncodingTestSampleManager.AddConversionResult(const SamplePath: string;
  const Result: TEncodingConversionResult);
var
  ResultsList: TList<TEncodingConversionResult>;
begin
  if not FConversionResults.TryGetValue(SamplePath, ResultsList) then
  begin
    ResultsList := TList<TEncodingConversionResult>.Create;
    FConversionResults.Add(SamplePath, ResultsList);
  end;
  
  ResultsList.Add(Result);
  
  Log(Format('添加转换结果: %s -> %s (%s)', [Result.SourceEncoding, Result.TargetEncoding, SamplePath]));
end;

procedure TEncodingTestSampleManager.AddDetectionResult(const SamplePath: string;
  const Result: TEncodingDetectionResult);
begin
  FDetectionResults.AddOrSetValue(SamplePath, Result);
  
  Log(Format('添加检测结果: %s (置信度: %.2f, 正确: %s)', 
    [Result.DetectedEncoding, Result.ConfidenceScore, BoolToStr(Result.IsCorrect, True)]));
end;

procedure TEncodingTestSampleManager.ClearResults;
var
  ResultsList: TList<TEncodingConversionResult>;
begin
  // 清除检测结果
  FDetectionResults.Clear;
  
  // 清除转换结果
  for ResultsList in FConversionResults.Values do
    ResultsList.Free;
  FConversionResults.Clear;
  
  Log('清除所有结果');
end;

function TEncodingTestSampleManager.GenerateConversionReport: string;
var
  SamplePath: string;
  ResultsList: TList<TEncodingConversionResult>;
  Result: TEncodingConversionResult;
  TotalCount, SuccessCount: Integer;
  TotalTime: Int64;
  SourceEncodings, TargetEncodings: TDictionary<string, Integer>;
  SourceEncoding, TargetEncoding: string;
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    TotalCount := 0;
    SuccessCount := 0;
    TotalTime := 0;
    SourceEncodings := TDictionary<string, Integer>.Create;
    TargetEncodings := TDictionary<string, Integer>.Create;
    
    try
      // 统计转换结果
      for SamplePath in FConversionResults.Keys do
      begin
        ResultsList := FConversionResults[SamplePath];
        for Result in ResultsList do
        begin
          Inc(TotalCount);
          if Result.IsSuccessful then
            Inc(SuccessCount);
          TotalTime := TotalTime + Result.ConversionTime;
          
          // 统计源编码
          if SourceEncodings.ContainsKey(Result.SourceEncoding) then
            SourceEncodings[Result.SourceEncoding] := SourceEncodings[Result.SourceEncoding] + 1
          else
            SourceEncodings.Add(Result.SourceEncoding, 1);
          
          // 统计目标编码
          if TargetEncodings.ContainsKey(Result.TargetEncoding) then
            TargetEncodings[Result.TargetEncoding] := TargetEncodings[Result.TargetEncoding] + 1
          else
            TargetEncodings.Add(Result.TargetEncoding, 1);
        end;
      end;
      
      // 生成报告
      SB.AppendLine('# 编码转换结果统计报告');
      SB.AppendLine('');
      SB.AppendLine('## 总体统计');
      SB.AppendLine('');
      SB.AppendLine(Format('- 总转换次数: %d', [TotalCount]));
      SB.AppendLine(Format('- 成功转换次数: %d', [SuccessCount]));
      SB.AppendLine(Format('- 成功率: %.2f%%', [SuccessCount / TotalCount * 100]));
      SB.AppendLine(Format('- 总耗时: %d 毫秒', [TotalTime]));
      SB.AppendLine(Format('- 平均耗时: %.2f 毫秒', [TotalTime / TotalCount]));
      SB.AppendLine('');
      
      // 源编码统计
      SB.AppendLine('## 源编码统计');
      SB.AppendLine('');
      SB.AppendLine('| 编码 | 次数 | 百分比 |');
      SB.AppendLine('|------|------|--------|');
      for SourceEncoding in SourceEncodings.Keys do
      begin
        SB.AppendLine(Format('| %s | %d | %.2f%% |', 
          [SourceEncoding, SourceEncodings[SourceEncoding], 
           SourceEncodings[SourceEncoding] / TotalCount * 100]));
      end;
      SB.AppendLine('');
      
      // 目标编码统计
      SB.AppendLine('## 目标编码统计');
      SB.AppendLine('');
      SB.AppendLine('| 编码 | 次数 | 百分比 |');
      SB.AppendLine('|------|------|--------|');
      for TargetEncoding in TargetEncodings.Keys do
      begin
        SB.AppendLine(Format('| %s | %d | %.2f%% |', 
          [TargetEncoding, TargetEncodings[TargetEncoding], 
           TargetEncodings[TargetEncoding] / TotalCount * 100]));
      end;
      SB.AppendLine('');
      
      // 详细结果
      SB.AppendLine('## 详细结果');
      SB.AppendLine('');
      SB.AppendLine('| 样本 | 源编码 | 目标编码 | 耗时(毫秒) | 结果 |');
      SB.AppendLine('|------|--------|----------|------------|------|');
      
      for SamplePath in FConversionResults.Keys do
      begin
        ResultsList := FConversionResults[SamplePath];
        for Result in ResultsList do
        begin
          SB.AppendLine(Format('| %s | %s | %s | %d | %s |', 
            [ExtractFileName(SamplePath), Result.SourceEncoding, Result.TargetEncoding, 
             Result.ConversionTime, IfThen(Result.IsSuccessful, '成功', '失败')]));
        end;
      end;
      
      System.Result := SB.ToString;
    finally
      SourceEncodings.Free;
      TargetEncodings.Free;
    end;
  finally
    SB.Free;
  end;
end;

function TEncodingTestSampleManager.GenerateDetectionReport: string;
var
  SamplePath: string;
  Result: TEncodingDetectionResult;
  TotalCount, CorrectCount: Integer;
  TotalTime, TotalConfidence: Double;
  Encodings: TDictionary<string, Integer>;
  Encoding: string;
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    TotalCount := 0;
    CorrectCount := 0;
    TotalTime := 0;
    TotalConfidence := 0;
    Encodings := TDictionary<string, Integer>.Create;
    
    try
      // 统计检测结果
      for SamplePath in FDetectionResults.Keys do
      begin
        Result := FDetectionResults[SamplePath];
        Inc(TotalCount);
        if Result.IsCorrect then
          Inc(CorrectCount);
        TotalTime := TotalTime + Result.DetectionTime;
        TotalConfidence := TotalConfidence + Result.ConfidenceScore;
        
        // 统计编码
        if Encodings.ContainsKey(Result.DetectedEncoding) then
          Encodings[Result.DetectedEncoding] := Encodings[Result.DetectedEncoding] + 1
        else
          Encodings.Add(Result.DetectedEncoding, 1);
      end;
      
      // 生成报告
      SB.AppendLine('# 编码检测结果统计报告');
      SB.AppendLine('');
      SB.AppendLine('## 总体统计');
      SB.AppendLine('');
      SB.AppendLine(Format('- 总样本数: %d', [TotalCount]));
      SB.AppendLine(Format('- 正确检测数: %d', [CorrectCount]));
      SB.AppendLine(Format('- 正确率: %.2f%%', [CorrectCount / TotalCount * 100]));
      SB.AppendLine(Format('- 总耗时: %.2f 毫秒', [TotalTime]));
      SB.AppendLine(Format('- 平均耗时: %.2f 毫秒', [TotalTime / TotalCount]));
      SB.AppendLine(Format('- 平均置信度: %.2f', [TotalConfidence / TotalCount]));
      SB.AppendLine('');
      
      // 编码统计
      SB.AppendLine('## 编码统计');
      SB.AppendLine('');
      SB.AppendLine('| 编码 | 次数 | 百分比 |');
      SB.AppendLine('|------|------|--------|');
      for Encoding in Encodings.Keys do
      begin
        SB.AppendLine(Format('| %s | %d | %.2f%% |', 
          [Encoding, Encodings[Encoding], Encodings[Encoding] / TotalCount * 100]));
      end;
      SB.AppendLine('');
      
      // 详细结果
      SB.AppendLine('## 详细结果');
      SB.AppendLine('');
      SB.AppendLine('| 样本 | 检测编码 | 置信度 | 耗时(毫秒) | 结果 |');
      SB.AppendLine('|------|----------|--------|------------|------|');
      
      for SamplePath in FDetectionResults.Keys do
      begin
        Result := FDetectionResults[SamplePath];
        SB.AppendLine(Format('| %s | %s | %.2f | %d | %s |', 
          [ExtractFileName(SamplePath), Result.DetectedEncoding, Result.ConfidenceScore, 
           Result.DetectionTime, IfThen(Result.IsCorrect, '正确', '错误')]));
      end;
      
      System.Result := SB.ToString;
    finally
      Encodings.Free;
    end;
  finally
    SB.Free;
  end;
end;

function TEncodingTestSampleManager.GetConversionResults(
  const SamplePath: string): TArray<TEncodingConversionResult>;
var
  ResultsList: TList<TEncodingConversionResult>;
begin
  if FConversionResults.TryGetValue(SamplePath, ResultsList) then
    Result := ResultsList.ToArray
  else
    Result := [];
end;

function TEncodingTestSampleManager.GetDetectionResult(const SamplePath: string;
  out Result: TEncodingDetectionResult): Boolean;
begin
  System.Result := FDetectionResults.TryGetValue(SamplePath, Result);
end;

procedure TEncodingTestSampleManager.LoadConversionResultsFromFile(
  const FilePath: string);
var
  Json: TJSONObject;
  JsonArray: TJSONArray;
  JsonValue: TJSONValue;
  SamplePath: string;
  ResultsArray: TJSONArray;
  ResultJson: TJSONObject;
  Result: TEncodingConversionResult;
  I, J: Integer;
begin
  if not FileExists(FilePath) then
    Exit;
  
  // 清除现有结果
  for var ResultsList in FConversionResults.Values do
    ResultsList.Free;
  FConversionResults.Clear;
  
  try
    Json := TJSONObject.ParseJSONValue(TFile.ReadAllText(FilePath)) as TJSONObject;
    try
      if Json = nil then
        Exit;
      
      JsonArray := Json.GetValue('results') as TJSONArray;
      if JsonArray = nil then
        Exit;
      
      for I := 0 to JsonArray.Count - 1 do
      begin
        JsonValue := JsonArray.Items[I];
        if JsonValue is TJSONObject then
        begin
          SamplePath := (JsonValue as TJSONObject).GetValue('samplePath').Value;
          ResultsArray := (JsonValue as TJSONObject).GetValue('conversionResults') as TJSONArray;
          
          if ResultsArray <> nil then
          begin
            for J := 0 to ResultsArray.Count - 1 do
            begin
              ResultJson := ResultsArray.Items[J] as TJSONObject;
              if ResultJson <> nil then
              begin
                Result.SourceEncoding := ResultJson.GetValue('sourceEncoding').Value;
                Result.TargetEncoding := ResultJson.GetValue('targetEncoding').Value;
                Result.ConversionTime := StrToInt64Def(ResultJson.GetValue('conversionTime').Value, 0);
                Result.IsSuccessful := ResultJson.GetValue('isSuccessful').Value.ToLower = 'true';
                Result.ErrorMessage := ResultJson.GetValue('errorMessage').Value;
                
                AddConversionResult(SamplePath, Result);
              end;
            end;
          end;
        end;
      end;
      
      Log(Format('从文件加载了 %d 个样本的转换结果', [FConversionResults.Count]));
    finally
      Json.Free;
    end;
  except
    on E: Exception do
      Log('加载转换结果时出错: ' + E.Message);
  end;
end;

procedure TEncodingTestSampleManager.LoadDetectionResultsFromFile(
  const FilePath: string);
var
  Json: TJSONObject;
  JsonArray: TJSONArray;
  JsonValue: TJSONValue;
  SamplePath: string;
  Result: TEncodingDetectionResult;
  I: Integer;
begin
  if not FileExists(FilePath) then
    Exit;
  
  // 清除现有结果
  FDetectionResults.Clear;
  
  try
    Json := TJSONObject.ParseJSONValue(TFile.ReadAllText(FilePath)) as TJSONObject;
    try
      if Json = nil then
        Exit;
      
      JsonArray := Json.GetValue('results') as TJSONArray;
      if JsonArray = nil then
        Exit;
      
      for I := 0 to JsonArray.Count - 1 do
      begin
        JsonValue := JsonArray.Items[I];
        if JsonValue is TJSONObject then
        begin
          SamplePath := (JsonValue as TJSONObject).GetValue('samplePath').Value;
          Result.DetectedEncoding := (JsonValue as TJSONObject).GetValue('detectedEncoding').Value;
          Result.ConfidenceScore := StrToFloatDef((JsonValue as TJSONObject).GetValue('confidenceScore').Value, 0);
          Result.DetectionTime := StrToInt64Def((JsonValue as TJSONObject).GetValue('detectionTime').Value, 0);
          Result.IsCorrect := (JsonValue as TJSONObject).GetValue('isCorrect').Value.ToLower = 'true';
          Result.ErrorMessage := (JsonValue as TJSONObject).GetValue('errorMessage').Value;
          
          FDetectionResults.Add(SamplePath, Result);
        end;
      end;
      
      Log(Format('从文件加载了 %d 个检测结果', [FDetectionResults.Count]));
    finally
      Json.Free;
    end;
  except
    on E: Exception do
      Log('加载检测结果时出错: ' + E.Message);
  end;
end;

procedure TEncodingTestSampleManager.LoadSampleMetadata(const FilePath: string);
begin
  FSampleLoader.GetCollection.LoadMetadataFromFile(FilePath);
  Log(Format('从文件加载了样本元数据: %s', [FilePath]));
end;

procedure TEncodingTestSampleManager.LoadSamples(const Directory: string;
  Recursive: Boolean);
begin
  FSampleLoader.LoadFromDirectory(Directory, Recursive);
  Log(Format('从目录加载了 %d 个样本: %s', 
    [FSampleLoader.GetCollection.Count, Directory]));
end;

procedure TEncodingTestSampleManager.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

procedure TEncodingTestSampleManager.SaveConversionResultsToFile(
  const FilePath: string);
var
  Json: TJSONObject;
  JsonArray: TJSONArray;
  SampleJson: TJSONObject;
  ResultsArray: TJSONArray;
  ResultJson: TJSONObject;
  SamplePath: string;
  ResultsList: TList<TEncodingConversionResult>;
  Result: TEncodingConversionResult;
begin
  Json := TJSONObject.Create;
  try
    JsonArray := TJSONArray.Create;
    Json.AddPair('results', JsonArray);
    
    for SamplePath in FConversionResults.Keys do
    begin
      ResultsList := FConversionResults[SamplePath];
      
      SampleJson := TJSONObject.Create;
      SampleJson.AddPair('samplePath', SamplePath);
      
      ResultsArray := TJSONArray.Create;
      SampleJson.AddPair('conversionResults', ResultsArray);
      
      for Result in ResultsList do
      begin
        ResultJson := TJSONObject.Create;
        ResultJson.AddPair('sourceEncoding', Result.SourceEncoding);
        ResultJson.AddPair('targetEncoding', Result.TargetEncoding);
        ResultJson.AddPair('conversionTime', TJSONNumber.Create(Result.ConversionTime));
        ResultJson.AddPair('isSuccessful', TJSONBool.Create(Result.IsSuccessful));
        ResultJson.AddPair('errorMessage', Result.ErrorMessage);
        
        ResultsArray.Add(ResultJson);
      end;
      
      JsonArray.Add(SampleJson);
    end;
    
    TFile.WriteAllText(FilePath, Json.ToString);
    Log(Format('保存了 %d 个样本的转换结果到文件: %s', 
      [FConversionResults.Count, FilePath]));
  finally
    Json.Free;
  end;
end;

procedure TEncodingTestSampleManager.SaveDetectionResultsToFile(
  const FilePath: string);
var
  Json: TJSONObject;
  JsonArray: TJSONArray;
  ResultJson: TJSONObject;
  SamplePath: string;
  Result: TEncodingDetectionResult;
begin
  Json := TJSONObject.Create;
  try
    JsonArray := TJSONArray.Create;
    Json.AddPair('results', JsonArray);
    
    for SamplePath in FDetectionResults.Keys do
    begin
      Result := FDetectionResults[SamplePath];
      
      ResultJson := TJSONObject.Create;
      ResultJson.AddPair('samplePath', SamplePath);
      ResultJson.AddPair('detectedEncoding', Result.DetectedEncoding);
      ResultJson.AddPair('confidenceScore', TJSONNumber.Create(Result.ConfidenceScore));
      ResultJson.AddPair('detectionTime', TJSONNumber.Create(Result.DetectionTime));
      ResultJson.AddPair('isCorrect', TJSONBool.Create(Result.IsCorrect));
      ResultJson.AddPair('errorMessage', Result.ErrorMessage);
      
      JsonArray.Add(ResultJson);
    end;
    
    TFile.WriteAllText(FilePath, Json.ToString);
    Log(Format('保存了 %d 个检测结果到文件: %s', 
      [FDetectionResults.Count, FilePath]));
  finally
    Json.Free;
  end;
end;

procedure TEncodingTestSampleManager.SaveSampleMetadata(const FilePath: string);
begin
  FSampleLoader.GetCollection.SaveMetadataToFile(FilePath);
  Log(Format('保存了样本元数据到文件: %s', [FilePath]));
end;

end.
