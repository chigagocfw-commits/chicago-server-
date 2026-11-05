

-- Admin tool: view / add / remove a player's owned vehicles across garages.
-- Every action runs inside a short-lived, token-protected admin session.

AdminVehicles = AdminVehicles or {}

local RESOURCE = GetCurrentResourceName()

local sessions = {}            -- admin source -> session
local activeByIdentifier = {}  -- target identifier -> session currently mutating it
local sessionCounter = 0
local SESSION_TTL = 1800       -- seconds
local UNASSIGNED = "@unassigned"

local function log(message)
    print(("[%s] %s"):format(RESOURCE, message))
end

local function fail(key, fatal, ...)
    return {
        ok = false,
        error = key,
        message = _U(key, ...),
        fatal = fatal or nil, -- fatal = the NUI should drop the session
    }
end

local function endSession(session)
    session.valid = false
    if sessions[session.src] == session then
        sessions[session.src] = nil
    end
end

--------------------------------------------------------------------------------
-- Validation
--------------------------------------------------------------------------------

-- NOTE: the decompiled body of this function was garbled; this is the
-- reconstruction (positive integer id, connected, framework-loaded).
local function isValidPlayer(id)
    return type(id) == "number"
        and id % 1 == 0
        and id > 0
        and GetPlayerName(id) ~= nil
        and Framework.IsLoaded(id)
end

-- Returns an error table, or nil if the admin may proceed
local function checkAdmin(src)
    if not (isValidPlayer(src) and Framework.IsAdmin(src)) then
        return fail("no_permission", true)
    end

    if not (DB.Ready and DB.Mode and Garages.Ready) then
        return fail("not_loaded", true)
    end

    return nil
end

-- Returns an error table, or nil if the session is still good
local function validateSession(session)
    local err = checkAdmin(session.src)
    if err then
        endSession(session)
        return err
    end

    local stillValid = session.valid
        and sessions[session.src] == session
        and session.expires >= os.time()
        and Framework.GetIdentifier(session.src) == session.adminIdentifier

    if not stillValid then
        endSession(session)
        return fail("admin_garage_session_expired", true)
    end

    if not (isValidPlayer(session.target) and Framework.GetIdentifier(session.target) == session.identifier) then
        endSession(session)
        return fail("admin_garage_invalid_target", true)
    end

    return nil
end

-- Vehicles can only be added to real "garage" kind entries (not impounds)
local function canAddTo(garage)
    return garage and garage.kind == "garage"
end

-- Which garage group a vehicle is listed under
local function vehicleGarageId(vehicle)
    local id
    if vehicle.state == "impounded" then
        id = vehicle.lot
            or (vehicle.meta and vehicle.meta.impound and vehicle.meta.impound.lot)
    end
    id = id or vehicle.garage

    if id and Garages.Get(id) then
        return id
    end
    return UNASSIGNED
end

--------------------------------------------------------------------------------
-- Snapshot sent to the NUI
--------------------------------------------------------------------------------

local function serializeVehicle(vehicle)
    local meta = vehicle.meta or {}
    local parked = Park.Get(vehicle.key)
    local contract = Contract.SessionForPlate(vehicle.key)

    local out = {
        key = vehicle.key,
        plate = vehicle.plate,
        model = vehicle.model,
        modelName = vehicle.modelName,
        props = vehicle.props,
        state = vehicle.state,
        garage = vehicle.garage,
        garageLabel = vehicle.garage and Garages.Label(vehicle.garage) or nil,
        lot = vehicle.lot,
        condition = Utils.Condition(vehicle.props),
        here = vehicle.state == "stored",
        vtype = meta.vtype or vehicle.vehicleType,
        class = meta.class,
        label = meta.label,
        nickname = meta.nickname,
        storedAt = meta.storedAt,
        storedBy = meta.storedBy,
        lastGarage = meta.lastGarage and Garages.Label(meta.lastGarage) or nil,
    }

    if parked then
        out.parked = {
            x = parked.x, y = parked.y, z = parked.z, at = parked.at,
            towAt = Park.TowAt(vehicle.key),
        }
    end

    if meta.impound then
        out.impound = {
            reason = meta.impound.reason,
            fee = meta.impound.fee or vehicle.depotPrice or 0,
            at = meta.impound.at,
            by = meta.impound.by,
            lot = meta.impound.lot and Garages.Label(meta.impound.lot) or nil,
        }
    end

    if contract then
        out.contract = {
            id = contract.id,
            buyer = contract.buyerName,
            price = contract.price,
            expiresAt = contract.expiresAt,
        }
    end

    return out
