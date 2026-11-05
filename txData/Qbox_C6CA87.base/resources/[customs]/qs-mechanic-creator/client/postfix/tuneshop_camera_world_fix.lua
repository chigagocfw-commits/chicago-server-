-- Camera tuneshop: solo PointCamAtEntity (mai ricreare cam in loop — CreateTuneshopCamera distrugge la cam)

local function getVehicle()
    local v = _G.tuneshopTargetVehicle
    if v and v ~= 0 and DoesEntityExist(v) then
        return v
    end
    local ped = PlayerPedId()
    if ped and ped ~= 0 then
        v = GetVehiclePedIsIn(ped, false)
        if v and v ~= 0 and DoesEntityExist(v) then
            return v
        end
    end
    return nil
end

local function getCam()
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

local function defaultCamBehindVehicle(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then
        return
    end
    local cam = getCam()
    if not cam and type(CreateTuneshopCamera) == 'function' then
        cam = CreateTuneshopCamera(vehicle)
        if cam and cam ~= -1 then
            _G.QsTuneshopScriptCam = cam
        end
        return
    end
    if not cam then
        return
    end

    local vc = GetEntityCoords(vehicle)
    if not vc then
        return
    end
    local vx, vy, vz = tonumber(vc.x), tonumber(vc.y), tonumber(vc.z)
    if not vx or not vy or not vz then
        return
    end

    local heading = tonumber(GetEntityHeading(vehicle)) or 0.0
    local rad = math.rad(heading)
    local sinH = math.sin(rad)
    local cosH = math.cos(rad)
    local backX = -sinH * 3.2 + cosH * 2.8
    local backY = -cosH * 3.2 - sinH * 2.8

    SetCamCoord(cam, vx + backX, vy + backY, vz + 0.6)
    PointCamAtEntity(cam, vehicle, 0.0, 0.0, 0.0, true)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)
end

local function ensureTuneshopCamera(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then
        return
    end
    local cam = getCam()
    if not cam then
        defaultCamBehindVehicle(vehicle)
        return
    end

    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)

    if _G.QsTuneshopFreelookActive then
        return
    end

    local vc = GetEntityCoords(vehicle)
    local cc = GetCamCoord(cam)
    if not vc or not cc then
        PointCamAtEntity(cam, vehicle, 0.0, 0.0, 0.0, true)
        return
    end

    local vx, vy, vz = tonumber(vc.x), tonumber(vc.y), tonumber(vc.z)
    local cx, cy, cz = tonumber(cc.x), tonumber(cc.y), tonumber(cc.z)
    if not vx or not vy or not vz or not cx or not cy or not cz then
        PointCamAtEntity(cam, vehicle, 0.0, 0.0, 0.0, true)
        return
    end

    if cz < vz - 4.0 then
        defaultCamBehindVehicle(vehicle)
        return
    end

    local dx, dy, dz = cx - vx, cy - vy, cz - vz
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    if dist < 0.5 or dist > 30.0 or dist ~= dist then
        defaultCamBehindVehicle(vehicle)
        return
    end

    PointCamAtEntity(cam, vehicle, 0.0, 0.0, 0.0, true)
end

CreateThread(function()
    while type(CreateTuneshopCamera) ~= 'function' do
        Wait(200)
    end
    local _create = CreateTuneshopCamera
    CreateTuneshopCamera = function(vehicle)
        if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
            return nil
        end
        local cam = _create(vehicle)
        if cam and cam ~= -1 then
            _G.QsTuneshopScriptCam = cam
        end
        return cam
    end
end)

CreateThread(function()
    while true do
        if _G.QsTuneshopSuppressFocusPos then
            Wait(250)
            local vehicle = getVehicle()
            if vehicle then
                ensureTuneshopCamera(vehicle)
            end
        else
            Wait(500)
        end
    end
end)
