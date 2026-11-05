



Framework = Framework or {};

CreateThread(function()
    if Config.Framework ~= 'qbcore' then
        return
    end

    function Framework:getCore()
        return exports['qb-core']:GetCoreObject();
    end

    function Framework:Notify(message)
        Framework:getCore():Notify(message)
    end

    local QBCore = Framework:getCore();

    function Framework:fetchPlayer(source)
        return QBCore.Functions.GetPlayer(source)
    end

    function Framework:getPlayerName(source)
        source = tonumber(source)

        local player = self:fetchPlayer(source)

        if player.Functions.GetName then
            return player.Functions.GetName()
        end

        return "Unknown Player"
    end

    function Framework:isAdmin(source)
        source = tonumber(source)
        if not source then return false end

        if QBCore.Functions.HasPermission(source, 'admin') or QBCore.Functions.HasPermission(source, 'god') then
            return true
        end

        if IsPlayerAceAllowed(source, 'command') then
            return true
        end

        return false
    end
end)
