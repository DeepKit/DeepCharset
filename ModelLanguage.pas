unit ModelLanguage;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  // 应用程序支持的语言枚举
  TAppLanguage = (
    alChinese,              // 简体中文
    alEnglish,              // 英语
    alJapanese,             // 日语
    alKorean,               // 韩语
    alSpanish,              // 西班牙语
    alFrench,               // 法语
    alGerman,               // 德语
    alItalian,              // 意大利语
    alChineseTraditional,   // 繁体中文
    alRussian,              // 俄语
    alPortuguese,           // 葡萄牙语
    alArabic,               // 阿拉伯语
    alDutch,                // 荷兰语
    alThai,                 // 泰语
    alVietnamese,           // 越南语
    alPolish,               // 波兰语
    alSwahili,              // 斯瓦希里语
    alAmharic               // 阿姆哈拉语
  );

  // 语言信息记录
  TLanguageInfo = record
    Code: string;           // 语言代码 (如 'zh-CN', 'en-US')
    Name: string;           // 语言名称 (如 'Chinese', 'English')
    NativeName: string;     // 本地语言名称 (如 '简体中文', 'English')
    FileName: string;       // 语言文件名
  end;

  // 语言映射记录
  TLanguageMapping = record
    AppLanguage: TAppLanguage;
    LanguageCode: string;
    DisplayName: string;
  end;

  // 语言字符串记录 - 包含所有UI文本
  TLanguageStrings = record
    // 窗口标题
    WindowTitle: string;

    // 按钮文本
    BtnConvert: string;
    BtnSingleFile: string;
    BtnRefresh: string;
    BtnClose: string;
    BtnToggleSelect: string;
    BtnPreview: string;
    BtnAllFileTypes: string;
    BtnCheckContent: string;

    // 标签文本
    LanguageGroupCaption: string;
    DirectoryListBoxLabel: string;
    FileListLabel: string;
    CurrentEncodingLabel: string;

    // 表格列标题
    FileSelectColumn: string;
    FileNameColumn: string;
    EncodingColumn: string;

    // 菜单项
    PopupMenuConvert: string;
    PopupMenuToggleSelect: string;

    // 状态和提示文本
    NoFilesText: string;
    ReadErrorText: string;
    LogSelectedDirectory: string;

    // 复选框
    ChkIncludeSubdirs: string;

    // 弹窗消息
    MsgSelectTargetEncoding: string;
    MsgSelectFiles: string;
    MsgNoMatchingFiles: string;
    MsgConversionComplete: string;
    MsgConversionFailed: string;
    MsgFileNotExists: string;
    MsgNotTextFile: string;
    MsgSingleFileSuccess: string;
    MsgSingleFileFailed: string;
    MsgSelectFile: string;
    MsgCannotCreateViewer: string;
    MsgCannotLoadFile: string;
    MsgViewerError: string;
    MsgSubdirEnabled: string;
    MsgConversionSuccess: string;

    // 进度提示文本
    ProgressSearchingFiles: string;
    ProgressDetectingEncoding: string;
    ProgressDetecting: string;
    ProgressComplete: string;
    ProgressCompleteFiles: string;

    // 日志消息
    LogDetectionComplete: string;
    LogFilesFound: string;
    LogDeselectAllFileTypes: string;
    LogSelectAllFileTypes: string;
    LogForceUpdateFileList: string;
    LogAsyncScanComplete: string;

    // UI动态文本
    BtnSelectAllFileTypes: string;
    BtnDeselectAllFileTypes: string;
    WindowTitleDefault: string;
    WindowTitleScanProgress: string;
    WindowTitleConvertProgress: string;
    SingleFileConvertSuffix: string;

    // 编码分类标题
    EncCategoryUnicode: string;
    EncCategoryAsian: string;
    EncCategoryEuropean: string;
    EncCategoryOther: string;
    EncCategoryLatinAmerican: string;  // 新增：拉丁美洲编码分类
    EncCategoryAfrican: string;        // 新增：非洲编码分类

    // Unicode编码描述
    EncUTF8Desc: string;
    EncUTF8BOMDesc: string;
    EncUTF16LEDesc: string;
    EncUTF16BEDesc: string;
    EncUTF16Desc: string;
    EncUTF32LEDesc: string;
    EncUTF32BEDesc: string;
    EncUTF32Desc: string;
    EncUTF7Desc: string;
    EncUCS2Desc: string;
    EncUCS4LEDesc: string;
    EncUCS4BEDesc: string;
    
    // 亚洲编码描述
    EncGB2312Desc: string;
    EncGBKDesc: string;
    EncGB18030Desc: string;
    EncBig5Desc: string;
    EncBig5HKSCSDesc: string;
    EncShiftJISDesc: string;
    EncEUCJPDesc: string;
    EncISO2022JPDesc: string;
    EncISO2022JP2Desc: string;
    EncEUCKRDesc: string;
    
    // 欧洲编码描述
    EncISO8859_1Desc: string;
    EncISO8859_2Desc: string;
    EncISO8859_3Desc: string;
    EncISO8859_5Desc: string;
    EncISO8859_7Desc: string;
    EncISO8859_9Desc: string;
    EncWindows1250Desc: string;
    EncWindows1251Desc: string;
    EncWindows1252Desc: string;
    EncWindows1253Desc: string;
    EncWindows1254Desc: string;
    EncWindows1257Desc: string;
    EncIBM850Desc: string;
    EncDOSLatinUSDesc: string;
    
    // 拉丁美洲编码描述
    EncQuechuaDesc: string;         // 新增：克丘亚语编码
    EncAymaraDesc: string;          // 新增：艾马拉语编码
    EncGuaraniDesc: string;         // 新增：瓜拉尼语编码
    EncMayaDesc: string;            // 新增：玛雅语编码
    EncNahuatlDesc: string;         // 新增：纳瓦特尔语编码
    
    // 非洲编码描述
    EncSwahiliDesc: string;         // 新增：斯瓦希里语编码
    EncHausaDesc: string;           // 新增：豪萨语编码
    EncYorubaDesc: string;          // 新增：约鲁巴语编码
    EncZuluDesc: string;            // 新增：祖鲁语编码
    EncAmharicDesc: string;         // 新增：阿姆哈拉语编码
    EncTigrinyaDesc: string;        // 新增：提格雷尼亚语编码
    EncOromoDesc: string;           // 新增：奥罗莫语编码
    EncSomaliDesc: string;          // 新增：索马里语编码
    EncBerberDesc: string;          // 新增：柏柏尔语编码
    EncMalagasyDesc: string;        // 新增：马达加斯加语编码
  end;

  // 语言变更事件类型
  TOnLanguageChangeEvent = procedure(const LangCode: string) of object;

  // 获取语言字符串回调函数类型
  TGetLanguageStringsCallback = function(const LangCode: string): TLanguageStrings of object;

