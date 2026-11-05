-- Client-side Traffic Control System

-- Update existing traffic zone type
RegisterNetEvent("origen_police:client:UpdateTraffic", function(zoneIndex, newType)
    local zone = Public.TrafficZones[zoneIndex]
    
    if not zone then
        return
    end
    
    -- Remove existing speed zone
    RemoveRoadNodeSpeedZone(zone.id)
    
    -- Update zone type
    zone.type = newType
    
    -- Apply new speed restrictions
    if zone.type == "stop" then
        -- Complete stop zone (0 speed)
        zone.id = AddRoadNodeSpeedZone(zone.coords, 50.0, 0.0, false)
        
        -- Update blip color to red
        if zone.blip then
            SetBlipColour(zone.blip, 6) -- Red
        end
    elseif zone.type == "slow" then
        -- Slow zone (5 speed)
        zone.id = AddRoadNodeSpeedZone(zone.coords, 50.0, 5.0, false)
        
        -- Update blip color to orange
        if zone.blip then
            SetBlipColour(zone.blip, 44) -- Orange
        end
    end
end)

-- Add new traffic zone
RegisterNetEvent("origen_police:client:AddTrafficZone", function(zoneData)
    -- Create radius blip if player is on duty
    if onduty then
        zoneData.blip = AddBlipForRadius(zoneData.coords, 50.0)
        SetBlipAlpha(zoneData.blip, 100)
    end
    
    -- Apply speed zone based on type
    if zoneData.type == "stop" then
        -- Complete stop zone
        zoneData.id = AddRoadNodeSpeedZone(zoneData.coords, 50.0, 0.0, false)
        
        if zoneData.blip then
            SetBlipColour(zoneData.blip, 6) -- Red
        end
    elseif zoneData.type == "slow" then
        -- Slow traffic zone
        zoneData.id = AddRoadNodeSpeedZone(zoneData.coords, 50.0, 5.0, false)
        
        if zoneData.blip then
            SetBlipColour(zoneData.blip, 44) -- Orange
        end
    end
    
    -- Add to local traffic zones table
    table.insert(Public.TrafficZones, zoneData)
end)

-- Remove traffic zone
RegisterNetEvent("origen_police:client:RemoveTraffic", function(zoneIndex)
    local zone = Public.TrafficZones[zoneIndex]
    
    if not zone then
        return
    end
    
    -- Remove blip if exists
    if zone.blip then
        RemoveBlip(zone.blip, 17)
    end
    
    -- Remove speed zone
    RemoveRoadNodeSpeedZone(zone.id)
    
    -- Remove from table
    table.remove(Public.TrafficZones, zoneIndex)
end)