local boostingConfig = Config.contracts.boosting

local activeBoostingContracts = {}
local spawnedEntities = {}
local vehicleBlips = {}

local function getClassSettings(className)
    if className then
        for _, class in ipairs(boostingConfig.classes) do
            if class.label == className then
                return class.settings
            end
        end
    end
    return boostingConfig.settings
end

local function getContractSettings(contractId)
    local contract = activeBoostingContracts[contractId]
    if contract and contract.class then
        return getClassSettings(contract.class.label)
    end
    return boostingConfig.settings
end

local function addTrackerBlip(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle):strtrim()
    vehicleBlips[vehicle] = true
    
    Dispatch.call(GetEntityCoords(vehicle), {
        Code = boostingConfig.dispatch.code,
        Title = boostingConfig.dispatch.title,
        Message = boostingConfig.dispatch.message,
        Plate = plate
    })
end

local function removeTrackerBlip(vehicle)
    vehicleBlips[vehicle] = nil
    if Utils.getTableSize(vehicleBlips) == 0 then
        TriggerClientEvent("lunar_contracts:boosting:removeVehicleBlips", -1)
    end
end

local function cleanUpEntities(contractId)
    local contract = activeBoostingContracts[contractId]
    if not contract then return end
    
    if contract.vehicle and DoesEntityExist(contract.vehicle) then
        if not contract.vehicleDeleted[contract.vehicle] then
            removeTrackerBlip(contract.vehicle)
            DeleteEntity(contract.vehicle)
            
            for i, entity in ipairs(spawnedEntities) do
                if entity == contract.vehicle then
                    table.remove(spawnedEntities, i)
                    break
                end
            end
        end
    end
    
    if contract.entities then
        for _, entity in ipairs(contract.entities) do
            if DoesEntityExist(entity) and entity ~= contract.vehicle then
                DeleteEntity(entity)
                for i, spawned in ipairs(spawnedEntities) do
                    if spawned == entity then
                        table.remove(spawnedEntities, i)
                        break
                    end
                end
            end
        end
        contract.entities = nil
    end
end

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == cache.resource then
        cleanUpEntities()
    end
end)

local function spawnVehicle(contractId, coords)
    local contract = activeBoostingContracts[contractId]
    local vehicleModel = Utils.randomFromTable(contract.class.cars)
    local vehicle = Utils.createVehicle(vehicleModel, coords, "automobile")
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local plate = nil
    
    contract.vehicle = vehicle
    
    CreateThread(function()
        repeat
            plate = GetVehicleNumberPlateText(vehicle)
            Wait(200)
        until #plate > 0
        
        TriggerClientEvent("lunar_contracts:boosting:addVehicle", -1, contractId, netId, plate)
        
        Entity(vehicle).state:set("boosting:lockVehicle", true, true)
        table.insert(spawnedEntities, vehicle)
        
        if not contract.entities then
            contract.entities = {}
        end
        table.insert(contract.entities, vehicle)
        
        if contract.class.style == "keyfob" then
            local location = boostingConfig.spawnLocations.keyfob[contract.locationIndex]
            contract.signal = Utils.randomFromTable(location.signal)
        end
    end)
end

lib.callback.register("lunar_contracts:boosting:getSignal", function(playerId, contractId)
    local contract = activeBoostingContracts[contractId]
    
    if not contract.dogSpawned and boostingConfig.dog.enabled then
        local dogLocation = Utils.randomFromTable(boostingConfig.spawnLocations.keyfob[contract.locationIndex].dog)
        local dogModel = Utils.randomFromTable(boostingConfig.dog.models)
        local dog = CreatePed(1, dogModel, dogLocation.x, dogLocation.y, dogLocation.z, dogLocation.w, true, true)
        
        contract.dogSpawned = true
        Entity(dog).state:set("boosting:initDog", true, true)
        table.insert(spawnedEntities, dog)
        
        if not contract.entities then
            contract.entities = {}
        end
        table.insert(contract.entities, dog)
    end
    
    return contract.signal
end)

SetInterval(function()
    if Utils.getTableSize(vehicleBlips) == 0 then return end
    
    for vehicle in pairs(vehicleBlips) do
        vehicleBlips[vehicle] = GetEntityCoords(vehicle)
    end
    
    TriggerClientEvent("lunar_contracts:boosting:syncVehicleBlips", -1, vehicleBlips)
end, boostingConfig.dispatch.vehicleBlip.updateInterval)

