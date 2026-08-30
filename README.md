# vfox-mingw

A [vfox](https://vfox.dev) plugin that installs the **WinLibs MinGW-w64 (UCRT)** build —
a complete, dependency-free GNU toolchain for Windows:

- `gcc` / `g++` (compilers)
- `gdb` (debugger)
- `mingw32-make`
- binutils (`ar`, `ld`, `dlltool`, `nm`, `objdump`, `ranlib`, `windres`, ...)

It deliberately downloads the **without LLVM/Clang/LLD/LLDB** variant, so you only get the
GNU set (no Clang bloat).

## How it works

- `hooks/available.lua` fetches the WinLibs GitHub releases **at search/install time** and
  lists every available GCC version. There is no hard-coded version list — when WinLibs
  publishes a new GCC, it shows up automatically (vfox caches the list for 12h).
- `hooks/pre_install.lua` resolves the exact zip download URL for the chosen version and
  lets vfox download + extract it (zip is a supported archive, so no wizard UI appears).
- `hooks/env_keys.lua` puts `<sdk>/bin` on `PATH` (covering gcc/g++/gdb/make/binutils) and
  sets `MINGW_PREFIX`, `CC=gcc`, `CXX=g++`. In QfPlus, **Enable = one-click add env**,
  **Disable/Uninstall = one-click remove env** — same as the nodejs/python plugins.

## Install (direct, from this repo)

```
vfox add --source https://github.com/YOUR_USERNAME/vfox-mingw/releases/download/v0.1.0/vfox-mingw-0.1.0.zip
```

Or publish it to a registry (see the companion `vfox-plugins` index repo) and use:

```
vfox add mingw
```

## Use

```
vfox install mingw@14.2.0
vfox use mingw@14.2.0
```

Then in a new terminal: `gcc --version`, `gdb --version`, `mingw32-make --version` all work.

## Notes

- Windows only (MinGW-w64 targets native Windows binaries).
- If the version list comes back empty, it is almost always a GitHub API rate-limit /
  User-Agent restriction on the network you are on; retry later or use the `--source` install.
