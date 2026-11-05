

-- Vinewood editor client (cleaned from decompiled output)

VinewoodEditor = {
    Active        = false,
    PreviewMotion = true,
}
local Editor = VinewoodEditor

local Math   = VinewoodMath
local Core   = Vinewood
local Render = VinewoodRender

---------------------------------------------------------------------
-- State
---------------------------------------------------------------------
local cam              = nil     -- main scripted camera
local ped              = nil
local pedWasFrozen     = false
local scene            = nil
local revision         = 0
local selectedId       = nil
local cursorMode       = true    -- true = mouse cursor / UI interaction, false = mouse-look
local selectedGlyph    = 0       -- 0 = whole layer, >0 = single letter
local toolMode         = "translate"
local toolAxis         = "x"
local snapStep         = 0.1
local drag             = nil     -- active gizmo/layer drag
local saving           = false
local saveDeadline     = 0
local lastTransformSend = 0
local viewportBottom   = 1.0     -- fraction of the screen not covered by UI panels
local transitionCam    = nil
local transitionStart  = 0
local transitionEnd    = 0
local orbit            = nil     -- right-mouse orbit state
local pan              = nil     -- middle-mouse pan state
local camSettings      = {}
local bookmarks        = {}      -- [1..3] saved cameras
local timePreview      = nil
local uiHidden         = false
local fovDirty         = false
local lastFovSend      = 0

local TIME_PRESETS = {
    day    = { 13, 0 },
    sunset = { 19, 40 },
    night  = { 0, 30 },
}

local moveKeys = { f = false, b = false, l = false, r = false, u = false, d = false, fast = false, slow = false }
local lookDelta = { x = 0.0, y = 0.0 }

local AXES = {
    x = { x = 1, y = 0, z = 0 },
    y = { x = 0, y = 1, z = 0 },
    z = { x = 0, y = 0, z = 1 },
}

local AXIS_COLORS = {
    x = { 240, 80, 95 },
    y = { 61, 220, 151 },
    z = { 111, 168, 255 },
}

local VIEW_PRESETS = {
    home = true, front = true, back = true, left = true,
    right = true, side = true, top = true, iso = true,
}

---------------------------------------------------------------------
-- Small helpers
---------------------------------------------------------------------
local function resetInput()
    for k in pairs(moveKeys) do moveKeys[k] = false end
    lookDelta.x, lookDelta.y = 0.0, 0.0
end

function Editor.MotionPaused()
    return not Editor.PreviewMotion
end

local function isFiniteNumber(v)
    return type(v) == "number" and v == v
end

local function wrap180(a)
    return ((a + 180) % 360) - 180
end

local function snap(v)
    if snapStep > 0 then
        return math.floor(v / snapStep + 0.5) * snapStep
    end
    return v
end

local function activeCam()
    return transitionCam or cam
end

local function vec3(v)
    return { x = v.x, y = v.y, z = v.z }
end

local function camPos()        return vec3(GetCamCoord(cam)) end
local function camRot()        return vec3(GetCamRot(cam, 2)) end
local function finalCamPos()   return vec3(GetFinalRenderedCamCoord()) end
local function finalCamRot()   return vec3(GetFinalRenderedCamRot(2)) end

local function resourceVersion()
    return GetResourceMetadata(GetCurrentResourceName(), "version", 0) or "2.5.0"
end

local function findLayer(id)
    if scene then
        for _, layer in ipairs(scene.layers) do
            if layer.id == id then return layer end
        end
    end
end

-- Currently selected letter (solid text only), or nil
local function glyphOf(layer)
    if VinewoodSolid and layer and selectedGlyph > 0 then
        return VinewoodSolid.Glyph(layer.id, selectedGlyph) or nil
    end
    return nil
end

local function layerCenter(layer)
    local glyph = glyphOf(layer)
    return (glyph and glyph.center) or Render.DisplayLayer(layer).position
end

local function setSelectedGlyph(index)
    selectedGlyph = (type(index) == "number" and math.floor(index)) or 0
    if selectedGlyph < 1 or not glyphOf(findLayer(selectedId)) then
        selectedGlyph = 0
    end
end

local function firstLayerId()
    return (scene.layers[1] and scene.layers[1].id) or nil
end

---------------------------------------------------------------------
-- NUI sync (throttled to 50 ms unless forced)
---------------------------------------------------------------------
local function sendTransform(layer, force)
    local now = GetGameTimer()
    if force or now - lastTransformSend > 50 then
        SendNUIMessage({
            action   = "transform",
            id       = layer.id,
            position = layer.position,
            rotation = layer.rotation,
            width    = layer.width,
            height   = layer.height,
        })
        lastTransformSend = now
    end
end

local function sendLetterTransform(layer, index, force)
    local now = GetGameTimer()
    if force or now - lastTransformSend > 50 then
        SendNUIMessage({
            action   = "letterTransform",
            id       = layer.id,
            index    = index,
            override = VinewoodLayout.Override(layer, index, false),
        })
        lastTransformSend = now
    end
end

---------------------------------------------------------------------
-- Camera settings
---------------------------------------------------------------------
local function defaultCamSettings()
    local c = Config.Camera or {}
    return {
        fov         = (Config.Freecam.Fov or 55.0) + 0.0,
        speed       = (Config.Freecam.Speed or 18.0) + 0.0,
        sensitivity = (c.Sensitivity or 1.0) + 0.0,
        invertY     = c.InvertY == true,
        smooth      = c.Smooth ~= false,
    }
end

local function cameraSettingsSnapshot()
    return {
        fov         = camSettings.fov,
        speed       = camSettings.speed,
        sensitivity = camSettings.sensitivity,
        invertY     = camSettings.invertY,
        smooth      = camSettings.smooth,
    }
end

local function interpolationMs()
    local v = Config.Camera and Config.Camera.Interpolation
    if isFiniteNumber(v) then
        return math.floor(Math.clamp(v, 0, 5000))
    end
    return 0
end

