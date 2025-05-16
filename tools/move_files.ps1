# 创建必要的目录
$backupDir = ".\backup"
$deprecatedDir = "$backupDir\deprecated"
$testsDir = "$backupDir\tests"
$encodingDir = "$backupDir\encoding"
$resourcesDir = "$backupDir\resources"
$utilsDir = "$backupDir\utils"
$docsDir = "$backupDir\docs"

# 确保目录存在
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir }
if (-not (Test-Path $deprecatedDir)) { New-Item -ItemType Directory -Path $deprecatedDir }
if (-not (Test-Path $testsDir)) { New-Item -ItemType Directory -Path $testsDir }
if (-not (Test-Path $encodingDir)) { New-Item -ItemType Directory -Path $encodingDir }
if (-not (Test-Path $resourcesDir)) { New-Item -ItemType Directory -Path $resourcesDir }
if (-not (Test-Path $utilsDir)) { New-Item -ItemType Directory -Path $utilsDir }
if (-not (Test-Path $docsDir)) { New-Item -ItemType Directory -Path $docsDir }

# 1. 移动测试相关文件
Write-Host "移动测试相关文件..." -ForegroundColor Green

# 移动Test开头的文件
Get-ChildItem -Path "." -Filter "Test*.dpr" | ForEach-Object {
    if ($_.Name -ne "TestUTF8BOMConverter.dpr") {
        Move-Item -Path $_.FullName -Destination "$testsDir\$($_.Name)" -Force
        Write-Host "已移动: $($_.Name) -> $testsDir\$($_.Name)" -ForegroundColor Yellow
    }
}

Get-ChildItem -Path "." -Filter "Test*.pas" | ForEach-Object {
    if ($_.Name -ne "TestUTF8BOMConverter.pas") {
        Move-Item -Path $_.FullName -Destination "$testsDir\$($_.Name)" -Force
        Write-Host "已移动: $($_.Name) -> $testsDir\$($_.Name)" -ForegroundColor Yellow
    }
}

# 移动test_开头的文件
Get-ChildItem -Path "." -Filter "test_*.dpr" | ForEach-Object {
    Move-Item -Path $_.FullName -Destination "$testsDir\$($_.Name)" -Force
    Write-Host "已移动: $($_.Name) -> $testsDir\$($_.Name)" -ForegroundColor Yellow
}

Get-ChildItem -Path "." -Filter "test_*.md" | ForEach-Object {
    if ($_.Name -ne "test_progress.md") {
        Move-Item -Path $_.FullName -Destination "$docsDir\$($_.Name)" -Force
        Write-Host "已移动: $($_.Name) -> $docsDir\$($_.Name)" -ForegroundColor Yellow
    }
}

# 移动其他测试文件
$testFiles = @(
    "BasicTest.dpr", "BasicTest.dproj", "BasicTest.identcache", "BasicTest.res",
    "BatchConversionTest.dpr", "BatchConversionTest.dproj",
    "EncodingTestRunner.dproj", "EncodingTestRunner.exe",
    "simple_encoding_test.dpr", "simple_test.dpr", "simple_test.exe", "simple_test.rc", "simple_test.RES",
    "minimal_test.dpr", "tiny_test.dpr", "var_test.dpr",
    "encoding_report.dpr", "encoding_report.exe", "encoding_report.rc", "encoding_report.RES",
    "test_report.dpr", "test_report.rc", "test_report.RES",
    "encoding_test.dpr", "basic_encoding_test.dpr"
)

foreach ($file in $testFiles) {
    if (Test-Path $file) {
        Move-Item -Path $file -Destination "$testsDir\$file" -Force
        Write-Host "已移动: $file -> $testsDir\$file" -ForegroundColor Yellow
    }
}

# 2. 移动编码检测和转换相关的重复或过时文件
Write-Host "移动编码检测和转换相关的重复或过时文件..." -ForegroundColor Green

