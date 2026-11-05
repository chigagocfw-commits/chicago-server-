PreloadDicts(
    "anim@heists@ornate_bank@thermal_charge",
    "anim_heist@hs3f@ig1_hack_keypad@arcade@male@",
    "anim_heist@hs3f@ig1_hack_keypad@arcade@female@",
    "anim@scripted@heist@ig11_bomb_plant@male@"
)

local bobcatConfig = Config.contracts.bobcat
local minigames = Editable.minigames.bobcat

local entryDoorPoint = nil
local securityDoorPoint = nil
local keypadPoint = nil
local bombPoint = nil
local weaponsLoot = {}
local zonePoint = nil
local blip = nil

-- Create keypad prop
Utils.createProp(bobcatConfig.guardedArea.keypad.coords, { model = -2122821887 })

-- Hide/remove props on enter/exit
for _, prop in ipairs(bobcatConfig.removeProps) do
    lib.points.new({
        coords = prop.coords,
        distance = 30.0,
        onEnter = function()
            CreateModelHide(prop.coords.x, prop.coords.y, prop.coords.z, 1.0, prop.model, true)
        end,
        onExit = function()
            RemoveModelHide(prop.coords.x, prop.coords.y, prop.coords.z, 1.0, prop.model, true)
        end
    })
end

-- Entry door thermite placement
local function placeEntryThermite()
    if bobcatConfig.entryDoor.requiredItem and not Framework.hasItem(bobcatConfig.entryDoor.requiredItem) then
        LR.notify(locale("missing_" .. bobcatConfig.entryDoor.requiredItem), "error")
        return
    end
    
    if IsSpotOccupied("bobcat:entry_door") then return end
    
    local animDict = "anim@heists@ornate_bank@thermal_charge"
    lib.requestModel(-944468481)
    lib.requestModel(865563579)
    
    local doorCoords = GetDoorCoords(bobcatConfig.entryDoor.locations)
    local offsetCoords = Utils.offsetCoords(vector4(doorCoords.x, doorCoords.y, doorCoords.z, bobcatConfig.entryDoor.heading), 0.0, -0.02, 0.0)
    
    local bagObject = CreateSceneObject(-944468481, offsetCoords)
    local thermiteObject = CreateSceneObject(865563579, offsetCoords)
    
    local scene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z - 0.15, 0.0, 0.0, offsetCoords.w, 2, true, false, 1.0, 0, 1.0)
    SetEntityCollision(thermiteObject, false, false)
    
    NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, "thermal_charge", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bagObject, scene, animDict, "bag_thermal_charge", 1.0, -1.0, 1148846080)
    NetworkStartSynchronisedScene(scene)
    
    AttachEntityToEntity(thermiteObject, cache.ped, GetPedBoneIndex(cache.ped, 28422), 0, 0, 0, 0, 0, 200.0, true, true, false, true, 1, true)
    
    Wait(4000)
    DetachEntity(thermiteObject, true, true)
    Wait(1800)
    SetEntityVisible(bagObject, false, false)
    
    if not minigames.thermite() then
        FreeOccupiedSpot()
        DeleteEntity(thermiteObject)
        DeleteEntity(bagObject)
        LR.notify(locale("thermite_failed"), "error")
        return
    end
    
    LR.notify(locale("thermite_success"), "success")
    
    local dropPos = GetOffsetFromEntityInWorldCoords(thermiteObject, 0.0, 0.0, -1.0)
    TriggerServerEvent("lunar_contracts:bobcat:unlockEntryDoor", dropPos)
    
    TaskPlayAnim(cache.ped, "anim@heists@ornate_bank@thermal_charge", "cover_eyes_loop", 1000.0, 3.0, 11000, 49, 1, false, false, false)
    DeleteEntity(bagObject)
    Wait(10200)
    DeleteEntity(thermiteObject)
    
    LR.notify(locale("entry_door_unlocked"), "success")
    SetModelAsNoLongerNeeded(-944468481)
    SetModelAsNoLongerNeeded(865563579)
    FreeOccupiedSpot()
end

