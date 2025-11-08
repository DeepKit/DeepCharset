@echo off
setlocal
pushd "%~dp0"
set LOGDIR=%~dp0tmp_tests

if exist "%LOGDIR%\selftest_log.txt" (
  start notepad "%LOGDIR%\selftest_log.txt"
) else (
  echo selftest_log.txt not found under tmp_tests.
)

if exist "%LOGDIR%\convert_trace.txt" (
  start notepad "%LOGDIR%\convert_trace.txt"
) else (
  echo convert_trace.txt not found under tmp_tests.
)

popd
endlocal
