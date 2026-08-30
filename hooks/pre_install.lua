local http = require("http")
local json = require("json")

local RELEASES_API = "https://api.github.com/repos/brechtsanders/winlibs/releases"
local ASSET_PATTERN = "winlibs%-x86_64%-posix%-seh%-ucrt%-(%d+%.%d+%.%d+)%.zip"

--- Returns pre-install information: the exact download URL for the chosen version.
--- vfox downloads and extracts the zip automatically (zip is a supported archive).
function PLUGIN:PreInstall(ctx)
    local version = ctx.version

    if version == "latest" then
        local lists = self:Available({})
        if #lists == 0 then
            error("no available mingw versions")
        end
        version = lists[1].version
    end

    if RUNTIME.osType ~= "windows" then
        error("mingw (WinLibs) is Windows-only. On this platform use your system package manager for GCC/GDB.")
    end

    local resp, err = http.get({
        url = RELEASES_API,
        headers = { ["User-Agent"] = "vfox-mingw" }
    })
    if err ~= nil or resp == nil or resp.status_code ~= 200 then
        error("failed to fetch WinLibs releases")
    end

    local body = json.decode(resp.body)
    if body == nil or type(body) ~= "table" then
        error("failed to parse WinLibs releases")
    end

    for _, release in ipairs(body) do
        local name = string.lower(release.name or "")
        local skip = string.find(name, "llvm") or string.find(name, "clang") or string.find(name, "lld")
        if not skip then
            for _, asset in ipairs(release.assets or {}) do
                local v = string.match(asset.name or "", ASSET_PATTERN)
                if v == version then
                    return {
                        version = version,
                        url = asset.browser_download_url,
                        note = "WinLibs MinGW-w64 UCRT (GCC + GDB, without LLVM)"
                    }
                end
            end
        end
    end

    error("mingw version " .. version .. " not found in WinLibs releases")
end
