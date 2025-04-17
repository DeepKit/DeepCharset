Write-Host "开始下载libiconv.dll文件..."

# 设置下载地址 - libiconv.dll通常在MSYS2/MinGW或GnuWin32项目中提供
$downloadUrl = "https://github.com/mlocati/gettext-iconv-windows/releases/download/v0.21-v1.16/gettext0.21-iconv1.16-shared-32.zip"
$zipFile = ".\lib\bin\iconv.zip"
$extractPath = ".\lib\bin\"

# 创建目录
if (-not (Test-Path $extractPath)) {
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
}

# 下载文件
Write-Host "正在下载 $downloadUrl ..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile

# 解压文件
Write-Host "正在解压文件..."
Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force

# 复制所需的DLL文件到bin目录
Write-Host "正在复制DLL文件..."
Get-ChildItem -Path "$extractPath\bin" -Filter "*.dll" | ForEach-Object {
    Copy-Item $_.FullName -Destination $extractPath
}

# 清理临时文件
Write-Host "清理临时文件..."
Remove-Item -Path $zipFile -Force
Remove-Item -Path "$extractPath\bin" -Recurse -Force
Remove-Item -Path "$extractPath\include" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$extractPath\lib" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$extractPath\share" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "完成！DLL文件已下载到 $extractPath" 