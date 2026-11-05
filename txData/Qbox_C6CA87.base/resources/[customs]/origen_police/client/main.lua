-- Global variables
onduty = false
local locationData = {}
ValidVehicles = {}
local playerJobCategory = nil

-- QBCore: Set duty on player load
if Config.Framework == "qbcore" then
    Citizen.CreateThread(function()
        local playerData = Framework.Functions.GetPlayerData()
        if playerData.job and playerData.job.onduty then
            SetDuty(true)
        end
    end)
    
    RegisterNetEvent("origen_police:client:OnPlayerLoaded", function()
        local playerData = Framework.Functions.GetPlayerData()
        
        -- Wait for job data to be available
        while not playerData.job do
            Citizen.Wait(1000)
            playerData = Framework.Functions.GetPlayerData()
        end
        
        if playerData.job.onduty then
            SetDuty(true)
        end
    end)
end

-- Update player job category
function UpdatePlayerCategory(jobName)
    if not jobName then
        local playerData = FW_GetPlayerData(false)
        if playerData and playerData.job and playerData.job.name then
            jobName = playerData.job.name
        end
    end
    
    if not jobName then return end
    
    playerJobCategory = CanOpenTablet(jobName)[2]
end

-- Get player job category
function GetPlayerJobCategory()
    if playerJobCategory then
        return playerJobCategory
    end
    
    UpdatePlayerCategory()
    return playerJobCategory
end

-- Handle job updates
RegisterNetEvent("origen_police:client:OnJobUpdate", function(job)
    UpdatePlayerCategory(job.name)
end)

-- Toggle duty via event
RegisterNetEvent("origen_police:client:enterOnDuty", function()
    local canOpen = CanOpenTablet(FW_GetPlayerData(false).job.name)[1]
    if not canOpen then return end
    
    TriggerEvent("origen_police:toggleDuty")
    SendNUIMessage({
        setDuty = true,
        duty = not onduty
    })
end)

-- Handle player unload
RegisterNetEvent("origen_police:client:OnPlayerUnload", function()
    onduty = false
    ToggleAlerts(false)
    TriggerServerEvent("origen_police:server_esx:ForceDropDuty")
end)

-- Set duty status
function SetDuty(dutyStatus)
    local playerData = FW_GetPlayerData(false)
    local canOpen, jobCategory = CanOpenTablet(playerData.job.name)[1], CanOpenTablet(playerData.job.name)[2]
    
    if not dutyStatus then
        ToggleAlerts(false)
    end
    
    -- Don't change if already in requested state or not allowed
    if dutyStatus == onduty or canOpen == false then
        return
    end
    
    onduty = dutyStatus
    
    if onduty then
        StartAlerts()
    end
    
    Citizen.CreateThread(function()
        -- Setup police relationships
        StartReferences()
        
        local policeDogGroup = AddRelationshipGroup("POLICEDOG")
        local copGroup = AddRelationshipGroup("COP")
        
        SetRelationshipBetweenGroups(0, policeDogGroup, copGroup)
        SetRelationshipBetweenGroups(0, copGroup, policeDogGroup)
        SetPedRelationshipGroupHash(PlayerPedId(), copGroup)
        
        -- Delayed clock-in event
        Citizen.CreateThread(function()
            Citizen.Wait(60000)
            if FW_GetPlayerData(false).job.onduty then
                TriggerServerEvent("origen_police:server:ClockIn")
            end
        end)
        
        -- Main duty loop
        while onduty do
            local sleepTime = 500
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            -- Handle markers
            if Tables.Markers then
                for categoryIndex = 1, #Tables.Markers do
                    local allowed = true
                    
                    -- Check if job is allowed for this marker category
                    if not Config.IgnoreSettings then
                        if MapOptions[categoryIndex].AllowedJobCat then
                            allowed = IsJobAllowed(MapOptions[categoryIndex], jobCategory)
                        end
                    end
                    
                    if allowed then
                        for markerIndex = 1, #Tables.Markers[categoryIndex] do
                            local marker = Tables.Markers[categoryIndex][markerIndex]
                            local distance = #(playerCoords - marker.coords.xyz)
                            
                            if distance < 30 then
                                sleepTime = 0
                                
                                -- Draw marker
                                if Config.MarkersDraw then
                                    DrawMarker(
                                        marker.sprite,
                                        marker.coords.x, marker.coords.y, marker.coords.z,
                                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                        0.3, 0.3, 0.3,
                                        marker.rgba.r, marker.rgba.g, marker.rgba.b, marker.rgba.a,
                                        false, false, 0, true
                                    )
                                end
                                
                                local radius = marker.radius or 1
                                
                                if distance < radius then
                                    -- Show help notification
                                    if Config.CustomNotify then
                                        ShowHelpNotification("E", marker.text)
                                        marker.noty = true
                                    else
                                        if Config.Framework == "qbcore" then
                                            if not marker.noty then
                                                exports["qb-core"]:DrawText("[E] " .. marker.text, "left")
                                                marker.noty = true
                                            end
                                        elseif Config.Framework == "esx" then
                                            Framework.ShowHelpNotification("~INPUT_PICKUP~ " .. marker.text, true)
                                        end
                                    end
                                    
                                    -- Handle interaction
                                    if IsControlJustPressed(0, 38) then
                                        Debuger("Marker interact: ", categoryIndex, markerIndex, json.encode(marker))
                                        TriggerEvent(marker.event, categoryIndex, markerIndex, marker.stationName)
                                    end
                                else
                                    if marker.noty then
                                        HideHelpNotification()
                                        marker.noty = nil
                                    end
                                end
                            else
                                if marker.noty then
                                    HideHelpNotification()
                                    marker.noty = nil
                                end
                            end
                        end
                    end
                end
            end
            
            -- Handle street display in vehicle
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            
            if vehicle ~= 0 then
                if Config.ShowCurrentStreet then
                    if not locationData.enabled or GetGameTimer() - locationData.enabled > 500 then
                        local street = GetStreetName(playerCoords)
                        local cardinal = GetCardinalFromHeading(GetEntityHeading(vehicle))
                        locationData.enabled = GetGameTimer()
                        
                        if locationData.street ~= street or locationData.cardinal ~= cardinal then
                            locationData.street = street
                            locationData.cardinal = cardinal
                            
                            SendNUIMessage({
                                action = "Location",
                                street = street,
                                cardinal = cardinal
                            })
                        end
                    end
                end
            else
                if locationData.enabled then
                    SendNUIMessage({ action = "HideLocation" })
                    locationData = {}
                end
            end
            
            Citizen.Wait(sleepTime)
        end
        
        -- Cleanup when going off duty
        SendNUIMessage({ action = "HideLocation" })
        locationData = {}
        
        -- Hide all marker notifications
        if Tables.Markers then
            for categoryIndex = 1, #Tables.Markers do
                for markerIndex = 1, #Tables.Markers[categoryIndex] do
                    if Tables.Markers[categoryIndex][markerIndex].noty then
                        HideHelpNotification()
                        break
                    end
                end
            end
        end
        
        TriggerServerEvent("origen_police:server:ClockOut")
    end)
    
    return onduty
