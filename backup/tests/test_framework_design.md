# 编码测试框架设计

## 1. 总体架构

测试框架将采用模块化设计，包含以下主要组件：

1. **主程序（EncodingTestRunner.dpr）**：
   - 命令行参数处理
   - 测试模式选择
   - 测试执行控制
   - 结果输出格式化

2. **测试模块**：
   - 编码检测测试模块
   - 编码转换测试模块
   - 批量测试模块
   - 性能测试模块

3. **工具类**：
   - 测试文件管理
   - 结果比较工具
   - 报告生成器
   - 日志记录器

4. **配置系统**：
   - 测试配置加载
   - 参数验证
   - 默认值管理

## 2. 命令行接口设计

```
EncodingTestRunner <命令> [选项]

命令:
  detect <文件路径>                    - 检测单个文件的编码
  convert <源文件> <目标文件> <目标编码> [添加BOM] - 转换单个文件的编码
  batch <目录路径> <目标编码> [添加BOM]  - 批量检测和转换目录中的文件
  performance                         - 运行性能测试
  compare <文件路径> <编码1> <编码2>    - 比较两种编码检测算法

选项:
  --verbose                           - 显示详细日志
  --output=<文件路径>                  - 将结果输出到文件
  --format=<csv|json|text>            - 结果输出格式
  --timeout=<秒数>                     - 设置操作超时时间
  --buffer-size=<字节数>               - 设置缓冲区大小
```

## 3. 测试模块设计

### 3.1 编码检测测试模块

```pascal
unit TestEncodingDetection;

interface

uses
  System.SysUtils, System.Classes,
  UtilsEncodingBOM, UtilsEncodingUTF8Detector, UtilsEncodingDetect,
  UtilsEncodingTypes, UtilsEncodingConstants, UtilsEncodingLogger;

type
  TDetectionTestResult = record
    FileName: string;
    DetectedEncoding: string;
    Confidence: Double;
    HasBOM: Boolean;
    ProcessingTimeMs: Int64;
    // 其他相关信息
  end;

  TEncodingDetectionTester = class
  private
    FLogger: TEncodingLogger;
    // 其他私有字段和方法
  public
    constructor Create(Logger: TEncodingLogger = nil);
    destructor Destroy; override;
    
    // 使用不同的检测器测试文件编码
    function TestWithBOMDetector(const FileName: string): TDetectionTestResult;
    function TestWithUTF8Detector(const FileName: string): TDetectionTestResult;
    function TestWithEncodingDetector(const FileName: string): TDetectionTestResult;
    
    // 比较不同检测器的结果
    function CompareDetectors(const FileName: string): TArray<TDetectionTestResult>;
    
    // 验证检测结果
    function ValidateDetection(const FileName: string; ExpectedEncoding: string): Boolean;
  end;
```

### 3.2 编码转换测试模块

```pascal
unit TestEncodingConversion;

interface

uses
  System.SysUtils, System.Classes,
  UtilsEncodingConverter, UtilsEncodingBOM, UtilsEncodingTypes, UtilsEncodingLogger;

type
  TConversionTestResult = record
    SourceFile: string;
    TargetFile: string;
    SourceEncoding: string;
    TargetEncoding: string;
    Success: Boolean;
    ProcessingTimeMs: Int64;
    BytesProcessed: Int64;
    // 其他相关信息
  end;

  TEncodingConversionTester = class
  private
    FLogger: TEncodingLogger;
    // 其他私有字段和方法
  public
    constructor Create(Logger: TEncodingLogger = nil);
    destructor Destroy; override;
    
    // 测试文件编码转换
    function TestConversion(const SourceFile, TargetFile: string; 
                           TargetEncoding: string; WithBOM: Boolean = False): TConversionTestResult;
    
    // 验证转换结果
    function ValidateConversion(const SourceFile, TargetFile: string; 
                               SourceEncoding, TargetEncoding: string): Boolean;
    
    // 测试特定的转换场景
    function TestUTF8ToBOM(const SourceFile, TargetFile: string): TConversionTestResult;
    function TestGBKToUTF8(const SourceFile, TargetFile: string): TConversionTestResult;
    function TestUTF8ToGBK(const SourceFile, TargetFile: string): TConversionTestResult;
  end;
```

### 3.3 批量测试模块

