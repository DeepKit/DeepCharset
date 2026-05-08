unit UtilsTempFileSecurity;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.SyncObjs, Winapi.Windows;

type
  /// <summary>
  /// 临时文件安全管理器
  /// 提供安全的临时文件创建和删除功能
  /// </summary>
  TTempFileSecurityManager = class
  private
    class var FTempFileList: TStringList;
    class var FTempFileListLock: TCriticalSection;  // Bug #14: 线程安全锁
    class var FAutoCleanup: Boolean;
    class constructor Create;
    class destructor Destroy;
  public
    /// <summary>
    /// 获取安全的临时文件路径
    /// 使用GUID确保文件名不可预测
    /// </summary>
    /// <param name="Prefix">文件名前缀（默认为 "DeepCharset_"）</param>
    /// <param name="Extension">文件扩展名（默认为 ".tmp"）</param>
    /// <returns>完整的临时文件路径</returns>
    class function GetSecureTempFile(const Prefix: string = 'DeepCharset_'; 
                                    const Extension: string = '.tmp'): string;
    
    /// <summary>
    /// 在指定目录生成安全的临时文件路径（Bug #11 修复）
    /// 避免跨卷重命名失败问题
    /// </summary>
    /// <param name="TargetDir">目标目录</param>
    /// <param name="Prefix">文件名前缀（默认为 "DeepCharset_"）</param>
    /// <param name="Extension">文件扩展名（默认为 ".tmp"）</param>
    /// <returns>完整的临时文件路径</returns>
    class function GetSecureTempFileInDir(const TargetDir: string;
                                         const Prefix: string = 'DeepCharset_'; 
                                         const Extension: string = '.tmp'): string;
    
    /// <summary>
    /// 安全删除文件
    /// 先用零覆写文件内容，然后删除
    /// </summary>
    /// <param name="FileName">要删除的文件路径</param>
    /// <param name="OverwritePasses">覆写次数（默认为1次）</param>
    /// <returns>删除是否成功</returns>
    class function SecureDeleteFile(const FileName: string; 
                                   const OverwritePasses: Integer = 1): Boolean;
    
    /// <summary>
    /// 注册临时文件以便自动清理
    /// </summary>
    /// <param name="FileName">临时文件路径</param>
    class procedure RegisterTempFile(const FileName: string);
    
    /// <summary>
    /// 取消注册临时文件
    /// </summary>
    /// <param name="FileName">临时文件路径</param>
    class procedure UnregisterTempFile(const FileName: string);
    
    /// <summary>
    /// 清理所有已注册的临时文件
    /// </summary>
    class procedure CleanupAllTempFiles;
    
    /// <summary>
    /// 启用或禁用程序退出时的自动清理
    /// </summary>
    /// <param name="Value">是否启用自动清理</param>
    class procedure SetAutoCleanup(const Value: Boolean);
    
    /// <summary>
    /// 获取临时文件目录
    /// </summary>
    class function GetTempDirectory: string;
  end;

implementation

uses
  System.Math;

const
  // 覆写缓冲区大小 (4KB)
  OVERWRITE_BUFFER_SIZE = 4096;

{ TTempFileSecurityManager }

class constructor TTempFileSecurityManager.Create;
begin
  FTempFileListLock := TCriticalSection.Create;  // Bug #14: 初始化锁
  FTempFileList := TStringList.Create;
  FTempFileList.Duplicates := dupIgnore;
  FTempFileList.Sorted := True;
  FAutoCleanup := True;
end;

class destructor TTempFileSecurityManager.Destroy;
begin
  if FAutoCleanup then
    CleanupAllTempFiles;
  FreeAndNil(FTempFileList);
  FreeAndNil(FTempFileListLock);  // Bug #14: 释放锁
end;

class function TTempFileSecurityManager.GetTempDirectory: string;
begin
  Result := TPath.GetTempPath;
end;

class function TTempFileSecurityManager.GetSecureTempFile(
  const Prefix, Extension: string): string;
var
  TempDir: string;
  FileName: string;
  GUID: TGUID;
  GUIDStr: string;
begin
  // 获取系统临时目录
  TempDir := GetTempDirectory;
  
  // 生成GUID
  if CreateGUID(GUID) = S_OK then
  begin
    // 转换GUID为字符串（移除大括号和连字符）
    GUIDStr := GUIDToString(GUID);
    GUIDStr := StringReplace(GUIDStr, '{', '', [rfReplaceAll]);
    GUIDStr := StringReplace(GUIDStr, '}', '', [rfReplaceAll]);
    GUIDStr := StringReplace(GUIDStr, '-', '', [rfReplaceAll]);
  end
  else
  begin
    // 如果GUID生成失败，使用时间戳作为备用方案
    GUIDStr := FormatDateTime('yyyymmddhhnnsszzz', Now) + '_' + IntToStr(Random(99999));
  end;
  
  // 组合文件名
  FileName := Prefix + GUIDStr + Extension;
  Result := TPath.Combine(TempDir, FileName);
  
  // 确保文件不存在（理论上GUID应该是唯一的）
  if FileExists(Result) then
  begin
    // 如果文件存在，递归调用生成新的文件名
    Result := GetSecureTempFile(Prefix, Extension);
  end;
end;

