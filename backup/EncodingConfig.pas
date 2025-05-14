unit EncodingConfig;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles, System.Generics.Collections,
  System.JSON, System.IOUtils, EncodingLogger;

type
  /// <summary>
  /// 编码转换配置选项
  /// </summary>
  TEncodingConfigOptions = class
  private
    FDefaultSourceEncoding: string;
    FDefaultTargetEncoding: string;
    FPreserveBOM: Boolean;
    FBackupFiles: Boolean;
    FBackupFolder: string;
    FOverwriteExisting: Boolean;
    FVerboseLogging: Boolean;
    FRecursiveFolderScan: Boolean;
    FMaxThreadCount: Integer;
    FMaxFileSizeInMB: Integer;
    FFileFilters: TStringList;
    FExcludeFolders: TStringList;
  public
    constructor Create;
    destructor Destroy; override;

    property DefaultSourceEncoding: string read FDefaultSourceEncoding write FDefaultSourceEncoding;
    property DefaultTargetEncoding: string read FDefaultTargetEncoding write FDefaultTargetEncoding;
    property PreserveBOM: Boolean read FPreserveBOM write FPreserveBOM;
    property BackupFiles: Boolean read FBackupFiles write FBackupFiles;
    property BackupFolder: string read FBackupFolder write FBackupFolder;
    property OverwriteExisting: Boolean read FOverwriteExisting write FOverwriteExisting;
    property VerboseLogging: Boolean read FVerboseLogging write FVerboseLogging;
    property RecursiveFolderScan: Boolean read FRecursiveFolderScan write FRecursiveFolderScan;
    property MaxThreadCount: Integer read FMaxThreadCount write FMaxThreadCount;
    property MaxFileSizeInMB: Integer read FMaxFileSizeInMB write FMaxFileSizeInMB;
    property FileFilters: TStringList read FFileFilters;
    property ExcludeFolders: TStringList read FExcludeFolders;

    procedure Reset;
  end;

  /// <summary>
  /// 编码转换配置文件的保存和加载操作接口
  /// </summary>
  IConfigStorage = interface
    ['{E8A2D9F1-492B-4D7A-9C3A-D5B6B1EF7BAE}']
    function Load(const AFileName: string; AOptions: TEncodingConfigOptions): Boolean;
    function Save(const AFileName: string; AOptions: TEncodingConfigOptions): Boolean;
  end;

  /// <summary>
  /// INI格式的配置存储实现
  /// </summary>
  TIniConfigStorage = class(TInterfacedObject, IConfigStorage)
  private
    FLogger: ILogger;
  public
    constructor Create(ALogger: ILogger = nil);
    function Load(const AFileName: string; AOptions: TEncodingConfigOptions): Boolean;
    function Save(const AFileName: string; AOptions: TEncodingConfigOptions): Boolean;
  end;

  /// <summary>
  /// JSON格式的配置存储实现
  /// </summary>
  TJsonConfigStorage = class(TInterfacedObject, IConfigStorage)
  private
    FLogger: ILogger;
  public
    constructor Create(ALogger: ILogger = nil);
    function Load(const AFileName: string; AOptions: TEncodingConfigOptions): Boolean;
    function Save(const AFileName: string; AOptions: TEncodingConfigOptions): Boolean;
  end;

  /// <summary>
  /// 编码转换配置管理器
  /// </summary>
  TEncodingConfig = class
  private
    FOptions: TEncodingConfigOptions;
    FStorage: IConfigStorage;
    FConfigFileName: string;
    FLogger: ILogger;
    class var FInstance: TEncodingConfig;
    class constructor Create;
    class destructor Destroy;
  public
    constructor Create(AStorage: IConfigStorage; const AConfigFileName: string = ''; ALogger: ILogger = nil);
    destructor Destroy; override;

    function LoadConfig: Boolean;
    function SaveConfig: Boolean;
    procedure ResetToDefaults;

    property Options: TEncodingConfigOptions read FOptions;
    property ConfigFileName: string read FConfigFileName write FConfigFileName;

    class property Instance: TEncodingConfig read FInstance;
  end;

implementation

{ TEncodingConfigOptions }

constructor TEncodingConfigOptions.Create;
begin
  inherited Create;
  FFileFilters := TStringList.Create;
  FExcludeFolders := TStringList.Create;
  Reset;
end;

destructor TEncodingConfigOptions.Destroy;
begin
  FFileFilters.Free;
  FExcludeFolders.Free;
  inherited;
end;

