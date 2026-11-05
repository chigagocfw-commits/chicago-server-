local mazebankConfig = Config.contracts.mazebank

local activeMazebankContract = nil
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

local securityDoors = RegisterDoors(mazebankConfig.securityDoors.locations)

local sewerDoors = nil
if mazebankConfig.sewers then
    sewerDoors = RegisterDoorsWithModel(mazebankConfig.sewers.doors.locations, mazebankConfig.sewers.doors.model)
end

local keypadDoors = RegisterDoorsWithModel(mazebankConfig.keypadDoors.doors.locations, mazebankConfig.keypadDoors.doors.model)

local elevatorDoor = nil
if mazebankConfig.elevator then
    local elevatorController = RegisterDoors(mazebankConfig.elevator.door)
    elevatorDoor = {
        set = function(locked)
            elevatorController:setAll(locked)
        end,
        get = function()
            return elevatorController:get(1)
        end
    }
end

local basementDoors = RegisterDoors(mazebankConfig.basement.doors)

-- Initialize all doors to locked state on startup
CreateThread(function()
    Wait(1000)
    securityDoors:setAll(true)
    if sewerDoors then
        sewerDoors:setAll(true)
    end
    keypadDoors:setAll(true)
    if elevatorDoor then
        elevatorDoor.set(true)
    end
    basementDoors:setAll(true)
    if Config and Config.debug then print("[Mazebank] All mazebank doors locked on startup") end
end)

