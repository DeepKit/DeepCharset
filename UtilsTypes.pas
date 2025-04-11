unit UtilsTypes;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows,
  JclBOM, JclStrings, JclStringConversions, JclFileUtils, JclStreams,
  ModelLanguage;

type
  // 编码分类枚举
  TEncodingCategory = (
    ecUnicode,       // Unicode编码系列
    ecChinese,       // 中文编码系列
    ecJapanese,      // 日文编码系列
    ecKorean,        // 韩文编码系列
    ecWindows,       // Windows编码系列
    ecISO,           // ISO编码系列
    ecDOS,           // DOS/OEM编码系列
    ecOther          // 其他区域编码
  );

  // 编码细节记录类型
  TEncodingInfo = record
    Name: string;          // 显示名称
    TechnicalName: string; // 技术名称（用于转换时的标识）
    CodePage: Integer;     // 代码页
    Category: TEncodingCategory; // 所属分类
    HasBOM: Boolean;       // 是否有BOM标记
    Description: string;   // 描述
    IsPrimaryEncoding: Boolean; // 是否为主要编码（在UI中优先显示）
  end;

  // 编码信息列表
  TEncodingInfoList = class
  private
    FItems: array of TEncodingInfo;
    FCount: Integer;
    function GetItem(Index: Integer): TEncodingInfo;
  public
    constructor Create;
    procedure Add(const Name, TechnicalName: string; CodePage: Integer;
                 Category: TEncodingCategory; HasBOM: Boolean;
                 const Description: string = ''; IsPrimaryEncoding: Boolean = False);
    property Items[Index: Integer]: TEncodingInfo read GetItem; default;
    property Count: Integer read FCount;
    function FindByName(const Name: string): Integer;
    function FindByTechnicalName(const TechnicalName: string): Integer;
    function FindByCodePage(CodePage: Integer; HasBOM: Boolean = False): Integer;
  end;

// 常量部分
const
  // 代码页常量
  CP_ANSI = 0;  // 使用GetACP获取
  CP_UTF16LE = 1200;
  CP_UTF16BE = 1201;
  CP_UTF32LE = 12000;
  CP_UTF32BE = 12001;
  CP_ASCII = 20127;
  CP_ISO_8859_1 = 28591;
  CP_GBK = 936;
  CP_BIG5 = 950;
  CP_SHIFT_JIS = 932;
  CP_GB18030 = 54936;
  CP_EUC_JP = 20932;
  CP_ISO_2022_JP = 50220;
  CP_ISO_2022_JP_MS = 50221;
  CP_ISO_2022_JP_JIS = 50222;
  CP_EUC_KR = 949;
  CP_JOHAB = 1361;
  CP_ISO_2022_KR = 50225;

  // 编码名称常量 - 使用标准化的技术名称
  ENCODING_ANSI = 'ANSI';
  ENCODING_UTF8 = 'UTF-8';
  ENCODING_UTF8_BOM = 'UTF-8 with BOM';
  ENCODING_UTF16_LE = 'UTF-16LE';
  ENCODING_UTF16_BE = 'UTF-16BE';
  ENCODING_UTF32_LE = 'UTF-32LE';
  ENCODING_UTF32_BE = 'UTF-32BE';
  ENCODING_GBK = 'GBK';
  ENCODING_GB2312 = 'GB2312';
  ENCODING_BIG5 = 'BIG5';
  ENCODING_GB18030 = 'GB18030';
  ENCODING_ASCII = 'ASCII';
  ENCODING_SHIFT_JIS = 'Shift-JIS';
  ENCODING_EUC_JP = 'EUC-JP';
  ENCODING_ISO_2022_JP = 'ISO-2022-JP';
  ENCODING_EUC_KR = 'EUC-KR';
  ENCODING_JOHAB = 'JOHAB';

  // 显示名称常量 - 更友好的界面显示
  DISPLAY_ENCODING_UTF8 = 'UTF-8 (无BOM)';
  DISPLAY_ENCODING_UTF8_BOM = 'UTF-8 BOM';
  DISPLAY_ENCODING_GB2312 = 'GB2312 (简体中文)';
  DISPLAY_ENCODING_GBK = 'GBK (简体中文扩展)';
  DISPLAY_ENCODING_BIG5 = 'BIG5 (繁体中文)';

// 获取分类名称
function GetCategoryName(Category: TEncodingCategory): string;

// 根据编码名称获取代码页
function GetEncodingCodePage(const EncodingName: string): Integer;

