# DeepCharset Test Data Generation Script
# Purpose: Generate comprehensive test files for encoding detection and conversion testing
# Date: 2025-11-13

param(
    [string]$OutputPath = "D:\SynologyDrive\Progs\_Delphi\DeepCharset\test_data",
    [switch]$Force
)

# Create output directory structure
function New-TestDirectory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "Created directory: $Path" -ForegroundColor Green
    }
}

# Generate test content
function Get-TestContent {
    param(
        [string]$Type = "mixed",
        [int]$Multiplier = 1
    )
    
    $base = "Hello World! 你好世界 مرحبا بالعالم Привет мир こんにちは世界 안녕하세요`n"
    $base += "The quick brown fox jumps over the lazy dog 123456789 !@#`$%^&*()_+-=[]{}|;:',.<>?/`n"
    $base += "Special chars: © ® ™ € £ ¥ § ¶ † ‡ • … ‰ ′ ″ ‴`n"
    $base += "ASCII line 1: ABCDEFGHIJKLMNOPQRSTUVWXYZ`n"
    $base += "ASCII line 2: abcdefghijklmnopqrstuvwxyz`n"
    $base += "Numbers: 0123456789`n"
    $base += "Punctuation: . , ; : ! ? ( ) [ ] { } / \ | - _ = + * & % $ # @ ~ ` ^`n"
    
    $content = $base
    for ($i = 1; $i -lt $Multiplier; $i++) {
        $content += $base
    }
    
    return $content
}

# Create file with specific encoding
function New-EncodedFile {
    param(
        [string]$FilePath,
        [string]$Content,
        [string]$Encoding
    )
    
    try {
        $bytes = [System.Text.Encoding]::GetEncoding($Encoding).GetBytes($Content)
        [System.IO.File]::WriteAllBytes($FilePath, $bytes)
        Write-Host "Created: $FilePath ($(Get-Item $FilePath).Length) bytes" -ForegroundColor Cyan
    } catch {
        Write-Host "Error creating $FilePath with encoding $Encoding : $_" -ForegroundColor Red
    }
}

# Create file with BOM
function New-EncodedFileWithBOM {
    param(
        [string]$FilePath,
        [string]$Content,
        [System.Text.Encoding]$Encoding
    )
    
    try {
        [System.IO.File]::WriteAllText($FilePath, $Content, $Encoding)
        Write-Host "Created: $FilePath with BOM ($(Get-Item $FilePath).Length) bytes" -ForegroundColor Cyan
    } catch {
        Write-Host "Error creating $FilePath with encoding $($Encoding.EncodingName) : $_" -ForegroundColor Red
    }
}

# Main test data generation
Write-Host "`n====== DeepCharset Test Data Generation ======`n" -ForegroundColor Yellow

# Create directory structure
$dirs = @(
    "$OutputPath\encoding_detection\utf8_bom",
    "$OutputPath\encoding_detection\utf8_no_bom",
    "$OutputPath\encoding_detection\utf16le",
    "$OutputPath\encoding_detection\utf16be",
    "$OutputPath\encoding_detection\gbk",
    "$OutputPath\encoding_detection\gb2312",
    "$OutputPath\encoding_detection\shift_jis",
    "$OutputPath\encoding_detection\euc_jp",
    "$OutputPath\encoding_detection\euc_kr",
    "$OutputPath\encoding_detection\windows1252",
    "$OutputPath\encoding_detection\iso88591",
    "$OutputPath\conversion_tests\utf8_to_utf16",
    "$OutputPath\conversion_tests\gbk_to_utf8",
    "$OutputPath\conversion_tests\shift_jis_to_utf8",
    "$OutputPath\conversion_tests\euc_kr_to_utf8",
    "$OutputPath\edge_cases"
)

foreach ($dir in $dirs) {
    New-TestDirectory $dir
}

Write-Host "`nGenerating test files...`n" -ForegroundColor Yellow

