unit ModelEncoding;

interface

uses
  System.SysUtils, System.Classes, System.Math;

type
  // 转换结果枚举
  TConversionResult = (crSuccess, crFailed, crSkipped);

  // 编码信息结构体
  TEncodingInfo = record
    Name: string;          // 编码名称
    CodePage: Integer;     // 编码的代码页
    HasBOM: Boolean;       // 是否支持BOM
    ShortName: string;     // 短名称或识别符（可选）
    IsGroup: Boolean;      // 是否为分组标题
  end;
  
  TEncodingInfoArray = array of TEncodingInfo;
  
  // 编码模型类
  TEncodingModel = class
  private
    FEncodingList: TEncodingInfoArray;
    
    function GetEncodingCount: Integer;
    function GetEncoding(Index: Integer): TEncodingInfo;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure InitEncodingList;
    function GetEncodingByIndex(Index: Integer; out WithBOM: Boolean): TEncoding;
    function GetEncodingName(Encoding: TEncoding): string;
    function GetFormattedEncodingName(CodePage: Integer; HasBOM: Boolean): string;
    
    // 添加编码到列表
    procedure AddEncodingGroup(const GroupName: string);
    procedure AddEncodingOption(const EncodingName, ShortName: string; CodePage: Integer; HasBOM: Boolean);
    
    // 替换编码列表（仅用于UI展示，不影响实际功能）
    procedure ReplaceEncodingList(const NewList: TEncodingInfoArray);
    
    property EncodingCount: Integer read GetEncodingCount;
    property Encodings[Index: Integer]: TEncodingInfo read GetEncoding;
    property EncodingList: TEncodingInfoArray read FEncodingList;
  end;
  
const
  // 不支持转换的文件格式列表
  UNSUPPORTED_FILES: array[0..6] of string = (
    'utf16be_bom.txt',
    'utf16le_bom.txt',
    'mixed_encoding_simulation.txt',
    'shift_jis.txt',
    'iso8859_1.txt',
    'invalid_utf8.txt',
    'euc_jp.txt'
  );
  
implementation

{ TEncodingModel }

constructor TEncodingModel.Create;
begin
  inherited Create;
  InitEncodingList;
end;

destructor TEncodingModel.Destroy;
begin
  SetLength(FEncodingList, 0);
  inherited;
end;

procedure TEncodingModel.AddEncodingGroup(const GroupName: string);
var
  EncodingInfo: TEncodingInfo;
begin
  EncodingInfo.Name := GroupName;
  EncodingInfo.CodePage := -999; // 特殊标记
  EncodingInfo.HasBOM := False;
  EncodingInfo.ShortName := '';
  EncodingInfo.IsGroup := True;
  
  SetLength(FEncodingList, Length(FEncodingList) + 1);
  FEncodingList[High(FEncodingList)] := EncodingInfo;
end;

procedure TEncodingModel.AddEncodingOption(const EncodingName, ShortName: string; CodePage: Integer; HasBOM: Boolean);
var
  EncodingInfo: TEncodingInfo;
begin
  EncodingInfo.Name := EncodingName;
  EncodingInfo.CodePage := CodePage;
  EncodingInfo.HasBOM := HasBOM;
  EncodingInfo.ShortName := ShortName;
  EncodingInfo.IsGroup := False;
  
  SetLength(FEncodingList, Length(FEncodingList) + 1);
  FEncodingList[High(FEncodingList)] := EncodingInfo;
end;

function TEncodingModel.GetEncoding(Index: Integer): TEncodingInfo;
begin
  if (Index >= 0) and (Index < Length(FEncodingList)) then
    Result := FEncodingList[Index]
  else
    raise Exception.Create('编码索引超出范围');
end;

