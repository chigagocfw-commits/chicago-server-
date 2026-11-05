-- Police station settings management - Client side

-- Helper function to check if numbers are approximately equal
function NumberEquals(num1, num2, tolerance)
    tolerance = tolerance or 0.5
    return math.abs(num1 - num2) < tolerance
end

-- NUI Callback: Teleport to marker
RegisterNUICallback("GotoMarker", function(data, cb)
    local coords = vector3(tonumber(data.x), tonumber(data.y), tonumber(data.z))
    SetEntityCoords(PlayerPedId(), coords)
    cb(true)
end)

-- NUI Callback: Get job categories
RegisterNUICallback("GetJobCategories", function(data, cb)
    local jobCategories = Config.JobCategory
    local result = {}
    
    for categoryName, jobs in pairs(jobCategories) do
        result[categoryName] = {}
        for _, jobData in pairs(jobs) do
            result[categoryName][#result[categoryName] + 1] = jobData.name
        end
    end
    
    cb(result)
end)

-- NUI Callback: Set marker position
RegisterNUICallback("SetMarkerPos", function(data, cb)
    SetNewPos(data.station, data.markerName, data.markerIndex, data.multiple)
    cb(true)
end)

-- NUI Callback: Create new marker
RegisterNUICallback("CreateMarker", function(data, cb)
    SetNewPos(data.station, data.markerName, nil, data.multiple, true)
    cb(true)
end)

-- Main function to set new marker position
function SetNewPos(stationName, markerName, markerIndex, isMultiple, isCreating)
    local markerSprite = 20
    
    -- Get marker sprite from config
    if MarkersList[markerName] then
        markerSprite = MarkersList[markerName].sprite
    elseif PublicMarkerList[markerName] then
        markerSprite = PublicMarkerList[markerName].sprite
    end
    
    local positionCount = 0
    local creatingData = {}
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(10)
            
            local onScreen, screenCoords = GetScreenCoords(100)
            
            -- Show help text
            local helpText = (isMultiple and positionCount >= 1) and "Place spawn position" or "Place marker position"
            ShowHelpNotification("E", helpText)
            
            -- Draw marker preview
            if onScreen then
                local playerPos = GetEntityCoords(PlayerPedId())
                
                -- Draw line from player to marker
                DrawLine(playerPos.x, playerPos.y, playerPos.z, screenCoords.x, screenCoords.y, screenCoords.z, 255, 255, 255, 100)
                
                -- Draw marker sprite
                DrawMarker(
                    markerSprite,
                    screenCoords.x, screenCoords.y, screenCoords.z + 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    0.3, 0.3, 0.3,
                    0, 0, 0, 100,
                    false, false, 0, true
                )
                
                -- E - Confirm position
                if IsControlJustPressed(0, 38) then
                    positionCount = positionCount + 1
                    
                    local coordKey = (positionCount == 1) and "coords" or "spawn"
                    creatingData[coordKey] = {
                        screenCoords.x,
                        screenCoords.y,
                        screenCoords.z + 1.0,
                        GetEntityHeading(PlayerPedId())
                    }
                    
                    HideHelpNotification()
                    
                    -- Update existing marker
                    if not isCreating then
                        FW_TriggerCallback("origen_police:callback:UpdateMarkerPos", function(response)
                        end, {
                            station = stationName,
                            markerName = markerName,
                            markerIndex = tonumber(markerIndex) + 1,
                            x = screenCoords.x,
                            y = screenCoords.y,
                            z = screenCoords.z + 1.0,
                            w = GetEntityHeading(PlayerPedId()),
                            isMultiple = positionCount > 1
                        })
                        -- Exit after updating marker
                        if not isMultiple or positionCount > 1 then
                            TogglePause(true)
                            break
                        end
                    -- Create new marker
                    elseif not isMultiple or positionCount == 1 then
                        FW_TriggerCallback("origen_police:callback:CreateMarker", function(response)
                        end, {
                            station = stationName,
                            markerName = markerName,
                            creatingData = creatingData
                        })
                        -- Exit after creating single marker or first position of multiple marker
                        if not isMultiple then
                            TogglePause(true)
                            break
                        end
                    end
                    
                    -- Exit after placing spawn position for multiple markers
                    if isMultiple and positionCount > 1 then
                        TogglePause(true)
                        break
                    end
                -- ESC/BACKSPACE - Cancel
                elseif IsControlJustPressed(0, 177) then
                    TogglePause(true)
                    break
                end
            end
        end
        
        HideHelpNotification()
    end)
end

