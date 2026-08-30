local http = require("http")
local json = require("json")

-- WinLibs GitHub repo that publishes the MinGW-w64 UCRT builds.
-- Version list is fetched live here, so new GCC releases show up automatically.
local RELEASES_API = "https://api.github.com/repos/brechtsanders/winlibs/releases"

-- Match the 64-bit UCRT build zip, e.g. winlibs-x86_64-posix-seh-ucrt-14.2.0.zip
local ASSET_PATTERN = "winlibs%-x86_64%-posix%-seh%-ucrt%-(%d+%.%d+%.%d+)%.zip"

--- Return all available versions provided by this plugin.
--- Fetches the WinLibs releases at runtime and lists the pure GNU (without LLVM) builds.
function PLUGIN:Available(ctx)
    local resp, err = http.get({
        url = RELEASES_API,
        headers = { ["User-Agent"] = "vfox-mingw" }
    })
    if err ~= nil or resp == nil or resp.status_code ~= 200 then
        return {}
    end

    local body = json.decode(resp.body)
    if body == nil or type(body) ~= "table" then
        return {}
    end

    local result = {}
    for _, release in ipairs(body) do
        -- Skip the "with LLVM/Clang/LLD/LLDB" builds; we only want the pure GNU toolchain.
        local name = string.lower(release.name or "")
        local skip = string.find(name, "llvm") or string.find(name, "clang") or string.find(name, "lld")
        if not skip then
            local assets = release.assets or {}
            for _, asset in ipairs(assets) do
                local version = string.match(asset.name or "", ASSET_PATTERN)
                if version ~= nil then
                    table.insert(result, {
                        version = version,
                        note = "WinLibs UCRT (GCC + GDB, no LLVM)"
                    })
                    break
                end
            end
        end
    end

    -- Sort descending so the newest GCC is first.
    table.sort(result, function(a, b) return a.version > b.version end)
    return result
end
