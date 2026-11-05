

Preview = Preview or {}

---------------------------------------------------------------------
-- State
---------------------------------------------------------------------

local state = {
    active = false,
    handoff = false,     -- true while handing the vehicle over to Garage.TakeOut / Release
    token = 0,           -- incremented to invalidate in-flight Show() calls
    veh = nil,
    model = nil,
    plate = nil,
    spot = nil,
    garage = nil,        -- garage id
    cam = nil,
    origin = nil,        -- vector4: player position before preview started
    center = nil,        -- vector3: camera focus point (vehicle bounding-box center)

    -- camera parameters
    dist = 6.0,
    height = 1.2,
    angle = 35.0,
    tilt = 0.0,
    zoom = 1.0,
    clip = 1.0,          -- current wall-clip factor (smoothed)
    clipTarget = 1.0,
    lastInput = 0,
}

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

local function getConfig()
    return (Config.Garage and Config.Garage.preview) or {}
end

function Preview.Enabled()
    return getConfig().enabled ~= false
end

function Preview.Active()
    return state.active
end

function Preview.HandingOff()
    return state.handoff
end

-- Impound lots are not previewable
local function isPreviewable(garage, menuVehicle)
    if not garage or not menuVehicle then
        return false
    end
    return garage.kind ~= "impound"
end

local function deletePreviewVehicle()
    if state.veh and DoesEntityExist(state.veh) then
        SetEntityAsMissionEntity(state.veh, true, true)
        DeleteVehicle(state.veh)
    end
    state.veh = nil
end

local function releasePreviewModel()
    if state.model then
        SetModelAsNoLongerNeeded(state.model)
    end
    state.model = nil
end

local function deleteEntitySafe(entity)
    if entity and DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteVehicle(entity)
    end
end

local function destroyCamLater(cam, delay)
    SetTimeout(delay, function()
        if DoesCamExist(cam) then
            DestroyCam(cam, false)
        end
    end)
end

---------------------------------------------------------------------
-- Camera
---------------------------------------------------------------------

-- Sets camera distance/height/center from the vehicle's model dimensions
local function computeFraming(vehicle, model)
    local min, max = GetModelDimensions(model)

    local length = math.abs(max.y - min.y)
    local width = math.abs(max.x - min.x)
    local vHeight = math.abs(max.z - min.z)
    local largest = math.max(length, width)

    local distScale = tonumber(getConfig().distance) or 1.0
    state.dist = math.max(4.6, largest * 1.2 + 2.6) * distScale
    state.height = vHeight * 0.5 + math.min(3.5, largest * 0.11) + 0.6

    local center = GetOffsetFromEntityInWorldCoords(
        vehicle,
        (min.x + max.x) * 0.5,
        (min.y + max.y) * 0.5,
        (min.z + max.z) * 0.5
    )
    state.center = vector3(center.x, center.y, center.z)
end

-- World position of the camera. If ignoreClip is true, uses the full
-- (un-clipped) orbit distance - used as the end of the collision probe.
local function getCameraPosition(ignoreClip)
    local rad = math.rad(state.angle)
    local clip = ignoreClip and 1.0 or state.clip

    local radius = state.dist * state.zoom * clip
    local height = (state.height + state.tilt) * (ignoreClip and 1.0 or (0.45 + 0.55 * clip))

    local offset = GetOffsetFromEntityInWorldCoords(
        state.veh,
        math.sin(rad) * radius,
        math.cos(rad) * radius,
        0.0
    )

    return offset + vector3(0.0, 0.0, height)
end

local function updateCamera(cam)
    local pos = getCameraPosition(false)
    SetCamCoord(cam, pos.x, pos.y, pos.z)
    PointCamAtCoord(cam, state.center.x, state.center.y, state.center.z)
end

local function createCamera()
    local fov = tonumber(getConfig().fov) or 40.0

    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", false)
    SetCamFov(cam, fov)
    SetCamUseShallowDofMode(cam, true)
    SetCamNearDof(cam, 0.4)
    SetCamFarDof(cam, state.dist * 2.4)
    SetCamDofStrength(cam, 0.5)
    updateCamera(cam)

    return cam
