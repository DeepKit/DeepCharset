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
var
  ConfigPath: string;
  IniFile: TMemIniFile;
  LoadedLang: string;
begin
  // 确保语言目录存在
  if not DirectoryExists(FLanguagePath) then
    ForceDirectories(FLanguagePath);
    
  // 加载可用语言
  LoadAvailableLanguages;
  
  // 尝试从配置文件加载上次使用的语言
  ConfigPath := ChangeFileExt(Application.ExeName, '.ini');
  if FileExists(ConfigPath) then
  begin
    IniFile := TMemIniFile.Create(ConfigPath, TEncoding.UTF8);
    try
      LoadedLang := IniFile.ReadString('Settings', 'Language', '');
      if (LoadedLang <> '') and FLanguages.ContainsKey(LoadedLang) then
        FCurrentLanguage := LoadedLang
      else
        FCurrentLanguage := GetDefaultLanguage;
    finally
      IniFile.Free;
    end;
  end
  else
    FCurrentLanguage := GetDefaultLanguage;
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
var
  LangFiles: TArray<string>;
  LangInfo: TLanguageInfo;
  IniFile: TMemIniFile;
  i: Integer;
  BuiltInStrings: TLanguageStrings;
  LanguageEnum: TAppLanguage;
begin
  // 清空现有语言列表
  FLanguageInfoList.Clear;
  FLanguages.Clear;
  
  // 添加内置语言
  for i := 0 to High(BUILTIN_LANGUAGES) do
  begin
    LangInfo.Code := BUILTIN_LANGUAGES[i, 0];
    LangInfo.Name := BUILTIN_LANGUAGES[i, 1];
    LangInfo.NativeName := BUILTIN_LANGUAGES[i, 1];
    LangInfo.FileName := '';
    
    // 添加到语言信息列表
    FLanguageInfoList.Add(LangInfo);
    
    // 使用默认语言字符串
    BuiltInStrings := CreateDefaultLanguageStrings;
    
    // 如果回调函数存在且是内置的语言，尝试获取硬编码的语言字符串
    if Assigned(FGetLanguageStringsCallback) and (i < 16) then
    begin
      try
        // 直接使用索引值对应的枚举
        if i < Ord(High(TAppLanguage)) then
        begin
          LanguageEnum := TAppLanguage(i);
          BuiltInStrings := FGetLanguageStringsCallback(LanguageEnum);
        end;
      except
        // 忽略错误，使用默认字符串
      end;
    end;
    
    // 添加到语言字典
    if not FLanguages.ContainsKey(LangInfo.Code) then
      FLanguages.Add(LangInfo.Code, BuiltInStrings);
    
    // 导出内置语言到INI文件（如果文件不存在且路径已初始化）
    if DirectoryExists(FLanguagePath) and 
       not FileExists(FLanguagePath + PathDelim + LangInfo.Code + '.ini') then
      ExportLanguageToFile(LangInfo.Code, BuiltInStrings, '');
  end;
  
  // 加载外部语言文件
  if DirectoryExists(FLanguagePath) then
  begin
    LangFiles := TDirectory.GetFiles(FLanguagePath, '*.ini');
    for var FileName in LangFiles do
    begin
      IniFile := TMemIniFile.Create(FileName, TEncoding.UTF8);
      try
        LangInfo.Code := IniFile.ReadString('Meta', 'LanguageCode', '');
        LangInfo.Name := IniFile.ReadString('Meta', 'LanguageName', '');
        LangInfo.NativeName := IniFile.ReadString('Meta', 'NativeName', LangInfo.Name);
        LangInfo.FileName := FileName;
        
        // 如果是有效的语言文件
        if (LangInfo.Code <> '') and (LangInfo.Name <> '') then
        begin
          // 加载语言字符串
          var LangStrings := LoadFromFile(FileName);
          
          // 更新语言字典
          if FLanguages.ContainsKey(LangInfo.Code) then
            FLanguages[LangInfo.Code] := LangStrings
          else
            FLanguages.Add(LangInfo.Code, LangStrings);
            
          // 更新或添加语言信息
          var ExistingIndex := -1;
          for var j := 0 to FLanguageInfoList.Count - 1 do
          begin
            if FLanguageInfoList[j].Code = LangInfo.Code then
            begin
              ExistingIndex := j;
              Break;
            end;
          end;
          
          if ExistingIndex >= 0 then
            FLanguageInfoList[ExistingIndex] := LangInfo
          else
            FLanguageInfoList.Add(LangInfo);
        end;
      finally
        IniFile.Free;
      end;
    end;
  end;
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
  if FCurrentLanguage <> '' then
    ExportLanguageToFile(FCurrentLanguage, FLanguages[FCurrentLanguage], FilePath);
end;

procedure TLanguageManager.ExportLanguageToFile(const LangCode: string; 
  const LangStrings: TLanguageStrings; const CustomPath: string);
var
  IniFile: TMemIniFile;
  FilePath: string;
  LangInfo: TLanguageInfo;
