# TransSuccess 开发文档

## 项目概述

TransSuccess 是一个专注于文本编码检测和转换的工具，支持多种编码格式的自动识别和转换。

## 技术架构

### 整体架构

TransSuccess 采用 MVC（Model-View-Controller）架构设计：

1. **Model**：数据模型层，包括编码信息、文件信息等
2. **View**：用户界面层，包括主窗体、对话框等
3. **Controller**：控制器层，处理用户输入并更新模型和视图

### 目录结构

```
TransSuccess/
├── bin/                  # 编译输出目录
├── ini/                  # 语言文件目录
├── lib/                  # 第三方库
├── backup/               # 备份文件
├── tests/                # 测试代码和文件
├── icons/                # 图标资源
└── docs/                 # 文档
```

### 核心组件

1. **ModelEncoding**：编码模型，定义编码相关的数据结构
2. **ControllerEncoding**：编码控制器，处理编码检测和转换逻辑
3. **ViewMainCode**：主视图，用户界面的主要实现
4. **HelperLanguage**：语言辅助类，处理多语言支持
5. **UtilsTypes**：类型定义和全局变量
6. **UtilsEncodingDetect2**：增强版编码检测器，提供更高准确性的编码检测

## 最新开发进展

### 编码检测增强

为了解决复杂编码检测场景，我们新增了增强版编码检测器 `UtilsEncodingDetect2.pas`，具有以下特点：

1. **多层次检测算法**：
   - BOM检测：快速识别UTF编码
   - 统计分析：基于字节分布特征判断编码
   - 模式匹配：识别特定编码的字节模式
   - 启发式方法：综合上下文信息判断编码

2. **亚洲语言优化**：
   - 特定的中文编码检测（GB18030、GBK、GB2312）
   - 日文编码检测（Shift-JIS、EUC-JP）
   - 韩文编码检测（EUC-KR）

3. **结果置信度**：
   - 每次检测都会提供置信度得分（0.0-1.0）
   - 可配置最小置信度阈值，低于阈值时回退到默认编码

4. **检测结果丰富**：
   - 不仅返回编码类型，还包括语言提示、检测方法等
   - 便于调试和日志记录的详细描述信息

5. **性能优化**：
   - 对大文件的高效处理，支持分块检测
   - 可配置的最大扫描大小，平衡检测精度和速度

### API 变更

新增了以下API：

```pascal
// 增强版编码检测结果
TEncodingDetectionResult = record
  DetectedEncoding: TEncoding; // 检测到的编码
  EncodingName: string;        // 编码名称
  Confidence: Double;          // 置信度 (0.0-1.0)
  HasBOM: Boolean;             // 是否有BOM
  Description: string;         // 描述
  LanguageHint: string;        // 语言提示
  DetectionMethod: string;     // 检测方法
end;

// 增强版编码检测器类
TEncodingDetector2 = class
  // 配置选项
  property Options: TEncodingDetectionOptions;
  
  // 主要方法
  function DetectFileEncoding(const FileName: string): TEncodingDetectionResult;
  function DetectStreamEncoding(Stream: TStream): TEncodingDetectionResult;
  function DetectBytesEncoding(const Bytes: TBytes): TEncodingDetectionResult;
  
  // 工具方法
  class function GetSupportedEncodings: TArray<TEncoding>;
  class function GetSupportedEncodingNames: TArray<string>;
  class function GetEncodingByName(const EncodingName: string): TEncoding;
  class function GetEncodingFriendlyName(Encoding: TEncoding): string;
end;
```

### 性能优化

1. **大文件处理**：
   - 新增分块处理算法，减少内存占用
   - 文件大小超过阈值时自动启用分块处理

2. **并行处理**：
   - 批量转换时支持并行处理
   - 通过任务队列平衡CPU负载

3. **缓存机制**：
   - 优化频繁编码检测的性能
   - 文件扩展名与编码类型的关联缓存

## 开发规范

### 命名规范

