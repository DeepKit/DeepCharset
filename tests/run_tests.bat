@echo off
echo JCL扩展编码支持测试程序
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

:menu
cls
echo 选择测试模式:
echo [1] 单向转换测试 (从UTF-8到其他编码，从其他编码到UTF-8)
echo [2] 往返转换测试 (编码A → UTF → 编码A)
echo [3] 编译测试程序
echo [4] 退出
echo.
set /p choice=请输入选项编号:

if "%choice%"=="1" goto oneway
if "%choice%"=="2" goto roundtrip
if "%choice%"=="3" goto compile
if "%choice%"=="4" goto end

echo 无效选项，请重新选择
pause
goto menu

:oneway
echo.
echo 正在执行单向转换测试...
conversion_roundtrip_test.exe oneway
echo.
echo 测试完成，结果已保存到 oneway_conversion_tests.md
echo.
pause
goto menu

:roundtrip
echo.
echo 正在执行往返转换测试...
conversion_roundtrip_test.exe roundtrip
echo.
echo 测试完成，结果已保存到 roundtrip_tests.md
echo.
pause
goto menu

:compile
echo.
echo 正在重新编译测试程序...
dcc32 -b conversion_roundtrip_test.dpr
if errorlevel 1 (
    echo 编译失败! 请检查Delphi和JCL环境。
) else (
    echo 编译成功!
)
pause
goto menu

:end
echo 感谢使用JCL扩展编码支持测试程序
exit /b 0 