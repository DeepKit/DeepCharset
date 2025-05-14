# 移动未使用的文件到backup目录
# 此脚本用于将未使用的文件移动到backup目录

# 定义根目录
$rootDir = "d:\SynologyDrive\Progs\_Delphi\TransSuccess"

# 定义备份目录
$backupDir = "$rootDir\backup"

# 创建备份目录（如果不存在）
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
    Write-Host "创建备份目录: $backupDir"
}

# 定义核心文件列表（这些文件不会被移动）
$coreFiles = @(
    # 主程序文件
    "TransSuccess.dpr",
    "TransSuccess.dproj",
    "TransSuccess.res",

    # 主窗体文件
    "ViewMainCode.pas",
    "ViewMainCode.dfm",

    # 控制器文件
    "ControllerEncoding.pas",
    "ControllerEncodingEnhanced.pas",
    "ControllerLanguage.pas",

    # 模型文件
    "ModelEncoding.pas",
    "ModelConfig.pas",
    "ModelLanguage.pas",

    # 视图文件
    "ViewSynEdit.pas",
    "ViewSynEdit.dfm",

    # 辅助文件
    "HelperFiles.pas",
    "HelperUI.pas",
    "HelperLanguage.pas",

    # 工具类文件
    "UtilsTypes.pas",
    "UtilsEncodingTypes.pas",
    "UtilsEncodingLogger.pas",

    # 编码检测和转换相关文件
    "UtilsEncodingBOM_Improved.pas",
    "UtilsEncodingUTF8Detector_Improved.pas",
    "ChineseEncodingDetector_Improved.pas",
    "EncodingConverter_Improved.pas",
    "UTF8BOMConverter_Improved.pas",

    # 文档文件
    "detect.md",
    "better.md",
    "improve.md",

    # 脚本文件
    "AnalyzeFiles.ps1",
    "MoveUnusedFiles.ps1",

    # 配置文件
    "TransSuccess.cfg",

    # 其他必要文件
    ".gitignore"
)

# 获取所有文件
$allFiles = Get-ChildItem -Path $rootDir -File | Select-Object -ExpandProperty Name

# 找出未使用的文件
$unusedFiles = $allFiles | Where-Object { $coreFiles -notcontains $_ }

# 输出分析结果
Write-Host "文件分析结果:"
Write-Host "总文件数: $($allFiles.Count)"
Write-Host "核心文件数: $($coreFiles.Count)"
Write-Host "未使用的文件数: $($unusedFiles.Count)"

# 输出未使用的文件列表
Write-Host "`n未使用的文件列表:"
foreach ($file in $unusedFiles | Sort-Object) {
    Write-Host "  $file"
}

# 询问是否移动文件
$response = Read-Host "是否将未使用的文件移动到backup目录? (Y/N)"
if ($response -eq "Y" -or $response -eq "y") {
    $movedCount = 0
    foreach ($file in $unusedFiles) {
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
