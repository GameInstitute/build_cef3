#!/bin/bash
# CEF Linux x64本地编译脚本
# 使用方法: ./build-linux.sh [CEF分支号]
# 示例: ./build-linux.sh 6367

set -e  # 遇到错误立即退出

# ============================================
# 配置参数
# ============================================

# CEF分支号 (默认6367 = CEF 131)
CEF_BRANCH=${1:-6367}

# 工作目录
WORK_DIR="$PWD/cef_build_linux"
DOWNLOAD_DIR="$WORK_DIR/download"
DEPOT_TOOLS_DIR="$WORK_DIR/depot_tools"
OUTPUT_DIR="$PWD/output/linux_x64"

# GN编译参数
export GN_DEFINES="proprietary_codecs=true ffmpeg_branding=\"Chrome\" is_official_build=true"
export CEF_ARCHIVE_FORMAT="tar.bz2"

echo "============================================"
echo "CEF Linux x64 本地编译脚本"
echo "============================================"
echo "CEF分支: $CEF_BRANCH"
echo "工作目录: $WORK_DIR"
echo "输出目录: $OUTPUT_DIR"
echo "============================================"
echo ""

# ============================================
# 检查操作系统
# ============================================

echo "[1/9] 检查操作系统..."
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "错误: 此脚本仅支持Linux系统"
    exit 1
fi

# 检查是否为Ubuntu/Debian
if ! command -v apt-get &> /dev/null; then
    echo "警告: 未检测到apt-get，某些依赖可能需要手动安装"
fi

echo "操作系统检查通过！"
echo ""

# ============================================
# 检查和安装必要工具
# ============================================

echo "[2/9] 检查必要工具..."

# 检查Python
if ! command -v python3 &> /dev/null; then
    echo "错误: 未找到Python3，请先安装"
    exit 1
fi

PYTHON_CMD=python3
echo "Python版本: $($PYTHON_CMD --version)"

# 检查Git
if ! command -v git &> /dev/null; then
    echo "错误: 未找到Git，请先安装"
    exit 1
fi

echo "Git版本: $(git --version)"
echo "工具检查完成！"
echo ""

# ============================================
# 安装编译依赖
# ============================================

echo "[3/9] 安装编译依赖..."
echo "这可能需要sudo权限..."
echo ""

if command -v apt-get &> /dev/null; then
    echo "检测到apt-get，安装Ubuntu/Debian依赖..."
    
    # 更新包列表
    sudo apt-get update
    
    # 安装基础构建工具
    sudo apt-get install -y \
        build-essential \
        ninja-build \
        cmake \
        pkg-config \
        git \
        python3 \
        python3-pip \
        curl \
        wget
    
    # 安装CEF依赖库
    sudo apt-get install -y \
        libglib2.0-dev \
        libgtk-3-dev \
        libpango1.0-dev \
        libatk1.0-dev \
        libcairo2-dev \
        libx11-dev \
        libxcomposite-dev \
        libxdamage-dev \
        libxext-dev \
        libxfixes-dev \
        libxrandr-dev \
        libgbm-dev \
        libdrm-dev \
        libxkbcommon-dev \
        libnss3-dev \
        libcups2-dev \
        libxss-dev \
        libasound2-dev \
        libpci-dev \
        libpulse-dev \
        libudev-dev \
        libdbus-1-dev \
        libxtst-dev
    
    echo "依赖安装完成！"
else
    echo "警告: 无法自动安装依赖，请手动安装以下包："
    echo "  - build-essential, cmake, ninja-build"
    echo "  - libgtk-3-dev, libnss3-dev, libcups2-dev"
    echo "  - 更多依赖请参考CEF文档"
    read -p "按回车继续..."
fi

echo ""

# ============================================
# 创建工作目录
# ============================================

echo "[4/9] 创建工作目录..."
mkdir -p "$WORK_DIR"
mkdir -p "$OUTPUT_DIR"
cd "$WORK_DIR"
echo "工作目录已创建: $WORK_DIR"
echo ""

# ============================================
# 下载automate-git.py
# ============================================

echo "[5/9] 下载automate-git.py..."
if [ ! -f "automate-git.py" ]; then
    echo "正在从Bitbucket下载..."
    curl -o automate-git.py https://bitbucket.org/chromiumembedded/cef/raw/master/tools/automate/automate-git.py
    
    if [ $? -ne 0 ]; then
        echo "错误: 下载失败"
        exit 1
    fi
fi

chmod +x automate-git.py
echo "automate-git.py准备就绪！"
echo ""

# ============================================
# 设置ulimit
# ============================================

echo "[6/9] 设置系统限制..."
# 增加文件描述符限制
ulimit -n 4096 2>/dev/null || echo "警告: 无法设置ulimit"
echo "当前ulimit -n: $(ulimit -n)"
echo ""

# ============================================
# 运行automate-git.py
# ============================================

echo "[7/9] 开始编译CEF (这可能需要4-8小时)..."
echo "开始时间: $(date)"
echo ""
echo "编译参数:"
echo "  - CEF分支: $CEF_BRANCH"
echo "  - 架构: x64"
echo "  - 专有编解码器: 启用"
echo "  - 调试版本: 禁用"
echo "  - 最小化分发: 启用"
echo ""

