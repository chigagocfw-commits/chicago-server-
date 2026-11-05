local bobcatConfig = Config.contracts.bobcat

local activeBobcatContract = nil
local spawnedEntities = {}

local function cleanUpEntities()
    for _, entity in ipairs(spawnedEntities) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
    spawnedEntities = {}
end

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == cache.resource then
        cleanUpEntities()
    end
end)

local entryDoor = RegisterDoorWithModel(bobcatConfig.entryDoor.locations, bobcatConfig.entryDoor.model)
local securityDoor = RegisterDoorWithModel(bobcatConfig.securityDoor.coords, bobcatConfig.securityDoor.model)
local guardedAreaDoor = RegisterDoorsWithModel(
    (function()
        local coords = {}
        for i, d in ipairs(bobcatConfig.guardedArea.door) do coords[i] = d.coords end
        return coords
    end)(),
    bobcatConfig.guardedArea.door[1].model
)

-- Initialize all doors to locked state on startup
CreateThread(function()
    Wait(1000)
    entryDoor.set(true)
    securityDoor.set(true)
    guardedAreaDoor:setAll(true)
    if Config and Config.debug then print("[Bobcat] All bobcat doors locked on startup") end
end)

RegisterNetEvent("lunar_contracts:bobcat:unlockEntryDoor")
AddEventHandler("lunar_contracts:bobcat:unlockEntryDoor", function(doorCoords)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not activeBobcatContract or not player then return end
    if not entryDoor.get() then return end
    
    if bobcatConfig.entryDoor.requiredItem and not player:hasItem(bobcatConfig.entryDoor.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activeBobcatContract.contractIndex) then return end
    if not Utils.distanceCheck(sourcePlayer, doorCoords, 3.0) then return end
    
    if bobcatConfig.entryDoor.requiredItem then
        player:removeItem(bobcatConfig.entryDoor.requiredItem, 1)
    end
    
    TriggerClientEvent("lunar_contracts:bobcat:syncEffect", -1, doorCoords)
    
    if bobcatConfig.dispatch.enabled then
        Dispatch.call(bobcatConfig.alarm.coords, {
            Code = bobcatConfig.dispatch.code,
            Title = bobcatConfig.dispatch.title,
            Message = bobcatConfig.dispatch.message
        })
    end
    
    Wait(10000)
    entryDoor.set(false)
    TriggerClientEvent("lunar_contracts:bobcat:removeEntryDoor", -1)
end)

RegisterNetEvent("lunar_contracts:bobcat:unlockSecurityDoor")
AddEventHandler("lunar_contracts:bobcat:unlockSecurityDoor", function(doorCoords)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not activeBobcatContract or not player then return end
    if not securityDoor.get() then return end
    if entryDoor.get() then return end
    
    if bobcatConfig.securityDoor.requiredItem and not player:hasItem(bobcatConfig.securityDoor.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activeBobcatContract.contractIndex) then return end
    if not Utils.distanceCheck(sourcePlayer, doorCoords, 3.0) then return end
    
    if bobcatConfig.securityDoor.requiredItem then
        player:removeItem(bobcatConfig.securityDoor.requiredItem, 1)
    end
    
    TriggerClientEvent("lunar_contracts:bobcat:syncEffect", -1, doorCoords)
    
    Wait(10000)
    securityDoor.set(false)
    TriggerClientEvent("lunar_contracts:bobcat:removeSecurityDoor", -1)
end)

local function spawnGuards()
    if not activeBobcatContract then return end
    
    local guardNetIds = {}
    
    for i, coords in ipairs(bobcatConfig.guardedArea.guards.locations) do
        local weapon = Utils.randomFromTable(bobcatConfig.guardedArea.guards.weapons)
        local guard = CreatePed(4, bobcatConfig.guardedArea.guards.model, coords.x, coords.y, coords.z, coords.w, true, true)
        
        GiveWeaponToPed(guard, joaat(weapon.name), 200, true, true)
        SetPedArmour(guard, 100)
        SetPedRandomComponentVariation(guard, 0)
        
        activeBobcatContract.guards[i] = {
            netId = NetworkGetNetworkIdFromEntity(guard),
            weapon = weapon
        }
        
        guardNetIds[i] = activeBobcatContract.guards[i].netId
        table.insert(spawnedEntities, guard)
    end
    
    TriggerClientEvent("lunar_contracts:bobcat:handleGuardsLogic", -1, guardNetIds)
end

