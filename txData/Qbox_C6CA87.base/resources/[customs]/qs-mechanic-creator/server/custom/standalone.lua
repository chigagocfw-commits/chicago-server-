if Config.Framework and Config.Framework ~= 'standalone' then
    return
end

function Mechanic.GetIdentifier(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:find('license:') then
            return id
        end
    end
    return ('player:%s'):format(src)
end

function Mechanic.GetPlayerLicense(src)
    return Mechanic.GetIdentifier(src)
end

function Mechanic.GetJob(src)
    return { name = 'unemployed', grade = 0 }
end

function Mechanic.HasAdminPermission(src)
    return IsPlayerAceAllowed(src, 'command.' .. (Config.CreatorCommand or 'mechanic_creator'))
        or IsPlayerAceAllowed(src, 'qs-mechanic-creator.admin')
end

function Mechanic.GetMoney()
    return 999999999
end

function Mechanic.RemoveMoney()
    return true
end

function Mechanic.AddMoney()
    return true
end

function Mechanic.SaveOwnedVehicleMods()
end

AddEventHandler('playerJoining', function()
    local src = source
    SetTimeout(3000, function()
        TriggerEvent('qs-mechanic-creator:internal:playerReady', src)
    end)
end)
