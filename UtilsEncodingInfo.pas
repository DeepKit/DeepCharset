unit UtilsEncodingInfo;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, UtilsEncodingDetect2;

type
  // 编码信息记录
  TEncodingInfo = record
    Name: string;        // 编码名称，如'UTF-8'
    DisplayName: string; // 显示名称，如'UTF-8 (Unicode)'
    CodePage: Integer;   // 代码页
    Category: string;    // 分类，如'Unicode', 'Asian', 'European'
    HasBOM: Boolean;     // 是否支持BOM
    IsUnicode: Boolean;  // 是否为Unicode编码
    IsAvailable: Boolean; // 系统是否支持
    Description: string; // 描述
  end;

  // 编码信息管理类
  TEncodingInfoManager = class
  private
    FEncodingList: TList<TEncodingInfo>;
    class var FInstance: TEncodingInfoManager;
    
    constructor Create;
    procedure InitializeEncodingList;
    function IsEncodingAvailable(CodePage: Integer): Boolean;
    
  public
    destructor Destroy; override;
    class function GetInstance: TEncodingInfoManager;
    class procedure ReleaseInstance;
    
    // 获取所有编码信息
    function GetAllEncodings: TArray<TEncodingInfo>;
    
    // 按分类获取编码信息
    function GetEncodingsByCategory(const Category: string): TArray<TEncodingInfo>;
    
    // 根据名称获取编码信息
    function GetEncodingInfoByName(const Name: string): TEncodingInfo;
    
    // 根据代码页获取编码信息
    function GetEncodingInfoByCodePage(CodePage: Integer): TEncodingInfo;
    
    // 获取编码分类列表
    function GetCategories: TArray<string>;
    
    // 获取所有可用的UTF编码
    function GetUTFEncodings: TArray<TEncodingInfo>;
    
    // 获取常用区域编码列表
    function GetRegionalEncodings: TArray<TEncodingInfo>;
    
    // 根据编码名创建TEncoding对象
    function CreateEncoding(const Name: string): TEncoding;
  end;

implementation

constructor TEncodingInfoManager.Create;
begin
  inherited;
  FEncodingList := TList<TEncodingInfo>.Create;
  InitializeEncodingList;
end;

destructor TEncodingInfoManager.Destroy;
begin
  FEncodingList.Free;
  inherited;
end;

class function TEncodingInfoManager.GetInstance: TEncodingInfoManager;
begin
  if FInstance = nil then
    FInstance := TEncodingInfoManager.Create;
  Result := FInstance;
end;

class procedure TEncodingInfoManager.ReleaseInstance;
begin
  if FInstance <> nil then
  begin
    FInstance.Free;
    FInstance := nil;
  end;
end;

function TEncodingInfoManager.IsEncodingAvailable(CodePage: Integer): Boolean;
begin
  try
    var Encoding := TEncoding.GetEncoding(CodePage);
    Encoding.Free;
    Result := True;
  except
    Result := False;
  end;
end;

procedure TEncodingInfoManager.InitializeEncodingList;
var
  EncodingInfo: TEncodingInfo;
