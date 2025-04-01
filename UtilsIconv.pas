unit UtilsIconv;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Math, Winapi.Windows, ModelEncoding, UtilsTypes;

const
  // 返回代码
  ICONV_SUCCESS = 0;
  ICONV_EINVAL = -1;  // 无效的多字节序列
  ICONV_EILSEQ = -2;  // 非法的多字节序列
  ICONV_E2BIG = -3;   // 输出缓冲区不足

type
  // iconv句柄
  iconv_t = Pointer;
  
  // 编码信息结构
  TIconvEncodingInfo = record
    Name: string;          // 编码名称
    IconvName: string;     // iconv使用的编码名
    CodePage: Integer;     // Windows代码页
    Category: TEncodingCategory; // 编码分类
  end;
  
  // iconv工具类
  TIconvHelper = class
  private
    FLibHandle: THandle;
    FIconvOpen: function(tocode, fromcode: PAnsiChar): iconv_t; cdecl;
    FIconvConvert: function(cd: iconv_t; inbuf: PPAnsiChar; inbytesleft: PNativeUInt;
                           outbuf: PPAnsiChar; outbytesleft: PNativeUInt): NativeInt; cdecl;
    FIconvClose: function(cd: iconv_t): Integer; cdecl;
    
    FEncodingList: array of TIconvEncodingInfo;
    
    function LoadIconvLibrary: Boolean;
    procedure InitEncodingList;
    procedure AddEncoding(const Name, IconvName: string; CodePage: Integer; Category: TEncodingCategory = ecOther);
    function TestEncoding(const Buffer: TBytes; const EncodingName: string): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    
    // 检查编码是否被iconv支持
    function IsEncodingSupported(const EncodingName: string): Boolean;
    
    // 获取编码列表
    function GetSupportedEncodings: TArray<TIconvEncodingInfo>;
    
    // 检测文件编码
    function DetectFileEncoding(const FileName: string; 
                               out DetectedEncoding: string): Boolean;
    
    // 转换编码
    function ConvertEncoding(const Source: TBytes; 
                            const FromEncoding, ToEncoding: string;
                            out Destination: TBytes): Boolean;
                            
    // 转换文件编码
    function ConvertFileEncoding(const SourceFile, TargetFile: string;
                               const FromEncoding, ToEncoding: string): Boolean;
  end;

implementation

{$REGION 'Initialization'}
constructor TIconvHelper.Create;
begin
  inherited Create;
  try
    if not LoadIconvLibrary then
    begin
      raise Exception.Create(
        '无法加载iconv库。' + sLineBreak + sLineBreak +
        '请按以下步骤解决：' + sLineBreak +
        '1. 确保libiconv-2.dll文件存在于程序目录' + sLineBreak +
        '2. 或将其放置在系统PATH环境变量包含的目录中' + sLineBreak +
        '3. 如果问题仍然存在，请尝试重新下载并安装libiconv-2.dll' + sLineBreak +
        sLineBreak +
        '您可以从以下地址下载libiconv-2.dll：' + sLineBreak +
        'https://github.com/winlibs/libiconv/releases'
      );
    end;
    
    // 初始化函数指针
    @FIconvOpen := GetProcAddress(FLibHandle, 'libiconv_open');
    @FIconvConvert := GetProcAddress(FLibHandle, 'libiconv');
    @FIconvClose := GetProcAddress(FLibHandle, 'libiconv_close');
    
    if not (Assigned(FIconvOpen) and Assigned(FIconvConvert) and Assigned(FIconvClose)) then
    begin
      raise Exception.Create('无法获取iconv函数地址。错误代码：' + IntToStr(GetLastError));
    end;
    
    // 初始化编码列表
    InitEncodingList;
  except
    on E: Exception do
      raise Exception.Create(
        '初始化编码转换组件失败：' + sLineBreak +
        E.Message
      );
  end;
end;

destructor TIconvHelper.Destroy;
begin
  if FLibHandle <> 0 then
    Winapi.Windows.FreeLibrary(FLibHandle);
  inherited;
end;

function TIconvHelper.LoadIconvLibrary: Boolean;
var
  LibPath: string;
