# 分析项目文件
# 此脚本用于分析项目文件，找出哪些是必要的，哪些可以移动到backup目录

# 定义根目录
$rootDir = "d:\SynologyDrive\Progs\_Delphi\TransSuccess"

# 定义备份目录
$backupDir = "$rootDir\backup"

# 创建备份目录（如果不存在）
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
    Write-Host "创建备份目录: $backupDir"
}

# 从dpr文件中提取使用的单元
function Get-UsedUnits {
    param (
        [string]$dprFile
    )
    
    $content = Get-Content -Path $dprFile -Raw
    $usesPattern = "(?s)uses\s+(.*?);.*?begin"
    $usesMatch = [regex]::Match($content, $usesPattern)
    
    if ($usesMatch.Success) {
        $usesBlock = $usesMatch.Groups[1].Value
        $units = @()
        
        # 提取单元名称
        $unitPattern = "(\w+)\s+in\s+'([^']+)'"
        $unitMatches = [regex]::Matches($usesBlock, $unitPattern)
        
        foreach ($match in $unitMatches) {
            $unitName = $match.Groups[1].Value
            $unitFile = $match.Groups[2].Value
            $units += $unitFile
        }
        
        return $units
    }
    
    return @()
}

# 从pas文件中提取使用的单元
function Get-UsedUnitsFromPas {
    param (
        [string]$pasFile
    )
    
    $content = Get-Content -Path $pasFile -Raw
    $usesPattern = "(?s)uses\s+(.*?);.*?(?:implementation|type|const|var|begin)"
    $usesMatch = [regex]::Match($content, $usesPattern)
    
    if ($usesMatch.Success) {
        $usesBlock = $usesMatch.Groups[1].Value
        $units = @()
        
        # 提取单元名称
        $unitPattern = "(\w+)"
        $unitMatches = [regex]::Matches($usesBlock, $unitPattern)
        
        foreach ($match in $unitMatches) {
            $unitName = $match.Groups[1].Value
            $units += $unitName
        }
        
        return $units
    }
    
    return @()
}

# 递归查找依赖
function Find-Dependencies {
    param (
        [string[]]$files,
        [ref]$allDependencies
    )
    
    foreach ($file in $files) {
        $fullPath = Join-Path -Path $rootDir -ChildPath $file
        
        if (Test-Path $fullPath) {
            if (-not $allDependencies.Value.Contains($file)) {
                $allDependencies.Value.Add($file) | Out-Null
                
                # 如果是pas文件，查找其依赖
                if ($file -like "*.pas") {
                    $units = Get-UsedUnitsFromPas -pasFile $fullPath
                    foreach ($unit in $units) {
                        $unitFile = "$unit.pas"
                        $unitPath = Join-Path -Path $rootDir -ChildPath $unitFile
                        
                        if (Test-Path $unitPath) {
                            if (-not $allDependencies.Value.Contains($unitFile)) {
                                Find-Dependencies -files @($unitFile) -allDependencies $allDependencies
                            }
                        }
                    }
                }
            }
        }
    }
}

# 获取所有文件
$allFiles = Get-ChildItem -Path $rootDir -File | Select-Object -ExpandProperty Name

# 获取dpr文件
$dprFiles = Get-ChildItem -Path $rootDir -Filter "*.dpr" | Select-Object -ExpandProperty Name

# 初始化必要文件列表
$necessaryFiles = New-Object System.Collections.ArrayList

# 添加dpr文件
foreach ($dpr in $dprFiles) {
    $necessaryFiles.Add($dpr) | Out-Null
}

# 添加dproj文件
$dprojFiles = Get-ChildItem -Path $rootDir -Filter "*.dproj" | Select-Object -ExpandProperty Name
foreach ($dproj in $dprojFiles) {
    $necessaryFiles.Add($dproj) | Out-Null
}

# 添加res文件
$resFiles = Get-ChildItem -Path $rootDir -Filter "*.res" | Select-Object -ExpandProperty Name
foreach ($res in $resFiles) {
    $necessaryFiles.Add($res) | Out-Null
}

# 添加md文件
$mdFiles = Get-ChildItem -Path $rootDir -Filter "*.md" | Select-Object -ExpandProperty Name
foreach ($md in $mdFiles) {
    $necessaryFiles.Add($md) | Out-Null
}

# 添加ini文件
$iniFiles = Get-ChildItem -Path $rootDir -Filter "*.ini" | Select-Object -ExpandProperty Name
foreach ($ini in $iniFiles) {
    $necessaryFiles.Add($ini) | Out-Null
}

# 添加脚本文件
$scriptFiles = Get-ChildItem -Path $rootDir -Filter "*.ps1" | Select-Object -ExpandProperty Name
foreach ($script in $scriptFiles) {
    $necessaryFiles.Add($script) | Out-Null
}

