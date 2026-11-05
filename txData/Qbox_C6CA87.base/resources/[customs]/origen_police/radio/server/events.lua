-- Handle talking events between players on the same frequency
RegisterServerEvent("origen_police:server:talking")
AddEventHandler("origen_police:server:talking", function(players, isTalking)
    for playerId, _ in pairs(players) do
        TriggerClientEvent("origen_police:client:talking", playerId, source, isTalking)
    end
end)

-- Set simple frequency for a player
RegisterServerEvent("origen_police:server:SetFreq")
AddEventHandler("origen_police:server:SetFreq", function(frequency)
    SetFreq(source, frequency)
end)

-- Set multi-frequency (unit-based system)
RegisterServerEvent("origen_police:server:SetMultiFrec")
AddEventHandler("origen_police:server:SetMultiFrec", function(group, unit, extraData)
    if group == Config.PoliceJobName then
        if unit == "entrada" or unit == "none" then
            TriggerEvent("origen_police:server:removeref", source)
        else
            TriggerEvent("origen_police:server:updateref", {
                source = source,
                unit = unit:upper()
            })
        end
    end
    
    SetMultiFrec(source, group, unit, extraData)
end)

-- Move player between frequencies
RegisterServerEvent("origen_police:server:moveplayer")
AddEventHandler("origen_police:server:moveplayer", function(targetPlayer, group, unit)
    TriggerClientEvent("origen_police:client:SetMultiFrec", targetPlayer, group, unit)
end)

-- Mute/unmute a player
RegisterServerEvent("origen_police:server:Mute")
AddEventHandler("origen_police:server:Mute", function(group, muted)
    MutePlayer(source, group, muted)
end)

-- Set ready status for player(s)
RegisterServerEvent("origen_police:server:Ready")
AddEventHandler("origen_police:server:Ready", function(group, ready, playerList)
    if playerList then
        for i = 1, #playerList do
            ReadyPlayer(playerList[i], group, ready)
            
            if playerList[i] ~= source then
                TriggerClientEvent("origen_police:client:SyncQuick", playerList[i], {
                    ready = ready
                })
            end
        end
    else
        ReadyPlayer(source, group, ready)
    end
end)

-- Get multi-frequency data for a player
FW_CreateCallback("origen_police:GetMultiFrecs", function(source, callback, data)
    if not data.group then
        data.group = Config.PoliceJobName
    end
    
    -- Send current frequency targets to client
    TriggerClientEvent("origen_police:client:SetMultiFrecTargets", source, MultiFrecs[data.group])
    
    -- Return frequency data
    callback(MultiFrecs[data.group] or {})
    
    -- Check if player is already in a frequency
    for unit, players in pairs(MultiFrecs[data.group] or {}) do
        if players[source] then
            return
        end
    end
    
    -- Add player to entrada (default entry) if they're police
    if data.group == Config.PoliceJobName then
        MultiFrecs[data.group] = MultiFrecs[data.group] or {}
        MultiFrecs[data.group].entrada = MultiFrecs[data.group].entrada or {}
        
        local player = FW_GetPlayer(source)
        MultiFrecs[data.group].entrada[source] = {
            muted = false,
            ready = true,
            job = player.PlayerData.job.name
        }
    end
end)

-- Handle player disconnect
AddEventHandler("playerDropped", function(reason)
    local playerId = source
    if not playerId then return end
    
    -- Remove from simple frequencies
    for frequency, players in pairs(Frecs) do
        if players[playerId] then
            players[playerId] = nil
            
            -- Notify other players on the frequency
            for otherPlayer, _ in pairs(players) do
                TriggerClientEvent("origen_police:client:RemovePlayerTarget", otherPlayer, playerId)
            end
            break
        end
    end
    
    -- Remove from multi-frequencies
    for group, units in pairs(MultiFrecs) do
        for unit, players in pairs(units) do
            if players[playerId] then
                players[playerId] = nil
                
                -- Notify all players in all units of this group
                for otherUnit, otherPlayers in pairs(units) do
                    for otherPlayer, _ in pairs(otherPlayers) do
                        TriggerClientEvent("origen_police:client:RemovePlayerMultiFrec", otherPlayer, playerId, unit)
                    end
                end
                
                -- Special handling for police
                if group == "police" then
                    TriggerEvent("origen_police:server:removeref", playerId)
                end
                break
            end
        end
    end
end)