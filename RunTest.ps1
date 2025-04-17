# 设置超时时间（毫秒）
$timeout = 5000

# 开始进程
$process = Start-Process -FilePath ".\TestIconv.exe" -NoNewWindow -PassThru -RedirectStandardOutput "test_output.log"

# 等待指定时间
Write-Host "等待程序运行，超时时间：$timeout 毫秒..."
if (-not $process.WaitForExit($timeout)) {
    Write-Host "程序运行超时，强制终止..."
    $process.Kill()
}

# 显示输出文件内容
Write-Host "`n----------- 测试日志输出 -----------"
Get-Content -Path "test_output.log" | ForEach-Object { Write-Host $_ }
Write-Host "----------- 测试日志结束 -----------`n"

# 返回进程退出代码
Write-Host "程序退出代码: $($process.ExitCode)"

# 检查测试文件
Write-Host "`n----------- 测试文件列表 -----------"
Get-ChildItem -Path ".\test_files" | Select-Object Name, Length | Format-Table
Write-Host "----------- 文件列表结束 -----------" 