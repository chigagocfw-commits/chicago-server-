-- Freelook tuneshop (SHIFT): orbit sul veicolo — NO SetFocusPosAndVel (causa camera sotto mappa)

local freelookLoopRunning = false
local PITCH_MIN = -12.0
local PITCH_MAX = 40.0
local ORBIT_DIST = 4.5
local ORBIT_DIST_MIN = 2.8
local ORBIT_DIST_MAX = 8.0

local function getTuneshopVehicle()
    if _G.tuneshopTargetVehicle and _G.tuneshopTargetVehicle ~= 0 and DoesEntityExist(_G.tuneshopTargetVehicle) then
        return _G.tuneshopTargetVehicle
    end
    local ped = PlayerPedId()
    if not ped or ped == 0 then return nil end
    local veh = GetVehiclePedIsIn(ped, false)
    if veh and veh ~= 0 and DoesEntityExist(veh) then
        return veh
    end
    return nil
end

local function getVehicleCenter(vehicle)
    local c = GetEntityCoords(vehicle)
    if not c then return nil end
    local x, y, z = tonumber(c.x), tonumber(c.y), tonumber(c.z)
    if not x or not y or not z then return nil end
    return x, y, z + 0.45
end

local function getTuneshopScriptCam()
    local cam = _G.QsTuneshopScriptCam
    if cam and cam ~= -1 and DoesCamExist(cam) then
        return cam
    end
    cam = GetRenderingCam()
    if cam and cam ~= -1 and DoesCamExist(cam) then
        _G.QsTuneshopScriptCam = cam
        return cam
    end
    return nil
end

local function saveCamSnapshot(cam)
    if not cam or not DoesCamExist(cam) then return end
    local c = GetCamCoord(cam)
    local rx, ry, rz = GetCamRot(cam, 2)
    _G.QsTuneshopCamSnapshot = {
        position = c,
        rotation = { x = rx, y = ry, z = rz },
        fov = GetCamFov(cam),
    }
end

-- Stessa formula orbit di tunes.lua (client/modules/vehicle/tunes.lua)
function QsTuneshopApplyFreelookCam(cam, vehicle)
    if not cam or not DoesCamExist(cam) or not vehicle or not DoesEntityExist(vehicle) then
        return
    end
    local tx, ty, tz = getVehicleCenter(vehicle)
    if not tx then return end

    local yaw = tonumber(_G.QsFreelookYaw) or 0.0
    local pitch = tonumber(_G.QsFreelookPitch) or -8.0
    local dist = tonumber(_G.QsFreelookDist) or ORBIT_DIST
    pitch = math.max(PITCH_MIN, math.min(PITCH_MAX, pitch))
    dist = math.max(ORBIT_DIST_MIN, math.min(ORBIT_DIST_MAX, dist))

    local pr = math.rad(pitch)
    local yr = math.rad(yaw)
    local cosP = math.cos(pr)
    local sinY = math.sin(yr)
    local cosY = math.cos(yr)

    local ring = dist * cosP
    local offX = ring * sinY
    local offY = ring * cosY
    local offZ = dist * math.sin(pr)

    SetCamCoord(cam, tx + offX, ty + offY, tz + offZ + 0.35)
    PointCamAtCoord(cam, tx, ty, tz)
end

local function defaultOrbitFromVehicle(vehicle)
    local tx, ty, tz = getVehicleCenter(vehicle)
    if not tx then return end
    local heading = tonumber(GetEntityHeading(vehicle)) or 0.0
    _G.QsFreelookYaw = heading + 135.0
    _G.QsFreelookPitch = -8.0
    _G.QsFreelookDist = ORBIT_DIST
end

local function initOrbitFromCam(cam, vehicle)
    local tx, ty, tz = getVehicleCenter(vehicle)
    if not tx or not cam or not DoesCamExist(cam) then
        defaultOrbitFromVehicle(vehicle)
        return
    end
    local cc = GetCamCoord(cam)
    if not cc then
        defaultOrbitFromVehicle(vehicle)
        return
    end
    local cx, cy, cz = tonumber(cc.x), tonumber(cc.y), tonumber(cc.z)
    if not cx or not cy or not cz then
        defaultOrbitFromVehicle(vehicle)
        return
    end

    if cz < tz - 3.0 then
        defaultOrbitFromVehicle(vehicle)
        return
    end

    local dx, dy, dz = cx - tx, cy - ty, cz - tz
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    if dist < 0.001 or dist ~= dist then
        defaultOrbitFromVehicle(vehicle)
        return
    end
    if dist < ORBIT_DIST_MIN then dist = ORBIT_DIST end
    if dist > ORBIT_DIST_MAX then dist = ORBIT_DIST_MAX end

    _G.QsFreelookDist = dist
    _G.QsFreelookYaw = math.deg(math.atan(dx, dy))
    local ratio = math.max(-1.0, math.min(1.0, dz / dist))
    _G.QsFreelookPitch = math.max(PITCH_MIN, math.min(PITCH_MAX, math.deg(math.asin(ratio))))
end

