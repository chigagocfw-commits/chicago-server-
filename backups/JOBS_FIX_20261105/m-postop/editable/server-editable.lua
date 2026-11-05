bot_Token = "YOUR_BOT_TOKEN"


Citizen.CreateThread(function()
    while frameworkObject == nil do Citizen.Wait(100) end
    if CDM.Config.Framework == "new-qb" or CDM.Config.Framework == "old-qb" then
        frameworkObject.Functions.CreateUseableItem(CDM.Config.VehicleItem, function(source)
            TriggerClientEvent("m-postop-client:SetVehicleItem", source)
        end)
    else
        frameworkObject.RegisterUsableItem(CDM.Config.VehicleItem, function()
            TriggerClientEvent("m-postop-client:SetVehicleItem", source)
        end)
    end
    if CDM.Config.FinishJobCommand.enable then
        RegisterCommand(CDM.Config.FinishJobCommand.command, function(source)
            if not source then return end
            local Player = CDM.GetPlayer(source)
            if CDM.Config.Framework == "new-qb" or CDM.Config.Framework == "old-qb" then
                if CDM.Config.FinishJobCommand.DeleteVehicleAfterUsage then
                    TriggerClientEvent("m-postop-client:DeleteJobVehicle", source)
                end
                Citizen.Wait(100)
                CDM.FinishJobWithCommand(Player.PlayerData.citizenid, source)
            else
                if CDM.Config.FinishJobCommand.DeleteVehicleAfterUsage then
                    TriggerClientEvent("m-postop-client:DeleteJobVehicle", source)
                end
                Citizen.Wait(100)
                CDM.FinishJobWithCommand(Player.identifier, source)
            end
        end)
    end
end)


CDM.Inventory = {}


CDM.Inventory.AddMoney = function(source, money)
    if not source then return print("unknown source") end
    money = tonumber(money)
    local Player = CDM.GetPlayer(source)
    if (CDM.Config.Inventory == "qb-inventory") then
        if (CDM.Config.Framework == "qb" or CDM.Config.Framework == "new-qb") then
            local ok = Player.Functions.AddMoney(CDM.Config.MoneyType, money, 'postop')
            if CDM.Config.MoneyType == 'bank' and ok then
                TriggerEvent('job_payment_email:send', source, money, 'payment')
            end
            -- notification
        else
            -- your qb to esx converted qb-inventory codes
        end
    elseif (CDM.Config.Inventory == "ox_inventory") then
        if CDM.Config.MoneyType == "cash" then
            exports.ox_inventory:AddItem(source, CDM.Config.OXInventoryCashItem, money)
            else
                if CDM.Config.Framework == "qb" or CDM.Config.Framework == "new-qb" then
                Player.Functions.AddMoney("bank", money, 'postop')
            else
                Player.addAccountMoney('bank', money)
                TriggerEvent('job_payment_email:send', source, money, 'payment')
            end
        end
    elseif (CDM.Config.Inventory == "esx_default") then
        if CDM.Config.MoneyType == "cash" then
            Player.addMoney(money)
        else
            Player.addAccountMoney('bank', money)
            TriggerEvent('job_payment_email:send', source, money, 'payment')
        end
    elseif CDM.Config.Inventory == "custom" then
        -- return  //your custom inv codes
    end
    CDM.SetEarnedMoney(source, money)
    CDM.SendMessage(CDM.Messages["server"]["earnmoney"] .. " " .. money .. "$", false, "server", source)
end


