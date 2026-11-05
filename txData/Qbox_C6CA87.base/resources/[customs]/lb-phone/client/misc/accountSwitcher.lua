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

local switchableApps = {
    Twitter = true,
    Instagram = true,
    TikTok = true,
    Mail = true,
    DarkChat = true
}

RegisterNUICallback("AccountSwitcher", function(data, callback)
    debugprint("AccountSwitcher:" .. (data.action or ""))

    if not currentPhone or not switchableApps[data.app] then
        debugprint("AccountSwitcher: Invalid app / no currentPhone", data.app)
        return callback(false)
    end

    if data.action == "switch" then
        TriggerCallback("accountSwitcher:switchAccount", callback, data.app, data.account)
    elseif data.action == "getAccounts" then
        TriggerCallback("accountSwitcher:getAccounts", function(accounts)
            if not accounts then
                return callback(false)
            end

            local usernames = {}

            for i = 1, #accounts do
                usernames[i] = accounts[i].username
            end

            callback(usernames)
        end, data.app)
    end
end)

RegisterNetEvent("phone:logoutFromApp", function(data)
    debugprint("logoutFromApp:", data)

    if data.number and data.number == currentPhone then
        return debugprint("Ignoring logoutFromApp event since number matches")
    end

    local action = data.app .. ":logout"

    debugprint(action, data.username)
    SendNUIAction(action, data.username)
end)

