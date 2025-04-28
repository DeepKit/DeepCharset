unit ChineseEncodingFeatureDB.Matcher;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Math,
  ChineseEncodingFeatureDB.Types, ChineseEncodingFeatureDB.Storage;

type
  // 匹配结果类型
  TMatchResultType = (
    mrtExactMatch,     // 精确匹配
    mrtHighMatch,      // 高匹配度
    mrtMediumMatch,    // 中等匹配度
    mrtLowMatch,       // 低匹配度
    mrtNoMatch         // 无匹配
  );

  // 匹配结果
  TMatchResult = record
    ResultType: TMatchResultType;
    Score: Double;                   // 匹配分数(0.0~1.0)
    EncodingType: TChineseEncodingType; // 匹配的编码类型
    Description: string;             // 匹配描述
  end;

  // 特征匹配接口
  IFeatureMatcher = interface
    ['{B1A2C3D4-E5F6-7890-12AB-CDEF01234567}']
    // 字节频率匹配
    function MatchByteFrequency(const AData: array of Byte; AEncoding: TChineseEncodingType): TMatchResult;
    
    // 字符频率匹配
    function MatchCharFrequency(const AText: string; AEncoding: TChineseEncodingType): TMatchResult;
    
    // 字节对匹配
    function MatchBytePair(const AData: array of Byte; AEncoding: TChineseEncodingType): TMatchResult;
    
    // 区域特征匹配
    function MatchRegion(const ACodePoints: array of UInt32; AEncoding: TChineseEncodingType): TMatchResult;
    
    // 特殊字符匹配
    function MatchSpecialChar(const ACodePoints: array of UInt32; AEncoding: TChineseEncodingType): TMatchResult;
    
    // 语言特征匹配
    function MatchLanguageFeature(const AText: string; AEncoding: TChineseEncodingType): TMatchResult;
    
    // 综合匹配
    function MatchComprehensive(const AData: array of Byte; const AText: string; AEncoding: TChineseEncodingType): TMatchResult;
  end;

  // 基本特征匹配器
  TBaseFeatureMatcher = class(TInterfacedObject, IFeatureMatcher)
  private
    FStorage: IFeatureDataStorage;
    
    // 计算匹配结果类型
    function CalculateResultType(AScore: Double): TMatchResultType;
    
    // 计算字节频率分布
    procedure CalculateByteFrequency(const AData: array of Byte; var AFrequency: array of Double);
    
    // 计算字节对频率分布
    procedure CalculateBytePairFrequency(const AData: array of Byte; var APairFrequency: TDictionary<Word, Double>);
    
    // 提取文本中的Unicode码点
    function ExtractCodePoints(const AText: string): TArray<UInt32>;
    
    // 将字节数据转换为文本
    function BytesToText(const AData: array of Byte; AEncoding: TChineseEncodingType): string;
  public
    constructor Create(AStorage: IFeatureDataStorage);
    destructor Destroy; override;
    
    // 实现IFeatureMatcher接口
    function MatchByteFrequency(const AData: array of Byte; AEncoding: TChineseEncodingType): TMatchResult;
    function MatchCharFrequency(const AText: string; AEncoding: TChineseEncodingType): TMatchResult;
    function MatchBytePair(const AData: array of Byte; AEncoding: TChineseEncodingType): TMatchResult;
    function MatchRegion(const ACodePoints: array of UInt32; AEncoding: TChineseEncodingType): TMatchResult;
    function MatchSpecialChar(const ACodePoints: array of UInt32; AEncoding: TChineseEncodingType): TMatchResult;
    function MatchLanguageFeature(const AText: string; AEncoding: TChineseEncodingType): TMatchResult;
    function MatchComprehensive(const AData: array of Byte; const AText: string; AEncoding: TChineseEncodingType): TMatchResult;
  end;

  // 匹配器工厂
  TFeatureMatcherFactory = class
  public
    // 创建基本匹配器
    class function CreateMatcher(AStorage: IFeatureDataStorage): IFeatureMatcher;
  end;

implementation

uses
  System.Character, System.StrUtils;

{ TBaseFeatureMatcher }

constructor TBaseFeatureMatcher.Create(AStorage: IFeatureDataStorage);
begin
  inherited Create;
  FStorage := AStorage;
end;

