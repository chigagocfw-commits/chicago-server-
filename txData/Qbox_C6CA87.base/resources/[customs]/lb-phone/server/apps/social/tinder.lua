--[[
░▒▓████████▓▒░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░   ░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓███████▓▒░  
                                                                         
 This File Leaked By TC HUB Team, Join Our Server For More
 DISCORD: - https://discord.gg/k3S8RjkPWc - https://t.me/+RgDxwPX3L7w2ODBk - https://tchub.shop/
--]]


local accountCache = {}

local function GetOrFetchAccount(source, phoneNumber)
    
    local cached = accountCache[source]
    if cached and cached.phoneNumber == phoneNumber then
        return cached
    end

    local row = MySQL.single.await(
        "SELECT `name`, photos, bio, dob, is_male, interested_men, interested_women, `active` FROM phone_tinder_accounts WHERE phone_number = ?",
        { phoneNumber }
    )

    if not row then
        return nil
    end

    MySQL.update.await(
        "UPDATE phone_tinder_accounts SET last_seen = NOW() WHERE phone_number = ?",
        { phoneNumber }
    )

    accountCache[source] = {
        phoneNumber  = phoneNumber,
        name         = row.name,
        photos       = json.decode(row.photos),
        bio          = row.bio,
        dob          = row.dob,
        isMale       = row.is_male,
        showMen      = row.interested_men,
        showWomen    = row.interested_women,
        active       = row.active,
    }

    return accountCache[source]
end

local function RegisterAccountCallback(callbackName, handler, defaultReturn)
    BaseCallback("spark:" .. callbackName, function(source, phoneNumber, ...)
        
        local account = accountCache[source]
        if not account or account.phoneNumber ~= phoneNumber then
            return defaultReturn
        end

        return handler(source, phoneNumber, account, ...)
    end, defaultReturn)
end

BaseCallback("spark:createAccount", function(source, phoneNumber, accountData)
    
    local exists = MySQL.scalar.await(
        "SELECT TRUE FROM phone_tinder_accounts WHERE phone_number = ?",
        { phoneNumber }
    )
    if exists then
        return false
    end

    local rowsAffected = MySQL.update.await([[
        INSERT INTO phone_tinder_accounts
            (`name`, phone_number, photos, bio, dob, is_male, interested_men, interested_women)
        VALUES
            (@name, @phoneNumber, @photos, @bio, @dob, @isMale, @showMen, @showWomen)
    ]], {
        name        = accountData.name,
        phoneNumber = phoneNumber,
        photos      = json.encode(accountData.photos),
        bio         = accountData.bio,
        dob         = accountData.dob,
        isMale      = accountData.isMale,
        showMen     = accountData.showMen,
        showWomen   = accountData.showWomen,
    })

    local success = rowsAffected > 0

    accountCache[source] = {
        name        = accountData.name,
        phoneNumber = phoneNumber,
        photos      = accountData.photos,
        bio         = accountData.bio,
        dob         = accountData.dob,
        isMale      = accountData.isMale,
        showMen     = accountData.showMen,
        showWomen   = accountData.showWomen,
        active      = true,
    }

    return success
end, false)

BaseCallback("spark:deleteAccount", function(source, phoneNumber)
    
    if not Config.DeleteAccount or not Config.DeleteAccount.Spark then
        infoprint("warning", ("%%s tried to delete their spark account, but it's not enabled in the config."):format(source))
        return false
    end

    local rowsAffected = MySQL.update.await(
        "DELETE FROM phone_tinder_accounts WHERE phone_number = ?",
        { phoneNumber }
    )

    if rowsAffected <= 0 then
        return false
    end

    MySQL.update(
        "DELETE FROM phone_tinder_swipes WHERE swiper = ? OR swipee = ?",
        { phoneNumber, phoneNumber }
    )

    MySQL.update(
        "DELETE FROM phone_tinder_matches WHERE phone_number_1 = ? OR phone_number_2 = ?",
        { phoneNumber, phoneNumber }
    )

    MySQL.update(
        "DELETE FROM phone_tinder_messages WHERE sender = ? OR recipient = ?",
        { phoneNumber, phoneNumber }
    )

    return true
end)

RegisterAccountCallback("updateAccount", function(source, phoneNumber, account, updates)
    
    for key in pairs(account) do
        if updates[key] ~= nil then
            account[key] = updates[key]
        end
    end

    local rowsAffected = MySQL.update.await([[
        UPDATE phone_tinder_accounts
        SET
            `name`=@name,
            photos=@photos,
            bio=@bio,
            is_male=@isMale,
            interested_men=@showMen,
            interested_women=@showWomen,
            `active`=@active
        WHERE phone_number=@phoneNumber
    ]], {
        name        = updates.name,
        photos      = json.encode(updates.photos),
        bio         = updates.bio,
        isMale      = updates.isMale,
        showMen     = updates.showMen,
        showWomen   = updates.showWomen,
        active      = updates.active,
        phoneNumber = phoneNumber,
    })

    return rowsAffected > 0
end, false)

