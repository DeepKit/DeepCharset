@echo off
REM 测试命令行功能
echo 测试 TransSuccess 命令行功能
echo ================================
echo.

echo 1. 测试 --version
bin\TransSuccess.exe --version
echo.

echo 2. 测试 --help
bin\TransSuccess.exe --help
echo.

echo 3. 创建测试文件（GBK编码）
if not exist "tmp_tests" mkdir tmp_tests
echo 这是测试文件 > tmp_tests\cli_test.txt
echo 中文内容测试 >> tmp_tests\cli_test.txt
echo.

echo 4. 测试单文件转换
bin\TransSuccess.exe -s auto -t UTF-8 --verbose tmp_tests\cli_test.txt
echo.

pause
