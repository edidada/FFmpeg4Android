# Created by jianxi on 2017/6/4
# https://github.com/mabeijianxi
# mabeijianxi@gmail.com
basepath=$(cd `dirname $0`; pwd)
export TMPDIR=$basepath/ffmpegtemp
# NDK的路径，根据自己的安装位置进行设置
NDK=/Users/ibqo/Develop/git/github/android/ffmpeg4-android/android-sdk/android-ndk-r21e
# 编译针对的平台，可以根据自己的需求进行设置
# 这里选择最低支持android-14, arm架构，生成的so库是放在
# libs/armeabi文件夹下的，若针对x86架构，要选择arch-x86
PLATFORM=$NDK/platforms/android-21/arch-arm64
# 工具链的路径，根据编译的平台不同而不同
# arm-linux-androideabi-4.9与上面设置的PLATFORM对应，4.9为工具的版本号，
# 根据自己安装的NDK版本来确定，一般使用最新的版本
TOOLCHAIN=$NDK/toolchains/aarch64-linux-android-4.9/prebuilt/darwin-x86_64
# NDK sysroot路径
SYSROOT=$NDK/sysroot
# 设置LD_LIBRARY_PATH，指向包含crtbegin_dynamic.o和crtend_android.o的目录
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$NDK/platforms/android-21/arch-arm64/usr/lib
# 设置PKG_CONFIG_PATH，指向fdk-aac的pkgconfig目录
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$basepath/fdk-aac-0.1.5/android/arm64-v8a/lib/pkgconfig

CPU=arm64-v8a

echo $basepath

FDK_INCLUDE=$basepath/fdk-aac-0.1.5/android/arm64-v8a/include

FDK_LIB=$basepath/fdk-aac-0.1.5/android/arm64-v8a/lib

X264_INCLUDE=$basepath/libx264/android/arm64-v8a/include

X264_LIB=$basepath/libx264/android/arm64-v8a/lib

FF_EXTRA_CFLAGS=""
FF_CFLAGS="-O3 -Wall -pipe \
-ffast-math \
-fstrict-aliasing -Werror=strict-aliasing \
-Wno-psabi -Wa,--noexecstack \
-DANDROID  "
PREFIX=../build_script/android/$CPU

rm "./compat/strtod.o"

export LIBS="$FDK_LIB/libfdk-aac.a"

cd ../ffmpeg-3.2.5


build_one(){
./configure \
--prefix=$PREFIX \
--enable-cross-compile \
--disable-runtime-cpudetect \
--enable-asm \
--arch=aarch64 \
--target-os=android \
--cc=$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android21-clang \
--cross-prefix=$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android- \
--disable-stripping \
--nm=$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android-nm \
--sysroot=$NDK/toolchains/llvm/prebuilt/darwin-x86_64/sysroot \
--extra-cflags="-I$X264_INCLUDE -I$FDK_INCLUDE -I$SYSROOT/usr/include -I$SYSROOT/usr/include/aarch64-linux-android" \
--extra-ldflags="-L$FDK_LIB -L$X264_LIB -L$PLATFORM/usr/lib64 -L$NDK/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/21" \
--enable-gpl \
--enable-nonfree \
--enable-shared \
--disable-static \
--enable-version3 \
--enable-pthreads \
--enable-small \
--disable-vda \
--disable-iconv \
--disable-encoders \
--enable-libx264 \
--enable-neon \
--enable-yasm \
--enable-libfdk_aac \
--enable-encoder=libx264 \
--enable-encoder=libfdk_aac \
--enable-encoder=mjpeg \
--enable-encoder=png \
--enable-nonfree \
--enable-muxers \
--enable-muxer=mov \
--enable-muxer=mp4 \
--enable-muxer=h264 \
--enable-muxer=avi \
--disable-decoders \
--enable-decoder=aac \
--enable-decoder=aac_latm \
--enable-decoder=h264 \
--enable-decoder=mpeg4 \
--enable-decoder=mjpeg \
--enable-decoder=png \
--disable-demuxers \
--enable-demuxer=image2 \
--enable-demuxer=h264 \
--enable-demuxer=aac \
--enable-demuxer=avi \
--enable-demuxer=mpc \
--enable-demuxer=mov \
--enable-demuxer=mpegts \
--disable-parsers \
--enable-parser=aac \
--enable-parser=ac3 \
--enable-parser=h264 \
--enable-protocols \
--enable-zlib \
--enable-avfilter \
--disable-outdevs \
--disable-ffprobe \
--disable-ffplay \
--disable-ffmpeg \
--disable-ffserver \
--disable-debug \
--disable-ffprobe \
--disable-ffplay \
--disable-ffmpeg \
--disable-postproc \
--disable-avdevice \
--disable-symver \
--disable-stripping
}

build_one



make -j16
make install

cp $FDK_LIB/libfdk-aac.so ../build_script/android/$CPU/lib


