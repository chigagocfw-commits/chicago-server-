-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------
---@diagnostic disable: undefined-global
if not GetResourceState('es_extended'):find('start') then return end

lib.print.debug('[wasabi_multichar] ESX framework detected, initializing bridge...')

local ESX    = exports['es_extended']:getSharedObject()
local bridge = {}
local charCache     = {}
local pendingCreate = {}

bridge.framework = 'esx'

---Strip type prefix and multichar prefix from an ESX identifier
---@param id string e.g. "license:940874...", "char1:license:940874..."
---@return string e.g. "940874..."
local function baseId(id)
    local stripped = id:match('^char%d+:(.+)$') or id
    stripped = stripped:gsub('^license:', ''):gsub('^license2:', ''):gsub('^steam:', ''):gsub('^discord:', ''):gsub('^ip:', '')
    return stripped
end

-- Ensure nationality column exists in users table
CreateThread(function()
    local ok, err = pcall(function()
        local col = MySQL.single.await("SHOW COLUMNS FROM `users` LIKE 'nationality'")
        if not col then
            lib.print.debug('[wasabi_multichar][ESX] Adding missing nationality column to users table')
            MySQL.query.await("ALTER TABLE `users` ADD COLUMN `nationality` VARCHAR(50) NULL DEFAULT ''")
            lib.print.debug('[wasabi_multichar][ESX] nationality column added')
        end
    end)
    if not ok then
        lib.print.error(('[wasabi_multichar][ESX] Failed to ensure columns: %s'):format(tostring(err)))
    end
end)

local function getCachedCharacter(source, slot)
    local list = charCache[source]
    if not list then return nil end
    for _, entry in ipairs(list) do
        if entry.slot == slot and entry.character then
            return entry.character
        end
    end
    return nil
end

local esxCharacterDataTables = {
    { 'addon_account_data', 'owner' },
    { 'addon_inventory_items', 'owner' },
    { 'billing', 'identifier' },
    { 'datastore_data', 'owner' },
    { 'owned_vehicles', 'owner' },
    { 'user_licenses', 'owner' },
    { 'users', 'identifier' },
}

local function doesColumnExist(tableName, columnName)
    local result = MySQL.scalar.await([[
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?
    ]], { tableName, columnName })

    return (result or 0) > 0
end

local function deleteEsxCharacterData(characterId)
    local queries = {}

    for i = 1, #esxCharacterDataTables do
        local data = esxCharacterDataTables[i]
        local tableName = data[1]
        local columnName = data[2]

        if doesColumnExist(tableName, columnName) then
            queries[#queries + 1] = {
                query = ('DELETE FROM `%s` WHERE `%s` = ?'):format(tableName, columnName),
                values = { characterId }
            }
        end
    end

    if #queries == 0 then
        return false
    end

    return MySQL.transaction.await(queries)
end

