local bodyCamStatus = {}

-- Get list of players with body cameras available
FW_CreateCallback("origen_police:server:GetBodyCams", function(source, callback)
    local jobCategory = CanOpenTablet(source)[2]
    local playerIds = {}
    local bodyCamPlayers = {}
    
    -- Get players on duty based on framework
    if Config.Framework == "qbcore" then
        if Config.JobCategory[jobCategory] == nil then
            print("origen_police: ERROR: You are trying to send an alert with a job category that doesn't exist in the Config.JobCategory table in config/permissions.lua")
            return
        end
        
        -- Get all players from jobs in this category
        for _, job in pairs(Config.JobCategory[jobCategory]) do
            local onDutyPlayers = Framework.Functions.GetPlayersOnDuty(job.name)
            
            for i = 1, #onDutyPlayers do
                table.insert(playerIds, onDutyPlayers[i])
            end
        end
    elseif Config.Framework == "esx" then
        playerIds = GetPlayersInDuty(jobCategory)
    else
        playerIds = {}
        print("Can't find supported framework: ", Config.Framework)
    end
    
    -- Build body cam player list
    for i = 1, #playerIds do
        local player = FW_GetPlayer(playerIds[i])
        
        if player and player.PlayerData then
            local playerId = playerIds[i]
            
            -- Only include if body cam is enabled
            if not bodyCamStatus[playerId] then
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
                
                -- Add player to body cam list
                table.insert(bodyCamPlayers, {
                    name = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname,
                    badge = player.PlayerData.metadata.police_badge or "0000",
                    grade = player.PlayerData.job.grade.name,
                    image = image,
                    source = playerIds[i]
                })
            end
        end
    end
    
    callback(bodyCamPlayers)
end)

-- Show body camera to requesting player
RegisterServerEvent("origen_police:server:ShowBodycam", function(targetPlayerId)
    local source = source
    
    -- Check if already viewing a body cam
    if bodyCamStatus[source] then
        return
    end
    
    local targetPlayer = FW_GetPlayer(targetPlayerId)
    
    if targetPlayer then
        TriggerClientEvent(
            "origen_police:client:ShowBodycam",
            source,
            GetEntityCoords(GetPlayerPed(targetPlayerId)),
            targetPlayerId
        )
        
        -- Log the action
        CreateLog({
            type = "Cams",
            embed = {
                title = Config.LogsTranslations.UseBodyCam.title,
                description = string.format(
                    Config.LogsTranslations.UseBodyCam.message,
                    targetPlayer.PlayerData.charinfo.firstname .. " " .. targetPlayer.PlayerData.charinfo.lastname
                ),
                color = 1791423
            },
            source = source
        })
    else
        print("Cant get target: " .. targetPlayerId)
    end
end)

-- Show car camera to requesting player
RegisterServerEvent("origen_police:server:ShowCarcam", function(vehicleNetId)
    local source = source
    local jobCategory = CanOpenTablet(source)[2]
    local trackedVehicles = GetVehiclesTrackeds()[jobCategory][vehicleNetId]
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    
    if vehicle and DoesEntityExist(vehicle) then
        TriggerClientEvent(
            "origen_police:client:ShowCarcam",
            source,
            GetEntityCoords(vehicle),
            vehicleNetId
        )
        
        -- Log the action
        CreateLog({
            type = "Cams",
            embed = {
                title = Config.LogsTranslations.UseCarCam.title,
                description = string.format(
                    Config.LogsTranslations.UseCarCam.message,
                    trackedVehicles and trackedVehicles.plate or "Unknown"
                ),
                color = 1791423
            },
            source = source
        })
    end
end)

-- Enable/disable body camera
RegisterNetEvent("origen_police:server:DisableBodyCam", function(enabled)
    local source = source
    
    if enabled then
        bodyCamStatus[source] = nil
    else
        bodyCamStatus[source] = true
    end
end)