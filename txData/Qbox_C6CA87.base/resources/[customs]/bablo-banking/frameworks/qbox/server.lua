Framework = Framework or {};

CreateThread(function()
    if Config.Framework ~= 'qbox' then
        return
    end

    local QBX = nil
    local hasNativeQbxExports = false
    local hasQbCoreCompat = false

    local function normalizePlayerList(players)
        local normalized = {}

        for source, player in pairs(players) do
            if type(player) == 'table' and player.PlayerData and player.PlayerData.source then
                normalized[#normalized + 1] = player.PlayerData.source
            elseif type(player) == 'table' and player.source then
                normalized[#normalized + 1] = player.source
            elseif type(player) == 'number' or type(player) == 'string' then
                normalized[#normalized + 1] = tonumber(player) or player
            else
                normalized[#normalized + 1] = tonumber(source) or source
            end
        end

        return normalized
    end

    local function getPlayersList()
        local success, players = pcall(function()
            return exports.qbx_core:GetQBPlayers()
        end)

        if success and type(players) == 'table' then
            return normalizePlayerList(players)
        end

        if hasQbCoreCompat and QBX and QBX.Functions and QBX.Functions.GetPlayers then
            success, players = pcall(function()
                return QBX.Functions.GetPlayers()
            end)

            if success and type(players) == 'table' then
                return normalizePlayerList(players)
            end
        end

        return nil
    end

    function Framework:getCore()
        if QBX or hasNativeQbxExports then return QBX end

        local success, result = pcall(function()
            return exports.qbx_core
        end)
        if success and result then
            hasNativeQbxExports = true
            Trace("^2[QBox Server] Using native qbx_core exports^0")
        end

        success, result = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if success and result then
            hasQbCoreCompat = true
            QBX = result
            Trace("^3[QBox Server] Using qb-core compatibility layer^0")
            return QBX
        end

        if hasNativeQbxExports then
            return nil
        end

        Trace("^1[QBox Server] Failed to get QBox/QBCore object^0")
        return nil
    end

    QBX = Framework:getCore()

    function Framework:fetchPlayer(source)
        if not source then return nil end

        if type(source) == 'table' and source.PlayerData then
            return source
        end

        source = tonumber(source) or source

        if hasNativeQbxExports then
            local success, player = pcall(function()
                return exports.qbx_core:GetPlayer(source)
            end)
            if success and player then
                return player
            end
        end

        if hasQbCoreCompat and QBX and QBX.Functions and QBX.Functions.GetPlayer then
            local success, player = pcall(function()
                return QBX.Functions.GetPlayer(source)
            end)
            if success and player then
                return player
            end
        end

        Trace("^1[QBox Server] Failed to fetch player for source: " .. tostring(source) .. "^0")
        return nil
    end

    function Framework:getCharacterIdentifier(character)
        if not character then
            Trace("^1[QBox Server] getCharacterIdentifier called with nil character^0")
            return nil
        end

        local playerData = character.PlayerData
        if not playerData then
            Trace("^1[QBox Server] Character has no PlayerData^0")
            return nil
        end

        local citizenid = playerData.citizenid
        if not citizenid and playerData.charinfo then
            citizenid = playerData.charinfo.citizenid
        end

        if not citizenid then
            Trace("^1[QBox Server] Could not find citizenid in PlayerData^0")
        end

        return citizenid
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
        if not identifier then return false end

        local player = Framework:fetchPlayerByIdentifier(identifier)
        return player ~= nil
    end

    function Framework:fetchPlayerByIdentifier(identifier)
        if not identifier then return nil end

        if hasNativeQbxExports then
            local success, player = pcall(function()
                return exports.qbx_core:GetPlayerByCitizenId(identifier)
            end)
            if success and player then
                return player
            end
        end

        if hasQbCoreCompat and QBX and QBX.Functions and QBX.Functions.GetPlayerByCitizenId then
            local success, player = pcall(function()
                return QBX.Functions.GetPlayerByCitizenId(identifier)
            end)
            if success and player then
                return player
            end
        end

        local players = getPlayersList()
        if not players then
            Trace("^1[QBox Server] Failed to get players list for identifier: " .. tostring(identifier) .. "^0")
            return nil
        end

        for _, src in ipairs(players) do
            local success, player = pcall(function()
                return Framework:fetchPlayer(src)
            end)
            if success and player then
                local playerCitizenid = player.PlayerData and player.PlayerData.citizenid
                if not playerCitizenid and player.PlayerData and player.PlayerData.charinfo then
                    playerCitizenid = player.PlayerData.charinfo.citizenid
                end
                if playerCitizenid == identifier then
                    return player
                end
            end
        end
        return nil
    end

    function Framework:getPlayerSource(character)
        if character and character.PlayerData then
            return character.PlayerData.source or character.source
        end
        return character and character.source or nil
    end

    function Framework:getPlayerJobData(character)
        if not character then return nil end

        local playerData = character.PlayerData
        if not playerData then return nil end

        local job = playerData.job
        if not job then return nil end

        local gradeLevel = 0
        local gradeName = ''
        local isBoss = false

        if job.grade then
            if type(job.grade) == 'table' then
                gradeLevel = job.grade.level or job.grade.grade or 0
                gradeName = job.grade.name or ''
            else
                gradeLevel = tonumber(job.grade) or 0
            end
        end

        isBoss = (job.isboss == true) or
            (job.isBoss == true) or
            (gradeName == 'boss') or
            (job.grade and type(job.grade) == 'table' and job.grade.isboss == true)

        return {
            name = job.name or 'unemployed',
            label = job.label or job.name or 'Unemployed',
            grade = gradeLevel,
            gradeName = gradeName,
            isBoss = isBoss
        }
    end

    -- Hooks fired when money is added/removed through AddMoney/RemoveMoney/AddMoneyByCard.
    -- info = { accountNumber, amount, description, isAtm, actorIdentifier, cardNumber, newBalance, isDefault, owner }
    function Framework:onDeposit(info)
    end

    function Framework:onWithdrawal(info)
    end
end)

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