begin
  // 确定文件路径
  if CustomPath <> '' then
    FilePath := CustomPath
  else
    FilePath := FLanguagePath + PathDelim + LangCode + '.ini';
    
  // 确保目录存在
  ForceDirectories(ExtractFilePath(FilePath));
  
  // 获取语言信息
  LangInfo := GetLanguageInfo(LangCode);
    
  IniFile := TMemIniFile.Create(FilePath, TEncoding.UTF8);
  try
    // 写入元数据
    IniFile.WriteString('Meta', 'LanguageCode', LangCode);
    IniFile.WriteString('Meta', 'LanguageName', LangInfo.Name);
    IniFile.WriteString('Meta', 'NativeName', LangInfo.NativeName);
    IniFile.WriteString('Meta', 'Version', '1.0');
    IniFile.WriteString('Meta', 'ExportDate', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    
    // 写入所有界面字符串
    IniFile.WriteString('Strings', 'WindowTitle', LangStrings.WindowTitle);
    IniFile.WriteString('Strings', 'BtnConvert', LangStrings.BtnConvert);
    IniFile.WriteString('Strings', 'BtnSingleFile', LangStrings.BtnSingleFile);
    IniFile.WriteString('Strings', 'BtnRefresh', LangStrings.BtnRefresh);
    IniFile.WriteString('Strings', 'BtnClose', LangStrings.BtnClose);
    IniFile.WriteString('Strings', 'BtnToggleSelect', LangStrings.BtnToggleSelect);
    IniFile.WriteString('Strings', 'LanguageGroupCaption', LangStrings.LanguageGroupCaption);
    IniFile.WriteString('Strings', 'DirectoryListBoxLabel', LangStrings.DirectoryListBoxLabel);
    IniFile.WriteString('Strings', 'FileListLabel', LangStrings.FileListLabel);
    IniFile.WriteString('Strings', 'CurrentEncodingLabel', LangStrings.CurrentEncodingLabel);
    IniFile.WriteString('Strings', 'FileSelectColumn', LangStrings.FileSelectColumn);
    IniFile.WriteString('Strings', 'FileNameColumn', LangStrings.FileNameColumn);
    IniFile.WriteString('Strings', 'EncodingColumn', LangStrings.EncodingColumn);
    IniFile.WriteString('Strings', 'PopupMenuConvert', LangStrings.PopupMenuConvert);
    IniFile.WriteString('Strings', 'PopupMenuToggleSelect', LangStrings.PopupMenuToggleSelect);
    IniFile.WriteString('Strings', 'NoFilesText', LangStrings.NoFilesText);
    IniFile.WriteString('Strings', 'ReadErrorText', LangStrings.ReadErrorText);
    IniFile.WriteString('Strings', 'LogSelectedDirectory', LangStrings.LogSelectedDirectory);
    
    // 更新到文件
    IniFile.UpdateFile;
  finally
    IniFile.Free;
  end;
end;

function TLanguageManager.ImportLanguage(const FilePath: string): Boolean;
var
  IniFile: TMemIniFile;
  LangInfo: TLanguageInfo;
  LangStrings: TLanguageStrings;
begin
  Result := False;
  
  if not FileExists(FilePath) then
    Exit;
    
  IniFile := TMemIniFile.Create(FilePath, TEncoding.UTF8);
  try
    // 读取语言代码和名称
    LangInfo.Code := IniFile.ReadString('Meta', 'LanguageCode', '');
    LangInfo.Name := IniFile.ReadString('Meta', 'LanguageName', '');
    LangInfo.NativeName := IniFile.ReadString('Meta', 'NativeName', LangInfo.Name);
    
    // 检查语言代码和名称是否有效
    if (LangInfo.Code = '') or (LangInfo.Name = '') then
      Exit;
      
    // 加载语言字符串
    LangStrings := LoadFromFile(FilePath);
    
    // 目标文件路径
    LangInfo.FileName := FLanguagePath + PathDelim + LangInfo.Code + '.ini';
    
    // 复制到语言目录
    if not DirectoryExists(FLanguagePath) then
      ForceDirectories(FLanguagePath);
      
    TFile.Copy(FilePath, LangInfo.FileName, True);
    
    // 添加或更新语言信息
    var ExistingIndex := -1;
    for var i := 0 to FLanguageInfoList.Count - 1 do
    begin
      if FLanguageInfoList[i].Code = LangInfo.Code then
      begin
        ExistingIndex := i;
        Break;
      end;
    end;
    
    if ExistingIndex >= 0 then
      FLanguageInfoList[ExistingIndex] := LangInfo
    else
      FLanguageInfoList.Add(LangInfo);
      
    // 更新语言字典
    if FLanguages.ContainsKey(LangInfo.Code) then
      FLanguages[LangInfo.Code] := LangStrings
    else
      FLanguages.Add(LangInfo.Code, LangStrings);
      
    Result := True;
  finally
    IniFile.Free;
  end;
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
var
  ConfigPath: string;
  IniFile: TMemIniFile;
begin
  ConfigPath := ChangeFileExt(Application.ExeName, '.ini');
  
  IniFile := TMemIniFile.Create(ConfigPath, TEncoding.UTF8);
  try
    IniFile.WriteString('Settings', 'Language', LangCode);
    IniFile.UpdateFile;
  finally
    IniFile.Free;
  end;
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