include_guard()


function(detect_macos_version version)
    if (APPLE)
        find_program(SW_VERS_EXECUTABLE sw_vers)
        execute_process(
            COMMAND "${SW_VERS_EXECUTABLE}" -productVersion
            OUTPUT_VARIABLE MACOS_VERSION
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        set(${version} "${MACOS_VERSION}" PARENT_SCOPE)
    endif()
endfunction()

detect_macos_version(MACOS_VERSION)

set(LLVM_BIN_PATHS)

list(APPEND LLVM_BIN_PATHS 
    "$ENV{VCPKG_LLVM_PATH}/bin"
    "$ENV{LLVM_PATH}/bin"
    "$ENV{LLVMInstallDir}/bin"
    "$ENV{PROGRAMFILES}/LLVM/bin"
    "/usr/bin"
)

set(LLVM_LIB_PATHS)
foreach(LLVM_BIN_PATH IN LISTS LLVM_BIN_PATHS)
    if(EXISTS "${LLVM_BIN_PATH}/clang++${CMAKE_EXECUTABLE_SUFFIX}")
        list(INSERT CMAKE_PROGRAM_PATH 0 "${LLVM_BIN_PATH}")
        list(APPEND LLVM_LIB_PATHS "${LLVM_BIN_PATH}/../lib/c++" "${LLVM_BIN_PATH}/../lib")
        break()
    endif()
endforeach()

# If requested by the portfile, use clang-cl.
if (WIN32 AND (VCPKG_CXX_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC" OR VCPKG_C_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC"))
    find_program(CLANGCL_EXECUTBALE NAMES "clang-cl"
        REQUIRED
        DOC "clang-cl executable"
    )
    set(CLANG_EXECUTBALE "${CLANGCL_EXECUTBALE}")
    set(CLANGPP_EXECUTBALE "${CLANGCL_EXECUTBALE}")
else()
    find_program(CLANGPP_EXECUTBALE NAMES "clang++"
        REQUIRED
        DOC "clang++ executable"
    )
    find_program(CLANG_EXECUTBALE NAMES "clang"
        REQUIRED
        DOC "clang executable"
    )
endif()

set(CMAKE_C_COMPILER "${CLANG_EXECUTBALE}" CACHE STRING "" FORCE)
set(CMAKE_CXX_COMPILER "${CLANGPP_EXECUTBALE}" CACHE STRING "" FORCE)

if (NOT CLANGCL_EXECUTBALE AND NOT "${VCPKG_NO_LLVM_TOOLS}" STREQUAL "ON")
    find_program(LLD_LINKER NAMES "lld"
        PATHS ${LLVM_BIN_PATHS}
        DOC "LLD linker executable"
    )
    if(LLD_LINKER)
        set(VCPKG_LINKER_FLAGS "${VCPKG_LINKER_FLAGS} -fuse-ld=lld")
    endif()
endif()

# Common flags
set(VCPKG_CCXX_FLAGS " -Wno-implicit-function-declaration ")

if (NOT CLANGCL_EXECUTBALE)
    set(VCPKG_CCXX_FLAGS " -fvisibility=hidden -fvisibility-inlines-hidden ")
endif()

if (NOT WIN32)
    set(VCPKG_CCXX_FLAGS " -fPIC ")
endif()

# File map for debug, macros
cmake_path(GET CMAKE_BINARY_DIR PARENT_PATH CMAKE_BINARY_DIR_DIR)
cmake_path(GET CMAKE_BINARY_DIR_DIR PARENT_PATH CMAKE_BUILDTREES_DIR)
set(VCPKG_CXX_FLAGS_RELEASE " ${VCPKG_CXX_FLAGS_RELEASE} -ffile-prefix-map=${CMAKE_BINARY_DIR}=. -ffile-prefix-map=${CMAKE_CURRENT_SOURCE_DIR}=. -ffile-prefix-map=${CMAKE_SOURCE_DIR}=. -ffile-prefix-map=$ENV{HOME}=. -ffile-prefix-map=${CMAKE_BUILDTREES_DIR}=.")

# Language flags
set(CMAKE_C_STANDARD 17 CACHE STRING "" FORCE)
set(CMAKE_CXX_STANDARD 20 CACHE STRING "" FORCE)
if(WIN32)
    if(CLANGCL_EXECUTBALE)
        set(VCPKG_C_FLAGS " ${VCPKG_CCXX_FLAGS} ${VCPKG_C_FLAGS} ")
        set(VCPKG_CXX_FLAGS " ${VCPKG_CCXX_FLAGS} ${VCPKG_CXX_FLAGS} ")
    else()
        set(VCPKG_C_FLAGS " ${VCPKG_CCXX_FLAGS} ${VCPKG_C_FLAGS} ")
        set(VCPKG_CXX_FLAGS " ${VCPKG_CCXX_FLAGS} ${VCPKG_CXX_FLAGS} ")
    endif()
else()
    set(VCPKG_C_FLAGS " ${VCPKG_CCXX_FLAGS} ${VCPKG_C_FLAGS} ")
    set(VCPKG_CXX_FLAGS " ${VCPKG_CCXX_FLAGS} ${VCPKG_CXX_FLAGS} ")
endif()

# Link the LLVM's libc++
if(APPLE AND MACOS_VERSION VERSION_LESS 13)
    foreach(LLVM_LIB_PATH IN LISTS LLVM_LIB_PATHS)
        if(EXISTS "${LLVM_LIB_PATH}")
            # resolve the path to the libc++ and libc++abi
            cmake_path(ABSOLUTE_PATH LLVM_LIB_PATH NORMALIZE OUTPUT_VARIABLE LLVM_LIB_PATH)
            set(VCPKG_CXX_FLAGS " ${VCPKG_CXX_FLAGS} -Wl,${LLVM_LIB_PATH}/libc++.a,${LLVM_LIB_PATH}/libc++abi.a ")
            set(VCPKG_C_FLAGS " ${VCPKG_C_FLAGS} -Wl,${LLVM_LIB_PATH}/libc++.a,${LLVM_LIB_PATH}/libc++abi.a ")
            break()
        endif()
    endforeach()
endif()

# Release flags
if(NOT APPLE OR NOT MACOS_VERSION VERSION_LESS 13)
    set(VCPKG_CXX_FLAGS_RELEASE " ${VCPKG_CXX_FLAGS} -flto=thin ")
    set(VCPKG_C_FLAGS_RELEASE " ${VCPKG_C_FLAGS} -flto=thin ")
    if (NOT "${VCPKG_NO_LLVM_TOOLS}" STREQUAL "ON")
        set(VCPKG_DETECTED_CMAKE_SHARED_LINKER_FLAGS " ${VCPKG_DETECTED_CMAKE_SHARED_LINKER_FLAGS} -flto=thin ")
        set(VCPKG_DETECTED_CMAKE_STATIC_LINKER_FLAGS " ${VCPKG_DETECTED_CMAKE_STATIC_LINKER_FLAGS} -flto=thin ")
        set(VCPKG_DETECTED_CMAKE_EXE_LINKER_FLAGS " ${VCPKG_DETECTED_CMAKE_EXE_LINKER_FLAGS} -flto=thin ")
    endif()
endif()
