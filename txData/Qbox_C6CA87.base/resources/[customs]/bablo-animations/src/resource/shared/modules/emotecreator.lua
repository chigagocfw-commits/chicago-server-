



if IsDuplicityVersion() then return end

-- ─── Object definition ───────────────────────────────────────────────────────

EmoteCreator = {
    isActive          = false,
    ped1              = nil,
    ped2              = nil,
    camera            = nil,
    cameraDistance    = 3.0,
    cameraHeight      = 1.0,
    cameraAngle       = 0.0,
    cameraPitch       = 0.0,
    isWalking         = false,
    walkThread        = nil,

    anim1  = { dict = "", clip = "", label = "", name = "" },
    anim2  = { dict = "", clip = "", label = "", name = "" },

    anim1Options = { emoteLoop = true, emoteMoving = false, syncOffsetFront = 0.0, syncOffsetSide = 0.0 },
    anim2Options = { emoteLoop = true, emoteMoving = false, syncOffsetFront = 0.0, syncOffsetSide = 0.0 },

    attach1Enabled = false,
    attach2Enabled = false,

    props1 = {
        prop                  = "",  propBone         = 57005,
        propPlacement         = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
        secondaryProp         = "",  secondaryPropBone = 18905,
        secondaryPropPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
    },
    props2 = {
        prop                  = "",  propBone         = 57005,
        propPlacement         = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
        secondaryProp         = "",  secondaryPropBone = 18905,
        secondaryPropPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
    },

    ptfx1 = {
        ptfxAsset = "", ptfxName = "", ptfxBone = 31086, ptfxNoProp = true,
        ptfxPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0 },
        ptfxInfo = "", ptfxWait = 0, ptfxCanHold = false,
    },
    ptfx2 = {
        ptfxAsset = "", ptfxName = "", ptfxBone = 31086, ptfxNoProp = true,
        ptfxPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0 },
        ptfxInfo = "", ptfxWait = 0, ptfxCanHold = false,
    },

    ptfx1Handle           = nil,
    ptfx2Handle           = nil,

    prop1Entity           = nil,
    prop1SecondaryEntity  = nil,
    prop2Entity           = nil,
    prop2SecondaryEntity  = nil,

    baseCoords            = nil,
    baseHeading           = 0.0,

    offsets1 = { bone = -1, xPos = 0.0, yPos = 0.0, zPos = 0.0, xRot = 0.0, yRot = 0.0, zRot = 0.0 },
    offsets2 = { bone = -1, xPos = 0.0, yPos = 0.0, zPos = 0.0, xRot = 0.0, yRot = 0.0, zRot = 0.0 },

    -- Current attachment-selector offsets (for GenerateCode)
    offsets = { bone = -1, xPos = 0.0, yPos = 0.0, zPos = 0.0, xRot = 0.0, yRot = 0.0, zRot = 0.0 },

    offsetStep = 0.01,
    rotStep    = 1.0,

    -- Skeleton bones available for attachment
    bones = {
        { id = -1,    name = "NONE",             label = "Entity Origin (Default)" },
        { id = 0,     name = "SKEL_ROOT",         label = "Pelvis/Root"            },
        { id = 11816, name = "SKEL_Spine0",        label = "Spine Base"             },
        { id = 14410, name = "SKEL_Spine1",        label = "Spine 1"                },
        { id = 14411, name = "SKEL_Spine2",        label = "Spine 2"                },
        { id = 24818, name = "SKEL_Spine3",        label = "Spine 3 (Upper)"        },
        { id = 31086, name = "SKEL_Head",          label = "Head"                   },
        { id = 39317, name = "SKEL_Neck_1",        label = "Neck"                   },
        { id = 18905, name = "SKEL_L_Hand",        label = "Left Hand"              },
        { id = 57005, name = "SKEL_R_Hand",        label = "Right Hand"             },
        { id = 61163, name = "SKEL_L_Forearm",     label = "Left Forearm"           },
        { id = 28252, name = "SKEL_R_Forearm",     label = "Right Forearm"          },
        { id = 45509, name = "SKEL_L_UpperArm",    label = "Left Upper Arm"         },
        { id = 40269, name = "SKEL_R_UpperArm",    label = "Right Upper Arm"        },
        { id = 46078, name = "SKEL_L_Thigh",       label = "Left Thigh"             },
        { id = 51826, name = "SKEL_R_Thigh",       label = "Right Thigh"            },
        { id = 63931, name = "SKEL_L_Calf",        label = "Left Calf"              },
        { id = 36864, name = "SKEL_R_Calf",        label = "Right Calf"             },
        { id = 14201, name = "SKEL_L_Foot",        label = "Left Foot"              },
        { id = 52301, name = "SKEL_R_Foot",        label = "Right Foot"             },
        { id = 26610, name = "SKEL_L_Finger00",    label = "Left Thumb"             },
        { id = 58866, name = "SKEL_R_Finger00",    label = "Right Thumb"            },
        { id = 26611, name = "SKEL_L_Finger01",    label = "Left Index"             },
        { id = 58867, name = "SKEL_R_Finger01",    label = "Right Index"            },
    },

    _allPropEntities = {},
}

