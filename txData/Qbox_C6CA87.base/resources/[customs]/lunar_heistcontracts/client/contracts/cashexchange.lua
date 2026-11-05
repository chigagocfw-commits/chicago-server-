PreloadDicts(
    "anim_heist@hs3f@ig1_hack_keypad@arcade@male@",
    "anim_heist@hs3f@ig1_hack_keypad@arcade@female@",
    "anim@heists@ornate_bank@hack"
)

local cashexchangeConfig = Config.contracts.cashexchange
local minigames = Editable.minigames.cashexchange

local currentLocationIndex = nil
local startPanelPoint = nil
local electricBoxPoint = nil
local vaultPoint = nil
local alarmBlip = nil

-- Create props for each location
for i, location in ipairs(cashexchangeConfig.locations) do
    CreateThread(function()
        while not IsModelInCdimage(431639513) do Wait(500) end
        
        for _, prop in ipairs(location.props) do
            lib.requestModel(prop.model)
            Utils.createProp(prop.coords, {
                model = prop.model,
                offset = vector3(0.0, 0.0, -1.0)
            })
        end
        
        for _, prop in ipairs(location.removeProps) do
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
    end)
end

-- Disable smart lock (start panel hack)
local function disableSmartLock()
    if cashexchangeConfig.startPanel.requiredItem and not Framework.hasItem(cashexchangeConfig.startPanel.requiredItem) then
        LR.notify(locale("missing_" .. cashexchangeConfig.startPanel.requiredItem), "error")
        return
    end
    
    if IsSpotOccupied("cashexchange:disable_smart_lock_" .. currentLocationIndex) then return end
    
    local location = cashexchangeConfig.locations[currentLocationIndex]
    local panelConfig = location.startPanel
    
    local offsetCoords = Utils.offsetCoords(panelConfig.coords, panelConfig.offset.x, panelConfig.offset.y, panelConfig.offset.z)
    
    local gender = IsPedMale(cache.ped) and "male@" or "female@"
    local animDict = "anim_heist@hs3f@ig1_hack_keypad@arcade@" .. gender
    
    lib.requestModel(-1746470518)
    lib.requestModel(413312110)
    
    local usbObject = CreateSceneObject(-1746470518, offsetCoords)
    local phoneObject = CreateSceneObject(413312110, offsetCoords)
    local rotation = vector3(0.0, 0.0, offsetCoords.w)
    
    local sceneAction = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z, rotation.x, rotation.y, rotation.z, 2, true, false, 1.0, 0, 1.0)
    
    NetworkAddPedToSynchronisedScene(cache.ped, sceneAction, animDict, "action_var_01", 1000.0, -1.5, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbObject, sceneAction, animDict, "action_var_01_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phoneObject, sceneAction, animDict, "action_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)
    
    local sceneHack = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z, rotation.x, rotation.y, rotation.z, 2, false, true, 1.0, 0, 1.0)
    
    NetworkAddPedToSynchronisedScene(cache.ped, sceneHack, animDict, "hack_loop_var_01", 1000.0, -1.5, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbObject, sceneHack, animDict, "hack_loop_var_01_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phoneObject, sceneHack, animDict, "hack_loop_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)
    
    NetworkStartSynchronisedScene(sceneAction)
    Wait((GetAnimDuration(animDict, "action_var_01") * 1000) - 500)
    NetworkStartSynchronisedScene(sceneHack)
    
    local success = minigames.smartLock()
    
    local reactionScene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z, rotation.x, rotation.y, rotation.z, 2, false, false, 1.0, 0, 1.0)
    local reactionAnim = success and "success_react_exit_var_02" or "fail_react"
    
    NetworkAddPedToSynchronisedScene(cache.ped, reactionScene, animDict, reactionAnim, 1000.0, -1.5, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbObject, reactionScene, animDict, reactionAnim .. "_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phoneObject, reactionScene, animDict, reactionAnim .. "_prop_phone_ing", 1.0, -1.0, 1148846080)
    NetworkStartSynchronisedScene(reactionScene)
    
    if not success then
        local exitScene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z, rotation.x, rotation.y, rotation.z, 2, false, false, 1.0, 0, 1.0)
        NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "exit", 1000.0, -1.5, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(usbObject, exitScene, animDict, "exit_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
        NetworkAddEntityToSynchronisedScene(phoneObject, exitScene, animDict, "exit_prop_phone_ing", 1.0, -1.0, 1148846080)
        NetworkStartSynchronisedScene(exitScene)
        Wait((GetAnimDuration(animDict, "exit") * 1000) - 500)
    end
    
    DeleteEntity(usbObject)
    DeleteEntity(phoneObject)
    SetModelAsNoLongerNeeded(-1746470518)
    SetModelAsNoLongerNeeded(413312110)
    Wait(1000)
    FreeOccupiedSpot()
    
    if success then
        LR.notify(locale("disabled_smart_lock"), "success")
        TriggerServerEvent("lunar_contracts:cashexchange:disableSmartLock", currentLocationIndex)
    else
        LR.notify(locale("hack_failed"), "error")
    end
end

-- Disable other door locks (electric box hack)
local function disableOtherDoors()
    if cashexchangeConfig.electricBox.requiredItem and not Framework.hasItem(cashexchangeConfig.electricBox.requiredItem) then
        LR.notify(locale("missing_" .. cashexchangeConfig.electricBox.requiredItem), "error")
        return
    end
    
    if IsSpotOccupied("cashexchange:unlock_other_doors_" .. currentLocationIndex) then return end
    
    local location = cashexchangeConfig.locations[currentLocationIndex]
    local offsetCoords = Utils.offsetCoords(location.electricBox, -0.01, 0.03, 0.05)
    
    local gender = IsPedMale(cache.ped) and "male@" or "female@"
    local animDict = "anim_heist@hs3f@ig1_hack_keypad@arcade@" .. gender
    
    lib.requestModel(-1746470518)
    lib.requestModel(413312110)
    
    local usbObject = CreateSceneObject(-1746470518, offsetCoords)
    local phoneObject = CreateSceneObject(413312110, offsetCoords)
    local rotation = vector3(0.0, 0.0, offsetCoords.w)
    
    local sceneAction = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z, rotation.x, rotation.y, rotation.z, 2, true, false, 1.0, 0, 1.0)
    
    NetworkAddPedToSynchronisedScene(cache.ped, sceneAction, animDict, "action_var_01", 1000.0, -1.5, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbObject, sceneAction, animDict, "action_var_01_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phoneObject, sceneAction, animDict, "action_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)
    
    local sceneHack = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z, rotation.x, rotation.y, rotation.z, 2, false, true, 1.0, 0, 1.0)
    
    NetworkAddPedToSynchronisedScene(cache.ped, sceneHack, animDict, "hack_loop_var_01", 1000.0, -1.5, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbObject, sceneHack, animDict, "hack_loop_var_01_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phoneObject, sceneHack, animDict, "hack_loop_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)
    
    NetworkStartSynchronisedScene(sceneAction)
    Wait((GetAnimDuration(animDict, "action_var_01") * 1000) - 500)
    NetworkStartSynchronisedScene(sceneHack)
    
    local success = minigames.electricBox()
    
    local reactionScene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z, rotation.x, rotation.y, rotation.z, 2, false, false, 1.0, 0, 1.0)
    local reactionAnim = success and "success_react_exit_var_02" or "fail_react"
    
    NetworkAddPedToSynchronisedScene(cache.ped, reactionScene, animDict, reactionAnim, 1000.0, -1.5, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbObject, reactionScene, animDict, reactionAnim .. "_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phoneObject, reactionScene, animDict, reactionAnim .. "_prop_phone_ing", 1.0, -1.0, 1148846080)
    NetworkStartSynchronisedScene(reactionScene)
    
    if not success then
        local exitScene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z, rotation.x, rotation.y, rotation.z, 2, false, false, 1.0, 0, 1.0)
        NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "exit", 1000.0, -1.5, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(usbObject, exitScene, animDict, "exit_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
        NetworkAddEntityToSynchronisedScene(phoneObject, exitScene, animDict, "exit_prop_phone_ing", 1.0, -1.0, 1148846080)
        NetworkStartSynchronisedScene(exitScene)
        Wait((GetAnimDuration(animDict, "exit") * 1000) - 500)
    end
    
    DeleteEntity(usbObject)
    DeleteEntity(phoneObject)
    SetModelAsNoLongerNeeded(-1746470518)
    SetModelAsNoLongerNeeded(413312110)
    Wait(1000)
    FreeOccupiedSpot()
    
    if success then
        LR.notify(locale("disabled_locks"), "success")
        TriggerServerEvent("lunar_contracts:cashexchange:unlockOtherDoors", currentLocationIndex)
    else
        LR.notify(locale("hack_failed"), "error")
    end
end

-- Unlock vault
local function unlockVault()
    if cashexchangeConfig.unlockVault.requiredItem and not Framework.hasItem(cashexchangeConfig.unlockVault.requiredItem) then
        LR.notify(locale("missing_" .. cashexchangeConfig.unlockVault.requiredItem), "error")
        return
    end
    
    if IsSpotOccupied("cashexchange:unlock_vault") then return end
    
    local location = cashexchangeConfig.locations[currentLocationIndex]
    local vaultDoor = location.doors.vault[1]
    
    local vaultObj = GetClosestObjectOfType(vaultDoor.x, vaultDoor.y, vaultDoor.z, 2.0, cashexchangeConfig.doorModels.vault, false, false, false)
    
    local offset = cashexchangeConfig.unlockVault.offset or vector3(-0.07, 0.05, 0.05)
    local interactCoords = GetOffsetFromEntityInWorldCoords(vaultObj, offset.x, offset.y, offset.z)
    
    local rotation = GetEntityRotation(vaultObj)
    local rotationOffset = cashexchangeConfig.unlockVault.rotationOffset or 0.0
    local finalRotation = vector3(rotation.x, rotation.y, rotation.z + rotationOffset)
    
    lib.requestModel(-944468481)
    lib.requestModel(-411901183)
    lib.requestModel(-676527372)
    
    local animDict = "anim@heists@ornate_bank@hack"
    
    local bagObject = CreateSceneObject(-944468481, interactCoords)
    local cardObject = CreateSceneObject(-411901183, interactCoords)
    local laptopObject = CreateSceneObject(-676527372, interactCoords)
    
    local sceneEnter = NetworkCreateSynchronisedScene(interactCoords.x, interactCoords.y, interactCoords.z, finalRotation.x, finalRotation.y, finalRotation.z, 2, true, false, 1.0, 0, 1.0)
    
    NetworkAddPedToSynchronisedScene(cache.ped, sceneEnter, animDict, "hack_enter", 1.5, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bagObject, sceneEnter, animDict, "hack_enter_suit_bag", 1.0, -1.0, 0)
    NetworkAddEntityToSynchronisedScene(cardObject, sceneEnter, animDict, "hack_enter_card", 1.0, -1.0, 0)
    NetworkAddEntityToSynchronisedScene(laptopObject, sceneEnter, animDict, "hack_enter_laptop", 1.0, -1.0, 0)
    
    local sceneLoop = NetworkCreateSynchronisedScene(interactCoords.x, interactCoords.y, interactCoords.z, finalRotation.x, finalRotation.y, finalRotation.z, 2, false, true, 1.0, 0, 1.0)
    
    NetworkAddPedToSynchronisedScene(cache.ped, sceneLoop, animDict, "hack_loop", 1000.0, -1.5, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bagObject, sceneLoop, animDict, "hack_loop_suit_bag", 1.0, -1.0, 0)
    NetworkAddEntityToSynchronisedScene(cardObject, sceneLoop, animDict, "hack_loop_card", 1.0, -1.0, 0)
    NetworkAddEntityToSynchronisedScene(laptopObject, sceneLoop, animDict, "hack_loop_laptop", 1.0, -1.0, 0)
    
    local sceneExit = NetworkCreateSynchronisedScene(interactCoords.x, interactCoords.y, interactCoords.z, finalRotation.x, finalRotation.y, finalRotation.z, 2, true, false, 1.0, 0, 1.0)
    
    NetworkAddPedToSynchronisedScene(cache.ped, sceneExit, animDict, "hack_exit", 1000.0, -1.5, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bagObject, sceneExit, animDict, "hack_exit_suit_bag", 1.0, -1.0, 0)
    NetworkAddEntityToSynchronisedScene(cardObject, sceneExit, animDict, "hack_exit_card", 1.0, -1.0, 0)
    NetworkAddEntityToSynchronisedScene(laptopObject, sceneExit, animDict, "hack_exit_laptop", 1.0, -1.0, 0)
    
    NetworkStartSynchronisedScene(sceneEnter)
    Wait((GetAnimDuration(animDict, "hack_enter") * 1000) - 200)
    NetworkStartSynchronisedScene(sceneLoop)
    
    local success = minigames.unlockVault()
    
    if success then
        LR.notify(locale("vault_unlocks_in", cashexchangeConfig.unlockVault.delay), "success")
        TriggerServerEvent("lunar_contracts:cashexchange:unlockVault", currentLocationIndex)
    else
        LR.notify(locale("hack_failed"), "error")
    end
    
    NetworkStartSynchronisedScene(sceneExit)
    Wait((GetAnimDuration(animDict, "hack_exit") * 1000) - 500)
    
    DeleteEntity(bagObject)
    DeleteEntity(cardObject)
    DeleteEntity(laptopObject)
    SetModelAsNoLongerNeeded(-944468481)
    SetModelAsNoLongerNeeded(-411901183)
    SetModelAsNoLongerNeeded(-676527372)
    Wait(1000)
    FreeOccupiedSpot()
end

-- Smart lock disabled event (trigger alarm)
RegisterNetEvent("lunar_contracts:cashexchange:smartLockDisabled", function(locationIndex)
    local alarmCoords = cashexchangeConfig.locations[locationIndex].alarm
    local soundId = GetSoundId()
    
    local alarmZone = lib.points.new({
        coords = alarmCoords,
        distance = 200.0,
        onEnter = function()
            while not RequestScriptAudioBank("SCRIPT/ALARM_KLAXON_04", false) do Wait(0) end
            PlaySoundFromCoord(soundId, "Klaxon_04", alarmCoords.x, alarmCoords.y, alarmCoords.z, "ALARMS_SOUNDSET", false, 200.0, false)
        end,
        onExit = function()
            StopSound(soundId)
        end
    })
    
    SetTimeout(cashexchangeConfig.alarmDuration * 1000, function()
        alarmZone:onExit()
        alarmZone:remove()
    end)
    
    if currentLocationIndex == locationIndex then
        if startPanelPoint then
            startPanelPoint:remove()
            startPanelPoint = nil
        end
    end
end)

RegisterNetEvent("lunar_contracts:cashexchange:removeElectricBox", function(locationIndex)
    if currentLocationIndex == locationIndex and electricBoxPoint then
        electricBoxPoint:remove()
        electricBoxPoint = nil
    end
end)

RegisterNetEvent("lunar_contracts:cashexchange:removeVault", function(locationIndex)
    if currentLocationIndex == locationIndex and vaultPoint then
        vaultPoint:remove()
        vaultPoint = nil
    end
end)

-- Setup interaction points
-- Reset contract
local function resetContract()
    if startPanelPoint then
        startPanelPoint:remove()
        startPanelPoint = nil
    end
    if electricBoxPoint then
        electricBoxPoint:remove()
        electricBoxPoint = nil
    end
    if vaultPoint then
        vaultPoint:remove()
        vaultPoint = nil
    end
    if alarmBlip then
        alarmBlip:remove()
        alarmBlip = nil
    end
    
    currentLocationIndex = nil
end

-- Setup interaction points
local function setupInteractions(locationIndex)
    local location = cashexchangeConfig.locations[locationIndex]
    
    startPanelPoint = Utils.createInteractionPoint({
        coords = location.startPanel.coords,
        radius = 1.0,
        options = {{
            label = locale("disable_smart_lock"),
            icon = "code",
            onSelect = disableSmartLock,
            canInteract = function() return not Busy end
        }}
    })
    
    electricBoxPoint = Utils.createInteractionPoint({
        coords = location.electricBox,
        radius = 1.0,
        options = {{
            label = locale("disable_locks"),
            icon = "code",
            onSelect = disableOtherDoors,
            canInteract = function() return not Busy and not startPanelPoint end
        }}
    })
    
    local vaultCoords = location.doors.vault[1]
    local interactionOffset = cashexchangeConfig.unlockVault.interactionOffset
    if interactionOffset then
        vaultCoords = vector3(vaultCoords.x + interactionOffset.x, vaultCoords.y + interactionOffset.y, vaultCoords.z + interactionOffset.z)
    end
    
    vaultPoint = Utils.createInteractionPoint({
        coords = vaultCoords,
        radius = 1.0,
        options = {{
            label = locale("open_vault"),
            icon = "code",
            onSelect = unlockVault,
            canInteract = function() return not Busy and not startPanelPoint and not electricBoxPoint end
        }}
    })
    
    alarmBlip = Utils.createBlip(location.alarm, cashexchangeConfig.blip)
    SetBlipRoute(alarmBlip.value, true)
end

local function resetAndStart(locationIndex)
    resetContract()
    currentLocationIndex = locationIndex
    setupInteractions(locationIndex)
end

RegisterNetEvent("lunar_contracts:cashexchange:started", function(members, locationIndex)
    for _, memberId in ipairs(members) do
        if Framework.getIdentifier() == memberId then
            resetAndStart(locationIndex)
            LR.showObjective(locale("cashexchange_title"), locale("obj_go_to_exchange_from_back"))
        end
    end
end)

RegisterNetEvent("lunar_contracts:cashexchange:reset", function(locationIndex)
    if currentLocationIndex ~= locationIndex then return end
    
    if startPanelPoint then
        startPanelPoint:remove()
        startPanelPoint = nil
    end
    if electricBoxPoint then
        electricBoxPoint:remove()
        electricBoxPoint = nil
    end
    if vaultPoint then
        vaultPoint:remove()
        vaultPoint = nil
    end
    if alarmBlip then
        alarmBlip:remove()
        alarmBlip = nil
    end
    
    currentLocationIndex = nil
end)