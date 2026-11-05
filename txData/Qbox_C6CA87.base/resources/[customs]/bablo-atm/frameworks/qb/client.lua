
if Config.Framework ~= "qbcore" then return end
local core = exports['qb-core']:GetCoreObject()

if not core then
    Debug("[bablo-atm] Error: QB-Core object not found!")
    return
end

function SendNotification(message)
    core.Functions.Notify(message)
end
