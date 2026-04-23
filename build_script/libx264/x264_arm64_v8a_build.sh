NDK=/Users/ibqo/Develop/git/github/android/ffmpeg4-android/android-sdk/android-ndk-r21e

PLATFORM=$NDK/platforms/android-21/arch-arm64/
TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/darwin-x86_64
SYSROOT=$NDK/toolchains/llvm/prebuilt/darwin-x86_64/sysroot
PREFIX=./android/arm64-v8a

function build_one
{
CC="$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android21-clang" \
CXX="$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android21-clang++" \
AR="$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android-ar" \
LD="$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android-ld" \
RANLIB="$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android-ranlib" \
STRIP="$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android-strip" \
./configure \
--prefix=$PREFIX \
--disable-shared \
--enable-static \
--enable-pic \
--enable-strip \
--host=aarch64-linux \
--cross-prefix=$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android- \
--sysroot=$SYSROOT \
--extra-cflags="-Os -fpic -I$SYSROOT/usr/include -I$SYSROOT/usr/include/aarch64-linux-android" \
--extra-ldflags="-L$PLATFORM/usr/lib64" \

$ADDITIONAL_CONFIGURE_FLAG
make clean
make -j4
make install
}

build_one
