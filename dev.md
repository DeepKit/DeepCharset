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
├── lib/                  # 第三方库
├── src/                  # 源代码
│   ├── controllers/      # 控制器
│   ├── helpers/          # 辅助类
│   ├── models/           # 数据模型
│   ├── utils/            # 工具类
│   └── views/            # 视图
├── tests/                # 测试代码
├── docs/                 # 文档
└── resources/            # 资源文件
```

### 核心组件

1. **ModelEncoding**：编码模型，定义编码相关的数据结构
2. **ControllerEncoding**：编码控制器，处理编码检测和转换逻辑
3. **ViewMainCode**：主视图，用户界面的主要实现
4. **HelperLanguage**：语言辅助类，处理多语言支持
5. **UtilsICU**：ICU 库封装，提供编码检测和转换功能

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

语言文件采用 JSON 格式，存放在 `resources/languages` 目录下，文件名格式为 `{language_code}.json`。

每个语言文件包含以下部分：
1. **meta**：元数据，包括语言名称、作者、版本等
2. **ui**：用户界面文本
3. **messages**：消息文本
4. **errors**：错误文本

示例：
```json
{
  "meta": {
    "language": "English",
    "code": "en",
    "author": "TransSuccess Team",
    "version": "1.0.0"
  },
  "ui": {
    "main_window_title": "TransSuccess - File Encoding Converter",
    "menu_file": "File",
    "menu_edit": "Edit",
    "menu_help": "Help"
  },
  "messages": {
    "conversion_success": "Conversion completed successfully.",
    "file_not_found": "File not found."
  },
  "errors": {
    "encoding_detection_failed": "Failed to detect file encoding.",
    "conversion_failed": "Conversion failed."
  }
}
```

### 语言切换机制

1. **语言检测**：启动时自动检测系统语言，并加载相应的语言文件
2. **语言选择**：用户可以通过设置对话框手动选择语言
3. **动态切换**：支持运行时切换语言，无需重启应用程序

### 支持的语言

TransSuccess 计划支持以下 16 种常用语言：

1. 简体中文 (zh-CN)
2. 繁体中文 (zh-TW)
3. 英语 (en)
4. 西班牙语 (es)
5. 法语 (fr)
6. 德语 (de)
7. 意大利语 (it)
8. 葡萄牙语 (pt)
9. 俄语 (ru)
10. 日语 (ja)
11. 韩语 (ko)
12. 阿拉伯语 (ar)
13. 荷兰语 (nl)
14. 波兰语 (pl)
15. 土耳其语 (tr)
16. 越南语 (vi)

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

3. **日文编码**：
   - Shift-JIS
   - EUC-JP

4. **韩文编码**：
   - EUC-KR

5. **其他编码**：
   - ISO-8859 系列
   - Windows 代码页系列
   - KOI8-R
   - ASCII

## 开发计划

### 短期目标（1-2 个月）

1. 完成国际化支持，实现 16 种语言的翻译
2. 优化编码检测算法，提高准确率
3. 改进批量转换性能，支持大文件处理
4. 完善错误处理机制，提高程序稳定性

### 中期目标（3-6 个月）

1. 添加更多编码格式支持
2. 实现插件系统，支持功能扩展
3. 开发命令行版本，支持脚本和自动化操作
4. 添加更多高级功能，如文件比较、编码统计等

### 长期目标（6-12 个月）

1. 开发跨平台版本，支持 macOS 和 Linux
2. 实现云同步功能，支持配置和历史记录同步
3. 开发 Web 版本，提供在线编码转换服务
4. 建立用户社区，收集反馈并持续改进

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

## 发布流程

1. **版本号规则**：采用语义化版本号（Semantic Versioning）
2. **发布渠道**：GitHub Releases、官方网站
3. **发布内容**：
   - 可执行文件（32 位和 64 位）
   - 语言文件
   - 文档
   - 更新日志

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
