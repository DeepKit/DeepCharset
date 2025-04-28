@echo off
echo UTF-8到UTF-8+BOM转换测试
echo =====================

REM 编译测试程序
echo 正在编译测试程序...
dcc32 -B TestUTF8BOMConversion.dpr
if errorlevel 1 (
    echo 编译失败！
    pause
    exit /b 1
)

REM 创建测试目录
if not exist testfiles_bom mkdir testfiles_bom

REM 运行测试
echo.
echo 1. 测试添加BOM到单个文件
echo -------------------
TestUTF8BOMConversion.exe add TestFiles\test_utf8.txt testfiles_bom\test_utf8_bom.txt

echo.
echo 2. 测试从单个文件移除BOM
echo -------------------
TestUTF8BOMConversion.exe remove testfiles_bom\test_utf8_bom.txt testfiles_bom\test_utf8_nobom.txt

echo.
echo 3. 测试批量添加BOM
echo -------------------
TestUTF8BOMConversion.exe batch TestFiles testfiles_bom

echo.
echo 测试完成！
pause
