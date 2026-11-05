

Garage = Garage or {}
Garage.List = {}      -- array of garages (synced from server)
Garage.ById = {}      -- id -> garage
Garage.Open = false
Garage.Current = nil  -- id of the garage whose menu is open

local RESOURCE = GetCurrentResourceName()

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

local blips = {}              -- garage id -> blip
local peds = {}               -- garage id -> attendant ped
local targetZones = {}        -- { {kind="ox"|"qb", id=...}, ... }
local nearbyGarages = {}      -- garages within draw distance of the player
local ghostGarages = {}       -- nearby garages with vehicleCollision == false
local pedPending = {}         -- garage id -> generation of an in-flight ped spawn
local pedGen = 0
local promptThreadRunning = false
local ghostThreadRunning = false
local promptState = { shown = false, kind = nil, garage = nil, label = nil }
local menuData = nil          -- last payload sent to the garage NUI
local busy = false            -- a store/takeout/release is in progress
local lastWorldJson = ""
local covered = false         -- true while pause menu / fade / NUI focus hides the HUD
local activeTarget = nil      -- "ox_target" | "qb-target" | nil
local impoundToolOpen = false
local locateBlip = nil

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function nui(name, data)
    Client.NUI(name, data)
end

local function settings()
    return Client.Settings or {}
end

