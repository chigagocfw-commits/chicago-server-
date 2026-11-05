-- Preload animation dictionaries
PreloadDicts(
    "anim_heist@hs3f@ig1_hack_keypad@arcade@male@",
    "anim_heist@hs3f@ig1_hack_keypad@arcade@female@",
    "anim_heist@arcade_property@arcade_safe_open@male",
    "anim_heist@arcade_property@arcade_safe_open@female"
)

local Config = Config.contracts.laundromat
local minigames = Editable.minigames.laundromat

-- State variables
local isContractActive = false
local generatorPoint = nil
local lootPoints = {}
local electricBoxPoint = nil
local safePoint = nil
local safeOpen = false
local blip = nil

-- Cut generator power (main hack)
local function cutGeneratorPower()
    if Config.generator.requiredItem then
        if not Framework.hasItem(Config.generator.requiredItem) then
            LR.notify(locale("missing_" .. Config.generator.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied("laundromat:start_panel") then
        return
    end

    local sceneCoords = Utils.offsetCoords(Config.generator.coords, -0.11, 0.05, 0.05)
    local animDict = "anim_heist@hs3f@ig1_hack_keypad@arcade@" .. (IsPedMale(cache.ped) and "male@" or "female@")

    lib.requestModel(-1746470518)
    lib.requestModel(413312110)

    local usbDrive = CreateSceneObject(-1746470518, sceneCoords)
    local phone = CreateSceneObject(413312110, sceneCoords)
    local rotation = vector3(0.0, 0.0, sceneCoords.w)

    -- Intro scene
    local introScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, introScene, animDict, "action_var_01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbDrive, introScene, animDict, "action_var_01_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phone, introScene, animDict, "action_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)

    -- Loop scene
    local loopScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, true, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "hack_loop_var_01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbDrive, loopScene, animDict, "hack_loop_var_01_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phone, loopScene, animDict, "hack_loop_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(introScene)
    Wait((GetAnimDuration(animDict, "action_var_01") * 1000) - 500)

    NetworkStartSynchronisedScene(loopScene)

    local success = minigames.cutGenerator()

    if success then
        LR.notify(locale("cutted_generator"), "success")
        TriggerServerEvent("lunar_contracts:laundromat:cutGeneratorPower")
    else
        LR.notify(locale("hack_failed"), "error")
    end

    -- Reaction scene
    local reactionScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)

    local reactionAnim = success and "success_react_exit_var_02" or "fail_react"

    NetworkAddPedToSynchronisedScene(cache.ped, reactionScene, animDict, reactionAnim, -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbDrive, reactionScene, animDict, reactionAnim .. "_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phone, reactionScene, animDict, reactionAnim .. "_prop_phone_ing", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(reactionScene)
    Wait((GetAnimDuration(animDict, reactionAnim) * 1000) - 500)

    -- Exit animation on failure
    if not success then
        local exitScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
            rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)

        NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "exit", -4.0, -4.0, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(usbDrive, exitScene, animDict, "exit_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
        NetworkAddEntityToSynchronisedScene(phone, exitScene, animDict, "exit_prop_phone_ing", 1.0, -1.0, 1148846080)

        NetworkStartSynchronisedScene(exitScene)
        Wait((GetAnimDuration(animDict, "exit") * 1000) - 500)
    end

    DeleteEntity(usbDrive)
    DeleteEntity(phone)
    SetModelAsNoLongerNeeded(-1746470518)
    SetModelAsNoLongerNeeded(413312110)
    Wait(1000)
    FreeOccupiedSpot()
end

-- Loot item
local function lootItem(lootIndex)
    if IsSpotOccupied(string.format("laundromat:loot_%s", lootIndex)) then
        return
    end

    local animDict = "missheist_jewel"
    local animClip = "smash_case"

    lib.requestAnimDict(animDict)
    Utils.makeEntityFaceCoords(cache.ped, Config.loot.locations[lootIndex])

    local success = minigames.loot()

    if success then
        TriggerServerEvent("lunar_contracts:laundromat:takeLoot", lootIndex)
        TaskPlayAnim(cache.ped, animDict, animClip, 8.0, 3.0, -1, 1, 1.0, false, false, false)
        Wait(2500)
        StopAnimTask(cache.ped, animDict, animClip, 3.0)
    end

    RemoveAnimDict(animDict)
    Wait(500)
    FreeOccupiedSpot()
end

-- Disable power (office door hack)
local function disableOfficePower()
    if Config.office.electricBox.requiredItem then
        if not Framework.hasItem(Config.office.electricBox.requiredItem) then
            LR.notify(locale("missing_" .. Config.office.electricBox.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied("laundromat:disable_power") then
        return
    end

    local sceneCoords = Utils.offsetCoords(Config.office.electricBox.coords, 0.1, 0.1, 0.0)
    local animDict = "anim_heist@hs3f@ig1_hack_keypad@arcade@" .. (IsPedMale(cache.ped) and "male@" or "female@")

    lib.requestModel(-1746470518)
    lib.requestModel(413312110)

    local usbDrive = CreateSceneObject(-1746470518, sceneCoords)
    local phone = CreateSceneObject(413312110, sceneCoords)
    local rotation = vector3(0.0, 0.0, sceneCoords.w)

    -- Intro scene
    local introScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, introScene, animDict, "action_var_01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbDrive, introScene, animDict, "action_var_01_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phone, introScene, animDict, "action_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)

    -- Loop scene
    local loopScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, true, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "hack_loop_var_01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbDrive, loopScene, animDict, "hack_loop_var_01_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phone, loopScene, animDict, "hack_loop_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(introScene)

    -- Hide USB drive after 2.5 seconds
    SetTimeout(2500, function()
        SetEntityVisible(usbDrive, false)
    end)

    Wait((GetAnimDuration(animDict, "action_var_01") * 1000) - 500)

    NetworkStartSynchronisedScene(loopScene)

    local success = minigames.disablePower()

    if success then
        LR.notify(locale("overriden_door"), "success")
        TriggerServerEvent("lunar_contracts:laundromat:unlockOfficeDoor")
    else
        LR.notify(locale("hack_failed"), "error")
    end

    -- Reaction scene
    local reactionScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)

    local reactionAnim = success and "success_react_exit_var_02" or "fail_react"

    NetworkAddPedToSynchronisedScene(cache.ped, reactionScene, animDict, reactionAnim, -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbDrive, reactionScene, animDict, reactionAnim .. "_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phone, reactionScene, animDict, reactionAnim .. "_prop_phone_ing", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(reactionScene)

    -- Show USB drive again after 1.5 seconds
    SetTimeout(1500, function()
        SetEntityVisible(usbDrive, true)
    end)

    Wait((GetAnimDuration(animDict, reactionAnim) * 1000) - 500)

    -- Exit animation on failure
    if not success then
        local exitScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
            rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)

        NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "exit", -4.0, -4.0, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(usbDrive, exitScene, animDict, "exit_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
        NetworkAddEntityToSynchronisedScene(phone, exitScene, animDict, "exit_prop_phone_ing", 1.0, -1.0, 1148846080)

        NetworkStartSynchronisedScene(exitScene)
        Wait((GetAnimDuration(animDict, "exit") * 1000) - 500)
    end

    DeleteEntity(usbDrive)
    DeleteEntity(phone)
    SetModelAsNoLongerNeeded(-1746470518)
    SetModelAsNoLongerNeeded(413312110)
    Wait(1000)
    FreeOccupiedSpot()
end

-- Safe open state
local safeShouldOpen = false

RegisterNetEvent("lunar_contracts:laundromat:setSafeOpen", function()
    safeShouldOpen = true
end)

-- Safe rotation handling
local safeCoords = Config.office.safe.coords
local safeRotated = {}

SetInterval(function()
    if not Utils.distanceCheck(cache.ped, safeCoords, 30.0) then
        return
    end

    local safeObj = GetClosestObjectOfType(safeCoords.x, safeCoords.y, safeCoords.z, 1.0,
        Config.office.safe.model, false, false, false)

    if not DoesEntityExist(safeObj) then
        return
    end

    if safeShouldOpen then
        if not safeRotated[safeObj] then
            SetEntityHeading(safeObj, GetEntityHeading(safeObj) + 90.0)
            safeRotated[safeObj] = true
        end
    else
        if safeRotated[safeObj] then
            SetEntityHeading(safeObj, GetEntityHeading(safeObj) - 90.0)
            safeRotated[safeObj] = nil
        end
    end
end, 1000)

-- Lockpick safe
local function lockpickSafe()
    if IsSpotOccupied("laundromat:safe") then
        return
    end

    local success = minigames.unlockSafe()

    if success then
        LR.notify(locale("opened_safe"), "success")
        TriggerServerEvent("lunar_contracts:laundromat:openSafe")
    else
        LR.notify(locale("lockpick_failed"), "error")
    end

    FreeOccupiedSpot()
end

-- Power disabled event (spawns loot and electric box)
RegisterNetEvent("lunar_contracts:laundromat:powerDisabled", function()
    local soundId = GetSoundId()
    local alarmCoords = Config.alarm.coords

    -- Play alarm
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

    SetTimeout(Config.alarm.duration * 1000, function()
        alarmPoint:onExit()
        alarmPoint.remove()
    end)

    -- Remove generator point
    if generatorPoint then
        generatorPoint.remove()
        generatorPoint = nil
    end

    -- Create loot points
    for i = 1, #Config.loot.locations do
        lootPoints[#lootPoints + 1] = Utils.createInteractionPoint({
            coords = Config.loot.locations[i],
            radius = 1.0,
            options = {{
                label = locale("loot_coins"),
                icon = "coins",
                onSelect = lootItem,
                args = i,
                canInteract = function() return not Busy end
            }}
        })
    end

    -- Create electric box point
    electricBoxPoint = Utils.createInteractionPoint({
        coords = Config.office.electricBox.coords,
        radius = 1.0,
        options = {{
            label = locale("disable_power"),
            icon = "code",
            onSelect = disableOfficePower,
            args = index,
            canInteract = function() return not Busy end
        }}
    })

    -- Create safe point
    safePoint = Utils.createInteractionPoint({
        coords = Config.office.safe.coords,
        radius = 1.0,
        options = {
            {
                label = locale("lockpick_safe"),
                icon = "vault",
                onSelect = lockpickSafe,
                canInteract = function() return not (Busy or electricBoxPoint or safeOpen) end
            },
            {
                label = locale("take_safe_loot"),
                icon = "vault",
                onSelect = function()
                    if IsSpotOccupied("laundromat:safe") then
                        return
                    end
                    TriggerServerEvent("lunar_contracts:laundromat:openSafe")
                    FreeOccupiedSpot()
                end,
                canInteract = function() return not (Busy or electricBoxPoint or not safeOpen) end
            }
        }
    })
end)

-- Remove loot point
RegisterNetEvent("lunar_contracts:laundromat:removeLoot", function(lootIndex)
    if not isContractActive then
        return
    end

    if lootPoints[lootIndex] then
        lootPoints[lootIndex].remove()
        lootPoints[lootIndex] = nil
    end
end)

-- Remove electric box
RegisterNetEvent("lunar_contracts:laundromat:removeElectricBox", function()
    if not electricBoxPoint then
        return
    end
    electricBoxPoint.remove()
    electricBoxPoint = nil
end)

-- Set safe as lootable
RegisterNetEvent("lunar_contracts:laundromat:setSafeAsLootable", function()
    if not safePoint then
        return
    end
    safeOpen = true
end)

-- Remove safe
RegisterNetEvent("lunar_contracts:laundromat:removeSafe", function()
    if not safePoint then
        return
    end
    safePoint.remove()
    safePoint = nil
end)

-- Initialize contract
local function initializeContract()
    isContractActive = true

    -- Generator point
    generatorPoint = Utils.createInteractionPoint({
        coords = Config.generator.coords,
        radius = 1.0,
        options = {{
            label = locale("cut_generator"),
            icon = "bolt",
            onSelect = cutGeneratorPower,
            canInteract = function() return not Busy end
        }}
    })

    -- Blip
    blip = Utils.createBlip(Config.blip.coords, Config.blip)
    SetBlipRoute(blip.value, true)
    Utils.distanceWait(Config.blip.coords, 30.0)
    blip.remove()
end

-- Contract start event
RegisterNetEvent("lunar_contracts:laundromat:started", function(players)
    local identifier = Framework.getIdentifier()
    for _, playerId in ipairs(players) do
        if identifier == playerId then
            initializeContract()
        end
    end
end)

-- Reset contract
RegisterNetEvent("lunar_contracts:laundromat:reset", function()
    safeShouldOpen = false

    if not isContractActive then
        return
    end

    if generatorPoint then
        generatorPoint.remove()
        generatorPoint = nil
    end

    if electricBoxPoint then
        electricBoxPoint.remove()
        electricBoxPoint = nil
    end

    if safePoint then
        safePoint.remove()
        safePoint = nil
    end

    for _, point in pairs(lootPoints) do
        if point then point.remove() end
    end
    table.wipe(lootPoints)

    if blip then
        blip.remove()
        blip = nil
    end

    isContractActive = false
end)