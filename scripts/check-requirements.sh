#!/bin/bash
# CEF编译环境检查脚本
# 检查系统是否满足编译要求

echo "============================================"
echo "CEF编译环境检查"
echo "============================================"
echo ""

ERRORS=0
WARNINGS=0

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

# 检查操作系统
echo "[1] 操作系统"
OS_TYPE=$(uname -s)
case "$OS_TYPE" in
    Linux*)
        check_pass "操作系统: Linux"
        
        # 检查发行版
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            echo "  发行版: $NAME $VERSION"
            
            # 检查是否为推荐的Ubuntu版本
            if [[ "$ID" == "ubuntu" ]]; then
                VERSION_NUM=$(echo $VERSION_ID | cut -d. -f1)
                if [ "$VERSION_NUM" -ge 20 ]; then
                    check_pass "Ubuntu $VERSION_ID (推荐)"
                else
                    check_warn "Ubuntu版本较旧，推荐20.04+"
                fi
            fi
        fi
        ;;
    Darwin*)
        check_pass "操作系统: macOS"
        check_warn "macOS编译支持有限，建议使用Linux"
        ;;
    *)
        check_fail "不支持的操作系统: $OS_TYPE"
        ;;
esac
echo ""

# 检查Python
echo "[2] Python"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
    
    if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 8 ]; then
        check_pass "Python $PYTHON_VERSION"
    else
        check_warn "Python $PYTHON_VERSION (推荐3.11+)"
    fi
else
    check_fail "未安装Python 3"
fi
echo ""

# 检查Git
echo "[3] Git"
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    check_pass "Git $GIT_VERSION"
else
    check_fail "未安装Git"
fi
echo ""

# 检查编译工具
echo "[4] 编译工具"
if command -v gcc &> /dev/null; then
    GCC_VERSION=$(gcc --version | head -1 | awk '{print $NF}')
    GCC_MAJOR=$(echo $GCC_VERSION | cut -d. -f1)
    
    if [ "$GCC_MAJOR" -ge 9 ]; then
        check_pass "GCC $GCC_VERSION"
    else
        check_warn "GCC $GCC_VERSION (推荐9+)"
    fi
else
    check_fail "未安装GCC"
fi

if command -v g++ &> /dev/null; then
    check_pass "G++ 已安装"
else
    check_fail "未安装G++"
fi

if command -v make &> /dev/null; then
    check_pass "Make 已安装"
else
    check_fail "未安装Make"
fi

if command -v ninja &> /dev/null; then
    check_pass "Ninja 已安装"
else
    check_warn "未安装Ninja (推荐安装)"
fi

if command -v cmake &> /dev/null; then
    CMAKE_VERSION=$(cmake --version | head -1 | awk '{print $3}')
    check_pass "CMake $CMAKE_VERSION"
else
    check_warn "未安装CMake (可选)"
fi
echo ""

# 检查Java (Android编译需要)
echo "[5] Java (Android编译)"
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -1 | awk -F '"' '{print $2}')
    check_pass "Java $JAVA_VERSION"
else
    check_warn "未安装Java (Android编译需要)"
fi
echo ""

# 检查磁盘空间
echo "[6] 磁盘空间"
AVAILABLE_GB=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')

if [ "$AVAILABLE_GB" -ge 150 ]; then
    check_pass "可用空间: ${AVAILABLE_GB}GB (充足)"
elif [ "$AVAILABLE_GB" -ge 100 ]; then
    check_warn "可用空间: ${AVAILABLE_GB}GB (建议150GB+)"
else
    check_fail "可用空间: ${AVAILABLE_GB}GB (不足，需要至少100GB)"
fi
echo ""

# 检查内存
echo "[7] 系统内存"
if command -v free &> /dev/null; then
    TOTAL_RAM_GB=$(free -g | grep Mem | awk '{print $2}')
    AVAILABLE_RAM_GB=$(free -g | grep Mem | awk '{print $7}')
    
    if [ "$TOTAL_RAM_GB" -ge 16 ]; then
        check_pass "总内存: ${TOTAL_RAM_GB}GB (充足)"
    elif [ "$TOTAL_RAM_GB" -ge 8 ]; then
        check_warn "总内存: ${TOTAL_RAM_GB}GB (建议16GB+)"
    else
        check_fail "总内存: ${TOTAL_RAM_GB}GB (不足，需要至少8GB)"
    fi
    
    echo "  可用内存: ${AVAILABLE_RAM_GB}GB"
else
    check_warn "无法检测内存信息"
fi
echo ""

