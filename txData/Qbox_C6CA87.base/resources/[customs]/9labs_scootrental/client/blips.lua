local activeBlips = {}
local BlipModule = {}

local function parseBlipSettings(stationData)
    local globalConfig = ScootConfig.blips or {}
    local stationBlip = stationData.blip or {}

    local isEnabled = stationBlip.enabled
    if isEnabled == nil then
        isEnabled = globalConfig.enabled
    end

    if isEnabled == false then
        return nil
    end

    local sprite = math.floor(tonumber(stationBlip.sprite) or globalConfig.sprite or 1)
    local color = math.floor(tonumber(stationBlip.color) or globalConfig.color or 3)
    local scale = math.max(0.1, math.min(2.0, tonumber(stationBlip.scale) or globalConfig.scale or 0.75))

    local isShortRange = stationBlip.shortRange
    if isShortRange == nil then
        isShortRange = globalConfig.shortRange
    end

    local isFlashing = stationBlip.flash
    if isFlashing == nil then
        isFlashing = globalConfig.flash
    end

    local flashInterval = math.max(100, math.floor(tonumber(stationBlip.flashInterval) or globalConfig.flashInterval or 500))

    local label = stationBlip.label
    if not label or label == "" then
        label = stationData.name or globalConfig.label or "SCOOT"
    end

    return {
        sprite = sprite,
        color = color,
        scale = scale,
        shortRange = isShortRange,
        flash = isFlashing,
        flashInterval = flashInterval,
        label = label
    }
end

function BlipModule.remove(stationId)
    local blipHandle = activeBlips[stationId]
    if blipHandle and DoesBlipExist(blipHandle) then
        RemoveBlip(blipHandle)
    end
    activeBlips[stationId] = nil
end

function BlipModule.set(stationId, stationData)
    BlipModule.remove(stationId)

    local settings = parseBlipSettings(stationData)
    if not settings then
        return
    end

    local coords = stationData.coords
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(blip, settings.sprite)
    SetBlipColour(blip, settings.color)
    SetBlipScale(blip, settings.scale + 0.0)
    SetBlipAsShortRange(blip, settings.shortRange == true)
    SetBlipFlashes(blip, settings.flash == true)

    if settings.flash then
        SetBlipFlashInterval(blip, settings.flashInterval)
    end

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(settings.label)
    EndTextCommandSetBlipName(blip)

    activeBlips[stationId] = blip
end

function BlipModule.refresh(stations)
    for stationId in pairs(activeBlips) do
        if not stations[stationId] then
            BlipModule.remove(stationId)
        end
    end

    for stationId, stationData in pairs(stations) do
        BlipModule.set(stationId, stationData)
    end
end

function BlipModule.clear()
    for stationId in pairs(activeBlips) do
        BlipModule.remove(stationId)
    end
end

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == cache.resource then
        BlipModule.clear()
    end
end)

ScootBlips = BlipModule
