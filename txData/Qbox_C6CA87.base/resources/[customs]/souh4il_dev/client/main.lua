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
    ['pdm']      = vector4(-56.79, -1096.55, 26.42, 25.0),
    ['bennys']   = vector4(-211.55, -1324.55, 30.89, 180.0),
    ['prison']   = vector4(1845.91, 2585.87, 45.67, 90.0),
    ['lsia']     = vector4(-1037.51, -2737.61, 20.17, 330.0),
    ['grove']    = vector4(105.78, -1940.21, 20.8, 50.0),
    ['cayo']     = vector4(4440.12, -4482.55, 4.22, 200.0),
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

    -- 1. Try local client spawn if model is in CD image
    if IsModelInCdimage(hash) and IsModelAVehicle(hash) then
        RequestModel(hash)
        local timeout = 0
        while not HasModelLoaded(hash) and timeout < 80 do
            Wait(50)
            timeout = timeout + 1
        end

        if HasModelLoaded(hash) then
            -- Delete current vehicle if sitting inside
            local currentVeh = GetVehiclePedIsIn(ped, false)
            if currentVeh and currentVeh ~= 0 then
                SetEntityAsMissionEntity(currentVeh, true, true)
                DeleteVehicle(currentVeh)
            end

            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)

            local waitCount = 0
            while not DoesEntityExist(veh) and waitCount < 40 do
                Wait(25)
                waitCount = waitCount + 1
            end

            if DoesEntityExist(veh) then
                SetPedIntoVehicle(ped, veh, -1)
                SetVehicleEngineOn(veh, true, true, false)
                SetModelAsNoLongerNeeded(hash)

                local netId = NetworkGetNetworkIdFromEntity(veh)
                SetNetworkIdExistsOnAllMachines(netId, true)

                lib.callback('souh4il_dev:server:giveVehicleKeys', false, function() end, netId)

                if maxTune then
                    ApplyMaxTune(veh)
                end

                lib.notify({ title = SharedConfig.PanelName, description = ("Vehicle '%s' spawned."):format(modelName), type = 'success' })
                return
            end
        end
    end

    -- 2. Fallback to server-side spawn (Guaranteed for custom add-ons & server-setter)
    lib.callback('souh4il_dev:server:spawnVehicleDirect', false, function(res)
        if res and res.success then
            if maxTune and res.netId then
                Wait(300)
                local ent = NetworkGetEntityFromNetworkId(res.netId)
                if DoesEntityExist(ent) then ApplyMaxTune(ent) end
            end
            lib.notify({ title = SharedConfig.PanelName, description = ("Vehicle '%s' spawned."):format(modelName), type = 'success' })
        else
            lib.notify({ title = SharedConfig.PanelName, description = "Failed to spawn: " .. (res and res.error or modelName), type = 'error' })
        end
    end, { model = modelName, maxTune = maxTune })
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

-- Safe Ground-Resolving Map Waypoint Teleport (Supports Ped & Vehicle)
local function TeleportToWaypoint()
    local waypoint = GetFirstBlipInfoId(8)
    if not DoesBlipExist(waypoint) then
        lib.notify({ title = SharedConfig.PanelName, description = "No map waypoint set. Select a location on your map first!", type = 'error' })
        return
    end

    local coords = GetBlipInfoIdCoord(waypoint)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local entity = (veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped) and veh or ped

    DoScreenFadeOut(200)
    Wait(250)

    FreezeEntityPosition(entity, true)
    local foundGround = false
    local groundZ = 0.0

    -- Sweep heights to load collision and find exact ground Z
    for height = 1, 1000, 25 do
        local testZ = height + 0.0
        SetPedCoordsKeepVehicle(ped, coords.x, coords.y, testZ)
        RequestCollisionAtCoord(coords.x, coords.y, testZ)
        Wait(15)
        local found, z = GetGroundZFor_3dCoord(coords.x, coords.y, testZ, false)
        if found then
            groundZ = z + 1.0
            foundGround = true
            break
        end
    end

    if not foundGround then
        local _, z = GetGroundZFor_3dCoord(coords.x, coords.y, 1000.0, false)
        groundZ = (z and z > 0.0) and (z + 1.0) or 100.0
    end

    SetPedCoordsKeepVehicle(ped, coords.x, coords.y, groundZ)
    FreezeEntityPosition(entity, false)

    Wait(200)
    DoScreenFadeIn(200)
    lib.notify({ title = SharedConfig.PanelName, description = ("Teleported to map waypoint (%.1f, %.1f)"):format(coords.x, coords.y), type = 'success' })
end

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
            TeleportToWaypoint()
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
    local modelName = data and data.model
    if not modelName or #modelName == 0 then
        cb('error')
        return
    end

    local hash = joaat(modelName)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        lib.notify({ title = SharedConfig.PanelName, description = "Invalid skin model: " .. modelName, type = 'error' })
        cb('ok')
        return
    end

    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 80 do
        Wait(50)
        timeout = timeout + 1
    end

    if not HasModelLoaded(hash) then
        lib.notify({ title = SharedConfig.PanelName, description = "Failed to load skin model: " .. modelName, type = 'error' })
        cb('ok')
        return
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

-- Player Management: Full Long-Range OneSync Spectate
local spectateSavedCoords = nil
local spectateSavedHeading = nil

local function StopSpectatingPlayer()
    if not isSpectating then return end
    local myPed = PlayerPedId()
    NetworkSetInSpectatorMode(false, myPed)
    isSpectating = false
    spectateTarget = nil
    if spectateSavedCoords then
        RequestCollisionAtCoord(spectateSavedCoords.x, spectateSavedCoords.y, spectateSavedCoords.z)
        SetEntityCoords(myPed, spectateSavedCoords.x, spectateSavedCoords.y, spectateSavedCoords.z, false, false, false, false)
        if spectateSavedHeading then SetEntityHeading(myPed, spectateSavedHeading) end
        spectateSavedCoords = nil
        spectateSavedHeading = nil
    end
    FreezeEntityPosition(myPed, false)
    SetEntityCollision(myPed, true, true)
    if not isInvis then
        SetEntityVisible(myPed, true, false)
        ResetEntityAlpha(myPed)
    end
    if not isGodmode then
        SetEntityInvincible(myPed, false)
    end
    lib.notify({ title = SharedConfig.PanelName, description = "Mode Spectate désactivé.", type = 'inform' })
end

