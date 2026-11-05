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

-- Check for mka-lasers dependency
if not Laser then
    SetInterval(function()
        error("Missing mka-lasers dependency, Maze Bank heist won't work! (You can find a link in the documentation)")
    end, 2000)
end

local CameraSettings = Config.cameraSettings
local Config = Config.contracts.mazebank
local minigames = Editable.minigames.mazebank

-- State variables
local isContractActive = false
local circuitOverloaded = false
local securityDoorPoints = {}
local generatorPoints = {}
local electricBoxPoint = nil
local keypadPoints = {}
local laptopPoints = {}
local elevatorDoorPoint = nil
local terminalPoint = nil
local cameraPoints = {}
local circuitPoint = nil
local miniSafePoints = {}
local garagePanelPoint = nil
local blip = nil

-- Laser system
local laserZone = nil
local lasers = {}
local alarmTriggered = false

-- Create laptop props
CreateThread(function()
    while not IsModelInCdimage(-1634294596) do
        Wait(500)
    end

    for i = 1, #Config.keypadDoors.laptops.locations do
        Utils.createProp(Config.keypadDoors.laptops.locations[i], {
            model = -1634294596,
            offset = vector3(0.0, -0.1, -0.08)
        })
    end
end)

-- Create basement props
for i = 1, #Config.basement.props do
    local prop = Config.basement.props[i]
    Utils.createProp(prop.coords, {
        model = prop.model,
        offset = vector3(0.0, 0.0, -1.0)
    })
end

