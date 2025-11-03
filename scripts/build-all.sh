#!/bin/bash
# CEF全平台编译脚本
# 按顺序编译所有平台

set -e

CEF_BRANCH=${1:-6367}

echo "============================================"
echo "CEF全平台编译脚本"
echo "============================================"
echo "CEF分支: $CEF_BRANCH"
echo ""
echo "将依次编译以下平台:"
echo "  1. Linux x64"
echo "  2. Android arm64-v8a"
echo ""
echo "注意:"
echo "  - 总计需要约10-15小时"
echo "  - 需要约200GB磁盘空间"
echo "  - Windows平台请在Windows系统上单独编译"
echo ""

read -p "按回车键开始编译，或Ctrl+C取消..."

START_TIME=$(date +%s)

# 记录日志
LOG_FILE="build-all-$(date +%Y%m%d-%H%M%S).log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo ""
echo "============================================"
echo "开始编译 - $(date)"
echo "============================================"
echo ""

# 编译Linux
echo "[1/2] 编译 Linux x64..."
echo "开始时间: $(date)"
if [ -f "build-linux.sh" ]; then
    chmod +x build-linux.sh
    ./build-linux.sh $CEF_BRANCH
    echo "✓ Linux x64 编译完成！"
else
    echo "✗ 未找到 build-linux.sh"
    exit 1
fi

echo ""
echo "============================================"
echo ""

# 编译Android
echo "[2/2] 编译 Android arm64-v8a..."
echo "开始时间: $(date)"
if [ -f "build-android.sh" ]; then
    chmod +x build-android.sh
    ./build-android.sh $CEF_BRANCH
    echo "✓ Android arm64-v8a 编译完成！"
else
    echo "✗ 未找到 build-android.sh"
    exit 1
fi

echo ""
echo "============================================"
echo "全部编译完成！- $(date)"
echo "============================================"
echo ""

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
HOURS=$((ELAPSED / 3600))
MINUTES=$(((ELAPSED % 3600) / 60))

echo "总耗时: ${HOURS}小时 ${MINUTES}分钟"
echo ""
echo "编译产物位置:"
echo "  - Linux x64: output/linux_x64/"
echo "  - Android arm64: output/android_arm64/"
echo ""
echo "日志文件: $LOG_FILE"
echo ""

# 生成摘要报告
REPORT_FILE="BUILD_REPORT.txt"
cat > "$REPORT_FILE" << EOF
CEF全平台编译报告
========================================
编译时间: $(date)
CEF分支: $CEF_BRANCH
总耗时: ${HOURS}小时 ${MINUTES}分钟

编译平台:
✓ Linux x64
✓ Android arm64-v8a

编译产物:
$(find ../output -name "*.tar.bz2" -exec ls -lh {} \;)

磁盘使用:
$(du -sh ../output 2>/dev/null || echo "无法计算")

编译参数:
- proprietary_codecs: true
- ffmpeg_branding: Chrome
- is_official_build: true

详细日志: $LOG_FILE
========================================
EOF

echo "编译报告已保存到: $REPORT_FILE"
echo ""