RegisterNUICallback('spectatePlayer', function(data, cb)
    local targetId = tonumber(data.targetId)
    local myServerId = GetPlayerServerId(PlayerId())

    if targetId == myServerId and not isSpectating then
        lib.notify({ title = SharedConfig.PanelName, description = "Vous ne pouvez pas vous spectate vous-même.", type = 'error' })
        cb('ok')
        return
    end

    if isSpectating then
        StopSpectatingPlayer()
        cb('ok')
        return
    end

    lib.callback('souh4il_dev:server:getSpectateCoords', false, function(res)
        if not res or not res.success or not res.coords then
            lib.notify({ title = SharedConfig.PanelName, description = (res and res.error) or "Joueur introuvable.", type = 'error' })
            return
        end

        -- Hide panel so admin can see the player
        if isPanelOpen then
            isPanelOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action = "setVisible", visible = false })
        end

        local myPed = PlayerPedId()
        spectateSavedCoords = GetEntityCoords(myPed)
        spectateSavedHeading = GetEntityHeading(myPed)

        SetEntityVisible(myPed, false, false)
        SetEntityAlpha(myPed, 0, false)
        SetEntityInvincible(myPed, true)
        SetEntityCollision(myPed, false, false)
        FreezeEntityPosition(myPed, true)

        -- Move invisibly above target so OneSync streams the target ped
        RequestCollisionAtCoord(res.coords.x, res.coords.y, res.coords.z)
        SetEntityCoords(myPed, res.coords.x, res.coords.y, res.coords.z + 15.0, false, false, false, false)

        local tries = 0
        local targetPlayerIdx = GetPlayerFromServerId(targetId)
        local targetPed = targetPlayerIdx ~= -1 and GetPlayerPed(targetPlayerIdx) or 0

        while (targetPlayerIdx == -1 or targetPed == 0 or not DoesEntityExist(targetPed)) and tries < 40 do
            Wait(100)
            targetPlayerIdx = GetPlayerFromServerId(targetId)
            targetPed = targetPlayerIdx ~= -1 and GetPlayerPed(targetPlayerIdx) or 0
            tries = tries + 1
        end

        if targetPed ~= 0 and DoesEntityExist(targetPed) then
            NetworkSetInSpectatorMode(true, targetPed)
            isSpectating = true
            spectateTarget = targetId
            lib.notify({ title = SharedConfig.PanelName, description = ("Spectate de [#%d] %s — Appuyez sur [BACKSPACE] ou [E] pour quitter."):format(targetId, res.name or "Joueur"), type = 'success', duration = 6000 })

            CreateThread(function()
                while isSpectating do
                    Wait(0)
                    if IsControlJustPressed(0, 177) or IsControlJustPressed(0, 38) then -- BACKSPACE or E
                        StopSpectatingPlayer()
                        break
                    end
                end
            end)
        else
            StopSpectatingPlayer()
            lib.notify({ title = SharedConfig.PanelName, description = "Impossible de charger le flux vidéo du joueur.", type = 'error' })
        end
    end, targetId)

    cb('ok')
end)

-- Teleport to Map Waypoint (from Teleport Tab)
RegisterNUICallback('teleportWaypoint', function(_, cb)
    lib.callback('souh4il_dev:server:requestQuickAction', false, function(response)
        if not response or not response.success then
            lib.notify({ title = SharedConfig.PanelName, description = response and response.error or "Rejected", type = 'error' })
            return
        end
        TeleportToWaypoint()
    end, 'tpm')
    cb('ok')
end)

-- Teleport Preset (Self or Target Player)
RegisterNUICallback('teleportPreset', function(data, cb)
    local locKey = data.location
    local dest = TELEPORT_LOCATIONS[locKey]
    local targetId = tonumber(data.targetId)
    if dest then
        if targetId and targetId ~= GetPlayerServerId(PlayerId()) then
            lib.callback('souh4il_dev:server:teleportAction', false, function(res)
                if res and res.success then
                    lib.notify({ title = SharedConfig.PanelName, description = ("Joueur #%d téléporté vers %s !"):format(targetId, locKey:upper()), type = 'success' })
                else
                    lib.notify({ title = SharedConfig.PanelName, description = (res and res.error) or "Échec de téléportation.", type = 'error' })
                end
            end, 'preset', targetId, { x = dest.x, y = dest.y, z = dest.z, w = dest.w })
        else
            local ped = PlayerPedId()
            DoScreenFadeOut(200)
            Wait(250)
            SetPedCoordsKeepVehicle(ped, dest.x, dest.y, dest.z)
            SetEntityHeading(ped, dest.w)
            Wait(200)
            DoScreenFadeIn(200)
            lib.notify({ title = SharedConfig.PanelName, description = "Teleported to " .. locKey:upper(), type = 'success' })
        end
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
        SetPedCoordsKeepVehicle(ped, x, y, z)
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
    local act = data.action or data.type
    local tgt = tonumber(data.targetId or data.target)
    lib.callback('souh4il_dev:server:teleportAction', false, function(response)
        if response and response.success then
            lib.notify({ title = SharedConfig.PanelName, description = ("Téléportation '%s' vers #%s effectuée !"):format(tostring(act):upper(), tostring(tgt)), type = 'success' })
        else
            lib.notify({ title = SharedConfig.PanelName, description = response and response.error or "Failed", type = 'error' })
        end
    end, act, tgt)
    cb('ok')
end)

-- Freeze Player (Per-Target Toggle)
RegisterNUICallback('freezePlayer', function(data, cb)
    local targetId = tonumber(data.targetId or data.target)
    lib.callback('souh4il_dev:server:freezePlayer', false, function(response)
        if response and response.success then
            local statusTxt = response.frozen and "FREEZÉ (Immobilisé) ❄️" or "DÉFREEZÉ (Libéré) ✅"
            lib.notify({ title = SharedConfig.PanelName, description = ("Joueur #%d %s"):format(targetId or 0, statusTxt), type = response.frozen and 'inform' or 'success' })
            lib.callback('souh4il_dev:server:getOnlinePlayers', false, function(res)
                if res and res.success then SendNUIMessage({ action = "updatePlayers", players = res.players }) end
            end)
        else
            lib.notify({ title = SharedConfig.PanelName, description = response and response.error or "Failed", type = 'error' })
        end
    end, targetId, data.state)
    cb('ok')
end)

RegisterNetEvent('souh4il_dev:client:receiveFreeze', function(state)
    isFrozen = (state == true)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, isFrozen)
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        FreezeEntityPosition(veh, isFrozen)
    end
    lib.notify({
        title = SharedConfig.PanelName,
        description = isFrozen and "❄️ Vous avez été immobilisé (Freeze) par le Staff." or "✅ Vous avez été libéré (Unfreeze) par le Staff.",
        type = isFrozen and 'warning' or 'success'
    })
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

