unit UtilsMemoryMappedFile;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows;

type
  /// <summary>
  /// 内存映射文件异常类
  /// </summary>
  EMemoryMappedFileError = class(Exception);

  /// <summary>
  /// 内存映射文件访问模式
  /// </summary>
  TMemoryMappedFileAccess = (
    mmfaRead,      // 只读访问
    mmfaWrite,     // 只写访问
    mmfaReadWrite  // 读写访问
  );

  /// <summary>
  /// 内存映射文件类
  /// </summary>
  TMemoryMappedFile = class
  private
    FFileName: string;
    FFileHandle: THandle;
    FMappingHandle: THandle;
    FMappedView: Pointer;
    FFileSize: Int64;
    FAccess: TMemoryMappedFileAccess;
    FIsOpen: Boolean;
    FIsReadOnly: Boolean;
    FLogCallback: TProc<string>;

    procedure Log(const Msg: string);
    procedure CheckIsOpen;
    procedure SetFileSize(const Value: Int64);
    function GetPageSize: DWORD;
    function GetAllocationGranularity: DWORD;
    function GetSystemInfo: SYSTEM_INFO;
    function GetProtection: DWORD;
    function GetDesiredAccess: DWORD;
    function GetMapAccess: DWORD;
  public
    /// <summary>
    /// 创建内存映射文件对象
    /// </summary>
    constructor Create(const ALogCallback: TProc<string> = nil);
    
    /// <summary>
    /// 销毁内存映射文件对象
    /// </summary>
    destructor Destroy; override;
    
    /// <summary>
    /// 打开文件并创建内存映射
    /// </summary>
    procedure Open(const AFileName: string; AAccess: TMemoryMappedFileAccess = mmfaRead);
    
    /// <summary>
    /// 关闭内存映射和文件
    /// </summary>
    procedure Close;
    
    /// <summary>
    /// 将内存映射的内容刷新到磁盘
    /// </summary>
    procedure Flush;
    
    /// <summary>
    /// 读取数据到缓冲区
    /// </summary>
    function Read(var Buffer; Offset, Count: Int64): Int64;
    
    /// <summary>
    /// 将缓冲区数据写入内存映射
    /// </summary>
    function Write(const Buffer; Offset, Count: Int64): Int64;
    
    /// <summary>
    /// 读取整个文件内容到字节数组
    /// </summary>
    function ReadAll: TBytes;
    
    /// <summary>
    /// 将字节数组写入整个文件
    /// </summary>
    procedure WriteAll(const Buffer: TBytes);
    
    /// <summary>
    /// 读取整个文件内容为字符串
    /// </summary>
    function ReadAllText(Encoding: TEncoding = nil): string;
    
    /// <summary>
    /// 将字符串写入整个文件
    /// </summary>
    procedure WriteAllText(const Text: string; Encoding: TEncoding = nil);
    
    /// <summary>
    /// 获取指定偏移量处的内存指针
    /// </summary>
    function GetPointer(Offset: Int64 = 0): Pointer;
    
    /// <summary>
    /// 文件名
    /// </summary>
    property FileName: string read FFileName;
    
    /// <summary>
    /// 文件大小
    /// </summary>
    property FileSize: Int64 read FFileSize write SetFileSize;
    
    /// <summary>
    /// 访问模式
    /// </summary>
    property Access: TMemoryMappedFileAccess read FAccess;
    
    /// <summary>
    /// 是否已打开
    /// </summary>
    property IsOpen: Boolean read FIsOpen;
    
    /// <summary>
    /// 是否只读
    /// </summary>
    property IsReadOnly: Boolean read FIsReadOnly;
  end;

implementation

{ TMemoryMappedFile }

constructor TMemoryMappedFile.Create(const ALogCallback: TProc<string>);
begin
  inherited Create;
  FFileHandle := INVALID_HANDLE_VALUE;
  FMappingHandle := 0;
  FMappedView := nil;
  FFileSize := 0;
  FIsOpen := False;
  FIsReadOnly := True;
  FLogCallback := ALogCallback;
