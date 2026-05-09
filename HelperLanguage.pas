unit HelperLanguage;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.IniFiles,
  System.IOUtils, Winapi.Windows, Vcl.Forms, ModelLanguage, UtilsTypes, System.Rtti, System.TypInfo;

type
  // ���Թ�������
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

// ��ȡ�����ַ����е�ָ����ֵ
function GetString(const Key: string): string;

implementation

{ TLanguageManager }

constructor TLanguageManager.Create;
begin
  inherited Create;

  // ��ʼ����Ա����
  FLanguages := TDictionary<string, TLanguageStrings>.Create;
  FLanguageInfoList := TList<TLanguageInfo>.Create;

  // ���������ļ�·��
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

  // Ĭ��ʹ��Ӣ��
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
  // ���������б�
  LoadLanguageList;

  // ���ؿ�������
  LoadAvailableLanguages;

  // ���Լ����û���ѡ���Ի�ϵͳ����
  FCurrentLanguage := GetDefaultLanguage;
end;

function TLanguageManager.GetDefaultLanguage: string;
var
  ConfigFile: string;
begin
  // �����ļ�·��
  ConfigFile := ExtractFilePath(Application.ExeName) + 'config\language.cfg';

  // ����Ƿ�����û���ѡ��������
  if FileExists(ConfigFile) then
  begin
    try
      Result := TFile.ReadAllText(ConfigFile, TEncoding.UTF8).Trim;
      if FLanguages.ContainsKey(Result) then
        Exit;
    except
      // ���Զ�ȡ����
    end;
  end;

  // ����ʹ��ϵͳ����
  Result := GetSystemLanguage;

  // ���ϵͳ���Բ����ã�ʹ��Ӣ��
  if not FLanguages.ContainsKey(Result) then
    Result := 'en-US';

  // ���Ӣ�ﲻ���ã�ʹ�õ�һ����������
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
  // ��ʼ��Ϊ�ռ�¼
  Result.Code := '';
  Result.Name := '';
  Result.NativeName := '';
  Result.FileName := '';

  // ����������Ϣ
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
begin
  // 13.1 syntax: inline var
  SetLength(Result, FLanguageInfoList.Count);
  for var i := 0 to FLanguageInfoList.Count - 1 do
    Result[i] := FLanguageInfoList[i];
end;

function TLanguageManager.GetLanguageNameByCode(const LangCode: string): string;
begin
  // 13.1 syntax: inline var + ternary
  var LangInfo := GetLanguageInfo(LangCode);
  Result := if LangInfo.Name <> '' then LangInfo.Name else LangCode;
end;

function TLanguageManager.GetLanguageStrings(const LangCode: string): TLanguageStrings;
var
  LangInfo: TLanguageInfo;
  LangFile: string;
begin
  // ������������ڴ��У�ֱ�ӷ���
  if FLanguages.TryGetValue(LangCode, Result) then
  begin
    OutputDebugString(PChar('Language strings found in memory for: ' + LangCode));
    Exit;
  end;

  OutputDebugString(PChar('Language strings not found in memory for: ' + LangCode + ', trying to load from file...'));

  // ���Բ���������Ϣ
  LangInfo := GetLanguageInfo(LangCode);

  // ����ҵ�������Ϣ�����Դ��ļ�����
  if LangInfo.Code <> '' then
  begin
    // ʹ��ȫ�ֱ���IniDir����FLanguagePath
    if IniDir <> '' then
      LangFile := IniDir + PathDelim + LangInfo.FileName
    else
      LangFile := FLanguagePath + PathDelim + LangInfo.FileName;

    OutputDebugString(PChar('Trying to load language file: ' + LangFile));

    // ����ļ��Ƿ����
    if FileExists(LangFile) then
    begin
      OutputDebugString(PChar('Language file exists, loading...'));

      // ���ļ����������ַ���
      Result := LoadFromIniFile(LangFile);

      // �����ص������ַ������ӵ��ֵ���
      FLanguages.Add(LangCode, Result);
      OutputDebugString(PChar('Language strings loaded and added to dictionary: ' + LangCode));
      Exit;
    end
    else
      OutputDebugString(PChar('Language file does not exist: ' + LangFile));
  end
  else
    OutputDebugString(PChar('Language info not found for: ' + LangCode));

  // ����޷����أ�����Ĭ���ַ���
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
  // Ĭ��ΪӢ��
  Result := 'en-US';

  // ��ȡϵͳ����ID
  LangID := GetUserDefaultLCID;

  // ��ȡ���Դ���
  BufferLen := GetLocaleInfo(LangID, LOCALE_SISO639LANGNAME, Buffer, Length(Buffer));
  if BufferLen > 0 then
  begin
    LangCode := Buffer;

    // ��ȡ����/��������
    BufferLen := GetLocaleInfo(LangID, LOCALE_SISO3166CTRYNAME, Buffer, Length(Buffer));
    if BufferLen > 0 then
      LangCode := LangCode + '-' + Buffer;

    // ת��Ϊ��д����/��������
    Result := LangCode;
  end;
end;

procedure TLanguageManager.LoadAvailableLanguages;
var
  LangStrings: TLanguageStrings;
