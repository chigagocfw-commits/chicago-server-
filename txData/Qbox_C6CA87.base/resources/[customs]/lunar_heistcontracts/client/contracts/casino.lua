-- casino.lua (cleaned)

local PreloadDicts = PreloadDicts

local function generateDrillAnimDicts()
    local dicts = {}
    local genders = { "male", "female" }
    
    for pattern = 1, 4 do
        for lockbox = 1, 3 do
            for _, gender in ipairs(genders) do
                local anim = string.format(
                    "anim_heist@hs3f@ig10_lockbox_drill@pattern_0%s@lockbox_0%d@%s@",
                    pattern, lockbox, gender
                )
                table.insert(dicts, anim)
            end
        end
    end
    
    return dicts
end

PreloadDicts(
    "anim_heist@hs3f@ig1_hack_keypad@arcade@male@",
    "anim_heist@hs3f@ig1_hack_keypad@arcade@female@",
    "anim@heists@ornate_bank@hack",
    "anim_heist@arcade_property@arcade_safe_open@male",
    "anim_heist@arcade_property@arcade_safe_open@female",
    "anim_heist@hs3f@ig8_vault_explosives@left@male@",
    "anim_heist@hs3f@ig8_vault_explosives@right@male@",
    "anim_heist@hs3f@ig8_vault_door_explosion@",
    "anim_heist@hs3f@ig3_cardswipe@male@",
    "anim@apt_trans@hinge_l",
    "anim@scripted@player@mission@tun_control_tower@male@",
    "missbigscore2aig_7@driver",
    table.unpack(generateDrillAnimDicts())
)

local Config = Config.contracts.casino
local Editable = Editable.minigames.casino

local isContractActive = false
local entranceBlips = {}
local keypadInteractionPoints = {}
local entranceInteractionPoints = {}
local exitInteractionPoints = {}
local electricBoxInteractionPoint = nil
local tunnelTerminalPoints = {}
local explosivePoints = {}
local vaultKeypadPoints = {}
local depositBoxPoints = {}
local computerPoints = {}
local encryptionTerminalPoint = nil
local sewerEntrancePoint = nil
local activeCam = nil
local isAlarmPlaying = false
local alarmPoint = nil

-- Load scene
NewLoadSceneStart(2512.031, -256.831, -71.737, 0, 0, 0, 50.0, 0)

local startTime = GetGameTimer()
while true do
    if IsNewLoadSceneLoaded() then break end
    if GetGameTimer() - startTime > 10000 then break end
    Wait(0)
end

-- Create keypad props
local keypadLocations = table.unpack(Config.keypadDoors.locations)
for i, location in ipairs(keypadLocations) do
    keypadInteractionPoints[i] = {}
    for j, keypadCoord in ipairs(location.keypads) do
        local offsetCoord = Utils.offsetCoords(keypadCoord, 0.0, -0.02, 0.0)
        keypadInteractionPoints[i][j] = Utils.createProp(offsetCoord, { model = -2122821887 })
    end
end

-- Create props
for _, prop in ipairs(Config.props) do
    Utils.createProp(prop.coords, { model = prop.model })
end

-- Hide remove props
for _, prop in ipairs(Config.removeProps) do
    CreateModelHide(prop.coords.x, prop.coords.y, prop.coords.z, 0.25, prop.model, true)
end

-- Create entrance keypads
for _, entrance in ipairs(Config.entrances.locations) do
    if entrance.shouldSpawn then
        local offsetCoord = Utils.offsetCoords(entrance.keypad, 0.0, 0.0, 0.0)
        Utils.createProp(offsetCoord, { model = 1321190118 })
    end
end

-- Create tunnel terminals
for _, terminalCoord in ipairs(Config.tunnel.terminals.locations) do
    local terminalProp = Utils.createProp(terminalCoord, { model = Config.tunnel.terminals.model })
    SetInterval(function()
        local entity = terminalProp.get()
        if entity then
            SetEntityCollision(entity, false, false)
        end
    end, 2000)
end

-- Create vault keypads
for _, doorLocation in ipairs(Config.vault.doors.locations) do
    Utils.createProp(doorLocation.keypad, {
        model = -2122821887,
        offset = vector3(0.0, -0.02, 0.0)
    })
end

-- Model swaps
local vaultWallPos = vector3(2509.095459, -266.517761, -38.807579)
CreateModelSwap(vaultWallPos.x, vaultWallPos.y, vaultWallPos.z, 1.0, -1498975473, -1726818330)

local vaultDoorModel = -1241631688
local vaultDoorProp = Utils.createProp(Config.vault.doorCoords, { model = vaultDoorModel })

Utils.createProp(Config.vault.doorCoords, { model = -1822560524 })
Utils.createProp(Config.miniVault.terminal.coords, { model = 585450380 })
Utils.createProp(vector4(993.4242, -140.6818, 33.6937, 325.2004), { model = -1609352586 })

local interiorCoord = vector3(2522.511719, -218.115311, -70.438606)
local function setInteriorEntitySet(interior, entitySet, enable)
    if enable then
        ActivateInteriorEntitySet(interior, entitySet)
    else
        DeactivateInteriorEntitySet(interior, entitySet)
    end
end

-- Vault explosion function
local function explodeVault()
    local doorCoords = Config.vault.doorCoords
    local leftModel = -1241631688
    local rightModel = -1822560524
    local rubbleModel = 1625014289
    
    CreateModelHide(doorCoords.x, doorCoords.y, doorCoords.z, 2.5, leftModel, state)
    CreateModelHide(doorCoords.x, doorCoords.y, doorCoords.z, 2.5, rightModel, state)
    CreateModelHide(doorCoords.x, doorCoords.y, doorCoords.z, 2.5, rubbleModel, state)
    
    vaultDoorProp.remove()
    
    if Utils.distanceCheck(cache.ped, doorCoords, 50.0) then
        lib.requestModel(leftModel)
        lib.requestModel(rightModel)
        lib.requestAnimDict("anim_heist@hs3f@ig8_vault_door_explosion@")
        lib.requestNamedPtfxAsset("cut_hs3f")
        
        local leftDoor = CreateObject(leftModel, doorCoords.x, doorCoords.y, doorCoords.z, false, false, false)
        local rightDoor = CreateObject(rightModel, doorCoords.x, doorCoords.y, doorCoords.z, false, false, false)
        
        SetEntityCompletelyDisableCollision(leftDoor, false, false)
        SetCanAutoVaultOnEntity(leftDoor, false)
        SetCanClimbOnEntity(leftDoor, false)
        
        SetEntityCompletelyDisableCollision(rightDoor, false, false)
        SetCanAutoVaultOnEntity(rightDoor, false)
        SetCanClimbOnEntity(rightDoor, false)
        
        UseParticleFxAsset("cut_hs3f")
        StartParticleFxNonLoopedAtCoord("cut_hs3f_exp_vault", 2505.0, -238.5, -70.5, 0.0, 0.0, 0.0, 1.0, false, false, false)
        PlaySoundFromCoord(-1, "vault_door_explosion", doorCoords.x, doorCoords.y, doorCoords.z, "dlc_ch_heist_finale_sounds", false, 0, false)
        
        local scene = CreateSynchronizedScene(2488.348, -267.364, -71.646, 0.0, 0.0, 0.0, 2)
        PlaySynchronizedEntityAnim(leftDoor, scene, "explosion_vault_01", "anim_heist@hs3f@ig8_vault_door_explosion@", 1000.0, 8.0, 0, 1000.0)
        PlaySynchronizedEntityAnim(rightDoor, scene, "explosion_vault_02", "anim_heist@hs3f@ig8_vault_door_explosion@", 1000.0, 8.0, 0, 1000.0)
        SetSynchronizedScenePhase(scene, 0.056)
        
        local soundId = GetSoundId()
        ShakeGameplayCam("LARGE_EXPLOSION_SHAKE", 0.5)
        PlaySoundFromCoord(soundId, "Jet_Explosions", doorCoords.x, doorCoords.y, doorCoords.z, "exile_1", false, 0)
        ClearAreaOfProjectiles(doorCoords.x, doorCoords.y, doorCoords.z, 25.0, false)
        
        if Utils.distanceCheck(cache.ped, doorCoords, 5.0) then
            SetEntityHealth(cache.ped, 0)
        end
    end
    
    SetTimeout(4500, function()
        lib.requestModel(1082354026)
        local rubbleProp = CreateObject(1082354026, doorCoords.x, doorCoords.y, doorCoords.z - 1.625, false, false, false)
        if leftDoor and rightDoor then
            SetEntityVisible(leftDoor, false, false)
            SetEntityVisible(rightDoor, false, false)
        end
    end)
    
    RemoveModelHide(doorCoords.x, doorCoords.y, doorCoords.z, 25.0, rubbleModel)
