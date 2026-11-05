



if IsDuplicityVersion() then return end

-- State bag key prefix — matches eventName ("bablo-animations:")
local eventPrefix = GetCurrentResourceName() .. ":"

-- Per-player looped ptfx handle table keyed by server ID
local otherPlayerPtfxHandles = {}

-- Local player's current looped ptfx handle (nil when none active)
local localPtfxHandle = nil

-- Name of the currently loaded ptfx asset for local player (nil when none)
local localPtfxAsset  = nil

-- Globals read/written by c_funcs.lua (declared here so they exist before use)
ChosenAnimOptions     = nil
AnimationThreadStatus = false
PtfxPrompt            = false
PtfxNotif             = false

-- ─── PtfxThis(asset) ─────────────────────────────────────────────────────────
-- Requests `asset` and blocks until it is loaded, then calls
-- UseParticleFxAsset so the next StartParticleFx* call uses it.

function PtfxThis(asset)
    while not HasNamedPtfxAssetLoaded(asset) do
        RequestNamedPtfxAsset(asset)
        Wait(10)
    end
    UseParticleFxAsset(asset)
end

-- ─── PtfxStartDirect() ───────────────────────────────────────────────────────
-- Reads ptfx parameters from LocalPlayer.state (written by s_main.lua's
-- ptfx:sync handler) and starts a looped networked particle on the local ped.
-- Returns true on success, false if data is missing or player not in animation.