-- ─── EmoteCreator:Start() ────────────────────────────────────────────────────
function EmoteCreator:Start()
    if self.isActive then return end
    self.isActive        = true
    self._allPropEntities = {}

    local playerPed    = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    self.baseCoords    = playerCoords
    self.baseHeading   = 90.0

    -- Spawn ped1 slightly to the left, ped2 slightly to the right
    self.ped1 = self:CreatePed(playerCoords + vector3(-0.5, 0.0, 0.0))
    self.ped2 = self:CreatePed(playerCoords + vector3( 0.5, 0.0, 0.0))

    if not (self.ped1 and self.ped2) then
        self:Stop()
        return
    end

    SetEntityHeading(self.ped1, 90.0)
    SetEntityHeading(self.ped2, 270.0)

    self:CreateCamera()

    -- Hide real player ped
    SetEntityAlpha(playerPed, 0, false)
    SetEntityVisible(playerPed, false, false)
    FreezeEntityPosition(playerPed, true)

    Main:sendReactMessage("SHOW_MENU", { element = "showEmoteCreator", toggle = true })
    Main:sendReactMessage("EMOTE_CREATOR_INIT", {
        bones    = self.bones,
        offsets1 = self.offsets1,
        offsets2 = self.offsets2,
        anim1    = self.anim1,
        anim2    = self.anim2,
    })
    SetNuiFocus(true, true)
    self:CameraLoop()
end

-- ─── EmoteCreator:Stop() ────────────────────────────────────────────────────
function EmoteCreator:Stop()
    self.isActive  = false
    self.isWalking = false

    self:DeleteAllProps()

    if self.ped1 and DoesEntityExist(self.ped1) then DeleteEntity(self.ped1) end
    self.ped1 = nil
    if self.ped2 and DoesEntityExist(self.ped2) then DeleteEntity(self.ped2) end
    self.ped2 = nil

    if self.camera then
        RenderScriptCams(false, true, 500, true, false)
        DestroyCam(self.camera, false)
        self.camera = nil
    end

    local playerPed = PlayerPedId()
    SetEntityAlpha(playerPed,    255, false)
    SetEntityVisible(playerPed,  true, false)
    FreezeEntityPosition(playerPed, false)

    Main:sendReactMessage("SHOW_MENU", { element = "showEmoteCreator", toggle = false })
    SetNuiFocus(false, false)

    -- Reset all data
    self.offsets1 = { bone = -1, xPos=0.0, yPos=0.0, zPos=0.0, xRot=0.0, yRot=0.0, zRot=0.0 }
    self.offsets2 = { bone = -1, xPos=0.0, yPos=0.0, zPos=0.0, xRot=0.0, yRot=0.0, zRot=0.0 }
    self.anim1    = { dict="", clip="", label="", name="" }
    self.anim2    = { dict="", clip="", label="", name="" }
    self.anim1Options = { emoteLoop=true, emoteMoving=false, syncOffsetFront=0.0, syncOffsetSide=0.0 }
    self.anim2Options = { emoteLoop=true, emoteMoving=false, syncOffsetFront=0.0, syncOffsetSide=0.0 }
    self.attach1Enabled = false
    self.attach2Enabled = false

    local zeroProp = {
        prop="", propBone=57005, propPlacement={0,0,0,0,0,0},
        secondaryProp="", secondaryPropBone=18905, secondaryPropPlacement={0,0,0,0,0,0},
    }
    self.props1 = { prop="", propBone=57005, propPlacement={0,0,0,0,0,0}, secondaryProp="", secondaryPropBone=18905, secondaryPropPlacement={0,0,0,0,0,0} }
    self.props2 = { prop="", propBone=57005, propPlacement={0,0,0,0,0,0}, secondaryProp="", secondaryPropBone=18905, secondaryPropPlacement={0,0,0,0,0,0} }

    local zeroPtfx = { ptfxAsset="", ptfxName="", ptfxBone=31086, ptfxNoProp=true, ptfxPlacement={0,0,0,0,0,0,1.0}, ptfxInfo="", ptfxWait=0, ptfxCanHold=false }
    self:StopPtfx(1)
    self:StopPtfx(2)
    self.ptfx1 = { ptfxAsset="", ptfxName="", ptfxBone=31086, ptfxNoProp=true, ptfxPlacement={0,0,0,0,0,0,1.0}, ptfxInfo="", ptfxWait=0, ptfxCanHold=false }
    self.ptfx2 = { ptfxAsset="", ptfxName="", ptfxBone=31086, ptfxNoProp=true, ptfxPlacement={0,0,0,0,0,0,1.0}, ptfxInfo="", ptfxWait=0, ptfxCanHold=false }
end

-- ─── EmoteCreator:CreatePed(coords) ─────────────────────────────────────────
function EmoteCreator:CreatePed(coords)
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

-- ─── EmoteCreator:CreateCamera() ────────────────────────────────────────────
function EmoteCreator:CreateCamera()
    if self.camera then DestroyCam(self.camera, false) end
    self.camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    self:UpdateCameraPosition()
    SetCamActive(self.camera, true)
    RenderScriptCams(true, true, 500, true, false)
