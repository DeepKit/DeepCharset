@echo off
echo TransSuccess ICU 库设置脚本
echo ===========================
echo.

set ICU_VERSION=77
set ICU_DOWNLOAD_URL=https://github.com/unicode-org/icu/releases/download/release-77-1

echo 开始下载ICU库文件 (版本 %ICU_VERSION%)...
echo 下载路径: %ICU_DOWNLOAD_URL%
echo.

:: 创建临时下载目录
if not exist "download" mkdir download

:: 下载ICU动态库
curl -L "%ICU_DOWNLOAD_URL%/icu4c-77_1-Win32-MSVC2019.zip" -o "download\icu-win32.zip"
curl -L "%ICU_DOWNLOAD_URL%/icu4c-77_1-Win64-MSVC2019.zip" -o "download\icu-win64.zip"

echo 下载完成，开始解压...

:: 解压文件
if exist "download\icu-win32.zip" (
  powershell -Command "Expand-Archive -Path 'download\icu-win32.zip' -DestinationPath 'download\icu-win32' -Force"
)

if exist "download\icu-win64.zip" (
  powershell -Command "Expand-Archive -Path 'download\icu-win64.zip' -DestinationPath 'download\icu-win64' -Force"
)

echo 解压完成，复制必要的DLL文件...

:: 复制32位DLL到项目目录
if exist "download\icu-win32\bin\icuuc77.dll" (
  copy "download\icu-win32\bin\icuuc77.dll" .
  copy "download\icu-win32\bin\icuin77.dll" .
  copy "download\icu-win32\bin\icudt77.dll" .
)

:: 复制64位DLL到Win64目录
if not exist "Win64" mkdir Win64
if exist "download\icu-win64\bin\icuuc77.dll" (
  copy "download\icu-win64\bin\icuuc77.dll" Win64\
  copy "download\icu-win64\bin\icuin77.dll" Win64\
  copy "download\icu-win64\bin\icudt77.dll" Win64\
)

echo.
echo 设置完成！
echo.
echo ICU库文件已安装，您现在可以使用TransSuccess编码转换功能了。
echo.
echo 注：请确保程序能找到这些DLL文件。如果运行时报错，请将DLL复制到系统路径或程序运行目录。
echo.
pause 