CDM.Inventory.GetMoney = function(source)
    if not source then return print("unknown source") end
    local Player = CDM.GetPlayer(source)
    if (CDM.Config.Inventory == "qb-inventory") then
        if (CDM.Config.Framework == "qb" or CDM.Config.Framework == "new-qb") then
            return Player.Functions.GetMoney(CDM.Config.MoneyType)
        else
            -- your qb to esx converted qb-inventory codes
        end
    elseif CDM.Config.Inventory == "ox_inventory" then
        if CDM.Config.MoneyType == "cash" then
            local inventory = exports.ox_inventory:GetInventory(source)
            local cash = 0
            for itemkey, item in pairs(inventory.items) do
                if item.name == CDM.Config.OXInventoryCashItem then
                    cash = cash + item.count
                end
            end
            return cash
        else
            if CDM.Config.Framework == "qb" or CDM.Config.Framework == "qb-old" then
                return Player.Functions.GetMoney(CDM.Config.MoneyType)
            else
                return Player.getAccount('bank').money
            end
        end
    elseif CDM.Config.Inventory == "esx_default" then
        if CDM.Config.Framework == "esx" or CDM.Config.Framework == "new-esx" then
            if CDM.Config.MoneyType == "bank" then
                return Player.getAccount('bank').money
            elseif CDM.Config.MoneyType == "cash" then
                return Player.getMoney()
            end
        end
    elseif CDM.Config.Inventory == "custom" then
        -- your custom inv codes
    end
end


CDM.Inventory.RemoveMoney = function(source, money)
    if not source then return print("unknown source") end
    money = tonumber(money)
    local Player = CDM.GetPlayer(source)
    if (CDM.Config.Inventory == "qb-inventory") then
        if (CDM.Config.Framework == "qb" or CDM.Config.Framework == "new-qb") then
            if Player.Functions.RemoveMoney(CDM.Config.MoneyType, money, 'postop-remove') then
                return true
            else
                return false
            end
        else
            -- your qb to esx converted qb-inventory codes
        end
    elseif (CDM.Config.Inventory == "ox_inventory") then
        local PlayerMoney = CDM.Inventory.GetMoney(source)
        if CDM.Config.MoneyType == "cash" then
            if PlayerMoney >= money then
                exports.ox_inventory:RemoveItem(source, CDM.Config.OXInventoryCashItem, money)
                return true
            else
                return false
            end
        else
            if CDM.Config.Framework == "qb" or CDM.Config.Framework == "new-qb" then
                if CDM.Inventory.GetMoney(source) >= money then
                    Player.Functions.RemoveMoney(CDM.Config.MoneyType, money)
                    return true
                else
                    return false
                end
            else
                if CDM.Inventory.GetMoney(source) >= money then
                    Player.removeAccountMoney('bank', money)
                    return true
                else
                    return false
                end
            end
        end
    elseif (CDM.Config.Inventory == "esx_default") then
        if CDM.Config.MoneyType == "cash" then
            if CDM.Inventory.GetMoney(source) >= money then
                Player.removeMoney(money)
                return true
            else
                return false
            end
        else
            if Player.getAccount('bank').money >= money then
                Player.removeAccountMoney('bank', money)
                return true
            else
                return false
            end
        end
    elseif (CDM.Config.Inventory == "custom") then
        --return // your custom inv codes
    end
end


CDM.GetPlayer = function(source)
    if not source then return print("error while finding player") end
    if CDM.Config.Framework == "new-qb" or CDM.Config.Framework == "old-qb" then
        return frameworkObject.Functions.GetPlayer(source)
    else
        return frameworkObject.GetPlayerFromId(source)
    end
end

CDM.GetPlayerCharacterNameESX = function(source)
    local Player = CDM.GetPlayer(source)
    identifier = Player.identifier
    local result = CDM.ExecuteSql("SELECT * FROM users WHERE identifier = '" .. identifier .. "'")
    if result[1] then
        return result[1].firstname .. ' ' .. result[1].lastname
    end;
end

CDM.GetPlayerJob = function(source)
    if not source then return print("error while finding player") end
    local Player = CDM.GetPlayer(source)
    if CDM.Config.Framework == "new-qb" or CDM.Config.Framework == "old-qb" then
        return Player.PlayerData.job.name
    else
        return Player.job.name
    end
end

Citizen.CreateThread(function()
    local resource_name = 'codem-postop'
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
end)
