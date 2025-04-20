unit UtilsEncodingLocalization;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles, System.Generics.Collections;

type
  // 编码本地化管理类
  TEncodingLocalizationManager = class
  private
    FLanguageCode: string;
    FLanguagePath: string;
    FCategoryTranslations: TDictionary<string, string>;
    FEncodingTranslations: TDictionary<string, string>;

    class var FInstance: TEncodingLocalizationManager;

    constructor Create;
    procedure LoadTranslations;
    procedure ClearTranslations;

  public
    destructor Destroy; override;
    class function GetInstance: TEncodingLocalizationManager;
    class procedure ReleaseInstance;

    // 设置当前语言
    procedure SetLanguage(const LanguageCode: string);

    // 设置语言文件路径
    procedure SetLanguagePath(const Path: string);

    // 获取编码分类的本地化名称
    function GetLocalizedCategoryName(const CategoryName: string): string;

    // 获取编码的本地化名称
    function GetLocalizedEncodingName(const EncodingKey: string): string;

    // 重新加载翻译
    procedure ReloadTranslations;

    // 属性
    property LanguageCode: string read FLanguageCode;
    property LanguagePath: string read FLanguagePath write SetLanguagePath;
  end;

implementation

{ TEncodingLocalizationManager }

constructor TEncodingLocalizationManager.Create;
begin
  inherited Create;
  FCategoryTranslations := TDictionary<string, string>.Create;
  FEncodingTranslations := TDictionary<string, string>.Create;
  FLanguageCode := 'en-US'; // 默认语言
  FLanguagePath := ExtractFilePath(ParamStr(0)) + 'ini';

  // 加载默认语言的翻译
  LoadTranslations;
end;

destructor TEncodingLocalizationManager.Destroy;
begin
  FCategoryTranslations.Free;
  FEncodingTranslations.Free;
  inherited;
end;

class function TEncodingLocalizationManager.GetInstance: TEncodingLocalizationManager;
begin
  if FInstance = nil then
    FInstance := TEncodingLocalizationManager.Create;
  Result := FInstance;
end;

class procedure TEncodingLocalizationManager.ReleaseInstance;
begin
  if FInstance <> nil then
  begin
    FInstance.Free;
    FInstance := nil;
  end;
end;

procedure TEncodingLocalizationManager.ClearTranslations;
begin
  FCategoryTranslations.Clear;
  FEncodingTranslations.Clear;
end;

procedure TEncodingLocalizationManager.LoadTranslations;
var
  IniFile: TIniFile;
  LanguageFilePath: string;
  Sections, Keys: TStringList;
  i, j: Integer;
  Section, Key, Value: string;
begin
  // 清除现有翻译
  ClearTranslations;

  // 构建语言文件路径
  LanguageFilePath := IncludeTrailingPathDelimiter(FLanguagePath) + FLanguageCode + '.ini';

  // 如果文件不存在，尝试使用默认语言
  if not FileExists(LanguageFilePath) then
  begin
    LanguageFilePath := IncludeTrailingPathDelimiter(FLanguagePath) + 'en-US.ini';

    // 如果默认语言文件也不存在，则退出
    if not FileExists(LanguageFilePath) then
      Exit;
  end;

  // 加载INI文件
  IniFile := TIniFile.Create(LanguageFilePath);
  Sections := TStringList.Create;
  Keys := TStringList.Create;

  try
    // 读取[Encodings]部分
    IniFile.ReadSection('Encodings', Keys);

    // 处理编码分类
    for i := 0 to Keys.Count - 1 do
    begin
      Key := Keys[i];
      Value := IniFile.ReadString('Encodings', Key, Key);

      // 检查是否为分类名称（不包含下划线的键通常是分类）
      if Pos('_', Key) = 0 then
        FCategoryTranslations.AddOrSetValue(Key, Value)
      else
        FEncodingTranslations.AddOrSetValue(Key, Value);
    end;
  finally
    Keys.Free;
    Sections.Free;
    IniFile.Free;
  end;
end;

procedure TEncodingLocalizationManager.ReloadTranslations;
begin
  LoadTranslations;
end;

procedure TEncodingLocalizationManager.SetLanguage(const LanguageCode: string);
begin
  if FLanguageCode <> LanguageCode then
  begin
    FLanguageCode := LanguageCode;
    LoadTranslations;
  end;
end;

procedure TEncodingLocalizationManager.SetLanguagePath(const Path: string);
begin
  if FLanguagePath <> Path then
  begin
    FLanguagePath := Path;
    LoadTranslations;
  end;
end;

function TEncodingLocalizationManager.GetLocalizedCategoryName(const CategoryName: string): string;
begin
  // 尝试获取本地化的分类名称
  if FCategoryTranslations.TryGetValue(CategoryName, Result) then
    Exit;

  // 如果找不到，返回原始名称
  Result := CategoryName;
end;

function TEncodingLocalizationManager.GetLocalizedEncodingName(const EncodingKey: string): string;
begin
  // 尝试获取本地化的编码名称
  if FEncodingTranslations.TryGetValue(EncodingKey, Result) then
    Exit;

  // 如果找不到，返回原始名称
  Result := EncodingKey;
end;

initialization
  TEncodingLocalizationManager.FInstance := nil;

finalization
  TEncodingLocalizationManager.ReleaseInstance;

end.