RegisterNetEvent("lunar_contracts:boosting:signalHacked")
AddEventHandler("lunar_contracts:boosting:signalHacked", function(contractId)
    local sourcePlayer = source
    local contract = activeBoostingContracts[contractId]
    
    if not contract.signal then return end
    
    if Utils.distanceCheck(sourcePlayer, contract.signal, 5.0) and IsPlayerInContract(sourcePlayer, contractId) then
        contract.canDeliver = true
        
        local vehicleState = Entity(contract.vehicle).state
        vehicleState:set("boosting:unlockVehicle", true, true)
        
        if contract.class.hasTracker and boostingConfig.dispatch.enabled then
            vehicleState:set("boosting:hasTracker", true, true)
            addTrackerBlip(contract.vehicle)
        end
        
        TriggerClientEvent("lunar_contracts:boosting:vehicleUnlocked", -1, contractId, contract.deliveryIndex, contract.class.hasTracker)
    end
end)

RegisterNetEvent("lunar_contracts:boosting:lockpicked")
AddEventHandler("lunar_contracts:boosting:lockpicked", function(contractId)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = activeBoostingContracts[contractId]
    
    if not player or contract.signal then return end
    
    if Utils.distanceCheck(sourcePlayer, GetEntityCoords(contract.vehicle), 5.0) and IsPlayerInContract(sourcePlayer, contractId) then
        local requiredLockpickItem = boostingConfig.lockpickItem and boostingConfig.lockpickItem.name
        if requiredLockpickItem and not player:hasItem(requiredLockpickItem) then
            return
        end
        
        contract.canDeliver = true
        
        local vehicleState = Entity(contract.vehicle).state
        vehicleState:set("boosting:unlockVehicle", true, true)
        
        if requiredLockpickItem and boostingConfig.lockpickItem.removeAfterUse then
            player:removeItem(requiredLockpickItem, 1)
        end
        
        if contract.class.hasTracker and boostingConfig.dispatch.enabled then
            vehicleState:set("boosting:hasTracker", true, true)
            addTrackerBlip(contract.vehicle)
        end
        
        TriggerClientEvent("lunar_contracts:boosting:vehicleUnlocked", -1, contractId, contract.deliveryIndex, contract.class.hasTracker)
    end
end)

local function removeTracker(sourcePlayer, contractId)
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = activeBoostingContracts[contractId]
    
    if not player or not contract then return end
    
    local driver = GetPedInVehicleSeat(contract.vehicle, 0)
    if driver ~= GetPlayerPed(sourcePlayer) then return end
    
    if not IsPlayerInContract(sourcePlayer, contractId) then return end
    
    local requiredTrackerItem = boostingConfig.removeTrackerItem and boostingConfig.removeTrackerItem.name
    if requiredTrackerItem and not player:hasItem(requiredTrackerItem) then
        return
    end
    
    if requiredTrackerItem and boostingConfig.removeTrackerItem.removeAfterUse then
        player:removeItem(requiredTrackerItem, 1)
    end
    
    local vehicleState = Entity(contract.vehicle).state
    if vehicleState["boosting:hasTracker"] then
        vehicleState:set("boosting:hasTracker", nil, true)
        removeTrackerBlip(contract.vehicle)
    end
end

RegisterNetEvent("lunar_contracts:boosting:removeTracker")
AddEventHandler("lunar_contracts:boosting:removeTracker", function(contractId)
    removeTracker(source, contractId)
end)

RegisterNetEvent("lunar_contracts:cargo:removeTracker")
AddEventHandler("lunar_contracts:cargo:removeTracker", function(contractId)
    removeTracker(source, contractId)
end)

