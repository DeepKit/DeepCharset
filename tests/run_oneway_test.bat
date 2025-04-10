@echo off
echo JCL扩展编码单向转换测试程序
echo ----------------------------
echo.

REM 检查编译测试程序
if not exist conversion_roundtrip_test.exe (
    echo 正在编译测试程序...
    dcc32 -b conversion_roundtrip_test.dpr
    if errorlevel 1 (
        echo 编译失败! 请检查Delphi和JCL环境。
        pause
        exit /b 1
    )
)

REM 创建测试所需文件夹
if not exist sample_files mkdir sample_files
if not exist converted_files mkdir converted_files

echo 正在执行单向转换测试...
echo 这将测试从UTF-8到各种非Unicode编码的转换，以及从各种非Unicode编码到UTF-8的转换。
echo 结果将保存到 oneway_conversion_tests.md
echo.
conversion_roundtrip_test.exe oneway
echo.
echo 测试完成，结果已保存到 oneway_conversion_tests.md
echo.
pause
exit /b 0 