1. **单元命名**：
   - 控制器单元：`Controller{Name}.pas`
   - 模型单元：`Model{Name}.pas`
   - 视图单元：`View{Name}.pas`
   - 辅助类单元：`Helper{Name}.pas`
   - 工具类单元：`Utils{Name}.pas`

2. **类命名**：
   - 控制器类：`T{Name}Controller`
   - 模型类：`T{Name}Model`
   - 视图类：`T{Name}Form`
   - 辅助类：`T{Name}Helper`
   - 工具类：`T{Name}Utils`

3. **变量命名**：
   - 类成员变量：`F{Name}`
   - 局部变量：驼峰命名法，如 `fileName`
   - 常量：全大写，下划线分隔，如 `MAX_FILE_SIZE`

### 代码风格

1. **缩进**：使用 2 个空格缩进
2. **大括号**：开括号与语句在同一行，闭括号单独一行
3. **注释**：使用 `//` 进行单行注释，使用 `{ }` 进行多行注释
4. **文档注释**：使用 `///` 进行文档注释

### 提交规范

提交信息格式：`[类型] 简短描述`

类型包括：
- `[feat]`：新功能
- `[fix]`：修复 bug
- `[docs]`：文档更新
- `[style]`：代码风格调整
- `[refactor]`：代码重构
- `[perf]`：性能优化
- `[test]`：测试相关
- `[chore]`：构建过程或辅助工具的变动

## 计划中的特性

1. **自动编码建议**：基于文件内容自动推荐最佳编码

2. **批量处理优化**：
   - 批处理队列管理
   - 进度报告增强
   - 错误处理和恢复机制

3. **日志系统增强**：
   - 详细的日志级别
   - 日志文件保存和轮换
   - 日志查看器界面

4. **支持更多格式**：
   - EBCDIC编码系列
   - 更多区域特定的编码

5. **多线程优化**：
   - 大型批处理时的并发处理
   - UI响应性提升

## 国际化支持

### 语言文件结构

语言文件采用 INI 格式，存放在 `ini` 目录下，文件名格式为 `{language_code}.ini`。

每个语言文件包含以下部分：
1. **Meta**：元数据，包括语言名称、作者、版本等
2. **Strings**：用户界面文本
3. **Messages**：消息文本
4. **Encodings**：编码名称翻译

示例：
```ini
[Meta]
LanguageCode=en-US
LanguageName=English
NativeName=English
Version=1.0
ExportDate=2023-08-28 10:00:00

[Strings]
WindowTitle=UTF-8 BOM Encoding Converter
BtnConvert=Convert All
BtnSingleFile=Single File
...

[Messages]
MsgSelectTargetEncoding=Please select a target encoding.
MsgSelectFiles=Please select at least one file for conversion.
...

[Encodings]
Unicode=Unicode Encodings
Chinese=Chinese Encodings
...
```

### 语言切换机制

1. **语言检测**：启动时自动检测系统语言，并加载相应的语言文件
2. **语言选择**：用户可以通过下拉框手动选择语言
3. **动态切换**：支持运行时切换语言，无需重启应用程序

### 支持的语言

TransSuccess 支持以下 16 种常用语言：

1. 简体中文 (zh-CN)
2. 繁体中文 (zh-TW)
3. 英语 (en-US)
4. 西班牙语 (es-ES)
5. 法语 (fr-FR)
6. 德语 (de-DE)
7. 意大利语 (it-IT)
8. 葡萄牙语 (pt-BR)
9. 俄语 (ru-RU)
10. 日语 (ja-JP)
11. 韩语 (ko-KR)
12. 阿拉伯语 (ar-SA)
13. 荷兰语 (nl-NL)
14. 波兰语 (pl-PL)
15. 泰语 (th-TH)
16. 越南语 (vi-VN)

## 编码支持

TransSuccess 支持联合国多语言标准，覆盖全球范围内的主要编码格式，包括：

1. **Unicode 编码**：
   - UTF-8（带 BOM 和不带 BOM）
   - UTF-16LE（小端序）
   - UTF-16BE（大端序）
   - UTF-32LE（小端序）
   - UTF-32BE（大端序）
   - UTF-7

