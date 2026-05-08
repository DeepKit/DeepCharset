unit InterfacesEncoding;

interface

uses
  System.SysUtils, System.Classes, UtilsTypes;

type
  /// <summary>
  /// 编码检测结果接口
  /// 提供统一的检测结果访问方式
  /// </summary>
  IEncodingDetectionResult = interface
    ['{8F6D4B2A-1E3C-4D5B-9A7F-2C8E9D4F1B6A}']
    function GetEncoding: string;
    function GetConfidence: Double;
    function GetHasBOM: Boolean;
    function GetDetails: string;
    
    property Encoding: string read GetEncoding;
    property Confidence: Double read GetConfidence;
    property HasBOM: Boolean read GetHasBOM;
    property Details: string read GetDetails;
  end;

  /// <summary>
  /// 编码检测器接口
  /// 定义编码检测的标准方法
  /// </summary>
  IEncodingDetector = interface
    ['{A3F7B9C1-2D4E-4A6C-8B9D-5E1F3C7A2D8B}']
    /// <summary>
    /// 检测字节数组的编码
    /// </summary>
    function DetectBuffer(const Buffer: TBytes): IEncodingDetectionResult;
    
    /// <summary>
    /// 检测文件的编码
    /// </summary>
    function DetectFile(const FileName: string): IEncodingDetectionResult;
    
    /// <summary>
    /// 检测流的编码
    /// </summary>
    function DetectStream(const Stream: TStream): IEncodingDetectionResult;
    
    /// <summary>
    /// 获取检测器名称（如 "Chinese", "Japanese", "Korean", "UTF8"）
    /// </summary>
    function GetName: string;
    
    /// <summary>
    /// 获取最小置信度阈值
    /// </summary>
    function GetMinConfidence: Double;
    
    /// <summary>
    /// 设置最小置信度阈值
    /// </summary>
    procedure SetMinConfidence(const Value: Double);
    
    property Name: string read GetName;
    property MinConfidence: Double read GetMinConfidence write SetMinConfidence;
  end;

  /// <summary>
  /// 编码转换结果接口
  /// 提供统一的转换结果访问方式
  /// </summary>
  IEncodingConversionResult = interface
    ['{2B8E4D7F-3A5C-4E9B-8D6F-1C4A9E2B7D5C}']
    function GetSuccess: Boolean;
    function GetSourceEncoding: string;
    function GetTargetEncoding: string;
    function GetBytesProcessed: Int64;
    function GetErrorCount: Integer;
    function GetOutputData: TBytes;
    function GetErrorMessage: string;
    
    property Success: Boolean read GetSuccess;
    property SourceEncoding: string read GetSourceEncoding;
    property TargetEncoding: string read GetTargetEncoding;
    property BytesProcessed: Int64 read GetBytesProcessed;
    property ErrorCount: Integer read GetErrorCount;
    property OutputData: TBytes read GetOutputData;
    property ErrorMessage: string read GetErrorMessage;
  end;

  /// <summary>
  /// 编码转换选项接口
  /// 允许配置转换行为
  /// </summary>
  IEncodingConversionOptions = interface
    ['{7C3F9A2E-5D1B-4C8F-9E6D-4A2C8F1E7B3D}']
    function GetAddBOM: Boolean;
    procedure SetAddBOM(const Value: Boolean);
    function GetDetectSourceEncoding: Boolean;
    procedure SetDetectSourceEncoding(const Value: Boolean);
    function GetMaxErrorCount: Integer;
    procedure SetMaxErrorCount(const Value: Integer);
    
    property AddBOM: Boolean read GetAddBOM write SetAddBOM;
    property DetectSourceEncoding: Boolean read GetDetectSourceEncoding write SetDetectSourceEncoding;
    property MaxErrorCount: Integer read GetMaxErrorCount write SetMaxErrorCount;
  end;

  /// <summary>
  /// 编码转换器接口
  /// 定义编码转换的标准方法
  /// </summary>
  IEncodingConverter = interface
    ['{4D9C2E7A-6F3B-4A8D-9C5E-7B1F4D8A3C2E}']
    /// <summary>
    /// 转换字节数组
    /// </summary>
    function ConvertBuffer(const Buffer: TBytes; 
                          const SourceEncoding, TargetEncoding: string;
                          const Options: IEncodingConversionOptions): IEncodingConversionResult;
    
    /// <summary>
    /// 转换文件
    /// </summary>
    function ConvertFile(const SourceFileName, TargetFileName: string;
                        const SourceEncoding, TargetEncoding: string;
                        const Options: IEncodingConversionOptions): IEncodingConversionResult;
    
    /// <summary>
    /// 转换流
    /// </summary>
    function ConvertStream(const SourceStream, TargetStream: TStream;
                          const SourceEncoding, TargetEncoding: string;
                          const Options: IEncodingConversionOptions): IEncodingConversionResult;
    
    /// <summary>
    /// 批量转换文件
    /// </summary>
    function BatchConvertFiles(const FileNames: TArray<string>;
                              const TargetDir: string;
                              const TargetEncoding: string;
                              const Options: IEncodingConversionOptions): TArray<IEncodingConversionResult>;
    
    /// <summary>
    /// 获取转换器名称
    /// </summary>
    function GetName: string;
    
    property Name: string read GetName;
  end;

  /// <summary>
  /// 编码检测器工厂接口
  /// 用于创建和管理检测器实例
  /// </summary>
  IEncodingDetectorFactory = interface
    ['{6E2A9F4C-8D3B-4F7E-9A5C-3D1E7B4F8C2A}']
    /// <summary>
    /// 创建指定类型的检测器
    /// </summary>
    function CreateDetector(const DetectorType: string): IEncodingDetector;
    
    /// <summary>
    /// 注册检测器类型
    /// </summary>
    procedure RegisterDetector(const DetectorType: string; const Creator: TFunc<IEncodingDetector>);
    
    /// <summary>
    /// 获取所有已注册的检测器类型
    /// </summary>
    function GetRegisteredTypes: TArray<string>;
  end;

  /// <summary>
  /// 编码转换器工厂接口
  /// 用于创建和管理转换器实例
  /// </summary>
  IEncodingConverterFactory = interface
    ['{9F1C4D8A-7E2B-4C9D-8F3E-5A6D2B9C1F4E}']
    /// <summary>
    /// 创建默认转换器
    /// </summary>
    function CreateConverter: IEncodingConverter;
    
    /// <summary>
    /// 创建转换选项
    /// </summary>
    function CreateOptions: IEncodingConversionOptions;
  end;

implementation

end.