# 添加图标文件
$iconFiles = Get-ChildItem -Path $rootDir -Filter "*.ico" | Select-Object -ExpandProperty Name
foreach ($icon in $iconFiles) {
    $necessaryFiles.Add($icon) | Out-Null
}

# 添加图片文件
$imageFiles = Get-ChildItem -Path $rootDir -Filter "*.png" | Select-Object -ExpandProperty Name
foreach ($image in $imageFiles) {
    $necessaryFiles.Add($image) | Out-Null
}

# 添加配置文件
$configFiles = Get-ChildItem -Path $rootDir -Filter "*.cfg" | Select-Object -ExpandProperty Name
foreach ($config in $configFiles) {
    $necessaryFiles.Add($config) | Out-Null
}

# 添加gitignore文件
$gitignoreFiles = Get-ChildItem -Path $rootDir -Filter ".gitignore" | Select-Object -ExpandProperty Name
foreach ($gitignore in $gitignoreFiles) {
    $necessaryFiles.Add($gitignore) | Out-Null
}

# 从dpr文件中获取使用的单元
foreach ($dpr in $dprFiles) {
    $dprPath = Join-Path -Path $rootDir -ChildPath $dpr
    $units = Get-UsedUnits -dprFile $dprPath
    
    foreach ($unit in $units) {
        if (-not $necessaryFiles.Contains($unit)) {
            $necessaryFiles.Add($unit) | Out-Null
        }
        
        # 添加对应的dfm文件
        $dfmFile = [System.IO.Path]::ChangeExtension($unit, ".dfm")
        if (Test-Path (Join-Path -Path $rootDir -ChildPath $dfmFile)) {
            if (-not $necessaryFiles.Contains($dfmFile)) {
                $necessaryFiles.Add($dfmFile) | Out-Null
            }
        }
    }
}

# 递归查找依赖
$dependencies = New-Object System.Collections.ArrayList
foreach ($file in $necessaryFiles) {
    Find-Dependencies -files @($file) -allDependencies ([ref]$dependencies)
}

# 合并必要文件和依赖
foreach ($dep in $dependencies) {
    if (-not $necessaryFiles.Contains($dep)) {
        $necessaryFiles.Add($dep) | Out-Null
    }
}

# 添加特定的改进版文件
$improvedFiles = @(
    "ChineseEncodingDetector_Improved.pas",
    "EncodingConverter_Improved.pas",
    "UTF8BOMConverter_Improved.pas",
    "UtilsEncodingBOM_Improved.pas",
    "UtilsEncodingUTF8Detector_Improved.pas"
)

foreach ($file in $improvedFiles) {
    if (-not $necessaryFiles.Contains($file)) {
        $necessaryFiles.Add($file) | Out-Null
    }
}

# 找出可以移动到backup的文件
$filesToBackup = $allFiles | Where-Object { -not $necessaryFiles.Contains($_) }

# 输出分析结果
Write-Host "文件分析结果:"
Write-Host "总文件数: $($allFiles.Count)"
Write-Host "必要文件数: $($necessaryFiles.Count)"
Write-Host "可移动到backup的文件数: $($filesToBackup.Count)"

# 输出必要文件列表
Write-Host "`n必要文件列表:"
foreach ($file in $necessaryFiles | Sort-Object) {
    Write-Host "  $file"
}

# 输出可移动到backup的文件列表
Write-Host "`n可移动到backup的文件列表:"
foreach ($file in $filesToBackup | Sort-Object) {
    Write-Host "  $file"
}

# 询问是否移动文件
$response = Read-Host "是否将不必要的文件移动到backup目录? (Y/N)"
if ($response -eq "Y" -or $response -eq "y") {
    $movedCount = 0
    foreach ($file in $filesToBackup) {
        $sourcePath = Join-Path -Path $rootDir -ChildPath $file
        $destPath = Join-Path -Path $backupDir -ChildPath $file
        
        # 如果目标文件已存在，添加时间戳
        if (Test-Path $destPath) {
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $fileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($file)
            $fileExt = [System.IO.Path]::GetExtension($file)
            $newFileName = "$fileNameWithoutExt-$timestamp$fileExt"
            $destPath = Join-Path -Path $backupDir -ChildPath $newFileName
        }
        
        # 移动文件
        try {
            Move-Item -Path $sourcePath -Destination $destPath -Force
            Write-Host "已移动: $file -> $destPath"
            $movedCount++
        }
        catch {
            Write-Host "移动失败: $file - $_" -ForegroundColor Red
        }
    }
    
    Write-Host "`n移动完成: 共移动 $movedCount 个文件到 $backupDir"
}
else {
    Write-Host "操作已取消，未移动任何文件。"
}
