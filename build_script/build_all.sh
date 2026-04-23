#!/bin/bash

# 设置 NDK 路径
NDK="/Users/ibqo/Develop/git/github/android/ffmpeg4-android/android-sdk/android-ndk-r21e"
export http_proxy=http://127.0.0.1:10800
export https_proxy=http://127.0.0.1:10800

# 进入 build_script 目录
cd "$(dirname "$0")"
basepath="$(pwd)"
echo "Base path: $basepath"

# 编译 x264
echo "=== 编译 x264 ==="
cd libx264
for arch in arm arm64-v8a x86 x86_64; do
    echo "编译 x264 for $arch"
    if [ -f "x264_${arch}_build.sh" ]; then
        bash "x264_${arch}_build.sh"
    else
        echo "跳过 $arch，脚本不存在"
    fi
done
cd ..

# 编译 fdk-aac
echo "=== 编译 fdk-aac ==="
cd fdk-aac-0.1.5
for arch in arm arm64-v8a x86 x86_64; do
    echo "编译 fdk-aac for $arch"
    if [ -f "fdk_aac_${arch}_build.sh" ]; then
        bash "fdk_aac_${arch}_build.sh"
    else
        echo "跳过 $arch，脚本不存在"
    fi
done
cd ..

# 编译 ffmpeg
echo "=== 编译 ffmpeg ==="
cd ../ffmpeg-3.2.5
for arch in arm arm-v7a arm64-v8a x86 x86_64; do
    echo "编译 ffmpeg for $arch"
    if [ -f "../build_script/jianxi_ffmpeg_${arch}_build.sh" ]; then
        bash "../build_script/jianxi_ffmpeg_${arch}_build.sh"
    else
        echo "跳过 $arch，脚本不存在"
    fi
done
cd ..

echo "=== 编译完成 ==="
