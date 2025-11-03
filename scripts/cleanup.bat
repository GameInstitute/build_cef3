@echo off
REM CEF编译清理脚本 - Windows版本
REM 用于清理编译过程中产生的临时文件，节省磁盘空间

setlocal EnableDelayedExpansion

echo ============================================
echo CEF编译清理脚本 (Windows)
echo ============================================
echo.
echo 此脚本将清理编译过程中的临时文件
echo 可节省约50-80GB磁盘空间
echo.
echo 清理内容:
echo   [1] 编译中间文件 (out目录)
echo   [2] 下载缓存
echo   [3] 所有编译文件 (保留output目录)
echo   [4] 取消
echo.

set /p choice="请选择清理选项 [1-4]: "

if "%choice%"=="1" goto :clean_intermediate
if "%choice%"=="2" goto :clean_cache
if "%choice%"=="3" goto :clean_all
if "%choice%"=="4" goto :cancel
goto :invalid

:clean_intermediate
echo.
echo [清理中间文件]
echo.

set TOTAL_SIZE=0

if exist "cef_build_windows\chromium\src\out" (
    echo 正在清理: cef_build_windows\chromium\src\out
    for /f "tokens=3" %%a in ('dir /s /-c "cef_build_windows\chromium\src\out" 2^>nul ^| find "个文件"') do set SIZE=%%a
    rmdir /s /q "cef_build_windows\chromium\src\out" 2>nul
    echo 已清理！
)

echo.
echo 清理完成！
echo.
goto :end

:clean_cache
echo.
echo [清理下载缓存]
echo.

if exist "cef_build_windows\download" (
    echo 正在清理: cef_build_windows\download
    rmdir /s /q "cef_build_windows\download" 2>nul
    echo 已清理！
)

if exist "cef_build_windows\depot_tools\.cipd" (
    echo 正在清理: depot_tools缓存
    rmdir /s /q "cef_build_windows\depot_tools\.cipd" 2>nul
    echo 已清理！
)

echo.
echo 清理完成！
echo.
goto :end

:clean_all
echo.
echo [清理所有编译文件]
echo.
set /p confirm="确认删除所有编译文件? (保留output目录) [Y/N]: "
if /i not "%confirm%"=="Y" goto :cancel

echo.
if exist "cef_build_windows" (
    echo 正在清理: cef_build_windows
    rmdir /s /q "cef_build_windows" 2>nul
    echo 已清理！
)

echo.
echo 清理完成！源码需要重新下载
echo.
goto :end

:invalid
echo 无效选项！
pause
exit /b 1

:cancel
echo 操作已取消
goto :end

:end
echo ============================================
echo 清理结束
echo ============================================
echo.
echo 保留的目录:
if exist "output" (
    echo   ✓ output\ (编译产物)
)
echo.
pause