RegisterNetEvent("lunar_contracts:bobcat:lootGuard")
AddEventHandler("lunar_contracts:bobcat:lootGuard", function(guardNetId)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local guard = NetworkGetEntityFromNetworkId(guardNetId)
    
    if not activeBobcatContract or not player then return end
    if not DoesEntityExist(guard) then return end
    if not bobcatConfig.guardedArea.guards.looting.enabled then return end
    
    if not Utils.distanceCheck(sourcePlayer, GetEntityCoords(guard), 5.0) then return end
    
    for i, guardData in pairs(activeBobcatContract.guards) do
        if guardData.netId == guardNetId then
            local ammoAmount = math.random(guardData.weapon.ammo.min, guardData.weapon.ammo.max)
            
            if not player:canCarryItem(guardData.weapon.name, 1) or not player:canCarryItem(guardData.weapon.ammo.name, ammoAmount) then
                LR.notify(sourcePlayer, locale("inventory_full"), "error")
                return
            end
            
            activeBobcatContract.guards[i] = nil
            
            if player:addItem(guardData.weapon.name, 1) then
                player:addItem(guardData.weapon.ammo.name, ammoAmount)
                TriggerClientEvent("lunar_contracts:bobcat:guardLooted", -1, guardNetId)
                LogItem(sourcePlayer, string.format([[
Looted a Bobcat Security guard.
Weapon: %s]], guardData.weapon.name:upper()))
            else
                activeBobcatContract.guards[i] = guardData
                LR.notify(sourcePlayer, locale("inventory_full"), "error")
            end
            return
        end
    end
end)

RegisterNetEvent("lunar_contracts:bobcat:hackedKeypad")
AddEventHandler("lunar_contracts:bobcat:hackedKeypad", function()
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activeBobcatContract then return end
    if not guardedAreaDoor:get(1) then return end
    if securityDoor.get() then return end
    
    if bobcatConfig.guardedArea.keypad.requiredItem and not player:hasItem(bobcatConfig.guardedArea.keypad.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activeBobcatContract.contractIndex) then return end
    
    if not Utils.distanceCheck(sourcePlayer, bobcatConfig.guardedArea.keypad.coords, 3.0) then return end
    
    if bobcatConfig.guardedArea.keypad.requiredItem and bobcatConfig.guardedArea.keypad.removeAfterUse then
        player:removeItem(bobcatConfig.guardedArea.keypad.requiredItem, 1)
    end
    
    guardedAreaDoor:setAll(false)
    TriggerClientEvent("lunar_contracts:bobcat:removeKeypad", -1)
    
    ShowContractObjective(activeBobcatContract.contractIndex, locale("bobcat_title"), locale("obj_fight_guards_plant_c4"))
    spawnGuards()
end)

RegisterNetEvent("lunar_contracts:bobcat:plantBomb")
AddEventHandler("lunar_contracts:bobcat:plantBomb", function()
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not activeBobcatContract or not player then return end
    if activeBobcatContract.vaultOpened then return end
    
    if bobcatConfig.guardedArea.vault.requiredItem and not player:hasItem(bobcatConfig.guardedArea.vault.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activeBobcatContract.contractIndex) then return end
    
    if not Utils.distanceCheck(sourcePlayer, bobcatConfig.guardedArea.vault.coords, 3.0) then return end
    
    if bobcatConfig.guardedArea.vault.requiredItem then
        player:removeItem(bobcatConfig.guardedArea.vault.requiredItem, 1)
    end
    
    activeBobcatContract.vaultOpened = true
    
    TriggerClientEvent("lunar_contracts:bobcat:bombPlanted", -1)
    ShowContractObjective(activeBobcatContract.contractIndex, locale("bobcat_title"), locale("obj_wait_for_explosion"))
    
    Wait(12866)
    
    activeBobcatContract.loot = Loot.new(bobcatConfig.guardedArea.vault.loot)
    
    ShowContractObjective(activeBobcatContract.contractIndex, locale("bobcat_title"), locale("obj_contract_completed_loot"))
    
    SetTimeout(60000, function()
        HideContractObjective(activeBobcatContract.contractIndex)
    end)
    
    FinishContract(activeBobcatContract.contractIndex)
end)

