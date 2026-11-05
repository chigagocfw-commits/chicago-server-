local isDrawTextEnabled = (ScootConfig.interaction == "drawtext")
local stations = {}
local currentTextUiStation = nil

local function handleStationInteraction(stationId)
    if not ScootConfig.rental.externalUi then
        ScootUI.open(stationId)
        return
    end

    local ok, result = pcall(lib.callback.await, "scootbunker:menu", false, stationId)
    if ok and result and result.ok then
        TriggerEvent("scootbunker:stationOpened", stationId, result)
    else
        local errorMsg = (result and result.error) or ScootT("connection_error")
        ScootBunker.notify(errorMsg)
    end
end

ScootBunker.onInteract = handleStationInteraction

local function hideInteractionPrompt()
    if currentTextUiStation then
        lib.hideTextUI()
        currentTextUiStation = nil
    end
end

CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(cache.ped)

        for stationId, stationData in pairs(stations) do
            local dist = #(playerCoords - stationData.coords)
            local spawnedStation = ScootBunker.list[stationId]

            if dist <= ScootConfig.spawnDistance and not spawnedStation then
                ScootBunker.spawn(stationId, stationData)
            elseif dist > ScootConfig.despawnDistance and spawnedStation then
                if not spawnedStation.busy then
                    ScootBunker.despawn(stationId)
                end
            end
        end

        Wait(1000)
    end
end)

CreateThread(function()
    if not isDrawTextEnabled then
        return
    end

    while true do
        local sleep = 400
        local playerCoords = GetEntityCoords(cache.ped)
        local nearestStationId = nil
        local nearestDistance = nil

        for stationId, stationData in pairs(ScootBunker.list) do
            local dist = #(playerCoords - stationData.coords)
            if dist <= ScootConfig.interactDistance and not stationData.busy then
                if not nearestDistance or dist < nearestDistance then
                    nearestDistance = dist
                    nearestStationId = stationId
                end
            end
        end

        if nearestStationId then
            if not ScootUI.visible and not ScootPlacement.active then
                sleep = 0

                if currentTextUiStation ~= nearestStationId then
                    currentTextUiStation = nearestStationId
                    local keyLabel = ScootConfig.interactKeyLabel or "E"
                    lib.showTextUI(ScootT("key_hint", keyLabel, ScootT("interact")))
                end

                if IsControlJustReleased(0, ScootConfig.interactKey) then
                    ScootBunker.debug(string.format("key pressed for #%s", tostring(nearestStationId)))
                    hideInteractionPrompt()
                    handleStationInteraction(nearestStationId)
                end
            end
        else
            hideInteractionPrompt()
        end

        Wait(sleep)
    end
end)

local function refreshAllBlips()
    ScootBlips.refresh(stations)
end

RegisterNetEvent("scootbunker:setLocations", function(newLocations)
    if source ~= 65535 or type(newLocations) ~= "table" then
        return
    end

    for stationId in pairs(ScootBunker.list) do
        local newLoc = newLocations[stationId]
        local currentLoc = stations[stationId]

        if not newLoc or (currentLoc and newLoc.revision ~= currentLoc.revision) then
            ScootBunker.despawn(stationId)
        end
    end

    stations = {}
    for stationId, locData in pairs(newLocations) do
        stations[stationId] = {
            coords = vec3(locData.coords.x + 0.0, locData.coords.y + 0.0, locData.coords.z + 0.0),
            heading = locData.heading + 0.0,
            revision = locData.revision,
            name = locData.name,
            color = locData.color,
            blip = locData.blip
        }
    end

    refreshAllBlips()
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= cache.resource then
        return
    end

    for stationId in pairs(ScootBunker.list) do
        ScootBunker.despawn(stationId)
    end

    ScootBlips.clear()
    ScootUI.close()
    ScootPlacement.close()
    ScootAudio.stopAll()
    hideInteractionPrompt()
end)

CreateThread(function()
    Wait(500)
    TriggerServerEvent("scootbunker:requestLocations")
end)

exports("getLocations", function()
    return stations
end)

exports("getNearestStation", function()
    local playerCoords = GetEntityCoords(cache.ped)
    local nearestId = nil
    local nearestDist = nil

    for stationId, stationData in pairs(stations) do
        local dist = #(playerCoords - stationData.coords)
        if not nearestDist or dist < nearestDist then
            nearestDist = dist
            nearestId = stationId
        end
    end

    return nearestId, nearestDist
end)

exports("openStation", function(stationId)
    handleStationInteraction(stationId)
end)

exports("previewStation", function(stationId, delaySeconds, options)
    return ScootCycle.preview(stationId, delaySeconds, options)
end)

exports("clearPreview", function(stationId)
    ScootCycle.clearPreview(stationId)
end)