begin
  Result := False;
  try
    // 首先尝试从应用程序目录加载
    LibPath := ExtractFilePath(ParamStr(0)) + 'libiconv-2.dll';
    if FileExists(LibPath) then
    begin
      FLibHandle := LoadLibrary(PChar(LibPath));
      if FLibHandle <> 0 then
      begin
        Result := True;
        Exit;
      end;
    end;

    // 如果失败，尝试从系统路径加载
    FLibHandle := LoadLibrary('libiconv-2.dll');
    Result := (FLibHandle <> 0);
    
    if not Result then
    begin
      case GetLastError of
        ERROR_MOD_NOT_FOUND:
          raise Exception.Create('找不到libiconv-2.dll文件');
        ERROR_BAD_EXE_FORMAT:
          raise Exception.Create('libiconv-2.dll文件格式不正确或与系统不兼容');
        else
          raise Exception.Create('加载libiconv-2.dll失败，错误代码：' + IntToStr(GetLastError));
      end;
    end;
  except
    on E: Exception do
    begin
      FLibHandle := 0;
      raise;
    end;
  end;
end;

procedure TIconvHelper.InitEncodingList;
begin
  // 初始化支持的编码列表
  SetLength(FEncodingList, 0);
  
  // 添加常用编码
  // UTF编码
  AddEncoding('UTF-8', 'UTF-8', 65001, ecUnicode);
  AddEncoding('UTF-16LE', 'UTF-16LE', 1200, ecUnicode);
  AddEncoding('UTF-16BE', 'UTF-16BE', 1201, ecUnicode);
  AddEncoding('UTF-32LE', 'UTF-32LE', 12000, ecUnicode);
  AddEncoding('UTF-32BE', 'UTF-32BE', 12001, ecUnicode);
  
  // 欧洲编码
  AddEncoding('ISO-8859-1', 'ISO-8859-1', 28591, ecEuropean);
  AddEncoding('ISO-8859-2', 'ISO-8859-2', 28592, ecEuropean);
  AddEncoding('ISO-8859-3', 'ISO-8859-3', 28593, ecEuropean);
  AddEncoding('ISO-8859-4', 'ISO-8859-4', 28594, ecEuropean);
  AddEncoding('ISO-8859-5', 'ISO-8859-5', 28595, ecCyrillic);
  AddEncoding('ISO-8859-6', 'ISO-8859-6', 28596, ecMiddleEast);
  AddEncoding('ISO-8859-7', 'ISO-8859-7', 28597, ecEuropean);
  AddEncoding('ISO-8859-8', 'ISO-8859-8', 28598, ecMiddleEast);
  AddEncoding('ISO-8859-9', 'ISO-8859-9', 28599, ecEuropean);
  AddEncoding('ISO-8859-10', 'ISO-8859-10', 28600, ecEuropean);
  AddEncoding('ISO-8859-13', 'ISO-8859-13', 28603, ecEuropean);
  AddEncoding('ISO-8859-14', 'ISO-8859-14', 28604, ecEuropean);
  AddEncoding('ISO-8859-15', 'ISO-8859-15', 28605, ecEuropean);
  AddEncoding('ISO-8859-16', 'ISO-8859-16', 28606, ecEuropean);
  AddEncoding('Windows-1250', 'CP1250', 1250, ecEuropean);
  AddEncoding('Windows-1251', 'CP1251', 1251, ecCyrillic);
  AddEncoding('Windows-1252', 'CP1252', 1252, ecEuropean);
  AddEncoding('Windows-1253', 'CP1253', 1253, ecEuropean);
  AddEncoding('Windows-1254', 'CP1254', 1254, ecMiddleEast);
  AddEncoding('Windows-1255', 'CP1255', 1255, ecMiddleEast);
  AddEncoding('Windows-1256', 'CP1256', 1256, ecMiddleEast);
  AddEncoding('Windows-1257', 'CP1257', 1257, ecEuropean);
  AddEncoding('Windows-1258', 'CP1258', 1258, ecSouthEastAsian);
  AddEncoding('KOI8-R', 'KOI8-R', 20866, ecCyrillic);
  AddEncoding('KOI8-U', 'KOI8-U', 21866, ecCyrillic);
  
  // 亚洲编码
  AddEncoding('GB2312', 'GB2312', 936, ecEastAsian);
  AddEncoding('GBK', 'GBK', 936, ecEastAsian);
  AddEncoding('GB18030', 'GB18030', 54936, ecEastAsian);
  AddEncoding('Big5', 'BIG5', 950, ecEastAsian);
  AddEncoding('Shift-JIS', 'SHIFT-JIS', 932, ecEastAsian);
  AddEncoding('EUC-JP', 'EUC-JP', 51932, ecEastAsian);
  AddEncoding('EUC-KR', 'EUC-KR', 51949, ecEastAsian);
  AddEncoding('CP949', 'CP949', 949, ecEastAsian);
  AddEncoding('ISO-2022-JP', 'ISO-2022-JP', 50220, ecEastAsian);
  AddEncoding('ISO-2022-KR', 'ISO-2022-KR', 50225, ecEastAsian);
  AddEncoding('ISO-2022-CN', 'ISO-2022-CN', 50227, ecEastAsian);
  
  // 其他编码
  AddEncoding('CP437', 'CP437', 437, ecOther);
  AddEncoding('CP850', 'CP850', 850, ecOther);
  AddEncoding('CP866', 'CP866', 866, ecCyrillic);
  AddEncoding('KZ-1048', 'KZ-1048', 1048, ecCyrillic);
  AddEncoding('MacCyrillic', 'MACCYRILLIC', 10007, ecCyrillic);
  AddEncoding('MacRoman', 'MACROMAN', 10000, ecEuropean);
  
  // 添加中东语言编码
  AddEncoding('Windows-1256', 'CP1256', 1256, ecMiddleEast);  // 阿拉伯文
  AddEncoding('ISO-8859-6', 'ISO-8859-6', 28596, ecMiddleEast);  // 阿拉伯文
  AddEncoding('MacArabic', 'MACARABIC', 10004, ecMiddleEast);  // 阿拉伯文
  AddEncoding('Windows-1255', 'CP1255', 1255, ecMiddleEast);  // 希伯来文
  AddEncoding('ISO-8859-8', 'ISO-8859-8', 28598, ecMiddleEast);  // 希伯来文
  AddEncoding('MacHebrew', 'MACHEBREW', 10005, ecMiddleEast);  // 希伯来文
  AddEncoding('ISO-8859-9', 'ISO-8859-9', 28599, ecMiddleEast);  // 土耳其文
  AddEncoding('Windows-1254', 'CP1254', 1254, ecMiddleEast);  // 土耳其文
  AddEncoding('CP720', 'CP720', 720, ecMiddleEast);  // 阿拉伯DOS编码
  AddEncoding('CP864', 'CP864', 864, ecMiddleEast);  // 阿拉伯文DOS编码
  AddEncoding('CP862', 'CP862', 862, ecMiddleEast);  // 希伯来文DOS编码
  
  // 添加印度语系编码
  AddEncoding('ISCII-Devanagari', 'ISCII-DEV', 57002, ecSouthAsian);  // 梵文
  AddEncoding('ISCII-Bengali', 'ISCII-BNG', 57003, ecSouthAsian);  // 孟加拉文
  AddEncoding('ISCII-Tamil', 'ISCII-TML', 57004, ecSouthAsian);  // 泰米尔文
  AddEncoding('ISCII-Telugu', 'ISCII-TLG', 57005, ecSouthAsian);  // 泰卢固文
  AddEncoding('ISCII-Assamese', 'ISCII-ASM', 57006, ecSouthAsian);  // 阿萨姆文
  AddEncoding('ISCII-Oriya', 'ISCII-ORI', 57007, ecSouthAsian);  // 奥里亚文
  AddEncoding('ISCII-Kannada', 'ISCII-KND', 57008, ecSouthAsian);  // 卡纳达文
  AddEncoding('ISCII-Malayalam', 'ISCII-MLM', 57009, ecSouthAsian);  // 马拉雅拉姆文
  AddEncoding('ISCII-Gujarati', 'ISCII-GJR', 57010, ecSouthAsian);  // 古吉拉特文
  AddEncoding('ISCII-Punjabi', 'ISCII-PNJ', 57011, ecSouthAsian);  // 旁遮普文
  AddEncoding('TSCII', 'TSCII', 57012, ecSouthAsian);  // 泰米尔标准编码
  
  // 添加越南文编码
  AddEncoding('VISCII', 'VISCII', 30000, ecSouthEastAsian);  // 越南标准编码
  AddEncoding('VPS', 'VPS', 30001, ecSouthEastAsian);  // 越南DOS编码
  AddEncoding('TCVN-5712', 'TCVN-5712', 30002, ecSouthEastAsian);  // 越南标准编码
  AddEncoding('Windows-1258', 'CP1258', 1258, ecSouthEastAsian);  // 越南Windows编码
  
  // 添加更多特殊编码
  AddEncoding('ARMSCII-8', 'ARMSCII-8', 34010, ecOther);  // 亚美尼亚文
  AddEncoding('GEOSTD8', 'GEOSTD8', 34011, ecOther);  // 格鲁吉亚文
  AddEncoding('PT154', 'PT154', 34012, ecCyrillic);  // 哈萨克斯坦
  AddEncoding('TIS-620', 'TIS-620', 874, ecSouthEastAsian);  // 泰文
  AddEncoding('MuleLao-1', 'MULELAO-1', 34013, ecSouthEastAsian);  // 老挝文
  AddEncoding('CP1133', 'CP1133', 1133, ecSouthEastAsian);  // 老挝文DOS编码
  AddEncoding('MacThai', 'MACTHAI', 10021, ecSouthEastAsian);  // 泰文Mac编码
  AddEncoding('KOI8-T', 'KOI8-T', 20866, ecCyrillic);  // 塔吉克文
  AddEncoding('IBM424', 'CP424', 424, ecMiddleEast);  // 希伯来文EBCDIC
  AddEncoding('IBM420', 'CP420', 420, ecMiddleEast);  // 阿拉伯文EBCDIC
