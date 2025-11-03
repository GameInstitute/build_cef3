@echo off
REM CEF编译环境检查脚本 - Windows版本
REM 检查系统是否满足编译要求

setlocal EnableDelayedExpansion

echo ============================================
echo CEF编译环境检查 (Windows)
echo ============================================
echo.

set ERRORS=0
set WARNINGS=0

REM 检查Windows版本
echo [1] 操作系统
ver | find "10.0" >nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Windows 10/11
) else (
    echo [!!] 不支持的Windows版本，需要Windows 10+
    set /a ERRORS+=1
)
echo.

REM 检查Python
echo [2] Python
where python >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VER=%%i
    echo [OK] Python !PYTHON_VER!
) else (
    echo [!!] 未安装Python
    echo      下载: https://www.python.org/downloads/
    set /a ERRORS+=1
)
echo.

REM 检查Git
echo [3] Git
where git >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    for /f "tokens=3" %%i in ('git --version') do set GIT_VER=%%i
    echo [OK] Git !GIT_VER!
) else (
    echo [!!] 未安装Git
    echo      下载: https://git-scm.com/download/win
    set /a ERRORS+=1
)
echo.

REM 检查Visual Studio 2022
echo [4] Visual Studio 2022
set VS_PATH=C:\Program Files\Microsoft Visual Studio\2022
set VS_FOUND=0

if exist "%VS_PATH%\Enterprise\VC\Auxiliary\Build\vcvars64.bat" (
    echo [OK] Visual Studio 2022 Enterprise
    set VS_FOUND=1
) else if exist "%VS_PATH%\Professional\VC\Auxiliary\Build\vcvars64.bat" (
    echo [OK] Visual Studio 2022 Professional
    set VS_FOUND=1
) else if exist "%VS_PATH%\Community\VC\Auxiliary\Build\vcvars64.bat" (
    echo [OK] Visual Studio 2022 Community
    set VS_FOUND=1
) else (
    echo [!!] 未安装Visual Studio 2022
    echo      下载: https://visualstudio.microsoft.com/downloads/
    echo      需要安装"使用C++的桌面开发"工作负载
    set /a ERRORS+=1
)
echo.

REM 检查CMake
echo [5] CMake (可选)
where cmake >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    for /f "tokens=3" %%i in ('cmake --version ^| findstr /C:"version"') do set CMAKE_VER=%%i
    echo [OK] CMake !CMAKE_VER!
) else (
    echo [!!] 未安装CMake (推荐安装)
    echo      下载: https://cmake.org/download/
    set /a WARNINGS+=1
)
echo.

REM 检查磁盘空间
echo [6] 磁盘空间
for /f "tokens=3" %%i in ('dir /-c ^| find "bytes free"') do set SPACE=%%i
set SPACE_GB=0
set /a SPACE_GB=%SPACE%/1073741824

if %SPACE_GB% GEQ 150 (
    echo [OK] 可用空间: %SPACE_GB%GB ^(充足^)
) else if %SPACE_GB% GEQ 100 (
    echo [!!] 可用空间: %SPACE_GB%GB ^(建议150GB+^)
    set /a WARNINGS+=1
) else (
    echo [!!] 可用空间: %SPACE_GB%GB ^(不足，需要至少120GB^)
    set /a ERRORS+=1
)
echo.

REM 检查内存
echo [7] 系统内存
for /f "skip=1" %%p in ('wmic computersystem get totalphysicalmemory') do set RAM=%%p & goto :got_ram
:got_ram
set /a RAM_GB=%RAM%/1073741824

if %RAM_GB% GEQ 16 (
    echo [OK] 总内存: %RAM_GB%GB ^(充足^)
) else if %RAM_GB% GEQ 8 (
    echo [!!] 总内存: %RAM_GB%GB ^(建议16GB+^)
    set /a WARNINGS+=1
) else (
    echo [!!] 总内存: %RAM_GB%GB ^(不足，需要至少8GB^)
    set /a ERRORS+=1
)
echo.

REM 检查CPU
echo [8] CPU
for /f "skip=1" %%p in ('wmic cpu get NumberOfCores') do set CPU_CORES=%%p & goto :got_cpu
:got_cpu
echo [OK] CPU核心数: %CPU_CORES%

if %CPU_CORES% GEQ 8 (
    echo      预计编译时间: 4-6小时
) else if %CPU_CORES% GEQ 4 (
    echo      预计编译时间: 6-8小时
) else (
    echo      预计编译时间: 8-12小时
)
echo.

REM 检查.NET Framework (VS需要)
echo [9] .NET Framework
reg query "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v Version >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] .NET Framework 已安装
) else (
    echo [!!] .NET Framework 未安装
    set /a WARNINGS+=1
)
echo.

REM 检查Windows SDK
echo [10] Windows SDK
set SDK_FOUND=0
for /d %%i in ("C:\Program Files (x86)\Windows Kits\10\Include\*") do (
    set SDK_VER=%%~nxi
    if not "!SDK_VER!"=="." (
        if not "!SDK_VER!"==".." (
            echo [OK] Windows SDK !SDK_VER!
            set SDK_FOUND=1
            goto :sdk_done
        )
    )
)
:sdk_done

if %SDK_FOUND% EQU 0 (
    echo [!!] Windows SDK 未安装
    echo      通过Visual Studio Installer安装
    set /a WARNINGS+=1
)
echo.

REM 总结
echo ============================================
echo 检查结果总结
echo ============================================
echo.

if %ERRORS% EQU 0 (
    if %WARNINGS% EQU 0 (
        echo [OK] 系统满足所有编译要求！
        echo.
        echo 可以开始编译:
        echo   build-windows.bat
    ) else (
        echo [!!] 系统基本满足要求，但有 %WARNINGS% 个警告
        echo.
        echo 可以尝试编译，但可能遇到一些问题
    )
) else (
    echo [!!] 发现 %ERRORS% 个错误和 %WARNINGS% 个警告
    echo.
    echo 请先解决以下问题:
    echo.
    
    where python >nul 2>nul
    if %ERRORLEVEL% NEQ 0 (
        echo   - 安装Python 3.11+
        echo     https://www.python.org/downloads/
    )
    
    where git >nul 2>nul
    if %ERRORLEVEL% NEQ 0 (
        echo   - 安装Git for Windows
        echo     https://git-scm.com/download/win
    )
    
    if %VS_FOUND% EQU 0 (
        echo   - 安装Visual Studio 2022
        echo     https://visualstudio.microsoft.com/downloads/
        echo     选择"使用C++的桌面开发"工作负载
    )
    
    if %SPACE_GB% LSS 120 (
        echo   - 清理磁盘空间或使用更大的磁盘
    )
    
    if %RAM_GB% LSS 8 (
        echo   - 增加系统内存
    )
)

echo.
echo 详细说明请参考: scripts\README.md
echo.

pause