end

Framework.onPlayerLoaded(function()
    CreateThread(function()
        Wait(1000)

        local attempts = 0
        local maxAttempts = 10

        while attempts < maxAttempts do
            local ok, err = pcall(lib.callback, "lunar_contracts:casino:isVaultOpened", false, function(shouldOpen)
                if shouldOpen then
                    explodeVault()
                end
            end)

            if ok then
                break
            end

            attempts = attempts + 1
            Wait(1000)
        end
    end)
end)

-- Setup interior
local function setupInterior()
    local interior = GetInteriorAtCoords(2488.348, -267.3637, -71.64563)
    
    setInteriorEntitySet(interior, "set_vault_door", false)
    setInteriorEntitySet(interior, "set_spawn_group1", false)
    setInteriorEntitySet(interior, "set_spawn_group2", false)
    setInteriorEntitySet(interior, "set_vault_dressing", true)
    setInteriorEntitySet(interior, "set_vault_cash_02", false)
    setInteriorEntitySet(interior, "set_vault_art_01", false)
    setInteriorEntitySet(interior, "set_vault_gold_01", false)
    setInteriorEntitySet(interior, "set_vault_gold_02", false)
    setInteriorEntitySet(interior, "set_vault_diamonds_01", true)
    setInteriorEntitySet(interior, "set_vault_diamonds_02", true)
    setInteriorEntitySet(interior, "set_vault_door_locked", true)
    setInteriorEntitySet(interior, "set_vault_door_broken", false)
    setInteriorEntitySet(interior, "set_vault_wall_damagedxd", false)
    
    RefreshInterior(interior)
    
    local rubblePos = vector3(2505.8523, -238.4737, -70.7372)
    CreateModelHide(rubblePos.x, rubblePos.y, rubblePos.z, 25.0, 1625014289, state)
end

Framework.onPlayerLoaded(setupInterior)

