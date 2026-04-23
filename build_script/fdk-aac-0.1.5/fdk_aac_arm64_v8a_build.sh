NDK=/Users/ibqo/Develop/git/github/android/ffmpeg4-android/android-sdk/android-ndk-r21e

PLATFORM=$NDK/platforms/android-21/arch-arm64/
TOOLCHAIN=$NDK/toolchains/aarch64-linux-android-4.9/prebuilt/darwin-x86_64
SYSROOT=$NDK/sysroot
PREFIX=$(pwd)/android/arm64-v8a

function build_one
{
CC="$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android21-clang" \
CXX="$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android21-clang++" \
CFLAGS="-Os -fpic -I$SYSROOT/usr/include -I$SYSROOT/usr/include/aarch64-linux-android" \
LDFLAGS="-L$PLATFORM/usr/lib64" \
./configure \
--prefix=$PREFIX \
--enable-shared \
--disable-static \
--host=aarch64-linux \
--with-sysroot=$SYSROOT

make clean
make -j4
make install
}

build_one
