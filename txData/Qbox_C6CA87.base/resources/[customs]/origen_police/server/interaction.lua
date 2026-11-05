-- Server-side Interaction Script
-- Tracks pending cuff states to prevent exploits
local pendingCuffStates = {}

-- Handcuff/Uncuff Player
RegisterServerAction("origen_police:server:cuffuncuffplayer", function(targetId)
    if not targetId or not source then
        return
    end
    
    local sourceId = source
    targetId = tonumber(targetId)
    
    -- Mark player as having a pending cuff state
    pendingCuffStates[targetId] = true
    
    -- Trigger cuff state change on target player
    TriggerClientEvent("origen_police:client:setcuffstate", targetId, sourceId)
    
end, "handcuff", 300, 1, Config.HandCuff.AllowAllJobs)

-- Play Cuff Animation (Security Checks)
RegisterServerEvent("origen_police:server:playcuffanim", function(targetId, isCuffing)
    if not targetId or not source then
        return
    end
    
    local sourceId = tonumber(source)
    
    -- Security: Check if cuff action was initiated properly
    if not pendingCuffStates[sourceId] then
        BanPlayer(source, "Hook action detect not valid pending cuff state")
        return
    end
    
    -- Security: Validate target ID
    if targetId == -1 then
        BanPlayer(source, "Hook action with invalid source value in cuff animation")
        return
    end
    
    -- Security: Distance check
    local officerCoords = GetEntityCoords(GetPlayerPed(source))
    local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
    local distance = #(officerCoords - targetCoords)
    
    if distance > 20.0 then
        BanPlayer(source, "Hook action detect too far distance in cuff animation")
        return
    end
    
    -- Clear pending state
    pendingCuffStates[targetId] = nil
    
    -- Trigger animations on both players
    TriggerClientEvent("origen_police:client:playarrestanim", targetId, isCuffing) -- Officer animation
    TriggerClientEvent("origen_police:client:playarrestedanim", source, isCuffing) -- Suspect animation
end)

-- Drag Player
RegisterServerAction("origen_police:server:dragplayer", function(targetId, shouldDrag)
    if not targetId or not source then
        return
    end
    
    -- Update drag state on target player
    TriggerClientEvent("origen_police:client:setdragstate", targetId, shouldDrag, source)
    
end, "drag", 300, 1, Config.Actions.AllowAllJobsDrag)

-- Put Player In/Out of Vehicle
RegisterServerAction("origen_police:server:vehicleinof", function(targetId, vehicleNetId, seatIndex)
    if not source then
        return
    end
    
    -- Trigger vehicle in/out action on target
    TriggerClientEvent("origen_police:client:statevehicleinof", targetId, vehicleNetId, seatIndex)
    
end, "putinvehicle", 500, 1, Config.Actions.AllowAllJobsPutInVehicle)

-- Attach/Detach Player (Drag/Escort)
RegisterServerAction("origen_police:server:attachPlayer", function(targetId, dragType)
    if not source then
        return
    end
    
    -- Trigger animation on officer
    TriggerClientEvent("origen_police:client:doAnimation", source, dragType)
    
    -- Trigger attach/detach on target
    TriggerClientEvent("origen_police:client:getDragged", targetId, source, dragType)
    
end, "putinvehicle", 500, 1, Config.Actions.AllowAllJobsAttachPlayer)