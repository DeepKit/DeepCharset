@echo off
echo Starting compilation...
setlocal

set MODE=%1
if "%MODE%"=="" set MODE=Debug

rem madCollection paths
set MAD=D:\Program Files (x86)\madCollection
set MADPATHS=-U"%MAD%\madBasic\Source;%MAD%\madDisAsm\Source;%MAD%\madExcept\Source" -I"%MAD%\madBasic\Source;%MAD%\madDisAsm\Source;%MAD%\madExcept\Source"

rem Common compiler flags
set DCC=D:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe
set COMMON=-B -NSSystem;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win -U"D:\Program Files (x86)\Embarcadero\Studio\23.0\lib\Win64\release" -E"Win64\%MODE%" -N"Win64\%MODE%"

if /I "%MODE%"=="Debug" (
  "%DCC%" %COMMON% -$D+ -$L+ -$V+ %MADPATHS% DeepCharset.dpr > build_output.txt 2>&1
) else (
  "%DCC%" %COMMON% -$D- -$L- -$O+ %MADPATHS% DeepCharset.dpr > build_output.txt 2>&1
)

type build_output.txt

endlocal