```pascal
unit TestBatchProcessing;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  TestEncodingDetection, TestEncodingConversion,
  UtilsEncodingLogger;

type
  TBatchTestResult = record
    DirectoryPath: string;
    FilesProcessed: Integer;
    SuccessCount: Integer;
    FailureCount: Integer;
    TotalTimeMs: Int64;
    // 其他相关信息
  end;

  TBatchTester = class
  private
    FLogger: TEncodingLogger;
    FDetectionTester: TEncodingDetectionTester;
    FConversionTester: TEncodingConversionTester;
    // 其他私有字段和方法
  public
    constructor Create(Logger: TEncodingLogger = nil);
    destructor Destroy; override;
    
    // 批量检测目录中的文件编码
    function BatchDetect(const DirectoryPath: string): TBatchTestResult;
    
    // 批量转换目录中的文件编码
    function BatchConvert(const DirectoryPath: string; TargetEncoding: string; 
                         WithBOM: Boolean = False): TBatchTestResult;
    
    // 生成批量测试报告
    procedure GenerateReport(const ReportFile: string; const Result: TBatchTestResult);
  end;
```

### 3.4 性能测试模块

```pascal
unit TestPerformance;

interface

uses
  System.SysUtils, System.Classes, System.Diagnostics,
  TestEncodingDetection, TestEncodingConversion,
  UtilsEncodingLogger;

type
  TPerformanceTestResult = record
    TestName: string;
    IterationCount: Integer;
    TotalTimeMs: Int64;
    AverageTimeMs: Double;
    MinTimeMs: Int64;
    MaxTimeMs: Int64;
    // 其他相关信息
  end;

  TPerformanceTester = class
  private
    FLogger: TEncodingLogger;
    // 其他私有字段和方法
  public
    constructor Create(Logger: TEncodingLogger = nil);
    destructor Destroy; override;
    
    // 测试编码检测性能
    function TestDetectionPerformance(const FileName: string; 
                                    IterationCount: Integer = 100): TPerformanceTestResult;
    
    // 测试编码转换性能
    function TestConversionPerformance(const SourceFile, TargetFile: string;
                                     TargetEncoding: string; WithBOM: Boolean;
                                     IterationCount: Integer = 100): TPerformanceTestResult;
    
    // 生成性能测试报告
    procedure GenerateReport(const ReportFile: string; 
                           const Results: TArray<TPerformanceTestResult>);
  end;
```

## 4. 工具类设计

### 4.1 测试文件管理

```pascal
unit TestFileManager;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils;

type
  TTestFileManager = class
  private
    FTestFilesDir: string;
    // 其他私有字段和方法
  public
    constructor Create(const TestFilesDir: string = 'TestFiles');
    destructor Destroy; override;
    
    // 创建测试文件
    function CreateUTF8File(const FileName: string; const Content: string): string;
    function CreateUTF8BOMFile(const FileName: string; const Content: string): string;
    function CreateGBKFile(const FileName: string; const Content: string): string;
    function CreateBig5File(const FileName: string; const Content: string): string;
    function CreateASCIIFile(const FileName: string; const Content: string): string;
    function CreateUTF16File(const FileName: string; const Content: string; BigEndian: Boolean = False): string;
    
    // 获取测试文件
    function GetTestFilePath(const FileName: string): string;
    function GetAllTestFiles: TArray<string>;
    function GetTestFilesByEncoding(const Encoding: string): TArray<string>;
    
    // 清理测试文件
    procedure CleanupTestFiles;
  end;
```

### 4.2 结果比较工具

```pascal
unit TestComparer;

interface

uses
  System.SysUtils, System.Classes,
  TestEncodingDetection, TestEncodingConversion;

type
  TComparisonResult = record
    FileName: string;
    Method1Name: string;
    Method1Result: string;
    Method2Name: string;
    Method2Result: string;
    AreEqual: Boolean;
    Differences: string;
    // 其他相关信息
  end;

  TTestComparer = class
  private
    // 私有字段和方法
  public
    // 比较两种检测方法的结果
    function CompareDetectionMethods(const FileName: string; 
                                   Method1, Method2: string): TComparisonResult;
    
    // 比较两种转换方法的结果
    function CompareConversionMethods(const SourceFile: string;
                                    TargetEncoding: string;
                                    Method1, Method2: string): TComparisonResult;
    
    // 比较文件内容
    function CompareFileContents(const File1, File2: string): TComparisonResult;
  end;
```

### 4.3 报告生成器

