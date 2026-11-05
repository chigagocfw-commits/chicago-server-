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

BaseCallback("clock:getAlarms", function(source, phoneNumber)
    return MySQL.query.await(
        "SELECT id, hours, minutes, label, enabled FROM phone_clock_alarms WHERE phone_number = ?",
        { phoneNumber }
    )
end, {})

BaseCallback("clock:createAlarm", function(source, phoneNumber, label, hours, minutes)
    return MySQL.insert.await(
        "INSERT INTO phone_clock_alarms (phone_number, hours, minutes, label) VALUES (@phoneNumber, @hours, @minutes, @label)",
        {
            ["@phoneNumber"] = phoneNumber,
            ["@hours"] = hours,
            ["@minutes"] = minutes,
            ["@label"] = label
        }
    )
end)

BaseCallback("clock:deleteAlarm", function(source, phoneNumber, alarmId)
    local affectedRows = MySQL.update.await(
        "DELETE FROM phone_clock_alarms WHERE id = ? AND phone_number = ?",
        { alarmId, phoneNumber }
    )

    return affectedRows > 0
end)

BaseCallback("clock:toggleAlarm", function(source, phoneNumber, alarmId, enabled)
    MySQL.update.await(
        "UPDATE phone_clock_alarms SET enabled = ? WHERE id = ? AND phone_number = ?",
        { enabled == true, alarmId, phoneNumber }
    )

    return enabled
end)

BaseCallback("clock:updateAlarm", function(source, phoneNumber, alarmId, label, hours, minutes)
    local affectedRows = MySQL.update.await(
        "UPDATE phone_clock_alarms SET label = ?, hours = ?, minutes = ? WHERE id = ? AND phone_number = ?",
        { label, hours, minutes, alarmId, phoneNumber }
    )

    return affectedRows > 0
end)

