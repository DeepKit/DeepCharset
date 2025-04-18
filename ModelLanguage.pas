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
    alPolish                // 波兰语
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
    BtnSVGConverter: string;
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

    // 编码描述
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
  Result.BtnSVGConverter := 'SVG Image Converter';
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

  // 编码描述
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
end;

end.