PreloadDicts(
    "anim@scripted@heist@ig1_table_grab@cash@male@",
    "anim@scripted@heist@ig1_table_grab@gold@male@",
    "anim@heists@ornate_bank@grab_cash"
)

local lootData = {}

local function setLocationPhase(contractIndex, locationIndex, phase)
    local contract = lootData[contractIndex]
    if not contract then return end
    
    if phase >= 1.0 then phase = 0.99 end
    
    -- Remove phase zone if exists
    local phaseZone = contract.phaseZones and contract.phaseZones[locationIndex]
    if phaseZone then
        phaseZone:remove()
        contract.phaseZones[locationIndex] = nil
    end
    
    -- Remove phase scene if exists
    local scene = contract.phaseScenes and contract.phaseScenes[locationIndex]
    if scene then
        local location = contract.locations[locationIndex]
        if location.networked then
            NetworkStopSynchronisedScene(scene)
        else
            DetachSynchronizedScene(scene)
        end
        contract.phaseScenes[locationIndex] = nil
    end
    
    local processedObjects = {}
    local location = contract.locations[locationIndex]
    if not location then return end
    
    contract.phaseZones[locationIndex] = lib.points.new({
        coords = location.coords,
        distance = 30.0,
        onEnter = function()
            local obj = lib.getClosestObject(location.coords.xyz, 1.0)
            if not obj or processedObjects[obj] then return end
            
            local objCoords = GetEntityCoords(obj)
            local objRotation = GetEntityRotation(obj)
            local animDict, animName
            
            if location.type == "pile" then
                local lootType = location.lootType
                animDict = string.format("anim@scripted@heist@ig1_table_grab@%s@male@", lootType)
                animName = "grab_" .. lootType
            else
                animDict = "anim@heists@ornate_bank@grab_cash"
                animName = "cart_cash_dissapear"
            end
            
            if IsEntityPlayingAnim(obj, animDict, animName, 3) then return end
            
            if NetworkGetEntityIsNetworked(obj) then
                local rotation = Entity(obj).state["loot:rotation"]
                if rotation then
                    objRotation = vector3(objRotation.x, objRotation.y, rotation + 0.0)
                end
                
                local scene = NetworkCreateSynchronisedScene(
                    objCoords.x, objCoords.y, objCoords.z,
                    objRotation.x, objRotation.y, objRotation.z,
                    2, true, false, 1.0, phase, 0.0
                )
                NetworkAddEntityToSynchronisedScene(obj, scene, animDict, animName, 1.0, -1.0, 0)
                NetworkStartSynchronisedScene(scene)
            else
                local scene = CreateSynchronizedScene(
                    objCoords.x, objCoords.y, objCoords.z,
                    objRotation.x, objRotation.y, objRotation.z, 2
                )
                PlaySynchronizedEntityAnim(obj, scene, animName, animDict, 1000.0, -4.0, 1)
                ForceEntityAiAndAnimationUpdate(obj)
                SetSynchronizedSceneRate(scene, 0.0)
                SetSynchronizedScenePhase(scene, phase)
            end
            
            FreezeEntityPosition(obj, true)
            processedObjects[obj] = true
        end
    })
end

local function setLocationRotate(contractIndex, locationIndex)
    local contract = lootData[contractIndex]
    if not contract then return end
    
    local rotateZone = contract.rotateZones and contract.rotateZones[locationIndex]
    if rotateZone then
        rotateZone:remove()
    end
    
    local processedObjects = {}
    local location = contract.locations[locationIndex]
    if not location then return end
    
    contract.rotateZones[locationIndex] = lib.points.new({
        coords = location.coords,
        distance = 30.0,
        onEnter = function()
            local obj = lib.getClosestObject(location.coords.xyz, 1.0)
            if not obj or processedObjects[obj] then return end
            
            SetEntityRotation(obj, 0.0, 0.0, GetEntityHeading(obj) + location.coords.w + 0.0)
            processedObjects[obj] = true
        end
    })
end

