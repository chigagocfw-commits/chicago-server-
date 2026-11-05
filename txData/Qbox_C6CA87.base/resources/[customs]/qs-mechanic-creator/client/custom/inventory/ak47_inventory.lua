if not Config.Inventory or Config.Inventory ~= "ak47_inventory" then return end

InventoryShopSupport = true
InventoryStashSupport = true

function OpenShop(shopId, shopData)
    if not shopData or not shopData.items then return end

    TriggerServerEvent("qs-mechanic-creator:server:openAK47InventoryShop", shopId, shopData)
end

function OpenStash(stashId)
    exports['ak47_inventory']:OpenInventory(stashId)
end

function HasItem(itemName, amount)
    local count = exports['ak47_inventory']:GetAmount(itemName)
    return count >= (amount or 1)
end

function GetItemCount(itemName)
    return exports['ak47_inventory']:GetAmount(itemName) or 0
end
