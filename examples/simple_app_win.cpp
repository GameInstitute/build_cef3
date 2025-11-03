// Windows平台入口点
#include "simple_app.h"

#include <windows.h>

#include "include/cef_sandbox_win.h"

// 程序入口点函数
int APIENTRY wWinMain(HINSTANCE hInstance,
                      HINSTANCE hPrevInstance,
                      LPTSTR lpCmdLine,
                      int nCmdShow) {
  UNREFERENCED_PARAMETER(hPrevInstance);
  UNREFERENCED_PARAMETER(lpCmdLine);

  // 启用高DPI支持
  CefEnableHighDPISupport();

  // 提供CEF sandbox选项
  void* sandbox_info = nullptr;

#if defined(CEF_USE_SANDBOX)
  // 仅在启用沙盒支持时管理沙盒信息
  CefScopedSandboxInfo scoped_sandbox;
  sandbox_info = scoped_sandbox.sandbox_info();
#endif

  // CEF应用程序实例
  CefRefPtr<SimpleApp> app(new SimpleApp);

  // CEF主参数结构
  CefMainArgs main_args(hInstance);

  // CEF应用程序有多个子进程(render, plugin, GPU等)
  // 这个函数检查是否正在运行子进程并执行相应代码
  int exit_code = CefExecuteProcess(main_args, app, sandbox_info);
  if (exit_code >= 0) {
    // 子进程已完成，退出
    return exit_code;
  }

  // 指定CEF全局设置
  CefSettings settings;

  // 设置日志级别
  settings.log_severity = LOGSEVERITY_WARNING;

  // 设置用户代理字符串（可选）
  // CefString(&settings.user_agent) = "MyBrowser/1.0";

  // 设置资源目录（可选）
  // CefString(&settings.resources_dir_path) = "resources";
  // CefString(&settings.locales_dir_path) = "resources/locales";

  // 启用远程调试端口（可选）
  settings.remote_debugging_port = 9222;

  // 初始化CEF
  CefInitialize(main_args, settings, app, sandbox_info);

  // 运行CEF消息循环。这个函数会阻塞直到退出消息循环
  CefRunMessageLoop();

  // 关闭CEF
  CefShutdown();

  return 0;
}

