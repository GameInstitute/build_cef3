# CEF集成示例

本目录包含简单的CEF集成示例代码，展示如何在自己的项目中使用编译好的CEF库。

## 📁 文件说明

| 文件 | 说明 |
|------|------|
| `CMakeLists.txt` | CMake构建配置文件 |
| `simple_app.h/cpp` | CEF应用程序主类 |
| `simple_handler.h/cpp` | 浏览器事件处理器 |
| `simple_app_win.cpp` | Windows平台入口 |
| `simple_app_linux.cpp` | Linux平台入口 |

## 🚀 快速开始

### 步骤1: 准备CEF库

首先确保已经编译了CEF库，或从Release页面下载：

```bash
# 方式1: 本地编译
cd scripts
./build-linux.sh 6367

# 方式2: 从GitHub Release下载并解压
cd output/linux_x64
tar -xjf cef_binary_*_linux64_minimal.tar.bz2
```

### 步骤2: 设置CEF路径

设置环境变量指向CEF根目录：

**Linux/macOS:**
```bash
export CEF_ROOT=/path/to/cef_binary_xxx_minimal
```

**Windows:**
```cmd
set CEF_ROOT=C:\path\to\cef_binary_xxx_minimal
```

或直接在`CMakeLists.txt`中修改`CEF_ROOT`变量。

### 步骤3: 编译示例

**Linux:**
```bash
cd examples
mkdir build && cd build
cmake ..
make
```

**Windows:**
```cmd
cd examples
mkdir build && cd build
cmake ..
cmake --build . --config Release
```

### 步骤4: 运行示例

**Linux:**
```bash
./cef_example
# 或指定URL
./cef_example --url=https://www.example.com
```

**Windows:**
```cmd
Release\cef_example.exe
REM 或指定URL
Release\cef_example.exe --url=https://www.example.com
```

## 📖 代码说明

### SimpleApp类

`SimpleApp`实现了CEF的应用程序级别回调：

```cpp
class SimpleApp : public CefApp, public CefBrowserProcessHandler {
 public:
  SimpleApp();

  // 获取浏览器进程处理器
  virtual CefRefPtr<CefBrowserProcessHandler> GetBrowserProcessHandler() OVERRIDE {
    return this;
  }

  // 在CEF上下文初始化后调用
  virtual void OnContextInitialized() OVERRIDE;
  
 private:
  IMPLEMENT_REFCOUNTING(SimpleApp);
};
```

### SimpleHandler类

`SimpleHandler`处理浏览器事件：

```cpp
class SimpleHandler : public CefClient,
                      public CefDisplayHandler,
                      public CefLifeSpanHandler,
                      public CefLoadHandler {
 public:
  // 标题改变时调用
  virtual void OnTitleChange(CefRefPtr<CefBrowser> browser,
                             const CefString& title) OVERRIDE;

  // 浏览器创建后调用
  virtual void OnAfterCreated(CefRefPtr<CefBrowser> browser) OVERRIDE;

  // 浏览器即将关闭
  virtual bool DoClose(CefRefPtr<CefBrowser> browser) OVERRIDE;

  // 浏览器关闭前调用
  virtual void OnBeforeClose(CefRefPtr<CefBrowser> browser) OVERRIDE;

  // 加载错误时调用
  virtual void OnLoadError(CefRefPtr<CefBrowser> browser,
                           CefRefPtr<CefFrame> frame,
                           ErrorCode errorCode,
                           const CefString& errorText,
                           const CefString& failedUrl) OVERRIDE;
                           
 private:
  IMPLEMENT_REFCOUNTING(SimpleHandler);
};
```

## 🔧 自定义配置

### 修改默认URL

在`simple_app.cpp`的`OnContextInitialized`方法中：

```cpp
void SimpleApp::OnContextInitialized() {
  // ...
  std::string url = "https://your-website.com";  // 修改这里
  // ...
}
```

### 启用远程调试

在平台入口文件中（如`simple_app_linux.cpp`）：

```cpp
CefSettings settings;
settings.remote_debugging_port = 9222;  // 设置调试端口
```

然后在浏览器中访问：`http://localhost:9222`

### 配置浏览器设置

在`simple_app.cpp`中：

```cpp
CefBrowserSettings browser_settings;

// 启用/禁用JavaScript
browser_settings.javascript = STATE_ENABLED;

// 启用/禁用插件
browser_settings.plugins = STATE_DISABLED;

// 设置字体
CefString(&browser_settings.standard_font_family) = "Arial";
browser_settings.default_font_size = 16;

// 启用本地存储
browser_settings.local_storage = STATE_ENABLED;
```

### 设置日志级别

```cpp
CefSettings settings;

// 可选值: LOGSEVERITY_DEFAULT, LOGSEVERITY_VERBOSE, 
//         LOGSEVERITY_INFO, LOGSEVERITY_WARNING,
//         LOGSEVERITY_ERROR, LOGSEVERITY_FATAL
settings.log_severity = LOGSEVERITY_WARNING;
```