```pascal
unit TestReportGenerator;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  TestEncodingDetection, TestEncodingConversion,
  TestBatchProcessing, TestPerformance, TestComparer;

type
  TReportFormat = (rfText, rfCSV, rfJSON, rfHTML);

  TReportGenerator = class
  private
    FFormat: TReportFormat;
    // 其他私有字段和方法
  public
    constructor Create(Format: TReportFormat = rfText);
    destructor Destroy; override;
    
    // 生成检测测试报告
    procedure GenerateDetectionReport(const ReportFile: string; 
                                    const Results: TArray<TDetectionTestResult>);
    
    // 生成转换测试报告
    procedure GenerateConversionReport(const ReportFile: string;
                                     const Results: TArray<TConversionTestResult>);
    
    // 生成批量测试报告
    procedure GenerateBatchReport(const ReportFile: string;
                                const Result: TBatchTestResult);
    
    // 生成性能测试报告
    procedure GeneratePerformanceReport(const ReportFile: string;
                                      const Results: TArray<TPerformanceTestResult>);
    
    // 生成比较测试报告
    procedure GenerateComparisonReport(const ReportFile: string;
                                     const Results: TArray<TComparisonResult>);
  end;
```

## 5. 配置系统设计

```pascal
unit TestConfig;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles, System.JSON;

type
  TTestConfig = class
  private
    FConfigFile: string;
    FValues: TDictionary<string, Variant>;
    // 其他私有字段和方法
  public
    constructor Create(const ConfigFile: string = 'test_config.ini');
    destructor Destroy; override;
    
    // 加载配置
    procedure LoadFromFile;
    procedure LoadFromJSON(const JSONFile: string);
    
    // 获取配置值
    function GetValue(const Key: string; DefaultValue: Variant): Variant;
    function GetString(const Key: string; DefaultValue: string = ''): string;
    function GetInteger(const Key: string; DefaultValue: Integer = 0): Integer;
    function GetBoolean(const Key: string; DefaultValue: Boolean = False): Boolean;
    
    // 设置配置值
    procedure SetValue(const Key: string; Value: Variant);
    
    // 保存配置
    procedure SaveToFile;
    procedure SaveToJSON(const JSONFile: string);
  end;
```

## 6. 主程序设计

