local casinoConfig = Config.contracts.casino

local activeCasinoContract = nil
local spawnedEntities = {}
local keycardHackCount = 0

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

local lockedDoors = RegisterDoors(casinoConfig.lockedDoors)

local function createKeypadDoors()
    local doors = {}

    for i, location in ipairs(casinoConfig.keypadDoors.locations) do
        if location.model and location.coords then
            doors[i] = { model = location.model, coords = location.coords }
        elseif location.parts then
            local doorGroup = {}

            for _, part in ipairs(location.parts) do
                table.insert(doorGroup, { model = part.model, coords = part.coords })
            end

            doors[i] = doorGroup
        end
    end

    return RegisterDoors(doors)
end

local keypadDoors = createKeypadDoors()
local electricBoxDoor = RegisterDoor(casinoConfig.electricBox.unlockDoor)
local tunnelDoors = RegisterDoors(casinoConfig.tunnel.doors)
local vaultDoors = RegisterDoors(casinoConfig.vault.doors.locations)
local miniVaultDoor = RegisterDoor(casinoConfig.miniVault.door)
local sewerEntranceDoor = RegisterDoor(casinoConfig.sewerEntrance.bomb.door)

-- Initialize all doors to locked state on startup
CreateThread(function()
    Wait(1000)
    lockedDoors:setAll(true)
    keypadDoors:setAll(true)
    electricBoxDoor.set(true)
    tunnelDoors:setAll(true)
    vaultDoors:setAll(true)
    miniVaultDoor.set(true)
    sewerEntranceDoor.set(true)
    if Config and Config.debug then print("[Casino] All casino doors locked on startup") end
end)

