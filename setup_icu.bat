@echo off
setlocal

echo TransSuccess ICU库安装脚本
echo =========================
echo.

:: 设置ICU库版本和文件名
set ICU_VERSION=77
set ICUUC_DLL=icuuc%ICU_VERSION%.dll
set ICUIN_DLL=icuin%ICU_VERSION%.dll
set ICUDT_DLL=icudt%ICU_VERSION%.dll

:: 检查是否已存在ICU库文件
if exist "%ICUUC_DLL%" (
    echo 检测到已存在ICU库文件，请先删除旧文件后再安装。
    echo 现有文件: %ICUUC_DLL%
    goto :EOF
)

echo 正在下载ICU库文件...
echo.

:: 创建临时目录
mkdir temp_icu_download 2>nul
cd temp_icu_download

:: 设置下载链接（GitHub或官方源）
set DOWNLOAD_BASE=https://github.com/unicode-org/icu/releases/download/release-77-1

:: 使用PowerShell执行下载
powershell -Command "& {Invoke-WebRequest -Uri '%DOWNLOAD_BASE%/%ICUUC_DLL%' -OutFile '%ICUUC_DLL%'}"
if %ERRORLEVEL% neq 0 (
    echo 下载 %ICUUC_DLL% 失败！
    goto :cleanup
)

powershell -Command "& {Invoke-WebRequest -Uri '%DOWNLOAD_BASE%/%ICUIN_DLL%' -OutFile '%ICUIN_DLL%'}"
if %ERRORLEVEL% neq 0 (
    echo 下载 %ICUIN_DLL% 失败！
    goto :cleanup
)

powershell -Command "& {Invoke-WebRequest -Uri '%DOWNLOAD_BASE%/%ICUDT_DLL%' -OutFile '%ICUDT_DLL%'}"
if %ERRORLEVEL% neq 0 (
    echo 下载 %ICUDT_DLL% 失败！
    goto :cleanup
)

echo 下载完成！正在复制到项目根目录...

:: 复制文件到项目根目录
copy %ICUUC_DLL% ..\ >nul
copy %ICUIN_DLL% ..\ >nul  
copy %ICUDT_DLL% ..\ >nul

:: 检查是否复制成功
if exist "..\%ICUUC_DLL%" if exist "..\%ICUIN_DLL%" if exist "..\%ICUDT_DLL%" (
    echo.
    echo ICU库文件已成功安装到项目根目录！
    echo 现在可以运行TransSuccess程序了。
) else (
    echo.
    echo 警告：某些文件未能成功复制，请手动检查。
)

:cleanup
:: 清理临时文件
cd ..
rmdir /s /q temp_icu_download

endlocal 