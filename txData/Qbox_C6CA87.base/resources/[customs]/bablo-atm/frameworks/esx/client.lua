
if Config.Framework ~= "esx" then
    return
end

local ESX = exports['es_extended']:getSharedObject()

function SendNotification(message)
    ESX.ShowNotification(message)
end