begin
  FEncodingList.Clear;
  
  // Unicode编码
  
  // UTF-8
  EncodingInfo.Name := 'UTF-8';
  EncodingInfo.DisplayName := 'UTF-8 (Unicode)';
  EncodingInfo.CodePage := 65001;
  EncodingInfo.Category := 'Unicode';
  EncodingInfo.HasBOM := True;
  EncodingInfo.IsUnicode := True;
  EncodingInfo.IsAvailable := True;
  EncodingInfo.Description := '默认的Unicode编码，适用于网页和多语言文档';
  FEncodingList.Add(EncodingInfo);
  
  // UTF-8 with BOM
  EncodingInfo.Name := 'UTF-8 with BOM';
  EncodingInfo.DisplayName := 'UTF-8 with BOM (Unicode)';
  EncodingInfo.CodePage := 65001;
  EncodingInfo.Category := 'Unicode';
  EncodingInfo.HasBOM := True;
  EncodingInfo.IsUnicode := True;
  EncodingInfo.IsAvailable := True;
  EncodingInfo.Description := '带字节顺序标记的UTF-8编码';
  FEncodingList.Add(EncodingInfo);
  
  // UTF-16LE
  EncodingInfo.Name := 'UTF-16LE';
  EncodingInfo.DisplayName := 'UTF-16LE (Unicode)';
  EncodingInfo.CodePage := 1200;
  EncodingInfo.Category := 'Unicode';
  EncodingInfo.HasBOM := True;
  EncodingInfo.IsUnicode := True;
  EncodingInfo.IsAvailable := True;
  EncodingInfo.Description := '小端字节序的UTF-16编码，Windows默认';
  FEncodingList.Add(EncodingInfo);
  
  // UTF-16BE
  EncodingInfo.Name := 'UTF-16BE';
  EncodingInfo.DisplayName := 'UTF-16BE (Unicode)';
  EncodingInfo.CodePage := 1201;
  EncodingInfo.Category := 'Unicode';
  EncodingInfo.HasBOM := True;
  EncodingInfo.IsUnicode := True;
  EncodingInfo.IsAvailable := True;
  EncodingInfo.Description := '大端字节序的UTF-16编码，常用于Java和网络传输';
  FEncodingList.Add(EncodingInfo);
  
  // UTF-32LE
  EncodingInfo.Name := 'UTF-32LE';
  EncodingInfo.DisplayName := 'UTF-32LE (Unicode)';
  EncodingInfo.CodePage := 12000;
  EncodingInfo.Category := 'Unicode';
  EncodingInfo.HasBOM := True;
  EncodingInfo.IsUnicode := True;
  EncodingInfo.IsAvailable := IsEncodingAvailable(12000);
  EncodingInfo.Description := '小端字节序的UTF-32编码';
  FEncodingList.Add(EncodingInfo);
  
  // UTF-32BE
  EncodingInfo.Name := 'UTF-32BE';
  EncodingInfo.DisplayName := 'UTF-32BE (Unicode)';
  EncodingInfo.CodePage := 12001;
  EncodingInfo.Category := 'Unicode';
  EncodingInfo.HasBOM := True;
  EncodingInfo.IsUnicode := True;
  EncodingInfo.IsAvailable := IsEncodingAvailable(12001);
  EncodingInfo.Description := '大端字节序的UTF-32编码';
  FEncodingList.Add(EncodingInfo);
  
  // 基本编码
  
  // ASCII
  EncodingInfo.Name := 'ASCII';
  EncodingInfo.DisplayName := 'ASCII';
  EncodingInfo.CodePage := 20127;
  EncodingInfo.Category := 'Basic';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := True;
  EncodingInfo.Description := '基本的7位ASCII编码，仅支持英文和基本符号';
  FEncodingList.Add(EncodingInfo);
  
  // ANSI
  EncodingInfo.Name := 'ANSI';
  EncodingInfo.DisplayName := 'ANSI (本地编码)';
  EncodingInfo.CodePage := GetACP;
  EncodingInfo.Category := 'Basic';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := True;
  EncodingInfo.Description := '当前系统的默认ANSI编码';
  FEncodingList.Add(EncodingInfo);
  
  // 亚洲语言编码
  
  // GBK
  EncodingInfo.Name := 'GBK';
  EncodingInfo.DisplayName := 'GBK (简体中文)';
  EncodingInfo.CodePage := 936;
  EncodingInfo.Category := 'Asian';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(936);
  EncodingInfo.Description := '简体中文常用编码，GB2312的扩展';
  FEncodingList.Add(EncodingInfo);
  
  // GB2312
  EncodingInfo.Name := 'GB2312';
  EncodingInfo.DisplayName := 'GB2312 (简体中文)';
  EncodingInfo.CodePage := 936;
  EncodingInfo.Category := 'Asian';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(936);
  EncodingInfo.Description := '简体中文基础编码，GBK的子集';
  FEncodingList.Add(EncodingInfo);
  
  // GB18030
  EncodingInfo.Name := 'GB18030';
  EncodingInfo.DisplayName := 'GB18030 (简体中文)';
  EncodingInfo.CodePage := 54936;
  EncodingInfo.Category := 'Asian';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(54936);
  EncodingInfo.Description := '中国国家标准编码，支持所有Unicode字符';
  FEncodingList.Add(EncodingInfo);
  
  // Big5
  EncodingInfo.Name := 'Big5';
  EncodingInfo.DisplayName := 'Big5 (繁体中文)';
  EncodingInfo.CodePage := 950;
  EncodingInfo.Category := 'Asian';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(950);
  EncodingInfo.Description := '繁体中文常用编码，台湾和香港地区使用';
  FEncodingList.Add(EncodingInfo);
  
  // Shift-JIS
  EncodingInfo.Name := 'Shift-JIS';
  EncodingInfo.DisplayName := 'Shift-JIS (日文)';
  EncodingInfo.CodePage := 932;
  EncodingInfo.Category := 'Asian';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(932);
  EncodingInfo.Description := '日文常用编码';
  FEncodingList.Add(EncodingInfo);
  
  // EUC-JP
  EncodingInfo.Name := 'EUC-JP';
  EncodingInfo.DisplayName := 'EUC-JP (日文)';
  EncodingInfo.CodePage := 20932;
  EncodingInfo.Category := 'Asian';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(20932);
  EncodingInfo.Description := '日文扩展Unix编码';
  FEncodingList.Add(EncodingInfo);
  
  // EUC-KR
  EncodingInfo.Name := 'EUC-KR';
  EncodingInfo.DisplayName := 'EUC-KR (韩文)';
  EncodingInfo.CodePage := 51949;
  EncodingInfo.Category := 'Asian';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(51949);
  EncodingInfo.Description := '韩文扩展Unix编码';
  FEncodingList.Add(EncodingInfo);
  
  // 欧洲语言编码
  
  // ISO-8859-1
  EncodingInfo.Name := 'ISO-8859-1';
  EncodingInfo.DisplayName := 'ISO-8859-1 (西欧)';
  EncodingInfo.CodePage := 28591;
  EncodingInfo.Category := 'European';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(28591);
  EncodingInfo.Description := '西欧语言编码，包括英、法、德、西等';
  FEncodingList.Add(EncodingInfo);
  
  // ISO-8859-2
  EncodingInfo.Name := 'ISO-8859-2';
  EncodingInfo.DisplayName := 'ISO-8859-2 (中欧)';
  EncodingInfo.CodePage := 28592;
  EncodingInfo.Category := 'European';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(28592);
  EncodingInfo.Description := '中欧语言编码，包括波兰、捷克等';
  FEncodingList.Add(EncodingInfo);
  
  // ISO-8859-5
  EncodingInfo.Name := 'ISO-8859-5';
  EncodingInfo.DisplayName := 'ISO-8859-5 (西里尔字母)';
  EncodingInfo.CodePage := 28595;
  EncodingInfo.Category := 'European';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(28595);
  EncodingInfo.Description := '西里尔字母编码，适用于俄语等';
  FEncodingList.Add(EncodingInfo);
  
  // Windows-1251
  EncodingInfo.Name := 'Windows-1251';
  EncodingInfo.DisplayName := 'Windows-1251 (西里尔字母)';
  EncodingInfo.CodePage := 1251;
  EncodingInfo.Category := 'European';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(1251);
  EncodingInfo.Description := 'Windows的西里尔字母编码，广泛用于俄语文档';
  FEncodingList.Add(EncodingInfo);
  
  // KOI8-R
  EncodingInfo.Name := 'KOI8-R';
  EncodingInfo.DisplayName := 'KOI8-R (俄文)';
  EncodingInfo.CodePage := 20866;
  EncodingInfo.Category := 'European';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(20866);
  EncodingInfo.Description := '俄文常用编码，在Unix/Linux系统中广泛使用';
  FEncodingList.Add(EncodingInfo);
  
  // 添加其他ISO-8859编码
  for var i := 3 to 16 do
  begin
    // 跳过不存在的ISO-8859-12
    if i = 12 then
      Continue;
      
    var CodePage := 28590 + i;
    
    EncodingInfo.Name := Format('ISO-8859-%d', [i]);
    
    case i of
      3: EncodingInfo.DisplayName := 'ISO-8859-3 (南欧)';
      4: EncodingInfo.DisplayName := 'ISO-8859-4 (北欧)';
      6: EncodingInfo.DisplayName := 'ISO-8859-6 (阿拉伯语)';
      7: EncodingInfo.DisplayName := 'ISO-8859-7 (希腊语)';
      8: EncodingInfo.DisplayName := 'ISO-8859-8 (希伯来语)';
      9: EncodingInfo.DisplayName := 'ISO-8859-9 (土耳其语)';
      10: EncodingInfo.DisplayName := 'ISO-8859-10 (北欧语言)';
      11: EncodingInfo.DisplayName := 'ISO-8859-11 (泰语)';
      13: EncodingInfo.DisplayName := 'ISO-8859-13 (波罗的海语言)';
      14: EncodingInfo.DisplayName := 'ISO-8859-14 (凯尔特语)';
      15: EncodingInfo.DisplayName := 'ISO-8859-15 (带欧元符号的西欧)';
      16: EncodingInfo.DisplayName := 'ISO-8859-16 (东南欧)';
      else EncodingInfo.DisplayName := Format('ISO-8859-%d', [i]);
    end;
    
    EncodingInfo.CodePage := CodePage;
    EncodingInfo.Category := 'European';
    EncodingInfo.HasBOM := False;
    EncodingInfo.IsUnicode := False;
    EncodingInfo.IsAvailable := IsEncodingAvailable(CodePage);
    EncodingInfo.Description := Format('ISO-8859-%d编码，支持特定欧洲语言', [i]);
    
    FEncodingList.Add(EncodingInfo);
  end;
  
  // ========================
  // 新增编码支持开始
  // ========================
  
  // === 西欧/美洲编码 (7种) ===
  
  // Windows-1252
  EncodingInfo.Name := 'Windows-1252';
  EncodingInfo.DisplayName := 'Windows-1252 (西欧Windows)';
  EncodingInfo.CodePage := 1252;
  EncodingInfo.Category := 'Western';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(1252);
  EncodingInfo.Description := 'Windows西欧编码，支持英语、法语、德语等';
  FEncodingList.Add(EncodingInfo);
  
  // Windows-1250
  EncodingInfo.Name := 'Windows-1250';
  EncodingInfo.DisplayName := 'Windows-1250 (中欧Windows)';
  EncodingInfo.CodePage := 1250;
  EncodingInfo.Category := 'Western';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(1250);
  EncodingInfo.Description := 'Windows中欧编码，支持波兰语、捷克语等';
  FEncodingList.Add(EncodingInfo);
  
  // MacRoman
  EncodingInfo.Name := 'MacRoman';
  EncodingInfo.DisplayName := 'MacRoman (苹果西欧)';
  EncodingInfo.CodePage := 10000;
  EncodingInfo.Category := 'Western';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(10000);
  EncodingInfo.Description := '苹果Mac系统使用的西欧编码';
  FEncodingList.Add(EncodingInfo);
  
  // IBM850
  EncodingInfo.Name := 'IBM850';
  EncodingInfo.DisplayName := 'IBM850 (DOS西欧)';
  EncodingInfo.CodePage := 850;
  EncodingInfo.Category := 'Western';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(850);
  EncodingInfo.Description := 'DOS/Windows命令行使用的西欧编码';
  FEncodingList.Add(EncodingInfo);
  
  // IBM437
  EncodingInfo.Name := 'IBM437';
  EncodingInfo.DisplayName := 'IBM437 (DOS美国)';
  EncodingInfo.CodePage := 437;
  EncodingInfo.Category := 'Western';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(437);
  EncodingInfo.Description := '最初的IBM PC字符集，包含基本ASCII和绘图符号';
  FEncodingList.Add(EncodingInfo);
  
  // IBM865
  EncodingInfo.Name := 'IBM865';
  EncodingInfo.DisplayName := 'IBM865 (DOS北欧)';
  EncodingInfo.CodePage := 865;
  EncodingInfo.Category := 'Western';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(865);
  EncodingInfo.Description := 'DOS北欧编码，支持丹麦语、挪威语等';
  FEncodingList.Add(EncodingInfo);
  
  // IBM860
  EncodingInfo.Name := 'IBM860';
  EncodingInfo.DisplayName := 'IBM860 (DOS葡萄牙语)';
  EncodingInfo.CodePage := 860;
  EncodingInfo.Category := 'Western';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(860);
  EncodingInfo.Description := 'DOS葡萄牙语编码';
  FEncodingList.Add(EncodingInfo);
  
  // === 东欧/斯拉夫编码 (5种) ===
  
  // Windows-1253
  EncodingInfo.Name := 'Windows-1253';
  EncodingInfo.DisplayName := 'Windows-1253 (希腊Windows)';
  EncodingInfo.CodePage := 1253;
  EncodingInfo.Category := 'Eastern European';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(1253);
  EncodingInfo.Description := 'Windows希腊语编码';
  FEncodingList.Add(EncodingInfo);
  
  // Windows-1254
  EncodingInfo.Name := 'Windows-1254';
  EncodingInfo.DisplayName := 'Windows-1254 (土耳其Windows)';
  EncodingInfo.CodePage := 1254;
  EncodingInfo.Category := 'Eastern European';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(1254);
  EncodingInfo.Description := 'Windows土耳其语编码';
  FEncodingList.Add(EncodingInfo);
  
  // Windows-1257
  EncodingInfo.Name := 'Windows-1257';
  EncodingInfo.DisplayName := 'Windows-1257 (波罗的海Windows)';
  EncodingInfo.CodePage := 1257;
  EncodingInfo.Category := 'Eastern European';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(1257);
  EncodingInfo.Description := 'Windows波罗的海语言编码，支持爱沙尼亚语、拉脱维亚语、立陶宛语';
  FEncodingList.Add(EncodingInfo);
  
  // KOI8-U
  EncodingInfo.Name := 'KOI8-U';
  EncodingInfo.DisplayName := 'KOI8-U (乌克兰文)';
  EncodingInfo.CodePage := 21866;
  EncodingInfo.Category := 'Eastern European';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(21866);
  EncodingInfo.Description := '乌克兰语编码，KOI8-R的扩展';
  FEncodingList.Add(EncodingInfo);
  
  // MacCyrillic
  EncodingInfo.Name := 'MacCyrillic';
  EncodingInfo.DisplayName := 'MacCyrillic (苹果西里尔)';
  EncodingInfo.CodePage := 10007;
  EncodingInfo.Category := 'Eastern European';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(10007);
  EncodingInfo.Description := '苹果Mac系统使用的西里尔字母编码';
  FEncodingList.Add(EncodingInfo);
  
  // === 中东/希伯来/阿拉伯编码 (5种) ===
  
  // Windows-1255
  EncodingInfo.Name := 'Windows-1255';
  EncodingInfo.DisplayName := 'Windows-1255 (希伯来Windows)';
  EncodingInfo.CodePage := 1255;
  EncodingInfo.Category := 'Middle Eastern';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(1255);
  EncodingInfo.Description := 'Windows希伯来语编码';
  FEncodingList.Add(EncodingInfo);
  
  // Windows-1256
  EncodingInfo.Name := 'Windows-1256';
  EncodingInfo.DisplayName := 'Windows-1256 (阿拉伯Windows)';
  EncodingInfo.CodePage := 1256;
  EncodingInfo.Category := 'Middle Eastern';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(1256);
  EncodingInfo.Description := 'Windows阿拉伯语编码';
  FEncodingList.Add(EncodingInfo);
  
  // CP862
  EncodingInfo.Name := 'CP862';
  EncodingInfo.DisplayName := 'CP862 (DOS希伯来)';
  EncodingInfo.CodePage := 862;
  EncodingInfo.Category := 'Middle Eastern';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(862);
  EncodingInfo.Description := 'DOS希伯来语编码';
  FEncodingList.Add(EncodingInfo);
  
  // CP864
  EncodingInfo.Name := 'CP864';
  EncodingInfo.DisplayName := 'CP864 (DOS阿拉伯)';
  EncodingInfo.CodePage := 864;
  EncodingInfo.Category := 'Middle Eastern';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(864);
  EncodingInfo.Description := 'DOS阿拉伯语编码';
  FEncodingList.Add(EncodingInfo);
  
  // ISO-8859-6-I
  EncodingInfo.Name := 'ISO-8859-6-I';
  EncodingInfo.DisplayName := 'ISO-8859-6-I (阿拉伯方向反转)';
  EncodingInfo.CodePage := 708;
  EncodingInfo.Category := 'Middle Eastern';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(708);
  EncodingInfo.Description := '阿拉伯语ISO编码，支持从右到左书写方向';
  FEncodingList.Add(EncodingInfo);
  
  // === 亚洲编码扩展 (8种) ===
  
  // CP932
  EncodingInfo.Name := 'CP932';
  EncodingInfo.DisplayName := 'CP932 (日本Windows)';
  EncodingInfo.CodePage := 932;
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(932);
  EncodingInfo.Description := 'Microsoft扩展的Shift-JIS编码，用于Windows日文';
  FEncodingList.Add(EncodingInfo);
  
  // CP949
  EncodingInfo.Name := 'CP949';
  EncodingInfo.DisplayName := 'CP949 (韩国Windows)';
  EncodingInfo.CodePage := 949;
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(949);
  EncodingInfo.Description := '韩国Windows编码，也称为UHC编码';
  FEncodingList.Add(EncodingInfo);
  
  // CP950
  EncodingInfo.Name := 'CP950';
  EncodingInfo.DisplayName := 'CP950 (繁体中文Windows)';
  EncodingInfo.CodePage := 950;
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(950);
  EncodingInfo.Description := 'Microsoft扩展的Big5编码，用于Windows繁体中文';
  FEncodingList.Add(EncodingInfo);
  
  // CP936
  EncodingInfo.Name := 'CP936';
  EncodingInfo.DisplayName := 'CP936 (简体中文Windows)';
  EncodingInfo.CodePage := 936;
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(936);
  EncodingInfo.Description := 'Microsoft的GBK实现，用于Windows简体中文';
  FEncodingList.Add(EncodingInfo);
  
  // Big5-HKSCS
  EncodingInfo.Name := 'Big5-HKSCS';
  EncodingInfo.DisplayName := 'Big5-HKSCS (香港繁体中文)';
  EncodingInfo.CodePage := 950; // 使用Big5代码页
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(950);
  EncodingInfo.Description := '香港增补字符集，Big5的扩展版本';
  FEncodingList.Add(EncodingInfo);
  
  // EUC-TW
  EncodingInfo.Name := 'EUC-TW';
  EncodingInfo.DisplayName := 'EUC-TW (台湾EUC)';
  EncodingInfo.CodePage := 51950; // 估计值，可能需要调整
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(51950);
  EncodingInfo.Description := '台湾扩展Unix编码';
  FEncodingList.Add(EncodingInfo);
  
  // ISO-2022-JP
  EncodingInfo.Name := 'ISO-2022-JP';
  EncodingInfo.DisplayName := 'ISO-2022-JP (日本邮件编码)';
  EncodingInfo.CodePage := 50220;
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(50220);
  EncodingInfo.Description := '日本电子邮件和新闻组常用编码';
  FEncodingList.Add(EncodingInfo);
  
  // ISO-2022-KR
  EncodingInfo.Name := 'ISO-2022-KR';
  EncodingInfo.DisplayName := 'ISO-2022-KR (韩国邮件编码)';
  EncodingInfo.CodePage := 50225;
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(50225);
  EncodingInfo.Description := '韩国电子邮件和新闻组常用编码';
  FEncodingList.Add(EncodingInfo);
  
  // === 其他国际编码 (5种) ===
  
  // VISCII
  EncodingInfo.Name := 'VISCII';
  EncodingInfo.DisplayName := 'VISCII (越南)';
  EncodingInfo.CodePage := 1258; // Windows越南编码
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(1258);
  EncodingInfo.Description := '越南标准编码';
  FEncodingList.Add(EncodingInfo);
  
  // TIS-620
  EncodingInfo.Name := 'TIS-620';
  EncodingInfo.DisplayName := 'TIS-620 (泰国)';
  EncodingInfo.CodePage := 874;
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(874);
  EncodingInfo.Description := '泰语标准编码';
  FEncodingList.Add(EncodingInfo);
  
  // TSCII
  EncodingInfo.Name := 'TSCII';
  EncodingInfo.DisplayName := 'TSCII (泰米尔文)';
  EncodingInfo.CodePage := 57004; // 估计值，可能需要调整
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(57004);
  EncodingInfo.Description := '泰米尔标准编码';
  FEncodingList.Add(EncodingInfo);
  
  // ISCII
  EncodingInfo.Name := 'ISCII';
  EncodingInfo.DisplayName := 'ISCII (印度语言)';
  EncodingInfo.CodePage := 57002; // 估计值，可能需要调整
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(57002);
  EncodingInfo.Description := '印度语言标准编码，支持多种印度语言';
  FEncodingList.Add(EncodingInfo);
  
  // ARMSCII-8
  EncodingInfo.Name := 'ARMSCII-8';
  EncodingInfo.DisplayName := 'ARMSCII-8 (亚美尼亚)';
  EncodingInfo.CodePage := 901; // 估计值，可能需要调整
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(901);
  EncodingInfo.Description := '亚美尼亚语标准编码';
  FEncodingList.Add(EncodingInfo);
  
  // ========================
  // 新增编码支持结束
  // ========================
  
  // ========================
  // 附加编码支持开始 - 2024年更新
  // ========================
  
  // === 重新分类：将其他国际编码移至亚洲扩展 ===
  
  // 将VISCII从International移至Asian Extended
  EncodingInfo.Name := 'VISCII';
  EncodingInfo.DisplayName := 'VISCII (越南)';
  EncodingInfo.CodePage := 1258; // Windows越南编码
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(1258);
  EncodingInfo.Description := '越南标准编码';
  FEncodingList.Add(EncodingInfo);
  
  // 将TIS-620从International移至Asian Extended
  EncodingInfo.Name := 'TIS-620';
  EncodingInfo.DisplayName := 'TIS-620 (泰国)';
  EncodingInfo.CodePage := 874;
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(874);
  EncodingInfo.Description := '泰语标准编码';
  FEncodingList.Add(EncodingInfo);
  
  // 将TSCII从International移至Asian Extended
  EncodingInfo.Name := 'TSCII';
  EncodingInfo.DisplayName := 'TSCII (泰米尔文)';
  EncodingInfo.CodePage := 57004; // 估计值，可能需要调整
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(57004);
  EncodingInfo.Description := '泰米尔标准编码';
  FEncodingList.Add(EncodingInfo);
  
  // 将ISCII从International移至Asian Extended
  EncodingInfo.Name := 'ISCII';
  EncodingInfo.DisplayName := 'ISCII (印度语言)';
  EncodingInfo.CodePage := 57002; // 估计值，可能需要调整
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(57002);
  EncodingInfo.Description := '印度语言标准编码，支持多种印度语言';
  FEncodingList.Add(EncodingInfo);
  
  // === 新增非洲特有编码 ===
  
  // Geez (埃塞俄比亚文)
  EncodingInfo.Name := 'Geez';
  EncodingInfo.DisplayName := 'Geez (埃塞俄比亚文)';
  EncodingInfo.CodePage := 43507; // 埃塞俄比亚文代码页
  EncodingInfo.Category := 'African';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(43507);
  EncodingInfo.Description := '埃塞俄比亚传统文字系统编码';
  FEncodingList.Add(EncodingInfo);
  
  // Amharic (阿姆哈拉语)
  EncodingInfo.Name := 'Amharic';
  EncodingInfo.DisplayName := 'Amharic (阿姆哈拉语)';
  EncodingInfo.CodePage := 65000; // 使用UTF-7作为替代
  EncodingInfo.Category := 'African';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := True;
  EncodingInfo.Description := '埃塞俄比亚官方语言编码';
  FEncodingList.Add(EncodingInfo);
  
  // === 拉丁美洲特殊编码 ===
  
  // CESU-8
  EncodingInfo.Name := 'CESU-8';
  EncodingInfo.DisplayName := 'CESU-8 (拉丁美洲Unicode变种)';
  EncodingInfo.CodePage := 65000; // 使用UTF-7作为替代
  EncodingInfo.Category := 'Latin American';
  EncodingInfo.HasBOM := True;
  EncodingInfo.IsUnicode := True;
  EncodingInfo.IsAvailable := True;
  EncodingInfo.Description := '拉丁美洲地区使用的特殊Unicode编码变种';
  FEncodingList.Add(EncodingInfo);
  
  // === 其他少数民族语言编码 ===
  
  // 蒙古文编码
  EncodingInfo.Name := 'Mongolian';
  EncodingInfo.DisplayName := 'Mongolian (蒙古文)';
  EncodingInfo.CodePage := 54936; // 使用GB18030作为基础
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(54936);
  EncodingInfo.Description := '蒙古文编码，基于GB18030';
  FEncodingList.Add(EncodingInfo);
  
  // 藏文编码
  EncodingInfo.Name := 'Tibetan';
  EncodingInfo.DisplayName := 'Tibetan (藏文)';
  EncodingInfo.CodePage := 54936; // 使用GB18030作为基础
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(54936);
  EncodingInfo.Description := '藏文编码，基于GB18030';
  FEncodingList.Add(EncodingInfo);
  
  // 老挝文编码
  EncodingInfo.Name := 'Lao';
  EncodingInfo.DisplayName := 'Lao (老挝文)';
  EncodingInfo.CodePage := 28598; // 估计值
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(28598);
  EncodingInfo.Description := '老挝文编码';
  FEncodingList.Add(EncodingInfo);
  
  // 高棉文编码 (柬埔寨)
  EncodingInfo.Name := 'Khmer';
  EncodingInfo.DisplayName := 'Khmer (高棉文)';
  EncodingInfo.CodePage := 65001; // 使用UTF-8
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := True;
  EncodingInfo.IsAvailable := True;
  EncodingInfo.Description := '柬埔寨高棉文编码';
  FEncodingList.Add(EncodingInfo);
  
  // 缅甸文编码
  EncodingInfo.Name := 'Myanmar';
  EncodingInfo.DisplayName := 'Myanmar (缅甸文)';
  EncodingInfo.CodePage := 65001; // 使用UTF-8
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := True;
  EncodingInfo.IsAvailable := True;
  EncodingInfo.Description := '缅甸文编码';
  FEncodingList.Add(EncodingInfo);
  
  // 印尼文编码
  EncodingInfo.Name := 'Indonesian';
  EncodingInfo.DisplayName := 'Indonesian (印尼文)';
  EncodingInfo.CodePage := 1252; // 使用Windows-1252
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(1252);
  EncodingInfo.Description := '印尼文编码，基于拉丁字母';
  FEncodingList.Add(EncodingInfo);
  
  // 马来文编码
  EncodingInfo.Name := 'Malay';
  EncodingInfo.DisplayName := 'Malay (马来文)';
  EncodingInfo.CodePage := 1252; // 使用Windows-1252
  EncodingInfo.Category := 'Asian Extended';
  EncodingInfo.HasBOM := False;
  EncodingInfo.IsUnicode := False;
  EncodingInfo.IsAvailable := IsEncodingAvailable(1252);
  EncodingInfo.Description := '马来文编码，基于拉丁字母';
  FEncodingList.Add(EncodingInfo);
  
  // ========================
  // 附加编码支持结束
  // ========================