// 根据代码页获取编码名称
function GetEncodingNameByCodePage(CodePage: Integer; HasBOM: Boolean = False): string;

// 检查字符串是否表示UTF-8 BOM编码
function IsUTF8BOMEncodingName(const EncodingName: string): Boolean;

// 使用 ModelLanguage 单元中的 TAppLanguage 枚举

// 语言映射记录
TLanguageMapping = record
  AppLanguage: TAppLanguage;
  LanguageCode: string;
  DisplayName: string;
end;

// 语言代码映射表
const
  LANGUAGE_MAPPINGS: array[TAppLanguage] of TLanguageMapping = (
    (AppLanguage: alChinese; LanguageCode: 'zh-CN'; DisplayName: '简体中文'),
    (AppLanguage: alEnglish; LanguageCode: 'en-US'; DisplayName: 'English'),
    (AppLanguage: alJapanese; LanguageCode: 'ja-JP'; DisplayName: '日本語'),
    (AppLanguage: alKorean; LanguageCode: 'ko-KR'; DisplayName: '한국어'),
    (AppLanguage: alSpanish; LanguageCode: 'es-ES'; DisplayName: 'Español'),
    (AppLanguage: alFrench; LanguageCode: 'fr-FR'; DisplayName: 'Français'),
    (AppLanguage: alGerman; LanguageCode: 'de-DE'; DisplayName: 'Deutsch'),
    (AppLanguage: alItalian; LanguageCode: 'it-IT'; DisplayName: 'Italiano'),
    (AppLanguage: alChineseTraditional; LanguageCode: 'zh-TW'; DisplayName: '繁體中文'),
    (AppLanguage: alRussian; LanguageCode: 'ru-RU'; DisplayName: 'Русский'),
    (AppLanguage: alPortuguese; LanguageCode: 'pt-BR'; DisplayName: 'Português'),
    (AppLanguage: alArabic; LanguageCode: 'ar-SA'; DisplayName: 'العربية'),
    (AppLanguage: alDutch; LanguageCode: 'nl-NL'; DisplayName: 'Nederlands'),
    (AppLanguage: alThai; LanguageCode: 'th-TH'; DisplayName: 'ไทย'),
    (AppLanguage: alVietnamese; LanguageCode: 'vi-VN'; DisplayName: 'Tiếng Việt'),
    (AppLanguage: alPolish; LanguageCode: 'pl-PL'; DisplayName: 'Polski')
  );

// 辅助函数
function GetLanguageCodeByEnum(Lang: TAppLanguage): string;
function GetLanguageEnumByCode(const Code: string): TAppLanguage;
function GetLanguageDisplayName(Lang: TAppLanguage): string;

var
  // 全局编码列表对象
  GlobalEncodingList: TEncodingInfoList = nil;

// 初始化和清理全局编码列表
procedure InitializeEncodingList;
procedure FinalizeEncodingList;

implementation

function GetLanguageCodeByEnum(Lang: TAppLanguage): string;
begin
  Result := LANGUAGE_MAPPINGS[Lang].LanguageCode;
end;

function GetLanguageEnumByCode(const Code: string): TAppLanguage;
var
  Lang: TAppLanguage;
begin
  Result := alEnglish; // 默认

  for Lang := Low(TAppLanguage) to High(TAppLanguage) do
  begin
    if LANGUAGE_MAPPINGS[Lang].LanguageCode = Code then
    begin
      Result := Lang;
      Break;
    end;
  end;
end;

function GetLanguageDisplayName(Lang: TAppLanguage): string;
begin
  Result := LANGUAGE_MAPPINGS[Lang].DisplayName;
end;

// 获取分类名称
function GetCategoryName(Category: TEncodingCategory): string;
begin
  case Category of
    ecUnicode:  Result := 'Unicode编码';
    ecChinese:  Result := '中文编码';
    ecJapanese: Result := '日文编码';
    ecKorean:   Result := '韩文编码';
    ecWindows:  Result := 'Windows编码';
    ecISO:      Result := 'ISO编码';
    ecDOS:      Result := 'DOS/OEM编码';
    ecOther:    Result := '其他区域编码';
    else        Result := '未知分类';
  end;
end;

// 根据编码名称获取代码页
function GetEncodingCodePage(const EncodingName: string): Integer;
var
  UpperEncName: string;
  Index: Integer;
