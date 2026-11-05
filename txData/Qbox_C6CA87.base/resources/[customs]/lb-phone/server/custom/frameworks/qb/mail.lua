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

if Config.Framework ~= "qb" then
    return
end

if not Config.QBMailEvent then
    return
end

while not QB do
    Wait(500)
    debugprint("Mail: Waiting for QB to load")
end

local function SendQBMail(phoneNumber, data)
    if not phoneNumber then
        return
    end

    local address = exports["lb-phone"]:GetEmailAddress(phoneNumber)

    if not address then
        return
    end

    local actions
    if data.button?.enabled then
        actions = {
            {
                label = "button",
                data = {
                    event = data.button.buttonEvent,
                    isServer = false,
                    data = {
                        qbMail = true,
                        data = data.button.buttonData
                    }
                }
            }
        }
    end

    exports["lb-phone"]:SendMail({
        to = address,
        sender = data.sender,
        subject = data.subject,
        message = data.message,
        actions = actions
    })
end

RegisterNetEvent("qb-phone:server:sendNewMail", function(data)
    local phoneNumber = GetEquippedPhoneNumber(source)

    SendQBMail(phoneNumber, data)
end)

RegisterNetEvent("qb-phone:server:sendNewMailToOffline", function(citizenid, data)
    local phoneNumber = GetEquippedPhoneNumber(citizenid)

    SendQBMail(phoneNumber, data)
end)

AddEventHandler("__cfx_export_qb-phone_sendNewMailToOffline", function(citizenid, data)
    local phoneNumber = GetEquippedPhoneNumber(citizenid)

    SendQBMail(phoneNumber, data)
end)

