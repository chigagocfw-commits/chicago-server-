local artasylumConfig = Config.contracts.artasylum

local activeArtasylumContract = nil
local spawnedEntities = {}

local function cleanUpEntities()
    for _, entity in ipairs(spawnedEntities) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
    spawnedEntities = {}
end

local function isPlayerNearCameraDesk(sourcePlayer)
    for _, deskCoords in ipairs(artasylumConfig.cameras.desks) do
        if Utils.distanceCheck(sourcePlayer, deskCoords, 7.5) then
            return true
        end
    end

    return false
end

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == cache.resource then
        cleanUpEntities()
    end
end)

local function createKeypadDoors()
    local doors = {}
    for i, location in ipairs(artasylumConfig.keypadDoors.locations) do
        if location.door then
            table.insert(doors, { model = location.model, coords = location.door })
        elseif location.doors then
            local multiDoors = {}
            for _, coords in ipairs(location.doors) do
                table.insert(multiDoors, { model = location.model, coords = coords })
            end
            table.insert(doors, multiDoors)
        end
    end
    return RegisterDoors(doors)
end

local keypadDoors = createKeypadDoors()
local securityDoors = RegisterDoors(artasylumConfig.securityDoors.locations)
local genericDoors = RegisterDoors(artasylumConfig.genericDoors.locations)
local vaultDoor = RegisterDoorWithModel(artasylumConfig.vault.door.coords, artasylumConfig.vault.door.model)
local sewerDoors = RegisterDoors(artasylumConfig.sewerDoors.locations)

-- Initialize all doors to locked state on startup
CreateThread(function()
    Wait(1000)
    keypadDoors:setAll(true)
    securityDoors:setAll(true)
    genericDoors:setAll(true)
    vaultDoor.set(true)
    sewerDoors:setAll(true)
    if Config and Config.debug then print("[Art Asylum] All art asylum doors locked on startup") end
end)

