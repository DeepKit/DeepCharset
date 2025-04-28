@echo off
setlocal enabledelayedexpansion

echo 编码检测和转换测试套件
echo ====================
echo.

REM 设置测试文件目录
set TEST_DIR=TestFiles
set RESULTS_DIR=TestResults

REM 创建测试目录
if not exist "%TEST_DIR%" mkdir "%TEST_DIR%"
if not exist "%RESULTS_DIR%" mkdir "%RESULTS_DIR%"

REM 编译测试程序
echo 正在编译测试程序...
echo -------------------

echo 编译 EncodingTestRunner.dpr...
dcc32 -B EncodingTestRunner.dpr
if errorlevel 1 (
    echo 编译失败！
    pause
    exit /b 1
) else (
    echo 编译成功！
)

echo 编译 TestUTF8BOMConversion.dpr...
dcc32 -B TestUTF8BOMConversion.dpr
if errorlevel 1 (
    echo 编译失败！
    pause
    exit /b 1
) else (
    echo 编译成功！
)

REM 创建结果文件
echo 文件名,检测编码,置信度,BOM,耗时(ms) > "%RESULTS_DIR%\encoding_test_results.csv"

echo.
echo 运行编码检测测试
echo ---------------
echo.

REM 测试UTF-8检测
echo 1. 测试UTF-8检测
EncodingTestRunner.exe detect "%TEST_DIR%\test_utf8.txt" > "%RESULTS_DIR%\utf8_detection.txt"
echo    结果已保存到 %RESULTS_DIR%\utf8_detection.txt

REM 测试UTF-8+BOM检测
echo 2. 测试UTF-8+BOM检测
EncodingTestRunner.exe detect "%TEST_DIR%\test_utf8_bom.txt" > "%RESULTS_DIR%\utf8_bom_detection.txt"
echo    结果已保存到 %RESULTS_DIR%\utf8_bom_detection.txt

REM 测试GBK检测
echo 3. 测试GBK检测
EncodingTestRunner.exe detect "%TEST_DIR%\test_gbk.txt" > "%RESULTS_DIR%\gbk_detection.txt"
echo    结果已保存到 %RESULTS_DIR%\gbk_detection.txt

REM 测试UTF-16LE检测
echo 4. 测试UTF-16LE检测
EncodingTestRunner.exe detect "%TEST_DIR%\test_utf16le.txt" > "%RESULTS_DIR%\utf16le_detection.txt"
echo    结果已保存到 %RESULTS_DIR%\utf16le_detection.txt

REM 测试ASCII检测
echo 5. 测试ASCII检测
EncodingTestRunner.exe detect "%TEST_DIR%\test_ascii.txt" > "%RESULTS_DIR%\ascii_detection.txt"
echo    结果已保存到 %RESULTS_DIR%\ascii_detection.txt

echo.
echo 运行编码转换测试
echo ---------------
echo.

REM 测试UTF-8到UTF-8+BOM转换
echo 1. 测试UTF-8到UTF-8+BOM转换
TestUTF8BOMConversion.exe add "%TEST_DIR%\test_utf8.txt" "%RESULTS_DIR%\utf8_to_bom.txt" > "%RESULTS_DIR%\utf8_to_bom_conversion.txt"
echo    结果已保存到 %RESULTS_DIR%\utf8_to_bom_conversion.txt

REM 测试UTF-8+BOM到UTF-8转换
echo 2. 测试UTF-8+BOM到UTF-8转换
TestUTF8BOMConversion.exe remove "%TEST_DIR%\test_utf8_bom.txt" "%RESULTS_DIR%\bom_to_utf8.txt" > "%RESULTS_DIR%\bom_to_utf8_conversion.txt"
echo    结果已保存到 %RESULTS_DIR%\bom_to_utf8_conversion.txt

REM 测试GBK到UTF-8转换
echo 3. 测试GBK到UTF-8转换
EncodingTestRunner.exe convert "%TEST_DIR%\test_gbk.txt" "%RESULTS_DIR%\gbk_to_utf8.txt" utf-8 false > "%RESULTS_DIR%\gbk_to_utf8_conversion.txt"
echo    结果已保存到 %RESULTS_DIR%\gbk_to_utf8_conversion.txt

REM 测试UTF-8到GBK转换
echo 4. 测试UTF-8到GBK转换
EncodingTestRunner.exe convert "%TEST_DIR%\test_utf8.txt" "%RESULTS_DIR%\utf8_to_gbk.txt" gbk false > "%RESULTS_DIR%\utf8_to_gbk_conversion.txt"
echo    结果已保存到 %RESULTS_DIR%\utf8_to_gbk_conversion.txt

REM 测试UTF-16LE到UTF-8转换
echo 5. 测试UTF-16LE到UTF-8转换
EncodingTestRunner.exe convert "%TEST_DIR%\test_utf16le.txt" "%RESULTS_DIR%\utf16le_to_utf8.txt" utf-8 false > "%RESULTS_DIR%\utf16le_to_utf8_conversion.txt"
echo    结果已保存到 %RESULTS_DIR%\utf16le_to_utf8_conversion.txt

echo.
echo 运行批量测试
echo -----------
echo.

REM 批量检测测试
echo 1. 批量检测测试
if not exist "%RESULTS_DIR%\batch" mkdir "%RESULTS_DIR%\batch"
EncodingTestRunner.exe batch "%TEST_DIR%" utf-8 false > "%RESULTS_DIR%\batch_detection.txt"
echo    结果已保存到 %RESULTS_DIR%\batch_detection.txt

REM 批量转换测试
echo 2. 批量转换测试
TestUTF8BOMConversion.exe batch "%TEST_DIR%" "%RESULTS_DIR%\batch" > "%RESULTS_DIR%\batch_conversion.txt"
echo    结果已保存到 %RESULTS_DIR%\batch_conversion.txt

REM 处理所有测试文件并生成CSV报告
echo 3. 生成测试报告
echo 正在生成测试报告...

for %%F in ("%TEST_DIR%\*.txt") do (
    echo 处理文件: %%~nxF

    REM 使用我们的程序检测编码
    EncodingTestRunner.exe detect "%%F" > temp_result.txt

    REM 解析结果
    for /f "tokens=1,2 delims=:" %%A in ('type temp_result.txt ^| findstr /C:"编码:" /C:"置信度:" /C:"BOM:" /C:"检测耗时:"') do (
        if "%%A"=="编码" (
            set "encoding=%%B"
        ) else if "%%A"=="置信度" (
            set "confidence=%%B"
        ) else if "%%A"=="BOM" (
            set "bom=%%B"
        ) else if "%%A"=="检测耗时" (
            set "time=%%B"

            REM 移除前导空格
            set "encoding=!encoding:~1!"
            set "confidence=!confidence:~1!"
            set "bom=!bom:~1!"
            set "time=!time:~1!"

            REM 添加到结果文件
            echo %%~nxF,!encoding!,!confidence!,!bom!,!time! >> "%RESULTS_DIR%\encoding_test_results.csv"
        )
    )
)

del temp_result.txt

echo.
echo 测试完成！
echo 所有测试结果已保存到 %RESULTS_DIR% 目录
echo.
echo 按任意键查看结果...
pause > nul

REM 打开结果文件
start "" "%RESULTS_DIR%\encoding_test_results.csv"

exit /b 0
