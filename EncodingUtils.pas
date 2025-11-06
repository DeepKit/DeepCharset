unit EncodingUtils;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  UtilsTypes, UtilsEncodingBOM_Improved,
  UtilsEncodingDetector_Improved, UtilsEncodingConverter_Improved,
  UtilsEncodingManager;

type
  /// <summary>
  /// 编码检测结果记录
  /// </summary>
  TEncodingDetectionResult = UtilsEncodingDetector_Improved.TEncodingDetectionResult;

  /// <summary>
  /// 编码转换结果记录
  /// </summary>
  TEncodingConversionResult = UtilsEncodingConverter_Improved.TEncodingConversionResult;

  /// <summary>
  /// BOM类型枚举
  /// </summary>
  TBOMType = UtilsEncodingBOM_Improved.TBOMType;

  /// <summary>
  /// BOM检测结果记录
  /// </summary>
  TBOMDetectionResult = UtilsEncodingBOM_Improved.TBOMDetectionResult;

  /// <summary>
  /// 编码工具类 - 提供编码检测和转换功能
  /// </summary>
  TEncodingUtils = class
  private
    class var FLogCallback: TProc<string>;

  public
    /// <summary>
    /// 设置日志回调函数
    /// </summary>
    class procedure SetLogCallback(const Callback: TProc<string>);

    /// <summary>
    /// 获取最后一次错误信息
    /// </summary>
    class function GetLastError: string;

    /// <summary>
    /// 检测文件编码
    /// </summary>
    class function DetectFileEncoding(const FileName: string): TEncodingDetectionResult;

    /// <summary>
    /// 转换文件编码
    /// </summary>
    class function ConvertFileEncoding(const SourceFileName, TargetFileName: string;
      const SourceEncoding, TargetEncoding: string; AddBOM: Boolean = False): Boolean;

    /// <summary>
    /// 批量转换文件编码
    /// </summary>
    class function BatchConvertFileEncoding(const FileNames: TArray<string>;
      const SourceDir, TargetDir: string; const SourceEncoding, TargetEncoding: string;
      AddBOM: Boolean = False): Integer;

    /// <summary>
    /// 添加BOM到文件
    /// </summary>
    class function AddBOMToFile(const FileName: string; const EncodingName: string): Boolean;

    /// <summary>
    /// 移除文件的BOM
    /// </summary>
    class function RemoveBOMFromFile(const FileName: string): Boolean;

    /// <summary>
    /// 获取支持的编码列表
    /// </summary>
    class function GetSupportedEncodings: TArray<string>;

    /// <summary>
    /// 检查编码名称是否有效
    /// </summary>
    class function IsValidEncodingName(const EncodingName: string): Boolean;

    /// <summary>
    /// 获取编码的描述信息
    /// </summary>
    class function GetEncodingDescription(const EncodingName: string): string;
  end;

// 编码常量（统一引用 UtilsTypes）
const
  ENCODING_UNKNOWN = UtilsTypes.ENCODING_UNKNOWN;
  ENCODING_ANSI = UtilsTypes.ENCODING_ANSI;
  ENCODING_ASCII = UtilsTypes.ENCODING_ASCII;
  ENCODING_UTF8 = UtilsTypes.ENCODING_UTF8;
  ENCODING_UTF8_BOM = UtilsTypes.ENCODING_UTF8_BOM;
  ENCODING_UTF16_LE = UtilsTypes.ENCODING_UTF16_LE;
  ENCODING_UTF16_BE = UtilsTypes.ENCODING_UTF16_BE;
  ENCODING_UTF32_LE = UtilsTypes.ENCODING_UTF32_LE;
  ENCODING_UTF32_BE = UtilsTypes.ENCODING_UTF32_BE;
  ENCODING_GBK = UtilsTypes.ENCODING_GBK;
  ENCODING_GB2312 = UtilsTypes.ENCODING_GB2312;
  ENCODING_GB18030 = UtilsTypes.ENCODING_GB18030;
  ENCODING_BIG5 = UtilsTypes.ENCODING_BIG5;
  ENCODING_SHIFT_JIS = UtilsTypes.ENCODING_SHIFT_JIS;
  ENCODING_EUC_JP = UtilsTypes.ENCODING_EUC_JP;
  ENCODING_ISO_2022_JP = UtilsTypes.ENCODING_ISO2022_JP;
  ENCODING_EUC_KR = UtilsTypes.ENCODING_EUC_KR;
  ENCODING_ISO_2022_KR = UtilsTypes.ENCODING_ISO_2022_KR;
  ENCODING_BINARY = UtilsTypes.ENCODING_BINARY;

implementation

{ TEncodingUtils }

class function TEncodingUtils.AddBOMToFile(const FileName, EncodingName: string): Boolean;
begin
  Result := TEncodingManager.AddBOMToFile(FileName, EncodingName);
end;

class function TEncodingUtils.BatchConvertFileEncoding(const FileNames: TArray<string>;
  const SourceDir, TargetDir, SourceEncoding, TargetEncoding: string;
  AddBOM: Boolean): Integer;
begin
  Result := TEncodingManager.BatchConvertFileEncoding(FileNames, SourceDir, TargetDir,
    SourceEncoding, TargetEncoding, AddBOM);
end;

class function TEncodingUtils.ConvertFileEncoding(const SourceFileName, TargetFileName: string;
  const SourceEncoding, TargetEncoding: string; AddBOM: Boolean): Boolean;
begin
  Result := TEncodingManager.ConvertFileEncoding(SourceFileName, TargetFileName,
    SourceEncoding, TargetEncoding, AddBOM);
end;

class function TEncodingUtils.DetectFileEncoding(const FileName: string): TEncodingDetectionResult;
begin
  Result := TEncodingManager.DetectFileEncoding(FileName);
end;

class function TEncodingUtils.GetEncodingDescription(const EncodingName: string): string;
begin
  Result := TEncodingManager.GetEncodingDescription(EncodingName);
end;

class function TEncodingUtils.GetLastError: string;
begin
  Result := TEncodingManager.GetLastError;
end;

class function TEncodingUtils.GetSupportedEncodings: TArray<string>;
begin
  Result := TEncodingManager.GetSupportedEncodings;
end;

class function TEncodingUtils.IsValidEncodingName(const EncodingName: string): Boolean;
begin
  Result := TEncodingManager.IsValidEncodingName(EncodingName);
end;

class function TEncodingUtils.RemoveBOMFromFile(const FileName: string): Boolean;
begin
  Result := TEncodingManager.RemoveBOMFromFile(FileName);
end;

class procedure TEncodingUtils.SetLogCallback(const Callback: TProc<string>);
begin
  FLogCallback := Callback;
  TEncodingManager.SetLogCallback(Callback);
end;