$PYTHON_CMD automate-git.py \
    --download-dir="$DOWNLOAD_DIR" \
    --depot-tools-dir="$DEPOT_TOOLS_DIR" \
    --branch=$CEF_BRANCH \
    --x64-build \
    --with-proprietary-codecs \
    --no-debug-build \
    --minimal-distrib \
    --force-build \
    --build-target=cefsimple

if [ $? -ne 0 ]; then
    echo "错误: 编译失败，请检查日志"
    exit 1
fi

echo ""
echo "编译完成！结束时间: $(date)"
echo ""

# ============================================
# 查找编译产物
# ============================================

echo "[8/9] 查找编译产物..."
BINARY_DISTRIB_DIR="$WORK_DIR/chromium/src/cef/binary_distrib"

if [ ! -d "$BINARY_DISTRIB_DIR" ]; then
    echo "错误: 未找到编译产物目录"
    exit 1
fi

cd "$BINARY_DISTRIB_DIR"
ARTIFACT_FILE=$(ls -t cef_binary_*_linux64_minimal.tar.bz2 2>/dev/null | head -1)

if [ -z "$ARTIFACT_FILE" ]; then
    echo "错误: 未找到编译产物文件"
    exit 1
fi

echo "找到编译产物: $ARTIFACT_FILE"
echo ""

# ============================================
# 复制和解压编译产物
# ============================================

echo "[9/9] 复制和解压编译产物..."
cd "$OUTPUT_DIR"

# 复制压缩包
cp "$BINARY_DISTRIB_DIR/$ARTIFACT_FILE" "$OUTPUT_DIR/"
echo "已复制到: $OUTPUT_DIR/$ARTIFACT_FILE"

# 解压
echo "正在解压 $ARTIFACT_FILE..."
tar -xjf "$ARTIFACT_FILE"

if [ $? -ne 0 ]; then
    echo "错误: 解压失败"
    exit 1
fi

# 获取解压后的目录名
EXTRACTED_DIR=$(tar -tjf "$ARTIFACT_FILE" | head -1 | cut -f1 -d"/")
echo "解压完成！目录: $EXTRACTED_DIR"
echo ""

# ============================================
# 生成编译摘要
# ============================================

SUMMARY_FILE="$OUTPUT_DIR/BUILD_INFO.txt"
cat > "$SUMMARY_FILE" << EOF
CEF Linux x64 编译信息
========================================
编译时间: $(date)
CEF分支: $CEF_BRANCH
编译机器: $(hostname)
操作系统: $(uname -a)
GCC版本: $(gcc --version | head -1)

编译参数:
  - proprietary_codecs: true
  - ffmpeg_branding: Chrome
  - is_official_build: true

编译产物:
  - 压缩包: $ARTIFACT_FILE
  - 解压目录: $EXTRACTED_DIR
  - 位置: $OUTPUT_DIR

包含的编解码器:
  - H.264/AVC
  - H.265/HEVC
  - VP8/VP9
  - AAC

使用方法:
  1. 将 $EXTRACTED_DIR 目录复制到您的项目中
  2. 在CMakeLists.txt中设置 CEF_ROOT 路径
  3. 参考CEF文档集成到您的应用

========================================
EOF

echo "编译摘要已保存到: $SUMMARY_FILE"
echo ""

# ============================================
# 生成验证脚本
# ============================================

VERIFY_SCRIPT="$OUTPUT_DIR/verify_codecs.sh"
cat > "$VERIFY_SCRIPT" << 'EOF'
#!/bin/bash
# 验证编解码器支持

echo "验证CEF编解码器支持..."
echo ""

EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "cef_binary_*" | head -1)

if [ -z "$EXTRACTED_DIR" ]; then
    echo "错误: 未找到CEF目录"
    exit 1
fi

cd "$EXTRACTED_DIR"

# 检查libcef.so
if [ -f "Release/libcef.so" ]; then
    echo "✓ 找到 libcef.so"
    
    # 检查符号
    if nm -D Release/libcef.so | grep -q "avcodec"; then
        echo "✓ 包含FFmpeg符号"
    fi
    
    # 检查依赖
    echo ""
    echo "依赖库:"
    ldd Release/libcef.so | grep -E "(gtk|nss|cups|asound)"
    
else
    echo "✗ 未找到 libcef.so"
fi

echo ""
echo "验证完成！"
EOF

chmod +x "$VERIFY_SCRIPT"
echo "验证脚本已创建: $VERIFY_SCRIPT"
echo ""

# ============================================
# 完成
# ============================================

echo "============================================"
echo "编译完成！"
echo "============================================"
echo ""
echo "编译产物位置: $OUTPUT_DIR"
echo "压缩包: $ARTIFACT_FILE"
echo "解压目录: $EXTRACTED_DIR"
echo ""
echo "下一步:"
echo "  1. 查看编译信息: cat $SUMMARY_FILE"
echo "  2. 验证编解码器: cd $OUTPUT_DIR && ./verify_codecs.sh"
echo "  3. 集成到项目: 参考README.md"
echo ""
echo "清理临时文件 (可选):"
echo "  rm -rf $WORK_DIR/chromium/src/out"
echo ""

# 显示磁盘使用
echo "磁盘使用情况:"
du -sh "$WORK_DIR" 2>/dev/null || echo "无法计算大小"
echo ""

