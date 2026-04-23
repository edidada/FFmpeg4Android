#!/bin/bash

# 设置 NDK 路径
NDK="/Users/ibqo/Develop/git/github/android/ffmpeg4-android/android-sdk/android-ndk-r21e"
export http_proxy=http://127.0.0.1:10800
export https_proxy=http://127.0.0.1:10800

# 进入 build_script 目录
cd "$(dirname "$0")"
basepath="$(pwd)"
echo "Base path: $basepath"

# 创建必要的目录
mkdir -p ffmpegtemp

# 编译 x264 for arm64-v8a
echo "=== 编译 x264 for arm64-v8a ==="
cd libx264
if [ -f "x264_arm64_v8a_build.sh" ]; then
    bash "x264_arm64_v8a_build.sh"
else
    echo "x264_arm64_v8a_build.sh 不存在"
fi
cd ..

# 编译 fdk-aac for arm64-v8a
echo "=== 编译 fdk-aac for arm64-v8a ==="
cd fdk-aac-0.1.5
if [ -f "fdk_aac_arm64_v8a_build.sh" ]; then
    bash "fdk_aac_arm64_v8a_build.sh"
else
    echo "fdk_aac_arm64_v8a_build.sh 不存在"
fi
cd ..

# 编译 ffmpeg for arm64-v8a
echo "=== 编译 ffmpeg for arm64-v8a ==="
cd ../ffmpeg-3.2.5
if [ -f "../build_script/jianxi_ffmpeg_arm64_v8a_build.sh" ]; then
    bash "../build_script/jianxi_ffmpeg_arm64_v8a_build.sh"
else
    echo "jianxi_ffmpeg_arm64_v8a_build.sh 不存在"
fi
cd ..

echo "=== 测试编译完成 ==="
