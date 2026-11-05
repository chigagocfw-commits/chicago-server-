

-- Vinewood renderer (cleaned from decompiled output)
--
-- Non-"solid" layers (images and flat text) are drawn by a hidden browser page (DUI) that
-- renders them into a 2048x2048 atlas. The atlas is exposed as a runtime texture and each
-- visible layer is drawn in the world as two textured triangles.
-- "Solid" text layers are handled by VinewoodSolid instead.

VinewoodRender = {}
local M = VinewoodRender

local Math = VinewoodMath

---------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------
local ATLAS_TXD   = "oxlyn_vinewood_atlas"
local ATLAS_TEX   = "surface"
local ATLAS_SIZE  = 2048
local CELL_W      = 1024            -- each layer gets a 1024 x 512 cell (2 columns x 4 rows)
local CELL_H      = 512
local DUI_RETRY_MS     = 10000      -- back-off after a DUI failure
local DUI_LOAD_TIMEOUT = 10000      -- max wait for the DUI / atlas page to come up
local SCENE_SEND_MIN_MS = 120       -- min gap between scene pushes while drawing

-- Hash of the native used to draw a textured triangle (DRAW_SPRITE_POLY)
local NATIVE_DRAW_SPRITE_POLY = 2965620363887581480

---------------------------------------------------------------------
-- State
---------------------------------------------------------------------
local scene       = Config.DefaultScene
local renderables = {}      -- one entry per non-solid layer (see M.SetScene)
local candidates  = {}      -- renderables close enough to the camera to matter

local dui           = nil
local txd           = nil
local textureReady  = false  -- runtime texture created from the DUI
local atlasReady    = false  -- DUI page reported "atlasReady"
local duiCreating   = false
local duiReleasing  = false  -- DUI kept alive but parked on about:blank
local stopped       = false
local generation    = 0      -- bumped whenever the DUI lifecycle restarts (invalidates old threads)
local lastActiveTime = 0
local retryAt        = 0
local sceneJson      = ""    -- JSON of the current scene payload
local sentSceneJson  = nil   -- last payload actually sent to the DUI
local lastSceneSend  = 0
local imagesSent     = {}    -- [url] = true once the DUI has received the image
local originalHidden = false

---------------------------------------------------------------------
-- Hide / restore the original in-world sign
---------------------------------------------------------------------
local function setOriginalHidden(hidden)
    if originalHidden == hidden then return end
    originalHidden = hidden

    local sign = Config.OriginalSign
    for _, modelName in ipairs(sign.Models) do
        local hash = GetHashKey(modelName)
        if hidden then
            CreateModelHide(sign.Center.x, sign.Center.y, sign.Center.z, sign.Radius, hash, true)
        else
            RemoveModelHide(sign.Center.x, sign.Center.y, sign.Center.z, sign.Radius, hash, false)
        end
    end
end

---------------------------------------------------------------------
-- DUI lifecycle
---------------------------------------------------------------------
-- Fully tear down the DUI
local function destroyDui()
    generation = generation + 1

    if dui then
        DestroyDui(dui)
    end

    dui          = nil
    textureReady = false
    atlasReady   = false
    duiCreating  = false
    sentSceneJson = nil
    imagesSent   = {}
    duiReleasing = false
end

-- Keep the DUI + texture but park the page on about:blank (cheap to revive)
local function releaseDui()
    if not dui or duiReleasing then return end

    if not textureReady then
        destroyDui()
        return
    end

    generation    = generation + 1
    atlasReady    = false
    duiCreating   = false
    sentSceneJson = nil
    imagesSent    = {}
    duiReleasing  = true

    pcall(SetDuiUrl, dui, "about:blank")
end

-- Something failed: clean up and back off before trying again
local function failDui()
    if textureReady then
        releaseDui()
    else
        destroyDui()
    end
    retryAt = GetGameTimer() + DUI_RETRY_MS
end

local function atlasUrl(gen)
    local resource = GetCurrentResourceName()
    return ("https://cfx-nui-%s/web/dist/atlas.html?resource=%s&generation=%s"):format(resource, resource, gen)
end

---------------------------------------------------------------------
-- Sending data to the DUI
---------------------------------------------------------------------
-- Push one image (data URL) into the atlas page, if the scene uses it
function M.ImageLoaded(url, dataUrl)
    if stopped or not dui or not textureReady or not atlasReady or imagesSent[url] then
        return
    end

    for _, layer in ipairs(scene.layers) do
        if layer.type == "image" and layer.url == url then
            SendDuiMessage(dui, json.encode({ action = "asset", url = url, dataUrl = dataUrl }))
            imagesSent[url] = true
            return
        end
    end
