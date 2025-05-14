# 编码转换工具 (Encoding Converter)

[![Delphi Encoding Converter CI](https://github.com/YourUsername/EncodingConverter/actions/workflows/build-test.yml/badge.svg)](https://github.com/YourUsername/EncodingConverter/actions/workflows/build-test.yml)

## 项目简介

编码转换工具是一个高性能的文本文件编码检测和转换应用程序，可以轻松地将各种格式的文本文件从一种字符编码转换为另一种字符编码。

### 主要功能

- 支持自动检测文件编码
- 支持多种编码格式（UTF-8、UTF-16、UTF-32、ASCII、ANSI等）
- 高性能批量文件处理
- 可视化预览转换结果
- 多线程并行处理
- 自动备份原始文件

## 安装说明

### 系统需求

- Windows 7/8/10/11
- 不需要额外的依赖项

### 下载与安装

1. 从[发布页面](https://github.com/YourUsername/EncodingConverter/releases)下载最新版本
2. 解压缩到您选择的文件夹
3. 运行 `EncodingConverter.exe`

## 使用指南

### 单个文件转换

1. 点击"选择文件"按钮选择要转换的文件
2. 选择源文件编码（或使用自动检测）
3. 选择目标编码
4. 点击"转换"按钮

### 批量文件处理

1. 切换到"批量处理"选项卡
2. 点击"添加文件"或将文件拖放到列表中
3. 选择目标编码
4. 点击"批量转换"按钮

### 命令行使用

```
EncodingConverter.exe [选项] <输入文件> <输出文件>

选项:
  -s, --source <编码>   源文件编码
  -t, --target <编码>   目标文件编码
  -b, --backup          创建备份
  -r, --recursive       递归处理目录
  -v, --verbose         显示详细信息
```

示例:
```
EncodingConverter.exe -s utf8 -t utf16 input.txt output.txt
EncodingConverter.exe -r -b -s auto -t utf8 C:\MyFiles\
```

## 开发者信息

### 构建项目

1. 克隆仓库:
   ```
   git clone https://github.com/YourUsername/EncodingConverter.git
   ```

2. 使用Delphi IDE打开项目文件 `EncodingConverter.dproj`

3. 编译项目

也可以使用批处理脚本编译:
```
build.bat
```

### 运行测试

```
build.bat --run-tests
```

或者直接运行测试程序:
```
bin\EncodingTestRunner.exe
```

### 项目结构

- `ModelEncoding.pas` - 编码模型和核心逻辑
- `UtilsEncodingMemory.pas` - 内存管理工具
- `UtilsEncodingPerformance.pas` - 性能相关工具
- `ViewEncodingConverter.pas` - 用户界面
- `Tests/` - 测试用例

## 贡献指南

欢迎提交问题报告和代码贡献!

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/your-feature`)
3. 提交更改 (`git commit -am 'Add your feature'`)
4. 推送到分支 (`git push origin feature/your-feature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证 - 详情请参阅 [LICENSE](LICENSE) 文件

## 联系方式

如有问题或建议，请通过以下方式联系我们:

- GitHub Issues: [https://github.com/YourUsername/EncodingConverter/issues](https://github.com/YourUsername/EncodingConverter/issues)
- 电子邮件: your.email@example.com 