-- Equip Owner Arsenal Preset Loadout (Self or Target Player)
RegisterNUICallback('equipLoadout', function(data, cb)
    lib.callback('souh4il_dev:server:giveArsenalLoadout', false, function(response)
        if response and response.success then
            lib.notify({ title = SharedConfig.PanelName, description = ("Arsenal '%s' équipé avec succès !"):format(tostring(data.loadout):upper()), type = 'success' })
        else
            lib.notify({ title = SharedConfig.PanelName, description = response and response.error or "Failed", type = 'error' })
        end
    end, { loadout = data.loadout, targetId = data.targetId })
    cb('ok')
end)

-- =========================================================================
-- WORLD NPC, TRAFFIC & SMART POLICE NPC ENFORCEMENT (CLIENT)
-- =========================================================================
local currentWorldDensity = 1.0
local currentNpcConfig = {
    policeNpcEnabled = false,
    autoMode = true,
    minCopsThreshold = 1,
    wantedStarsEnabled = false,
    emsNpcEnabled = false,
    pedDensity = 1.0,
    trafficDensity = 1.0,
    parkedDensity = 1.0,
    realCopsOnDuty = 0,
}

local POLICE_DISPATCH_SERVICES = { 1, 2, 4, 6, 7, 8, 9, 10, 12, 13, 14, 15 }
local COP_PED_MODELS = {
    [joaat('s_m_y_cop_01')] = true,
    [joaat('s_f_y_cop_01')] = true,
    [joaat('s_m_y_sheriff_01')] = true,
    [joaat('s_f_y_sheriff_01')] = true,
    [joaat('s_m_y_swat_01')] = true,
    [joaat('s_m_y_hwaycop_01')] = true,
    [joaat('s_m_m_fiboffice_01')] = true,
    [joaat('s_m_m_prisguard_01')] = true,
}
local COP_VEH_MODELS = {
    [joaat('police')] = true,
    [joaat('police2')] = true,
    [joaat('police3')] = true,
    [joaat('police4')] = true,
    [joaat('policeb')] = true,
    [joaat('polmav')] = true,
    [joaat('sheriff')] = true,
    [joaat('sheriff2')] = true,
    [joaat('riot')] = true,
    [joaat('fbi')] = true,
    [joaat('fbi2')] = true,
    [joaat('pranger')] = true,
}

local function ApplyDispatchAndCopSettings()
    local copsOn = (currentNpcConfig.policeNpcEnabled == true)
    local emsOn = (currentNpcConfig.emsNpcEnabled == true)
    local starsOn = (currentNpcConfig.wantedStarsEnabled == true) and copsOn

    for _, serviceId in ipairs(POLICE_DISPATCH_SERVICES) do
        EnableDispatchService(serviceId, copsOn)
    end
    EnableDispatchService(3, emsOn) -- Fire Department
    EnableDispatchService(5, emsOn) -- Ambulance Department

    SetCreateRandomCops(copsOn)
    SetCreateRandomCopsNotOnScenarios(copsOn)
    SetCreateRandomCopsOnScenarios(copsOn)
    SetDispatchCopsForPlayer(PlayerId(), copsOn)
    DistantCopCarSirens(copsOn)

    if not starsOn then
        SetMaxWantedLevel(0)
        ClearPlayerWantedLevel(PlayerId())
        CancelCurrentPoliceReport()
    else
        SetMaxWantedLevel(5)
    end
end

local function CleanLocalNpcCops()
    ClearPlayerWantedLevel(PlayerId())
    CancelCurrentPoliceReport()

    -- Remove NPC Cop Peds
    local peds = GetGamePool('CPed')
    for i = 1, #peds do
        local ped = peds[i]
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
            local pType = GetPedType(ped)
            local model = GetEntityModel(ped)
            if pType == 6 or pType == 27 or COP_PED_MODELS[model] then
                SetEntityAsMissionEntity(ped, true, true)
                DeleteEntity(ped)
            end
        end
    end

    -- Remove NPC Police Vehicles (only if no real player is inside and not player-owned)
    local vehs = GetGamePool('CVehicle')
    for i = 1, #vehs do
        local veh = vehs[i]
        if DoesEntityExist(veh) then
            local model = GetEntityModel(veh)
            if COP_VEH_MODELS[model] and not Entity(veh).state.owner then
                local hasPlayer = false
                for seat = -1, 6 do
                    local occ = GetPedInVehicleSeat(veh, seat)
                    if occ ~= 0 and IsPedAPlayer(occ) then
                        hasPlayer = true
                        break
                    end
                end
                if not hasPlayer then
                    SetEntityAsMissionEntity(veh, true, true)
                    DeleteEntity(veh)
                end
            end
        end
    end
end

CreateThread(function()
    Wait(1000)
    if GlobalState.souh4ilNpcConfig then
        currentNpcConfig = GlobalState.souh4ilNpcConfig
    end
    ApplyDispatchAndCopSettings()
end)

RegisterNetEvent('souh4il_dev:client:syncNpcConfig', function(cfg)
    if type(cfg) == 'table' then
        currentNpcConfig = cfg
        currentWorldDensity = tonumber(cfg.trafficDensity) or 1.0
        ApplyDispatchAndCopSettings()
        SendNUIMessage({ action = "syncNpcConfig", config = currentNpcConfig })
    end
end)

RegisterNetEvent('souh4il_dev:client:cleanNpcCops', function()
    CleanLocalNpcCops()
end)

RegisterNUICallback('getNpcConfig', function(_, cb)
    lib.callback('souh4il_dev:server:getNpcConfig', false, function(res)
        if res and res.success and res.config then
            currentNpcConfig = res.config
            SendNUIMessage({ action = "syncNpcConfig", config = currentNpcConfig })
        end
    end)
    cb('ok')
end)

RegisterNUICallback('updateNpcConfig', function(data, cb)
    lib.callback('souh4il_dev:server:updateNpcConfig', false, function(res)
        if res and res.success and res.config then
            currentNpcConfig = res.config
            ApplyDispatchAndCopSettings()
            SendNUIMessage({ action = "syncNpcConfig", config = currentNpcConfig })
            lib.notify({
                title = SharedConfig.PanelName,
                description = "Paramètres PNJ & Police NPC mis à jour avec succès.",
                type = 'success'
            })
        else
            lib.notify({
                title = SharedConfig.PanelName,
                description = (res and res.error) or "Erreur lors de la mise à jour PNJ.",
                type = 'error'
            })
        end
    end, data)
    cb('ok')
end)