# 移动GBK和Big5开头的文件
Get-ChildItem -Path "." -Filter "GBK*.pas" | ForEach-Object {
    Move-Item -Path $_.FullName -Destination "$encodingDir\$($_.Name)" -Force
    Write-Host "已移动: $($_.Name) -> $encodingDir\$($_.Name)" -ForegroundColor Yellow
}

Get-ChildItem -Path "." -Filter "Big5*.pas" | ForEach-Object {
    Move-Item -Path $_.FullName -Destination "$encodingDir\$($_.Name)" -Force
    Write-Host "已移动: $($_.Name) -> $encodingDir\$($_.Name)" -ForegroundColor Yellow
}

# 移动GB_开头的文件
Get-ChildItem -Path "." -Filter "GB_*.pas" | ForEach-Object {
    Move-Item -Path $_.FullName -Destination "$encodingDir\$($_.Name)" -Force
    Write-Host "已移动: $($_.Name) -> $encodingDir\$($_.Name)" -ForegroundColor Yellow
}

# 移动ImprovedEncoding开头的文件
Get-ChildItem -Path "." -Filter "ImprovedEncoding*.pas" | ForEach-Object {
    Move-Item -Path $_.FullName -Destination "$encodingDir\$($_.Name)" -Force
    Write-Host "已移动: $($_.Name) -> $encodingDir\$($_.Name)" -ForegroundColor Yellow
}

# 移动Encoding开头的.dpr文件
Get-ChildItem -Path "." -Filter "Encoding*.dpr" | ForEach-Object {
    Move-Item -Path $_.FullName -Destination "$testsDir\$($_.Name)" -Force
    Write-Host "已移动: $($_.Name) -> $testsDir\$($_.Name)" -ForegroundColor Yellow
}

# 3. 移动工具和辅助文件
Write-Host "移动工具和辅助文件..." -ForegroundColor Green

# 移动.md文件
Get-ChildItem -Path "." -Filter "*.md" | ForEach-Object {
    if ($_.Name -notin @("README.md", "improve.md", "better.md", "better_progress.md", "test_progress.md")) {
        Move-Item -Path $_.FullName -Destination "$docsDir\$($_.Name)" -Force
        Write-Host "已移动: $($_.Name) -> $docsDir\$($_.Name)" -ForegroundColor Yellow
    }
}

# 移动.bat和.ps1文件
Get-ChildItem -Path "." -Filter "*.bat" | ForEach-Object {
    if ($_.Name -ne "build.bat") {
        Move-Item -Path $_.FullName -Destination "$backupDir\$($_.Name)" -Force
        Write-Host "已移动: $($_.Name) -> $backupDir\$($_.Name)" -ForegroundColor Yellow
    }
}

Get-ChildItem -Path "." -Filter "*.ps1" | ForEach-Object {
    if ($_.Name -ne "move_files.ps1") {
        Move-Item -Path $_.FullName -Destination "$backupDir\$($_.Name)" -Force
        Write-Host "已移动: $($_.Name) -> $backupDir\$($_.Name)" -ForegroundColor Yellow
    }
}

# 移动不需要的.dfm文件
Get-ChildItem -Path "." -Filter "*.dfm" | ForEach-Object {
    if ($_.Name -notin @("ViewMainCode.dfm", "ViewSynEdit.dfm", "ViewMemo.dfm")) {
        Move-Item -Path $_.FullName -Destination "$deprecatedDir\$($_.Name)" -Force
        Write-Host "已移动: $($_.Name) -> $deprecatedDir\$($_.Name)" -ForegroundColor Yellow
    }
}

# 4. 整理Utils前缀文件
Write-Host "整理Utils前缀文件..." -ForegroundColor Green

$coreUtilsFiles = @(
    "UtilsTypes.pas",
    "UtilsEncodingTypes.pas",
    "UtilsEncodingLogger.pas",
    "UtilsEncodingMemory.pas",
    "UtilsEncodingBOM_Simple.pas",
    "UtilsEncodingConstants.pas"
)

