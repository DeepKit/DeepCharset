@echo off
setlocal enabledelayedexpansion

echo 编码检测和转换测试套件
echo ====================
echo.

cd /d "%~dp0"

rem 运行编码测试
echo 正在运行编码测试...
call run_encoding_tests.bat

echo.
echo 所有测试完成!
echo.
echo 按任意键退出...
pause >nul

exit /b 0
