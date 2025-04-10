unit HelperLanguage;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles, System.Generics.Collections,
  System.IOUtils, Winapi.Windows, Vcl.Forms, UtilsTypes, ModelLanguage;

type
  // 语言管理器类
  TLanguageManager = class
  private
    FCurrentLanguage: string;
    FLanguages: TDictionary<string, TLanguageStrings>;
    FLanguageInfoList: TList<TLanguageInfo>;
    FOnLanguageChange: TOnLanguageChangeEvent;
    FLanguagePath: string;
    FGetLanguageStringsCallback: TGetLanguageStringsCallback;
    
    function LoadFromFile(const FileName: string): TLanguageStrings;
    procedure SaveUserPreference(const LangCode: string);
    function GetDefaultLanguage: string;
    procedure ExportLanguageToFile(const LangCode: string; 
      const LangStrings: TLanguageStrings; const CustomPath: string);
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Initialize;
    procedure LoadAvailableLanguages;
    function GetLanguageList: TArray<TLanguageInfo>;
    function GetLanguageStrings(const LangCode: string): TLanguageStrings;
    procedure SetLanguage(const LangCode: string);
    function GetSystemLanguage: string;
    function GetLanguageNameByCode(const LangCode: string): string;
    function GetLanguageInfo(const LangCode: string): TLanguageInfo;
    procedure ExportCurrentLanguage(const FilePath: string);
    function ImportLanguage(const FilePath: string): Boolean;
    
    property CurrentLanguage: string read FCurrentLanguage;
    property OnLanguageChange: TOnLanguageChangeEvent read FOnLanguageChange write FOnLanguageChange;
    property LanguagePath: string read FLanguagePath write FLanguagePath;
    property GetLanguageStringsCallback: TGetLanguageStringsCallback 
             read FGetLanguageStringsCallback write FGetLanguageStringsCallback;
  end;
  
var
  LanguageManager: TLanguageManager;
  
implementation

uses
  System.StrUtils, System.UITypes;

const
  // 内置语言与代码映射
  BUILTIN_LANGUAGES: array[0..15, 0..1] of string = (
    ('zh-CN', '简体中文'),
    ('en-US', 'English'),
    ('ja-JP', '日本語'),
    ('ko-KR', '한국어'),
    ('es-ES', 'Español'),
    ('fr-FR', 'Français'),
    ('de-DE', 'Deutsch'),
    ('it-IT', 'Italiano'),
    ('zh-TW', '繁體中文'),
    ('ru-RU', 'Русский'),
    ('pt-BR', 'Português'),
    ('ar-SA', 'العربية'),
    ('nl-NL', 'Nederlands'),
    ('th-TH', 'ไทย'),
    ('vi-VN', 'Tiếng Việt'),
    ('pl-PL', 'Polski')
  );

// 创建默认的语言字符串
function CreateDefaultLanguageStrings: TLanguageStrings;
var
  LangStrings: TLanguageStrings;
begin
  // 初始化为英语界面
  LangStrings.WindowTitle := 'UTF-8 BOM Encoding Converter';
  LangStrings.BtnConvert := 'Convert All';
  LangStrings.BtnSingleFile := 'Single File';
  LangStrings.BtnRefresh := 'Refresh';
  LangStrings.BtnClose := 'Close';
  LangStrings.BtnToggleSelect := 'Select/Deselect All';
  LangStrings.LanguageGroupCaption := 'Language';
  LangStrings.DirectoryListBoxLabel := 'Directory';
  LangStrings.FileListLabel := 'File List';
  LangStrings.CurrentEncodingLabel := 'Current Encoding';
  LangStrings.FileSelectColumn := 'Select';
  LangStrings.FileNameColumn := 'Filename';
  LangStrings.EncodingColumn := 'Current Encoding';
  LangStrings.PopupMenuConvert := 'Convert Selected Files';
  LangStrings.PopupMenuToggleSelect := 'Select/Deselect All';
  LangStrings.NoFilesText := '(No Files)';
  LangStrings.ReadErrorText := '(Read Error)';
  LangStrings.LogSelectedDirectory := 'Selected Directory: ';
  
  Result := LangStrings;
