local W = require("lib.winlibs")

--- Return all available versions provided by this plugin.
--- Fetches the WinLibs releases at runtime and lists the pure GNU (without LLVM) builds.
--- Honors VFOX_GITHUB_MIRROR / GITHUB_PROXY for acceleration.
function PLUGIN:Available(ctx)
    local list, err = W.fetchReleaseList()
    if not list then
        error(err)
    end

    local result = {}
    for _, item in ipairs(list) do
        table.insert(result, {
            version = item.version,
            note = item.note
        })
    end
    return result
end