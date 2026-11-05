local houseConfig = Config.contracts.house

local activeHouseContracts = {}
local houseEntities = {}
local houseLocationStates = {}
local playerLocations = {}
local houseLootInProgress = false

local function getTierSettings(tierName)
    if tierName and houseConfig.tiers[tierName] and houseConfig.tiers[tierName].settings then
        return houseConfig.tiers[tierName].settings
    end
    return houseConfig.settings
end

local function getContractSettings(contractId)
    local contract = activeHouseContracts[contractId]
    if contract and contract.tier then
        return getTierSettings(contract.tier)
    end
    return houseConfig.settings
end

local function setLocationLaserState(locationIndex, active)
    if not houseLocationStates[locationIndex] then
        houseLocationStates[locationIndex] = { lasersActive = true, alarmActive = false, contractIndex = nil }
    end
    houseLocationStates[locationIndex].lasersActive = active
    TriggerClientEvent("lunar_contracts:house:syncLocationState", -1, locationIndex, active, houseLocationStates[locationIndex].alarmActive)
end

local function setLocationAlarmState(locationIndex, active)
    if not houseLocationStates[locationIndex] then
        houseLocationStates[locationIndex] = { lasersActive = true, alarmActive = false, contractIndex = nil }
    end
    houseLocationStates[locationIndex].alarmActive = active
    TriggerClientEvent("lunar_contracts:house:syncLocationState", -1, locationIndex, houseLocationStates[locationIndex].lasersActive, active)
end

local function cleanUpLocationEntities(locationIndex)
    if not houseEntities[locationIndex] then return end
    
    for _, entity in ipairs(houseEntities[locationIndex]) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
    houseEntities[locationIndex] = nil
end

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == cache.resource then
        -- Clean up all entities
        for locationIndex in pairs(houseEntities) do
            cleanUpLocationEntities(locationIndex)
        end

        -- Reset all players inside houses back outside
        for playerId, locationIndex in pairs(playerLocations) do
            local player = Framework.getPlayerFromId(playerId)
            if player then
                SetPlayerRoutingBucket(playerId, 0)
                Player(playerId).state.instance = nil

                local location = houseConfig.locations[locationIndex]
                if location then
                    SetEntityCoords(GetPlayerPed(playerId), location.coords.x, location.coords.y, location.coords.z)
                end
            end
        end

        -- Clean up all state
        table.wipe(activeHouseContracts)
        table.wipe(houseEntities)
        table.wipe(houseLocationStates)
        table.wipe(playerLocations)
    end
end)

AddEventHandler("playerDropped", function()
    local sourcePlayer = source
    playerLocations[sourcePlayer] = nil
end)

-- Forward declarations for functions defined later
local startExitTimeout
local cleanupContract

lib.callback.register("lunar_contracts:house:getStartedLocations", function()
    local locations = {}
    for contractId, contract in pairs(activeHouseContracts) do
        if contract.started then
            table.insert(locations, {
                locationIndex = contract.locationIndex,
                unlocked = contract.opened,
                contractIndex = contractId
            })
        end
    end
    return locations
end)

RegisterNetEvent("lunar_contracts:house:lockpicked")
AddEventHandler("lunar_contracts:house:lockpicked", function(contractId)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = activeHouseContracts[contractId]
    
    if not player or not contract then return end
    if contract.opened then return end
    if not IsPlayerInContract(sourcePlayer, contractId) then return end
    
    if houseConfig.lockpickItem.name and not player:hasItem(houseConfig.lockpickItem.name) then
        return
    end
    
    contract.opened = true
    TriggerClientEvent("lunar_contracts:house:unlocked", -1, contract.locationIndex)
    
    if houseConfig.lockpickItem.name and houseConfig.lockpickItem.removeAfterUse then
        player:removeItem(houseConfig.lockpickItem.name, 1)
    end
    
    local interior = houseConfig.interiors[contract.tier]
    local objectiveText = interior.silent and locale("obj_loot_house_silent") or locale("obj_loot_house")
    ShowContractObjective(contractId, locale("house_title"), objectiveText)
end)

RegisterNetEvent("lunar_contracts:house:hackedKeypad")
AddEventHandler("lunar_contracts:house:hackedKeypad", function(contractId)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = activeHouseContracts[contractId]
    
    if not player or not contract then return end
    if contract.opened then return end
    if not IsPlayerInContract(sourcePlayer, contractId) then return end
    
    if houseConfig.hackingItem.name and not player:hasItem(houseConfig.hackingItem.name) then
        return
    end
    
    if houseConfig.hackingItem.name and houseConfig.hackingItem.removeAfterUse then
        player:removeItem(houseConfig.hackingItem.name, 1)
    end
    
    contract.opened = true
    TriggerClientEvent("lunar_contracts:house:unlocked", -1, contract.locationIndex)
    
    local interior = houseConfig.interiors[contract.tier]
    local objectiveText = interior.silent and locale("obj_loot_house_silent") or locale("obj_loot_house")
    ShowContractObjective(contractId, locale("house_title"), objectiveText)
end)

