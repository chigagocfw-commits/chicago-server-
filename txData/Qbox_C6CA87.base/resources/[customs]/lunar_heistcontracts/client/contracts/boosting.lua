local boostingConfig = Config.contracts.boosting
local minigames = Editable.minigames.boosting

local scaleform = nil
local colors = {
    red = { r = 255, g = 10, b = 10 },
    yellow = { r = 255, g = 209, b = 67 },
    lightblue = { r = 67, g = 200, b = 255 },
    green = { r = 0, g = 255, b = 80 }
}

local function setScaleformColor(color1, color2)
    if not scaleform then return end
    BeginScaleformMovieMethod(scaleform, "SET_COLOUR")
    PushScaleformMovieMethodParameterInt(color1.r)
    PushScaleformMovieMethodParameterInt(color1.g)
    PushScaleformMovieMethodParameterInt(color1.b)
    PushScaleformMovieMethodParameterInt(color2.r)
    PushScaleformMovieMethodParameterInt(color2.g)
    PushScaleformMovieMethodParameterInt(color2.b)
    EndScaleformMovieMethod()
end

local distanceLevels = {
    { distance = 30.0, bars = 0.0, beepInterval = 10000 },
    { distance = 20.0, bars = 50.0, beepInterval = 8000 },
    { distance = 15.0, bars = 60.0, beepInterval = 6000 },
    { distance = 10.0, bars = 70.0, beepInterval = 5000 },
    { distance = 5.0, bars = 80.0, beepInterval = 2500 },
    { distance = 2.0, bars = 90.0, beepInterval = 1000 },
    { distance = 1.0, bars = 100.0, beepInterval = 500 }
}

local currentBeepInterval = nil

local function updateDistanceUI(distance)
    if not scaleform then return end
    
    for i, level in ipairs(distanceLevels) do
        if distance > level.distance then
            BeginScaleformMovieMethod(scaleform, "SET_DISTANCE")
            PushScaleformMovieMethodParameterFloat(level.bars)
            EndScaleformMovieMethod()
            currentBeepInterval = level.beepInterval
            break
        end
    end
    
    if distance <= 1.5 then
        setScaleformColor(colors.green, colors.green)
    end
end

local function isFacingDirection(target)
    local playerCoords = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)
    local dx = target.x - playerCoords.x
    local dy = target.y - playerCoords.y
    local targetHeading = GetHeadingFromVector_2d(dx, dy)
    return math.abs(heading - targetHeading) < 20
end

local isSignalHacking = false

local function startSignalHacking(contractIndex)
    isSignalHacking = false
    
    local signalCoords = lib.callback.await("lunar_contracts:boosting:getSignal", false, contractIndex)
    
    scaleform = RequestScaleformMovie("digiscanner")
    while not HasScaleformMovieLoaded(scaleform) do Wait(0) end
    
    if not IsNamedRendertargetRegistered("digiscanner") then
        RegisterNamedRendertarget("digiscanner", false)
    end
    LinkNamedRendertarget(GetWeapontypeModel(-38085395), "digiscanner")
    
    local renderId = GetNamedRendertargetRenderId("digiscanner")
    
    CreateThread(function()
        while not isSignalHacking and activeContract do
            local weapon = GetSelectedPedWeapon(cache.ped)
            if weapon == -38085395 then
                SetTextRenderId(renderId)
                DrawScaleformMovie(scaleform, 0.1, 0.24, 0.21, 0.51, 100, 100, 100, 255, 0)
                SetTextRenderId(1)
            else
                Wait(100)
            end
            Wait(0)
        end
    end)
    
    CreateThread(function()
        while not isSignalHacking and activeContract do
            local isAiming = GetPedConfigFlag(cache.ped, 78)
            local weapon = GetSelectedPedWeapon(cache.ped)
            
            if weapon == -38085395 and (IsPlayerFreeAiming(cache.playerId) or isAiming) then
                if isFacingDirection(signalCoords) then
                    setScaleformColor(colors.lightblue, colors.yellow)
                else
                    setScaleformColor(colors.red, colors.red)
                end
                
                local distance = #(GetEntityCoords(cache.ped) - signalCoords)
                updateDistanceUI(distance)
                
                if distance <= 1.5 then
                    Wait(2000)
                    RemoveAllPedWeapons(cache.ped)
                    if minigames.signal() then
                        TriggerServerEvent("lunar_contracts:boosting:signalHacked", contractIndex)
                    else
                        LR.notify(locale("signal_hack_failed"), "error")
                    end
                end
            end
            Wait(200)
        end
    end)
    
    CreateThread(function()
        while not isSignalHacking and activeContract do
            if GetSelectedPedWeapon(cache.ped) == -38085395 then
                PlaySoundFrontend(-1, "IDLE_BEEP", "epsilonism_04_soundset", true)
            end
            Wait(currentBeepInterval or 10000)
        end
    end)
