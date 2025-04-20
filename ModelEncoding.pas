unit ModelEncoding;

interface

uses
  System.SysUtils, System.Classes, System.Math, HelperLanguage;

type
  // 转换结果枚举
  TConversionResult = (crSuccess, crFailed, crSkipped, crFileNotFound, crAccessDenied, crUnsupportedEncoding, crConversionFailed);

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
  
  // 生成ShortName - 使用英文对应名称作为查找键
  if GroupName = 'Unicode编码' then
    ShortNameValue := 'Unicode'
  else if GroupName = '亚洲编码' then
    ShortNameValue := 'Asian'
  else if GroupName = '西欧/美洲编码' then
    ShortNameValue := 'Western'
  else if GroupName = '拉丁美洲编码' then
    ShortNameValue := 'LatinAmerican'
  else if GroupName = '东欧/斯拉夫编码' then
    ShortNameValue := 'EasternEuropean'
  else if GroupName = '中东/希伯来/阿拉伯编码' then
    ShortNameValue := 'MiddleEastern'
  else if GroupName = '南亚和东南亚编码' then
    ShortNameValue := 'SouthAsian'
  else if GroupName = '非洲编码' then
    ShortNameValue := 'African'
  else if GroupName = '其他编码' then
    ShortNameValue := 'Other'
  else
  begin
    // 默认情况下，使用原始名称的前几个字符作为ShortName
    ShortNameValue := GroupName;
    if Length(ShortNameValue) > 10 then
      ShortNameValue := Copy(ShortNameValue, 1, 10);
  end;
  
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

