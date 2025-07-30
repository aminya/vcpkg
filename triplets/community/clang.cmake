if(${PORT} MATCHES "soundtouch")
	set(VCPKG_LIBRARY_LINKAGE dynamic)
else()
	set(VCPKG_LIBRARY_LINKAGE static)
endif()

if(${PORT} MATCHES "botan")
    set(VCPKG_NO_LLVM_TOOLS ON)
endif()

set(VCPKG_ENV_PASSTHROUGH_UNTRACKED "LLVM_PATH;LLVMInstallDir;VCPKG_LLVM_PATH")
set(VCPKG_ENV_PASSTHROUGH "CC;CXX")
