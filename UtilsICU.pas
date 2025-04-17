unit UtilsICU;

interface

uses
  System.SysUtils, System.Classes, System.Types, Winapi.Windows, System.Generics.Collections,
  System.IOUtils, System.Math;

// --- Windows PE 文件格式相关结构 ---
const
  IMAGE_DIRECTORY_ENTRY_EXPORT = 0;

type
  PImageDosHeader = ^TImageDosHeader;
  TImageDosHeader = packed record
    e_magic: Word;
    e_cblp: Word;
    e_cp: Word;
    e_crlc: Word;
    e_cparhdr: Word;
    e_minalloc: Word;
    e_maxalloc: Word;
    e_ss: Word;
    e_sp: Word;
    e_csum: Word;
    e_ip: Word;
    e_cs: Word;
    e_lfarlc: Word;
    e_ovno: Word;
    e_res: array[0..3] of Word;
    e_oemid: Word;
    e_oeminfo: Word;
    e_res2: array[0..9] of Word;
    e_lfanew: LongInt;
  end;

  PImageFileHeader = ^TImageFileHeader;
  TImageFileHeader = packed record
    Machine: Word;
    NumberOfSections: Word;
    TimeDateStamp: LongWord;
    PointerToSymbolTable: LongWord;
    NumberOfSymbols: LongWord;
    SizeOfOptionalHeader: Word;
    Characteristics: Word;
  end;

  PImageDataDirectory = ^TImageDataDirectory;
  TImageDataDirectory = packed record
    VirtualAddress: LongWord;
    Size: LongWord;
  end;

  PImageOptionalHeader = ^TImageOptionalHeader;
  TImageOptionalHeader = packed record
    Magic: Word;
    MajorLinkerVersion: Byte;
    MinorLinkerVersion: Byte;
    SizeOfCode: LongWord;
    SizeOfInitializedData: LongWord;
    SizeOfUninitializedData: LongWord;
    AddressOfEntryPoint: LongWord;
    BaseOfCode: LongWord;
    BaseOfData: LongWord;
    ImageBase: LongWord;
    SectionAlignment: LongWord;
    FileAlignment: LongWord;
    MajorOperatingSystemVersion: Word;
    MinorOperatingSystemVersion: Word;
    MajorImageVersion: Word;
    MinorImageVersion: Word;
    MajorSubsystemVersion: Word;
    MinorSubsystemVersion: Word;
    Win32VersionValue: LongWord;
    SizeOfImage: LongWord;
    SizeOfHeaders: LongWord;
    CheckSum: LongWord;
    Subsystem: Word;
    DllCharacteristics: Word;
    SizeOfStackReserve: LongWord;
    SizeOfStackCommit: LongWord;
    SizeOfHeapReserve: LongWord;
    SizeOfHeapCommit: LongWord;
    LoaderFlags: LongWord;
    NumberOfRvaAndSizes: LongWord;
    DataDirectory: array[0..15] of TImageDataDirectory;
  end;

  PImageNtHeaders = ^TImageNtHeaders;
  TImageNtHeaders = packed record
    Signature: LongWord;
    FileHeader: TImageFileHeader;
    OptionalHeader: TImageOptionalHeader;
  end;

  PImageExportDirectory = ^TImageExportDirectory;
  TImageExportDirectory = packed record
    Characteristics: LongWord;
    TimeDateStamp: LongWord;
    MajorVersion: Word;
    MinorVersion: Word;
    Name: LongWord;
    Base: LongWord;
    NumberOfFunctions: LongWord;
    NumberOfNames: LongWord;
    AddressOfFunctions: LongWord;
    AddressOfNames: LongWord;
    AddressOfNameOrdinals: LongWord;
  end;

// --- ICU 基础类型定义 ---
// 注意: 这些是简化的定义，可能需要根据具体的ICU版本和编译器设置进行调整。
type
  UErrorCode = Integer; // 通常是带符号的32位整数
  UCharsetDetector = Pointer; // 字符集探测器 (ucsdet) 的不透明指针
  UCharsetMatch = Pointer; // 字符集匹配信息 (ucsdet) 的不透明指针
  UConverter = Pointer; // 编码转换器 (ucnv) 的不透明指针

const
  // --- ICU DLL 文件名 (根据用户文件列表更新为版本 77) ---
  icuucDllName = 'icuuc77.dll'; // ICU Common DLL
  icuinDllName = 'icuin77.dll'; // ICU I18n DLL
  icudtDllName = 'icudt77.dll'; // ICU Data DLL

  // --- 常见的 UErrorCode 值 ---
  U_ZERO_ERROR = 0; // 成功
  U_BUFFER_OVERFLOW_ERROR = 15; // 缓冲区溢出错误
  U_FILE_ACCESS_ERROR = 4; // 文件访问错误 (示例值，需核对头文件)
  // 可根据需要添加其他相关错误码...

  // --- 缓冲区大小常量 ---
  DETECT_BUFFER_SIZE = 4096; // 用于检测时读取的字节数

