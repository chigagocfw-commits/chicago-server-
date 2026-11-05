-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------
---@diagnostic disable: undefined-global
local bridge     = Modules.require('bridge')
local Appearance = Modules.require('Appearance')

---Apply clothing/appearance to a ped
---@param ped number
---@param clothing table|string
local function setPedAppearance(ped, clothing)
    if not clothing then return end
    local data = type(clothing) == 'string' and json.decode(clothing) or clothing
    if not data then return end

    pcall(function()
        if GetResourceState('rcore_clothing') == 'started' then
            exports['rcore_clothing']:setPedSkin(ped, data)
            return
        end
        if GetResourceState('illenium-appearance') == 'started' then
            exports['illenium-appearance']:setPedAppearance(ped, data)
            return
        end
        if GetResourceState('fivem-appearance') == 'started' then
            exports['fivem-appearance']:setPedAppearance(ped, data)
            return
        end
        if GetResourceState('qb-clothing') == 'started' then
            TriggerEvent('qb-clothing:client:loadPlayerClothing', data, ped)
            return
        end
        Appearance.applyPedSkinFallback(ped, data)
    end)
end

---@param gender string|nil 'male' | 'female' (used for new characters before skin is saved)
local function genderToModel(gender)
    if gender == 'female' or gender == 'f' then
        return `mp_f_freemode_01`
    end
    return `mp_m_freemode_01`
end

---Load the correct ped model and apply skin/clothing for the player ped.
---@param characterId string|nil Character identifier; nil = brand-new char, use default model
---@param gender string|nil Fallback freemode model when no saved skin exists
local function loadPlayerAppearance(characterId, gender)
    local clothing, model
    if characterId then
        clothing, model = lib.callback.await('wasabi_multichar:getPedPreview', false, characterId)
    end

    if not model or model == '' then
        model = genderToModel(gender)
    end
    model = tonumber(model) and tonumber(model) or (type(model) == 'string' and joaat(model) or genderToModel(gender))

    lib.requestModel(model)
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)

    local ped = PlayerPedId()
    if clothing then
        setPedAppearance(ped, clothing)
    else
        SetPedDefaultComponentVariation(ped)
    end
end

---Apply freemode model + saved skin before an external spawn selector (wasabi_spawn, etc.).
---@param characterId string|nil
---@param gender string|nil
---@return boolean
local function preparePlayerAppearance(characterId, gender)
    ClearTimecycleModifier()
    ClearExtraTimecycleModifier()
    RenderScriptCams(false, false, 0, true, true)

    loadPlayerAppearance(characterId, gender)

    local ped = PlayerPedId()
    SetEntityVisible(ped, false, false)
    FreezeEntityPosition(ped, true)

    if bridge and bridge.framework == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        ESX.SetPlayerData('ped', ped)
    end

    return true
end

lib.callback.register('wasabi_multichar:preparePlayer', function(characterId, gender)
    return preparePlayerAppearance(characterId, gender)
end)

exports('PreparePlayerAppearance', preparePlayerAppearance)

local function getGroundedSpawnCoords(coords)
    local x = coords.x
    local y = coords.y
    local z = coords.z

    for _ = 1, 20 do
        RequestCollisionAtCoord(x, y, z)

        local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 50.0, false)
        if found then
            return vector3(x, y, groundZ)
        end

        Wait(50)
    end

    return vector3(x, y, z)
end

local function placePedOnGround(ped, coords, heading)
    local grounded = getGroundedSpawnCoords(coords)

    RequestCollisionAtCoord(grounded.x, grounded.y, grounded.z)
    for _ = 1, 20 do
        if HasCollisionLoadedAroundEntity(ped) then break end
        Wait(50)
    end

    SetEntityCoords(ped, grounded.x, grounded.y, grounded.z + 0.05, false, false, false, false)
    if heading then SetEntityHeading(ped, heading) end
end