end;

procedure TIconvHelper.AddEncoding(const Name, IconvName: string; CodePage: Integer; Category: TEncodingCategory = ecOther);
var
  Info: TIconvEncodingInfo;
  Len: Integer;
begin
  Info.Name := Name;
  Info.IconvName := IconvName;
  Info.CodePage := CodePage;
  Info.Category := Category;
  
  Len := Length(FEncodingList);
  SetLength(FEncodingList, Len + 1);
  FEncodingList[Len] := Info;
end;
{$ENDREGION}

{$REGION 'Public Methods'}
function TIconvHelper.IsEncodingSupported(const EncodingName: string): Boolean;
var
  cd: iconv_t;
  FromEncoding, ToEncoding: AnsiString;
begin
  if FLibHandle = 0 then
    Exit(False);
    
  // 尝试打开一个编码转换器来检查支持
  FromEncoding := 'UTF-8';
  ToEncoding := AnsiString(EncodingName);
  
  cd := FIconvOpen(PAnsiChar(ToEncoding), PAnsiChar(FromEncoding));
  Result := cd <> Pointer(-1);
  
  if Result then
    FIconvClose(cd);
end;

function TIconvHelper.GetSupportedEncodings: TArray<TIconvEncodingInfo>;
begin
  SetLength(Result, Length(FEncodingList));
  if Length(FEncodingList) > 0 then
    Move(FEncodingList[0], Result[0], Length(FEncodingList) * SizeOf(TIconvEncodingInfo));
