

-- Shared script (runs on both client and server).
-- Server: resolves the active key system and either calls it directly or relays to the client.
-- Client: runs client-only key systems and tracks grant results so callers can wait for them.

Keys = Keys or {}

local resourceName = GetCurrentResourceName()
local isServer = IsDuplicityVersion()

Keys.Build = "1.2.1"

if isServer then
    print(("[%s] vehicle keys bridge %s"):format(resourceName, Keys.Build))
end

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

-- Each warning key is only printed once (until a key resource starts/stops).
local warned = {}

local function warnOnce(key, message)
    if warned[key] then
        return
    end
    warned[key] = true
    print(("[%s] ^3vehicle keys: %s^7"):format(resourceName, tostring(message)))
end

local function trim(value)
    if type(value) == "string" then
        return (value:gsub("^%s+", ""):gsub("%s+$", ""))
    end
    return ""
end

local function isValidEntity(entity)
    return type(entity) == "number" and entity ~= 0
end

-- pcall wrapper. Returns true on success, or false plus an error/reason.
-- A provider returning `false` counts as failure; anything else (including nil) is success.
local function safeCall(fn, ...)
    if not fn then
        return false
    end

    local ok, result = pcall(fn, ...)
    if not ok or result == false then
        return false, ok and "provider returned false" or result
    end
    return true
end

---------------------------------------------------------------------
-- Provider definitions
---------------------------------------------------------------------
-- give/remove signature: (playerId, entity, plate, model)
--   entity = true  -> provider needs a live vehicle entity
--   relay  = true  -> the server hands the work to a client (client-side API)
--   noop   = true  -> nothing to do (key system needs no keys granted)
--   server = {...} -> extra server-side work done before relaying

