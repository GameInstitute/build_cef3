# CEF本地编译脚本

本目录包含用于在本地机器上编译CEF的完整脚本。

## 📋 脚本列表

| 脚本 | 平台 | 说明 |
|------|------|------|
| `build-windows.bat` | Windows | Windows x64编译脚本 |
| `build-linux.sh` | Linux | Linux x64编译脚本 |
| `build-linux-arm64.sh` | Linux | Linux ARM64编译脚本（交叉编译） |
| `build-android.sh` | Linux | Android arm64-v8a编译脚本 |

## 🚀 快速开始

### Windows

```cmd
# 在PowerShell或命令提示符中运行
cd scripts
.\build-windows.bat 6367
```

### Linux x64

```bash
# 给脚本添加执行权限
chmod +x scripts/build-linux.sh

# 运行编译
cd scripts
./build-linux.sh 6367
```

### Linux ARM64

```bash
# 给脚本添加执行权限
chmod +x scripts/build-linux-arm64.sh

# 运行编译（交叉编译）
cd scripts
./build-linux-arm64.sh 6367
```

**注意**: Linux ARM64编译使用交叉编译，在x64 Linux系统上编译出ARM64版本。

### Android

```bash
# 给脚本添加执行权限
chmod +x scripts/build-android.sh

# 运行编译
cd scripts
./build-android.sh 6367
```

## 📦 系统要求

### Windows

- **操作系统**: Windows 10/11 (64位)
- **Visual Studio**: Visual Studio 2022 (Community/Professional/Enterprise)
  - 需要"使用C++的桌面开发"工作负载
- **Python**: Python 3.11+
- **Git**: Git for Windows
- **磁盘空间**: 至少120GB可用空间
- **内存**: 建议16GB+ RAM
- **时间**: 4-8小时

#### 安装Visual Studio 2022

1. 下载：https://visualstudio.microsoft.com/downloads/
2. 安装时选择：
   - ✅ 使用C++的桌面开发
   - ✅ Windows 10 SDK
   - ✅ MSVC v143构建工具

### Linux x64

- **操作系统**: Ubuntu 20.04/22.04 或等效系统
- **编译器**: GCC 9+ 或 Clang 12+
- **Python**: Python 3.8+
- **磁盘空间**: 至少100GB可用空间
- **内存**: 建议16GB+ RAM
- **时间**: 4-6小时

#### Ubuntu快速设置

```bash
# 安装基础工具
sudo apt-get update
sudo apt-get install -y build-essential python3 git curl

# 脚本会自动安装其他依赖
```

### Linux ARM64

- **操作系统**: Ubuntu 20.04/22.04 或等效系统（x64，用于交叉编译）
- **编译器**: GCC 9+ 和 gcc-aarch64-linux-gnu
- **Python**: Python 3.8+
- **磁盘空间**: 至少110GB可用空间
- **内存**: 建议16GB+ RAM
- **时间**: 5-8小时

#### 交叉编译工具链安装

```bash
# 安装ARM64交叉编译工具链
sudo apt-get update
sudo apt-get install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# 脚本会自动安装其他依赖
```

**注意**: 这是交叉编译配置，在x64 Linux系统上编译出ARM64版本。如需在ARM64设备上本地编译，直接使用`build-linux.sh`。

**适用设备**:
- 树莓派 4/5 (运行Ubuntu ARM64)
- AWS Graviton处理器
- 华为鲲鹏处理器
- Ampere Altra处理器

### Android

- **操作系统**: Ubuntu 20.04/22.04 (推荐) 或 macOS
- **JDK**: OpenJDK 17
- **Python**: Python 3.8+
- **Android SDK**: 自动下载或使用现有
- **磁盘空间**: 至少130GB可用空间
- **内存**: 建议16GB+ RAM
- **时间**: 5-10小时

#### Android环境准备

```bash
# 安装JDK
sudo apt-get install openjdk-17-jdk

# (可选) 如果已有Android Studio，设置环境变量
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
```

## ⚙️ 使用方法

### 基本用法

```bash
# Windows
build-windows.bat [CEF分支号]

# Linux
./build-linux.sh [CEF分支号]

# Android
./build-android.sh [CEF分支号]
```