BaseCallback("spark:isLoggedIn", function(source, phoneNumber)
    return GetOrFetchAccount(source, phoneNumber)
end, false)

BaseCallback("spark:getFeed", function(source, phoneNumber, pageIndex)
    local page = (pageIndex or 0) * 10

    return MySQL.query.await([[
        SELECT
            a.`name`, a.phone_number, a.photos, a.bio, a.dob
        FROM
            phone_tinder_accounts a

        JOIN
            phone_tinder_accounts b
        ON
            b.phone_number = @phoneNumber

        WHERE
            a.phone_number != @phoneNumber
            AND a.`active` = 1
            AND (a.is_male = b.interested_men OR a.is_male=(NOT b.interested_women))
            AND (a.interested_men=b.is_male OR a.interested_women=(NOT b.is_male))
            AND NOT EXISTS (SELECT TRUE FROM phone_tinder_swipes WHERE swiper = @phoneNumber AND swipee = a.phone_number)

        ORDER BY a.phone_number

        LIMIT @page, @perPage
    ]], {
        phoneNumber = phoneNumber,
        page        = page,
        perPage     = 10,
    })
end, {})

RegisterAccountCallback("swipe", function(source, phoneNumber, account, targetNumber, liked)
    
    local result = MySQL.query.await(
        "INSERT INTO phone_tinder_swipes (swiper, swipee, liked) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE liked = ?",
        { phoneNumber, targetNumber, liked, liked }
    )

    if result == 0 or not liked then
        return false
    end

    local theyLikedUs = MySQL.scalar.await(
        "SELECT liked FROM phone_tinder_swipes WHERE swiper = ? AND swipee = ?",
        { targetNumber, phoneNumber }
    )

    theyLikedUs = (theyLikedUs == true)

    if not theyLikedUs then
        return false
    end

    local matchExists = MySQL.scalar.await([[
        SELECT TRUE
        FROM phone_tinder_matches
        WHERE
            (phone_number_1 = @phoneNumber AND phone_number_2 = @number)
            OR (phone_number_2 = @phoneNumber AND phone_number_1 = @number)
    ]], {
        phoneNumber = phoneNumber,
        number      = targetNumber,
    })

    if not matchExists then
        
        MySQL.update.await(
            "INSERT INTO phone_tinder_matches (phone_number_1, phone_number_2) VALUES (?, ?)",
            { phoneNumber, targetNumber }
        )

        SendNotification(targetNumber, {
            app       = "Tinder",
            title     = L("BACKEND.TINDER.NEW_MATCH"),
            content   = L("BACKEND.TINDER.MATCHED_WITH", { name = account.name }),
            thumbnail = account.photos[1],
        })
    end

    return true
end)

BaseCallback("spark:getNewMatchesCount", function(source, phoneNumber)
    local count = MySQL.scalar.await([[
        SELECT COUNT(*) FROM phone_tinder_matches
        WHERE
            (
                (phone_number_1 = @phoneNumber)
                OR (phone_number_2 = @phoneNumber)
            )
            AND latest_message IS NULL
    ]], { phoneNumber = phoneNumber })

    return count or 0
end)

BaseCallback("spark:getMatches", function(source, phoneNumber, withMessages, pageIndex)
    
    local messagesClause = withMessages and "IS NOT NULL" or "IS NULL"

    local query = ([[
        SELECT
            `account`.`name`,
            `account`.phone_number,
            `account`.photos,
            `account`.dob,
            `account`.bio,
            `account`.is_male,

            `match`.latest_sender,
            `match`.latest_message,
            `match`.latest_message_timestamp,

            CASE
                WHEN `match`.phone_number_1 = @phoneNumber THEN `match`.phone_number_1_has_unread
                ELSE `match`.phone_number_2_has_unread
            END as unread
        FROM
            phone_tinder_accounts `account`

        JOIN
            phone_tinder_matches `match`
        ON
            (
                `match`.phone_number_1 = @phoneNumber
                AND `match`.phone_number_2 = `account`.phone_number
            )
            OR
            (
                `match`.phone_number_2 = @phoneNumber
                AND `match`.phone_number_1 = `account`.phone_number
            )

        WHERE latest_message {MESSAGES}

        ORDER BY `match`.latest_message_timestamp DESC

        LIMIT @page, @perPage
    ]]):gsub("{MESSAGES}", messagesClause)

    local page = (pageIndex or 0) * 25

    return MySQL.query.await(query, {
        phoneNumber = phoneNumber,
        page        = page,
        perPage     = 25,
    })
end)

