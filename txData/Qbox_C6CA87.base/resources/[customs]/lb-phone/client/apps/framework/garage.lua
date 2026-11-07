

-- REPLACEMENT for lb-phone/client/apps/framework/garage.lua. See LB_PHONE.md.
-- Keeps the native Garage app actions and NPC valet; no clean/repair/refuel.
local RES = (Config.Valet and Config.Valet.OxlynResource) or 'oxlyn-garage'
local busy = false

local function modelReady(model)
    model = type(model) == 'string' and joaat(model) or model
    if not model or not IsModelInCdimage(model) or not IsModelValid(model) then return nil end
    local deadline = GetGameTimer() + 8000
    RequestModel(model)
    while not HasModelLoaded(model) and GetGameTimer() < deadline do Wait(50) end
    return HasModelLoaded(model) and model or nil
end
local function networkEntity(netId)
    if not netId then return nil end
    local deadline = GetGameTimer() + 8000
    repeat
        if NetworkDoesNetworkIdExist(netId) then
            local entity = NetworkGetEntityFromNetworkId(netId)
            if entity ~= 0 and DoesEntityExist(entity) then return entity end
        end
        Wait(50)
    until GetGameTimer() >= deadline
end
local function control(entity)
    local deadline = GetGameTimer() + 5000
    repeat
        if not DoesEntityExist(entity) then return false end
        if NetworkHasControlOfEntity(entity) then return true end
        NetworkRequestControlOfEntity(entity)
        Wait(50)
    until GetGameTimer() >= deadline
    return false
end
local function location()
    local origin = GetEntityCoords(PlayerPedId())
    local minimum = Config.Valet.Drive and 75.0 or 0.0
    -- Bounded native lookup, including map areas supported by road nodes.
    for n = 1, 80 do
        local found, pos, heading = GetNthClosestVehicleNodeWithHeading(origin.x, origin.y, origin.z, n, 1, 3.0, 0)
        if not found then break end
        local distance = #(pos - origin)
        if distance >= minimum and distance <= 250.0 and not IsAnyVehicleNearPoint(pos.x, pos.y, pos.z, 3.0) then return pos, heading end
    end
end

function GetVehicleLabel(model)
    if type(model) == 'string' then model = joaat(model) end
    local name = GetDisplayNameFromVehicleModel(model or 0)
    if not name or name == 'CARNOTFOUND' then return 'Unknown' end
    local label = GetLabelText(name)
    return label and label ~= 'NULL' and label or name
end

local function deliver(vehicle, ped, plate)
    local blip = AddBlipForEntity(vehicle)
    SetBlipSprite(blip, 225)
    SetBlipColour(blip, 5)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(plate)
    EndTextCommandSetBlipName(blip)
    local deadline, nextRoute = GetGameTimer() + 120000, 0
    while GetGameTimer() < deadline and DoesEntityExist(vehicle) do
        local target = GetEntityCoords(PlayerPedId())
        if #(GetEntityCoords(vehicle) - target) <= 15.0 then break end
        if ped and DoesEntityExist(ped) and GetGameTimer() >= nextRoute then
            TaskVehicleDriveToCoordLongrange(ped, vehicle, target.x, target.y, target.z, 17.0, 786603, 10.0)
            nextRoute = GetGameTimer() + 8000
        end
        Wait(500)
    end
    if DoesBlipExist(blip) then RemoveBlip(blip) end
    if DoesEntityExist(vehicle) then
        SetVehicleDoorsLocked(vehicle, 0)
        local pos = GetEntityCoords(vehicle)
        if #(pos - GetEntityCoords(PlayerPedId())) > 20.0 then SetNewWaypoint(pos.x, pos.y) end
    end
    if ped and DoesEntityExist(ped) then
        TaskLeaveVehicle(ped, vehicle, 0)
        Wait(3000)
        if DoesEntityExist(ped) then TaskWanderStandard(ped, 10.0, 10); SetEntityAsNoLongerNeeded(ped) end
    end
    -- NPC exit can stop the engine. Leave the delivered car running without
    -- changing the choice of a player who has already taken the driver seat.
    if DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == 0 and control(vehicle)
        and DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == 0 then
        SetVehicleEngineOn(vehicle, true, true, false)
    end
end