end

-- Returns the full payload, or an error table
local function buildSnapshot(session, message)
    local err = validateSession(session)
    if err then return err end

    local owned = DB.ListOwned(session.identifier)

    err = validateSession(session)
    if err then return err end

    local groups = {}
    local byId = {}

    local function getGroup(id)
        if byId[id] then return byId[id] end

        local garage = (id ~= UNASSIGNED) and Garages.Get(id) or nil
        local group = {
            id = id,
            label = (garage and garage.label) or _U("admin_garage_unassigned"),
            type = (garage and garage.type) or "all",
            kind = (garage and garage.kind) or "garage",
            canAdd = canAddTo(garage) or false,
            vehicles = {},
        }

        byId[id] = group
        groups[#groups + 1] = group
        return group
    end

    -- Every addable garage appears, even if the player has nothing there
    for _, garage in ipairs(Garages.All()) do
        if canAddTo(garage) then
            getGroup(garage.id)
        end
    end

    for _, vehicle in ipairs(owned or {}) do
        if vehicle.owner == session.identifier then
            local group = getGroup(vehicleGarageId(vehicle))
            group.vehicles[#group.vehicles + 1] = serializeVehicle(vehicle)
        end
    end

    -- "Unassigned" goes last; everything else by label then id
    table.sort(groups, function(a, b)
        if a.id == UNASSIGNED then return false end
        if b.id == UNASSIGNED then return true end

        local la, lb = a.label, b.label
        if la == lb then la, lb = a.id, b.id end
        return la < lb
    end)

    for _, group in ipairs(groups) do
        table.sort(group.vehicles, function(a, b) return a.plate < b.plate end)
    end

    return {
        ok = true,
        session = session.token,
        target = { id = session.target, name = Framework.GetName(session.target) },
        garages = groups,
        now = os.time(),
        message = message,
    }
end

--------------------------------------------------------------------------------
-- Session runner
--------------------------------------------------------------------------------

-- Runs `handler(session)` inside a validated session.
-- exclusive: also blocks other admins from touching the same target at once.
local function runSession(src, cb, token, exclusive, handler)
    local err = checkAdmin(src)
    if err then
        if sessions[src] then endSession(sessions[src]) end
        return cb(err)
    end

    local session = sessions[src]
    if not (type(token) == "string" and session and session.token == token) then
        return cb(fail("admin_garage_session_expired", true))
    end

    err = validateSession(session)
    if err then return cb(err) end

    if session.busy or (exclusive and activeByIdentifier[session.identifier]) then
        return cb(fail("admin_garage_busy"))
    end

    session.expires = os.time() + SESSION_TTL
    session.committed = false
    session.busy = true
    if exclusive then
        activeByIdentifier[session.identifier] = session
    end

    local ok, result = pcall(handler, session)

    -- Always release locks / flags, even if the handler threw
    if session.lock then
        Vehicles.ReleaseOwnership(session.lock.key, session.lock.token)
        session.lock = nil
    end
    if activeByIdentifier[session.identifier] == session then
        activeByIdentifier[session.identifier] = nil
    end
    session.busy = false

    if not ok then
        log(("^1admin vehicle action failed for %s: %s^7"):format(src, tostring(result)))

        -- Prefer a session error if the session died; otherwise a generic failure.
        -- If the change was already committed, the UI must reload (fatal).
        result = validateSession(session)
            or fail(session.committed and "admin_garage_refresh_failed" or "admin_garage_failed", session.committed)

        if session.committed then
            endSession(session)
        end
    end

    if session.committed and result and result.ok ~= true then
        endSession(session)
        result = fail("admin_garage_refresh_failed", true)
    end

    cb(result)
end

--------------------------------------------------------------------------------
-- Session callbacks
--------------------------------------------------------------------------------

Framework.RegisterCallback("adminGarage:open", function(source, cb, targetId)
    local err = checkAdmin(source)
    if err then return cb(err) end

    local target = tonumber(targetId)
    if not isValidPlayer(target) then
        return cb(fail("admin_garage_invalid_target", true))
    end

    if sessions[source] and sessions[source].busy then
        return cb(fail("admin_garage_busy"))
    end
    if sessions[source] then
        endSession(sessions[source])
    end

    sessionCounter = sessionCounter + 1

    local session = {
        src = source,
        adminIdentifier = Framework.GetIdentifier(source),
        target = target,
        identifier = Framework.GetIdentifier(target),
        valid = true,
        expires = os.time() + SESSION_TTL,
        token = ("AG-%x-%x-%08x"):format(os.time(), sessionCounter, math.random(0, 2147483647)),
    }
    sessions[source] = session

    runSession(source, cb, session.token, false, buildSnapshot)
end)

Framework.RegisterCallback("adminGarage:refresh", function(source, cb, token)
    runSession(source, cb, token, false, buildSnapshot)
end)

Framework.RegisterCallback("adminGarage:close", function(source, cb, token)
    local err = checkAdmin(source)
    if err then
        if sessions[source] then endSession(sessions[source]) end
        return cb(err)
    end

    local session = sessions[source]
    if session and type(token) == "string" and session.token == token then
        endSession(session)
    end

    cb({ ok = true })
end)

--------------------------------------------------------------------------------
-- Input sanitising / plate locking
--------------------------------------------------------------------------------

-- Accepts a number in int32/uint32 range and normalises to uint32 (model hashes)
local function toU32(value)
    local n = tonumber(value)
    if not (n and n == n and n % 1 == 0 and n >= -2147483648 and n <= 4294967295) then
        return nil
    end
    return n % 4294967296
end

-- Validates the model payload sent by the client. Returns a clean table or nil.
local function sanitizeModel(data)
    if type(data) ~= "table" then return nil end

    local model = toU32(data.model)
    local class = data.class

    local classOk = type(class) == "number" and class == class and class % 1 == 0 and class >= 0 and class <= 22
    if not (model and model ~= 0 and classOk) then
        return nil
    end

    local category = Utils.CategoryFromClass(class)
    if data.category ~= category then return nil end

    -- modelName is optional, but if present it must hash to the model
    local modelName = data.modelName
    if modelName ~= nil then
        local valid = type(modelName) == "string"
            and #modelName ~= 0
            and #modelName <= 48
            and modelName:match("^[%w_]+$")
            and toU32(GetHashKey(modelName)) == model

        if not valid then return nil end
    end

    local label = ""
    if type(data.label) == "string" then
        label = Utils.Trim((data.label:gsub("[%c<>]", ""))):sub(1, 96)
    end

    return {
        model = model,
        class = class,
        category = category,
        modelName = modelName,
        label = (label ~= "" and label) or modelName or tostring(model),
    }
end

-- Reserves ownership of a plate for the session. Returns true if nobody else holds it.
local function lockPlate(session, plateKey)
    local token = Vehicles.ReserveOwnership(plateKey)
    if not token then return false end

    session.lock = { key = plateKey, token = token }
    return Vehicles.OwnershipIsIdle(plateKey, token)
end

--------------------------------------------------------------------------------
-- Add / remove
--------------------------------------------------------------------------------

Framework.RegisterCallback("adminGarage:add", function(source, cb, token, garageId, vehicleData)
    runSession(source, cb, token, true, function(session)
        local garage = (type(garageId) == "string") and Garages.Get(garageId) or nil
        if not garage then return fail("garage_not_found") end
        if not canAddTo(garage) then return fail("no_access") end

        local model = sanitizeModel(vehicleData)
        if not model then return fail("admin_garage_invalid_model") end

        if not Utils.GarageAccepts(garage.type, model.category) then
            return fail("vehicle_wrong_type")
        end

        -- Plate: optional; generated if blank
        local plate = vehicleData.plate
        if plate ~= nil and type(plate) ~= "string" then
            return fail("admin_garage_invalid_plate")
        end

        plate = Utils.Trim(plate or ""):upper()
        if plate == "" then
            plate = Vehicles.NewPlate()
        end
        if not plate then return fail("admin_garage_failed") end

        if #plate > 8 or not plate:match("^[A-Z0-9 ]+$") or Utils.PlateKey(plate) == "" then
            return fail("admin_garage_invalid_plate")
        end

        local key = Utils.PlateKey(plate)

        if not lockPlate(session, key) then return fail("admin_garage_plate_taken") end
        if DB.GetByPlate(key) then return fail("admin_garage_plate_taken") end

        -- Re-validate everything after the awaits above
        local err = validateSession(session)
        if err then return err end

        garage = Garages.Get(garageId)
        if not canAddTo(garage) then return fail("no_access") end
        if not Utils.GarageAccepts(garage.type, model.category) then return fail("vehicle_wrong_type") end
        if not Vehicles.OwnershipIsIdle(key, session.lock.token) then return fail("admin_garage_plate_taken") end

        -- Brand-new vehicle in perfect condition
        local props = {
            plate = plate,
            model = model.model,
            engineHealth = 1000,
            bodyHealth = 1000,
            tankHealth = 1000,
            fuelLevel = 100,
            dirtLevel = 0,
        }

        local added = DB.AdminAddOwned({
            identifier = session.identifier,
            license = Framework.GetLicense(session.target),
            plate = plate,
            props = props,
            category = model.category,
            modelName = model.modelName,
            garage = garage.id,
        })
        if not added then return fail("admin_garage_failed") end

        session.committed = true -- from here on a failure means the UI must reload

        local metaOk, metaErr = pcall(DB.UpsertMeta, key, {
            nickname = false,
            vtype = model.category,
            stored_at = os.time(),
            stored_by = Framework.GetName(source),
            last_garage = garage.id,
            contract_id = false,
            impound_reason = false,
            impound_fee = false,
            impound_at = false,
            impound_by = false,
            impound_lot = false,
            data = { label = model.label, class = model.class },
        })
        if not metaOk then
            log(("^3admin vehicle %s added but metadata could not be saved: %s^7"):format(key, tostring(metaErr)))
        end

        log(("ADMIN VEHICLE ADD: %s (%s, id %s) -> %s (id %s), plate %s, model %s, garage %s"):format(
            Framework.GetName(source), session.adminIdentifier, source,
            session.identifier, session.target, plate, model.model, garage.id
        ))

        TriggerEvent(RESOURCE .. ":server:adminVehicleAdded", source, key, session.identifier, garage.id)

        return buildSnapshot(session, _U("admin_garage_added", model.label, plate, Framework.GetName(session.target)))
    end)
end)

Framework.RegisterCallback("adminGarage:remove", function(source, cb, token, garageId, plate)
    runSession(source, cb, token, true, function(session)
        if not (type(plate) == "string" and #plate <= 32 and type(garageId) == "string") then
            return fail("vehicle_not_owned")
        end

        local key = Utils.PlateKey(plate)
        if key == "" then return fail("vehicle_not_owned") end

        if not lockPlate(session, key) then return fail("admin_garage_vehicle_busy") end

        local vehicle = DB.GetOwnedByPlate(session.identifier, key)
        if not vehicle then return fail("vehicle_not_owned") end

        local err = validateSession(session)
        if err then return err end

        -- The UI must be looking at the same vehicle in the same garage
        if vehicle.plate ~= plate then return fail("admin_garage_failed") end
        if vehicleGarageId(vehicle) ~= garageId then return fail("admin_garage_failed") end

        -- Stored/impounded vehicles must be idle; vehicles that are out are allowed
        local removable = (vehicle.state ~= "stored" and vehicle.state ~= "impounded")
            or Vehicles.OwnershipIsIdle(key, session.lock.token)
        if not removable then return fail("admin_garage_vehicle_busy") end

        if not DB.AdminDeleteOwned(vehicle) then return fail("admin_garage_failed") end

        session.committed = true

        Vehicles.OwnershipRemoved(vehicle, session.lock.token)

        log(("ADMIN VEHICLE REMOVE: %s (%s, id %s) -> %s (id %s), plate %s, garage %s"):format(
            Framework.GetName(source), session.adminIdentifier, source,
            session.identifier, session.target, vehicle.plate, garageId
        ))

        TriggerEvent(RESOURCE .. ":server:adminVehicleRemoved", source, key, session.identifier, garageId)

        return buildSnapshot(session, _U("admin_garage_removed", vehicle.plate, Framework.GetName(session.target)))
    end)
end)

--------------------------------------------------------------------------------
-- Cleanup
--------------------------------------------------------------------------------

AddEventHandler("playerDropped", function()
    local dropped = source
    for _, session in pairs(sessions) do
        if session.src == dropped or session.target == dropped then
            endSession(session)
        end
    end
end)

-- Expire idle sessions
CreateThread(function()
    while true do
        Wait(60000)
        for _, session in pairs(sessions) do
            if not session.busy and session.expires < os.time() then
                endSession(session)
            end
        end
    end
end)