RegisterNUICallback('cleanNpcCopsNow', function(_, cb)
    lib.callback('souh4il_dev:server:cleanNpcCopsNow', false, function(res)
        if res and res.success then
            CleanLocalNpcCops()
            lib.notify({
                title = SharedConfig.PanelName,
                description = "Tous les policiers & véhicules PNJ ont été purgés de la carte !",
                type = 'success'
            })
        end
    end)
    cb('ok')
end)

RegisterNUICallback('setTrafficDensity', function(data, cb)
    local density = tonumber(data.density) or 1.0
    lib.callback('souh4il_dev:server:setTrafficDensity', false, function(res)
        if res and res.success then
            currentWorldDensity = density
            if res.config then
                currentNpcConfig = res.config
                SendNUIMessage({ action = "syncNpcConfig", config = currentNpcConfig })
            end
            lib.notify({ title = SharedConfig.PanelName, description = ("Densité globale PNJ & Trafic réglée à %.0f%%"):format(density * 100), type = 'success' })
        end
    end, density)
    cb('ok')
end)

RegisterNetEvent('souh4il_dev:client:syncDensity', function(val)
    local d = tonumber(val) or 1.0
    currentWorldDensity = d
    currentNpcConfig.pedDensity = d
    currentNpcConfig.trafficDensity = d
    currentNpcConfig.parkedDensity = d
end)

CreateThread(function()
    while true do
        local pedD = tonumber(currentNpcConfig.pedDensity) or 1.0
        local trafD = tonumber(currentNpcConfig.trafficDensity) or 1.0
        local parkD = tonumber(currentNpcConfig.parkedDensity) or 1.0
        local copsOn = (currentNpcConfig.policeNpcEnabled == true)
        local starsOn = (currentNpcConfig.wantedStarsEnabled == true) and copsOn

        if pedD ~= 1.0 or trafD ~= 1.0 or parkD ~= 1.0 or not copsOn or not starsOn then
            SetVehicleDensityMultiplierThisFrame(trafD)
            SetRandomVehicleDensityMultiplierThisFrame(trafD)
            SetParkedVehicleDensityMultiplierThisFrame(parkD)
            SetPedDensityMultiplierThisFrame(pedD)
            SetScenarioPedDensityMultiplierThisFrame(pedD, pedD)

            if not starsOn then
                if GetPlayerWantedLevel(PlayerId()) > 0 then
                    ClearPlayerWantedLevel(PlayerId())
                end
            end
            if not copsOn then
                CancelCurrentPoliceReport()
            end
            Wait(0)
        else
            Wait(500)
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

RegisterNetEvent('souh4il_dev:client:receiveNotify', function(data)
    if not data then return end
    lib.notify({
        title = data.title or SharedConfig.PanelName,
        description = data.description or "",
        type = data.type or 'inform'
    })
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

RegisterNetEvent('souh4il_dev:client:receiveSetPed', function(modelName)
    if not modelName or #tostring(modelName) == 0 then return end
    local hash = joaat(tostring(modelName))
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        lib.notify({ title = SharedConfig.PanelName, description = "Modèle de Ped invalide : " .. tostring(modelName), type = 'error' })
        return
    end
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 100 do
        Wait(30)
        timeout = timeout + 1
    end
    if HasModelLoaded(hash) then
        SetPlayerModel(PlayerId(), hash)
        local newPed = PlayerPedId()
        SetPedDefaultComponentVariation(newPed)
        ClearPedBloodDamage(newPed)
        SetModelAsNoLongerNeeded(hash)
        lib.notify({ title = SharedConfig.PanelName, description = "Apparence / Ped appliqué : " .. tostring(modelName), type = 'success' })
    end
end)

RegisterNetEvent('souh4il_dev:client:receiveOpenClothing', function(menuType)
    if isPanelOpen then
        isPanelOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "setVisible", visible = false })
        Wait(150)
    end
    if menuType == 'barber' then
        TriggerEvent('illenium-appearance:client:openClothingShopMenu', true)
        TriggerEvent('qb-clothing:client:openMenu')
    else
        TriggerEvent('illenium-appearance:client:openClothingShopMenu', true)
        TriggerEvent('qb-clothing:client:openMenu')
        TriggerEvent('fivem-appearance:client:openClothingShopMenu')
    end
    lib.notify({ title = SharedConfig.PanelName, description = "Menu Apparence & Vêtements ouvert par le Staff.", type = 'inform' })
end)

RegisterNetEvent('souh4il_dev:client:receiveReloadSkin', function()
    TriggerEvent('illenium-appearance:client:reloadSkin', true)
    TriggerEvent('qb-clothing:client:reloadOutfits')
    local ped = PlayerPedId()
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    lib.notify({ title = SharedConfig.PanelName, description = "Votre apparence originale a été rechargée.", type = 'success' })
end)

RegisterNetEvent('souh4il_dev:client:receiveCleanPed', function()
    local ped = PlayerPedId()
    ClearPedBloodDamage(ped)
    ClearPedWetness(ped)
    ClearPedEnvDirt(ped)
    ResetPedVisibleDamage(ped)
    ClearPedLastDamageBone(ped)
    lib.notify({ title = SharedConfig.PanelName, description = "Sang, blessures et saletés nettoyés.", type = 'success' })
end)

RegisterNetEvent('souh4il_dev:client:receiveVitalsControl', function(data)
    if not data then return end
    local ped = PlayerPedId()
    local vType = data.type
    if vType == 'armor' then
        SetPedArmour(ped, 100)
        lib.notify({ title = SharedConfig.PanelName, description = "Gilet pare-balles restauré à 100%.", type = 'success' })
    elseif vType == 'feed' then
        TriggerEvent('hud:client:UpdateNeeds', 100, 100)
        lib.notify({ title = SharedConfig.PanelName, description = "Faim et soif restaurées à 100%.", type = 'success' })
    elseif vType == 'kill' then
        SetEntityHealth(ped, 0)
    elseif vType == 'godmode' then
        isGodmode = not isGodmode
        SetEntityInvincible(ped, isGodmode)
        SetPlayerInvincible(PlayerId(), isGodmode)
        lib.notify({ title = SharedConfig.PanelName, description = "GodMode Staff : " .. (isGodmode and "ACTIVÉ" or "DÉSACTIVÉ"), type = isGodmode and 'success' or 'inform' })
    end
end)

