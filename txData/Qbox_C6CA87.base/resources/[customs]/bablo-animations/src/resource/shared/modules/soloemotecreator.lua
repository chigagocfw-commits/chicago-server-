



if IsDuplicityVersion() then return end
if not Config.EmoteCreatorCommand then return end

-- ─── Object definition ───────────────────────────────────────────────────────

SoloEmoteCreator = {
    isActive        = false,
    ped             = nil,
    camera          = nil,
    cameraDistance  = 2.5,
    cameraHeight    = 0.8,
    cameraAngle     = 0.0,
    cameraPitch     = 0.0,
    isWalking       = false,
    walkThread      = nil,

    anim = { dict = "", clip = "", label = "", name = "" },

    animOptions = {
        emoteLoop      = true,
        emoteMoving    = false,
        emoteDuration  = 0,
    },

    props = {
        prop             = "",
        propBone         = 57005,
        propPlacement    = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
        secondProp       = "",
        secondPropBone   = 18905,
        secondPropPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
    },

    ptfx = {
        ptfxAsset    = "",
        ptfxName     = "",
        ptfxBone     = 31086,
        ptfxNoProp   = true,
        ptfxPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0 },
        ptfxInfo     = "",
        ptfxWait     = 0,
        ptfxCanHold  = false,
    },

    ptfxHandle        = nil,
    propEntity        = nil,
    secondPropEntity  = nil,
    baseCoords        = nil,
    baseHeading       = 0.0,

    -- Skeleton bones available for prop attachment
    bones = {
        { id = 0,     name = "SKEL_ROOT",        label = "Pelvis/Root"      },
        { id = 11816, name = "SKEL_Spine0",       label = "Spine Base"       },
        { id = 14410, name = "SKEL_Spine1",       label = "Spine 1"          },
        { id = 14411, name = "SKEL_Spine2",       label = "Spine 2"          },
        { id = 24818, name = "SKEL_Spine3",       label = "Spine 3 (Upper)"  },
        { id = 31086, name = "SKEL_Head",         label = "Head"             },
        { id = 39317, name = "SKEL_Neck_1",       label = "Neck"             },
        { id = 18905, name = "SKEL_L_Hand",       label = "Left Hand"        },
        { id = 57005, name = "SKEL_R_Hand",       label = "Right Hand"       },
        { id = 61163, name = "SKEL_L_Forearm",    label = "Left Forearm"     },
        { id = 28252, name = "SKEL_R_Forearm",    label = "Right Forearm"    },
        { id = 45509, name = "SKEL_L_UpperArm",   label = "Left Upper Arm"   },
        { id = 40269, name = "SKEL_R_UpperArm",   label = "Right Upper Arm"  },
        { id = 46078, name = "SKEL_L_Thigh",      label = "Left Thigh"       },
        { id = 51826, name = "SKEL_R_Thigh",      label = "Right Thigh"      },
        { id = 63931, name = "SKEL_L_Calf",       label = "Left Calf"        },
        { id = 36864, name = "SKEL_R_Calf",       label = "Right Calf"       },
        { id = 14201, name = "SKEL_L_Foot",       label = "Left Foot"        },
        { id = 52301, name = "SKEL_R_Foot",       label = "Right Foot"       },
        { id = 26610, name = "SKEL_L_Finger00",   label = "Left Thumb"       },
        { id = 58866, name = "SKEL_R_Finger00",   label = "Right Thumb"      },
        { id = 26611, name = "SKEL_L_Finger01",   label = "Left Index"       },
        { id = 58867, name = "SKEL_R_Finger01",   label = "Right Index"      },
    },

    -- Internal: tracks all spawned prop entities for batch deletion
    _allPropEntities = {},
}

-- ─── SoloEmoteCreator:Start() ────────────────────────────────────────────────
-- Opens the solo emote creator: spawns a preview ped at the player's position,
-- hides the real player ped, activates a scripted camera, and shows the NUI.

