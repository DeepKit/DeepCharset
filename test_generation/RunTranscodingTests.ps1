# DeepCharset File Transcoding Test Execution Script
# Purpose: Run comprehensive file conversion tests with data integrity verification
# Date: 2025-11-13

param(
    [string]$TestDataPath = "D:\SynologyDrive\Progs\_Delphi\DeepCharset\test_data",
    [string]$DeepCharsetExe = "D:\SynologyDrive\Progs\_Delphi\DeepCharset\DeepCharset.exe",
    [string]$ResultsPath = "D:\SynologyDrive\Progs\_Delphi\DeepCharset\test_results",
    [switch]$Verbose
)

# Initialize
$conversionResults = @()
$conversionStats = @{}
$dataIntegrityResults = @()

# Create results directory
if (-not (Test-Path $ResultsPath)) {
    New-Item -ItemType Directory -Path $ResultsPath -Force | Out-Null
}

Write-Host "`n====== DeepCharset File Transcoding Tests ======`n" -ForegroundColor Yellow
Write-Host "Test Data Path: $TestDataPath" -ForegroundColor Cyan
Write-Host "Results Path: $ResultsPath`n" -ForegroundColor Cyan

# Function to compute SHA256 hash
function Get-FileHash256 {
    param([string]$FilePath)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($FilePath)
    $hash = $sha256.ComputeHash($stream)
    $stream.Dispose()
    return [System.BitConverter]::ToString($hash) -replace "-"
}

# Function to run transcoding test
function Invoke-TranscodingTest {
    param(
        [string]$SourceFile,
        [string]$SourceEncoding,
        [string]$TargetEncoding,
        [string]$OutputFile
    )
    
    $startTime = Get-Date
    # DeepCharset CLI: -s (source) -t (target) -o (output) -b (backup)
    $output = & $DeepCharsetExe -s "$SourceEncoding" -t "$TargetEncoding" -o "$OutputFile" -b "$SourceFile" 2>&1
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds
    
    $result = @{
        SourceFile = Split-Path $SourceFile -Leaf
        SourcePath = $SourceFile
        SourceSize = (Get-Item $SourceFile).Length
        SourceEncoding = $SourceEncoding
        TargetEncoding = $TargetEncoding
        OutputFile = $OutputFile
        OutputSize = if (Test-Path $OutputFile) { (Get-Item $OutputFile).Length } else { 0 }
        Duration = $duration
        Success = $LASTEXITCODE -eq 0
        Output = $output
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    return $result
}

# Define conversion test scenarios
$conversionScenarios = @(
    @{ SourcePath = "conversion_tests\utf8_to_utf16"; SourceEnc = "UTF-8"; TargetEnc = "UTF-16"; Category = "UTF conversions" }
    @{ SourcePath = "conversion_tests\gbk_to_utf8"; SourceEnc = "GBK"; TargetEnc = "UTF-8"; Category = "Asian encodings" }
    @{ SourcePath = "conversion_tests\shift_jis_to_utf8"; SourceEnc = "Shift_JIS"; TargetEnc = "UTF-8"; Category = "Asian encodings" }
    @{ SourcePath = "conversion_tests\euc_kr_to_utf8"; SourceEnc = "EUC-KR"; TargetEnc = "UTF-8"; Category = "Asian encodings" }
)

Write-Host "Starting file transcoding tests...`n" -ForegroundColor Yellow

$totalConversions = 0
$successCount = 0
$failureCount = 0

foreach ($scenario in $conversionScenarios) {
    $scenarioPath = Join-Path $TestDataPath $scenario.SourcePath
    
    if (-not (Test-Path $scenarioPath)) {
        Write-Host "Skipping: $($scenario.Category) - Source path not found" -ForegroundColor Gray
        continue
    }
    
    Write-Host "Testing: $($scenario.SourceEnc) → $($scenario.TargetEnc)" -ForegroundColor Cyan
    
    $sourceFiles = Get-ChildItem -Path $scenarioPath -Filter "source_*.txt"
    
    foreach ($sourceFile in $sourceFiles) {
        $outputFile = Join-Path $ResultsPath "$($sourceFile.BaseName)_converted$($sourceFile.Extension)"
        $sourceHash = Get-FileHash256 $sourceFile.FullName
        
        Write-Host "  Converting: $($sourceFile.Name)" -ForegroundColor White
        
        try {
            $testResult = Invoke-TranscodingTest -SourceFile $sourceFile.FullName `
                                                  -SourceEncoding $scenario.SourceEnc `
                                                  -TargetEncoding $scenario.TargetEnc `
                                                  -OutputFile $outputFile
            
            $totalConversions++
            $conversionResults += $testResult
            
            if ($testResult.Success -and (Test-Path $outputFile)) {
                $successCount++
                $outputHash = Get-FileHash256 $outputFile
                
                # Test reversibility (convert back to original encoding)
                $reverseOutput = Join-Path $ResultsPath "$($sourceFile.BaseName)_reversed$($sourceFile.Extension)"
                $reverseResult = Invoke-TranscodingTest -SourceFile $outputFile `
                                                        -SourceEncoding $scenario.TargetEnc `
                                                        -TargetEncoding $scenario.SourceEnc `
                                                        -OutputFile $reverseOutput
                
                $reversible = $false
                $reversibleNote = ""
                
                if ($reverseResult.Success -and (Test-Path $reverseOutput)) {
                    $reverseHash = Get-FileHash256 $reverseOutput
                    $reversible = ($sourceHash -eq $reverseHash)
                    $reversibleNote = if ($reversible) { "✓ Reversible (hash matches)" } else { "✗ Reversible test failed (hash mismatch)" }
                } else {
                    $reversibleNote = "✗ Reverse conversion failed"
                }
                
                $integrityData = @{
                    Conversion = "$($scenario.SourceEnc) → $($scenario.TargetEnc)"
                    File = $sourceFile.Name
                    SourceSize = $testResult.SourceSize
                    OutputSize = $testResult.OutputSize
                    SourceHash = $sourceHash
                    OutputHash = $outputHash
                    ReverseHash = if ($reversible) { $reverseHash } else { "" }
                    Reversible = $reversible
                    ReversibilityNote = $reversibleNote
                    Duration = $testResult.Duration
                }
                
                $dataIntegrityResults += $integrityData
                
                Write-Host "    ✓ Success (${$testResult.Duration}ms) - $reversibleNote" -ForegroundColor Green
            } else {
                $failureCount++
                Write-Host "    ✗ Failed (${$testResult.Duration}ms)" -ForegroundColor Red
                if ($Verbose) {
                    Write-Host "       Output: $($testResult.Output)" -ForegroundColor DarkGray
                }
            }
        } catch {
            $failureCount++
            $totalConversions++
            Write-Host "    ✗ Error: $_" -ForegroundColor Red
        }
    }
    
    Write-Host ""
}