Utils.entityStateHandler("loot:rotation", function(entity, rotation)
    if GetEntityHeading(entity) ~= rotation then
        SetEntityHeading(entity, rotation + 0.0)
        FreezeEntityPosition(entity, true)
    end
end, false)

RegisterNetEvent("lunar_contracts:loot:removeLocation", function(contractIndex, locationIndex)
    local contract = lootData[contractIndex]
    local location = contract and contract.locations[locationIndex]
    if not location then return end
    
    contract.zones[locationIndex]:remove()
    
    if location.type == "trolley" then
        setLocationPhase(contractIndex, locationIndex, 0.99)
    end
end)

RegisterNetEvent("lunar_contracts:loot:syncUnlocked", function(contractIndex, requires, unlocked)
    for i, location in ipairs(lootData[contractIndex].locations) do
        if location.requires == requires then
            location.unlocked = unlocked
        end
    end
end)

RegisterNetEvent("lunar_contracts:loot:setLocationPhase", setLocationPhase)

local forceStop = false

RegisterNetEvent("lunar_contracts:loot:forceStop", function()
    forceStop = true
end)

local function startTakingLoot(params)
    local contractIndex = params.index
    local locationIndex = params.locationIndex
    local location = params.location
    
    local currentWeapon = GetSelectedPedWeapon(cache.ped)
    if currentWeapon ~= -1569615261 then
        RemoveAllPedWeapons(cache.ped, true)
        Wait(500)
    end
    
    local obj = lib.getClosestObject(location.coords.xyz, 1.0)
    if not obj then return end
    
    if SetEntityRemoteSyncedScenesAllowed then
        SetEntityRemoteSyncedScenesAllowed(obj, true)
    end
    
    local success, startPhase, errorMsg = lib.callback.await("lunar_contracts:loot:startTaking", false, contractIndex, locationIndex)
    if not success then
        if errorMsg then
            LR.notify(errorMsg, "error")
        end
        return
    end
    
    if IsSpotOccupied(string.format("loot_%s_%s", contractIndex, locationIndex)) then
        return
    end
    
    if location.type == "pile" then
        local lootType = (location.lootType == "gold") and "gold" or "cash"
        local animDict = string.format("anim@scripted@heist@ig1_table_grab@%s@male@", lootType)
        
        lib.requestModel(-944468481)
        local objCoords = GetEntityCoords(obj)
        local objRotation = GetEntityRotation(obj)
        
        local sceneBag = CreateSceneObject(-944468481, objCoords)
        
        local sceneEnter = NetworkCreateSynchronisedScene(
            objCoords.x, objCoords.y, objCoords.z,
            objRotation.x, objRotation.y, objRotation.z,
            2, true, false, 1.0, 0, 1.0
        )
        NetworkAddPedToSynchronisedScene(cache.ped, sceneEnter, animDict, "enter", 1000.0, -1.5, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(sceneBag, sceneEnter, animDict, "enter_bag", 1.0, -1.0, 0)
        
        local sceneGrab = NetworkCreateSynchronisedScene(
            objCoords.x, objCoords.y, objCoords.z,
            objRotation.x, objRotation.y, objRotation.z,
            2, true, false, 1.0, startPhase or 0.0, 1.0
        )
        NetworkAddPedToSynchronisedScene(cache.ped, sceneGrab, animDict, "grab", 1000.0, -1.5, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(sceneBag, sceneGrab, animDict, "grab_bag", 1.0, -1.0, 0)
        NetworkAddEntityToSynchronisedScene(obj, sceneGrab, animDict, "grab_" .. lootType, 1.0, -1.0, 0)
        
        local sceneExit = NetworkCreateSynchronisedScene(
            objCoords.x, objCoords.y, objCoords.z,
            objRotation.x, objRotation.y, objRotation.z,
            2, false, false, 1.0, startPhase or 0.0, 1.0
        )
        NetworkAddPedToSynchronisedScene(cache.ped, sceneExit, animDict, "exit", 1000.0, -1.5, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(sceneBag, sceneExit, animDict, "exit_bag", 1.0, -1.0, 0)
        
        NetworkStartSynchronisedScene(sceneEnter)
        Wait((GetAnimDuration(animDict, "enter") * 1000) - 200)
        NetworkStartSynchronisedScene(sceneGrab)
        
        local grabbing = true
        local startTime = GetGameTimer()
        local grabDuration = GetAnimDuration(animDict, "grab") * 1000
        
        local timeout = Utils.setTimeout((1.0 - startPhase) * grabDuration - 200, function()
            grabbing = false
            setLocationPhase(contractIndex, locationIndex, 0.99)
            NetworkStartSynchronisedScene(sceneExit)
            Wait((GetAnimDuration(animDict, "exit") * 1000) - 200)
            DeleteEntity(sceneBag)
        end)
        
        Wait(0)
        while grabbing do
            if Editable.isDead(cache.ped) or not IsEntityPlayingAnim(cache.ped, animDict, "grab", 3) or forceStop then
                local elapsed = (GetGameTimer() - startTime) / grabDuration
                TriggerServerEvent("lunar_contracts:loot:stopTaking", contractIndex, locationIndex, elapsed)
                DeleteEntity(sceneBag)
                FreeOccupiedSpot()
                SetModelAsNoLongerNeeded(-944468481)
                setLocationPhase(contractIndex, locationIndex, startPhase + elapsed)
                timeout.cancel()
                forceStop = false
                return
            end
            Wait(100)
        end
        
    elseif location.type == "trolley" then
        local animDict = "anim@heists@ornate_bank@grab_cash"
        lib.requestModel(-944468481)
        
        local objCoords = GetEntityCoords(obj)
        local objRotation = GetEntityRotation(obj)
        
        local sceneBag = CreateSceneObject(-944468481, objCoords)
        
        local sceneIntro = NetworkCreateSynchronisedScene(
            objCoords.x, objCoords.y, objCoords.z,
            objRotation.x, objRotation.y, objRotation.z,
            2, true, false, 1.0, 0, 1.0
        )
        NetworkAddPedToSynchronisedScene(cache.ped, sceneIntro, animDict, "intro", 1000.0, -1.5, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(sceneBag, sceneIntro, animDict, "bag_intro", 1.0, -1.0, 0)
        
        local sceneGrab = NetworkCreateSynchronisedScene(
            objCoords.x, objCoords.y, objCoords.z,
            objRotation.x, objRotation.y, objRotation.z,
            2, true, false, 1.0, startPhase or 0.0, 1.0
        )
        NetworkAddPedToSynchronisedScene(cache.ped, sceneGrab, animDict, "grab", 1000.0, -1.5, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(sceneBag, sceneGrab, animDict, "bag_grab", 1.0, -1.0, 0)
        
        if NetworkGetEntityIsNetworked(obj) then
            NetworkAddEntityToSynchronisedScene(obj, sceneGrab, animDict, "cart_cash_dissapear", 1.0, -1.0, 1)
        else
            NetworkAddMapEntityToSynchronisedScene(sceneGrab, GetEntityModel(obj), objCoords.x, objCoords.y, objCoords.z, animDict, "cart_cash_dissapear", 1.0, -1.0, 1)
        end
        
        local sceneExit = NetworkCreateSynchronisedScene(
            objCoords.x, objCoords.y, objCoords.z,
            objRotation.x, objRotation.y, objRotation.z,
            2, false, false, 1.0, 0, 1.0
        )
        NetworkAddPedToSynchronisedScene(cache.ped, sceneExit, animDict, "exit", 1000.0, -1.5, 1037, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(sceneBag, sceneExit, animDict, "bag_exit", 1.0, -1.0, 0)
        
        local lootModel
        if location.lootType == "cash" then
            lootModel = 1246356548
        elseif location.lootType == "gold" then
            lootModel = -510900595
        elseif location.lootType == "diamonds" then
            lootModel = 1041247119
        end
        
        lib.requestModel(lootModel)
        local lootObject = CreateSceneObject(lootModel, objCoords)
        FreezeEntityPosition(lootObject, true)
        SetEntityInvincible(lootObject, true)
        SetEntityNoCollisionEntity(lootObject, cache.ped)
        SetEntityVisible(lootObject, false, false)
        AttachEntityToEntity(lootObject, cache.ped, GetPedBoneIndex(cache.ped, 60309), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 0, true)
        
        CreateThread(function()
            while IsEntityPlayingAnim(cache.ped, animDict, "grab", 3) do
                if HasAnimEventFired(cache.ped, 726137971) then
                    SetEntityVisible(lootObject, true, false)
                elseif HasAnimEventFired(cache.ped, -1157608532) then
                    SetEntityVisible(lootObject, false, false)
                end
                Wait(0)
            end
        end)
        
        NetworkStartSynchronisedScene(sceneIntro)
        Wait((GetAnimDuration(animDict, "intro") * 1000) - 200)
        NetworkStartSynchronisedScene(sceneGrab)
        
        local grabbing = true
        local startTime = GetGameTimer()
        local grabDuration = (GetAnimDuration(animDict, "grab") * 1000) - 200
        
        local timeout = Utils.setTimeout((1.0 - startPhase) * grabDuration, function()
            grabbing = false
            setLocationPhase(contractIndex, locationIndex, 0.99)
            DeleteEntity(lootObject)
            FreezeEntityPosition(obj, true)
            NetworkStartSynchronisedScene(sceneExit)
            Wait((GetAnimDuration(animDict, "exit") * 1000) - 1500)
            DeleteEntity(sceneBag)
            SetModelAsNoLongerNeeded(-944468481)
            SetModelAsNoLongerNeeded(lootModel)
        end)
        
        Wait(0)
        while grabbing do
            if Editable.isDead(cache.ped) or not IsEntityPlayingAnim(cache.ped, animDict, "grab", 3) or forceStop then
                local elapsed = (GetGameTimer() - startTime) / grabDuration
                TriggerServerEvent("lunar_contracts:loot:stopTaking", contractIndex, locationIndex, elapsed)
                DeleteEntity(lootObject)
                DeleteEntity(sceneBag)
                FreeOccupiedSpot()
                setLocationPhase(contractIndex, locationIndex, startPhase + elapsed)
                SetModelAsNoLongerNeeded(-944468481)
                SetModelAsNoLongerNeeded(lootModel)
                timeout.cancel()
                forceStop = false
                return
            end
            Wait(100)
        end
    end
    
    Wait(1000)
    FreeOccupiedSpot()
end

local function setupLoot(contractIndex, locations)
    lootData[contractIndex] = {
        locations = locations,
        zones = {},
        phaseZones = {},
        phaseScenes = {},
        rotateZones = {}
    }
    
    for i, location in ipairs(locations) do
        lootData[contractIndex].zones[i] = Utils.createInteractionPoint({
            coords = location.coords,
            radius = 1,
            options = {{
                label = locale("collect_" .. location.type),
                icon = "hand",
                onSelect = startTakingLoot,
                args = { index = contractIndex, locationIndex = i, location = location },
                canInteract = function() return not Busy end
            }}
        })
        
        if not location.networked then
            setLocationRotate(contractIndex, i)
        end
    end
end

lib.callback("lunar_contracts:getLoot", 1000, function(data)
    if not data then return end
    for index, locations in pairs(data) do
        setupLoot(index, locations)
    end
end)

RegisterNetEvent("lunar_contracts:loot:new", setupLoot)

RegisterNetEvent("lunar_contracts:loot:remove", function(contractIndex)
    local contract = lootData[contractIndex]
    if not contract then return end
    
    for _, zone in ipairs(contract.zones) do
        zone:remove()
    end
    
    for _, zone in pairs(contract.phaseZones) do
        zone:remove()
    end
    
    for _, zone in pairs(contract.rotateZones) do
        zone:remove()
    end
    
    lootData[contractIndex] = nil
end)