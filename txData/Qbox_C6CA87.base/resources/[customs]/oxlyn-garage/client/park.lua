

Park = Park or {}

local RESOURCE = GetCurrentResourceName()

-- Per-vehicle tracking tables (keyed by entity handle)
local lockedAt = {}        -- state.at value the lock/invincibility was last applied for
local propsAppliedAt = {}  -- state.at value the props were last applied for
local ownedStates = {}     -- parked state, only for vehicles that belong to this player
local blips = {}           -- blip handle per vehicle
local unparkPending = {}   -- vehicles with an unpark request in flight
local collisionOn = {}     -- vehicles whose collision is temporarily enabled (nearest owned one)

local NEARBY_RADIUS = 6.0  -- how close an owned parked vehicle must be to be targeted
local ENTER_DISTANCE = 3.5 -- distance at which pressing the enter key unparks it

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function getConfig()
    if Client.Settings and Client.Settings.park then
        return Client.Settings.park
    end
    return Config.Park or {}
end

-- NOTE: the original ignores its argument; "owned" simply means we have an identifier.
local function isOwner(_state)
    return Client.Identifier ~= nil
end

local function removeBlip(entity)
    local blip = blips[entity]
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
    blips[entity] = nil
end

local function addBlip(entity)
    if blips[entity] and DoesBlipExist(blips[entity]) then return end

    local blip = AddBlipForEntity(entity)
    SetBlipSprite(blip, 225)
    SetBlipColour(blip, 3)
    SetBlipScale(blip, 0.7)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(_U("park_blip"))
    EndTextCommandSetBlipName(blip)

    blips[entity] = blip
end

-- ---------------------------------------------------------------------------
-- Applying / releasing parked state
-- ---------------------------------------------------------------------------

local function applyState(entity, state)
    if not DoesEntityExist(entity) then return end

    local cfg = getConfig()
    local owned = isOwner(state)

    ownedStates[entity] = (owned and state) or nil

    -- Only the network owner applies props, so they're set once per park event
    if propsAppliedAt[entity] ~= state.at then
        if NetworkGetEntityOwner(entity) == PlayerId() then
            propsAppliedAt[entity] = state.at

            SetEntityInvincible(entity, false)
            Props.Set(entity, state.props or {})

            if state.plateRaw then
                SetVehicleNumberPlateText(entity, state.plateRaw)
            end

            SetVehicleEngineOn(entity, false, true, true)
            SetVehicleDoorsShut(entity, false)
            SetEntityInvincible(entity, true)
        end
    end

    -- Lock for non-owners (applied once per park event)
    if lockedAt[entity] ~= state.at then
        lockedAt[entity] = state.at
        SetEntityInvincible(entity, true)
        SetVehicleDoorsLockedForPlayer(entity, PlayerId(), not owned)
    end

    FreezeEntityPosition(entity, true)

    local collision = cfg.collision == true
    SetEntityCollision(entity, collision, collision)

    if owned then
        if cfg.blip ~= false then
            addBlip(entity)
        end
    else
        removeBlip(entity)
    end
end

local function releaseVehicle(entity)
    lockedAt[entity] = nil
    propsAppliedAt[entity] = nil
    ownedStates[entity] = nil
    unparkPending[entity] = nil
    collisionOn[entity] = nil
    removeBlip(entity)

    if not DoesEntityExist(entity) then return end

    FreezeEntityPosition(entity, false)
    SetEntityCollision(entity, true, true)
    SetEntityInvincible(entity, false)
    SetVehicleDoorsLockedForPlayer(entity, PlayerId(), false)
    SetVehicleDoorsLocked(entity, 1)

    if NetworkHasControlOfEntity(entity) then
        SetVehicleEngineOn(entity, GetIsVehicleEngineRunning(entity), true, false)
    end
end

-- React to state bag changes on vehicles
AddStateBagChangeHandler("oxlynParked", nil, function(bagName, _, value)
    local entity = GetEntityFromStateBagName(bagName)
    if not entity or entity == 0 then return end

    if type(value) == "table" then
        CreateThread(function()
            -- Entity may not have streamed in yet; wait up to 5s
            local start = GetGameTimer()
            while not DoesEntityExist(entity) and (GetGameTimer() - start) < 5000 do
                Wait(50)
            end
            applyState(entity, value)
        end)
    else
        releaseVehicle(entity)
    end
end)

-- Periodic sweep to catch vehicles streamed in later and clean up deleted ones
CreateThread(function()
    while true do
        Wait(1000)

        for _, vehicle in ipairs(GetGamePool("CVehicle")) do
            local state = Entity(vehicle).state.oxlynParked
            if type(state) == "table" then
                applyState(vehicle, state)
            elseif lockedAt[vehicle] then
                releaseVehicle(vehicle)
            end
        end

        for vehicle in pairs(lockedAt) do
            if not DoesEntityExist(vehicle) then
                lockedAt[vehicle] = nil
                propsAppliedAt[vehicle] = nil
                ownedStates[vehicle] = nil
                collisionOn[vehicle] = nil
                unparkPending[vehicle] = nil
                removeBlip(vehicle)
            end
        end
    end
end)

