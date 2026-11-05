local alertCode = 0
local heatMapAlerts = {}
local alertCooldowns = {}

-- Initialize heat map from database
if Config.HeatMapAlerts then
    Citizen.CreateThread(function()
        -- Clean up old alerts (keep only last 100)
        local result = MySQL.awaitQuery("SELECT COUNT(*) as count FROM origen_police_alerts")
        local count = result[1].count
        
        if count > 100 then
            local toDelete = count - 100
            local oldAlerts = MySQL.awaitQuery("SELECT id FROM origen_police_alerts ORDER BY id ASC LIMIT ?", { toDelete })
            
            if #oldAlerts > 0 then
                local ids = {}
                for _, alert in ipairs(oldAlerts) do
                    table.insert(ids, alert.id)
                end
                
                local idList = table.concat(ids, ",")
                MySQL.awaitRawExec("DELETE FROM origen_police_alerts WHERE id IN (" .. idList .. ")")
            end
        end
        
        -- Load existing alerts
        local alerts = MySQL.awaitQuery("SELECT x, y, job FROM origen_police_alerts")
        
        for i = 1, #alerts do
            local job = alerts[i].job
            heatMapAlerts[job] = heatMapAlerts[job] or {}
            
            table.insert(heatMapAlerts[job], {
                x = alerts[i].x,
                y = alerts[i].y
            })
        end
    end)
end

-- Register custom command alerts
for command, config in pairs(Config.Commands.CustomCommandAlert) do
    RegisterCommand(command, function(source, args, rawCommand)
        local playerId = source
        local message = args[1]
        
        if not message then
            TriggerClientEvent(
                "origen_police:ShowNotification",
                playerId,
                Config.Translations.CantSendEmpty .. " /" .. command
            )
            return
        end
        
        SendAlert({
            job = config.jobCategory,
            message = table.concat(args, " "),
            coords = GetEntityCoords(GetPlayerPed(playerId)),
            type = "GENERALES",
            title = Config.Translations.Call911,
            playerID = playerId
        })
        
        -- Log the alert
        CreateLog({
            type = "DispatchAlerts",
            embed = {
                title = Config.LogsTranslations.Alert.title,
                description = string.format(Config.LogsTranslations.Alert.message, command, table.concat(args, " ")),
                color = 1791423
            },
            source = playerId
        })
        
        -- Trigger custom event if configured
        if config.triggerEvent then
            TriggerClientEvent(config.triggerEvent, playerId, table.concat(args, " "))
        end
    end, false)
end

-- Check for HTML injection attempts
function TryingToInjectHTML(text)
    return string.find(text, "[<>]") ~= nil
end

-- Check for blacklisted words
function AnyWordBlackListed(text)
    for i = 1, #Config.BlackListedWords do
        if string.match(text:lower(), Config.BlackListedWords[i]:lower()) then
            return true
        end
    end
    return false
end

-- Main function to send alerts
function SendAlert(alertData, isRecursive)
    local playerId = source or alertData.playerID
    
    if not isRecursive then
        -- Validate title and message
        if alertData.title and AnyWordBlackListed(alertData.title) then return end
        if alertData.message and AnyWordBlackListed(alertData.message) then return end
        
        -- Check cooldown
        if playerId and not alertData.ignoreCooldown then
            if alertCooldowns[playerId] then
                local timeSinceLastAlert = GetGameTimer() - alertCooldowns[playerId]
                if timeSinceLastAlert < (Config.MinAlertCooldown * 1000) then
                    TriggerClientEvent("origen_police:ShowNotification", playerId, "You have to wait a bit to send another alert")
                    return
                end
            end
            alertCooldowns[playerId] = GetGameTimer()
        end
        
        -- Check for HTML injection
        for key, value in pairs(alertData) do
            if type(value) == "string" and TryingToInjectHTML(value) then
                return
            end
        end
        
        -- Validate coords type
        if alertData.coords then
            local coordsType = type(alertData.coords)
            if coordsType ~= "vector3" and coordsType ~= "vector4" then
                print("Invalid type for coords, expected vector3/4 got " .. coordsType)
            end
        end
        
        -- Get coords if not provided
        if not alertData.coords then
            alertData.coords = GetEntityCoords(GetPlayerPed(playerId))
        end
        
        -- Convert vector4 to vector3
        if alertData.coords and alertData.coords.w then
            alertData.coords = vector3(alertData.coords.x, alertData.coords.y, alertData.coords.z)
        end
        
        -- Assign alert code
        alertCode = alertCode + 1
        alertData.code = alertCode
        
        -- Determine job category if not specified
        if not alertData.job then
            local player = FW_GetPlayer(playerId)
            if not player then return end
            
            for category, jobs in pairs(Config.JobCategory) do
                for _, job in pairs(jobs) do
                    if job.name == player.PlayerData.job.name then
                        alertData.job = category
                        break
                    end
                end
            end
        end
        
        alertData.job = alertData.job or "police"
        
        -- Remove plate from metadata if configured
        if alertData.metadata and not Config.DisplayPlateOnVehicleAlerts then
            alertData.metadata.plate = nil
        end
        
        -- Set player ID
        if playerId then
            alertData.playerID = alertData.playerID or playerId
        end
    end
    
    -- Handle multiple job categories
    if type(alertData.job) == "table" then
        for i = 1, #alertData.job do
            local copiedAlert = Shallowcopy(alertData)
            copiedAlert.job = alertData.job[i]
            SendAlert(copiedAlert, true)
        end
        return
    end
    
    -- Get players to send alert to
    local targetPlayers = {}
    
    if Config.Framework == "qbcore" then
        if Config.JobCategory[alertData.job] == nil then
            print("origen_police: ERROR: You are trying to send an alert with a job category that doesn't exist in the Config.JobCategory table in config/permissions.lua")
            return
        end
        
        for _, job in pairs(Config.JobCategory[alertData.job]) do
            local onDutyPlayers = Framework.Functions.GetPlayersOnDuty(job.name)
            
            for i = 1, #onDutyPlayers do
                table.insert(targetPlayers, onDutyPlayers[i])
            end
        end
    elseif Config.Framework == "esx" then
        targetPlayers = GetPlayersInDuty(alertData.job)
    else
        targetPlayers = {}
        print("Can't find supported framework: ", Config.Framework)
    end
    
    -- Save to heat map database
    MySQL.awaitInsert("INSERT INTO origen_police_alerts (x, y, job) VALUES (?, ?, ?)", {
        FW_Round(alertData.coords.x),
        FW_Round(alertData.coords.y),
        alertData.job
    })
    
    -- Send alerts to players
    if Config.DispatchRedirect then
        -- Only send to central subscribers
        for i = 1, #targetPlayers do
            if CentralSuscribeds[targetPlayers[i]] then
                TriggerClientEvent("origen_police_menu:client:ReceiveAlert", targetPlayers[i], alertData)
            end
        end
    else
        -- Send to all or based on central subscription
        for i = 1, #targetPlayers do
            if CentralSuscribeds[targetPlayers[i]] then
                TriggerClientEvent("origen_police_menu:client:ReceiveAlert", targetPlayers[i], alertData)
                
                if Config.RecieveAlwaysAlerts then
                    TriggerClientEvent("origen_police:client:ReceiveAlert", targetPlayers[i], alertData)
                end
            else
                TriggerClientEvent("origen_police:client:ReceiveAlert", targetPlayers[i], alertData)
            end
        end
    end
