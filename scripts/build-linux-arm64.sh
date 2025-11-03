#!/bin/bash
# CEF Linux ARM64本地编译脚本
# 使用方法: ./build-linux-arm64.sh [CEF分支号]
# 示例: ./build-linux-arm64.sh 6367

set -e  # 遇到错误立即退出

# ============================================
# 配置参数
# ============================================

# CEF分支号 (默认6367 = CEF 131)
CEF_BRANCH=${1:-6367}

# 工作目录
WORK_DIR="$PWD/cef_build_linux_arm64"
DOWNLOAD_DIR="$WORK_DIR/download"
DEPOT_TOOLS_DIR="$WORK_DIR/depot_tools"
OUTPUT_DIR="$PWD/output/linux_arm64"

# GN编译参数
export GN_DEFINES="proprietary_codecs=true ffmpeg_branding=\"Chrome\" is_official_build=true target_cpu=\"arm64\""
export CEF_ARCHIVE_FORMAT="tar.bz2"

echo "============================================"
echo "CEF Linux ARM64 本地编译脚本"
echo "============================================"
echo "CEF分支: $CEF_BRANCH"
echo "工作目录: $WORK_DIR"
echo "输出目录: $OUTPUT_DIR"
echo "============================================"
echo ""

# ============================================
# 检查操作系统
# ============================================

echo "[1/10] 检查操作系统..."
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "错误: 此脚本仅支持Linux系统"
    exit 1
fi

echo "操作系统检查通过！"
echo ""

# ============================================
# 检查和安装必要工具
# ============================================

echo "[2/10] 检查必要工具..."

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

echo "[3/10] 安装编译依赖..."
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
    
    # 安装交叉编译工具链
    echo "安装ARM64交叉编译工具链..."
    sudo apt-get install -y \
        gcc-aarch64-linux-gnu \
        g++-aarch64-linux-gnu \
        binutils-aarch64-linux-gnu
    
    # 安装CEF依赖库（ARM64版本）
    echo "安装ARM64依赖库..."
    sudo apt-get install -y \
        libglib2.0-dev:arm64 \
        libgtk-3-dev:arm64 \
        libpango1.0-dev:arm64 \
        libatk1.0-dev:arm64 \
        libcairo2-dev:arm64 \
        libx11-dev:arm64 \
        libxcomposite-dev:arm64 \
        libxdamage-dev:arm64 \
        libxext-dev:arm64 \
        libxfixes-dev:arm64 \
        libxrandr-dev:arm64 \
        libgbm-dev:arm64 \
        libdrm-dev:arm64 \
        libxkbcommon-dev:arm64 \
        libnss3-dev:arm64 \
        libcups2-dev:arm64 \
        libxss-dev:arm64 \
        libasound2-dev:arm64 \
        libpci-dev:arm64 \
        libpulse-dev:arm64 \
        libudev-dev:arm64 \
        libdbus-1-dev:arm64 \
        libxtst-dev:arm64 2>/dev/null || echo "警告: 某些ARM64库安装失败，可能需要手动配置"
    
    echo "依赖安装完成！"
else
    echo "警告: 无法自动安装依赖，请手动安装以下内容："
    echo "  - build-essential, cmake, ninja-build"
    echo "  - gcc-aarch64-linux-gnu, g++-aarch64-linux-gnu"
    echo "  - ARM64版本的开发库"
    read -p "按回车继续..."
fi

echo ""

# ============================================
# 配置交叉编译环境
# ============================================

echo "[4/10] 配置交叉编译环境..."

# 设置交叉编译工具链
export AR=aarch64-linux-gnu-ar
export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++
export LINK=aarch64-linux-gnu-g++

echo "交叉编译工具链:"
echo "  AR:   $AR"
echo "  CC:   $CC"
echo "  CXX:  $CXX"
echo "  LINK: $LINK"

# 验证工具链
if ! command -v $CC &> /dev/null; then
    echo "错误: 未找到ARM64交叉编译器"
    echo "请运行: sudo apt-get install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu"
    exit 1
fi

echo "交叉编译器版本: $($CC --version | head -1)"
echo ""

# ============================================
# 创建工作目录
# ============================================

echo "[5/10] 创建工作目录..."
mkdir -p "$WORK_DIR"
mkdir -p "$OUTPUT_DIR"
cd "$WORK_DIR"
echo "工作目录已创建: $WORK_DIR"
echo ""

# ============================================
# 下载automate-git.py
# ============================================

echo "[6/10] 下载automate-git.py..."
if [ ! -f "automate-git.py" ]; then
    echo "正在从Bitbucket下载..."
    curl -O https://bitbucket.org/chromiumembedded/cef/raw/master/tools/automate/automate-git.py
    
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

echo "[7/10] 设置系统限制..."
# 增加文件描述符限制
ulimit -n 4096 2>/dev/null || echo "警告: 无法设置ulimit"
echo "当前ulimit -n: $(ulimit -n)"
echo ""

