# Cleanup unused files script

# Define directories
$backupDir = ".\backup"
$testsDir = ".\tests"
$toolsDir = ".\tools"
$docsDir = ".\docs"

# Create directories if they don't exist
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
    Write-Host "Created backup directory"
}

if (-not (Test-Path $testsDir)) {
    New-Item -ItemType Directory -Path $testsDir | Out-Null
    Write-Host "Created tests directory"
}

if (-not (Test-Path $toolsDir)) {
    New-Item -ItemType Directory -Path $toolsDir | Out-Null
    Write-Host "Created tools directory"
}

if (-not (Test-Path $docsDir)) {
    New-Item -ItemType Directory -Path $docsDir | Out-Null
    Write-Host "Created docs directory"
}

# Define core files (these will not be moved)
$coreFiles = @(
    # Main program files
    "TransSuccess.dpr",
    "TransSuccess.dproj",
    "TransSuccess.RES",
    "TransSuccess.cfg",
    "TransSuccess.ini",
    "TransSuccess_Icon.ico",
    "TransSuccess_Icon1.ico",
    "icons8_transaction_list.ico",
    "icons8_transaction_list_16.png",
    "icons8_transaction_list_256.png",

    # View layer files
    "ViewMainCode.pas",
    "ViewMainCode.dfm",
    "ViewSynEdit.pas",
    "ViewSynEdit.dfm",
    "ViewMemo.pas",
    "ViewMemo.dfm",

    # Controller layer files
    "ControllerEncoding.pas",
    "ControllerLanguage.pas",

    # Model layer files
    "ModelEncoding.pas",
    "ModelConfig.pas",
    "ModelLanguage.pas",

    # Helper class files
    "HelperFiles.pas",
    "HelperUI.pas",
    "HelperLanguage.pas",

    # Utility class files
    "UtilsTypes.pas",
    "UtilsEncodingTypes.pas",
    "UtilsEncodingLogger.pas",
    "UtilsEncodingConstants.pas",
    "UtilsLogFile.pas",

    # Encoding detection files
    "UtilsEncodingBOM_Improved.pas",
    "UtilsEncodingUTF8Detector_Improved.pas",
    "ChineseEncodingDetector_Improved.pas",
    "JapaneseEncodingDetector_Improved.pas",
    "KoreanEncodingDetector_Improved.pas",

    # Encoding conversion files
    "EncodingConverter_Improved.pas",
    "UTF8BOMConverter_Improved.pas",

    # Dependency library files
    "JclBOM.pas",
    "JclEncodingUtils.pas",
    "JclFileUtils.pas",
    "JclStreams.pas",
    "JclStringConversions.pas",
    "JclStrings.pas",

    # Documentation files
    "README.md",
    "LICENSE",
    "progress.md",

    # Configuration files
    ".gitignore",
    ".cursorignore",

    # This script
    "CleanupFiles.ps1"
)

# Define files to move to backup directory
$backupFiles = @(
    # Old version files
    "UtilsEncodingBOM_Simple.pas",
    "UTF8BOMConverter.pas",
    "UTF8BOMConverter_Simple.pas",
    "UTF8BOMConverter_Simple_Fixed.pas",
    "UTF8BOMConverter_Enhanced.pas",
    "UTF8BOMConverter_Advanced.pas",
    "UTF8EncodingDetector.pas",
    "UtilsEncodingDetect2.pas",
    "ControllerEncodingEnhanced.pas",
    "ControllerEncodingOptimized.pas",
    "HelperEncoding.pas",
    "UtilsEncodingSpecialChars.pas",
    "UtilsEncodingConversion.pas",
    "UtilsEncodingMemory.pas",
    "EncodingConfig.pas",

    # Experimental files
    "SmartBufferManager.pas",
    "SmartFileStream.pas",
    "SmartMemoryPool.pas",
    "ThreadSafeMemoryPool.pas",
    "MemoryPoolManager.pas",
    "LargeFileProcessor.pas",
    "EncodingCycleConverter.pas",
    "EncodingIrreversibleHandler.pas",
    "EncodingRoundTripValidator.pas",
    "EncodingComparisonDotNet.pas",
    "EncodingComparisonWindows.pas",
    "SynEditWrapper.pas"
)

# Define files to move to tests directory
$testFiles = @(
    # Test programs
    "TestEncodingMain.dpr",
    "TestUTF8BOMConverter.dpr",
    "TestUTF8BOMConverterApp.dpr",
    "TestUTF8BOMConverterProject.dpr",
    "TestUTF8BOMConverterSimple.dpr",
    "TestUTF8BOMConverter_Enhanced.dpr",
    "TestUTF8Detection.dpr",
    "TestRunner.dpr",
    "TestPerformanceApp.dpr",
    "TestSampleLoaderApp.dpr",
    "TestConsistencyReportApp.dpr",
    "TestCPUMonitorApp.dpr",
    "TestDetectionReportApp.dpr",
    "EncodingTestRunner.dpr",
    "EncodingComparisonTest.dpr",
    "EncodingUtilsTest.dpr",
    "TestEncodingDotNetProgram.dpr",
    "TestEncodingIntegrationMain.dpr",
    "ChineseEncodingFeatureDBDemo.dpr",

    # Test units
    "TestEncodingDetection.pas",
    "TestUTF8BOMConverter.pas",
    "TestEncodingComparisonUnit.pas",
    "TestEncodingConfig.pas",
    "TestEncodingDotNet.pas",
    "TestEncodingIntegration.pas",
    "TestEncodingStatistics.pas",
    "TestEncodingTestSampleLoader.pas",
    "TestRegistration.pas",
    "TestsRegister.pas",
    "TestSmartBufferManager.pas",
    "TestSmartFileStream.pas",
    "TestStandardSamples.pas",
    "TestStandardSamplesGenerator.pas",
    "TestStandardSamplesTest.pas",
    "TestThreadSafeMemoryPool.pas",

    # Test scripts
    "TestEncodingDetection.ps1",
    "TestEncodingConversion.ps1",
    "RunBOMTests.bat",
    "RunEncodingStatisticsTests.bat"
)

