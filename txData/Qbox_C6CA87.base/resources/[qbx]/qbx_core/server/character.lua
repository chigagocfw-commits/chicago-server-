local config = require 'config.server'
local clientConfig = require 'config.client'.characters
local logger = require 'modules.logger'
local storage = require 'server.storage.main'
local starterItems = require 'config.shared'.starterItems

---@param license2? string
---@param license? string
local function getAllowedAmountOfCharacters(license2, license)
    return (license2 and config.characters.playersNumberOfCharacters[license2]) or (license and config.characters.playersNumberOfCharacters[license]) or config.characters.defaultNumberOfCharacters
end

---@param source Source
---@return string? canonicalLicense
---@return string? license2
---@return string? license
---@return integer? userId
local function getCanonicalPlayerIdentity(source)
    if type(source) ~= 'number' or source <= 0 then return nil, nil end
    local srcStr = tostring(source)
    local license2 = GetPlayerIdentifierByType(srcStr, 'license2')
    local license = GetPlayerIdentifierByType(srcStr, 'license')
    license2 = type(license2) == 'string' and license2:match('^license2:%x+$') and license2 or nil
    license = type(license) == 'string' and license:match('^license:%x+$') and license or nil
    local canonicalLicense = license2 or license
    if not canonicalLicense then return nil, nil end

    local license2UserId = license2 and tonumber(storage.fetchUserByIdentifier(license2)) or nil
    local licenseUserId = license and tonumber(storage.fetchUserByIdentifier(license)) or nil
    if license2UserId and licenseUserId and license2UserId ~= licenseUserId then
        lib.print.warn(('qbx_core: conflicting user records for source %s; character access denied'):format(tostring(source)))
        return nil, nil, nil, nil
    end

    return canonicalLicense, license2, license, license2UserId or licenseUserId
end

---@param source Source
---@param citizenId string
---@return boolean
local function doesPlayerOwnCitizenId(source, citizenId)
    if type(citizenId) ~= 'string' or citizenId == '' or #citizenId > 32 then
        return false
    end
    local canonicalLicense, license2, license, userId = getCanonicalPlayerIdentity(source)
    if not canonicalLicense then
        return false
    end
    local playerEntity = storage.fetchPlayerEntity(citizenId)
    if not playerEntity or (playerEntity.license ~= license2 and playerEntity.license ~= license) then return false end
    return not userId or not playerEntity.userId or tonumber(playerEntity.userId) == userId
end

---@param source Source
local function giveStarterItems(source)
    if GetResourceState('ox_inventory') == 'missing' then return end
    while not exports.ox_inventory:GetInventory(source) do
        Wait(100)
    end
    for i = 1, #starterItems do
        local item = starterItems[i]
        if item.metadata and type(item.metadata) == 'function' then
            exports.ox_inventory:AddItem(source, item.name, item.amount, item.metadata(source))
        else
            exports.ox_inventory:AddItem(source, item.name, item.amount, item.metadata)
        end
    end
end

lib.callback.register('qbx_core:server:getCharacters', function(source)
    if clientConfig.useExternalCharacters then
        lib.print.warn(('qbx_core:server:getCharacters blocked for source %s because useExternalCharacters is enabled'):format(tostring(source)))
        return {}, 0
    end
    local canonicalLicense, license2, license = getCanonicalPlayerIdentity(source)
    if not canonicalLicense then return {}, 0 end
    license2 = license2 or canonicalLicense
    license = license or canonicalLicense
    -- Heal any account left with a broken cid sequence (duplicates from the
    -- pre-fix createCharacter bug, or gaps from deleted characters) before
    -- handing the list to the client, so create-time logic can stay a simple append.
    storage.normalizeCids(license2, license)
    return storage.fetchAllPlayerEntities(license2, license), getAllowedAmountOfCharacters(license2, license)
end)

lib.callback.register('qbx_core:server:getPreviewPedData', function(source, citizenId)
    if clientConfig.useExternalCharacters or not doesPlayerOwnCitizenId(source, citizenId) then
        lib.print.warn(('qbx_core:server:getPreviewPedData denied for source %s (unauthorized citizenId=%s)'):format(tostring(source), tostring(citizenId)))
        return
    end
    local ped = storage.fetchPlayerSkin(citizenId)
    if not ped then return end

    return ped.skin, ped.model and joaat(ped.model)
end)

