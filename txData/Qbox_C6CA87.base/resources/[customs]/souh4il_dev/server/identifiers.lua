-- SOUH4IL-DEV — Identifiers Service
-- Strictly handles extraction, format verification, and normalization of FiveM identifiers

local Config = require 'config.permissions'
local Identifiers = {}

---Safely extracts and validates a player's primary Rockstar license
---@param source number
---@return string? license
function Identifiers.GetLicense(source)
    if type(source) ~= 'number' or source <= 0 or math.tointeger(source) == nil then
        return nil
    end

    local srcStr = tostring(source)
    if not DoesPlayerExist(srcStr) then
        return nil
    end

    local lic = GetPlayerIdentifierByType(srcStr, 'license')
    if not lic or type(lic) ~= 'string' then
        return nil
    end

    -- Strict format check: prefix "license:" and length 48
    if #lic ~= 48 or lic:sub(1, 8) ~= 'license:' then
        return nil
    end

    return lic:lower()
end

---Safely extracts a player's License2 token
---@param source number
---@return string? license2
function Identifiers.GetLicense2(source)
    if type(source) ~= 'number' or source <= 0 or math.tointeger(source) == nil then
        return nil
    end

    local srcStr = tostring(source)
    if not DoesPlayerExist(srcStr) then
        return nil
    end

    local lic2 = GetPlayerIdentifierByType(srcStr, 'license2')
    if not lic2 or type(lic2) ~= 'string' then
        return nil
    end

    if lic2:sub(1, 9) ~= 'license2:' then
        return nil
    end

    return lic2:lower()
end

---Safely extracts a player's Discord identifier
---@param source number
---@return string? discord
function Identifiers.GetDiscord(source)
    if type(source) ~= 'number' or source <= 0 or math.tointeger(source) == nil then
        return nil
    end

    local srcStr = tostring(source)
    if not DoesPlayerExist(srcStr) then
        return nil
    end

    local disc = GetPlayerIdentifierByType(srcStr, 'discord')
    if not disc or type(disc) ~= 'string' then
        return nil
    end

    return disc:lower()
end

---Safely extracts a player's CitizenFX / FiveM identifier
---@param source number
---@return string? fivem
function Identifiers.GetFiveM(source)
    if type(source) ~= 'number' or source <= 0 or math.tointeger(source) == nil then
        return nil
    end

    local srcStr = tostring(source)
    if not DoesPlayerExist(srcStr) then
        return nil
    end

    local cfx = GetPlayerIdentifierByType(srcStr, 'fivem')
    if not cfx or type(cfx) ~= 'string' then
        return nil
    end

    return cfx:lower()
end

---Verifies whether the source matches the Canonical Owner License
---@param source number
---@return boolean isOwnerMatch
function Identifiers.IsCanonicalOwner(source)
    local lic = Identifiers.GetLicense(source)
    if not lic then
        return false
    end

    return lic == Config.CanonicalOwnerLicense:lower()
end

---Collects all valid identifiers for audit logging
---@param source number
---@return table
function Identifiers.GetAll(source)
    return {
        license = Identifiers.GetLicense(source) or "UNKNOWN",
        license2 = Identifiers.GetLicense2(source) or "NONE",
        discord = Identifiers.GetDiscord(source) or "NONE",
        fivem = Identifiers.GetFiveM(source) or "NONE",
    }
end

return Identifiers