# ============================================
# 运行automate-git.py
# ============================================

echo "[8/10] 开始编译CEF Linux ARM64 (这可能需要5-10小时)..."
echo "开始时间: $(date)"
echo ""
echo "编译参数:"
echo "  - CEF分支: $CEF_BRANCH"
echo "  - 目标架构: ARM64"
echo "  - 交叉编译: 是"
echo "  - 专有编解码器: 启用"
echo "  - 调试版本: 禁用"
echo "  - 最小化分发: 启用"
echo ""
echo "注意: ARM64交叉编译通常比本地编译耗时更长..."
echo ""

$PYTHON_CMD automate-git.py \
    --download-dir="$DOWNLOAD_DIR" \
    --depot-tools-dir="$DEPOT_TOOLS_DIR" \
    --branch=$CEF_BRANCH \
    --arm64-build \
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

echo "[9/10] 查找编译产物..."
BINARY_DISTRIB_DIR="$WORK_DIR/chromium/src/cef/binary_distrib"

if [ ! -d "$BINARY_DISTRIB_DIR" ]; then
    echo "错误: 未找到编译产物目录"
    exit 1
fi

cd "$BINARY_DISTRIB_DIR"
ARTIFACT_FILE=$(ls -t cef_binary_*_linuxarm64_minimal.tar.bz2 2>/dev/null | head -1)

if [ -z "$ARTIFACT_FILE" ]; then
    echo "错误: 未找到编译产物文件"
    echo "可用文件:"
    ls -lh *.tar.bz2 2>/dev/null || echo "无"
    exit 1
fi

echo "找到编译产物: $ARTIFACT_FILE"
echo ""

# ============================================
# 复制和解压编译产物
# ============================================

echo "[10/10] 复制和解压编译产物..."
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
CEF Linux ARM64 编译信息
========================================
编译时间: $(date)
CEF分支: $CEF_BRANCH
编译机器: $(hostname)
操作系统: $(uname -a)
交叉编译器: $($CC --version | head -1)

编译配置:
  - 目标架构: ARM64 (aarch64)
  - 交叉编译: 是
  - 工具链: gcc-aarch64-linux-gnu

编译参数:
  - proprietary_codecs: true
  - ffmpeg_branding: Chrome
  - is_official_build: true
  - target_cpu: arm64

编译产物:
  - 压缩包: $ARTIFACT_FILE
  - 解压目录: $EXTRACTED_DIR
  - 位置: $OUTPUT_DIR

包含的编解码器:
  - H.264/AVC
  - H.265/HEVC
  - VP8/VP9
  - AAC

使用说明:
  1. 将编译产物复制到ARM64 Linux设备
  2. 在CMakeLists.txt中设置 CEF_ROOT 路径
  3. 参考CEF文档集成到您的应用

系统要求:
  - Linux ARM64系统（如树莓派4、AWS Graviton等）
  - 支持的发行版：Ubuntu 20.04+ ARM64、Debian ARM64等

========================================
EOF

echo "编译摘要已保存到: $SUMMARY_FILE"
echo ""

# ============================================
# 生成验证脚本
# ============================================

VERIFY_SCRIPT="$OUTPUT_DIR/verify_arm64.sh"
cat > "$VERIFY_SCRIPT" << 'EOF'
#!/bin/bash
# 验证ARM64编解码器支持

echo "验证CEF ARM64库..."
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
    
    # 检查架构
    ARCH=$(file Release/libcef.so | grep -o "ARM aarch64" || echo "未知架构")
    echo "  架构: $ARCH"
    
    # 检查符号
    if nm -D Release/libcef.so | grep -q "avcodec"; then
        echo "✓ 包含FFmpeg符号"
    fi
    
    # 检查依赖
    echo ""
    echo "依赖库:"
    ldd Release/libcef.so | grep -E "(gtk|nss|cups|asound)" || echo "  (需要在ARM64设备上查看)"
    
else
    echo "✗ 未找到 libcef.so"
fi

echo ""
echo "注意: 此验证脚本应在ARM64 Linux设备上运行以获得完整信息"
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
echo "  2. 将产物传输到ARM64设备进行测试"
echo "  3. 在ARM64设备上运行: ./verify_arm64.sh"
echo ""
echo "ARM64设备示例:"
echo "  - 树莓派 4/5 (运行Ubuntu ARM64)"
echo "  - AWS Graviton处理器"
echo "  - 华为鲲鹏处理器"
echo "  - Ampere Altra处理器"
echo ""
echo "清理临时文件 (可选，可节省大量空间):"
echo "  rm -rf $WORK_DIR/chromium/src/out"
echo ""

# 显示磁盘使用
echo "磁盘使用情况:"
du -sh "$WORK_DIR" 2>/dev/null || echo "无法计算大小"
echo ""

