

-- Cleaned from decompiler output (register-style L0_1/L1_2 names -> readable names).
-- Logic is preserved; tangled goto/if chains were rebuilt by intent.
--
-- "Park" = leaving an owned vehicle parked in the world. The vehicle is
-- persisted in oxlyn_garage_parked, respawned on boot/removal, and towed to
-- the impound if left longer than the configured time limit.

Park = Park or {}

local resourceName = GetCurrentResourceName()

local function log(msg)
    print(("[%s] %s"):format(resourceName, msg))
end

local function debugLog(msg)
    if Config.Debug then
        log(msg)
    end
end

---------------------------------------------------------------------
-- State
---------------------------------------------------------------------

local parked        = {}  -- [plateKey] = park record
local countByOwner  = {}  -- [owner] = number of parked vehicles
local keyByEntity   = {}  -- [entity handle] = plateKey
local lastCall      = {}  -- [source] = game timer of last "park" call (rate limit)

-- Vehicle types accepted by CreateVehicleServerSetter
local VALID_VTYPES = {
    automobile = true,
    bike = true,
    boat = true,
    heli = true,
    plane = true,
    quadbike = true,
    submarine = true,
    submarinecar = true,
    trailer = true,
    blimp = true,
    amphibious_automobile = true,
    amphibious_quadbike = true,
}

-- Warn the owner this many seconds before the vehicle is towed
local TOW_WARNING_SECONDS = 900

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

local function parkSettings()
    return (Settings.Get() or {}).park or {}
end

--- Reply to a callback with a localised error.
local function fail(cb, errorKey, ...)
    cb({
        ok = false,
        error = errorKey,
        message = _U(errorKey, ...),
    })
end

--- Simple per-player rate limit. Returns false if called again within `ms`.
local function throttle(src, ms)
    local now = GetGameTimer()
    if now < (lastCall[src] or 0) + ms then
        return false
    end
    lastCall[src] = now
    return true
end

AddEventHandler("playerDropped", function()
    lastCall[source] = nil
end)

--- Network id -> entity handle, or nil if invalid / no longer existing.
local function resolveEntity(netId)
    netId = tonumber(netId)
    if not netId or netId == 0 then
        return nil
    end

    local ok, entity = pcall(NetworkGetEntityFromNetworkId, netId)
    if ok and entity and entity ~= 0 and DoesEntityExist(entity) then
        return entity
    end
    return nil
end

--- Data replicated to clients through the entity state bag.
local function stateBagData(record)
    return {
        plate    = record.key,
        plateRaw = record.plate,
        owner    = record.owner,
        props    = record.props,
        at       = record.at,
    }
end

--- Remove a record from the in-memory indexes. Returns the removed record.
local function unregister(key)
    local record = parked[key]
    if not record then
        return nil
    end

    parked[key] = nil

    local remaining = (countByOwner[record.owner] or 1) - 1
    countByOwner[record.owner] = (remaining > 0) and remaining or nil

    if record.entity then
        keyByEntity[record.entity] = nil
    end

    return record
end

local function register(record)
    unregister(record.key)

    parked[record.key] = record
    countByOwner[record.owner] = (countByOwner[record.owner] or 0) + 1
end

--- Park time limit in seconds (0 = unlimited).
local function maxSeconds()
    local hours = tonumber(parkSettings().maxHours) or 0
    if hours > 0 then
        return math.floor(hours * 3600)
    end
    return 0
end

--- Human-readable duration, e.g. "2 hours 30 minutes".
function Park.HoursText(hours)
    local totalMinutes = math.floor((tonumber(hours) or 0) * 60 + 0.5)
    local h = totalMinutes // 60
    local m = totalMinutes % 60

    if h == 0 then
        return _U("ui_imp_minutes", m)
    end
    if m == 0 then
        return _U("ui_imp_hours", h)
    end
    return _U("ui_imp_hours", h) .. " " .. _U("ui_imp_minutes", m)
end

--- Best display name for a vehicle: nickname, label, `fallback`, model name, plate key.
local function displayName(key, fallback)
    local vehicle = DB.GetByPlate(key)

    if vehicle and vehicle.meta then
        if vehicle.meta.nickname then return vehicle.meta.nickname end
        if vehicle.meta.label then return vehicle.meta.label end
    end

    return fallback or (vehicle and vehicle.modelName) or key
