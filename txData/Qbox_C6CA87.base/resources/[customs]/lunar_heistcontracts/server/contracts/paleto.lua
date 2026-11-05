local paletoConfig = Config.contracts.paleto

local activePaletoContract = nil
local spawnedEntities = {}

local authorizedDoors = RegisterDoors(paletoConfig.authorized.doors)
local surveilanceRoomDoor = RegisterDoor(paletoConfig.surveilanceRoom.door)
local officeDoors = RegisterDoors(paletoConfig.offices.doors)
local vaultDoor = RegisterDoor(paletoConfig.vault.door)

-- Initialize all doors to locked state on startup
CreateThread(function()
    Wait(1000)
    authorizedDoors:setAll(true)
    surveilanceRoomDoor.set(true)
    officeDoors:setAll(true)
    vaultDoor.set(true)
    if Config and Config.debug then print("[Paleto] All paleto doors locked on startup") end
end)

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

RegisterNetEvent("lunar_contracts:paleto:unlockAuthorizedDoors")
AddEventHandler("lunar_contracts:paleto:unlockAuthorizedDoors", function()
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activePaletoContract then return end
    if not authorizedDoors:get(1) then return end
    
    if paletoConfig.authorized.electricBox.requiredItem and not player:hasItem(paletoConfig.authorized.electricBox.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activePaletoContract.contractIndex) then return end
    
    if not Utils.distanceCheck(sourcePlayer, paletoConfig.authorized.electricBox.coords, 5.0) then return end
    
    if paletoConfig.authorized.electricBox.requiredItem and paletoConfig.authorized.electricBox.removeAfterUse then
        player:removeItem(paletoConfig.authorized.electricBox.requiredItem, 1)
    end
    
    authorizedDoors:setAll(false)
    TriggerClientEvent("lunar_contracts:paleto:removeElectricBox", -1)
    
    ShowContractObjective(activePaletoContract.contractIndex, locale("paleto_title"), locale("obj_unlock_surveilance"))
    
    SetTimeout(2000, function()
        LR.notify(sourcePlayer, locale("alarm_triggers_in"):format(paletoConfig.alarm.delay), "warn")
        
        SetTimeout(paletoConfig.alarm.delay * 60000, function()
            TriggerClientEvent("lunar_contracts:paleto:alarmTriggered", -1)
            
            if paletoConfig.dispatch.enabled then
                Dispatch.call(paletoConfig.alarm.coords, {
                    Code = paletoConfig.dispatch.code,
                    Title = paletoConfig.dispatch.title,
                    Message = paletoConfig.dispatch.message
                })
            end
        end)
    end)
end)

local function updateContractObjective()
    if not activePaletoContract then return end
    
    local codeDisplay = ""
    local hackedCount = 0
    
    for i = 1, #paletoConfig.offices.computers.locations do
        if activePaletoContract.hackedComputers[i] then
            local startPos = (i - 1) * 3 + 1
            local codePart = activePaletoContract.code:sub(startPos, startPos + 2)
            codeDisplay = codeDisplay .. codePart
            hackedCount = hackedCount + 1
        else
            codeDisplay = codeDisplay .. "___"
        end
    end
    
    ShowContractObjective(activePaletoContract.contractIndex, locale("paleto_title"), locale("obj_retrieve_vault_code"), codeDisplay)
end

RegisterNetEvent("lunar_contracts:paleto:unlockSurveilanceRoom")
AddEventHandler("lunar_contracts:paleto:unlockSurveilanceRoom", function()
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activePaletoContract then return end
    if not surveilanceRoomDoor.get() then return end
    
    if paletoConfig.surveilanceRoom.panel.requiredItem and not player:hasItem(paletoConfig.surveilanceRoom.panel.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activePaletoContract.contractIndex) then return end
    
    if not Utils.distanceCheck(sourcePlayer, paletoConfig.surveilanceRoom.panel.coords, 3.0) then return end
    
    if paletoConfig.surveilanceRoom.panel.requiredItem and paletoConfig.surveilanceRoom.panel.removeAfterUse then
        player:removeItem(paletoConfig.surveilanceRoom.panel.requiredItem, 1)
    end
    
    surveilanceRoomDoor.set(false)
    TriggerClientEvent("lunar_contracts:paleto:removeSurveilanceRoomPanel", -1)
    
    updateContractObjective()
end)