destructor TBaseFeatureMatcher.Destroy;
begin
  inherited;
end;

function TBaseFeatureMatcher.CalculateResultType(AScore: Double): TMatchResultType;
begin
  if AScore >= 0.95 then
    Result := mrtExactMatch
  else if AScore >= 0.8 then
    Result := mrtHighMatch
  else if AScore >= 0.6 then
    Result := mrtMediumMatch
  else if AScore >= 0.3 then
    Result := mrtLowMatch
  else
    Result := mrtNoMatch;
end;

procedure TBaseFeatureMatcher.CalculateByteFrequency(const AData: array of Byte; var AFrequency: array of Double);
var
  TotalBytes: Integer;
  i: Integer;
begin
  // 初始化频率数组
  for i := 0 to 255 do
    AFrequency[i] := 0.0;
    
  // 计算数据中每个字节的出现次数
  TotalBytes := Length(AData);
  if TotalBytes = 0 then
    Exit;
    
  for i := 0 to TotalBytes - 1 do
    AFrequency[AData[i]] := AFrequency[AData[i]] + 1.0;
    
  // 计算频率(百分比)
  for i := 0 to 255 do
    AFrequency[i] := AFrequency[i] / TotalBytes;
end;

procedure TBaseFeatureMatcher.CalculateBytePairFrequency(const AData: array of Byte; var APairFrequency: TDictionary<Word, Double>);
var
  TotalPairs: Integer;
  i: Integer;
  Pair: Word;
begin
  // 清空频率字典
  APairFrequency.Clear;
  
  // 计算数据中每个字节对的出现次数
  TotalPairs := Length(AData) - 1;
  if TotalPairs <= 0 then
    Exit;
    
  for i := 0 to TotalPairs - 1 do
  begin
    Pair := (AData[i] shl 8) or AData[i + 1];
    
    if APairFrequency.ContainsKey(Pair) then
      APairFrequency[Pair] := APairFrequency[Pair] + 1.0
    else
      APairFrequency.Add(Pair, 1.0);
  end;
  
  // 计算频率(百分比)
  for Pair in APairFrequency.Keys do
    APairFrequency[Pair] := APairFrequency[Pair] / TotalPairs;
end;

function TBaseFeatureMatcher.ExtractCodePoints(const AText: string): TArray<UInt32>;
var
  i, Count: Integer;
begin
  // 初始化结果数组
  SetLength(Result, Length(AText));
  Count := 0;
  
  // 提取Unicode码点
  i := 1;
  while i <= Length(AText) do
  begin
    Result[Count] := Ord(AText[i]);
    Inc(Count);
    Inc(i);
  end;
  
  // 调整数组大小
  SetLength(Result, Count);
end;

function TBaseFeatureMatcher.BytesToText(const AData: array of Byte; AEncoding: TChineseEncodingType): string;
var
  Encoding: System.Classes.TEncoding;
begin
  // 根据编码类型选择合适的编码对象
  case AEncoding of
    cetGB18030:
      // 使用GB18030编码(在Delphi中没有直接的GB18030编码，可能需要自定义实现)
      Result := '';
      
    cetGBK:
      // 使用GBK编码(在Delphi中可以用936代码页)
      Result := System.Classes.TEncoding.GetEncoding(936).GetString(AData);
      
    cetGB2312:
      // 使用GB2312编码(在Delphi中可以用936代码页)
      Result := System.Classes.TEncoding.GetEncoding(936).GetString(AData);
      
    cetBig5:
      // 使用Big5编码(在Delphi中可以用950代码页)
      Result := System.Classes.TEncoding.GetEncoding(950).GetString(AData);
      
    cetBig5HKSCS:
      // 使用Big5-HKSCS编码(在Delphi中没有直接支持，可能需要自定义实现)
      Result := '';
      
    cetUTF8:
      // 使用UTF-8编码
      Result := System.Classes.TEncoding.UTF8.GetString(AData);
      
    cetUTF16LE:
      // 使用UTF-16 LE编码
      Result := System.Classes.TEncoding.Unicode.GetString(AData);
      
    cetUTF16BE:
      // 使用UTF-16 BE编码
      Result := System.Classes.TEncoding.BigEndianUnicode.GetString(AData);
      
    cetUTF32LE, cetUTF32BE, cetUnknown:
      // 这些编码需要自定义实现或者不支持
      Result := '';
  end;
