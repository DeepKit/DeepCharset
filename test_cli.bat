@echo off
REM 测试命令行功�?echo 测试 DeepCharset 命令行功�?echo ================================
echo.

echo 1. 测试 --version
bin\DeepCharset.exe --version
echo.

echo 2. 测试 --help
bin\DeepCharset.exe --help
echo.

echo 3. 创建测试文件（GBK编码�?if not exist "tmp_tests" mkdir tmp_tests
echo 这是测试文件 > tmp_tests\cli_test.txt
echo 中文内容测试 >> tmp_tests\cli_test.txt
echo.

echo 4. 测试单文件转�?bin\DeepCharset.exe -s auto -t UTF-8 --verbose tmp_tests\cli_test.txt
echo.

pause
