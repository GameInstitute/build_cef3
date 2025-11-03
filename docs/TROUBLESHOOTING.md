# CEF编译故障排除指南

本文档提供常见问题的解决方案。

## 常见问题

### 1. GitHub Actions工作流超时

**症状**: Job在6-8小时后超时失败

**解决方案**:

#### 方案A: 使用GitHub Actions付费计划
- GitHub Pro: 提供更多并发任务和更长运行时间
- GitHub Team/Enterprise: 更高的资源限制

#### 方案B: 使用自托管Runner
```yaml
runs-on: self-hosted
```

#### 方案C: 优化构建参数
在`automate-git.py`中添加：
```bash
--no-distrib-archive  # 不创建分发包归档
--no-wrapper          # 不构建包装器
```

### 2. 磁盘空间不足

**症状**: 
```
fatal: write error: No space left on device
```

**解决方案**:

在编译步骤后添加清理：
```yaml
- name: 清理中间文件
  run: |
    cd cef_build/chromium/src
    ninja -C out/Release_GN_x64 -t clean
    rm -rf out/Release_GN_x64/obj
```

### 3. depot_tools下载失败

**症状**:
```
Failed to download depot_tools
```

**解决方案**:

手动预下载depot_tools：
```yaml
- name: 预下载depot_tools
  run: |
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $HOME/depot_tools
    export PATH=$HOME/depot_tools:$PATH
```

### 4. Android编译NDK版本不匹配

**症状**:
```
ERROR: Android NDK version mismatch
```

**解决方案**:

确保使用正确的NDK版本：
```yaml
sdkmanager "ndk;25.2.9519653"
```

在GN_DEFINES中指定：
```bash
android_ndk_version="r25c"
```

### 5. Visual Studio找不到

**症状** (Windows):
```
ERROR: Visual Studio installation not found
```

**解决方案**:

确保调用vcvars64.bat：
```cmd
call "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
```

或使用github-actions的setup-msbuild：
```yaml
- name: 设置Visual Studio环境
  uses: microsoft/setup-msbuild@v2
```

### 6. 编解码器未启用

**症状**: 编译成功但H.264视频无法播放

**验证步骤**:

1. 检查生成的args.gn：
```bash
cat cef_build/chromium/src/out/Release_GN_x64/args.gn
```

2. 确认包含：
```gn
proprietary_codecs = true
ffmpeg_branding = "Chrome"
```

**解决方案**:

确保环境变量正确设置：
```yaml
env:
  GN_DEFINES: proprietary_codecs=true ffmpeg_branding="Chrome"
```

### 7. Python版本不兼容

**症状**:
```
SyntaxError: invalid syntax
```

**解决方案**:

使用Python 3.11：
```yaml
- name: 设置Python环境
  uses: actions/setup-python@v5
  with:
    python-version: '3.11'
```

### 8. Git LFS限制

**症状**:
```
Error downloading object: exceeded bandwidth limit
```

**解决方案**:

CEF构建不需要LFS，禁用它：
```bash
git lfs install --skip-smudge
```

### 9. Release创建失败

**症状**:
```
Error: Resource not accessible by integration
```

**解决方案**:

检查GitHub仓库权限：
1. Settings → Actions → General
2. Workflow permissions → 选择 "Read and write permissions"
3. 勾选 "Allow GitHub Actions to create and approve pull requests"

### 10. Artifact下载失败

**症状**:
```
Unable to download artifact
```

**解决方案**:

增加重试次数：
```yaml
- name: 下载编译产物
  uses: actions/download-artifact@v4
  with:
    path: artifacts
  continue-on-error: true
  
- name: 重试下载
  if: failure()
  uses: actions/download-artifact@v4
  with:
    path: artifacts
```

## 调试技巧

### 启用详细日志

在automate-git.py中添加：
```bash
--verbose-build
```

### 使用tmate进行SSH调试

在工作流中添加：
```yaml
- name: Setup tmate session
  if: failure()
  uses: mxschmitt/action-tmate@v3
```

### 保存构建日志

```yaml
- name: 上传构建日志
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: build-logs
    path: |
      cef_build/chromium/src/cef/build.log
      cef_build/chromium/src/out/Release_GN_x64/build.log
```

## 性能优化建议

### 1. 使用缓存

添加depot_tools缓存：
```yaml
- name: 缓存depot_tools
  uses: actions/cache@v4
  with:
    path: ~/depot_tools
    key: depot-tools-${{ runner.os }}
```

### 2. 并行编译

在GN_DEFINES中设置：
```bash
use_jumbo_build=true
```

### 3. 减少符号信息

```bash
symbol_level=0
```

## 获取帮助

如果以上方案都无法解决问题：

1. **查看CEF论坛**: http://www.magpcss.org/ceforum/
2. **GitHub Issues**: https://github.com/chromiumembedded/cef/issues
3. **检查工作流日志**: Actions标签页 → 选择失败的运行
4. **搜索已知问题**: 在CEF Wiki中查找类似问题

## 有用的命令

### 查看磁盘使用
```bash
df -h
du -sh cef_build/*
```

### 检查编译产物
```bash
ls -lh cef_build/chromium/src/cef/binary_distrib/
```

### 验证库文件
```bash
# Windows
dumpbin /dependents libcef.dll

# Linux
ldd libcef.so

# Android
readelf -d libcef.so
```

### 测试编解码器支持
在cefclient中运行JavaScript：
```javascript
// 检查视频编解码器支持
const video = document.createElement('video');
console.log('H.264 support:', video.canPlayType('video/mp4; codecs="avc1.42E01E"'));
console.log('H.265 support:', video.canPlayType('video/mp4; codecs="hev1.1.6.L93.B0"'));
```