2. **西欧/美洲编码**：
   - Windows-1252 (西欧Windows)
   - Windows-1250 (中欧Windows)
   - MacRoman (苹果西欧)
   - IBM850 (DOS西欧)
   - IBM437 (DOS美国)
   - IBM865 (DOS北欧)
   - IBM860 (DOS葡萄牙语)
   - ISO-8859-1 (Latin-1)
   - ISO-8859-15 (Latin-9，含欧元符号)

3. **东欧/斯拉夫编码**：
   - Windows-1253 (希腊Windows)
   - Windows-1254 (土耳其Windows)
   - Windows-1257 (波罗的海Windows)
   - Windows-1251 (西里尔Windows)
   - KOI8-R (俄语)
   - KOI8-U (乌克兰语)
   - MacCyrillic (苹果西里尔)
   - MacGreek (苹果希腊语)
   - MacTurkish (苹果土耳其语)
   - ISO-8859-2 (Latin-2，中欧)
   - ISO-8859-3 (Latin-3，南欧)
   - ISO-8859-4 (Latin-4，北欧)
   - ISO-8859-5 (Cyrillic，斯拉夫)
   - ISO-8859-7 (Greek，希腊)
   - ISO-8859-9 (Turkish，土耳其)
   - ISO-8859-10 (Nordic，北欧)
   - ISO-8859-13 (Baltic，波罗的海)
   - ISO-8859-14 (Celtic，凯尔特)
   - ISO-8859-16 (Romanian，罗马尼亚)

4. **中东/希伯来/阿拉伯编码**：
   - Windows-1255 (希伯来Windows)
   - Windows-1256 (阿拉伯Windows)
   - CP862 (DOS希伯来)
   - CP864 (DOS阿拉伯)
   - ISO-8859-6 (阿拉伯)
   - ISO-8859-6-I (阿拉伯方向反转)
   - ISO-8859-8 (希伯来)
   - MacArabic (苹果阿拉伯)
   - MacHebrew (苹果希伯来)
   - ARMSCII-8 (亚美尼亚)
   - GEOSTD8 (格鲁吉亚)

5. **亚洲编码**：
   - **中文**：
     - GB2312 (简体中文基本编码)
     - GBK (中文扩展编码)
     - GB18030 (中文国家标准编码)
     - CP936 (简体中文Windows)
     - Big5 (繁体中文编码)
     - CP950 (繁体中文Windows)
     - Big5-HKSCS (香港繁体中文增补字符集)
     - EUC-TW (台湾EUC编码)
   - **日文**：
     - Shift-JIS (日文主要编码)
     - CP932 (日本Windows编码)
     - EUC-JP (日文扩展Unix编码)
     - ISO-2022-JP (日文邮件和网络编码)
   - **韩文**：
     - EUC-KR (韩文扩展Unix编码)
     - CP949 (韩国Windows编码)
     - Johab (韩文Johab编码)
     - ISO-2022-KR (韩文邮件和网络编码)

6. **南亚和东南亚编码**：
   - **印度语系**：
     - ISCII-Devanagari (印地语等)
     - ISCII-Bengali (孟加拉语)
     - ISCII-Tamil (泰米尔语)
     - ISCII-Telugu (泰卢固语)
     - ISCII-Assamese (阿萨姆语)
     - ISCII-Oriya (奥里亚语)
     - ISCII-Kannada (卡纳达语)
     - ISCII-Malayalam (马拉雅拉姆语)
     - ISCII-Gujarati (古吉拉特语)
     - ISCII-Punjabi (旁遮普语)
   - TSCII (泰米尔语专用编码)
   - TIS-620 (泰语编码)
   - Windows-874 (泰语Windows编码)
   - VISCII (越南语编码)
   - Windows-1258 (越南语Windows编码)

7. **其他编码**：
   - ASCII (基本ASCII编码)
   - EBCDIC-US (IBM大型机美国编码)
   - EBCDIC-International (IBM大型机国际编码)
   - EBCDIC-Latin-9 (IBM大型机拉丁9编码)