---Get characters for a player
---@param source number
---@param identifier string Player license
---@param identifier2? string Unused for ESX
---@param maxSlots? number
---@return table[]
function bridge.getCharacters(source, identifier, identifier2, maxSlots)
    maxSlots   = maxSlots or Config.MaxSlots or 5
    identifier = baseId(identifier)

    lib.print.debug(('[wasabi_multichar][ESX] getCharacters | source=%s identifier=%s maxSlots=%s'):format(
        source, identifier, maxSlots))

    local result = MySQL.query.await([[
        SELECT * FROM users WHERE identifier LIKE ? ORDER BY id ASC
    ]], { 'char%:' .. identifier })

    lib.print.debug(('[wasabi_multichar][ESX] DB rows returned: %s'):format(result and #result or 0))

    local characters = {}
    local bySlot = {}
    if result then
        for _, char in ipairs(result) do
            local slotNum = tonumber(char.identifier:match('^char(%d+):'))
            if slotNum and slotNum <= maxSlots then
                bySlot[slotNum] = char
            end
        end
    end

    for i = 1, maxSlots do
        local char = bySlot[i]
        if char then
            local accounts = (type(char.accounts) == 'string' and json.decode(char.accounts)) or {}
            local cash, bank = 0, 0
            if accounts[1] then
                for _, acc in ipairs(accounts) do
                    if acc.name == 'money' then cash = acc.money or 0 end
                    if acc.name == 'bank'  then bank = acc.money or 0 end
                end
            else
                cash = accounts.money or 0
                bank = accounts.bank  or 0
            end

            local jobLabel = 'Civilian'
            if char.job and char.job ~= '' then
                local jobRow = MySQL.single.await('SELECT label FROM jobs WHERE name = ? LIMIT 1', { char.job })
                if jobRow then jobLabel = jobRow.label end
            end

            local pos = (type(char.position) == 'string' and json.decode(char.position)) or char.position or nil

            characters[#characters + 1] = {
                slot = i,
                character = {
                    id           = char.identifier,
                    firstName    = char.firstname    or 'Unknown',
                    lastName     = char.lastname     or 'Unknown',
                    gender       = (char.sex == 'f' or char.sex == 'female') and 'female' or 'male',
                    birthdate    = char.dateofbirth  or '',
                    nationality  = char.nationality  or '',
                    job          = char.job          or 'unemployed',
                    jobLabel     = jobLabel,
                    cash         = cash,
                    bank         = bank,
                    phone        = char.phone_number or '',
                    lastPosition = pos and { x = pos.x, y = pos.y, z = pos.z, w = pos.w or pos.heading or 0.0 } or false,
                }
            }
        else
            characters[#characters + 1] = { slot = i, character = nil, locked = false }
        end
    end

    charCache[source] = characters
    return characters
end

---Create a new ESX character
---@param source number
---@param identifier string
---@param data table
---@param maxSlots? number
---@return boolean success
---@return number|string slotOrError
function bridge.createCharacter(source, identifier, data, maxSlots)
    maxSlots   = maxSlots or Config.MaxSlots or 5
    identifier = baseId(identifier)

    local existing = MySQL.query.await([[
        SELECT identifier FROM users WHERE identifier LIKE ? ORDER BY id ASC
    ]], { 'char%:' .. identifier })

    local usedSlots = {}
    if existing then
        for _, row in ipairs(existing) do
            local n = tonumber(row.identifier:match('^char(%d+):'))
            if n then usedSlots[n] = true end
        end
    end

    local newSlot
    for i = 1, maxSlots do
        if not usedSlots[i] then newSlot = i break end
    end

    if not newSlot then
        return false, 'No available character slots'
    end

    local charIdentifier = ('char%d:%s'):format(newSlot, identifier)

    lib.print.debug(('[wasabi_multichar][ESX] createCharacter | source=%s charIdentifier=%s name=%s %s'):format(
        source, charIdentifier, data.firstName, data.lastName))

    pendingCreate[source] = {
        slot           = newSlot,
        charIdentifier = charIdentifier,
        firstName      = data.firstName,
        lastName       = data.lastName,
        data           = data,
    }

    return true, newSlot
end

---Check if a characterId belongs to the requesting player.
---@param identifier string
---@param characterId string
---@param identifier2? string Unused for ESX
---@return boolean
function bridge.ownsCharacter(identifier, characterId, identifier2)
    if type(characterId) ~= 'string' then return false end
    local base = baseId(identifier)
    return characterId:match('^char%d+:' .. base:gsub('([^%w])', '%%%1') .. '$') ~= nil
end

---Delete an ESX character
---@param identifier string
---@param slot number
---@param characterId string full ESX identifier
---@return boolean success
---@return string|nil error
function bridge.deleteCharacter(identifier, slot, characterId)
    if type(characterId) ~= 'string' or type(slot) ~= 'number' then
        return false, 'Invalid character data'
    end

    local base = baseId(identifier)
    -- characterId must belong to the requesting player's base identifier and match the slot.
    local expected = ('char%d:%s'):format(slot, base)
    if characterId ~= expected then
        lib.print.warn(('[wasabi_multichar][ESX] deleteCharacter: ownership mismatch (got=%s expected=%s)'):format(characterId, expected))
        return false, 'Permission denied'
    end

    local ok, result = pcall(deleteEsxCharacterData, characterId)
    if not ok then
        lib.print.error(('[wasabi_multichar][ESX] deleteCharacter failed for identifier=%s: %s'):format(characterId, result))
        return false, 'Unable to delete character data'
    end

    if not result then
        return false, 'Unable to delete character data'
    end

    return true
end

---Wait until ESX has finished creating/loading the player (createESXPlayer is async).
---@param source number
---@param timeoutMs? number
---@return table|nil xPlayer
local function waitForEsxPlayer(source, timeoutMs)
    timeoutMs = timeoutMs or 15000
    local deadline = GetGameTimer() + timeoutMs
    while GetGameTimer() < deadline do
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then return xPlayer end
        Wait(50)
    end
    return nil
end

---Select/load an ESX character
---@param source number
---@param identifier string
---@param slot number
---@param wasNew? boolean True when this select follows character creation
function bridge.selectCharacter(source, identifier, slot, wasNew)
    identifier = baseId(identifier)
    local pending = pendingCreate[source]
    local isNew = wasNew == true

    if not isNew and pending and pending.slot == slot then
        isNew = true
    end

    local cached = isNew and nil or getCachedCharacter(source, slot)
    local charId = ('char%d'):format(slot)
    local esxData = nil
    local nationality

    lib.print.debug(('[wasabi_multichar][ESX] selectCharacter | source=%s slot=%s isNew=%s'):format(source, slot, tostring(isNew)))

    if isNew then
        if not pending or pending.slot ~= slot or not pending.data then
            lib.print.warn(('[wasabi_multichar][ESX] selectCharacter: missing pending create for slot %s source %s'):format(slot, source))
            return
        end

        local d = pending.data
        charId = ('char%d'):format(pending.slot)
        nationality = d.nationality
        esxData = {
            firstname   = d.firstName,
            lastname    = d.lastName,
            dateofbirth = d.birthdate,
            sex         = (d.gender == 'female') and 'f' or 'm',
            height      = d.height or 180,
        }
        cached = {
            id           = pending.charIdentifier,
            firstName    = pending.firstName or 'Unknown',
            lastName     = pending.lastName  or 'Unknown',
            gender       = d.gender or 'male',
            job          = 'unemployed',
            lastPosition = false,
        }
        pendingCreate[source] = nil
    elseif not cached then
        local charIdentifier = ('char%d:%s'):format(slot, identifier)
        local row = MySQL.single.await('SELECT * FROM users WHERE identifier = ?', { charIdentifier })
        if row then
            cached = {
                id           = charIdentifier,
                firstName    = row.firstname or 'Unknown',
                lastName     = row.lastname  or 'Unknown',
                gender       = (row.sex == 'f' or row.sex == 'female') and 'female' or 'male',
                job          = row.job or 'unemployed',
                lastPosition = false,
            }
        end
    end

    if not cached then
        lib.print.warn(('[wasabi_multichar][ESX] selectCharacter: no character at slot %s for source %s — aborting'):format(slot, source))
        return
    end

    TriggerClientEvent('wasabi_multichar:closeUI', source)
    TriggerEvent('esx:onPlayerJoined', source, charId, esxData)

    if isNew then
        local xPlayer = waitForEsxPlayer(source)
        if not xPlayer then
            lib.print.error(('[wasabi_multichar][ESX] selectCharacter: ESX failed to load new character for source %s'):format(source))
            return
        end
        cached.id = xPlayer.identifier
        if nationality and nationality ~= '' then
            MySQL.update.await('UPDATE users SET nationality = ? WHERE identifier = ?', { nationality, xPlayer.identifier })
        end
    else
        local xPlayer = waitForEsxPlayer(source, 5000)
        if not xPlayer then
            lib.print.error(('[wasabi_multichar][ESX] selectCharacter: ESX failed to load character for source %s'):format(source))
            return
        end
        cached.id = xPlayer.identifier
    end

    local SpawnSelector = Modules.require('SpawnSelector')
    SpawnSelector.run(source, cached, isNew)
    charCache[source] = nil
end

---Logout player (return to multichar)
---@param source number
function bridge.logout(source)
    TriggerEvent('esx:playerLogout', source)
end

---Give money to player
---@param source number
---@param account string 'money' | 'bank'
---@param amount number
function bridge.addMoney(source, account, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    if account == 'money' then
        xPlayer.addMoney(amount)
    else
        xPlayer.addAccountMoney(account, amount)
    end
end

---Give item to player
---@param source number
---@param name string
---@param amount number
function bridge.addItem(source, name, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    xPlayer.addInventoryItem(name, amount)
end

Modules.register('bridge', bridge)
