function DownloadFile {
    param (
        [string]$url,
        [string]$outputFile
    )
    
    Write-Host "正在下载: $url 到 $outputFile"
    
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($url, $outputFile)
        Write-Host "下载完成: $outputFile"
        return $true
    }
    catch {
        Write-Host "下载失败: $_"
        return $false
    }
}

# 创建libs目录(如果不存在)
$libsDir = Join-Path $PSScriptRoot "libs"
if (-not (Test-Path $libsDir)) {
    New-Item -ItemType Directory -Path $libsDir | Out-Null
    Write-Host "创建目录: $libsDir"
}

# 下载32位libiconv库文件
$libiconv32Url = "https://github.com/win-iconv/win-iconv/releases/download/v0.0.8/win-iconv-0.0.8-x86.zip"
$libiconv32ZipPath = Join-Path $libsDir "libiconv-x86.zip"
$libiconv32Success = DownloadFile $libiconv32Url $libiconv32ZipPath

# 下载64位libiconv库文件
$libiconv64Url = "https://github.com/win-iconv/win-iconv/releases/download/v0.0.8/win-iconv-0.0.8-x64.zip"
$libiconv64ZipPath = Join-Path $libsDir "libiconv-x64.zip"
$libiconv64Success = DownloadFile $libiconv64Url $libiconv64ZipPath

# 解压文件
if ($libiconv32Success -or $libiconv64Success) {
    Write-Host "正在解压文件..."
    
    if ($libiconv32Success) {
        Expand-Archive -Path $libiconv32ZipPath -DestinationPath $libsDir -Force
        # 重命名DLL
        $dllPath = Join-Path $libsDir "win-iconv-0.0.8-x86\bin\iconv.dll"
        if (Test-Path $dllPath) {
            Copy-Item $dllPath -Destination (Join-Path $libsDir "libiconv-2.dll") -Force
            Write-Host "已创建: libiconv-2.dll (32位)"
        }
    }
    
    if ($libiconv64Success) {
        Expand-Archive -Path $libiconv64ZipPath -DestinationPath $libsDir -Force
        # 重命名DLL
        $dllPath = Join-Path $libsDir "win-iconv-0.0.8-x64\bin\iconv.dll"
        if (Test-Path $dllPath) {
            Copy-Item $dllPath -Destination (Join-Path $libsDir "libiconv-x64.dll") -Force
            Write-Host "已创建: libiconv-x64.dll (64位)"
        }
    }
    
    # 复制到主目录
    Write-Host "正在复制DLL文件到主目录..."
    $mainDir = $PSScriptRoot
    
    if (Test-Path (Join-Path $libsDir "libiconv-2.dll")) {
        Copy-Item (Join-Path $libsDir "libiconv-2.dll") -Destination $mainDir -Force
        Write-Host "已复制: libiconv-2.dll 到主目录"
    }
    
    if (Test-Path (Join-Path $libsDir "libiconv-x64.dll")) {
        Copy-Item (Join-Path $libsDir "libiconv-x64.dll") -Destination $mainDir -Force
        Write-Host "已复制: libiconv-x64.dll 到主目录"
    }
    
    Write-Host "安装完成!"
}
else {
    Write-Host "所有下载均失败，请手动下载libiconv库文件。"
}

# 等待用户按任意键
Write-Host "按任意键退出..."
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 