# Define files to move to tools directory
$toolFiles = @(
    # Analysis tools
    "EncodingStatistics.pas",
    "EncodingPerformanceBenchmark.pas",
    "EncodingPerformanceBenchmark_HTMLReport.pas",
    "EncodingPerformanceBenchmark_JSONReport.pas",
    "EncodingPerformanceTester.pas",
    "EncodingCPUMonitor.pas",
    "EncodingMemoryMonitor.pas",
    "EncodingTimeMeasurer.pas",
    "EncodingDifferenceAnalyzer.pas",
    "EncodingConsistencyReportGenerator.pas",
    "EncodingDetectionReportGenerator.pas",
    "ConversionReportGenerator.pas",
    "EncodingTextComparator.pas",
    "EncodingErrorLocator.pas",
    "ErrorLocationIdentifier.pas",

    # Tool scripts
    "AnalyzeFiles.ps1",
    "MoveFiles.ps1",
    "MoveUnusedFiles.ps1",
    "move_files.ps1",
    "move_files_phase2.ps1",
    "build.bat",
    "compile.bat"
)

# Define files to move to docs directory
$docFiles = @(
    # Documentation
    "improve.md",
    "better.md",
    "detect.md",
    "better_progress.md",
    "summary.md",
    "project_dependencies.md",
    "encoding_detection_analysis.md",
    "encoding_conversion_analysis.md",
    "duplicate_files_analysis.md",
    "unused_files_analysis.md",
    "EncodingImprovement.md",
    "file_analysis.md"
)

# Function to move files
function MoveFiles($files, $targetDir, $description) {
    $movedCount = 0
    foreach ($file in $files) {
        if (Test-Path $file) {
            try {
                Move-Item -Path $file -Destination $targetDir -Force
                Write-Host "Moved file ($description): $file to $targetDir"
                $movedCount++
            }
            catch {
                Write-Host "Failed to move: $file - $_" -ForegroundColor Red
            }
        }
    }
    return $movedCount
}

# Move files to backup directory
$backupMovedCount = MoveFiles $backupFiles $backupDir "backup file"

# Move files to tests directory
$testsMovedCount = MoveFiles $testFiles $testsDir "test file"

# Move files to tools directory
$toolsMovedCount = MoveFiles $toolFiles $toolsDir "tool file"

# Move files to docs directory
$docsMovedCount = MoveFiles $docFiles $docsDir "documentation file"

# Get all remaining files
$allFiles = Get-ChildItem -Path "." -File | Select-Object -ExpandProperty Name

# Find files that are not in the core files list
$remainingUnusedFiles = $allFiles | Where-Object { $coreFiles -notcontains $_ }

# Move remaining unused files to backup directory
$remainingMovedCount = 0
foreach ($file in $remainingUnusedFiles) {
    # Skip files in the lists we've already processed
    if (($backupFiles -contains $file) -or
        ($testFiles -contains $file) -or
        ($toolFiles -contains $file) -or
        ($docFiles -contains $file)) {
        continue
    }

    # Skip DCU files (compiled units)
    if ($file -like "*.dcu") {
        continue
    }

    try {
        Move-Item -Path $file -Destination $backupDir -Force
        Write-Host "Moved remaining file: $file to $backupDir"
        $remainingMovedCount++
    }
    catch {
        Write-Host "Failed to move: $file - $_" -ForegroundColor Red
    }
}

# Delete DCU files
$dcuFiles = Get-ChildItem -Path "*.dcu" -File
foreach ($file in $dcuFiles) {
    try {
        Remove-Item -Path $file.FullName -Force
        Write-Host "Deleted compiled file: $($file.Name)"
    }
    catch {
        Write-Host "Failed to delete: $($file.Name) - $_" -ForegroundColor Red
    }
}

# Print summary
Write-Host "`nCleanup Summary:"
Write-Host "----------------"
Write-Host "Files moved to backup directory: $backupMovedCount"
Write-Host "Files moved to tests directory: $testsMovedCount"
Write-Host "Files moved to tools directory: $toolsMovedCount"
Write-Host "Files moved to docs directory: $docsMovedCount"
Write-Host "Additional files moved to backup: $remainingMovedCount"
Write-Host "Total files organized: $($backupMovedCount + $testsMovedCount + $toolsMovedCount + $docsMovedCount + $remainingMovedCount)"
Write-Host "`nCleanup completed!"
