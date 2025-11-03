# CEF多平台自动编译项目

本项目提供**GitHub Actions自动编译**和**本地编译脚本**两种方式来编译Chromium Embedded Framework (CEF)，支持多个平台并启用H264/H265解码器。

## 支持的平台

- ✅ **Windows 10 x64**
- ✅ **Linux x64**
- ✅ **Linux ARM64** (适用于树莓派、ARM服务器等)
- ✅ **Android arm64-v8a** (API 29及以上)

## 功能特性

- 🎬 **完整视频解码器支持**: 启用H264/H265等专有编解码器
- 📦 **最小化分发**: 仅包含库文件，减少编译时间和文件大小
- 🔄 **自动化构建**: 使用CEF官方automate工具
- 📅 **定时构建**: 每月自动构建最新稳定版（GitHub Actions）
- 🚀 **并行编译**: 三个平台同时编译，提高效率
- 💻 **本地编译**: 提供完整的本地编译脚本
- 📖 **集成示例**: 包含C++示例代码展示如何使用编译结果

## 使用方法

### 🌐 方式一：GitHub Actions自动编译（推荐用于CI/CD）

#### 1. 手动触发构建

1. 进入仓库的 **Actions** 标签页
2. 选择 **Build CEF Multi-Platform** 工作流
3. 点击 **Run workflow** 按钮
4. 配置参数：
   - **CEF分支版本**: 输入CEF分支号（如 `6367` 对应CEF 131稳定版）
   - **是否创建GitHub Release**: 勾选以自动创建Release
5. 点击 **Run workflow** 开始构建

#### 2. 自动定时构建

工作流配置为每月1号自动执行，使用默认的CEF分支版本。

#### 3. 修改工作流文件

编辑 `.github/workflows/build-cef.yml` 文件中的 `CEF_BRANCH` 默认值来更改编译版本。

### 💻 方式二：本地编译脚本（推荐用于开发环境）

#### 快速开始

**Windows:**
```cmd
# 1. 检查系统要求
cd scripts
check-requirements.bat

# 2. 开始编译
build-windows.bat 6367
```

**Linux x64:**
```bash
# 1. 检查系统要求
cd scripts
chmod +x *.sh
./check-requirements.sh

# 2. 开始编译
./build-linux.sh 6367
```

**Linux ARM64:**
```bash
# 1. 检查系统要求
cd scripts
chmod +x *.sh
./check-requirements.sh

# 2. 开始编译（交叉编译）
./build-linux-arm64.sh 6367
```

**Android:**
```bash
# 1. 检查系统要求
cd scripts
chmod +x *.sh
./check-requirements.sh

# 2. 开始编译
./build-android.sh 6367
```

#### 本地编译脚本功能

- ✅ 自动检查系统要求
- ✅ 自动安装编译依赖
- ✅ 自动下载automate-git.py
- ✅ 完整的编译流程
- ✅ 自动解压和整理编译产物
- ✅ 生成编译摘要和验证脚本
- ✅ 清理临时文件工具

#### 系统要求

**Windows:**
- Windows 10/11 (64位)
- Visual Studio 2022
- Python 3.11+
- 120GB+磁盘空间
- 16GB+内存（推荐）

**Linux x64:**
- Ubuntu 20.04/22.04 或等效系统
- GCC 9+ 或 Clang 12+
- Python 3.8+
- 100GB+磁盘空间
- 16GB+内存（推荐）

**Linux ARM64:**
- Ubuntu 20.04/22.04 或等效系统（用于交叉编译）
- gcc-aarch64-linux-gnu 交叉编译工具链
- Python 3.8+
- 110GB+磁盘空间
- 16GB+内存（推荐）

**Android:**
- Linux系统（推荐Ubuntu 22.04）
- JDK 17
- Android SDK & NDK
- 130GB+磁盘空间
- 16GB+内存（推荐）

详细说明请查看: [`scripts/README.md`](scripts/README.md)

## CEF版本对照表

| CEF版本 | Chromium版本 | 分支号 |
|---------|-------------|--------|
| CEF 131 | Chromium 131 | 6367 |
| CEF 130 | Chromium 130 | 6328 |
| CEF 129 | Chromium 129 | 6261 |
| CEF 128 | Chromium 128 | 6167 |

完整版本列表请访问: https://bitbucket.org/chromiumembedded/cef/wiki/BranchesAndBuilding

## 下载编译结果

构建完成后，在仓库的 **Releases** 页面下载对应平台的 `.tar.bz2` 文件。

### 解压方法

**Linux/macOS:**
```bash
tar -xjf cef_binary_*.tar.bz2
```

**Windows:**
使用7-Zip或其他支持tar.bz2格式的解压工具。

## 编译配置说明

### GN编译参数

工作流使用以下GN参数启用视频解码器：

```gn
proprietary_codecs=true
ffmpeg_branding="Chrome"
is_official_build=true
```

### 编译选项

- `--with-proprietary-codecs`: 启用专有编解码器
- `--minimal-distrib`: 最小化分发包（仅库文件）
- `--no-debug-build`: 仅编译Release版本
- `--force-build`: 强制重新编译

## 构建时间

