PreloadDicts("anim@scripted@player@mission@tunf_train_ig1_container_p1@male@")

local cargoConfig = Config.contracts.cargo
local activeContracts = {}
local currentBlip = nil
local radiusBlip = nil

local function startCargo(locationIndex, requiredItems)
    local location = cargoConfig.locations[locationIndex]
    
    currentBlip = Utils.createBlip(location.coords, cargoConfig.blip)
    radiusBlip = Utils.createRadiusBlip(location.coords, "", location.radius * 2, cargoConfig.blip.color)
    SetBlipRoute(currentBlip.value, true)
    
    LR.showObjective(locale("cargo_title"), locale("obj_go_to_containers"))
    Utils.distanceWait(location.coords, location.radius * 2.0)
    
    currentBlip.remove()
    radiusBlip.remove()
    
    LR.showObjective(locale("cargo_title"), locale("obj_loot_containers", table.concat(requiredItems, ", ")))
end

RegisterNetEvent("lunar_contracts:cargo:started", function(members, locationIndex, requiredItems)
    local contract = {}
    contract.zones = {}
    contract.props = {}
    contract.entities = {}
    activeContracts[locationIndex] = contract
    
    for _, memberId in ipairs(members) do
        if Framework.getIdentifier() == memberId then
            contract.member = true
            startCargo(locationIndex, requiredItems)
            return
        end
    end
end)

