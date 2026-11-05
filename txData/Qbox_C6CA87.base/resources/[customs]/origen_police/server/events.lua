-- Server Events and Callbacks

-- Set wanted level for a player
RegisterServerEvent("origen_police:server:SetWantedLevel", function(targetId, wantedLevel)
    TriggerClientEvent("origen_police:client:SetWantedLevel", targetId, wantedLevel)
end)

-- Set player routing bucket/dimension
FW_CreateCallback("origen_police:SetDimension", function(source, callback, dimension)
    local playerPed = GetPlayerPed(source)
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    -- Set player routing bucket
    SetPlayerRoutingBucket(source, dimension)
    
    -- Set vehicle routing bucket if in vehicle
    if vehicle ~= 0 then
        SetEntityRoutingBucket(vehicle, dimension)
    end
    
    callback(true)
end)

-- Confiscate vehicle
RegisterServerEvent("origen_police:server:confiscateveh", function(plate, reason, time)
    ConfiscateVehicle(plate, reason, time, nil, source)
end)

-- Get confiscated vehicles
FW_CreateCallback("origen_police:server:GetConfiscatedVehs", function(source, callback, data)
    callback(GetConfiscatedVehicles(data))
end)

-- Get player bills
FW_CreateCallback("origen_police:server:GetBills", function(source, callback, data)
    local player = FW_GetPlayer(source)
    
    if not player then
        return callback({})
    end
    
    callback(exports.origen_police:GetUnpayedBills(player.PlayerData.citizenid))
end)

-- Get server time
FW_CreateCallback("OsTime", function(source, callback)
    callback(os.time())
end)

-- Set player metadata
RegisterServerEvent("origen_police:server:SetMetaData", function(metaKey, value)
    local player = FW_GetPlayer(source)
    
    if player then
        -- Convert booleans to 0/1 if needed
        local finalValue = value
        if value == false then
            finalValue = 0
        elseif value == true then
            finalValue = 1
        end
        
        player.Functions.SetMetaData(metaKey, finalValue)
    end
end)

-- Generate police badge
FW_CreateCallback("origen_police:server:GeneratePoliceBadge", function(source, callback, data)
    local jobCategory = CanOpenTablet(source)[2]
    local player = FW_GetPlayer(source)
    
    if not player then
        return callback("Player not found")
    end
    
    -- Determine badge type based on job
    local badgeItem = "lspd_badge"
    for _, job in pairs(Config.JobCategory[jobCategory]) do
        if job.name:lower() == player.PlayerData.job.name:lower() then
            badgeItem = job.badge
        end
    end
    
    -- If badge should go to target agent
    if Config.GenerateBadgeToTheAgent and data.cid then
        local targetPlayer = FW_GetPlayerFromCitizenid(data.cid)
        
        if not targetPlayer then
            return callback("Target player not found")
        end
        
        if targetPlayer.PlayerData.source then
            source = targetPlayer.PlayerData.source
            player = targetPlayer
        end
    end
    
    -- FIB badge requires mugshot
    if badgeItem == "fib_badge" then
        local targetPlayer = FW_GetPlayerFromCitizenid(data.cid)
        
        if not targetPlayer then
            return callback("Target player not found for FIB badge")
        end
        
        if targetPlayer.PlayerData.source then
            local fullName = targetPlayer.PlayerData.charinfo.firstname .. " " .. 
                           targetPlayer.PlayerData.charinfo.lastname
            
            TriggerClientEvent("origen_police:client:GenerateMugshotBadge", 
                targetPlayer.PlayerData.source,
                fullName,
                source,
                {
                    url = ServerConfig.Logs.Mugshots,
                    fields = Config.Fields[Config.UploadMethod]
                }
            )
            return callback(true)
        end
        
        return callback("The police agent should be online to generate the badge")
    end
    
    -- Add badge to inventory
    if Config.Inventory == "qs-inventory" then
        exports["qs-inventory"]:AddItem(source, badgeItem, 1, false, {
            grade = data.grade,
            n = data.police_badge
        })
    else
        player.Functions.AddItem(badgeItem, 1, false, {
            grade = data.grade,
            n = data.police_badge
        })
    end
    
    callback(true)
end)

-- Handle belongings (jail system)
RegisterServerEvent("origen_police:server:pertenences", function(action)
    LeaveTakePertenences(action, source)
end)

-- Get current cop count
function GetCurrentCops()
    if not Config.JobCategory[Config.PoliceJobName] then
        return 0
    end
    
    local count = 0
    
    -- Count all police jobs in all categories
    for _, category in pairs(Config.JobCategory) do
        for _, job in pairs(category) do
            local onDutyPlayers = Framework.Functions.GetPlayersOnDuty(job.name)
            
            for i = 1, #onDutyPlayers do
                count = count + 1
            end
        end
    end
    
    return count
end

-- Update cop count periodically (QBCore only)
CreateThread(function()
    if Config.Framework == "esx" then
        return
    end
    
    while true do
        TriggerClientEvent("police:SetCopCount", -1, GetCurrentCops())
        Wait(30000) -- Update every 30 seconds
    end
end)

-- Export: Get bills for a player
exports("GetBills", function(source)
    local player = FW_GetPlayer(source)
    
    if not player then
        return {}
    end
    
    return exports.origen_police:GetUnpayedBills(player.PlayerData.citizenid)
end)

-- Save mugshot (FIB badge with photo)
RegisterNetEvent("origen_police:server:SaveMugshot", function(imageUrl, name, targetSource)
    local player = FW_GetPlayer(targetSource)
    
    if not player then
        return
    end
    
    -- Add FIB badge with mugshot
    if Config.Inventory == "qs-inventory" then
        exports["qs-inventory"]:AddItem(targetSource, "fib_badge", 1, false, {
            url = imageUrl,
            name = name
        })
    else
        player.Functions.AddItem("fib_badge", 1, false, {
            url = imageUrl,
            name = name
        })
    end
end)