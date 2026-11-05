



-- Wait for eventName global to be set by s_main / c_main
while not eventName do Wait(0) end

if IsDuplicityVersion() then return end

-- ─────────────────────────────────────────────────────────────────────────────
-- Build AnimationPositioning.Controls from Config.AnimPos or fallbacks
-- ─────────────────────────────────────────────────────────────────────────────
AnimationPositioning = {}

local function buildControls()
    local ctrl = {}

    -- Try Config.AnimPos first (new-style unified config)
    if Config and Config.AnimPos then
        for _, entry in ipairs(Config.AnimPos) do
            if entry.type == "control" and entry.phase == "edit" then
                if entry.name and entry.code then
                    ctrl[entry.name] = entry.code
                end
            end
        end
    end

    -- Fall back to Config.AnimPosControls
    if not next(ctrl) and Config and Config.AnimPosControls then
        ctrl = Config.AnimPosControls
    end

    -- Hard-coded defaults if both are empty
    if not next(ctrl) then
        ctrl = {
            goUp        = 85,
            goDown      = 48,
            turnLeft    = 14,
            turnRight   = 15,
            goLeft      = 34,
            goRight     = 35,
            goForward   = 32,
            goBackward  = 33,
            confirm     = 38,
            cancel      = 200,
            pitchUp     = 10,
            pitchDown   = 11,
        }
    end

    return ctrl
end

AnimationPositioning.Controls      = buildControls()
AnimationPositioning.Offsets       = { x = 0.2, y = 0.2, z = 0.2, h = 3, rot = 2.0 }
AnimationPositioning.MovementSpeed = 0.1
AnimationPositioning.MaxDistance   = 5.0
AnimationPositioning.Lang = {
    move_up    = "Move up",
    move_down  = "Move down",
    move_lr    = "Move left/right",
    fwrd_bwrd  = "Forward/Backward",
    rotate     = "Rotate left/right",
    confirm    = "Confirm position",
    cancel     = "Cancel position",
}

-- Module-level state variables
local isEditing        = false   
local anchorObject     = nil     
local savedCoords      = nil     
local _unused4         = nil     
local keepFrozen       = true    
local anchorModelHash  = GetHashKey("prop_ld_can_01")   

-- ─── RegisterCommand: AnimAdjustCommand ──────────────────────────────────────
-- Toggles between StopEditing (if already editing) and StartEditing (if in anim)

if Config.AnimAdjustCommand then
    Citizen.CreateThread(function()
        TriggerEvent("chat:addSuggestion",
            string.format("/%s", Config.AnimAdjustCommand),
            Translate("ADJUST_COMMAND_HELP"),
            {}
        )
    end)

    RegisterCommand(Config.AnimAdjustCommand, function()
        if isEditing then
            AnimationPositioning:StopEditing()
        else
            if not Framework:isPlayerDead() then return end

            if Config.BlockAnimposAfterPlace and Main.lastAnimationWasPlaced then
                local msg = Translate("ANIMPOS_BLOCKED_AFTER_PLACE")
                    or "Cannot adjust position after placing animation"
                Framework:Notify(msg)
                return
            end

            if LocalPlayer.state.isInAnimation then
                AnimationPositioning:StartEditing()
            end
        end
    end)
end

-- ─── Helper: capsule + box collision check ───────────────────────────────────
-- Returns false if there is a geometry obstacle between `from` and `to`.
-- Used to validate movement steps before applying them.

local function isPathClear(from, to, radius)
    radius = radius or 0.65
    local flags = 415

    -- Capsule test (sweeps along the movement path)
    local ray1 = StartShapeTestCapsule(
        from.x, from.y, from.z,
        to.x,   to.y,   to.z,
        radius, flags, cache.ped, 7
    )
    local status1, hit1 = 1, false
    while status1 == 1 do
        status1, hit1 = GetShapeTestResult(ray1)
        Wait(0)
    end
    if hit1 then return false end

    -- Box test at the destination (player-sized)
    local halfSize = vector3(0.35, 0.35, 1.0)
    local ray2 = StartShapeTestBox(
        to.x, to.y, to.z + 0.9,
        halfSize.x, halfSize.y, halfSize.z,
        0.0, 0.0, 0.0,
        0, flags, cache.ped, 7
    )
    local status2, hit2 = 1, false
    while status2 == 1 do
        status2, hit2 = GetShapeTestResult(ray2)
        Wait(0)
    end
    if hit2 then return false end

    return true
