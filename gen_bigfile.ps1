param(
  [int]$SizeMB = 200,
  [string]$OutFile = "tmp_tests\big_utf8.txt"
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root
$dir = Join-Path $root 'tmp_tests'
if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

$chunk = "A" * 2048 + "中文😀" + [Environment]::NewLine
$enc = New-Object System.Text.UTF8Encoding($false) # UTF-8 no BOM
$bytes = $enc.GetBytes($chunk)

$outPath = Join-Path $root $OutFile
$fs = [System.IO.File]::Open($outPath, [System.IO.FileMode]::Create)
try {
  $target = $SizeMB * 1024 * 1024
  $written = 0
  while ($written -lt $target) {
    $fs.Write($bytes, 0, $bytes.Length)
    $written += $bytes.Length
  }
}
finally {
  $fs.Close()
}

Write-Host "Generated: $outPath ($((Get-Item $outPath).Length) bytes)"