// --- ICU API 函数声明 (动态加载) ---
type
  // -- 错误检查 --
  Tu_errorName = function(code: UErrorCode): PAnsiChar; cdecl;

  // -- 字符集检测 (ucsdet) --
  Tucsdet_open = function(out pErrorCode: UErrorCode): UCharsetDetector; cdecl;
  Tucsdet_close = procedure(csd: UCharsetDetector); cdecl;
  Tucsdet_setText = procedure(csd: UCharsetDetector; text: PAnsiChar; length: Integer; out pErrorCode: UErrorCode); cdecl;
  Tucsdet_detect = function(csd: UCharsetDetector; out pErrorCode: UErrorCode): UCharsetMatch; cdecl;
  Tucsdet_detectAll = function(csd: UCharsetDetector; out matchesFound: Integer; out pErrorCode: UErrorCode): PPChar; cdecl;
  Tucsdet_getName = function(match: UCharsetMatch; out pErrorCode: UErrorCode): PAnsiChar; cdecl;
  Tucsdet_getConfidence = function(match: UCharsetMatch; out pErrorCode: UErrorCode): Integer; cdecl;
  Tucsdet_getLanguage = function(match: UCharsetMatch; out pErrorCode: UErrorCode): PAnsiChar; cdecl;

  // -- 编码转换 (ucnv) --
  Tucnv_open = function(converterName: PAnsiChar; out pErrorCode: UErrorCode): UConverter; cdecl;
  Tucnv_close = procedure(converter: UConverter); cdecl;
  Tucnv_convertEx = function(targetConverter, sourceConverter: UConverter;
    target: PChar; targetLimit: PChar;
    source: PChar; sourceLimit: PChar;
    pivotStart: PChar; pivotSource: PChar; pivotTarget: PChar; pivotLimit: PChar;
    reset: Boolean; useFallback: Boolean; out pErrorCode: UErrorCode): Integer; cdecl;
  Tucnv_fromUChars = function(cnv: UConverter; dest: PAnsiChar; destCapacity: Integer;
    src: PWideChar; srcLength: Integer; out pErrorCode: UErrorCode): Integer; cdecl;
  Tucnv_toUChars = function(cnv: UConverter; dest: PWideChar; destCapacity: Integer;
    src: PAnsiChar; srcLength: Integer; out pErrorCode: UErrorCode): Integer; cdecl;

var
  // -- 错误检查 --
  u_errorName: Tu_errorName;

  // -- 字符集检测 (ucsdet) --
  ucsdet_open: Tucsdet_open;
  ucsdet_close: Tucsdet_close;
  ucsdet_setText: Tucsdet_setText;
  ucsdet_detect: Tucsdet_detect;
  ucsdet_detectAll: Tucsdet_detectAll;
  ucsdet_getName: Tucsdet_getName;
  ucsdet_getConfidence: Tucsdet_getConfidence;
  ucsdet_getLanguage: Tucsdet_getLanguage;

  // -- 编码转换 (ucnv) --
  ucnv_open: Tucnv_open;
  ucnv_close: Tucnv_close;
  ucnv_convertEx: Tucnv_convertEx;
  ucnv_fromUChars: Tucnv_fromUChars;
  ucnv_toUChars: Tucnv_toUChars;

// 日志记录的辅助函数类型 (由 Controller 传递)
// Corrected: Changed to TProc<string> to match ControllerEncoding
type
  TLogProcedure = TProc<string>;

// --- ICU 辅助类 ---
type
  TIcuHelper = class
  private
    FLog: TLogProcedure; // Corrected: Changed type to TProc<string>
    FLastError: string;
    FLibraryLoaded: Boolean;
    FLibraryucuc: HMODULE;
    FLibraryicuin: HMODULE;
    FLibraryicudt: HMODULE;
    
    function CheckError(const Context: string; ErrorCode: UErrorCode): Boolean; // 检查并记录 ICU 错误
    function InternalDetectEncoding(const Buffer: TBytes): string; // 内部编码检测逻辑
    function GetBestDetectedEncoding(csd: UCharsetDetector): string; // 获取最佳检测结果
    
    // 添加内部日志方法
    procedure LogMessage(const Msg: string);
    
    // 尝试加载ICU库
    function TryLoadICULibraries: Boolean;
    // 尝试从指定路径加载ICU库
    function TryLoadICULibrariesFromPath(const BasePath: string): Boolean;
    // 查找DLL文件
    function FindDLLFile(const DllName: string): string;
    // 获取函数地址
    function GetProcedureAddress(Module: HMODULE; ProcName: string; const Suffix: string = ''): Pointer;
    // 分析DLL导出函数格式
    procedure AnalyzeDllExports(const DllHandle: THandle; const DllName: string);
  public
    constructor Create(LogProc: TLogProcedure = nil); // 构造函数，接收可选的日志回调
    destructor Destroy; override;
    function Initialize: Boolean; // 初始化
    function DetectFileEncoding(const FilePath: string; out DetectedEncoding: string): Boolean; // 检测文件编码
    // 将源字节流 (假设为 UTF-8) 转换为目标编码 TargetEncodingName
    function ConvertEncoding(var Source: TBytes; const TargetEncodingName: string; AddBOM: Boolean = False): Boolean; overload;
    // 将源字节流 (指定编码 FromEncodingName) 转换为目标编码 TargetEncodingName
    function ConvertEncoding(var Source: TBytes; const FromEncodingName, TargetEncodingName: string; AddBOM: Boolean = False): Boolean; overload;
    property LastError: string read FLastError; // 获取最后发生的错误信息
    property LibraryLoaded: Boolean read FLibraryLoaded; // 是否成功加载了库
  end;

implementation

// --- 错误代码检查辅助函数 ---
function UErrorCodeSuccess(code: UErrorCode): Boolean;
begin
  // 相当于 U_SUCCESS 宏
  Result := code <= U_ZERO_ERROR;
end;

function UErrorCodeFailed(code: UErrorCode): Boolean;
begin
  // 相当于 U_FAILURE 宏
  Result := code > U_ZERO_ERROR;
end;

// --- TIcuHelper 实现 ---

// 添加内部日志方法
procedure TIcuHelper.LogMessage(const Msg: string);
begin
  if Assigned(FLog) then
    FLog(Msg)
  else
    // 如果没有日志回调，可以选择将消息写入控制台或简单忽略
    {$IFDEF CONSOLE}
    WriteLn(Msg);
    {$ENDIF}
end;

