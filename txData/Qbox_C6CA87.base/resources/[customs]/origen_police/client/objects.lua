-- Police object placement system - Client side
local currentObject = 0
local lastCommandTime = GetGameTimer()
local placedObjects = {}

-- Command to place objects
RegisterCommand("plceobj", function(source, args)
    local playerData = FW_GetPlayerData(false)
    local canOpen = CanOpenTablet(playerData.job.name)
    
    if canOpen[1] and playerData.job.onduty then
        local currentTime = GetGameTimer()
        
        -- Rate limit: 1500ms between commands
        if (currentTime - lastCommandTime) > 1500 then
            lastCommandTime = GetGameTimer()
            
            -- Get object name from command args
            local objectName = table.concat(args, " ")
            local objectConfig = Config.Props[objectName]
            
            if objectConfig then
                SlectPropAndPos(
                    Config.Props[objectName],
                    Config.Props[objectName].Text,
                    Config.Props[objectName].Animations
                )
            end
        end
    end
end)

-- Find nearest placed object
function FindNearPlacedObject()
    local minDistance = 2.0
    local nearestSource = nil
    local nearestObjectId = nil
    local nearestEntity = nil
    local playerPos = GetEntityCoords(PlayerPedId())
    
    for source, objects in pairs(placedObjects) do
        for objectId, entity in pairs(objects) do
            if DoesEntityExist(entity) then
                local objectCoords = GetEntityCoords(entity)
                local objectModel = GetEntityModel(entity)
                
                -- Special handling for specific prop model
                if objectModel == 1927491455 then
                    objectCoords = vector3(objectCoords.x, objectCoords.y, objectCoords.z + 7.0)
                end
                
                local distance = #(playerPos - objectCoords)
                
                if distance < minDistance then
                    minDistance = distance
                    nearestSource = source
                    nearestObjectId = objectId
                    nearestEntity = entity
                end
            end
        end
    end
    
    return nearestSource, nearestObjectId, nearestEntity
end

-- Command to remove objects
RegisterCommand("rmveobj", function()
    local playerData = FW_GetPlayerData(false)
    local canOpen = CanOpenTablet(playerData.job.name)
    
    if canOpen[1] and playerData.job.onduty then
        local currentTime = GetGameTimer()
        
        if (currentTime - lastCommandTime) > 1500 then
            lastCommandTime = GetGameTimer()
            
            local source, objectId, entity = FindNearPlacedObject()
            
            if entity then
                -- Play pickup animation
                RequestAnimDict("pickup_object")
                while not HasAnimDictLoaded("pickup_object") do
                    Citizen.Wait(7)
                end
                
                TaskPlayAnim(PlayerPedId(), "pickup_object", "pickup_low", 8.0, -8.0, -1, 1, 0, false, false, false)
                
                Citizen.SetTimeout(700, function()
                    TriggerServerEvent("origen_police:callback:rmveobj", source, objectId, GetEntityCoords(entity))
                end)
                
                Citizen.Wait(1000)
                ClearPedTasks(PlayerPedId())
            end
        else
            ShowNotification(Config.Translations.CantFast)
        end
    end
end)