end

-- ─── EmoteCreator:UpdateCameraPosition() ────────────────────────────────────
function EmoteCreator:UpdateCameraPosition()
    if not (self.camera and self.ped1 and self.ped2) then return end

    -- Position camera midway between both peds
    local c1 = GetEntityCoords(self.ped1)
    local c2 = GetEntityCoords(self.ped2)
    local mid = vector3((c1.x + c2.x) * 0.5, (c1.y + c2.y) * 0.5, (c1.z + c2.z) * 0.5)

    local cx = mid.x
    local cy = mid.y
    local cz = mid.z + self.cameraHeight

    local angleRad  = math.rad(self.cameraAngle)
    local pitchRad  = math.rad(self.cameraPitch)
    local cosPitch  = math.cos(pitchRad)
    local dist      = self.cameraDistance

    local camX = cx + dist * math.cos(angleRad) * cosPitch
    local camY = cy + dist * math.sin(angleRad) * cosPitch
    local camZ = cz + dist * math.sin(pitchRad)

    SetCamCoord(self.camera, camX, camY, camZ)
    PointCamAtCoord(self.camera, cx, cy, cz)
end

-- ─── EmoteCreator:CameraLoop() ──────────────────────────────────────────────
function EmoteCreator:CameraLoop()
    Citizen.CreateThread(function()
        while self.isActive do Citizen.Wait(100) end
    end)
end

-- ─── EmoteCreator:PlayWalkAnim(ped) ─────────────────────────────────────────
function EmoteCreator:PlayWalkAnim(ped)
    if not (ped and DoesEntityExist(ped)) then return end
    local dict = "move_m@generic"
    local clip = "walk"
    RequestAnimDict(dict)
    local timeout = 50
    while not HasAnimDictLoaded(dict) and timeout > 0 do
        Citizen.Wait(10)
        timeout = timeout - 1
    end
    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(ped, dict, clip, 8.0, -8.0, -1, 1, 0, false, false, false)
    end
end

-- ─── EmoteCreator:StartWalkPreview() ────────────────────────────────────────
function EmoteCreator:StartWalkPreview()
    if self.isWalking then return end
    self.isWalking = true
    if self.ped1 and DoesEntityExist(self.ped1) then self:PlayWalkAnim(self.ped1) end
    -- Only walk ped2 if it isn't attached to ped1
    if self.ped2 and DoesEntityExist(self.ped2) and not self.attach2Enabled then
        self:PlayWalkAnim(self.ped2)
    end
end

-- ─── EmoteCreator:StopWalkPreview() ─────────────────────────────────────────
function EmoteCreator:StopWalkPreview()
    self.isWalking = false

    if self.ped1 and DoesEntityExist(self.ped1) then
        ClearPedTasks(self.ped1)
        if self.anim1.dict ~= "" and self.anim1.clip ~= "" then
            self:PlayAnimation(self.ped1, self.anim1.dict, self.anim1.clip, self.anim1Options.emoteMoving)
        end
    end

    if self.ped2 and DoesEntityExist(self.ped2) then
        ClearPedTasks(self.ped2)
        if self.anim2.dict ~= "" and self.anim2.clip ~= "" then
            self:PlayAnimation(self.ped2, self.anim2.dict, self.anim2.clip, self.anim2Options.emoteMoving)
        end
    end

    -- Re-apply attachments after a brief delay
    SetTimeout(100, function() self:UpdateAttachments() end)
end

-- ─── EmoteCreator:ToggleWalkPreview() ───────────────────────────────────────
function EmoteCreator:ToggleWalkPreview()
    if self.isWalking then self:StopWalkPreview() else self:StartWalkPreview() end
    Main:sendReactMessage("EMOTE_CREATOR_WALK_STATE", { isWalking = self.isWalking })
end

-- ─── EmoteCreator:PlayAnimation(ped, dict, clip, emoteMoving) ───────────────
function EmoteCreator:PlayAnimation(ped, dict, clip, emoteMoving)
    if not (dict and dict ~= "" and clip and clip ~= "") then return false end
    if not (ped and DoesEntityExist(ped)) then return false end

    RequestAnimDict(dict)
    local timeout = 100
    while not HasAnimDictLoaded(dict) and timeout > 0 do
        Citizen.Wait(10)
        timeout = timeout - 1
    end
    if not HasAnimDictLoaded(dict) then return false end

    local flag = emoteMoving and 51 or 1
    TaskPlayAnim(ped, dict, clip, 2.0, -2.0, -1, flag, 0, false, false, false)
    return true
end

-- ─── EmoteCreator:UpdateAttachments() ───────────────────────────────────────
-- Detaches both peds, then re-attaches according to attach1/2Enabled flags.

