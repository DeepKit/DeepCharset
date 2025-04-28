unit ChineseEncodingFeatureDB.Types;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  // 中文编码类型
  TChineseEncodingType = (
    cetGB18030,    // GB18030编码
    cetGBK,        // GBK编码
    cetGB2312,     // GB2312编码
    cetBig5,       // Big5编码
    cetBig5HKSCS,  // Big5-HKSCS编码
    cetUTF8,       // UTF-8编码
    cetUTF16LE,    // UTF-16 Little Endian编码
    cetUTF16BE,    // UTF-16 Big Endian编码
    cetUTF32LE,    // UTF-32 Little Endian编码
    cetUTF32BE,    // UTF-32 Big Endian编码
    cetUnknown     // 未知编码
  );

  // 特征数据类型
  TFeatureDataType = (
    fdtByteFrequency,    // 字节频率数据
    fdtCharFrequency,    // 字符频率数据
    fdtBytePair,         // 字节对数据
    fdtRegion,           // 区域数据
    fdtSpecialChar,      // 特殊字符数据
    fdtLanguageFeature,  // 语言特征数据
    fdtOther             // 其他数据类型
  );

  // 字符类型
  TCharType = (
    ctCommon,      // 常用汉字
    ctLessCommon,  // 次常用汉字
    ctRare,        // 罕用汉字
    ctPunctuation, // 标点符号
    ctSymbol,      // 符号
    ctNumber,      // 数字
    ctLetter,      // 字母
    ctOther        // 其他
  );

  // 区域类型
  TRegionType = (
    rtASCII,           // ASCII区域
    rtLevel1Hanzi,     // 一级汉字区
    rtLevel2Hanzi,     // 二级汉字区
    rtSymbol,          // 符号区
    rtPunctuation,     // 标点符号区
    rtExtendedHanzi,   // 扩展汉字区
    rtHKSCSHanzi,      // HKSCS汉字区
    rtUserDefined,     // 用户自定义区
    rtReserved,        // 保留区
    rtOther            // 其他区域
  );

  // 特殊字符类型
  TSpecialCharType = (
    sctPunctuation,    // 标点符号
    sctMathSymbol,     // 数学符号
    sctCurrency,       // 货币符号
    sctUnit,           // 单位符号
    sctArrow,          // 箭头符号
    sctGeometric,      // 几何符号
    sctBracket,        // 括号
    sctDiacritic,      // 变音符号
    sctHKSCSSpecial,   // HKSCS特殊字符
    sctOther           // 其他特殊符号
  );

  // 语言特征类型
  TLanguageFeatureType = (
    lftCommonWord,      // 常用词
    lftCommonPhrase,    // 常用短语
    lftIdiom,           // 成语
    lftProperNoun,      // 专有名词
    lftGrammarPattern,  // 语法模式
    lftCollocation,     // 词语搭配
    lftHKSCSSpecific,   // HKSCS特有表达
    lftOther            // 其他语言特征
  );

  // 字节频率数据
  TByteFrequencyData = record
    Encoding: TChineseEncodingType;
    ByteValues: array[0..255] of Double;
  end;

  // 字符频率数据
  TCharFrequencyData = record
    Encoding: TChineseEncodingType;
    CharCode: UInt32;     // Unicode码点
    FirstByte: Byte;      // 编码首字节
    SecondByte: Byte;     // 编码次字节
    ThirdByte: Byte;      // 编码第三字节（用于四字节编码）
    FourthByte: Byte;     // 编码第四字节（用于四字节编码）
    Frequency: Double;    // 使用频率
    Character: string;    // 字符
    CharType: TCharType;  // 字符类型
    Description: string;  // 描述
  end;

  // 字节对频率数据
  TBytePairFrequencyData = record
    Encoding: TChineseEncodingType;
    FirstByte: Byte;
    SecondByte: Byte;
    Frequency: Double;
  end;

  // 区域特征数据
  TRegionData = record
    Encoding: TChineseEncodingType;
    RegionType: TRegionType;
    StartRange: UInt32;
    EndRange: UInt32;
    Description: string;
  end;

  // 特殊字符数据
  TSpecialCharData = record
    Encoding: TChineseEncodingType;
    CharType: TSpecialCharType;
    CharCode: UInt32;     // Unicode码点
    FirstByte: Byte;      // 编码首字节
    SecondByte: Byte;     // 编码次字节
    ThirdByte: Byte;      // 编码第三字节（用于四字节编码）
    FourthByte: Byte;     // 编码第四字节（用于四字节编码）
    Character: string;    // 字符
    Description: string;  // 描述
  end;

  // 语言特征数据
  TLanguageFeatureData = record
    Encoding: TChineseEncodingType;
    FeatureType: TLanguageFeatureType;
    Content: string;           // 内容
    Frequency: Double;         // 使用频率
    Description: string;       // 描述
    EncodedBytes: TBytes;      // 编码字节序列
  end;

  // 特征数据基类
  TFeatureData = class
  private
    FDataType: TFeatureDataType;
    FEncoding: TChineseEncodingType;
    FID: Integer;
    FDescription: string;
    FLastUpdated: TDateTime;
  public
    constructor Create(ADataType: TFeatureDataType; AEncoding: TChineseEncodingType);
    
    property DataType: TFeatureDataType read FDataType;
    property Encoding: TChineseEncodingType read FEncoding;
    property ID: Integer read FID write FID;
    property Description: string read FDescription write FDescription;
    property LastUpdated: TDateTime read FLastUpdated write FLastUpdated;
  end;

  // 字节频率特征数据
  TByteFrequencyFeatureData = class(TFeatureData)
  private
    FData: TByteFrequencyData;
  public
    constructor Create(AEncoding: TChineseEncodingType);
    
    property Data: TByteFrequencyData read FData write FData;
  end;

  // 字符频率特征数据
  TCharFrequencyFeatureData = class(TFeatureData)
  private
    FData: TCharFrequencyData;
  public
    constructor Create(AEncoding: TChineseEncodingType);
    
    property Data: TCharFrequencyData read FData write FData;
  end;

  // 字节对频率特征数据
  TBytePairFreatureData = class(TFeatureData)
  private
    FData: TBytePairFrequencyData;
  public
    constructor Create(AEncoding: TChineseEncodingType);
    
    property Data: TBytePairFrequencyData read FData write FData;
  end;

  // 区域特征数据
  TRegionFeatureData = class(TFeatureData)
  private
    FData: TRegionData;
  public
    constructor Create(AEncoding: TChineseEncodingType);
    
    property Data: TRegionData read FData write FData;
  end;

  // 特殊字符特征数据
  TSpecialCharFeatureData = class(TFeatureData)
  private
    FData: TSpecialCharData;
  public
    constructor Create(AEncoding: TChineseEncodingType);
    
    property Data: TSpecialCharData read FData write FData;
  end;

  // 语言特征数据
  TLanguageFeatureFeatureData = class(TFeatureData)
  private
    FData: TLanguageFeatureData;
  public
    constructor Create(AEncoding: TChineseEncodingType);
    
    property Data: TLanguageFeatureData read FData write FData;
  end;

  // 特征数据集合
  TFeatureDataCollection = class
  private
    FItems: TObjectList<TFeatureData>;
    FEncoding: TChineseEncodingType;
    FDataType: TFeatureDataType;
  public
    constructor Create(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType);
    destructor Destroy; override;
    
    procedure Add(AItem: TFeatureData);
    procedure Remove(AItem: TFeatureData);
    procedure Clear;
    function Count: Integer;
    function GetItem(Index: Integer): TFeatureData;
    
    property Encoding: TChineseEncodingType read FEncoding;
    property DataType: TFeatureDataType read FDataType;
  end;

  // 特征数据库配置
  TFeatureDBConfig = record
    EnableCaching: Boolean;
    CacheSize: Integer;
    AutoUpdate: Boolean;
    UpdateInterval: Integer;
    LoggingEnabled: Boolean;
    LogLevel: Integer;
    LogFile: string;
  end;

  // 特征匹配结果
  TFeatureMatchResult = record
    Encoding: TChineseEncodingType;
    MatchScore: Double;
    Confidence: Double;
    MatchedFeatures: Integer;
    TotalFeatures: Integer;
    ProcessingTime: Double;
    Diagnostics: TArray<string>;
  end;

