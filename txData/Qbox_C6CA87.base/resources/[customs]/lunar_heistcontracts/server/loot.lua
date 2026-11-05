local nextContractId = 0
local contracts = {}
local activeTaking = {}

-- Loot type models
local lootModels = {
    cash = {
        pile = 1228147776,
        trolley = 412463629
    },
    gold = {
        pile = -180074230,
        trolley = -735318549
    },
    diamonds = {
        trolley = -805325757
    },
    coke = {
        pile = -2143906120
    },
    weed = {
        pile = 822904642
    }
}

Loot = {}
Loot.__index = Loot

-- Helper to delete all entities for a contract
local function deleteContractEntities(contractId)
    local contract = contracts[contractId]
    if not contract or not contract.locations then return end
    
    for _, location in ipairs(contract.locations) do
        if location.entity and DoesEntityExist(location.entity) then
            DeleteEntity(location.entity)
        end
    end
end

-- Clean up on resource stop
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == cache.resource then
        for contractId, _ in pairs(contracts) do
            deleteContractEntities(contractId)
        end
    end
end)

-- Serialize loot data for client
local function serializeLootData(contract)
    local serialized = {}
    for i, location in ipairs(contract.locations) do
        serialized[i] = {
            type = location.type,
            lootType = location.lootType,
            coords = location.coords,
            phase = location.phase,
            networked = location.entity ~= nil,
            requires = location.requires,
            unlocked = location.unlocked
        }
    end
    return serialized
end

-- Get loot data for client
lib.callback.register("lunar_contracts:getLoot", function(contractId)
    if not contracts[contractId] then return end
    
    local result = {}
    for id, contract in pairs(contracts) do
        result[id] = serializeLootData(contract)
    end
    return result
end)

-- Notify clients of new loot
local function notifyNewLoot(contract)
    TriggerClientEvent("lunar_contracts:loot:new", -1, contract.index, serializeLootData(contract))
end

-- Create new loot contract
function Loot.new(config, bucketId)
    nextContractId = nextContractId + 1
    local locations = {}
    
    for _, location in ipairs(config.locations) do
        local lootType = location.forceLootType or (type(location.alreadySpawned) == "string" and location.alreadySpawned or nil)
        local entity = nil
        
        if not location.alreadySpawned and not lootType then
            local random = math.random(1, 100)
            
            if location.type == "trolley" and config.diamondsChance and random <= config.diamondsChance then
                lootType = "diamonds"
            else
                local diamondsChance = config.diamondsChance or 0
                local goldChance = config.goldChance
                
                if random <= diamondsChance + goldChance then
                    lootType = "gold"
                else
                    lootType = "cash"
                end
            end
        end
        
        if not location.alreadySpawned then
            local model = lootModels[lootType][location.type]
            local zOffset = (location.type == "trolley") and -0.5 or 0.0
            
            entity = CreateObjectNoOffset(
                model,
                location.coords.x,
                location.coords.y,
                location.coords.z + zOffset,
                true, true, false
            )
            
            if bucketId then
                SetEntityRoutingBucket(entity, bucketId)
            end
            
            -- Set entity state for rotation
            Entity(entity).state:set("loot:rotation", location.coords.w, true)
        end
        
        local reward = config.rewards[lootType]
        local countPerTake = math.floor(reward.count[location.type] / Config.lootingAnimations[lootType][location.type].count)
        
        table.insert(locations, {
            type = location.type,
            lootType = lootType,
            reward = {
                item = reward.item,
                account = reward.account,
                countPerTake = math.max(1, countPerTake)
            },
            coords = location.coords,
            animation = Config.lootingAnimations[lootType][location.type],
            entity = entity,
            phase = 0,
            balance = Config.lootingAnimations[lootType][location.type].count,
            requires = location.requires,
            unlocked = location.requires == nil
        })
    end
    
    local contract = {
        index = nextContractId,
        locations = locations
    }
    
    contracts[nextContractId] = contract
    notifyNewLoot(contract)
    
    return setmetatable(contract, Loot)
