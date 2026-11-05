-- Preload animation dictionaries
PreloadDicts(
    "anim_heist@hs3f@ig1_hack_keypad@arcade@male@",
    "anim_heist@hs3f@ig1_hack_keypad@arcade@female@",
    "anim@heists@ornate_bank@hack",
    "anim@scripted@player@mission@tun_control_tower@male@",
    "anim_heist@arcade_property@arcade_safe_open@male@",
    "anim_heist@arcade_property@arcade_safe_open@female@",
    "anim_heist@hs3f@ig11_steal_painting@male@"
)

local Config = Config.contracts.paleto
local minigames = Editable.minigames.paleto

-- State variables
local isContractActive = false
local electricBoxPoint = nil
local surveilancePanelPoint = nil
local camerasPoint = nil
local terminalPoint = nil
local computerPoints = {}
local vaultPanelPoint = nil
local safePoint = nil
local paintingPoints = {}
local depositBoxPoints = {}
local paintingFixedPoints = {}
local safeOpen = false
local blip = nil

-- Terminal prop offsets
local terminalPropCoords = Config.terminal.prop
local offsets = {
    vector3(0.0, 0.15, -0.85),
    vector3(0.0, 0.15, 0.15),
    vector3(0.6, 0.15, -0.85),
    vector3(0.6, 0.15, 0.15),
    vector3(-0.6, 0.15, -0.85),
    vector3(-0.6, 0.15, 0.15)
}

-- Create terminal props
for i = 1, #offsets do
    Utils.createProp(terminalPropCoords, {
        model = 1030147405,
        offset = offsets[i]
    })
end

-- Fix misplaced props
local propModel = 536071214
local propLocations = {
    vector3(-97.423187, 6466.123535, 31.080677),
    vector3(-103.027519, 6460.501465, 31.080677)
}

local propFixed = {}

for i = 1, #propLocations do
    lib.points.new({
        coords = propLocations[i],
        distance = 30.0,
        onEnter = function()
            local obj = GetClosestObjectOfType(propLocations[i].x, propLocations[i].y, propLocations[i].z, 1.0, propModel, false, false, false)
            if DoesEntityExist(obj) and not propFixed[obj] then
                local fixedCoords = GetOffsetFromEntityInWorldCoords(obj, 0.0, -0.2, 0.0)
                SetEntityCoords(obj, fixedCoords.x, fixedCoords.y, fixedCoords.z)
                propFixed[obj] = true
            end
        end
    })
end

-- Resource stop handler
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= cache.resource then
        return
    end

    for i = 1, #propLocations do
        local obj = GetClosestObjectOfType(propLocations[i].x, propLocations[i].y, propLocations[i].z, 1.0, propModel, false, false, false)
        if DoesEntityExist(obj) then
            local resetCoords = GetOffsetFromEntityInWorldCoords(obj, 0.0, 0.2, 0.0)
            SetEntityCoords(obj, resetCoords.x, resetCoords.y, resetCoords.z)
        end
    end
end)

-- Remove props on enter
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

