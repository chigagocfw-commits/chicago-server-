
if Config.Framework ~= "esx" then return end

local ESX = exports['es_extended']:getSharedObject()

Citizen.CreateThread(function()
    function CreateUsableItem(item, cb)
        ESX.RegisterUsableItem(item, cb)
    end
end)

function GetCash(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        return xPlayer.getMoney()
    else
        error("Player not found")
        return false
    end
end

function RemoveCash(source, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        xPlayer.removeMoney(amount)
    else
        error("Player not found")
        return false
    end

    return true
end

function AddCash(source, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        xPlayer.addMoney(amount)
    else
        error("Player not found")
        return false
    end

    return true
end
