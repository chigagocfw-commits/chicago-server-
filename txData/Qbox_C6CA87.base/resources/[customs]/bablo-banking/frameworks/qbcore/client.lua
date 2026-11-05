Framework = Framework or {};

CreateThread(function()
    if Config.Framework ~= 'qbcore' then
        return
    end

    function Framework:getCore()
        return exports['qb-core']:GetCoreObject();
    end

    local QBCore = Framework:getCore();

    function Framework:getCharacterIdentifier()
        return QBCore.Functions.GetPlayerData().citizenid
    end

    function Framework:Notify(message)
        QBCore.Functions.Notify(message)
    end

    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        Citizen.Wait(5000)

        TriggerServerEvent(eventName .. "server:characterLoaded")
    end)

    -- TriggerServerEvent(eventName .. "server:characterLoaded")
end)