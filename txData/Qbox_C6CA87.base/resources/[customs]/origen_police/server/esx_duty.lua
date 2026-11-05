-- ESX Duty Management System
-- Only runs if framework is ESX
if Config.Framework ~= "esx" then
    return
end

-- Store players on duty by job category
local playersOnDuty = {}

-- Initialize duty tables for each job category
for jobCategory, _ in pairs(Config.JobCategory) do
    playersOnDuty[jobCategory] = {}
end

-- Set Duty Status
RegisterServerEvent("origen_police:server_esx:SetDuty", function(isOnDuty)
    local playerId = source
    
    -- Notify client of duty change
    TriggerClientEvent("origen_police:esx:SetDuty", playerId, isOnDuty)
    
    -- Get player's job category
    local jobCategory = CanOpenTablet(playerId)[2]
    
    if isOnDuty then
        -- Check if player is already in duty list
        for i = 1, #playersOnDuty[jobCategory] do
            if playersOnDuty[jobCategory][i] == playerId then
                return -- Already on duty
            end
        end
        
        -- Add player to duty list
        table.insert(playersOnDuty[jobCategory], playerId)
    else
        -- Remove player from duty list
        for i = 1, #playersOnDuty[jobCategory] do
            if playersOnDuty[jobCategory][i] == playerId then
                table.remove(playersOnDuty[jobCategory], i)
                return
            end
        end
    end
end)

-- Get all players on duty for a specific job category
function GetPlayersInDuty(jobCategory)
    return playersOnDuty[jobCategory] or {}
end

exports("GetPlayersInDuty", GetPlayersInDuty)

-- Check if a specific player is on duty
function IsPlayerOnDuty(playerId)
    -- Get player's job category
    local jobCategory = CanOpenTablet(playerId)[2]
    
    if not jobCategory then
        return false
    end
    
    -- Ensure duty table exists
    playersOnDuty[jobCategory] = playersOnDuty[jobCategory] or {}
    
    -- Check if no one is on duty
    if #playersOnDuty[jobCategory] == 0 then
        return false
    end
    
    -- Search for player in duty list
    for i = 1, #playersOnDuty[jobCategory] do
        if playersOnDuty[jobCategory] and playersOnDuty[jobCategory][i] == playerId then
            return true
        end
    end
    
    return false
end

exports("IsPlayerOnDuty", IsPlayerOnDuty)

-- Remove player from all duty lists
function DropDutyPlayer(playerId)
    for jobCategory, players in pairs(playersOnDuty) do
        for index, player in pairs(players) do
            if player == playerId then
                table.remove(players, index)
                return
            end
        end
    end
end

exports("DropDutyPlayer", DropDutyPlayer)

-- Handle player disconnect
AddEventHandler("playerDropped", function(reason)
    if not source then
        return
    end
    
    DropDutyPlayer(source)
end)

-- Force drop duty (can be called from client or other scripts)
RegisterNetEvent("origen_police:server_esx:ForceDropDuty", function()
    DropDutyPlayer(source)
end)