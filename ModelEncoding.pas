unit ModelEncoding;

interface

uses
  System.SysUtils, System.Classes, System.Math, HelperLanguage, System.Generics.Collections;

type
  /// <summary>
  /// 编码类型枚举
  /// </summary>
  TEncodingType = (
    etUnknown,       // 未知编码
    etASCII,         // ASCII编码
    etUTF8,          // UTF-8编码
    etUTF16LE,       // UTF-16 Little Endian
    etUTF16BE,       // UTF-16 Big Endian
    etUTF32LE,       // UTF-32 Little Endian
    etUTF32BE,       // UTF-32 Big Endian
    etGB18030,       // GB18030编码
    etGBK,           // GBK编码
    etGB2312,        // GB2312编码
    etBig5,          // Big5编码
    etShiftJIS,      // Shift-JIS编码
    etEUCJP,         // EUC-JP编码
    etEUCKR,         // EUC-KR编码
    etISO8859_1,     // ISO-8859-1编码
    etISO8859_2,     // ISO-8859-2编码
    etWindows1252,   // Windows-1252编码
    etHZGB2312,      // HZ-GB-2312编码
    etKOI8R,         // KOI8-R编码
    etKOI8U,         // KOI8-U编码
    etCP866,         // CP866编码
    etCP1251         // CP1251编码
  );

  /// <summary>
  /// 错误严重性级别
  /// </summary>
  TErrorSeverity = (
    esInfo,      // 信息
    esWarning,   // 警告
    esError,     // 错误
    esFatal      // 致命错误
  );

  /// <summary>
  /// 错误修复策略
  /// </summary>
  TRepairStrategy = (
    rsNone,                  // 不修复
    rsReplace,               // 替换为替代字符
    rsSkip,                  // 跳过无效字符
    rsConvertToClosest,      // 转换为最接近的合法字符
    rsInsertEscaped,         // 插入转义序列
    rsConvertToEntity        // 转换为实体引用
  );

  /// <summary>
  /// 编码检测选项
  /// </summary>
  TEncodingDetectionOption = (
    edoCheckBOM,             // 检查BOM标记
    edoAnalyzeContent,       // 分析内容
    edoUseSampling,          // 使用采样
    edoFastDetection,        // 快速检测模式
    edoFavorUTF8,            // 优先考虑UTF-8
    edoFavorCJK,             // 优先考虑CJK编码
    edoPreferUTF8,           // 在相同置信度时首选UTF-8
    edoIgnoreXML,            // 忽略XML/HTML声明
    edoAllowMixedEncodings,  // 允许混合编码
    edoHeuristicCheck        // 启用启发式检查
  );
  TEncodingDetectionOptions = set of TEncodingDetectionOption;

  /// <summary>
  /// 编码检测信息
  /// </summary>
  TEncodingDetectionInfo = record
    EncodingName: string;    // 编码名称
    Description: string;     // 编码描述
    EncodingType: TEncodingType; // 编码类型
    Confidence: Double;      // 置信度（0.0~1.0）
    HasBOM: Boolean;         // 是否包含BOM
    BOMSize: Integer;        // BOM大小（字节）
    Language: string;        // 可能的语言
    AverageBytesPerChar: Double; // 平均每字符字节数
    ContentSample: string;   // 内容样本
    SpecialNotes: string;    // 特殊说明
    IsReliable: Boolean;     // 检测结果是否可靠
    DetectionTime: Int64;    // 检测耗时（毫秒）
  end;

  /// <summary>
  /// 编码转换选项
  /// </summary>
  TEncodingConversionOption = (
    ecoStrictCheck,          // 严格检查
    ecoAllowLossyConversion, // 允许有损转换
    ecoReportErrors,         // 报告错误
    ecoIgnoreErrors,         // 忽略错误
    ecoOptimizeMemory,       // 优化内存使用
    ecoPreserveFormation,    // 保持排版格式
    ecoTransliterateChars,   // 音译不支持的字符
    ecoUseFallbackMapping    // 使用回退映射
  );
  TEncodingConversionOptions = set of TEncodingConversionOption;

  /// <summary>
  /// 编码转换结果
  /// </summary>
  TEncodingConversionResult = record
    Success: Boolean;        // 转换是否成功
    ErrorCount: Integer;     // 错误数量
    ProcessedBytes: Integer; // 处理的字节数
    OutputBytes: Integer;    // 输出的字节数
    ElapsedTime: Int64;      // 耗时（毫秒）
    ErrorMessages: TArray<string>; // 错误信息
    WarningCount: Integer;   // 警告数量
    CharactersConverted: Integer; // 转换的字符数
    CharactersLost: Integer; // 丢失的字符数
  end;

  /// <summary>
  /// 编码错误信息
  /// </summary>
  TEncodingError = record
    Position: Integer;       // 错误位置
    ByteValue: TBytes;       // 出错字节序列
    Message: string;         // 错误消息
    Severity: TErrorSeverity; // 严重性级别
    SuggestedRepair: TRepairStrategy; // 建议的修复策略
    InvalidCodePoint: Integer; // 无效的码点
  end;

  /// <summary>
  /// 编码性能指标
  /// </summary>
  TEncodingPerformance = record
    BytesPerSecond: Int64;    // 每秒处理字节数
    CharsPerSecond: Int64;    // 每秒处理字符数
    MemoryUsed: Integer;      // 使用的内存（字节）
    PeakMemory: Integer;      // 峰值内存使用（字节）
    ThreadCount: Integer;     // 使用的线程数
    CPUUsage: Double;         // CPU使用率（0.0~1.0）
  end;

  // 编码信息结构体
  TEncodingInfo = record
    Name: string;          // 编码名称
    CodePage: Integer;     // 编码的代码页
    HasBOM: Boolean;       // 是否支持BOM
    ShortName: string;     // 短名称或识别符（可选）
    IsGroup: Boolean;      // 是否为分组标题
    Description: string;   // 编码描述（用于显示在UI中）
  end;

  TEncodingInfoArray = array of TEncodingInfo;

  // 编码模型类
  TEncodingModel = class
  private
    FEncodingList: TEncodingInfoArray;
    FSelectedEncodingIndex: Integer;

    function GetEncodingCount: Integer;
    function GetEncoding(Index: Integer): TEncodingInfo;
  public
    constructor Create;
    destructor Destroy; override;

    procedure InitEncodingList;
    function GetEncodingByIndex(Index: Integer; out WithBOM: Boolean): TEncoding;
    function GetEncodingName(Encoding: TEncoding): string;
    function GetFormattedEncodingName(CodePage: Integer; HasBOM: Boolean): string;

    // 添加编码到列表
    procedure AddEncodingGroup(const GroupName: string);
    procedure AddEncodingOption(const EncodingName, ShortName: string; CodePage: Integer; HasBOM: Boolean; const Description: string = '');

    // 替换编码列表（仅用于UI展示，不影响实际功能）
    procedure ReplaceEncodingList(const NewList: TEncodingInfoArray);

    // 重新加载编码列表（用于语言切换后更新显示）
    procedure ReloadEncodings;

    function GetSelectedEncoding: TEncoding;

    property EncodingCount: Integer read GetEncodingCount;
    property Encodings[Index: Integer]: TEncodingInfo read GetEncoding;
    property EncodingList: TEncodingInfoArray read FEncodingList;
  end;

