@echo off
echo 正在编译TransSuccess项目...

rem 设置Delphi环境变量
set BDS=C:\Program Files (x86)\Embarcadero\Studio\23.0
set BDSINCLUDE=%BDS%\include
set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\23.0
set FrameworkDir=C:\Windows\Microsoft.NET\Framework\v4.0.30319
set FrameworkVersion=v4.0.30319
set FrameworkSDKDir=
set PATH=%FrameworkDir%;%FrameworkSDKDir%;%BDS%\bin;%BDS%\bin64;%PATH%

rem 清理旧的编译文件
if exist *.dcu del *.dcu
if exist *.exe del *.exe
if exist *.~* del *.~*

rem 编译项目
dcc32 -B TransSuccess.dpr

if errorlevel 1 (
  echo 编译失败！
  exit /b 1
) else (
  echo 编译成功！
  exit /b 0
)
