cmake_minimum_required(VERSION 3.22.1)

# ---------- NDK discovery (must happen BEFORE project(), which loads the
# toolchain file) ----------
if(NOT DEFINED NDK_PATH)
  if(DEFINED ENV{ANDROID_NDK_HOME})
    set(NDK_PATH $ENV{ANDROID_NDK_HOME})
  else()
    set(NDK_PATH "C:/Users/wdidada/AppData/Local/Android/Sdk/ndk/27.0.12077973")
  endif()
endif()

# Build natively on Windows for Android even when opened from CLion / command
# line without Gradle: fall back to the NDK CMake toolchain if none was given.
if(NOT DEFINED CMAKE_TOOLCHAIN_FILE)
  set(CMAKE_TOOLCHAIN_FILE "${NDK_PATH}/build/cmake/android.toolchain.cmake"
      CACHE FILEPATH "Android NDK CMake toolchain")
  set(ANDROID_NDK "${NDK_PATH}" CACHE PATH "")
  if(NOT DEFINED ANDROID_ABI)
    set(ANDROID_ABI "arm64-v8a" CACHE STRING "Android ABI")
  endif()
  if(NOT DEFINED ANDROID_PLATFORM)
    set(ANDROID_PLATFORM "android-21" CACHE STRING "Android platform (API level)")
  endif()
endif()

project(ffmpeg4android C CXX)

# Source / output locations shared by the zlib, ffmpeg and wrapper targets.
set(FFMPEG_SRC      ${CMAKE_SOURCE_DIR}/ffmpeg)
set(FFMPEG_GENERATED ${CMAKE_SOURCE_DIR}/ffmpeg_generated)
set(ZLIB_SRC        ${CMAKE_SOURCE_DIR}/zlib)

# zlib (its own CMake build, cross-compiled with the same NDK toolchain) +
# ffmpeg (pure-CMake build of its sources, links zlib) + the JNI wrapper.
include(cmake/zlib.cmake)
include(cmake/ffmpeg.cmake)
add_subdirectory(wrapper)