RegisterNetEvent('souh4il_dev:client:receiveVehicleControl', function(vAction)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return end
    if vAction == 'repair' then
        SetVehicleFixed(veh)
        SetVehicleDeformationFixed(veh)
        SetVehicleDirtLevel(veh, 0.0)
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehicleFuelLevel(veh, 100.0)
    elseif vAction == 'max_tune' then
        ApplyMaxTune(veh)
    elseif vAction == 'eject' then
        TaskLeaveVehicle(ped, veh, 16)
    elseif vAction == 'damage' then
        for i = 0, 7 do SetVehicleTyreBurst(veh, i, true, 1000.0) end
        SetVehicleEngineHealth(veh, 100.0)
    elseif vAction == 'delete' then
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
    end
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
        if isPanelOpen then
            isPanelOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action = "setVisible", visible = false })
            Wait(150)
        end
        TriggerEvent('qb-clothing:client:openMenu')
        TriggerEvent('illenium-appearance:client:openClothingShopMenu', true)
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
        local plate = data.plate or (veh ~= 0 and GetVehicleNumberPlateText(veh) or "")
        lib.callback('souh4il_dev:server:giveKeysToPlayer', false, function(res)
            lib.notify({ title = SharedConfig.PanelName, description = res and res.success and "Clés transmises au joueur avec succès." or "Échec de l'envoi des clés.", type = res and res.success and 'success' or 'error' })
        end, { targetId = tId, plate = plate })
    elseif action == 'seize_vehicle' then
        lib.callback('souh4il_dev:server:seizePlayerVehicle', false, function(res)
            if res and res.success then
                lib.notify({ title = SharedConfig.PanelName, description = ("Véhicule [%s] saisi et supprimé du garage du joueur."):format(res.plate or data.plate), type = 'success' })
                -- Refresh player assets live
                lib.callback('souh4il_dev:server:getPlayerDetails', false, function(detailsRes)
                    if detailsRes and detailsRes.success then
                        SendNUIMessage({ action = "showPlayerDetails", details = detailsRes.details })
                    end
                end, tId)
            else
                lib.notify({ title = SharedConfig.PanelName, description = res and res.error or "Échec de la saisie du véhicule.", type = 'error' })
            end
        end, data)
    elseif action == 'give_owned_vehicle' then
        lib.callback('souh4il_dev:server:givePlayerOwnedVehicle', false, function(res)
            if res and res.success then
                lib.notify({ title = SharedConfig.PanelName, description = ("Véhicule %s [%s] attribué au joueur avec les clés !"):format(res.model:upper(), res.plate), type = 'success' })
                -- Refresh player assets live
                lib.callback('souh4il_dev:server:getPlayerDetails', false, function(detailsRes)
                    if detailsRes and detailsRes.success then
                        SendNUIMessage({ action = "showPlayerDetails", details = detailsRes.details })
                    end
                end, tId)
            else
                lib.notify({ title = SharedConfig.PanelName, description = res and res.error or "Échec de l'attribution du véhicule.", type = 'error' })
            end
        end, data)
    elseif action == 'seize_property' then
        lib.callback('souh4il_dev:server:seizePlayerProperty', false, function(res)
            if res and res.success then
                lib.notify({ title = SharedConfig.PanelName, description = ("Propriété '%s' saisie et révoquée avec succès."):format(res.propertyName or ("#" .. tostring(data.propertyId))), type = 'success' })
                -- Refresh player assets live
                lib.callback('souh4il_dev:server:getPlayerDetails', false, function(detailsRes)
                    if detailsRes and detailsRes.success then
                        SendNUIMessage({ action = "showPlayerDetails", details = detailsRes.details })
                    end
                end, tId)
            else
                lib.notify({ title = SharedConfig.PanelName, description = res and res.error or "Échec de la révocation de la propriété.", type = 'error' })
            end
        end, data)
    elseif action == 'open_house_stash' then
        isPanelOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "setVisible", visible = false })
        lib.callback('souh4il_dev:server:openHouseStash', false, function(res)
            if res and res.success then
                lib.notify({ title = SharedConfig.PanelName, description = "Coffre de la propriété ouvert.", type = 'success' })
            else
                lib.notify({ title = SharedConfig.PanelName, description = res and res.error or "Échec d'ouverture du coffre.", type = 'error' })
            end
        end, data)
    elseif action == 'tp_property' then
        lib.callback('souh4il_dev:server:teleportToProperty', false, function(res)
            if res and res.success then
                lib.notify({ title = SharedConfig.PanelName, description = ("Téléporté à l'entrée de '%s' !"):format(res.propertyName or "Propriété"), type = 'success' })
            else
                lib.notify({ title = SharedConfig.PanelName, description = res and res.error or "Échec de la téléportation.", type = 'error' })
            end
        end, data)
    elseif action == 'give_property_key' then
        lib.callback('souh4il_dev:server:givePropertyKey', false, function(res)
            if res and res.success then
                lib.notify({ title = SharedConfig.PanelName, description = ("Double des clés donné à %s !"):format(res.holderName or ("#" .. tostring(data.toPlayerId))), type = 'success' })
                lib.callback('souh4il_dev:server:getPlayerDetails', false, function(detailsRes)
                    if detailsRes and detailsRes.success then
                        SendNUIMessage({ action = "showPlayerDetails", details = detailsRes.details })
                    end
                end, tId)
            else
                lib.notify({ title = SharedConfig.PanelName, description = res and res.error or "Échec de l'ajout de la clé.", type = 'error' })
            end
        end, data)
    elseif action == 'reset_property_keys' then
        lib.callback('souh4il_dev:server:resetPropertyKeyholders', false, function(res)
            if res and res.success then
                lib.notify({ title = SharedConfig.PanelName, description = "Tous les doubles de clés révoqués avec succès.", type = 'success' })
                lib.callback('souh4il_dev:server:getPlayerDetails', false, function(detailsRes)
                    if detailsRes and detailsRes.success then
                        SendNUIMessage({ action = "showPlayerDetails", details = detailsRes.details })
                    end
                end, tId)
            else
                lib.notify({ title = SharedConfig.PanelName, description = "Erreur de réinitialisation des clés.", type = 'error' })
            end
        end, data)
    elseif action == 'transfer_property' then
        lib.callback('souh4il_dev:server:transferPlayerProperty', false, function(res)
            if res and res.success then
                lib.notify({ title = SharedConfig.PanelName, description = ("Propriété transférée à %s avec succès !"):format(res.newOwnerName or "Nouveau propriétaire"), type = 'success' })
                lib.callback('souh4il_dev:server:getPlayerDetails', false, function(detailsRes)
                    if detailsRes and detailsRes.success then
                        SendNUIMessage({ action = "showPlayerDetails", details = detailsRes.details })
                    end
                end, tId)
            else
                lib.notify({ title = SharedConfig.PanelName, description = res and res.error or "Échec du transfert.", type = 'error' })
            end
        end, data)
    elseif action == 'open_veh_trunk' then
        isPanelOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "setVisible", visible = false })
        lib.callback('souh4il_dev:server:openVehicleTrunk', false, function(res)
            if res and res.success then
                lib.notify({ title = SharedConfig.PanelName, description = ("Coffre [%s] ouvert."):format(data.plate), type = 'success' })
            else
                lib.notify({ title = SharedConfig.PanelName, description = res and res.error or "Échec d'ouverture du coffre.", type = 'error' })
            end
        end, data)
    elseif action == 'open_veh_glovebox' then
        isPanelOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "setVisible", visible = false })
        lib.callback('souh4il_dev:server:openVehicleGlovebox', false, function(res)
            if res and res.success then
                lib.notify({ title = SharedConfig.PanelName, description = ("Boîte à gants [%s] ouverte."):format(data.plate), type = 'success' })
            else
                lib.notify({ title = SharedConfig.PanelName, description = res and res.error or "Échec d'ouverture de la boîte à gants.", type = 'error' })
            end
        end, data)
    elseif action == 'store_veh' then
        lib.callback('souh4il_dev:server:storePlayerVehicle', false, function(res)
            if res and res.success then
                lib.notify({ title = SharedConfig.PanelName, description = ("Véhicule [%s] rangé au garage !"):format(data.plate), type = 'success' })
                lib.callback('souh4il_dev:server:getPlayerDetails', false, function(detailsRes)
                    if detailsRes and detailsRes.success then
                        SendNUIMessage({ action = "showPlayerDetails", details = detailsRes.details })
                    end
                end, tId)
            else
                lib.notify({ title = SharedConfig.PanelName, description = res and res.error or "Échec du rangement au garage.", type = 'error' })
            end
        end, data)
    elseif action == 'bring_veh' then
        lib.callback('souh4il_dev:server:bringPlayerVehicle', false, function(res)
            if res and res.success then
                if res.netId and res.mods then
                    Wait(200)
                    local ent = NetworkGetEntityFromNetworkId(res.netId)
                    if DoesEntityExist(ent) and lib.setVehicleProperties then
                        pcall(function() lib.setVehicleProperties(ent, res.mods) end)
                    end
                end
                lib.notify({ title = SharedConfig.PanelName, description = ("Véhicule [%s] rapatrié à votre position (%s) !"):format(data.plate, res.action == 'spawned' and 'Sorti du Garage' or 'Téléporté'), type = 'success' })
                lib.callback('souh4il_dev:server:getPlayerDetails', false, function(detailsRes)
                    if detailsRes and detailsRes.success then
                        SendNUIMessage({ action = "showPlayerDetails", details = detailsRes.details })
                    end
                end, tId)
            else
                lib.notify({ title = SharedConfig.PanelName, description = res and res.error or "Échec du rapatriement du véhicule.", type = 'error' })
            end
        end, data)
    elseif action == 'repair_veh' then
        lib.callback('souh4il_dev:server:repairPlayerVehicle', false, function(res)
            if res and res.success then
                lib.notify({ title = SharedConfig.PanelName, description = ("Véhicule [%s] réparé & lavé à 100%% !"):format(data.plate), type = 'success' })
                lib.callback('souh4il_dev:server:getPlayerDetails', false, function(detailsRes)
                    if detailsRes and detailsRes.success then
                        SendNUIMessage({ action = "showPlayerDetails", details = detailsRes.details })
                    end
                end, tId)
            else
                lib.notify({ title = SharedConfig.PanelName, description = "Erreur de réparation.", type = 'error' })
            end
        end, data)
    elseif action == 'transfer_veh' then
        lib.callback('souh4il_dev:server:transferPlayerVehicle', false, function(res)
            if res and res.success then
                lib.notify({ title = SharedConfig.PanelName, description = ("Véhicule [%s] transféré à %s !"):format(data.plate, res.newOwnerName or "Nouveau propriétaire"), type = 'success' })
                lib.callback('souh4il_dev:server:getPlayerDetails', false, function(detailsRes)
                    if detailsRes and detailsRes.success then
                        SendNUIMessage({ action = "showPlayerDetails", details = detailsRes.details })
                    end
                end, tId)
            else
                lib.notify({ title = SharedConfig.PanelName, description = res and res.error or "Échec du transfert du véhicule.", type = 'error' })
            end
        end, data)
    elseif action == 'set_gang' then
        lib.callback('souh4il_dev:server:setPlayerGang', false, function(res)
            lib.notify({ title = SharedConfig.PanelName, description = res and res.success and "Player gang updated." or "Failed", type = res and res.success and 'success' or 'error' })
        end, { targetId = tId, gang = data.gang, grade = data.grade })
    elseif action == 'give_perm' or action == 'remove_perm' then
        -- managePermission is OWNER_ONLY on the server side.
        -- Reject non-owner callers client-side to avoid a pointless round-trip.
        -- Server will also reject, but this gives instant feedback.
        lib.callback('souh4il_dev:server:managePermission', false, function(res)
            lib.notify({ title = SharedConfig.PanelName, description = res and res.success and "Permissions updated." or (res and res.error) or "Access denied: Owner only.", type = res and res.success and 'success' or 'error' })
        end, { targetId = tId, role = data.role or 'admin', action = action == 'give_perm' and 'add' or 'remove' })
    elseif action == 'open_inv' then
        isPanelOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "setVisible", visible = false })
        lib.callback('souh4il_dev:server:openInventory', false, function() end, { type = 'player', target = tId })
    elseif action == 'open_trunk' or action == 'open_glovebox' then
        isPanelOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "setVisible", visible = false })
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
    elseif action == 'teleport_to_friend' then
        lib.callback('souh4il_dev:server:teleportPlayerToPlayer', false, function(res)
            lib.notify({ title = SharedConfig.PanelName, description = res and res.success and ("Joueur #%d transféré avec succès vers #%d!"):format(data.fromId, data.toId) or (res and res.error or "Échec"), type = res and res.success and 'success' or 'error' })
        end, { fromId = data.fromId, toId = data.toId })
    elseif action == 'manage_money' then
        lib.callback('souh4il_dev:server:managePlayerMoney', false, function(res)
            if res and res.success then
                SendNUIMessage({ action = "updateTargetLiveMoney", cash = res.cash, bank = res.bank })
                lib.notify({ title = SharedConfig.PanelName, description = ("Argent mis à jour sur joueur #%d."):format(tId), type = 'success' })
            else
                lib.notify({ title = SharedConfig.PanelName, description = res and res.error or "Erreur", type = 'error' })
            end
        end, data)
    elseif action == 'give_item_target' then
        lib.callback('souh4il_dev:server:giveItemToPlayer', false, function(res)
            lib.notify({ title = SharedConfig.PanelName, description = res and res.success and ("Item %s (x%d) donné à #%d."):format(data.item, data.count, tId) or (res and res.error or "Erreur"), type = res and res.success and 'success' or 'error' })
        end, data)
    elseif action == 'set_job_direct' then
        lib.callback('souh4il_dev:server:setPlayerJobDirect', false, function(res)
            lib.notify({ title = SharedConfig.PanelName, description = res and res.success and ("Métier défini sur %s (Grade %d)."):format(data.job, data.grade) or "Erreur", type = res and res.success and 'success' or 'error' })
        end, data)
    elseif action == 'vitals' then
        lib.callback('souh4il_dev:server:controlPlayerVitals', false, function(res)
            lib.notify({ title = SharedConfig.PanelName, description = res and res.success and ("Action vitale '%s' envoyée à #%d."):format(data.vitalsType, tId) or "Erreur", type = res and res.success and 'success' or 'error' })
        end, data)
    elseif action == 'vehicle_control' then
        lib.callback('souh4il_dev:server:controlPlayerVehicle', false, function(res)
            lib.notify({ title = SharedConfig.PanelName, description = res and res.success and ("Action véhicule '%s' envoyée à #%d."):format(data.vehAction, tId) or "Erreur", type = res and res.success and 'success' or 'error' })
        end, data)
    elseif action == 'appearance_control' then
        lib.callback('souh4il_dev:server:controlPlayerAppearance', false, function(res)
            lib.notify({ title = SharedConfig.PanelName, description = res and res.success and ("Action apparence '%s' envoyée à #%d."):format(data.appType, tId) or "Erreur", type = res and res.success and 'success' or 'error' })
        end, data)
    elseif action == 'remove_item_target' then
        lib.callback('souh4il_dev:server:removePlayerItem', false, function(res)
            if res and res.success then
                lib.notify({ title = SharedConfig.PanelName, description = ("Item %s retiré de l'inventaire de #%d."):format(data.item, tId), type = 'success' })
                lib.callback('souh4il_dev:server:getPlayerDetails', false, function(detailsRes)
                    if detailsRes and detailsRes.success then
                        SendNUIMessage({ action = "showPlayerDetails", details = detailsRes.details })
                    end
                end, tId)
            else
                lib.notify({ title = SharedConfig.PanelName, description = "Échec du retrait de l'item.", type = 'error' })
            end
        end, data)
    elseif action == 'give_property' then
        lib.callback('souh4il_dev:server:givePlayerProperty', false, function(res)
            if res and res.success then
                lib.notify({ title = SharedConfig.PanelName, description = ("Propriété '%s' attribuée officiellement à #%d !"):format(res.propertyName or "Maison", tId), type = 'success' })
                lib.callback('souh4il_dev:server:getPlayerDetails', false, function(detailsRes)
                    if detailsRes and detailsRes.success then
                        SendNUIMessage({ action = "showPlayerDetails", details = detailsRes.details })
                    end
                end, tId)
            else
                lib.notify({ title = SharedConfig.PanelName, description = res and res.error or "Échec de l'attribution de la propriété.", type = 'error' })
            end
        end, data)
    end
    cb('ok')
