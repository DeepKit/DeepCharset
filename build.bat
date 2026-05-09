@echo off
REM DeepCharset — Delphi 13.1 Build Script
call "%~dp0\..\scripts\env\delphi-13.1.bat"

echo Starting compilation...
setlocal

set MODE=%1
if "%MODE%"=="" set MODE=Debug

rem NOTE: madCollection removed. Source code does not actually use madExcept.
rem The {$DEFINE USE_MADEXCEPT} block in DeepCharset.dpr is disabled and the
rem local madExcept.pas is an empty stub. Re-enable this if you later adopt madCollection.

rem Common compiler flags
set COMMON=-B -NSSystem;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win -E"Win64\%MODE%" -N"Win64\%MODE%"

if /I "%MODE%"=="Debug" (
  %DCC64% %COMMON% -$D+ -$L+ -$V+ DeepCharset.dpr > build_output.txt 2>&1
) else (
  %DCC64% %COMMON% -$D- -$L- -$O+ DeepCharset.dpr > build_output.txt 2>&1
)

type build_output.txt

endlocal