-- Security door thermite placement
local function placeSecurityThermite()
    if bobcatConfig.securityDoor.requiredItem and not Framework.hasItem(bobcatConfig.securityDoor.requiredItem) then
        LR.notify(locale("missing_" .. bobcatConfig.securityDoor.requiredItem), "error")
        return
    end
    
    if IsSpotOccupied("bobcat:security_door") then return end
    
    local animDict = "anim@heists@ornate_bank@thermal_charge"
    lib.requestModel(-944468481)
    lib.requestModel(865563579)
    
    local offsetCoords = Utils.offsetCoords(bobcatConfig.securityDoor.coords, 0.0, -0.02, 0.0)
    
    local bagObject = CreateSceneObject(-944468481, offsetCoords)
    local thermiteObject = CreateSceneObject(865563579, offsetCoords)
    
    local scene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z - 0.15, 0.0, 0.0, offsetCoords.w, 2, true, false, 1.0, 0, 1.0)
    SetEntityCollision(thermiteObject, false, false)
    
    NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, "thermal_charge", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bagObject, scene, animDict, "bag_thermal_charge", 1.0, -1.0, 1148846080)
    NetworkStartSynchronisedScene(scene)
    
    AttachEntityToEntity(thermiteObject, cache.ped, GetPedBoneIndex(cache.ped, 28422), 0, 0, 0, 0, 0, 200.0, true, true, false, true, 1, true)
    
    Wait(4000)
    DetachEntity(thermiteObject, true, true)
    Wait(1800)
    SetEntityVisible(bagObject, false, false)
    
    if not minigames.thermite() then
        FreeOccupiedSpot()
        DeleteEntity(thermiteObject)
        DeleteEntity(bagObject)
        LR.notify(locale("thermite_failed"), "error")
        return
    end
    
    LR.notify(locale("thermite_success"), "success")
    
    local dropPos = GetOffsetFromEntityInWorldCoords(thermiteObject, 0.0, 0.0, -1.0)
    TriggerServerEvent("lunar_contracts:bobcat:unlockSecurityDoor", dropPos)
    
    TaskPlayAnim(cache.ped, "anim@heists@ornate_bank@thermal_charge", "cover_eyes_loop", 1000.0, 3.0, 11000, 49, 1, false, false, false)
    DeleteEntity(bagObject)
    Wait(10200)
    DeleteEntity(thermiteObject)
    
    LR.notify(locale("entry_door_unlocked"), "success")
    SetModelAsNoLongerNeeded(-944468481)
    SetModelAsNoLongerNeeded(865563579)
    FreeOccupiedSpot()
end