local function valet(plate)
    if busy or not Config.Valet.Enabled or GetResourceState(RES) ~= 'started' or IsPedInAnyVehicle(PlayerPedId(), false) then return false end
    busy = true
    local data, vehicle, ped, confirmed
    local ok, success = pcall(function()
        local pos, heading = location()
        if not pos then return false end
        data = AwaitCallback('garage:valetVehicle', plate, { x = pos.x, y = pos.y, z = pos.z }, heading)
        if not data or not data.ok then return false end
        if Config.ServerSideSpawn then
            vehicle = networkEntity(data.vehNetId)
            if not vehicle or not control(vehicle) then return false end
            if Config.Valet.Drive then
                ped = networkEntity(data.pedNetId)
                if not ped or not control(ped) then return false end
            end
        else
            local model = modelReady(data.model)
            if not model then return false end
            vehicle = CreateVehicle(model, data.spot.x, data.spot.y, data.spot.z, data.spot.w, true, false)
            SetModelAsNoLongerNeeded(model)
            if not vehicle or vehicle == 0 or not control(vehicle) then return false end
        end
        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleOnGroundProperly(vehicle)
        -- This restores full props, damage, tyres, windows, dirt, fuel and keys.
        -- Its return is mandatory: a failed restore never starts delivery.
        if exports[RES]:ApplyPhoneVehicle(vehicle, data, { deferConfirm = true }) ~= true then return false end
        if AwaitCallback('garage:oxlynConfirm', data.oxlynRequest, NetworkGetNetworkIdFromEntity(vehicle)) ~= true then return false end
        confirmed = true
        if exports[RES]:WaitForVehicleKeys(vehicle, 12000) ~= true then return false end
        if Config.Valet.Drive then
            if Config.ServerSideSpawn then
                TaskWarpPedIntoVehicle(ped, vehicle, -1)
            else
                local driver = modelReady(Config.Valet.Model)
                if not driver then return false end
                ped = CreatePedInsideVehicle(vehicle, 4, driver, -1, true, false)
                SetModelAsNoLongerNeeded(driver)
                if not ped or ped == 0 or not DoesEntityExist(ped) then return false end
            end
        end
        SetVehRadioStation(vehicle, 'OFF')
        SetVehicleEngineOn(vehicle, true, true, false)
        if ped then
            SetPedKeepTask(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetEntityAsMissionEntity(ped, true, true)
        end
        CreateThread(function() deliver(vehicle, ped, data.plate) end)
        return true
    end)
    if not ok or not success then
        if not ok then print('[lb-phone/OXLYN] Valet failed: ' .. tostring(success)) end
        -- Once confirmed, key/driver errors leave the vehicle parked and
        -- locatable. Clean up its driver without restoring SQL or refunding.
        if confirmed then
            if ped and DoesEntityExist(ped) and control(ped) then
                ClearPedTasksImmediately(ped)
                DeleteEntity(ped)
            end
            if vehicle and DoesEntityExist(vehicle) then
                if control(vehicle) then
                    SetVehicleEngineOn(vehicle, false, true, false)
                    SetVehicleDoorsLocked(vehicle, 0)
                end
                local pos = GetEntityCoords(vehicle)
                SetNewWaypoint(pos.x, pos.y)
            end
            busy = false
            return true
        end
        if not Config.ServerSideSpawn then
            if ped and DoesEntityExist(ped) and NetworkHasControlOfEntity(ped) then DeleteEntity(ped) end
            if vehicle and DoesEntityExist(vehicle) and NetworkHasControlOfEntity(vehicle) then DeleteEntity(vehicle) end
        end
        if data and data.oxlynRequest then pcall(AwaitCallback, 'garage:oxlynCancel', data.oxlynRequest) end
    end
    busy = false
    return ok and success == true
end

RegisterNUICallback('Garage', function(data, cb)
    if data.action == 'getVehicles' then
        local vehicles = AwaitCallback('garage:getVehicles') or {}
        for _, v in ipairs(vehicles) do v.model = GetVehicleLabel(v.model) end
        cb(vehicles)
    elseif data.action == 'valet' then
        cb(valet(data.plate))
    elseif data.action == 'setWaypoint' then
        local pos = AwaitCallback('garage:findCar', data.plate)
        if pos and pos.x and pos.y then
            SetNewWaypoint(pos.x, pos.y)
            TriggerEvent('phone:sendNotification', { app = 'Garage', title = L('BACKEND.GARAGE.VALET'), content = L('BACKEND.GARAGE.MARKED') })
        end
        cb('ok')
    else
        cb(false)
    end
end)