end

-- ─────────────────────────────────────────────────────────────────────────────
-- AnimationPositioning:StartEditing()
-- Spawns an invisible anchor prop at the player's feet, attaches the ped to
-- it (so the ped's position is controlled via the prop), and starts EditingLoop.
-- ─────────────────────────────────────────────────────────────────────────────
function AnimationPositioning:StartEditing()
    local ped = cache.ped
    if IsPedInAnyVehicle(ped, false) then return end
    if not Config.AnimAdjustCommand then return end

    savedCoords = GetEntityCoords(ped)

    -- Load the model
    RequestModel(anchorModelHash)
    while not HasModelLoaded(anchorModelHash) do Wait(0) end

    -- Spawn prop at player position
    anchorObject = CreateObject(
        anchorModelHash,
        savedCoords.x, savedCoords.y, savedCoords.z,
        false, false, false
    )
    while not DoesEntityExist(anchorObject) do Wait(0) end

    -- Orient and configure the anchor
    SetEntityHeading(anchorObject, GetEntityHeading(ped))
    FreezeEntityPosition(anchorObject, true)
    SetEntityCollision(anchorObject, false, false)
    SetEntityAlpha(anchorObject, 0, false)
    SetEntityVisible(anchorObject, false, 0)

    -- Attach ped to the anchor (offset z by -0.07 so feet align)
    AttachEntityToEntity(
        ped, anchorObject, ped,
        0.0, 0.0, -0.07,
        0.0, 0.0, 0.0,
        false, false, false, false, 2, true
    )
    FreezeEntityPosition(ped, true)

    ShowEditAnim(true)
    isEditing = true

    -- Make ped semi-transparent to show editing state
    SetEntityAlpha(ped, 200, false)

    Citizen.CreateThread(function()
        AnimationPositioning:EditingLoop()
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- AnimationPositioning:StopEditing()
-- Detaches the ped from the anchor, restores its alpha, and cleans up.
-- A brief thread blocks ESC/BACK inputs to prevent accidental pause-menu.
-- ─────────────────────────────────────────────────────────────────────────────
function AnimationPositioning:StopEditing()
    local ped = cache.ped

    -- Detach and delete anchor
    if anchorObject then
        if IsEntityAttachedToEntity(ped, anchorObject) then
            DetachEntity(ped, true, true)
        end
        DeleteEntity(anchorObject)
        anchorObject = nil
    end

    FreezeEntityPosition(ped, false)

    -- Move ped slightly below saved coords (so it falls to the ground)
    if savedCoords then
        SetEntityCoords(ped, savedCoords.x, savedCoords.y, savedCoords.z - 1.0)
        savedCoords = nil
    end

    SetEntityAlpha(ped, 255, false)
    ShowEditAnim(false)
    isEditing = false
    SetPauseMenuActive(false)

    -- Block ESC/BACK for 600 ms to prevent accidental menu open
    Citizen.CreateThread(function()
        local endTime = GetGameTimer() + 600
        while GetGameTimer() < endTime do
            SetPauseMenuActive(false)
            DisableControlAction(0, 199, true)
            DisableControlAction(0, 200, true)
            DisableControlAction(1, 199, true)
            DisableControlAction(1, 200, true)
            Wait(0)
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- AnimationPositioning:ConfirmPosition()
-- Finalises the editing position:
--   1. Reads current object coords/rotation
--   2. Deletes anchor, unfreezes ped
--   3. Teleports ped to confirmed position (z - 0.99 for ground contact)
--   4. Applies entity rotation, sets animRot state bag
--   5. Syncs position to server for other clients
--   6. Replays the animation at the new position
-- ─────────────────────────────────────────────────────────────────────────────
function AnimationPositioning:ConfirmPosition()
    local ped = cache.ped

    -- Handle placed-animation freeze: keep frozen for 1 s then unfreeze
    if Main.lastAnimationWasPlaced then
        Citizen.CreateThread(function()
            keepFrozen = true

            -- Unfreeze timer thread
            Citizen.CreateThread(function()
                Citizen.Wait(1000)
                keepFrozen = false
            end)

            while keepFrozen do
                Wait(0)
                FreezeEntityPosition(ped, true)
                if not LocalPlayer.state.isInAnimation then
                    FreezeEntityPosition(ped, false)
                end
            end
        end)
    end

    if anchorObject and DoesEntityExist(anchorObject) then
        local objCoords   = GetEntityCoords(anchorObject)
        local rx, ry, rz  = table.unpack(GetEntityRotation(anchorObject, 2))

        -- Detach and delete anchor
        if IsEntityAttachedToEntity(ped, anchorObject) then
            DetachEntity(ped, true, true)
        end
        DeleteEntity(anchorObject)
        anchorObject = nil

        -- Place ped at confirmed position
        local confirmedZ = objCoords.z - 0.99
        SetEntityCoords(ped, objCoords.x, objCoords.y, confirmedZ)
        SetEntityRotation(ped, rx, ry, rz, 2)

        -- Sync rotation to state bag and server
        Main:setPlayerStateBag("animRot", { x = rx, y = ry, z = rz })
        TriggerServerEvent(
            eventName .. "server:syncAnimpos",
            vector3(objCoords.x, objCoords.y, confirmedZ),
            rx, ry, rz
        )

        -- Re-play the animation at the new position if still in animation
        local animName = LocalPlayer.state.isInAnimation
        if animName and type(animName) == "string" and Main and Main.animations then
            animName = LocalPlayer.state.isInAnimation
            if animName then
                Main:playAnimation(ped, animName, false, true)

                -- Apply rotation over 10 × 50 ms frames (smooth settle)
                Citizen.CreateThread(function()
                    for _ = 1, 10 do
                        SetEntityRotation(ped, rx, ry, rz, 2)
                        Wait(50)
                    end
                end)
            end
        end
    end

    FreezeEntityPosition(ped, true)
    Main.lastAnimationWasPlaced = true
    Main.hasObject              = false
    savedCoords                 = nil
    isEditing                   = false

    SetEntityAlpha(ped, 255, false)
    ShowEditAnim(false)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- AnimationPositioning:CleanupObject()
-- Detaches and deletes the anchor without confirming position.
-- Called from Main:cancelEmote when Main.hasObject is true.
-- ─────────────────────────────────────────────────────────────────────────────
function AnimationPositioning:CleanupObject()
    if not anchorObject then
        isEditing = false
        return
    end

    local ped = cache.ped
    if anchorObject then
        if IsEntityAttachedToEntity(ped, anchorObject) then
            DetachEntity(ped, true, true)
        end
        DeleteEntity(anchorObject)
        anchorObject = nil
    end

    FreezeEntityPosition(ped, false)
    Main.hasObject = false
end

-- ─────────────────────────────────────────────────────────────────────────────
-- AnimationPositioning:EditingLoop()
-- Per-frame loop that:
--   • Disables all movement/combat inputs
--   • Reads WASD/Q/E/numpad for forward/back/left/right/up/down movement
--   • Reads arrow keys for rotation
--   • Reads PgUp/PgDn for pitch adjustment
--   • Handles confirm (Enter) and cancel (Backspace/ESC/G)
--   • Smoothly moves the anchor using collision-checked step interpolation
-- ─────────────────────────────────────────────────────────────────────────────
function AnimationPositioning:EditingLoop()
    if not anchorObject then
        isEditing = false
        return
    end

    local ctrl    = AnimationPositioning.Controls
    local offsets = AnimationPositioning.Offsets
    local speed   = AnimationPositioning.MovementSpeed
    local ped     = cache.ped

    while isEditing do
        if not DoesEntityExist(anchorObject) then break end

        Wait(0)
        DisableControls()
        BlockWeaponWheelThisFrame()
        HideHudComponentThisFrame(19)
        SetPauseMenuActive(false)

        -- Read directional inputs
        local dx, dy, dz = 0.0, 0.0, 0.0

        if IsDisabledControlPressed(0, ctrl.goForward)  then dy =  offsets.y end
        if IsDisabledControlPressed(0, ctrl.goBackward) then dy = -offsets.y end
        if IsDisabledControlPressed(0, ctrl.goLeft)     then dx = -offsets.x end
        if IsDisabledControlPressed(0, ctrl.goRight)    then dx =  offsets.x end
        if IsDisabledControlPressed(0, ctrl.goUp)       then dz =  offsets.z end
        if IsDisabledControlPressed(0, ctrl.goDown)     then dz = -offsets.z end

        -- Heading adjustment
        if IsDisabledControlPressed(0, ctrl.turnLeft) then
            SetEntityHeading(anchorObject, GetEntityHeading(anchorObject) + offsets.h)
        end
        if IsDisabledControlPressed(0, ctrl.turnRight) then
            SetEntityHeading(anchorObject, GetEntityHeading(anchorObject) - offsets.h)
        end

        -- Pitch adjustment (entity rotation X axis)
        local rx, ry, rz = table.unpack(GetEntityRotation(anchorObject, 2))
        if IsDisabledControlPressed(0, ctrl.pitchUp)   then rx = rx + offsets.rot end
        if IsDisabledControlPressed(0, ctrl.pitchDown) then rx = rx - offsets.rot end
        SetEntityRotation(anchorObject, rx, ry, rz, 2)

        -- Confirm
        if IsDisabledControlPressed(0, ctrl.confirm) then
            AnimationPositioning:ConfirmPosition()
            break
        end

        -- Cancel — accept any of: cancel key (both input groups), or G (73)
        local cancelled =
            IsDisabledControlJustPressed(0, ctrl.cancel)  or
            IsDisabledControlJustPressed(1, ctrl.cancel)  or
            IsDisabledControlJustReleased(0, ctrl.cancel) or
            IsDisabledControlJustReleased(1, ctrl.cancel) or
            IsDisabledControlJustPressed(0, 73)           or
            IsDisabledControlJustPressed(1, 73)           or
            IsDisabledControlJustReleased(0, 73)          or
            IsDisabledControlJustReleased(1, 73)

        if cancelled then
            SetPauseMenuActive(false)
            Main:cancelEmote()
            AnimationPositioning:StopEditing()
            break
        end

        -- Apply position delta if there is any movement
        if dx ~= 0.0 or dy ~= 0.0 or dz ~= 0.0 then
            local targetPos = GetOffsetFromEntityInWorldCoords(
                anchorObject,
                dx * speed, dy * speed, dz * speed
            )

            -- Height cap: don't move above PlaceMaxHeight above the ped's Z
            if savedCoords and Config and Config.PlaceMaxHeight then
                local maxZ = savedCoords.z - 0.49 + Config.PlaceMaxHeight
                if targetPos.z > maxZ then
                    targetPos = vector3(targetPos.x, targetPos.y, maxZ)
                end
            end

            -- Distance / collision check: step toward target using short segments
            if savedCoords then
                local distToTarget = #(savedCoords - targetPos)
                if distToTarget < AnimationPositioning.MaxDistance then
                    local currentPos = GetEntityCoords(anchorObject)
                    local delta      = targetPos - currentPos
                    local deltaMag   = #delta

                    if deltaMag > 0.0 then
                        local stepSize  = 0.15
                        local numSteps  = math.max(1, math.ceil(deltaMag / stepSize))
                        local blocked   = false
                        local reachPos  = currentPos

                        for s = 1, numSteps do
                            local t       = s / numSteps
                            local nextPos = vector3(
                                currentPos.x + delta.x * t,
                                currentPos.y + delta.y * t,
                                currentPos.z + delta.z * t
                            )
                            if isPathClear(reachPos, nextPos, 0.6) then
                                reachPos = nextPos
                            else
                                blocked = true
                                break
                            end
                        end

                        SetEntityCoordsNoOffset(
                            anchorObject,
                            (blocked and reachPos or targetPos).x,
                            (blocked and reachPos or targetPos).y,
                            (blocked and reachPos or targetPos).z,
                            true, true, true
                        )
                    end
                end
            end
        end

        -- Re-attach ped to anchor if it detached (collision may have detached it)
        if not IsEntityAttachedToEntity(ped, anchorObject) then
            AttachEntityToEntity(
                ped, anchorObject, ped,
                0.0, 0.0, -0.07,
                0.0, 0.0, 0.0,
                false, false, false, false, 2, true
            )
        end
    end

    SetPauseMenuActive(true)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- DisableControls()
-- Disables all inputs that should be blocked while in editing mode.
-- ─────────────────────────────────────────────────────────────────────────────
local DISABLED_CONTROLS = {
    30, 31, 32, 33, 34, 35, 48, 85,
    266, 267, 268, 269,
    44, 20, 74, 14, 15, 37, 45,
    140, 141, 142,
    157, 158, 159, 160, 161, 162, 163, 164,
    199, 200,
}

function DisableControls()
    for _, code in ipairs(DISABLED_CONTROLS) do
        DisableControlAction(0, code, true)
    end
    DisableControlAction(1, 199, true)
    DisableControlAction(1, 200, true)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- ButtonMessage(text) / Button(glyph)
-- Scaleform helpers for the instructional-buttons overlay.
-- ─────────────────────────────────────────────────────────────────────────────
function ButtonMessage(text)
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
end

function Button(glyph)
    N_0xe83a3e3557a56640(glyph)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- setupScaleform(movieName)
-- Loads the instructional-buttons scaleform and populates it with the
-- position-adjustment controls. Returns the scaleform handle.
-- ─────────────────────────────────────────────────────────────────────────────
function setupScaleform(movieName)
    local handle = RequestScaleformMovie(movieName)
    while not HasScaleformMovieLoaded(handle) do Wait(1) end

    PushScaleformMovieFunction(handle, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(handle, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()

    local ctrl = AnimationPositioning.Controls
    local lang = AnimationPositioning.Lang

    -- Each slot: { slotId, buttonCode(s), labelText }
    -- buttonCode can be a number (single) or a table (two alternates shown together)
    local slots = {
        { 6, ctrl.goUp,       lang.move_up    },
        { 5, ctrl.goDown,     lang.move_down  },
        { 4, { ctrl.turnRight, ctrl.turnLeft }, lang.rotate    },
        { 3, { ctrl.goLeft,    ctrl.goRight  }, lang.move_lr   },
        { 2, { ctrl.goBackward,ctrl.goForward}, lang.fwrd_bwrd },
        { 1, ctrl.confirm,    lang.confirm    },
        { 0, ctrl.cancel,     lang.cancel     },
    }

    for _, slot in ipairs(slots) do
        local slotId, codes, label = slot[1], slot[2], slot[3]
        PushScaleformMovieFunction(handle, "SET_DATA_SLOT")
        PushScaleformMovieFunctionParameterInt(slotId)

        if type(codes) == "table" then
            for _, code in ipairs(codes) do
                Button(GetControlInstructionalButton(1, code, true))
            end
        else
            Button(GetControlInstructionalButton(1, codes, true))
        end

        ButtonMessage(label)
        PopScaleformMovieFunctionVoid()
    end

    PushScaleformMovieFunction(handle, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(handle, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(80)
    PopScaleformMovieFunctionVoid()

    return handle
end

-- ─── Net Event: client:syncAnimpos ───────────────────────────────────────────
-- Receives an animation position update broadcast by s_main.lua and applies
-- it to the appropriate remote player's ped (skips local ped).

RegisterNetEvent(eventName .. "client:syncAnimpos")
AddEventHandler(eventName .. "client:syncAnimpos", function(serverId, coords, rx, ry, rz)
    local player    = GetPlayerFromServerId(serverId)
    local playerPed = GetPlayerPed(player)

    if player == nil or playerPed == nil then return end
    if PlayerPedId() == playerPed then return end  -- skip self

    SetEntityCoordsNoOffset(playerPed, coords.x, coords.y, coords.z, true, true)
    SetEntityRotation(playerPed, rx, ry, rz)
end)