-- ---------------------------------------------------------------------------
-- Unparking
-- ---------------------------------------------------------------------------

-- Returns false if a request for this vehicle is already pending
local function requestUnpark(entity)
    if unparkPending[entity] then
        return false
    end

    unparkPending[entity] = true
    TriggerServerEvent(RESOURCE .. ":sv:unpark", NetworkGetNetworkIdFromEntity(entity))

    SetTimeout(3000, function()
        unparkPending[entity] = nil
    end)

    return true
end

-- Waits for the parked state to clear, then makes the player enter the vehicle
local function enterAfterUnpark(entity)
    CreateThread(function()
        local start = GetGameTimer()

        while (GetGameTimer() - start) < 2500 do
            if not DoesEntityExist(entity) then return end
            if type(Entity(entity).state.oxlynParked) ~= "table" then break end
            Wait(50)
        end

        local ped = PlayerPedId()
        if DoesEntityExist(entity)
            and not IsPedInAnyVehicle(ped, false)
            and GetVehiclePedIsTryingToEnter(ped) == 0 then
            TaskEnterVehicle(ped, entity, 5000, -1, 1.5, 1, 0)
        end
    end)
end

-- Nearest owned parked vehicle within NEARBY_RADIUS: returns entity, distance
local function findNearestOwned(coords)
    local best = nil
    local bestSq = NEARBY_RADIUS * NEARBY_RADIUS

    for entity, state in pairs(ownedStates) do
        if isOwner(state) and DoesEntityExist(entity) then
            local pos = GetEntityCoords(entity)
            local dx, dy, dz = coords.x - pos.x, coords.y - pos.y, coords.z - pos.z
            local distSq = dx * dx + dy * dy + dz * dz

            if bestSq > distSq then
                best = entity
                bestSq = distSq
            end
        end
    end

    return best, math.sqrt(bestSq)
end

-- Returns the wait time (ms) before the next tick
function Park.Tick()
    local ped = PlayerPedId()
    local inVehicle = IsPedInAnyVehicle(ped, false)

    local entering = GetVehiclePedIsTryingToEnter(ped)
    if entering == 0 and inVehicle then
        entering = GetVehiclePedIsIn(ped, false)
    end

    -- Entering/occupying one of our parked vehicles auto-unparks it
    if entering ~= 0 then
        local state = Entity(entering).state.oxlynParked
        if type(state) == "table" and isOwner(state) then
            requestUnpark(entering)
        end
    end

    local target, dist
    if not inVehicle then
        target, dist = findNearestOwned(GetEntityCoords(ped))
    end

    -- Restore "no collision" on any vehicle that is no longer the target
    for entity in pairs(collisionOn) do
        if entity ~= target then
            collisionOn[entity] = nil
            if DoesEntityExist(entity) and lockedAt[entity] and getConfig().collision ~= true then
                SetEntityCollision(entity, false, false)
            end
        end
    end

    if not target then
        return 200
    end

    -- Give the nearest owned vehicle collision so the player can interact with it
    if not collisionOn[target] then
        collisionOn[target] = true
        SetEntityCollision(target, true, true)
    end

    -- Control 23 = vehicle enter (F)
    if dist <= ENTER_DISTANCE and IsControlJustPressed(0, 23) then
        if GetVehiclePedIsTryingToEnter(ped) ~= target then
            if requestUnpark(target) then
                enterAfterUnpark(target)
            end
        end
    end

    return 0
end

function Park.Apply(entity, state)
    applyState(entity, state)
end

CreateThread(function()
    while true do
        Wait(Park.Tick())
    end
end)

-- ---------------------------------------------------------------------------
-- Hologram (parking info projected to the UI)
-- ---------------------------------------------------------------------------

local hologramToken = 0

-- Returns true if a hologram was shown
function Park.ShowHologram(worldPos, info)
    local seconds = tonumber(Config.Park.hologramSeconds) or 8
    if seconds <= 0 then
        return false
    end

    hologramToken = hologramToken + 1
    local myToken = hologramToken

    Client.NUI("park:holo", {
        label = info.label,
        plate = info.plate,
        hours = tonumber(info.hours) or 0,
        fee = tonumber(info.fee) or 0,
        seconds = seconds,
    })

    CreateThread(function()
        local endAt = GetGameTimer() + math.floor(seconds * 1000)
        local lastPayload = ""

        while myToken == hologramToken and endAt > GetGameTimer() do
            local onScreen, sx, sy = GetScreenCoordFromWorldCoord(worldPos.x, worldPos.y, worldPos.z)
            local dist = #(GetEntityCoords(PlayerPedId()) - worldPos)

            local payload = "null"
            if onScreen and dist < 45.0 then
                payload = ('{"x":%d,"y":%d,"d":%d}'):format(
                    math.floor(sx * 2000 + 0.5),
                    math.floor(sy * 2000 + 0.5),
                    math.floor(dist * 10 + 0.5)
                )
            end

            -- Only message the UI when the position actually changes
            if payload ~= lastPayload then
                lastPayload = payload
                SendNuiMessage('{"type":"park:holoPos","data":' .. payload .. '}')
            end

            Wait(0)
        end

        if myToken == hologramToken then
            Client.NUI("park:holoEnd", {})
        end
    end)

    return true
