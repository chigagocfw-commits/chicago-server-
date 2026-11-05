

-- Cleaned from decompiler output (register-style L0_1/L1_2 names -> readable names).
-- Logic is preserved; tangled goto/if chains were rebuilt by intent.
--
-- Spots marked "RECONSTRUCTED" are places where the decompiler lost part of
-- an expression; verify them against the original behaviour.
--
-- Terminology used below
--   key          normalised plate (Utils.PlateKey)
--   outVehicles  vehicles currently taken out of a garage and live in the world
--   pending      spawn "sessions" waiting for the client to confirm the spawn
--   ownershipLocks  short-lived per-plate locks so only one operation touches a vehicle
--   fleetOut / fleetPending   same idea for job/gang fleet vehicles (not DB-backed)

Vehicles = Vehicles or {}

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

local outVehicles     = {}  -- [key] = { src, identifier, netId, garage, since }
local pending         = {}  -- [key] = spawn session
local lastSeen        = {}  -- [key] = { x, y, z, at }  last known world position
local ownershipLocks  = {}  -- [key] = token table
local lostSince       = {}  -- [key] = os.time() when first seen "lost"
local scanning        = false
local lostCounter     = 0

local SPAWN_CONFIRM_TIMEOUT    = 30000  -- ms to wait for the client to confirm a spawn
local LOCATION_REFRESH_INTERVAL = 15000 -- ms between last-seen updates

local rateLimits = {}       -- [src] = { [action] = last GetGameTimer() }

local fleetOut     = {}     -- [key] = { src, owner, garage, index, plate, netId, at }
local fleetPending = {}     -- [key] = { src, owner, garage, index, plate, model, at }

---------------------------------------------------------------------
-- Generic helpers
---------------------------------------------------------------------

--- Per-player, per-action rate limit. Returns false if called again within `ms`.
local function throttle(src, action, ms)
    local now = GetGameTimer()
    rateLimits[src] = rateLimits[src] or {}

    local last = rateLimits[src][action]
    if last and ms > (now - last) then
        return false
    end

    rateLimits[src][action] = now
    return true
end

AddEventHandler("playerDropped", function()
    rateLimits[source] = nil
end)

--- Reply to a callback with a localised error.
local function fail(cb, errorKey, ...)
    cb({
        ok = false,
        error = errorKey,
        message = _U(errorKey, ...),
    })
end

--- Network id -> vehicle entity, or nil.
local function vehicleFromNetId(netId)
    if not netId or netId == 0 then
        return nil
    end

    local ok, entity = pcall(NetworkGetEntityFromNetworkId, netId)
    if ok and entity and entity ~= 0 and DoesEntityExist(entity) and GetEntityType(entity) == 2 then
        return entity
    end
    return nil
end

local function plateOf(entity)
    local ok, text = pcall(GetVehicleNumberPlateText, entity)
    return ok and Utils.Trim(text or "") or ""
end

local function safeDelete(entity)
    if entity and DoesEntityExist(entity) then
        pcall(DeleteEntity, entity)
    end
end

--- Best display name for an owned vehicle.
local function displayLabel(vehicle)
    if vehicle.meta and vehicle.meta.nickname then return vehicle.meta.nickname end
    if vehicle.meta and vehicle.meta.label then return vehicle.meta.label end
    return vehicle.modelName or ("#" .. tostring(vehicle.key))
end

local function metaVtype(vehicle)
    return vehicle.meta and vehicle.meta.vtype or nil
end

--- Does `garage` accept this vehicle's type?
local function garageAcceptsVehicle(garage, vehicle, category)
    if not Config.Garage.typeCheck or garage.type == "all" then
        return true
    end

    local vtype = metaVtype(vehicle) or category
    if not vtype then
        return true
    end

    return Utils.GarageAccepts(garage.type, vtype)
end

--- The garage (kind "garage") a vehicle is currently stored in, if any.
local function homeGarage(vehicle)
    local garage = vehicle.garage and Garages.Get(vehicle.garage)
    if garage and garage.kind == "garage" then
        return garage
    end
    return nil
end

--- A "local" vehicle is one stored in a regular garage (as opposed to a lot).
function Vehicles.IsLocalVehicle(vehicle)
    return homeGarage(vehicle) ~= nil
end

--- May this vehicle be used from `garage`?
function Vehicles.CanUseFromGarage(vehicle, garage)
    if garage.kind ~= "garage" or vehicle.state == "impounded" then
        return true
    end

    local home = homeGarage(vehicle)
    if not home or home.id == garage.id then
        return true
    end

    return garage.localVehiclesOnly ~= true
end

--- For garages with localVehiclesOnly: is the player close enough to it?
local function playerNearGarage(src, garage)
    if garage.localVehiclesOnly ~= true then
        return true
    end

    local ped = GetPlayerPed(src)
    if not (ped and ped ~= 0 and DoesEntityExist(ped)) then
        return false
    end

    local radius = Utils.Clamp(tonumber(garage.radius) or 2.5, 1.0, 15.0)
    local coords = GetEntityCoords(ped)
    local limit = math.max(5.0, radius + 5.0)

    if limit >= Utils.Dist(coords, garage.point) then
        return true
    end

    for _, spot in ipairs(garage.spots or {}) do
        if limit >= Utils.Dist(coords, spot) then
            return true
        end
    end

    return false
end

--- Find a live vehicle entity by plate key (scans all server vehicles).
local function findEntityByPlate(key)
    local ok, all = pcall(GetAllVehicles)
    if not (ok and type(all) == "table") then
        return nil
    end

    for _, entity in ipairs(all) do
        if DoesEntityExist(entity) and Utils.PlateKey(plateOf(entity)) == key then
            return entity
        end
    end
    return nil
end

local function isOccupied(entity)
    for seat = -1, 6 do
        local ok, ped = pcall(GetPedInVehicleSeat, entity, seat)
        if ok and ped and ped ~= 0 then
            return true
        end
    end
    return false
end

--- Best-effort lookup of the world entity for an owned plate.
local function findLiveEntity(key)
    local record = outVehicles[key]
    local entity = record and vehicleFromNetId(record.netId)

    if entity and Utils.PlateKey(plateOf(entity)) ~= key then
        entity = nil
    end

    return entity or Park.Entity(key) or findEntityByPlate(key)
end

--- Number coercion with bounds; NaN/inf fall back to `default`.
local function clampNumber(value, default, min, max)
    value = tonumber(value)
    if not (value and value == value and value ~= math.huge and value ~= -math.huge) then
        value = default
    end
    return math.max(min, math.min(max, value))
end

local function toUInt32(n)
    return math.floor(tonumber(n) or 0) % 4294967296
end

local function sanitisePhysicalProps(props, entity, plateText)
    props.plate        = plateText
    props.model        = GetEntityModel(entity)
    props.engineHealth = Utils.Clamp(tonumber(props.engineHealth) or 1000, -4000, 1000)
    props.bodyHealth   = Utils.Clamp(tonumber(props.bodyHealth) or 1000, 0, 1000)
    props.tankHealth   = Utils.Clamp(tonumber(props.tankHealth) or 1000, -4000, 1000)
    props.fuelLevel    = Utils.Clamp(tonumber(props.fuelLevel) or 100, 0, 100)
    props.dirtLevel    = Utils.Clamp(tonumber(props.dirtLevel) or 0, 0, 15)
    return props
end

---------------------------------------------------------------------
-- Recovery policy (what happens to vehicles that are "out" but not in the world)
---------------------------------------------------------------------

function Vehicles.RecoveryPolicy()
    local cfg = type(Config.Garage.lostVehicles) == "table" and Config.Garage.lostVehicles or {}
    local impound = type(cfg.impound) == "table" and cfg.impound or {}

    local mode
    if cfg.mode == nil then
        mode = "garage"
    else
        mode = tostring(cfg.mode):lower()
    end
    if mode ~= "garage" and mode ~= "impound" and mode ~= "disabled" then
        mode = "disabled"
    end

    local reason = Utils.Trim(tostring(impound.reason or "Abandoned / lost vehicle"))
    reason = reason:gsub("[%c<>]", "")
    if reason == "" then
        reason = "Abandoned / lost vehicle"
    end

    local maxFee = math.floor(clampNumber(Config.Impound.maxFee, 25000, 0, 10000000))

    return {
        mode          = mode,
        autoImpound   = cfg.autoImpound ~= false,
        graceSeconds  = math.floor(clampNumber(cfg.graceSeconds, 120, 0, 86400)),
        checkInterval = math.floor(clampNumber(cfg.checkInterval, 60, 5, 3600)),
        lot           = impound.lot,
        fee           = math.floor(clampNumber(impound.fee, 500, 0, maxFee)),
        reason        = reason:sub(1, 120),
    }
end

--- True while a recovery/impound operation holds the plate.
function Vehicles.IsRecovering(key)
    return ownershipLocks[key] ~= nil
end

---------------------------------------------------------------------
-- World snapshots (used to decide whether a vehicle really is missing)
---------------------------------------------------------------------

-- Weak-keyed set of active snapshots; entityCreated/Removed keep them current.
local scans = setmetatable({}, { __mode = "k" })

AddEventHandler("entityCreated", function(entity)
    for scan in pairs(scans) do
        scan.entities[entity] = true
    end
end)

AddEventHandler("entityRemoved", function(entity)
    for scan in pairs(scans) do
        scan.entities[entity] = nil
    end
end)

local function beginWorldSnapshot()
    local ok, all = pcall(GetAllVehicles)
    if not (ok and type(all) == "table") then
        return nil
    end

    local scan = { entities = {}, plates = {} }
    for _, entity in ipairs(all) do
        if DoesEntityExist(entity) then
            scan.entities[entity] = true
            scan.plates[Utils.PlateKey(plateOf(entity))] = true
        end
    end

    scans[scan] = true
    return scan
end

--- Is a vehicle with this plate currently in the world according to the snapshot?
local function snapshotHasPlate(scan, key)
    for entity in pairs(scan.entities) do
        if not DoesEntityExist(entity) then
            scan.entities[entity] = nil
        elseif GetEntityType(entity) == 2 and Utils.PlateKey(plateOf(entity)) == key then
            return true
        end
    end
    return false
end

--- Any operation or state that makes a vehicle "not available" for recovery.
local function isBusy(key)
    return pending[key] or Park.IsParked(key) or Contract.IsLocked(key)
end

---------------------------------------------------------------------
-- Lost-vehicle impounding
---------------------------------------------------------------------

local function isImpoundLot(garage)
    return garage and garage.kind == "impound"
end