end

-- Lockpick vehicle
local lockpickPoint = nil

local function setupLockpick(contractIndex)
    while activeContract and not isSignalHacking do
        if NetworkDoesEntityExistWithNetworkId(activeContract.vehicleNetId) then
            if not lockpickPoint then
                local vehicle = NetworkGetEntityFromNetworkId(activeContract.vehicleNetId)
                lockpickPoint = Utils.createEntityPoint({
                    entity = vehicle,
                    offset = vector3(-0.8, 0.0, 0.1),
                    distance = 2.0,
                    options = {{
                        label = locale("use_lockpick"),
                        icon = "lock",
                        onSelect = function()
                            local requiredLockpickItem = boostingConfig.lockpickItem and boostingConfig.lockpickItem.name
                            if requiredLockpickItem and not Framework.hasItem(requiredLockpickItem) then
                                LR.notify(locale("missing_" .. requiredLockpickItem), "error")
                                return
                            end
                            if minigames.lockpick() then
                                TriggerServerEvent("lunar_contracts:boosting:lockpicked", contractIndex)
                            end
                        end
                    }}
                })
            end
        elseif lockpickPoint then
            lockpickPoint.remove()
            lockpickPoint = nil
        end
        Wait(200)
    end
end

local currentBlip = nil
local radiusBlip = nil
local deliveryBlip = nil
local deliveryPeds = {}
local trackerUI = false
local trackerKeybindActive = false
local isRemovingTracker = false

