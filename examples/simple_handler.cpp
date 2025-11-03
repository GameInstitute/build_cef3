#include "simple_handler.h"

#include <sstream>
#include <string>

#include "include/base/cef_callback.h"
#include "include/cef_app.h"
#include "include/cef_parser.h"
#include "include/views/cef_browser_view.h"
#include "include/views/cef_window.h"
#include "include/wrapper/cef_closure_task.h"
#include "include/wrapper/cef_helpers.h"

SimpleHandler::SimpleHandler() : is_closing_(false) {}

SimpleHandler::~SimpleHandler() {}

void SimpleHandler::OnTitleChange(CefRefPtr<CefBrowser> browser,
                                   const CefString& title) {
  CEF_REQUIRE_UI_THREAD();

  // 设置窗口标题
#if defined(OS_WIN)
  // Windows平台
  CefWindowHandle hwnd = browser->GetHost()->GetWindowHandle();
  if (hwnd) {
    SetWindowText(hwnd, std::wstring(title).c_str());
  }
#endif
}

void SimpleHandler::OnAfterCreated(CefRefPtr<CefBrowser> browser) {
  CEF_REQUIRE_UI_THREAD();

  // 将浏览器添加到列表
  browser_list_.push_back(browser);
}

bool SimpleHandler::DoClose(CefRefPtr<CefBrowser> browser) {
  CEF_REQUIRE_UI_THREAD();

  // 允许关闭操作继续
  return false;
}

void SimpleHandler::OnBeforeClose(CefRefPtr<CefBrowser> browser) {
  CEF_REQUIRE_UI_THREAD();

  // 从列表中移除浏览器
  BrowserList::iterator bit = browser_list_.begin();
  for (; bit != browser_list_.end(); ++bit) {
    if ((*bit)->IsSame(browser)) {
      browser_list_.erase(bit);
      break;
    }
  }

  if (browser_list_.empty()) {
    // 所有浏览器窗口都已关闭，退出消息循环
    CefQuitMessageLoop();
  }
}

void SimpleHandler::OnLoadError(CefRefPtr<CefBrowser> browser,
                                 CefRefPtr<CefFrame> frame,
                                 ErrorCode errorCode,
                                 const CefString& errorText,
                                 const CefString& failedUrl) {
  CEF_REQUIRE_UI_THREAD();

  // 不要为下载错误显示错误页面
  if (errorCode == ERR_ABORTED)
    return;

  // 显示加载错误消息
  std::stringstream ss;
  ss << "<html><body bgcolor=\"white\">"
        "<h2>页面加载失败</h2>"
        "<p><b>URL:</b> "
     << std::string(failedUrl) << "</p>"
     << "<p><b>错误代码:</b> " << errorCode << "</p>"
     << "<p><b>错误描述:</b> " << std::string(errorText) << "</p>"
     << "<hr>"
     << "<p>这可能是因为:</p>"
     << "<ul>"
     << "<li>网络连接问题</li>"
     << "<li>URL地址不正确</li>"
     << "<li>服务器无响应</li>"
     << "</ul>"
     << "</body></html>";

  frame->LoadURL(GetDataURI(ss.str(), "text/html"));
}

void SimpleHandler::CloseAllBrowsers(bool force_close) {
  if (!CefCurrentlyOn(TID_UI)) {
    // 在UI线程上执行
    CefPostTask(TID_UI, base::BindOnce(&SimpleHandler::CloseAllBrowsers, this,
                                        force_close));
    return;
  }

  if (browser_list_.empty())
    return;

  is_closing_ = true;

  BrowserList::const_iterator it = browser_list_.begin();
  for (; it != browser_list_.end(); ++it) {
    (*it)->GetHost()->CloseBrowser(force_close);
  }
}

