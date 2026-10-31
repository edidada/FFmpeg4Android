# zlib (git submodule, v1.3.1) built with a thin CMake pass.
#
# Why not the submodule's own CMakeLists.txt? Two problems with in-tree use:
#   1. on first configure it RENAMES the source-tree zconf.h to
#      zconf.h.included, permanently dirtying the submodule;
#   2. with the NDK toolchain the generic tracked zconf.h would win over the
#      generated one via quoted-include same-dir priority, silently disabling
#      Z_HAVE_UNISTD_H ("lseek undeclared" in gzlib.c).
# So: zlib.h/	priv headers + the 15 sources are COPIED into the build dir and
# compiled only from there; zconf.h is configured from zconf.h.cmakein with
# Z_HAVE_UNISTD_H=1. The submodule stays completely pristine.
set(ZLIB_GEN ${CMAKE_BINARY_DIR}/zlib_gen)

file(COPY
  ${ZLIB_SRC}/zlib.h
  ${ZLIB_SRC}/crc32.h
  ${ZLIB_SRC}/deflate.h
  ${ZLIB_SRC}/gzguts.h
  ${ZLIB_SRC}/inffast.h
  ${ZLIB_SRC}/inffixed.h
  ${ZLIB_SRC}/inflate.h
  ${ZLIB_SRC}/inftrees.h
  ${ZLIB_SRC}/trees.h
  ${ZLIB_SRC}/zutil.h
  DESTINATION ${ZLIB_GEN})
file(COPY
  ${ZLIB_SRC}/adler32.c
  ${ZLIB_SRC}/compress.c
  ${ZLIB_SRC}/crc32.c
  ${ZLIB_SRC}/deflate.c
  ${ZLIB_SRC}/gzclose.c
  ${ZLIB_SRC}/gzlib.c
  ${ZLIB_SRC}/gzread.c
  ${ZLIB_SRC}/gzwrite.c
  ${ZLIB_SRC}/inflate.c
  ${ZLIB_SRC}/infback.c
  ${ZLIB_SRC}/inftrees.c
  ${ZLIB_SRC}/inffast.c
  ${ZLIB_SRC}/trees.c
  ${ZLIB_SRC}/uncompr.c
  ${ZLIB_SRC}/zutil.c
  DESTINATION ${ZLIB_GEN})

# zconf.h.cmakein uses #cmakedefine Z_HAVE_UNISTD_H; Android has unistd.h.
set(Z_HAVE_UNISTD_H 1)
configure_file(${ZLIB_SRC}/zconf.h.cmakein ${ZLIB_GEN}/zconf.h @ONLY)

add_library(zlib SHARED
  ${ZLIB_GEN}/adler32.c
  ${ZLIB_GEN}/compress.c
  ${ZLIB_GEN}/crc32.c
  ${ZLIB_GEN}/deflate.c
  ${ZLIB_GEN}/gzclose.c
  ${ZLIB_GEN}/gzlib.c
  ${ZLIB_GEN}/gzread.c
  ${ZLIB_GEN}/gzwrite.c
  ${ZLIB_GEN}/inflate.c
  ${ZLIB_GEN}/infback.c
  ${ZLIB_GEN}/inftrees.c
  ${ZLIB_GEN}/inffast.c
  ${ZLIB_GEN}/trees.c
  ${ZLIB_GEN}/uncompr.c
  ${ZLIB_GEN}/zutil.c
  ${ZLIB_GEN}/zlib.h)

# Headers resolve exclusively from the generated/copied set.
target_include_directories(zlib PUBLIC ${ZLIB_GEN})
set_target_properties(zlib PROPERTIES OUTPUT_NAME z)

# Bring the submodule headers into the IDE index as well.
target_sources(zlib PRIVATE
  ${ZLIB_SRC}/zlib.h
  ${ZLIB_SRC}/crc32.h
  ${ZLIB_SRC}/deflate.h
  ${ZLIB_SRC}/gzguts.h
  ${ZLIB_SRC}/inffast.h
  ${ZLIB_SRC}/inffixed.h
  ${ZLIB_SRC}/inflate.h
  ${ZLIB_SRC}/inftrees.h
  ${ZLIB_SRC}/trees.h
  ${ZLIB_SRC}/zutil.h)
