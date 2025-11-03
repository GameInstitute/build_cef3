# 快速开始指南

本指南帮助您快速开始使用CEF多平台编译工作流。

## 前置要求

1. **GitHub账号**
2. **GitHub仓库**（fork本仓库或创建新仓库）
3. **存储空间**：确保有足够的Actions存储配额

## 5分钟快速部署

### 步骤1: 复制文件到您的仓库

将以下文件复制到您的GitHub仓库：
```
.github/workflows/build-cef.yml
README.md
.gitignore
docs/
```

### 步骤2: 配置仓库权限

1. 进入仓库设置：`Settings` → `Actions` → `General`
2. 在 "Workflow permissions" 部分：
   - 选择 **"Read and write permissions"**
   - 勾选 **"Allow GitHub Actions to create and approve pull requests"**
3. 点击 **"Save"**

### 步骤3: 触发工作流

#### 方式A: 手动触发（推荐用于首次测试）

1. 进入 `Actions` 标签页
2. 选择 **"Build CEF Multi-Platform"**
3. 点击 **"Run workflow"**
4. 输入参数：
   - **cef_branch**: `6367` (CEF 131稳定版)
   - **create_release**: `true` (创建Release)
5. 点击 **"Run workflow"**

#### 方式B: 定时触发

工作流会在每月1号自动运行（可以在YAML中修改）

### 步骤4: 等待编译完成

- ⏱️ **预计时间**: 4-8小时（取决于平台）
- 📊 **进度查看**: Actions标签页查看实时日志
- 🔔 **通知**: 可以在Settings → Notifications中启用邮件通知

### 步骤5: 下载编译结果

编译完成后：

1. 进入 `Releases` 页面
2. 找到最新的Release（标签格式：`cef-build-6367-YYYYMMDD-HHMMSS`）
3. 下载对应平台的文件：
   - `cef_binary_*_windows64_minimal.tar.bz2` - Windows版本
   - `cef_binary_*_linux64_minimal.tar.bz2` - Linux版本
   - `cef_binary_*_androidarm64_minimal.tar.bz2` - Android版本

## 解压和使用

### Windows

```powershell
# 安装7-Zip或使用WSL
tar -xjf cef_binary_*_windows64_minimal.tar.bz2
cd cef_binary_*_windows64_minimal
```

### Linux

```bash
tar -xjf cef_binary_*_linux64_minimal.tar.bz2
cd cef_binary_*_linux64_minimal
```

### 集成到您的项目

#### CMake示例

```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.19)
project(my_cef_app)

# 设置CEF路径
set(CEF_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/cef_binary_*_minimal")

# 添加CEF
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CEF_ROOT}/cmake")
find_package(CEF REQUIRED)

# 添加您的可执行文件
add_executable(my_app main.cpp)
target_link_libraries(my_app libcef_lib libcef_dll_wrapper)
```

## 自定义编译

### 修改CEF版本

在工作流触发时输入不同的分支号：

| CEF版本 | 分支号 | Chromium版本 |
|---------|--------|--------------|
| CEF 131 | 6367 | Chromium 131 |
| CEF 130 | 6478 | Chromium 130 |
| CEF 129 | 6533 | Chromium 129 |

查找更多版本：https://cef-builds.spotifycdn.com/index.html

### 仅编译特定平台

编辑 `.github/workflows/build-cef.yml`，注释掉不需要的job：

```yaml
jobs:
  build-windows:
    # ...
  
  # build-linux:    # 注释掉不需要的平台
  #   # ...
  
  # build-android:  # 注释掉不需要的平台
  #   # ...
```

### 修改编译参数

在对应平台的job中找到 `GN_DEFINES` 环境变量，添加您需要的参数：

```yaml
env:
  GN_DEFINES: proprietary_codecs=true ffmpeg_branding="Chrome" your_custom_arg=true
```

常用GN参数：
- `is_component_build=true` - 组件构建（更快但文件更多）
- `enable_nacl=false` - 禁用NaCl支持
- `use_jumbo_build=true` - 加速编译

## 常见使用场景

### 场景1: 桌面应用开发

需要：Windows + Linux

```yaml
# 只保留这两个job
jobs:
  build-windows: ...
  build-linux: ...
  create-release: 
    needs: [build-windows, build-linux]
```

### 场景2: 移动应用开发

需要：Android

```yaml
jobs:
  build-android: ...
  create-release:
    needs: [build-android]
```

### 场景3: 全平台支持

保持默认配置即可。

## 验证编译结果

### 检查H.264支持

下载后解压，创建简单的测试HTML：

```html
<!DOCTYPE html>
<html>
<body>
  <video controls>
    <source src="test.mp4" type="video/mp4">
  </video>
  <script>
    const video = document.querySelector('video');
    console.log('H.264:', video.canPlayType('video/mp4; codecs="avc1.42E01E"'));
  </script>
</body>
</html>
```

### 查看库信息

**Windows**:
```powershell
# 在Visual Studio Developer Command Prompt中
dumpbin /exports libcef.dll
```

**Linux**:
```bash
nm -D libcef.so | grep cef
```

**Android**:
```bash
readelf -d libcef.so
```

## 下一步

- 📖 阅读 [完整文档](../README.md)
- 🔧 查看 [编译配置详解](BUILD_CONFIGURATION.md)
- 🐛 遇到问题？查看 [故障排除指南](TROUBLESHOOTING.md)
- 💬 获取帮助：[CEF论坛](http://www.magpcss.org/ceforum/)

## 预计成本

### GitHub Actions免费版
- ✅ 公开仓库：无限制
- ⚠️ 私有仓库：2000分钟/月（约可编译1-2次）

### GitHub Actions付费版
- Pro: $4/月，3000分钟
- Team: $4/用户/月，10000分钟
- Enterprise: 定制

### 建议
- 测试阶段：使用公开仓库
- 生产环境：考虑自托管runner或每月1-2次定时构建

## 技巧和窍门

### 💡 加速编译
- 使用 `--no-debug-build` 跳过调试版本
- 启用 `use_jumbo_build=true`
- 仅构建需要的平台

### 💡 节省存储
- 使用 `--minimal-distrib` 只包含必要文件
- 自动清理旧的Release（可添加GitHub Action）

### 💡 稳定构建
- 使用稳定分支号而非master
- 定期更新到新的稳定版本
- 保留多个版本的Release作为备份

## 获取示例项目

以下是使用本编译结果的示例项目：

- **C++**: [cef-project](https://github.com/chromiumembedded/cef-project)
- **CefSharp (.NET)**: https://github.com/cefsharp/CefSharp
- **Java**: https://github.com/chromiumembedded/java-cef

## 问题反馈

遇到问题？
1. 检查 [故障排除指南](TROUBLESHOOTING.md)
2. 查看GitHub Actions日志
3. 在本仓库提Issue
4. 访问CEF官方论坛