### 指定CEF版本

```bash
# 编译CEF 131 (稳定版，推荐)
./build-linux.sh 6367

# 编译CEF 130
./build-linux.sh 6478

# 编译CEF 129
./build-linux.sh 6533
```

CEF版本对照请参考：`docs/VERSION_MATRIX.md`

## 📂 输出结构

编译完成后，产物将保存在 `output/` 目录：

```
output/
├── windows_x64/
│   ├── cef_binary_*_windows64_minimal.tar.bz2  # 压缩包
│   ├── cef_binary_*_windows64_minimal/         # 解压后的目录
│   └── BUILD_INFO.txt                          # 编译信息
├── linux_x64/
│   ├── cef_binary_*_linux64_minimal.tar.bz2
│   ├── cef_binary_*_linux64_minimal/
│   ├── BUILD_INFO.txt
│   └── verify_codecs.sh                        # 验证脚本
└── android_arm64/
    ├── cef_binary_*_androidarm64_minimal.tar.bz2
    ├── cef_binary_*_androidarm64_minimal/
    ├── BUILD_INFO.txt
    └── verify_libs.sh                          # 验证脚本
```

### 编译产物包含

- 📚 头文件 (include/)
- 📦 静态库和动态库 (Release/)
- 🔧 CMake配置文件
- 📄 许可证和README
- 🎯 最小化分发 (仅核心文件，无示例应用)

## 🎯 编译参数说明

所有脚本默认启用以下GN参数：

```gn
proprietary_codecs=true        # 启用H.264/H.265等专有编解码器
ffmpeg_branding="Chrome"       # 使用Chrome品牌FFmpeg
is_official_build=true         # 官方构建模式（优化）
```

### 自定义编译参数

如需修改编译参数，编辑对应脚本中的 `GN_DEFINES` 变量：

**Windows** (`build-windows.bat`):
```batch
set GN_DEFINES=proprietary_codecs=true ffmpeg_branding="Chrome" your_param=true
```

**Linux/Android** (`build-linux.sh`/`build-android.sh`):
```bash
export GN_DEFINES="proprietary_codecs=true ffmpeg_branding=\"Chrome\" your_param=true"
```

### 常用可选参数

```gn
# 组件构建（编译更快，但产生更多文件）
is_component_build=true

# 禁用NaCl支持
enable_nacl=false

# 使用Jumbo构建加速
use_jumbo_build=true

# 符号级别 (0=无符号, 1=最小, 2=完整)
symbol_level=0

# 启用调试信息
is_debug=true
```

## 🐛 故障排除

### Windows常见问题

#### 1. 找不到Visual Studio

**错误**:
```
错误: 未找到Visual Studio 2022
```

**解决**:
- 确保安装了Visual Studio 2022
- 检查安装路径是否为标准路径
- 运行 "x64 Native Tools Command Prompt for VS 2022"

#### 2. Python版本不兼容

**错误**:
```
SyntaxError: invalid syntax
```

**解决**:
```cmd
# 检查Python版本
python --version

# 应该是3.11或更高，如果不是，安装新版本
```

#### 3. 磁盘空间不足

**解决**:
- 清理不必要的文件
- 使用外置硬盘
- 编译后删除中间文件：`rmdir /s cef_build_windows\chromium\src\out`

### Linux常见问题

#### 1. 依赖包缺失

**错误**:
```
fatal error: gtk/gtk.h: No such file or directory
```

**解决**:
```bash
# 脚本会自动安装，但如果失败，手动安装：
sudo apt-get install libgtk-3-dev
```

#### 2. 编译器版本过低

**错误**:
```
error: #error This file requires compiler and library support for the ISO C++ 2017 standard
```

**解决**:
```bash
# 升级到GCC 9+
sudo apt-get install gcc-9 g++-9
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 90
```

#### 3. 内存不足

**解决**:
```bash
# 限制并行编译任务数
# 编辑脚本，在GN_DEFINES中添加：
export GN_DEFINES="$GN_DEFINES use_jumbo_build=false"

# 或增加swap空间
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Android常见问题

#### 1. Android SDK下载失败

**解决**:
```bash
# 手动下载并解压到指定位置
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-11076708_latest.zip -d $HOME/Android/Sdk/cmdline-tools/

