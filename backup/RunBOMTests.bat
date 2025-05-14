@echo off
setlocal enabledelayedexpansion

echo ===================================
echo UTF-8 BOM Conversion Test
echo ===================================

rem 确保测试目录存在
if not exist "TestData\EncodingSamples" mkdir "TestData\EncodingSamples"

rem 创建UTF-8无BOM测试文件（使用ASCII保存然后手动添加内容）
echo Test UTF-8 without BOM > "TestData\EncodingSamples\UTF8-WithoutBOM.txt"

rem 创建UTF-8带BOM测试文件
powershell -Command "echo 'Test UTF-8 with BOM' | Out-File -Encoding 'utf8' -FilePath 'TestData\EncodingSamples\UTF8-WithBOM.txt'"

rem 创建GBK测试文件
powershell -Command "echo 'Test GBK file' | Out-File -Encoding 'default' -FilePath 'TestData\EncodingSamples\GBK.txt'"

echo Test files created!

rem 编译测试程序
echo Compiling test program...
dcc32 TestUTF8BOMConverterSimple.dpr
if errorlevel 1 (
    echo Compilation failed!
    exit /b 1
)

echo Compilation successful, running tests...
TestUTF8BOMConverterSimple.exe

echo ===================================
echo Tests completed!
echo ===================================

pause 