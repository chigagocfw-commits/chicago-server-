-- Check if player grade qualifies as boss
function IsBoss(playerGrade)
    playerGrade = tonumber(playerGrade)
    
    for _, bossGrade in pairs(Config.BossGrade) do
        if bossGrade <= playerGrade then
            return true
        end
    end
    
    return false
end

-- Set player metadata
RegisterNetEvent("origen_police:SetMetaData", function(key, value)
    local player = FW_GetPlayer(source)
    
    if not player then
        return
    end
    
    player.Functions.SetMetaData(key, value)
end)

-- Get player metadata callback
FW_CreateCallback("origen_police:server:GetPlayerMetadata", function(source, callback)
    local player = FW_GetPlayer(source)
    
    if player and player.PlayerData then
        local metadata = player.Functions.GetMetaData() or {}
        callback(metadata)
    else
        callback(false)
    end
end)

-- Round number to nearest integer
function FW_Round(number)
    return math.floor(number + 0.5)
end