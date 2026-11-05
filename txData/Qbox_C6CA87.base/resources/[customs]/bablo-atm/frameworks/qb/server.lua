
if Config.Framework ~= "qbcore" then return end

local qbCore = exports['qb-core']:GetCoreObject()

if not qbCore then
    Debug("[bablo-atm] Error: QB-Core object not found!")
    return
end

Debug("[bablo-atm] QB-Core framework detected.")

function CreateUsableItem(item, cb)
    qbCore.Functions.CreateUseableItem(item, cb)
end

function GetCash(source)
    local Player = qbCore.Functions.GetPlayer(source)
    if Player then
        return Player.PlayerData.money.cash
    else
        error("Player not found")
        return false
    end
end

function RemoveCash(source, amount)
    local Player = qbCore.Functions.GetPlayer(source)
    if Player then
        Player.Functions.RemoveMoney('cash', amount)
    else
        error("Player not found")
        return false
    end

    return true
end

function AddCash(source, amount)
    local Player = qbCore.Functions.GetPlayer(source)
    if Player then
        Player.Functions.AddMoney('cash', amount)
    else
        error("Player not found")
        return false
    end

    return true
end