procedure TEncodingConfigOptions.Reset;
begin
  FDefaultSourceEncoding := 'auto';
  FDefaultTargetEncoding := 'UTF-8';
  FPreserveBOM := True;
  FBackupFiles := True;
  FBackupFolder := '';
  FOverwriteExisting := False;
  FVerboseLogging := False;
  FRecursiveFolderScan := True;
  FMaxThreadCount := 4;
  FMaxFileSizeInMB := 50;

  FFileFilters.Clear;
  FFileFilters.Add('*.txt');
  FFileFilters.Add('*.csv');
  FFileFilters.Add('*.xml');
  FFileFilters.Add('*.html');
  FFileFilters.Add('*.htm');
  FFileFilters.Add('*.json');
  FFileFilters.Add('*.pas');
  FFileFilters.Add('*.dpr');
  FFileFilters.Add('*.cpp');
  FFileFilters.Add('*.c');
  FFileFilters.Add('*.h');
  FFileFilters.Add('*.cs');
  FFileFilters.Add('*.js');
  FFileFilters.Add('*.ts');
  FFileFilters.Add('*.php');

  FExcludeFolders.Clear;
  FExcludeFolders.Add('.git');
  FExcludeFolders.Add('.svn');
  FExcludeFolders.Add('node_modules');
  FExcludeFolders.Add('bin');
  FExcludeFolders.Add('obj');
end;

{ TIniConfigStorage }

constructor TIniConfigStorage.Create(ALogger: ILogger);
begin
  inherited Create;
  if Assigned(ALogger) then
    FLogger := ALogger
  else
    FLogger := EncodingLogger.Logger;
end;

function TIniConfigStorage.Load(const AFileName: string; AOptions: TEncodingConfigOptions): Boolean;
var
  IniFile: TIniFile;
  I: Integer;
  TempList: TStringList;
  Count: Integer;
begin
  Result := False;
  if (AFileName = '') or (not Assigned(AOptions)) then
    Exit;

  if not FileExists(AFileName) then
  begin
    FLogger.Warning('配置文件不存在: %s', [AFileName]);
    Exit;
  end;

  try
    IniFile := TIniFile.Create(AFileName);
    try
      AOptions.DefaultSourceEncoding := IniFile.ReadString('Encoding', 'DefaultSourceEncoding', AOptions.DefaultSourceEncoding);
      AOptions.DefaultTargetEncoding := IniFile.ReadString('Encoding', 'DefaultTargetEncoding', AOptions.DefaultTargetEncoding);
      AOptions.PreserveBOM := IniFile.ReadBool('Encoding', 'PreserveBOM', AOptions.PreserveBOM);
      AOptions.BackupFiles := IniFile.ReadBool('Files', 'BackupFiles', AOptions.BackupFiles);
      AOptions.BackupFolder := IniFile.ReadString('Files', 'BackupFolder', AOptions.BackupFolder);
      AOptions.OverwriteExisting := IniFile.ReadBool('Files', 'OverwriteExisting', AOptions.OverwriteExisting);
      AOptions.VerboseLogging := IniFile.ReadBool('Debug', 'VerboseLogging', AOptions.VerboseLogging);
      AOptions.RecursiveFolderScan := IniFile.ReadBool('Files', 'RecursiveFolderScan', AOptions.RecursiveFolderScan);
      AOptions.MaxThreadCount := IniFile.ReadInteger('Performance', 'MaxThreadCount', AOptions.MaxThreadCount);
      AOptions.MaxFileSizeInMB := IniFile.ReadInteger('Files', 'MaxFileSizeInMB', AOptions.MaxFileSizeInMB);

      // 读取文件过滤器
      Count := IniFile.ReadInteger('FileFilters', 'Count', 0);
      if Count > 0 then
      begin
        AOptions.FileFilters.Clear;
        for I := 0 to Count - 1 do
          AOptions.FileFilters.Add(IniFile.ReadString('FileFilters', 'Filter' + IntToStr(I), ''));
      end;

      // 读取排除文件夹
      Count := IniFile.ReadInteger('ExcludeFolders', 'Count', 0);
      if Count > 0 then
      begin
        AOptions.ExcludeFolders.Clear;
        for I := 0 to Count - 1 do
          AOptions.ExcludeFolders.Add(IniFile.ReadString('ExcludeFolders', 'Folder' + IntToStr(I), ''));
      end;

      Result := True;
      FLogger.Info('成功从INI文件加载配置: %s', [AFileName]);
    finally
      IniFile.Free;
    end;
  except
    on E: Exception do
    begin
      FLogger.Error('从INI文件加载配置时出错: %s - %s', [AFileName, E.Message]);
      Result := False;
    end;
  end;
end;

function TIniConfigStorage.Save(const AFileName: string; AOptions: TEncodingConfigOptions): Boolean;
var
  IniFile: TIniFile;
  I: Integer;
