-- Alert dispatch system for origen_police
local alerts = {}
local alertsVisible = false
local currentAlertIndex = 0
local alertFilter = {}
local bindsRegistered = false

-- Register network event for /me command
RegisterNetEvent("origen_police:meCommand", function(message)
    UseCommand("me", message)
end)

-- Initialize key bindings and commands
function StartAlerts()
    if bindsRegistered then
        return
    end
    bindsRegistered = true
    
    -- Set default key bindings
    exports.origen_police:SetDefaultBind(
        Config.Commands.OpenMiniDispatch.key,
        "origen_police:dispatch:alertas"
    )
    
    exports.origen_police:SetDefaultBind(
        Config.Commands.AcceptAlert.key,
        "origen_police:dispatch:mrkalert"
    )
    
    exports.origen_police:SetDefaultBind(
        Config.Commands.DeleteAlert.key,
        "origen_police:dispatch:delalert"
    )
    
    -- Register key mappings
    RegisterKeyMapping(
        Config.Commands.NextAlert.cmd,
        Config.Commands.NextAlert.description,
        "keyboard",
        Config.Commands.NextAlert.key
    )
    
    RegisterKeyMapping(
        Config.Commands.PreviousAlert.cmd,
        Config.Commands.PreviousAlert.description,
        "keyboard",
        Config.Commands.PreviousAlert.key
    )
    
    -- Open mini dispatch
    RegisterNetEvent("origen_police:dispatch:alertas", function()
        local playerData = FW_GetPlayerData(false)
        
        if onduty and not IsNuiFocused() then
            local canOpen = CanOpenTablet(playerData.job.name)
            if canOpen[1] then
                ToggleAlerts()
            end
        end
    end)
    
    -- Mark/accept alert (set waypoint)
    RegisterNetEvent("origen_police:dispatch:mrkalert", function()
        if not onduty then
            return
        end
        
        if alertsVisible then
            if IsWaypointActive() then
                DeleteWaypoint()
            else
                if currentAlertIndex > 0 then
                    local alert = alerts[currentAlertIndex]
                    if alert then
                        local coords = alert.coords
                        local playerPos = GetEntityCoords(PlayerPedId())
                        local distance = #(vector3(coords.x, coords.y, coords.z) - playerPos)
                        
                        if distance > 10 then
                            SetNewWaypoint(tonumber(coords.x), tonumber(coords.y))
                        else
                            ShowNotification(Config.Translations.ClosestAlert)
                        end
                    end
                end
            end
        end
    end)
    
    -- Delete current alert
    RegisterNetEvent("origen_police:dispatch:delalert", function()
        if not onduty then
            return
        end
        
        if alertsVisible then
            Del()
        end
    end)
    
    -- Next alert command
    RegisterCommand(Config.Commands.NextAlert.cmd, function()
        if not onduty then
            return
        end
        
        if alertsVisible then
            Next()
        end
    end)
    
    -- Previous alert command
    RegisterCommand(Config.Commands.PreviousAlert.cmd, function()
        if not onduty then
            return
        end
        
        if alertsVisible then
            Prev()
        end
    end)
end

-- Toggle alerts visibility
function ToggleAlerts(state)
    if state == nil then
        state = not alertsVisible
    end
    
    if alertsVisible ~= state then
        alertsVisible = state
        SendNUIMessage({
            action = "ShowAlerts",
            value = alertsVisible
        })
    end
end

-- Receive new alert
RegisterNetEvent("origen_police:client:ReceiveAlert", function(alertData, setWaypoint)
    -- Check if alert type is filtered
    if #alertFilter > 0 then
        if alertData.type then
            local isFiltered = false
            for i = 1, #alertFilter do
                if alertFilter[i] == alertData.type then
                    isFiltered = true
                    break
                end
                if i == #alertFilter then
                    return
                end
            end
        end
    end
    
    -- Play alert sound
    PlaySoundFrontend(-1, "Event_Message_Purple", "GTAO_FM_Events_Soundset", false)
    
    -- Convert coords to vector3 if needed
    if type(alertData.coords) == "table" then
        alertData.coords = vector3(alertData.coords.x, alertData.coords.y, alertData.coords.z)
    end
    
    -- Calculate distance from player
    local playerPos = GetEntityCoords(PlayerPedId())
    local distance = #(playerPos - alertData.coords)
    alertData.distance = distance
    
    -- Format distance string
    if alertData.distance < 1000 then
        alertData.distance = FW_Round(alertData.distance, 2) .. " m"
    else
        alertData.distance = FW_Round(alertData.distance / 1000, 2) .. " Km"
    end
    
    -- Get street name
    alertData.street = GetStreetNameFromHashKey(
        GetStreetNameAtCoord(alertData.coords.x, alertData.coords.y, alertData.coords.z)
    )
    
    -- Set timestamp
    alertData.time = GetGameTimer()
    
    -- Add alert to list
    table.insert(alerts, alertData)
    currentAlertIndex = #alerts
    
    -- Auto-select new alert if configured
    if Config.SelectNewAlert then
        SetAlert(currentAlertIndex)
    end
    
    -- Set waypoint if requested
    if setWaypoint then
        if IsWaypointActive() then
            DeleteWaypoint()
        end
        SetNewWaypoint(
            tonumber(alerts[currentAlertIndex].coords.x),
            tonumber(alerts[currentAlertIndex].coords.y)
        )
    end
    
    -- Auto-open dispatch if configured
    if Config.OpenDispatchOnAlert then
        ToggleAlerts(true)
    end
end)

