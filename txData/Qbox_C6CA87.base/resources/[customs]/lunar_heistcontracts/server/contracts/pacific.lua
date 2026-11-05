local pacificConfig = Config.contracts.pacific

local activePacificContract = nil
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

local genericDoors = RegisterDoorsWithModel(pacificConfig.genericDoors.locations, pacificConfig.genericDoors.model)
local officeDoors = RegisterDoorsWithModel(pacificConfig.offices.doors.locations, pacificConfig.offices.doors.model)
local mainOfficeDoor = RegisterDoorWithModel(pacificConfig.mainOffice.door.locations, pacificConfig.mainOffice.door.model)

-- Initialize all doors to locked state on startup
CreateThread(function()
    Wait(1000)
    genericDoors:setAll(true)
    officeDoors:setAll(true)
    mainOfficeDoor.set(true)
    if Config and Config.debug then print("[Pacific] Main floor doors locked on startup") end
end)

local function updateContractObjective()
    if not activePacificContract then return end
    
    local codeDisplay = ""
    local hackedCount = 0
    
    for i = 1, #pacificConfig.offices.computers do
        if activePacificContract.hackedComputers[i] then
            local startPos = (i - 1) * 2 + 1
            local codePart = activePacificContract.code:sub(startPos, startPos + 1)
            codeDisplay = codeDisplay .. codePart
            hackedCount = hackedCount + 1
        else
            codeDisplay = codeDisplay .. "__"
        end
    end
    
    local objectiveText = (hackedCount == #pacificConfig.offices.computers) 
        and locale("obj_open_office_safe_and_hack") 
        or locale("obj_hack_top_offices")
    
    ShowContractObjective(activePacificContract.contractIndex, locale("pacific_title"), objectiveText, codeDisplay)
end

RegisterNetEvent("lunar_contracts:pacific:openGenericDoors")
AddEventHandler("lunar_contracts:pacific:openGenericDoors", function()
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activePacificContract then return end
    
    if pacificConfig.genericDoors.requiredItem and not player:hasItem(pacificConfig.genericDoors.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activePacificContract.contractIndex) then return end
    
    if not Utils.distanceCheck(sourcePlayer, pacificConfig.genericDoors.terminal.coords, 3.0) then return end
    
    if pacificConfig.genericDoors.requiredItem and pacificConfig.genericDoors.removeAfterUse then
        player:removeItem(pacificConfig.genericDoors.requiredItem, 1)
    end
    
    TriggerClientEvent("lunar_contracts:pacific:removeTerminal", -1)
    genericDoors:setAll(false)
end)

RegisterNetEvent("lunar_contracts:pacific:hackedKeypad")
AddEventHandler("lunar_contracts:pacific:hackedKeypad", function(keypadIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activePacificContract then return end
    
    if pacificConfig.offices.requiredItem and not player:hasItem(pacificConfig.offices.requiredItem) then
        return
    end
    
    if not IsPlayerInContract(sourcePlayer, activePacificContract.contractIndex) then return end
    
    local maxOfficeKeypads = #pacificConfig.offices.keypads
    
    if keypadIndex <= maxOfficeKeypads then
        if not Utils.distanceCheck(sourcePlayer, pacificConfig.offices.keypads[keypadIndex], 3.0) then return end
        officeDoors:set(keypadIndex, false)
        TriggerClientEvent("lunar_contracts:pacific:officeUnlocked", -1, keypadIndex)
    else
        if not Utils.distanceCheck(sourcePlayer, pacificConfig.mainOffice.keypad, 3.0) then return end
        mainOfficeDoor.set(false)
        TriggerClientEvent("lunar_contracts:pacific:mainOfficeUnlocked", -1, keypadIndex)
    end
    
    if pacificConfig.offices.requiredItem and pacificConfig.offices.removeAfterUse then
        player:removeItem(pacificConfig.offices.requiredItem, 1)
    end
end)

RegisterNetEvent("lunar_contracts:pacific:hackedComputer")
AddEventHandler("lunar_contracts:pacific:hackedComputer", function(computerIndex)
    local sourcePlayer = source
    
    if not activePacificContract then return end
    
    if not Utils.distanceCheck(sourcePlayer, pacificConfig.offices.computers[computerIndex], 3.0) then return end
    if not IsPlayerInContract(sourcePlayer, activePacificContract.contractIndex) then return end
    if officeDoors:get(computerIndex) then return end
    
    local startPos = (computerIndex - 1) * 2 + 1
    local codePart = activePacificContract.code:sub(startPos, startPos + 1)
    
    TriggerClientEvent("lunar_contracts:pacific:officeComputerHacked", -1, computerIndex, codePart)
    
    activePacificContract.hackedComputers[computerIndex] = true
    updateContractObjective()
end)

lib.callback.register("lunar_contracts:pacific:openSafe", function(playerId, enteredCode)
    local player = Framework.getPlayerFromId(playerId)
    
    if not player then return end
    if not activePacificContract then return end
    if not IsPlayerInContract(playerId, activePacificContract.contractIndex) then return end
    if not Utils.distanceCheck(playerId, pacificConfig.mainOffice.safe, 5.0) then return end
    if mainOfficeDoor.get() then return end
    if activePacificContract.receivedBlue and activePacificContract.receivedPurple then return end
    
    if activePacificContract.code == enteredCode then
        SetTimeout(2300, function()
            if not activePacificContract.receivedBlue then
                if player:addItem(pacificConfig.basement.enterance.securityPanel.keycard, 2) then
                    activePacificContract.receivedBlue = true
                end
            end
            
            if not activePacificContract.receivedPurple then
                if player:addItem(pacificConfig.basement.mainVault.securityPanel.keycard, 1) then
                    activePacificContract.receivedPurple = true
                end
            end
            
            if activePacificContract.receivedBlue and activePacificContract.receivedPurple then
                TriggerClientEvent("lunar_contracts:pacific:setSafeState", -1, true)
                
                local objectiveText = genericDoors:get(1) and locale("obj_hack_terminal") or locale("obj_go_to_basement")
                ShowContractObjective(activePacificContract.contractIndex, locale("pacific_title"), objectiveText)
                
                LogItem(player.source, "Opened the Pacific Bank safe inside the main office.")
            end
        end)
        return true
    end
    
    return false
end)

local function spawnBasement()
    if not activePacificContract then return end
    
    activePacificContract.loot = Loot.new(pacificConfig.basement.loot)
    TriggerClientEvent("lunar_contracts:pacific:createBasement", -1)
    
    if not pacificConfig.basement.guards.enabled then return end
    
    local selectedPositions = {}
    for i = 1, pacificConfig.basement.guards.count do
        local pos
        repeat
            pos = math.random(#pacificConfig.basement.guards.locations)
        until not lib.table.contains(selectedPositions, pos)
        table.insert(selectedPositions, pos)
    end
    
    local guardNetIds = {}
    
    for i, posIndex in ipairs(selectedPositions) do
        local coords = pacificConfig.basement.guards.locations[posIndex]
        local weapon = Utils.randomFromTable(pacificConfig.basement.guards.weapons)
        local guard = CreatePed(4, pacificConfig.basement.guards.model, coords.x, coords.y, coords.z, coords.w, true, true)
        
        GiveWeaponToPed(guard, joaat(weapon.name), 200, true, true)
        SetPedArmour(guard, 100)
        SetPedRandomComponentVariation(guard, 0)
        
        activePacificContract.guards[i] = {
            netId = NetworkGetNetworkIdFromEntity(guard),
            weapon = weapon
        }
        
        guardNetIds[i] = activePacificContract.guards[i].netId
        table.insert(spawnedEntities, guard)
    end
    
    TriggerClientEvent("lunar_contracts:pacific:handleGuardsLogic", -1, guardNetIds)
    
    if pacificConfig.dispatch.enabled then
        Dispatch.call(pacificConfig.basement.centre, {
            Code = pacificConfig.dispatch.code,
            Title = pacificConfig.dispatch.title,
            Message = pacificConfig.dispatch.message
        })
    end
end

RegisterNetEvent("lunar_contracts:pacific:lootGuard")
AddEventHandler("lunar_contracts:pacific:lootGuard", function(guardNetId)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local guard = NetworkGetEntityFromNetworkId(guardNetId)
    
    if not activePacificContract or not player then return end
    if not DoesEntityExist(guard) then return end
    if not pacificConfig.basement.guards.looting.enabled then return end
    
    if not Utils.distanceCheck(sourcePlayer, GetEntityCoords(guard), 5.0) then return end
    
    for i, guardData in pairs(activePacificContract.guards) do
        if guardData.netId == guardNetId then
            local ammoAmount = math.random(guardData.weapon.ammo.min, guardData.weapon.ammo.max)
            
            if not player:canCarryItem(guardData.weapon.name, 1) or not player:canCarryItem(guardData.weapon.ammo.name, ammoAmount) then
                LR.notify(sourcePlayer, locale("inventory_full"), "error")
                return
            end
            
            activePacificContract.guards[i] = nil
            
            if player:addItem(guardData.weapon.name, 1) then
                player:addItem(guardData.weapon.ammo.name, ammoAmount)
                TriggerClientEvent("lunar_contracts:pacific:guardLooted", -1, guardNetId)
                LogItem(sourcePlayer, string.format([[
Looted a Pacific Bank guard.
Weapon: %s]], guardData.weapon.name:upper()))
            else
                activePacificContract.guards[i] = guardData
                LR.notify(sourcePlayer, locale("inventory_full"), "error")
            end
            return
        end
    end
end)

local basementEnteranceDoors = RegisterDoorsWithModel(
    pacificConfig.basement.enterance.doors.locations,
    pacificConfig.basement.enterance.doors.model
)

local keycardUsers = {}

-- Initialize basement entrance doors to locked state on startup
CreateThread(function()
    Wait(1500)
    basementEnteranceDoors:setAll(true)
    if Config and Config.debug then print("[Pacific] Basement entrance doors locked on startup") end
end)

lib.callback.register("lunar_contracts:pacific:useEnteranceKeycard", function(playerId, doorIndex)
    local player = Framework.getPlayerFromId(playerId)
    
    if not activePacificContract or not player then return end
    if not player:hasItem(pacificConfig.basement.enterance.securityPanel.keycard) then return end
    if not IsPlayerInContract(playerId, activePacificContract.contractIndex) then return end
    
    local panelCoords = pacificConfig.basement.enterance.securityPanel.locations[doorIndex]
    if not Utils.distanceCheck(playerId, panelCoords, 3.0) then return end
    if lib.table.contains(keycardUsers, doorIndex) then return end
    
    player:removeItem(pacificConfig.basement.enterance.securityPanel.keycard, 1)
    keycardUsers[playerId] = doorIndex
    
    if Utils.getTableSize(keycardUsers) == #pacificConfig.basement.enterance.doors.locations then
        SetTimeout(2000, function()
            if Utils.getTableSize(keycardUsers) == #pacificConfig.basement.enterance.doors.locations then
                TriggerClientEvent("lunar_contracts:pacific:stopEnteranceAnimation", -1, true)
                basementEnteranceDoors:setAll(false)
                table.wipe(keycardUsers)
                spawnBasement()
                
                ShowContractObjective(activePacificContract.contractIndex, locale("pacific_title"), locale("obj_open_main_vault"))
            end
        end)
    else
        SetTimeout(5000, function()
            if Utils.getTableSize(keycardUsers) == 1 then
                player:addItem(pacificConfig.basement.enterance.securityPanel.keycard, 1)
                TriggerClientEvent("lunar_contracts:pacific:stopEnteranceAnimation", playerId, false)
                LR.notify(playerId, locale("two_man_keycard_failed"), "error")
                keycardUsers[playerId] = nil
            end
        end)
    end
    
    return true
end)

local sideVaultDoors = RegisterDoorsWithModel(
    pacificConfig.basement.sideVaults.doors.locations,
    pacificConfig.basement.sideVaults.doors.model
)

-- Initialize side vault doors to locked state on startup
CreateThread(function()
    Wait(1500)
    sideVaultDoors:setAll(true)
    if Config and Config.debug then print("[Pacific] Side vault doors locked on startup") end
end)

RegisterNetEvent("lunar_contracts:pacific:openSideVault")
AddEventHandler("lunar_contracts:pacific:openSideVault", function(vaultIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local panelConfig = pacificConfig.basement.sideVaults.securityPanel
    
    if not player then return end
    if not activePacificContract then return end
    
    if panelConfig.requiredItem and not player:hasItem(panelConfig.requiredItem) then return end
    if not IsPlayerInContract(sourcePlayer, activePacificContract.contractIndex) then return end
    
    local panelCoords = panelConfig.locations[vaultIndex]
    if not Utils.distanceCheck(sourcePlayer, panelCoords, 3.0) then return end
    if not sideVaultDoors:get(vaultIndex) then return end
    
    if panelConfig.requiredItem and panelConfig.removeAfterUse then
        player:removeItem(panelConfig.requiredItem, 1)
    end
    
    sideVaultDoors:set(vaultIndex, false)
    activePacificContract.loot:setUnlocked("sideVault" .. vaultIndex, true)
    TriggerClientEvent("lunar_contracts:pacific:removeSideVaultPanel", -1, vaultIndex)
end)

lib.callback.register("lunar_contracts:pacific:openMainVault", function(playerId)
    local player = Framework.getPlayerFromId(playerId)
    
    if not player then return end
    if not activePacificContract then return end
    if activePacificContract.opened then return end
    if not player:hasItem(pacificConfig.basement.mainVault.securityPanel.keycard) then return end
    if not IsPlayerInContract(playerId, activePacificContract.contractIndex) then return end
    
    if not Utils.distanceCheck(playerId, pacificConfig.basement.mainVault.securityPanel.coords, 3.0) then return end
    
    activePacificContract.opened = true
    player:removeItem(pacificConfig.basement.mainVault.securityPanel.keycard, 1)
    
    activePacificContract.loot:setUnlocked("mainVault", true)
    TriggerClientEvent("lunar_contracts:pacific:removeMainVaultPanel", -1)
    
    FinishContract(activePacificContract.contractIndex)
    
    SetTimeout(60000, function()
        HideContractObjective(activePacificContract.contractIndex)
    end)
    
    return true
end)

lib.callback.register("lunar_contracts:pacific:canDrillDepositBox", function(playerId, boxIndex)
    local player = Framework.getPlayerFromId(playerId)
    
    if not player then return false end
    if not activePacificContract then return false end
    if not IsPlayerInContract(playerId, activePacificContract.contractIndex) then return false end
    
    local boxCoords = pacificConfig.basement.drilling.locations[boxIndex]
    if not Utils.distanceCheck(playerId, boxCoords, 5.0) then return false end
    if not activePacificContract.loot then return false end
    if not activePacificContract.depositBoxes[boxIndex] then return false end
    
    for _, reward in ipairs(pacificConfig.basement.drilling.rewards) do
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

RegisterNetEvent("lunar_contracts:pacific:drillDepositBox")
AddEventHandler("lunar_contracts:pacific:drillDepositBox", function(boxIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activePacificContract then return end
    if not IsPlayerInContract(sourcePlayer, activePacificContract.contractIndex) then return end
    
    local boxCoords = pacificConfig.basement.drilling.locations[boxIndex]
    if not Utils.distanceCheck(sourcePlayer, boxCoords, 5.0) then return end
    if not activePacificContract.loot then return end
    if not activePacificContract.depositBoxes[boxIndex] then return end
    
    local collectedItems = {}
    local failed = false
    
    for _, reward in ipairs(pacificConfig.basement.drilling.rewards) do
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
        activePacificContract.depositBoxes[boxIndex] = nil
        TriggerClientEvent("lunar_contracts:pacific:removeDepositBox", -1, boxIndex)
        LogItem(sourcePlayer, string.format([[
Drilled a Pacific Bank deposit box.
Items: %s]], table.concat(collectedItems, ", ")))
    end
end)

local function resetDoors()
    officeDoors:setAll(true)
    mainOfficeDoor.set(true)
    if basementEnteranceDoors then basementEnteranceDoors:setAll(true) end
    sideVaultDoors:setAll(true)
end

local function cleanup()
    if not activePacificContract then return end
    
    resetDoors()
    cleanUpEntities()
    
    if activePacificContract.loot then
        activePacificContract.loot:remove()
    end
    
    TriggerClientEvent("lunar_contracts:pacific:reset", -1)
    TriggerClientEvent("lunar_contracts:pacific:removeGuards", -1)
    HideContractObjective(activePacificContract.contractIndex)
    DeleteContract(activePacificContract.contractIndex)
    
    activePacificContract = nil
end

local function startContract()
    if not activePacificContract then return end
    
    resetDoors()
    updateContractObjective()
    
    SetTimeout(pacificConfig.duration * 60000, cleanup)
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
        pacificConfig.keypadDoors.laptops.requiredItem,
        pacificConfig.genericDoors.requiredItem,
        pacificConfig.serverRoomTerminal.requiredItem
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
    if pacificConfig.sewers then
        for i = 1, #pacificConfig.sewers.generators do
            generators[i] = false
        end
    end
    
    local keypadCodes = {}
    for i = 1, #pacificConfig.keypadDoors.keypads do
        keypadCodes[i] = generateRandomNumericCode(6)
    end
    
    local laptopLocations = {}
    local laptopLocationList = {}
    for _ = 1, #pacificConfig.keypadDoors.keypads do
        local location
        repeat
            location = Utils.randomFromTable(pacificConfig.keypadDoors.laptops.locations)
        until not lib.table.contains(laptopLocationList, location)
        table.insert(laptopLocationList, location)
    end
    
    local doorCodes = {}
    for i = 1, #pacificConfig.basement.doors do
        doorCodes[i] = generateRandomHexCode(6)
    end
    
    local miniSafes = {}
    if pacificConfig.miniSafe then
        for i = 1, #pacificConfig.miniSafe.locations do
            local safeLoot = {}
            for _, reward in ipairs(pacificConfig.miniSafe.rewards) do
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
    
    activePacificContract = {
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
        miniSafes = miniSafes,
        hackedComputers = {},
        code = generateRandomNumericCode(#pacificConfig.offices.computers * 2)
    }
end

Missions.pacific = {}

function Missions.pacific.canBeGenerated()
    return activePacificContract == nil
end

function Missions.pacific.generated(contractId)
    createContract(contractId)
    
    local metadata = {
        { left = locale("reward"), right = locale("reward_pacific") },
        { left = locale("required_tools"), right = getRequiredToolsText() }
    }
    
    return pacificConfig.image, metadata
end

Missions.pacific.deleted = cleanup

function Missions.pacific.cancelled(contractId)
    TriggerClientEvent("lunar_contracts:pacific:reset", -1)
    HideContractObjective(contractId)
end

function Missions.pacific.start(contractId, data)
    if not activePacificContract then return end
    
    local members = data.members
    TriggerClientEvent("lunar_contracts:pacific:started", -1, members, activePacificContract.laptops, activePacificContract.basementDoorCodes)
    TriggerEvent("lunar_contracts:pacific:announceStarted", contractId, members)
    
    startContract()
end

function Missions.pacific.getSaveData(contractId)
    if not activePacificContract then
        error("Can't fetch save data from the pacific bank contract.")
    end
    
    return { contractIndex = contractId }
end

function Missions.pacific.loadSaveData(data)
    createContract(data.contractIndex)
end

function Missions.pacific.getCancelPoint(contractId)
    return pacificConfig.cancelPoint
end
