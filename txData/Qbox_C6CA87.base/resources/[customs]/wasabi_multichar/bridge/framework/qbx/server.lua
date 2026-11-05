-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------
---@diagnostic disable: undefined-global
if not GetResourceState('qbx_core'):find('start') then return end

lib.print.debug('[wasabi_multichar] QBX framework detected, initializing bridge...')

local QBX           = exports.qbx_core
local bridge        = {}
local charCache     = {}
local pendingCreate = {}
local createLocks   = {}
local createGenerations = {}
local loadingLocks  = {}
local qbxSlotOverrides = nil
local qbxSlotOverridesLoaded = false

bridge.framework = 'qbx'

---Validate that an identifier is a canonical Rockstar license or license2 hex string.
---Rejects nil, empty strings, fxdk placeholders, steam, discord, or malformed values.
---@param id any
---@param expectedPrefix? 'license:' | 'license2:'
---@return boolean
local function isValidRockstarLicense(id, expectedPrefix)
    if type(id) ~= 'string' or id == '' or id == 'license:fxdk' then
        return false
    end
    if expectedPrefix then
        return id:match('^' .. expectedPrefix .. '%x+$') ~= nil
    end
    return id:match('^license2?:%x+$') ~= nil
end

---Validate that a citizenid is a non-empty alphanumeric identifier.
---@param citizenId any
---@return boolean
local function isValidCitizenId(citizenId)
    return type(citizenId) == 'string' and #citizenId >= 1 and #citizenId <= 32 and citizenId:match('^[%w_%-]+$') ~= nil
end

---Validate that a slot index is a positive integer.
---@param slot any
---@return boolean
local function isValidSlot(slot)
    return type(slot) == 'number' and slot >= 1 and slot == math.floor(slot)
end

---Extract live license2 and license identifiers directly from an active player source.
---@param source number
---@return string? license2
---@return string? license
local function getLivePlayerLicenses(source)
    if type(source) ~= 'number' or source <= 0 then
        return nil, nil
    end

    local license2, license
    if type(GetPlayerIdentifierByType) == 'function' then
        local srcStr = tostring(source)
        local l2 = GetPlayerIdentifierByType(srcStr, 'license2')
        local l1 = GetPlayerIdentifierByType(srcStr, 'license')
        if isValidRockstarLicense(l2, 'license2:') then license2 = l2 end
        if isValidRockstarLicense(l1, 'license:') then license = l1 end
    end

    if (not license2 or not license) and type(GetPlayerIdentifiers) == 'function' then
        local ids = GetPlayerIdentifiers(source)
        if type(ids) == 'table' then
            for _, id in ipairs(ids) do
                if not license2 and isValidRockstarLicense(id, 'license2:') then
                    license2 = id
                elseif not license and isValidRockstarLicense(id, 'license:') then
                    license = id
                end
            end
        end
    end

    return license2, license
end