end;

function TBaseFeatureMatcher.MatchByteFrequency(const AData: array of Byte; AEncoding: TChineseEncodingType): TMatchResult;
var
  DataFrequency: array[0..255] of Double;
  ReferenceData: TFeatureDataCollection;
  ByteFreqData: TByteFrequencyFeatureData;
  TotalDiff, Weight, MaxDiff: Double;
  i: Integer;
begin
  // 初始化结果
  Result.ResultType := mrtNoMatch;
  Result.Score := 0.0;
  Result.EncodingType := AEncoding;
  Result.Description := '';
  
  // 计算数据的字节频率
  CalculateByteFrequency(AData, DataFrequency);
  
  // 获取参考数据
  ReferenceData := FStorage.QueryFeatureData(AEncoding, fdtByteFrequency);
  try
    if (ReferenceData = nil) or (ReferenceData.Count = 0) then
    begin
      Result.Description := '没有找到参考字节频率数据';
      Exit;
    end;
    
    // 计算与参考数据的差异
    TotalDiff := 0.0;
    MaxDiff := 0.0;
    
    for i := 0 to ReferenceData.Count - 1 do
    begin
      if not (ReferenceData.GetItem(i) is TByteFrequencyFeatureData) then
        Continue;
        
      ByteFreqData := ReferenceData.GetItem(i) as TByteFrequencyFeatureData;
      
      // 使用加权欧几里得距离计算相似度
      for i := 0 to 255 do
      begin
        // 高频字节给予更高的权重
        Weight := 1.0 + 9.0 * ByteFreqData.Data.ByteValues[i];
        TotalDiff := TotalDiff + Weight * Sqr(DataFrequency[i] - ByteFreqData.Data.ByteValues[i]);
        MaxDiff := MaxDiff + Weight;
      end;
    end;
    
    // 计算最终分数(0.0~1.0)
    if MaxDiff > 0 then
      Result.Score := 1.0 - Sqrt(TotalDiff) / Sqrt(MaxDiff)
    else
      Result.Score := 0.0;
      
    // 设置结果类型
    Result.ResultType := CalculateResultType(Result.Score);
    Result.Description := Format('字节频率匹配分数: %.2f', [Result.Score]);
  finally
    ReferenceData.Free;
  end;
end;

function TBaseFeatureMatcher.MatchCharFrequency(const AText: string; AEncoding: TChineseEncodingType): TMatchResult;
var
  CharFrequency: TDictionary<UInt32, Double>;
  ReferenceData: TFeatureDataCollection;
  CharFreqData: TCharFrequencyFeatureData;
  TotalChars: Integer;
  TotalDiff, TotalRef, MaxDiff: Double;
  CodePoint: UInt32;
  i: Integer;
  CodePoints: TArray<UInt32>;
