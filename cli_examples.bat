@echo off
REM TransSuccess 命令行转码示例脚本
REM 
REM 使用前请先编译 TransSuccess.exe

setlocal
set EXE=bin\TransSuccess.exe

echo ====================================
echo TransSuccess 命令行转码示例
echo ====================================
echo.

REM 检查程序是否存在
if not exist "%EXE%" (
    echo 错误: 未找到 %EXE%
    echo 请先编译程序
    pause
    exit /b 1
)

echo 1. 显示帮助信息
echo ------------------------
%EXE% --help
echo.
pause

echo.
echo 2. 显示版本信息
echo ------------------------
%EXE% --version
echo.
pause

REM 创建测试文件
echo.
echo 3. 创建测试文件
echo ------------------------
if not exist "tmp_tests" mkdir tmp_tests

echo 这是一个GBK编码的测试文件 > tmp_tests\test_gbk.txt
echo 包含中文内容：你好，世界！ >> tmp_tests\test_gbk.txt

echo 已创建测试文件: tmp_tests\test_gbk.txt
echo.
pause

echo.
echo 4. 单文件转换 (GBK -> UTF-8)
echo ------------------------
%EXE% -s GBK -t UTF-8 --verbose tmp_tests\test_gbk.txt
echo.
pause

echo.
echo 5. 转换并输出到新文件
echo ------------------------
%EXE% -s auto -t UTF-8 tmp_tests\test_gbk.txt -o tmp_tests\test_utf8.txt --verbose
echo.
pause

echo.
echo 6. 添加 BOM
echo ------------------------
%EXE% -s UTF-8 -t UTF-8 --add-bom --verbose tmp_tests\test_utf8.txt
echo.
pause

echo.
echo 7. 移除 BOM
echo ------------------------
%EXE% -s UTF-8 -t UTF-8 --remove-bom --verbose tmp_tests\test_utf8.txt
echo.
pause

echo.
echo 8. 带备份的转换
echo ------------------------
%EXE% -s GBK -t UTF-8 -b --verbose tmp_tests\test_gbk.txt
echo 查看备份文件: tmp_tests\test_gbk.txt.bak
echo.
pause

echo.
echo 9. 使用代码页转换 (936=GBK, 65001=UTF-8)
echo ------------------------
%EXE% -s 936 -t 65001 --verbose tmp_tests\test_gbk.txt
echo.
pause

echo.
echo 测试完成！
echo.
pause
