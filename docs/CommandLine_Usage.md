# DeepCharset 命令行使用指�?

## 概述

DeepCharset 支持命令行模式进行批量文件编码转换，无需启动图形界面即可完成转换任务�?

## 基本语法

```bash
DeepCharset.exe [选项] <输入文件或目�?
```

## 命令行选项

### 编码选项
- `-s, --source <编码>` - 源编码（默认：auto - 自动检测）
- `-t, --target <编码>` - 目标编码（默认：UTF-8�?

### 输出选项
- `-o, --output <文件>` - 输出文件路径（默认：覆盖原文件）
- `--add-bom` - 添加 BOM（仅适用�?UTF-8/UTF-16/UTF-32�?
- `--remove-bom` - 移除 BOM

### 批量处理选项
- `-r, --recursive` - 递归处理子目�?
- `-b, --backup` - 转换前创建备份文件（.bak�?

### 输出控制
- `-q, --quiet` - 安静模式，不显示任何输出
- `--verbose` - 显示详细信息（包括每个文件的转换结果�?

### 帮助选项
- `-h, --help, /?` - 显示帮助信息
- `-v, --version` - 显示版本信息

## 支持的编�?

### Unicode 系列
- **UTF-8** - Unicode 8位编码（默认�?
- **UTF-16LE** - Unicode 16位小端编�?
- **UTF-16BE** - Unicode 16位大端编�?
- **UTF-32LE** - Unicode 32位小端编�?
- **UTF-32BE** - Unicode 32位大端编�?

### 中文编码
- **GBK** / **936** - 简体中文（GB2312 扩展�?
- **GB2312** - 简体中文基本集
- **GB18030** / **54936** - 中国国家标准（支持繁简体）
- **Big5** / **950** - 繁体中文

### 日文编码
- **Shift-JIS** / **932** - 日语（Windows 默认�?
- **EUC-JP** / **51932** - 日语扩展Unix编码
- **ISO-2022-JP** / **50220** - 日语JIS编码

### 韩文编码
- **EUC-KR** / **949** - 韩语扩展Unix编码
- **JOHAB** / **1361** - 韩语Johab编码

### 其他编码
- **Windows-1252** / **1252** - 西欧语言
- **ISO-8859-1** / **28591** - 拉丁�?
- **ASCII** / **20127** - 7位ASCII编码

### 使用代码�?
也可以直接使用代码页数字，例如：
- `936` = GBK
- `950` = Big5
- `65001` = UTF-8
- `1200` = UTF-16LE

## 使用示例

### 1. 单文件转�?

#### GBK �?UTF-8
```bash
DeepCharset.exe -s GBK -t UTF-8 input.txt
```

#### 自动检测源编码
```bash
DeepCharset.exe -s auto -t UTF-8 input.txt
```

#### 转换并输出到新文�?
```bash
DeepCharset.exe -s GBK -t UTF-8 input.txt -o output.txt
```

### 2. BOM 处理

#### 添加 UTF-8 BOM
```bash
DeepCharset.exe -s UTF-8 -t UTF-8 --add-bom file.txt
```

#### 移除 BOM
```bash
DeepCharset.exe -s UTF-8 -t UTF-8 --remove-bom file.txt
```

### 3. 批量转换

#### 转换目录下所有文�?
```bash
DeepCharset.exe -s GBK -t UTF-8 C:\MyFiles\
```

#### 递归转换（包括子目录�?
```bash
DeepCharset.exe -s GBK -t UTF-8 -r C:\MyFiles\
```

#### 带备份的批量转换
```bash
DeepCharset.exe -s GBK -t UTF-8 -r -b C:\MyFiles\
```

### 4. 使用代码�?

#### 使用代码页数�?
```bash
DeepCharset.exe -s 936 -t 65001 input.txt
```

#### Big5 �?UTF-8
```bash
DeepCharset.exe -s 950 -t 65001 input.txt
```

### 5. 详细模式

#### 显示详细转换信息
```bash
DeepCharset.exe -s GBK -t UTF-8 --verbose input.txt
```

输出示例�?
```
处理文件: input.txt
已创建备�? input.txt.bak
�?成功: GBK -> UTF-8 (2048 字节)

转换完成:
  成功: 1
  失败: 0
```

### 6. 安静模式

#### 无输出（适用于脚本）
```bash
DeepCharset.exe -s GBK -t UTF-8 -q input.txt
echo 错误�? %ERRORLEVEL%
```

## 返回值（错误码）

- **0** - 转换成功
- **1** - 转换失败或有错误

可在批处理脚本中使用 `%ERRORLEVEL%` 检查：

