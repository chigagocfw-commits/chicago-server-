-- SOUH4IL-DEV — Client Master Controller & God Mode Engine
-- Author: SOUH4IL / Antigravity
-- Framework: Qbox / ox_lib

local SharedConfig = require 'config.shared'
local isPanelOpen = false

-- God Powers State
local isGodmode = false
local isInvis = false
local isNoclip = false
local isSuperSprint = false
local isSuperJump = false
local isFrozen = false

-- Popular Teleport Destinations (Vector4: x, y, z, heading)
local TELEPORT_LOCATIONS = {
    ['legion']   = vector4(215.76, -910.0, 30.69, 340.0),
    ['pillbox']  = vector4(298.54, -584.66, 43.26, 70.0),
    ['mrpd']     = vector4(428.23, -984.28, 30.71, 90.0),
    ['sandy']    = vector4(1734.55, 3710.98, 34.14, 210.0),
    ['paleto']   = vector4(-103.73, 6467.89, 31.63, 45.0),
    ['mazebank'] = vector4(-75.0, -818.0, 326.0, 0.0),
    ['casino']   = vector4(925.33, 47.11, 81.11, 60.0),
}

-- Item Pack Definitions
local ITEM_PACKS = {
    ['tactical_weapons'] = {
        { item = 'weapon_carbinerifle', count = 1 },
        { item = 'weapon_combatpistol', count = 1 },
        { item = 'weapon_smg', count = 1 },
        { item = 'ammo-rifle', count = 100 },
        { item = 'ammo-9', count = 100 },
    },
    ['survival_food'] = {
        { item = 'burger', count = 5 },
        { item = 'water', count = 5 },
        { item = 'medikit', count = 5 },
        { item = 'bandage', count = 5 },
    },
    ['special_ops'] = {
        { item = 'weapon_specialcarbine', count = 1 },
        { item = 'weapon_appistol', count = 1 },
        { item = 'weapon_heavysniper', count = 1 },
        { item = 'ammo-rifle', count = 150 },
        { item = 'ammo-sniper', count = 50 },
    }
}

---Toggles the SOUH4IL-DEV Control Panel
local function TogglePanel()
    if isPanelOpen then
        isPanelOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "setVisible", visible = false })
        return
    end

    lib.callback('souh4il_dev:server:getSecurityStatus', false, function(response)
        if not response or not response.success then
            lib.notify({
                title = SharedConfig.PanelName,
                description = response and response.error or "Server connection failed",
                type = 'error'
            })
            return
        end

        if not response.hasAccess and not response.isOwner then
            lib.notify({
                title = SharedConfig.PanelName,
                description = "Access Denied: You do not possess SOUH4IL-DEV staff permissions.",
                type = 'error'
            })
            return
        end

        isPanelOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "setVisible",
            visible = true,
            status = response,
            panelName = SharedConfig.PanelName,
            community = SharedConfig.Community
        })

        -- Sync active god toggles to UI
        SendNUIMessage({
            action = "syncToggles",
            toggles = {
                godmode = isGodmode,
                noclip = isNoclip,
                invis = isInvis,
                sprint = isSuperSprint,
                jump = isSuperJump
            }
        })
    end)
end

-- Primary Commands & Key Mapping
RegisterCommand('sdev_menu', TogglePanel, false)
RegisterCommand('sdev', TogglePanel, false)
RegisterCommand('devmenu', TogglePanel, false)
RegisterKeyMapping('sdev_menu', 'Open SOUH4IL-DEV Control Panel', 'keyboard', 'F10')

-- Status Check Command
RegisterCommand('sdev_status', function()
    lib.callback('souh4il_dev:server:getSecurityStatus', false, function(response)
        if not response or not response.success then
            lib.notify({ title = SharedConfig.PanelName, description = "Connection failed", type = 'error' })
            return
        end
        lib.notify({
            title = SharedConfig.PanelName,
            description = ("Role: %s | Owner: %s"):format(response.role, response.isOwner and "YES (Dual-Key)" or "NO"),
            type = response.isOwner and 'success' or 'inform'
        })
    end)
end, false)