// 创建默认的语言字符串
function CreateDefaultLanguageStrings: TLanguageStrings;

implementation

// 创建默认的语言字符串
function CreateDefaultLanguageStrings: TLanguageStrings;
begin
  // 初始化为英语界面
  Result.WindowTitle := 'UTF-8 BOM Encoding Converter';
  Result.BtnConvert := 'Convert All';
  Result.BtnSingleFile := 'Single File';
  Result.BtnRefresh := 'Refresh';
  Result.BtnClose := 'Close';
  Result.BtnToggleSelect := 'Select/Deselect All';
  Result.BtnPreview := 'Preview';
  Result.BtnAllFileTypes := 'Select All File Types';
  Result.BtnCheckContent := 'Check Content';
  Result.LanguageGroupCaption := 'Language';
  Result.DirectoryListBoxLabel := 'Directory';
  Result.FileListLabel := 'File List';
  Result.CurrentEncodingLabel := 'Current Encoding';
  Result.FileSelectColumn := 'Select';
  Result.FileNameColumn := 'Filename';
  Result.EncodingColumn := 'Current Encoding';
  Result.PopupMenuConvert := 'Convert Selected Files';
  Result.PopupMenuToggleSelect := 'Select/Deselect All';
  Result.NoFilesText := '(No Files)';
  Result.ReadErrorText := '(Read Error)';
  Result.LogSelectedDirectory := 'Selected Directory: ';
  Result.ChkIncludeSubdirs := 'Include Subdirectories';

  // 弹窗消息
  Result.MsgSelectTargetEncoding := 'Please select a target encoding.';
  Result.MsgSelectFiles := 'Please select at least one file for conversion.';
  Result.MsgNoMatchingFiles := 'No matching files found in the current directory.';
  Result.MsgConversionComplete := 'Conversion completed: %d/%d files successful';
  Result.MsgConversionFailed := 'Conversion failed: No files were successfully converted. Please check the log for details.';
  Result.MsgFileNotExists := 'File does not exist: %s';
  Result.MsgNotTextFile := 'File %s is not a normal text file. It may be a binary file or other unsupported format.';
  Result.MsgSingleFileSuccess := 'File %s has been successfully converted to %s';
  Result.MsgSingleFileFailed := 'File %s conversion failed. Please check the log for details.';
  Result.MsgSelectFile := 'Please select a file first';
  Result.MsgCannotCreateViewer := 'Cannot create file viewer: %s';
  Result.MsgCannotLoadFile := 'Cannot load file: %s';
  Result.MsgViewerError := 'Error viewing file: %s';
  Result.MsgSubdirEnabled := 'Subdirectory search enabled. This may increase file list loading time, especially for folders with many subdirectories.';
  Result.MsgConversionSuccess := 'Conversion successful!';

  // 进度提示文本
  Result.ProgressSearchingFiles := 'Searching files...';
  Result.ProgressDetectingEncoding := 'Detecting encoding: 0/%d';
  Result.ProgressDetecting := 'Detecting: %d/%d (%.0f%%)';
  Result.ProgressComplete := 'Complete: %d files';
  Result.ProgressCompleteFiles := 'Complete: %d files';

  // 日志消息
  Result.LogDetectionComplete := 'Detection complete: %d files';
  Result.LogFilesFound := 'Found %d files, starting encoding detection...';

  // 编码分类标题
  Result.EncCategoryUnicode := 'Unicode';
  Result.EncCategoryAsian := 'Asian';
  Result.EncCategoryEuropean := 'European';
  Result.EncCategoryOther := 'Other';
  Result.EncCategoryLatinAmerican := 'Latin American';  // 新增：拉丁美洲编码分类
  Result.EncCategoryAfrican := 'African';              // 新增：非洲编码分类

  // Unicode编码描述
  Result.EncUTF8Desc := 'Universal Unicode encoding, compatible with ASCII';
  Result.EncUTF8BOMDesc := 'UTF-8 with Byte Order Mark';
  Result.EncUTF16LEDesc := 'Unicode encoding with little-endian byte order';
  Result.EncUTF16BEDesc := 'Unicode encoding with big-endian byte order';
  Result.EncUTF16Desc := '16-bit Unicode encoding';
  Result.EncUTF32LEDesc := '32-bit Unicode encoding with little-endian byte order';
  Result.EncUTF32BEDesc := '32-bit Unicode encoding with big-endian byte order';
  Result.EncUTF32Desc := '32-bit Unicode encoding';
  Result.EncUTF7Desc := '7-bit Unicode encoding (obsolete)';
  Result.EncUCS2Desc := 'Early 16-bit Unicode encoding';
  Result.EncUCS4LEDesc := '32-bit Unicode encoding with little-endian byte order';
  Result.EncUCS4BEDesc := '32-bit Unicode encoding with big-endian byte order';
  
  // 亚洲编码描述
  Result.EncGB2312Desc := 'Chinese character encoding for mainland China';
  Result.EncGBKDesc := 'Extended Chinese character encoding';
  Result.EncGB18030Desc := 'Chinese national standard encoding, compatible with GBK';
  Result.EncBig5Desc := 'Traditional Chinese character encoding for Taiwan and Hong Kong';
  Result.EncBig5HKSCSDesc := 'Big5 encoding with Hong Kong Supplementary Character Set';
  Result.EncShiftJISDesc := 'Japanese character encoding, default in Windows Japanese version';
  Result.EncEUCJPDesc := 'Extended Unix Code for Japanese';
  Result.EncISO2022JPDesc := 'Japanese encoding for email and news groups';
  Result.EncISO2022JP2Desc := 'Extended version of Japanese character encoding';
  Result.EncEUCKRDesc := 'Korean character encoding';
  
  // 欧洲编码描述
  Result.EncISO8859_1Desc := 'ISO-8859-1 Latin Alphabet No. 1';
  Result.EncISO8859_2Desc := 'ISO-8859-2 Central European';
  Result.EncISO8859_3Desc := 'ISO-8859-3 Latin Alphabet No. 3';
  Result.EncISO8859_5Desc := 'ISO-8859-5 Latin/Cyrillic';
  Result.EncISO8859_7Desc := 'ISO-8859-7 Greek';
  Result.EncISO8859_9Desc := 'ISO-8859-9 Latin Alphabet No. 9';
  Result.EncWindows1250Desc := 'Windows Code Page 1250';
  Result.EncWindows1251Desc := 'Windows Code Page 1251';
  Result.EncWindows1252Desc := 'Windows Code Page 1252';
  Result.EncWindows1253Desc := 'Windows Code Page 1253';
  Result.EncWindows1254Desc := 'Windows Code Page 1254';
  Result.EncWindows1257Desc := 'Windows Code Page 1257';
  Result.EncIBM850Desc := 'IBM Code Page 850';
  Result.EncDOSLatinUSDesc := 'DOS Latin US';
  
  // 拉丁美洲编码描述（新增）
  Result.EncQuechuaDesc := 'Quechua encoding for indigenous Andean languages';
  Result.EncAymaraDesc := 'Aymara encoding for Bolivia and Peru indigenous language';
  Result.EncGuaraniDesc := 'Guaraní encoding for Paraguay and Argentina indigenous language';
  Result.EncMayaDesc := 'Maya encoding for Central American indigenous languages';
  Result.EncNahuatlDesc := 'Nahuatl encoding for Aztec descendant language';
  
  // 非洲编码描述（新增）
  Result.EncSwahiliDesc := 'Swahili encoding for East African lingua franca';
  Result.EncHausaDesc := 'Hausa encoding for West African language (Nigeria, Niger)';
  Result.EncYorubaDesc := 'Yoruba encoding for West African language (Nigeria, Benin)';
  Result.EncZuluDesc := 'Zulu encoding for Southern African language';
  Result.EncAmharicDesc := 'Amharic encoding for Ethiopian official language';
  Result.EncTigrinyaDesc := 'Tigrinya encoding for Eritrea and Ethiopia';
  Result.EncOromoDesc := 'Oromo encoding for Ethiopia and Kenya';
  Result.EncSomaliDesc := 'Somali encoding for Horn of Africa';
  Result.EncBerberDesc := 'Berber encoding for North African indigenous languages';
  Result.EncMalagasyDesc := 'Malagasy encoding for Madagascar';
end;

end.