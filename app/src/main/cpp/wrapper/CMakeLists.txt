# The JNI wrapper: ffmpeg command-line frontend (ffmpeg.c/cmdutils.c/...)
# built as a shared lib that links the in-tree ffmpeg + zlib targets (they are
# propagated to Gradle's APK packaging automatically). Exposes the JNI entry
# points used by the app (com.mabeijianxi.jianxiffmpegcmd).
add_library(jxffmpegrun SHARED
  cmdutils.c
  ffmpeg.c
  ffmpeg_filter.c
  ffmpeg_opt.c
  jx_ffmpeg_cmd_run.c)

# Include paths needed by the ffmpeg CLI frontend:
#  - this dir (ffmpeg.h, cmdutils.h)
#  - the per-ABI generated config.h (takes priority over any in-tree one)
#  - the ffmpeg source tree (public + internal headers) / zlib headers
#  - log for Android logging
find_library(log-lib log)

target_include_directories(jxffmpegrun PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${FFMPEG_GENERATED}/${ANDROID_ABI}
  ${FFMPEG_SRC}
  wrapper)

target_link_libraries(jxffmpegrun
  avformat
  avcodec
  avfilter
  swresample
  swscale
  avutil
  zlib
  ${log-lib})

# Debug/CLion convenience: also copy the shared libs next to jxffmpegrun so
# they can be bundled/loaded outside of Gradle packaging. Gradle itself picks
# them up as direct link dependencies of this target.
set(FFMPEG_LIB_NAMES avutil avcodec avformat avfilter swresample swscale zlib)
foreach(LIB ${FFMPEG_LIB_NAMES})
  add_custom_command(TARGET jxffmpegrun POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      $<TARGET_FILE:${LIB}> $<TARGET_FILE_DIR:jxffmpegrun>/
    COMMENT "Copying lib${LIB}.so next to jxffmpegrun")
endforeach()
