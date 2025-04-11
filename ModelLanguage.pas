unit ModelLanguage;

interface

type
  // 语言信息结构
  TLanguageInfo = record
    Code: string;       // 语言代码，如 'zh-CN', 'en'
    Name: string;       // 语言名称，如 'Chinese (Simplified)', 'English'
    NativeName: string; // 本地化名称，如 '简体中文', 'English'
    FileName: string;   // 语言文件名，如 'zh-CN.json'
  end;

  // 语言字符串结构
  TLanguageStrings = record
    // 窗口标题
    WindowTitle: string;

    // 按钮文本
    BtnConvert: string;
    BtnSingleFile: string;
    BtnRefresh: string;
    BtnClose: string;
    BtnToggleSelect: string;
    BtnSVG2ICON: string;
    BtnPreview: string;

    // 标签文本
    LanguageGroupCaption: string;
    DirectoryListBoxLabel: string;
    FileListLabel: string;
    CurrentEncodingLabel: string;

    // 列表列标题
    FileSelectColumn: string;
    FileNameColumn: string;
    EncodingColumn: string;

    // 菜单项
    PopupMenuConvert: string;
    PopupMenuToggleSelect: string;

    // 消息文本
    NoFilesText: string;
    ReadErrorText: string;
    LogSelectedDirectory: string;
  end;

  // 语言变更事件
  TOnLanguageChangeEvent = reference to procedure(const LangCode: string);

  // 获取语言字符串回调
  TGetLanguageStringsCallback = reference to function(const LangCode: string): TLanguageStrings;

// 应用程序支持的语言枚举
type
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

implementation

end.