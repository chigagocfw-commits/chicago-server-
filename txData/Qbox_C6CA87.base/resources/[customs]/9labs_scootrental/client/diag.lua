if not ScootConfig.debug then
    return
end

local trackedBones = { "root", "door", "fork", "fork_mid" }
local testPhases = { 0.0, 0.1, 0.16, 0.3, 0.52 }

local function diagLog(formatStr, ...)
    print(string.format("[scootdiag] " .. formatStr, ...))
end

local function formatBoneOffsets(entity, boneIndices)
    local results = {}
    for i = 1, #trackedBones do
        local boneIndex = boneIndices[i]
        local boneName = trackedBones[i]

        if boneIndex ~= -1 then
            local worldPos = GetWorldPositionOfEntityBone(entity, boneIndex)
            local relOffset = GetOffsetFromEntityGivenWorldCoords(entity, worldPos.x, worldPos.y, worldPos.z)
            results[#results + 1] = string.format("%s=%.3f/%.3f/%.3f", boneName, relOffset.x, relOffset.y, relOffset.z)
        else
            results[#results + 1] = string.format("%s=MISSING", boneName)
        end
    end
    return table.concat(results, "  ")
end

local function testPhasesOnBunker(entity, boneIndices, label)
    for i = 1, #testPhases do
        local targetPhase = testPhases[i]
        ScootBunker.setPhase(entity, targetPhase)
        ScootBunker.setSpeed(entity, 0.0)
        Wait(150)

        local actualPhase = ScootBunker.phaseOf(entity)
        local boneOffsetsStr = formatBoneOffsets(entity, boneIndices)
        diagLog("%s phase=%.2f read=%.3f  %s", label, targetPhase, actualPhase, boneOffsetsStr)
    end
end

RegisterCommand("scootsound", function(_, args)
    local targetArg = args[1]
    local playerCoords = GetEntityCoords(cache.ped)

    if targetArg and targetArg:find("%.ogg$") then
        diagLog("play %s", targetArg)
        ScootAudio.play(targetArg, playerCoords, 1.0, 3.0)
        return
    end

    if not ScootConfig.sounds then
        return
    end

    for i = 1, #ScootConfig.sounds do
        local cue = ScootConfig.sounds[i]
        local matched = not targetArg or cue.file:find(targetArg, 1, true)

        if matched then
            diagLog("play %s vol=%.2f len=%.2f", cue.file, cue.volume, cue.length)
            ScootAudio.play(cue.file, playerCoords, cue.volume, cue.length)
            Wait(math.floor(cue.length * 1000) + 250)
        end
    end
end, false)

RegisterCommand("scootdiag", function()
    local playerCoords = GetEntityCoords(cache.ped)
    local nearestId = nil
    local nearestDist = nil

    for stationId, station in pairs(ScootBunker.list) do
        local dist = #(playerCoords - station.coords)
        if not nearestDist or dist < nearestDist then
            nearestDist = dist
            nearestId = stationId
        end
    end

    if not nearestId then
        diagLog("no bunker spawned nearby")
        return
    end

    local bunker = ScootBunker.list[nearestId]
    local bunkerObj = bunker.obj
    local boneIndices = {}

    for i = 1, #trackedBones do
        boneIndices[i] = GetEntityBoneIndexByName(bunkerObj, trackedBones[i])
    end

    diagLog("bunker #%d obj=%s dist=%.1f bones=%s/%s/%s/%s",
        nearestId,
        tostring(bunkerObj),
        nearestDist,
        tostring(boneIndices[1]),
        tostring(boneIndices[2]),
        tostring(boneIndices[3]),
        tostring(boneIndices[4])
    )

    local proxyPhysics = bunker.proxy and tostring(DoesEntityHavePhysics(bunker.proxy)) or "none"
    local proxyCollision = bunker.proxy and tostring(GetEntityCollisionDisabled(bunker.proxy)) or "none"

    diagLog("prop physics=%s collisionDisabled=%s | proxy=%s physics=%s collisionDisabled=%s",
        tostring(DoesEntityHavePhysics(bunkerObj)),
        tostring(GetEntityCollisionDisabled(bunkerObj)),
        tostring(bunker.proxy or "none"),
        proxyPhysics,
        proxyCollision
    )

    local barrierModel = `prop_barrier_work05`
    if lib.requestModel(barrierModel, 5000) then
        local testProp = CreateObjectNoOffset(barrierModel, playerCoords.x + 2.0, playerCoords.y, playerCoords.z, false, false, true)
        Wait(200)
        diagLog("control prop_barrier_work05 obj=%s physics=%s collisionDisabled=%s",
            tostring(testProp),
            tostring(DoesEntityHavePhysics(testProp)),
            tostring(GetEntityCollisionDisabled(testProp))
        )
        DeleteEntity(testProp)
        SetModelAsNoLongerNeeded(barrierModel)
    else
        diagLog("control prop failed to load")
    end

    local minDim, maxDim = GetModelDimensions(GetEntityModel(bunkerObj))
    diagLog("model dims min=%.2f/%.2f/%.2f max=%.2f/%.2f/%.2f", minDim.x, minDim.y, minDim.z, maxDim.x, maxDim.y, maxDim.z)
    diagLog("model=%s anim=%s/%s playing=%s",
        ScootAssets.model,
        ScootAssets.animDict,
        ScootAssets.animClip,
        tostring(IsEntityPlayingAnim(bunkerObj, ScootAssets.animDict, ScootAssets.animClip, 3))
    )

    ScootBunker.ensureAnim(bunker)
    local initialCoords = GetEntityCoords(bunkerObj)

    testPhasesOnBunker(bunkerObj, boneIndices, "frozen  ")

    FreezeEntityPosition(bunkerObj, false)
    SetEntityDynamic(bunkerObj, true)
    testPhasesOnBunker(bunkerObj, boneIndices, "unfrozen")

    local afterCoords = GetEntityCoords(bunkerObj)
    FreezeEntityPosition(bunkerObj, true)
    SetEntityCoordsNoOffset(bunkerObj, initialCoords.x, initialCoords.y, initialCoords.z, false, false, false)
    ScootBunker.setPhase(bunkerObj, 0.0)

    diagLog("entity drift while unfrozen = %.3f m", #(afterCoords - initialCoords))
end, false)
