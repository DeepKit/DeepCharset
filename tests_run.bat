@echo off
setlocal
set DCC="D:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe"

REM Parse args
set OPENLOGS=0
set PERF=0
set QUICK=0
for %%A in (%*) do (
  if /I "%%~A"=="/openlogs" set OPENLOGS=1
  if /I "%%~A"=="/perf" set PERF=1
  if /I "%%~A"=="/quick" set QUICK=1
)

REM Go to project root (this script is placed at project root)
pushd "%~dp0"

REM Build self-test console app
cd Tests
%DCC% -B -U.. -E..\bin SelfTest_Encoding.dpr > ..\tests_build_output.txt 2>&1
set BUILD_RC=%ERRORLEVEL%

if not %BUILD_RC%==0 (
  echo Build failed. See tests_build_output.txt
  type ..\tests_build_output.txt
  popd
  exit /b %BUILD_RC%
)

REM Run self-test app (pass through args like /crit /cp /quick)
cd ..\bin
if exist SelfTest_Encoding.exe (
  echo Running SelfTest_Encoding.exe ...
  echo Args: %*
  .\SelfTest_Encoding.exe %*
  if %PERF%==1 (
    echo Measuring performance... (SelfTest_Encoding.exe /crit)
    powershell -NoProfile -Command "\
      $root=Split-Path -Parent $MyInvocation.MyCommand.Path; \
      $log=Join-Path $root 'tmp_tests\\perf_log.txt'; \
      if(!(Test-Path (Join-Path $root 'tmp_tests'))){ New-Item -ItemType Directory -Path (Join-Path $root 'tmp_tests') | Out-Null }; \
      $res=Measure-Command { .\\SelfTest_Encoding.exe /crit }; \
      $line=('[PERF] crit_elapsed_ms=' + [int]$res.TotalMilliseconds + ' timestamp=' + (Get-Date -Format o)); \
      $line | Tee-Object -FilePath $log -Append; \
      Write-Host $line; \
    "
  )
) else (
  echo SelfTest_Encoding.exe not found.
)

popd

REM Show brief log summary if exists
if exist "%~dp0tmp_tests\selftest_log.txt" (
  echo === Self Test Log (tail) ===
  echo (use /crit for critical tests, /cp for cross-codepage, /quick for ultra-fast smoke test)
  powershell -NoProfile -Command "Get-Content -Path '%~dp0tmp_tests\selftest_log.txt' -Tail 200"
) else (
  echo selftest_log.txt not found under tmp_tests.
)

REM Optionally open logs
if %OPENLOGS%==1 (
  if exist "%~dp0tmp_tests\selftest_log.txt" start notepad "%~dp0tmp_tests\selftest_log.txt"
  if exist "%~dp0tmp_tests\convert_trace.txt" start notepad "%~dp0tmp_tests\convert_trace.txt"
)

endlocal
