#!/bin/bash
# CEF编译清理脚本 - Linux/macOS版本
# 用于清理编译过程中产生的临时文件，节省磁盘空间

set -e

echo "============================================"
echo "CEF编译清理脚本 (Linux/macOS)"
echo "============================================"
echo ""
echo "此脚本将清理编译过程中的临时文件"
echo "可节省约50-80GB磁盘空间"
echo ""
echo "清理选项:"
echo "  [1] 编译中间文件 (out目录)"
echo "  [2] 下载缓存"
echo "  [3] 所有编译文件 (保留output目录)"
echo "  [4] 取消"
echo ""

read -p "请选择清理选项 [1-4]: " choice

case $choice in
    1)
        echo ""
        echo "[清理中间文件]"
        echo ""
        
        # Windows中间文件
        if [ -d "cef_build_windows/chromium/src/out" ]; then
            echo "正在清理: cef_build_windows/chromium/src/out"
            SIZE=$(du -sh cef_build_windows/chromium/src/out 2>/dev/null | cut -f1)
            rm -rf cef_build_windows/chromium/src/out
            echo "已清理！(约 $SIZE)"
        fi
        
        # Linux中间文件
        if [ -d "cef_build_linux/chromium/src/out" ]; then
            echo "正在清理: cef_build_linux/chromium/src/out"
            SIZE=$(du -sh cef_build_linux/chromium/src/out 2>/dev/null | cut -f1)
            rm -rf cef_build_linux/chromium/src/out
            echo "已清理！(约 $SIZE)"
        fi
        
        # Android中间文件
        if [ -d "cef_build_android/chromium/src/out" ]; then
            echo "正在清理: cef_build_android/chromium/src/out"
            SIZE=$(du -sh cef_build_android/chromium/src/out 2>/dev/null | cut -f1)
            rm -rf cef_build_android/chromium/src/out
            echo "已清理！(约 $SIZE)"
        fi
        
        echo ""
        echo "清理完成！"
        ;;
        
    2)
        echo ""
        echo "[清理下载缓存]"
        echo ""
        
        # Windows下载缓存
        if [ -d "cef_build_windows/download" ]; then
            echo "正在清理: cef_build_windows/download"
            SIZE=$(du -sh cef_build_windows/download 2>/dev/null | cut -f1)
            rm -rf cef_build_windows/download
            echo "已清理！(约 $SIZE)"
        fi
        
        # Linux下载缓存
        if [ -d "cef_build_linux/download" ]; then
            echo "正在清理: cef_build_linux/download"
            SIZE=$(du -sh cef_build_linux/download 2>/dev/null | cut -f1)
            rm -rf cef_build_linux/download
            echo "已清理！(约 $SIZE)"
        fi
        
        # Android下载缓存
        if [ -d "cef_build_android/download" ]; then
            echo "正在清理: cef_build_android/download"
            SIZE=$(du -sh cef_build_android/download 2>/dev/null | cut -f1)
            rm -rf cef_build_android/download
            echo "已清理！(约 $SIZE)"
        fi
        
        # depot_tools缓存
        for build_dir in cef_build_*/depot_tools/.cipd; do
            if [ -d "$build_dir" ]; then
                echo "正在清理: $build_dir"
                rm -rf "$build_dir"
                echo "已清理！"
            fi
        done
        
        echo ""
        echo "清理完成！"
        ;;
        
    3)
        echo ""
        echo "[清理所有编译文件]"
        echo ""
        read -p "确认删除所有编译文件? (保留output目录) [y/N]: " confirm
        
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "操作已取消"
            exit 0
        fi
        
        echo ""
        
        # Windows编译目录
        if [ -d "cef_build_windows" ]; then
            echo "正在清理: cef_build_windows"
            SIZE=$(du -sh cef_build_windows 2>/dev/null | cut -f1)
            rm -rf cef_build_windows
            echo "已清理！(约 $SIZE)"
        fi
        
        # Linux编译目录
        if [ -d "cef_build_linux" ]; then
            echo "正在清理: cef_build_linux"
            SIZE=$(du -sh cef_build_linux 2>/dev/null | cut -f1)
            rm -rf cef_build_linux
            echo "已清理！(约 $SIZE)"
        fi
        
        # Android编译目录
        if [ -d "cef_build_android" ]; then
            echo "正在清理: cef_build_android"
            SIZE=$(du -sh cef_build_android 2>/dev/null | cut -f1)
            rm -rf cef_build_android
            echo "已清理！(约 $SIZE)"
        fi
        
        echo ""
        echo "清理完成！源码需要重新下载"
        ;;
        
    4)
        echo "操作已取消"
        exit 0
        ;;
        
    *)
        echo "无效选项！"
        exit 1
        ;;
esac

echo ""
echo "============================================"
echo "清理结束"
echo "============================================"
echo ""
echo "保留的目录:"
if [ -d "output" ]; then
    echo "  ✓ output/ (编译产物)"
    du -sh output/ 2>/dev/null || true
fi
echo ""

# 显示当前磁盘使用
echo "当前磁盘使用:"
df -h . | tail -1
echo ""

