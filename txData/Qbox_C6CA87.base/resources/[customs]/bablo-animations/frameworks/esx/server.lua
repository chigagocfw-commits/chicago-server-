



Framework = Framework or {};

CreateThread(function()
    if Config.Framework ~= 'esx' then
        return
    end

    function Framework:getCore()
        return exports['es_extended']:getSharedObject();
    end

    local ESX = Framework:getCore();

    function Framework:fetchPlayer(source)
        return ESX.GetPlayerFromId(source)
    end

    function Framework:getPlayerName(source)
        source = tonumber(source)

        local player = self:fetchPlayer(source)

        if player.getName then
            return player.getName()
        end

        return "Unknown Player"
    end

    function Framework:isAdmin(source)
        source = tonumber(source)
        if not source then return false end

        local xPlayer = self:fetchPlayer(source)
        if xPlayer then
            local group = xPlayer.getGroup()
            if group == 'admin' or group == 'superadmin' or group == 'god' then
                return true
            end
        end

        if IsPlayerAceAllowed(source, 'command') then
            return true
        end

        return false
    end
end)
