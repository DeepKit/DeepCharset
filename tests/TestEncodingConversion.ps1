# Encoding conversion test script

# Test files directory
$testFilesDir = ".\TestFiles"
$outputDir = ".\TestOutput"

# Create output directory
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Check if test files directory exists
if (-not (Test-Path $testFilesDir)) {
    Write-Host "Test files directory does not exist. Please run TestEncodingDetection.ps1 first!"
    exit
}

# Get all test files
$testFiles = Get-ChildItem -Path $testFilesDir -Filter "Test_*.txt"

# Create test report file
$reportFile = Join-Path $outputDir "TestReport.txt"
"Encoding Conversion Test Report" | Out-File -FilePath $reportFile
"=============================" | Out-File -FilePath $reportFile -Append
"" | Out-File -FilePath $reportFile -Append

# Test TransSuccess program
$exePath = ".\TransSuccess.exe"

if (-not (Test-Path $exePath)) {
    Write-Host "TransSuccess.exe does not exist. Please compile the project first!"
    "TransSuccess.exe does not exist. Please compile the project first!" | Out-File -FilePath $reportFile -Append
    exit
}

# Test encoding conversion
foreach ($file in $testFiles) {
    $fileName = $file.Name
    $filePath = $file.FullName

    # Create output files with different encodings
    $outputUTF8 = Join-Path $outputDir ($fileName -replace "\.txt$", "_to_UTF8.txt")
    $outputUTF8BOM = Join-Path $outputDir ($fileName -replace "\.txt$", "_to_UTF8BOM.txt")
    $outputANSI = Join-Path $outputDir ($fileName -replace "\.txt$", "_to_ANSI.txt")

    # Convert to UTF-8 without BOM
    Write-Host "Converting $fileName to UTF-8 without BOM..."
    & $exePath -convert "$filePath" "$outputUTF8" "UTF-8"

    # Convert to UTF-8+BOM
    Write-Host "Converting $fileName to UTF-8+BOM..."
    & $exePath -convert "$filePath" "$outputUTF8BOM" "UTF-8+BOM"

    # Convert to ANSI
    Write-Host "Converting $fileName to ANSI..."
    & $exePath -convert "$filePath" "$outputANSI" "ANSI"

    # Record test results
    "File: $fileName" | Out-File -FilePath $reportFile -Append
    "  Convert to UTF-8 without BOM: $(if (Test-Path $outputUTF8) { "Success" } else { "Failed" })" | Out-File -FilePath $reportFile -Append
    "  Convert to UTF-8+BOM: $(if (Test-Path $outputUTF8BOM) { "Success" } else { "Failed" })" | Out-File -FilePath $reportFile -Append
    "  Convert to ANSI: $(if (Test-Path $outputANSI) { "Success" } else { "Failed" })" | Out-File -FilePath $reportFile -Append
    "" | Out-File -FilePath $reportFile -Append
}

# Test batch conversion
$batchOutputDir = Join-Path $outputDir "BatchOutput"
if (-not (Test-Path $batchOutputDir)) {
    New-Item -ItemType Directory -Path $batchOutputDir | Out-Null
}

# Batch convert to UTF-8 without BOM
Write-Host "Batch converting all files to UTF-8 without BOM..."
& $exePath -batch "$testFilesDir" "$batchOutputDir\UTF8" "UTF-8"

# Batch convert to UTF-8+BOM
Write-Host "Batch converting all files to UTF-8+BOM..."
& $exePath -batch "$testFilesDir" "$batchOutputDir\UTF8BOM" "UTF-8+BOM"

# Batch convert to ANSI
Write-Host "Batch converting all files to ANSI..."
& $exePath -batch "$testFilesDir" "$batchOutputDir\ANSI" "ANSI"

# Record batch conversion test results
"Batch Conversion Tests" | Out-File -FilePath $reportFile -Append
"====================" | Out-File -FilePath $reportFile -Append
"  Batch convert to UTF-8 without BOM: $(if (Test-Path "$batchOutputDir\UTF8") { "Success" } else { "Failed" })" | Out-File -FilePath $reportFile -Append
"  Batch convert to UTF-8+BOM: $(if (Test-Path "$batchOutputDir\UTF8BOM") { "Success" } else { "Failed" })" | Out-File -FilePath $reportFile -Append
"  Batch convert to ANSI: $(if (Test-Path "$batchOutputDir\ANSI") { "Success" } else { "Failed" })" | Out-File -FilePath $reportFile -Append
"" | Out-File -FilePath $reportFile -Append

Write-Host "Testing completed! Test report saved to $reportFile"
