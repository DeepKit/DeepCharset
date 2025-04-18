@echo off
setlocal enabledelayedexpansion

echo 编码检测和转换测试
echo ==================
echo.

rem 检查Python是否安装
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 未找到Python。请安装Python并确保它在PATH中。
    exit /b 1
)

rem 检查chardet是否安装
python -c "import chardet" >nul 2>&1
if %errorlevel% neq 0 (
    echo 正在安装chardet...
    pip install chardet
    if %errorlevel% neq 0 (
        echo 错误: 无法安装chardet。
        exit /b 1
    )
)

rem 编译Delphi程序
echo 正在编译Delphi程序...
dcc32 -b CheckEncodings.dpr
if %errorlevel% neq 0 (
    echo 错误: 编译CheckEncodings.dpr失败。
    exit /b 1
)

dcc32 -b ConvertEncodings.dpr
if %errorlevel% neq 0 (
    echo 错误: 编译ConvertEncodings.dpr失败。
    exit /b 1
)

rem 设置测试目录
set SOURCE_DIR=from
set DELPHI_DIR=byDelphi
set PYTHON_DIR=byPython

rem 确保目标目录存在
if not exist "%DELPHI_DIR%" mkdir "%DELPHI_DIR%"
if not exist "%PYTHON_DIR%" mkdir "%PYTHON_DIR%"

rem 第一步: 编码检测
echo.
echo 步骤1: 编码检测
echo --------------
echo.

echo 使用Delphi检测文件编码...
CheckEncodings.exe "%SOURCE_DIR%" delphi_encoding_results.csv
echo.

echo 使用Python检测文件编码...
python check_encodings.py "%SOURCE_DIR%" python_encoding_results.csv
echo.

rem 第二步: 编码转换
echo.
echo 步骤2: 编码转换
echo --------------
echo.

echo 使用Delphi转换文件编码...
ConvertEncodings.exe "%SOURCE_DIR%" "%DELPHI_DIR%" utf-8 true
echo.

echo 使用Python转换文件编码...
python convert_encodings.py "%SOURCE_DIR%" "%PYTHON_DIR%" utf-8 true
echo.

rem 第三步: 比较结果
echo.
echo 步骤3: 比较结果
echo --------------
echo.

echo 使用Python比较结果...
python compare_results.py delphi_encoding_results.csv python_encoding_results.csv "%DELPHI_DIR%" "%PYTHON_DIR%" comparison_results.html
if %errorlevel% neq 0 (
    echo 错误: 比较结果失败。
    exit /b 1
)

echo 编码检测结果比较:
echo Delphi检测结果: delphi_encoding_results.csv
echo Python检测结果: python_encoding_results.csv
echo.

echo 编码转换结果比较:
echo Delphi转换结果目录: %DELPHI_DIR%
echo Python转换结果目录: %PYTHON_DIR%
echo.

echo 比较结果已保存到: comparison_results.html
echo.

echo 测试完成!
echo.
echo 按任意键打开比较结果...
pause >nul

rem 打开比较结果
start "" comparison_results.html

exit /b 0