-- =========================================================================
-- GOD MODE ENGINE
-- =========================================================================
CreateThread(function()
    while true do
        if isGodmode then
            local ped = PlayerPedId()
            SetEntityInvincible(ped, true)
            SetPlayerInvincible(PlayerId(), true)
            SetPedCanRagdoll(ped, false)
            ClearPedBloodDamage(ped)
            ResetPedVisibleDamage(ped)
            SetPedDiesInWater(ped, false)
            SetPedCanBeKnockedOffBike(ped, false)
            if GetEntityHealth(ped) < 200 then
                SetEntityHealth(ped, 200)
            end
            if GetPedArmour(ped) < 100 then
                SetPedArmour(ped, 100)
            end
            Wait(250)
        else
            Wait(1000)
        end
    end
end)

-- Super Powers Engine (Sprint & Jump)
CreateThread(function()
    while true do
        local sleep = 500
        local player = PlayerId()

        if isSuperSprint then
            sleep = 0
            SetRunSprintMultiplierForPlayer(player, 1.49)
            SetSwimMultiplierForPlayer(player, 1.49)
            RestorePlayerStamina(player, 1.0)
        end

        if isSuperJump then
            sleep = 0
            SetSuperJumpThisFrame(player)
        end

        Wait(sleep)
    end
end)

-- =========================================================================
-- NOCLIP ENGINE (Smooth Freecam)
-- =========================================================================
local speeds = { 0.5, 1.5, 3.5, 7.0, 15.0 }
local speedIndex = 2

CreateThread(function()
    while true do
        if isNoclip then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            local entity = veh ~= 0 and veh or ped

            SetEntityCollision(entity, false, false)
            FreezeEntityPosition(entity, true)
            SetEntityInvincible(entity, true)

            local camRot = GetGameplayCamRot(2)
            SetEntityRotation(entity, 0.0, 0.0, camRot.z, 2, false)

            local forward, right, up, p = GetEntityMatrix(entity)
            local delta = vector3(0, 0, 0)

            local currentSpeed = speeds[speedIndex]
            if IsControlPressed(0, 21) then -- Left Shift
                currentSpeed = currentSpeed * 2.5
            end

            -- W / S (Forward / Backward)
            if IsControlPressed(0, 32) then
                delta = delta + (forward * currentSpeed)
            elseif IsControlPressed(0, 33) then
                delta = delta - (forward * currentSpeed)
            end

            -- A / D (Left / Right)
            if IsControlPressed(0, 34) then
                delta = delta - (right * currentSpeed)
            elseif IsControlPressed(0, 35) then
                delta = delta + (right * currentSpeed)
            end

            -- Space (Up) / Ctrl (Down)
            if IsControlPressed(0, 22) then
                delta = delta + vector3(0.0, 0.0, currentSpeed)
            elseif IsControlPressed(0, 36) then
                delta = delta - vector3(0.0, 0.0, currentSpeed)
            end

            local curCoords = GetEntityCoords(entity)
            SetEntityCoordsNoOffset(entity, curCoords.x + delta.x, curCoords.y + delta.y, curCoords.z + delta.z, false, false, false)

            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- =========================================================================
-- VEHICLE HELPERS
-- =========================================================================
local function ApplyMaxTune(veh)
    if not DoesEntityExist(veh) then return end
    SetVehicleModKit(veh, 0)
    ToggleVehicleMod(veh, 18, true) -- Turbo
    SetVehicleMod(veh, 11, 3, false) -- Engine Max
    SetVehicleMod(veh, 12, 2, false) -- Brakes Max
    SetVehicleMod(veh, 13, 2, false) -- Transmission Max
    SetVehicleMod(veh, 15, 3, false) -- Suspension Max
    ToggleVehicleMod(veh, 22, true) -- Xenon Lights
    SetVehicleDirtLevel(veh, 0.0)
    SetVehicleFixed(veh)
end

local function SpawnVehicle(modelName, maxTune)
    local ped = PlayerPedId()
    local hash = joaat(modelName)

    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        lib.notify({ title = SharedConfig.PanelName, description = "Invalid vehicle model: " .. modelName, type = 'error' })
        return
    end

    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end

    if not HasModelLoaded(hash) then
        lib.notify({ title = SharedConfig.PanelName, description = "Failed to load model: " .. modelName, type = 'error' })
        return
    end

    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)

    SetPedIntoVehicle(ped, veh, -1)
    SetVehicleEngineOn(veh, true, true, false)
    SetModelAsNoLongerNeeded(hash)

    local netId = NetworkGetNetworkIdFromEntity(veh)
    SetNetworkIdExistsOnAllMachines(netId, true)

    -- Register keys in server
    lib.callback('souh4il_dev:server:giveVehicleKeys', false, function() end, netId)

    if maxTune then
        ApplyMaxTune(veh)
    end

    lib.notify({ title = SharedConfig.PanelName, description = ("Vehicle '%s' spawned."):format(modelName), type = 'success' })
