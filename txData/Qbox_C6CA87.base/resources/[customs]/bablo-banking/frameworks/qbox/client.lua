Framework = Framework or {};

CreateThread(function()
    if Config.Framework ~= 'qbox' then
        return
    end

    function Framework:getCore()
        local success, core = pcall(function()
            return exports.qbx_core
        end)
        if success and core then
            return core
        end
        success, core = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if success and core then
            return core
        end
        return nil
    end

    function Framework:getCharacterIdentifier()
        local success, playerData = pcall(function()
            return exports.qbx_core:GetPlayerData()
        end)
        if not success or not playerData then
            Trace("^1[QBox Client] Failed to get player data^0")
            return nil
        end
        local citizenid = playerData.citizenid
        if not citizenid and playerData.charinfo then
            citizenid = playerData.charinfo.citizenid
        end
        return citizenid
    end

    function Framework:Notify(message)
        local success = pcall(function()
            exports.qbx_core:Notify(message)
        end)
        if not success then
            success = pcall(function()
                TriggerEvent('ox_lib:notify', {
                    title = 'Notification',
                    description = message,
                    type = 'inform'
                })
            end)
        end
        if not success then
            pcall(function()
                TriggerEvent('QBCore:Notify', message)
            end)
        end
    end

    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        Citizen.Wait(5000)
        TriggerServerEvent(eventName .. "server:characterLoaded")
    end)

    RegisterNetEvent('qbx_core:client:playerLoaded', function()
        Citizen.Wait(5000)
        TriggerServerEvent(eventName .. "server:characterLoaded")
    end)
end)