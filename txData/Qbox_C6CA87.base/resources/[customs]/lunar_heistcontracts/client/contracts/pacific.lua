-- Preload animation dictionaries
PreloadDicts(
    "anim_heist@hs3f@ig1_hack_keypad@arcade@male@",
    "anim_heist@hs3f@ig1_hack_keypad@arcade@female@",
    "anim@heists@ornate_bank@hack",
    "anim_heist@arcade_property@arcade_safe_open@male",
    "anim_heist@arcade_property@arcade_safe_open@female",
    "anim@heists@humane_labs@finale@keycards"
)

local Config = Config.contracts.pacific
local minigames = Editable.minigames.pacific

local isContractActive = false
local keypadPoints = {}
local computerPoints = {}
local mainVaultPanelPoint = nil
local depositBoxPoints = {}
local blip = nil

-- Create keypad props
local keypadCoords = { table.unpack(Config.offices.keypads) }
keypadCoords[#keypadCoords + 1] = Config.mainOffice.keypad

for i = 1, #keypadCoords do
    local offsetCoords = Utils.offsetCoords(keypadCoords[i], 0.0, -0.03, 0.0)
    Utils.createProp(offsetCoords, { model = -2122821887 })
end

-- Create basement props
for i = 1, #Config.basement.props do
    local prop = Config.basement.props[i]
    Utils.createProp(prop.coords, {
        model = prop.model,
        offset = vector3(0.0, 0.0, -1.0)
    })
end

-- Keypad hacking function
local function hackKeypad(keypadIndex)
    -- Check required item
    if Config.offices.requiredItem then
        if not Framework.hasItem(Config.offices.requiredItem) then
            LR.notify(locale("missing_" .. Config.offices.requiredItem), "error")
            return
        end
    end

    -- Check spot occupancy
    if IsSpotOccupied(string.format("pacific:keypad_%s", keypadIndex)) then
        return
    end

    -- Get keypad coordinates
    local keypadCoords
    if keypadIndex <= #Config.offices.keypads then
        keypadCoords = Config.offices.keypads[keypadIndex]
    else
        keypadCoords = Config.mainOffice.keypad
    end

    local offsetCoords = Utils.offsetCoords(keypadCoords, 0.03, 0.0, 0.0)
    local animDict = "anim_heist@hs3f@ig1_hack_keypad@arcade@" .. (IsPedMale(cache.ped) and "male@" or "female@")

    -- Request models
    lib.requestModel(-1746470518)
    lib.requestModel(413312110)

    -- Create scene objects
    local usbDrive = CreateSceneObject(-1746470518, offsetCoords)
    local phone = CreateSceneObject(413312110, offsetCoords)

    -- Get keypad object
    local keypadObj = GetClosestObjectOfType(offsetCoords.x, offsetCoords.y, offsetCoords.z, 0.5, -2122821887, false, false, false)
    local rotation = GetEntityRotation(keypadObj)

    -- Create intro scene
    local introScene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z,
        rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, introScene, animDict, "action_var_01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbDrive, introScene, animDict, "action_var_01_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phone, introScene, animDict, "action_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)

    -- Create loop scene
    local loopScene = NetworkCreateSynchronisedScene(offsetCoords.x, offsetCoords.y, offsetCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, true, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "hack_loop_var_01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbDrive, loopScene, animDict, "hack_loop_var_01_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phone, loopScene, animDict, "hack_loop_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)

    -- Start intro
    NetworkStartSynchronisedScene(introScene)
    Wait((GetAnimDuration(animDict, "action_var_01") * 1000) - 500)

    -- Start loop
    NetworkStartSynchronisedScene(loopScene)

    -- Run minigame
    local success = minigames.keypad()
    if success then
        LR.notify(locale("hacked_keypad"), "success")
        TriggerServerEvent("lunar_contracts:pacific:hackedKeypad", keypadIndex)
    else
        LR.notify(locale("hack_failed"), "error")
    end

    -- Create reaction scene
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

    -- Cleanup
    DeleteEntity(usbDrive)
    DeleteEntity(phone)
    SetModelAsNoLongerNeeded(-1746470518)
    SetModelAsNoLongerNeeded(413312110)
    FreeOccupiedSpot()
end

-- Enterance keycard animation stop
local stopAnimationFlag = false

RegisterNetEvent("lunar_contracts:pacific:stopEnteranceAnimation", function(removePoints)
    if not isContractActive then
        return
    end

    stopAnimationFlag = false

    if removePoints then
        for _, point in ipairs(keypadPoints) do
            point.remove()
        end
    end
end)

-- Use enterance keycard
local function useEnteranceKeycard(panelIndex)
    local hasKeycard = lib.callback.await("lunar_contracts:pacific:useEnteranceKeycard", false, panelIndex)

    if not hasKeycard then
        LR.notify(locale("missing_" .. Config.basement.enterance.securityPanel.keycard), "error")
        return
    end

    if IsSpotOccupied(string.format("pacific:enterance_%s", panelIndex)) then
        return
    end

    local animDict = "anim@heists@humane_labs@finale@keycards"
    local panelCoords = Config.basement.enterance.securityPanel.locations[panelIndex]
    local panelObj = GetClosestObjectOfType(panelCoords.x, panelCoords.y, panelCoords.z, 2.0,
        Config.basement.enterance.securityPanel.model, false, false, false)

    local offset = Config.basement.enterance.securityPanel.offset
    local sceneCoords = GetOffsetFromEntityInWorldCoords(panelObj, offset.x, offset.y, offset.z)
    panelCoords = sceneCoords

    lib.requestModel(511938898)
    local keycardObj = CreateSceneObject(511938898, panelCoords)
    FreezeEntityPosition(keycardObj, true)

    local rotation = GetEntityRotation(panelObj)

    -- Intro scene
    local introScene = NetworkCreateSynchronisedScene(panelCoords.x, panelCoords.y, panelCoords.z,
        rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, introScene, animDict, "ped_a_intro_b", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(keycardObj, introScene, animDict, "ped_a_intro_b_keycard", 1.0, -1.0, 0)

    -- Loop scene
    local loopScene = NetworkCreateSynchronisedScene(panelCoords.x, panelCoords.y, panelCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, true, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "ped_a_loop", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(keycardObj, loopScene, animDict, "ped_a_loop_keycard", 1.0, -1.0, 0)

    -- Pass scene
    local passScene = NetworkCreateSynchronisedScene(panelCoords.x, panelCoords.y, panelCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, passScene, animDict, "ped_a_pass", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(keycardObj, passScene, animDict, "ped_a_pass_keycard", 1.0, -1.0, 0)

    -- Start scenes
    NetworkStartSynchronisedScene(introScene)
    Wait((GetAnimDuration(animDict, "ped_a_enter") * 1000) + 500)

    NetworkStartSynchronisedScene(loopScene)
    stopAnimationFlag = true

    while stopAnimationFlag do
        Wait(100)
    end

    NetworkStartSynchronisedScene(passScene)
    Wait((GetAnimDuration(animDict, "ped_a_exit") * 1000) - 500)

    -- Cleanup
    DeleteEntity(keycardObj)
    SetModelAsNoLongerNeeded(511938898)
    Wait(1000)
    FreeOccupiedSpot()
end

-- Generic doors terminal hack
local function hackGenericTerminal()
    if Config.genericDoors.requiredItem then
        if not Framework.hasItem(Config.genericDoors.requiredItem) then
            LR.notify(locale("missing_" .. Config.genericDoors.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied("main_office_terminal") then
        return
    end

    local terminalCoords = Config.genericDoors.terminal.coords
    local animDict = "anim_heist@hs3f@ig1_hack_keypad@arcade@" .. (IsPedMale(cache.ped) and "male@" or "female@")

    lib.requestModel(-1746470518)
    lib.requestModel(413312110)

    local usbDrive = CreateSceneObject(-1746470518, terminalCoords)
    local phone = CreateSceneObject(413312110, terminalCoords)

    local terminalObj = GetClosestObjectOfType(terminalCoords.x, terminalCoords.y, terminalCoords.z, 0.5,
        Config.genericDoors.terminal.model, false, false, false)
    local rotation = GetEntityRotation(terminalObj)

    -- Intro scene
    local introScene = NetworkCreateSynchronisedScene(terminalCoords.x, terminalCoords.y, terminalCoords.z,
        rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, introScene, animDict, "action_var_01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbDrive, introScene, animDict, "action_var_01_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phone, introScene, animDict, "action_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)

    -- Loop scene
    local loopScene = NetworkCreateSynchronisedScene(terminalCoords.x, terminalCoords.y, terminalCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, true, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "hack_loop_var_01", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbDrive, loopScene, animDict, "hack_loop_var_01_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phone, loopScene, animDict, "hack_loop_var_01_prop_phone_ing", 1.0, -1.0, 1148846080)

    -- Start intro
    NetworkStartSynchronisedScene(introScene)
    Wait((GetAnimDuration(animDict, "action_var_01") * 1000) - 500)

    -- Start loop
    NetworkStartSynchronisedScene(loopScene)

    local success = minigames.panelTerminal()

    if success then
        LR.notify(locale("hacked_keypad"), "success")
        TriggerServerEvent("lunar_contracts:pacific:openGenericDoors")
    else
        LR.notify(locale("hack_failed"), "error")
    end

    -- Reaction scene
    local reactionScene = NetworkCreateSynchronisedScene(terminalCoords.x, terminalCoords.y, terminalCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)

    local reactionAnim = success and "success_react_exit_var_02" or "fail_react"

    NetworkAddPedToSynchronisedScene(cache.ped, reactionScene, animDict, reactionAnim, -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(usbDrive, reactionScene, animDict, reactionAnim .. "_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(phone, reactionScene, animDict, reactionAnim .. "_prop_phone_ing", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(reactionScene)
    Wait((GetAnimDuration(animDict, reactionAnim) * 1000) - 500)

    -- Exit animation on failure
    if not success then
        local exitScene = NetworkCreateSynchronisedScene(terminalCoords.x, terminalCoords.y, terminalCoords.z,
            rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)

        NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "exit", -4.0, -4.0, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(usbDrive, exitScene, animDict, "exit_ch_prop_ch_usb_drive01x", 1.0, -1.0, 1148846080)
        NetworkAddEntityToSynchronisedScene(phone, exitScene, animDict, "exit_prop_phone_ing", 1.0, -1.0, 1148846080)

        NetworkStartSynchronisedScene(exitScene)
        Wait((GetAnimDuration(animDict, "exit") * 1000) - 500)
    end

    -- Cleanup
    DeleteEntity(usbDrive)
    DeleteEntity(phone)
    SetModelAsNoLongerNeeded(-1746470518)
    SetModelAsNoLongerNeeded(413312110)
    Wait(1000)
    FreeOccupiedSpot()
end

-- Thermal effect sync
RegisterNetEvent("lunar_contracts:pacific:syncEffect", function(coords)
    lib.requestNamedPtfxAsset("scr_ornate_heist")
    local particleFx = StartParticleFxLoopedAtCoord("scr_heist_ornate_thermal_burn", coords, 0.0, 0.0, 0.0, 1.0, 0, 0, false, false)
    Wait(13000)
    StopParticleFxLooped(particleFx, false)
    RemoveNamedPtfxAsset("scr_ornate_heist")
end)

-- Remove terminal
RegisterNetEvent("lunar_contracts:pacific:removeTerminal", function()
    if not isContractActive then
        return
    end
    mainVaultPanelPoint.disableOptions()
end)

-- Initialize contract
local function initializeContract()
    isContractActive = true

    -- Create keypad interaction points
    local allKeypads = {}
    for i, v in ipairs(Config.offices.keypads) do
        allKeypads[i] = v
    end
    allKeypads[#allKeypads + 1] = Config.mainOffice.keypad

    for i = 1, #allKeypads do
        keypadPoints[i] = Utils.createInteractionPoint({
            coords = allKeypads[i],
            radius = 0.75,
            options = {{
                label = locale("hack_keypad"),
                icon = "code",
                onSelect = hackKeypad,
                args = i,
                canInteract = function() return not Busy end
            }}
        })
    end

    -- Create enterance interaction points
    for i = 1, #Config.basement.enterance.securityPanel.locations do
        keypadPoints[i] = Utils.createInteractionPoint({
            coords = Config.basement.enterance.securityPanel.locations[i],
            radius = 0.75,
            options = {{
                label = locale("use_keycard"),
                icon = "credit-card",
                onSelect = useEnteranceKeycard,
                args = i,
                canInteract = function() return not Busy end
            }}
        })
    end

    -- Create blip
    blip = Utils.createBlip(Config.blip.coords, Config.blip)
    SetBlipRoute(blip.value, true)

    Utils.distanceWait(Config.blip.coords, 30.0)
    blip.remove()
end

-- Start contract event
RegisterNetEvent("lunar_contracts:pacific:started", function(players)
    local identifier = Framework.getIdentifier()
    for _, playerId in ipairs(players) do
        if identifier == playerId then
            initializeContract()
        end
    end
end)

-- Hack computer
local function hackComputer(computerIndex)
    if IsSpotOccupied(string.format("pacific:computer_%s", computerIndex)) then
        return
    end

    local computerCoords = Config.offices.computers[computerIndex]
    local animDict = "missheist_jewel@hacking"
    local animClip = "hack_loop"

    Utils.makeEntityFaceCoords(cache.ped, computerCoords)
    lib.requestAnimDict(animDict)

    TaskPlayAnim(cache.ped, animDict, animClip, 4.0, 4.0, -1, 1, 1.0, false, false, false)

    LR.progressBar(locale("init_hack"), 3000, false)

    local success = minigames.computer()

    if success then
        LR.notify(locale("hacked_computer"), "success")
        TriggerServerEvent("lunar_contracts:pacific:hackedComputer", computerIndex)
    else
        LR.notify(locale("hack_failed"), "error")
    end

    RemoveAnimDict(animDict)
    ClearPedTasks(cache.ped)
    FreeOccupiedSpot()
end

-- Office unlocked event
RegisterNetEvent("lunar_contracts:pacific:officeUnlocked", function(officeIndex)
    if not isContractActive then
        return
    end

    keypadPoints[officeIndex].remove()

    computerPoints[officeIndex] = Utils.createInteractionPoint({
        coords = Config.offices.computers[officeIndex],
        radius = 0.75,
        options = {{
            label = locale("hack_computer"),
            icon = "code",
            onSelect = hackComputer,
            args = officeIndex,
            canInteract = function() return not Busy end
        }}
    })
end)

-- Display computer code
local function displayComputerCode(code)
    lib.alertDialog({
        header = locale("computer_header"),
        content = locale("computer_content", code),
        centered = true
    })
end

-- Office computer hacked event
RegisterNetEvent("lunar_contracts:pacific:officeComputerHacked", function(officeIndex, code)
    if not isContractActive then
        return
    end

    computerPoints[officeIndex].remove()

    computerPoints[officeIndex] = Utils.createInteractionPoint({
        coords = Config.offices.computers[officeIndex],
        radius = 0.75,
        options = {{
            label = locale("read_code"),
            icon = "computer",
            onSelect = displayComputerCode,
            args = code
        }}
    })
end)

-- Safe state
local safeOpen = false

RegisterNetEvent("lunar_contracts:pacific:setSafeState", function(state)
    safeOpen = state
    if mainVaultPanelPoint and safeOpen then
        mainVaultPanelPoint.remove()
    end
end)

-- Safe model swap
local safeCoords = Config.mainOffice.safe

lib.points.new({
    coords = safeCoords,
    distance = 20.0,
    nearby = function()
        if safeOpen then
            CreateModelSwap(safeCoords.x, safeCoords.y, safeCoords.z, 4.0, 1098122770, 1337434777, true)
        end
        Wait(300)
    end,
    onExit = function()
        RemoveModelSwap(safeCoords.x, safeCoords.y, safeCoords.z, 4.0, 1098122770, 1337434777, true)
    end
})

-- Safe interaction
local function openSafe(success)
    if IsSpotOccupied("pacific:safe") then
        return
    end

    local animDict = "anim@scripted@heist@ig15_safe_crack@male@"
    local playerCoords = GetEntityCoords(cache.ped)
    local safeObj = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 5.0, 1098122770, false, false, false)
    local objCoords = GetEntityCoords(safeObj)
    local rotation = GetEntityRotation(safeObj)

    local scene = NetworkCreateSynchronisedScene(objCoords.x, objCoords.y, objCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)

    local animClip = success and "door_open_player" or "fail_player"
    local safeAnim = success and "door_open_safe" or "fail_safe"

    NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, animClip, -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddMapEntityToSynchronisedScene(scene, 1098122770, objCoords.x, objCoords.y, objCoords.z, animDict, safeAnim, 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(scene)
    Wait((GetAnimDuration(animDict, animClip) * 1000) - 800)

    FreezeEntityPosition(safeObj, true)

    if success then
        LR.notify(locale("opened_safe"), "success")
    else
        LR.notify(locale("wrong_code"), "error")
    end

    FreeOccupiedSpot()
end

-- Main office unlocked event
RegisterNetEvent("lunar_contracts:pacific:mainOfficeUnlocked", function()
    local numKeypads = #Config.offices.keypads
    keypadPoints[numKeypads + 1].remove()

    -- Safe interaction point
    mainVaultPanelPoint = Utils.createInteractionPoint({
        coords = Config.mainOffice.safe,
        radius = 0.75,
        options = {{
            label = locale("enter_code"),
            icon = "vault",
            onSelect = function()
                local codeLength = #Config.offices.computers * 2
                local input = lib.inputDialog(locale("safe_header"), {{
                    type = "input",
                    label = locale("code"),
                    min = codeLength,
                    max = codeLength,
                    icon = "key"
                }})

                if not input then return end

                local success = lib.callback.await("lunar_contracts:pacific:openSafe", false, input[1])
                openSafe(success)
            end,
            canInteract = function() return not Busy end
        }}
    })

    -- Terminal interaction point
    mainVaultPanelPoint = Utils.createProp(Config.genericDoors.terminal.coords, {
        model = Config.genericDoors.terminal.model
    }, {{
        label = locale("hack_central_locks"),
        icon = "lock",
        onSelect = hackGenericTerminal,
        canInteract = function() return not Busy end
    }})
end)

-- Side vault hack
local function hackSideVault(panelIndex)
    if Config.basement.sideVaults.securityPanel.requiredItem then
        if not Framework.hasItem(Config.basement.sideVaults.securityPanel.requiredItem) then
            LR.notify(locale("missing_" .. Config.basement.sideVaults.securityPanel.requiredItem), "error")
            return
        end
    end

    if IsSpotOccupied(string.format("pacific:side_vault_%s", panelIndex)) then
        return
    end

    local animDict = "anim@heists@ornate_bank@hack"
    local panelCoords = Config.basement.sideVaults.securityPanel.locations[panelIndex]
    local panelObj = GetClosestObjectOfType(panelCoords.x, panelCoords.y, panelCoords.z, 2.0,
        Config.basement.sideVaults.securityPanel.model, false, false, false)
    local sceneCoords = GetEntityCoords(panelObj)
    panelCoords = sceneCoords

    lib.requestModel(-944468481)
    lib.requestModel(-411901183)
    lib.requestModel(-676527372)

    local suitBag = CreateSceneObject(-944468481, panelCoords)
    local keycard = CreateSceneObject(-411901183, panelCoords)
    local laptop = CreateSceneObject(-676527372, panelCoords)

    local rotation = GetEntityRotation(panelObj)

    -- Intro scene
    local introScene = NetworkCreateSynchronisedScene(panelCoords.x, panelCoords.y, panelCoords.z,
        rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, introScene, animDict, "hack_enter", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(suitBag, introScene, animDict, "hack_enter_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(keycard, introScene, animDict, "hack_enter_card", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, introScene, animDict, "hack_enter_laptop", 1.0, -1.0, 1148846080)

    -- Loop scene
    local loopScene = NetworkCreateSynchronisedScene(panelCoords.x, panelCoords.y, panelCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, true, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "hack_loop", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(suitBag, loopScene, animDict, "hack_loop_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(keycard, loopScene, animDict, "hack_loop_card", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, loopScene, animDict, "hack_loop_laptop", 1.0, -1.0, 1148846080)

    -- Exit scene
    local exitScene = NetworkCreateSynchronisedScene(panelCoords.x, panelCoords.y, panelCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "hack_exit", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(suitBag, exitScene, animDict, "hack_exit_suit_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(keycard, exitScene, animDict, "hack_exit_card", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(laptop, exitScene, animDict, "hack_exit_laptop", 1.0, -1.0, 1148846080)

    -- Start scenes
    NetworkStartSynchronisedScene(introScene)
    Wait((GetAnimDuration(animDict, "hack_enter") * 1000) - 200)

    NetworkStartSynchronisedScene(loopScene)

    local success = minigames.unlockSideVault()

    if success then
        TriggerServerEvent("lunar_contracts:pacific:openSideVault", panelIndex)
    end

    NetworkStartSynchronisedScene(exitScene)
    Wait((GetAnimDuration(animDict, "hack_exit") * 1000) - 500)

    -- Cleanup
    DeleteEntity(suitBag)
    DeleteEntity(keycard)
    DeleteEntity(laptop)
    SetModelAsNoLongerNeeded(-944468481)
    SetModelAsNoLongerNeeded(-411901183)
    SetModelAsNoLongerNeeded(-676527372)
    Wait(1000)
    FreeOccupiedSpot()
end

-- Main vault keycard use
local function useMainVaultKeycard()
    local hasKeycard = lib.callback.await("lunar_contracts:pacific:openMainVault", false, index)

    if not hasKeycard then
        LR.notify(locale("missing_" .. Config.basement.mainVault.securityPanel.keycard), "error")
        return
    end

    if IsSpotOccupied("pacific:main_vault") then
        return
    end

    local animDict = "anim@heists@humane_labs@finale@keycards"
    local panelCoords = Config.basement.mainVault.securityPanel.coords
    local panelObj = GetClosestObjectOfType(panelCoords.x, panelCoords.y, panelCoords.z, 2.0,
        Config.basement.mainVault.securityPanel.model, false, false, false)

    local offset = Config.basement.mainVault.securityPanel.offset
    local sceneCoords = GetOffsetFromEntityInWorldCoords(panelObj, offset.x, offset.y, offset.z)
    panelCoords = sceneCoords

    lib.requestModel(511938898)
    local keycardObj = CreateSceneObject(511938898, panelCoords)
    FreezeEntityPosition(keycardObj, true)

    local rotation = GetEntityRotation(panelObj)

    -- Intro scene
    local introScene = NetworkCreateSynchronisedScene(panelCoords.x, panelCoords.y, panelCoords.z,
        rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, introScene, animDict, "ped_a_intro_b", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(keycardObj, introScene, animDict, "ped_a_intro_b_keycard", 1.0, -1.0, 1148846080)

    -- Loop scene
    local loopScene = NetworkCreateSynchronisedScene(panelCoords.x, panelCoords.y, panelCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, true, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "ped_a_loop", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(keycardObj, loopScene, animDict, "ped_a_loop_keycard", 1.0, -1.0, 1148846080)

    -- Pass scene
    local passScene = NetworkCreateSynchronisedScene(panelCoords.x, panelCoords.y, panelCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, passScene, animDict, "ped_a_pass", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(keycardObj, passScene, animDict, "ped_a_pass_keycard", 1.0, -1.0, 1148846080)

    -- Start scenes
    NetworkStartSynchronisedScene(introScene)
    Wait((GetAnimDuration(animDict, "ped_a_enter") * 1000) + 500)

    NetworkStartSynchronisedScene(loopScene)
    Wait(1000)

    NetworkStartSynchronisedScene(passScene)
    Wait((GetAnimDuration(animDict, "ped_a_exit") * 1000) - 500)

    -- Cleanup
    DeleteEntity(keycardObj)
    SetModelAsNoLongerNeeded(511938898)
    Wait(1000)
    FreeOccupiedSpot()
end

-- Basement interaction points
local sideVaultPoints = {}
local mainVaultPoint = nil
local depositBoxPointsList = {}

-- Create basement interactions
RegisterNetEvent("lunar_contracts:pacific:createBasement", function()
    if not isContractActive then
        return
    end

    -- Side vault panels
    for i = 1, #Config.basement.sideVaults.securityPanel.locations do
        sideVaultPoints[i] = Utils.createInteractionPoint({
            coords = Config.basement.sideVaults.securityPanel.locations[i],
            radius = 1.0,
            options = {{
                label = locale("hack_panel"),
                icon = "code",
                onSelect = hackSideVault,
                args = i,
                canInteract = function() return not Busy end
            }}
        })
    end

    -- Main vault panel
    mainVaultPoint = Utils.createInteractionPoint({
        coords = Config.basement.mainVault.securityPanel.coords,
        radius = 1.0,
        options = {{
            label = locale("use_keycard"),
            icon = "credit-card",
            onSelect = useMainVaultKeycard,
            canInteract = function() return not Busy end
        }}
    })

    -- Deposit boxes
    for i = 1, #Config.basement.drilling.locations do
        local drillCoords = Config.basement.drilling.locations[i]

        depositBoxPointsList[i] = Utils.createInteractionPoint({
            coords = drillCoords,
            radius = 1.0,
            options = {{
                label = locale("drill_deposit_box"),
                icon = "sack-dollar",
                onSelect = function()
                    if Config.basement.drilling.requiredItem then
                        if not Framework.hasItem(Config.basement.drilling.requiredItem) then
                            LR.notify(locale("missing_" .. Config.basement.drilling.requiredItem), "error")
                            return
                        end
                    end

                    if IsSpotOccupied(string.format("pacific:drilling_%s", i)) then
                        return
                    end

                    local canDrill = lib.callback.await("lunar_contracts:pacific:canDrillDepositBox", false, i)
                    if not canDrill then
                        FreeOccupiedSpot()
                        return
                    end

                    local drillOffset = Utils.offsetCoords(drillCoords, 0.15, 0.0, -0.19)
                    local success = StartDrilling(drillOffset)

                    if success then
                        TriggerServerEvent("lunar_contracts:pacific:drillDepositBox", i)
                    end

                    FreeOccupiedSpot()
                end,
                canInteract = function() return not (Busy or vaultPanel) end
            }}
        })
    end
end)

-- Remove side vault panel
RegisterNetEvent("lunar_contracts:pacific:removeSideVaultPanel", function(panelIndex)
    if not isContractActive then
        return
    end

    if sideVaultPoints[panelIndex] then
        sideVaultPoints[panelIndex].remove()
        sideVaultPoints[panelIndex] = nil
    end
end)

-- Remove deposit box
RegisterNetEvent("lunar_contracts:pacific:removeDepositBox", function(boxIndex)
    if depositBoxPointsList[boxIndex] then
        depositBoxPointsList[boxIndex].remove()
        depositBoxPointsList[boxIndex] = nil
    end
end)

-- Angle normalization
local doorAnimationActive = false
local doorTargetHeading = false

local function getAngleDifference(angle1, angle2)
    local function normalize(angle)
        angle = angle % 360
        if angle < 0 then angle = angle + 360 end
        return angle
    end

    angle1 = normalize(angle1)
    angle2 = normalize(angle2)

    local diff = angle2 - angle1
    if diff > 180 then
        diff = diff - 360
    elseif diff < -180 then
        diff = diff + 360
    end

    return diff
end

-- Remove main vault panel
RegisterNetEvent("lunar_contracts:pacific:removeMainVaultPanel", function()
    SetTimeout(3000, function()
        doorAnimationActive = true
        doorTargetHeading = true

        local doorCoords = Config.basement.mainVault.door.coords
        local doorHeading = Config.basement.mainVault.door.heading
        local angleDiff = getAngleDifference(doorHeading.closed, doorHeading.open)

        local doorObj = GetClosestObjectOfType(doorCoords.x, doorCoords.y, doorCoords.z, 2.0,
            Config.basement.mainVault.door.model, false, false, false)

        for _ = 1, 2000 do
            local currentHeading = GetEntityHeading(doorObj)
            SetEntityHeading(doorObj, currentHeading + (angleDiff / 2000))
            Wait(10)
        end

        doorAnimationActive = false
    end)

    if not isContractActive then
        return
    end

    if mainVaultPoint then
        mainVaultPoint.remove()
        mainVaultPoint = nil
    end
end)

-- Vault door thread
CreateThread(function()
    while true do
        local doorCoords = Config.basement.mainVault.door.coords
        local distanceCheck = Utils.distanceCheck(cache.ped, doorCoords, 200.0)

        if not distanceCheck then
            Wait(1000)
            return
        end

        local doorHeading = Config.basement.mainVault.door.heading
        local doorObj = GetClosestObjectOfType(doorCoords.x, doorCoords.y, doorCoords.z, 2.0,
            Config.basement.mainVault.door.model, false, false, false)

        if not doorAnimationActive then
            FreezeEntityPosition(doorObj, true)
            SetEntityHeading(doorObj, doorTargetHeading and doorHeading.open or doorHeading.closed)
        end

        Wait(1000)
    end
end)

-- Reset contract
RegisterNetEvent("lunar_contracts:pacific:reset", function()
    if not isContractActive then
        return
    end

    isContractActive = false

    if mainVaultPanelPoint then
        mainVaultPanelPoint.remove()
    end

    if mainVaultPoint then
        mainVaultPoint.remove()
    end

    for i = 1, #sideVaultPoints do
        if sideVaultPoints[i] then
            sideVaultPoints[i].remove()
        end
    end
    table.wipe(sideVaultPoints)

    for i = 1, #keypadPoints do
        if keypadPoints[i] then
            keypadPoints[i].remove()
        end
    end
    table.wipe(keypadPoints)

    for _, point in pairs(computerPoints) do
        point.remove()
    end
    table.wipe(computerPoints)

    for _, point in pairs(depositBoxPointsList) do
        point.remove()
    end
    table.wipe(depositBoxPointsList)

    if blip then
        blip.remove()
        blip = nil
    end

    isContractActive = false
end)

-- Guard setup functions
local function setupGuard(ped)
    SetPedDropsWeaponsWhenDead(ped, false)
    SetPedCombatAbility(ped, Config.basement.guards.combatAbility)
    SetPedAccuracy(ped, Config.basement.guards.accuracy)
    SetPedRelationshipGroupHash(ped, 151644478)
    SetPedCombatMovement(ped, math.random(1, 2))
    SetPedCombatAttributes(ped, 5, true)
    SetPedCombatAttributes(ped, 68, false)
    SetPedCombatAttributes(ped, 28, true)
    SetPedCombatAttributes(ped, 21, true)
    SetPedCurrentWeaponVisible(ped, true)
end

local function guardLogic(ped)
    if not GetIsTaskActive(ped, 357) and not GetIsTaskActive(ped, 343) then
        if math.random(1, 8) == 1 then
            TaskGuardCurrentPosition(ped, 15.0, 10.0, true)
        end
    end

    local nearbyPlayers = lib.getNearbyPlayers(Config.basement.centre, 50.0, true)
    local closestPed = nil
    local closestDistance = math.huge

    for _, player in ipairs(nearbyPlayers) do
        local playerPed = player.ped
        local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(ped))

        if closestDistance > distance and not Editable.isDead(playerPed) then
            if Config.basement.guards.minPolice == 0 then
                local playerState = Player(GetPlayerServerId(player.id)).state
                if not playerState.isPolice then
                    closestDistance = distance
                    closestPed = playerPed
                end
            else
                closestDistance = distance
                closestPed = playerPed
            end
        end
    end

    if closestPed and not GetIsTaskActive(ped, 343) then
        TaskCombatPed(ped, closestPed, 0, 16)
    end
end

AddRelationshipGroup("PACIFIC_GUARD")

local guardPoints = {}
local lootedGuards = {}

-- Loot guard
local function lootGuard(guardId)
    if IsSpotOccupied(string.format("pacific:guard_%s", guardId)) then
        return
    end

    local success = LR.progressBar(locale("looting_guard"),
        Config.basement.guards.looting.progressDuration,
        false,
        { dict = "missbigscore2aig_7@driver", clip = "boot_r_loop", flag = 1 })

    if success then
        TriggerServerEvent("lunar_contracts:pacific:lootGuard", guardId)
    end

    FreeOccupiedSpot()
end

-- Guard looted event
RegisterNetEvent("lunar_contracts:pacific:guardLooted", function(guardId)
    lootedGuards[guardId] = true
    if guardPoints[guardId] then
        guardPoints[guardId].remove()
        guardPoints[guardId] = nil
    end
end)

-- Create guard loot point
local function createGuardLootPoint(guardId, ped)
    if guardPoints[guardId] then
        return
    end

    guardPoints[guardId] = Utils.createEntityPoint({
        entity = ped,
        radius = 1.5,
        options = {{
            label = locale("take_loot"),
            icon = "hand",
            onSelect = lootGuard,
            args = guardId,
            canInteract = function() return not Busy end
        }}
    })
end

-- Handle guards logic
local function handleGuardsLogic(guards)
    SetRelationshipBetweenGroups(0, 151644478, 151644478)
    SetRelationshipBetweenGroups(4, 151644478, 1862763509)
    SetRelationshipBetweenGroups(4, 1862763509, 151644478)

    for _, guardId in ipairs(guards) do
        if NetworkDoesEntityExistWithNetworkId(guardId) then
            local ped = NetworkGetEntityFromNetworkId(guardId)
            local owner = NetworkGetEntityOwner(ped)

            if owner == cache.playerId then
                setupGuard(ped)
                guardLogic(ped)
            end

            if IsEntityDead(ped) and not lootedGuards[guardId] then
                createGuardLootPoint(guardId, ped)
            end
        else
            if guardPoints[guardId] and Config.basement.guards.looting.enabled then
                guardPoints[guardId].remove()
                guardPoints[guardId] = nil
            end
        end
    end
end

local guardLogicPoint = nil

RegisterNetEvent("lunar_contracts:pacific:handleGuardsLogic", function(guards)
    guardLogicPoint = lib.points.new({
        coords = Config.basement.centre,
        distance = 420.0,
        nearby = function()
            handleGuardsLogic(guards)
            Wait(1000)
        end
    })
end)

-- Remove guards
RegisterNetEvent("lunar_contracts:pacific:removeGuards", function()
    if guardLogicPoint then
        guardLogicPoint.remove()
        guardLogicPoint = nil
    end

    for _, point in pairs(guardPoints) do
        point.remove()
        guardPoints[_] = nil
    end

    table.wipe(lootedGuards)
end)