end;

{ TLanguageManager }

constructor TLanguageManager.Create;
begin
  inherited Create;
  FLanguages := TDictionary<string, TLanguageStrings>.Create;
  FLanguageInfoList := TList<TLanguageInfo>.Create;
  FCurrentLanguage := '';
  FLanguagePath := ExtractFilePath(Application.ExeName) + 'languages';
  FGetLanguageStringsCallback := nil;
end;

destructor TLanguageManager.Destroy;
begin
  FLanguages.Free;
  FLanguageInfoList.Free;
  inherited Destroy;
end;

procedure TLanguageManager.Initialize;
begin
  // 完全简化初始化流程，直接使用内置语言
  FLanguageInfoList.Clear;
  FLanguages.Clear;
  
  // 只添加简体中文语言
  var LangInfo: TLanguageInfo;
  LangInfo.Code := 'zh-CN';
  LangInfo.Name := '简体中文';
  LangInfo.NativeName := '简体中文';
  LangInfo.FileName := '';
  
  // 添加到语言信息列表
  FLanguageInfoList.Add(LangInfo);
  
  // 创建默认语言字符串
  var DefaultStrings := CreateDefaultLanguageStrings;
  
  // 中文界面字符串
  DefaultStrings.WindowTitle := 'UTF-8 BOM 编码转换工具';
  DefaultStrings.BtnConvert := '批量转换';
  DefaultStrings.BtnSingleFile := '单个文件';
  DefaultStrings.BtnRefresh := '刷新';
  DefaultStrings.BtnClose := '关闭';
  DefaultStrings.BtnToggleSelect := '全选/取消全选';
  DefaultStrings.LanguageGroupCaption := '语言';
  DefaultStrings.DirectoryListBoxLabel := '目录';
  DefaultStrings.FileListLabel := '文件列表';
  DefaultStrings.CurrentEncodingLabel := '当前编码';
  DefaultStrings.FileSelectColumn := '选择';
  DefaultStrings.FileNameColumn := '文件名';
  DefaultStrings.EncodingColumn := '当前编码';
  DefaultStrings.PopupMenuConvert := '转换选中文件';
  DefaultStrings.PopupMenuToggleSelect := '全选/取消全选';
  DefaultStrings.NoFilesText := '(无文件)';
  DefaultStrings.ReadErrorText := '(读取错误)';
  DefaultStrings.LogSelectedDirectory := '选择的目录: ';
  
  // 添加到语言字典
  FLanguages.Add(LangInfo.Code, DefaultStrings);
  
  // 设置当前语言为简体中文
  FCurrentLanguage := 'zh-CN';
end;

function TLanguageManager.GetDefaultLanguage: string;
var
  SysLang: string;
begin
  // 尝试获取系统语言
  SysLang := GetSystemLanguage;
  
  // 如果系统语言在支持列表中，使用它
  if FLanguages.ContainsKey(SysLang) then
    Result := SysLang
  // 否则使用英语作为默认语言
  else if FLanguages.ContainsKey('en-US') then
    Result := 'en-US'
  // 如果英语也不存在，使用第一个可用语言
  else if FLanguageInfoList.Count > 0 then
    Result := FLanguageInfoList[0].Code
  // 最后的后备选项：简体中文
  else
    Result := 'zh-CN';
end;

procedure TLanguageManager.LoadAvailableLanguages;
begin
  // 这个方法不再需要，由Initialize直接处理
end;

function TLanguageManager.LoadFromFile(const FileName: string): TLanguageStrings;
var
  IniFile: TMemIniFile;
  LangStrings: TLanguageStrings;
