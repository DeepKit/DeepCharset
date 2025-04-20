unit ModelEncoding;

interface

uses
  System.SysUtils, System.Classes, System.Math, HelperLanguage;

type
  // 转换结果枚举
  TConversionResult = (crSuccess, crFailed, crSkipped, crFileNotFound, crAccessDenied, crUnsupportedEncoding, crConversionFailed);

  // 编码信息结构体
  TEncodingInfo = record
    Name: string;          // 编码名称
    CodePage: Integer;     // 编码的代码页
    HasBOM: Boolean;       // 是否支持BOM
    ShortName: string;     // 短名称或识别符（可选）
    IsGroup: Boolean;      // 是否为分组标题
    Description: string;   // 编码描述（用于显示在UI中）
  end;

  TEncodingInfoArray = array of TEncodingInfo;

  // 编码模型类
  TEncodingModel = class
  private
    FEncodingList: TEncodingInfoArray;
    FSelectedEncodingIndex: Integer;

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
    procedure AddEncodingOption(const EncodingName, ShortName: string; CodePage: Integer; HasBOM: Boolean; const Description: string = '');

    // 替换编码列表（仅用于UI展示，不影响实际功能）
    procedure ReplaceEncodingList(const NewList: TEncodingInfoArray);

    // 重新加载编码列表（用于语言切换后更新显示）
    procedure ReloadEncodings;

    function GetSelectedEncoding: TEncoding;

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
  FSelectedEncodingIndex := -1;
end;

destructor TEncodingModel.Destroy;
begin
  SetLength(FEncodingList, 0);
  inherited;
end;

procedure TEncodingModel.AddEncodingGroup(const GroupName: string);
var
  EncodingInfo: TEncodingInfo;
  ShortNameValue: string;
begin
  EncodingInfo.Name := GroupName;
  EncodingInfo.CodePage := -999; // 特殊标记
  EncodingInfo.HasBOM := False;
  
  // 使用GroupName作为ShortName
  ShortNameValue := GroupName;
  
  EncodingInfo.ShortName := ShortNameValue;
  EncodingInfo.IsGroup := True;
  EncodingInfo.Description := '';

  SetLength(FEncodingList, Length(FEncodingList) + 1);
  FEncodingList[High(FEncodingList)] := EncodingInfo;
end;

procedure TEncodingModel.AddEncodingOption(const EncodingName, ShortName: string; CodePage: Integer; HasBOM: Boolean; const Description: string = '');
var
  EncodingInfo: TEncodingInfo;