function PtfxStartDirect()
    local isInAnim = LocalPlayer.state.isInAnimation
    if not isInAnim then
        if not PtfxPrompt then
            Trace("PtfxStartDirect: Animation not active, skipping")
            return false
        end
    end

    -- Stop any previously running local ptfx first
    PtfxStopDirect()

    -- Read all ptfx parameters from the local player's state bag
    local playerState = LocalPlayer.state
    local ptfxAsset  = playerState[eventPrefix .. "ptfxAsset"]
    local ptfxName   = playerState[eventPrefix .. "ptfxName"]
    local ptfxOffset = playerState[eventPrefix .. "ptfxOffset"]
    local ptfxRot    = playerState[eventPrefix .. "ptfxRot"]
    local ptfxBone   = playerState[eventPrefix .. "ptfxBone"]
    local ptfxScale  = playerState[eventPrefix .. "ptfxScale"] or 1
    local ptfxColor  = playerState[eventPrefix .. "ptfxColor"]

    if not (ptfxAsset and ptfxName and ptfxOffset) or not ptfxRot then
        Trace("PtfxStartDirect: Missing PTFX data")
        return false
    end

    local localPed = PlayerPedId()

    -- Determine which bone to attach the particle to.
    -- Prefer the numeric bone index from ptfxBone; fall back to the "VFX"
    -- named bone on the ptfxName entity.
    local boneIdx
    if ptfxBone and GetPedBoneIndex(localPed, ptfxBone) then
        boneIdx = GetPedBoneIndex(localPed, ptfxBone)
    else
        boneIdx = GetEntityBoneIndexByName(ptfxName, "VFX")
    end

    -- If a prop net ID was synced, attach the particle to that prop instead of
    -- the ped.
    local targetEntity  = localPed
    local ptfxPropNetId = playerState[eventPrefix .. "ptfxPropNet"]
    if ptfxPropNetId then
        local propEntity = NetToObj(ptfxPropNetId)
        if DoesEntityExist(propEntity) then
            targetEntity = propEntity
        end
    end

    -- Load asset and start the looped particle
    PtfxThis(ptfxAsset)
    localPtfxAsset = ptfxAsset

    localPtfxHandle = StartNetworkedParticleFxLoopedOnEntityBone(
        ptfxName,
        targetEntity,
        ptfxOffset.x, ptfxOffset.y, ptfxOffset.z,
        ptfxRot.x,    ptfxRot.y,    ptfxRot.z,
        boneIdx,
        ptfxScale + 0.0,
        false, false, false
    )

    -- Apply optional colour / alpha overrides
    if ptfxColor then
        local colorEntry = ptfxColor
        -- If the config provides an array of colour options, pick one at random
        if colorEntry[1] and type(colorEntry[1]) == "table" then
            colorEntry = colorEntry[math.random(1, #colorEntry)]
        end
        if colorEntry.A then
            SetParticleFxLoopedAlpha(localPtfxHandle, colorEntry.A)
        end
        if colorEntry.R then
            SetParticleFxLoopedColour(
                localPtfxHandle,
                colorEntry.R / 255,
                colorEntry.G / 255,
                colorEntry.B / 255,
                false
            )
        end
    end

    Trace("PtfxStartDirect: Started particle " .. tostring(localPtfxHandle))

    -- Mark local player state so other clients' state-bag handler fires
    LocalPlayer.state:set(eventPrefix .. "ptfx", true, true)

    return true
end

-- ─── PtfxStopDirect() ────────────────────────────────────────────────────────
-- Stops and removes the local player's active looped particle (if any) and
-- unloads the ptfx asset.

function PtfxStopDirect()
    Trace("PtfxStopDirect: Stopping particle " .. tostring(localPtfxHandle))

    if localPtfxHandle then
        if DoesParticleFxLoopedExist(localPtfxHandle) then
            StopParticleFxLooped(localPtfxHandle, false)
        end
        RemoveParticleFx(localPtfxHandle, false)
        localPtfxHandle = nil
    end

    if localPtfxAsset then
        RemoveNamedPtfxAsset(localPtfxAsset)
        localPtfxAsset = nil
    end

    -- Clear the local player's state bag flag
    LocalPlayer.state:set(eventPrefix .. "ptfx", nil, true)
end

-- ─── PtfxStart / PtfxStop ────────────────────────────────────────────────────
-- Public aliases kept for call-site compatibility with c_funcs.lua.

function PtfxStart()
    return PtfxStartDirect()
end

function PtfxStop()
    PtfxStopDirect()
end

-- ─── PtfxForceStopAll() ──────────────────────────────────────────────────────
-- Immediately stops all active particles: the local player's and any entry in
-- the other-player handles cache.

function PtfxForceStopAll()
    Trace("PtfxForceStopAll: Force stopping all particles")

    PtfxPrompt = false
    PtfxNotif  = false
    PtfxStopDirect()

    -- Also clean up any leftover handle cached under our own server ID
    local myServerId = GetPlayerServerId(PlayerId())
    local ownHandle  = otherPlayerPtfxHandles[myServerId]
    if ownHandle then
        if DoesParticleFxLoopedExist(ownHandle) then
            StopParticleFxLooped(ownHandle, false)
        end
        RemoveParticleFx(ownHandle, false)
        otherPlayerPtfxHandles[myServerId] = nil
    end
end

-- ─── State-bag handler: other players' particles ─────────────────────────────
-- Watches the "bablo-animations:ptfx" state bag key on every player.
-- When a remote player starts or stops their ptfx animation, this handler
-- spawns or removes a looped particle on their ped.

AddStateBagChangeHandler(eventPrefix .. "ptfx", "", function(bagName, _key, value, _reserved, _replicated)
    -- Parse the server ID from the bag name ("player:X" → X)
    local serverId   = tonumber(bagName:gsub("player:", ""), 10)
    local myServerId = GetPlayerServerId(PlayerId())

    -- Ignore our own state bag
    if serverId == myServerId then return end

    local existingHandle = otherPlayerPtfxHandles[serverId]

    -- Skip if neither value nor handle changed (both nil)
    if not existingHandle and not value then return end

    -- Resolve the player client and ped
    local playerClient = GetPlayerFromServerId(serverId)
    if playerClient <= 0 then return end

    local playerPed = GetPlayerPed(playerClient)
    if not DoesEntityExist(playerPed) then return end

    local playerState = Player(serverId).state

    if value then
        -- ── Start particle for this remote player ─────────────────────────
        local ptfxBone = playerState[eventPrefix .. "ptfxBone"]
        local ptfxName = playerState[eventPrefix .. "ptfxName"]

        -- Bone resolution: prefer numeric bone, fall back to "VFX" named bone
        local boneIdx
        if ptfxBone and GetPedBoneIndex(playerPed, ptfxBone) then
            boneIdx = GetPedBoneIndex(playerPed, ptfxBone)
        else
            boneIdx = GetEntityBoneIndexByName(ptfxName, "VFX")
        end

        -- Check for an associated prop
        local targetEntity  = playerPed
        local ptfxPropNetId = playerState[eventPrefix .. "ptfxPropNet"]
        if ptfxPropNetId then
            local propEntity = NetToObj(ptfxPropNetId)
            if DoesEntityExist(propEntity) then
                targetEntity = propEntity
            end
        end

        local ptfxAsset  = playerState[eventPrefix .. "ptfxAsset"]
        local ptfxOffset = playerState[eventPrefix .. "ptfxOffset"]
        local ptfxRot    = playerState[eventPrefix .. "ptfxRot"]
        local ptfxScale  = playerState[eventPrefix .. "ptfxScale"] or 1
        local ptfxColor  = playerState[eventPrefix .. "ptfxColor"]

        PtfxThis(ptfxAsset)

        local handle = StartNetworkedParticleFxLoopedOnEntityBone(
            ptfxName,
            targetEntity,
            ptfxOffset.x, ptfxOffset.y, ptfxOffset.z,
            ptfxRot.x,    ptfxRot.y,    ptfxRot.z,
            boneIdx,
            ptfxScale + 0.0,
            false, false, false
        )
        otherPlayerPtfxHandles[serverId] = handle

        -- Apply colour if provided
        if ptfxColor then
            local colorEntry = ptfxColor
            if colorEntry[1] and type(colorEntry[1]) == "table" then
                colorEntry = colorEntry[math.random(1, #colorEntry)]
            end
            SetParticleFxLoopedAlpha(handle, colorEntry.A)
            SetParticleFxLoopedColour(
                handle,
                colorEntry.R / 255,
                colorEntry.G / 255,
                colorEntry.B / 255,
                false
            )
        end

        Trace("Started PTFX for other player: " .. tostring(handle))
    else
        -- ── Stop particle for this remote player ──────────────────────────
        local handle = otherPlayerPtfxHandles[serverId]
        if handle then
            Trace("Stopped PTFX for other player: " .. tostring(handle))
            if DoesParticleFxLoopedExist(handle) then
                StopParticleFxLooped(handle, false)
            end
            RemoveParticleFx(handle, false)
        end

        -- Unload the remote player's ptfx asset
        local ptfxAsset = playerState[eventPrefix .. "ptfxAsset"]
        if ptfxAsset then
            RemoveNamedPtfxAsset(ptfxAsset)
        end

        otherPlayerPtfxHandles[serverId] = nil
    end
end)

-- ─── RunAnimationThread() ────────────────────────────────────────────────────
-- Starts the per-frame ptfx management thread (guard: only one instance runs).
--
-- The thread:
--  • While in animation + player is aiming → cancels the emote (ptfx + aim
--    are mutually exclusive) and disables the look/aim control inputs.
--  • While PtfxPrompt is active → shows an info notification and waits for the
--    player to press G (control 47) to fire the particle effect.
--    If ChosenAnimOptions.ptfxCanHold is true, the particle continues while
--    the button is held.
--  • Exits the loop and calls PtfxForceStopAll() when the animation ends.

function RunAnimationThread()
    if AnimationThreadStatus then return end
    AnimationThreadStatus = true

    local initialPed = PlayerPedId()

    -- Helper: is the player currently free-aiming or in an aim camera?
    local function isAiming(ped)
        return IsPlayerFreeAiming(ped)
            or IsAimCamActive()
            or IsAimCamThirdPersonActive()
    end

    CreateThread(function()
        local waitMs = 0

        while true do
            -- Exit if the thread was externally stopped
            if not AnimationThreadStatus then break end

            -- Exit if neither in-animation nor prompt is active
            local inAnim = LocalPlayer.state.isInAnimation
            if not inAnim and not PtfxPrompt then break end

            waitMs = 500  -- default slow poll

            if inAnim then
                waitMs = 0

                -- Cancel emote if the player starts aiming (incompatible with ptfx)
                if isAiming(initialPed) then
                    Main:cancelEmote()
                end

                -- Disable the left-aim controls so aiming doesn't interfere
                DisableControlAction(2, 140, true)
                DisableControlAction(2, 141, true)
                DisableControlAction(2, 142, true)
            end

            -- ── "Press G" prompt handling ─────────────────────────────────
            if PtfxPrompt and ChosenAnimOptions then
                waitMs = 0

                -- Show the info notification once
                if not PtfxNotif then
                    PtfxNotif = true
                    ShowInfo(ChosenAnimOptions.ptfxInfo)
                end

                -- Enable G and watch for press
                EnableControlAction(0, 47, true)
                if IsControlPressed(0, 47) then
                    if LocalPlayer.state.isInAnimation and PtfxPrompt then
                        local started = PtfxStart()
                        if started then
                            -- Wait ptfxWait ms (or default 300), bailing early
                            -- if the animation ends or prompt is cleared
                            local waitTotal  = ChosenAnimOptions.ptfxWait or 300
                            local elapsed    = 0
                            local earlyStop  = false

                            while elapsed < waitTotal do
                                Wait(10)
                                elapsed = elapsed + 10
                                if not LocalPlayer.state.isInAnimation or not PtfxPrompt then
                                    PtfxStop()
                                    earlyStop = true
                                    break
                                end
                            end

                            -- If ptfxCanHold: keep the particle running while G is held
                            if not earlyStop and ChosenAnimOptions.ptfxCanHold then
                                while IsControlPressed(0, 47)
                                    and LocalPlayer.state.isInAnimation
                                    and AnimationThreadStatus
                                    and PtfxPrompt
                                do
                                    Wait(5)
                                end
                            end

                            PtfxStop()
                        end
                    end
                end
            end

            Wait(waitMs)
        end

        -- ── Thread exit ───────────────────────────────────────────────────
        PtfxForceStopAll()
        HideInfo()
        AnimationThreadStatus = false
    end)
end