const
  // 不支持转换的文件格式列表
  UNSUPPORTED_FILES: array[0..6] of string = (
    'utf16be_bom.txt',
    'utf16le_bom.txt',
    'mixed_encoding_simulation.txt',
    'shift_jis.txt',
    'iso8859_1.txt',
    'invalid_utf8.txt',
    'euc_jp.txt'
  );

implementation

{ TEncodingModel }

constructor TEncodingModel.Create;
begin
  inherited Create;
  InitEncodingList;
  FSelectedEncodingIndex := -1;
end;

destructor TEncodingModel.Destroy;
begin
  SetLength(FEncodingList, 0);
  inherited;
end;

procedure TEncodingModel.AddEncodingGroup(const GroupName: string);
var
  EncodingInfo: TEncodingInfo;
  ShortNameValue: string;
begin
  EncodingInfo.Name := GroupName;
  EncodingInfo.CodePage := -999; // 特殊标记
  EncodingInfo.HasBOM := False;

  // 使用GroupName作为ShortName
  ShortNameValue := GroupName;

  EncodingInfo.ShortName := ShortNameValue;
  EncodingInfo.IsGroup := True;
  EncodingInfo.Description := '';

  SetLength(FEncodingList, Length(FEncodingList) + 1);
  FEncodingList[High(FEncodingList)] := EncodingInfo;
