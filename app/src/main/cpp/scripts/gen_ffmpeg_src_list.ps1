# Generate per-ABI ffmpeg source file lists for the pure-CMake (Windows-native,
# no make / no bash) ffmpeg build, by evaluating the OBJS rules of each library's
# own Makefile (+ the <arch>/Makefile the root Makefile includes for the ABI)
# against the CONFIG_*/HAVE_*/ARCH_* switches of the generated config.h for that
# ABI (the same evaluation ffmpeg's make would perform).
#
# Output: ../cmake/ffmpeg_sources.cmake  (sets like FFMPEG_AVCODEC_SRCS_ARM64_V8A)
#
# Usage (from any shell):  powershell -File scripts\gen_ffmpeg_src_list.ps1
# Only needs to be re-run when the ffmpeg submodule version or config changes.

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)  # .../cpp
$ffmpeg = Join-Path $root "ffmpeg"
$genDir = Join-Path $root "ffmpeg_generated"
$outFile = Join-Path $root "cmake\ffmpeg_sources.cmake"

# ABI -> tag (used in the generated CMake variable names) and -> arch directory
# name (the root Makefile does `-include $(1)/$(ARCH)/Makefile`; x86_64 uses the
# x86 sources, gated by ARCH_X86/ARCH_X86_64 flags).
$abimap = @{
  "arm64-v8a"   = @{ tag = "ARM64_V8A"; arch = "aarch64" }
  "armeabi-v7a" = @{ tag = "ARMV7A";    arch = "arm"      }
  "x86"         = @{ tag = "X86";       arch = "x86"      }
  "x86_64"      = @{ tag = "X86_64";    arch = "x86"      }
}
$libs = @("libavutil", "libavcodec", "libavformat", "libavfilter", "libswresample", "libswscale")

# <SPEC>-OBJS variables are folded into OBJS by ffmpeg/arch.mak:
#   OBJS-$(HAVE_<SPEC>) += $(<SPEC>-OBJS) $(<SPEC>-OBJS-yes)
# so a "<SPEC>-OBJS-$(COND) += a.o" line adds a.o only when both HAVE_<SPEC> and
# COND hold. With --disable-asm all of these are zero for Android builds, but
# evaluate them anyway so a future config change picks the files up.
$specToHave = @{
  "ARMV5TE" = "HAVE_ARMV5TE"; "ARMV6" = "HAVE_ARMV6"; "ARMV8" = "HAVE_ARMV8"
  "VFP" = "HAVE_VFP"; "NEON" = "HAVE_NEON"
  "MIPSFPU" = "HAVE_MIPSFPU"; "MIPSDSP" = "HAVE_MIPSDSP"; "MIPSDSPR2" = "HAVE_MIPSDSPR2"
  "MSA" = "HAVE_MSA"; "MMI" = "HAVE_MMI"
  "ALTIVEC" = "HAVE_ALTIVEC"; "VSX" = "HAVE_VSX"
  "MMX" = "HAVE_MMX"; "YASM" = "HAVE_YASM"
}