end;

destructor TMemoryMappedFile.Destroy;
begin
  Close;
  inherited;
end;

procedure TMemoryMappedFile.Log(const Msg: string);
begin
  if Assigned(FLogCallback) then
    FLogCallback(Msg);
end;

procedure TMemoryMappedFile.CheckIsOpen;
begin
  if not FIsOpen then
    raise EMemoryMappedFileError.Create('内存映射文件未打开');
end;

function TMemoryMappedFile.GetAllocationGranularity: DWORD;
begin
  Result := GetSystemInfo.dwAllocationGranularity;
end;

function TMemoryMappedFile.GetDesiredAccess: DWORD;
begin
  case FAccess of
    mmfaRead: Result := GENERIC_READ;
    mmfaWrite: Result := GENERIC_WRITE;
    mmfaReadWrite: Result := GENERIC_READ or GENERIC_WRITE;
    else Result := GENERIC_READ;
  end;
end;

function TMemoryMappedFile.GetMapAccess: DWORD;
begin
  case FAccess of
    mmfaRead: Result := FILE_MAP_READ;
    mmfaWrite: Result := FILE_MAP_WRITE;
    mmfaReadWrite: Result := FILE_MAP_ALL_ACCESS;
    else Result := FILE_MAP_READ;
  end;
end;

function TMemoryMappedFile.GetPageSize: DWORD;
begin
  Result := GetSystemInfo.dwPageSize;
end;

function TMemoryMappedFile.GetPointer(Offset: Int64): Pointer;
begin
  CheckIsOpen;
  if (Offset < 0) or (Offset >= FFileSize) then
    raise EMemoryMappedFileError.CreateFmt('偏移量 %d 超出文件范围 (0-%d)', [Offset, FFileSize - 1]);
  Result := Pointer(NativeUInt(FMappedView) + NativeUInt(Offset));
end;

function TMemoryMappedFile.GetProtection: DWORD;
begin
  case FAccess of
    mmfaRead: Result := PAGE_READONLY;
    mmfaWrite: Result := PAGE_READWRITE;
    mmfaReadWrite: Result := PAGE_READWRITE;
    else Result := PAGE_READONLY;
  end;
end;

function TMemoryMappedFile.GetSystemInfo: SYSTEM_INFO;
begin
  ZeroMemory(@Result, SizeOf(SYSTEM_INFO));
  Winapi.Windows.GetSystemInfo(Result);
end;

procedure TMemoryMappedFile.Open(const AFileName: string; AAccess: TMemoryMappedFileAccess);
var
  FileMode: DWORD;
  FileCreation: DWORD;
  MaxSizeHigh, MaxSizeLow: DWORD;
  FileInfo: TWin32FileAttributeData;
