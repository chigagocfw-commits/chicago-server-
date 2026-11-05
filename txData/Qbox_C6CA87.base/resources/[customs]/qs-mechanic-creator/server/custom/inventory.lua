function Mechanic.HasItem(src, item, count)
    count = count or 1
    if GetResourceState('ox_inventory') == 'started' then
        return (exports.ox_inventory:Search(src, 'count', item) or 0) >= count
    end
    if Config.Framework == 'esx' then
        local xPlayer = exports['es_extended']:getSharedObject().GetPlayerFromId(src)
        if not xPlayer then return false end
        local inv = xPlayer.getInventoryItem(item)
        return inv and inv.count >= count
    end
    if Config.Framework == 'qbcore' then
        local player = exports['qb-core']:GetCoreObject().Functions.GetPlayer(src)
        if not player then return false end
        local it = player.Functions.GetItemByName(item)
        return it and it.amount >= count
    end
    return true
end

function Mechanic.RemoveItem(src, item, count)
    count = count or 1
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:RemoveItem(src, item, count)
    end
    if Config.Framework == 'esx' then
        local xPlayer = exports['es_extended']:getSharedObject().GetPlayerFromId(src)
        if xPlayer then xPlayer.removeInventoryItem(item, count) end
        return true
    end
    if Config.Framework == 'qbcore' then
        local player = exports['qb-core']:GetCoreObject().Functions.GetPlayer(src)
        if player then player.Functions.RemoveItem(item, count) end
        return true
    end
    return true
end

function Mechanic.AddItem(src, item, count, metadata)
    count = count or 1
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:AddItem(src, item, count, metadata)
    end
    if Config.Framework == 'esx' then
        local xPlayer = exports['es_extended']:getSharedObject().GetPlayerFromId(src)
        if xPlayer then xPlayer.addInventoryItem(item, count) end
        return true
    end
    if Config.Framework == 'qbcore' then
        local player = exports['qb-core']:GetCoreObject().Functions.GetPlayer(src)
        if player then player.Functions.AddItem(item, count, false, metadata) end
        return true
    end
    return true
end

function Mechanic.GetInventory(src)
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:GetInventoryItems(src) or {}
    end
    return {}
end
