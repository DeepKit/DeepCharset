@echo off
echo 正在运行 TransSuccess 单元测试...
echo.

REM 编译测试项目
echo 编译测试项目...
dcc32 -cc TestTransSuccess.dpr
if %ERRORLEVEL% NEQ 0 (
  echo 编译失败，错误代码: %ERRORLEVEL%
  pause
  exit /b %ERRORLEVEL%
)

REM 运行测试
echo.
echo 运行测试...
TestTransSuccess.exe
set TEST_RESULT=%ERRORLEVEL%

echo.
if %TEST_RESULT% EQU 0 (
  echo 所有测试通过！
) else (
  echo 测试失败，错误代码: %TEST_RESULT%
)

pause
