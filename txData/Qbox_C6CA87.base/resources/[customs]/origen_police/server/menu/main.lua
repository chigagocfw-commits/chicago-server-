-- Callback to remove item from player inventory
FW_CreateCallback("origen_police:server:RemoveItem", function(source, callback, data)
    local player = FW_GetPlayer(source)
    
    if not player then
        callback(false)
        return
    end
    
    if Config.Framework == "qbcore" then
        -- QBCore returns success/failure directly
        callback(player.Functions.RemoveItem(data.item_name, data.amount, data.slot))
    else
        -- ESX doesn't return a value, assume success
        player.Functions.RemoveItem(data.item_name, data.amount, data.slot)
        callback(true)
    end
end)

-- Get closest players with their character info
FW_CreateCallback("origen_police:server:GetClosestPlayers", function(source, callback, playerIds, filters)
    local closestPlayers = {}
    
    for i = 1, #playerIds do
        local player = FW_GetPlayer(playerIds[i])
        
        if player and player.PlayerData then
            local shouldInclude = true
            
            -- Filter by job if specified
            if player.PlayerData.job then
                if filters.job then
                    if filters.job ~= player.PlayerData.job.name then
                        shouldInclude = false
                    end
                end
            end
            
            if shouldInclude then
                -- Get player image from database
                local tableName = Config.Framework == "qbcore" and "players" or "users"
                local idColumn = Config.Framework == "qbcore" and "citizenid" or "identifier"
                
                local query = string.format(
                    "SELECT image FROM %s WHERE %s = ?",
                    tableName,
                    idColumn
                )
                
                local result = MySQL.awaitQuery(query, {
                    player.PlayerData.citizenid
                })
                
                local image = nil
                if result[1] then
                    image = result[1].image
                end
                
                -- Add player to results
                table.insert(closestPlayers, {
                    citizenid = player.PlayerData.citizenid,
                    firstname = player.PlayerData.charinfo.firstname,
                    lastname = player.PlayerData.charinfo.lastname,
                    image = image
                })
            end
        end
    end
    
    callback(closestPlayers)
end)

-- Register useable item for police tablet/CAD
if Config.Commands.OpenPoliceCad and Config.Commands.OpenPoliceCad.item then
    FW_CreateUseableItem(Config.Commands.OpenPoliceCad.item, function(source)
        local player = FW_GetPlayer(source)
        
        if not player or not player.PlayerData or not player.PlayerData.job then
            TriggerClientEvent("origen_police:ShowNotification", source, "Error: Player data not found")
            return
        end
        
        -- Check if player's job can open the tablet
        local canOpen = CanOpenTablet(player.PlayerData.job.name)[1]
        
        if not canOpen then
            -- Send notification to client using existing event
            TriggerClientEvent("origen_police:ShowNotification", source, Config.Translations.CantUseItem or "You cannot use this item")
            return
        end
        
        TriggerClientEvent("origen_police:client:OpenPoliceCad", source)
    end)
end