local Bridge = {}

local function detectFramework()
    local configured = ScootConfig.framework
    if configured and configured ~= "auto" then
        return configured
    end

    if GetResourceState("qbx_core") == "started" then
        return "qbx"
    end
    if GetResourceState("qb-core") == "started" then
        return "qb"
    end
    if GetResourceState("es_extended") == "started" then
        return "esx"
    end
    if GetResourceState("ox_core") == "started" then
        return "ox"
    end

    return "standalone"
end

Bridge.framework = detectFramework()

local QBCore = nil
local ESX = nil

if Bridge.framework == "qb" then
    pcall(function()
        QBCore = exports["qb-core"]:GetCoreObject()
    end)
elseif Bridge.framework == "esx" then
    pcall(function()
        ESX = exports.es_extended:getSharedObject()
    end)
end

function Bridge.getIdentifier(source)
    if Bridge.framework == "qbx" then
        local player = exports.qbx_core:GetPlayer(source)
        if player and player.PlayerData then
            return player.PlayerData.citizenid
        end
    elseif Bridge.framework == "qb" and QBCore then
        local player = QBCore.Functions.GetPlayer(source)
        if player and player.PlayerData then
            return player.PlayerData.citizenid
        end
    elseif Bridge.framework == "esx" and ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            return xPlayer.identifier
        end
    elseif Bridge.framework == "ox" then
        local player = exports.ox_core:GetPlayer(source)
        if player then
            return tostring(player.charId or player.userId)
        end
    end

    local license = GetPlayerIdentifierByType(source, "license")
    if license then
        return license
    end

    return tostring(source)
end

function Bridge.getName(source)
    if Bridge.framework == "qbx" then
        local player = exports.qbx_core:GetPlayer(source)
        if player and player.PlayerData and player.PlayerData.charinfo then
            return string.format("%s %s", player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname)
        end
    elseif Bridge.framework == "qb" and QBCore then
        local player = QBCore.Functions.GetPlayer(source)
        if player and player.PlayerData and player.PlayerData.charinfo then
            return string.format("%s %s", player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname)
        end
    elseif Bridge.framework == "esx" and ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer and xPlayer.getName then
            return xPlayer.getName()
        end
    end

    return GetPlayerName(source)
end

function Bridge.getMoney(source, account)
    account = account or "cash"

    if Bridge.framework == "qbx" then
        local player = exports.qbx_core:GetPlayer(source)
        if player and player.Functions then
            local accType = (account == "bank") and "bank" or "cash"
            return player.Functions.GetMoney(accType) or 0
        end
    elseif Bridge.framework == "qb" and QBCore then
        local player = QBCore.Functions.GetPlayer(source)
        if player and player.Functions then
            local accType = (account == "bank") and "bank" or "cash"
            return player.Functions.GetMoney(accType) or 0
        end
    elseif Bridge.framework == "esx" and ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            if account == "bank" then
                local bankAcc = xPlayer.getAccount("bank")
                return bankAcc and bankAcc.money or 0
            else
                return xPlayer.getMoney() or 0
            end
        end
    elseif Bridge.framework == "ox" then
        local player = exports.ox_core:GetPlayer(source)
        if player then
            return player.getAccountBalance(account) or 0
        end
    end

    return 999999
end

function Bridge.removeMoney(source, account, amount)
    amount = math.floor(amount or 0)
    if amount <= 0 then
        return true
    end

    if Bridge.framework == "qbx" then
        local player = exports.qbx_core:GetPlayer(source)
        if player and player.Functions then
            local accType = (account == "bank") and "bank" or "cash"
            if player.Functions.GetMoney(accType) >= amount then
                return player.Functions.RemoveMoney(accType, amount, "scoot-rental") == true
            end
            return false
        end
    elseif Bridge.framework == "qb" and QBCore then
        local player = QBCore.Functions.GetPlayer(source)
        if player and player.Functions then
            local accType = (account == "bank") and "bank" or "cash"
            if player.Functions.GetMoney(accType) >= amount then
                return player.Functions.RemoveMoney(accType, amount, "scoot-rental") == true
            end
            return false
        end
    elseif Bridge.framework == "esx" and ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            if account == "bank" then
                local bankAcc = xPlayer.getAccount("bank")
                if bankAcc and bankAcc.money >= amount then
                    xPlayer.removeAccountMoney("bank", amount, "scoot-rental")
                    return true
                end
            else
                if xPlayer.getMoney() >= amount then
                    xPlayer.removeMoney(amount, "scoot-rental")
                    return true
                end
            end
            return false
        end
    elseif Bridge.framework == "ox" then
        local player = exports.ox_core:GetPlayer(source)
        if player then
            return player.removeAccountBalance(account, amount) == true
        end
    end

    return true
end

function Bridge.addMoney(source, account, amount)
    amount = math.floor(amount or 0)
    if amount <= 0 then
        return true
    end

    if Bridge.framework == "qbx" then
        local player = exports.qbx_core:GetPlayer(source)
        if player and player.Functions then
            local accType = (account == "bank") and "bank" or "cash"
            return player.Functions.AddMoney(accType, amount, "scoot-refund") == true
        end
    elseif Bridge.framework == "qb" and QBCore then
        local player = QBCore.Functions.GetPlayer(source)
        if player and player.Functions then
            local accType = (account == "bank") and "bank" or "cash"
            return player.Functions.AddMoney(accType, amount, "scoot-refund") == true
        end
    elseif Bridge.framework == "esx" and ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            if account == "bank" then
                xPlayer.addAccountMoney("bank", amount, "scoot-refund")
            else
                xPlayer.addMoney(amount, "scoot-refund")
            end
            return true
        end
    elseif Bridge.framework == "ox" then
        local player = exports.ox_core:GetPlayer(source)
        if player then
            return player.addAccountBalance(account, amount) == true
        end
    end

    return true
end

function Bridge.hasPermission(source, permission)
    if not permission or permission == "" then
        return true
    end

    if IsPlayerAceAllowed(source, permission) then
        return true
    end

    local adminAce = ScootConfig.creator and ScootConfig.creator.adminAce
    if adminAce and IsPlayerAceAllowed(source, adminAce) then
        return true
    end

    if Bridge.framework == "qbx" then
        local player = exports.qbx_core:GetPlayer(source)
        if player and player.PlayerData and (player.PlayerData.optin or player.PlayerData.isAdmin) then
            return true
        end
    elseif Bridge.framework == "qb" and QBCore then
        if QBCore.Functions.HasPermission(source, "admin") or QBCore.Functions.HasPermission(source, "god") then
            return true
        end
    elseif Bridge.framework == "esx" and ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer and (xPlayer.getGroup() == "admin" or xPlayer.getGroup() == "superadmin") then
            return true
        end
    end

    return false
end

return Bridge
