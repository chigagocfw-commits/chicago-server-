Profiles = {}
local profiles = {}
local leaderboard = {}
local profilesReady = false

function Profiles.isReady()
    return profilesReady
end

-- Load profiles from database
MySQL.ready(function()
    Wait(1000)
    
    local results = MySQL.query.await("SELECT * FROM lunar_contracts_profiles")
    
    for _, row in ipairs(results) do
        profiles[row.identifier] = row
    end
    
    table.sort(results, function(a, b)
        return a.xp > b.xp
    end)
    
    leaderboard = results
    profilesReady = true

    -- Re-sync profiles and leaderboard after MySQL.ready completes
    SetTimeout(100, function()
        local players = GetPlayers()
        for i = 1, #players do
            local playerId = tonumber(players[i])
            local player = Framework.getPlayerFromId(playerId)
            if player then
                Profiles.sync(player:getIdentifier())
            end
        end

        Profiles.updateLeaderboard()
    end)
end)

-- Get player profile
lib.callback.register("lunar_contracts:getProfile", function(source)
    while not profilesReady do Wait(200) end
    
    local player = Framework.getPlayerFromId(source)
    if not player then return end
    
    local identifier = player:getIdentifier()
    local profile = profiles[identifier]
    
    if not profile then
        Profiles.create(identifier)
        profile = profiles[identifier]
    end
    
    -- Apply overrides
    if Config.overrideCrypto then
        profile.crypto = Editable.getPlayerCrypto(identifier) or 0
    end
    
    if Config.overrideExperience then
        profile.xp = Editable.getPlayerExperience(identifier) or 0
    end
    
    return profile
end)

-- Get leaderboard
lib.callback.register("lunar_contracts:getLeaderboard", function()
    local result = {}
    local limit = Config.leaderboard.limit
    
    for i = 1, limit do
        result[i] = leaderboard[i]
    end
    
    return result
end)

-- Update leaderboard
function Profiles.updateLeaderboard()
    table.sort(leaderboard, function(a, b)
        return a.xp > b.xp
    end)
    
    local limited = {}
    local limit = Config.leaderboard.limit
    
    for i = 1, limit do
        limited[i] = leaderboard[i]
    end
    
    TriggerClientEvent("lunar_contracts:updateLeaderboard", -1, limited)
end

-- Get profile
function Profiles.get(identifier)
    local profile = profiles[identifier]
    if not profile then return nil end

    if Config.overrideCrypto then
        profile.crypto = Editable.getPlayerCrypto(identifier) or 0
    end

    if Config.overrideExperience then
        profile.xp = Editable.getPlayerExperience(identifier) or 0
    end

    return profile
end

-- Generate random username
local function generateRandomUsername()
    local username = locale("anon") .. " #" .. math.random(1, 99999)
    local taken = false
    
    repeat
        taken = false
        for _, profile in pairs(profiles) do
            if profile.username == username then
                taken = true
                username = locale("anon") .. " #" .. math.random(1, 99999)
                break
            end
        end
    until not taken
    
    return username
end

-- Create profile
function Profiles.create(identifier)
    if profiles[identifier] then return end
    
    local username = generateRandomUsername()
    local timestamp = os.time()
    
    local profile = {
        identifier = identifier,
        username = username,
        firstLogin = timestamp,
        completedContracts = 0,
        lastActive = timestamp,
        crypto = Config.defaultProfile.crypto,
        xp = Config.defaultProfile.xp
    }
    
    profiles[identifier] = profile
    table.insert(leaderboard, profile)
    
    MySQL.insert.await(
        "INSERT INTO lunar_contracts_profiles (identifier, username, firstLogin, completedContracts, lastActive, crypto, xp) VALUES(?, ?, ?, ?, ?, ?, ?)",
        { identifier, username, timestamp, 0, timestamp, profile.crypto, profile.xp }
    )
    
    Profiles.updateLeaderboard()
end

-- Add crypto
function Profiles.addCrypto(identifier, amount)
    if Config.overrideCrypto then
        Editable.addPlayerCrypto(identifier, amount)
        return
    end
    
    local profile = profiles[identifier]
    if not profile or amount <= 0 then return end
    
    profile.crypto = profile.crypto + amount
    
    MySQL.update.await(
        "UPDATE lunar_contracts_profiles SET crypto = ? WHERE identifier = ?",
        { profile.crypto, identifier }
    )
end

-- Remove crypto
function Profiles.removeCrypto(identifier, amount)
    if Config.overrideCrypto then
        Editable.removePlayerCrypto(identifier, amount)
        return
    end
    
    local profile = profiles[identifier]
    if not profile or amount <= 0 then return end
    
    profile.crypto = math.max(0, profile.crypto - amount)
    
    MySQL.update.await(
        "UPDATE lunar_contracts_profiles SET crypto = ? WHERE identifier = ?",
        { profile.crypto, identifier }
    )
end

