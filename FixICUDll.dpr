program FixICUDll;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Net.HttpClient,
  System.IOUtils,
  Winapi.Windows,
  Winapi.ShellAPI;

// 简单实现IfThen函数
function IfThen(Condition: Boolean; const TrueValue, FalseValue: string): string;
begin
  if Condition then
    Result := TrueValue
  else
    Result := FalseValue;
end;

// 检查DLL是64位还是32位
function Is64BitDll(const DllPath: string): Boolean;
const
  IMAGE_DOS_SIGNATURE = $5A4D;  // MZ
  IMAGE_NT_SIGNATURE = $00004550; // PE00
  IMAGE_FILE_MACHINE_AMD64 = $8664; // 64位架构
type
  // PE文件头结构
  TImageDosHeader = record
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
  PImageDosHeader = ^TImageDosHeader;

  TImageFileHeader = record
    Machine: Word;
    NumberOfSections: Word;
    TimeDateStamp: DWORD;
    PointerToSymbolTable: DWORD;
    NumberOfSymbols: DWORD;
    SizeOfOptionalHeader: Word;
    Characteristics: Word;
  end;

  TImageNtHeaders = record
    Signature: DWORD;
    FileHeader: TImageFileHeader;
  end;
  PImageNtHeaders = ^TImageNtHeaders;
var
  ImageNtHeaders: PImageNtHeaders;
  ImageDosHeader: PImageDosHeader;
  FileHandle: THandle;
  MapHandle: THandle;
  ViewBase: Pointer;
  FileSize: DWORD;
