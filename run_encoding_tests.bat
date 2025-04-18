@echo off
setlocal enabledelayedexpansion

rem 设置测试文件目录
set TEST_DIR=TestFiles

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

rem 创建测试文件目录
if not exist "%TEST_DIR%" mkdir "%TEST_DIR%"

rem 生成测试文件
echo 正在生成测试文件...
python generate_test_files.py --output "%TEST_DIR%"
if %errorlevel% neq 0 (
    echo 错误: 无法生成测试文件。
    exit /b 1
)

rem 创建结果文件
echo 文件名,chardet检测结果,置信度 > encoding_test_results.csv

rem 处理所有测试文件
echo 正在测试所有文件...
for %%F in ("%TEST_DIR%\*.txt") do (
    echo 处理文件: %%F
    
    rem 使用chardet检测
    for /f "tokens=1,2 delims=:" %%A in ('python detect_encoding.py "%%F" ^| findstr /C:"编码:" /C:"置信度:"') do (
        if "%%A"=="编码" (
            set "encoding=%%B"
        ) else if "%%A"=="置信度" (
            set "confidence=%%B"
            
            rem 移除前导空格
            set "encoding=!encoding:~1!"
            set "confidence=!confidence:~1!"
            
            rem 添加到结果文件
            echo %%~nxF,!encoding!,!confidence! >> encoding_test_results.csv
        )
    )
)

echo 测试完成! 结果已保存到 encoding_test_results.csv
echo 按任意键查看结果...
pause > nul

rem 打开结果文件
start "" encoding_test_results.csv

exit /b 0
