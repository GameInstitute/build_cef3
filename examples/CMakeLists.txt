cmake_minimum_required(VERSION 3.19)

project(cef_example)

# ============================================
# CEF配置
# ============================================

# 设置CEF根目录
# 方法1: 使用环境变量
if(DEFINED ENV{CEF_ROOT})
    set(CEF_ROOT $ENV{CEF_ROOT})
# 方法2: 手动指定路径
elseif(WIN32)
    set(CEF_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../output/windows_x64/cef_binary_xxx_windows64_minimal")
elseif(APPLE)
    set(CEF_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../output/macos_x64/cef_binary_xxx_macosx64_minimal")
else()
    set(CEF_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../output/linux_x64/cef_binary_xxx_linux64_minimal")
endif()

# 检查CEF路径是否存在
if(NOT EXISTS "${CEF_ROOT}")
    message(FATAL_ERROR 
        "CEF路径不存在: ${CEF_ROOT}\n"
        "请设置环境变量 CEF_ROOT 或在CMakeLists.txt中指定正确的路径"
    )
endif()

message(STATUS "使用CEF: ${CEF_ROOT}")

# 添加CEF CMake模块路径
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CEF_ROOT}/cmake")

# 查找CEF包
find_package(CEF REQUIRED)

# ============================================
# 编译选项
# ============================================

# 使用C++17标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 启用优化
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# ============================================
# 添加可执行文件
# ============================================

# 源文件
set(EXAMPLE_SOURCES
    simple_app.cpp
    simple_app.h
    simple_handler.cpp
    simple_handler.h
)

# 平台特定源文件
if(WIN32)
    list(APPEND EXAMPLE_SOURCES
        simple_app_win.cpp
        resource.h
        simple.rc
    )
elseif(APPLE)
    list(APPEND EXAMPLE_SOURCES
        simple_app_mac.mm
    )
else()
    list(APPEND EXAMPLE_SOURCES
        simple_app_linux.cpp
    )
endif()

# 创建可执行文件
add_executable(cef_example ${EXAMPLE_SOURCES})

# ============================================
# 链接库
# ============================================

# 添加CEF包含目录
target_include_directories(cef_example PRIVATE
    ${CEF_ROOT}
)

# 链接CEF库
target_link_libraries(cef_example
    libcef_lib
    libcef_dll_wrapper
    ${CEF_STANDARD_LIBS}
)

# ============================================
# 设置可执行文件属性
# ============================================

# Windows特定设置
if(WIN32)
    # 设置为窗口应用程序
    set_target_properties(cef_example PROPERTIES
        WIN32_EXECUTABLE TRUE
    )
    
    # 添加清单文件
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/simple.exe.manifest")
        target_sources(cef_example PRIVATE
            "${CMAKE_CURRENT_SOURCE_DIR}/simple.exe.manifest"
        )
    endif()
endif()

# macOS特定设置
if(APPLE)
    set_target_properties(cef_example PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist"
    )
endif()

# ============================================
# 复制CEF资源文件
# ============================================

# 复制CEF二进制文件
if(WIN32)
    # Windows: 复制libcef.dll和其他DLL
    add_custom_command(
        TARGET cef_example POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CEF_ROOT}/Release/libcef.dll"
            "$<TARGET_FILE_DIR:cef_example>"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CEF_ROOT}/Release"
            "$<TARGET_FILE_DIR:cef_example>"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CEF_ROOT}/Resources"
            "$<TARGET_FILE_DIR:cef_example>"
    )
elseif(APPLE)
    # macOS: 复制framework
    add_custom_command(
        TARGET cef_example POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CEF_ROOT}/Release/Chromium Embedded Framework.framework"
            "$<TARGET_BUNDLE_CONTENT_DIR:cef_example>/Frameworks/Chromium Embedded Framework.framework"
    )
else()
    # Linux: 复制libcef.so和资源文件
    add_custom_command(
        TARGET cef_example POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CEF_ROOT}/Release/libcef.so"
            "$<TARGET_FILE_DIR:cef_example>"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CEF_ROOT}/Resources"
            "$<TARGET_FILE_DIR:cef_example>"
        # 创建符号链接
        COMMAND ${CMAKE_COMMAND} -E create_symlink
            "./libcef.so"
            "$<TARGET_FILE_DIR:cef_example>/libcef.so"
    )
endif()

# ============================================
# 安装规则
# ============================================

install(TARGETS cef_example
    RUNTIME DESTINATION bin
    BUNDLE DESTINATION .
)

# 安装CEF资源
install(DIRECTORY ${CEF_ROOT}/Resources/
    DESTINATION bin
    PATTERN ".*" EXCLUDE
)

# 安装CEF库
if(WIN32)
    install(FILES ${CEF_ROOT}/Release/libcef.dll
        DESTINATION bin
    )
elseif(NOT APPLE)
    install(FILES ${CEF_ROOT}/Release/libcef.so
        DESTINATION bin
    )
endif()

# ============================================
# 打印配置信息
# ============================================

message(STATUS "==========================================")
message(STATUS "CEF Example 配置完成")
message(STATUS "==========================================")
message(STATUS "CEF路径: ${CEF_ROOT}")
message(STATUS "构建类型: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++标准: C++${CMAKE_CXX_STANDARD}")
message(STATUS "==========================================")

