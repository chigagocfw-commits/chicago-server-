-- Add license to player
FW_CreateCallback("origen_police:police:AddLicense", function(source, callback, data)
    -- data.citizenid, data.type
    
    cachedLicenses[data.citizenid] = nil
    TriggerEvent("origen_police:server:onLicenseAdded", data.citizenid, data.type)
    
    if Config.UseDefaultSystem then
        if Config.Framework == "qbcore" then
            local player = Framework.Functions.GetPlayerByCitizenId(data.citizenid)
            
            if not player then
                player = Framework.Functions.GetOfflinePlayerByCitizenId(data.citizenid)
            end
            
            if player and player.PlayerData.metadata.licences then
                if not player.PlayerData.metadata.licences[data.type] then
                    player.PlayerData.metadata.licences[data.type] = true
                    player.Functions.SetMetaData("licences", player.PlayerData.metadata.licences)
                    callback(true)
                else
                    callback(false)
                end
            end
        elseif Config.Framework == "esx" then
            MySQL.query(
                "SELECT COUNT(*) as count FROM user_licenses WHERE type = ? AND owner = ?",
                {data.type, data.citizenid},
                function(result)
                    if result[1].count == 0 then
                        MySQL.insert(
                            "INSERT INTO user_licenses (type, owner) VALUES (?, ?)",
                            {data.type, data.citizenid},
                            function(affectedRows)
                                callback(affectedRows > 0)
                            end
                        )
                    else
                        callback(false)
                    end
                end
            )
        end
    else
        AddLicense(source, data.citizenid, data.type, callback)
    end
end)

-- Remove license from player
FW_CreateCallback("origen_police:police:RemoveLicense", function(source, callback, data)
    TriggerEvent("origen_police:server:onLicenseRemoved", data.citizenid, data.type)
    cachedLicenses[data.citizenid] = nil
    
    if Config.UseDefaultSystem then
        if Config.Framework == "qbcore" then
            local player = Framework.Functions.GetPlayerByCitizenId(data.citizenid)
            
            if not player then
                player = Framework.Functions.GetOfflinePlayerByCitizenId(data.citizenid)
            end
            
            if player and player.PlayerData.metadata.licences then
                if player.PlayerData.metadata.licences[data.type] then
                    player.PlayerData.metadata.licences[data.type] = false
                    player.Functions.SetMetaData("licences", player.PlayerData.metadata.licences)

                    local licenseItemMap = {
                        driver = 'driver_license',
                        weapon = 'weaponlicense',
                        id = 'id_card',
                    }
                    local itemToConfiscate = licenseItemMap[data.type]
                    if itemToConfiscate and player.PlayerData.source and GetResourceState('ox_inventory') == 'started' then
                        pcall(function()
                            local count = exports.ox_inventory:GetItemCount(player.PlayerData.source, itemToConfiscate)
                            if count and count > 0 then
                                exports.ox_inventory:RemoveItem(player.PlayerData.source, itemToConfiscate, count)
                            end
                        end)
                    end

                    callback(true)
                end
            end
        elseif Config.Framework == "esx" then
            MySQL.awaitQuery(
                "DELETE FROM user_licenses WHERE owner = ? AND type = ?",
                {data.citizenid, data.type}
            )
            callback(true)
        end
    else
        RemoveLicense(source, data.citizenid, data.type, callback)
    end
end)

-- Get available licenses
FW_CreateCallback("origen_police:police:GetLicenses", function(source, callback)
    if Config.UseDefaultSystem then
        local licenses = {}
        
        if Config.Framework == "qbcore" then
            for type, name in pairs(Config.Licenses) do
                licenses[type] = {
                    name = name,
                    type = type,
                    expire = Config.DefaultExpireTime
                }
            end
            callback(licenses)
        elseif Config.Framework == "esx" then
            local result = MySQL.awaitQuery("SELECT * FROM licenses")
            
            for i = 1, #result do
                licenses[result[i].type] = {
                    name = result[i].label,
                    type = result[i].type,
                    expire = Config.DefaultExpireTime
                }
            end
            callback(licenses)
        end
    else
        callback(GetLicenses())
    end
end)