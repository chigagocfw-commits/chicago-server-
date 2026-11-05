

-- Free-camera editor for garage zones (polygon) and parking spots.
-- Frames are projected to screen space in Lua and streamed to the NUI as JSON.

Zone = Zone or {}

local S = nil          -- active editor session (nil when closed)
local sessionId = 0    -- bumped on start/end so stale camera threads exit

local function nui(name, data)
    Client.NUI(name, data)
end

function Zone.Active()
    return S ~= nil
end

--------------------------------------------------------------------------------
-- Camera math
--------------------------------------------------------------------------------

-- Returns forward, right, up unit vectors for a pitch/yaw (degrees)
local function basis(pitch, yaw)
    local p, y = math.rad(pitch), math.rad(yaw)
    local cp = math.cos(p)

    local fwd = vector3(-math.sin(y) * cp, math.cos(y) * cp, math.sin(p))
    local right = vector3(math.cos(y), math.sin(y), 0.0)
    local up = vector3(
        right.y * fwd.z - right.z * fwd.y,
        right.z * fwd.x - right.x * fwd.z,
        right.x * fwd.y - right.y * fwd.x
    )

    return fwd, right, up
end

local function dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

local function cameraBasis()
    local fwd, right, up = basis(S.pitch, S.yaw)
    local ty = math.tan(math.rad(S.fov) * 0.5)

    local aspect = GetAspectRatio(false)
    if not aspect or aspect <= 0 then aspect = 16 / 9 end

    return { pos = S.pos, fwd = fwd, right = right, up = up, tx = ty * aspect, ty = ty }
end

local NEAR = 0.15

-- World point -> normalized screen (0..1), or nil if behind the camera
local function project(cam, world)
    local d = world - cam.pos
    local depth = dot(d, cam.fwd)
    if depth < NEAR then return nil end

    local sx = 0.5 + (dot(d, cam.right) / (depth * cam.tx)) * 0.5
    local sy = 0.5 - (dot(d, cam.up) / (depth * cam.ty)) * 0.5
    return sx, sy
end

-- Projects a 3D segment, clipping it against the near plane
local function projectSegment(cam, a, b)
    local da = dot(a - cam.pos, cam.fwd)
    local db = dot(b - cam.pos, cam.fwd)

    if da < NEAR and db < NEAR then return nil end

    if da < NEAR then
        a = a + (b - a) * ((NEAR - da) / (db - da))
    end
    if db < NEAR then
        b = b + (a - b) * ((NEAR - db) / (da - db))
    end

    local ax, ay = project(cam, a)
    local bx, by = project(cam, b)
    if not ax or not bx then return nil end

    return ax, ay, bx, by
end

-- Casts a ray through screen position (sx, sy).
-- Returns worldPoint, isFloorPlaneFallback  (or nil)
local function raycast(cam, sx, sy)
    local dir = cam.fwd
        + cam.right * ((sx - 0.5) * 2.0 * cam.tx)
        + cam.up * ((0.5 - sy) * 2.0 * cam.ty)

    local len = #dir
    if len < 1.0e-6 then return nil end
    dir = dir / len

    local origin = cam.pos
    local target = origin + dir * 600.0

    local probe = _ENV["StartExpensiveSynchronousShapeTestLosProbe"]
    local handle = probe(origin.x, origin.y, origin.z, target.x, target.y, target.z, 17, PlayerPedId(), 7)
    local _, hit, endCoords = GetShapeTestResult(handle)

    if (hit == true or hit == 1) and endCoords then
        return vector3(endCoords.x, endCoords.y, endCoords.z), false
    end

    -- Fallback: intersect with the flat plane at the garage floor height
    local floorZ = S.floor
    if dir.z < -0.01 and floorZ < origin.z then
        local t = (floorZ - origin.z) / dir.z
        if t > 0 and t < 800 then
            return origin + dir * t, true
        end
    end

    return nil
end

-- Quantizers used when serialising frames
local function q4(v) return math.floor(v * 10000 + 0.5) end
local function q1(v) return math.floor(v * 10 + 0.5) end

--------------------------------------------------------------------------------
-- Change detection / undo history
--------------------------------------------------------------------------------

-- Compares `list` to a cached copy. For spots, compares by `.p`.
-- NOTE: the original only compares indexes 1..#list, so a removal that leaves
-- the leading entries untouched isn't detected here.
local function geometryChanged(list, useSpotPos)
    local cached = S.geometryPoints
    local changed = not cached

    if not changed then
        for i = 1, #list do
            local value = (useSpotPos and list[i].p) or list[i]
            if cached[i] ~= value then
                changed = true
                break
            end
        end
    end

    if changed then
        cached = {}
        for i = 1, #list do
            cached[i] = (useSpotPos and list[i].p) or list[i]
        end
        S.geometryPoints = cached
    end

    return changed
