# DeepCharset Encoding Detection Test Execution Script
# Purpose: Run comprehensive encoding detection tests and record results
# Date: 2025-11-13

param(
    [string]$TestDataPath = "D:\SynologyDrive\Progs\_Delphi\DeepCharset\test_data",
    [string]$DeepCharsetExe = "D:\SynologyDrive\Progs\_Delphi\DeepCharset\DeepCharset.exe",
    [string]$ResultsPath = "D:\SynologyDrive\Progs\_Delphi\DeepCharset\test_results",
    [switch]$Verbose
)

# Import required modules
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Initialize
$results = @()
$detectionStats = @{}
$errorCount = 0

# Create results directory
if (-not (Test-Path $ResultsPath)) {
    New-Item -ItemType Directory -Path $ResultsPath -Force | Out-Null
    Write-Host "Created results directory: $ResultsPath" -ForegroundColor Green
}

# Verify DeepCharset executable exists
if (-not (Test-Path $DeepCharsetExe)) {
    Write-Host "Error: DeepCharset.exe not found at $DeepCharsetExe" -ForegroundColor Red
    exit 1
}

Write-Host "`n====== DeepCharset Encoding Detection Tests ======`n" -ForegroundColor Yellow
Write-Host "Test Data Path: $TestDataPath" -ForegroundColor Cyan
Write-Host "Results Path: $ResultsPath`n" -ForegroundColor Cyan