-- Object placement UI and position selection
function SlectPropAndPos(propConfig, propText, animations)
    local ped = PlayerPedId()
    local playerPos = GetEntityCoords()
    local currentPropIndex = 1
    local currentProp = propConfig.Props[currentPropIndex]
    
    -- Delete any existing preview object
    DeleteEntity(currentObject)
    currentObject = 0
    HideHelpNotification()
    Wait(500)
    
    -- Generate preview object
    currentObject = GenerateObject(currentProp.model, playerPos, animations.dict)
    
    -- Attach preview to player
    AttachEntityToEntity(
        currentObject,
        ped,
        currentProp.bone,
        currentProp.x + 0.0,
        currentProp.y + 0.0,
        currentProp.z + 0.0,
        currentProp.xr + 0.0,
        currentProp.yr + 0.0,
        currentProp.zr + 0.0,
        true,
        true,
        false,
        true,
        1,
        true
    )
    
    -- Main placement loop
    Citizen.CreateThread(function()
        local helpShown = false
        
        while currentObject ~= 0 do
            Citizen.Wait(5)
            playerPos = GetEntityCoords(ped)
            
            -- Show help notifications
            if Config.CustomNotify then
                if not helpShown then
                    if GetResourceState("origen_notify") == "started" then
                        ShowHelpNotification("E", Config.Translations.objects.place)
                        ShowHelpNotification("left", Config.Translations.objects.prev)
                        ShowHelpNotification("right", Config.Translations.objects.next)
                        ShowHelpNotification("backspace", Config.Translations.objects.cancel)
                        
                        if Config.Framework == "esx" then
                            CreateThread(function()
                                Wait(0)
                                helpShown = false
                            end)
                        end
                    else
                        ShowHelpNotification("E", Config.Translations.objects.fullText:format("[E]", "[LEFT]", "[RIGHT]", "[BACKSPACE]"))
                    end
                    helpShown = true
                end
            else
                if Config.Framework == "qbcore" and not helpShown then
                    helpShown = true
                    exports["qb-core"]:DrawText(Config.Translations.objects.fullText:format("[E]", "[LEFT]", "[RIGHT]", "[BACKSPACE]"))
                elseif Config.Framework == "esx" then
                    Framework.ShowHelpNotification(Config.Translations.objects.fullText:format("~INPUT_CONTEXT~", "~INPUT_CELLPHONE_LEFT~", "~INPUT_CELLPHONE_RIGHT~", "~INPUT_FRONTEND_RRIGHT~"))
                end
            end
            
            -- Play holding animation
            if animations.dict and animations.anim then
                if not IsEntityPlayingAnim(ped, animations.dict, animations.anim, 3) then
                    TaskPlayAnim(ped, animations.dict, animations.anim, 8.0, 8.0, -1, 51, false, false, false)
                end
            end
            
            -- E - Place object
            if IsControlJustPressed(0, 38) then
                local placeCoords = nil
                local placeHeading = nil
                
                -- Play placement animation if configured
                if animations.dictponer and animations.animponer then
                    RequestAnimDict(animations.dictponer)
                    while not HasAnimDictLoaded(animations.dictponer) do
                        Wait(1)
                    end
                    
                    TaskPlayAnim(ped, animations.dictponer, animations.animponer, 8.0, 8.0, -1, 0, false, false, false)
                    Citizen.Wait(1000)
                    
                    -- Calculate placement position in front of player
                    local forwardVector = GetEntityForwardVector(ped)
                    placeCoords = vector3(playerPos.x, playerPos.y, playerPos.z - 1) + (forwardVector * 1.0)
                    placeHeading = GetEntityHeading(ped)
                    
                    -- Special adjustment for cone light
                    if currentProp.model == "prop_air_conelight" then
                        placeCoords = placeCoords - vector3(0, 0, 0.15)
                    end
                else
                    -- Use current object position
                    placeCoords = GetEntityCoords(currentObject)
                    placeHeading = GetEntityHeading(currentObject)
                end
                
                -- Special handling for speed radar and plate reader
                if currentProp.type == "speed" or currentProp.type == "plate" then
                    local objectCoords = GetEntityCoords(currentObject)
                    local forwardVector = GetEntityForwardVector(currentObject)
                    
                    if currentProp.type == "speed" then
                        placeCoords = placeCoords - vector3(0, 0, 1)
                        
                        -- Open dialog for max speed
                        OpenMenu("dialog", GetCurrentResourceName(), "radarmaxspeed", {
                            title = Config.Translations.EnterMaxSpeed
                        }, function(data, menu)
                            if data and data.value then
                                local speed = tonumber(data.value)
                                if speed then
                                    TriggerServerEvent("origen_police:server:placeradar", {
                                        objectCoords = placeCoords,
                                        coords = placeCoords - (forwardVector * 22.5),
                                        value = tonumber(data.value),
                                        type = 1
                                    })
                                    menu.close()
                                end
                            else
                                ShowNotification(Config.Translations.MustEnterNumber)
                            end
                        end, function(data, menu)
                            menu.close()
                        end)
                    else
                        -- Plate reader
                        local tempObject = GenerateObject(currentProp.model, objectCoords)
                        SetEntityHeading(tempObject, GetEntityHeading(PlayerPedId()))
                        local tempForward = GetEntityForwardVector(tempObject)
                        DeleteEntity(tempObject)
                        
                        OpenMenu("dialog", GetCurrentResourceName(), "radarplate", {
                            title = Config.Translations.EnterPlate
                        }, function(data, menu)
                            if data and data.value then
                                TriggerServerEvent("origen_police:server:placeradar", {
                                    objectCoords = placeCoords,
                                    coords = placeCoords - (tempForward * 22.5),
                                    value = data.value,
                                    type = 2
                                })
                                menu.close()
                            else
                                ShowNotification(Config.Translations.MustEnterNumber)
                            end
                        end, function(data, menu)
                            menu.close()
                        end)
                    end
                    
                    -- Place the radar object
                    TriggerServerEvent("origen_police:server:placeobj", currentProp.model, placeCoords, placeHeading, not currentProp.physics)
                    DeleteEntity(currentObject)
                    
                    if animations.dict and animations.anim then
                        ClearPedTasks(GetPlayerPed(-1))
                    end
                    break
                else
                    -- Place regular object
                    TriggerServerEvent("origen_police:server:placeobj", currentProp.model, placeCoords, placeHeading, not currentProp.physics)
                end
            end
            
            -- LEFT - Previous prop
            if IsControlJustPressed(0, 174) then
                if propConfig.Props[currentPropIndex - 1] then
                    DeleteEntity(currentObject)
                    currentPropIndex = currentPropIndex - 1
                    currentProp = propConfig.Props[currentPropIndex]
                    
                    currentObject = GenerateObject(currentProp.model, playerPos)
                    AttachEntityToEntity(
                        currentObject,
                        ped,
                        currentProp.bone,
                        currentProp.x + 0.0,
                        currentProp.y + 0.0,
                        currentProp.z + 0.0,
                        currentProp.xr + 0.0,
                        currentProp.yr + 0.0,
                        currentProp.zr + 0.0,
                        true,
                        true,
                        false,
                        true,
                        1,
                        true
                    )
                end
            end
            
            -- RIGHT - Next prop
            if IsControlJustPressed(0, 175) then
                if propConfig.Props[currentPropIndex + 1] then
                    DeleteEntity(currentObject)
                    currentPropIndex = currentPropIndex + 1
                    currentProp = propConfig.Props[currentPropIndex]
                    
                    currentObject = GenerateObject(currentProp.model, playerPos)
                    AttachEntityToEntity(
                        currentObject,
                        ped,
                        currentProp.bone,
                        currentProp.x + 0.0,
                        currentProp.y + 0.0,
                        currentProp.z + 0.0,
                        currentProp.xr + 0.0,
                        currentProp.yr + 0.0,
                        currentProp.zr + 0.0,
                        true,
                        true,
                        false,
                        true,
                        1,
                        true
                    )
                end
            end
            
            -- BACKSPACE - Cancel placement
            if IsControlJustPressed(0, 202) then
                DeleteEntity(currentObject)
                
                if animations.dict and animations.anim then
                    ClearPedTasks(GetPlayerPed(-1))
                end
                break
            end
        end
        
        ClearPedTasks(PlayerPedId())
        HideHelpNotification()
    end)