begin
  Result := False;
  
  // 打开文件
  FileHandle := CreateFile(PChar(DllPath), GENERIC_READ, FILE_SHARE_READ, nil, 
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if FileHandle = INVALID_HANDLE_VALUE then
    Exit;
  
  try
    FileSize := GetFileSize(FileHandle, nil);
    if FileSize = INVALID_FILE_SIZE then
      Exit;
    
    // 创建内存映射
    MapHandle := CreateFileMapping(FileHandle, nil, PAGE_READONLY, 0, 0, nil);
    if MapHandle = 0 then
      Exit;
    
    try
      ViewBase := MapViewOfFile(MapHandle, FILE_MAP_READ, 0, 0, 0);
      if ViewBase = nil then
        Exit;
      
      try
        // 读取DOS头
        ImageDosHeader := PImageDosHeader(ViewBase);
        if ImageDosHeader^.e_magic <> IMAGE_DOS_SIGNATURE then
          Exit;
        
        // 读取NT头
        ImageNtHeaders := PImageNtHeaders(PByte(ViewBase) + ImageDosHeader^.e_lfanew);
        if ImageNtHeaders^.Signature <> IMAGE_NT_SIGNATURE then
          Exit;
        
        // 判断是否为64位
        Result := ImageNtHeaders^.FileHeader.Machine = IMAGE_FILE_MACHINE_AMD64;
      finally
        UnmapViewOfFile(ViewBase);
      end;
    finally
      CloseHandle(MapHandle);
    end;
  finally
    CloseHandle(FileHandle);
  end;
end;

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

// 下载Visual C++ Redistributable
function DownloadVCRedist: Boolean;
var
  URL: string;
  SavePath: string;
  HttpClient: THTTPClient;
  FileStream: TFileStream;
begin
  Result := False;
  
  // 64位Visual C++ Redistributable 2022
  URL := 'https://aka.ms/vs/17/release/vc_redist.x64.exe';
  SavePath := ExtractFilePath(ParamStr(0)) + 'vc_redist.x64.exe';
  
  Writeln('正在下载Visual C++ Redistributable...');
  Writeln('URL: ', URL);
  Writeln('保存路径: ', SavePath);
  
  try
    HttpClient := THTTPClient.Create;
    try
      FileStream := TFileStream.Create(SavePath, fmCreate);
      try
        HttpClient.Get(URL, FileStream);
        Result := True;
      finally
        FileStream.Free;
      end;
    finally
      HttpClient.Free;
    end;
    
    if Result then
      Writeln('下载完成: ', SavePath)
    else
      Writeln('下载失败');
  except
    on E: Exception do
    begin
      Writeln('下载Visual C++ Redistributable时发生错误: ', E.Message);
      Result := False;
    end;
  end;
end;

// 安装Visual C++ Redistributable
function InstallVCRedist(const FilePath: string): Boolean;
var
  ExecInfo: TShellExecuteInfo;
  ExitCode: DWORD;
begin
  Result := False;
  
  Writeln('正在安装Visual C++ Redistributable...');
  
  FillChar(ExecInfo, SizeOf(ExecInfo), 0);
  ExecInfo.cbSize := SizeOf(ExecInfo);
  ExecInfo.fMask := SEE_MASK_NOCLOSEPROCESS;
  ExecInfo.lpFile := PChar(FilePath);
  ExecInfo.lpParameters := '/quiet /norestart';
  ExecInfo.nShow := SW_SHOW;
  
  if ShellExecuteEx(@ExecInfo) then
  begin
    Writeln('安装程序已启动，等待完成...');
    WaitForSingleObject(ExecInfo.hProcess, INFINITE);
    
    if GetExitCodeProcess(ExecInfo.hProcess, ExitCode) then
    begin
      Result := (ExitCode = 0) or (ExitCode = 3010); // 3010表示需要重启
      if Result then
        Writeln('安装成功完成')
      else
        Writeln('安装失败，退出代码: ', ExitCode);
    end;
    
    CloseHandle(ExecInfo.hProcess);
  end
  else
  begin
    Writeln('无法启动安装程序: ', GetLastErrorMessage);
  end;
end;

function TestICUDllLoad: Boolean;
var
  IcuDllHandle: HMODULE;
  u_errorName: function(code: Integer): PAnsiChar; cdecl;
begin
  Result := False;
  
  Writeln('尝试加载ICU DLL...');
  
  IcuDllHandle := LoadLibrary('icuuc77.dll');
  if IcuDllHandle <> 0 then
  begin
    Writeln('成功加载 icuuc77.dll');
    
    // 尝试获取一个函数指针
    u_errorName := GetProcAddress(IcuDllHandle, 'u_errorName');
    if Assigned(u_errorName) then
    begin
      Writeln('成功获取 u_errorName 函数指针');
      Writeln('u_errorName(0) = ', string(u_errorName(0)));
      Result := True;
    end
    else
    begin
      Writeln('无法获取 u_errorName 函数指针: ', GetLastErrorMessage);
    end;
    
    FreeLibrary(IcuDllHandle);
  end
  else
  begin
    Writeln('无法加载 icuuc77.dll: ', GetLastErrorMessage);
  end;
end;

var
  DllPath: string;
  Is64Bit: Boolean;
  RedistPath: string;
  
begin
  try
    Writeln('ICU DLL 修复工具');
    Writeln('=================');
    Writeln;
    
    // 检查ICU DLL是否存在
    DllPath := ExtractFilePath(ParamStr(0)) + 'icuuc77.dll';
    if not FileExists(DllPath) then
    begin
      Writeln('错误: icuuc77.dll 不存在于当前目录');
      Exit;
    end;
    
    // 检查DLL是否为64位
    Is64Bit := Is64BitDll(DllPath);
    Writeln('icuuc77.dll 架构: ', IfThen(Is64Bit, '64位', '32位'));
    
    // 尝试加载DLL
    if TestICUDllLoad then
    begin
      Writeln('ICU DLL已经可以正常加载，无需修复');
      Exit;
    end;
    
    // 下载安装VC++ Redistributable
    Writeln('ICU DLL加载失败，可能缺少Visual C++ Redistributable');
    Writeln('是否下载并安装Visual C++ Redistributable 2022? (Y/N)');
    if UpperCase(ReadLn) = 'Y' then
    begin
      if DownloadVCRedist then
      begin
        RedistPath := ExtractFilePath(ParamStr(0)) + 'vc_redist.x64.exe';
        if InstallVCRedist(RedistPath) then
        begin
          Writeln('Visual C++ Redistributable 安装完成，重新测试ICU DLL');
          if TestICUDllLoad then
            Writeln('成功: ICU DLL现在可以正常加载')
          else
            Writeln('问题仍然存在，ICU DLL无法加载');
        end;
      end;
    end;
    
    Writeln;
    Writeln('按任意键退出...');
    ReadLn;
  except
    on E: Exception do
    begin
      Writeln('程序错误: ', E.ClassName, ': ', E.Message);
      ReadLn;
    end;
  end;
end. 