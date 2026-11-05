local Bridge = require("server.bridge")

local locations = {}
local busyStations = {}
local activeRentals = {}
local warnedRentals = {}
local nextStationId = 1
local locationsFile = "locations.json"
local rentalsFile = "rentals.json"

local function loadJsonFile(filename, defaultData)
    local raw = LoadResourceFile(cache.resource, filename)
    if not raw or raw == "" then
        return defaultData
    end
    local ok, parsed = pcall(json.decode, raw)
    if ok and type(parsed) == "table" then
        return parsed
    end
    return defaultData
end

local function saveJsonFile(filename, data)
    local encoded = json.encode(data, { indent = true })
    SaveResourceFile(cache.resource, filename, encoded, -1)
end

local function loadStoredLocations()
    locations = {}

    if ScootConfig.locations and type(ScootConfig.locations) == "table" then
        for id, loc in pairs(ScootConfig.locations) do
            local stationId = tostring(id)
            locations[stationId] = {
                id = stationId,
                name = loc.name or "Station",
                coords = vec3(loc.coords.x + 0.0, loc.coords.y + 0.0, loc.coords.z + 0.0),
                heading = (loc.heading or 0.0) + 0.0,
                color = loc.color,
                blip = loc.blip or {},
                revision = 1,
                fixed = true
            }
        end
    end

    local saved = loadJsonFile(locationsFile, {})
    for id, loc in pairs(saved) do
        local stationId = tostring(id)
        local numId = tonumber(stationId)
        if numId and numId >= nextStationId then
            nextStationId = numId + 1
        end

        locations[stationId] = {
            id = stationId,
            name = loc.name or "Station",
            coords = vec3(loc.coords.x + 0.0, loc.coords.y + 0.0, loc.coords.z + 0.0),
            heading = (loc.heading or 0.0) + 0.0,
            color = loc.color,
            blip = loc.blip or {},
            revision = tonumber(loc.revision) or 1,
            fixed = false
        }
    end
end

local function saveStoredLocations()
    local toSave = {}
    for id, loc in pairs(locations) do
        if not loc.fixed then
            toSave[id] = {
                id = loc.id,
                name = loc.name,
                coords = { x = loc.coords.x, y = loc.coords.y, z = loc.coords.z },
                heading = loc.heading,
                color = loc.color,
                blip = loc.blip,
                revision = loc.revision
            }
        end
    end
    saveJsonFile(locationsFile, toSave)
end

local function broadcastLocations(target)
    local payload = {}
    for id, loc in pairs(locations) do
        payload[id] = {
            id = loc.id,
            name = loc.name,
            coords = { x = loc.coords.x, y = loc.coords.y, z = loc.coords.z },
            heading = loc.heading,
            color = loc.color,
            blip = loc.blip,
            revision = loc.revision,
            fixed = loc.fixed
        }
    end

    if target then
        TriggerClientEvent("scootbunker:setLocations", target, payload)
    else
        TriggerClientEvent("scootbunker:setLocations", -1, payload)
    end
end

local function loadStoredRentals()
    local now = os.time()
    local saved = loadJsonFile(rentalsFile, {})
    activeRentals = {}

    for identifier, rentData in pairs(saved) do
        local remaining = rentData.expires - now
        if remaining > 0 then
            rentData.recoverable = true
            rentData.vehicle = nil
            rentData.netId = nil
            activeRentals[identifier] = rentData
        end
    end
end

local function saveStoredRentals()
    local toSave = {}
    local now = os.time()

    for identifier, rentData in pairs(activeRentals) do
        if rentData.expires > now then
            toSave[identifier] = {
                identifier = rentData.identifier,
                plate = rentData.plate,
                plan = rentData.plan,
                minutes = rentData.minutes,
                started = rentData.started,
                expires = rentData.expires,
                account = rentData.account,
                price = rentData.price,
                stationId = rentData.stationId
            }
        end
    end

    saveJsonFile(rentalsFile, toSave)
end

local function formatRentalForClient(rentData)
    if not rentData then
        return false
    end
    local remaining = math.max(0, rentData.expires - os.time())
    if remaining <= 0 then
        return false
    end

    return {
        plate = rentData.plate,
        remaining = remaining,
        plan = rentData.plan,
        started = rentData.started,
        recoverable = rentData.recoverable == true
    }
end

local function generateScooterPlate()
    local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local r1 = math.random(1, 26)
    local r2 = math.random(1, 26)
    local num = math.random(100, 999)
    return string.format("SC%s%s%d", letters:sub(r1, r1), letters:sub(r2, r2), num)
end

