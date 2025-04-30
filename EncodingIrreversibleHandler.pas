unit EncodingIrreversibleHandler;

{
  EncodingIrreversibleHandler.pas
  实现不可逆转换标记和处理
  
  作为improve.md中任务2.2.4的实现
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Math,
  EncodingTextComparator, EncodingDifferenceAnalyzer;

type
  /// <summary>
  /// 不可逆原因
  /// </summary>
  TIrreversibleReason = (
    irNone,                // 无原因（可逆）
    irEncodingLimitation,  // 编码限制
    irCharacterLoss,       // 字符丢失
    irCharacterReplacement,// 字符替换
    irNormalization,       // 规范化
    irByteOrderMark,       // 字节顺序标记
    irLineEnding,          // 行结束符
    irWhitespace,          // 空白字符
    irCase,                // 大小写
    irPunctuation,         // 标点符号
    irUnknown              // 未知原因
  );
  
  /// <summary>
  /// 不可逆转换信息
  /// </summary>
  TIrreversibleInfo = record
    IsIrreversible: Boolean;           // 是否不可逆
    Reasons: TArray<TIrreversibleReason>; // 不可逆原因
    DifferenceCount: Integer;          // 差异字符数
    DifferencePercentage: Double;      // 差异百分比
    Description: string;               // 描述
    
    constructor Create(AIsIrreversible: Boolean; const AReasons: TArray<TIrreversibleReason>;
      ADifferenceCount: Integer; ADifferencePercentage: Double; const ADescription: string = '');
  end;
  
  /// <summary>
  /// 编码对信息
  /// </summary>
  TEncodingPairInfo = record
    SourceEncoding: string;            // 源编码
    TargetEncoding: string;            // 目标编码
    IsIrreversible: Boolean;           // 是否不可逆
    Reasons: TArray<TIrreversibleReason>; // 不可逆原因
    Description: string;               // 描述
    
    constructor Create(const ASourceEncoding, ATargetEncoding: string;
      AIsIrreversible: Boolean; const AReasons: TArray<TIrreversibleReason>;
      const ADescription: string = '');
  end;
  
  /// <summary>
  /// 不可逆转换处理器
  /// </summary>
  TEncodingIrreversibleHandler = class
  private
    FLogCallback: TProc<string>;
    FKnownIrreversiblePairs: TDictionary<string, TEncodingPairInfo>;
    
    procedure Log(const Msg: string);
    function GetEncodingPairKey(const SourceEncoding, TargetEncoding: string): string;
    function AnalyzeIrreversibleReasons(const DifferenceResult: TDifferenceAnalysisResult): TArray<TIrreversibleReason>;
    function GetIrreversibleReasonDescription(Reason: TIrreversibleReason): string;
  public
    constructor Create(ALogCallback: TProc<string> = nil);
    destructor Destroy; override;
    
    /// <summary>
    /// 初始化已知的不可逆编码对
    /// </summary>
    procedure InitializeKnownIrreversiblePairs;
    
    /// <summary>
    /// 检查编码对是否已知不可逆
    /// </summary>
    function IsKnownIrreversiblePair(const SourceEncoding, TargetEncoding: string): Boolean;
    
    /// <summary>
    /// 获取编码对信息
    /// </summary>
    function GetEncodingPairInfo(const SourceEncoding, TargetEncoding: string): TEncodingPairInfo;
    
    /// <summary>
    /// 分析不可逆转换
    /// </summary>
    function AnalyzeIrreversibleConversion(const SourceText, ResultText: string): TIrreversibleInfo;
    
    /// <summary>
    /// 分析不可逆转换（文件版本）
    /// </summary>
    function AnalyzeIrreversibleConversionFile(const SourceFilePath, ResultFilePath: string): TIrreversibleInfo;
    
    /// <summary>
    /// 生成不可逆转换报告
    /// </summary>
    function GenerateIrreversibleReport(const Info: TIrreversibleInfo): string;
    
    /// <summary>
    /// 添加已知的不可逆编码对
    /// </summary>
    procedure AddKnownIrreversiblePair(const SourceEncoding, TargetEncoding: string;
      const Reasons: TArray<TIrreversibleReason>; const Description: string = '');
    
    /// <summary>
    /// 日志回调
    /// </summary>
    property LogCallback: TProc<string> read FLogCallback write FLogCallback;
  end;

implementation

uses
  System.IOUtils, System.StrUtils;

{ TIrreversibleInfo }

constructor TIrreversibleInfo.Create(AIsIrreversible: Boolean; const AReasons: TArray<TIrreversibleReason>;
  ADifferenceCount: Integer; ADifferencePercentage: Double; const ADescription: string);
begin
  IsIrreversible := AIsIrreversible;
  Reasons := AReasons;
  DifferenceCount := ADifferenceCount;
  DifferencePercentage := ADifferencePercentage;
  Description := ADescription;
end;

{ TEncodingPairInfo }

constructor TEncodingPairInfo.Create(const ASourceEncoding, ATargetEncoding: string;
  AIsIrreversible: Boolean; const AReasons: TArray<TIrreversibleReason>; const ADescription: string);
begin
  SourceEncoding := ASourceEncoding;
  TargetEncoding := ATargetEncoding;
  IsIrreversible := AIsIrreversible;
  Reasons := AReasons;
  Description := ADescription;
end;

{ TEncodingIrreversibleHandler }

constructor TEncodingIrreversibleHandler.Create(ALogCallback: TProc<string>);
begin
  inherited Create;
  FLogCallback := ALogCallback;
  FKnownIrreversiblePairs := TDictionary<string, TEncodingPairInfo>.Create;
  
  // 初始化已知的不可逆编码对
  InitializeKnownIrreversiblePairs;
end;

destructor TEncodingIrreversibleHandler.Destroy;
begin
  FKnownIrreversiblePairs.Free;
  inherited;
end;

procedure TEncodingIrreversibleHandler.AddKnownIrreversiblePair(const SourceEncoding, TargetEncoding: string;
  const Reasons: TArray<TIrreversibleReason>; const Description: string);
var
  Key: string;
  PairInfo: TEncodingPairInfo;
begin
  Key := GetEncodingPairKey(SourceEncoding, TargetEncoding);
  
  PairInfo := TEncodingPairInfo.Create(
    SourceEncoding, TargetEncoding, True, Reasons, Description);
  
  FKnownIrreversiblePairs.AddOrSetValue(Key, PairInfo);
  
  Log(Format('添加已知不可逆编码对: %s → %s', [SourceEncoding, TargetEncoding]));
end;

function TEncodingIrreversibleHandler.AnalyzeIrreversibleConversion(const SourceText, ResultText: string): TIrreversibleInfo;
var
  Comparator: TEncodingTextComparator;
  Analyzer: TEncodingDifferenceAnalyzer;
  ComparisonResult: TTextComparisonResult;
  DifferenceResult: TDifferenceAnalysisResult;
  Reasons: TArray<TIrreversibleReason>;
  Description: string;
  IsIrreversible: Boolean;
begin
  Comparator := TEncodingTextComparator.Create(FLogCallback);
  Analyzer := TEncodingDifferenceAnalyzer.Create(FLogCallback);
  try
    // 比较文本
    ComparisonResult := Comparator.CompareTextStrings(SourceText, ResultText);
    
    // 如果完全相同，则可逆
    if ComparisonResult.IsIdentical then
    begin
      Result := TIrreversibleInfo.Create(False, [irNone], 0, 0, '转换是可逆的');
      Exit;
    end;
    
    // 分析差异
    DifferenceResult := Analyzer.AnalyzeTextDifferences(SourceText, ResultText);
    
    // 分析不可逆原因
    Reasons := AnalyzeIrreversibleReasons(DifferenceResult);
    
    // 生成描述
    Description := '转换是不可逆的，原因：';
    for var Reason in Reasons do
    begin
      Description := Description + GetIrreversibleReasonDescription(Reason) + '、';
    end;
    
    // 移除最后的顿号
    if Description.EndsWith('、') then
      Description := Description.Substring(0, Description.Length - 1);
    
    // 确定是否不可逆
    IsIrreversible := Length(Reasons) > 0;
    
    // 创建结果
    Result := TIrreversibleInfo.Create(
      IsIrreversible, Reasons, ComparisonResult.DifferenceCount, 
      ComparisonResult.DifferencePercentage, Description);
    
    Log(Format('分析不可逆转换: 不可逆=%s, 差异字符数=%d, 差异百分比=%.2f%%', 
      [BoolToStr(IsIrreversible, True), ComparisonResult.DifferenceCount, 
       ComparisonResult.DifferencePercentage]));
  finally
    Analyzer.Free;
    Comparator.Free;
  end;
end;

function TEncodingIrreversibleHandler.AnalyzeIrreversibleConversionFile(const SourceFilePath, ResultFilePath: string): TIrreversibleInfo;
var
  SourceText, ResultText: string;
begin
  try
    // 读取文件内容
    SourceText := TFile.ReadAllText(SourceFilePath);
    ResultText := TFile.ReadAllText(ResultFilePath);
    
    // 分析不可逆转换
    Result := AnalyzeIrreversibleConversion(SourceText, ResultText);
    
    Log(Format('分析文件不可逆转换: %s 和 %s', 
      [ExtractFileName(SourceFilePath), ExtractFileName(ResultFilePath)]));
  except
    on E: Exception do
    begin
      Log(Format('分析文件不可逆转换失败: %s', [E.Message]));
      Result := TIrreversibleInfo.Create(True, [irUnknown], 0, 0, '分析失败: ' + E.Message);
    end;
  end;
end;

function TEncodingIrreversibleHandler.AnalyzeIrreversibleReasons(const DifferenceResult: TDifferenceAnalysisResult): TArray<TIrreversibleReason>;
var
  Reasons: TList<TIrreversibleReason>;
  DiffPositions: TArray<TDifferencePosition>;
  Position: TDifferencePosition;
  HasCharacterLoss, HasCharacterReplacement, HasNormalization, 
  HasBOM, HasLineEnding, HasWhitespace, HasCase, HasPunctuation: Boolean;
begin
  Reasons := TList<TIrreversibleReason>.Create;
  try
    // 初始化标志
    HasCharacterLoss := False;
    HasCharacterReplacement := False;
    HasNormalization := False;
    HasBOM := False;
    HasLineEnding := False;
    HasWhitespace := False;
    HasCase := False;
    HasPunctuation := False;
    
    // 分析差异位置
    DiffPositions := DifferenceResult.GetDifferencePositions;
    for Position in DiffPositions do
    begin
      case Position.DifferenceType of
        dtMissing: HasCharacterLoss := True;
        dtAdditional: HasCharacterReplacement := True;
        dtCharacter: HasCharacterReplacement := True;
        dtEncoding: HasNormalization := True;
        dtWhitespace: HasWhitespace := True;
        dtCase: HasCase := True;
        dtPunctuation: HasPunctuation := True;
      end;
      
      // 检查BOM
      if (Position.SourceChar.Length >= 1) and (Ord(Position.SourceChar[1]) = $FEFF) or
         (Position.TargetChar.Length >= 1) and (Ord(Position.TargetChar[1]) = $FEFF) then
        HasBOM := True;
      
      // 检查行结束符
      if (Position.SourceChar = #13) or (Position.SourceChar = #10) or
         (Position.TargetChar = #13) or (Position.TargetChar = #10) then
        HasLineEnding := True;
    end;
    
    // 添加原因
    if HasCharacterLoss then
      Reasons.Add(irCharacterLoss);
    
    if HasCharacterReplacement then
      Reasons.Add(irCharacterReplacement);
    
    if HasNormalization then
      Reasons.Add(irNormalization);
    
    if HasBOM then
      Reasons.Add(irByteOrderMark);
    
    if HasLineEnding then
      Reasons.Add(irLineEnding);
    
    if HasWhitespace then
      Reasons.Add(irWhitespace);
    
    if HasCase then
      Reasons.Add(irCase);
    
    if HasPunctuation then
      Reasons.Add(irPunctuation);
    
    // 如果没有找到具体原因，但有差异，则添加编码限制
    if (Reasons.Count = 0) and (DifferenceResult.TotalDifferences > 0) then
      Reasons.Add(irEncodingLimitation);
    
    Result := Reasons.ToArray;
  finally
    Reasons.Free;
  end;
end;

function TEncodingIrreversibleHandler.GenerateIrreversibleReport(const Info: TIrreversibleInfo): string;
var
  SB: TStringBuilder;
  Reason: TIrreversibleReason;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('# 不可逆转换分析报告');
    SB.AppendLine('');
    
    // 总体信息
    SB.AppendLine('## 1. 总体信息');
    SB.AppendLine('');
    SB.AppendLine(Format('- 是否不可逆: %s', [IfThen(Info.IsIrreversible, '是', '否')]));
    SB.AppendLine(Format('- 差异字符数: %d', [Info.DifferenceCount]));
    SB.AppendLine(Format('- 差异百分比: %.2f%%', [Info.DifferencePercentage]));
    SB.AppendLine(Format('- 描述: %s', [Info.Description]));
    SB.AppendLine('');
    
    // 不可逆原因
    if Info.IsIrreversible then
    begin
      SB.AppendLine('## 2. 不可逆原因');
      SB.AppendLine('');
      SB.AppendLine('| 原因 | 描述 |');
      SB.AppendLine('|------|------|');
      
      for Reason in Info.Reasons do
      begin
        SB.AppendLine(Format('| %s | %s |', 
          [GetEnumName(TypeInfo(TIrreversibleReason), Ord(Reason)), 
           GetIrreversibleReasonDescription(Reason)]));
      end;
      
      SB.AppendLine('');
      
      // 处理建议
      SB.AppendLine('## 3. 处理建议');
      SB.AppendLine('');
      
      if Info.DifferencePercentage < 1 then
      begin
        SB.AppendLine('差异较小，可以接受不可逆转换。');
      end
      else if Info.DifferencePercentage < 5 then
      begin
        SB.AppendLine('差异适中，建议检查关键内容是否受影响。');
      end
      else
      begin
        SB.AppendLine('差异较大，建议使用其他编码方式或保留原始文件。');
      end;
      
      SB.AppendLine('');
      
      // 具体建议
      SB.AppendLine('### 具体建议');
      SB.AppendLine('');
      
      for Reason in Info.Reasons do
      begin
        case Reason of
          irCharacterLoss:
            SB.AppendLine('- 对于字符丢失问题，建议使用支持更广泛字符集的编码，如UTF-8或UTF-16。');
          
          irCharacterReplacement:
            SB.AppendLine('- 对于字符替换问题，建议检查替换后的字符是否影响文本含义。');
          
          irNormalization:
            SB.AppendLine('- 对于规范化问题，可以在转换前应用Unicode规范化。');
          
          irByteOrderMark:
            SB.AppendLine('- 对于BOM问题，可以选择保留或移除BOM，但需要确保应用程序能正确处理。');
          
          irLineEnding:
            SB.AppendLine('- 对于行结束符问题，建议在转换前统一行结束符格式。');
          
          irWhitespace:
            SB.AppendLine('- 对于空白字符问题，可以考虑在转换前规范化空白字符。');
          
          irCase:
            SB.AppendLine('- 对于大小写问题，如果文本对大小写敏感，建议使用保留大小写的编码方式。');
          
          irPunctuation:
            SB.AppendLine('- 对于标点符号问题，建议检查替换后的标点是否影响文本含义。');
          
          irEncodingLimitation:
            SB.AppendLine('- 对于编码限制问题，建议使用支持更广泛字符集的编码，如UTF-8或UTF-16。');
        end;
      end;
    end;
    
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TEncodingIrreversibleHandler.GetEncodingPairInfo(const SourceEncoding, TargetEncoding: string): TEncodingPairInfo;
var
  Key: string;
begin
  Key := GetEncodingPairKey(SourceEncoding, TargetEncoding);
  
  if not FKnownIrreversiblePairs.TryGetValue(Key, Result) then
  begin
    // 如果不是已知的不可逆对，则创建一个可逆的信息
    Result := TEncodingPairInfo.Create(
      SourceEncoding, TargetEncoding, False, [irNone], '未知编码对，假定为可逆');
  end;
end;

function TEncodingIrreversibleHandler.GetEncodingPairKey(const SourceEncoding, TargetEncoding: string): string;
begin
  Result := Format('%s->%s', [SourceEncoding, TargetEncoding]);
end;

function TEncodingIrreversibleHandler.GetIrreversibleReasonDescription(Reason: TIrreversibleReason): string;
begin
  case Reason of
    irNone: Result := '无原因（可逆）';
    irEncodingLimitation: Result := '编码限制导致某些字符无法表示';
    irCharacterLoss: Result := '字符丢失，目标编码无法表示某些字符';
    irCharacterReplacement: Result := '字符替换，某些字符被替换为其他字符';
    irNormalization: Result := '规范化，字符被规范化为等效形式';
    irByteOrderMark: Result := '字节顺序标记（BOM）处理不一致';
    irLineEnding: Result := '行结束符转换不一致';
    irWhitespace: Result := '空白字符处理不一致';
    irCase: Result := '大小写转换不一致';
    irPunctuation: Result := '标点符号转换不一致';
    irUnknown: Result := '未知原因';
  else
    Result := '未分类原因';
  end;
end;

procedure TEncodingIrreversibleHandler.InitializeKnownIrreversiblePairs;
begin
  // 添加已知的不可逆编码对
  
  // UTF-8 到 ASCII
  AddKnownIrreversiblePair('UTF-8', 'ASCII', [irCharacterLoss],
    'ASCII只能表示基本拉丁字符，无法表示UTF-8中的非ASCII字符');
  
  // UTF-8 到 ANSI (Windows-1252)
  AddKnownIrreversiblePair('UTF-8', 'Windows-1252', [irCharacterLoss],
    'Windows-1252只能表示西欧字符，无法表示UTF-8中的其他字符');
  
  // UTF-8 到 GBK
  AddKnownIrreversiblePair('UTF-8', 'GBK', [irCharacterLoss],
    'GBK主要支持中文字符，无法表示UTF-8中的某些非中文字符');
  
  // UTF-8 到 Big5
  AddKnownIrreversiblePair('UTF-8', 'Big5', [irCharacterLoss],
    'Big5主要支持繁体中文字符，无法表示UTF-8中的某些非中文字符');
  
  // UTF-8 到 Shift-JIS
  AddKnownIrreversiblePair('UTF-8', 'Shift-JIS', [irCharacterLoss],
    'Shift-JIS主要支持日文字符，无法表示UTF-8中的某些非日文字符');
  
  // UTF-8 到 EUC-KR
  AddKnownIrreversiblePair('UTF-8', 'EUC-KR', [irCharacterLoss],
    'EUC-KR主要支持韩文字符，无法表示UTF-8中的某些非韩文字符');
  
  // UTF-8 到 ISO-8859-1
  AddKnownIrreversiblePair('UTF-8', 'ISO-8859-1', [irCharacterLoss],
    'ISO-8859-1只能表示西欧字符，无法表示UTF-8中的其他字符');
  
  // UTF-8 到 ISO-8859-2
  AddKnownIrreversiblePair('UTF-8', 'ISO-8859-2', [irCharacterLoss],
    'ISO-8859-2只能表示中欧字符，无法表示UTF-8中的其他字符');
  
  // UTF-8 到 ISO-8859-5
  AddKnownIrreversiblePair('UTF-8', 'ISO-8859-5', [irCharacterLoss],
    'ISO-8859-5只能表示西里尔字符，无法表示UTF-8中的其他字符');
  
  // UTF-8 到 ISO-8859-6
  AddKnownIrreversiblePair('UTF-8', 'ISO-8859-6', [irCharacterLoss],
    'ISO-8859-6只能表示阿拉伯字符，无法表示UTF-8中的其他字符');
  
  // UTF-8 到 ISO-8859-7
  AddKnownIrreversiblePair('UTF-8', 'ISO-8859-7', [irCharacterLoss],
    'ISO-8859-7只能表示希腊字符，无法表示UTF-8中的其他字符');
  
  // UTF-8 到 ISO-8859-8
  AddKnownIrreversiblePair('UTF-8', 'ISO-8859-8', [irCharacterLoss],
    'ISO-8859-8只能表示希伯来字符，无法表示UTF-8中的其他字符');
  
  // UTF-8 到 ISO-8859-9
  AddKnownIrreversiblePair('UTF-8', 'ISO-8859-9', [irCharacterLoss],
    'ISO-8859-9只能表示土耳其字符，无法表示UTF-8中的其他字符');
  
  // UTF-8 到 UTF-8（BOM处理）
  AddKnownIrreversiblePair('UTF-8', 'UTF-8 with BOM', [irByteOrderMark],
    'UTF-8和UTF-8 with BOM在BOM处理上不同');
  
  // UTF-8 with BOM 到 UTF-8
  AddKnownIrreversiblePair('UTF-8 with BOM', 'UTF-8', [irByteOrderMark],
    'UTF-8 with BOM和UTF-8在BOM处理上不同');
  
  // UTF-16LE 到 UTF-8（代理对处理）
  AddKnownIrreversiblePair('UTF-16LE', 'UTF-8', [irNormalization],
    'UTF-16LE和UTF-8在代理对处理上可能不同');
  
  // UTF-16BE 到 UTF-8（代理对处理）
  AddKnownIrreversiblePair('UTF-16BE', 'UTF-8', [irNormalization],
    'UTF-16BE和UTF-8在代理对处理上可能不同');
  
  Log(Format('初始化了 %d 个已知不可逆编码对', [FKnownIrreversiblePairs.Count]));
end;

function TEncodingIrreversibleHandler.IsKnownIrreversiblePair(const SourceEncoding, TargetEncoding: string): Boolean;
var
  Key: string;
  PairInfo: TEncodingPairInfo;
begin
  Key := GetEncodingPairKey(SourceEncoding, TargetEncoding);
  
  if FKnownIrreversiblePairs.TryGetValue(Key, PairInfo) then
    Result := PairInfo.IsIrreversible
  else
    Result := False;
end;

procedure TEncodingIrreversibleHandler.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

end.
