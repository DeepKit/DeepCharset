program EncodingTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Winapi.Windows;

type
  UErrorCode = Integer;
  UCharsetDetector = Pointer;
  UCharsetMatch = Pointer;

  Tu_errorName = function(code: UErrorCode): PAnsiChar; cdecl;
  Tucsdet_open = function(out status: UErrorCode): UCharsetDetector; cdecl;
  Tucsdet_close = procedure(ucsd: UCharsetDetector); cdecl;
  Tucsdet_setText = procedure(ucsd: UCharsetDetector; textIn: PAnsiChar; len: Integer; out status: UErrorCode); cdecl;
  Tucsdet_detect = function(ucsd: UCharsetDetector; out status: UErrorCode): UCharsetMatch; cdecl;
  Tucsdet_getName = function(ucsm: UCharsetMatch; out status: UErrorCode): PAnsiChar; cdecl;
  Tucsdet_getConfidence = function(ucsm: UCharsetMatch; out status: UErrorCode): Integer; cdecl;

var
  u_errorName: Tu_errorName;
  ucsdet_open: Tucsdet_open;
  ucsdet_close: Tucsdet_close;
  ucsdet_setText: Tucsdet_setText;
  ucsdet_detect: Tucsdet_detect;
  ucsdet_getName: Tucsdet_getName;
  ucsdet_getConfidence: Tucsdet_getConfidence;
  
  IcuucDllHandle: HMODULE;
  IcuinDllHandle: HMODULE;
  IcudtDllHandle: HMODULE;

function GetLastErrorMessage: string;
var
  ErrorCode: DWORD;
  Buffer: array[0..1023] of Char;
begin
  ErrorCode := GetLastError;
  if ErrorCode = 0 then
    Result := '没有错误'
  else
  begin
    FormatMessage(
      FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_IGNORE_INSERTS,
      nil, ErrorCode, 0, Buffer, Length(Buffer), nil);
    Result := Format('错误代码: %d - %s', [ErrorCode, Buffer]);
  end;
end;

function LoadICULibraries: Boolean;
begin
  Result := False;
  
  // 第一步：尝试加载icuuc77.dll
  Writeln('正在加载 icuuc77.dll...');
  IcuucDllHandle := LoadLibrary('icuuc77.dll');
  if IcuucDllHandle = 0 then
  begin
    Writeln('无法加载 icuuc77.dll: ', GetLastErrorMessage);
    Exit;
  end;
  Writeln('icuuc77.dll 加载成功');
  
  // 第二步：尝试加载icuin77.dll
  Writeln('正在加载 icuin77.dll...');
  IcuinDllHandle := LoadLibrary('icuin77.dll');
  if IcuinDllHandle = 0 then
  begin
    Writeln('无法加载 icuin77.dll: ', GetLastErrorMessage);
    FreeLibrary(IcuucDllHandle);
    Exit;
  end;
  Writeln('icuin77.dll 加载成功');
  
  // 第三步：尝试加载icudt77.dll
  Writeln('正在加载 icudt77.dll...');
  IcudtDllHandle := LoadLibrary('icudt77.dll');
  if IcudtDllHandle = 0 then
  begin
    Writeln('无法加载 icudt77.dll: ', GetLastErrorMessage);
    FreeLibrary(IcuucDllHandle);
    FreeLibrary(IcuinDllHandle);
    Exit;
  end;
  Writeln('icudt77.dll 加载成功');
  
  // 获取函数地址
  Writeln('获取函数地址...');
  
  // 错误处理函数
  u_errorName := GetProcAddress(IcuucDllHandle, 'u_errorName');
  if not Assigned(u_errorName) then
  begin
    Writeln('警告: 无法获取 u_errorName 函数: ', GetLastErrorMessage);
  end;
  
  // 编码检测函数
  ucsdet_open := GetProcAddress(IcuinDllHandle, 'ucsdet_open');
  if not Assigned(ucsdet_open) then
  begin
    Writeln('错误: 无法获取 ucsdet_open 函数: ', GetLastErrorMessage);
    Exit;
  end;
  
  ucsdet_close := GetProcAddress(IcuinDllHandle, 'ucsdet_close');
  if not Assigned(ucsdet_close) then
  begin
    Writeln('错误: 无法获取 ucsdet_close 函数: ', GetLastErrorMessage);
    Exit;
  end;
  
  ucsdet_setText := GetProcAddress(IcuinDllHandle, 'ucsdet_setText');
  if not Assigned(ucsdet_setText) then
  begin
    Writeln('错误: 无法获取 ucsdet_setText 函数: ', GetLastErrorMessage);
    Exit;
  end;
  
  ucsdet_detect := GetProcAddress(IcuinDllHandle, 'ucsdet_detect');
  if not Assigned(ucsdet_detect) then
  begin
    Writeln('错误: 无法获取 ucsdet_detect 函数: ', GetLastErrorMessage);
    Exit;
  end;
  
  ucsdet_getName := GetProcAddress(IcuinDllHandle, 'ucsdet_getName');
  if not Assigned(ucsdet_getName) then
  begin
    Writeln('错误: 无法获取 ucsdet_getName 函数: ', GetLastErrorMessage);
    Exit;
  end;
  
  ucsdet_getConfidence := GetProcAddress(IcuinDllHandle, 'ucsdet_getConfidence');
  if not Assigned(ucsdet_getConfidence) then
  begin
    Writeln('错误: 无法获取 ucsdet_getConfidence 函数: ', GetLastErrorMessage);
    Exit;
  end;
  
  Result := True;
