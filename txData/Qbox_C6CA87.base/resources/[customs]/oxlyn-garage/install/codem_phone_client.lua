

-- Install INSIDE CodeM after exports/garage/client.lua; see CODEM_PHONE.md.
local GarageClient = assert(rawget(_G, 'GarageClient'), 'Load OXLYN adapter after CodeM exports/garage/client.lua')
local RES = (Config.Valet and Config.Valet.OxlynResource) or 'oxlyn-garage'
local PHONE = GetCurrentResourceName()
local oldDeliver = GarageClient.SpawnAndDeliver

local function oxlynSelected()
    local configured = Config.Valet and Config.Valet.GarageScript or 'auto'
    return configured == 'oxlyn-garage' or configured == RES
        or (configured == 'auto' and GetResourceState(RES) == 'started')
end

local function findSpawn(minDist)
    local here = GetEntityCoords(PlayerPedId())
    local maxDistance = tonumber(Config.Valet and Config.Valet.OxlynMaxDistance) or 250.0
    -- Bound the native node search (the supplied phone helper has no cap).
    for nth = 1, 128 do
        local found, node, heading = GetNthClosestVehicleNodeWithHeading(here.x, here.y, here.z, nth, 0, 0, 0)
        if not found or not node then break end
        local distance = #(node - here)
        if distance > minDist and distance <= maxDistance and not IsAnyVehicleNearPoint(node.x, node.y, node.z, 3.0) then
            return node, heading
        end
    end
end

local function reservationOf(vehicleData)
    if type(vehicleData) ~= 'table' then return nil end
    local props = vehicleData.mods
    if type(props) == 'string' then
        local ok, decoded = pcall(json.decode, props)
        props = ok and decoded or nil
    end
    local marker = type(props) == 'table' and props.__oxlynPhone
    if type(marker) == 'table' and marker.oxlyn == true then
        local copy = {}
        for k, v in pairs(props) do if k ~= '__oxlynPhone' then copy[k] = v end end
        local data = {}
        for k, v in pairs(marker) do data[k] = v end
        data.props = copy
        return data
    end
    if vehicleData.oxlyn == true and type(vehicleData.props) == 'table' then
        return { ok = true, oxlyn = true, plate = vehicleData.plate, key = vehicleData.key,
            model = vehicleData.model or vehicleData.spawncode, spot = vehicleData.spot, props = vehicleData.props }
    end
end

