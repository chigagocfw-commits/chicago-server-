function ExecuteSql(query, parameters)
    local IsBusy = true
    local result = nil

    local function handleCallback(data)
        result = data
        IsBusy = false
    end

    if Config.SQL == "oxmysql" then
        if parameters then
            exports.oxmysql:execute(query, parameters, handleCallback)
        else
            exports.oxmysql:execute(query, {}, handleCallback)
        end
    elseif Config.SQL == "ghmattimysql" then
        if parameters then
            exports.ghmattimysql:execute(query, parameters, handleCallback)
        else
            exports.ghmattimysql:execute(query, {}, handleCallback)
        end
    elseif Config.SQL == "mysql-async" then
        if parameters then
            MySQL.Async.fetchAll(query, parameters, handleCallback)
        else
            MySQL.Async.fetchAll(query, {}, handleCallback)
        end
    end

    while IsBusy do
        Citizen.Wait(0)
    end

    return result
end

function CodemSQLQuery(query, parameters)
    if Config.SQL == "oxmysql" then
        exports.oxmysql:execute(query, parameters)
    elseif Config.SQL == "ghmattimysql" then
        exports.ghmattimysql:execute(query, parameters)
    elseif Config.SQL == "mysql-async" then
        MySQL.Async.fetchAll(query, parameters)
    end
end

function WaitCore()
    while Core == nil do
        Wait(0)
    end
end

function RegisterCallback(name, cbFunc)
    while not Core do
        Wait(0)
    end
    if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
        Core.RegisterServerCallback(name, function(source, cb, data)
            cbFunc(source, cb, data)
        end)
    else
        Core.Functions.CreateCallback(name, function(source, cb, data)
            cbFunc(source, cb, data)
        end)
    end
end

Citizen.CreateThread(function()
    while not Core do
        Citizen.Wait(0)
    end
    if Config.Framework == "qb" or Config.Framework == "oldqb" or Config.Framework == 'qbox' then
        for k, v in pairs(Config.Items) do
            if v.type == "rod" then
                Core.Functions.CreateUseableItem(v.name, function(source)
                    local src = source
                    local Player = Core.Functions.GetPlayer(src)
                    if not Player then
                        return
                    end
                    TriggerClientEvent("codem-fishingjob:client:StartFishing", src, v)
                end)
            end
        end
    else
        for k, v in pairs(Config.Items) do
            if v.type == "rod" then
                Core.RegisterUsableItem(v.name, function(source)
                    local src = source
                    local Player = Core.GetPlayerFromId(src)
                    if not Player then
                        return
                    end
                    TriggerClientEvent("codem-fishingjob:client:StartFishing", src, v)
                    --TriggerClientEvent("codem-fishingjob:client:StartFishing", src, v.name, v.label)
                end)
            end
        end
    end
end)

RegisterServerEvent('codem-fishingjob:getplayerinventory', function()
    local src = source

    local inventory = GetPlayerInventory(src)
    TriggerClientEvent('codem-fishingjob:client:playerinventory', src, inventory)
end)

function GetPlayerInventory(source)
    local data = {}
    local Player = GetPlayer(source)
    if not Player then
        return {}
    end
    if Config.Inventory == "esx-inventory" then
        for _, v in pairs(Player.getInventory()) do
            local amount = v.count or v.amount
            if v and tonumber(amount) > 0 then
                local formattedData = v
                formattedData.name = string.lower(v.name)
                formattedData.label = v.label
                formattedData.amount = amount
                formattedData.image = v.image or (string.lower(v.name) .. '.png')
                table.insert(data, formattedData)
            end
        end
    elseif Config.Inventory == "qb-inventory" then
        for _, v in pairs(Player.PlayerData.items or {}) do
            if v then
                local amount = v.count or v.amount
                if tonumber(amount) > 0 then
                    local formattedData = v
                    formattedData.name = string.lower(v.name)
                    formattedData.label = v.label
                    formattedData.amount = amount
                    formattedData.image = v.image or (string.lower(v.name) .. '.png')
                    table.insert(data, formattedData)
                end
            end
        end
    elseif Config.Inventory == "qs-inventory" then
        local inventory = exports['qs-inventory']:GetInventory(source)
        if inventory then
            for _, v in pairs(inventory) do
                local amount = v.amount or v.count
                if tonumber(amount) > 0 then
                    local formattedData = v
                    formattedData.name = string.lower(v.name)
                    formattedData.label = v.label
                    formattedData.amount = amount
                    formattedData.image = v.image or (string.lower(v.name) .. '.png')
                    table.insert(data, formattedData)
                end
            end
        end
    elseif Config.Inventory == "ox-inventory" then
        local inventory = exports.ox_inventory:GetInventoryItems(source)
        for _, v in pairs(inventory) do
            local amount = v.count or v.amount
            if tonumber(amount) > 0 then
                local formattedData = v
                formattedData.name = string.lower(v.name)
                formattedData.label = v.label
                formattedData.amount = amount
                formattedData.image = v.image or (string.lower(v.name) .. '.png')
                table.insert(data, formattedData)
            end
        end
    end
    return data
