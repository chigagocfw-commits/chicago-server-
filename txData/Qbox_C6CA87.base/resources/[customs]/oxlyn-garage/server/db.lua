

-- Cleaned from decompiler output (register-style L0_1/L1_2 names -> readable names).
-- Logic is preserved; a few spots where the decompiler produced tangled
-- goto/if chains were reconstructed by intent.

DB = DB or {}
DB.Ready = false
DB.Mode = nil              -- "esx" | "qb" | nil
DB.EsxAccountsJson = true  -- true if users.accounts is a JSON column

local resourceName = GetCurrentResourceName()

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

local function log(msg)
    print(("[%s] %s"):format(resourceName, msg))
end

local function debugLog(msg)
    if Config.Debug then
        log(msg)
    end
end

--- Decode JSON safely; always returns a table.
local function decode(value)
    if type(value) == "table" then return value end
    if type(value) ~= "string" or value == "" then return {} end

    local ok, result = pcall(json.decode, value)
    if ok and type(result) == "table" then
        return result
    end
    return {}
end

local function tableExists(name)
    local count = MySQL.scalar.await(
        "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?",
        { name }
    )
    return (tonumber(count) or 0) > 0
end

local function columnExists(tableName, column)
    local count = MySQL.scalar.await(
        "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?",
        { tableName, column }
    )
    return (tonumber(count) or 0) > 0
end

---------------------------------------------------------------------
-- Schema / indexes
---------------------------------------------------------------------

local contractIndexes = {
    { "plate_status_created", "`plate`, `status`, `created_at`" },
    { "status_expires",       "`status`, `expires_at`" },
    { "seller_refund",        "`seller`, `refund_pending`" },
}