```pascal
program EncodingTestRunner;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  TestConfig in 'TestConfig.pas',
  TestEncodingDetection in 'TestEncodingDetection.pas',
  TestEncodingConversion in 'TestEncodingConversion.pas',
  TestBatchProcessing in 'TestBatchProcessing.pas',
  TestPerformance in 'TestPerformance.pas',
  TestFileManager in 'TestFileManager.pas',
  TestComparer in 'TestComparer.pas',
  TestReportGenerator in 'TestReportGenerator.pas',
  UtilsEncodingLogger in 'UtilsEncodingLogger.pas';

var
  Config: TTestConfig;
  Logger: TEncodingLogger;
  FileManager: TTestFileManager;
  ReportGenerator: TReportGenerator;

// 命令行参数处理函数
procedure ProcessCommandLine;
begin
  // 实现命令行参数处理逻辑
end;

// 检测命令处理函数
procedure HandleDetectCommand(const FileName: string);
var
  DetectionTester: TEncodingDetectionTester;
  Result: TDetectionTestResult;
begin
  DetectionTester := TEncodingDetectionTester.Create(Logger);
  try
    Result := DetectionTester.TestWithEncodingDetector(FileName);
    // 输出结果
    Writeln(Format('文件: %s', [FileName]));
    Writeln(Format('检测到的编码: %s', [Result.DetectedEncoding]));
    Writeln(Format('置信度: %.2f', [Result.Confidence]));
    Writeln(Format('BOM: %s', [BoolToStr(Result.HasBOM, True)]));
    Writeln(Format('处理时间: %d 毫秒', [Result.ProcessingTimeMs]));
  finally
    DetectionTester.Free;
  end;
end;

// 转换命令处理函数
procedure HandleConvertCommand(const SourceFile, TargetFile, TargetEncoding: string; WithBOM: Boolean);
var
  ConversionTester: TEncodingConversionTester;
  Result: TConversionTestResult;
begin
  ConversionTester := TEncodingConversionTester.Create(Logger);
  try
    Result := ConversionTester.TestConversion(SourceFile, TargetFile, TargetEncoding, WithBOM);
    // 输出结果
    Writeln(Format('源文件: %s', [SourceFile]));
    Writeln(Format('目标文件: %s', [TargetFile]));
    Writeln(Format('目标编码: %s', [TargetEncoding]));
    Writeln(Format('添加BOM: %s', [BoolToStr(WithBOM, True)]));
    Writeln(Format('转换结果: %s', [BoolToStr(Result.Success, True)]));
    Writeln(Format('处理时间: %d 毫秒', [Result.ProcessingTimeMs]));
  finally
    ConversionTester.Free;
  end;
end;

// 批量命令处理函数
procedure HandleBatchCommand(const DirectoryPath, TargetEncoding: string; WithBOM: Boolean);
var
  BatchTester: TBatchTester;
  Result: TBatchTestResult;
begin
  BatchTester := TBatchTester.Create(Logger);
  try
    Result := BatchTester.BatchConvert(DirectoryPath, TargetEncoding, WithBOM);
    // 输出结果
    Writeln(Format('目录: %s', [DirectoryPath]));
    Writeln(Format('处理文件数: %d', [Result.FilesProcessed]));
    Writeln(Format('成功数: %d', [Result.SuccessCount]));
    Writeln(Format('失败数: %d', [Result.FailureCount]));
    Writeln(Format('总处理时间: %d 毫秒', [Result.TotalTimeMs]));
    
    // 生成报告
    BatchTester.GenerateReport('batch_test_report.txt', Result);
  finally
    BatchTester.Free;
  end;
end;

// 性能测试命令处理函数
procedure HandlePerformanceCommand;
var
  PerformanceTester: TPerformanceTester;
  Results: TArray<TPerformanceTestResult>;
begin
  PerformanceTester := TPerformanceTester.Create(Logger);
  try
    SetLength(Results, 2);
    
    // 测试检测性能
    Results[0] := PerformanceTester.TestDetectionPerformance(
      FileManager.GetTestFilePath('test_utf8.txt'), 100);
    
    // 测试转换性能
    Results[1] := PerformanceTester.TestConversionPerformance(
      FileManager.GetTestFilePath('test_utf8.txt'),
      FileManager.GetTestFilePath('test_utf8_bom.txt'),
      'utf-8', True, 100);
    
    // 生成报告
    ReportGenerator.GeneratePerformanceReport('performance_test_report.txt', Results);
    
    // 输出结果摘要
    Writeln('性能测试完成，结果已保存到 performance_test_report.txt');
  finally
    PerformanceTester.Free;
  end;
end;

// 比较命令处理函数
procedure HandleCompareCommand(const FileName, Method1, Method2: string);
var
  Comparer: TTestComparer;
  Result: TComparisonResult;
begin
  Comparer := TTestComparer.Create;
  try
    Result := Comparer.CompareDetectionMethods(FileName, Method1, Method2);
    // 输出结果
    Writeln(Format('文件: %s', [FileName]));
    Writeln(Format('方法1 (%s): %s', [Result.Method1Name, Result.Method1Result]));
    Writeln(Format('方法2 (%s): %s', [Result.Method2Name, Result.Method2Result]));
    Writeln(Format('结果相同: %s', [BoolToStr(Result.AreEqual, True)]));
    if not Result.AreEqual then
      Writeln(Format('差异: %s', [Result.Differences]));
  finally
    Comparer.Free;
  end;
end;

begin
  try
    // 初始化
    Config := TTestConfig.Create;
    Logger := TEncodingLogger.Create;
    FileManager := TTestFileManager.Create;
    ReportGenerator := TReportGenerator.Create;
    
    try
      // 处理命令行参数
      ProcessCommandLine;
    finally
      // 清理
      ReportGenerator.Free;
      FileManager.Free;
      Logger.Free;
      Config.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
```

## 7. 测试数据设计

### 7.1 测试文件类型

1. **UTF-8编码文件**：
   - 纯ASCII内容
   - 混合ASCII和中文内容
   - 特殊字符内容
   - 边界情况（非常短的文件、非常长的文件）

2. **UTF-8+BOM编码文件**：
   - 与UTF-8文件相同的内容变体，但添加BOM

3. **GBK/GB18030编码文件**：
   - 纯中文内容
   - 混合中英文内容
   - 特殊字符内容

4. **Big5编码文件**：
   - 纯繁体中文内容
   - 混合繁体中文和英文内容

5. **ASCII编码文件**：
   - 纯ASCII内容
   - 控制字符内容

6. **UTF-16LE/BE编码文件**：
   - 带BOM和不带BOM的变体
   - 混合内容

7. **混合编码文件**：
   - 用于测试边界情况和错误处理

### 7.2 测试场景