procedure TEncodingModel.InitEncodingList;
begin
  SetLength(FEncodingList, 0);

  // ======================================================================
  // Unicode编码组 - 通用标准编码，适用于全球多语言支持
  // 默认选中UTF-8 BOM作为程序默认编码
  // ======================================================================
  AddEncodingGroup('Unicode编码');
  AddEncodingOption('UTF-8', 'utf8', 65001, False, '通用Unicode编码，适用于网络和国际化应用'); // 无BOM的UTF-8
  AddEncodingOption('UTF-8 (BOM)', 'utf8bom', 65001, True, '带有字节顺序标记的UTF-8'); // 带BOM的UTF-8，默认选项
  AddEncodingOption('UTF-16LE', 'utf16le', 1200, True, '小端序Unicode编码'); // Windows默认的Unicode编码
  AddEncodingOption('UTF-16BE', 'utf16be', 1201, True, '大端序Unicode编码'); // macOS常用格式
  AddEncodingOption('UTF-32LE', 'utf32le', 12000, True, '32位小端序Unicode编码'); // 扩展Unicode，每字符固定4字节
  AddEncodingOption('UTF-32BE', 'utf32be', 12001, True, '32位大端序Unicode编码'); // 扩展Unicode，每字符固定4字节
  AddEncodingOption('UTF-7', 'utf7', 65000, False, '7位ASCII兼容的Unicode编码'); // 已淘汰，仅用于兼容性

  // ======================================================================
  // 亚洲编码组 - 放在Unicode之后，便于亚洲用户快速找到本地编码
  // 包括中文、日文、韩文等亚洲主要语言编码
  // ======================================================================
  AddEncodingGroup('亚洲编码');
  // 中文编码 - 按照使用频率排序
  AddEncodingOption('GB2312', 'gb2312', 936, False, '简体中文基本编码'); // 中国国家标准，收录6763个汉字
  AddEncodingOption('GBK', 'gbk', 936, False, '中文扩展编码'); // GB2312扩展，收录21003个汉字
  AddEncodingOption('GB18030', 'gb18030', 54936, False, '中文国家标准编码'); // 国家强制标准，完全兼容Unicode
  AddEncodingOption('CP936', 'cp936', 936, False, '简体中文Windows编码'); // Windows简体中文编码，实际上就是GBK
  AddEncodingOption('Big5', 'big5', 950, False, '繁体中文编码'); // 台湾和香港地区使用的繁体中文编码
  AddEncodingOption('CP950', 'cp950', 950, False, '繁体中文Windows编码'); // Windows繁体中文编码，基于Big5
  AddEncodingOption('Big5-HKSCS', 'big5hkscs', 951, False, '香港繁体中文增补字符集'); // 香港地区Big5扩展
  AddEncodingOption('EUC-TW', 'euctw', 20000, False, '台湾EUC编码'); // 台湾扩展Unix编码
  
  // 日文编码
  AddEncodingOption('Shift-JIS', 'sjis', 932, False, '日文主要编码'); // 日本最常用的编码，Windows默认
  AddEncodingOption('CP932', 'cp932', 932, False, '日本Windows编码'); // Windows日文编码，Shift-JIS的Microsoft实现
  AddEncodingOption('EUC-JP', 'eucjp', 20932, False, '日文扩展Unix编码'); // Unix系统日文标准编码
  AddEncodingOption('ISO-2022-JP', 'iso2022jp', 50220, False, '日文邮件和网络编码'); // 电子邮件用日文编码
  
  // 韩文编码
  AddEncodingOption('EUC-KR', 'euckr', 51949, False, '韩文扩展Unix编码'); // Unix系统韩文标准编码
  AddEncodingOption('CP949', 'cp949', 949, False, '韩国Windows编码'); // Windows韩文编码
  AddEncodingOption('Johab', 'johab', 1361, False, '韩文Johab编码'); // 韩文音节编码
  AddEncodingOption('ISO-2022-KR', 'iso2022kr', 50225, False, '韩文邮件和网络编码'); // 电子邮件用韩文编码

  // ======================================================================
  // 西欧/美洲编码组 - 西方常用编码
  // ======================================================================
  AddEncodingGroup('西欧/美洲编码');
  AddEncodingOption('Windows-1252', 'cp1252', 1252, False, '西欧Windows编码'); // Windows默认西欧编码
  AddEncodingOption('Windows-1250', 'cp1250', 1250, False, '中欧Windows编码'); // Windows中欧编码
  AddEncodingOption('MacRoman', 'macroman', 10000, False, '苹果西欧编码'); // 早期Mac OS系统使用的编码
  AddEncodingOption('IBM850', 'cp850', 850, False, 'DOS西欧编码'); // DOS系统西欧编码
  AddEncodingOption('IBM437', 'cp437', 437, False, 'DOS美国编码'); // DOS系统美国编码
  AddEncodingOption('IBM865', 'cp865', 865, False, 'DOS北欧编码'); // DOS系统北欧编码
  AddEncodingOption('IBM860', 'cp860', 860, False, 'DOS葡萄牙语编码'); // DOS系统葡萄牙语编码
  AddEncodingOption('ISO-8859-1 (Latin-1)', 'iso88591', 28591, False, '西欧语言'); // 西欧ISO标准编码
  AddEncodingOption('ISO-8859-15 (Latin-9)', 'iso885915', 28605, False, '西欧语言（含欧元符号）'); // 欧元符号版本

  // ======================================================================
  // 拉丁美洲编码组 - 中南美洲国家和原住民语言编码
  // ======================================================================
  AddEncodingGroup('拉丁美洲编码');
  AddEncodingOption('ISO-8859-1 (Latin-1)', 'iso88591-latam', 28591, False, '拉丁美洲西班牙语、葡萄牙语编码'); // 拉美地区使用的ISO-8859-1
  AddEncodingOption('Windows-1252 (LATAM)', 'cp1252-latam', 1252, False, '拉丁美洲Windows编码'); // 拉美地区Windows编码
  AddEncodingOption('MacRoman (LATAM)', 'macroman-latam', 10000, False, '拉丁美洲苹果系统编码'); // 拉美地区Mac编码
  AddEncodingOption('Quechua', 'quechua', 29001, False, '克丘亚语(安第斯山脉原住民语言)编码'); // 秘鲁、玻利维亚等地的印加后裔语言
  AddEncodingOption('Aymara', 'aymara', 29002, False, '艾马拉语(玻利维亚、秘鲁原住民语言)编码'); // 安第斯山脉南部原住民语言
  AddEncodingOption('Guaraní', 'guarani', 29003, False, '瓜拉尼语(巴拉圭、阿根廷原住民语言)编码'); // 巴拉圭官方语言之一
  AddEncodingOption('Maya', 'maya', 29004, False, '玛雅语(中美洲原住民语言)编码'); // 墨西哥、危地马拉等地区玛雅后裔语言
  AddEncodingOption('Nahuatl', 'nahuatl', 29005, False, '纳瓦特尔语(阿兹特克后裔语言)编码'); // 墨西哥原住民语言

  // ======================================================================
  // 东欧/斯拉夫编码组 - 东欧国家和斯拉夫语系编码
  // ======================================================================
  AddEncodingGroup('东欧/斯拉夫编码');
  AddEncodingOption('Windows-1253', 'cp1253', 1253, False, '希腊语Windows编码'); // Windows希腊语编码
  AddEncodingOption('Windows-1254', 'cp1254', 1254, False, '土耳其语Windows编码'); // Windows土耳其语编码
  AddEncodingOption('Windows-1257', 'cp1257', 1257, False, '波罗的海Windows编码'); // Windows波罗的海编码
  AddEncodingOption('Windows-1251', 'cp1251', 1251, False, '西里尔字母Windows编码'); // Windows俄语编码
  AddEncodingOption('KOI8-R', 'koi8r', 20866, False, '俄语编码'); // 俄语互联网标准编码
  AddEncodingOption('KOI8-U', 'koi8u', 21866, False, '乌克兰语编码'); // 乌克兰语互联网标准编码
  AddEncodingOption('MacCyrillic', 'maccyrillic', 10007, False, '苹果西里尔编码'); // Mac系统俄语编码
  AddEncodingOption('MacGreek', 'macgreek', 10006, False, '苹果希腊语编码'); // Mac系统希腊语编码
  AddEncodingOption('MacTurkish', 'macturkish', 10081, False, '苹果土耳其语编码'); // Mac系统土耳其语编码
  AddEncodingOption('ISO-8859-2 (Latin-2)', 'iso88592', 28592, False, '中欧语言'); // 中欧ISO标准编码
  AddEncodingOption('ISO-8859-3 (Latin-3)', 'iso88593', 28593, False, '南欧语言'); // 南欧ISO标准编码
  AddEncodingOption('ISO-8859-4 (Latin-4)', 'iso88594', 28594, False, '北欧语言'); // 北欧ISO标准编码
  AddEncodingOption('ISO-8859-5 (Cyrillic)', 'iso88595', 28595, False, '斯拉夫语系'); // 斯拉夫语系ISO标准编码
  AddEncodingOption('ISO-8859-7 (Greek)', 'iso88597', 28597, False, '希腊语'); // 希腊语ISO标准编码
  AddEncodingOption('ISO-8859-9 (Latin-5)', 'iso88599', 28599, False, '土耳其语'); // 土耳其语ISO标准编码
  AddEncodingOption('ISO-8859-10 (Latin-6)', 'iso885910', 28600, False, '北欧语言'); // 北欧语言ISO标准编码
  AddEncodingOption('ISO-8859-13 (Latin-7)', 'iso885913', 28603, False, '波罗的海语言'); // 波罗的海语言ISO标准编码
  AddEncodingOption('ISO-8859-14 (Latin-8)', 'iso885914', 28604, False, '凯尔特语'); // 凯尔特语ISO标准编码
  AddEncodingOption('ISO-8859-16 (Latin-10)', 'iso885916', 28606, False, '东南欧语言'); // 东南欧语言ISO标准编码

  // ======================================================================
  // 中东/希伯来/阿拉伯编码组 - 中东地区常用编码
  // ======================================================================
  AddEncodingGroup('中东/希伯来/阿拉伯编码');
  AddEncodingOption('Windows-1255', 'cp1255', 1255, False, '希伯来语Windows编码'); // Windows希伯来语编码
  AddEncodingOption('Windows-1256', 'cp1256', 1256, False, '阿拉伯语Windows编码'); // Windows阿拉伯语编码
  AddEncodingOption('CP862', 'cp862', 862, False, '希伯来语DOS编码'); // DOS希伯来语编码
  AddEncodingOption('CP864', 'cp864', 864, False, '阿拉伯语DOS编码'); // DOS阿拉伯语编码
  AddEncodingOption('ISO-8859-6 (Arabic)', 'iso88596', 28596, False, '阿拉伯语'); // 阿拉伯语ISO标准编码
  AddEncodingOption('ISO-8859-6-I', 'iso88596i', 28597, False, '阿拉伯语方向反转'); // 阿拉伯语ISO标准编码(反方向)
  AddEncodingOption('ISO-8859-8 (Hebrew)', 'iso88598', 28598, False, '希伯来语'); // 希伯来语ISO标准编码
  AddEncodingOption('MacArabic', 'macarabic', 10004, False, '苹果阿拉伯语编码'); // Mac系统阿拉伯语编码
  AddEncodingOption('MacHebrew', 'machebrew', 10005, False, '苹果希伯来语编码'); // Mac系统希伯来语编码
  AddEncodingOption('ARMSCII-8', 'armscii8', 901, False, '亚美尼亚语编码'); // 亚美尼亚语标准编码
  AddEncodingOption('GEOSTD8', 'geostd8', 902, False, '格鲁吉亚语编码'); // 格鲁吉亚语标准编码

  // ======================================================================
  // 南亚和东南亚编码组 - 印度次大陆和东南亚国家编码
  // ======================================================================
  AddEncodingGroup('南亚和东南亚编码');
  AddEncodingOption('ISCII-Devanagari', 'isciidev', 57002, False, '印度天城文编码'); // 印地语、梵语等使用的编码
  AddEncodingOption('ISCII-Bengali', 'isciibeng', 57003, False, '孟加拉语编码'); // 孟加拉语编码
  AddEncodingOption('ISCII-Tamil', 'isciitam', 57004, False, '泰米尔语编码'); // 泰米尔语编码
  AddEncodingOption('ISCII-Telugu', 'isciitel', 57005, False, '泰卢固语编码'); // 泰卢固语编码
  AddEncodingOption('ISCII-Assamese', 'isciiasm', 57006, False, '阿萨姆语编码'); // 阿萨姆语编码
  AddEncodingOption('ISCII-Oriya', 'isciiorya', 57007, False, '奥里亚语编码'); // 奥里亚语编码
  AddEncodingOption('ISCII-Kannada', 'isciiknd', 57008, False, '卡纳达语编码'); // 卡纳达语编码
  AddEncodingOption('ISCII-Malayalam', 'isciimlm', 57009, False, '马拉雅拉姆语编码'); // 马拉雅拉姆语编码
  AddEncodingOption('ISCII-Gujarati', 'isciiguj', 57010, False, '古吉拉特语编码'); // 古吉拉特语编码
  AddEncodingOption('ISCII-Punjabi', 'isciipjb', 57011, False, '旁遮普语编码'); // 旁遮普语编码
  AddEncodingOption('TSCII', 'tscii', 57012, False, '泰米尔语TSCII编码'); // 泰米尔语扩展编码
  AddEncodingOption('TIS-620', 'tis620', 874, False, '泰语编码'); // 泰语标准编码
  AddEncodingOption('Windows-874', 'cp874', 874, False, '泰语Windows编码'); // Windows泰语编码
  AddEncodingOption('VISCII', 'viscii', 1129, False, '越南语编码'); // 越南语标准编码
  AddEncodingOption('Windows-1258', 'cp1258', 1258, False, '越南语Windows编码'); // Windows越南语编码

  // ======================================================================
  // 非洲编码组 - 非洲大陆主要语言编码
  // ======================================================================
  AddEncodingGroup('非洲编码');
  AddEncodingOption('Swahili', 'swahili', 30001, False, '斯瓦希里语编码(东非通用语)'); // 东非主要通用语言
  AddEncodingOption('Hausa', 'hausa', 30002, False, '豪萨语编码(西非尼日利亚、尼日尔等地区)'); // 尼日利亚等西非国家使用
  AddEncodingOption('Yoruba', 'yoruba', 30003, False, '约鲁巴语编码(西非尼日利亚、贝宁等地区)'); // 尼日利亚等地区使用
  AddEncodingOption('Zulu', 'zulu', 30004, False, '祖鲁语编码(南部非洲)'); // 南非官方语言之一
  AddEncodingOption('Amharic', 'amharic', 30005, False, '阿姆哈拉语编码(埃塞俄比亚官方语言)'); // 埃塞俄比亚官方语言
  AddEncodingOption('Tigrinya', 'tigrinya', 30006, False, '提格雷尼亚语编码(厄立特里亚、埃塞俄比亚)'); // 厄立特里亚官方语言
  AddEncodingOption('Oromo', 'oromo', 30007, False, '奥罗莫语编码(埃塞俄比亚、肯尼亚)'); // 埃塞俄比亚主要语言
  AddEncodingOption('Somali', 'somali', 30008, False, '索马里语编码'); // 索马里官方语言
  AddEncodingOption('Berber', 'berber', 30009, False, '柏柏尔语编码(北非原住民语言)'); // 北非摩洛哥、阿尔及利亚等地区使用
  AddEncodingOption('Malagasy', 'malagasy', 30010, False, '马达加斯加语编码'); // 马达加斯加官方语言

  // ======================================================================
  // 其他编码组 - 不属于特定地区的通用编码和特殊编码
  // ======================================================================
  AddEncodingGroup('其他编码');
  AddEncodingOption('ASCII', 'ascii', 20127, False, '基本ASCII编码'); // 基础7位ASCII编码，仅支持英文和符号
  AddEncodingOption('EBCDIC-US', 'ebcdicus', 37, False, 'IBM大型机美国编码'); // IBM大型机使用的美国编码
  AddEncodingOption('EBCDIC-International', 'ebcdicint', 500, False, 'IBM大型机国际编码'); // IBM大型机使用的国际编码
  AddEncodingOption('EBCDIC-Latin-9', 'ebcdiclat9', 1140, False, 'IBM大型机拉丁9编码'); // IBM大型机使用的拉丁9编码
end;

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