--- Choose the impound lot for a lost vehicle: the configured lot, otherwise
--- the lot closest to where the vehicle came from.
local function findImpoundLot(vehicle, policy)
    if policy.lot ~= nil then
        local lot = Garages.Get(policy.lot)
        if lot and isImpoundLot(lot) then
            return lot
        end
        return nil
    end

    local home = homeGarage(vehicle)
    local origin = (home and home.point) or lastSeen[vehicle.key]

    local lots = {}
    for _, garage in pairs(Garages.List or {}) do
        if isImpoundLot(garage) then
            lots[#lots + 1] = garage
        end
    end

    table.sort(lots, function(a, b)
        local da = origin and Utils.Dist(origin, a.point) or 0
        local db = origin and Utils.Dist(origin, b.point) or 0
        if da == db then
            return tostring(a.id) < tostring(b.id)
        end
        return da < db
    end)

    return lots[1]
end

--- Impound a vehicle that is marked "out" but cannot be found in the world.
--- Returns: success, messageKey, vehicle, lot
local function impoundLostVehicle(key, policy, expectedOwner, snapshot)
    if ownershipLocks[key] or isBusy(key) then
        lostSince[key] = nil
        return false, "vehicle_out"
    end

    local lock = {}
    ownershipLocks[key] = lock

    local ok, r1, r2, r3, r4 = pcall(function()
        local vehicle = DB.GetByPlate(key)
        if not (vehicle and vehicle.state == "out"
            and (not expectedOwner or vehicle.owner == expectedOwner)) then
            lostSince[key] = nil
            return false, "vehicle_out"
        end

        -- Is the vehicle still lost, and do we still hold the lock?
        local function stillLost()
            if isBusy(key) or snapshotHasPlate(snapshot, key) then
                lostSince[key] = nil
                return false
            end
            return ownershipLocks[key] == lock
        end

        if not stillLost() then
            return false, "lost_vehicle_present"
        end

        local lot = findImpoundLot(vehicle, policy)
        if not lot then
            return false, "impound_no_lot"
        end

        local firstSeen = lostSince[key] or os.time()
        lostSince[key] = firstSeen
        if os.time() - firstSeen < policy.graceSeconds then
            return false, "lost_vehicle_wait"
        end

        lostCounter = lostCounter + 1
        local now = os.time()
        local marker = ("system:lost:%s:%s"):format(GetGameTimer(), lostCounter)

        local success = DB.SetLostImpounded(vehicle, lot.id, policy.fee, policy.reason, now, marker, stillLost)
        if not success then
            return false, stillLost() and "store_failed" or "lost_vehicle_present"
        end

        -- The vehicle showed up while we were writing: undo the impound.
        if not stillLost() then
            local rollback
            rollback = function()
                local restoredOk, restored = pcall(DB.RestoreLostOut, vehicle, lot.id, now, marker)
                if restoredOk and restored then
                    if ownershipLocks[key] == lock then
                        ownershipLocks[key] = nil
                    end
                    return true
                end

                local readOk, current = pcall(DB.GetByPlate, key)
                local meta = readOk and current and current.meta and current.meta.impound

                if readOk then
                    local stillOurImpound = current
                        and current.state == "impounded"
                        and current.owner == vehicle.owner
                        and current.lot == lot.id
                        and meta
                        and meta.lot == lot.id
                        and meta.by == marker
                        and meta.at == now

                    if not stillOurImpound then
                        -- Someone else changed it; nothing left for us to undo.
                        if ownershipLocks[key] == lock then
                            ownershipLocks[key] = nil
                        end
                        return true
                    end
                end

                log(("^1lost-vehicle rollback for %s is waiting for the database^7"):format(key))
                lock.retrying = true
                SetTimeout(5000, rollback)
                return false
            end

            rollback()
            return false, "lost_vehicle_present"
        end

        -- Success: clear runtime state, take keys, notify the owner.
        outVehicles[key] = nil
        lastSeen[key] = nil
        lostSince[key] = nil

        local owner = Framework.GetPlayerByIdentifier(vehicle.owner)
        if owner then
            pcall(Keys.RemoveServer, owner, 0, vehicle.plate, vehicle.model, true)
            Framework.Notify(owner,
                _U("impound_notify_owner", displayLabel(vehicle), vehicle.plate, policy.reason),
                "warning")
        end

        TriggerEvent(resourceName .. ":server:vehicleImpounded", key, lot.id, policy.fee, policy.reason, 0)
        return true, "lost_impound_sent", vehicle, lot
    end)

    if ownershipLocks[key] == lock and not lock.retrying then
        ownershipLocks[key] = nil
    end

    if not ok then
        log(("^1lost-vehicle recovery failed for %s: %s^7"):format(key, tostring(r1)))
        return false, "store_failed"
    end

    return r1, r2, r3, r4
end

--- Periodic scan: impound vehicles that have been "out" but missing for too long.
--- Returns the number of vehicles impounded.
function Vehicles.ProcessLostVehicles()
    local policy = Vehicles.RecoveryPolicy()

    if scanning or not (DB.Ready and Garages.Ready) then
        return 0
    end

    if policy.mode ~= "impound" then
        lostSince = {}
        return 0
    end

    scanning = true

    local ok, result = pcall(function()
        local keys = DB.ListOutKeys()
        local seen = {}
        local impounded = 0

        local snapshot = beginWorldSnapshot()
        if not snapshot then
            lostSince = {}
            return 0
        end

        local now = os.time()

        for _, key in ipairs(keys) do
            seen[key] = true

            if ownershipLocks[key] or isBusy(key) or snapshot.plates[key] then
                lostSince[key] = nil
            else
                lostSince[key] = lostSince[key] or now

                if policy.autoImpound and (now - lostSince[key]) >= policy.graceSeconds then
                    if impoundLostVehicle(key, policy, nil, snapshot) then
                        impounded = impounded + 1
                    end
                end
            end
        end

        for key in pairs(lostSince) do
            if not seen[key] then
                lostSince[key] = nil
            end
        end

        scans[snapshot] = nil
        return impounded
    end)

    scanning = false

    if not ok then
        lostSince = {}
        log(("^1lost-vehicle scan failed: %s^7"):format(tostring(result)))
        return 0
    end

    return result
end

CreateThread(function()
    while true do
        Wait(Vehicles.RecoveryPolicy().checkInterval * 1000)
        Vehicles.ProcessLostVehicles()
    end
end)

--- Remember where a live vehicle was last seen.
local function rememberLocation(key, entity)
    local coords = GetEntityCoords(entity)
    lastSeen[key] = { x = coords.x, y = coords.y, z = coords.z, at = os.time() }
end

---------------------------------------------------------------------
-- Fleet (job/gang vehicles defined on a garage; not stored in the DB)
---------------------------------------------------------------------

--- Player's grade for a job/gang garage (nil if the garage is not job/gang based,
--- -1 if the player does not qualify).
local function fleetGrade(src, garage)
    local mode = garage.access and garage.access.mode

    if mode == "job" then
        local job = Framework.GetJob(src)
        if job and garage.access.jobs and garage.access.jobs[job.name] ~= nil then
            return job.grade
        end
        return -1
    elseif mode == "gang" then
        local gang = Framework.GetGang(src)
        return (gang and gang.grade) or -1
    end

    return nil
end

--- Max fleet vehicles one player may have out at once (0 = unlimited).
local function fleetPerPlayer(garage)
    local value = garage.fleetPerPlayer
    if value == nil then
        value = Config.Garage.fleetPerPlayer
    end
    return math.max(0, math.floor(tonumber(value) or 1))
end

--- All fleet vehicles (spawned or about to spawn) belonging to `garage`.
local function fleetEntries(garage, src, identifier)
    local list = {}

    local recall = garage.fleetRecall
    if recall == nil then
        recall = Config.Garage.fleetRecall ~= false
    end

    for key, record in pairs(fleetOut) do
        if record.garage == garage.id then
            local entity = vehicleFromNetId(record.netId)

            if entity and Utils.PlateKey(plateOf(entity)) == key then
                list[#list + 1] = {
                    key   = key,
                    x     = record,
                    mine  = (identifier ~= nil and record.owner == identifier),
                    spare = recall and not isOccupied(entity),
                }
            else
                fleetOut[key] = nil -- entity is gone
            end
        end
    end

    for key, record in pairs(fleetPending) do
        if record.garage == garage.id then
            list[#list + 1] = {
                key     = key,
                x       = record,
                pending = true,
                mine    = (identifier ~= nil and record.owner == identifier),
            }
        end
    end

    -- settled vehicles first, then oldest first
    table.sort(list, function(a, b)
        local pa, pb = a.pending or false, b.pending or false
        if pa ~= pb then
            return not a.pending
        end
        return (a.x.at or 0) < (b.x.at or 0)
    end)

    return list
end