---Resolve canonical character ownership identity (canonicalLicense and users.userId).
---Prefers live server source identifiers when source is a valid player ID; falls back to
---validated passed identifiers for bridge methods called without source (ownsCharacter, deleteCharacter).
---Fails closed if no valid Rockstar license exists or if a users table collision is detected.
---@param source number|nil
---@param passedIdentifier? string
---@param passedIdentifier2? string
---@return string? canonicalLicense
---@return number? userId
---@return string? secondaryLicense
---@return string? errorReason
local function resolvePlayerOwnership(source, passedIdentifier, passedIdentifier2)
    local license2, license
    if type(source) == 'number' and source > 0 then
        license2, license = getLivePlayerLicenses(source)
    else
        if isValidRockstarLicense(passedIdentifier2, 'license2:') then
            license2 = passedIdentifier2
        elseif isValidRockstarLicense(passedIdentifier, 'license2:') then
            license2 = passedIdentifier
        end
        if isValidRockstarLicense(passedIdentifier, 'license:') then
            license = passedIdentifier
        elseif isValidRockstarLicense(passedIdentifier2, 'license:') then
            license = passedIdentifier2
        end
    end

    -- Align strictly with Qbox Login / CheckPlayerData: license2 is primary, license is fallback ONLY when license2 is absent.
    local canonicalLicense = license2 or license
    if not canonicalLicense then
        return nil, nil, nil, 'no_valid_rockstar_license'
    end

    local column = canonicalLicense:match('^license2:') and 'license2' or 'license'
    local userRows = MySQL.query.await(
        ('SELECT userId, license, license2 FROM users WHERE `%s` = ?'):format(column),
        { canonicalLicense }
    )

    if type(userRows) == 'table' and #userRows > 1 then
        lib.print.error(('[wasabi_multichar][QBX] SECURITY: Multiple users rows (%d) matched %s=%s; failing closed.'):format(
            #userRows, column, canonicalLicense
        ))
        return nil, nil, nil, 'ambiguous_user_account'
    end

    local userRow = type(userRows) == 'table' and userRows[1] or nil
    local userId = userRow and tonumber(userRow.userId) or nil

    -- If a single users row exists and both license and license2 are present on the session,
    -- verify that the session's secondary license does not belong to a different users.userId.
    if userId and license2 and license then
        local otherRows = MySQL.query.await(
            'SELECT userId FROM users WHERE `license` = ?',
            { license }
        )
        if type(otherRows) == 'table' then
            for _, r in ipairs(otherRows) do
                local otherId = tonumber(r.userId)
                if otherId and otherId ~= userId then
                    lib.print.warn(('[wasabi_multichar][QBX] Secondary license %s belongs to userId=%s while canonical %s belongs to userId=%s; isolating strictly to canonical userId=%s.'):format(
                        license, tostring(otherId), canonicalLicense, tostring(userId), tostring(userId)
                    ))
                end
            end
        end
    end

    return canonicalLicense, userId, license, nil
end

---Load Qbox per-license character slot overrides from qbx_core/config/server.lua once.
---@return table<string, number>
local function getQbxSlotOverrides()
    if qbxSlotOverridesLoaded then
        return qbxSlotOverrides or {}
    end
    qbxSlotOverridesLoaded = true
    qbxSlotOverrides = {}

    if type(LoadResourceFile) == 'function' then
        local raw = LoadResourceFile('qbx_core', 'config/server.lua')
        if type(raw) == 'string' and raw ~= '' then
            local fn = load(raw, '@qbx_core/config/server.lua', 't', {
                exports = exports,
                lib = lib,
                GetConvar = GetConvar,
                GetConvarInt = GetConvarInt,
                math = math,
                tostring = tostring,
                tonumber = tonumber,
                pairs = pairs,
                ipairs = ipairs,
                type = type,
                table = table,
                string = string,
                os = os,
            })
            if fn then
                local ok, cfg = pcall(fn)
                if ok and type(cfg) == 'table' and type(cfg.characters) == 'table' and type(cfg.characters.playersNumberOfCharacters) == 'table' then
                    for k, v in pairs(cfg.characters.playersNumberOfCharacters) do
                        if type(k) == 'string' and type(v) == 'number' and v > 0 then
                            qbxSlotOverrides[k] = math.floor(v)
                        end
                    end
                end
            end
        end
    end

    return qbxSlotOverrides
end

---Count VIP extra slots stored under a specific identifier in wasabi_multicharacter_vips.
---@param identifier string?
---@return number
local function getVipSlotsForIdentifier(identifier)
    if not isValidRockstarLicense(identifier) then
        return 0
    end
    local ok, result = pcall(function()
        return MySQL.query.await(
            'SELECT transactions FROM wasabi_multicharacter_vips WHERE identifier = ?',
            { identifier }
        )
    end)
    if not ok or type(result) ~= 'table' or not result[1] then
        return 0
    end
    local transactions = type(result[1].transactions) == 'string' and json.decode(result[1].transactions) or result[1].transactions
    if type(transactions) ~= 'table' then
        return 0
    end
    local count = 0
    for _ in pairs(transactions) do
        count = count + 1
    end
    return count
