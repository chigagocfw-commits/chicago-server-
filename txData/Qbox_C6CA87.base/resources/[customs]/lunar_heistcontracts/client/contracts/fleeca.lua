-- Preload animation dictionaries
PreloadDicts(
    "anim@heists@ornate_bank@thermal_charge",
    "anim@heists@ornate_bank@hack"
)

local Config = Config.contracts.fleeca
local minigames = Editable.minigames.fleeca

-- State variables
local currentLocation = nil
local entryDoorPoint = nil
local vaultPanelPoint = nil
local insideDoorPoint = nil
local depositBoxPoints = {}
local vaultDoorZones = {}
local blip = nil

-- Create props for each location
for locationIdx = 1, #Config.locations do
    local location = Config.locations[locationIdx]

    -- Create props
    for propIdx = 1, #Config.props do
        local prop = Config.props[propIdx]
        local propCoords = Utils.offsetCoords(location, prop.coords.x, prop.coords.y, prop.coords.z, prop.coords.w)

        Utils.createProp(propCoords, {
            model = prop.model,
            offset = vector3(0.0, 0.0, -1.0)
        })
    end

    -- Remove props on enter
    for removeIdx = 1, #Config.removeProps do
        local removeProp = Config.removeProps[removeIdx]
        local propCoords = Utils.offsetCoords(location, removeProp.coords.x, removeProp.coords.y, removeProp.coords.z)

        lib.points.new({
            coords = propCoords,
            distance = 30.0,
            onEnter = function()
                CreateModelHide(propCoords.x, propCoords.y, propCoords.z, 1.0, removeProp.model, true)
            end,
            onExit = function()
                RemoveModelHide(propCoords.x, propCoords.y, propCoords.z, 1.0, removeProp.model, true)
            end
        })
    end
end

