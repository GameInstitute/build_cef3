#!/bin/bash
# CEF Android arm64-v8a本地编译脚本
# 使用方法: ./build-android.sh [CEF分支号]
# 示例: ./build-android.sh 6367

set -e  # 遇到错误立即退出

# ============================================
# 配置参数
# ============================================

# CEF分支号 (默认6367 = CEF 131)
CEF_BRANCH=${1:-6367}

# 工作目录
WORK_DIR="$PWD/cef_build_android"
DOWNLOAD_DIR="$WORK_DIR/download"
DEPOT_TOOLS_DIR="$WORK_DIR/depot_tools"
OUTPUT_DIR="$PWD/output/android_arm64"

# Android配置
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
ANDROID_NDK_VERSION="25.2.9519653"
ANDROID_API_LEVEL="29"

# GN编译参数
export GN_DEFINES="proprietary_codecs=true ffmpeg_branding=\"Chrome\" is_official_build=true target_os=\"android\" target_cpu=\"arm64\""
export CEF_ARCHIVE_FORMAT="tar.bz2"

echo "============================================"
echo "CEF Android arm64-v8a 本地编译脚本"
echo "============================================"
echo "CEF分支: $CEF_BRANCH"
echo "工作目录: $WORK_DIR"
echo "输出目录: $OUTPUT_DIR"
echo "Android SDK: $ANDROID_SDK_ROOT"
echo "Android NDK: $ANDROID_NDK_VERSION"
echo "Android API: $ANDROID_API_LEVEL"
echo "============================================"
echo ""

# ============================================
# 检查操作系统
# ============================================

echo "[1/10] 检查操作系统..."
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "错误: 此脚本仅支持Linux系统"
    echo "Android编译建议在Linux环境下进行"
    exit 1
fi

echo "操作系统检查通过！"
echo ""

# ============================================
# 检查必要工具
# ============================================

echo "[2/10] 检查必要工具..."

# 检查Python
if ! command -v python3 &> /dev/null; then
    echo "错误: 未找到Python3"
    exit 1
fi

PYTHON_CMD=python3
echo "Python版本: $($PYTHON_CMD --version)"

# 检查Git
if ! command -v git &> /dev/null; then
    echo "错误: 未找到Git"
    exit 1
fi

# 检查Java
if ! command -v java &> /dev/null; then
    echo "错误: 未找到Java，Android编译需要JDK"
    exit 1
fi

echo "Java版本: $(java -version 2>&1 | head -1)"
echo "工具检查完成！"
echo ""

# ============================================
# 安装基础依赖
# ============================================

echo "[3/10] 安装基础编译依赖..."

if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y \
        build-essential \
        ninja-build \
        cmake \
        pkg-config \
        git \
        python3 \
        python3-pip \
        curl \
        wget \
        unzip \
        openjdk-17-jdk
    
    echo "基础依赖安装完成！"
else
    echo "警告: 无法自动安装依赖，请确保已安装必要的构建工具"
fi

echo ""

# ============================================
# 设置/检查Android SDK
# ============================================

echo "[4/10] 设置Android SDK..."

# 如果SDK不存在，下载安装
if [ ! -d "$ANDROID_SDK_ROOT" ]; then
    echo "未找到Android SDK，正在下载..."
    mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
    cd "$ANDROID_SDK_ROOT/cmdline-tools"
    
    # 下载命令行工具
    wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
    unzip commandlinetools-linux-11076708_latest.zip
    mv cmdline-tools latest
    
    echo "Android SDK下载完成！"
    cd "$WORK_DIR"
fi

# 设置环境变量
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

echo "Android SDK路径: $ANDROID_SDK_ROOT"
echo ""

# ============================================
# 安装Android SDK组件
# ============================================

echo "[5/10] 安装Android SDK组件..."

# 接受许可
yes | sdkmanager --licenses 2>/dev/null || true

# 安装必要组件
echo "安装平台工具..."
sdkmanager "platform-tools"

echo "安装Android $ANDROID_API_LEVEL..."
sdkmanager "platforms;android-$ANDROID_API_LEVEL"

echo "安装构建工具..."
sdkmanager "build-tools;34.0.0"

echo "安装NDK $ANDROID_NDK_VERSION..."
sdkmanager "ndk;$ANDROID_NDK_VERSION"

# 设置NDK路径
export ANDROID_NDK_ROOT="$ANDROID_SDK_ROOT/ndk/$ANDROID_NDK_VERSION"

echo "Android组件安装完成！"
echo "NDK路径: $ANDROID_NDK_ROOT"
echo ""

# ============================================
# 创建工作目录
# ============================================

echo "[6/10] 创建工作目录..."
mkdir -p "$WORK_DIR"
mkdir -p "$OUTPUT_DIR"
cd "$WORK_DIR"
echo "工作目录已创建: $WORK_DIR"
echo ""

# ============================================
# 下载automate-git.py
# ============================================

echo "[7/10] 下载automate-git.py..."
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
# 更新GN参数包含Android路径
# ============================================

echo "[8/10] 配置编译参数..."
export GN_DEFINES="$GN_DEFINES android_sdk_root=\"$ANDROID_SDK_ROOT\" android_ndk_root=\"$ANDROID_NDK_ROOT\" android_ndk_version=\"r25c\" android_ndk_api_level=$ANDROID_API_LEVEL"

echo "GN参数:"
echo "$GN_DEFINES"
echo ""

# ============================================
# 运行automate-git.py
# ============================================