# Function to detect encoding using DeepCharset
function Invoke-EncodingDetection {
    param(
        [string]$FilePath,
        [string]$ExpectedEncoding
    )
    
    $startTime = Get-Date
    # DeepCharset expects: -s (source/auto-detect) -t (target encoding)
    # For detection, we simply run without specifying source to trigger auto-detection
    $output = & $DeepCharsetExe -s auto -t UTF-8 "$FilePath" --verbose 2>&1
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds
    
    $result = @{
        File = Split-Path $FilePath -Leaf
        FilePath = $FilePath
        FileSize = (Get-Item $FilePath).Length
        ExpectedEncoding = $ExpectedEncoding
        DetectedEncoding = ""
        Confidence = ""
        Result = "UNKNOWN"
        Duration = $duration
        Output = $output
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    # Parse output to extract detected encoding from verbose mode
    # The output format is typically: "✓ Success: <SourceEncoding> -> UTF-8"
    if ($output -match "Success:\s*([^-]*?)\s*->") {
        $result.DetectedEncoding = $matches[1].Trim()
    } elseif ($output -match "Detected?.*?:\s*([^\n,]*?)[\s,\n]") {
        $result.DetectedEncoding = $matches[1].Trim()
    }
    
    # Normalize encoding names for comparison
    $detected = Normalize-EncodingName $result.DetectedEncoding
    $expected = Normalize-EncodingName $result.ExpectedEncoding
    
    if ($detected -eq $expected) {
        $result.Result = "PASS"
    } else {
        $result.Result = "FAIL"
    }
    
    return $result
}

# Function to normalize encoding names for comparison
function Normalize-EncodingName {
    param([string]$Name)
    
    if ([string]::IsNullOrWhiteSpace($Name)) {
        return ""
    }
    
    # Standardize common encoding name variants
    $name = $name.ToLower() -replace "\s+", "" -replace "_", "-"
    
    # Handle common aliases
    switch ($name) {
        { $_ -match "utf-?8" } { return "utf-8" }
        { $_ -match "utf-?16.*le" } { return "utf-16le" }
        { $_ -match "utf-16.*be" } { return "utf-16be" }
        { $_ -match "gbk|gb-?2312|gb18030" } { return "gbk" }
        { $_ -match "shift-?jis|sjis|ms932" } { return "shift-jis" }
        { $_ -match "euc-?jp" } { return "euc-jp" }
        { $_ -match "euc-?kr" } { return "euc-kr" }
        { $_ -match "windows-?1252|cp1252" } { return "windows-1252" }
        { $_ -match "iso-?8859-?1|latin-?1" } { return "iso-8859-1" }
        default { return $name }
    }
}

# Test mapping: folder name to expected encoding
$encodingMap = @{
    "utf8_bom"      = "UTF-8 BOM"
    "utf8_no_bom"   = "UTF-8"
    "utf16le"       = "UTF-16LE"
    "utf16be"       = "UTF-16BE"
    "gbk"           = "GBK"
    "gb2312"        = "GB2312"
    "shift_jis"     = "Shift_JIS"
    "euc_jp"        = "EUC-JP"
    "euc_kr"        = "EUC-KR"
    "windows1252"   = "Windows-1252"
    "iso88591"      = "ISO-8859-1"
}

# Run encoding detection tests
Write-Host "Starting encoding detection tests...`n" -ForegroundColor Yellow

$encodingTestPath = Join-Path $TestDataPath "encoding_detection"
$testFolders = Get-ChildItem -Path $encodingTestPath -Directory

foreach ($folder in $testFolders) {
    $folderName = $folder.Name
    $expectedEncoding = $encodingMap[$folderName]
    
    if (-not $expectedEncoding) {
        Write-Host "Skipping unknown folder: $folderName" -ForegroundColor Gray
        continue
    }
    
    Write-Host "Testing: $expectedEncoding" -ForegroundColor Cyan
    
    if (-not $detectionStats[$folderName]) {
        $detectionStats[$folderName] = @{
            Encoding = $expectedEncoding
            Total = 0
            Pass = 0
            Fail = 0
            Accuracy = 0
            AvgDuration = 0
            TotalDuration = 0
            Tests = @()
        }
    }
    
    $testFiles = Get-ChildItem -Path $folder.FullName -File
    
    foreach ($testFile in $testFiles) {
        try {
            $testResult = Invoke-EncodingDetection -FilePath $testFile.FullName -ExpectedEncoding $expectedEncoding
            $results += $testResult
            $detectionStats[$folderName].Tests += $testResult
            
            $detectionStats[$folderName].Total++
            $detectionStats[$folderName].TotalDuration += $testResult.Duration
            
            if ($testResult.Result -eq "PASS") {
                $detectionStats[$folderName].Pass++
                Write-Host "  ✓ $($testFile.Name) - $($testResult.DetectedEncoding) (${$testResult.Duration}ms)" -ForegroundColor Green
            } else {
                $detectionStats[$folderName].Fail++
                Write-Host "  ✗ $($testFile.Name) - Got $($testResult.DetectedEncoding), Expected $expectedEncoding (${$testResult.Duration}ms)" -ForegroundColor Red
            }
            
            if ($Verbose) {
                Write-Host "     Output: $($testResult.Output | Out-String)" -ForegroundColor DarkGray
            }
        } catch {
            Write-Host "  ✗ $($testFile.Name) - Error: $_" -ForegroundColor Red
            $detectionStats[$folderName].Total++
            $detectionStats[$folderName].Fail++
            $errorCount++
        }
    }
    
    # Calculate stats for this encoding
    if ($detectionStats[$folderName].Total -gt 0) {
        $detectionStats[$folderName].Accuracy = ($detectionStats[$folderName].Pass / $detectionStats[$folderName].Total) * 100
        $detectionStats[$folderName].AvgDuration = $detectionStats[$folderName].TotalDuration / $detectionStats[$folderName].Total
    }
    
    Write-Host ""
}

# Test edge cases
Write-Host "Testing edge cases...`n" -ForegroundColor Yellow

$edgeCasePath = Join-Path $TestDataPath "edge_cases"
if (Test-Path $edgeCasePath) {
    $edgeCaseFiles = Get-ChildItem -Path $edgeCasePath -File
    $edgeCaseResults = @()
    
    foreach ($file in $edgeCaseFiles) {
        Write-Host "  Testing: $($file.Name)" -ForegroundColor Cyan
        $startTime = Get-Date
        $output = & $DeepCharsetExe -detect "$($file.FullName)" 2>&1
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        $edgeCaseResult = @{
            File = $file.Name
            FilePath = $file.FullName
            FileSize = $file.Length
            DetectedEncoding = ""
            Duration = $duration
            Output = $output
            Status = "Completed"
        }
        
        if ($output -match "Encoding:\s*(.+?)($|Confidence)") {
            $edgeCaseResult.DetectedEncoding = $matches[1].Trim()
        }
        
        $edgeCaseResults += $edgeCaseResult
        Write-Host "    Detected: $($edgeCaseResult.DetectedEncoding) (${duration}ms)" -ForegroundColor Gray
    }
}

# Generate summary report
Write-Host "`n====== Test Summary ======`n" -ForegroundColor Yellow

$totalTests = $results.Count
$totalPassed = ($results | Where-Object { $_.Result -eq "PASS" }).Count
$totalFailed = ($results | Where-Object { $_.Result -eq "FAIL" }).Count
$overallAccuracy = if ($totalTests -gt 0) { ($totalPassed / $totalTests) * 100 } else { 0 }

Write-Host "Total Tests: $totalTests" -ForegroundColor Cyan
Write-Host "Passed: $totalPassed" -ForegroundColor Green
Write-Host "Failed: $totalFailed" -ForegroundColor Red
Write-Host "Accuracy: $([Math]::Round($overallAccuracy, 2))%" -ForegroundColor Cyan
Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { 'Red' } else { 'Green' })
Write-Host ""