local function spawnScooterVehicle(station, plate)
    local modelHash = joaat(ScootConfig.scooterModel or "labscoot")
    local rad = math.rad((station.heading + 180.0) % 360.0)
    local spawnX = station.coords.x
    local spawnY = station.coords.y
    local spawnZ = station.coords.z

    local veh = CreateVehicle(modelHash, spawnX, spawnY, spawnZ, (station.heading + 180.0) % 360.0, true, true)
    local timeout = GetGameTimer() + 2500

    while not DoesEntityExist(veh) and GetGameTimer() < timeout do
        Wait(50)
    end

    if not DoesEntityExist(veh) then
        return nil, nil
    end

    SetVehicleNumberPlateText(veh, plate)
    local netId = NetworkGetNetworkIdFromEntity(veh)

    return veh, netId
end

RegisterNetEvent("scootbunker:requestLocations", function()
    local src = source
    broadcastLocations(src)
end)

lib.callback.register("scootbunker:menu", function(source, stationId)
    stationId = tostring(stationId)
    local station = locations[stationId]
    if not station then
        return { ok = false, error = ScootT("invalid") }
    end

    local identifier = Bridge.getIdentifier(source)
    local rentData = activeRentals[identifier]
    local clientRental = formatRentalForClient(rentData)

    local balances = {}
    for _, acc in ipairs(ScootConfig.rental.accounts or { "cash", "bank" }) do
        balances[acc] = Bridge.getMoney(source, acc)
    end

    return {
        ok = true,
        station = {
            name = station.name or ScootT("station"),
            busy = busyStations[stationId] == true
        },
        busy = busyStations[stationId] == true,
        rental = clientRental,
        plans = ScootConfig.rental.plans,
        accounts = ScootConfig.rental.accounts,
        balance = balances
    }
end)

lib.callback.register("scootbunker:rent", function(source, data)
    if type(data) ~= "table" then
        return { ok = false, error = ScootT("invalid") }
    end

    local stationId = tostring(data.id)
    local station = locations[stationId]
    if not station then
        return { ok = false, error = ScootT("invalid") }
    end

    if busyStations[stationId] then
        return { ok = false, error = ScootT("busy") }
    end

    local identifier = Bridge.getIdentifier(source)
    local existing = activeRentals[identifier]
    if existing and (existing.expires - os.time()) > 0 then
        return { ok = false, error = ScootT("already_rented") }
    end

    local chosenPlan = nil
    for _, plan in ipairs(ScootConfig.rental.plans or {}) do
        if plan.id == data.plan then
            chosenPlan = plan
            break
        end
    end

    if not chosenPlan then
        return { ok = false, error = ScootT("invalid") }
    end

    local account = data.account or "cash"
    local balance = Bridge.getMoney(source, account)
    if balance < chosenPlan.price then
        return { ok = false, error = ScootT("insufficient") }
    end

    if not Bridge.removeMoney(source, account, chosenPlan.price) then
        return { ok = false, error = ScootT("insufficient") }
    end

    busyStations[stationId] = true

    local plate = generateScooterPlate()
    local veh, netId = spawnScooterVehicle(station, plate)

    if not veh or not netId then
        busyStations[stationId] = nil
        Bridge.addMoney(source, account, chosenPlan.price)
        return { ok = false, error = ScootT("model_failed") }
    end

    local now = os.time()
    local durationSec = chosenPlan.minutes * 60

    activeRentals[identifier] = {
        source = source,
        identifier = identifier,
        stationId = stationId,
        plate = plate,
        vehicle = veh,
        netId = netId,
        plan = chosenPlan.id,
        minutes = chosenPlan.minutes,
        started = now,
        expires = now + durationSec,
        account = account,
        price = chosenPlan.price,
        recoverable = false
    }

    warnedRentals[identifier] = nil
    saveStoredRentals()

    TriggerClientEvent("scootbunker:playCycle", -1, stationId, source, netId, plate)

    SetTimeout(11000, function()
        busyStations[stationId] = nil
    end)

    local clientRental = formatRentalForClient(activeRentals[identifier])
    return { ok = true, rental = clientRental }
end)

lib.callback.register("scootbunker:returnRental", function(source, stationId)
    local identifier = Bridge.getIdentifier(source)
    local rentData = activeRentals[identifier]

    if not rentData then
        return { ok = false, error = ScootT("invalid") }
    end

    local veh = rentData.vehicle
    if veh and DoesEntityExist(veh) then
        DeleteEntity(veh)
    end

    activeRentals[identifier] = nil
    warnedRentals[identifier] = nil
    saveStoredRentals()

    TriggerClientEvent("scootbunker:rentalUpdate", source, false)
    return { ok = true }
end)

