-- Server Callbacks
-- Handles various server-side data requests

local vehicleOwnerCache = {}
-- Get vehicle owner data from plate
FW_CreateCallback("origen_police:callback:vehicledata", function(source, callback, plate)
    local ownerName = nil
    
    -- Check cache first
    if vehicleOwnerCache[plate] then
        ownerName = vehicleOwnerCache[plate]
    else
        -- Get owner from database
        local ownerIdentifier = GetOwnerIdentifierByPlate(plate)
        
        if not ownerIdentifier then
            -- No owner found, generate random name
            local gender = math.random(1, 2) == 1 and "male" or "female"
            ownerName = GetRandomName(gender)
        else
            -- Get player data from identifier
            local player = FW_GetPlayerFromCitizenid(ownerIdentifier)
            
            if player then
                ownerName = player.PlayerData.charinfo.firstname .. " " .. 
                           player.PlayerData.charinfo.lastname
            else
                -- Player not online, generate random name
                local gender = math.random(1, 2) == 1 and "male" or "female"
                ownerName = GetRandomName(gender)
            end
        end
        
        -- Cache the result
        vehicleOwnerCache[plate] = ownerName
    end
    
    callback(ownerName)
end)
-- K9 Unit search for illegal items
FW_CreateCallback("origen_police:server:K9Search", function(source, callback, searchTargets)
    for targetId, targetData in pairs(searchTargets) do
        Debuger("Processing search key", targetId)
        
        if tonumber(targetId) then
            -- Search player
            local player = FW_GetPlayer(targetId)
            Debuger("Player ID detected", targetId)
            
            if player then
                -- Check if player is police and on duty
                local canOpen = CanOpenTablet(player.PlayerData.job.name)
                local isPoliceOnDuty = canOpen[1] and player.PlayerData.job.onduty
                
                if not isPoliceOnDuty then
                    Debuger("Player is not allowed to use tablet or is off duty, job: ", player.PlayerData.job)
                    
                    -- Search player inventory
                    for i = 1, #player.PlayerData.items do
                        local item = player.PlayerData.items[i]
                        Debuger("Checking player item", item.name)
                        
                        if Config.K9.IlegalItems[item.name] then
                            Debuger("Illegal item found on player", item.name)
                            callback(targetId)
                            return
                        end
                    end
                end
            end
        else
            -- Search vehicle
            Debuger("Vehicle ID detected", targetId)
            
            local trunkItems = GetTrunkItems(targetId)
            local gloveboxItems = GetGloveboxItems(targetId)
            
            Debuger("Fetched vehicle storage, Trunk: ", json.encode(trunkItems), 
                   "Glovebox: ", json.encode(gloveboxItems))
            
            -- Check trunk items
            if trunkItems and type(trunkItems) == "table" and #trunkItems > 0 then
                for i = 1, #trunkItems do
                    if Config.K9.IlegalItems[trunkItems[i].name] then
                        Debuger("Illegal item found in trunk", trunkItems[i].name, targetId)
                        callback(targetId)
                        return
                    end
                end
            end
            
            -- Check glovebox items
            if gloveboxItems and type(gloveboxItems) == "table" and #gloveboxItems > 0 then
                for i = 1, #gloveboxItems do
                    if Config.K9.IlegalItems[gloveboxItems[i].name] then
                        Debuger("Illegal item found in glovebox", gloveboxItems[i].name, targetId)
                        callback(targetId)
                        return
                    end
                end
            end
        end
    end
    
    Debuger("No illegal items found")
    callback(false)
end)
-- Get camera URL for screenshots
FW_CreateCallback("origen_police:server:GetCameraUrl", function(source, callback)
    local cameraUrl = ServerConfig.Logs.Camera
    
    if not isValidURL(cameraUrl) then
        Debuger("Camera url not set in config/logs/logs.lua")
        callback(false)
    else
        callback(cameraUrl)
    end
end)
-- Check if player is admin
FW_CreateCallback("origen_police:server:getAdminState", function(source, callback)
    local isAdmin = Framework.Functions.HasPermission(source, "admin")
    print("^3[Origen Police] Admin check for player " .. source .. ": " .. tostring(isAdmin) .. "^7")
    callback(isAdmin)
end)