function SoloEmoteCreator:Start()
    if self.isActive then return end
    self.isActive        = true
    self._allPropEntities = {}

    local playerPed     = PlayerPedId()
    local playerCoords  = GetEntityCoords(playerPed)
    self.baseCoords     = playerCoords
    self.baseHeading    = GetEntityHeading(playerPed)

    -- Spawn preview ped
    self.ped = self:CreatePed(playerCoords)
    if not self.ped then
        self:Stop()
        return
    end

    SetEntityHeading(self.ped, self.baseHeading)
    self:CreateCamera()

    -- Hide real player ped
    SetEntityAlpha(playerPed, 0, false)
    SetEntityVisible(playerPed, false, false)
    FreezeEntityPosition(playerPed, true)

    -- Open NUI creator panel
    Main:sendReactMessage("SHOW_MENU", { element = "showSoloEmoteCreator", toggle = true })
    Main:sendReactMessage("SOLO_EMOTE_CREATOR_INIT", {
        bones = self.bones,
        anim  = self.anim,
    })
    SetNuiFocus(true, true)

    self:CameraLoop()
end

-- ─── SoloEmoteCreator:Stop() ─────────────────────────────────────────────────
-- Cleans up all entities, camera, and resets state for next use.

function SoloEmoteCreator:Stop()
    self.isActive  = false
    self.isWalking = false

    self:DeleteAllProps()

    if self.ped and DoesEntityExist(self.ped) then
        DeleteEntity(self.ped)
        self.ped = nil
    end

    if self.camera then
        RenderScriptCams(false, true, 500, true, false)
        DestroyCam(self.camera, false)
        self.camera = nil
    end

    -- Restore real player ped
    local playerPed = PlayerPedId()
    SetEntityAlpha(playerPed,    255, false)
    SetEntityVisible(playerPed,  true, false)
    FreezeEntityPosition(playerPed, false)

    Main:sendReactMessage("SHOW_MENU", { element = "showSoloEmoteCreator", toggle = false })
    SetNuiFocus(false, false)

    self:StopPtfx()

    -- Reset all data tables to defaults
    self.anim        = { dict = "", clip = "", label = "", name = "" }
    self.animOptions = { emoteLoop = true, emoteMoving = false, emoteDuration = 0 }
    self.props       = {
        prop              = "",  propBone         = 57005,
        propPlacement     = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
        secondProp        = "",  secondPropBone   = 18905,
        secondPropPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
    }
    self.ptfx = {
        ptfxAsset = "", ptfxName = "", ptfxBone = 31086, ptfxNoProp = true,
        ptfxPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0 },
        ptfxInfo = "", ptfxWait = 0, ptfxCanHold = false,
    }
end

-- ─── SoloEmoteCreator:CreatePed(coords) ─────────────────────────────────────
-- Clones the local player ped and sets it up as an invisible preview ped.