begin
  IniFile := TMemIniFile.Create(FileName, TEncoding.UTF8);
  try
    // 从INI文件读取所有界面字符串
    LangStrings.WindowTitle := IniFile.ReadString('Strings', 'WindowTitle', '');
    LangStrings.BtnConvert := IniFile.ReadString('Strings', 'BtnConvert', '');
    LangStrings.BtnSingleFile := IniFile.ReadString('Strings', 'BtnSingleFile', '');
    LangStrings.BtnRefresh := IniFile.ReadString('Strings', 'BtnRefresh', '');
    LangStrings.BtnClose := IniFile.ReadString('Strings', 'BtnClose', '');
    LangStrings.BtnToggleSelect := IniFile.ReadString('Strings', 'BtnToggleSelect', '');
    LangStrings.LanguageGroupCaption := IniFile.ReadString('Strings', 'LanguageGroupCaption', '');
    LangStrings.DirectoryListBoxLabel := IniFile.ReadString('Strings', 'DirectoryListBoxLabel', '');
    LangStrings.FileListLabel := IniFile.ReadString('Strings', 'FileListLabel', '');
    LangStrings.CurrentEncodingLabel := IniFile.ReadString('Strings', 'CurrentEncodingLabel', '');
    LangStrings.FileSelectColumn := IniFile.ReadString('Strings', 'FileSelectColumn', '');
    LangStrings.FileNameColumn := IniFile.ReadString('Strings', 'FileNameColumn', '');
    LangStrings.EncodingColumn := IniFile.ReadString('Strings', 'EncodingColumn', '');
    LangStrings.PopupMenuConvert := IniFile.ReadString('Strings', 'PopupMenuConvert', '');
    LangStrings.PopupMenuToggleSelect := IniFile.ReadString('Strings', 'PopupMenuToggleSelect', '');
    LangStrings.NoFilesText := IniFile.ReadString('Strings', 'NoFilesText', '');
    LangStrings.ReadErrorText := IniFile.ReadString('Strings', 'ReadErrorText', '');
    LangStrings.LogSelectedDirectory := IniFile.ReadString('Strings', 'LogSelectedDirectory', '');
  finally
    IniFile.Free;
  end;
  
  Result := LangStrings;
end;

procedure TLanguageManager.ExportCurrentLanguage(const FilePath: string);
begin
  // 不再执行任何文件操作
end;

procedure TLanguageManager.ExportLanguageToFile(const LangCode: string; 
  const LangStrings: TLanguageStrings; const CustomPath: string);
begin
  // 不再执行任何文件操作
end;

function TLanguageManager.ImportLanguage(const FilePath: string): Boolean;
begin
  // 不再执行任何文件操作，直接返回false
  Result := False;
end;

function TLanguageManager.GetLanguageList: TArray<TLanguageInfo>;
var
  LResult: TArray<TLanguageInfo>;
  i: Integer;
begin
  SetLength(LResult, FLanguageInfoList.Count);
  for i := 0 to FLanguageInfoList.Count - 1 do
    LResult[i] := FLanguageInfoList[i];
  Result := LResult;
end;

