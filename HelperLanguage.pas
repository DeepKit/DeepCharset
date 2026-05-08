unit HelperLanguage;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.IniFiles,
  System.IOUtils, Winapi.Windows, Vcl.Forms, ModelLanguage, UtilsTypes, System.Rtti, System.TypInfo;

type
  // 语言管理器类
  TLanguageManager = class
  private
    FCurrentLanguage: string;
    FLanguages: TDictionary<string, TLanguageStrings>;
    FLanguageInfoList: TList<TLanguageInfo>;
    FOnLanguageChange: TOnLanguageChangeEvent;
    FLanguagePath: string;

    function LoadFromIniFile(const FileName: string): TLanguageStrings;
    procedure SaveUserPreference(const LangCode: string);
    function GetDefaultLanguage: string;
    procedure LoadLanguageList;
    function GetSystemLanguage: string;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Initialize;
    procedure LoadAvailableLanguages;
    function GetLanguageList: TArray<TLanguageInfo>;
    function GetLanguageStrings(const LangCode: string): TLanguageStrings;
    procedure SetLanguage(const LangCode: string);
    function GetLanguageNameByCode(const LangCode: string): string;
    function GetLanguageInfo(const LangCode: string): TLanguageInfo;
    function GetString(const Key: string): string;

    property CurrentLanguage: string read FCurrentLanguage;
    property OnLanguageChange: TOnLanguageChangeEvent read FOnLanguageChange write FOnLanguageChange;
    property LanguagePath: string read FLanguagePath write FLanguagePath;
  end;

var
  LanguageManager: TLanguageManager;

// 获取语言字符串中的指定键值
function GetString(const Key: string): string;

implementation

{ TLanguageManager }

constructor TLanguageManager.Create;
begin
  inherited Create;

  // 初始化成员变量
  FLanguages := TDictionary<string, TLanguageStrings>.Create;
  FLanguageInfoList := TList<TLanguageInfo>.Create;

  // 设置语言文件路径
  if IniDir <> '' then
    FLanguagePath := IniDir
  else
    FLanguagePath := ExtractFilePath(Application.ExeName) + 'ini';

  OutputDebugString(PChar('Language path set to: ' + FLanguagePath));

  if not DirectoryExists(FLanguagePath) then
  begin
    ForceDirectories(FLanguagePath);
    OutputDebugString(PChar('Created language directory: ' + FLanguagePath));
  end;

  // 默认使用英语
  FCurrentLanguage := 'en-US';
end;

destructor TLanguageManager.Destroy;
begin
  FLanguages.Free;
  FLanguageInfoList.Free;
  inherited;
end;

procedure TLanguageManager.Initialize;
begin
  // 加载语言列表
  LoadLanguageList;

  // 加载可用语言
  LoadAvailableLanguages;

  // 尝试加载用户首选语言或系统语言
  FCurrentLanguage := GetDefaultLanguage;
end;

function TLanguageManager.GetDefaultLanguage: string;
var
  ConfigFile: string;
begin
  // 配置文件路径
  ConfigFile := ExtractFilePath(Application.ExeName) + 'config\language.cfg';

  // 检查是否存在用户首选语言配置
  if FileExists(ConfigFile) then
  begin
    try
      Result := TFile.ReadAllText(ConfigFile, TEncoding.UTF8).Trim;
      if FLanguages.ContainsKey(Result) then
        Exit;
    except
      // 忽略读取错误
    end;
  end;

  // 尝试使用系统语言
  Result := GetSystemLanguage;

  // 如果系统语言不可用，使用英语
  if not FLanguages.ContainsKey(Result) then
    Result := 'en-US';

  // 如果英语不可用，使用第一个可用语言
  if not FLanguages.ContainsKey(Result) and (FLanguages.Count > 0) then
  begin
    var Enumerator := FLanguages.Keys.GetEnumerator;
    if Enumerator.MoveNext then
      Result := Enumerator.Current;
  end;
end;

function TLanguageManager.GetLanguageInfo(const LangCode: string): TLanguageInfo;
var
  i: Integer;
begin
  // 初始化为空记录
  Result.Code := '';
  Result.Name := '';
  Result.NativeName := '';
  Result.FileName := '';

  // 查找语言信息
  for i := 0 to FLanguageInfoList.Count - 1 do
  begin
    if FLanguageInfoList[i].Code = LangCode then
    begin
      Result := FLanguageInfoList[i];
      Break;
    end;
  end;
