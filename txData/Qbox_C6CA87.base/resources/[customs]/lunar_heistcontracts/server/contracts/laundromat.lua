local laundromatConfig = Config.contracts.laundromat

local activeLaundromatContract = nil
local officeDoor = RegisterDoor(laundromatConfig.office.door)

-- Initialize door to locked state on startup
CreateThread(function()
    Wait(1000)
    officeDoor.set(true)
    if Config and Config.debug then print("[Laundromat] Office door locked on startup") end
end)

RegisterNetEvent("lunar_contracts:laundromat:cutGeneratorPower")
AddEventHandler("lunar_contracts:laundromat:cutGeneratorPower", function()
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activeLaundromatContract then return end
    
    if laundromatConfig.generator.requiredItem and not player:hasItem(laundromatConfig.generator.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activeLaundromatContract.contractIndex) then return end
    
    if not Utils.distanceCheck(sourcePlayer, laundromatConfig.generator.coords, 5.0) then return end
    if activeLaundromatContract.powerDisabled then return end
    
    if laundromatConfig.generator.requiredItem and laundromatConfig.generator.removeAfterUse then
        player:removeItem(laundromatConfig.generator.requiredItem, 1)
    end
    
    activeLaundromatContract.powerDisabled = true
    
    TriggerClientEvent("lunar_contracts:laundromat:powerDisabled", -1)
    
    ShowContractObjective(activeLaundromatContract.contractIndex, locale("laundromat_title"), locale("obj_loot_laundry_hack_office"))
    
    if laundromatConfig.dispatch.enabled then
        Dispatch.call(laundromatConfig.alarm.coords, {
            Code = laundromatConfig.dispatch.code,
            Title = laundromatConfig.dispatch.title,
            Message = laundromatConfig.dispatch.message
        })
    end
end)