end)

-- Mass Server Actions (Heal & Feed All, Clean Abandoned Cars)
RegisterNUICallback('massServerAction', function(data, cb)
    lib.callback('souh4il_dev:server:massServerAction', false, function(res)
        if res and res.success then
            lib.notify({ title = SharedConfig.PanelName, description = ("Action globale '%s' exécutée (%d entités/joueurs) !"):format(data.massType, res.count or 0), type = 'success' })
        else
            lib.notify({ title = SharedConfig.PanelName, description = res and res.error or "Erreur", type = 'error' })
        end
    end, data)
    cb('ok')
end)

-- Save Current Vehicle to Personal Garage
RegisterNUICallback('saveMyCurrentVehicle', function(data, cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        lib.notify({ title = SharedConfig.PanelName, description = "Vous devez être assis dans un véhicule !", type = 'error' })
        cb('ok')
        return
    end
    local modelHash = GetEntityModel(veh)
    local modelName = (data and data.model and #data.model > 0) and data.model or string.lower(GetDisplayNameFromVehicleModel(modelHash))
    local plate = GetVehicleNumberPlateText(veh)
    local mods = lib.getVehicleProperties and lib.getVehicleProperties(veh) or { plate = plate, model = modelHash }
    local garage = (data and data.garage and #data.garage > 0) and data.garage or 'motel'

    lib.callback('souh4il_dev:server:saveMyCurrentVehicle', false, function(res)
        if res and res.success then
            lib.notify({ title = SharedConfig.PanelName, description = ("Véhicule [%s] enregistré dans votre garage (%s) avec les clés !"):format(res.plate, res.garage), type = 'success' })
        else
            lib.notify({ title = SharedConfig.PanelName, description = res and res.error or "Erreur d'enregistrement garage.", type = 'error' })
        end
    end, { model = modelName, plate = plate, mods = mods, garage = garage })
    cb('ok')
end)

-- Vehicle Workshop Extra Controls (Liveries, Neon Lights, Window Tint)
RegisterNUICallback('vehicleWorkshopExtra', function(data, cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        lib.notify({ title = SharedConfig.PanelName, description = "Vous devez être dans un véhicule !", type = 'error' })
        cb('ok')
        return
    end
    SetVehicleModKit(veh, 0)
    local eType = data.extraType
    if eType == 'next_livery' then
        local count = GetVehicleLiveryCount(veh)
        if count and count > 0 then
            local cur = GetVehicleLivery(veh)
            local nxt = (cur + 1) % count
            SetVehicleLivery(veh, nxt)
            lib.notify({ title = SharedConfig.PanelName, description = ("Livery changée : #%d / %d"):format(nxt + 1, count), type = 'success' })
        else
            local modCount = GetNumVehicleMods(veh, 48)
            if modCount and modCount > 0 then
                local cur = GetVehicleMod(veh, 48)
                local nxt = (cur + 1) % modCount
                SetVehicleMod(veh, 48, nxt, false)
                lib.notify({ title = SharedConfig.PanelName, description = ("Mod Livery changée : #%d / %d"):format(nxt + 1, modCount), type = 'success' })
            else
                lib.notify({ title = SharedConfig.PanelName, description = "Ce véhicule n'a pas de Livery supplémentaire.", type = 'inform' })
            end
        end
    elseif eType == 'neon_on' then
        for i = 0, 3 do SetVehicleNeonLightEnabled(veh, i, true) end
        local r = tonumber(data.r) or 0
        local g = tonumber(data.g) or 229
        local b = tonumber(data.b) or 255
        SetVehicleNeonLightsColour(veh, r, g, b)
        lib.notify({ title = SharedConfig.PanelName, description = "Néons LED activés sous le véhicule !", type = 'success' })
    elseif eType == 'neon_off' then
        for i = 0, 3 do SetVehicleNeonLightEnabled(veh, i, false) end
        lib.notify({ title = SharedConfig.PanelName, description = "Néons désactivés.", type = 'inform' })
    elseif eType == 'tint_limo' then
        SetVehicleWindowTint(veh, 1)
        lib.notify({ title = SharedConfig.PanelName, description = "Vitres teintées 100% Noir (Limo) appliquées !", type = 'success' })
    end
    cb('ok')
end)

-- Upgrade Held Weapon (Full Tactical Attachments + Gold/Platinum Tint + Max Ammo)
RegisterNUICallback('upgradeCurrentWeapon', function(data, cb)
    local ped = PlayerPedId()
    local wep = GetSelectedPedWeapon(ped)
    if not wep or wep == `WEAPON_UNARMED` then
        lib.notify({ title = SharedConfig.PanelName, description = "Prenez une arme en main d'abord !", type = 'error' })
        cb('ok')
        return
    end
    local tint = tonumber(data and data.tint) or 2 -- 2 = Gold, 7 = Platinum
    SetPedWeaponTintIndex(ped, wep, tint)
    AddAmmoToPed(ped, wep, 250)
    SetPedAmmo(ped, wep, 999)
    lib.notify({ title = SharedConfig.PanelName, description = "Arme équipée avec Munitions Max (999) & Finition Luxe !", type = 'success' })
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

-- =========================================================================
-- SERVER-ENFORCED GOD POWERS DISABLE
-- Received from server when periodic check detects no god_powers permission.
-- Forces all active powers off to prevent unauthorized client-side toggling.
-- =========================================================================
RegisterNetEvent('souh4il_dev:client:forceDisablePowers', function()
    local ped = PlayerPedId()
    local player = PlayerId()

    if isGodmode then
        isGodmode = false
        SetEntityInvincible(ped, false)
        SetPlayerInvincible(player, false)
        SetPedCanRagdoll(ped, true)
        SetPedDiesInWater(ped, true)
    end
    if isNoclip then
        isNoclip = false
        local veh = GetVehiclePedIsIn(ped, false)
        local entity = veh ~= 0 and veh or ped
        SetEntityCollision(entity, true, true)
        FreezeEntityPosition(entity, false)
        SetEntityInvincible(entity, isGodmode)
    end
    if isInfiniteAmmo then
        isInfiniteAmmo = false
        SetPedInfiniteAmmoClip(ped, false)
        local weapon = GetSelectedPedWeapon(ped)
        if weapon ~= `WEAPON_UNARMED` then SetPedInfiniteAmmo(ped, false, weapon) end
    end
    if isSuperDamage then
        isSuperDamage = false
        SetPlayerMeleeWeaponDamageModifier(player, 1.0)
        SetPlayerWeaponDamageModifier(player, 1.0)
    end
    if isVehGodmode then
        isVehGodmode = false
    end

    -- Sync UI to reflect disabled state
    SendNUIMessage({
        action = "syncToggles",
        toggles = {
            godmode = false, noclip = false, ammo = false, damage = false, vehgod = false,
        }
    })
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

-- =========================================================================
-- DANCES & EMOTES ENGINE
-- =========================================================================
local currentEmoteDict = nil
local currentEmoteClip = nil
local isEmotePlaying = false

local function LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end
    return HasAnimDictLoaded(dict)
end

local function StopCurrentEmote()
    if isEmotePlaying and currentEmoteDict and currentEmoteClip then
        local ped = PlayerPedId()
        StopAnimTask(ped, currentEmoteDict, currentEmoteClip, 3.0)
        ClearPedTasks(ped)
    end
    currentEmoteDict = nil
    currentEmoteClip = nil
    isEmotePlaying = false
end

RegisterNUICallback('playEmote', function(data, cb)
    local dict = data.dict
    local clip = data.clip
    local loop = data.loop ~= false -- default true

    if not dict or not clip then
        cb('error')
        return
    end

    -- Stop any running emote first
    StopCurrentEmote()

    local ped = PlayerPedId()

    -- Must be on foot
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        lib.notify({ title = SharedConfig.PanelName, description = "Sort du véhicule pour danser!", type = 'error' })
        cb('ok')
        return
    end

    local loaded = LoadAnimDict(dict)
    if not loaded then
        lib.notify({ title = SharedConfig.PanelName, description = "Failed to load animation: " .. dict, type = 'error' })
        cb('ok')
        return
    end

    local flag = loop and 1 or 0  -- 1 = loop, 0 = play once
    TaskPlayAnim(ped, dict, clip, 8.0, -8.0, -1, flag, 0, false, false, false)

    currentEmoteDict = dict
    currentEmoteClip = clip
    isEmotePlaying = true

    -- Auto stop on movement
    CreateThread(function()
        local savedDict = dict
        local savedClip = clip
        Wait(500)
        while isEmotePlaying and currentEmoteDict == savedDict and currentEmoteClip == savedClip do
            local ped2 = PlayerPedId()
            -- If player moves or enters vehicle, stop emote
            if IsEntityMoving(ped2) or GetVehiclePedIsIn(ped2, false) ~= 0 then
                StopCurrentEmote()
                SendNUIMessage({ action = "emoteStopped" })
                break
            end
            Wait(300)
        end
    end)

    cb('ok')
end)

RegisterNUICallback('stopEmote', function(_, cb)
    StopCurrentEmote()
    SendNUIMessage({ action = "emoteStopped" })
    cb('ok')
end)

-- Stop emote on panel close too
local _origClose = nil
AddEventHandler('__cfx_export_souh4il_dev_stopEmoteOnClose', function()
    StopCurrentEmote()
end)