end

-- =========================================================================
-- NUI CALLBACKS
-- =========================================================================

-- Close
RegisterNUICallback('close', function(_, cb)
    isPanelOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Quick Actions
RegisterNUICallback('quickAction', function(data, cb)
    local action = data.action
    local ped = PlayerPedId()

    lib.callback('souh4il_dev:server:requestQuickAction', false, function(response)
        if not response or not response.success then
            lib.notify({ title = SharedConfig.PanelName, description = response and response.error or "Rejected", type = 'error' })
            return
        end

        if action == 'revive' or action == 'heal' then
            lib.notify({ title = SharedConfig.PanelName, description = action:upper() .. " applied successfully.", type = 'success' })
        elseif action == 'armor' then
            SetPedArmour(ped, 100)
            lib.notify({ title = SharedConfig.PanelName, description = "Armor restored to 100%.", type = 'success' })
        elseif action == 'repair' then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                SetVehicleFixed(veh)
                SetVehicleDirtLevel(veh, 0.0)
                lib.notify({ title = SharedConfig.PanelName, description = "Vehicle repaired & cleaned.", type = 'success' })
            else
                lib.notify({ title = SharedConfig.PanelName, description = "Must be inside a vehicle.", type = 'error' })
            end
        elseif action == 'clean' then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                SetVehicleDirtLevel(veh, 0.0)
            else
                ClearPedBloodDamage(ped)
                ResetPedVisibleDamage(ped)
            end
            lib.notify({ title = SharedConfig.PanelName, description = "Cleaned successfully.", type = 'success' })
        elseif action == 'tpm' then
            local waypoint = GetFirstBlipInfoId(8)
            if DoesBlipExist(waypoint) then
                local coords = GetBlipInfoIdCoord(waypoint)
                DoScreenFadeOut(200)
                Wait(250)
                SetEntityCoords(ped, coords.x, coords.y, coords.z + 1.0, false, false, false, false)
                Wait(200)
                DoScreenFadeIn(200)
                lib.notify({ title = SharedConfig.PanelName, description = "Teleported to waypoint.", type = 'success' })
            else
                lib.notify({ title = SharedConfig.PanelName, description = "No map waypoint set.", type = 'error' })
            end
        elseif action == 'dv' then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                DeleteEntity(veh)
                lib.notify({ title = SharedConfig.PanelName, description = "Vehicle deleted.", type = 'inform' })
            end
        elseif action == 'maxmod' then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                ApplyMaxTune(veh)
                lib.notify({ title = SharedConfig.PanelName, description = "Max performance mods applied.", type = 'success' })
            else
                lib.notify({ title = SharedConfig.PanelName, description = "Must be inside a vehicle.", type = 'error' })
            end
        end
    end, action)

    cb('ok')
end)

-- God Powers Toggle
RegisterNUICallback('togglePower', function(data, cb)
    local ped = PlayerPedId()
    local power = data.power
    local state = data.state

    if power == 'godmode' then
        isGodmode = state
        SetEntityInvincible(ped, state)
        SetPlayerInvincible(PlayerId(), state)
        SetPedCanRagdoll(ped, not state)
        SetPedDiesInWater(ped, not state)
        if state then
            SetEntityHealth(ped, 200)
            SetPedArmour(ped, 100)
        end
        lib.notify({ title = SharedConfig.PanelName, description = "God Mode " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'noclip' then
        isNoclip = state
        local veh = GetVehiclePedIsIn(ped, false)
        local entity = veh ~= 0 and veh or ped
        if not state then
            SetEntityCollision(entity, true, true)
            FreezeEntityPosition(entity, false)
            SetEntityInvincible(entity, isGodmode)
        end
        lib.notify({ title = SharedConfig.PanelName, description = "NoClip " .. (state and "ENABLED (Fly with WASD/Space/Ctrl)" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'invis' then
        isInvis = state
        SetEntityVisible(ped, not state, false)
        SetLocalPlayerVisibleLocally(true)
        lib.notify({ title = SharedConfig.PanelName, description = "Invisibility " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'sprint' then
        isSuperSprint = state
        if not state then
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
            SetSwimMultiplierForPlayer(PlayerId(), 1.0)
        end
        lib.notify({ title = SharedConfig.PanelName, description = "Super Sprint " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'jump' then
        isSuperJump = state
        lib.notify({ title = SharedConfig.PanelName, description = "Super Jump " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    end

    cb('ok')
end)

-- Teleport Preset
RegisterNUICallback('teleportPreset', function(data, cb)
    local locKey = data.location
    local dest = TELEPORT_LOCATIONS[locKey]
    if dest then
        local ped = PlayerPedId()
        DoScreenFadeOut(200)
        Wait(250)
        SetEntityCoords(ped, dest.x, dest.y, dest.z, false, false, false, false)
        SetEntityHeading(ped, dest.w)
        Wait(200)
        DoScreenFadeIn(200)
        lib.notify({ title = SharedConfig.PanelName, description = "Teleported to " .. locKey:upper(), type = 'success' })
    end
    cb('ok')
end)

-- Teleport Coords
RegisterNUICallback('teleportCoords', function(data, cb)
    local ped = PlayerPedId()
    local x = tonumber(data.x)
    local y = tonumber(data.y)
    local z = tonumber(data.z)
    if x and y and z then
        DoScreenFadeOut(200)
        Wait(250)
        SetEntityCoords(ped, x, y, z, false, false, false, false)
        Wait(200)
        DoScreenFadeIn(200)
        lib.notify({ title = SharedConfig.PanelName, description = ("Teleported to (%.1f, %.1f, %.1f)"):format(x, y, z), type = 'success' })
    end
    cb('ok')
end)

-- Fetch Online Players
RegisterNUICallback('fetchPlayers', function(_, cb)
    lib.callback('souh4il_dev:server:getOnlinePlayers', false, function(response)
        if response and response.success then
            SendNUIMessage({ action = "updatePlayers", players = response.players })
        end
    end)
    cb('ok')
end)

-- Player Teleport Actions (Goto / Bring)
RegisterNUICallback('teleportAction', function(data, cb)
    lib.callback('souh4il_dev:server:teleportAction', false, function(response)
        if response and response.success then
            lib.notify({ title = SharedConfig.PanelName, description = ("Action '%s' completed."):format(data.action), type = 'success' })
        else
            lib.notify({ title = SharedConfig.PanelName, description = response and response.error or "Failed", type = 'error' })
        end
    end, data.action, data.targetId)
    cb('ok')
end)

-- Freeze Player
RegisterNUICallback('freezePlayer', function(data, cb)
    local targetId = data.targetId
    isFrozen = not isFrozen
    lib.callback('souh4il_dev:server:freezePlayer', false, function(response)
        if response and response.success then
            lib.notify({ title = SharedConfig.PanelName, description = "Player freeze state toggled.", type = 'inform' })
        else
            lib.notify({ title = SharedConfig.PanelName, description = response and response.error or "Failed", type = 'error' })
        end
    end, targetId, isFrozen)
    cb('ok')
end)

-- Kick Player
RegisterNUICallback('kickPlayer', function(data, cb)
    lib.callback('souh4il_dev:server:kickPlayer', false, function(response)
        if response and response.success then
            lib.notify({ title = SharedConfig.PanelName, description = "Player kicked from server.", type = 'success' })
            -- Refresh list
            lib.callback('souh4il_dev:server:getOnlinePlayers', false, function(res)
                if res and res.success then SendNUIMessage({ action = "updatePlayers", players = res.players }) end
            end)
        else
            lib.notify({ title = SharedConfig.PanelName, description = response and response.error or "Kick failed", type = 'error' })
        end
    end, data)
    cb('ok')
end)

-- Ban Player
RegisterNUICallback('banPlayer', function(data, cb)
    lib.callback('souh4il_dev:server:banPlayer', false, function(response)
        if response and response.success then
            lib.notify({ title = SharedConfig.PanelName, description = "Player successfully banned.", type = 'success' })
            -- Refresh list
            lib.callback('souh4il_dev:server:getOnlinePlayers', false, function(res)
                if res and res.success then SendNUIMessage({ action = "updatePlayers", players = res.players }) end
            end)
        else
            lib.notify({ title = SharedConfig.PanelName, description = response and response.error or "Ban failed", type = 'error' })
        end
    end, data)
    cb('ok')
end)

-- Items: Give Pack
RegisterNUICallback('giveItemPack', function(data, cb)
    local pack = ITEM_PACKS[data.pack]
    if pack then
        for _, itemData in ipairs(pack) do
            lib.callback('souh4il_dev:server:giveItem', false, function() end, { item = itemData.item, count = itemData.count })
        end
        lib.notify({ title = SharedConfig.PanelName, description = "Equipment pack granted to inventory.", type = 'success' })
    end
    cb('ok')
end)

-- Items: Give Custom Item
RegisterNUICallback('giveCustomItem', function(data, cb)
    lib.callback('souh4il_dev:server:giveItem', false, function(response)
        if response and response.success then
            lib.notify({ title = SharedConfig.PanelName, description = ("Received %dx %s"):format(data.count, data.item), type = 'success' })
        else
            lib.notify({ title = SharedConfig.PanelName, description = response and response.error or "Item failed", type = 'error' })
        end
    end, data)
    cb('ok')
end)

-- Give Money
RegisterNUICallback('giveMoney', function(data, cb)
    lib.callback('souh4il_dev:server:giveMoney', false, function(response)
        if response and response.success then
            lib.notify({ title = SharedConfig.PanelName, description = ("Received $%d cash."):format(data.amount), type = 'success' })
        else
            lib.notify({ title = SharedConfig.PanelName, description = response and response.error or "Money failed", type = 'error' })
        end
    end, data)
    cb('ok')
end)

-- Vehicle Spawner
RegisterNUICallback('spawnVehicle', function(data, cb)
    if data.model and #data.model > 0 then
        SpawnVehicle(data.model, data.maxTune == true)
    end
    cb('ok')
end)

-- Fetch Audit Logs
RegisterNUICallback('fetchLogs', function(_, cb)
    lib.callback('souh4il_dev:server:queryAuditLogs', false, function(response)
        if response and response.success then
            SendNUIMessage({ action = "updateLogs", logs = response.logs })
        end
    end, 30)
    cb('ok')
end)

-- Weather Set
RegisterNUICallback('setWeather', function(data, cb)
    TriggerServerEvent('souh4il_dev:server:setWeather', data.weather)
    cb('ok')
end)

-- Cleanup on Stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= cache.resource then return end
    if isPanelOpen then SetNuiFocus(false, false) end
    if isNoclip then
        local ped = PlayerPedId()
        SetEntityCollision(ped, true, true)
        FreezeEntityPosition(ped, false)
    end
    if isGodmode then
        local ped = PlayerPedId()
        SetEntityInvincible(ped, false)
        SetPlayerInvincible(PlayerId(), false)
    end
end)