function SoloEmoteCreator:CreatePed(coords)
    local clone = ClonePed(PlayerPedId(), false, false, true)
    if not clone or clone == 0 then return nil end

    SetEntityCoords(clone, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityCollision(clone, false, false)
    SetEntityInvincible(clone, true)
    SetBlockingOfNonTemporaryEvents(clone, true)
    SetPedFleeAttributes(clone, 0, false)
    SetPedCanRagdoll(clone, false)
    SetEntityAlpha(clone, 200, false)
    SetEntityAsMissionEntity(clone, true, true)
    FreezeEntityPosition(clone, true)

    return clone
end

-- ─── SoloEmoteCreator:CreateCamera() ────────────────────────────────────────
-- Creates and activates a scripted camera, positioned via UpdateCameraPosition.

function SoloEmoteCreator:CreateCamera()
    if self.camera then
        DestroyCam(self.camera, false)
    end
    self.camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    self:UpdateCameraPosition()
    SetCamActive(self.camera, true)
    RenderScriptCams(true, true, 500, true, false)
end

-- ─── SoloEmoteCreator:UpdateCameraPosition() ────────────────────────────────
-- Positions the scripted camera using spherical coordinates around the ped.

function SoloEmoteCreator:UpdateCameraPosition()
    if not (self.camera and self.ped) then return end

    local pedCoords = GetEntityCoords(self.ped)
    local cx = pedCoords.x
    local cy = pedCoords.y
    local cz = pedCoords.z + self.cameraHeight

    local angleRad = math.rad(self.cameraAngle)
    local pitchRad = math.rad(self.cameraPitch)

    -- Spherical → Cartesian
    local dist    = self.cameraDistance
    local cosPitch = math.cos(pitchRad)
    local camX = cx + dist * math.cos(angleRad) * cosPitch
    local camY = cy + dist * math.sin(angleRad) * cosPitch
    local camZ = cz + dist * math.sin(pitchRad)

    SetCamCoord(self.camera, camX, camY, camZ)
    PointCamAtCoord(self.camera, cx, cy, cz)
end

-- ─── SoloEmoteCreator:CameraLoop() ──────────────────────────────────────────
-- Lightweight loop that keeps the thread alive while the creator is active.

function SoloEmoteCreator:CameraLoop()
    Citizen.CreateThread(function()
        while self.isActive do
            Citizen.Wait(100)
        end
    end)
end

-- ─── SoloEmoteCreator:PlayAnimation() ───────────────────────────────────────
-- Plays self.anim on the preview ped. Returns false if dict/clip are empty
-- or the ped doesn't exist.

function SoloEmoteCreator:PlayAnimation()
    if not (self.anim.dict and self.anim.dict ~= "") then return false end
    if not (self.anim.clip and self.anim.clip ~= "") then return false end
    if not (self.ped and DoesEntityExist(self.ped)) then return false end

    RequestAnimDict(self.anim.dict)
    local timeout = 100
    while not HasAnimDictLoaded(self.anim.dict) and timeout > 0 do
        Citizen.Wait(10)
        timeout = timeout - 1
    end
    if not HasAnimDictLoaded(self.anim.dict) then return false end

    local flag = self.animOptions.emoteMoving and 51 or 1

    TaskPlayAnim(
        self.ped, self.anim.dict, self.anim.clip,
        2.0, -2.0, -1, flag, 0,
        false, false, false
    )
    return true
end

-- ─── SoloEmoteCreator:DeleteAllProps() ──────────────────────────────────────
-- Deletes all prop entities that were spawned during this session.

function SoloEmoteCreator:DeleteAllProps()
    if self._allPropEntities then
        for _, entity in ipairs(self._allPropEntities) do
            if entity and DoesEntityExist(entity) then
                DeleteEntity(entity)
            end
        end
        self._allPropEntities = {}
    end
    self.propEntity       = nil
    self.secondPropEntity = nil
end

-- ─── SoloEmoteCreator:StopPtfx() ────────────────────────────────────────────
-- Stops the active looped particle effect on the preview ped.

function SoloEmoteCreator:StopPtfx()
    if self.ptfxHandle then
        StopParticleFxLooped(self.ptfxHandle, false)
        self.ptfxHandle = nil
    end
end

-- ─── SoloEmoteCreator:StartPtfx() ───────────────────────────────────────────
-- Loads the ptfx asset and starts a looped particle on the preview ped.

function SoloEmoteCreator:StartPtfx()
    if not (self.ped and DoesEntityExist(self.ped)) then return end

    local ptfx = self.ptfx
    if not (ptfx.ptfxAsset and ptfx.ptfxAsset ~= "") then return end
    if not (ptfx.ptfxName  and ptfx.ptfxName  ~= "") then return end

    self:StopPtfx()

    RequestNamedPtfxAsset(ptfx.ptfxAsset)
    local timeout = 0
    while not HasNamedPtfxAssetLoaded(ptfx.ptfxAsset) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    if not HasNamedPtfxAssetLoaded(ptfx.ptfxAsset) then return end

    UseParticleFxAssetNextCall(ptfx.ptfxAsset)

    local pl = ptfx.ptfxPlacement
    local x1 = pl[1] or 0.0
    local x2 = pl[2] or 0.0
    local x3 = pl[3] or 0.0
    local x4 = pl[4] or 0.0
    local x5 = pl[5] or 0.0
    local x6 = pl[6] or 0.0
    local scale = pl[7] or 1.0

    local boneIdx = GetPedBoneIndex(self.ped, ptfx.ptfxBone)

    self.ptfxHandle = StartParticleFxLoopedOnPedBone(
        ptfx.ptfxName,
        self.ped,
        x1, x2, x3, x4, x5, x6,
        boneIdx, scale,
        false, false, false
    )
end

-- ─── SoloEmoteCreator:UpdatePtfx(data) ──────────────────────────────────────
-- Replaces the ptfx config and restarts the effect if asset/name are set.

function SoloEmoteCreator:UpdatePtfx(data)
    self.ptfx = data
    if data.ptfxAsset and data.ptfxAsset ~= ""
    and data.ptfxName  and data.ptfxName  ~= "" then
        self:StartPtfx()
    else
        self:StopPtfx()
    end
end

-- ─── SoloEmoteCreator:SpawnProp(propName, targetPed, bone, placement) ───────
-- Loads and spawns a prop, attaches it to `targetPed` at `bone`, and returns
-- the entity handle. Returns nil on failure.

function SoloEmoteCreator:SpawnProp(propName, targetPed, bone, placement)
    if not propName or propName == "" then return nil end
    if not (targetPed and DoesEntityExist(targetPed)) then return nil end

    local hash = GetHashKey(propName)
    RequestModel(hash)

    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    if not HasModelLoaded(hash) then return nil end

    local pedCoords = GetEntityCoords(targetPed)
    local obj = CreateObject(hash, pedCoords.x, pedCoords.y, pedCoords.z, true, true, false)
    if not obj or obj == 0 then
        SetModelAsNoLongerNeeded(hash)
        return nil
    end

    if Config.DisablePropCollision then
        SetEntityCollision(obj, false, false)
        SetEntityNoCollisionEntity(obj, targetPed, false)
    end

    local p1  = placement[1] or 0.0
    local p2  = placement[2] or 0.0
    local p3  = placement[3] or 0.0
    local p4  = placement[4] or 0.0
    local p5  = placement[5] or 0.0
    local p6  = placement[6] or 0.0

    AttachEntityToEntity(
        obj, targetPed,
        GetPedBoneIndex(targetPed, bone),
        p1, p2, p3, p4, p5, p6,
        true, true, false, true, 1, true
    )

    SetModelAsNoLongerNeeded(hash)

    if self._allPropEntities then
        table.insert(self._allPropEntities, obj)
    end

    return obj
end

-- ─── SoloEmoteCreator:UpdateProps() ─────────────────────────────────────────
-- Deletes old prop entities and re-spawns both props from self.props config.

function SoloEmoteCreator:UpdateProps()
    if self.propEntity and DoesEntityExist(self.propEntity) then
        DeleteEntity(self.propEntity)
        self.propEntity = nil
    end
    if self.secondPropEntity and DoesEntityExist(self.secondPropEntity) then
        DeleteEntity(self.secondPropEntity)
        self.secondPropEntity = nil
    end

    if not (self.ped and DoesEntityExist(self.ped)) then return end

    if self.props.prop and self.props.prop ~= "" then
        self.propEntity = self:SpawnProp(
            self.props.prop, self.ped,
            self.props.propBone, self.props.propPlacement
        )
    end

    if self.props.secondProp and self.props.secondProp ~= "" then
        self.secondPropEntity = self:SpawnProp(
            self.props.secondProp, self.ped,
            self.props.secondPropBone, self.props.secondPropPlacement
        )
    end
end

-- ─── SoloEmoteCreator:SetAnim(dict, clip, label, name) ──────────────────────
-- Updates the active animation and replays it on the preview ped.

function SoloEmoteCreator:SetAnim(dict, clip, label, name)
    self.anim = {
        dict  = dict  or "",
        clip  = clip  or "",
        label = label or "",
        name  = name  or "",
    }

    if self.ped and DoesEntityExist(self.ped) then
        ClearPedTasks(self.ped)
        if dict ~= "" and clip ~= "" then
            self:PlayAnimation()
        end
    end
end

-- ─── SoloEmoteCreator:PlayWalkAnim() ────────────────────────────────────────
-- Plays a generic walk animation on the preview ped.

function SoloEmoteCreator:PlayWalkAnim()
    if not (self.ped and DoesEntityExist(self.ped)) then return end

    local dict = "move_m@generic"
    local clip = "walk"

    RequestAnimDict(dict)
    local timeout = 50
    while not HasAnimDictLoaded(dict) and timeout > 0 do
        Citizen.Wait(10)
        timeout = timeout - 1
    end
    if not HasAnimDictLoaded(dict) then return end

    TaskPlayAnim(self.ped, dict, clip, 8.0, -8.0, -1, 1, 0, false, false, false)
end

-- ─── SoloEmoteCreator:StartWalkPreview() ────────────────────────────────────
function SoloEmoteCreator:StartWalkPreview()
    if self.isWalking then return end
    self.isWalking = true
    if self.ped and DoesEntityExist(self.ped) then
        self:PlayWalkAnim()
    end
end

-- ─── SoloEmoteCreator:StopWalkPreview() ─────────────────────────────────────
function SoloEmoteCreator:StopWalkPreview()
    self.isWalking = false
    if self.ped and DoesEntityExist(self.ped) then
        ClearPedTasks(self.ped)
        if self.anim.dict ~= "" and self.anim.clip ~= "" then
            self:PlayAnimation()
        end
    end
end

-- ─── SoloEmoteCreator:ToggleWalkPreview() ───────────────────────────────────
function SoloEmoteCreator:ToggleWalkPreview()
    if self.isWalking then
        self:StopWalkPreview()
    else
        self:StartWalkPreview()
    end
    Main:sendReactMessage("SOLO_EMOTE_CREATOR_WALK_STATE", { isWalking = self.isWalking })
end

-- =============================================================================
-- NUI Callbacks
-- =============================================================================

RegisterNUICallback("SOLO_EMOTE_CREATOR_CLOSE", function(data, cb)
    SoloEmoteCreator:Stop()
    return cb(true)
end)

RegisterNUICallback("SOLO_EMOTE_CREATOR_SET_ANIM", function(data, cb)
    SoloEmoteCreator:SetAnim(data.dict, data.clip, data.label, data.name)
    return cb(true)
end)

RegisterNUICallback("SOLO_EMOTE_CREATOR_SET_ANIM_OPTIONS", function(data, cb)
    if data then
        SoloEmoteCreator.animOptions = {
            emoteLoop     = data.emoteLoop     or false,
            emoteMoving   = data.emoteMoving   or false,
            emoteDuration = data.emoteDuration or 0,
        }
    end
    return cb(true)
end)

RegisterNUICallback("SOLO_EMOTE_CREATOR_SET_PROPS", function(data, cb)
    if data then
        SoloEmoteCreator.props = {
            prop             = data.prop             or "",
            propBone         = data.propBone         or 57005,
            propPlacement    = data.propPlacement    or { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
            secondProp       = data.secondProp       or "",
            secondPropBone   = data.secondPropBone   or 18905,
            secondPropPlacement = data.secondPropPlacement or { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
        }
        SoloEmoteCreator:UpdateProps()
    end
    return cb(true)
end)

RegisterNUICallback("SOLO_EMOTE_CREATOR_SET_PTFX", function(data, cb)
    if data then
        SoloEmoteCreator:UpdatePtfx({
            ptfxAsset    = data.ptfxAsset    or "",
            ptfxName     = data.ptfxName     or "",
            ptfxBone     = data.ptfxBone     or 31086,
            ptfxNoProp   = (data.ptfxNoProp ~= false),
            ptfxPlacement = data.ptfxPlacement or { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0 },
            ptfxInfo     = data.ptfxInfo     or "",
            ptfxWait     = data.ptfxWait     or 0,
            ptfxCanHold  = (data.ptfxCanHold == true),
        })
    end
    return cb(true)
end)

RegisterNUICallback("SOLO_EMOTE_CREATOR_TOGGLE_WALK", function(data, cb)
    SoloEmoteCreator:ToggleWalkPreview()
    return cb(true)
end)

RegisterNUICallback("SOLO_EMOTE_CREATOR_PLAY_ANIM", function(data, cb)
    if SoloEmoteCreator.ped and DoesEntityExist(SoloEmoteCreator.ped) then
        ClearPedTasks(SoloEmoteCreator.ped)
        if SoloEmoteCreator.anim.dict ~= "" and SoloEmoteCreator.anim.clip ~= "" then
            SoloEmoteCreator:PlayAnimation()
        end
    end
    return cb(true)
end)

RegisterNUICallback("SOLO_EMOTE_CREATOR_COPY_CODE", function(data, cb)
    if data and data.code then
        if lib and lib.setClipboard then
            lib.setClipboard(data.code)
            if Main and Main.Notify then
                Main:Notify("Code copied to clipboard!", "success")
            end
        end
    end
    return cb(true)
end)

RegisterNUICallback("SOLO_EMOTE_CREATOR_CAMERA", function(data, cb)
    if not SoloEmoteCreator.isActive then return cb(true) end

    local ANGLE_STEP  = 0.8
    local ZOOM_STEP   = 0.08
    local HEIGHT_STEP = 0.02
    local changed     = false

    if data.left      then SoloEmoteCreator.cameraAngle = SoloEmoteCreator.cameraAngle + ANGLE_STEP;  changed = true end
    if data.right     then SoloEmoteCreator.cameraAngle = SoloEmoteCreator.cameraAngle - ANGLE_STEP;  changed = true end
    if data.up        then SoloEmoteCreator.cameraPitch = math.min(60.0, SoloEmoteCreator.cameraPitch + ANGLE_STEP);  changed = true end
    if data.down      then SoloEmoteCreator.cameraPitch = math.max(-60.0, SoloEmoteCreator.cameraPitch - ANGLE_STEP); changed = true end
    if data.zoomIn    then SoloEmoteCreator.cameraDistance = math.max(1.0, SoloEmoteCreator.cameraDistance - ZOOM_STEP);  changed = true end
    if data.zoomOut   then SoloEmoteCreator.cameraDistance = math.min(10.0, SoloEmoteCreator.cameraDistance + ZOOM_STEP); changed = true end
    if data.heightUp  then SoloEmoteCreator.cameraHeight = SoloEmoteCreator.cameraHeight + HEIGHT_STEP; changed = true end
    if data.heightDown then SoloEmoteCreator.cameraHeight = SoloEmoteCreator.cameraHeight - HEIGHT_STEP; changed = true end
    if data.reset then
        SoloEmoteCreator.cameraAngle    = 0.0
        SoloEmoteCreator.cameraPitch    = 0.0
        SoloEmoteCreator.cameraDistance = 2.5
        SoloEmoteCreator.cameraHeight   = 0.8
        changed = true
    end

    if changed then SoloEmoteCreator:UpdateCameraPosition() end
    return cb(true)
end)

RegisterNUICallback("SOLO_EMOTE_CREATOR_CAMERA_MOUSE", function(data, cb)
    if not SoloEmoteCreator.isActive then return cb(true) end

    local SENSITIVITY = 0.05

    if data.deltaX then
        SoloEmoteCreator.cameraAngle = SoloEmoteCreator.cameraAngle - (data.deltaX * SENSITIVITY)
    end
    if data.deltaY then
        SoloEmoteCreator.cameraPitch = math.max(-60.0, math.min(60.0,
            SoloEmoteCreator.cameraPitch + (data.deltaY * SENSITIVITY)
        ))
    end

    SoloEmoteCreator:UpdateCameraPosition()
    return cb(true)
end)