-- Preload animation dictionaries
PreloadDicts(
    "anim_heist@hs3f@ig1_hack_keypad@arcade@male@",
    "anim_heist@hs3f@ig1_hack_keypad@arcade@female@",
    "anim@heists@ornate_bank@hack",
    "anim@scripted@player@mission@tun_control_tower@male@",
    "anim@gangops@morgue@office@laptop@",
    "anim_heist@arcade_property@arcade_safe_open@male",
    "anim_heist@arcade_property@arcade_safe_open@female"
)

local CameraSettings = Config.cameraSettings
local Config = Config.contracts.artasylum
local minigames = Editable.minigames.artasylum

-- State variables
local isContractActive = false
local keypadPoints = {}
local securityDoorPoints = {}
local electricBoxPoint = nil
local decryptionMainPoint = nil
local officeComputerPoints = {}
local vaultKeypadPoints = {}
local safePoint = nil
local paintingPoints = {}
local cameraPoints = {}
local sewerDoorPoints = {}

local disabledSensors = {}
local safeOpen = false
local alertLevel = 0.0
local alertTimer = nil
local paintingRemovalZones = {}
local blip = nil

-- Create model hide zones for remove props
for i = 1, #Config.removeProps do
    local prop = Config.removeProps[i]
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

-- Hack keypad door
local function hackKeypadDoor(doorIndex)
    if Config.keypadDoors.requiredItem then
        if not Framework.hasItem(Config.keypadDoors.requiredItem) then
            LR.notify(locale("missing_" .. Config.keypadDoors.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied(string.format("artasylum:keypad_%s", doorIndex)) then
        return
    end

    local playerCoords = GetEntityCoords(cache.ped)
    local closestKeypad = nil
    local closestDistance = math.huge

    for i = 1, #Config.keypadDoors.locations[doorIndex].keypads do
        local keypad = Config.keypadDoors.locations[doorIndex].keypads[i]
        local distance = #(keypad.xyz - playerCoords)
        if closestDistance > distance then
            closestDistance = distance
            closestKeypad = keypad
        end
    end

    local sceneCoords = Utils.offsetCoords(closestKeypad, 0.0, -0.1, -0.1)
    local animDict = "anim_heist@hs3f@ig1_hack_keypad@arcade@" .. (IsPedMale(cache.ped) and "male@" or "female@")

    lib.requestModel(-1746470518)
    lib.requestModel(413312110)

    local phone = CreateSceneObject(413312110, sceneCoords)
    local rotation = vector3(0.0, 0.0, sceneCoords.w)

    -- Intro scene
    local introScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, introScene, animDict, "action_var_01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(phone, introScene, animDict, "action_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)

    -- Loop scene
    local loopScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, true, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "hack_loop_var_01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(phone, loopScene, animDict, "hack_loop_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(introScene)

    SetTimeout(2500, function()
        SetEntityVisible(usb, false)
    end)

    Wait((GetAnimDuration(animDict, "action_var_01") * 1000) - 500)

    NetworkStartSynchronisedScene(loopScene)

    local success = minigames.keypad()

    if success then
        LR.notify(locale("unlocked_door"), "success")
        TriggerServerEvent("lunar_contracts:artasylum:openKeypadDoor", doorIndex)
    else
        LR.notify(locale("hack_failed"), "error")
    end

    -- Reaction scene
    local reactionScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)

    local reactionAnim = success and "success_react_exit_var_02" or "fail_react"

    NetworkAddPedToSynchronisedScene(cache.ped, reactionScene, animDict, reactionAnim, -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(phone, reactionScene, animDict, reactionAnim .. "_prop_phone_ing", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(reactionScene)

    SetTimeout(1500, function()
        SetEntityVisible(usb, true)
    end)

    Wait((GetAnimDuration(animDict, reactionAnim) * 1000) - 500)

    -- Exit animation on failure
    if not success then
        local exitScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
            rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)

        NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "exit", -4.0, -4.0, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(phone, exitScene, animDict, "exit_prop_phone_ing", 1.0, -1.0, 1148846080)

        NetworkStartSynchronisedScene(exitScene)
        Wait((GetAnimDuration(animDict, "exit") * 1000) - 500)
    end

    DeleteEntity(phone)
    SetModelAsNoLongerNeeded(-1746470518)
    SetModelAsNoLongerNeeded(413312110)

    Wait(1000)
    FreeOccupiedSpot()
end

-- Hack security door
local function hackSecurityDoor(doorIndex)
    if Config.securityDoors.requiredItem then
        if not Framework.hasItem(Config.securityDoors.requiredItem) then
            LR.notify(locale("missing_" .. Config.securityDoors.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied(string.format("artasylum:security_door_%s", doorIndex)) then
        return
    end

    local animDict = "anim@heists@ornate_bank@hack"
    local doorConfig = Config.securityDoors.locations[doorIndex]
    local doorCoords = GetDoorCoords(doorConfig)
    local doorModel = doorConfig.model or doorConfig[1].model

    local doorObj = GetClosestObjectOfType(doorCoords.x, doorCoords.y, doorCoords.z, 2.0, doorModel, false, false, false)

    local pos1 = GetOffsetFromEntityInWorldCoords(doorObj, 0.0, 0.25, 0.0)
    local pos2 = GetOffsetFromEntityInWorldCoords(doorObj, 0.0, -0.25, 0.0)

    local playerCoords = GetEntityCoords(cache.ped)
    local isLeftSide = #(playerCoords - pos1) < #(playerCoords - pos2)

    local sceneCoords = GetOffsetFromEntityInWorldCoords(doorObj, isLeftSide and 1.01 or 1.185, 0.0, 0.3)

    lib.requestModel(-944468481)
    lib.requestModel(-411901183)
    lib.requestModel(-676527372)

    local suitBag = CreateSceneObject(-944468481, sceneCoords)
    local keycard = CreateSceneObject(-411901183, sceneCoords)
    local laptop = CreateSceneObject(-676527372, sceneCoords)

    local rotation = GetEntityRotation(doorObj)
    if isLeftSide then
        rotation = vector3(rotation.x, rotation.y, rotation.z + 180.0)
    end

    -- Enter scene
    local enterScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, enterScene, animDict, "hack_enter", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(suitBag, enterScene, animDict, "hack_enter_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(keycard, enterScene, animDict, "hack_enter_card", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, enterScene, animDict, "hack_enter_laptop", 1.0, -1.0, 1148846080)

    -- Loop scene
    local loopScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, true, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "hack_loop", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(suitBag, loopScene, animDict, "hack_loop_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(keycard, loopScene, animDict, "hack_loop_card", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, loopScene, animDict, "hack_loop_laptop", 1.0, -1.0, 1148846080)

    -- Exit scene
    local exitScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "hack_exit", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(suitBag, exitScene, animDict, "hack_exit_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(keycard, exitScene, animDict, "hack_exit_card", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, exitScene, animDict, "hack_exit_laptop", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(enterScene)
    Wait((GetAnimDuration(animDict, "hack_enter") * 1000) - 200)

    NetworkStartSynchronisedScene(loopScene)

    local success = minigames.securityDoor()

    if success then
        TriggerServerEvent("lunar_contracts:artasylum:openSecurityDoor", doorIndex)
        LR.notify(locale("hacked_door"), "success")
    else
        LR.notify(locale("hack_failed"), "error")
    end

    NetworkStartSynchronisedScene(exitScene)
    Wait((GetAnimDuration(animDict, "hack_exit") * 1000) - 500)

    DeleteEntity(suitBag)
    DeleteEntity(keycard)
    DeleteEntity(laptop)

    SetModelAsNoLongerNeeded(-944468481)
    SetModelAsNoLongerNeeded(-411901183)
    SetModelAsNoLongerNeeded(-676527372)

    Wait(1000)
    FreeOccupiedSpot()
end

-- Disable locks via electric box
local function disableLocks()
    if Config.genericDoors.electricBox.requiredItem then
        if not Framework.hasItem(Config.genericDoors.electricBox.requiredItem) then
            LR.notify(locale("missing_" .. Config.genericDoors.electricBox.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied("artasylum:disable_locks") then
        return
    end

    local animDict = "anim@scripted@player@mission@tun_control_tower@male@"
    local boxCoords = Config.genericDoors.electricBox.coords.xyz
    local boxModel = Config.genericDoors.electricBox.model

    local boxObj = GetClosestObjectOfType(boxCoords.x, boxCoords.y, boxCoords.z, 2.0, boxModel, false, false, false)
    local objCoords = GetEntityCoords(boxObj)
    local rotation = GetEntityRotation(boxObj)

    -- Enter scene
    local enterScene = NetworkCreateSynchronisedScene(objCoords.x, objCoords.y, objCoords.z,
        rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, enterScene, animDict, "enter", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(boxObj, enterScene, animDict, "enter_electric_box", 1.0, -1.0, 1148846080)

    -- Loop scene
    local loopScene = NetworkCreateSynchronisedScene(objCoords.x, objCoords.y, objCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, true, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "loop", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(boxObj, loopScene, animDict, "loop_electric_box", 1.0, -1.0, 1148846080)

    -- Exit scene
    local exitScene = NetworkCreateSynchronisedScene(objCoords.x, objCoords.y, objCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "exit", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(boxObj, exitScene, animDict, "exit_electric_box", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(enterScene)
    Wait((GetAnimDuration(animDict, "enter") * 1000) - 200)

    NetworkStartSynchronisedScene(loopScene)

    local success = minigames.electricBox()

    if success then
        TriggerServerEvent("lunar_contracts:artasylum:disableLocks")
        LR.notify(locale("disabled_locks"), "success")
    else
        LR.notify(locale("hack_failed"), "error")
    end

    NetworkStartSynchronisedScene(exitScene)
    Wait((GetAnimDuration(animDict, "exit") * 1000) - 500)

    NetworkStopSynchronisedScene(exitScene)
    NetworkStopSynchronisedScene(loopScene)
    FreezeEntityPosition(boxObj, true)
    Wait(1000)
    FreeOccupiedSpot()
end

-- Decryption activated event
RegisterNetEvent("lunar_contracts:artasylum:decryptionActivated", function()
    if decryptionMainPoint then
        decryptionMainPoint.remove()
        decryptionMainPoint = nil
    end
end)

-- Found code event
RegisterNetEvent("lunar_contracts:artasylum:foundCode", function(computerIndex, code)
    if not isContractActive then
        return
    end

    lib.alertDialog({
        header = locale("decrypted_code_header"),
        content = string.format(locale("decrypted_code_content_" .. computerIndex), code),
        centered = true
    })
end)

-- Activate decryption on main computer
local function activateDecryption()
    if Config.officeComputers.requiredItem then
        if not Framework.hasItem(Config.officeComputers.requiredItem) then
            LR.notify(locale("missing_" .. Config.officeComputers.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied("artasylum:activate_decryption") then
        return
    end

    local computerCoords = Config.officeComputers.main
    local animDict = "missheist_jewel@hacking"
    local animClip = "hack_loop"

    Utils.makeEntityFaceCoords(cache.ped, computerCoords)
    lib.requestAnimDict(animDict)

    TaskPlayAnim(cache.ped, animDict, animClip, 4.0, 4.0, -1, 1, 1.0, false, false, false)

    LR.progressBar(locale("init_hack"), 3000, false)

    local success = minigames.activateDecryption()

    if success then
        LR.notify(locale("hacked_computer"), "success")
        TriggerServerEvent("lunar_contracts:artasylum:activateDecryption")
    else
        LR.notify(locale("hack_failed"), "error")
    end

    RemoveAnimDict(animDict)
    ClearPedTasks(cache.ped)
    Wait(1000)
    FreeOccupiedSpot()
end

-- Decrypt code on office computer
local function decryptCode(computerIndex)
    if decryptionMainPoint then
        LR.notify(locale("decryption_not_activated"), "error")
        return
    end

    if Config.officeComputers.requiredItem then
        if not Framework.hasItem(Config.officeComputers.requiredItem) then
            LR.notify(locale("missing_" .. Config.officeComputers.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied("artasylum:office_computer") then
        return
    end

    local computerCoords = Config.officeComputers.other[computerIndex]
    local animDict = "missheist_jewel@hacking"
    local animClip = "hack_loop"

    Utils.makeEntityFaceCoords(cache.ped, computerCoords)
    lib.requestAnimDict(animDict)

    TaskPlayAnim(cache.ped, animDict, animClip, 4.0, 4.0, -1, 1, 1.0, false, false, false)

    LR.progressBar(locale("init_hack"), 3000, false)

    local success = minigames.decryptCode()

    if success then
        LR.notify(locale("hacked_computer"), "success")
        TriggerServerEvent("lunar_contracts:artasylum:decryptCode", computerIndex)
    else
        LR.notify(locale("hack_failed"), "error")
    end

    RemoveAnimDict(animDict)
    ClearPedTasks(cache.ped)
    FreeOccupiedSpot()
end

-- Enter vault code
local function enterVaultCode(keypadIndex)
    local input = lib.inputDialog(locale("keypad_header"), {{
        type = "input",
        label = locale("code"),
        icon = "key"
    }})

    if not input then
        return
    end

    if IsSpotOccupied(string.format("artasylum:keypad_%s", keypadIndex)) then
        return
    end

    local success, errorMsg = lib.callback.await("lunar_contracts:artasylum:enterVaultCode", false, keypadIndex, input[1])

    if success then
        local soundId = GetSoundId()
        PlaySoundFrontend(soundId, "HACKING_SUCCESS", "", false)
        LR.notify(locale("vault_unlocked"), "success")
        Wait(1000)
        LR.notify(locale("silent_alarm_in", Config.alarm.silentDelay), "warning")
    else
        LR.notify(errorMsg, "error")
    end

    FreeOccupiedSpot()
end

-- Open mini safe
local function openMiniSafe(safeIndex)
    if IsSpotOccupied("artasylum:safe") then
        return
    end

    local success = minigames.unlockSafe()

    if success then
        LR.notify(locale("opened_minisafe"), "success")

        local animDict = "anim_heist@arcade_property@arcade_safe_open@" .. (IsPedMale(cache.ped) and "male" or "female")
        local playerCoords = GetEntityCoords(cache.ped)
        local safeObj = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 5.0, Config.safe.model, false, false, false)
        local objCoords = GetEntityCoords(safeObj)
        local rotation = GetEntityRotation(safeObj)

        local scene = NetworkCreateSynchronisedScene(objCoords.x + 0.972076, objCoords.y + 6.19471, objCoords.z - 2.368813,
            rotation.x, rotation.y, rotation.z + 90.0, 2, false, false, 1.0, 0.0, 1065353216)

        NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, "safe_open", 4.0, -4.0, 1037, 16, 1000.0, 0)
        NetworkAddMapEntityToSynchronisedScene(scene, Config.safe.model, objCoords.x, objCoords.y, objCoords.z, animDict, "safe_open_safedoor", 1.0, -1.0, 1148846080)

        NetworkStartSynchronisedScene(scene)
        Wait(5000)

        TriggerServerEvent("lunar_contracts:artasylum:openSafe", safeIndex)
        NetworkStopSynchronisedScene(scene)
        FreezeEntityPosition(safeObj, true)
    else
        LR.notify(locale("lockpick_failed"), "error")
    end

    Wait(2000)
    FreeOccupiedSpot()
end

-- Set painting looted (creates removal zone)
local function setPaintingLooted(paintingIndex)
    local offsetCoords = Utils.offsetCoords(Config.paintings.locations[paintingIndex], 0.0, 0.0, -0.5)
    local zoneAdded = {}

    local point = lib.points.new({
        coords = offsetCoords,
        distance = 30.0,
        onEnter = function()
            local paintingObj = lib.getClosestObject(offsetCoords.xyz, 1.0)
            if not paintingObj or zoneAdded[paintingObj] then
                return
            end

            local sceneCoords = GetOffsetFromEntityInWorldCoords(paintingObj, 0.0, -0.425, -1.165)
            local rotation = GetEntityRotation(paintingObj)

            local scene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
                rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0.99, 0.0)

            NetworkAddEntityToSynchronisedScene(paintingObj, scene,
                "anim_heist@hs3f@ig11_steal_painting@male@",
                "ver_01_with_painting_exit_ch_prop_vault_painting_01a",
                1.0, -1.0, 1148846080)

            NetworkStartSynchronisedScene(scene)
            FreezeEntityPosition(paintingObj, true)

            zoneAdded[paintingObj] = true
            Wait(200)
        end
    })

    paintingRemovalZones[#paintingRemovalZones + 1] = point

    if isContractActive and paintingPoints[paintingIndex] then
        paintingPoints[paintingIndex].remove()
    end
end

-- Steal painting
local function stealPainting(paintingIndex)
    local animDict = "anim_heist@hs3f@ig11_steal_painting@male@"

    if IsSpotOccupied(string.format("artasylum:painting_%s", paintingIndex)) then
        return
    end

    lib.requestModel(-944468481)
    lib.requestModel(-963831200)

    local offsetCoords = Utils.offsetCoords(Config.paintings.locations[paintingIndex], 0.0, 0.0, -0.5).xyz
    local paintingObj = lib.getClosestObject(offsetCoords, 1.0)

    if not paintingObj then
        SetModelAsNoLongerNeeded(-944468481)
        SetModelAsNoLongerNeeded(-963831200)
        FreeOccupiedSpot()
        error("Can't locate the painting object.")
        return
    end

    local sceneCoords = GetOffsetFromEntityInWorldCoords(paintingObj, 0.0, -0.425, -1.15)
    local rotation = GetEntityRotation(paintingObj)

    local bag = CreateSceneObject(-944468481, sceneCoords)
    local knife = CreateSceneObject(-963831200, sceneCoords)

    local anims = {
        "ver_01_top_left_enter",
        "ver_01_cutting_top_left_to_right",
        "ver_01_cutting_right_top_to_bottom",
        "ver_01_cutting_bottom_right_to_left",
        "ver_01_re-enter_cutting_left_top_to_bottom",
        "ver_01_with_painting_exit"
    }

    local scenes = {}

    for i = 1, #anims do
        local scene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
            rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1065353216)

        NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, anims[i], -4.0, -4.0, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(bag, scene, animDict, anims[i] .. "_hei_p_m_bag_var22_arm_s", 1.0, -1.0, 1148846080)
        NetworkAddEntityToSynchronisedScene(paintingObj, scene, animDict, anims[i] .. "_ch_prop_vault_painting_01a", 1.0, -1.0, 1148846080)
        NetworkAddEntityToSynchronisedScene(knife, scene, animDict, anims[i] .. "_w_me_switchblade", 1.0, -1.0, 1148846080)

        scenes[i] = scene
    end

    for i = 1, #anims do
        NetworkStartSynchronisedScene(scenes[i])
        Wait((GetAnimDuration(animDict, anims[i]) * 1000) - 100)
    end

    TriggerServerEvent("lunar_contracts:artasylum:stealPainting", paintingIndex)

    DeleteEntity(bag)
    DeleteEntity(knife)
    SetModelAsNoLongerNeeded(-944468481)
    SetModelAsNoLongerNeeded(-963831200)
    FreeOccupiedSpot()
end

-- Pry open sewer door
local function openSewerDoor(doorIndex)
    local currentWeapon = GetSelectedPedWeapon(cache.ped)

    if currentWeapon ~= Config.sewerDoors.requiredWeapon then
        LR.notify(locale("missing_crowbar"), "error")
        return
    end

    if IsSpotOccupied(string.format("artasylum:sewer_door_%s", doorIndex)) then
        return
    end

    local interactCoords = Config.sewerDoors.locations[doorIndex].interact
    Utils.makeEntityFaceCoords(cache.ped, interactCoords)

    LR.progressBar(locale("prying_open"), 5000, false, {
        dict = "missheistfbi3b_ig7",
        clip = "lift_fibagent_loop",
        flag = 1
    })

    LR.notify(locale("sewer_door_opened"), "success")
    TriggerServerEvent("lunar_contracts:artasylum:openSewerDoor", doorIndex)
    FreeOccupiedSpot()
end

-- Circular motion helper (for laser/lights)
local function getCircularMotionPoint(center, radius, progress)
    local angle = progress * 2.0 * math.pi
    return vector3(center.x + radius * math.cos(angle), center.y + radius * math.sin(angle), center.z)
end

-- Linear interpolation helper
local function getLinearInterpolatedPoint(startPoint, endPoint, progress)
    progress = progress * 2.0
    if progress > 1.0 then
        progress = 1.0 - (progress - 1.0)
    end
    return vector3(
        startPoint.x + (endPoint.x - startPoint.x) * progress,
        startPoint.y + (endPoint.y - startPoint.y) * progress,
        startPoint.z + (endPoint.z - startPoint.z) * progress
    )
end

-- Light/laser system
local lightZone = nil
local alarmTriggeredFlag = false

local function createLightZone()
    lightZone = lib.zones.sphere({
        coords = Config.lights.render.coords,
        radius = Config.lights.render.radius,
        debug = Config.lights.render.debug,
        inside = function()
            local playerCoords = GetEntityCoords(cache.ped)

            for i = 1, #Config.lights.locations do
                local light = Config.lights.locations[i]
                local currentTime = GetGameTimer()
                local progress = (currentTime % light.interval) / light.interval

                local lightPos
                if light.coords then
                    if progress <= 0.5 then
                        lightPos = light.coords
                    else
                        goto continue
                    end
                elseif light.centre then
                    lightPos = getCircularMotionPoint(light.centre, light.radius, progress)
                else
                    lightPos = getLinearInterpolatedPoint(light.startCoords, light.endCoords, progress)
                end

                DrawSpotLight(lightPos.x, lightPos.y, lightPos.z + 2.0, 0.0, 0.0, -1.0, 255, 255, 255, 5.0, 1.0, 0.0, light.lightRadius * 20, 0.2)

                if #(playerCoords - lightPos) < light.lightRadius and not alarmTriggeredFlag then
                    alarmTriggeredFlag = true
                    TriggerServerEvent("lunar_contracts:artasylum:triggerAlarm")
                end

                ::continue::
            end
        end
    })
end

-- Trigger alarm event
RegisterNetEvent("lunar_contracts:artasylum:triggerAlarm", function()
    SetTimeout(2000, function()
        if lightZone then
            lightZone.remove()
            lightZone = nil
            alarmTriggeredFlag = false
        end
    end)

    local soundId = GetSoundId()
    local alarmCoords = Config.alarm.coords

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

    alertLevel = 1.0
end)

-- Room ID sync
local roomSyncActive = false

RegisterNetEvent("lunar_contracts:artasylum:syncRoomId", function(pedIds)
    roomSyncActive = true

    for _, pedId in ipairs(pedIds) do
        CreateThread(function()
            while roomSyncActive do
                if NetworkDoesEntityExistWithNetworkId(pedId) then
                    local ped = NetworkGetEntityFromNetworkId(pedId)
                    local offsetCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, -3.0, 0.0)
                    local obj = lib.getClosestObject(offsetCoords, 2.5)

                    if obj then
                        local interiorId = GetInteriorFromEntity(obj)
                        local roomKey = GetRoomKeyFromEntity(obj)
                        ForceRoomForEntity(ped, interiorId, roomKey)
                    end
                end
                Wait(500)
            end
        end)
    end
end)

-- Update UI bars
local function updateBars(alert, noise)
    alert = math.min(alert, 1.0)
    noise = math.min(noise, 1.0)

    LR.showBars({
        {
            label = locale("alert_level"),
            icon = "triangle-exclamation",
            percentage = alert * 100,
            color = "#FFD700"
        },
        {
            label = locale("noise_level"),
            icon = "volume-up",
            percentage = noise * 100,
            color = "#1E90FF"
        }
    })
end

-- Raycast helper
local function raycastProbe(from, to, flags, ignore)
    flags = flags or 511
    ignore = ignore or 4
    local rayHandle = StartShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, flags, cache.ped, ignore)

    while true do
        Wait(0)
        local result, hit, endCoords, surfaceNormal, entityHit, materialHash = GetShapeTestResultIncludingMaterial(rayHandle)
        if result ~= 1 then
            return hit == 1, entityHit, endCoords, surfaceNormal, materialHash
        end
    end
end

-- Sensor disabled event
local function getDisabledSensorCount()
    local count = 0

    for i = 1, #Config.noiseSensors do
        if disabledSensors[i] then
            count = count + 1
        end
    end

    return count
end

RegisterNetEvent("lunar_contracts:artasylum:sensorDisabled", function(sensorIndex)
    if not isContractActive then
        return
    end

    disabledSensors[sensorIndex] = true

    local disabledCount = getDisabledSensorCount()
    local totalSensors = #Config.noiseSensors

    if disabledCount >= totalSensors then
        LR.notify(locale("noise_sensors_all_disabled"), "success")
    else
        LR.notify(locale("noise_sensors_disabled_count", disabledCount, totalSensors), "inform")
    end
end)

-- Camera viewing
local function viewCamera(cameraCoords)
    if Editable.isDead(cache.ped) then
        return
    end

    -- Find closest desk
    local closest = { coords = nil, dist = math.huge }
    for i = 1, #Config.cameras.desks do
        local dist = #(GetEntityCoords(cache.ped) - Config.cameras.desks[i])
        if dist < closest.dist then
            closest = { coords = Config.cameras.desks[i], dist = dist }
        end
    end

    Busy = true
    Utils.makeEntityFaceCoords(cache.ped, closest.coords)

    lib.requestAnimDict("anim@amb@warehouse@laptop@")
    TaskPlayAnim(cache.ped, "anim@amb@warehouse@laptop@", "idle_a", 8.0, 8.0, -1, 11, 1.0, false, false, false)
    RemoveAnimDict("anim@amb@warehouse@laptop@")

    LR.progressBar(locale("opening_cctv"), 1500, false)

    DoScreenFadeOut(500)
    Wait(1000)

    -- Load scaleform
    local scaleform = lib.requestScaleformMovie("DRONE_CAM")
    if scaleform then
        PushScaleformMovieFunction(scaleform, "DRONE_CAM")
        PopScaleformMovieFunctionVoid()
        PushScaleformMovieFunction(scaleform, "SET_RETICLE_IS_VISIBLE")
        PushScaleformMovieFunctionParameterBool(true)
        PopScaleformMovieFunctionVoid()
    end

    -- Create camera
    local cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", cameraCoords.x, cameraCoords.y, cameraCoords.z,
        -30.0, 0.0, cameraCoords.w, 60.0, true, 2)

    SetCamActive(cam, true)
    RenderScriptCams(true, false, 1, false)
    SetTimecycleModifier("scanline_cam_cheap")
    SetTimecycleModifierStrength(1.0)
    DoScreenFadeIn(500)

    LR.showUI(locale("artasylum_cctv_controls"))

    RequestAmbientAudioBank("Phone_Soundset_Franklin", false)
    RequestAmbientAudioBank("HintCamSounds", false)

    local baseHeading = cameraCoords.w
    if baseHeading < 0.0 then
        baseHeading = 180.0 + baseHeading
    end

    local bounds = { left = 90, right = -90, up = 45.0, down = -45.0 }
    local cameraRunning = true
    local closestSensorIndex = nil
    local sensorHackInProgress = false

    -- Camera control thread
    CreateThread(function()
        while cameraRunning do
            DisableAllControlActions(0)
            HideHudComponentThisFrame(7)
            HideHudComponentThisFrame(8)
            HideHudComponentThisFrame(9)
            HideHudComponentThisFrame(6)
            HideHudComponentThisFrame(19)
            HideHudAndRadarThisFrame()

            local camRot = GetCamRot(cam, 2)
            local currentHeading = camRot.z
            if currentHeading < 0.0 then
                currentHeading = 360.0 + currentHeading
            end

            local angleDiff = currentHeading - baseHeading
            angleDiff = (angleDiff + 180) % 360 - 180

            if scaleform then
                DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
            end

            if closestSensorIndex then
                local sensorCoords = Config.noiseSensors[closestSensorIndex].coords
                local text = disabledSensors[closestSensorIndex] and locale("noise_sensor_disabled") or locale("disable_noise_sensor")
                Editable.draw3DText(sensorCoords, text)
            end

            -- Handle camera rotation
            if IsDisabledControlPressed(0, CameraSettings.controls.left) and angleDiff < bounds.left then
                camRot = vector3(camRot.x, camRot.y, camRot.z + CameraSettings.rotateSpeed)
            end

            if IsDisabledControlPressed(0, CameraSettings.controls.right) and angleDiff > bounds.right then
                camRot = vector3(camRot.x, camRot.y, camRot.z - CameraSettings.rotateSpeed)
            end

            if IsDisabledControlPressed(0, CameraSettings.controls.up) and camRot.x < bounds.up then
                camRot = vector3(camRot.x + CameraSettings.rotateSpeed, camRot.y, camRot.z)
            end

            if IsDisabledControlPressed(0, CameraSettings.controls.down) and camRot.x > bounds.down then
                camRot = vector3(camRot.x - CameraSettings.rotateSpeed, camRot.y, camRot.z)
            end

            -- Disable noise sensor
            if closestSensorIndex and not disabledSensors[closestSensorIndex] and not sensorHackInProgress and IsDisabledControlJustPressed(0, Config.cameras.settings.controls.disableSensor) then
                sensorHackInProgress = true
                local success = minigames.noiseSensor()
                if success then
                    TriggerServerEvent("lunar_contracts:artasylum:hackSensor", closestSensorIndex)
                    Wait(1000)
                    closestSensorIndex = nil
                end
                sensorHackInProgress = false
            end

            SetCamRot(cam, camRot.x, camRot.y, camRot.z, 2)
            Wait(0)
        end
    end)

    -- Sensor detection thread
    CreateThread(function()
        while cameraRunning do
            local closest = { index = nil, dist = math.huge }

            for idx, sensor in pairs(Config.noiseSensors) do
                local sensorCoords = sensor.coords
                local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(sensorCoords.x, sensorCoords.y, sensorCoords.z)

                if onScreen then
                    local distance = math.sqrt((screenX - 0.5) ^ 2 + (screenY - 0.5) ^ 2)

                    if distance < 0.1 then
                        local worldDist = #(cameraCoords.xyz - sensorCoords)
                        if worldDist < closest.dist then
                            local hit = raycastProbe(cameraCoords.xyz, sensorCoords)
                            if not hit then
                                closest = { index = idx, dist = worldDist }
                            end
                        end
                    end
                end
            end

            closestSensorIndex = closest.index
            Wait(200)
        end
    end)

    -- Exit handler
    CreateThread(function()
        while cameraRunning do
            if IsDisabledControlJustReleased(0, 38) or Editable.isDead(cache.ped) then
                LR.hideUI()
                DoScreenFadeOut(500)
                Wait(500)
                cameraRunning = false
                Busy = false
                DestroyCam(cam)
                ClearPedTasks(cache.ped)
                RenderScriptCams(false, false, 1, false)
                Wait(200)
                if scaleform then
                    SetScaleformMovieAsNoLongerNeeded(scaleform)
                end
                ClearTimecycleModifier()
                Wait(500)
                DoScreenFadeIn(500)
                return
            end
            Wait(0)
        end
    end)
end

-- Camera options setup
for i = 1, #Config.cameras.options do
    local option = Config.cameras.options[i]
    option.onSelect = viewCamera
    option.args = option.coords
    option.icon = "camera"
end

-- Register camera context
lib.registerContext({
    id = "artasylum_cameras",
    title = locale("cameras_header"),
    options = Config.cameras.options
})

-- Remove keypad door
RegisterNetEvent("lunar_contracts:artasylum:removeKeypadDoor", function(doorIndex)
    if not isContractActive then
        return
    end

    if keypadPoints[doorIndex] then
        keypadPoints[doorIndex].remove()
        keypadPoints[doorIndex] = nil
    end
end)

-- Remove security door
RegisterNetEvent("lunar_contracts:artasylum:removeSecurityDoor", function(doorIndex)
    if not isContractActive then
        return
    end

    if securityDoorPoints[doorIndex] then
        securityDoorPoints[doorIndex].remove()
        securityDoorPoints[doorIndex] = nil
    end
end)

-- Remove electric box
RegisterNetEvent("lunar_contracts:artasylum:removeElectricBox", function()
    if not isContractActive then
        return
    end

    if electricBoxPoint then
        electricBoxPoint.remove()
        electricBoxPoint = nil
    end
end)

-- Remove vault keypads
RegisterNetEvent("lunar_contracts:artasylum:removeVaultKeypads", function()
    if not isContractActive then
        return
    end

    for _, point in pairs(vaultKeypadPoints) do
        point.remove()
    end
    table.wipe(vaultKeypadPoints)
end)

-- Set safe as lootable
RegisterNetEvent("lunar_contracts:artasylum:setSafeAsLootable", function()
    safeOpen = true
end)

-- Remove safe
RegisterNetEvent("lunar_contracts:artasylum:removeSafe", function()
    if not isContractActive then
        return
    end

    if safePoint then
        safePoint.remove()
        safePoint = nil
    end
end)

-- Remove sewer door
RegisterNetEvent("lunar_contracts:artasylum:removeSewerDoor", function(doorIndex)
    if not isContractActive then
        return
    end

    if sewerDoorPoints[doorIndex] then
        sewerDoorPoints[doorIndex].remove()
        sewerDoorPoints[doorIndex] = nil
    end
end)

-- Update alert level
local lastAlertLevel = 0.0
local noiseAccumulator = 0
local noiseTimer = -1

local function stopNoiseAlertBars(delay)
    if alertTimer then
        ClearInterval(alertTimer)
        alertTimer = nil
    end

    alertLevel = 0.0
    lastAlertLevel = 0.0
    noiseAccumulator = 0
    noiseTimer = -1

    if delay and delay > 0 then
        SetTimeout(delay, function()
            LR.hideBars()
        end)
    else
        LR.hideBars()
    end
end

RegisterNetEvent("lunar_contracts:artasylum:updateAlertLevel", function(level)
    if not isContractActive then
        return
    end
    alertLevel = level
end)

-- Initialize contract
local function initializeContract()
    isContractActive = true
    table.wipe(disabledSensors)
    safeOpen = false
    alertLevel = 0.0

    -- Keypad doors
    for i = 1, #Config.keypadDoors.locations do
        local doorCoords = Config.keypadDoors.locations[i].door or GetDoorCoords(Config.keypadDoors.locations[i].doors)

        keypadPoints[i] = Utils.createInteractionPoint({
            coords = doorCoords,
            radius = 1.0,
            options = {{
                label = locale("hack_keypad"),
                icon = "code",
                onSelect = hackKeypadDoor,
                args = i,
                canInteract = function() return not Busy end
            }}
        })
    end

    -- Security doors
    for i = 1, #Config.securityDoors.locations do
        local doorCoords = GetDoorCoords(Config.securityDoors.locations[i])

        securityDoorPoints[i] = Utils.createInteractionPoint({
            coords = doorCoords,
            radius = 1.0,
            options = {{
                label = locale("hack_door"),
                icon = "code",
                onSelect = hackSecurityDoor,
                args = i,
                canInteract = function() return not Busy end
            }}
        })
    end

    -- Electric box
    local boxCoords = Utils.offsetCoords(Config.genericDoors.electricBox.coords, 0.0, 0.25, 0.3)

    electricBoxPoint = Utils.createInteractionPoint({
        coords = boxCoords,
        radius = 1.0,
        options = {{
            label = locale("disable_locks"),
            icon = "code",
            onSelect = disableLocks,
            canInteract = function() return not Busy end
        }}
    })

    -- Office computers (decryption)
    for i = 1, #Config.officeComputers.other do
        officeComputerPoints[i] = Utils.createInteractionPoint({
            coords = Config.officeComputers.other[i],
            radius = 1.0,
            options = {{
                label = locale("decrypt_code"),
                icon = "code",
                onSelect = decryptCode,
                args = i,
                canInteract = function() return not Busy end
            }}
        })
    end

    -- Main decryption computer
    decryptionMainPoint = Utils.createInteractionPoint({
        coords = Config.officeComputers.main,
        radius = 1.0,
        options = {{
            label = locale("activate_decryption"),
            icon = "code",
            onSelect = activateDecryption,
            canInteract = function() return not Busy end
        }}
    })

    -- Vault keypads
    for i = 1, #Config.vault.keypads do
        vaultKeypadPoints[i] = Utils.createInteractionPoint({
            coords = Config.vault.keypads[i],
            radius = 1.0,
            options = {{
                label = locale("enter_code"),
                icon = "key",
                onSelect = enterVaultCode,
                args = i,
                canInteract = function() return not Busy end
            }}
        })
    end

    -- Safe
    safePoint = Utils.createInteractionPoint({
        coords = Config.safe.coords,
        radius = 1.0,
        options = {
            {
                label = locale("lockpick_safe"),
                icon = "vault",
                onSelect = openMiniSafe,
                canInteract = function() return not (Busy or safeOpen) end
            },
            {
                label = locale("take_safe_loot"),
                icon = "vault",
                onSelect = function()
                    if IsSpotOccupied("artasylum:safe") then
                        return
                    end
                    TriggerServerEvent("lunar_contracts:artasylum:openSafe")
                    Wait(1000)
                    FreeOccupiedSpot()
                end,
                canInteract = function() return not (Busy or not safeOpen) end
            }
        }
    })

    -- Paintings
    for i = 1, #Config.paintings.locations do
        local paintingCoords = Utils.offsetCoords(Config.paintings.locations[i], 0.0, 0.0, -0.1)

        paintingPoints[i] = Utils.createInteractionPoint({
            coords = paintingCoords,
            radius = 0.75,
            options = {{
                label = locale("steal_painting"),
                icon = "user-ninja",
                onSelect = stealPainting,
                args = i,
                canInteract = function()
                    return not Busy and Utils.distanceCheck(cache.ped, Utils.offsetCoords(Config.paintings.locations[i], 0.0, 0.0, -0.1), 0.75)
                end
            }}
        })
    end

    -- Cameras
    for i = 1, #Config.cameras.desks do
        cameraPoints[i] = Utils.createInteractionPoint({
            coords = Config.cameras.desks[i],
            radius = 1.25,
            options = {{
                label = locale("open_cameras"),
                icon = "camera",
                onSelect = function() lib.showContext("artasylum_cameras") end,
                canInteract = function() return not Busy end
            }}
        })
    end

    -- Sewer doors
    for i = 1, #Config.sewerDoors.locations do
        sewerDoorPoints[i] = Utils.createInteractionPoint({
            coords = Config.sewerDoors.locations[i].interact,
            radius = 1.25,
            options = {{
                label = locale("pry_open"),
                icon = "lock",
                onSelect = openSewerDoor,
                args = i,
                canInteract = function() return not Busy end
            }}
        })
    end

    -- Noise detection loop
    local prevAlertLevel = 0.0
    local counter = -1

    alertTimer = SetInterval(function()
        local noiseLevel = 0.0

        if NetworkIsPlayerTalking(cache.playerId) then
            noiseLevel = 0.1 + (math.random() % (0.1 * MumbleGetTalkerProximity()))
        else
            noiseLevel = 0.0
        end

        local speed = GetEntitySpeed(cache.ped)
        if speed > 0.2 then
            noiseLevel = noiseLevel + 0.2 + (math.random() % 0.1)
        end

        if not GetPedStealthMovement(cache.ped) then
            local movementClipset = GetPedMovementClipset(cache.ped)
            if movementClipset ~= -1155413492 then
                noiseLevel = noiseLevel * 2
            end
        end

        if IsPedRunning(cache.ped) then
            noiseLevel = noiseLevel * 2
        end

        local totalNoise = noiseLevel

        updateBars(alertLevel, totalNoise)

        -- Check noise sensors
        for idx, sensor in ipairs(Config.noiseSensors) do
            if not disabledSensors[idx] then
                if Utils.distanceCheck(cache.ped, sensor.coords, sensor.radius) then
                    if totalNoise > sensor.threshold then
                        alertLevel = alertLevel + 0.1
                        counter = 0
                    end
                end
            end
        end

        if prevAlertLevel == alertLevel then
            if counter < 5 and counter >= 0 then
                counter = counter + 1
            end
        end

        if counter >= 5 then
            TriggerServerEvent("lunar_contracts:artasylum:updateAlertLevel", alertLevel)
            counter = -1
        end

        prevAlertLevel = alertLevel
    end, 200)

    -- Blip
    blip = Utils.createBlip(Config.blip.coords, Config.blip)
    SetBlipRoute(blip.value, true)
    Utils.distanceWait(Config.blip.coords, 30.0)
    blip.remove()
    blip = nil
end

-- Start contract
RegisterNetEvent("lunar_contracts:artasylum:started", function(players)
    local identifier = Framework.getIdentifier()
    for _, playerId in ipairs(players) do
        if identifier == playerId then
            initializeContract()
        end
    end

    createLightZone()
end)

-- Finished contract
RegisterNetEvent("lunar_contracts:artasylum:finished", function()
    if isContractActive then
        stopNoiseAlertBars(1000)
    end
end)

-- Reset contract
RegisterNetEvent("lunar_contracts:artasylum:reset", function()
    roomSyncActive = false

    if not isContractActive then
        return
    end

    for _, point in pairs(keypadPoints) do
        point.remove()
    end
    table.wipe(keypadPoints)

    for _, point in pairs(securityDoorPoints) do
        point.remove()
    end
    table.wipe(securityDoorPoints)

    if electricBoxPoint then
        electricBoxPoint.remove()
        electricBoxPoint = nil
    end

    if decryptionMainPoint then
        decryptionMainPoint.remove()
        decryptionMainPoint = nil
    end

    for _, point in pairs(officeComputerPoints) do
        point.remove()
    end
    table.wipe(officeComputerPoints)

    for _, point in pairs(vaultKeypadPoints) do
        point.remove()
    end
    table.wipe(vaultKeypadPoints)

    if safePoint then
        safePoint.remove()
        safePoint = nil
    end

    for _, point in pairs(paintingPoints) do
        point.remove()
    end
    table.wipe(paintingPoints)

    for _, point in pairs(cameraPoints) do
        point.remove()
    end
    table.wipe(cameraPoints)

    for _, point in pairs(sewerDoorPoints) do
        point.remove()
    end
    table.wipe(sewerDoorPoints)

    for _, zone in ipairs(paintingRemovalZones) do
        zone.remove()
    end
    table.wipe(paintingRemovalZones)

    if lightZone then
        lightZone.remove()
        lightZone = nil
        alarmTriggeredFlag = false
    end

    if blip then
        blip.remove()
        blip = nil
    end

    stopNoiseAlertBars()
    table.wipe(disabledSensors)
    safeOpen = false

    isContractActive = false
end)