function EmoteCreator:UpdateAttachments()
    if not (self.ped1 and self.ped2) then return end
    if not (DoesEntityExist(self.ped1) and DoesEntityExist(self.ped2)) then return end

    DetachEntity(self.ped1, true, false)
    DetachEntity(self.ped2, true, false)

    if self.attach1Enabled then
        local o = self.offsets1
        AttachEntityToEntity(
            self.ped1, self.ped2,
            GetPedBoneIndex(self.ped2, o.bone),
            o.xPos, o.yPos, o.zPos,
            o.xRot, o.yRot, o.zRot,
            false, false, false, true, 1, true
        )
    end

    -- Only attach ped2 to ped1 if ped1 is NOT already attached to ped2
    if self.attach2Enabled and not self.attach1Enabled then
        local o = self.offsets2
        AttachEntityToEntity(
            self.ped2, self.ped1,
            GetPedBoneIndex(self.ped1, o.bone),
            o.xPos, o.yPos, o.zPos,
            o.xRot, o.yRot, o.zRot,
            false, false, false, true, 1, true
        )
    end
end

-- ─── EmoteCreator:DeleteAllProps() ──────────────────────────────────────────
function EmoteCreator:DeleteAllProps()
    if self._allPropEntities then
        for _, entity in ipairs(self._allPropEntities) do
            if entity and DoesEntityExist(entity) then DeleteEntity(entity) end
        end
        self._allPropEntities = {}
    end
    self.prop1Entity          = nil
    self.prop1SecondaryEntity = nil
    self.prop2Entity          = nil
    self.prop2SecondaryEntity = nil
end

-- ─── EmoteCreator:StopPtfx(slot) ────────────────────────────────────────────
function EmoteCreator:StopPtfx(slot)
    if slot == 1 then
        if self.ptfx1Handle then
            StopParticleFxLooped(self.ptfx1Handle, false)
            self.ptfx1Handle = nil
        end
    elseif slot == 2 then
        if self.ptfx2Handle then
            StopParticleFxLooped(self.ptfx2Handle, false)
            self.ptfx2Handle = nil
        end
    end
end

-- ─── EmoteCreator:StartPtfx(slot) ───────────────────────────────────────────
function EmoteCreator:StartPtfx(slot)
    local ped  = (slot == 1) and self.ped1 or self.ped2
    local ptfx = (slot == 1) and self.ptfx1 or self.ptfx2

    if not (ped and DoesEntityExist(ped)) then return end
    if not (ptfx.ptfxAsset and ptfx.ptfxAsset ~= "") then return end
    if not (ptfx.ptfxName  and ptfx.ptfxName  ~= "") then return end

    self:StopPtfx(slot)

    RequestNamedPtfxAsset(ptfx.ptfxAsset)
    local timeout = 0
    while not HasNamedPtfxAssetLoaded(ptfx.ptfxAsset) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    if not HasNamedPtfxAssetLoaded(ptfx.ptfxAsset) then return end

    UseParticleFxAssetNextCall(ptfx.ptfxAsset)

    local pl    = ptfx.ptfxPlacement
    local scale = pl[7] or 1.0
    local handle = StartParticleFxLoopedOnPedBone(
        ptfx.ptfxName, ped,
        pl[1] or 0.0, pl[2] or 0.0, pl[3] or 0.0,
        pl[4] or 0.0, pl[5] or 0.0, pl[6] or 0.0,
        GetPedBoneIndex(ped, ptfx.ptfxBone),
        scale,
        false, false, false
    )

    if slot == 1 then self.ptfx1Handle = handle
    else              self.ptfx2Handle = handle
    end
end

-- ─── EmoteCreator:UpdatePtfx(slot, data) ────────────────────────────────────
function EmoteCreator:UpdatePtfx(slot, data)
    if slot == 1 then self.ptfx1 = data else self.ptfx2 = data end

    local ptfx = (slot == 1) and self.ptfx1 or self.ptfx2
    if ptfx.ptfxAsset and ptfx.ptfxAsset ~= "" and ptfx.ptfxName and ptfx.ptfxName ~= "" then
        self:StartPtfx(slot)
    else
        self:StopPtfx(slot)
    end
end

-- ─── EmoteCreator:SpawnProp(propName, targetPed, bone, placement) ────────────
function EmoteCreator:SpawnProp(propName, targetPed, bone, placement)
    if not propName or propName == "" then return nil end
    if not (targetPed and DoesEntityExist(targetPed)) then return nil end

    local hash = GetHashKey(propName)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 100 do Wait(10); timeout = timeout + 1 end
    if not HasModelLoaded(hash) then return nil end

    local pedCoords = GetEntityCoords(targetPed)
    local obj = CreateObject(hash, pedCoords.x, pedCoords.y, pedCoords.z, true, true, false)
    if not obj or obj == 0 then SetModelAsNoLongerNeeded(hash); return nil end

    if Config.DisablePropCollision then
        SetEntityCollision(obj, false, false)
        SetEntityNoCollisionEntity(obj, targetPed, false)
    end

    AttachEntityToEntity(
        obj, targetPed,
        GetPedBoneIndex(targetPed, bone),
        placement[1] or 0.0, placement[2] or 0.0, placement[3] or 0.0,
        placement[4] or 0.0, placement[5] or 0.0, placement[6] or 0.0,
        true, true, false, true, 1, true
    )

    SetModelAsNoLongerNeeded(hash)
    if self._allPropEntities then table.insert(self._allPropEntities, obj) end
    return obj
end