end

function RemoveItem(src, item, amount)
    local Player = GetPlayer(src)
    if Player then
        if Config.Inventory == "qb-inventory" then
            Player.Functions.RemoveItem(item, amount)
        elseif Config.Inventory == "esx-inventory" then
            Player.removeInventoryItem(item, amount)
        elseif Config.Inventory == "ox-inventory" then
            exports.ox_inventory:RemoveItem(src, item, amount)
        elseif Config.Inventory == "codem-inventory" then
            exports['codem-inventory']:RemoveItem(src, item, amount)
        elseif Config.Inventory == "qs-inventory" then
            exports['qs-inventory']:RemoveItem(src, item, amount)
        end
        --  TriggerClientEvent('codem-fishingjob:client:playerinventory', src, GetPlayerInventory(src))
    end
end

function GetPlayerMoney(source, value)
    local Player = GetPlayer(source)
    if Player then
        if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
            if value == 'bank' then
                return Player.getAccount('bank').money
            end
            if value == 'cash' then
                return Player.getMoney()
            end
        elseif Config.Framework == 'qb' or Config.Framework == 'oldqb' then
            if value == 'bank' then
                return Player.PlayerData.money['bank']
            end
            if value == 'cash' then
                return Player.Functions.GetMoney('cash')
            end
        elseif Config.Framework == 'qbox' then
            if value == 'bank' then
                return Player.PlayerData.money['bank']
            end
            if value == 'cash' then
                return Player.Functions.GetMoney('cash')
            end
        end
    end
end

function AddItem(src, item, amount, slot, info)
    local Player = GetPlayer(src)
    if Player then
        if Config.Inventory == "qb-inventory" then
            Player.Functions.AddItem(item, amount, slot, info)
        elseif Config.Inventory == "esx-inventory" then
            Player.addInventoryItem(item, amount, slot, info)
        elseif Config.Inventory == "ox-inventory" then
            exports.ox_inventory:AddItem(src, item, amount, info)
        elseif Config.Inventory == "codem-inventory" then
            exports['codem-inventory']:AddItem(src, item, amount)
        elseif Config.Inventory == "qs-inventory" then
            exports['qs-inventory']:AddItem(src, item, amount, slot or nil, info)
        end
    end
end

function RemoveMoney(source, type, value)
    local Player = GetPlayer(source)
    if Player then
        if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
            if type == 'bank' then
                Player.removeAccountMoney('bank', value)
            end
            if type == 'cash' then
                Player.removeMoney(value)
            end
        elseif Config.Framework == 'qb' or Config.Framework == 'oldqb' then
            if type == 'bank' then
                Player.Functions.RemoveMoney('bank', value)
            end
            if type == 'cash' then
                Player.Functions.RemoveMoney('cash', value)
            end
        end
    end
end

function AddMoney(source, type, value)
    local Player = GetPlayer(source)
    if Player then
        if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
            if type == 'bank' then
                Player.addAccountMoney('bank', value)
                TriggerEvent('job_payment_email:send', source, value, 'payment')
            end
            if type == 'cash' then
                Player.addMoney(value)
            end
        elseif Config.Framework == 'qb' or Config.Framework == 'oldqb' then
            if type == 'bank' then
                local ok = Player.Functions.AddMoney('bank', value)
                if ok then
                    TriggerEvent('job_payment_email:send', source, value, 'payment')
                end
            end
            if type == 'cash' then
                Player.Functions.AddMoney('cash', value)
            end
        end
    end
end

