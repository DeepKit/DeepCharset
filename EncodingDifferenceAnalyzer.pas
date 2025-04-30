unit EncodingDifferenceAnalyzer;

{
  EncodingDifferenceAnalyzer.pas
  添加字符级差异分析功能
  
  作为improve.md中任务2.2.3的实现
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Math,
  System.Character;

type
  /// <summary>
  /// 差异类型
  /// </summary>
  TDifferenceType = (
    dtNone,           // 无差异
    dtCharacter,      // 字符差异
    dtEncoding,       // 编码差异
    dtMissing,        // 缺失字符
    dtAdditional,     // 额外字符
    dtOrder,          // 顺序差异
    dtCase,           // 大小写差异
    dtWhitespace,     // 空白字符差异
    dtPunctuation,    // 标点符号差异
    dtCombiningMark,  // 组合标记差异
    dtSurrogate,      // 代理对差异
    dtUnknown         // 未知差异
  );
  
  /// <summary>
  /// 差异位置
  /// </summary>
  TDifferencePosition = record
    SourceIndex: Integer;      // 源文本索引
    TargetIndex: Integer;      // 目标文本索引
    SourceChar: string;        // 源文本字符
    TargetChar: string;        // 目标文本字符
    DifferenceType: TDifferenceType; // 差异类型
    Description: string;       // 差异描述
    
    constructor Create(ASourceIndex, ATargetIndex: Integer; const ASourceChar, ATargetChar: string;
      ADifferenceType: TDifferenceType; const ADescription: string = '');
  end;
  
  /// <summary>
  /// 差异分析结果
  /// </summary>
  TDifferenceAnalysisResult = record
    TotalDifferences: Integer;                 // 总差异数
    DifferencesByType: TDictionary<TDifferenceType, Integer>; // 按类型统计差异
    DifferencePositions: TList<TDifferencePosition>; // 差异位置列表
    
    constructor Create;
    procedure Free;
    
    /// <summary>
    /// 添加差异位置
    /// </summary>
    procedure AddDifference(const Difference: TDifferencePosition);
    
    /// <summary>
    /// 获取差异位置数组
    /// </summary>
    function GetDifferencePositions: TArray<TDifferencePosition>;
    
    /// <summary>
    /// 获取差异类型统计
    /// </summary>
    function GetDifferenceTypeStats: TDictionary<TDifferenceType, Integer>;
  end;
  
  /// <summary>
  /// 字符级差异分析器
  /// </summary>
  TEncodingDifferenceAnalyzer = class
  private
    FLogCallback: TProc<string>;
    
    procedure Log(const Msg: string);
    function DetermineCharacterDifferenceType(const SourceChar, TargetChar: string): TDifferenceType;
    function GetDifferenceTypeDescription(DifferenceType: TDifferenceType; const SourceChar, TargetChar: string): string;
  public
    constructor Create(ALogCallback: TProc<string> = nil);
    
    /// <summary>
    /// 分析两个文本文件的差异
    /// </summary>
    function AnalyzeFileDifferences(const SourceFilePath, TargetFilePath: string): TDifferenceAnalysisResult;
    
    /// <summary>
    /// 分析两个文本字符串的差异
    /// </summary>
    function AnalyzeTextDifferences(const SourceText, TargetText: string): TDifferenceAnalysisResult;
    
    /// <summary>
    /// 分析两个字节数组的差异
    /// </summary>
    function AnalyzeByteArrayDifferences(const SourceBytes, TargetBytes: TBytes): TDifferenceAnalysisResult;
    
    /// <summary>
    /// 生成差异报告
    /// </summary>
    function GenerateDifferenceReport(const Result: TDifferenceAnalysisResult): string;
    
    /// <summary>
    /// 日志回调
    /// </summary>
    property LogCallback: TProc<string> read FLogCallback write FLogCallback;
  end;

implementation

uses
  System.IOUtils, System.StrUtils;

{ TDifferencePosition }

constructor TDifferencePosition.Create(ASourceIndex, ATargetIndex: Integer; const ASourceChar, ATargetChar: string;
  ADifferenceType: TDifferenceType; const ADescription: string);
begin
  SourceIndex := ASourceIndex;
  TargetIndex := ATargetIndex;
  SourceChar := ASourceChar;
  TargetChar := ATargetChar;
  DifferenceType := ADifferenceType;
  Description := ADescription;
end;

{ TDifferenceAnalysisResult }

constructor TDifferenceAnalysisResult.Create;
begin
  TotalDifferences := 0;
  DifferencesByType := TDictionary<TDifferenceType, Integer>.Create;
  DifferencePositions := TList<TDifferencePosition>.Create;
end;

procedure TDifferenceAnalysisResult.AddDifference(const Difference: TDifferencePosition);
var
  Count: Integer;
begin
  // 添加到差异位置列表
  DifferencePositions.Add(Difference);
  
  // 更新总差异数
  Inc(TotalDifferences);
  
  // 更新按类型统计差异
  if DifferencesByType.TryGetValue(Difference.DifferenceType, Count) then
    DifferencesByType[Difference.DifferenceType] := Count + 1
  else
    DifferencesByType.Add(Difference.DifferenceType, 1);
end;

procedure TDifferenceAnalysisResult.Free;
begin
  DifferencesByType.Free;
  DifferencePositions.Free;
end;

function TDifferenceAnalysisResult.GetDifferencePositions: TArray<TDifferencePosition>;
begin
  Result := DifferencePositions.ToArray;
end;

function TDifferenceAnalysisResult.GetDifferenceTypeStats: TDictionary<TDifferenceType, Integer>;
begin
  Result := DifferencesByType;
end;

{ TEncodingDifferenceAnalyzer }

constructor TEncodingDifferenceAnalyzer.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := ALogCallback;
end;

function TEncodingDifferenceAnalyzer.AnalyzeByteArrayDifferences(const SourceBytes, TargetBytes: TBytes): TDifferenceAnalysisResult;
var
  SourceText, TargetText: string;
begin
  // 将字节数组转换为字符串
  SourceText := TEncoding.UTF8.GetString(SourceBytes);
  TargetText := TEncoding.UTF8.GetString(TargetBytes);
  
  // 分析文本差异
  Result := AnalyzeTextDifferences(SourceText, TargetText);
end;

function TEncodingDifferenceAnalyzer.AnalyzeFileDifferences(const SourceFilePath, TargetFilePath: string): TDifferenceAnalysisResult;
var
  SourceText, TargetText: string;
begin
  try
    // 读取文件内容
    SourceText := TFile.ReadAllText(SourceFilePath);
    TargetText := TFile.ReadAllText(TargetFilePath);
    
    // 分析文本差异
    Result := AnalyzeTextDifferences(SourceText, TargetText);
    
    Log(Format('分析文件差异: %s 和 %s', [ExtractFileName(SourceFilePath), ExtractFileName(TargetFilePath)]));
  except
    on E: Exception do
    begin
      Log(Format('分析文件差异失败: %s', [E.Message]));
      Result := TDifferenceAnalysisResult.Create;
    end;
  end;
end;

function TEncodingDifferenceAnalyzer.AnalyzeTextDifferences(const SourceText, TargetText: string): TDifferenceAnalysisResult;
var
  I, J, MinLength: Integer;
  SourceChar, TargetChar: string;
  DiffType: TDifferenceType;
  DiffDesc: string;
  Difference: TDifferencePosition;
begin
  Result := TDifferenceAnalysisResult.Create;
  
  try
    // 比较共同部分
    MinLength := Min(Length(SourceText), Length(TargetText));
    I := 1;
    J := 1;
    
    while (I <= MinLength) and (J <= MinLength) do
    begin
      SourceChar := SourceText[I];
      TargetChar := TargetText[J];
      
      // 检查是否有差异
      if SourceChar <> TargetChar then
      begin
        // 确定差异类型
        DiffType := DetermineCharacterDifferenceType(SourceChar, TargetChar);
        DiffDesc := GetDifferenceTypeDescription(DiffType, SourceChar, TargetChar);
        
        // 创建差异位置
        Difference := TDifferencePosition.Create(I, J, SourceChar, TargetChar, DiffType, DiffDesc);
        
        // 添加到结果
        Result.AddDifference(Difference);
      end;
      
      Inc(I);
      Inc(J);
    end;
    
    // 处理剩余部分
    while I <= Length(SourceText) do
    begin
      SourceChar := SourceText[I];
      
      // 创建差异位置（目标文本缺失）
      Difference := TDifferencePosition.Create(I, 0, SourceChar, '', dtMissing, '目标文本缺失此字符');
      
      // 添加到结果
      Result.AddDifference(Difference);
      
      Inc(I);
    end;
    
    while J <= Length(TargetText) do
    begin
      TargetChar := TargetText[J];
      
      // 创建差异位置（目标文本额外）
      Difference := TDifferencePosition.Create(0, J, '', TargetChar, dtAdditional, '目标文本额外字符');
      
      // 添加到结果
      Result.AddDifference(Difference);
      
      Inc(J);
    end;
    
    Log(Format('分析文本差异: 总差异数=%d', [Result.TotalDifferences]));
  except
    on E: Exception do
    begin
      Log(Format('分析文本差异失败: %s', [E.Message]));
      Result.Free;
      Result := TDifferenceAnalysisResult.Create;
    end;
  end;
end;

function TEncodingDifferenceAnalyzer.DetermineCharacterDifferenceType(const SourceChar, TargetChar: string): TDifferenceType;
begin
  // 如果字符相同，则无差异
  if SourceChar = TargetChar then
    Exit(dtNone);
  
  // 检查大小写差异
  if AnsiLowerCase(SourceChar) = AnsiLowerCase(TargetChar) then
    Exit(dtCase);
  
  // 检查空白字符差异
  if (SourceChar.Trim = '') and (TargetChar.Trim = '') then
    Exit(dtWhitespace);
  
  // 检查标点符号差异
  if TCharacter.IsPunctuation(SourceChar, 1) and TCharacter.IsPunctuation(TargetChar, 1) then
    Exit(dtPunctuation);
  
  // 检查组合标记差异
  if TCharacter.GetUnicodeCategory(SourceChar, 1) = TUnicodeCategory.ucCombiningMark then
    Exit(dtCombiningMark);
  
  // 检查代理对差异
  if TCharacter.IsHighSurrogate(SourceChar, 1) or TCharacter.IsLowSurrogate(SourceChar, 1) or
     TCharacter.IsHighSurrogate(TargetChar, 1) or TCharacter.IsLowSurrogate(TargetChar, 1) then
    Exit(dtSurrogate);
  
  // 默认为字符差异
  Result := dtCharacter;
end;

function TEncodingDifferenceAnalyzer.GenerateDifferenceReport(const Result: TDifferenceAnalysisResult): string;
var
  SB: TStringBuilder;
  DiffType: TDifferenceType;
  Count: Integer;
  Positions: TArray<TDifferencePosition>;
  Position: TDifferencePosition;
  I: Integer;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('# 字符级差异分析报告');
    SB.AppendLine('');
    
    // 总体统计
    SB.AppendLine('## 1. 总体统计');
    SB.AppendLine('');
    SB.AppendLine(Format('- 总差异数: %d', [Result.TotalDifferences]));
    SB.AppendLine('');
    
    // 按类型统计
    SB.AppendLine('## 2. 按类型统计');
    SB.AppendLine('');
    SB.AppendLine('| 差异类型 | 数量 | 百分比 |');
    SB.AppendLine('|----------|------|--------|');
    
    for DiffType := Low(TDifferenceType) to High(TDifferenceType) do
    begin
      if Result.DifferencesByType.TryGetValue(DiffType, Count) and (Count > 0) then
      begin
        SB.AppendLine(Format('| %s | %d | %.2f%% |', 
          [GetEnumName(TypeInfo(TDifferenceType), Ord(DiffType)), Count, 
           (Count / Result.TotalDifferences) * 100]));
      end;
    end;
    
    SB.AppendLine('');
    
    // 详细差异
    SB.AppendLine('## 3. 详细差异');
    SB.AppendLine('');
    
    if Result.TotalDifferences > 0 then
    begin
      SB.AppendLine('| 源索引 | 目标索引 | 源字符 | 目标字符 | 差异类型 | 描述 |');
      SB.AppendLine('|--------|----------|--------|----------|----------|------|');
      
      Positions := Result.GetDifferencePositions;
      
      // 限制显示的差异数量
      for I := 0 to Min(99, Length(Positions) - 1) do
      begin
        Position := Positions[I];
        
        SB.AppendLine(Format('| %d | %d | %s | %s | %s | %s |', 
          [Position.SourceIndex, Position.TargetIndex, 
           StringReplace(Position.SourceChar, '|', '\|', [rfReplaceAll]), 
           StringReplace(Position.TargetChar, '|', '\|', [rfReplaceAll]), 
           GetEnumName(TypeInfo(TDifferenceType), Ord(Position.DifferenceType)), 
           Position.Description]));
      end;
      
      // 如果差异太多，显示省略信息
      if Length(Positions) > 100 then
        SB.AppendLine(Format('| ... | ... | ... | ... | ... | 还有 %d 个差异未显示 |', [Length(Positions) - 100]));
    end
    else
    begin
      SB.AppendLine('没有发现差异。');
    end;
    
    System.Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TEncodingDifferenceAnalyzer.GetDifferenceTypeDescription(DifferenceType: TDifferenceType; const SourceChar, TargetChar: string): string;
begin
  case DifferenceType of
    dtNone: Result := '无差异';
    dtCharacter: Result := Format('字符差异: %s → %s', [SourceChar, TargetChar]);
    dtEncoding: Result := '编码差异';
    dtMissing: Result := Format('目标文本缺失字符: %s', [SourceChar]);
    dtAdditional: Result := Format('目标文本额外字符: %s', [TargetChar]);
    dtOrder: Result := '顺序差异';
    dtCase: Result := Format('大小写差异: %s → %s', [SourceChar, TargetChar]);
    dtWhitespace: Result := '空白字符差异';
    dtPunctuation: Result := Format('标点符号差异: %s → %s', [SourceChar, TargetChar]);
    dtCombiningMark: Result := '组合标记差异';
    dtSurrogate: Result := '代理对差异';
    dtUnknown: Result := '未知差异';
  else
    Result := '未分类差异';
  end;
end;

procedure TEncodingDifferenceAnalyzer.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

end.