RegisterNetEvent("lunar_contracts:house:entered")
AddEventHandler("lunar_contracts:house:entered", function(contractId)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = activeHouseContracts[contractId]
    
    if not player then return end
    if playerLocations[sourcePlayer] then return end
    
    playerLocations[sourcePlayer] = contract.locationIndex
    
    local instanceId = 4000 + contract.locationIndex
    SetPlayerRoutingBucket(sourcePlayer, instanceId)
    Player(sourcePlayer).state.instance = instanceId
    
    local interior = houseConfig.interiors[contract.tier]
    local playerIdentifier = player:getIdentifier()
    
    if playerIdentifier == contract.owner and not contract.hostEnteredOnce then
        contract.hostEnteredOnce = true
        startExitTimeout(contractId)
    end
    
    if not houseLocationStates[contract.locationIndex] then
        houseLocationStates[contract.locationIndex] = {
            lasersActive = true,
            alarmActive = false,
            contractIndex = contractId
        }
    end
    
    TriggerClientEvent("lunar_contracts:house:syncLocationState", sourcePlayer, contract.locationIndex,
        houseLocationStates[contract.locationIndex].lasersActive,
        houseLocationStates[contract.locationIndex].alarmActive)
    
    if not interior.silent and not contract.alarm then
        local hasHomeownerPeds = interior.homeownerPeds and interior.homeownerPeds.enabled and #(interior.homeownerPeds.peds or {}) > 0
        
        if not hasHomeownerPeds then
            contract.alarm = true
            
            local alarmDelay = houseConfig.dispatch.delayForTiers and houseConfig.dispatch.delayForTiers[contract.tier] or 0
            
            if alarmDelay > 0 then
                SetTimeout(alarmDelay * 1000, function()
                    if activeHouseContracts[contractId] then
                        setLocationAlarmState(contract.locationIndex, true)
                        setLocationLaserState(contract.locationIndex, false)
                        
                        if houseConfig.dispatch.enabled then
                            Dispatch.call(houseConfig.locations[contract.locationIndex].coords.xyz, {
                                Code = houseConfig.dispatch.code,
                                Title = houseConfig.dispatch.title,
                                Message = houseConfig.dispatch.message
                            })
                        end
                    end
                end)
            else
                setLocationAlarmState(contract.locationIndex, true)
                setLocationLaserState(contract.locationIndex, false)
                
                if houseConfig.dispatch.enabled then
                    Dispatch.call(houseConfig.locations[contract.locationIndex].coords.xyz, {
                        Code = houseConfig.dispatch.code,
                        Title = houseConfig.dispatch.title,
                        Message = houseConfig.dispatch.message
                    })
                end
            end
        end
    end
end)

RegisterNetEvent("lunar_contracts:house:exited")
AddEventHandler("lunar_contracts:house:exited", function(contractId)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = activeHouseContracts[contractId]
    
    if not player or not contract then return end
    if not playerLocations[sourcePlayer] then return end
    
    playerLocations[sourcePlayer] = nil
    SetPlayerRoutingBucket(sourcePlayer, 0)
    Player(sourcePlayer).state.instance = nil
    
    -- Završi misiju kada igrač izađe iz kuće ako ima loota
    if Utils.getTableSize(contract.looted) > 0 then
        HideContractObjective(contractId)
        FinishContract(contractId)
        cleanupContract(contractId)
    end
end)

RegisterNetEvent("lunar_contracts:house:stealDisplayCase")
AddEventHandler("lunar_contracts:house:stealDisplayCase", function(contractId)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = activeHouseContracts[contractId]
    local interior = houseConfig.interiors[contract.tier]
    local displayCase = interior.displayCase
    
    if not player or not contract then return end
    if not contract.displayCaseLoot then return end
    
    if displayCase.requiredItem and not player:hasItem(displayCase.requiredItem) then
        return
    end
    
    if not player:canCarryItem(contract.displayCaseLoot, 1) then
        LR.notify(sourcePlayer, locale("inventory_full"), "error")
        return
    end
    
    if displayCase.removeAfterUse then
        player:removeItem(displayCase.requiredItem, 1)
    end
    
    if player:addItem(contract.displayCaseLoot, 1) then
        contract.displayCaseLoot = nil
        TriggerClientEvent("lunar_contracts:house:displayCaseStolen", -1, contractId)
    else
        LR.notify(sourcePlayer, locale("inventory_full"), "error")
    end
end)