begin
  // 初始化结果
  Result.ResultType := mrtNoMatch;
  Result.Score := 0.0;
  Result.EncodingType := AEncoding;
  Result.Description := '';
  
  // 如果文本为空，则返回无匹配
  if AText = '' then
  begin
    Result.Description := '文本为空';
    Exit;
  end;
  
  // 提取文本中的Unicode码点并计算频率
  CodePoints := ExtractCodePoints(AText);
  TotalChars := Length(CodePoints);
  
  if TotalChars = 0 then
  begin
    Result.Description := '无有效字符';
    Exit;
  end;
  
  CharFrequency := TDictionary<UInt32, Double>.Create;
  try
    // 计算每个字符的出现频率
    for i := 0 to TotalChars - 1 do
    begin
      CodePoint := CodePoints[i];
      
      if CharFrequency.ContainsKey(CodePoint) then
        CharFrequency[CodePoint] := CharFrequency[CodePoint] + 1.0
      else
        CharFrequency.Add(CodePoint, 1.0);
    end;
    
    // 计算频率(百分比)
    for CodePoint in CharFrequency.Keys.ToArray do
      CharFrequency[CodePoint] := CharFrequency[CodePoint] / TotalChars;
    
    // 获取参考数据
    ReferenceData := FStorage.QueryFeatureData(AEncoding, fdtCharFrequency);
    try
      if (ReferenceData = nil) or (ReferenceData.Count = 0) then
      begin
        Result.Description := '没有找到参考字符频率数据';
        Exit;
      end;
      
      // 计算与参考数据的差异
      TotalDiff := 0.0;
      TotalRef := 0.0;
      MaxDiff := 0.0;
      
      for i := 0 to ReferenceData.Count - 1 do
      begin
        if not (ReferenceData.GetItem(i) is TCharFrequencyFeatureData) then
          Continue;
          
        CharFreqData := ReferenceData.GetItem(i) as TCharFrequencyFeatureData;
        CodePoint := CharFreqData.Data.CharCode;
        
        // 如果字符在输入文本中出现
        if CharFrequency.ContainsKey(CodePoint) then
        begin
          TotalDiff := TotalDiff + Abs(CharFrequency[CodePoint] - CharFreqData.Data.Frequency);
          TotalRef := TotalRef + CharFreqData.Data.Frequency;
        end
        else
        begin
          TotalDiff := TotalDiff + CharFreqData.Data.Frequency;
          TotalRef := TotalRef + CharFreqData.Data.Frequency;
        end;
        
        MaxDiff := MaxDiff + CharFreqData.Data.Frequency;
      end;
      
      // 计算最终分数(0.0~1.0)
      if TotalRef > 0 then
        Result.Score := 1.0 - (TotalDiff / (2.0 * TotalRef))
      else
        Result.Score := 0.0;
        
      // 设置结果类型
      Result.ResultType := CalculateResultType(Result.Score);
      Result.Description := Format('字符频率匹配分数: %.2f', [Result.Score]);
    finally
      ReferenceData.Free;
    end;
  finally
    CharFrequency.Free;
  end;
end;

function TBaseFeatureMatcher.MatchBytePair(const AData: array of Byte; AEncoding: TChineseEncodingType): TMatchResult;
var
  PairFrequency: TDictionary<Word, Double>;
  ReferenceData: TFeatureDataCollection;
  BytePairData: TBytePairFreatureData;
  TotalDiff, MaxDiff: Double;
  i: Integer;
  Pair: Word;
begin
  // 初始化结果
  Result.ResultType := mrtNoMatch;
  Result.Score := 0.0;
  Result.EncodingType := AEncoding;
  Result.Description := '';
  
  // 如果数据太少，则返回无匹配
  if Length(AData) < 2 then
  begin
    Result.Description := '数据太少，无法分析字节对';
    Exit;
  end;
  
  // 计算数据的字节对频率
  PairFrequency := TDictionary<Word, Double>.Create;
  try
    CalculateBytePairFrequency(AData, PairFrequency);
    
    // 获取参考数据
    ReferenceData := FStorage.QueryFeatureData(AEncoding, fdtBytePair);
    try
      if (ReferenceData = nil) or (ReferenceData.Count = 0) then
      begin
        Result.Description := '没有找到参考字节对频率数据';
        Exit;
      end;
      
      // 计算与参考数据的差异
      TotalDiff := 0.0;
      MaxDiff := 0.0;
      
      for i := 0 to ReferenceData.Count - 1 do
      begin
        if not (ReferenceData.GetItem(i) is TBytePairFreatureData) then
          Continue;
          
        BytePairData := ReferenceData.GetItem(i) as TBytePairFreatureData;
        Pair := (BytePairData.Data.FirstByte shl 8) or BytePairData.Data.SecondByte;
        
        // 如果字节对在输入数据中出现
        if PairFrequency.ContainsKey(Pair) then
          TotalDiff := TotalDiff + Abs(PairFrequency[Pair] - BytePairData.Data.Frequency)
        else
          TotalDiff := TotalDiff + BytePairData.Data.Frequency;
          
        MaxDiff := MaxDiff + BytePairData.Data.Frequency;
      end;
      
      // 计算最终分数(0.0~1.0)
      if MaxDiff > 0 then
        Result.Score := 1.0 - (TotalDiff / MaxDiff)
      else
        Result.Score := 0.0;
        
      // 设置结果类型
      Result.ResultType := CalculateResultType(Result.Score);
      Result.Description := Format('字节对匹配分数: %.2f', [Result.Score]);
    finally
      ReferenceData.Free;
    end;
  finally
    PairFrequency.Free;
  end;
end;

