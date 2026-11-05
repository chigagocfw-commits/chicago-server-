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

    -- Hooks fired when money is added/removed through AddMoney/RemoveMoney/AddMoneyByCard.
    -- info = { accountNumber, amount, description, isAtm, actorIdentifier, cardNumber, newBalance, isDefault, owner }
    function Framework:onDeposit(info)
    end

    function Framework:onWithdrawal(info)
    end

    function Framework:getCharacterIdentifier(character)
        if not character then
            return nil
        end

        return character.identifier
    end

    -- Player helpers (ESX implementations mirroring QBCore API used elsewhere)

    -- Returns full name for an online xPlayer
    function Framework:getPlayerFullName(character)
        if not character then return 'Unknown Player' end
        local fullname = nil
        if character.getName then
            fullname = character:getName()
        end
        if (not fullname) or fullname == '' then
            local first, last = nil, nil
            if character.get then
                pcall(function()
                    first = character:get('firstName') or character:get('firstname')
                    last = character:get('lastName') or character:get('lastname')
                end)
            end
            first = first or ''
            last = last or ''
            fullname = (tostring(first) .. ' ' .. tostring(last)):gsub('^%s+', ''):gsub('%s+$', '')
        end
        return (fullname and #fullname > 0) and fullname or 'Unknown Player'
    end

    function Framework:getPlayerMoney(character, type)
        if not character then return 0 end
        if type == 'cash' or type == 'wallet' then
            if character.getMoney then
                return tonumber(character.getMoney()) or 0
            end
            return 0
        elseif type == 'bank' then
            local acc = character.getAccount and character.getAccount('bank') or nil
            return tonumber(acc and acc.money or 0) or 0
        end
        return 0
    end

    function Framework:addPlayerMoney(character, type, amount)
        if not character then return false end
        amount = tonumber(amount) or 0
        if amount <= 0 then return false end
        if type == 'cash' or type == 'wallet' then
            if character.addMoney then
                character.addMoney(amount)
                return true
            end
        elseif type == 'bank' then
            if character.addAccountMoney then
                character.addAccountMoney('bank', amount)
                return true
            end
        end
        return false
    end

    function Framework:removePlayerMoney(character, type, amount)
        if not character then return false end
        amount = tonumber(amount) or 0
        if amount <= 0 then return false end
        if type == 'cash' or type == 'wallet' then
            if character.removeMoney then
                character.removeMoney(amount)
                return true
            end
        elseif type == 'bank' then
            if character.removeAccountMoney then
                character.removeAccountMoney('bank', amount)
                return true
            end
        end
        return false
    end

    function Framework:fetchOfflinePlayerName(identifier)
        if not identifier then return 'Unknown Player' end

        local success, rows = pcall(function()
            return MySQL.query.await('SELECT firstname, lastname, name FROM users WHERE identifier = ? LIMIT 1',
                { identifier })
        end)

        if not success or not rows or not rows[1] then
            rows = MySQL.query.await('SELECT firstname, lastname FROM users WHERE identifier = ? LIMIT 1',
                { identifier })
        end

        if not rows or not rows[1] then return 'Unknown Player' end
        local firstname = rows[1].firstname or ''
        local lastname = rows[1].lastname or ''
        local full = (tostring(firstname) .. ' ' .. tostring(lastname)):gsub('^%s+', ''):gsub('%s+$', '')
        if #full == 0 and rows[1].name then
            full = rows[1].name or ''
            full = tostring(full):gsub('^%s+', ''):gsub('%s+$', '')
        end
        return (#full > 0) and full or 'Unknown Player'
    end

    function Framework:isPlayerOnline(identifier)
        if not identifier then return false end
        if ESX.GetPlayerFromIdentifier then
            local xp = ESX.GetPlayerFromIdentifier(identifier)
            return xp ~= nil
        end
        if ESX.GetExtendedPlayers then
            for _, xPlayer in pairs(ESX.GetExtendedPlayers()) do
                if xPlayer and xPlayer.identifier == identifier then
                    return true
                end
            end
        else
            local players = ESX.GetPlayers and ESX.GetPlayers() or {}
            for _, src in ipairs(players) do
                local xPlayer = ESX.GetPlayerFromId(src)
                if xPlayer and xPlayer.identifier == identifier then
                    return true
                end
            end
        end
        return false
    end

    function Framework:fetchPlayerByIdentifier(identifier)
        if not identifier then return nil end
        if ESX.GetPlayerFromIdentifier then
            return ESX.GetPlayerFromIdentifier(identifier)
        end
        if ESX.GetExtendedPlayers then
            for _, xPlayer in pairs(ESX.GetExtendedPlayers()) do
                if xPlayer and xPlayer.identifier == identifier then
                    return xPlayer
                end
            end
        else
            local players = ESX.GetPlayers and ESX.GetPlayers() or {}
            for _, src in ipairs(players) do
                local xPlayer = ESX.GetPlayerFromId(src)
                if xPlayer and xPlayer.identifier == identifier then
                    return xPlayer
                end
            end
        end
        return nil
    end

    function Framework:getPlayerSource(character)
        if character and character.source then
            return character.source
        end
        return nil
    end

    function Framework:getPlayerJobData(character)
        if not character then return nil end
        local job = character.job or (character.getJob and character.getJob(character)) or nil
        if not job then return nil end
        return {
            name = job.name,
            label = job.label or job.name,
            grade = tonumber(job.grade or 0) or 0,
            gradeName = tostring(job.grade_name or job.gradeLabel or ''),
            isBoss = (tostring(job.grade_name or '') == 'boss')
        }
    end

    -- Offline money helpers for ESX (users table money/accounts JSON)
    function Framework:getOfflineMoney(identifier, moneyType)
        if not identifier then return 0 end
        local rows = MySQL.query.await('SELECT accounts FROM users WHERE identifier = ? LIMIT 1', { identifier })
        if not rows or not rows[1] then return 0 end
        local ok, acc = pcall(json.decode, rows[1].accounts or '{}')
        if not ok or type(acc) ~= 'table' then acc = {} end
        local key = (moneyType == 'cash' or moneyType == 'wallet') and 'money' or 'bank'
        return tonumber(acc[key] or 0) or 0
    end

    function Framework:addOfflineMoney(identifier, moneyType, amount)
        amount = tonumber(amount) or 0
        if not identifier or amount <= 0 then return false end
        local rows = MySQL.query.await('SELECT accounts FROM users WHERE identifier = ? LIMIT 1', { identifier })
        if not rows or not rows[1] then return false end
        local ok, acc = pcall(json.decode, rows[1].accounts or '{}')
        if not ok or type(acc) ~= 'table' then acc = {} end
        local key = (moneyType == 'cash' or moneyType == 'wallet') and 'money' or 'bank'
        local current = tonumber(acc[key] or 0) or 0
        acc[key] = current + amount
        local newJson = json.encode(acc)
        local affected = (MySQL.update and MySQL.update.await and MySQL.update.await('UPDATE users SET accounts = ? WHERE identifier = ?', { newJson, identifier }))
            or MySQL.query.await('UPDATE users SET accounts = ? WHERE identifier = ?', { newJson, identifier })
        if type(affected) == 'number' then return affected > 0 end
        return affected and true or false
    end

    function Framework:removeOfflineMoney(identifier, moneyType, amount)
        amount = tonumber(amount) or 0
        if not identifier or amount <= 0 then return false end
        local rows = MySQL.query.await('SELECT accounts FROM users WHERE identifier = ? LIMIT 1', { identifier })
        if not rows or not rows[1] then return false end
        local ok, acc = pcall(json.decode, rows[1].accounts or '{}')
        if not ok or type(acc) ~= 'table' then acc = {} end
        local key = (moneyType == 'cash' or moneyType == 'wallet') and 'money' or 'bank'
        local current = tonumber(acc[key] or 0) or 0
        if current < amount then return false end
        acc[key] = current - amount
        local newJson = json.encode(acc)
        local affected = (MySQL.update and MySQL.update.await and MySQL.update.await('UPDATE users SET accounts = ? WHERE identifier = ?', { newJson, identifier }))
            or MySQL.query.await('UPDATE users SET accounts = ? WHERE identifier = ?', { newJson, identifier })
        if type(affected) == 'number' then return affected > 0 end
        return affected and true or false
    end
end)