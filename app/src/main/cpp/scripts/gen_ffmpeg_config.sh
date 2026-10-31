#!/usr/bin/env bash
# Generate ffmpeg 3.2.5 config.h + generated list files for each Android ABI.
# Runs ffmpeg configure with the NDK clang toolchain, copies generated files
# OUT of the submodule (kept pristine), and patches ARCH_* / CONFIG_ZLIB.
# NOTE: ffmpeg 3.2.5 only auto-generates bsf_list.c + protocol_list.c at
# configure time; codec/parser/filter/muxer/demuxer lists do not exist yet.
set -e
NDK=C:/Users/wdidada/AppData/Local/Android/Sdk/ndk/27.0.12077973
TOOL=$NDK/toolchains/llvm/prebuilt/windows-x86_64
SYS=$TOOL/sysroot
HERE=$(cd "$(dirname "$0")/.." && pwd)
FF=$HERE/ffmpeg
OUT=$HERE/ffmpeg_generated
API=21
clean_ff() {
  cd "$FF"
  git checkout . >/dev/null 2>&1 || true
  rm -f config.h config.mak config.log .config Makefile
  rm -rf ffbuild doc/config.texi
  rm -f libavutil/avconfig.h libavutil/ffversion.h
  rm -f libavcodec/bsf_list.c
  rm -f libavformat/protocol_list.c
  cd "$HERE"
}
gen() {
  local ABI=$1 ARCH=$2 CPU=$3 TR=$4 ADEF=$5
  local CC=$TOOL/bin/$TR$API-clang
  local CXX=$TOOL/bin/$TR$API-clang++
  local AR=$TOOL/bin/llvm-ar NM=$TOOL/bin/llvm-nm RANLIB=$TOOL/bin/llvm-ranlib
  local STRIP=$TOOL/bin/llvm-strip AS=$CC
  echo "===== configure ffmpeg for $ABI (arch=$ARCH cpu=$CPU) ====="
  ( cd "$FF" && ./configure --enable-cross-compile --target-os=linux \
      --arch=$ARCH --cpu=$CPU \
      --cc="$CC" --cxx="$CXX" --ar="$AR" --nm="$NM" --ranlib="$RANLIB" --strip="$STRIP" --as="$AS" \
      --sysroot="$SYS" \
      --disable-asm --disable-neon --disable-programs --disable-doc \
      --disable-avdevice --disable-postproc --disable-symver \
      --disable-htmlpages --disable-manpages --disable-podpages --disable-txtpages \
      --disable-zlib --disable-bzlib --disable-lzma --disable-iconv )
  ( cd "$FF" && bash version.sh . libavutil/ffversion.h )
  local D=$OUT/$ABI
  mkdir -p "$D/libavcodec" "$D/libavfilter" "$D/libavformat" "$D/libavutil"
  cp "$FF/config.h"                   "$D/config.h"
  cp "$FF/libavutil/avconfig.h"       "$D/libavutil/avconfig.h"
  cp "$FF/libavutil/ffversion.h"      "$D/libavutil/ffversion.h"
  [ -f "$FF/libavcodec/bsf_list.c" ]    && cp "$FF/libavcodec/bsf_list.c"    "$D/libavcodec/"
  [ -f "$FF/libavformat/protocol_list.c" ] && cp "$FF/libavformat/protocol_list.c" "$D/libavformat/"
  sed -i "s/#define $ADEF 0/#define $ADEF 1/" "$D/config.h"
  sed -i "s/#define CONFIG_ZLIB 0/#define CONFIG_ZLIB 1/" "$D/config.h"
  clean_ff
  echo "----- $ABI done -----"
}
rm -rf "$OUT"
gen arm64-v8a   aarch64  armv8-a   aarch64-linux-android    ARCH_AARCH64
gen armeabi-v7a arm      armv7-a   armv7a-linux-androideabi ARCH_ARM
gen x86         x86      i686      i686-linux-android        ARCH_X86
gen x86_64      x86_64   x86_64    x86_64-linux-android      ARCH_X86_64
echo "ALL DONE -> $OUT"
