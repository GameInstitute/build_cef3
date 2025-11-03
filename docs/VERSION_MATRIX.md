# CEF版本对照表

本文档列出了常用的CEF版本、对应的Chromium版本和分支号。

## 最新稳定版本

| CEF版本 | 分支号 | Chromium版本 | 发布日期 | 状态 |
|---------|--------|--------------|----------|------|
| CEF 131 | 6367 | 131.0.6778.205 | 2024-11 | ✅ 推荐 |
| CEF 130 | 6478 | 130.0.6723.117 | 2024-10 | ✅ 稳定 |
| CEF 129 | 6533 | 129.0.6668.100 | 2024-09 | ✅ 稳定 |
| CEF 128 | 6613 | 128.0.6613.120 | 2024-08 | ✅ 稳定 |
| CEF 127 | 6650 | 127.0.6533.120 | 2024-07 | ⚠️ 旧版 |

## 如何选择版本

### 推荐选择标准

1. **生产环境**: 使用最新的稳定版本（标记为✅推荐）
2. **兼容性优先**: 使用与您现有Chromium/Chrome版本对应的CEF版本
3. **长期支持**: 选择标记为"稳定"的版本

### 查询更多版本

访问CEF自动化构建索引页面：
https://cef-builds.spotifycdn.com/index.html

## 分支号说明

分支号用于automate-git.py的`--branch`参数：

```bash
python automate-git.py --branch=6367  # 使用CEF 131
```

在GitHub Actions工作流中：

```yaml
env:
  CEF_BRANCH: 6367  # 修改这里
```

## 版本特性

### CEF 131 (推荐)
- ✨ 基于Chromium 131
- ✨ 改进的性能和稳定性
- ✨ 更新的Web标准支持
- ✅ 支持Windows 10/11, macOS, Linux
- ✅ 支持Android

### CEF 130
- 基于Chromium 130
- 稳定的生产版本
- 完整的H.264/H.265支持

### CEF 129
- 基于Chromium 129
- 经过充分测试
- 适合保守型项目

## 平台支持矩阵

| 平台 | CEF 131 | CEF 130 | CEF 129 | 最低系统要求 |
|------|---------|---------|---------|--------------|
| **Windows x64** | ✅ | ✅ | ✅ | Windows 10+ |
| **Windows x86** | ✅ | ✅ | ✅ | Windows 10+ |
| **Windows ARM64** | ✅ | ✅ | ⚠️ | Windows 11+ |
| **Linux x64** | ✅ | ✅ | ✅ | Ubuntu 20.04+ |
| **Linux ARM64** | ✅ | ✅ | ✅ | Ubuntu 20.04+ |
| **macOS x64** | ✅ | ✅ | ✅ | macOS 11+ |
| **macOS ARM64** | ✅ | ✅ | ✅ | macOS 11+ |
| **Android ARM** | ✅ | ✅ | ✅ | Android 7.0+ (API 24+) |
| **Android ARM64** | ✅ | ✅ | ✅ | Android 10+ (API 29+) |
| **Android x64** | ✅ | ✅ | ✅ | Android 10+ (API 29+) |

## 编解码器支持

启用`proprietary_codecs=true`后的编解码器支持：

| 编解码器 | 格式 | CEF支持 | 许可证要求 |
|----------|------|---------|------------|
| **H.264/AVC** | MP4 | ✅ | MPEG LA |
| **H.265/HEVC** | MP4 | ✅ | HEVC Advance/MPEG LA |
| **VP8** | WebM | ✅ | 免费 |
| **VP9** | WebM | ✅ | 免费 |
| **AV1** | WebM/MP4 | ✅ | 免费 |
| **AAC** | MP4/M4A | ✅ | Via Licensing |
| **Opus** | WebM/Ogg | ✅ | 免费 |
| **Vorbis** | WebM/Ogg | ✅ | 免费 |

## 更新策略

### 建议的更新周期

- **安全关键应用**: 每次新稳定版发布后1-2周内更新
- **一般应用**: 每2-3个月更新一次
- **保守型应用**: 每6个月或重大版本更新

### 更新工作流中的版本

1. 检查最新稳定版本号
2. 更新 `.github/workflows/build-cef.yml` 中的默认分支号：
   ```yaml
   inputs:
     cef_branch:
       default: '6367'  # 更新这里
   ```
3. 运行工作流测试新版本
4. 更新项目文档

## 兼容性注意事项

### Windows
- CEF 109+需要Windows 10或更高版本
- Visual Studio 2022推荐用于所有版本

### Linux
- Ubuntu 20.04+或等效系统
- 需要较新的glibc版本

### macOS
- macOS 11 (Big Sur) 或更高版本
- 支持Intel和Apple Silicon

### Android
- API 24+ (Android 7.0) 最低要求
- API 29+ (Android 10) 推荐用于完整功能
- 64位架构是必需的（自Android 10起）

## Beta和Master分支

### Beta分支
```yaml
# 使用beta分支（仅用于测试）
CEF_BRANCH: beta
```

### Master分支
```yaml
# 使用master分支（不推荐用于生产）
CEF_BRANCH: master
```

⚠️ **警告**: Beta和Master分支不稳定，仅用于开发和测试。

## 历史版本归档

旧版本CEF可能不再支持最新的操作系统或工具链：

| CEF版本 | 分支号 | Chromium | 状态 | 备注 |
|---------|--------|----------|------|------|
| CEF 120 | 5993 | 120.x | 🔴 EOL | - |
| CEF 110 | 5481 | 110.x | 🔴 EOL | - |
| CEF 100 | 4896 | 100.x | 🔴 EOL | - |
| CEF 90 | 4430 | 90.x | 🔴 EOL | Windows 7最后支持版本 |

## 获取版本信息

### 从CEF二进制文件
```cpp
#include "include/cef_version.h"

std::string version = 
    std::to_string(CEF_VERSION_MAJOR) + "." +
    std::to_string(CEF_COMMIT_NUMBER);
```

### 从命令行
```bash
# Linux/macOS
strings libcef.so | grep "Chrome/"

# Windows
findstr "Chrome/" libcef.dll
```

## 参考资源

- 📦 [CEF官方下载](https://cef-builds.spotifycdn.com/index.html)
- 📖 [CEF版本发布说明](https://bitbucket.org/chromiumembedded/cef/wiki/BranchesAndBuilding)
- 🔍 [Chromium版本历史](https://chromiumdash.appspot.com/releases)
- 📊 [CEF论坛](http://www.magpcss.org/ceforum/)

