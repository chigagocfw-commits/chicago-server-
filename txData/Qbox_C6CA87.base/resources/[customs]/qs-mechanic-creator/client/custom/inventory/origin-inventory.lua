if not Config.Inventory or Config.Inventory ~= "origin-inventory" then return end

InventoryShopSupport = true
InventoryStashSupport = true

function OpenShop(shopId, shopData)
    if not shopData then return end
    
    exports.origen_inventory:openInventory('shop', 'mechanic_' .. shopId)
end

function OpenStash(stashId)
    exports.origen_inventory:openInventory('stash', stashId)
end
