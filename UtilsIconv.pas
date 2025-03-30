unit UtilsIconv;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Math, Winapi.Windows;

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
    
    function LoadLibrary: Boolean;
    procedure InitEncodingList;
    procedure AddEncoding(const Name, IconvName: string; CodePage: Integer);
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
  FLibHandle := 0;
  LoadLibrary;
  InitEncodingList;
end;

destructor TIconvHelper.Destroy;
begin
  if FLibHandle <> 0 then
    Winapi.Windows.FreeLibrary(FLibHandle);
  inherited;
end;

function TIconvHelper.LoadLibrary: Boolean;
const
  // 尝试查找的DLL名称列表
  DLL_NAMES: array[0..3] of string = (
    'libiconv-2.dll',    // 常见名称
    'libiconv.dll',      // 另一个常见名称
    'iconv.dll',         // 简化名称
    'libiconv-x64.dll'   // 64位版本可能名称
  );
var
  i: Integer;
  DllPath: string;
begin
  Result := False;
  
  // 尝试在应用程序目录和系统目录查找DLL
  for i := Low(DLL_NAMES) to High(DLL_NAMES) do
  begin
    // 应用程序目录
    DllPath := ExtractFilePath(ParamStr(0)) + DLL_NAMES[i];
    if FileExists(DllPath) then
    begin
      FLibHandle := Winapi.Windows.LoadLibrary(PChar(DllPath));
      if FLibHandle <> 0 then
        Break;
    end;
    
    // 系统目录
    FLibHandle := Winapi.Windows.LoadLibrary(PChar(DLL_NAMES[i]));
    if FLibHandle <> 0 then
      Break;
  end;
  
  if FLibHandle <> 0 then
  begin
    // 获取函数地址
    @FIconvOpen := GetProcAddress(FLibHandle, 'libiconv_open');
    @FIconvConvert := GetProcAddress(FLibHandle, 'libiconv');
    @FIconvClose := GetProcAddress(FLibHandle, 'libiconv_close');
    
    Result := Assigned(FIconvOpen) and Assigned(FIconvConvert) and Assigned(FIconvClose);
  end;
  
  if not Result then
    raise Exception.Create('无法加载iconv库。请确保libiconv-2.dll或兼容库文件存在于应用程序目录或系统路径中。');
end;

procedure TIconvHelper.InitEncodingList;
begin
  // 初始化支持的编码列表
  SetLength(FEncodingList, 0);
  
  // 添加常用编码
  // UTF编码
  AddEncoding('UTF-8', 'UTF-8', 65001);
  AddEncoding('UTF-16LE', 'UTF-16LE', 1200);
  AddEncoding('UTF-16BE', 'UTF-16BE', 1201);
  AddEncoding('UTF-32LE', 'UTF-32LE', 12000);
  AddEncoding('UTF-32BE', 'UTF-32BE', 12001);
  
  // 欧洲编码
  AddEncoding('ISO-8859-1', 'ISO-8859-1', 28591);
  AddEncoding('ISO-8859-2', 'ISO-8859-2', 28592);
  AddEncoding('ISO-8859-3', 'ISO-8859-3', 28593);
  AddEncoding('ISO-8859-4', 'ISO-8859-4', 28594);
  AddEncoding('ISO-8859-5', 'ISO-8859-5', 28595);
  AddEncoding('ISO-8859-6', 'ISO-8859-6', 28596);
  AddEncoding('ISO-8859-7', 'ISO-8859-7', 28597);
  AddEncoding('ISO-8859-8', 'ISO-8859-8', 28598);
  AddEncoding('ISO-8859-9', 'ISO-8859-9', 28599);
  AddEncoding('ISO-8859-10', 'ISO-8859-10', 28600);
  AddEncoding('ISO-8859-13', 'ISO-8859-13', 28603);
  AddEncoding('ISO-8859-14', 'ISO-8859-14', 28604);
  AddEncoding('ISO-8859-15', 'ISO-8859-15', 28605);
  AddEncoding('ISO-8859-16', 'ISO-8859-16', 28606);
  AddEncoding('Windows-1250', 'CP1250', 1250);
  AddEncoding('Windows-1251', 'CP1251', 1251);
  AddEncoding('Windows-1252', 'CP1252', 1252);
  AddEncoding('Windows-1253', 'CP1253', 1253);
  AddEncoding('Windows-1254', 'CP1254', 1254);
  AddEncoding('Windows-1255', 'CP1255', 1255);
  AddEncoding('Windows-1256', 'CP1256', 1256);
  AddEncoding('Windows-1257', 'CP1257', 1257);
  AddEncoding('Windows-1258', 'CP1258', 1258);
  AddEncoding('KOI8-R', 'KOI8-R', 20866);
  AddEncoding('KOI8-U', 'KOI8-U', 21866);
  
  // 亚洲编码
  AddEncoding('GB2312', 'GB2312', 936);
  AddEncoding('GBK', 'GBK', 936);
  AddEncoding('GB18030', 'GB18030', 54936);
  AddEncoding('Big5', 'BIG5', 950);
  AddEncoding('Shift-JIS', 'SHIFT-JIS', 932);
  AddEncoding('EUC-JP', 'EUC-JP', 51932);
  AddEncoding('EUC-KR', 'EUC-KR', 51949);
  AddEncoding('CP949', 'CP949', 949);
  AddEncoding('ISO-2022-JP', 'ISO-2022-JP', 50220);
  AddEncoding('ISO-2022-KR', 'ISO-2022-KR', 50225);
  AddEncoding('ISO-2022-CN', 'ISO-2022-CN', 50227);
  
  // 其他编码
  AddEncoding('CP437', 'CP437', 437);
  AddEncoding('CP850', 'CP850', 850);
  AddEncoding('CP866', 'CP866', 866);
  AddEncoding('KZ-1048', 'KZ-1048', 1048);
  AddEncoding('MacCyrillic', 'MACCYRILLIC', 10007);
  AddEncoding('MacRoman', 'MACROMAN', 10000);
end;

procedure TIconvHelper.AddEncoding(const Name, IconvName: string; CodePage: Integer);
var
  Info: TIconvEncodingInfo;
  Len: Integer;
begin
  Info.Name := Name;
  Info.IconvName := IconvName;
  Info.CodePage := CodePage;
  
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
  cd: iconv_t;
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