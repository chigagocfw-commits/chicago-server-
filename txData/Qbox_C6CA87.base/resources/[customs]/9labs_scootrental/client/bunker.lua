local bunkerModel = joaat(ScootAssets.model)
local collisionModel = joaat(ScootAssets.collisionModel or ScootAssets.model)
local animDict = ScootAssets.animDict
local animClip = ScootAssets.animClip

local BunkerModule = {
    list = {},
    onInteract = nil
}

function BunkerModule.debug(...)
    if not ScootConfig.debug then
        return
    end
    local message = string.format("[scootbunker] %s", table.concat({ ... }, " "))
    print(message)
end

function BunkerModule.notify(message)
    lib.notify({
        description = message,
        type = "error"
    })
end

function BunkerModule.setPhase(entity, phase)
    SetEntityAnimCurrentTime(entity, animDict, animClip, phase)
end

function BunkerModule.setSpeed(entity, speed)
    SetEntityAnimSpeed(entity, animDict, animClip, speed)
end

function BunkerModule.phaseOf(entity)
    return GetEntityAnimCurrentTime(entity, animDict, animClip)
end

function BunkerModule.ensureAnim(bunkerData)
    local entity = bunkerData.obj
    if not DoesEntityExist(entity) then
        return false
    end

    if bunkerData.playing and IsEntityPlayingAnim(entity, animDict, animClip, 3) then
        return true
    end

    if not lib.requestAnimDict(animDict, 10000) then
        BunkerModule.notify(ScootT("animation_failed"))
        return false
    end

    for _ = 1, 3 do
        PlayEntityAnim(entity, animClip, animDict, 1.0, false, true, false, 0.0, 0)
        Wait(0)
        if IsEntityPlayingAnim(entity, animDict, animClip, 3) then
            break
        end
    end

    bunkerData.playing = true
    BunkerModule.setSpeed(entity, 0.0)
    BunkerModule.setPhase(entity, 0.0)
    BunkerModule.debug(string.format("anim %s/%s playing=%s phase=%.3f", animDict, animClip, tostring(IsEntityPlayingAnim(entity, animDict, animClip, 3)), BunkerModule.phaseOf(entity)))

    return true
end

function BunkerModule.moveCollision(bunkerData, offsetZ)
    local proxy = bunkerData.proxy
    if not proxy or not DoesEntityExist(proxy) then
        return
    end

    if bunkerData.proxyZ and math.abs(bunkerData.proxyZ - offsetZ) < 0.001 then
        return
    end

    bunkerData.proxyZ = offsetZ
    local coords = bunkerData.coords
    SetEntityCoordsNoOffset(proxy, coords.x, coords.y, coords.z + offsetZ, false, false, false)
end

local function spawnCollisionProxy(bunkerData)
    local coords = bunkerData.coords

    if collisionModel ~= bunkerModel then
        if not lib.requestModel(collisionModel, 10000) then
            return nil
        end
    end

    local initialZ = ScootCurves.rootZ[1] or 0.0
    local proxy = CreateObjectNoOffset(collisionModel, coords.x, coords.y, coords.z + initialZ, false, false, true)

    if proxy == 0 or not DoesEntityExist(proxy) then
        BunkerModule.debug("proxy failed to spawn")
        return nil
    end

    SetEntityHeading(proxy, (bunkerData.heading + 180.0) % 360.0)
    SetEntityAlpha(proxy, 0, false)
    SetEntityCollision(proxy, true, true)
    SetEntityDynamic(proxy, true)
    FreezeEntityPosition(proxy, true)
    SetEntityInvincible(proxy, true)
    SetEntityCanBeDamaged(proxy, false)
    SetEntityLodDist(proxy, 300)

    if collisionModel ~= bunkerModel then
        SetModelAsNoLongerNeeded(collisionModel)
    end

    BunkerModule.debug(string.format("proxy obj=%s physics=%s collisionDisabled=%s z=%.2f", tostring(proxy), tostring(DoesEntityHavePhysics(proxy)), tostring(GetEntityCollisionDisabled(proxy)), coords.z + initialZ))

    return proxy
end

local function registerTargetZone(stationId, bunkerData)
    if ScootConfig.interaction ~= "target" or GetResourceState("ox_target") ~= "started" then
        return
    end

    local zoneCoords = bunkerData.coords + vec3(0.0, 0.0, 0.9)
    local zone = exports.ox_target:addSphereZone({
        coords = zoneCoords,
        radius = ScootConfig.interactDistance,
        debug = ScootConfig.debug,
        options = {
            {
                name = string.format("scoot_bunker_%s", stationId),
                icon = ScootConfig.icon,
                label = ScootT("interact"),
                distance = ScootConfig.interactDistance,
                onSelect = function()
                    if BunkerModule.onInteract then
                        BunkerModule.onInteract(stationId)
                    end
                end,
                canInteract = function()
                    local station = BunkerModule.list[stationId]
                    return station ~= nil and not station.busy
                end
            }
        }
    })

    bunkerData.zone = zone
end

function BunkerModule.spawn(stationId, stationData)
    if not IsModelInCdimage(bunkerModel) or not lib.requestModel(bunkerModel, 10000) then
        BunkerModule.notify(ScootT("model_failed"))
        return
    end

    local coords = stationData.coords
    local obj = CreateObjectNoOffset(bunkerModel, coords.x, coords.y, coords.z, false, false, false)

    SetEntityHeading(obj, (stationData.heading + 180.0) % 360.0)
    FreezeEntityPosition(obj, true)
    SetEntityInvincible(obj, true)
    SetEntityCollision(obj, false, false)
    SetEntityLodDist(obj, 300)

    local bunkerData = {
        coords = coords,
        heading = stationData.heading,
        color = stationData.color,
        obj = obj,
        busy = false,
        playing = false
    }

    if ScootConfig.propCollision then
        bunkerData.proxy = spawnCollisionProxy(stationData)
        bunkerData.proxyZ = ScootCurves.rootZ[1]
    end

    SetModelAsNoLongerNeeded(bunkerModel)

    BunkerModule.list[stationId] = bunkerData
    BunkerModule.debug(string.format("spawn #%s at %.2f %.2f %.2f", tostring(stationId), coords.x, coords.y, coords.z))

    if ScootGlow and ScootGlow.apply then
        ScootGlow.apply()
    end

    if ScootLogo and ScootLogo.apply then
        ScootLogo.apply()
    end

    BunkerModule.ensureAnim(bunkerData)
    registerTargetZone(stationId, bunkerData)
end

function BunkerModule.despawn(stationId)
    local bunkerData = BunkerModule.list[stationId]
    if not bunkerData then
        return
    end

    if bunkerData.zone and GetResourceState("ox_target") == "started" then
        exports.ox_target:removeZone(bunkerData.zone)
    end

    if bunkerData.proxy and DoesEntityExist(bunkerData.proxy) then
        DeleteEntity(bunkerData.proxy)
    end

    if DoesEntityExist(bunkerData.obj) then
        DeleteEntity(bunkerData.obj)
    end

    BunkerModule.list[stationId] = nil
end

ScootBunker = BunkerModule