function GetPlayer(source)
    local Player = false
    while Core == nil do
        Citizen.Wait(0)
    end
    if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
        Player = Core.GetPlayerFromId(source)
    elseif Config.Framework == 'oldqb' or Config.Framework == 'qb' then
        Player = Core.Functions.GetPlayer(source)
    elseif Config.Framework == 'qbox' then
        Player = Core.Functions.GetPlayer(source)
    end
    return Player
end

function GetIdentifier(source)
    local Player = GetPlayer(source)
    if Player then
        if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
            return Player.getIdentifier() or nil
        elseif Config.Framework == 'qb' or Config.Framework == 'oldqb' then
            return Player.PlayerData.citizenid or nil
        elseif Config.Framework == 'qbox' then
            return Player.PlayerData.citizenid or nil
        end
    end
end

function GetName(source)
    if Config.Framework == "oldesx" or Config.Framework == "esx" then
        local xPlayer = Core.GetPlayerFromId(tonumber(source))
        if xPlayer then
            return xPlayer.getName()
        else
            return "0"
        end
    elseif Config.Framework == 'qb' or Config.Framework == 'oldqb' then
        local Player = Core.Functions.GetPlayer(tonumber(source))
        if Player then
            return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        else
            return "0"
        end
    end
end

function IsPlayerInGame(serverId)
    if (serverId == nil) then
        return false
    end
    if (serverId == 0) then
        return false
    end
    local playerId = tonumber(serverId)
    if not playerId then
        return false
    end
    local endpoint = GetPlayerEndpoint(playerId)

    if endpoint and endpoint ~= "" then
        return true
    else
        return false
    end
end

