local frameDurationMs = 1000.0 / ScootCurves.fps
local totalDurationMs = (ScootCurves.frames - 1) * frameDurationMs
local activePreviews = {}

local function getFrameFromElapsed(elapsedMs)
    local frameIndex = math.floor(elapsedMs / frameDurationMs) + 1
    if frameIndex < 1 then
        return 1
    end
    if frameIndex > ScootCurves.frames then
        return ScootCurves.frames
    end
    return frameIndex
end

local function getForkWorldCoords(bunkerObj, forkYOffset)
    local rest = ScootAssets.scooterRest
    return GetOffsetFromEntityInWorldCoords(bunkerObj, rest.x, rest.y + forkYOffset, rest.z)
end

local function getVehicleReleaseYOffset(vehicleModel)
    local bunkerMin = GetModelDimensions(joaat(ScootAssets.model))
    local vehMin, vehMax = GetModelDimensions(vehicleModel)

    local bunkerFrontY = bunkerMin.y < 0.0 and bunkerMin.y or -1.52
    local vehLengthY = (vehMax.y - vehMin.y) > 0.0 and (vehMax.y - vehMin.y) or 1.8

    return bunkerFrontY - (vehLengthY * 0.5) - 0.35
end

local function releaseVehicle(bunkerObj, vehicle, plate, vehicleModel)
    if not vehicle or not DoesEntityExist(vehicle) then
        return
    end

    local releaseY = math.min(
        ScootAssets.scooterRest.y + ScootCurves.forkY[ScootCurves.releaseFrame],
        getVehicleReleaseYOffset(vehicleModel)
    )

    local releaseCoords = GetOffsetFromEntityInWorldCoords(
        bunkerObj,
        ScootAssets.scooterRest.x,
        releaseY,
        ScootAssets.scooterRest.z
    )

    SetEntityCoordsNoOffset(vehicle, releaseCoords.x, releaseCoords.y, releaseCoords.z, false, false, false)
    FreezeEntityPosition(vehicle, false)
    SetEntityCollision(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, true, true, false)
    ScootBunker.debug(string.format("release y=%.2f at %.2f %.2f %.2f", releaseY, releaseCoords.x, releaseCoords.y, releaseCoords.z))
    SetEntityVisible(vehicle, true, false)
end

local function runDispenseCycle(bunkerData, startTime, isRenter, netId, plate, previewState)
    local bunkerObj = bunkerData.obj

    if not ScootBunker.ensureAnim(bunkerData) then
        error(ScootT("animation_failed"))
    end

    ScootBunker.setPhase(bunkerObj, 0.0)
    ScootBunker.setSpeed(bunkerObj, 1.0)

    local vehicle = nil
    local released = false
    local scooterModelHash = ScootConfig.scooterModel and joaat(ScootConfig.scooterModel)
    local previousFrame = 0
    local cycleEndTime = GetGameTimer() + totalDurationMs + 3000
    local soundCoords = bunkerData.coords + vec3(0.0, 0.0, 0.9)

    ScootBunker.debug(string.format("cycle start renter=%s phase=%.3f playing=%s", tostring(isRenter), ScootBunker.phaseOf(bunkerObj), tostring(IsEntityPlayingAnim(bunkerObj, ScootAssets.animDict, ScootAssets.animClip, 3))))

    while DoesEntityExist(bunkerObj) and GetGameTimer() < cycleEndTime do
        local elapsedMs = GetGameTimer() - startTime
        if elapsedMs >= totalDurationMs then
            break
        end

        local expectedPhase = elapsedMs / totalDurationMs
        local currentPhase = ScootBunker.phaseOf(bunkerObj)

        if currentPhase < 0.0 or math.abs(currentPhase - expectedPhase) > 0.03 then
            ScootBunker.setPhase(bunkerObj, expectedPhase)
            ScootBunker.setSpeed(bunkerObj, 1.0)
        end

        local currentFrame = getFrameFromElapsed(elapsedMs)
        ScootBunker.moveCollision(bunkerData, ScootCurves.rootZ[currentFrame])

        if ScootConfig.sounds then
            for i = 1, #ScootConfig.sounds do
                local cue = ScootConfig.sounds[i]
                if previousFrame < cue.frame and currentFrame >= cue.frame then
                    ScootAudio.play(cue.file, soundCoords, cue.volume, cue.length)
                end
            end
        end

        if previewState and not vehicle and not released and scooterModelHash then
            if currentFrame >= ScootCurves.spawnFrame then
                if lib.requestModel(scooterModelHash, 5000) then
                    local spawnCoords = getForkWorldCoords(bunkerObj, ScootCurves.forkY[currentFrame])
                    local spawnHeading = (GetEntityHeading(bunkerObj) + 180.0) % 360.0
                    local createdVeh = CreateVehicle(scooterModelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnHeading, false, false)
                    SetModelAsNoLongerNeeded(scooterModelHash)

                    if createdVeh ~= 0 then
                        vehicle = createdVeh
                        previewState.vehicle = vehicle
                        SetEntityCollision(vehicle, false, false)
                        SetVehicleNeedsToBeHotwired(vehicle, false)
                        SetVehicleNumberPlateText(vehicle, plate or "SCOOT")
                        SetVehicleEngineOn(vehicle, false, true, true)
                    end
                end
            end
        end

        if not vehicle and not released and netId then
            if NetworkDoesEntityExistWithNetworkId(netId) then
                local resolvedVeh = NetToVeh(netId)
                if resolvedVeh ~= 0 then
                    vehicle = resolvedVeh
                    SetEntityVisible(vehicle, currentFrame >= ScootCurves.spawnFrame, false)
                    SetEntityCollision(vehicle, false, false)
                    SetVehicleNeedsToBeHotwired(vehicle, false)
                    if plate then
                        SetVehicleNumberPlateText(vehicle, plate)
                    end
                end
            end
        end

        if vehicle and DoesEntityExist(vehicle) then
            if currentFrame >= ScootCurves.spawnFrame then
                SetEntityVisible(vehicle, true, false)
            end

            if NetworkHasControlOfEntity(vehicle) then
                if currentFrame < ScootCurves.releaseFrame then
                    FreezeEntityPosition(vehicle, true)
                    local forkPos = getForkWorldCoords(bunkerObj, ScootCurves.forkY[currentFrame])
                    SetEntityCoordsNoOffset(vehicle, forkPos.x, forkPos.y, forkPos.z, false, false, false)
                    SetEntityHeading(vehicle, (GetEntityHeading(bunkerObj) + 180.0) % 360.0)
                elseif not released then
                    releaseVehicle(bunkerObj, vehicle, plate, scooterModelHash)
                end
            end

            if currentFrame >= ScootCurves.releaseFrame then
                SetEntityVisible(vehicle, true, false)
                SetEntityCollision(vehicle, true, true)
                FreezeEntityPosition(vehicle, false)

                if isRenter and ScootConfig.warpIntoScooter and not released then
                    TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)
                end

                released = true
            end
        end

        previousFrame = currentFrame
        Wait(0)
    end

    if vehicle and DoesEntityExist(vehicle) then
        SetEntityVisible(vehicle, true, false)
        SetEntityCollision(vehicle, true, true)
        FreezeEntityPosition(vehicle, false)

        if not released and NetworkHasControlOfEntity(vehicle) then
            releaseVehicle(bunkerObj, vehicle, plate, scooterModelHash)
        end
    end

    ScootBunker.moveCollision(bunkerData, ScootCurves.rootZ[1])

    if DoesEntityExist(bunkerObj) then
        ScootBunker.debug(string.format("cycle end phase=%.3f", ScootBunker.phaseOf(bunkerObj)))
        ScootBunker.setSpeed(bunkerObj, 0.0)
        ScootBunker.setPhase(bunkerObj, 0.0)
    end