-- ─── EmoteCreator:UpdateProps1() ────────────────────────────────────────────
function EmoteCreator:UpdateProps1()
    if self.prop1Entity and DoesEntityExist(self.prop1Entity) then
        DeleteEntity(self.prop1Entity); self.prop1Entity = nil
    end
    if self.prop1SecondaryEntity and DoesEntityExist(self.prop1SecondaryEntity) then
        DeleteEntity(self.prop1SecondaryEntity); self.prop1SecondaryEntity = nil
    end

    if not (self.ped1 and DoesEntityExist(self.ped1)) then return end

    if self.props1.prop and self.props1.prop ~= "" then
        self.prop1Entity = self:SpawnProp(self.props1.prop, self.ped1, self.props1.propBone, self.props1.propPlacement)
    end
    if self.props1.secondaryProp and self.props1.secondaryProp ~= "" then
        self.prop1SecondaryEntity = self:SpawnProp(self.props1.secondaryProp, self.ped1, self.props1.secondaryPropBone, self.props1.secondaryPropPlacement)
    end
end

-- ─── EmoteCreator:UpdateProps2() ────────────────────────────────────────────
function EmoteCreator:UpdateProps2()
    if self.prop2Entity and DoesEntityExist(self.prop2Entity) then
        DeleteEntity(self.prop2Entity); self.prop2Entity = nil
    end
    if self.prop2SecondaryEntity and DoesEntityExist(self.prop2SecondaryEntity) then
        DeleteEntity(self.prop2SecondaryEntity); self.prop2SecondaryEntity = nil
    end

    if not (self.ped2 and DoesEntityExist(self.ped2)) then return end

    if self.props2.prop and self.props2.prop ~= "" then
        self.prop2Entity = self:SpawnProp(self.props2.prop, self.ped2, self.props2.propBone, self.props2.propPlacement)
    end
    if self.props2.secondaryProp and self.props2.secondaryProp ~= "" then
        self.prop2SecondaryEntity = self:SpawnProp(self.props2.secondaryProp, self.ped2, self.props2.secondaryPropBone, self.props2.secondaryPropPlacement)
    end
end

-- ─── EmoteCreator:UpdateSyncOffsets() ───────────────────────────────────────
-- Places ped2 relative to ped1 based on anim1Options sync offsets.
-- Skips if either attachment is enabled (attachment overrides offset positioning).

function EmoteCreator:UpdateSyncOffsets()
    if not (self.ped1 and self.ped2) then return end
    if not (DoesEntityExist(self.ped1) and DoesEntityExist(self.ped2)) then return end
    if self.attach1Enabled or self.attach2Enabled then return end

    local ped1Coords = GetEntityCoords(self.ped1)
    local ped1Heading = GetEntityHeading(self.ped1)
    local headingRad  = math.rad(ped1Heading)

    local front = self.anim1Options.syncOffsetFront or 0.0
    local side  = self.anim1Options.syncOffsetSide  or 0.0

    -- Rotate side/front offsets by ped1 heading
    local dx = side * math.cos(headingRad) - front * math.sin(headingRad)
    local dy = side * math.sin(headingRad) + front * math.cos(headingRad)

    SetEntityCoords(self.ped2,
        ped1Coords.x + dx,
        ped1Coords.y + dy,
        ped1Coords.z - 0.97,
        false, false, false, false
    )
end

-- ─── EmoteCreator:SetOffset1(key, value) ────────────────────────────────────
function EmoteCreator:SetOffset1(key, value)
    if self.offsets1[key] ~= nil then
        self.offsets1[key] = value
        self:UpdateAttachments()
    end
end

-- ─── EmoteCreator:SetOffset2(key, value) ────────────────────────────────────
function EmoteCreator:SetOffset2(key, value)
    if self.offsets2[key] ~= nil then
        self.offsets2[key] = value
        self:UpdateAttachments()
    end
end

-- ─── EmoteCreator:SetOffsets(tbl) ───────────────────────────────────────────
function EmoteCreator:SetOffsets(tbl)
    for key, value in pairs(tbl) do
        if self.offsets[key] ~= nil then
            self.offsets[key] = value
        end
    end
    self:UpdateAttachments()
end

-- ─── EmoteCreator:SetAnim1(dict, clip, label, name) ─────────────────────────
function EmoteCreator:SetAnim1(dict, clip, label, name)
    self.anim1 = {
        dict  = dict  or "",
        clip  = clip  or "",
        label = label or "",
        name  = name  or "",
    }
    if self.ped1 and DoesEntityExist(self.ped1) then
        ClearPedTasks(self.ped1)
        if dict ~= "" and clip ~= "" then
            self:PlayAnimation(self.ped1, dict, clip, self.anim1Options.emoteMoving)
        end
    end
end

-- ─── EmoteCreator:SetAnim2(dict, clip, label, name) ─────────────────────────
function EmoteCreator:SetAnim2(dict, clip, label, name)
    self.anim2 = {
        dict  = dict  or "",
        clip  = clip  or "",
        label = label or "",
        name  = name  or "",
    }
    if self.ped2 and DoesEntityExist(self.ped2) then
        ClearPedTasks(self.ped2)
        if dict ~= "" and clip ~= "" then
            self:PlayAnimation(self.ped2, dict, clip, self.anim2Options.emoteMoving)
            -- Re-apply attachments after the animation starts
            SetTimeout(100, function() self:UpdateAttachments() end)
        end
    end