end;

procedure TEncodingModel.AddEncodingOption(const EncodingName, ShortName: string; CodePage: Integer; HasBOM: Boolean; const Description: string = '');
var
  EncodingInfo: TEncodingInfo;
begin
  EncodingInfo.Name := EncodingName;
  EncodingInfo.CodePage := CodePage;
  EncodingInfo.HasBOM := HasBOM;
  EncodingInfo.ShortName := ShortName;
  EncodingInfo.IsGroup := False;
  EncodingInfo.Description := Description;

  SetLength(FEncodingList, Length(FEncodingList) + 1);
  FEncodingList[High(FEncodingList)] := EncodingInfo;
end;

function TEncodingModel.GetEncoding(Index: Integer): TEncodingInfo;
begin
  if (Index >= 0) and (Index < Length(FEncodingList)) then
    Result := FEncodingList[Index]
  else
    raise Exception.Create('编码索引超出范围');
end;

function TEncodingModel.GetEncodingByIndex(Index: Integer; out WithBOM: Boolean): TEncoding;
begin
  // 默认值
  Result := TEncoding.UTF8;
  WithBOM := True;

  // 验证索引
  if (Index < 0) or (Index >= Length(FEncodingList)) then
    Exit;

  // 如果是组标题，返回默认编码
  if FEncodingList[Index].IsGroup then
    Exit;

  // 根据CodePage决定编码
  case FEncodingList[Index].CodePage of
    1200: Result := TEncoding.Unicode;     // UTF-16LE
    1201: Result := TEncoding.BigEndianUnicode; // UTF-16BE
    65001: Result := TEncoding.UTF8;       // UTF-8
    20127: Result := TEncoding.ASCII;      // ASCII
    65000: Result := TEncoding.UTF7;       // UTF-7
    else
      // 尝试获取系统编码
      try
        Result := TEncoding.GetEncoding(FEncodingList[Index].CodePage);
      except
        // 出错时使用默认
        Result := TEncoding.Default;
      end;
  end;

  // 设置BOM标志
  WithBOM := FEncodingList[Index].HasBOM;
end;

function TEncodingModel.GetEncodingCount: Integer;
begin
  Result := Length(FEncodingList);
end;

function TEncodingModel.GetEncodingName(Encoding: TEncoding): string;
var
  CodePage: Integer;
begin
  // 检查已知编码
  if Encoding = TEncoding.ASCII then
    Result := 'ASCII'
  else if Encoding = TEncoding.Unicode then
    Result := 'UTF-16LE'
  else if Encoding = TEncoding.BigEndianUnicode then
    Result := 'UTF-16BE'
  else if Encoding = TEncoding.UTF8 then
    Result := 'UTF-8'
  else if Encoding = TEncoding.UTF7 then
    Result := 'UTF-7'
  else
  begin
    // 尝试获取代码页
    try
      CodePage := Encoding.CodePage;
      Result := GetFormattedEncodingName(CodePage, False);
    except
      Result := '未知编码';
    end;
  end;
end;