## 🎨 功能扩展

### 添加JavaScript执行

```cpp
// 在页面加载完成后执行JavaScript
void SimpleHandler::OnLoadEnd(CefRefPtr<CefBrowser> browser,
                              CefRefPtr<CefFrame> frame,
                              int httpStatusCode) {
  // 执行JavaScript
  frame->ExecuteJavaScript(
      "console.log('Hello from C++!');",
      frame->GetURL(),
      0
  );
}
```

### 添加自定义scheme处理

```cpp
// 注册自定义scheme
class CustomSchemeHandlerFactory : public CefSchemeHandlerFactory {
 public:
  virtual CefRefPtr<CefResourceHandler> Create(
      CefRefPtr<CefBrowser> browser,
      CefRefPtr<CefFrame> frame,
      const CefString& scheme_name,
      CefRefPtr<CefRequest> request) OVERRIDE {
    // 返回自定义资源处理器
    return new CustomResourceHandler();
  }
  
  IMPLEMENT_REFCOUNTING(CustomSchemeHandlerFactory);
};

// 在SimpleApp::OnContextInitialized中注册
CefRegisterSchemeHandlerFactory(
    "myscheme", 
    "", 
    new CustomSchemeHandlerFactory()
);
```

### 拦截网络请求

```cpp
class RequestHandler : public CefRequestHandler {
 public:
  virtual CefRefPtr<CefResourceRequestHandler> GetResourceRequestHandler(
      CefRefPtr<CefBrowser> browser,
      CefRefPtr<CefFrame> frame,
      CefRefPtr<CefRequest> request,
      bool is_navigation,
      bool is_download,
      const CefString& request_initiator,
      bool& disable_default_handling) OVERRIDE {
    // 返回资源请求处理器
    return new MyResourceRequestHandler();
  }
  
  IMPLEMENT_REFCOUNTING(RequestHandler);
};
```

## 📊 测试H264/H265支持

在浏览器中打开开发者工具（F12），在Console中执行：

```javascript
// 测试H.264支持
const video = document.createElement('video');
console.log('H.264支持:', video.canPlayType('video/mp4; codecs="avc1.42E01E"'));
console.log('H.265支持:', video.canPlayType('video/mp4; codecs="hev1.1.6.L93.B0"'));

// 创建视频元素测试
const testVideo = document.createElement('video');
testVideo.controls = true;
testVideo.src = 'path/to/your/h264video.mp4';
document.body.appendChild(testVideo);
```

## 🐛 常见问题

### 1. 找不到libcef.so/libcef.dll

**解决方案**:
- 确保CEF库文件与可执行文件在同一目录
- 或将CEF库目录添加到系统PATH

**Linux:**
```bash
export LD_LIBRARY_PATH=/path/to/cef/Release:$LD_LIBRARY_PATH
```

**Windows:**
```cmd
set PATH=C:\path\to\cef\Release;%PATH%
```

### 2. 缺少资源文件

**错误**:
```
Check failed: base::PathExists(pak_file)
```

**解决方案**:
确保以下资源文件与可执行文件在同一目录：
- `icudtl.dat`
- `*.pak` 文件
- `locales/` 目录

### 3. 无法播放视频

**检查**:
1. 确认使用了启用proprietary_codecs的CEF构建
2. 检查视频编解码器格式
3. 查看浏览器console是否有错误

### 4. 崩溃或段错误

**调试方法**:
```bash
# Linux使用gdb调试
gdb ./cef_example
run
# 崩溃后使用 bt 查看堆栈
```

**Windows使用Visual Studio调试**

## 📚 更多示例

### 完整的CEF示例项目

官方提供了更完整的示例：

- **cefclient**: https://bitbucket.org/chromiumembedded/cef/src/master/tests/cefclient/
- **cefsimple**: https://bitbucket.org/chromiumembedded/cef/src/master/tests/cefsimple/

### 第三方包装库

- **CefSharp (.NET)**: https://github.com/cefsharp/CefSharp
- **JCEF (Java)**: https://bitbucket.org/chromiumembedded/java-cef
- **CEF4Delphi**: https://github.com/salvadordf/CEF4Delphi

## 📖 参考文档

- [CEF官方文档](https://bitbucket.org/chromiumembedded/cef/wiki/Home)
- [CEF通用用法](https://bitbucket.org/chromiumembedded/cef/wiki/GeneralUsage)
- [CEF API文档](https://magpcss.org/ceforum/apidocs3/)
- [CEF论坛](http://www.magpcss.org/ceforum/)

## ⚖️ 许可证

本示例代码使用MIT许可证。

CEF本身使用BSD许可证。

如果使用了启用专有编解码器的构建，请注意相关许可证要求。