end

-- ─── EmoteCreator:GenerateCode() ────────────────────────────────────────────
-- Returns a Lua config code string for inserting into an animations file.

function EmoteCreator:GenerateCode()
    local name1  = (self.anim1.name  ~= "" and self.anim1.name)  or "emotename"
    local name2  = (self.anim2.name  ~= "" and self.anim2.name)  or "linkedemote"
    local label1 = (self.anim1.label ~= "" and self.anim1.label) or "Emote Label"
    local label2 = (self.anim2.label ~= "" and self.anim2.label) or "Linked Emote Label"

    local template = [[
["%s"] = {
    "%s",
    "%s",
    "%s",
    "%s",
    AnimationOptions = {
        EmoteLoop = true,
    }
},
["%s"] = {
    "%s",
    "%s",
    "%s",
    "%s",
    AnimationOptions = {
        EmoteLoop = true,
        Attachto = true,
        bone = %d,
        xPos = %.4f,
        yPos = %.4f,
        zPos = %.4f,
        xRot = %.1f,
        yRot = %.1f,
        zRot = %.1f,
    }
},]]

    return string.format(template,
        name1,
        self.anim1.dict, self.anim1.clip, label1, name2,
        name2,
        self.anim2.dict, self.anim2.clip, label2, name1,
        self.offsets.bone,
        self.offsets.xPos, self.offsets.yPos, self.offsets.zPos,
        self.offsets.xRot, self.offsets.yRot, self.offsets.zRot
    )
end

-- ─── EmoteCreator:ToggleAttachment(enable) ──────────────────────────────────
-- If enable=true: apply current offsets attachment.
-- If enable=false: detach ped2 and place it 1m to the side of ped1.

function EmoteCreator:ToggleAttachment(enable)
    if not (self.ped2 and DoesEntityExist(self.ped2)) then return end

    if enable then
        self:UpdateAttachments()
    else
        DetachEntity(self.ped2, true, false)
        local ped1Coords = GetEntityCoords(self.ped1)
        SetEntityCoords(self.ped2,
            ped1Coords.x + 1.0, ped1Coords.y, ped1Coords.z,
            false, false, false, false
        )
        SetEntityHeading(self.ped2, GetEntityHeading(self.ped1) + 180.0)
    end
end

-- ─── EmoteCreator:ResetOffsets() ────────────────────────────────────────────
function EmoteCreator:ResetOffsets()
    self.offsets = { bone=0, xPos=0.0, yPos=0.0, zPos=0.0, xRot=0.0, yRot=0.0, zRot=0.0 }
    self:UpdateAttachments()
    Main:sendReactMessage("EMOTE_CREATOR_UPDATE", { offsets = self.offsets })
end

-- =============================================================================
-- Selector state — tracks whether the creator-type picker is open
-- =============================================================================

local selectorOpen = false

local function openSelector()
    if selectorOpen then return end

    -- Close any active creator first
    if EmoteCreator.isActive then   EmoteCreator:Stop();   return end
    if SoloEmoteCreator and SoloEmoteCreator.isActive then SoloEmoteCreator:Stop(); return end

    selectorOpen = true
    Main:sendReactMessage("SHOW_MENU", { element = "showEmoteCreatorSelector", toggle = true })
    SetNuiFocus(true, true)
end

local function closeSelector()
    selectorOpen = false
    Main:sendReactMessage("SHOW_MENU", { element = "showEmoteCreatorSelector", toggle = false })
    SetNuiFocus(false, false)
end

local function toggleCreator()
    if EmoteCreator.isActive then            EmoteCreator:Stop();   return end
    if SoloEmoteCreator and SoloEmoteCreator.isActive then SoloEmoteCreator:Stop(); return end

    if selectorOpen then closeSelector(); return end
    openSelector()
end

-- ─── Net Event: client:openEmoteCreator ──────────────────────────────────────
while not eventName do Wait(0) end
RegisterNetEvent(eventName .. "client:openEmoteCreator")
AddEventHandler(eventName .. "client:openEmoteCreator", function()
    toggleCreator()
end)

-- =============================================================================
-- NUI Callbacks
-- =============================================================================

-- EMOTE_CREATOR_SELECT — choose shared or solo type
RegisterNUICallback("EMOTE_CREATOR_SELECT", function(data, cb)
    closeSelector()
    if data.type == "shared" then
        EmoteCreator:Start()
    elseif data.type == "solo" and SoloEmoteCreator then
        SoloEmoteCreator:Start()
    end
    return cb(true)
end)

RegisterNUICallback("EMOTE_CREATOR_SELECTOR_CLOSE", function(data, cb)
    closeSelector()
    return cb(true)
end)

RegisterNUICallback("EMOTE_CREATOR_CLOSE", function(data, cb)
    EmoteCreator:Stop()
    return cb(true)
end)

-- Offset setters