```batch
DeepCharset.exe -s GBK -t UTF-8 file.txt
if %ERRORLEVEL% NEQ 0 (
    echo 转换失败�?
    exit /b 1
)
```

## 批处理脚本示�?

### 批量转换 GBK �?UTF-8

```batch
@echo off
REM 批量转换当前目录所�?txt 文件

for %%f in (*.txt) do (
    echo 转换: %%f
    DeepCharset.exe -s GBK -t UTF-8 -b "%%f"
)

echo 转换完成�?
pause
```

### 递归转换目录�?

```batch
@echo off
set SOURCE_DIR=C:\MyProject
set SOURCE_ENC=GBK
set TARGET_ENC=UTF-8

echo 开始转�?%SOURCE_DIR%
echo 源编�? %SOURCE_ENC%
echo 目标编码: %TARGET_ENC%
echo.

DeepCharset.exe -s %SOURCE_ENC% -t %TARGET_ENC% -r -b --verbose "%SOURCE_DIR%"

pause
```

### 条件转换（仅转换特定文件�?

```batch
@echo off
REM 仅转�?.pas �?.inc 文件

for %%e in (pas inc) do (
    for /r "C:\MyProject" %%f in (*.%%e) do (
        echo 转换: %%f
        DeepCharset.exe -s auto -t UTF-8 --add-bom -b "%%f"
    )
)

echo 转换完成�?
pause
```

## PowerShell 脚本示例

### 批量转换指定扩展�?

```powershell
# 转换所�?.txt �?.log 文件
$files = Get-ChildItem -Path "C:\MyFiles" -Include "*.txt","*.log" -Recurse
$exe = "DeepCharset.exe"

foreach ($file in $files) {
    Write-Host "转换: $($file.FullName)"
    & $exe -s GBK -t UTF-8 -b $file.FullName
}

Write-Host "转换完成�?
```

### 并行转换（加速处理）

```powershell
$files = Get-ChildItem -Path "C:\MyFiles" -Filter "*.txt" -Recurse
$exe = "DeepCharset.exe"

$files | ForEach-Object -Parallel {
    & $using:exe -s GBK -t UTF-8 $_.FullName
} -ThrottleLimit 4

Write-Host "并行转换完成�?
```

## �?EmEditor 命令行对�?

### EmEditor 语法
```bash
emeditor.exe file.txt /cp 65001 /cps 932 /sa output.txt
```

### DeepCharset 等效语法
```bash
DeepCharset.exe -s UTF-8 -t Shift-JIS file.txt -o output.txt
```

### 主要差异

| 功能 | EmEditor | DeepCharset |
|------|----------|--------------|
| 源编�?| `/cp <code>` | `-s <encoding>` |
| 目标编码 | `/cps <code>` | `-t <encoding>` |
| 输出文件 | `/sa <file>` | `-o <file>` |
| 添加BOM | `/ss+` | `--add-bom` |
| 移除BOM | `/ss-` | `--remove-bom` |
| 自动检�?| 不支�?| `-s auto` |
| 递归处理 | 需脚本 | `-r` |
| 备份 | 需脚本 | `-b` |

## 常见问题

### Q: 如何自动检测源编码�?
A: 使用 `-s auto` 或不指定 `-s` 参数�?
```bash
DeepCharset.exe -t UTF-8 input.txt
```

### Q: 转换失败但没有错误信息？
A: 使用 `--verbose` 查看详细信息�?
```bash
DeepCharset.exe -s GBK -t UTF-8 --verbose input.txt
```

### Q: 如何防止覆盖原文件？
A: 使用 `-o` 指定输出文件�?`-b` 创建备份�?
```bash
DeepCharset.exe -s GBK -t UTF-8 -b input.txt
```

### Q: 批量转换时如何跳过某些文件？
A: 在批处理脚本中添加过滤条件，或使�?PowerShell �?`-Exclude` 参数

### Q: 支持管道输入吗？
A: 当前版本不支持标准输�?输出，需要指定文件路�?

## 最佳实�?

1. **转换前备�?* - 使用 `-b` 选项自动创建备份
2. **先测试单个文�?* - 批量转换前先测试单个文件
3. **使用详细模式** - 初次使用时启�?`--verbose` 查看详情
4. **验证结果** - 转换后用文本编辑器打开验证
5. **使用版本控制** - 如果文件在版本控制下，可直接转换后对比差�?

## 技术支�?

- 项目主页：后续公开仓库后补�?- 问题报告：后续公开仓库后补�?- 文档：后续公开仓库后补�?
---

**最后更�?*: 2025-11-08  
**版本**: 1.2.0