RegisterNetEvent("lunar_contracts:bobcat:takeWeaponsLoot")
AddEventHandler("lunar_contracts:bobcat:takeWeaponsLoot", function(lootIndex, positionIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local lootConfig = bobcatConfig.guardedArea.vault.weaponsLoot[lootIndex]
    
    if not activeBobcatContract or not player or not lootConfig then return end
    if not activeBobcatContract.vaultOpened then return end
    if not activeBobcatContract.weaponsLoot[lootIndex][positionIndex] then return end
    
    for _, itemData in ipairs(lootConfig.items) do
        local count = type(itemData.count) == "number" and itemData.count or itemData.count.max
        
        if not player:canCarryItem(itemData.name, count) then
            LR.notify(sourcePlayer, locale("inventory_full"), "error")
            return
        end
    end
    
    local collectedItems = {}
    local failed = false
    
    for _, itemData in ipairs(lootConfig.items) do
        local count = type(itemData.count) == "number" and itemData.count or math.random(itemData.count.min, itemData.count.max)
        
        if itemData.chance then
            local randomChance = math.random(1, 100)
            if randomChance > itemData.chance then
                goto continue
            end
        end
        
        if not player:addItem(itemData.name, count, itemData.metadata) then
            failed = true
            LR.notify(sourcePlayer, locale("inventory_full"), "error")
            break
        end
        
        table.insert(collectedItems, string.format("%sx %s", count, itemData.name))
        
        ::continue::
    end
    
    if not failed then
        activeBobcatContract.weaponsLoot[lootIndex][positionIndex] = false
        TriggerClientEvent("lunar_contracts:bobcat:removeWeaponsLoot", -1, lootIndex, positionIndex)
        LogItem(sourcePlayer, string.format([[
Took the Bobcat Security weapons loot.
Items: %s]], table.concat(collectedItems, ", ")))
    end
end)

local function resetDoors()
    entryDoor.set(true)
    securityDoor.set(true)
    guardedAreaDoor:setAll(true)
end

local function cleanup()
    if not activeBobcatContract then return end
    
    resetDoors()
    
    if activeBobcatContract.loot then
        activeBobcatContract.loot:remove()
    end
    
    TriggerClientEvent("lunar_contracts:bobcat:reset", -1)
    TriggerClientEvent("lunar_contracts:bobcat:removeGuards", -1)
    HideContractObjective(activeBobcatContract.contractIndex)
    DeleteContract(activeBobcatContract.contractIndex)
    
    activeBobcatContract = nil
end

local function startContract()
    if not activeBobcatContract then return end
    
    resetDoors()
    
    ShowContractObjective(activeBobcatContract.contractIndex, locale("bobcat_title"), locale("obj_gain_access_to_area"))
    
    SetTimeout(bobcatConfig.duration * 60000, cleanup)
end

local function getRequiredToolsText()
    local tools = {}
    local requiredItems = {
        bobcatConfig.entryDoor.requiredItem,
        bobcatConfig.securityDoor.requiredItem,
        bobcatConfig.guardedArea.keypad.requiredItem,
        bobcatConfig.guardedArea.vault.requiredItem
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
    local weaponsLoot = {}
    
    for i, lootLocation in ipairs(bobcatConfig.guardedArea.vault.weaponsLoot) do
        local positions = {}
        for j = 1, #lootLocation.locations do
            positions[j] = true
        end
        weaponsLoot[i] = positions
    end
    
    activeBobcatContract = {
        contractIndex = contractId,
        guards = {},
        vaultOpened = false,
        weaponsLoot = weaponsLoot
    }
end

Missions.bobcat = {}

function Missions.bobcat.canBeGenerated()
    return activeBobcatContract == nil
end

function Missions.bobcat.generated(contractId)
    createContract(contractId)
    
    local metadata = {
        {
            left = locale("reward"),
            right = locale("reward_bobcat")
        },
        {
            left = locale("required_tools"),
            right = getRequiredToolsText()
        }
    }
    
    return bobcatConfig.image, metadata
end

Missions.bobcat.deleted = cleanup

function Missions.bobcat.cancelled(contractId)
    TriggerClientEvent("lunar_contracts:bobcat:reset", -1)
    HideContractObjective(contractId)
end

function Missions.bobcat.start(contractId, data)
    if not activeBobcatContract then return end
    
    local members = data.members
    TriggerClientEvent("lunar_contracts:bobcat:started", -1, members)
    TriggerEvent("lunar_contracts:bobcat:announceStarted", contractId, members)
    
    startContract()
end

function Missions.bobcat.getSaveData(contractId)
    if not activeBobcatContract then
        error("Can't fetch save data from the bobcat security contract.")
    end
    
    return { contractIndex = contractId }
end

function Missions.bobcat.loadSaveData(data)
    createContract(data.contractIndex)
end

function Missions.bobcat.getCancelPoint(contractId)
    return bobcatConfig.entryDoor.locations[1]
end