function QsTuneshopInitFreelookOrbit()
    local vehicle = getTuneshopVehicle()
    if not vehicle then return end

    local cam = getTuneshopScriptCam()
    if not cam and type(CreateTuneshopCamera) == 'function' then
        cam = CreateTuneshopCamera(vehicle)
        if cam then
            _G.QsTuneshopScriptCam = cam
        end
    end
    if not cam then return end

    saveCamSnapshot(cam)
    initOrbitFromCam(cam, vehicle)

    RenderScriptCams(true, false, 0, true, true)
    SetCamActive(cam, true)
    QsTuneshopApplyFreelookCam(cam, vehicle)
end

local function restoreTuneshopCamera()
    local vehicle = getTuneshopVehicle()
    local cam = getTuneshopScriptCam()
    if not cam and vehicle and type(CreateTuneshopCamera) == 'function' then
        cam = CreateTuneshopCamera(vehicle)
        if cam then
            _G.QsTuneshopScriptCam = cam
        end
    end

    if cam and DoesCamExist(cam) and vehicle then
        local snap = _G.QsTuneshopCamSnapshot
        if snap and snap.position then
            local p = snap.position
            local px, py, pz = tonumber(p.x), tonumber(p.y), tonumber(p.z)
            local tx, ty, tz = getVehicleCenter(vehicle)
            if px and py and pz and tz and pz >= tz - 2.0 then
                SetCamCoord(cam, px, py, pz)
                if snap.rotation then
                    SetCamRot(cam, snap.rotation.x, snap.rotation.y, snap.rotation.z, 2)
                end
                if snap.fov then
                    SetCamFov(cam, snap.fov)
                end
            else
                pcall(CreateTuneshopCamera, vehicle)
                cam = getTuneshopScriptCam()
            end
        end
        if cam and DoesCamExist(cam) then
            RenderScriptCams(true, false, 0, true, true)
            SetCamActive(cam, true)
            PointCamAtEntity(cam, vehicle, 0.0, 0.0, 0.0, true)
        end
    elseif type(QsRestoreTuneshopCameraAfterFreelook) == 'function' then
        pcall(QsRestoreTuneshopCameraAfterFreelook)
    end

end

local function readLookAxis()
    local mx = GetDisabledControlNormal(0, 1)
    local my = GetDisabledControlNormal(0, 2)
    if math.abs(mx) < 0.001 then
        mx = GetControlNormal(0, 1)
    end
    if math.abs(my) < 0.001 then
        my = GetControlNormal(0, 2)
    end
    return mx, my
end

local function startFreelookLoop()
    if freelookLoopRunning then return end
    freelookLoopRunning = true

    CreateThread(function()
        while _G.QsTuneshopFreelookActive do
            Wait(0)

            local vehicle = getTuneshopVehicle()
            if not vehicle then
                _G.QsTuneshopFreelookActive = false
                break
            end

            local cam = getTuneshopScriptCam()
            if not cam then
                Wait(50)
                goto continue
            end

            RenderScriptCams(true, false, 0, true, true)
            SetCamActive(cam, true)

            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 106, true)

            local mx, my = readLookAxis()
            local yaw = tonumber(_G.QsFreelookYaw) or 0.0
            local pitch = tonumber(_G.QsFreelookPitch) or -8.0
            yaw = yaw + (mx * -6.0)
            pitch = pitch + (my * -6.0)
            pitch = math.max(PITCH_MIN, math.min(PITCH_MAX, pitch))
            _G.QsFreelookYaw = yaw
            _G.QsFreelookPitch = pitch
            if not _G.QsFreelookDist then
                _G.QsFreelookDist = ORBIT_DIST
            end

            QsTuneshopApplyFreelookCam(cam, vehicle)

            if IsControlJustPressed(0, 21) then
                _G.QsTuneshopFreelookActive = false
                SendNUIMessage({ type = 'exitFreelook' })
                break
            end

            ::continue::
        end

        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
        restoreTuneshopCamera()
        _G.QsFreelookYaw = nil
        _G.QsFreelookPitch = nil
        _G.QsFreelookDist = nil
        freelookLoopRunning = false
    end)
end

local function onFreelookEnable()
    _G.QsTuneshopFreelookActive = true
    SetNuiFocus(true, false)
    SetNuiFocusKeepInput(true)
    SetPlayerControl(PlayerId(), true, 0)
    QsTuneshopInitFreelookOrbit()
    startFreelookLoop()
end

local function onFreelookDisable()
    _G.QsTuneshopFreelookActive = false
end

CreateThread(function()
    while not RegisterNUICallback do
        Wait(100)
    end
    Wait(500)

    RegisterNUICallback('toggleFreelook', function(data, cb)
        local enable = data and (data.enable == true or data.enable == 1 or data.enable == 'true')
        if enable then
            onFreelookEnable()
        else
            onFreelookDisable()
        end
        if cb then
            cb({ status = 'success' })
        end
    end)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    _G.QsTuneshopFreelookActive = false
    _G.QsTuneshopScriptCam = nil
end)