-- Keypad hacking
local function hackKeypad()
    local requiredItem = bobcatConfig.guardedArea.keypad.requiredItem
    if requiredItem and not Framework.hasItem(requiredItem) then
        LR.notify(locale("missing_" .. requiredItem), "error")
        return
    end
    
    if IsSpotOccupied("bobcat:keypad") then return end
    
    local offsetCoords = Utils.offsetCoords(bobcatConfig.guardedArea.keypad.coords, 0.03, 0.02, 0.0)
    
    local gender = IsPedMale(cache.ped) and "male@" or "female@"
    local animDict = "anim_heist@hs3f@ig1_hack_keypad@arcade@" .. gender
    
    lib.requestModel(-1746470518)
    lib.requestModel(413312110)
    
    local usbObject = CreateSceneObject(-1746470518, offsetCoords)
    local phoneObject = CreateSceneObject(413312110, offsetCoords)
    
    local keypadObj = GetClosestObjectOfType(offsetCoords.x, offsetCoords.y, offsetCoords.z, 0.5, -2122821887, false, false, false)
    local rotation = GetEntityRotation(keypadObj)
    
    local sceneAction = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z, rotation.x, rotation.y, rotation.z, 2, true, false, 1.0, 0, 1.0)
    
    NetworkAddPedToSynchronisedScene(cache.ped, sceneAction, animDict, "action_var_01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbObject, sceneAction, animDict, "action_var_01_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phoneObject, sceneAction, animDict, "action_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)
    
    local sceneHack = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z, rotation.x, rotation.y, rotation.z, 2, false, true, 1.0, 0, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, sceneHack, animDict, "hack_loop_var_01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbObject, sceneHack, animDict, "hack_loop_var_01_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phoneObject, sceneHack, animDict, "hack_loop_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)
    
    local sceneExit = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z, rotation.x, rotation.y, rotation.z, 2, false, false, 1.0, 0, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, sceneExit, animDict, "exit", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbObject, sceneExit, animDict, "exit_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phoneObject, sceneExit, animDict, "exit_prop_phone_ing", 1.0, -1.0, 1148846080)
    
    NetworkStartSynchronisedScene(sceneAction)
    Wait((GetAnimDuration(animDict, "action_var_01") * 1000) - 500)
    NetworkStartSynchronisedScene(sceneHack)
    
    local success = minigames.keypad()
    
    local reactionScene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z, rotation.x, rotation.y, rotation.z, 2, true, false, 1.0, 0, 1.0)
    local reactionAnim = success and "success_react_exit_var_02" or "fail_react"
    
    NetworkAddPedToSynchronisedScene(cache.ped, reactionScene, animDict, reactionAnim, -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbObject, reactionScene, animDict, reactionAnim .. "_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phoneObject, reactionScene, animDict, reactionAnim .. "_prop_phone_ing", 1.0, -1.0, 1148846080)
    NetworkStartSynchronisedScene(reactionScene)
    
    Wait((GetAnimDuration(animDict, reactionAnim) * 1000) - 500)
    
    if not success then
        local exitScene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z, rotation.x, rotation.y, rotation.z, 2, false, false, 1.0, 0, 1.0)
        NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "exit", -4.0, -4.0, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(usbObject, exitScene, animDict, "exit_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
        NetworkAddEntityToSynchronisedScene(phoneObject, exitScene, animDict, "exit_prop_phone_ing", 1.0, -1.0, 1148846080)
        NetworkStartSynchronisedScene(exitScene)
        Wait((GetAnimDuration(animDict, "exit") * 1000) - 500)
    end
    
    DeleteEntity(usbObject)
    DeleteEntity(phoneObject)
    SetModelAsNoLongerNeeded(-1746470518)
    SetModelAsNoLongerNeeded(413312110)
    FreeOccupiedSpot()
    
    if success then
        LR.notify(locale("hacked_keypad"), "success")
        TriggerServerEvent("lunar_contracts:bobcat:hackedKeypad")
    else
        LR.notify(locale("hack_failed"), "error")
    end
end

-- Plant bomb at vault
local function plantBomb()
    if bobcatConfig.guardedArea.vault.requiredItem and not Framework.hasItem(bobcatConfig.guardedArea.vault.requiredItem) then
        LR.notify(locale("missing_" .. bobcatConfig.guardedArea.vault.requiredItem), "error")
        return
    end
    
    if IsSpotOccupied("bobcat:bomb") then return end
    
    TriggerServerEvent("lunar_contracts:bobcat:plantBomb")
    
    local animDict = "anim@scripted@heist@ig11_bomb_plant@male@"
    local offsetCoords = Utils.offsetCoords(bobcatConfig.guardedArea.vault.coords, -0.5, 0.05, 0.4)
    
    lib.requestModel(-944468481)
    lib.requestModel(1929884544)
    
    local bagObject = CreateSceneObject(-944468481, offsetCoords)
    local bombObject = CreateSceneObject(1929884544, offsetCoords)
    
    local scene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z, 0.0, 0.0, offsetCoords.w, 2, true, false, 1.0, 0, 1.0)
    
    NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, "enter", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bagObject, scene, animDict, "enter_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(bombObject, scene, animDict, "enter_bomb", 1.0, -1.0, 1148846080)
    
    NetworkStartSynchronisedScene(scene)
    Wait((GetAnimDuration(animDict, "enter") * 1000) - 200)
    
    DeleteEntity(bagObject)
    SetModelAsNoLongerNeeded(-944468481)
    SetModelAsNoLongerNeeded(1929884544)
    FreeOccupiedSpot()
    
    LR.notify(locale("explodes_in", bobcatConfig.guardedArea.vault.explosion.delay), "inform")
    Wait(bobcatConfig.guardedArea.vault.explosion.delay * 1000)
    
    local bombCoords = GetEntityCoords(bombObject)
    AddExplosion(bombCoords.x, bombCoords.y, bombCoords.z, bobcatConfig.guardedArea.vault.explosion.type, 3.5, true, false, bobcatConfig.guardedArea.vault.explosion.cameraShake, true)
    DeleteEntity(bombObject)
    
    Wait(3000)
    StopFireInRange(bombCoords.x, bombCoords.y, bombCoords.z, 50.0)