-- Security door hack
local function hackSecurityDoor(doorIndex)
    if Config.securityDoors.requiredItem then
        if not Framework.hasItem(Config.securityDoors.requiredItem) then
            LR.notify(locale("missing_" .. Config.securityDoors.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied(string.format("mazebank:security_door_%s", doorIndex)) then
        return
    end

    local animDict = "anim@heists@ornate_bank@hack"
    local doorConfig = Config.securityDoors.locations[doorIndex]
    local sceneCoords = nil
    local sceneRot = nil

    if doorConfig.keypad then
        sceneCoords = Utils.offsetCoords(doorConfig.keypad, 0.08, 0.05, -0.01)
        sceneRot = vector3(0.0, 0.0, sceneCoords.w)
    else
        local doorCoords = GetDoorCoords(doorConfig)
        local doorModel = doorConfig.model or doorConfig[1].model
        local doorObj = GetClosestObjectOfType(doorCoords.x, doorCoords.y, doorCoords.z, 2.0, doorModel, false, false, false)

        local pos1 = GetOffsetFromEntityInWorldCoords(doorObj, 0.0, 0.25, 0.0)
        local pos2 = GetOffsetFromEntityInWorldCoords(doorObj, 0.0, -0.25, 0.0)

        local playerCoords = GetEntityCoords(cache.ped)
        local isLeftSide = #(playerCoords - pos1) < #(playerCoords - pos2)

        sceneCoords = GetOffsetFromEntityInWorldCoords(doorObj, isLeftSide and 0.975 or 1.15, 0.0, 0.3)
        sceneRot = GetEntityRotation(doorObj)

        if isLeftSide then
            sceneRot = vector3(sceneRot.x, sceneRot.y, sceneRot.z + 180.0)
        end
    end

    lib.requestModel(-944468481)
    lib.requestModel(-411901183)
    lib.requestModel(-676527372)

    local suitBag = CreateSceneObject(-944468481, sceneCoords)
    local keycard = CreateSceneObject(-411901183, sceneCoords)
    local laptop = CreateSceneObject(-676527372, sceneCoords)

    -- Enter scene
    local enterScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        sceneRot.x, sceneRot.y, sceneRot.z, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, enterScene, animDict, "hack_enter", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(suitBag, enterScene, animDict, "hack_enter_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(keycard, enterScene, animDict, "hack_enter_card", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, enterScene, animDict, "hack_enter_laptop", 1.0, -1.0, 1148846080)

    -- Loop scene
    local loopScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        sceneRot.x, sceneRot.y, sceneRot.z, 2, false, true, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "hack_loop", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(suitBag, loopScene, animDict, "hack_loop_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(keycard, loopScene, animDict, "hack_loop_card", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, loopScene, animDict, "hack_loop_laptop", 1.0, -1.0, 1148846080)

    -- Exit scene
    local exitScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        sceneRot.x, sceneRot.y, sceneRot.z, 2, false, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "hack_exit", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(suitBag, exitScene, animDict, "hack_exit_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(keycard, exitScene, animDict, "hack_exit_card", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, exitScene, animDict, "hack_exit_laptop", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(enterScene)
    Wait((GetAnimDuration(animDict, "hack_enter") * 1000) - 200)

    NetworkStartSynchronisedScene(loopScene)

    local success = minigames.securityDoor()

    if success then
        TriggerServerEvent("lunar_contracts:mazebank:openSecurityDoor", doorIndex)
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

-- Disable generator (sewer locks)
local function disableGenerator(generatorIndex)
    if Config.sewers.generators.requiredItem then
        if not Framework.hasItem(Config.sewers.generators.requiredItem) then
            LR.notify(locale("missing_" .. Config.sewers.generators.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied(string.format("mazebank:generator_%s", generatorIndex)) then
        return
    end

    local generatorCoords = Config.sewers.generators.locations[generatorIndex]
    local sceneCoords = Utils.offsetCoords(generatorCoords, -0.1, 0.05, 0.35)
    local animDict = "anim_heist@hs3f@ig1_hack_keypad@arcade@" .. (IsPedMale(cache.ped) and "male@" or "female@")

    lib.requestModel(413312110)
    local phone = CreateSceneObject(413312110, sceneCoords)

    -- Intro scene
    local introScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        0.0, 0.0, sceneCoords.w, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, introScene, animDict, "action_var_01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(phone, introScene, animDict, "action_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)

    -- Loop scene
    local loopScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        0.0, 0.0, sceneCoords.w, 2, false, true, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "hack_loop_var_01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(phone, loopScene, animDict, "hack_loop_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(introScene)
    Wait((GetAnimDuration(animDict, "action_var_01") * 1000) - 500)

    NetworkStartSynchronisedScene(loopScene)

    local success = minigames.generator()

    if success then
        LR.notify(locale("disabled_generator"), "success")
        TriggerServerEvent("lunar_contracts:mazebank:disableGenerator", generatorIndex)
    else
        LR.notify(locale("hack_failed"), "error")
    end

    -- Reaction scene
    local reactionScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        0.0, 0.0, sceneCoords.w, 2, false, false, 1065353216, 0, 1065353216)

    local reactionAnim = success and "success_react_exit_var_02" or "fail_react"

    NetworkAddPedToSynchronisedScene(cache.ped, reactionScene, animDict, reactionAnim, -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(phone, reactionScene, animDict, reactionAnim .. "_prop_phone_ing", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(reactionScene)
    Wait((GetAnimDuration(animDict, reactionAnim) * 1000) - 500)

    -- Exit animation on failure
    if not success then
        local exitScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
            0.0, 0.0, sceneCoords.w, 2, false, false, 1065353216, 0, 1065353216)

        NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "exit", -4.0, -4.0, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(phone, exitScene, animDict, "exit_prop_phone_ing", 1.0, -1.0, 1148846080)

        NetworkStartSynchronisedScene(exitScene)
        Wait((GetAnimDuration(animDict, "exit") * 1000) - 500)
    end

    DeleteEntity(phone)
    SetModelAsNoLongerNeeded(413312110)
    Wait(1000)
    FreeOccupiedSpot()
end

-- Disable lasers (electric box hack)
local function disableLasers()
    if Config.lasers.electricBox.requiredItem then
        if not Framework.hasItem(Config.lasers.electricBox.requiredItem) then
            LR.notify(locale("missing_" .. Config.lasers.electricBox.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied("mazebank:disable_lasers") then
        return
    end

    local animDict = "anim@scripted@player@mission@tun_control_tower@male@"
    local boxCoords = Config.lasers.electricBox.coords.xyz
    local boxModel = Config.lasers.electricBox.model

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
        TriggerServerEvent("lunar_contracts:mazebank:disableLasers")
        LR.notify(locale("disabled_lasers"), "success")
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

-- Hack laptop for keypad code
local function hackLaptop(data)
    local index = data.index
    local laptopCoords = data.coords

    if Config.keypadDoors.laptops.requiredItem then
        if not Framework.hasItem(Config.keypadDoors.laptops.requiredItem) then
            LR.notify(locale("missing_" .. Config.keypadDoors.laptops.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied(string.format("mazebank:laptop_%s", index)) then
        return
    end

    local animDict = "anim@gangops@morgue@office@laptop@"

    lib.requestModel(-779874356)
    local usb = CreateSceneObject(-779874356, laptopCoords)

    local laptopObj = GetClosestObjectOfType(laptopCoords.x, laptopCoords.y, laptopCoords.z, 2.0,
        Config.keypadDoors.laptops.model, false, false, false)
    local objCoords = GetEntityCoords(laptopObj)
    local rotation = GetEntityRotation(laptopObj)

    -- Enter scene
    local enterScene = NetworkCreateSynchronisedScene(objCoords.x, objCoords.y, objCoords.z,
        rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, enterScene, animDict, "enter", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usb, enterScene, animDict, "enter_usb", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptopObj, enterScene, animDict, "enter_laptop", 1.0, -1.0, 1148846080)

    -- Idle scene
    local idleScene = NetworkCreateSynchronisedScene(objCoords.x, objCoords.y, objCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, true, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, idleScene, animDict, "idle", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usb, idleScene, animDict, "idle_usb", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptopObj, idleScene, animDict, "idle_laptop", 1.0, -1.0, 1148846080)

    -- Exit scene
    local exitScene = NetworkCreateSynchronisedScene(objCoords.x, objCoords.y, objCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "exit", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usb, exitScene, animDict, "exit_usb", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptopObj, exitScene, animDict, "exit_laptop", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(enterScene)
    Wait((GetAnimDuration(animDict, "enter") * 1000) - 200)

    NetworkStartSynchronisedScene(idleScene)

    local success = minigames.laptop()

    if success then
        LR.notify(locale("hacked_laptop"), "success")
        TriggerServerEvent("lunar_contracts:mazebank:hackedLaptop", index)
    else
        LR.notify(locale("hack_failed"), "error")
    end

    NetworkStartSynchronisedScene(exitScene)
    Wait((GetAnimDuration(animDict, "exit") * 1000) - 200)

    DeleteEntity(usb)
    FreezeEntityPosition(laptopObj, true)
    SetModelAsNoLongerNeeded(-779874356)
    FreeOccupiedSpot()
end

-- Enter keypad code
local function enterKeypadCode(keypadIndex)
    local input = lib.inputDialog(locale("keypad_header"), {{
        type = "input",
        label = locale("code"),
        icon = "key"
    }})

    if not input then
        return
    end

    local success = lib.callback.await("lunar_contracts:mazebank:openKeypadDoor", false, keypadIndex, input[1])

    if success then
        LR.notify(locale("door_opened"), "success")
    else
        LR.notify(locale("wrong_code"), "error")
    end
end

-- Open elevator door with crowbar
local function openElevatorDoor()
    local currentWeapon = GetSelectedPedWeapon(cache.ped)

    if currentWeapon ~= Config.elevator.requiredWeapon then
        LR.notify(locale("missing_crowbar"), "error")
        return
    end

    if IsSpotOccupied("mazebank:elevator_door") then
        return
    end

    local doorCoords = GetDoorCoords(Config.elevator.door)
    Utils.makeEntityFaceCoords(cache.ped, doorCoords)

    LR.progressBar(locale("prying_open"), 5000, false, {
        dict = "missheistfbi3b_ig7",
        clip = "lift_fibagent_loop",
        flag = 1
    })

    LR.notify(locale("elevator_open"), "success")
    TriggerServerEvent("lunar_contracts:mazebank:openedElevatorDoor")
    FreeOccupiedSpot()
end

-- Access server room terminal
local function accessServerTerminal()
    if Config.serverRoomTerminal.requiredItem then
        if not Framework.hasItem(Config.serverRoomTerminal.requiredItem) then
            LR.notify(locale("missing_" .. Config.serverRoomTerminal.requiredItem), "error")
            return
        end
    end

    local input = lib.inputDialog(locale("terminal_header"), {{
        type = "input",
        label = locale("code"),
        description = locale("basement_door_code"),
        icon = "qrcode"
    }})

    if not input then
        return
    end

    TriggerServerEvent("lunar_contracts:mazebank:unlockBasementDoor", input[1])
end

-- Show hacked code
RegisterNetEvent("lunar_contracts:mazebank:showCode", function(message, code)
    Wait(1000)
    lib.alertDialog({
        header = locale("hacked_code"),
        content = string.format(message, code),
        cancel = false,
        centered = true,
        labels = { confirm = locale("understood") }
    })
end)

-- Basement door hack callback
lib.callback.register("lunar_contracts:mazebank:basementDoorHack", function()
    if Config.serverRoomTerminal.requiredItem then
        if not Framework.hasItem(Config.serverRoomTerminal.requiredItem) then
            LR.notify(locale("missing_" .. Config.serverRoomTerminal.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied("mazebank:server_room_terminal") then
        return
    end

    local animDict = "anim@heists@ornate_bank@hack"
    local sceneCoords = Utils.offsetCoords(Config.serverRoomTerminal.coords, -0.16, 0.0, 0.1)

    lib.requestModel(-944468481)
    lib.requestModel(-411901183)
    lib.requestModel(-676527372)

    local suitBag = CreateSceneObject(-944468481, sceneCoords)
    local keycard = CreateSceneObject(-411901183, sceneCoords)
    local laptop = CreateSceneObject(-676527372, sceneCoords)

    -- Enter scene
    local enterScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        0.0, 0.0, sceneCoords.w, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, enterScene, animDict, "hack_enter", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(suitBag, enterScene, animDict, "hack_enter_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(keycard, enterScene, animDict, "hack_enter_card", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, enterScene, animDict, "hack_enter_laptop", 1.0, -1.0, 1148846080)

    -- Loop scene
    local loopScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        0.0, 0.0, sceneCoords.w, 2, false, true, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "hack_loop", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(suitBag, loopScene, animDict, "hack_loop_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(keycard, loopScene, animDict, "hack_loop_card", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, loopScene, animDict, "hack_loop_laptop", 1.0, -1.0, 1148846080)

    -- Exit scene
    local exitScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        0.0, 0.0, sceneCoords.w, 2, false, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "hack_exit", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(suitBag, exitScene, animDict, "hack_exit_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(keycard, exitScene, animDict, "hack_exit_card", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, exitScene, animDict, "hack_exit_laptop", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(enterScene)
    Wait((GetAnimDuration(animDict, "hack_enter") * 1000) - 200)

    NetworkStartSynchronisedScene(loopScene)

    local success = minigames.terminal()

    if success then
        LR.notify(locale("remotely_unlocked_door"), "success")
    else
        LR.notify(locale("hack_failed"), "error")
    end

    CreateThread(function()
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
    end)

    return success
end)

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

-- Generate random hex code
local function generateRandomCode(length)
    local code = ""
    for i = 1, length do
        local index = math.random(1, string.len("0123456789ABCDEF"))
        code = code .. string.sub("0123456789ABCDEF", index, index)
    end
    return "0x" .. code
end

-- Camera viewing
local cameraActive = false
local currentScrambledCode = nil
local computerCodes = nil

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

    LR.showUI(locale("cctv_controls"))

    RequestAmbientAudioBank("Phone_Soundset_Franklin", false)
    RequestAmbientAudioBank("HintCamSounds", false)

    local baseHeading = cameraCoords.w
    if baseHeading < 0.0 then
        baseHeading = 180.0 + baseHeading
    end

    local bounds = { left = 90, right = -90, up = 45.0, down = -45.0 }
    local cameraRunning = true
    local closestDoorIndex = nil
    local scrambledCode = nil

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

            if closestDoorIndex then
                local doorCoords = Config.basement.doors[closestDoorIndex].coords
                local shouldScramble = Config.basement.doors[closestDoorIndex].shouldScramble
                local displayCode = (shouldScramble and not circuitOverloaded) and scrambledCode or computerCodes[closestDoorIndex]
                Editable.draw3DText(doorCoords, displayCode)
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

            SetCamRot(cam, camRot.x, camRot.y, camRot.z, 2)
            Wait(0)
        end
    end)

    -- Door detection thread
    CreateThread(function()
        while cameraRunning do
            local closest = { index = nil, dist = math.huge }

            for i = 1, #Config.basement.doors do
                local doorCoords = Config.basement.doors[i].coords
                local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(doorCoords.x, doorCoords.y, doorCoords.z)

                if onScreen then
                    local distance = math.sqrt((screenX - 0.5) ^ 2 + (screenY - 0.5) ^ 2)

                    if distance < 0.1 then
                        local worldDist = #(cameraCoords.xyz - doorCoords)
                        if worldDist < closest.dist then
                            closest = { index = i, dist = worldDist }
                        end
                    end
                end
            end

            closestDoorIndex = closest.index
            Wait(200)
        end
    end)

    -- Scrambled code generator
    CreateThread(function()
        while cameraRunning do
            scrambledCode = generateRandomCode(6)
            Wait(50)
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

-- Overload circuit
local function overloadCircuit()
    if Config.basement.circuitOverload.requiredItem then
        if not Framework.hasItem(Config.basement.circuitOverload.requiredItem) then
            LR.notify(locale("missing_" .. Config.basement.circuitOverload.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied("mazebank:overload_circuit") then
        return
    end

    local sceneCoords = Utils.offsetCoords(Config.basement.circuitOverload.coords, -0.05, 0.1, 0.1)
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

    local success = minigames.circuitOverload()

    if success then
        LR.notify(locale("overloaded_circuit"), "success")
        TriggerServerEvent("lunar_contracts:mazebank:overloadedCircuit")
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

-- Open mini safe
local function openMiniSafe(safeIndex)
    if IsSpotOccupied("mazebank:minisafe_" .. safeIndex) then
        return
    end

    local success = minigames.unlockSafe()

    if success then
        LR.notify(locale("opened_minisafe"), "success")

        local animDict = "anim_heist@arcade_property@arcade_safe_open@" .. (IsPedMale(cache.ped) and "male" or "female")
        local playerCoords = GetEntityCoords(cache.ped)
        local safeObj = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 5.0, Config.miniSafe.model, false, false, false)
        local objCoords = GetEntityCoords(safeObj)
        local rotation = GetEntityRotation(safeObj)

        local scene = NetworkCreateSynchronisedScene(objCoords.x - 4.189087, objCoords.y - 4.665955, objCoords.z - 2.372 + 0.003187,
            rotation.x, rotation.y, rotation.z + 90.0, 2, false, false, 1.0, 0.0, 1065353216)

        NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, "safe_open", 4.0, -4.0, 1037, 16, 1000.0, 0)
        NetworkAddMapEntityToSynchronisedScene(scene, Config.miniSafe.model, objCoords.x, objCoords.y, objCoords.z, animDict, "safe_open_safedoor", 1.0, -1.0, 1148846080)

        NetworkStartSynchronisedScene(scene)
        Wait(5000)

        TriggerServerEvent("lunar_contracts:mazebank:openMiniSafe", safeIndex)
        NetworkStopSynchronisedScene(scene)
        FreezeEntityPosition(safeObj, true)
    else
        LR.notify(locale("lockpick_failed"), "error")
    end

    Wait(2000)
    FreeOccupiedSpot()
end

-- Press garage button
local function pressGarageButton()
    if IsSpotOccupied("mazebank:garage_door") then
        return
    end

    LR.progressBar(locale("pressing_button"), 1000, false, {
        dict = "mini@repair",
        clip = "fixing_a_ped"
    })

    TriggerServerEvent("lunar_contracts:mazebank:toggleGarageDoor")
    FreeOccupiedSpot()
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
    id = "mazebank_cameras",
    title = locale("cameras_header"),
    options = Config.cameras.options
})

-- Remove security door
RegisterNetEvent("lunar_contracts:mazebank:removeSecurityDoor", function(doorIndex)
    if not isContractActive then
        return
    end

    if securityDoorPoints[doorIndex] then
        securityDoorPoints[doorIndex].remove()
        securityDoorPoints[doorIndex] = nil
    end
end)

-- Remove keypad
RegisterNetEvent("lunar_contracts:mazebank:removeKeypad", function(keypadIndex)
    if not isContractActive then
        return
    end

    if keypadPoints[keypadIndex] then
        keypadPoints[keypadIndex].remove()
        keypadPoints[keypadIndex] = nil
    end
end)

-- Remove elevator door
RegisterNetEvent("lunar_contracts:mazebank:removeElevatorDoor", function()
    if not elevatorDoorPoint then
        return
    end
    elevatorDoorPoint.remove()
    elevatorDoorPoint = nil
end)

-- Remove generator
RegisterNetEvent("lunar_contracts:mazebank:removeGenerator", function(generatorIndex)
    if not isContractActive then
        return
    end

    if generatorPoints[generatorIndex] then
        generatorPoints[generatorIndex].remove()
        generatorPoints[generatorIndex] = nil
    end
end)

-- Remove circuit
RegisterNetEvent("lunar_contracts:mazebank:removeCircuit", function()
    circuitOverloaded = true
    if not circuitPoint then
        return
    end
    circuitPoint.remove()
    circuitPoint = nil
end)

RegisterNetEvent("lunar_contracts:mazebank:circuitOverloaded", function()
    circuitOverloaded = true
end)

-- Remove mini safe
RegisterNetEvent("lunar_contracts:mazebank:removeMiniSafe", function(safeIndex)
    if not isContractActive then
        return
    end

    if miniSafePoints[safeIndex] then
        miniSafePoints[safeIndex].remove()
        miniSafePoints[safeIndex] = nil
    end
end)

-- Laser alarm trigger
local function triggerLaserAlarm()
    if not alarmTriggered then
        TriggerServerEvent("lunar_contracts:mazebank:triggerAlarm")
        alarmTriggered = true
    end
end

-- Create lasers
if Laser then
for i = 1, math.min(#Config.lasers.origins, #Config.lasers.ends) do
    local origin = Config.lasers.origins[i]
    local target = Config.lasers.ends[i]

    local laser = Laser.new(origin, { target }, {
        maxDistance = #(origin - target),
        name = "mazebank_" .. i,
        color = { 255, 0, 0, 120 }
    })

    laser.onPlayerHit(triggerLaserAlarm)
    lasers[#lasers + 1] = laser
end
end

-- Create lasers zone
RegisterNetEvent("lunar_contracts:mazebank:createLasers", function()
    laserZone = lib.zones.sphere({
        coords = Config.lasers.render.coords,
        radius = Config.lasers.render.radius,
        debug = Config.lasers.render.debug,
        onEnter = function()
            for _, laser in ipairs(lasers) do
                laser.setActive(true)
            end
        end,
        onExit = function()
            for _, laser in ipairs(lasers) do
                laser.setActive(false)
            end
        end
    })
    alarmTriggered = false
end)

-- Disable lasers event
RegisterNetEvent("lunar_contracts:mazebank:disableLasers", function()
    if electricBoxPoint then
        electricBoxPoint.remove()
        electricBoxPoint = nil
    end

    if laserZone then
        laserZone:onExit()
        laserZone.remove()
    end
end)

-- Alarm system
local alarmPoint = nil

RegisterNetEvent("lunar_contracts:mazebank:alarmTriggered", function()
    local soundId = GetSoundId()
    local alarmCoords = Config.alarm.coords

    alarmPoint = lib.points.new({
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
        if alarmPoint then
            alarmPoint:onExit()
            alarmPoint.remove()
            alarmPoint = nil
        end
    end)

    TriggerEvent("lunar_contracts:mazebank:disableLasers")
end)

-- Remove alarm
RegisterNetEvent("lunar_contracts:mazebank:removeAlarm", function()
    if alarmPoint then
        alarmPoint:onExit()
        alarmPoint.remove()
        alarmPoint = nil
    end
end)

-- Initialize contract
local function initializeContract(laptopLocations, computerCode)
    isContractActive = true
    computerCodes = computerCode
    circuitOverloaded = false
    print("[Mazebank Client] computerCodes received: " .. tostring(computerCode ~= nil) .. " count: " .. tostring(computerCode and #computerCode or 0))

    -- Security doors
    for i = 1, #Config.securityDoors.locations do
        local doorConfig = Config.securityDoors.locations[i]

        if doorConfig.keypad then
            Utils.createProp(doorConfig.keypad, { model = -2122821887 })
        end

        securityDoorPoints[i] = Utils.createInteractionPoint({
            coords = doorConfig.keypad and doorConfig.keypad.xyz or GetDoorCoords(doorConfig),
            radius = doorConfig.keypad and 0.3 or 1.0,
            options = {{
                label = locale("hack_door"),
                icon = "code",
                onSelect = hackSecurityDoor,
                args = i,
                canInteract = function() return not Busy end
            }}
        })
    end

    -- Sewer generators
    if Config.sewers then
        for i = 1, #Config.sewers.generators.locations do
            generatorPoints[i] = Utils.createInteractionPoint({
                coords = Config.sewers.generators.locations[i],
                radius = 1.0,
                options = {{
                    label = locale("disable_locks"),
                    icon = "code",
                    onSelect = disableGenerator,
                    args = i,
                    canInteract = function() return not Busy end
                }}
            })
        end
    end

    -- Keypad doors
    for i = 1, #Config.keypadDoors.keypads do
        keypadPoints[i] = Utils.createInteractionPoint({
            coords = Config.keypadDoors.keypads[i],
            radius = 1.0,
            options = {{
                label = locale("enter_code"),
                icon = "key",
                onSelect = enterKeypadCode,
                args = i,
                canInteract = function() return not Busy end
            }}
        })
    end

    -- Laptops
    for i = 1, #laptopLocations do
        laptopPoints[i] = Utils.createInteractionPoint({
            coords = laptopLocations[i],
            radius = 1.0,
            options = {{
                label = locale("hack_laptop"),
                icon = "code",
                onSelect = hackLaptop,
                args = { index = i, coords = laptopLocations[i] },
                canInteract = function() return not Busy end
            }}
        })
    end

    -- Electric box (lasers)
    electricBoxPoint = Utils.createInteractionPoint({
        coords = Config.lasers.electricBox.coords,
        radius = 1.0,
        options = {{
            label = locale("disable_lasers"),
            icon = "code",
            onSelect = disableLasers,
            canInteract = function() return not Busy end
        }}
    })

    -- Elevator door
    if Config.elevator then
        elevatorDoorPoint = Utils.createInteractionPoint({
            coords = GetDoorCoords(Config.elevator.door),
            radius = 1.25,
            options = {{
                label = locale("open_elevator_door"),
                icon = "door-open",
                onSelect = openElevatorDoor,
                canInteract = function() return not Busy end
            }}
        })
    end

    -- Server room terminal
    terminalPoint = Utils.createInteractionPoint({
        coords = Config.serverRoomTerminal.coords,
        radius = 1.0,
        options = {{
            label = locale("access_terminal"),
            icon = "code",
            onSelect = accessServerTerminal,
            canInteract = function() return not Busy end
        }}
    })

    -- Cameras
    for i = 1, #Config.cameras.desks do
        cameraPoints[i] = Utils.createInteractionPoint({
            coords = Config.cameras.desks[i],
            radius = 1.25,
            options = {{
                label = locale("open_cameras"),
                icon = "camera",
                onSelect = function() lib.showContext("mazebank_cameras") end,
                canInteract = function() return not Busy end
            }}
        })
    end

    -- Circuit overload
    circuitPoint = Utils.createInteractionPoint({
        coords = Config.basement.circuitOverload.coords,
        radius = 1.0,
        options = {{
            label = locale("overload_circuit"),
            icon = "code",
            onSelect = overloadCircuit,
            canInteract = function() return not Busy end
        }}
    })

    -- Mini safes
    if Config.miniSafe then
        for i = 1, #Config.miniSafe.locations do
            miniSafePoints[i] = Utils.createInteractionPoint({
                coords = Config.miniSafe.locations[i],
                radius = 1.0,
                options = {{
                    label = locale("open_minisafe"),
                    icon = "vault",
                    onSelect = openMiniSafe,
                    args = i,
                    canInteract = function() return not Busy end
                }}
            })
        end
    end

    -- Garage panel
    garagePanelPoint = Utils.createInteractionPoint({
        coords = Config.garage.panel,
        radius = 1.0,
        options = {{
            label = locale("press_button"),
            icon = "hand",
            onSelect = pressGarageButton,
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
RegisterNetEvent("lunar_contracts:mazebank:started", function(players, laptopLocations, computerCode)
    local identifier = Framework.getIdentifier()
    for _, playerId in ipairs(players) do
        if identifier == playerId then
            initializeContract(laptopLocations, computerCode)
        end
    end
end)

-- Reset contract
RegisterNetEvent("lunar_contracts:mazebank:reset", function()
    if not isContractActive then
        return
    end

    circuitOverloaded = false
    TriggerEvent("lunar_contracts:mazebank:removeAlarm")
    TriggerEvent("lunar_contracts:mazebank:disableLasers")

    for _, point in pairs(securityDoorPoints) do
        if point then point.remove() end
    end
    table.wipe(securityDoorPoints)

    for _, point in pairs(generatorPoints) do
        if point then point.remove() end
    end
    table.wipe(generatorPoints)

    if electricBoxPoint then
        electricBoxPoint.remove()
        electricBoxPoint = nil
    end

    for _, point in pairs(keypadPoints) do
        if point then point.remove() end
    end
    table.wipe(keypadPoints)

    for _, point in pairs(laptopPoints) do
        if point then point.remove() end
    end
    table.wipe(laptopPoints)

    if elevatorDoorPoint then
        elevatorDoorPoint.remove()
        elevatorDoorPoint = nil
    end

    if terminalPoint then
        terminalPoint.remove()
        terminalPoint = nil
    end

    for _, point in pairs(cameraPoints) do
        if point then point.remove() end
    end
    table.wipe(cameraPoints)

    if circuitPoint then
        circuitPoint.remove()
        circuitPoint = nil
    end

    if garagePanelPoint then
        garagePanelPoint.remove()
        garagePanelPoint = nil
    end

    if blip then
        blip.remove()
        blip = nil
    end

    isContractActive = false
end)