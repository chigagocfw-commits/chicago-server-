Detection = Detection or {}

if not Constants then
    error("Constants module must be loaded before Detection")
end

local variantByModel = {
    [Constants.Models.fleeca] = "fleeca",
    [Constants.Models.one] = "one",
    [Constants.Models.two] = "two",
    [Constants.Models.three] = "three",
}

function Detection.isATMModel(model)
    for _, atmModel in ipairs(Constants.ATMModels) do
        if model == atmModel then
            return true
        end
    end

    return false
end

function Detection.getVariantIDFromObject(entity)
    if not DoesEntityExist(entity) then
        return nil
    end

    return variantByModel[GetEntityModel(entity)]
end

function Detection.getVariantForEntity(entity)
    if not DoesEntityExist(entity) then
        return nil
    end

    local variantId = Detection.getVariantIDFromObject(entity)
    local variant = variantId and GetATMVariant(variantId)

    if not variant then
        return nil
    end

    return {
        uiType = variant.uiType,
        txd = variant.hardwareTexture[1],
        tx = variant.softwareTexture[2],
        res = variant.res,
        variant = variant,
    }
end

function Detection.tryOffset(entity, offset)
    local forwardVector = GetEntityForwardVector(entity)
    local entityCoords = GetEntityCoords(entity)
    local point = entityCoords + (forwardVector * offset)
    local foundGround, groundZ = GetGroundZFor_3dCoord(point.x, point.y, point.z + 1.0, false)

    if foundGround then
        point = vector3(point.x, point.y, groundZ + 0.02)
    end

    return point
end

function Detection.getATMInteractionDistance(entity, playerCoords)
    if not DoesEntityExist(entity) then
        return math.huge
    end

    local entityCoords = GetEntityCoords(entity)
    local forwardVector = GetEntityForwardVector(entity)
    local offset = 1.0
    local variantId = Detection.getVariantIDFromObject(entity)
    local variant = variantId and GetATMVariant(variantId)

    if variant and variant.interactionSpotOffset then
        offset = math.abs(variant.interactionSpotOffset)
    end

    local forwardPoint = entityCoords + (forwardVector * offset)
    local backPoint = entityCoords - (forwardVector * offset)

    return math.min(
        #(forwardPoint - playerCoords),
        #(backPoint - playerCoords),
        #(entityCoords - playerCoords)
    )
end

local function addNearbyATM(candidates, entity, playerCoords, maxDistance)
    local variantId = Detection.getVariantIDFromObject(entity)
    local variant = variantId and GetATMVariant(variantId)

    if not variant then
        return
    end

    local distance = Detection.getATMInteractionDistance(entity, playerCoords)
    if distance <= maxDistance then
        candidates[entity] = math.min(candidates[entity] or math.huge, distance)
    end
end

function Detection.getClosestATM()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local maxDistance = Constants.Distances.INTERACTION_RANGE
    local candidates = {}

    for _, entity in ipairs(GetGamePool("CObject")) do
        addNearbyATM(candidates, entity, playerCoords, maxDistance)
    end

    local scanRadius = math.max(maxDistance + 1.0, 2.5)
    for _, model in ipairs(Constants.ATMModels) do
        local entity = GetClosestObjectOfType(
            playerCoords.x,
            playerCoords.y,
            playerCoords.z,
            scanRadius,
            model,
            false,
            false,
            false
        )

        if entity and entity ~= 0 and DoesEntityExist(entity) then
            addNearbyATM(candidates, entity, playerCoords, maxDistance)
        end
    end

    local closestEntity = nil
    local closestDistance = math.huge

    for entity, distance in pairs(candidates) do
        if distance < closestDistance then
            closestEntity = entity
            closestDistance = distance
        end
    end

    return closestEntity
end

function Detection.isPlayerCloseToATM()
    local closestATM = Detection.getClosestATM()
    if not closestATM then
        return false, nil, nil
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local entityCoords = GetEntityCoords(closestATM)
    local entityDistance = #(playerCoords - entityCoords)

    if entityDistance > Constants.Distances.ATM_REPLACE_RADIUS then
        return false, nil, nil
    end

    local bestPosition = entityCoords
    local bestDistance = entityDistance

    for _, offset in ipairs({ 0.4, 0.6, 0.8, 1.0 }) do
        local point = Detection.tryOffset(closestATM, offset)
        local distance = #(playerCoords - point)

        if distance < bestDistance then
            bestDistance = distance
            bestPosition = point
        end
    end

    return true, closestATM, bestPosition
end