end

-- Per-frame loop: auto-orbit when idle, wall-collision probe, camera update
local function startCameraThread()
    CreateThread(function()
        local lastTime = GetGameTimer()
        local orbitSpeed = tonumber(getConfig().orbitSpeed) or 6.0
        local probe = nil
        local nextProbeAt = 0

        while state.active do
            local now = GetGameTimer()
            local dt = (now - lastTime) / 1000.0
            lastTime = now

            if state.cam and state.veh and DoesEntityExist(state.veh) then
                -- auto-rotate after 2.5s without input
                if now - state.lastInput > 2500 then
                    state.angle = (state.angle + orbitSpeed * dt) % 360.0
                end

                if probe then
                    local status, hit, hitCoords = GetShapeTestResult(probe)
                    if status ~= 1 then -- 1 = still pending
                        probe = nil
                        if status == 2 and (hit == true or hit == 1) and hitCoords then
                            local fullPos = getCameraPosition(true)
                            local fullDist = #(fullPos - state.center)
                            local hitDist = #(hitCoords - state.center) - 0.45
                            state.clipTarget = Utils.Clamp(hitDist / math.max(0.1, fullDist), 0.25, 1.0)
                        else
                            state.clipTarget = 1.0
                        end
                    end
                elseif nextProbeAt <= now then
                    local fullPos = getCameraPosition(true)
                    probe = StartShapeTestLosProbe(
                        state.center.x, state.center.y, state.center.z,
                        fullPos.x, fullPos.y, fullPos.z,
                        17, state.veh, 7
                    )
                    nextProbeAt = now + 100
                end

                -- smooth clip toward target
                state.clip = state.clip + (state.clipTarget - state.clip) * math.min(1.0, dt * 5.0)

                updateCamera(state.cam)
                SetUseHiDof()
            end

            HideHudAndRadarThisFrame()
            Wait(0)
        end
    end)
end

---------------------------------------------------------------------
-- Preview vehicle spawning
---------------------------------------------------------------------

local function spawnPreviewVehicle(model, spot, props, plate)
    local veh = CreateVehicle(model, spot.x, spot.y, Garage.SpawnZ(model, spot), spot.w, false, false)

    -- wait up to 3s for the entity to exist
    local startedAt = GetGameTimer()
    while not DoesEntityExist(veh) and GetGameTimer() - startedAt < 3000 do
        Wait(0)
    end

    if not DoesEntityExist(veh) then
        return nil
    end

    SetEntityAsMissionEntity(veh, true, true)
    Props.Set(veh, props or {})
    SetVehicleNumberPlateText(veh, plate or "")

    local class = GetVehicleClass(veh)
    local isBoat = class == 14

    if not isBoat then
        SetVehicleOnGroundProperly(veh)
    end
    if class == 15 then -- helicopters
        SetHeliBladesSpeed(veh, 0.0)
    end

    SetVehicleEngineOn(veh, false, true, true)
    SetVehicleLights(veh, 2)
    SetEntityInvincible(veh, true)
    SetVehicleDoorsLocked(veh, 4)
    SetVehRadioStation(veh, "OFF")

    if isBoat then
        SetEntityDynamic(veh, true)
        ActivatePhysics(veh)
        if SetBoatFrozenWhenAnchored then
            SetBoatFrozenWhenAnchored(veh, false)
        end
        if _ENV["SetBoatRemainsAnchoredWhilePlayerIsDriver"] then
            _ENV["SetBoatRemainsAnchoredWhilePlayerIsDriver"](veh, true)
        end
        SetBoatAnchor(veh, true)
    else
        FreezeEntityPosition(veh, true)
    end

    return veh
end

---------------------------------------------------------------------
-- Preview.Show
---------------------------------------------------------------------

