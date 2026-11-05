

-- Cleaned from decompiler output (register-style L0_1/L1_2 names -> readable names).
--
-- NOTE: the decompiler lost part of the `canValet` expression in
-- getPhoneVehicles (several intermediate values were computed and then
-- overwritten). That block is a best-effort reconstruction and is marked
-- with a "RECONSTRUCTED" comment — verify it against the original behaviour.

local resourceName = GetCurrentResourceName()

local lastCall = {} -- [source] = game timer of last "phone:vehicles" call

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

--- Validate a player source. Returns src, identifier — or nil if invalid.
local function resolvePlayer(src)
    src = tonumber(src)
    if not (src and src > 0 and GetPlayerName(src)) then
        return nil
    end
    return src, Framework.GetIdentifier(src)
end

---------------------------------------------------------------------
-- Vehicle list for phone apps
---------------------------------------------------------------------

--- Build the vehicle list shown in a phone app.
--- @param src       player source
--- @param phoneType optional phone resource name ("codem" adds extra fields)
local function getPhoneVehicles(src, phoneType)
    local identifier
    src, identifier = resolvePlayer(src)

    local phoneEnabled = (Config.Phone or {}).enabled ~= false
    if not (phoneEnabled and src and identifier and DB.Ready and Garages.Ready) then
        return {}
    end

    local result = {}

    for _, vehicle in ipairs(DB.ListOwned(identifier)) do
        local meta = vehicle.meta or {}
        local isParked = Park.IsParked(vehicle.key)
        local garage = vehicle.garage and Garages.Get(vehicle.garage)
        local category = Vehicles.PhoneCategory(vehicle)

        -- RECONSTRUCTED: can the vehicle be valeted from the phone?
        -- The original also read garage.kind / garage.personal, along with
        -- Vehicles.IsOut / IsPending and Contract.IsLocked, but the
        -- decompiler dropped how they were combined. This is the most
        -- plausible reading; adjust if the original rules differed.
        local canValet = false
        if garage
            and vehicle.state == "stored"
            and not isParked
            and not Vehicles.IsOut(vehicle.key)
            and not Vehicles.IsPending(vehicle.key)
            and not Contract.IsLocked(vehicle.key)
            and Garages.CanAccess(src, garage)
            and Vehicles.IsLocalVehicle(vehicle)
        then
            canValet = true
        end
        canValet = canValet and (category == "car" or category == "motorcycle")

        local location
        if vehicle.state == "out" or isParked then
            location = "out"
        else
            location = Garages.Label(vehicle.lot or vehicle.garage)
        end

        local phoneType_ -- vehicle type as the phone UI expects it
        if category == "motorcycle" then
            phoneType_ = "bike"
        elseif category == "air" then
            phoneType_ = "plane"
        else
            phoneType_ = category or "car"
        end

        local entry = {
            plate        = vehicle.plate,
            key          = vehicle.key,
            model        = vehicle.model,
            modelName    = vehicle.modelName,
            label        = meta.nickname or meta.label or vehicle.modelName or vehicle.plate,
            state        = vehicle.state,
            garage       = vehicle.garage,
            garageLabel  = Garages.Label(vehicle.garage),
            location     = location,
            impounded    = vehicle.state == "impounded",
            parked       = isParked,
            canValet     = canValet == true,
            statistics   = Utils.Condition(vehicle.props),
            type         = phoneType_,
            impoundReason = meta.impound and {
                reason    = meta.impound.reason,
                price     = meta.impound.fee,
                impounder = meta.impound.by,
            } or nil,
        }

        -- Extra fields for the CodeM phone
        if phoneType == "codem" then
            entry.inGarage  = entry.canValet
            entry.spawncode = entry.model
            entry.mods      = json.encode(vehicle.props)
        end

        result[#result + 1] = entry
    end

    return result
end

---------------------------------------------------------------------
-- Locate / transfer
---------------------------------------------------------------------

--- Start locating a vehicle (waypoint etc.). Returns a result table.
local function locateVehicle(src, target)
    if (Config.Phone or {}).enabled == false then
        return { ok = false, error = "no_access" }
    end

    src = resolvePlayer(src)
    if not src then
        return { ok = false, error = "no_access" }
    end

    local result
    Vehicles.Locate(src, function(res)
        result = res
    end, target)

    return result or { ok = false, error = "busy" }
end

--- Transfer a vehicle to another garage. The meaning of a1/a2/a3 is defined
--- by Vehicles.TransferToGarage(src, cb, a2, a1, a3) — names inferred from
--- argument order only.
local function transferVehicleToGarage(src, a1, a2, a3)
    src = resolvePlayer(src)
    if not src then
        return { ok = false, error = "no_access" }
    end

    local result
    Vehicles.TransferToGarage(src, function(res)
        result = res
    end, a2, a1, a3)

    return result or { ok = false, error = "busy" }
end

---------------------------------------------------------------------
-- Exports
---------------------------------------------------------------------

exports("GetPhoneVehicles", getPhoneVehicles)
exports("LocateVehicle", locateVehicle)
exports("TransferVehicleToGarage", transferVehicleToGarage)

--- options.charge (default true): charge the player for the valet.
--- If a2 is nil the vehicle is spawned externally by the calling resource.
exports("PreparePhoneVehicle", function(src, a1, a2, a3, options)
    if type(options) ~= "table" then
        options = {}
    end

    return Vehicles.PreparePhoneVehicle(src, a1, a2, a3, {
        externalSpawn = (a2 == nil),
        charge = options.charge ~= false,
    })
end)

-- Note: these two capture the function values at load time, as in the original.
exports("CancelPhoneVehicle", Vehicles.CancelPhoneVehicle)
exports("ConfirmPhoneVehicle", Vehicles.ConfirmPhoneVehicle)

---------------------------------------------------------------------
-- Callbacks (used by the in-game UI)
---------------------------------------------------------------------

Framework.RegisterCallback("phone:vehicles", function(src, cb)
    -- Rate limit: one request per second per player
    local now = GetGameTimer()
    if lastCall[src] and (now - lastCall[src]) < 1000 then
        return cb({ ok = false, error = "busy" })
    end
    lastCall[src] = now

    if (Config.Phone or {}).enabled == false then
        return cb({ ok = false, error = "no_access" })
    end

    if not (DB.Ready and Garages.Ready) then
        return cb({ ok = false, error = "not_loaded" })
    end

    cb({ ok = true, vehicles = getPhoneVehicles(src) })
end)

Framework.RegisterCallback("phone:locate", function(src, cb, target)
    cb(locateVehicle(src, target))
end)

Framework.RegisterCallback("phone:valet", function(src, cb, a1, a2, a3)
    cb(Vehicles.PreparePhoneVehicle(src, a1, a2, a3))
end)

Framework.RegisterCallback("phone:cancel", function(src, cb, id)
    cb({ ok = Vehicles.CancelPhoneVehicle(src, id) })
end)

AddEventHandler("playerDropped", function()
    lastCall[source] = nil
end)