function GenerateId()
    local random = math.random
    local templates = {
        'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx',
        'xxxxxxxx-2xxx-xxxx-yxxx-xxxxxxxxxxxx',
        'xxxxxxxx-xxxx-8xxx-yxxx-xxxxxxxxxxxx',
        'xxxxxxxx-1xxx-xxxx-yxxx-xxxxxxxxxxxx',
        'xxxxxxxx-6xxx-xxxx-yxxx-xxxxxxxxxxxx',
    }
    local template = templates[random(1, #templates)]
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

AddEventHandler('playerDropped', function(reason)
    local src = source
end)

Citizen.CreateThread(function()
    if Config.VersionChecker then
        local resource_name = 'codem-fishing'
        local current_version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
        PerformHttpRequest('https://raw.githubusercontent.com/Aiakos232/versionchecker/main/version.json',
            function(error, result, headers)
                if not result then
                    print('^1Version check disabled because github is down.^0')
                    return
                end
                local result = json.decode(result)
                if tonumber(result[resource_name]) ~= nil then
                    if tonumber(result[resource_name]) > tonumber(current_version) then
                        print('\n')
                        print('^1======================================================================^0')
                        print('^1' .. resource_name ..
                            ' is outdated, new version is available: ' .. result[resource_name] .. '^0')
                        print('^1======================================================================^0')
                        print('\n')
                    elseif tonumber(result[resource_name]) == tonumber(current_version) then
                        print('^2' .. resource_name .. ' is up to date! -  ^4 Thanks for choose CodeM ^4 ^0')
                    elseif tonumber(result[resource_name]) < tonumber(current_version) then
                        print('^3' .. resource_name .. ' is a higher version than the official version!^0')
                    end
                else
                    print('^1' .. resource_name .. ' is not in the version database^0')
                end
            end, 'GET')
    end
end)

function ExtractIdentifiers(src)
    local identifiers = {
        steam = "",
        discord = "",
        license = ""
    }
    if src == nil or src == 0 then
        return identifiers
    end
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if string.find(id, "steam") then
            identifiers.steam = id
        elseif string.find(id, "discord") then
            identifiers.discord = "<@" .. id:gsub("discord:", "") .. ">"
        elseif string.find(id, "license") then
            identifiers.license = id
        end
    end
    return identifiers
end

function AddXP(src, identifier)
    local PlayerData = AllPlayerData[identifier]
    if not PlayerData then
        return
    end
    local randomXP = math.random(Config.FishIsCoughtXp.min, Config.FishIsCoughtXp.max)

    PlayerData.xp = tonumber(PlayerData.xp)
    PlayerData.level = tonumber(PlayerData.level)
    PlayerData.xp = PlayerData.xp + randomXP
    local requiredXP = Config.RequiredXP[PlayerData.level]
    if PlayerData.xp >= requiredXP then
        PlayerData.level = PlayerData.level + 1
        PlayerData.xp = PlayerData.xp - requiredXP
    end
    local query = [[
        UPDATE codem_fishingjob_player SET level = ?, xp = ? WHERE identifier = ?
    ]]

    local parameters = { PlayerData.level, PlayerData.xp, identifier }

    local success, result = pcall(function()
        CodemSQLQuery(query, parameters)
    end)

    if not success then
        print('Error: ' .. result)
    end
    TriggerClientEvent('codem-fishingjob:UpdateLevel', src, PlayerData.level, PlayerData.xp)
end

function AddXpCount(src, identifier, amount)
    local PlayerData = AllPlayerData[identifier]
    if not PlayerData then
        return
    end

    if not amount or amount == 0 then
        return
    end
    
    PlayerData.xp = tonumber(PlayerData.xp) + tonumber(amount)
    PlayerData.level = tonumber(PlayerData.level)

    local requiredXP = Config.RequiredXP[PlayerData.level]
    if PlayerData.xp >= requiredXP then
        PlayerData.level = PlayerData.level + 1
        PlayerData.xp = PlayerData.xp - requiredXP
    end

    local query = [[
        UPDATE codem_fishingjob_player SET level = ?, xp = ? WHERE identifier = ?
    ]]
    local parameters = { PlayerData.level, PlayerData.xp, identifier }
    local success, result = pcall(function()
        CodemSQLQuery(query, parameters)
    end)
    if not success then
        print('Error: ' .. result)
    end
    TriggerClientEvent('codem-fishingjob:UpdateLevel', src, PlayerData.level, PlayerData.xp)
end

RegisterCommand(Config.Commands['setfishinglevel'], function(source, args)
    local src = source
    local isAdmin = CheckIfAdmin(src)
    if not isAdmin then
        Config.ServerNotify(src, SelectedLocalesData['error'], SelectedLocalesData['permission'])
    end
    local target = tonumber(args[1])
    local level = tonumber(args[2])
    if not target or not level then
        Config.ServerNotify(src, SelectedLocalesData['error'], SelectedLocalesData['invalidarguments'])
        return
    end
    local identifier = GetIdentifier(target)
    if not identifier then
        Config.ServerNotify(src, SelectedLocalesData['error'], SelectedLocalesData['playeridentifiernotfound'])
        return
    end
    local PlayerData = AllPlayerData[identifier]
    if not PlayerData then
        Config.ServerNotify(src, SelectedLocalesData['error'], SelectedLocalesData['playeridentifiernotfound'])
        return
    end
    PlayerData.level = level
    PlayerData.xp = 0
    local query = [[
         UPDATE codem_fishingjob_player SET level = ?, xp = ? WHERE identifier = ?
     ]]
    local parameters = { PlayerData.level, PlayerData.xp, identifier }
    local success, result = pcall(function()
        CodemSQLQuery(query, parameters)
    end)
    if not success then
        print('Error: ' .. result)
    end
    TriggerClientEvent('codem-fishingjob:UpdateLevel', target, PlayerData.level, PlayerData.xp)
end, false)


function CheckIfAdmin(source)
    local src = source
    local Player = GetPlayer(src)
    if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
        return CheckPermissions(Player.getGroup())
    elseif Config.Framework == 'oldqb' or Config.Framework == 'qb' then
        return CheckPermissions(source)
    elseif Config.Framework == 'qbox' then
        return CheckPermissions(source)
    end
    return false
end

function CheckPermissions(permission)
    if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
        for _, v in pairs(Config.AdminPermissions) do
            if v == permission then
                return true
            end
        end
        return false
    elseif Config.Framework == 'qb' or Config.Framework == 'oldqb' then
        for _, v in pairs(Config.AdminPermissions) do
            if Core.Functions.HasPermission(permission, v) or IsPlayerAceAllowed(permission, 'command') then
                return true
            end
        end
        return false
    elseif Config.Framework == 'qbox' then
        for _, v in pairs(Config.AdminPermissions) do
            if Core.Functions.HasPermission(permission, v) or IsPlayerAceAllowed(permission, 'command') then
                return true
            end
        end
        return false
    end
end