end

RegisterNetEvent("scootbunker:playCycle", function(stationId, renterServerId, vehicleNetId, plate)
    if source ~= 65535 then
        return
    end

    local bunkerData = ScootBunker.list[stationId]
    if not bunkerData or bunkerData.busy or not DoesEntityExist(bunkerData.obj) then
        return
    end

    bunkerData.busy = true
    local isRenter = (renterServerId == cache.serverId)

    local success, err = xpcall(
        runDispenseCycle,
        debug.traceback,
        bunkerData,
        GetGameTimer(),
        isRenter,
        vehicleNetId,
        plate,
        nil
    )

    bunkerData.busy = false

    if not success then
        ScootBunker.debug(err)
        if vehicleNetId and NetworkDoesEntityExistWithNetworkId(vehicleNetId) then
            local veh = NetToVeh(vehicleNetId)
            SetEntityVisible(veh, true, false)
            SetEntityCollision(veh, true, true)
            FreezeEntityPosition(veh, false)
        end
    end
end)

local CycleModule = {}

function CycleModule.preview(stationId, delaySeconds, options)
    local bunkerData = ScootBunker.list[stationId]
    if not bunkerData or bunkerData.busy or not DoesEntityExist(bunkerData.obj) then
        return false
    end

    local opts = options or {}
    local previewState = opts.scooter ~= false and {} or nil

    CycleModule.clearPreview(stationId)

    CreateThread(function()
        if delaySeconds and delaySeconds > 0 then
            Wait(math.floor(delaySeconds * 1000))
        end

        local station = ScootBunker.list[stationId]
        if not station or station.busy or not DoesEntityExist(station.obj) then
            return
        end

        station.busy = true
        xpcall(runDispenseCycle, debug.traceback, station, GetGameTimer(), false, nil, nil, previewState)
        station.busy = false

        if not previewState or not previewState.vehicle then
            return
        end

        activePreviews[stationId] = previewState.vehicle

        if opts.keep then
            return
        end

        local cleanupTimeoutSec = opts.cleanup or 45
        SetTimeout(math.floor(cleanupTimeoutSec * 1000), function()
            if activePreviews[stationId] == previewState.vehicle then
                CycleModule.clearPreview(stationId)
            end
        end)
    end)

    return true
end

function CycleModule.clearPreview(stationId)
    local previewVehicle = activePreviews[stationId]
    if previewVehicle and DoesEntityExist(previewVehicle) then
        if IsVehicleSeatFree(previewVehicle, -1) then
            DeleteEntity(previewVehicle)
        end
    end
    activePreviews[stationId] = nil
end

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= cache.resource then
        return
    end
    for stationId in pairs(activePreviews) do
        CycleModule.clearPreview(stationId)
    end
end)

ScootCycle = CycleModule
