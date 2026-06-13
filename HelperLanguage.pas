unit HelperLanguage;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.IniFiles,
  System.IOUtils, Winapi.Windows, Vcl.Forms, ModelLanguage, UtilsTypes, System.Rtti, System.TypInfo;

type

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


function GetString(const Key: string): string;

implementation

{ TLanguageManager }

constructor TLanguageManager.Create;
begin
  inherited Create;


  FLanguages := TDictionary<string, TLanguageStrings>.Create;
  FLanguageInfoList := TList<TLanguageInfo>.Create;


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

  LoadLanguageList;


  LoadAvailableLanguages;


  FCurrentLanguage := GetDefaultLanguage;
end;

function TLanguageManager.GetDefaultLanguage: string;
var
  ConfigFile: string;
begin

  ConfigFile := ExtractFilePath(Application.ExeName) + 'config\language.cfg';


  if FileExists(ConfigFile) then
  begin
    try
      Result := TFile.ReadAllText(ConfigFile, TEncoding.UTF8).Trim;
      if FLanguages.ContainsKey(Result) then
        Exit;
    except

    end;
  end;


  Result := GetSystemLanguage;


  if not FLanguages.ContainsKey(Result) then
    Result := 'en-US';


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

  Result.Code := '';
  Result.Name := '';
  Result.NativeName := '';
  Result.FileName := '';


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
  // Inline var + 标准 if-else
  var LangInfo := GetLanguageInfo(LangCode);
  if LangInfo.Name <> '' then Result := LangInfo.Name else Result := LangCode;
end;

function TLanguageManager.GetLanguageStrings(const LangCode: string): TLanguageStrings;
var
  LangInfo: TLanguageInfo;
  LangFile: string;
begin

  if FLanguages.TryGetValue(LangCode, Result) then
  begin
    OutputDebugString(PChar('Language strings found in memory for: ' + LangCode));
    Exit;
  end;

  OutputDebugString(PChar('Language strings not found in memory for: ' + LangCode + ', trying to load from file...'));


  LangInfo := GetLanguageInfo(LangCode);


  if LangInfo.Code <> '' then
  begin

    if IniDir <> '' then
      LangFile := IniDir + PathDelim + LangInfo.FileName
    else
      LangFile := FLanguagePath + PathDelim + LangInfo.FileName;

    OutputDebugString(PChar('Trying to load language file: ' + LangFile));


    if FileExists(LangFile) then
    begin
      OutputDebugString(PChar('Language file exists, loading...'));


      Result := LoadFromIniFile(LangFile);


      FLanguages.Add(LangCode, Result);
      OutputDebugString(PChar('Language strings loaded and added to dictionary: ' + LangCode));
      Exit;
    end
    else
      OutputDebugString(PChar('Language file does not exist: ' + LangFile));
  end
  else
    OutputDebugString(PChar('Language info not found for: ' + LangCode));


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

  Result := 'en-US';


  LangID := GetUserDefaultLCID;


  BufferLen := GetLocaleInfo(LangID, LOCALE_SISO639LANGNAME, Buffer, Length(Buffer));
  if BufferLen > 0 then
  begin
    LangCode := Buffer;


    BufferLen := GetLocaleInfo(LangID, LOCALE_SISO3166CTRYNAME, Buffer, Length(Buffer));
    if BufferLen > 0 then
      LangCode := LangCode + '-' + Buffer;


    Result := LangCode;
  end;
end;

procedure TLanguageManager.LoadAvailableLanguages;
var
  LangStrings: TLanguageStrings;
