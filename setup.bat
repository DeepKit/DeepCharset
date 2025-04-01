@echo off
echo 正在设置TransSuccess应用程序...

REM 检查libiconv-2.dll是否存在
if exist "libiconv-2.dll" (
    echo 找到libiconv-2.dll，正在复制...
    copy /Y "libiconv-2.dll" "%~dp0"
    if errorlevel 1 (
        echo 复制libiconv-2.dll失败！
        pause
        exit /b 1
    )
    echo libiconv-2.dll复制成功！
) else (
    echo 错误：未找到libiconv-2.dll！
    echo 请确保libiconv-2.dll文件存在于当前目录中。
    pause
    exit /b 1
)

echo 设置完成！
pause 