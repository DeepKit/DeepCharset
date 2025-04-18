@echo off
setlocal enabledelayedexpansion

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

rem 检查命令行参数
if "%~1"=="" (
    echo 用法: run_chardet.bat ^<文件路径^>
    exit /b 1
)

rem 检查文件是否存在
if not exist "%~1" (
    echo 错误: 文件不存在 - %~1
    exit /b 1
)

rem 运行Python脚本检测编码
echo 正在使用chardet检测文件编码: %~1
python detect_encoding.py "%~1"

echo.
echo 按任意键退出...
pause >nul

exit /b 0