-- Returns hour, minute for "day" / "sunset" / "night" (config may override)
local function resolveTimePreview(mode)
    local configured = Config.Camera and Config.Camera.TimePreview
    if type(configured) ~= "table" then configured = nil end

    local t = (configured and configured[mode]) or TIME_PRESETS[mode]
    if type(t) ~= "table" or not isFiniteNumber(t[1]) or not isFiniteNumber(t[2]) then
        return nil
    end

    return math.floor(Math.clamp(t[1], 0, 23)), math.floor(Math.clamp(t[2], 0, 59))
end

local function setTimePreview(mode)
    local had = timePreview ~= nil
    timePreview = mode
    if not mode and had then
        NetworkClearClockTimeOverride()
    end
end

---------------------------------------------------------------------
-- Camera transitions / movement
---------------------------------------------------------------------
-- Abort a running interpolation, snapping the main cam to where it is now
local function finishTransition()
    if not transitionCam then return end

    local pos = GetFinalRenderedCamCoord()
    local rot = GetFinalRenderedCamRot(2)
    local fov = GetFinalRenderedCamFov()

    local old = transitionCam
    transitionCam = nil

    SetCamCoord(cam, pos.x, pos.y, pos.z)
    SetCamRot(cam, Math.clamp(rot.x, -89.0, 89.0), 0.0, rot.z, 2)
    SetCamFov(cam, fov)
    SetCamActive(cam, false)
    SetCamActive(cam, true)
    DestroyCam(old, false)
end

-- Interpolation finished: the transition cam becomes the main cam
local function promoteTransitionCam()
    local old = cam
    cam = transitionCam
    transitionCam = nil
    DestroyCam(old, false)
    Render.RefreshCandidates()
end

local function moveCamera(pos, rot, fov, smooth)
    finishTransition()

    fov = fov or GetCamFov(cam)
    local interp = interpolationMs()
    local pitch  = Math.clamp(rot.x, -89.0, 89.0) + 0.0
    local roll   = (rot.y or 0.0) + 0.0

    if smooth and camSettings.smooth and interp > 0 then
        local newCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", false)
        SetCamCoord(newCam, pos.x + 0.0, pos.y + 0.0, pos.z + 0.0)
        SetCamRot(newCam, pitch, roll, rot.z + 0.0, 2)
        SetCamFov(newCam, fov + 0.0)
        SetCamActiveWithInterp(newCam, cam, interp, 1, 1)

        transitionCam   = newCam
        transitionStart = GetGameTimer()
        transitionEnd   = GetGameTimer() + interp + 80
    else
        SetCamCoord(cam, pos.x + 0.0, pos.y + 0.0, pos.z + 0.0)
        SetCamRot(cam, pitch, roll, rot.z + 0.0, 2)
        SetCamFov(cam, fov + 0.0)
        SetFocusPosAndVel(pos.x + 0.0, pos.y + 0.0, pos.z + 0.0, 0.0, 0.0, 0.0)
        Render.RefreshCandidates()
    end
end

local function captureCamera()
    local pos = GetFinalRenderedCamCoord()
    local rot = GetFinalRenderedCamRot(2)
    return {
        position = { x = pos.x, y = pos.y, z = pos.z },
        rotation = { x = Math.clamp(rot.x, -89.0, 89.0), y = 0.0, z = rot.z },
        fov      = GetFinalRenderedCamFov(),
    }
end

-- Validate a bookmark coming from the UI; returns a clean table or nil
local function sanitizeCamera(c)
    if type(c) ~= "table" or type(c.position) ~= "table" or type(c.rotation) ~= "table" then
        return nil
    end

    local p, r = c.position, c.rotation
    if not (isFiniteNumber(p.x) and isFiniteNumber(p.y) and isFiniteNumber(p.z)
        and isFiniteNumber(r.x) and isFiniteNumber(r.z)) then
        return nil
    end

    local pos = { x = p.x + 0.0, y = p.y + 0.0, z = p.z + 0.0 }
    if Math.distance2(pos, Config.Anchor) > Config.Freecam.MaxDistance ^ 2 then
        return nil
    end

    local fov = (isFiniteNumber(c.fov) and Math.clamp(c.fov, 20.0, 90.0)) or camSettings.fov

    return {
        position = pos,
        rotation = {
            x = Math.clamp(r.x, -89.0, 89.0) + 0.0,
            y = 0.0,
            z = wrap180(r.z) + 0.0,
        },
        fov = fov + 0.0,
    }
end

---------------------------------------------------------------------
-- Open / close / publish
---------------------------------------------------------------------
function Editor.Cursor(enabled)
    if not Editor.Active then return end

    cursorMode = enabled == true
    drag, orbit, pan = nil, nil, nil
    resetInput()

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = "mode", cursor = cursorMode })
end

