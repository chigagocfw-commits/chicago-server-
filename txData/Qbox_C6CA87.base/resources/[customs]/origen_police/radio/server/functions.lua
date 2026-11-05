-- Set a player's frequency (simple frequency system)
function SetFreq(playerId, frequency)
    -- Remove player from their current frequency
    for freq, players in pairs(Frecs) do
        if players[playerId] then
            players[playerId] = nil
            
            -- Notify other players to remove this player from targets
            for otherPlayer, _ in pairs(players) do
                TriggerClientEvent("origen_police:client:RemovePlayerTarget", otherPlayer, playerId)
            end
            break
        end
    end
    
    -- Add player to new frequency if valid
    if frequency > 0 then
        Frecs[frequency] = Frecs[frequency] or {}
        Frecs[frequency][playerId] = true
        
        -- Sync with other players on the frequency
        for otherPlayer, _ in pairs(Frecs[frequency]) do
            if otherPlayer ~= playerId then
                -- Tell others about the new player
                TriggerClientEvent("origen_police:client:AddPlayerTarget", otherPlayer, playerId)
            else
                -- Tell the player about all others on the frequency
                TriggerClientEvent("origen_police:client:SetTargets", otherPlayer, Frecs[frequency])
            end
        end
    end
end

-- Shallow copy utility function
function Shallowcopy(original)
    local copy
    
    if type(original) == "table" then
        copy = {}
        for key, value in pairs(original) do
            copy[key] = value
        end
    else
        copy = original
    end
    
    return copy
end

-- Set a player's multi-frequency unit
function SetMultiFrec(playerId, group, unit, extraData)
    extraData = extraData or {}
    
    local wasMuted = false
    local wasReady = true
    local oldUnit = false
    
    -- Initialize group if it doesn't exist
    MultiFrecs[group] = MultiFrecs[group] or {}
    
    -- Find and remove player from their current unit
    for currentUnit, players in pairs(MultiFrecs[group]) do
        if players[playerId] then
            local playerData = Shallowcopy(players[playerId])
            wasMuted = players[playerId].muted
            wasReady = players[playerId].ready
            players[playerId] = nil
            oldUnit = currentUnit
            
            -- If disconnecting (unit = "none"), move to entrada
            if unit == "none" then
                MultiFrecs[group] = MultiFrecs[group] or {}
                MultiFrecs[group].entrada = MultiFrecs[group].entrada or {}
                MultiFrecs[group].entrada[playerId] = playerData
            end
            break
        end
    end
    
    -- Notify about removal from old unit
    if oldUnit then
        TriggerClientEvent("origen_police:client:RemovePlayerMultiFrec", playerId, playerId, oldUnit)
        
        -- Notify all other players in the group
        for currentUnit, players in pairs(MultiFrecs[group]) do
            for otherPlayer, _ in pairs(players) do
                TriggerClientEvent("origen_police:client:RemovePlayerMultiFrec", otherPlayer, playerId, oldUnit)
            end
        end
        
        -- Trigger ready event if leaving entrada
        if oldUnit == "entrada" then
            TriggerEvent("origen_police:server:PlayerReady", playerId, true)
        end
    else
        TriggerEvent("origen_police:server:PlayerReady", playerId, true)
    end
    
    -- Add player to new unit (if not disconnecting)
    if unit ~= "none" then
        MultiFrecs[group][unit] = MultiFrecs[group][unit] or {}
        
        local playerName, playerGrade = GetPlayerIcName(playerId, group)
        local player = FW_GetPlayer(playerId)
        
        MultiFrecs[group][unit][playerId] = {
            name = playerName,
            muted = wasMuted,
            ready = wasReady,
            grade = playerGrade,
            job = player.PlayerData.job.name
        }
        
        -- Apply any extra data
        for key, value in pairs(extraData) do
            MultiFrecs[group][unit][playerId][key] = value
        end
        
        -- Notify all players in the group about the new player
        for currentUnit, players in pairs(MultiFrecs[group]) do
            for otherPlayer, _ in pairs(players) do
                TriggerClientEvent("origen_police:client:AddPlayerMultiFrec", otherPlayer, playerId, unit, 
                    MultiFrecs[group][unit][playerId])
            end
        end
    else
        -- Player disconnected from radio
        TriggerClientEvent("origen_police:client:Disconnected", playerId)
    end
end

-- Mute or unmute a player
function MutePlayer(playerId, group, muted)
    -- Update mute status
    for unit, players in pairs(MultiFrecs[group]) do
        if players[playerId] then
            players[playerId].muted = muted
            break
        end
    end
    
    -- Notify all players in the group
    for unit, players in pairs(MultiFrecs[group]) do
        for otherPlayer, _ in pairs(players) do
            TriggerClientEvent("origen_police:client:SetMuted", otherPlayer, playerId, muted)
        end
    end
end

-- Set a player's ready status
function ReadyPlayer(playerId, group, ready)
    -- Update ready status
    for unit, players in pairs(MultiFrecs[group]) do
        if players[playerId] then
            players[playerId].ready = ready
            break
        end
    end
    
    -- Notify all players in the group
    for unit, players in pairs(MultiFrecs[group]) do
        for otherPlayer, _ in pairs(players) do
            TriggerClientEvent("origen_police:client:SetReady", otherPlayer, playerId, ready)
        end
    end
    
    TriggerEvent("origen_police:server:PlayerReady", playerId, ready)
end

-- Get a player's in-character name
function GetPlayerIcName(playerId, group)
    local player = FW_GetPlayer(playerId)
    
    if group == "police" then
        local name
        if player then
            local badge = player.PlayerData.metadata.police_badge or "0000"
            name = player.PlayerData.charinfo.firstname .. " " .. 
                   player.PlayerData.charinfo.lastname .. " (" .. badge .. ")"
        else
            name = GetPlayerName(playerId)
        end
        
        local grade = player and player.PlayerData.job.grade.name or "Desempleado"
        return name, grade
    else
        local name
        if player then
            name = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
        else
            name = GetPlayerName(playerId)
        end
        
        return name, ""
    end
end

-- Get all ready players in a group
function GetPlayersReady(group)
    local readyPlayers = {}
    
    if not MultiFrecs[group] then
        return readyPlayers
    end
    
    for unit, players in pairs(MultiFrecs[group]) do
        for playerId, playerData in pairs(players) do
            if playerData.ready then
                readyPlayers[playerId] = true
            end
        end
    end
    
    return readyPlayers
end

-- Get ready players filtered by job
function GetPlayersReadyByJob(jobName, excludeEntrada)
    local readyPlayers = {}
    
    for unit, players in pairs(MultiFrecs[Config.PoliceJobName]) do
        for playerId, playerData in pairs(players) do
            local shouldInclude = true
            
            if excludeEntrada and unit == "entrada" then
                shouldInclude = false
            end
            
            if shouldInclude and playerData.job == jobName and playerData.ready then
                readyPlayers[playerId] = true
            end
        end
    end
    
    return readyPlayers
end

-- Get all multi-frequencies for a group
function GetMultiFrecs(group)
    return MultiFrecs[group]
end

-- Export functions for other resources
exports("GetPlayersReady", GetPlayersReady)
exports("GetMultiFrecs", GetMultiFrecs)
exports("GetPlayersReadyByJob", GetPlayersReadyByJob)