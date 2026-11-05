



-- wordWrap: splits a string into lines no longer than maxWidth (ignoring colour codes)
local function wordWrap(text, maxWidth)
    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end

    local lines   = {}
    local current = ""

    for _, word in ipairs(words) do
        local candidate = current ~= "" and (current .. " " .. word) or word
        local visible   = candidate:gsub("%^%d", "")
        if maxWidth >= #visible then
            current = candidate
        else
            if current ~= "" then
                table.insert(lines, current)
            end
            current = word
        end
    end

    if current ~= "" then
        table.insert(lines, current)
    end

    return lines
end

-- Version checker thread — runs once on startup after a short delay
Citizen.CreateThread(function()
    local resourceName   = GetCurrentResourceName()
    local currentVersion = GetResourceMetadata(resourceName, "version", 0)

    if not currentVersion then
        print("^1[" .. resourceName .. "] Could not read version from fxmanifest.lua — skipping update check.^0")
        return
    end

    -- Helper: strips all non-digit characters and converts to a number for comparison
    -- Uses string.* explicitly and tostring() to handle non-standard string types
    -- from GetResourceMetadata on some FiveM builds
    local function versionToNumber(v)
        if not v then return nil end
        local clean = string.gsub(tostring(v), "[^%d]", "")
        return tonumber(clean)
    end

    Citizen.Wait(5000)
    print("^6[CHECKING UPDATES]^0 ^7" .. resourceName .. "^0")

    local url = "https://raw.githubusercontent.com/TheRealBablo/version/master/" .. resourceName .. ".json"

    PerformHttpRequest(url, function(statusCode, body, headers)
        if not body or body == "" then
            print("^1Unable to check version.^0")

            return
        end

        local trimmed = body:match("^(.-)%s*$")
        local data    = json.decode(trimmed)

        if not data or not data.version then
            print("^1Invalid version data received.^0")

            return
        end

        local remoteNum  = versionToNumber(data.version)
        local currentNum = versionToNumber(currentVersion)

        if not remoteNum or not currentNum then
            print("^1[" .. resourceName .. "] Failed to parse version numbers (remote: " .. tostring(data.version) .. ", current: " .. tostring(currentVersion) .. ")^0")

            return
        end

        if remoteNum > currentNum then
            -- Update available
            local separator = "^3" .. string.rep("-", 50) .. "^0"
            print("")
            print("^1[UPDATE AVAILABLE]^0 ^7" .. resourceName .. "^0")
            print(separator)
            print("^7Current Version: ^5" .. tostring(currentVersion) .. "^0")
            print("^7New Version:     ^2" .. data.version .. "^0")
            print("")
            print("^6Patch Notes:^0")

            if data.descriptions and #data.descriptions > 0 then
                for _, description in ipairs(data.descriptions) do
                    local lines = wordWrap(description, 75)
                    for lineIndex, line in ipairs(lines) do
                        if lineIndex == 1 then
                            print("^6  \226\128\162 ^5" .. line .. "^0")
                        else
                            print("^5    " .. line .. "^0")
                        end
                    end
                end
            else
                print("^6  \226\128\162 ^5No patch notes available^0")
            end

            print("")
            print("^4Download: ^7portal.cfx.re/assets/granted-assets^0")
            print(separator)

            print("")
        else
            -- Up to date
            print("")
            print("^2[UP TO DATE]^0 ^7" .. resourceName .. " - Version " .. tostring(currentVersion) .. "^0")

            print("")
        end
    print("")
    print("^5[" .. resourceName .. "]^0 ^3[Ak Leaks]^0 ^7discord.gg/6NCbAv2VNK^0")
    print("^5[" .. resourceName .. "]^0 ^3[Said AK]^0 ^2Fixed By Said Ak!^0")
    print("^5[" .. resourceName .. "]^0 ^3[Said AK]^0 ^7U have any problem just open a ticket on ^3discord.gg/6NCbAv2VNK^0 ^7and will fix it!^0")
    end, "GET")
end)