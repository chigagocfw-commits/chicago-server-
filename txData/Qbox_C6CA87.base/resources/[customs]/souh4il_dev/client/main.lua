-- SOUH4IL-DEV — Client Master Controller & Pro Developer Suite
-- Author: SOUH4IL / Antigravity
-- Framework: Qbox / ox_lib

local SharedConfig = require 'config.shared'
local isPanelOpen = false

-- Full Super Powers State
local isGodmode = false
local isInvis = false
local isNoclip = false
local isInfiniteAmmo = false
local isSuperDamage = false
local isNeverWanted = false
local isThermalVision = false
local isNightVision = false
local isSuperSprint = false
local isSuperJump = false
local isVehGodmode = false
local isVehBoost = false
local isFrozen = false

-- New Advanced Super Powers State
local isAntiRagdoll = false
local isInfOxygen = false
local isInfStamina = false
local isExpPunch = false
local isExpAmmo = false
local isVehJump = false
local isVehDrift = false
local isVehAutoFlip = false
local isFastSwim = false

-- Dev Tools State
local isInspectorActive = false
local isCinematicHUD = false
local isSpectating = false
local spectateTarget = nil

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
                ammo = isInfiniteAmmo,
                damage = isSuperDamage,
                wanted = isNeverWanted,
                thermal = isThermalVision,
                nightvision = isNightVision,
                sprint = isSuperSprint,
                jump = isSuperJump,
                vehgod = isVehGodmode,
                vehboost = isVehBoost,
                antiragdoll = isAntiRagdoll,
                infoxygen = isInfOxygen,
                infstamina = isInfStamina,
                exppunch = isExpPunch,
                expammo = isExpAmmo,
                vehjump = isVehJump,
                vehdrift = isVehDrift,
                autoflip = isVehAutoFlip,
                fastswim = isFastSwim,
                inspector = isInspectorActive,
                hidehud = isCinematicHUD,
                blackout = GlobalState.blackout == true
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

-- Super Physical Powers Engine (Sprint, Jump, Damage, Wanted, Ammo)
CreateThread(function()
    while true do
        local sleep = 500
        local player = PlayerId()
        local ped = PlayerPedId()

        -- Super Sprint
        if isSuperSprint then
            sleep = 0
            SetRunSprintMultiplierForPlayer(player, 1.49)
            SetSwimMultiplierForPlayer(player, 1.49)
            RestorePlayerStamina(player, 1.0)
        end

        -- Super Jump
        if isSuperJump then
            sleep = 0
            SetSuperJumpThisFrame(player)
        end

        -- Infinite Ammo & No Reload
        if isInfiniteAmmo then
            sleep = 0
            local weapon = GetSelectedPedWeapon(ped)
            if weapon ~= `WEAPON_UNARMED` then
                SetPedInfiniteAmmoClip(ped, true)
                SetPedInfiniteAmmo(ped, true, weapon)
            end
        end

        -- Super Damage
        if isSuperDamage then
            SetPlayerMeleeWeaponDamageModifier(player, 1000.0)
            SetPlayerWeaponDamageModifier(player, 10.0)
        end

        -- Never Wanted
        if isNeverWanted then
            ClearPlayerWantedLevel(player)
            SetPlayerWantedLevel(player, 0, false)
            SetPlayerWantedLevelNow(player, false)
            SetPoliceIgnorePlayer(player, true)
            SetDispatchCopsForPlayer(player, false)
        end

        -- Anti-Ragdoll
        if isAntiRagdoll then
            SetPedCanRagdoll(ped, false)
            SetPedCanRagdollFromPlayerPed(ped, false)
            SetPedRagdollOnCollision(ped, false)
        end

        -- Infinite Oxygen
        if isInfOxygen then
            SetPedDiesInWater(ped, false)
            SetPedMaxTimeUnderwater(ped, 999999.0)
            SetPedDiesInSinkingVehicle(ped, false)
        end

        -- Infinite Stamina
        if isInfStamina then
            RestorePlayerStamina(player, 1.0)
            ResetPlayerStamina(player)
        end

        -- Explosive Melee
        if isExpPunch then
            sleep = 0
            SetExplosiveMeleeThisFrame(player)
        end

        -- Explosive Bullets
        if isExpAmmo then
            sleep = 0
            SetExplosiveAmmoThisFrame(player)
        end

        -- Fast Swim
        if isFastSwim then
            sleep = 0
            SetSwimMultiplierForPlayer(player, 1.49)
        end

        Wait(sleep)
    end
end)

