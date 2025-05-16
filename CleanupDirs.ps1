# Simplified directory cleanup script

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

# Define directories to merge into tests
$testDirs = @(
    "test",
    "TestData",
    "TestFiles",
    "TestOutput",
    "test_files"
)

# Define directories to delete
$dirsToDelete = @(
    "__pycache__"
)

# Create tests directory if it doesn't exist
if (-not (Test-Path "tests")) {
    New-Item -ItemType Directory -Path "tests" | Out-Null
    Write-Host "Created tests directory"
}

# Merge test directories into tests
Write-Host "`nMerging test directories into tests..."
foreach ($dir in $testDirs) {
    if (Test-Path $dir) {
        Write-Host "Processing $dir..."
        
        # Get all items in the directory
        $items = Get-ChildItem -Path $dir
        
        foreach ($item in $items) {
            $targetPath = Join-Path -Path "tests" -ChildPath $item.Name
            
            # If target already exists, add timestamp to filename
            if (Test-Path $targetPath) {
                $timestamp = Get-Date -Format "yyyyMMddHHmmss"
                $newName = $item.BaseName + "_" + $timestamp + $item.Extension
                $targetPath = Join-Path -Path "tests" -ChildPath $newName
            }
            
            # Move item to tests directory
            try {
                Move-Item -Path $item.FullName -Destination $targetPath -Force
                Write-Host "  Moved $($item.Name) to tests"
            }
            catch {
                Write-Host "  Failed to move $($item.Name)" -ForegroundColor Red
            }
        }
        
        # Try to remove the now empty directory
        try {
            Remove-Item -Path $dir -Force
            Write-Host "Removed empty directory $dir"
        }
        catch {
            Write-Host "Could not remove directory $dir" -ForegroundColor Yellow
        }
    }
}

# Delete unnecessary directories
Write-Host "`nDeleting unnecessary directories..."
foreach ($dir in $dirsToDelete) {
    if (Test-Path $dir) {
        try {
            Remove-Item -Path $dir -Recurse -Force
            Write-Host "Deleted directory $dir"
        }
        catch {
            Write-Host "Failed to delete directory $dir" -ForegroundColor Red
        }
    }
}

# Clean Win32/Win64 directories (keep directories but delete contents)
Write-Host "`nCleaning compilation output directories..."
foreach ($dir in @("Win32", "Win64")) {
    if (Test-Path $dir) {
        try {
            Get-ChildItem -Path $dir -Recurse -File | Remove-Item -Force
            Write-Host "Cleaned $dir directory"
        }
        catch {
            Write-Host "Failed to clean $dir directory" -ForegroundColor Red
        }
    }
}

# List remaining directories
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
