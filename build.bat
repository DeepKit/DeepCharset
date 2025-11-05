@echo off
echo Starting compilation...
setlocal
  
set MODE=%1
if "%MODE%"=="" set MODE=Debug
  
rem madCollection paths (adjust if installed elsewhere)
set MAD=D:\Program Files (x86)\madCollection
set MADPATHS=-U"%MAD%\madBasic\Source;%MAD%\madDisAsm\Source;%MAD%\madExcept\Source" -I"%MAD%\madBasic\Source;%MAD%\madDisAsm\Source;%MAD%\madExcept\Source"

if /I "%MODE%"=="Debug" (
  "D:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe" -B -$D+ -$L+ %MADPATHS% TransSuccess.dpr > build_output.txt 2>&1
) else (
  "D:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe" -B -$D- -$L- %MADPATHS% TransSuccess.dpr > build_output.txt 2>&1
)
  
type build_output.txt
  
endlocal