-- Vehicle Powers Engine (God Mode, Rocket Boost, Jump, Drift, Auto-Flip)
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 then
            if isVehGodmode then
                SetEntityInvincible(veh, true)
                SetVehicleFixed(veh)
                SetVehicleDirtLevel(veh, 0.0)
                SetVehicleTyresCanBurst(veh, false)
                SetVehicleWheelsCanBreak(veh, false)
            end

            if isVehBoost and IsControlJustPressed(0, 21) then -- Left Shift
                local curSpeed = GetEntitySpeed(veh)
                SetVehicleForwardSpeed(veh, curSpeed + 20.0)
                StartScreenEffect("RaceTurbo", 400, false)
            end

            if isVehJump and IsControlJustPressed(0, 22) then -- Spacebar (Bunny Hop)
                ApplyForceToEntity(veh, 1, 0.0, 0.0, 8.5, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
            end

            if isVehDrift then
                SetVehicleReduceGrip(veh, true)
            end

            if isVehAutoFlip then
                local roll = GetEntityRoll(veh)
                if roll > 65.0 or roll < -65.0 then
                    SetVehicleOnGroundProperly(veh)
                end
            end

            Wait(0)
        else
            Wait(1000)
        end
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
-- DEV TOOLS: ENTITY INSPECTOR & RAYCAST
-- =========================================================================
local function RotationToDirection(rotation)
    local z = math.rad(rotation.z)
    local x = math.rad(rotation.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

CreateThread(function()
    while true do
        if isInspectorActive then
            local camCoords = GetGameplayCamCoord()
            local camRot = GetGameplayCamRot(2)
            local forward = RotationToDirection(camRot)
            local endCoords = camCoords + (forward * 30.0)

            local ray = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, endCoords.x, endCoords.y, endCoords.z, -1, PlayerPedId(), 0)
            local retval, hit, hitCoords, surfaceNormal, entityHit = GetShapeTestResult(ray)

            DrawLine(camCoords.x, camCoords.y, camCoords.z, hitCoords.x, hitCoords.y, hitCoords.z, 0, 229, 255, 200)

            if hit and entityHit ~= 0 and DoesEntityExist(entityHit) then
                local modelHash = GetEntityModel(entityHit)
                local entityType = "Unknown"
                if IsEntityAVehicle(entityHit) then entityType = "Vehicle"
                elseif IsEntityAPed(entityHit) then entityType = "Ped"
                elseif IsEntityAnObject(entityHit) then entityType = "Object/Prop"
                end

                local coords = GetEntityCoords(entityHit)
                local dist = #(camCoords - coords)
                local netId = NetworkGetEntityIsNetworked(entityHit) and NetworkGetNetworkIdFromEntity(entityHit) or "N/A"

                SetTextScale(0.35, 0.35)
                SetTextFont(4)
                SetTextProportional(1)
                SetTextColour(0, 229, 255, 255)
                SetTextOutline()
                SetTextEntry("STRING")
                AddTextComponentString(("[INSPECTOR] Type: %s | Hash: %d | NetID: %s\nDist: %.1fm | Coords: (%.2f, %.2f, %.2f)"):format(
                    entityType, modelHash, tostring(netId), dist, coords.x, coords.y, coords.z
                ))
                DrawText(0.4, 0.85)
            end
            Wait(0)
        else
            Wait(600)
        end
    end
end)

-- Cinematic HUD Toggle Thread
CreateThread(function()
    while true do
        if isCinematicHUD then
            DisplayRadar(false)
            DisplayHud(false)
            Wait(0)
        else
            Wait(1000)
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

-- Guaranteed Clean Close Callback
RegisterNUICallback('close', function(_, cb)
    isPanelOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "setVisible", visible = false })
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
        elseif action == 'clean_ped' then
            ClearPedBloodDamage(ped)
            ClearPedWetness(ped)
            ClearPedEnvDirt(ped)
            ResetPedVisibleDamage(ped)
            ClearPedLastDamageBone(ped)
            lib.notify({ title = SharedConfig.PanelName, description = "Corps et vêtements nettoyés (Blood & Dirt Cleared).", type = 'success' })
        elseif action == 'flip_car' then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                SetVehicleOnGroundProperly(veh)
                lib.notify({ title = SharedConfig.PanelName, description = "Véhicule remis sur ses roues.", type = 'success' })
            else
                lib.notify({ title = SharedConfig.PanelName, description = "Vous devez être dans un véhicule.", type = 'error' })
            end
        elseif action == 'fix_wash_car' then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                SetVehicleFixed(veh)
                SetVehicleDirtLevel(veh, 0.0)
                SetVehicleDeformationFixed(veh)
                SetVehicleEngineHealth(veh, 1000.0)
                lib.notify({ title = SharedConfig.PanelName, description = "Véhicule réparé et nettoyé à neuf.", type = 'success' })
            else
                lib.notify({ title = SharedConfig.PanelName, description = "Vous devez être dans un véhicule.", type = 'error' })
            end
        end
    end, action)

    cb('ok')
end)