begin
  // 首先尝试在全局列表中查找
  if Assigned(GlobalEncodingList) then
  begin
    Index := GlobalEncodingList.FindByTechnicalName(EncodingName);
    if Index >= 0 then
      Exit(GlobalEncodingList[Index].CodePage);
  end;

  // 如果没找到，使用传统的匹配方法
  UpperEncName := UpperCase(EncodingName);

  // Unicode编码
  if (UpperEncName = 'UTF-8') or (UpperEncName = 'UTF8') then
    Result := CP_UTF8
  else if IsUTF8BOMEncodingName(EncodingName) then
    Result := CP_UTF8
  else if (UpperEncName = 'UTF-16LE') or (UpperEncName = 'UTF16LE') or
          (UpperEncName = 'UNICODE') then
    Result := CP_UTF16LE
  else if (UpperEncName = 'UTF-16BE') or (UpperEncName = 'UTF16BE') then
    Result := CP_UTF16BE
  else if (UpperEncName = 'UTF-32LE') or (UpperEncName = 'UTF32LE') then
    Result := CP_UTF32LE
  else if (UpperEncName = 'UTF-32BE') or (UpperEncName = 'UTF32BE') then
    Result := CP_UTF32BE

  // 中文编码
  else if (UpperEncName = 'GBK') or (UpperEncName = 'GB2312') or
          (UpperEncName = '936') then
    Result := CP_GBK
  else if (UpperEncName = 'BIG5') or (UpperEncName = '950') then
    Result := CP_BIG5
  else if UpperEncName = 'GB18030' then
    Result := CP_GB18030

  // 日文编码
  else if (UpperEncName = 'SHIFT-JIS') or (UpperEncName = 'SHIFT_JIS') then
    Result := CP_SHIFT_JIS

  // 如果是数字格式的代码页
  else if TryStrToInt(EncodingName, Result) then
    // 已经转换为Integer了

  // 未知的编码
  else
    Result := GetACP(); // 返回系统默认代码页
end;

// 根据代码页获取编码名称
function GetEncodingNameByCodePage(CodePage: Integer; HasBOM: Boolean = False): string;
var
  Index: Integer;
begin
  // 首先尝试在全局列表中查找
  if Assigned(GlobalEncodingList) then
  begin
    Index := GlobalEncodingList.FindByCodePage(CodePage, HasBOM);
    if Index >= 0 then
      Exit(GlobalEncodingList[Index].TechnicalName);
  end;

  // 如果没找到，使用传统的匹配方法
  case CodePage of
    CP_UTF8:
      if HasBOM then
        Result := ENCODING_UTF8_BOM  // 统一使用 'UTF-8 with BOM' 格式
      else
        Result := ENCODING_UTF8;
    CP_UTF16LE: Result := ENCODING_UTF16_LE;
    CP_UTF16BE: Result := ENCODING_UTF16_BE;
    CP_UTF32LE: Result := ENCODING_UTF32_LE;
    CP_UTF32BE: Result := ENCODING_UTF32_BE;
    CP_GBK: Result := ENCODING_GBK;
    CP_BIG5: Result := ENCODING_BIG5;
    CP_SHIFT_JIS: Result := ENCODING_SHIFT_JIS;
    CP_GB18030: Result := ENCODING_GB18030;
    CP_ASCII: Result := ENCODING_ASCII;
    else Result := 'CP' + IntToStr(CodePage);
  end;
end;

// 检查字符串是否表示UTF-8 BOM编码
function IsUTF8BOMEncodingName(const EncodingName: string): Boolean;
begin
  Result := SameText(EncodingName, 'UTF-8') or
            SameText(EncodingName, 'UTF8') or
            SameText(EncodingName, 'UTF-8 with BOM') or
            SameText(EncodingName, 'UTF8-BOM');
end;

{ TEncodingInfoList }

constructor TEncodingInfoList.Create;
begin
  inherited Create;
  FCount := 0;
  SetLength(FItems, 0);
end;

procedure TEncodingInfoList.Add(const Name, TechnicalName: string; CodePage: Integer;
  Category: TEncodingCategory; HasBOM: Boolean; const Description: string = '';
  IsPrimaryEncoding: Boolean = False);
begin
  Inc(FCount);
  SetLength(FItems, FCount);

  with FItems[FCount - 1] do
  begin
    Name := Name;
    TechnicalName := TechnicalName;
    CodePage := CodePage;
    Category := Category;
    HasBOM := HasBOM;
    Description := Description;
    IsPrimaryEncoding := IsPrimaryEncoding;
  end;