implementation

{ TFeatureData }

constructor TFeatureData.Create(ADataType: TFeatureDataType; AEncoding: TChineseEncodingType);
begin
  inherited Create;
  FDataType := ADataType;
  FEncoding := AEncoding;
  FLastUpdated := Now;
end;

{ TByteFrequencyFeatureData }

constructor TByteFrequencyFeatureData.Create(AEncoding: TChineseEncodingType);
begin
  inherited Create(fdtByteFrequency, AEncoding);
  FillChar(FData, SizeOf(FData), 0);
  FData.Encoding := AEncoding;
end;

{ TCharFrequencyFeatureData }

constructor TCharFrequencyFeatureData.Create(AEncoding: TChineseEncodingType);
begin
  inherited Create(fdtCharFrequency, AEncoding);
  FillChar(FData, SizeOf(FData), 0);
  FData.Encoding := AEncoding;
end;

{ TBytePairFreatureData }

constructor TBytePairFreatureData.Create(AEncoding: TChineseEncodingType);
begin
  inherited Create(fdtBytePair, AEncoding);
  FillChar(FData, SizeOf(FData), 0);
  FData.Encoding := AEncoding;
end;

{ TRegionFeatureData }

constructor TRegionFeatureData.Create(AEncoding: TChineseEncodingType);
begin
  inherited Create(fdtRegion, AEncoding);
  FillChar(FData, SizeOf(FData), 0);
  FData.Encoding := AEncoding;
end;

{ TSpecialCharFeatureData }

constructor TSpecialCharFeatureData.Create(AEncoding: TChineseEncodingType);
begin
  inherited Create(fdtSpecialChar, AEncoding);
  FillChar(FData, SizeOf(FData), 0);
  FData.Encoding := AEncoding;
end;

{ TLanguageFeatureFeatureData }

constructor TLanguageFeatureFeatureData.Create(AEncoding: TChineseEncodingType);
begin
  inherited Create(fdtLanguageFeature, AEncoding);
  FillChar(FData, SizeOf(FData), 0);
  FData.Encoding := AEncoding;
end;

{ TFeatureDataCollection }

constructor TFeatureDataCollection.Create(AEncoding: TChineseEncodingType; ADataType: TFeatureDataType);
begin
  inherited Create;
  FItems := TObjectList<TFeatureData>.Create(True);
  FEncoding := AEncoding;
  FDataType := ADataType;
end;

destructor TFeatureDataCollection.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TFeatureDataCollection.Add(AItem: TFeatureData);
begin
  if (AItem.Encoding = FEncoding) and (AItem.DataType = FDataType) then
    FItems.Add(AItem);
end;

procedure TFeatureDataCollection.Remove(AItem: TFeatureData);
begin
  FItems.Remove(AItem);
end;

procedure TFeatureDataCollection.Clear;
begin
  FItems.Clear;
end;

function TFeatureDataCollection.Count: Integer;
begin
  Result := FItems.Count;
end;

function TFeatureDataCollection.GetItem(Index: Integer): TFeatureData;
begin
  if (Index >= 0) and (Index < FItems.Count) then
    Result := FItems[Index]
  else
    Result := nil;
end;

end.
