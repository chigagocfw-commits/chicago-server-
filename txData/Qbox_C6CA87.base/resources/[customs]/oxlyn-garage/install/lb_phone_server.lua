

-- REPLACEMENT for lb-phone/server/apps/framework/garage.lua.
-- Do not load alongside the original file: LB rejects duplicate callbacks.
-- See LB_PHONE.md. This file runs inside lb-phone, not inside OXLYN.
local RES = (Config.Valet and Config.Valet.OxlynResource) or 'oxlyn-garage'
local active, sequence = {}, 0
local function key(plate) return tostring(plate or ''):upper():gsub('%s+', '') end
local function call(name, ...)
    if GetResourceState(RES) ~= 'started' then return nil end
    local args = table.pack(...)
    local ok, result = pcall(function() return exports[RES][name](exports[RES], table.unpack(args, 1, args.n)) end)
    if not ok then print(('[lb-phone/OXLYN] %s: %s'):format(name, tostring(result))); return nil end
    return result
end
local function notify(phone, text)
    SendNotification(phone, { app = 'Garage', title = L('BACKEND.GARAGE.VALET'), content = text })
end
local function cancel(src, request)
    if active[src] ~= request then return false end
    -- ApplyPhoneVehicle can already have committed the entity. An old cancel
    -- or delivery timeout must never delete it or return it to stored state.
    if call('IsVehicleOut', request.data.plate) then active[src] = nil; return false end
    if request.ped and DoesEntityExist(request.ped) then DeleteEntity(request.ped) end
    if request.vehicle and DoesEntityExist(request.vehicle) then DeleteEntity(request.vehicle) end
    local cancelled = call('CancelPhoneVehicle', src, request.data.plate) == true
    if not cancelled then
        -- The resource's own timeout may already have restored the vehicle.
        for _, row in ipairs(call('GetPhoneVehicles', src, 'lb') or {}) do
            if key(row.plate) == key(request.data.plate) and row.state == 'stored' then cancelled = true; break end
        end
    end
    if cancelled then
        active[src] = nil
        if request.paid > 0 and AddMoney(src, request.paid) == false then
            print(('[lb-phone/OXLYN] Refund failed: player %s, plate %s, amount %s'):format(src, request.data.plate, request.paid))
        end
        return true
    end
    return false
end

BaseCallback('garage:getVehicles', function(src)
    return call('GetPhoneVehicles', src, 'lb') or {}
end, {}, { preventSpam = true, rateLimit = 30 })

BaseCallback('garage:findCar', function(src, phone, plate)
    local found = call('LocateVehicle', src, plate)
    if found and found.ok and found.x and found.y then return { x = found.x, y = found.y, z = found.z or 0.0 } end
    notify(phone, L('BACKEND.GARAGE.COULDNT_FIND'))
    return false
end, false, { preventSpam = true, rateLimit = 20 })

BaseCallback('garage:valetVehicle', function(src, phone, plate, coords, heading)
    if not Config.Valet.Enabled or active[src] or type(plate) ~= 'string' then return nil end
    if type(coords) ~= 'table' and type(coords) ~= 'vector3' then return nil end
    local price = math.max(0, math.floor(tonumber(Config.Valet.Price) or 0))
    if price > 0 and GetBalance(src) < price then notify(phone, L('BACKEND.GARAGE.NO_MONEY')); return nil end
    -- LB owns its configured fee. OXLYN validates owner, impound, saved state,
    -- locks, spawn distance, bucket occupancy and duplicate plates atomically.
    local data = call('PreparePhoneVehicle', src, plate, { x = coords.x, y = coords.y, z = coords.z }, heading, { charge = false })
    if not data or data.ok ~= true then
        notify(phone, data and data.message or L('BACKEND.GARAGE.COULDNT_FIND'))
        return nil
    end
    sequence = sequence + 1
    data.oxlynRequest = sequence
    local request = { data = data, paid = 0 }
    active[src] = request
    -- A missing client response must not leave a charged/reserved vehicle.
    SetTimeout(20000, function()
        if active[src] == request then
            if not cancel(src, request) and active[src] == request then
                SetTimeout(1500, function() cancel(src, request) end)
            end
        end
    end)
    if price > 0 then
        local charged, removed = pcall(RemoveMoney, src, price)
        if not charged or not removed then cancel(src, request); notify(phone, L('BACKEND.GARAGE.NO_MONEY')); return nil end
        request.paid = price
    end
    if Config.ServerSideSpawn then
        request.vehicle = CreateServerVehicle(data.model, vector3(data.spot.x, data.spot.y, data.spot.z), data.spot.w)
        if not request.vehicle or not DoesEntityExist(request.vehicle) then cancel(src, request); return nil end
        SetEntityRoutingBucket(request.vehicle, GetPlayerRoutingBucket(src))
        SetVehicleNumberPlateText(request.vehicle, data.plate)
        data.vehNetId = NetworkGetNetworkIdFromEntity(request.vehicle)
        if Config.Valet.Drive then
            request.ped = CreateServerPed(Config.Valet.Model, vector3(data.spot.x, data.spot.y, data.spot.z + 1.0), data.spot.w)
            if not request.ped or not DoesEntityExist(request.ped) then cancel(src, request); return nil end
            SetEntityRoutingBucket(request.ped, GetPlayerRoutingBucket(src))
            data.pedNetId = NetworkGetNetworkIdFromEntity(request.ped)
        end
    end
    return data
end, nil, { preventSpam = true, rateLimit = 10 })

BaseCallback('garage:oxlynConfirm', function(src, phone, token, netId)
    local request = active[src]
    netId = tonumber(netId)
    if not request or request.data.oxlynRequest ~= token or not netId or netId <= 0 then return false end
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    local data = request.data
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then return false end
    if request.vehicle and request.vehicle ~= vehicle then return false end
    if key(GetVehicleNumberPlateText(vehicle)) ~= key(data.plate)
        or GetEntityModel(vehicle) % 4294967296 ~= tonumber(data.model) % 4294967296
        or GetEntityRoutingBucket(vehicle) ~= GetPlayerRoutingBucket(src) then return false end
    local pos = GetEntityCoords(vehicle)
    if (pos.x - data.spot.x)^2 + (pos.y - data.spot.y)^2 + (pos.z - data.spot.z)^2 > 400 then return false end
    if call('ConfirmPhoneVehicle', src, data.plate, netId) ~= true then return false end
    active[src] = nil
    notify(phone, L('BACKEND.GARAGE.ON_WAY'))
    return true
end, false, { preventSpam = true, rateLimit = 20 })

BaseCallback('garage:oxlynCancel', function(src, _, token)
    local request = active[src]
    return request and request.data.oxlynRequest == token and cancel(src, request) or false
end, false, { preventSpam = true, rateLimit = 20 })

AddEventHandler('playerDropped', function()
    local src = source
    local request = active[src]
    if request then cancel(src, request); active[src] = nil end
end)

