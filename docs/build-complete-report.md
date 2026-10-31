# 纯 Windows CMake 编译 ffmpeg/zlib 完成报告

> 2026-10-31 · arm64-v8a 构建闭环后的总结

## 完成情况

目标达成：安卓 NDK 编译 ffmpeg，全程 Windows 原生工具链（CMake+Ninja+NDK clang），
没有任何 bash/make/git-bash 依赖；构建顺序为 **zlib 先编译 → ffmpeg 依赖 zlib →
wrapper 链接所有库**。

产物（arm64-v8a，Gradle 可照此编 4 个 ABI）：

| 库 | 大小 | DT_NEEDED |
|---|---|---|
| libz.so | 334K | 系统库（zlib 先编译 ✓） |
| libavutil.so | 1.3M | 系统库 |
| libswresample.so | 308K | avutil |
| libswscale.so | 2.5M | avutil |
| libavcodec.so | 48M | **libz.so** + swresample + avutil |
| libavformat.so | 16M | avcodec + **libz.so** + avutil |
| libavfilter.so | 7.5M | avformat/avcodec/swscale/swresample |
| libjxffmpegrun.so | 847K | 全部 ffmpeg 库 + libz + liblog |

公共 API 导出已验证（`avcodec_register_all`、`swr_alloc`、`avformat_open_input` 等都在）。

## 改动清单

- **新增** `cpp/scripts/gen_ffmpeg_src_list.ps1` — Windows 原生生成器：按各 ABI
  `config.h` 的开关求值每个库自身 Makefile 的 `OBJS-$(CONFIG_*)` 规则，产出
  `cmake/ffmpeg_sources.cmake`（4 个 ABI 清单已验证完全一致）
- **重写** `cpp/cmake/zlib.cmake` — `add_subdirectory(zlib)` in-tree 构建，`zlib`
  目标自动进入链接/打包
- **重写** `cpp/cmake/ffmpeg.cmake` — 纯 CMake 编 ffmpeg 6 个库（含 png↔libz、
  opusdec/af_pan↔swresample 等依赖；`allcodecs.c` 等注册文件固定 `-O1`，
  Debug 构建也能链接）
- **重写** `cpp/CMakeLists.txt` / `wrapper/CMakeLists.txt` — 全 in-tree 目标
  （不再 ExternalProject），CLion 打开 cpp 目录可完整索引/跳转/重构 zlib、ffmpeg、
  wrapper 全部源码；未配置时自动兜底 NDK toolchain
- **修正** `ffmpeg_generated/{x86,x86_64}/config.h` — `CONFIG_NVENC*` 归零
  （NDK 无 nvEncodeAPI.h 且 Android 上无意义）；四个 ABI 的 `ARCH_*` 统一为 0
  （纯 C 语义，与 `--disable-asm` 一致——这些运行期 `have_neon()` 分支引用的
  汇编符号本来就不参与编译）
- **删除** 旧 bash 构建脚本 `scripts/build_ffmpeg.sh`、`ff-ld.sh`；保留
  `gen_ffmpeg_config.sh` 供未来重新生成 config
- **文档** `docs/clion-ndk-build.md` 全量更新
- **清理** ffmpeg submodule 恢复 pristine（删除 configure 生成物 config.h/config.mak/
  avconfig.h/ffversion.h/bsf_list.c/protocol_list.c，误删的源 Makefile 已恢复）

## 编译方式

```sh
cd app/src/main/cpp
cmake -S . -B build/arm64-v8a -G Ninja -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-21
cmake --build build/arm64-v8a --target zlib   # 第一步：zlib
cmake --build build/arm64-v8a                  # 第二步：ffmpeg（自动先建依赖）+ wrapper
```

Gradle 直接 `gradlew :app:assembleDebug` 也会按 abiFilters 编 4 个 ABI。
CLion 打开 `app/src/main/cpp` 目录后不加任何特殊配置即可识别为 Android 交叉编译，
可用 `-DANDROID_ABI=...` 切换。

## 源码清单生成原理（踩坑记录）

1. ffmpeg 3.2.5 用运行期注册（`allcodecs.c` 的 `if (CONFIG_X)` 模式），
   不需要生成 codec/muxer/filter 列表文件；只有 `bsf_list.c`、`protocol_list.c`
   是生成文件，由 `bitstream_filters.c`、`protocols.c` 以 quoted-include 方式
   从 `ffmpeg_generated/<abi>/` 命中。
2. 各库 Makefile 的 `OBJS-$(CONFIG_X) += a.o` 行由 PowerShell 脚本对 config.h
   求值（`CONFIG_*` 缺省视为 0），即等价复刻 make 的行为。
3. `<SPEC>-OBJS`（NEON/VFP/MMX/YASM 等）由 `arch.mak` 按 `HAVE_<SPEC>` 合并，
   本配置全部为 0，arch 汇编文件不参与。
4. 共享库模式的 `OBJS-$(CONFIG_SHARED)`（log2_tab、golomb_tab、reverse 等）
   以合成 flag `CONFIG_SHARED=1` 参与（生成的 config 是静态配置，但我们的
   构建永远是 shared）。
5. aarch64 init 文件（如 `h264dsp_init_aarch64.c`）在运行期按 `have_neon(cpu_flags)`
   分支，但 `ff_get_cpu_flags_aarch64()` 是编译期常量（HAVE_NEON=0 → 恒 0），
   分支必假；这些 unreachable-but-relocated 的代码引用外部汇编符号，仍会产生
   无法解析的重定位，所以整体把 `ARCH_*` 关为 0、不编 arch 目录源文件，语义与
   `--disable-asm` 一致。
6. `libavcodec` 的 opus 解码、`libavfilter` 的 af_pan/af_aresample 依赖
   swresample 的 `swr_*` 符号，链接时加入即可。

## 可选后续

- ① `app/src/main/build/ffmpeg_build_arm64-v8a` 是旧 out-of-tree make 尝试的
  残留目录，确认不要可删。
- ② `.so` 目前含 `-g` 调试信息（avcodec 48M），发版 Gradle 会做 strip，
  无需手动处理。
- ③ 若需 GPL filter（eq、boxblur、delogo、pp、drawtext 等）：在
  `scripts/gen_ffmpeg_config.sh` 加 `--enable-gpl` 重新生成 config，再跑
  `gen_ffmpeg_src_list.ps1` 重新生成清单即可。