end

-- Thermal burn effect
RegisterNetEvent("lunar_contracts:bobcat:syncEffect", function(coords)
    lib.requestNamedPtfxAsset("scr_ornate_heist")
    UseParticleFxAssetNextCall("scr_ornate_heist")
    local particle = StartParticleFxLoopedAtCoord("scr_heist_ornate_thermal_burn", coords.x, coords.y, coords.z, 0.0, 0.0, bobcatConfig.entryDoor.heading, 1.0, false, false, false, false)
    Wait(10000)
    StopParticleFxLooped(particle, false)
end)

-- Remove entry door interaction
RegisterNetEvent("lunar_contracts:bobcat:removeEntryDoor", function()
    if entryDoorPoint then
        entryDoorPoint.remove()
        entryDoorPoint = nil
    end
end)

-- Remove security door interaction
RegisterNetEvent("lunar_contracts:bobcat:removeSecurityDoor", function()
    if securityDoorPoint then
        securityDoorPoint.remove()
        securityDoorPoint = nil
    end
end)

-- Remove keypad interaction
RegisterNetEvent("lunar_contracts:bobcat:removeKeypad", function()
    if keypadPoint then
        keypadPoint.remove()
        keypadPoint = nil
    end
end)

-- Remove weapons loot
RegisterNetEvent("lunar_contracts:bobcat:removeWeaponsLoot", function(weaponIndex, locationIndex)
    local loot = weaponsLoot[weaponIndex] and weaponsLoot[weaponIndex][locationIndex]
    if loot then
        loot.disableOptions()
        weaponsLoot[weaponIndex][locationIndex] = nil
    end
end)

-- Take weapons loot
local function takeWeaponsLoot(params)
    local index = params.index
    local locationIndex = params.locationIndex
    local lootConfig = bobcatConfig.guardedArea.vault.weaponsLoot[index]
    
    local success = LR.progressBar(locale("taking_loot"), lootConfig.progressDuration, false, {
        dict = "missbigscore2aig_7@driver",
        clip = "boot_r_loop",
        flag = 1
    })
    
    if success then
        TriggerServerEvent("lunar_contracts:bobcat:takeWeaponsLoot", index, locationIndex)
    end
end

-- Create weapons loot props
local function createWeaponsLoot()
    local weaponsConfig = bobcatConfig.guardedArea.vault.weaponsLoot
    
    for i, weaponSet in ipairs(weaponsConfig) do
        weaponsLoot[i] = {}
        for j, location in ipairs(weaponSet.locations) do
            weaponsLoot[i][j] = Utils.createProp(location, {
                model = weaponSet.model,
                offset = vector3(0.0, 0.0, -0.5)
            }, {{
                label = locale("take_loot"),
                icon = "hand",
                onSelect = takeWeaponsLoot,
                args = { index = i, locationIndex = j },
                canInteract = function()
                    return not Busy and not Utils.isPolice() and Utils.distanceCheck(cache.ped, location.xyz, 1.5)
                end
            }})
        end
    end
end

-- Bomb planted event
RegisterNetEvent("lunar_contracts:bobcat:bombPlanted", function()
    if bombPoint then
        bombPoint.remove()
        bombPoint = nil
    end
    
    Wait((bobcatConfig.guardedArea.vault.explosion.delay * 1000) + 2866)
    
    zonePoint = lib.points.new({
        coords = bobcatConfig.guardedArea.vault.coords,
        distance = 30.0,
        onEnter = function()
            CreateModelSwap(bobcatConfig.guardedArea.vault.coords.x, bobcatConfig.guardedArea.vault.coords.y, bobcatConfig.guardedArea.vault.coords.z, 5.0, 290638124, -1583068368, false)
        end,
        onExit = function()
            RemoveModelSwap(bobcatConfig.guardedArea.vault.coords.x, bobcatConfig.guardedArea.vault.coords.y, bobcatConfig.guardedArea.vault.coords.z, 5.0, 290638124, -1583068368, false)
        end
    })
    
    createWeaponsLoot()
end)

