$template = Get-Content -Path "log_section_template.txt" -Raw
$iniFiles = Get-ChildItem -Path "ini" -Filter "*.ini" | Where-Object { $_.Name -ne "TransSuccess.ini" -and $_.Name -ne "en-US.ini" -and $_.Name -ne "zh-CN.ini" -and $_.Name -ne "ja-JP.ini" }

foreach ($file in $iniFiles) {
    Write-Host "Processing $($file.Name)..."
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    
    # Check if the file already has [Log] section
    if ($content -notmatch "\[Log\]") {
        # Find the position to insert the template (before [EncodingDescriptions] section)
        if ($content -match "\[EncodingDescriptions\]") {
            $newContent = $content -replace "\[EncodingDescriptions\]", "$template`n[EncodingDescriptions]"
            [System.IO.File]::WriteAllText($file.FullName, $newContent, [System.Text.Encoding]::UTF8)
            Write-Host "Added [Log] and [ChineseMessages] sections to $($file.Name)"
        }
        else {
            # If [EncodingDescriptions] section doesn't exist, append at the end
            $newContent = $content + "`n" + $template
            [System.IO.File]::WriteAllText($file.FullName, $newContent, [System.Text.Encoding]::UTF8)
            Write-Host "Appended [Log] and [ChineseMessages] sections to $($file.Name)"
        }
    }
    else {
        Write-Host "$($file.Name) already has [Log] section, skipping..."
    }
}

Write-Host "Done!"