# 设置环境变量
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
```

#### 2. NDK版本不匹配

**错误**:
```
ERROR: Android NDK version mismatch
```

**解决**:
```bash
# 检查已安装的NDK版本
ls $ANDROID_SDK_ROOT/ndk/

# 安装特定版本
sdkmanager "ndk;25.2.9519653"
```

#### 3. 编译时间过长

**优化**:
```bash
# 使用更多CPU核心
# 脚本会自动使用所有可用核心

# 检查系统资源
htop  # 或 top

# 确保没有其他重量级进程在运行
```

## 📊 性能优化

### 加速编译

1. **使用SSD**: 将工作目录放在SSD上
2. **增加RAM**: 16GB以上效果最佳
3. **禁用防病毒**: 临时禁用实时扫描（编译目录）
4. **使用ccache**: Linux上可以启用ccache缓存

```bash
# Linux启用ccache
sudo apt-get install ccache
export PATH="/usr/lib/ccache:$PATH"
export CCACHE_DIR=$HOME/.ccache
```

### 减少磁盘使用

编译完成后清理中间文件：

```bash
# Windows
rmdir /s cef_build_windows\chromium\src\out

# Linux/Android
rm -rf cef_build_*/chromium/src/out
```

## ✅ 验证编译结果

### Windows

```powershell
cd output\windows_x64

# 查看编译信息
type BUILD_INFO.txt

# 检查DLL
where /R . libcef.dll
```

### Linux

```bash
cd output/linux_x64

# 查看编译信息
cat BUILD_INFO.txt

# 运行验证脚本
./verify_codecs.sh
```

### Android

```bash
cd output/android_arm64

# 查看编译信息
cat BUILD_INFO.txt

# 运行验证脚本
./verify_libs.sh
```

## 🔄 增量编译

如果只需要重新编译（不重新下载源码）：

1. 保留 `cef_build_*/` 目录
2. 修改脚本中的 `--force-build` 参数
3. 或直接进入 chromium/src/cef 目录手动编译

```bash
# 进入CEF目录
cd cef_build_linux/chromium/src/cef

# 使用ninja直接编译
ninja -C out/Release_GN_x64 cef
```

## 📝 集成到项目

### CMake示例

```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.19)
project(my_cef_app)

# 设置CEF路径
set(CEF_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/output/linux_x64/cef_binary_XXX_minimal")

# 添加CEF
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CEF_ROOT}/cmake")
find_package(CEF REQUIRED)

# 添加可执行文件
add_executable(my_app main.cpp)

# 链接CEF
target_link_libraries(my_app 
    libcef_lib 
    libcef_dll_wrapper
    ${CEF_STANDARD_LIBS}
)

# 复制CEF二进制文件
COPY_FILES("my_app" "${CEF_BINARY_FILES}" "${CEF_BINARY_DIR}" "${CMAKE_CURRENT_BINARY_DIR}")
COPY_FILES("my_app" "${CEF_RESOURCE_FILES}" "${CEF_RESOURCE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}")
```

## 🆘 获取帮助

如果遇到问题：

1. 📖 查看 `docs/TROUBLESHOOTING.md`
2. 🔍 检查编译日志（在 `cef_build_*/` 目录中）
3. 💬 访问 [CEF论坛](http://www.magpcss.org/ceforum/)
4. 🐛 查看 [CEF GitHub Issues](https://github.com/chromiumembedded/cef/issues)

## ⚖️ 许可证注意

编译出的二进制文件包含专有编解码器，商业使用需遵守：

- **H.264/AVC**: MPEG LA许可
- **H.265/HEVC**: HEVC Advance许可
- **AAC**: Via Licensing许可

详情请查看 `LICENSE` 文件。

## 🔗 相关文档

- [编译配置详解](../docs/BUILD_CONFIGURATION.md)
- [版本对照表](../docs/VERSION_MATRIX.md)
- [GitHub Actions工作流](../.github/workflows/build-cef.yml)
- [CEF官方文档](https://bitbucket.org/chromiumembedded/cef/wiki/Home)