RegisterNetEvent("lunar_contracts:artasylum:openKeypadDoor")
AddEventHandler("lunar_contracts:artasylum:openKeypadDoor", function(doorIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local doorLocation = artasylumConfig.keypadDoors.locations[doorIndex]
    
    if not player then return end
    if not activeArtasylumContract then return end
    if not keypadDoors:get(doorIndex) then return end
    
    if artasylumConfig.keypadDoors.requiredItem and not player:hasItem(artasylumConfig.keypadDoors.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activeArtasylumContract.contractIndex) then return end
    
    local checkCoords = doorLocation.door or doorLocation.doors
    if not Utils.distanceCheck(sourcePlayer, GetDoorCoords(checkCoords), 8.0) then return end
    
    if artasylumConfig.keypadDoors.requiredItem and artasylumConfig.keypadDoors.removeAfterUse then
        player:removeItem(artasylumConfig.keypadDoors.requiredItem, 1)
    end
    
    keypadDoors:set(doorIndex, false)
    TriggerClientEvent("lunar_contracts:artasylum:removeKeypadDoor", -1, doorIndex)
end)

RegisterNetEvent("lunar_contracts:artasylum:openSecurityDoor")
AddEventHandler("lunar_contracts:artasylum:openSecurityDoor", function(doorIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local doorLocation = artasylumConfig.securityDoors.locations[doorIndex]
    
    if not player then return end
    if not activeArtasylumContract then return end
    if not securityDoors:get(doorIndex) then return end
    
    if artasylumConfig.securityDoors.requiredItem and not player:hasItem(artasylumConfig.securityDoors.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activeArtasylumContract.contractIndex) then return end
    if not Utils.distanceCheck(sourcePlayer, GetDoorCoords(doorLocation), 5.0) then return end
    
    if artasylumConfig.securityDoors.requiredItem and artasylumConfig.securityDoors.removeAfterUse then
        player:removeItem(artasylumConfig.securityDoors.requiredItem, 1)
    end
    
    securityDoors:set(doorIndex, false)
    TriggerClientEvent("lunar_contracts:artasylum:removeSecurityDoor", -1, doorIndex)
end)

RegisterNetEvent("lunar_contracts:artasylum:disableLocks")
AddEventHandler("lunar_contracts:artasylum:disableLocks", function()
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activeArtasylumContract then return end
    
    if artasylumConfig.genericDoors.electricBox.requiredItem and not player:hasItem(artasylumConfig.genericDoors.electricBox.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activeArtasylumContract.contractIndex) then return end
    if not Utils.distanceCheck(sourcePlayer, artasylumConfig.genericDoors.electricBox.coords, 5.0) then return end
    
    if artasylumConfig.genericDoors.electricBox.requiredItem and artasylumConfig.genericDoors.electricBox.removeAfterUse then
        player:removeItem(artasylumConfig.genericDoors.electricBox.requiredItem, 1)
    end
    
    genericDoors:setAll(false)
    TriggerClientEvent("lunar_contracts:artasylum:removeElectricBox", -1)
    
    ShowContractObjective(activeArtasylumContract.contractIndex, locale("artasylum_title"), locale("obj_decrypt_code"))
end)

local function triggerAlarm()
    if not activeArtasylumContract then return end
    
    activeArtasylumContract.alarmTriggered = true
    TriggerClientEvent("lunar_contracts:artasylum:triggerAlarm", -1)
    
    if artasylumConfig.dispatch.enabled then
        Dispatch.call(artasylumConfig.alarm.coords, {
            Code = artasylumConfig.dispatch.code,
            Title = artasylumConfig.dispatch.title,
            Message = artasylumConfig.dispatch.message
        })
    end
end

RegisterNetEvent("lunar_contracts:artasylum:triggerAlarm")
AddEventHandler("lunar_contracts:artasylum:triggerAlarm", function()
    local sourcePlayer = source
    
    if not activeArtasylumContract then return end
    
    local detectionRadius = artasylumConfig.lights.render.radius * 2
    if Utils.distanceCheck(sourcePlayer, artasylumConfig.lights.render.coords, detectionRadius) then
        if not activeArtasylumContract.alarmTriggered then
            triggerAlarm()
        end
    end
end)

RegisterNetEvent("lunar_contracts:artasylum:activateDecryption")
AddEventHandler("lunar_contracts:artasylum:activateDecryption", function()
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activeArtasylumContract then return end
    if not Utils.distanceCheck(sourcePlayer, artasylumConfig.officeComputers.main, 3.0) then return end
    if not IsPlayerInContract(sourcePlayer, activeArtasylumContract.contractIndex) then return end
    
    if artasylumConfig.officeComputers.requiredItem and not player:hasItem(artasylumConfig.officeComputers.requiredItem) then
        return
    end
    
    if activeArtasylumContract.decryptionActivated then return end
    
    activeArtasylumContract.decryptionActivated = true
    TriggerClientEvent("lunar_contracts:artasylum:decryptionActivated", -1)
end)

RegisterNetEvent("lunar_contracts:artasylum:decryptCode")
AddEventHandler("lunar_contracts:artasylum:decryptCode", function(computerIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activeArtasylumContract then return end
    if not Utils.distanceCheck(sourcePlayer, artasylumConfig.officeComputers.other[computerIndex], 3.0) then return end
    if not IsPlayerInContract(sourcePlayer, activeArtasylumContract.contractIndex) then return end
    
    if artasylumConfig.officeComputers.requiredItem and not player:hasItem(artasylumConfig.officeComputers.requiredItem) then
        return
    end
    
    if not activeArtasylumContract.decryptionActivated then return end
    
    activeArtasylumContract.decryptedTotal = activeArtasylumContract.decryptedTotal + 1
    
    TriggerClientEvent("lunar_contracts:artasylum:foundCode", -1, computerIndex, activeArtasylumContract.codes[computerIndex])
    
    if activeArtasylumContract.decryptedTotal == #artasylumConfig.officeComputers.other then
        ShowContractObjective(activeArtasylumContract.contractIndex, locale("artasylum_title"), locale("obj_unlock_vault"))
    end
end)

lib.callback.register("lunar_contracts:artasylum:enterVaultCode", function(playerId, keypadIndex, enteredCode)
    local player = Framework.getPlayerFromId(playerId)
    
    if not activeArtasylumContract or not player then return end
    if not Utils.distanceCheck(playerId, artasylumConfig.vault.keypads[keypadIndex], 5.0) then return end
    if not IsPlayerInContract(playerId, activeArtasylumContract.contractIndex) then return end
    if not activeArtasylumContract.codes[keypadIndex] then return end
    if activeArtasylumContract.entered[keypadIndex] then return end
    
    if activeArtasylumContract.codes[keypadIndex] ~= enteredCode then
        return false, locale("wrong_code")
    end
    
    activeArtasylumContract.entered[keypadIndex] = true
    
    if Utils.getTableSize(activeArtasylumContract.entered) == #artasylumConfig.vault.keypads then
        vaultDoor.set(false)
        activeArtasylumContract.loot = Loot.new(artasylumConfig.vault.loot)
        TriggerClientEvent("lunar_contracts:artasylum:removeVaultKeypads", -1)
        FinishContract(activeArtasylumContract.contractIndex)
        TriggerClientEvent("lunar_contracts:artasylum:finished", -1)
        
        ShowContractObjective(activeArtasylumContract.contractIndex, locale("artasylum_title"), locale("obj_contract_completed_loot"))
        
        SetTimeout(60000, function()
            HideContractObjective(activeArtasylumContract.contractIndex)
        end)
    end
    
    return true
end)

local safeLootInProgress = false

local function lootSafe(playerObj)
    if not activeArtasylumContract or safeLootInProgress then return false end
    
    safeLootInProgress = true
    
    local collectedItems = {}
    
    while #activeArtasylumContract.safeLoot > 0 do
        local loot = activeArtasylumContract.safeLoot[1]
        
        if loot.item then
            if not playerObj:canCarryItem(loot.item, loot.count) then
                TriggerClientEvent("lunar_contracts:artasylum:setSafeAsLootable", -1)
                
                if #collectedItems > 0 then
                    LogItem(playerObj.source, string.format([[
Looted the Art Asylum safe.
Items: %s]], table.concat(collectedItems, ", ")))
                end
                
                safeLootInProgress = false
                return false
            end
            
            if not playerObj:addItem(loot.item, loot.count, loot.metadata) then
                TriggerClientEvent("lunar_contracts:artasylum:setSafeAsLootable", -1)
                
                if #collectedItems > 0 then
                    LogItem(playerObj.source, string.format([[
Looted the Art Asylum safe.
Items: %s]], table.concat(collectedItems, ", ")))
                end
                
                safeLootInProgress = false
                return false
            end
        elseif loot.account then
            playerObj:addAccountMoney(loot.account, loot.count)
        end
        
        table.insert(collectedItems, string.format("%sx %s", loot.count, loot.item or loot.account))
        table.remove(activeArtasylumContract.safeLoot, 1)
    end
    
    LogItem(playerObj.source, string.format([[
Looted the Art Asylum safe.
Items: %s]], table.concat(collectedItems, ", ")))
    
    safeLootInProgress = false
    return true
end

RegisterNetEvent("lunar_contracts:artasylum:openSafe")
AddEventHandler("lunar_contracts:artasylum:openSafe", function()
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not activeArtasylumContract or not player then return end
    if not IsPlayerInContract(sourcePlayer, activeArtasylumContract.contractIndex) then return end
    if not Utils.distanceCheck(sourcePlayer, artasylumConfig.safe.coords, 3.0) then return end
    
    if not activeArtasylumContract.safeOpened then
        TriggerClientEvent("lunar_contracts:artasylum:setSafeOpen", -1)
        activeArtasylumContract.safeOpened = true
    end
    
    if not lootSafe(player) then return end
    
    TriggerClientEvent("lunar_contracts:artasylum:removeSafe", -1)
end)

RegisterNetEvent("lunar_contracts:artasylum:stealPainting")
AddEventHandler("lunar_contracts:artasylum:stealPainting", function(paintingIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local paintingCoords = artasylumConfig.paintings.locations[paintingIndex]
    
    if not player then return end
    if not activeArtasylumContract then return end
    if not activeArtasylumContract.paintings[paintingIndex] then return end
    if not IsPlayerInContract(sourcePlayer, activeArtasylumContract.contractIndex) then return end
    if not Utils.distanceCheck(sourcePlayer, paintingCoords, 3.0) then return end
    
    if not player:canCarryItem(artasylumConfig.paintings.item, 1) then
        LR.notify(sourcePlayer, locale("inventory_full"), "error")
        return
    end
    
    if player:addItem(artasylumConfig.paintings.item, 1) then
        activeArtasylumContract.paintings[paintingIndex] = false
        TriggerClientEvent("lunar_contracts:artasylum:setPaintingLooted", -1, paintingIndex)
        LogItem(player.source, "Stole a painting inside the Art Asylum.")
    else
        LR.notify(sourcePlayer, locale("inventory_full"), "error")
    end
end)

RegisterNetEvent("lunar_contracts:artasylum:hackSensor")
AddEventHandler("lunar_contracts:artasylum:hackSensor", function(sensorIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    sensorIndex = tonumber(sensorIndex)
    
    if not player then return end
    if not activeArtasylumContract then return end
    if not sensorIndex then return end
    if sensorIndex <= 0 or sensorIndex > #artasylumConfig.noiseSensors then return end
    if not IsPlayerInContract(sourcePlayer, activeArtasylumContract.contractIndex) then return end
    
    if not isPlayerNearCameraDesk(sourcePlayer) then return end
    if activeArtasylumContract.disabledSensors[sensorIndex] then return end

    activeArtasylumContract.disabledSensors[sensorIndex] = true
    TriggerClientEvent("lunar_contracts:artasylum:sensorDisabled", -1, sensorIndex)
end)

RegisterNetEvent("lunar_contracts:artasylum:updateAlertLevel")
AddEventHandler("lunar_contracts:artasylum:updateAlertLevel", function(alertLevel)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activeArtasylumContract then return end
    if alertLevel <= activeArtasylumContract.alertLevel then return end
    if activeArtasylumContract.alarmTriggered then return end
    if not IsPlayerInContract(sourcePlayer, activeArtasylumContract.contractIndex) then return end
    
    if alertLevel >= 1.0 then
        triggerAlarm()
    else
        activeArtasylumContract.alertLevel = alertLevel
        TriggerClientEvent("lunar_contracts:artasylum:updateAlertLevel", -1, alertLevel)
    end
end)

RegisterNetEvent("lunar_contracts:artasylum:openSewerDoor")
AddEventHandler("lunar_contracts:artasylum:openSewerDoor", function(doorIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activeArtasylumContract then return end
    
    local doorCoords = artasylumConfig.sewerDoors.locations[doorIndex].coords
    if not Utils.distanceCheck(sourcePlayer, doorCoords, 5.0) then return end
    if not sewerDoors:get(doorIndex) then return end
    
    sewerDoors:set(doorIndex, false)
    TriggerClientEvent("lunar_contracts:artasylum:removeSewerDoor", -1, doorIndex)
end)

local function spawnElectricBox()
    local coords = artasylumConfig.genericDoors.electricBox.coords
    local box = CreateObjectNoOffset(artasylumConfig.genericDoors.electricBox.model, coords.x, coords.y, coords.z - 1.0, true, false, false)
    SetEntityHeading(box, coords.w + 180.0)
    table.insert(spawnedEntities, box)
end

local function spawnPaintings()
    local paintingModels = {
        1860271043, 645688058, 876512894, 158478566, 397364576,
        -274367155, -33875464, -1302822220, -526786762, -2120801998
    }
    
    local modelIndex = math.random(#paintingModels)
    local paintingNetIds = {}
    
    for i = 1, #artasylumConfig.paintings.locations do
        local coords = Utils.offsetCoords(artasylumConfig.paintings.locations[i], 0.0, 0.05, 0.0)
        local painting = CreateObjectNoOffset(paintingModels[modelIndex], coords.x, coords.y, coords.z - 0.5, true, false, false)
        SetEntityHeading(painting, coords.w)
        table.insert(spawnedEntities, painting)
        table.insert(paintingNetIds, NetworkGetNetworkIdFromEntity(painting))
        
        modelIndex = modelIndex + 1
        if modelIndex > #paintingModels then modelIndex = 1 end
    end
    
    TriggerClientEvent("lunar_contracts:artasylum:syncRoomId", -1, paintingNetIds)
end

local function resetDoors()
    keypadDoors:setAll(true)
    securityDoors:setAll(true)
    genericDoors:setAll(true)
    vaultDoor.set(true)
    sewerDoors:setAll(true)
end

local function cleanup()
    if not activeArtasylumContract then return end
    
    if activeArtasylumContract.loot then
        activeArtasylumContract.loot:remove()
    end
    
    resetDoors()
    cleanUpEntities()
    
    TriggerClientEvent("lunar_contracts:artasylum:reset", -1)
    HideContractObjective(activeArtasylumContract.contractIndex)
    DeleteContract(activeArtasylumContract.contractIndex)
    
    activeArtasylumContract = nil
end

local function startContract()
    if not activeArtasylumContract then return end
    
    resetDoors()
    spawnElectricBox()
    spawnPaintings()
    
    ShowContractObjective(activeArtasylumContract.contractIndex, locale("artasylum_title"), locale("obj_go_to_surveilance"))
    
    SetTimeout(artasylumConfig.duration * 60000, cleanup)
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
        artasylumConfig.genericDoors.electricBox.requiredItem,
        artasylumConfig.keypadDoors.requiredItem,
        artasylumConfig.officeComputers.requiredItem,
        artasylumConfig.securityDoors.requiredItem
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
    local safeLoot = {}
    for _, reward in ipairs(artasylumConfig.safe.rewards) do
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
    for i = 1, #artasylumConfig.paintings.locations do
        paintings[i] = true
    end
    
    local codes = {}
    for i = 1, 6 do
        codes[i] = generateRandomNumericCode(6)
    end
    
    activeArtasylumContract = {
        contractIndex = contractId,
        alarmTriggered = false,
        decryptionActivated = false,
        codes = codes,
        entered = {},
        safeLoot = safeLoot,
        safeOpened = false,
        paintings = paintings,
        alertLevel = 0.0,
        disabledSensors = {},
        decryptedTotal = 0
    }
end

Missions.artasylum = {}

function Missions.artasylum.canBeGenerated()
    return activeArtasylumContract == nil
end

function Missions.artasylum.generated(contractId)
    createContract(contractId)
    
    local metadata = {
        { left = locale("reward"), right = locale("reward_artasylum") },
        { left = locale("required_tools"), right = getRequiredToolsText() }
    }
    
    return artasylumConfig.image, metadata
end

Missions.artasylum.deleted = cleanup

function Missions.artasylum.cancelled(contractId)
    TriggerClientEvent("lunar_contracts:artasylum:reset", -1)
    HideContractObjective(contractId)
end

function Missions.artasylum.start(contractId, data)
    if not activeArtasylumContract then return end
    
    local members = data.members
    TriggerClientEvent("lunar_contracts:artasylum:started", -1, members)
    TriggerEvent("lunar_contracts:artasylum:announceStarted", contractId, members)
    
    startContract()
end

function Missions.artasylum.getSaveData(contractId)
    if not activeArtasylumContract then
        error("Can't fetch save data from the art asylum contract.")
    end
    
    return { contractIndex = contractId }
end

function Missions.artasylum.loadSaveData(data)
    createContract(data.contractIndex)
end

function Missions.artasylum.getCancelPoint(contractId)
    return artasylumConfig.cancelPoint
end
