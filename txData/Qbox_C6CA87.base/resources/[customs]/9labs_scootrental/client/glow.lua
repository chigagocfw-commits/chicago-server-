local txdName = string.format("scoot_glow_%d", GetGameTimer())
local appliedTextures = {}
local duiObject = nil
local isTextureReady = false
local currentActiveColor = nil
local defaultGlowColor = nil

local GlowModule = {}

function GlowModule.apply()
    if not isTextureReady then
        return
    end

    local glowConfig = ScootConfig.glow
    local dictionary = (glowConfig and glowConfig.dictionary) or ScootAssets.model
    local targetTextures = (glowConfig and glowConfig.textures) or {}

    appliedTextures = {}

    for _, textureName in ipairs(targetTextures) do
        AddReplaceTexture(dictionary, textureName, txdName, "glow")
        appliedTextures[#appliedTextures + 1] = { dictionary, textureName }
    end
end

CreateThread(function()
    local glowConfig = ScootConfig.glow
    if not glowConfig or not glowConfig.enabled then
        return
    end

    defaultGlowColor = ScootColor(glowConfig.color)
    if not defaultGlowColor then
        print(string.format("[scootbunker] glow.color is not a usable colour: %s", tostring(glowConfig.color)))
        return
    end

    Wait(1500)

    local hexWithoutHash = defaultGlowColor:sub(2)
    local nuiUrl = string.format("nui://%s/web/glow.html?c=%s", cache.resource, hexWithoutHash)
    duiObject = CreateDui(nuiUrl, 32, 32)

    local timeout = GetGameTimer() + 10000
    while not IsDuiAvailable(duiObject) and GetGameTimer() < timeout do
        Wait(100)
    end

    if not IsDuiAvailable(duiObject) then
        print("[scootbunker] glow: DUI never became available, strip colour not applied")
        return
    end

    local duiHandle = GetDuiHandle(duiObject)
    local runtimeTxd = CreateRuntimeTxd(txdName)

    if not runtimeTxd then
        print(string.format("[scootbunker] glow: could not create runtime txd %s", txdName))
        return
    end

    local ok, runtimeTexture = pcall(CreateRuntimeTextureFromDuiHandle, runtimeTxd, "glow", duiHandle)
    if not ok or not runtimeTexture then
        print(string.format("[scootbunker] glow: runtime texture failed (%s)", tostring(runtimeTexture)))
        return
    end

    isTextureReady = true
    GlowModule.apply()
    currentActiveColor = defaultGlowColor

    if ScootConfig.debug then
        local dict = glowConfig.dictionary or ScootAssets.model
        local texList = table.concat(glowConfig.textures or {}, ", ")
        print(string.format("[scootbunker] glow %s over %s: %s", defaultGlowColor, dict, texList))
    end

    if not glowConfig.perStation then
        return
    end

    while true do
        Wait(400)
        local playerCoords = GetEntityCoords(cache.ped)
        local nearestColor = nil
        local nearestDistance = nil

        for _, station in pairs(ScootBunker.list) do
            local dist = #(playerCoords - station.coords)
            if station.color and (not nearestDistance or dist < nearestDistance) then
                nearestDistance = dist
                nearestColor = station.color
            end
        end

        local targetHex = ScootColor(nearestColor) or defaultGlowColor
        if targetHex ~= currentActiveColor then
            currentActiveColor = targetHex
            SendDuiMessage(duiObject, json.encode({
                color = targetHex:sub(2)
            }))
            GlowModule.apply()
        end
    end
end)

RegisterCommand("scootglow", function(_, args)
    local targetTexture = args[1]
    local glowConfig = ScootConfig.glow
    local dictionary = (glowConfig and glowConfig.dictionary) or ScootAssets.model

    if not isTextureReady then
        print("[scootbunker] glow: texture not ready (glow.enabled false, or colour is not a #rrggbb hex)")
        return
    end

    if not targetTexture then
        print("[scootbunker] usage: /scootglow scoot_trim | scoot_top | scoot_door | scoot_around | scoot_roofpanel | scoot_metal")
        return
    end

    AddReplaceTexture(dictionary, targetTexture, txdName, "glow")
    appliedTextures[#appliedTextures + 1] = { dictionary, targetTexture }
    print(string.format("[scootbunker] painted %s/%s - if the strip changed, put that name in Config.glow.textures", dictionary, targetTexture))
end, false)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= cache.resource then
        return
    end

    for _, entry in ipairs(appliedTextures) do
        RemoveReplaceTexture(entry[1], entry[2])
    end

    if duiObject then
        DestroyDui(duiObject)
    end
end)

ScootGlow = GlowModule
