# 创建必要的目录
$backupDir = ".\backup"
$deprecatedDir = "$backupDir\deprecated"
$testsDir = "$backupDir\tests"
$encodingDir = "$backupDir\encoding"
$resourcesDir = "$backupDir\resources"
$utilsDir = "$backupDir\utils"
$docsDir = "$backupDir\docs"
$dprDir = "$backupDir\dpr"

# 确保目录存在
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir }
if (-not (Test-Path $deprecatedDir)) { New-Item -ItemType Directory -Path $deprecatedDir }
if (-not (Test-Path $testsDir)) { New-Item -ItemType Directory -Path $testsDir }
if (-not (Test-Path $encodingDir)) { New-Item -ItemType Directory -Path $encodingDir }
if (-not (Test-Path $resourcesDir)) { New-Item -ItemType Directory -Path $resourcesDir }
if (-not (Test-Path $utilsDir)) { New-Item -ItemType Directory -Path $utilsDir }
if (-not (Test-Path $docsDir)) { New-Item -ItemType Directory -Path $docsDir }
if (-not (Test-Path $dprDir)) { New-Item -ItemType Directory -Path $dprDir }

# 1. 移动测试相关文件
Write-Host "移动测试相关文件..." -ForegroundColor Green

# 移动测试相关的.dpr文件
$testDprFiles = @(
    "AutoConverter.dpr",
    "BatchTest.dpr",
    "CheckDLL.dpr",
    "FileEncodingTool.dpr",
    "FullTest.dpr",
    "GenerateTestFiles.dpr",
    "IconvTest.dpr",
    "ICUTest.dpr",
    "MinTest.dpr",
    "SimpleConverter.dpr",
    "SimpleEncodingTest.dpr",
    "SimpleTest.dpr",
    "SpecialCharValidatorDemo.dpr",
    "SimpleBOMTest.dpr"
)

foreach ($file in $testDprFiles) {
    if (Test-Path $file) {
        Move-Item -Path $file -Destination "$dprDir\$file" -Force
        Write-Host "已移动: $file -> $dprDir\$file" -ForegroundColor Yellow
    }
}

# 2. 移动测试相关的.pas文件
Write-Host "移动测试相关的.pas文件..." -ForegroundColor Green

$testPasFiles = @(
    "BenchmarkRunner.pas",
    "EncodingBenchmark.pas",
    "EncodingCLI.pas",
    "EncodingCommandLine.pas",
    "EncodingCommandLineOptions.pas",
    "EncodingCommandLineSmartDetection.pas",
    "EncodingLogViewer.pas",
    "EncodingTest.pas",
    "FileMonitor.pas",
    "FileOperationManager.pas",
    "FixCompileErrors.pas",
    "FixedFile.pas",
    "FormBatchConversion.pas",
    "FormBatchEncodingManager.pas",
    "FormEncodingConversionExample.pas",
    "FormEncodingProfileManager.pas",
    "FormEncodingScheduler.pas",
    "SimpleUTF8Test.pas",
    "SimpleView.pas",
    "ViewAdvancedConvert.pas"
)

foreach ($file in $testPasFiles) {
    if (Test-Path $file) {
        Move-Item -Path $file -Destination "$testsDir\$file" -Force
        Write-Host "已移动: $file -> $testsDir\$file" -ForegroundColor Yellow
    }
}

# 3. 移动编码检测和转换相关的文件
Write-Host "移动编码检测和转换相关的文件..." -ForegroundColor Green

$encodingFiles = @(
    "HZGBEncoding.pas",
    "ImprovedBig5Detection.pas",
    "ImprovedGBKConfidenceScoring.pas",
    "ImprovedGBKDetection.pas",
    "IsValidUTF8SequenceImproved.pas",
    "RemoveBOM.pas"
)

foreach ($file in $encodingFiles) {
    if (Test-Path $file) {
        Move-Item -Path $file -Destination "$encodingDir\$file" -Force
        Write-Host "已移动: $file -> $encodingDir\$file" -ForegroundColor Yellow
    }
}

# 4. 移动JCL相关的文件
Write-Host "移动JCL相关的文件..." -ForegroundColor Green

$jclFiles = @(
    "JclAnsiStrings.pas",
    "JclSysInfo.pas",
    "JclSysUtils.pas",
    "JclUnicode.pas"
)

foreach ($file in $jclFiles) {
    if (Test-Path $file) {
        Move-Item -Path $file -Destination "$deprecatedDir\$file" -Force
        Write-Host "已移动: $file -> $deprecatedDir\$file" -ForegroundColor Yellow
    }
}

# 5. 移动Python脚本
Write-Host "移动Python脚本..." -ForegroundColor Green

$pythonFiles = @(
    "detect_encoding.py",
    "generate_test_files.py"
)

foreach ($file in $pythonFiles) {
    if (Test-Path $file) {
        Move-Item -Path $file -Destination "$testsDir\$file" -Force
        Write-Host "已移动: $file -> $testsDir\$file" -ForegroundColor Yellow
    }
}

# 6. 移动测试结果文件
Write-Host "移动测试结果文件..." -ForegroundColor Green

$resultFiles = @(
    "BatchConversionTest_Results.txt",
    "controller_log.txt",
    "convert_log.txt",
    "test_gb2312.txt"
)

foreach ($file in $resultFiles) {
    if (Test-Path $file) {
        Move-Item -Path $file -Destination "$testsDir\$file" -Force
        Write-Host "已移动: $file -> $testsDir\$file" -ForegroundColor Yellow
    }
}

# 7. 移动可执行文件
Write-Host "移动可执行文件..." -ForegroundColor Green

$exeFiles = @(
    "EncodingDetectTest.exe",
    "ImprovedEncodingConvert.exe",
    "ImprovedEncodingDetect.exe",
    "SimpleBOMTest.exe",
    "TestUTF8BOM.exe",
    "TestUTF8BOMConverter.exe",
    "test_encoding.exe"
)

foreach ($file in $exeFiles) {
    if (Test-Path $file) {
        Move-Item -Path $file -Destination "$testsDir\$file" -Force
        Write-Host "已移动: $file -> $testsDir\$file" -ForegroundColor Yellow
    }
}

# 8. 移动项目文件
Write-Host "移动项目文件..." -ForegroundColor Green

$projFiles = @(
    "ImprovedEncodingConvert.dproj",
    "ImprovedEncodingDetect.dproj"
)

foreach ($file in $projFiles) {
    if (Test-Path $file) {
        Move-Item -Path $file -Destination "$dprDir\$file" -Force
        Write-Host "已移动: $file -> $dprDir\$file" -ForegroundColor Yellow
    }
}

# 9. 移动HTML文件
Write-Host "移动HTML文件..." -ForegroundColor Green

$htmlFiles = @(
    "HelpSmartEncodingDetector.html"
)

foreach ($file in $htmlFiles) {
    if (Test-Path $file) {
        Move-Item -Path $file -Destination "$docsDir\$file" -Force
        Write-Host "已移动: $file -> $docsDir\$file" -ForegroundColor Yellow
    }
}

# 10. 移动DCU文件
Write-Host "移动DCU文件..." -ForegroundColor Green

Get-ChildItem -Path "." -Filter "*.dcu" | ForEach-Object {
    Move-Item -Path $_.FullName -Destination "$backupDir\$($_.Name)" -Force
    Write-Host "已移动: $($_.Name) -> $backupDir\$($_.Name)" -ForegroundColor Yellow
}

Write-Host "文件整理完成!" -ForegroundColor Green
