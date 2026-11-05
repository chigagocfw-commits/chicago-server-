local fleecaConfig = Config.contracts.fleeca

local activeFleecaContracts = {}
local fleecaDoors = {}

for i = 1, #fleecaConfig.locations do
    local location = fleecaConfig.locations[i]
    
    fleecaDoors[i] = {
        entry = not fleecaConfig.doors.entry.disabled and RegisterDoorWithModel(
            Utils.offsetCoords(location, table.unpack(fleecaConfig.doors.entry.offset)),
            fleecaConfig.doors.entry.model
        ),
        inside = RegisterDoorWithModel(
            Utils.offsetCoords(location, table.unpack(fleecaConfig.doors.inside.offset)),
            fleecaConfig.doors.inside.model
        )
    }
end

-- Initialize all doors to locked state on startup
CreateThread(function()
    Wait(1000)
    for i = 1, #fleecaConfig.locations do
        if fleecaDoors[i].entry then
            fleecaDoors[i].entry:set(true)
        end
        if fleecaDoors[i].inside then
            fleecaDoors[i].inside:set(true)
        end
    end
    if Config and Config.debug then print("[Fleeca] All fleeca doors locked on startup") end
end)

local function findContract(contractId)
    for locationIndex, contract in pairs(activeFleecaContracts) do
        if contract.contractIndex == contractId then
            return locationIndex, contract
        end
    end
end

local function createLoot(locationIndex)
    local contract = activeFleecaContracts[locationIndex]
    local lootLocations = {}
    
    for i, lootData in ipairs(fleecaConfig.loot.locations) do
        local locationCopy = table.clone(lootData)
        locationCopy.coords = Utils.offsetCoords(fleecaConfig.locations[locationIndex], lootData.coords.x, lootData.coords.y, lootData.coords.z, lootData.coords.w)
        lootLocations[i] = locationCopy
    end
    
    contract.loot = Loot.new({
        rewards = fleecaConfig.loot.rewards,
        goldChance = fleecaConfig.loot.goldChance,
        locations = lootLocations
    })
    
    contract.loot:setUnlocked("back", true)
end

RegisterNetEvent("lunar_contracts:fleeca:syncEffect")
AddEventHandler("lunar_contracts:fleeca:syncEffect", function(locationIndex, coords)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = activeFleecaContracts[locationIndex]
    
    if not player or not contract then return end
    if contract.triggeredEffect then return end
    
    if not IsPlayerInContract(sourcePlayer, contract.contractIndex) then return end
    
    if fleecaConfig.doors.entry.requiredItem and not player:hasItem(fleecaConfig.doors.entry.requiredItem) then
        return
    end
    
    contract.triggeredEffect = true
    
    TriggerClientEvent("lunar_contracts:fleeca:syncEffect", -1, locationIndex, coords)
    
    if fleecaConfig.doors.entry.requiredItem then
        player:removeItem(fleecaConfig.doors.entry.requiredItem, 1)
    end
    
    if fleecaConfig.dispatch.enabled then
        Dispatch.call(fleecaConfig.locations[locationIndex].xyz, {
            Code = fleecaConfig.dispatch.code,
            Title = fleecaConfig.dispatch.title,
            Message = fleecaConfig.dispatch.message
        })
    end
    
    Wait(10000)
    fleecaDoors[locationIndex].entry:set(false)
    
    ShowContractObjective(contract.contractIndex, locale("fleeca_title"), locale("obj_gain_access_to_vault"))
end)

