if not Config.Inventory or Config.Inventory ~= "jaksam_inventory" then return end

InventoryShopSupport = true
InventoryStashSupport = true

function OpenShop(shopId, shopData)
    if not shopId then return end

    local success, err = pcall(function()
        exports.jaksam_inventory:OpenShop(shopId)
    end)

    if not success then
        if Config.Debug then
            print('^3[Jaksam Inventory] Failed to open shop: ' .. tostring(err) .. '^0')
        end
        InventoryShopSupport = false
        if openShopMenu then
            openShopMenu(shopId, shopData and shopData.items or {})
        end
    end
end

function OpenStash(stashId)
    if not stashId then return end

    local success, err = pcall(function()
        exports.jaksam_inventory:OpenStash(stashId)
    end)

    if not success then
        if Config.Debug then
            print('^3[Jaksam Inventory] Failed to open stash: ' .. tostring(err) .. '^0')
        end
        InventoryStashSupport = false
        if openStashMenu then
            openStashMenu(stashId)
        end
    end
end