function TEncodingModel.GetEncodingByIndex(Index: Integer; out WithBOM: Boolean): TEncoding;
begin
  // 默认值
  Result := TEncoding.UTF8;
  WithBOM := True;
  
  // 验证索引
  if (Index < 0) or (Index >= Length(FEncodingList)) then
    Exit;
    
  // 如果是组标题，返回默认编码
  if FEncodingList[Index].IsGroup then
    Exit;
    
  // 根据CodePage决定编码
  case FEncodingList[Index].CodePage of
    1200: Result := TEncoding.Unicode;     // UTF-16LE
    1201: Result := TEncoding.BigEndianUnicode; // UTF-16BE
    65001: Result := TEncoding.UTF8;       // UTF-8
    20127: Result := TEncoding.ASCII;      // ASCII
    65000: Result := TEncoding.UTF7;       // UTF-7
    else
      // 尝试获取系统编码
      try
        Result := TEncoding.GetEncoding(FEncodingList[Index].CodePage);
      except
        // 出错时使用默认
        Result := TEncoding.Default;
      end;
  end;
  
  // 设置BOM标志
  WithBOM := FEncodingList[Index].HasBOM;
end;

function TEncodingModel.GetEncodingCount: Integer;
begin
  Result := Length(FEncodingList);
end;

function TEncodingModel.GetEncodingName(Encoding: TEncoding): string;
var
  CodePage: Integer;
begin
  // 检查已知编码
  if Encoding = TEncoding.ASCII then
    Result := 'ASCII'
  else if Encoding = TEncoding.Unicode then
    Result := 'UTF-16LE'
  else if Encoding = TEncoding.BigEndianUnicode then
    Result := 'UTF-16BE'
  else if Encoding = TEncoding.UTF8 then
    Result := 'UTF-8'
  else if Encoding = TEncoding.UTF7 then
    Result := 'UTF-7'
  else
  begin
    // 尝试获取代码页
    try
      CodePage := Encoding.CodePage;
      Result := GetFormattedEncodingName(CodePage, False);
    except
      Result := '未知编码';
    end;
  end;
end;

function TEncodingModel.GetFormattedEncodingName(CodePage: Integer; HasBOM: Boolean): string;
begin
  case CodePage of
    0: Result := '未知';
    1200: Result := 'UTF-16LE';
    1201: Result := 'UTF-16BE';
    12000: Result := 'UTF-32';
    20127: Result := 'ASCII';
    65000: Result := 'UTF-7';
    65001: 
      begin
        if HasBOM then
          Result := 'UTF-8 BOM'
        else
          Result := 'UTF-8';
      end;
    936: Result := 'GB2312';
    950: Result := '繁体中文';
    932: Result := '日语';
    949: Result := '韩语';
    1250: Result := '中欧语系';
    1251: Result := '西里尔字母';
    1252: Result := '西欧语系';
    1253: Result := '希腊语';
    1254: Result := '土耳其语';
    1255: Result := '希伯来语';
    1256: Result := '阿拉伯语';
    1257: Result := '波罗的海语系';
    1258: Result := '越南语';
    else
      Result := 'CodePage-' + IntToStr(CodePage);
  end;
  
  // 添加代码页信息
  if CodePage > 0 then
    Result := Result + ' (' + IntToStr(CodePage) + ')';
end;