end

-- Remove loot contract
function Loot.remove(contract)
    TriggerClientEvent("lunar_contracts:loot:remove", -1, contract.index)
    deleteContractEntities(contract.index)
    contracts[contract.index] = nil
end

-- Set unlocked state
function Loot.setUnlocked(contract, requirement, unlocked)
    for _, location in ipairs(contract.locations) do
        if location.requires == requirement then
            location.unlocked = unlocked
        end
    end
    
    TriggerClientEvent("lunar_contracts:loot:syncUnlocked", -1, contract.index, requirement, unlocked)
end

-- Get unlocked state
function Loot.getUnlocked(contract, requirement)
    for _, location in ipairs(contract.locations) do
        if location.requires == requirement then
            return location.unlocked
        end
    end
    return false
end

-- Start taking loot
lib.callback.register("lunar_contracts:loot:startTaking", function(source, contractId, locationIndex)
    local player = Framework.getPlayerFromId(source)
    local contract = contracts[contractId]
    local location = contract and contract.locations[locationIndex]
    
    if not (player and contract and location) then
        return false, 0, locale("player_already_taking")
    end
    
    if location.taking or location.phase >= 0.99 or location.balance == 0 then
        return false, 0, locale("player_already_taking")
    end
    
    if not Utils.distanceCheck(source, location.coords, 1.5) then
        return false, 0, locale("player_already_taking")
    end
    
    -- Check inventory space for items
    if location.reward.item then
        if not player:canCarryItem(location.reward.item, location.reward.countPerTake) then
            return false, 0, locale("inventory_full")
        end
    end
    
    location.taking = { source = source }
    
    SetTimeout(location.animation.intro, function()
        if location.taking and location.taking.source == source then
            location.taking.interval = SetInterval(function()
                if not (location.taking and location.taking.source == source) then return end
                
                if location.balance <= 0 then
                    ClearInterval(location.taking.interval)
                    location.taking = nil
                    location.phase = 0.99
                    
                    if location.entity and location.type == "pile" then
                        DeleteEntity(location.entity)
                    end
                    
                    TriggerClientEvent("lunar_contracts:loot:removeLocation", -1, contractId, locationIndex)
                    return
                end
                
                -- Give reward
                if location.reward.item then
                    if not player:addItem(location.reward.item, location.reward.countPerTake) then
                        LR.notify(source, locale("inventory_full"), "error")
                        TriggerClientEvent("lunar_contracts:loot:forceStop", source)
                        Wait(location.animation.interval * 2)
                        return
                    end
                    
                    LogItem(source, string.format([[
Picked up loot from a trolley/pile.
Item name: %s
Count: %s]], Utils.getItemLabel(location.reward.item), location.reward.countPerTake))
                elseif location.reward.account then
                    player:addAccountMoney(location.reward.account, location.reward.countPerTake)
                    
                    LogItem(source, string.format([[
Picked up loot from a trolley/pile.
Account name: %s
Count: %s]], location.reward.account, location.reward.countPerTake))
                end
                
                location.balance = location.balance - 1
            end, location.animation.interval)
        end
    end)
    
    return true, location.phase
end)

-- Stop taking loot
RegisterNetEvent("lunar_contracts:loot:stopTaking")
AddEventHandler("lunar_contracts:loot:stopTaking", function(contractId, locationIndex, progress)
    local source = source
    local contract = contracts[contractId]
    local location = contract and contract.locations[locationIndex]
    
    if not (location and location.taking and location.taking.source == source) then return end
    
    ClearInterval(location.taking.interval)
    location.phase = location.phase + progress
    location.taking = nil
    
    TriggerClientEvent("lunar_contracts:loot:setLocationPhase", -1, contractId, locationIndex, location.phase)
end)