local providers = {
    qbx = {
        resource = "qbx_vehiclekeys",
        entity = true,
        give = function(src, entity)
            return exports.qbx_vehiclekeys:GiveKeys(src, entity, true)
        end,
        remove = function(src, entity)
            return exports.qbx_vehiclekeys:RemoveKeys(src, entity, true)
        end,
    },

    qb = {
        resource = "qb-vehiclekeys",
        give = function(src, _, plate)
            return exports["qb-vehiclekeys"]:GiveKeys(src, plate)
        end,
        remove = function(src, _, plate)
            return exports["qb-vehiclekeys"]:RemoveKeys(src, plate)
        end,
    },

    mrnewb = {
        resource = "MrNewbVehicleKeys",
        give = function(src, _, plate)
            return exports.MrNewbVehicleKeys:GiveKeysByPlate(src, plate)
        end,
        remove = function(src, _, plate)
            return exports.MrNewbVehicleKeys:RemoveKeysByPlate(src, plate)
        end,
    },

    wasabi = {
        resource = "wasabi_carlock",
        give = function(src, _, plate)
            return exports.wasabi_carlock:GiveKey(src, plate)
        end,
        remove = function(src, _, plate)
            return exports.wasabi_carlock:RemoveKey(src, plate)
        end,
    },

    renewed = {
        resource = "Renewed-Vehiclekeys",
        give = function(src, _, plate)
            return exports["Renewed-Vehiclekeys"]:addKey(src, plate)
        end,
        remove = function(src, _, plate)
            return exports["Renewed-Vehiclekeys"]:removeKey(src, plate)
        end,
    },

    qs = { resource = "qs-vehiclekeys", relay = true },

    ti = {
        resource = "ti_vehicleKeys",
        give = function(src, _, plate)
            return exports.ti_vehicleKeys:createKey(src, plate)
        end,
    },

    jaksam = {
        resource = "vehicles_keys",
        give = function(src, _, plate)
            return exports.vehicles_keys:giveVehicleKeysToPlayerId(src, plate, "temporary")
        end,
        remove = function(src, _, plate)
            return exports.vehicles_keys:removeKeysFromPlayerId(src, plate)
        end,
    },

    -- ak47 / mk: check first so we don't duplicate or fail on missing keys
    ak47 = {
        resource = "ak47_vehiclekeys",
        give = function(src, _, plate)
            local ok, hasKey = pcall(function()
                return exports.ak47_vehiclekeys:HasKey(src, plate)
            end)
            if ok and hasKey == true then
                return true
            end
            return exports.ak47_vehiclekeys:GiveKey(src, plate)
        end,
        remove = function(src, _, plate)
            local ok, hasKey = pcall(function()
                return exports.ak47_vehiclekeys:HasKey(src, plate)
            end)
            if ok and hasKey == false then
                return true
            end
            return exports.ak47_vehiclekeys:RemoveKey(src, plate)
        end,
    },

    tgiann = {
        resource = "tgiann-hotwire",
        give = function(src, _, plate)
            return exports["tgiann-hotwire"]:GiveKeyPlate(src, plate, false)
        end,
    },

    brutal = {
        resource = "brutal_keys",
        give = function(src, _, plate)
            TriggerEvent("brutal_keys:server:addVehicleKey", src, plate, plate)
        end,
        remove = function(src, _, plate)
            TriggerEvent("brutal_keys:server:removeKey", src, plate, true)
        end,
    },

    mono = {
        resource = "mono_carkeys",
        give = function(src, _, plate)
            return exports.mono_carkeys:InventoryKeys("add", { plate = plate, player = src })
        end,
        remove = function(src, _, plate)
            return exports.mono_carkeys:InventoryKeys("remove", { plate = plate, player = src })
        end,
    },

    mk = {
        resource = "mk_vehiclekeys",
        entity = true,
        give = function(src, entity)
            local ok, hasKey = pcall(function()
                return exports.mk_vehiclekeys:HasKey(entity, src)
            end)
            if ok and hasKey == true then
                return true
            end
            return exports.mk_vehiclekeys:AddKey(entity, src)
        end,
        remove = function(src, entity)
            local ok, hasKey = pcall(function()
                return exports.mk_vehiclekeys:HasKey(entity, src)
            end)
            if ok and hasKey == false then
                return true
            end
            return exports.mk_vehiclekeys:RemoveKey(entity, src)
        end,
    },

    t1ger = {
        resource = "t1ger_keys",
        relay = true,
        server = {
            give = function(_, _, plate)
                exports.t1ger_keys:UpdateKeysToDatabase(plate, true)
            end,
            remove = function(_, _, plate)
                exports.t1ger_keys:UpdateKeysToDatabase(plate, false)
            end,
        },
    },

    frks      = { resource = "F_RealCarKeysSystem", relay = true },
    xd        = { resource = "xd_locksystem",       relay = true },
    esxlock   = { resource = "esx_vehiclelock",     noop = true },
    cd_garage = { resource = "cd_garage",           relay = true },
    okok      = { resource = "okokGarage",          relay = true },
}

-- Priority order used when Config.VehicleKeys.system is "auto"
local autoOrder = {
    "qbx", "qb", "mrnewb", "wasabi", "renewed", "qs", "ti", "jaksam", "ak47",
    "tgiann", "brutal", "mono", "mk", "t1ger", "frks", "xd", "esxlock",
    "cd_garage", "okok",
}

---------------------------------------------------------------------
-- System resolution (cached)
---------------------------------------------------------------------

local cachedSystem = nil
local cachedConfigSystem = nil

-- Clears caches when one of the key resources starts or stops.
local function onKeyResourceChange(name)
    for _, provider in pairs(providers) do
        if provider.resource == name then
            warned = {}
            cachedConfigSystem = nil
            cachedSystem = nil
            return true
        end
    end
    return false
end

AddEventHandler(isServer and "onResourceStart" or "onClientResourceStart", onKeyResourceChange)
AddEventHandler(isServer and "onResourceStop" or "onClientResourceStop", onKeyResourceChange)

