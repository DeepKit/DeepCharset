# Move unused files to backup directory
# This script is used to move unused files to the backup directory

# Define root directory
$rootDir = "d:\SynologyDrive\Progs\_Delphi\TransSuccess"

# Define backup directory
$backupDir = "$rootDir\backup"

# Create backup directory if it doesn't exist
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
    Write-Host "Created backup directory: $backupDir"
}

# Define core files list (these files won't be moved)
$coreFiles = @(
    # Main program files
    "TransSuccess.dpr",
    "TransSuccess.dproj",
    "TransSuccess.res",
    
    # Main form files
    "ViewMainCode.pas",
    "ViewMainCode.dfm",
    
    # Controller files
    "ControllerEncoding.pas",
    "ControllerEncodingEnhanced.pas",
    "ControllerLanguage.pas",
    
    # Model files
    "ModelEncoding.pas",
    "ModelConfig.pas",
    "ModelLanguage.pas",
    
    # View files
    "ViewSynEdit.pas",
    "ViewSynEdit.dfm",
    
    # Helper files
    "HelperFiles.pas",
    "HelperUI.pas",
    "HelperLanguage.pas",
    
    # Utility files
    "UtilsTypes.pas",
    "UtilsEncodingTypes.pas",
    "UtilsEncodingLogger.pas",
    
    # Encoding detection and conversion files
    "UtilsEncodingBOM_Improved.pas",
    "UtilsEncodingUTF8Detector_Improved.pas",
    "ChineseEncodingDetector_Improved.pas",
    "EncodingConverter_Improved.pas",
    "UTF8BOMConverter_Improved.pas",
    
    # Documentation files
    "detect.md",
    "better.md",
    "improve.md",
    
    # Script files
    "AnalyzeFiles.ps1",
    "MoveFiles.ps1",
    "MoveUnusedFiles.ps1",
    
    # Configuration files
    "TransSuccess.cfg",
    
    # Other necessary files
    ".gitignore"
)

# Get all files
$allFiles = Get-ChildItem -Path $rootDir -File | Select-Object -ExpandProperty Name

# Find unused files
$unusedFiles = $allFiles | Where-Object { $coreFiles -notcontains $_ }

# Output analysis results
Write-Host "File analysis results:"
Write-Host "Total files: $($allFiles.Count)"
Write-Host "Core files: $($coreFiles.Count)"
Write-Host "Unused files: $($unusedFiles.Count)"

# Output list of unused files
Write-Host "`nList of unused files:"
foreach ($file in $unusedFiles | Sort-Object) {
    Write-Host "  $file"
}

# Ask whether to move files
Write-Host "`nDo you want to move unused files to the backup directory? (Y/N)"
$response = "Y" # Automatically proceed with Y

if ($response -eq "Y" -or $response -eq "y") {
    $movedCount = 0
    foreach ($file in $unusedFiles) {
        $sourcePath = Join-Path -Path $rootDir -ChildPath $file
        $destPath = Join-Path -Path $backupDir -ChildPath $file
        
        # If the target file already exists, add a timestamp
        if (Test-Path $destPath) {
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $fileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($file)
            $fileExt = [System.IO.Path]::GetExtension($file)
            $newFileName = "$fileNameWithoutExt-$timestamp$fileExt"
            $destPath = Join-Path -Path $backupDir -ChildPath $newFileName
        }
        
        # Move file
        try {
            Move-Item -Path $sourcePath -Destination $destPath -Force
            Write-Host "Moved: $file -> $destPath"
            $movedCount++
        }
        catch {
            Write-Host "Failed to move: $file - $_" -ForegroundColor Red
        }
    }
    
    Write-Host "`nMove completed: Moved $movedCount files to $backupDir"
}
else {
    Write-Host "Operation cancelled, no files were moved."
}
