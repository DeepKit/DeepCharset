param(
  [string]$TargetDir = "C:\TestData",
  [string]$TargetEncoding = "UTF-8",
  [switch]$AddBOM = $false,
  [int]$Minutes = 10
)

# Long-run logging and stability test
# - Repeatedly processes target directory recursively
# - Intended to stress log rotation/archiving and buffer pooling

$exe = Join-Path $PSScriptRoot "..\DeepCharset.exe"
if (-not (Test-Path $exe)) {
  Write-Host "Executable not found: $exe" -ForegroundColor Red
  exit 1
}

$endTime = (Get-Date).AddMinutes($Minutes)
$iteration = 0

Write-Host "Starting long-run test for $Minutes minute(s) on $TargetDir" -ForegroundColor Cyan

while ((Get-Date) -lt $endTime) {
  $iteration++
  $args = @("-s", "auto", "-t", $TargetEncoding, "-r", "--verbose", $TargetDir)
  if ($AddBOM) { $args += "--add-bom" }
  Write-Host ("[#{0}] Iteration {1}: {2} {3}" -f (Get-Date).ToString("HH:mm:ss"), $iteration, $exe, ($args -join ' '))
  & $exe @args
  Start-Sleep -Seconds 2
}

Write-Host "Long-run test completed: iterations=$iteration" -ForegroundColor Green
