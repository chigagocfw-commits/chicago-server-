if not ATM then
    error("ATM module must be loaded before animations.lua")
end

local animationInProgress = false
local scenarioActive = false
local currentAtm = nil
local forceEnding = false
local wasRadarVisible = true

local function getPedGender(ped, lowerCase)
    local gender = IsPedMale(ped) and "Male" or "Female"

    if lowerCase then
        return gender:lower()
    end

    return gender
end

local function getCurrentAtmModel()
    local atm = ATM:getCurrentATM()

    if atm and DoesEntityExist(atm) then
        return GetEntityModel(atm), atm
    end

    return nil, atm
end

local function getCardOffsets(atm)
    local model = atm and DoesEntityExist(atm) and GetEntityModel(atm) or nil
    local offsets = Config.Offsets and Config.Offsets.CardPos

    if not offsets then
        return nil
    end

    return offsets[model] or offsets.Default
end

local function getConfiguredAnimation(section)
    local ped = PlayerPedId()
    local gender = getPedGender(ped, false)
    local model = getCurrentAtmModel()
    local config = Config.AnimSettings.InsertCard[gender][section]

    local dict = config.Dict[model] or config.Dict.Default
    local anim = config.Anim[model] or config.Anim.Default

    return dict, anim, ped
end

local function isInterrupted()
    local ped = PlayerPedId()

    if IsPedDeadOrDying(ped, true) or IsPedInAnyVehicle(ped, false) or IsPedRagdoll(ped) then
        return true
    end

    if currentAtm and DoesEntityExist(currentAtm) then
        local distance = #(GetEntityCoords(ped) - GetEntityCoords(currentAtm))

        if distance > 3.0 then
            return true
        end
    end

    return forceEnding
end

local function resetSequenceState()
    currentAtm = nil
    forceEnding = false
    animationInProgress = false
    scenarioActive = false
end

local function attachCardToHand(cardObject, ped, boneId)
    local bone = GetPedBoneIndex(ped, boneId or 28422)
    AttachEntityToEntity(
        cardObject,
        ped,
        bone,
        0.1,
        0.03,
        -0.05,
        0.0,
        0.0,
        180.0,
        true,
        true,
        false,
        true,
        1,
        true
    )
end

local function slideObjectTo(object, coords)
    local finished = false

    while not finished do
        finished = SlideObject(object, coords.x, coords.y, coords.z, 0.001, 0.001, 0.001, false)
        Wait(10)
    end
end

local function moveCardIntoAtm(cardObject, atm)
    if not atm or not DoesEntityExist(atm) then
        return
    end

    local offsets = getCardOffsets(atm)

    if not offsets then
        return
    end

    local firstPosition = GetOffsetFromEntityInWorldCoords(atm, offsets.First.x, offsets.First.y, offsets.First.z)
    SetEntityCoords(cardObject, firstPosition.x, firstPosition.y, firstPosition.z, false, false, false, true)
    SetEntityRotation(cardObject, -90.0, 90.0, GetEntityHeading(atm), 2, true)

    local secondPosition = GetOffsetFromEntityInWorldCoords(atm, offsets.Second.x, offsets.Second.y, offsets.Second.z)
    slideObjectTo(cardObject, secondPosition)

    SetEntityAsMissionEntity(cardObject, true, true)
    SetEntityCoords(cardObject, secondPosition.x, secondPosition.y, secondPosition.z, false, false, false, true)
    SetEntityAlpha(cardObject, 0, false)
end

local function playInsertCardAnimation(callback)
    animationInProgress = true

    local dict, anim, ped = getConfiguredAnimation("Insert")

    loadAnimDict(dict, function()
        if Config.AnimSettings.InsertCard.Object then
            local spawnCoords = GetEntityCoords(ped) + vector3(0.0, 0.0, 1.0)

            createObject(Config.Objects.Card, spawnCoords, Config.AnimSettings.InsertCard.IsLocal, function(cardObject)
                if not cardObject then
                    Debug("insertCardAnim: Failed to create card object")
                    animationInProgress = false
                    return callback()
                end

                FreezeEntityPosition(cardObject, true)
                ATM:setCurrentCardObject(cardObject)
                attachCardToHand(cardObject, ped, 28422)

                TaskPlayAnim(ped, dict, anim, 8.0, 8.0, 1500, 1, 0, false, false, false)
                Wait(1500)
                ClearPedTasks(ped)
                DetachEntity(cardObject, false, false)

                local atm = ATM:getCurrentATM()
                moveCardIntoAtm(cardObject, atm)

                Wait(500)
                animationInProgress = false
                callback(cardObject)
            end)

            return
        end

        TaskPlayAnim(ped, dict, anim, 8.0, 8.0, 1500, 1, 0, false, false, false)
        Wait(1500)
        ClearPedTasks(ped)
        SetEntityAlpha(ped, 0, false)

        animationInProgress = false
        callback()
    end)
