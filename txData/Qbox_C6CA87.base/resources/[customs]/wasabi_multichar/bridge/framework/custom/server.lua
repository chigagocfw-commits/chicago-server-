-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------
---@diagnostic disable: undefined-global
if GetResourceState('qb-core'):find('start') or GetResourceState('qbx_core'):find('start') or GetResourceState('es_extended'):find('start') then return end

lib.print.debug('[wasabi_multichar] No known framework detected, loading custom bridge...')

local bridge    = {}
local charCache = {}

bridge.framework = 'custom'

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

---Get characters for a player (uses ESX `users` table schema as fallback)
---@param source number
---@param identifier string
---@param identifier2? string
---@param maxSlots? number
---@return table[]
function bridge.getCharacters(source, identifier, identifier2, maxSlots)
    maxSlots = maxSlots or Config.MaxSlots or 5

    -- Escape LIKE metacharacters and anchor to the end of the identifier so we
    -- only match `charN:<identifier>` rows for this player, not substrings.
    local safeIdentifier = identifier:gsub('([%%_\\])', '\\%1')
    local result = MySQL.query.await([[
        SELECT * FROM users WHERE identifier LIKE ? ESCAPE '\' ORDER BY id ASC
    ]], { 'char%:' .. safeIdentifier })

    local characters = {}
    if result then
        for i, row in ipairs(result) do
            if i > maxSlots then break end

            local accounts = (type(row.accounts) == 'string' and json.decode(row.accounts)) or {}
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
            if row.job and row.job ~= '' then
                local jobRow = MySQL.single.await('SELECT label FROM jobs WHERE name = ? LIMIT 1', { row.job })
                if jobRow then jobLabel = jobRow.label end
            end

            local pos = (type(row.position) == 'string' and json.decode(row.position)) or row.position or nil

            characters[#characters + 1] = {
                slot = i,
                character = {
                    id           = row.identifier or row.id,
                    firstName    = row.firstname   or 'Unknown',
                    lastName     = row.lastname    or 'Unknown',
                    gender       = row.sex         or 'male',
                    birthdate    = row.dateofbirth or '',
                    nationality  = row.nationality or '',
                    job          = row.job         or 'unemployed',
                    jobLabel     = jobLabel,
                    cash         = cash,
                    bank         = bank,
                    phone        = row.phone_number or '',
                    lastPosition = pos and { x = pos.x, y = pos.y, z = pos.z, w = pos.w or pos.heading or 0.0 } or false,
                },
            }
        end
    end

    for i = #characters + 1, maxSlots do
        characters[#characters + 1] = { slot = i, character = nil, locked = false }
    end

    charCache[source] = characters
    return characters
end

---Create a new character — implement for your framework
---@param source number
---@param identifier string
---@param data table
---@param maxSlots? number
---@return boolean success
---@return string|nil error
function bridge.createCharacter(source, identifier, data, maxSlots)
    return false, 'Custom framework: createCharacter not implemented'
end

---Check if a characterId belongs to the requesting player — implement for your framework.
---Used to gate per-character lookups (ped preview, deletion). Return false by default to
---deny access; implementers should query their DB to confirm ownership.
---@param identifier string
---@param characterId string
---@param identifier2? string
---@return boolean
function bridge.ownsCharacter(identifier, characterId, identifier2)
    return false
end

---Delete a character — implement for your framework
---IMPORTANT: validate that characterId actually belongs to the requesting player
---(match against identifier/identifier2) before deleting.
---@param identifier string
---@param slot number
---@param characterId string
---@param identifier2? string optional secondary identifier
---@return boolean success
---@return string|nil error
function bridge.deleteCharacter(identifier, slot, characterId, identifier2)
    return false, 'Custom framework: deleteCharacter not implemented'
end

---Select/load a character
---@param source number
---@param identifier string
---@param slot number
function bridge.selectCharacter(source, identifier, slot, _wasNew)
    local cached = getCachedCharacter(source, slot)
    TriggerClientEvent('wasabi_multichar:closeUI', source)
    local SpawnSelector = Modules.require('SpawnSelector')
    SpawnSelector.run(source, cached, false)
    charCache[source] = nil
end

---Logout player — implement for your framework
---@param source number
function bridge.logout(source)
    -- Implement your custom logout logic here
end

---Give money to player — implement for your framework
---@param source number
---@param account string
---@param amount number
function bridge.addMoney(source, account, amount)
    -- Implement your custom addMoney logic here
end

---Give item to player — implement for your framework
---@param source number
---@param name string
---@param amount number
function bridge.addItem(source, name, amount)
    -- Implement your custom addItem logic here
end

Modules.register('bridge', bridge)