{$WARN IMPLICIT_STRING_CAST OFF}
function TEncodingModel.GetFormattedEncodingName(CodePage: Integer; HasBOM: Boolean): string;
begin
  case CodePage of
    0: Result := '未知';
    1200: Result := 'UTF-16LE';
    1201: Result := 'UTF-16BE';
    12000: Result := 'UTF-32';
    20127: Result := 'ASCII';
    65000: Result := 'UTF-7';
    65001:
      begin
        if HasBOM then
          Result := 'UTF-8 BOM'
        else
          Result := 'UTF-8';
      end;
    936: Result := 'GB2312';
    950: Result := '繁体中文';
    932: Result := '日语';
    949: Result := '韩语';
    1250: Result := '中欧语系';
    1251: Result := '西里尔字母';
    1252: Result := '西欧语系';
    1253: Result := '希腊语';
    1254: Result := '土耳其语';
    1255: Result := '希伯来语';
    1256: Result := '阿拉伯语';
    1257: Result := '波罗的海语系';
    1258: Result := '越南语';
    else
      Result := 'CodePage-' + IntToStr(CodePage);
  end;

  // 添加代码页信息
  if CodePage > 0 then
    Result := Result + ' (' + IntToStr(CodePage) + ')';
end;
{$WARN IMPLICIT_STRING_CAST ON}