-- squared distance between two vec3-likes
local function distSq(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

function Garage.Enrich(v)
    if type(v) ~= "table" then return v end

    local model = tonumber(v.model) or (v.props and tonumber(v.props.model)) or 0
    v.model = model
    v.displayName = Props.Label(model)
    v.image = Props.ImageName(model, v.modelName)
    v.label = v.nickname or v.label or v.displayName
    v.class = (model ~= 0 and GetVehicleClassFromName(model)) or 0
    v.category = v.vtype or Utils.CategoryFromClass(v.class)
    v.condition = v.condition or Utils.Condition(v.props)
    v.color = v.props and v.props.color1 or nil
    v.color2 = v.props and v.props.color2 or nil
    return v
end

local function rebuildById()
    Garage.ById = {}
    for _, g in ipairs(Garage.List) do
        Garage.ById[g.id] = g
    end
end

-- Sends the minimal garage list to the NUI (for the map/world layer)
local function sendWorldMeta()
    local list = {}
    for _, g in ipairs(Garage.List) do
        if g.accessible or not Config.Blips.showOnlyAccessible then
            list[#list + 1] = {
                id = g.id,
                label = g.label,
                kind = g.kind,
                type = g.type,
                radius = g.radius,
            }
        end
    end
    nui("world:meta", list)
end

RegisterNetEvent(RESOURCE .. ":client:sync", function(data)
    Garage.List = (type(data) == "table" and data) or {}
    nearbyGarages = {}
    ghostGarages = {}

    rebuildById()
    Garage.RebuildBlips()
    Garage.RebuildTargets()
    Garage.DespawnPeds()

    lastWorldJson = ""
    sendWorldMeta()

    if Editor and Editor.OnSync then
        Editor.OnSync(Garage.List)
    end
end)

function Garage.ResendWorld()
    sendWorldMeta()
    lastWorldJson = ""
    covered = nil
end

--------------------------------------------------------------------------------
-- Blips
--------------------------------------------------------------------------------

function Garage.RebuildBlips()
    for _, blip in pairs(blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    blips = {}

    if Config.Blips.enabled == false then return end

    for _, g in ipairs(Garage.List) do
        local show = g.blip and g.blip.enabled
        if show and Config.Blips.showOnlyAccessible and not g.accessible then
            show = false
        end

        if show then
            local blip = AddBlipForCoord(g.point.x, g.point.y, g.point.z)
            SetBlipSprite(blip, g.blip.sprite or 357)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, g.blip.scale or 0.75)
            SetBlipColour(blip, g.blip.color or 3)
            SetBlipAsShortRange(blip, true)

            BeginTextCommandSetBlipName("STRING")
            local name = g.blip.label
            if not name or name == "" then name = g.label end
            AddTextComponentSubstringPlayerName(name)
            EndTextCommandSetBlipName(blip)

            blips[g.id] = blip
        end
    end
end

--------------------------------------------------------------------------------
-- Attendant peds
--------------------------------------------------------------------------------

local function spawnPed(g, gen)
    local model = joaat(g.ped.model or "s_m_y_valet_01")
    if not (IsModelInCdimage(model) and IsModelValid(model)) then return end

    RequestModel(model)
    local started = GetGameTimer()
    while not HasModelLoaded(model) and (GetGameTimer() - started) < 5000 do
        Wait(50)
    end

    if not HasModelLoaded(model) then
        SetModelAsNoLongerNeeded(model)
        return
    end

    local spawnDistance = Config.Peds.spawnDistance or 60.0

    -- Abort if things changed while the model was loading
    local stillValid = gen == pedGen
        and Garage.ById[g.id] == g
        and distSq(GetEntityCoords(PlayerPedId()), g.point) <= spawnDistance * spawnDistance

    if not stillValid then
        SetModelAsNoLongerNeeded(model)
        return
    end

    local ped = CreatePed(4, model, g.point.x, g.point.y, g.point.z - 1.0, g.point.w, false, false)
    SetModelAsNoLongerNeeded(model)
    if not DoesEntityExist(ped) then return end

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedDiesWhenInjured(ped, false)

    if g.ped.scenario and g.ped.scenario ~= "" then
        TaskStartScenarioInPlace(ped, g.ped.scenario, 0, true)
    end

    peds[g.id] = ped
end

function Garage.DespawnPeds()
    pedGen = pedGen + 1
    pedPending = {}

    for _, ped in pairs(peds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    peds = {}
end

local function updatePeds(coords)
    if not Config.Peds.enabled then return end

    local spawnDistance = Config.Peds.spawnDistance or 60.0
    local maxSq = spawnDistance * spawnDistance

    for _, g in ipairs(Garage.List) do
        local wants = g.ped and g.ped.enabled
            and (g.accessible or not Config.Blips.showOnlyAccessible)
        local d = wants and distSq(coords, g.point) or math.huge

        if wants and d <= maxSq then
            local existing = peds[g.id]
            local alive = existing and DoesEntityExist(existing)

            if not alive and not pedPending[g.id] then
                local gen = pedGen
                pedPending[g.id] = gen

                CreateThread(function()
                    spawnPed(g, gen)
                    if pedPending[g.id] == gen then
                        pedPending[g.id] = nil
                    end
                end)
            end
        elseif peds[g.id] then
            if DoesEntityExist(peds[g.id]) then
                DeleteEntity(peds[g.id])
            end
            peds[g.id] = nil
        end
    end
end

--------------------------------------------------------------------------------
-- Interaction mode / third-party targeting
--------------------------------------------------------------------------------

function Garage.InteractionMode()
    local s = Client.Settings
    return (s and s.interaction and s.interaction.mode)
        or Config.Interaction.mode
        or "prompt"
end

function Garage.TargetResource()
    if GetResourceState("ox_target") == "started" then return "ox_target" end
    if GetResourceState("qb-target") == "started" then return "qb-target" end
    return nil
end

local function removeTargetZones()
    for _, zone in ipairs(targetZones) do
        if zone.kind == "ox" then
            pcall(function() exports.ox_target:removeZone(zone.id) end)
        else
            pcall(function() exports["qb-target"]:RemoveZone(zone.id) end)
        end
    end
    targetZones = {}
end

function Garage.RebuildTargets()
    removeTargetZones()
    activeTarget = nil

    local mode = Garage.InteractionMode()
    if mode ~= "target" and mode ~= "both" then return end

    local resource = Garage.TargetResource()
    if not resource then return end

    local isOx = resource == "ox_target"
    local cfg = Config.Interaction.target or {}
    local canInteract = function() return not Client.Busy() end

    for _, g in ipairs(Garage.List) do
        if g.accessible then
            local isImpound = g.kind == "impound"
            local label = (isImpound and _U("prompt_impound")) or _U("prompt_open")
            local icon
            if isImpound then
                icon = cfg.impoundIcon or "fa-solid fa-gavel"
            else
                icon = cfg.icon or "fa-solid fa-warehouse"
            end
            local garageId = g.id
            local pos = vector3(g.point.x, g.point.y, g.point.z)
            local radius = math.max(1.0, g.radius)

            if isOx then
                local ok, zoneId = pcall(function()
                    return exports.ox_target:addSphereZone({
                        coords = pos,
                        radius = radius,
                        debug = false,
                        options = {
                            {
                                name = RESOURCE .. ":" .. garageId,
                                icon = icon,
                                label = label,
                                distance = cfg.distance or 2.5,
                                canInteract = canInteract,
                                onSelect = function() Garage.OpenMenu(garageId) end,
                            },
                        },
                    })
                end)
                if ok and zoneId then
                    targetZones[#targetZones + 1] = { kind = "ox", id = zoneId }
                end
            else
                local name = RESOURCE .. ":" .. garageId
                local ok = pcall(function()
                    exports["qb-target"]:AddCircleZone(name, pos, radius, {
                        name = name,
                        debugPoly = false,
                        useZ = true,
                    }, {
                        options = {
                            {
                                icon = icon,
                                label = label,
                                canInteract = canInteract,
                                action = function() Garage.OpenMenu(garageId) end,
                            },
                        },
                        distance = cfg.distance or 2.5,
                    })
                end)
                if ok then
                    targetZones[#targetZones + 1] = { kind = "qb", id = name }
                end
            end
        end
    end

    if #targetZones > 0 then
        activeTarget = resource
    end
end

function Garage.PromptOnFoot()
    return Garage.InteractionMode() ~= "target"
end

AddEventHandler("onClientResourceStart", function(resource)
    if resource == "ox_target" or resource == "qb-target" then
        SetTimeout(500, Garage.RebuildTargets)
    end
end)

AddEventHandler("onClientResourceStop", function(resource)
    if resource == "ox_target" or resource == "qb-target" then
        targetZones = {}
        activeTarget = nil
        SetTimeout(500, Garage.RebuildTargets)
    end
end)

--------------------------------------------------------------------------------
-- On-screen prompt + world icons
--------------------------------------------------------------------------------

local function setPrompt(kind, g, label)
    if promptState.shown
        and promptState.kind == kind
        and promptState.garage == (g and g.id)
        and promptState.label == label then
        return
    end

    promptState.label = label
    promptState.garage = g and g.id or nil
    promptState.kind = kind
    promptState.shown = kind ~= nil

    if kind then
        nui("prompt", {
            visible = true,
            kind = kind,
            label = label,
            garage = g.label,
            key = Config.Interaction.keyLabel or "E",
        })
    else
        nui("prompt", { visible = false })
    end
end

function Garage.ResendPrompt()
    if promptState.shown and promptState.garage then
        local g = Garage.ById[promptState.garage]
        if g then
            nui("prompt", {
                visible = true,
                kind = promptState.kind,
                label = promptState.label,
                garage = g.label,
                key = Config.Interaction.keyLabel or "E",
            })
        end
    else
        nui("prompt", { visible = false })
    end

    Garage.ResendWorld()
end

-- Returns (isInside, distance) for a garage zone / store radius
local function inGarageZone(g, coords)
    if g.zone then
        local d = Utils.ZoneDistance(g.zone, coords)
        return d <= 0.5, d
    end

    local best = distSq(coords, g.point)
    for _, spot in ipairs(g.spots or {}) do
        local d = distSq(coords, spot)
        if best > d then best = d end
    end

    return best <= g.storeRadius * g.storeRadius, math.sqrt(best)
end

local worldBuf = {}

-- Projects nearby garages to screen space and sends them to the NUI as JSON
local function pushWorld(garages, coords, selectedId, hide)
    local count = 0

    if not hide then
        local range = (Config.Interaction.worldIcons and Config.Interaction.worldIcons.distance) or 12.0

        for i = 1, #garages do
            local g = garages[i]
            if g.accessible or not Config.Blips.showOnlyAccessible then
                local d = distSq(coords, g.point)
                if d <= range * range then
                    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(g.point.x, g.point.y, g.point.z + 1.15)
                    if onScreen then
                        count = count + 1
                        worldBuf[count] = ('{"i":"%s","x":%d,"y":%d,"d":%d,"a":%s}'):format(
                            g.id,
                            math.floor(sx * 2000 + 0.5),
                            math.floor(sy * 2000 + 0.5),
                            math.floor(math.sqrt(d) * 10 + 0.5),
                            selectedId == g.id and "true" or "false"
                        )
                    end
                end
            end
        end
    end

    for i = #worldBuf, count + 1, -1 do
        worldBuf[i] = nil
    end

    local json = (count == 0) and "[]" or ("[" .. table.concat(worldBuf, ",") .. "]")
    if json ~= lastWorldJson then
        lastWorldJson = json
        SendNuiMessage('{"type":"world","data":' .. json .. '}')
    end
end

-- NOTE: the decompiled original also called GetRenderingCam() here but
-- discarded the result, and compared IsPlayerSwitchInProgress() against -1 in a
-- way that can't be literal. Kept to the sensible reading.
local function isCovered()
    return IsPauseMenuActive()
        or IsNuiFocused()
        or IsScreenFadedOut()
        or IsScreenFadingOut()
        or IsPlayerSwitchInProgress()
end

local function setCovered(value)
    if value == covered then return end
    covered = value
    SendNuiMessage(value and '{"type":"covered","data":true}' or '{"type":"covered","data":false}')
end

local function worldIconsEnabled()
    local wi = Config.Interaction.worldIcons
    if wi and wi.enabled == false then return false end
    return (settings().worldIcon or "pin") ~= "none"
end

local function startPromptThread()
    if promptThreadRunning then return end
    promptThreadRunning = true

    CreateThread(function()
        local key = Config.Interaction.key or 38

        while #nearbyGarages > 0 do
            local onFoot = Garage.PromptOnFoot()
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local inVehicle = IsPedInAnyVehicle(ped, false)
            local veh = inVehicle and GetVehiclePedIsIn(ped, false) or 0
            local driving = inVehicle and veh ~= 0
            local category = driving and Utils.CategoryFromClass(GetVehicleClass(veh)) or nil

            local isHidden = isCovered()
            setCovered(isHidden)

            local blocked = isHidden or Client.Busy() or IsPedDeadOrDying(ped, true) or busy

            local kind, best, label
            local bestDist = math.huge

            for _, g in ipairs(nearbyGarages) do
                if g.accessible and not blocked then
                    if driving then
                        local inside, d = inGarageZone(g, coords)
                        if inside and bestDist > d then
                            best, bestDist = g, d
                            if g.kind == "impound" then
                                kind, label = "blocked", _U("prompt_impound_blocked")
                            elseif Utils.GarageAccepts(g.type, category) then
                                kind, label = "store", _U("prompt_store")
                            else
                                kind, label = "blocked", _U("prompt_blocked")
                            end
                        end
                    elseif not inVehicle and onFoot then
                        local d = distSq(coords, g.point)
                        if d <= g.radius * g.radius and bestDist > d then
                            best, bestDist = g, d
                            if g.kind == "impound" then
                                kind, label = "impound", _U("prompt_impound")
                            else
                                kind, label = "open", _U("prompt_open")
                            end
                        end
                    end
                end
            end

            setPrompt(kind, best, label)

            if worldIconsEnabled() then
                pushWorld(nearbyGarages, coords, best and best.id, isHidden or Client.Focus ~= nil)
            elseif lastWorldJson ~= "[]" then
                pushWorld(nearbyGarages, coords, nil, true)
            end

            if kind and kind ~= "blocked" and IsControlJustReleased(0, key) then
                if kind == "store" then
                    Garage.Store(best)
                else
                    Garage.OpenMenu(best.id)
                end
                Wait(300)
            end

            Wait(0)
        end

        setPrompt(nil)
        pushWorld({}, vector3(0, 0, 0), nil, true)
        setCovered(false)
        promptThreadRunning = false
    end)
end

--------------------------------------------------------------------------------
-- Ghost collision (garages with vehicleCollision == false)
--------------------------------------------------------------------------------

local function filterGhost(list)
    if not list then return ghostGarages end

    local out = {}
    for _, g in ipairs(list) do
        if g.vehicleCollision == false then
            out[#out + 1] = g
        end
    end
    return out
end

local function findZone(list, coords)
    for _, g in ipairs(list) do
        if inGarageZone(g, coords) then
            return g
        end
    end
    return nil
end

-- Returns vehicles that should be ghosted against `veh`, or nil if `veh`
-- isn't inside a ghost garage.
function Garage.GhostTargets(veh, list)
    list = list or filterGhost()

    if veh == 0 or #list == 0 or not findZone(list, GetEntityCoords(veh)) then
        return nil
    end

    local out = {}
    for _, other in ipairs(GetGamePool("CVehicle")) do
        if other ~= veh and findZone(list, GetEntityCoords(other)) then
            out[#out + 1] = other
        end
    end
    return out
end

local function startGhostThread()
    if ghostThreadRunning then return end
    ghostThreadRunning = true

    CreateThread(function()
        local cache = nil
        local nextRefresh = 0
        local lastVeh = nil
        local lastList = nil

        while #ghostGarages > 0 do
            local veh = GetVehiclePedIsIn(PlayerPedId(), false)
            local now = GetGameTimer()

            if nextRefresh <= now or veh ~= lastVeh or lastList ~= ghostGarages then
                nextRefresh = now + 300
                lastVeh = veh
                lastList = ghostGarages
                cache = Garage.GhostTargets(veh, ghostGarages)
            end

            if cache and #cache > 0 and veh ~= 0 then
                for i = 1, #cache do
                    local other = cache[i]
                    if DoesEntityExist(other) then
                        SetEntityNoCollisionEntity(veh, other, true)
                        SetEntityNoCollisionEntity(other, veh, true)
                    end
                end
                Wait(0)
            else
                Wait(250)
            end
        end

        ghostThreadRunning = false
    end)
end

--------------------------------------------------------------------------------
-- Main proximity loop
--------------------------------------------------------------------------------

CreateThread(function()
    while true do
        Wait(500)

        if #Garage.List > 0 then
            local coords = GetEntityCoords(PlayerPedId())
            local drawDistance = Config.Interaction.drawDistance or 60.0
            local near = {}

            for _, g in ipairs(Garage.List) do
                local reach = (g.zone and g.zone.reach) or g.storeRadius
                local limit = math.max(drawDistance, reach + 10.0)
                if distSq(coords, g.point) <= limit * limit then
                    near[#near + 1] = g
                end
            end

            nearbyGarages = near
            ghostGarages = filterGhost(near)
            updatePeds(coords)

            if #nearbyGarages > 0 then startPromptThread() end
            if #ghostGarages > 0 then startGhostThread() end
        end
    end
end)

--------------------------------------------------------------------------------
-- Nearest garage / spots
--------------------------------------------------------------------------------

function Garage.Nearest()
    local coords = GetEntityCoords(PlayerPedId())
    local best, bestDist = nil, math.huge

    for _, g in ipairs(Garage.List) do
        local d = #(coords - vector3(g.point.x, g.point.y, g.point.z))
        if bestDist > d then
            best, bestDist = g, d
        end
    end

    return best, bestDist
end

function Garage.OpenNearest()
    local g, d = Garage.Nearest()

    if not g or d > math.max(g.radius, 6.0) then
        return Client.Notify(_U("no_garage_here"), "error")
    end

    if not g.accessible then
        return Client.Notify(_U("no_access"), "error")
    end

    Garage.OpenMenu(g.id)
end

local function spotFree(spot)
    return not IsAnyVehicleNearPoint(spot.x, spot.y, spot.z, Config.Garage.spotClearRadius or 2.6)
end
Garage.SpotFree = spotFree

-- Boats spawn at the water surface instead of the stored spot z
function Garage.SpawnZ(model, spot)
    if model ~= 0 and GetVehicleClassFromName(model) == 14 then
        local probe = spot.z + 2.0
        local found, height = GetWaterHeightNoWaves(spot.x, spot.y, probe)
        if not found then
            found, height = GetWaterHeight(spot.x, spot.y, probe)
        end

        if found and type(height) == "number" and probe > height and height > spot.z - 30.0 then
            return height
        end
    end

    return spot.z
end

--------------------------------------------------------------------------------
-- Garage menu
--------------------------------------------------------------------------------

local function prepareMenu(data)
    for _, v in ipairs(data.vehicles or {}) do
        Garage.Enrich(v)
    end

    local spots = {}
    for i, s in ipairs(data.garage.spots or {}) do
        spots[i] = { index = i, x = s.x, y = s.y, z = s.z, w = s.w, free = spotFree(s) }
    end
    data.spots = spots
    data.vehicles = Utils.Arr(data.vehicles)

    if data.now then
        Client.Server.now = data.now
        Client.Server.at = GetGameTimer()
    end

    return data
end

function Garage.OpenMenu(id)
    if Garage.Open or Client.Busy() or busy then return end

    local g = Garage.ById[id]
    if not g then return end

    Framework.TriggerCallback("garage:open", function(res)
        if not res then return end

        if not res.ok then
            return Client.Notify(res.message or _U("no_access"), "error")
        end

        if Garage.Open or Client.Busy() then return end

        menuData = prepareMenu(res)
        Garage.Current = id
        Garage.Open = true

        Client.SetFocus("garage")
        nui("garage:open", menuData)
    end, id)
end

function Garage.Refresh(cb)
    if not (Garage.Open and Garage.Current) then return end

    Framework.TriggerCallback("garage:open", function(res)
        if not Garage.Open then return end

        if res and res.ok then
            menuData = prepareMenu(res)
            nui("garage:refresh", menuData)
        end

        if cb then cb(res) end
    end, Garage.Current)
end

function Garage.MenuVehicle(plate)
    for _, v in ipairs((menuData and menuData.vehicles) or {}) do
        if v.plate == plate then return v end
    end
    return nil
end

function Garage.Close()
    if not Garage.Open then return end

    if Preview and not Preview.HandingOff() then
        Preview.Stop(true)
    end

    Garage.Current = nil
    Garage.Open = false
    menuData = nil

    Client.ReleaseFocus("garage")
    nui("garage:close")
end

--------------------------------------------------------------------------------
-- Transitions (fade UI / animations)
--------------------------------------------------------------------------------

local function transitionsEnabled()
    return settings().transitions ~= false
end

local function fadeAlpha(entity, from, to, durationMs)
    if not DoesEntityExist(entity) then return end

    local steps = math.max(1, math.floor(durationMs / 40))
    for i = 1, steps do
        if not DoesEntityExist(entity) then return end
        SetEntityAlpha(entity, math.floor(from + (to - from) * (i / steps)), false)
        Wait(40)
    end
end

-- Default spot for the player after parking: just behind the vehicle
local function defaultStoreExit(veh)
    local offset = GetOffsetFromEntityInWorldCoords(veh, -2.3, 0.4, 0.0)
    local found, groundZ = GetGroundZFor_3dCoord(offset.x, offset.y, offset.z + 1.5, false)
    return vector3(offset.x, offset.y, found and (groundZ + 0.05) or offset.z)
end

-- Returns (position, heading, useFade). With `returnToAttendant` the player
-- is placed in front of the attendant ped instead.
function Garage.StoreExit(veh, g, category)
    local cfg = Config.Garage.returnToAttendant

    if type(cfg) == "table" and cfg[category] and g and g.point then
        local p = g.point
        local heading = tonumber(p.w) or 0.0
        local offset = (g.ped and g.ped.enabled and Config.Peds.enabled ~= false) and 1.4 or 0.0
        local rad = math.rad(heading)

        local x = p.x - math.sin(rad) * offset
        local y = p.y + math.cos(rad) * offset

        local found, groundZ = GetGroundZFor_3dCoord(x, y, p.z + 1.5, false)
        local z
        if found and groundZ and groundZ > p.z - 4.0 then
            z = groundZ + 0.05
        else
            z = p.z - 0.98
        end

        return vector3(x, y, z), (heading + 180.0) % 360.0, true
    end

    return defaultStoreExit(veh), nil, false
end

local function placePlayer(ped, pos, heading, fade)
    if fade then
        DoScreenFadeOut(180)
        local started = GetGameTimer()
        while not IsScreenFadedOut() and (GetGameTimer() - started) < 400 do
            Wait(0)
        end
    end

    local ok, err = pcall(function()
        SetEntityCoords(ped, pos.x, pos.y, pos.z, false, false, false, false)
        if heading then SetEntityHeading(ped, heading) end

        if fade then
            RequestCollisionAtCoord(pos.x, pos.y, pos.z)
            local started = GetGameTimer()
            while not HasCollisionLoadedAroundEntity(ped) and (GetGameTimer() - started) < 1500 do
                Wait(0)
            end
        end
    end)

    if fade then DoScreenFadeIn(260) end

    if not ok then
        print(("[%s] placing the player after parking failed: %s"):format(RESOURCE, tostring(err)))
    end
end

local function storeAnimation(veh, data, g)
    local ped = PlayerPedId()
    local summary = {
        label = data.label,
        plate = data.plate,
        image = data.image,
        class = data.class,
        category = data.category,
        color = data.color,
    }

    local exitPos, exitHeading, exitFade = Garage.StoreExit(veh, g, data.category)

    if transitionsEnabled() then
        nui("transition", {
            kind = "store",
            step = 1,
            vehicle = summary,
            garage = g.label,
            title = _U("ui_tr_store_title"),
            steps = { _U("ui_tr_store_1"), _U("ui_tr_store_2"), _U("ui_tr_store_3") },
        })

        FreezeEntityPosition(veh, true)
        SetVehicleEngineOn(veh, false, true, true)
        SetVehicleDoorsLocked(veh, 2)
        Wait(120)

        nui("transition", { kind = "store", step = 2 })
        SetEntityVisible(ped, false, false)
        fadeAlpha(veh, 255, 0, 420)
        placePlayer(ped, exitPos, exitHeading, exitFade)
        SetEntityVisible(ped, true, false)
        nui("transition", { kind = "store", step = 3 })
    else
        placePlayer(ped, exitPos, exitHeading, exitFade)
    end

    if DoesEntityExist(veh) then
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
    end

    if transitionsEnabled() then
        nui("transition", {
            kind = "store",
            done = true,
            message = _U("ui_tr_done_store", data.garageLabel or g.label),
        })
        Wait(900)
        nui("transition", { kind = "store", hide = true })
    end

    Client.Notify(_U("stored_ok", data.label or data.plate, data.garageLabel or g.label), "success")
end

--------------------------------------------------------------------------------
-- Store
--------------------------------------------------------------------------------

function Garage.Store(g)
    local ped = PlayerPedId()

    if not IsPedInAnyVehicle(ped, false) then
        return Client.Notify(_U("not_in_vehicle"), "error")
    end

    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then
        return Client.Notify(_U("not_driver"), "error")
    end

    if busy then return end

    local props = Props.Get(veh)
    if not props then return end

    local category = Utils.CategoryFromClass(GetVehicleClass(veh))
    local netId = NetworkGetNetworkIdFromEntity(veh)
    local model = GetEntityModel(veh)
    local modelLabel = Props.Label(model)

    busy = true

    Framework.TriggerCallback("garage:store", function(res)
        if not res then
            busy = false
            return Client.Notify(_U("store_failed"), "error")
        end

        if res.busy then
            busy = false
            return
        end

        if not res.ok then
            busy = false
            return Client.Notify(res.message or _U("store_failed"), "error")
        end

        res.image = Props.ImageName(model)
        res.class = GetVehicleClassFromName(model)
        res.category = category
        res.color = props.color1
        res.label = res.label or modelLabel

        CreateThread(function()
            storeAnimation(veh, res, g)
            busy = false
            TriggerEvent(RESOURCE .. ":client:vehicleStored", res.key, g.id)
        end)
    end, g.id, netId, props, category, modelLabel)
end

--------------------------------------------------------------------------------
-- Spawning vehicles (take out / release)
--------------------------------------------------------------------------------

-- Returns spotIndex, or nil + error key
function Garage.PickSpot(g, requested)
    local n = tonumber(requested) or 0

    if n > 0 then
        local spot = g.spots[n]
        if not spot or not spotFree(spot) then
            return nil, "spot_occupied"
        end
        return n
    end

    for i, spot in ipairs(g.spots) do
        if spotFree(spot) then return i end
    end

    return nil, "no_free_spot"
end

function Garage.LoadModel(model)
    if not (IsModelInCdimage(model) and IsModelAVehicle(model)) then
        return false
    end

    RequestModel(model)
    local started = GetGameTimer()
    while not HasModelLoaded(model) and (GetGameTimer() - started) < 10000 do
        Wait(25)
    end

    return HasModelLoaded(model)
end

-- v: vehicle record from server (props, plate, spot, key, ...)
-- mode: "out" | "release"
-- opts: { seamless, z, onDone(ok), beforeWarp(veh) }
function Garage.Spawn(v, mode, garageLabel, opts)
    mode = mode or "out"
    opts = opts or {}

    local model = tonumber(v.props and v.props.model) or 0

    if v.label == "" and model ~= 0 then
        v.label = Props.Label(model)
    end

    local animate = transitionsEnabled() and not opts.seamless

    local function finish(ok)
        if opts.onDone then opts.onDone(ok) end
    end

    local function hideTransition()
        if animate then nui("transition", { kind = mode, hide = true }) end
    end

    local summary = {
        label = v.label,
        plate = v.plate,
        image = Props.ImageName(model),
        class = (model ~= 0 and GetVehicleClassFromName(model)) or 0,
        color = v.props and v.props.color1,
    }

    if animate then
        nui("transition", {
            kind = mode,
            step = 1,
            vehicle = summary,
            garage = garageLabel,
            title = _U(mode == "release" and "ui_tr_release_title" or "ui_tr_out_title"),
            steps = {
                _U("ui_tr_out_1"),
                _U("ui_tr_out_2"),
                _U("ui_tr_out_3", v.spotIndex or 1),
            },
        })
    end

    if model == 0 or not Garage.LoadModel(model) then
        TriggerServerEvent(RESOURCE .. ":sv:spawnFailed", v.key)
        hideTransition()
        finish(false)
        return Client.Notify(_U("model_invalid"), "error")
    end

    if animate then nui("transition", { kind = mode, step = 2 }) end

    local spot = v.spot
    local isBoat = GetVehicleClassFromName(model) == 14

    local veh = CreateVehicle(model, spot.x, spot.y, opts.z or Garage.SpawnZ(model, spot), spot.w, true, false)

    local started = GetGameTimer()
    while not DoesEntityExist(veh) and (GetGameTimer() - started) < 5000 do
        Wait(10)
    end

    SetModelAsNoLongerNeeded(model)

    if not DoesEntityExist(veh) then
        TriggerServerEvent(RESOURCE .. ":sv:spawnFailed", v.key)
        hideTransition()
        finish(false)
        return Client.Notify(_U("spawn_failed"), "error")
    end

    SetEntityAsMissionEntity(veh, true, true)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    SetNetworkIdCanMigrate(netId, true)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehRadioStation(veh, "OFF")

    Props.Set(veh, v.props)
    SetVehicleNumberPlateText(veh, v.plate)

    if not isBoat then SetVehicleOnGroundProperly(veh) end

    SetVehicleDoorsLocked(veh, 1)
    Keys.Give(veh)
    TriggerServerEvent(RESOURCE .. ":sv:spawned", v.key, netId)

    if animate then
        SetEntityAlpha(veh, 0, false)
        if not isBoat then FreezeEntityPosition(veh, true) end

        nui("transition", { kind = mode, step = 3 })
        fadeAlpha(veh, 0, 255, 480)
        ResetEntityAlpha(veh)

        if not isBoat then FreezeEntityPosition(veh, false) end
    end

    local granted = Keys.WaitForGrant(veh, 12000)

    -- Make sure the entity is still the one we spawned
    local valid = DoesEntityExist(veh)
        and NetworkGetNetworkIdFromEntity(veh) == netId
        and GetEntityModel(veh) == model
        and Utils.PlateKey(GetVehicleNumberPlateText(veh)) == Utils.PlateKey(v.plate)

    if not valid then
        hideTransition()
        finish(false)
        return Client.Notify(_U("spawn_failed"), "error")
    end

    if not granted then
        Client.Notify(_U("vehicle_keys_failed"), "warning")
    end

    if opts.beforeWarp then opts.beforeWarp(veh) end

    if v.putIn or opts.seamless then
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    end

    SetVehicleEngineOn(veh, granted, true, false)
    TriggerEvent(RESOURCE .. ":client:vehicleOut", v.key, veh)
    finish(true)

    if animate then
        local message
        if mode == "release" then
            message = _U("ui_tr_done_release", garageLabel or "")
        else
            message = _U("ui_tr_done_out", v.spotIndex or 1)
        end

        nui("transition", { kind = mode, done = true, message = message })
        Wait(900)
        nui("transition", { kind = mode, hide = true })
    end

    Client.Notify(_U("takeout_ok", v.label or v.plate, v.spotIndex or 1), "success")
end

function Garage.TakeOut(plate, requestedSpot, opts)
    opts = opts or {}

    local function fail(message)
        if opts.onDone then opts.onDone(false) end
        if message then Client.Notify(message, "error") end
    end

    if not Garage.Open or busy then
        return fail(nil)
    end

    local g = Garage.ById[Garage.Current]
    if not g then return fail(nil) end

    local spot, err
    if opts.spot then
        spot = opts.spot
    else
        spot, err = Garage.PickSpot(g, requestedSpot)
    end

    if not spot then
        return fail(_U(err))
    end

    local vehicle = Garage.MenuVehicle(plate)
    busy = true

    local function handler(res)
        if not res then
            busy = false
            return fail(nil)
        end

        if not res.ok then
            busy = false
            return fail(res.message or _U("store_failed"))
        end

        Garage.Close()

        CreateThread(function()
            Garage.Spawn(res, "out", g.label, opts)
            busy = false
        end)
    end

    if vehicle and vehicle.fleet then
        return Framework.TriggerCallback("garage:fleetTakeout", handler, g.id, vehicle.fleet.index, spot)
    end

    Framework.TriggerCallback("garage:takeout", handler, g.id, plate, spot, vehicle and vehicle.category or nil)
end

function Garage.Release(plate, requestedSpot, account, opts)
    opts = opts or {}

    local function fail(message)
        if opts.onDone then opts.onDone(false) end
        if message then Client.Notify(message, "error") end
    end

    if not Garage.Open or busy then
        return fail(nil)
    end

    local g = Garage.ById[Garage.Current]
    if not (g and g.kind == "impound") then
        return fail(nil)
    end

    local spot, err
    if opts.spot then
        spot = opts.spot
    else
        spot, err = Garage.PickSpot(g, requestedSpot)
    end

    if not (spot and g.spots[spot]) then
        return fail(_U(err or "spot_occupied"))
    end

    busy = true

    Framework.TriggerCallback("garage:release", function(res)
        if not res then
            busy = false
            return fail(nil)
        end

        if not res.ok then
            busy = false
            return fail(res.message or _U("store_failed"))
        end

        Garage.Close()

        CreateThread(function()
            Garage.Spawn(res, "release", g.label, opts)
            busy = false
        end)
    end, g.id, plate, spot, account)
end

--------------------------------------------------------------------------------
-- NUI callbacks: garage menu
--------------------------------------------------------------------------------

RegisterNUICallback("garage:close", function(_, cb)
    Garage.Close()
    cb(1)
end)

RegisterNUICallback("garage:refresh", function(_, cb)
    Garage.Refresh()
    cb(1)
end)

RegisterNUICallback("garage:takeout", function(data, cb)
    cb(1)
    if data and data.plate then
        Garage.TakeOut(data.plate, data.spot)
    end
end)

RegisterNUICallback("garage:release", function(data, cb)
    cb(1)
    if data and data.plate then
        Garage.Release(data.plate, data.spot, data.account)
    end
end)

-- Generic "call server, notify, refresh menu" NUI action.
-- buildArgs(data) returns the argument list passed to the server callback.
local function registerAction(name, buildArgs)
    RegisterNUICallback(name, function(data, cb)
        if not (Garage.Open and Garage.Current) then
            return cb({ ok = false })
        end

        local args = buildArgs(data or {})

        Framework.TriggerCallback(name, function(res)
            if res and res.ok then
                if res.message then Client.Notify(res.message, "success") end
                Garage.Refresh()
            elseif res then
                Client.Notify(res.message or _U("store_failed"), "error")
            end

            cb(res or { ok = false })
        end, table.unpack(args))
    end)
end

local function plateAccountArgs(d)
    return { Garage.Current, d.plate, d.account or "bank" }
end

registerAction("garage:retrieve", plateAccountArgs)
registerAction("garage:transfer", plateAccountArgs)

--------------------------------------------------------------------------------
-- Locate vehicle
--------------------------------------------------------------------------------

local LOCATE_SPRITES = { car = 225, motorcycle = 226, boat = 427, air = 423 }

local function locationLabel(x, y, z)
    local street, crossing = GetStreetNameAtCoord(x, y, z)

    local name = (street and street ~= 0) and GetStreetNameFromHashKey(street) or nil
    if (not name or name == "") and crossing and crossing ~= 0 then
        name = GetStreetNameFromHashKey(crossing)
    end
    if name == "" then name = nil end

    local zone = GetLabelText(GetNameOfZone(x, y, z))
    if not zone or zone == "" or zone == "NULL" then zone = nil end

    if name and zone then return name .. ", " .. zone end
    if name or zone then return name or zone end
    return ("%.0f, %.0f"):format(x, y)
end

local function setLocateBlip(x, y, z, category, label)
    if locateBlip and DoesBlipExist(locateBlip) then
        RemoveBlip(locateBlip)
    end

    local blip = AddBlipForCoord(x + 0.0, y + 0.0, z + 0.0)
    SetBlipSprite(blip, LOCATE_SPRITES[category] or 225)
    SetBlipColour(blip, 3)
    SetBlipScale(blip, 0.95)
    SetBlipAsShortRange(blip, false)
    SetBlipFlashes(blip, true)
    SetBlipFlashTimer(blip, 8000)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(_U("locate_blip", label))
    EndTextCommandSetBlipName(blip)

    locateBlip = blip

    local seconds = tonumber(Config.Garage.locateBlipSeconds) or 120
    SetTimeout(math.floor(seconds * 1000), function()
        if locateBlip == blip then
            if DoesBlipExist(blip) then RemoveBlip(blip) end
            locateBlip = nil
        end
    end)
end

RegisterNUICallback("garage:locate", function(data, cb)
    if not (Garage.Open and type(data) == "table" and data.plate) then
        return cb({ ok = false })
    end

    Framework.TriggerCallback("garage:locate", function(res)
        if not res then
            return cb({ ok = false })
        end

        if not res.ok then
            Client.Notify(res.message or _U("store_failed"), "error")
            return cb(res)
        end

        local label = res.label or data.plate

        if res.kind == "lost" or not res.x then
            Client.Notify(_U("locate_lost", label), "error")
            return cb({ ok = true, kind = "lost" })
        end

        local where = locationLabel(res.x, res.y, res.z)
        SetNewWaypoint(res.x + 0.0, res.y + 0.0)

        if res.kind == "world" or res.kind == "parked" then
            setLocateBlip(res.x, res.y, res.z, data.category, label)
        end

        local message
        if res.kind == "garage" then
            message = _U("locate_garage", label, res.place or where)
        elseif res.kind == "impound" then
            message = _U("locate_impound", label, res.place or where)
        elseif res.live then
            message = _U("locate_world", label, where)
        else
            message = _U("locate_seen", label, where)
        end

        Client.Notify(message, "info")

        local playerPos = GetEntityCoords(PlayerPedId())
        cb({
            ok = true,
            kind = res.kind,
            where = where,
            place = res.place,
            distance = math.floor(#(playerPos - vector3(res.x, res.y, res.z)) + 0.5),
            live = res.live == true,
            driven = res.driven == true,
            seenAt = res.seenAt,
            now = res.now,
        })
    end, data.plate)
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() and locateBlip and DoesBlipExist(locateBlip) then
        RemoveBlip(locateBlip)
    end
end)

--------------------------------------------------------------------------------
-- NUI callbacks: rename / cancel contract
--------------------------------------------------------------------------------

RegisterNUICallback("garage:rename", function(data, cb)
    Framework.TriggerCallback("garage:rename", function(res)
        if res and res.ok then
            Garage.Refresh()
        elseif res then
            Client.Notify(res.message, "error")
        end
        cb(res or { ok = false })
    end, data and data.plate, data and data.nickname)
end)

RegisterNUICallback("garage:cancelContract", function(data, cb)
    Framework.TriggerCallback("contract:cancel", function(res)
        if res and res.ok then
            Client.Notify(res.message, "success")
            Garage.Refresh()
        elseif res then
            Client.Notify(res.message, "error")
        end
        cb(res or { ok = false })
    end, data and data.plate)
end)

--------------------------------------------------------------------------------
-- Impound tool
--------------------------------------------------------------------------------

function Garage.OpenImpoundTool()
    if impoundToolOpen or Client.Busy() then return end

    Framework.TriggerCallback("garage:impoundTool", function(res)
        if not (res and res.ok) then
            return Client.Notify((res and res.message) or _U("no_permission"), "error")
        end

        if impoundToolOpen or Client.Busy() then return end

        local coords = GetEntityCoords(PlayerPedId())
        local radius = Config.Impound.toolRadius or 30.0
        local vehicles = {}

        for _, veh in ipairs(GetGamePool("CVehicle")) do
            local d = #(GetEntityCoords(veh) - coords)
            if radius >= d then
                local model = GetEntityModel(veh)
                local color = GetVehicleColours(veh)

                vehicles[#vehicles + 1] = {
                    netId = NetworkGetNetworkIdFromEntity(veh),
                    plate = GetVehicleNumberPlateText(veh) or "",
                    label = Props.Label(model),
                    image = Props.ImageName(model),
                    class = GetVehicleClass(veh),
                    color = color,
                    distance = Utils.Round(d, 1),
                    occupied = GetPedInVehicleSeat(veh, -1) ~= 0,
                    parked = Entity(veh).state.oxlynParked and true or false,
                }
            end
        end

        table.sort(vehicles, function(a, b) return a.distance < b.distance end)

        local lots = res.lots or {}
        for _, lot in ipairs(lots) do
            lot.distance = Utils.Round(#(coords - vector3(lot.x, lot.y, lot.z)), 0)
        end
        table.sort(lots, function(a, b) return a.distance < b.distance end)

        impoundToolOpen = true
        Client.SetFocus("impoundtool")
        nui("impound:tool", {
            vehicles = vehicles,
            lots = res.lots or {},
            fee = res.fee,
            maxFee = res.maxFee,
            reasons = res.reasons or {},
            reason = res.reason or "",
        })
    end)
end

function Garage.CloseImpoundTool()
    if not impoundToolOpen then return end

    impoundToolOpen = false
    Client.ReleaseFocus("impoundtool")
    nui("impound:toolClose")
end

RegisterNUICallback("impound:close", function(_, cb)
    Garage.CloseImpoundTool()
    cb(1)
end)

RegisterNUICallback("impound:send", function(data, cb)
    cb(1)

    if not (impoundToolOpen and data and data.netId) then return end

    Framework.TriggerCallback("garage:impound", function(res)
        Garage.CloseImpoundTool()
        if not res then return end

        Client.Notify(res.message or _U("impound_no_vehicle"), res.ok and "success" or "error")
    end, tonumber(data.netId), tonumber(data.fee), data.reason, data.lot)
end)

--------------------------------------------------------------------------------
-- Commands
--------------------------------------------------------------------------------

if Config.Commands.impound then
    RegisterCommand(Config.Commands.impound, function(_, args)
        if #args == 0 then
            return Garage.OpenImpoundTool()
        end

        CreateThread(function()
            local ped = PlayerPedId()
            local veh = 0

            if IsPedInAnyVehicle(ped, false) then
                veh = GetVehiclePedIsIn(ped, false)
            else
                local c = GetEntityCoords(ped)
                veh = GetClosestVehicle(c.x, c.y, c.z, Config.Impound.radius or 6.0, 0, 70)
            end

            if veh == 0 or not DoesEntityExist(veh) then
                return Client.Notify(_U("impound_no_vehicle"), "error")
            end

            -- /impound [fee] [reason...]   or   /impound [reason]
            local fee = tonumber(args[1])
            local reason = nil
            if #args > 1 then
                reason = table.concat(args, " ", 2)
            elseif #args == 1 and not fee then
                reason = args[1]
            end

            Framework.TriggerCallback("garage:impound", function(res)
                if not res then return end
                Client.Notify(res.message or _U("impound_no_vehicle"), res.ok and "success" or "error")
            end, NetworkGetNetworkIdFromEntity(veh), fee, reason)
        end)
    end, false)
end

if Config.Commands.admincar then
    RegisterCommand(Config.Commands.admincar, function()
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)

        if veh == 0 or not DoesEntityExist(veh) then
            return Client.Notify(_U("admincar_not_in_vehicle"), "error")
        end

        if not NetworkGetEntityIsNetworked(veh) then
            return Client.Notify(_U("admincar_local"), "error")
        end

        local model = GetEntityModel(veh)
        local props = Props.Get(veh) or {}
        local category = Utils.CategoryFromClass(GetVehicleClass(veh))
        local spawnName = (GetDisplayNameFromVehicleModel(model) or ""):lower()

        Framework.TriggerCallback("admin:claimVehicle", function(res)
            if not res then return end

            if res.ok then
                if res.plate and Utils.Trim(GetVehicleNumberPlateText(veh) or "") ~= res.plate then
                    SetVehicleNumberPlateText(veh, res.plate)
                end
                Keys.Give(veh)
            end

            Client.Notify(res.message or _U("store_failed"), res.ok and "success" or "error")
        end, NetworkGetNetworkIdFromEntity(veh), props, category, spawnName, Props.Label(model))
    end, false)
end

--------------------------------------------------------------------------------
-- Cleanup
--------------------------------------------------------------------------------

function Garage.Cleanup()
    for _, blip in pairs(blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end

    Garage.DespawnPeds()
    removeTargetZones()
end