-- Place thermite on entry door
local function placeThermite()
    if Config.doors.entry.requiredItem then
        if not Framework.hasItem(Config.doors.entry.requiredItem) then
            LR.notify(locale("missing_" .. Config.doors.entry.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied(string.format("fleeca:entry_%s", currentLocation)) then
        return
    end

    local animDict = "anim@heists@ornate_bank@thermal_charge"

    lib.requestModel(-944468481)
    lib.requestModel(865563579)

    local locationCoords = Config.locations[currentLocation]
    local offset = table.unpack(Config.doors.entry.offset)
    local sceneCoords = Utils.offsetCoords(locationCoords, offset[1], offset[2], offset[3], offset[4])
    local finalCoords = Utils.offsetCoords(sceneCoords, 0.0, -0.02, 0.0)
    sceneCoords = finalCoords

    local bag = CreateSceneObject(-944468481, sceneCoords)
    local thermalCharge = CreateSceneObject(865563579, sceneCoords)

    local scene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        0.0, 0.0, sceneCoords.w, 2, true, false, 1065353216, 0, 1065353216)

    SetEntityCollision(thermalCharge, false, false)

    NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, "thermal_charge", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bag, scene, animDict, "bag_thermal_charge", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(scene)

    AttachEntityToEntity(thermalCharge, cache.ped, GetPedBoneIndex(cache.ped, 28422), 0, 0, 0, 0, 0, 200.0, true, true, false, true, 1, true)

    Wait(4000)
    DetachEntity(thermalCharge, true, true)
    Wait(1800)

    SetEntityVisible(bag, false, false)

    local success = minigames.thermite()

    if not success then
        FreeOccupiedSpot()
        DeleteEntity(thermalCharge)
        DeleteEntity(bag)
        LR.notify(locale("thermite_failed"), "error")
        return
    end

    LR.notify(locale("thermite_success"), "success")

    local effectCoords = GetOffsetFromEntityInWorldCoords(thermalCharge, 0.0, 0.0, -1.0)
    local effectPos = vector4(effectCoords.x, effectCoords.y, effectCoords.z, sceneCoords.w)

    TriggerServerEvent("lunar_contracts:fleeca:syncEffect", currentLocation, effectPos)

    TaskPlayAnim(cache.ped, "anim@heists@ornate_bank@thermal_charge", "cover_eyes_loop", 1000.0, 3.0, 11000, 49, 1, false, false, false)

    DeleteEntity(bag)
    Wait(10200)
    DeleteEntity(thermalCharge)

    SetModelAsNoLongerNeeded(-944468481)
    SetModelAsNoLongerNeeded(865563579)

    LR.notify(locale("entry_door_unlocked"), "success")
    FreeOccupiedSpot()
end

-- Hack vault panel
local function hackVaultPanel()
    if Config.panels.requiredItem then
        if not Framework.hasItem(Config.panels.requiredItem) then
            LR.notify(locale("missing_" .. Config.panels.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied(string.format("fleeca:vault_%s", currentLocation)) then
        return
    end

    local animDict = "anim@heists@ornate_bank@hack"
    local sceneCoords = Utils.offsetCoords(Config.locations[currentLocation], 0.0, 0.0, 0.2)

    lib.requestModel(-944468481)
    lib.requestModel(-676527372)

    local bag = CreateSceneObject(-944468481, sceneCoords)
    local laptop = CreateSceneObject(-676527372, sceneCoords)

    -- Enter scene
    local enterScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        0.0, 0.0, sceneCoords.w, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, enterScene, animDict, "hack_enter", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bag, enterScene, animDict, "hack_enter_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, enterScene, animDict, "hack_enter_laptop", 1.0, -1.0, 1148846080)

    -- Loop scene
    local loopScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        0.0, 0.0, sceneCoords.w, 2, false, true, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "hack_loop", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bag, loopScene, animDict, "hack_loop_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, loopScene, animDict, "hack_loop_laptop", 1.0, -1.0, 1148846080)

    -- Exit scene
    local exitScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        0.0, 0.0, sceneCoords.w, 2, false, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "hack_exit", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bag, exitScene, animDict, "hack_exit_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, exitScene, animDict, "hack_exit_laptop", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(enterScene)
    Wait((GetAnimDuration(animDict, "hack_enter") * 1000) - 200)

    NetworkStartSynchronisedScene(loopScene)

    local success = minigames.unlockVault()

    if success then
        TriggerServerEvent("lunar_contracts:fleeca:openVault", currentLocation)
        LR.notify(locale("unlocked_vault"), "success")

        SetTimeout(5000, function()
            LR.notify(locale("vault_opens_in", Config.doors.vault.openDelay), "inform")
        end)
    else
        LR.notify(locale("hack_failed"), "error")
    end

    NetworkStartSynchronisedScene(exitScene)
    Wait((GetAnimDuration(animDict, "hack_exit") * 1000) - 500)

    DeleteEntity(bag)
    DeleteEntity(laptop)
    SetModelAsNoLongerNeeded(-944468481)
    SetModelAsNoLongerNeeded(-676527372)

    Wait(1000)
    FreeOccupiedSpot()
end

-- Hack inside door panel
local function hackInsideDoor()
    if Config.panels.requiredItem then
        if not Framework.hasItem(Config.panels.requiredItem) then
            LR.notify(locale("missing_" .. Config.panels.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied(string.format("fleeca:inside_door_%s", currentLocation)) then
        return
    end

    local animDict = "anim@heists@ornate_bank@hack"
    local panelOffset = Config.panels.offset
    local sceneCoords = Utils.offsetCoords(Config.locations[currentLocation], panelOffset.x, panelOffset.y, panelOffset.z + 0.2)

    lib.requestModel(-944468481)
    lib.requestModel(-676527372)

    local bag = CreateSceneObject(-944468481, sceneCoords)
    local laptop = CreateSceneObject(-676527372, sceneCoords)

    -- Enter scene
    local enterScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        0.0, 0.0, sceneCoords.w, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, enterScene, animDict, "hack_enter", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bag, enterScene, animDict, "hack_enter_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, enterScene, animDict, "hack_enter_laptop", 1.0, -1.0, 1148846080)

    -- Loop scene
    local loopScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        0.0, 0.0, sceneCoords.w, 2, false, true, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "hack_loop", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bag, loopScene, animDict, "hack_loop_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, loopScene, animDict, "hack_loop_laptop", 1.0, -1.0, 1148846080)

    -- Exit scene
    local exitScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        0.0, 0.0, sceneCoords.w, 2, false, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "hack_exit", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bag, exitScene, animDict, "hack_exit_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, exitScene, animDict, "hack_exit_laptop", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(enterScene)
    Wait((GetAnimDuration(animDict, "hack_enter") * 1000) - 200)

    NetworkStartSynchronisedScene(loopScene)

    local success = minigames.unlockInsideDoor()

    if success then
        LR.notify(locale("unlocked_door"), "success")
        TriggerServerEvent("lunar_contracts:fleeca:openInsideDoor", currentLocation)
    else
        LR.notify(locale("hack_failed"), "error")
    end

    NetworkStartSynchronisedScene(exitScene)
    Wait((GetAnimDuration(animDict, "hack_exit") * 1000) - 500)

    DeleteEntity(bag)
    DeleteEntity(laptop)
    SetModelAsNoLongerNeeded(-944468481)
    SetModelAsNoLongerNeeded(-676527372)

    Wait(1000)
    FreeOccupiedSpot()
end

-- Sync thermal effect
RegisterNetEvent("lunar_contracts:fleeca:syncEffect", function(locationIndex, effectCoords)
    if currentLocation == locationIndex and entryDoorPoint then
        entryDoorPoint.remove()
        entryDoorPoint = nil
    end

    SetTimeout(1000, function()
        local soundId = GetSoundId()
        local alarmCoords = Utils.offsetCoords(Config.locations[locationIndex], 0.0, 0.0, 1.0)

        local alarmPoint = lib.points.new({
            coords = alarmCoords,
            distance = 200.0,
            onEnter = function()
                while true do
                    if RequestScriptAudioBank("SCRIPT/ALARM_KLAXON_04", false) then
                        break
                    end
                    Wait(0)
                end
                PlaySoundFromCoord(soundId, "Klaxon_04", alarmCoords.x, alarmCoords.y, alarmCoords.z, "ALARMS_SOUNDSET", false, 200.0, false)
            end,
            onExit = function()
                StopSound(soundId)
            end
        })

        SetTimeout(Config.alarmDuration * 1000, function()
            alarmPoint:onExit()
            alarmPoint.remove()
        end)
    end)

    lib.requestNamedPtfxAsset("scr_ornate_heist")
    UseParticleFxAssetNextCall("scr_ornate_heist")

    local particleFx = StartParticleFxLoopedAtCoord("scr_heist_ornate_thermal_burn",
        effectCoords.x, effectCoords.y, effectCoords.z,
        0.0, 0.0, effectCoords.w, 1.0, false, false, false, false)

    Wait(10000)
    StopParticleFxLooped(particleFx, false)
end)

-- Open vault door
local vaultDoorRotated = {}

RegisterNetEvent("lunar_contracts:fleeca:openVault", function(locationIndex)
    local delay = Config.doors.vault.openDelay * 1000 + 5000

    if currentLocation == locationIndex and vaultPanelPoint then
        vaultPanelPoint.remove()
        vaultPanelPoint = nil

        SetTimeout(delay, function()
            vaultPanelPoint = nil
        end)
    end

    Wait(delay)

    local doorOffset = table.unpack(Config.doors.vault.offset)
    local doorCoords = Utils.offsetCoords(Config.locations[locationIndex], doorOffset[1], doorOffset[2], doorOffset[3], doorOffset[4])
    local doorObj = GetClosestObjectOfType(doorCoords.x, doorCoords.y, doorCoords.z, 2.0, Config.doors.vault.model, false, false, false)

    local rotatedDoors = {}

    if DoesEntityExist(doorObj) then
        for i = 1, 2000 do
            local currentHeading = GetEntityHeading(doorObj)
            SetEntityHeading(doorObj, currentHeading + (Config.doors.vault.openAngleDiff / 2000))
            Wait(10)
        end
        rotatedDoors[doorObj] = true
    end

    vaultDoorZones[locationIndex] = lib.points.new({
        coords = doorCoords.xyz,
        distance = 30.0,
        onEnter = function()
            local obj = GetClosestObjectOfType(doorCoords.x, doorCoords.y, doorCoords.z, 2.0, Config.doors.vault.model, false, false, false)
            if DoesEntityExist(obj) and not rotatedDoors[obj] then
                local heading = GetEntityHeading(obj)
                SetEntityHeading(obj, heading + Config.doors.vault.openAngleDiff)
                rotatedDoors[obj] = true
            end
        end
    })
end)

-- Remove inside panel
RegisterNetEvent("lunar_contracts:fleeca:removeInsidePanel", function(locationIndex)
    if currentLocation ~= locationIndex then
        return
    end

    if insideDoorPoint then
        insideDoorPoint.remove()
        insideDoorPoint = nil
    end
end)

-- Remove deposit box
RegisterNetEvent("lunar_contracts:fleeca:removeDepositBox", function(locationIndex, boxIndex)
    if currentLocation ~= locationIndex then
        return
    end

    if depositBoxPoints[boxIndex] then
        depositBoxPoints[boxIndex].remove()
        depositBoxPoints[boxIndex] = nil
    end
end)

-- Initialize contract
local function initializeContract(locationIndex)
    local location = Config.locations[locationIndex]

    -- Entry door point
    if not Config.doors.entry.disabled then
        local doorOffset = table.unpack(Config.doors.entry.offset)
        local doorCoords = Utils.offsetCoords(Config.locations[currentLocation], doorOffset[1], doorOffset[2], doorOffset[3], doorOffset[4])

        entryDoorPoint = Utils.createInteractionPoint({
            coords = doorCoords,
            radius = 1.0,
            options = {{
                label = locale("place_thermite"),
                icon = "door-closed",
                onSelect = placeThermite,
                canInteract = function() return not Busy end
            }}
        })
    end

    -- Vault panel point
    vaultPanelPoint = Utils.createInteractionPoint({
        coords = location,
        radius = 1.0,
        options = {{
            label = locale("unlock_vault"),
            icon = "code",
            onSelect = hackVaultPanel,
            canInteract = function() return not (Busy or entryDoorPoint) end
        }}
    })

    -- Inside door panel point
    local panelOffset = Config.panels.offset
    local panelCoords = Utils.offsetCoords(location, panelOffset.x, panelOffset.y, panelOffset.z)

    insideDoorPoint = Utils.createInteractionPoint({
        coords = panelCoords,
        radius = 1.0,
        options = {{
            label = locale("unlock_door"),
            icon = "code",
            onSelect = hackInsideDoor,
            canInteract = function() return not (Busy or vaultPanelPoint) end
        }}
    })

    -- Deposit box drilling points
    for boxIndex = 1, #Config.drilling.locations do
        local boxLocation = Config.drilling.locations[boxIndex]
        local boxCoords = Utils.offsetCoords(location, boxLocation.x, boxLocation.y, boxLocation.z, boxLocation.w)

        depositBoxPoints[boxIndex] = Utils.createInteractionPoint({
            coords = boxCoords,
            radius = 1.0,
            options = {{
                label = locale("drill_deposit_box"),
                icon = "sack-dollar",
                onSelect = function()
                    if Config.drilling.requiredItem then
                        if not Framework.hasItem(Config.drilling.requiredItem) then
                            LR.notify(locale("missing_" .. Config.drilling.requiredItem), "error")
                            return
                        end
                    end

                    if IsSpotOccupied(string.format("fleeca:drilling_%s", boxIndex)) then
                        return
                    end

                    local canDrill = lib.callback.await("lunar_contracts:fleeca:canDrillDepositBox", false, currentLocation, boxIndex)
                    if not canDrill then
                        FreeOccupiedSpot()
                        return
                    end

                    local drillOffset = Utils.offsetCoords(boxCoords, 0.2, 0.0, -0.11)
                    local success = StartDrilling(drillOffset)

                    if success then
                        TriggerServerEvent("lunar_contracts:fleeca:drillDepositBox", currentLocation, boxIndex)
                    end

                    FreeOccupiedSpot()
                end,
                canInteract = function()
                    return not (Busy or vaultPanelPoint) and Utils.distanceCheck(cache.ped, boxCoords.xyz, 1.0)
                end
            }}
        })
    end

    -- Entry door coords for blip
    local entryOffset = table.unpack(Config.doors.entry.offset)
    local blipCoords = Utils.offsetCoords(Config.locations[currentLocation], entryOffset[1], entryOffset[2], entryOffset[3], entryOffset[4])

    blip = Utils.createBlip(blipCoords, Config.blip)
    SetBlipRoute(blip.value, true)

    Utils.distanceWait(blipCoords, 30.0)
    blip.remove()
end

-- Reset contract
local function resetContract(locationIndex)
    if currentLocation ~= locationIndex then
        return
    end

    if entryDoorPoint then
        entryDoorPoint.remove()
        entryDoorPoint = nil
    end

    if vaultPanelPoint then
        vaultPanelPoint.remove()
        vaultPanelPoint = nil
    end

    if insideDoorPoint then
        insideDoorPoint.remove()
        insideDoorPoint = nil
    end

    for idx, point in pairs(depositBoxPoints) do
        point.remove()
        depositBoxPoints[idx] = nil
    end

    if vaultDoorZones[locationIndex] then
        vaultDoorZones[locationIndex].remove()
        vaultDoorZones[locationIndex] = nil
    end

    if blip then
        blip.remove()
        blip = nil
    end

    currentLocation = nil
end

-- Wait for reset
local function waitForReset()
    if not currentLocation then
        return
    end

    TriggerEvent("lunar_contracts:fleeca:reset", currentLocation)

    while currentLocation do
        Wait(100)
    end
end

-- Start contract
RegisterNetEvent("lunar_contracts:fleeca:started", function(players, locationIndex)
    for _, playerId in ipairs(players) do
        if Framework.getIdentifier() == playerId then
            waitForReset()
            currentLocation = locationIndex
            initializeContract(locationIndex)
            return
        end
    end
end)

-- Reset contract
RegisterNetEvent("lunar_contracts:fleeca:reset", function(locationIndex)
    if currentLocation ~= locationIndex then
        return
    end
    resetContract(locationIndex)
end)

-- Helper function to format vectors (for debugging)
local function formatVectors(vectors)
    local result = ""
    for _, vec in ipairs(vectors) do
        local formatStr = vec.w and "vector4(%.8f, %.8f, %.8f, %.8f),\n" or "vector3(%.8f, %.8f, %.8f),\n"
        result = result .. formatStr:format(vec.x, vec.y, vec.z, vec.w)
    end
    return result
end

-- Debug function to copy position to clipboard
local function copyPositionToClipboard()
    local obj = 8755202
    local coords = GetEntityCoords(obj)
    local pos = vector4(coords.x, coords.y, coords.z, GetEntityHeading(obj))
    lib.setClipboard(tostring(pos))
end

-- Sample vectors (kept for reference)
local sampleVectors = {
    vector3(3.35255003, -1.51019967, -0.06079865),
    vector3(-0.53442669, -1.50575030, -0.09355068),
    vector3(-3.04553461, -0.12364487, 0.01667404),
    vector3(-1.72191715, -0.37155154, 0.01645660),
    vector4(-4.15483332, -1.32051313, -0.20012951, -90.54205322),
    vector4(-1.09726119, 3.31316924, -0.20012951, -231.93424988),
    vector4(-1.19558799, 0.63045835, -0.20012951, 45.33004761),
    vector4(-3.18608308, 3.52774024, -0.20012951, -180.54205322),
    vector4(-4.59074354, 2.01884556, -0.35062885, 89.45794678),
    vector4(-0.53724456, 1.98195720, 0.12397003, -90.54205322),
    vector4(-2.37841201, -2.73317814, 0.12497139, -180.54205322),
    vector4(-4.62180853, 1.98183489, -0.20012951, -90.54205322),
    vector3(-4.14793825, 2.89802003, -0.56009102),
    vector3(-4.29339170, 1.31317520, -0.56009102),
    vector3(-1.50950301, 2.81285167, -0.55828094),
    vector3(-4.02510691, -1.79512274, -0.97770786)
}