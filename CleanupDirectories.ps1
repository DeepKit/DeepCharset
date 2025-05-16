# Cleanup directories script

# Define directories to keep
$directoriesToKeep = @(
    "backup",
    "docs",
    "ini",
    "libs",
    "SynEdit",
    "tools",
    ".git",
    ".github",
    "Win32",
    "Win64",
    ".cursor",
    "Html",
    "tests"  # We'll keep only this test directory
)

# Define directories to merge or delete
$directoriesToMerge = @{
    "test" = "tests";
    "TestData" = "tests";
    "TestFiles" = "tests";
    "TestOutput" = "tests";
    "test_files" = "tests";
}

# Define directories to delete
$directoriesToDelete = @(
    "__pycache__"
)

# Function to merge directories
function MergeDirectory($sourceDir, $targetDir) {
    if (-not (Test-Path $sourceDir)) {
        Write-Host "Source directory $sourceDir does not exist."
        return
    }

    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir | Out-Null
        Write-Host "Created target directory $targetDir"
    }

    # Get all items in source directory
    $items = Get-ChildItem -Path $sourceDir

    foreach ($item in $items) {
        $targetPath = Join-Path -Path $targetDir -ChildPath $item.Name

        # If target already exists, add timestamp to filename
        if (Test-Path $targetPath) {
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $newName = $item.BaseName + "_" + $timestamp + $item.Extension
            $targetPath = Join-Path -Path $targetDir -ChildPath $newName
        }

        # Move item to target directory
        try {
            Move-Item -Path $item.FullName -Destination $targetPath -Force
            Write-Host "Moved $($item.FullName) to $targetPath"
        }
        catch {
            Write-Host "Failed to move $($item.FullName): $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Remove source directory if empty
    if ((Get-ChildItem -Path $sourceDir).Count -eq 0) {
        Remove-Item -Path $sourceDir -Force
        Write-Host "Removed empty directory $sourceDir"
    }
}

# Function to delete directory
function DeleteDirectory($dir) {
    if (-not (Test-Path $dir)) {
        Write-Host "Directory $dir does not exist."
        return
    }

    try {
        Remove-Item -Path $dir -Recurse -Force
        Write-Host "Deleted directory $dir"
    }
    catch {
        Write-Host "Failed to delete $dir: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main script

# 1. Merge test directories
Write-Host "`nMerging test directories..."
foreach ($sourceDir in $directoriesToMerge.Keys) {
    $targetDir = $directoriesToMerge[$sourceDir]
    Write-Host "Merging $sourceDir into $targetDir..."
    MergeDirectory $sourceDir $targetDir
}

# 2. Delete unnecessary directories
Write-Host "`nDeleting unnecessary directories..."
foreach ($dir in $directoriesToDelete) {
    Write-Host "Deleting $dir..."
    DeleteDirectory $dir
}

# 3. Clean Win32/Win64 directories (keep directories but delete contents)
Write-Host "`nCleaning compilation output directories..."
foreach ($dir in @("Win32", "Win64")) {
    if (Test-Path $dir) {
        $items = Get-ChildItem -Path $dir -Recurse
        foreach ($item in $items) {
            if ($item.PSIsContainer) { continue } # Skip directories
            try {
                Remove-Item -Path $item.FullName -Force
                Write-Host "Deleted $($item.FullName)"
            }
            catch {
                Write-Host "Failed to delete $($item.FullName): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        Write-Host "Cleaned $dir directory"
    }
}

# 4. List remaining directories
Write-Host "`nRemaining directories:"
$remainingDirs = Get-ChildItem -Directory | Select-Object -ExpandProperty Name
foreach ($dir in $remainingDirs) {
    if ($directoriesToKeep -contains $dir) {
        Write-Host "  $dir (kept)" -ForegroundColor Green
    }
    else {
        Write-Host "  $dir (not in keep list)" -ForegroundColor Yellow
    }
}

Write-Host "`nDirectory cleanup completed!"
