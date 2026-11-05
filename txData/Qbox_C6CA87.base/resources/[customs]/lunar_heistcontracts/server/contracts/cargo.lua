local cargoConfig = Config.contracts.cargo

local activeCargoContracts = {}
local containerModels = {
    [-1064812128] = "S8B5",
    [-773987253] = "S91F",
    [-1489531137] = "9C0B",
    [-965292667] = "9J3B",
    [-788536681] = "B09W",
    [-1701710420] = "CB06",
    [-1266013780] = "8E7T",
    [2030482070] = "S92H"
}

local function getCargoLocation(locationIndex)
    if not cargoConfig.locations or not locationIndex then return nil end
    
    local location = cargoConfig.locations[locationIndex]
    if not location or not location.containers or #location.containers == 0 then
        return nil
    end
    
    return location
end

local function getAvailableCargoLocations()
    local availableLocations = {}
    if not cargoConfig.locations then return availableLocations end
    
    for i = 1, #cargoConfig.locations do
        if not activeCargoContracts[i] and getCargoLocation(i) then
            table.insert(availableLocations, i)
        end
    end
    
    return availableLocations
end

local function spawnContainers(locationIndex)
    local location = cargoConfig.locations[locationIndex]
    local containerCoords = location.containers
    local contract = activeCargoContracts[locationIndex]
    
    local containerNetIds = {}
    local lootPedNetIds = {}
    
    for i, coords in ipairs(containerCoords) do
        local container = CreateObjectNoOffset(contract.containers[i], coords.x, coords.y, coords.z - 1.0, true, true, false)
        SetEntityHeading(container, coords.w)
        FreezeEntityPosition(container, true)
        table.insert(contract.entities, container)
        table.insert(containerNetIds, NetworkGetNetworkIdFromEntity(container))
        
        local lootPedCoords = Utils.offsetCoords(coords, 0.0, -1.825, 0.2)
        local lootPed = CreateObjectNoOffset(2009935917, lootPedCoords.x, lootPedCoords.y, lootPedCoords.z, true, true, false)
        SetEntityHeading(lootPed, lootPedCoords.w)
        FreezeEntityPosition(lootPed, true)
        table.insert(contract.entities, lootPed)
        table.insert(lootPedNetIds, NetworkGetNetworkIdFromEntity(lootPed))
    end
    
    TriggerClientEvent("lunar_contracts:cargo:spawned", -1, locationIndex, containerNetIds, lootPedNetIds)
end

local function spawnGuards(locationIndex)
    if not cargoConfig.guards.enabled then return end
    
    local location = cargoConfig.locations[locationIndex]
    local guardCoords = location.guards
    local contract = activeCargoContracts[locationIndex]
    
    local guardNetIds = {}
    
    for i, coords in ipairs(guardCoords) do
        local weapon = Utils.randomFromTable(cargoConfig.guards.weapons)
        local guard = CreatePed(4, cargoConfig.guards.model, coords.x, coords.y, coords.z, coords.w, true, true)
        
        CreateThread(function()
            while DoesEntityExist(guard) do
                local currentWeapon = GetSelectedPedWeapon(guard)
                if currentWeapon ~= weapon.name then
                    GiveWeaponToPed(guard, weapon.name, 500, true, true)
                end
                
                if GetEntityHealth(guard) == 0 then
                    local currentWeaponCheck = GetSelectedPedWeapon(guard)
                    if currentWeaponCheck ~= 0 and not contract.reported and cargoConfig.dispatch.enabled then
                        contract.reported = true
                        Dispatch.call(cargoConfig.locations[locationIndex].coords, {
                            Code = cargoConfig.dispatch.code,
                            Title = cargoConfig.dispatch.title,
                            Message = cargoConfig.dispatch.message
                        })
                    end
                end
                
                Wait(2000)
            end
        end)
        
        SetPedArmour(guard, 100)
        SetPedRandomComponentVariation(guard, 0)
        
        local netId = NetworkGetNetworkIdFromEntity(guard)
        guardNetIds[i] = netId
        
        contract.guards[i] = {
            netId = netId,
            weapon = weapon
        }
        
        table.insert(contract.entities, guard)
    end
    
    TriggerClientEvent("lunar_contracts:cargo:handleGuardsLogic", -1, locationIndex, guardNetIds)
