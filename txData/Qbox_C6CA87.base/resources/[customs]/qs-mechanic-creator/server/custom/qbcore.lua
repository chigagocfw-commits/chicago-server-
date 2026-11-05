if not Config.Framework or Config.Framework ~= 'qbcore' then
    return
end

local QBCore = exports['qb-core']:GetCoreObject()

function Mechanic.GetIdentifier(src)
    local player = QBCore.Functions.GetPlayer(src)
    return player and player.PlayerData.citizenid or nil
end

function Mechanic.GetPlayerLicense(src)
    return Mechanic.GetIdentifier(src)
end

function Mechanic.GetJob(src)
    local player = QBCore.Functions.GetPlayer(src)
    if not player or not player.PlayerData.job then return nil end
    local job = player.PlayerData.job
    return { name = job.name, grade = job.grade.level or job.grade or 0 }
end

function Mechanic.HasAdminPermission(src)
    return QBCore.Functions.HasPermission(src, 'admin')
        or QBCore.Functions.HasPermission(src, 'god')
        or IsPlayerAceAllowed(src, 'command.' .. (Config.CreatorCommand or 'mechanic_creator'))
end

function Mechanic.GetMoney(src, account)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return 0 end
    if account == 'cash' or account == 'money' then
        return player.PlayerData.money.cash or 0
    end
    return player.PlayerData.money.bank or 0
end

function Mechanic.RemoveMoney(src, amount, account)
    local player = QBCore.Functions.GetPlayer(src)
    if not player or amount <= 0 then return false end
    if account == 'bank' then
        return player.Functions.RemoveMoney('bank', amount)
    end
    return player.Functions.RemoveMoney('cash', amount)
end

function Mechanic.AddMoney(src, amount, account)
    local player = QBCore.Functions.GetPlayer(src)
    if not player or amount <= 0 then return false end
    if account == 'bank' then
        return player.Functions.AddMoney('bank', amount)
    end
    return player.Functions.AddMoney('cash', amount)
end

function Mechanic.SaveOwnedVehicleMods(plate, props)
    if not plate or not props then return end
    plate = NormalizePlate(plate)
    MySQL.update.await(
        'UPDATE player_vehicles SET mods = ? WHERE plate = ? OR REPLACE(UPPER(plate), " ", "") = ?',
        { json.encode(props), plate, plate }
    )
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    SetTimeout(1500, function()
        TriggerEvent('qs-mechanic-creator:internal:playerReady', src)
    end)
end)
