--       _                           _   _             _                   _             _                
--   ___| | ___  __ _ _ __   ___  __| | | |__  _   _  | |__  _ __ __ _  __| |_   _   ___| |_ ___ _ __     
--  / __| |/ _ \/ _` | '_ \ / _ \/ _` | | '_ \| | | | | '_ \| '__/ _` |/ _` | | | | / __| __/ _ \ '_ \    
-- | (__| |  __/ (_| | | | |  __/ (_| | | |_) | |_| | | |_) | | | (_| | (_| | |_| | \__ \ ||  __/ | | |   
--  \___|_|\___|\__,_|_| |_|\___|\__,_| |_.__/ \__, | |_.__/|_|  \__,_|\__,_|\__, | |___/\__\___|_| |_|   
--  / _(_)_  _____  __| | | |__  _   _  | |__  |___/ ___(_)_ __ ___   | |__  |___/_ __ _ __ ___ _ __ __ _ 
-- | |_| \ \/ / _ \/ _` | | '_ \| | | | | '_ \ / _` |_  / | '_ ` _ \  | '_ \ / _ \ '__| '__/ _ \ '__/ _` |
-- |  _| |>  <  __/ (_| | | |_) | |_| | | | | | (_| |/ /| | | | | | | | | | |  __/ |  | | |  __/ | | (_| |
-- |_| |_/_/\_\___|\__,_| |_.__/ \__, | |_| |_|\__,_/___|_|_| |_| |_| |_| |_|\___|_|  |_|  \___|_|  \__,_|
--                               |___/
--   

-- ============================================================
--  RTX SMOKING  –  main.lua  (refactorisé)
-- ============================================================

hookahs = {}

-- ── constantes d'attache ──────────────────────────────────
local MOUTHPIECE_MODEL          = -1188984809
local HAND_BONE                 = 57005

local MOUTHPIECE_OFFSET_POS     = vector3(0.12, -0.004, -0.008)
local MOUTHPIECE_OFFSET_ROT     = vector3(-170.0, -3.65, -18.799999)

local HOOKAH_TIP_OFFSET_POS     = vector3(3.79E-4, -0.156826, 0.571417)
local HOOKAH_TIP_OFFSET_ROT     = vector3(0.0, 0.09, 0.0)

local ROPE_MAX_LENGTH           = 5
local ROPE_BREAK_FORCE          = 1.0
local ROPE_MIN_LENGTH           = 0.25
local ROPE_INITIAL_LENGTH       = 1.0

local HOSE_ATTACH_OFFSET_POS    = vector3(0.12, -0.004, -0.008)
local HOSE_ATTACH_OFFSET_ROT    = vector3(-170.0, -3.65, -18.799999)

local HOOKAH_BONE               = 57005
local HOSE_MOUTHPIECE_OFFSET    = vector3(0.074, -0.015, -0.023)
local HOSE_MOUTHPIECE_ROT       = vector3(-169.300003, -110.550003, -33.650002)

-- ── états globaux ─────────────────────────────────────────
local hookahMenuOpen            = false
local hookahMenuEntity          = nil
local hookahMenuHookahId        = nil

local hookahHoseActive          = false
local hookahHoseHookahId        = nil
local hookahHoseInhaleStart     = 0
local hookahHoseAutoReleased    = false

local nearestHookahId           = nil
local isPlacingHookah           = false
local placingHookahObject       = nil

local isSmokingBusy             = false
local isSmokingUIOpen           = false
local isSmokingMenuOpen         = false

local hookahCamera              = nil
local hookahCameraTransition    = false

local currentSmokingVariant     = nil
local currentSmokingConfig      = nil
local currentSmokingType        = nil
local currentSmokingItemKey     = nil
local currentSmokingVariantDef  = nil
local currentSmokingState       = nil

local isSmokingActive           = false
local isSmokingPuffing          = false
local isSmokingLighting         = false
local smokingPuffStyleIndex     = 1
local smokingInhaleStartTime    = 0
local smokingLastPuffTime       = 0
local smokingPuffCooldownMs     = 2000

local mainItemObject            = nil
local secondaryItemObject       = nil
local progressSecondaryObject   = nil

local idleParticleFx            = nil
local puffParticleFx            = nil
local lightParticleFx           = nil
local exhaleParticleFx          = nil

local activeLoopSounds          = {}
local localLoopStates           = {}

-- ── alias de langue (compatibilité avec d'autres fichiers) ─
function GetLocalizedString(key, ...)
    return string.format(Language[Config.Language][key], ...)
end

function GetLocalizedFormattedString(key, ...)
    local text = tostring(GetLocalizedString(key, ...))
    return (text:gsub('^%l', string.upper))
end

LanguageFile2 = GetLocalizedString
LanguageFile  = GetLocalizedFormattedString

-- ── utilitaires généraux ──────────────────────────────────
function DeepCopy(value)
    if type(value) ~= 'table' then
        return value
    end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

function MergeOverrides(base, overrides)
    local result = DeepCopy(base)
    if type(overrides) ~= 'table' then
        return result
    end
    for k, v in pairs(overrides) do
        if type(v) == 'table' then
            if type(result[k]) == 'table' then
                result[k] = MergeOverrides(result[k], v)
            else
                result[k] = DeepCopy(v)
            end
        else
            result[k] = v
        end
    end
    return result
end

function Round(value, decimals)
    decimals = decimals or 0
    local m = 10 ^ decimals
    return math.floor(value * m + 0.5) / m
end

function Clamp(value, minVal, maxVal)
    if value < minVal then return minVal end
    if value > maxVal then return maxVal end
    return value
end

-- ── utilitaires réseau ────────────────────────────────────
function GetNearbyPlayerServerIds(maxDistance)
    local ids = {}
    local origin = GetEntityCoords(PlayerPedId())
    for _, pid in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(pid)
        if ped and ped ~= 0 then
            local dist = #(origin - GetEntityCoords(ped))
            if maxDistance >= dist then
                local sid = GetPlayerServerId(pid)
                if sid and sid > 0 then
                    ids[#ids + 1] = sid
                end
            end
        end
    end
    return ids
end

function GetLocalClientId()
    return PlayerId()
end

function GetLocalServerIdValue()
    return GetPlayerServerId(PlayerId())
end

function FindLocalPlayerById(serverId)
    for _, pid in ipairs(GetActivePlayers()) do
        if GetPlayerServerId(pid) == serverId then
            return pid
        end
    end
    return nil
end

function GetAllValidPlayerIds()
    local result = {}
    for _, pid in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(pid)
        if DoesEntityExist(ped) then
            result[#result + 1] = pid
        end
    end
    return result
end

function FindNearestOtherPlayer(coords, maxDistance)
    local best = nil
    local bestDist = maxDistance + 0.001
    for _, pid in ipairs(GetAllValidPlayerIds()) do
        if pid ~= PlayerId() and pid ~= -1 then
            local ped = GetPlayerPed(pid)
            if DoesEntityExist(ped) then
                local dist = #(coords - GetEntityCoords(ped))
                if maxDistance >= dist and bestDist > dist then
                    bestDist = dist
                    best = {
                        clientId = pid,
                        serverId = GetPlayerServerId(pid),
                        ped      = ped,
                        distance = dist,
                    }
                end
            end
        end
    end
    return best
end

-- ── sons ──────────────────────────────────────────────────
function GetSoundDefaultVolume()
    return Config.SoundEffectsVolume or 0.45
end

function GetSoundDefaultDistance()
    return Config.SoundEffectsDistance or 12.0
end

function PlaySmokingSoundPath(src, volume)
    if Config.SoundEffects ~= true or not src then return end
    SendNUIMessage({ message = 'rtx_smoking:playSound', src = src, volume = volume or GetSoundDefaultVolume() })
end

function StartSmokingLoopSoundPath(loopId, src, volume)
    if Config.SoundEffects ~= true or not loopId or not src then return end
    SendNUIMessage({ message = 'rtx_smoking:startLoopSound', loopId = loopId, src = src, volume = volume or GetSoundDefaultVolume() })
end

function SetSmokingLoopSoundVolume(loopId, volume)
    if not loopId then return end
    SendNUIMessage({ message = 'rtx_smoking:setLoopVolume', loopId = loopId, volume = volume })
end

function StopSmokingLoopSound(loopId)
    if not loopId then return end
    activeLoopSounds[loopId] = nil
    SendNUIMessage({ message = 'rtx_smoking:stopLoopSound', loopId = loopId })
end

function StopAllSmokingLoopSounds()
    activeLoopSounds = {}
    SendNUIMessage({ message = 'rtx_smoking:stopAllLoopSounds' })
end

function RequestSmokingSound(soundKey, loopId, isLoop, shouldStop)
    if Config.SoundEffects ~= true or not soundKey then return end
    if isLoop == true and loopId then
        if shouldStop == true then
            localLoopStates[loopId] = nil
        else
            localLoopStates[loopId] = { soundKey = soundKey, startedAt = GetGameTimer() }
        end
    end
    TriggerServerEvent('rtx_smoking:server:RequestSound', {
        soundKey     = soundKey,
        loopId       = loopId,
        isLoop       = isLoop == true,
        shouldStop   = shouldStop == true,
        nearbyPlayers = GetNearbyPlayerServerIds(GetSoundDefaultDistance()),
    })
end

function StopLocalSmokingLoop(loopId)
    if not loopId then return end
    local state = localLoopStates[loopId]
    localLoopStates[loopId] = nil
    if not state then return end
    RequestSmokingSound(state.soundKey, loopId, true, true)
end

function StopAllLocalSmokingLoops()
    local prev = localLoopStates
    localLoopStates = {}
    for loopId, state in pairs(prev) do
        TriggerServerEvent('rtx_smoking:server:RequestSound', {
            soundKey     = state.soundKey,
            loopId       = loopId,
            isLoop       = true,
            shouldStop   = true,
            nearbyPlayers = GetNearbyPlayerServerIds(GetSoundDefaultDistance()),
        })
    end
end

function CleanupAllSmokingAudio()
    StopAllLocalSmokingLoops()
    StopAllSmokingLoopSounds()
end

function StopHookahInhaleAudio()
    StopLocalSmokingLoop('hookah_inhale_loop')
    StopSmokingLoopSound('player_' .. tostring(GetLocalServerIdValue()) .. '_hookah_inhale_loop')
end

function GetCurrentInhaleLoopIds()
    return { 'smoking_bong_loop', 'smoking_inhale_loop', 'vape_inhale_loop' }
end

function StopCurrentInhaleLoopSound()
    local typeKey, loopId = GetInhaleLoopSoundKeys(currentSmokingType)
    if typeKey and loopId then
        RequestSmokingSound(typeKey, loopId, true, true)
        local playerPrefix = 'player_' .. tostring(GetLocalServerIdValue()) .. '_'
        StopSmokingLoopSound(playerPrefix .. loopId)
    end
    for _, lid in ipairs(GetCurrentInhaleLoopIds()) do
        StopLocalSmokingLoop(lid)
        StopSmokingLoopSound('player_' .. tostring(GetLocalServerIdValue()) .. '_' .. lid)
    end
end

-- boucle de gestion de volume des sons en boucle
CreateThread(function()
    while true do
        Wait(200)
        if next(activeLoopSounds) then
            local now        = GetGameTimer()
            local origin     = GetEntityCoords(PlayerPedId())
            local maxDur     = Config.SoundLoopMaxDurationMs or 20000
            for loopId, ls in pairs(activeLoopSounds) do
                local stop = false
                local elapsed = now - ls.startedAt
                if elapsed > maxDur then
                    stop = true
                elseif ls.sourceId then
                    local pid = GetPlayerFromServerId(ls.sourceId)
                    if pid == -1 then
                        stop = true
                    else
                        local ped = GetPlayerPed(pid)
                        if not ped or ped == 0 or not DoesEntityExist(ped) or IsEntityDead(ped) then
                            stop = true
                        else
                            local dist = #(origin - GetEntityCoords(ped))
                            if dist > ls.maxDistance then
                                SetSmokingLoopSoundVolume(loopId, 0.0)
                                ls.outOfRangeSince = ls.outOfRangeSince or now
                                if Config.SoundLoopAutoStopOnDistance ~= false then
                                    local grace = Config.SoundLoopOutOfRangeGraceMs or 3000
                                    if now - ls.outOfRangeSince > grace then stop = true end
                                end
                            else
                                ls.outOfRangeSince = nil
                                local vol = ls.baseVolume * (1.0 - dist / ls.maxDistance)
                                if vol < 0.0 then vol = 0.0 end
                                SetSmokingLoopSoundVolume(loopId, vol)
                            end
                        end
                    end
                end
                if stop then StopSmokingLoopSound(loopId) end
            end
        end
        if next(localLoopStates) then
            local now    = GetGameTimer()
            local maxDur = Config.SoundLoopMaxDurationMs or 20000
            for loopId, state in pairs(localLoopStates) do
                if now - state.startedAt > maxDur then
                    StopLocalSmokingLoop(loopId)
                end
            end
        end
    end
end)

RegisterNetEvent('rtx_smoking:client:PlaySyncedSound')
AddEventHandler('rtx_smoking:client:PlaySyncedSound', function(soundData)
    if Config.SoundEffects ~= true or type(soundData) ~= 'table' then return end
    if soundData.shouldStop == true and soundData.loopId then
        StopSmokingLoopSound(soundData.loopId)
        return
    end
    if soundData.isLoop == true and soundData.loopId then
        activeLoopSounds[soundData.loopId] = {
            sourceId    = tonumber(soundData.sourceId),
            startedAt   = GetGameTimer(),
            baseVolume  = soundData.baseVolume  or GetSoundDefaultVolume(),
            maxDistance = soundData.maxDistance or GetSoundDefaultDistance(),
        }
        StartSmokingLoopSoundPath(soundData.loopId, soundData.src, soundData.volume)
        return
    end
    PlaySmokingSoundPath(soundData.src, soundData.volume)
end)

RegisterNetEvent('rtx_smoking:client:StopSyncedSoundLoop')
AddEventHandler('rtx_smoking:client:StopSyncedSoundLoop', function(loopId)
    StopSmokingLoopSound(loopId)
end)

RegisterNetEvent('rtx_smoking:client:StopAllSyncedSounds')
AddEventHandler('rtx_smoking:client:StopAllSyncedSounds', function()
    StopAllSmokingLoopSounds()
end)

-- ── géométrie ─────────────────────────────────────────────
function RotationToDirection(rotation)
    local rx = math.rad(rotation.x)
    local rz = math.rad(rotation.z)
    local h  = math.abs(math.cos(rx))
    return vector3(-math.sin(rz) * h, math.cos(rz) * h, math.sin(rx))
end

function GetInView(originX, originY, originZ, rotX, rotY, rotZ)
    local dir = RotationToDirection({ x = rotX, y = rotY, z = rotZ })
    local tx  = originX + dir.x * 10000.0
    local ty  = originY + dir.y * 10000.0
    local tz  = originZ + dir.z * 10000.0
    local handle = StartShapeTestRay(originX, originY, originZ, tx, ty, tz, -1, -1, 1)
    local _, _, endCoords, _, hitEntity = GetShapeTestResult(handle)
    if hitEntity <= 0 or GetEntityType(hitEntity) == 0 then
        return endCoords, nil, 0
    end
    local dist = #(vector3(originX, originY, originZ) - GetEntityCoords(hitEntity))
    if dist >= 100.0 then
        return endCoords, nil, dist
    end
    return endCoords, hitEntity, dist
end

function GetLookPosition()
    local ped    = PlayerPedId()
    local origin = GetEntityCoords(ped)
    local camRot = GetGameplayCamRot(2)
    local dir    = RotationToDirection(camRot)
    local bone   = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.0)
    local from   = bone + dir * 0.5
    local to     = bone + dir * 7.0
    local handle = StartShapeTestRay(from.x, from.y, from.z, to.x, to.y, to.z, 1, ped, 0)
    local status, hit, hitCoords = GetShapeTestResult(handle)
    local checks = 0
    while status == 1 and checks < 10 do
        Wait(0)
        status, hit, hitCoords = GetShapeTestResult(handle)
        checks = checks + 1
    end
    if status ~= 2 then return false, origin end
    if hit and hitCoords and hitCoords.x and hitCoords.y and hitCoords.z then
        local dist = #(origin - hitCoords)
        if dist > 50.0 then
            return false, origin
        end
        return true, hitCoords
    end
    return false, origin
end

-- ── NUI : fumée simple ────────────────────────────────────
function OpenSmokingUI(data)
    if type(data) ~= 'table' then return false end
    isSmokingUIOpen = true
    currentSmokingState = DeepCopy(data)
    SendNUIMessage({ action = 'smoking:open', data = currentSmokingState })
    return true
end

function UpdateSmokingUI(data)
    if not isSmokingUIOpen or type(data) ~= 'table' then return false end
    if not currentSmokingState then currentSmokingState = {} end
    for k, v in pairs(data) do
        currentSmokingState[k] = v
    end
    SendNUIMessage({ action = 'smoking:update', data = currentSmokingState })
    return true
end

function HideSmokingUI()
    if not isSmokingUIOpen then return false end
    isSmokingUIOpen = false
    currentSmokingState = nil
    SendNUIMessage({ action = 'smoking:hide' })
    return true
end

-- ── NUI : menu narguilé ───────────────────────────────────
function ToggleHookahNUI(visible)
    SendNUIMessage({ message = 'hookah:toggle', visible = visible })
end

function UpdateHookahNUI(data)
    SendNUIMessage({ message = 'hookah:update', data = data })
end

function SetInterfaceColor(colorData)
    SendNUIMessage({ message = 'updateinterfacedata', interfacecolordata = colorData })
end

-- ── attache narguilé ──────────────────────────────────────
function AttachMouthpieceToHandRight(ped, obj)
    if not obj or not DoesEntityExist(obj) then return end
    AttachEntityToEntity(
        obj, ped,
        GetPedBoneIndex(ped, HAND_BONE),
        HOSE_ATTACH_OFFSET_POS.x, HOSE_ATTACH_OFFSET_POS.y, HOSE_ATTACH_OFFSET_POS.z,
        HOSE_ATTACH_OFFSET_ROT.x, HOSE_ATTACH_OFFSET_ROT.y, HOSE_ATTACH_OFFSET_ROT.z,
        false, false, false, false, 2, true
    )
end

function AttachMouthpieceToHandLeft(ped, obj)
    if not obj or not DoesEntityExist(obj) then return end
    AttachEntityToEntity(
        obj, ped,
        GetPedBoneIndex(ped, HOOKAH_BONE),
        HOSE_MOUTHPIECE_OFFSET.x, HOSE_MOUTHPIECE_OFFSET.y, HOSE_MOUTHPIECE_OFFSET.z,
        HOSE_MOUTHPIECE_ROT.x,    HOSE_MOUTHPIECE_ROT.y,    HOSE_MOUTHPIECE_ROT.z,
        false, false, false, false, 2, true
    )
end

function PlayHookahSmokeAnimation(ped)
    RequestAnimDict('shishaanimsmoke@rtx')
    while not HasAnimDictLoaded('shishaanimsmoke@rtx') do Wait(0) end
    if not IsEntityPlayingAnim(ped, 'shishaanimsmoke@rtx', 'shishaanimsmoke', 3) then
        TaskPlayAnim(ped, 'shishaanimsmoke@rtx', 'shishaanimsmoke', 4.0, 4.0, -1, 49, 0.0, false, false, false)
    end
end

function StopHookahSmokeAnimation(ped)
    StopAnimTask(ped, 'shishaanimsmoke@rtx', 'shishaanimsmoke', 2.0)
end

function LoadModelSync(modelHash)
    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do Wait(0) end
    end
end

function GetHookahTipCoords(hookahEntity)
    if not hookahEntity or not DoesEntityExist(hookahEntity) then return nil end
    return GetOffsetFromEntityInWorldCoords(
        hookahEntity,
        HOOKAH_TIP_OFFSET_POS.x, HOOKAH_TIP_OFFSET_POS.y, HOOKAH_TIP_OFFSET_POS.z
    )
end

function GetMouthpieceTipCoords(mouthpieceEntity)
    if not mouthpieceEntity or not DoesEntityExist(mouthpieceEntity) then return nil end
    return GetOffsetFromEntityInWorldCoords(
        mouthpieceEntity,
        HOOKAH_TIP_OFFSET_ROT.x, HOOKAH_TIP_OFFSET_ROT.y, HOOKAH_TIP_OFFSET_ROT.z
    )
end

function CleanupHoseForPlayer(hookahIdStr, serverId)
    hookahIdStr = tostring(hookahIdStr)
    local hookah = hookahs[hookahIdStr]
    if not hookah or not hookah.hoses or not hookah.hoses.players then return end
    local hoseData = hookah.hoses.players[serverId]
    if not hoseData then return end
    if hoseData.ropehandler then
        DeleteRope(hoseData.ropehandler)
        hoseData.ropehandler = nil
    end
    if hoseData.mouthpiecehandler and DoesEntityExist(hoseData.mouthpiecehandler) then
        DeleteEntity(hoseData.mouthpiecehandler)
        hoseData.mouthpiecehandler = nil
    end
end

function SetupHoseForPlayer(hookahIdStr, serverId)
    hookahIdStr = tostring(hookahIdStr)
    local hookah = hookahs[hookahIdStr]
    if not hookah or not hookah.handler or not DoesEntityExist(hookah.handler) then return end

    hookah.hoses = hookah.hoses or { players = {} }
    hookah.hoses.players = hookah.hoses.players or {}
    hookah.hoses.players[serverId] = hookah.hoses.players[serverId] or {
        ropehandler = nil, mouthpiecehandler = nil
    }
    local hoseData = hookah.hoses.players[serverId]

    local pid = GetPlayerFromServerId(serverId)
    if pid == -1 then return end
    local ped = GetPlayerPed(pid)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end

    if not hoseData.mouthpiecehandler or not DoesEntityExist(hoseData.mouthpiecehandler) then
        LoadModelSync(MOUTHPIECE_MODEL)
        local coords = GetEntityCoords(ped)
        local obj = CreateObject(MOUTHPIECE_MODEL, coords.x, coords.y, coords.z, false, false, false)
        AttachEntityToEntity(
            obj, ped,
            GetPedBoneIndex(ped, HAND_BONE),
            MOUTHPIECE_OFFSET_POS.x, MOUTHPIECE_OFFSET_POS.y, MOUTHPIECE_OFFSET_POS.z,
            MOUTHPIECE_OFFSET_ROT.x, MOUTHPIECE_OFFSET_ROT.y, MOUTHPIECE_OFFSET_ROT.z,
            false, false, false, false, 2, true
        )
        hoseData.mouthpiecehandler = obj
    end

    if not hoseData.ropehandler then
        local tipA = GetHookahTipCoords(hookah.handler)
        local tipB = GetMouthpieceTipCoords(hoseData.mouthpiecehandler)
        if not tipA or not tipB then return end

        RopeLoadTextures()
        while not RopeAreTexturesLoaded() do Wait(0) end

        local rope = AddRope(
            tipA.x, tipA.y, tipA.z,
            0.0, 0.0, 0.0,
            ROPE_MAX_LENGTH, 4, 1000.0,
            ROPE_MIN_LENGTH, ROPE_INITIAL_LENGTH,
            false, false, false, 1.0, true
        )
        if rope then
            ActivatePhysics(rope)
            Wait(50)
            AttachEntitiesToRope(
                rope,
                hookah.handler, hoseData.mouthpiecehandler,
                tipA.x, tipA.y, tipA.z,
                tipB.x, tipB.y, tipB.z,
                ROPE_MAX_LENGTH,
                false, false, nil, nil
            )
            hoseData.ropehandler = rope
        end
    end
end

-- ── boucle de rendu des narguileés ───────────────────────
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped        = PlayerPedId()
        local myCoords   = GetEntityCoords(ped)

        for hookahIdVal, hookahData in pairs(hookahs) do
            local hookahIdStr = tostring(hookahIdVal)
            local hCoords = vector3(hookahData.coords.x, hookahData.coords.y, hookahData.coords.z)
            local dx = myCoords.x - hCoords.x
            local dy = myCoords.y - hCoords.y
            local dz = myCoords.z - hCoords.z
            local distSq = dx*dx + dy*dy + dz*dz
            local renderDist = Config.HookahRenderDistance
            local renderDistSq = renderDist * renderDist

            if distSq < renderDistSq then
                if hookahData.remove == true then
                    -- narguilé en cours de suppression : nettoyer les entités
                    if hookahData.handler and DoesEntityExist(hookahData.handler) then
                        DeleteEntity(hookahData.handler)
                        hookahData.handler = nil
                    end
                    if hookahData.tabacco and DoesEntityExist(hookahData.tabacco) then
                        DeleteEntity(hookahData.tabacco)
                        hookahData.tabacco = nil
                    end
                    if hookahData.hoses and hookahData.hoses.players then
                        for sid, _ in pairs(hookahData.hoses.players) do
                            CleanupHoseForPlayer(hookahIdStr, sid)
                        end
                    end
                else
                    -- ── spawner le modèle principal
                    if EnsureHookahEntity(hookahData) then

                    -- ── tabac rempli
                    local tobaccoState = GlobalState['rtxsmoking-' .. hookahIdStr .. '-tobacco-state']
                    if tobaccoState == 'filled' then
                        if not DoesEntityExist(hookahData.tabaccofilled) then
                            local mHash = GetHashKey('rtx_sempre_smoking_shisha_tobacco')
                            RequestModel(mHash)
                            while not HasModelLoaded(mHash) do RequestModel(mHash) Citizen.Wait(5) end
                            local obj = CreateObjectNoOffset(mHash, hookahData.coords.x, hookahData.coords.y, hookahData.coords.z, false, true, true)
                            hookahData.tabaccofilled = obj
                            FreezeEntityPosition(obj, true)
                            AttachEntityToEntity(obj, hookahData.handler, 0, 0.0, 0.0, 0.025, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                        end
                    else
                        if hookahData.tabaccofilled and DoesEntityExist(hookahData.tabaccofilled) then
                            DeleteEntity(hookahData.tabaccofilled)
                            hookahData.tabaccofilled = nil
                        end
                    end

                    -- ── tabac préparé (foil)
                    local tobaccoStatePrepared = GlobalState['rtxsmoking-' .. hookahIdStr .. '-tobacco-state']
                    if tobaccoStatePrepared == 'prepared' then
                        if not DoesEntityExist(hookahData.tabacco) then
                            local mHash = GetHashKey('rtx_sempre_smoking_shisha_foil')
                            RequestModel(mHash)
                            while not HasModelLoaded(mHash) do RequestModel(mHash) Citizen.Wait(5) end
                            local obj = CreateObjectNoOffset(mHash, hookahData.coords.x, hookahData.coords.y, hookahData.coords.z, false, true, true)
                            hookahData.tabacco = obj
                            FreezeEntityPosition(obj, true)
                            AttachEntityToEntity(obj, hookahData.handler, 0, 0.0, 0.0, 0.025, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                        end
                    else
                        if hookahData.tabacco and DoesEntityExist(hookahData.tabacco) then
                            DeleteEntity(hookahData.tabacco)
                            hookahData.tabacco = nil
                        end
                    end

                    -- ── charbon et brûleur
                    local coalState = GlobalState['rtxsmoking-' .. hookahIdStr .. '-coal-state']
                    if coalState == 'heating' or coalState == 'ready' then
                        if not DoesEntityExist(hookahData.burner) then
                            local mHash = GetHashKey('rtx_sempre_smoking_heater')
                            RequestModel(mHash)
                            while not HasModelLoaded(mHash) do RequestModel(mHash) Citizen.Wait(5) end
                            local obj = CreateObjectNoOffset(mHash, hookahData.coords.x, hookahData.coords.y, hookahData.coords.z, false, true, true)
                            hookahData.burner = obj
                            FreezeEntityPosition(obj, true)
                            AttachEntityToEntity(obj, hookahData.handler, 0, 0.3, -0.1, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                        end
                        if coalState == 'heating' then
                            if not DoesEntityExist(hookahData.coalobj) then
                                local mHash = GetHashKey('rtx_sempre_smoking_shisha_charcoal_cold')
                                RequestModel(mHash)
                                while not HasModelLoaded(mHash) do RequestModel(mHash) Citizen.Wait(5) end
                                local obj = CreateObjectNoOffset(mHash, hookahData.coords.x, hookahData.coords.y, hookahData.coords.z, false, true, true)
                                hookahData.coalobj = obj
                                FreezeEntityPosition(obj, true)
                                AttachEntityToEntity(obj, hookahData.burner, 0, 0.015, 0.0, -1.06, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                            end
                        else
                            if DoesEntityExist(hookahData.coalobj) then
                                DeleteEntity(hookahData.coalobj)
                            end
                        end
                        if coalState == 'ready' then
                            if not DoesEntityExist(hookahData.coalobj2) then
                                local mHash = GetHashKey('rtx_sempre_smoking_shisha_charcoal_hot')
                                RequestModel(mHash)
                                while not HasModelLoaded(mHash) do RequestModel(mHash) Citizen.Wait(5) end
                                local obj = CreateObjectNoOffset(mHash, hookahData.coords.x, hookahData.coords.y, hookahData.coords.z, false, true, true)
                                hookahData.coalobj2 = obj
                                FreezeEntityPosition(obj, true)
                                AttachEntityToEntity(obj, hookahData.burner, 0, 0.015, 0.0, -1.06, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                            end
                        else
                            if DoesEntityExist(hookahData.coalobj2) then
                                DeleteEntity(hookahData.coalobj2)
                            end
                        end
                    else
                        if DoesEntityExist(hookahData.burner)   then DeleteEntity(hookahData.burner)   end
                        if DoesEntityExist(hookahData.coalobj)  then DeleteEntity(hookahData.coalobj)  end
                        if DoesEntityExist(hookahData.coalobj2) then DeleteEntity(hookahData.coalobj2) end
                    end

                    -- ── couvercle avec charbon placé
                    local placedState  = GlobalState['rtxsmoking-' .. hookahIdStr .. '-coal-state']
                    local tobaccoState2 = GlobalState['rtxsmoking-' .. hookahIdStr .. '-tobacco-state']
                    if placedState == 'placed' and tobaccoState2 == 'prepared' then
                        if not DoesEntityExist(hookahData.cover) then
                            local mHash = GetHashKey('rtx_sempre_smoking_shisha_cover')
                            RequestModel(mHash)
                            while not HasModelLoaded(mHash) do RequestModel(mHash) Citizen.Wait(5) end
                            local obj = CreateObjectNoOffset(mHash, hookahData.coords.x, hookahData.coords.y, hookahData.coords.z, false, true, true)
                            hookahData.cover = obj
                            FreezeEntityPosition(obj, true)
                            AttachEntityToEntity(obj, hookahData.handler, 0, 0.0, 0.0, 0.025, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                        end
                        if not DoesEntityExist(hookahData.covercoal) then
                            local mHash = GetHashKey('rtx_sempre_smoking_shisha_charcoal_hot')
                            RequestModel(mHash)
                            while not HasModelLoaded(mHash) do RequestModel(mHash) Citizen.Wait(5) end
                            local obj = CreateObjectNoOffset(mHash, hookahData.coords.x, hookahData.coords.y, hookahData.coords.z, false, true, true)
                            hookahData.covercoal = obj
                            FreezeEntityPosition(obj, true)
                            AttachEntityToEntity(obj, hookahData.handler, 0, 0.0, 0.0, 0.025, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                        end
                    else
                        if hookahData.cover and DoesEntityExist(hookahData.cover) then
                            DeleteEntity(hookahData.cover)
                            hookahData.cover = nil
                        end
                        if hookahData.covercoal and DoesEntityExist(hookahData.covercoal) then
                            DeleteEntity(hookahData.covercoal)
                            hookahData.covercoal = nil
                        end
                    end

                    -- ── tuyaux des joueurs
                    if hookahData.hoses and hookahData.hoses.players then
                        for sid, hoseData in pairs(hookahData.hoses.players) do
                            SetupHoseForPlayer(hookahIdStr, sid)
                            hoseData = hookahData.hoses.players[sid]
                            if hoseData and hoseData.mouthpiecehandler and DoesEntityExist(hoseData.mouthpiecehandler) then
                                local hoseStateKey     = 'rtxsmoking-' .. hookahIdStr .. '-hose-' .. sid .. '-state'
                                local hoseConnectedKey = 'rtxsmoking-' .. hookahIdStr .. '-hose-' .. sid .. '-connected'
                                local hoseState     = GlobalState[hoseStateKey] or 'idle'
                                local hoseConnected = GlobalState[hoseConnectedKey] == true
                                local pidRemote     = GetPlayerFromServerId(sid)
                                if pidRemote ~= -1 then
                                    local remotePed = GetPlayerPed(pidRemote)
                                    if remotePed and remotePed ~= 0 and DoesEntityExist(remotePed) then
                                        hoseData.laststate = hoseData.laststate or 'idle'
                                        if not hoseConnected then
                                            CleanupHoseForPlayer(hookahIdStr, sid)
                                        else
                                            if hoseState == 'inhale' then
                                                AttachMouthpieceToHandLeft(remotePed, hoseData.mouthpiecehandler)
                                                PlayHookahSmokeAnimation(remotePed)
                                            else
                                                AttachMouthpieceToHandRight(remotePed, hoseData.mouthpiecehandler)
                                                if hoseData.laststate == 'inhale' then
                                                    StopHookahSmokeAnimation(remotePed)
                                                end
                                            end
                                            hoseData.laststate = hoseState
                                        end
                                    end
                                end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ── boucle de détection du narguilé le plus proche ────────
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped        = PlayerPedId()
        local myCoords   = GetEntityCoords(ped)
        local foundId    = nil
        local bestDistSq = -1

        if not hookahMenuOpen and not isPlacingHookah and not hookahHoseActive then
            for hookahIdVal, hookahData in pairs(hookahs) do
                local hCoords = vector3(hookahData.coords.x, hookahData.coords.y, hookahData.coords.z)
                local dx = myCoords.x - hCoords.x
                local dy = myCoords.y - hCoords.y
                local dz = myCoords.z - hCoords.z
                local dSq = dx*dx + dy*dy + dz*dz
                local interactDist = Config.HookahInteractDistance
                if Config.Target == true then
                    interactDist = interactDist + 5.0
                end
                local threshSq = interactDist * interactDist
                if dSq < threshSq and (bestDistSq == -1 or bestDistSq > dSq) then
                    bestDistSq = dSq
                    foundId    = hookahIdVal
                end
            end
        end

        if foundId then
            nearestHookahId = foundId
            if Config.Target ~= true then
                ShowInteraction('hookahinteract', hookahs[foundId].coords)
            end
        else
            if nearestHookahId ~= nil then
                HideInteraction()
            end
            nearestHookahId = nil
        end

        if not foundId then
            Citizen.Wait(1000)
        end
    end
end)

-- ── initialisation ────────────────────────────────────────
local smokingResourceInitialized = false

function InitializeSmoking()
    if smokingResourceInitialized then return end
    smokingResourceInitialized = true

    SendNUIMessage({
        message = 'updateinterfacedata',
        interfacecolordata = Config.InterfaceColor,
        smokingresourcenamedata = tostring(GetCurrentResourceName()),
    })

    if Config.Target == true then
        CreateHookahTargets()
    end

    SendNUIMessage({
        message = 'hookah:setLocale',
        locale  = {
            state_empty    = Language[Config.Language].state_empty,
            state_low      = Language[Config.Language].state_low,
            state_good     = Language[Config.Language].state_good,
            state_filled   = Language[Config.Language].state_filled,
            state_prepared = Language[Config.Language].state_prepared,
            state_missing  = Language[Config.Language].state_missing,
            state_heating  = Language[Config.Language].state_heating,
            state_ready    = Language[Config.Language].state_ready,
            state_placed   = Language[Config.Language].state_placed,
            ready          = Language[Config.Language].ready,
            preparing      = Language[Config.Language].preparing,
            removehookah   = Language[Config.Language].removehookah,
            forceremovehookah = Language[Config.Language].forceremovehookah,
            adminforceremove  = Language[Config.Language].adminforceremove,
            nohookahpermission = Language[Config.Language].nohookahpermission,
        },
    })

    TriggerServerEvent('rtx_smoking:server:SynchHookah')
end

AddEventHandler('playerSpawned', function()
    Citizen.CreateThread(function()
        Citizen.Wait(2000)
        InitializeSmoking()
    end)
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Citizen.CreateThread(function()
        while true do
            if NetworkIsPlayerActive(PlayerId()) and DoesEntityExist(PlayerPedId()) then
                break
            end
            Citizen.Wait(500)
        end
        Citizen.Wait(1000)
        InitializeSmoking()
    end)
end)

RegisterNetEvent('rtx_smoking:Global:SynchHookahs')
AddEventHandler('rtx_smoking:Global:SynchHookahs', function(hookahList)
    if type(hookahList) ~= 'table' then
        print('[RTX SMOKING] Ignored invalid hookah synchronization payload.')
        return
    end

    local incomingIds = {}
    for id in pairs(hookahList) do
        incomingIds[tostring(id)] = true
    end
    for id in pairs(hookahs) do
        if not incomingIds[tostring(id)] then
            TriggerEvent('rtx_smoking:Global:HookahRemove', id)
        end
    end

    local clientEntityFields = {
        'handler', 'tabacco', 'tabaccofilled', 'burner',
        'coalobj', 'coalobj2', 'cover', 'covercoal',
    }
    for id, data in pairs(hookahList) do
        if type(data) == 'table' and type(data.coords) == 'vector3' or
            (type(data) == 'table' and type(data.coords) == 'table'
                and tonumber(data.coords.x) and tonumber(data.coords.y) and tonumber(data.coords.z))
        then
            local key = tostring(id)
            local existing = hookahs[key]
            if existing then
                local moved = #(vector3(existing.coords.x, existing.coords.y, existing.coords.z)
                    - vector3(data.coords.x, data.coords.y, data.coords.z)) > 0.01
                if moved then
                    TriggerEvent('rtx_smoking:Global:HookahRemove', key)
                    existing = nil
                end
            end
            if existing then
                for _, field in ipairs(clientEntityFields) do
                    if data[field] == nil then data[field] = existing[field] end
                end
                if type(data.hoses) == 'table' and type(existing.hoses) == 'table' then
                    local incomingPlayers = type(data.hoses.players) == 'table' and data.hoses.players or {}
                    local existingPlayers = type(existing.hoses.players) == 'table' and existing.hoses.players or {}
                    local synchronizedPlayers = {}
                    for serverId, playerData in pairs(incomingPlayers) do
                        local oldPlayerData = existingPlayers[serverId] or existingPlayers[tostring(serverId)]
                        if type(playerData) == 'table' and type(oldPlayerData) == 'table' then
                            playerData.ropehandler = playerData.ropehandler or oldPlayerData.ropehandler
                            playerData.mouthpiecehandler = playerData.mouthpiecehandler or oldPlayerData.mouthpiecehandler
                        end
                        synchronizedPlayers[serverId] = playerData
                    end
                    for serverId in pairs(existingPlayers) do
                        if not incomingPlayers[serverId] and not incomingPlayers[tonumber(serverId)] then
                            CleanupHoseForPlayer(key, serverId)
                        end
                    end
                    data.hoses.players = synchronizedPlayers
                end
            end
            hookahs[key] = data
        else
            print(('[RTX SMOKING] Ignored invalid hookah data for id "%s".'):format(tostring(id)))
        end
    end
end)

-- ── placement d'un narguilé ───────────────────────────────
function PlaceHookah(hookahType, colorIndex)
    local modelHash = GetHashKey('rtx_sempre_smoking_shisha')
    if not IsModelInCdimage(modelHash) or not IsModelValid(modelHash) then
        print('[RTX SMOKING] Hookah model rtx_sempre_smoking_shisha is unavailable. Check that rtx_smoking_objects is started.')
        Notify('error', 'Shisha', 'Hookah model is unavailable.')
        return
    end

    isPlacingHookah = true

    SendNUIMessage({
        message     = 'showKeymap',
        actionLabel = Language[Config.Language].placehookah,
        keys = {
            { key = 'ENTER',     label = Language[Config.Language].confirmplacement },
            { key = 'ARROWS',    label = Language[Config.Language].rotate           },
            { key = 'BACKSPACE', label = Language[Config.Language].cancel           },
        },
    })

    RequestModel(modelHash)
    local modelTimeoutAt = GetGameTimer() + 10000
    while not HasModelLoaded(modelHash) and GetGameTimer() < modelTimeoutAt do
        Wait(0)
    end
    if not HasModelLoaded(modelHash) then
        isPlacingHookah = false
        SendNUIMessage({ message = 'hideKeymap' })
        print('[RTX SMOKING] Timed out loading model rtx_sempre_smoking_shisha.')
        Notify('error', 'Shisha', 'Hookah model did not load.')
        return
    end

    local ped            = PlayerPedId()
    local spawnCoords    = GetEntityCoords(ped)
    local initialHeading = GetEntityHeading(ped)
    pointerheading       = initialHeading

    local previewObj = CreateObjectNoOffset(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, true, true)
    SetModelAsNoLongerNeeded(modelHash)
    if not previewObj or previewObj == 0 or not DoesEntityExist(previewObj) then
        isPlacingHookah = false
        SendNUIMessage({ message = 'hideKeymap' })
        print('[RTX SMOKING] Failed to create hookah placement preview.')
        Notify('error', 'Shisha', 'Hookah preview could not be created.')
        return
    end
    placingHookahObject = previewObj
    SetEntityHeading(previewObj, pointerheading)
    FreezeEntityPosition(previewObj, true)
    SetEntityAlpha(previewObj, 155)
    SetObjectTextureVariation(previewObj, colorIndex)
    SetEntityCompletelyDisableCollision(previewObj, false, false)
    SetEntityVisible(previewObj, false)

    Citizen.CreateThread(function()
        while isPlacingHookah do
            Citizen.Wait(0)

            if IsEntityDead(PlayerPedId()) then
                isPlacingHookah = false
                SendNUIMessage({ message = 'hideKeymap' })
                break
            end

            local validPos, lookPos = GetLookPosition()
            if validPos and lookPos then
                SetEntityVisible(previewObj, true)
                if IsControlPressed(0, 174) then pointerheading = pointerheading - 1.0 end
                if IsControlPressed(0, 175) then pointerheading = pointerheading + 1.0 end
                if pointerheading < 0.0   then pointerheading = pointerheading + 360.0 end
                if pointerheading >= 360.0 then pointerheading = pointerheading - 360.0 end
                SetEntityCoordsNoOffset(previewObj, lookPos.x, lookPos.y, lookPos.z)
                SetEntityHeading(previewObj, pointerheading)

                if IsControlJustPressed(0, 191) then
                    isPlacingHookah = false
                    DeleteEntity(previewObj)
                    placingHookahObject = nil
                    SendNUIMessage({ message = 'hideKeymap' })
                    TriggerServerEvent(
                        'rtx_smoking:Global:PlaceHookah',
                        vector3(lookPos.x, lookPos.y, lookPos.z),
                        vector3(0.0, 0.0, pointerheading),
                        hookahType
                    )
                end
            else
                SetEntityVisible(previewObj, false)
            end

            if IsControlJustPressed(0, 194) then
                SendNUIMessage({ message = 'hideKeymap' })
                isPlacingHookah = false
                DeleteEntity(previewObj)
                placingHookahObject = nil
            end
        end

        if previewObj and DoesEntityExist(previewObj) then
            DeleteEntity(previewObj)
        end
        placingHookahObject = nil
        SetModelAsNoLongerNeeded(modelHash)
    end)
end

function CancelHookahPlacement()
    if not isPlacingHookah and not placingHookahObject then return end
    isPlacingHookah = false
    if placingHookahObject and DoesEntityExist(placingHookahObject) then
        DeleteEntity(placingHookahObject)
    end
    placingHookahObject = nil
    SendNUIMessage({ message = 'hideKeymap' })
end

-- ── narguilé : caméra menu ───────────────────────────────
function CloseHookahCamera()
    hookahCameraTransition = false
    if DoesCamExist(hookahCamera) then
        DestroyCam(hookahCamera, true)
        hookahCamera = nil
    end
    RenderScriptCams(false, true, 500, true, true)
end

function OpenHookahCamera(hookahEntity, transitionMs)
    if DoesCamExist(hookahCamera) then
        DestroyCam(hookahCamera, true)
        hookahCamera = nil
    end
    hookahCameraTransition = true

    local entityCoords = GetEntityCoords(hookahEntity)
    local camStart     = GetOffsetFromEntityInWorldCoords(hookahEntity, 0.0, 2.8, 1.2)
    local camEnd       = GetOffsetFromEntityInWorldCoords(hookahEntity, 0.0, 1.8, 1.0)
    local lookAtStart  = vector3(entityCoords.x, entityCoords.y, entityCoords.z + 0.9)
    local lookAtEnd    = vector3(entityCoords.x, entityCoords.y, entityCoords.z + 0.58)
    local fovStart     = 50.0
    local fovEnd       = 40.0

    hookahCamera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(hookahCamera, camStart.x, camStart.y, camStart.z)
    PointCamAtCoord(hookahCamera, lookAtStart.x, lookAtStart.y, lookAtStart.z)
    SetCamFov(hookahCamera, fovStart)
    SetCamActive(hookahCamera, true)
    RenderScriptCams(true, true, 0, true, true)

    local startTime = GetGameTimer()

    Citizen.CreateThread(function()
        while hookahCameraTransition do
            if not hookahMenuOpen then break end
            local elapsed = GetGameTimer() - startTime
            local t = elapsed / transitionMs
            if t > 1.0 then t = 1.0 end

            -- ease in-out cubic
            local eased
            if t < 0.5 then
                eased = 4.0 * t * t * t
            else
                local inv = -2.0 * t + 2.0
                eased = 1.0 - (inv * inv * inv) / 2.0
            end

            local function lerpVal(a, b, f) return a + (b - a) * f end
            local function lerpVec(a, b, f)
                return vector3(lerpVal(a.x, b.x, f), lerpVal(a.y, b.y, f), lerpVal(a.z, b.z, f))
            end

            local camPos  = lerpVec(camStart,    camEnd,    eased)
            local lookAt  = lerpVec(lookAtStart, lookAtEnd, eased)
            local fov     = lerpVal(fovStart,    fovEnd,    eased)

            SetCamCoord(hookahCamera, camPos.x, camPos.y, camPos.z)
            PointCamAtCoord(hookahCamera, lookAt.x, lookAt.y, lookAt.z)
            SetCamFov(hookahCamera, fov)

            if t >= 1.0 then break end
            Wait(0)
        end
        hookahCameraTransition = false
    end)
end

-- ── narguilé : hose (tuyau) local ─────────────────────────
function CanSmokeFromHookah()
    if not hookahHoseHookahId then return false end
    return GlobalState['rtxsmoking-' .. hookahHoseHookahId .. '-can-smoke'] == true
end

function LockPedHeading()
    local ped = PlayerPedId()
    if not hookahLockedHeading then
        hookahLockedHeading = GetEntityHeading(ped)
    end
    SetPedCanHeadIk(ped, false)
end

function UnlockPedHeading()
    PlayerPedId()
    hookahLockedHeading = nil
    SetPedCanHeadIk(PlayerPedId(), true)
end

function DisableCameraMovementControls()
    if not hookahLockedHeading then return end
    for _, control in ipairs({1, 2, 3, 4, 5, 6}) do
        DisableControlAction(0, control, true)
    end
end

local hookahForceReleaseTimer = 0
local hookahForceReleaseActive = false

function PlayHookahCoughAnimation()
    local cfg = Config.HookahForceRelease
    if not cfg or cfg.enabled ~= true then return end
    local ped = PlayerPedId()
    RequestAnimDict(cfg.dict)
    while not HasAnimDictLoaded(cfg.dict) do Wait(0) end
    TaskPlayAnim(
        ped,
        cfg.dict,
        cfg.anim,
        8.0, -8.0,
        cfg.durationMs or 1500,
        cfg.flag or 49,
        0.0, false, false, false
    )
end

function StopHookahInhaleAudio()
    StopLocalSmokingLoop('hookah_inhale_loop')
    StopSmokingLoopSound('player_' .. tostring(GetLocalServerIdValue()) .. '_hookah_inhale_loop')
end

function AbortHookahInhale(notifyServer)
    if hookahForceReleaseTimer <= 0 then
        StopHookahInhaleAudio()
        UnlockPedHeading()
        return
    end
    local elapsed = GetGameTimer() - hookahForceReleaseTimer
    hookahForceReleaseTimer = 0
    UnlockPedHeading()
    StopHookahInhaleAudio()
    if notifyServer ~= false and hookahHoseHookahId then
        TriggerServerEvent('rtx_smoking:Global:HookahInhaleStop', hookahHoseHookahId, elapsed)
    end
end

function TriggerHookahForceRelease()
    local elapsed = GetGameTimer() - hookahForceReleaseTimer
    hookahForceReleaseTimer = 0
    hookahForceReleaseActive = true
    UnlockPedHeading()
    StopHookahInhaleAudio()
    RequestSmokingSound('hookahInhale', 'hookah_inhale_loop', true, true)
    RequestSmokingSound(GetCoughSoundKey(), nil, false, false)
    TriggerServerEvent('rtx_smoking:Global:HookahInhaleStop', hookahHoseHookahId, elapsed)
    PlayHookahCoughAnimation()
end

function StartHookahForceReleaseWatcher()
    CreateThread(function()
        while hookahForceReleaseTimer > 0 do
            local cfg = Config.HookahForceRelease
            if cfg and cfg.enabled == true then
                local elapsed  = GetGameTimer() - hookahForceReleaseTimer
                local maxHold  = cfg.maxHoldMs or 4500
                if elapsed >= maxHold then
                    TriggerHookahForceRelease()
                    return
                end
            end
            Wait(50)
        end
    end)
end

function ExitHookahHose(notifyServer)
    AbortHookahInhale(notifyServer)
    if notifyServer ~= false then
        TriggerServerEvent('rtx_smoking:Global:DisconnectHose')
    end
    SetLocalHookahHolding(false)
    HideSmokingUI()
    UnlockPedHeading()
end

function BuildHookahSmokingUIData()
    local hookahData = hookahs[tostring(hookahHoseHookahId)]
    if not hookahData then return {} end
    local hid = hookahHoseHookahId
    return {
        type         = 'shisha',
        itemLabel    = 'Hookah',
        icon         = 'img/shisha_' .. Config.HookahTypes[hookahData.type].color .. '.png',
        flavour      = GlobalState['rtxsmoking-' .. hid .. '-tobacco-flavor'],
        flavourPercent = GlobalState['rtxsmoking-' .. hid .. '-tobacco-amount'],
        waterPercent = GlobalState['rtxsmoking-' .. hid .. '-water-level'],
        statusPercent = GlobalState['rtxsmoking-' .. hid .. '-tobacco-amount'],
        lit          = true,
    }
end

function SetLocalHookahHolding(active, hookahId)
    if active == true then
        hookahHoseActive      = true
        hookahHoseHookahId    = tostring(hookahId)
        hookahForceReleaseTimer = 0
        SendNUIMessage({
            action = 'SmokingOpen',
            data   = BuildHookahSmokingUIData(),
        })
        StartHookahHoseLoop()
    else
        hookahHoseActive      = false
        hookahHoseHookahId    = nil
        hookahForceReleaseTimer = 0
        StopHookahInhaleAudio()
        SendNUIMessage({ action = 'SmokingHide' })
    end
end

function StartHookahHoseLoop()
    if isSmokingBusy then return end
    isSmokingBusy = true

    CreateThread(function()
        while hookahHoseActive do
            Wait(0)
            local hid = hookahHoseHookahId
            if not hid then break end

            local ped = PlayerPedId()
            if IsEntityDead(ped) then
                ExitHookahHose(true)
                break
            end

            local hookahData = hookahs[tostring(hid)]
            if not hookahData or hookahData.remove == true then
                ExitHookahHose(true)
                break
            end

            local pedCoords    = GetEntityCoords(ped)
            local hookahCoords = vector3(hookahData.coords.x, hookahData.coords.y, hookahData.coords.z)
            local dist = #(pedCoords - hookahCoords)
            if dist > Config.HookahMaxHoseDistance then
                ExitHookahHose(true)
                break
            end

            UpdateSmokingUI(BuildHookahSmokingUIData())

            if CanSmokeFromHookah() then
                if IsControlJustPressed(0, 38) then
                    LockPedHeading()
                    hookahForceReleaseTimer = GetGameTimer()
                    hookahForceReleaseActive = false
                    RequestSmokingSound('hookahInhale', 'hookah_inhale_loop', true, false)
                    TriggerServerEvent('rtx_smoking:Global:HookahInhaleStart', hid)
                    StartHookahForceReleaseWatcher()
                end

                if IsControlJustReleased(0, 38) then
                    if hookahForceReleaseTimer > 0 then
                        local elapsed = GetGameTimer() - hookahForceReleaseTimer
                        hookahForceReleaseTimer = 0
                        UnlockPedHeading()
                        RequestSmokingSound('hookahInhale', 'hookah_inhale_loop', true, true)
                        RequestSmokingSound(GetExhaleSoundKey('hookah'), nil, false, false)
                        TriggerServerEvent('rtx_smoking:Global:HookahInhaleStop', hid, elapsed)
                    end
                end
            end

            if hookahForceReleaseTimer > 0 then
                DisableCameraMovementControls()
            end

            if IsControlJustPressed(0, 194) then
                ExitHookahHose(true)
                break
            end
        end

        isSmokingBusy = false
        AbortHookahInhale(false)
    end)
end

-- ── callbacks NUI narguilé ───────────────────────────────
RegisterNUICallback('hookahFillWater', function(data, cb)
    if hookahMenuOpen and hookahMenuHookahId ~= nil then
        TriggerServerEvent('rtx_smoking:Global:HookahWater', hookahMenuHookahId)
    end
    cb('ok')
end)

RegisterNUICallback('hookahSelectFlavor', function(data, cb)
    if hookahMenuOpen and hookahMenuHookahId ~= nil then
        local flavorKey = data.flavorKey or 'Unknown'
        TriggerServerEvent('rtx_smoking:Global:FlavorSelect', hookahMenuHookahId, flavorKey)
    end
    cb('ok')
end)

RegisterNUICallback('hookahPrepareOrChangeBowl', function(data, cb)
    if hookahMenuOpen and hookahMenuHookahId ~= nil then
        TriggerServerEvent('rtx_smoking:Global:FlavorPrepare', hookahMenuHookahId)
    end
    cb('ok')
end)

RegisterNUICallback('hookahLightCoal', function(data, cb)
    if hookahMenuOpen and hookahMenuHookahId ~= nil then
        TriggerServerEvent('rtx_smoking:Global:CoalHeat', hookahMenuHookahId)
    end
    cb('ok')
end)

RegisterNUICallback('hookahPlaceCoal', function(data, cb)
    if hookahMenuOpen and hookahMenuHookahId ~= nil then
        TriggerServerEvent('rtx_smoking:Global:CoalPlace', hookahMenuHookahId)
    end
    cb('ok')
end)

RegisterNUICallback('hookahConnectHose', function(data, cb)
    if hookahMenuOpen and hookahMenuHookahId ~= nil then
        TriggerServerEvent('rtx_smoking:Global:ConnectHose', hookahMenuHookahId)
    end
    cb('ok')
end)

RegisterNUICallback('hookahClean', function(data, cb)
    if hookahMenuOpen and hookahMenuHookahId ~= nil then
        TriggerServerEvent('rtx_smoking:Global:CleanHookah', hookahMenuHookahId)
    end
    cb('ok')
end)

RegisterNUICallback('hookahQuit', function(data, cb)
    if hookahMenuOpen and hookahMenuHookahId ~= nil then
        TriggerServerEvent('rtx_smoking:Global:HookahClose', hookahMenuHookahId)
        CloseHookahMenuLocal()
    end
    cb('ok')
end)

RegisterNUICallback('hookahRemove', function(data, cb)
    if hookahMenuOpen and hookahMenuHookahId ~= nil then
        TriggerServerEvent('rtx_smoking:Global:RemoveHookah', hookahMenuHookahId)
    end
    cb('ok')
end)

RegisterNUICallback('closemenu', function(data, cb)
    isSmokingMenuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- ── événements réseau narguilé ───────────────────────────
RegisterNetEvent('rtx_smoking:Notify')
AddEventHandler('rtx_smoking:Notify', function(notifType, title, message)
    Notify(notifType, title, message)
end)

RegisterNetEvent('rtx_smoking:Global:HookahCreate')
AddEventHandler('rtx_smoking:Global:HookahCreate', function(hookahId, hookahData)
    hookahs[tostring(hookahId)] = hookahData
end)

RegisterNetEvent('rtx_smoking:Global:Remove')
AddEventHandler('rtx_smoking:Global:Remove', function()
    CloseHookahMenuLocal()
end)

function EnsureHookahEntity(hookahData)
    if hookahData.handler and DoesEntityExist(hookahData.handler) then return true end

    local hookahType = Config.HookahTypes[hookahData.type]
    if not hookahType then
        print(('[RTX SMOKING] Cannot spawn hookah with invalid type "%s"'):format(tostring(hookahData.type)))
        return false
    end

    local modelHash = GetHashKey('rtx_sempre_smoking_shisha')
    if not IsModelInCdimage(modelHash) or not IsModelValid(modelHash) then
        print('[RTX SMOKING] Hookah model rtx_sempre_smoking_shisha is unavailable. Check that rtx_smoking_objects is started.')
        return false
    end

    RequestModel(modelHash)
    local timeoutAt = GetGameTimer() + 10000
    while not HasModelLoaded(modelHash) and GetGameTimer() < timeoutAt do
        Wait(0)
    end
    if not HasModelLoaded(modelHash) then
        print('[RTX SMOKING] Timed out loading model rtx_sempre_smoking_shisha.')
        return false
    end

    local coords = hookahData.coords
    local obj = CreateObjectNoOffset(modelHash, coords.x, coords.y, coords.z, false, true, true)
    SetModelAsNoLongerNeeded(modelHash)
    if not obj or obj == 0 or not DoesEntityExist(obj) then
        print('[RTX SMOKING] Failed to create hookah prop.')
        return false
    end

    hookahData.handler = obj
    FreezeEntityPosition(obj, true)
    local rotation = hookahData.rotation or vector3(0.0, 0.0, 0.0)
    SetEntityRotation(obj, rotation.x, rotation.y, rotation.z, 2, true)
    SetObjectTextureVariation(obj, hookahType.color or 0)
    return true
end

RegisterNetEvent('rtx_smoking:Global:OpenHookah')
AddEventHandler('rtx_smoking:Global:OpenHookah', function(hookahId, permissions, permsData)
    if hookahMenuOpen then return end

    local hookahData = hookahs[tostring(hookahId)]
    if not hookahData or not EnsureHookahEntity(hookahData) then
        Notify('error', 'Shisha', 'Hookah prop could not be loaded. Check the server console for model/resource errors.')
        return
    end

    local ped = PlayerPedId()
    SetEntityVisible(ped, false)
    hookahMenuOpen      = true
    hookahMenuHookahId  = hookahId

    HideInteraction()

    SendNUIMessage({ message = 'hookah:setFlavors', flavors = Config.HookahFlavors })

    permsData = permsData or {}
    SendNUIMessage({
        message   = 'hookah:setPermissions',
        canRemove = permsData.canRemove == true,
        isAdmin   = permsData.isAdmin   == true,
        static    = permsData.static    == true,
    })

    OpenHookahCamera(hookahData.handler, 900)
    SetNuiFocus(true, true)
    ToggleHookahNUI(true)

    UpdateHookahNUI({
        water   = { state = hookahData.water.state,   level      = hookahData.water.level        },
        tobacco = { state = hookahData.tobacco.state, amount     = hookahData.tobacco.amount, flavor = hookahData.tobacco.flavor },
        coal    = { state = hookahData.coal.state,    progress   = hookahData.coal.progress, durability = hookahData.coal.durability },
        hoses   = {
            connected = GlobalState['rtxsmoking-' .. hookahId .. '-connected'] or 0,
            max       = Config.MaxHoses,
        },
        visible = true,
    })

    while hookahMenuOpen do
        Citizen.Wait(50)
        UpdateHookahNUI({
            water   = {
                state = GlobalState['rtxsmoking-' .. hookahId .. '-water-state'],
                level = GlobalState['rtxsmoking-' .. hookahId .. '-water-level'],
            },
            tobacco = {
                state  = GlobalState['rtxsmoking-' .. hookahId .. '-tobacco-state'],
                amount = GlobalState['rtxsmoking-' .. hookahId .. '-tobacco-amount'],
                flavor = GlobalState['rtxsmoking-' .. hookahId .. '-tobacco-flavor'],
            },
            coal = {
                state      = GlobalState['rtxsmoking-' .. hookahId .. '-coal-state'],
                progress   = GlobalState['rtxsmoking-' .. hookahId .. '-coal-progress'],
                durability = GlobalState['rtxsmoking-' .. hookahId .. '-coal-durability'],
            },
            hoses = {
                connected = GlobalState['rtxsmoking-' .. hookahId .. '-connected'] or 0,
                max       = Config.MaxHoses,
            },
            status   = GlobalState['rtxsmoking-' .. hookahId .. '-status'],
            canSmoke = GlobalState['rtxsmoking-' .. hookahId .. '-can-smoke'],
        })
    end
end)

RegisterNetEvent('rtx_smoking:Global:HookahRemove')
AddEventHandler('rtx_smoking:Global:HookahRemove', function(hookahId)
    local hookahIdStr = tostring(hookahId)
    local hookahData  = hookahs[hookahIdStr]
    if not hookahData then return end
    hookahData.remove = true

    if hookahHoseActive and tostring(hookahHoseHookahId) == hookahIdStr then
        ExitHookahHose(false)
    end

    if hookahMenuOpen and hookahMenuHookahId and tostring(hookahMenuHookahId) == hookahIdStr then
        CloseHookahMenuLocal()
    end

    if hookahData.hoses and hookahData.hoses.players then
        for sid, _ in pairs(hookahData.hoses.players) do
            CleanupHoseForPlayer(hookahIdStr, sid)
        end
    end

    local entitiesToDelete = {
        'tabacco', 'handler', 'tabaccofilled', 'tabacco',
        'burner', 'coalobj', 'coalobj2', 'cover', 'covercoal',
    }
    for _, key in ipairs(entitiesToDelete) do
        if hookahData[key] and DoesEntityExist(hookahData[key]) then
            DeleteEntity(hookahData[key])
            hookahData[key] = nil
        end
    end

    hookahs[hookahIdStr] = nil

    if hookahHoseHookahId and tostring(hookahHoseHookahId) == hookahIdStr then
        SetLocalHookahHolding(false)
    end
end)

RegisterNetEvent('rtx_smoking:Global:UpdateWater')
AddEventHandler('rtx_smoking:Global:UpdateWater', function(hookahId, waterData)
    if hookahMenuOpen and tostring(hookahMenuHookahId) == tostring(hookahId) then
        UpdateHookahNUI({ water = { state = waterData.state, level = waterData.level } })
    end
end)

RegisterNetEvent('rtx_smoking:Global:UpdateTabacco')
AddEventHandler('rtx_smoking:Global:UpdateTabacco', function(hookahId, tobaccoData)
    if hookahMenuOpen and tostring(hookahMenuHookahId) == tostring(hookahId) then
        UpdateHookahNUI({ tobacco = { state = tobaccoData.state, amount = tobaccoData.amount, flavor = tobaccoData.flavor } })
    end
end)

RegisterNetEvent('rtx_smoking:Global:UpdateCoal')
AddEventHandler('rtx_smoking:Global:UpdateCoal', function(hookahId, coalData)
    if hookahMenuOpen and tostring(hookahMenuHookahId) == tostring(hookahId) then
        UpdateHookahNUI({ coal = { state = coalData.state, progress = coalData.progress, durability = coalData.durability } })
    end
end)

RegisterNetEvent('rtx_smoking:Global:HosePlayerAdded')
AddEventHandler('rtx_smoking:Global:HosePlayerAdded', function(hookahId, serverId)
    local hookahIdStr = tostring(hookahId)
    serverId = tonumber(serverId)
    if not hookahIdStr or not serverId then
        print('[RTX SMOKING] HosePlayerAdded missing data', hookahIdStr, serverId)
        return
    end
    local hookahData = hookahs[hookahIdStr]
    if not hookahData then
        print('[RTX SMOKING] HosePlayerAdded missing hookah', hookahIdStr)
        return
    end
    hookahData.hoses = hookahData.hoses or { players = {} }
    hookahData.hoses.players = hookahData.hoses.players or {}
    if not hookahData.hoses.players[serverId] then
        hookahData.hoses.players[serverId] = { ropehandler = nil, mouthpiecehandler = nil, laststate = 'idle' }
    end
    if serverId == GetLocalServerIdValue() then
        if hookahMenuOpen and tostring(hookahMenuHookahId) == hookahIdStr then
            CloseHookahMenuLocal()
        end
        SetLocalHookahHolding(true, hookahId)
    end
end)

RegisterNetEvent('rtx_smoking:Global:HosePlayerRemoved')
AddEventHandler('rtx_smoking:Global:HosePlayerRemoved', function(hookahId, serverId)
    local hookahIdStr = tostring(hookahId)
    local hookahData  = hookahs[hookahIdStr]
    if not hookahData or not hookahData.hoses or not hookahData.hoses.players then return end
    local hoseData = hookahData.hoses.players[serverId]
    if not hoseData then return end
    if hoseData.ropehandler then
        DeleteRope(hoseData.ropehandler)
        hoseData.ropehandler = nil
    end
    if hoseData.mouthpiecehandler and DoesEntityExist(hoseData.mouthpiecehandler) then
        DeleteEntity(hoseData.mouthpiecehandler)
        hoseData.mouthpiecehandler = nil
    end
    hookahData.hoses.players[serverId] = nil
    if tonumber(serverId) == GetLocalServerIdValue() then
        SetLocalHookahHolding(false)
    end
end)

RegisterNetEvent('rtx_smoking:Global:Connected')
AddEventHandler('rtx_smoking:Global:Connected', function(hookahId, count)
    if hookahs[hookahId] then
        hookahs[hookahId].connected = count
    end
end)

RegisterNetEvent('rtx_smoking:Global:HookahExhaleSmoke')
AddEventHandler('rtx_smoking:Global:HookahExhaleSmoke', function(hookahId, sourceServerId, holdDuration)
    local pid = GetPlayerFromServerId(sourceServerId)
    if pid == -1 then return end
    local ped = GetPlayerPed(pid)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end

    local fx      = Config.HookahSmokeEffect
    local minHold = fx.minHoldMs
    local maxHold = fx.maxHoldMs
    local minTime = fx.minSmokeTimeMs
    local maxTime = fx.maxSmokeTimeMs
    local hold    = math.max(minHold, math.min(tonumber(holdDuration) or 0, maxHold))
    local ratio   = 0.0
    if minHold < maxHold then
        ratio = (hold - minHold) / (maxHold - minHold)
    end
    local duration = minTime + (maxTime - minTime) * ratio

    RequestNamedPtfxAsset(fx.dict)
    while not HasNamedPtfxAssetLoaded(fx.dict) do Wait(0) end
    UseParticleFxAssetNextCall(fx.dict)

    local fxHandle = _ENV['StartNetworkedParticleFxLoopedOnEntityBone'](
        fx.name, ped,
        fx.offset.x, fx.offset.y, fx.offset.z,
        fx.rotation.x, fx.rotation.y, fx.rotation.z,
        GetPedBoneIndex(ped, fx.bone),
        fx.scale,
        false, false, false
    )

    CreateThread(function()
        Wait(math.floor(duration))
        if fxHandle then StopParticleFxLooped(fxHandle, false) end
    end)
end)

RegisterNetEvent('rtx_smoking:Global:Place')
AddEventHandler('rtx_smoking:Global:Place', function(hookahType, colorIndex)
    if isPlacingHookah ~= true then
        PlaceHookah(hookahType, colorIndex)
    end
end)

RegisterNetEvent('rtx_smoking:client:ForceReleaseHose')
AddEventHandler('rtx_smoking:client:ForceReleaseHose', function(hookahId)
    if hookahHoseActive ~= true then
        StopHookahInhaleAudio()
        return
    end
    if hookahHoseHookahId and tostring(hookahHoseHookahId) ~= tostring(hookahId) then return end
    ExitHookahHose(false)
end)

-- ── système de fumée (cigarette / joint / vape / bong) ───
function IsPlayerSmoking()
    return hookahHoseActive == true or isSmokingActive == true
end

function DebugLog(message)
    if Config.Debug then
        print(string.format('[SmokingSystem] %s', message))
    end
end

function PlayGiveAnimationA()
    local ped = PlayerPedId()
    RequestAnimDict('mp_common')
    while not HasAnimDictLoaded('mp_common') do Wait(5) end
    TaskPlayAnim(ped, 'mp_common', 'givetake1_a', 8.0, -8.0, 1200, 48, 0, false, false, false)
end

function PlayGiveAnimationB()
    local ped = PlayerPedId()
    RequestAnimDict('mp_common')
    while not HasAnimDictLoaded('mp_common') do Wait(5) end
    TaskPlayAnim(ped, 'mp_common', 'givetake2_a', 8.0, -8.0, 1200, 48, 0, false, false, false)
end

local activeScreenEffect = nil
local screenEffectCounter = 0

function ClearSmokingScreenEffects()
    local ped = PlayerPedId()
    SetPedIsDrunk(ped, false)
    SetPedMotionBlur(ped, false)
    ResetPedMovementClipset(ped, 0.0)
    AnimpostfxStopAll()
    ClearTimecycleModifier()
    ShakeGameplayCam('DRUNK_SHAKE', 0.0)
    SetTimecycleModifierStrength(0.0)
    SetPedMoveRateOverride(PlayerId(), 1.0)
end

function ApplyVariantTint(entity, variantDef)
    if not entity or not DoesEntityExist(entity) or not variantDef then return end
    if variantDef.tintValue ~= nil then
        SetObjectTextureVariation(entity, tonumber(variantDef.tintValue) or 0)
    end
end

function ApplySmokeEffect(effectKey)
    local cfg = Config.SmokeEffects
    if not cfg or not cfg.enabled or not cfg.effects or not cfg.effects[effectKey] then
        return false
    end
    local fx  = cfg.effects[effectKey]
    local ped = PlayerPedId()
    screenEffectCounter = screenEffectCounter + 1
    local myCount   = screenEffectCounter
    activeScreenEffect = effectKey

    ClearSmokingScreenEffects()

    if fx.screenEffect and fx.screenEffect ~= '' then
        AnimpostfxPlay(fx.screenEffect, 10000001, true)
    end
    if fx.timecycle and fx.timecycle ~= '' then
        SetTimecycleModifier(fx.timecycle)
    end
    if fx.movementClipset and fx.movementClipset ~= '' then
        RequestAnimSet(fx.movementClipset)
        while not HasAnimSetLoaded(fx.movementClipset) do Wait(0) end
        SetPedMovementClipset(ped, fx.movementClipset, true)
    end
    SetPedIsDrunk(ped, fx.isDrunk == true)
    SetPedMotionBlur(ped, fx.motionBlur == true)
    ShakeGameplayCam('DRUNK_SHAKE', fx.shake or 0.0)

    CreateThread(function()
        Wait(fx.durationMs or 30000)
        if screenEffectCounter ~= myCount then return end
        activeScreenEffect = nil
        ClearSmokingScreenEffects()
    end)

    return true
end

function GetRandomSmokeEffectForCategory(category)
    local cfg = Config.SmokeEffects
    if not cfg or not cfg.enabled then return nil end
    local cat = cfg.categories and cfg.categories[category]
    if not cat or not cat.enabled then return nil end
    local chance = tonumber(cat.chance) or 0
    if chance <= 0 then return nil end
    if math.random(1, 100) > chance then return nil end
    local effects = cat.effects or {}
    if #effects == 0 then return nil end
    return effects[math.random(1, #effects)]
end

function TryRandomSmokeEffect(category)
    local effectKey = GetRandomSmokeEffectForCategory(category)
    if not effectKey then return false end
    return ApplySmokeEffect(effectKey)
end

function SyncPedParticle(ptfxDict, ptfxName, bone, scale, offset, rotation, durationMs)
    TriggerServerEvent('rtx_smoking:server:SyncPedParticle', {
        ptfxDict  = ptfxDict,
        ptfxName  = ptfxName,
        bone      = bone,
        scale     = scale,
        offset    = offset,
        rotation  = rotation,
        durationMs = durationMs,
    })
end

function StartParticleOnEntity(fxConfig)
    if not fxConfig or not fxConfig.enabled then return nil end
    RequestNamedPtfxAsset(fxConfig.ptfxDict)
    while not HasNamedPtfxAssetLoaded(fxConfig.ptfxDict) do Wait(0) end
    UseParticleFxAssetNextCall(fxConfig.ptfxDict)

    local attachTo = fxConfig.attachTo
    if attachTo == 'mouth' then
        local ped = PlayerPedId()
        return _ENV['StartNetworkedParticleFxLoopedOnEntityBone'](
            fxConfig.ptfxName, ped,
            fxConfig.offset.x, fxConfig.offset.y, fxConfig.offset.z,
            fxConfig.rotation.x, fxConfig.rotation.y, fxConfig.rotation.z,
            GetPedBoneIndex(ped, fxConfig.mouthBone or 47495),
            fxConfig.scale or 0.3,
            false, false, false
        )
    elseif attachTo == 'mainItem' and mainItemObject and DoesEntityExist(mainItemObject) then
        return StartParticleFxLoopedOnEntity(
            fxConfig.ptfxName, mainItemObject,
            fxConfig.offset.x, fxConfig.offset.y, fxConfig.offset.z,
            fxConfig.rotation.x, fxConfig.rotation.y, fxConfig.rotation.z,
            fxConfig.scale or 0.3,
            false, false, false
        )
    elseif attachTo == 'secondaryItem' and secondaryItemObject and DoesEntityExist(secondaryItemObject) then
        return StartParticleFxLoopedOnEntity(
            fxConfig.ptfxName, secondaryItemObject,
            fxConfig.offset.x, fxConfig.offset.y, fxConfig.offset.z,
            fxConfig.rotation.x, fxConfig.rotation.y, fxConfig.rotation.z,
            fxConfig.scale or 0.3,
            false, false, false
        )
    end
    return nil
end

function StopParticle(handle)
    if handle then StopParticleFxLooped(handle, false) end
end

function StopAllSmokingParticles()
    StopParticle(idleParticleFx)
    StopParticle(puffParticleFx)
    StopParticle(lightParticleFx)
    StopParticle(exhaleParticleFx)
    idleParticleFx   = nil
    puffParticleFx   = nil
    lightParticleFx  = nil
    exhaleParticleFx = nil
end

function RefreshIdleParticle()
    StopParticle(idleParticleFx)
    idleParticleFx = nil
    if not currentSmokingConfig or not currentSmokingConfig.particles then return end
    if isSmokingPuffing or isSmokingLighting then return end
    if currentSmokingConfig.supportsLighting and not (currentSmokingState and currentSmokingState.lighted) then return end
    local fx = currentSmokingConfig.particles.idleMain
    if fx and fx.enabled then
        idleParticleFx = StartParticleOnEntity(fx)
    end
end

function RefreshLightParticle()
    StopParticle(lightParticleFx)
    lightParticleFx = nil
    if not currentSmokingConfig or not currentSmokingConfig.particles then return end
    local fxMain = currentSmokingConfig.particles.lightMain
    local fxSec  = currentSmokingConfig.particles.lightSecondary
    if fxMain and fxMain.enabled then
        lightParticleFx = StartParticleOnEntity(fxMain)
    elseif fxSec and fxSec.enabled then
        lightParticleFx = StartParticleOnEntity(fxSec)
    end
end

function ClearLightParticle()
    StopParticle(lightParticleFx)
    lightParticleFx = nil
end

function RefreshPuffParticle()
    StopParticle(puffParticleFx)
    puffParticleFx = nil
    if not currentSmokingConfig or not currentSmokingConfig.particles then return end
    local fxMain = currentSmokingConfig.particles.puffMain
    local fxSec  = currentSmokingConfig.particles.puffSecondary or currentSmokingConfig.particles.inhaleSecondary
    if fxMain and fxMain.enabled then
        puffParticleFx = StartParticleOnEntity(fxMain)
    elseif fxSec and fxSec.enabled then
        puffParticleFx = StartParticleOnEntity(fxSec)
    end
end

function ClearPuffParticle()
    StopParticle(puffParticleFx)
    puffParticleFx = nil
end

function PlayExhaleParticle(holdDurationMs)
    if not currentSmokingConfig or not currentSmokingConfig.particles then return end
    local fx = currentSmokingConfig.particles.exhale
    if not fx or not fx.enabled then return end

    local minHold = fx.minHoldMs or 300
    local maxHold = fx.maxHoldMs or 5000
    local minDur  = fx.minDurationMs or 800
    local maxDur  = fx.maxDurationMs or 5000
    local hold    = math.max(minHold, math.min(holdDurationMs, maxHold))
    local ratio   = 0.0
    if minHold < maxHold then ratio = (hold - minHold) / (maxHold - minHold) end
    local duration = minDur + (maxDur - minDur) * ratio

    SyncPedParticle(
        fx.ptfxDict, fx.ptfxName,
        fx.mouthBone or 47495,
        fx.scale or 0.3,
        fx.offset   or vec3(0,0,0),
        fx.rotation or vec3(0,0,0),
        math.floor(duration)
    )
end

-- ── items de fumée ────────────────────────────────────────
function GetSmokingVariantDef(variantKey)
    if Config.SmokingVariants and Config.SmokingVariants[variantKey] then
        return Config.SmokingVariants[variantKey]
    end
    return nil
end

function GetSelectionSetEntry(setName, key)
    if not key or key == '' then return nil end
    local set = Config.SelectionSets and Config.SelectionSets[setName]
    if not set then return nil end
    return set[key]
end

function ResolveSmokingVariantAndConfig(variantKey)
    local variantDef = GetSmokingVariantDef(variantKey)
    if not variantDef then return nil, nil end
    local itemType   = variantDef.type
    local itemConfig = Config.Items and Config.Items[itemType]
    if not itemConfig then return nil, nil end

    local merged = DeepCopy(itemConfig)
    if variantDef.attachPreset then
        local preset = Config.AttachPresets and Config.AttachPresets[variantDef.attachPreset]
        if preset then
            merged = MergeOverrides(merged, preset)
        end
    end
    if variantDef.prop then
        merged.mainItem = merged.mainItem or {}
        merged.mainItem.model = variantDef.prop
    end
    if variantDef.overrides then
        merged = MergeOverrides(merged, variantDef.overrides)
    end

    return variantDef, merged
end

function BuildDefaultSmokingState(itemType)
    local itemCfg = Config.Items and Config.Items[itemType]
    local state   = {
        type         = itemType,
        lighted      = false,
        selectionKey = nil,
        selectionLabel = nil,
        selectionImage = nil,
        subtitle     = nil,
        brand        = nil,
        itemId       = nil,
        idleVariant  = 'hand',
        actions      = nil,
        stats        = {},
    }
    if itemCfg and itemCfg.stats then
        for statKey, _ in pairs(itemCfg.stats) do
            state.stats[statKey] = 100.0
        end
    end
    state.stats.durability = state.stats.durability or 100.0
    state.stats.fill       = state.stats.fill       or 100.0
    state.stats.battery    = state.stats.battery    or 100.0
    state.stats.water      = state.stats.water      or 100.0
    state.stats.smokeLevel = state.stats.smokeLevel or 0.0
    state.stats.burnLevel  = state.stats.burnLevel  or 0.0
    state.stats.heat       = state.stats.heat       or 0.0
    return state
end

function BuildSmokingStateFromInput(itemType, inputState)
    local state = BuildDefaultSmokingState(itemType)
    if not inputState then return state end
    state.lighted = inputState.lighted == true or inputState.ignited == true
    local selKey  = inputState.selectionKey or inputState.flavourKey or inputState.fillKey
    state.selectionKey = selKey
    state.selectionLabel = inputState.selectionLabel
    state.selectionImage = inputState.selectionImage
    state.subtitle       = inputState.subtitle
    state.brand          = inputState.brand
    state.itemId         = inputState.itemId
    state.idleVariant    = inputState.idleVariant or state.idleVariant
    state.actions        = inputState.actions
    if type(inputState.stats) == 'table' then
        for k, v in pairs(inputState.stats) do
            state.stats[k] = Clamp(tonumber(v) or 0.0, 0.0, 100.0)
        end
    end
    return state
end

function EnrichStateWithSelectionData(itemType, state)
    if not state then return end
    local selKey = state.selectionKey
    if not selKey or selKey == '' then return end
    local entry = GetSelectionSetEntry(itemType, selKey)
    if not entry then return end
    if not state.selectionLabel then state.selectionLabel = entry.label end
    if not state.selectionImage then state.selectionImage = entry.image end
    if not state.subtitle then state.subtitle = entry.label end
end

function GetCurrentSmokingStateSnapshot()
    if not currentSmokingState then return nil end
    return DeepCopy(currentSmokingState)
end

function GetCurrentSmokingGiftData()
    if not currentSmokingState or not currentSmokingVariantDef then return nil end
    return {
        variant       = currentSmokingItemKey,
        type          = currentSmokingType,
        lighted       = currentSmokingState.lighted,
        selectionKey  = currentSmokingState.selectionKey,
        selectionLabel = currentSmokingState.selectionLabel,
        subtitle      = currentSmokingState.subtitle,
        brand         = currentSmokingState.brand,
        idleVariant   = currentSmokingState.idleVariant,
        itemId        = currentSmokingState.itemId,
        image         = currentSmokingVariantDef.image,
        stats         = DeepCopy(currentSmokingState.stats),
    }
end

function ValidateSmokingStateIntegrity(itemType, state)
    local itemCfg = Config.Items and Config.Items[itemType]
    if not itemCfg then return false, 'Invalid type' end
    if itemCfg.stats then
        for k, _ in pairs(itemCfg.stats) do
            local v = (state.stats and state.stats[k]) or 0.0
            if v < 0.0 then return false, string.format('%s invalid', k) end
        end
    end
    return true, nil
end

function ValidateSmokingStateForUse(itemType, state)
    local itemCfg = Config.Items and Config.Items[itemType]
    if not itemCfg then return false, 'Invalid type' end
    if itemCfg.requirements and itemCfg.requirements.requireSelection then
        if not state.selectionKey or state.selectionKey == '' then
            return false, 'Missing selection'
        end
    end
    if itemCfg.stats then
        for k, statCfg in pairs(itemCfg.stats) do
            local v       = (state.stats and state.stats[k]) or 0.0
            local minReq  = statCfg.minRequiredToUse or 0.0
            if v < minReq then return false, string.format('%s too low', k) end
        end
    end
    return true, nil
end

function GetConsumptionDeltas(itemType, actionKey, elapsedMs)
    local itemCfg = Config.Items and Config.Items[itemType]
    local deltas  = {}
    if not itemCfg or not itemCfg.consumption or not itemCfg.consumption[actionKey] then
        return deltas
    end
    local consumption = itemCfg.consumption[actionKey]
    local statCfgs    = consumption.stats or {}
    local seconds     = elapsedMs / 1000.0
    for statKey, statCfg in pairs(statCfgs) do
        local raw  = seconds * (statCfg.perSecond or 0.0)
        local clampedDelta = Clamp(raw, statCfg.min or 0.0, statCfg.max or 9999.0)
        deltas[statKey]    = Round(clampedDelta, 2)
    end
    return deltas
end

function DeductConsumption(state, deltas)
    if not state or not state.stats then return end
    for statKey, delta in pairs(deltas or {}) do
        local current = state.stats[statKey] or 0.0
        state.stats[statKey] = Round(math.max(current - delta, 0.0), 2)
    end
end

function GetShallowStats(state)
    if not state or not state.stats then return {} end
    local result = {}
    for k, v in pairs(state.stats) do
        if type(v) ~= 'table' then result[k] = v end
    end
    return result
end

-- ── objet principal et secondaire ────────────────────────
function LoadModelAsync(modelHash)
    if type(modelHash) ~= 'number' then
        modelHash = joaat(modelHash)
    end
    if not IsModelInCdimage(modelHash) or not IsModelValid(modelHash) then
        print(string.format('Model not found: %s', tostring(modelHash)))
        return nil
    end
    RequestModel(modelHash)
    local timeoutAt = GetGameTimer() + 10000
    while not HasModelLoaded(modelHash) and GetGameTimer() < timeoutAt do
        Wait(0)
    end
    if not HasModelLoaded(modelHash) then
        print(string.format('[RTX SMOKING] Timed out loading model: %s', tostring(modelHash)))
        return nil
    end
    return modelHash
end

function LoadModelAsyncNoCheck(modelHash)
    if type(modelHash) ~= 'number' then
        modelHash = joaat(modelHash)
    end
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(0) end
    return modelHash
end

function LoadAnimDictSync(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
end

function LoadAnimSetSync(animSet)
    RequestAnimSet(animSet)
    while not HasAnimSetLoaded(animSet) do Wait(0) end
end

function LoadNamedPtfxSync(ptfxDict)
    RequestNamedPtfxAsset(ptfxDict)
    while not HasNamedPtfxAssetLoaded(ptfxDict) do Wait(0) end
end

function GetIconPath(imageFilename)
    if not imageFilename or imageFilename == '' then return nil end
    return string.format('img/%s', imageFilename)
end

function GetSelectionSetItems(setName, eventName)
    local items  = {}
    local setDef = Config.SelectionSets and Config.SelectionSets[setName]
    if not setDef then return items end
    for id, entry in pairs(setDef) do
        items[#items + 1] = {
            id    = id,
            label = entry.label or id,
            image = GetIconPath(entry.image),
            meta  = entry.category or '',
            event = eventName,
        }
    end
    table.sort(items, function(a, b) return tostring(a.label) < tostring(b.label) end)
    return items
end

function SpawnAttachedObject(ped, modelName, attachConfig)
    local hash = LoadModelAsync(modelName)
    if not hash then return nil end
    local coords = GetEntityCoords(ped)
    local obj    = CreateObject(hash, coords.x, coords.y, coords.z + 0.2, true, true, false)
    if not DoesEntityExist(obj) then return nil end
    SetEntityCollision(obj, false, false)
    SetEntityAsMissionEntity(obj, true, true)
    AttachEntityToEntity(
        obj, ped,
        GetPedBoneIndex(ped, attachConfig.bone),
        attachConfig.offset.x, attachConfig.offset.y, attachConfig.offset.z,
        attachConfig.rotation.x, attachConfig.rotation.y, attachConfig.rotation.z,
        false, false, false, false, 2, true
    )
    SetModelAsNoLongerNeeded(hash)
    return obj
end

function DeleteEntitySafe(entity)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

function DeleteMainAndSecondaryItems()
    DeleteEntitySafe(mainItemObject)
    DeleteEntitySafe(secondaryItemObject)
    mainItemObject      = nil
    secondaryItemObject = nil
end

function GetMainItemAttachConfig(animState)
    if not currentSmokingConfig or not currentSmokingConfig.mainItem then return nil end
    local mainItem = currentSmokingConfig.mainItem
    animState = NormalizePuffToAnimState(animState)
    if animState == 'idle' then
        if mainItem.idleVariants then
            local variantName = (currentSmokingState and currentSmokingState.idleVariant) or 'hand'
            return mainItem.idleVariants[variantName] or mainItem.idleVariants.hand
        end
    end
    if animState == 'puff' and mainItem.puffStyles then
        return mainItem.puffStyles[smokingPuffStyleIndex] or mainItem.puffStyles[1]
    end
    return mainItem[animState] or mainItem.idle
end

function ReattachMainItem(ped, animState)
    if not mainItemObject or not DoesEntityExist(mainItemObject) then return end
    local cfg = GetMainItemAttachConfig(animState)
    if not cfg then return end
    AttachEntityToEntity(
        mainItemObject, ped,
        GetPedBoneIndex(ped, cfg.bone),
        cfg.offset.x, cfg.offset.y, cfg.offset.z,
        cfg.rotation.x, cfg.rotation.y, cfg.rotation.z,
        false, false, false, false, 2, true
    )
end

function GetSecondaryItemAttachConfig(animState)
    if not currentSmokingConfig or not currentSmokingConfig.secondaryItem then return nil end
    local sec = currentSmokingConfig.secondaryItem
    animState = NormalizePuffToAnimState(animState)
    if animState == 'puff' and sec.puffStyles then
        return sec.puffStyles[smokingPuffStyleIndex] or sec.puffStyles[1]
    end
    local cfg = sec[animState]
    if cfg then return cfg end
    if animState == 'puff' then return sec.inhale end
    return sec.idle
end

function IsSecondaryItemEnabled(animState)
    if not currentSmokingConfig or not currentSmokingConfig.secondaryItem then return false end
    local sec   = currentSmokingConfig.secondaryItem
    if not sec.enabled then return false end
    animState   = NormalizePuffToAnimState(animState)
    local phase = NormalizePuffToAnimState(sec.phase or 'always')
    if phase == 'always' then return true end
    return phase == animState
end

function RefreshSecondaryItem(ped, animState)
    if not IsSecondaryItemEnabled(animState) then
        DeleteEntitySafe(secondaryItemObject)
        secondaryItemObject = nil
        return
    end
    local cfg = GetSecondaryItemAttachConfig(animState)
    if not cfg then
        DeleteEntitySafe(secondaryItemObject)
        secondaryItemObject = nil
        return
    end
    if secondaryItemObject and DoesEntityExist(secondaryItemObject) then
        AttachEntityToEntity(
            secondaryItemObject, ped,
            GetPedBoneIndex(ped, cfg.bone),
            cfg.offset.x, cfg.offset.y, cfg.offset.z,
            cfg.rotation.x, cfg.rotation.y, cfg.rotation.z,
            false, false, false, false, 2, true
        )
    else
        local model = currentSmokingConfig.secondaryItem.model
        secondaryItemObject = SpawnAttachedObject(ped, model, cfg)
    end
end

function SpawnMainItem(ped)
    local cfg = GetMainItemAttachConfig('idle')
    if not cfg then return false end
    if not currentSmokingConfig.mainItem or not currentSmokingConfig.mainItem.model then return false end
    mainItemObject = SpawnAttachedObject(ped, currentSmokingConfig.mainItem.model, cfg)
    if mainItemObject and DoesEntityExist(mainItemObject) then
        ApplyVariantTint(mainItemObject, currentSmokingVariantDef)
    end
    return mainItemObject ~= nil
end

-- ── animations ───────────────────────────────────────────
function NormalizePuffToAnimState(state)
    if state == 'inhale' then return 'puff' end
    return state
end

function StopAllSmokingAnimations(ped)
    if not currentSmokingConfig or not currentSmokingConfig.animations then
        ClearPedSecondaryTask(ped)
        return
    end
    local anims = currentSmokingConfig.animations
    for _, animKey in ipairs({'idle', 'light', 'puff', 'forceRelease'}) do
        local animCfg = anims[animKey]
        if animCfg and animCfg.dict and animCfg.dict ~= '' and animCfg.anim and animCfg.anim ~= '' then
            StopAnimTask(ped, animCfg.dict, animCfg.anim, 1.0)
        end
    end
    ClearPedSecondaryTask(ped)
end

function PlaySmokingAnimation(ped, animCfg)
    if not animCfg or not animCfg.enabled then return end
    if not animCfg.dict or animCfg.dict == '' then return end
    if not animCfg.anim or animCfg.anim == '' then return end
    LoadAnimDictSync(animCfg.dict)
    StopAllSmokingAnimations(ped)
    Wait(0)
    TaskPlayAnim(ped, animCfg.dict, animCfg.anim, 8.0, 8.0, -1, animCfg.flag or 49, 0.0, false, false, false)
end

function StopSmokingAnimation(ped, animCfg)
    if not animCfg or not animCfg.enabled then
        ClearPedSecondaryTask(ped)
        return
    end
    if animCfg.dict and animCfg.dict ~= '' and animCfg.anim and animCfg.anim ~= '' then
        StopAnimTask(ped, animCfg.dict, animCfg.anim, 1.0)
    end
    ClearPedSecondaryTask(ped)
end

function PlayIdleAnimation(ped)
    local anims = currentSmokingConfig and currentSmokingConfig.animations
    PlaySmokingAnimation(ped, anims and anims.idle)
end

function PlayLightAnimation(ped)
    local anims = currentSmokingConfig and currentSmokingConfig.animations
    PlaySmokingAnimation(ped, anims and anims.light)
end

function GetCurrentPuffAnimation()
    if not currentSmokingConfig then return nil end
    local anims = currentSmokingConfig.animations
    if anims and anims.puffStyles then
        return anims.puffStyles[smokingPuffStyleIndex] or anims.puffStyles[1]
    end
    return anims and anims.puff
end

function GetCurrentMainItemPuffAnimation()
    if not currentSmokingConfig or not currentSmokingConfig.mainItem then return nil end
    local main = currentSmokingConfig.mainItem
    if main.puffStyles then
        return main.puffStyles[smokingPuffStyleIndex] or main.puffStyles[1]
    end
    return main.puff
end

function PlayPuffAnimation(ped)
    PlaySmokingAnimation(ped, GetCurrentPuffAnimation())
end

function IsAnimationPlaying(ped, animState)
    animState = NormalizePuffToAnimState(animState)
    local anims = currentSmokingConfig and currentSmokingConfig.animations
    local animCfg
    if animState == 'puff' then
        animCfg = GetCurrentPuffAnimation()
    elseif anims then
        animCfg = anims[animState]
    end
    if not animCfg or not animCfg.enabled then return true end
    if not animCfg.dict or animCfg.dict == '' then return true end
    if not animCfg.anim or animCfg.anim == '' then return true end
    return IsEntityPlayingAnim(ped, animCfg.dict, animCfg.anim, 3)
end

function PlayForceReleaseAnimation(ped)
    local anims = currentSmokingConfig and currentSmokingConfig.animations
    local animCfg = anims and anims.forceRelease
    if not animCfg or not animCfg.enabled then return false, 0 end
    RequestSmokingSound(GetCoughSoundKey(), nil, false, false)
    PlaySmokingAnimation(ped, animCfg)
    return true, animCfg.durationMs or 1000
end

function RevertToIdleAfterLight(ped)
    isSmokingLighting = false
    currentSmokingState.lighted = true
    ClearLightParticle()
    StopAllSmokingAnimations(ped)
    ReattachMainItem(ped, 'idle')
    RefreshSecondaryItem(ped, 'idle')
    PlayIdleAnimation(ped)
    RefreshIdleParticle()
    UpdateSmokingUIFromState()
end

-- ── NUI: état de fumée ────────────────────────────────────
function BuildSmokingNUIData()
    if not currentSmokingVariantDef or not currentSmokingConfig or not currentSmokingState then return {} end
    local t    = currentSmokingType
    local cfg  = currentSmokingConfig
    local state = currentSmokingState
    local label = currentSmokingVariantDef.label or cfg.label or 'Smoke'
    local data  = {
        type      = t,
        itemLabel = label,
        lit       = state.lighted == true,
        icon      = GetIconPath(currentSmokingVariantDef.image),
    }
    if t == 'cigarette' or t == 'cigar' then
        data.brand        = state.brand or currentSmokingVariantDef.brand or state.subtitle or label
        data.statusPercent = Clamp(state.stats.durability or 0.0, 0.0, 100.0)
    elseif t == 'joint' then
        local fill = state.selectionLabel or state.subtitle or 'Weed'
        if not (state.selectionKey and state.selectionKey ~= '') then fill = 'Not selected' end
        data.fill         = fill
        data.statusPercent = Clamp(state.stats.durability or 0.0, 0.0, 100.0)
    elseif t == 'vape' then
        local flavour
        if state.selectionKey and state.selectionKey ~= '' then
            flavour = state.flavour or state.selectionLabel or state.subtitle or (cfg.nui and cfg.nui.emptyText)
        else
            flavour = cfg.nui and cfg.nui.emptyText
        end
        data.flavour = flavour
        local fillPct = 0
        if state.selectionKey and state.selectionKey ~= '' then
            fillPct = Clamp(state.stats.fill or 0.0, 0.0, 100.0) or 0
        end
        data.flavourPercent = fillPct
        data.batteryPercent = Clamp(state.stats.battery or 0.0, 0.0, 100.0)
    elseif t == 'bong' then
        local fill
        if state.selectionKey and state.selectionKey ~= '' then
            fill = state.fill or state.flavour or state.subtitle or (cfg.nui and cfg.nui.emptyText)
        else
            fill = cfg.nui and cfg.nui.emptyText
        end
        data.fill = fill
        local fillPct = 0
        if state.selectionKey and state.selectionKey ~= '' then
            fillPct = Clamp(state.stats.fill or 0.0, 0.0, 100.0) or 0
        end
        data.fillPercent  = fillPct
        data.waterPercent = Clamp(state.stats.water or 0.0, 0.0, 100.0)
    end
    return data
end

function OpenSmokingUIFromState()
    if not isSmokingActive or not currentSmokingState or not currentSmokingConfig or not currentSmokingVariantDef then return end
    SendNUIMessage({ action = 'smoking:open', data = BuildSmokingNUIData() })
end

function UpdateSmokingUIFromState()
    if not isSmokingActive or not currentSmokingState or not currentSmokingConfig or not currentSmokingVariantDef then return end
    SendNUIMessage({ action = 'smoking:update', data = BuildSmokingNUIData() })
end

function CloseSmokingUIFromState()
    SendNUIMessage({ action = 'smoking:hide' })
end

function SetSmokingBusy(busy)
    isSmokingBusy = busy == true
    if isSmokingBusy then
        CloseSmokingUIFromState()
    else
        OpenSmokingUIFromState()
    end
end

-- ── mise à jour des stats ─────────────────────────────────
function SetCurrentSmokingStat(statKey, value)
    if not currentSmokingState then return false end
    currentSmokingState.stats = currentSmokingState.stats or {}
    currentSmokingState.stats[statKey] = Clamp(tonumber(value) or 0.0, 0.0, 100.0)
    UpdateSmokingUIFromState()
    return true
end

function AddCurrentSmokingStat(statKey, delta)
    if not currentSmokingState then return false end
    local current = (currentSmokingState.stats and currentSmokingState.stats[statKey]) or 0.0
    return SetCurrentSmokingStat(statKey, current + (tonumber(delta) or 0.0))
end

function SetCurrentSmokingLighted(value)
    if not currentSmokingState then return false end
    currentSmokingState.lighted = value == true
    UpdateSmokingUIFromState()
    return true
end

function SetCurrentSmokingSelectionKey(key)
    if not currentSmokingState then return false end
    currentSmokingState.selectionKey   = key
    currentSmokingState.selectionLabel = nil
    currentSmokingState.selectionImage = nil
    EnrichStateWithSelectionData(currentSmokingType, currentSmokingState)
    UpdateSmokingUIFromState()
    return true
end

function SetCurrentSmokingSubtitle(text)
    if not currentSmokingState then return false end
    currentSmokingState.subtitle = text
    UpdateSmokingUIFromState()
    return true
end

function SetCurrentSmokingBrand(brand)
    if not currentSmokingState then return false end
    currentSmokingState.brand = brand
    UpdateSmokingUIFromState()
    return true
end

function SetCurrentSmokingIdleVariant(variant)
    if not currentSmokingState then return false end
    currentSmokingState.idleVariant = variant or 'hand'
    if isSmokingActive and not isSmokingPuffing and not isSmokingLighting then
        local ped = PlayerPedId()
        ReattachMainItem(ped, 'idle')
        RefreshSecondaryItem(ped, 'idle')
    end
    UpdateSmokingUIFromState()
    return true
end

function UpdateCurrentSmokingState(updates)
    if not currentSmokingState then return false end
    if not updates then return false end

    if updates.lighted ~= nil or updates.ignited ~= nil then
        currentSmokingState.lighted = (updates.lighted == true)
    end
    if updates.selectionKey ~= nil then
        currentSmokingState.selectionKey   = updates.selectionKey
        currentSmokingState.selectionLabel = nil
        currentSmokingState.selectionImage = nil
        EnrichStateWithSelectionData(currentSmokingType, currentSmokingState)
    end
    if updates.subtitle  ~= nil then currentSmokingState.subtitle    = updates.subtitle  end
    if updates.brand     ~= nil then currentSmokingState.brand       = updates.brand     end
    if updates.itemId    ~= nil then currentSmokingState.itemId      = updates.itemId    end
    if updates.idleVariant ~= nil then currentSmokingState.idleVariant = updates.idleVariant end
    if updates.actions   ~= nil then currentSmokingState.actions     = updates.actions   end
    if type(updates.stats) == 'table' then
        currentSmokingState.stats = currentSmokingState.stats or {}
        for k, v in pairs(updates.stats) do
            currentSmokingState.stats[k] = Clamp(tonumber(v) or 0.0, 0.0, 100.0)
        end
    end

    if isSmokingActive and not isSmokingPuffing and not isSmokingLighting then
        local ped = PlayerPedId()
        ReattachMainItem(ped, 'idle')
        RefreshSecondaryItem(ped, 'idle')
    end
    UpdateSmokingUIFromState()
    return true
end

function GetAvailableIdleVariants()
    if not currentSmokingConfig or not currentSmokingConfig.mainItem then return {} end
    local variants = currentSmokingConfig.mainItem.idleVariants
    if not variants then return {} end
    local list = {}
    for k, _ in pairs(variants) do list[#list + 1] = k end
    table.sort(list)
    return list
end

function CycleIdleVariant()
    if not currentSmokingState then return false end
    local variants = GetAvailableIdleVariants()
    if #variants == 0 then return false end
    local current = currentSmokingState.idleVariant or variants[1]
    local nextIdx = 1
    for i, v in ipairs(variants) do
        if v == current then nextIdx = i + 1 break end
    end
    if nextIdx > #variants then nextIdx = 1 end
    currentSmokingState.idleVariant = variants[nextIdx]
    if isSmokingActive and not isSmokingPuffing and not isSmokingLighting then
        local ped = PlayerPedId()
        ReattachMainItem(ped, 'idle')
        RefreshSecondaryItem(ped, 'idle')
    end
    UpdateSmokingUIFromState()
    DebugLog('Idle variant changed to: ' .. currentSmokingState.idleVariant)
    return true
end

function IsCigaretteType()
    return currentSmokingType == 'cigarette'
end

function SupportsPuffStyles()
    if not currentSmokingConfig or not currentSmokingConfig.animations then return false end
    if not IsCigaretteType() then return false end
    local styles = currentSmokingConfig.animations.puffStyles
    if not styles then return false end
    local maxIdx = 0
    for i, _ in pairs(styles) do
        if i > maxIdx then maxIdx = i end
    end
    if maxIdx <= 1 then return false end
    smokingPuffStyleIndex = smokingPuffStyleIndex + 1
    if smokingPuffStyleIndex > maxIdx then smokingPuffStyleIndex = 1 end
    DebugLog('Puff style switched to: ' .. smokingPuffStyleIndex)
    return true
end

-- ── don d'item ────────────────────────────────────────────
function CanGiveSmokingItem()
    if isSmokingBusy then return false end
    if not isSmokingActive or not currentSmokingState or not currentSmokingItemKey then return false end
    return true
end

function TryGiveSmokingItem()
    if not CanGiveSmokingItem() then return false end
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local target = FindNearestOtherPlayer(coords, Config.GiveDistance or 3.0)
    if not target then
        Notify('error', Language[Config.Language].smoking, Language[Config.Language].noplayernearby)
        return false
    end
    local giftData = {
        variantKey = currentSmokingItemKey,
        type       = currentSmokingType,
        state      = DeepCopy(currentSmokingState),
        variant    = DeepCopy(currentSmokingVariantDef),
    }
    PlayGiveAnimationA()
    TriggerServerEvent('rtx_smoking:server:GiveSmokingItem', target.serverId, giftData)
    return true
end

-- ── progress action ───────────────────────────────────────
function GetProgressActionPoses(actionKey, selectionSetName, selectionKey, secondaryModelOverride)
    if not currentSmokingConfig then return nil end
    local mainPose = currentSmokingConfig.mainItem and currentSmokingConfig.mainItem.progress and currentSmokingConfig.mainItem.progress[actionKey]
    local secPose  = currentSmokingConfig.secondaryItem and currentSmokingConfig.secondaryItem.progress and currentSmokingConfig.secondaryItem.progress[actionKey]

    local secondaryModel = secondaryModelOverride
    if not secondaryModel and selectionSetName and selectionKey then
        local setEntry = GetSelectionSetEntry(selectionSetName, selectionKey)
        if setEntry and setEntry.object then
            secondaryModel = setEntry.object
        end
    end

    return {
        mainPose  = mainPose,
        secondary = (secPose and secondaryModel) and { model = secondaryModel, pose = secPose } or nil,
    }
end

function SpawnProgressSecondaryObject(secondaryConfig)
    if not secondaryConfig or not secondaryConfig.model or not secondaryConfig.pose then return nil end
    return SpawnAttachedObject(PlayerPedId(), secondaryConfig.model, secondaryConfig.pose)
end

function RunProgressAction(actionKey, poses)
    local actionCfg = Config.ProgressActions and Config.ProgressActions[actionKey]
    if not actionCfg then
        print(string.format('Missing progress action config: %s', tostring(actionKey)))
        return false
    end

    local ped = PlayerPedId()
    if IsEntityDead(ped) or IsPedRagdoll(ped) then return false end

    isSmokingBusy = true
    CloseSmokingUIFromState()
    FreezeEntityPosition(ped, true)

    if poses and poses.mainPose and mainItemObject and DoesEntityExist(mainItemObject) then
        local mp = poses.mainPose
        AttachEntityToEntity(
            mainItemObject, ped,
            GetPedBoneIndex(ped, mp.bone),
            mp.offset.x, mp.offset.y, mp.offset.z,
            mp.rotation.x, mp.rotation.y, mp.rotation.z,
            false, false, false, false, 2, true
        )
    end

    if poses and poses.secondary then
        progressSecondaryObject = SpawnProgressSecondaryObject(poses.secondary)
    end

    local animCfg = actionCfg.animation
    if animCfg then
        if animCfg.dict and animCfg.dict ~= '' and animCfg.anim and animCfg.anim ~= '' then
            LoadAnimDictSync(animCfg.dict)
            TaskPlayAnim(ped, animCfg.dict, animCfg.anim, 8.0, 8.0, -1, animCfg.flag or 49, 0.0, false, false, false)
        end
    end

    local completed = StartProgress({
        title     = actionCfg.title,
        label     = actionCfg.label,
        icon      = actionCfg.icon,
        time      = actionCfg.time,
        canCancel = actionCfg.canCancel,
    })

    if animCfg then
        StopSmokingAnimation(ped, animCfg)
    end

    DeleteEntitySafe(progressSecondaryObject)
    progressSecondaryObject = nil

    RefreshMainItemPosition(ped)
    FreezeEntityPosition(ped, false)
    isSmokingBusy = false
    OpenSmokingUIFromState()
    return completed == true
end

function RefreshMainItemPosition(ped)
    if not mainItemObject or not DoesEntityExist(mainItemObject) then return end
    if isSmokingLighting then
        ReattachMainItem(ped, 'light')
    elseif isSmokingPuffing then
        ReattachMainItem(ped, 'puff')
    else
        ReattachMainItem(ped, 'idle')
    end
end

-- ── boucle d'inhale / puff cooldown ──────────────────────
local lastPuffTimestamp   = 0
local puffCooldownMs      = 2000

function CanStartNewPuff()
    local now    = GetGameTimer()
    local since  = lastPuffTimestamp
    if since > 0 and now - since < puffCooldownMs then return false end
    lastPuffTimestamp = now
    return true
end

function CanPuffNow()
    local ok, reason = ValidateSmokingStateForUse(currentSmokingType, currentSmokingState)
    if not ok then
        DebugLog('Cannot puff: ' .. (reason or 'unknown'))
        local language = Language[Config.Language]
        local message = language.itemnotready
        if reason == 'Missing selection' then
            message = currentSmokingType == 'vape' and language.needvapeflavour or language.needbongfill
        elseif reason and reason:find('fill too low', 1, true) then
            message = language.itemneedsrefill
        elseif reason and reason:find('battery too low', 1, true) then
            message = language.neednewvapebattery
        end
        Notify('error', language.smoking, message)
        return false
    end
    if currentSmokingConfig.supportsLighting and not currentSmokingState.lighted then
        DebugLog('Cannot puff: item is not lighted')
        local language = Language[Config.Language]
        Notify('error', language.smoking, language.needlightbeforepuff)
        return false
    end
    return true
end

function GetInhaleLoopSoundKeys(itemType)
    if itemType == 'bong'       then return 'bongLoop',       'smoking_bong_loop'    end
    if itemType == 'vape'       then return 'vape',           'vape_inhale_loop'     end
    if itemType == 'cigarette'
    or itemType == 'cigar'
    or itemType == 'joint'      then return 'inhalenormal',   'smoking_inhale_loop'  end
    return nil, nil
end

function StartInhaleLoopSound()
    local key, loopId = GetInhaleLoopSoundKeys(currentSmokingType)
    if key and loopId then
        RequestSmokingSound(key, loopId, true, false)
    end
end

function FinishPuff(ped, holdMs, autoReleased)
    isSmokingPuffing = false
    smokingInhaleStartTime = 0

    local soundKey, loopId = GetInhaleLoopSoundKeys(currentSmokingType)
    if soundKey and loopId then
        RequestSmokingSound(soundKey, loopId, true, true)
    end

    local exhaleSoundKey = GetExhaleSoundKey()
    RequestSmokingSound(exhaleSoundKey, nil, false, false)

    local deltas = GetConsumptionDeltas(currentSmokingType, 'puff', holdMs)
    DeductConsumption(currentSmokingState, deltas)

    local puffData = {
        item          = currentSmokingItemKey,
        type          = currentSmokingType,
        amount        = Clamp(math.min(10.0, math.max(0.1, holdMs / 1000.0)), 0.1, 10.0),
        holdDuration  = holdMs,
        autoReleased  = autoReleased == true,
        stats         = GetShallowStats(currentSmokingState),
    }
    TriggerEvent('rtx_smoking:client:OnPuff', puffData)
    TriggerServerEvent('rtx_smoking:server:OnPuff', puffData)

    ClearPuffParticle()
    StopAllSmokingAnimations(ped)
    ReattachMainItem(ped, 'idle')
    RefreshSecondaryItem(ped, 'idle')

    if autoReleased then
        local didAnim, animDurationMs = PlayForceReleaseAnimation(ped)
        if didAnim then
            Wait(animDurationMs)
            StopAllSmokingAnimations(ped)
        end
    end

    PlayIdleAnimation(ped)
    PlayExhaleParticle(holdMs)
    UpdateSmokingUIFromState()
    RefreshIdleParticle()

    if Config.SmokeEffects and Config.SmokeEffects.enabled then
        TryRandomSmokeEffect(currentSmokingType)
    end
end

function StartPuff(ped)
    isSmokingPuffing = true
    smokingInhaleStartTime = GetGameTimer()
    lastPuffTimestamp = smokingInhaleStartTime

    StartInhaleLoopSound()
    ReattachMainItem(ped, 'puff')
    RefreshSecondaryItem(ped, 'puff')
    SetPedCanHeadIk(ped, false)
    SetPedCanTorsoIk(ped, false)
    PlayPuffAnimation(ped)
    RefreshPuffParticle()
end

function StartSmokingHitFromUI()
    if not isSmokingActive or isSmokingBusy or isSmokingPuffing or isSmokingLighting then
        return false
    end

    if not CanPuffNow() then return false end

    if not CanStartNewPuff() then
        Notify('error', Language[Config.Language].smoking, Language[Config.Language].puffcooldown)
        return false
    end

    local ped = PlayerPedId()
    StartPuff(ped)
    local itemKey = currentSmokingItemKey
    local startedAt = smokingInhaleStartTime

    CreateThread(function()
        Wait(1200)
        if isSmokingActive
            and isSmokingPuffing
            and currentSmokingItemKey == itemKey
            and smokingInhaleStartTime == startedAt
        then
            FinishPuff(ped, GetGameTimer() - startedAt, false)
        end
    end)

    return true
end

function StartLighting(ped)
    isSmokingLighting = true
    smokingInhaleStartTime = GetGameTimer()
    RequestSmokingSound('lighter', nil, false, false)
    ReattachMainItem(ped, 'light')
    RefreshSecondaryItem(ped, 'light')
    StopParticle(idleParticleFx)
    idleParticleFx = nil
    PlayLightAnimation(ped)
    RefreshLightParticle()
    DebugLog('Started light stage')
end

function CheckLightingTimer(ped)
    local anims     = currentSmokingConfig and currentSmokingConfig.animations
    local lightAnim = anims and anims.light
    local lightDur  = lightAnim and lightAnim.durationMs or 1200
    local elapsed   = GetGameTimer() - smokingInhaleStartTime
    SetPedCanHeadIk(ped, false)
    SetPedCanTorsoIk(ped, false)
    if elapsed >= lightDur then
        RevertToIdleAfterLight(ped)
    else
        if not IsAnimationPlaying(ped, 'light') then
            PlayLightAnimation(ped)
        end
    end
end

function CheckPuffForceRelease(ped)
    local dur = currentSmokingConfig.consumption
        and currentSmokingConfig.consumption.puff
        and currentSmokingConfig.consumption.puff.duration
    if not dur then return end
    local maxHold = dur.maxHoldMs
    if not maxHold or maxHold <= 0 then return end
    local elapsed = GetGameTimer() - smokingInhaleStartTime
    if elapsed >= maxHold then
        FinishPuff(ped, elapsed, true)
    else
        if not IsAnimationPlaying(ped, 'puff') then
            PlayPuffAnimation(ped)
        end
        SetPedCanHeadIk(ped, false)
        SetPedCanTorsoIk(ped, false)
    end
end

function TriggerLightCheck()
    if not currentSmokingItemKey or not currentSmokingType then return false end
    TriggerServerEvent('rtx_smoking:server:lightCheck', currentSmokingItemKey, currentSmokingType)
    Citizen.Wait(500)
    return true
end

-- ── démarrage / arrêt du fumage ──────────────────────────
function StopSmoking()
    SaveVapeMetadataIfNeeded()
    StopCurrentInhaleLoopSound()

    isSmokingActive   = false
    isSmokingPuffing  = false
    isSmokingLighting = false
    smokingInhaleStartTime = 0
    smokingPuffStyleIndex  = 1

    local ped = PlayerPedId()
    StopAllSmokingAnimations(ped)
    ClearPedTasks(ped)
    StopAllSmokingParticles()
    DeleteMainAndSecondaryItems()
    CloseSmokingUIFromState()
    isSmokingMenuOpen = false
    SetNuiFocus(false, false)

    currentSmokingConfig     = nil
    currentSmokingState      = nil
    currentSmokingType       = nil
    currentSmokingItemKey    = nil
    currentSmokingVariantDef = nil

    DebugLog('Smoking stopped')
    TriggerServerEvent('rtx_smoking:server:SetSmokingState', { smoking = false })
end

function SaveVapeMetadataIfNeeded()
    if not isSmokingActive or not currentSmokingItemKey then return end
    if not currentSmokingState then return end
    if currentSmokingType ~= 'vape' then return end
    TriggerServerEvent('rtx_smoking:server:SaveSmokingMetadata', currentSmokingItemKey, currentSmokingState)
end

function StartSmoking(variantKey, inputState)
    local ped = PlayerPedId()
    if isSmokingActive then
        StopSmoking()
        return
    end
    if IsEntityDead(ped) then return end

    local variantDef, itemConfig = ResolveSmokingVariantAndConfig(variantKey)
    if not variantDef or not itemConfig then
        print(string.format('[RTX SMOKING] Invalid SmokingVariant: %s', tostring(variantKey)))
        Notify('error', Language[Config.Language].smoking, Language[Config.Language].itemnotready)
        return
    end

    currentSmokingItemKey    = variantKey
    currentSmokingVariantDef = variantDef
    currentSmokingType       = variantDef.type
    currentSmokingConfig     = itemConfig
    currentSmokingState      = BuildSmokingStateFromInput(currentSmokingType, inputState)
    EnrichStateWithSelectionData(currentSmokingType, currentSmokingState)

    if not currentSmokingState.itemId then
        currentSmokingState.itemId = variantDef.item
    end
    if inputState and inputState.itemId then
        currentSmokingState.itemId = inputState.itemId
    end

    if not currentSmokingState.subtitle then
        currentSmokingState.subtitle = currentSmokingState.selectionLabel or variantDef.label
    end

    if currentSmokingType == 'cigarette' then
        if not currentSmokingState.brand then
            currentSmokingState.brand = variantDef.brand or currentSmokingState.subtitle or variantDef.label
        end
    end

    local valid, reason = ValidateSmokingStateIntegrity(currentSmokingType, currentSmokingState)
    if not valid then
        DebugLog('Cannot start: ' .. (reason or 'invalid state'))
        Notify('error', Language[Config.Language].smoking, Language[Config.Language].itemnotready)
        currentSmokingItemKey = nil
        currentSmokingVariantDef = nil
        currentSmokingType = nil
        currentSmokingConfig = nil
        currentSmokingState = nil
        return
    end

    local spawned = SpawnMainItem(ped)
    if not spawned then
        DebugLog('Failed to create main item')
        Notify('error', Language[Config.Language].smoking, Language[Config.Language].itemnotready)
        currentSmokingItemKey = nil
        currentSmokingVariantDef = nil
        currentSmokingType = nil
        currentSmokingConfig = nil
        currentSmokingState = nil
        return
    end

    RefreshSecondaryItem(ped, 'idle')

    isSmokingActive   = true
    isSmokingPuffing  = false
    isSmokingLighting = false
    smokingInhaleStartTime = 0
    smokingPuffStyleIndex  = 1

    PlayIdleAnimation(ped)
    RefreshIdleParticle()
    OpenSmokingUIFromState()

    DebugLog(string.format('Started smoking variant: %s | type: %s', variantKey, currentSmokingType))
    TriggerServerEvent('rtx_smoking:server:SetSmokingState', {
        smoking = true,
        item    = currentSmokingItemKey,
        type    = currentSmokingType,
    })

    CreateThread(function()
        while isSmokingActive do
            local pedLocal = PlayerPedId()
            if IsEntityDead(pedLocal) or IsPedRagdoll(pedLocal) then
                StopSmoking()
                break
            end

            if not isSmokingBusy then
                if IsControlJustPressed(0, Config.CancelKey) then
                    StopSmoking()
                    break
                end

                if not isSmokingPuffing and not isSmokingLighting then
                    if IsControlJustPressed(0, Config.SettingsKey) then
                        OpenSmokingSettingsMenu()
                    end
                    if IsControlJustPressed(0, Config.GiveKey) then
                        TryGiveSmokingItem()
                    end
                end

                if not isSmokingPuffing and not isSmokingLighting then
                    if IsControlJustPressed(0, Config.CycleIdleKey) then
                        CycleIdleVariant()
                    end
                    if IsControlJustPressed(0, Config.SecretSwitchPuffKey) then
                        SupportsPuffStyles()
                    end
                end

                local puffDurConfig = currentSmokingConfig.consumption
                    and currentSmokingConfig.consumption.puff
                    and currentSmokingConfig.consumption.puff.duration

                if isSmokingLighting then
                    CheckLightingTimer(pedLocal)
                elseif isSmokingPuffing then
                    CheckPuffForceRelease(pedLocal)
                else
                    if IsControlJustPressed(0, Config.HoldKey) then
                        if currentSmokingConfig.supportsLighting and not currentSmokingState.lighted then
                            TriggerLightCheck()
                        else
                            if CanPuffNow() and CanStartNewPuff() then
                                StartPuff(pedLocal)
                            end
                        end
                    end
                end

                if isSmokingPuffing then
                    if IsControlJustReleased(0, Config.HoldKey) then
                        SetPedCanHeadIk(pedLocal, false)
                        SetPedCanTorsoIk(pedLocal, false)
                        local holdMs = GetGameTimer() - smokingInhaleStartTime
                        FinishPuff(pedLocal, holdMs, false)
                    end
                end
            end

            Wait(0)
        end
    end)
end

-- ── menu des paramètres de fumée ─────────────────────────
function OpenSmokingSettingsMenu()
    if not isSmokingActive then return end
    if isSmokingBusy then return end
    if isSmokingMenuOpen then return end

    local t = currentSmokingType
    if t == 'vape' then
        isSmokingMenuOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'smoking:menuItems',
            data   = {
                menu  = 'vape_flavour',
                items = GetSelectionSetItems('vape', 'smoking:setFlavour'),
            },
        })
        SendNUIMessage({ action = 'smoking:menu', data = { menu = 'vape_settings' } })
    elseif t == 'bong' then
        isSmokingMenuOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'smoking:menuItems',
            data   = {
                menu  = 'bong_fill',
                items = GetSelectionSetItems('bong', 'smoking:setBongFill'),
            },
        })
        SendNUIMessage({ action = 'smoking:menu', data = { menu = 'bong_settings' } })
    elseif t == 'joint' then
        isSmokingMenuOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'smoking:menuItems',
            data   = {
                menu  = 'roll_joint',
                items = GetSelectionSetItems('joint', 'smoking:craftJoint'),
            },
        })
        SendNUIMessage({ action = 'smoking:menu', data = { menu = 'roll_joint' } })
    end
end

-- ── callbacks NUI fumée ───────────────────────────────────
RegisterNUICallback('smoking:setFlavour', function(data, cb)
    if isSmokingBusy then cb(false) return end
    if not data.id or data.id == '' then cb(false) return end
    TriggerServerEvent('rtx_smoking:server:removeLiquid', data.id)
    cb(true)
end)

RegisterNUICallback('smoking:changeBattery', function(data, cb)
    if isSmokingBusy then cb(false) return end
    TriggerServerEvent('rtx_smoking:server:removeVapeBattery')
    cb(true)
end)

RegisterNUICallback('smoking:setBongFill', function(data, cb)
    if isSmokingBusy then cb(false) return end
    if not data.id or data.id == '' then cb(false) return end
    TriggerServerEvent('rtx_smoking:server:FillBong', data.id)
    cb(true)
end)

RegisterNUICallback('smoking:addWater', function(data, cb)
    if isSmokingBusy then cb(false) return end
    TriggerServerEvent('rtx_smoking:server:RemoveWater')
    cb(true)
end)

RegisterNUICallback('smoking:craftJoint', function(data, cb)
    if isSmokingBusy then cb(false) return end
    if not data.id or data.id == '' then cb(false) return end
    TriggerServerEvent('rtx_smoking:server:CraftJoint', data.id)
    cb(true)
end)

RegisterNUICallback('smoking:takeHit', function(_, cb)
    cb(StartSmokingHitFromUI())
end)

RegisterNUICallback('smoking:takePuff', function(_, cb)
    cb(StartSmokingHitFromUI())
end)

RegisterNUICallback('smoking:light', function(_, cb)
    if not isSmokingActive or isSmokingBusy or isSmokingPuffing or isSmokingLighting then
        cb(false)
        return
    end

    if not currentSmokingConfig.supportsLighting or currentSmokingState.lighted then
        cb(false)
        return
    end

    TriggerLightCheck()
    cb(true)
end)

RegisterNUICallback('smoking:give', function(_, cb)
    cb(TryGiveSmokingItem())
end)

RegisterNUICallback('smoking:position', function(_, cb)
    cb(CycleIdleVariant())
end)

RegisterNUICallback('smoking:cancel', function(_, cb)
    if not isSmokingActive then
        cb(false)
        return
    end

    StopSmoking()
    cb(true)
end)

-- ── événements réseau fumée ───────────────────────────────
RegisterNetEvent('rtx_smoking:LiquidChange')
AddEventHandler('rtx_smoking:LiquidChange', function(flavorKey)
    if not flavorKey or flavorKey == '' then return end
    local poses = GetProgressActionPoses('fillFlavour', 'vape', flavorKey)
    local ok    = RunProgressAction('fill_flavour', poses)
    if ok then
        currentSmokingState.selectionKey = flavorKey
        currentSmokingState.flavourKey   = flavorKey
        currentSmokingState.fillKey      = nil
        EnrichStateWithSelectionData('vape', currentSmokingState)
        local entry = GetSelectionSetEntry('vape', flavorKey)
        local label = (entry and entry.label) or flavorKey
        currentSmokingState.stats = currentSmokingState.stats or {}
        currentSmokingState.stats.fill = 100.0
        Notify('info', Language[Config.Language].vape, GetLocalizedFormattedString('vapefilled', label))
        UpdateSmokingUIFromState()
    end
end)

RegisterNetEvent('rtx_smoking:BatteryChange')
AddEventHandler('rtx_smoking:BatteryChange', function()
    if isSmokingBusy then return end
    local poses = GetProgressActionPoses('changeBattery')
    local ok    = RunProgressAction('change_battery', poses)
    if ok then
        SetCurrentSmokingStat('battery', 100.0)
        Notify('info', Language[Config.Language].vape, Language[Config.Language].vapebatterychanged)
        UpdateSmokingUIFromState()
    end
end)

RegisterNetEvent('rtx_smoking:LightCigarette')
AddEventHandler('rtx_smoking:LightCigarette', function()
    if isSmokingBusy then return end
    if not currentSmokingConfig or not currentSmokingConfig.supportsLighting then return end
    if currentSmokingState and currentSmokingState.lighted then return end
    RequestSmokingSound('lighter', nil, false, false)
    StartLighting(PlayerPedId())
end)

RegisterNetEvent('rtx_smoking:FillChange')
AddEventHandler('rtx_smoking:FillChange', function(fillKey)
    if isSmokingBusy then return end
    if not fillKey or fillKey == '' then return end
    local poses = GetProgressActionPoses('fillBong', 'bong', fillKey)
    local ok    = RunProgressAction('fill_bong', poses)
    if ok then
        currentSmokingState.selectionKey = fillKey
        currentSmokingState.fillKey      = fillKey
        currentSmokingState.flavourKey   = nil
        EnrichStateWithSelectionData('bong', currentSmokingState)
        SetCurrentSmokingStat('fill', 100.0)
        local entry = GetSelectionSetEntry('bong', fillKey)
        local label = (entry and entry.label) or fillKey
        Notify('info', Language[Config.Language].bong, GetLocalizedFormattedString('bongfilled', label))
        UpdateSmokingUIFromState()
    end
end)

RegisterNetEvent('rtx_smoking:WaterChange')
AddEventHandler('rtx_smoking:WaterChange', function()
    if isSmokingBusy then return end
    local poses = GetProgressActionPoses('fillWater', nil, nil, 'vw_prop_casino_water_bottle_01a')
    local ok    = RunProgressAction('fill_water', poses)
    if ok then
        SetCurrentSmokingStat('water', 100.0)
        Notify('info', Language[Config.Language].bong, Language[Config.Language].bongwaterchanged)
        UpdateSmokingUIFromState()
    end
end)

RegisterNetEvent('rtx_smoking:CraftJoint')
AddEventHandler('rtx_smoking:CraftJoint', function(fillKey)
    if isSmokingBusy then return end
    if not fillKey or fillKey == '' then return end
    local poses = GetProgressActionPoses('craftJoint', 'joint', fillKey)
    local ok    = RunProgressAction('craft_joint', poses)
    if ok then
        local entry = GetSelectionSetEntry('joint', fillKey)
        local label = (entry and entry.label) or fillKey
        Notify('info', Language[Config.Language].smoking, GetLocalizedFormattedString('jointrolled', label))
        TriggerServerEvent('rtx_smoking:server:CraftedJoint', fillKey)
    end
end)

RegisterNetEvent('rtx_smoking:client:GiveSucceeded')
AddEventHandler('rtx_smoking:client:GiveSucceeded', function()
    if isSmokingBusy then
        Notify('error', Language[Config.Language].smoking, Language[Config.Language].cannotgiveitem)
        return
    end
    if not isSmokingActive then
        Notify('error', Language[Config.Language].smoking, Language[Config.Language].nosmokingitem)
        return
    end
    StopSmoking()
    PlayGiveAnimationA()
    Notify('info', Language[Config.Language].smoking, Language[Config.Language].itemgiven)
end)

RegisterNetEvent('rtx_smoking:client:GiveFailed')
AddEventHandler('rtx_smoking:client:GiveFailed', function(reason)
    Notify('error', Language[Config.Language].smoking, reason or Language[Config.Language].unabletogiveitem)
end)

RegisterNetEvent('rtx_smoking:client:ReceiveSmokingItem')
AddEventHandler('rtx_smoking:client:ReceiveSmokingItem', function(senderId, itemData)
    if isSmokingBusy or isSmokingActive then return end
    if type(itemData) ~= 'table' then return end
    if type(itemData.variantKey) ~= 'string' then return end
    if type(itemData.state) ~= 'table' then return end
    PlayGiveAnimationB()
    Citizen.Wait(500)
    Notify('info', Language[Config.Language].smoking, Language[Config.Language].receivedsmokingitem)
    StartSmoking(itemData.variantKey, itemData.state)
end)

RegisterNetEvent('rtx_smoking:client:SyncPedParticle')
AddEventHandler('rtx_smoking:client:SyncPedParticle', function(particleData)
    if type(particleData) ~= 'table' or not particleData.sourceServerId then return end
    local pid = FindLocalPlayerById(particleData.sourceServerId)
    if pid == nil then return end
    local ped = GetPlayerPed(pid)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end

    local ptfxDict = particleData.ptfxDict
    local ptfxName = particleData.ptfxName
    local bone     = particleData.bone or 47495
    local scale    = particleData.scale or 0.3
    local offset   = particleData.offset   or vec3(0, 0, 0)
    local rotation = particleData.rotation or vec3(0, 0, 0)
    local duration = particleData.durationMs or 1000

    LoadNamedPtfxSync(ptfxDict)
    UseParticleFxAssetNextCall(ptfxDict)
    local fxHandle = _ENV['StartNetworkedParticleFxLoopedOnEntityBone'](
        ptfxName, ped,
        offset.x, offset.y, offset.z,
        rotation.x, rotation.y, rotation.z,
        GetPedBoneIndex(ped, bone),
        scale, false, false, false
    )
    CreateThread(function()
        Wait(duration)
        if fxHandle then StopParticleFxLooped(fxHandle, false) end
    end)
end)

RegisterNetEvent('rtx_smoking:client:useItem')
AddEventHandler('rtx_smoking:client:useItem', function(itemCategory, variantKey, savedState)
    if not itemCategory or not variantKey then return end
    if type(savedState) == 'table' then
        StartSmoking(variantKey, savedState)
        return
    end

    if itemCategory == 'cigarette' then
        StartSmoking(variantKey, {
            itemId      = variantKey .. '_01',
            ignited     = false,
            idleVariant = 'hand',
            stats       = { durability = 100.0, burnLevel = 0.0, smokeLevel = 0.0 },
        })
    elseif itemCategory == 'cigar' then
        StartSmoking(variantKey, {
            itemId      = variantKey .. '_01',
            ignited     = false,
            idleVariant = 'hand',
            stats       = { durability = 100.0, burnLevel = 0.0, smokeLevel = 0.0 },
        })
    elseif itemCategory == 'joint' then
        local fillMap = {
            joint_og_kush      = 'og_kush',
            joint_purple_haze  = 'purple_haze',
            joint_amnesia_haze = 'amnesia_haze',
            joint_white_widow  = 'white_widow',
        }
        local fillKey = fillMap[variantKey] or 'og_kush'
        StartSmoking(variantKey, {
            itemId      = variantKey .. '_01',
            ignited     = false,
            fillKey     = fillKey,
            stats       = { durability = 100.0, burnLevel = 0.0, smokeLevel = 0.0, fill = 78.0 },
        })
    elseif itemCategory == 'bong' then
        StartSmoking(variantKey, {
            itemId       = variantKey .. '_01',
            ignited      = true,
            selectionKey = '',
            stats        = { water = 0.0, fill = 0.0, smokeLevel = 46.0, durability = 0.0 },
        })
    elseif itemCategory == 'vape' then
        StartSmoking(variantKey, {
            itemId       = variantKey .. '_01',
            ignited      = true,
            selectionKey = 'apple',
            stats        = { battery = 100.0, fill = 100.0, heat = 22.0, durability = 93.0 },
        })
    elseif itemCategory == 'rolling_paper' then
        isSmokingMenuOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'smoking:menuItems',
            data   = {
                menu  = 'roll_joint',
                items = GetSelectionSetItems('joint', 'smoking:craftJoint'),
            },
        })
        SendNUIMessage({ action = 'smoking:menu', data = { menu = 'roll_joint' } })
    end
end)

-- ── fermeture du menu narguilé ───────────────────────────
function CloseHookahMenuLocal()
    if not hookahMenuOpen then return end
    local ped = PlayerPedId()
    SetEntityVisible(ped, true)
    hookahMenuOpen     = false
    hookahMenuHookahId = nil
    ToggleHookahNUI(false)
    SetNuiFocus(false, false)
    if DoesCamExist(hookahCamera) then
        DestroyCam(hookahCamera, false)
        hookahCamera = nil
    end
    RenderScriptCams(false, true, 1000, true, false)
end

-- ── nettoyage au décès ────────────────────────────────────
function CleanupSmokingOnDeath()
    local wasBusy = isSmokingBusy == true
    CancelHookahPlacement()
    if hookahHoseActive then ExitHookahHose(true) end
    if isSmokingActive   then StopSmoking() end
    CloseHookahMenuLocal()
    HideSmokingUI()
    isSmokingBusy   = false
    isSmokingUIOpen = false
    if wasBusy then
        FreezeEntityPosition(PlayerPedId(), false)
    end
    StopAllSmokingParticles()
    DeleteMainAndSecondaryItems()
    CleanupAllSmokingAudio()
end

CreateThread(function()
    local wasDead = false
    while true do
        Wait(250)
        local ped  = PlayerPedId()
        local dead = IsEntityDead(ped) or IsPedFatallyInjured(ped)
        if dead and not wasDead then
            CleanupSmokingOnDeath()
        end
        wasDead = dead
    end
end)

AddEventHandler('baseevents:onPlayerDied', function()
    CleanupSmokingOnDeath()
end)

AddEventHandler('baseevents:onPlayerKilled', function()
    CleanupSmokingOnDeath()
end)

-- ── commandes / touches (sans target) ────────────────────
if Config.Target == false then
    RegisterCommand('useinteractionhookah', function()
        if nearestHookahId == nil then return end
        if isPlacingHookah or hookahMenuOpen or hookahHoseActive or isSmokingBusy then return end
        TriggerServerEvent('rtx_smoking:Global:CheckHookah', nearestHookahId)
    end)

    RegisterCommand('grabhosehookah', function()
        if nearestHookahId == nil then return end
        if isPlacingHookah or hookahMenuOpen or hookahHoseActive or isSmokingBusy then return end
        TriggerServerEvent('rtx_smoking:Global:ConnectHose', nearestHookahId)
    end)

    RegisterKeyMapping('useinteractionhookah', Language[Config.Language].hookah,    'keyboard', Config.HookahUseKey)
    RegisterKeyMapping('grabhosehookah',        Language[Config.Language].hookahhose, 'keyboard', Config.HookahHoseKey)
else
    RegisterNetEvent('rtx_smoking:Global:HookahInteractTarget')
    AddEventHandler('rtx_smoking:Global:HookahInteractTarget', function()
        if nearestHookahId == nil then return end
        if isPlacingHookah or hookahMenuOpen or hookahHoseActive or isSmokingBusy then return end
        TriggerServerEvent('rtx_smoking:Global:CheckHookah', nearestHookahId)
    end)

    RegisterNetEvent('rtx_smoking:Global:HookahHoseTarget')
    AddEventHandler('rtx_smoking:Global:HookahHoseTarget', function()
        if nearestHookahId == nil then return end
        if isPlacingHookah or hookahMenuOpen or hookahHoseActive or isSmokingBusy then return end
        TriggerServerEvent('rtx_smoking:Global:ConnectHose', nearestHookahId)
    end)
end

-- ── exports ───────────────────────────────────────────────
exports('StartSmokingWithState',          function(variantKey, state) StartSmoking(variantKey, state) end)
exports('StopSmoking',                    function() StopSmoking() end)
exports('GetCurrentSmokingState',         function() return GetCurrentSmokingStateSnapshot() end)
exports('GetCurrentSmokingGiftData',      function() return GetCurrentSmokingGiftData() end)
exports('BuildSmokingState',              function(variantKey, inputState)
    local variantDef = GetSmokingVariantDef(variantKey)
    if not variantDef then return nil end
    return BuildSmokingStateFromInput(variantDef.type, inputState)
end)
exports('UpdateCurrentSmokingState',      function(updates) return UpdateCurrentSmokingState(updates) end)
exports('SetCurrentSmokingLighted',       function(v)       return SetCurrentSmokingLighted(v) end)
exports('SetCurrentSmokingSelectionKey',  function(k)       return SetCurrentSmokingSelectionKey(k) end)
exports('SetCurrentSmokingSubtitle',      function(t)       return SetCurrentSmokingSubtitle(t) end)
exports('SetCurrentSmokingBrand',         function(b)       return SetCurrentSmokingBrand(b) end)
exports('SetCurrentSmokingIdleVariant',   function(v)       return SetCurrentSmokingIdleVariant(v) end)
exports('SetCurrentSmokingStat',          function(k, v)    return SetCurrentSmokingStat(k, v) end)
exports('AddCurrentSmokingStat',          function(k, v)    return AddCurrentSmokingStat(k, v) end)
exports('SetCurrentSmokingBattery',       function(v)       return SetCurrentSmokingStat('battery', v) end)
exports('AddCurrentSmokingBattery',       function(v)       return AddCurrentSmokingStat('battery', v) end)
exports('SetCurrentSmokingFill',          function(v)       return SetCurrentSmokingStat('fill', v) end)
exports('AddCurrentSmokingFill',          function(v)       return AddCurrentSmokingStat('fill', v) end)
exports('SetCurrentSmokingWater',         function(v)       return SetCurrentSmokingStat('water', v) end)
exports('AddCurrentSmokingWater',         function(v)       return AddCurrentSmokingStat('water', v) end)
exports('SetCurrentSmokingDurability',    function(v)       return SetCurrentSmokingStat('durability', v) end)
exports('AddCurrentSmokingDurability',    function(v)       return AddCurrentSmokingStat('durability', v) end)

-- ── événements réseau (alias) ─────────────────────────────
RegisterNetEvent('smoking:startWithState')
AddEventHandler('smoking:startWithState',   function(k, s) StartSmoking(k, s) end)

RegisterNetEvent('smoking:stop')
AddEventHandler('smoking:stop',             function() StopSmoking() end)

RegisterNetEvent('smoking:updateState')
AddEventHandler('smoking:updateState',      function(u) UpdateCurrentSmokingState(u) end)

RegisterNetEvent('smoking:setLighted')
AddEventHandler('smoking:setLighted',       function(v) SetCurrentSmokingLighted(v) end)

RegisterNetEvent('smoking:setSelectionKey')
AddEventHandler('smoking:setSelectionKey',  function(k) SetCurrentSmokingSelectionKey(k) end)

RegisterNetEvent('smoking:setSubtitle')
AddEventHandler('smoking:setSubtitle',      function(t) SetCurrentSmokingSubtitle(t) end)

RegisterNetEvent('smoking:setBrand')
AddEventHandler('smoking:setBrand',         function(b) SetCurrentSmokingBrand(b) end)

RegisterNetEvent('smoking:setIdleVariant')
AddEventHandler('smoking:setIdleVariant',   function(v) SetCurrentSmokingIdleVariant(v) end)

RegisterNetEvent('smoking:setBattery')
AddEventHandler('smoking:setBattery',       function(v) SetCurrentSmokingStat('battery', v) end)

RegisterNetEvent('smoking:addBattery')
AddEventHandler('smoking:addBattery',       function(v) AddCurrentSmokingStat('battery', v) end)

RegisterNetEvent('smoking:setFill')
AddEventHandler('smoking:setFill',          function(v) SetCurrentSmokingStat('fill', v) end)

RegisterNetEvent('smoking:addFill')
AddEventHandler('smoking:addFill',          function(v) AddCurrentSmokingStat('fill', v) end)

RegisterNetEvent('smoking:setWater')
AddEventHandler('smoking:setWater',         function(v) SetCurrentSmokingStat('water', v) end)

RegisterNetEvent('smoking:addWater')
AddEventHandler('smoking:addWater',         function(v) AddCurrentSmokingStat('water', v) end)

RegisterNetEvent('smoking:setDurability')
AddEventHandler('smoking:setDurability',    function(v) SetCurrentSmokingStat('durability', v) end)

RegisterNetEvent('smoking:addDurability')
AddEventHandler('smoking:addDurability',    function(v) AddCurrentSmokingStat('durability', v) end)

-- ── seed aléatoire ────────────────────────────────────────
CreateThread(function()
    math.randomseed(GetGameTimer())
end)

-- ── nettoyage à l'arrêt de la ressource ──────────────────
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    StopAllSmokingLoopSounds()
    CancelHookahPlacement()

    local ped = PlayerPedId()
    if isSmokingActive then
        StopAllSmokingParticles()
        DeleteMainAndSecondaryItems()
        StopAllSmokingAnimations(ped)
        ClearPedTasks(ped)
    end

    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true)
    SetNuiFocus(false, false)

    if DoesCamExist(hookahCamera) then
        DestroyCam(hookahCamera, false)
        hookahCamera = nil
    end
    RenderScriptCams(false, 0, 0, true, false)

    for hookahIdVal, hookahData in pairs(hookahs) do
        local hookahIdStr = tostring(hookahIdVal)
        if hookahData.hoses and hookahData.hoses.players then
            for sid, _ in pairs(hookahData.hoses.players) do
                CleanupHoseForPlayer(hookahIdStr, sid)
            end
        end
        for _, entityKey in ipairs({'handler','tabacco','tabaccofilled','coalobj','coalobj2','burner','cover','covercoal'}) do
            if hookahData[entityKey] and DoesEntityExist(hookahData[entityKey]) then
                DeleteEntity(hookahData[entityKey])
            end
        end
    end
end)