constructor TIcuHelper.Create(LogProc: TLogProcedure);
begin
  inherited Create;
  FLog := LogProc;
  FLastError := '';
  FLibraryLoaded := False;
  FLibraryucuc := 0;
  FLibraryicuin := 0;
  FLibraryicudt := 0;
end;

destructor TIcuHelper.Destroy;
begin
  // 释放库句柄
  if FLibraryucuc <> 0 then
    FreeLibrary(FLibraryucuc);
  if FLibraryicuin <> 0 then
    FreeLibrary(FLibraryicuin);
  if FLibraryicudt <> 0 then
    FreeLibrary(FLibraryicudt);
  inherited;
end;

function TIcuHelper.Initialize: Boolean;
begin
  // 尝试加载ICU库
  Result := TryLoadICULibraries;
  if not Result then
  begin
    LogMessage('无法加载ICU库，请确保库文件存在');
    Exit;
  end;
  
  LogMessage('ICU库加载成功');
  FLibraryLoaded := True;
end;

// 查找DLL文件的所有可能位置
function TIcuHelper.FindDLLFile(const DllName: string): string;
var
  PossiblePaths: TArray<string>;
  Path: string;
  ExeDir: string;
  i: Integer;
begin
  Result := '';
  
  // 获取可执行文件所在目录
  ExeDir := ExtractFilePath(ParamStr(0));
  
  // 定义可能的路径列表 - 只检查项目根目录和可执行文件所在目录
  PossiblePaths := [
    // 可执行文件所在目录
    ExeDir + DllName,
    // 当前目录
    GetCurrentDir + PathDelim + DllName
  ];
  
  // 检查每个可能的路径
  for i := 0 to Length(PossiblePaths) - 1 do
  begin
    Path := PossiblePaths[i];
    if FileExists(Path) then
    begin
      Result := Path;
      LogMessage('找到DLL文件: ' + Path);
      Exit;
    end;
  end;
  
  LogMessage('找不到DLL文件: ' + DllName);
end;

// 获取系统目录
function GetSystemDir: string;
var
  Buffer: array[0..MAX_PATH] of Char;
begin
  GetSystemDirectory(Buffer, MAX_PATH);
  Result := Buffer;
end;

// 获取Windows目录
function GetWindowsDir: string;
var
  Buffer: array[0..MAX_PATH] of Char;
begin
  GetWindowsDirectory(Buffer, MAX_PATH);
  Result := Buffer;
end;

// 从指定路径加载ICU库
function TIcuHelper.TryLoadICULibrariesFromPath(const BasePath: string): Boolean;
var
  ucucPath, icuinPath, icudtPath: string;
  VersionSuffix: string;
begin
  Result := False;
  
  // 构建完整路径
  ucucPath := IncludeTrailingPathDelimiter(BasePath) + icuucDllName;
  icuinPath := IncludeTrailingPathDelimiter(BasePath) + icuinDllName;
  icudtPath := IncludeTrailingPathDelimiter(BasePath) + icudtDllName;
  
  // 检查文件是否存在
  if not FileExists(ucucPath) or not FileExists(icuinPath) or not FileExists(icudtPath) then
  begin
    LogMessage('ICU库文件在 ' + BasePath + ' 中不完整');
    Exit;
  end;
  
  // 尝试加载库
  FLibraryucuc := LoadLibrary(PChar(ucucPath));
  if FLibraryucuc = 0 then
  begin
    LogMessage('无法加载 ' + ucucPath);
    Exit;
  end;
  
  FLibraryicuin := LoadLibrary(PChar(icuinPath));
  if FLibraryicuin = 0 then
  begin
    LogMessage('无法加载 ' + icuinPath);
    FreeLibrary(FLibraryucuc);
    FLibraryucuc := 0;
    Exit;
  end;
  
  FLibraryicudt := LoadLibrary(PChar(icudtPath));
  if FLibraryicudt = 0 then
  begin
    LogMessage('无法加载 ' + icudtPath);
    FreeLibrary(FLibraryucuc);
    FreeLibrary(FLibraryicuin);
    FLibraryucuc := 0;
    FLibraryicuin := 0;
    Exit;
  end;
  
  // 分析DLL导出函数
  LogMessage('正在分析 ' + icuucDllName + ' 的导出函数');
  AnalyzeDllExports(FLibraryucuc, icuucDllName);
  
  LogMessage('正在分析 ' + icuinDllName + ' 的导出函数');
  AnalyzeDllExports(FLibraryicuin, icuinDllName);
  
  // 确定版本后缀 (如 "_77")
  VersionSuffix := '_77';
  
  // 加载各个函数
  // -- 错误检查 --
  u_errorName := GetProcedureAddress(FLibraryucuc, 'u_errorName');
  
  // -- 字符集检测 (ucsdet) --
  ucsdet_open := GetProcedureAddress(FLibraryicuin, 'ucsdet_open', VersionSuffix);
  ucsdet_close := GetProcedureAddress(FLibraryicuin, 'ucsdet_close', VersionSuffix);
  ucsdet_setText := GetProcedureAddress(FLibraryicuin, 'ucsdet_setText', VersionSuffix);
  ucsdet_detect := GetProcedureAddress(FLibraryicuin, 'ucsdet_detect', VersionSuffix);
  ucsdet_detectAll := GetProcedureAddress(FLibraryicuin, 'ucsdet_detectAll', VersionSuffix);
  ucsdet_getName := GetProcedureAddress(FLibraryicuin, 'ucsdet_getName', VersionSuffix);
  ucsdet_getConfidence := GetProcedureAddress(FLibraryicuin, 'ucsdet_getConfidence', VersionSuffix);
  ucsdet_getLanguage := GetProcedureAddress(FLibraryicuin, 'ucsdet_getLanguage', VersionSuffix);
  
  // -- 编码转换 (ucnv) --
  ucnv_open := GetProcedureAddress(FLibraryucuc, 'ucnv_open', VersionSuffix);
  ucnv_close := GetProcedureAddress(FLibraryucuc, 'ucnv_close', VersionSuffix);
  ucnv_convertEx := GetProcedureAddress(FLibraryucuc, 'ucnv_convertEx', VersionSuffix);
  ucnv_fromUChars := GetProcedureAddress(FLibraryucuc, 'ucnv_fromUChars', VersionSuffix);
  ucnv_toUChars := GetProcedureAddress(FLibraryucuc, 'ucnv_toUChars', VersionSuffix);
  
  // 如果不需要所有函数也能正常工作，只检查必要的几个核心函数
  if not (Assigned(ucsdet_open) and Assigned(ucsdet_close) and 
          Assigned(ucsdet_setText) and Assigned(ucsdet_detect) and 
          Assigned(ucsdet_getName) and Assigned(ucnv_open) and 
          Assigned(ucnv_close)) then
  begin
    LogMessage('部分ICU核心函数无法加载');
    FreeLibrary(FLibraryucuc);
    FreeLibrary(FLibraryicuin);
    FreeLibrary(FLibraryicudt);
    FLibraryucuc := 0;
    FLibraryicuin := 0;
    FLibraryicudt := 0;
    Exit;
  end;
  
  Result := True;
  LogMessage('成功从 ' + BasePath + ' 加载ICU库');
