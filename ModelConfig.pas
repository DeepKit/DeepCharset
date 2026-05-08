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
  // 转换配置结构体
  TConversionConfig = record
    Name: string;                // 配置名称
    TargetEncoding: string;      // 目标编码
    AddBOM: Boolean;             // 是否添加BOM
    IncludeSubdirs: Boolean;     // 是否包含子目录
    FileExtensions: TArray<string>; // 文件扩展名列表
    LastDirectory: string;       // 上次使用的目录
  end;

  // 应用程序配置类
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

    // 保存和加载配置
    procedure SaveConfig(const Config: TConversionConfig);
    function LoadConfig(const ConfigName: string; out Config: TConversionConfig): Boolean;
    function GetConfigNames: TArray<string>;
    procedure DeleteConfig(const ConfigName: string);

    // 应用程序设置
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
  // 清空现有配置
  SetLength(FSavedConfigs, 0);
  
  // 获取所有配置名称
  ConfigNames := GetConfigNames;
  
  // 加载每个配置
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
  // 保存所有配置
  for Config in FSavedConfigs do
    SaveConfig(Config);
end;

procedure TAppConfig.SaveConfig(const Config: TConversionConfig);
var
  Section: string;
  i: Integer;
  ExtStr: string;
begin
  if Config.Name = '' then
    Exit;
    
  Section := 'Config_' + Config.Name;
  
  // 保存配置项
  FIniFile.WriteString(Section, 'Name', Config.Name);
  FIniFile.WriteString(Section, 'TargetEncoding', Config.TargetEncoding);
  FIniFile.WriteBool(Section, 'AddBOM', Config.AddBOM);
  FIniFile.WriteBool(Section, 'IncludeSubdirs', Config.IncludeSubdirs);
  FIniFile.WriteString(Section, 'LastDirectory', Config.LastDirectory);
  
  // 保存文件扩展名列表
  ExtStr := '';
  for i := 0 to High(Config.FileExtensions) do
  begin
    if i > 0 then
      ExtStr := ExtStr + ';';
    ExtStr := ExtStr + Config.FileExtensions[i];
  end;
  FIniFile.WriteString(Section, 'FileExtensions', ExtStr);
  
  // 刷新 INI 文件
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
  
  // 检查配置节是否存在
  if not FIniFile.SectionExists(Section) then
    Exit;
  
  // 加载配置项
  Config.Name := FIniFile.ReadString(Section, 'Name', ConfigName);
  Config.TargetEncoding := FIniFile.ReadString(Section, 'TargetEncoding', 'UTF-8');
  Config.AddBOM := FIniFile.ReadBool(Section, 'AddBOM', False);
  Config.IncludeSubdirs := FIniFile.ReadBool(Section, 'IncludeSubdirs', False);
  Config.LastDirectory := FIniFile.ReadString(Section, 'LastDirectory', '');
  
  // 加载文件扩展名列表
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
      // 只读取 Config_ 开头的节
      if Sections[i].StartsWith('Config_') then
      begin
        SetLength(Result, Count + 1);
        // 移除 Config_ 前缀
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
  
  // 从 INI 文件中删除
  FIniFile.EraseSection(Section);
  FIniFile.UpdateFile;
  
  // 从内存中删除
  for i := High(FSavedConfigs) downto 0 do
  begin
    if FSavedConfigs[i].Name = ConfigName then
    begin
      // 移动后面的元素
      if i < High(FSavedConfigs) then
        Move(FSavedConfigs[i + 1], FSavedConfigs[i], 
             (Length(FSavedConfigs) - i - 1) * SizeOf(TConversionConfig));
      // 减少数组大小
      SetLength(FSavedConfigs, Length(FSavedConfigs) - 1);
      Break;
    end;
  end;
end;

constructor TAppConfig.Create;
var
  IniPath: string;
begin
  inherited Create;

  // 确保INI目录存在
  IniPath := ExtractFilePath(ParamStr(0)) + 'ini';
  if not DirectoryExists(IniPath) then
    ForceDirectories(IniPath);

  // 创建INI文件
  FIniFile := TIniFile.Create(IniPath + '\DeepCharset.ini');

  // 加载设置
  FLastDirectory := FIniFile.ReadString(INI_SECTION_GENERAL, INI_KEY_LAST_DIR, '');
  FLastEncoding := FIniFile.ReadString(INI_SECTION_GENERAL, INI_KEY_LAST_ENCODING, 'UTF-8');
  FLastAddBOM := FIniFile.ReadBool(INI_SECTION_GENERAL, INI_KEY_LAST_ADD_BOM, True);
  FIncludeSubdirs := FIniFile.ReadBool(INI_SECTION_GENERAL, INI_KEY_INCLUDE_SUBDIRS, False);
  FLastLanguage := FIniFile.ReadString(INI_SECTION_GENERAL, INI_KEY_LAST_LANGUAGE, 'zh-CN');

  // 加载保存的配置
  LoadSavedConfigs;
end;

destructor TAppConfig.Destroy;
begin
  // 保存设置
  FIniFile.WriteString(INI_SECTION_GENERAL, INI_KEY_LAST_DIR, FLastDirectory);
  FIniFile.WriteString(INI_SECTION_GENERAL, INI_KEY_LAST_ENCODING, FLastEncoding);
  FIniFile.WriteBool(INI_SECTION_GENERAL, INI_KEY_LAST_ADD_BOM, FLastAddBOM);
  FIniFile.WriteBool(INI_SECTION_GENERAL, INI_KEY_INCLUDE_SUBDIRS, FIncludeSubdirs);
  FIniFile.WriteString(INI_SECTION_GENERAL, INI_KEY_LAST_LANGUAGE, FLastLanguage);

  // 保存配置列表
  SaveConfigsToIni;

  // 释放INI文件
  FIniFile.Free;

  inherited;
end;

end.