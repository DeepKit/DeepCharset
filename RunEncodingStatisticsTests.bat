@echo off
echo 运行编码统计分析测试...
cd /d %~dp0
dcc32 -cc TestEncodingStatistics.pas
if errorlevel 1 (
  echo 编译错误！
  pause
  exit /b 1
)

echo 开始测试...
TestEncodingStatistics.exe
if errorlevel 1 (
  echo 测试失败！
  pause
  exit /b 1
)

echo 测试成功完成！
pause 