end;

function TLanguageManager.GetLanguageList: TArray<TLanguageInfo>;
var
  i: Integer;
begin
  SetLength(Result, FLanguageInfoList.Count);
  for i := 0 to FLanguageInfoList.Count - 1 do
    Result[i] := FLanguageInfoList[i];
end;

function TLanguageManager.GetLanguageNameByCode(const LangCode: string): string;
var
  LangInfo: TLanguageInfo;
begin
  LangInfo := GetLanguageInfo(LangCode);
  if LangInfo.Name <> '' then
    Result := LangInfo.Name
  else
    Result := LangCode;
end;

function TLanguageManager.GetLanguageStrings(const LangCode: string): TLanguageStrings;
var
  LangInfo: TLanguageInfo;
  LangFile: string;
begin
  // 如果语言已在内存中，直接返回
  if FLanguages.TryGetValue(LangCode, Result) then
  begin
    OutputDebugString(PChar('Language strings found in memory for: ' + LangCode));
    Exit;
  end;

  OutputDebugString(PChar('Language strings not found in memory for: ' + LangCode + ', trying to load from file...'));

  // 尝试查找语言信息
  LangInfo := GetLanguageInfo(LangCode);

  // 如果找到语言信息，尝试从文件加载
  if LangInfo.Code <> '' then
  begin
    // 使用全局变量IniDir而非FLanguagePath
    if IniDir <> '' then
      LangFile := IniDir + PathDelim + LangInfo.FileName
    else
      LangFile := FLanguagePath + PathDelim + LangInfo.FileName;

    OutputDebugString(PChar('Trying to load language file: ' + LangFile));

    // 检查文件是否存在
    if FileExists(LangFile) then
    begin
      OutputDebugString(PChar('Language file exists, loading...'));

      // 从文件加载语言字符串
      Result := LoadFromIniFile(LangFile);

      // 将加载的语言字符串添加到字典中
      FLanguages.Add(LangCode, Result);
      OutputDebugString(PChar('Language strings loaded and added to dictionary: ' + LangCode));
      Exit;
    end
    else
      OutputDebugString(PChar('Language file does not exist: ' + LangFile));
  end
  else
    OutputDebugString(PChar('Language info not found for: ' + LangCode));

  // 如果无法加载，返回默认字符串
  OutputDebugString(PChar('Returning default language strings for: ' + LangCode));
  Result := CreateDefaultLanguageStrings;
end;

function TLanguageManager.GetSystemLanguage: string;
var
  LangID: Word;
  LangCode: string;
  Buffer: array[0..255] of Char;
  BufferLen: Integer;
begin
  // 默认为英语
  Result := 'en-US';

  // 获取系统语言ID
  LangID := GetUserDefaultLCID;

  // 获取语言代码
  BufferLen := GetLocaleInfo(LangID, LOCALE_SISO639LANGNAME, Buffer, Length(Buffer));
  if BufferLen > 0 then
  begin
    LangCode := Buffer;

    // 获取国家/地区代码
    BufferLen := GetLocaleInfo(LangID, LOCALE_SISO3166CTRYNAME, Buffer, Length(Buffer));
    if BufferLen > 0 then
      LangCode := LangCode + '-' + Buffer;

    // 转换为大写国家/地区代码
    Result := LangCode;
  end;
end;

procedure TLanguageManager.LoadAvailableLanguages;
var
  i: Integer;
  LangInfo: TLanguageInfo;
  LangFile: string;
  LangStrings: TLanguageStrings;