RegisterNetEvent("lunar_contracts:paleto:unlockOfficeDoor")
AddEventHandler("lunar_contracts:paleto:unlockOfficeDoor", function(doorCode)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local lowerDoorCode = doorCode:lower()
    
    if not player then return end
    if not activePaletoContract then return end
    
    if paletoConfig.terminal.requiredItem and not player:hasItem(paletoConfig.terminal.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activePaletoContract.contractIndex) then return end
    if not Utils.distanceCheck(sourcePlayer, paletoConfig.terminal.coords, 3.0) then return end
    
    for i, storedCode in ipairs(activePaletoContract.doorCodes) do
        if storedCode:lower() == lowerDoorCode then
            if officeDoors:get(i) then
                local hackSuccess = lib.callback.await("lunar_contracts:paleto:officeDoorHack", sourcePlayer)
                
                if hackSuccess then
                    if paletoConfig.terminal.requiredItem then
                        if not player:hasItem(paletoConfig.terminal.requiredItem) then return end
                        if paletoConfig.terminal.removeAfterUse then
                            player:removeItem(paletoConfig.terminal.requiredItem)
                        end
                    end
                    
                    officeDoors:set(i, false)
                    TriggerClientEvent("lunar_contracts:paleto:officeDoorHacked", -1, i)
                end
                return
            end
        end
    end
    
    LR.notify(sourcePlayer, locale("door_doesnt_exist"), "error")
end)