end

RegisterNetEvent("lunar_contracts:cargo:lootGuard")
AddEventHandler("lunar_contracts:cargo:lootGuard", function(locationIndex, guardNetId)
    local sourcePlayer = source
    local contract = activeCargoContracts[locationIndex]
    local player = Framework.getPlayerFromId(sourcePlayer)
    local guard = NetworkGetEntityFromNetworkId(guardNetId)
    
    if not contract or not player then return end
    if not DoesEntityExist(guard) then return end
    if not cargoConfig.guards.looting.enabled then return end
    
    if not Utils.distanceCheck(sourcePlayer, GetEntityCoords(guard), 5.0) then return end
    
    for i, guardData in pairs(contract.guards) do
        if guardData.netId == guardNetId then
            if guardData.looted then return end
            
            local ammoAmount = math.random(guardData.weapon.ammo.min, guardData.weapon.ammo.max)
            
            if not player:canCarryItem(guardData.weapon.name, 1) or not player:canCarryItem(guardData.weapon.ammo.name, ammoAmount) then
                LR.notify(sourcePlayer, locale("inventory_full"), "error")
                return
            end
            
            contract.guards[i].looted = true
            
            if player:addItem(guardData.weapon.name, 1) then
                player:addItem(guardData.weapon.ammo.name, ammoAmount)
                TriggerClientEvent("lunar_contracts:cargo:guardLooted", -1, guardNetId)
                LogItem(sourcePlayer, string.format([[
Looted an Ammu Containers guard.
Weapon: %s]], guardData.weapon.name:upper()))
            else
                contract.guards[i].looted = false
                LR.notify(sourcePlayer, locale("inventory_full"), "error")
            end
            return
        end
    end
end)

local function cleanUpEntities(locationIndex)
    local contract = activeCargoContracts[locationIndex]
    if not contract then return end
    
    for _, entity in ipairs(contract.entities) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
end

local function cleanupContract(locationIndex, contractIndex)
    local contract = activeCargoContracts[locationIndex]
    if not contract then return end
    
    local guardNetIds = {}
    for i, guard in ipairs(contract.guards) do
        guardNetIds[i] = guard.netId
    end
    
    TriggerClientEvent("lunar_contracts:cargo:stop", -1, locationIndex, guardNetIds)
    cleanUpEntities(locationIndex)
    HideContractObjective(contractIndex)
    DeleteContract(contractIndex)
    activeCargoContracts[locationIndex] = nil
end

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == cache.resource then
        for locationIndex in pairs(activeCargoContracts) do
            cleanUpEntities(locationIndex)
        end
    end
end)

local syncingPlayers = {}

RegisterNetEvent("lunar_contracts:cargo:syncContainer")
AddEventHandler("lunar_contracts:cargo:syncContainer", function(locationIndex, containerIndex, lootPedNetIds)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    
    local contract = activeCargoContracts[locationIndex]
    if not contract then return end
    
    syncingPlayers[sourcePlayer] = true
    
    local containerCoords = cargoConfig.locations[locationIndex].containers[containerIndex]
    
    Wait(8250)
    
    if not syncingPlayers[sourcePlayer] then return end
    
    TriggerClientEvent("lunar_contracts:cargo:syncContainer", -1, locationIndex, containerIndex, containerCoords, contract.containers[containerIndex])
    
    local lootData = contract.loot[containerIndex]
    if lootData and not lootData.spawned then
        local lootCoords = Utils.offsetCoords(containerCoords, 0.0, 0.5, -0.4)
        TriggerClientEvent("lunar_contracts:cargo:spawnLoot", -1, locationIndex, containerIndex, lootCoords)
        lootData.spawned = true
    end
    
    Wait(2000)
    
    for _, netId in ipairs(lootPedNetIds) do
        local entity = NetworkGetEntityFromNetworkId(netId)
        local model = GetEntityModel(entity)
        local modelCode = containerModels[model]
        
        if not modelCode and model ~= 2009935917 then
            if DoesEntityExist(entity) then
                DeleteEntity(entity)
            end
        end
    end
end)