begin
  // 清空语言字典
  FLanguages.Clear;

  // 输出调试信息
  OutputDebugString(PChar('Loading available languages, language list count: ' + IntToStr(FLanguageInfoList.Count)));

  // 遍历所有语言信息
  for i := 0 to FLanguageInfoList.Count - 1 do
  begin
    LangInfo := FLanguageInfoList[i];

    // 输出调试信息
    OutputDebugString(PChar('Processing language: ' + LangInfo.Code + ', file: ' + LangInfo.FileName));

    // 检查语言文件是否存在
    // 使用全局变量IniDir而非FLanguagePath
    if IniDir <> '' then
      LangFile := IniDir + PathDelim + LangInfo.FileName
    else
      LangFile := FLanguagePath + PathDelim + LangInfo.FileName;

    if FileExists(LangFile) then
    begin
      // 输出调试信息
      OutputDebugString(PChar('Language file exists: ' + LangFile));

      try
        // 加载语言文件
        LangStrings := LoadFromIniFile(LangFile);

        // 添加到语言字典
        FLanguages.Add(LangInfo.Code, LangStrings);

        // 输出调试信息
        OutputDebugString(PChar('Added language to dictionary: ' + LangInfo.Code));
      except
        on E: Exception do
        begin
          OutputDebugString(PChar('Error loading language file ' + LangFile + ': ' + E.Message));
        end;
      end;
    end
    else
    begin
      // 输出调试信息
      OutputDebugString(PChar('Language file does not exist: ' + LangFile));
    end;
  end;

  // 确保至少有一种语言可用
  if FLanguages.Count = 0 then
  begin
    // 创建默认英语字符串
    LangStrings := CreateDefaultLanguageStrings;
    FLanguages.Add('en-US', LangStrings);
  end;
end;

procedure TLanguageManager.LoadLanguageList;
var
  SearchRec: TSearchRec;
  LangInfo: TLanguageInfo;
  IniFile: TMemIniFile;
  FilePath: string;
  FindResult: Integer;
begin
  // 清空语言列表
  FLanguageInfoList.Clear;

  // 使用全局变量IniDir而非FLanguagePath
  if IniDir <> '' then
  begin
    OutputDebugString(PChar('Searching for language files in: ' + IniDir));
    FindResult := FindFirst(IniDir + PathDelim + '*.ini', faAnyFile, SearchRec);
  end
  else
  begin
    OutputDebugString(PChar('Searching for language files in: ' + FLanguagePath));
    FindResult := FindFirst(FLanguagePath + PathDelim + '*.ini', faAnyFile, SearchRec);
  end;
  try
    while FindResult = 0 do
    begin
      // 使用全局变量IniDir而非FLanguagePath
      if IniDir <> '' then
        FilePath := IniDir + PathDelim + SearchRec.Name
      else
        FilePath := FLanguagePath + PathDelim + SearchRec.Name;

      // 输出调试信息
      OutputDebugString(PChar('Found language file: ' + FilePath));

      // 使用TMemIniFile读取语言信息
      IniFile := TMemIniFile.Create(FilePath, TEncoding.UTF8);
      try
        // 读取语言元数据
        LangInfo.Code := IniFile.ReadString('Meta', 'LanguageCode', '');
        LangInfo.Name := IniFile.ReadString('Meta', 'LanguageName', '');
        LangInfo.NativeName := IniFile.ReadString('Meta', 'NativeName', '');
        LangInfo.FileName := SearchRec.Name;

        // 输出调试信息
        OutputDebugString(PChar('Language info: Code=' + LangInfo.Code + ', Name=' + LangInfo.Name + ', NativeName=' + LangInfo.NativeName));

        // 如果有有效的语言代码，添加到列表
        if LangInfo.Code <> '' then
        begin
          FLanguageInfoList.Add(LangInfo);
          OutputDebugString(PChar('Added language to list: ' + LangInfo.Code));
        end
        else
          OutputDebugString(PChar('Invalid language code in file: ' + FilePath));
      finally
        IniFile.Free;
      end;

      // 查找下一个文件
      FindResult := FindNext(SearchRec);
    end;
  finally
    System.SysUtils.FindClose(SearchRec);
  end;

  // 如果没有找到任何语言文件，添加默认语言
  if FLanguageInfoList.Count = 0 then
  begin
    LangInfo.Code := 'en-US';
    LangInfo.Name := 'English';
    LangInfo.NativeName := 'English';
    LangInfo.FileName := 'en-US.ini';
    FLanguageInfoList.Add(LangInfo);
  end;
end;

