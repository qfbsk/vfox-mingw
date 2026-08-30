--- !!! DO NOT EDIT OR RENAME !!!
PLUGIN = {}

--- !!! MUST BE SET !!!
--- Plugin name (used as: vfox add mingw / vfox install mingw@x.y.z)
PLUGIN.name = "mingw"
--- Plugin version
PLUGIN.version = "0.1.1"
--- Plugin repository
PLUGIN.homepage = "https://github.com/qfbsk/vfox-mingw"
--- Plugin license
PLUGIN.license = "MIT"
--- Plugin description
PLUGIN.description = "MinGW-w64 (GCC + GDB) toolchain for Windows."

--- !!! OPTIONAL !!!
--- minimum compatible vfox version
PLUGIN.minRuntimeVersion = "0.3.0"
--- Some things that need user to be attention!
PLUGIN.notes = {
    "Windows only. Downloads the official WinLibs MinGW-w64 UCRT build *without* LLVM/Clang/LLD/LLDB,",
    "so you get a complete GNU toolchain in one package: gcc, g++, gdb, mingw32-make and binutils.",
    "Version list is fetched live from the WinLibs GitHub releases - no hard-coded version numbers."
}
--- List legacy configuration filenames for determining the specified version of the tool.
PLUGIN.legacyFilenames = {}
