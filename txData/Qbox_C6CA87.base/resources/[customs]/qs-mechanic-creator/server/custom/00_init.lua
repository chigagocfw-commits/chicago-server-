Mechanic = Mechanic or {}

Mechanic.ResourceName = GetCurrentResourceName()

if not Config.AdminGroups then
    Config.AdminGroups = {
        admin = true,
        superadmin = true,
        god = true,
    }
end

function Mechanic.Debug(...)
    if Config.Debug then
        print('^3[qs-mechanic-creator]^0', ...)
    end
end

function Mechanic.Notify(src, data)
    if type(data) == 'string' then
        data = { description = data }
    end
    TriggerClientEvent('qs-mechanic-creator:client:showNotification', src, data)
end