# UTF-8 with BOM (small, medium, large)
$utf8Bom = [System.Text.UTF8Encoding]::new($true)
New-EncodedFileWithBOM "$OutputPath\encoding_detection\utf8_bom\small.txt" (Get-TestContent) $utf8Bom
New-EncodedFileWithBOM "$OutputPath\encoding_detection\utf8_bom\medium.txt" (Get-TestContent "mixed" 100) $utf8Bom
New-EncodedFileWithBOM "$OutputPath\encoding_detection\utf8_bom\large.txt" (Get-TestContent "mixed" 1000) $utf8Bom

# UTF-8 without BOM (small, medium, large)
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
New-EncodedFileWithBOM "$OutputPath\encoding_detection\utf8_no_bom\small.txt" (Get-TestContent) $utf8NoBom
New-EncodedFileWithBOM "$OutputPath\encoding_detection\utf8_no_bom\medium.txt" (Get-TestContent "mixed" 100) $utf8NoBom
New-EncodedFileWithBOM "$OutputPath\encoding_detection\utf8_no_bom\large.txt" (Get-TestContent "mixed" 1000) $utf8NoBom

# UTF-16LE with BOM (small, medium)
$utf16Le = [System.Text.UnicodeEncoding]::new($false, $true)
New-EncodedFileWithBOM "$OutputPath\encoding_detection\utf16le\small.txt" (Get-TestContent) $utf16Le
New-EncodedFileWithBOM "$OutputPath\encoding_detection\utf16le\medium.txt" (Get-TestContent "mixed" 100) $utf16Le

# UTF-16BE with BOM (small, medium)
$utf16Be = [System.Text.UnicodeEncoding]::new($true, $true)
New-EncodedFileWithBOM "$OutputPath\encoding_detection\utf16be\small.txt" (Get-TestContent) $utf16Be
New-EncodedFileWithBOM "$OutputPath\encoding_detection\utf16be\medium.txt" (Get-TestContent "mixed" 100) $utf16Be

# GBK encoding (Chinese)
$gbkContent = "你好世界!`nGB2312编码测试`n中文简体测试内容`nGBK encoding sample`n"
New-EncodedFile "$OutputPath\encoding_detection\gbk\small.txt" $gbkContent "gb2312"
New-EncodedFile "$OutputPath\encoding_detection\gbk\medium.txt" ($gbkContent * 100) "gb2312"
New-EncodedFile "$OutputPath\encoding_detection\gbk\large.txt" ($gbkContent * 1000) "gb2312"

# GB2312 encoding
New-EncodedFile "$OutputPath\encoding_detection\gb2312\small.txt" $gbkContent "gb2312"
New-EncodedFile "$OutputPath\encoding_detection\gb2312\medium.txt" ($gbkContent * 100) "gb2312"

# Shift_JIS encoding (Japanese)
$jpContent = "こんにちは世界!`nShift_JIS エンコーディングテスト`n日本語テスト内容`n"
New-EncodedFile "$OutputPath\encoding_detection\shift_jis\small.txt" $jpContent "shift_jis"
New-EncodedFile "$OutputPath\encoding_detection\shift_jis\medium.txt" ($jpContent * 100) "shift_jis"
New-EncodedFile "$OutputPath\encoding_detection\shift_jis\large.txt" ($jpContent * 1000) "shift_jis"

# EUC-JP encoding (Japanese)
New-EncodedFile "$OutputPath\encoding_detection\euc_jp\small.txt" $jpContent "euc-jp"
New-EncodedFile "$OutputPath\encoding_detection\euc_jp\medium.txt" ($jpContent * 100) "euc-jp"

# EUC-KR encoding (Korean)
$krContent = "안녕하세요 세계!`nEUC-KR 인코딩 테스트`n한국어 테스트 내용`n"
New-EncodedFile "$OutputPath\encoding_detection\euc_kr\small.txt" $krContent "euc-kr"
New-EncodedFile "$OutputPath\encoding_detection\euc_kr\medium.txt" ($krContent * 100) "euc-kr"
New-EncodedFile "$OutputPath\encoding_detection\euc_kr\large.txt" ($krContent * 1000) "euc-kr"