end

---Calculate the effective unlocked character slots for a player, preserving:
---1. Ordinary default slots (Config.MaxSlots = 3)
---2. VIP extra slots (both license: via multichar.lua and license2: via wasabi_multicharacter_vips)
---3. Qbox playersNumberOfCharacters overrides
---@param source number
---@param canonicalLicense string
---@param secondaryLicense string?
---@param passedMaxSlots number?
---@return number
local function resolveEffectiveMaxSlots(source, canonicalLicense, secondaryLicense, passedMaxSlots)
    local baseSlots = tonumber(Config.MaxSlots) or 3
    local effective = tonumber(passedMaxSlots) or baseSlots
    if effective < baseSlots then
        effective = baseSlots
    end

    -- multichar.lua VipSlots:getCount(source) only checks `license:`.
    -- If /addvip was used with `license2:<hex>`, include those VIP slots as well without double-counting.
    if canonicalLicense and canonicalLicense:match('^license2:') and canonicalLicense ~= secondaryLicense then
        local license2VipCount = getVipSlotsForIdentifier(canonicalLicense)
        if license2VipCount > 0 then
            effective = effective + license2VipCount
        end
    end

    local overrides = getQbxSlotOverrides()
    local overrideVal = overrides[canonicalLicense] or (secondaryLicense and overrides[secondaryLicense]) or nil
    if type(overrideVal) == 'number' and overrideVal > effective then
        effective = overrideVal
    end

    return effective
end

local function getCachedCharacter(source, slot, expectedLicense)
    local cacheEntry = charCache[source]
    if type(cacheEntry) ~= 'table' then return nil end

    -- Support structured cache { license = ..., userId = ..., characters = ... }
    local list = cacheEntry.characters
    if not list then return nil end
    if expectedLicense and cacheEntry.license ~= expectedLicense then
        return nil
    end

    for _, entry in ipairs(list) do
        if entry.slot == slot and entry.character then
            return entry.character
        end
    end
    return nil
end

AddEventHandler('playerDropped', function()
    local src = tonumber(source)
    if src then
        charCache[src] = nil
        pendingCreate[src] = nil
        createGenerations[src] = (createGenerations[src] or 0) + 1
        createLocks[src] = nil
        loadingLocks[src] = nil
    end
end)

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

local qbxCharacterDataTables = {
    { 'properties', 'owner' },
    { 'bank_accounts_new', 'id' },
    { 'playerskins', 'citizenid' },
    { 'player_mails', 'citizenid' },
    { 'player_outfits', 'citizenid' },
    { 'player_vehicles', 'citizenid' },
    { 'player_groups', 'citizenid' },
    { 'npwd_calls', 'identifier' },
    { 'npwd_darkchat_channel_members', 'user_identifier' },
    { 'npwd_marketplace_listings', 'identifier' },
    { 'npwd_messages_participants', 'participant' },
    { 'npwd_notes', 'identifier' },
    { 'npwd_phone_contacts', 'identifier' },
    { 'npwd_phone_gallery', 'identifier' },
    { 'npwd_twitter_profiles', 'identifier' },
    { 'npwd_match_profiles', 'identifier' },
    { 'players', 'citizenid' },
}

local function doesColumnExist(tableName, columnName)
    local result = MySQL.scalar.await([[
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?
    ]], { tableName, columnName })

    return (result or 0) > 0
end

local function deleteQbxCharacterData(characterId)
    local queries = {}

    for i = 1, #qbxCharacterDataTables do
        local data = qbxCharacterDataTables[i]
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