RegisterNetEvent("lunar_contracts:boosting:deliverVehicle")
AddEventHandler("lunar_contracts:boosting:deliverVehicle", function(contractId)
    local sourcePlayer = source
    local contract = activeBoostingContracts[contractId]
    local deliveryLocation = boostingConfig.deliveryLocations[contract.deliveryIndex]
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not contract or not player then return end
    if not DoesEntityExist(contract.vehicle) then return end
    if Entity(contract.vehicle).state["boosting:hasTracker"] then return end
    if not contract.canDeliver then return end
    
    if Utils.distanceCheck(sourcePlayer, deliveryLocation, 12.0) then
        local driver = GetPedInVehicleSeat(contract.vehicle, -1)
        if driver == GetPlayerPed(sourcePlayer) and IsPlayerInContract(sourcePlayer, contractId) then
            local vehicle = contract.vehicle
            
            contract.vehicleDeleted[vehicle] = true
            
            TriggerClientEvent("lunar_contracts:boosting:vehicleDelivered", -1, contractId, NetworkGetNetworkIdFromEntity(vehicle))
            
            FinishContract(contractId)
            DeleteContract(contractId)
            removeTrackerBlip(vehicle)
            activeBoostingContracts[contractId] = nil
            
            local reward = contract.class.reward
            local moneyAmount = type(reward.money) == "number" and reward.money or math.random(reward.money.min, reward.money.max)
            
            player:addAccountMoney(boostingConfig.rewardAccount, moneyAmount)
            
            SetTimeout(15000, function()
                TriggerClientEvent("lunar_contracts:boosting:reset", -1, contractId)
            end)
            
            SetTimeout(35000, function()
                contract.vehicleDeleted[vehicle] = nil
                if DoesEntityExist(vehicle) then
                    DeleteEntity(vehicle)
                end
            end)
        end
    end
end)

RegisterNetEvent("lunar_contracts:boosting:spawnVehicle")
AddEventHandler("lunar_contracts:boosting:spawnVehicle", function(contractId)
    local sourcePlayer = source
    local contract = activeBoostingContracts[contractId]
    
    if not contract or contract.vehicle then return end
    if not IsPlayerInContract(sourcePlayer, contractId) then return end
    
    contract.vehicle = nil
    
    local locationIndex = contract.locationIndex
    local spawnCoords = nil
    
    if contract.class.style == "lockpick" then
        spawnCoords = boostingConfig.spawnLocations.lockpick[locationIndex]
    end
    
    if not spawnCoords then
        spawnCoords = boostingConfig.spawnLocations.keyfob[locationIndex].coords
    end
    
    spawnVehicle(contractId, spawnCoords)
end)

local function countActiveContractsByStyle(style)
    local count = 0
    for _, contract in pairs(activeBoostingContracts) do
        if contract.class.style == style then
            count = count + 1
        end
    end
    return count
end

local function isLocationInUse(locationIndex, style)
    for _, contract in pairs(activeBoostingContracts) do
        if contract.locationIndex == locationIndex and contract.class.style == style then
            return true
        end
    end
    return false
end

local function selectRandomClass()
    local availableClasses = {}
    local totalChance = 0
    
    for _, class in ipairs(boostingConfig.classes) do
        local activeCount = countActiveContractsByStyle(class.style)
        local maxLocations = #boostingConfig.spawnLocations[class.style]
        
        if activeCount < maxLocations then
            if not class.settings or not class.settings.disabled then
                table.insert(availableClasses, class)
                totalChance = totalChance + class.chance
            end
        end
    end
    
    local randomValue = math.random(math.floor(totalChance))
    local cumulativeChance = 0
    
    for _, class in ipairs(availableClasses) do
        cumulativeChance = cumulativeChance + class.chance
        if randomValue <= cumulativeChance then
            return class
        end
    end
end

local function getRequiredToolsText(class)
    local tools = {}
    
    if class.style == "keyfob" then
        table.insert(tools, locale("signal_booster"))
    else
        local requiredLockpickItem = boostingConfig.lockpickItem and boostingConfig.lockpickItem.name
        if requiredLockpickItem then
            table.insert(tools, Utils.getItemLabel(requiredLockpickItem))
        end
    end
    
    local requiredTrackerItem = boostingConfig.removeTrackerItem and boostingConfig.removeTrackerItem.name
    if requiredTrackerItem and class.hasTracker then
        table.insert(tools, Utils.getItemLabel(requiredTrackerItem))
    end
    
    if #tools == 0 then
        return locale("no_tools")
    end
    
    return table.concat(tools, ", ")
end

local function getClass(className)
    local selectedClass = nil
    
    if className then
        for _, class in ipairs(boostingConfig.classes) do
            if class.label == className then
                selectedClass = class
                break
            end
        end
    else
        selectedClass = selectRandomClass()
    end
    
    return selectedClass