RegisterNetEvent("lunar_contracts:casino:unlockEntrance")
AddEventHandler("lunar_contracts:casino:unlockEntrance", function(entranceIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activeCasinoContract then return end
    if not activeCasinoContract.entrances[entranceIndex] then return end
    if not Utils.distanceCheck(sourcePlayer, casinoConfig.entrances.locations[entranceIndex].keypad, 5.0) then return end
    
    local isInContract = IsPlayerInContract(sourcePlayer, activeCasinoContract.contractIndex)
    
    if isInContract then
        if casinoConfig.entrances.requiredItem and not player:hasItem(casinoConfig.entrances.requiredItem) then
            return
        end
    elseif not Utils.isPolice(sourcePlayer) then
        return
    end
    
    if casinoConfig.entrances.requiredItem and casinoConfig.entrances.removeAfterUse and isInContract then
        player:removeItem(casinoConfig.entrances.requiredItem, 1)
    end
    
    if not activeCasinoContract.alerted then
        ShowContractObjective(activeCasinoContract.contractIndex, locale("casino_title"), locale("obj_find_keycards"))
        Dispatch.call(casinoConfig.dispatch.coords, {
            Code = casinoConfig.dispatch.code,
            Title = casinoConfig.dispatch.title,
            Message = casinoConfig.dispatch.message
        })
    end
    
    activeCasinoContract.entrances[entranceIndex] = false
    activeCasinoContract.alerted = true
    TriggerClientEvent("lunar_contracts:casino:openEntrance", -1, entranceIndex)
end)

RegisterNetEvent("lunar_contracts:casino:unlockKeypadDoor")
AddEventHandler("lunar_contracts:casino:unlockKeypadDoor", function(doorIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local doorLocation = casinoConfig.keypadDoors.locations[doorIndex]
    
    if not player then return end
    if not activeCasinoContract then return end
    if not keypadDoors:get(doorIndex) then return end
    
    local checkCoords = doorLocation.coords or GetDoorCoords(doorLocation.parts)
    if not Utils.distanceCheck(sourcePlayer, checkCoords, 7.5) then return end
    
    local isInContract = IsPlayerInContract(sourcePlayer, activeCasinoContract.contractIndex)
    
    if isInContract then
        if casinoConfig.keypadDoors.requiredItem and not player:hasItem(casinoConfig.keypadDoors.requiredItem) then
            return
        end
    elseif not Utils.isPolice(sourcePlayer) then
        return
    end
    
    if isInContract and casinoConfig.keypadDoors.requiredItem and casinoConfig.keypadDoors.removeAfterUse then
        player:removeItem(casinoConfig.keypadDoors.requiredItem, 1)
    end
    
    keypadDoors:set(doorIndex, false)
    TriggerClientEvent("lunar_contracts:casino:openKeypadDoor", -1, doorIndex)
end)

RegisterNetEvent("lunar_contracts:casino:hackElectricBox")
AddEventHandler("lunar_contracts:casino:hackElectricBox", function()
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activeCasinoContract then return end
    if not Utils.distanceCheck(sourcePlayer, casinoConfig.electricBox.coords, 5.0) then return end
    if not IsPlayerInContract(sourcePlayer, activeCasinoContract.contractIndex) then return end
    
    if casinoConfig.electricBox.requiredItem and not player:hasItem(casinoConfig.electricBox.requiredItem) then
        return
    end
    
    if casinoConfig.electricBox.requiredItem and casinoConfig.electricBox.removeAfterUse then
        player:removeItem(casinoConfig.electricBox.requiredItem, 1)
    end
    
    electricBoxDoor.set(false)
    TriggerClientEvent("lunar_contracts:casino:disableElectricBox", -1)
end)

RegisterNetEvent("lunar_contracts:casino:swipeTerminal")
AddEventHandler("lunar_contracts:casino:swipeTerminal", function(terminalIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activeCasinoContract then return end
    if activeCasinoContract.tunnelOpened then return end
    
    if casinoConfig.tunnel.terminals.requiredItem and not player:hasItem(casinoConfig.tunnel.terminals.requiredItem) then
        return
    end
    
    local terminalCoords = casinoConfig.tunnel.terminals.locations[terminalIndex]
    if not Utils.distanceCheck(sourcePlayer, terminalCoords, 5.0) then return end
    
    if casinoConfig.tunnel.terminals.requiredItem then
        player:removeItem(casinoConfig.tunnel.terminals.requiredItem, 1)
    end
    
    keycardHackCount = keycardHackCount + 1
    
    if keycardHackCount >= 2 then
        activeCasinoContract.tunnelOpened = true
        tunnelDoors:setAll(false)
        ShowContractObjective(activeCasinoContract.contractIndex, locale("casino_title"), locale("obj_explode_vault"))
        TriggerClientEvent("lunar_contracts:casino:openTunnel", -1)
        LR.notify(sourcePlayer, locale("opened_tunnel"), "success")
    end
    
    SetTimeout(casinoConfig.tunnel.terminals.timing, function()
        if not activeCasinoContract.tunnelOpened then
            keycardHackCount = keycardHackCount - 1
            player:addItem(casinoConfig.tunnel.terminals.requiredItem, 1)
            LR.notify(sourcePlayer, locale("failed_tunnel"), "error")
        end
    end)
end)

lib.callback.register("lunar_contracts:casino:isVaultOpened", function()
    return activeCasinoContract and activeCasinoContract.loot and activeCasinoContract.loot:getUnlocked("mainVault")
end)

RegisterNetEvent("lunar_contracts:casino:plantExplosive")
AddEventHandler("lunar_contracts:casino:plantExplosive", function(side, explosiveNetIds)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activeCasinoContract then return end
    
    local explosiveLocation = casinoConfig.vault.explosives.locations[side]
    if not explosiveLocation then return end
    
    if not player:hasItem(casinoConfig.vault.explosives.requiredItem) then return end
    if not explosiveNetIds or #explosiveNetIds > 3 then return end
    if not Utils.distanceCheck(sourcePlayer, explosiveLocation, 5.0) then return end
    
    player:removeItem(casinoConfig.vault.explosives.requiredItem, 1)
    
    if side == "left" then
        if activeCasinoContract.plantedLeft then return end
        activeCasinoContract.plantedLeft = true
        TriggerClientEvent("lunar_contracts:casino:explosivePlanted", -1, side)
    elseif side == "right" then
        if activeCasinoContract.plantedRight then return end
        activeCasinoContract.plantedRight = true
        TriggerClientEvent("lunar_contracts:casino:explosivePlanted", -1, side)
    else
        return
    end
    
    for _, netId in ipairs(explosiveNetIds) do
        table.insert(activeCasinoContract.explosivesNetIds, netId)
    end
    
    if activeCasinoContract.plantedLeft and activeCasinoContract.plantedRight then
        local delay = casinoConfig.vault.explosives.delay
        LR.notify(sourcePlayer, locale("vault_explodes_in"):format(delay), "success")
        ShowContractObjective(activeCasinoContract.contractIndex, locale("casino_title"), locale("obj_vault_explodes"):format(delay))
        
        SetTimeout(delay * 1000, function()
            TriggerClientEvent("lunar_contracts:casino:explodeVault", -1)
            activeCasinoContract.loot:setUnlocked("mainVault", true)
            TriggerClientEvent("lunar_contracts:casino:depositBoxesUnlocked", -1, "mainVault")
            
            ShowContractObjective(activeCasinoContract.contractIndex, locale("casino_title"), locale("obj_contract_completed_extra"))
            
            SetTimeout(60000, function()
                HideContractObjective(activeCasinoContract.contractIndex)
            end)
            
            FinishContract(activeCasinoContract.contractIndex)
            
            for _, netId in ipairs(activeCasinoContract.explosivesNetIds) do
                local entity = NetworkGetEntityFromNetworkId(netId)
                if DoesEntityExist(entity) then
                    DeleteEntity(entity)
                end
            end
        end)
    end
end)

RegisterNetEvent("lunar_contracts:casino:unlockVaultDoor")
AddEventHandler("lunar_contracts:casino:unlockVaultDoor", function(doorIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local doorConfig = casinoConfig.vault.doors.locations[doorIndex]
    
    if not player then return end
    if not activeCasinoContract then return end
    if not vaultDoors:get(doorIndex) then return end
    if not activeCasinoContract.loot or not activeCasinoContract.loot:getUnlocked("mainVault") then return end
    if not IsPlayerInContract(sourcePlayer, activeCasinoContract.contractIndex) then return end
    
    if casinoConfig.vault.doors.requiredItem and not player:hasItem(casinoConfig.vault.doors.requiredItem) then
        return
    end
    
    if not Utils.distanceCheck(sourcePlayer, doorConfig.keypad, 5.0) then return end
    
    if casinoConfig.vault.doors.requiredItem and casinoConfig.vault.doors.removeAfterUse then
        player:removeItem(casinoConfig.vault.doors.requiredItem, 1)
    end
    
    if doorConfig.unlocks then
        activeCasinoContract.loot:setUnlocked(doorConfig.unlocks, true)
        TriggerClientEvent("lunar_contracts:casino:depositBoxesUnlocked", -1, doorConfig.unlocks)
    end
    
    vaultDoors:set(doorIndex, false)
    TriggerClientEvent("lunar_contracts:casino:openVaultDoor", -1, doorIndex)
end)

RegisterNetEvent("lunar_contracts:casino:openDepositBox")
AddEventHandler("lunar_contracts:casino:openDepositBox", function(boxIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local boxConfig = casinoConfig.depositBoxes.locations[boxIndex]
    
    if not player then return end
    if not activeCasinoContract then return end
    if activeCasinoContract.depositBoxes[boxIndex] >= 4 then return end
    if not IsPlayerInContract(sourcePlayer, activeCasinoContract.contractIndex) then return end
    
    if boxConfig.requires and not activeCasinoContract.loot:getUnlocked(boxConfig.requires) then return end
    
    if casinoConfig.depositBoxes.requiredItem and not player:hasItem(casinoConfig.depositBoxes.requiredItem) then
        return
    end
    
    if not Utils.distanceCheck(sourcePlayer, boxConfig.coords, 5.0) then return end
    
    local reward = Utils.randomFromTable(casinoConfig.depositBoxes.rewards)
    local count = type(reward.count) == "number" and reward.count or math.random(reward.count.min, reward.count.max)
    
    player:addItem(reward.item, count)
    
    activeCasinoContract.depositBoxes[boxIndex] = activeCasinoContract.depositBoxes[boxIndex] + 1
    
    if activeCasinoContract.depositBoxes[boxIndex] >= 4 then
        TriggerClientEvent("lunar_contracts:casino:depositBoxOpened", -1, boxIndex)
    end
end)

RegisterNetEvent("lunar_contracts:casino:disableEncryption")
AddEventHandler("lunar_contracts:casino:disableEncryption", function()
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activeCasinoContract then return end
    if activeCasinoContract.encryptionDisabled then return end
    
    if casinoConfig.miniVault.terminal.requiredItem and not player:hasItem(casinoConfig.miniVault.terminal.requiredItem) then
        return
    end
    
    if not Utils.distanceCheck(sourcePlayer, casinoConfig.miniVault.terminal.coords, 5.0) then return end
    
    activeCasinoContract.encryptionDisabled = true
    TriggerClientEvent("lunar_contracts:casino:disableEncryption", -1)
end)

RegisterNetEvent("lunar_contracts:casino:hackedComputer")
AddEventHandler("lunar_contracts:casino:hackedComputer", function(computerIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activeCasinoContract then return end
    if not activeCasinoContract.computers[computerIndex] then return end
    if not activeCasinoContract.encryptionDisabled then return end
    if not IsPlayerInContract(sourcePlayer, activeCasinoContract.contractIndex) then return end
    
    if casinoConfig.miniVault.computers.requiredItem and not player:hasItem(casinoConfig.miniVault.computers.requiredItem) then
        return
    end
    
    local computerCoords = activeCasinoContract.computers[computerIndex].coords
    if not Utils.distanceCheck(sourcePlayer, computerCoords, 5.0) then return end
    
    if casinoConfig.miniVault.computers.requiredItem and casinoConfig.miniVault.computers.removeAfterUse then
        player:removeItem(casinoConfig.miniVault.computers.requiredItem, 1)
    end
    
    activeCasinoContract.computers[computerIndex].hacked = true
    TriggerClientEvent("lunar_contracts:casino:hackedComputer", -1, computerIndex)
    
    local hackedCount = 0
    for _, computer in ipairs(activeCasinoContract.computers) do
        if computer.hacked then hackedCount = hackedCount + 1 end
    end
    
    if hackedCount >= casinoConfig.miniVault.computers.hackCount then
        miniVaultDoor.set(false)
        LR.notify(sourcePlayer, locale("mini_vault_opened"), "success")
        activeCasinoContract.loot:setUnlocked("miniVault", true)
        TriggerClientEvent("lunar_contracts:casino:depositBoxesUnlocked", -1, "miniVault")
    end
end)

RegisterNetEvent("lunar_contracts:casino:plantEntranceBomb")
AddEventHandler("lunar_contracts:casino:plantEntranceBomb", function(explosiveNetIds)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player then return end
    if not activeCasinoContract then return end
    
    if casinoConfig.sewerEntrance.bomb.requiredItem and not player:hasItem(casinoConfig.sewerEntrance.bomb.requiredItem) then
        return
    end
    
    if not Utils.distanceCheck(sourcePlayer, casinoConfig.sewerEntrance.bomb.coords, 5.0) then return end
    
    for _, netId in ipairs(explosiveNetIds) do
        local entity = NetworkGetEntityFromNetworkId(netId)
        if entity and not Utils.distanceCheck(sourcePlayer, GetEntityCoords(entity), 50.0) then
            return
        end
    end
    
    if casinoConfig.sewerEntrance.bomb.requiredItem then
        player:removeItem(casinoConfig.sewerEntrance.bomb.requiredItem, 1)
    end
    
    if not activeCasinoContract.alerted then
        ShowContractObjective(activeCasinoContract.contractIndex, locale("casino_title"), locale("obj_find_keycards"))
        Dispatch.call(casinoConfig.dispatch.coords, {
            Code = casinoConfig.dispatch.code,
            Title = casinoConfig.dispatch.title,
            Message = casinoConfig.dispatch.message
        })
    end
    
    activeCasinoContract.entranceBomb = true
    activeCasinoContract.alerted = true
    
    TriggerClientEvent("lunar_contracts:casino:plantEntranceBomb", -1, explosiveNetIds)
    
    SetTimeout(10000, function()
        sewerEntranceDoor.set(false)
    end)
end)

local function resetDoors()
    keypadDoors:setAll(true)
    electricBoxDoor.set(true)
    tunnelDoors:setAll(true)
    vaultDoors:setAll(true)
    miniVaultDoor.set(true)
    sewerEntranceDoor.set(true)
end

local guardVariationIndex = 0

local function randomizeGuardOutfit(ped, isSpecial)
    if isSpecial then
        SetPedComponentVariation(ped, 0, guardVariationIndex, 0, guardVariationIndex)
        SetPedComponentVariation(ped, 2, guardVariationIndex, 0, guardVariationIndex)
        guardVariationIndex = guardVariationIndex + 1
    else
        local variation = math.random(0, 5)
        SetPedComponentVariation(ped, 11, 0, math.random(1, 2), 0)
        SetPedPropIndex(ped, 0, 1, 0)
        SetPedComponentVariation(ped, 9, math.random(2, 3), 0, 0)
        SetPedComponentVariation(ped, 7, 1, 0, 0)
        SetPedComponentVariation(ped, 8, 1, 0, 0)
        SetPedComponentVariation(ped, 0, variation, 0, variation)
        SetPedComponentVariation(ped, 2, variation, 0, variation)
    end
end

local function spawnGuards()
    if not activeCasinoContract then return end
    
    local specialPositions = {}
    for _ = 1, 2 do
        local pos
        repeat
            pos = math.random(#casinoConfig.guards.locations)
        until not lib.table.contains(specialPositions, pos)
        table.insert(specialPositions, pos)
    end
    
    local guardNetIds = {}
    local guardList = {}
    
    for i, coords in ipairs(casinoConfig.guards.locations) do
        local isSpecial = lib.table.contains(specialPositions, i)
        local model = isSpecial and casinoConfig.guards.models.special or casinoConfig.guards.models.normal
        
        local guard = CreatePed(4, model, coords.x, coords.y, coords.z, coords.w, true, true)
        local weapon = Utils.randomFromTable(casinoConfig.guards.weapons)
        
        GiveWeaponToPed(guard, joaat(weapon.name), 250, false, true)
        randomizeGuardOutfit(guard, isSpecial)
        
        activeCasinoContract.guards[i] = {
            netId = NetworkGetNetworkIdFromEntity(guard),
            weapon = weapon,
            special = isSpecial
        }
        
        guardNetIds[i] = activeCasinoContract.guards[i].netId
        table.insert(spawnedEntities, guard)
        
        table.insert(guardList, { ped = guard, weapon = joaat(weapon.name) })
        
        Entity(guard).state:set("casino:setupPed", joaat(weapon.name))
    end
    
    TriggerClientEvent("lunar_contracts:casino:handleGuardsLogic", -1, guardNetIds)
    
    CreateThread(function()
        while activeCasinoContract do
            for _, guardInfo in ipairs(guardList) do
                if DoesEntityExist(guardInfo.ped) then
                    local currentWeapon = GetSelectedPedWeapon(guardInfo.ped)
                    if currentWeapon == -1569615261 then
                        GiveWeaponToPed(guardInfo.ped, guardInfo.weapon, 250, false, true)
                    end
                end
            end
            Wait(1000)
        end
    end)
end

RegisterNetEvent("lunar_contracts:casino:lootGuard")
AddEventHandler("lunar_contracts:casino:lootGuard", function(guardNetId)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local guard = NetworkGetEntityFromNetworkId(guardNetId)
    
    if not activeCasinoContract or not player then return end
    if not DoesEntityExist(guard) then return end
    if not Utils.distanceCheck(sourcePlayer, GetEntityCoords(guard), 5.0) then return end
    if not activeCasinoContract.alerted then return end
    
    for i, guardData in pairs(activeCasinoContract.guards) do
        if guardData.netId == guardNetId then
            local ammoAmount = math.random(guardData.weapon.ammo.min, guardData.weapon.ammo.max)
            
            local canCarryWeapon = true
            local canCarryAmmo = true
            local canCarryKeycard = true
            
            if casinoConfig.guards.looting.enabled then
                canCarryWeapon = player:canCarryItem(guardData.weapon.name, 1)
                canCarryAmmo = player:canCarryItem(guardData.weapon.ammo.name, ammoAmount)
            end
            
            if guardData.special then
                canCarryKeycard = player:canCarryItem(casinoConfig.tunnel.terminals.requiredItem, 1)
            end
            
            if not (canCarryWeapon and canCarryAmmo and canCarryKeycard) then
                LR.notify(sourcePlayer, locale("inventory_full"), "error")
                return
            end
            
            activeCasinoContract.guards[i] = nil
            
            if guardData.special then
                if player:addItem(casinoConfig.tunnel.terminals.requiredItem, 1) then
                    if casinoConfig.guards.looting.enabled then
                        player:addItem(guardData.weapon.name, 1)
                        player:addItem(guardData.weapon.ammo.name, ammoAmount)
                    end
                    
                    activeCasinoContract.lootedKeycards = activeCasinoContract.lootedKeycards + 1
                    
                    if activeCasinoContract.lootedKeycards >= 2 then
                        ShowContractObjective(activeCasinoContract.contractIndex, locale("casino_title"), locale("obj_unlock_tunnel"))
                    end
                else
                    activeCasinoContract.guards[i] = guardData
                    LR.notify(sourcePlayer, locale("inventory_full"), "error")
                    return
                end
            else
                if casinoConfig.guards.looting.enabled then
                    player:addItem(guardData.weapon.name, 1)
                    player:addItem(guardData.weapon.ammo.name, ammoAmount)
                end
            end
            
            TriggerClientEvent("lunar_contracts:casino:guardLooted", -1, guardNetId)
            LogItem(sourcePlayer, string.format([[
Looted a Casino guard.
Weapon: %s]], guardData.weapon.name:upper()))
            return
        end
    end
end)

local function spawnElectricBox()
    local coords = casinoConfig.electricBox.coords
    local box = CreateObjectNoOffset(casinoConfig.electricBox.model, coords.x, coords.y, coords.z - 1.0, true, false, false)
    SetEntityHeading(box, coords.w + 180.0)
    table.insert(spawnedEntities, box)
end

local depositBoxModels = { -2110344306, 1941903007, -815542789 }

local function spawnDepositBoxes()
    for i, location in ipairs(casinoConfig.depositBoxes.locations) do
        local model = Utils.randomFromTable(depositBoxModels)
        local box = CreateObjectNoOffset(model, location.coords.x, location.coords.y, location.coords.z, true, false, false)
        SetEntityHeading(box, location.coords.w)
        table.insert(spawnedEntities, box)
    end
end

local function startContract()
    if not activeCasinoContract then return end
    
    resetDoors()
    spawnElectricBox()
    spawnDepositBoxes()
    spawnGuards()
    
    activeCasinoContract.loot = Loot.new(casinoConfig.vault.loot)
    
    ShowContractObjective(activeCasinoContract.contractIndex, locale("casino_title"), locale("obj_enter_casino"))
    
    SetTimeout(casinoConfig.duration * 60000, cleanup)
end

local function cleanup()
    if not activeCasinoContract then return end
    
    resetDoors()
    HideContractObjective(activeCasinoContract.contractIndex)
    cleanUpEntities()
    
    if activeCasinoContract.loot then
        activeCasinoContract.loot:remove()
    end
    
    TriggerClientEvent("lunar_contracts:casino:reset", -1)
    TriggerClientEvent("lunar_contracts:casino:removeGuards", -1)
    DeleteContract(activeCasinoContract.contractIndex)
    
    activeCasinoContract = nil
end

local function getRequiredToolsText()
    local tools = {}
    local requiredItems = {
        casinoConfig.electricBox.requiredItem,
        casinoConfig.entrances.requiredItem,
        casinoConfig.depositBoxes.requiredItem,
        casinoConfig.miniVault.computers.requiredItem,
        casinoConfig.keypadDoors.requiredItem,
        casinoConfig.miniVault.terminal.requiredItem
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
    
    if casinoConfig.vault.explosives.requiredItem then
        table.insert(uniqueTools, "2x " .. Utils.getItemLabel(casinoConfig.vault.explosives.requiredItem))
    end
    
    if #uniqueTools == 0 then
        return locale("no_tools")
    end
    
    return table.concat(uniqueTools, ", ")
end

local function createContract(contractId)
    local entrances = {}
    for i = 1, #casinoConfig.entrances.locations do
        entrances[i] = true
    end
    
    local depositBoxes = {}
    for i = 1, #casinoConfig.depositBoxes.locations do
        depositBoxes[i] = 0
    end
    
    local computers = {}
    local computerLocations = {}
    local hackCount = math.min(casinoConfig.miniVault.computers.hackCount, #casinoConfig.miniVault.computers.locations)
    
    for _ = 1, hackCount do
        local location
        repeat
            location = math.random(#casinoConfig.miniVault.computers.locations)
        until not lib.table.contains(computerLocations, location)
        table.insert(computerLocations, location)
    end
    
    for i, coords in ipairs(casinoConfig.miniVault.computers.locations) do
        if lib.table.contains(computerLocations, i) then
            table.insert(computers, { coords = coords, hacked = false })
        end
    end
    
    activeCasinoContract = {
        contractIndex = contractId,
        entrances = entrances,
        tunnelOpened = false,
        plantedLeft = false,
        plantedRight = false,
        explosivesNetIds = {},
        depositBoxes = depositBoxes,
        computers = computers,
        encryptionDisabled = false,
        guards = {},
        alerted = false,
        entranceBomb = false,
        lootedKeycards = 0
    }
end

Missions.casino = {}

function Missions.casino.canBeGenerated()
    return activeCasinoContract == nil
end

function Missions.casino.generated(contractId)
    createContract(contractId)
    
    local metadata = {
        { left = locale("reward"), right = locale("reward_casino") },
        { left = locale("required_tools"), right = getRequiredToolsText() }
    }
    
    return casinoConfig.image, metadata
end

Missions.casino.deleted = cleanup

function Missions.casino.cancelled(contractId)
    TriggerClientEvent("lunar_contracts:casino:reset", -1)
    HideContractObjective(contractId)
    SetTimeout(300000, cleanUpEntities)
end

function Missions.casino.start(contractId, data)
    if not activeCasinoContract then return end
    
    local members = data.members
    TriggerClientEvent("lunar_contracts:casino:started", -1, members, activeCasinoContract.computers)
    TriggerEvent("lunar_contracts:casino:announceStarted", contractId, members)
    
    startContract()
end

function Missions.casino.getSaveData(contractId)
    if not activeCasinoContract then
        error("Can't fetch save data from the casino contract.")
    end
    
    return { contractIndex = contractId }
end

function Missions.casino.loadSaveData(data)
    createContract(data.contractIndex)
end

function Missions.casino.getCancelPoint(contractId)
    return casinoConfig.dispatch.coords
end
