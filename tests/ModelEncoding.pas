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
  
  // 添加常见编码组和选项
  // 1. Unicode组
  AddEncodingGroup('Unicode编码');
  AddEncodingOption('UTF-8', 'UTF-8', 65001, False);
  AddEncodingOption('UTF-8 BOM', 'UTF-8 BOM', 65001, True);
  AddEncodingOption('UTF-16LE', 'UTF-16', 1200, True);
  AddEncodingOption('UTF-16BE', 'UTF-16BE', 1201, True);
  AddEncodingOption('UTF-7', 'UTF-7', 65000, False);
  AddEncodingOption('UTF-32', 'UTF-32', 12000, True);
  AddEncodingOption('UTF-32BE', 'UTF-32BE', 12001, True);
  
  // 2. 亚洲编码组
  AddEncodingGroup('亚洲编码');
  AddEncodingOption('简体中文 (GB2312)', 'GB2312', 936, False);
  AddEncodingOption('繁体中文 (Big5)', 'Big5', 950, False);
  AddEncodingOption('日语 (Shift-JIS)', 'Shift-JIS', 932, False);
  AddEncodingOption('韩语 (Korean)', 'Korean', 949, False);
  AddEncodingOption('日语 EUC-JP', 'EUC-JP', 51932, False);
  AddEncodingOption('简体中文 GB18030', 'GB18030', 54936, False);
  AddEncodingOption('泰语', 'Thai', 874, False);
  AddEncodingOption('越南语', 'Vietnamese', 1258, False);
  
  // 3. 欧洲编码组
  AddEncodingGroup('欧洲编码');
  AddEncodingOption('西欧语系 (Latin1)', 'Latin1', 1252, False);
  AddEncodingOption('ASCII', 'ASCII', 20127, False);
  AddEncodingOption('中欧语系 (Latin2)', 'Latin2', 1250, False);
  AddEncodingOption('西里尔字母 (Cyrillic)', 'Cyrillic', 1251, False);
  AddEncodingOption('希腊语', 'Greek', 1253, False);
  AddEncodingOption('土耳其语', 'Turkish', 1254, False);
  AddEncodingOption('希伯来语', 'Hebrew', 1255, False);
  AddEncodingOption('阿拉伯语', 'Arabic', 1256, False);
  AddEncodingOption('波罗的海语系', 'Baltic', 1257, False);
  
  // 4. 其他编码组
  AddEncodingGroup('其他编码');
  AddEncodingOption('IBM EBCDIC (US)', 'EBCDIC', 37, False);
  AddEncodingOption('OEM 美国', 'OEM-US', 437, False);
  AddEncodingOption('OEM 多语言拉丁语 I', 'OEM-Latin', 850, False);
  AddEncodingOption('ISO-8859-1', 'ISO-8859-1', 28591, False);
  AddEncodingOption('ISO-8859-2', 'ISO-8859-2', 28592, False);
  AddEncodingOption('ISO-8859-3', 'ISO-8859-3', 28593, False);
  AddEncodingOption('ISO-8859-4', 'ISO-8859-4', 28594, False);
  AddEncodingOption('ISO-8859-5', 'ISO-8859-5', 28595, False);
  AddEncodingOption('ISO-8859-6', 'ISO-8859-6', 28596, False);
  AddEncodingOption('ISO-8859-7', 'ISO-8859-7', 28597, False);
  AddEncodingOption('ISO-8859-8', 'ISO-8859-8', 28598, False);
  AddEncodingOption('ISO-8859-9', 'ISO-8859-9', 28599, False);
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