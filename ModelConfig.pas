unit ModelConfig;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles, System.IOUtils;

const
  INI_SECTION_GENERAL = 'General';
  INI_KEY_LAST_DIR = 'LastDirectory';
  INI_KEY_LAST_ENCODING = 'LastEncoding';
  INI_KEY_LAST_ADD_BOM = 'LastAddBOM';
  INI_KEY_INCLUDE_SUBDIRS = 'IncludeSubdirs';
  INI_KEY_LAST_LANGUAGE = 'LastLanguage';

type
  // ת�����ýṹ��
  TConversionConfig = record
    Name: string;                // ��������
    TargetEncoding: string;      // Ŀ�����
    AddBOM: Boolean;             // �Ƿ�����BOM
    IncludeSubdirs: Boolean;     // �Ƿ������Ŀ¼
    FileExtensions: TArray<string>; // �ļ���չ���б�
    LastDirectory: string;       // �ϴ�ʹ�õ�Ŀ¼
  end;

  // Ӧ�ó���������
  TAppConfig = class
  private
    FIniFile: TIniFile;
    FLastDirectory: string;
    FLastEncoding: string;
    FLastAddBOM: Boolean;
    FIncludeSubdirs: Boolean;
    FLastLanguage: string;
    FSavedConfigs: TArray<TConversionConfig>;

    procedure LoadSavedConfigs;
    procedure SaveConfigsToIni;

  public
    constructor Create;
    destructor Destroy; override;

    // ����ͼ�������
    procedure SaveConfig(const Config: TConversionConfig);
    function LoadConfig(const ConfigName: string; out Config: TConversionConfig): Boolean;
    function GetConfigNames: TArray<string>;
    procedure DeleteConfig(const ConfigName: string);

    // Ӧ�ó�������
    property LastDirectory: string read FLastDirectory write FLastDirectory;
    property LastEncoding: string read FLastEncoding write FLastEncoding;
    property LastAddBOM: Boolean read FLastAddBOM write FLastAddBOM;
    property IncludeSubdirs: Boolean read FIncludeSubdirs write FIncludeSubdirs;
    property LastLanguage: string read FLastLanguage write FLastLanguage;
    property SavedConfigs: TArray<TConversionConfig> read FSavedConfigs;
    property IniFile: TIniFile read FIniFile;
  end;

implementation

{ TAppConfig }

procedure TAppConfig.LoadSavedConfigs;
var
  ConfigNames: TArray<string>;
  ConfigName: string;
  Config: TConversionConfig;
begin
  // �����������
  SetLength(FSavedConfigs, 0);
  
  // ��ȡ������������
  ConfigNames := GetConfigNames;
  
  // ����ÿ������
  for ConfigName in ConfigNames do
  begin
    if LoadConfig(ConfigName, Config) then
    begin
      SetLength(FSavedConfigs, Length(FSavedConfigs) + 1);
      FSavedConfigs[High(FSavedConfigs)] := Config;
    end;
  end;
end;

procedure TAppConfig.SaveConfigsToIni;
var
  Config: TConversionConfig;
begin
  // ������������
  for Config in FSavedConfigs do
    SaveConfig(Config);
end;

procedure TAppConfig.SaveConfig(const Config: TConversionConfig);
begin
  if Config.Name = '' then
    Exit;
    
  var Section := 'Config_' + Config.Name;
  
  FIniFile.WriteString(Section, 'Name', Config.Name);
  FIniFile.WriteString(Section, 'TargetEncoding', Config.TargetEncoding);
  FIniFile.WriteBool(Section, 'AddBOM', Config.AddBOM);
  FIniFile.WriteBool(Section, 'IncludeSubdirs', Config.IncludeSubdirs);
  FIniFile.WriteString(Section, 'LastDirectory', Config.LastDirectory);
  
  // 13.1 syntax: inline var + string.Join pattern
  var ExtStr := '';
  for var i := 0 to High(Config.FileExtensions) do
  begin
    if i > 0 then
      ExtStr := ExtStr + ';';
    ExtStr := ExtStr + Config.FileExtensions[i];
  end;
  FIniFile.WriteString(Section, 'FileExtensions', ExtStr);
  
  FIniFile.UpdateFile;
end;

function TAppConfig.LoadConfig(const ConfigName: string; out Config: TConversionConfig): Boolean;
var
  Section: string;
  ExtStr: string;
  ExtList: TStringList;
  i: Integer;