end

-- Push the scene to the DUI if it changed since the last push
local function sendScene()
    if not (dui and textureReady and atlasReady) then return end
    if sceneJson == sentSceneJson then return end

    -- make sure cached images go out before/with the scene
    if VinewoodImages then
        for _, layer in ipairs(scene.layers) do
            if layer.type == "image" then
                local data = VinewoodImages.Get(layer.url)
                if data then
                    M.ImageLoaded(layer.url, data)
                end
            end
        end
    end

    SendDuiMessage(dui, json.encode({ action = "render", scene = scene }))

    sentSceneJson  = sceneJson
    lastSceneSend  = GetGameTimer()
end

-- Create (or revive) the DUI and runtime texture, then wait for the atlas page
local function ensureDui()
    if dui and not duiReleasing then return end
    if duiCreating or stopped or GetGameTimer() < retryAt then return end

    duiCreating = true
    generation  = generation + 1
    local myGen = generation

    CreateThread(function()
        if stopped or myGen ~= generation then return end

        local handle = dui
        if not handle then
            handle = CreateDui(atlasUrl(myGen), ATLAS_SIZE, ATLAS_SIZE)

            if stopped or myGen ~= generation then
                if handle and handle ~= 0 then DestroyDui(handle) end
                return
            end

            if not handle or handle == 0 then
                duiCreating = false
                retryAt = GetGameTimer() + DUI_RETRY_MS
                return
            end

            dui = handle
        else
            -- reviving a parked DUI
            duiReleasing = false
            local ok = pcall(SetDuiUrl, handle, atlasUrl(myGen))

            if stopped or myGen ~= generation then return end
            if not ok then
                failDui()
                return
            end
        end

        -- wait for the DUI browser to become available
        local deadline = GetGameTimer() + DUI_LOAD_TIMEOUT
        while myGen == generation and not stopped
            and deadline > GetGameTimer()
            and not IsDuiAvailable(handle) do
            Wait(50)
        end

        if myGen ~= generation or stopped then return end

        if not IsDuiAvailable(handle) then
            failDui()
            return
        end

        -- runtime texture backed by the DUI
        if not textureReady then
            if not txd then
                txd = CreateRuntimeTxd(ATLAS_TXD)
            end
            if not txd or txd == 0 then
                txd = nil
                failDui()
                return
            end

            local tex = CreateRuntimeTextureFromDuiHandle(txd, ATLAS_TEX, GetDuiHandle(handle))

            if myGen ~= generation or stopped then return end
            if not tex or tex == 0 then
                failDui()
                return
            end

            textureReady = tex
        end

        duiCreating = false
        sendScene()

        -- wait for the page to say it's ready
        while not atlasReady
            and deadline > GetGameTimer()
            and myGen == generation do
            Wait(100)
        end

        if myGen == generation and not stopped and not atlasReady then
            failDui()
        end
    end)
end

RegisterNUICallback("atlasReady", function(data, cb)
    if not stopped and not duiReleasing
        and tonumber(data.generation) == generation and dui then
        atlasReady = true
        sendScene()
        cb({ ok = true })
    else
        cb({ ok = false })
    end
end)

---------------------------------------------------------------------
-- Scene setup
---------------------------------------------------------------------
local function parseTint(hex)
    local function channel(from, to)
        return tonumber(hex:sub(from, to), 16) or 255
    end
    return channel(2, 3), channel(4, 5), channel(6, 7)
end

