if not Config.Inventory or Config.Inventory ~= "ps-inventory" then return end

InventoryShopSupport = true
InventoryStashSupport = true

function OpenShop(shopId, shopData)
    if not shopData or not shopData.items then return end
    
    TriggerServerEvent("inventory:server:OpenInventory", "shop", shopId, {
        label = "Mechanic Shop",
        items = shopData.items
    })
end

function OpenStash(stashId)
    TriggerServerEvent("inventory:server:OpenInventory", "stash", stashId)
    TriggerEvent("inventory:client:SetCurrentStash", stashId)
end

