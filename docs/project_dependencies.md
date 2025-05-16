# TransSuccess 项目文件依赖关系图

## 主程序文件
- `TransSuccess.dpr`: 主程序入口，引用所有需要的单元
  - 依赖: ViewMainCode.pas, ModelEncoding.pas, UtilsTypes.pas, ControllerEncoding.pas, HelperFiles.pas, HelperUI.pas, ModelConfig.pas, HelperLanguage.pas, ViewSynEdit.pas, ControllerLanguage.pas, UtilsEncodingTypes.pas, UtilsEncodingLogger.pas, UtilsEncodingBOM_Simple.pas, UTF8BOMConverter.pas

## 视图层文件
- `ViewMainCode.pas/dfm`: 主窗体，包含用户界面
  - 依赖: ControllerEncoding.pas, HelperUI.pas, HelperFiles.pas, ModelEncoding.pas
- `ViewSynEdit.pas/dfm`: 文本编辑器窗体
  - 依赖: HelperUI.pas

## 控制器层文件
- `ControllerEncoding.pas`: 编码控制器，处理编码检测和转换
  - 依赖: UtilsEncodingBOM_Simple.pas, UTF8BOMConverter_Simple.pas, HelperFiles.pas
- `ControllerLanguage.pas`: 语言控制器，处理多语言支持
  - 依赖: ModelLanguage.pas, HelperLanguage.pas

## 模型层文件
- `ModelEncoding.pas`: 编码模型，定义编码相关的数据结构
  - 依赖: UtilsTypes.pas
- `ModelConfig.pas`: 配置模型，处理应用程序配置
  - 依赖: UtilsTypes.pas
- `ModelLanguage.pas`: 语言模型，处理多语言支持
  - 依赖: UtilsTypes.pas

## 辅助类文件
- `HelperFiles.pas`: 文件操作辅助类
  - 依赖: UtilsTypes.pas
- `HelperUI.pas`: UI操作辅助类
  - 依赖: UtilsTypes.pas
- `HelperLanguage.pas`: 语言操作辅助类
  - 依赖: UtilsTypes.pas, ModelLanguage.pas

## 工具类文件
- `UtilsTypes.pas`: 基本类型定义
  - 依赖: UtilsEncodingConstants.pas
- `UtilsEncodingTypes.pas`: 编码类型定义
  - 依赖: UtilsEncodingConstants.pas
- `UtilsEncodingLogger.pas`: 编码日志记录器
  - 依赖: UtilsEncodingTypes.pas
- `UtilsEncodingConstants.pas`: 编码常量定义
  - 依赖: 无

## 编码检测相关文件
- `UtilsEncodingBOM_Simple.pas`: 简化版BOM检测器
  - 依赖: UtilsEncodingTypes.pas, UtilsEncodingLogger.pas
- `UtilsEncodingBOM_Improved.pas`: 改进版BOM检测器
  - 依赖: UtilsEncodingTypes.pas
- `UtilsEncodingUTF8Detector_Improved.pas`: 改进版UTF-8检测器
  - 依赖: UtilsEncodingTypes.pas
- `ChineseEncodingDetector_Improved.pas`: 改进版中文编码检测器
  - 依赖: UtilsEncodingTypes.pas, UtilsEncodingBOM_Improved.pas, UtilsEncodingUTF8Detector_Improved.pas

## 编码转换相关文件
- `UTF8BOMConverter.pas`: UTF-8 BOM转换器
  - 依赖: UtilsEncodingBOM_Simple.pas, UtilsEncodingTypes.pas, UtilsEncodingLogger.pas
- `UTF8BOMConverter_Simple.pas`: 简化版UTF-8 BOM转换器
  - 依赖: 无
- `UTF8BOMConverter_Improved.pas`: 改进版UTF-8 BOM转换器
  - 依赖: UtilsEncodingTypes.pas, UtilsEncodingBOM_Improved.pas, UtilsEncodingUTF8Detector_Improved.pas
- `EncodingConverter_Improved.pas`: 改进版编码转换器
  - 依赖: UtilsEncodingTypes.pas, UtilsEncodingBOM_Improved.pas, UtilsEncodingUTF8Detector_Improved.pas, ChineseEncodingDetector_Improved.pas, UTF8BOMConverter_Improved.pas

## 测试相关文件
- `TestEncodingMain.dpr`: 编码测试主程序
  - 依赖: UtilsEncodingTypes.pas, UtilsEncodingBOM_Improved.pas, UtilsEncodingUTF8Detector_Improved.pas, ChineseEncodingDetector_Improved.pas, UTF8BOMConverter_Improved.pas, EncodingConverter_Improved.pas, TestEncodingDetection.pas
- `TestEncodingDetection.pas`: 编码检测测试
  - 依赖: UtilsEncodingTypes.pas, UtilsEncodingBOM_Improved.pas, UtilsEncodingUTF8Detector_Improved.pas, ChineseEncodingDetector_Improved.pas, UTF8BOMConverter_Improved.pas, EncodingConverter_Improved.pas
