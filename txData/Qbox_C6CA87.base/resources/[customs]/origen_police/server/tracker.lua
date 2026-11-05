-- Server-side Ankle Tracker System
Trackers = {}

-- Load all trackers from database on server start
Citizen.CreateThread(function()
    local result = MySQL.awaitQuery("SELECT * FROM origen_police_ankle")
    Wait(2000)
    
    if not result then
        return
    end
    
    for _, tracker in pairs(result) do
        local player = FW_GetPlayerFromCitizenid(tracker.citizenid)
        
        if player and player.PlayerData and player.PlayerData.source then
            Trackers[player.PlayerData.source] = tracker
            TriggerClientEvent("origen_police:client:SetAnkleCuff", player.PlayerData.source, true)
        end
    end
end)

-- Get tracker information by citizen ID
function GetTrackerFromCitizenid(citizenid)
    for serverId, tracker in pairs(Trackers) do
        local player = FW_GetPlayer(serverId)
        
        if tracker.citizenid == citizenid and player and player.PlayerData and player.PlayerData.citizenid == citizenid then
            local policeOwner = FW_GetPlayerFromCitizenid(tracker.policeOwner)
            
            if not policeOwner.PlayerData.charinfo then
                print("Invalid charinfo while getting the tracker from CID: ", citizenid)
                return
            end
            
            if not policeOwner.PlayerData.metadata then
                print("Invalid metadata while getting the tracker from CID: ", citizenid)
                return
            end
            
            -- Build police officer label with badge number
            local badgeNumber = policeOwner.PlayerData.metadata.police_badge or "0000"
            tracker.policeLabel = policeOwner.PlayerData.charinfo.firstname .. " " .. 
                                  policeOwner.PlayerData.charinfo.lastname .. " (" .. 
                                  badgeNumber .. ")"
            
            -- Get target coordinates
            local ped = GetPlayerPed(serverId)
            local coords = {table.unpack(GetEntityCoords(ped))}
            tracker.coords = coords
            tracker.targetId = serverId
            
            return tracker
        end
    end
    
    return nil
end

-- Place or remove ankle cuff
RegisterServerAction("origen_police:server:anklecuff", function(targetId)
    local source = source
    local hasTracker = Trackers[targetId] ~= nil
    local targetPlayer = FW_GetPlayer(targetId)
    local sourcePlayer = FW_GetPlayer(source)
    
    if not targetPlayer or not sourcePlayer then
        return
    end
    
    local action = ""
    
    if not hasTracker then
        -- Place new tracker
        MySQL.awaitInsert("INSERT INTO origen_police_ankle (citizenid, policeOwner) VALUES (@citizenid, @police)", {
            ["@citizenid"] = targetPlayer.PlayerData.citizenid,
            ["@police"] = sourcePlayer.PlayerData.citizenid
        })
        
        Trackers[targetId] = {
            citizenid = targetPlayer.PlayerData.citizenid,
            policeOwner = sourcePlayer.PlayerData.citizenid,
            date = os.time()
        }
        
        action = "Placed"
    else
        -- Remove tracker
        Trackers[targetId] = nil
        MySQL.awaitQuery("DELETE FROM origen_police_ankle WHERE citizenid = @citizenid", {
            ["@citizenid"] = targetPlayer.PlayerData.citizenid
        })
        
        action = "Removed"
    end
    
    -- Freeze player during animation
    local targetPed = GetPlayerPed(targetId)
    FreezeEntityPosition(targetPed, true)
    Wait(5000)
    
    -- Update client
    TriggerClientEvent("origen_police:client:SetAnkleCuff", targetId, not hasTracker)
    FreezeEntityPosition(targetPed, false)
    
    -- Create log
    CreateLog({
        type = "Ankle",
        embed = {
            title = "Ankle Cuff - " .. action,
            description = string.format(
                "**%s [%s]** has %s the ankle cuff of **%s [%s]**\nDate: <t:%d:f>",
                sourcePlayer.PlayerData.charinfo.firstname .. " " .. sourcePlayer.PlayerData.charinfo.lastname,
                source,
                string.lower(action),
                targetPlayer.PlayerData.charinfo.firstname .. " " .. targetPlayer.PlayerData.charinfo.lastname,
                targetId,
                os.time()
            ),
            color = action == "Placed" and 65280 or 16711680
        },
        source = source
    })
end, "ankle_cuff", 300, 1)

-- Shock ankle tracker
RegisterServerAction("origen_police:server:ankleshock", function(targetId)
    local tracker = Trackers[tonumber(targetId)]
    
    if not tracker then
        print("No tracker on this player")
        return
    end
    
    local targetPlayer = FW_GetPlayer(targetId)
    
    if not targetPlayer then
        return
    end
    
    -- Update last shock time in database
    MySQL.awaitInsert("UPDATE origen_police_ankle SET lastShock = CURRENT_TIMESTAMP WHERE citizenid = ?", {
        targetPlayer.PlayerData.citizenid
    })
    
    -- Update tracker timestamp
    Trackers[tonumber(targetId)].lastShock = os.time() * 1000
    
    -- Trigger shock effect on client
    TriggerClientEvent("origen_police:client:ankleshock", targetId)
end, "ankle_shock", 300, 1)

-- Get ankle cuff status when player joins
RegisterNetEvent("origen_police:server:GetAnkleCuff", function()
    local source = source
    local player = FW_GetPlayer(source)
    
    if not player then
        return
    end
    
    local result = MySQL.awaitQuery("SELECT * FROM origen_police_ankle WHERE citizenid = ? LIMIT 1", {
        player.PlayerData.citizenid
    })
    
    if not result or not result[1] then
        return
    end
    
    local tracker = result[1]
    Trackers[source] = tracker
    TriggerClientEvent("origen_police:client:SetAnkleCuff", source, true)
end)