begin
  Result := False;
  if (AFileName = '') or (not Assigned(AOptions)) then
    Exit;

  try
    IniFile := TIniFile.Create(AFileName);
    try
      IniFile.WriteString('Encoding', 'DefaultSourceEncoding', AOptions.DefaultSourceEncoding);
      IniFile.WriteString('Encoding', 'DefaultTargetEncoding', AOptions.DefaultTargetEncoding);
      IniFile.WriteBool('Encoding', 'PreserveBOM', AOptions.PreserveBOM);
      IniFile.WriteBool('Files', 'BackupFiles', AOptions.BackupFiles);
      IniFile.WriteString('Files', 'BackupFolder', AOptions.BackupFolder);
      IniFile.WriteBool('Files', 'OverwriteExisting', AOptions.OverwriteExisting);
      IniFile.WriteBool('Debug', 'VerboseLogging', AOptions.VerboseLogging);
      IniFile.WriteBool('Files', 'RecursiveFolderScan', AOptions.RecursiveFolderScan);
      IniFile.WriteInteger('Performance', 'MaxThreadCount', AOptions.MaxThreadCount);
      IniFile.WriteInteger('Files', 'MaxFileSizeInMB', AOptions.MaxFileSizeInMB);

      // 写入文件过滤器
      IniFile.WriteInteger('FileFilters', 'Count', AOptions.FileFilters.Count);
      for I := 0 to AOptions.FileFilters.Count - 1 do
        IniFile.WriteString('FileFilters', 'Filter' + IntToStr(I), AOptions.FileFilters[I]);

      // 写入排除文件夹
      IniFile.WriteInteger('ExcludeFolders', 'Count', AOptions.ExcludeFolders.Count);
      for I := 0 to AOptions.ExcludeFolders.Count - 1 do
        IniFile.WriteString('ExcludeFolders', 'Folder' + IntToStr(I), AOptions.ExcludeFolders[I]);

      Result := True;
      FLogger.Info('成功保存配置到INI文件: %s', [AFileName]);
    finally
      IniFile.Free;
    end;
  except
    on E: Exception do
    begin
      FLogger.Error('保存配置到INI文件时出错: %s - %s', [AFileName, E.Message]);
      Result := False;
    end;
  end;
end;

{ TJsonConfigStorage }

constructor TJsonConfigStorage.Create(ALogger: ILogger);
begin
  inherited Create;
  if Assigned(ALogger) then
    FLogger := ALogger
  else
    FLogger := EncodingLogger.Logger;
end;

function TJsonConfigStorage.Load(const AFileName: string; AOptions: TEncodingConfigOptions): Boolean;
var
  JsonText: string;
  JsonObj, JsonFilters, JsonFolders: TJSONObject;
  JsonArray: TJSONArray;
  I: Integer;
begin
  Result := False;
  if (AFileName = '') or (not Assigned(AOptions)) then
    Exit;

  if not FileExists(AFileName) then
  begin
    FLogger.Warning('配置文件不存在: %s', [AFileName]);
    Exit;
  end;

  try
    JsonText := TFile.ReadAllText(AFileName);
    JsonObj := TJSONObject.ParseJSONValue(JsonText) as TJSONObject;

    if not Assigned(JsonObj) then
    begin
      FLogger.Error('无效的JSON文件格式: %s', [AFileName]);
      Exit;
    end;

    try
      // 基本配置
      var TempStr: string;
      var TempBool: Boolean;
      var TempInt: Integer;

      if JsonObj.TryGetValue<string>('defaultSourceEncoding', TempStr) then
        AOptions.FDefaultSourceEncoding := TempStr;
      if JsonObj.TryGetValue<string>('defaultTargetEncoding', TempStr) then
        AOptions.FDefaultTargetEncoding := TempStr;
      if JsonObj.TryGetValue<Boolean>('preserveBOM', TempBool) then
        AOptions.FPreserveBOM := TempBool;
      if JsonObj.TryGetValue<Boolean>('backupFiles', TempBool) then
        AOptions.FBackupFiles := TempBool;
      if JsonObj.TryGetValue<string>('backupFolder', TempStr) then
        AOptions.FBackupFolder := TempStr;
      if JsonObj.TryGetValue<Boolean>('overwriteExisting', TempBool) then
        AOptions.FOverwriteExisting := TempBool;
      if JsonObj.TryGetValue<Boolean>('verboseLogging', TempBool) then
        AOptions.FVerboseLogging := TempBool;
      if JsonObj.TryGetValue<Boolean>('recursiveFolderScan', TempBool) then
        AOptions.FRecursiveFolderScan := TempBool;
      if JsonObj.TryGetValue<Integer>('maxThreadCount', TempInt) then
        AOptions.FMaxThreadCount := TempInt;
      if JsonObj.TryGetValue<Integer>('maxFileSizeInMB', TempInt) then
        AOptions.FMaxFileSizeInMB := TempInt;

      // 文件过滤器
      if JsonObj.TryGetValue<TJSONArray>('fileFilters', JsonArray) then
      begin
        AOptions.FileFilters.Clear;
        for I := 0 to JsonArray.Count - 1 do
          AOptions.FileFilters.Add(JsonArray.Items[I].Value);
      end;

      // 排除文件夹
      if JsonObj.TryGetValue<TJSONArray>('excludeFolders', JsonArray) then
      begin
        AOptions.ExcludeFolders.Clear;
        for I := 0 to JsonArray.Count - 1 do
          AOptions.ExcludeFolders.Add(JsonArray.Items[I].Value);
      end;

      Result := True;
      FLogger.Info('成功从JSON文件加载配置: %s', [AFileName]);
    finally
      JsonObj.Free;
    end;
  except
    on E: Exception do
    begin
      FLogger.Error('从JSON文件加载配置时出错: %s - %s', [AFileName, E.Message]);
      Result := False;
    end;
  end;