lib.callback.register('qbx_core:server:loadCharacter', function(source, citizenId)
    if clientConfig.useExternalCharacters then
        lib.print.warn(('qbx_core:server:loadCharacter blocked for source %s because useExternalCharacters is enabled'):format(tostring(source)))
        return
    end
    if not doesPlayerOwnCitizenId(source, citizenId) then
        lib.print.warn(('qbx_core:server:loadCharacter denied for source %s (unauthorized citizenId=%s)'):format(tostring(source), tostring(citizenId)))
        return
    end
    local success = Login(source, citizenId)
    if not success then return end

    logger.log({
        source = 'qbx_core',
        webhook = config.logging.webhook['joinleave'],
        event = 'Loaded',
        color = 'green',
        message = ('**%s** (%s |  ||%s|| | %s | %s | %s) loaded'):format(GetPlayerName(source), GetPlayerIdentifierByType(source, 'discord') or 'undefined', GetPlayerIdentifierByType(source, 'ip') or 'undefined', GetPlayerIdentifierByType(source, 'license2') or GetPlayerIdentifierByType(source, 'license') or 'undefined', citizenId, source)
    })
    lib.print.info(('%s (Citizen ID: %s ID: %s) has successfully loaded!'):format(GetPlayerName(source), citizenId, source))
end)

--- Validates client-supplied character info. Never trust the values the create
--- screen sends: cap free-text length, enforce types, and reject anything that
--- isn't a usable string so a crafted payload can't bloat the row or smuggle in
--- non-string fields. Returns nil to refuse creation outright.
---@param data table
---@return table? sanitized
local function sanitizeNewCharInfo(data)
    local MAX_TEXT = 50
    local MAX_BACKSTORY = 1000

    local function text(value, maxLength)
        if type(value) ~= 'string' then return nil end
        value = value:gsub('^%s+', ''):gsub('%s+$', '')
        if value == '' or #value > maxLength then return nil end
        return value
    end

    local firstname = text(data.firstname, MAX_TEXT)
    local lastname = text(data.lastname, MAX_TEXT)
    local nationality = text(data.nationality, MAX_TEXT)
    local birthdate = text(data.birthdate, MAX_TEXT)
    local gender = tonumber(data.gender)

    if not firstname or not lastname or not nationality or not birthdate or not gender then
        return nil
    end

    return {
        firstname = firstname,
        lastname = lastname,
        nationality = nationality,
        birthdate = birthdate,
        gender = math.floor(gender),
        backstory = text(data.backstory, MAX_BACKSTORY) or 'placeholder backstory',
    }
end

---@param existingCharacters PlayerEntity[] sorted ascending by cid (storage.fetchAllPlayerEntities orders by cid)
---@return integer
local function getNextCid(existingCharacters)
    local lastCharacter = existingCharacters[#existingCharacters]
    return (lastCharacter and lastCharacter.charinfo.cid or 0) + 1
end

---@param data unknown
---@return table? newData
lib.callback.register('qbx_core:server:createCharacter', function(source, data)
    if clientConfig.useExternalCharacters then
        lib.print.warn(('qbx_core:server:createCharacter blocked for source %s because useExternalCharacters is enabled'):format(tostring(source)))
        return
    end
    if type(data) ~= 'table' then return end

    local canonicalLicense, license2, license = getCanonicalPlayerIdentity(source)
    if not canonicalLicense then return end

    license2 = license2 or canonicalLicense
    license = license or canonicalLicense
    local existingCharacters = storage.fetchAllPlayerEntities(license2, license)
    if #existingCharacters >= getAllowedAmountOfCharacters(license2, license) then
        return
    end

    local charinfo = sanitizeNewCharInfo(data)
    if not charinfo then return end

    -- The client sends a cid (its local slot index), but that value is never
    -- trustworthy: sanitizeNewCharInfo() intentionally drops it, so it must be
    -- computed server-side from the account's existing characters or every new
    -- character silently falls back to cid 1 (see CheckPlayerData in player.lua).
    charinfo.cid = getNextCid(existingCharacters)

    local newData = {}
    newData.charinfo = charinfo

    local success = Login(source, nil, newData)
    if not success then return end

    giveStarterItems(source)

    lib.print.info(('%s has created a character'):format(GetPlayerName(source)))
    return newData
end)

--- Deprecated. This event is kept for backward compatibility only and is no longer used internally.
RegisterNetEvent('qbx_core:server:deleteCharacter', function(citizenId)
    local src = source
    if clientConfig.useExternalCharacters then
        lib.print.warn(('qbx_core:server:deleteCharacter blocked for source %s because useExternalCharacters is enabled'):format(tostring(src)))
        return
    end
    if not doesPlayerOwnCitizenId(src, citizenId) then
        lib.print.warn(('qbx_core:server:deleteCharacter denied for source %s'):format(tostring(src)))
        return
    end

    if not DeleteCharacter(src --[[@as number]], citizenId) then
        Notify(src, locale('error.character_delete_failed'), 'error')
        return
    end
    Notify(src, locale('success.character_deleted'), 'success')
end)