RegisterNetEvent("lunar_contracts:laundromat:takeLoot")
AddEventHandler("lunar_contracts:laundromat:takeLoot", function(lootIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not activeLaundromatContract or not player then return end
    if not activeLaundromatContract.loot[lootIndex] then return end
    
    if not IsPlayerInContract(sourcePlayer, activeLaundromatContract.contractIndex) then return end
    
    if not Utils.distanceCheck(sourcePlayer, laundromatConfig.loot.locations[lootIndex], 3.0) then return end
    
    local lootItem = Utils.randomFromTable(laundromatConfig.loot.items)
    local count = type(lootItem.count) == "number" and lootItem.count or math.random(lootItem.count.min, lootItem.count.max)
    
    if not player:canCarryItem(lootItem.name, count) then
        LR.notify(sourcePlayer, locale("inventory_full"), "error")
        return
    end
    
    if player:addItem(lootItem.name, count, lootItem.metadata) then
        activeLaundromatContract.loot[lootIndex] = false
        TriggerClientEvent("lunar_contracts:laundromat:removeLoot", -1, lootIndex)
        LogItem(sourcePlayer, string.format([[
Looted a washing machine inside the Laundromat.
Item: %s
Count: %s]], Utils.getItemLabel(lootItem.name), count))
    else
        LR.notify(sourcePlayer, locale("inventory_full"), "error")
    end
end)

RegisterNetEvent("lunar_contracts:laundromat:unlockOfficeDoor")
AddEventHandler("lunar_contracts:laundromat:unlockOfficeDoor", function()
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activeLaundromatContract then return end
    if not officeDoor.get() then return end
    
    if laundromatConfig.office.electricBox.requiredItem and not player:hasItem(laundromatConfig.office.electricBox.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activeLaundromatContract.contractIndex) then return end
    
    if not Utils.distanceCheck(sourcePlayer, laundromatConfig.office.electricBox.coords, 3.0) then return end
    
    if laundromatConfig.office.electricBox.requiredItem and laundromatConfig.office.electricBox.removeAfterUse then
        player:removeItem(laundromatConfig.office.electricBox.requiredItem, 1)
    end
    
    officeDoor.set(false)
    TriggerClientEvent("lunar_contracts:laundromat:removeElectricBox", -1)
    
    ShowContractObjective(activeLaundromatContract.contractIndex, locale("laundromat_title"), locale("obj_loot_laundry_open_safe"))
end)

local lootInProgress = false

local function lootSafe(playerObj)
    if not activeLaundromatContract or lootInProgress then return false end
    
    lootInProgress = true
    
    local collectedItems = {}
    
    while #activeLaundromatContract.safeLoot > 0 do
        local loot = activeLaundromatContract.safeLoot[1]
        
        if loot.item then
            if not playerObj:canCarryItem(loot.item, loot.count) then
                TriggerClientEvent("lunar_contracts:laundromat:setSafeAsLootable", -1)
                LR.notify(playerObj.source, locale("inventory_full"), "error")
                
                if #collectedItems > 0 then
                    LogItem(playerObj.source, string.format([[
Looted the Laundromat safe.
Items: %s]], table.concat(collectedItems, ", ")))
                end
                
                lootInProgress = false
                return false
            end
            
            if not playerObj:addItem(loot.item, loot.count, loot.metadata) then
                TriggerClientEvent("lunar_contracts:laundromat:setSafeAsLootable", -1)
                LR.notify(playerObj.source, locale("inventory_full"), "error")
                
                if #collectedItems > 0 then
                    LogItem(playerObj.source, string.format([[
Looted the Laundromat safe.
Items: %s]], table.concat(collectedItems, ", ")))
                end
                
                lootInProgress = false
                return false
            end
        elseif loot.account then
            playerObj:addAccountMoney(loot.account, loot.count)
        end
        
        table.insert(collectedItems, string.format("%sx %s", loot.count, loot.item or loot.account))
        table.remove(activeLaundromatContract.safeLoot, 1)
    end
    
    LogItem(playerObj.source, string.format([[
Looted the Laundromat safe.
Items: %s]], table.concat(collectedItems, ", ")))
    
    lootInProgress = false
    return true
end

RegisterNetEvent("lunar_contracts:laundromat:openSafe")
AddEventHandler("lunar_contracts:laundromat:openSafe", function()
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not activeLaundromatContract or not player then return end
    
    if not IsPlayerInContract(sourcePlayer, activeLaundromatContract.contractIndex) then return end
    
    if not Utils.distanceCheck(sourcePlayer, laundromatConfig.office.safe.coords, 3.0) then return end
    
    if not activeLaundromatContract.safeOpened then
        TriggerClientEvent("lunar_contracts:laundromat:setSafeOpen", -1)
        activeLaundromatContract.safeOpened = true
    end
    
    if not lootSafe(player) then return end
    
    TriggerClientEvent("lunar_contracts:laundromat:removeSafe", -1)
    FinishContract(activeLaundromatContract.contractIndex)
    
    ShowContractObjective(activeLaundromatContract.contractIndex, locale("laundromat_title"), locale("obj_contract_completed"))
    
    SetTimeout(60000, function()
        HideContractObjective(activeLaundromatContract.contractIndex)
    end)
end)

local function cleanup()
    if not activeLaundromatContract then return end
    
    officeDoor.set(true)
    TriggerClientEvent("lunar_contracts:laundromat:reset", -1)
    DeleteContract(activeLaundromatContract.contractIndex)
    HideContractObjective(activeLaundromatContract.contractIndex)
    
    activeLaundromatContract = nil
end

local function startContract()
    if not activeLaundromatContract then return end
    
    officeDoor.set(true)
    ShowContractObjective(activeLaundromatContract.contractIndex, locale("laundromat_title"), locale("obj_cut_generator_power"))
    
    SetTimeout(laundromatConfig.duration * 60000, cleanup)
end

local function getRequiredToolsText()
    local tools = {}
    local requiredItems = {
        laundromatConfig.generator.requiredItem,
        laundromatConfig.office.electricBox.requiredItem
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

local function createContract(contractId)
    local loot = {}
    for i = 1, #laundromatConfig.loot.locations do
        loot[i] = true
    end
    
    local safeLoot = {}
    for _, reward in ipairs(laundromatConfig.office.safe.rewards) do
        local count = type(reward.count) == "number" and reward.count or math.random(reward.count.min, reward.count.max)
        
        if reward.chance then
            local randomChance = math.random(1, 100)
            if randomChance > reward.chance then
                goto continue
            end
        end
        
        table.insert(safeLoot, {
            item = reward.item,
            account = reward.account,
            count = count,
            metadata = reward.metadata
        })
        
        ::continue::
    end
    
    activeLaundromatContract = {
        contractIndex = contractId,
        powerDisabled = false,
        loot = loot,
        safeOpened = false,
        safeLoot = safeLoot
    }
end

Missions.laundromat = {}

function Missions.laundromat.canBeGenerated()
    return activeLaundromatContract == nil
end

function Missions.laundromat.generated(contractId)
    createContract(contractId)
    
    local metadata = {
        {
            left = locale("reward"),
            right = locale("reward_laundromat")
        },
        {
            left = locale("required_tools"),
            right = getRequiredToolsText()
        }
    }
    
    return laundromatConfig.image, metadata
end

Missions.laundromat.deleted = cleanup

function Missions.laundromat.cancelled(contractId)
    TriggerClientEvent("lunar_contracts:laundromat:reset", -1)
    HideContractObjective(contractId)
end

function Missions.laundromat.start(contractId, data)
    if not activeLaundromatContract then return end
    
    local members = data.members
    TriggerClientEvent("lunar_contracts:laundromat:started", -1, members)
    TriggerEvent("lunar_contracts:laundromat:announceStarted", contractId, members)
    
    startContract()
end

function Missions.laundromat.getSaveData(contractId)
    if not activeLaundromatContract then
        error("Can't fetch save data from the laundromat contract.")
    end
    
    return { contractIndex = contractId }
end

function Missions.laundromat.loadSaveData(data)
    createContract(data.contractIndex)
end

function Missions.laundromat.getCancelPoint(contractId)
    return laundromatConfig.cancelPoint
end
