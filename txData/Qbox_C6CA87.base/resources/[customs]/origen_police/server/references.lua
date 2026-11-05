-- GPS Reference System (Server-Side)
References = {}
HiddenGpsCops = {}

-- Update reference coordinates periodically
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2500)
        
        -- Safety check - recreate if nil
        if References == nil then
            print("References has been breaked into a nil value, recreating it")
            References = {}
        else
            -- Update coordinates for all officers
            for categoryName, categoryRefs in pairs(References) do
                for serverId, refData in pairs(categoryRefs) do
                    local playerPed = GetPlayerPed(serverId)
                    refData.coords = GetEntityCoords(playerPed)
                end
            end
            
            -- Sync to GlobalState for client access
            GlobalState.References = References
        end
    end
end)

-- Update reference data
RegisterServerEvent("origen_police:server:updateref", function(data, playerIds)
    if playerIds then
        -- Update for multiple players (vehicle passengers)
        for i = 1, #playerIds do
            UpdateRef(playerIds[i], data)
            
            -- Sync to other players except sender
            if playerIds[i] ~= source then
                TriggerClientEvent("origen_police:client:SyncQuick", playerIds[i], data)
            end
        end
    else
        -- Update for single player
        UpdateRef(data.source or source, data)
    end
end)

-- Update reference for a specific officer
function UpdateRef(serverId, data)
    local player = FW_GetPlayer(serverId)
    
    if not player or not player.PlayerData or not player.PlayerData.job then
        return
    end
    
    local canOpen, jobCategory = CanOpenTablet(player.PlayerData.job.name)[1], CanOpenTablet(player.PlayerData.job.name)[2]
    
    -- Check if player can open tablet
    if not canOpen or not jobCategory then
        return
    end
    
    -- Initialize category if needed
    References[jobCategory] = References[jobCategory] or {}
    
    -- Create reference if doesn't exist
    if not References[jobCategory][serverId] then
        if player and player.PlayerData then
            References[jobCategory][serverId] = {
                lastname = player.PlayerData.charinfo.lastname,
                unit = "Sin Asignar", -- Unassigned
                jobCategory = jobCategory
            }
        end
    else
        -- Mark as synced
        References[jobCategory][serverId].sync = true
    end
    
    -- Update unit number
    if data.unit then
        References[jobCategory][serverId].unit = data.unit
    end
    
    -- Update blip sprite
    if data.sprite then
        References[jobCategory][serverId].sprite = data.sprite
    end
    
    -- Update blip color
    if data.color then
        References[jobCategory][serverId].color = data.color
    end
    
    -- Update GPS visibility
    if data.hideGPS ~= nil then
        References[jobCategory][serverId].hideGPS = data.hideGPS
    end
end

-- Remove reference
RegisterServerEvent("origen_police:server:removeref", function(targetId)
    local serverId = targetId or source
    local player = FW_GetPlayer(serverId)
    
    if not player or not player.PlayerData or not player.PlayerData.job then
        return
    end
    
    local canOpen, jobCategory = CanOpenTablet(player.PlayerData.job.name)[1], CanOpenTablet(player.PlayerData.job.name)[2]
    
    if not canOpen or not jobCategory then
        return
    end
    
    -- Initialize category if needed
    References[jobCategory] = References[jobCategory] or {}
    
    -- Notify all officers in category
    for refServerId, refData in pairs(References[jobCategory]) do
        TriggerClientEvent("origen_police:client:removeref", 
            refServerId, 
            serverId, 
            refServerId == serverId
        )
    end
    
    -- Remove reference
    References[jobCategory][serverId] = nil
end)

-- Toggle GPS visibility
RegisterNetEvent("origen_police:server:setLocation", function(showGPS)
    local serverId = source
    local player = FW_GetPlayer(serverId)
    
    if not player or not player.PlayerData or not player.PlayerData.job then
        return
    end
    
    local canOpen, jobCategory = CanOpenTablet(player.PlayerData.job.name)[1], CanOpenTablet(player.PlayerData.job.name)[2]
    
    if not canOpen or not jobCategory then
        return
    end
    
    -- Update hidden GPS list
    HiddenGpsCops[serverId] = not showGPS
    
    -- Update in Cops table
    Cops[jobCategory] = Cops[jobCategory] or {}
    for _, cop in pairs(Cops[jobCategory]) do
        if cop.source == serverId then
            cop.hideGPS = not showGPS
            break
        end
    end
    
    -- Update reference if exists
    References[jobCategory] = References[jobCategory] or {}
    
    if References[jobCategory][serverId] then
        References[jobCategory][serverId].hideGPS = not showGPS
        UpdateRef(serverId, {hideGPS = not showGPS})
    end
end)