begin
  Result := False;
  
  if ConfigName = '' then
    Exit;
    
  Section := 'Config_' + ConfigName;
  
  // ������ý��Ƿ����
  if not FIniFile.SectionExists(Section) then
    Exit;
  
  // ����������
  Config.Name := FIniFile.ReadString(Section, 'Name', ConfigName);
  Config.TargetEncoding := FIniFile.ReadString(Section, 'TargetEncoding', 'UTF-8');
  Config.AddBOM := FIniFile.ReadBool(Section, 'AddBOM', False);
  Config.IncludeSubdirs := FIniFile.ReadBool(Section, 'IncludeSubdirs', False);
  Config.LastDirectory := FIniFile.ReadString(Section, 'LastDirectory', '');
  
  // �����ļ���չ���б�
  ExtStr := FIniFile.ReadString(Section, 'FileExtensions', '');
  if ExtStr <> '' then
  begin
    ExtList := TStringList.Create;
    try
      ExtList.Delimiter := ';';
      ExtList.StrictDelimiter := True;
      ExtList.DelimitedText := ExtStr;
      
      SetLength(Config.FileExtensions, ExtList.Count);
      for i := 0 to ExtList.Count - 1 do
        Config.FileExtensions[i] := ExtList[i];
    finally
      ExtList.Free;
    end;
  end
  else
    SetLength(Config.FileExtensions, 0);
  
  Result := True;
end;

function TAppConfig.GetConfigNames: TArray<string>;
var
  Sections: TStringList;
  i, Count: Integer;
begin
  SetLength(Result, 0);
  
  Sections := TStringList.Create;
  try
    FIniFile.ReadSections(Sections);
    
    Count := 0;
    for i := 0 to Sections.Count - 1 do
    begin
      // ֻ��ȡ Config_ ��ͷ�Ľ�
      if Sections[i].StartsWith('Config_') then
      begin
        SetLength(Result, Count + 1);
        // �Ƴ� Config_ ǰ׺
        Result[Count] := Copy(Sections[i], 8, MaxInt);
        Inc(Count);
      end;
    end;
  finally
    Sections.Free;
  end;
end;

procedure TAppConfig.DeleteConfig(const ConfigName: string);
var
  Section: string;
  i: Integer;
begin
  if ConfigName = '' then
    Exit;
    
  Section := 'Config_' + ConfigName;
  
  // �� INI �ļ���ɾ��
  FIniFile.EraseSection(Section);
  FIniFile.UpdateFile;
  
  // ���ڴ���ɾ��
  for i := High(FSavedConfigs) downto 0 do
  begin
    if FSavedConfigs[i].Name = ConfigName then
    begin
      // �ƶ������Ԫ��
      if i < High(FSavedConfigs) then
        Move(FSavedConfigs[i + 1], FSavedConfigs[i], 
             (Length(FSavedConfigs) - i - 1) * SizeOf(TConversionConfig));
      // ���������С
      SetLength(FSavedConfigs, Length(FSavedConfigs) - 1);
      Break;
    end;
  end;
end;

constructor TAppConfig.Create;
begin
  inherited Create;

  // 13.1 syntax: inline var
  var IniPath := ExtractFilePath(ParamStr(0)) + 'ini';
  if not DirectoryExists(IniPath) then
    ForceDirectories(IniPath);

  FIniFile := TIniFile.Create(IniPath + '\DeepCharset.ini');

  FLastDirectory := FIniFile.ReadString(INI_SECTION_GENERAL, INI_KEY_LAST_DIR, '');
  FLastEncoding := FIniFile.ReadString(INI_SECTION_GENERAL, INI_KEY_LAST_ENCODING, 'UTF-8');
  FLastAddBOM := FIniFile.ReadBool(INI_SECTION_GENERAL, INI_KEY_LAST_ADD_BOM, True);
  FIncludeSubdirs := FIniFile.ReadBool(INI_SECTION_GENERAL, INI_KEY_INCLUDE_SUBDIRS, False);
  FLastLanguage := FIniFile.ReadString(INI_SECTION_GENERAL, INI_KEY_LAST_LANGUAGE, 'zh-CN');

  LoadSavedConfigs;
end;

destructor TAppConfig.Destroy;
begin
  // ��������
  FIniFile.WriteString(INI_SECTION_GENERAL, INI_KEY_LAST_DIR, FLastDirectory);
  FIniFile.WriteString(INI_SECTION_GENERAL, INI_KEY_LAST_ENCODING, FLastEncoding);
  FIniFile.WriteBool(INI_SECTION_GENERAL, INI_KEY_LAST_ADD_BOM, FLastAddBOM);
  FIniFile.WriteBool(INI_SECTION_GENERAL, INI_KEY_INCLUDE_SUBDIRS, FIncludeSubdirs);
  FIniFile.WriteString(INI_SECTION_GENERAL, INI_KEY_LAST_LANGUAGE, FLastLanguage);

  // ���������б�
  SaveConfigsToIni;

  // �ͷ�INI�ļ�
  FIniFile.Free;

  inherited;
end;

end.