RegisterNetEvent("lunar_contracts:fleeca:openVault")
AddEventHandler("lunar_contracts:fleeca:openVault", function(locationIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = activeFleecaContracts[locationIndex]
    
    if not player or not contract then return end
    if contract.vaultOpen then return end
    if not contract.triggeredEffect then return end
    
    if not fleecaConfig.doors.entry.disabled then
        return
    end
    
    if fleecaConfig.panels.requiredItem and not player:hasItem(fleecaConfig.panels.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, contract.contractIndex) then return end
    
    local vaultCoords = Utils.offsetCoords(fleecaConfig.locations[locationIndex], table.unpack(fleecaConfig.doors.vault.offset))
    if not Utils.distanceCheck(sourcePlayer, vaultCoords, 5.0) then return end
    
    if fleecaConfig.panels.requiredItem and fleecaConfig.panels.removeAfterUse then
        player:removeItem(fleecaConfig.panels.requiredItem)
    end
    
    if fleecaConfig.dispatch.enabled and fleecaConfig.doors.entry.disabled then
        Dispatch.call(fleecaConfig.locations[locationIndex].xyz, {
            Code = fleecaConfig.dispatch.code,
            Title = fleecaConfig.dispatch.title,
            Message = fleecaConfig.dispatch.message
        })
    end
    
    contract.vaultOpen = true
    createLoot(locationIndex)
    
    TriggerClientEvent("lunar_contracts:fleeca:openVault", -1, locationIndex)
    
    ShowContractObjective(contract.contractIndex, locale("fleeca_title"), locale("obj_contract_completed_loot"))
    
    SetTimeout(60000, function()
        HideContractObjective(contract.contractIndex)
    end)
    
    FinishContract(contract.contractIndex)
end)

RegisterNetEvent("lunar_contracts:fleeca:openInsideDoor")
AddEventHandler("lunar_contracts:fleeca:openInsideDoor", function(locationIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = activeFleecaContracts[locationIndex]
    local insideDoor = fleecaDoors[locationIndex].inside
    
    if not player or not contract then return end
    if not insideDoor.get() then return end
    
    if fleecaConfig.panels.requiredItem and not player:hasItem(fleecaConfig.panels.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, contract.contractIndex) then return end
    
    local insideCoords = Utils.offsetCoords(fleecaConfig.locations[locationIndex], table.unpack(fleecaConfig.doors.inside.offset))
    if not Utils.distanceCheck(sourcePlayer, insideCoords, 5.0) then return end
    
    if fleecaConfig.panels.requiredItem and fleecaConfig.panels.removeAfterUse then
        player:removeItem(fleecaConfig.panels.requiredItem)
    end
    
    insideDoor:set(false)
    
    contract.loot:setUnlocked(fleecaConfig.doors.inside.unlocks, true)
    
    TriggerClientEvent("lunar_contracts:fleeca:removeInsidePanel", -1, locationIndex)
end)

lib.callback.register("lunar_contracts:fleeca:canDrillDepositBox", function(playerId, locationIndex, boxIndex)
    local player = Framework.getPlayerFromId(playerId)
    local contract = activeFleecaContracts[locationIndex]
    local boxCoords = fleecaConfig.drilling.locations[boxIndex]
    local worldCoords = Utils.offsetCoords(fleecaConfig.locations[locationIndex], boxCoords.x, boxCoords.y, boxCoords.z, boxCoords.w)
    
    if not player then return false end
    if not contract then return false end
    if not contract.vaultOpen then return false end
    if not Utils.distanceCheck(playerId, worldCoords, 5.0) then return false end
    if contract.depositBoxes[boxIndex] then return false end
    
    for _, reward in ipairs(fleecaConfig.drilling.rewards) do
        if reward.item then
            local count = type(reward.count) == "number" and reward.count or reward.count.max
            if not player:canCarryItem(reward.item, count) then
                LR.notify(playerId, locale("inventory_full"), "error")
                return false
            end
        end
    end
    
    return true
end)

RegisterNetEvent("lunar_contracts:fleeca:drillDepositBox")
AddEventHandler("lunar_contracts:fleeca:drillDepositBox", function(locationIndex, boxIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = activeFleecaContracts[locationIndex]
    local boxCoords = fleecaConfig.drilling.locations[boxIndex]
    local worldCoords = Utils.offsetCoords(fleecaConfig.locations[locationIndex], boxCoords.x, boxCoords.y, boxCoords.z, boxCoords.w)
    
    if not player then return end
    if not contract then return end
    if not contract.vaultOpen then return end
    if not Utils.distanceCheck(sourcePlayer, worldCoords, 5.0) then return end
    if contract.depositBoxes[boxIndex] then return end
    
    local collectedItems = {}
    local failed = false
    
    for _, reward in ipairs(fleecaConfig.drilling.rewards) do
        local count = type(reward.count) == "number" and reward.count or math.random(reward.count.min, reward.count.max)
        
        if reward.chance then
            local randomChance = math.random(1, 100)
            if randomChance > reward.chance then
                goto continue
            end
        end
        
        if reward.item then
            if not player:addItem(reward.item, count, reward.metadata) then
                failed = true
                LR.notify(sourcePlayer, locale("inventory_full"), "error")
                break
            end
        elseif reward.account then
            player:addAccountMoney(reward.account, count)
        end
        
        table.insert(collectedItems, string.format("%sx %s", reward.item or reward.account, count))
        
        ::continue::
    end
    
    if not failed then
        contract.depositBoxes[boxIndex] = true
        TriggerClientEvent("lunar_contracts:fleeca:removeDepositBox", -1, locationIndex, boxIndex)
        LogItem(sourcePlayer, string.format([[
Drilled a Fleeca Bank deposit box.
Items: %s]], table.concat(collectedItems, ", ")))
    end
end)

local function resetDoors(locationIndex)
    local doors = fleecaDoors[locationIndex]
    if doors.entry then
        doors.entry:set(true)
    end
    doors.inside:set(true)
end

local function cleanup(locationIndex)
    local contract = activeFleecaContracts[locationIndex]
    if not contract then return end
    
    resetDoors(locationIndex)
    
    if contract.loot then
        contract.loot:remove()
    end
    
    TriggerClientEvent("lunar_contracts:fleeca:reset", -1, locationIndex)
    HideContractObjective(contract.contractIndex)
    DeleteContract(contract.contractIndex)
    
    activeFleecaContracts[locationIndex] = nil
end

local function startContract(locationIndex)
    resetDoors(locationIndex)
    
    local objectiveText = fleecaConfig.doors.entry.disabled
        and locale("obj_gain_access_to_vault")
        or locale("obj_unlock_vault_panel_room")
    
    ShowContractObjective(activeFleecaContracts[locationIndex].contractIndex, locale("fleeca_title"), objectiveText)
    
    SetTimeout(fleecaConfig.duration * 60000, function()
        cleanup(locationIndex)
    end)
end

local function getRequiredToolsText()
    local tools = {}
    local requiredItems = {
        not fleecaConfig.doors.entry.disabled and fleecaConfig.doors.entry.requiredItem,
        fleecaConfig.panels.requiredItem,
        fleecaConfig.drilling.requiredItem
    }
    
    local uniqueTools = {}
    for _, item in pairs(requiredItems) do
        if type(item) == "string" then
            local label = Utils.getItemLabel(item)
            if not lib.table.contains(uniqueTools, label) then
                table.insert(uniqueTools, label)
            end
        end
    end
    
    if #uniqueTools == 0 then
        return locale("no_tools")
    end
    
    return table.concat(uniqueTools, ", ")
end

local function createContract(contractId, locationIndex)
    local depositBoxes = {}
    for i = 1, #fleecaConfig.drilling.locations do
        depositBoxes[i] = false
    end
    
    activeFleecaContracts[locationIndex] = {
        contractIndex = contractId,
        triggeredEffect = false,
        vaultOpen = false,
        depositBoxes = depositBoxes
    }
end

Missions.fleeca = {}

function Missions.fleeca.canBeGenerated()
    return Utils.getTableSize(activeFleecaContracts) < #fleecaConfig.locations
end

function Missions.fleeca.generated(contractId)
    local locationIndex
    repeat
        locationIndex = math.random(#fleecaConfig.locations)
    until not activeFleecaContracts[locationIndex]
    
    createContract(contractId, locationIndex)
    
    local metadata = {
        {
            left = locale("reward"),
            right = locale("reward_fleeca")
        },
        {
            left = locale("required_tools"),
            right = getRequiredToolsText()
        }
    }
    
    return fleecaConfig.images[locationIndex], metadata
end

function Missions.fleeca.deleted(contractId)
    local locationIndex, contract = findContract(contractId)
    if contract then
        cleanup(locationIndex)
    end
end

function Missions.fleeca.cancelled(contractId)
    local locationIndex, contract = findContract(contractId)
    if contract then
        TriggerClientEvent("lunar_contracts:fleeca:reset", -1, locationIndex)
        HideContractObjective(contractId)
    end
end

function Missions.fleeca.start(contractId, data)
    local locationIndex, contract = findContract(contractId)
    if not contract then return end
    
    local members = data.members
    TriggerClientEvent("lunar_contracts:fleeca:started", -1, members, locationIndex)
    TriggerEvent("lunar_contracts:fleeca:announceStarted", contractId, members, locationIndex)
    
    startContract(locationIndex)
end

function Missions.fleeca.getSaveData(contractId)
    if not activeFleecaContracts then
        error("Can't fetch save data from a fleeca contract.")
    end
    
    local locationIndex, contract = findContract(contractId)
    if contract then
        return {
            contractIndex = contractId,
            locationIndex = locationIndex
        }
    end
    
    return {}
end

function Missions.fleeca.loadSaveData(data)
    createContract(data.contractIndex, data.locationIndex)
end

function Missions.fleeca.getCancelPoint(contractId)
    local locationIndex = findContract(contractId)
    return fleecaConfig.locations[locationIndex]
end