1. **编码检测场景**：
   - 检测各种编码的文件
   - 检测边界情况（空文件、超大文件、混合编码）
   - 比较不同检测算法的结果

2. **编码转换场景**：
   - UTF-8到UTF-8+BOM的转换
   - GBK/GB18030到UTF-8的转换
   - UTF-8到GBK/GB18030的转换
   - Big5到UTF-8的转换
   - UTF-8到Big5的转换
   - 处理不可转换字符的情况

3. **批量处理场景**：
   - 批量检测目录中的文件
   - 批量转换目录中的文件
   - 处理大量文件的性能测试

4. **性能测试场景**：
   - 检测性能测试（不同大小的文件）
   - 转换性能测试（不同编码对）
   - 批量处理性能测试

## 8. 测试报告设计

### 8.1 检测测试报告

```
编码检测测试报告
=================
测试时间: 2023-05-20 15:30:45
测试文件数: 10

文件详情:
---------
1. test_utf8.txt
   - 检测编码: UTF-8
   - 置信度: 0.95
   - BOM: False
   - 处理时间: 5 ms

2. test_utf8_bom.txt
   - 检测编码: UTF-8 with BOM
   - 置信度: 1.00
   - BOM: True
   - 处理时间: 3 ms

...

统计信息:
---------
- 平均处理时间: 4.2 ms
- 最长处理时间: 8 ms (test_large.txt)
- 最短处理时间: 2 ms (test_empty.txt)
- 置信度 >= 0.9 的文件数: 8
- 置信度 < 0.9 的文件数: 2
```

### 8.2 转换测试报告

```
编码转换测试报告
=================
测试时间: 2023-05-20 15:45:30
测试转换对数: 5

转换详情:
---------
1. UTF-8 -> UTF-8+BOM
   - 源文件: test_utf8.txt
   - 目标文件: test_utf8_bom.txt
   - 成功: True
   - 处理时间: 10 ms
   - 处理字节数: 1024

2. GBK -> UTF-8
   - 源文件: test_gbk.txt
   - 目标文件: test_gbk_utf8.txt
   - 成功: True
   - 处理时间: 15 ms
   - 处理字节数: 2048

...

统计信息:
---------
- 平均处理时间: 12.6 ms
- 最长处理时间: 20 ms (test_large_gbk.txt -> test_large_utf8.txt)
- 最短处理时间: 8 ms (test_small.txt -> test_small_utf8.txt)
- 成功转换数: 5
- 失败转换数: 0
```

### 8.3 性能测试报告

```
编码性能测试报告
=================
测试时间: 2023-05-20 16:00:15
测试迭代次数: 100

测试详情:
---------
1. UTF-8检测性能
   - 测试文件: test_utf8.txt (10 KB)
   - 总时间: 500 ms
   - 平均时间: 5 ms
   - 最短时间: 4 ms
   - 最长时间: 8 ms
   - 标准差: 0.8 ms

2. UTF-8到UTF-8+BOM转换性能
   - 测试文件: test_utf8.txt (10 KB)
   - 总时间: 1200 ms
   - 平均时间: 12 ms
   - 最短时间: 10 ms
   - 最长时间: 18 ms
   - 标准差: 1.5 ms

...

性能比较:
---------
- 检测性能排名: UTF-8+BOM > ASCII > UTF-8 > GBK > Big5
- 转换性能排名: ASCII->UTF-8 > UTF-8->UTF-8+BOM > GBK->UTF-8 > UTF-8->GBK
```

## 9. 实现计划

1. **第一阶段**：基础框架实现
   - 创建主程序框架
   - 实现命令行参数处理
   - 实现基本的测试文件管理

2. **第二阶段**：编码检测测试实现
   - 实现编码检测测试模块
   - 整合UtilsEncodingBOM.pas
   - 整合UtilsEncodingUTF8Detector.pas
   - 整合UtilsEncodingDetect.pas

3. **第三阶段**：编码转换测试实现
   - 实现编码转换测试模块
   - 整合UtilsEncodingConverter.pas
   - 实现UTF-8到UTF-8+BOM的转换测试
   - 实现其他编码对的转换测试

4. **第四阶段**：批量测试和性能测试实现
   - 实现批量测试模块
   - 实现性能测试模块
   - 实现测试报告生成

5. **第五阶段**：测试和优化
   - 创建完整的测试数据集
   - 运行全面测试
   - 优化性能和内存使用
   - 完善错误处理和日志记录