-- Full Super Powers Toggle Callback
RegisterNUICallback('togglePower', function(data, cb)
    local ped = PlayerPedId()
    local player = PlayerId()
    local power = data.power
    local state = data.state

    if power == 'godmode' then
        isGodmode = state
        SetEntityInvincible(ped, state)
        SetPlayerInvincible(player, state)
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
    elseif power == 'ammo' then
        isInfiniteAmmo = state
        if not state then
            SetPedInfiniteAmmoClip(ped, false)
            local weapon = GetSelectedPedWeapon(ped)
            if weapon ~= `WEAPON_UNARMED` then
                SetPedInfiniteAmmo(ped, false, weapon)
            end
        end
        lib.notify({ title = SharedConfig.PanelName, description = "Infinite Ammo " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'damage' then
        isSuperDamage = state
        if not state then
            SetPlayerMeleeWeaponDamageModifier(player, 1.0)
            SetPlayerWeaponDamageModifier(player, 1.0)
        end
        lib.notify({ title = SharedConfig.PanelName, description = "One-Punch Super Damage " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'wanted' then
        isNeverWanted = state
        if not state then
            SetPoliceIgnorePlayer(player, false)
            SetDispatchCopsForPlayer(player, true)
        end
        lib.notify({ title = SharedConfig.PanelName, description = "Never Wanted " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'thermal' then
        isThermalVision = state
        SetSeethrough(state)
        lib.notify({ title = SharedConfig.PanelName, description = "Thermal Vision " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'nightvision' then
        isNightVision = state
        SetNightvision(state)
        lib.notify({ title = SharedConfig.PanelName, description = "Night Vision " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'sprint' then
        isSuperSprint = state
        if not state then
            SetRunSprintMultiplierForPlayer(player, 1.0)
            SetSwimMultiplierForPlayer(player, 1.0)
        end
        lib.notify({ title = SharedConfig.PanelName, description = "Super Sprint " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'jump' then
        isSuperJump = state
        lib.notify({ title = SharedConfig.PanelName, description = "Super Jump " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'vehgod' then
        isVehGodmode = state
        lib.notify({ title = SharedConfig.PanelName, description = "Vehicle God Mode " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'vehboost' then
        isVehBoost = state
        lib.notify({ title = SharedConfig.PanelName, description = "Vehicle Rocket Boost " .. (state and "ENABLED (Press Left Shift in car)" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'inspector' then
        isInspectorActive = state
        lib.notify({ title = SharedConfig.PanelName, description = "Entity Inspector " .. (state and "ACTIVE" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'hidehud' then
        isCinematicHUD = state
        if not state then
            DisplayRadar(true)
            DisplayHud(true)
        end
        lib.notify({ title = SharedConfig.PanelName, description = "Cinematic HUD " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'blackout' then
        lib.callback('souh4il_dev:server:setBlackout', false, function() end, state)
    elseif power == 'antiragdoll' then
        isAntiRagdoll = state
        if not state then
            SetPedCanRagdoll(ped, true)
            SetPedCanRagdollFromPlayerPed(ped, true)
            SetPedRagdollOnCollision(ped, true)
        end
        lib.notify({ title = SharedConfig.PanelName, description = "Anti-Ragdoll " .. (state and "ENABLED (Unknockable)" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'infoxygen' then
        isInfOxygen = state
        if not state then
            SetPedDiesInWater(ped, true)
            SetPedMaxTimeUnderwater(ped, 15.0)
        end
        lib.notify({ title = SharedConfig.PanelName, description = "Infinite Oxygen " .. (state and "ENABLED (Scuba Diver)" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'infstamina' then
        isInfStamina = state
        lib.notify({ title = SharedConfig.PanelName, description = "Infinite Stamina " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'exppunch' then
        isExpPunch = state
        lib.notify({ title = SharedConfig.PanelName, description = "Explosive Punch " .. (state and "ENABLED (Super Blast)" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'expammo' then
        isExpAmmo = state
        lib.notify({ title = SharedConfig.PanelName, description = "Explosive Bullets " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'vehjump' then
        isVehJump = state
        lib.notify({ title = SharedConfig.PanelName, description = "Vehicle Bunny Hop " .. (state and "ENABLED (Press Spacebar in car)" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'vehdrift' then
        isVehDrift = state
        local currentVeh = GetVehiclePedIsIn(ped, false)
        if not state and currentVeh ~= 0 then
            SetVehicleReduceGrip(currentVeh, false)
        end
        lib.notify({ title = SharedConfig.PanelName, description = "Vehicle Drift Mode " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'autoflip' then
        isVehAutoFlip = state
        lib.notify({ title = SharedConfig.PanelName, description = "Auto-Right (Anti-Flip) " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'fastswim' then
        isFastSwim = state
        if not state then
            SetSwimMultiplierForPlayer(player, 1.0)
        end
        lib.notify({ title = SharedConfig.PanelName, description = "Fast Swim " .. (state and "ENABLED (Dolphin Speed)" or "DISABLED"), type = state and 'success' or 'inform' })
    end

    cb('ok')
end)

-- Developer Tools: Coords
local function FormatCoords(formatType)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    if formatType == 'vec3' then
        return ("vector3(%.2f, %.2f, %.2f)"):format(coords.x, coords.y, coords.z)
    elseif formatType == 'vec4' then
        return ("vector4(%.2f, %.2f, %.2f, %.2f)"):format(coords.x, coords.y, coords.z, heading)
    elseif formatType == 'heading' then
        return ("%.2f"):format(heading)
    end
    return ("%.2f, %.2f, %.2f"):format(coords.x, coords.y, coords.z)
end

RegisterNUICallback('copyCoords', function(data, cb)
    local text = FormatCoords(data.format)
    lib.setClipboard(text)
    print(("[SOUH4IL-DEV COORDS] %s"):format(text))
    lib.notify({ title = SharedConfig.PanelName, description = "Copied to clipboard: " .. text, type = 'success' })
    SendNUIMessage({ action = "updateCoordsDisplay", text = text })
    cb('ok')
end)

RegisterNUICallback('requestCoordsDisplay', function(_, cb)
    local text = FormatCoords('vec4')
    SendNUIMessage({ action = "updateCoordsDisplay", text = text })
    cb('ok')
end)

-- Developer Tools: Clear Area
RegisterNUICallback('clearArea', function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local radius = 50.0
    local pType = data.type

    if pType == 'vehicles' or pType == 'all' then
        local vehs = GetGamePool('CVehicle')
        local myVeh = GetVehiclePedIsIn(ped, false)
        for _, veh in ipairs(vehs) do
            if veh ~= myVeh and #(coords - GetEntityCoords(veh)) <= radius then
                SetEntityAsMissionEntity(veh, true, true)
                DeleteVehicle(veh)
            end
        end
    end

    if pType == 'peds' or pType == 'all' then
        local peds = GetGamePool('CPed')
        for _, p in ipairs(peds) do
            if p ~= ped and not IsPedAPlayer(p) and #(coords - GetEntityCoords(p)) <= radius then
                SetEntityAsMissionEntity(p, true, true)
                DeletePed(p)
            end
        end
    end

    if pType == 'props' or pType == 'all' then
        local objs = GetGamePool('CObject')
        for _, obj in ipairs(objs) do
            if #(coords - GetEntityCoords(obj)) <= radius then
                SetEntityAsMissionEntity(obj, true, true)
                DeleteObject(obj)
            end
        end
    end

    lib.notify({ title = SharedConfig.PanelName, description = ("Area cleared (Radius: 50m, Type: %s)"):format(pType:upper()), type = 'success' })
    cb('ok')
end)

-- Developer Tools: Ped Model Changer
RegisterNUICallback('setPedModel', function(data, cb)
    local modelName = data.model
    local hash = joaat(modelName)

    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        lib.notify({ title = SharedConfig.PanelName, description = "Invalid skin model: " .. modelName, type = 'error' })
        cb('ok')
        return
    end

    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(50)
    end

    SetPlayerModel(PlayerId(), hash)
    SetPedDefaultComponentVariation(PlayerPedId())
    SetModelAsNoLongerNeeded(hash)
    lib.notify({ title = SharedConfig.PanelName, description = "Skin changed to: " .. modelName, type = 'success' })
    cb('ok')
end)

-- Vehicle Workshop Additions
RegisterNUICallback('setVehiclePlate', function(data, cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        local netId = NetworkGetNetworkIdFromEntity(veh)
        lib.callback('souh4il_dev:server:setVehiclePlate', false, function(res)
            if res and res.success then
                SetVehicleNumberPlateText(veh, res.plate)
                lib.notify({ title = SharedConfig.PanelName, description = "License plate set to: " .. res.plate, type = 'success' })
            else
                lib.notify({ title = SharedConfig.PanelName, description = "Failed to set plate", type = 'error' })
            end
        end, netId, data.plate)
    else
        lib.notify({ title = SharedConfig.PanelName, description = "Must be inside a vehicle.", type = 'error' })
    end
    cb('ok')
end)

RegisterNUICallback('flipVehicle', function(_, cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        local coords = GetEntityCoords(veh)
        SetEntityCoords(veh, coords.x, coords.y, coords.z + 1.0, false, false, false, false)
        SetVehicleOnGroundProperly(veh)
        lib.notify({ title = SharedConfig.PanelName, description = "Vehicle flipped upright.", type = 'success' })
    else
        lib.notify({ title = SharedConfig.PanelName, description = "Must be inside a vehicle.", type = 'error' })
    end
    cb('ok')
end)

RegisterNUICallback('toggleDoors', function(data, cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        local d = data.door
        if d == 'all' then
            for i = 0, 5 do
                if GetVehicleDoorAngleRatio(veh, i) > 0.0 then
                    SetVehicleDoorShut(veh, i, false)
                else
                    SetVehicleDoorOpen(veh, i, false, false)
                end
            end
        elseif d == 'hood' then
            if GetVehicleDoorAngleRatio(veh, 4) > 0.0 then SetVehicleDoorShut(veh, 4, false) else SetVehicleDoorOpen(veh, 4, false, false) end
        elseif d == 'trunk' then
            if GetVehicleDoorAngleRatio(veh, 5) > 0.0 then SetVehicleDoorShut(veh, 5, false) else SetVehicleDoorOpen(veh, 5, false, false) end
        end
    end
    cb('ok')
end)

RegisterNUICallback('setVehicleColor', function(data, cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and data.color then
        SetVehicleColours(veh, data.color, data.color)
        lib.notify({ title = SharedConfig.PanelName, description = "Vehicle color applied.", type = 'success' })
    else
        lib.notify({ title = SharedConfig.PanelName, description = "Must be inside a vehicle.", type = 'error' })
    end
    cb('ok')
end)

-- World Time & Announcements
RegisterNUICallback('setTime', function(data, cb)
    lib.callback('souh4il_dev:server:setTime', false, function() end, data.hour, data.minute)
    NetworkOverrideClockTime(data.hour, data.minute, 0)
    lib.notify({ title = SharedConfig.PanelName, description = ("Time set to %02d:%02d"):format(data.hour, data.minute), type = 'success' })
    cb('ok')
end)

RegisterNUICallback('broadcastAnnouncement', function(data, cb)
    lib.callback('souh4il_dev:server:broadcastAnnouncement', false, function(res)
        if res and res.success then
            lib.notify({ title = SharedConfig.PanelName, description = "Announcement broadcasted to server.", type = 'success' })
        end
    end, data.message)
    cb('ok')
end)

-- Player Management: Set Job
RegisterNUICallback('setPlayerJob', function(data, cb)
    lib.callback('souh4il_dev:server:setPlayerJob', false, function(response)
        if response and response.success then
            lib.notify({ title = SharedConfig.PanelName, description = "Player job & grade updated.", type = 'success' })
            lib.callback('souh4il_dev:server:getOnlinePlayers', false, function(res)
                if res and res.success then SendNUIMessage({ action = "updatePlayers", players = res.players }) end
            end)
        else
            lib.notify({ title = SharedConfig.PanelName, description = response and response.error or "Failed", type = 'error' })
        end
    end, data)
    cb('ok')
end)

-- Player Management: Clear Inventory
RegisterNUICallback('clearPlayerInventory', function(data, cb)
    lib.callback('souh4il_dev:server:clearPlayerInventory', false, function(response)
        if response and response.success then
            lib.notify({ title = SharedConfig.PanelName, description = "Target inventory wiped.", type = 'success' })
        else
            lib.notify({ title = SharedConfig.PanelName, description = response and response.error or "Failed", type = 'error' })
        end
    end, data.targetId)
    cb('ok')
end)

-- Player Management: Spectate
RegisterNUICallback('spectatePlayer', function(data, cb)
    local targetId = tonumber(data.targetId)
    local myPed = PlayerPedId()

    if isSpectating then
            NetworkSetInSpectatorMode(false, myPed)
            isSpectating = false
            spectateTarget = nil
            lib.notify({ title = SharedConfig.PanelName, description = "Spectate mode disabled.", type = 'inform' })
        else
            local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
            if DoesEntityExist(targetPed) then
                NetworkSetInSpectatorMode(true, targetPed)
                isSpectating = true
                spectateTarget = targetId
                lib.notify({ title = SharedConfig.PanelName, description = "Spectating player #" .. targetId, type = 'success' })
            else
                lib.notify({ title = SharedConfig.PanelName, description = "Target ped is not within streaming distance.", type = 'error' })
            end
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
            lib.callback('souh4il_dev:server:getOnlinePlayers', false, function(res)
                if res and res.success then SendNUIMessage({ action = "updatePlayers", players = res.players }) end
            end)
        else
            lib.notify({ title = SharedConfig.PanelName, description = response and response.error or "Ban failed", type = 'error' })
        end
    end, data)
    cb('ok')
end)

-- Items: Give Custom Item / Visual Item
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

-- Fetch All Server Items (ox_inventory Dynamic Catalog)
RegisterNUICallback('fetchAllItems', function(_, cb)
    lib.callback('souh4il_dev:server:getAllGameItems', false, function(response)
        if response and response.success then
            SendNUIMessage({ action = "updateAllItems", items = response.items })
        end
    end)
    cb('ok')
end)

-- Fetch All Server Vehicles (Qbox Dynamic Catalog)
RegisterNUICallback('fetchAllVehicles', function(_, cb)
    lib.callback('souh4il_dev:server:getAllGameVehicles', false, function(response)
        if response and response.success then
            SendNUIMessage({ action = "updateAllVehicles", vehicles = response.vehicles })
        end
    end)
    cb('ok')
end)

-- Fetch All Server Characters / Peds (illenium-appearance Dynamic Catalog)
RegisterNUICallback('fetchAllCharacters', function(_, cb)
    lib.callback('souh4il_dev:server:getAllGameCharacters', false, function(response)
        if response and response.success then
            SendNUIMessage({ action = "updateAllCharacters", characters = response.characters })
        end
    end)
    cb('ok')
end)

-- Fetch All Server Jobs (Qbox Dynamic Catalog)
RegisterNUICallback('fetchAllJobs', function(_, cb)
    lib.callback('souh4il_dev:server:getAllGameJobs', false, function(response)
        if response and response.success then
            SendNUIMessage({ action = "updateAllJobs", jobs = response.jobs })
        end
    end)
    cb('ok')
end)

-- Set Caller Job Direct
RegisterNUICallback('setMyJob', function(data, cb)
    lib.callback('souh4il_dev:server:setMyJob', false, function(response)
        if response and response.success then
            lib.notify({ title = SharedConfig.PanelName, description = ("Job set to %s (Grade: %d)"):format(data.job:upper(), data.grade), type = 'success' })
        else
            lib.notify({ title = SharedConfig.PanelName, description = response and response.error or "Failed", type = 'error' })
        end
    end, data)
    cb('ok')
end)

-- Equip Owner Arsenal Preset Loadout
RegisterNUICallback('equipLoadout', function(data, cb)
    lib.callback('souh4il_dev:server:giveArsenalLoadout', false, function(response)
        if response and response.success then
            lib.notify({ title = SharedConfig.PanelName, description = ("Equipped '%s' Loadout."):format(data.loadout:upper()), type = 'success' })
        else
            lib.notify({ title = SharedConfig.PanelName, description = response and response.error or "Failed", type = 'error' })
        end
    end, data.loadout)
    cb('ok')
end)

-- World Density Multiplier
local currentWorldDensity = 1.0
RegisterNUICallback('setTrafficDensity', function(data, cb)
    local density = tonumber(data.density) or 1.0
    lib.callback('souh4il_dev:server:setTrafficDensity', false, function(res)
        if res and res.success then
            currentWorldDensity = density
            lib.notify({ title = SharedConfig.PanelName, description = ("Traffic & Ped Density set to %.0f%%"):format(density * 100), type = 'success' })
        end
    end, density)
    cb('ok')
end)

RegisterNetEvent('souh4il_dev:client:syncDensity', function(val)
    currentWorldDensity = tonumber(val) or 1.0
end)

CreateThread(function()
    while true do
        if currentWorldDensity ~= 1.0 then
            SetVehicleDensityMultiplierThisFrame(currentWorldDensity)
            SetPedDensityMultiplierThisFrame(currentWorldDensity)
            SetRandomVehicleDensityMultiplierThisFrame(currentWorldDensity)
            SetParkedVehicleDensityMultiplierThisFrame(currentWorldDensity)
            SetScenarioPedDensityMultiplierThisFrame(currentWorldDensity, currentWorldDensity)
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

-- Weather Set
RegisterNUICallback('setWeather', function(data, cb)
    TriggerServerEvent('souh4il_dev:server:setWeather', data.weather)
    cb('ok')
end)

-- Client Event Listeners for World Sync
RegisterNetEvent('souh4il_dev:client:syncTime', function(h, m)
    NetworkOverrideClockTime(h, m, 0)
end)

RegisterNetEvent('souh4il_dev:client:syncBlackout', function(state)
    SetBlackout(state)
end)

-- =========================================================================
-- EXPANDED OWNER CHEATS & ADMIN SUITE (ALL REQUESTED FEATURES)
-- =========================================================================
local isAdminTag = false
local isPlayerNames = false
local isPlayerBlips = false
local isMinimapOnFoot = false
local isCoordsHUD = false
local playerBlips = {}

local function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.32, 0.32)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 230)
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Admin Tag Thread
CreateThread(function()
    while true do
        if isAdminTag then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            Draw3DText(coords.x, coords.y, coords.z + 1.15, "~r~[OWNER / ADMIN]~w~\n~y~SOUH4IL~w~")
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

-- Overhead Names Thread
CreateThread(function()
    while true do
        if isPlayerNames then
            local myPed = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)
            for _, player in ipairs(GetActivePlayers()) do
                local ped = GetPlayerPed(player)
                if ped ~= myPed and DoesEntityExist(ped) then
                    local coords = GetEntityCoords(ped)
                    local dist = #(myCoords - coords)
                    if dist <= 120.0 then
                        local sId = GetPlayerServerId(player)
                        local name = GetPlayerName(player)
                        local hp = GetEntityHealth(ped)
                        local arm = GetPedArmour(ped)
                        local text = ("~y~[%d] %s~w~\nHP: ~g~%d~w~ | ARM: ~b~%d~w~ | ~s~%.0fm"):format(sId, name, hp, arm, dist)
                        Draw3DText(coords.x, coords.y, coords.z + 1.05, text)
                    end
                end
            end
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

-- Player Blips Thread
CreateThread(function()
    while true do
        if isPlayerBlips then
            local myServerId = GetPlayerServerId(PlayerId())
            for _, player in ipairs(GetActivePlayers()) do
                local sId = GetPlayerServerId(player)
                if sId ~= myServerId then
                    local ped = GetPlayerPed(player)
                    if DoesEntityExist(ped) then
                        if not playerBlips[sId] or not DoesBlipExist(playerBlips[sId]) then
                            local blip = AddBlipForEntity(ped)
                            SetBlipSprite(blip, 1)
                            SetBlipColour(blip, 0)
                            SetBlipScale(blip, 0.75)
                            BeginTextCommandSetBlipName("STRING")
                            AddTextComponentString(("Player [%d] %s"):format(sId, GetPlayerName(player)))
                            EndTextCommandSetBlipName(blip)
                            playerBlips[sId] = blip
                        end
                    end
                end
            end
            Wait(2000)
        else
            if next(playerBlips) then
                for sId, blip in pairs(playerBlips) do
                    if DoesBlipExist(blip) then RemoveBlip(blip) end
                end
                playerBlips = {}
            end
            Wait(1000)
        end
    end
end)

-- Minimap on Foot Thread
CreateThread(function()
    while true do
        if isMinimapOnFoot and not isCinematicHUD then
            DisplayRadar(true)
            Wait(250)
        else
            Wait(1000)
        end
    end
end)

-- Live Coordinates HUD Thread
CreateThread(function()
    while true do
        if isCoordsHUD then
            local ped = PlayerPedId()
            local c = GetEntityCoords(ped)
            local h = GetEntityHeading(ped)
            SetTextScale(0.35, 0.35)
            SetTextFont(4)
            SetTextColour(0, 255, 204, 255)
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString(("~y~X:~w~ %.2f  ~y~Y:~w~ %.2f  ~y~Z:~w~ %.2f  ~y~H:~w~ %.2f"):format(c.x, c.y, c.z, h))
            DrawText(0.015, 0.015)
            Wait(0)
        else
            Wait(800)
        end
    end
end)

-- Infinite Ammo Thread
CreateThread(function()
    while true do
        if isInfiniteAmmo then
            local ped = PlayerPedId()
            local weapon = GetSelectedPedWeapon(ped)
            if weapon ~= `WEAPON_UNARMED` then
                SetPedInfiniteAmmo(ped, true, weapon)
                SetPedInfiniteAmmoClip(ped, true)
                SetAmmoInClip(ped, weapon, 999)
            end
            Wait(250)
        else
            Wait(1000)
        end
    end
end)

-- Client Event Listeners for Heal, Warn, Troll
RegisterNetEvent('souh4il_dev:client:receiveHeal', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ClearPedLastWeaponDamage(ped)
    lib.notify({ title = SharedConfig.PanelName, description = "You have been revived & fully healed by staff.", type = 'success' })
end)

RegisterNetEvent('souh4il_dev:client:receiveWarn', function(reason)
    PlaySoundFrontend(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 1)
    lib.alertDialog({
        header = '⚠️ OFFICIAL STAFF WARNING',
        content = reason,
        centered = true,
        cancel = false
    })
end)

RegisterNetEvent('souh4il_dev:client:receiveTroll', function(trollType)
    local ped = PlayerPedId()
    if trollType == 'slap' then
        SetEntityVelocity(ped, 0.0, 0.0, 45.0)
        PlaySoundFrontend(-1, "Bed", "WastedSounds", 1)
    elseif trollType == 'fire' then
        StartEntityFire(ped)
    elseif trollType == 'jailbox' then
        DoScreenFadeOut(200)
        Wait(250)
        SetEntityCoords(ped, 1792.5, 2483.2, -122.5, false, false, false, false)
        Wait(200)
        DoScreenFadeIn(200)
    elseif trollType == 'drunk' then
        RequestAnimSet("move_m@drunk@verydrunk")
        while not HasAnimSetLoaded("move_m@drunk@verydrunk") do Wait(10) end
        SetPedMovementClipset(ped, "move_m@drunk@verydrunk", 1.0)
        ShakeGameplayCam("DRUNK_SHAKE", 2.0)
        SetPedIsDrunk(ped, true)
        Wait(15000)
        ResetPedMovementClipset(ped, 0.0)
        StopGameplayCamShaking(true)
        SetPedIsDrunk(ped, false)
    elseif trollType == 'pee' then
        lib.playAnim(ped, 'misscarsteal2peeing', 'peeing_loop', 8.0, -8.0, 6000, 1, 0, false, false, false)
    elseif trollType == 'poop' then
        lib.playAnim(ped, 'missfbi3_party', 'stand_talk_loop_a_male1', 8.0, -8.0, 6000, 1, 0, false, false, false)
    elseif trollType == 'sound' then
        PlaySoundFrontend(-1, "Bed", "WastedSounds", 1)
    elseif trollType == 'damage_veh' then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 then
            SetVehicleEngineHealth(veh, 0.0)
            SetVehicleUndriveable(veh, true)
            for i = 0, 7 do SetVehicleTyreBurst(veh, i, true, 1000.0) end
        end
    end
end)

-- Extended Toggle Power Callback
RegisterNUICallback('toggleExtendedPower', function(data, cb)
    local power = data.power
    local state = data.state

    if power == 'admintag' then
        isAdminTag = state
        lib.notify({ title = SharedConfig.PanelName, description = "Admin Overhead Tag " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'names' then
        isPlayerNames = state
        lib.notify({ title = SharedConfig.PanelName, description = "Player Names & Distance " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'blips' then
        isPlayerBlips = state
        lib.notify({ title = SharedConfig.PanelName, description = "Map Player Blips " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'minimap' then
        isMinimapOnFoot = state
        lib.notify({ title = SharedConfig.PanelName, description = "Minimap on Foot " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'coordshud' then
        isCoordsHUD = state
        lib.notify({ title = SharedConfig.PanelName, description = "Live Coordinates HUD " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'infammo' then
        isInfiniteAmmo = state
        lib.notify({ title = SharedConfig.PanelName, description = "Infinite Ammo " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    elseif power == 'noclip2' then
        isNoclip = state
        speedIndex = state and 5 or 2
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        local entity = veh ~= 0 and veh or ped
        if not state then
            SetEntityCollision(entity, true, true)
            FreezeEntityPosition(entity, false)
        end
        lib.notify({ title = SharedConfig.PanelName, description = "Fast NoClip 2 (5x) " .. (state and "ENABLED" or "DISABLED"), type = state and 'success' or 'inform' })
    end
    cb('ok')
end)

-- General Client Action Execution
RegisterNUICallback('clientAction', function(data, cb)
    local action = data.action
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    if action == 'clothes' then
        TriggerEvent('qb-clothing:client:openMenu')
        TriggerEvent('illenium-appearance:client:openClothingShopMenu')
        TriggerEvent('fivem-appearance:client:openClothingShopMenu')
        lib.notify({ title = SharedConfig.PanelName, description = "Clothing & Appearance menu requested.", type = 'inform' })
    elseif action == 'bennys' then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 then
            ApplyMaxTune(veh)
            lib.notify({ title = SharedConfig.PanelName, description = "Max Benny's Tuning & Armor applied!", type = 'success' })
        else
            lib.notify({ title = SharedConfig.PanelName, description = "You must be inside a vehicle.", type = 'error' })
        end
    elseif action == 'refuel' then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 then
            SetVehicleFuelLevel(veh, 100.0)
            DecorSetFloat(veh, "_FUEL_LEVEL", 100.0)
            if exports['LegacyFuel'] then exports['LegacyFuel']:SetFuel(veh, 100.0) end
            lib.notify({ title = SharedConfig.PanelName, description = "Vehicle tank refueled to 100%.", type = 'success' })
        else
            lib.notify({ title = SharedConfig.PanelName, description = "You must be inside a vehicle.", type = 'error' })
        end
    elseif action == 'clear_veh' then
        ClearAreaOfVehicles(coords.x, coords.y, coords.z, 100.0, false, false, false, false, false)
        lib.notify({ title = SharedConfig.PanelName, description = "Cleared all unoccupied vehicles in 100m radius.", type = 'success' })
    elseif action == 'clear_peds' then
        ClearAreaOfPeds(coords.x, coords.y, coords.z, 100.0, 1)
        lib.notify({ title = SharedConfig.PanelName, description = "Cleared all NPCs in 100m radius.", type = 'success' })
    elseif action == 'clear_props' then
        ClearAreaOfObjects(coords.x, coords.y, coords.z, 100.0, 0)
        lib.notify({ title = SharedConfig.PanelName, description = "Cleared all loose props in 100m radius.", type = 'success' })
    elseif action == 'duty' then
        lib.callback('souh4il_dev:server:toggleDuty', false, function(res)
            if res and res.success then
                lib.notify({ title = SharedConfig.PanelName, description = "Duty status toggled.", type = 'success' })
            end
        end)
    elseif action == 'stress' then
        lib.callback('souh4il_dev:server:removeStress', false, function()
            lib.notify({ title = SharedConfig.PanelName, description = "Stress fully removed.", type = 'success' })
        end)
    elseif action == 'revive_all' then
        lib.callback('souh4il_dev:server:reviveAll', false, function(res)
            if res and res.success then
                lib.notify({ title = SharedConfig.PanelName, description = ("Revived %d players."):format(res.count), type = 'success' })
            end
        end)
    elseif action == 'revive_radius' then
        lib.callback('souh4il_dev:server:reviveInRadius', false, function(res)
            if res and res.success then
                lib.notify({ title = SharedConfig.PanelName, description = ("Revived %d nearby players."):format(res.count), type = 'success' })
            end
        end, 50.0)
    elseif action == 'veh_lock' or action == 'veh_unlock' or action == 'veh_engine' or action == 'veh_freeze' then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 then
            if action == 'veh_lock' then SetVehicleDoorsLocked(veh, 2)
            elseif action == 'veh_unlock' then SetVehicleDoorsLocked(veh, 1)
            elseif action == 'veh_engine' then SetVehicleEngineOn(veh, not GetIsVehicleEngineRunning(veh), true, true)
            elseif action == 'veh_freeze' then FreezeEntityPosition(veh, not IsEntityPositionFrozen(veh))
            end
            lib.notify({ title = SharedConfig.PanelName, description = "Vehicle state updated.", type = 'success' })
        else
            lib.notify({ title = SharedConfig.PanelName, description = "Must be inside a vehicle.", type = 'error' })
        end
    elseif action == 'spawn_prop' and data.prop then
        local propHash = joaat(data.prop)
        RequestModel(propHash)
        local t = 0
        while not HasModelLoaded(propHash) and t < 50 do Wait(50); t = t + 1 end
        if HasModelLoaded(propHash) then
            local p = CreateObject(propHash, coords.x + 1.0, coords.y, coords.z, true, true, false)
            PlaceObjectOnGroundProperly(p)
            lib.notify({ title = SharedConfig.PanelName, description = "Prop spawned successfully.", type = 'success' })
        else
            lib.notify({ title = SharedConfig.PanelName, description = "Invalid prop model.", type = 'error' })
        end
    end
    cb('ok')
end)

-- Player Detailed Action Handler
RegisterNUICallback('playerDetailedAction', function(data, cb)
    local action = data.action
    local tId = tonumber(data.targetId)

    if action == 'heal' then
        lib.callback('souh4il_dev:server:healPlayer', false, function(res)
            lib.notify({ title = SharedConfig.PanelName, description = res and res.success and "Player healed & revived." or "Failed", type = res and res.success and 'success' or 'error' })
        end, tId)
    elseif action == 'give_keys' then
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        local plate = veh ~= 0 and GetVehicleNumberPlateText(veh) or "CHICAGO"
        lib.callback('souh4il_dev:server:giveKeysToPlayer', false, function()
            lib.notify({ title = SharedConfig.PanelName, description = "Keys granted to player.", type = 'success' })
        end, { targetId = tId, plate = plate })
    elseif action == 'set_gang' then
        lib.callback('souh4il_dev:server:setPlayerGang', false, function(res)
            lib.notify({ title = SharedConfig.PanelName, description = res and res.success and "Player gang updated." or "Failed", type = res and res.success and 'success' or 'error' })
        end, { targetId = tId, gang = data.gang, grade = data.grade })
    elseif action == 'give_perm' or action == 'remove_perm' then
        lib.callback('souh4il_dev:server:managePermission', false, function(res)
            lib.notify({ title = SharedConfig.PanelName, description = res and res.success and "Permissions updated." or "Failed", type = res and res.success and 'success' or 'error' })
        end, { targetId = tId, role = data.role or 'admin', action = action == 'give_perm' and 'add' or 'remove' })
    elseif action == 'open_inv' then
        lib.callback('souh4il_dev:server:openInventory', false, function() end, { type = 'player', target = tId })
    elseif action == 'open_trunk' or action == 'open_glovebox' then
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        local plate = veh ~= 0 and GetVehicleNumberPlateText(veh) or "CHICAGO"
        lib.callback('souh4il_dev:server:openInventory', false, function() end, { type = action == 'open_trunk' and 'trunk' or 'glovebox', target = plate })
    elseif action == 'warn' then
        lib.callback('souh4il_dev:server:warnPlayer', false, function(res)
            lib.notify({ title = SharedConfig.PanelName, description = "Warning issued to player.", type = 'success' })
        end, { targetId = tId, reason = data.reason })
    elseif action == 'force_logout' then
        lib.callback('souh4il_dev:server:forceLogout', false, function(res)
            lib.notify({ title = SharedConfig.PanelName, description = "Player forced to logout.", type = 'inform' })
        end, tId)
    elseif action == 'message' then
        lib.callback('souh4il_dev:server:messagePlayer', false, function()
            lib.notify({ title = SharedConfig.PanelName, description = "Staff message dispatched.", type = 'success' })
        end, { targetId = tId, message = data.message })
    elseif action == 'troll' then
        lib.callback('souh4il_dev:server:trollPlayer', false, function()
            lib.notify({ title = SharedConfig.PanelName, description = ("Troll action '%s' sent."):format(data.trollType), type = 'inform' })
        end, { targetId = tId, type = data.trollType })
    elseif action == 'wipe' then
        lib.callback('souh4il_dev:server:wipePlayer', false, function(res)
            lib.notify({ title = SharedConfig.PanelName, description = "Player wipe completed.", type = 'success' })
        end, { targetId = tId, type = data.wipeType })
    elseif action == 'get_details' then
        lib.callback('souh4il_dev:server:getPlayerDetails', false, function(res)
            if res and res.success then
                SendNUIMessage({ action = "showPlayerDetails", details = res.details })
            end
        end, tId)
    end
    cb('ok')
end)

-- Staff & Permissions Management NUI Callbacks
RegisterNUICallback('getStaffData', function(_, cb)
    lib.callback('souh4il_dev:server:getStaffData', false, function(res)
        cb(res or { success = false })
    end)
end)

RegisterNUICallback('saveStaffMember', function(data, cb)
    lib.callback('souh4il_dev:server:saveStaffMember', false, function(res)
        cb(res or { success = false })
    end, data)
end)

RegisterNUICallback('removeStaffMember', function(data, cb)
    lib.callback('souh4il_dev:server:removeStaffMember', false, function(res)
        cb(res or { success = false })
    end, data)
end)

-- Network Events for Staff Management
RegisterNetEvent('souh4il_dev:client:refreshPermissions', function()
    if isPanelOpen then
        lib.callback('souh4il_dev:server:getSecurityStatus', false, function(response)
            if response and response.success then
                SendNUIMessage({
                    action = "updatePermissions",
                    status = response,
                })
            end
        end)
    end
end)

RegisterNetEvent('souh4il_dev:client:forceClosePanel', function()
    if isPanelOpen then
        isPanelOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "setVisible", visible = false })
    end
end)

-- Event Manager Client Blips & Waypoint
local currentEventBlip = nil
local currentEventRadiusBlip = nil

RegisterNetEvent('souh4il_dev:client:syncEvent', function(eventData)
    if currentEventBlip and DoesBlipExist(currentEventBlip) then
        RemoveBlip(currentEventBlip)
        currentEventBlip = nil
    end
    if currentEventRadiusBlip and DoesBlipExist(currentEventRadiusBlip) then
        RemoveBlip(currentEventRadiusBlip)
        currentEventRadiusBlip = nil
    end

    if not eventData or not eventData.coords then
        return
    end

    local cx = tonumber(eventData.coords.x) or 0.0
    local cy = tonumber(eventData.coords.y) or 0.0
    local cz = tonumber(eventData.coords.z) or 0.0

    currentEventBlip = AddBlipForCoord(cx, cy, cz)
    SetBlipSprite(currentEventBlip, tonumber(eventData.blipSprite) or 38)
    SetBlipDisplay(currentEventBlip, 4)
    SetBlipScale(currentEventBlip, 1.2)
    SetBlipColour(currentEventBlip, tonumber(eventData.blipColor) or 1)
    SetBlipAsShortRange(currentEventBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("EVENT: " .. (eventData.title or "Chicago Event"))
    EndTextCommandSetBlipName(currentEventBlip)

    if eventData.radius and tonumber(eventData.radius) > 0 then
        currentEventRadiusBlip = AddBlipForRadius(cx, cy, cz, tonumber(eventData.radius) * 1.0)
        SetBlipColour(currentEventRadiusBlip, tonumber(eventData.blipColor) or 1)
        SetBlipAlpha(currentEventRadiusBlip, 90)
    end

    SetNewWaypoint(cx, cy)
end)

-- Event Manager NUI Callbacks
RegisterNUICallback('startEvent', function(data, cb)
    if not data.coords then
        local ped = PlayerPedId()
        local c = GetEntityCoords(ped)
        data.coords = { x = c.x, y = c.y, z = c.z }
    end
    lib.callback('souh4il_dev:server:startEvent', false, function(res)
        cb(res or { success = false })
    end, data)
end)

RegisterNUICallback('stopEvent', function(_, cb)
    lib.callback('souh4il_dev:server:stopEvent', false, function(res)
        cb(res or { success = false })
    end)
end)

RegisterNUICallback('getEventState', function(_, cb)
    lib.callback('souh4il_dev:server:getEventState', false, function(res)
        cb(res or { success = false })
    end)
end)

-- Clean Cleanup on Stop
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
    if isThermalVision then SetSeethrough(false) end
    if isNightVision then SetNightvision(false) end
    if isCinematicHUD then
        DisplayRadar(true)
        DisplayHud(true)
    end
    if isSpectating then
        NetworkSetInSpectatorMode(false, PlayerPedId())
    end
end)