-- Returns the active provider id, or "none".
function Keys.System()
    local config = Config.VehicleKeys or {}
    local system = config.system or "auto"

    if config.enabled == false then
        return "none"
    end

    -- use the cached result while it's still valid
    if cachedConfigSystem == system and cachedSystem then
        local provider = providers[cachedSystem]
        if not (provider and GetResourceState(provider.resource) ~= "started") then
            return cachedSystem
        end
    end

    cachedConfigSystem = system
    cachedSystem = nil

    if system ~= "auto" then
        if system == "none" then
            cachedSystem = "none"
        else
            local provider = providers[system]
            if not provider then
                warnOnce("unknown:" .. tostring(system), "unknown Config.VehicleKeys.system: " .. tostring(system))
                cachedSystem = "none"
            elseif GetResourceState(provider.resource) == "started" then
                cachedSystem = system
            else
                warnOnce("stopped:" .. system, provider.resource .. " is not started")
                return "none"
            end
        end
        return cachedSystem
    end

    -- auto: pick the first started provider, warn if several are running
    local running = {}
    for _, id in ipairs(autoOrder) do
        if GetResourceState(providers[id].resource) == "started" then
            cachedSystem = cachedSystem or id
            running[#running + 1] = id .. " (" .. providers[id].resource .. ")"
        end
    end

    if #running > 1 then
        warnOnce("auto-ambiguous",
            "multiple systems started: " .. table.concat(running, ", ")
            .. ". Auto selected " .. cachedSystem
            .. "; set Config.VehicleKeys.system explicitly to your active key system.")
    end

    return cachedSystem or "none"
end

-- Triggers each configured extra event. Returns true if any succeeded.
local function runHooks(events, ...)
    local anyOk = false

    for _, eventName in ipairs(type(events) == "table" and events or {}) do
        if type(eventName) == "string" and eventName ~= "" then
            local ok, err = safeCall(TriggerEvent, eventName, ...)
            anyOk = anyOk or ok
            if not ok then
                warnOnce("hook:" .. eventName, eventName .. ": " .. tostring(err))
            end
        end
    end

    return anyOk
end

---------------------------------------------------------------------
-- SERVER
---------------------------------------------------------------------

if isServer then
    local function dispatch(action, playerId, entity, plate, model, force)
        local config = Config.VehicleKeys or {}

        playerId = tonumber(playerId)
        plate = trim(plate)

        local valid = config.enabled ~= false
            and playerId and playerId > 0 and playerId % 1 == 0
            and GetPlayerName(playerId)
            and plate ~= ""
        if not valid then
            return false
        end

        if action == "remove" and config.removeOnStore == false and not force then
            return false
        end

        local system = Keys.System()
        local provider = providers[system]
        local netId = isValidEntity(entity) and NetworkGetNetworkIdFromEntity(entity) or 0

        local ok = false
        local err = nil
        local relayed = false

        local hookEvents = action == "give" and config.extraServerEvents or config.extraServerRemoveEvents
        local hookOk = runHooks(hookEvents, playerId, plate, model, entity)

        if provider and provider.relay then
            -- optional server-side work first
            if provider.server and provider.server[action] then
                local serverOk, serverErr = safeCall(provider.server[action], playerId, entity or 0, plate, model)
                if not serverOk then
                    warnOnce(system .. ":server-" .. action,
                        system .. " server " .. action .. ": " .. tostring(serverErr))
                end
            end

            -- hand off to the player's client, which reports back via ":keys:result"
            ok, err = safeCall(TriggerClientEvent, resourceName .. ":keys:client", playerId,
                action, system, plate, model, netId, force == true, hookOk)
            relayed = ok
        elseif provider and provider.noop then
            ok = true
        elseif provider then
            if provider.entity and not isValidEntity(entity) then
                err = "provider needs a live vehicle entity"
            elseif not provider[action] then
                err = action .. " unsupported; configure extra remove events"
            else
                ok, err = safeCall(provider[action], playerId, entity or 0, plate, model)
            end
        else
            -- no provider: only fine when the system is auto-detected or disabled
            local configured = config.system or "auto"
            ok = configured == "auto" or configured == "none"
        end

        ok = hookOk or ok

        if not ok then
            warnOnce(system .. ":" .. action,
                system .. " " .. action .. " failed: " .. tostring(err or "provider unavailable"))
        end

        if not relayed then
            TriggerClientEvent(resourceName .. ":keys:result", playerId, action, plate, netId, ok)
        end

        return ok
    end

    function Keys.GiveServer(playerId, entity, plate, model)
        return dispatch("give", playerId, entity, plate, model)
    end

    function Keys.RemoveServer(playerId, entity, plate, model, force)
        return dispatch("remove", playerId, entity, plate, model, force)
    end

---------------------------------------------------------------------
-- CLIENT
---------------------------------------------------------------------

else
    -- Latest result reported by the server for each plate, and local grants.
    local pending = {}
    local given = {}

    local function plateKey(plate)
        return trim(plate):upper()
    end

    local function recordResult(action, plate, netId, ok, model, plateUsed, modelUsed)
        local key = plateKey(plate)

        if action == "remove" then
            pending[key] = nil
            given[key] = nil
        else
            pending[key] = {
                netId = netId,
                at = GetGameTimer(),
                ok = ok,
                model = model,
                plateUsed = plateUsed,
                modelUsed = modelUsed,
            }
        end
    end

    -- Accepts a model hash or name and returns a display/spawn name (or nil).
    local function modelName(model)
        local hash = tonumber(model)
        if not hash and type(model) == "string" and type(GetHashKey) == "function" then
            hash = GetHashKey(model)
        end

        if hash and type(GetDisplayNameFromVehicleModel) == "function" then
            local ok, name = pcall(GetDisplayNameFromVehicleModel, hash)
            if ok and type(name) == "string" and name ~= "" and name ~= "CARNOTFOUND" and name ~= "NULL" then
                return name
            end
        end

        if type(model) == "string" and model ~= "" and not tonumber(model) then
            return model
        end

        return nil
    end

    -- Different key scripts store plates differently (padding, spaces, case),
    -- so build a list of spellings to try.
    local function plateCandidates(plate, entity)
        local list = {}
        local seen = {}

        local function add(value)
            if type(value) == "string" and value ~= "" and not seen[value] then
                seen[value] = true
                list[#list + 1] = value
            end
        end

        if isValidEntity(entity) then
            add(GetVehicleNumberPlateText(entity))
        end

        local trimmed = trim(plate)
        add(trimmed)

        if #trimmed > 0 and #trimmed < 8 then
            add(trimmed .. string.rep(" ", 8 - #trimmed))
        end

        add((trimmed:gsub("%s+", "")))

        return list
    end

    local function modelCandidates(model)
        local list = {}
        local seen = {}

        local function add(value)
            if type(value) == "string" and value ~= "" and not seen[value] then
                seen[value] = true
                list[#list + 1] = value
            end
        end

        add(modelName(model))

        if type(model) == "string" and model ~= "" and not tonumber(model) then
            add(model:upper())
            add(model)
        end

        if list[1] then
            add(list[1]:lower())
        end

        return list
    end

    -- qs-vehiclekeys: true/false, or nil if the export is unavailable.
    local function qsHasKey(plate, model)
        local ok, result = pcall(function()
            return exports["qs-vehiclekeys"]:GetKey(plate, model)
        end)
        if not ok then
            return nil
        end
        return result == true
    end

    -- Searches plate x model spellings.
    -- Returns true + the matching spelling, false if none match, or nil if unsupported.
    local function findQsKey(plates, models)
        for _, plate in ipairs(plates) do
            for _, model in ipairs(models) do
                local has = qsHasKey(plate, model)
                if has == nil then
                    return nil
                end
                if has then
                    return true, plate, model
                end
            end
        end
        return false
    end

    -- Client-side work for relay providers.
    -- Returns success, error message, and the plate/model spelling that worked.
    local function applyRelay(action, system, plate, model, entity)
        if system == "qs" then
            local plates = plateCandidates(plate, entity)
            local models = modelCandidates(model)

            if action ~= "give" and #models == 0 then
                models = { "" }
            end

            local plate1 = plates[1]
            local model1 = models[1]
            if not model1 then
                return false, "cannot resolve a model name for " .. tostring(model)
            end

            if action == "give" then
                -- already has the key?
                local found, foundPlate, foundModel = findQsKey(plates, models)
                if found then
                    return true, nil, foundPlate, foundModel
                end

                if exports["qs-vehiclekeys"]:GiveKeys(plate1, model1, false) ~= false then
                    return true, nil, plate1, model1
                end

                -- maybe it was granted under another spelling
                found, foundPlate, foundModel = findQsKey(plates, models)
                if found then
                    return true, nil, foundPlate, foundModel
                end
                if found == nil then
                    return false, "GiveKeys returned false"
                end

                for i = 2, #plates do
                    if exports["qs-vehiclekeys"]:GiveKeys(plates[i], model1, false) ~= false then
                        return true, nil, plates[i], model1
                    end
                end
                return false, "GiveKeys refused every plate spelling"
            end

            -- remove
            local found, foundPlate, foundModel = findQsKey(plates, models)
            if found == false then
                return true -- nothing to remove
            end

            if found then
                -- remove, then re-check up to 3 times for duplicates under other spellings
                local attempts = 0
                while found and attempts < 3 do
                    exports["qs-vehiclekeys"]:RemoveKeys(foundPlate, foundModel)
                    attempts = attempts + 1

                    local nextFound, nextPlate, nextModel = findQsKey(plates, models)
                    if not nextFound or (nextPlate == foundPlate and nextModel == foundModel) then
                        break
                    end
                    found, foundPlate, foundModel = nextFound, nextPlate, nextModel
                end
                return true
            end

            -- existence check unsupported: try every spelling blindly
            if exports["qs-vehiclekeys"]:RemoveKeys(plate1, model1) ~= false then
                return true
            end
            for i = 2, #plates do
                if exports["qs-vehiclekeys"]:RemoveKeys(plates[i], model1) ~= false then
                    return true
                end
            end
            for i = 2, #models do
                if exports["qs-vehiclekeys"]:RemoveKeys(plate1, models[i]) ~= false then
                    return true
                end
            end
            return false, "RemoveKeys refused every spelling"

        elseif system == "t1ger" then
            local label = modelName(model) or trim(plate)
            if action == "give" then
                exports.t1ger_keys:GiveTemporaryKeys(trim(plate), label, "garage")
            else
                TriggerServerEvent("t1ger_keys:deleteCarKeys", trim(plate), label)
            end
            return true

        elseif system == "frks" then
            local name = plateCandidates(plate, entity)[1] or trim(plate)
            if action == "give" then
                TriggerServerEvent("F_RealCarKeysSystem:generateVehicleKeys", name)
            else
                TriggerEvent("F_RealCarKeysSystem:removeVehicleKeysByPlate", name)
            end
            return true

        elseif system == "xd" then
            local name = plateCandidates(plate, entity)[1] or trim(plate)
            if action == "give" then
                exports.xd_locksystem:SetVehicleKey(name)
            else
                exports.xd_locksystem:SetVehicleKey(name, true)
            end
            return true

        elseif system == "cd_garage" then
            TriggerEvent(action == "give" and "cd_garage:AddKeys" or "cd_garage:RemoveKeys", plate)
            return true

        elseif system == "okok" then
            if action == "give" then
                TriggerServerEvent("okokGarage:GiveKeys", plate)
            else
                TriggerServerEvent("okokGarage:RemoveKeys", plate, GetPlayerServerId(PlayerId()))
            end
            return true
        end

        return false
    end

    -- Server -> client: perform a relayed give/remove
    RegisterNetEvent(resourceName .. ":keys:client", function(action, system, plate, model, netId, force, hookOk)
        if source ~= 65535 or (action ~= "give" and action ~= "remove") then
            return
        end

        local config = Config.VehicleKeys or {}
        local provider = providers[system]

        if not (config.enabled ~= false and provider and provider.relay and Keys.System() == system) then
            return
        end

        if action == "remove" and config.removeOnStore == false and force ~= true then
            return
        end

        plate = trim(plate)
        if plate == "" or GetResourceState(provider.resource) ~= "started" then
            return
        end

        local entity = (type(netId) == "number" and netId > 0 and NetworkGetEntityFromNetworkId(netId)) or 0

        local ok, result, err, plateUsed, modelUsed = pcall(applyRelay, action, system, plate, model, entity)
        local success
        if ok then
            success = result == true
        else
            err = result -- pcall error message
            success = false
        end

        local hookEvents = action == "give" and config.extraClientEvents or config.extraClientRemoveEvents
        local hooksOk = runHooks(hookEvents, plate, model, entity)
        success = hooksOk or hookOk == true or success

        recordResult(action, plate, netId, success, model, plateUsed, modelUsed)

        if not success then
            warnOnce(system .. ":" .. action,
                system .. " " .. action .. " failed: " .. tostring(err or "invalid model or refused operation"))
        end
    end)

    -- Server -> client: result of a non-relayed give/remove
    RegisterNetEvent(resourceName .. ":keys:result", function(action, plate, netId, ok)
        if not (source == 65535 and (action == "give" or action == "remove") and type(plate) == "string") then
            return
        end

        local config = Config.VehicleKeys or {}
        if config.enabled == false then
            return
        end

        local entity = (type(netId) == "number" and netId > 0 and NetworkGetEntityFromNetworkId(netId)) or 0
        local model = isValidEntity(entity) and GetEntityModel(entity) or nil

        local hookEvents = action == "give" and config.extraClientEvents or config.extraClientRemoveEvents
        local hooksOk = runHooks(hookEvents, trim(plate), model, entity)
        ok = hooksOk or ok == true

        recordResult(action, plate, netId, ok, model)
    end)

    AddEventHandler("onClientResourceStop", function(name)
        if onKeyResourceChange(name) then
            pending = {}
            given = {}
        end
    end)

    -- Gives the local player access to a vehicle they spawned (no key system call).
    function Keys.Give(vehicle)
        if not isValidEntity(vehicle) then
            return false
        end

        SetVehicleNeedsToBeHotwired(vehicle, false)
        SetVehicleHasBeenOwnedByPlayer(vehicle, true)

        local plate = trim(GetVehicleNumberPlateText(vehicle))
        if plate == "" then
            return false
        end

        given[plateKey(plate)] = {
            at = GetGameTimer(),
            netId = NetworkGetNetworkIdFromEntity(vehicle),
        }
        return true
    end

    -- Asks the key resource whether the player actually has the key.
    -- If the resource has no read export, trusts the successful grant result instead.
    local function verifyGrant(system, vehicle, plate, record)
        local model = record and record.model
        local resource, exportName, check

        if system == "qs" then
            resource, exportName = "qs-vehiclekeys", "GetKey"

            local plates, models
            if record and record.plateUsed then
                plates = { record.plateUsed }
                models = { record.modelUsed or modelCandidates(GetEntityModel(vehicle))[1] or "" }
            else
                plates = plateCandidates(plate, vehicle)
                models = modelCandidates(GetEntityModel(vehicle))
                if #models == 0 then
                    models = modelCandidates(model)
                end
                if #models == 0 then
                    return false
                end
            end

            check = function()
                local found = findQsKey(plates, models)
                if found == nil then
                    error("No such export GetKey in resource qs-vehiclekeys")
                end
                return found
            end

        elseif system == "qb" then
            resource, exportName = "qb-vehiclekeys", "HasKeys"
            check = function()
                return exports["qb-vehiclekeys"]:HasKeys(plate)
            end

        elseif system == "qbx" then
            resource, exportName = "qbx_vehiclekeys", "HasKeys"
            check = function()
                return exports.qbx_vehiclekeys:HasKeys(vehicle)
            end

        elseif system == "ak47" then
            resource, exportName = "ak47_vehiclekeys", "HasKey"
            check = function()
                return exports.ak47_vehiclekeys:HasKey(plate)
            end

        elseif system == "tgiann" then
            resource, exportName = "tgiann-hotwire", "HaveKeyPlate"
            check = function()
                if exports["tgiann-hotwire"]:HaveKeyPlate(plate) == true then
                    return true
                end
                return plateCandidates(plate, vehicle)[1] ~= plate
            end

        elseif system == "brutal" then
            resource, exportName = "brutal_keys", "getPlayerKey"
            check = function()
                return exports.brutal_keys:getPlayerKey(plate) == true
            end

        elseif system == "mono" then
            resource, exportName = "mono_carkeys", "GetPlayerKey"
            check = function()
                return exports.mono_carkeys:GetPlayerKey(vehicle) == true
            end

        elseif system == "mk" then
            resource, exportName = "mk_vehiclekeys", "HasKey"
            check = function()
                return exports.mk_vehiclekeys:HasKey(vehicle) == true
            end

        elseif system == "xd" then
            resource, exportName = "xd_locksystem", "GetVehicleData"
            check = function()
                local data = exports.xd_locksystem:GetVehicleData(plateCandidates(plate, vehicle)[1] or plate)
                return data == "self"
            end

        else
            return true -- no way to verify; assume granted
        end

        local ok, result = pcall(check)
        if ok then
            return result == true
        end

        local message = tostring(result)
        if message:find("No such export " .. exportName .. " in resource " .. resource, 1, true) then
            warnOnce(system .. ":read-unsupported",
                resource .. " has no " .. exportName .. " export; using its approved grant result")
            return true
        end

        warnOnce(system .. ":read", resource .. " " .. exportName .. " failed: " .. message)
        return false
    end

    -- Blocks (yields) until the key grant for `vehicle` has been confirmed, failed, or timed out.
    -- Returns true only if the key was granted and (where possible) verified.
    function Keys.WaitForGrant(vehicle, timeoutMs)
        local config = Config.VehicleKeys or {}
        if config.enabled == false or config.system == "none" then
            return true
        end

        local system = Keys.System()
        if system == "none" and (config.system or "auto") == "auto" then
            return true
        end

        if not isValidEntity(vehicle) then
            return false
        end

        local plate = trim(GetVehicleNumberPlateText(vehicle))
        local key = plateKey(plate)
        local baseline = given[key] -- ignore results older than a local grant
        local netId = NetworkGetNetworkIdFromEntity(vehicle)

        local startedAt = GetGameTimer()
        local timeout = math.max(0, math.min(15000, tonumber(timeoutMs) or 12000))
        local nextCheck = startedAt

        local function sameVehicle()
            return isValidEntity(vehicle) and NetworkGetNetworkIdFromEntity(vehicle) == netId
        end

        while true do
            if not sameVehicle() then
                return false
            end

            local record = pending[key]
            if record and record.netId == netId and (not baseline or record.at >= baseline.at) then
                if record.ok ~= true then
                    return false
                end

                local now = GetGameTimer()
                if nextCheck <= now then
                    local verified = verifyGrant(system, vehicle, plate, record)

                    if not sameVehicle() then
                        return false
                    end

                    if verified and pending[key] == record and (GetGameTimer() - startedAt) <= timeout then
                        return true
                    end

                    nextCheck = now + 100
                end
            end

            if GetGameTimer() - startedAt >= timeout then
                return false
            end

            Wait(25)
        end
    end
end

