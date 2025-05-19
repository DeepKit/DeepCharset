unit UtilsEncodingCache;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.DateUtils,
  Winapi.Windows, UtilsEncodingTypes;

type
  /// <summary>
  /// 编码检测结果缓存项
  /// </summary>
  TEncodingCacheItem = record
    FileName: string;           // 文件名
    FileSize: Int64;            // 文件大小
    FileModified: TDateTime;    // 文件修改时间
    DetectionResult: TEncodingDetectionResult; // 检测结果
    ExpirationTime: TDateTime;  // 过期时间
  end;

  /// <summary>
  /// 编码检测结果缓存管理器
  /// </summary>
  TEncodingCache = class
  private
    class var FCacheItems: TDictionary<string, TEncodingCacheItem>;
    class var FCacheEnabled: Boolean;
    class var FCacheTimeout: Integer; // 缓存超时时间（分钟）
    class var FMaxCacheSize: Integer; // 最大缓存项数

    class procedure Initialize; static;
    class procedure Cleanup; static;
    class procedure CleanExpiredItems; static;

  public
    /// <summary>
    /// 初始化缓存
    /// </summary>
    class procedure Init(MaxCacheSize: Integer = 1000; CacheTimeout: Integer = 60); static;

    /// <summary>
    /// 关闭缓存
    /// </summary>
    class procedure Shutdown; static;

    /// <summary>
    /// 启用或禁用缓存
    /// </summary>
    class procedure SetCacheEnabled(Enabled: Boolean); static;

    /// <summary>
    /// 获取缓存项
    /// </summary>
    class function GetCacheItem(const FileName: string; out DetectionResult: TEncodingDetectionResult): Boolean; static;

    /// <summary>
    /// 添加缓存项
    /// </summary>
    class procedure AddCacheItem(const FileName: string; const DetectionResult: TEncodingDetectionResult); static;

    /// <summary>
    /// 清除缓存
    /// </summary>
    class procedure ClearCache; static;

    /// <summary>
    /// 获取缓存统计信息
    /// </summary>
    class function GetCacheStats: string; static;
  end;

implementation

{ TEncodingCache }

class procedure TEncodingCache.AddCacheItem(const FileName: string; const DetectionResult: TEncodingDetectionResult);
var
  CacheItem: TEncodingCacheItem;
  FileInfo: TSearchRec;
begin
  if not FCacheEnabled then
    Exit;

  // 如果缓存已满，清理过期项
  if FCacheItems.Count >= FMaxCacheSize then
    CleanExpiredItems;

  // 如果缓存仍然已满，不添加新项
  if FCacheItems.Count >= FMaxCacheSize then
    Exit;

  // 获取文件属性
  if System.SysUtils.FindFirst(FileName, faAnyFile, FileInfo) <> 0 then
  begin
    System.SysUtils.FindClose(FileInfo);
    Exit;
  end;
  System.SysUtils.FindClose(FileInfo);

  // 创建缓存项
  CacheItem.FileName := FileName;
  CacheItem.FileSize := FileInfo.Size;
  CacheItem.FileModified := System.SysUtils.FileDateToDateTime(FileInfo.Time);
  CacheItem.DetectionResult := DetectionResult;
  CacheItem.ExpirationTime := Now + (FCacheTimeout / 1440); // 转换为天

  // 添加到缓存
  FCacheItems.AddOrSetValue(FileName, CacheItem);
end;

class procedure TEncodingCache.CleanExpiredItems;
var
  Keys: TArray<string>;
  i: Integer;
  CurrentTime: TDateTime;
begin
  CurrentTime := Now;
  Keys := FCacheItems.Keys.ToArray;

  for i := 0 to High(Keys) do
  begin
    if FCacheItems[Keys[i]].ExpirationTime < CurrentTime then
      FCacheItems.Remove(Keys[i]);
  end;
end;

class procedure TEncodingCache.ClearCache;
begin
  FCacheItems.Clear;
end;

class procedure TEncodingCache.Cleanup;
begin
  FreeAndNil(FCacheItems);
end;

class function TEncodingCache.GetCacheItem(const FileName: string; out DetectionResult: TEncodingDetectionResult): Boolean;
var
  CacheItem: TEncodingCacheItem;
  FileInfo: TSearchRec;
  FileSize: Int64;
  FileModified: TDateTime;
begin
  Result := False;

  if not FCacheEnabled then
    Exit;

  // 检查文件是否在缓存中
  if not FCacheItems.TryGetValue(FileName, CacheItem) then
    Exit;

  // 检查缓存项是否过期
  if CacheItem.ExpirationTime < Now then
  begin
    FCacheItems.Remove(FileName);
    Exit;
  end;

  // 获取文件属性
  if System.SysUtils.FindFirst(FileName, faAnyFile, FileInfo) <> 0 then
  begin
    System.SysUtils.FindClose(FileInfo);
    Exit;
  end;

  // 计算文件大小和修改时间
  FileSize := FileInfo.Size;
  FileModified := System.SysUtils.FileDateToDateTime(FileInfo.Time);
  System.SysUtils.FindClose(FileInfo);

  // 检查文件是否被修改
  if (FileSize <> CacheItem.FileSize) or (FileModified <> CacheItem.FileModified) then
  begin
    FCacheItems.Remove(FileName);
    Exit;
  end;

  // 返回缓存的检测结果
  DetectionResult := CacheItem.DetectionResult;
  Result := True;
end;

class function TEncodingCache.GetCacheStats: string;
begin
  Result := Format('缓存项数: %d, 最大缓存项数: %d, 缓存超时: %d分钟, 缓存状态: %s',
    [FCacheItems.Count, FMaxCacheSize, FCacheTimeout, System.SysUtils.BoolToStr(FCacheEnabled, True)]);
end;

class procedure TEncodingCache.Init(MaxCacheSize, CacheTimeout: Integer);
begin
  FMaxCacheSize := MaxCacheSize;
  FCacheTimeout := CacheTimeout;
  FCacheEnabled := True;
  Initialize;
end;

class procedure TEncodingCache.Initialize;
begin
  if FCacheItems = nil then
    FCacheItems := TDictionary<string, TEncodingCacheItem>.Create;
end;

class procedure TEncodingCache.SetCacheEnabled(Enabled: Boolean);
begin
  FCacheEnabled := Enabled;
  if Enabled and (FCacheItems = nil) then
    Initialize;
end;

class procedure TEncodingCache.Shutdown;
begin
  Cleanup;
end;

initialization
  TEncodingCache.Initialize;

finalization
  TEncodingCache.Cleanup;

end.