end

local function playRemoveCardAnimation(callback)
    animationInProgress = true

    local dict, anim, ped = getConfiguredAnimation("Remove")

    loadAnimDict(dict, function()
        local cardObject = ATM:getCurrentCardObject()
        local atm = ATM:getCurrentATM()

        if cardObject and DoesEntityExist(cardObject) and atm and DoesEntityExist(atm) then
            local offsets = getCardOffsets(atm)

            if offsets then
                local firstPosition = GetOffsetFromEntityInWorldCoords(atm, offsets.First.x, offsets.First.y, offsets.First.z)
                SetEntityAlpha(cardObject, 255, false)
                slideObjectTo(cardObject, firstPosition)
                SetEntityCoords(cardObject, firstPosition.x, firstPosition.y, firstPosition.z, false, false, false, true)
            end
        end

        TaskPlayAnim(ped, dict, anim, 8.0, 8.0, 1000, 1, 0, false, false, false)
        Wait(1000)

        if cardObject and DoesEntityExist(cardObject) then
            attachCardToHand(cardObject, ped, 28422)
        end

        Wait(1000)
        ClearPedTasks(ped)

        if cardObject and DoesEntityExist(cardObject) then
            DetachEntity(cardObject, false, false)
            ATM:clearCardObject()
        end

        animationInProgress = false
        callback()
    end)
end

local function stopATMScenario()
    if not scenarioActive then
        return
    end

    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, false)
    SetPedCanRagdoll(ped, true)
    scenarioActive = false
end

local function clearInterruptedSequence(message)
    local ped = PlayerPedId()

    Debug(message)
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    SetPedCanRagdoll(ped, true)
    DisplayRadar(wasRadarVisible)
    resetSequenceState()
    ATM:setUsageState(false)
end

local function walkToATM(atm, ped, atmCoords)
    local targetPosition = GetOffsetFromEntityInWorldCoords(atm, 0.0, -0.6, 0.0)
    local heading = GetHeadingFromVector_2d(atmCoords.x - targetPosition.x, atmCoords.y - targetPosition.y)
    local startTime = GetGameTimer()
    local timeout = 10000

    if #(GetEntityCoords(ped).xy - targetPosition.xy) <= 0.1 then
        return heading
    end

    TaskGoStraightToCoord(ped, targetPosition.x, targetPosition.y, targetPosition.z, 1.0, timeout, heading, 0.0)

    while GetGameTimer() - startTime < timeout do
        if isInterrupted() then
            clearInterruptedSequence("insertCardSequence: Interrupted while walking to ATM")
            return nil
        end

        if #(GetEntityCoords(ped).xy - targetPosition.xy) < 0.9 then
            break
        end

        Wait(50)
    end

    if #(GetEntityCoords(ped).xy - targetPosition.xy) > 1.1 then
        Debug("insertCardSequence: Player too far, adjusting position")
        SetEntityCoords(ped, targetPosition.x, targetPosition.y, targetPosition.z - 1.0, false, false, false, true)
        SetEntityHeading(ped, heading)
    end

    return heading
end

local function turnToATM(atm, ped, atmCoords)
    local pedCoords = GetEntityCoords(ped)
    local heading = GetHeadingFromVector_2d(atmCoords.x - pedCoords.x, atmCoords.y - pedCoords.y)

    SetPedDesiredHeading(ped, heading)
    TaskTurnPedToFaceCoord(ped, atmCoords.x, atmCoords.y, atmCoords.z, -1)

    for _ = 1, 20 do
        if isInterrupted() then
            clearInterruptedSequence("insertCardSequence: Interrupted while turning to ATM")
            return false
        end

        local currentHeading = GetEntityHeading(ped)
        local diff = math.abs(currentHeading - heading)

        if diff > 180 then
            diff = 360 - diff
        end

        if diff < 15.0 then
            break
        end

        Wait(50)
    end

    return true
end

