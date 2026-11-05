local Config = Config.contracts.house
local minigames = Editable.minigames.house

-- State tables
local activeContracts = {}
local entryPoints = {}
local exitPoints = {}
local keypadPoints = {}
local lootedZones = {}
local alarmPoints = {}
local createdProps = {}
local homeownerState = {}
local alarmTriggered = {}
local laserZones = {}
local guardPoints = {}
local guardLogicPoints = {}
local guardLootPoints = {}
local lootedGuards = {}
local unlockedLocations = {}
local homeownerList = {}
local lootedHomeowners = {}
local pedDataList = {}
local homeownerData = {}

local currentLocation = nil
local animationCam = nil
local alertLevel = 0.0
local lastAlertLevel = 0.0
local alertTimer = nil
local isTransitioning = false
local isCarryingItem = false
local currentItemEntity = nil
local carryItemData = {
    active = false,
    playing = false,
    currentItem = nil,
    isAttaching = false
}
local carryItemList = {}

-- Laser control
local function setLasersState(locationIndex, state)
    local tier = Config.locations[locationIndex].tier
    if laserZones[tier] then
        for _, laser in ipairs(laserZones[tier]) do
            laser:setActive(state)
        end
    end
end

-- Alarm control
local function setAlarmState(locationIndex, enabled)
    if not Config.interiors[Config.locations[locationIndex].tier].alarm then
        return
    end

    if enabled then
        if not alarmPoints[locationIndex] then
            local soundId = GetSoundId()
            local alarmCoords = Config.interiors[Config.locations[locationIndex].tier].alarm.coords

            alarmPoints[locationIndex] = lib.points.new({
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

            SetTimeout(Config.interiors[Config.locations[locationIndex].tier].alarm.duration * 1000, function()
                if alarmPoints[locationIndex] then
                    alarmPoints[locationIndex]:onExit()
                    alarmPoints[locationIndex]:remove()
                    alarmPoints[locationIndex] = nil
                end
            end)
        end
    elseif not enabled and alarmPoints[locationIndex] then
        alarmPoints[locationIndex]:onExit()
        alarmPoints[locationIndex]:remove()
        alarmPoints[locationIndex] = nil
    end
end

-- Update homeowner state
local function updateHomeownerState(locationIndex, isAlerted)
    local tier = Config.locations[locationIndex].tier
    setLasersState(locationIndex, isAlerted)
end

-- Update alarm state
local function updateAlarmState(locationIndex, triggered)
    homeownerState[locationIndex] = triggered
    setAlarmState(locationIndex, triggered)
end

-- Reset location state
local function resetLocationState(locationIndex)
    setLasersState(locationIndex, false)
    setAlarmState(locationIndex, false)
end

-- Relationship group
local HOMEOWNER_GROUP = "HOUSE_HOMEOWNER"
AddRelationshipGroup(HOMEOWNER_GROUP)

-- Setup homeowner ped
local function setupHomeowner(ped, pedData, pedConfig)
    SetEntityInvincible(ped, false)
    SetPedDropsWeaponsWhenDead(ped, false)
    SetPedRelationshipGroupHash(ped, GetHashKey(HOMEOWNER_GROUP))

    local combatAbility = pedConfig.combatAbility or 30

    if pedData.weapon then
        GiveWeaponToPed(ped, GetHashKey(pedData.weapon), 100, true, true)
        SetPedCombatAttributes(ped, 46, true)
        SetPedCombatAbility(ped, combatAbility)
        SetPedCombatMovement(ped, 2)
        SetPedCombatRange(ped, 1)
        SetPedAlertness(ped, 3)
    else
        SetPedFleeAttributes(ped, 0, false)
    end

    SetPedKeepTask(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    if pedData.anim then
        lib.requestAnimDict(pedData.anim.dict)
        TaskPlayAnim(ped, pedData.anim.dict, pedData.anim.clip, 8.0, -8.0, -1, 1, 0, false, false, false)

        CreateThread(function()
            while true do
                if not DoesEntityExist(ped) or IsEntityDead(ped) then
                    break
                end

                if not IsEntityPlayingAnim(ped, pedData.anim.dict, pedData.anim.clip, 3) then
                    local homeowner = nil
                    for _, owner in pairs(homeownerList[locationIndex] or {}) do
                        if owner.ped == ped then
                            homeowner = owner
                            break
                        end
                    end

                    if homeowner and not homeowner.detected then
                        TaskPlayAnim(ped, pedData.anim.dict, pedData.anim.clip, 8.0, -8.0, -1, 1, 0, false, false, false)
                    else
                        break
                    end
                end

                Wait(2000)
            end
        end)
    end
end

-- Homeowner detection
local function onHomeownerDetected(locationIndex, ped, pedData, homeownerIndex)
    if homeownerList[locationIndex] and homeownerList[locationIndex][homeownerIndex] then
        homeownerList[locationIndex][homeownerIndex].detected = true
    end

    SetBlockingOfNonTemporaryEvents(ped, false)
    ClearPedTasks(ped)

    if pedData.weapon then
        SetRelationshipBetweenGroups(5, GetHashKey(HOMEOWNER_GROUP), 1862763509)
        SetRelationshipBetweenGroups(5, 1862763509, GetHashKey(HOMEOWNER_GROUP))
        TaskCombatPed(ped, cache.ped, 0, 16)
    else
        TaskSmartFleePed(ped, cache.ped, 100.0, -1, false, false)
    end

    if not alarmTriggered[locationIndex] then
        alarmTriggered[locationIndex] = true
        TriggerServerEvent("lunar_contracts:house:alarm", locationIndex)
        LR.notify(locale("homeowner_detected"), "error")
    end
end

-- Homeowner detection thread
local function startHomeownerDetection(locationIndex, ped, pedData, homeownerIndex)
    local detectionRadius = pedData.detectionRadius or 2.0

    CreateThread(function()
        while currentLocation == locationIndex and DoesEntityExist(ped) and not IsEntityDead(ped) do
            Wait(200)

            local currentHomeowner = homeownerList[locationIndex] and homeownerList[locationIndex][homeownerIndex]
            if currentHomeowner and currentHomeowner.detected then
                break
            end

            local playerCoords = GetEntityCoords(cache.ped)
            local pedCoords = GetEntityCoords(ped)
            local distance = #(playerCoords - pedCoords)
            local isStealth = GetPedStealthMovement(cache.ped)
            local stealthMultiplier = isStealth and 0.5 or 1.0
            local detectionDistance = detectionRadius * stealthMultiplier

            if distance < detectionDistance then
                onHomeownerDetected(locationIndex, ped, pedData, homeownerIndex)
                break
            end

            if distance < detectionDistance * 2 then
                local isRunning = GetEntitySpeed(cache.ped) > 3.0
                local isShooting = IsPedShooting(cache.ped)

                if (isRunning and not isStealth) or isShooting then
                    onHomeownerDetected(locationIndex, ped, pedData, homeownerIndex)
                    break
                end
            end
        end
    end)
end

-- Create loot point for dead homeowner
local function createHomeownerLootPoint(locationIndex, homeownerIndex, ped, pedData, contractIndex, pedConfig)
    if not guardLootPoints[locationIndex] then
        guardLootPoints[locationIndex] = {}
    end

    if guardLootPoints[locationIndex][homeownerIndex] then
        if guardLootPoints[locationIndex][homeownerIndex].remove then
            guardLootPoints[locationIndex][homeownerIndex].remove()
        end
        guardLootPoints[locationIndex][homeownerIndex] = nil
    end

    local lootingConfig = pedConfig.looting or {}
    local progressDuration = lootingConfig.progressDuration or 3000

    guardLootPoints[locationIndex][homeownerIndex] = Utils.createInteractionPoint({
        coords = GetEntityCoords(ped),
        radius = 1.5,
        options = {{
            label = locale("loot_homeowner"),
            icon = "hand",
            onSelect = function()
                local success = LR.progressBar(locale("looting_homeowner"), progressDuration, false, {
                    dict = "missbigscore2aig_7@driver",
                    clip = "boot_r_loop",
                    flag = 1
                })

                if success then
                    TriggerServerEvent("lunar_contracts:house:lootHomeowner", contractIndex, homeownerIndex)
                end
            end,
            canInteract = function()
                if not DoesEntityExist(ped) or not IsEntityDead(ped) then
                    return false
                end

                if homeownerList[locationIndex] and homeownerList[locationIndex][homeownerIndex] then
                    if homeownerList[locationIndex][homeownerIndex].looted then
                        return false
                    end
                end

                return not Busy and Utils.distanceCheck(cache.ped, ped, 1.5)
            end
        }}
    })
end

-- Monitor homeowner death
local function monitorHomeownerDeath(locationIndex, homeownerIndex, ped, pedData, contractIndex, pedConfig)
    CreateThread(function()
        while currentLocation == locationIndex and DoesEntityExist(ped) do
            Wait(500)

            if IsEntityDead(ped) then
                createHomeownerLootPoint(locationIndex, homeownerIndex, ped, pedData, contractIndex, pedConfig)
                break
            end
        end
    end)
end

-- Handle homeowner logic
local function handleHomeownerLogic(locationIndex, contractIndex)
    if homeownerList[locationIndex] then
        checkHomeownerLoot(locationIndex, contractIndex)
        return
    end

    local tier = Config.locations[locationIndex].tier
    local interior = Config.interiors[tier]
    local pedConfig = interior.homeownerPeds

    if not pedConfig or not pedConfig.enabled then
        return
    end

    homeownerList[locationIndex] = {}
    alarmTriggered[locationIndex] = false

    for idx, pedData in ipairs(pedDataList) do
        local netId = pedData.netId
        local ped = nil

        for i = 0, 50 do
            if NetworkDoesEntityExistWithNetworkId(netId) then
                ped = NetworkGetEntityFromNetworkId(netId)
                if DoesEntityExist(ped) then
                    break
                end
            end
            Wait(100)
        end

        if ped and DoesEntityExist(ped) then
            local data = {
                model = pedData.model,
                coords = pedData.coords,
                anim = pedData.anim,
                weapon = pedData.weapon,
                items = pedData.items,
                detectionRadius = pedData.detectionRadius
            }

            homeownerList[locationIndex][idx] = {
                ped = ped,
                netId = netId,
                detected = false,
                looted = false,
                data = data
            }

            setupHomeowner(ped, data, pedConfig)
            startHomeownerDetection(locationIndex, ped, data, idx)
            monitorHomeownerDeath(locationIndex, idx, ped, data, contractIndex, pedConfig)
        end
    end
end

-- Cleanup homeowners
local function cleanupHomeowners(locationIndex)
    homeownerList[locationIndex] = nil
    lootedHomeowners[locationIndex] = nil

    if guardLootPoints[locationIndex] then
        for _, point in pairs(guardLootPoints[locationIndex]) do
            if point and point.remove then
                point.remove()
            end
        end
        guardLootPoints[locationIndex] = nil
    end

    alarmTriggered[locationIndex] = nil
end

-- Check for lootable homeowners
local function checkHomeownerLoot(locationIndex, contractIndex)
    if not homeownerList[locationIndex] then
        return
    end

    local interior = Config.interiors[Config.locations[locationIndex].tier]
    local pedConfig = interior.homeownerPeds

    for idx, homeowner in pairs(homeownerList[locationIndex]) do
        local netId = homeowner.netId
        if netId and NetworkDoesEntityExistWithNetworkId(netId) then
            local ped = NetworkGetEntityFromNetworkId(netId)
            if DoesEntityExist(ped) then
                homeowner.ped = ped
            end
        end

        if DoesEntityExist(homeowner.ped) then
            if IsEntityDead(homeowner.ped) then
                if not homeowner.looted then
                    createHomeownerLootPoint(locationIndex, idx, homeowner.ped, homeowner.data, contractIndex, pedConfig)
                end
            elseif homeowner.detected then
                SetBlockingOfNonTemporaryEvents(homeowner.ped, false)
                ClearPedTasks(homeowner.ped)

                if homeowner.data.weapon then
                    SetRelationshipBetweenGroups(5, GetHashKey(HOMEOWNER_GROUP), 1862763509)
                    SetRelationshipBetweenGroups(5, 1862763509, GetHashKey(HOMEOWNER_GROUP))
                    TaskCombatPed(homeowner.ped, cache.ped, 0, 16)
                else
                    TaskSmartFleePed(homeowner.ped, cache.ped, 100.0, -1, false, false)
                end

                monitorHomeownerDeath(locationIndex, idx, homeowner.ped, homeowner.data, contractIndex, pedConfig)
            else
                startHomeownerDetection(locationIndex, homeowner.ped, homeowner.data, idx)
                monitorHomeownerDeath(locationIndex, idx, homeowner.ped, homeowner.data, contractIndex, pedConfig)
            end
        end
    end
end

-- Setup camera
local function setupCamera(direction, zoom, targetZ)
    local offset = GetOffsetFromEntityInWorldCoords(cache.ped, (direction or 2.0) * (zoom and -1 or 1), -0.25, 0.5)
    animationCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", offset.x, offset.y, offset.z, 0.0, 0.0, 0.0, 50.0, true, 2)

    local lookAt = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, -0.1, 0.5)
    PointCamAtCoord(animationCam, lookAt.x, lookAt.y, targetZ + 1.5)

    RenderScriptCams(true, false, 1, false)
end

-- Cleanup camera
local function cleanupCamera()
    if animationCam then
        RenderScriptCams(false, false, 1, false)
        DestroyCam(animationCam, true)
        animationCam = nil
    end
end

-- Camera animation
local function startCameraTransition(fromCoords, toCoords, zoom, shouldSwap)
    if isTransitioning then
        return
    end

    isTransitioning = true

    if currentItemEntity then
        DeleteEntity(currentItemEntity)
        currentItemEntity = nil
    end

    lib.requestAnimDict("anim@apt_trans@hinge_l")

    CreateThread(function()
        SetEntityCoords(cache.ped, fromCoords.x, fromCoords.y, fromCoords.z - 1.0)
        SetEntityHeading(cache.ped, fromCoords.w + 180.0)

        local offsetCoords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, -1.75, 0.0)
        local groundZ = GetGroundZFor_3dCoord(offsetCoords.x, offsetCoords.y, offsetCoords.z, false)

        local zoomValue = zoom or 1.0
        local camDistance = shouldSwap and -1 or 1

        setupCamera(camDistance, zoomValue, groundZ)

        SetEntityCoords(cache.ped, offsetCoords.x, offsetCoords.y, groundZ)
        TaskPlayAnim(cache.ped, "anim@apt_trans@hinge_l", "ext_player", 8.0, 8.0, 2000, 1, 1.0, false, false, false)

        RequestCollisionAtCoord(toCoords.x, toCoords.y, toCoords.z)
    end)

    Wait(700)

    -- Update police state
    local playerState = Player(cache.serverId).state
    playerState:set("isPolice", Utils.isPolice(), true)

    DoScreenFadeOut(750)
    Wait(1000)

    cleanupCamera()
    SetArtificialLightsState(false)
    SetEntityVisible(cache.ped, false, false)
    SetEntityCoords(cache.ped, toCoords.x, toCoords.y, toCoords.z + 0.0)
    SetEntityHeading(cache.ped, toCoords.w)
    SetGameplayCamRelativeHeading(0.0)
    PlaceObjectOnGroundProperly(cache.ped)

    Wait(1000)

    DoScreenFadeIn(500)
    SetEntityVisible(cache.ped, true, false)

    isTransitioning = false
end

-- Lockpick house
local function lockpickHouse(contractIndex)
    local contract = activeContracts[contractIndex]
    if not contract then
        return
    end

    local locationIndex = contract.locationIndex
    local location = Config.locations[locationIndex]

    if Config.lockpickItem.name then
        if not Framework.hasItem(Config.lockpickItem.name) then
            LR.notify(locale("missing_" .. Config.lockpickItem.name), "error")
            return
        end
    end

    if IsSpotOccupied(string.format("house:lockpick_%s", locationIndex)) then
        return
    end

    lib.requestAnimDict("missheistfbisetup1")
    Utils.makeEntityFaceCoords(cache.ped, location.entrance)
    TaskPlayAnim(cache.ped, "missheistfbisetup1", "hassle_intro_loop_f", 8.0, 8.0, -1, 1, 0, false, false, false)

    local success = minigames.lockpick()

    if success then
        TriggerServerEvent("lunar_contracts:house:lockpicked", contractIndex)
    end

    ClearPedTasks(cache.ped)
    FreeOccupiedSpot()
end

-- Hack keypad
local function hackKeypad(contractIndex)
    local contract = activeContracts[contractIndex]
    if not contract then
        return
    end

    local locationIndex = contract.locationIndex
    local location = Config.locations[locationIndex]

    if Config.hackingItem.name then
        if not Framework.hasItem(Config.hackingItem.name) then
            LR.notify(locale("missing_" .. Config.hackingItem.name), "error")
            return
        end
    end

    if IsSpotOccupied(string.format("house:keypad_%s", locationIndex)) then
        return
    end

    Utils.makeEntityFaceCoords(cache.ped, location.keypad)

    local animDict = "anim@heists@ornate_bank@hack"
    lib.requestAnimDict(animDict)

    local sceneCoords = Utils.offsetCoords(location.keypad, 0.08, 0.05, -0.01)

    local bag = CreateSceneObject(-944468481, sceneCoords)
    local laptop = CreateSceneObject(-676527372, sceneCoords)
    local keycard = CreateSceneObject(-411901183, sceneCoords)

    local rotation = vector3(0.0, 0.0, location.keypad.w)

    -- Enter scene
    local enterScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1.0)

    NetworkAddPedToSynchronisedScene(cache.ped, enterScene, animDict, "hack_enter", -4.0, -4.0, 1037, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(bag, enterScene, animDict, "hack_enter_bag", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(laptop, enterScene, animDict, "hack_enter_laptop", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(keycard, enterScene, animDict, "hack_enter_card", 4.0, -8.0, 1)

    NetworkStartSynchronisedScene(enterScene)
    Wait((GetAnimDuration(animDict, "hack_enter") * 1000) - 200)

    -- Loop scene
    local loopScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, true, 1065353216, 0, 1.0)

    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "hack_loop", -4.0, -4.0, 1037, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(bag, loopScene, animDict, "hack_loop_bag", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(laptop, loopScene, animDict, "hack_loop_laptop", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(keycard, loopScene, animDict, "hack_loop_card", 4.0, -8.0, 1)

    NetworkStartSynchronisedScene(loopScene)

    local success = minigames.keypad()

    -- Exit scene
    local exitScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1.0)

    NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "hack_exit", -4.0, -4.0, 1037, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(bag, exitScene, animDict, "hack_exit_bag", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(laptop, exitScene, animDict, "hack_exit_laptop", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(keycard, exitScene, animDict, "hack_exit_card", 4.0, -8.0, 1)

    if success then
        TriggerServerEvent("lunar_contracts:house:hackedKeypad", contractIndex)
        LR.notify(locale("hacked_keypad"), "success")
    else
        LR.notify(locale("hack_failed"), "error")
    end

    NetworkStartSynchronisedScene(exitScene)
    Wait((GetAnimDuration(animDict, "hack_exit") * 1000) - 500)

    DeleteEntity(bag)
    DeleteEntity(laptop)
    DeleteEntity(keycard)

    SetModelAsNoLongerNeeded(-944468481)
    SetModelAsNoLongerNeeded(-676527372)
    SetModelAsNoLongerNeeded(-411901183)

    FreeOccupiedSpot()
end

-- Steal painting
local function stealPainting(data)
    local contractIndex = data.contractIndex
    local paintingIndex = data.index
    local contract = activeContracts[contractIndex]

    if not contract then
        return
    end

    local locationIndex = contract.locationIndex
    local animDict = "anim_heist@hs3f@ig11_steal_painting@male@"

    if IsSpotOccupied(string.format("house:painting_%s", paintingIndex)) then
        return
    end

    lib.requestModel(-944468481)
    lib.requestModel(-963831200)

    local offsetCoords = Utils.offsetCoords(
        Config.interiors[contract.tier].paintings.locations[paintingIndex],
        0.0, 0.0, -0.5
    ).xyz

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

    TriggerServerEvent("lunar_contracts:house:stealPainting", contractIndex, paintingIndex)

    DeleteEntity(bag)
    DeleteEntity(knife)
    SetModelAsNoLongerNeeded(-944468481)
    SetModelAsNoLongerNeeded(-963831200)
    FreeOccupiedSpot()
end

-- Break display case
local function breakDisplayCase(contractIndex)
    local contract = activeContracts[contractIndex]
    if not contract then
        return
    end

    local locationIndex = contract.locationIndex
    local interior = Config.interiors[contract.tier]

    if interior.displayCase.requiredItem then
        if not Framework.hasItem(interior.displayCase.requiredItem) then
            LR.notify(locale("missing_" .. interior.displayCase.requiredItem), "error")
            return
        end
    end

    local animDict = "anim@scripted@heist@ig16_glass_cut@male@"

    if IsSpotOccupied(string.format("house:display_case_%s", locationIndex)) then
        return
    end

    lib.requestModel(-944468481)
    lib.requestModel(-270699417)
    lib.requestModel(768636065)
    lib.requestModel(-89363854)
    lib.requestNamedPtfxAsset("scr_ih_fin")

    local caseCoords = interior.displayCase.coords
    local caseObj = GetClosestObjectOfType(caseCoords.x, caseCoords.y, caseCoords.z, 1.0, interior.displayCase.model, false)

    if not caseObj then
        SetModelAsNoLongerNeeded(-944468481)
        SetModelAsNoLongerNeeded(-270699417)
        SetModelAsNoLongerNeeded(768636065)
        SetModelAsNoLongerNeeded(-89363854)
        FreeOccupiedSpot()
        error("Can't locate the display case object.")
        return
    end

    local objCoords = GetEntityCoords(caseObj)
    local rotation = GetEntityRotation(caseObj)

    local bag = CreateSceneObject(-944468481, objCoords)
    local cutter = CreateSceneObject(-270699417, objCoords)
    local glassPiece = CreateSceneObject(-89363854, objCoords)

    -- Enter scene
    local enterScene = NetworkCreateSynchronisedScene(objCoords.x, objCoords.y, objCoords.z,
        rotation.x, rotation.y, rotation.z, 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, enterScene, animDict, "enter", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bag, enterScene, animDict, "enter_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(cutter, enterScene, animDict, "enter_cutter", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(caseObj, enterScene, animDict, "enter_glass_display", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(enterScene)
    Wait((GetAnimDuration(animDict, "enter") * 1000) - 100)

    -- Cutting loop scene
    local loopScene = NetworkCreateSynchronisedScene(objCoords.x, objCoords.y, objCoords.z,
        rotation.x, rotation.y, rotation.z, 2, false, true, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(cache.ped, loopScene, animDict, "cutting_loop", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bag, loopScene, animDict, "cutting_loop_bag", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(cutter, loopScene, animDict, "cutting_loop_cutter", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(caseObj, loopScene, animDict, "cutting_loop_glass_display", 1.0, -1.0, 1148846080)

    NetworkStartSynchronisedScene(loopScene)

    UseParticleFxAssetNextCall("scr_ih_fin")
    local particleFx = StartParticleFxLoopedOnEntity("scr_ih_fin_glass_cutter_cut", cutter, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false)

    Wait(1000)

    local success = minigames.displayCase()

    StopParticleFxLooped(particleFx, false)

    if success then
        -- Mark display case as broken
        Entity(caseObj).state["house:isDisplayCaseBroken"] = true

        -- Find and hide the loot item
        local lootItem = nil
        for _, item in ipairs(interior.displayCase.items) do
            local obj = GetClosestObjectOfType(objCoords.x, objCoords.y, objCoords.z, 1.0, item.model, false)
            if obj and obj ~= 0 then
                lootItem = obj
                break
            end
        end

        SetTimeout(2200, function()
            SetEntityVisible(lootItem, false, false)
            NetworkSetEntityInvisibleToNetwork(lootItem, true)
            TriggerServerEvent("lunar_contracts:house:stealDisplayCase", contractIndex)
        end)

        -- Success exit scene
        local exitScene = NetworkCreateSynchronisedScene(objCoords.x, objCoords.y, objCoords.z,
            rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)

        NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "success", -4.0, -4.0, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(bag, exitScene, animDict, "success_bag", 1.0, -1.0, 1148846080)
        NetworkAddEntityToSynchronisedScene(cutter, exitScene, animDict, "success_cutter", 1.0, -1.0, 1148846080)
        NetworkAddEntityToSynchronisedScene(caseObj, exitScene, animDict, "success_glass_display_cut", 1.0, -1.0, 1148846080)
        NetworkAddEntityToSynchronisedScene(glassPiece, exitScene, animDict, "success_glass_piece", 1.0, -1.0, 1148846080)

        NetworkStartSynchronisedScene(exitScene)
        Wait((GetAnimDuration(animDict, "success") * 1000) - 500)

        LR.notify(locale("display_case_stolen"), "success")
    else
        -- Failure reaction scene
        local exitScene = NetworkCreateSynchronisedScene(objCoords.x, objCoords.y, objCoords.z,
            rotation.x, rotation.y, rotation.z, 2, false, false, 1065353216, 0, 1065353216)

        NetworkAddPedToSynchronisedScene(cache.ped, exitScene, animDict, "overheat_react_02", -4.0, -4.0, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(bag, exitScene, animDict, "overheat_react_02_bag", 1.0, -1.0, 1148846080)
        NetworkAddEntityToSynchronisedScene(cutter, exitScene, animDict, "overheat_react_02_cutter", 1.0, -1.0, 1148846080)
        NetworkAddEntityToSynchronisedScene(caseObj, exitScene, animDict, "overheat_react_02_glass_display", 1.0, -1.0, 1148846080)

        NetworkStartSynchronisedScene(exitScene)
        Wait(GetAnimDuration(animDict, "overheat_react_02") * 1000)

        LR.notify(locale("display_case_failed"), "error")
    end

    DeleteEntity(bag)
    DeleteEntity(cutter)
    DeleteEntity(glassPiece)

    SetModelAsNoLongerNeeded(-944468481)
    SetModelAsNoLongerNeeded(-270699417)
    SetModelAsNoLongerNeeded(768636065)
    SetModelAsNoLongerNeeded(-89363854)

    FreeOccupiedSpot()
end

-- Take loot
local function takeLoot(data)
    local contractIndex = data.contractIndex
    local lootIndex = data.index
    local contract = activeContracts[contractIndex]

    if not contract then
        return
    end

    local locationIndex = contract.locationIndex
    local interior = Config.interiors[contract.tier]
    local lootConfig = interior.takeLoot[lootIndex]

    if IsSpotOccupied(string.format("house:loot_%s_%s", locationIndex, lootIndex)) then
        return
    end

    local animConfig = nil
    local isHeavyItem = false

    if Config.carryItems and Config.carryItems.enabled then
        for _, heavyItem in ipairs(Config.carryItems.list) do
            if heavyItem.name == lootConfig.items[1].name then
                isHeavyItem = true
                break
            end
        end
    end

    local hasRemoveProp = lootConfig.removeProp or lootConfig.createProp

    if hasRemoveProp then
        if not isHeavyItem then
            animConfig = { dict = "anim@scripted@heist@ig1_table_grab@gold@male@", clip = "grab" }
        end
    else
        animConfig = { scenario = "PROP_HUMAN_BUM_BIN" }
    end

    Utils.makeEntityFaceCoords(cache.ped, lootConfig.coords)

    local progressDuration = hasRemoveProp and (isHeavyItem and 800 or 4000) or 3000

    local success = LR.progressBar(lootConfig.label, progressDuration, true, animConfig)

    if success then
        TriggerServerEvent("lunar_contracts:house:takeLoot", contractIndex, lootIndex)
    end

    FreeOccupiedSpot()
end

-- Display case broken handler
Utils.entityStateHandler("house:isDisplayCaseBroken", function(entity, _)
    local coords = GetEntityCoords(entity)
    CreateModelSwap(coords.x, coords.y, coords.z, 10.0, -1714533217, 768636065)
end)

-- Update UI bars
local function updateBars(alertLevel, noiseLevel)
    alertLevel = math.min(alertLevel, 1.0)
    noiseLevel = math.min(noiseLevel, 1.0)

    LR.showBars({
        {
            label = locale("alert_level"),
            icon = "triangle-exclamation",
            percentage = alertLevel * 100,
            color = "#FFD700"
        },
        {
            label = locale("noise_level"),
            icon = "volume-up",
            percentage = noiseLevel * 100,
            color = "#1E90FF"
        }
    })
end

-- Create entry point for house
local function createEntryPoint(locationIndex, contractIndex)
    local location = Config.locations[locationIndex]

    if entryPoints[locationIndex] then
        entryPoints[locationIndex].remove()
        entryPoints[locationIndex] = nil
    end

    if keypadPoints[locationIndex] then
        keypadPoints[locationIndex].remove()
        keypadPoints[locationIndex] = nil
    end

    entryPoints[locationIndex] = Utils.createInteractionPoint({
        coords = location.entrance,
        radius = 1.5,
        options = {
            {
                label = locale("lockpick"),
                icon = "lock",
                onSelect = lockpickHouse,
                args = contractIndex,
                canInteract = function() return not location.keypad end
            },
            {
                label = locale("enter_house"),
                icon = "door-open",
                onSelect = function()
                    local interior = Config.interiors[location.tier]

                    RefreshInterior(interior.interiorId)

                    startCameraTransition(
                        location.coords,
                        interior.coords,
                        location.swapCamera,
                        contractIndex
                    )

                    currentLocation = locationIndex

                    TriggerServerEvent("lunar_contracts:house:entered", contractIndex)

                    if activeContracts[contractIndex] and activeContracts[contractIndex].lootIndex then
                        TriggerEvent("lunar_contracts:loot:syncUnlocked",
                            activeContracts[contractIndex].lootIndex,
                            string.format("house_%s", locationIndex),
                            true
                        )
                    end

                    -- Hide remove props
                    if interior.removeProps then
                        for _, prop in pairs(interior.removeProps) do
                            CreateModelHide(prop.coords.x, prop.coords.y, prop.coords.z, 10.0, prop.model, true)
                        end
                    end

                    -- Create interior props
                    if interior.props then
                        if not createdProps[contractIndex] then
                            createdProps[contractIndex] = {}
                        end
                        for idx, prop in pairs(interior.props) do
                            createdProps[contractIndex][idx] = Utils.createProp(prop.coords, { model = prop.model })
                        end
                    end

                    -- Create take loot points
                    CreateThread(function()
                        while IsScreenFadingIn() do
                            Wait(0)
                        end
                        Wait(200)

                        if interior.takeLoot then
                            for idx, loot in ipairs(interior.takeLoot) do
                                local isLooted = lootedZones[contractIndex] and lootedZones[contractIndex][idx]

                                if loot.createProp and not isLooted and activeContracts[contractIndex] then
                                    activeContracts[contractIndex].createdProps[idx] = Utils.createProp(loot.coords, { model = loot.createProp })
                                end

                                if loot.removeProp and isLooted then
                                    local obj = GetClosestObjectOfType(loot.coords.x, loot.coords.y, loot.coords.z, 0.25, loot.removeProp, false)
                                    if obj ~= 0 then
                                        SetEntityAsMissionEntity(obj)
                                        DeleteEntity(obj)
                                    end
                                end

                                -- Create interaction point for lootable item
                                if not isLooted and activeContracts[contractIndex] then
                                    local lootPoint = Utils.createInteractionPoint({
                                        coords = loot.coords,
                                        radius = 1.5,
                                        options = {{
                                            label = loot.label,
                                            icon = loot.icon or "magnifying-glass",
                                            onSelect = takeLoot,
                                            args = { contractIndex = contractIndex, index = idx },
                                            canInteract = function()
                                                if not activeContracts[contractIndex] then return false end
                                                if lootedZones[contractIndex] and lootedZones[contractIndex][idx] then return false end
                                                return not Busy
                                            end
                                        }}
                                    })
                                    if not activeContracts[contractIndex].lootZones then
                                        activeContracts[contractIndex].lootZones = {}
                                    end
                                    activeContracts[contractIndex].lootZones[idx] = lootPoint
                                end
                            end
                        end
                    end)

                    -- Handle homeowner peds
                    if interior.homeownerPeds and interior.homeownerPeds.enabled then
                        if homeownerData[locationIndex] then
                            handleHomeownerLogic(locationIndex, homeownerData[locationIndex].tier, homeownerData[locationIndex].data, homeownerData[locationIndex].contractIndex)
                        else
                            checkHomeownerLoot(locationIndex, contractIndex)
                        end
                    end

                    -- Set laser state
                    if homeownerState[locationIndex] == nil then
                        homeownerState[locationIndex] = true
                    end
                    setLasersState(locationIndex, homeownerState[locationIndex])

                    -- Create exit point
                    if exitPoints[locationIndex] then
                        exitPoints[locationIndex].remove()
                        exitPoints[locationIndex] = nil
                    end

                    exitPoints[locationIndex] = Utils.createInteractionPoint({
                        coords = interior.exit,
                        radius = 2.0,
                        options = {{
                            label = locale("exit_house"),
                            icon = "door-open",
                            onSelect = function()
                                startCameraTransition(interior.coords, location.coords, location.tier == "low" and 0.8 or location.tier == "medium" and 1.1, nil)

                                TriggerServerEvent("lunar_contracts:house:exited", contractIndex)
                                currentLocation = nil

                                if activeContracts[contractIndex] and activeContracts[contractIndex].lootIndex then
                                    TriggerEvent("lunar_contracts:loot:syncUnlocked",
                                        activeContracts[contractIndex].lootIndex,
                                        string.format("house_%s", locationIndex),
                                        true
                                    )
                                end

                                -- Restore removed props
                                if interior.removeProps then
                                    for _, prop in ipairs(interior.removeProps) do
                                        RemoveModelHide(prop.coords.x, prop.coords.y, prop.coords.z, 10.0, prop.model, true)
                                    end
                                end

                                -- Cleanup interior props
                                if createdProps[contractIndex] then
                                    for _, prop in pairs(createdProps[contractIndex]) do
                                        if prop and prop.remove then
                                            prop.remove()
                                        end
                                    end
                                    createdProps[contractIndex] = nil
                                end

                                -- Cleanup loot zones
                                if activeContracts[contractIndex] then
                                    for _, zone in pairs(activeContracts[contractIndex].lootZones or {}) do
                                        if zone and zone.remove then
                                            zone.remove()
                                        end
                                    end
                                    activeContracts[contractIndex].lootZones = {}
                                end

                                resetLocationState(locationIndex)

                                if exitPoints[locationIndex] then
                                    exitPoints[locationIndex].remove()
                                    exitPoints[locationIndex] = nil
                                end

                                if alertTimer then
                                    ClearInterval(alertTimer)
                                    alertTimer = nil
                                end

                                if exitPoints[locationIndex] then
                                    exitPoints[locationIndex].remove()
                                    exitPoints[locationIndex] = nil
                                end

                                SetTimeout(2000, function()
                                    LR.hideBars()
                                end)
                            end,
                            canInteract = function()
                                return unlockedLocations[locationIndex] and currentLocation == locationIndex and not Busy and not animationCam
                            end
                        }}
                    })
                end,
                args = locationIndex,
                canInteract = function()
                    return unlockedLocations[locationIndex] and not Busy and not animationCam
                end
            }
        }
    })
end

-- Update alert level
RegisterNetEvent("lunar_contracts:house:updateAlertLevel", function(locationIndex, level)
    if not activeContracts or currentLocation ~= locationIndex then
        return
    end

    alertLevel = level
end)

-- Sync location state
RegisterNetEvent("lunar_contracts:house:syncLocationState", function(locationIndex, isAlerted, alarmState)
    homeownerState[locationIndex] = isAlerted
    alarmTriggered[locationIndex] = alarmState

    if currentLocation == locationIndex then
        updateHomeownerState(locationIndex, isAlerted)
        updateAlarmState(locationIndex, alarmState)
    end
end)

-- Trigger alarm
RegisterNetEvent("lunar_contracts:house:alarm", function(locationIndex)
    homeownerState[locationIndex] = false
    alarmTriggered[locationIndex] = true

    updateHomeownerState(locationIndex, false)
    updateAlarmState(locationIndex, true)

    if currentLocation == locationIndex then
        if alertTimer then
            ClearInterval(alertTimer)
            alertTimer = nil
        end

        SetTimeout(2000, function()
            LR.hideBars()
        end)
    end
end)

-- Sync room ID for NPCs
local roomSyncActive = {}

RegisterNetEvent("lunar_contracts:house:syncRoomId", function(locationIndex, pedIds)
    roomSyncActive[locationIndex] = true

    for _, pedId in ipairs(pedIds) do
        CreateThread(function()
            while roomSyncActive[locationIndex] do
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

-- Set painting as looted
local function setPaintingLooted(contractIndex, paintingIndex)
    local contract = activeContracts[contractIndex]
    if not contract or contract.contractIndex ~= contractIndex then
        return
    end

    local offsetCoords = Utils.offsetCoords(
        Config.interiors[contract.tier].paintings.locations[paintingIndex],
        0.0, 0.0, -0.5
    )

    local pointAdded = false

    local function onEnter()
        if currentLocation ~= contract.locationIndex then
            return
        end

        local paintingObj = lib.getClosestObject(offsetCoords.xyz, 1.0)
        if not paintingObj or pointAdded[paintingObj] then
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

        pointAdded[paintingObj] = true

        Wait(200)
    end

    if not contract.paintingZones then
        contract.paintingZones = {}
    end

    table.insert(contract.paintingZones, lib.points.new({
        coords = offsetCoords,
        distance = 30.0,
        nearby = onEnter,
        onEnter = onEnter
    }))

    if contract.paintings[paintingIndex] then
        contract.paintings[paintingIndex].remove()
    end
end

-- Display case stolen
RegisterNetEvent("lunar_contracts:house:displayCaseStolen", function(contractIndex)
    local contract = activeContracts[contractIndex]
    if contract and contract.contractIndex == contractIndex then
        if contract.displayCase then
            contract.displayCase.remove()
            contract.displayCase = nil
        end
    end
end)

-- Loot taken
RegisterNetEvent("lunar_contracts:house:looted", function(contractIndex, locationIndex, lootIndex)
    if not lootedZones[contractIndex] then
        lootedZones[contractIndex] = {}
    end
    lootedZones[contractIndex][lootIndex] = true

    if activeContracts[contractIndex] and activeContracts[contractIndex].lootZones and activeContracts[contractIndex].lootZones[lootIndex] then
        activeContracts[contractIndex].lootZones[lootIndex].remove()
        activeContracts[contractIndex].lootZones[lootIndex] = nil
    end

    if currentLocation == locationIndex and activeContracts[contractIndex] then
        if activeContracts[contractIndex].createdProps and activeContracts[contractIndex].createdProps[lootIndex] then
            activeContracts[contractIndex].createdProps[lootIndex].remove()
            activeContracts[contractIndex].createdProps[lootIndex] = nil
        end

        local interior = Config.interiors[Config.locations[locationIndex].tier]
        local lootConfig = interior.takeLoot[lootIndex]

        if lootConfig.removeProp then
            local obj = GetClosestObjectOfType(lootConfig.coords.x, lootConfig.coords.y, lootConfig.coords.z, 0.25, lootConfig.removeProp, false)
            if obj ~= 0 then
                SetEntityAsMissionEntity(obj)
                DeleteEntity(obj)
            end
        end
    end
end)

-- Get started locations callback
lib.callback.register("lunar_contracts:house:getStartedLocations", false, function(locations)
    for _, loc in ipairs(locations) do
        local locationIndex = loc.locationIndex
        createEntryPoint(locationIndex, loc.contractIndex)
        unlockedLocations[locationIndex] = loc.unlocked
    end
end)

-- Create contract state
local function createContract(contractIndex, locationIndex, tier, lootIndex)
    activeContracts[contractIndex] = {
        contractIndex = contractIndex,
        locationIndex = locationIndex,
        tier = tier,
        lootIndex = lootIndex,
        paintings = {},
        displayCase = nil,
        lootZones = {},
        createdProps = {},
        paintingZones = nil,
        startBlip = nil,
    }

    unlockedLocations[locationIndex] = true
    createEntryPoint(locationIndex, contractIndex)

    -- Create GPS waypoint to the house entrance
    local location = Config.locations[locationIndex]
    if location then
        local blipData = Config.blip
        activeContracts[contractIndex].startBlip = Utils.createBlip(location.entrance, blipData)
        SetBlipRoute(activeContracts[contractIndex].startBlip.value, true)
    end
end

-- Start contract
RegisterNetEvent("lunar_contracts:house:started", function(players, contractIndex, locationIndex, tier, lootIndex)
    for _, playerId in ipairs(players) do
        if Framework.getIdentifier() == playerId then
            createContract(contractIndex, locationIndex, tier, lootIndex)
        end
    end
end)

-- Reset contract
RegisterNetEvent("lunar_contracts:house:reset", function(contractIndex, shouldRemove)
    local contract = activeContracts[contractIndex]
    if not contract then
        return
    end

    if entryPoints[contract.locationIndex] then
        entryPoints[contract.locationIndex].remove()
        entryPoints[contract.locationIndex] = nil
    end

    if shouldRemove and exitPoints[contract.locationIndex] then
        exitPoints[contract.locationIndex].remove()
        exitPoints[contract.locationIndex] = nil
    end

    if keypadPoints[contract.locationIndex] then
        keypadPoints[contract.locationIndex].remove()
        keypadPoints[contract.locationIndex] = nil
    end

    for _, painting in pairs(contract.paintings) do
        painting.remove()
    end
    contract.paintings = {}

    if contract.displayCase then
        contract.displayCase.remove()
        contract.displayCase = nil
    end

    for _, zone in pairs(contract.lootZones) do
        zone.remove()
    end
    contract.lootZones = {}

    for _, prop in pairs(contract.createdProps) do
        prop.remove()
    end
    contract.createdProps = {}

    if contract.paintingZones then
        for _, zone in ipairs(contract.paintingZones) do
            zone.remove()
        end
        contract.paintingZones = nil
    end

    if contract.startBlip then
        contract.startBlip.remove()
        contract.startBlip = nil
    end

    if createdProps[contractIndex] then
        for _, prop in pairs(createdProps[contractIndex]) do
            prop.remove()
        end
        createdProps[contractIndex] = nil
    end

    if lootedZones[contractIndex] then
        lootedZones[contractIndex] = nil
    end

    unlockedLocations[contract.locationIndex] = nil
    homeownerState[contract.locationIndex] = nil
    alarmTriggered[contract.locationIndex] = nil

    if alarmPoints[contract.locationIndex] then
        alarmPoints[contract.locationIndex]:onExit()
        alarmPoints[contract.locationIndex]:remove()
        alarmPoints[contract.locationIndex] = nil
    end

    cleanupHomeowners(contract.locationIndex)
    roomSyncActive[contract.locationIndex] = nil

    if shouldRemove then
        if contract.tier then
            setLasersState(contract.locationIndex, false)
        end
    end

    if shouldRemove and currentLocation == contract.locationIndex then
        currentLocation = nil
        if alertTimer then
            ClearInterval(alertTimer)
            alertTimer = nil
        end
        LR.hideBars()

        local interior = Config.interiors[contract.tier]
        if interior and Utils.distanceCheck(cache.ped, interior.coords.xyz, 200.0) then
            DoScreenFadeOut(500)
            Wait(500)

            local location = Config.locations[contract.locationIndex]
            SetEntityCoords(cache.ped, location.coords.x, location.coords.y, location.coords.z)
            Wait(500)
            DoScreenFadeIn(500)
        end
    end

    if shouldRemove then
        activeContracts[contractIndex] = nil
    end
end)

-- Setup guard ped
local function setupGuardPed(locationIndex, ped)
    local location = Config.locations[locationIndex]
    local interior = Config.interiors[location.tier]
    local guardConfig = interior.guards

    SetPedDropsWeaponsWhenDead(ped, false)
    SetPedCombatAbility(ped, guardConfig.combatAbility)
    SetPedAccuracy(ped, guardConfig.accuracy)
    SetPedRelationshipGroupHash(ped, 1976378873)
    SetPedCombatMovement(ped, 1)
    SetPedCombatAttributes(ped, 5, true)
    SetPedCombatAttributes(ped, 43, true)
    SetPedCombatAttributes(ped, 21, true)
    SetPedCombatAttributes(ped, 50, true)
    SetPedDropsWeaponsWhenDead(ped, false)
end

-- Static ped animations
local staticAnimations = {
    { dict = "random@homelandsecurity", clip = "knees_loop_girl" },
    { dict = "anim@heists@ornate_bank@hostages@hit", clip = "hit_loop_ped_b" },
    { dict = "anim@heists@ornate_bank@hostages@hit", clip = "hit_loop_ped_c" },
    { dict = "anim@heists@ornate_bank@hostages@hit", clip = "hit_loop_ped_d" },
    { dict = "anim@heists@ornate_bank@hostages@hit", clip = "hit_loop_ped_e" }
}

-- Setup static ped
Utils.entityStateHandler("house:setupStaticPed", function(ped)
    SetBlockingOfNonTemporaryEvents(ped, true)

    local anim = Utils.randomFromTable(staticAnimations)
    lib.requestAnimDict(anim.dict)

    if not IsEntityPlayingAnim(ped, anim.dict, anim.clip, 3) then
        TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, -8.0, -1, 1, 0, false, false, false)
    end

    CreateThread(function()
        while DoesEntityExist(ped) do
            if not IsEntityPlayingAnim(ped, anim.dict, anim.clip, 3) then
                TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, -8.0, -1, 1, 0, false, false, false)
            end
            Wait(2000)
        end
    end)
end)

-- Guard AI logic
local guardAggroState = {}

local function handleGuardAI(locationIndex, ped)
    local location = Config.locations[locationIndex]
    local interior = Config.interiors[location.tier]

    -- Handle weapon switching
    if GetSelectedPedWeapon(ped) == -1569615261 then
        ClearPedTasks(ped)
        SetCurrentPedWeapon(ped, -1569615261, true)
    end

    -- Handle idle tasks
    if not GetIsTaskActive(ped, 357) and not GetIsTaskActive(ped, 343) then
        if math.random(1, 8) == 1 then
            TaskGuardCurrentPosition(ped, 15.0, 10.0, true)
        end
    end

    local isAggressive = Entity(ped).state["house:isPedAggressive"]
    local pedCoords = GetEntityCoords(ped)
    local nearbyPlayers = lib.getNearbyPlayers(pedCoords, 50.0, true)

    local closestPed = nil
    local closestDistance = math.huge

    for _, player in ipairs(nearbyPlayers) do
        local playerPed = player.ped
        local distance = #(GetEntityCoords(playerPed) - pedCoords)

        if closestDistance > distance then
            if not (distance < 20.0) then
                if distance < 30.0 and not IsPedArmed(cache.ped, 6) and not isAggressive then
                    if not guardAggroState[locationIndex] then
                        goto continue
                    end
                end
            end

            if not Editable.isDead(playerPed) then
                if interior.guards.minPolice == 0 then
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
        ::continue::
    end

    if closestPed and not GetIsTaskActive(ped, 343) then
        TaskCombatPed(ped, closestPed, 0, 16)
        guardAggroState[locationIndex] = true
    end
end

-- Guard relationship group
AddRelationshipGroup("HOUSE_GUARD")

-- Guard loot point creation

local function createGuardLootPoint(locationIndex, guardNetId, ped)
    if guardLootPoints[locationIndex] and guardLootPoints[locationIndex][guardNetId] then
        return
    end

    if not guardLootPoints[locationIndex] then
        guardLootPoints[locationIndex] = {}
    end

    local contractIndex = nil
    for idx, contract in pairs(activeContracts) do
        if contract.locationIndex == locationIndex then
            contractIndex = idx
            break
        end
    end

    guardLootPoints[locationIndex][guardNetId] = Utils.createInteractionPoint({
        coords = GetEntityCoords(ped),
        radius = 1.5,
        options = {{
            label = locale("take_loot"),
            icon = "hand",
            onSelect = function()
                if IsSpotOccupied(string.format("house:guard_%s", guardNetId)) then
                    return
                end

                local success = LR.progressBar(locale("looting_guard"),
                    Config.interiors[Config.locations[locationIndex].tier].guards.looting.progressDuration,
                    false,
                    { dict = "missbigscore2aig_7@driver", clip = "boot_r_loop", flag = 1 }
                )

                if success then
                    TriggerServerEvent("lunar_contracts:house:lootGuard", locationIndex, guardNetId)
                end

                FreeOccupiedSpot()
            end,
            canInteract = function()
                if not contractIndex then
                    return false
                end

                return not Busy and Utils.distanceCheck(cache.ped, ped, 1.5)
            end
        }}
    })
end

-- Guard looted event
RegisterNetEvent("lunar_contracts:house:guardLooted", function(guardNetId)
    lootedGuards[guardNetId] = true

    for _, points in pairs(guardLootPoints) do
        if points[guardNetId] then
            points[guardNetId].remove()
            points[guardNetId] = nil
            break
        end
    end
end)

-- Handle guard logic for location
local function handleGuardLogic(locationIndex, guardList)
    local location = Config.locations[locationIndex]
    local interior = Config.interiors[location.tier]

    SetRelationshipBetweenGroups(0, 1976378873, 1976378873)
    SetRelationshipBetweenGroups(4, 1976378873, 1862763509)
    SetRelationshipBetweenGroups(4, 1862763509, 1976378873)

    for _, guardId in ipairs(guardList) do
        if NetworkDoesEntityExistWithNetworkId(guardId) then
            local ped = NetworkGetEntityFromNetworkId(guardId)
            local owner = NetworkGetEntityOwner(ped)

            if owner == cache.playerId then
                handleGuardAI(locationIndex, ped)
            end

            if IsEntityDead(ped) and not lootedGuards[guardId] then
                if interior.guards.looting.enabled then
                    createGuardLootPoint(locationIndex, guardId, ped)
                end
            end
        else
            if guardLootPoints[locationIndex] and guardLootPoints[locationIndex][guardId] and interior.guards.looting.enabled then
                guardLootPoints[locationIndex][guardId].remove()
                guardLootPoints[locationIndex][guardId] = nil
            end
        end
    end
end

-- Guard logic zones
local entranceGuardZones = {}
local exitGuardZones = {}

RegisterNetEvent("lunar_contracts:house:handleGuardsLogic", function(locationIndex, guardList)
    entranceGuardZones[locationIndex] = lib.points.new({
        coords = Config.locations[locationIndex].entrance,
        distance = 200.0,
        nearby = function()
            handleGuardLogic(locationIndex, guardList)
            Wait(1000)
        end
    })

    exitGuardZones[locationIndex] = lib.points.new({
        coords = Config.interiors[Config.locations[locationIndex].tier].exit,
        distance = 200.0,
        nearby = function()
            handleGuardLogic(locationIndex, guardList)
            Wait(1000)
        end
    })
end)

-- Remove guards
RegisterNetEvent("lunar_contracts:house:removeGuards", function(locationIndex)
    if entranceGuardZones[locationIndex] then
        entranceGuardZones[locationIndex].remove()
        entranceGuardZones[locationIndex] = nil
    end

    if exitGuardZones[locationIndex] then
        exitGuardZones[locationIndex].remove()
        exitGuardZones[locationIndex] = nil
    end

    if guardLootPoints[locationIndex] then
        for _, point in pairs(guardLootPoints[locationIndex]) do
            point.remove()
        end
        guardLootPoints[locationIndex] = nil
    end

    table.wipe(lootedGuards)
    guardAggroState[locationIndex] = nil
end)

-- Owner left area notification
RegisterNetEvent("lunar_contracts:house:ownerLeftArea", function()
    LR.notify(locale("house_left_area"), "error")
end)

-- Owner returned to area notification
RegisterNetEvent("lunar_contracts:house:ownerReturnedToArea", function()
    LR.notify(locale("house_returned_to_area"), "success")
end)

-- Contract abandoned notification
RegisterNetEvent("lunar_contracts:house:contractAbandoned", function()
    LR.notify(locale("house_abandoned"), "error")
end)