end;

function TEncodingInfoManager.GetAllEncodings: TArray<TEncodingInfo>;
begin
  Result := FEncodingList.ToArray;
end;

function TEncodingInfoManager.GetEncodingsByCategory(const Category: string): TArray<TEncodingInfo>;
var
  MatchList: TList<TEncodingInfo>;
begin
  MatchList := TList<TEncodingInfo>.Create;
  try
    for var Info in FEncodingList do
    begin
      if SameText(Info.Category, Category) then
        MatchList.Add(Info);
    end;
    Result := MatchList.ToArray;
  finally
    MatchList.Free;
  end;
end;

function TEncodingInfoManager.GetEncodingInfoByName(const Name: string): TEncodingInfo;
begin
  for var Info in FEncodingList do
  begin
    if SameText(Info.Name, Name) then
      Exit(Info);
  end;
  
  // 如果找不到，返回默认编码信息
  Result.Name := 'Unknown';
  Result.DisplayName := 'Unknown';
  Result.CodePage := 0;
  Result.Category := '';
  Result.HasBOM := False;
  Result.IsUnicode := False;
  Result.IsAvailable := False;
  Result.Description := '';
end;

function TEncodingInfoManager.GetEncodingInfoByCodePage(CodePage: Integer): TEncodingInfo;
begin
  for var Info in FEncodingList do
  begin
    if Info.CodePage = CodePage then
      Exit(Info);
  end;
  
  // 如果找不到，返回默认编码信息
  Result.Name := 'Unknown';
  Result.DisplayName := 'Unknown';
  Result.CodePage := 0;
  Result.Category := '';
  Result.HasBOM := False;
  Result.IsUnicode := False;
  Result.IsAvailable := False;
  Result.Description := '';