Get-ChildItem -Path "." -Filter "Utils*.pas" | ForEach-Object {
    if ($_.Name -notin $coreUtilsFiles) {
        Move-Item -Path $_.FullName -Destination "$utilsDir\$($_.Name)" -Force
        Write-Host "已移动: $($_.Name) -> $utilsDir\$($_.Name)" -ForegroundColor Yellow
    }
}

# 5. 整理重复的编码检测和转换实现
Write-Host "整理重复的编码检测和转换实现..." -ForegroundColor Green

$coreEncodingFiles = @(
    "UTF8BOMConverter.pas",
    "UTF8BOMConverter_Simple.pas"
)

Get-ChildItem -Path "." -Filter "*Converter*.pas" | ForEach-Object {
    if ($_.Name -notin $coreEncodingFiles) {
        Move-Item -Path $_.FullName -Destination "$deprecatedDir\$($_.Name)" -Force
        Write-Host "已移动: $($_.Name) -> $deprecatedDir\$($_.Name)" -ForegroundColor Yellow
    }
}

Get-ChildItem -Path "." -Filter "*Detector*.pas" | ForEach-Object {
    Move-Item -Path $_.FullName -Destination "$deprecatedDir\$($_.Name)" -Force
    Write-Host "已移动: $($_.Name) -> $deprecatedDir\$($_.Name)" -ForegroundColor Yellow
}

# 6. 移动备份文件和临时文件
Write-Host "移动备份文件和临时文件..." -ForegroundColor Green

Get-ChildItem -Path "." -Filter "*.bak" | ForEach-Object {
    Move-Item -Path $_.FullName -Destination "$backupDir\$($_.Name)" -Force
    Write-Host "已移动: $($_.Name) -> $backupDir\$($_.Name)" -ForegroundColor Yellow
}

Get-ChildItem -Path "." -Filter "*.orig" | ForEach-Object {
    Move-Item -Path $_.FullName -Destination "$backupDir\$($_.Name)" -Force
    Write-Host "已移动: $($_.Name) -> $backupDir\$($_.Name)" -ForegroundColor Yellow
}

Get-ChildItem -Path "." -Filter "*.identcache" | ForEach-Object {
    Move-Item -Path $_.FullName -Destination "$backupDir\$($_.Name)" -Force
    Write-Host "已移动: $($_.Name) -> $backupDir\$($_.Name)" -ForegroundColor Yellow
}

# 7. 整理图标和资源文件
Write-Host "整理图标和资源文件..." -ForegroundColor Green

$coreResourceFiles = @(
    "TransSuccess_Icon.ico",
    "TransSuccess.res"
)

Get-ChildItem -Path "." -Filter "*.ico" | ForEach-Object {
    if ($_.Name -notin $coreResourceFiles) {
        Move-Item -Path $_.FullName -Destination "$resourcesDir\$($_.Name)" -Force
        Write-Host "已移动: $($_.Name) -> $resourcesDir\$($_.Name)" -ForegroundColor Yellow
    }
}

Get-ChildItem -Path "." -Filter "*.png" | ForEach-Object {
    Move-Item -Path $_.FullName -Destination "$resourcesDir\$($_.Name)" -Force
    Write-Host "已移动: $($_.Name) -> $resourcesDir\$($_.Name)" -ForegroundColor Yellow
}

Get-ChildItem -Path "." -Filter "*.res" | ForEach-Object {
    if ($_.Name -ne "TransSuccess.res") {
        Move-Item -Path $_.FullName -Destination "$resourcesDir\$($_.Name)" -Force
        Write-Host "已移动: $($_.Name) -> $resourcesDir\$($_.Name)" -ForegroundColor Yellow
    }
}

Write-Host "文件整理完成!" -ForegroundColor Green