end

-- Track valid vehicles for sirens/features
HandlerManager:AddCallback("vehicle_sit", function(vehicle, lastVehicle)
    if vehicle then
        ValidVehicles[vehicle] = IsVehicleValid("any", vehicle)
        Debuger("Is vehicle valid: " .. tostring(ValidVehicles[vehicle]))
    else
        ValidVehicles[lastVehicle] = nil
        Debuger("Vehicle left: " .. tostring(lastVehicle))
    end
end)

-- Main vehicle controls thread
Citizen.CreateThread(function()
    local isDriverSeat = false
    local hornPressed = false
    
    while true do
        local sleepTime = 500
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        if ValidVehicles[vehicle] == nil then
            -- Vehicle not yet validated
        elseif vehicle ~= 0 and ValidVehicles[vehicle] == true then
            if Config.SirensSystem then
                -- Disable default siren controls
                DisableControlAction(0, 85, true)
                
                if Config.Commands.HornKey.disabledKey then
                    DisableControlAction(0, Config.Commands.HornKey.disabledKey, true)
                end
                
                -- Turn off radio
                SetVehRadioStation(vehicle, "OFF")
                SetVehicleRadioEnabled(vehicle, false)
                
                -- Handle police horn (driver only)
                if GetPedInVehicleSeat(vehicle, -1) == playerPed then
                    if IsDisabledControlPressed(0, Config.Commands.HornKey.key) then
                        if not IsVehicleValid("heli", vehicle) then
                            if not hornPressed then
                                hornPressed = vehicle
                                TriggerServerEvent("origen_police:server:PoliceHornState", 
                                    NetworkGetNetworkIdFromEntity(vehicle), true)
                            end
                        end
                    elseif hornPressed then
                        hornPressed = false
                        TriggerServerEvent("origen_police:server:PoliceHornState", 
                            NetworkGetNetworkIdFromEntity(vehicle), false)
                    end
                end
            end
            
            -- Camera or rappel (helicopters)
            if IsControlJustPressed(0, Config.Commands.CamOrRappel.key) then
                if GetVehicleClass(vehicle) == 15 then
                    DoCamOrRappel(vehicle)
                end
            end
            
            -- Car megaphone
            if IsControlJustPressed(0, Config.Commands.TalkMegaphone.key) then
                SendNUIMessage({ action = "ShowCarMegaphone" })
                OverrideProximityRange(Config.MegaphoneVoiceDist, true)
                
                while IsControlPressed(0, 246) do
                    Citizen.Wait(0)
                    SetControlNormal(0, 249, 1.0)
                    SetControlNormal(1, 249, 1.0)
                    SetControlNormal(2, 249, 1.0)
                end
                
                OverrideProximityRange()
                SendNUIMessage({ action = "HideCarMegaphone" })
            end
            
            sleepTime = 0
        else
            -- Not in valid vehicle, cleanup
            if isDriverSeat and hornPressed then
                TriggerServerEvent("origen_police:server:PoliceHornState", 
                    NetworkGetNetworkIdFromEntity(hornPressed), false)
            end
            
            isDriverSeat = false
            hornPressed = false
            SendNUIMessage({ action = "HideCarMegaphone" })
        end
        
        Citizen.Wait(sleepTime)
    end
end)

-- NUI Callbacks
RegisterNUICallback("duty", function(data, cb)
    if Config.Framework == "qbcore" then
        TriggerServerEvent("QBCore:ToggleDuty", not onduty)
    elseif Config.Framework == "esx" then
        TriggerServerEvent("origen_police:server_esx:SetDuty", not onduty)
    end
    
    cb(not onduty)
end)

RegisterNetEvent("origen_police:ShowNotification", function(message)
    ShowNotification(message)
end)

RegisterNUICallback("GetWebhook", function(data, cb)
    GetCameraWebhook(function(webhookUrl)
        if webhookUrl then
            cb({
                url = webhookUrl,
                fields = Config.Fields[Config.UploadMethod]
            })
        else
            cb(false)
            ShowNotification("Not webhook found in config/logs/logs.lua")
        end
    end)
end)

-- Exports
exports("GetPoliceDuty", function()
    return onduty
end)

exports("IsOnDuty", function()
    return onduty
end)