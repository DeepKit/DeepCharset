unit UtilsPathSecurity;

{
  路径安全验证模块
  
  功能：
  - 路径规范化与验证
  - 防止路径遍历攻击
  - 系统关键目录保护
  - 文件权限检查
  
  P0-3: Bug #7 文件操作安全检查
  创建时间: 2025-12-06
}

interface

uses
  System.SysUtils, System.IOUtils, System.Classes, Winapi.Windows;

type
  /// <summary>
  /// 路径安全检查结果
  /// </summary>
  TPathSecurityResult = record
    IsSafe: Boolean;              // 路径是否安全
    NormalizedPath: string;       // 规范化后的路径
    ErrorMessage: string;         // 错误消息
    IsSystemPath: Boolean;        // 是否是系统路径
    IsReadOnly: Boolean;          // 是否只读
  end;

  /// <summary>
  /// 路径安全验证器
  /// </summary>
  TPathSecurityValidator = class
  private
    /// <summary>
    /// 系统关键目录列表
    /// </summary>
    class var FProtectedPaths: TArray<string>;
    
    /// <summary>
    /// 初始化保护路径列表
    /// </summary>
    class procedure InitializeProtectedPaths;
    
    /// <summary>
    /// 检查是否包含路径遍历字符
    /// </summary>
    class function ContainsPathTraversal(const Path: string): Boolean;
    
    /// <summary>
    /// 检查是否在保护目录中
    /// </summary>
    class function IsInProtectedDirectory(const Path: string): Boolean;
    
  public
    /// <summary>
    /// 验证路径是否安全
    /// </summary>
    class function ValidatePath(const FilePath: string): TPathSecurityResult;
    
    /// <summary>
    /// 检查路径是否安全（简化版本）
    /// </summary>
    class function IsPathSafe(const FilePath: string): Boolean;
    
    /// <summary>
    /// 添加自定义保护路径
    /// </summary>
    class procedure AddProtectedPath(const Path: string);
    
    /// <summary>
    /// 获取保护路径列表
    /// </summary>
    class function GetProtectedPaths: TArray<string>;
  end;

implementation

{ TPathSecurityValidator }

class procedure TPathSecurityValidator.InitializeProtectedPaths;
var
  WinDir, SysDir, ProgFiles, ProgFilesX86: string;
  
  procedure AddPath(const Path: string);
  var
    Len: Integer;
  begin
    if Path <> '' then
    begin
      Len := Length(FProtectedPaths);
      SetLength(FProtectedPaths, Len + 1);
      FProtectedPaths[Len] := IncludeTrailingPathDelimiter(Path);
    end;
  end;
  
begin
  if Length(FProtectedPaths) > 0 then
    Exit; // 已初始化
    
  // 获取系统目录
  SetLength(WinDir, MAX_PATH);
  GetWindowsDirectory(PChar(WinDir), MAX_PATH);
  WinDir := PChar(WinDir); // 去除尾部空字符
  
  SetLength(SysDir, MAX_PATH);
  GetSystemDirectory(PChar(SysDir), MAX_PATH);
  SysDir := PChar(SysDir);
  
  ProgFiles := GetEnvironmentVariable('ProgramFiles');
  ProgFilesX86 := GetEnvironmentVariable('ProgramFiles(x86)');
  
  // Bug #15 修复：使用动态追加方式，避免空字符串元素
  SetLength(FProtectedPaths, 0);
  AddPath(WinDir);
  AddPath(SysDir);
  AddPath(ProgFiles);
  AddPath(ProgFilesX86);  // 仅在非空时添加
  AddPath('C:\Windows');
  AddPath('C:\System32');
end;

class function TPathSecurityValidator.ContainsPathTraversal(const Path: string): Boolean;
begin
  // 检查是否包含 ".." 路径遍历
  Result := Path.Contains('..') or 
            Path.Contains('/../') or 
            Path.Contains('\..\');
end;

class function TPathSecurityValidator.IsInProtectedDirectory(const Path: string): Boolean;
var
  NormalizedPath: string;
  ProtectedPath: string;
begin
  Result := False;
  
  // 初始化保护路径
  InitializeProtectedPaths;
  
  // 规范化路径（转为大写以便比较）
  NormalizedPath := UpperCase(IncludeTrailingPathDelimiter(Path));
  
  // 检查是否以任何保护路径开头
  for ProtectedPath in FProtectedPaths do
  begin
    if ProtectedPath <> '' then
    begin
      if NormalizedPath.StartsWith(UpperCase(ProtectedPath)) then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
end;

class function TPathSecurityValidator.ValidatePath(const FilePath: string): TPathSecurityResult;
var
  ExpandedPath: string;
begin
  // 初始化结果
  Result.IsSafe := False;
  Result.NormalizedPath := '';
  Result.ErrorMessage := '';
  Result.IsSystemPath := False;
  Result.IsReadOnly := False;
  
  // 检查空路径
  if Trim(FilePath) = '' then
  begin
    Result.ErrorMessage := '路径不能为空';
    Exit;
  end;
  
  // Bug #12 修复：在规范化之前检查原始路径是否包含路径遍历字符
  // 这样可以阻止 "C:\temp\..\Windows\system32\file.txt" 这类恶意输入
  if ContainsPathTraversal(FilePath) then
  begin
    Result.ErrorMessage := '路径包含非法的遍历字符 (..)';
    Exit;
  end;
  
  try
    // 规范化路径
    ExpandedPath := TPath.GetFullPath(FilePath);
    Result.NormalizedPath := ExpandedPath;
  except
    on E: Exception do
    begin
      Result.ErrorMessage := '无效的路径格式: ' + E.Message;
      Exit;
    end;
  end;
  
  // 检查是否在保护目录中
  if IsInProtectedDirectory(ExpandedPath) then
  begin
    Result.IsSystemPath := True;
    Result.ErrorMessage := '不允许访问系统关键目录';
    Exit;
  end;
  
  // 检查文件是否存在且只读
  if FileExists(ExpandedPath) then
  begin
    var Attr := TFile.GetAttributes(ExpandedPath);
    Result.IsReadOnly := TFileAttribute.faReadOnly in Attr;
  end;
  
  // 路径安全
  Result.IsSafe := True;
end;

class function TPathSecurityValidator.IsPathSafe(const FilePath: string): Boolean;
var
  ValidationResult: TPathSecurityResult;
begin
  ValidationResult := ValidatePath(FilePath);
  Result := ValidationResult.IsSafe;
end;

class procedure TPathSecurityValidator.AddProtectedPath(const Path: string);
var
  Len: Integer;
begin
  InitializeProtectedPaths;
  
  Len := Length(FProtectedPaths);
  SetLength(FProtectedPaths, Len + 1);
  FProtectedPaths[Len] := IncludeTrailingPathDelimiter(Path);
end;

class function TPathSecurityValidator.GetProtectedPaths: TArray<string>;
begin
  InitializeProtectedPaths;
  Result := FProtectedPaths;
end;

initialization
  TPathSecurityValidator.InitializeProtectedPaths;

end.
