local PlacementModule = {
    active = false
}
ScootPlacement = PlacementModule

local ghostObject = nil
local draft = nil
local placedLocations = nil
local isSaving = false
local isTypingInNui = false
local isAimLooking = false
local isLoadingCreator = false
local currentEditStationId = nil
local isPinned = false
local isPreviewRaised = true
local isGroundDetected = false
local pendingRaycastHandle = nil
local lastRaycastTime = 0
local lastStateSendTime = 0
local smoothedCoords = nil
local smoothedHeading = nil
local activeBrowsePage = nil

local function isNumeric(val)
    return type(val) == "number" and val == val
end

local function updateBrowseBlips()
    for i = 1, 12 do
        ScootBlips.remove("__scoot_browse_" .. i)
    end

    if not activeBrowsePage or not draft then
        return
    end

    local baseIndex = (activeBrowsePage - 1) * 12 + 1
    local center = draft.coords
    local rad = math.rad((draft.heading or 0.0) + 90.0)
    local dirX = -math.sin(rad)
    local dirY = math.cos(rad)

    for i = 1, 12 do
        local spriteIndex = baseIndex + i - 1
        if spriteIndex <= 826 then
            local blipX = center.x + (dirX * i * 6.0)
            local blipY = center.y + (dirY * i * 6.0)

            ScootBlips.set("__scoot_browse_" .. i, {
                coords = { x = blipX, y = blipY, z = center.z },
                blip = {
                    sprite = spriteIndex,
                    color = (draft.blip and draft.blip.color) or 3,
                    scale = 0.9,
                    shortRange = false,
                    label = string.format("#%d", spriteIndex)
                }
            })
        end
    end
end

local function updateDraftBlip()
    if not draft then
        ScootBlips.remove("__scoot_draft")
        return
    end

    local blipSettings = draft.blip or {}
    if blipSettings.enabled == false then
        ScootBlips.remove("__scoot_draft")
        return
    end

    ScootBlips.set("__scoot_draft", {
        coords = draft.coords,
        name = draft.name,
        blip = blipSettings
    })
end

local function sendCreatorState()
    if not draft then
        return
    end

    updateDraftBlip()

    SendNUIMessage({
        action = "creatorState",
        draft = draft,
        pinned = isPinned,
        raised = isPreviewRaised,
        groundValid = isGroundDetected,
        browsePage = activeBrowsePage
    })
end

function PlacementModule.close()
    PlacementModule.active = false

    if ghostObject and DoesEntityExist(ghostObject) then
        DeleteEntity(ghostObject)
    end

    if currentEditStationId then
        local station = ScootBunker.list[currentEditStationId]
        if station then
            SetEntityVisible(station.obj, true, false)
            if station.proxy then
                SetEntityCollision(station.proxy, true, true)
            end
        end
    end

    ScootBlips.remove("__scoot_draft")
    activeBrowsePage = nil
    updateBrowseBlips()

    ghostObject = nil
    draft = nil
    currentEditStationId = nil
    pendingRaycastHandle = nil
    isTypingInNui = false
    isAimLooking = false

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = "closeCreator"
    })
end

local function setupDraftStation(stationData)
    if currentEditStationId then
        local station = ScootBunker.list[currentEditStationId]
        if station then
            SetEntityVisible(station.obj, true, false)
            if station.proxy then
                SetEntityCollision(station.proxy, true, true)
            end
        end
    end

    currentEditStationId = nil

    local pedCoords = GetEntityCoords(cache.ped)
    local forward = GetEntityForwardVector(cache.ped) * 3.0
    local initialPos = pedCoords + forward

    draft = {
        name = ScootT("new_station"),
        coords = { x = initialPos.x, y = initialPos.y, z = initialPos.z },
        heading = GetEntityHeading(cache.ped),
        color = ScootColor(ScootConfig.glow and ScootConfig.glow.color),
        blip = {}
    }

    isPinned = false
    isGroundDetected = false

    if stationData then
        draft = {
            id = stationData.id,
            revision = stationData.revision,
            color = stationData.color,
            blip = stationData.blip or {},
            name = stationData.name or ScootT("station"),
            coords = { x = stationData.coords.x, y = stationData.coords.y, z = stationData.coords.z },
            heading = stationData.heading
        }
        isPinned = true
        isGroundDetected = true

        local existingStation = ScootBunker.list[stationData.id]
        if existingStation then
            currentEditStationId = stationData.id
            SetEntityVisible(existingStation.obj, false, false)
            if existingStation.proxy then
                SetEntityCollision(existingStation.proxy, false, false)
            end
        end
    end

    smoothedCoords = nil
    smoothedHeading = nil
    sendCreatorState()
