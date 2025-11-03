@echo off
REM CEF Windows x64本地编译脚本
REM 使用方法: build-windows.bat [CEF分支号]
REM 示例: build-windows.bat 6367

setlocal EnableDelayedExpansion

REM ============================================
REM 配置参数
REM ============================================

REM CEF分支号 (默认6367 = CEF 131)
set CEF_BRANCH=%1
if "%CEF_BRANCH%"=="" set CEF_BRANCH=6367

REM 工作目录
set WORK_DIR=%CD%\cef_build_windows
set DOWNLOAD_DIR=%WORK_DIR%\download
set DEPOT_TOOLS_DIR=%WORK_DIR%\depot_tools
set OUTPUT_DIR=%CD%\output\windows_x64

REM Visual Studio版本
set GYP_MSVS_VERSION=2022

REM GN编译参数
set GN_DEFINES=proprietary_codecs=true ffmpeg_branding="Chrome" is_official_build=true

echo ============================================
echo CEF Windows x64 本地编译脚本
echo ============================================
echo CEF分支: %CEF_BRANCH%
echo 工作目录: %WORK_DIR%
echo 输出目录: %OUTPUT_DIR%
echo ============================================
echo.

REM ============================================
REM 检查必要工具
REM ============================================

echo [1/8] 检查必要工具...
where python >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 未找到Python，请先安装Python 3.11+
    exit /b 1
)

where cmake >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo 警告: 未找到CMake，建议安装
)

where git >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 未找到Git，请先安装Git
    exit /b 1
)

echo 工具检查完成！
echo.

REM ============================================
REM 设置Visual Studio环境
REM ============================================

echo [2/8] 设置Visual Studio 2022环境...

set VS_PATH=C:\Program Files\Microsoft Visual Studio\2022
set VCVARS_BAT=
if exist "%VS_PATH%\Enterprise\VC\Auxiliary\Build\vcvars64.bat" (
    set VCVARS_BAT=%VS_PATH%\Enterprise\VC\Auxiliary\Build\vcvars64.bat
) else if exist "%VS_PATH%\Professional\VC\Auxiliary\Build\vcvars64.bat" (
    set VCVARS_BAT=%VS_PATH%\Professional\VC\Auxiliary\Build\vcvars64.bat
) else if exist "%VS_PATH%\Community\VC\Auxiliary\Build\vcvars64.bat" (
    set VCVARS_BAT=%VS_PATH%\Community\VC\Auxiliary\Build\vcvars64.bat
)

if "%VCVARS_BAT%"=="" (
    echo 错误: 未找到Visual Studio 2022，请先安装
    echo 下载地址: https://visualstudio.microsoft.com/downloads/
    exit /b 1
)

echo 找到Visual Studio: %VCVARS_BAT%
call "%VCVARS_BAT%"
echo.

REM ============================================
REM 创建工作目录
REM ============================================

echo [3/8] 创建工作目录...
if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
cd /d "%WORK_DIR%"
echo.

REM ============================================
REM 下载automate-git.py
REM ============================================

echo [4/8] 下载automate-git.py...
if not exist "automate-git.py" (
    echo 正在从Bitbucket下载...
    powershell -Command "Invoke-WebRequest -Uri 'https://bitbucket.org/chromiumembedded/cef/raw/master/tools/automate/automate-git.py' -OutFile 'automate-git.py'"
    if !ERRORLEVEL! NEQ 0 (
        echo 错误: 下载失败
        exit /b 1
    )
)
echo automate-git.py准备就绪！
echo.

REM ============================================
REM 运行automate-git.py
REM ============================================

echo [5/8] 开始编译CEF (这可能需要4-8小时)...
echo 开始时间: %TIME%
echo.
echo 编译参数:
echo - CEF分支: %CEF_BRANCH%
echo - 架构: x64
echo - 专有编解码器: 启用
echo - 调试版本: 禁用
echo - 最小化分发: 启用
echo.

