Framework = Framework or {};

CreateThread(function()
    if Config.Framework ~= 'qbcore' then
        return
    end

    function Framework:getCore()
        return exports['qb-core']:GetCoreObject();
    end

    local QBCore = Framework:getCore();

    function Framework:fetchPlayer(source)
        return QBCore.Functions.GetPlayer(source)
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

        return character.PlayerData.citizenid or character.PlayerData.charinfo.citizenid
    end

    function Framework:getPlayerFullName(character)
        if not character or not character.PlayerData or not character.PlayerData.charinfo then
            return 'Unknown Player'
        end
        local info = character.PlayerData.charinfo
        local firstname = info.firstname or ''
        local lastname = info.lastname or ''
        local full = (firstname .. ' ' .. lastname):gsub('^%s+', ''):gsub('%s+$', '')
        return (#full > 0) and full or 'Unknown Player'
    end

    function Framework:getPlayerMoney(character, type)
        if not character then return 0 end

        if type == 'cash' or type == 'wallet' then
            return character.PlayerData.money.cash or 0
        elseif type == 'bank' then
            return character.PlayerData.money.bank or 0
        end

        return 0
    end

    function Framework:addPlayerMoney(character, type, amount)
        if not character then return false end

        if type == 'cash' or type == 'wallet' then
            return character.Functions.AddMoney('cash', amount)
        elseif type == 'bank' then
            return character.Functions.AddMoney('bank', amount)
        end

        return false
    end

    function Framework:removePlayerMoney(character, type, amount)
        if not character then return false end

        if type == 'cash' or type == 'wallet' then
            return character.Functions.RemoveMoney('cash', amount)
        elseif type == 'bank' then
            return character.Functions.RemoveMoney('bank', amount)
        end

        return false
    end

    function Framework:fetchOfflinePlayerName(identifier)
        local rows = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ?', { identifier })
        if not rows or not rows[1] or not rows[1].charinfo then
            return "Unknown Player"
        end
        local ok, data = pcall(function()
            return json.decode(rows[1].charinfo)
        end)
        if not ok or type(data) ~= 'table' then
            return "Unknown Player"
        end
        local firstname = data.firstname or ''
        local lastname = data.lastname or ''
        local full = (firstname .. ' ' .. lastname):gsub('^%s+', ''):gsub('%s+$', '')
        return (#full > 0) and full or "Unknown Player"
    end

    function Framework:isPlayerOnline(identifier)
        local players = QBCore.Functions.GetPlayers()
        for _, src in ipairs(players) do
            local player = QBCore.Functions.GetPlayer(src)
            if player and player.PlayerData and player.PlayerData.citizenid == identifier then
                return true
            end
        end
        return false
    end

    function Framework:fetchPlayerByIdentifier(identifier)
        local players = QBCore.Functions.GetPlayers()
        for _, src in ipairs(players) do
            local player = QBCore.Functions.GetPlayer(src)
            if player and player.PlayerData and player.PlayerData.citizenid == identifier then
                return player
            end
        end
        return nil
    end

    function Framework:getPlayerSource(character)
        if character and character.PlayerData then
            return character.PlayerData.source
        end
        return nil
    end

    function Framework:getPlayerJobData(character)
        if not character then return nil end
        local job = character.PlayerData and character.PlayerData.job or nil
        if not job then return nil end
        return {
            name = job.name,
            label = job.label or job.name,
            grade = (job.grade and (job.grade.level or job.grade)) or 0,
            gradeName = (job.grade and job.grade.name) or tostring(job.grade or ''),
            isBoss = (job.isboss == true) or (job.grade and (job.grade.name == 'boss'))
        }
    end
end)

-- Offline money helpers for QBCore (updates players table JSON)
function Framework:getOfflineMoney(identifier, moneyType)
    if not identifier then return 0 end
    moneyType = (moneyType == 'cash' or moneyType == 'wallet') and 'cash' or 'bank'

    local rows = MySQL.query.await('SELECT money FROM players WHERE citizenid = ? LIMIT 1', { identifier })
    if not rows or not rows[1] or not rows[1].money then return 0 end
    local ok, moneyObj = pcall(json.decode, rows[1].money)
    if not ok or type(moneyObj) ~= 'table' then return 0 end
    local val = tonumber(moneyObj[moneyType] or 0) or 0
    return val
end

function Framework:addOfflineMoney(identifier, moneyType, amount)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end
    moneyType = (moneyType == 'cash' or moneyType == 'wallet') and 'cash' or 'bank'
    local rows = MySQL.query.await('SELECT money FROM players WHERE citizenid = ? LIMIT 1', { identifier })
    if not rows or not rows[1] then return false end
    local moneyJson = rows[1].money
    local ok, moneyObj = pcall(json.decode, moneyJson or '{}')
    if not ok or type(moneyObj) ~= 'table' then moneyObj = {} end
    local current = tonumber(moneyObj[moneyType] or 0) or 0
    moneyObj[moneyType] = current + amount
    local newJson = json.encode(moneyObj)
    local affected = MySQL.update and MySQL.update.await and
        MySQL.update.await('UPDATE players SET money = ? WHERE citizenid = ?', { newJson, identifier }) or
        MySQL.query.await('UPDATE players SET money = ? WHERE citizenid = ?', { newJson, identifier })
    -- oxmysql returns affected rows count for update.await, ensure boolean
    if type(affected) == 'number' then
        return affected > 0
    end
    return affected and true or false
end

function Framework:removeOfflineMoney(identifier, moneyType, amount)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end
    moneyType = (moneyType == 'cash' or moneyType == 'wallet') and 'cash' or 'bank'
    local rows = MySQL.query.await('SELECT money FROM players WHERE citizenid = ? LIMIT 1', { identifier })
    if not rows or not rows[1] then return false end
    local moneyJson = rows[1].money
    local ok, moneyObj = pcall(json.decode, moneyJson or '{}')
    if not ok or type(moneyObj) ~= 'table' then moneyObj = {} end
    local current = tonumber(moneyObj[moneyType] or 0) or 0
    if current < amount then return false end
    moneyObj[moneyType] = current - amount
    local newJson = json.encode(moneyObj)
    local affected = MySQL.update and MySQL.update.await and
        MySQL.update.await('UPDATE players SET money = ? WHERE citizenid = ?', { newJson, identifier }) or
        MySQL.query.await('UPDATE players SET money = ? WHERE citizenid = ?', { newJson, identifier })
    if type(affected) == 'number' then
        return affected > 0
    end
    return affected and true or false
end