# 检查CPU核心数
echo "[8] CPU"
if command -v nproc &> /dev/null; then
    CPU_CORES=$(nproc)
    check_pass "CPU核心数: $CPU_CORES"
    
    if [ "$CPU_CORES" -ge 8 ]; then
        echo "  编译速度: 快"
    elif [ "$CPU_CORES" -ge 4 ]; then
        echo "  编译速度: 中等"
    else
        echo "  编译速度: 较慢"
    fi
else
    check_warn "无法检测CPU信息"
fi
echo ""

# 检查必要的库 (Linux)
if [[ "$OS_TYPE" == "Linux"* ]]; then
    echo "[9] 必要的开发库"
    
    LIBS_TO_CHECK=(
        "libgtk-3-dev:gtk/gtk.h"
        "libnss3-dev:nss/nss.h"
        "libcups2-dev:cups/cups.h"
        "libasound2-dev:alsa/asoundlib.h"
    )
    
    for lib_info in "${LIBS_TO_CHECK[@]}"; do
        LIB_NAME=$(echo $lib_info | cut -d: -f1)
        HEADER=$(echo $lib_info | cut -d: -f2)
        
        if dpkg -l | grep -q "^ii.*$LIB_NAME" 2>/dev/null; then
            check_pass "$LIB_NAME 已安装"
        else
            check_warn "$LIB_NAME 未安装 (编译时需要)"
        fi
    done
    echo ""
fi

# 检查ulimit
echo "[10] 系统限制"
ULIMIT_N=$(ulimit -n)
if [ "$ULIMIT_N" -ge 4096 ]; then
    check_pass "文件描述符限制: $ULIMIT_N"
else
    check_warn "文件描述符限制: $ULIMIT_N (建议4096+)"
    echo "  提示: 运行 'ulimit -n 4096' 临时提高限制"
fi
echo ""

# Android特定检查
echo "[11] Android开发环境 (可选)"
if [ -n "$ANDROID_SDK_ROOT" ] && [ -d "$ANDROID_SDK_ROOT" ]; then
    check_pass "Android SDK: $ANDROID_SDK_ROOT"
    
    # 检查NDK
    if [ -d "$ANDROID_SDK_ROOT/ndk" ]; then
        NDK_VERSIONS=$(ls "$ANDROID_SDK_ROOT/ndk" 2>/dev/null)
        if [ -n "$NDK_VERSIONS" ]; then
            check_pass "Android NDK: 已安装"
            echo "  版本: $NDK_VERSIONS"
        else
            check_warn "Android NDK: 未安装"
        fi
    else
        check_warn "Android NDK: 未安装"
    fi
else
    check_warn "Android SDK: 未配置 (Android编译需要)"
    echo "  提示: 设置环境变量 ANDROID_SDK_ROOT"
fi
echo ""

# 估算编译时间
echo "[12] 预计编译时间"
if [ "$CPU_CORES" -ge 8 ] && [ "$TOTAL_RAM_GB" -ge 16 ]; then
    echo "  Linux x64: 4-5小时"
    echo "  Android arm64: 5-7小时"
elif [ "$CPU_CORES" -ge 4 ] && [ "$TOTAL_RAM_GB" -ge 8 ]; then
    echo "  Linux x64: 6-8小时"
    echo "  Android arm64: 7-10小时"
else
    echo "  Linux x64: 8-12小时"
    echo "  Android arm64: 10-15小时"
fi
echo ""

# 总结
echo "============================================"
echo "检查结果总结"
echo "============================================"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ 系统满足所有编译要求！${NC}"
    echo ""
    echo "可以开始编译："
    echo "  Linux:   ./build-linux.sh"
    echo "  Android: ./build-android.sh"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ 系统基本满足要求，但有 $WARNINGS 个警告${NC}"
    echo ""
    echo "可以尝试编译，但可能遇到一些问题"
else
    echo -e "${RED}✗ 发现 $ERRORS 个错误和 $WARNINGS 个警告${NC}"
    echo ""
    echo "请先解决以下问题："
    echo ""
    
    if ! command -v python3 &> /dev/null; then
        echo "  - 安装Python 3: sudo apt-get install python3"
    fi
    
    if ! command -v git &> /dev/null; then
        echo "  - 安装Git: sudo apt-get install git"
    fi
    
    if ! command -v gcc &> /dev/null; then
        echo "  - 安装构建工具: sudo apt-get install build-essential"
    fi
    
    if [ "$AVAILABLE_GB" -lt 100 ]; then
        echo "  - 清理磁盘空间或使用更大的磁盘"
    fi
    
    if [ "$TOTAL_RAM_GB" -lt 8 ]; then
        echo "  - 增加系统内存或配置swap空间"
    fi
fi

echo ""
echo "详细说明请参考: scripts/README.md"
echo ""