function TBaseFeatureMatcher.MatchRegion(const ACodePoints: array of UInt32; AEncoding: TChineseEncodingType): TMatchResult;
var
  RegionCounts: TDictionary<TRegionType, Integer>;
  ReferenceData: TFeatureDataCollection;
  RegionData: TRegionFeatureData;
  TotalPoints, MatchedPoints: Integer;
  i, j: Integer;
begin
  // 初始化结果
  Result.ResultType := mrtNoMatch;
  Result.Score := 0.0;
  Result.EncodingType := AEncoding;
  Result.Description := '';
  
  // 如果没有码点，则返回无匹配
  TotalPoints := Length(ACodePoints);
  if TotalPoints = 0 then
  begin
    Result.Description := '没有Unicode码点可分析';
    Exit;
  end;
  
  // 初始化区域计数器
  RegionCounts := TDictionary<TRegionType, Integer>.Create;
  try
    // 获取参考数据
    ReferenceData := FStorage.QueryFeatureData(AEncoding, fdtRegion);
    try
      if (ReferenceData = nil) or (ReferenceData.Count = 0) then
      begin
        Result.Description := '没有找到参考区域数据';
        Exit;
      end;
      
      // 统计每个码点所属的区域
      MatchedPoints := 0;
      
      for i := 0 to TotalPoints - 1 do
      begin
        for j := 0 to ReferenceData.Count - 1 do
        begin
          if not (ReferenceData.GetItem(j) is TRegionFeatureData) then
            Continue;
            
          RegionData := ReferenceData.GetItem(j) as TRegionFeatureData;
          
          // 检查码点是否在区域范围内
          if (ACodePoints[i] >= RegionData.Data.StartRange) and 
             (ACodePoints[i] <= RegionData.Data.EndRange) then
          begin
            Inc(MatchedPoints);
            
            if RegionCounts.ContainsKey(RegionData.Data.RegionType) then
              RegionCounts[RegionData.Data.RegionType] := RegionCounts[RegionData.Data.RegionType] + 1
            else
              RegionCounts.Add(RegionData.Data.RegionType, 1);
              
            Break; // 一个码点只属于一个区域
          end;
        end;
      end;
      
      // 计算最终分数(0.0~1.0)
      if TotalPoints > 0 then
        Result.Score := MatchedPoints / TotalPoints
      else
        Result.Score := 0.0;
        
      // 设置结果类型
      Result.ResultType := CalculateResultType(Result.Score);
      
      // 生成描述
      var Desc := Format('区域匹配分数: %.2f, 识别区域:', [Result.Score]);
      for var Region in RegionCounts.Keys do
      begin
        var RegionStr := '';
        case Region of
          rtASCII: RegionStr := 'ASCII';
          rtLevel1Hanzi: RegionStr := '一级汉字';
          rtLevel2Hanzi: RegionStr := '二级汉字';
          rtSymbol: RegionStr := '符号';
          rtPunctuation: RegionStr := '标点';
          rtExtendedHanzi: RegionStr := '扩展汉字';
          rtHKSCSHanzi: RegionStr := 'HKSCS汉字';
          rtUserDefined: RegionStr := '用户自定义';
          rtReserved: RegionStr := '保留区';
          rtOther: RegionStr := '其他';
        end;
        
        Desc := Desc + ' ' + RegionStr + '(' + IntToStr(RegionCounts[Region]) + ')';
      end;
      
      Result.Description := Desc;
    finally
      ReferenceData.Free;
    end;
  finally
    RegionCounts.Free;
  end;
end;

function TBaseFeatureMatcher.MatchSpecialChar(const ACodePoints: array of UInt32; AEncoding: TChineseEncodingType): TMatchResult;
var
  SpecialCharCounts: TDictionary<TSpecialCharType, Integer>;
  ReferenceData: TFeatureDataCollection;
  SpecialCharData: TSpecialCharFeatureData;
  TotalSpecialChars, TotalPoints: Integer;
  i, j: Integer;