function Preview.Show(plate, requestedSpot)
    if not Preview.Enabled() then
        return false, "preview_disabled"
    end

    if not Garage.Open or state.handoff then
        return false, nil
    end

    local garage = Garage.ById[Garage.Current]
    local menuVehicle = Garage.MenuVehicle(plate)

    if not isPreviewable(garage, menuVehicle) then
        return false, "preview_disabled"
    end

    local garageId = Garage.Current
    local model = tonumber(menuVehicle.props and menuVehicle.props.model)
        or tonumber(menuVehicle.model)
        or 0

    state.token = state.token + 1
    local myToken = state.token

    -- NOTE: the decompiler dropped the comparison logic in this closure;
    -- this is a reconstruction of the likely intent. Verify against behavior.
    local function stillValid()
        return Garage.Open
            and myToken == state.token
            and Garage.Current == garageId
            and isPreviewable(Garage.ById[garageId], Garage.MenuVehicle(plate))
    end

    local previousVeh = state.veh
    local previousSpot = state.spot

    local function discardPrevious()
        deleteEntitySafe(previousVeh)
        if state.veh == previousVeh then
            state.veh = nil
        end
        previousVeh = nil
    end

    -- pick a spot
    requestedSpot = tonumber(requestedSpot) or 0
    local spot, spotError
    if previousSpot and (requestedSpot == 0 or requestedSpot == previousSpot) then
        spot = previousSpot
    else
        spot, spotError = Garage.PickSpot(garage, requestedSpot)
    end

    if not spot then
        return false, spotError
    end

    if model == 0 or not Garage.LoadModel(model) then
        return false, "model_invalid"
    end

    local function abortCleanup()
        if state.model ~= model then
            SetModelAsNoLongerNeeded(model)
        end
        if myToken == state.token then
            Preview.Stop(true)
        end
    end

    if not stillValid() then
        abortCleanup()
        return false, nil
    end

    local ped = PlayerPedId()

    -- remember where the player was and hide them
    if not state.active then
        local coords = GetEntityCoords(ped)
        state.origin = vector4(coords.x, coords.y, coords.z, GetEntityHeading(ped))
        NetworkSetEntityInvisibleToNetwork(ped, true)
    end

    -- park the old preview vehicle while the new one spawns
    if previousVeh and DoesEntityExist(previousVeh) then
        SetEntityCollision(previousVeh, false, false)
        FreezeEntityPosition(previousVeh, true)
    end

    local newVeh = spawnPreviewVehicle(model, garage.spots[spot], menuVehicle.props, menuVehicle.plate)

    -- state changed while we were spawning
    if not stillValid() then
        deleteEntitySafe(newVeh)
        abortCleanup()
        return false, nil
    end

    -- spawn failed: restore the previous vehicle
    if not newVeh then
        if previousVeh and DoesEntityExist(previousVeh) then
            SetEntityCollision(previousVeh, true, true)
            if GetVehicleClass(previousVeh) == 14 then
                FreezeEntityPosition(previousVeh, false)
            end
        end
        if not state.active then
            NetworkSetEntityInvisibleToNetwork(ped, false)
        end
        return false, "spawn_failed"
    end

    -- commit the new vehicle
    discardPrevious()
    if state.model and state.model ~= model then
        releasePreviewModel()
    end

    state.spot = spot
    state.plate = plate
    state.model = model
    state.veh = newVeh
    state.garage = garageId

    TaskWarpPedIntoVehicle(ped, newVeh, -1)
    computeFraming(newVeh, model)

    state.angle = 35.0
    state.tilt = 0.0
    state.zoom = 1.0
    state.clip = 1.0
    state.clipTarget = 1.0

    local cam = createCamera()

    if not state.active then
        state.active = true
        SetCamActive(cam, true)
        RenderScriptCams(true, true, 900, true, true)
        state.cam = cam
        startCameraThread()
    else
        local oldCam = state.cam
        SetCamActiveWithInterp(cam, oldCam, 900, 1, 1)
        state.cam = cam

        SetTimeout(950, function()
            if oldCam and DoesCamExist(oldCam) and oldCam ~= state.cam then
                DestroyCam(oldCam, false)
            end
        end)
    end

    return true, spot