end;

function TIconvHelper.DetectFileEncoding(const FileName: string;
                                       out DetectedEncoding: string): Boolean;
var
  Stream: TFileStream;
  Buffer: TBytes;
  i: Integer;
  TestBytes: Integer;
  ErrorCount: Integer;
  BestEncoding: string;
  LeastErrors: Integer;
begin
  Result := False;
  DetectedEncoding := '';
  
  if not FileExists(FileName) then
    Exit;
    
  // 读取文件前4KB用于检测
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    TestBytes := System.Math.Min(Stream.Size, 4096);
    SetLength(Buffer, TestBytes);
    if TestBytes > 0 then
      Stream.ReadBuffer(Buffer[0], TestBytes);
  finally
    Stream.Free;
  end;
  
  // 首先检查BOM
  if TestBytes >= 3 then
  begin
    if (Buffer[0] = $EF) and (Buffer[1] = $BB) and (Buffer[2] = $BF) then
    begin
      DetectedEncoding := 'UTF-8';
      Exit(True);
    end
    else if (TestBytes >= 2) and (Buffer[0] = $FE) and (Buffer[1] = $FF) then
    begin
      DetectedEncoding := 'UTF-16BE';
      Exit(True);
    end
    else if (TestBytes >= 2) and (Buffer[0] = $FF) and (Buffer[1] = $FE) then
    begin
      if (TestBytes >= 4) and (Buffer[2] = 0) and (Buffer[3] = 0) then
      begin
        DetectedEncoding := 'UTF-32LE';
        Exit(True);
      end
      else
      begin
        DetectedEncoding := 'UTF-16LE';
        Exit(True);
      end;
    end;
  end;
  
  // 尝试不同编码，选择错误最少的
  LeastErrors := High(Integer);
  BestEncoding := '';
  
  for i := 0 to High(FEncodingList) do
  begin
    ErrorCount := TestEncoding(Buffer, FEncodingList[i].IconvName);
    if ErrorCount < LeastErrors then
    begin
      LeastErrors := ErrorCount;
      BestEncoding := FEncodingList[i].Name;
      
      // 如果完全没有错误，就选择这个编码
      if ErrorCount = 0 then
        Break;
    end;
  end;
  
  if BestEncoding <> '' then
  begin
    DetectedEncoding := BestEncoding;
    Result := True;
  end;
end;