begin
  // 关闭已打开的文件
  Close;
  
  FFileName := AFileName;
  FAccess := AAccess;
  FIsReadOnly := (AAccess = mmfaRead);
  
  try
    // 设置文件打开模式
    FileMode := GetDesiredAccess;
    
    // 设置文件创建模式
    if FIsReadOnly then
      FileCreation := OPEN_EXISTING
    else
      FileCreation := OPEN_ALWAYS;
    
    // 打开文件
    FFileHandle := CreateFile(
      PChar(FFileName),
      FileMode,
      FILE_SHARE_READ,
      nil,
      FileCreation,
      FILE_ATTRIBUTE_NORMAL,
      0
    );
    
    if FFileHandle = INVALID_HANDLE_VALUE then
      raise EMemoryMappedFileError.CreateFmt('无法打开文件 "%s": %s', 
        [FFileName, SysErrorMessage(GetLastError)]);
    
    // 获取文件大小
    if not GetFileAttributesEx(PChar(FFileName), GetFileExInfoStandard, @FileInfo) then
      raise EMemoryMappedFileError.CreateFmt('无法获取文件 "%s" 的属性: %s', 
        [FFileName, SysErrorMessage(GetLastError)]);
    
    FFileSize := Int64(FileInfo.nFileSizeLow) or (Int64(FileInfo.nFileSizeHigh) shl 32);
    
    // 如果文件为空，则设置最小大小
    if FFileSize = 0 then
    begin
      if not FIsReadOnly then
      begin
        FFileSize := GetPageSize;
        SetFilePointer(FFileHandle, FFileSize, nil, FILE_BEGIN);
        SetEndOfFile(FFileHandle);
      end
      else
      begin
        // 只读模式下不能映射空文件
        Close;
        raise EMemoryMappedFileError.CreateFmt('无法映射空文件 "%s" 为只读模式', [FFileName]);
      end;
    end;
    
    // 创建文件映射对象
    MaxSizeHigh := DWORD(FFileSize shr 32);
    MaxSizeLow := DWORD(FFileSize and $FFFFFFFF);
    
    FMappingHandle := CreateFileMapping(
      FFileHandle,
      nil,
      GetProtection,
      MaxSizeHigh,
      MaxSizeLow,
      nil
    );
    
    if FMappingHandle = 0 then
    begin
      CloseHandle(FFileHandle);
      FFileHandle := INVALID_HANDLE_VALUE;
      raise EMemoryMappedFileError.CreateFmt('无法创建文件 "%s" 的内存映射: %s', 
        [FFileName, SysErrorMessage(GetLastError)]);
    end;
    
    // 映射文件视图
    FMappedView := MapViewOfFile(
      FMappingHandle,
      GetMapAccess,
      0,
      0,
      0  // 映射整个文件
    );
    
    if FMappedView = nil then
    begin
      CloseHandle(FMappingHandle);
      FMappingHandle := 0;
      CloseHandle(FFileHandle);
      FFileHandle := INVALID_HANDLE_VALUE;
      raise EMemoryMappedFileError.CreateFmt('无法映射文件 "%s" 的视图: %s', 
        [FFileName, SysErrorMessage(GetLastError)]);
    end;
    
    FIsOpen := True;
    Log(Format('成功打开并映射文件 "%s", 大小: %d 字节', [FFileName, FFileSize]));
  except
    on E: Exception do
    begin
      Close;
      Log(Format('打开文件 "%s" 失败: %s', [FFileName, E.Message]));
      raise;
    end;
  end;
end;

procedure TMemoryMappedFile.Close;
begin
  if FMappedView <> nil then
  begin
    UnmapViewOfFile(FMappedView);
    FMappedView := nil;
  end;
  
  if FMappingHandle <> 0 then
  begin
    CloseHandle(FMappingHandle);
    FMappingHandle := 0;
  end;
  
  if FFileHandle <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FFileHandle);
    FFileHandle := INVALID_HANDLE_VALUE;
  end;
  
  FIsOpen := False;
  FFileSize := 0;
  
  if FFileName <> '' then
    Log(Format('关闭文件 "%s"', [FFileName]));
    
  FFileName := '';
end;

procedure TMemoryMappedFile.Flush;
begin
  CheckIsOpen;
  
  if not FlushViewOfFile(FMappedView, 0) then
    raise EMemoryMappedFileError.CreateFmt('无法刷新文件 "%s" 的内存映射: %s', 
      [FFileName, SysErrorMessage(GetLastError)]);
      
  Log(Format('刷新文件 "%s" 的内存映射', [FFileName]));
end;

function TMemoryMappedFile.Read(var Buffer; Offset, Count: Int64): Int64;
var
  Ptr: Pointer;
begin
  CheckIsOpen;
  
  if (Offset < 0) or (Offset >= FFileSize) then
    raise EMemoryMappedFileError.CreateFmt('读取偏移量 %d 超出文件范围 (0-%d)', 
      [Offset, FFileSize - 1]);
      
  // 调整读取大小，确保不超出文件末尾
  if Offset + Count > FFileSize then
    Count := FFileSize - Offset;
    
  if Count <= 0 then
    Exit(0);
    
  // 获取源指针
  Ptr := GetPointer(Offset);
  
  // 复制数据
  Move(Ptr^, Buffer, Count);
  
  Result := Count;