end;

function TEncodingInfoList.FindByCodePage(CodePage: Integer; HasBOM: Boolean): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to FCount - 1 do
  begin
    if (FItems[i].CodePage = CodePage) and (FItems[i].HasBOM = HasBOM) then
    begin
      Result := i;
      Break;
    end;
  end;
end;

function TEncodingInfoList.FindByName(const Name: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to FCount - 1 do
  begin
    if SameText(FItems[i].Name, Name) then
    begin
      Result := i;
      Break;
    end;
  end;
end;

function TEncodingInfoList.FindByTechnicalName(const TechnicalName: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to FCount - 1 do
  begin
    if SameText(FItems[i].TechnicalName, TechnicalName) then
    begin
      Result := i;
      Break;
    end;
  end;
end;

function TEncodingInfoList.GetItem(Index: Integer): TEncodingInfo;
begin
  if (Index >= 0) and (Index < FCount) then
    Result := FItems[Index]
  else
    raise Exception.Create('编码列表索引越界');
end;

// 初始化编码列表
procedure InitializeEncodingList;
begin
  if Assigned(GlobalEncodingList) then
    Exit;

  GlobalEncodingList := TEncodingInfoList.Create;

  // 添加Unicode编码
  GlobalEncodingList.Add(DISPLAY_ENCODING_UTF8, ENCODING_UTF8, CP_UTF8, ecUnicode, False,
    'Unicode 8位编码，兼容ASCII，适用于网络传输', True);
  GlobalEncodingList.Add(DISPLAY_ENCODING_UTF8_BOM, ENCODING_UTF8_BOM, CP_UTF8, ecUnicode, True,
    'Unicode 8位编码，带字节顺序标记(BOM)', True);
  GlobalEncodingList.Add('UTF-16LE', ENCODING_UTF16_LE, CP_UTF16LE, ecUnicode, True,
    'Unicode 16位小端编码，Windows默认Unicode格式');
  GlobalEncodingList.Add('UTF-16BE', ENCODING_UTF16_BE, CP_UTF16BE, ecUnicode, True,
    'Unicode 16位大端编码');
  GlobalEncodingList.Add('UTF-32LE', ENCODING_UTF32_LE, CP_UTF32LE, ecUnicode, True,
    'Unicode 32位小端编码');
  GlobalEncodingList.Add('UTF-32BE', ENCODING_UTF32_BE, CP_UTF32BE, ecUnicode, True,
    'Unicode 32位大端编码');

  // 添加中文编码
  GlobalEncodingList.Add('ANSI/简体中文(GB2312)', ENCODING_GB2312, CP_GBK, ecChinese, False,
    '简体中文编码，支持6763个汉字', True);
  GlobalEncodingList.Add(DISPLAY_ENCODING_GBK, ENCODING_GBK, CP_GBK, ecChinese, False,
    '中国国家标准编码，支持21003个汉字');
  GlobalEncodingList.Add('GB18030', ENCODING_GB18030, CP_GB18030, ecChinese, False,
    '中国国家标准编码，支持7万多个汉字，包括繁体');
  GlobalEncodingList.Add(DISPLAY_ENCODING_BIG5, ENCODING_BIG5, CP_BIG5, ecChinese, False,
    '繁体中文编码，主要用于台湾、香港地区');

  // 添加日文编码
  GlobalEncodingList.Add('Shift-JIS', ENCODING_SHIFT_JIS, CP_SHIFT_JIS, ecJapanese, False,
    '日语编码，Windows日文版的默认编码');
  GlobalEncodingList.Add('EUC-JP', ENCODING_EUC_JP, CP_EUC_JP, ecJapanese, False,
    '日语扩展Unix编码');
  GlobalEncodingList.Add('ISO-2022-JP', ENCODING_ISO_2022_JP, CP_ISO_2022_JP, ecJapanese, False,
    '日语JIS编码');

  // 添加韩文编码
  GlobalEncodingList.Add('EUC-KR', ENCODING_EUC_KR, CP_EUC_KR, ecKorean, False,
    '韩语扩展Unix编码');
  GlobalEncodingList.Add('JOHAB', ENCODING_JOHAB, CP_JOHAB, ecKorean, False,
    '韩语Johab编码');

  // 添加Windows编码系列
  GlobalEncodingList.Add('Windows-1250', 'Windows-1250', 1250, ecWindows, False,
    '中欧语言编码');
  GlobalEncodingList.Add('Windows-1251', 'Windows-1251', 1251, ecWindows, False,
    '西里尔文编码');
  GlobalEncodingList.Add('Windows-1252', 'Windows-1252', 1252, ecWindows, False,
    '西欧语言编码', True);
  GlobalEncodingList.Add('Windows-1253', 'Windows-1253', 1253, ecWindows, False,
    '希腊文编码');
  GlobalEncodingList.Add('Windows-1254', 'Windows-1254', 1254, ecWindows, False,
    '土耳其文编码');
  GlobalEncodingList.Add('Windows-1255', 'Windows-1255', 1255, ecWindows, False,
    '希伯来文编码');
  GlobalEncodingList.Add('Windows-1256', 'Windows-1256', 1256, ecWindows, False,
    '阿拉伯文编码');
  GlobalEncodingList.Add('Windows-1257', 'Windows-1257', 1257, ecWindows, False,
    '波罗的海文编码');
  GlobalEncodingList.Add('Windows-1258', 'Windows-1258', 1258, ecWindows, False,
    '越南文编码');
  GlobalEncodingList.Add('Windows-874', 'Windows-874', 874, ecWindows, False,
    '泰文编码');

  // 添加ISO编码系列
  GlobalEncodingList.Add('ISO-8859-1', 'ISO-8859-1', CP_ISO_8859_1, ecISO, False,
    '拉丁文1，西欧语言编码');
  GlobalEncodingList.Add('ISO-8859-2', 'ISO-8859-2', 28592, ecISO, False,
    '拉丁文2，中欧语言编码');
  GlobalEncodingList.Add('ISO-8859-3', 'ISO-8859-3', 28593, ecISO, False,
    '拉丁文3，南欧语言编码');
  GlobalEncodingList.Add('ISO-8859-4', 'ISO-8859-4', 28594, ecISO, False,
    '拉丁文4，北欧语言编码');
  GlobalEncodingList.Add('ISO-8859-5', 'ISO-8859-5', 28595, ecISO, False,
    '拉丁文/西里尔文编码');
  GlobalEncodingList.Add('ISO-8859-6', 'ISO-8859-6', 28596, ecISO, False,
    '拉丁文/阿拉伯文编码');
  GlobalEncodingList.Add('ISO-8859-7', 'ISO-8859-7', 28597, ecISO, False,
    '拉丁文/希腊文编码');
  GlobalEncodingList.Add('ISO-8859-8', 'ISO-8859-8', 28598, ecISO, False,
    '拉丁文/希伯来文编码');
  GlobalEncodingList.Add('ISO-8859-9', 'ISO-8859-9', 28599, ecISO, False,
    '拉丁文5，土耳其文编码');
  GlobalEncodingList.Add('ISO-8859-13', 'ISO-8859-13', 28603, ecISO, False,
    '拉丁文7，波罗的海文编码');
  GlobalEncodingList.Add('ISO-8859-15', 'ISO-8859-15', 28605, ecISO, False,
    '拉丁文9，西欧语言编码，带欧元符号');

  // 添加DOS/OEM编码
  GlobalEncodingList.Add('IBM437/CP437', 'IBM437', 437, ecDOS, False,
    '美国编码');
  GlobalEncodingList.Add('IBM850/CP850', 'IBM850', 850, ecDOS, False,
    '西欧语言编码');
  GlobalEncodingList.Add('IBM852/CP852', 'IBM852', 852, ecDOS, False,
    '中欧语言编码');
  GlobalEncodingList.Add('IBM855/CP855', 'IBM855', 855, ecDOS, False,
    'OEM西里尔文编码');
  GlobalEncodingList.Add('IBM866/CP866', 'IBM866', 866, ecDOS, False,
    '西里尔文编码');

  // 添加其他区域编码
  GlobalEncodingList.Add('KOI8-R', 'KOI8-R', 20866, ecOther, False,
    '俄文编码');
  GlobalEncodingList.Add('KOI8-U', 'KOI8-U', 21866, ecOther, False,
    '乌克兰文编码');
  GlobalEncodingList.Add('ASCII', ENCODING_ASCII, CP_ASCII, ecOther, False,
    '美国标准信息交换码，7位编码', True);
end;

// 清理编码列表
procedure FinalizeEncodingList;
begin
  if Assigned(GlobalEncodingList) then
  begin
    FreeAndNil(GlobalEncodingList);
  end;
end;

initialization
  InitializeEncodingList;

finalization
  FinalizeEncodingList;

end.