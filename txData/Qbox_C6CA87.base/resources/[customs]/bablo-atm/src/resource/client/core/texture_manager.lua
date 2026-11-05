TextureManager = TextureManager or {}

if not Constants or not Detection or not DUI then
    error("Constants, Detection, and DUI modules must be loaded before TextureManager")
end

TextureManager.LoadedTextures = {}
TextureManager.IsUnloadingTextures = false
TextureManager.ActiveScanInterval = 250
TextureManager.IdleScanInterval = 1500

local function getInteractionPosition(entity, variant)
    local entityCoords = GetEntityCoords(entity)
    local forwardVector = GetEntityForwardVector(entity)

    return entityCoords + (forwardVector * variant.interactionSpotOffset), entityCoords
end

local function isWithinTextureDistance(position, playerCoords)
    return #(position - playerCoords) <= Constants.DUI.LOAD_TEXTURE_DISTANCE
end

local function buildCurrentVariant(variant)
    return {
        uiType = variant.uiType,
        txd = variant.hardwareTexture[1],
        tx = variant.softwareTexture[2],
        res = variant.res,
        variant = variant,
    }
end

local function waitForModelLoaded(model, variantId)
    local attempts = 0

    repeat
        Wait(0)
        attempts = attempts + 1

        if TextureManager.IsUnloadingTextures or HasModelLoaded(model) then
            break
        end
    until attempts >= 1000

    if attempts >= 1000 then
        Debug("Timeout loading ATM model for " .. tostring(variantId))
        return false
    end

    return true
end

function TextureManager.loadATMTextures()
    if not Config.EnableATMTextureReplace then
        return
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearbyVariants = {}

    for _, entity in ipairs(GetGamePool("CObject")) do
        local variantId = Detection.getVariantIDFromObject(entity)
        local variant = variantId and GetATMVariant(variantId)

        if variant then
            local interactionPosition, entityCoords = getInteractionPosition(entity, variant)

            if isWithinTextureDistance(interactionPosition, playerCoords) then
                nearbyVariants[variantId] = true

                if not TextureManager.LoadedTextures[variantId] then
                    TextureManager.LoadedTextures[variantId] = entityCoords

                    CreateThread(function()
                        if not waitForModelLoaded(variant.model, variantId) then
                            return
                        end

                        DUI.replaceTextureWithDUI(
                            variant.softwareTexture[1],
                            variant.softwareTexture[2],
                            "atm_software",
                            { type = variantId },
                            variant.softwareTexture[3]
                        )

                        Wait(100)
                    end)
                end
            end
        end
    end

    TextureManager.unloadDistantTextures(playerCoords, nearbyVariants)
end

function TextureManager.unloadDistantTextures(playerCoords, nearbyVariants)
    if TextureManager.IsUnloadingTextures then
        return
    end

    local staleTextures = {}

    for variantId, loadedCoords in pairs(TextureManager.LoadedTextures) do
        staleTextures[variantId] = loadedCoords
    end

    for variantId in pairs(nearbyVariants) do
        staleTextures[variantId] = nil
    end

    if next(staleTextures) == nil then
        return
    end

    TextureManager.IsUnloadingTextures = true

    CreateThread(function()
        for variantId, loadedCoords in pairs(staleTextures) do
            if #(loadedCoords - playerCoords) > Constants.DUI.LOAD_TEXTURE_DISTANCE then
                local variant = GetATMVariant(variantId)

                if variant then
                    DUI.unloadReplaceTexture(variant.hardwareTexture[1], variant.hardwareTexture[2], variantId)
                    DUI.unloadReplaceTexture(variant.softwareTexture[1], variant.softwareTexture[2], variantId .. "_software")
                    SetModelAsNoLongerNeeded(variant.model)
                    TextureManager.LoadedTextures[variantId] = nil
                end
            end
        end

        TextureManager.IsUnloadingTextures = false
    end)
end

function TextureManager.updateClosestATM()
    local closestATM = Detection.getClosestATM()

    if not closestATM then
        ATM:setCurrentATM(nil)
        ATM:setCurrentVariant(nil)
        return
    end

    ATM:setCurrentATM(closestATM)

    local variantId = Detection.getVariantIDFromObject(closestATM)
    local variant = variantId and GetATMVariant(variantId)

    if variant then
        ATM:setCurrentVariant(buildCurrentVariant(variant))
    end
end

CreateThread(function()
    while true do
        TextureManager.loadATMTextures()

        if ATM:isUsing() then
            TextureManager.updateClosestATM()
            Wait(TextureManager.ActiveScanInterval)
        else
            Wait(TextureManager.IdleScanInterval)
        end
    end
end)
