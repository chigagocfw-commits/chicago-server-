if not Config.Inventory or Config.Inventory ~= "codem-inventory" then return end

InventoryShopSupport = false
InventoryStashSupport = false

function OpenShop(shopId, shopData)
    if not shopData or not shopData.items then return end
    
    openShopMenu(shopId, shopData.items)
end

function OpenStash(stashId)
    openStashMenu(stashId)
end