end;

function TJsonConfigStorage.Save(const AFileName: string; AOptions: TEncodingConfigOptions): Boolean;
var
  JsonObj: TJSONObject;
  JsonArray: TJSONArray;
  I: Integer;
  JsonText: string;
begin
  Result := False;
  if (AFileName = '') or (not Assigned(AOptions)) then
    Exit;

  try
    JsonObj := TJSONObject.Create;
    try
      // 基本配置
      JsonObj.AddPair('defaultSourceEncoding', AOptions.DefaultSourceEncoding);
      JsonObj.AddPair('defaultTargetEncoding', AOptions.DefaultTargetEncoding);
      JsonObj.AddPair('preserveBOM', TJSONBool.Create(AOptions.PreserveBOM));
      JsonObj.AddPair('backupFiles', TJSONBool.Create(AOptions.BackupFiles));
      JsonObj.AddPair('backupFolder', AOptions.BackupFolder);
      JsonObj.AddPair('overwriteExisting', TJSONBool.Create(AOptions.OverwriteExisting));
      JsonObj.AddPair('verboseLogging', TJSONBool.Create(AOptions.VerboseLogging));
      JsonObj.AddPair('recursiveFolderScan', TJSONBool.Create(AOptions.RecursiveFolderScan));
      JsonObj.AddPair('maxThreadCount', TJSONNumber.Create(AOptions.MaxThreadCount));
      JsonObj.AddPair('maxFileSizeInMB', TJSONNumber.Create(AOptions.MaxFileSizeInMB));

      // 文件过滤器
      JsonArray := TJSONArray.Create;
      for I := 0 to AOptions.FileFilters.Count - 1 do
        JsonArray.Add(AOptions.FileFilters[I]);
      JsonObj.AddPair('fileFilters', JsonArray);

      // 排除文件夹
      JsonArray := TJSONArray.Create;
      for I := 0 to AOptions.ExcludeFolders.Count - 1 do
        JsonArray.Add(AOptions.ExcludeFolders[I]);
      JsonObj.AddPair('excludeFolders', JsonArray);

      // 保存到文件
      JsonText := JsonObj.Format;
      TFile.WriteAllText(AFileName, JsonText);

      Result := True;
      FLogger.Info('成功保存配置到JSON文件: %s', [AFileName]);
    finally
      JsonObj.Free;
    end;
  except
    on E: Exception do
    begin
      FLogger.Error('保存配置到JSON文件时出错: %s - %s', [AFileName, E.Message]);
      Result := False;
    end;
  end;
end;

{ TEncodingConfig }

class constructor TEncodingConfig.Create;
begin
  FInstance := TEncodingConfig.Create(TIniConfigStorage.Create, 'encoding_config.ini');
end;

class destructor TEncodingConfig.Destroy;
begin
  FInstance.Free;
end;

constructor TEncodingConfig.Create(AStorage: IConfigStorage; const AConfigFileName: string; ALogger: ILogger);
begin
  inherited Create;
  FOptions := TEncodingConfigOptions.Create;
  FStorage := AStorage;
  FConfigFileName := AConfigFileName;

  if Assigned(ALogger) then
    FLogger := ALogger
  else
    FLogger := EncodingLogger.Logger;
end;

destructor TEncodingConfig.Destroy;
begin
  FOptions.Free;
  inherited;
end;

function TEncodingConfig.LoadConfig: Boolean;
begin
  if FConfigFileName = '' then
  begin
    FLogger.Warning('配置文件名为空，无法加载配置');
    Result := False;
    Exit;
  end;

  Result := FStorage.Load(FConfigFileName, FOptions);
end;

procedure TEncodingConfig.ResetToDefaults;
begin
  FOptions.Reset;
  FLogger.Info('已重置配置选项为默认值');
end;

function TEncodingConfig.SaveConfig: Boolean;
begin
  if FConfigFileName = '' then
  begin
    FLogger.Warning('配置文件名为空，无法保存配置');
    Result := False;
    Exit;
  end;

  Result := FStorage.Save(FConfigFileName, FOptions);
end;

end.