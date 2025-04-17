# TransSuccess 开发文档

## 项目概述

TransSuccess 是一款文件编码转换工具，旨在提供简单、高效、可靠的文件编码转换功能。本项目使用 Delphi 开发，支持多种编码格式之间的转换，包括 UTF-8、UTF-16、GBK、BIG5、Shift-JIS 等。

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

TransSuccess 支持多种编码格式之间的转换，包括：

1. **Unicode 编码**：
   - UTF-8（带 BOM 和不带 BOM）
   - UTF-16LE（小端序）
   - UTF-16BE（大端序）
   - UTF-32LE（小端序）
   - UTF-32BE（大端序）

2. **中文编码**：
   - GB2312
   - GBK
   - GB18030
   - BIG5
   - BIG5-HKSCS

3. **日文编码**：
   - Shift-JIS
   - EUC-JP
   - ISO-2022-JP

4. **韩文编码**：
   - EUC-KR
   - Johab
   - ISO-2022-KR

5. **欧洲语言编码**：
   - ISO-8859-1 (Latin-1)
   - ISO-8859-2 (Latin-2)
   - ISO-8859-3 (Latin-3)
   - ISO-8859-4 (Latin-4)
   - ISO-8859-5 (Cyrillic)
   - ISO-8859-6 (Arabic)
   - ISO-8859-7 (Greek)
   - ISO-8859-8 (Hebrew)
   - ISO-8859-9 (Turkish)
   - ISO-8859-10 (Nordic)
   - ISO-8859-13 (Baltic)
   - ISO-8859-14 (Celtic)
   - ISO-8859-15 (Latin-9)
   - ISO-8859-16 (Romanian)

6. **Windows 代码页**：
   - Windows-1250 (Central European)
   - Windows-1251 (Cyrillic)
   - Windows-1252 (Western European)
   - Windows-1253 (Greek)
   - Windows-1254 (Turkish)
   - Windows-1255 (Hebrew)
   - Windows-1256 (Arabic)
   - Windows-1257 (Baltic)
   - Windows-1258 (Vietnamese)
   - Windows-874 (Thai)

7. **其他编码**：
   - KOI8-R (Russian)
   - KOI8-U (Ukrainian)
   - ASCII
   - EBCDIC
   - ISCII (Indian Script Code)
   - VISCII (Vietnamese)
   - TSCII (Tamil)
   - TIS-620 (Thai)
   - MacRoman
   - MacCyrillic
   - MacGreek
   - MacTurkish
   - MacArabic
   - MacHebrew

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
   - 运行时语言切换
   - 自动检测系统语言

2. **文件列表**：
   - 显示文件名和当前编码
   - 支持多选操作
   - 右键菜单功能

3. **编码选择**：
   - 树形结构显示编码
   - 按类别分组
   - 详细的编码描述

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