end;

// 获取函数地址
function TIcuHelper.GetProcedureAddress(Module: HMODULE; ProcName: string; const Suffix: string = ''): Pointer;
var
  Attempts: TArray<string>;
  i: Integer;
begin
  Result := nil;
  
  // 定义可能的函数名格式
  Attempts := [
    ProcName,                 // 原始名称
    ProcName + Suffix,        // 带后缀
    ProcName + '_' + '77',    // 带版本号
    ProcName + Suffix + '64', // 带后缀和64位标识
    'lib' + ProcName,         // lib前缀
    'lib' + ProcName + Suffix // lib前缀带后缀
  ];
  
  // 尝试所有可能的名称
  for i := 0 to High(Attempts) do
  begin
    Result := GetProcAddress(Module, PChar(Attempts[i]));
    if Result <> nil then
    begin
      LogMessage('成功获取函数 ' + ProcName + ' 使用名称: ' + Attempts[i]);
      Exit;
    end;
  end;
  
  // 所有尝试都失败
  LogMessage('无法获取函数地址: ' + ProcName + ' (尝试了 ' + IntToStr(Length(Attempts)) + ' 种不同名称)');
  
  // 最后尝试使用序号（某些DLL使用序号导出函数）
  try
    // 尝试常见的序号范围（1-100）
    for i := 1 to 100 do
    begin
      Result := GetProcAddress(Module, PChar(i));
      if Result <> nil then
      begin
        LogMessage('找到函数地址使用序号: ' + IntToStr(i) + '，尝试用于 ' + ProcName);
        Exit;
      end;
    end;
  except
    // 忽略序号搜索异常
  end;
end;

// 分析DLL导出函数格式
procedure TIcuHelper.AnalyzeDllExports(const DllHandle: THandle; const DllName: string);
var
  DosHeader: PImageDosHeader;
  NtHeader: PImageNtHeaders;
  ExportDirectory: PImageExportDirectory;
  FunctionEntries: PDWORD;
  FunctionNames: PDWORD;
  FunctionOrdinals: PWORD;
  FunctionNamePtr: DWORD;
  FunctionName: PAnsiChar;
  MaxExports: Cardinal;
  i: Cardinal;
  FunctionNameStr: string;
begin
  if DllHandle = 0 then
  begin
    LogMessage('DLL句柄无效: ' + DllName);
    Exit;
  end;

  LogMessage('正在分析 ' + DllName + ' 的导出函数');

  try
    // 获取DOS头
    DosHeader := PImageDosHeader(DllHandle);
    if DosHeader.e_magic <> IMAGE_DOS_SIGNATURE then
    begin
      LogMessage('无效的DOS头 (MZ标记): ' + DllName);
      Exit;
    end;

    // 获取NT头
    NtHeader := PImageNtHeaders(PByte(DllHandle) + DosHeader.e_lfanew);
    if NtHeader.Signature <> IMAGE_NT_SIGNATURE then
    begin
      LogMessage('无效的NT头 (PE标记): ' + DllName);
      Exit;
    end;

    // 获取导出目录
    if NtHeader.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress = 0 then
    begin
      LogMessage('无法找到导出目录: ' + DllName);
      Exit;
    end;

    ExportDirectory := PImageExportDirectory(PByte(DllHandle) + 
      NtHeader.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress);

    // 获取函数表
    FunctionEntries := PDWORD(PByte(DllHandle) + ExportDirectory.AddressOfFunctions);
    FunctionNames := PDWORD(PByte(DllHandle) + ExportDirectory.AddressOfNames);
    FunctionOrdinals := PWORD(PByte(DllHandle) + ExportDirectory.AddressOfNameOrdinals);

    // 验证导出函数数量的合理性
    if (ExportDirectory.NumberOfFunctions > 10000) or (ExportDirectory.NumberOfNames > 10000) then
    begin
      LogMessage('导出函数数量不合理，可能是内存结构错误: ' + IntToStr(ExportDirectory.NumberOfFunctions));
      LogMessage('限制为最多10000个函数分析');
      MaxExports := 10000;
    end else
      MaxExports := ExportDirectory.NumberOfNames;

    LogMessage('开始分析DLL导出函数，总共' + IntToStr(MaxExports) + '个导出函数');

    // 输出前10个函数名
    for i := 0 to Min(MaxExports - 1, 9) do
    begin
      try
        // 安全地获取函数名，使用指针偏移
        FunctionNamePtr := PDWORD(PByte(FunctionNames) + i * SizeOf(DWORD))^;
        FunctionName := PAnsiChar(PByte(DllHandle) + FunctionNamePtr);
        FunctionNameStr := string(FunctionName);
        LogMessage('函数 #' + IntToStr(i) + ': ' + FunctionNameStr);
      except
        on E: Exception do
        begin
          LogMessage('读取函数名 #' + IntToStr(i) + ' 失败: ' + E.Message);
          Break;
        end;
      end;
    end;

    // 寻找特定函数
    for i := 0 to MaxExports - 1 do
    begin
      try
        // 安全地获取函数名，使用指针偏移
        FunctionNamePtr := PDWORD(PByte(FunctionNames) + i * SizeOf(DWORD))^;
        FunctionName := PAnsiChar(PByte(DllHandle) + FunctionNamePtr);
        FunctionNameStr := string(FunctionName);
        
        // 输出关键函数
        if (Pos('u_error', FunctionNameStr) > 0) or
           (Pos('ucsdet', FunctionNameStr) > 0) or
           (Pos('ucnv', FunctionNameStr) > 0) then
        begin
          LogMessage('找到关键函数: ' + FunctionNameStr);
        end;
      except
        on E: Exception do
        begin
          LogMessage('在索引 ' + IntToStr(i) + ' 读取函数名失败: ' + E.Message);
          Break;
        end;
      end;
    end;
  except
    on E: Exception do
      LogMessage('分析DLL导出函数失败: ' + E.Message);
  end;
