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


local callbackActions       
local createAccountName     
local saveProfileName       
local sendMessageName       

callbackActions = {}
createAccountName = "createAccount"
saveProfileName = "saveProfile"
sendMessageName = "sendMessage"

callbackActions[1] = createAccountName
callbackActions[2] = saveProfileName
callbackActions[3] = sendMessageName

function getMatchesOrMessages(isRecentMessages, page)
    local rawMatches
    local formattedMatches
    local i
    local rawMatch
    local match
    local value

    rawMatches = AwaitCallback("spark:getMatches", isRecentMessages, page)

    formattedMatches = {}

    for i = 1, #rawMatches, 1 do
        rawMatch = rawMatches[i]
        match = {}

        value = rawMatch.name
        match.name = value

        value = rawMatch.phone_number
        match.number = value

        value = json.decode(rawMatch.photos)
        match.photos = value

        value = rawMatch.dob
        match.dob = value

        value = rawMatch.bio
        match.bio = value

        value = rawMatch.is_male
        match.isMale = value

        value = rawMatch.latest_message_timestamp
        match.timestamp = value

        value = rawMatch.unread
        value = (true == value)
        match.unread = value

        value = rawMatch.latest_message
        if value then
            value = rawMatch.latest_message
            match.lastMessage = value

            value = rawMatch.latest_sender
            match.lastSender = value
        end

        formattedMatches[i] = match
    end

    return formattedMatches
end

RegisterNUICallback("Tinder", function(data, cb)
    local phone
    local action
    local logMessage
    local actionLogText
    local isCallbackAction
    local result
    local feed
    local i
    local rawEntry
    local formattedEntry
    local value
    local messages
    local attachments

    phone = currentPhone
    if not phone then
        return
    end

    action = data.action

    actionLogText = "Spark:"
    actionLogText = actionLogText .. (action or "")
    debugprint(actionLogText)

    isCallbackAction = table.contains(callbackActions, action)
    if isCallbackAction then
        if not CanInteract() then
            return cb(false)
        end
    end

    if "createAccount" == action then
        
        return TriggerCallback("spark:createAccount", cb, data.data)

    elseif "deleteAccount" == action then
        
        return TriggerCallback("spark:deleteAccount", cb)

    elseif "saveProfile" == action then
        
        return TriggerCallback("spark:updateAccount", cb, data.data)

    elseif "isLoggedIn" == action then
        
        result = AwaitCallback("spark:isLoggedIn", data.phoneNumber)
        return cb(result or false)

    elseif "getFeed" == action then
        
        feed = AwaitCallback("spark:getFeed", data.page)

        result = {}
        for i = 1, #feed, 1 do
            rawEntry = feed[i]
            formattedEntry = {}

            value = rawEntry.name
            formattedEntry.name = value

            value = rawEntry.dob
            formattedEntry.dob = value

            value = rawEntry.bio
            formattedEntry.bio = value

            value = json.decode(rawEntry.photos)
            formattedEntry.photos = value

            value = rawEntry.phone_number
            formattedEntry.number = value

            result[i] = formattedEntry
        end

        cb(result)

    elseif "swipe" == action then
        
        TriggerCallback("spark:swipe", cb, data.number, data.like)

    elseif "getNewMatchesCount" == action then
        
        TriggerCallback("spark:getNewMatchesCount", cb)

    elseif "getMatches" == action then
        
        return cb(getMatchesOrMessages(false, data.page))

    elseif "getRecentMessages" == action then
        
        return cb(getMatchesOrMessages(true, data.page))

    elseif "sendMessage" == action then
        
        data = data.data

        if "table" == type(data.attachments) then
            if 0 ~= #data.attachments then
                goto lbl_150
            end
        end
        data.attachments = nil
        ::lbl_150::

        attachments = data.attachments
        if attachments then
            attachments = data.attachments
        end

        TriggerCallback("spark:sendMessage", cb, data.recipient, data.content, attachments)

    elseif "getMessages" == action then
        
        messages = AwaitCallback("spark:getMessages", data.number, data.lastId)

        for i = 1, #messages, 1 do
            if messages[i].attachments then
                messages[i].attachments = json.decode(messages[i].attachments)
            else
                messages[i].attachments = {}
            end
        end

        cb(messages)

    elseif "markAsRead" == action then
        
        TriggerCallback("spark:markAsRead", cb, data.number)
    end
end)

RegisterNetEvent("phone:spark:newMessage", function(messageData)
    local attachments

    attachments = messageData.attachments
    if not attachments then
        attachments = {}
    end
    messageData.attachments = attachments

    SendNUIAction("tinder:newMessage", messageData)
end)