function Editor.Open(data)
    if Editor.Active then return end

    ped = PlayerPedId()
    if IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) then
        TriggerServerEvent("oxlyn-vinewood:closeEditor")
        Core.Notify(L("editor_enter_vehicle"), "error")
        return
    end

    local valid, err = VinewoodSchema.Validate(data.scene)
    if not valid then
        TriggerServerEvent("oxlyn-vinewood:closeEditor")
        Core.Notify(err, "error")
        return
    end

    scene    = valid
    revision = data.revision

    Core.received = true
    Core.revision = data.revision
    Core.scene    = Math.copy(valid)

    selectedId    = firstLayerId()
    selectedGlyph = 0

    pedWasFrozen = IsEntityPositionFrozen(ped)
    FreezeEntityPosition(ped, true)

    camSettings = defaultCamSettings()
    resetInput()
    drag, orbit, pan, transitionCam = nil, nil, nil, nil
    uiHidden, fovDirty = false, false
    setTimePreview(nil)

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local pos = Config.Freecam.Position
    local rot = Config.Freecam.Rotation
    SetCamCoord(cam, pos.x + 0.0, pos.y + 0.0, pos.z + 0.0)
    SetCamRot(cam, rot.x + 0.0, rot.y + 0.0, rot.z + 0.0, 2)
    SetCamFov(cam, camSettings.fov)
    RenderScriptCams(true, false, 0, true, true)
    SetFocusPosAndVel(pos.x + 0.0, pos.y + 0.0, pos.z + 0.0, 0.0, 0.0, 0.0)

    Editor.Active = true
    viewportBottom = 1.0
    Editor.PreviewMotion = true
    saving = false

    Render.SetScene(scene)

    -- Characters available in the condensed glyph font
    local glyphChars = {}
    if VinewoodGlyphs then
        for code in pairs(VinewoodGlyphs.fonts.condensed.glyphs) do
            glyphChars[#glyphChars + 1] = code
        end
        table.sort(glyphChars)
        for i, code in ipairs(glyphChars) do
            glyphChars[i] = utf8.char(code)
        end
    end

    local fontCatalog = VinewoodSchema.FontCatalog()

    SendNUIMessage({
        action                = "open",
        scene                 = scene,
        revision              = revision,
        limits                = data.limits or Config.Limits,
        theme                 = Config.Theme,
        glyphCharacters       = (#glyphChars > 0) and table.concat(glyphChars) or nil,
        -- guess at the original expression: "compatible unless the solid module says otherwise"
        solidCompatibility    = (not VinewoodSolid) or VinewoodSolid.MaterialEffectsAvailable,
        solidColorAvailable   = VinewoodSolid and VinewoodSolid.ColorAvailable == true,
        textFillAvailable     = true,
        solidFillAvailable    = true,
        fillDirectionAvailable = true,
        solidGradientScope    = "letter",
        solidFonts            = fontCatalog.solid,
        fontCatalog           = fontCatalog,
        anchor                = Math.copy(Config.Anchor),
        cameraPresetsAvailable = true,
        keys                  = Config.Keys,
        ui                    = Config.UI,
        camera                = cameraSettingsSnapshot(),
        version               = resourceVersion(),
    })

    Editor.Cursor(true)
end

function Editor.Close()
    if not Editor.Active then return end
    Editor.Active = false

    drag, orbit, pan = nil, nil, nil
    setTimePreview(nil)
    uiHidden = false

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    if transitionCam then
        DestroyCam(transitionCam, false)
        transitionCam = nil
    end
    if cam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(cam, false)
        cam = nil
    end

    ClearFocus()

    if ped and DoesEntityExist(ped) then
        FreezeEntityPosition(ped, pedWasFrozen)
    end
    ped = nil

    Render.SetScene(Core.scene)
    SendNUIMessage({ action = "close" })
    TriggerServerEvent("oxlyn-vinewood:closeEditor")
end

-- Called when the server confirms a publish
function Editor.Published(newScene, newRevision)
    saving   = false
    scene    = Math.copy(newScene)
    revision = newRevision

    if not findLayer(selectedId) then
        selectedId = firstLayerId()
    end

    drag = nil
    Render.SetScene(scene)
    setSelectedGlyph(selectedGlyph)
end

---------------------------------------------------------------------
-- NUI callback helper
---------------------------------------------------------------------
local function requireActive(cb)
    if not Editor.Active then
        cb({ ok = false, error = L("editor_closed") })
        return false
    end
    return true
end

---------------------------------------------------------------------
-- NUI callbacks: scene
---------------------------------------------------------------------
RegisterNUICallback("preview", function(data, cb)
    if not requireActive(cb) then return end

    if drag then cb({ ok = true }) return end
    if saving then cb({ ok = false, error = L("editor_wait_publish") }) return end

    local valid, err = VinewoodSchema.Validate(data.scene)
    if not valid then cb({ ok = false, error = err }) return end

    scene = valid
    selectedId = (type(data.selectedId) == "string" and data.selectedId) or nil
    Render.SetScene(scene)
    setSelectedGlyph(data.selectedGlyph)
    cb({ ok = true })
end)

RegisterNUICallback("save", function(data, cb)
    if not requireActive(cb) then return end

    if saving then cb({ ok = false, error = L("editor_publishing") }) return end

    local valid, err = VinewoodSchema.Validate(data.scene)
    if not valid then cb({ ok = false, error = err }) return end

    if data.baseRevision ~= revision then
        cb({ ok = false, error = L("editor_outdated_revision") })
        return
    end

    scene = valid
    drag = nil
    saving = true
    saveDeadline = GetGameTimer() + 15000

    TriggerServerEvent("oxlyn-vinewood:save", { scene = valid, baseRevision = revision })
    cb({ ok = true })
end)

RegisterNUICallback("close", function(_, cb)
    Editor.Close()
    cb({ ok = true })
end)

RegisterNUICallback("cursor", function(data, cb)
    Editor.Cursor(data.enabled)
    cb({ ok = true })
end)

RegisterNUICallback("select", function(data, cb)
    if not requireActive(cb) then return end
    selectedId = findLayer(data.id) and data.id or nil
    setSelectedGlyph(data.glyphIndex)
    cb({ ok = true })
end)

RegisterNUICallback("motionPreview", function(data, cb)
    if not requireActive(cb) then return end
    Editor.PreviewMotion = data.enabled ~= false
    cb({ ok = true })
end)

RegisterNUICallback("tool", function(data, cb)
    if not requireActive(cb) then return end

    if data.mode == "translate" or data.mode == "rotate" or data.mode == "scale" then
        toolMode = data.mode
    end
    if AXES[data.axis] then
        toolAxis = data.axis
    end
    if isFiniteNumber(data.snap) then
        snapStep = Math.clamp(data.snap, 0, 15)
    end
    cb({ ok = true })
end)

RegisterNUICallback("viewportLayout", function(data, cb)
    if not requireActive(cb) then return end

    if not isFiniteNumber(data.bottom) then
        cb({ ok = false, error = L("editor_invalid_viewport") })
        return
    end
    viewportBottom = Math.clamp(data.bottom, 0.35, 1.0)
    cb({ ok = true })
end)

RegisterNUICallback("hideUi", function(data, cb)
    if not requireActive(cb) then return end
    uiHidden = type(data) == "table"
    cb({ ok = true, hidden = uiHidden })
end)

---------------------------------------------------------------------
-- NUI callbacks: freecam input
---------------------------------------------------------------------
RegisterNUICallback("freecamMove", function(data, cb)
    if not Editor.Active then cb({ ok = false }) return end

    if type(data) == "table" then
        for key in pairs(moveKeys) do
            if type(data[key]) == "boolean" then
                moveKeys[key] = data[key]
            end
        end
    end
    cb({ ok = true })
end)

RegisterNUICallback("freecamLook", function(data, cb)
    if not Editor.Active or cursorMode then cb({ ok = false }) return end

    if type(data) == "table" and isFiniteNumber(data.dx) and isFiniteNumber(data.dy) then
        lookDelta.x = lookDelta.x + Math.clamp(data.dx + 0.0, -400.0, 400.0)
        lookDelta.y = lookDelta.y + Math.clamp(data.dy + 0.0, -400.0, 400.0)
    end
    cb({ ok = true })
end)

RegisterNUICallback("freecamWheel", function(data, cb)
    if not (Editor.Active and not cursorMode and cam) then cb({ ok = false }) return end

    local delta = type(data) == "table" and tonumber(data.delta) or nil
    if delta and delta ~= 0 then
        local fov = Math.clamp(GetCamFov(cam) + (delta > 0 and 3.0 or -3.0), 20.0, 90.0)
        SetCamFov(cam, fov)
        camSettings.fov = fov
        fovDirty = true
    end
    cb({ ok = true })
end)

---------------------------------------------------------------------
-- View presets (front / back / left / right / top / iso)
---------------------------------------------------------------------
-- Horizontal (Z = 0) version of `dir`; falls back to the layer's facing
local function horizontalDirection(dir, layer)
    local flat = { x = dir.x, y = dir.y, z = 0 }
    if Math.length(flat) < 1.0E-4 then
        local yaw = math.rad(layer.rotation.z)
        return { x = math.sin(yaw), y = -math.cos(yaw), z = 0 }
    end
    return Math.normal(flat)
end

-- Work out where the camera should sit to frame `layer` (or one `glyph`) from `view`
local function computeViewCamera(layer, view, glyph)
    local display = (layer and Render.DisplayLayer(layer)) or {
        position = Config.Anchor,
        rotation = { x = 0, y = 0, z = 0 },
        width    = 110,
        height   = 25,
    }

    local right, up = Math.basis(display.rotation)
    if glyph then
        right, up = glyph.right, glyph.up
    end

    local center = (glyph and glyph.center) or display.position
    local normal = Math.normal(Math.cross(right, up))

    local halfFov    = math.rad(GetCamFov(activeCam()) / 2)
    local vertOffset = math.atan(math.tan(halfFov) * (1 - viewportBottom))
    local distMult   = 1.0

    if view == "back" then
        normal = Math.mul(normal, -1)
    elseif view == "right" or view == "side" then
        normal = right
    elseif view == "left" then
        normal = Math.mul(right, -1)
    elseif view == "iso" then
        local horiz = horizontalDirection(normal, display)
        local side  = { x = right.x, y = right.y, z = 0 }
        if Math.length(side) < 1.0E-4 then
            side = Math.cross({ x = 0, y = 0, z = 1 }, horiz)
        end
        side = Math.normal(side)

        local c, s = math.cos(math.rad(40)), math.sin(math.rad(40))
        local flat = Math.normal({
            x = horiz.x * c - side.x * s,
            y = horiz.y * c - side.y * s,
            z = 0,
        })

        local elev = math.rad(25)
        normal = {
            x = flat.x * math.cos(elev),
            y = flat.y * math.cos(elev),
            z = math.sin(elev),
        }
        distMult = 1.1
    elseif view == "top" then
        local horiz = horizontalDirection(normal, display)
        local k = math.max(0.4, math.tan(vertOffset + math.rad(3)))
        normal = Math.normal({ x = horiz.x * k, y = horiz.y * k, z = 1.0 })
    end

    local width  = (glyph and glyph.width)  or display.width
    local height = (glyph and glyph.height) or display.height
    local halfDiag = math.sqrt(width * width + height * height) / 2

    local aspect = GetAspectRatio(false)
    local vFit = math.atan(math.tan(halfFov) * viewportBottom)
    local hFit = math.atan(math.tan(halfFov) * aspect)

    if view == "top" then
        vFit = math.min(
            halfFov - vertOffset,
            math.atan(math.tan(halfFov) * (2 * viewportBottom - 1)) + vertOffset
        )
        hFit = math.asin(math.sin(hFit) * math.cos(vertOffset))
    end

    local dist = (halfDiag / math.sin(math.min(vFit, hFit))) * 1.15 + 8
    dist = dist * distMult

    local pos = Math.add(center, Math.mul(normal, dist))

    -- keep inside the allowed freecam radius
    local fromAnchor = Math.sub(pos, Config.Anchor)
    local maxDist = Config.Freecam.MaxDistance - 5
    if Math.length(fromAnchor) > maxDist then
        pos = Math.add(Config.Anchor, Math.mul(Math.normal(fromAnchor), maxDist))
    end

    local look  = Math.normal(Math.sub(center, pos))
    local pitch = math.asin(Math.clamp(look.z, -1, 1)) - vertOffset

    return {
        position = pos,
        rotation = {
            x = Math.clamp(math.deg(pitch), -89, 89),
            y = 0.0,
            z = math.deg(math.atan(-look.x, look.y)),
        },
    }
end

local function applyView(layer, view, glyph)
    local c = computeViewCamera(layer, view, glyph)
    moveCamera(c.position, c.rotation, nil, true)
end

RegisterNUICallback("focus", function(data, cb)
    if not requireActive(cb) then return end

    local layer = findLayer(data.id)
    if layer then
        selectedId = layer.id
        setSelectedGlyph(data.glyphIndex)
        applyView(layer, "front", glyphOf(layer))
    end
    cb({ ok = true })
end)

RegisterNUICallback("cameraPreset", function(data, cb)
    if not requireActive(cb) then return end

    local preset = data.preset
    if preset == "home" then
        local pos, rot = Config.Freecam.Position, Config.Freecam.Rotation
        moveCamera(
            { x = pos.x, y = pos.y, z = pos.z },
            { x = rot.x, y = rot.y, z = rot.z },
            camSettings.fov,
            true
        )
    elseif VIEW_PRESETS[preset] then
        local layer = findLayer(data.id or selectedId)
        local glyph = (layer and layer.id == selectedId and glyphOf(layer)) or nil
        applyView(layer, preset, glyph)
    else
        cb({ ok = false, error = L("editor_unknown_view") })
        return
    end

    cb({ ok = true })
end)

RegisterNUICallback("cameraSettings", function(data, cb)
    if not requireActive(cb) then return end

    if type(data) ~= "table" then
        cb({ ok = false, error = L("editor_invalid_settings") })
        return
    end

    for _, key in ipairs({ "fov", "speed", "sensitivity" }) do
        if data[key] ~= nil and not isFiniteNumber(data[key]) then
            cb({ ok = false, error = L("editor_invalid_settings") })
            return
        end
    end

    if data.fov ~= nil then
        camSettings.fov = Math.clamp(data.fov, 20.0, 90.0) + 0.0
        SetCamFov(cam, camSettings.fov)
        if transitionCam then SetCamFov(transitionCam, camSettings.fov) end
    end
    if data.speed ~= nil then
        camSettings.speed = Math.clamp(data.speed, 2.0, 120.0) + 0.0
    end
    if data.sensitivity ~= nil then
        camSettings.sensitivity = Math.clamp(data.sensitivity, 0.3, 3.0) + 0.0
    end
    if data.invertY ~= nil then camSettings.invertY = data.invertY == true end
    if data.smooth  ~= nil then camSettings.smooth  = data.smooth  == true end

    cb({ ok = true, camera = cameraSettingsSnapshot() })
end)

RegisterNUICallback("cameraBookmark", function(data, cb)
    if not requireActive(cb) then return end

    local slot = (type(data) == "table" and isFiniteNumber(data.slot) and math.floor(data.slot)) or 0
    if slot < 1 or slot > 3 then
        cb({ ok = false, error = L("bookmark_invalid_slot") })
        return
    end

    local action = data.action
    if action == "save" then
        bookmarks[slot] = captureCamera()
        cb({ ok = true, slot = slot, saved = true, camera = bookmarks[slot] })

    elseif action == "set" then
        local clean = sanitizeCamera(data.camera)
        if not clean then
            cb({ ok = false, error = L("bookmark_invalid_camera") })
            return
        end
        bookmarks[slot] = clean
        cb({ ok = true, slot = slot, saved = true })

    elseif action == "clear" then
        bookmarks[slot] = nil
        cb({ ok = true, slot = slot, saved = false })

    elseif action == "go" then
        local saved = bookmarks[slot]
        if not saved then
            cb({ ok = false, error = L("bookmark_slot_empty", { slot = slot }) })
            return
        end
        moveCamera(saved.position, saved.rotation, saved.fov, true)
        if math.abs(saved.fov - camSettings.fov) > 0.01 then
            camSettings.fov = saved.fov
            fovDirty = true
        end
        cb({ ok = true, slot = slot, camera = saved })

    else
        cb({ ok = false, error = L("bookmark_invalid_action") })
    end
end)

RegisterNUICallback("timePreview", function(data, cb)
    if not requireActive(cb) then return end

    local mode = (type(data) == "table" and data.mode) or "live"

    if mode == "live" then
        setTimePreview(nil)
        cb({ ok = true, mode = "live" })
    elseif mode == "day" or mode == "sunset" or mode == "night" then
        if resolveTimePreview(mode) then
            setTimePreview(mode)
            cb({ ok = true, mode = mode })
        end
        -- (original gives no reply if the preset can't be resolved)
    else
        cb({ ok = false, error = L("editor_invalid_time_preview") })
    end
end)

---------------------------------------------------------------------
-- Orbit / pan / dolly
---------------------------------------------------------------------
-- Point the camera orbits around: selected layer, else the anchor
local function focusPoint()
    local layer = findLayer(selectedId)
    if layer then
        return Math.copy(layerCenter(layer))
    end
    return Math.copy(Config.Anchor)
end

local function inRange(pos)
    return Math.distance2(pos, Config.Anchor) <= Config.Freecam.MaxDistance ^ 2
end

local function beginOrbit(x, y)
    finishTransition()

    local center = focusPoint()
    local offset = Math.sub(camPos(), center)
    local dist   = Math.length(offset)
    local look   = (dist > 0.001 and Math.mul(Math.normal(offset), -1)) or { x = 0, y = 1, z = 0 }

    orbit = {
        center = center,
        dist   = math.max(1.0, dist),
        yaw    = math.deg(math.atan(-look.x, look.y)),
        pitch  = Math.clamp(math.deg(math.asin(Math.clamp(look.z, -1, 1))), -85.0, 85.0),
        x      = x,
        y      = y,
    }
end

local function updateOrbit(x, y)
    local sens = camSettings.sensitivity * ((Config.Camera and Config.Camera.OrbitSensitivity) or 1.0)

    local dPitch = (y - orbit.y) * 180 * sens
    if camSettings.invertY then dPitch = -dPitch end

    local yaw   = wrap180(orbit.yaw - (x - orbit.x) * 360 * sens)
    local pitch = Math.clamp(orbit.pitch - dPitch, -85.0, 85.0)

    local forward = Math.cameraBasis({ x = pitch, y = 0, z = yaw })
    local pos = Math.sub(orbit.center, Math.mul(forward, orbit.dist))

    if inRange(pos) then
        SetCamCoord(cam, pos.x, pos.y, pos.z)
        SetCamRot(cam, pitch, 0.0, yaw, 2)
    end
end

local function beginPan(x, y)
    finishTransition()

    local origin = camPos()
    pan = {
        origin   = origin,
        dist     = math.max(3.0, Math.length(Math.sub(origin, focusPoint()))),
        x        = x,
        y        = y,
        rotation = camRot(),
    }
end

local function updatePan(x, y)
    local _, right, up = Math.cameraBasis(pan.rotation)

    local height = math.tan(math.rad(GetCamFov(cam) * 0.5)) * pan.dist * 2
    local dx = (x - pan.x) * height * GetAspectRatio(false)
    local dy = (y - pan.y) * height

    local pos = Math.add(pan.origin, Math.add(Math.mul(right, -dx), Math.mul(up, dy)))
    if inRange(pos) then
        SetCamCoord(cam, pos.x, pos.y, pos.z)
    end
end

RegisterNUICallback("dolly", function(data, cb)
    if not requireActive(cb) then return end

    if not (cursorMode and type(data) == "table" and isFiniteNumber(data.delta)) then
        cb({ ok = false })
        return
    end

    finishTransition()

    local center = (orbit and orbit.center) or focusPoint()
    local pos    = camPos()
    local offset = Math.sub(pos, center)
    local dist   = Math.length(offset)

    if dist < 0.01 then cb({ ok = true }) return end

    local d = Math.clamp(data.delta, -5, 5)
    local factor = (d >= 0) and (1 + 0.08 * d) or (1 / (1 + 0.08 * (-d)))
    local newDist = math.max(3.0, dist * factor)
    local newPos  = Math.add(center, Math.mul(Math.normal(offset), newDist))

    if inRange(newPos) then
        SetCamCoord(cam, newPos.x, newPos.y, newPos.z)
        SetFocusPosAndVel(newPos.x, newPos.y, newPos.z, 0.0, 0.0, 0.0)

        if orbit then orbit.dist = newDist end
        if pan then
            pan.origin = Math.add(pan.origin, Math.sub(newPos, pos))
            pan.dist   = newDist
        end
        Render.RefreshCandidates()
    end

    cb({ ok = true })
end)

---------------------------------------------------------------------
-- Face camera
---------------------------------------------------------------------
RegisterNUICallback("faceCamera", function(data, cb)
    if not requireActive(cb) then return end
    if type(data) ~= "table" then data = {} end

    local layer = findLayer(data.id or selectedId)
    if not layer then cb({ ok = false, error = L("editor_layer_not_found") }) return end
    if layer.locked then cb({ ok = false, error = L("editor_layer_locked") }) return end

    local glyphIndex = (isFiniteNumber(data.glyphIndex) and math.floor(data.glyphIndex)) or 0
    local glyph = nil
    if glyphIndex > 0 and layer.type == "text" and layer.renderMode == "solid" and VinewoodSolid then
        glyph = VinewoodSolid.Glyph(layer.id, glyphIndex) or nil
    end

    local center = (glyph and glyph.center) or Render.DisplayLayer(layer).position
    local cpos   = finalCamPos()
    local toCam  = { x = cpos.x - center.x, y = cpos.y - center.y, z = 0 }

    if Math.length(toCam) < 0.01 then cb({ ok = true }) return end

    local n   = Math.normal(toCam)
    local yaw = math.deg(math.atan(n.x, -n.y))

    if glyph then
        local override = VinewoodLayout.Override(layer, glyphIndex, true)
        override.rotation.z = wrap180(yaw - layer.rotation.z)
        Render.SetScene(scene)
        sendLetterTransform(layer, glyphIndex, true)
    else
        layer.rotation.z = wrap180(yaw)
        Render.SetScene(scene)
        sendTransform(layer, true)
    end

    cb({ ok = true })
end)

---------------------------------------------------------------------
-- Gizmo helpers
---------------------------------------------------------------------
-- Closest-point parameter along a line (point + dir) to a mouse ray
local function axisParameter(rayOrigin, rayDir, linePoint, lineDir)
    local w = Math.sub(rayOrigin, linePoint)
    local b = Math.dot(lineDir, rayDir)
    local denom = 1 - b * b
    if denom < 0.005 then return nil end

    local d = Math.dot(lineDir, w)
    local e = Math.dot(rayDir, w)
    return (d - b * e) / denom
end

local function gizmoScale(layer)
    local dist = Math.length(Math.sub(camPos(), layerCenter(layer)))
    return Math.clamp(dist * 0.055, 2.0, 18.0)
end

-- World-space directions of the gizmo handles
local function gizmoAxes(layer)
    if toolMode ~= "rotate" then
        return AXES
    end

    local glyph = glyphOf(layer)
    local rot = (glyph and VinewoodLayout.Override(layer, selectedGlyph, false).rotation) or layer.rotation

    local axes = {
        x = Math.rotate(AXES.x, { x = 0,     y = 0, z = rot.z }),
        y = Math.rotate(AXES.y, { x = rot.x, y = 0, z = rot.z }),
        z = AXES.z,
    }

    if glyph then
        for k, v in pairs(axes) do
            axes[k] = Math.rotate(v, layer.rotation)
        end
    end
    return axes
end

-- Which gizmo handle (if any) is under the cursor at normalised (x, y)
local function pickGizmoAxis(layer, x, y)
    local scale = gizmoScale(layer)
    local resX, resY = GetActiveScreenResolution()
    local best, bestDist = nil, 400

    for axis, dir in pairs(gizmoAxes(layer)) do
        local tip = Math.add(layerCenter(layer), Math.mul(dir, scale))
        local onScreen, sx, sy = GetScreenCoordFromWorldCoord(tip.x, tip.y, tip.z)
        if onScreen then
            local d = ((x - sx) * resX) ^ 2 + ((y - sy) * resY) ^ 2
            if d < bestDist then
                best, bestDist = axis, d
            end
        end
    end
    return best
end

local function mouseRay(x, y)
    local origin = finalCamPos()
    return origin, Math.ray(finalCamRot(), GetFinalRenderedCamFov(), GetAspectRatio(false), x, y)
end

---------------------------------------------------------------------
-- Viewport mouse handling
---------------------------------------------------------------------
local function applyLayerDrag(layer, x, y)
    local origin, dir = mouseRay(x, y)

    if drag.glyphIndex > 0 then
        -- editing a single letter via its override
        local override = VinewoodLayout.Override(layer, drag.glyphIndex, true)

        if toolMode == "translate" then
            local t = axisParameter(origin, dir, drag.center, AXES[toolAxis])
            if t and drag.parameter then
                local delta = Math.mul(AXES[toolAxis], snap(t - drag.parameter))
                local offset = Math.add(
                    drag.initialOverride.offset,
                    VinewoodLayout.WorldVectorToLocal(delta, layer.rotation)
                )
                if math.abs(offset.x) <= 50 and math.abs(offset.y) <= 50 and math.abs(offset.z) <= 50 then
                    override.offset = offset
                end
            end
        elseif toolMode == "rotate" then
            override.rotation[toolAxis] = wrap180(
                drag.initialOverride.rotation[toolAxis] + snap((x - drag.x) * 360)
            )
        elseif toolMode == "scale" then
            local factor = math.max(0.01, 1 + (x - drag.x) * 3 - (y - drag.y) * 3)
            override.scale = Math.clamp(snap(drag.initialOverride.scale * factor), 0.25, 3)
        end

        drag.changed = true
    else
        -- editing the whole layer
        if toolMode == "translate" then
            local t = axisParameter(origin, dir, drag.initial.position, AXES[toolAxis])
            if t and drag.parameter then
                local d = snap(t - drag.parameter)
                local newPos = Math.add(drag.initial.position, Math.mul(AXES[toolAxis], d))
                if Math.distance2(newPos, Config.Anchor) <= Config.Limits.AreaRadius ^ 2 then
                    layer.position = newPos
                end
            end
        elseif toolMode == "rotate" then
            layer.rotation[toolAxis] = wrap180(drag.initial.rotation[toolAxis] + snap((x - drag.x) * 360))
        elseif toolMode == "scale" then
            local factor = math.max(0.01, 1 + (x - drag.x) * 3 - (y - drag.y) * 3)
            local limits = Config.Limits

            if layer.type == "image" and layer.keepAspect ~= false then
                factor = Math.clamp(
                    factor,
                    limits.MinSize / math.min(drag.initial.width, drag.initial.height),
                    limits.MaxSize / math.max(drag.initial.width, drag.initial.height)
                )
                layer.width  = drag.initial.width * factor
                layer.height = drag.initial.height * factor
            else
                if toolAxis == "x" or toolAxis == "y" then
                    layer.width = Math.clamp(snap(drag.initial.width * factor), limits.MinSize, limits.MaxSize)
                end
                if toolAxis == "z" or toolAxis == "y" then
                    layer.height = Math.clamp(snap(drag.initial.height * factor), limits.MinSize, limits.MaxSize)
                end
            end
        end
    end

    Render.SetScene(scene)
    if drag.glyphIndex > 0 then
        sendLetterTransform(layer, drag.glyphIndex, false)
    else
        sendTransform(layer, false)
    end
end

local function beginLeftClick(x, y)
    local origin, dir = mouseRay(x, y)

    -- Did the click land on a gizmo handle of the current selection?
    local selected = findLayer(selectedId)
    local axisHit = (selected and not selected.locked and pickGizmoAxis(selected, x, y)) or nil
    if axisHit then
        toolAxis = axisHit
        SendNUIMessage({ action = "tool", mode = toolMode, axis = toolAxis, snap = snapStep })
    end

    local target = (selected and axisHit) and selected or nil
    local bestDist = math.huge
    local glyphIdx = target and selectedGlyph or 0

    -- Otherwise ray-pick the nearest unlocked, visible layer
    if not target then
        for _, layer in ipairs(scene.layers) do
            if layer.visible and layer.opacity > 0 and not layer.locked then
                local glyph, dist
                if layer.type == "text" and layer.renderMode == "solid" then
                    glyph, dist = VinewoodSolid.Hit(origin, dir, layer.id)
                else
                    dist = Math.hitLayer(origin, dir, Render.DisplayLayer(layer))
                end

                if dist and dist < bestDist then
                    target   = layer
                    bestDist = dist
                    glyphIdx = (glyph and glyph.index) or 0
                end
            end
        end
    end

    if not target then return end

    selectedId    = target.id
    selectedGlyph = glyphIdx

    local center = (target.type == "image" and target.position) or layerCenter(target)

    SendNUIMessage({ action = "select", id = selectedId, glyphIndex = selectedGlyph })

    drag = {
        id         = selectedId,
        initial    = Math.copy(target),
        x          = x,
        y          = y,
        center     = Math.copy(center),
        glyphIndex = selectedGlyph,
        initialOverride = (selectedGlyph > 0
            and Math.copy(VinewoodLayout.Override(target, selectedGlyph, false))) or nil,
        parameter  = axisParameter(origin, dir, center, AXES[toolAxis]),
    }
end

RegisterNUICallback("viewport", function(data, cb)
    if not requireActive(cb) then return end

    if not (cursorMode and not saving and isFiniteNumber(data.x) and isFiniteNumber(data.y)) then
        cb({ ok = false })
        return
    end

    local button = (isFiniteNumber(data.button) and math.floor(data.button)) or 0
    local phase  = data.phase

    if phase == "down" then
        drag, orbit, pan = nil, nil, nil

        if button == 2 then
            beginOrbit(data.x, data.y)
        elseif button == 1 then
            beginPan(data.x, data.y)
        elseif button == 0 then
            beginLeftClick(data.x, data.y)
        end

    elseif phase == "move" then
        if orbit then
            updateOrbit(data.x, data.y)
        elseif pan then
            updatePan(data.x, data.y)
        elseif drag then
            local layer = findLayer(drag.id)
            if layer and layer.locked then
                drag, layer = nil, nil
            end
            if layer then
                applyLayerDrag(layer, data.x, data.y)
            end
        end

    elseif phase == "up" then
        if orbit or pan then
            orbit, pan = nil, nil
            local p = camPos()
            SetFocusPosAndVel(p.x, p.y, p.z, 0.0, 0.0, 0.0)
            Render.RefreshCandidates()
        elseif drag then
            local layer = findLayer(drag.id)
            if layer then
                if drag.glyphIndex > 0 then
                    if drag.changed then
                        sendLetterTransform(layer, drag.glyphIndex, true)
                    end
                else
                    sendTransform(layer, true)
                end
            end
            drag = nil
        end
    end

    cb({ ok = true })
end)

---------------------------------------------------------------------
-- Server events / background threads
---------------------------------------------------------------------
RegisterNetEvent("oxlyn-vinewood:saveResult", function()
    saving = false
end)

-- keep-alive so the server knows the editor is still open
CreateThread(function()
    while true do
        if Editor.Active then
            TriggerServerEvent("oxlyn-vinewood:heartbeat")
        end
        Wait(15000)
    end
end)

-- Draw selection outline + transform gizmo
local function drawSelection()
    local layer = findLayer(selectedId)
    if not layer or uiHidden then return end

    local glyph  = glyphOf(layer)
    local center = layerCenter(layer)
    local corners = (glyph and VinewoodLayout.Corners(glyph)) or Math.corners(Render.DisplayLayer(layer))

    for i = 1, 4 do
        local a = corners[i]
        local b = corners[(i % 4) + 1]
        DrawLine(a.x, a.y, a.z, b.x, b.y, b.z, 242, 243, 245, 150)
    end

    if layer.locked then return end

    local scale = gizmoScale(layer)
    for axis, dir in pairs(gizmoAxes(layer)) do
        local tip   = Math.add(center, Math.mul(dir, scale))
        local color = AXIS_COLORS[axis]

        DrawLine(center.x, center.y, center.z, tip.x, tip.y, tip.z,
            color[1], color[2], color[3], (axis == toolAxis) and 255 or 125)

        DrawMarker(28, tip.x, tip.y, tip.z,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            scale * 0.07, scale * 0.07, scale * 0.07,
            color[1], color[2], color[3], 220,
            false, false, 2, false, nil, nil, false)
    end
end

-- Free-fly camera movement + mouse look
local function updateFreecam()
    local rot = camRot()
    local dx, dy = lookDelta.x, lookDelta.y
    lookDelta.x, lookDelta.y = 0.0, 0.0

    local pitchDelta = dy * 0.08 * camSettings.sensitivity
    if camSettings.invertY then pitchDelta = -pitchDelta end

    rot.z = rot.z - dx * 0.08 * camSettings.sensitivity
    rot.x = Math.clamp(rot.x - pitchDelta, -89.0, 89.0)
    SetCamRot(cam, rot.x, 0.0, rot.z, 2)

    local forward, right = Math.cameraBasis(rot)
    local move = { x = 0, y = 0, z = 0 }

    if moveKeys.f then move = Math.add(move, forward) end
    if moveKeys.b then move = Math.sub(move, forward) end
    if moveKeys.r then move = Math.add(move, right) end
    if moveKeys.l then move = Math.sub(move, right) end
    if moveKeys.u then move.z = move.z + 1 end
    if moveKeys.d then move.z = move.z - 1 end

    local speed = camSettings.speed
    if moveKeys.fast then speed = speed * Config.Freecam.FastMultiplier end
    if moveKeys.slow then speed = speed * Config.Freecam.SlowMultiplier end

    local current = camPos()
    local newPos = Math.add(current,
        Math.mul(Math.normal(move), speed * math.min(GetFrameTime(), 0.05)))

    -- allow movement inside the radius, or any move that brings us closer to the anchor
    local newDist = Math.distance2(newPos, Config.Anchor)
    if newDist < Config.Freecam.MaxDistance ^ 2
        or newDist < Math.distance2(current, Config.Anchor) then
        SetCamCoord(cam, newPos.x, newPos.y, newPos.z)
    end
end

-- Per-frame editor tick
local function editorTick()
    DisableAllControlActions(0)
    DisableAllControlActions(1)
    DisableAllControlActions(2)
    DisablePlayerFiring(PlayerId(), true)
    HideHudAndRadarThisFrame()

    if IsEntityDead(ped) or PlayerPedId() ~= ped then
        Editor.Close()
        Core.Notify(L("editor_player_state"), "error")
        return
    end

    local now = GetGameTimer()

    -- finish smooth camera transitions
    if transitionCam then
        if now >= transitionEnd
            or ((now - transitionStart) > 150 and not IsCamInterpolating(transitionCam)) then
            promoteTransitionCam()
        end
    end

    -- time-of-day preview
    if timePreview then
        local hour, minute = resolveTimePreview(timePreview)
        if hour then
            NetworkOverrideClockTime(hour, minute, 0)
        else
            setTimePreview(nil)
        end
    end

    if not cursorMode and not transitionCam then
        updateFreecam()
    end

    -- push FOV changes (scroll wheel / bookmarks) to the UI at most every 100 ms
    if fovDirty and now - lastFovSend >= 100 then
        fovDirty = false
        lastFovSend = now
        SendNUIMessage({ action = "camera", fov = camSettings.fov })
    end

    local p = GetFinalRenderedCamCoord()
    SetFocusPosAndVel(p.x, p.y, p.z, 0.0, 0.0, 0.0)

    drawSelection()

    -- publish timeout
    if saving and GetGameTimer() > saveDeadline then
        saving = false
        SendNUIMessage({ action = "saveResult", ok = false, error = L("editor_no_response") })
    end
end

CreateThread(function()
    while true do
        local sleep = 500
        if Editor.Active and cam then
            sleep = 0
            editorTick()
        end
        Wait(sleep)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Editor.Close()
    end
end)

