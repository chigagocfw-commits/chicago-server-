Modules.waitFor({ "config" })
local config = Modules.require("config")

CreateThread(function()
    if not config.CheckForUpdates then
        return
    end

    local expectedResourceName = "wasabi_multichar"
    local currentVersion = GetResourceMetadata(GetCurrentResourceName(), "version")
    local versionsUrl = "https://raw.githubusercontent.com/Wasabi-Scripts/wasabi_versions/main/versions.json"

    function FetchLatestVersion(callback)
        PerformHttpRequest(versionsUrl, function(statusCode, responseText, headers)
            if statusCode == 200 and responseText then
                local versionsData = json.decode(responseText)
                if type(versionsData) == "table" then
                    for _, entry in ipairs(versionsData) do
                        if entry.script and entry.script == expectedResourceName then
                            callback(entry.version)
                            return
                        end
                    end
                end
            end
            callback(false)
        end, "GET")
    end

    function CompareVersions(latestVersion)
        if latestVersion and currentVersion ~= latestVersion then
            Wait(4500)
            print("^0[^3WARNING^0] " .. expectedResourceName .. " is ^1NOT ^0up to date!")
            print("^0[^3WARNING^0] Your Version: ^1" .. tostring(currentVersion) .. "^0")
            print("^0[^3WARNING^0] Latest Version: ^2" .. tostring(latestVersion) .. "^0")
            print("^0[^3WARNING^0] ^1Get the latest version from portal.cfx.re!^0")
        end
    end

    CreateThread(function()
        local currentResourceName = GetCurrentResourceName()
        if currentResourceName ~= expectedResourceName then
            print(string.format("^0[^3WARNING^0] Rename the folder from ^1%s^0 to ^2%s^0, otherwise this resource could experience problems!", currentResourceName, expectedResourceName))
        end

        while true do
            FetchLatestVersion(CompareVersions)
            Wait(3600000)
        end
    end)
end)
