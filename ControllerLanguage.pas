unit ControllerLanguage;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.IniFiles,
  System.IOUtils, Winapi.Windows, Vcl.Forms, ModelLanguage, HelperLanguage;

// 获取语言列表
function GetLanguageList: TArray<TLanguageInfo>;

// 获取语言字符串
function GetLanguageStrings(const LangCode: string): TLanguageStrings;

// 设置语言
procedure SetLanguage(const LangCode: string);

// 获取语言名称
function GetLanguageNameByCode(const LangCode: string): string;

// 获取语言信息
function GetLanguageInfo(const LangCode: string): TLanguageInfo;

// 获取当前语言
function GetCurrentLanguage: string;

// 初始化语言管理器
procedure InitializeLanguageManager;

implementation

function GetLanguageList: TArray<TLanguageInfo>;
begin
  Result := HelperLanguage.LanguageManager.GetLanguageList;
end;

function GetLanguageStrings(const LangCode: string): TLanguageStrings;
begin
  Result := HelperLanguage.LanguageManager.GetLanguageStrings(LangCode);
end;

procedure SetLanguage(const LangCode: string);
begin
  HelperLanguage.LanguageManager.SetLanguage(LangCode);
end;

function GetLanguageNameByCode(const LangCode: string): string;
begin
  Result := HelperLanguage.LanguageManager.GetLanguageNameByCode(LangCode);
end;

function GetLanguageInfo(const LangCode: string): TLanguageInfo;
begin
  Result := HelperLanguage.LanguageManager.GetLanguageInfo(LangCode);
end;

function GetCurrentLanguage: string;
begin
  Result := HelperLanguage.LanguageManager.CurrentLanguage;
end;

procedure InitializeLanguageManager;
begin
  if not Assigned(HelperLanguage.LanguageManager) then
    HelperLanguage.LanguageManager := HelperLanguage.TLanguageManager.Create;
  
  HelperLanguage.LanguageManager.Initialize;
end;

end.