function Parse-MakefileSrcs {
  param(
    [string[]]$makefiles,
    [string]$libdir,
    [hashtable]$flags
  )

  $objs = New-Object System.Collections.Generic.List[string]

  foreach ($makefile in $makefiles) {
    # Join backslash-continued physical lines into logical lines.
    $logical = New-Object System.Collections.Generic.List[string]
    foreach ($raw in (Get-Content $makefile)) {
      if ($logical.Count -gt 0 -and $logical[$logical.Count - 1] -match '\\$') {
        $logical[$logical.Count - 1] = $logical[$logical.Count - 1] -replace '\\\s*$', ''
        $logical[$logical.Count - 1] += " " + $raw
      } else {
        $logical.Add($raw)
      }
    }

    foreach ($line in $logical) {
      # drop comments mid-line (ffmpeg makefiles have none on OBJS lines, be safe)
      $l = ($line -replace '\s+#.*$', '').Trim()
      if ($l -notmatch '^OBJS') { continue }

      $ok = $false
      $items = ""
      # <SPEC>-OBJS[-$(COND)] += files  (folded by arch.mak behind HAVE_<SPEC>)
      if ($l -match '^(ARMV5TE|ARMV6|ARMV8|VFP|NEON|MIPSFPU|MIPSDSP|MIPSDSPR2|MSA|MMI|ALTIVEC|VSX|MMX|YASM)-OBJS(?:-\$\(\s*!?([\w@]+)\s*\))?\s*\+=\s*(.*)$') {
        if (-not $flags.ContainsKey($specToHave[$Matches[1]]) -or $flags[$specToHave[$Matches[1]]] -eq 0) { continue }
        if ($Matches[2] -ne "") {
          if (-not $flags.ContainsKey($Matches[2]) -or $flags[$Matches[2]] -eq 0) { continue }
        }
        $ok = $true; $items = $Matches[3]
      }
      # OBJS-$(COND) += files     |  OBJS-$(COND) = files
      elseif ($l -match '^OBJS-\$\(\s*!?([\w@]+)\s*\)\s*(\+=|=)\s*(.*)$') {
        $cond = $Matches[1]; $items = $Matches[3]
        if ($flags.ContainsKey($cond)) { $ok = ($flags[$cond] -ne 0) }
      }
      # OBJS += files  |  OBJS = files
      elseif ($l -match '^OBJS\s*(\+=|=)\s*(.*)$') {
        $ok = $true; $items = $Matches[2]
      }
      if (-not $ok -or $items -eq "") { continue }

      foreach ($tok in ($items -split '[ \t]+')) {
        $t = $tok.Trim()
        if ($t -eq "" -or $t -match '\$') { continue }          # rule substitutions -> handled manually
        if ($t -notmatch '^[A-Za-z0-9_./@-]+\.o$') { continue } # not an object file token
        $src = ($t -replace '\.o$', '') + ".c"                  # foo/bar.o -> foo/bar.c
        if (-not ($src -match '\.c$')) { continue }
        $full = Join-Path $libdir $src
        if (-not (Test-Path $full)) { continue }                # asm/asm-only/generated objects
        if (-not $objs.Contains($src)) { $objs.Add($src) }
      }
    }
  }
  return $objs
}

function Collect-Lib {
  param([string]$lib, [hashtable]$flags)
  # Only the library's own Makefile: arch/<abi> Makefiles only carry
  # assembler/init plumbing which the pure-C config (all ARCH_*/HAVE_<asm> = 0)
  # deliberately does not use, and keeping them out keeps every relocation
  # resolvable.
  $libdir = Join-Path $ffmpeg $lib
  return Parse-MakefileSrcs -makefiles @((Join-Path $libdir "Makefile")) -libdir $libdir -flags $flags
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# AUTO-GENERATED by scripts/gen_ffmpeg_src_list.ps1 - do not edit by hand.")
[void]$sb.AppendLine("# Per-ABI ffmpeg 3.2.5 source lists, evaluated from each library's own Makefile")
[void]$sb.AppendLine("# (plus its <arch>/Makefile) OBJS rules against the switches in")
[void]$sb.AppendLine("# ffmpeg_generated/<abi>/config.h, for the pure-CMake (Windows-native,")
[void]$sb.AppendLine("# no make/bash) ffmpeg build.")
[void]$sb.AppendLine("")
foreach ($abi in ($abimap.Keys | Sort-Object)) {
  $info = $abimap[$abi]
  $tag = $info["tag"]
  $flags = @{}
  foreach ($m in (Select-String -Path (Join-Path $genDir "$abi\config.h") -Pattern '^\s*#define\s+(\w+)\s+1\b' -AllMatches)) {
    foreach ($mm in $m.Matches) { $flags[$mm.Groups[1].Value] = 1 }
  }
  # The generated configs were produced without --enable-shared, but this build
  # always produces shared libs, so evaluate CONFIG_SHARED like make would.
  $flags["CONFIG_SHARED"] = 1
  foreach ($lib in $libs) {
    $objs = Collect-Lib -lib $lib -flags $flags
    if ($objs.Count -eq 0) { throw "No sources collected for $lib / $abi - check Makefile parsing" }
    [void]$sb.AppendLine("# $lib ($abi): $($objs.Count) files")
    [void]$sb.AppendLine(("set(FFMPEG_" + $lib.Substring(3).ToUpper() + "_SRCS_$tag"))
    foreach ($o in $objs) { [void]$sb.AppendLine("    ffmpeg/$lib/$o") }
    [void]$sb.AppendLine(")")
    [void]$sb.AppendLine("")
  }
}
Set-Content -Path $outFile -Value ($sb.ToString() -replace '\r\n?', "`n") -Encoding ASCII -NoNewline
Write-Host "Wrote $outFile"
