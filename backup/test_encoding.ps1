# 创建测试目录
$testDir = ".\test_files"
if (-not (Test-Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory
}

# 测试文本
$utf8Text = "UTF-8测试文本 - 这是中文和English混合"
$gb2312Text = "GB2312测试文本 - 这是中文和English混合"

# 创建UTF-8文件(无BOM)
$utf8NoBomPath = "$testDir\utf8_nobom.txt"
[System.IO.File]::WriteAllText($utf8NoBomPath, $utf8Text, [System.Text.Encoding]::UTF8)

# 创建UTF-8文件(带BOM)
$utf8BomPath = "$testDir\utf8_bom.txt"
$utf8Encoding = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($utf8BomPath, $utf8Text, $utf8Encoding)

# 创建GB2312文件
$gb2312Path = "$testDir\gb2312.txt"
$gb2312Encoding = [System.Text.Encoding]::GetEncoding(936)
[System.IO.File]::WriteAllText($gb2312Path, $gb2312Text, $gb2312Encoding)

# 创建ANSI文件
$ansiPath = "$testDir\ansi.txt"
[System.IO.File]::WriteAllText($ansiPath, "ANSI text file - 这是ANSI编码", [System.Text.Encoding]::Default)

# 输出创建的文件
Write-Host "Created test files:"
Write-Host "- UTF-8 (No BOM): $utf8NoBomPath"
Write-Host "- UTF-8 (BOM): $utf8BomPath"
Write-Host "- GB2312: $gb2312Path"
Write-Host "- ANSI: $ansiPath"

# 创建二进制测试文件
$binPath = "$testDir\binary.bin"
$bytes = [byte[]]::new(100)
for ($i = 0; $i -lt 100; $i++) {
    $bytes[$i] = $i -band 0xFF
}
[System.IO.File]::WriteAllBytes($binPath, $bytes)
Write-Host "- Binary: $binPath" 