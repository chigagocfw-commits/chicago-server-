

local resourceName = GetCurrentResourceName()
local valetBusy = false

local function isValidVehicle(entity)
    return entity
        and DoesEntityExist(entity)
        and GetEntityType(entity) == 2
end

---------------------------------------------------------------------
-- Exports: vehicle list / locate
---------------------------------------------------------------------

exports("GetPhoneVehicles", function()
    local result = Framework.Await("phone:vehicles")
    if not result then
        result = { ok = false, error = "timeout" }
    end
    return result
end)

exports("LocateVehicle", function(plate, setWaypoint)
    local result = Framework.Await("phone:locate", plate)
    if not result then
        result = { ok = false, error = "timeout" }
    end

    if result.ok and setWaypoint ~= false and result.x and result.y then
        SetNewWaypoint(result.x, result.y)
    end

    return result
end)

---------------------------------------------------------------------
-- Exports: vehicle properties
---------------------------------------------------------------------

exports("GetVehicleProperties", function(vehicle)
    if not isValidVehicle(vehicle) then
        return nil
    end
    return Props.Get(vehicle)
end)

exports("SetVehicleProperties", function(vehicle, props)
    if not isValidVehicle(vehicle) or type(props) ~= "table" then
        return false
    end
    Props.Set(vehicle, props)
    return true
end)

---------------------------------------------------------------------
-- Apply a phone vehicle (props, plate, keys) to a spawned entity
---------------------------------------------------------------------

local function applyPhoneVehicle(vehicle, data, options)
    if not isValidVehicle(vehicle) or type(data) ~= "table" then
        return false
    end

    -- props can come directly, or as a JSON string in `mods`
    local props = data.props
    if not props and type(data.mods) == "string" then
        local ok, decoded = pcall(json.decode, data.mods)
        if ok then
            props = decoded
        end
    end

    if type(props) ~= "table" or not data.plate then
        return false
    end

    -- model sanity check (compare as unsigned 32-bit)
    if tonumber(props.model) then
        local entityModel = GetEntityModel(vehicle) % 4294967296
        local propsModel = tonumber(props.model) % 4294967296
        if entityModel ~= propsModel then
            return false
        end
    end

    -- request network control (5s timeout)
    if not NetworkHasControlOfEntity(vehicle) then
        local deadline = GetGameTimer() + 5000
        repeat
            NetworkRequestControlOfEntity(vehicle)
            Wait(50)
            if NetworkHasControlOfEntity(vehicle) then
                break
            end
        until deadline <= GetGameTimer()

        if not NetworkHasControlOfEntity(vehicle) then
            return false
        end
    end

    if not isValidVehicle(vehicle) or not NetworkGetEntityIsNetworked(vehicle) then
        return false
    end

    Props.Set(vehicle, props)
    SetVehicleNumberPlateText(vehicle, data.plate)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    Keys.Give(vehicle)

    local deferConfirm = type(options) == "table" and options.deferConfirm == true
    if not deferConfirm then
        TriggerServerEvent(
            resourceName .. ":sv:spawned",
            Utils.PlateKey(data.plate),
            NetworkGetNetworkIdFromEntity(vehicle)
        )
    end

    return true
end

exports("ApplyPhoneVehicle", applyPhoneVehicle)

exports("WaitForVehicleKeys", function(vehicle, timeout)
    local granted = Keys.WaitForGrant(vehicle, timeout)
    if not granted then
        Client.Notify(_U("vehicle_keys_failed"), "error")
    end
    return granted
end)

---------------------------------------------------------------------
-- Valet
---------------------------------------------------------------------

local function findValetSpot()
    local coords = GetEntityCoords(PlayerPedId())

    local valetConfig = (Config.Phone or {}).valet or {}
    local maxDistance = tonumber(valetConfig.maxDistance) or 250.0

    for i = 1, 12 do
        local found, nodePos, heading = GetNthClosestVehicleNodeWithHeading(
            coords.x, coords.y, coords.z, i, 1, 3.0, 0
        )

        if found then
            local dist = Utils.Dist(coords, nodePos)
            if dist <= maxDistance
                and not IsAnyVehicleNearPoint(nodePos.x, nodePos.y, nodePos.z, 3.0) then
                return nodePos, heading
            end
        end
    end

    return nil, nil
end

local function doValet(plate)
    if Client.Busy() or IsPedInAnyVehicle(PlayerPedId(), false) then
        return { ok = false, error = "busy" }
    end

    local spot, heading = findValetSpot()
    if not spot then
        return { ok = false, error = "spot_occupied" }
    end

    local response = Framework.Await("phone:valet", plate, {
        x = spot.x,
        y = spot.y,
        z = spot.z,
    }, heading)

    if not (response and response.ok) then
        return response or { ok = false, error = "timeout" }
    end

    local spawned = false
    Garage.Spawn(response, "out", response.garageLabel, {
        onDone = function(success)
            spawned = success
        end,
    })

    if not spawned then
        Framework.Await("phone:cancel", plate)
        return { ok = false, error = "spawn_failed" }
    end

    return {
        ok = true,
        plate = response.plate,
        key = response.key,
    }
end

exports("RequestValet", function(plate)
    if valetBusy then
        return { ok = false, error = "busy" }
    end

    valetBusy = true
    local ok, result = pcall(doValet, plate)
    valetBusy = false

    if not ok then
        Framework.TriggerCallback("phone:cancel", function() end, plate)
        return { ok = false, error = "spawn_failed" }
    end

    return result
end)