lib.callback.register("scootbunker:recover", function(source, stationId)
    stationId = tostring(stationId)
    local station = locations[stationId]
    if not station then
        return { ok = false, error = ScootT("invalid") }
    end

    if busyStations[stationId] then
        return { ok = false, error = ScootT("busy") }
    end

    local identifier = Bridge.getIdentifier(source)
    local rentData = activeRentals[identifier]
    if not rentData or not rentData.recoverable then
        return { ok = false, error = ScootT("invalid") }
    end

    local remaining = rentData.expires - os.time()
    if remaining <= 0 then
        activeRentals[identifier] = nil
        saveStoredRentals()
        return { ok = false, error = ScootT("expired") }
    end

    busyStations[stationId] = true

    local veh, netId = spawnScooterVehicle(station, rentData.plate)
    if not veh or not netId then
        busyStations[stationId] = nil
        return { ok = false, error = ScootT("model_failed") }
    end

    rentData.vehicle = veh
    rentData.netId = netId
    rentData.recoverable = false
    rentData.source = source
    saveStoredRentals()

    TriggerClientEvent("scootbunker:playCycle", -1, stationId, source, netId, rentData.plate)

    SetTimeout(11000, function()
        busyStations[stationId] = nil
    end)

    local clientRental = formatRentalForClient(rentData)
    return { ok = true, rental = clientRental }
end)

lib.callback.register("scootbunker:status", function(source)
    local identifier = Bridge.getIdentifier(source)
    local rentData = activeRentals[identifier]
    return {
        ok = true,
        rental = formatRentalForClient(rentData)
    }
end)

lib.callback.register("scootbunker:creator", function(source)
    local adminAce = (ScootConfig.creator and ScootConfig.creator.adminAce) or "command"
    if not Bridge.hasPermission(source, adminAce) then
        return { ok = false, error = ScootT("no_permission") }
    end

    local payload = {}
    for id, loc in pairs(locations) do
        payload[id] = {
            id = loc.id,
            name = loc.name,
            coords = { x = loc.coords.x, y = loc.coords.y, z = loc.coords.z },
            heading = loc.heading,
            color = loc.color,
            blip = loc.blip,
            revision = loc.revision,
            fixed = loc.fixed
        }
    end

    return { ok = true, locations = payload }
end)

lib.callback.register("scootbunker:saveLocation", function(source, draft)
    local adminAce = (ScootConfig.creator and ScootConfig.creator.adminAce) or "command"
    if not Bridge.hasPermission(source, adminAce) then
        return { ok = false, error = ScootT("no_permission") }
    end

    if type(draft) ~= "table" or type(draft.coords) ~= "table" then
        return { ok = false, error = ScootT("invalid") }
    end

    local newPos = vec3(
        tonumber(draft.coords.x) or 0.0,
        tonumber(draft.coords.y) or 0.0,
        tonumber(draft.coords.z) or 0.0
    )
    local heading = (tonumber(draft.heading) or 0.0) % 360.0
    local minSpacing = (ScootConfig.creator and ScootConfig.creator.minimumSpacing) or 5.0
    local draftId = draft.id and tostring(draft.id) or nil

    for id, loc in pairs(locations) do
        if id ~= draftId then
            local dist = #(newPos - loc.coords)
            if dist < minSpacing then
                return { ok = false, error = ScootT("spacing") }
            end
        end
    end

    local stationCount = 0
    for _ in pairs(locations) do
        stationCount = stationCount + 1
    end

    local maxLocs = (ScootConfig.creator and ScootConfig.creator.maxLocations) or 200
    if not draftId and stationCount >= maxLocs then
        return { ok = false, error = ScootT("limit") }
    end

    local stationId = draftId or tostring(nextStationId)
    if not draftId then
        nextStationId = nextStationId + 1
    end

    local oldRevision = (locations[stationId] and locations[stationId].revision) or 0
    locations[stationId] = {
        id = stationId,
        name = draft.name or ScootT("new_station"),
        coords = newPos,
        heading = heading,
        color = draft.color,
        blip = draft.blip or {},
        revision = oldRevision + 1,
        fixed = false
    }

    saveStoredLocations()
    broadcastLocations()

    return {
        ok = true,
        id = stationId,
        revision = locations[stationId].revision
    }
end)