end

local function teleportPlayerToStation(stationData)
    local targetCoords = stationData.coords
    local rad = math.rad(stationData.heading or 0.0)
    local spawnX = targetCoords.x - (math.sin(rad) * 3.0)
    local spawnY = targetCoords.y + (math.cos(rad) * 3.0)
    local playerPed = cache.ped

    DoScreenFadeOut(200)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    SetEntityCoordsNoOffset(playerPed, spawnX, spawnY, targetCoords.z + 1.0, false, false, false)
    RequestCollisionAtCoord(spawnX, spawnY, targetCoords.z)

    local timeout = GetGameTimer() + 6000
    while not HasCollisionLoadedAroundEntity(playerPed) and GetGameTimer() < timeout do
        RequestCollisionAtCoord(spawnX, spawnY, targetCoords.z)
        Wait(50)
    end

    local groundFound, groundZ = GetGroundZFor_3dCoord(spawnX, spawnY, targetCoords.z + 3.0, false)
    local finalZ = (groundFound and groundZ or targetCoords.z) + 0.15

    SetEntityCoordsNoOffset(playerPed, spawnX, spawnY, finalZ, false, false, false)
    SetEntityHeading(playerPed, ((stationData.heading or 0.0) + 180.0) % 360.0)

    smoothedCoords = nil
    smoothedHeading = nil
    DoScreenFadeIn(300)
end

local function saveCurrentDraft(callback)
    if not PlacementModule.active or isSaving or not draft or (not isPinned and not isGroundDetected) then
        if callback then
            callback({
                ok = false,
                error = ScootT("ground_failed")
            })
        end
        return
    end

    if not isPinned then
        isPinned = true
        sendCreatorState()
    end

    isSaving = true
    local ok, response = pcall(lib.callback.await, "scootbunker:saveLocation", false, draft)
    isSaving = false

    if not ok or not response then
        response = {
            ok = false,
            error = ScootT("connection_error")
        }
    end

    if callback then
        callback(response)
    end

    if response.ok then
        lib.notify({
            description = ScootT("saved"),
            type = "success"
        })
        PlacementModule.close()
    else
        SendNUIMessage({
            action = "creatorError",
            error = response.error
        })
    end
end

