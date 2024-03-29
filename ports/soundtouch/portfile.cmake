vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    GITHUB_HOST https://codeberg.org
    REPO soundtouch/soundtouch
    REF d3f7e2530ba8f21df9d3b68bcb87c070dba6bb79
    SHA512 5f1e2362e5e25228eb7082d89795a1985c0fc47f5d60ffc433a449d12857fc7241bd47199f31e603923d2a82ad3429892ff51087d345cd7bcd0a14f63510efe8
    HEAD_REF master
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
  FEATURES
    soundstretch SOUNDSTRETCH
    soundtouchdll SOUNDTOUCH_DLL
)

if(SOUNDTOUCH_DLL)
  vcpkg_check_linkage(ONLY_DYNAMIC_LIBRARY)
endif()

vcpkg_cmake_configure(
  SOURCE_PATH "${SOURCE_PATH}"
  OPTIONS ${FEATURE_OPTIONS}
)
vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/SoundTouch)
vcpkg_fixup_pkgconfig()
vcpkg_copy_pdbs()

if(SOUNDSTRETCH)
  vcpkg_copy_tools(TOOL_NAMES soundstretch AUTO_CLEAN)
endif()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING.TXT")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