RegisterNetEvent("lunar_contracts:house:stealPainting")
AddEventHandler("lunar_contracts:house:stealPainting", function(contractId, paintingIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = activeHouseContracts[contractId]
    local interior = houseConfig.interiors[contract.tier]
    
    if not player or not contract then return end
    if not contract.paintings[paintingIndex] then return end
    if not IsPlayerInContract(sourcePlayer, contractId) then return end
    
    if not player:canCarryItem(interior.paintings.item, 1) then
        LR.notify(sourcePlayer, locale("inventory_full"), "error")
        return
    end
    
    if player:addItem(interior.paintings.item, 1) then
        contract.paintings[paintingIndex] = nil
        TriggerClientEvent("lunar_contracts:house:setPaintingLooted", -1, contractId, paintingIndex)
    else
        LR.notify(sourcePlayer, locale("inventory_full"), "error")
    end
end)

RegisterNetEvent("lunar_contracts:house:takeLoot")
AddEventHandler("lunar_contracts:house:takeLoot", function(contractId, lootIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = activeHouseContracts[contractId]
    local interior = houseConfig.interiors[contract.tier]
    
    if not player or not contract then 
        if Config and Config.debug then print("[House] takeLoot: player or contract nil") end
        return 
    end
    if lootIndex <= 0 or lootIndex > #interior.takeLoot then 
        if Config and Config.debug then print("[House] takeLoot: lootIndex out of range: " .. tostring(lootIndex)) end
        return 
    end
    if contract.looted[lootIndex] then 
        if Config and Config.debug then print("[House] takeLoot: already looted index " .. tostring(lootIndex)) end
        return 
    end
    if not IsPlayerInContract(sourcePlayer, contractId) then 
        print("[House] Player " .. sourcePlayer .. " is not in contract " .. contractId)
        return 
    end
    if Config and Config.debug then print("[House] takeLoot: processing loot index " .. tostring(lootIndex) .. " for contract " .. tostring(contractId)) end
    
    local lootConfig = interior.takeLoot[lootIndex]
    local maxItems = lootConfig.maxItemCount

    local failed = false
    
    if maxItems then
        local indices = {}
        for i = 1, #lootConfig.items do
            indices[i] = i
        end
        
        for i = #indices, 2, -1 do
            local j = math.random(i)
            indices[i], indices[j] = indices[j], indices[i]
        end
        
        local lootedCount = 0
        for _, idx in ipairs(indices) do
            if lootedCount >= maxItems then break end
            
            local item = lootConfig.items[idx]
            local count = item.count or math.random(item.min, item.max)
            
            if not item.chance or math.random(1, 100) <= item.chance then
                if not player:addItem(item.name, count) then
                    failed = true
                    LR.notify(sourcePlayer, locale("inventory_full"), "error")
                    break
                end
                lootedCount = lootedCount + 1
            end
        end
    else
        for _, item in ipairs(lootConfig.items) do
            local count = item.count or math.random(item.min, item.max)
            
            if not item.chance or math.random(1, 100) <= item.chance then
                if not player:addItem(item.name, count) then
                    failed = true
                    LR.notify(sourcePlayer, locale("inventory_full"), "error")
                    break
                end
            end
        end
    end
    
    contract.looted[lootIndex] = true
    TriggerClientEvent("lunar_contracts:house:looted", -1, contractId, contract.locationIndex, lootIndex)
    
    if not failed then
        if Config and Config.debug then print("[House] looted count: " .. Utils.getTableSize(contract.looted) .. " / " .. #interior.takeLoot) end
        if Utils.getTableSize(contract.looted) == #interior.takeLoot then
            HideContractObjective(contractId)
            FinishContract(contractId)
            cleanupContract(contractId)
        end
    end
end)

RegisterNetEvent("lunar_contracts:house:lootGuard")
AddEventHandler("lunar_contracts:house:lootGuard", function(locationIndex, guardNetId)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local guard = NetworkGetEntityFromNetworkId(guardNetId)
    local location = houseConfig.locations[locationIndex]
    local interior = houseConfig.interiors[location.tier]
    local contract = nil
    
    for _, c in pairs(activeHouseContracts) do
        if c.locationIndex == locationIndex then
            contract = c
            break
        end
    end
    
    if not contract or not player then return end
    if not DoesEntityExist(guard) then return end
    if not interior.guards.looting.enabled then return end
    if not Utils.distanceCheck(sourcePlayer, GetEntityCoords(guard), 5.0) then return end
    
    for i, guardData in pairs(contract.guards) do
        if guardData.netId == guardNetId then
            local ammoAmount = math.random(guardData.weapon.ammo.min, guardData.weapon.ammo.max)
            
            if not player:canCarryItem(guardData.weapon.name, 1) or not player:canCarryItem(guardData.weapon.ammo.name, ammoAmount) then
                LR.notify(sourcePlayer, locale("inventory_full"), "error")
                return
            end
            
            contract.guards[i] = nil
            
            if player:addItem(guardData.weapon.name, 1) then
                player:addItem(guardData.weapon.ammo.name, ammoAmount)
                TriggerClientEvent("lunar_contracts:house:guardLooted", -1, guardNetId)
                LogItem(sourcePlayer, string.format([[
Looted a House Robbery guard.
Weapon: %s]], guardData.weapon.name:upper()))
            else
                contract.guards[i] = guardData
                LR.notify(sourcePlayer, locale("inventory_full"), "error")
            end
            return
        end
    end
end)

RegisterNetEvent("lunar_contracts:house:lootHomeowner")
AddEventHandler("lunar_contracts:house:lootHomeowner", function(contractId, pedIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = activeHouseContracts[contractId]
    
    if not player or not contract then return end
    if not IsPlayerInContract(sourcePlayer, contractId) then return end
    
    local interior = houseConfig.interiors[contract.tier]
    if not interior.homeownerPeds or not interior.homeownerPeds.enabled then return end
    if not interior.homeownerPeds.looting or not interior.homeownerPeds.looting.enabled then return end
    
    local pedConfig = interior.homeownerPeds.peds[pedIndex]
    if not pedConfig then return end
    
    if not contract.lootedHomeowners then
        contract.lootedHomeowners = {}
    end
    if contract.lootedHomeowners[pedIndex] then return end
    
    local collectedItems = {}
    
    if pedConfig.items then
        for _, itemData in ipairs(pedConfig.items) do
            local count = itemData.count or math.random(itemData.min, itemData.max)
            
            if not itemData.chance or math.random(1, 100) <= itemData.chance then
                if not player:addItem(itemData.name, count) then
                    LR.notify(sourcePlayer, locale("inventory_full"), "error")
                    return
                end
                table.insert(collectedItems, string.format("%s x%d", itemData.name, count))
            end
        end
    end
    
    contract.lootedHomeowners[pedIndex] = true
    TriggerClientEvent("lunar_contracts:house:homeownerLooted", -1, contract.locationIndex, pedIndex)
    LogItem(sourcePlayer, string.format([[
Looted a homeowner in House Robbery.
Items: %s]], table.concat(collectedItems, ", ")))
end)

RegisterNetEvent("lunar_contracts:house:alarm")
AddEventHandler("lunar_contracts:house:alarm", function(locationIndex)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = nil
    
    for _, c in pairs(activeHouseContracts) do
        if c.locationIndex == locationIndex then
            contract = c
            break
        end
    end
    
    if not contract then return end
    
    local interior = houseConfig.interiors[contract.tier]
    local hasHomeownerPeds = interior.homeownerPeds and interior.homeownerPeds.enabled and #(interior.homeownerPeds.peds or {}) > 0
    
    if contract.alarm then return end
    if not player then return end
    if not interior.silent and not hasHomeownerPeds then return end
    if playerLocations[sourcePlayer] ~= locationIndex then return end
    if not Utils.distanceCheck(sourcePlayer, interior.alarm.coords, 200.0) then return end
    
    contract.alarm = true
    setLocationAlarmState(locationIndex, true)
    setLocationLaserState(locationIndex, false)
    
    if houseConfig.dispatch.enabled then
        Dispatch.call(houseConfig.locations[locationIndex].coords.xyz, {
            Code = houseConfig.dispatch.code,
            Title = houseConfig.dispatch.title,
            Message = houseConfig.dispatch.message
        })
    end
end)

RegisterNetEvent("lunar_contracts:house:updateAlertLevel")
AddEventHandler("lunar_contracts:house:updateAlertLevel", function(locationIndex, alertLevel)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = nil
    
    for _, c in pairs(activeHouseContracts) do
        if c.locationIndex == locationIndex then
            contract = c
            break
        end
    end
    
    if not player or not contract then return end
    
    local interior = houseConfig.interiors[contract.tier]
    
    if alertLevel <= contract.alertLevel then return end
    if contract.alarm then return end
    if not interior.silent then return end
    if playerLocations[sourcePlayer] ~= locationIndex then return end
    if not Utils.distanceCheck(sourcePlayer, interior.alarm.coords, 200.0) then return end
    
    if alertLevel >= 1.0 then
        contract.alarm = true
        setLocationAlarmState(locationIndex, true)
        setLocationLaserState(locationIndex, false)
        
        if houseConfig.dispatch.enabled then
            Dispatch.call(houseConfig.locations[locationIndex].coords.xyz, {
                Code = houseConfig.dispatch.code,
                Title = houseConfig.dispatch.title,
                Message = houseConfig.dispatch.message
            })
        end
    else
        contract.alertLevel = alertLevel
        TriggerClientEvent("lunar_contracts:house:updateAlertLevel", -1, locationIndex, alertLevel)
    end
end)

local function randomizePedOutfit(ped)
    local variation = math.random(0, 5)
    
    SetPedComponentVariation(ped, 11, 0, math.random(1, 2), 0)
    SetPedPropIndex(ped, 0, 1, 0)
    SetPedComponentVariation(ped, 9, math.random(2, 3), 0, 0)
    SetPedComponentVariation(ped, 7, 1, 0, 0)
    SetPedComponentVariation(ped, 8, 1, 0, 0)
    SetPedComponentVariation(ped, 0, variation, 0, variation)
    SetPedComponentVariation(ped, 2, variation, 0, variation)
end

local function createGuard(coords, model, bucketId, weapons, contractId)
    local contract = activeHouseContracts[contractId]
    local guard = CreatePed(4, model, coords.x, coords.y, coords.z, coords.w, true, true)
    randomizePedOutfit(guard)
    
    if bucketId then
        SetEntityRoutingBucket(guard, bucketId)
    end
    
    local weapon = Utils.randomFromTable(weapons)
    GiveWeaponToPed(guard, weapon.name, 250, false, true)
    SetPedArmour(guard, 100)
    
    CreateThread(function()
        while DoesEntityExist(guard) do
            local currentWeapon = GetSelectedPedWeapon(guard)
            if currentWeapon ~= weapon.name then
                GiveWeaponToPed(guard, weapon.name, 250, true, true)
            end
            Wait(2000)
        end
    end)
    
    local guardData = {
        netId = NetworkGetNetworkIdFromEntity(guard),
        weapon = weapon
    }
    
    if not contract.guards then
        contract.guards = {}
    end
    table.insert(contract.guards, guardData)
    
    Entity(guard).state:set("house:setupPed", contract.locationIndex)
    Entity(guard).state:set("house:isPedAggressive", true)
    
    return guardData.netId, guard
end

local function spawnGuards(contractId)
    local contract = activeHouseContracts[contractId]
    local location = houseConfig.locations[contract.locationIndex]
    local interior = houseConfig.interiors[contract.tier]
    
    if not interior.guards then return end
    
    local guardNetIds = {}
    local bucketId = 4000 + contract.locationIndex
    
    for _, coords in ipairs(interior.guards.locations) do
        local netId, ped = createGuard(coords, interior.guards.model, bucketId, interior.guards.weapons, contractId)
        table.insert(guardNetIds, netId)
        
        if not houseEntities[contractId] then
            houseEntities[contractId] = {}
        end
        table.insert(houseEntities[contractId], ped)
        
        Entity(ped).state:set("house:setupPed", contract.locationIndex)
        Entity(ped).state:set("house:isPedAggressive", true)
    end
    
    if location.outsideGuards then
        for _, coords in ipairs(location.outsideGuards) do
            local netId, ped = createGuard(coords, interior.guards.model, nil, interior.guards.weapons, contractId)
            table.insert(guardNetIds, netId)
            
            if not houseEntities[contractId] then
                houseEntities[contractId] = {}
            end
            table.insert(houseEntities[contractId], ped)
            
            Entity(ped).state:set("house:setupPed", contract.locationIndex)
            Entity(ped).state:set("house:isPedAggressive", false)
        end
    end
    
    TriggerClientEvent("lunar_contracts:house:handleGuardsLogic", -1, contract.locationIndex, guardNetIds)
end

local civilianModels = {
    "a_m_m_bevhills_01", "a_m_m_bevhills_02", "a_f_y_bevhills_01", "a_f_y_bevhills_02",
    "a_f_m_bevhills_01", "a_f_m_bevhills_02", "a_m_y_hipster_01", "a_m_y_hipster_02",
    "a_m_y_hipster_03", "a_f_y_hipster_01", "a_f_y_hipster_02", "a_f_y_hipster_03",
    "a_f_y_hipster_04", "a_m_y_vinewood_01", "a_m_y_vinewood_02", "a_m_y_vinewood_03",
    "a_m_y_vinewood_04", "a_f_y_vinewood_01", "a_f_y_vinewood_02", "a_f_y_vinewood_03",
    "a_f_y_vinewood_04", "a_m_m_soucent_01", "a_m_m_soucent_02", "a_m_m_soucent_03",
    "a_f_m_soucent_01", "a_f_m_soucent_02", "a_m_y_soucent_01", "a_m_y_soucent_02",
    "a_f_y_soucent_01", "a_f_y_soucent_02", "a_m_m_fatlatin_01", "a_m_m_genfat_01",
    "a_m_m_genfat_02", "a_f_m_fatwhite_01", "a_m_y_genstreet_01", "a_m_y_genstreet_02",
    "g_m_y_famca_01", "g_m_y_famdnf_01", "g_m_y_famfor_01", "g_m_y_ballasout_01",
    "g_m_y_ballaeast_01", "g_m_y_ballaorig_01", "g_m_y_mexgoon_01", "g_m_y_mexgoon_02",
    "g_m_y_mexgoon_03", "g_m_y_salvaboss_01", "g_m_y_salvagoon_01", "g_m_y_salvagoon_02",
    "g_m_y_salvagoon_03", "g_m_y_strpunk_01", "g_m_y_strpunk_02", "g_f_y_ballas_01",
    "g_f_y_families_01", "g_f_y_vagos_01", "g_m_y_korean_01", "g_m_y_korean_02",
    "g_m_y_korlieut_01", "g_m_y_lost_01", "g_m_y_lost_02", "g_m_y_lost_03",
    "g_m_y_pologoon_01", "g_m_y_pologoon_02", "g_m_y_armgoon_01"
}

local function spawnHomeowners(contractId)
    local contract = activeHouseContracts[contractId]
    local interior = houseConfig.interiors[contract.tier]
    
    if not interior.homeownerPeds or not interior.homeownerPeds.enabled then return end
    if not interior.homeownerPeds.peds or #interior.homeownerPeds.peds == 0 then return end
    
    local bucketId = 4000 + contract.locationIndex
    local homeowners = {}
    
    for i, pedConfig in ipairs(interior.homeownerPeds.peds) do
        local chance = pedConfig.chance or 50
        if math.random(1, 100) <= chance then
            local model = civilianModels[math.random(#civilianModels)]
            local ped = CreatePed(4, model, pedConfig.coords.x, pedConfig.coords.y, pedConfig.coords.z, pedConfig.coords.w, true, true)
            
            if DoesEntityExist(ped) then
                SetEntityRoutingBucket(ped, bucketId)
                SetPedRandomComponentVariation(ped, 1)
                SetPedRandomProps(ped)
                
                if pedConfig.weapon then
                    GiveWeaponToPed(ped, pedConfig.weapon, 100, false, true)
                end
                
                if not houseEntities[contractId] then
                    houseEntities[contractId] = {}
                end
                table.insert(houseEntities[contractId], ped)
                
                homeowners[i] = {
                    netId = NetworkGetNetworkIdFromEntity(ped),
                    model = model,
                    coords = pedConfig.coords,
                    anim = pedConfig.anim,
                    weapon = pedConfig.weapon,
                    items = pedConfig.items,
                    detectionRadius = pedConfig.detectionRadius or 2.0
                }
            end
        end
    end
    
    if next(homeowners) then
        TriggerClientEvent("lunar_contracts:house:handleHomeownersLogic", -1, contract.locationIndex, contract.tier, homeowners, contractId)
    end
end

local function countActiveContractsByTier(tier)
    local count = 0
    for _, contract in pairs(activeHouseContracts) do
        if contract.tier == tier then
            count = count + 1
        end
    end
    return count
end

local function countLocationsByTier(tier)
    local count = 0
    for _, location in pairs(houseConfig.locations) do
        if location.tier == tier then
            count = count + 1
        end
    end
    return count
end

local function isLocationInUse(locationIndex, tier)
    for _, contract in pairs(activeHouseContracts) do
        if contract.locationIndex == locationIndex and contract.tier == tier then
            return true
        end
    end
    return false
end

local function selectRandomTier()
    local availableTiers = {}
    local totalChance = 0
    
    for tierIndex, tier in pairs(houseConfig.tiers) do
        if countActiveContractsByTier(tierIndex) < countLocationsByTier(tierIndex) then
            if not tier.settings or not tier.settings.disabled then
                table.insert(availableTiers, tierIndex)
                totalChance = totalChance + tier.chance
            end
        end
    end
    
    local randomValue = math.random(math.floor(totalChance))
    local cumulativeChance = 0
    
    for _, tierIndex in ipairs(availableTiers) do
        cumulativeChance = cumulativeChance + houseConfig.tiers[tierIndex].chance
        if randomValue <= cumulativeChance then
            return tierIndex
        end
    end
end

local function getRequiredToolsText(hasKeypad)
    local tools = {}
    
    if hasKeypad then
        if houseConfig.hackingItem and houseConfig.hackingItem.name then
            table.insert(tools, Utils.getItemLabel(houseConfig.hackingItem.name))
        end
    else
        if houseConfig.lockpickItem and houseConfig.lockpickItem.name then
            table.insert(tools, Utils.getItemLabel(houseConfig.lockpickItem.name))
        end
    end
    
    if #tools == 0 then
        return locale("no_tools")
    end
    
    return table.concat(tools, ", ")
end

local function getTierIndex(tierName)
    if tierName then
        for index, tier in pairs(houseConfig.tiers) do
            if tier.label == tierName then
                return index
            end
        end
    end
    return selectRandomTier()
end

local function spawnPaintings(contractId)
    local contract = activeHouseContracts[contractId]
    local interior = houseConfig.interiors[contract.tier]
    
    if not interior.paintings then return end
    
    local paintingModels = {
        1860271043, 645688058, 876512894, 158478566, 397364576,
        -274367155, -33875464, -1302822220, -526786762, -2120801998
    }
    
    local modelIndex = math.random(#paintingModels)
    local paintingNetIds = {}
    local bucketId = 4000 + contract.locationIndex
    
    for i = 1, #interior.paintings.locations do
        local coords = Utils.offsetCoords(interior.paintings.locations[i], 0.0, -0.01, 0.0)
        local painting = CreateObjectNoOffset(paintingModels[modelIndex], coords.x, coords.y, coords.z - 0.5, true, false, false)
        SetEntityHeading(painting, coords.w)
        SetEntityRoutingBucket(painting, bucketId)
        
        if not houseEntities[contractId] then
            houseEntities[contractId] = {}
        end
        table.insert(houseEntities[contractId], painting)
        table.insert(paintingNetIds, NetworkGetNetworkIdFromEntity(painting))
        
        modelIndex = modelIndex + 1
        if modelIndex > #paintingModels then modelIndex = 1 end
    end
    
    TriggerClientEvent("lunar_contracts:house:syncRoomId", -1, contract.locationIndex, paintingNetIds)
end

local function spawnDisplayCase(contractId)
    local contract = activeHouseContracts[contractId]
    local interior = houseConfig.interiors[contract.tier]
    
    if not interior.displayCase then return end
    
    local bucketId = 4000 + contract.locationIndex
    local displayCaseCoords = interior.displayCase.coords
    
    local displayCase = CreateObjectNoOffset(interior.displayCase.model, displayCaseCoords.x, displayCaseCoords.y, displayCaseCoords.z - 1.0, true, false, false)
    SetEntityHeading(displayCase, displayCaseCoords.w + 180.0)
    SetEntityRoutingBucket(displayCase, bucketId)
    
    if not houseEntities[contractId] then
        houseEntities[contractId] = {}
    end
    table.insert(houseEntities[contractId], displayCase)
    
    local lootItem = Utils.randomFromTable(interior.displayCase.items)
    
    if lootItem.model == 677732008 then
        local base = CreateObjectNoOffset(167446900, displayCaseCoords.x, displayCaseCoords.y, displayCaseCoords.z, true, false, false)
        SetEntityHeading(base, displayCaseCoords.w + 180.0)
        SetEntityRoutingBucket(base, bucketId)
        
        if not houseEntities[contractId] then
            houseEntities[contractId] = {}
        end
        table.insert(houseEntities[contractId], base)
    end
    
    if lootItem.model then
        local lootObject = CreateObjectNoOffset(lootItem.model, displayCaseCoords.x, displayCaseCoords.y, displayCaseCoords.z, true, false, false)
        SetEntityHeading(lootObject, displayCaseCoords.w + 180.0)
        SetEntityRoutingBucket(lootObject, bucketId)
        
        if not houseEntities[contractId] then
            houseEntities[contractId] = {}
        end
        table.insert(houseEntities[contractId], lootObject)
    end
end

local function spawnStaticPeds(contractId)
    local contract = activeHouseContracts[contractId]
    local interior = houseConfig.interiors[contract.tier]
    
    if not interior.staticPeds then return end
    
    local bucketId = 4000 + contract.locationIndex
    
    for _, pedConfig in pairs(interior.staticPeds) do
        local ped = CreatePed(4, pedConfig.model, pedConfig.coords.x, pedConfig.coords.y, pedConfig.coords.z - 1.0, pedConfig.coords.w, true, true)
        SetEntityRoutingBucket(ped, bucketId)
        SetPedRandomComponentVariation(ped, 1)
        SetPedRandomProps(ped)
        
        if not houseEntities[contractId] then
            houseEntities[contractId] = {}
        end
        table.insert(houseEntities[contractId], ped)
        
        if not contract.staticPeds then
            contract.staticPeds = {}
        end
        table.insert(contract.staticPeds, ped)
        
        Entity(ped).state:set("house:setupStaticPed", contract.locationIndex)
    end
end

local function createContract(contractId, tierName)
    local tier = getTierIndex(tierName)
    local interior = houseConfig.interiors[tier]
    
    local availableLocations = {}
    for i = 1, #houseConfig.locations do
        if houseConfig.locations[i].tier == tier then
            if not isLocationInUse(i, tier) then
                table.insert(availableLocations, i)
            end
        end
    end
    
    if #availableLocations == 0 then return end
    
    local locationIndex = Utils.randomFromTable(availableLocations)
    
    local paintings = {}
    if interior.paintings then
        for i = 1, #interior.paintings.locations do
            paintings[i] = true
        end
    end
    
    local displayCaseLoot = nil
    if interior.displayCase then
        displayCaseLoot = Utils.randomFromTable(interior.displayCase.items).name
    end
    
    activeHouseContracts[contractId] = {
        locationIndex = locationIndex,
        tier = tier,
        started = false,
        opened = false,
        paintings = paintings,
        guards = {},
        displayCaseLoot = displayCaseLoot,
        looted = {},
        staticPeds = {},
        alarm = false,
        alertLevel = 0.0,
        inProgress = false,
        abandoned = false,
        owner = nil,
        members = nil,
        exitTimeout = nil,
        exitNotified = false,
        hostEnteredOnce = false
    }
    
    return tier
end

startExitTimeout = function(contractId)
    local config = houseConfig.exitTimeout
    if not config or not config.enabled then return end

    local contract = activeHouseContracts[contractId]
    if not contract or not contract.owner or not contract.hostEnteredOnce then return end

    CreateThread(function()
        local timeout = config.timeout
        local radius = config.radius
        local gracePeriod = config.gracePeriod or 10

        local location = houseConfig.locations[contract.locationIndex]
        local interior = houseConfig.interiors[contract.tier]
        local outsideCoords = location.coords.xyz
        local insideCoords = interior.coords.xyz

        while activeHouseContracts[contractId] do
            if contract.abandoned then break end

            Wait(1000)

            if not activeHouseContracts[contractId] then break end
            if not contract.inProgress then break end
            if not contract.hostEnteredOnce then break end

            local owner = Framework.getPlayerFromIdentifier(contract.owner)
            if not owner then
                contract.abandoned = true
                contract.inProgress = false
                cleanupContract(contractId)
                break
            end

            local ownerPed = GetPlayerPed(owner.source)
            local ownerCoords = GetEntityCoords(ownerPed)
            local distToOutside = #(ownerCoords - outsideCoords)
            local distToInside = #(ownerCoords - insideCoords)

            if distToOutside > radius and distToInside > radius then
                if not contract.exitTimeout then
                    contract.exitTimeout = timeout
                    if not contract.exitNotified then
                        TriggerClientEvent("lunar_contracts:house:ownerLeftArea", owner.source, timeout)
                        contract.exitNotified = true
                    end
                else
                    contract.exitTimeout = contract.exitTimeout - 1
                    if contract.exitTimeout <= 0 then
                        contract.abandoned = true
                        contract.inProgress = false

                        for _, memberId in ipairs(contract.members) do
                            local member = Framework.getPlayerFromIdentifier(memberId)
                            if member then
                                TriggerClientEvent("lunar_contracts:house:contractAbandoned", member.source)
                            end
                        end

                        cleanupContract(contractId)
                        break
                    end
                end
            else
                if contract.exitTimeout then
                    if contract.exitTimeout > timeout - gracePeriod then
                        TriggerClientEvent("lunar_contracts:house:ownerReturnedToArea", owner.source)
                    end
                    contract.exitTimeout = nil
                    contract.exitNotified = false
                end
            end
        end
    end)
end

cleanupContract = function(contractId)
    local contract = activeHouseContracts[contractId]
    if not contract then return end
    
    contract.inProgress = false
    
    if houseLocationStates[contract.locationIndex] and houseLocationStates[contract.locationIndex].contractIndex == contractId then
        houseLocationStates[contract.locationIndex] = nil
    end
    
    activeHouseContracts[contractId] = nil
    
    TriggerClientEvent("lunar_contracts:house:reset", -1, contractId, true, contract.locationIndex)
    TriggerClientEvent("lunar_contracts:house:removeGuards", -1, contract.locationIndex)
    HideContractObjective(contractId)
    DeleteContract(contractId)
    cleanUpLocationEntities(contractId)
    
    for playerId, locIndex in pairs(playerLocations) do
        if locIndex == contract.locationIndex then
            playerLocations[playerId] = nil
            SetPlayerRoutingBucket(playerId, 0)
            Player(playerId).state.instance = nil
        end
    end
end

local function startContract(contractId)
    local contract = activeHouseContracts[contractId]
    if not contract then return end
    
    local interior = houseConfig.interiors[contract.tier]
    contract.started = true
    contract.inProgress = true
    
    local objectiveText = interior.guards and locale("obj_defeat_guards_enter_house") or locale("obj_enter_house")
    ShowContractObjective(contractId, locale("house_title"), objectiveText)
    
    spawnGuards(contractId)
    spawnHomeowners(contractId)
    spawnPaintings(contractId)
    spawnDisplayCase(contractId)
    spawnStaticPeds(contractId)
    
    if interior.loot then
        for _, lootLocation in ipairs(interior.loot.locations) do
            lootLocation.requires = "house_" .. contract.locationIndex
        end
        contract.loot = Loot.new(interior.loot, 4000 + contract.locationIndex)
    end
    
    TriggerClientEvent("lunar_contracts:house:started", -1, contract.members, contractId, contract.locationIndex, contract.tier, contract.loot and contract.loot.index)
    TriggerEvent("lunar_contracts:house:announceStarted", contractId, contract.members, contract.locationIndex)
    
    SetTimeout(houseConfig.duration * 60000, function()
        cleanupContract(contractId)
    end)
end

Missions.house = {}

function Missions.house.canBeGenerated(tierName)
    if tierName then
        local tier = getTierIndex(tierName)
        return countActiveContractsByTier(tier) < countLocationsByTier(tier)
    end
    return Utils.getTableSize(activeHouseContracts) < #houseConfig.locations
end

function Missions.house.generated(contractId, tierName)
    local tier = createContract(contractId, tierName)
    local tierData = houseConfig.tiers[tier]
    local location = houseConfig.locations[activeHouseContracts[contractId].locationIndex]
    
    local metadata = {
        { left = locale("house_tier"), right = tierData.label },
        { left = locale("required_tools"), right = getRequiredToolsText(not not location.keypad) }
    }
    
    return tierData.image, metadata
end

Missions.house.deleted = cleanupContract

function Missions.house.cancelled(contractId)
    local contract = activeHouseContracts[contractId]
    if contract then
        contract.abandoned = true
        contract.inProgress = false
        contract.exitTimeout = nil
        contract.exitNotified = false
        
        for playerId, locIndex in pairs(playerLocations) do
            if locIndex == contract.locationIndex then
                playerLocations[playerId] = nil
                SetPlayerRoutingBucket(playerId, 0)
                Player(playerId).state.instance = nil
            end
        end
    end
    
    TriggerClientEvent("lunar_contracts:house:reset", -1, contractId, true, contract and contract.locationIndex)
    HideContractObjective(contractId)
end

function Missions.house.start(contractId, data)
    local contract = activeHouseContracts[contractId]
    if not contract then return end
    
    contract.started = true
    contract.inProgress = true
    contract.owner = data.owner
    contract.members = data.members
    
    startContract(contractId)
end

function Missions.house.getPrice(contractId)
    return houseConfig.tiers[activeHouseContracts[contractId].tier].price
end

function Missions.house.getRequiredExperience(contractId)
    return houseConfig.tiers[activeHouseContracts[contractId].tier].requiredExperience
end

function Missions.house.getReward(contractId)
    return houseConfig.tiers[activeHouseContracts[contractId].tier].reward
end

function Missions.house.getSaveData(contractId)
    if not activeHouseContracts then
        error("Can't fetch save data from a house contract.")
    end
    
    return {
        contractIndex = contractId,
        tierLabel = houseConfig.tiers[activeHouseContracts[contractId].tier].label
    }
end

function Missions.house.loadSaveData(data)
    createContract(data.contractIndex, data.tierLabel)
end

function Missions.house.getCancelPoint(contractId)
    local contract = activeHouseContracts[contractId]
    return houseConfig.locations[contract.locationIndex].coords
end

function Missions.house.getSettings(contractId)
    return getContractSettings(contractId)
end

function Missions.house.getTierSettings(tierName)
    return getTierSettings(tierName)
end

-- Ox Inventory hook for heavy item restriction
if GetResourceState("ox_inventory") == "started" then
    exports.ox_inventory:registerHook("swapItems", function(data)
        if data.toType ~= "player" then return end
        if data.fromInventory == data.toInventory then return end
        
        local itemName = data.fromSlot.name
        local isHeavyItem = false
        
        if houseConfig.carryItems and houseConfig.carryItems.enabled then
            for _, heavyItem in ipairs(houseConfig.carryItems.list) do
                if heavyItem.name == itemName then
                    isHeavyItem = true
                    break
                end
            end
        end
        
        if not isHeavyItem then return end
        
        if data.count and data.count > 1 then
            LR.notify(data.source, locale("you_cannot_carry_two_heavy_items"), "error")
            return false
        end
        
        local targetInventory = data.toInventory
        local hasHeavyItem = false
        local items = exports.ox_inventory.GetInventoryItems(targetInventory)
        
        if items then
            for _, item in pairs(items) do
                for _, heavyItem in ipairs(houseConfig.carryItems.list) do
                    if item.name == heavyItem.name then
                        hasHeavyItem = true
                        break
                    end
                end
                if hasHeavyItem then break end
            end
        end
        
        if hasHeavyItem then
            LR.notify(data.source, locale("you_cannot_carry_two_heavy_items"), "error")
            return false
        end
    end)
end
