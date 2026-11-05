if not Config.Framework or Config.Framework ~= 'esx' then
    return
end

local ESX = exports['es_extended']:getSharedObject()

function Mechanic.GetIdentifier(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    return xPlayer and xPlayer.identifier or nil
end

function Mechanic.GetPlayerLicense(src)
    return Mechanic.GetIdentifier(src)
end

function Mechanic.GetJob(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not xPlayer.job then return nil end
    return {
        name = xPlayer.job.name,
        grade = xPlayer.job.grade,
    }
end

function Mechanic.HasAdminPermission(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    local group = xPlayer.getGroup and xPlayer.getGroup() or xPlayer.group
    if group and Config.AdminGroups[group] then
        return true
    end
    return IsPlayerAceAllowed(src, 'command.' .. (Config.CreatorCommand or 'mechanic_creator'))
        or IsPlayerAceAllowed(src, 'qs-mechanic-creator.admin')
end

function Mechanic.GetMoney(src, account)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return 0 end
    account = account or 'money'
    if account == 'cash' then account = 'money' end
    local acc = xPlayer.getAccount(account)
    return acc and acc.money or 0
end

function Mechanic.RemoveMoney(src, amount, account)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or amount <= 0 then return false end
    account = account or 'money'
    if account == 'cash' then account = 'money' end
    if Mechanic.GetMoney(src, account) < amount then return false end
    xPlayer.removeAccountMoney(account, amount)
    return true
end

function Mechanic.AddMoney(src, amount, account)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or amount <= 0 then return false end
    account = account or 'money'
    if account == 'cash' then account = 'money' end
    xPlayer.addAccountMoney(account, amount)
    return true
end

function Mechanic.SaveOwnedVehicleMods(plate, props)
    if not plate or not props then return end
    plate = NormalizePlate(plate)
    MySQL.update.await(
        'UPDATE owned_vehicles SET vehicle = ? WHERE plate = ? OR REPLACE(UPPER(plate), " ", "") = ?',
        { json.encode(props), plate, plate }
    )
end

RegisterNetEvent('esx:playerLoaded', function(playerId, _)
    local src = playerId or source
    if src and src > 0 then
        SetTimeout(1500, function()
            TriggerEvent('qs-mechanic-creator:internal:playerReady', src)
        end)
    end
end)

AddEventHandler('esx:playerDropped', function() end)
