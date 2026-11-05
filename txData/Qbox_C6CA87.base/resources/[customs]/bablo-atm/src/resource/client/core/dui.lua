DUI = DUI or {}

if not Constants then
    error("Constants module must be loaded before DUI")
end

DUI.TextureDicts = {}
DUI.Objects = {}
DUI.TextureDictsMade = 0
DUI.LoadedTextures = {}
DUI.IsUnloadingTextures = false
DUI.URLPaths = {
    default = "/src/resource/software/index.html",
    fleeca = "/src/resource/client/assets/fleeca/index.html",
    atm_software = "/src/resource/software/index.html",
}

function DUI.buildDUIURL(duiType, data)
    local resourceName = GetCurrentResourceName()
    local baseUrl = "https://cfx-nui-" .. resourceName
    local path = DUI.URLPaths[duiType] or DUI.URLPaths.default

    if duiType == "atm_software" then
        local atmType = (data and data.type) or "one"
        return baseUrl .. path .. "?type=" .. atmType
    end

    return baseUrl .. path
end

function DUI.createDUI(duiType, data, resolution)
    if not duiType or not resolution then
        Error("DUI.createDUI: Missing required parameters (duiType or resolution)")
        return nil, nil
    end

    if type(resolution) ~= "table" or not resolution[1] or not resolution[2] then
        Error("DUI.createDUI: Invalid resolution format. Expected table with [width, height]")
        return nil, nil
    end

    local url = DUI.buildDUIURL(duiType, data)
    local width = resolution[1]
    local height = resolution[2]

    Debug(("Creating DUI: type=%s, url=%s, size=%sx%s"):format(tostring(duiType), url, width, height))

    local duiObject = CreateDui(url, width, height)
    if not duiObject then
        Error("Failed to create DUI handle for type: " .. tostring(duiType))
        return nil, nil
    end

    return duiObject, duiObject
end

local function ensureRuntimeTextureDict(duiId)
    if DUI.TextureDicts[duiId] then
        return DUI.TextureDicts[duiId]
    end

    local runtimeName = duiId .. DUI.TextureDictsMade
    DUI.TextureDicts[duiId] = {
        name = runtimeName,
        dict = CreateRuntimeTxd(runtimeName),
    }
    DUI.TextureDictsMade = DUI.TextureDictsMade + 1

    local attempts = 0
    repeat
        Wait(0)
        attempts = attempts + 1

        if HasStreamedTextureDictLoaded(runtimeName) then
            break
        end
    until attempts >= 1000

    return DUI.TextureDicts[duiId]
end

local function pushLocaleToDUI(duiHandle)
    Wait(200)

    if not IsDuiAvailable(duiHandle) then
        return
    end

    SendDuiMessage(duiHandle, json.encode({
        action = "ui:setLocale",
        data = {
            locale = "en-US",
            currency = (Config and Config.Currency) or "USD",
            currencySymbol = Config and Config.CurrencySymbol or nil,
            dict = Locales or {},
        }
    }))
end

local function loadThemeCss()
    local resourceName = GetCurrentResourceName()
    local candidates = {
        "src/resource/software/colors.css",
        "colors.css",
        "./src/resource/software/colors.css",
    }

    for _, path in ipairs(candidates) do
        local css = LoadResourceFile(resourceName, path)
        if css and css ~= "" then
            Debug(("[bablo-atm] loaded colors.css from '%s' (%d bytes)"):format(path, #css))
            return css
        end
    end

    Debug("[bablo-atm] could not load colors.css from any candidate path")
    return nil
end

local function pushThemeToDUI(duiHandle)
    Wait(200)

    if not IsDuiAvailable(duiHandle) then
        return
    end

    local css = loadThemeCss()
    if not css then
        return
    end

    SendDuiMessage(duiHandle, json.encode({
        action = "theme:setColors",
        data = {
            css = css,
        }
    }))
end

function DUI.replaceTextureWithDUI(originalTxd, originalTxn, duiType, data, resolution)
    local duiObject, duiHandle = DUI.createDUI(duiType, data, resolution)
    if not duiObject or not duiHandle then
        return
    end

    local duiId = (data and data.type and (data.type .. "_software")) or duiType

    CreateThread(function()
        local runtimeTexture = ensureRuntimeTextureDict(duiId)

        Wait(250)

        local texture = CreateRuntimeTextureFromDuiHandle(
            runtimeTexture.dict,
            duiId,
            GetDuiHandle(duiHandle)
        )

        if texture then
            AddReplaceTexture(originalTxd, originalTxn, runtimeTexture.name, duiId)
        end

        CreateThread(function()
            pushLocaleToDUI(duiHandle)
        end)

        CreateThread(function()
            pushThemeToDUI(duiHandle)
        end)
    end)

    DUI.Objects[duiId] = duiObject
end

ReplaceTextureWithDUI = DUI.replaceTextureWithDUI

function DUI.getDUIObject(duiId)
    return DUI.Objects[duiId]
end

function DUI.unloadReplaceTexture(originalTxd, originalTxn, duiId)
    local duiObject = DUI.Objects[duiId]
    if not duiObject then
        return
    end

    CreateThread(function()
        if IsDuiAvailable(duiObject) then
            DestroyDui(duiObject)
        end

        RemoveReplaceTexture(originalTxd, originalTxn)
        SetStreamedTextureDictAsNoLongerNeeded(originalTxd)

        local runtimeTexture = DUI.TextureDicts[duiId]
        if runtimeTexture then
            RemoveReplaceTexture(runtimeTexture.name, duiId)
            SetStreamedTextureDictAsNoLongerNeeded(runtimeTexture.name)
        end

        DUI.Objects[duiId] = nil
        DUI.TextureDicts[duiId] = nil
    end)
end

function DUI.setCurrentATMDUI()
    local closestATM = Detection.getClosestATM()
    if not closestATM then
        Debug("SetCurrentATMDui: No ATM found")
        return false
    end

    local variantId = Detection.getVariantIDFromObject(closestATM)
    if not variantId then
        Debug("SetCurrentATMDui: Could not determine ATM variant ID")
        return false
    end

    local duiId = variantId .. "_software"
    local duiObject = DUI.Objects[duiId]
    if not duiObject then
        Debug("SetCurrentATMDui: No DUI handle found for " .. duiId)
        return false
    end

    Debug("SetCurrentATMDui: Found DUI handle for " .. variantId)
    return duiObject
end

function DUI.sendMessage(message)
    local duiObject = ATM:getCurrentDUI()
    if not duiObject or not IsDuiAvailable(duiObject) then
        return
    end

    SendDuiMessage(duiObject, json.encode({
        action = message.action,
        data = message.data,
    }))
end

function DUI.clearAllReplaceTextures()
    for _, variant in pairs(GetAllATMVariants()) do
        if variant.hardwareTexture then
            RemoveReplaceTexture(variant.hardwareTexture[1], variant.hardwareTexture[2])
        end

        if variant.softwareTexture then
            RemoveReplaceTexture(variant.softwareTexture[1], variant.softwareTexture[2])
        end
    end
end