local function insertCardSequence(atm, callback)
    if animationInProgress then
        Debug("insertCardSequence: Animation already in progress")
        return
    end

    Debug("insertCardSequence: Starting animation")

    animationInProgress = true
    currentAtm = atm
    forceEnding = false
    ATM:setCurrentATM(atm)

    local ped = PlayerPedId()
    ClearPedTasks(ped)
    SetPedCanRagdoll(ped, false)
    FreezeEntityPosition(ped, false)
    SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)

    wasRadarVisible = not IsRadarHidden()
    DisplayRadar(false)

    Debug("insertCardSequence: Walking to ATM")

    local atmCoords = GetEntityCoords(atm)
    local heading = walkToATM(atm, ped, atmCoords)

    if not heading then
        return
    end

    if isInterrupted() then
        clearInterruptedSequence("insertCardSequence: Interrupted after reaching ATM")
        return
    end

    if not turnToATM(atm, ped, atmCoords) then
        return
    end

    Wait(300)

    if isInterrupted() then
        clearInterruptedSequence("insertCardSequence: Interrupted before animation")
        return
    end

    local gender = getPedGender(ped, true)
    PlayAnimation(ped, ("amb@prop_human_atm@%s@enter"):format(gender), "enter", 3000, 1)
    Wait(3000)
    PlayAnimation(ped, ("amb@prop_human_atm@%s@base"):format(gender), "base", -1, 1)
    Wait(1000)

    if Config.EnableATMCamera and CameraHandler then
        CameraHandler.createAtmCamera(atm)
    end

    animationInProgress = false

    if callback then
        callback()
    end
end

local function endATMSequence()
    local ped = PlayerPedId()

    forceEnding = true
    Debug("endATMSequence: Unfreezing player position")

    FreezeEntityPosition(ped, false)
    SetPedCanRagdoll(ped, true)
    stopATMScenario()

    if Config.EnableATMCamera and CameraHandler then
        Debug("endATMSequence: Destroying ATM camera")
        CameraHandler.destroyAtmCamera()
    end

    Debug("endATMSequence: Starting card removal animation")

    playRemoveCardAnimation(function()
        Debug("endATMSequence: Card removal complete")

        ClearPedTasks(ped)
        SetPedCanRagdoll(ped, true)
        FreezeEntityPosition(ped, false)
        DisplayRadar(wasRadarVisible)

        ATM:clearCardObject()
        ATM:setCurrentATM(nil)
        ATM:setUsageState(false)

        resetSequenceState()
    end)
end

local function isAnimationActive()
    return animationInProgress or scenarioActive
end

local function isATMActive()
    return currentAtm ~= nil and DoesEntityExist(currentAtm)
end

local function forceStopAnimation()
    local ped = PlayerPedId()

    FreezeEntityPosition(ped, false)
    forceEnding = true

    if SetATMUsageState then
        SetATMUsageState(false)
    end

    endATMSequence()
end

CreateThread(function()
    while true do
        if scenarioActive then
            Wait(100)

            local ped = PlayerPedId()

            if isInterrupted() then
                Debug("ATM scenario interrupted by external factor")
                FreezeEntityPosition(ped, false)
                SetPedCanRagdoll(ped, true)
                endATMSequence()
            elseif not IsPedUsingScenario(ped, "PROP_HUMAN_ATM") and not IsPedDeadOrDying(ped, true) then
                TaskStartScenarioInPlace(ped, "PROP_HUMAN_ATM", 0, true)
            end
        else
            Wait(500)
        end
    end
end)

function LoadAnimDict(dict)
    local ok, loaded = pcall(HasAnimDictLoaded, dict)

    if not ok then
        Debug("LoadAnimDict: Error checking animation dictionary: " .. tostring(loaded))
        return false
    end

    if loaded then
        return true
    end

    ok, loaded = pcall(RequestAnimDict, dict)

    if not ok then
        Debug("LoadAnimDict: Error requesting animation dictionary: " .. tostring(loaded))
        return false
    end

    local attempts = 0

    while not HasAnimDictLoaded(dict) and attempts < 50 do
        Wait(10)
        attempts = attempts + 1
    end

    ok, loaded = pcall(HasAnimDictLoaded, dict)

    if not ok then
        Debug("LoadAnimDict: Error checking if animation dictionary loaded: " .. tostring(loaded))
        return false
    end

    return loaded == true
end

function PlayAnimation(ped, dict, anim, duration, flags)
    local ok, loaded = pcall(LoadAnimDict, dict)

    if not ok or not loaded then
        Debug("PlayAnimation: Error loading animation dictionary: " .. tostring(loaded))
        return false
    end

    TaskPlayAnim(ped, dict, anim, 1.0, 1.0, duration, flags or 0, 1, true, true, true)
    return true
end

AnimationHandler = {
    insertCardSequence = insertCardSequence,
    endATMSequence = endATMSequence,
    isAnimationActive = isAnimationActive,
    isATMActive = isATMActive,
    stopATMScenario = stopATMScenario,
    forceStopAnimation = forceStopAnimation,
}

exports("isATMActive", isATMActive)
