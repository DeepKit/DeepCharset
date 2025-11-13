param(
  [string]$Target = "C:\\MyFiles",
  [string]$Report = "C:\\tmp\\report.json",
  [string]$Enc = "UTF-8"
)

$exe = Join-Path $PSScriptRoot "..\TransSuccess.exe"
if (-not (Test-Path $exe)) {
  Write-Host "Executable not found: $exe" -ForegroundColor Red
  exit 1
}

# Run once with JSON report
& $exe --verbose --report $Report -s auto -t $Enc $Target

if (Test-Path $Report) {
  Write-Host "Report saved: $Report" -ForegroundColor Green
  Get-Content $Report | Select-Object -First 20 | ForEach-Object { $_ }
} else {
  Write-Host "No report generated." -ForegroundColor Yellow
}
