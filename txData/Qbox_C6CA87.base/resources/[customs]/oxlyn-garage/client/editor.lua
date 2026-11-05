

Editor = Editor or {}
Editor.open = false
Editor.placing = nil
Editor.preview = nil

local RESOURCE = GetCurrentResourceName()

-- Incremented whenever a placement starts/ends so stale placement threads exit
local placementToken = 0

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function sendNUI(action, data)
    Client.NUI(action, data)
end

local function round(v, decimals)
    return Utils.Round(v, decimals)
end

-- Callback result helper: always hand NUI a table
local function reply(cb, res)
    cb(res or { ok = false })
end

-- ---------------------------------------------------------------------------
-- Drawing
-- ---------------------------------------------------------------------------

local function drawText3D(x, y, z, text, scale)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    scale = scale or 0.32
    SetTextScale(scale, scale)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 220)
    SetTextDropshadow(0, 0, 0, 0, 200)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(sx, sy)
end

-- Draws a parking spot rectangle with a direction arrow
local function drawParkingSpot(x, y, z, heading, r, g, b, a, faint)
    local halfWidth, halfLength = 1.15, 2.5
    local rad = math.rad(heading)
    local cosH, sinH = math.cos(rad), math.sin(rad)

    local function corner(lx, ly)
        return vector3(
            x + lx * cosH - ly * sinH,
            y + lx * sinH + ly * cosH,
            z + 0.03
        )
    end

    local c1 = corner(-halfWidth, -halfLength)
    local c2 = corner(halfWidth, -halfLength)
    local c3 = corner(halfWidth, halfLength)
    local c4 = corner(-halfWidth, halfLength)

    local fillAlpha = math.floor(a * (faint and 0.35 or 0.55))

    -- Fill (both windings so it's visible from either side)
    DrawPoly(c1, c2, c3, r, g, b, fillAlpha)
    DrawPoly(c1, c3, c4, r, g, b, fillAlpha)
    DrawPoly(c3, c2, c1, r, g, b, fillAlpha)
    DrawPoly(c4, c3, c1, r, g, b, fillAlpha)

    -- Outline
    DrawLine(c1, c2, r, g, b, a)
    DrawLine(c2, c3, r, g, b, a)
    DrawLine(c3, c4, r, g, b, a)
    DrawLine(c4, c1, r, g, b, a)

    -- Arrow pointing along the heading
    local tip = corner(0, halfLength + 0.9)
    local left = corner(-0.5, halfLength + 0.2)
    local right = corner(0.5, halfLength + 0.2)
    DrawLine(left, tip, r, g, b, a)
    DrawLine(right, tip, r, g, b, a)
    DrawLine(corner(0, 0), tip, r, g, b, a)
end

local function drawRadius(x, y, z, radius, r, g, b, a)
    DrawMarker(25, x, y, z - 0.97,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        radius * 2.0, radius * 2.0, 1.0,
        r, g, b, a,
        false, false, 2, false, nil, nil, false)
end

local function drawZone(zone, r, g, b, a)
    local points = zone.points or zone
    local count = #points
    if count < 2 then return end

    for i = 1, count do
        local p = points[i]
        local q = points[(i % count) + 1]
        DrawLine(p.x, p.y, p.z + 0.08, q.x, q.y, q.z + 0.08, r, g, b, a)
        DrawLine(p.x, p.y, p.z + 0.08, p.x, p.y, p.z + 1.2, r, g, b, a)
    end
end

local function drawGarage(garage, selected)
    if not (garage and garage.point) then return end

    local point = garage.point
    local alpha = selected and 200 or 90

    -- Ground marker
    DrawMarker(1, point.x, point.y, point.z - 0.98,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        1.0, 1.0, 0.6,
        242, 243, 245, alpha,
        false, false, 2, false, nil, nil, false)

    -- Floating chevron
    DrawMarker(2, point.x, point.y, point.z + 0.9,
        0.0, 0.0, 0.0,
        0.0, 180.0, 0.0,
        0.35, 0.35, 0.35,
        242, 243, 245, alpha,
        true, false, 2, true, nil, nil, false)

    if not selected then
        drawText3D(point.x, point.y, point.z + 1.1, garage.label or garage.id or "", 0.3)
        return
    end

    -- Interaction radius
    drawRadius(point.x, point.y, point.z, tonumber(garage.radius) or 2.5, 61, 220, 151, 160)

    -- Store zone (polygon) or fallback store radius
    if garage.zone then
        local pts = garage.zone.points or garage.zone
        if #pts >= 3 then
            drawZone(garage.zone, 77, 124, 255, 230)
        end
    else
        drawRadius(point.x, point.y, point.z, tonumber(garage.storeRadius) or 14.0, 245, 181, 68, 110)
    end

    drawText3D(point.x, point.y, point.z + 1.3, garage.label or garage.id or "", 0.36)

    -- Parking spots with index labels
    for i, spot in ipairs(garage.spots or {}) do
        drawParkingSpot(spot.x, spot.y, spot.z, spot.w or 0.0, 111, 168, 255, 220, false)
        drawText3D(spot.x, spot.y, spot.z + 0.9, tostring(i), 0.4)
    end
end

local function startRenderLoop()
    CreateThread(function()
        while Editor.open do
            -- Skip drawing while the zone editor is active
            if not (Zone and Zone.Active()) then
                local playerCoords = GetEntityCoords(PlayerPedId())
                local preview = Editor.preview

                -- Nearby garages (excluding the one being previewed)
                for _, garage in ipairs(Garage.List) do
                    if not (preview and garage.id == preview.id) then
                        local p = garage.point
                        if #(playerCoords - vector3(p.x, p.y, p.z)) < 160.0 then
                            drawGarage(garage, false)
                        end
                    end
                end

                -- Previewed garage, highlighted
                if preview and preview.point then
                    local p = preview.point
                    if #(playerCoords - vector3(p.x, p.y, p.z)) < 400.0 then
                        drawGarage(preview, true)
                    end
                end

                -- Placement ghost
                local placing = Editor.placing
                if placing then
                    if placing.kind == "spot" then
                        drawParkingSpot(placing.x, placing.y, placing.z, placing.w, 61, 220, 151, 230, false)
                    else
                        DrawMarker(1, placing.x, placing.y, placing.z - 0.98,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            1.0, 1.0, 0.6,
                            61, 220, 151, 170,
                            false, false, 2, false, nil, nil, false)

                        local radius = (preview and tonumber(preview.radius)) or 2.5
                        drawRadius(placing.x, placing.y, placing.z, radius, 61, 220, 151, 120)
                    end
                end
            end

            Wait(0)
        end
    end)
end

-- ---------------------------------------------------------------------------
-- Position helpers
-- ---------------------------------------------------------------------------

local function getPlayerPosition()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)

    return {
        x = round(coords.x, 2),
        y = round(coords.y, 2),
        z = round(coords.z, 2),
        w = round(heading, 1),
        street = GetStreetNameFromHashKey(streetHash),
    }