end;

// 尝试加载ICU库
function TIcuHelper.TryLoadICULibraries: Boolean;
var
  ucucDllPath, icuinDllPath, icudtDllPath: string;
  BasePath: string;
begin
  // 首先尝试在同一目录中查找所有DLL
  ucucDllPath := FindDLLFile(icuucDllName);
  icuinDllPath := FindDLLFile(icuinDllName);
  icudtDllPath := FindDLLFile(icudtDllName);
  
  if (ucucDllPath <> '') and (icuinDllPath <> '') and (icudtDllPath <> '') then
  begin
    // 所有DLL都找到了，尝试加载
    BasePath := ExtractFilePath(ucucDllPath);
    Result := TryLoadICULibrariesFromPath(BasePath);
    if Result then
    begin
      LogMessage('成功加载所有ICU库文件');
      Exit;
    end;
  end;
  
  // 尝试在两个指定位置查找并加载
  // 1. 程序所在目录
  LogMessage('尝试从程序所在目录加载ICU库');
  if TryLoadICULibrariesFromPath(ExtractFilePath(ParamStr(0))) then
  begin
    Result := True;
    Exit;
  end;
  
  // 2. 当前目录（项目根目录）
  LogMessage('尝试从当前目录加载ICU库');
  if TryLoadICULibrariesFromPath(GetCurrentDir) then
  begin
    Result := True;
    Exit;
  end;
  
  // 如果所有尝试都失败
  LogMessage('无法在指定位置找到ICU库');
  Result := False;
end;

function TIcuHelper.CheckError(const Context: string; ErrorCode: UErrorCode): Boolean;
var
  ErrorNameAnsi: PAnsiChar;
  ErrorName: string;
begin
  Result := UErrorCodeSuccess(ErrorCode);
  if not Result then
  begin
    // 确保u_errorName函数被正确加载
    if Assigned(u_errorName) then
    begin
      ErrorNameAnsi := u_errorName(ErrorCode);
      if ErrorNameAnsi <> nil then
        ErrorName := string(ErrorNameAnsi) // PAnsiChar 转 Delphi string
      else
        ErrorName := '未知的错误码';
    end
    else
    begin
      ErrorName := Format('未知错误(代码: %d)', [ErrorCode]);
    end;
    
    FLastError := Format('%s 失败。ICU 错误: %s (%d)', [Context, ErrorName, ErrorCode]);
    // 调用内部日志方法
    LogMessage(FLastError);
  end
  else
  begin
    FLastError := ''; // 成功时清除最后错误信息
  end;
end;

// 简单辅助函数获取最佳匹配 (最高置信度)
// 注意: 这是基础实现，实际可能需要遍历 ucsdet_detectAll 的结果
function TIcuHelper.GetBestDetectedEncoding(csd: UCharsetDetector): string;
var
  Match: UCharsetMatch;
  ErrorCode: UErrorCode;
  EncodingNameAnsi: PAnsiChar;
  Confidence: Integer;
begin
  Result := '';
  
  // 检查必要的函数指针是否已初始化
  if not Assigned(ucsdet_detect) or not Assigned(ucsdet_getName) or
     not Assigned(ucsdet_getConfidence) then
  begin
    LogMessage('ICU函数未正确加载，无法检测编码');
    Exit;
  end;
  
  ErrorCode := U_ZERO_ERROR;
  Match := ucsdet_detect(csd, ErrorCode); // 获取单个最佳匹配结果

  if CheckError('ucsdet_detect', ErrorCode) and (Match <> nil) then
  begin
    EncodingNameAnsi := ucsdet_getName(Match, ErrorCode);
    if CheckError('ucsdet_getName', ErrorCode) and (EncodingNameAnsi <> nil) then
    begin
      Confidence := ucsdet_getConfidence(Match, ErrorCode);
      if CheckError('ucsdet_getConfidence', ErrorCode) then
      begin
        LogMessage(Format('  [ICU检测] 最佳猜测: %s (置信度: %d)', [string(EncodingNameAnsi), Confidence]));
        // 基本的置信度阈值 - 可根据需要调整
        if Confidence >= 50 then // 示例阈值
          Result := string(EncodingNameAnsi)
        else
          LogMessage('  [ICU检测] 置信度过低，忽略检测结果。');
      end;
    end;
    // 注意: UCharsetMatch 对象由 ICU 通过探测器内部管理，我们不需要手动释放它。
  end;