class function TTempFileSecurityManager.GetSecureTempFileInDir(
  const TargetDir: string;
  const Prefix, Extension: string): string;
var
  FileName: string;
  GUID: TGUID;
  GUIDStr: string;
  ActualDir: string;
begin
  // Bug #11 修复：在目标目录生成临时文件，避免跨卷重命名失败
  
  // 确定目标目录
  if TargetDir = '' then
    ActualDir := GetTempDirectory
  else
    ActualDir := TargetDir;
  
  // 确保目录存在
  if not TDirectory.Exists(ActualDir) then
    ForceDirectories(ActualDir);
  
  // 生成GUID
  if CreateGUID(GUID) = S_OK then
  begin
    GUIDStr := GUIDToString(GUID);
    GUIDStr := StringReplace(GUIDStr, '{', '', [rfReplaceAll]);
    GUIDStr := StringReplace(GUIDStr, '}', '', [rfReplaceAll]);
    GUIDStr := StringReplace(GUIDStr, '-', '', [rfReplaceAll]);
  end
  else
  begin
    // 备用方案：时间戳 + 随机数
    GUIDStr := FormatDateTime('yyyymmddhhnnsszzz', Now) + '_' + IntToStr(Random(99999));
  end;
  
  // 组合文件名
  FileName := Prefix + GUIDStr + Extension;
  Result := TPath.Combine(ActualDir, FileName);
  
  // 确保文件不存在
  if FileExists(Result) then
    Result := GetSecureTempFileInDir(TargetDir, Prefix, Extension);
end;

class function TTempFileSecurityManager.SecureDeleteFile(
  const FileName: string; const OverwritePasses: Integer): Boolean;
var
  FileStream: TFileStream;
  ZeroBuffer: array[0..OVERWRITE_BUFFER_SIZE-1] of Byte;
  RandomBuffer: array[0..OVERWRITE_BUFFER_SIZE-1] of Byte;
  FileSize: Int64;
  BytesToWrite: Integer;
  Pass: Integer;
  i: Integer;
begin
  Result := False;
  
  // 检查文件是否存在
  if not FileExists(FileName) then
  begin
    Result := True; // 文件不存在视为成功
    Exit;
  end;
  
  try
    // 打开文件进行覆写
    FileStream := TFileStream.Create(FileName, fmOpenReadWrite or fmShareDenyWrite);
    try
      FileSize := FileStream.Size;
      
      // 执行多次覆写
      for Pass := 1 to OverwritePasses do
      begin
        FileStream.Position := 0;
        
        // 第一次用零覆写，后续用随机数
        if Pass = 1 then
          FillChar(ZeroBuffer, SizeOf(ZeroBuffer), 0)
        else
        begin
          // 生成随机数据
          for i := 0 to OVERWRITE_BUFFER_SIZE - 1 do
            RandomBuffer[i] := Random(256);
        end;
        
        // 覆写整个文件
        while FileStream.Position < FileSize do
        begin
          BytesToWrite := Min(OVERWRITE_BUFFER_SIZE, FileSize - FileStream.Position);
          if Pass = 1 then
            FileStream.Write(ZeroBuffer, BytesToWrite)
          else
            FileStream.Write(RandomBuffer, BytesToWrite);
        end;
        
        // 刷新到磁盘
        FlushFileBuffers(FileStream.Handle);
      end;
      
    finally
      FileStream.Free;
    end;
    
    // 删除文件
    Result := System.SysUtils.DeleteFile(FileName);
    
  except
    on E: Exception do
    begin
      // 记录错误但不抛出异常
      Result := False;
    end;
  end;
end;

class procedure TTempFileSecurityManager.RegisterTempFile(const FileName: string);
begin
  // Bug #14: 线程安全保护
  FTempFileListLock.Enter;
  try
    if FTempFileList <> nil then
      FTempFileList.Add(FileName);
  finally
    FTempFileListLock.Leave;
  end;
end;

class procedure TTempFileSecurityManager.UnregisterTempFile(const FileName: string);
var
  Index: Integer;
begin
  // Bug #14: 线程安全保护
  FTempFileListLock.Enter;
  try
    if FTempFileList <> nil then
    begin
      Index := FTempFileList.IndexOf(FileName);
      if Index >= 0 then
        FTempFileList.Delete(Index);
    end;
  finally
    FTempFileListLock.Leave;
  end;
end;

class procedure TTempFileSecurityManager.CleanupAllTempFiles;
var
  i: Integer;
  FileName: string;
  FilesToDelete: TArray<string>;
begin
  // Bug #14: 线程安全保护 - 先复制列表再删除
  FTempFileListLock.Enter;
  try
    if FTempFileList <> nil then
    begin
      SetLength(FilesToDelete, FTempFileList.Count);
      for i := 0 to FTempFileList.Count - 1 do
        FilesToDelete[i] := FTempFileList[i];
      FTempFileList.Clear;
    end;
  finally
    FTempFileListLock.Leave;
  end;
  
  // 在锁外执行文件删除操作，避免长时间持有锁
  for FileName in FilesToDelete do
  begin
    if FileExists(FileName) then
      SecureDeleteFile(FileName);
  end;
end;

class procedure TTempFileSecurityManager.SetAutoCleanup(const Value: Boolean);
begin
  FAutoCleanup := Value;
end;

end.