所有上述编码均支持互相转换，对于某些特殊编码对，转换过程会通过 UTF-8 作为中间格式进行两步转换，以确保转换的精确性。此外，系统针对各地区特殊编码提供了专门的检测算法，大大提升了无BOM文件的编码识别准确率。

## 功能特性

### 核心功能

1. **文件编码检测**：
   - 自动检测文件编码
   - 支持BOM检测
   - 基于字符频率和语言特征的高级检测算法

2. **编码转换**：
   - 单文件转换
   - 批量文件转换
   - 支持保留或添加BOM标记

3. **文件浏览**：
   - 文件夹浏览
   - 文件类型筛选
   - 子目录递归搜索

4. **文件预览**：
   - 文本文件内容查看
   - 语法高亮支持
   - 编码信息显示

5. **SVG转ICON**：
   - SVG文件转换为ICO格式
   - 支持自定义输出路径

### 用户界面

1. **多语言界面**：
   - 支持16种语言
   - 运行时动态切换

2. **主题支持**：
   - 亮色模式
   - 暗色模式
   - 自定义主题

3. **操作便捷性**：
   - 拖放支持
   - 上下文菜单
   - 快捷键支持
   - 历史记录

4. **界面布局**：
   - 可调整面板
   - 自定义列表视图
   - 状态栏信息

## 开发计划

### 当前优先任务（2024年7月-8月）

1. **国际化完善**：
   - 检查所有16种语言文件的完整性
   - 确保所有UI元素都能正确翻译
   - 测试RTL语言(如阿拉伯语)的界面布局

2. **编码检测增强**：
   - 改进混合语言文本的编码检测
   - 添加更多启发式规则提高准确率
   - 实现编码检测结果的置信度评分

3. **文件处理优化**：
   - 限制文件内容查看仅支持文本文件
   - 为大文件添加部分加载功能
   - 改进文件类型检测

### 中期计划（2024年9月-10月）

1. **批量处理增强**：
   - 实现并行处理提高转换效率
   - 添加转换进度显示
   - 实现批量转换的暂停和恢复

2. **SVG转ICON功能完善**：
   - 支持多种尺寸的图标生成
   - 添加批量转换功能
   - 提供更多转换选项

3. **性能优化**：
   - 优化大文件处理的内存使用
   - 实现流式处理大文件
   - 添加缓存机制避免重复检测

### 长期计划（2024年11月及以后）

1. **高级功能开发**：
   - 实现文件比较功能
   - 添加编码统计分析
   - 开发命令行版本

2. **用户体验改进**：
   - 添加深色模式支持
   - 实现配置保存功能
   - 完善帮助系统

3. **跨平台支持**：
   - 研究Delphi跨平台开发可能性
   - 评估使用其他技术栈重写核心功能
   - 探索Web版本开发

## 测试策略

### 单元测试

使用 DUnit 框架进行单元测试，主要测试以下组件：

1. 编码检测功能
2. 编码转换功能
3. 文件操作功能
4. 国际化支持功能

### 集成测试

测试各组件之间的交互，确保系统作为一个整体正常工作。

### 性能测试

测试大文件和批量转换的性能，确保程序在各种情况下都能高效运行。

### 用户界面测试

测试用户界面的可用性和响应性，确保良好的用户体验。

## 发布准备

### 发布流程

1. **版本号规则**：采用语义化版本号（Semantic Versioning）
2. **发布渠道**：GitHub Releases、官方网站
3. **发布内容**：
   - 可执行文件（32 位和 64 位）
   - 语言文件
   - 文档
   - 更新日志

### 发布文档

1. **功能介绍文档**：详细介绍软件功能和支持的编码格式
2. **使用说明文档**：提供软件使用方法和最佳实践
3. **试用引导文案**：帮助新用户快速上手

### 发布形式

1. **免费使用**：软件免费提供给所有用户
2. **压缩包分发**：使用ZIP压缩包分发，无需安装程序
3. **帮助文件**：使用HTML格式放置在网站上

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 联系方式

- 项目负责人：[联系邮箱]
- 技术支持：[支持邮箱]
- 官方网站：[网站地址]
- GitHub 仓库：[仓库地址]