-- Disable smart locks (electric box hack)
local function disableSmartLocks()
    if Config.authorized.electricBox.requiredItem then
        if not Framework.hasItem(Config.authorized.electricBox.requiredItem) then
            LR.notify(locale("missing_" .. Config.authorized.electricBox.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied("paleto:disable_smart_locks") then
        return
    end

    local animDict = "anim@scripted@player@mission@tun_control_tower@male@"
    local boxCoords = Config.authorized.electricBox.coords.xyz
    local boxModel = Config.authorized.electricBox.model

    local boxObj = GetClosestObjectOfType(boxCoords.x, boxCoords.y, boxCoords.z, 2.0, boxModel, false, false, false)
    local objCoords = GetEntityCoords(boxObj)
    local rotation = GetEntityRotation(boxObj)

    -- Enter scene
    local enterScene = NetworkCreateSynchronisedScene(objCoords.x, objCoords.y, objCoords.z,
        rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, enterScene, animDict, "enter", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(boxObj, enterScene, animDict, "enter_electric_box", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(enterScene)
    Wait((GetAnimDuration(animDict, "enter") * 1000) - 200)

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

    NetworkStartSynchronisedScene(loopScene)

    local success = minigames.smartLocks()

    if success then
        TriggerServerEvent("lunar_contracts:paleto:unlockAuthorizedDoors")
        LR.notify(locale("disabled_smart_locks"), "success")
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

-- Unlock surveilance room
local function unlockSurveilanceRoom()
    if Config.surveilanceRoom.panel.requiredItem then
        if not Framework.hasItem(Config.surveilanceRoom.panel.requiredItem) then
            LR.notify(locale("missing_" .. Config.surveilanceRoom.panel.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied("paleto:unlock_surveilance_room") then
        return
    end

    local offsetCoords = Utils.offsetCoords(Config.surveilanceRoom.panel.coords, 0.0, 0.05, -0.125)
    local animDict = "anim_heist@hs3f@ig1_hack_keypad@arcade@" .. (IsPedMale(cache.ped) and "male@" or "female@")

    lib.requestModel(-1746470518)
    lib.requestModel(413312110)

    local usbDrive = CreateSceneObject(-1746470518, offsetCoords)
    local phone = CreateSceneObject(413312110, offsetCoords)

    local rotation = vector3(0.0, 0.0, offsetCoords.w)

    -- Intro scene
    local introScene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z,
        rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, introScene, animDict, "action_var_01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbDrive, introScene, animDict, "action_var_01_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phone, introScene, animDict, "action_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)

    -- Loop scene
    local loopScene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, true, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "hack_loop_var_01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbDrive, loopScene, animDict, "hack_loop_var_01_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phone, loopScene, animDict, "hack_loop_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(introScene)
    Wait((GetAnimDuration(animDict, "action_var_01") * 1000) - 500)

    NetworkStartSynchronisedScene(loopScene)

    local success = minigames.unlockSurveilance()

    if success then
        LR.notify(locale("unlocked_surveilance_room"), "success")
        TriggerServerEvent("lunar_contracts:paleto:unlockSurveilanceRoom")
    else
        LR.notify(locale("hack_failed"), "error")
    end

    -- Reaction scene
    local reactionScene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)

    local reactionAnim = success and "success_react_exit_var_02" or "fail_react"

    NetworkAddPedToSynchronisedScene(cache.ped, reactionScene, animDict, reactionAnim, -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbDrive, reactionScene, animDict, reactionAnim .. "_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phone, reactionScene, animDict, reactionAnim .. "_prop_phone_ing", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(reactionScene)
    Wait((GetAnimDuration(animDict, reactionAnim) * 1000) - 500)

    -- Exit animation on failure
    if not success then
        local exitScene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z,
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

-- Hack office computer
local function hackOfficeComputer(computerIndex)
    if Config.offices.computers.requiredItem then
        if not Framework.hasItem(Config.offices.computers.requiredItem) then
            LR.notify(locale("missing_" .. Config.offices.computers.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied(string.format("paleto:computer_%s", computerIndex)) then
        return
    end

    local computerCoords = Config.offices.computers.locations[computerIndex]
    local animDict = "missheist_jewel@hacking"
    local animClip = "hack_loop"

    Utils.makeEntityFaceCoords(cache.ped, computerCoords)
    lib.requestAnimDict(animDict)

    TaskPlayAnim(cache.ped, animDict, animClip, 4.0, 4.0, -1, 1, 1.0, false, false, false)

    LR.progressBar(locale("init_hack"), 3000, false)

    local success = minigames.computer()

    if success then
        LR.notify(locale("hacked_computer"), "success")
        TriggerServerEvent("lunar_contracts:paleto:hackedOfficeComputer", computerIndex)
    else
        LR.notify(locale("hack_failed"), "error")
    end

    RemoveAnimDict(animDict)
    ClearPedTasks(cache.ped)
    FreeOccupiedSpot()
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

-- Camera viewing
local cameraActive = false
local currentScrambledCode = nil

local function viewCamera(cameraCoords)
    if Editable.isDead(cache.ped) then
        return
    end

    Busy = true
    Utils.makeEntityFaceCoords(cache.ped, Config.surveilanceRoom.cameras.coords)

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
        -10.0, 0.0, cameraCoords.w, 60.0, true, 2)

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
                local doorCoords = Config.offices.doors[closestDoorIndex].coords
                local shouldScramble = Config.offices.doors[closestDoorIndex].shouldScramble
                local displayCode = shouldScramble and scrambledCode or paintingFixedPoints[closestDoorIndex]
                Editable.draw3DText(doorCoords, displayCode)
            end

            -- Handle camera rotation
            if IsDisabledControlPressed(0, Config.cameraSettings.controls.left) and angleDiff < bounds.left then
                camRot = vector3(camRot.x, camRot.y, camRot.z + Config.cameraSettings.rotateSpeed)
            end

            if IsDisabledControlPressed(0, Config.cameraSettings.controls.right) and angleDiff > bounds.right then
                camRot = vector3(camRot.x, camRot.y, camRot.z - Config.cameraSettings.rotateSpeed)
            end

            if IsDisabledControlPressed(0, Config.cameraSettings.controls.up) and camRot.x < bounds.up then
                camRot = vector3(camRot.x + Config.cameraSettings.rotateSpeed, camRot.y, camRot.z)
            end

            if IsDisabledControlPressed(0, Config.cameraSettings.controls.down) and camRot.x > bounds.down then
                camRot = vector3(camRot.x - Config.cameraSettings.rotateSpeed, camRot.y, camRot.z)
            end

            SetCamRot(cam, camRot.x, camRot.y, camRot.z, 2)
            Wait(0)
        end
    end)

    -- Door detection thread
    CreateThread(function()
        while cameraRunning do
            local closest = { index = nil, dist = math.huge }

            for i = 1, #Config.offices.doors do
                local doorCoords = Config.offices.doors[i].coords
                local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(doorCoords.x, doorCoords.y, doorCoords.z)

                if onScreen then
                    local distance = math.sqrt((screenX - 0.5) ^ 2 + (screenY - 0.5) ^ 2)

                    if distance < 0.1 then
                        local worldDist = #(cameraCoords.xyz - doorCoords)
                        if worldDist < closest.dist then
                            local hit = raycastProbe(cameraCoords.xyz, doorCoords)
                            if not hit then
                                closest = { index = i, dist = worldDist }
                            end
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

-- Unlock vault code input
local function unlockVault()
    local input = lib.inputDialog(locale("vault_header"), {{
        type = "input",
        label = locale("code"),
        description = locale("vault_code"),
        icon = "qrcode"
    }})

    if not input then
        return
    end

    TriggerServerEvent("lunar_contracts:paleto:unlockVault", input[1])
end

-- Vault minigame callback
lib.callback.register("lunar_contracts:paleto:vaultMinigame", function()
    if not Framework.hasItem(Config.vault.panel.requiredItem) then
        LR.notify(locale("missing_" .. Config.vault.panel.requiredItem), "error")
        return
    end

    if IsSpotOccupied("paleto:unlock_vault") then
        return
    end

    local animDict = "anim@heists@ornate_bank@hack"
    local panelCoords = Config.vault.panel.coords

    local panelObj = GetClosestObjectOfType(panelCoords.x, panelCoords.y, panelCoords.z, 2.0,
        Config.vault.panel.model, false, false, false)

    local objCoords = GetEntityCoords(panelObj)
    local offsetCoords = Utils.offsetCoords(vector4(objCoords.x, objCoords.y, objCoords.z, GetEntityHeading(panelObj)), 0.0, 0.05, 0.0)

    lib.requestModel(-944468481)
    lib.requestModel(-411901183)
    lib.requestModel(-676527372)

    local suitBag = CreateSceneObject(-944468481, offsetCoords)
    local keycard = CreateSceneObject(-411901183, offsetCoords)
    local laptop = CreateSceneObject(-676527372, offsetCoords)

    local rotation = GetEntityRotation(panelObj)

    -- Enter scene
    local enterScene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z,
        rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, enterScene, animDict, "hack_enter", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(suitBag, enterScene, animDict, "hack_enter_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, enterScene, animDict, "hack_enter_laptop", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(keycard, enterScene, animDict, "hack_enter_card", 1.0, -1.0, 1148846080)

    -- Loop scene
    local loopScene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, true, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "hack_loop", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(suitBag, loopScene, animDict, "hack_loop_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, loopScene, animDict, "hack_loop_laptop", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(keycard, loopScene, animDict, "hack_loop_card", 1.0, -1.0, 1148846080)

    -- Exit scene
    local exitScene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "hack_exit", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(suitBag, exitScene, animDict, "hack_exit_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, exitScene, animDict, "hack_exit_laptop", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(keycard, exitScene, animDict, "hack_exit_card", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(enterScene)
    Wait((GetAnimDuration(animDict, "hack_enter") * 1000) - 200)

    NetworkStartSynchronisedScene(loopScene)

    local success = minigames.unlockVault()

    if success then
        LR.notify(locale("vault_unlocked"), "success")
    else
        LR.notify(locale("hack_failed"), "error")
    end

    CreateThread(function()
        NetworkStartSynchronisedScene(exitScene)
        Wait((GetAnimDuration(animDict, "hack_exit") * 1000) - 500)

        DeleteEntity(suitBag)
        DeleteEntity(laptop)
        DeleteEntity(keycard)
        SetModelAsNoLongerNeeded(-944468481)
        SetModelAsNoLongerNeeded(-411901183)
        SetModelAsNoLongerNeeded(-676527372)
        Wait(1000)
        FreeOccupiedSpot()
    end)

    return success
end)

-- Office door hack callback
lib.callback.register("lunar_contracts:paleto:officeDoorHack", function()
    if Config.terminal.requiredItem then
        if not Framework.hasItem(Config.terminal.requiredItem) then
            LR.notify(locale("missing_" .. Config.terminal.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied("paleto:terminal") then
        return
    end

    local animDict = "anim@heists@ornate_bank@hack"
    local offsetCoords = Utils.offsetCoords(Config.terminal.coords, -0.34, 0.1, 0.2)

    lib.requestModel(-944468481)
    lib.requestModel(-411901183)
    lib.requestModel(-676527372)

    local suitBag = CreateSceneObject(-944468481, offsetCoords)
    local keycard = CreateSceneObject(-411901183, offsetCoords)
    local laptop = CreateSceneObject(-676527372, offsetCoords)

    -- Enter scene
    local enterScene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z,
        0.0, 0.0, offsetCoords.w, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, enterScene, animDict, "hack_enter", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(suitBag, enterScene, animDict, "hack_enter_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(keycard, enterScene, animDict, "hack_enter_card", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, enterScene, animDict, "hack_enter_laptop", 1.0, -1.0, 1148846080)

    -- Loop scene
    local loopScene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z,
        0.0, 0.0, offsetCoords.w, 2, false, true, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "hack_loop", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(suitBag, loopScene, animDict, "hack_loop_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(keycard, loopScene, animDict, "hack_loop_card", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, loopScene, animDict, "hack_loop_laptop", 1.0, -1.0, 1148846080)

    -- Exit scene
    local exitScene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z,
        0.0, 0.0, offsetCoords.w, 2, false, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "hack_exit", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(suitBag, exitScene, animDict, "hack_exit_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(keycard, exitScene, animDict, "hack_exit_card", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, exitScene, animDict, "hack_exit_laptop", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(enterScene)
    Wait((GetAnimDuration(animDict, "hack_enter") * 1000) - 200)

    NetworkStartSynchronisedScene(loopScene)

    local success = minigames.unlockOffice()

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

-- Terminal code input
local function accessTerminal()
    if Config.terminal.requiredItem then
        if not Framework.hasItem(Config.terminal.requiredItem) then
            LR.notify(locale("missing_" .. Config.terminal.requiredItem), "error")
            return
        end
    end

    local input = lib.inputDialog(locale("terminal_header"), {{
        type = "input",
        label = locale("code"),
        description = locale("office_door_code"),
        icon = "qrcode"
    }})

    if not input then
        return
    end

    TriggerServerEvent("lunar_contracts:paleto:unlockOfficeDoor", input[1])
end

-- Safe open state
local safeShouldOpen = false

RegisterNetEvent("lunar_contracts:paleto:setSafeOpen", function()
    safeShouldOpen = true
end)

-- Safe rotation handling
local safeCoords = Config.offices.safe.coords
local safeRotated = {}

SetInterval(function()
    if not Utils.distanceCheck(cache.ped, safeCoords, 30.0) then
        return
    end

    local safeObj = GetClosestObjectOfType(safeCoords.x, safeCoords.y, safeCoords.z, 1.0,
        Config.offices.safe.model, false, false, false)

    if not DoesEntityExist(safeObj) then
        return
    end

    if safeShouldOpen then
        if not safeRotated[safeObj] then
            SetEntityHeading(safeObj, GetEntityHeading(safeObj) + 135.0)
            safeRotated[safeObj] = true
        end
    else
        if safeRotated[safeObj] then
            SetEntityHeading(safeObj, GetEntityHeading(safeObj) - 135.0)
            safeRotated[safeObj] = nil
        end
    end
end, 1000)

-- Lockpick safe
local function lockpickSafe()
    if IsSpotOccupied("paleto:safe") then
        return
    end

    local success = minigames.unlockSafe()

    if success then
        LR.notify(locale("opened_safe"), "success")
        TriggerServerEvent("lunar_contracts:paleto:openSafe")
    else
        LR.notify(locale("lockpick_failed"), "error")
    end

    FreeOccupiedSpot()
end

-- Steal painting animation
local function stealPainting(data)
    local index = data.index
    local locationIndex = data.locationIndex
    local animDict = "anim_heist@hs3f@ig11_steal_painting@male@"

    if IsSpotOccupied(string.format("paleto:painting_%s_%s", index, locationIndex)) then
        return
    end

    lib.requestModel(-944468481)
    lib.requestModel(-963831200)

    local offsetCoords = Utils.offsetCoords(Config.offices.paintings.locations[index][locationIndex], 0.0, 0.0, -0.1).xyz
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

    TriggerServerEvent("lunar_contracts:paleto:stealPainting", index, locationIndex)

    DeleteEntity(bag)
    DeleteEntity(knife)
    SetModelAsNoLongerNeeded(-944468481)
    SetModelAsNoLongerNeeded(-963831200)
    FreeOccupiedSpot()
end

-- Remove electric box
RegisterNetEvent("lunar_contracts:paleto:removeElectricBox", function()
    if not electricBoxPoint then
        return
    end
    electricBoxPoint.remove()
    electricBoxPoint = nil
end)

-- Remove surveilance room panel
RegisterNetEvent("lunar_contracts:paleto:removeSurveilanceRoomPanel", function()
    if not surveilancePanelPoint then
        return
    end
    surveilancePanelPoint.remove()
    surveilancePanelPoint = nil
end)

-- Office door hacked event
RegisterNetEvent("lunar_contracts:paleto:officeDoorHacked", function(officeIndex)
    if not isContractActive then
        return
    end

    -- Computer interaction point
    computerPoints[officeIndex] = Utils.createInteractionPoint({
        coords = Config.offices.computers.locations[officeIndex],
        radius = 1.0,
        options = {{
            label = locale("hack_computer"),
            icon = "code",
            onSelect = hackOfficeComputer,
            args = officeIndex,
            canInteract = function() return not Busy end
        }}
    })

    -- Painting interaction points
    paintingPoints[officeIndex] = {}

    for i = 1, #Config.offices.paintings.locations[officeIndex] do
        paintingPoints[officeIndex][i] = Utils.createInteractionPoint({
            coords = Utils.offsetCoords(Config.offices.paintings.locations[officeIndex][i], 0.0, 0.0, -0.1),
            radius = 1.0,
            options = {{
                label = locale("steal_painting"),
                icon = "user-ninja",
                onSelect = stealPainting,
                args = { index = officeIndex, locationIndex = i },
                canInteract = function()
                    return not Busy and Utils.distanceCheck(cache.ped,
                        Utils.offsetCoords(Config.offices.paintings.locations[officeIndex][i], 0.0, 0.0, -0.1).xyz, 1.0)
                end
            }}
        })
    end

    -- Safe interaction for last office
    if officeIndex == #Config.offices.computers.locations then
        safePoint = Utils.createInteractionPoint({
            coords = Config.offices.safe.coords,
            radius = 1.0,
            options = {
                {
                    label = locale("lockpick_safe"),
                    icon = "vault",
                    onSelect = lockpickSafe,
                    canInteract = function() return not (Busy or safeOpen) end
                },
                {
                    label = locale("take_safe_loot"),
                    icon = "vault",
                    onSelect = function()
                        if IsSpotOccupied("paleto:safe") then
                            return
                        end
                        TriggerServerEvent("lunar_contracts:paleto:openSafe")
                        Wait(1000)
                        FreeOccupiedSpot()
                    end,
                    canInteract = function() return not (Busy or not safeOpen) end
                }
            }
        })
    end
end)

-- Remove vault panel
RegisterNetEvent("lunar_contracts:paleto:removeVaultPanel", function()
    if not vaultPanelPoint then
        return
    end
    vaultPanelPoint.remove()
    vaultPanelPoint = nil
end)

-- Show code
RegisterNetEvent("lunar_contracts:paleto:showCode", function(code)
    Wait(1000)
    lib.alertDialog({
        header = locale("hacked_code"),
        content = code,
        cancel = false,
        centered = true,
        labels = { confirm = locale("understood") }
    })
end)

-- Alarm triggered
RegisterNetEvent("lunar_contracts:paleto:alarmTriggered", function()
    local soundId = GetSoundId()
    local alarmCoords = Config.alarm.coords

    local point = lib.points.new({
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
        point:onExit()
        point.remove()
    end)
end)

-- Set safe as lootable
RegisterNetEvent("lunar_contracts:paleto:setSafeAsLootable", function()
    safeOpen = true
end)

-- Remove safe
RegisterNetEvent("lunar_contracts:paleto:removeSafe", function()
    if not safePoint then
        return
    end
    safePoint.remove()
    safePoint = nil
end)

-- Remove deposit box
RegisterNetEvent("lunar_contracts:paleto:removeDepositBox", function(boxIndex)
    if not depositBoxPoints[boxIndex] then
        return
    end
    depositBoxPoints[boxIndex].remove()
    depositBoxPoints[boxIndex] = nil
end)

-- Room ID sync
local roomSyncActive = false

RegisterNetEvent("lunar_contracts:paleto:syncRoomId", function(pedIds)
    roomSyncActive = true

    for i = 1, #pedIds do
        local pedId = pedIds[i]

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

-- Camera options setup
for i = 1, #Config.surveilanceRoom.cameras.options do
    local option = Config.surveilanceRoom.cameras.options[i]
    option.onSelect = viewCamera
    option.args = option.coords
    option.icon = "camera"
end

-- Register camera context
lib.registerContext({
    id = "paleto_cameras",
    title = locale("cameras_header"),
    options = Config.surveilanceRoom.cameras.options
})

-- Initialize contract
local function initializeContract(computerCode)
    isContractActive = true
    paintingFixedPoints = computerCode

    -- Electric box
    electricBoxPoint = Utils.createInteractionPoint({
        coords = Config.authorized.electricBox.coords,
        radius = 1.0,
        options = {{
            label = locale("disable_smart_locks"),
            icon = "code",
            onSelect = disableSmartLocks,
            canInteract = function() return not Busy end
        }}
    })

    -- Surveilance panel
    surveilancePanelPoint = Utils.createInteractionPoint({
        coords = Config.surveilanceRoom.panel.coords,
        radius = 1.0,
        options = {{
            label = locale("disable_lock"),
            icon = "code",
            onSelect = unlockSurveilanceRoom,
            canInteract = function() return not (Busy or electricBoxPoint) end
        }}
    })

    -- Cameras
    camerasPoint = Utils.createInteractionPoint({
        coords = Config.surveilanceRoom.cameras.coords,
        radius = 1.0,
        options = {{
            label = locale("open_cameras"),
            icon = "camera",
            onSelect = function() lib.showContext("paleto_cameras") end,
            canInteract = function() return not (Busy or surveilancePanelPoint) end
        }}
    })

    -- Terminal
    terminalPoint = Utils.createInteractionPoint({
        coords = Config.terminal.coords,
        radius = 1.0,
        options = {{
            label = locale("access_terminal"),
            icon = "code",
            onSelect = accessTerminal,
            canInteract = function() return not (Busy or electricBoxPoint) end
        }}
    })

    -- Vault panel
    vaultPanelPoint = Utils.createInteractionPoint({
        coords = Config.vault.panel.coords,
        radius = 1.25,
        options = {{
            label = locale("unlock_vault"),
            icon = "code",
            onSelect = unlockVault,
            canInteract = function() return not Busy end
        }}
    })

    -- Deposit boxes
    for i = 1, #Config.vault.drilling.locations do
        local drillCoords = Config.vault.drilling.locations[i]

        depositBoxPoints[i] = Utils.createInteractionPoint({
            coords = drillCoords,
            radius = 1.0,
            options = {{
                label = locale("drill_deposit_box"),
                icon = "sack-dollar",
                onSelect = function()
                    if Config.vault.drilling.requiredItem then
                        if not Framework.hasItem(Config.vault.drilling.requiredItem) then
                            LR.notify(locale("missing_" .. Config.vault.drilling.requiredItem), "error")
                            return
                        end
                    end

                    if IsSpotOccupied(string.format("paleto:drilling_%s", i)) then
                        return
                    end

                    local canDrill = lib.callback.await("lunar_contracts:paleto:canDrillDepositBox", false, i)
                    if not canDrill then
                        FreeOccupiedSpot()
                        return
                    end

                    local drillOffset = Utils.offsetCoords(drillCoords, 0.15, 0.0, -0.19)
                    local success = StartDrilling(drillOffset)

                    if success then
                        TriggerServerEvent("lunar_contracts:paleto:drillDepositBox", i)
                    end

                    FreeOccupiedSpot()
                end,
                canInteract = function() return not (Busy or vaultPanelPoint) end
            }}
        })
    end

    -- Blip
    blip = Utils.createBlip(Config.blip.coords, Config.blip)
    SetBlipRoute(blip.value, true)
    Utils.distanceWait(Config.blip.coords, 30.0)
    blip.remove()
end

-- Contract start event
RegisterNetEvent("lunar_contracts:paleto:started", function(players, computerCode)
    local identifier = Framework.getIdentifier()
    for _, playerId in ipairs(players) do
        if identifier == playerId then
            initializeContract(computerCode)
        end
    end
end)

-- Reset contract
RegisterNetEvent("lunar_contracts:paleto:reset", function()
    roomSyncActive = false

    if electricBoxPoint then
        electricBoxPoint.remove()
    end

    if surveilancePanelPoint then
        surveilancePanelPoint.remove()
    end

    if camerasPoint then
        camerasPoint.remove()
    end

    if terminalPoint then
        terminalPoint.remove()
    end

    for _, point in pairs(computerPoints) do
        point.remove()
    end
    table.wipe(computerPoints)

    if vaultPanelPoint then
        vaultPanelPoint.remove()
    end

    if safePoint then
        safePoint.remove()
    end

    for _, officePoints in pairs(paintingPoints) do
        for _, point in pairs(officePoints) do
            point.remove()
        end
    end
    table.wipe(paintingPoints)

    for _, point in pairs(depositBoxPoints) do
        point.remove()
    end
    table.wipe(depositBoxPoints)

    for i = 1, #paintingFixedPoints do
        if paintingFixedPoints[i] then
            paintingFixedPoints[i].remove()
        end
    end
    table.wipe(paintingFixedPoints)

    safeOpen = false

    if blip then
        blip.remove()
        blip = nil
    end
end)