local function openCreatorSession(selectedStationId)
    if PlacementModule.active or isSaving or isLoadingCreator then
        return
    end

    if GetVehiclePedIsIn(cache.ped, false) ~= 0 then
        ScootBunker.notify(ScootT("exit_vehicle"))
        return
    end

    isLoadingCreator = true
    local ok, response = pcall(lib.callback.await, "scootbunker:creator", false)

    if not ok or not response or not response.ok then
        isLoadingCreator = false
        ScootBunker.notify((response and response.error) or ScootT("connection_error"))
        return
    end

    local modelHash = joaat(ScootAssets.model)
    local loadSuccess = pcall(function()
        lib.requestModel(modelHash, 10000)
        lib.requestAnimDict(ScootAssets.animDict, 10000)
    end)

    isLoadingCreator = false
    if not loadSuccess then
        ScootBunker.notify(ScootT("model_failed"))
        return
    end

    ScootUI.close()
    placedLocations = response.locations

    ghostObject = CreateObjectNoOffset(modelHash, 0.0, 0.0, 0.0, false, false, false)
    if ghostObject == 0 then
        ScootBunker.notify(ScootT("model_failed"))
        return
    end

    SetEntityAlpha(ghostObject, 190, false)
    SetEntityCollision(ghostObject, false, false)
    SetEntityInvincible(ghostObject, true)
    FreezeEntityPosition(ghostObject, true)
    PlayEntityAnim(ghostObject, ScootAssets.animClip, ScootAssets.animDict, 1.0, false, true, false, 0.0, 0)
    Wait(0)
    SetEntityAnimSpeed(ghostObject, ScootAssets.animDict, ScootAssets.animClip, 0.0)
    SetModelAsNoLongerNeeded(modelHash)

    PlacementModule.active = true
    isPreviewRaised = true

    SendNUIMessage({
        action = "openCreator",
        locale = ScootTranslations(),
        theme = ScootTheme(),
        locations = placedLocations,
        presets = (ScootConfig.glow and ScootConfig.glow.presets) or {},
        blips = ScootConfig.blips
    })

    setupDraftStation(selectedStationId and placedLocations[selectedStationId] or nil)

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)

    CreateThread(function()
        local disabledControls = {
            24, 25, 37, 38, 44, 140, 141, 142, 174, 175, 172, 173, 10, 11, 191, 200
        }

        while PlacementModule.active do
            DisablePlayerFiring(PlayerId(), true)

            for i = 1, #disabledControls do
                DisableControlAction(0, disabledControls[i], true)
            end

            if isTypingInNui then
                DisableAllControlActions(0)
                DisableAllControlActions(1)
                DisableAllControlActions(2)
            else
                local isRmbHeld = IsDisabledControlPressed(0, 25)
                if isRmbHeld ~= isAimLooking then
                    isAimLooking = isRmbHeld
                    SetNuiFocus(not isRmbHeld, not isRmbHeld)
                    SetNuiFocusKeepInput(true)
                end

                if not isAimLooking then
                    DisableControlAction(0, 1, true)
                    DisableControlAction(0, 2, true)
                end
            end

            if IsEntityDead(cache.ped) then
                PlacementModule.close()
                break
            end

            local now = GetGameTimer()

            if not isPinned and not isSaving then
                if pendingRaycastHandle then
                    local status, hit, hitCoords = GetShapeTestResult(pendingRaycastHandle)
                    if status ~= 1 then
                        pendingRaycastHandle = nil
                        isGroundDetected = (hit == 1)
                        if isGroundDetected then
                            draft.coords = { x = hitCoords.x, y = hitCoords.y, z = hitCoords.z }
                        end
                    end
                elseif (now - lastRaycastTime) >= 60 then
                    lastRaycastTime = now
                    local camCoords = GetGameplayCamCoord()
                    local camRot = GetGameplayCamRot(2)
                    local pitch = math.rad(camRot.x)
                    local yaw = math.rad(camRot.z)

                    local forward = vec3(
                        -math.sin(yaw) * math.cos(pitch),
                        math.cos(yaw) * math.cos(pitch),
                        math.sin(pitch)
                    )

                    local maxDist = ScootConfig.creator.maxDistance
                    local targetRayEnd = camCoords + (forward * maxDist)

                    pendingRaycastHandle = StartShapeTestRay(
                        camCoords.x, camCoords.y, camCoords.z,
                        targetRayEnd.x, targetRayEnd.y, targetRayEnd.z,
                        17, cache.ped, 7
                    )
                end
            end

            if not isTypingInNui and not isSaving then
                local dtScale = math.min(GetFrameTime(), 0.05) * 60
                local precision = IsControlPressed(0, 21) and (ScootConfig.creator.precisionMultiplier or 1) or 1
                local moveSpeed = ScootConfig.creator.moveStep * dtScale * precision
                local rotateSpeed = ScootConfig.creator.rotateStep * dtScale * precision

                local anyNudge = IsDisabledControlPressed(0, 174)
                    or IsDisabledControlPressed(0, 175)
                    or IsDisabledControlPressed(0, 172)
                    or IsDisabledControlPressed(0, 173)
                    or IsDisabledControlPressed(0, 10)
                    or IsDisabledControlPressed(0, 11)

                if anyNudge and not isPinned and isGroundDetected then
                    isPinned = true
                    sendCreatorState()
                end

                if isPinned then
                    if IsDisabledControlPressed(0, 174) then draft.coords.x = draft.coords.x - moveSpeed end
                    if IsDisabledControlPressed(0, 175) then draft.coords.x = draft.coords.x + moveSpeed end
                    if IsDisabledControlPressed(0, 172) then draft.coords.y = draft.coords.y + moveSpeed end
                    if IsDisabledControlPressed(0, 173) then draft.coords.y = draft.coords.y - moveSpeed end
                    if IsDisabledControlPressed(0, 10) then draft.coords.z = draft.coords.z + moveSpeed end
                    if IsDisabledControlPressed(0, 11) then draft.coords.z = draft.coords.z - moveSpeed end
                end

                if IsDisabledControlPressed(0, 44) then
                    draft.heading = (draft.heading - rotateSpeed) % 360
                end
                if IsDisabledControlPressed(0, 38) then
                    draft.heading = (draft.heading + rotateSpeed) % 360
                end

                if IsDisabledControlJustReleased(0, 191) then
                    if not isPinned then
                        isPinned = isGroundDetected
                        sendCreatorState()
                    else
                        CreateThread(function()
                            saveCurrentDraft()
                        end)
                    end
                end

                if IsDisabledControlJustReleased(0, 200) then
                    PlacementModule.close()
                    break
                end
            end

            local targetPos = draft.coords
            local lerpFactor = 1.0 - math.exp(-18.0 * math.min(GetFrameTime(), 0.1))

            if not smoothedCoords or #(vec3(targetPos.x, targetPos.y, targetPos.z) - smoothedCoords) > 6.0 then
                smoothedCoords = vec3(targetPos.x, targetPos.y, targetPos.z)
                smoothedHeading = draft.heading
            else
                smoothedCoords = smoothedCoords + ((vec3(targetPos.x, targetPos.y, targetPos.z) - smoothedCoords) * lerpFactor)
                local headingDiff = ((draft.heading - smoothedHeading + 540.0) % 360.0) - 180.0
                smoothedHeading = (smoothedHeading + (headingDiff * lerpFactor)) % 360.0
            end

            SetEntityCoordsNoOffset(ghostObject, smoothedCoords.x, smoothedCoords.y, smoothedCoords.z, false, false, false)
            SetEntityHeading(ghostObject, (smoothedHeading + 180.0) % 360)
            SetEntityAnimCurrentTime(ghostObject, ScootAssets.animDict, ScootAssets.animClip, isPreviewRaised and 0.27 or 0.0)

            local arrowRad = math.rad(smoothedHeading)
            local arrowDirX = -math.sin(arrowRad)
            local arrowDirY = math.cos(arrowRad)
            local lineEndX = smoothedCoords.x + (arrowDirX * 4)
            local lineEndY = smoothedCoords.y + (arrowDirY * 4)
            local lineZ = smoothedCoords.z + 0.1

            DrawLine(smoothedCoords.x, smoothedCoords.y, lineZ, lineEndX, lineEndY, lineZ, 0, 229, 180, 255)
            DrawLine(lineEndX, lineEndY, lineZ, lineEndX - (arrowDirX * 0.6) + (arrowDirY * 0.35), lineEndY - (arrowDirY * 0.6) - (arrowDirX * 0.35), lineZ, 0, 229, 180, 255)
            DrawLine(lineEndX, lineEndY, lineZ, lineEndX - (arrowDirX * 0.6) - (arrowDirY * 0.35), lineEndY - (arrowDirY * 0.6) + (arrowDirX * 0.35), lineZ, 0, 229, 180, 255)

            if (now - lastStateSendTime) > 120 then
                lastStateSendTime = now
                sendCreatorState()
            end

            Wait(0)
        end
    end)