Write-Host "Per-Encoding Accuracy:`n" -ForegroundColor Yellow
foreach ($encoding in ($detectionStats.Keys | Sort-Object)) {
    $stat = $detectionStats[$encoding]
    $accuracy = $stat.Accuracy
    $color = if ($accuracy -ge 90) { 'Green' } elseif ($accuracy -ge 80) { 'Yellow' } else { 'Red' }
    Write-Host "$($stat.Encoding): $($stat.Pass)/$($stat.Total) ($([Math]::Round($accuracy, 2))%) - Avg ${$($stat.AvgDuration)}ms" -ForegroundColor $color
}

# Export detailed results to CSV
Write-Host "`nExporting results to CSV..." -ForegroundColor Cyan
$csvPath = Join-Path $ResultsPath "test_results_detailed.csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "Detailed results saved to: $csvPath" -ForegroundColor Green

# Export summary to text file
$summaryPath = Join-Path $ResultsPath "test_results_summary.txt"
$summary = @"
DeepCharset Encoding Detection Test Results
=============================================
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

OVERALL STATISTICS
==================
Total Tests: $totalTests
Passed: $totalPassed
Failed: $totalFailed
Overall Accuracy: $([Math]::Round($overallAccuracy, 2))%
Errors: $errorCount

PER-ENCODING RESULTS
====================
"@

foreach ($encoding in ($detectionStats.Keys | Sort-Object)) {
    $stat = $detectionStats[$encoding]
    $summary += "`n$($stat.Encoding):`n"
    $summary += "  Tests Run: $($stat.Total)`n"
    $summary += "  Passed: $($stat.Pass)`n"
    $summary += "  Failed: $($stat.Fail)`n"
    $summary += "  Accuracy: $([Math]::Round($stat.Accuracy, 2))%`n"
    $summary += "  Avg Detection Time: $([Math]::Round($stat.AvgDuration, 2))ms`n"
}

$summary | Out-File -FilePath $summaryPath -Encoding UTF8
Write-Host "Summary saved to: $summaryPath" -ForegroundColor Green

# Export JSON results for further analysis
$jsonPath = Join-Path $ResultsPath "test_results.json"
$jsonData = @{
    GeneratedAt = Get-Date -Format "o"
    TotalTests = $totalTests
    Passed = $totalPassed
    Failed = $totalFailed
    OverallAccuracy = $overallAccuracy
    Errors = $errorCount
    EncodingStats = $detectionStats
    DetailedResults = $results
} | ConvertTo-Json -Depth 4
$jsonData | Out-File -FilePath $jsonPath -Encoding UTF8
Write-Host "JSON results saved to: $jsonPath" -ForegroundColor Green

Write-Host "`n====== Test Execution Complete ======`n" -ForegroundColor Green
Write-Host "Results directory: $ResultsPath" -ForegroundColor Cyan
