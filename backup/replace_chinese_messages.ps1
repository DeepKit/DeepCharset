$iniFile = "ini/ko-KR.ini"
$chineseMessagesFile = "ini/ko-KR-ChineseMessages.txt"

# Read the content of both files
$iniContent = Get-Content -Path $iniFile -Raw -Encoding UTF8
$chineseMessages = Get-Content -Path $chineseMessagesFile -Raw -Encoding UTF8

# Find the position of [ChineseMessages] section in the INI file
$pattern = "\[ChineseMessages\][\s\S]*?(?=\[|$)"
if ($iniContent -match $pattern) {
    # Replace the [ChineseMessages] section with the new content
    $newContent = [regex]::Replace($iniContent, $pattern, "$chineseMessages`n")
    
    # Write the modified content back to the INI file
    [System.IO.File]::WriteAllText($iniFile, $newContent, [System.Text.Encoding]::UTF8)
    
    Write-Host "Successfully replaced [ChineseMessages] section in $iniFile"
}
else {
    Write-Host "$iniFile doesn't have [ChineseMessages] section"
}