-- Vehicle unlocked event
RegisterNetEvent("lunar_contracts:boosting:vehicleUnlocked", function(contractIndex, deliveryIndex, skipTracker)
    local deliveryLocation = boostingConfig.deliveryLocations[deliveryIndex]
    local pedModel = Utils.randomFromTable(boostingConfig.deliveryPed)
    
    deliveryPeds[contractIndex] = Utils.createPed(deliveryLocation, pedModel)
    
    if not activeContract or activeContract.contractIndex ~= contractIndex then return end
    
    isSignalHacking = true
    Editable.addKeys(activeContract.plate)
    LR.notify(locale("vehicle_unlocked"), "success")
    
    local objText = skipTracker and locale("obj_deliver_vehicle2") or locale("obj_deliver_vehicle")
    LR.showObjective(locale("boosting_title"), objText)
    
    if lockpickPoint then
        lockpickPoint.remove()
        lockpickPoint = nil
    end
    
    deliveryBlip = Utils.createBlip(deliveryLocation, boostingConfig.deliveryBlip)
    SetBlipRoute(deliveryBlip.value, true)
    
    local deliveryZone = nil
    local showTrackerUI = false
    local showingTrackerUI = false
    
    while activeContract do
        local vehicleNetId = activeContract.vehicleNetId
        local vehicle = NetworkDoesEntityExistWithNetworkId(vehicleNetId) and NetworkGetEntityFromNetworkId(vehicleNetId) or nil
        
        if vehicle then
            local hasTracker = Entity(vehicle).state["boosting:hasTracker"]
            local isDriver = cache.vehicle == vehicle
            
            if hasTracker and isDriver and not showingTrackerUI then
                LR.showUI(locale("remove_tracker", Binds.interact.getCurrentKey()), "microchip")
                showingTrackerUI = true
                
                Binds.interact.addListener("remove_tracker", function()
                    if isRemovingTracker then return end
                    if cache.vehicle ~= vehicle then return end
                    if GetPedInVehicleSeat(cache.vehicle, 0) ~= cache.ped then return end
                    
                    local requiredTrackerItem = boostingConfig.removeTrackerItem and boostingConfig.removeTrackerItem.name
                    if requiredTrackerItem and not Framework.hasItem(requiredTrackerItem) then
                        LR.notify(locale("missing_" .. requiredTrackerItem), "error")
                        return
                    end
                    
                    isRemovingTracker = true
                    
                    LR.progressBar(locale("plugging_usb"), 3000, false, {
                        dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
                        clip = "machinic_loop_mechandplayer",
                        flag = 49
                    })
                    
                    if cache.vehicle == vehicle and GetPedInVehicleSeat(cache.vehicle, 0) == cache.ped then
                        if minigames.removeTracker() then
                            TriggerServerEvent("lunar_contracts:boosting:removeTracker", contractIndex)
                            LR.hideUI()
                            Binds.interact.removeListener("remove_tracker")
                            showTrackerUI = false
                            isRemovingTracker = false
                            SetTimeout(3000, function() showingTrackerUI = false end)
                        end
                    end
                    isRemovingTracker = false
                end)
                showTrackerUI = true
            elseif (not isDriver or not hasTracker) and showingTrackerUI then
                LR.hideUI()
                showingTrackerUI = false
                if showTrackerUI then
                    Binds.interact.removeListener("remove_tracker")
                    showTrackerUI = false
                end
            end
        elseif showingTrackerUI then
            LR.hideUI()
            showingTrackerUI = false
            if showTrackerUI then
                Binds.interact.removeListener("remove_tracker")
                showTrackerUI = false
            end
        end
        
        if cache.vehicle == vehicle then
            local driver = GetPedInVehicleSeat(cache.vehicle, -1)
            if driver == cache.ped then
                if not deliveryZone then
                    local zoneCoords = Utils.offsetCoords(deliveryLocation, 0.0, 1.5, 0.0)
                    deliveryZone = lib.points.new({
                        coords = zoneCoords,
                        distance = 4.0,
                        onEnter = function()
                            LR.showUI(locale("press_to_deliver", Binds.interact.getCurrentKey()), "dollar-sign")
                            Binds.interact.addListener("deliver_vehicle", function()
                                if Entity(vehicle).state["boosting:hasTracker"] then
                                    LR.notify(locale("tracker_not_removed"), "error")
                                    return
                                end
                                TriggerServerEvent("lunar_contracts:boosting:deliverVehicle", contractIndex)
                                SetVehicleDoorsLockedForAllPlayers(vehicle, true)
                                Binds.interact.removeListener("deliver_vehicle")
                                if deliveryZone then
                                    deliveryZone:onExit()
                                    deliveryZone.remove()
                                    deliveryZone = nil
                                end
                                Wait(2000)
                            end)
                        end,
                        onExit = function()
                            LR.hideUI()
                        end
                    })
                end
            elseif deliveryZone then
                deliveryZone:onExit()
                deliveryZone.remove()
                deliveryZone = nil
                Binds.interact.removeListener("deliver_vehicle")
            end
        elseif deliveryZone then
            deliveryZone:onExit()
            deliveryZone.remove()
            deliveryZone = nil
            Binds.interact.removeListener("deliver_vehicle")
        end
        
        Wait(500)
    end
end)

