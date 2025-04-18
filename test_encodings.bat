@echo off
setlocal enabledelayedexpansion

rem 设置测试文件目录
set TEST_DIR=TestFiles

rem 检查目录是否存在
if not exist "%TEST_DIR%" (
    echo 错误: 测试文件目录不存在: %TEST_DIR%
    exit /b 1
)

rem 删除旧的结果文件
if exist encoding_compare_results.csv del encoding_compare_results.csv

rem 处理目录中的所有文件
for %%F in ("%TEST_DIR%\*.*") do (
    echo 处理文件: %%F
    EncodingCompare.exe "%%F"
    echo.
)

echo 测试完成! 结果已保存到 encoding_compare_results.csv
echo 按任意键查看结果...
pause > nul

rem 打开结果文件
start "" encoding_compare_results.csv

exit /b 0