begin
  EncodingInfo.Name := EncodingName;
  EncodingInfo.CodePage := CodePage;
  EncodingInfo.HasBOM := HasBOM;
  EncodingInfo.ShortName := ShortName;
  EncodingInfo.IsGroup := False;
  EncodingInfo.Description := Description;

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

  // ======================================================================
  // 国际标准编码组
  // ======================================================================
  AddEncodingGroup('Unicode');
  AddEncodingOption('UTF-8', 'UTF8', 65001, False);
  AddEncodingOption('UTF-8 with BOM', 'UTF8BOM', 65001, True);
  AddEncodingOption('UTF-16 LE', 'UTF16LE', 1200, True);
  AddEncodingOption('UTF-16 BE', 'UTF16BE', 1201, True);
  AddEncodingOption('UTF-32 LE', 'UTF32LE', 12000, True);
  AddEncodingOption('UTF-32 BE', 'UTF32BE', 12001, True);
  AddEncodingOption('UTF-7', 'UTF7', 65000, False);
  AddEncodingOption('ASCII', 'ASCII', 20127, False);

  // ======================================================================
  // 亚洲编码组
  // ======================================================================
  AddEncodingGroup('Asian');
  
  // 中文编码
  AddEncodingOption('GBK', 'GBK', 936, False);
  AddEncodingOption('GB18030', 'GB18030', 54936, False);
  AddEncodingOption('GB2312', 'GB2312', 936, False);
  AddEncodingOption('Big5', 'BIG5', 950, False);
  AddEncodingOption('Big5-HKSCS', 'BIG5_HKSCS', 951, False);
  AddEncodingOption('CP936', 'CP936', 936, False);
  AddEncodingOption('CP950', 'CP950', 950, False);
  AddEncodingOption('EUC-TW', 'EUC_TW', 20000, False);
  
  // 日文编码
  AddEncodingOption('Shift-JIS', 'SHIFT_JIS', 932, False);
  AddEncodingOption('EUC-JP', 'EUC_JP', 20932, False);
  AddEncodingOption('CP932', 'CP932', 932, False);
  AddEncodingOption('ISO-2022-JP', 'ISO_2022_JP', 50220, False);
  
  // 韩文编码
  AddEncodingOption('EUC-KR', 'EUC_KR', 51949, False);
  AddEncodingOption('CP949', 'CP949', 949, False);
  AddEncodingOption('ISO-2022-KR', 'ISO_2022_KR', 50225, False);
  
  // 其他亚洲编码
  AddEncodingOption('VISCII', 'VISCII', 1129, False);
  AddEncodingOption('TIS-620', 'TIS_620', 874, False);
  AddEncodingOption('TSCII', 'TSCII', 57012, False);
  AddEncodingOption('ISCII', 'ISCII', 57002, False);

  // ======================================================================
  // 西欧和美洲编码组
  // ======================================================================
  AddEncodingGroup('Western');
  AddEncodingOption('Windows-1252', 'WINDOWS1252', 1252, False);
  AddEncodingOption('ISO-8859-1', 'ISO8859_1', 28591, False);
  AddEncodingOption('ISO-8859-15', 'ISO8859_15', 28605, False);
  AddEncodingOption('MacRoman', 'MACROMAN', 10000, False);
  AddEncodingOption('IBM850', 'IBM850', 850, False);
  AddEncodingOption('IBM437', 'IBM437', 437, False);

  // ======================================================================
  // 东欧和斯拉夫编码组
  // ======================================================================
  AddEncodingGroup('Eastern');
  AddEncodingOption('Windows-1250', 'WINDOWS1250', 1250, False);
  AddEncodingOption('Windows-1251', 'WINDOWS1251', 1251, False);
  AddEncodingOption('ISO-8859-2', 'ISO8859_2', 28592, False);
  AddEncodingOption('ISO-8859-5', 'ISO8859_5', 28595, False);
  AddEncodingOption('KOI8-R', 'KOI8R', 20866, False);
  AddEncodingOption('KOI8-U', 'KOI8U', 21866, False);
  AddEncodingOption('MacCyrillic', 'MACCYRILLIC', 10007, False);

  // ======================================================================
  // 中东和希伯来/阿拉伯编码组
  // ======================================================================
  AddEncodingGroup('MiddleEast');
  AddEncodingOption('Windows-1255', 'WINDOWS1255', 1255, False);
  AddEncodingOption('Windows-1256', 'WINDOWS1256', 1256, False);
  AddEncodingOption('ISO-8859-6', 'ISO8859_6', 28596, False);
  AddEncodingOption('ISO-8859-8', 'ISO8859_8', 28598, False);
  AddEncodingOption('ISO-8859-6-I', 'ISO_8859_6_I', 28597, False);
  AddEncodingOption('CP862', 'CP862', 862, False);
  AddEncodingOption('CP864', 'CP864', 864, False);

  // ======================================================================
  // 北欧和波罗的海编码组
  // ======================================================================
  AddEncodingGroup('Nordic');
  AddEncodingOption('Windows-1257', 'WINDOWS1257', 1257, False);
  AddEncodingOption('ISO-8859-4', 'ISO8859_4', 28594, False);
  AddEncodingOption('ISO-8859-10', 'ISO8859_10', 28600, False);
  AddEncodingOption('ISO-8859-13', 'ISO8859_13', 28603, False);
  AddEncodingOption('IBM865', 'IBM865', 865, False);

  // ======================================================================
  // 南欧和地中海编码组
  // ======================================================================
  AddEncodingGroup('Southern');
  AddEncodingOption('Windows-1253', 'WINDOWS1253', 1253, False);
  AddEncodingOption('Windows-1254', 'WINDOWS1254', 1254, False);
  AddEncodingOption('ISO-8859-3', 'ISO8859_3', 28593, False);
  AddEncodingOption('ISO-8859-7', 'ISO8859_7', 28597, False);
  AddEncodingOption('ISO-8859-9', 'ISO8859_9', 28599, False);
  AddEncodingOption('IBM860', 'IBM860', 860, False);

  // ======================================================================
  // 其他特殊编码组
  // ======================================================================
  AddEncodingGroup('Other');
  AddEncodingOption('Windows-1258', 'WINDOWS1258', 1258, False);
  AddEncodingOption('ISO-8859-11', 'ISO8859_11', 28601, False);
  AddEncodingOption('ISO-8859-14', 'ISO8859_14', 28604, False);
  AddEncodingOption('ISO-8859-16', 'ISO8859_16', 28606, False);
  AddEncodingOption('ARMSCII-8', 'ARMSCII_8', 901, False);
  AddEncodingOption('Mongolian', 'MONGOLIAN', 0, False);
  AddEncodingOption('Tibetan', 'TIBETAN', 0, False);
  AddEncodingOption('Lao', 'LAO', 0, False);
  AddEncodingOption('Khmer', 'KHMER', 0, False);
  AddEncodingOption('Myanmar', 'MYANMAR', 0, False);
  AddEncodingOption('Indonesian', 'INDONESIAN', 0, False);
  AddEncodingOption('Malay', 'MALAY', 0, False);
  AddEncodingOption('Geez', 'GEEZ', 0, False);
  AddEncodingOption('Amharic', 'AMHARIC', 0, False);
  AddEncodingOption('CESU-8', 'CESU_8', 0, False);
end;

procedure TEncodingModel.ReplaceEncodingList(const NewList: TEncodingInfoArray);
var
  i: Integer;
begin
  SetLength(FEncodingList, Length(NewList));
  for i := 0 to High(NewList) do
    FEncodingList[i] := NewList[i];
end;

procedure TEncodingModel.ReloadEncodings;
begin
  // 清空当前编码列表
  SetLength(FEncodingList, 0);

  // 重新初始化编码列表
  InitEncodingList;
end;

function TEncodingModel.GetSelectedEncoding: TEncoding;
begin
  // 默认返回UTF8编码
  Result := TEncoding.UTF8;
  
  // 这里可以根据FSelectedEncodingIndex返回不同的编码
  case FSelectedEncodingIndex of
    0: Result := TEncoding.ASCII;
    1: Result := TEncoding.UTF8;
    2: Result := TEncoding.Unicode;
    3: Result := TEncoding.BigEndianUnicode;
    // 可以添加更多编码类型
  end;
end;

end.
