-- Police object placement system - Server side
local playerObjectCounts = {}

-- Place object server action
RegisterServerAction("origen_police:server:placeobj", function(model, coords, heading, freeze)
    local src = source
    
    -- Initialize or increment player object count
    playerObjectCounts[src] = (playerObjectCounts[src] or 0) + 1
    
    -- Check if player exceeded max objects limit
    if playerObjectCounts[src] > Config.Actions.MaxObjectsPerPlayer then
        return
    end
    
    -- Broadcast object placement to all clients
    TriggerClientEvent("origen_police:client:placeobj", -1, {
        source = src,
        objectId = playerObjectCounts[src]
    }, {
        model = model,
        coords = coords,
        heading = heading,
        freeze = freeze
    })
end, "placeobj", 400, nil, false)

-- Remove object callback
RegisterServerAction("origen_police:callback:rmveobj", function(playerSource, objectId, objectCoords)
    -- Validate player has objects
    if not playerObjectCounts[playerSource] or playerObjectCounts[playerSource] < 1 then
        return
    end
    
    -- Decrement player object count
    playerObjectCounts[playerSource] = playerObjectCounts[playerSource] - 1
    
    -- Clean up if no objects left
    if playerObjectCounts[playerSource] <= 0 then
        playerObjectCounts[playerSource] = nil
    end
    
    -- Broadcast object removal to all clients
    TriggerClientEvent("origen_police:client:rmveobj", -1, {
        source = playerSource,
        objectId = objectId
    })
    
    -- Check if removed object was a radar
    for i = 1, #Public.Radars do
        local radar = Public.Radars[i]
        local distance = #(objectCoords - radar.objectCoords)
        
        if distance < 1.2 then
            Debuger("Removing radar at coords: " .. tostring(objectCoords))
            
            -- Remove radar from table
            table.remove(Public.Radars, i)
            
            -- Notify all clients
            TriggerClientEvent("origen_police:client:removeradar", -1, i)
            
            -- Remove from central dispatch
            for playerId, _ in pairs(CentralSuscribeds) do
                TriggerClientEvent("origen_police:client:RemoveCentralMark", playerId, "Radar_" .. i)
            end
            
            break
        end
    end
end, "removeobj", 1000, nil, false)

-- Place radar (speed or plate reader)
RegisterServerAction("origen_police:server:placeradar", function(radarData)
    -- Add radar to public radars list
    table.insert(Public.Radars, radarData)
    
    -- Notify all clients
    TriggerClientEvent("origen_police:client:placeradar", -1, radarData)
    
    -- Set icon for central dispatch
    radarData.icon = "radar"
    
    -- Add to central dispatch for subscribed players
    for playerId, _ in pairs(CentralSuscribeds) do
        TriggerClientEvent(
            "origen_police:client:AddCentralMark",
            playerId,
            "Radar_" .. #Public.Radars,
            json.decode(json.encode(radarData))
        )
    end
end, "placeradar", 1000, nil, false)