end

local function pushHistory()
    local snapshot = {}

    if S.mode == "spots" then
        for i, sp in ipairs(S.spots) do
            snapshot[i] = { p = sp.p, w = sp.w, z0 = sp.z0, moved = sp.moved }
        end
    else
        for i, p in ipairs(S.pts) do
            snapshot[i] = p
        end
    end

    S.hist[#S.hist + 1] = snapshot
    if #S.hist > 80 then
        table.remove(S.hist, 1)
    end
end

--------------------------------------------------------------------------------
-- Frame builders (JSON strings for the NUI)
--------------------------------------------------------------------------------

local function buildZoneFrame(cam)
    local parts = {}
    local pts = S.pts
    local n = #pts

    -- vertices: [index, x, y]
    local verts = {}
    for i, p in ipairs(pts) do
        local sx, sy = project(cam, p)
        if sx then
            verts[#verts + 1] = ("[%d,%d,%d]"):format(i, q4(sx), q4(sy))
        end
    end

    -- edges: [index, x1, y1, x2, y2, lengthDm, midX, midY]
    local edges = {}
    local edgeCount = (n >= 3) and n or (n - 1)
    for i = 1, math.max(0, edgeCount) do
        local a = pts[i]
        local b = pts[i % n + 1]
        local ax, ay, bx, by = projectSegment(cam, a, b)

        if ax then
            local mx, my = project(cam, (a + b) / 2)
            local length = math.sqrt((b.x - a.x) ^ 2 + (b.y - a.y) ^ 2)

            edges[#edges + 1] = ("[%d,%d,%d,%d,%d,%d,%d,%d]"):format(
                i, q4(ax), q4(ay), q4(bx), q4(by), q1(length),
                mx and q4(mx) or -99999,
                my and q4(my) or -99999
            )
        end
    end

    -- hover cursor + ghost edges (from last point and back to first)
    local hoverJson = "null"
    local ghostJson = "[]"

    if S.hover then
        local h = S.hover
        local hx, hy = project(cam, h)

        if hx then
            hoverJson = ("[%d,%d,%d,%d,%d,%d]"):format(
                q4(hx), q4(hy), q1(h.x), q1(h.y), q1(h.z), S.hoverPlane and 1 or 0
            )
        end

        if n >= 1 and not S.drag then
            local ghost = {}

            local ax, ay, bx, by = projectSegment(cam, pts[n], h)
            local length = math.sqrt((h.x - pts[n].x) ^ 2 + (h.y - pts[n].y) ^ 2)
            if ax then
                ghost[#ghost + 1] = ("[%d,%d,%d,%d,%d]"):format(q4(ax), q4(ay), q4(bx), q4(by), q1(length))
            end

            if n >= 2 then
                ax, ay, bx, by = projectSegment(cam, h, pts[1])
                if ax then
                    ghost[#ghost + 1] = ("[%d,%d,%d,%d,-1]"):format(q4(ax), q4(ay), q4(bx), q4(by))
                end
            end

            ghostJson = "[" .. table.concat(ghost, ",") .. "]"
        end
    end

    -- context markers: anchor (index 0) + existing parking spots
    local ctx = {}
    local axs, ays = project(cam, S.anchor)
    if axs then
        ctx[#ctx + 1] = ("[0,%d,%d]"):format(q4(axs), q4(ays))
    end
    for i, spot in ipairs(S.ctxSpots) do
        local sx, sy = project(cam, spot)
        if sx then
            ctx[#ctx + 1] = ("[%d,%d,%d]"):format(i, q4(sx), q4(sy))
        end
    end

    if geometryChanged(pts, false) then
        S.area, S.perimeter = Utils.ZoneStats(pts)
        S.crossing = Utils.ZoneSelfIntersects(pts)
    end

    parts[#parts + 1] = '"v":[' .. table.concat(verts, ",") .. "]"
    parts[#parts + 1] = '"e":[' .. table.concat(edges, ",") .. "]"
    parts[#parts + 1] = '"h":' .. hoverJson
    parts[#parts + 1] = '"g":' .. ghostJson
    parts[#parts + 1] = '"c":[' .. table.concat(ctx, ",") .. "]"
    parts[#parts + 1] = ('"n":%d,"a":%d,"p":%d,"x":%s,"s":%d,"d":%d,"alt":%d'):format(
        n,
        q1(S.area),
        q1(S.perimeter),
        S.crossing and "true" or "false",
        S.sel or 0,
        S.drag and S.drag.i or 0,
        math.floor(S.pos.z - S.floor + 0.5)
    )

    return "{" .. table.concat(parts, ",") .. "}"
end

--------------------------------------------------------------------------------
-- Spots helpers
--------------------------------------------------------------------------------

-- Vehicle footprint size by garage type: { width, length } in meters
local SIZES = {
    car        = { 2.6, 5.4 },
    motorcycle = { 1.4, 2.6 },
    boat       = { 4.2, 11.0 },
    air        = { 13.0, 15.0 },
    all        = { 2.6, 5.4 },
}

-- Heading (degrees, GTA convention) from a direction vector
local function headingFromVector(v)
    return (math.deg(math.atan(-v.x, v.y)) + 360.0) % 360.0
end

-- Returns forward, right vectors for a heading
local function headingBasis(heading)
    local r = math.rad(heading)
    return vector3(-math.sin(r), math.cos(r), 0.0), vector3(math.cos(r), math.sin(r), 0.0)
end

-- Projects the footprint box + arrow markers of a spot.
-- Returns "x,y,x,y,..." for 9 points, or nil if any is off-screen.
local function spotBoxJson(cam, spot)
    local fwd, right = headingBasis(spot.w)
    local halfW = S.size[1] * 0.5
    local halfL = S.size[2] * 0.5
    local c = spot.p + vector3(0.0, 0.0, 0.05)

    local points = {
        c,
        c + right * halfW + fwd * halfL,
        c - right * halfW + fwd * halfL,
        c - right * halfW - fwd * halfL,
        c + right * halfW - fwd * halfL,
        c + fwd * (halfL + 1.1),
        c + fwd * (halfL + 0.25) - right * 0.8,
        c + fwd * (halfL + 0.25) + right * 0.8,
        c + fwd * (halfL + 2.6),
    }

    local out = {}
    for _, p in ipairs(points) do
        local sx, sy = project(cam, p)
        if not sx then return nil end
        out[#out + 1] = q4(sx)
        out[#out + 1] = q4(sy)
    end

    return table.concat(out, ",")
end

-- Which spot's footprint contains `world`? (prefers the selected one)
local function pickSpot(world)
    if not world then return nil end

    local halfW = S.size[1] * 0.5
    local halfL = S.size[2] * 0.5
    local found = nil

    for i, spot in ipairs(S.spots) do
        local d = world - spot.p

        if math.abs(d.z) < 3.0 then
            local fwd, right = headingBasis(spot.w)
            local alongRight = math.abs(d.x * right.x + d.y * right.y)
            local alongFwd = math.abs(d.x * fwd.x + d.y * fwd.y)

            if halfW >= alongRight and halfL >= alongFwd then
                if i == S.sel then return i end
                found = i
            end
        end
    end

    return found
end

-- Flags spots that overlap each other. Returns flags[i], count
local function computeOverlaps()
    local flags = {}
    local count = 0

    local limit = math.min(S.size[1], S.size[2]) * 0.92
    local limitSq = limit * limit

    for i = 1, #S.spots do
        for j = i + 1, #S.spots do
            local a = S.spots[i].p
            local b = S.spots[j].p
            local dsq = (a.x - b.x) ^ 2 + (a.y - b.y) ^ 2

            if limitSq > dsq and math.abs(a.z - b.z) < 3.0 then
                if not flags[i] then count = count + 1 end
                if not flags[j] then count = count + 1 end
                flags[j] = true
                flags[i] = true
            end
        end
    end

    return flags, count
end

local function buildSpotsFrame(cam)
    local parts = {}

    if geometryChanged(S.spots, true) then
        S.overlaps, S.overlapCount = computeOverlaps()
    end
    local flags = S.overlaps
    local badCount = S.overlapCount

    -- spot boxes: [index, headingDeg*10, overlapFlag, ...box]
    local spotsOut = {}
    for i, spot in ipairs(S.spots) do
        local box = spotBoxJson(cam, spot)
        if box then
            spotsOut[#spotsOut + 1] = ("[%d,%d,%d,%s]"):format(i, q1(spot.w), flags[i] and 1 or 0, box)
        end
    end

    -- ghost preview of the next spot + hover cursor
    local ghostJson = "null"
    local hoverJson = "null"

    if S.hover then
        local h = S.hover
        local hx, hy = project(cam, h)

        if hx then
            hoverJson = ("[%d,%d,%d,%d,%d,%d]"):format(
                q4(hx), q4(hy), q1(h.x), q1(h.y), q1(h.z), S.hoverPlane and 1 or 0
            )
        end

        if not S.drag and not S.over then
            local box = spotBoxJson(cam, { p = h, w = S.nextW })
            if box then
                ghostJson = ("[%d,%s]"):format(q1(S.nextW), box)
            end
        end
    end

    -- anchor marker
    local ctx = {}
    local ax, ay = project(cam, S.anchor)
    if ax then
        ctx[#ctx + 1] = ("[%d,%d]"):format(q4(ax), q4(ay))
    end

    -- existing zone outline (read-only context)
    local zoneOut = {}
    local zonePts = S.ctxZone
    for i = 1, #zonePts do
        local x1, y1, x2, y2 = projectSegment(cam, zonePts[i], zonePts[i % #zonePts + 1])
        if x1 then
            zoneOut[#zoneOut + 1] = ("[%d,%d,%d,%d]"):format(q4(x1), q4(y1), q4(x2), q4(y2))
        end
    end

    local selected = S.sel and S.spots[S.sel]

    parts[#parts + 1] = '"s":[' .. table.concat(spotsOut, ",") .. "]"
    parts[#parts + 1] = '"gh":' .. ghostJson
    parts[#parts + 1] = '"h":' .. hoverJson
    parts[#parts + 1] = '"c":[' .. table.concat(ctx, ",") .. "]"
    parts[#parts + 1] = '"z":[' .. table.concat(zoneOut, ",") .. "]"
    parts[#parts + 1] = ('"n":%d,"bad":%d,"sel":%d,"sw":%d,"d":%d,"dk":"%s","o":%d,"alt":%d,"max":%d'):format(
        #S.spots,
        badCount,
        S.sel or 0,
        selected and q1(selected.w) or -1,
        S.drag and S.drag.i or 0,
        S.drag and S.drag.kind or "",
        S.over or 0,
        math.floor(S.pos.z - S.floor + 0.5),
        Utils.MAX_SPOTS
    )

    return "{" .. table.concat(parts, ",") .. "}"
end

local function sendFrame(cam)
    local json = (S.mode == "spots") and buildSpotsFrame(cam) or buildZoneFrame(cam)

    if json ~= S.sent then
        S.sent = json
        SendNuiMessage('{"type":"zone:frame","data":' .. json .. "}")
    end
end

--------------------------------------------------------------------------------
-- Dragging
--------------------------------------------------------------------------------

-- Snaps to 5 degrees unless shift is held
local function snapAngle(angle)
    if S.shift then
        return (angle + 360.0) % 360.0
    end
    return (math.floor(angle / 5.0 + 0.5) * 5.0) % 360.0
end

local function applyDrag(world)
    local drag = S.drag
    if not drag or not world then return end

    if S.mode == "zone" then
        if S.pts[drag.i] then
            S.pts[drag.i] = world
        end
        return
    end

    local spot = S.spots[drag.i]
    if not spot then return end

    if drag.kind == "move" then
        spot.p = vector3(world.x + drag.off.x, world.y + drag.off.y, world.z)
        spot.moved = true
    else -- "rot"
        local delta = world - spot.p
        if math.sqrt(delta.x * delta.x + delta.y * delta.y) > 0.4 then
            spot.w = snapAngle(headingFromVector(delta))
            S.nextW = spot.w
        end
    end
end

--------------------------------------------------------------------------------
-- Camera loop
--------------------------------------------------------------------------------

local function startCameraLoop(session)
    CreateThread(function()
        local last = GetGameTimer()
        local focusAt = 0
        local hoverCache = nil
        local hoverRecheckAt = 0
        local lastPos, lastPitch, lastYaw = nil, nil, nil

        while S and sessionId == session do
            local now = GetGameTimer()
            local dt = math.min(0.1, (now - last) / 1000.0)
            last = now

            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)
            DisableControlAction(0, 199, true) -- pause
            DisableControlAction(0, 200, true) -- pause alt

            -- Movement (flat, relative to yaw)
            local yawRad = math.rad(S.yaw)
            local flatFwd = vector3(-math.sin(yawRad), math.cos(yawRad), 0.0)
            local flatRight = vector3(math.cos(yawRad), math.sin(yawRad), 0.0)
            local move = vector3(0.0, 0.0, 0.0)

            if IsDisabledControlPressed(0, 32) then move = move + flatFwd end   -- W
            if IsDisabledControlPressed(0, 33) then move = move - flatFwd end   -- S
            if IsDisabledControlPressed(0, 34) then move = move - flatRight end -- A
            if IsDisabledControlPressed(0, 35) then move = move + flatRight end -- D
            if IsDisabledControlPressed(0, 44) then move = move - vector3(0.0, 0.0, 1.0) end -- Q (down)
            if IsDisabledControlPressed(0, 38) then move = move + vector3(0.0, 0.0, 1.0) end -- E (up)

            if #move > 0.001 then
                local speed = 16.0
                if IsDisabledControlPressed(0, 21) then speed = speed * 3.0 end -- shift: fast
                if IsDisabledControlPressed(0, 36) then speed = speed * 0.3 end -- ctrl: slow
                S.pos = S.pos + (move / #move) * (speed * dt)
            end

            -- Keep camera within 260m of the anchor and within height limits
            local offset = vector3(S.pos.x - S.anchor.x, S.pos.y - S.anchor.y, 0.0)
            local dist = #offset
            if dist > 260.0 then
                S.pos = vector3(
                    S.anchor.x + offset.x / dist * 260.0,
                    S.anchor.y + offset.y / dist * 260.0,
                    S.pos.z
                )
            end

            if S.pos.z < S.floor + 1.5 then
                S.pos = vector3(S.pos.x, S.pos.y, S.floor + 1.5)
            end
            if S.pos.z > S.floor + 180.0 then
                S.pos = vector3(S.pos.x, S.pos.y, S.floor + 180.0)
            end

            if lastPos ~= S.pos then
                SetCamCoord(S.cam, S.pos.x, S.pos.y, S.pos.z)
                lastPos = S.pos
            end

            if lastPitch ~= S.pitch or lastYaw ~= S.yaw then
                SetCamRot(S.cam, S.pitch, 0.0, S.yaw, 2)
                lastPitch, lastYaw = S.pitch, S.yaw
            end

            -- Stream the world around the camera
            if focusAt <= now then
                SetFocusPosAndVel(S.pos.x, S.pos.y, S.pos.z, 0.0, 0.0, 0.0)
                focusAt = now + 400
            end

            HideHudAndRadarThisFrame()

            local cam = cameraBasis()

            -- Raycast under the cursor (cached unless something moved, or every 200ms)
            local reuse = hoverCache
                and now < hoverRecheckAt
                and hoverCache.pos == S.pos
                and hoverCache.pitch == S.pitch
                and hoverCache.yaw == S.yaw
                and hoverCache.x == S.cursor.x
                and hoverCache.y == S.cursor.y
                and hoverCache.tx == cam.tx
                and hoverCache.ty == cam.ty

            if not reuse then
                local hitPoint, isPlane = raycast(cam, S.cursor.x, S.cursor.y)
                hoverCache = {
                    pos = S.pos, pitch = S.pitch, yaw = S.yaw,
                    x = S.cursor.x, y = S.cursor.y, tx = cam.tx, ty = cam.ty,
                    hp = hitPoint, plane = isPlane,
                }
                hoverRecheckAt = now + 200
            end

            S.hoverPlane = hoverCache.plane
            S.hover = hoverCache.hp
            applyDrag(hoverCache.hp)

            if S.mode == "spots" then
                S.over = (S.drag and S.drag.i) or pickSpot(hoverCache.hp)
            end

            sendFrame(cam)
            Wait(0)
        end
    end)
end

--------------------------------------------------------------------------------
-- Start / End
--------------------------------------------------------------------------------

function Zone.Start(garage, mode)
    if S or type(garage) ~= "table" or type(garage.point) ~= "table" then
        return false
    end

    if not (Editor and Editor.IsOpen and Editor.IsOpen()) then
        return false
    end

    mode = (mode == "spots") and "spots" or "zone"

    local point = garage.point
    local anchor = vector3(
        (tonumber(point.x) or 0) + 0.0,
        (tonumber(point.y) or 0) + 0.0,
        (tonumber(point.z) or 0) + 0.0
    )
    local floorZ = anchor.z - 1.0

    -- Existing zone polygon (shown as context in spots mode, editable in zone mode)
    local ctxZone = {}
    local rawZone = {}
    if type(garage.zone) == "table" then
        rawZone = garage.zone.points or garage.zone
    end
    for _, p in ipairs(rawZone) do
        if type(p) == "table" and tonumber(p.x) and tonumber(p.y) and tonumber(p.z) then
            ctxZone[#ctxZone + 1] = vector3(p.x + 0.0, p.y + 0.0, p.z + 0.0)
        end
    end

    local gtype = tostring(garage.type or "car")

    -- Existing parking spots, snapped to the ground where possible
    local ctxSpots, spots = {}, {}
    local rawSpots = (type(garage.spots) == "table") and garage.spots or {}

    for _, s in ipairs(rawSpots) do
        if tonumber(s.x) and tonumber(s.y) then
            local z = (tonumber(s.z) or anchor.z) + 0.0
            ctxSpots[#ctxSpots + 1] = vector3(s.x + 0.0, s.y + 0.0, z)

            local found, groundZ = GetGroundZFor_3dCoord(s.x + 0.0, s.y + 0.0, z + 1.5, false)
            local pz
            if found and groundZ and groundZ > z - 6.0 then
                pz = groundZ
            else
                pz = z - 1.0
            end
            if gtype == "boat" and floorZ > pz then
                pz = floorZ
            end

            spots[#spots + 1] = {
                p = vector3(s.x + 0.0, s.y + 0.0, pz),
                w = (tonumber(s.w) or 0.0) % 360.0,
                z0 = z,
                moved = false,
            }
        end
    end

    sessionId = sessionId + 1

    -- Initial camera: above and behind the garage point, looking down
    local yaw = GetGameplayCamRot(2).z
    local pitch = -58.0
    local fwd = basis(pitch, yaw)
    local distance = math.max(26.0, (tonumber(garage.storeRadius) or 14.0) * 1.8)
    local startPos = anchor - fwd * distance

    local cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", startPos.x, startPos.y, startPos.z, pitch, 0.0, yaw, 55.0, false, 0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 700, true, true)

    S = {
        mode = mode,
        cam = cam,
        pos = startPos,
        pitch = pitch,
        yaw = yaw,
        fov = 55.0,
        anchor = anchor,
        floor = floorZ,
        gtype = gtype,
        size = SIZES[gtype] or SIZES.car,
        pts = (mode == "zone") and ctxZone or {},
        ctxSpots = ctxSpots,
        spots = spots,
        ctxZone = ctxZone,
        nextW = (#spots > 0 and spots[#spots].w) or (((yaw % 360.0) + 360.0) % 360.0),
        hist = {},
        cursor = { x = 0.5, y = 0.5 },
        shift = false,
        hover = nil,
        hoverPlane = false,
        drag = nil,
        sel = nil,
        over = nil,
        sent = "",
        turnAt = 0,
    }

    FreezeEntityPosition(PlayerPedId(), true)
    Client.SetFocus("zone")
    SetNuiFocusKeepInput(true)

    nui("zone:start", {
        mode = mode,
        label = garage.label or garage.id or "",
        max = (mode == "spots") and Utils.MAX_SPOTS or Utils.ZONE_MAX_POINTS,
        radius = tonumber(garage.storeRadius) or 14.0,
        size = S.size,
    })

    startCameraLoop(sessionId)
    return true
end

-- result: { points = {...} } | { spots = {...} } | nil (cancelled)
function Zone.End(result)
    if not S then return end

    local session = S
    S = nil
    sessionId = sessionId + 1

    RenderScriptCams(false, true, 600, true, true)

    local cam = session.cam
    SetTimeout(700, function()
        if DoesCamExist(cam) then
            DestroyCam(cam, false)
        end
    end)

    ClearFocus()
    FreezeEntityPosition(PlayerPedId(), false)

    if Editor and Editor.IsOpen and Editor.IsOpen() then
        Client.SetFocus("editor")
        nui("zone:end", { mode = session.mode, result = result })
    else
        Client.ReleaseFocus("zone")
        nui("zone:end", { mode = session.mode, result = nil })
    end
end

--------------------------------------------------------------------------------
-- NUI callbacks: shared camera / cursor
--------------------------------------------------------------------------------

-- tonumber that rejects NaN
local function num(value, default)
    value = tonumber(value)
    if value and value == value then return value end
    return default
end

RegisterNUICallback("zone:cursor", function(data, cb)
    if S and data then
        S.cursor = { x = num(data.x, 0.5), y = num(data.y, 0.5) }
        S.shift = data.shift == true
    end
    cb(1)
end)

RegisterNUICallback("zone:release", function(_, cb)
    if S then S.drag = nil end
    cb(1)
end)

RegisterNUICallback("zone:undo", function(_, cb)
    cb(1)
    if not S or #S.hist == 0 then return end

    local snapshot = table.remove(S.hist)
    if S.mode == "spots" then
        S.spots = snapshot
    else
        S.pts = snapshot
    end

    S.drag = nil
    S.sel = nil
end)

RegisterNUICallback("zone:look", function(data, cb)
    if S and data then
        S.yaw = (S.yaw - num(data.dx, 0) * 0.16) % 360.0
        S.pitch = Utils.Clamp(S.pitch - num(data.dy, 0) * 0.16, -89.0, 20.0)
    end
    cb(1)
end)

RegisterNUICallback("zone:fly", function(data, cb)
    if S and data then
        local fwd = basis(S.pitch, S.yaw)
        S.pos = S.pos + fwd * (-num(data.dz, 0) * 0.03)
    end
    cb(1)
end)

RegisterNUICallback("zone:home", function(_, cb)
    cb(1)
    if not S then return end

    local fwd = basis(S.pitch, S.yaw)
    S.pos = S.anchor - fwd * 30.0
end)

RegisterNUICallback("zone:cancel", function(_, cb)
    cb(1)
    Zone.End(nil)
end)

--------------------------------------------------------------------------------
-- NUI callbacks: zone polygon
--------------------------------------------------------------------------------

local function toPlainPoints(list)
    local out = {}
    for i, p in ipairs(list) do
        out[i] = { x = p.x, y = p.y, z = p.z }
    end
    return out
end

-- Updates the cursor from the payload and raycasts at it
local function raycastAtCursor(data)
    if data then
        S.cursor = { x = num(data.x, S.cursor.x), y = num(data.y, S.cursor.y) }
    end
    return raycast(cameraBasis(), S.cursor.x, S.cursor.y)
end

RegisterNUICallback("zone:add", function(data, cb)
    cb(1)
    if not (S and S.mode == "zone") then return end

    local hit = raycastAtCursor(data)
    if not hit or #S.pts >= Utils.ZONE_MAX_POINTS then return end

    pushHistory()
    S.pts[#S.pts + 1] = hit
    S.sel = #S.pts
end)

RegisterNUICallback("zone:grab", function(data, cb)
    cb(1)

    local i = data and math.floor(num(data.i, 0))
    if not (S and S.mode == "zone" and i and S.pts[i]) then return end

    pushHistory()
    S.sel = i
    S.drag = { kind = "move", i = i }
end)

RegisterNUICallback("zone:insert", function(data, cb)
    cb(1)

    local i = data and math.floor(num(data.i, 0))
    if not (S and S.mode == "zone" and i and S.pts[i] and #S.pts < Utils.ZONE_MAX_POINTS) then
        return
    end

    local a = S.pts[i]
    local b = S.pts[i % #S.pts + 1]

    pushHistory()
    table.insert(S.pts, i + 1, (a + b) / 2)

    S.drag = { kind = "move", i = i + 1 }
    S.sel = i + 1
end)

RegisterNUICallback("zone:remove", function(_, cb)
    cb(1)
    if not (S and S.mode == "zone" and #S.pts ~= 0) then return end

    pushHistory()
    local index = (S.sel and S.pts[S.sel] and S.sel) or #S.pts
    table.remove(S.pts, index)

    S.drag = nil
    S.sel = nil
end)

RegisterNUICallback("zone:clear", function(_, cb)
    cb(1)
    if not (S and S.mode == "zone" and #S.pts ~= 0) then return end

    pushHistory()
    S.pts = {}
    S.drag = nil
    S.sel = nil
end)

RegisterNUICallback("zone:save", function(_, cb)
    if not (S and S.mode == "zone") then
        return cb({ ok = false })
    end

    local n = #S.pts

    if n > 0 and n < 3 then
        return cb({ ok = false, message = _U("zone_min") })
    end

    if Utils.ZoneSelfIntersects(S.pts) then
        return cb({ ok = false, message = _U("zone_crossing") })
    end

    local points = toPlainPoints(S.pts)

    if n >= 3 and not Utils.SanitiseZone(points) then
        return cb({ ok = false, message = _U("zone_small") })
    end

    cb({ ok = true })
    Zone.End({ points = points })
end)

RegisterNUICallback("editor:zone", function(data, cb)
    cb({ ok = Zone.Start(data and data.garage, "zone") })
end)

--------------------------------------------------------------------------------
-- NUI callbacks: parking spots
--------------------------------------------------------------------------------

RegisterNUICallback("spots:add", function(data, cb)
    cb(1)
    if not (S and S.mode == "spots") then return end

    local hit = raycastAtCursor(data)
    if not hit or #S.spots >= Utils.MAX_SPOTS then return end

    pushHistory()
    S.spots[#S.spots + 1] = { p = hit, w = S.nextW, moved = true }
    S.sel = #S.spots
end)

RegisterNUICallback("spots:grab", function(data, cb)
    cb(1)

    local i = data and math.floor(num(data.i, 0))
    if not (S and S.mode == "spots" and i and S.spots[i]) then return end

    pushHistory()

    local spot = S.spots[i]
    local h = S.hover or spot.p

    S.drag = {
        kind = "move",
        i = i,
        off = vector3(spot.p.x - h.x, spot.p.y - h.y, 0.0), -- keeps the grab point stable
    }
    S.sel = i
    S.nextW = spot.w
end)

RegisterNUICallback("spots:rotate", function(data, cb)
    cb(1)

    local i = data and math.floor(num(data.i, 0))
    if not (S and S.mode == "spots" and i and S.spots[i]) then return end

    pushHistory()
    S.drag = { kind = "rot", i = i }
    S.sel = i
end)

RegisterNUICallback("spots:turn", function(data, cb)
    cb(1)
    if not (S and S.mode == "spots") then return end

    local i = (data and data.i and math.floor(num(data.i, 0))) or S.sel
    local spot = i and S.spots[i]
    if not spot then return end

    -- Coalesce rapid turns into a single undo step
    local now = GetGameTimer()
    if now - S.turnAt > 700 then
        pushHistory()
    end
    S.turnAt = now

    spot.w = (spot.w + num(data and data.deg, 0) + 360.0) % 360.0
    S.nextW = spot.w
    S.sel = i
end)

RegisterNUICallback("spots:clone", function(data, cb)
    cb(1)
    if not (S and S.mode == "spots" and #S.spots < Utils.MAX_SPOTS) then return end

    local i = S.sel or #S.spots
    local spot = S.spots[i]
    if not spot then return end

    local side = (data and num(data.side, 1) < 0) and -1 or 1
    local _, right = headingBasis(spot.w)
    local gap = S.size[1] + 0.35

    local newPos = spot.p + right * (side * gap)

    local found, groundZ = GetGroundZFor_3dCoord(newPos.x, newPos.y, newPos.z + 2.0, false)
    if found and groundZ and math.abs(groundZ - newPos.z) < 3.0 then
        newPos = vector3(newPos.x, newPos.y, groundZ)
    end

    pushHistory()
    table.insert(S.spots, i + 1, { p = newPos, w = spot.w, moved = true })
    S.sel = i + 1
end)

RegisterNUICallback("spots:remove", function(_, cb)
    cb(1)
    if not (S and S.mode == "spots" and #S.spots ~= 0) then return end

    pushHistory()
    local index = (S.sel and S.spots[S.sel] and S.sel) or #S.spots
    table.remove(S.spots, index)

    S.drag = nil
    S.sel = nil
end)

RegisterNUICallback("spots:clear", function(_, cb)
    cb(1)
    if not (S and S.mode == "spots" and #S.spots ~= 0) then return end

    pushHistory()
    S.spots = {}
    S.drag = nil
    S.sel = nil
end)

RegisterNUICallback("spots:save", function(_, cb)
    if not (S and S.mode == "spots") then
        return cb({ ok = false })
    end

    -- Moved/new spots are saved ~1m above the ground (0.5m for boats);
    -- untouched ones keep their original z.
    local zOffset = (S.gtype == "boat") and 0.5 or 1.0
    local out = {}

    for i, spot in ipairs(S.spots) do
        local z = (not spot.moved and spot.z0) or (spot.p.z + zOffset)

        out[i] = {
            x = Utils.Round(spot.p.x, 2),
            y = Utils.Round(spot.p.y, 2),
            z = Utils.Round(z, 2),
            w = Utils.Round(spot.w, 1),
        }
    end

    cb({ ok = true })
    Zone.End({ spots = out })
end)

RegisterNUICallback("editor:spots", function(data, cb)
    cb({ ok = Zone.Start(data and data.garage, "spots") })
end)

--------------------------------------------------------------------------------
-- Cleanup
--------------------------------------------------------------------------------

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() or not S then return end

    RenderScriptCams(false, false, 0, true, true)
    if DoesCamExist(S.cam) then
        DestroyCam(S.cam, false)
    end
    ClearFocus()
    FreezeEntityPosition(PlayerPedId(), false)
end)