end

RegisterCommand(ScootConfig.creator.command, function()
    openCreatorSession()
end, false)

RegisterCommand(ScootConfig.creator.removeCommand, function()
    local ok, response = pcall(lib.callback.await, "scootbunker:creator", false)
    if not ok or not response or not response.ok then
        ScootBunker.notify((response and response.error) or ScootT("connection_error"))
        return
    end

    local playerCoords = GetEntityCoords(cache.ped)
    local closestStationId = nil
    local closestDistance = ScootConfig.creator.maxDistance

    for id, loc in pairs(response.locations) do
        local locCoords = vec3(loc.coords.x, loc.coords.y, loc.coords.z)
        local dist = #(playerCoords - locCoords)
        if not loc.fixed and dist < closestDistance then
            closestDistance = dist
            closestStationId = id
        end
    end

    if closestStationId then
        openCreatorSession(closestStationId)
    else
        ScootBunker.notify(ScootT("no_station"))
    end
end, false)

RegisterNUICallback("creatorTyping", function(data, cb)
    isTypingInNui = (data.active == true)
    SetNuiFocusKeepInput(not isAimLooking and isTypingInNui)
    cb({ ok = true })
end)

RegisterNUICallback("creatorAction", function(data, cb)
    if not PlacementModule.active or isSaving or not draft then
        cb({ ok = false })
        return
    end

    local action = data.action

    if action == "save" then
        saveCurrentDraft(cb)
        return
    end

    if action == "delete" then
        if not draft.id then
            cb({ ok = false })
            return
        end

        isSaving = true
        local ok, response = pcall(lib.callback.await, "scootbunker:deleteLocation", false, {
            id = draft.id,
            revision = draft.revision
        })
        isSaving = false

        if not ok or not response then
            response = { ok = false, error = ScootT("connection_error") }
        end

        cb(response)

        if response.ok then
            PlacementModule.close()
            lib.notify({
                description = ScootT("deleted"),
                type = "success"
            })
        end
        return
    end

    if action == "new" then
        setupDraftStation()
    elseif action == "edit" then
        local station = placedLocations[data.id]
        if station then
            local dist = #(GetEntityCoords(cache.ped) - vec3(station.coords.x, station.coords.y, station.coords.z))
            if dist > ScootConfig.creator.maxDistance then
                teleportPlayerToStation(station)
            end
            if not station.fixed then
                setupDraftStation(station)
            end
        end
    elseif action == "remove" then
        local station = placedLocations[data.id]
        if not station or station.fixed then
            cb({ ok = false, error = ScootT("invalid") })
            return
        end

        local dist = #(GetEntityCoords(cache.ped) - vec3(station.coords.x, station.coords.y, station.coords.z))
        if dist > ScootConfig.creator.maxDistance then
            teleportPlayerToStation(station)
        end

        isSaving = true
        local ok, response = pcall(lib.callback.await, "scootbunker:deleteLocation", false, {
            id = station.id,
            revision = station.revision
        })
        isSaving = false

        if not ok or not response then
            response = { ok = false, error = ScootT("connection_error") }
        end

        if response.ok then
            placedLocations = response.locations or placedLocations
            if draft and draft.id == station.id then
                PlacementModule.close()
            end
            lib.notify({
                description = ScootT("deleted"),
                type = "success"
            })
            SendNUIMessage({
                action = "openCreator",
                locale = ScootTranslations(),
                theme = ScootTheme(),
                locations = placedLocations,
                presets = (ScootConfig.glow and ScootConfig.glow.presets) or {},
                blips = ScootConfig.blips
            })
        end

        cb(response)
        sendCreatorState()
        return
    elseif action == "pin" then
        isPinned = (not isPinned) and isGroundDetected
    elseif action == "preview" then
        isPreviewRaised = not isPreviewRaised
    elseif action == "color" then
        if type(data.value) == "string" then
            draft.color = ScootColor(data.value) or draft.color
        end
    elseif action == "blip" then
        if type(data.field) == "string" then
            draft.blip = draft.blip or {}
            local field = data.field
            local val = data.value

            if field == "enabled" or field == "shortRange" or field == "flash" then
                draft.blip[field] = (val == true)
            elseif field == "sprite" and isNumeric(val) then
                draft.blip.sprite = math.max(1, math.min(5000, math.floor(val)))
            elseif field == "color" and isNumeric(val) then
                draft.blip.color = math.max(0, math.min(85, math.floor(val)))
            elseif field == "scale" and isNumeric(val) then
                draft.blip.scale = math.max(0.1, math.min(2.0, val + 0.0))
            elseif field == "flashInterval" and isNumeric(val) then
                draft.blip.flashInterval = math.max(100, math.min(5000, math.floor(val)))
            elseif field == "label" and type(val) == "string" then
                draft.blip.label = val:sub(1, 40)
            elseif field == "browse" then
                if val == false then
                    activeBrowsePage = nil
                else
                    activeBrowsePage = math.max(1, math.min(math.ceil(68.83333333333333), math.floor(val)))
                end
                updateBrowseBlips()
            end
        end
    elseif action == "name" then
        if type(data.value) == "string" then
            draft.name = data.value:sub(1, 80)
        end
    elseif action == "heading" then
        if isNumeric(data.value) then
            draft.heading = data.value % 360
        end
    elseif action == "coordinate" then
        if (data.axis == "x" or data.axis == "y" or data.axis == "z") and isNumeric(data.value) then
            isPinned = true
            draft.coords[data.axis] = data.value
        end
    elseif action == "ground" then
        local found, groundZ = GetGroundZFor_3dCoord(draft.coords.x, draft.coords.y, draft.coords.z + 2.0, false)
        if found then
            draft.coords.z = groundZ
            isPinned = true
            isGroundDetected = true
        else
            cb({ ok = false, error = ScootT("ground_failed") })
            return
        end
    end

    sendCreatorState()
    cb({ ok = true })
end)
