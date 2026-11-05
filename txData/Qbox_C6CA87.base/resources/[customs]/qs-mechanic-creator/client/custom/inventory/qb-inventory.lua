if not Config.Inventory or Config.Inventory ~= "qb-inventory" then return end

InventoryShopSupport = true
InventoryStashSupport = true

function OpenShop(shopId, shopData)
    if not shopData or not shopData.items then return end

    TriggerServerEvent("qs-mechanic-creator:server:openQBInventoryShop", shopId, shopData)
end

function OpenStash(stashId)
    TriggerServerEvent("qs-mechanic-creator:server:openQBInventoryStash", stashId)
end