-- Keypad hacking function
local function hackKeypad(index)
    local location = Config.keypadDoors.locations[index]
    local animDict = "anim@heists@ornate_bank@hack"
    local targetProp = nil
    
    for _, keypadProp in ipairs(keypadInteractionPoints[index]) do
        local prop = keypadProp.get()
        if prop and HasEntityClearLosToEntity(cache.ped, prop, 81) then
            targetProp = prop
            break
        end
    end
    
    if not targetProp then
        LR.notify(locale("try_standing_further_away"), "error")
        return
    end
    
    if Config.keypadDoors.requiredItem and not Framework.hasItem(Config.keypadDoors.requiredItem) then
        LR.notify(locale("missing_" .. Config.keypadDoors.requiredItem), "error")
        return
    end
    
    if IsSpotOccupied(string.format("casino:keypad_%s", index)) then
        return
    end
    
    lib.requestAnimDict(animDict)
    
    local offsetPos = GetOffsetFromEntityInWorldCoords(targetProp, 0.08, 0.05, -0.01)
    local bagProp = CreateSceneObject(-944468481, offsetPos)
    local laptopProp = CreateSceneObject(-676527372, offsetPos)
    local cardProp = CreateSceneObject(-411901183, offsetPos)
    
    local rotation = GetEntityRotation(targetProp)
    
    local enterScene = NetworkCreateSynchronisedScene(offsetPos.x, offsetPos.y, offsetPos.z, rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, enterScene, animDict, "hack_enter", -4.0, -4.0, 1037, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(bagProp, enterScene, animDict, "hack_enter_bag", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(laptopProp, enterScene, animDict, "hack_enter_laptop", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(cardProp, enterScene, animDict, "hack_enter_card", 4.0, -8.0, 1)
    NetworkStartSynchronisedScene(enterScene)
    
    Wait(GetAnimDuration(animDict, "hack_enter") * 1000 - 200)
    
    local loopScene = NetworkCreateSynchronisedScene(offsetPos.x, offsetPos.y, offsetPos.z, rotation.x, rotation.y, rotation.z, 2, false, true, 1065353216, 0, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "hack_loop", -4.0, -4.0, 1037, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(bagProp, loopScene, animDict, "hack_loop_bag", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(laptopProp, loopScene, animDict, "hack_loop_laptop", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(cardProp, loopScene, animDict, "hack_loop_card", 4.0, -8.0, 1)
    NetworkStartSynchronisedScene(loopScene)
    
    local success = Editable.keypad()
    
    local exitScene = NetworkCreateSynchronisedScene(offsetPos.x, offsetPos.y, offsetPos.z, rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "hack_exit", -4.0, -4.0, 1037, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(bagProp, exitScene, animDict, "hack_exit_bag", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(laptopProp, exitScene, animDict, "hack_exit_laptop", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(cardProp, exitScene, animDict, "hack_exit_card", 4.0, -8.0, 1)
    
    if success then
        TriggerServerEvent("lunar_contracts:casino:unlockKeypadDoor", index)
        LR.notify(locale("hacked_keypad"), "success")
    else
        LR.notify(locale("hack_failed"), "error")
    end
    
    NetworkStartSynchronisedScene(exitScene)
    Wait(GetAnimDuration(animDict, "hack_exit") * 1000 - 500)
    
    DeleteEntity(bagProp)
    DeleteEntity(laptopProp)
    DeleteEntity(cardProp)
    SetModelAsNoLongerNeeded(-944468481)
    SetModelAsNoLongerNeeded(-676527372)
    SetModelAsNoLongerNeeded(-411901183)
    FreeOccupiedSpot()
end

-- Entrance hacking function
local function hackEntrance(index)
    if Config.entrances.requiredItem and not Framework.hasItem(Config.entrances.requiredItem) then
        LR.notify(locale("missing_" .. Config.entrances.requiredItem), "error")
        return
    end
    
    if IsSpotOccupied(string.format("casino:entrance_%s", index)) then
        return
    end
    
    local entrance = Config.entrances.locations[index]
    local keypadCoord = entrance.keypad
    local offsetCoord = Utils.offsetCoords(keypadCoord, 0.03, 0.0, 0.0)
    
    local animBase = "anim_heist@hs3f@ig1_hack_keypad@arcade@"
    local genderSuffix = IsPedMale(cache.ped) and "male@" or "female@"
    local animDict = animBase .. genderSuffix
    
    lib.requestModel(-1746470518)
    lib.requestModel(413312110)
    
    local usbProp = CreateSceneObject(-1746470518, offsetCoord)
    local phoneProp = CreateSceneObject(413312110, offsetCoord)
    
    local keypadObj = GetClosestObjectOfType(offsetCoord.x, offsetCoord.y, offsetCoord.z, 0.5, 1321190118, false, false, false)
    local rotation = GetEntityRotation(keypadObj)
    
    local enterScene = NetworkCreateSynchronisedScene(offsetCoord.x, offsetCoord.y, offsetCoord.z, rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1065353216)
    NetworkAddPedToSynchronisedScene(cache.ped, enterScene, animDict, "action_var_01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbProp, enterScene, animDict, "action_var_01_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phoneProp, enterScene, animDict, "action_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)
    
    local loopScene = NetworkCreateSynchronisedScene(offsetCoord.x, offsetCoord.y, offsetCoord.z, rotation.x, rotation.y, rotation.z, 2, false, true, 1065353216, 0, 1065353216)
    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "hack_loop_var_01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbProp, loopScene, animDict, "hack_loop_var_01_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phoneProp, loopScene, animDict, "hack_loop_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)
    
    NetworkStartSynchronisedScene(enterScene)
    Wait(GetAnimDuration(animDict, "action_var_01") * 1000 - 500)
    NetworkStartSynchronisedScene(loopScene)
    
    local success = Editable.enterances()
    
    if success then
        LR.notify(locale("hacked_keypad"), "success")
        TriggerServerEvent("lunar_contracts:casino:unlockEntrance", index)
    else
        LR.notify(locale("hack_failed"), "error")
    end
    
    local reactScene = NetworkCreateSynchronisedScene(offsetCoord.x, offsetCoord.y, offsetCoord.z, rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)
    local reactAnim = success and "success_react_exit_var_02" or "fail_react"
    
    NetworkAddPedToSynchronisedScene(cache.ped, reactScene, animDict, reactAnim, -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbProp, reactScene, animDict, reactAnim .. "_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phoneProp, reactScene, animDict, reactAnim .. "_prop_phone_ing", 1.0, -1.0, 1148846080)
    NetworkStartSynchronisedScene(reactScene)
    Wait(GetAnimDuration(animDict, reactAnim) * 1000 - 500)
    
    if not success then
        local exitScene = NetworkCreateSynchronisedScene(offsetCoord.x, offsetCoord.y, offsetCoord.z, rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)
        NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "exit", -4.0, -4.0, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(usbProp, exitScene, animDict, "exit_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
        NetworkAddEntityToSynchronisedScene(phoneProp, exitScene, animDict, "exit_prop_phone_ing", 1.0, -1.0, 1148846080)
        NetworkStartSynchronisedScene(exitScene)
        Wait(GetAnimDuration(animDict, "exit") * 1000 - 500)
    end
    
    DeleteEntity(usbProp)
    DeleteEntity(phoneProp)
    SetModelAsNoLongerNeeded(-1746470518)
    SetModelAsNoLongerNeeded(413312110)
    FreeOccupiedSpot()
end

-- Vault keypad hacking
local function hackVaultKeypad(index)
    local location = Config.vault.doors.locations[index]
    local animDict = "anim@heists@ornate_bank@hack"
    local keypadModel = -2122821887
    
    local keypadObj = GetClosestObjectOfType(location.keypad.x, location.keypad.y, location.keypad.z, 0.5, keypadModel, false, false, false)
    
    if Config.vault.doors.requiredItem and not Framework.hasItem(Config.vault.doors.requiredItem) then
        LR.notify(locale("missing_" .. Config.vault.doors.requiredItem), "error")
        return
    end
    
    if IsSpotOccupied(string.format("casino:vault_keypad_%s", index)) then
        return
    end
    
    lib.requestAnimDict(animDict)
    
    local offsetPos = GetOffsetFromEntityInWorldCoords(keypadObj, 0.08, 0.05, -0.01)
    local bagProp = CreateSceneObject(-944468481, offsetPos)
    local laptopProp = CreateSceneObject(-676527372, offsetPos)
    local cardProp = CreateSceneObject(-411901183, offsetPos)
    
    local rotation = GetEntityRotation(keypadObj)
    
    local enterScene = NetworkCreateSynchronisedScene(offsetPos.x, offsetPos.y, offsetPos.z, rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, enterScene, animDict, "hack_enter", -4.0, -4.0, 1037, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(bagProp, enterScene, animDict, "hack_enter_bag", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(laptopProp, enterScene, animDict, "hack_enter_laptop", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(cardProp, enterScene, animDict, "hack_enter_card", 4.0, -8.0, 1)
    NetworkStartSynchronisedScene(enterScene)
    
    Wait(GetAnimDuration(animDict, "hack_enter") * 1000 - 200)
    
    local loopScene = NetworkCreateSynchronisedScene(offsetPos.x, offsetPos.y, offsetPos.z, rotation.x, rotation.y, rotation.z, 2, false, true, 1065353216, 0, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "hack_loop", -4.0, -4.0, 1037, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(bagProp, loopScene, animDict, "hack_loop_bag", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(laptopProp, loopScene, animDict, "hack_loop_laptop", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(cardProp, loopScene, animDict, "hack_loop_card", 4.0, -8.0, 1)
    NetworkStartSynchronisedScene(loopScene)
    
    local success = Editable.vaultKeypad()
    
    local exitScene = NetworkCreateSynchronisedScene(offsetPos.x, offsetPos.y, offsetPos.z, rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "hack_exit", -4.0, -4.0, 1037, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(bagProp, exitScene, animDict, "hack_exit_bag", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(laptopProp, exitScene, animDict, "hack_exit_laptop", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(cardProp, exitScene, animDict, "hack_exit_card", 4.0, -8.0, 1)
    
    if success then
        TriggerServerEvent("lunar_contracts:casino:unlockVaultDoor", index)
        LR.notify(locale("hacked_keypad"), "success")
    else
        LR.notify(locale("hack_failed"), "error")
    end
    
    NetworkStartSynchronisedScene(exitScene)
    Wait(GetAnimDuration(animDict, "hack_exit") * 1000 - 500)
    
    DeleteEntity(bagProp)
    DeleteEntity(laptopProp)
    DeleteEntity(cardProp)
    SetModelAsNoLongerNeeded(-944468481)
    SetModelAsNoLongerNeeded(-676527372)
    SetModelAsNoLongerNeeded(-411901183)
    FreeOccupiedSpot()
end

-- Camera functions
local function createCam(zoom)
    local offset = GetOffsetFromEntityInWorldCoords(cache.ped, zoom and 1.5 or 2.0, -0.25, 0.5)
    local cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", offset.x, offset.y, offset.z, 0.0, 0.0, 0.0, 50.0, true, 2)
    activeCam = cam
    
    local target = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, -0.1, 0.5)
    PointCamAtCoord(activeCam, target.x, target.y, target.z)
    RenderScriptCams(true, false, 1, false)
end

local function destroyCam()
    if activeCam then
        RenderScriptCams(false, false, 1, false)
        DestroyCam(activeCam, true)
        activeCam = nil
    end
end

-- Teleport function
local function teleportToPosition(data)
    lib.requestAnimDict("anim@apt_trans@hinge_l")
    
    CreateThread(function()
        SetEntityCoords(cache.ped, data.from.x, data.from.y, data.from.z - 1.0)
        SetEntityHeading(cache.ped, data.from.w + 180.0)
        createCam(data.zoom)
        
        local backOffset = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, -1.75, 0.0)
        SetEntityCoords(cache.ped, backOffset.x, backOffset.y, backOffset.z - 1.0)
        TaskPlayAnim(cache.ped, "anim@apt_trans@hinge_l", "ext_player", 8.0, 8.0, 2000, 1, 1.0, false, false, false)
        RequestCollisionAtCoord(data.to.x, data.to.y, data.to.z)
    end)
    
    Wait(800)
    
    local playerState = Player(cache.serverId).state
    playerState:set("isPolice", Utils.isPolice(), true)
    
    DoScreenFadeOut(750)
    Wait(1000)
    destroyCam()
    SetArtificialLightsState(false)
    SetEntityVisible(cache.ped, false, false)
    SetEntityCoords(cache.ped, data.to.x, data.to.y, data.to.z + 0.0)
    SetEntityHeading(cache.ped, data.to.w)
    SetGameplayCamRelativeHeading(0.0)
    PlaceObjectOnGroundProperly(cache.ped)
    Wait(1000)
    DoScreenFadeIn(500)
    SetEntityVisible(cache.ped, true, false)
end

-- Electric box hacking
local function hackElectricBox()
    if Config.electricBox.requiredItem and not Framework.hasItem(Config.electricBox.requiredItem) then
        LR.notify(locale("missing_" .. Config.electricBox.requiredItem), "error")
        return
    end
    
    if IsSpotOccupied("casino:disable_prevault") then
        return
    end
    
    local animDict = "anim@scripted@player@mission@tun_control_tower@male@"
    local boxCoords = Config.electricBox.coords.xyz
    local boxModel = Config.electricBox.model
    
    local boxObj = GetClosestObjectOfType(boxCoords.x, boxCoords.y, boxCoords.z, 2.0, boxModel, false, false, false)
    local pos = GetEntityCoords(boxObj)
    local rotation = GetEntityRotation(boxObj)
    
    local enterScene = NetworkCreateSynchronisedScene(pos.x, pos.y, pos.z, rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1065353216)
    NetworkAddPedToSynchronisedScene(cache.ped, enterScene, animDict, "enter", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(boxObj, enterScene, animDict, "enter_electric_box", 1.0, -1.0, 1148846080)
    NetworkStartSynchronisedScene(enterScene)
    
    Wait(GetAnimDuration(animDict, "enter") * 1000 - 200)
    
    local loopScene = NetworkCreateSynchronisedScene(pos.x, pos.y, pos.z, rotation.x, rotation.y, rotation.z, 2, false, true, 1065353216, 0, 1065353216)
    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "loop", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(boxObj, loopScene, animDict, "loop_electric_box", 1.0, -1.0, 1148846080)
    
    local exitScene = NetworkCreateSynchronisedScene(pos.x, pos.y, pos.z, rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)
    NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "exit", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(boxObj, exitScene, animDict, "exit_electric_box", 1.0, -1.0, 1148846080)
    
    NetworkStartSynchronisedScene(loopScene)
    
    local success = Editable.electricBox()
    
    if success then
        TriggerServerEvent("lunar_contracts:casino:hackElectricBox")
        LR.notify(locale("disabled_prevault"), "success")
    else
        LR.notify(locale("hack_failed"), "error")
    end
    
    NetworkStartSynchronisedScene(exitScene)
    Wait(GetAnimDuration(animDict, "exit") * 1000 - 500)
    
    NetworkStopSynchronisedScene(exitScene)
    NetworkStopSynchronisedScene(loopScene)
    FreezeEntityPosition(boxObj, true)
    Wait(1000)
    FreeOccupiedSpot()
end

-- Terminal swiping
local function swipeTerminal(index)
    if electricBoxInteractionPoint then
        LR.notify(locale("terminal_locked"), "error")
        return
    end
    
    if Config.tunnel.terminals.requiredItem and not Framework.hasItem(Config.tunnel.terminals.requiredItem) then
        LR.notify(locale("missing_" .. Config.tunnel.terminals.requiredItem), "error")
        return
    end
    
    if IsSpotOccupied("casino:swipe_terminal" .. index) then
        return
    end
    
    local animDict = "anim_heist@hs3f@ig3_cardswipe@male@"
    local terminalPos = Config.tunnel.terminals.locations[index]
    
    local terminalObj = GetClosestObjectOfType(terminalPos.x, terminalPos.y, terminalPos.z, 2.0, 278208236, false, false, false)
    local rotation = GetEntityRotation(terminalObj)
    
    lib.requestAnimDict(animDict)
    lib.requestModel(-1788269803)
    
    local cardProp = CreateObject(-1788269803, terminalPos.x, terminalPos.y, terminalPos.z, true, true, false)
    SetEntityCollision(cardProp, false, false)
    
    local scene = NetworkCreateSynchronisedScene(terminalPos.x, terminalPos.y, terminalPos.z, rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)
    NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, "success_var01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(cardProp, scene, animDict, "success_var01_card", 1.0, -1.0, 1148846080)
    
    SetTimeout(1500, function()
        TriggerServerEvent("lunar_contracts:casino:swipeTerminal", index)
    end)
    
    NetworkStartSynchronisedScene(scene)
    Wait(GetAnimDuration(animDict, "success_var01") * 1000)
    
    DeleteObject(cardProp)
    FreezeEntityPosition(terminalObj, true)
    FreeOccupiedSpot()
end

-- Plant explosive
local function plantExplosive(side)
    if Config.vault.explosives.requiredItem and not Framework.hasItem(Config.vault.explosives.requiredItem) then
        LR.notify(locale("missing_" .. Config.vault.explosives.requiredItem), "error")
        return
    end
    
    if IsSpotOccupied("casino:plant_explosive") then
        return
    end
    
    local doorCoords = Config.vault.doorCoords
    local animDict = string.format("anim_heist@hs3f@ig8_vault_explosives@%s@male@", side)
    
    lib.requestAnimDict(animDict)
    lib.requestModel(-944468481)
    lib.requestModel(-765902777)
    
    local bagProp = CreateSceneObject(-944468481, doorCoords)
    local explosives = {}
    
    local explosiveCount = side == "right" and 3 or 2
    for i = 1, explosiveCount do
        local explosive = CreateSceneObject(-765902777, doorCoords)
        explosives[i] = explosive
        SetEntityCollision(explosive, false, false)
    end
    
    SetEntityCollision(bagProp, false, false)
    
    local scene = NetworkCreateSynchronisedScene(doorCoords.x, doorCoords.y, doorCoords.z, 0.0, 0.0, doorCoords.w, 2, true, false, 1065353216, 0, 1065353216)
    NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, "player_ig8_vault_explosive", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bagProp, scene, animDict, "bag_ig8_vault_explosive", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(explosives[1], scene, animDict, "semtex_a_ig8_vault_explosive", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(explosives[2], scene, animDict, "semtex_b_ig8_vault_explosive", 1.0, -1.0, 1148846080)
    
    if explosives[3] then
        NetworkAddEntityToSynchronisedScene(explosives[3], scene, animDict, "semtex_c_ig8_vault_explosive", 1.0, -1.0, 1148846080)
    end
    
    NetworkStartSynchronisedScene(scene)
    Wait(GetAnimDuration(animDict, "player_ig8_vault_explosive") * 1000 - 500)
    
    local explosiveData = {}
    for i, explosive in ipairs(explosives) do
        local pos = GetEntityCoords(explosive)
        local rot = GetEntityRotation(explosive, 2)
        explosiveData[i] = { coords = pos, rotation = rot }
    end
    
    DeleteObject(bagProp)
    for _, explosive in ipairs(explosives) do
        DeleteObject(explosive)
    end
    
    local placedExplosives = {}
    for i, data in ipairs(explosiveData) do
        local newExplosive = CreateSceneObject(-765902777, vector3(data.coords.x, data.coords.y, data.coords.z - 0.005))
        SetEntityRotation(newExplosive, data.rotation.x, data.rotation.y, data.rotation.z, 2, true)
        FreezeEntityPosition(newExplosive, true)
        placedExplosives[i] = NetworkGetNetworkIdFromEntity(newExplosive)
    end
    
    TriggerServerEvent("lunar_contracts:casino:plantExplosive", side, placedExplosives)
    FreeOccupiedSpot()
end

-- Drill deposit box
local function drillDepositBox(index)
    if Config.depositBoxes.requiredItem and not Framework.hasItem(Config.depositBoxes.requiredItem) then
        LR.notify(locale("missing_" .. Config.depositBoxes.requiredItem), "error")
        return
    end
    
    if IsSpotOccupied("casino:drill_deposit_box" .. index) then
        return
    end
    
    local boxLocation = Config.depositBoxes.locations[index]
    local boxObj = lib.getClosestObject(boxLocation.coords.xyz, 1.0)
    
    if not boxObj then return end
    
    local pos = GetEntityCoords(boxObj)
    local model = GetEntityModel(boxObj)
    
    local boxType = nil
    if model == -2110344306 then
        boxType = 1
    elseif model == 1941903007 then
        boxType = 2
    elseif model == -815542789 then
        boxType = 3
    end
    
    if not boxType then return end
    
    lib.requestModel(-12990308)
    lib.requestModel(-944468481)
    lib.requestModel(690307545)
    
    RequestScriptAudioBank("DLC_HEIST_FLEECA_SOUNDSET", false)
    RequestScriptAudioBank("DLC_MPHEIST\\HEIST_FLEECA_DRILL", false)
    RequestScriptAudioBank("DLC_MPHEIST\\HEIST_FLEECA_DRILL_2", false)
    
    local drillProp = CreateSceneObject(-12990308, pos)
    local bagProp = CreateSceneObject(-944468481, pos)
    local moneyBagProp = CreateSceneObject(690307545, pos)
    SetEntityVisible(moneyBagProp, false)
    
    local soundId = GetSoundId()
    
    local cabinetName = nil
    if boxType == 1 then
        cabinetName = "ch_prop_ch_sec_cabinet_01abc"
    elseif boxType == 2 then
        cabinetName = "ch_prop_ch_sec_cabinet_01def"
    elseif boxType == 3 then
        cabinetName = "ch_prop_ch_sec_cabinet_01ghi"
    end
    
    for stage = 1, 4 do
        local gender = IsPedMale(cache.ped) and "male" or "female"
        local animDict = string.format("anim_heist@hs3f@ig10_lockbox_drill@pattern_0%s@lockbox_0%d@%s@", boxType, stage, gender)
        lib.requestAnimDict(animDict)
        
        if stage == 1 then
            local enterScene = NetworkCreateSynchronisedScene(pos.x, pos.y, pos.z, 0.0, 0.0, GetEntityHeading(boxObj), 2, true, false, 1065353216, 0, 1.0)
            NetworkAddPedToSynchronisedScene(cache.ped, enterScene, animDict, "enter", -4.0, -4.0, 1037, 16, 1000.0, 0)
            NetworkAddEntityToSynchronisedScene(boxObj, enterScene, animDict, "enter_" .. cabinetName, 4.0, -8.0, 1)
            NetworkAddEntityToSynchronisedScene(drillProp, enterScene, animDict, "enter_ch_prop_vault_drill_01a", 4.0, -8.0, 1)
            NetworkAddEntityToSynchronisedScene(bagProp, enterScene, animDict, "enter_p_m_bag_var22_arm_s", 4.0, -8.0, 1)
            NetworkStartSynchronisedScene(enterScene)
            Wait(GetAnimDuration(animDict, "enter") * 1000)
        end
        
        local actionScene = NetworkCreateSynchronisedScene(pos.x, pos.y, pos.z, 0.0, 0.0, GetEntityHeading(boxObj), 2, false, true, 1065353216, 0, 1.0)
        NetworkAddPedToSynchronisedScene(cache.ped, actionScene, animDict, "action", -4.0, -4.0, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(boxObj, actionScene, animDict, "action_" .. cabinetName, 4.0, -8.0, 1)
        NetworkAddEntityToSynchronisedScene(drillProp, actionScene, animDict, "action_ch_prop_vault_drill_01a", 4.0, -8.0, 1)
        NetworkAddEntityToSynchronisedScene(bagProp, actionScene, animDict, "action_p_m_bag_var22_arm_s", 4.0, -8.0, 1)
        NetworkStartSynchronisedScene(actionScene)
        
        PlaySoundFromEntity(soundId, "Drill", drillProp, "DLC_HEIST_FLEECA_SOUNDSET", false, 0)
        Wait(2000)
        StopSound(soundId)
        
        SetEntityVisible(moneyBagProp, true)
        
        local rewardScene = NetworkCreateSynchronisedScene(pos.x, pos.y, pos.z, 0.0, 0.0, GetEntityHeading(boxObj), 2, true, false, 1065353216, 0, 1.0)
        NetworkAddPedToSynchronisedScene(cache.ped, rewardScene, animDict, "reward", -4.0, -4.0, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(boxObj, rewardScene, animDict, "reward_" .. cabinetName, 4.0, -8.0, 1)
        NetworkAddEntityToSynchronisedScene(drillProp, rewardScene, animDict, "reward_ch_prop_vault_drill_01a", 4.0, -8.0, 1)
        NetworkAddEntityToSynchronisedScene(bagProp, rewardScene, animDict, "reward_p_m_bag_var22_arm_s", 4.0, -8.0, 1)
        NetworkAddEntityToSynchronisedScene(moneyBagProp, rewardScene, animDict, "reward_ch_prop_ch_moneybag_01a", 4.0, -8.0, 1)
        
        SetTimeout(2500, function()
            TriggerServerEvent("lunar_contracts:casino:openDepositBox", index)
        end)
        
        NetworkStartSynchronisedScene(rewardScene)
        Wait(GetAnimDuration(animDict, "reward") * 1000)
        SetEntityVisible(moneyBagProp, false)
    end
    
    DeleteObject(drillProp)
    DeleteObject(bagProp)
    DeleteObject(moneyBagProp)
    ReleaseSoundId(soundId)
    ReleaseScriptAudioBank("DLC_HEIST_FLEECA_SOUNDSET")
    ReleaseScriptAudioBank("DLC_MPHEIST\\HEIST_FLEECA_DRILL")
    ReleaseScriptAudioBank("DLC_MPHEIST\\HEIST_FLEECA_DRILL_2")
    FreeOccupiedSpot()
end

-- Hack computer
local function hackComputer(data)
    if encryptionTerminalPoint then
        LR.notify(locale("encryption_not_disabled"), "error")
        return
    end
    
    if Config.miniVault.computers.requiredItem and not Framework.hasItem(Config.miniVault.computers.requiredItem) then
        LR.notify(locale("missing_" .. Config.miniVault.computers.requiredItem), "error")
        return
    end
    
    if IsSpotOccupied(string.format("casino:computer_%s", data.index)) then
        return
    end
    
    local animDict = "missheist_jewel@hacking"
    local animName = "hack_loop"
    
    Utils.makeEntityFaceCoords(cache.ped, data.coords)
    lib.requestAnimDict(animDict)
    
    TaskPlayAnim(cache.ped, animDict, animName, 4.0, 4.0, -1, 1, 1.0, false, false, false)
    
    LR.progressBar(locale("init_hack"), 3000, false)
    
    local success = Editable.computer()
    
    if success then
        LR.notify(locale("hacked_computer"), "success")
        TriggerServerEvent("lunar_contracts:casino:hackedComputer", data.index)
    else
        LR.notify(locale("hack_failed"), "error")
    end
    
    RemoveAnimDict(animDict)
    ClearPedTasks(cache.ped)
    FreeOccupiedSpot()
end

-- Disable encryption
local function disableEncryption()
    if Config.miniVault.terminal.requiredItem and not Framework.hasItem(Config.miniVault.terminal.requiredItem) then
        LR.notify(locale("missing_" .. Config.miniVault.terminal.requiredItem), "error")
        return
    end
    
    if IsSpotOccupied("casino:disable_encryption") then
        return
    end
    
    local terminalPos = Config.miniVault.terminal.coords
    local offsetPos = Utils.offsetCoords(terminalPos, 0.03, 0.0, 0.0)
    
    local animBase = "anim_heist@hs3f@ig1_hack_keypad@arcade@"
    local genderSuffix = IsPedMale(cache.ped) and "male@" or "female@"
    local animDict = animBase .. genderSuffix
    
    lib.requestModel(-1746470518)
    lib.requestModel(413312110)
    
    local usbProp = CreateSceneObject(-1746470518, offsetPos)
    local phoneProp = CreateSceneObject(413312110, offsetPos)
    
    local terminalObj = GetClosestObjectOfType(offsetPos.x, offsetPos.y, offsetPos.z, 0.5, 585450380, false, false, false)
    local rotation = GetEntityRotation(terminalObj)
    
    local enterScene = NetworkCreateSynchronisedScene(offsetPos.x, offsetPos.y, offsetPos.z, rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1065353216)
    NetworkAddPedToSynchronisedScene(cache.ped, enterScene, animDict, "action_var_01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbProp, enterScene, animDict, "action_var_01_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phoneProp, enterScene, animDict, "action_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)
    
    local loopScene = NetworkCreateSynchronisedScene(offsetPos.x, offsetPos.y, offsetPos.z, rotation.x, rotation.y, rotation.z, 2, false, true, 1065353216, 0, 1065353216)
    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "hack_loop_var_01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbProp, loopScene, animDict, "hack_loop_var_01_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phoneProp, loopScene, animDict, "hack_loop_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)
    
    NetworkStartSynchronisedScene(enterScene)
    Wait(GetAnimDuration(animDict, "action_var_01") * 1000 - 500)
    NetworkStartSynchronisedScene(loopScene)
    
    local success = Editable.enterances()
    
    if success then
        LR.notify(locale("encryption_disabled"), "success")
        TriggerServerEvent("lunar_contracts:casino:disableEncryption")
    else
        LR.notify(locale("hack_failed"), "error")
    end
    
    local reactScene = NetworkCreateSynchronisedScene(offsetPos.x, offsetPos.y, offsetPos.z, rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)
    local reactAnim = success and "success_react_exit_var_02" or "fail_react"
    
    NetworkAddPedToSynchronisedScene(cache.ped, reactScene, animDict, reactAnim, -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbProp, reactScene, animDict, reactAnim .. "_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phoneProp, reactScene, animDict, reactAnim .. "_prop_phone_ing", 1.0, -1.0, 1148846080)
    NetworkStartSynchronisedScene(reactScene)
    Wait(GetAnimDuration(animDict, reactAnim) * 1000 - 500)
    
    if not success then
        local exitScene = NetworkCreateSynchronisedScene(offsetPos.x, offsetPos.y, offsetPos.z, rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)
        NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "exit", -4.0, -4.0, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(usbProp, exitScene, animDict, "exit_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
        NetworkAddEntityToSynchronisedScene(phoneProp, exitScene, animDict, "exit_prop_phone_ing", 1.0, -1.0, 1148846080)
        NetworkStartSynchronisedScene(exitScene)
        Wait(GetAnimDuration(animDict, "exit") * 1000 - 500)
    end
    
    DeleteEntity(usbProp)
    DeleteEntity(phoneProp)
    SetModelAsNoLongerNeeded(-1746470518)
    SetModelAsNoLongerNeeded(413312110)
    FreeOccupiedSpot()
end

-- Plant entrance bomb
local function plantEntranceBomb()
    if Config.sewerEntrance.bomb.requiredItem and not Framework.hasItem(Config.sewerEntrance.bomb.requiredItem) then
        LR.notify(locale("missing_" .. Config.sewerEntrance.bomb.requiredItem), "error")
        return
    end
    
    if IsSpotOccupied("casino:plant_bomb") then
        return
    end
    
    local nearbyPlayers = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 40.0, true)
    
    for _, player in ipairs(nearbyPlayers) do
        local distance = #(player.coords - Config.sewerEntrance.bomb.coords)
        player.distance = distance
    end
    
    table.sort(nearbyPlayers, function(a, b) return a.distance < b.distance end)
    
    local playerIds = {}
    for i, player in ipairs(nearbyPlayers) do
        playerIds[i] = GetPlayerServerId(player.id)
    end
    
    TriggerServerEvent("lunar_contracts:casino:plantEntranceBomb", playerIds)
    
    SetTimeout(10000, FreeOccupiedSpot)
end

-- Alarm functions
local alarmPoint = nil
local isAlarmPlaying = false

local function startAlarm()
    if alarmPoint then return end
    isAlarmPlaying = true
    
    local alarmCoords = Config.alarm.coords
    local soundId = GetSoundId()
    
    alarmPoint = lib.points.new({
        coords = alarmCoords,
        distance = 200.0,
        onEnter = function()
            while not RequestScriptAudioBank("SCRIPT/ALARM_KLAXON_03", false) do
                Wait(0)
            end
            PlaySoundFromCoord(soundId, "ALARMS_KLAXON_03_FAR", alarmCoords.x, alarmCoords.y, alarmCoords.z, "", false, 200.0, false)
        end,
        onExit = function()
            StopSound(soundId)
        end
    })
    
    if Config.alarm.duration then
        SetTimeout(Config.alarm.duration * 1000, function()
            if alarmPoint then
                alarmPoint:onExit()
                alarmPoint:remove()
                alarmPoint = nil
            end
        end)
    end
end

-- Create interaction points
local function createKeypadInteractions()
    for i, location in ipairs(Config.keypadDoors.locations) do
        local coords = location.coords or GetDoorCoords(location.parts)
        
        keypadInteractionPoints[i] = Utils.createInteractionPoint({
            coords = coords,
            radius = 1.25,
            options = {
                {
                    label = locale("hack_keypad"),
                    icon = "code",
                    onSelect = hackKeypad,
                    args = i,
                    canInteract = function()
                        return not isContractActive and not Busy and not Utils.isPolice()
                    end
                },
                {
                    label = locale("unlock"),
                    icon = "lock-open",
                    onSelect = function()
                        TriggerServerEvent("lunar_contracts:casino:unlockKeypadDoor", i)
                        LR.notify(locale("authorized"), "success")
                    end,
                    canInteract = Utils.isPolice
                }
            }
        })
    end
end

-- Register events
RegisterNetEvent("lunar_contracts:casino:openEntrance", function(index)
    if entranceInteractionPoints[index] then
        entranceInteractionPoints[index]:remove()
        entranceInteractionPoints[index] = nil
    end
    startAlarm()
end)

RegisterNetEvent("lunar_contracts:casino:openKeypadDoor", function(index)
    if keypadInteractionPoints[index] then
        keypadInteractionPoints[index]:remove()
        keypadInteractionPoints[index] = nil
    end
end)

RegisterNetEvent("lunar_contracts:casino:disableElectricBox", function()
    if electricBoxInteractionPoint then
        electricBoxInteractionPoint:remove()
        electricBoxInteractionPoint = nil
    end
end)

RegisterNetEvent("lunar_contracts:casino:openTunnel", function()
    if not isContractActive then return end
    for _, point in pairs(tunnelTerminalPoints) do
        point:remove()
        tunnelTerminalPoints[_] = nil
    end
end)

RegisterNetEvent("lunar_contracts:casino:explosivePlanted", function(side)
    if side == "left" then
        if explosivePoints.left then
            explosivePoints.left:remove()
            explosivePoints.left = nil
        end
    else
        if explosivePoints.right then
            explosivePoints.right:remove()
            explosivePoints.right = nil
        end
    end
end)

RegisterNetEvent("lunar_contracts:casino:explodeVault", explodeVault)

RegisterNetEvent("lunar_contracts:casino:openVaultDoor", function(index)
    if vaultKeypadPoints[index] then
        vaultKeypadPoints[index]:remove()
        vaultKeypadPoints[index] = nil
    end
end)

RegisterNetEvent("lunar_contracts:casino:depositBoxOpened", function(index)
    if depositBoxPoints[index] then
        depositBoxPoints[index]:remove()
        depositBoxPoints[index] = nil
    end
    
    SetTimeout(2000, function()
        local boxObj = lib.getClosestObject(Config.depositBoxes.locations[index].coords.xyz, 1.0)
        if not boxObj then return end
        
        if NetworkGetEntityOwner(boxObj) ~= cache.playerId then return end
        
        local pos = GetEntityCoords(boxObj)
        local model = GetEntityModel(boxObj)
        
        local boxType = nil
        if model == -2110344306 then
            boxType = 1
        elseif model == 1941903007 then
            boxType = 2
        elseif model == -815542789 then
            boxType = 3
        end
        
        local cabinetName = nil
        if boxType == 1 then
            cabinetName = "ch_prop_ch_sec_cabinet_01abc"
        elseif boxType == 2 then
            cabinetName = "ch_prop_ch_sec_cabinet_01def"
        elseif boxType == 3 then
            cabinetName = "ch_prop_ch_sec_cabinet_01ghi"
        end
        
        local gender = IsPedMale(cache.ped) and "male" or "female"
        local animDict = string.format("anim_heist@hs3f@ig10_lockbox_drill@pattern_0%s@lockbox_04@%s@", boxType, gender)
        
        local scene = NetworkCreateSynchronisedScene(pos.x, pos.y, pos.z, 0.0, 0.0, GetEntityHeading(boxObj), 2, true, false, 1.0, 0.99, 0.0)
        NetworkAddEntityToSynchronisedScene(boxObj, scene, animDict, "reward_" .. cabinetName, 1.0, -1.0, 0)
        NetworkStartSynchronisedScene(scene)
        FreezeEntityPosition(boxObj, true)
    end)
end)

RegisterNetEvent("lunar_contracts:casino:hackedComputer", function(index)
    if computerPoints[index] then
        computerPoints[index]:remove()
        computerPoints[index] = nil
    end
end)

RegisterNetEvent("lunar_contracts:casino:disableEncryption", function()
    if encryptionTerminalPoint then
        encryptionTerminalPoint:remove()
        encryptionTerminalPoint = nil
    end
end)

RegisterNetEvent("lunar_contracts:casino:depositBoxesUnlocked", function(index)
    depositBoxUnlocked[index] = true
end)

-- Cutscene for bomb planting
local function playBombCutscene(playerPeds)
    local cutsceneName = "hs3f_dir_sew"
    RequestCutscene(cutsceneName)
    
    DoScreenFadeOut(500)
    Wait(1000)
    
    while not HasCutsceneLoaded() do
        Wait(0)
    end
    
    DoScreenFadeIn(1000)
    
    SetEntityVisible(cache.ped, false, false)
    NetworkSetEntityInvisibleToNetwork(cache.ped, true)
    
    if #playerPeds == 1 then
        table.insert(playerPeds, 1, -1)
    else
        local temp = playerPeds[1]
        playerPeds[1] = playerPeds[2]
        playerPeds[2] = temp
    end
    
    local clonedPeds = {}
    for i = 1, 4 do
        local pedToClone = playerPeds[i] or cache.ped
        local cloned = ClonePed(pedToClone, false, true)
        
        if playerPeds[i] == -1 then
            SetEntityVisible(cloned, false, false)
        end
        
        RegisterEntityForCutscene(cloned, "MP_" .. i, 0, GetEntityModel(cloned), 64)
        SetCutsceneEntityStreamingFlags("MP_" .. i, 0, 1)
        table.insert(clonedPeds, cloned)
    end
    
    StartCutscene(0)
    Wait(10)
    
    for i, pedId in ipairs(playerPeds) do
        if pedId ~= -1 then
            ClonePedToTarget(pedId, clonedPeds[i])
        end
    end
    
    Wait(9000)
    DoScreenFadeOut(1000)
    Wait(1000)
    StopCutsceneImmediately()
    
    NetworkSetEntityInvisibleToNetwork(cache.ped, false)
    SetEntityVisible(cache.ped, true, true)
    
    for _, ped in ipairs(clonedPeds) do
        DeleteEntity(ped)
    end
    
    for i, pedId in ipairs(playerPeds) do
        if pedId == cache.ped or i == #Config.sewerEntrance.bomb.cutsceneFinalLocations then
            local finalPos = Config.sewerEntrance.bomb.cutsceneFinalLocations[i]
            SetEntityCoords(cache.ped, finalPos.x, finalPos.y, finalPos.z)
            SetEntityHeading(cache.ped, finalPos.w)
            SetGameplayCamRelativeHeading(0.0)
            break
        end
    end
    
    Wait(1000)
    DoScreenFadeIn(1000)
end

RegisterNetEvent("lunar_contracts:casino:plantEntranceBomb", function(players)
    SetTimeout(10000, startAlarm)
    
    if not isContractActive or not sewerEntrancePoint then
        return
    end
    
    sewerEntrancePoint:remove()
    sewerEntrancePoint = nil
    
    for _, serverId in ipairs(players) do
        if serverId == cache.serverId then
            local peds = {}
            for j, id in ipairs(players) do
                peds[j] = GetPlayerPed(GetPlayerFromServerId(id))
            end
            playBombCutscene(peds)
        end
    end
    
    Utils.createProp(vector4(2480.4705, -294.7413, -71.6345, 188.6713), { model = 317753433 })
end)

-- Start contract
local function startContract(computers)
    if isContractActive then return end
    
    isContractActive = true
    
    for i, blipData in ipairs(Config.entranceBlips) do
        entranceBlips[i] = Utils.createBlip(blipData.coords, {
            name = blipData.name,
            sprite = 1,
            size = 0.75,
            color = 1
        })
    end
    
    electricBoxInteractionPoint = Utils.createInteractionPoint({
        coords = Config.electricBox.coords,
        radius = 1.0,
        options = {
            {
                label = locale("unlock_keypads"),
                icon = "code",
                onSelect = hackElectricBox,
                canInteract = function() return not Busy end
            }
        }
    })
    
    for i, terminalPos in ipairs(Config.tunnel.terminals.locations) do
        tunnelTerminalPoints[i] = Utils.createInteractionPoint({
            coords = terminalPos,
            radius = 1.25,
            options = {
                {
                    label = locale("swipe_card"),
                    icon = "credit-card",
                    onSelect = swipeTerminal,
                    args = i,
                    canInteract = function() return not Busy end
                }
            }
        })
    end
    
    for side, pos in pairs(Config.vault.explosives.locations) do
        explosivePoints[side] = Utils.createInteractionPoint({
            coords = pos,
            radius = 1.25,
            options = {
                {
                    label = locale("plant_explosive"),
                    icon = "bomb",
                    onSelect = plantExplosive,
                    args = side,
                    canInteract = function()
                        return not Busy and Utils.getTableSize(tunnelTerminalPoints) == 0
                    end
                }
            }
        })
    end
    
    for i, doorLocation in ipairs(Config.vault.doors.locations) do
        vaultKeypadPoints[i] = Utils.createInteractionPoint({
            coords = doorLocation.keypad,
            radius = 1.25,
            options = {
                {
                    label = locale("hack_keypad"),
                    icon = "code",
                    onSelect = hackVaultKeypad,
                    args = i,
                    canInteract = function()
                        return not isContractActive and not Busy and not explosivePoints.left and not explosivePoints.right
                    end
                }
            }
        })
    end
    
    for i, boxLocation in ipairs(Config.depositBoxes.locations) do
        local offsetCoords = Utils.offsetCoords(boxLocation.coords, 0.0, 0.0, 1.0)
        depositBoxPoints[i] = Utils.createInteractionPoint({
            coords = offsetCoords,
            radius = 1.25,
            options = {
                {
                    label = locale("drill_deposit_box"),
                    icon = "sack-dollar",
                    onSelect = drillDepositBox,
                    args = i,
                    canInteract = function()
                        return not Busy and depositBoxUnlocked[boxLocation.requires or 0]
                    end
                }
            }
        })
    end
    
    encryptionTerminalPoint = Utils.createInteractionPoint({
        coords = Config.miniVault.terminal.coords,
        radius = 1.25,
        options = {
            {
                label = locale("disable_encryption"),
                icon = "code",
                onSelect = disableEncryption,
                canInteract = function() return not Busy end
            }
        }
    })
    
    for i, computer in ipairs(computers) do
        computerPoints[i] = Utils.createInteractionPoint({
            coords = computer.coords,
            radius = 1.25,
            options = {
                {
                    label = locale("hack_computer"),
                    icon = "code",
                    onSelect = hackComputer,
                    args = { index = i, coords = computer.coords },
                    canInteract = function()
                        return not computer.hacked and not Busy
                    end
                }
            }
        })
    end
    
    table.insert(exitInteractionPoints, Utils.createInteractionPoint({
        coords = Config.sewerEntrance.from.target,
        radius = 1.25,
        options = {
            {
                label = locale("enter"),
                icon = "door-open",
                onSelect = teleportToPosition,
                args = {
                    from = Config.sewerEntrance.from.coords,
                    to = Config.sewerEntrance.to.coords
                },
                canInteract = function() return not activeCam end
            }
        }
    }))
    
    table.insert(exitInteractionPoints, Utils.createInteractionPoint({
        coords = Config.sewerEntrance.to.target,
        radius = 1.25,
        options = {
            {
                label = locale("exit"),
                icon = "door-open",
                onSelect = teleportToPosition,
                args = {
                    from = Config.sewerEntrance.to.coords,
                    to = Config.sewerEntrance.from.coords
                },
                canInteract = function() return not activeCam end
            }
        }
    }))
    
    sewerEntrancePoint = Utils.createInteractionPoint({
        coords = Config.sewerEntrance.bomb.coords,
        radius = 1.25,
        options = {
            {
                label = locale("plant_c4"),
                icon = "bomb",
                onSelect = plantEntranceBomb,
                canInteract = function() return not Busy end
            }
        }
    })
end

RegisterNetEvent("lunar_contracts:casino:started", function(identifiers, computers)
    for _, identifier in ipairs(identifiers) do
        if Framework.getIdentifier() == identifier then
            startContract(computers)
            createKeypadInteractions()
        end
    end
end)

-- Reset contract
local function resetContract()
    if not vaultDoorProp then
        vaultDoorProp = Utils.createProp(Config.vault.doorCoords, { model = -1241631688 })
    end
    
    if vaultRubbleProp then
        DeleteEntity(vaultRubbleProp)
        vaultRubbleProp = nil
    end
    
    if not isContractActive then
        return
    end
    
    isContractActive = false
    isAlarmPlaying = false
    
    for _, blip in pairs(entranceBlips) do
        if blip then
            blip:remove()
            entranceBlips[_] = nil
        end
    end
    
    for _, point in pairs(keypadInteractionPoints) do
        if point then
            point:remove()
            keypadInteractionPoints[_] = nil
        end
    end
    
    for _, point in pairs(entranceInteractionPoints) do
        if point then
            point:remove()
            entranceInteractionPoints[_] = nil
        end
    end
    
    for _, point in pairs(exitInteractionPoints) do
        if point then
            point:remove()
            exitInteractionPoints[_] = nil
        end
    end
    
    if electricBoxInteractionPoint then
        electricBoxInteractionPoint:remove()
        electricBoxInteractionPoint = nil
    end
    
    for _, point in pairs(tunnelTerminalPoints) do
        if point then
            point:remove()
            tunnelTerminalPoints[_] = nil
        end
    end
    
    for _, point in pairs(explosivePoints) do
        if point then
            point:remove()
            explosivePoints[_] = nil
        end
    end
    
    for _, point in pairs(vaultKeypadPoints) do
        if point then
            point:remove()
            vaultKeypadPoints[_] = nil
        end
    end
    
    for _, point in pairs(depositBoxPoints) do
        if point then
            point:remove()
            depositBoxPoints[_] = nil
        end
    end
    
    for _, point in pairs(computerPoints) do
        if point then
            point:remove()
            computerPoints[_] = nil
        end
    end
    
    for _, blip in pairs(entranceBlips) do
        if blip then
            blip:remove()
            entranceBlips[_] = nil
        end
    end
    
    if encryptionTerminalPoint then
        encryptionTerminalPoint:remove()
        encryptionTerminalPoint = nil
    end
    
    if sewerEntrancePoint then
        sewerEntrancePoint:remove()
        sewerEntrancePoint = nil
    end
    
    if alarmPoint then
        alarmPoint:remove()
        alarmPoint = nil
    end
    
    table.wipe(depositBoxUnlocked)
    setupInterior()
    
    local doorCoords = Config.vault.doorCoords
    RemoveModelHide(doorCoords.x, doorCoords.y, doorCoords.z, 2.5, -1241631688)
    RemoveModelHide(doorCoords.x, doorCoords.y, doorCoords.z, 2.5, -1822560524)
    RemoveModelHide(doorCoords.x, doorCoords.y, doorCoords.z, 2.5, 1625014289)
end

RegisterNetEvent("lunar_contracts:casino:reset", resetContract)

-- Guard functions
local function setupGuard(guard)
    SetPedDropsWeaponsWhenDead(guard, false)
    SetPedCombatAbility(guard, Config.guards.combatAbility)
    SetPedAccuracy(guard, Config.guards.accuracy)
    SetPedRelationshipGroupHash(guard, -2143528956)
    SetPedCombatMovement(guard, 1)
    SetPedCombatAttributes(guard, 5, true)
    SetPedCombatAttributes(guard, 68, true)
    SetPedCombatAttributes(guard, 43, true)
    SetPedCombatAttributes(guard, 21, true)
    SetPedCombatAttributes(guard, 50, true)
    SetBlockingOfNonTemporaryEvents(guard, true)
end

Utils.entityStateHandler("casino:setupPed", setupGuard)

local function handleGuardLogic(guard)
    local currentWeapon = GetSelectedPedWeapon(guard)
    if currentWeapon == -1569615261 then
        ClearPedTasks(guard)
        SetCurrentPedWeapon(guard, -1569615261, true)
    end
    
    if not GetIsTaskActive(guard, 343) and not GetIsTaskActive(guard, 222) then
        if math.random(1, 8) == 1 then
            local coords = GetEntityCoords(guard)
            TaskWanderInArea(guard, coords.x, coords.y, coords.z, 7.5, 10, 15.0)
        end
    end
    
    if not isAlarmPlaying then
        return
    end
    
    local guardPos = GetEntityCoords(guard)
    local players = lib.getNearbyPlayers(guardPos, 50.0, true)
    local closestPlayer = nil
    local closestDist = math.huge
    
    for _, player in ipairs(players) do
        local playerPed = player.ped
        local dist = #(GetEntityCoords(playerPed) - guardPos)
        
        if closestDist > dist and not Editable.isDead(playerPed) then
            if Config.guards.minPolice == 0 then
                local isPolice = Player(GetPlayerServerId(player.id)).state.isPolice
                if isPolice then goto continue end
            end
            closestDist = dist
            closestPlayer = playerPed
        end
        ::continue::
    end
    
    if closestPlayer and not GetIsTaskActive(guard, 343) then
        TaskCombatPed(guard, closestPlayer, 0, 16)
    end
end

AddRelationshipGroup("CASINO_GUARD")

local guardInteractionPoints = {}
local lootedGuards = {}

local function lootGuard(index)
    if IsSpotOccupied(string.format("casino:guard_%s", index)) then
        return
    end
    
    LR.progressBar(locale("looting_guard"), Config.guards.looting.progressDuration, false, {
        dict = "missbigscore2aig_7@driver",
        clip = "boot_r_loop",
        flag = 1
    })
    
    TriggerServerEvent("lunar_contracts:casino:lootGuard", index)
    FreeOccupiedSpot()
end

RegisterNetEvent("lunar_contracts:casino:guardLooted", function(index)
    lootedGuards[index] = true
    if guardInteractionPoints[index] then
        guardInteractionPoints[index]:remove()
        guardInteractionPoints[index] = nil
    end
end)

local function addGuardInteraction(index, guard)
    if guardInteractionPoints[index] then
        return
    end
    
    guardInteractionPoints[index] = Utils.createEntityPoint({
        entity = guard,
        radius = 1.5,
        options = {
            {
                label = locale("take_loot"),
                icon = "hand",
                onSelect = lootGuard,
                args = index,
                canInteract = function() return not Busy end
            }
        }
    })
end

local function handleAllGuards(guards)
    SetRelationshipBetweenGroups(0, -2143528956, -2143528956)
    SetRelationshipBetweenGroups(4, -2143528956, 1862763509)
    SetRelationshipBetweenGroups(4, 1862763509, -2143528956)
    
    local deadGuards = {}
    
    for _, guardId in ipairs(guards) do
        if NetworkDoesEntityExistWithNetworkId(guardId) then
            local guard = NetworkGetEntityFromNetworkId(guardId)
            if NetworkGetEntityOwner(guard) == cache.playerId then
                handleGuardLogic(guard)
            end
            
            if IsEntityDead(guard) and not lootedGuards[guardId] then
                if Config.guards.looting.enabled and GetEntityModel(guard) == Config.guards.models.special then
                    addGuardInteraction(guardId, guard)
                end
            end
        else
            if guardInteractionPoints[guardId] and Config.guards.looting.enabled then
                guardInteractionPoints[guardId]:remove()
                guardInteractionPoints[guardId] = nil
            end
        end
    end
    
    TriggerServerEvent("lunar_contracts:casino:regainWeapons", deadGuards)
end

local guardHandlerPoint = nil

RegisterNetEvent("lunar_contracts:casino:handleGuardsLogic", function(guards)
    guardHandlerPoint = lib.points.new({
        coords = Config.alarm.coords,
        distance = 420.0,
        nearby = function()
            handleAllGuards(guards)
            Wait(1000)
        end
    })
end)

RegisterNetEvent("lunar_contracts:casino:removeGuards", function()
    if guardHandlerPoint then
        guardHandlerPoint:remove()
        guardHandlerPoint = nil
    end
    
    for _, point in pairs(guardInteractionPoints) do
        point:remove()
        guardInteractionPoints[_] = nil
    end
    
    table.wipe(lootedGuards)
end)