end

---------------------------------------------------------------------
-- Preview.Orbit (mouse/touch input from NUI)
---------------------------------------------------------------------

function Preview.Orbit(dx, dy, dz)
    if not state.active then
        return
    end

    state.angle = (state.angle - (tonumber(dx) or 0) * 0.3) % 360.0

    state.tilt = Utils.Clamp(
        state.tilt + (tonumber(dy) or 0) * 0.012,
        -state.height + 0.35,
        state.height * 1.6
    )

    state.zoom = Utils.Clamp(
        state.zoom + (tonumber(dz) or 0) * 0.001,
        0.6,
        1.5
    )

    state.lastInput = GetGameTimer()
end

---------------------------------------------------------------------
-- Preview.Stop
---------------------------------------------------------------------

function Preview.Stop(restorePlayer)
    state.token = state.token + 1

    local ped = PlayerPedId()

    if restorePlayer and state.origin then
        SetEntityCoords(ped, state.origin.x, state.origin.y, state.origin.z - 0.98, false, false, false, false)
        SetEntityHeading(ped, state.origin.w)
    end

    deletePreviewVehicle()
    releasePreviewModel()

    if state.cam then
        RenderScriptCams(false, true, restorePlayer and 700 or 900, true, true)
        destroyCamLater(state.cam, 1000)
    end

    if state.origin then
        NetworkSetEntityInvisibleToNetwork(ped, false)
    end

    state.garage = nil
    state.origin = nil
    state.spot = nil
    state.plate = nil
    state.cam = nil
    state.handoff = false
    state.active = false
end

---------------------------------------------------------------------
-- Preview.Confirm (take out / release the previewed vehicle)
---------------------------------------------------------------------

function Preview.Confirm(plate, account)
    if not (state.active and not state.handoff and plate == state.plate) then
        return
    end

    local garage = nil
    if Garage.Open and Garage.Current == state.garage then
        garage = Garage.ById[Garage.Current]
    end

    local stillAllowed = Preview.Enabled()
        and isPreviewable(garage, Garage.MenuVehicle(plate))

    if not stillAllowed then
        Preview.Stop(true)
        if Garage.Open then
            Client.NUI("preview:ended", {})
        end
        return
    end

    state.handoff = true

    local veh = state.veh
    local boatZ = nil

    if veh and DoesEntityExist(veh) then
        SetEntityCollision(veh, false, false)
        FreezeEntityPosition(veh, true)
        if GetVehicleClass(veh) == 14 then
            boatZ = GetEntityCoords(veh).z
        end
    end

    local options = {
        spot = state.spot,
        z = boatZ,
        seamless = true,
        beforeWarp = deletePreviewVehicle,
        onDone = function(success)
            if success then
                Preview.Stop(false)
            else
                state.handoff = false
                Preview.Stop(true)
                if Garage.Open then
                    Client.NUI("preview:ended", {})
                end
            end
        end,
    }

    if garage.kind == "impound" then
        Garage.Release(plate, state.spot, account, options)
    else
        Garage.TakeOut(plate, state.spot, options)
    end
end

---------------------------------------------------------------------
-- NUI callbacks
---------------------------------------------------------------------

RegisterNUICallback("preview:show", function(data, cb)
    CreateThread(function()
        local ok, result = Preview.Show(data and data.plate, data and data.spot)

        if ok then
            cb({ ok = true, spot = result })
        else
            cb({
                ok = false,
                error = result,
                message = result and _U(result) or nil,
            })
        end
    end)
end)

RegisterNUICallback("preview:orbit", function(data, cb)
    Preview.Orbit(data and data.dx, data and data.dy, data and data.dz)
    cb(1)
end)

RegisterNUICallback("preview:stop", function(_, cb)
    if not state.handoff then
        Preview.Stop(true)
    end
    cb(1)
end)

RegisterNUICallback("preview:confirm", function(data, cb)
    cb(1)
    if data and data.plate then
        Preview.Confirm(data.plate, data.account)
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end
    Preview.Stop(true)
end)

