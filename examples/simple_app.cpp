#include "simple_app.h"
#include "simple_handler.h"

#include "include/cef_browser.h"
#include "include/cef_command_line.h"
#include "include/views/cef_browser_view.h"
#include "include/views/cef_window.h"
#include "include/wrapper/cef_helpers.h"

SimpleApp::SimpleApp() {}

void SimpleApp::OnContextInitialized() {
  CEF_REQUIRE_UI_THREAD();

  CefRefPtr<CefCommandLine> command_line =
      CefCommandLine::GetGlobalCommandLine();

  // 创建浏览器窗口设置
  CefWindowInfo window_info;

#if defined(OS_WIN)
  // Windows平台设置
  window_info.SetAsPopup(NULL, "CEF示例浏览器");
#endif

  // 创建浏览器设置
  CefBrowserSettings browser_settings;
  
  // 启用Web安全
  browser_settings.web_security = STATE_ENABLED;
  
  // 启用JavaScript
  browser_settings.javascript = STATE_ENABLED;
  
  // 启用本地存储
  browser_settings.local_storage = STATE_ENABLED;
  
  // 设置默认字体
  CefString(&browser_settings.standard_font_family) = "Arial";
  CefString(&browser_settings.fixed_font_family) = "Courier New";
  
  // 设置默认字号
  browser_settings.default_font_size = 16;

  // 指定启动URL
  std::string url;

  // 检查命令行参数中是否指定了URL
  if (command_line->HasSwitch("url")) {
    url = command_line->GetSwitchValue("url");
  }

  // 如果没有指定URL，使用默认页面
  if (url.empty()) {
    url = "https://www.chromium.org";
  }

  // 创建浏览器处理器
  CefRefPtr<SimpleHandler> handler(new SimpleHandler());

  // 创建浏览器窗口
  CefBrowserHost::CreateBrowser(window_info, handler, url, browser_settings,
                                 nullptr, nullptr);
}