RegisterNUICallback("EMOTE_CREATOR_SET_OFFSET1", function(data, cb)
    if data.key and data.value ~= nil then
        EmoteCreator:SetOffset1(data.key, tonumber(data.value) or 0)
    else
        for key, value in pairs(data) do
            if EmoteCreator.offsets1[key] ~= nil then
                EmoteCreator.offsets1[key] = tonumber(value) or 0
            end
        end
        EmoteCreator:UpdateAttachments()
    end
    return cb(true)
end)

RegisterNUICallback("EMOTE_CREATOR_SET_OFFSET2", function(data, cb)
    if data.key and data.value ~= nil then
        EmoteCreator:SetOffset2(data.key, tonumber(data.value) or 0)
    else
        for key, value in pairs(data) do
            if EmoteCreator.offsets2[key] ~= nil then
                EmoteCreator.offsets2[key] = tonumber(value) or 0
            end
        end
        EmoteCreator:UpdateAttachments()
    end
    return cb(true)
end)

-- Animation setters

RegisterNUICallback("EMOTE_CREATOR_SET_ANIM1", function(data, cb)
    EmoteCreator:SetAnim1(data.dict, data.clip, data.label, data.name)
    return cb(true)
end)

RegisterNUICallback("EMOTE_CREATOR_SET_ANIM2", function(data, cb)
    EmoteCreator:SetAnim2(data.dict, data.clip, data.label, data.name)
    return cb(true)
end)

RegisterNUICallback("EMOTE_CREATOR_SET_ANIM1_OPTIONS", function(data, cb)
    if data then
        EmoteCreator.anim1Options = {
            emoteLoop       = data.emoteLoop       or false,
            emoteMoving     = data.emoteMoving      or false,
            syncOffsetFront = data.syncOffsetFront  or 0.0,
            syncOffsetSide  = data.syncOffsetSide   or 0.0,
        }
        EmoteCreator:UpdateSyncOffsets()
    end
    return cb(true)
end)

RegisterNUICallback("EMOTE_CREATOR_SET_ANIM2_OPTIONS", function(data, cb)
    if data then
        EmoteCreator.anim2Options = {
            emoteLoop       = data.emoteLoop       or false,
            emoteMoving     = data.emoteMoving      or false,
            syncOffsetFront = data.syncOffsetFront  or 0.0,
            syncOffsetSide  = data.syncOffsetSide   or 0.0,
        }
        EmoteCreator:UpdateSyncOffsets()
    end
    return cb(true)
end)

RegisterNUICallback("EMOTE_CREATOR_TOGGLE_WALK", function(data, cb)
    EmoteCreator:ToggleWalkPreview()
    return cb(true)
end)

-- Attachment toggles

RegisterNUICallback("EMOTE_CREATOR_TOGGLE_ATTACH1", function(data, cb)
    EmoteCreator.attach1Enabled = (data.enabled == true)
    EmoteCreator:UpdateAttachments()
    return cb(true)
end)

RegisterNUICallback("EMOTE_CREATOR_TOGGLE_ATTACH2", function(data, cb)
    EmoteCreator.attach2Enabled = (data.enabled == true)
    EmoteCreator:UpdateAttachments()
    return cb(true)
end)

-- Offset resets

RegisterNUICallback("EMOTE_CREATOR_RESET1", function(data, cb)
    EmoteCreator.offsets1 = { bone=-1, xPos=0.0, yPos=0.0, zPos=0.0, xRot=0.0, yRot=0.0, zRot=0.0 }
    EmoteCreator:UpdateAttachments()
    return cb(true)
end)

RegisterNUICallback("EMOTE_CREATOR_RESET2", function(data, cb)
    EmoteCreator.offsets2 = { bone=-1, xPos=0.0, yPos=0.0, zPos=0.0, xRot=0.0, yRot=0.0, zRot=0.0 }
    EmoteCreator:UpdateAttachments()
    return cb(true)
end)

-- Props

local function buildPropsFromData(data)
    return {
        prop                    = data.prop              or "",
        propBone                = data.propBone          or 57005,
        propPlacement           = data.propPlacement     or { 0,0,0,0,0,0 },
        secondaryProp           = data.secondaryProp     or "",
        secondaryPropBone       = data.secondaryPropBone or 18905,
        secondaryPropPlacement  = data.secondaryPropPlacement or { 0,0,0,0,0,0 },
    }
end

RegisterNUICallback("EMOTE_CREATOR_SET_PROPS1", function(data, cb)
    if data then
        EmoteCreator.props1 = buildPropsFromData(data)
        EmoteCreator:UpdateProps1()
    end
    return cb(true)
end)

RegisterNUICallback("EMOTE_CREATOR_SET_PROPS2", function(data, cb)
    if data then
        EmoteCreator.props2 = buildPropsFromData(data)
        EmoteCreator:UpdateProps2()
    end
    return cb(true)
end)

-- PTFX

local function buildPtfxFromData(data)
    return {
        ptfxAsset     = data.ptfxAsset    or "",
        ptfxName      = data.ptfxName     or "",
        ptfxBone      = data.ptfxBone     or 31086,
        ptfxNoProp    = (data.ptfxNoProp ~= false),
        ptfxPlacement = data.ptfxPlacement or { 0,0,0,0,0,0,1.0 },
        ptfxInfo      = data.ptfxInfo     or "",
        ptfxWait      = data.ptfxWait     or 0,
        ptfxCanHold   = (data.ptfxCanHold == true),
    }
