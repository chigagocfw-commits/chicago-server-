-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------
---@diagnostic disable: undefined-global

local bridge
local SpawnSelector = {}

function SpawnSelector.init()
    bridge = Modules.get('bridge')
end

---Resolve last-known position from cached character data
---@param cached table|nil Character cache entry (with .lastPosition)
---@return vector3|nil position
---@return number|nil heading
local function resolvePosition(cached)
    local pos = type(cached) == 'table' and cached.lastPosition
    if type(pos) ~= 'table' then return nil, nil end

    local x, y, z = pos.x, pos.y, pos.z
    local heading = pos.w or pos.heading
    local function isFinite(value)
        return type(value) == 'number' and value == value and value ~= math.huge and value ~= -math.huge
    end

    if not isFinite(x) or not isFinite(y) or not isFinite(z)
        or math.abs(x) > 10000 or math.abs(y) > 10000 or z < -1000 or z > 10000 then
        return nil, nil
    end

    if not isFinite(heading) then heading = 0.0 end
    return vector3(x, y, z), heading % 360.0
end

---Ask the client to set freemode model + skin before opening an external spawn selector.
---@param source number
---@param appearanceId string|nil
---@param gender string|nil
---@return boolean
local function preparePlayerAppearance(source, appearanceId, gender)
    local ok, result = pcall(function()
        return lib.callback.await('wasabi_multichar:preparePlayer', source, appearanceId, gender)
    end)
    if not ok or result ~= true then
        lib.print.warn(('[wasabi_multichar] preparePlayer failed for source %s (ok=%s)'):format(source, tostring(ok)))
        return false
    end
    return true
end

---Pick a random default coord from Config.SpawnOptions.defaultCoords
---@return vector4
local function getDefaultCoord()
    local coords = Config.SpawnOptions and Config.SpawnOptions.defaultCoords
    if coords and #coords > 0 then
        return coords[math.random(#coords)]
    end
    return vector4(-269.4, -955.3, 31.2, 205.0)
end

---Main spawn selector entry point, called after selectCharacter / createCharacter.
---Decides whether to use an external spawn resource, built-in fallback, or skip entirely.
---@param source number Player server id
---@param cached table|nil Cached character data from getCharacters (has .lastPosition, .job, .id)
---@param isNew boolean True when spawning a brand-new character
function SpawnSelector.run(source, cached, isNew)
    local opts = Config.SpawnOptions or {}
    local position, heading = resolvePosition(cached)
    local characterId = cached and cached.id or nil

    if not isNew and not position then
        local fallback = getDefaultCoord()
        position = vector3(fallback.x, fallback.y, fallback.z)
        heading = fallback.w
    end

    local openCustomization = isNew and (not opts.useCustomSpawnSelector or (opts.useCustomSpawnSelector and not opts.spawnSelectOnFirstSpawn))

    local gender = cached and cached.gender or nil
    -- New characters have no saved skin yet; use gender-based freemode on the client.
    local appearanceId = (isNew and openCustomization) and nil or characterId

    if opts.skipSpawnSelector then
        if position and not isNew then
            TriggerClientEvent('wasabi_multichar:spawnAt', source, position, heading, appearanceId, false, gender)
        else
            local def = getDefaultCoord()
            TriggerClientEvent('wasabi_multichar:spawnAt', source, vector3(def.x, def.y, def.z), def.w, appearanceId, openCustomization, gender)
        end
        return
    end

    if opts.useCustomSpawnSelector then
        if isNew and not opts.spawnSelectOnFirstSpawn then
            local def = getDefaultCoord()
            TriggerClientEvent('wasabi_multichar:spawnAt', source, vector3(def.x, def.y, def.z), def.w, appearanceId, openCustomization, gender)
            return
        end

        preparePlayerAppearance(source, appearanceId, gender)

        if GetResourceState('wasabi_spawn') == 'started' then
            TriggerClientEvent('wasabi_spawn:openMenu', source, isNew, position)
            return
        end

        if GetResourceState('um-spawn') == 'started' then
            TriggerClientEvent('wasabi_multicharacter:spawnMenu', source, position)
            return
        end

        if bridge and (bridge.framework == 'qb' or bridge.framework == 'qbx') then
            local cData = { citizenid = characterId, position = position }
            if GetResourceState('qb-apartments') == 'started' then
                TriggerClientEvent('apartments:client:setupSpawnUI', source, cData)
                return
            end
            if GetResourceState('qb-spawn') == 'started' then
                TriggerClientEvent('qb-spawn:client:setupSpawns', source, cData, false, nil)
                TriggerClientEvent('qb-spawn:client:openUI', source, true)
                return
            end
        end
    end

    TriggerClientEvent('wasabi_multichar:spawnDefault', source, cached, position, heading, appearanceId, openCustomization)
end

Modules.register('SpawnSelector', SpawnSelector, {
    optionalDependencies = { 'bridge' }
})