# Windows-1252 (Western European)
$western = "Hello! Copyright © 2025 Euro € Pound £ Yen ¥`nWindows-1252 encoding test`n"
New-EncodedFile "$OutputPath\encoding_detection\windows1252\small.txt" $western "windows-1252"
New-EncodedFile "$OutputPath\encoding_detection\windows1252\medium.txt" ($western * 100) "windows-1252"

# ISO-8859-1 (Latin 1)
New-EncodedFile "$OutputPath\encoding_detection\iso88591\small.txt" $western "iso-8859-1"

# Edge Cases
Write-Host "`nGenerating edge case files...`n" -ForegroundColor Yellow

# Empty file
New-Item -Path "$OutputPath\edge_cases\empty.txt" -ItemType File -Force | Out-Null

# ASCII only
"ASCII only content: 0123456789 abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ`n" | Set-Content "$OutputPath\edge_cases\ascii_only.txt"

# BOM only (UTF-8 BOM with no content)
$bomOnly = [System.Text.UTF8Encoding]::new($true)
New-EncodedFileWithBOM "$OutputPath\edge_cases\bom_only_utf8.txt" "" $bomOnly

# Mixed line endings (CRLF and LF)
$mixedLineEndings = "Line 1 with CRLF`r`nLine 2 with LF`nLine 3 with CRLF`r`n"
$utf8Bom = [System.Text.UTF8Encoding]::new($true)
New-EncodedFileWithBOM "$OutputPath\edge_cases\mixed_line_endings.txt" $mixedLineEndings $utf8Bom

# Very short file (1 byte)
[System.IO.File]::WriteAllBytes("$OutputPath\edge_cases\single_byte.txt", [byte[]]@(65)) # 'A'

# Repeated pattern (good for compression detection)
$pattern = "ABCDEFGHIJ" * 100
New-EncodedFileWithBOM "$OutputPath\edge_cases\repeated_pattern.txt" $pattern ([System.Text.UTF8Encoding]::new($true))

Write-Host "`nGenerating conversion test files...`n" -ForegroundColor Yellow

# Conversion test files
$content = Get-TestContent "mixed" 50

# UTF-8 source for UTF-16 conversion
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
New-EncodedFileWithBOM "$OutputPath\conversion_tests\utf8_to_utf16\source_small.txt" (Get-TestContent) $utf8NoBom
New-EncodedFileWithBOM "$OutputPath\conversion_tests\utf8_to_utf16\source_large.txt" (Get-TestContent "mixed" 500) $utf8NoBom

# GBK source for UTF-8 conversion
New-EncodedFile "$OutputPath\conversion_tests\gbk_to_utf8\source_small.txt" $gbkContent "gb2312"
New-EncodedFile "$OutputPath\conversion_tests\gbk_to_utf8\source_large.txt" ($gbkContent * 500) "gb2312"

# Shift_JIS source for UTF-8 conversion
New-EncodedFile "$OutputPath\conversion_tests\shift_jis_to_utf8\source_small.txt" $jpContent "shift_jis"
New-EncodedFile "$OutputPath\conversion_tests\shift_jis_to_utf8\source_large.txt" ($jpContent * 500) "shift_jis"

# EUC-KR source for UTF-8 conversion
New-EncodedFile "$OutputPath\conversion_tests\euc_kr_to_utf8\source_small.txt" $krContent "euc-kr"
New-EncodedFile "$OutputPath\conversion_tests\euc_kr_to_utf8\source_large.txt" ($krContent * 500) "euc-kr"

Write-Host "`n====== Test Data Generation Complete ======`n" -ForegroundColor Green
Write-Host "Test data directory: $OutputPath`n" -ForegroundColor Cyan

# Summary statistics
$totalSize = 0
$fileCount = 0
Get-ChildItem $OutputPath -Recurse -File | ForEach-Object {
    $totalSize += $_.Length
    $fileCount++
}

Write-Host "Total files created: $fileCount" -ForegroundColor Cyan
Write-Host "Total size: $([Math]::Round($totalSize / 1MB, 2)) MB" -ForegroundColor Cyan
Write-Host "`nReady for testing!`n" -ForegroundColor Yellow