end

---------------------------------------------------------------------
-- Public accessors
---------------------------------------------------------------------

function Park.Settings()
    return parkSettings()
end

--- Unix time at which the parked vehicle will be towed (nil if no limit).
function Park.TowAt(key)
    local record = parked[key]
    local limit = maxSeconds()
    if not record or limit <= 0 then
        return nil
    end
    return (tonumber(record.at) or os.time()) + limit
end

function Park.IsParked(key)
    return parked[key] ~= nil
end

function Park.Get(key)
    return parked[key]
end

function Park.Keys()
    local keys = {}
    for key in pairs(parked) do
        keys[#keys + 1] = key
    end
    return keys
end

function Park.CountFor(owner)
    return countByOwner[owner] or 0
end

--- Live entity of a parked vehicle (nil if not spawned).
function Park.Entity(key)
    local record = parked[key]
    return record and record.netId and resolveEntity(record.netId) or nil
end

---------------------------------------------------------------------
-- Spawning
---------------------------------------------------------------------

--- Spawn the world entity for a park record and publish its state bag.
local function spawn(record)
    local vtype = VALID_VTYPES[record.vtype] and record.vtype or "automobile"

    local ok, entity = pcall(CreateVehicleServerSetter,
        record.model, vtype, record.x, record.y, record.z, record.w)

    if not (ok and entity) or entity == 0 then
        log(("^3park: could not spawn %s (%s)^7"):format(record.key, tostring(entity)))
        return nil
    end

    -- Wait (up to 5s) for the entity to exist
    local started = GetGameTimer()
    while not DoesEntityExist(entity) and (GetGameTimer() - started) < 5000 do
        Wait(50)
    end

    if not DoesEntityExist(entity) then
        return nil
    end

    -- The record may have been released/replaced while we were waiting
    if parked[record.key] ~= record then
        DeleteEntity(entity)
        return nil
    end

    record.entity = entity
    keyByEntity[entity] = record.key
    record.netId = NetworkGetNetworkIdFromEntity(entity)

    Entity(entity).state:set("oxlynParked", stateBagData(record), true)

    debugLog(("park: %s spawned (net %s)"):format(record.key, tostring(record.netId)))
    return entity
end

---------------------------------------------------------------------
-- Forget / Release
---------------------------------------------------------------------

--- Drop a park record (DB + memory) and clear its state bag. Does not touch
--- the world entity.
function Park.Forget(key)
    local record = unregister(key)
    if not record then return end

    DB.DeletePark(key)

    local entity = record.netId and resolveEntity(record.netId)
    if entity then
        pcall(function()
            Entity(entity).state:set("oxlynParked", false, true)
        end)
    end
end

--- Release a parked vehicle. If `src` is given, the vehicle is handed to that
--- player (marked out + keys given). Returns true if a record existed.
function Park.Release(key, src)
    local record = unregister(key)
    if not record then
        return false
    end

    DB.DeletePark(key)

    local entity = record.netId and resolveEntity(record.netId)
    if entity then
        pcall(function()
            Entity(entity).state:set("oxlynParked", false, true)
        end)

        if src then
            Vehicles.MarkOut(key, src, record.netId, nil)
            Keys.GiveServer(src, entity, record.plate, record.model)
        end
    end

    TriggerEvent(resourceName .. ":server:vehicleUnparked", key, src)
    return true
end

---------------------------------------------------------------------
-- Park a vehicle (player action)
---------------------------------------------------------------------

Framework.RegisterCallback("park:park", function(src, cb, netId, props, vtype)
    if not DB.Ready then
        return fail(cb, "not_loaded")
    end

    if not throttle(src, 1000) then
        return cb(nil)
    end

    local settings = parkSettings()
    if settings.enabled == false then
        return fail(cb, "park_disabled")
    end

    local vehicle = resolveEntity(netId)
    if not vehicle then
        return fail(cb, "park_no_vehicle")
    end

    local plateText = GetVehicleNumberPlateText(vehicle) or ""
    local key = Utils.PlateKey(plateText)
    if key == "" then
        return fail(cb, "park_no_vehicle")
    end

    -- Must be owned by the requesting player
    local owned = DB.GetByPlate(key)
    if not (owned and owned.owner == Framework.GetIdentifier(src)) then
        return fail(cb, "vehicle_not_owned")
    end

    if owned.state == "impounded" then
        return fail(cb, "vehicle_impounded")
    end

    if Contract.IsLocked(key) then
        return fail(cb, "contract_locked")
    end

    if Vehicles.IsRecovering and Vehicles.IsRecovering(key) then
        return fail(cb, "vehicle_out")
    end

    if parked[key] then
        return fail(cb, "park_already")
    end

    -- Per-player limit
    local maxPerPlayer = math.floor(tonumber(settings.maxPerPlayer) or 0)
    if maxPerPlayer > 0 and maxPerPlayer <= Park.CountFor(owned.owner) then
        return fail(cb, "park_limit", maxPerPlayer)
    end

    -- Player must be near the vehicle
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local vehicleCoords = GetEntityCoords(vehicle)
    local maxDistance = (tonumber(settings.radius) or 8.0) + 4.0
    if #(playerCoords - vehicleCoords) > maxDistance then
        return fail(cb, "park_too_far")
    end

    -- Nobody may be inside
    for seat = -1, 6 do
        if GetPedInVehicleSeat(vehicle, seat) ~= 0 then
            return fail(cb, "park_occupied")
        end
    end

    -- Sanitise client-supplied props
    if type(props) ~= "table" then
        props = {}
    end
    props.plate        = plateText
    props.model        = GetEntityModel(vehicle)
    props.engineHealth = Utils.Clamp(tonumber(props.engineHealth) or 1000, -4000, 1000)
    props.bodyHealth   = Utils.Clamp(tonumber(props.bodyHealth) or 1000, 0, 1000)
    props.tankHealth   = Utils.Clamp(tonumber(props.tankHealth) or 1000, -4000, 1000)
    props.fuelLevel    = Utils.Clamp(tonumber(props.fuelLevel) or 100, 0, 100)
    props.dirtLevel    = Utils.Clamp(tonumber(props.dirtLevel) or 0, 0, 15)

    local record = {
        key   = key,
        plate = plateText,
        owner = owned.owner,
        model = props.model,
        vtype = (type(vtype) == "string" and VALID_VTYPES[vtype] and vtype) or "automobile",
        x     = vehicleCoords.x,
        y     = vehicleCoords.y,
        z     = vehicleCoords.z,
        w     = GetEntityHeading(vehicle),
        props = props,
        at    = os.time(),
    }

    -- Re-check right before committing (state may have changed)
    if Vehicles.IsRecovering and Vehicles.IsRecovering(key) then
        return fail(cb, "vehicle_out")
    end

    DB.SetOut(owned)
    DB.SavePark(record)
    register(record)
    Vehicles.ClearOut(key)

    -- Replace the player's vehicle with the server-owned parked copy
    DeleteEntity(vehicle)
    CreateThread(function()
        Wait(300)
        if parked[key] == record then
            spawn(record)
        end
    end)

    TriggerEvent(resourceName .. ":server:vehicleParked", key, src)

    local meta = owned.meta
    local name = (meta and (meta.nickname or meta.label)) or owned.modelName or plateText
    local label = (meta and (meta.nickname or meta.label)) or owned.modelName

    local hours = tonumber(settings.maxHours) or 0
    local fee = tonumber(settings.towFee) or 0

    local response = {
        ok    = true,
        label = label,
        plate = plateText,
        hours = hours,
        fee   = fee,
    }

    if hours > 0 then
        response.towAt = record.at + maxSeconds()
        response.message = _U("park_ok_limit", name, Park.HoursText(hours), Utils.Money(fee))
    else
        response.message = _U("park_ok", name)
    end

    cb(response)
end)

---------------------------------------------------------------------
-- Tow expiry
---------------------------------------------------------------------

--- Tow one overdue parked vehicle to the impound.
local function tow(key, record, maxHours)
    local success, err = Vehicles.Impound({
        key    = key,
        entity = Park.Entity(key),
        fee    = tonumber(parkSettings().towFee) or 0,
        reason = _U("park_tow_reason", Park.HoursText(maxHours)),
        byName = _U("park_tow_by"),
        coords = { x = record.x, y = record.y, z = record.z },
    })

    if success then
        log(("park: %s towed to the impound (over %s)"):format(key, Park.HoursText(maxHours)))
    else
        log(("^3park: %s is over the limit but could not be impounded (%s) — park mode ended^7")
            :format(key, tostring(err)))

        local entity = Park.Entity(key)
        Park.Forget(key)
        if entity then
            DeleteEntity(entity)
        end
    end
end

--- Warn owners about vehicles close to expiry and tow those past the limit.
--- Returns the number of vehicles towed.
function Park.CheckExpired(now)
    now = now or os.time()

    local limit = maxSeconds()
    if limit <= 0 then
        return 0
    end

    local maxHours = tonumber(parkSettings().maxHours) or 0
    local expired = {}
    local towed = 0

    for key, record in pairs(parked) do
        local elapsed = now - (tonumber(record.at) or now)

        if elapsed >= limit then
            expired[#expired + 1] = key
        elseif elapsed >= limit - TOW_WARNING_SECONDS and not record.warned then
            record.warned = true

            local player = Framework.GetPlayerByIdentifier(record.owner)
            if player then
                local minutesLeft = math.max(1, math.ceil((limit - elapsed) / 60))
                Framework.Notify(player,
                    _U("park_tow_warning", displayName(key, record.plate), minutesLeft),
                    "warning")
            end
        end
    end

    for _, key in ipairs(expired) do
        local record = parked[key]
        if record then
            tow(key, record, maxHours)
            towed = towed + 1
        end
    end

    return towed
end

CreateThread(function()
    while true do
        Wait(60000)
        if DB.Ready then
            Park.CheckExpired()
        end
    end
end)

---------------------------------------------------------------------
-- Events
---------------------------------------------------------------------

--- Player takes a parked vehicle back (client sends the entity's net id).
RegisterNetEvent(resourceName .. ":sv:unpark", function(netId)
    local src = source

    local entity = resolveEntity(netId)
    if not entity then return end

    local data = Entity(entity).state.oxlynParked
    if type(data) ~= "table" or not data.plate then
        return
    end

    local record = parked[data.plate]
    if not (record and record.owner == Framework.GetIdentifier(src)) then
        return
    end

    Park.Release(data.plate, src)
    Framework.Notify(src, _U("park_released"), "info")
end)

--- If a parked vehicle's entity is deleted (e.g. by cleanup), respawn it.
AddEventHandler("entityRemoved", function(entity)
    local key = keyByEntity[entity]
    if not key then return end

    keyByEntity[entity] = nil

    local record = parked[key]
    if not (record and record.entity == entity) then
        return
    end

    record.entity = nil
    record.netId = nil

    SetTimeout(2000, function()
        if parked[key] == record and not record.netId then
            debugLog(("park: %s was removed — respawning"):format(key))
            spawn(record)
        end
    end)
end)

---------------------------------------------------------------------
-- Boot
---------------------------------------------------------------------

function Park.Boot()
    parked = {}
    countByOwner = {}
    keyByEntity = {}

    for _, record in ipairs(DB.LoadParked() or {}) do
        if record.key and record.owner then
            register(record)
        end
    end

    -- Tow anything that expired while the server was down
    local towed = Park.CheckExpired(os.time())
    if towed > 0 then
        log(("%d parked vehicle(s) went over the time limit and were towed"):format(towed))
    end

    local count = Utils.Count(parked)
    if count > 0 then
        log(("%d parked vehicle(s) coming back"):format(count))

        CreateThread(function()
            for _, record in pairs(parked) do
                spawn(record)
                Wait(50)
            end
        end)
    end
end

---------------------------------------------------------------------
-- Exports
---------------------------------------------------------------------

exports("IsVehicleParked", function(plate)
    return Park.IsParked(Utils.PlateKey(plate))
end)

exports("GetParkedVehicles", function()
    local list = {}
    for key, record in pairs(parked) do
        list[#list + 1] = {
            plate = record.plate,
            key   = key,
            owner = record.owner,
            x     = record.x,
            y     = record.y,
            z     = record.z,
            w     = record.w,
            at    = record.at,
        }
    end
    return list
end)

