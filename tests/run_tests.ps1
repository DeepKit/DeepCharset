# PowerShell脚本：运行JCL编码检测和转换测试

Write-Host "开始运行JCL编码检测和转换测试..." -ForegroundColor Green

# 确保to目录存在
if (-not (Test-Path -Path "to")) {
    New-Item -ItemType Directory -Path "to"
}

# 编译并运行编码检测测试
Write-Host "编译并运行编码检测测试程序..." -ForegroundColor Yellow
& dcc32 -b sample_test.dpr
if ($LASTEXITCODE -ne 0) {
    Write-Host "编译编码检测测试程序失败" -ForegroundColor Red
    Read-Host "按Enter键退出"
    exit 1
}

Write-Host "运行编码检测测试..." -ForegroundColor Yellow
& .\sample_test.exe
if ($LASTEXITCODE -ne 0) {
    Write-Host "运行编码检测测试失败" -ForegroundColor Red
    Read-Host "按Enter键退出"
    exit 1
}

# 编译并运行编码转换测试
Write-Host "编译并运行编码转换测试程序..." -ForegroundColor Yellow
& dcc32 -b conversion_test.dpr
if ($LASTEXITCODE -ne 0) {
    Write-Host "编译编码转换测试程序失败" -ForegroundColor Red
    Read-Host "按Enter键退出"
    exit 1
}

Write-Host "运行编码转换测试..." -ForegroundColor Yellow
& .\conversion_test.exe
if ($LASTEXITCODE -ne 0) {
    Write-Host "运行编码转换测试失败" -ForegroundColor Red
    Read-Host "按Enter键退出"
    exit 1
}

Write-Host "所有测试已完成，测试结果已保存到tests.md文件中。" -ForegroundColor Green
Write-Host "按Enter键查看测试结果..." -ForegroundColor Green
Read-Host

# 打开测试结果文件
Invoke-Item tests.md 