function M.SetScene(newScene)
    if stopped then return end
    scene = newScene

    -- forget "sent" flags for images no longer in the scene
    local used = {}
    for _, layer in ipairs(scene.layers) do
        if layer.type == "image" then
            used[layer.url] = true
        end
    end
    for url in pairs(imagesSent) do
        if not used[url] then
            imagesSent[url] = nil
        end
    end

    -- image sources: the editor requests+pushes them itself; otherwise release the UI side
    if VinewoodImages then
        if VinewoodEditor and VinewoodEditor.Active then
            VinewoodImages.WantScene(scene, true)
        elseif VinewoodImages.ReleaseUi then
            VinewoodImages.ReleaseUi()
        end
    end

    if VinewoodSolid then
        VinewoodSolid.SetScene(scene)
    end

    renderables = {}
    local payload = {}

    for i, layer in ipairs(scene.layers) do
        if layer.type == "text" and layer.renderMode == "solid" then
            -- drawn by VinewoodSolid; the atlas just needs a placeholder
            payload[i] = { id = layer.id, renderMode = "solid" }
        else
            -- atlas cell: 2 columns x 4 rows of 1024 x 512
            local col = (i - 1) % 2
            local row = math.floor((i - 1) / 2)

            local tint = (layer.type == "image" and layer.imageTint) or "#FFFFFF"
            local red, green, blue = parseTint(tint)

            local basis = {}   -- cached right/up axes (rx..uz) for facing checks

            renderables[#renderables + 1] = {
                layer   = layer,
                corners = Math.corners(layer, nil, basis),
                basis   = basis,
                display = {},
                pose    = { position = {}, rotation = {} },
                animatedCorners = { {}, {}, {}, {} },
                radius  = (VinewoodEffects and VinewoodEffects.Bounds(layer))
                          or (math.sqrt(layer.width * layer.width + layer.height * layer.height) / 2),
                red     = red,
                green   = green,
                blue    = blue,
                animated = VinewoodEffects and VinewoodEffects.Animated(layer),
                -- half-texel inset to avoid bleeding between atlas cells
                u0 = (col * CELL_W + 0.5) / ATLAS_SIZE,
                u1 = ((col + 1) * CELL_W - 0.5) / ATLAS_SIZE,
                v0 = (row * CELL_H + 0.5) / ATLAS_SIZE,
                v1 = ((row + 1) * CELL_H - 0.5) / ATLAS_SIZE,
            }

            local imageFit = nil
            if layer.type == "image" then
                imageFit = layer.imageFit
                    or ((layer.keepAspect == false) and "stretch")
                    or "contain"
            end

            payload[i] = {
                id = layer.id,
                type = layer.type,
                text = layer.text,
                font = layer.font,
                weight = layer.weight,
                color = layer.color,
                fillMode = layer.fillMode,
                gradientColor = layer.gradientColor,
                gradientDirection = layer.gradientDirection,
                outline = layer.outline,
                outlineWidth = layer.outlineWidth,
                tracking = layer.tracking,
                glow = layer.glow,
                brightness = layer.brightness,
                align = layer.align,
                lineHeight = layer.lineHeight,
                url = layer.url,
                width = layer.width,
                height = layer.height,
                visible = layer.visible,
                imageFit = imageFit,
                imageBrightness = layer.imageBrightness,
                imageContrast = layer.imageContrast,
                imageSaturation = layer.imageSaturation,
                imageGlow = layer.imageGlow,
                imageGlowColor = layer.imageGlowColor,
                imageFlipX = layer.imageFlipX,
                imageFlipY = layer.imageFlipY,
            }
        end
    end

    sceneJson = json.encode(payload)

    setOriginalHidden(scene.hideOriginal)
    M.RefreshCandidates()
end

-- Rebuild the list of layers near enough to the camera to draw
function M.RefreshCandidates()
    local camPos = GetFinalRenderedCamCoord()
    local count = 0

    for _, r in ipairs(renderables) do
        local layer = r.layer
        if layer.visible and layer.opacity > 0 then
            local maxDist = Config.DrawDistance + r.radius
            if Math.distance2(camPos, layer.position) < maxDist ^ 2 then
                count = count + 1
                candidates[count] = r

                if VinewoodImages and layer.type == "image" then
                    VinewoodImages.Want(layer.url)
                end
            end
        end
    end

    for i = #candidates, count + 1, -1 do
        candidates[i] = nil
    end
end

---------------------------------------------------------------------
-- Animated layers
---------------------------------------------------------------------
-- Returns the layer as it should currently be displayed (effects applied).
-- Non-animated (or paused) layers are returned unchanged.
--   time  : seconds (defaults to network time)
--   out   : table to reuse for the result
--   pose  : scratch table for VinewoodEffects.Pose
function M.DisplayLayer(layer, time, out, pose)
    if not (VinewoodEffects and VinewoodEffects.Animated(layer)) then
        return layer
    end

    local editor = VinewoodEditor
    if editor and editor.Active and editor.MotionPaused and editor.MotionPaused(layer.id) then
        return layer
    end

    if not time then
        local ms = (GetNetworkTimeAccurate and GetNetworkTimeAccurate()) or GetGameTimer()
        if ms < 0 then ms = ms + 4294967296 end   -- unsigned wrap
        time = ms / 1000
    end

    local position, rotation, scale, opacity = VinewoodEffects.Pose(layer, time, false, pose)

    out = out or {}
    out.position = position
    out.rotation = rotation
    out.width    = layer.width * (scale or 1)
    out.height   = layer.height * (scale or 1)
    out.opacity  = layer.opacity * (opacity or 1)
    return out