begin
  // 初始化结果
  Result.ResultType := mrtNoMatch;
  Result.Score := 0.0;
  Result.EncodingType := AEncoding;
  Result.Description := '';
  
  // 如果没有码点，则返回无匹配
  TotalPoints := Length(ACodePoints);
  if TotalPoints = 0 then
  begin
    Result.Description := '没有Unicode码点可分析';
    Exit;
  end;
  
  // 初始化特殊字符计数器
  SpecialCharCounts := TDictionary<TSpecialCharType, Integer>.Create;
  try
    // 获取参考数据
    ReferenceData := FStorage.QueryFeatureData(AEncoding, fdtSpecialChar);
    try
      if (ReferenceData = nil) or (ReferenceData.Count = 0) then
      begin
        Result.Description := '没有找到参考特殊字符数据';
        Exit;
      end;
      
      // 统计特殊字符
      TotalSpecialChars := 0;
      
      for i := 0 to TotalPoints - 1 do
      begin
        for j := 0 to ReferenceData.Count - 1 do
        begin
          if not (ReferenceData.GetItem(j) is TSpecialCharFeatureData) then
            Continue;
            
          SpecialCharData := ReferenceData.GetItem(j) as TSpecialCharFeatureData;
          
          // 检查码点是否匹配特殊字符
          if ACodePoints[i] = SpecialCharData.Data.CharCode then
          begin
            Inc(TotalSpecialChars);
            
            if SpecialCharCounts.ContainsKey(SpecialCharData.Data.CharType) then
              SpecialCharCounts[SpecialCharData.Data.CharType] := SpecialCharCounts[SpecialCharData.Data.CharType] + 1
            else
              SpecialCharCounts.Add(SpecialCharData.Data.CharType, 1);
              
            Break; // 一个码点只匹配一个特殊字符
          end;
        end;
      end;
      
      // 计算最终分数(0.0~1.0)
      if TotalPoints > 0 then
        Result.Score := Min(1.0, TotalSpecialChars / (TotalPoints * 0.2))
      else
        Result.Score := 0.0;
        
      // 设置结果类型
      Result.ResultType := CalculateResultType(Result.Score);
      
      // 生成描述
      var Desc := Format('特殊字符匹配分数: %.2f, 识别特殊字符:', [Result.Score]);
      for var CharType in SpecialCharCounts.Keys do
      begin
        var TypeStr := '';
        case CharType of
          sctPunctuation: TypeStr := '标点符号';
          sctMathSymbol: TypeStr := '数学符号';
          sctCurrency: TypeStr := '货币符号';
          sctUnit: TypeStr := '单位符号';
          sctArrow: TypeStr := '箭头符号';
          sctGeometric: TypeStr := '几何符号';
          sctBracket: TypeStr := '括号';
          sctDiacritic: TypeStr := '变音符号';
          sctHKSCSSpecial: TypeStr := 'HKSCS特殊字符';
          sctOther: TypeStr := '其他符号';
        end;
        
        Desc := Desc + ' ' + TypeStr + '(' + IntToStr(SpecialCharCounts[CharType]) + ')';
      end;
      
      Result.Description := Desc;
    finally
      ReferenceData.Free;
    end;
  finally
    SpecialCharCounts.Free;
  end;
end;

function TBaseFeatureMatcher.MatchLanguageFeature(const AText: string; AEncoding: TChineseEncodingType): TMatchResult;
var
  ReferenceData: TFeatureDataCollection;
  LangFeatureData: TLanguageFeatureFeatureData;
  TotalFeatures, MatchedFeatures: Integer;
  i: Integer;
begin
  // 初始化结果
  Result.ResultType := mrtNoMatch;
  Result.Score := 0.0;
  Result.EncodingType := AEncoding;
  Result.Description := '';
  
  // 如果文本为空，则返回无匹配
  if AText = '' then
  begin
    Result.Description := '文本为空';
    Exit;
  end;
  
  // 获取参考数据
  ReferenceData := FStorage.QueryFeatureData(AEncoding, fdtLanguageFeature);
  try
    if (ReferenceData = nil) or (ReferenceData.Count = 0) then
    begin
      Result.Description := '没有找到参考语言特征数据';
      Exit;
    end;
    
    // 统计匹配的语言特征
    TotalFeatures := ReferenceData.Count;
    MatchedFeatures := 0;
    
    for i := 0 to TotalFeatures - 1 do
    begin
      if not (ReferenceData.GetItem(i) is TLanguageFeatureFeatureData) then
        Continue;
        
      LangFeatureData := ReferenceData.GetItem(i) as TLanguageFeatureFeatureData;
      
      // 检查文本是否包含特征内容
      if ContainsText(AText, LangFeatureData.Data.Content) then
        Inc(MatchedFeatures);
    end;
    
    // 计算最终分数(0.0~1.0)
    if TotalFeatures > 0 then
      Result.Score := Min(1.0, MatchedFeatures / (Sqrt(TotalFeatures) * 0.5))
    else
      Result.Score := 0.0;
      
    // 设置结果类型
    Result.ResultType := CalculateResultType(Result.Score);
    Result.Description := Format('语言特征匹配分数: %.2f, 匹配数: %d/%d', [Result.Score, MatchedFeatures, TotalFeatures]);
  finally
    ReferenceData.Free;
  end;
