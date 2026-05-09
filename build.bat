@echo off
REM DeepCharset — Delphi 13.1 Build Script
call "%~dp0\..\scripts\env\delphi-13.1.bat"

echo Starting compilation...
setlocal

set MODE=%1
if "%MODE%"=="" set MODE=Debug

rem madCollection paths (BDS24 版本)
set MAD=D:\Program Files (x86)\madCollection
set MADPATHS=-U"%MAD%\madBasic\Source;%MAD%\madDisAsm\Source;%MAD%\madExcept\Source" -I"%MAD%\madBasic\Source;%MAD%\madDisAsm\Source;%MAD%\madExcept\Source"

rem Common compiler flags
set COMMON=-B -NSSystem;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win -E"Win64\%MODE%" -N"Win64\%MODE%"

if /I "%MODE%"=="Debug" (
  %DCC64% %COMMON% -$D+ -$L+ -$V+ %MADPATHS% DeepCharset.dpr > build_output.txt 2>&1
) else (
  %DCC64% %COMMON% -$D- -$L- -$O+ %MADPATHS% DeepCharset.dpr > build_output.txt 2>&1
)

type build_output.txt

endlocal