RegisterNetEvent("lunar_contracts:paleto:hackedOfficeComputer")
AddEventHandler("lunar_contracts:paleto:hackedOfficeComputer", function(computerIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activePaletoContract then return end
    if activePaletoContract.hackedComputers[computerIndex] then return end
    
    if paletoConfig.offices.computers.requiredItem and not player:hasItem(paletoConfig.offices.computers.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activePaletoContract.contractIndex) then return end
    
    local computerCoords = paletoConfig.offices.computers.locations[computerIndex]
    if not Utils.distanceCheck(sourcePlayer, computerCoords, 3.0) then return end
    
    if paletoConfig.offices.computers.requiredItem and paletoConfig.offices.computers.removeAfterUse then
        player:removeItem(paletoConfig.offices.computers.requiredItem, 1)
    end
    
    activePaletoContract.hackedComputers[computerIndex] = true
    
    local startPos = (computerIndex - 1) * 3 + 1
    local codePart = activePaletoContract.code:sub(startPos, startPos + 2)
    
    TriggerClientEvent("lunar_contracts:paleto:showCode", sourcePlayer, locale("vault_code_part"):format(codePart))
    updateContractObjective()
end)

local safeLootInProgress = false

local function lootSafe(playerObj)
    if not activePaletoContract or safeLootInProgress then return false end
    
    safeLootInProgress = true
    
    local collectedItems = {}
    
    while #activePaletoContract.safeLoot > 0 do
        local loot = activePaletoContract.safeLoot[1]
        
        if loot.item then
            if not playerObj:canCarryItem(loot.item, loot.count) then
                TriggerClientEvent("lunar_contracts:paleto:setSafeAsLootable", -1)
                
                if #collectedItems > 0 then
                    LogItem(playerObj.source, string.format([[
Looted the Paleto Bank safe.
Items: %s]], table.concat(collectedItems, ", ")))
                end
                
                safeLootInProgress = false
                return false
            end
            
            if not playerObj:addItem(loot.item, loot.count, loot.metadata) then
                TriggerClientEvent("lunar_contracts:paleto:setSafeAsLootable", -1)
                
                if #collectedItems > 0 then
                    LogItem(playerObj.source, string.format([[
Looted the Paleto Bank safe.
Items: %s]], table.concat(collectedItems, ", ")))
                end
                
                safeLootInProgress = false
                return false
            end
        elseif loot.account then
            playerObj:addAccountMoney(loot.account, loot.count)
        end
        
        table.insert(collectedItems, string.format("%sx %s", loot.count, loot.item or loot.account))
        table.remove(activePaletoContract.safeLoot, 1)
    end
    
    LogItem(playerObj.source, string.format([[
Looted the Paleto Bank safe.
Items: %s]], table.concat(collectedItems, ", ")))
    
    safeLootInProgress = false
    return true
end

RegisterNetEvent("lunar_contracts:paleto:openSafe")
AddEventHandler("lunar_contracts:paleto:openSafe", function()
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not activePaletoContract or not player then return end
    if not Utils.distanceCheck(sourcePlayer, paletoConfig.offices.safe.coords, 3.0) then return end
    
    if not activePaletoContract.safeOpened then
        TriggerClientEvent("lunar_contracts:paleto:setSafeOpen", -1)
        activePaletoContract.safeOpened = true
    end
    
    if not lootSafe(player) then return end
    
    TriggerClientEvent("lunar_contracts:paleto:removeSafe", -1)
end)

RegisterNetEvent("lunar_contracts:paleto:unlockVault")
AddEventHandler("lunar_contracts:paleto:unlockVault", function(enteredCode)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activePaletoContract then return end
    if activePaletoContract.code ~= enteredCode then return end
    if not vaultDoor.get() then return end
    
    if paletoConfig.vault.panel.requiredItem and not player:hasItem(paletoConfig.vault.panel.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activePaletoContract.contractIndex) then return end
    
    if not Utils.distanceCheck(sourcePlayer, paletoConfig.vault.panel.coords, 5.0) then return end
    
    local minigameSuccess = lib.callback.await("lunar_contracts:paleto:vaultMinigame", sourcePlayer)
    
    if minigameSuccess then
        if paletoConfig.vault.panel.requiredItem then
            if not player:hasItem(paletoConfig.vault.panel.requiredItem) then return end
            if paletoConfig.vault.panel.removeAfterUse then
                player:removeItem(paletoConfig.vault.panel.requiredItem, 1)
            end
        end
        
        vaultDoor.set(false)
        activePaletoContract.loot = Loot.new(paletoConfig.vault.loot)
        TriggerClientEvent("lunar_contracts:paleto:removeVaultPanel", -1)
        
        ShowContractObjective(activePaletoContract.contractIndex, locale("paleto_title"), locale("obj_contract_completed_loot"))
        
        SetTimeout(60000, function()
            HideContractObjective(activePaletoContract.contractIndex)
        end)
        
        FinishContract(activePaletoContract.contractIndex)
    end
end)

RegisterNetEvent("lunar_contracts:paleto:stealPainting")
AddEventHandler("lunar_contracts:paleto:stealPainting", function(roomIndex, paintingIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local paintingConfig = paletoConfig.offices.paintings.locations[roomIndex][paintingIndex]
    
    if not player then return end
    if not activePaletoContract then return end
    if not activePaletoContract.paintings[roomIndex] or not activePaletoContract.paintings[roomIndex][paintingIndex] then return end
    if not IsPlayerInContract(sourcePlayer, activePaletoContract.contractIndex) then return end
    if not Utils.distanceCheck(sourcePlayer, paintingConfig, 3.0) then return end
    
    if not player:canCarryItem(paletoConfig.offices.paintings.item, 1) then
        LR.notify(sourcePlayer, locale("inventory_full"), "error")
        return
    end
    
    if player:addItem(paletoConfig.offices.paintings.item, 1) then
        activePaletoContract.paintings[roomIndex][paintingIndex] = false
        TriggerClientEvent("lunar_contracts:paleto:setPaintingLooted", -1, roomIndex, paintingIndex)
        LogItem(player.source, "Stole a painting inside the Paleto Bank.")
    else
        LR.notify(sourcePlayer, locale("inventory_full"), "error")
    end
end)

lib.callback.register("lunar_contracts:paleto:canDrillDepositBox", function(playerId, boxIndex)
    local player = Framework.getPlayerFromId(playerId)
    
    if not player then return false end
    if not activePaletoContract then return false end
    if vaultDoor.get() then return false end
    if not IsPlayerInContract(playerId, activePaletoContract.contractIndex) then return false end
    
    local boxCoords = paletoConfig.vault.drilling.locations[boxIndex]
    if not Utils.distanceCheck(playerId, boxCoords, 5.0) then return false end
    if not activePaletoContract.depositBoxes[boxIndex] then return false end
    
    for _, reward in ipairs(paletoConfig.vault.drilling.rewards) do
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

RegisterNetEvent("lunar_contracts:paleto:drillDepositBox")
AddEventHandler("lunar_contracts:paleto:drillDepositBox", function(boxIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activePaletoContract then return end
    if vaultDoor.get() then return end
    if not IsPlayerInContract(sourcePlayer, activePaletoContract.contractIndex) then return end
    
    local boxCoords = paletoConfig.vault.drilling.locations[boxIndex]
    if not Utils.distanceCheck(sourcePlayer, boxCoords, 5.0) then return end
    if not activePaletoContract.depositBoxes[boxIndex] then return end
    
    local collectedItems = {}
    local failed = false
    
    for _, reward in ipairs(paletoConfig.vault.drilling.rewards) do
        local count = type(reward.count) == "number" and reward.count or math.random(reward.count.min, reward.count.max)
        
        if reward.chance then
            local randomChance = math.random(1, 100)
            if randomChance > reward.chance then goto continue end
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
        activePaletoContract.depositBoxes[boxIndex] = nil
        TriggerClientEvent("lunar_contracts:paleto:removeDepositBox", -1, boxIndex)
        LogItem(sourcePlayer, string.format([[
Drilled a Paleto Bank deposit box.
Items: %s]], table.concat(collectedItems, ", ")))
    end
end)

local function spawnElectricBox()
    local coords = paletoConfig.authorized.electricBox.coords
    local box = CreateObjectNoOffset(paletoConfig.authorized.electricBox.model, coords.x, coords.y, coords.z - 1.2, true, false, false)
    SetEntityHeading(box, coords.w + 180.0)
    table.insert(spawnedEntities, box)
end

local paintingModels = {
    1860271043, 645688058, 876512894, 158478566, 397364576,
    -274367155, -33875464, -1302822220, -526786762, -2120801998
}

local function spawnPaintings()
    local modelIndex = math.random(#paintingModels)
    local paintingNetIds = {}
    
    for roomIndex, roomPaintings in ipairs(paletoConfig.offices.paintings.locations) do
        for paintingIndex, coords in ipairs(roomPaintings) do
            local painting = CreateObjectNoOffset(paintingModels[modelIndex], coords.x, coords.y, coords.z - 0.5, true, false, false)
            SetEntityHeading(painting, coords.w)
            table.insert(spawnedEntities, painting)
            table.insert(paintingNetIds, NetworkGetNetworkIdFromEntity(painting))
            
            modelIndex = modelIndex + 1
            if modelIndex > #paintingModels then modelIndex = 1 end
        end
    end
    
    TriggerClientEvent("lunar_contracts:paleto:syncRoomId", -1, paintingNetIds)
end

local function resetDoors()
    authorizedDoors:setAll(true)
    surveilanceRoomDoor.set(true)
    officeDoors:setAll(true)
    vaultDoor.set(true)
end

local function cleanup()
    if not activePaletoContract then return end
    
    resetDoors()
    cleanUpEntities()
    
    if activePaletoContract.loot then
        activePaletoContract.loot:remove()
    end
    
    TriggerClientEvent("lunar_contracts:paleto:reset", -1)
    HideContractObjective(activePaletoContract.contractIndex)
    DeleteContract(activePaletoContract.contractIndex)
    
    activePaletoContract = nil
end

local function startContract()
    if not activePaletoContract then return end
    
    spawnElectricBox()
    spawnPaintings()
    resetDoors()
    
    ShowContractObjective(activePaletoContract.contractIndex, locale("paleto_title"), locale("obj_disable_smart_locks"))
    
    SetTimeout(paletoConfig.duration * 60000, cleanup)
end

local function generateRandomHexCode(length)
    local code = ""
    for _ = 1, length do
        local digit = math.random(#"0123456789ABCDEF")
        code = code .. ("0123456789ABCDEF"):sub(digit, digit)
    end
    return "0x" .. code
end

local function generateRandomNumericCode(length)
    local code = ""
    for _ = 1, length do
        local digit = math.random(#"0123456789")
        code = code .. ("0123456789"):sub(digit, digit)
    end
    return code
end

local function getRequiredToolsText()
    local tools = {}
    local requiredItems = {
        paletoConfig.authorized.electricBox.requiredItem,
        paletoConfig.surveilanceRoom.panel.requiredItem,
        paletoConfig.terminal.requiredItem,
        paletoConfig.offices.computers.requiredItem,
        paletoConfig.vault.panel.requiredItem,
        paletoConfig.vault.drilling.requiredItem
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
    local doorCodes = {}
    for i = 1, #paletoConfig.offices.doors do
        doorCodes[i] = generateRandomHexCode(6)
    end
    
    local codeLength = #paletoConfig.offices.computers.locations * 3
    local vaultCode = generateRandomNumericCode(codeLength)
    
    local safeLoot = {}
    for _, reward in ipairs(paletoConfig.offices.safe.rewards) do
        local count = type(reward.count) == "number" and reward.count or math.random(reward.count.min, reward.count.max)
        
        if not reward.chance or math.random(1, 100) <= reward.chance then
            table.insert(safeLoot, {
                item = reward.item,
                account = reward.account,
                count = count,
                metadata = reward.metadata
            })
        end
    end
    
    local paintings = {}
    for roomIndex, roomPaintings in ipairs(paletoConfig.offices.paintings.locations) do
        paintings[roomIndex] = {}
        for paintingIndex = 1, #roomPaintings do
            paintings[roomIndex][paintingIndex] = true
        end
    end
    
    local depositBoxes = {}
    for i = 1, #paletoConfig.vault.drilling.locations do
        depositBoxes[i] = true
    end
    
    activePaletoContract = {
        contractIndex = contractId,
        doorCodes = doorCodes,
        code = vaultCode,
        safeLoot = safeLoot,
        hackedComputers = {},
        paintings = paintings,
        depositBoxes = depositBoxes,
        safeOpened = false
    }
end

Missions.paleto = {}

function Missions.paleto.canBeGenerated()
    return activePaletoContract == nil
end

function Missions.paleto.generated(contractId)
    createContract(contractId)
    
    local metadata = {
        { left = locale("reward"), right = locale("reward_paleto") },
        { left = locale("required_tools"), right = getRequiredToolsText() }
    }
    
    return paletoConfig.image, metadata
end

Missions.paleto.deleted = cleanup

function Missions.paleto.cancelled(contractId)
    TriggerClientEvent("lunar_contracts:paleto:reset", -1)
    HideContractObjective(contractId)
end

function Missions.paleto.start(contractId, data)
    if not activePaletoContract then return end
    
    local members = data.members
    TriggerClientEvent("lunar_contracts:paleto:started", -1, members, activePaletoContract.doorCodes)
    TriggerEvent("lunar_contracts:paleto:announceStarted", contractId, members)
    
    startContract()
end

function Missions.paleto.getSaveData(contractId)
    if not activePaletoContract then
        error("Can't fetch save data from the paleto bank contract.")
    end
    
    return { contractIndex = contractId }
end

function Missions.paleto.loadSaveData(data)
    createContract(data.contractIndex)
end

function Missions.paleto.getCancelPoint(contractId)
    return paletoConfig.cancelPoint
end
