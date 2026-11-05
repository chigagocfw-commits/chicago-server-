
if Config.Framework ~= "qbox" then return end

local function GetQBXPlayer(source)
    if not source then return nil end
    
    local success, player = pcall(function()
        return exports.qbx_core:GetPlayer(source)
    end)
    if success and player then
        return player
    end
    
    success, player = pcall(function()
        local QBCore = exports['qb-core']:GetCoreObject()
        return QBCore.Functions.GetPlayer(source)
    end)
    if success and player then
        return player
    end
    
    return nil
end

Citizen.CreateThread(function()
    function CreateUsableItem(item, cb)
        local success = pcall(function()
            exports.qbx_core:CreateUsableItem(item, cb)
        end)
        if not success then
            pcall(function()
                local QBCore = exports['qb-core']:GetCoreObject()
                QBCore.Functions.CreateUsableItem(item, cb)
            end)
        end
    end
end)

function GetCash(source)
    local Player = GetQBXPlayer(source)
    if Player and Player.PlayerData and Player.PlayerData.money then
        return Player.PlayerData.money.cash or 0
    else
        Trace("^1[QBox ATM] Player not found for GetCash, source: " .. tostring(source) .. "^0")
        return 0
    end
end

function RemoveCash(source, amount)
    local Player = GetQBXPlayer(source)
    if Player and Player.Functions and Player.Functions.RemoveMoney then
        local success = pcall(function()
            Player.Functions.RemoveMoney('cash', amount)
        end)
        return success
    else
        Trace("^1[QBox ATM] Player not found for RemoveCash, source: " .. tostring(source) .. "^0")
        return false
    end
end

function AddCash(source, amount)
    local Player = GetQBXPlayer(source)
    if Player and Player.Functions and Player.Functions.AddMoney then
        local success = pcall(function()
            Player.Functions.AddMoney('cash', amount)
        end)
        return success
    else
        Trace("^1[QBox ATM] Player not found for AddCash, source: " .. tostring(source) .. "^0")
        return false
    end
end
