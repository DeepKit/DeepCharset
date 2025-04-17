unit UtilsTypes;

interface

uses
  System.SysUtils, System.Classes;

type
  // 编码分类枚举
  TEncodingCategory = (
    ecUnicode,       // Unicode编码 (UTF-8, UTF-16等)
    ecEuropean,      // 欧洲编码 (ISO-8859, Windows-125x等)
    ecCyrillic,      // 西里尔编码 (KOI8, Windows-1251等)
    ecMiddleEast,    // 中东编码 (阿拉伯文, 希伯来文等)
    ecEastAsian,     // 东亚编码 (GB2312, Big5, Shift-JIS等)
    ecSouthAsian,    // 南亚编码 (印度语系等)
    ecSouthEastAsian,// 东南亚编码 (泰文, 越南文等)
    ecOther          // 其他编码
  );

  // 应用程序支持的语言枚举
  TAppLanguage = (
    alChinese,             // 简体中文
    alEnglish,             // 英语
    alJapanese,            // 日语
    alKorean,              // 韩语
    alSpanish,             // 西班牙语
    alFrench,              // 法语
    alGerman,              // 德语
    alItalian,             // 意大利语
    alChineseTraditional,  // 繁体中文
    alRussian,             // 俄语
    alPortuguese,          // 葡萄牙语
    alArabic,              // 阿拉伯语
    alDutch,               // 荷兰语
    alThai,                // 泰语
    alVietnamese,          // 越南语
    alPolish               // 波兰语
  );
  
  // 界面字符串结构体
  TLanguageStrings = record
    WindowTitle: string;           // 窗口标题
    BtnConvert: string;            // 转换所有按钮
    BtnSingleFile: string;         // 单个文件按钮
    BtnRefresh: string;            // 刷新按钮
    BtnClose: string;              // 关闭按钮
    BtnToggleSelect: string;       // 全选/取消全选按钮
    LanguageGroupCaption: string;  // 语言组标题
    DirectoryListBoxLabel: string; // 目录列表标签
    FileListLabel: string;         // 文件列表标签
    CurrentEncodingLabel: string;  // 当前编码标签
    FileSelectColumn: string;      // 文件选择列
    FileNameColumn: string;        // 文件名列
    EncodingColumn: string;        // 编码列
    PopupMenuConvert: string;      // 弹出菜单转换
    PopupMenuToggleSelect: string; // 弹出菜单全选/取消全选
    NoFilesText: string;           // 无文件文本
    ReadErrorText: string;         // 读取错误文本
    LogSelectedDirectory: string;  // 日志选择目录
  end;

  // 语言信息记录
  TLanguageInfo = record
    Code: string;        // 语言代码 (zh-CN, zh-TW, en-US等)
    Name: string;        // 显示名称 (简体中文, 繁體中文, English等)
    FileName: string;    // 资源文件名
    NativeName: string;  // 本地语言名称
  end;
  
  // 语言映射记录
  TLanguageMapping = record
    AppLanguage: TAppLanguage;
    LanguageCode: string;
    DisplayName: string;
  end;

  // 语言变更事件
  TOnLanguageChangeEvent = procedure(const LangCode: string) of object;
  
  // 语言字符串获取回调函数
  TGetLanguageStringsCallback = function(Language: TAppLanguage): TLanguageStrings of object;

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

end. 