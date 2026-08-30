local W = require("winlibs")

--- Returns pre-install information: the exact download URL for the chosen version.
--- vfox downloads and extracts the zip automatically (zip is a supported archive).
function PLUGIN:PreInstall(ctx)
    local version = ctx.version

    if RUNTIME.osType ~= "windows" then
        error("mingw (WinLibs) is Windows-only. On this platform use your system package manager for GCC/GDB.")
    end

    if version == "latest" then
        local list, err = W.fetchReleaseList()
        if not list or #list == 0 then
            error(err or "no available mingw versions")
        end
        version = list[1].version
    end

    local item = W.resolveVersion(version)
    local url = W.applyMirror(W.buildDownloadURL(item))

    return {
        version = item.version,
        url = url,
        note = item.note
    }
end