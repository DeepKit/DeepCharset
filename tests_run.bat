@echo off
setlocal
set DCC="D:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe"

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

REM Run self-test app
cd ..\bin
if exist SelfTest_Encoding.exe (
  echo Running SelfTest_Encoding.exe ...
  .\SelfTest_Encoding.exe
) else (
  echo SelfTest_Encoding.exe not found.
)

popd

REM Show brief log summary if exists
if exist "%~dp0tmp_tests\selftest_log.txt" (
  echo === Self Test Log (tail) ===
  powershell -NoProfile -Command "Get-Content -Path '%~dp0tmp_tests\selftest_log.txt' -Tail 20"
) else (
  echo selftest_log.txt not found under tmp_tests.
)

endlocal
