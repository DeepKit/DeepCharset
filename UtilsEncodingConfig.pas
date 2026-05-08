unit UtilsEncodingConfig;

interface

uses
  System.SysUtils, System.IniFiles, System.IOUtils;

const
  // 默认检测阈值
  DEFAULT_MIN_UTF8_CONFIDENCE    = 0.80;
  DEFAULT_MIN_CHINESE_CONFIDENCE = 0.75;
  DEFAULT_MIN_JAPANESE_CONFIDENCE = 0.75;
  DEFAULT_MIN_KOREAN_CONFIDENCE  = 0.75;
  DEFAULT_MIN_GENERAL_CONFIDENCE = 0.75;

  // 通用缓冲区/采样配置
  DEFAULT_BUFFER_SIZE = 64 * 1024;          // 64KB
  MAX_SAMPLE_SIZE     = 16 * 1024;          // 16KB
  FILE_READ_LIMIT     = 4 * 1024 * 1024;    // 4MB

  // 性能相关默认值
  CODEPAGE_CACHE_SIZE = 32;

type
  /// <summary>
  /// 编码检测配置管理器
  /// 从配置文件读取和管理检测阈值
  /// </summary>
  TEncodingDetectionConfig = class
  private
    class var FIniFile: TIniFile;
    class var FConfigLoaded: Boolean;
    class var FMinUTF8Confidence: Double;
    class var FMinChineseConfidence: Double;
    class var FMinJapaneseConfidence: Double;
    class var FMinKoreanConfidence: Double;
    class var FMinGeneralConfidence: Double;
    
    class procedure LoadConfig;
    class function ValidateConfidence(const Value: Double): Double;
    class function GetConfigFilePath: string;
  public
    /// <summary>
    /// 初始化配置系统
    /// </summary>
    class constructor Create;
    class destructor Destroy;
    
    /// <summary>
    /// 重新加载配置
    /// </summary>
    class procedure ReloadConfig;
    
    /// <summary>
    /// 保存配置到文件
    /// </summary>
    class procedure SaveConfig;
    
    /// <summary>
    /// 获取/设置 UTF-8 检测最小置信度阈值
    /// 默认值: 0.80
    /// </summary>
    class property MinUTF8Confidence: Double read FMinUTF8Confidence write FMinUTF8Confidence;
    
    /// <summary>
    /// 获取/设置中文编码检测最小置信度阈值
    /// 默认值: 0.75
    /// </summary>
    class property MinChineseConfidence: Double read FMinChineseConfidence write FMinChineseConfidence;
    
    /// <summary>
    /// 获取/设置日文编码检测最小置信度阈值
    /// 默认值: 0.75
    /// </summary>
    class property MinJapaneseConfidence: Double read FMinJapaneseConfidence write FMinJapaneseConfidence;
    
    /// <summary>
    /// 获取/设置韩文编码检测最小置信度阈值
    /// 默认值: 0.75
    /// </summary>
    class property MinKoreanConfidence: Double read FMinKoreanConfidence write FMinKoreanConfidence;
    
    /// <summary>
    /// 获取/设置通用编码检测最小置信度阈值
    /// 默认值: 0.75
    /// </summary>
    class property MinGeneralConfidence: Double read FMinGeneralConfidence write FMinGeneralConfidence;
  end;

implementation

const
  // 置信度范围（用于 ValidateConfidence 约束配置值）
  MIN_CONFIDENCE_THRESHOLD = 0.50;  // 最小允许阈值
  MAX_CONFIDENCE_THRESHOLD = 0.99;  // 最大允许阈值

{ TEncodingDetectionConfig }

class constructor TEncodingDetectionConfig.Create;
begin
  FConfigLoaded := False;
  FIniFile := nil;
  
  // 设置默认值
  FMinUTF8Confidence := DEFAULT_MIN_UTF8_CONFIDENCE;
  FMinChineseConfidence := DEFAULT_MIN_CHINESE_CONFIDENCE;
  FMinJapaneseConfidence := DEFAULT_MIN_JAPANESE_CONFIDENCE;
  FMinKoreanConfidence := DEFAULT_MIN_KOREAN_CONFIDENCE;
  FMinGeneralConfidence := DEFAULT_MIN_GENERAL_CONFIDENCE;
  
  // 自动加载配置
  LoadConfig;
end;

class destructor TEncodingDetectionConfig.Destroy;
begin
  if Assigned(FIniFile) then
    FreeAndNil(FIniFile);
end;

class function TEncodingDetectionConfig.GetConfigFilePath: string;
var
  ExePath: string;
  IniPath: string;
