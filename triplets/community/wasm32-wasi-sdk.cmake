set(VCPKG_ENV_PASSTHROUGH_UNTRACKED EMSCRIPTEN_ROOT EMSDK PATH)

if(NOT DEFINED ENV{WASI_SDK_PATH})
   find_path(WASI_SDK_PATH "wasi-sdk")
else()
   set(WASI_SDK_PATH "$ENV{WASI_SDK_PATH}")
endif()

if(NOT WASI_SDK_PATH)
   if(NOT DEFINED ENV{WASI_SDK_PATH})
      message(FATAL_ERROR "The wasi-sdk not found in PATH")
   endif()
   set(WASI_SDK_PATH "$ENV{WASI_SDK_PATH}")
endif()

if(NOT EXISTS "${WASI_SDK_PATH}/share/cmake/wasi-sdk.cmake")
   message(FATAL_ERROR "wasi-sdk.cmake toolchain file not found")
endif()

set(VCPKG_TARGET_ARCHITECTURE wasm32)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_CMAKE_SYSTEM_NAME Wasi)
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${WASI_SDK_PATH}/share/cmake/wasi-sdk.cmake")