---Play optional spawn synchronised scene at current ped position
---@param finalCoords vector3 Grounded final spawn position
---@param finalHeading number|nil Final spawn heading
local function runSpawnAnimation(finalCoords, finalHeading)
    local opts = Config.SpawnOptions
    if not opts or not opts.spawnAnimation then return end

    local dict = 'anim@scripted@heist@ig25_beach@male@'
    lib.requestAnimDict(dict)

    local ped = PlayerPedId()
    local heading = finalHeading or GetEntityHeading(ped)
    local zOffset = opts.spawnAnimationZOffset or 0.0
    local sceneZ = finalCoords.z + zOffset

    FreezeEntityPosition(ped, false)
    local scene = NetworkCreateSynchronisedScene(finalCoords.x, finalCoords.y, sceneZ, 0.0, 0.0, heading, 2, false, false, 8.0, 1000.0, 1.0)
    NetworkAddPedToSynchronisedScene(ped, scene, dict, 'action', 1000.0, 8.0, 0, 0, 1000.0, 8192)
    NetworkAddSynchronisedSceneCamera(scene, dict, 'action_camera')
    NetworkStartSynchronisedScene(scene)

    DoScreenFadeIn(1000)
    Wait(14250)

    NetworkStopSynchronisedScene(scene)
    ClearPedTasksImmediately(ped)
    placePedOnGround(ped, finalCoords, heading)
    FreezeEntityPosition(ped, false)
    ClearTimecycleModifier()
end

---Finalize spawn: set model, apply skin, teleport, make visible, fade in, then optionally open first-spawn customization.
---@param coords vector3 Spawn position
---@param heading number Spawn heading
---@param characterId string|nil Character identifier for appearance
---@param openCustomization boolean Whether to open first-spawn customization menu
---@param gender string|nil
---@param preserveExactCoords boolean|nil Whether to preserve saved coords instead of grounding them
local function applySpawn(coords, heading, characterId, openCustomization, gender, preserveExactCoords)
    loadPlayerAppearance(characterId, gender)

    local ped = PlayerPedId()
    local spawnCoords = preserveExactCoords and coords or getGroundedSpawnCoords(coords)

    if preserveExactCoords then
        RequestCollisionAtCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z)
        for _ = 1, 20 do
            if HasCollisionLoadedAroundEntity(ped) then break end
            Wait(50)
        end

        SetEntityCoords(ped, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, false)
        if heading then SetEntityHeading(ped, heading) end
    else
        placePedOnGround(ped, spawnCoords, heading)
    end

    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityAlpha(ped, 255, false)
    ClearTimecycleModifier()
    ClearExtraTimecycleModifier()

    Wait(500)

    local opts = Config.SpawnOptions
    if opts and opts.spawnAnimation and not openCustomization then
        runSpawnAnimation(spawnCoords, heading)
    else
        DoScreenFadeIn(1000)
    end

    while not IsScreenFadedIn() do Wait(10) end

    if openCustomization then
        if Appearance then Appearance.openFirstSpawnCustomization() end
    end

    if bridge then bridge.onPlayerLoaded() end
end

---Direct spawn at a known position
RegisterNetEvent('wasabi_multichar:spawnAt', function(position, heading, characterId, openCustomization, gender)
    applySpawn(
        type(position) == 'vector3' and position or vector3(position.x, position.y, position.z),
        heading or 0.0,
        characterId,
        openCustomization or false,
        gender,
        true
    )
end)

---Built-in spawn fallback: resolve coords from last position, job spawns, or defaultCoords.
RegisterNetEvent('wasabi_multichar:spawnDefault', function(character, position, heading, characterId, openCustomization)
    local coords, hdg

    if position then
        coords = type(position) == 'vector3' and position or vector3(position.x, position.y, position.z)
        hdg = heading or 0.0
    elseif character and character.job and Config.JobSpawns and Config.JobSpawns[character.job] then
        local js = Config.JobSpawns[character.job]
        coords = vector3(js.x, js.y, js.z)
        hdg = js.w or 0.0
    else
        local defaults = Config.SpawnOptions and Config.SpawnOptions.defaultCoords
        if defaults and #defaults > 0 then
            local pick = defaults[math.random(#defaults)]
            coords = vector3(pick.x, pick.y, pick.z)
            hdg = pick.w or 0.0
        else
            coords = vector3(-269.4, -955.3, 31.2)
            hdg = 205.0
        end
    end

    local gender = character and character.gender or nil
    applySpawn(coords, hdg, characterId, openCustomization or false, gender, position ~= nil)
end)
