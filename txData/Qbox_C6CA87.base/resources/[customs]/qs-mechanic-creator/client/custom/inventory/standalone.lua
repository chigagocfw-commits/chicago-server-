if Config.Inventory and Config.Inventory ~= "standalone" then return end

InventoryShopSupport = false
InventoryStashSupport = false

function OpenShop(shopId, shopData)
    if not shopData or not shopData.items then return end
    
    openShopMenu(shopId, shopData.items)
end

function OpenStash(stashId)
    openStashMenu(stashId)
end
