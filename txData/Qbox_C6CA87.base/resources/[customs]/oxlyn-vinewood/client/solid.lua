

-- Vinewood solid (3D object) letters (cleaned from decompiled output)
--
-- "Solid" text layers are built from real 3D letter models. This module lays them out
-- (VinewoodLayout), decides which ones are close enough to matter, streams their models,
-- spawns/updates/deletes the objects, and keeps their transforms from drifting.

VinewoodSolid = {
    MaterialEffectsAvailable = false,
    ColorAvailable           = true,
}
local M = VinewoodSolid

local Math   = VinewoodMath
local Layout = VinewoodLayout

---------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------
local MODEL_RETRY_MISSING_MS = 30000  -- retry delay when a model isn't in the game files
local MODEL_RETRY_TIMEOUT_MS = 15000  -- retry delay after a load timeout
local MODEL_REQUEST_INTERVAL = 500    -- re-issue RequestModel this often while loading
local DRIFT_EPSILON          = 1.0E-4 -- squared matrix drift that triggers a repair
local OBJECT_LOD_EXTRA       = 400    -- added to DrawDistance for object LOD distance
local LAYER_RANGE_PADDING    = 60     -- extra range around wide layers

---------------------------------------------------------------------
-- State
---------------------------------------------------------------------
local scene          = { layers = {} }
local layouts        = {}   -- [layerId]  = list of glyph specs (from Layout.Build)
local wantedByKey    = {}   -- [spec.key] = spec   (everything that should exist right now)
local wantedList     = {}   -- same specs as an ordered list
local objects        = {}   -- [spec.key] = { entity, model, spec, lastWanted, matrix, repairs }
local modelState     = {}   -- [modelHash] = { requested, deadline, nextRequestAt, retryAt }
local warned         = {}   -- [name] = true once a warning was shown
local stopped        = false
local generation     = 0    -- bumped on every update; lets the spawn loop notice stale work
local lastNight      = nil
local colorReady     = false
local lastSnapshot   = nil  -- last solid-layer snapshot (to skip no-op SetScene calls)
local slotByLayer    = {}   -- [layerId] = colour bank slot (1..MaxSolidLayers)
local spawnPending   = false
local repairQueue    = {}   -- [obj] = true for objects whose matrix keeps getting reset

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
local function deepEqual(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end

    for k, v in pairs(a) do
        if not deepEqual(v, b[k]) then return false end
    end
    for k in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

local function isNight()
    return GetClockHours() >= Config.Solid.NightStart
end

-- Print a console warning (and toast in the editor) once per `key`
local function warnOnce(key, consoleMessage, uiMessage)
    if warned[key] then return end
    warned[key] = true

    print("^3[oxlyn-vinewood]^7 " .. consoleMessage)

    if VinewoodEditor and VinewoodEditor.Active then
        SendNUIMessage({ action = "toast", message = uiMessage or consoleMessage, kind = "error" })
    end
end

-- Subset of a layer's fields that affects solid layout; used to detect real changes
local function snapshotSolidLayers(layers)
    local out = {}
    for _, layer in ipairs(layers) do
        if layer.type == "text" and layer.renderMode == "solid" then
            out[#out + 1] = {
                id              = layer.id,
                text            = layer.text,
                font            = layer.font,
                position        = layer.position,
                rotation        = layer.rotation,
                width           = layer.width,
                height          = layer.height,
                depth           = layer.depth,
                tracking        = layer.tracking,
                opacity         = layer.opacity,
                visible         = layer.visible,
                lighting        = layer.lighting,
                supports        = layer.supports,
                supportDrop     = layer.supportDrop,
                letterOverrides = layer.letterOverrides,
            }
        end
    end
    return out
end

-- Give every solid layer a stable colour-bank slot (first free slot), drop stale ones
local function assignSlots()
    local solidIds = {}
    local usedSlots = {}

    for _, layer in ipairs(scene.layers) do
        if layer.type == "text" and layer.renderMode == "solid" then
            solidIds[layer.id] = true
        end
    end

    for id, slot in pairs(slotByLayer) do
        if solidIds[id] then
            usedSlots[slot] = true
        else
            slotByLayer[id] = nil
        end
    end

    for _, layer in ipairs(scene.layers) do
        if solidIds[layer.id] and not slotByLayer[layer.id] then
            for slot = 1, Config.Limits.MaxSolidLayers do
                if not usedSlots[slot] then
                    slotByLayer[layer.id] = slot
                    usedSlots[slot] = true
                    break
                end
            end
        end
    end

    VinewoodSolidColor.SetLayers(scene.layers, slotByLayer)
end

local function ensureColor()
    colorReady = VinewoodSolidColor.Ensure()
end

---------------------------------------------------------------------
-- Object transforms
---------------------------------------------------------------------
local function applyMatrix(obj)
    local m = obj.matrix
    if m and DoesEntityExist(obj.entity) then
        SetEntityMatrix(obj.entity, table.unpack(m))
    end
end

local function deleteObject(obj)
    if not obj then return end

    repairQueue[obj] = nil
    if obj.entity and DoesEntityExist(obj.entity) then
        DeleteEntity(obj.entity)
    end
end

-- Position/scale/fade an existing object to match `spec`
local function applySpec(obj, spec)
    if not DoesEntityExist(obj.entity) then return end
    local entity = obj.entity

    local forward = Math.mul(spec.forward, spec.scaleY)
    local right   = Math.mul(spec.right,   spec.scaleX)
    local up      = Math.mul(spec.up,      spec.scaleZ)

    obj.matrix = {
        forward.x, forward.y, forward.z,
        right.x,   right.y,   right.z,
        up.x,      up.y,      up.z,
        spec.origin.x, spec.origin.y, spec.origin.z,
    }
    applyMatrix(obj)

    SetEntityAlpha(entity, math.floor(spec.opacity * 255), false)

    obj.spec = spec
    obj.lastWanted = GetGameTimer()
end

---------------------------------------------------------------------
-- Support posts (optional pole under a letter)
---------------------------------------------------------------------
local function buildSupport(glyph)
    local support = VinewoodGlyphs.support
    if not (support and glyph.layer.supports) then
        return nil
    end

    local minZ      = support.minZ or 0
    local modelH    = support.height or 1
    local totalH    = glyph.height + glyph.layer.supportDrop
    local scaleZ    = totalH / modelH

    -- bottom of the post sits supportDrop below the letter
    local base = Math.sub(glyph.center,
        Math.mul(glyph.up, glyph.height / 2 + glyph.layer.supportDrop))
    local origin = Math.sub(base, Math.mul(glyph.up, minZ * scaleZ))

    -- push it slightly behind the letter
    origin = Math.add(origin,
        Math.mul(glyph.forward, (glyph.scaleY * (VinewoodGlyphs.depth or 0.1)) / 2 + 0.4))

    return {
        key      = glyph.key .. ":support",
        layerId  = glyph.layerId,
        index    = glyph.index,
        slot     = glyph.slot,
        model    = support.model,
        origin   = origin,
        center   = glyph.center,
        right    = glyph.right,
        forward  = glyph.forward,
        up       = glyph.up,
        width    = glyph.width,
        height   = totalH,
        scaleX   = math.max(0.4, glyph.width * 0.83) / (support.width or 1),
        scaleY   = 1,
        scaleZ   = scaleZ,
        opacity  = glyph.opacity,
        visible  = glyph.visible,
        layer    = glyph.layer,
        isSupport = true,
    }
end

-- Does this spec still need an object spawned (none yet, wrong model, or entity gone)?
-- NOTE: the model comparison was lost in the decompile; this is the inferred intent.
local function needsSpawn(spec)
    local obj = objects[spec.key]
    return not obj
        or obj.model ~= spec.model
        or not DoesEntityExist(obj.entity)
end

---------------------------------------------------------------------
-- Model streaming
---------------------------------------------------------------------
local function releaseModel(hash)
    local state = modelState[hash]
    if state and state.requested then
        SetModelAsNoLongerNeeded(hash)
    end
    modelState[hash] = nil
end

-- Release every model not in `needed` ([hash] = true)
local function releaseUnneededModels(needed)
    for hash in pairs(modelState) do
        if not needed[hash] then
            releaseModel(hash)
        end
    end
end

-- Drive loading of one model. Returns true once it is loaded.
local function ensureModel(hash, name, now)
    -- the font's IPL bank must be streamed in first
    if VinewoodFontStreaming and not VinewoodFontStreaming.Ready(name, now) then
        return false
    end

    local state = modelState[hash]
    if state and state.retryAt and now < state.retryAt then
        return false
    end

    -- (re)start loading
    if not state or state.retryAt then
        if not (IsModelInCdimage(hash) and IsModelValid(hash)) then
            warnOnce(name,
                "3D model unavailable: " .. name .. ". Restart the resource after installing its stream files.",
                (L("solid_model_unavailable", { model = name })))
            modelState[hash] = { retryAt = now + MODEL_RETRY_MISSING_MS }
            return false
        end

        RequestModel(hash)
        state = {
            requested     = true,
            deadline      = now + Config.Solid.LoadTimeout,
            nextRequestAt = now + MODEL_REQUEST_INTERVAL,
        }
        modelState[hash] = state
    end

    if HasModelLoaded(hash) then
        state.deadline = nil
        return true
    end

    state.deadline = state.deadline or (now + Config.Solid.LoadTimeout)

    if now >= state.deadline then
        warnOnce(name,
            "Model loading timed out: " .. name .. ". Check the resource stream files.",
            (L("solid_model_timeout", { model = name })))
        releaseModel(hash)
        modelState[hash] = { retryAt = now + MODEL_RETRY_TIMEOUT_MS }
        return false
    end

    if now >= state.nextRequestAt then
        RequestModel(hash)
        state.nextRequestAt = now + MODEL_REQUEST_INTERVAL
        if HasModelLoaded(hash) then
            state.deadline = nil
            return true
        end
    end

    return false
end

---------------------------------------------------------------------
-- Main update: decide what should exist, update/delete what does
---------------------------------------------------------------------
local function update(force)
    if stopped then return end

    local night = isNight()

    -- rebuild glyph layouts when forced or when day/night flipped (lighting variants)
    if force or lastNight ~= night then
        layouts = {}

        for _, layer in ipairs(scene.layers) do
            local slot = slotByLayer[layer.id]
            if layer.type == "text" and layer.renderMode == "solid" and slot then
                layouts[layer.id] = Layout.Build(layer, slot, night)

                for _, glyph in ipairs(layouts[layer.id]) do
                    glyph.hash    = GetHashKey(glyph.model)
                    glyph.support = buildSupport(glyph)
                    if glyph.support then
                        glyph.support.hash = GetHashKey(glyph.support.model)
                    end
                end
            end
        end

        lastNight = night
    end

    -- collect glyphs of nearby, visible layers
    local camPos = GetFinalRenderedCamCoord()
    local byKey, list = {}, {}
    local now = GetGameTimer()

    for _, layer in ipairs(scene.layers) do
        local glyphs = layouts[layer.id]
        if glyphs and layer.visible and layer.opacity > 0 then
            local range = Config.DrawDistance + layer.width + LAYER_RANGE_PADDING
            if Math.distance2(camPos, layer.position) < range ^ 2 then
                for _, glyph in ipairs(glyphs) do
                    byKey[glyph.key] = glyph
                    list[#list + 1] = glyph

                    local support = glyph.support
                    if support then
                        byKey[support.key] = support
                        list[#list + 1] = support
                    end
                end
            end
        end
    end

    wantedByKey = byKey
    wantedList  = list
    generation  = generation + 1

    -- update or retire existing objects
    for key, obj in pairs(objects) do
        local wanted = byKey[key]

        if wanted then
            if wanted.model == obj.model then
                if force or obj.spec ~= wanted then
                    applySpec(obj, wanted)
                else
                    obj.lastWanted = now
                end
            end
            -- (model changed: left alone; the spawn loop replaces it)
        else
            -- not wanted right now: is its layer still alive?
            local layerStillSolid = false
            for _, layer in ipairs(scene.layers) do
                if layer.id == obj.spec.layerId
                    and layer.visible and layer.opacity > 0
                    and layer.renderMode == "solid"
                    and not (obj.spec.isSupport and not layer.supports) then
                    layerStillSolid = true
                    break
                end
            end

            -- keep briefly (just out of range) to avoid churn
            local keep = not force and layerStillSolid
                and (now - obj.lastWanted) <= Config.Solid.ReleaseDelay

            if not keep then
                deleteObject(obj)
                objects[key] = nil
            end
        end
    end

    -- which models are needed for specs that still have to be spawned?
    local needed = {}
    for _, spec in ipairs(wantedList) do
        if needsSpawn(spec) then
            needed[spec.hash] = true
        end
    end
    spawnPending = next(needed) ~= nil
    releaseUnneededModels(needed)

    if VinewoodFontStreaming then
        VinewoodFontStreaming.Sync(wantedList, objects)
    end

    if #list > 0 then
        ensureColor()
    end
end

---------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------
function M.SetScene(newScene)
    if stopped then return end

    scene = newScene
    assignSlots()

    local snapshot = snapshotSolidLayers(newScene.layers)

    -- nothing relevant changed: just make sure colours are still bound
    if lastSnapshot and deepEqual(lastSnapshot, snapshot) then
        if #wantedList > 0 or next(objects) then
            ensureColor()
        end
        return
    end

    lastSnapshot = Math.copy(snapshot)
    update(true)
end

-- One letter's layout spec
function M.Glyph(layerId, index)
    for _, glyph in ipairs(layouts[layerId] or {}) do
        if glyph.index == index then
            return glyph
        end
    end
end

function M.Layout(layerId)
    return layouts[layerId] or {}
end

-- Ray-pick letters of a layer; returns the nearest glyph and its distance
function M.Hit(origin, dir, layerId)
    local best, bestDist = nil, math.huge

    for _, glyph in ipairs(layouts[layerId] or {}) do
        local d = Layout.Hit(origin, dir, glyph)
        if d and d < bestDist then
            best, bestDist = glyph, d
        end
    end

    return best, (best and bestDist) or nil
end

---------------------------------------------------------------------
-- Background loops
---------------------------------------------------------------------
-- Re-evaluate what should exist as the camera moves
CreateThread(function()
    while not stopped do
        update(false)
        Wait(Config.Solid.StreamInterval)
    end
end)

-- Spawn loop: loads models and creates objects within a per-iteration budget
CreateThread(function()
    while not stopped do
        local budget = Config.Solid.SpawnBudget
        local more = false

        if spawnPending then
            local session = generation

            if #wantedList > 0 and not colorReady then
                ensureColor()
            end

            -- specs that still need an object, grouped by model
            local pending, groups, ready = {}, {}, {}
            for _, spec in ipairs(wantedList) do
                if needsSpawn(spec) then
                    local hash = spec.hash
                    local group = groups[hash]
                    if not group then
                        group = { model = spec.model, count = 0 }
                        groups[hash] = group
                    end
                    group.count = group.count + 1
                    pending[#pending + 1] = { spec = spec, hash = hash }
                end
            end

            releaseUnneededModels(groups)

            local now = GetGameTimer()
            for hash, group in pairs(groups) do
                ready[hash] = ensureModel(hash, group.model, now)
            end

            for _, item in ipairs(pending) do
                if stopped or session ~= generation then break end

                local spec, hash = item.spec, item.hash

                if ready[hash] and budget > 0 and colorReady then
                    local o = spec.origin
                    local entity = CreateObjectNoOffset(hash, o.x + 0.0, o.y + 0.0, o.z + 0.0, false, false, false)

                    if entity and entity ~= 0 then
                        SetEntityAsMissionEntity(entity, true, true)
                        SetEntityDynamic(entity, false)
                        SetEntityCollision(entity, false, false)
                        FreezeEntityPosition(entity, true)
                        SetEntityInvincible(entity, true)
                        SetEntityLodDist(entity, math.floor(Config.DrawDistance + OBJECT_LOD_EXTRA))

                        local record = {
                            entity     = entity,
                            model      = spec.model,
                            spec       = spec,
                            lastWanted = now,
                        }
                        applySpec(record, spec)

                        deleteObject(objects[spec.key])   -- replace any stale object
                        objects[spec.key] = record

                        groups[hash].count = groups[hash].count - 1
                        budget = budget - 1
                    end
                end
            end

            -- release models with nothing left to spawn; remember if work remains
            if not stopped and session == generation then
                for hash, group in pairs(groups) do
                    if group.count == 0 then
                        releaseModel(hash)
                    else
                        more = true
                    end
                end
                spawnPending = more
            end
        end

        -- spent the whole budget -> go again immediately; work left -> soon; idle -> slowly
        Wait((budget == 0 and 0) or (more and 100) or 350)
    end
end)

-- Matrix watchdog: something (streaming, physics) can reset our transforms
CreateThread(function()
    while not stopped do
        Wait(Config.Solid.MatrixCheckInterval)
        if stopped then break end

        for _, obj in pairs(objects) do
            if DoesEntityExist(obj.entity) then
                -- NOTE: GetEntityMatrix's return order is (right, forward, up, ...) here,
                -- compared against the stored matrix slots [4..6], [1..3], [7..9].
                local a, b, c = GetEntityMatrix(obj.entity)
                local m = obj.matrix

                local function sq(v, i)
                    local dx, dy, dz = v.x - m[i], v.y - m[i + 1], v.z - m[i + 2]
                    return dx * dx + dy * dy + dz * dz
                end

                if sq(a, 4) > DRIFT_EPSILON or sq(b, 1) > DRIFT_EPSILON or sq(c, 7) > DRIFT_EPSILON then
                    obj.repairs = (obj.repairs or 0) + 1
                    applyMatrix(obj)

                    -- repeatedly drifting objects get re-applied every frame
                    if obj.repairs >= 2 then
                        repairQueue[obj] = true
                    end
                end
            end
        end
    end
end)

-- Per-frame re-apply for objects that keep drifting (only while still wanted)
CreateThread(function()
    while not stopped do
        local sleep = 500

        for obj in pairs(repairQueue) do
            if wantedByKey[obj.spec.key] then
                sleep = 0
                applyMatrix(obj)
            end
        end

        Wait(sleep)
    end
end)

---------------------------------------------------------------------
-- Cleanup
---------------------------------------------------------------------
function M.Stop()
    if stopped then return end
    stopped = true
    generation = generation + 1

    for _, obj in pairs(objects) do
        deleteObject(obj)
    end
    for hash in pairs(modelState) do
        releaseModel(hash)
    end

    if VinewoodFontStreaming then
        VinewoodFontStreaming.Stop()
    end
    VinewoodSolidColor.Stop()

    lastSnapshot = nil
    slotByLayer  = {}
    spawnPending = false
    repairQueue  = {}

    layouts, wantedByKey, wantedList, objects, modelState = {}, {}, {}, {}, {}
end

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        M.Stop()
    end
end)