end;

function TMemoryMappedFile.ReadAll: TBytes;
begin
  CheckIsOpen;
  
  SetLength(Result, FFileSize);
  if FFileSize > 0 then
    Move(FMappedView^, Result[0], FFileSize);
end;

function TMemoryMappedFile.ReadAllText(Encoding: TEncoding): string;
var
  Bytes: TBytes;
begin
  Bytes := ReadAll;
  
  if Encoding = nil then
    Encoding := TEncoding.Default;
    
  Result := Encoding.GetString(Bytes);
end;

procedure TMemoryMappedFile.SetFileSize(const Value: Int64);
begin
  if FIsReadOnly then
    raise EMemoryMappedFileError.Create('无法调整只读文件的大小');
    
  if Value = FFileSize then
    Exit;
    
  // 关闭当前映射
  Close;
  
  // 重新打开文件
  Open(FFileName, FAccess);
  
  // 调整文件大小
  if Value > FFileSize then
  begin
    SetFilePointer(FFileHandle, Value, nil, FILE_BEGIN);
    SetEndOfFile(FFileHandle);
    
    // 重新创建映射
    Close;
    Open(FFileName, FAccess);
  end;
end;

function TMemoryMappedFile.Write(const Buffer; Offset, Count: Int64): Int64;
var
  Ptr: Pointer;
begin
  CheckIsOpen;
  
  if FIsReadOnly then
    raise EMemoryMappedFileError.Create('无法写入只读文件');
    
  if (Offset < 0) or (Offset >= FFileSize) then
    raise EMemoryMappedFileError.CreateFmt('写入偏移量 %d 超出文件范围 (0-%d)', 
      [Offset, FFileSize - 1]);
      
  // 调整写入大小，确保不超出文件末尾
  if Offset + Count > FFileSize then
    Count := FFileSize - Offset;
    
  if Count <= 0 then
    Exit(0);
    
  // 获取目标指针
  Ptr := GetPointer(Offset);
  
  // 复制数据
  Move(Buffer, Ptr^, Count);
  
  Result := Count;
end;

procedure TMemoryMappedFile.WriteAll(const Buffer: TBytes);
var
  NewSize: Int64;
begin
  CheckIsOpen;
  
  if FIsReadOnly then
    raise EMemoryMappedFileError.Create('无法写入只读文件');
    
  NewSize := Length(Buffer);
  
  // 如果新内容大小与文件大小不同，需要调整文件大小
  if NewSize <> FFileSize then
  begin
    // 关闭当前映射
    Close;
    
    // 创建或打开文件
    FFileHandle := CreateFile(
      PChar(FFileName),
      GENERIC_READ or GENERIC_WRITE,
      FILE_SHARE_READ,
      nil,
      CREATE_ALWAYS,
      FILE_ATTRIBUTE_NORMAL,
      0
    );
    
    if FFileHandle = INVALID_HANDLE_VALUE then
      raise EMemoryMappedFileError.CreateFmt('无法创建文件 "%s": %s', 
        [FFileName, SysErrorMessage(GetLastError)]);
        
    try
      // 设置文件大小
      SetFilePointer(FFileHandle, NewSize, nil, FILE_BEGIN);
      SetEndOfFile(FFileHandle);
      
      // 重新打开文件映射
      Close;
      Open(FFileName, FAccess);
    except
      CloseHandle(FFileHandle);
      FFileHandle := INVALID_HANDLE_VALUE;
      raise;
    end;
  end;
  
  // 写入数据
  if NewSize > 0 then
    Move(Buffer[0], FMappedView^, NewSize);
    
  // 刷新到磁盘
  Flush;
end;

procedure TMemoryMappedFile.WriteAllText(const Text: string; Encoding: TEncoding);
var
  Bytes: TBytes;
begin
  if Encoding = nil then
    Encoding := TEncoding.Default;
    
  Bytes := Encoding.GetBytes(Text);
  WriteAll(Bytes);
end;

end.
