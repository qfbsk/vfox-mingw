local http = require("http")

local M = {}

M.WINLIBS_REPO = "brechtsanders/winlibs_mingw"
M.WINLIBS_ATOM = "https://github.com/" .. M.WINLIBS_REPO .. "/releases.atom"
M.WINLIBS_HOME = "https://winlibs.com/"

function M.getProxyMirror()
    return os.getenv("VFOX_GITHUB_MIRROR") or os.getenv("GITHUB_MIRROR") or ""
end

function M.trim(s)
    return string.gsub(s, "^%s*(.-)%s*$", "%1")
end

function M.transformGitHubURL(sourceURL, originalURL)
    if sourceURL == "" or originalURL == "" then
        return originalURL
    end

    -- Template form: https://mirror.ghproxy.com/{url}
    if string.find(sourceURL, "{url}", 1, true) then
        return string.gsub(sourceURL, "{url}", function() return originalURL end, 1)
    end

    -- Prefix form: https://ghps.cc/https://github.com
    if string.sub(sourceURL, 1, 4) == "http" and string.sub(originalURL, 1, 4) == "http" then
        local prefix = string.gsub(sourceURL, "/+$", "")
        local suffix = string.gsub(originalURL, "^/+", "")
        return prefix .. "/" .. suffix
    end

    -- Hostname replacement form: https://kkgithub.com
    local host = string.gsub(sourceURL, "^https?://", "")
    host = string.match(host, "^[^/]+")
    if host == nil or host == "" then
        return originalURL
    end

    local scheme = "https"
    if string.sub(originalURL, 1, 7) == "http://" then
        scheme = "http"
    end

    local result = string.gsub(originalURL, "^https?://[^/]+", scheme .. "://" .. host)
    return result
end

function M.applyMirror(url)
    local mirror = M.getProxyMirror()
    if mirror == "" then
        return url
    end
    return M.transformGitHubURL(mirror, url)
end

function M.httpGet(url)
    local resp, err = http.get({
        url = url,
        headers = {
            ["User-Agent"] = "vfox-mingw",
            ["Accept"] = "application/atom+xml,application/xhtml+xml,text/html,application/xml;q=0.9,*/*;q=0.8"
        }
    })
    return resp, err
end

function M.parseReleasesAtom(body)
    local result = {}
    local start = 1

    while true do
        local s, e = string.find(body, "<entry>", start, true)
        if not s then break end
        local se, ee = string.find(body, "</entry>", e + 1, true)
        if not se then break end

        local entry = string.sub(body, e + 1, se - 1)
        start = ee + 1

        -- Extract within the single entry; these tags are usually on one line.
        local title = string.match(entry, "<title[^>]*>(.-)</title>")
        local link = string.match(entry, "<link[^>]+href=[\"']([^\"']+)[\"'][^>]*/>")
        if title and link then
            title = M.trim(title)
            link = M.trim(link)
            local lower = string.lower(title)
            if not (string.find(lower, "llvm", 1, true) or string.find(lower, "clang", 1, true) or string.find(lower, "lld", 1, true)) then
                local tag = string.match(link, "/releases/tag/([^\"'/ ]+)")
                if tag then
                    -- e.g. 16.2.0posix-14.0.0-ucrt-r1
                    local gcc, mingw, runtime, rev = string.match(tag, "^(%d+%.%d+%.%d+)posix%-(%d+%.%d+%.%d+)%-(ucrt)%-r(%d+)$")
                    if gcc and runtime == "ucrt" then
                        table.insert(result, {
                            version = gcc,
                            tag = tag,
                            mingw = mingw,
                            runtime = runtime,
                            rev = rev,
                            note = "WinLibs UCRT (GCC + GDB, no LLVM)"
                        })
                    end
                end
            end
        end
    end

    table.sort(result, function(a, b) return a.version > b.version end)

    local seen = {}
    local deduped = {}
    for _, item in ipairs(result) do
        if not seen[item.version] then
            seen[item.version] = true
            table.insert(deduped, item)
        end
    end
    return deduped
end

function M.parseWinlibsHtml(body)
    local result = {}
    local flat = string.gsub(body, "%s+", " ")

    for url in string.gmatch(flat, "(https://github%.com/brechtsanders/winlibs_mingw/releases/download/[^\"'<>%s]+/winlibs%-x86_64%-posix%-seh%-gcc%-[^\"'<>%s]-%.zip)") do
        if not string.find(url, "llvm", 1, true) then
            local tag, gcc, runtime, mingw, rev = string.match(url, "/releases/download/([%w%.%-]+)/winlibs%-x86_64%-posix%-seh%-gcc%-(%d+%.%d+%.%d+)%-mingw%-w64(ucrt)%-(%d+%.%d+%.%d+)%-r(%d+)%.zip$")
            if tag and gcc and runtime == "ucrt" then
                table.insert(result, {
                    version = gcc,
                    tag = tag,
                    mingw = mingw,
                    runtime = runtime,
                    rev = rev,
                    url = url,
                    note = "WinLibs UCRT (GCC + GDB, no LLVM)"
                })
            end
        end
    end

    table.sort(result, function(a, b) return a.version > b.version end)

    local seen = {}
    local deduped = {}
    for _, item in ipairs(result) do
        if not seen[item.version] then
            seen[item.version] = true
            table.insert(deduped, item)
        end
    end
    return deduped
end

function M.fetchReleaseList()
    -- Primary: GitHub releases.atom (no API key, usually mirror-friendly)
    local atomUrl = M.applyMirror(M.WINLIBS_ATOM)
    local resp, err = M.httpGet(atomUrl)
    if resp and resp.status_code == 200 then
        local list = M.parseReleasesAtom(resp.body)
        if #list > 0 then
            return list, nil
        end
    end

    local lastErr = err or (resp and "atom feed status " .. tostring(resp.status_code)) or "atom feed empty"

    -- Fallback: winlibs.com homepage HTML
    local homeUrl = M.applyMirror(M.WINLIBS_HOME)
    local resp2, err2 = M.httpGet(homeUrl)
    if resp2 and resp2.status_code == 200 then
        local list = M.parseWinlibsHtml(resp2.body)
        if #list > 0 then
            return list, nil
        end
    end

    return nil, "failed to fetch WinLibs versions from both atom feed and winlibs.com: " .. tostring(lastErr) .. " ; " .. tostring(err2 or "unknown")
end

function M.buildDownloadURL(item)
    return "https://github.com/" .. M.WINLIBS_REPO .. "/releases/download/" .. item.tag .. "/winlibs-x86_64-posix-seh-gcc-" .. item.version .. "-mingw-w64" .. item.runtime .. "-" .. item.mingw .. "-r" .. item.rev .. ".zip"
end

function M.resolveVersion(version)
    local list, err = M.fetchReleaseList()
    if not list then
        error(err)
    end
    for _, item in ipairs(list) do
        if item.version == version then
            return item
        end
    end
    error("mingw version " .. version .. " not found in WinLibs releases")
end

return M