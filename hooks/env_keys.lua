--- Tell vfox which environment variables this SDK needs.
--- One PATH entry covers the whole GNU toolchain (gcc, g++, gdb, mingw32-make,
--- ar, ld, dlltool, nm, objdump, ranlib, windres, ...). Enabling/disabling in
--- QfPlus is therefore a single one-click environment switch.
function PLUGIN:EnvKeys(ctx)
    local mainSdkInfo = ctx.main
    local mainPath = mainSdkInfo.path
    return {
        {
            key = "PATH",
            value = mainPath .. "/bin"
        },
        {
            key = "MINGW_PREFIX",
            value = mainPath
        },
        {
            key = "CC",
            value = "gcc"
        },
        {
            key = "CXX",
            value = "g++"
        }
    }
end
