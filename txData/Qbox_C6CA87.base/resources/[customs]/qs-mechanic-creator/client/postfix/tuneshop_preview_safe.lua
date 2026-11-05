-- Preview mod + camera tuneshop: debounce NUI, normalizza indici, evita crash CEF

local PREVIEW_DEBOUNCE_MS = 80
local lastPreviewAt = 0
local previewBusy = false

local function normalizeModType(modType)
    if modType == nil then return modType end
    if type(modType) == 'number' then return modType end
    if type(modType) ~= 'string' then return modType end
    local n = tonumber(modType)
    if n ~= nil then return n end
    return modType
end

local function normalizeModIndex(modIndex)
    if modIndex == nil then return modIndex end
    if type(modIndex) == 'number' then return modIndex end
    if type(modIndex) ~= 'string' then return modIndex end
    if modIndex == 'true' then return true end
    if modIndex == 'false' then return false end
    if modIndex == 'stock' or modIndex == 'STOCK' or modIndex == '' then return -1 end
    return tonumber(modIndex) or modIndex
end

CreateThread(function()
    while type(ApplyVehicleModification) ~= 'function' do
        Wait(200)
    end

    local _apply = ApplyVehicleModification
    ApplyVehicleModification = function(vehicle, modType, modIndex)
        if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
            return false
        end
        modType = normalizeModType(modType)
        modIndex = normalizeModIndex(modIndex)
        local ok, result = pcall(_apply, vehicle, modType, modIndex)
        if ok then
            return result ~= false
        end
        if Config and Config.Debug then
            print(('^1[qs-mechanic-creator]^0 ApplyVehicleModification: %s'):format(tostring(result)))
        end
        return false
    end
end)

CreateThread(function()
    while GetResourceState(GetCurrentResourceName()) ~= 'started' do
        Wait(200)
    end
    Wait(1500)

    if type(TransitionCameraToEngine) == 'function' then
        local _engineCam = TransitionCameraToEngine
        TransitionCameraToEngine = function(vehicle)
            if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
            local ok, err = pcall(_engineCam, vehicle)
            if not ok and Config and Config.Debug then
                print(('^1[qs-mechanic-creator]^0 TransitionCameraToEngine: %s'):format(tostring(err)))
            end
            if not ok and type(TransitionCameraToDefault) == 'function' then
                pcall(TransitionCameraToDefault, vehicle)
            end
        end
    end

    if type(TransitionCameraToBrakes) == 'function' then
        local _brakesCam = TransitionCameraToBrakes
        TransitionCameraToBrakes = function(vehicle)
            if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
            local ok, err = pcall(_brakesCam, vehicle)
            if not ok and type(TransitionCameraToDefault) == 'function' then
                pcall(TransitionCameraToDefault, vehicle)
            end
        end
    end
end)

-- Debounce callback NUI previewModification (registrato in tunes.lua)
AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(2500)
        -- Il callback e' gia registrato; wrappiamo ApplyVehicleModification sopra.
        -- Debounce lato client: flag durante spam click NUI.
        previewBusy = false
        lastPreviewAt = 0
    end)
end)

exports('QsTuneshopPreviewBusy', function()
    return previewBusy
end)

exports('QsTuneshopTryPreview', function(vehicle, modType, modIndex)
    local now = GetGameTimer()
    if previewBusy or (now - lastPreviewAt) < PREVIEW_DEBOUNCE_MS then
        return false
    end
    previewBusy = true
    lastPreviewAt = now
    local ok = ApplyVehicleModification(vehicle, modType, modIndex)
    previewBusy = false
    return ok
end)