end;


function TIcuHelper.InternalDetectEncoding(const Buffer: TBytes): string;
var
  Detector: UCharsetDetector;
  ErrorCode: UErrorCode;
  BufferPtr: PAnsiChar;
  BytesToDetect: Integer;
begin
  Result := '';
  FLastError := '';
  ErrorCode := U_ZERO_ERROR;
  
  // 检查库是否加载
  if not FLibraryLoaded then
  begin
    if not Initialize then
    begin
      LogMessage('ICU库未初始化，无法进行编码检测');
      Exit;
    end;
  end;

  // 打开字符集探测器
  Detector := ucsdet_open(ErrorCode);
  if not CheckError('ucsdet_open', ErrorCode) or (Detector = nil) then
    Exit;

  try
    // 设置要检测的文本数据
    BytesToDetect := Min(Length(Buffer), DETECT_BUFFER_SIZE);
    if BytesToDetect <= 0 then
    begin
      FLastError := '检测数据为空';
      LogMessage(FLastError);
      Exit;
    end;

    // 直接使用TBytes数组地址
    BufferPtr := PAnsiChar(@Buffer[0]);
    ErrorCode := U_ZERO_ERROR;
    ucsdet_setText(Detector, BufferPtr, BytesToDetect, ErrorCode);
    if not CheckError('ucsdet_setText', ErrorCode) then
      Exit;

    // 执行检测并获取最佳匹配
    Result := GetBestDetectedEncoding(Detector);
    if Result = '' then
      LogMessage('  [ICU检测] 无法确定编码，使用默认编码');
  finally
    // 关闭探测器
    ucsdet_close(Detector);
  end;
end;

function TIcuHelper.DetectFileEncoding(const FilePath: string; out DetectedEncoding: string): Boolean;
var
  FS: TFileStream;
  Buffer: TBytes;
  BytesRead: Integer;
begin
  Result := False;
  DetectedEncoding := '';
  FLastError := '';

  // 检查库是否加载
  if not FLibraryLoaded then
  begin
    if not Initialize then
    begin
      LogMessage('ICU库未初始化，无法进行编码检测');
      Exit;
    end;
  end;

  if not TFile.Exists(FilePath) then
  begin
    FLastError := Format('文件未找到: %s', [FilePath]);
    LogMessage(FLastError);
    Exit;
  end;

  try
    FS := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(Buffer, DETECT_BUFFER_SIZE);
      BytesRead := FS.Read(Buffer, 0, DETECT_BUFFER_SIZE);
      SetLength(Buffer, BytesRead); // 调整缓冲区为实际读取大小

      if BytesRead > 0 then
      begin
        DetectedEncoding := InternalDetectEncoding(Buffer);
        Result := DetectedEncoding <> '';
        if not Result and (FLastError = '') then // 内部检测成功但未找到可靠结果
          FLastError := 'ICU 未能可靠地确定编码。';
        // 记录最终检测到的编码或失败原因
        if Result then
        begin
          LogMessage(Format('[ICU检测] 文件 [%s] 检测到编码: %s', [ExtractFileName(FilePath), DetectedEncoding]));
        end
        else
        begin
          LogMessage(Format('[ICU检测] 文件 [%s] 编码检测失败: %s', [ExtractFileName(FilePath), FLastError]));
        end;
      end
      else
      begin
         FLastError := Format('文件为空或无法读取: %s', [FilePath]);
         LogMessage(FLastError);
      end;

    finally
      FS.Free;
    end;
  except
    on E: Exception do
    begin
      FLastError := Format('读取文件 %s 进行检测时出错: %s', [FilePath, E.Message]);
      LogMessage(FLastError);
      Result := False;
    end;
  end;
end;

// --- 转换实现 ---

// 重载 1: 假设源编码为 UTF-8
function TIcuHelper.ConvertEncoding(var Source: TBytes; const TargetEncodingName: string; AddBOM: Boolean = False): Boolean;
begin
  // 为简化，委托给更通用的版本，假设源是 UTF-8
  Result := ConvertEncoding(Source, 'UTF-8', TargetEncodingName, AddBOM);
end;

// 重载 2: 指定源编码和目标编码
function TIcuHelper.ConvertEncoding(var Source: TBytes; const FromEncodingName, TargetEncodingName: string; AddBOM: Boolean = False): Boolean;
var
  SrcConverter, DstConverter: UConverter;
  ErrorCode: UErrorCode;
  SourcePtr: PAnsiChar;
  SourceLen: Integer;
  UCharsBuffer: TArray<WideChar>; // 中间 Unicode 缓冲区 (UTF-16)
  UCharsCapacity, UCharsLen: Integer;
  TargetBuffer: TArray<Byte>; // 最终字节缓冲区
  TargetCapacity, TargetLen: Integer;
  RetryCount: Integer;
  BOMBytes: TBytes;
  ActualFromName, ActualTargetName: string;
  ForceAddBOM, IsUTF8ToUTF8BOM, IsUTF8BOMToUTF8: Boolean;
  HasBOM: Boolean;
  TempBuffer: TBytes;