-- Setup interaction points
local function setupBobcat()
    -- Entry door
    entryDoorPoint = Utils.createInteractionPoint({
        coords = GetDoorCoords(bobcatConfig.entryDoor.locations),
        radius = 1.0,
        options = {{
            label = locale("place_thermite"),
            icon = "door-open",
            onSelect = placeEntryThermite,
            canInteract = function() return not Busy end
        }}
    })
    
    -- Security door
    securityDoorPoint = Utils.createInteractionPoint({
        coords = bobcatConfig.securityDoor.coords.xyz,
        radius = 1.0,
        options = {{
            label = locale("place_thermite"),
            icon = "door-open",
            onSelect = placeSecurityThermite,
            canInteract = function() return not Busy and not entryDoorPoint end
        }}
    })
    
    -- Keypad
    keypadPoint = Utils.createInteractionPoint({
        coords = bobcatConfig.guardedArea.keypad.coords,
        radius = 1.0,
        options = {{
            label = locale("hack_keypad"),
            icon = "code",
            onSelect = hackKeypad,
            canInteract = function() return not Busy and not securityDoorPoint end
        }}
    })
    
    -- Vault bomb
    bombPoint = Utils.createInteractionPoint({
        coords = bobcatConfig.guardedArea.vault.coords,
        radius = 1.5,
        options = {{
            label = locale("plant_c4"),
            icon = "bomb",
            onSelect = plantBomb,
            canInteract = function() return not Busy and not keypadPoint end
        }}
    })
    
    -- Blip
    blip = Utils.createBlip(bobcatConfig.blip.coords, bobcatConfig.blip)
    SetBlipRoute(blip.value, true)
    Utils.distanceWait(bobcatConfig.blip.coords, 30.0)
    blip.remove()
end

RegisterNetEvent("lunar_contracts:bobcat:started", function(members)
    local playerId = Framework.getIdentifier()
    for _, memberId in ipairs(members) do
        if playerId == memberId then
            setupBobcat()
        end
    end
end)

RegisterNetEvent("lunar_contracts:bobcat:reset", function()
    if entryDoorPoint then entryDoorPoint.remove(); entryDoorPoint = nil end
    if securityDoorPoint then securityDoorPoint.remove(); securityDoorPoint = nil end
    if keypadPoint then keypadPoint.remove(); keypadPoint = nil end
    if bombPoint then bombPoint.remove(); bombPoint = nil end
    
    for _, weapons in pairs(weaponsLoot) do
        for _, lootPoint in pairs(weapons) do
            if lootPoint and lootPoint.remove then lootPoint.remove() end
        end
    end
    weaponsLoot = {}
    
    if zonePoint then
        zonePoint:onExit()
        zonePoint.remove()
        zonePoint = nil
    end
    
    if blip then
        blip.remove()
        blip = nil
    end
end)

-- Guard setup
local function setupGuard(ped)
    SetPedDropsWeaponsWhenDead(ped, false)
    SetPedCombatAbility(ped, bobcatConfig.guardedArea.guards.combatAbility)
    SetPedAccuracy(ped, bobcatConfig.guardedArea.guards.accuracy)
    SetPedRelationshipGroupHash(ped, 1986468669)
    SetPedCombatMovement(ped, 0)
    SetPedCombatAttributes(ped, 5, true)
    SetPedCombatAttributes(ped, 68, false)
    SetPedCombatAttributes(ped, 28, true)
    SetPedCombatAttributes(ped, 21, true)
    SetPedCurrentWeaponVisible(ped, true)
end