-- Add experience
function Profiles.addExperience(identifier, amount)
    if Config.overrideExperience then
        Editable.addPlayerExperience(identifier, amount)
        return
    end
    
    local profile = profiles[identifier]
    if not profile or amount <= 0 then return end
    
    profile.xp = profile.xp + amount
    
    MySQL.update.await(
        "UPDATE lunar_contracts_profiles SET xp = ? WHERE identifier = ?",
        { profile.xp, identifier }
    )
end

-- Remove experience
function Profiles.removeExperience(identifier, amount)
    if Config.overrideExperience then
        Editable.removePlayerExperience(identifier, amount)
        return
    end
    
    local profile = profiles[identifier]
    if not profile or amount <= 0 then return end
    
    profile.xp = math.max(0, profile.xp - amount)
    
    MySQL.update.await(
        "UPDATE lunar_contracts_profiles SET xp = ? WHERE identifier = ?",
        { profile.xp, identifier }
    )
end

-- Complete contract
function Profiles.completedContract(identifier)
    local profile = profiles[identifier]
    if not profile then return end
    
    profile.completedContracts = profile.completedContracts + 1
    
    MySQL.update.await(
        "UPDATE lunar_contracts_profiles SET completedContracts = ? WHERE identifier = ?",
        { profile.completedContracts, identifier }
    )
end

-- Update last active
function Profiles.updateLastActive(identifier)
    local profile = profiles[identifier]
    if not profile then return end
    
    profile.lastActive = os.time()
    
    MySQL.update.await(
        "UPDATE lunar_contracts_profiles SET lastActive = ? WHERE identifier = ?",
        { profile.lastActive, identifier }
    )
end

-- Sync profile to client
function Profiles.sync(identifier)
    local player = Framework.getPlayerFromIdentifier(identifier)
    local profile = profiles[identifier]
    
    if not profile or not player then return end
    
    TriggerClientEvent("lunar_contracts:syncProfile", player.source, profile)
end

-- Update username
lib.callback.register("lunar_contracts:updateUsername", function(source, newUsername)
    local player = Framework.getPlayerFromId(source)
    if not player then return end
    
    local identifier = player:getIdentifier()
    local profile = profiles[identifier]
    if not profile then return end
    
    -- Check if username is taken
    for _, otherProfile in pairs(profiles) do
        if otherProfile.username == newUsername then
            return false
        end
    end
    
    profile.username = newUsername
    TriggerClientEvent("lunar_contracts:updateProfile", -1, profile)
    
    MySQL.update.await(
        "UPDATE lunar_contracts_profiles SET username = ? WHERE identifier = ?",
        { profile.username, identifier }
    )
    
    return true
end)

-- Validate image URL
local function isValidImageUrl(url)
    local host = url:match("^https?://([^/]+)")
    if not host then return false end
    
    -- Check for local/private IPs
    if host:match("^127%.") or host:match("^10%.") or 
       host:match("^192%.168%.") or host:match("^172%.1[6-9]%.") or
       host:match("^172%.2[0-9]%.") or host:match("^172%.3[0-1]%.") then
        return false
    end
    
    local promise = promise.new()
    
    PerformHttpRequest(url, function(status, _, headers)
        if status == 200 then
            local contentType = headers["content-type"] or headers["Content-Type"]
            if contentType and contentType:lower():match("^image/") then
                promise:resolve(true)
                return
            end
        end
        promise:resolve(false)
    end, "GET")
    
    return Citizen.Await(promise)
end

-- Update profile picture
lib.callback.register("lunar_contracts:updateProfilePicture", function(source, imageUrl)
    local player = Framework.getPlayerFromId(source)
    if not player then return end
    
    local identifier = player:getIdentifier()
    local profile = profiles[identifier]
    
    if not profile or not isValidImageUrl(imageUrl) then
        return
    end
    
    profile.image = imageUrl
    TriggerClientEvent("lunar_contracts:updateProfile", -1, profile)
    
    MySQL.update.await(
        "UPDATE lunar_contracts_profiles SET image = ? WHERE identifier = ?",
        { profile.image, identifier }
    )
    
    return true
end)

-- Export functions
exports("getPlayerCrypto", function(identifier)
    local profile = Profiles.get(identifier)
    return (profile and profile.crypto) or 0
end)

exports("getPlayerExperience", function(identifier)
    local profile = Profiles.get(identifier)
    return (profile and profile.xp) or 0
end)

-- Wrapper for exports
local function wrapProfileFunction(func)
    return function(identifier, amount)
        func(identifier, amount)
        Profiles.sync(identifier)
    end
end

exports("addPlayerCrypto", wrapProfileFunction(Profiles.addCrypto))
exports("removePlayerCrypto", wrapProfileFunction(Profiles.removeCrypto))
exports("addPlayerExperience", wrapProfileFunction(Profiles.addExperience))
exports("removePlayerExperience", wrapProfileFunction(Profiles.removeExperience))