由于CEF编译非常耗时，每个平台预计需要：

- **Windows**: 4-6小时
- **Linux**: 4-6小时  
- **Android**: 5-7小时

三个平台并行编译，总共约需要6-8小时完成所有构建。

## 注意事项

### GitHub Actions限制

- **免费版**: 单个job最长6小时，可能导致超时
- **存储空间**: 每个平台需要80-120GB磁盘空间
- **并发限制**: 免费版有并发job数量限制

如果遇到超时问题，可以考虑：
1. 使用GitHub Actions付费计划
2. 使用自托管Runner
3. 分阶段构建

### 专有编解码器许可

启用 `proprietary_codecs=true` 后的二进制文件包含专有编解码器（如H264/H265），使用时需要：

- 遵守相关专利许可要求
- 不得用于违反许可协议的商业用途
- 建议咨询法律顾问确认合规性

详情请参考: https://www.chromium.org/audio-video/

## 📁 项目结构

```
build_cef3/
├── .github/
│   └── workflows/
│       └── build-cef.yml           # GitHub Actions工作流配置
├── docs/
│   ├── BUILD_CONFIGURATION.md      # 编译配置详解
│   ├── QUICK_START.md              # 5分钟快速开始指南
│   ├── TROUBLESHOOTING.md          # 故障排除指南
│   └── VERSION_MATRIX.md           # CEF版本对照表
├── scripts/
│   ├── build-windows.bat           # Windows编译脚本
│   ├── build-linux.sh              # Linux x64编译脚本
│   ├── build-linux-arm64.sh        # Linux ARM64编译脚本
│   ├── build-android.sh            # Android编译脚本
│   ├── build-all.sh                # 全平台编译脚本
│   ├── check-requirements.bat      # Windows系统检查
│   ├── check-requirements.sh       # Linux系统检查
│   ├── cleanup.bat                 # Windows清理工具
│   ├── cleanup.sh                  # Linux清理工具
│   └── README.md                   # 脚本使用说明
├── examples/
│   ├── CMakeLists.txt              # CMake构建配置
│   ├── simple_app.h/cpp            # 示例应用
│   ├── simple_handler.h/cpp        # 事件处理器
│   ├── simple_app_win.cpp          # Windows入口
│   ├── simple_app_linux.cpp        # Linux入口
│   └── README.md                   # 示例说明
├── LICENSE                         # 许可证文件
└── README.md                       # 本文件
```

## 故障排除

### 构建失败

1. **超时**: 增加 `timeout-minutes` 值或使用自托管Runner
2. **磁盘空间不足**: GitHub Actions提供的空间应该足够，检查是否有其他问题
3. **依赖错误**: 检查平台特定的依赖安装步骤

### 找不到编译产物

检查工作流日志中的 "查找编译产物" 步骤，确认文件路径正确。

### Android编译问题

确保Android SDK和NDK版本正确：
- Android SDK API 29或更高
- NDK r25c (25.2.9519653)

## 📚 文档快速导航

- **[快速开始指南](docs/QUICK_START.md)** - 5分钟快速部署
- **[编译配置详解](docs/BUILD_CONFIGURATION.md)** - 详细的编译参数说明
- **[故障排除指南](docs/TROUBLESHOOTING.md)** - 常见问题解决方案
- **[CEF版本对照表](docs/VERSION_MATRIX.md)** - CEF版本和Chromium对应关系
- **[本地编译脚本](scripts/README.md)** - 本地编译完整说明
- **[集成示例](examples/README.md)** - C++集成示例代码

## 🔗 相关链接

**CEF资源:**
- [CEF官方网站](https://bitbucket.org/chromiumembedded/cef)
- [CEF构建指南](https://bitbucket.org/chromiumembedded/cef/wiki/BranchesAndBuilding)
- [CEF自动化工具](https://bitbucket.org/chromiumembedded/cef/wiki/AutomatedBuildSetup)
- [CEF论坛](http://www.magpcss.org/ceforum/)
- [CEF API文档](https://magpcss.org/ceforum/apidocs3/)

**Chromium资源:**
- [Chromium音视频支持](https://www.chromium.org/audio-video/)
- [Chromium GN构建配置](https://www.chromium.org/developers/gn-build-configuration/)

## ⚖️ 许可证

本项目的脚本和文档使用MIT许可证。

CEF本身遵循BSD许可证。编译产物的许可证遵循CEF和Chromium项目的相关条款。

详情请查看: [LICENSE](LICENSE)

## 🤝 贡献

欢迎提交Issue和Pull Request来改进本项目：

- 🐛 报告bug
- 💡 提出新功能建议
- 📝 改进文档
- 🔧 提交代码改进

## 💬 获取帮助

如果遇到问题：

1. 查看[故障排除指南](docs/TROUBLESHOOTING.md)
2. 搜索[GitHub Issues](../../issues)
3. 访问[CEF论坛](http://www.magpcss.org/ceforum/)
4. 创建新的[Issue](../../issues/new)

## ⭐ Star历史

如果这个项目对您有帮助，请给它一个Star！⭐

---

**注意**: 本项目仅用于自动化编译CEF，不包含CEF源代码本身。CEF源代码版权归其原作者所有。