RegisterAccountCallback("sendMessage", function(source, phoneNumber, account, recipientNumber, content, attachments)
    
    if ContainsBlacklistedWord(source, "Spark", content) then
        return false
    end

    local messageId = MySQL.insert.await(
        "INSERT INTO phone_tinder_messages (sender, recipient, content, attachments) VALUES (?, ?, ?, ?)",
        { phoneNumber, recipientNumber, content, json.encode(attachments) }
    )

    if not messageId then
        return false
    end

    MySQL.update([[
        UPDATE
            phone_tinder_matches
        SET
            latest_message = @content,
            latest_sender = @sender,
            latest_message_timestamp = CURRENT_TIMESTAMP,
            phone_number_1_has_unread = CASE WHEN phone_number_1 = @recipient THEN 1 ELSE 0 END,
            phone_number_2_has_unread = CASE WHEN phone_number_2 = @recipient THEN 1 ELSE 0 END
        WHERE
            (phone_number_1 = @sender AND phone_number_2 = @recipient)
            OR (phone_number_2 = @sender AND phone_number_1 = @recipient)
    ]], {
        content   = content,
        sender    = phoneNumber,
        recipient = recipientNumber,
    })

    local recipientSource = GetSourceFromNumber(recipientNumber)
    if recipientSource then
        TriggerClientEvent("phone:spark:newMessage", recipientSource, {
            sender      = phoneNumber,
            recipient   = recipientNumber,
            content     = content,
            attachments = attachments,
            timestamp   = os.time() * 1000,  
        })
    end

    SendNotification(recipientNumber, {
        app       = "Tinder",
        title     = account.name,
        content   = content,
        thumbnail = attachments and attachments[1] or nil,
        avatar    = account.photos[1],
        showAvatar = true,
    })

    return messageId
end)

BaseCallback("spark:getMessages", function(source, phoneNumber, otherNumber, lastId)
    
    if not lastId then
        MySQL.update([[
            UPDATE
                phone_tinder_matches
            SET
                phone_number_1_has_unread = CASE WHEN phone_number_1 = @phoneNumber THEN 0 ELSE phone_number_1_has_unread END,
                phone_number_2_has_unread = CASE WHEN phone_number_2 = @phoneNumber THEN 0 ELSE phone_number_2_has_unread END
            WHERE
                (phone_number_1 = @phoneNumber AND phone_number_2 = @number)
                OR (phone_number_2 = @phoneNumber AND phone_number_1 = @number)
        ]], {
            phoneNumber = phoneNumber,
            number      = otherNumber,
        })
    end

    local paginationClause = lastId and "AND id < @lastId" or ""

    local query = ([[
        SELECT
            id,
            sender,
            recipient,
            content,
            attachments,
            timestamp
        FROM
            phone_tinder_messages
        WHERE
            (
                (sender = @phoneNumber AND recipient = @number)
                OR (recipient = @phoneNumber AND sender = @number)
            ) {PAGINATION}
        ORDER BY id DESC
        LIMIT 25
    ]]):gsub("{PAGINATION}", paginationClause)

    return MySQL.query.await(query, {
        phoneNumber = phoneNumber,
        number      = otherNumber,
        lastId      = lastId,
    })
end)

BaseCallback("spark:markAsRead", function(source, phoneNumber, otherNumber)
    MySQL.update([[
        UPDATE
            phone_tinder_matches
        SET
            phone_number_1_has_unread = CASE WHEN phone_number_1 = @phoneNumber THEN 0 ELSE phone_number_1_has_unread END,
            phone_number_2_has_unread = CASE WHEN phone_number_2 = @phoneNumber THEN 0 ELSE phone_number_2_has_unread END
        WHERE
            (phone_number_1 = @phoneNumber AND phone_number_2 = @number)
            OR (phone_number_2 = @phoneNumber AND phone_number_1 = @number)
    ]], {
        phoneNumber = phoneNumber,
        number      = otherNumber,
    })
end)

CreateThread(function()
    if not Config.AutoDisableSparkAccounts then
        return
    end

    local intervalMs  = 3600000  
    local inactiveDays = 7        

    if type(Config.AutoDisableSparkAccounts) == "number" then
        inactiveDays = math.max(Config.AutoDisableSparkAccounts, 1)
    end

    while true do
        if DatabaseCheckerFinished then
            break
        end
        Wait(500)
    end

    while true do
        MySQL.update(
            "UPDATE phone_tinder_accounts SET active = 0 WHERE active = 1 AND last_seen < NOW() - INTERVAL ? DAY",
            { inactiveDays },
            function(rowsDisabled)
                debugprint("Disabled " .. rowsDisabled .. " inactive Spark accounts.")
            end
        )

        Wait(intervalMs)
    end
end)

AddEventHandler("playerDropped", function()
    local playerSource = source
    accountCache[playerSource] = nil
end)