# Test BOM handling specifically
Write-Host "Testing BOM handling...`n" -ForegroundColor Yellow

$bomTestPath = Join-Path $TestDataPath "encoding_detection\utf8_bom\small.txt"
if (Test-Path $bomTestPath) {
    Write-Host "  Testing: UTF-8 with BOM → UTF-16LE" -ForegroundColor Cyan
    
    $bomOutput = Join-Path $ResultsPath "bom_test_utf16le.txt"
    $bomResult = Invoke-TranscodingTest -SourceFile $bomTestPath `
                                        -SourceEncoding "UTF-8" `
                                        -TargetEncoding "UTF-16LE" `
                                        -OutputFile $bomOutput
    
    if ($bomResult.Success) {
        Write-Host "    ✓ BOM handling test passed" -ForegroundColor Green
    } else {
        Write-Host "    ✗ BOM handling test failed" -ForegroundColor Red
    }
}

# Generate summary
Write-Host "`n====== Transcoding Test Summary =====" -ForegroundColor Yellow
Write-Host ""
Write-Host "Total Conversions: $totalConversions" -ForegroundColor Cyan
Write-Host "Successful: $successCount" -ForegroundColor Green
Write-Host "Failed: $failureCount" -ForegroundColor Red

if ($totalConversions -gt 0) {
    $successRate = ($successCount / $totalConversions) * 100
    Write-Host "Success Rate: $([Math]::Round($successRate, 2))%" -ForegroundColor $(if ($successRate -ge 95) { 'Green' } else { 'Yellow' })
}

Write-Host ""

# Data Integrity Summary
$reversibleCount = ($dataIntegrityResults | Where-Object { $_.Reversible }).Count
$totalIntegrityTests = $dataIntegrityResults.Count

Write-Host "Data Integrity:" -ForegroundColor Yellow
Write-Host "  Round-trip reversible: $reversibleCount / $totalIntegrityTests" -ForegroundColor $(if ($reversibleCount -eq $totalIntegrityTests) { 'Green' } else { 'Yellow' })

# Export results
Write-Host "`nExporting results..." -ForegroundColor Cyan

$csvPath = Join-Path $ResultsPath "transcoding_results.csv"
$conversionResults | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "  Conversion results saved to: $csvPath" -ForegroundColor Green

$integrityPath = Join-Path $ResultsPath "data_integrity_results.csv"
$dataIntegrityResults | Export-Csv -Path $integrityPath -NoTypeInformation -Encoding UTF8
Write-Host "  Data integrity results saved to: $integrityPath" -ForegroundColor Green

# Export detailed summary
$summaryPath = Join-Path $ResultsPath "transcoding_summary.txt"
$summary = @"
DeepCharset File Transcoding Test Results
===========================================
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

OVERALL STATISTICS
==================
Total Conversions: $totalConversions
Successful: $successCount
Failed: $failureCount
$(if ($totalConversions -gt 0) { "Success Rate: $([Math]::Round(($successCount / $totalConversions) * 100, 2))%" })

DATA INTEGRITY
==============
Round-trip Reversible Tests: $reversibleCount / $totalIntegrityTests
$(if ($totalIntegrityTests -gt 0) { "Reversibility Rate: $([Math]::Round(($reversibleCount / $totalIntegrityTests) * 100, 2))%" })

DETAILED RESULTS
================
"@

if ($dataIntegrityResults.Count -gt 0) {
    $summary += "`n"
    foreach ($integrity in $dataIntegrityResults) {
        $summary += "Conversion: $($integrity.Conversion)`n"
        $summary += "  File: $($integrity.File)`n"
        $summary += "  Source Size: $($integrity.SourceSize) bytes`n"
        $summary += "  Output Size: $($integrity.OutputSize) bytes`n"
        $summary += "  Reversible: $($integrity.Reversible)`n"
        $summary += "  Note: $($integrity.ReversibilityNote)`n"
        $summary += "  Duration: $([Math]::Round($integrity.Duration, 2))ms`n`n"
    }
}

$summary | Out-File -FilePath $summaryPath -Encoding UTF8
Write-Host "  Summary saved to: $summaryPath" -ForegroundColor Green

Write-Host "`n====== Transcoding Tests Complete ======`n" -ForegroundColor Green