-- Get station index from name
function GetStationIndex(stationName)
    for index, name in pairs(Config.Maps) do
        if name == stationName then
            return tonumber(index)
        end
    end
end

-- Network event: Update marker position
RegisterNetEvent("origen_police:client:UpdateMarkerPos", function(data)
    -- Special handling for NPC markers
    if data.markerName == "BillsNPC" then
        return ShowNotification("The NPC position will be updated after a script restart")
    end
    
    -- Determine if marker is public or station-specific
    local isPublicMarker = PublicMarkerList[data.markerName] ~= nil
    local markersList = isPublicMarker and Public.Markers or Tables.Markers[GetStationIndex(data.station)]
    local eventName = isPublicMarker and PublicMarkerList[data.markerName].event or MarkersList[data.markerName].event
    
    -- Find and update the marker
    for _, marker in pairs(markersList) do
        if marker.event == eventName then
            local coordKey = data.isMultiple and "spawn" or "coords"
            marker[coordKey] = vector4(data.x, data.y, data.z, data.w)
            break
        end
    end
end)

-- Network event: Remove marker
RegisterNetEvent("origen_police:client:RemoveMarker", function(data)
    -- Special handling for NPC markers
    if data.markerName == "BillsNPC" then
        return ShowNotification("The NPC will be removed after a script restart")
    end
    
    -- Determine if marker is public or station-specific
    local isPublicMarker = PublicMarkerList[data.markerName] ~= nil
    local markersList = isPublicMarker and Public.Markers or Tables.Markers[GetStationIndex(data.station)]
    local eventName = isPublicMarker and PublicMarkerList[data.markerName].event or MarkersList[data.markerName].event
    
    -- Find and remove the marker
    for index, marker in pairs(markersList) do
        if marker.event == eventName then
            -- Check if coordinates match (with tolerance)
            if NumberEquals(marker.coords.x, data.coords[1]) and
               NumberEquals(marker.coords.y, data.coords[2]) and
               NumberEquals(marker.coords.z, data.coords[3]) then
                print("REMOVED MARKER: " .. data.markerName)
                table.remove(markersList, index)
                break
            end
        end
    end
end)

-- Network event: Create marker
RegisterNetEvent("origen_police:client:CreateMarker", function(data)
    -- Special handling for NPC markers
    if data.markerName == "BillsNPC" then
        return ShowNotification("The NPC will be spawned after a script restart")
    end
    
    -- Determine if marker is public or station-specific
    local isPublicMarker = PublicMarkerList[data.markerName] ~= nil
    local markerConfig = isPublicMarker and PublicMarkerList[data.markerName] or MarkersList[data.markerName]
    local stationIndex = GetStationIndex(data.station)
    local markersList = isPublicMarker and Public.Markers or Tables.Markers[stationIndex]
    
    -- Initialize markers table if needed
    if markersList == nil and not isPublicMarker then
        Tables.Markers[stationIndex] = {}
        markersList = Tables.Markers[stationIndex]
    end
    
    -- Add new marker
    local newIndex = #markersList + 1
    markersList[newIndex] = markerConfig
    markersList[newIndex].coords = vector4(
        data.creatingData.coords[1],
        data.creatingData.coords[2],
        data.creatingData.coords[3],
        data.creatingData.coords[4]
    )
    
    -- Add spawn position if provided
    if data.creatingData.spawn then
        markersList[newIndex].spawn = vector4(
            data.creatingData.spawn[1],
            data.creatingData.spawn[2],
            data.creatingData.spawn[3],
            data.creatingData.coords[4]
        )
    end
end)

-- Network event: Toggle station active status
RegisterNetEvent("origen_police:client:ActiveStation", function(data)
    if not data.active then
        -- Remove station from active maps
        for index, stationName in pairs(Config.Maps) do
            if stationName == data.station then
                Config.Maps[index] = nil
                break
            end
        end
        ReloadMarkers()
        return
    end
    
    -- Add station to active maps
    Config.Maps[#Config.Maps + 1] = data.station
    ReloadMarkers()
end)

-- Handle player loaded event
local mapsInitialized = false

RegisterNetEvent("origen_police:client:OnPlayerLoaded", function()
    if Config.IgnoreSettings or mapsInitialized then
        return
    end
    
    mapsInitialized = true
    
    FW_TriggerCallback("origen_police:callback:GetActiveMaps", function(activeMaps)
        Config.Maps = activeMaps
        
        if #activeMaps == 0 then
            print("^3WARNING: NO ACTIVE MAPS, PLEASE ADD SOME IN THE SETTING TAB OF THE POLICE TABLET^0")
        end
        
        ReloadMarkers()
    end)
end)