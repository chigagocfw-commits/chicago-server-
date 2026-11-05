Framework = Framework or {};

CreateThread(function()
    if Config.Framework ~= 'esx' then
        return
    end

    function Framework:getCore()
        return exports['es_extended']:getSharedObject();
    end

    local ESX = Framework:getCore();

    function Framework:getCharacterIdentifier()
        return ESX.GetPlayerData().identifier
    end

    function Framework:Notify(message)
        ESX.ShowNotification(message)
    end

    RegisterNetEvent('esx:playerLoaded', function()
        Citizen.Wait(5000)

        TriggerServerEvent(eventName .. "server:characterLoaded")
    end)
end)