function TLanguageManager.GetLanguageNameByCode(const LangCode: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to FLanguageInfoList.Count - 1 do
  begin
    if FLanguageInfoList[i].Code = LangCode then
    begin
      Result := FLanguageInfoList[i].Name;
      Exit;
    end;
  end;
end;

function TLanguageManager.GetLanguageInfo(const LangCode: string): TLanguageInfo;
var
  i: Integer;
  EmptyInfo: TLanguageInfo;
begin
  for i := 0 to FLanguageInfoList.Count - 1 do
  begin
    if FLanguageInfoList[i].Code = LangCode then
    begin
      Result := FLanguageInfoList[i];
      Exit;
    end;
  end;
  
  // 返回空信息
  EmptyInfo.Code := '';
  EmptyInfo.Name := '';
  EmptyInfo.FileName := '';
  EmptyInfo.NativeName := '';
  Result := EmptyInfo;
end;

function TLanguageManager.GetLanguageStrings(const LangCode: string): TLanguageStrings;
var
  Enumerator: TDictionary<string, TLanguageStrings>.TPairEnumerator;
begin
  if FLanguages.ContainsKey(LangCode) then
    Result := FLanguages[LangCode]
  else
    // 返回英语作为后备语言
    if FLanguages.ContainsKey('en-US') then
      Result := FLanguages['en-US']
    // 如果连英语都没有，返回第一个可用语言
    else if FLanguages.Count > 0 then
    begin
      Enumerator := FLanguages.GetEnumerator;
      try
        if Enumerator.MoveNext then
          Result := Enumerator.Current.Value
        else
          Result := CreateDefaultLanguageStrings;
      finally
        Enumerator.Free;
      end;
    end
    // 最后的防御：返回默认字符串
    else
      Result := CreateDefaultLanguageStrings;
end;

procedure TLanguageManager.SetLanguage(const LangCode: string);
var
  LangStrings: TLanguageStrings;
begin
  // 如果没有变化，直接返回
  if FCurrentLanguage = LangCode then
    Exit;
    
  // 检查是否支持该语言
  if not FLanguages.ContainsKey(LangCode) then
    Exit;
    
  // 确保能获取到语言字符串
  LangStrings := GetLanguageStrings(LangCode);
  
  // 设置当前语言
  FCurrentLanguage := LangCode;
  
  // 保存用户偏好
  SaveUserPreference(LangCode);
  
  // 立即触发语言变更事件，确保UI更新
  if Assigned(FOnLanguageChange) then
  begin
    try
      // 传递语言代码到事件处理器
      FOnLanguageChange(LangCode);
      
      // 记录语言切换成功
      OutputDebugString(PChar('语言已切换到: ' + LangCode));
    except
      on E: Exception do
      begin
        // 记录异常但不中断流程
        OutputDebugString(PChar('语言切换异常: ' + E.Message));
      end;
    end;
  end
  else
  begin
    // 记录没有事件处理器的情况
    OutputDebugString(PChar('警告：未设置OnLanguageChange事件处理器'));
  end;
end;

procedure TLanguageManager.SaveUserPreference(const LangCode: string);
begin
  // 不再保存到ini文件，此方法保留但不执行任何操作
end;

function TLanguageManager.GetSystemLanguage: string;
begin
  // 默认为英语
  Result := 'en-US';
  
  // 基于Windows语言ID设置语言代码
  case GetUserDefaultLCID of
    $0804: Result := 'zh-CN'; // 简体中文
    $0404, $0C04, $1004, $1404: Result := 'zh-TW'; // 繁体中文
    $0409, $0809, $0C09, $1009, $1409, $1809, $1C09, $2009, $2409, $2809, $2C09, $3009, $3409: Result := 'en-US'; // 英语
    $0411: Result := 'ja-JP'; // 日语
    $0412: Result := 'ko-KR'; // 韩语
    $040A, $080A, $0C0A, $100A, $140A, $180A, $1C0A, $200A, $240A, $280A, $2C0A, $300A, $340A, $380A, $3C0A, $400A, $440A, $480A, $4C0A, $500A: Result := 'es-ES'; // 西班牙语
    $040C, $080C, $0C0C, $100C, $140C, $180C: Result := 'fr-FR'; // 法语
    $0407, $0807, $0C07, $1007, $1407: Result := 'de-DE'; // 德语
    $0410, $0810: Result := 'it-IT'; // 意大利语
    $0419: Result := 'ru-RU'; // 俄语
    $0416, $0816: Result := 'pt-BR'; // 葡萄牙语
    $0401, $0801, $0C01, $1001, $1401, $1801, $1C01, $2001, $2401, $2801, $2C01, $3001, $3401, $3801, $3C01, $4001: Result := 'ar-SA'; // 阿拉伯语
    $0413, $0813: Result := 'nl-NL'; // 荷兰语
    $041E: Result := 'th-TH'; // 泰语
    $042A: Result := 'vi-VN'; // 越南语
    $0415: Result := 'pl-PL'; // 波兰语
  end;
end;

initialization
  LanguageManager := TLanguageManager.Create;
  
finalization
  if Assigned(LanguageManager) then
    LanguageManager.Free;
  
end. 