function TLanguageManager.LoadFromIniFile(const FileName: string): TLanguageStrings;
var
  Lines: TStringList;
  EqualPos: Integer;
  
  function GetValue(const Section, KeyName: string): string;
  var
    j: Integer;
    InSection: Boolean;
    TempLine, TempKey: string;
  begin
    Result := '';
    InSection := False;
    
    for j := 0 to Lines.Count - 1 do
    begin
      TempLine := Trim(Lines[j]);
      
      // 跳过空行和注释
      if (TempLine = '') or (TempLine.StartsWith('#')) or (TempLine.StartsWith(';')) then
        Continue;
      
      // 检查是否是节标题
      if TempLine.StartsWith('[') and TempLine.EndsWith(']') then
      begin
        InSection := SameText(Copy(TempLine, 2, Length(TempLine) - 2), Section);
        Continue;
      end;
      
      // 如果在目标节中，查找键值
      if InSection then
      begin
        EqualPos := Pos('=', TempLine);
        if EqualPos > 0 then
        begin
          TempKey := Trim(Copy(TempLine, 1, EqualPos - 1));
          if SameText(TempKey, KeyName) then
          begin
            Result := Trim(Copy(TempLine, EqualPos + 1, MaxInt));
            Exit;
          end;
        end;
      end;
    end;
  end;
  
begin
  // 初始化为默认字符串
  Result := CreateDefaultLanguageStrings;

  try
    // 使用TStringList直接读取UTF-8文件
    Lines := TStringList.Create;
    try
      Lines.LoadFromFile(FileName, TEncoding.UTF8);
      
      // 读取字符串部分
      Result.WindowTitle := GetValue('Strings', 'WindowTitle');
      Result.BtnConvert := GetValue('Strings', 'BtnConvert');
      Result.BtnSingleFile := GetValue('Strings', 'BtnSingleFile');
      Result.BtnRefresh := GetValue('Strings', 'BtnRefresh');
      Result.BtnClose := GetValue('Strings', 'BtnClose');
      Result.BtnToggleSelect := GetValue('Strings', 'BtnToggleSelect');
      Result.BtnPreview := GetValue('Strings', 'BtnPreview');
      Result.LanguageGroupCaption := GetValue('Strings', 'LanguageGroupCaption');
      Result.DirectoryListBoxLabel := GetValue('Strings', 'DirectoryListBoxLabel');
      Result.FileListLabel := GetValue('Strings', 'FileListLabel');
      Result.CurrentEncodingLabel := GetValue('Strings', 'CurrentEncodingLabel');
      Result.FileSelectColumn := GetValue('Strings', 'FileSelectColumn');
      Result.FileNameColumn := GetValue('Strings', 'FileNameColumn');
      Result.EncodingColumn := GetValue('Strings', 'EncodingColumn');
      Result.PopupMenuConvert := GetValue('Strings', 'PopupMenuConvert');
      Result.PopupMenuToggleSelect := GetValue('Strings', 'PopupMenuToggleSelect');
      Result.NoFilesText := GetValue('Strings', 'NoFilesText');
      Result.ReadErrorText := GetValue('Strings', 'ReadErrorText');
      Result.LogSelectedDirectory := GetValue('Strings', 'LogSelectedDirectory');
      Result.BtnAllFileTypes := GetValue('Strings', 'BtnAllFileTypes');
      Result.BtnCheckContent := GetValue('Strings', 'BtnCheckContent');
      Result.ChkIncludeSubdirs := GetValue('Strings', 'ChkIncludeSubdirs');

      // 弹窗消息
      Result.MsgSelectTargetEncoding := GetValue('Messages', 'MsgSelectTargetEncoding');
      Result.MsgSelectFiles := GetValue('Messages', 'MsgSelectFiles');
      Result.MsgNoMatchingFiles := GetValue('Messages', 'MsgNoMatchingFiles');
      Result.MsgConversionComplete := GetValue('Messages', 'MsgConversionComplete');
      Result.MsgConversionFailed := GetValue('Messages', 'MsgConversionFailed');
      Result.MsgFileNotExists := GetValue('Messages', 'MsgFileNotExists');
      Result.MsgNotTextFile := GetValue('Messages', 'MsgNotTextFile');
      Result.MsgSingleFileSuccess := GetValue('Messages', 'MsgSingleFileSuccess');
      Result.MsgSingleFileFailed := GetValue('Messages', 'MsgSingleFileFailed');
      Result.MsgSelectFile := GetValue('Messages', 'MsgSelectFile');
      Result.MsgCannotCreateViewer := GetValue('Messages', 'MsgCannotCreateViewer');
      Result.MsgCannotLoadFile := GetValue('Messages', 'MsgCannotLoadFile');
      Result.MsgViewerError := GetValue('Messages', 'MsgViewerError');
      Result.MsgSubdirEnabled := GetValue('Messages', 'MsgSubdirEnabled');
      Result.MsgConversionSuccess := GetValue('Messages', 'MsgConversionSuccess');
      
      // 进度提示文本
      Result.ProgressSearchingFiles := GetValue('Progress', 'ProgressSearchingFiles');
      Result.ProgressDetectingEncoding := GetValue('Progress', 'ProgressDetectingEncoding');
      Result.ProgressDetecting := GetValue('Progress', 'ProgressDetecting');
      Result.ProgressComplete := GetValue('Progress', 'ProgressComplete');
      Result.ProgressCompleteFiles := GetValue('Progress', 'ProgressCompleteFiles');
      
      // 日志消息
      Result.LogDetectionComplete := GetValue('Logs', 'LogDetectionComplete');
      Result.LogFilesFound := GetValue('Logs', 'LogFilesFound');
      Result.LogDeselectAllFileTypes := GetValue('Logs', 'LogDeselectAllFileTypes');
      Result.LogSelectAllFileTypes := GetValue('Logs', 'LogSelectAllFileTypes');
      Result.LogForceUpdateFileList := GetValue('Logs', 'LogForceUpdateFileList');
      Result.LogAsyncScanComplete := GetValue('Logs', 'LogAsyncScanComplete');
      
      // UI动态文本
      Result.BtnSelectAllFileTypes := GetValue('UI', 'BtnSelectAllFileTypes');
      Result.BtnDeselectAllFileTypes := GetValue('UI', 'BtnDeselectAllFileTypes');
      Result.WindowTitleDefault := GetValue('UI', 'WindowTitleDefault');
      Result.WindowTitleScanProgress := GetValue('UI', 'WindowTitleScanProgress');
      Result.WindowTitleConvertProgress := GetValue('UI', 'WindowTitleConvertProgress');
      Result.SingleFileConvertSuffix := GetValue('UI', 'SingleFileConvertSuffix');
    finally
      Lines.Free;
    end;
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('Error loading language file ' + FileName + ': ' + E.Message));
    end;
  end;