-- Vehicle delivered event
RegisterNetEvent("lunar_contracts:boosting:vehicleDelivered", function(contractIndex, vehicleNetId)
    local ped = deliveryPeds[contractIndex]
    
    SetTimeout(2000, function()
        if ped then
            local npc = ped.get()
            local vehicle = NetworkDoesEntityExistWithNetworkId(vehicleNetId) and NetworkGetEntityFromNetworkId(vehicleNetId) or nil
            
            if npc and vehicle then
                ped.free()
                if Config.invincibleDeliveryPed then
                    SetEntityInvincible(npc, true)
                end
                SetBlockingOfNonTemporaryEvents(npc, true)
                TaskSetBlockingOfNonTemporaryEvents(npc, true)
                TaskEnterVehicle(npc, vehicle, 20000, -1, 1.0, 1, 0)
                
                while not IsPedInVehicle(npc, vehicle, false) do Wait(100) end
                
                TaskVehicleDriveWander(npc, vehicle, 20.0, 1)
                
                SetTimeout(30000, function()
                    if DoesEntityExist(vehicle) then DeleteEntity(vehicle) end
                    if DoesEntityExist(npc) then DeleteEntity(npc) end
                end)
            end
            deliveryPeds[contractIndex] = nil
        end
    end)
    
    if not activeContract or activeContract.contractIndex ~= contractIndex then return end
    
    if deliveryBlip then
        deliveryBlip.remove()
        deliveryBlip = nil
    end
    
    Editable.removeKeys(activeContract.plate)
    
    local vehicle = NetworkDoesEntityExistWithNetworkId(activeContract.vehicleNetId) and NetworkGetEntityFromNetworkId(activeContract.vehicleNetId) or nil
    if cache.vehicle == vehicle then
        TaskLeaveVehicle(cache.ped, cache.vehicle, 0)
    end
    
    LR.hideObjective()
    activeContract = nil
    isSignalHacking = false
end)

-- Reset current contract
local function resetContract()
    if not activeContract then return end
    TriggerEvent("lunar_contracts:boosting:reset", activeContract.contractIndex)
    while activeContract do Wait(100) end
end

-- Start boosting contract
local function startBoosting(contractIndex, deliveryIndex, style, spawnCoords, approxCoords)
    resetContract()
    
    activeContract = {
        contractIndex = contractIndex,
        deliveryIndex = deliveryIndex,
        style = style
    }
    
    local areaBlip = Utils.createBlip(approxCoords, boostingConfig.areaBlip)
    local radiusBlip = Utils.createRadiusBlip(approxCoords, "", boostingConfig.approximateRadius, boostingConfig.areaBlip.color)
    
    LR.showObjective(locale("boosting_title"), locale("obj_go_to_approx"))
    Utils.distanceWait(approxCoords, boostingConfig.approximateRadius)
    
    if not activeContract then return end
    
    TriggerServerEvent("lunar_contracts:boosting:spawnVehicle", activeContract.contractIndex)
    
    while activeContract and not activeContract.plate do Wait(100) end
    if not activeContract then return end
    
    LR.showObjective(locale("boosting_title"), locale("obj_find_car", activeContract.plate))
    Utils.distanceWait(spawnCoords, 10.0)
    
    if not activeContract then return end
    
    areaBlip.remove()
    radiusBlip.remove()
    
    local vehicleBlip = nil
    
    CreateThread(function()
        while activeContract do
            local vehicleNetId = activeContract.vehicleNetId
            local vehicle = NetworkDoesEntityExistWithNetworkId(vehicleNetId) and NetworkGetEntityFromNetworkId(vehicleNetId) or nil
            
            if vehicle and cache.vehicle ~= vehicle then
                if not vehicleBlip then
                    vehicleBlip = Utils.createEntityBlip(vehicle, boostingConfig.carBlip)
                end
            elseif vehicleBlip then
                vehicleBlip.remove()
                vehicleBlip = nil
            end
            Wait(200)
        end
        if vehicleBlip then vehicleBlip.remove() end
    end)
    
    if not activeContract then return end
    
    if style == "lockpick" then
        LR.showObjective(locale("boosting_title"), locale("obj_lockpick_vehicle"))
        setupLockpick(contractIndex)
    elseif style == "keyfob" then
        LR.showObjective(locale("boosting_title"), locale("obj_find_signal"))
        startSignalHacking(contractIndex)
    end
end

RegisterNetEvent("lunar_contracts:boosting:started", function(members, contractIndex, deliveryIndex, style, spawnCoords, approxCoords)
    for _, memberId in ipairs(members) do
        if Framework.getIdentifier() == memberId then
            startBoosting(contractIndex, deliveryIndex, style, spawnCoords, approxCoords)
        end
    end
end)