-- Guard logic
local function handleGuard(guardPed, locationIndex)
    if GetIsTaskActive(guardPed, 357) or GetIsTaskActive(guardPed, 343) then return end
    if math.random(1, 8) == 1 then
        TaskGuardCurrentPosition(guardPed, 15.0, 10.0, true)
    end
    
    local players = lib.getNearbyPlayers(guardPed, 50.0, true)
    local closestPlayer = nil
    local closestDist = math.huge
    
    for _, player in ipairs(players) do
        local playerPed = player.ped
        local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(guardPed))
        if closestDist > dist and not Editable.isDead(playerPed) then
            if bobcatConfig.guardedArea.guards.minPolice ~= 0 then
                local isPolice = Player(player.id).state.isPolice
                if not isPolice then
                    closestPlayer = playerPed
                    closestDist = dist
                end
            else
                closestPlayer = playerPed
                closestDist = dist
            end
        end
    end
    
    if closestPlayer and not GetIsTaskActive(guardPed, 343) then
        TaskCombatPed(guardPed, closestPlayer, 0, 16)
    end
end

-- Setup guard group
AddRelationshipGroup("BOBCAT_GUARD")

local guardInteractionPoints = {}
local lootedGuards = {}

-- Loot guard
local function lootGuard(guardNetId)
    if IsSpotOccupied(string.format("bobcat:guard_%s", guardNetId)) then return end
    
    local success = LR.progressBar(locale("looting_guard"), bobcatConfig.guardedArea.guards.looting.progressDuration, false, {
        dict = "missbigscore2aig_7@driver",
        clip = "boot_r_loop",
        flag = 1
    })
    
    if success then
        TriggerServerEvent("lunar_contracts:bobcat:lootGuard", guardNetId)
    end
    FreeOccupiedSpot()
end

RegisterNetEvent("lunar_contracts:bobcat:guardLooted", function(guardNetId)
    lootedGuards[guardNetId] = true
    if guardInteractionPoints[guardNetId] then
        guardInteractionPoints[guardNetId].remove()
        guardInteractionPoints[guardNetId] = nil
    end
end)

-- Add loot interaction for dead guard
local function addGuardLootPoint(guardNetId, guardPed, locationIndex)
    if guardInteractionPoints[guardNetId] then return end
    
    guardInteractionPoints[guardNetId] = Utils.createEntityPoint({
        entity = guardPed,
        radius = 1.5,
        options = {{
            label = locale("take_loot"),
            icon = "hand",
            onSelect = lootGuard,
            args = guardNetId,
            canInteract = function() return not Busy and Utils.distanceCheck(cache.ped, guardPed, 1.5) end
        }}
    })
end

-- Handle guards
local function handleGuardsLogic(locationIndex, guards)
    SetRelationshipBetweenGroups(0, 1986468669, 1986468669)
    SetRelationshipBetweenGroups(4, 1986468669, 1862763509)
    SetRelationshipBetweenGroups(4, 1862763509, 1986468669)
    
    for _, guardNetId in ipairs(guards) do
        if NetworkDoesEntityExistWithNetworkId(guardNetId) then
            local guardPed = NetworkGetEntityFromNetworkId(guardNetId)
            local owner = NetworkGetEntityOwner(guardPed)
            
            if owner == cache.playerId then
                setupGuard(guardPed)
                handleGuard(guardPed, locationIndex)
            end
            
            if IsEntityDead(guardPed) and not lootedGuards[guardNetId] and bobcatConfig.guardedArea.guards.looting.enabled then
                addGuardLootPoint(guardNetId, guardPed, locationIndex)
            end
        else
            if guardInteractionPoints[guardNetId] and bobcatConfig.guardedArea.guards.looting.enabled then
                guardInteractionPoints[guardNetId].remove()
                guardInteractionPoints[guardNetId] = nil
            end
        end
    end
end

local guardZone = nil

RegisterNetEvent("lunar_contracts:bobcat:handleGuardsLogic", function(guards)
    guardZone = lib.points.new({
        coords = bobcatConfig.guardedArea.vault.coords,
        distance = 420.0,
        nearby = function()
            handleGuardsLogic(nil, guards)
            Wait(1000)
        end
    })
end)

RegisterNetEvent("lunar_contracts:bobcat:removeGuards", function()
    if guardZone then
        guardZone.remove()
        guardZone = nil
    end
    
    for _, point in pairs(guardInteractionPoints) do
        point.remove()
    end
    guardInteractionPoints = {}
    lootedGuards = {}
end)