function GarageClient.SpawnAndDeliver(vehicleData, plate, valetDrive, serverSideSpawn)
    local data = reservationOf(vehicleData)
    if not data then
        if oxlynSelected() then
            TriggerServerEvent(PHONE .. ':oxlynGarage:cancel', plate)
            return { success = false, message = 'valet.errors.invalidData' }
        end
        return oldDeliver(vehicleData, plate, valetDrive, serverSideSpawn)
    end
    local vehicle, ped, blip
    local function fail(message)
        if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
        if ped and DoesEntityExist(ped) and NetworkHasControlOfEntity(ped) then DeleteEntity(ped) end
        if vehicle and DoesEntityExist(vehicle) and NetworkHasControlOfEntity(vehicle) then DeleteEntity(vehicle) end
        TriggerServerEvent(PHONE .. ':oxlynGarage:cancel', data.plate or plate)
        return { success = false, message = message }
    end
    if GetResourceState(RES) ~= 'started' or not data.plate or not data.props.model then
        return fail('valet.errors.invalidData')
    end
    if IsPedInAnyVehicle(PlayerPedId(), false) then return fail('valet.errors.playerInVehicle') end

    if serverSideSpawn then
        if not vehicleData.vehNetId then return fail('valet.errors.serverSpawnFailed') end
        vehicle = GarageClient.WaitForNetworkId(vehicleData.vehNetId)
        if not vehicle or not GarageClient.TakeControlOfEntity(vehicle) then return fail('valet.errors.vehicleNotExist') end
        if valetDrive and vehicleData.pedNetId then
            local deadline = GetGameTimer() + 5000
            while not NetworkDoesNetworkIdExist(vehicleData.pedNetId) and GetGameTimer() < deadline do Wait(100) end
            if NetworkDoesNetworkIdExist(vehicleData.pedNetId) then
                ped = NetworkGetEntityFromNetworkId(vehicleData.pedNetId)
                if ped == 0 or not GarageClient.TakeControlOfEntity(ped) then ped = nil end
            end
        end
    else
        local location, heading = findSpawn(valetDrive and math.random(75, 150) or 0)
        if not location then return fail('valet.errors.noLocationFound') end
        local spawnData = { spawncode = data.model or data.props.model }
        vehicle = GarageClient.CreateClientVehicle(spawnData, vector4(location.x, location.y, location.z, heading or 0.0))
        if not vehicle or not DoesEntityExist(vehicle) then return fail('valet.errors.vehicleNotExist') end
        if not GarageClient.TakeControlOfEntity(vehicle) then return fail('valet.errors.vehicleNotExist') end
    end

    -- Full saved properties once, before driving: no clean/repair/refuel step,
    -- and no reapplication after travel that could erase new collision damage.
    local ok, applied = pcall(function() return exports[RES]:ApplyPhoneVehicle(vehicle, data) end)
    if not ok or applied ~= true then return fail('valet.errors.vehicleNotExist') end
    -- Apply confirms the real vehicle. A key-provider failure after this
    -- point must leave it out and locatable, never cancel/refund its spawn.
    local waited, keysReady = pcall(function() return exports[RES]:WaitForVehicleKeys(vehicle, 12000) end)
    if not waited or keysReady ~= true then
        if ped and DoesEntityExist(ped) and GarageClient.TakeControlOfEntity(ped) then
            ClearPedTasksImmediately(ped)
            DeleteEntity(ped)
        end
        if DoesEntityExist(vehicle) then
            if GarageClient.TakeControlOfEntity(vehicle) then
                SetVehicleEngineOn(vehicle, false, true, false)
                SetVehicleDoorsLocked(vehicle, 0)
            end
            local pos = GetEntityCoords(vehicle)
            SetNewWaypoint(pos.x, pos.y)
        end
        -- OXLYN already showed the specific key warning. Report the valid
        -- parked delivery so the phone does not undo it or refund its fee.
        return { success = true, message = 'valet.success.vehicleDelivered' }
    end
    if valetDrive and ped then TaskWarpPedIntoVehicle(ped, vehicle, -1) end
    if valetDrive and not ped then
        local model = GarageClient.LoadModel('S_M_Y_XMech_01')
        if model then
            ped = CreatePedInsideVehicle(vehicle, 4, model, -1, true, false)
            SetModelAsNoLongerNeeded(model)
            if not ped or ped == 0 or not DoesEntityExist(ped) then ped = nil end
        end
    end
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehRadioStation(vehicle, 'OFF')
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleEngineOn(vehicle, true, true, false)
    -- The configured key provider has acknowledged the grant before driving.
    local coords = GetEntityCoords(vehicle)
    blip = AddBlipForEntity(vehicle)
    SetBlipSprite(blip, 225)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 0.9)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Valet - ' .. data.plate)
    EndTextCommandSetBlipName(blip)

    if not valetDrive or not ped then
        CreateThread(function()
            local deadline = GetGameTimer() + 120000
            while GetGameTimer() < deadline and DoesBlipExist(blip) do
                if not DoesEntityExist(vehicle) or #(GetEntityCoords(vehicle) - GetEntityCoords(PlayerPedId())) <= 20 then break end
                Wait(500)
            end
            if DoesBlipExist(blip) then RemoveBlip(blip) end
        end)
        return { success = true, message = 'valet.success.vehicleDelivered' }
    end

    SetPedKeepTask(ped, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, false)
    SetDriverAbility(ped, 1.0)
    SetDriverAggressiveness(ped, 0.0)
    local function drive()
        if not DoesEntityExist(ped) or not DoesEntityExist(vehicle) then return end
        local target = GetEntityCoords(PlayerPedId())
        local found, node = GetClosestVehicleNode(target.x, target.y, target.z, 1, 3.0, 0)
        if found then target = node end
        TaskVehicleDriveToCoordLongrange(ped, vehicle, target.x, target.y, target.z, 17.0, 786603, 12.0)
    end
    drive()
    local deadline, nextRepath, lastSeen = GetGameTimer() + 180000, GetGameTimer() + 8000, GetGameTimer()
    local arrived = false
    while GetGameTimer() < deadline do
        Wait(250)
        if DoesEntityExist(vehicle) then
            coords, lastSeen = GetEntityCoords(vehicle), GetGameTimer()
            if #(coords - GetEntityCoords(PlayerPedId())) <= 15 then arrived = true; break end
            if GetGameTimer() >= nextRepath then drive(); nextRepath = GetGameTimer() + 8000 end
        elseif GetGameTimer() - lastSeen > 30000 then break end
    end
    if DoesBlipExist(blip) then RemoveBlip(blip) end
    if DoesEntityExist(vehicle) then
        if ped and DoesEntityExist(ped) then ClearPedTasks(ped) end
        SetVehicleEngineOn(vehicle, true, true, false)
        SetVehicleDoorsLocked(vehicle, 0)
        if not arrived then SetNewWaypoint(coords.x, coords.y) end
    end
    if ped and DoesEntityExist(ped) then
        if DoesEntityExist(vehicle) then TaskLeaveVehicle(ped, vehicle, 0); Wait(3000) end
        if DoesEntityExist(ped) then TaskWanderStandard(ped, 10.0, 10); SetEntityAsNoLongerNeeded(ped) end
    end
    -- The valet driver's exit can stop the engine. Finish the handoff with
    -- it running, but do not override a player already in the driver seat.
    if DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == 0
        and GarageClient.TakeControlOfEntity(vehicle)
        and DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == 0 then
        SetVehicleEngineOn(vehicle, true, true, false)
    end
    -- A timed-out driver leaves the already confirmed vehicle locatable.
    -- Do not cancel it or restore its database state after a successful spawn.
    if not DoesEntityExist(vehicle) then return { success = false, message = 'valet.errors.vehicleNotExist' } end
    return { success = true, message = arrived and 'valet.success.deliveredByValet' or 'valet.success.vehicleDelivered' }
end

