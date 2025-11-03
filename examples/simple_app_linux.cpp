// Linux平台入口点
#include "simple_app.h"

#include <X11/Xlib.h>

#include "include/base/cef_logging.h"
#include "include/cef_command_line.h"

// 程序入口点函数
int main(int argc, char* argv[]) {
  // 为多线程应用提供CEF默认的X11错误处理器
  XInitThreads();

  // CEF应用程序实例
  CefRefPtr<SimpleApp> app(new SimpleApp);

  // CEF主参数结构
  CefMainArgs main_args(argc, argv);

  // CEF应用程序有多个子进程(render, plugin, GPU等)
  // 这个函数检查是否正在运行子进程并执行相应代码
  int exit_code = CefExecuteProcess(main_args, app, nullptr);
  if (exit_code >= 0) {
    // 子进程已完成，退出
    return exit_code;
  }

  // 解析命令行参数（可选）
  CefRefPtr<CefCommandLine> command_line = CefCommandLine::CreateCommandLine();
  command_line->InitFromArgv(argc, argv);

  // 指定CEF全局设置
  CefSettings settings;

  // 设置日志级别
  settings.log_severity = LOGSEVERITY_WARNING;

  // 设置日志文件（可选）
  // CefString(&settings.log_file) = "/tmp/cef_debug.log";

  // 设置资源目录（可选）
  // CefString(&settings.resources_dir_path) = "./resources";
  // CefString(&settings.locales_dir_path) = "./resources/locales";

  // 设置缓存目录（可选）
  // CefString(&settings.cache_path) = "/tmp/cef_cache";

  // 启用远程调试端口（可选）
  settings.remote_debugging_port = 9222;

  // 禁用多线程消息循环（Linux下推荐）
  settings.multi_threaded_message_loop = false;

  // 设置用户代理字符串（可选）
  // CefString(&settings.user_agent) = "MyBrowser/1.0 (Linux)";

  // 启用无窗口渲染模式（可选）
  // settings.windowless_rendering_enabled = true;

  // 初始化CEF
  if (!CefInitialize(main_args, settings, app, nullptr)) {
    LOG(ERROR) << "CEF初始化失败";
    return 1;
  }

  // 运行CEF消息循环。这个函数会阻塞直到退出消息循环
  CefRunMessageLoop();

  // 关闭CEF
  CefShutdown();

  return 0;
}