-- Open container animation
local function openContainer(containerCoords, containerObject, lockObject)
    if Editable.isDead(cache.ped) then return end
    
    CreateThread(function()
        LR.progressBar(locale("opening_container"), 10000, false)
    end)
    
    local animDict = "anim@scripted@player@mission@tunf_train_ig1_container_p1@male@"
    lib.requestModel(-2023225718)
    lib.requestModel(1860506282)
    lib.requestNamedPtfxAsset("scr_tn_tr")
    
    local grinderObject = CreateSceneObject(-2023225718, containerCoords)
    local bagObject = CreateSceneObject(1860506282, containerCoords)
    local rotation = GetEntityRotation(containerObject)
    
    local scene = NetworkCreateSynchronisedScene(containerCoords.x, containerCoords.y, containerCoords.z - 1.0, rotation.x, rotation.y, rotation.z, 2, true, false, 1.0, 0, 1.0)
    
    NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, "action", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(containerObject, scene, animDict, "action_container", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(lockObject, scene, animDict, "action_lock", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(grinderObject, scene, animDict, "action_angle_grinder", 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(bagObject, scene, animDict, "action_bag", 1.0, -1.0, 1148846080)
    
    NetworkStartSynchronisedScene(scene)
    
    -- Check for player death during animation
    CreateThread(function()
        for i = 1, 100 do
            if Editable.isDead(cache.ped) then
                DeleteEntity(grinderObject)
                DeleteEntity(bagObject)
                TriggerServerEvent("lunar_contracts:cargo:cancelSync")
                return
            end
            Wait(100)
        end
    end)
    
    Wait(4000)
    
    UseParticleFxAssetNextCall("scr_tn_tr")
    local sparks = StartParticleFxLoopedOnEntity("scr_tn_tr_angle_grinder_sparks", grinderObject, 0.0, 0.25, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
    
    Wait(1000)
    StopParticleFxLooped(sparks, true)
    
    Wait((GetAnimDuration(animDict, "action") * 1000) - 6100)
    
    DeleteEntity(grinderObject)
    DeleteEntity(bagObject)
    SetModelAsNoLongerNeeded(-2023225718)
    SetModelAsNoLongerNeeded(1860506282)
    RemoveNamedPtfxAsset("scr_tn_tr")
end

-- Sync container for other players
RegisterNetEvent("lunar_contracts:cargo:syncContainer", function(locationIndex, containerIndex, coords, containerModel)
    local contract = activeContracts[locationIndex]
    if not contract then return end
    
    if contract.zones[containerIndex] and contract.zones[containerIndex].remove then
        contract.zones[containerIndex].remove()
        contract.zones[containerIndex] = nil
    end
    
    Wait(1500)
    
    local animDict = "anim@scripted@player@mission@tunf_train_ig1_container_p1@male@"
    lib.requestAnimDict(animDict)
    lib.requestModel(containerModel)
    lib.requestModel(-469102706)
    
    local containerObj = CreateObjectNoOffset(containerModel, coords.x, coords.y, coords.z - 5.0, false, true, false)
    local lockObj = CreateObjectNoOffset(-469102706, coords.x, coords.y, coords.z + 0.4, false, true, false)
    
    SetEntityHeading(containerObj, coords.w)
    SetEntityHeading(lockObj, coords.w)
    FreezeEntityPosition(containerObj, true)
    FreezeEntityPosition(lockObj, true)
    SetEntityVisible(containerObj, false, false)
    SetEntityVisible(lockObj, false, false)
    SetCanClimbOnEntity(lockObj, false)
    
    local rotation = GetEntityRotation(containerObj)
    
    local scene = CreateSynchronizedScene(coords.x, coords.y, coords.z - 1.0, rotation.x, rotation.y, rotation.z, 2)
    
    local bagCoords = Utils.offsetCoords(coords, 0.0, -1.825, 0.2)
    local bagObj = CreateObjectNoOffset(2009935917, bagCoords.x, bagCoords.y, bagCoords.z - 5.0, false, true, false)
    SetEntityHeading(bagObj, bagCoords.w)
    FreezeEntityPosition(bagObj, true)
    SetEntityVisible(bagObj, false, false)
    
    PlaySynchronizedEntityAnim(containerObj, scene, "action_container", animDict, 1.0, -1.0, 0, 1148846080)
    ForceEntityAiAndAnimationUpdate(containerObj)
    PlaySynchronizedEntityAnim(bagObj, scene, "action_lock", animDict, 1.0, -1.0, 0, 1148846080)
    ForceEntityAiAndAnimationUpdate(bagObj)
    
    SetEntityCollision(containerObj, false, true)
    SetSynchronizedScenePhase(scene, 0.99)
    Wait(100)
    
    SetEntityVisible(containerObj, true)
    SetEntityVisible(bagObj, true)
    SetEntityCoords(containerObj, coords.x, coords.y, coords.z - 1.0)
    SetEntityCoords(bagObj, coords.x, coords.y, coords.z)
    
    SetModelAsNoLongerNeeded(containerModel)
    SetModelAsNoLongerNeeded(-469102706)
    
    table.insert(contract.entities, containerObj)
    table.insert(contract.entities, bagObj)
    table.insert(contract.entities, lockObj)
end)

-- Spawn container interactions
RegisterNetEvent("lunar_contracts:cargo:spawned", function(locationIndex, containerIds, lockIds)
    activeContracts[locationIndex] = activeContracts[locationIndex] or {
        zones = {},
        props = {},
        entities = {}
    }
    
    local containers = cargoConfig.locations[locationIndex].containers
    local contract = activeContracts[locationIndex]
    
    for i, container in ipairs(containers) do
        local offsetCoords = Utils.offsetCoords(container, 0.0, -1.9, 0.2)
        
        contract.zones[i] = Utils.createInteractionPoint({
            coords = offsetCoords,
            radius = 1.5,
            options = {{
                label = locale("open_container"),
                icon = "unlock",
                onSelect = function()
                    if cargoConfig.requiredItem and not Framework.hasItem(cargoConfig.requiredItem) then
                        LR.notify(locale("missing_" .. cargoConfig.requiredItem), "error")
                        return
                    end
                    
                    local spotId = string.format("container_%s_%s", locationIndex, i)
                    if IsSpotOccupied(spotId) then return end
                    
                    local containerObj = NetworkGetEntityFromNetworkId(containerIds[i])
                    local lockObj = NetworkGetEntityFromNetworkId(lockIds[i])
                    
                    TriggerServerEvent("lunar_contracts:cargo:syncContainer", locationIndex, i, { containerIds[i], lockIds[i] })
                    openContainer(container, containerObj, lockObj)
                    FreeOccupiedSpot()
                end,
                canInteract = function()
                    return not IsEntityPlayingAnim(cache.ped, "anim@scripted@player@mission@tunf_train_ig1_container_p1@male@", "action", 3)
                end
            }}
        })
    end
end)

-- Spawn loot props
RegisterNetEvent("lunar_contracts:cargo:spawnLoot", function(locationIndex, lootIndex, lootCoords)
    local contract = activeContracts[locationIndex]
    if not contract then return end
    
    contract.props[lootIndex] = Utils.createProp(lootCoords, {
        model = 2055492359,
        offset = vector3(0.0, 0.0, -0.3)
    }, {{
        label = locale("take_loot"),
        icon = "hand",
        onSelect = function()
            if LR.progressBar(locale("taking_loot"), cargoConfig.loot.progressDuration, false, {
                dict = "missbigscore2aig_7@driver",
                clip = "boot_r_loop",
                flag = 1
            }) then
                TriggerServerEvent("lunar_contracts:cargo:takeLoot", locationIndex, lootIndex)
            end
        end,
        canInteract = function()
            return not IsEntityPlayingAnim(cache.ped, "missbigscore2aig_7@driver", "boot_r_loop", 3)
        end
    }})
end)

RegisterNetEvent("lunar_contracts:cargo:disableLoot", function(locationIndex, lootIndex)
    local contract = activeContracts[locationIndex]
    local prop = contract and contract.props[lootIndex]
    
    if prop and prop.disableOptions then
        prop.disableOptions()
    end
end)

-- Guard setup and logic
local guards = {}
local lootedGuards = {}

local function setupGuard(guardPed)
    SetPedDropsWeaponsWhenDead(guardPed, false)
    SetPedCombatAbility(guardPed, cargoConfig.guards.combatAbility)
    SetPedAccuracy(guardPed, cargoConfig.guards.accuracy)
    SetPedRelationshipGroupHash(guardPed, 1480610330)
    SetPedCombatAttributes(guardPed, 5, true)
    SetPedCombatAttributes(guardPed, 13, true)
    SetPedCombatAttributes(guardPed, 68, false)
    SetPedCombatAttributes(guardPed, 0, false)
    SetPedCurrentWeaponVisible(guardPed, true)
end

local function handleGuard(guardPed, locationIndex)
    if GetIsTaskActive(guardPed, 357) or GetIsTaskActive(guardPed, 343) then
        -- already in combat or guard task
    elseif math.random(1, 8) == 1 then
        TaskGuardCurrentPosition(guardPed, 15.0, 10.0, true)
    end
    
    local location = cargoConfig.locations[locationIndex]
    local players = lib.getNearbyPlayers(location.coords, location.radius, true)
    local closestPlayer = nil
    local closestDist = math.huge
    
    for _, player in ipairs(players) do
        local playerPed = player.ped
        local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(guardPed))
        if closestDist > dist and not Editable.isDead(playerPed) then
            if GetSelectedPedWeapon(playerPed) ~= -1569615261 then
                closestPlayer = playerPed
                closestDist = dist
            end
        end
    end
    
    if not closestPlayer then
        players = lib.getNearbyPlayers(location.coords, location.radius * 2, true)
        for _, player in ipairs(players) do
            local playerPed = player.ped
            local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(guardPed))
            if closestDist > dist and not Editable.isDead(guardPed) then
                if GetSelectedPedWeapon(playerPed) ~= -1569615261 then
                    closestPlayer = playerPed
                    closestDist = dist
                end
            end
        end
    end
    
    if closestPlayer and not GetIsTaskActive(guardPed, 343) then
        TaskCombatPed(guardPed, closestPlayer, 0, 16)
        SetPedAlertness(guardPed, 3)
    end
end

AddRelationshipGroup("MERRYWEATHER_GUARD")

local guardInteractionPoints = {}

local function lootGuard(data)
    local locationIndex = data.locationIndex
    local guardNetId = data.netId
    
    if IsSpotOccupied(string.format("cargo:guard_%s", guardNetId)) then return end
    
    local success = LR.progressBar(locale("looting_guard"), cargoConfig.guards.looting.progressDuration, false, {
        dict = "missbigscore2aig_7@driver",
        clip = "boot_r_loop",
        flag = 1
    })
    
    if success then
        TriggerServerEvent("lunar_contracts:cargo:lootGuard", locationIndex, guardNetId)
    end
    FreeOccupiedSpot()
end

RegisterNetEvent("lunar_contracts:cargo:guardLooted", function(guardNetId)
    lootedGuards[guardNetId] = true
    if guardInteractionPoints[guardNetId] then
        guardInteractionPoints[guardNetId].remove()
        guardInteractionPoints[guardNetId] = nil
    end
end)

local function addGuardLootPoint(guardNetId, guardPed, locationIndex)
    if guardInteractionPoints[guardNetId] then return end
    
    guardInteractionPoints[guardNetId] = Utils.createEntityPoint({
        entity = guardPed,
        radius = 1.5,
        options = {{
            label = locale("take_loot"),
            icon = "hand",
            onSelect = lootGuard,
            args = { locationIndex = locationIndex, netId = guardNetId },
            canInteract = function()
                return not Busy and Utils.distanceCheck(cache.ped, guardPed, 1.5)
            end
        }}
    })
end

local guardBlips = {}

local function handleGuardsLogic(locationIndex, guardsNetIds)
    SetRelationshipBetweenGroups(0, 1480610330, 1480610330)
    SetRelationshipBetweenGroups(4, 1480610330, 1862763509)
    SetRelationshipBetweenGroups(4, 1862763509, 1480610330)
    
    local inRange = Utils.distanceCheck(cache.ped, cargoConfig.locations[locationIndex].coords, cargoConfig.locations[locationIndex].radius * 2.0)
    
    for i, guardNetId in ipairs(guardsNetIds) do
        if NetworkDoesEntityExistWithNetworkId(guardNetId) then
            local guardPed = NetworkGetEntityFromNetworkId(guardNetId)
            local owner = NetworkGetEntityOwner(guardPed)
            
            if owner == cache.playerId then
                setupGuard(guardPed)
                handleGuard(guardPed, locationIndex)
            end
            
            if IsEntityDead(guardPed) then
                if not lootedGuards[guardNetId] then
                    addGuardLootPoint(guardNetId, guardPed, locationIndex)
                end
                
                if inRange and guardBlips[i] then
                    guardBlips[i].remove()
                    guardBlips[i] = nil
                end
            elseif inRange then
                if not guardBlips[i] then
                    guardBlips[i] = Utils.createEntityBlip(guardPed, cargoConfig.guards.blip)
                end
            elseif guardBlips[i] then
                guardBlips[i].remove()
                guardBlips[i] = nil
            end
        else
            if guardInteractionPoints[guardNetId] and cargoConfig.guards.looting.enabled then
                guardInteractionPoints[guardNetId].remove()
                guardInteractionPoints[guardNetId] = nil
            end
        end
    end
end

local guardZones = {}

RegisterNetEvent("lunar_contracts:cargo:handleGuardsLogic", function(locationIndex, guardsNetIds)
    guardZones[locationIndex] = lib.points.new({
        coords = cargoConfig.locations[locationIndex].coords.xyz,
        distance = 420.0,
        nearby = function()
            handleGuardsLogic(locationIndex, guardsNetIds)
            Wait(1000)
        end
    })
end)

-- Stop cargo contract
RegisterNetEvent("lunar_contracts:cargo:stop", function(locationIndex, guardNetIds)
    if guardZones[locationIndex] then
        guardZones[locationIndex].remove()
        guardZones[locationIndex] = nil
    end
    
    for _, blip in pairs(guardBlips) do
        if blip then blip.remove() end
    end
    guardBlips = {}
    
    for _, netId in ipairs(guardNetIds) do
        lootedGuards[netId] = nil
        if guardInteractionPoints[netId] then
            guardInteractionPoints[netId].remove()
            guardInteractionPoints[netId] = nil
        end
    end
    
    local contract = activeContracts[locationIndex]
    if contract then
        for _, prop in pairs(contract.props) do
            if prop and prop.remove then prop.remove() end
        end
        
        for _, entity in ipairs(contract.entities) do
            if DoesEntityExist(entity) then DeleteEntity(entity) end
        end
        
        for _, zone in pairs(contract.zones) do
            if zone and zone.remove then zone.remove() end
        end
        
        if contract.member then
            LR.hideObjective()
        end
    end
    
    activeContracts[locationIndex] = nil
end)