---Fetch all players rows strictly owned by the resolved canonicalLicense and userId.
---Never uses an unvalidated OR across license and license2.
---@param canonicalLicense string
---@param userId number?
---@param columns? string
---@return table[]
local function queryOwnedCharacterRows(canonicalLicense, userId, columns)
    local selectCols = columns or '*'
    if userId then
        return MySQL.query.await(
            ('SELECT %s FROM players WHERE license = ? AND (userId = ? OR userId IS NULL) ORDER BY cid ASC, id ASC'):format(selectCols),
            { canonicalLicense, userId }
        ) or {}
    else
        return MySQL.query.await(
            ('SELECT %s FROM players WHERE license = ? AND userId IS NULL ORDER BY cid ASC, id ASC'):format(selectCols),
            { canonicalLicense }
        ) or {}
    end
end

---Sanitize free-text fields for character creation.
---@param value any
---@param maxLength number
---@return string?
local function sanitizeTextField(value, maxLength)
    if type(value) ~= 'string' then return nil end
    local trimmed = value:gsub('^%s+', ''):gsub('%s+$', '')
    if trimmed == '' or #trimmed > maxLength then return nil end
    return trimmed
end

---Get characters for a player
---@param source number
---@param identifier string Player license
---@param identifier2? string Player license2
---@param maxSlots? number
---@return table[]
function bridge.getCharacters(source, identifier, identifier2, maxSlots)
    local canonicalLicense, userId, secondaryLicense, err = resolvePlayerOwnership(source, identifier, identifier2)
    if not canonicalLicense then
        lib.print.warn(('[wasabi_multichar][QBX] getCharacters: denied for source=%s (%s)'):format(
            tostring(source), tostring(err)
        ))
        if type(source) == 'number' then
            charCache[source] = nil
        end
        return {}
    end

    local effectiveMaxSlots = resolveEffectiveMaxSlots(source, canonicalLicense, secondaryLicense, maxSlots)

    lib.print.debug(('[wasabi_multichar][QBX] getCharacters | source=%s canonicalLicense=%s userId=%s effectiveMaxSlots=%s'):format(
        tostring(source), canonicalLicense, tostring(userId), tostring(effectiveMaxSlots)
    ))

    local result = queryOwnedCharacterRows(canonicalLicense, userId, '*')

    lib.print.debug(('[wasabi_multichar][QBX] DB rows returned: %s'):format(#result))

    -- Preserve all existing characters on the account even if the account has more characters than default slots.
    local displaySlots = math.max(effectiveMaxSlots, #result)
    local assignedSlots = assignCharacterSlots(result, displaySlots)
    local characters = {}

    for i = 1, displaySlots do
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
            characters[#characters + 1] = { slot = i, character = nil, locked = i > effectiveMaxSlots }
        end
    end

    charCache[source] = {
        license    = canonicalLicense,
        userId     = userId,
        characters = characters,
    }
    return characters
end

---Create a new QBX character
---@param source number
---@param identifier string
---@param data table
---@param maxSlots? number
---@return boolean success
---@return number|string slotOrError
local function createCharacterForPlayer(source, identifier, data, maxSlots)
    if type(data) ~= 'table' then
        return false, 'Invalid character data'
    end

    local firstName   = sanitizeTextField(data.firstName, 50)
    local lastName    = sanitizeTextField(data.lastName, 50)
    local birthdate   = sanitizeTextField(data.birthdate, 50)
    local nationality = sanitizeTextField(data.nationality or 'American', 50)

    if not firstName or not lastName or not birthdate or not nationality then
        return false, 'Invalid character details'
    end

    local canonicalLicense, userId, secondaryLicense, err = resolvePlayerOwnership(source, identifier, nil)
    if not canonicalLicense then
        lib.print.warn(('[wasabi_multichar][QBX] createCharacter: denied for source=%s (%s)'):format(
            tostring(source), tostring(err)
        ))
        return false, 'Could not verify player identity'
    end

    local effectiveMaxSlots = resolveEffectiveMaxSlots(source, canonicalLicense, secondaryLicense, maxSlots)
    local result = queryOwnedCharacterRows(canonicalLicense, userId, 'id, citizenid, cid')

    if #result >= effectiveMaxSlots then
        return false, 'No available character slots'
    end

    local assignedSlots = assignCharacterSlots(result, effectiveMaxSlots)
    local usedSlots = {}
    for slot, row in pairs(assignedSlots) do
        if row then usedSlots[slot] = true end
    end

    local newSlot
    for i = 1, effectiveMaxSlots do
        if not usedSlots[i] then
            newSlot = i
            break
        end
    end

    if not newSlot then
        return false, 'No available character slots'
    end

    local newData = {
        cid      = newSlot,
        charinfo = {
            firstname   = firstName,
            lastname    = lastName,
            birthdate   = birthdate,
            gender      = data.gender == 'male' and 0 or 1,
            nationality = nationality,
            phone       = tostring(math.random(1000000, 9999999)),
        }
    }

    lib.print.debug(('[wasabi_multichar][QBX] createCharacter | source=%s canonicalLicense=%s assigned slot=%s'):format(
        tostring(source), canonicalLicense, tostring(newSlot)
    ))

    local pending = {
        license = canonicalLicense,
        userId  = userId,
        data    = newData,
    }
    return true, newSlot, pending
end

function bridge.createCharacter(source, identifier, data, maxSlots)
    if type(source) ~= 'number' or source <= 0 then
        return false, 'Invalid player source'
    end
    if createLocks[source] or pendingCreate[source] then
        return false, 'Character creation already in progress'
    end

    local generation = (createGenerations[source] or 0) + 1
    createGenerations[source] = generation
    createLocks[source] = generation

    local callOk, success, result, pending = pcall(
        createCharacterForPlayer, source, identifier, data, maxSlots
    )

    if createLocks[source] == generation then
        createLocks[source] = nil
    end

    if not callOk then
        lib.print.error(('[wasabi_multichar][QBX] createCharacter failed for source=%s: %s'):format(
            tostring(source), tostring(success)
        ))
        return false, 'Unable to create character'
    end
    if createGenerations[source] ~= generation or not GetPlayerName(source) then
        return false, 'Player session ended during character creation'
    end
    if not success then
        return false, result
    end

    local liveLicense2, liveLicense = getLivePlayerLicenses(source)
    local liveCanonicalLicense = liveLicense2 or liveLicense
    if liveCanonicalLicense ~= pending.license then
        return false, 'Player identity changed during character creation'
    end

    pendingCreate[source] = pending
    return true, result
end

---Check if a citizenid belongs to the requesting player.
---Supports both (identifier, characterId, identifier2) from escrow multichar.lua
---and (source, characterId) when called with a numeric player source.
---@param identifierOrSource string|number
---@param characterId string citizenid
---@param identifier2? string optional license2
---@return boolean
function bridge.ownsCharacter(identifierOrSource, characterId, identifier2)
    if not isValidCitizenId(characterId) then
        return false
    end

    local canonicalLicense, userId
    if type(identifierOrSource) == 'number' then
        canonicalLicense, userId = resolvePlayerOwnership(identifierOrSource, nil, nil)
    else
        canonicalLicense, userId = resolvePlayerOwnership(nil, identifierOrSource, identifier2)
    end

    if not canonicalLicense then
        return false
    end

    local row
    if userId then
        row = MySQL.single.await(
            'SELECT 1 FROM players WHERE citizenid = ? AND license = ? AND (userId = ? OR userId IS NULL) LIMIT 1',
            { characterId, canonicalLicense, userId }
        )
    else
        row = MySQL.single.await(
            'SELECT 1 FROM players WHERE citizenid = ? AND license = ? AND userId IS NULL LIMIT 1',
            { characterId, canonicalLicense }
        )
    end
    return row ~= nil
end

---Delete a QBX character
---@param identifier string
---@param slot number
---@param characterId string citizenid
---@param identifier2? string optional license2
---@return boolean success
---@return string|nil error
function bridge.deleteCharacter(identifier, slot, characterId, identifier2)
    if not isValidSlot(slot) then
        return false, 'Invalid slot'
    end
    if not isValidCitizenId(characterId) then
        return false, 'Invalid character id'
    end

    local canonicalLicense, userId = resolvePlayerOwnership(nil, identifier, identifier2)
    if not canonicalLicense then
        return false, 'Permission denied'
    end

    if not bridge.ownsCharacter(canonicalLicense, characterId, canonicalLicense) then
        lib.print.warn(('[wasabi_multichar][QBX] deleteCharacter: ownership mismatch (citizenid=%s canonicalLicense=%s userId=%s slot=%s)')
            :format(tostring(characterId), tostring(canonicalLicense), tostring(userId), tostring(slot)))
        return false, 'Permission denied'
    end

    local ok, result = pcall(deleteQbxCharacterData, characterId)
    if not ok then
        lib.print.error(('[wasabi_multichar][QBX] deleteCharacter failed for citizenid=%s: %s'):format(characterId, result))
        return false, 'Unable to delete character data'
    end

    if not result then
        return false, 'Unable to delete character data'
    end

    return true
end

---Select/load a QBX character
---@param source number
---@param identifier string
---@param slot number
---@param wasNew? boolean True when this select follows character creation
function bridge.selectCharacter(source, identifier, slot, wasNew)
    if type(source) ~= 'number' or source <= 0 then
        lib.print.warn(('[wasabi_multichar][QBX] selectCharacter: invalid source=%s'):format(tostring(source)))
        return
    end

    if not isValidSlot(slot) then
        lib.print.warn(('[wasabi_multichar][QBX] selectCharacter: invalid slot=%s from source=%s'):format(
            tostring(slot), tostring(source)
        ))
        return
    end

    if loadingLocks[source] then
        lib.print.warn(('[wasabi_multichar][QBX] selectCharacter: concurrent load attempt blocked for source=%s'):format(
            tostring(source)
        ))
        return
    end

    local canonicalLicense, userId, _, err = resolvePlayerOwnership(source, identifier, nil)
    if not canonicalLicense then
        lib.print.warn(('[wasabi_multichar][QBX] selectCharacter: denied for source=%s (%s)'):format(
            tostring(source), tostring(err)
        ))
        return
    end

    local pendingEntry = pendingCreate[source]
    local pendingData = (type(pendingEntry) == 'table' and pendingEntry.license == canonicalLicense) and pendingEntry.data or nil
    local isNew = wasNew == true

    if not isNew and pendingData and pendingData.cid == slot then
        isNew = true
    end

    local cached = nil
    if isNew then
        if not pendingData or pendingData.cid ~= slot then
            lib.print.warn(('[wasabi_multichar][QBX] selectCharacter: missing or mismatched pendingCreate for source=%s slot=%s'):format(
                tostring(source), tostring(slot)
            ))
            return
        end
    else
        cached = getCachedCharacter(source, slot, canonicalLicense)
        if not cached or not isValidCitizenId(cached.id) then
            lib.print.warn(('[wasabi_multichar][QBX] selectCharacter: unauthorized or uncached slot=%s for source=%s (canonicalLicense=%s)'):format(
                tostring(slot), tostring(source), canonicalLicense
            ))
            return
        end

        -- Re-verify persistent database ownership of the target citizenid before closing UI or logging in.
        if not bridge.ownsCharacter(source, cached.id) then
            lib.print.warn(('[wasabi_multichar][QBX] selectCharacter: DB ownership check failed for citizenid=%s source=%s canonicalLicense=%s'):format(
                tostring(cached.id), tostring(source), canonicalLicense
            ))
            return
        end
    end

    loadingLocks[source] = true
    local ok, loadErr = pcall(function()
        lib.print.debug(('[wasabi_multichar][QBX] selectCharacter | source=%s slot=%s isNew=%s wasNew=%s'):format(
            source, slot, tostring(isNew), tostring(wasNew)))

        TriggerClientEvent('wasabi_multichar:closeUI', source)

        if QBX:GetPlayer(source) then
            QBX:Logout(source)
        end

        if isNew then
            if not QBX:Login(source, nil, pendingData) then
                lib.print.debug('[wasabi_multichar][QBX] selectCharacter | Login FAILED for new character')
                return
            end
            pendingCreate[source] = nil
            local charinfo = pendingData.charinfo or {}
            cached = {
                id           = nil,
                job          = 'unemployed',
                lastPosition = false,
                gender       = charinfo.gender == 0 and 'male' or 'female',
            }
        else
            if not QBX:Login(source, cached.id) then
                lib.print.debug('[wasabi_multichar][QBX] selectCharacter | Login FAILED')
                return
            end
        end

        local SpawnSelector = Modules.require('SpawnSelector')
        SpawnSelector.run(source, cached, isNew)
        charCache[source] = nil
    end)
    loadingLocks[source] = nil

    if not ok then
        lib.print.error(('[wasabi_multichar][QBX] selectCharacter error for source=%s: %s'):format(
            tostring(source), tostring(loadErr)
        ))
    end
end

---Logout player (return to multichar)
---@param source number
function bridge.logout(source)
    if type(source) == 'number' then
        charCache[source] = nil
        pendingCreate[source] = nil
        createGenerations[source] = (createGenerations[source] or 0) + 1
        createLocks[source] = nil
        loadingLocks[source] = nil
    end
    QBX:Logout(source)
end

local function getQbxStarterItems()
    return nil -- qbx_core natively grants starter items via server/character.lua
end

local function waitForPlayerLoaded(source)
    for _ = 1, 120 do
        local qbxPlayer = QBX:GetPlayer(source)
        if qbxPlayer and Player(source).state.isLoggedIn then
            return qbxPlayer
        end
        Wait(500)
    end
end

---Give money to player
---@param source number
---@param account string e.g. 'cash', 'bank'
---@param amount number
function bridge.addMoney(source, account, amount)
    local Player = QBX:GetPlayer(source)
    if not Player then return false end
    return Player.Functions.AddMoney(account, amount)
end

---Give item to player
---@param source number
---@param name string
---@param amount number
---@param metadata table|nil
function bridge.addItem(source, name, amount, metadata)
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:AddItem(source, name, amount, metadata)
    end

    local Player = QBX:GetPlayer(source)
    if not Player then return false end
    return Player.Functions.AddItem(name, amount, nil, metadata)
end

---Give starter items after Qbox has finished loading the player/inventory.
---@param source number
---@param items table[]|nil Wasabi starter items; falls back to Qbox shared starterItems when nil
function bridge.deferStarterItems(source, items)
    CreateThread(function()
        local Player = waitForPlayerLoaded(source)
        if not Player then
            lib.print.warn(('[wasabi_multichar][QBX] starter items skipped; player did not finish loading (source=%s)'):format(source))
            return
        end

        Wait(500)

        if items then
            for _, reward in ipairs(items) do
                local success = true
                if reward.type == 'account' then
                    success = bridge.addMoney(source, reward.name, reward.amount)
                elseif reward.type == 'item' then
                    success = bridge.addItem(source, reward.name, reward.amount, reward.metadata)
                end

                if success == false then
                    lib.print.warn(('[wasabi_multichar][QBX] failed to grant starter reward %s x%s'):format(
                        tostring(reward.name), tostring(reward.amount)
                    ))
                end
            end
            return
        end

        local qbxStarterItems = getQbxStarterItems()
        if not qbxStarterItems then return end

        for _, item in ipairs(qbxStarterItems) do
            local metadata = item.metadata
            if type(metadata) == 'function' then
                local ok, result = pcall(metadata, source)
                if ok then
                    metadata = result
                else
                    metadata = nil
                    lib.print.warn(('[wasabi_multichar][QBX] failed to build starter metadata for %s: %s'):format(
                        tostring(item.name), tostring(result)
                    ))
                end
            end

            local success = bridge.addItem(source, item.name, item.amount or 1, metadata)
            if success == false then
                lib.print.warn(('[wasabi_multichar][QBX] failed to grant starter item %s x%s'):format(
                    tostring(item.name), tostring(item.amount or 1)
                ))
            end
        end
    end)
end

Modules.register('bridge', bridge)