end

-- ---------------------------------------------------------------------------
-- Parking the nearest vehicle
-- ---------------------------------------------------------------------------

-- Closest networked vehicle within radius: returns entity, netId (0, 0 if none)
local function findNearbyVehicle(coords, radius)
    radius = tonumber(radius) or 8.0
    if radius ~= radius or radius < 0 or radius == math.huge then
        radius = 8.0
    end

    local best, bestNetId = 0, 0
    local bestSq = radius * radius

    for _, vehicle in ipairs(GetGamePool("CVehicle")) do
        if DoesEntityExist(vehicle) and NetworkGetEntityIsNetworked(vehicle) then
            local pos = GetEntityCoords(vehicle)
            local dx, dy, dz = pos.x - coords.x, pos.y - coords.y, pos.z - coords.z
            local distSq = dx * dx + dy * dy + dz * dz

            if bestSq >= distSq then
                local netId = NetworkGetNetworkIdFromEntity(vehicle)
                if netId and netId > 0 then
                    best = vehicle
                    bestNetId = netId
                    bestSq = distSq
                end
            end
        end
    end

    return best, bestNetId
end

function Park.Here()
    local cfg = getConfig()

    if cfg.enabled == false then
        return Client.Notify(_U("park_disabled"), "error")
    end

    if Client.Busy() then return end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        return Client.Notify(_U("park_get_out"), "error")
    end

    local vehicle, netId = findNearbyVehicle(GetEntityCoords(ped), cfg.radius)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return Client.Notify(_U("park_no_vehicle"), "error")
    end

    if Entity(vehicle).state.oxlynParked then
        return Client.Notify(_U("park_already"), "error")
    end

    local props = Props.Get(vehicle) or {}
    local model = GetEntityModel(vehicle)
    local vehCoords = GetEntityCoords(vehicle)
    local _, maxDim = GetModelDimensions(model)

    -- Hologram floats just above the roof
    local holoPos = vector3(
        vehCoords.x,
        vehCoords.y,
        vehCoords.z + ((maxDim and maxDim.z) or 1.2) + 0.45
    )

    local label = Props.Label(model)
    local plate = Utils.Trim(GetVehicleNumberPlateText(vehicle) or "")

    Framework.TriggerCallback("park:park", function(res)
        if not res then return end

        if res.ok then
            local shown = Park.ShowHologram(holoPos, {
                label = res.label or label,
                plate = res.plate or plate,
                hours = res.hours,
                fee = res.fee,
            })
            if shown then return end
        end

        Client.Notify(res.message or _U("park_no_vehicle"), res.ok and "success" or "error")
    end, netId, props, GetVehicleType(vehicle))
end

-- ---------------------------------------------------------------------------
-- Command & keybind
-- ---------------------------------------------------------------------------

if Config.Commands.park then
    RegisterCommand(Config.Commands.park, function()
        Park.Here()
    end, false)
end

local function getKeybindConfig()
    if type(Config.Park.keybind) == "table" then
        return Config.Park.keybind
    end
    return {}
end

local keybind = getKeybindConfig()

if keybind.enabled == true then
    local commandName = RESOURCE .. ":park"
    local held = false

    RegisterCommand("+" .. commandName, function()
        if held then return end
        held = true

        local kb = getKeybindConfig()
        local allowed = kb.enabled == true
            and Client.Ready
            and not Client.Busy()
            and not IsPauseMenuActive()
            and not IsNuiFocused()

        if not allowed then return end

        Park.Here()
    end, false)

    RegisterCommand("-" .. commandName, function()
        held = false
    end, false)

    local mapper = type(keybind.mapper) == "string" and Utils.Trim(keybind.mapper) or ""
    local key = type(keybind.key) == "string" and Utils.Trim(keybind.key) or ""

    RegisterKeyMapping(
        "+" .. commandName,
        _U("park_keybind"),
        (mapper ~= "") and mapper or "keyboard",
        (key ~= "") and key or "F7"
    )
end

-- ---------------------------------------------------------------------------
-- Cleanup
-- ---------------------------------------------------------------------------

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= RESOURCE then return end

    for entity in pairs(blips) do
        removeBlip(entity)
    end
end)