RegisterNetEvent("lunar_contracts:cargo:cancelSync")
AddEventHandler("lunar_contracts:cargo:cancelSync", function()
    local sourcePlayer = source
    if syncingPlayers[sourcePlayer] then
        syncingPlayers[sourcePlayer] = nil
    end
end)

RegisterNetEvent("lunar_contracts:cargo:takeLoot")
AddEventHandler("lunar_contracts:cargo:takeLoot", function(locationIndex, containerIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    
    local contract = activeCargoContracts[locationIndex]
    local lootCoords = Utils.offsetCoords(cargoConfig.locations[locationIndex].containers[containerIndex], 0.0, -1.9, 0.2)
    
    local lootData = contract.loot[containerIndex]
    if not lootData or lootData.busy then return end
    
    if not Utils.distanceCheck(sourcePlayer, lootCoords, 2.0) then return end
    
    local items = lootData.items
    if #items == 0 then return end
    
    lootData.busy = true
    
    local collectedItems = {}
    
    repeat
        local item = items[1]
        if player:addItem(item.name, item.count, item.metadata) then
            table.remove(items, 1)
            table.insert(collectedItems, string.format("%sx %s", item.count, Utils.getItemLabel(item.name)))
        else
            LR.notify(sourcePlayer, locale("inventory_full"), "error")
            break
        end
    until #items == 0
    
    lootData.busy = false
    
    if #collectedItems > 0 then
        LogItem(sourcePlayer, string.format([[
Took loot from Ammu Containers.
Items: %s]], table.concat(collectedItems, ", ")))
    end
    
    if #items > 0 then return end
    
    TriggerClientEvent("lunar_contracts:cargo:disableLoot", -1, locationIndex, containerIndex)
    
    local allLooted = true
    for _, loot in pairs(contract.loot) do
        if #loot.items > 0 then
            allLooted = false
            break
        end
    end
    
    if allLooted then
        ShowContractObjective(contract.contractIndex, locale("cargo_title"), locale("obj_contract_completed"))
        FinishContract(contract.contractIndex)
        
        SetTimeout(60000, function()
            HideContractObjective(contract.contractIndex)
        end)
    end
end)

local function getRequiredToolsText()
    if cargoConfig.requiredItem then
        return Utils.getItemLabel(cargoConfig.requiredItem)
    end
    return locale("no_tools")
end

local function generateLoot(contractIndex, locationIndex)
    local location = getCargoLocation(locationIndex)
    if not location then
        error(("Invalid cargo location index: %s"):format(tostring(locationIndex)))
    end
    
    local lootCount = math.min(math.random(cargoConfig.loot.count.min, cargoConfig.loot.count.max), #location.containers)
    if lootCount <= 0 then
        error(("Cargo location %s has no lootable containers."):format(tostring(locationIndex)))
    end
    local lootType = Utils.randomFromTable(cargoConfig.loot.types)
    
    local loot = {}
    
    repeat
        local containerIndex = math.random(#location.containers)
        
        if not loot[containerIndex] then
            local function hasItem(looted, itemName)
                for _, item in ipairs(looted) do
                    if item.name == itemName then
                        return true
                    end
                end
                return false
            end
            
            local containerLoot = {}
            local itemCount = math.min(lootType.itemCount, #lootType.items)
            
            for _ = 1, itemCount do
                local itemData
                repeat
                    itemData = Utils.randomFromTable(lootType.items)
                until not hasItem(containerLoot, itemData.name)
                
                local itemCountValue = type(itemData.count) == "number" and itemData.count or math.random(itemData.count.min, itemData.count.max)
                
                table.insert(containerLoot, {
                    name = itemData.name,
                    count = itemCountValue,
                    metadata = itemData.metadata
                })
            end
            
            loot[containerIndex] = {
                spawned = false,
                busy = false,
                items = containerLoot
            }
        end
        
    until Utils.getTableSize(loot) == lootCount
    
    local containerModelsList = {}
    for model in pairs(containerModels) do
        table.insert(containerModelsList, model)
    end
    
    local containerCount = math.min(#containerModelsList, #location.containers)
    local containers = {}
    
    for i = 1, containerCount do
        local randomIndex = math.random(#containerModelsList)
        containers[i] = containerModelsList[randomIndex]
        table.remove(containerModelsList, randomIndex)
    end
    
    activeCargoContracts[locationIndex] = {
        contractIndex = contractIndex,
        containers = containers,
        loot = loot,
        guards = {},
        entities = {}
    }
end

Missions.cargo = {}

function Missions.cargo.canBeGenerated()
    return #getAvailableCargoLocations() > 0
end

function Missions.cargo.generated(contractId)
    local availableLocations = getAvailableCargoLocations()
    if #availableLocations == 0 then
        error("No available cargo locations with containers.")
    end
    
    local locationIndex = Utils.randomFromTable(availableLocations)
    local location = getCargoLocation(locationIndex)
    generateLoot(contractId, locationIndex)
    
    local metadata = {
        {
            left = locale("reward"),
            right = locale("reward_cargo")
        },
        {
            left = locale("required_tools"),
            right = getRequiredToolsText()
        }
    }
    
    return location.image, metadata
end

function Missions.cargo.deleted(contractId)
    for locationIndex, contract in pairs(activeCargoContracts) do
        if contract.contractIndex == contractId then
            cleanupContract(locationIndex, contractId)
            break
        end
    end
end

function Missions.cargo.cancelled(contractId)
    for locationIndex, contract in pairs(activeCargoContracts) do
        if contract.contractIndex == contractId then
            HideContractObjective(contractId)
            break
        end
    end
end

function Missions.cargo.start(contractId, data)
    for locationIndex, contract in pairs(activeCargoContracts) do
        if contract.contractIndex == contractId then
            local members = data.members
            local containerCodes = {}
            
            for containerIndex, containerModel in pairs(contract.containers) do
                table.insert(containerCodes, containerModels[containerModel])
            end
            
            TriggerClientEvent("lunar_contracts:cargo:started", -1, contractId, locationIndex, containerCodes)
            TriggerEvent("lunar_contracts:cargo:announceStarted", contractId, contractId, locationIndex)
            
            spawnContainers(locationIndex)
            spawnGuards(locationIndex)
            
            SetTimeout(cargoConfig.duration * 60000, function()
                cleanupContract(locationIndex, contractId)
            end)
            
            break
        end
    end
end

function Missions.cargo.getSaveData(contractId)
    if not activeCargoContracts then
        error("Can't fetch save data from a cargo contract.")
    end
    
    for locationIndex, contract in pairs(activeCargoContracts) do
        if contract.contractIndex == contractId then
            return {
                contractIndex = contractId,
                locationIndex = locationIndex
            }
        end
    end
    
    return {}
end

function Missions.cargo.loadSaveData(data)
    if not data or not data.contractIndex then
        print("^1[lunar_heistcontracts] Failed to load cargo contract: missing save data.^0")
        return
    end
    
    local locationIndex = data.locationIndex
    if type(locationIndex) ~= "number" then
        locationIndex = tonumber(locationIndex)
    end
    
    if not getCargoLocation(locationIndex) or activeCargoContracts[locationIndex] then
        local availableLocations = getAvailableCargoLocations()
        locationIndex = #availableLocations > 0 and Utils.randomFromTable(availableLocations) or nil
    end
    
    if not locationIndex then
        print(("^1[lunar_heistcontracts] Failed to load cargo contract %s: no valid cargo locations available.^0"):format(data.contractIndex))
        return
    end
    
    generateLoot(data.contractIndex, locationIndex)
end

function Missions.cargo.getCancelPoint(contractId)
    for locationIndex, contract in pairs(activeCargoContracts) do
        if contract.contractIndex == contractId then
            local location = getCargoLocation(locationIndex)
            return location and location.coords
        end
    end
end