echo "[9/10] 开始编译CEF Android (这可能需要5-10小时)..."
echo "开始时间: $(date)"
echo ""
echo "编译参数:"
echo "  - CEF分支: $CEF_BRANCH"
echo "  - 目标平台: Android"
echo "  - 架构: arm64-v8a"
echo "  - API级别: $ANDROID_API_LEVEL"
echo "  - 专有编解码器: 启用"
echo "  - 调试版本: 禁用"
echo "  - 最小化分发: 启用"
echo ""
echo "注意: Android编译通常比桌面平台耗时更长，请耐心等待..."
echo ""

          $PYTHON_CMD automate-git.py \
            --download-dir="$DOWNLOAD_DIR" \
            --depot-tools-dir="$DEPOT_TOOLS_DIR" \
            --branch=$CEF_BRANCH \
            --arm64-build \
            --no-debug-build \
            --minimal-distrib \
            --force-build

if [ $? -ne 0 ]; then
    echo "错误: 编译失败，请检查日志"
    exit 1
fi

echo ""
echo "编译完成！结束时间: $(date)"
echo ""

# ============================================
# 查找和复制编译产物
# ============================================

echo "[10/10] 查找编译产物..."
BINARY_DISTRIB_DIR="$WORK_DIR/chromium/src/cef/binary_distrib"

if [ ! -d "$BINARY_DISTRIB_DIR" ]; then
    echo "错误: 未找到编译产物目录"
    exit 1
fi

cd "$BINARY_DISTRIB_DIR"

# Android编译产物可能有不同命名
ARTIFACT_FILE=$(ls -t cef_binary_*_androidarm64_minimal.tar.bz2 2>/dev/null | head -1)
if [ -z "$ARTIFACT_FILE" ]; then
    ARTIFACT_FILE=$(ls -t cef_binary_*_linuxarm64_minimal.tar.bz2 2>/dev/null | head -1)
fi

if [ -z "$ARTIFACT_FILE" ]; then
    echo "错误: 未找到编译产物文件"
    echo "可用文件:"
    ls -lh *.tar.bz2 2>/dev/null || echo "无"
    exit 1
fi

echo "找到编译产物: $ARTIFACT_FILE"
echo ""

# 复制和解压
cd "$OUTPUT_DIR"
cp "$BINARY_DISTRIB_DIR/$ARTIFACT_FILE" "$OUTPUT_DIR/"
echo "已复制到: $OUTPUT_DIR/$ARTIFACT_FILE"

echo "正在解压 $ARTIFACT_FILE..."
tar -xjf "$ARTIFACT_FILE"

if [ $? -ne 0 ]; then
    echo "错误: 解压失败"
    exit 1
fi

EXTRACTED_DIR=$(tar -tjf "$ARTIFACT_FILE" | head -1 | cut -f1 -d"/")
echo "解压完成！目录: $EXTRACTED_DIR"
echo ""

# ============================================
# 生成编译摘要
# ============================================

SUMMARY_FILE="$OUTPUT_DIR/BUILD_INFO.txt"
cat > "$SUMMARY_FILE" << EOF
CEF Android arm64-v8a 编译信息
========================================
编译时间: $(date)
CEF分支: $CEF_BRANCH
编译机器: $(hostname)
操作系统: $(uname -a)

Android配置:
  - SDK路径: $ANDROID_SDK_ROOT
  - NDK版本: $ANDROID_NDK_VERSION
  - NDK路径: $ANDROID_NDK_ROOT
  - API级别: $ANDROID_API_LEVEL
  - 目标架构: arm64-v8a

编译参数:
  - proprietary_codecs: true
  - ffmpeg_branding: Chrome
  - is_official_build: true
  - target_os: android
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

Android集成说明:
  1. 将编译产物中的 .so 文件复制到 Android 项目的 jniLibs/arm64-v8a/ 目录
  2. 将Java包装类复制到项目中
  3. 在 build.gradle 中配置 NDK
  4. 参考 CEF Android 示例项目

最低系统要求:
  - Android 10 (API 29) 或更高
  - 64位设备 (arm64-v8a)

========================================
EOF

echo "编译摘要已保存到: $SUMMARY_FILE"
echo ""

# ============================================
# 生成验证脚本
# ============================================

VERIFY_SCRIPT="$OUTPUT_DIR/verify_libs.sh"
cat > "$VERIFY_SCRIPT" << 'EOF'
#!/bin/bash
# 验证Android库文件

echo "验证CEF Android库文件..."
echo ""

EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "cef_binary_*" | head -1)

if [ -z "$EXTRACTED_DIR" ]; then
    echo "错误: 未找到CEF目录"
    exit 1
fi

cd "$EXTRACTED_DIR"

echo "查找 .so 文件:"
find . -name "*.so" -type f

echo ""
echo "检查库文件架构:"
for so_file in $(find . -name "*.so" -type f); do
    echo "文件: $so_file"
    readelf -h "$so_file" | grep "Machine:" || echo "  无法读取"
    readelf -d "$so_file" | grep "NEEDED" | head -5 || echo "  无法读取依赖"
    echo ""
done

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
echo "  2. 验证库文件: cd $OUTPUT_DIR && ./verify_libs.sh"
echo "  3. 集成到Android项目: 参考BUILD_INFO.txt中的说明"
echo ""
echo "Android集成快速提示:"
echo "  - 复制 .so 文件到 app/src/main/jniLibs/arm64-v8a/"
echo "  - 复制 Java 文件到对应的包路径"
echo "  - 在 app/build.gradle 中配置 ndk { abiFilters 'arm64-v8a' }"
echo ""
echo "清理临时文件 (可选，可节省大量空间):"
echo "  rm -rf $WORK_DIR/chromium/src/out"
echo ""

# 显示磁盘使用
echo "磁盘使用情况:"
du -sh "$WORK_DIR" 2>/dev/null || echo "无法计算大小"
echo ""