begin

  FLanguages.Clear;


  OutputDebugString(PChar('Loading available languages, language list count: ' + IntToStr(FLanguageInfoList.Count)));


  for var i := 0 to FLanguageInfoList.Count - 1 do
  begin
    var LangInfo := FLanguageInfoList[i];


    OutputDebugString(PChar('Processing language: ' + LangInfo.Code + ', file: ' + LangInfo.FileName));

    // Inline var + 标准 if-else for path resolution
    var LangFile: string;
    if IniDir <> '' then
      LangFile := IniDir + PathDelim + LangInfo.FileName
    else
      LangFile := FLanguagePath + PathDelim + LangInfo.FileName;

    if FileExists(LangFile) then
    begin

      OutputDebugString(PChar('Language file exists: ' + LangFile));

      try

        LangStrings := LoadFromIniFile(LangFile);


        FLanguages.Add(LangInfo.Code, LangStrings);


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

      OutputDebugString(PChar('Language file does not exist: ' + LangFile));
    end;
  end;


  if FLanguages.Count = 0 then
  begin

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

  FLanguageInfoList.Clear;


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

      if IniDir <> '' then
        FilePath := IniDir + PathDelim + SearchRec.Name
      else
        FilePath := FLanguagePath + PathDelim + SearchRec.Name;


      OutputDebugString(PChar('Found language file: ' + FilePath));


      try
        IniFile := TMemIniFile.Create(FilePath, TEncoding.UTF8);
      except
        on EEncodingError do
          IniFile := TMemIniFile.Create(FilePath, TEncoding.Default);
      end;
      try

        LangInfo.Code := IniFile.ReadString('Meta', 'LanguageCode', '');
        LangInfo.Name := IniFile.ReadString('Meta', 'LanguageName', '');
        LangInfo.NativeName := IniFile.ReadString('Meta', 'NativeName', '');
        LangInfo.FileName := SearchRec.Name;


        OutputDebugString(PChar('Language info: Code=' + LangInfo.Code + ', Name=' + LangInfo.Name + ', NativeName=' + LangInfo.NativeName));


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


      FindResult := FindNext(SearchRec);
    end;
  finally
    System.SysUtils.FindClose(SearchRec);
  end;


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
      

      if (TempLine = '') or (TempLine.StartsWith('#')) or (TempLine.StartsWith(';')) then
        Continue;
      

      if TempLine.StartsWith('[') and TempLine.EndsWith(']') then
      begin
        InSection := SameText(Copy(TempLine, 2, Length(TempLine) - 2), Section);
        Continue;
      end;
      

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

  Result := CreateDefaultLanguageStrings;

  try

    Lines := TStringList.Create;
    try
      try
        Lines.LoadFromFile(FileName, TEncoding.UTF8);
      except
        on EEncodingError do
        begin
          // UTF-8 loading failed, try with default encoding as fallback
          try
            Lines.LoadFromFile(FileName, TEncoding.Default);
          except
            // If default also fails, use empty list
          end;
        end;
      end;
      

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
      

      Result.ProgressSearchingFiles := GetValue('Progress', 'ProgressSearchingFiles');
      Result.ProgressDetectingEncoding := GetValue('Progress', 'ProgressDetectingEncoding');
      Result.ProgressDetecting := GetValue('Progress', 'ProgressDetecting');
      Result.ProgressComplete := GetValue('Progress', 'ProgressComplete');
      Result.ProgressCompleteFiles := GetValue('Progress', 'ProgressCompleteFiles');
      

      Result.LogDetectionComplete := GetValue('Logs', 'LogDetectionComplete');
      Result.LogFilesFound := GetValue('Logs', 'LogFilesFound');
      Result.LogDeselectAllFileTypes := GetValue('Logs', 'LogDeselectAllFileTypes');
      Result.LogSelectAllFileTypes := GetValue('Logs', 'LogSelectAllFileTypes');
      Result.LogForceUpdateFileList := GetValue('Logs', 'LogForceUpdateFileList');
      Result.LogAsyncScanComplete := GetValue('Logs', 'LogAsyncScanComplete');
      Result.LogBatchConversionStart := GetValue('Logs', 'LogBatchConversionStart');
      Result.LogRefreshDirectory := GetValue('Logs', 'LogRefreshDirectory');
      Result.LogStartSearching := GetValue('Logs', 'LogStartSearching');
      Result.LogRefreshingFileList := GetValue('Logs', 'LogRefreshingFileList');
      Result.LogFileListRefreshed := GetValue('Logs', 'LogFileListRefreshed');
      Result.LogWarningInvalidLanguage := GetValue('Logs', 'LogWarningInvalidLanguage');
      Result.LogUserSelectedLanguage := GetValue('Logs', 'LogUserSelectedLanguage');
      Result.LogSwitchToLanguage := GetValue('Logs', 'LogSwitchToLanguage');
      Result.LogRootDirectory := GetValue('Logs', 'LogRootDirectory');
      Result.LogIniDirectory := GetValue('Logs', 'LogIniDirectory');
      Result.LogUserCancelled := GetValue('Logs', 'LogUserCancelled');
      Result.LogConversionSkipped := GetValue('Logs', 'LogConversionSkipped');
      Result.MsgSelectValidFolder := GetValue('Logs', 'MsgSelectValidFolder');
      Result.ChkInstantScan := GetValue('Logs', 'ChkInstantScan');
      Result.BtnScanDir := GetValue('Logs', 'BtnScanDir');
      Result.LogInstantScanOn := GetValue('Logs', 'LogInstantScanOn');
      Result.LogInstantScanOff := GetValue('Logs', 'LogInstantScanOff');


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

  ConfigDir := ExtractFilePath(Application.ExeName) + 'config';
  if not DirectoryExists(ConfigDir) then
    ForceDirectories(ConfigDir);


  ConfigFile := ConfigDir + PathDelim + 'language.cfg';


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

  if FCurrentLanguage = LangCode then
    Exit;


  if not FLanguages.ContainsKey(LangCode) then
    Exit;


  FCurrentLanguage := LangCode;


  SaveUserPreference(LangCode);


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

  Result := '';


  Strings := GetLanguageStrings(FCurrentLanguage);


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