end

---------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------
-- Draw one textured triangle from the atlas
--   p1..p3 : world positions, (u,v) per vertex, alpha 0-255, r = renderable (for tint)
local function drawTriangle(p1, p2, p3, u1, v1, u2, v2, u3, v3, alpha, r)
    Citizen.InvokeNative(NATIVE_DRAW_SPRITE_POLY,
        p1.x, p1.y, p1.z,
        p2.x, p2.y, p2.z,
        p3.x, p3.y, p3.z,
        r.red, r.green, r.blue, alpha,
        ATLAS_TXD, ATLAS_TEX,
        u1, v1, 1.0,
        u2, v2, 1.0,
        u3, v3, 1.0)
end

-- Streaming loop: keeps candidates fresh and starts/parks the DUI as needed
CreateThread(function()
    while not stopped do
        M.RefreshCandidates()

        if #candidates > 0 then
            lastActiveTime = GetGameTimer()
            ensureDui()
        elseif dui and not duiReleasing
            and GetGameTimer() - lastActiveTime > Config.DuiReleaseDelay then
            releaseDui()
        end

        Wait(Config.StreamInterval)
    end
end)

-- Draw loop
CreateThread(function()
    while not stopped do
        local sleep = 500

        if #candidates > 0 then
            sleep = 50

            if dui and textureReady and atlasReady then
                sleep = 0

                if sceneJson ~= sentSceneJson and GetGameTimer() - lastSceneSend >= SCENE_SEND_MIN_MS then
                    sendScene()
                end

                local camPos = GetFinalRenderedCamCoord()
                local now = nil   -- lazily computed network time for animated layers

                for _, r in ipairs(candidates) do
                    local layer   = r.layer
                    local corners = r.corners
                    local pos     = layer.position
                    local opacity = layer.opacity

                    if IsSphereVisible(pos.x, pos.y, pos.z, r.radius) then
                        if r.animated then
                            if not now then
                                local ms = (GetNetworkTimeAccurate and GetNetworkTimeAccurate()) or GetGameTimer()
                                if ms < 0 then ms = ms + 4294967296 end
                                now = ms / 1000
                            end

                            local d = M.DisplayLayer(layer, now, r.display, r.pose)
                            pos     = d.position
                            opacity = d.opacity
                            corners = Math.corners(d, r.animatedCorners, r.basis)
                        end

                        -- distance fade
                        local dist = math.sqrt(Math.distance2(camPos, pos))
                        local fade = Math.clamp((Config.DrawDistance + r.radius - dist) / Config.FadeDistance, 0, 1)
                        local alpha = math.floor(opacity * fade * 255)

                        if alpha > 0 then
                            -- which side of the layer is the camera on? (dot with right x up)
                            local b = r.basis
                            local facing =
                                (camPos.x - pos.x) * (b.ry * b.uz - b.rz * b.uy) +
                                (camPos.y - pos.y) * (b.rz * b.ux - b.rx * b.uz) +
                                (camPos.z - pos.z) * (b.rx * b.uy - b.ry * b.ux)

                            if facing >= 0 then
                                -- front face
                                drawTriangle(corners[3], corners[2], corners[1],
                                    r.u1, r.v1, r.u1, r.v0, r.u0, r.v0, alpha, r)
                                drawTriangle(corners[4], corners[3], corners[1],
                                    r.u0, r.v1, r.u1, r.v1, r.u0, r.v0, alpha, r)
                            elseif layer.doubleSided then
                                -- back face (reverse winding)
                                drawTriangle(corners[1], corners[2], corners[3],
                                    r.u0, r.v0, r.u1, r.v0, r.u1, r.v1, alpha, r)
                                drawTriangle(corners[1], corners[3], corners[4],
                                    r.u0, r.v0, r.u1, r.v1, r.u0, r.v1, alpha, r)
                            end
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

---------------------------------------------------------------------
-- Cleanup
---------------------------------------------------------------------
function M.Stop()
    stopped = true
    destroyDui()
    setOriginalHidden(false)
end

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        M.Stop()
    end
end)

