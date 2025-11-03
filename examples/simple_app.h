#ifndef CEF_EXAMPLE_SIMPLE_APP_H_
#define CEF_EXAMPLE_SIMPLE_APP_H_

#include "include/cef_app.h"

// 实现应用程序级别的回调
class SimpleApp : public CefApp, public CefBrowserProcessHandler {
 public:
  SimpleApp();

  // CefApp方法:
  virtual CefRefPtr<CefBrowserProcessHandler> GetBrowserProcessHandler()
      OVERRIDE {
    return this;
  }

  // CefBrowserProcessHandler方法:
  virtual void OnContextInitialized() OVERRIDE;

 private:
  // 包含CEF引用计数的实现
  IMPLEMENT_REFCOUNTING(SimpleApp);
};

#endif  // CEF_EXAMPLE_SIMPLE_APP_H_

