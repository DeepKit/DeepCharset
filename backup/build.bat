@echo off
setlocal enabledelayedexpansion

REM 设置编译器和工具路径
set DELPHI_BIN=C:\Program Files (x86)\Embarcadero\Studio\23.0\bin
if not exist "%DELPHI_BIN%" set DELPHI_BIN=C:\Program Files (x86)\Embarcadero\Studio\22.0\bin
if not exist "%DELPHI_BIN%" set DELPHI_BIN=C:\Program Files (x86)\Embarcadero\Studio\21.0\bin
if not exist "%DELPHI_BIN%" set DELPHI_BIN=C:\Program Files (x86)\Embarcadero\Studio\20.0\bin
set MSBuild="%DELPHI_BIN%\rsvars.bat"
set DCC32="%DELPHI_BIN%\dcc32.exe"
set DUNITX_DIR=%CD%\libs\DUnitX\Source
set OUTPUT_DIR=bin
set TEST_OUTPUT_DIR=testresults

echo ===================================
echo 编码转换工具自动构建脚本
echo ===================================

REM 检查参数
set BUILD_MODE=Release
set RUN_TESTS=1
set CLEAN=0

:parse_args
if "%~1"=="" goto end_parse_args
if /i "%~1"=="--debug" set BUILD_MODE=Debug
if /i "%~1"=="--release" set BUILD_MODE=Release
if /i "%~1"=="--no-tests" set RUN_TESTS=0
if /i "%~1"=="--clean" set CLEAN=1
shift
goto parse_args
:end_parse_args

echo 构建模式: %BUILD_MODE%
echo 运行测试: %RUN_TESTS%
echo 清理旧文件: %CLEAN%

REM 创建输出目录
if not exist %OUTPUT_DIR% mkdir %OUTPUT_DIR%
if not exist %TEST_OUTPUT_DIR% mkdir %TEST_OUTPUT_DIR%

REM 清理旧文件
if %CLEAN%==1 (
  echo 清理旧文件...
  del /q /s %OUTPUT_DIR%\*
  del /q /s %TEST_OUTPUT_DIR%\*
  del /q *.dcu
  del /q /s __history\*
  echo 清理完成
)

REM 设置Delphi环境
echo 设置Delphi编译环境...
call %MSBuild%

REM 编译测试程序
echo 编译测试程序...
%DCC32% EncodingTestRunner.dpr -B -$D+ -$L+ -$Y+ -Q -O- -DDEBUG -E%OUTPUT_DIR% -U%DUNITX_DIR%

if errorlevel 1 (
  echo 测试程序编译失败
  exit /b 1
)

REM 编译主程序
echo 编译主程序...
%DCC32% EncodingConverter.dpr -B -$D+ -$L+ -$Y+ -Q -DDEBUG -E%OUTPUT_DIR%

if errorlevel 1 (
  echo 主程序编译失败
  exit /b 1
)

echo 编译完成，输出到 %OUTPUT_DIR% 目录

REM 运行测试
if %RUN_TESTS%==1 (
  echo 运行单元测试...
  cd %OUTPUT_DIR%
  EncodingTestRunner.exe -xml:%TEST_OUTPUT_DIR%\TestResults.xml

  if errorlevel 1 (
    echo 测试失败
    cd ..
    exit /b 1
  )

  echo 测试通过
  cd ..

  REM 运行GUI测试
  echo 运行GUI测试...
  cd %OUTPUT_DIR%
  EncodingTestRunner.exe -category:"User Interface" -xml:%TEST_OUTPUT_DIR%\GUITestResults.xml

  if errorlevel 1 (
    echo GUI测试失败
    cd ..
    exit /b 1
  )

  echo GUI测试通过
  cd ..
)

echo ===================================
echo 构建成功!
echo ===================================

REM 显示构建信息
echo 主程序: %OUTPUT_DIR%\EncodingConverter.exe
echo 测试程序: %OUTPUT_DIR%\EncodingTestRunner.exe
echo 测试结果: %TEST_OUTPUT_DIR%\TestResults.xml

exit /b 0