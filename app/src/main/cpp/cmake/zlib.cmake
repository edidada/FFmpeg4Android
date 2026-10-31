# zlib (git submodule, v1.3.1) built IN-TREE with its own CMakeLists.txt.
# The NDK toolchain file (set by the top-level CMakeLists.txt / Gradle) does all
# the cross-compilation; no bash/make involved. Its `zlib` target already
# carries the public include dirs and becomes a link dependency of
# libavcodec/libavformat/wrapper, so CMake builds zlib before anything that
# needs it ("zlib first, ffmpeg depends on zlib").
add_subdirectory(${ZLIB_SRC} ${CMAKE_BINARY_DIR}/zlib EXCLUDE_FROM_ALL)
