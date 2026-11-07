if not Config.Inventory or Config.Inventory ~= "ox_inventory" then return end

InventoryShopSupport = true
InventoryStashSupport = true

function OpenShop(shopId, shopData)
    if not shopData then return end
    
    local success, err = pcall(function()
        exports.ox_inventory:openInventory('shop', { type = shopId })
    end)
    
    if not success then
        if Config.Debug then
            print('^3[ox_inventory] Failed to open shop, falling back to context menu: ' .. tostring(err) .. '^0')
        end
        InventoryShopSupport = false
        if openShopMenu then
            openShopMenu(shopId, shopData.items or {})
        end
    end
end

function OpenStash(stashId)
    local success, err = pcall(function()
        exports.ox_inventory:openInventory('stash', { id = stashId })
    end)
    
    if not success then
        if Config.Debug then
            print('^3[ox_inventory] Failed to open stash, falling back to context menu: ' .. tostring(err) .. '^0')
        end
        InventoryStashSupport = false
        if openStashMenu then
            openStashMenu(stashId)
        end
    end
end

exports('mechanic_tablet', function(data, slot)
    exports.ox_inventory:useItem(data, function(used)
        if used then
            TriggerEvent('qs-mechanic-creator:client:openTablet')
        end
    end)
end)

exports('repairkit', function(data, slot)
    exports.ox_inventory:useItem(data, function(used)
        if used then
            TriggerEvent('qs-mechanic-creator:client:useRepairkit')
        end
    end)
end)

exports('sponge', function(data, slot)
    exports.ox_inventory:useItem(data, function(used)
        if used then
            TriggerEvent('qs-mechanic-creator:client:useSponge')
        end
    end)
end)

exports('rope', function(data, slot)
    exports.ox_inventory:useItem(data, function(used)
        if used then
            TriggerEvent('qs-mechanic-creator:client:useRope')
        end
    end)
end)