begin
  Result := False;
  FLastError := '';
  SrcConverter := nil;
  DstConverter := nil;
  UCharsLen := -1; // 初始化 UCharsLen 为 -1，表示初始失败状态

  // 检查库是否加载
  if not FLibraryLoaded then
  begin
    if not Initialize then
    begin
      LogMessage('ICU库未初始化，无法进行编码转换');
      Exit;
    end;
  end;

  SourceLen := Length(Source);
  if SourceLen = 0 then
  begin
    LogMessage('源缓冲区为空，无需转换。');
    Result := True; // 空输入转换为空输出，视为成功
    Exit;
  end;

  // 处理特殊编码名称"UTF-8 BOM"
  ActualFromName := FromEncodingName;
  ActualTargetName := TargetEncodingName;
  ForceAddBOM := AddBOM;
  
  // 检查源编码是否带有BOM
  HasBOM := False;
  if SourceLen >= 3 then
  begin
    HasBOM := (Source[0] = $EF) and (Source[1] = $BB) and (Source[2] = $BF);
  end;
  
  // 处理源编码为UTF-8 BOM的情况
  if SameText(ActualFromName, 'UTF-8 BOM') then
  begin
    ActualFromName := 'UTF-8';
    LogMessage('源编码是UTF-8 BOM，使用UTF-8处理并跳过BOM (如果存在)');
  end;
  
  // 处理目标编码为UTF-8 BOM的情况
  if SameText(ActualTargetName, 'UTF-8 BOM') then
  begin
    ActualTargetName := 'UTF-8';
    ForceAddBOM := True;
    LogMessage('目标编码是UTF-8 BOM，使用UTF-8处理并强制添加BOM');
  end;
  
  // 其他编码名称中可能带有"BOM"后缀，移除它们以确保兼容性
  if Pos(' BOM', ActualFromName) > 0 then
  begin
    ActualFromName := StringReplace(ActualFromName, ' BOM', '', [rfReplaceAll, rfIgnoreCase]);
    LogMessage('源编码名称包含BOM后缀，改为使用"' + ActualFromName + '"');
  end;
  
  if Pos(' BOM', ActualTargetName) > 0 then
  begin
    ActualTargetName := StringReplace(ActualTargetName, ' BOM', '', [rfReplaceAll, rfIgnoreCase]);
    ForceAddBOM := True;
    LogMessage('目标编码名称包含BOM后缀，改为使用"' + ActualTargetName + '"并添加BOM');
  end;
  
  // 检测是否为UTF-8到UTF-8 BOM的转换或反向转换
  IsUTF8ToUTF8BOM := (SameText(ActualFromName, 'UTF-8') and 
                      SameText(ActualTargetName, 'UTF-8') and ForceAddBOM);
  
  IsUTF8BOMToUTF8 := (SameText(ActualFromName, 'UTF-8') and HasBOM and
                      SameText(ActualTargetName, 'UTF-8') and not ForceAddBOM);
  
  // 特殊处理UTF-8与UTF-8 BOM的相互转换
  if IsUTF8ToUTF8BOM then
  begin
    // UTF-8 -> UTF-8 BOM: 只需添加BOM标记
    if HasBOM then
    begin
      // 已经有BOM了，无需更改
      LogMessage('文件已经有UTF-8 BOM，无需修改');
      Result := True;
    end
    else
    begin
      // 添加UTF-8 BOM
      SetLength(TempBuffer, SourceLen + 3);
      TempBuffer[0] := $EF;
      TempBuffer[1] := $BB;
      TempBuffer[2] := $BF;
      
      // 复制原内容
      if SourceLen > 0 then
        Move(Source[0], TempBuffer[3], SourceLen);
      
      // 替换源内容
      Source := TempBuffer;
      
      LogMessage('直接添加UTF-8 BOM (EF BB BF)到UTF-8文件，跳过编码转换');
      Result := True;
    end;
    Exit; // 直接返回
  end
  else if IsUTF8BOMToUTF8 then
  begin
    // UTF-8 BOM -> UTF-8: 只需移除BOM标记
    SetLength(TempBuffer, SourceLen - 3);
    if SourceLen > 3 then
      Move(Source[3], TempBuffer[0], SourceLen - 3);
    
    // 替换源内容
    Source := TempBuffer;
    
    LogMessage('直接移除UTF-8 BOM，跳过编码转换');
    Result := True;
    Exit; // 直接返回
  end;

  // 标准编码转换流程
  ErrorCode := U_ZERO_ERROR;
  SrcConverter := ucnv_open(PAnsiChar(AnsiString(ActualFromName)), ErrorCode);
  if not CheckError(Format('ucnv_open (源: %s)', [ActualFromName]), ErrorCode) or (SrcConverter = nil) then Exit;
  try // 源转换器的 TRY 块
    // 如果源有BOM但不是UTF-8转UTF-8的特殊情况，跳过BOM
    if HasBOM and SameText(ActualFromName, 'UTF-8') then
    begin
      // 调整源指针和长度，跳过BOM
      SourcePtr := PAnsiChar(@Source[3]);
      SourceLen := SourceLen - 3;
      LogMessage('检测到UTF-8 BOM，在转换时跳过它');
    end
    else
    begin
      SourcePtr := PAnsiChar(Pointer(Source));
    end;
    
    // 步骤 1: 将源字节流 (ActualFromName) 转换为 UChars (WideChar / UTF-16)
    UCharsCapacity := SourceLen * 2 + 10; // 足够大的初始估计
    SetLength(UCharsBuffer, UCharsCapacity);
    RetryCount := 0;
    repeat
      ErrorCode := U_ZERO_ERROR;
      // 调用 ICU 函数进行转换到 UChars
      UCharsLen := ucnv_toUChars(SrcConverter, @UCharsBuffer[0], UCharsCapacity, SourcePtr, SourceLen, ErrorCode);
      if UErrorCodeSuccess(ErrorCode) then
      begin
        SetLength(UCharsBuffer, UCharsLen); // 调整 UChars 缓冲区为实际长度
        LogMessage(Format('成功将 %s 转换为 %d UChars (WideChars)。', [ActualFromName, UCharsLen]));
        Break; // 步骤 1 成功
      end
      else if ErrorCode = U_BUFFER_OVERFLOW_ERROR then
      begin // 缓冲区溢出处理
        Inc(RetryCount);
        if RetryCount > 3 then
        begin
          CheckError(Format('ucnv_toUChars (转换 %s 时超出重试次数)', [ActualFromName]), ErrorCode);
          UCharsLen := -1; // 明确标记失败
          Break; // 放弃
        end;
        // 容量加倍并重试
        UCharsCapacity := UCharsCapacity * 2 + 10;
        SetLength(UCharsBuffer, UCharsCapacity);
        LogMessage(Format('ucnv_toUChars 缓冲区溢出 (%s)，使用容量 %d 重试', [ActualFromName, UCharsCapacity]));
      end
      else
      begin // 步骤 1 发生其他错误
        CheckError(Format('ucnv_toUChars (%s)', [ActualFromName]), ErrorCode);
        UCharsLen := -1; // 明确标记失败
        Break;
      end;
    until False;

    // 步骤 2: 将 UChars (WideChar / UTF-16) 转换为目标字节流 (ActualTargetName)
    if UCharsLen >= 0 then // 仅当步骤 1 成功时继续
    begin
      ErrorCode := U_ZERO_ERROR;
      DstConverter := ucnv_open(PAnsiChar(AnsiString(ActualTargetName)), ErrorCode);
      if not CheckError(Format('ucnv_open (目标: %s)', [ActualTargetName]), ErrorCode) or (DstConverter = nil) then
      begin
        // 如果目标转换器打开失败，仍需在 finally 中关闭源转换器
        Exit; // 退出函数，Result 保持 False
      end;
      try // 目标转换器的 TRY 块
        // 估计目标缓冲区大小
        TargetCapacity := UCharsLen * 4 + 10; // 充分估计空间 (每个UTF-16字符最多可能需要4字节)
        SetLength(TargetBuffer, TargetCapacity);
        RetryCount := 0;
        repeat
          ErrorCode := U_ZERO_ERROR;
          // 调用 ICU 函数从 UChars 进行转换
          TargetLen := ucnv_fromUChars(DstConverter, PAnsiChar(@TargetBuffer[0]), TargetCapacity, @UCharsBuffer[0], UCharsLen, ErrorCode);
          if UErrorCodeSuccess(ErrorCode) then
          begin
            SetLength(TargetBuffer, TargetLen); // 调整目标缓冲区大小
            LogMessage(Format('成功将 %d UChars 转换为 %s (%d 字节)。', [UCharsLen, ActualTargetName, TargetLen]));
            
            // 处理 BOM
            if ForceAddBOM then
            begin
              // 处理UTF-8的BOM
              if SameText(ActualTargetName, 'UTF-8') then
              begin
                // 直接使用UTF-8 BOM: EF BB BF
                SetLength(TempBuffer, TargetLen + 3);
                TempBuffer[0] := $EF;
                TempBuffer[1] := $BB;
                TempBuffer[2] := $BF;
                
                // 复制转换后的内容
                if TargetLen > 0 then
                  Move(TargetBuffer[0], TempBuffer[3], TargetLen);
                  
                LogMessage('为UTF-8添加3字节BOM (EF BB BF)');
                Source := TempBuffer;
              end
              else
              begin
                try
                  // 尝试使用 Delphi 的 TEncoding 获取目标编码的 BOM
                  BOMBytes := TEncoding.GetEncoding(ActualTargetName).GetPreamble;
                except
                  // 处理 Delphi 无法识别编码名称的异常
                  BOMBytes := [];
                  LogMessage(Format('警告：无法通过 TEncoding 获取目标编码 %s 的 BOM。', [ActualTargetName]));
                end;
                
                if Length(BOMBytes) > 0 then
                begin
                  LogMessage(Format('为 %s 添加 %d 字节的 BOM', [ActualTargetName, Length(BOMBytes)]));
                  // 创建新的包含BOM的数组
                  SetLength(TempBuffer, TargetLen + Length(BOMBytes));
                  // 复制BOM
                  Move(BOMBytes[0], TempBuffer[0], Length(BOMBytes));
                  // 复制转换后的内容
                  if TargetLen > 0 then
                    Move(TargetBuffer[0], TempBuffer[Length(BOMBytes)], TargetLen);
                  Source := TempBuffer;
                end
                else
                begin
                  Source := TargetBuffer; // 将结果写回 Source (Var 参数)
                end;
              end;
            end
            else
            begin
              Source := TargetBuffer; // 将结果写回 Source (Var 参数)
            end;
            
            Result := True; // 最终成功!
            Break; // 步骤 2 成功
          end
          else if ErrorCode = U_BUFFER_OVERFLOW_ERROR then
          begin
            Inc(RetryCount);
            if RetryCount > 3 then
            begin
              CheckError(Format('ucnv_fromUChars (转换到 %s 时超出重试次数)', [ActualTargetName]), ErrorCode);
              Break; // 放弃
            end;
            // 容量加倍并重试
            TargetCapacity := TargetCapacity * 2 + 10;
            SetLength(TargetBuffer, TargetCapacity);
            LogMessage(Format('ucnv_fromUChars 缓冲区溢出 (%s)，使用容量 %d 重试', [ActualTargetName, TargetCapacity]));
          end
          else
          begin
            CheckError(Format('ucnv_fromUChars (%s)', [ActualTargetName]), ErrorCode);
            Break; // 转换失败
          end;
        until False;
      finally // 目标转换器的 FINALLY 块
        if DstConverter <> nil then ucnv_close(DstConverter);
      end;
    end;
  finally // 源转换器的 FINALLY 块
    if SrcConverter <> nil then ucnv_close(SrcConverter);
  end;
end;

end. // 单元结束 