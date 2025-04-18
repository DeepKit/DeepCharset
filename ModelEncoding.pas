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
begin
  EncodingInfo.Name := GroupName;
  EncodingInfo.CodePage := -999; // 特殊标记
  EncodingInfo.HasBOM := False;
  EncodingInfo.ShortName := '';
  EncodingInfo.IsGroup := True;

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

  // --- NEW Categorized List with Descriptions (Ordered as UTF, Asia, Regions, Other) ---

  // --- 1. UTF 相关 ---
  AddEncodingGroup('UTF');
  AddEncodingOption('UTF-8', 'UTF-8', 65001, False, 'UTF-8 - ' + GetString('EncUTF8Desc'));
  AddEncodingOption('UTF-8 BOM', 'UTF-8 BOM', 65001, True, 'UTF-8 BOM - ' + GetString('EncUTF8BOMDesc'));
  AddEncodingOption('UTF-16LE', 'UTF-16LE', 1200, True, 'UTF-16LE - ' + GetString('EncUTF16LEDesc'));
  AddEncodingOption('UTF-16BE', 'UTF-16BE', 1201, True, 'UTF-16BE - ' + GetString('EncUTF16BEDesc'));
  AddEncodingOption('UTF-16', 'UTF-16', 1200, True, 'UTF-16 - ' + GetString('EncUTF16Desc'));
  AddEncodingOption('UTF-32LE', 'UTF-32LE', 12000, True, 'UTF-32LE - ' + GetString('EncUTF32LEDesc'));
  AddEncodingOption('UTF-32BE', 'UTF-32BE', 12001, True, 'UTF-32BE - ' + GetString('EncUTF32BEDesc'));
  AddEncodingOption('UTF-32', 'UTF-32', 12000, True, 'UTF-32 - ' + GetString('EncUTF32Desc'));
  AddEncodingOption('UTF-7', 'UTF-7', 65000, False, 'UTF-7 - ' + GetString('EncUTF7Desc'));
  AddEncodingOption('UCS-2', 'UCS-2', 1200, False, 'UCS-2 - ' + GetString('EncUCS2Desc'));
  AddEncodingOption('UCS-4LE', 'UCS-4LE', 12000, False, 'UCS-4LE - ' + GetString('EncUCS4LEDesc'));
  AddEncodingOption('UCS-4BE', 'UCS-4BE', 12001, False, 'UCS-4BE - ' + GetString('EncUCS4BEDesc'));

  // --- 2. 亚洲 ---
  AddEncodingGroup('Asia');
  AddEncodingOption('GB2312', 'GB2312', 936, False, 'GB2312 - ' + GetString('EncGB2312Desc'));
  AddEncodingOption('GBK', 'GBK', 936, False, 'GBK - ' + GetString('EncGBKDesc'));
  AddEncodingOption('GB18030', 'GB18030', 54936, False, 'GB18030 - ' + GetString('EncGB18030Desc'));
  AddEncodingOption('Big5', 'BIG5', 950, False, 'Big5 - ' + GetString('EncBig5Desc'));
  AddEncodingOption('Big5-HKSCS', 'BIG5-HKSCS', 950, False, 'Big5-HKSCS - ' + GetString('EncBig5HKSCSDesc'));
  AddEncodingOption('Shift_JIS', 'SHIFT_JIS', 932, False, 'Shift_JIS - ' + GetString('EncShiftJISDesc'));
  AddEncodingOption('EUC-JP', 'EUC-JP', 20932, False, 'EUC-JP - ' + GetString('EncEUCJPDesc'));
  AddEncodingOption('ISO-2022-JP', 'ISO-2022-JP', 50220, False, 'ISO-2022-JP - ' + GetString('EncISO2022JPDesc'));
  AddEncodingOption('ISO-2022-JP-2', 'ISO-2022-JP-2', 50222, False, 'ISO-2022-JP-2 - ' + GetString('EncISO2022JP2Desc'));
  AddEncodingOption('EUC-KR', 'EUC-KR', 949, False, 'EUC-KR - ' + GetString('EncEUCKRDesc'));
  AddEncodingOption('TIS-620', 'TIS-620', 874, False, 'TIS-620 - Thai character encoding');
  AddEncodingOption('VISCII', 'VISCII', 0, False, 'VISCII - Vietnamese character encoding');

  // --- 3. Windows (代码页) ---
  AddEncodingGroup('Windows');
  AddEncodingOption('Windows-1250', 'CP1250', 1250, False, 'Windows-1250 - 中欧语言编码');
  AddEncodingOption('Windows-1251', 'CP1251', 1251, False, 'Windows-1251 - 西里尔文编码，俄语等');
  AddEncodingOption('Windows-1252', 'CP1252', 1252, False, 'Windows-1252 - 西欧语言编码');
  AddEncodingOption('Windows-1253', 'CP1253', 1253, False, 'Windows-1253 - 希腊文编码');
  AddEncodingOption('Windows-1254', 'CP1254', 1254, False, 'Windows-1254 - 土耳其文编码');
  AddEncodingOption('Windows-1255', 'CP1255', 1255, False, 'Windows-1255 - 希伯来文编码');
  AddEncodingOption('Windows-1256', 'CP1256', 1256, False, 'Windows-1256 - 阿拉伯文编码');
  AddEncodingOption('Windows-1257', 'CP1257', 1257, False, 'Windows-1257 - 波罗的海文编码');
  AddEncodingOption('Windows-1258', 'CP1258', 1258, False, 'Windows-1258 - 越南文编码');
  AddEncodingOption('Windows-874', 'CP874', 874, False, 'Windows-874 - 泰文编码');

  // --- 4. ISO-8859 ---
  AddEncodingGroup('ISO-8859');
  AddEncodingOption('ISO-8859-1 (Latin-1)', 'ISO-8859-1', 28591, False);
  AddEncodingOption('ISO-8859-2 (Latin-2)', 'ISO-8859-2', 28592, False);
  AddEncodingOption('ISO-8859-3 (Latin-3)', 'ISO-8859-3', 28593, False);
  AddEncodingOption('ISO-8859-4 (Latin-4)', 'ISO-8859-4', 28594, False);
  AddEncodingOption('ISO-8859-5', 'ISO-8859-5', 28595, False);
  AddEncodingOption('ISO-8859-6', 'ISO-8859-6', 28596, False);
  AddEncodingOption('ISO-8859-7', 'ISO-8859-7', 28597, False);
  AddEncodingOption('ISO-8859-8', 'ISO-8859-8', 28598, False);
  AddEncodingOption('ISO-8859-9 (Latin-5)', 'ISO-8859-9', 28599, False);
  AddEncodingOption('ISO-8859-10 (Latin-6)', 'ISO-8859-10', 28600, False);
  AddEncodingOption('ISO-8859-13 (Latin-7)', 'ISO-8859-13', 28603, False);
  AddEncodingOption('ISO-8859-14 (Latin-8)', 'ISO-8859-14', 28604, False);
  AddEncodingOption('ISO-8859-15 (Latin-9)', 'ISO-8859-15', 28605, False);
  AddEncodingOption('ISO-8859-16 (Latin-10)', 'ISO-8859-16', 28606, False);

  // --- 5. IBM/DOS/EBCDIC ---
  AddEncodingGroup('IBM/DOS');
  AddEncodingOption('IBM437 / CP437', 'CP437', 437, False);
  AddEncodingOption('IBM850 / CP850', 'CP850', 850, False);
  AddEncodingOption('IBM852 / CP852', 'CP852', 852, False);
  AddEncodingOption('IBM855 / CP855', 'CP855', 855, False);
  AddEncodingOption('IBM857 / CP857', 'CP857', 857, False);
  AddEncodingOption('IBM862 / CP862', 'CP862', 862, False);
  AddEncodingOption('IBM866 / CP866', 'CP866', 866, False);
  AddEncodingOption('CP866NAV', 'CP866NAV', 0, False);
  AddEncodingOption('IBM037', 'IBM037', 37, False);
  AddEncodingOption('IBM273', 'IBM273', 20273, False);
  AddEncodingOption('IBM500', 'IBM500', 500, False);
  AddEncodingOption('IBM870', 'IBM870', 870, False);
  AddEncodingOption('IBM1047', 'IBM1047', 1047, False);

  // --- 6. KOI8 ---
  AddEncodingGroup('KOI8');
  AddEncodingOption('KOI8-R', 'KOI8-R', 20866, False);
  AddEncodingOption('KOI8-U', 'KOI8-U', 21866, False);
  AddEncodingOption('KOI8-T', 'KOI8-T', 0, False);

  // --- 7. Mac ---
  AddEncodingGroup('Mac');
  AddEncodingOption('MacRoman', 'MACROMAN', 10000, False);
  AddEncodingOption('MacCyrillic', 'MACCYRILLIC', 10007, False);
  AddEncodingOption('MacGreek', 'MACGREEK', 10006, False);
  AddEncodingOption('MacTurkish', 'MACTURKISH', 10081, False);
  AddEncodingOption('MacCentralEurope', 'MACCE', 10029, False);
  AddEncodingOption('MacIceland', 'MACICELAND', 10079, False);

  // --- 8. 其他 ---
  AddEncodingGroup('Other');
  AddEncodingOption('ASCII', 'ASCII', 20127, False, 'ASCII - 美国标准信息交换码，7位编码');
  AddEncodingOption('ARMSCII-8', 'ARMSCII-8', 0, False, 'ARMSCII-8 - 亚美尼亚文字编码');
  AddEncodingOption('ATARIST', 'ATARIST', 0, False, 'ATARIST - Atari ST计算机编码');
  AddEncodingOption('HP Roman8', 'HP-ROMAN8', 0, False, 'HP Roman8 - 惠普打印机编码');
  AddEncodingOption('TRANSLIT', 'TRANSLIT', 0, False, 'TRANSLIT - 音译转换标志'); // Special iconv flag

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