procedure TEncodingModel.InitEncodingList;
begin
  SetLength(FEncodingList, 0);

  // --- NEW Categorized List with Descriptions (Ordered as UTF, Asia, Regions, Other) ---

  // --- 1. UTF 相关 ---
  AddEncodingGroup('UTF 相关');
  AddEncodingOption('UTF-8', 'UTF-8', 65001, False);
  AddEncodingOption('UTF-8 BOM', 'UTF-8 BOM', 65001, True);
  AddEncodingOption('UTF-16LE - 小端序', 'UTF-16LE', 1200, True);
  AddEncodingOption('UTF-16BE - 大端序', 'UTF-16BE', 1201, True);
  AddEncodingOption('UTF-16 - 小端序', 'UTF-16', 1200, True);
  AddEncodingOption('UTF-32LE - 小端序', 'UTF-32LE', 12000, True);
  AddEncodingOption('UTF-32BE - 大端序', 'UTF-32BE', 12001, True);
  AddEncodingOption('UTF-32 - 小端序', 'UTF-32', 12000, True);
  AddEncodingOption('UTF-7 - 不推荐', 'UTF-7', 65000, False);
  AddEncodingOption('UCS-2 - UTF-16旧版', 'UCS-2', 1200, False);
  AddEncodingOption('UCS-4LE - 小端序', 'UCS-4LE', 12000, False);
  AddEncodingOption('UCS-4BE - 大端序', 'UCS-4BE', 12001, False);

  // --- 2. 亚洲 --- 
  AddEncodingGroup('亚洲');
  AddEncodingOption('GB2312 - 中文简体', 'GB2312', 936, False);
  AddEncodingOption('GBK - 中文简体扩展', 'GBK', 936, False);
  AddEncodingOption('GB18030 - 最新中文国标', 'GB18030', 54936, False);
  AddEncodingOption('Big5 - 中文繁体', 'BIG5', 950, False);
  AddEncodingOption('Big5-HKSCS - 香港标准', 'BIG5-HKSCS', 950, False);
  AddEncodingOption('Shift_JIS - 日语 (Windows常用)', 'SHIFT_JIS', 932, False);
  AddEncodingOption('EUC-JP - 日语 (Unix常用)', 'EUC-JP', 20932, False);
  AddEncodingOption('ISO-2022-JP - 日语 (电子邮件常用)', 'ISO-2022-JP', 50220, False);
  AddEncodingOption('ISO-2022-JP-2 - 日语 (多语言扩展)', 'ISO-2022-JP-2', 50222, False);
  AddEncodingOption('EUC-KR - 韩语', 'EUC-KR', 949, False);
  AddEncodingOption('TIS-620 - 泰语', 'TIS-620', 874, False);
  AddEncodingOption('VISCII - 越南语', 'VISCII', 0, False);

  // --- 3. Windows (代码页) --- 
  AddEncodingGroup('Windows (代码页)');
  AddEncodingOption('Windows-1250 - 中欧', 'CP1250', 1250, False);
  AddEncodingOption('Windows-1251 - 西里尔', 'CP1251', 1251, False);
  AddEncodingOption('Windows-1252 - 西欧', 'CP1252', 1252, False);
  AddEncodingOption('Windows-1253 - 希腊', 'CP1253', 1253, False);
  AddEncodingOption('Windows-1254 - 土耳其', 'CP1254', 1254, False);
  AddEncodingOption('Windows-1255 - 希伯来', 'CP1255', 1255, False);
  AddEncodingOption('Windows-1256 - 阿拉伯', 'CP1256', 1256, False);
  AddEncodingOption('Windows-1257 - 波罗的海', 'CP1257', 1257, False);
  AddEncodingOption('Windows-1258 - 越南', 'CP1258', 1258, False);
  AddEncodingOption('Windows-874 - 泰语', 'CP874', 874, False);

  // --- 4. ISO-8859 --- 
  AddEncodingGroup('ISO-8859 (Latin系列)');
  AddEncodingOption('ISO-8859-1 (Latin-1)', 'ISO-8859-1', 28591, False);
  AddEncodingOption('ISO-8859-2 (Latin-2) - 中欧', 'ISO-8859-2', 28592, False);
  AddEncodingOption('ISO-8859-3 (Latin-3) - 南欧', 'ISO-8859-3', 28593, False);
  AddEncodingOption('ISO-8859-4 (Latin-4) - 北欧', 'ISO-8859-4', 28594, False);
  AddEncodingOption('ISO-8859-5 - 西里尔', 'ISO-8859-5', 28595, False);
  AddEncodingOption('ISO-8859-6 - 阿拉伯', 'ISO-8859-6', 28596, False);
  AddEncodingOption('ISO-8859-7 - 希腊', 'ISO-8859-7', 28597, False);
  AddEncodingOption('ISO-8859-8 - 希伯来', 'ISO-8859-8', 28598, False);
  AddEncodingOption('ISO-8859-9 (Latin-5) - 土耳其', 'ISO-8859-9', 28599, False);
  AddEncodingOption('ISO-8859-10 (Latin-6) - 北欧', 'ISO-8859-10', 28600, False);
  AddEncodingOption('ISO-8859-13 (Latin-7) - 波罗的海', 'ISO-8859-13', 28603, False);
  AddEncodingOption('ISO-8859-14 (Latin-8) - 凯尔特', 'ISO-8859-14', 28604, False);
  AddEncodingOption('ISO-8859-15 (Latin-9) - 带欧元符号', 'ISO-8859-15', 28605, False);
  AddEncodingOption('ISO-8859-16 (Latin-10) - 东南欧', 'ISO-8859-16', 28606, False);

  // --- 5. IBM/DOS/EBCDIC --- 
  AddEncodingGroup('IBM/DOS/EBCDIC');
  AddEncodingOption('IBM437 / CP437 - DOS 美国', 'CP437', 437, False);
  AddEncodingOption('IBM850 / CP850 - DOS 拉丁1', 'CP850', 850, False);
  AddEncodingOption('IBM852 / CP852 - DOS 拉丁2', 'CP852', 852, False);
  AddEncodingOption('IBM855 / CP855 - DOS 西里尔', 'CP855', 855, False);
  AddEncodingOption('IBM857 / CP857 - DOS 土耳其', 'CP857', 857, False);
  AddEncodingOption('IBM862 / CP862 - DOS 希伯来', 'CP862', 862, False);
  AddEncodingOption('IBM866 / CP866 - DOS 俄语', 'CP866', 866, False);
  AddEncodingOption('CP866NAV - Navision 俄语', 'CP866NAV', 0, False);
  AddEncodingOption('IBM037 - EBCDIC 美国/加拿大', 'IBM037', 37, False);
  AddEncodingOption('IBM273 - EBCDIC 德国', 'IBM273', 20273, False);
  AddEncodingOption('IBM500 - EBCDIC 国际', 'IBM500', 500, False);
  AddEncodingOption('IBM870 - EBCDIC 多语言拉丁2', 'IBM870', 870, False);
  AddEncodingOption('IBM1047 - EBCDIC OpenSys 拉丁1', 'IBM1047', 1047, False);

  // --- 6. KOI8 --- 
  AddEncodingGroup('KOI8 (西里尔)');
  AddEncodingOption('KOI8-R - 俄语', 'KOI8-R', 20866, False);
  AddEncodingOption('KOI8-U - 乌克兰语', 'KOI8-U', 21866, False);
  AddEncodingOption('KOI8-T - 塔吉克语', 'KOI8-T', 0, False);

  // --- 7. Mac --- 
  AddEncodingGroup('Macintosh');
  AddEncodingOption('MacRoman - 西欧', 'MACROMAN', 10000, False);
  AddEncodingOption('MacCyrillic - 西里尔', 'MACCYRILLIC', 10007, False);
  AddEncodingOption('MacGreek - 希腊', 'MACGREEK', 10006, False);
  AddEncodingOption('MacTurkish - 土耳其', 'MACTURKISH', 10081, False);
  AddEncodingOption('MacCentralEurope - 中欧', 'MACCE', 10029, False);
  AddEncodingOption('MacIceland - 冰岛', 'MACICELAND', 10079, False);

  // --- 8. 其他 --- 
  AddEncodingGroup('其他');
  AddEncodingOption('ASCII - 美国信息交换标准代码', 'ASCII', 20127, False);
  AddEncodingOption('ARMSCII-8 - 亚美尼亚语', 'ARMSCII-8', 0, False);
  AddEncodingOption('ATARIST - Atari ST', 'ATARIST', 0, False);
  AddEncodingOption('HP Roman8 - HP 罗马字符', 'HP-ROMAN8', 0, False);
  AddEncodingOption('TRANSLIT - 音译转换', 'TRANSLIT', 0, False); // Special iconv flag

end;

procedure TEncodingModel.ReplaceEncodingList(const NewList: TEncodingInfoArray);
var
  i: Integer;
begin
  SetLength(FEncodingList, Length(NewList));
  for i := 0 to High(NewList) do
    FEncodingList[i] := NewList[i];
end;

end.