begin
  // ��������ֵ�
  FLanguages.Clear;

  // ���������Ϣ
  OutputDebugString(PChar('Loading available languages, language list count: ' + IntToStr(FLanguageInfoList.Count)));

  // ��������������Ϣ
  for var i := 0 to FLanguageInfoList.Count - 1 do
  begin
    var LangInfo := FLanguageInfoList[i];

    // ���������Ϣ
    OutputDebugString(PChar('Processing language: ' + LangInfo.Code + ', file: ' + LangInfo.FileName));

    // 13.1 syntax: inline var + ternary for path resolution
    var LangFile := if IniDir <> '' then IniDir + PathDelim + LangInfo.FileName
                    else FLanguagePath + PathDelim + LangInfo.FileName;

    if FileExists(LangFile) then
    begin
      // ���������Ϣ
      OutputDebugString(PChar('Language file exists: ' + LangFile));

      try
        // ���������ļ�
        LangStrings := LoadFromIniFile(LangFile);

        // ���ӵ������ֵ�
        FLanguages.Add(LangInfo.Code, LangStrings);

        // ���������Ϣ
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
      // ���������Ϣ
      OutputDebugString(PChar('Language file does not exist: ' + LangFile));
    end;
  end;

  // ȷ��������һ�����Կ���
  if FLanguages.Count = 0 then
  begin
    // ����Ĭ��Ӣ���ַ���
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
  // ��������б�
  FLanguageInfoList.Clear;

  // ʹ��ȫ�ֱ���IniDir����FLanguagePath
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
      // ʹ��ȫ�ֱ���IniDir����FLanguagePath
      if IniDir <> '' then
        FilePath := IniDir + PathDelim + SearchRec.Name
      else
        FilePath := FLanguagePath + PathDelim + SearchRec.Name;

      // ���������Ϣ
      OutputDebugString(PChar('Found language file: ' + FilePath));

      // ʹ��TMemIniFile��ȡ������Ϣ
      IniFile := TMemIniFile.Create(FilePath, TEncoding.UTF8);
      try
        // ��ȡ����Ԫ����
        LangInfo.Code := IniFile.ReadString('Meta', 'LanguageCode', '');
        LangInfo.Name := IniFile.ReadString('Meta', 'LanguageName', '');
        LangInfo.NativeName := IniFile.ReadString('Meta', 'NativeName', '');
        LangInfo.FileName := SearchRec.Name;

        // ���������Ϣ
        OutputDebugString(PChar('Language info: Code=' + LangInfo.Code + ', Name=' + LangInfo.Name + ', NativeName=' + LangInfo.NativeName));

        // �������Ч�����Դ��룬���ӵ��б�
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

      // ������һ���ļ�
      FindResult := FindNext(SearchRec);
    end;
  finally
    System.SysUtils.FindClose(SearchRec);
  end;

  // ���û���ҵ��κ������ļ�������Ĭ������
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
      
      // �������к�ע��
      if (TempLine = '') or (TempLine.StartsWith('#')) or (TempLine.StartsWith(';')) then
        Continue;
      
      // ����Ƿ��ǽڱ���
      if TempLine.StartsWith('[') and TempLine.EndsWith(']') then
      begin
        InSection := SameText(Copy(TempLine, 2, Length(TempLine) - 2), Section);
        Continue;
      end;
      
      // �����Ŀ����У����Ҽ�ֵ
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
  // ��ʼ��ΪĬ���ַ���
  Result := CreateDefaultLanguageStrings;

  try
    // ʹ��TStringListֱ�Ӷ�ȡUTF-8�ļ�
    Lines := TStringList.Create;
    try
      Lines.LoadFromFile(FileName, TEncoding.UTF8);
      
      // ��ȡ�ַ�������
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

      // ������Ϣ
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
      
      // ������ʾ�ı�
      Result.ProgressSearchingFiles := GetValue('Progress', 'ProgressSearchingFiles');
      Result.ProgressDetectingEncoding := GetValue('Progress', 'ProgressDetectingEncoding');
      Result.ProgressDetecting := GetValue('Progress', 'ProgressDetecting');
      Result.ProgressComplete := GetValue('Progress', 'ProgressComplete');
      Result.ProgressCompleteFiles := GetValue('Progress', 'ProgressCompleteFiles');
      
      // ��־��Ϣ
      Result.LogDetectionComplete := GetValue('Logs', 'LogDetectionComplete');
      Result.LogFilesFound := GetValue('Logs', 'LogFilesFound');
      Result.LogDeselectAllFileTypes := GetValue('Logs', 'LogDeselectAllFileTypes');
      Result.LogSelectAllFileTypes := GetValue('Logs', 'LogSelectAllFileTypes');
      Result.LogForceUpdateFileList := GetValue('Logs', 'LogForceUpdateFileList');
      Result.LogAsyncScanComplete := GetValue('Logs', 'LogAsyncScanComplete');
      
      // UI��̬�ı�
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
  // ��������Ŀ¼
  ConfigDir := ExtractFilePath(Application.ExeName) + 'config';
  if not DirectoryExists(ConfigDir) then
    ForceDirectories(ConfigDir);

  // �����ļ�·��
  ConfigFile := ConfigDir + PathDelim + 'language.cfg';

  // ��������ѡ��
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
  // �������û�б仯��ֱ�ӷ���
  if FCurrentLanguage = LangCode then
    Exit;

  // ��������Ƿ����
  if not FLanguages.ContainsKey(LangCode) then
    Exit;

  // ���õ�ǰ����
  FCurrentLanguage := LangCode;

  // �����û���ѡ����
  SaveUserPreference(LangCode);

  // �������Ա���¼�
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
  // Ĭ�Ϸ��ؿ��ַ���
  Result := '';

  // ��ȡ��ǰ���Ե��ַ���
  Strings := GetLanguageStrings(FCurrentLanguage);

  // ʹ��RTTI��ȡ�ֶ�ֵ
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

// ȫ��GetString����ʵ��
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
