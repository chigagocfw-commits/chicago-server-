-- Server-side Traffic Control System

-- Stop traffic command
RegisterNetEvent("origen_police:server:stoptraffic", function()
    local coords = GetEntityCoords(GetPlayerPed(source))
    
    -- Check if there's already a zone nearby (within 20 units)
    for i = 1, #Public.TrafficZones do
        local distance = #(Public.TrafficZones[i].coords - coords)
        
        if distance < 20 then
            -- Update existing zone to "stop"
            Public.TrafficZones[i].type = "stop"
            
            TriggerClientEvent("origen_police:client:UpdateTraffic", -1, i, "stop")
            
            -- Update central map markers for all subscribers
            for playerId, _ in pairs(CentralSuscribeds) do
                TriggerClientEvent("origen_police:client:UpdateCentralMark", playerId, 
                    "Traffic_" .. #Public.TrafficZones, {
                        coords = {x = coords.x, y = coords.y, z = coords.z},
                        type = "stop",
                        radius = 50,
                        icon = "traffic"
                    })
            end
            
            TriggerClientEvent("origen_police:ShowNotification", source, 
                Config.Translations.UpdatedLimitation)
            return
        end
    end
    
    -- Create new stop zone
    table.insert(Public.TrafficZones, {
        coords = coords,
        type = "stop",
        radius = 50
    })
    
    TriggerClientEvent("origen_police:client:AddTrafficZone", -1, {
        coords = coords,
        type = "stop"
    })
    
    TriggerClientEvent("origen_police:ShowNotification", source, 
        Config.Translations.NewLimitation)
    
    -- Add central map markers for all subscribers
    for playerId, _ in pairs(CentralSuscribeds) do
        TriggerClientEvent("origen_police:client:AddCentralMark", playerId,
            "Traffic_" .. #Public.TrafficZones, {
                coords = {x = coords.x, y = coords.y, z = coords.z},
                type = "stop",
                radius = 50,
                icon = "traffic"
            })
    end
end)

-- Slow traffic command
RegisterNetEvent("origen_police:server:slowtraffic", function()
    local coords = GetEntityCoords(GetPlayerPed(source))
    
    -- Check if there's already a zone nearby (within 20 units)
    for i = 1, #Public.TrafficZones do
        local distance = #(Public.TrafficZones[i].coords - coords)
        
        if distance < 20 then
            -- Update existing zone to "slow"
            Public.TrafficZones[i].type = "slow"
            
            TriggerClientEvent("origen_police:client:UpdateTraffic", -1, i, "slow")
            
            -- Update central map markers for all subscribers
            for playerId, _ in pairs(CentralSuscribeds) do
                TriggerClientEvent("origen_police:client:UpdateCentralMark", playerId,
                    "Traffic_" .. #Public.TrafficZones, {
                        coords = {x = coords.x, y = coords.y, z = coords.z},
                        type = "slow",
                        radius = 50,
                        icon = "traffic"
                    })
            end
            
            TriggerClientEvent("origen_police:ShowNotification", source,
                Config.Translations.UpdatedLimitation)
            return
        end
    end
    
    -- Create new slow zone
    table.insert(Public.TrafficZones, {
        coords = coords,
        type = "slow",
        radius = 50
    })
    
    TriggerClientEvent("origen_police:client:AddTrafficZone", -1, {
        coords = coords,
        type = "slow"
    })
    
    TriggerClientEvent("origen_police:ShowNotification", source,
        Config.Translations.NewLimitation)
    
    -- Add central map markers for all subscribers
    for playerId, _ in pairs(CentralSuscribeds) do
        TriggerClientEvent("origen_police:client:AddCentralMark", playerId,
            "Traffic_" .. #Public.TrafficZones, {
                coords = {x = coords.x, y = coords.y, z = coords.z},
                type = "slow",
                radius = 50,
                icon = "traffic"
            })
    end
end)

-- Resume traffic command (remove limitation)
RegisterNetEvent("origen_police:server:resumetraffic", function()
    local coords = GetEntityCoords(GetPlayerPed(source))
    
    -- Find and remove nearby zone (within 20 units)
    for i = 1, #Public.TrafficZones do
        local distance = #(Public.TrafficZones[i].coords - coords)
        
        if distance < 20 then
            -- Remove zone from table
            table.remove(Public.TrafficZones, i)
            
            TriggerClientEvent("origen_police:client:RemoveTraffic", -1, i)
            
            TriggerClientEvent("origen_police:ShowNotification", source,
                Config.Translations.LimitationRemoved)
            
            -- Remove central map markers for all subscribers
            for playerId, _ in pairs(CentralSuscribeds) do
                TriggerClientEvent("origen_police:client:RemoveCentralMark", playerId,
                    "Traffic_" .. i)
            end
            return
        end
    end
    
    -- No zone found nearby
    TriggerClientEvent("origen_police:ShowNotification", source,
        Config.Translations.CantFindLimitation)
end)