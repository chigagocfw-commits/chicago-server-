if not Config.Inventory or Config.Inventory ~= "qs-inventory" then return end

InventoryShopSupport = true
InventoryStashSupport = true

exports('mechanic_tablet', function()
    TriggerEvent('qs-mechanic-creator:client:openTablet')
end)

exports('repairkit', function()
    TriggerEvent('qs-mechanic-creator:client:useRepairKit')
end)

exports('sponge', function()
    TriggerEvent('qs-mechanic-creator:client:useSponge')
end)

exports('rope', function()
    TriggerEvent('qs-mechanic-creator:client:useRope')
end)

local shopSessionId = tostring(GetGameTimer())

function OpenShop(shopId, shopData)
    if not shopData or not shopData.items then return end

    local formattedItems = {}
    for i, item in ipairs(shopData.items) do
        formattedItems[i] = {
            name = item.item,
            amount = 999,
            price = item.price or 0,
            slot = i
        }
    end

    local shopConfig = {
        label = 'Mechanic Shop',
        items = formattedItems
    }

    TriggerServerEvent("inventory:server:OpenInventory", "shop", "mechanic_" .. shopId .. "_" .. shopSessionId, shopConfig)
end

function OpenStash(stashId)
    TriggerServerEvent("inventory:server:OpenInventory", "stash", stashId)
    TriggerEvent("inventory:client:SetCurrentStash", stashId)
end
