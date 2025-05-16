# Encoding detection test script

# Test files directory
$testFilesDir = ".\TestFiles"

# Create test files directory
if (-not (Test-Path $testFilesDir)) {
    New-Item -ItemType Directory -Path $testFilesDir | Out-Null
}

# Create test files with different encodings
function CreateTestFile($fileName, $content, $encoding) {
    $filePath = Join-Path $testFilesDir $fileName

    # Create file with specified encoding
    switch ($encoding) {
        "UTF8" {
            [System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)
            Write-Host "Created UTF-8 file: $fileName"
        }
        "UTF8-BOM" {
            [System.IO.File]::WriteAllText($filePath, $content, [System.Text.UTF8Encoding]::new($true))
            Write-Host "Created UTF-8+BOM file: $fileName"
        }
        "UTF16LE" {
            [System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::Unicode)
            Write-Host "Created UTF-16LE file: $fileName"
        }
        "UTF16BE" {
            [System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::BigEndianUnicode)
            Write-Host "Created UTF-16BE file: $fileName"
        }
        "ANSI" {
            [System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::Default)
            Write-Host "Created ANSI file: $fileName"
        }
        default {
            Write-Host "Unsupported encoding: $encoding"
        }
    }
}

# Create test files
# English test files
CreateTestFile "Test_English_UTF8.txt" "This is an English test file." "UTF8"
CreateTestFile "Test_English_UTF8BOM.txt" "This is an English test file with BOM." "UTF8-BOM"
CreateTestFile "Test_English_UTF16LE.txt" "This is an English test file in UTF-16LE." "UTF16LE"
CreateTestFile "Test_English_UTF16BE.txt" "This is an English test file in UTF-16BE." "UTF16BE"
CreateTestFile "Test_English_ANSI.txt" "This is an English test file in ANSI." "ANSI"

# Chinese test files
CreateTestFile "Test_Chinese_UTF8.txt" "This is a Chinese test file." "UTF8"
CreateTestFile "Test_Chinese_UTF8BOM.txt" "This is a Chinese test file with BOM." "UTF8-BOM"
CreateTestFile "Test_Chinese_UTF16LE.txt" "This is a Chinese test file in UTF-16LE." "UTF16LE"
CreateTestFile "Test_Chinese_UTF16BE.txt" "This is a Chinese test file in UTF-16BE." "UTF16BE"
CreateTestFile "Test_Chinese_ANSI.txt" "This is a Chinese test file in ANSI." "ANSI"

# Japanese test files
CreateTestFile "Test_Japanese_UTF8.txt" "This is a Japanese test file." "UTF8"
CreateTestFile "Test_Japanese_UTF8BOM.txt" "This is a Japanese test file with BOM." "UTF8-BOM"
CreateTestFile "Test_Japanese_UTF16LE.txt" "This is a Japanese test file in UTF-16LE." "UTF16LE"
CreateTestFile "Test_Japanese_UTF16BE.txt" "This is a Japanese test file in UTF-16BE." "UTF16BE"
CreateTestFile "Test_Japanese_ANSI.txt" "This is a Japanese test file in ANSI." "ANSI"

# Korean test files
CreateTestFile "Test_Korean_UTF8.txt" "This is a Korean test file." "UTF8"
CreateTestFile "Test_Korean_UTF8BOM.txt" "This is a Korean test file with BOM." "UTF8-BOM"
CreateTestFile "Test_Korean_UTF16LE.txt" "This is a Korean test file in UTF-16LE." "UTF16LE"
CreateTestFile "Test_Korean_UTF16BE.txt" "This is a Korean test file in UTF-16BE." "UTF16BE"
CreateTestFile "Test_Korean_ANSI.txt" "This is a Korean test file in ANSI." "ANSI"

# Mixed language test files
CreateTestFile "Test_Mixed_UTF8.txt" "This is a mixed language test file." "UTF8"
CreateTestFile "Test_Mixed_UTF8BOM.txt" "This is a mixed language test file with BOM." "UTF8-BOM"
CreateTestFile "Test_Mixed_UTF16LE.txt" "This is a mixed language test file in UTF-16LE." "UTF16LE"
CreateTestFile "Test_Mixed_UTF16BE.txt" "This is a mixed language test file in UTF-16BE." "UTF16BE"
CreateTestFile "Test_Mixed_ANSI.txt" "This is a mixed language test file in ANSI." "ANSI"

Write-Host "Test files created successfully!"