end;

procedure FreeICULibraries;
begin
  if IcudtDllHandle <> 0 then
    FreeLibrary(IcudtDllHandle);
  if IcuinDllHandle <> 0 then
    FreeLibrary(IcuinDllHandle);
  if IcuucDllHandle <> 0 then
    FreeLibrary(IcuucDllHandle);
end;

function CheckICUError(const Context: string; ErrorCode: UErrorCode): Boolean;
var
  ErrorName: string;
begin
  Result := (ErrorCode <= 0);  // 成功时ErrorCode <= 0
  
  if not Result then
  begin
    if Assigned(u_errorName) then
      ErrorName := string(u_errorName(ErrorCode))
    else
      ErrorName := IntToStr(ErrorCode);
    
    Writeln('ICU错误: ', Context, ' - ', ErrorName, ' (', ErrorCode, ')');
  end;
end;

function DetectTextEncoding(const Text: TBytes): string;
var
  Status: UErrorCode;
  Detector: UCharsetDetector;
  Match: UCharsetMatch;
  DetectedName: PAnsiChar;
  Confidence: Integer;
begin
  Result := '';
  Status := 0;
  
  // 创建检测器
  Detector := ucsdet_open(Status);
  if not CheckICUError('创建编码检测器', Status) or (Detector = nil) then
    Exit;
  
  try
    // 设置文本
    ucsdet_setText(Detector, @Text[0], Length(Text), Status);
    if not CheckICUError('设置文本', Status) then
      Exit;
    
    // 检测编码
    Match := ucsdet_detect(Detector, Status);
    if not CheckICUError('检测编码', Status) or (Match = nil) then
      Exit;
    
    // 获取编码名称
    DetectedName := ucsdet_getName(Match, Status);
    if not CheckICUError('获取编码名称', Status) then
      Exit;
    
    // 获取置信度
    Confidence := ucsdet_getConfidence(Match, Status);
    if not CheckICUError('获取置信度', Status) then
      Exit;
    
    // 输出结果
    Result := string(DetectedName);
    Writeln('检测到的编码: ', Result, ' (置信度: ', Confidence, '%)');
  finally
    ucsdet_close(Detector);
  end;
end;

procedure CreateTestFile(const FileName: string; const Content: string; Encoding: TEncoding);
var
  Stream: TFileStream;
  Bytes: TBytes;
begin
  Writeln('创建测试文件: ', FileName);
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    Bytes := Encoding.GetBytes(Content);
    Stream.WriteBuffer(Bytes[0], Length(Bytes));
  finally
    Stream.Free;
  end;
  Writeln('测试文件创建成功，大小: ', Length(Bytes), ' 字节');
end;

procedure TestEncodingDetection;
const
  UTF8FileName = 'utf8_test.txt';
  UTF16FileName = 'utf16_test.txt';
  TextContent = 'This is a test. 这是一个测试。 こんにちは世界！';
var
  Bytes: TBytes;
begin
  // 创建测试文件
  CreateTestFile(UTF8FileName, TextContent, TEncoding.UTF8);
  CreateTestFile(UTF16FileName, TextContent, TEncoding.Unicode);
  
  // 测试UTF-8文件
  Writeln;
  Writeln('测试UTF-8文件...');
  Bytes := TFile.ReadAllBytes(UTF8FileName);
  Writeln('读取: ', Length(Bytes), ' 字节');
  DetectTextEncoding(Bytes);
  
  // 测试UTF-16文件
  Writeln;
  Writeln('测试UTF-16文件...');
  Bytes := TFile.ReadAllBytes(UTF16FileName);
  Writeln('读取: ', Length(Bytes), ' 字节');
  DetectTextEncoding(Bytes);
end;

begin
  try
    Writeln('ICU编码检测测试程序');
    Writeln('===================');
    Writeln;
    
    // 加载ICU库
    if not LoadICULibraries then
    begin
      Writeln('错误: 无法加载ICU库，按任意键退出...');
      Readln;
      Exit;
    end;
    Writeln('所有ICU库和函数加载成功');
    
    // 测试编码检测
    TestEncodingDetection;
    
    Writeln;
    Writeln('测试完成，按任意键退出...');
    Readln;
  finally
    FreeICULibraries;
  end;
end. 