--- Work out whether another fleet vehicle of model `index` may be taken out.
--- Returns: entriesToRecall, modelLimitHitWithNoSpare, playerLimitHitWithNoSpare, outCountForModel
local function fleetAvailability(entries, index, def, perPlayer)
    local toRecall = {}
    local modelBlocked = false
    local playerBlocked = false
    local outCount = 0
    local spareOfModel = nil

    for _, entry in ipairs(entries) do
        if entry.x.index == index then
            outCount = outCount + 1
            if entry.spare and not spareOfModel then
                spareOfModel = entry
            end
        end
    end

    if def.count > 0 and outCount >= def.count then
        if spareOfModel then
            toRecall[1] = spareOfModel
        else
            modelBlocked = true
        end
    end

    if perPlayer > 0 then
        local mine = 0
        local spareMine = nil

        for _, entry in ipairs(entries) do
            if entry.mine and entry ~= toRecall[1] then
                mine = mine + 1
                if entry.spare and not spareMine then
                    spareMine = entry
                end
            end
        end

        if perPlayer <= mine then
            if spareMine then
                toRecall[#toRecall + 1] = spareMine
            else
                playerBlocked = true
            end
        end
    end

    return toRecall, modelBlocked, playerBlocked, outCount
end

--- Return a fleet vehicle: remove keys and delete the entity.
local function fleetReturn(key, record)
    fleetOut[key] = nil

    local entity = vehicleFromNetId(record.netId)
    if entity and Utils.PlateKey(plateOf(entity)) == key then
        if Framework.GetIdentifier(record.src) == record.owner then
            pcall(Keys.RemoveServer, record.src, entity, plateOf(entity), GetEntityModel(entity), true)
        end
        safeDelete(entity)
    end

    TriggerEvent(resourceName .. ":server:fleetReturned", record.src, key, record.garage)
end

--- Plate prefix for a fleet garage (configured, or first 4 alphanumerics of its id).
local function fleetPlatePrefix(garage)
    return garage.fleetPlate or garage.id:upper():gsub("[^%w]", ""):sub(1, 4)
end

--- Does `plate` look like a fleet plate belonging to a garage's fleet model?
--- Returns { garage = id, index = n } or nil.
local function detectFleetVehicle(plate, entity)
    local modelHash = toUInt32(GetEntityModel(entity))

    for _, garage in pairs(Garages.List or {}) do
        if garage.kind == "garage" and type(garage.fleet) == "table" and #garage.fleet > 0 then
            local prefix = Utils.PlateKey(fleetPlatePrefix(garage))

            if prefix ~= ""
                and plate:sub(1, #prefix) == prefix
                and plate:sub(#prefix + 1):match("^%d+$") then

                for index, def in ipairs(garage.fleet) do
                    if toUInt32(GetHashKey(def.model)) == modelHash then
                        if DB.GetByPlate(plate) then
                            return nil -- a real owned vehicle has this plate
                        end
                        return { garage = garage.id, index = index }
                    end
                end
            end
        end
    end

    return nil
end

--- Generate an unused plate for a fleet vehicle.
local function newFleetPlate(garage)
    local prefix = fleetPlatePrefix(garage)
    local digits = math.max(2, 7 - #prefix)
    local modulus = 10 ^ digits

    for _ = 1, 40 do
        local plate = ("%s %0" .. digits .. "d"):format(prefix, math.random(0, modulus - 1))
        local key = Utils.PlateKey(plate)

        if not DB.GetByPlate(key)
            and not fleetOut[key]
            and not fleetPending[key]
            and not pending[key]
            and not ownershipLocks[key]
            and not Park.IsParked(key) then
            return plate
        end
    end

    return nil
end

--- Vehicle props for a fleet vehicle definition.
local function fleetProps(def, plate)
    local props = {
        model        = GetHashKey(def.model),
        plate        = plate,
        fuelLevel    = 100.0,
        dirtLevel    = 0.0,
        engineHealth = 1000.0,
        bodyHealth   = 1000.0,
        tankHealth   = 1000.0,
    }

    if (def.livery or -1) >= 0 then
        props.modLivery = def.livery
    end

    local extras = Utils.SanitiseFleetExtras(def.extras)
    if extras then
        props.extras = {}
        for id = 0, 20 do
            props.extras[tostring(id)] = false
        end
        for _, id in ipairs(extras) do
            props.extras[tostring(id)] = true
        end
    end

    if def.tuned then
        props.modTurbo        = true
        props.modArmor        = 4
        props.modSuspension   = 3
        props.modTransmission = 2
        props.modBrakes       = 2
        props.modEngine       = 3
    end

    return props
end

--- Fleet entries shown in the garage UI.
local function fleetVehicleList(src, garage)
    local result = {}

    if garage.kind ~= "garage" or type(garage.fleet) ~= "table" then
        return result
    end

    local grade = fleetGrade(src, garage)
    local prefix = fleetPlatePrefix(garage)
    local perPlayer = fleetPerPlayer(garage)
    local entries = fleetEntries(garage, src, Framework.GetIdentifier(src))

    for index, def in ipairs(garage.fleet) do
        local toRecall, modelBlocked, playerBlocked, outCount =
            fleetAvailability(entries, index, def, perPlayer)

        local recallPlates, recallLeft
        if not modelBlocked and not playerBlocked and #toRecall > 0 then
            recallPlates = {}
            for _, entry in ipairs(toRecall) do
                recallPlates[#recallPlates + 1] = entry.x.plate or entry.key
                if not entry.mine then
                    recallLeft = true
                end
            end
        end

        result[#result + 1] = {
            plate     = ("%s %02d"):format(prefix, index),
            key       = ("FLEET:%s:%d"):format(garage.id, index),
            model     = GetHashKey(def.model),
            modelName = def.model,
            label     = def.label,
            state     = "fleet",
            here      = true,
            props     = fleetProps(def, ""),
            condition = { engine = 100, body = 100, fuel = 100 },
            fleet = {
                index        = index,
                minGrade     = def.minGrade,
                count        = def.count,
                out          = outCount,
                subcategory  = def.subcategory,
                -- RECONSTRUCTED: the decompiler only kept `grade == nil`; the
                -- takeout callback rejects grade < minGrade, so this mirrors it.
                allowed      = (grade == nil) or (grade >= (def.minGrade or 0)),
                available    = not modelBlocked,
                limitReached = playerBlocked,
                perPlayer    = perPlayer,
                recall       = recallPlates,
                recallLeft   = recallLeft,
                tuned        = def.tuned or nil,
            },
        }
    end

    return result
end

-- Drop fleet records whose entity no longer exists
CreateThread(function()
    while true do
        Wait(30000)

        for key, record in pairs(fleetOut) do
            local entity = vehicleFromNetId(record.netId)
            if not (entity and Utils.PlateKey(plateOf(entity)) == key) then
                fleetOut[key] = nil
            end
        end
    end
end)

function Vehicles.FleetOut()
    return fleetOut
end

---------------------------------------------------------------------
-- Money
---------------------------------------------------------------------

--- Charge a player. Returns true if nothing to charge or payment succeeded.
local function charge(src, account, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return true
    end

    if account ~= "cash" and account ~= "bank" then
        account = "bank"
    end

    return Framework.RemoveMoney(src, account, amount, "garage")
end

local function balances(src)
    return {
        cash = Framework.GetMoney(src, "cash"),
        bank = Framework.GetMoney(src, "bank"),
    }
end

---------------------------------------------------------------------
-- Spawn sessions
---------------------------------------------------------------------

--- Clear impound metadata once the owner actually has the vehicle.
local function clearImpoundIfNeeded(session, key)
    if not (session.impound and not session.impoundCleared) then
        return
    end

    DB.ClearImpound(key)
    DB.UpsertMeta(key, { last_garage = session.garage })
    session.impoundCleared = true
end

--- Undo a spawn that was never confirmed (or failed): restore the DB state and
--- refund any fee. Returns true if the vehicle was successfully put back.
local function revertSpawn(key, session)
    if pending[key] ~= session then
        return false
    end
    if session.approving or session.reverting then
        return false
    end
    if session.confirming then
        SetTimeout(1000, function()
            revertSpawn(key, session)
        end)
        return false
    end

    session.reverting = true

    --- If the vehicle actually exists in the world after all, adopt it as "out".
    local function adoptSpawnedEntity()
        local entity = findEntityByPlate(key)
        if not entity then
            return false
        end

        if session.restored or session.impoundRestoredState then
            if not DB.SetOut(session.v) then
                error("could not keep replicated vehicle out")
            end
            session.impoundRestoredState = false
            session.restored = false
        end

        clearImpoundIfNeeded(session, key)

        if DoesEntityExist(entity) then
            if Utils.PlateKey(plateOf(entity)) == key then
                outVehicles[key] = {
                    src = session.src,
                    identifier = session.v.owner,
                    netId = NetworkGetNetworkIdFromEntity(entity),
                    garage = session.garage,
                    since = os.time(),
                }

                if Framework.GetIdentifier(session.src) == session.v.owner then
                    local expectedModel = session.v.model
                        or (session.v.props and session.v.props.model)

                    if toUInt32(GetEntityModel(entity)) == toUInt32(expectedModel)
                        and GetEntityRoutingBucket(entity) == GetPlayerRoutingBucket(session.src) then
                        Keys.GiveServer(session.src, entity, plateOf(entity), GetEntityModel(entity))
                    end
                end
            end
        end

        return true
    end

    local ok, result = pcall(function()
        if adoptSpawnedEntity() then
            return false
        end

        -- Restore DB state
        if not session.restored then
            local restored

            if session.impound then
                if not session.impoundRestoredState then
                    session.impoundRestoredState =
                        DB.SetImpounded(session.v, session.impoundLot, session.impoundFee) == true
                end

                restored = session.impoundRestoredState
                if restored then
                    local old = (session.v.meta and session.v.meta.impound) or {}
                    DB.UpsertMeta(key, {
                        impound_reason = old.reason or false,
                        impound_fee    = session.impoundFee or 0,
                        impound_at     = old.at or false,
                        impound_by     = old.by or false,
                        impound_lot    = session.impoundLot,
                    })
                    session.impoundCleared = false
                end
            else
                restored = DB.SetParking(session.v, session.garage)
            end

            if not restored then
                error("could not restore vehicle state")
            end
            session.restored = true
        end

        if adoptSpawnedEntity() then
            return false
        end

        -- Refund any fee that was charged
        if session.fee and session.fee > 0 then
            local refunded
            if Framework.GetIdentifier(session.src) == session.v.owner then
                refunded = Framework.AddMoney(session.src, session.account, session.fee, "garage-spawn-refund")
            else
                refunded = DB.AddMoneyOffline(session.v.owner, session.account, session.fee)
            end

            if not refunded then
                error("could not refund valet fee")
            end
            session.fee = nil
        end

        if adoptSpawnedEntity() then
            return false
        end

        return true
    end)

    if not ok then
        session.reverting = false
        log(("^1spawn rollback failed for %s: %s^7"):format(key, tostring(result)))

        SetTimeout(5000, function()
            revertSpawn(key, session)
        end)
        return false
    end

    if pending[key] == session then
        pending[key] = nil
    end

    return result
end

--- Start spawning an owned vehicle for a player: validates it is still in the
--- state the UI saw, charges any fee, marks it "out", and asks the client to spawn.
local function beginSpawn(src, cb, garage, vehicle, spotIndex, opts)
    opts = opts or {}

    local spot = opts.spot or garage.spots[spotIndex]
    if not spot then
        return fail(cb, "spot_occupied")
    end

    if pending[vehicle.key] or ownershipLocks[vehicle.key] then
        return fail(cb, "vehicle_out")
    end

    local session = {
        src         = src,
        garage      = vehicle.garage or garage.id,
        spot        = spotIndex,
        at          = GetGameTimer(),
        v           = vehicle,
        phone       = opts.phone,
        coords      = spot,
        account     = opts.account,
        approving   = true,
        impound     = opts.impound,
        impoundLot  = vehicle.lot or garage.id,
        impoundFee  = opts.impound and opts.fee or nil,
    }
    pending[vehicle.key] = session

    local fee = opts.fee or 0

    local ok, result = pcall(function()
        local current = DB.GetOwnedByPlate(vehicle.owner, vehicle.key)

        -- Vehicle must be unchanged since the UI listed it
        if not (current
            and Framework.GetIdentifier(src) == vehicle.owner
            and current.state == vehicle.state
            and current.model == vehicle.model
            and current.garage == vehicle.garage
            and current.lot == vehicle.lot) then
            return false
        end

        if opts.impound then
            local currentFee = ((current.meta or {}).impound or {}).fee
            local listedFee  = ((vehicle.meta or {}).impound or {}).fee
            if not (current.depotPrice == vehicle.depotPrice and currentFee == listedFee) then
                return false
            end
        end

        session.v = current
        vehicle = current

        if fee > 0 then
            if not charge(src, opts.account, fee) then
                return "funds"
            end
            session.fee = fee
        end

        return DB.SetOut(vehicle)
    end)

    session.approving = false

    if pending[vehicle.key] ~= session then
        return fail(cb, "store_failed")
    end

    if not ok or result ~= true then
        if ok then
            session.restored = true
        end

        if session.fee then
            revertSpawn(vehicle.key, session) -- refunds
        else
            pending[vehicle.key] = nil
        end

        if result == "funds" then
            return fail(cb, "not_enough_money", Utils.Money(fee))
        end
        return fail(cb, "store_failed")
    end

    -- If the client never confirms the spawn, put the vehicle back.
    SetTimeout(SPAWN_CONFIRM_TIMEOUT, function()
        if pending[vehicle.key] == session then
            if revertSpawn(vehicle.key, session) then
                debugLog(("spawn of %s never confirmed — reverted to stored"):format(vehicle.key))
            end
        end
    end)

    cb({
        ok          = true,
        plate       = vehicle.plate,
        key         = vehicle.key,
        props       = vehicle.props,
        model       = vehicle.model,
        spot        = spot,
        spotIndex   = spotIndex,
        oxlyn       = opts.phone == true,
        label       = displayLabel(vehicle),
        garageLabel = garage.label,
        engineOn    = true,
        putIn       = not opts.phone,
    })
end

---------------------------------------------------------------------
-- Opening a garage
---------------------------------------------------------------------

Framework.RegisterCallback("garage:open", function(src, cb, garageId)
    if not (DB.Ready and Garages.Ready) then
        return fail(cb, "not_loaded")
    end

    if not throttle(src, "open", 400) then
        return cb(nil)
    end

    local garage = Garages.Get(garageId)
    if not garage then
        return fail(cb, "garage_not_found")
    end

    if not Garages.CanAccess(src, garage) then
        return fail(cb, "no_access")
    end

    local identifier = Framework.GetIdentifier(src)
    local owned = (garage.personal ~= false and DB.ListOwned(identifier)) or {}
    local now = os.time()

    -- fleet vehicles first, then owned vehicles
    local vehicles = fleetVehicleList(src, garage)

    for _, vehicle in ipairs(owned) do
        if Vehicles.CanUseFromGarage(vehicle, garage) then
            local meta = vehicle.meta or {}
            local contract = Contract.SessionForPlate(vehicle.key)
            local parked = Park.IsParked(vehicle.key) and Park.Get(vehicle.key) or nil

            local impound
            if meta.impound then
                impound = {
                    reason = meta.impound.reason,
                    fee    = meta.impound.fee or (garage.impound and garage.impound.fee) or 0,
                    at     = meta.impound.at,
                    by     = meta.impound.by,
                    lot    = meta.impound.lot and Garages.Label(meta.impound.lot) or nil,
                }
            end

            vehicles[#vehicles + 1] = {
                plate       = vehicle.plate,
                key         = vehicle.key,
                model       = vehicle.model,
                modelName   = vehicle.modelName,
                props       = vehicle.props,
                state       = vehicle.state,
                garage      = vehicle.garage,
                garageLabel = vehicle.garage and Garages.Label(vehicle.garage) or nil,
                lot         = vehicle.lot,
                condition   = Utils.Condition(vehicle.props),
                here        = vehicle.state == "stored",
                parked      = parked and {
                    x = parked.x, y = parked.y, z = parked.z, at = parked.at,
                    towAt = Park.TowAt(vehicle.key),
                } or nil,
                nickname    = meta.nickname,
                storedAt    = meta.storedAt,
                storedBy    = meta.storedBy,
                lastGarage  = meta.lastGarage and Garages.Label(meta.lastGarage) or nil,
                vtype       = meta.vtype,
                label       = meta.label,
                impound     = impound,
                contract    = contract and {
                    id        = contract.id,
                    buyer     = contract.buyerName,
                    price     = contract.price,
                    expiresAt = contract.expiresAt,
                } or nil,
            }
        end
    end

    local recovery = Vehicles.RecoveryPolicy()

    cb({
        ok = true,
        now = now,
        garage = {
            id                 = garage.id,
            label              = garage.label,
            kind               = garage.kind,
            type               = garage.type,
            spots              = garage.spots,
            point              = garage.point,
            impoundFee         = (garage.impound and garage.impound.fee) or 0,
            theme              = garage.theme or {},
            impoundPresentation = (garage.impound and garage.impound.presentation == "cinematic")
                                   and "cinematic" or "document",
            personal           = garage.personal ~= false,
            fleet              = #(garage.fleet or {}) > 0,
            localVehiclesOnly  = garage.localVehiclesOnly == true,
        },
        vehicles = vehicles,
        recovery = {
            mode   = recovery.mode,
            fee    = recovery.fee,
            reason = recovery.reason,
        },
        balances = balances(src),
        fees = {
            retrieve = Config.Garage.retrieveFee or 0,
            transfer = Config.Garage.transferFee or 0,
            global   = Config.Garage.global == true,
        },
    })
end)

---------------------------------------------------------------------
-- Taking vehicles out
---------------------------------------------------------------------

Framework.RegisterCallback("garage:takeout", function(src, cb, garageId, plate, spotIndex, category)
    if not DB.Ready then
        return fail(cb, "not_loaded")
    end

    if not throttle(src, "takeout", 800) then
        return cb(nil)
    end

    local garage = Garages.Get(garageId)
    if not garage then
        return fail(cb, "garage_not_found")
    end

    if not Garages.CanAccess(src, garage) then
        return fail(cb, "no_access")
    end

    if garage.kind ~= "garage" then
        return fail(cb, "vehicle_impound_only")
    end

    if garage.personal == false then
        return fail(cb, "garage_fleet_only")
    end

    local identifier = Framework.GetIdentifier(src)
    local vehicle = DB.GetOwnedByPlate(identifier, Utils.PlateKey(plate))
    if not vehicle then
        return fail(cb, "vehicle_not_owned")
    end

    if vehicle.state == "out" then
        return fail(cb, "vehicle_out")
    end

    if vehicle.state == "impounded" then
        return fail(cb, "vehicle_impounded")
    end

    if Contract.IsLocked(vehicle.key) then
        return fail(cb, "contract_locked")
    end

    if not (Vehicles.CanUseFromGarage(vehicle, garage) and playerNearGarage(src, garage)) then
        return fail(cb, "garage_local_only")
    end

    -- Without "global" garages, a vehicle can only leave the garage it is stored in
    local home = homeGarage(vehicle)
    if not Config.Garage.global and home and home.id ~= garage.id then
        return fail(cb, "not_stored_here", Garages.Label(vehicle.garage))
    end

    if not garageAcceptsVehicle(garage, vehicle, category) then
        return fail(cb, "vehicle_wrong_type")
    end

    spotIndex = math.floor(tonumber(spotIndex) or 1)
    if spotIndex < 1 or spotIndex > #garage.spots then
        spotIndex = 1
    end

    beginSpawn(src, cb, garage, vehicle, spotIndex)
end)

Framework.RegisterCallback("garage:fleetTakeout", function(src, cb, garageId, fleetIndex, spotIndex)
    if not DB.Ready then
        return fail(cb, "not_loaded")
    end

    if not throttle(src, "takeout", 800) then
        return cb(nil)
    end

    local garage = Garages.Get(garageId)
    if not (garage and garage.kind == "garage") then
        return fail(cb, "garage_not_found")
    end

    if not Garages.CanAccess(src, garage) then
        return fail(cb, "no_access")
    end

    fleetIndex = math.floor(tonumber(fleetIndex) or 0)
    local def = garage.fleet and garage.fleet[fleetIndex]
    if not def then
        return fail(cb, "fleet_unknown")
    end

    local grade = fleetGrade(src, garage)
    if grade ~= nil and grade < (def.minGrade or 0) then
        return fail(cb, "fleet_grade", def.minGrade)
    end

    local identifier = Framework.GetIdentifier(src)
    local perPlayer = fleetPerPlayer(garage)

    local toRecall, modelBlocked, playerBlocked =
        fleetAvailability(fleetEntries(garage, src, identifier), fleetIndex, def, perPlayer)

    if modelBlocked then
        return fail(cb, "fleet_in_use")
    end

    if playerBlocked then
        if perPlayer == 1 then
            return fail(cb, "fleet_have_one")
        end
        return fail(cb, "fleet_have_n", perPlayer)
    end

    local plate = newFleetPlate(garage)
    if not plate then
        return fail(cb, "store_failed")
    end
    local key = Utils.PlateKey(plate)

    spotIndex = math.floor(tonumber(spotIndex) or 1)
    if spotIndex < 1 or spotIndex > #garage.spots then
        spotIndex = 1
    end

    -- Recall (delete) any spare vehicles that were blocking this one
    for _, entry in ipairs(toRecall) do
        fleetReturn(entry.key, entry.x)
    end

    fleetPending[key] = {
        src    = src,
        owner  = identifier,
        garage = garage.id,
        index  = fleetIndex,
        plate  = plate,
        model  = GetHashKey(def.model),
        at     = os.time(),
    }

    SetTimeout(SPAWN_CONFIRM_TIMEOUT, function()
        local record = fleetPending[key]
        if record and record.src == src then
            fleetPending[key] = nil
        end
    end)

    cb({
        ok          = true,
        fleet       = true,
        plate       = plate,
        key         = key,
        props       = fleetProps(def, plate),
        spot        = garage.spots[spotIndex],
        spotIndex   = spotIndex,
        label       = def.label,
        garageLabel = garage.label,
        engineOn    = true,
        putIn       = Config.Garage.putInVehicle ~= false,
    })
end)

---------------------------------------------------------------------
-- Spawn confirmation (client -> server)
---------------------------------------------------------------------

--- Wait up to 10s for the networked vehicle with this plate to appear, then call `onResult(entity)`.
local function waitForEntity(netId, key, onResult)
    CreateThread(function()
        local started = GetGameTimer()
        local entity = nil

        while (GetGameTimer() - started) < 10000 do
            entity = vehicleFromNetId(netId)
            if entity and Utils.PlateKey(plateOf(entity)) == key then
                return onResult(entity)
            end
            Wait(150)
        end

        onResult(entity)
    end)
end

local function confirmSpawn(src, key, netId)
    -- Fleet vehicle?
    local fleet = fleetPending[key]
    if fleet and fleet.src == src then
        return waitForEntity(netId, key, function(entity)
            if fleetPending[key] ~= fleet then
                return
            end

            if not (entity
                and Utils.PlateKey(plateOf(entity)) == key
                and Framework.GetIdentifier(src) == fleet.owner
                and GetEntityRoutingBucket(entity) == GetPlayerRoutingBucket(src)
                and toUInt32(GetEntityModel(entity)) == toUInt32(fleet.model)) then
                return
            end

            fleetPending[key] = nil
            fleetOut[key] = {
                src    = src,
                owner  = fleet.owner,
                garage = fleet.garage,
                index  = fleet.index,
                plate  = fleet.plate,
                netId  = netId,
                at     = os.time(),
            }

            pcall(function()
                Entity(entity).state:set("oxlynGarage", { plate = key, fleet = fleet.garage }, true)
            end)

            Keys.GiveServer(src, entity, fleet.plate or plateOf(entity), GetEntityModel(entity))
            TriggerEvent(resourceName .. ":server:fleetOut", src, key, netId, fleet.garage, fleet.index)
        end)
    end

    -- Owned vehicle
    local session = pending[key]
    if not (session
        and session.src == src
        and not (session.approving or session.confirming or session.reverting)) then
        return
    end

    session.confirming = true

    waitForEntity(netId, key, function(entity)
        session.confirming = false

        if not (pending[key] == session
            and not session.approving
            and not session.reverting
            and entity
            and Utils.PlateKey(plateOf(entity)) == key) then
            return
        end

        if Framework.GetIdentifier(src) ~= session.v.owner then
            return
        end

        local expectedModel = session.v.model or (session.v.props and session.v.props.model)
        if not (GetEntityRoutingBucket(entity) == GetPlayerRoutingBucket(src)
            and toUInt32(GetEntityModel(entity)) == toUInt32(expectedModel)) then
            return
        end

        -- Phone valet: the vehicle must have spawned near the requested spot
        if session.phone then
            local maxDistance = (Config.Phone.valet.maxDistance or 250) + 20
            if Utils.Dist(GetEntityCoords(entity), session.coords) > maxDistance then
                return
            end
        end

        if session.impound then
            session.confirming = true
            local clearOk, clearErr = pcall(clearImpoundIfNeeded, session, key)
            session.confirming = false

            if not clearOk then
                log(("^1impound release confirmation failed for %s: %s^7"):format(key, tostring(clearErr)))
                return
            end

            if not (pending[key] == session and not session.reverting) then
                return
            end
        end

        pending[key] = nil
        outVehicles[key] = {
            src        = src,
            identifier = Framework.GetIdentifier(src),
            netId      = netId,
            garage     = session.garage,
            since      = os.time(),
        }

        pcall(function()
            Entity(entity).state:set("oxlynGarage", {
                plate = key,
                owner = outVehicles[key].identifier,
            }, true)
        end)

        Keys.GiveServer(src, entity, plateOf(entity), GetEntityModel(entity))
        TriggerEvent(resourceName .. ":server:vehicleOut", src, key, netId, session.garage)
    end)
end

RegisterNetEvent(resourceName .. ":sv:spawned", function(plate, netId)
    if type(plate) == "string" and type(netId) == "number" and netId > 0 then
        confirmSpawn(source, Utils.PlateKey(plate), netId)
    end
end)

--- Called by other resources/phone UIs once the valet vehicle has spawned.
function Vehicles.ConfirmPhoneVehicle(src, plate, netId)
    src = tonumber(src)
    netId = tonumber(netId)

    local key = Utils.PlateKey(plate)

    local out = outVehicles[key]
    if out and out.src == src and out.netId == netId then
        return true
    end

    local session = pending[key]
    if not (src and netId and netId > 0
        and session
        and session.phone
        and session.src == src
        and not (session.approving or session.reverting)) then
        return false
    end

    confirmSpawn(src, key, netId)
    return true
end

RegisterNetEvent(resourceName .. ":sv:spawnFailed", function(plate)
    local src = source

    local fleet = fleetPending[plate]
    if fleet and fleet.src == src then
        fleetPending[plate] = nil
        return Framework.Notify(src, _U("spawn_failed"), "error")
    end

    local session = pending[plate]
    if not (session and session.src == src) then
        return
    end

    revertSpawn(plate, session)
    Framework.Notify(src, _U("spawn_failed"), "error")
end)

---------------------------------------------------------------------
-- Storing a vehicle
---------------------------------------------------------------------

-- Callback args: garage id, vehicle net id, vehicle props, (unused), optional nickname
Framework.RegisterCallback("garage:store", function(src, cb, garageId, netId, props, _, nickname)
    if not DB.Ready then
        return fail(cb, "not_loaded")
    end

    if not throttle(src, "store", 800) then
        return cb({ ok = false, busy = true })
    end

    local garage = Garages.Get(garageId)
    if not garage then
        return fail(cb, "garage_not_found")
    end

    if not Garages.CanAccess(src, garage) then
        return fail(cb, "no_access")
    end

    if garage.kind ~= "garage" then
        return fail(cb, "vehicle_impound_only")
    end

    local vehicle = vehicleFromNetId(netId)
    if not vehicle then
        return fail(cb, "not_in_vehicle")
    end

    local ped = GetPlayerPed(src)
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        return fail(cb, "not_driver")
    end

    local vehicleCoords = GetEntityCoords(vehicle)
    local point = { x = vehicleCoords.x, y = vehicleCoords.y, z = vehicleCoords.z }

    if not Utils.InParkingArea(garage, point, garage.zone and 4.0 or 6.0) then
        return fail(cb, "too_far")
    end

    local plateText = plateOf(vehicle)
    local key = Utils.PlateKey(plateText)
    if key == "" then
        return fail(cb, "vehicle_not_owned")
    end

    -- Fleet vehicle: just delete it and free the slot
    if fleetOut[key] or fleetPending[key] or detectFleetVehicle(key, vehicle) then
        if #(garage.fleet or {}) == 0 then
            return fail(cb, "fleet_wrong_garage")
        end

        local record = fleetOut[key] or fleetPending[key]
        fleetOut[key] = nil
        fleetPending[key] = nil

        Keys.RemoveServer(src, vehicle, plateText, GetEntityModel(vehicle), true)

        if record and record.src ~= src and Framework.GetIdentifier(record.src) == record.owner then
            Keys.RemoveServer(record.src, vehicle, plateText, GetEntityModel(vehicle), true)
        end

        SetTimeout(6000, function()
            local entity = vehicleFromNetId(netId)
            if entity and Utils.PlateKey(plateOf(entity)) == key then
                safeDelete(entity)
            end
        end)

        TriggerEvent(resourceName .. ":server:fleetReturned", src, key, garage.id)

        return cb({
            ok          = true,
            fleet       = true,
            plate       = plateText,
            key         = key,
            label       = nickname or plateText,
            garageLabel = garage.label,
            spotIndex   = 0,
        })
    end

    -- Owned vehicle
    if garage.personal == false then
        return fail(cb, "garage_fleet_only")
    end

    local owned = DB.GetByPlate(key)
    if not owned then
        return fail(cb, "vehicle_not_owned")
    end

    local identifier = Framework.GetIdentifier(src)
    if owned.owner ~= identifier and not Config.Garage.allowStoreOthers then
        return fail(cb, "vehicle_not_owned")
    end

    if Contract.IsLocked(key) then
        return fail(cb, "contract_locked")
    end

    if ownershipLocks[key] then
        return fail(cb, "vehicle_out")
    end

    local category = Utils.CategoryFromType(GetVehicleType(vehicle))
    if not Utils.GarageAccepts(garage.type, category) and Config.Garage.typeCheck then
        return fail(cb, "vehicle_wrong_type")
    end

    if type(props) ~= "table" then
        props = {}
    end
    sanitisePhysicalProps(props, vehicle, plateText)

    if not DB.SetStored(owned, garage.id, props) then
        return fail(cb, "store_failed")
    end

    Park.Forget(key)

    local meta = {
        vtype          = category,
        stored_at      = os.time(),
        stored_by      = Framework.GetName(src),
        last_garage    = garage.id,
        impound_reason = false,
        impound_fee    = false,
        impound_at     = false,
        impound_by     = false,
        impound_lot    = false,
    }
    if type(nickname) == "string" and nickname ~= "" then
        meta.data = { label = nickname:sub(1, 48) }
    end
    DB.UpsertMeta(key, meta)

    outVehicles[key] = nil
    pending[key] = nil
    lastSeen[key] = nil

    Keys.RemoveServer(src, vehicle, plateText, props.model)

    local ownerPlayer = Framework.GetPlayerByIdentifier(owned.owner)
    if ownerPlayer and ownerPlayer ~= src then
        Keys.RemoveServer(ownerPlayer, vehicle, plateText, props.model)
    end

    SetTimeout(6000, function()
        local entity = vehicleFromNetId(netId)
        if entity and Utils.PlateKey(plateOf(entity)) == key then
            safeDelete(entity)
        end
    end)

    TriggerEvent(resourceName .. ":server:vehicleStored", src, key, garage.id)

    cb({
        ok          = true,
        plate       = plateText,
        key         = key,
        label       = nickname or (owned.meta and owned.meta.nickname) or plateText,
        garageLabel = garage.label,
        spotIndex   = 0,
    })
end)

--- Called after a vehicle changes owner (e.g. sale contract) to move keys/state bags.
function Vehicles.Transferred(key, newIdentifier, newSrc, oldSrc, entity)
    local out = outVehicles[key]
    if out then
        out.identifier = newIdentifier
        out.src = newSrc
    end

    if not (entity and DoesEntityExist(entity) and Utils.PlateKey(plateOf(entity)) == key) then
        entity = nil
    end

    local plate = entity and plateOf(entity) or nil
    local model = entity and GetEntityModel(entity) or nil

    if not plate or not model then
        local row = DB.GetByPlate(key)
        plate = plate or (row and row.plate) or key
        model = model or (row and row.model) or nil
    end

    if oldSrc then
        Keys.RemoveServer(oldSrc, entity or 0, plate, model, true)
    end

    if newSrc then
        Keys.GiveServer(newSrc, entity or 0, plate, model)
    end

    if entity then
        pcall(function()
            Entity(entity).state:set("oxlynGarage", { plate = key, owner = newIdentifier }, true)
        end)
    end

    TriggerEvent(resourceName .. ":server:vehicleTransferred", key, newIdentifier, newSrc)
end

---------------------------------------------------------------------
-- Retrieving a lost vehicle
---------------------------------------------------------------------

Framework.RegisterCallback("garage:retrieve", function(src, cb, garageId, plate, account)
    if not DB.Ready then
        return fail(cb, "not_loaded")
    end

    if not throttle(src, "retrieve", 800) then
        return cb(nil)
    end

    local garage = Garages.Get(garageId)
    if not (garage and garage.kind == "garage") then
        return fail(cb, "garage_not_found")
    end

    if not Garages.CanAccess(src, garage) then
        return fail(cb, "no_access")
    end

    if garage.personal == false then
        return fail(cb, "garage_fleet_only")
    end

    local policy = Vehicles.RecoveryPolicy()
    local key = Utils.PlateKey(plate)

    local vehicle = DB.GetOwnedByPlate(Framework.GetIdentifier(src), key)
    if not vehicle then
        return fail(cb, "vehicle_not_owned")
    end

    if vehicle.state ~= "out" then
        return fail(cb, "vehicle_impounded")
    end

    if pending[key] or ownershipLocks[key] or Contract.IsLocked(key) then
        return fail(cb, "vehicle_out")
    end

    if not (Vehicles.CanUseFromGarage(vehicle, garage) and playerNearGarage(src, garage)) then
        return fail(cb, "garage_local_only")
    end

    if policy.mode == "disabled" then
        return fail(cb, "lost_recovery_disabled")
    end

    -- Recovery by impounding: the vehicle is sent to the impound lot
    if policy.mode == "impound" then
        local snapshot = beginWorldSnapshot()
        if not snapshot then
            lostSince[key] = nil
            return fail(cb, "store_failed")
        end

        local success, messageKey, impounded, lot =
            impoundLostVehicle(key, policy, vehicle.owner, snapshot)
        scans[snapshot] = nil

        if not success then
            return fail(cb, messageKey)
        end

        return cb({
            ok        = true,
            message   = _U("lost_impound_sent", impounded.plate, lot.label),
            balances  = balances(src),
            impounded = true,
            lot       = lot.id,
        })
    end

    -- Recovery by returning it to this garage
    local entity = findLiveEntity(key)
    if entity and Config.Garage.rescueWhenOccupied ~= true and isOccupied(entity) then
        return fail(cb, "rescue_in_use")
    end

    local fee = Config.Garage.retrieveFee or 0
    if not charge(src, account, fee) then
        return fail(cb, "not_enough_money", Utils.Money(fee))
    end

    if entity and Config.Garage.retrieveDeletesWorld ~= false then
        safeDelete(entity)
    end

    Park.Forget(key)
    DB.SetParking(vehicle, garage.id)
    DB.UpsertMeta(key, {
        last_garage = garage.id,
        stored_at   = os.time(),
        stored_by   = Framework.GetName(src),
    })

    outVehicles[key] = nil
    pending[key] = nil
    lastSeen[key] = nil

    cb({
        ok       = true,
        message  = _U("retrieved", displayLabel(vehicle), garage.label),
        balances = balances(src),
    })
end)

---------------------------------------------------------------------
-- Locating a vehicle
---------------------------------------------------------------------

function Vehicles.Locate(src, cb, plate)
    if not DB.Ready then
        return fail(cb, "not_loaded")
    end

    if not throttle(src, "locate", 1200) then
        return cb(nil)
    end

    local key = Utils.PlateKey(plate)
    local vehicle = DB.GetOwnedByPlate(Framework.GetIdentifier(src), key)
    if not vehicle then
        return fail(cb, "vehicle_not_owned")
    end

    local label = displayLabel(vehicle)
    local now = os.time()

    local function reply(coords, extra)
        local response = {
            ok    = true,
            label = label,
            now   = now,
            x     = coords.x,
            y     = coords.y,
            z     = coords.z,
        }
        for k, v in pairs(extra) do
            response[k] = v
        end
        return response
    end

    -- Parked in the world
    if Park.IsParked(key) then
        return cb(reply(Park.Get(key), { kind = "parked", live = true, seenAt = now }))
    end

    -- In an impound lot
    if vehicle.state == "impounded" then
        local lotId = vehicle.lot
        if not lotId and vehicle.meta and vehicle.meta.impound then
            lotId = vehicle.meta.impound.lot
        end

        local lot = lotId and Garages.Get(lotId)
        if not lot then
            return cb({ ok = true, kind = "lost", label = label, now = now })
        end

        return cb(reply(lot.point, { kind = "impound", place = lot.label }))
    end

    -- Stored in a garage
    if vehicle.state == "stored" then
        local garage = vehicle.garage and Garages.Get(vehicle.garage)
        if not garage then
            return fail(cb, "locate_stored")
        end

        return cb(reply(garage.point, { kind = "garage", place = garage.label }))
    end

    -- Out in the world
    local entity = findLiveEntity(key)
    if entity then
        rememberLocation(key, entity)
        return cb(reply(lastSeen[key], {
            kind   = "world",
            live   = true,
            seenAt = now,
            driven = isOccupied(entity),
        }))
    end

    if lastSeen[key] then
        return cb(reply(lastSeen[key], {
            kind   = "world",
            live   = false,
            seenAt = lastSeen[key].at,
        }))
    end

    cb({ ok = true, kind = "lost", label = label, now = now })
end

Framework.RegisterCallback("garage:locate", Vehicles.Locate)

-- Keep last-seen positions of vehicles that are out fresh
CreateThread(function()
    while true do
        Wait(LOCATION_REFRESH_INTERVAL)

        for key, record in pairs(outVehicles) do
            local entity = vehicleFromNetId(record.netId)
            if entity and Utils.PlateKey(plateOf(entity)) == key then
                rememberLocation(key, entity)
            end
        end
    end
end)

---------------------------------------------------------------------
-- Transferring a stored vehicle to another garage
---------------------------------------------------------------------

function Vehicles.TransferToGarage(src, cb, garageId, plate, account)
    if not DB.Ready then
        return fail(cb, "not_loaded")
    end

    if not throttle(src, "transfer", 800) then
        return cb(nil)
    end

    local garage = Garages.Get(garageId)
    if not (garage and garage.kind == "garage") then
        return fail(cb, "garage_not_found")
    end

    if not Garages.CanAccess(src, garage) then
        return fail(cb, "no_access")
    end

    if garage.personal == false then
        return fail(cb, "garage_fleet_only")
    end

    local key = Utils.PlateKey(plate)
    local vehicle = DB.GetOwnedByPlate(Framework.GetIdentifier(src), key)
    if not vehicle then
        return fail(cb, "vehicle_not_owned")
    end

    if not (vehicle.state == "stored" and not pending[key] and not ownershipLocks[key]) then
        return fail(cb, "vehicle_out")
    end

    -- Already here: nothing to do
    if vehicle.garage == garage.id then
        return cb({ ok = true, balances = balances(src) })
    end

    if Contract.IsLocked(vehicle.key) then
        return fail(cb, "contract_locked")
    end

    if not Vehicles.CanUseFromGarage(vehicle, garage) then
        return fail(cb, "garage_local_only")
    end

    if not garageAcceptsVehicle(garage, vehicle, nil) then
        return fail(cb, "vehicle_wrong_type")
    end

    local fee = Config.Garage.transferFee or 0

    local token = Vehicles.ReserveOwnership(key)
    if not token then
        return fail(cb, "vehicle_out")
    end

    account = (account == "cash") and "cash" or "bank"

    local charged = false
    local moved = false

    local ok, result = pcall(function()
        local current = DB.GetOwnedByPlate(vehicle.owner, key)

        if not (current
            and current.state == "stored"
            and current.garage == vehicle.garage
            and current.model == vehicle.model
            and Framework.GetIdentifier(src) == vehicle.owner) then
            return false
        end

        vehicle = current

        if not charge(src, account, fee) then
            return "funds"
        end
        charged = fee > 0

        moved = DB.SetParking(vehicle, garage.id) == true
        if not moved then
            return false
        end

        DB.UpsertMeta(key, { last_garage = garage.id })
        return true
    end)

    -- Charged but the move failed: refund
    if charged and not moved then
        local refundOk, refunded = pcall(function()
            if Framework.GetIdentifier(src) == vehicle.owner then
                return Framework.AddMoney(src, account, fee, "garage-transfer-refund")
            end
            return DB.AddMoneyOffline(vehicle.owner, account, fee)
        end)

        if not refundOk or refunded ~= true then
            log(("^1could not refund failed transfer for %s^7"):format(key))
        end
    end

    Vehicles.ReleaseOwnership(key, token)

    if result == "funds" then
        return fail(cb, "not_enough_money", Utils.Money(fee))
    end

    if not moved then
        return fail(cb, "store_failed")
    end

    if not ok then
        log(("^3transfer of %s completed but metadata could not be saved: %s^7")
            :format(key, tostring(result)))
    end

    cb({
        ok       = true,
        message  = _U("transferred_here", displayLabel(vehicle), garage.label),
        balances = balances(src),
    })
end

Framework.RegisterCallback("garage:transfer", Vehicles.TransferToGarage)

---------------------------------------------------------------------
-- Releasing from the impound
---------------------------------------------------------------------

Framework.RegisterCallback("garage:release", function(src, cb, garageId, plate, spotIndex, account)
    if not DB.Ready then
        return fail(cb, "not_loaded")
    end

    if not throttle(src, "release", 800) then
        return cb(nil)
    end

    local garage = Garages.Get(garageId)
    if not (garage and garage.kind == "impound") then
        return fail(cb, "garage_not_found")
    end

    if not Garages.CanAccess(src, garage) then
        return fail(cb, "no_access")
    end

    local key = Utils.PlateKey(plate)
    local vehicle = DB.GetOwnedByPlate(Framework.GetIdentifier(src), key)
    if not vehicle then
        return fail(cb, "vehicle_not_owned")
    end

    if not (vehicle.state == "impounded" and not pending[key] and not ownershipLocks[key]) then
        return fail(cb, "vehicle_out")
    end

    -- Unless any lot may release it, it must be released from its own lot
    if not Config.Impound.anyLot
        and vehicle.lot
        and vehicle.lot ~= garage.id
        and Garages.Get(vehicle.lot) then
        return fail(cb, "not_stored_here", Garages.Label(vehicle.lot))
    end

    -- Fee: stored impound fee, else the lot's fee, else 0 (QB depot price overrides)
    local fee = (vehicle.meta and vehicle.meta.impound and vehicle.meta.impound.fee)
        or (garage.impound and garage.impound.fee)
        or 0

    if DB.Mode == "qb" and (vehicle.depotPrice or 0) > 0 then
        fee = vehicle.depotPrice
    end

    fee = math.floor(clampNumber(fee, 0, 0, 10000000))

    spotIndex = math.floor(tonumber(spotIndex) or 1)
    if spotIndex < 1 or spotIndex > #garage.spots then
        spotIndex = 1
    end

    beginSpawn(src, cb, garage, vehicle, spotIndex, {
        impound = true,
        fee     = fee,
        account = (account == "cash") and "cash" or "bank",
    })
end)

---------------------------------------------------------------------
-- Renaming
---------------------------------------------------------------------

Framework.RegisterCallback("garage:rename", function(src, cb, plate, name)
    if not DB.Ready then
        return fail(cb, "not_loaded")
    end

    if not throttle(src, "rename", 500) then
        return cb(nil)
    end

    local key = Utils.PlateKey(plate)
    local owned = DB.GetOwnedByPlate(Framework.GetIdentifier(src), key)
    if not owned then
        return fail(cb, "vehicle_not_owned")
    end

    name = Utils.Trim(tostring(name or ""))
    name = name:gsub("[%c<>]", "")
    if #name > 24 then
        name = name:sub(1, 24)
    end

    DB.UpsertMeta(key, { nickname = (name ~= "" and name) or false })

    cb({
        ok       = true,
        nickname = (name ~= "" and name) or nil,
        message  = _U("renamed"),
    })
end)

---------------------------------------------------------------------
-- Impounding (police / admin tool + exports)
---------------------------------------------------------------------

--- May this player impound vehicles? (console, admins, or configured jobs)
local function canImpound(src)
    if src == 0 then
        return true
    end

    if Config.Impound.adminCanImpound ~= false and Framework.IsAdmin(src) then
        return true
    end

    return Framework.HasJob(src, Config.Impound.jobs, Config.Impound.jobOnDuty == true) and true or false
end

--- Impound a vehicle.
--- opts: key | entity, lot, coords, fee, reason, by (source), byName
--- Returns: success, messageKey, vehicle
function Vehicles.Impound(opts)
    opts = opts or {}

    local by = opts.by or 0
    local entity = opts.entity

    local key = opts.key
    if not key then
        if entity then
            key = Utils.PlateKey(plateOf(entity))
        end
    end

    if not key or key == "" then
        return false, "impound_no_vehicle"
    end

    -- Pick the lot: explicit, nearest to coords, or any
    local lot = opts.lot and Garages.Get(opts.lot)
    if not lot and opts.coords then
        lot = Garages.Nearest(opts.coords, "impound")
    end
    if not lot then
        lot = Garages.Any("impound")
    end
    if not (lot and lot.kind == "impound") then
        return false, "impound_no_lot"
    end

    local fee = tonumber(opts.fee)
    if not fee then
        fee = (lot.impound and lot.impound.fee) or Config.Impound.defaultFee or 0
    end
    fee = Utils.Clamp(math.floor(fee), 0, Config.Impound.maxFee or 25000)

    local reason = Utils.Trim(tostring(opts.reason or ""))
    if reason == "" then
        reason = Config.Impound.defaultReason or "Impounded"
    end
    if #reason > 120 then
        reason = reason:sub(1, 120)
    end

    if pending[key] or ownershipLocks[key] then
        return false, "vehicle_out"
    end

    local vehicle = DB.GetByPlate(key)
    if not vehicle then
        -- Not a known owned vehicle: optionally just delete it
        if entity and Config.Impound.deleteUnknownPlates ~= false then
            safeDelete(entity)
            return true, "impound_unknown_deleted"
        end
        return false, "vehicle_not_owned"
    end

    if ownershipLocks[key] or pending[key] then
        return false, "vehicle_out"
    end

    local lock = {}
    ownershipLocks[key] = lock

    local ok, r1, r2, r3 = pcall(function()
        local fresh = DB.GetByPlate(key)

        if not (fresh
            and fresh.owner == vehicle.owner
            and fresh.model == vehicle.model
            and fresh.state == vehicle.state
            and fresh.garage == vehicle.garage
            and fresh.lot == vehicle.lot) then
            return false, "vehicle_not_owned"
        end
        vehicle = fresh

        if not DB.SetImpounded(vehicle, lot.id, fee) then
            return false, "store_failed"
        end

        DB.UpsertMeta(key, {
            impound_reason = reason,
            impound_fee    = fee,
            impound_at     = os.time(),
            impound_by     = opts.byName or (by ~= 0 and Framework.GetName(by)) or "system",
            impound_lot    = lot.id,
        })

        outVehicles[key] = nil
        pending[key] = nil
        lastSeen[key] = nil

        entity = entity or Park.Entity(key) or findEntityByPlate(key)
        Park.Forget(key)

        local owner = Framework.GetPlayerByIdentifier(vehicle.owner)
        if owner then
            Keys.RemoveServer(
                owner,
                entity or 0,
                entity and plateOf(entity) or vehicle.plate,
                entity and GetEntityModel(entity) or vehicle.model,
                true)
        end

        if entity then
            safeDelete(entity)
        end

        if owner then
            Framework.Notify(owner,
                _U("impound_notify_owner", displayLabel(vehicle), vehicle.plate, reason),
                "warning")
        end

        TriggerEvent(resourceName .. ":server:vehicleImpounded", key, lot.id, fee, reason, by)
        return true, "impound_ok", vehicle
    end)

    if ownershipLocks[key] == lock then
        ownershipLocks[key] = nil
    end

    if not ok then
        log(("^1impound of %s failed: %s^7"):format(key, tostring(r1)))
        return false, "store_failed"
    end

    return r1, r2, r3
end

Framework.RegisterCallback("garage:impoundTool", function(src, cb)
    if not DB.Ready then
        return fail(cb, "not_loaded")
    end

    if not canImpound(src) then
        return fail(cb, "no_permission")
    end

    local lots = {}
    for _, garage in ipairs(Garages.All()) do
        if garage.kind == "impound" then
            lots[#lots + 1] = {
                id    = garage.id,
                label = garage.label,
                x     = garage.point.x,
                y     = garage.point.y,
                z     = garage.point.z,
                fee   = (garage.impound and garage.impound.fee) or Config.Impound.defaultFee or 0,
            }
        end
    end

    cb({
        ok      = true,
        lots    = lots,
        fee     = Config.Impound.defaultFee or 0,
        maxFee  = Config.Impound.maxFee or 25000,
        reasons = Config.Impound.reasons or {},
        reason  = Config.Impound.defaultReason or "",
    })
end)

Framework.RegisterCallback("garage:impound", function(src, cb, netId, fee, reason, lotId)
    if not DB.Ready then
        return fail(cb, "not_loaded")
    end

    if not throttle(src, "impound", 1000) then
        return cb(nil)
    end

    if not canImpound(src) then
        return fail(cb, "no_permission")
    end

    local entity = vehicleFromNetId(netId)
    if not entity then
        return fail(cb, "impound_no_vehicle")
    end

    fee = tonumber(fee)
    if fee then
        local maxFee = Config.Impound.maxFee or 25000
        if fee < 0 or fee > maxFee then
            return fail(cb, "impound_fee_invalid", Utils.Money(maxFee))
        end
    end

    if lotId ~= nil then
        local lot = Garages.Get(lotId)
        if not (lot and lot.kind == "impound") then
            return fail(cb, "impound_no_lot")
        end
    end

    local playerCoords = GetEntityCoords(GetPlayerPed(src))

    local success, messageKey, vehicle = Vehicles.Impound({
        entity = entity,
        fee    = fee,
        reason = reason,
        by     = src,
        lot    = lotId,
        coords = { x = playerCoords.x, y = playerCoords.y, z = playerCoords.z },
    })

    if not success then
        return fail(cb, messageKey)
    end

    if messageKey == "impound_unknown_deleted" then
        return cb({ ok = true, message = _U("impound_unknown_deleted") })
    end

    cb({
        ok      = true,
        message = _U("impound_ok", displayLabel(vehicle), vehicle.plate),
    })
end)

---------------------------------------------------------------------
-- Admin: claim the vehicle you are sitting in (/admincar)
---------------------------------------------------------------------

local PLATE_LETTERS = "ABCDEFGHJKLMNPRSTUVWXYZ"

--- Generate an unused random plate ("ABC 123").
function Vehicles.NewPlate()
    for _ = 1, 40 do
        local letters = {}
        for i = 1, 3 do
            local index = math.random(1, #PLATE_LETTERS)
            letters[i] = PLATE_LETTERS:sub(index, index)
        end

        local plate = ("%s %03d"):format(table.concat(letters), math.random(0, 999))
        local key = Utils.PlateKey(plate)

        if not DB.GetByPlate(key)
            and not pending[key]
            and not ownershipLocks[key]
            and not fleetPending[key]
            and not fleetOut[key]
            and not Park.IsParked(key) then
            return plate
        end
    end

    return nil
end

--- Nearest garage the player can use that accepts `category`.
local function nearestGarageFor(src, coords, category)
    local nearest = nil
    local best = math.huge

    for _, garage in pairs(Garages.List) do
        if garage.kind == "garage"
            and Utils.GarageAccepts(garage.type, category)
            and Garages.CanAccess(src, garage) then

            local dist = Utils.Dist(coords, garage.point)
            if best > dist then
                best = dist
                nearest = garage
            end
        end
    end

    return nearest
end

-- Callback args: net id, props, category override, model name, label
Framework.RegisterCallback("admin:claimVehicle", function(src, cb, netId, props, category, modelName, label)
    if not DB.Ready then
        return fail(cb, "not_loaded")
    end

    if not throttle(src, "claim", 1500) then
        return cb(nil)
    end

    if not Framework.IsAdmin(src) then
        return fail(cb, "no_permission")
    end

    local entity = vehicleFromNetId(netId)
    if not (entity and GetVehiclePedIsIn(GetPlayerPed(src), false) == entity) then
        return fail(cb, "admincar_not_in_vehicle")
    end

    local identifier = Framework.GetIdentifier(src)
    if not identifier then
        return fail(cb, "not_loaded")
    end

    local plateText = plateOf(entity)
    local key = Utils.PlateKey(plateText)
    local existing = (key ~= "") and DB.GetByPlate(key) or nil

    if existing and existing.owner == identifier then
        return fail(cb, "admincar_already", plateText)
    end

    -- Keep the plate only if it is non-empty, unused and at most 8 characters;
    -- otherwise give the vehicle a fresh plate.
    local replated = false
    if not (key ~= "" and not existing and #plateText <= 8) then
        plateText = Vehicles.NewPlate()
        if not plateText then
            return fail(cb, "store_failed")
        end

        pcall(SetVehicleNumberPlateText, entity, plateText)
        key = Utils.PlateKey(plateText)
        replated = true
    end

    if type(props) ~= "table" then
        props = {}
    end
    sanitisePhysicalProps(props, entity, plateText)

    category = category or Utils.CategoryFromType(GetVehicleType(entity)) or "car"

    local coords = GetEntityCoords(entity)
    local garage = nearestGarageFor(src, { x = coords.x, y = coords.y, z = coords.z }, category)

    local token = Vehicles.ReserveOwnership(key)
    if not token then
        return fail(cb, "vehicle_out")
    end

    local ok, result = pcall(function()
        local function errorResult(errorKey)
            return { ok = false, error = errorKey, message = _U(errorKey) }
        end

        if DB.GetByPlate(key) then
            return errorResult("admin_garage_plate_taken")
        end

        if not (Framework.IsAdmin(src) and Framework.GetIdentifier(src) == identifier) then
            return errorResult("no_permission")
        end

        -- Re-validate: still sitting in the same vehicle with the same plate
        if not (vehicleFromNetId(netId) == entity
            and Utils.PlateKey(plateOf(entity)) == key
            and GetVehiclePedIsIn(GetPlayerPed(src), false) == entity) then
            return errorResult("admincar_not_in_vehicle")
        end

        local added = DB.AddOwned({
            identifier = identifier,
            license    = Framework.GetLicense(src),
            plate      = plateText,
            props      = props,
            category   = category,
            modelName  = (type(modelName) == "string" and modelName:sub(1, 48)) or nil,
            garage     = garage and garage.id or nil,
        })
        if not added then
            return errorResult("store_failed")
        end

        local meta = {
            vtype       = category,
            stored_by   = Framework.GetName(src),
            last_garage = garage and garage.id or false,
        }
        if type(label) == "string" and label ~= "" then
            meta.data = { label = label:sub(1, 48) }
        end
        DB.UpsertMeta(key, meta)

        Vehicles.MarkOut(key, src, netId, garage and garage.id or nil)
        Keys.GiveServer(src, entity, plateText, props.model)

        local displayName = (type(label) == "string" and label ~= "" and label) or plateText

        log(("%s (%s) registered %s [%s] as their vehicle with /admincar")
            :format(Framework.GetName(src), identifier, plateText, displayName))

        TriggerEvent(resourceName .. ":server:adminVehicleAdded", src, key, identifier)

        return {
            ok       = true,
            plate    = plateText,
            replated = replated,
            garage   = garage and garage.id or nil,
            message  = _U(
                replated and "admincar_ok_replated" or "admincar_ok",
                displayName,
                plateText,
                (garage and garage.label) or "—"),
        }
    end)

    Vehicles.ReleaseOwnership(key, token)

    if not ok then
        log(("^1admincar registration failed for %s: %s^7"):format(key, tostring(result)))
        return fail(cb, "store_failed")
    end

    cb(result)
end)

---------------------------------------------------------------------
-- Boot, simple accessors and ownership locks
---------------------------------------------------------------------

function Vehicles.Boot()
    lostSince = {}

    if Vehicles.RecoveryPolicy().mode == "garage" and Config.Garage.restoreOnRestart ~= false then
        -- Vehicles left "out" across a restart go back to their garage (parked ones excepted)
        local restored = DB.RestoreAllOut(Park.Keys())
        if (restored or 0) > 0 then
            log(("%d vehicle(s) that were out have been put back in their garage"):format(restored))
        end
    end
end

function Vehicles.IsOut(key)
    return outVehicles[key] ~= nil
end

function Vehicles.IsPending(key)
    return pending[key] ~= nil
end

function Vehicles.OutList()
    return outVehicles
end

--- Mark a vehicle as out in the world (and tag the entity's state bag).
function Vehicles.MarkOut(key, src, netId, garage)
    lostSince[key] = nil
    pending[key] = nil

    outVehicles[key] = {
        src        = src,
        identifier = Framework.GetIdentifier(src),
        netId      = netId,
        garage     = garage,
        since      = os.time(),
    }

    local entity = vehicleFromNetId(netId)
    if entity then
        pcall(function()
            Entity(entity).state:set("oxlynGarage", {
                plate = key,
                owner = outVehicles[key].identifier,
            }, true)
        end)
    end
end

function Vehicles.ClearOut(key)
    lostSince[key] = nil
    outVehicles[key] = nil
    pending[key] = nil
end

--- Try to take an exclusive ownership lock on a plate. Returns a token or nil.
function Vehicles.ReserveOwnership(key)
    if not (type(key) == "string" and key ~= ""
        and not pending[key]
        and not ownershipLocks[key]
        and not fleetPending[key]
        and not fleetOut[key]
        and not Contract.IsLocked(key)
        and not Park.IsParked(key)) then
        return nil
    end

    local token = {}
    ownershipLocks[key] = token
    return token
end

function Vehicles.ReleaseOwnership(key, token)
    if ownershipLocks[key] == token then
        ownershipLocks[key] = nil
    end
end

--- Is the vehicle really idle (we hold the lock, nothing else touches it, and it is
--- not in the world)?
function Vehicles.OwnershipIsIdle(key, token)
    if not (token
        and ownershipLocks[key] == token
        and not pending[key]
        and not fleetPending[key]
        and not fleetOut[key]
        and not Contract.IsLocked(key)
        and not Park.IsParked(key)) then
        return false
    end

    local snapshot = beginWorldSnapshot()
    if not snapshot then
        return false
    end

    local present = snapshotHasPlate(snapshot, key)
    scans[snapshot] = nil

    return not present
end

--- Called after an owned vehicle record was removed (admin delete): clean runtime state.
function Vehicles.OwnershipRemoved(record, token)
    if ownershipLocks[record.key] ~= token then
        return false
    end

    outVehicles[record.key] = nil
    pending[record.key] = nil
    lastSeen[record.key] = nil
    lostSince[record.key] = nil

    local owner = Framework.GetPlayerByIdentifier(record.owner)
    if owner and Framework.GetIdentifier(owner) == record.owner then
        local ok, err = pcall(Keys.RemoveServer, owner, 0, record.plate, record.model, true)
        if not ok then
            log(("^3admin key cleanup for %s failed: %s^7"):format(record.key, tostring(err)))
        end
    end

    return true
end

---------------------------------------------------------------------
-- Exports
---------------------------------------------------------------------

exports("ImpoundVehicle", function(plate, opts)
    if type(opts) ~= "table" then
        opts = {}
    end
    opts.key = Utils.PlateKey(plate)
    return Vehicles.Impound(opts)
end)

exports("GetVehicle", function(plate)
    return (DB.Ready and DB.GetByPlate(Utils.PlateKey(plate))) or nil
end)

exports("GetOwnedVehicles", function(identifier)
    return (DB.Ready and DB.ListOwned(identifier)) or {}
end)

--- Move a stored/idle vehicle to a garage (or clear its garage). Returns true on success.
exports("SetVehicleGarage", function(plate, garageId)
    if not DB.Ready then
        return false
    end

    local vehicle = DB.GetByPlate(Utils.PlateKey(plate))

    if not (vehicle
        and not pending[vehicle.key]
        and not ownershipLocks[vehicle.key]
        and not Contract.IsLocked(vehicle.key)
        and not Park.IsParked(vehicle.key)
        and not findLiveEntity(vehicle.key)) then
        return false
    end

    if garageId and not Garages.Get(garageId) then
        return false
    end

    local token = Vehicles.ReserveOwnership(vehicle.key)
    if not token then
        return false
    end

    local ok, result = pcall(function()
        local fresh = DB.GetByPlate(vehicle.key)

        if not (fresh
            and fresh.owner == vehicle.owner
            and fresh.state == vehicle.state
            and fresh.garage == vehicle.garage
            and fresh.model == vehicle.model) then
            return false
        end
        vehicle = fresh

        if not DB.SetParking(vehicle, garageId) then
            return false
        end

        DB.UpsertMeta(vehicle.key, {
            last_garage    = garageId or false,
            impound_reason = false,
            impound_fee    = false,
            impound_at     = false,
            impound_by     = false,
            impound_lot    = false,
        })
        return true
    end)

    Vehicles.ReleaseOwnership(vehicle.key, token)

    if not ok then
        log(("^1setting garage for %s failed: %s^7"):format(vehicle.key, tostring(result)))
    end

    return ok and result == true
end)

exports("IsVehicleOut", function(plate)
    return outVehicles[Utils.PlateKey(plate)] ~= nil
end)

---------------------------------------------------------------------
-- Phone valet
---------------------------------------------------------------------

--- Vehicle category as the phone UI sees it ("car", "motorcycle", "air", ...).
function Vehicles.PhoneCategory(vehicle)
    local category = metaVtype(vehicle) or vehicle.vehicleType
    if category then
        return category
    end

    local garage = vehicle.garage and Garages.Get(vehicle.garage)
    if garage and garage.type ~= "all" and garage.type then
        return garage.type
    end

    return nil
end

--- Request a valet delivery from the phone.
--- spotCoords may be nil with options.externalSpawn = true (the calling resource
--- spawns the vehicle itself at the player's position).
--- options.charge (default true): charge the configured valet fee.
function Vehicles.PreparePhoneVehicle(src, plate, spotCoords, heading, options)
    local function result(errorKey)
        return { ok = false, error = errorKey, message = _U(errorKey) }
    end

    local phoneCfg = Config.Phone or {}
    options = options or {}

    src = tonumber(src)
    if not (src and src > 0 and GetPlayerName(src)) then
        return result("no_access")
    end

    if not (phoneCfg.enabled ~= false and phoneCfg.valet and phoneCfg.valet.enabled ~= false) then
        return result("no_access")
    end

    if not (DB.Ready and Garages.Ready) then
        return result("not_loaded")
    end

    if not throttle(src, "phoneValet", 3000) then
        return result("vehicle_out")
    end

    local key = Utils.PlateKey(plate)
    local vehicle = DB.GetOwnedByPlate(Framework.GetIdentifier(src), key)
    if not vehicle then
        return result("vehicle_not_owned")
    end

    if vehicle.state == "impounded" then
        return result("vehicle_impounded")
    end

    if not (vehicle.state == "stored"
        and not pending[key]
        and not ownershipLocks[key]
        and not Park.IsParked(key)) then
        return result("vehicle_out")
    end

    if Contract.IsLocked(key) then
        return result("contract_locked")
    end

    local category = Vehicles.PhoneCategory(vehicle)
    if category ~= "car" and category ~= "motorcycle" then
        return result("vehicle_wrong_type")
    end

    local garage = vehicle.garage and Garages.Get(vehicle.garage)
    if not (garage and garage.kind == "garage") then
        return result("garage_not_found")
    end

    if not (garage.personal ~= false and Garages.CanAccess(src, garage)) then
        return result("no_access")
    end

    -- Vehicles stored in a "local" garage cannot be valeted
    if Vehicles.IsLocalVehicle(vehicle) then
        return result("garage_local_only")
    end

    local ped = GetPlayerPed(src)
    if not (ped ~= 0 and DoesEntityExist(ped)) then
        return result("no_access")
    end

    local playerCoords = GetEntityCoords(ped)

    local external = options.externalSpawn == true and spotCoords == nil
    local spot = (type(spotCoords) == "table" and Utils.Coords(spotCoords)) or nil

    if external then
        spot = { x = playerCoords.x, y = playerCoords.y, z = playerCoords.z, w = 0.0 }
    end

    if not spot then
        return result("spot_occupied")
    end

    spot.w = tonumber(heading) or spot.w

    -- Reject NaN / absurd coordinates
    for _, value in ipairs({ spot.x, spot.y, spot.z, spot.w }) do
        if not (value == value and math.abs(value) <= 100000) then
            return result("spot_occupied")
        end
    end

    local maxDistance = tonumber(phoneCfg.valet.maxDistance) or 250.0
    if Utils.Dist(playerCoords, spot) > maxDistance then
        return result("spot_occupied")
    end

    -- Make sure the vehicle isn't already in the world and the spot is free
    local bucket = GetPlayerRoutingBucket(src)
    local ok, all = pcall(GetAllVehicles)
    if not (ok and type(all) == "table") then
        return result("spot_occupied")
    end

    for _, existing in ipairs(all) do
        if DoesEntityExist(existing) then
            if Utils.PlateKey(plateOf(existing)) == key then
                return result("vehicle_out")
            end

            if not external
                and GetEntityRoutingBucket(existing) == bucket
                and Utils.Dist(GetEntityCoords(existing), spot) < 3.0 then
                return result("spot_occupied")
            end
        end
    end

    local response
    beginSpawn(src, function(r)
        response = r
    end, garage, vehicle, 1, {
        phone   = true,
        spot    = spot,
        account = (phoneCfg.valet.account == "cash") and "cash" or "bank",
        fee     = (options.charge ~= false)
                    and math.floor(Utils.Clamp(phoneCfg.valet.fee or 0, 0, 10000000))
                    or 0,
    })

    return response
end

--- Cancel a pending phone valet request. Returns true if it was reverted.
function Vehicles.CancelPhoneVehicle(src, plate)
    local key = Utils.PlateKey(plate)
    local session = pending[key]

    return (session
        and session.phone
        and session.src == tonumber(src)
        and revertSpawn(key, session)) or false
end