end

-- Generate object helper
function GenerateObject(model, coords, animDict)
    if animDict then
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(1)
        end
    end
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(10)
    end
    
    return CreateObject(GetHashKey(model), coords.x, coords.y, coords.z, false, true, true)
end

-- Cleanup on resource stop
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        DeleteEntity(currentObject)
    end
end)

-- Network events for radar placement
RegisterNetEvent("origen_police:client:placeradar", function(radarData)
    table.insert(Public.Radars, radarData)
end)

RegisterNetEvent("origen_police:client:removeradar", function(index)
    table.remove(Public.Radars, index)
end)

-- Place object from server
RegisterNetEvent("origen_police:client:placeobj", function(placerData, objectData)
    local source = placerData.source
    
    -- Initialize source table if needed
    if not placedObjects[source] then
        placedObjects[source] = {}
    end
    
    -- Load model
    objectData.model = GetHashKey(objectData.model)
    local loaded = LoadModel(objectData.model, 5000)
    
    if not loaded then
        print("Could not load model to place: " .. objectData.model)
        placedObjects[source][placerData.objectId] = 1
        return
    end
    
    -- Create object
    local object = CreateObject(objectData.model, objectData.coords, false, true, false)
    SetEntityHeading(object, objectData.heading)
    FreezeEntityPosition(object, objectData.freeze)
    
    placedObjects[source][placerData.objectId] = object
end)

-- Remove object from server
RegisterNetEvent("origen_police:client:rmveobj", function(placerData)
    Debuger("Remove object, placer data: " .. json.encode(placerData))
    
    if placedObjects[placerData.source] then
        if placedObjects[placerData.source][placerData.objectId] then
            local entity = placedObjects[placerData.source][placerData.objectId]
            
            if DoesEntityExist(entity) then
                DeleteEntity(entity)
            end
            
            placedObjects[placerData.source][placerData.objectId] = nil
            
            -- Clean up empty source table
            if not next(placedObjects[placerData.source]) then
                placedObjects[placerData.source] = nil
            end
        end
    end
end)