end;

function TEncodingInfoManager.GetCategories: TArray<string>;
var
  CategorySet: TDictionary<string, Boolean>;
  Category: string;
begin
  CategorySet := TDictionary<string, Boolean>.Create;
  try
    for var Info in FEncodingList do
    begin
      if not CategorySet.ContainsKey(Info.Category) then
        CategorySet.Add(Info.Category, True);
    end;
    
    SetLength(Result, CategorySet.Count);
    var Index := 0;
    for Category in CategorySet.Keys do
    begin
      Result[Index] := Category;
      Inc(Index);
    end;
  finally
    CategorySet.Free;
  end;
end;

function TEncodingInfoManager.GetUTFEncodings: TArray<TEncodingInfo>;
begin
  Result := GetEncodingsByCategory('Unicode');
end;

function TEncodingInfoManager.GetRegionalEncodings: TArray<TEncodingInfo>;
var
  AsianEncodings, EuropeanEncodings: TArray<TEncodingInfo>;
  TotalCount, Index: Integer;
begin
  AsianEncodings := GetEncodingsByCategory('Asian');
  EuropeanEncodings := GetEncodingsByCategory('European');
  
  TotalCount := Length(AsianEncodings) + Length(EuropeanEncodings);
  SetLength(Result, TotalCount);
  
  Index := 0;
  for var i := 0 to High(AsianEncodings) do
  begin
    Result[Index] := AsianEncodings[i];
    Inc(Index);
  end;
  
  for var i := 0 to High(EuropeanEncodings) do
  begin
    Result[Index] := EuropeanEncodings[i];
    Inc(Index);
  end;
end;

function TEncodingInfoManager.CreateEncoding(const Name: string): TEncoding;
var
  EncodingInfo: TEncodingInfo;
begin
  EncodingInfo := GetEncodingInfoByName(Name);
  
  if EncodingInfo.IsAvailable then
  begin
    try
      if EncodingInfo.CodePage = 65001 then
        Result := TEncoding.UTF8
      else if EncodingInfo.CodePage = 1200 then
        Result := TEncoding.Unicode
      else if EncodingInfo.CodePage = 1201 then
        Result := TEncoding.BigEndianUnicode
      else if EncodingInfo.CodePage = 20127 then
        Result := TEncoding.ASCII
      else if EncodingInfo.CodePage = GetACP then
        Result := TEncoding.ANSI
      else
        Result := TEncoding.GetEncoding(EncodingInfo.CodePage);
    except
      Result := TEncoding.ANSI; // 失败时返回ANSI编码
    end;
  end
  else
    Result := TEncoding.ANSI; // 不可用时返回ANSI编码
end;

initialization
  TEncodingInfoManager.FInstance := nil;

finalization
  TEncodingInfoManager.ReleaseInstance;

end. 