RegisterNetEvent("lunar_contracts:mazebank:openSecurityDoor")
AddEventHandler("lunar_contracts:mazebank:openSecurityDoor", function(doorIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local doorLocation = mazebankConfig.securityDoors.locations[doorIndex]
    
    if not player then return end
    if not activeMazebankContract then return end
    if not securityDoors:get(doorIndex) then return end
    
    if mazebankConfig.securityDoors.requiredItem and not player:hasItem(mazebankConfig.securityDoors.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activeMazebankContract.contractIndex) then return end
    if not Utils.distanceCheck(sourcePlayer, GetDoorCoords(doorLocation), 5.0) then return end
    
    if mazebankConfig.securityDoors.requiredItem and mazebankConfig.securityDoors.removeAfterUse then
        player:removeItem(mazebankConfig.securityDoors.requiredItem, 1)
    end
    
    securityDoors:set(doorIndex, false)
    TriggerClientEvent("lunar_contracts:mazebank:removeSecurityDoor", -1, doorIndex)
end)

lib.callback.register("lunar_contracts:mazebank:openKeypadDoor", function(playerId, keypadIndex, enteredCode)
    local keypadCoords = mazebankConfig.keypadDoors.keypads[keypadIndex]
    
    if not activeMazebankContract or not keypadCoords then return false end
    if not keypadDoors:get(keypadIndex) then return false end
    if not IsPlayerInContract(playerId, activeMazebankContract.contractIndex) then return false end
    if not Utils.distanceCheck(playerId, keypadCoords, 5.0) then return false end
    
    if enteredCode == activeMazebankContract.codes[keypadIndex] then
        keypadDoors:set(keypadIndex, false)
        TriggerClientEvent("lunar_contracts:mazebank:removeKeypad", -1, keypadIndex)
        
        local allUnlocked = true
        for i = 1, #mazebankConfig.keypadDoors.keypads do
            if keypadDoors:get(i) then
                allUnlocked = false
                break
            end
        end
        
        if allUnlocked then
            ShowContractObjective(activeMazebankContract.contractIndex, locale("mazebank_title"), locale("obj_unlock_from_terminal"))
        end
        
        return true
    end
    
    return false
end)

RegisterNetEvent("lunar_contracts:mazebank:openedElevatorDoor")
AddEventHandler("lunar_contracts:mazebank:openedElevatorDoor", function()
    local sourcePlayer = source
    
    if not mazebankConfig.elevator then return end
    if not activeMazebankContract then return end
    if not elevatorDoor or not elevatorDoor.get() then return end
    if not IsPlayerInContract(sourcePlayer, activeMazebankContract.contractIndex) then return end
    
    if not Utils.distanceCheck(sourcePlayer, GetDoorCoords(mazebankConfig.elevator.door), 5.0) then return end
    
    elevatorDoor.set(false)
    TriggerClientEvent("lunar_contracts:mazebank:removeElevatorDoor", -1)
end)

RegisterNetEvent("lunar_contracts:mazebank:disableGenerator")
AddEventHandler("lunar_contracts:mazebank:disableGenerator", function(generatorIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not mazebankConfig.sewers then return end
    
    local generatorCoords = mazebankConfig.sewers.generators.locations[generatorIndex]
    if not player then return end
    if not activeMazebankContract then return end
    if activeMazebankContract.disabledGenerators[generatorIndex] then return end
    
    if mazebankConfig.sewers.generators.requiredItem and not player:hasItem(mazebankConfig.sewers.generators.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activeMazebankContract.contractIndex) then return end
    if not Utils.distanceCheck(sourcePlayer, generatorCoords, 5.0) then return end
    
    if mazebankConfig.sewers.generators.requiredItem and mazebankConfig.sewers.generators.removeAfterUse then
        player:removeItem(mazebankConfig.sewers.generators.requiredItem, 1)
    end
    
    activeMazebankContract.disabledGenerators[generatorIndex] = true
    TriggerClientEvent("lunar_contracts:mazebank:removeGenerator", -1, generatorIndex)
    
    for _, disabled in ipairs(activeMazebankContract.disabledGenerators) do
        if not disabled then return end
    end
    
    sewerDoors:setAll(false)
    LR.notify(sourcePlayer, locale("sewer_locks_disabled"), "success")
end)

RegisterNetEvent("lunar_contracts:mazebank:disableLasers")
AddEventHandler("lunar_contracts:mazebank:disableLasers", function()
    local sourcePlayer = source
    
    if not activeMazebankContract then return end
    if not IsPlayerInContract(sourcePlayer, activeMazebankContract.contractIndex) then return end
    
    if not Utils.distanceCheck(sourcePlayer, mazebankConfig.lasers.electricBox.coords, 5.0) then return end
    
    activeMazebankContract.lasersDisabled = true
    TriggerClientEvent("lunar_contracts:mazebank:disableLasers", -1)
end)

RegisterNetEvent("lunar_contracts:mazebank:hackedLaptop")
AddEventHandler("lunar_contracts:mazebank:hackedLaptop", function(laptopIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activeMazebankContract then return end
    
    if mazebankConfig.keypadDoors.laptops.requiredItem and not player:hasItem(mazebankConfig.keypadDoors.laptops.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activeMazebankContract.contractIndex) then return end
    if not Utils.distanceCheck(sourcePlayer, activeMazebankContract.laptops[laptopIndex], 5.0) then return end
    
    if mazebankConfig.keypadDoors.laptops.requiredItem and mazebankConfig.keypadDoors.laptops.removeAfterUse then
        player:removeItem(mazebankConfig.keypadDoors.laptops.requiredItem, 1)
    end
    
    TriggerClientEvent("lunar_contracts:mazebank:showCode", sourcePlayer, locale("code_for_" .. laptopIndex), activeMazebankContract.codes[laptopIndex])
end)

RegisterNetEvent("lunar_contracts:mazebank:triggerAlarm")
AddEventHandler("lunar_contracts:mazebank:triggerAlarm", function()
    local sourcePlayer = source
    
    if not activeMazebankContract then return end
    if activeMazebankContract.lasersDisabled then return end
    if activeMazebankContract.alarm then return end
    if not IsPlayerInContract(sourcePlayer, activeMazebankContract.contractIndex) then return end
    
    if not Utils.distanceCheck(sourcePlayer, mazebankConfig.lasers.render.coords, mazebankConfig.lasers.render.radius) then return end
    
    activeMazebankContract.alarm = true
    TriggerClientEvent("lunar_contracts:mazebank:alarmTriggered", -1)
    
    if mazebankConfig.dispatch.enabled then
        Dispatch.call(mazebankConfig.alarm.coords, {
            Code = mazebankConfig.dispatch.code,
            Title = mazebankConfig.dispatch.title,
            Message = mazebankConfig.dispatch.message
        })
    end
end)

RegisterNetEvent("lunar_contracts:mazebank:unlockBasementDoor")
AddEventHandler("lunar_contracts:mazebank:unlockBasementDoor", function(doorCode)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local lowerDoorCode = doorCode:lower()
    
    if not player then return end
    if not activeMazebankContract then return end
    
    if mazebankConfig.serverRoomTerminal.requiredItem and not player:hasItem(mazebankConfig.serverRoomTerminal.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activeMazebankContract.contractIndex) then return end
    if not Utils.distanceCheck(sourcePlayer, mazebankConfig.serverRoomTerminal.coords, 5.0) then return end
    
    for i, storedCode in ipairs(activeMazebankContract.basementDoorCodes) do
        if storedCode:lower() == lowerDoorCode then
            local doorConfig = mazebankConfig.basement.doors[i]
            if basementDoors:get(i) then
                if doorConfig.shouldScramble and not activeMazebankContract.overloadedCircuit then
                    return
                end
                
                local hackSuccess = lib.callback.await("lunar_contracts:mazebank:basementDoorHack", sourcePlayer)
                if hackSuccess then
                    if mazebankConfig.serverRoomTerminal.requiredItem then
                        if not player:hasItem(mazebankConfig.serverRoomTerminal.requiredItem) then return end
                        if mazebankConfig.serverRoomTerminal.removeAfterUse then
                            player:removeItem(mazebankConfig.serverRoomTerminal.requiredItem)
                        end
                    end
                    
                    if doorConfig.unlocks then
                        activeMazebankContract.loot:setUnlocked(doorConfig.unlocks, true)
                    end
                    
                    basementDoors:set(i, false)
                    
                    if doorConfig.triggersReward then
                        FinishContract(activeMazebankContract.contractIndex)
                        ShowContractObjective(activeMazebankContract.contractIndex, locale("mazebank_title"), locale("obj_contract_completed_loot"))
                        
                        SetTimeout(60000, function()
                            HideContractObjective(activeMazebankContract.contractIndex)
                        end)
                        
                        if mazebankConfig.dispatch.enabled and not activeMazebankContract.alarm then
                            LR.notify(sourcePlayer, locale("silent_alarm_in"):format(mazebankConfig.alarm.silentDelay), "warning")
                            SetTimeout(mazebankConfig.alarm.silentDelay * 60000, function()
                                if mazebankConfig.dispatch.enabled and not activeMazebankContract.alarm then
                                    Dispatch.call(mazebankConfig.alarm.coords, {
                                        Code = mazebankConfig.dispatch.code,
                                        Title = mazebankConfig.dispatch.title,
                                        Message = mazebankConfig.dispatch.message
                                    })
                                end
                            end)
                        end
                    end
                end
                return
            end
        end
    end
    
    LR.notify(sourcePlayer, locale("door_doesnt_exist"), "error")
end)

RegisterNetEvent("lunar_contracts:mazebank:overloadedCircuit")
AddEventHandler("lunar_contracts:mazebank:overloadedCircuit", function()
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activeMazebankContract then return end
    
    if mazebankConfig.basement.circuitOverload.requiredItem and not player:hasItem(mazebankConfig.basement.circuitOverload.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activeMazebankContract.contractIndex) then return end
    if not Utils.distanceCheck(sourcePlayer, mazebankConfig.basement.circuitOverload.coords, 3.0) then return end
    if activeMazebankContract.overloadedCircuit then return end
    
    if mazebankConfig.basement.circuitOverload.requiredItem and mazebankConfig.basement.circuitOverload.removeAfterUse then
        player:removeItem(mazebankConfig.basement.circuitOverload.requiredItem, 1)
    end
    
    activeMazebankContract.overloadedCircuit = true
    TriggerClientEvent("lunar_contracts:mazebank:removeCircuit", -1)
    TriggerClientEvent("lunar_contracts:mazebank:circuitOverloaded", -1)
end)

local lootInProgress = {}

local function lootMiniSafe(playerObj, safeIndex)
    if not activeMazebankContract or lootInProgress[safeIndex] then return false end
    
    lootInProgress[safeIndex] = true
    
    local safeLoot = activeMazebankContract.miniSafes[safeIndex]
    local collectedItems = {}
    
    while #safeLoot > 0 do
        local loot = safeLoot[1]
        
        if loot.item then
            if not playerObj:canCarryItem(loot.item, loot.count) then
                TriggerClientEvent("lunar_contracts:laundromat:setSafeAsLootable", -1)
                LR.notify(playerObj.source, locale("inventory_full"), "error")
                
                if #collectedItems > 0 then
                    LogItem(playerObj.source, string.format([[
Looted one of the Maze Bank safes.
Items: %s]], table.concat(collectedItems, ", ")))
                end
                
                lootInProgress[safeIndex] = nil
                return false
            end
            
            if not playerObj:addItem(loot.item, loot.count, loot.metadata) then
                TriggerClientEvent("lunar_contracts:laundromat:setSafeAsLootable", -1)
                LR.notify(playerObj.source, locale("inventory_full"), "error")
                
                if #collectedItems > 0 then
                    LogItem(playerObj.source, string.format([[
Looted one of the Maze Bank safes.
Items: %s]], table.concat(collectedItems, ", ")))
                end
                
                lootInProgress[safeIndex] = nil
                return false
            end
        elseif loot.account then
            playerObj:addAccountMoney(loot.account, loot.count)
        end
        
        table.insert(collectedItems, string.format("%sx %s", loot.count, loot.item or loot.account))
        table.remove(safeLoot, 1)
    end
    
    LogItem(playerObj.source, string.format([[
Looted one of the Maze Bank safes.
Items: %s]], table.concat(collectedItems, ", ")))
    
    lootInProgress[safeIndex] = nil
    return true
end

RegisterNetEvent("lunar_contracts:mazebank:openMiniSafe")
AddEventHandler("lunar_contracts:mazebank:openMiniSafe", function(safeIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not activeMazebankContract or not player then return end
    if not IsPlayerInContract(sourcePlayer, activeMazebankContract.contractIndex) then return end
    
    if not mazebankConfig.miniSafe then return end
    
    local safeCoords = mazebankConfig.miniSafe.locations[safeIndex]
    if not Utils.distanceCheck(sourcePlayer, safeCoords, 5.0) then return end
    
    if not lootMiniSafe(player, safeIndex) then return end
    
    TriggerClientEvent("lunar_contracts:mazebank:removeMiniSafe", -1, safeIndex)
end)

local garageDoor = RegisterDoorWithModel(mazebankConfig.garage.door.coords, mazebankConfig.garage.door.model)

-- Initialize garage door to locked state on startup
CreateThread(function()
    Wait(1500)
    garageDoor.set(true)
    if Config and Config.debug then print("[Mazebank] Garage door locked on startup") end
end)

RegisterNetEvent("lunar_contracts:mazebank:toggleGarageDoor")
AddEventHandler("lunar_contracts:mazebank:toggleGarageDoor", function()
    local sourcePlayer = source
    
    if not activeMazebankContract then return end
    if not IsPlayerInContract(sourcePlayer, activeMazebankContract.contractIndex) then return end
    
    local isOpen = not garageDoor.get()
    garageDoor.set(isOpen)
    TriggerClientEvent("lunar_contracts:mazebank:setGarageDoorOpen", -1, isOpen)
    
    LR.notify(sourcePlayer, isOpen and locale("garage_closed") or locale("garage_opened"), "success")
end)

local function spawnElectricBox()
    local coords = mazebankConfig.lasers.electricBox.coords
    local box = CreateObjectNoOffset(mazebankConfig.lasers.electricBox.model, coords.x, coords.y, coords.z - 1.0, true, false, false)
    SetEntityHeading(box, coords.w + 180.0)
    table.insert(spawnedEntities, box)
end

local function spawnLaptops(locations)
    for _, coords in ipairs(locations) do
        local laptop = CreateObjectNoOffset(mazebankConfig.keypadDoors.laptops.model, coords.x, coords.y, coords.z, true, false, false)
        SetEntityHeading(laptop, coords.w)
        table.insert(spawnedEntities, laptop)
    end
end

local function resetDoors()
    securityDoors:setAll(true)
    if sewerDoors then sewerDoors:setAll(true) end
    keypadDoors:setAll(true)
    if elevatorDoor then elevatorDoor.set(true) end
    basementDoors:setAll(true)
    garageDoor.set(true)
end

local function cleanup()
    if not activeMazebankContract then return end
    
    resetDoors()
    cleanUpEntities()
    
    if activeMazebankContract.loot then
        activeMazebankContract.loot:remove()
    end
    
    TriggerClientEvent("lunar_contracts:mazebank:reset", -1)
    HideContractObjective(activeMazebankContract.contractIndex)
    DeleteContract(activeMazebankContract.contractIndex)
    
    activeMazebankContract = nil
end

local function startContract()
    if not activeMazebankContract then return end
    
    resetDoors()
    
    -- Unlock always-open basement doors
    for i, door in ipairs(mazebankConfig.basement.doors) do
        if door.alwaysOpen then
            basementDoors:set(i, false)
        end
    end
    
    spawnElectricBox()
    spawnLaptops(activeMazebankContract.laptops)
    TriggerClientEvent("lunar_contracts:mazebank:createLasers", -1)
    
    ShowContractObjective(activeMazebankContract.contractIndex, locale("mazebank_title"), locale("obj_hack_laptops"))
    
    activeMazebankContract.loot = Loot.new(mazebankConfig.basement.loot)
    
    SetTimeout(mazebankConfig.duration * 60000, cleanup)
end

local function generateRandomNumericCode(length)
    local code = ""
    for _ = 1, length do
        local digit = math.random(#"0123456789")
        code = code .. ("0123456789"):sub(digit, digit)
    end
    return code
end

local function generateRandomHexCode(length)
    local code = ""
    for _ = 1, length do
        local digit = math.random(#"0123456789ABCDEF")
        code = code .. ("0123456789ABCDEF"):sub(digit, digit)
    end
    return "0x" .. code
end

local function getRequiredToolsText()
    local tools = {}
    local requiredItems = {
        mazebankConfig.keypadDoors.laptops.requiredItem,
        mazebankConfig.securityDoors.requiredItem,
        mazebankConfig.serverRoomTerminal.requiredItem
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
    local generators = {}
    if mazebankConfig.sewers then
        for i = 1, #mazebankConfig.sewers.generators do
            generators[i] = false
        end
    end
    
    local keypadCodes = {}
    for i = 1, #mazebankConfig.keypadDoors.keypads do
        keypadCodes[i] = generateRandomNumericCode(6)
    end
    
    local laptopLocations = {}
    local laptopLocationList = {}
    for _ = 1, #mazebankConfig.keypadDoors.keypads do
        local location
        repeat
            location = Utils.randomFromTable(mazebankConfig.keypadDoors.laptops.locations)
        until not lib.table.contains(laptopLocationList, location)
        table.insert(laptopLocationList, location)
    end
    
    local doorCodes = {}
    for i = 1, #mazebankConfig.basement.doors do
        doorCodes[i] = generateRandomHexCode(6)
    end
    
    local miniSafes = {}
    if mazebankConfig.miniSafe then
        for i = 1, #mazebankConfig.miniSafe.locations do
            local safeLoot = {}
            for _, reward in ipairs(mazebankConfig.miniSafe.rewards) do
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
            miniSafes[i] = safeLoot
        end
    end
    
    activeMazebankContract = {
        contractIndex = contractId,
        generators = generators,
        disabledGenerators = {},
        laptops = laptopLocationList,
        codes = keypadCodes,
        lasersDisabled = false,
        alarm = false,
        basementDoorCodes = doorCodes,
        overloadedCircuit = false,
        opened = false,
        miniSafes = miniSafes
    }
end

Missions.mazebank = {}

function Missions.mazebank.canBeGenerated()
    return activeMazebankContract == nil
end

function Missions.mazebank.generated(contractId)
    createContract(contractId)
    
    local metadata = {
        { left = locale("reward"), right = locale("reward_mazebank") },
        { left = locale("required_tools"), right = getRequiredToolsText() }
    }
    
    return mazebankConfig.image, metadata
end

Missions.mazebank.deleted = cleanup

function Missions.mazebank.cancelled(contractId)
    TriggerClientEvent("lunar_contracts:mazebank:reset", -1)
    HideContractObjective(contractId)
end

function Missions.mazebank.start(contractId, data)
    if not activeMazebankContract then return end
    
    local members = data.members
    TriggerClientEvent("lunar_contracts:mazebank:started", -1, members, activeMazebankContract.laptops, activeMazebankContract.basementDoorCodes)
    TriggerEvent("lunar_contracts:mazebank:announceStarted", contractId, members)
    
    startContract()
end

function Missions.mazebank.getSaveData(contractId)
    if not activeMazebankContract then
        error("Can't fetch save data from the maze bank contract.")
    end
    
    return { contractIndex = contractId }
end

function Missions.mazebank.loadSaveData(data)
    createContract(data.contractIndex)
end

function Missions.mazebank.getCancelPoint(contractId)
    return mazebankConfig.cancelPoint
end
