local activeLogos = {}
local LogoModule = {}

local function createSurfaceLogo(surfaceName, surfaceData, logoFile)
    local txdName = string.format("scoot_logo_%s_%d", surfaceName, GetGameTimer())
    local posX = surfaceData.x or 0.5
    local posY = surfaceData.y or 0.5
    local size = surfaceData.size or 0.7
    local turn = surfaceData.turn or 0

    local duiUrl = string.format(
        "nui://%s/web/logo.html?base=%s&logo=%s&x=%s&y=%s&size=%s&turn=%s",
        cache.resource,
        surfaceData.base,
        logoFile,
        posX,
        posY,
        size,
        turn
    )

    local duiObject = CreateDui(duiUrl, 1024, 1024)
    local timeout = GetGameTimer() + 10000

    while not IsDuiAvailable(duiObject) and GetGameTimer() < timeout do
        Wait(100)
    end

    if not IsDuiAvailable(duiObject) then
        print(string.format("[scootbunker] logo: %s page never loaded", surfaceName))
        DestroyDui(duiObject)
        return
    end

    Wait(600)

    local runtimeTxd = CreateRuntimeTxd(txdName)
    local ok, runtimeTexture = pcall(CreateRuntimeTextureFromDuiHandle, runtimeTxd, "logo", GetDuiHandle(duiObject))

    if not runtimeTxd or not ok or not runtimeTexture then
        print(string.format("[scootbunker] logo: %s texture failed (%s)", surfaceName, tostring(runtimeTexture)))
        DestroyDui(duiObject)
        return
    end

    activeLogos[surfaceName] = {
        dui = duiObject,
        txd = txdName,
        texture = surfaceData.texture
    }

    LogoModule.apply()
end

function LogoModule.apply()
    local logoConfig = ScootConfig.logo
    local dictionary = (logoConfig and logoConfig.dictionary) or ScootAssets.model

    for _, data in pairs(activeLogos) do
        AddReplaceTexture(dictionary, data.texture, data.txd, "logo")
    end
end

CreateThread(function()
    local logoConfig = ScootConfig.logo
    if not logoConfig or not logoConfig.enabled then
        return
    end

    local logoFile = logoConfig.file or "logo/logo.png"
    local fileContent = LoadResourceFile(cache.resource, logoFile)

    if fileContent == nil then
        if ScootConfig.debug then
            print(string.format("[scootbunker] logo: no %s, keeping the artwork that ships with the model", logoFile))
        end
        return
    end

    Wait(1500)

    local surfaces = logoConfig.surfaces or {}
    for surfaceName, surfaceData in pairs(surfaces) do
        createSurfaceLogo(surfaceName, surfaceData, logoFile)
    end

    if ScootConfig.debug then
        local loadedList = {}
        for surfaceName in pairs(activeLogos) do
            loadedList[#loadedList + 1] = surfaceName
        end
        print(string.format("[scootbunker] logo %s on: %s", logoFile, table.concat(loadedList, ", ")))
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= cache.resource then
        return
    end

    local logoConfig = ScootConfig.logo
    local dictionary = (logoConfig and logoConfig.dictionary) or ScootAssets.model

    for _, data in pairs(activeLogos) do
        RemoveReplaceTexture(dictionary, data.texture)
        if data.dui then
            DestroyDui(data.dui)
        end
    end
end)

ScootLogo = LogoModule