-- Go to previous alert
function Prev()
    if alerts[currentAlertIndex - 1] then
        currentAlertIndex = currentAlertIndex - 1
        SetAlert(currentAlertIndex)
        return true
    else
        return false
    end
end

-- Go to next alert
function Next()
    if alerts[currentAlertIndex + 1] then
        currentAlertIndex = currentAlertIndex + 1
        SetAlert(currentAlertIndex)
        return true
    else
        return false
    end
end

-- Delete alert
function Del(index)
    if not index then
        index = currentAlertIndex
    end
    
    if type(alerts) ~= "table" then
        alerts = {}
    end
    
    for i, alert in pairs(alerts) do
        if i == index then
            table.remove(alerts, i)
            break
        end
    end
    
    local success = SetAlert(currentAlertIndex)
    
    if not success then
        success = Prev()
    end
    
    if not success then
        ToggleAlerts(false)
        Citizen.Wait(500)
        SendNUIMessage({
            action = "NoAlert"
        })
    end
end

-- Set current alert
function SetAlert(index)
    if currentAlertIndex ~= index then
        currentAlertIndex = index
    end
    
    local alert = alerts[index]
    
    if alert then
        SendNUIMessage({
            action = "SetAlert",
            title = alert.title,
            message = alert.message,
            annotation = alert.annotation,
            metadata = alert.metadata,
            distance = alert.distance,
            street = alert.street,
            code = alert.code,
            central = alert.central,
            playerID = alert.playerID,
            count = currentAlertIndex,
            ago = math.ceil((GetGameTimer() - alert.time) / 1000),
            total = #alerts
        })
        return true
    else
        return false
    end
end

-- Get alert by ID
function GetAlertFromId(alertId)
    local foundAlert = false
    local foundIndex = false
    
    if type(alerts) ~= "table" then
        alerts = {}
    end
    
    for i, alert in pairs(alerts) do
        if alert.id == alertId then
            foundAlert = alerts[i]
            foundIndex = i
            break
        end
    end
    
    return foundAlert, foundIndex
end

exports("GetAlertFromId", GetAlertFromId)

-- Set alert filter (NUI callback)
RegisterNUICallback("SetFilter", function(data, cb)
    alertFilter = data.filter
    cb(true)
end)

-- Edit existing alert
RegisterNetEvent("origen_police:client:EditAlert", function(newData)
    for i = 1, #alerts do
        if alerts[i].code == newData.code then
            if type(newData) ~= "table" then
                newData = {}
            end
            
            -- Update alert properties
            for key, value in pairs(newData) do
                alerts[i][key] = value
            end
            
            -- Refresh display if it's the current alert
            if i == currentAlertIndex then
                SetAlert(currentAlertIndex)
            end
            break
        end
    end
end)

-- Force select specific alert (from central dispatch)
RegisterNetEvent("origen_police:client:ForceSelectAlert", function(alertData)
    local found = false
    
    for i = 1, #alerts do
        if alerts[i].code == alertData.code then
            alerts[i].central = true
            SetAlert(i)
            found = true
            
            -- Set waypoint to alert location
            if IsWaypointActive() then
                DeleteWaypoint()
            end
            SetNewWaypoint(
                tonumber(alerts[i].coords.x),
                tonumber(alerts[i].coords.y)
            )
            break
        end
    end
    
    -- If alert not found, create it
    if not found then
        alertData.central = true
        TriggerEvent("origen_police:client:ReceiveAlert", alertData, true)
    end
end)