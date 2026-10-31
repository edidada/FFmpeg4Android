# Windows 原生 CMake + NDK 编译 ffmpeg 源码（本工程）

本工程把 ffmpeg、zlib 作为 git submodule 放在 `app/src/main/cpp/` 下，
**全部用 Windows 原生 CMake（CMake + Ninja + NDK toolchain）从源码交叉编译**，
不以任何 bash/make 为前置依赖，也不需要 git-bash/cygwin。

构建顺序：`libz.so（zlib 先编译）→ libavutil/libavcodec/… （ffmpeg，依赖 zlib）`
→ `libjxffmpegrun.so`（JNI wrapper，链接全部库）。依赖顺序由 CMake 目标依赖自动保证。

## 目录结构

```
app/src/main/cpp/
  CMakeLists.txt            # 顶层：NDK 工具链兜底 + zlib/ffmpeg 子构建 + add_subdirectory(wrapper)
  cmake/
    zlib.cmake              # add_subdirectory(zlib)：zlib 自带 CMake，交叉编译出 libz.so
    ffmpeg.cmake            # 纯 CMake 直接编 ffmpeg 各库源码（无需 configure/make）
    ffmpeg_sources.cmake    # 自动生成的各 ABI ffmpeg 源码清单（勿手改）
  scripts/
    gen_ffmpeg_config.sh    # （维护用，一次性）ffmpeg configure 生成 config.h 等到 ffmpeg_generated/<abi>
    gen_ffmpeg_src_list.ps1 # Windows 原生成脚本：按 config.h 开关求值各库 Makefile 的 OBJS 生成源码清单
  ffmpeg/                   # git submodule，切到 n3.2.5（源码）
  zlib/                     # git submodule，切到 v1.3.1（源码）
  ffmpeg_generated/         # 各 ABI 的 config.h/avconfig.h/ffversion.h/bsf_list.c/protocol_list.c
  wrapper/                  # JNI wrapper 源码（ffmpeg.c/cmdutils.c/...）+ CMakeLists.txt
```

## 命令行编译（与 Gradle 之外独立验证）

```sh
cd app/src/main/cpp
cmake -S . -B build/arm64-v8a -G Ninja -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-21
cmake --build build/arm64-v8a --target zlib     # 第一步：zlib
cmake --build build/arm64-v8a                    # 第二步：ffmpeg（依赖 zlib）+ wrapper
```

NDK 路径取自环境变量 `ANDROID_NDK_HOME`，或顶层 CMakeLists.txt 里的默认值；
Gradle 构建时由 `androidx externalNativeBuild` 自行传 toolchain/ABI，兜底逻辑自动跳过。
Gradle 的 `abiFilters` 覆盖 4 个 ABI，会按 ABI 分别 configure+build。

产物在每个构建目录下：`libz.so`、`libavutil.so / libavcodec.so / libavformat.so /
libavfilter.so / libswresample.so / libswscale.so`、`libjxffmpegrun.so`
（wrapper 的 POST_BUILD 会把所有 .so 拷到 `libjxffmpegrun.so` 旁边便于打包/运行）。

## 在 CLion 中打开 cpp 目录

1. CLion → Open → 选择 `app/src/main/cpp`（或工程根目录后再定位该 CMakeLists）。
2. CMake Profile 里可用 options 覆盖：
   `-DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-21 -DNDK_PATH=...`
   （不传时使用默认 NDK 路径 / arm64-v8a / android-21，由顶层 CMakeLists 自动装上
   NDK toolchain file，因此不需要配置交叉编译器）。
3. 因为 zlib/ffmpeg/wrapper 都在同一个 CMake 工程里（不再用 ExternalProject），
   CLion 可以完整索引、跳转、重构 zlib/ffmpeg/wrapper 的源码。

## 纯 CMake 编 ffmpeg 的关键点 / 踩坑记录

- ffmpeg 3.2.5 官方 `configure` 必须 POSIX shell。本工程改用：
  ① 一次性用 `scripts/gen_ffmpeg_config.sh`（bash，仅维护时）生成每个 ABI 的
  `config.h/avconfig.h/ffversion.h/bsf_list.c/protocol_list.c`；
  ② `scripts/gen_ffmpeg_src_list.ps1`（PowerShell，Windows 原生）按 config.h 的
  `CONFIG_*` 开关、求值每个库自身 Makefile 的 `OBJS-$(CONFIG_*)` 规则，
  生成 `cmake/ffmpeg_sources.cmake`；CMake 直接按清单编源码。
- 3.2.5 用运行期注册（`allcodecs.c` 等 `if (CONFIG_X)`），不需要生成
  codec/muxer/filter 列表文件；只有 `bsf_list.c`、`protocol_list.c` 是生成文件，
  由 `bitstream_filters.c`、`protocols.c` 以 quoted-include 方式从
  `ffmpeg_generated/<abi>/libavcodoc/、libavformat/` 命中。
- `HAVE_AV_CONFIG_H`、`-DPIC -D_ISOC99_SOURCE -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE`
  与 configure 的默认 flags 对齐。
- `allcodecs.c/allformats.c/allfilters.c` 的注册代码依赖常量折叠：Debug（-O0）下
  `if (CONFIG_X_DECODER)` 仍会引用未编入的 `ff_x` 符号导致链接失败，
  因此对这几个文件固定 `-O1`（见 cmake/ffmpeg.cmake）。
- `--disable-asm/--disable-neon` 的 config：ARM/x86 汇编与 intrinsics 全关，纯 C。
- GPL 相关 filter（eq、boxblur、delogo、pp、drawtext 等，未 `--enable-gpl`）
  config 中默认关闭。
- x86/x86_64 的 config 历史上 `CONFIG_NVENC=1`（Android 上无意义且 NDK 无
  nvEncodeAPI.h），已改回 0。
- `log2_tab.c` 在 CONFIG_SHARED=1 时会被 swresample、swscale 各自编入（两库各一份），
  avutil 里无条件编入 —— 源码清单生成的规则会自动带上。

## 若要修改 config（例如打开 --enable-gpl）

1. 在 `scripts/gen_ffmpeg_config.sh` 里改造好的 configure 选项并运行（一次性，需要 bash）。
2. 运行 `scripts\gen_ffmpeg_src_list.ps1` 重新生成 `cmake/ffmpeg_sources.cmake`。
3. 重新编译即可（zlib 不受影响）。