local function ensureContractIndexes()
    local rows = MySQL.query.await([[
        SELECT DISTINCT INDEX_NAME AS name
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'oxlyn_garage_contracts']])

    local existing = {}
    for _, row in ipairs(rows or {}) do
        local idxName = row.name or row.NAME or row.INDEX_NAME or row.index_name
        if idxName then
            existing[idxName] = true
        end
    end

    local alters = {}
    for _, idx in ipairs(contractIndexes) do
        if not existing[idx[1]] then
            alters[#alters + 1] = ("ADD INDEX `%s` (%s)"):format(idx[1], idx[2])
        end
    end

    if #alters > 0 then
        MySQL.query.await("ALTER TABLE `oxlyn_garage_contracts` " .. table.concat(alters, ", "))
    end
end

function DB.Init()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `oxlyn_garages` (
            `id`         VARCHAR(48) NOT NULL,
            `data`       LONGTEXT    NOT NULL,
            `updated_at` INT         NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `oxlyn_garage_vehicles` (
            `plate`          VARCHAR(16)  NOT NULL,
            `nickname`       VARCHAR(32)  NULL,
            `vtype`          VARCHAR(16)  NULL,
            `stored_at`      INT          NULL,
            `stored_by`      VARCHAR(64)  NULL,
            `last_garage`    VARCHAR(48)  NULL,
            `impound_reason` VARCHAR(128) NULL,
            `impound_fee`    INT          NULL,
            `impound_at`     INT          NULL,
            `impound_by`     VARCHAR(64)  NULL,
            `impound_lot`    VARCHAR(48)  NULL,
            `contract_id`    VARCHAR(40)  NULL,
            `data`           LONGTEXT     NULL,
            PRIMARY KEY (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `oxlyn_garage_settings` (
            `id`         VARCHAR(32) NOT NULL,
            `data`       LONGTEXT    NOT NULL,
            `updated_at` INT         NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `oxlyn_garage_parked` (
            `plate`      VARCHAR(16)  NOT NULL,
            `plate_raw`  VARCHAR(16)  NOT NULL,
            `owner`      VARCHAR(64)  NOT NULL,
            `model`      BIGINT       NOT NULL DEFAULT 0,
            `vtype`      VARCHAR(24)  NOT NULL DEFAULT 'automobile',
            `x`          FLOAT        NOT NULL DEFAULT 0,
            `y`          FLOAT        NOT NULL DEFAULT 0,
            `z`          FLOAT        NOT NULL DEFAULT 0,
            `w`          FLOAT        NOT NULL DEFAULT 0,
            `props`      LONGTEXT     NULL,
            `parked_at`  INT          NOT NULL DEFAULT 0,
            PRIMARY KEY (`plate`),
            KEY `owner` (`owner`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `oxlyn_garage_contracts` (
            `id`             VARCHAR(40) NOT NULL,
            `plate`          VARCHAR(16) NOT NULL,
            `seller`         VARCHAR(64) NOT NULL,
            `seller_name`    VARCHAR(64) NULL,
            `buyer`          VARCHAR(64) NOT NULL,
            `buyer_name`     VARCHAR(64) NULL,
            `price`          INT         NOT NULL DEFAULT 0,
            `model`          VARCHAR(64) NULL,
            `label`          VARCHAR(64) NULL,
            `status`         VARCHAR(16) NOT NULL DEFAULT 'pending',
            `created_at`     INT         NULL,
            `expires_at`     INT         NULL,
            `resolved_at`    INT         NULL,
            `refund_pending` TINYINT     NOT NULL DEFAULT 0,
            `data`           LONGTEXT    NULL,
            PRIMARY KEY (`id`),
            KEY `seller` (`seller`),
            KEY `buyer` (`buyer`),
            KEY `status` (`status`),
            KEY `plate_status_created` (`plate`, `status`, `created_at`),
            KEY `status_expires` (`status`, `expires_at`),
            KEY `seller_refund` (`seller`, `refund_pending`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    local ok, err = pcall(ensureContractIndexes)
    if not ok then
        log(("^3contract indexes could not be updated: %s^7"):format(tostring(err)))
    end

    -- Determine which vehicle schema we are running on
    if Framework.Name == "esx" then
        DB.Mode = "esx"
    elseif Framework.Name == "qbcore" or Framework.Name == "qbox" then
        DB.Mode = "qb"
    elseif tableExists("player_vehicles") then
        DB.Mode = "qb"
    elseif tableExists("owned_vehicles") then
        DB.Mode = "esx"
    end

    if DB.Mode == "esx" then
        if not tableExists("owned_vehicles") then
            log("^1owned_vehicles table not found - vehicle ownership is unavailable.^7")
        else
            if not columnExists("owned_vehicles", "parking") then
                MySQL.query.await("ALTER TABLE `owned_vehicles` ADD `parking` VARCHAR(60) NULL")
                log("added owned_vehicles.parking")
            end
            if not columnExists("owned_vehicles", "pound") then
                MySQL.query.await("ALTER TABLE `owned_vehicles` ADD `pound` VARCHAR(60) NULL")
                log("added owned_vehicles.pound")
            end
        end
        DB.EsxAccountsJson = columnExists("users", "accounts")
    elseif DB.Mode == "qb" then
        if not tableExists("player_vehicles") then
            log("^1player_vehicles table not found - vehicle ownership is unavailable.^7")
        end
    else
        log("^3no vehicle table detected (owned_vehicles / player_vehicles) - running without ownership.^7")
    end

    DB.Ready = true
    debugLog(("DB ready (mode %s)"):format(tostring(DB.Mode)))
end

---------------------------------------------------------------------
-- Vehicle row normalisation
---------------------------------------------------------------------

local ESX_COLUMNS = "`owner`, `plate`, `vehicle`, `type`, `job`, `stored`, `parking`, `pound`"
local QB_COLUMNS  = "`id`, `license`, `citizenid`, `vehicle`, `hash`, `mods`, `plate`, `fakeplate`, `garage`, `fuel`, `engine`, `body`, `state`, `depotprice`, `drivingdistance`"

-- Small ring-buffer cache: normalised plate key -> raw plate as stored in DB
local PLATE_CACHE_SIZE = 2048
local plateCache = {}
local plateRing = {}
local plateRingPos = 1

local function cachePlate(plate)
    local key = Utils.PlateKey(plate)
    if key == "" then return key end

    if plateCache[key] == nil then
        local evicted = plateRing[plateRingPos]
        if evicted then
            plateCache[evicted] = nil
        end
        plateRing[plateRingPos] = key
        plateRingPos = (plateRingPos % PLATE_CACHE_SIZE) + 1
    end

    plateCache[key] = plate
    return key
end

--- Convert a raw ESX/QB vehicle row into the common internal shape.
local function normalizeVehicle(row)
    if not row then return nil end

    local key = cachePlate(row.plate)

    if DB.Mode == "esx" then
        local props = decode(row.vehicle)

        local state = "out"
        if row.pound and row.pound ~= "" then
            state = "impounded"
        elseif tonumber(row.stored) == 1 then
            state = "stored"
        end

        local vehicleType
        if row.type == "boat" then
            vehicleType = "boat"
        elseif row.type == "aircraft" then
            vehicleType = "air"
        elseif row.type == "car" then
            vehicleType = "car"
        end

        return {
            plate       = row.plate,
            key         = key,
            owner       = row.owner,
            job         = row.job,
            props       = props,
            model       = props.model,
            state       = state,
            vehicleType = vehicleType,
            garage      = (row.parking and row.parking ~= "") and row.parking or nil,
            lot         = (state == "impounded") and row.pound or nil,
            meta        = {},
        }
    end

    -- QB / Qbox
    local props = decode(row.mods)
    local stateNum = tonumber(row.state) or 0
    local state = (stateNum == 2 and "impounded") or (stateNum == 1 and "stored") or "out"

    if props.fuelLevel == nil and row.fuel then
        props.fuelLevel = tonumber(row.fuel)
    end
    if props.engineHealth == nil and row.engine then
        props.engineHealth = tonumber(row.engine)
    end
    if props.bodyHealth == nil and row.body then
        props.bodyHealth = tonumber(row.body)
    end
    if props.model == nil and row.hash then
        props.model = tonumber(row.hash)
    end

    return {
        plate          = row.plate,
        key            = key,
        owner          = row.citizenid,
        license        = row.license,
        props          = props,
        model          = props.model,
        modelName      = row.vehicle,
        state          = state,
        garage         = (row.garage and row.garage ~= "") and row.garage or nil,
        lot            = (state == "impounded") and row.garage or nil,
        depotPrice     = tonumber(row.depotprice) or 0,
        drivingDistance = tonumber(row.drivingdistance) or 0,
        meta           = {},
    }
end

--- Attach oxlyn_garage_vehicles metadata to a list of normalised vehicles.
local function attachMeta(list)
    if #list == 0 then return list end

    local keys = {}
    for _, vehicle in ipairs(list) do
        keys[#keys + 1] = vehicle.key
    end

    local metaByKey = DB.ListMeta(keys)
    for _, vehicle in ipairs(list) do
        vehicle.meta = metaByKey[vehicle.key] or {}
    end
    return list
end

---------------------------------------------------------------------
-- Owned vehicles (ESX owned_vehicles / QB player_vehicles)
---------------------------------------------------------------------

function DB.ListOwned(owner)
    if not DB.Mode or not owner then return {} end

    local rows
    if DB.Mode == "esx" then
        rows = MySQL.query.await(
            ("SELECT %s FROM `owned_vehicles` WHERE `owner` = ?"):format(ESX_COLUMNS), { owner })
    else
        rows = MySQL.query.await(
            ("SELECT %s FROM `player_vehicles` WHERE `citizenid` = ?"):format(QB_COLUMNS), { owner })
    end

    local list = {}
    for _, row in ipairs(rows or {}) do
        local vehicle = normalizeVehicle(row)
        if vehicle and vehicle.key ~= "" then
            list[#list + 1] = vehicle
        end
    end

    return attachMeta(list)
end

function DB.CountOwned(owner)
    if not DB.Mode or not owner then return 0 end

    local count
    if DB.Mode == "esx" then
        count = MySQL.scalar.await("SELECT COUNT(*) FROM `owned_vehicles` WHERE `owner` = ?", { owner })
    else
        count = MySQL.scalar.await("SELECT COUNT(*) FROM `player_vehicles` WHERE `citizenid` = ?", { owner })
    end
    return tonumber(count) or 0
end

--- Plate keys of every vehicle currently marked as "out" (spawned in the world).
function DB.ListOutKeys()
    if not DB.Mode then return {} end

    local query = (DB.Mode == "esx")
        and "SELECT `plate` FROM `owned_vehicles` WHERE `stored` = 0 AND (`pound` IS NULL OR `pound` = '')"
        or  "SELECT `plate` FROM `player_vehicles` WHERE `state` = 0"

    local rows = MySQL.query.await(query)
    if type(rows) ~= "table" then
        error("lost-vehicle query did not return rows")
    end

    local keys, seen = {}, {}
    for _, row in ipairs(rows) do
        local key = cachePlate(row.plate)
        if key ~= "" and not seen[key] then
            seen[key] = true
            keys[#keys + 1] = key
        end
    end
    return keys
end

function DB.GetByPlate(key)
    if not (DB.Mode and key) or key == "" then return nil end

    local isEsx   = DB.Mode == "esx"
    local tbl     = isEsx and "owned_vehicles" or "player_vehicles"
    local columns = isEsx and ESX_COLUMNS or QB_COLUMNS

    -- Fast path: exact plate from cache
    local row = MySQL.single.await(
        ("SELECT %s FROM `%s` WHERE `plate` = ? LIMIT 1"):format(columns, tbl),
        { plateCache[key] or key }
    )

    -- Slow path: compare on normalised plate
    if not (row and Utils.PlateKey(row.plate) == key) then
        row = MySQL.single.await(
            ("SELECT %s FROM `%s` WHERE REPLACE(UPPER(`plate`), ' ', '') = ? LIMIT 1"):format(columns, tbl),
            { key }
        )
    end

    local vehicle = normalizeVehicle(row)
    if not vehicle then return nil end

    vehicle.meta = DB.GetMeta(vehicle.key) or {}
    return vehicle
end

function DB.GetOwnedByPlate(owner, key)
    if not (DB.Mode and owner and key) or key == "" then return nil end

    local isEsx    = DB.Mode == "esx"
    local tbl      = isEsx and "owned_vehicles" or "player_vehicles"
    local ownerCol = isEsx and "owner" or "citizenid"
    local columns  = isEsx and ESX_COLUMNS or QB_COLUMNS

    local row = MySQL.single.await(
        ("SELECT %s FROM `%s` WHERE `%s` = ? AND REPLACE(UPPER(`plate`), ' ', '') = ? LIMIT 1")
            :format(columns, tbl, ownerCol),
        { owner, key }
    )

    local vehicle = normalizeVehicle(row)
    if not vehicle then return nil end

    vehicle.meta = DB.GetMeta(vehicle.key) or {}
    return vehicle
end

--- Mark a vehicle as stored in `garage`, saving its props.
function DB.SetStored(vehicle, garage, props)
    if not DB.Mode then return false end

    local source = props or vehicle.props or {}
    local propsJson = json.encode(source)

    if DB.Mode == "esx" then
        local affected = MySQL.update.await(
            "UPDATE `owned_vehicles` SET `vehicle` = ?, `stored` = 1, `parking` = ?, `pound` = NULL WHERE `plate` = ?",
            { propsJson, garage, vehicle.plate }
        )
        return (affected or 0) > 0
    end

    local condition = Utils.Condition(source)
    local affected = MySQL.update.await(
        "UPDATE `player_vehicles` SET `mods` = ?, `state` = 1, `garage` = ?, `fuel` = ?, `engine` = ?, `body` = ?, `depotprice` = 0 WHERE `plate` = ?",
        {
            propsJson,
            garage,
            condition.fuel,
            source.engineHealth or 1000,
            source.bodyHealth or 1000,
            vehicle.plate,
        }
    )
    return (affected or 0) > 0
end

--- Insert a new owned vehicle (state: out).
function DB.AddOwned(data)
    if not (DB.Mode and data and data.identifier and data.plate) then
        return false
    end

    local props = data.props or {}
    local propsJson = json.encode(props)

    if DB.Mode == "esx" then
        local vtype = (data.category == "boat" and "boat")
            or (data.category == "air" and "aircraft")
            or "car"

        local affected = MySQL.update.await(
            "INSERT INTO `owned_vehicles` (`owner`, `plate`, `vehicle`, `type`, `stored`, `parking`) VALUES (?, ?, ?, ?, 0, ?)",
            { data.identifier, data.plate, propsJson, vtype, data.garage }
        )
        return (affected or 0) > 0
    end

    local condition = Utils.Condition(props)
    local affected = MySQL.update.await(
        "INSERT INTO `player_vehicles` (`license`, `citizenid`, `vehicle`, `hash`, `mods`, `plate`, `garage`, `fuel`, `engine`, `body`, `state`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)",
        {
            data.license or "",
            data.identifier,
            data.modelName or "",
            tonumber(props.model) or 0,
            propsJson,
            data.plate,
            data.garage,
            condition.fuel,
            props.engineHealth or 1000,
            props.bodyHealth or 1000,
        }
    )
    return (affected or 0) > 0
end

--- Admin insert: refuses if the plate already exists, is parked in the world,
--- or has an open (pending/signed) sale contract. Vehicle is inserted as stored.
function DB.AdminAddOwned(data)
    if not (DB.Mode and data and data.identifier and data.plate and data.garage) then
        return false
    end

    local key = Utils.PlateKey(data.plate)
    local props = data.props or {}
    local propsJson = json.encode(props)
    local tbl = (DB.Mode == "esx") and "owned_vehicles" or "player_vehicles"

    local guard = ([[
 FROM (SELECT 1 AS seed) AS seed LEFT JOIN `%s` existing
        ON REPLACE(UPPER(existing.`plate`), ' ', '') = ? WHERE existing.`plate` IS NULL
        AND NOT EXISTS (SELECT 1 FROM `oxlyn_garage_parked` WHERE `plate` = ?)
        AND NOT EXISTS (SELECT 1 FROM `oxlyn_garage_contracts` WHERE `plate` = ? AND `status` IN ('pending', 'signed'))]]):format(tbl)

    local query, params

    if DB.Mode == "esx" then
        local vtype = (data.category == "boat" and "boat")
            or (data.category == "air" and "aircraft")
            or "car"

        query = "INSERT INTO `owned_vehicles` (`owner`, `plate`, `vehicle`, `type`, `stored`, `parking`) SELECT ?, ?, ?, ?, 1, ?" .. guard
        params = { data.identifier, data.plate, propsJson, vtype, data.garage, key, key, key }
    else
        query = "INSERT INTO `player_vehicles` (`license`, `citizenid`, `vehicle`, `hash`, `mods`, `plate`, `garage`, `fuel`, `engine`, `body`, `state`) SELECT ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1" .. guard
        params = {
            data.license or "",
            data.identifier,
            data.modelName or "",
            props.model,
            propsJson,
            data.plate,
            data.garage,
            props.fuelLevel or 100,
            props.engineHealth or 1000,
            props.bodyHealth or 1000,
            key, key, key,
        }
    end

    local affected = MySQL.update.await(query, params)
    return (affected or 0) > 0
end

--- Admin delete: only deletes a vehicle that is still in the exact state the
--- admin UI saw, is the sole match for the plate, is not parked in the world
--- and has no open contract. Also removes its metadata row.
function DB.AdminDeleteOwned(data)
    if not (DB.Mode and data and data.owner and data.key
        and (data.state == "stored" or data.state == "impounded")) then
        return false
    end

    local isEsx    = DB.Mode == "esx"
    local tbl      = isEsx and "owned_vehicles" or "player_vehicles"
    local ownerCol = isEsx and "owner" or "citizenid"

    local stateClause, params
    if isEsx then
        stateClause = "v.`stored` = 1 AND COALESCE(v.`parking`, '') = ? AND COALESCE(v.`pound`, '') = ?"
        params = {
            data.key, data.key, data.owner, data.plate,
            data.garage or "",
            (data.state == "impounded") and (data.lot or "") or "",
            data.key, data.key,
        }
    else
        stateClause = "v.`state` = ? AND COALESCE(v.`garage`, '') = ?"
        params = {
            data.key, data.key, data.owner, data.plate,
            (data.state == "impounded") and 2 or 1,
            data.garage or "",
            data.key, data.key,
        }
    end

    local query = ([[
DELETE v, m FROM `%s` v LEFT JOIN `oxlyn_garage_vehicles` m ON m.`plate` = ?
        INNER JOIN (SELECT COUNT(*) AS matches FROM `%s` WHERE REPLACE(UPPER(`plate`), ' ', '') = ?) unique_plate ON unique_plate.matches = 1
        WHERE v.`%s` = ? AND v.`plate` = ? AND %s
        AND NOT EXISTS (SELECT 1 FROM `oxlyn_garage_parked` p WHERE p.`plate` = ?)
        AND NOT EXISTS (SELECT 1 FROM `oxlyn_garage_contracts` c WHERE c.`plate` = ? AND c.`status` IN ('pending', 'signed'))]])
        :format(tbl, tbl, ownerCol, stateClause)

    local affected = MySQL.update.await(query, params)
    local deleted = (affected or 0) > 0

    if deleted then
        plateCache[data.key] = nil
    end
    return deleted
end

--- Mark as "out" (spawned).
function DB.SetOut(vehicle)
    if not DB.Mode then return false end

    local affected
    if DB.Mode == "esx" then
        affected = MySQL.update.await(
            "UPDATE `owned_vehicles` SET `stored` = 0, `pound` = NULL WHERE `plate` = ?",
            { vehicle.plate })
    else
        affected = MySQL.update.await(
            "UPDATE `player_vehicles` SET `state` = 0, `depotprice` = 0 WHERE `plate` = ?",
            { vehicle.plate })
    end
    return (affected or 0) > 0
end

--- Mark as stored in `garage` (no props update).
function DB.SetParking(vehicle, garage)
    if not DB.Mode then return false end

    local affected
    if DB.Mode == "esx" then
        affected = MySQL.update.await(
            "UPDATE `owned_vehicles` SET `stored` = 1, `parking` = ?, `pound` = NULL WHERE `plate` = ?",
            { garage, vehicle.plate })
    else
        affected = MySQL.update.await(
            "UPDATE `player_vehicles` SET `state` = 1, `garage` = ?, `depotprice` = 0 WHERE `plate` = ?",
            { garage, vehicle.plate })
    end
    return (affected or 0) > 0
end

--- Mark as impounded in `lot` (QB also stores the depot price).
function DB.SetImpounded(vehicle, lot, fee)
    if not DB.Mode then return false end

    local affected
    if DB.Mode == "esx" then
        affected = MySQL.update.await(
            "UPDATE `owned_vehicles` SET `stored` = 1, `pound` = ? WHERE `plate` = ?",
            { lot, vehicle.plate })
    else
        affected = MySQL.update.await(
            "UPDATE `player_vehicles` SET `state` = 2, `garage` = ?, `depotprice` = ? WHERE `plate` = ?",
            { lot, math.floor(fee or 0), vehicle.plate })
    end
    return (affected or 0) > 0
end

--- Impound a vehicle that was "lost" (marked out but not in the world),
--- writing impound info to the metadata table in the same statement.
--- `precheck` (optional) runs after the meta row is ensured; return false to abort.
function DB.SetLostImpounded(vehicle, lot, fee, reason, impoundedAt, impoundedBy, precheck)
    if not DB.Mode then return false end

    MySQL.query.await("INSERT IGNORE INTO `oxlyn_garage_vehicles` (`plate`) VALUES (?)", { vehicle.key })

    if precheck and not precheck() then
        return false
    end

    local isEsx = DB.Mode == "esx"
    local tbl = isEsx and "owned_vehicles" or "player_vehicles"

    local lostClause = isEsx
        and "v.`stored` = 0 AND (v.`pound` IS NULL OR v.`pound` = '') AND v.`owner` = ?"
        or  "v.`state` = 0 AND v.`citizenid` = ?"

    local setClause = isEsx
        and "v.`stored` = 1, v.`pound` = ?"
        or  "v.`state` = 2, v.`garage` = ?, v.`depotprice` = ?"

    local params = { vehicle.key, lot }
    if not isEsx then
        params[#params + 1] = fee
    end

    -- meta columns, then WHERE / guard parameters
    for _, value in ipairs({
        reason, fee, impoundedAt, impoundedBy, lot,   -- impound_reason/fee/at/by/lot
        vehicle.plate, vehicle.owner,                 -- v.plate = ?, owner/citizenid = ?
        vehicle.key, vehicle.key,                     -- NOT EXISTS parked / contracts
    }) do
        params[#params + 1] = value
    end

    local query = ([[
UPDATE `%s` v INNER JOIN `oxlyn_garage_vehicles` m ON m.`plate` = ?
        SET %s, m.`impound_reason` = ?, m.`impound_fee` = ?, m.`impound_at` = ?,
            m.`impound_by` = ?, m.`impound_lot` = ?
        WHERE v.`plate` = ? AND %s
          AND NOT EXISTS (SELECT 1 FROM `oxlyn_garage_parked` p WHERE p.`plate` = ?)
          AND NOT EXISTS (SELECT 1 FROM `oxlyn_garage_contracts` c WHERE c.`plate` = ? AND c.`status` IN ('pending', 'signed'))]])
        :format(tbl, setClause, lostClause)

    local affected = MySQL.update.await(query, params)
    return (affected or 0) > 0
end

--- Undo SetLostImpounded (only if the impound record still matches exactly).
function DB.RestoreLostOut(vehicle, lot, impoundedAt, impoundedBy)
    if not DB.Mode then return false end

    local isEsx = DB.Mode == "esx"
    local tbl = isEsx and "owned_vehicles" or "player_vehicles"

    local setClause = isEsx
        and "v.`stored` = 0, v.`pound` = NULL"
        or  "v.`state` = 0, v.`garage` = ?, v.`depotprice` = 0"

    local whereClause = isEsx
        and "v.`stored` = 1 AND v.`pound` = ? AND v.`owner` = ?"
        or  "v.`state` = 2 AND v.`garage` = ? AND v.`citizenid` = ?"

    local params = { vehicle.key }
    if not isEsx then
        params[#params + 1] = vehicle.garage or ""
    end

    for _, value in ipairs({
        vehicle.plate, lot, vehicle.owner,   -- v.plate = ?, pound/garage = ?, owner = ?
        lot, impoundedAt, impoundedBy,       -- m.impound_lot / impound_at / impound_by
    }) do
        params[#params + 1] = value
    end

    local query = ([[
UPDATE `%s` v INNER JOIN `oxlyn_garage_vehicles` m ON m.`plate` = ?
        SET %s, m.`impound_reason` = NULL, m.`impound_fee` = NULL, m.`impound_at` = NULL,
            m.`impound_by` = NULL, m.`impound_lot` = NULL
        WHERE v.`plate` = ? AND %s AND m.`impound_lot` = ? AND m.`impound_at` = ? AND m.`impound_by` = ?]])
        :format(tbl, setClause, whereClause)

    local affected = MySQL.update.await(query, params)
    return (affected or 0) > 0
end

--- Change owner of a vehicle.
function DB.Transfer(vehicle, newOwner, license)
    if not DB.Mode then return false end

    local affected
    if DB.Mode == "esx" then
        affected = MySQL.update.await(
            "UPDATE `owned_vehicles` SET `owner` = ? WHERE `plate` = ?",
            { newOwner, vehicle.plate })
    else
        affected = MySQL.update.await(
            "UPDATE `player_vehicles` SET `citizenid` = ?, `license` = ? WHERE `plate` = ?",
            { newOwner, license or "", vehicle.plate })
    end
    return (affected or 0) > 0
end

--- Put every "out" vehicle back to stored, except those whose plates are in `keepOut`.
--- Returns the number of rows affected.
function DB.RestoreAllOut(keepOut)
    if not DB.Mode then return 0 end

    local exclusion = ""
    local params = {}

    if type(keepOut) == "table" and #keepOut > 0 then
        local placeholders = {}
        for _, plate in ipairs(keepOut) do
            placeholders[#placeholders + 1] = "?"
            params[#params + 1] = plate
        end
        exclusion = (" AND REPLACE(`plate`, ' ', '') NOT IN (%s)"):format(table.concat(placeholders, ","))
    end

    if DB.Mode == "esx" then
        return MySQL.update.await(
            "UPDATE `owned_vehicles` SET `stored` = 1 WHERE `stored` = 0 AND (`pound` IS NULL OR `pound` = '')" .. exclusion,
            params) or 0
    end

    return MySQL.update.await(
        "UPDATE `player_vehicles` SET `state` = 1 WHERE `state` = 0" .. exclusion,
        params) or 0
end

---------------------------------------------------------------------
-- World-parked vehicles
---------------------------------------------------------------------

function DB.LoadParked()
    local rows = MySQL.query.await("SELECT * FROM `oxlyn_garage_parked`")
    local list = {}

    for _, row in ipairs(rows or {}) do
        list[#list + 1] = {
            key   = row.plate,
            plate = row.plate_raw or row.plate,
            owner = row.owner,
            model = tonumber(row.model) or 0,
            vtype = row.vtype or "automobile",
            x     = tonumber(row.x) or 0.0,
            y     = tonumber(row.y) or 0.0,
            z     = tonumber(row.z) or 0.0,
            w     = tonumber(row.w) or 0.0,
            props = decode(row.props),
            at    = tonumber(row.parked_at) or 0,
        }
    end

    return list
end

function DB.SavePark(park)
    MySQL.query.await(
        "INSERT INTO `oxlyn_garage_parked` (`plate`, `plate_raw`, `owner`, `model`, `vtype`, `x`, `y`, `z`, `w`, `props`, `parked_at`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE `owner` = VALUES(`owner`), `model` = VALUES(`model`), `vtype` = VALUES(`vtype`), `x` = VALUES(`x`), `y` = VALUES(`y`), `z` = VALUES(`z`), `w` = VALUES(`w`), `props` = VALUES(`props`), `parked_at` = VALUES(`parked_at`)",
        {
            park.key,
            park.plate,
            park.owner,
            park.model,
            park.vtype,
            park.x,
            park.y,
            park.z,
            park.w,
            json.encode(park.props or {}),
            park.at,
        }
    )
end

function DB.DeletePark(key)
    MySQL.query.await("DELETE FROM `oxlyn_garage_parked` WHERE `plate` = ?", { key })
end

---------------------------------------------------------------------
-- Vehicle metadata (oxlyn_garage_vehicles)
---------------------------------------------------------------------

local function metaFromRow(row)
    if not row then return nil end

    local data = decode(row.data)

    local meta = {
        nickname   = row.nickname,
        vtype      = row.vtype,
        storedAt   = tonumber(row.stored_at),
        storedBy   = row.stored_by,
        lastGarage = row.last_garage,
        contractId = row.contract_id,
        label      = data.label,
        class      = data.class,
    }

    if row.impound_at or row.impound_reason then
        meta.impound = {
            reason = row.impound_reason,
            fee    = tonumber(row.impound_fee) or 0,
            at     = tonumber(row.impound_at),
            by     = row.impound_by,
            lot    = row.impound_lot,
        }
    end

    return meta
end

function DB.GetMeta(key)
    local row = MySQL.single.await("SELECT * FROM `oxlyn_garage_vehicles` WHERE `plate` = ?", { key })
    return metaFromRow(row)
end

--- Batch fetch metadata for many plate keys. Returns { [key] = meta }.
function DB.ListMeta(keys)
    local result = {}
    if #keys == 0 then return result end

    -- de-duplicate
    local unique, seen = {}, {}
    for _, key in ipairs(keys) do
        if not seen[key] then
            seen[key] = true
            unique[#unique + 1] = key
        end
    end

    -- query in chunks of 500
    for i = 1, #unique, 500 do
        local placeholders, params = {}, {}
        for j = i, math.min(i + 499, #unique) do
            placeholders[#placeholders + 1] = "?"
            params[#params + 1] = unique[j]
        end

        local rows = MySQL.query.await(
            ("SELECT * FROM `oxlyn_garage_vehicles` WHERE `plate` IN (%s)"):format(table.concat(placeholders, ",")),
            params
        )

        for _, row in ipairs(rows or {}) do
            result[row.plate] = metaFromRow(row)
        end
    end

    return result
end

--- Insert/update only the provided metadata fields. `fields.data` is merged
--- into the existing JSON blob rather than replacing it.
--- A `false` or `nil`-valued key is skipped; use ClearImpound to null impound fields.
function DB.UpsertMeta(key, fields)
    if not key or key == "" then return end

    local columns      = { "`plate`" }
    local params       = { key }
    local placeholders = { "?" }
    local updates      = {}

    local function addColumn(name, value)
        columns[#columns + 1] = "`" .. name .. "`"
        if value == false or value == nil then
            placeholders[#placeholders + 1] = "NULL"
        else
            placeholders[#placeholders + 1] = "?"
            params[#params + 1] = value
        end
        updates[#updates + 1] = ("`%s` = VALUES(`%s`)"):format(name, name)
    end

    for _, name in ipairs({
        "nickname", "vtype", "stored_at", "stored_by", "last_garage",
        "impound_reason", "impound_fee", "impound_at", "impound_by", "impound_lot",
        "contract_id",
    }) do
        if fields[name] ~= nil then
            addColumn(name, fields[name])
        end
    end

    if fields.data ~= nil then
        local current = MySQL.scalar.await(
            "SELECT `data` FROM `oxlyn_garage_vehicles` WHERE `plate` = ?", { key })
        local merged = decode(current)
        for k, v in pairs(fields.data) do
            merged[k] = v
        end
        addColumn("data", json.encode(merged))
    end

    if #columns == 1 then return end -- nothing to write

    MySQL.query.await(
        ("INSERT INTO `oxlyn_garage_vehicles` (%s) VALUES (%s) ON DUPLICATE KEY UPDATE %s"):format(
            table.concat(columns, ","),
            table.concat(placeholders, ","),
            table.concat(updates, ",")),
        params
    )
end

function DB.ClearImpound(key)
    MySQL.query.await(
        "UPDATE `oxlyn_garage_vehicles` SET `impound_reason` = NULL, `impound_fee` = NULL, `impound_at` = NULL, `impound_by` = NULL, `impound_lot` = NULL WHERE `plate` = ?",
        { key })
end

---------------------------------------------------------------------
-- Garages
---------------------------------------------------------------------

function DB.LoadGarages()
    local rows = MySQL.query.await("SELECT `id`, `data` FROM `oxlyn_garages`")
    local garages = {}

    for _, row in ipairs(rows or {}) do
        local garage = decode(row.data)
        garage.id = garage.id or row.id
        garages[#garages + 1] = garage
    end

    return garages
end

function DB.SaveGarage(garage)
    MySQL.query.await(
        "INSERT INTO `oxlyn_garages` (`id`, `data`, `updated_at`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `data` = VALUES(`data`), `updated_at` = VALUES(`updated_at`)",
        { garage.id, json.encode(garage), os.time() })
end

function DB.DeleteGarage(id)
    MySQL.query.await("DELETE FROM `oxlyn_garages` WHERE `id` = ?", { id })
end

---------------------------------------------------------------------
-- Global settings
---------------------------------------------------------------------

function DB.LoadSettings()
    local raw = MySQL.scalar.await("SELECT `data` FROM `oxlyn_garage_settings` WHERE `id` = 'global'")
    if not raw then return nil end
    return decode(raw)
end

function DB.SaveSettings(settings)
    MySQL.query.await(
        "INSERT INTO `oxlyn_garage_settings` (`id`, `data`, `updated_at`) VALUES ('global', ?, ?) ON DUPLICATE KEY UPDATE `data` = VALUES(`data`), `updated_at` = VALUES(`updated_at`)",
        { json.encode(settings), os.time() })
end

function DB.DeleteSettings()
    MySQL.query.await("DELETE FROM `oxlyn_garage_settings` WHERE `id` = 'global'")
end

---------------------------------------------------------------------
-- Sale contracts
---------------------------------------------------------------------

local function contractFromRow(row)
    if not row then return nil end

    return {
        id            = row.id,
        plate         = row.plate,
        seller        = row.seller,
        sellerName    = row.seller_name,
        buyer         = row.buyer,
        buyerName     = row.buyer_name,
        price         = tonumber(row.price) or 0,
        model         = row.model,
        label         = row.label,
        status        = row.status,
        createdAt     = tonumber(row.created_at),
        expiresAt     = tonumber(row.expires_at),
        resolvedAt    = tonumber(row.resolved_at),
        refundPending = tonumber(row.refund_pending) == 1,
        data          = decode(row.data),
    }
end

local function contractsFromRows(rows)
    local list = {}
    for _, row in ipairs(rows or {}) do
        list[#list + 1] = contractFromRow(row)
    end
    return list
end

function DB.CreateContract(contract)
    MySQL.insert.await(
        "INSERT INTO `oxlyn_garage_contracts` (`id`, `plate`, `seller`, `seller_name`, `buyer`, `buyer_name`, `price`, `model`, `label`, `status`, `created_at`, `expires_at`, `data`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        {
            contract.id,
            contract.plate,
            contract.seller,
            contract.sellerName,
            contract.buyer,
            contract.buyerName,
            contract.price,
            contract.model,
            contract.label,
            "pending",
            contract.createdAt,
            contract.expiresAt,
            json.encode(contract.data or {}),
        }
    )
end

function DB.GetContract(id)
    if not id then return nil end
    return contractFromRow(MySQL.single.await(
        "SELECT * FROM `oxlyn_garage_contracts` WHERE `id` = ?", { id }))
end

function DB.ContractExists(id)
    local count = MySQL.scalar.await(
        "SELECT COUNT(*) FROM `oxlyn_garage_contracts` WHERE `id` = ?", { id })
    return (tonumber(count) or 0) > 0
end

function DB.PendingContractForPlate(plate)
    return contractFromRow(MySQL.single.await(
        "SELECT * FROM `oxlyn_garage_contracts` WHERE `plate` = ? AND `status` = 'pending' ORDER BY `created_at` DESC LIMIT 1",
        { plate }))
end

function DB.SetContractStatus(id, status)
    MySQL.update.await(
        "UPDATE `oxlyn_garage_contracts` SET `status` = ? WHERE `id` = ?",
        { status, id })
end

--- Close a contract, optionally flagging that the seller is owed a refund.
function DB.ResolveContract(id, status, refundPending)
    MySQL.update.await(
        "UPDATE `oxlyn_garage_contracts` SET `status` = ?, `resolved_at` = ?, `refund_pending` = ? WHERE `id` = ?",
        { status, os.time(), refundPending and 1 or 0, id })
end

function DB.SetContractBuyerName(id, name)
    MySQL.update.await(
        "UPDATE `oxlyn_garage_contracts` SET `buyer_name` = ? WHERE `id` = ?",
        { name, id })
end

function DB.PendingRefunds(seller)
    return contractsFromRows(MySQL.query.await(
        "SELECT * FROM `oxlyn_garage_contracts` WHERE `seller` = ? AND `refund_pending` = 1",
        { seller }))
end

function DB.ClearRefund(id)
    MySQL.update.await(
        "UPDATE `oxlyn_garage_contracts` SET `refund_pending` = 0 WHERE `id` = ?",
        { id })
end

--- Pending contracts whose expiry time is before `now`.
function DB.ExpiredContracts(now)
    return contractsFromRows(MySQL.query.await(
        "SELECT * FROM `oxlyn_garage_contracts` WHERE `status` = 'pending' AND `expires_at` IS NOT NULL AND `expires_at` < ?",
        { now }))
end

--- Expire every open (pending/signed) contract. Returns rows affected.
function DB.ExpirePendingContracts()
    return MySQL.update.await(
        "UPDATE `oxlyn_garage_contracts` SET `status` = 'expired', `resolved_at` = ? WHERE `status` IN ('pending', 'signed')",
        { os.time() }) or 0
end

---------------------------------------------------------------------
-- Offline money
---------------------------------------------------------------------

--- Add money to a player who is not online.
--- account: "cash" or anything else (treated as bank).
function DB.AddMoneyOffline(identifier, account, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or not identifier then
        return false
    end

    if DB.Mode == "esx" then
        local field = (account == "cash") and "money" or "bank"

        if DB.EsxAccountsJson then
            local path = "$." .. field
            local affected = MySQL.update.await(
                "UPDATE `users` SET `accounts` = JSON_SET(COALESCE(`accounts`, '{}'), ?, COALESCE(JSON_EXTRACT(`accounts`, ?), 0) + ?) WHERE `identifier` = ?",
                { path, path, amount, identifier })
            return (affected or 0) > 0
        end

        local affected = MySQL.update.await(
            ("UPDATE `users` SET `%s` = `%s` + ? WHERE `identifier` = ?"):format(field, field),
            { amount, identifier })
        return (affected or 0) > 0
    elseif DB.Mode == "qb" then
        local field = (account == "cash") and "cash" or "bank"
        local path = "$." .. field

        local affected = MySQL.update.await(
            "UPDATE `players` SET `money` = JSON_SET(COALESCE(`money`, '{}'), ?, COALESCE(JSON_EXTRACT(`money`, ?), 0) + ?) WHERE `citizenid` = ?",
            { path, path, amount, identifier })
        return (affected or 0) > 0
    end

    return false
end

