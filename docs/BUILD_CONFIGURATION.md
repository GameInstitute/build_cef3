# CEF编译配置详解

## GN编译参数说明

本项目使用以下GN参数来编译CEF：

### 核心参数

```gn
proprietary_codecs=true
```
启用专有编解码器支持，包括H.264、H.265等。

```gn
ffmpeg_branding="Chrome"
```
使用Chrome品牌的FFmpeg，包含更多编解码器支持。

```gn
is_official_build=true
```
官方构建模式，启用优化并禁用调试符号。

```gn
is_debug=false
```
非调试构建，生成优化的发布版本。

## 平台特定配置

### Windows x64

- **编译器**: Visual Studio 2022
- **架构**: x64
- **环境变量**:
  - `GYP_MSVS_VERSION=2022`
  - `CEF_ARCHIVE_FORMAT=tar.bz2`

### Linux x64

- **编译器**: GCC (Ubuntu 22.04默认版本)
- **架构**: x64
- **必需依赖包**:
  - build-essential
  - libglib2.0-dev
  - libgtk-3-dev
  - libnss3-dev
  - libcups2-dev
  - libasound2-dev

### Android arm64-v8a

- **目标API**: 29 (Android 10)及以上
- **架构**: arm64-v8a
- **NDK版本**: r25c
- **额外GN参数**:
  ```gn
  target_os="android"
  target_cpu="arm64"
  android_sdk_root="$ANDROID_SDK_ROOT"
  android_ndk_root="$ANDROID_NDK_ROOT"
  ```

## automate-git.py参数说明

### 通用参数

- `--download-dir`: 下载目录路径
- `--depot-tools-dir`: depot_tools工具目录
- `--branch`: CEF分支号（如6367对应CEF 131稳定版）
- `--no-debug-build`: 不构建调试版本
- `--minimal-distrib`: 生成最小化分发包（仅库文件）
- `--force-build`: 强制重新构建

**注意**: `--with-proprietary-codecs` 不是有效选项。专有编解码器通过环境变量 `GN_DEFINES` 启用：

```bash
export GN_DEFINES="proprietary_codecs=true ffmpeg_branding=\"Chrome\""
```

### 平台特定参数

#### Windows/Linux
- `--x64-build`: 构建64位版本

#### Android
- `--arm64-build`: 构建ARM64版本

## 编译时间估算

基于GitHub Actions runners的性能：

| 平台 | 预计时间 | 磁盘空间 |
|------|----------|----------|
| Windows x64 | 5-7小时 | 100-120GB |
| Linux x64 | 4-6小时 | 80-100GB |
| Android arm64 | 5-8小时 | 100-130GB |

**注意**: 
- 首次构建需要下载大量依赖，时间会更长
- GitHub Actions免费版单个job限制6小时，可能需要付费计划或自托管runner
- 建议使用8小时超时设置以应对可能的性能波动

## 故障排除

### 编译超时

如果遇到超时问题：

1. **使用GitHub Actions付费计划**: 提供更长的运行时间
2. **使用自托管runner**: 可以突破时间限制
3. **使用预构建的Chromium**: 修改automate脚本跳过Chromium编译
4. **分阶段构建**: 将下载和编译分为多个步骤

### 磁盘空间不足

- GitHub Actions runners通常有150GB+可用空间
- 如果空间不足，考虑：
  - 在编译后立即清理中间文件
  - 使用`--no-build`先下载，然后分别构建

### 编解码器未生效

验证编解码器是否正确启用：

1. 检查生成的`args.gn`文件
2. 确认包含：
   ```gn
   proprietary_codecs=true
   ffmpeg_branding="Chrome"
   ```
3. 测试播放H.264视频确认

## 许可证合规性

启用`proprietary_codecs`后的二进制文件包含专有编解码器：

- ⚠️ **H.264/AVC**: 受MPEG LA专利池约束
- ⚠️ **H.265/HEVC**: 受多个专利池约束
- ⚠️ **AAC**: 受Via Licensing约束

**使用建议**:
- 商业使用需获取相应许可证
- 详细了解各编解码器的许可要求
- 考虑咨询法律顾问

## 参考链接

- [CEF官方文档](https://bitbucket.org/chromiumembedded/cef/wiki/Home)
- [CEF分支和构建指南](https://bitbucket.org/chromiumembedded/cef/wiki/BranchesAndBuilding)
- [Chromium GN构建配置](https://www.chromium.org/developers/gn-build-configuration/)
- [FFmpeg许可证信息](https://www.ffmpeg.org/legal.html)

