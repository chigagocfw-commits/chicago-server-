-- K9 Dog Item
FW_CreateUseableItem("k9", function(source)
    local player = FW_GetPlayer(source)
    
    if not player or not player.PlayerData or not player.PlayerData.job then
        TriggerClientEvent("origen_police:ShowNotification", source, Config.Translations.CantUseItem or "You cannot use this item")
        return
    end
    
    local result = CanOpenTablet(player.PlayerData.job.name)
    local canOpen = result[1]
    local jobCategory = result[2]
    
    -- K9 is police-only equipment
    if not canOpen or jobCategory ~= Config.PoliceJobCategory then
        TriggerClientEvent("origen_police:ShowNotification", source, Config.Translations.CantUseItem or "You cannot use police K9")
        return
    end
    
    TriggerClientEvent("origen_police:client:CallK9", source)
end)

-- Badge System (LSPD, BCSD, FIB)
function BadgeUse(source, itemData, badgeType)
    local player = FW_GetPlayer(source)
    
    if not player or not player.PlayerData then
        return
    end
    
    local canOpen = CanOpenTablet(player.PlayerData.job.name)[1]
    
    -- Only police can use badge if configured
    if Config.OnlyPoliceCanUseBadge and not canOpen then
        return
    end
    
    -- ESX compatibility - convert item format
    if Config.Framework == "esx" then
        for _, item in pairs(player.PlayerData.items) do
            if item.name == itemData.name then
                itemData = {
                    name = item.name,
                    info = GetItemMetadata(item),
                    metadata = GetItemMetadata(item)
                }
                break
            end
        end
    end
    
    -- Initialize metadata
    itemData.info = itemData.info or {}
    itemData.metadata = itemData.metadata or {}
    itemData.info.type = badgeType
    itemData.metadata.type = badgeType
    
    TriggerClientEvent("origen_police:client:showbadge", source, GetItemMetadata(itemData))
end

-- Register badge items
FW_CreateUseableItem("lspd_badge", function(source, item)
    BadgeUse(source, item, "LSPD")
end)

FW_CreateUseableItem("bcsd_badge", function(source, item)
    BadgeUse(source, item, "BCSD")
end)

FW_CreateUseableItem("fib_badge", function(source, item)
    BadgeUse(source, item, "FIB")
end)

-- Show badge to nearby players
RegisterServerEvent("origen_police:server:showbadge", function(targetId, badgeData)
    TriggerClientEvent("origen_police:client:viewbadge", targetId, badgeData)
end)