RegisterNetEvent("lunar_contracts:boosting:addVehicle", function(contractIndex, vehicleNetId, plate)
    if not activeContract or activeContract.contractIndex ~= contractIndex then return end
    activeContract.vehicleNetId = vehicleNetId
    activeContract.plate = plate
end)

-- Guard dog setup
AddRelationshipGroup("GUARD_DOG")

Utils.entityStateHandler("boosting:initDog", function(entity, shouldInit)
    if not shouldInit then return end
    if NetworkGetEntityOwner(entity) ~= cache.playerId then return end
    
    SetPedCombatAttributes(entity, 5, true)
    SetPedCombatAttributes(entity, 13, true)
    SetBlockingOfNonTemporaryEvents(entity, true)
    SetRelationshipBetweenGroups(5, 1862763509, 1378588234)
    SetRelationshipBetweenGroups(5, 1378588234, 1862763509)
    SetPedRelationshipGroupHash(entity, 1378588234)
    TaskCombatHatedTargetsAroundPed(entity, 200.0, 0)
    
    CreateThread(function()
        while DoesEntityExist(entity) and not IsEntityDead(entity) do
            if not GetIsTaskActive(entity, 343) then
                TaskCombatHatedTargetsAroundPed(entity, 300.0, 0)
            end
            Wait(1000)
        end
    end)
end, true)

-- Vehicle lock/unlock state handlers
Utils.entityStateHandler("boosting:lockVehicle", function(entity, shouldLock)
    if not shouldLock then return end
    if NetworkGetEntityOwner(entity) ~= cache.playerId then return end
    SetVehicleDoorsLockedForAllPlayers(entity, true)
end, true)

Utils.entityStateHandler("boosting:unlockVehicle", function(entity, shouldUnlock)
    if not shouldUnlock then return end
    if NetworkGetEntityOwner(entity) ~= cache.playerId then return end
    SetVehicleDoorsLockedForAllPlayers(entity, false)
end, true)

-- Police vehicle blips
local policeBlips = {}

RegisterNetEvent("lunar_contracts:boosting:syncVehicleBlips", function(blips)
    if not Utils.isPolice() then
        for _, blip in pairs(policeBlips) do
            blip.remove()
        end
        policeBlips = {}
        return
    end
    
    for netId, coords in pairs(blips) do
        if policeBlips[netId] then
            SetBlipCoords(policeBlips[netId].value, coords)
        else
            policeBlips[netId] = Utils.createBlip(coords, boostingConfig.dispatch.vehicleBlip)
        end
    end
    
    for netId, blip in pairs(policeBlips) do
        if not blips[netId] then
            blip.remove()
            policeBlips[netId] = nil
        end
    end
end)

RegisterNetEvent("lunar_contracts:boosting:removeVehicleBlips", function()
    for _, blip in pairs(policeBlips) do
        blip.remove()
    end
    policeBlips = {}
end)

-- Cleanup scaleform and render target
local function cleanup()
    if scaleform then
        SetScaleformMovieAsNoLongerNeeded(scaleform)
        scaleform = nil
    end
    if IsNamedRendertargetRegistered("digiscanner") then
        ReleaseNamedRendertarget("digiscanner")
    end
end

RegisterNetEvent("lunar_contracts:boosting:reset", function(contractIndex)
    if not activeContract or activeContract.contractIndex ~= contractIndex then return end
    
    if areaBlip then areaBlip.remove(); areaBlip = nil end
    if radiusBlip then radiusBlip.remove(); radiusBlip = nil end
    if deliveryBlip then deliveryBlip.remove(); deliveryBlip = nil end
    if lockpickPoint then lockpickPoint.remove(); lockpickPoint = nil end
    
    if deliveryPeds[contractIndex] then
        if deliveryPeds[contractIndex].free then deliveryPeds[contractIndex].free() end
        deliveryPeds[contractIndex] = nil
    end
    
    if activeContract.plate then
        Editable.removeKeys(activeContract.plate)
    end
    
    LR.hideUI()
    LR.hideObjective()
    Binds.interact.removeListener("deliver_vehicle")
    Binds.interact.removeListener("remove_tracker")
    cleanup()
    isSignalHacking = false
    activeContract = nil
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    cleanup()
end)