end;

function TBaseFeatureMatcher.MatchComprehensive(const AData: array of Byte; const AText: string; AEncoding: TChineseEncodingType): TMatchResult;
var
  TextFromBytes: string;
  CodePoints: TArray<UInt32>;
  ByteFreqResult, CharFreqResult, BytePairResult, RegionResult, SpecialCharResult, LangFeatureResult: TMatchResult;
  WeightSum, ScoreSum: Double;
begin
  // 初始化结果
  Result.ResultType := mrtNoMatch;
  Result.Score := 0.0;
  Result.EncodingType := AEncoding;
  Result.Description := '';
  
  // 如果没有数据，则返回无匹配
  if Length(AData) = 0 then
  begin
    Result.Description := '没有数据可分析';
    Exit;
  end;
  
  // 如果没有提供文本，则尝试从字节数据转换
  if AText = '' then
    TextFromBytes := BytesToText(AData, AEncoding)
  else
    TextFromBytes := AText;
    
  // 提取Unicode码点
  CodePoints := ExtractCodePoints(TextFromBytes);
  
  // 执行各种匹配
  ByteFreqResult := MatchByteFrequency(AData, AEncoding);
  CharFreqResult := MatchCharFrequency(TextFromBytes, AEncoding);
  BytePairResult := MatchBytePair(AData, AEncoding);
  RegionResult := MatchRegion(CodePoints, AEncoding);
  SpecialCharResult := MatchSpecialChar(CodePoints, AEncoding);
  LangFeatureResult := MatchLanguageFeature(TextFromBytes, AEncoding);
  
  // 加权综合分数计算
  WeightSum := 0.0;
  ScoreSum := 0.0;
  
  // 字节频率匹配权重
  ScoreSum := ScoreSum + ByteFreqResult.Score * 0.3;
  WeightSum := WeightSum + 0.3;
  
  // 字符频率匹配权重
  ScoreSum := ScoreSum + CharFreqResult.Score * 0.2;
  WeightSum := WeightSum + 0.2;
  
  // 字节对匹配权重
  ScoreSum := ScoreSum + BytePairResult.Score * 0.15;
  WeightSum := WeightSum + 0.15;
  
  // 区域特征匹配权重
  ScoreSum := ScoreSum + RegionResult.Score * 0.15;
  WeightSum := WeightSum + 0.15;
  
  // 特殊字符匹配权重
  ScoreSum := ScoreSum + SpecialCharResult.Score * 0.1;
  WeightSum := WeightSum + 0.1;
  
  // 语言特征匹配权重
  ScoreSum := ScoreSum + LangFeatureResult.Score * 0.1;
  WeightSum := WeightSum + 0.1;
  
  // 计算综合分数
  if WeightSum > 0 then
    Result.Score := ScoreSum / WeightSum
  else
    Result.Score := 0.0;
    
  // 设置结果类型
  Result.ResultType := CalculateResultType(Result.Score);
  
  // 生成描述
  Result.Description := Format('综合匹配分数: %.2f (字节:%.2f, 字符:%.2f, 字节对:%.2f, 区域:%.2f, 特殊字符:%.2f, 语言:%.2f)', 
    [Result.Score, ByteFreqResult.Score, CharFreqResult.Score, BytePairResult.Score, 
     RegionResult.Score, SpecialCharResult.Score, LangFeatureResult.Score]);
end;

{ TFeatureMatcherFactory }

class function TFeatureMatcherFactory.CreateMatcher(AStorage: IFeatureDataStorage): IFeatureMatcher;
begin
  Result := TBaseFeatureMatcher.Create(AStorage);
end;

end. 