python automate-git.py ^
    --download-dir="%DOWNLOAD_DIR%" ^
    --depot-tools-dir="%DEPOT_TOOLS_DIR%" ^
    --branch=%CEF_BRANCH% ^
    --x64-build ^
    --with-proprietary-codecs ^
    --no-debug-build ^
    --minimal-distrib ^
    --force-build ^
    --build-target=cefsimple

if %ERRORLEVEL% NEQ 0 (
    echo 错误: 编译失败，请检查日志
    exit /b 1
)

echo.
echo 编译完成！结束时间: %TIME%
echo.

REM ============================================
REM 查找编译产物
REM ============================================

echo [6/8] 查找编译产物...
set BINARY_DISTRIB_DIR=%WORK_DIR%\chromium\src\cef\binary_distrib

if not exist "%BINARY_DISTRIB_DIR%" (
    echo 错误: 未找到编译产物目录
    exit /b 1
)

cd /d "%BINARY_DISTRIB_DIR%"
for /f "delims=" %%i in ('dir /b /o-d cef_binary_*_windows64_minimal.tar.bz2 2^>nul') do (
    set ARTIFACT_FILE=%%i
    goto :found_artifact
)

:found_artifact
if "%ARTIFACT_FILE%"=="" (
    echo 错误: 未找到编译产物文件
    exit /b 1
)

echo 找到编译产物: %ARTIFACT_FILE%
echo.

REM ============================================
REM 解压编译产物
REM ============================================

echo [7/8] 解压编译产物...
cd /d "%OUTPUT_DIR%"

REM 复制压缩包
copy "%BINARY_DISTRIB_DIR%\%ARTIFACT_FILE%" "%OUTPUT_DIR%\"

REM 解压
echo 正在解压 %ARTIFACT_FILE%...
tar -xjf "%ARTIFACT_FILE%"

if %ERRORLEVEL% NEQ 0 (
    echo 警告: tar解压失败，尝试使用7-Zip...
    where 7z >nul 2>nul
    if !ERRORLEVEL! NEQ 0 (
        echo 请手动解压文件: %OUTPUT_DIR%\%ARTIFACT_FILE%
    ) else (
        7z x "%ARTIFACT_FILE%" -so | 7z x -si -ttar
    )
)

echo 解压完成！
echo.

REM ============================================
REM 生成编译摘要
REM ============================================

echo [8/8] 生成编译摘要...

set SUMMARY_FILE=%OUTPUT_DIR%\BUILD_INFO.txt
(
    echo CEF Windows x64 编译信息
    echo ========================================
    echo 编译时间: %DATE% %TIME%
    echo CEF分支: %CEF_BRANCH%
    echo 编译机器: %COMPUTERNAME%
    echo Visual Studio: 2022
    echo 编译参数:
    echo   - proprietary_codecs: true
    echo   - ffmpeg_branding: Chrome
    echo   - is_official_build: true
    echo.
    echo 编译产物:
    echo   - 压缩包: %ARTIFACT_FILE%
    echo   - 位置: %OUTPUT_DIR%
    echo.
    echo 包含的编解码器:
    echo   - H.264/AVC
    echo   - H.265/HEVC
    echo   - VP8/VP9
    echo   - AAC
    echo ========================================
) > "%SUMMARY_FILE%"

echo 编译摘要已保存到: %SUMMARY_FILE%
echo.

REM ============================================
REM 完成
REM ============================================

echo ============================================
echo 编译完成！
echo ============================================
echo.
echo 编译产物位置: %OUTPUT_DIR%
echo 压缩包: %ARTIFACT_FILE%
echo.
echo 下一步:
echo 1. 查看编译信息: type "%SUMMARY_FILE%"
echo 2. 解压后的目录包含所有必要的头文件和库文件
echo 3. 参考README.md集成到您的项目中
echo.

pause