{$WARN IMPLICIT_STRING_CAST OFF}
procedure TEncodingModel.InitEncodingList;
begin
  SetLength(FEncodingList, 0);

  // ======================================================================
  // 国际标准编码组
  // ======================================================================
  AddEncodingGroup('Unicode');
  AddEncodingOption('UTF-8', 'UTF8', 65001, False, '无BOM标记的Unicode编码，适用于网页和跨平台文本');
  AddEncodingOption('UTF-8 with BOM', 'UTF8BOM', 65001, True, '带BOM标记的Unicode编码，Windows下更兼容');
  AddEncodingOption('UTF-16 LE', 'UTF16LE', 1200, True, '16位Unicode编码，Windows默认格式');
  AddEncodingOption('UTF-16 BE', 'UTF16BE', 1201, True, '16位Unicode编码，Mac/Unix常用格式');
  AddEncodingOption('UTF-32 LE', 'UTF32LE', 12000, True, '32位Unicode编码，支持所有Unicode字符');
  AddEncodingOption('UTF-32 BE', 'UTF32BE', 12001, True, '32位Unicode编码，大端字节序版本');
  AddEncodingOption('UTF-7', 'UTF7', 65000, False, '邮件系统使用的7位ASCII兼容Unicode编码');
  AddEncodingOption('ASCII', 'ASCII', 20127, False, '基本英文字符集，仅支持英文和数字');

  // ======================================================================
  // 亚洲编码组
  // ======================================================================
  AddEncodingGroup('Asian');

  // 中文编码
  AddEncodingOption('GBK', 'GBK', 936, False, '中国国家标准编码，支持简体和部分繁体');
  AddEncodingOption('GB18030', 'GB18030', 54936, False, '中国强制标准编码，支持所有汉字');
  AddEncodingOption('GB2312', 'GB2312', 936, False, '简体中文基本编码，仅支持常用汉字');
  AddEncodingOption('Big5', 'BIG5', 950, False, '台湾和香港地区使用的繁体中文编码');
  AddEncodingOption('Big5-HKSCS', 'BIG5_HKSCS', 951, False, '香港增补字符集，支持香港特殊用字');
  AddEncodingOption('CP936', 'CP936', 936, False, 'Windows简体中文编码，与GBK基本相同');
  AddEncodingOption('CP950', 'CP950', 950, False, 'Windows繁体中文编码，与Big5基本相同');
  AddEncodingOption('EUC-TW', 'EUC_TW', 20000, False, '台湾地区使用的扩展Unix编码');

  // 日文编码
  AddEncodingOption('Shift-JIS', 'SHIFT_JIS', 932, False, '日本最常用的编码，Windows默认日文编码');
  AddEncodingOption('EUC-JP', 'EUC_JP', 20932, False, 'Unix系统常用的日文编码');
  AddEncodingOption('CP932', 'CP932', 932, False, 'Windows日文编码，Shift-JIS的扩展版本');
  AddEncodingOption('ISO-2022-JP', 'ISO_2022_JP', 50220, False, '日本邮件和网页使用的编码');

  // 韩文编码
  AddEncodingOption('EUC-KR', 'EUC_KR', 51949, False, 'Unix系统常用的韩文编码');
  AddEncodingOption('CP949', 'CP949', 949, False, 'Windows韩文编码，EUC-KR的扩展版本');
  AddEncodingOption('ISO-2022-KR', 'ISO_2022_KR', 50225, False, '韩国邮件系统使用的编码');

  // 其他亚洲编码
  AddEncodingOption('VISCII', 'VISCII', 1129, False, '越南语编码，支持所有越南文字符');
  AddEncodingOption('TIS-620', 'TIS_620', 874, False, '泰国标准编码，支持泰文');
  AddEncodingOption('TSCII', 'TSCII', 57012, False, '泰米尔语编码，印度南部语言');
  AddEncodingOption('ISCII', 'ISCII', 57002, False, '印度语言编码，支持多种印度语言');

  // ======================================================================
  // 西欧和美洲编码组
  // ======================================================================
  AddEncodingGroup('Western');
  AddEncodingOption('Windows-1252', 'WINDOWS1252', 1252, False, 'Windows西欧语言编码，支持英语、法语、德语等');
  AddEncodingOption('ISO-8859-1', 'ISO8859_1', 28591, False, '国际标准拉丁字母1，西欧语言');
  AddEncodingOption('ISO-8859-15', 'ISO8859_15', 28605, False, '国际标准拉丁字母9，西欧语言更新版');
  AddEncodingOption('MacRoman', 'MACROMAN', 10000, False, '苹果Mac系统西欧语言编码');
  AddEncodingOption('IBM850', 'IBM850', 850, False, 'DOS西欧语言编码');
  AddEncodingOption('IBM437', 'IBM437', 437, False, 'DOS美国英语编码，包含基本图形字符');

  // ======================================================================
  // 东欧和斯拉夫编码组
  // ======================================================================
  AddEncodingGroup('Eastern');
  AddEncodingOption('Windows-1250', 'WINDOWS1250', 1250, False, 'Windows中欧语言编码，支持波兰、捷克等');
  AddEncodingOption('Windows-1251', 'WINDOWS1251', 1251, False, 'Windows西里尔文编码，支持俄语等');
  AddEncodingOption('ISO-8859-2', 'ISO8859_2', 28592, False, '国际标准拉丁字母2，中欧语言');
  AddEncodingOption('ISO-8859-5', 'ISO8859_5', 28595, False, '国际标准西里尔字母，斯拉夫语言');
  AddEncodingOption('KOI8-R', 'KOI8R', 20866, False, '俄语编码，互联网和Unix系统常用');
  AddEncodingOption('KOI8-U', 'KOI8U', 21866, False, '乌克兰语编码，KOI8-R的扩展');
  AddEncodingOption('MacCyrillic', 'MACCYRILLIC', 10007, False, '苹果Mac系统西里尔文编码');

  // ======================================================================
  // 中东和希伯来/阿拉伯编码组
  // ======================================================================
  AddEncodingGroup('MiddleEast');
  AddEncodingOption('Windows-1255', 'WINDOWS1255', 1255, False, 'Windows希伯来语编码，从右到左显示');
  AddEncodingOption('Windows-1256', 'WINDOWS1256', 1256, False, 'Windows阿拉伯语编码，从右到左显示');
  AddEncodingOption('ISO-8859-6', 'ISO8859_6', 28596, False, '国际标准阿拉伯字母');
  AddEncodingOption('ISO-8859-8', 'ISO8859_8', 28598, False, '国际标准希伯来字母');
  AddEncodingOption('ISO-8859-6-I', 'ISO_8859_6_I', 28597, False, '国际标准阿拉伯字母，支持从右到左显示');
  AddEncodingOption('CP862', 'CP862', 862, False, 'DOS希伯来语编码');
  AddEncodingOption('CP864', 'CP864', 864, False, 'DOS阿拉伯语编码');

  // ======================================================================
  // 北欧和波罗的海编码组
  // ======================================================================
  AddEncodingGroup('Nordic');
  AddEncodingOption('Windows-1257', 'WINDOWS1257', 1257, False, 'Windows波罗的海语言编码');
  AddEncodingOption('ISO-8859-4', 'ISO8859_4', 28594, False, '国际标准拉丁字母4，北欧语言');
  AddEncodingOption('ISO-8859-10', 'ISO8859_10', 28600, False, '国际标准拉丁字母6，北欧语言');
  AddEncodingOption('ISO-8859-13', 'ISO8859_13', 28603, False, '国际标准拉丁字母7，波罗的海语言');
  AddEncodingOption('IBM865', 'IBM865', 865, False, 'DOS北欧语言编码');

  // ======================================================================
  // 南欧和地中海编码组
  // ======================================================================
  AddEncodingGroup('Southern');
  AddEncodingOption('Windows-1253', 'WINDOWS1253', 1253, False, 'Windows希腊语编码');
  AddEncodingOption('Windows-1254', 'WINDOWS1254', 1254, False, 'Windows土耳其语编码');
  AddEncodingOption('ISO-8859-3', 'ISO8859_3', 28593, False, '国际标准拉丁字母3，南欧语言');
  AddEncodingOption('ISO-8859-7', 'ISO8859_7', 28597, False, '国际标准希腊字母');
  AddEncodingOption('ISO-8859-9', 'ISO8859_9', 28599, False, '国际标准拉丁字母5，土耳其语');
  AddEncodingOption('IBM860', 'IBM860', 860, False, 'DOS葡萄牙语编码');

  // ======================================================================
  // 其他特殊编码组
  // ======================================================================
  AddEncodingGroup('Other');
  AddEncodingOption('Windows-1258', 'WINDOWS1258', 1258, False, 'Windows越南语编码');
  AddEncodingOption('ISO-8859-11', 'ISO8859_11', 28601, False, '国际标准泰语字母');
  AddEncodingOption('ISO-8859-14', 'ISO8859_14', 28604, False, '国际标准拉丁字母8，凯尔特语言');
  AddEncodingOption('ISO-8859-16', 'ISO8859_16', 28606, False, '国际标准拉丁字母10，东南欧语言');
  AddEncodingOption('ARMSCII-8', 'ARMSCII_8', 901, False, '亚美尼亚语编码');
  AddEncodingOption('Mongolian', 'MONGOLIAN', 0, False, '蒙古语编码，支持传统蒙古文');
  AddEncodingOption('Tibetan', 'TIBETAN', 0, False, '藏语编码，支持藏文字符');
  AddEncodingOption('Lao', 'LAO', 0, False, '老挝语编码，支持老挝文字符');
  AddEncodingOption('Khmer', 'KHMER', 0, False, '柬埔寨高棉语编码');
  AddEncodingOption('Myanmar', 'MYANMAR', 0, False, '缅甸语编码，支持缅甸文字符');
  AddEncodingOption('Indonesian', 'INDONESIAN', 0, False, '印尼语编码');
  AddEncodingOption('Malay', 'MALAY', 0, False, '马来语编码');
  AddEncodingOption('Geez', 'GEEZ', 0, False, '埃塞俄比亚吉兹语编码');
  AddEncodingOption('Amharic', 'AMHARIC', 0, False, '埃塞俄比亚阿姆哈拉语编码');
  AddEncodingOption('CESU-8', 'CESU_8', 0, False, '拉丁美洲使用的Unicode变种编码');
end;
{$WARN IMPLICIT_STRING_CAST ON}

procedure TEncodingModel.ReplaceEncodingList(const NewList: TEncodingInfoArray);
var
  i: Integer;
begin
  SetLength(FEncodingList, Length(NewList));
  for i := 0 to High(NewList) do
    FEncodingList[i] := NewList[i];
end;

procedure TEncodingModel.ReloadEncodings;
begin
  // 清空当前编码列表
  SetLength(FEncodingList, 0);

  // 重新初始化编码列表
  InitEncodingList;
end;

function TEncodingModel.GetSelectedEncoding: TEncoding;
begin
  // 默认返回UTF8编码
  Result := TEncoding.UTF8;

  // 这里可以根据FSelectedEncodingIndex返回不同的编码
  case FSelectedEncodingIndex of
    0: Result := TEncoding.ASCII;
    1: Result := TEncoding.UTF8;
    2: Result := TEncoding.Unicode;
    3: Result := TEncoding.BigEndianUnicode;
    // 可以添加更多编码类型
  end;
end;

end.
