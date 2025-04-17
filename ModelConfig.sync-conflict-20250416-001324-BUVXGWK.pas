unit ModelConfig;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles, Winapi.Windows, Winapi.Messages;

type
  // 应用程序配置模型
  TAppConfig = class
  private
    FConfigPath: string;
    FLastDirectory: string;
    FDefaultEncoding: Integer;
    FAddBOM: Boolean;
    
    procedure LoadConfig;
    procedure SaveConfig;
  public
    constructor Create;
    destructor Destroy; override;
    
    // 保存最后使用的目录
    procedure SetLastDirectory(const Directory: string);
    
    // 配置属性
    property LastDirectory: string read FLastDirectory write SetLastDirectory;
    property DefaultEncoding: Integer read FDefaultEncoding write FDefaultEncoding;
    property AddBOM: Boolean read FAddBOM write FAddBOM;
  end;
  
implementation

{ TAppConfig }

constructor TAppConfig.Create;
begin
  inherited Create;
  FConfigPath := ChangeFileExt(ParamStr(0), '.ini');
  FLastDirectory := '';
  FDefaultEncoding := 65001; // UTF-8
  FAddBOM := True; // 总是添加BOM
  
  LoadConfig;
  
  // 强制设置为UTF-8+BOM，无论配置文件中的设置如何
  FDefaultEncoding := 65001; // UTF-8
  FAddBOM := True;
  
  // 保存新设置到配置文件
  SaveConfig;
end;

destructor TAppConfig.Destroy;
begin
  SaveConfig;
  inherited;
end;

procedure TAppConfig.LoadConfig;
var
  IniFile: TMemIniFile;
begin
  if FileExists(FConfigPath) then
  begin
    IniFile := TMemIniFile.Create(FConfigPath, TEncoding.UTF8);
    try
      FLastDirectory := IniFile.ReadString('Settings', 'LastDirectory', '');
      FDefaultEncoding := IniFile.ReadInteger('Settings', 'DefaultEncoding', 65001);
      FAddBOM := IniFile.ReadBool('Settings', 'AddBOM', True);
    finally
      IniFile.Free;
    end;
  end;
end;

procedure TAppConfig.SaveConfig;
var
  IniFile: TMemIniFile;
begin
  IniFile := TMemIniFile.Create(FConfigPath, TEncoding.UTF8);
  try
    IniFile.WriteString('Settings', 'LastDirectory', FLastDirectory);
    IniFile.WriteInteger('Settings', 'DefaultEncoding', FDefaultEncoding);
    IniFile.WriteBool('Settings', 'AddBOM', FAddBOM);
    IniFile.UpdateFile;
  finally
    IniFile.Free;
  end;
end;

procedure TAppConfig.SetLastDirectory(const Directory: string);
begin
  if Directory <> FLastDirectory then
  begin
    FLastDirectory := Directory;
    SaveConfig;
  end;
end;

end. 