# TransSuccess 编码转换工具

一个使用Delphi开发的编码转换工具，支持多种编码格式的检测和转换。

## 安装iconv库

要启用扩展编码支持，请安装libiconv库：

1. 下载 libiconv 库文件：
   - 32位系统: https://github.com/win-iconv/win-iconv/releases/download/v0.0.8/win-iconv-0.0.8-x86.zip
   - 64位系统: https://github.com/win-iconv/win-iconv/releases/download/v0.0.8/win-iconv-0.0.8-x64.zip

2. 从ZIP文件中提取 `iconv.dll`，并将其重命名为：
   - 32位系统: `libiconv-2.dll`
   - 64位系统: `libiconv-x64.dll`

3. 将DLL文件复制到程序主目录（与 `TransSuccess.exe` 同一目录）。

## 功能特性

- 支持检测和转换文件编码
- 支持50多种编码格式
- 批量处理多个文件
- 语法高亮显示文件内容
- 多语言界面

## 使用方法

1. 选择文件或文件夹
2. 选择目标编码
3. 点击"转换"按钮

## 支持的编码

- UTF-8 (带BOM和不带BOM)
- UTF-16 (LE/BE)
- UTF-32 (LE/BE)
- GB2312/GBK/GB18030
- Big5
- Shift-JIS
- EUC-JP
- ISO-8859 系列
- 以及更多... 