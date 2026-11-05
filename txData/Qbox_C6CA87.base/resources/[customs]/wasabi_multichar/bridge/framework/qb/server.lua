-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------
---@diagnostic disable: undefined-global
if not GetResourceState('qb-core'):find('start') or GetResourceState('qbx_core'):find('start') then return end

lib.print.debug('[wasabi_multichar] QBCore framework detected, initializing bridge...')

local QBCore    = exports['qb-core']:GetCoreObject()
local bridge    = {}
local charCache     = {}
local pendingCreate = {}

bridge.framework = 'qb'

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

local function getSlotCid(row)
    local cid = row and tonumber(row.cid)
    if not cid then return nil end
    if cid < 1 or cid % 1 ~= 0 then return nil end
    return cid
end

local function assignCharacterSlots(rows, maxSlots)
    local slots, overflow = {}, {}

    if rows then
        for _, row in ipairs(rows) do
            local cid = getSlotCid(row)
            if cid and cid <= maxSlots and not slots[cid] then
                slots[cid] = row
            else
                overflow[#overflow + 1] = row
            end
        end
    end

    for _, row in ipairs(overflow) do
        for slot = 1, maxSlots do
            if not slots[slot] then
                slots[slot] = row
                break
            end
        end
    end

    return slots
end

local qbCharacterDataTables = {
    { 'apartments', 'citizenid' },
    { 'bank_accounts', 'citizenid' },
    { 'crypto_transactions', 'citizenid' },
    { 'phone_invoices', 'citizenid' },
    { 'phone_messages', 'citizenid' },
    { 'playerskins', 'citizenid' },
    { 'player_contacts', 'citizenid' },
    { 'player_houses', 'citizenid' },
    { 'player_mails', 'citizenid' },
    { 'player_outfits', 'citizenid' },
    { 'player_vehicles', 'citizenid' },
    { 'properties', 'owner' },
    { 'players', 'citizenid' },
}

local function doesColumnExist(tableName, columnName)
    local result = MySQL.scalar.await([[
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?
    ]], { tableName, columnName })

    return (result or 0) > 0
end

local function deleteQbCharacterData(characterId)
    local queries = {}

    for i = 1, #qbCharacterDataTables do
        local data = qbCharacterDataTables[i]
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
---@param identifier2? string Player license2
---@param maxSlots? number
---@return table[]
function bridge.getCharacters(source, identifier, identifier2, maxSlots)
    maxSlots = maxSlots or Config.MaxSlots or 5

    lib.print.debug(('[wasabi_multichar][QB] getCharacters | source=%s identifier=%s maxSlots=%s'):format(
        source, identifier, maxSlots))

    local result
    if identifier2 then
        result = MySQL.query.await([[
            SELECT * FROM players WHERE license = ? OR license = ? ORDER BY cid ASC
        ]], { identifier, identifier2 })
    else
        result = MySQL.query.await([[
            SELECT * FROM players WHERE license = ? ORDER BY cid ASC
        ]], { identifier })
    end

    lib.print.debug(('[wasabi_multichar][QB] DB rows returned: %s'):format(result and #result or 0))

    local assignedSlots = assignCharacterSlots(result, maxSlots)
    local characters = {}
    for i = 1, maxSlots do
        local char = assignedSlots[i]

        if char then
            local charinfo = (type(char.charinfo) == 'string' and json.decode(char.charinfo)) or char.charinfo or {}
            local job      = (type(char.job)      == 'string' and json.decode(char.job))      or char.job      or {}
            local money    = (type(char.money)     == 'string' and json.decode(char.money))    or char.money    or {}
            local pos      = (type(char.position)  == 'string' and json.decode(char.position)) or char.position or nil

            characters[#characters + 1] = {
                slot = i,
                character = {
                    id           = char.citizenid,
                    firstName    = charinfo.firstname   or 'Unknown',
                    lastName     = charinfo.lastname    or 'Unknown',
                    gender       = charinfo.gender == 0 and 'male' or 'female',
                    birthdate    = charinfo.birthdate   or '',
                    nationality  = charinfo.nationality or '',
                    job          = job.name             or 'unemployed',
                    jobLabel     = job.label            or 'Civilian',
                    cash         = money.cash           or 0,
                    bank         = money.bank           or 0,
                    phone        = charinfo.phone       or '',
                    lastPosition = pos and { x = pos.x, y = pos.y, z = pos.z, w = pos.w or pos.heading or 0.0 } or false,
                }
            }
        else
            characters[#characters + 1] = { slot = i, character = nil, locked = i > maxSlots }
        end
    end

    charCache[source] = characters
    return characters
end

---Create a new QB character
---@param source number
---@param identifier string
---@param data table
---@param maxSlots? number
---@return boolean success
---@return number|string slotOrError
function bridge.createCharacter(source, identifier, data, maxSlots)
    maxSlots = maxSlots or Config.MaxSlots or 5

    local result = MySQL.query.await([[
        SELECT cid FROM players WHERE license = ? ORDER BY cid ASC
    ]], { identifier })

    local assignedSlots = assignCharacterSlots(result, maxSlots)
    local usedSlots = {}
    for slot, row in pairs(assignedSlots) do
        if row then usedSlots[slot] = true end
    end

    local newSlot
    for i = 1, maxSlots do
        if not usedSlots[i] then newSlot = i break end
    end

    if not newSlot then
        return false, 'No available character slots'
    end

    local newData = {
        cid      = newSlot,
        charinfo = {
            firstname   = data.firstName,
            lastname    = data.lastName,
            birthdate   = data.birthdate,
            gender      = data.gender == 'male' and 0 or 1,
            nationality = data.nationality or 'American',
            phone       = QBCore.Functions.CreatePhoneNumber(),
        }
    }

    lib.print.debug(('[wasabi_multichar][QB] createCharacter | assigned slot=%s'):format(newSlot))

    pendingCreate[source] = newData
    return true, newSlot
end

---Check if a citizenid belongs to the requesting player.
---@param identifier string
---@param characterId string citizenid
---@param identifier2? string optional license2
---@return boolean
function bridge.ownsCharacter(identifier, characterId, identifier2)
    if type(characterId) ~= 'string' then return false end
    local row
    if identifier2 then
        row = MySQL.single.await(
            'SELECT 1 FROM players WHERE citizenid = ? AND (license = ? OR license = ?) LIMIT 1',
            { characterId, identifier, identifier2 }
        )
    else
        row = MySQL.single.await(
            'SELECT 1 FROM players WHERE citizenid = ? AND license = ? LIMIT 1',
            { characterId, identifier }
        )
    end
    return row ~= nil
end

---Delete a QB character
---@param identifier string
---@param slot number
---@param characterId string citizenid
---@param identifier2? string optional license2
---@return boolean success
---@return string|nil error
function bridge.deleteCharacter(identifier, slot, characterId, identifier2)
    local row
    if identifier2 then
        row = MySQL.single.await(
            'SELECT 1 FROM players WHERE citizenid = ? AND (license = ? OR license = ?) LIMIT 1',
            { characterId, identifier, identifier2 }
        )
    else
        row = MySQL.single.await(
            'SELECT 1 FROM players WHERE citizenid = ? AND license = ? LIMIT 1',
            { characterId, identifier }
        )
    end
    if not row then
        lib.print.warn(('[wasabi_multichar][QB] deleteCharacter: ownership mismatch (citizenid=%s license=%s slot=%s)')
            :format(characterId, identifier, slot))
        return false, 'Permission denied'
    end

    local ok, result = pcall(deleteQbCharacterData, characterId)
    if not ok then
        lib.print.error(('[wasabi_multichar][QB] deleteCharacter failed for citizenid=%s: %s'):format(characterId, result))
        return false, 'Unable to delete character data'
    end

    if not result then
        return false, 'Unable to delete character data'
    end

    return true
end

---Select/load a QB character
---@param source number
---@param identifier string
---@param slot number
function bridge.selectCharacter(source, identifier, slot, _wasNew)
    local cached = getCachedCharacter(source, slot)
    local isNew  = cached == nil

    lib.print.debug(('[wasabi_multichar][QB] selectCharacter | source=%s slot=%s isNew=%s'):format(source, slot, tostring(isNew)))

    TriggerClientEvent('wasabi_multichar:closeUI', source)

    if isNew then
        local pendingData = pendingCreate[source]
        if pendingData then
            if not QBCore.Player.Login(source, false, pendingData) then
                lib.print.debug('[wasabi_multichar][QB] selectCharacter | Login FAILED for new character')
                return
            end
            QBCore.Commands.Refresh(source)
            pendingCreate[source] = nil
            cached = { id = nil, job = 'unemployed', lastPosition = false }
        else
            lib.print.debug('[wasabi_multichar][QB] selectCharacter | no pendingCreate data, aborting')
            return
        end
    else
        if not QBCore.Player.Login(source, cached.id) then
            lib.print.debug('[wasabi_multichar][QB] selectCharacter | Login FAILED')
            return
        end
        QBCore.Commands.Refresh(source)
    end

    local SpawnSelector = Modules.require('SpawnSelector')
    SpawnSelector.run(source, cached, isNew)
    charCache[source] = nil
end

---Logout player (return to multichar)
---@param source number
function bridge.logout(source)
    QBCore.Player.Logout(source)
end

---Give money to player
---@param source number
---@param account string e.g. 'cash', 'bank'
---@param amount number
function bridge.addMoney(source, account, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    Player.Functions.AddMoney(account, amount)
end

---Give item to player
---@param source number
---@param name string
---@param amount number
function bridge.addItem(source, name, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    Player.Functions.AddItem(name, amount)
end

Modules.register('bridge', bridge)