end

RegisterNUICallback("EMOTE_CREATOR_SET_PTFX1", function(data, cb)
    if data then EmoteCreator:UpdatePtfx(1, buildPtfxFromData(data)) end
    return cb(true)
end)

RegisterNUICallback("EMOTE_CREATOR_SET_PTFX2", function(data, cb)
    if data then EmoteCreator:UpdatePtfx(2, buildPtfxFromData(data)) end
    return cb(true)
end)

-- Code generation + copy

RegisterNUICallback("EMOTE_CREATOR_COPY_CODE", function(data, cb)
    if data and data.code and lib and lib.setClipboard then
        lib.setClipboard(data.code)
        if Main and Main.Notify then
            Main:Notify("Code copied to clipboard!", "success")
        end
    end
    return cb(true)
end)

-- Play both anims simultaneously

RegisterNUICallback("EMOTE_CREATOR_PLAY_ANIMS", function(data, cb)
    if EmoteCreator.ped1 and DoesEntityExist(EmoteCreator.ped1) then
        ClearPedTasks(EmoteCreator.ped1)
    end
    if EmoteCreator.ped2 and DoesEntityExist(EmoteCreator.ped2) then
        ClearPedTasks(EmoteCreator.ped2)
    end

    if EmoteCreator.anim1.dict ~= "" and EmoteCreator.anim1.clip ~= "" and EmoteCreator.ped1 then
        EmoteCreator:PlayAnimation(EmoteCreator.ped1, EmoteCreator.anim1.dict, EmoteCreator.anim1.clip, EmoteCreator.anim1Options.emoteMoving)
    end
    if EmoteCreator.anim2.dict ~= "" and EmoteCreator.anim2.clip ~= "" and EmoteCreator.ped2 then
        EmoteCreator:PlayAnimation(EmoteCreator.ped2, EmoteCreator.anim2.dict, EmoteCreator.anim2.clip, EmoteCreator.anim2Options.emoteMoving)
    end

    SetTimeout(100, function() EmoteCreator:UpdateAttachments() end)
    return cb(true)
end)

-- Camera controls

RegisterNUICallback("EMOTE_CREATOR_CAMERA", function(data, cb)
    if not EmoteCreator.isActive then return cb(true) end

    local ANGLE_STEP  = 0.8
    local ZOOM_STEP   = 0.08
    local HEIGHT_STEP = 0.02
    local changed     = false

    if data.left      then EmoteCreator.cameraAngle    = EmoteCreator.cameraAngle + ANGLE_STEP;  changed = true end
    if data.right     then EmoteCreator.cameraAngle    = EmoteCreator.cameraAngle - ANGLE_STEP;  changed = true end
    if data.up        then EmoteCreator.cameraPitch    = math.min(60.0, EmoteCreator.cameraPitch + ANGLE_STEP);  changed = true end
    if data.down      then EmoteCreator.cameraPitch    = math.max(-60.0, EmoteCreator.cameraPitch - ANGLE_STEP); changed = true end
    if data.zoomIn    then EmoteCreator.cameraDistance = math.max(1.0,  EmoteCreator.cameraDistance - ZOOM_STEP);  changed = true end
    if data.zoomOut   then EmoteCreator.cameraDistance = math.min(10.0, EmoteCreator.cameraDistance + ZOOM_STEP); changed = true end
    if data.heightUp  then EmoteCreator.cameraHeight   = EmoteCreator.cameraHeight + HEIGHT_STEP; changed = true end
    if data.heightDown then EmoteCreator.cameraHeight  = EmoteCreator.cameraHeight - HEIGHT_STEP; changed = true end
    if data.reset then
        EmoteCreator.cameraAngle    = 0.0
        EmoteCreator.cameraPitch    = 0.0
        EmoteCreator.cameraDistance = 3.0
        EmoteCreator.cameraHeight   = 1.0
        changed = true
    end

    if changed then EmoteCreator:UpdateCameraPosition() end
    return cb(true)
end)

RegisterNUICallback("EMOTE_CREATOR_CAMERA_MOUSE", function(data, cb)
    if not EmoteCreator.isActive then return cb(true) end

    local SENSITIVITY = 0.05
    if data.deltaX then EmoteCreator.cameraAngle = EmoteCreator.cameraAngle - (data.deltaX * SENSITIVITY) end
    if data.deltaY then
        EmoteCreator.cameraPitch = math.max(-60.0, math.min(60.0,
            EmoteCreator.cameraPitch + (data.deltaY * SENSITIVITY)
        ))
    end
    EmoteCreator:UpdateCameraPosition()
    return cb(true)
end)

RegisterNUICallback("EMOTE_CREATOR_TOGGLE_FOCUS", function(data, cb)
    -- Toggle NUI focus for free-look
    local focusState = not IsNuiFocused()
    SetNuiFocus(focusState, focusState)
    return cb(true)
end)