lib.callback.register("scootbunker:deleteLocation", function(source, data)
    local adminAce = (ScootConfig.creator and ScootConfig.creator.adminAce) or "command"
    if not Bridge.hasPermission(source, adminAce) then
        return { ok = false, error = ScootT("no_permission") }
    end

    local stationId = tostring(data and data.id or "")
    local station = locations[stationId]

    if not station or station.fixed then
        return { ok = false, error = ScootT("invalid") }
    end

    if busyStations[stationId] then
        return { ok = false, error = ScootT("in_use") }
    end

    for _, rentData in pairs(activeRentals) do
        if rentData.stationId == stationId and (rentData.expires - os.time()) > 0 then
            return { ok = false, error = ScootT("in_use") }
        end
    end

    locations[stationId] = nil
    saveStoredLocations()
    broadcastLocations()

    local payload = {}
    for id, loc in pairs(locations) do
        payload[id] = {
            id = loc.id,
            name = loc.name,
            coords = { x = loc.coords.x, y = loc.coords.y, z = loc.coords.z },
            heading = loc.heading,
            color = loc.color,
            blip = loc.blip,
            revision = loc.revision,
            fixed = loc.fixed
        }
    end

    return { ok = true, locations = payload }
end)

CreateThread(function()
    loadStoredLocations()
    loadStoredRentals()

    while true do
        Wait(1000)
        local now = os.time()
        local warningSec = (ScootConfig.rental and ScootConfig.rental.warningSeconds) or 60

        for identifier, rentData in pairs(activeRentals) do
            local remaining = rentData.expires - now

            if remaining <= 0 then
                local veh = rentData.vehicle
                if veh and DoesEntityExist(veh) then
                    DeleteEntity(veh)
                end

                if rentData.source and GetPlayerPing(rentData.source) > 0 then
                    TriggerClientEvent("scootbunker:rentalUpdate", rentData.source, false)
                    TriggerClientEvent("scootbunker:notify", rentData.source, ScootT("expired"))
                end

                activeRentals[identifier] = nil
                warnedRentals[identifier] = nil
                saveStoredRentals()
            elseif remaining <= warningSec and not warnedRentals[identifier] then
                warnedRentals[identifier] = true
                if rentData.source and GetPlayerPing(rentData.source) > 0 then
                    TriggerClientEvent("scootbunker:notify", rentData.source, ScootT("expiry_warning", tostring(remaining)))
                end
            end
        end
    end
end)

AddEventHandler("playerDropped", function()
    local src = source
    for _, rentData in pairs(activeRentals) do
        if rentData.source == src then
            rentData.source = nil
        end
    end
end)

exports("GetLocations", function()
    return locations
end)

exports("GetStation", function(stationId)
    return locations[tostring(stationId)]
end)

exports("GetActiveRentals", function()
    return activeRentals
end)

exports("GetPlayerRental", function(source)
    local identifier = Bridge.getIdentifier(source)
    return activeRentals[identifier]
end)

exports("EndPlayerRental", function(source)
    local identifier = Bridge.getIdentifier(source)
    local rentData = activeRentals[identifier]
    if not rentData then
        return false
    end

    local veh = rentData.vehicle
    if veh and DoesEntityExist(veh) then
        DeleteEntity(veh)
    end

    activeRentals[identifier] = nil
    warnedRentals[identifier] = nil
    saveStoredRentals()

    TriggerClientEvent("scootbunker:rentalUpdate", source, false)
    return true
end)

RegisterCommand("scootreload", function(source)
    if source ~= 0 and not Bridge.hasPermission(source, "command") then
        return
    end

    loadStoredLocations()
    loadStoredRentals()
    broadcastLocations()

    local msg = "[scootbunker] Stations and rentals reloaded successfully."
    if source == 0 then
        print(msg)
    else
        TriggerClientEvent("scootbunker:notify", source, msg)
    end
end, true)

RegisterCommand("scootwipe", function(source)
    if source ~= 0 and not Bridge.hasPermission(source, "command") then
        return
    end

    local count = 0
    for identifier, rentData in pairs(activeRentals) do
        local veh = rentData.vehicle
        if veh and DoesEntityExist(veh) then
            DeleteEntity(veh)
        end
        if rentData.source and GetPlayerPing(rentData.source) > 0 then
            TriggerClientEvent("scootbunker:rentalUpdate", rentData.source, false)
        end
        count = count + 1
    end

    activeRentals = {}
    warnedRentals = {}
    saveStoredRentals()

    local msg = string.format("[scootbunker] Wiped %d active rentals.", count)
    if source == 0 then
        print(msg)
    else
        TriggerClientEvent("scootbunker:notify", source, msg)
    end
end, true)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= cache.resource then
        return
    end

    saveStoredLocations()
    saveStoredRentals()

    for _, rentData in pairs(activeRentals) do
        local veh = rentData.vehicle
        if veh and DoesEntityExist(veh) then
            DeleteEntity(veh)
        end
    end
end)