end

local function getVehiclePosition()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return nil end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then return nil end

    local coords = GetEntityCoords(vehicle)
    return {
        x = round(coords.x, 2),
        y = round(coords.y, 2),
        z = round(coords.z, 2),
        w = round(GetEntityHeading(vehicle), 1),
    }
end

local function rotationToDirection(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local cosX = math.abs(math.cos(x))
    return vector3(-math.sin(z) * cosX, math.cos(z) * cosX, math.sin(x))
end

-- Returns (coords, hitSomething)
local function getAimPoint()
    local camCoords = GetGameplayCamCoord()
    local dir = rotationToDirection(GetGameplayCamRot(2))
    local target = camCoords + dir * 80.0

    local handle = StartExpensiveSynchronousShapeTestLosProbe(
        camCoords.x, camCoords.y, camCoords.z,
        target.x, target.y, target.z,
        1, PlayerPedId(), 4)
    local _, hit, endCoords = GetShapeTestResult(handle)

    if hit == 1 then
        return endCoords, true
    end

    -- Nothing hit: fall back to a point 6m ahead, snapped to the ground
    local ahead = GetEntityCoords(PlayerPedId()) + dir * 6.0
    local found, groundZ = GetGroundZFor_3dCoord(ahead.x, ahead.y, ahead.z + 5.0, false)
    return vector3(ahead.x, ahead.y, (found and groundZ) or ahead.z), false
end

-- ---------------------------------------------------------------------------
-- Placement
-- ---------------------------------------------------------------------------

function Editor.StartPlacement(kind)
    if not Editor.open or Editor.placing then return end

    placementToken = placementToken + 1
    local myToken = placementToken

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    Editor.placing = {
        kind = (kind == "spot") and "spot" or "point",
        x = coords.x,
        y = coords.y,
        z = coords.z,
        w = GetEntityHeading(ped),
        vehicle = false,
    }

    Client.ReleaseFocus("editor")
    sendNUI("placement:start", {
        kind = Editor.placing.kind,
        key = Config.Interaction.keyLabel or "E",
    })

    CreateThread(function()
        local lastSent = 0

        while Editor.placing and placementToken == myToken and Editor.open do
            local placing = Editor.placing
            local playerPed = PlayerPedId()

            if IsPedInAnyVehicle(playerPed, false) then
                -- In a vehicle: place at the vehicle's position/heading
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                local vCoords = GetEntityCoords(vehicle)
                placing.vehicle = true
                placing.x, placing.y, placing.z = vCoords.x, vCoords.y, vCoords.z
                placing.w = GetEntityHeading(vehicle)
            else
                -- On foot: place where the camera is aiming
                local aim = getAimPoint()
                placing.vehicle = false
                placing.x, placing.y, placing.z = aim.x, aim.y, aim.z

                -- Scroll wheel / arrow keys rotate; 45 snaps 90 degrees
                for _, control in ipairs({ 14, 15, 16, 17, 99, 100, 45 }) do
                    DisableControlAction(0, control, true)
                end

                if IsDisabledControlJustPressed(0, 14)
                    or IsDisabledControlJustPressed(0, 16)
                    or IsDisabledControlJustPressed(0, 99) then
                    placing.w = (placing.w + 5.0) % 360
                elseif IsDisabledControlJustPressed(0, 15)
                    or IsDisabledControlJustPressed(0, 17)
                    or IsDisabledControlJustPressed(0, 100) then
                    placing.w = (placing.w - 5.0) % 360
                end

                if IsDisabledControlJustPressed(0, 45) then
                    placing.w = (placing.w + 90.0) % 360
                end
            end

            -- Block attack/aim/phone/pause menu while placing
            for _, control in ipairs({ 24, 25, 140, 141, 142, 199, 200 }) do
                DisableControlAction(0, control, true)
            end

            -- Throttled live update to the UI
            local now = GetGameTimer()
            if now - lastSent > 90 then
                lastSent = now
                sendNUI("placement:update", {
                    x = round(placing.x, 2),
                    y = round(placing.y, 2),
                    z = round(placing.z, 2),
                    w = round(placing.w, 1),
                    vehicle = placing.vehicle,
                })
            end

            -- Confirm / cancel
            if IsControlJustReleased(0, Config.Interaction.key or 38) then
                Editor.EndPlacement(true)
            elseif IsControlJustReleased(0, 177)
                or IsControlJustReleased(0, 194)
                or IsControlJustReleased(0, 202) then
                Editor.EndPlacement(false)
            end

            Wait(0)
        end
    end)
end

function Editor.EndPlacement(confirmed)
    local placing = Editor.placing
    if not placing then return end

    Editor.placing = nil
    placementToken = placementToken + 1

    local result = nil
    if confirmed then
        result = {
            x = round(placing.x, 2),
            y = round(placing.y, 2),
            z = round(placing.z, 2),
            w = round(placing.w, 1),
        }
    end

    if Editor.open then
        Client.SetFocus("editor")
        sendNUI("placement:end", { kind = placing.kind, result = result })
    end
end

-- ---------------------------------------------------------------------------
-- Open / close
-- ---------------------------------------------------------------------------

function Editor.Open()
    if Editor.open or Client.Busy() then return end

    Framework.TriggerCallback("admin:open", function(res)
        if not res then return end

        if not res.ok then
            return Client.Notify(res.message or _U("no_permission"), "error")
        end

        if Editor.open or Client.Busy() then return end

        Editor.open = true
        Editor.preview = nil
        Client.SetFocus("editor")

        sendNUI("editor:open", {
            garages = Utils.Arr(res.garages),
            me = getPlayerPosition(),
            vehicle = getVehiclePosition(),
            defaults = res.defaults,
            settings = res.settings or Client.Settings,
            presets = res.presets or Utils.PRESETS,
            target = Garage.TargetResource(),
        })

        startRenderLoop()
    end)
end

function Editor.Close()
    if not Editor.open then return end

    if Zone and Zone.Active() then
        Zone.End(nil)
    end

    if Editor.placing then
        Editor.placing = nil
        placementToken = placementToken + 1
    end

    Editor.open = false
    Editor.preview = nil
    Client.ReleaseFocus("editor")
    sendNUI("editor:close")
end

function Editor.IsOpen()
    return Editor.open
end

function Editor.OnSync(garages)
    if not Editor.open then return end
    sendNUI("editor:garages", { garages = Utils.Arr(garages) })
end

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------

RegisterNetEvent(RESOURCE .. ":client:openEditor", function()
    CreateThread(function()
        Wait(50)
        Editor.Open()
    end)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= RESOURCE then return end
    Editor.placing = nil
end)

-- ---------------------------------------------------------------------------
-- NUI callbacks
-- ---------------------------------------------------------------------------

RegisterNUICallback("editor:close", function(_, cb)
    Editor.Close()
    cb(1)
end)

RegisterNUICallback("editor:myPosition", function(_, cb)
    cb(getPlayerPosition())
end)

RegisterNUICallback("editor:myVehicle", function(_, cb)
    cb(getVehiclePosition() or false)
end)

RegisterNUICallback("editor:myVehicleModel", function(_, cb)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return cb(false)
    end

    local modelHash = GetEntityModel(vehicle)
    local modelName = (GetDisplayNameFromVehicleModel(modelHash) or ""):lower()

    -- Livery: prefer mod slot 48, fall back to the native livery
    local livery = GetVehicleMod(vehicle, 48)
    if livery == -1 then
        livery = GetVehicleLivery(vehicle)
    end

    -- Extras that exist and are currently turned on
    local extras = {}
    for extra = 0, 20 do
        if DoesExtraExist(vehicle, extra) and IsVehicleExtraTurnedOn(vehicle, extra) then
            extras[#extras + 1] = extra
        end
    end

    cb({
        model = modelName,
        exact = modelName ~= "",
        label = Props.Label(modelHash),
        livery = (livery and livery >= 0) and livery or -1,
        extras = extras,
    })
end)

RegisterNUICallback("editor:pick", function(data, cb)
    cb(1)
    Editor.StartPlacement((data and data.kind) or "point")
end)

RegisterNUICallback("editor:preview", function(data, cb)
    if data and type(data.garage) == "table" then
        Editor.preview = data.garage
    else
        Editor.preview = nil
    end
    cb(1)
end)

RegisterNUICallback("editor:teleport", function(data, cb)
    cb(1)

    local coords = data and Utils.Coords(data.coords)
    if not coords then return end

    local ped = PlayerPedId()
    local entity = ped
    if IsPedInAnyVehicle(ped, false) then
        entity = GetVehiclePedIsIn(ped, false)
    end

    SetEntityCoords(entity, coords.x, coords.y, coords.z + 0.5, false, false, false, false)
    if coords.w then
        SetEntityHeading(entity, coords.w)
    end
end)

RegisterNUICallback("editor:save", function(data, cb)
    Framework.TriggerCallback("admin:save", function(res)
        if res and res.ok then
            Client.Notify(res.message, "success")
        elseif res then
            Client.Notify(res.message or _U("editor_invalid", "?"), "error")
        end
        reply(cb, res)
    end, data and data.garage, data and data.previousId)
end)

RegisterNUICallback("editor:saveSettings", function(data, cb)
    Framework.TriggerCallback("admin:saveSettings", function(res)
        if res and res.ok then
            Client.Notify(res.message, "success")
            if type(res.settings) == "table" then
                Client.ApplySettings(res.settings)
            end
        elseif res then
            Client.Notify(res.message or _U("no_permission"), "error")
        end
        reply(cb, res)
    end, data and data.settings)
end)

RegisterNUICallback("editor:resetSettings", function(_, cb)
    Framework.TriggerCallback("admin:resetSettings", function(res)
        if res and res.ok then
            Client.Notify(res.message, "success")
            if type(res.settings) == "table" then
                Client.ApplySettings(res.settings)
            end
        elseif res then
            Client.Notify(res.message or _U("no_permission"), "error")
        end
        reply(cb, res)
    end)
end)

RegisterNUICallback("editor:delete", function(data, cb)
    Framework.TriggerCallback("admin:delete", function(res)
        if res and res.ok then
            Client.Notify(res.message, "success")
        elseif res then
            Client.Notify(res.message, "error")
        end
        reply(cb, res)
    end, data and data.id)
end)