end

-- Edit an existing alert
function EditAlert(playerId, alertData)
    if not alertData.code then return end
    
    local jobCategory = CanOpenTablet(playerId)[2]
    local targetPlayers = {}
    
    -- Get players to notify
    if Config.Framework == "qbcore" then
        if Config.JobCategory[jobCategory] == nil then
            print("origen_police: ERROR: You are trying to send an alert with a job category that doesn't exist in the Config.JobCategory table in config/permissions.lua")
            return
        end
        
        for _, job in pairs(Config.JobCategory[jobCategory]) do
            local onDutyPlayers = Framework.Functions.GetPlayersOnDuty(job.name)
            
            for i = 1, #onDutyPlayers do
                table.insert(targetPlayers, onDutyPlayers[i])
            end
        end
    elseif Config.Framework == "esx" then
        targetPlayers = GetPlayersInDuty(jobCategory)
    else
        targetPlayers = {}
        print("Can't find supported framework: ", Config.Framework)
    end
    
    -- Send edit to players
    for i = 1, #targetPlayers do
        if Config.RecieveAlwaysAlerts then
            TriggerClientEvent("origen_police:client:EditAlert", targetPlayers[i], alertData)
            TriggerClientEvent("origen_police_menu:client:EditAlert", targetPlayers[i], alertData)
        else
            if not CentralSuscribeds[targetPlayers[i]] then
                TriggerClientEvent("origen_police:client:EditAlert", targetPlayers[i], alertData)
            else
                TriggerClientEvent("origen_police_menu:client:EditAlert", targetPlayers[i], alertData)
            end
        end
    end
end

-- Exports and event registrations
exports("SendAlert", SendAlert)
RegisterServerEvent("SendAlert:police", SendAlert)

exports("EditAlert", EditAlert)
RegisterServerEvent("origen_police:server:EditAlert", EditAlert)

FW_CreateCallback("origen_police:server:EditAlert", function(source, callback, alertData)
    EditAlert(source, alertData)
    callback(true)
end)

-- Force select alert for unit
FW_CreateCallback("origen_police:server:ForceSelectAlert", function(source, callback, data)
    local jobCategory = CanOpenTablet(source)[2]
    
    References[jobCategory] = References[jobCategory] or {}
    
    -- Send to all units with matching unit name
    for playerId, reference in pairs(References[jobCategory]) do
        if reference.unit == data.unit then
            TriggerClientEvent("origen_police:client:ForceSelectAlert", playerId, data.alert)
        end
        
        data.alert.unit = data.unit
        TriggerClientEvent("origen_police_menu:client:EditAlert", playerId, data.alert)
        
        data.alert.code = string.format("%04d", data.alert.code)
        local message = Translations.AlertAsigned:format(data.alert.code, data.unit)
        TriggerClientEvent("origen_police:ForceNotification", playerId, message)
    end
    
    callback(true)
end)

-- Get heat map alerts
if Config.HeatMapAlerts then
    FW_CreateCallback("origen_police:server:GetHeatAlerts", function(source, callback)
        local jobCategory = CanOpenTablet(source)[2]
        callback(heatMapAlerts[jobCategory] or {})
    end)
end