--[[
░▒▓████████▓▒░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░   ░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓███████▓▒░  
                                                                         
 This File Leaked By TC HUB Team, Join Our Server For More
 DISCORD: - https://discord.gg/k3S8RjkPWc - https://t.me/+RgDxwPX3L7w2ODBk - https://tchub.shop/
--]]

local anyExternalAllowed = false

for _, v in pairs(Config.AllowExternal) do
    if v then
        anyExternalAllowed = true
    end
end

local allowedPatterns = {}

local blockedPatterns = {}

local function EscapePattern(text)
    local escaped = text:gsub("(%W)", "%%%1")

    return escaped
end

local function GetHostnamePattern(entry)
    local parts = {}

    for segment in entry:gmatch("[^%.]+") do
        parts[#parts+1] = segment == "*" and "[^.]+" or EscapePattern(segment)
    end

    return "^" .. table.concat(parts, "%.") .. "$"
end

local function GetDomainPatterns(entry)
    local escaped = EscapePattern(entry)
    local exactPattern = "^" .. escaped .. "$"
    local subdomainPattern = "^.+%." .. escaped .. "$"

    return exactPattern, subdomainPattern
end

local function AddHostnamePatterns(target, entries)
    if not entries then return end

    for i = 1, #entries do
        target[#target+1] = GetHostnamePattern(entries[i])
    end
end

local function AddDomainPatterns(target, entries)
    if not entries then return end

    for i = 1, #entries do
        local exact, subdomain = GetDomainPatterns(entries[i])
        target[#target+1] = exact
        target[#target+1] = subdomain
    end
end

if anyExternalAllowed then
    AddHostnamePatterns(allowedPatterns, Config.ExternalWhitelistedHostnames)
    AddDomainPatterns(allowedPatterns, Config.ExternalWhitelistedDomains)
    AddHostnamePatterns(blockedPatterns, Config.ExternalBlacklistedHostnames)
    AddDomainPatterns(blockedPatterns, Config.ExternalBlacklistedDomains)
end

AddHostnamePatterns(allowedPatterns, Config.UploadWhitelistedHostnames)
AddDomainPatterns(allowedPatterns, Config.UploadWhitelistedDomains)

local function DoesHostnameMatchPattern(hostname, patterns)
    for i = 1, #patterns do
        if hostname:find(patterns[i]) then
            return true
        end
    end

    return false
end

function IsMediaLinkAllowed(link, source)
    if #allowedPatterns == 0 and #blockedPatterns == 0 then
        return true
    end

    local hostname = link:match("^https?://([^/]+)")

    if not hostname then
        debugprint("IsMediaLinkAllowed: Failed to extract hostname from:", link)
        return false
    end

    if not hostname:find("%.") then
        debugprint("IsMediaLinkAllowed: Hostname has no dot:", hostname, "from link:", link)
        return false
    end

    if DoesHostnameMatchPattern(hostname, blockedPatterns) then
        debugprint("IsMediaLinkAllowed: Link is blocked by config:", link)
        return false
    end

    if #allowedPatterns == 0 then
        return true
    end

    if DoesHostnameMatchPattern(hostname, allowedPatterns) then
        return true
    end

    return false
end