end

local function createContract(contractId, className)
    local contractClass = getClass(className)
    
    local availableLocations = {}
    for i = 1, #boostingConfig.spawnLocations[contractClass.style] do
        if not isLocationInUse(i, contractClass.style) then
            table.insert(availableLocations, i)
        end
    end
    
    local locationIndex = Utils.randomFromTable(availableLocations)
    local deliveryIndex = math.random(#boostingConfig.deliveryLocations)
    
    activeBoostingContracts[contractId] = {
        locationIndex = locationIndex,
        deliveryIndex = deliveryIndex,
        class = contractClass,
        entities = {},
        vehicleDeleted = {}
    }
    
    return contractClass
end

Missions.boosting = {}

function Missions.boosting.canBeGenerated(className)
    if className then
        local contractClass = getClass(className)
        local activeCount = countActiveContractsByStyle(contractClass.style)
        local maxLocations = #boostingConfig.spawnLocations[contractClass.style]
        return activeCount < maxLocations
    end
    
    local totalActive = Utils.getTableSize(activeBoostingContracts)
    local totalLocations = #boostingConfig.spawnLocations.keyfob + #boostingConfig.spawnLocations.lockpick
    return totalActive < totalLocations
end

function Missions.boosting.generated(contractId, className)
    local contractClass = createContract(contractId, className)
    
    local metadata = {
        {
            left = locale("boosting_class"),
            right = contractClass.label
        },
        {
            left = locale("required_tools"),
            right = getRequiredToolsText(contractClass)
        }
    }
    
    return contractClass.image, metadata
end

function Missions.boosting.deleted(contractId)
    cleanUpEntities(contractId)
    activeBoostingContracts[contractId] = nil
end

function Missions.boosting.cancelled(contractId)
    cleanUpEntities(contractId)
    TriggerClientEvent("lunar_contracts:boosting:reset", -1, contractId)
    HideContractObjective(contractId)
end

function Missions.boosting.start(contractId, data)
    local contract = activeBoostingContracts[contractId]
    local locationIndex = contract.locationIndex
    local spawnCoords = nil
    
    if contract.class.style == "lockpick" then
        spawnCoords = boostingConfig.spawnLocations.lockpick[locationIndex]
    end
    
    if not spawnCoords then
        spawnCoords = boostingConfig.spawnLocations.keyfob[locationIndex].coords
    end
    
    local randomOffset = vector3(
        spawnCoords.x + (math.random(boostingConfig.approximateRadius / 4, boostingConfig.approximateRadius / 2) * (math.random(0, 1) == 1 and 1 or -1)),
        spawnCoords.y + (math.random(boostingConfig.approximateRadius / 4, boostingConfig.approximateRadius / 2) * (math.random(0, 1) == 1 and 1 or -1)),
        spawnCoords.z
    )
    
    TriggerClientEvent("lunar_contracts:boosting:started", -1, data.members, contractId, contract.deliveryIndex, contract.class.style, spawnCoords, randomOffset)
    TriggerEvent("lunar_contracts:boosting:announceStarted", contractId, data.members, contract.locationIndex)
end

function Missions.boosting.getPrice(contractId)
    return activeBoostingContracts[contractId].class.price
end

function Missions.boosting.getRequiredExperience(contractId)
    return activeBoostingContracts[contractId].class.requiredExperience
end

function Missions.boosting.getReward(contractId)
    return activeBoostingContracts[contractId].class.reward
end

function Missions.boosting.getSaveData(contractId)
    if not activeBoostingContracts then
        error("Can't fetch save data from a boosting contract.")
    end
    
    return {
        contractIndex = contractId,
        classLabel = activeBoostingContracts[contractId].class.label
    }
end

function Missions.boosting.loadSaveData(data)
    createContract(data.contractIndex, data.classLabel)
end

function Missions.boosting.getCancelPoint(contractId)
    return nil
end

function Missions.boosting.getSettings(contractId)
    return getContractSettings(contractId)
end

function Missions.boosting.getClassSettings(className)
    return getClassSettings(className)
end

if not boostingConfig.settings.disabled and GetGameBuildNumber() == 3258 then
    SetInterval(function()
        warn("Gamebuild 3258 is broken and causes issues for some natives. Downgrade to 3095 or disable boosting.")
    end, 10000)
end
