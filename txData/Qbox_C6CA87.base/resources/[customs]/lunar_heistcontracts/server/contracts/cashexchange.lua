local cashexchangeConfig = Config.contracts.cashexchange

local activeCashexchangeContracts = {}
local cashexchangeDoors = {}

if Config and Config.debug then print("[Cash Exchange] Starting door registration...") end

for i = 1, #cashexchangeConfig.locations do
    local location = cashexchangeConfig.locations[i]
    local doors = {}
    
    if Config and Config.debug then print(string.format("[Cash Exchange] Registering doors for location %d", i)) end
    
    local otherDoors = {}
    for j, coords in ipairs(location.doors.other) do
        otherDoors[j] = {
            coords = coords,
            model = cashexchangeConfig.doorModels.other[j]
        }
        if Config and Config.debug then print(string.format("  - Other door %d at %s with model %s", j, coords, cashexchangeConfig.doorModels.other[j])) end
    end
    
    if Config and Config.debug then print(string.format("  - Entry door at %s with model %s", location.doors.entry, cashexchangeConfig.doorModels.entry)) end
    doors.entry = RegisterDoorWithModel(location.doors.entry, cashexchangeConfig.doorModels.entry)
    
    if Config and Config.debug then print(string.format("  - Registering %d other doors", #otherDoors)) end
    doors.other = RegisterDoors(otherDoors)
    
    if Config and Config.debug then print(string.format("  - Registering %d vault doors with model %s", #location.doors.vault, cashexchangeConfig.doorModels.vault)) end
    doors.vault = RegisterDoorsWithModel(location.doors.vault, cashexchangeConfig.doorModels.vault)
    
    cashexchangeDoors[i] = doors
end

if Config and Config.debug then print("[Cash Exchange] Door registration complete!") end

-- Initialize all doors to locked state on startup
CreateThread(function()
    Wait(1000) -- Wait for door system to be ready
    for i = 1, #cashexchangeConfig.locations do
        if Config and Config.debug then print("[Cash Exchange] Initializing doors for location " .. i .. " to LOCKED state") end
        if cashexchangeDoors[i].entry then
            cashexchangeDoors[i].entry.set(true)
        end
        if cashexchangeDoors[i].other then
            cashexchangeDoors[i].other:setAll(true)
        end
        if cashexchangeDoors[i].vault then
            cashexchangeDoors[i].vault:setAll(true)
        end
    end
    if Config and Config.debug then print("[Cash Exchange] All cash exchange doors are now LOCKED") end
end)

local function findContract(contractId)
    for locationIndex, contract in pairs(activeCashexchangeContracts) do
        if contract.contractIndex == contractId then
            return locationIndex, contract
        end
    end
end

RegisterNetEvent("lunar_contracts:cashexchange:disableSmartLock")
AddEventHandler("lunar_contracts:cashexchange:disableSmartLock", function(locationIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = activeCashexchangeContracts[locationIndex]
    
    if not player or not contract then return end
    if contract.entryUnlocked then return end
    
    if cashexchangeConfig.startPanel.requiredItem and not player:hasItem(cashexchangeConfig.startPanel.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, contract.contractIndex) then return end
    
    local startPanel = cashexchangeConfig.locations[locationIndex].startPanel.coords
    if not Utils.distanceCheck(sourcePlayer, startPanel, 3.0) then return end
    
    if cashexchangeConfig.startPanel.requiredItem and cashexchangeConfig.startPanel.removeAfterUse then
        player:removeItem(cashexchangeConfig.startPanel.requiredItem, 1)
    end
    
    contract.entryUnlocked = true
    
    if Config and Config.debug then print("[Cash Exchange] Unlocking entry door for location " .. locationIndex) end
    cashexchangeDoors[locationIndex].entry.set(false)
    TriggerClientEvent("lunar_contracts:cashexchange:smartLockDisabled", -1, locationIndex)
    
    ShowContractObjective(contract.contractIndex, locale("cashexchange_title"), locale("obj_disable_exchange_locks"))
    
    if cashexchangeConfig.unlockVault.spawnLootEarly then
        contract.loot = Loot.new(cashexchangeConfig.locations[locationIndex].loot)
    end
    
    if cashexchangeConfig.dispatch.enabled then
        Dispatch.call(cashexchangeConfig.locations[locationIndex].alarm, {
            Code = cashexchangeConfig.dispatch.code,
            Title = cashexchangeConfig.dispatch.title,
            Message = cashexchangeConfig.dispatch.message
        })
    end
end)

RegisterNetEvent("lunar_contracts:cashexchange:unlockOtherDoors")
AddEventHandler("lunar_contracts:cashexchange:unlockOtherDoors", function(locationIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = activeCashexchangeContracts[locationIndex]
    
    if not player or not contract then return end
    if not contract.entryUnlocked then return end
    if contract.otherUnlocked then return end
    
    if cashexchangeConfig.electricBox.requiredItem and not player:hasItem(cashexchangeConfig.electricBox.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, contract.contractIndex) then return end
    
    local electricBox = cashexchangeConfig.locations[locationIndex].electricBox
    if not Utils.distanceCheck(sourcePlayer, electricBox, 3.0) then return end
    
    if cashexchangeConfig.electricBox.requiredItem and cashexchangeConfig.electricBox.removeAfterUse then
        player:removeItem(cashexchangeConfig.electricBox.requiredItem, 1)
    end
    
    contract.otherUnlocked = true
    
    if Config and Config.debug then print("[Cash Exchange] Unlocking other doors for location " .. locationIndex) end
    cashexchangeDoors[locationIndex].other:setAll(false)
    TriggerClientEvent("lunar_contracts:cashexchange:removeElectricBox", -1, locationIndex)
    
    ShowContractObjective(contract.contractIndex, locale("cashexchange_title"), locale("obj_override_vault_door"))
end)

RegisterNetEvent("lunar_contracts:cashexchange:unlockVault")
AddEventHandler("lunar_contracts:cashexchange:unlockVault", function(locationIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = activeCashexchangeContracts[locationIndex]
    
    if not player or not contract then return end
    if not contract.entryUnlocked then return end
    if not contract.otherUnlocked then return end
    
    if cashexchangeConfig.unlockVault.requiredItem and not player:hasItem(cashexchangeConfig.unlockVault.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, contract.contractIndex) then return end
    
    local vaultCoords = cashexchangeConfig.locations[locationIndex].doors.vault[1]
    if not Utils.distanceCheck(sourcePlayer, vaultCoords, 5.0) then return end
    
    if cashexchangeConfig.unlockVault.requiredItem and cashexchangeConfig.unlockVault.removeAfterUse then
        player:removeItem(cashexchangeConfig.unlockVault.requiredItem, 1)
    end
    
    contract.vaultOpened = true
    
    SetTimeout(cashexchangeConfig.unlockVault.delay * 60000 - 2000, function()
        if not cashexchangeConfig.unlockVault.spawnLootEarly then
            contract.loot = Loot.new(cashexchangeConfig.locations[locationIndex].loot)
        end
        
        LR.notify(sourcePlayer, locale("vault_opened"), "success")
        
        Wait(2000)
        if Config and Config.debug then print("[Cash Exchange] Unlocking vault doors for location " .. locationIndex) end
        cashexchangeDoors[locationIndex].vault:setAll(false)
        
        FinishContract(contract.contractIndex)
        
        ShowContractObjective(contract.contractIndex, locale("cashexchange_title"), locale("obj_contract_completed_loot"))
        
        SetTimeout(60000, function()
            HideContractObjective(contract.contractIndex)
        end)
    end)
    
    TriggerClientEvent("lunar_contracts:cashexchange:removeVault", -1, locationIndex)
end)

local function resetDoors(locationIndex)
    local doors = cashexchangeDoors[locationIndex]
    if Config and Config.debug then print("[Cash Exchange] Resetting all doors to locked for location " .. locationIndex) end
    doors.entry.set(true)
    doors.other:setAll(true)
    doors.vault:setAll(true)
end

local function cleanup(locationIndex)
    local contract = activeCashexchangeContracts[locationIndex]
    if not contract then return end
    
    resetDoors(locationIndex)
    
    if contract.loot then
        contract.loot:remove()
    end
    
    TriggerClientEvent("lunar_contracts:cashexchange:reset", -1, locationIndex)
    HideContractObjective(contract.contractIndex)
    DeleteContract(contract.contractIndex)
    
    activeCashexchangeContracts[locationIndex] = nil
end

local function startContract(locationIndex)
    local contract = activeCashexchangeContracts[locationIndex]
    
    resetDoors(locationIndex)
    SetTimeout(500, function()
        if activeCashexchangeContracts[locationIndex] then
            resetDoors(locationIndex)
        end
    end)
    
    ShowContractObjective(contract.contractIndex, locale("cashexchange_title"), locale("obj_go_to_exchange_from_back"))
    
    SetTimeout(cashexchangeConfig.duration * 60000, function()
        cleanup(locationIndex)
    end)
end

local function getRequiredToolsText()
    local tools = {}
    local requiredItems = {
        cashexchangeConfig.startPanel.requiredItem,
        cashexchangeConfig.electricBox.requiredItem,
        cashexchangeConfig.unlockVault.requiredItem
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
    activeCashexchangeContracts[locationIndex] = {
        contractIndex = contractId,
        entryUnlocked = false,
        otherUnlocked = false,
        vaultOpened = false
    }
end

Missions.cashexchange = {}

function Missions.cashexchange.canBeGenerated()
    return Utils.getTableSize(activeCashexchangeContracts) < #cashexchangeConfig.locations
end

function Missions.cashexchange.generated(contractId)
    local locationIndex
    repeat
        locationIndex = math.random(#cashexchangeConfig.locations)
    until not activeCashexchangeContracts[locationIndex]
    
    createContract(contractId, locationIndex)
    
    local metadata = {
        {
            left = locale("reward"),
            right = locale("reward_cashexchange")
        },
        {
            left = locale("required_tools"),
            right = getRequiredToolsText()
        }
    }
    
    return cashexchangeConfig.locations[locationIndex].image, metadata
end

function Missions.cashexchange.deleted(contractId)
    local locationIndex, contract = findContract(contractId)
    if contract then
        cleanup(locationIndex)
    end
end

function Missions.cashexchange.cancelled(contractId)
    local locationIndex, contract = findContract(contractId)
    if contract then
        TriggerClientEvent("lunar_contracts:cashexchange:reset", -1, locationIndex)
        HideContractObjective(contractId)
    end
end

function Missions.cashexchange.start(contractId, data)
    local locationIndex, contract = findContract(contractId)
    if not contract then return end
    
    local members = data.members
    TriggerClientEvent("lunar_contracts:cashexchange:started", -1, members, locationIndex)
    TriggerEvent("lunar_contracts:cashexchange:announceStarted", contractId, members, locationIndex)
    
    startContract(locationIndex)
end

function Missions.cashexchange.getSaveData(contractId)
    if not activeCashexchangeContracts then
        error("Can't fetch save data from a cash exchange contract.")
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

function Missions.cashexchange.loadSaveData(data)
    createContract(data.contractIndex, data.locationIndex)
end

function Missions.cashexchange.getCancelPoint(contractId)
    local locationIndex = findContract(contractId)
    return cashexchangeConfig.locations[locationIndex].cancelPoint
end