function TIconvHelper.TestEncoding(const Buffer: TBytes; const EncodingName: string): Integer;
var
  cd: iconv_t;
  SrcBuf, DestBuf: TBytes;
  SrcPtr, DestPtr: PAnsiChar;
  SrcLeft, DestLeft: NativeUInt;
  DestSize: NativeUInt;
  PSrcPtr, PDestPtr: PPAnsiChar;
  ConvResult: NativeInt;
  ErrorCount: Integer;
begin
  Result := High(Integer); // 默认返回最大错误数
  
  if (FLibHandle = 0) or (Length(Buffer) = 0) then
    Exit;
  
  // 创建从指定编码到UTF-8的转换器
  cd := FIconvOpen(PAnsiChar(AnsiString('UTF-8')), PAnsiChar(AnsiString(EncodingName)));
  if cd = Pointer(-1) then
    Exit;
  
  try
    // 准备缓冲区
    SrcBuf := Buffer;
    SrcLeft := Length(SrcBuf);
    DestSize := SrcLeft * 4; // 确保足够大
    SetLength(DestBuf, DestSize);
    DestLeft := DestSize;
    
    SrcPtr := PAnsiChar(@SrcBuf[0]);
    DestPtr := PAnsiChar(@DestBuf[0]);
    PSrcPtr := @SrcPtr;
    PDestPtr := @DestPtr;
    
    // 重置转换器状态
    FIconvConvert(cd, nil, nil, nil, nil);
    
    // 尝试转换并计算错误数
    ErrorCount := 0;
    while SrcLeft > 0 do
    begin
      ConvResult := FIconvConvert(cd, PSrcPtr, @SrcLeft, PDestPtr, @DestLeft);
      
      if ConvResult = NativeInt(-1) then
      begin
        Inc(ErrorCount);
        // 跳过错误字符
        Inc(SrcPtr);
        Dec(SrcLeft);
        PSrcPtr := @SrcPtr;
      end
      else if SrcLeft = 0 then
        Break;
    end;
    
    Result := ErrorCount;
  finally
    FIconvClose(cd);
  end;
end;

function TIconvHelper.ConvertEncoding(const Source: TBytes;
                                    const FromEncoding, ToEncoding: string;
                                    out Destination: TBytes): Boolean;
var
  cd: iconv_t;
  SrcPtr, DestPtr: PAnsiChar;
  SrcLeft, DestLeft, DestSize: NativeUInt;
  PSrcPtr, PDestPtr: PPAnsiChar;
  ConvResult: NativeInt;
  FromEnc, ToEnc: AnsiString;
begin
  Result := False;
  SetLength(Destination, 0);
  
  if (FLibHandle = 0) or (Length(Source) = 0) then
    Exit;
  
  // 准备编码名称
  FromEnc := AnsiString(FromEncoding);
  ToEnc := AnsiString(ToEncoding);
  
  // 创建转换器
  cd := FIconvOpen(PAnsiChar(ToEnc), PAnsiChar(FromEnc));
  if cd = Pointer(-1) then
    Exit;
  
  try
    // 准备缓冲区
    SrcLeft := Length(Source);
    DestSize := SrcLeft * 4; // 确保足够大
    SetLength(Destination, DestSize);
    DestLeft := DestSize;
    
    SrcPtr := PAnsiChar(@Source[0]);
    DestPtr := PAnsiChar(@Destination[0]);
    PSrcPtr := @SrcPtr;
    PDestPtr := @DestPtr;
    
    // 重置转换器状态
    FIconvConvert(cd, nil, nil, nil, nil);
    
    // 执行转换
    ConvResult := FIconvConvert(cd, PSrcPtr, @SrcLeft, PDestPtr, @DestLeft);
    
    if (ConvResult = 0) or (ConvResult = ICONV_E2BIG) then
    begin
      // 成功转换或输出缓冲区不足
      // 调整输出缓冲区大小
      SetLength(Destination, DestSize - DestLeft);
      Result := True;
    end;
  finally
    FIconvClose(cd);
  end;
end;

function TIconvHelper.ConvertFileEncoding(const SourceFile, TargetFile: string;
                                       const FromEncoding, ToEncoding: string): Boolean;
var
  Source, Destination: TBytes;
begin
  Result := False;
  
  if not FileExists(SourceFile) then
    Exit;
  
  try
    // 读取源文件
    Source := TFile.ReadAllBytes(SourceFile);
    
    // 转换编码
    if not ConvertEncoding(Source, FromEncoding, ToEncoding, Destination) then
      Exit;
    
    // 写入目标文件
    TFile.WriteAllBytes(TargetFile, Destination);
    Result := True;
  except
    Result := False;
  end;
end;
{$ENDREGION}

end. 