end;

procedure TLanguageManager.SaveUserPreference(const LangCode: string);
var
  ConfigFile: string;
  ConfigDir: string;
begin
  // 创建配置目录
  ConfigDir := ExtractFilePath(Application.ExeName) + 'config';
  if not DirectoryExists(ConfigDir) then
    ForceDirectories(ConfigDir);

  // 配置文件路径
  ConfigFile := ConfigDir + PathDelim + 'language.cfg';

  // 保存语言选择
  try
    TFile.WriteAllText(ConfigFile, LangCode, TEncoding.UTF8);
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('Error saving language preference: ' + E.Message));
    end;
  end;
end;

procedure TLanguageManager.SetLanguage(const LangCode: string);
begin
  // 如果语言没有变化，直接返回
  if FCurrentLanguage = LangCode then
    Exit;

  // 检查语言是否可用
  if not FLanguages.ContainsKey(LangCode) then
    Exit;

  // 设置当前语言
  FCurrentLanguage := LangCode;

  // 保存用户首选语言
  SaveUserPreference(LangCode);

  // 触发语言变更事件
  if Assigned(FOnLanguageChange) then
    FOnLanguageChange(LangCode);
end;

function TLanguageManager.GetString(const Key: string): string;
var
  Strings: TLanguageStrings;
  Value: string;
  KeyField: TRttiField;
  Context: TRttiContext;
  StringsType: TRttiType;
begin
  // 默认返回空字符串
  Result := '';

  // 获取当前语言的字符串
  Strings := GetLanguageStrings(FCurrentLanguage);

  // 使用RTTI获取字段值
  Context := TRttiContext.Create;
  try
    StringsType := Context.GetType(TypeInfo(TLanguageStrings));
    if Assigned(StringsType) then
    begin
      KeyField := StringsType.GetField(Key);
      if Assigned(KeyField) then
      begin
        Value := KeyField.GetValue(@Strings).AsString;
        if Value <> '' then
          Result := Value;
      end;
    end;
  finally
    Context.Free;
  end;
end;

// 全局GetString函数实现
function GetString(const Key: string): string;
begin
  if Assigned(LanguageManager) then
    Result := LanguageManager.GetString(Key)
  else
    Result := '';
end;

initialization
  LanguageManager := TLanguageManager.Create;

finalization
  LanguageManager.Free;

end.