begin
  // 获取程序所在目录
  ExePath := ExtractFilePath(ParamStr(0));
  
  // 尝试 ini/ui.ini
  IniPath := TPath.Combine(ExePath, 'ini');
  IniPath := TPath.Combine(IniPath, 'ui.ini');
  
  if FileExists(IniPath) then
  begin
    Result := IniPath;
    Exit;
  end;
  
  // 尝试 ui.ini
  IniPath := TPath.Combine(ExePath, 'ui.ini');
  if FileExists(IniPath) then
  begin
    Result := IniPath;
    Exit;
  end;
  
  // 如果都不存在，使用默认路径 ini/ui.ini
  Result := TPath.Combine(TPath.Combine(ExePath, 'ini'), 'ui.ini');
end;

class function TEncodingDetectionConfig.ValidateConfidence(const Value: Double): Double;
begin
  // 确保值在有效范围内
  if Value < MIN_CONFIDENCE_THRESHOLD then
    Result := MIN_CONFIDENCE_THRESHOLD
  else if Value > MAX_CONFIDENCE_THRESHOLD then
    Result := MAX_CONFIDENCE_THRESHOLD
  else
    Result := Value;
end;

class procedure TEncodingDetectionConfig.LoadConfig;
var
  ConfigPath: string;
  TempValue: Double;
begin
  if FConfigLoaded then
    Exit;
    
  try
    ConfigPath := GetConfigFilePath;
    
    // 如果配置文件不存在，使用默认值
    if not FileExists(ConfigPath) then
    begin
      FConfigLoaded := True;
      Exit;
    end;
    
    // 创建 INI 文件对象
    FIniFile := TIniFile.Create(ConfigPath);
    
    // 读取 UTF-8 检测阈值
    TempValue := FIniFile.ReadFloat('Detection', 'MinUTF8Confidence', DEFAULT_MIN_UTF8_CONFIDENCE);
    FMinUTF8Confidence := ValidateConfidence(TempValue);
    
    // 读取中文检测阈值
    TempValue := FIniFile.ReadFloat('Detection', 'MinChineseConfidence', DEFAULT_MIN_CHINESE_CONFIDENCE);
    FMinChineseConfidence := ValidateConfidence(TempValue);
    
    // 读取日文检测阈值
    TempValue := FIniFile.ReadFloat('Detection', 'MinJapaneseConfidence', DEFAULT_MIN_JAPANESE_CONFIDENCE);
    FMinJapaneseConfidence := ValidateConfidence(TempValue);
    
    // 读取韩文检测阈值
    TempValue := FIniFile.ReadFloat('Detection', 'MinKoreanConfidence', DEFAULT_MIN_KOREAN_CONFIDENCE);
    FMinKoreanConfidence := ValidateConfidence(TempValue);
    
    // 读取通用检测阈值
    TempValue := FIniFile.ReadFloat('Detection', 'MinGeneralConfidence', DEFAULT_MIN_GENERAL_CONFIDENCE);
    FMinGeneralConfidence := ValidateConfidence(TempValue);
    
    FConfigLoaded := True;
  except
    // 如果加载失败，使用默认值
    FMinUTF8Confidence := DEFAULT_MIN_UTF8_CONFIDENCE;
    FMinChineseConfidence := DEFAULT_MIN_CHINESE_CONFIDENCE;
    FMinJapaneseConfidence := DEFAULT_MIN_JAPANESE_CONFIDENCE;
    FMinKoreanConfidence := DEFAULT_MIN_KOREAN_CONFIDENCE;
    FMinGeneralConfidence := DEFAULT_MIN_GENERAL_CONFIDENCE;
    FConfigLoaded := True;
  end;
end;

class procedure TEncodingDetectionConfig.ReloadConfig;
begin
  FConfigLoaded := False;
  if Assigned(FIniFile) then
    FreeAndNil(FIniFile);
  LoadConfig;
end;

class procedure TEncodingDetectionConfig.SaveConfig;
var
  ConfigPath: string;
  ConfigDir: string;
begin
  try
    ConfigPath := GetConfigFilePath;
    ConfigDir := ExtractFilePath(ConfigPath);
    
    // 确保目录存在
    if not DirectoryExists(ConfigDir) then
      ForceDirectories(ConfigDir);
    
    // 如果 INI 文件对象不存在，创建它
    if not Assigned(FIniFile) then
      FIniFile := TIniFile.Create(ConfigPath);
    
    // 写入配置值
    FIniFile.WriteFloat('Detection', 'MinUTF8Confidence', FMinUTF8Confidence);
    FIniFile.WriteFloat('Detection', 'MinChineseConfidence', FMinChineseConfidence);
    FIniFile.WriteFloat('Detection', 'MinJapaneseConfidence', FMinJapaneseConfidence);
    FIniFile.WriteFloat('Detection', 'MinKoreanConfidence', FMinKoreanConfidence);
    FIniFile.WriteFloat('Detection', 'MinGeneralConfidence', FMinGeneralConfidence);
    
    // 更新文件
    FIniFile.UpdateFile;
  except
    // 静默失败
  end;
end;

end.
