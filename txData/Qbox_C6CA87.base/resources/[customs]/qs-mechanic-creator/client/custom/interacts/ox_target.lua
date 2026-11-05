if not Config.Interact or Config.Interact ~= 'ox_target' then return end

local activeZones = {}

local function cleanText(text)
    if not text then return "" end
    text = text:gsub("^%[E%]%s*%-%s*", "")
    text = text:gsub("^%[E%]%s*", "")
    text = text:gsub("^Press%s*%[E%]%s*%-%s*", "")
    text = text:gsub("^Press%s*%[E%]%s*to%s*", "")
    text = text:gsub("^Press%s*%[E%]%s*", "")
    text = text:gsub("^Press E%s*%-%s*", "")
    text = text:gsub("^Press E to%s*", "")
    text = text:gsub("^Press E%s*", "")
    return text
end

function CreateCarliftInteract(zoneId, coords, size, rotation, text, callback)
    RemoveInteract(zoneId)

    local cleanedText = cleanText(text)

    local options = {
        {
            name = zoneId,
            icon = 'fa-solid fa-car',
            label = cleanedText,
            onSelect = callback
        }
    }

    local zoneResult = exports.ox_target:addBoxZone({
        coords = coords,
        size = size,
        rotation = rotation,
        debug = Config.Debug,
        options = options
    })

    if zoneResult then
        activeZones[zoneId] = zoneResult
        return true
    else
        print("[ox_target] Failed to create carlift zone:", zoneId)
        return false
    end
end

function CreateShopInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)

    local cleanedText = cleanText(text)

    local options = {
        {
            name = zoneId,
            icon = 'fa-solid fa-shopping-cart',
            label = cleanedText,
            onSelect = callback
        }
    }

    local zoneResult = exports.ox_target:addBoxZone({
        coords = vector3(location.x, location.y, location.z),
        size = vector3(2.5, 2.5, 3.0),
        rotation = location.w or 0,
        debug = Config.Debug,
        options = options
    })

    if zoneResult then
        activeZones[zoneId] = zoneResult
        return true
    else
        print("[ox_target] Failed to create shop zone:", zoneId)
        return false
    end
end

function CreateEngineSwapInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)

    local cleanedText = cleanText(text)

    local options = {
        {
            name = zoneId,
            icon = 'fa-solid fa-laptop',
            label = cleanedText,
            onSelect = callback
        }
    }

    local zoneResult = exports.ox_target:addBoxZone({
        coords = vector3(location.x, location.y, location.z),
        size = vector3(1.5, 1.5, 2.0),
        rotation = location.w or 0,
        debug = Config.Debug,
        options = options
    })

    if zoneResult then
        activeZones[zoneId] = zoneResult
        return true
    else
        print("[ox_target] Failed to create engine swap zone:", zoneId)
        return false
    end
end

function CreateEngineHoistInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)

    local cleanedText = cleanText(text)

    local options = {
        {
            name = zoneId,
            icon = 'fa-solid fa-dolly',
            label = cleanedText,
            onSelect = callback
        }
    }

    local zoneResult = exports.ox_target:addBoxZone({
        coords = vector3(location.x, location.y, location.z),
        size = vector3(2.0, 2.0, 2.5),
        rotation = location.w or 0,
        debug = Config.Debug,
        options = options
    })

    if zoneResult then
        activeZones[zoneId] = zoneResult
        return true
    else
        print("[ox_target] Failed to create zone:", zoneId, "at", location.x, location.y, location.z)
        return false
    end
end

function CreateStashInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)

    local cleanedText = cleanText(text)

    local options = {
        {
            name = zoneId,
            icon = 'fa-solid fa-box-archive',
            label = cleanedText,
            onSelect = callback
        }
    }

    local zoneResult = exports.ox_target:addBoxZone({
        coords = vector3(location.x, location.y, location.z),
        size = vector3(2.5, 2.5, 3.0),
        rotation = location.w or 0,
        debug = Config.Debug,
        options = options
    })

    if zoneResult then
        activeZones[zoneId] = zoneResult
        return true
    else
        print("[ox_target] Failed to create stash zone:", zoneId)
        return false
    end
end

function CreateGarageOpenInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)

    local cleanedText = cleanText(text)

    local options = {
        {
            name = zoneId,
            icon = 'fa-solid fa-car',
            label = cleanedText,
            onSelect = callback
        }
    }

    local rotation = tonumber(location.w) or location.heading or 0.0

    local zoneResult = exports.ox_target:addBoxZone({
        coords = vector3(location.x, location.y, location.z),
        size = vector3(3.0, 3.0, 3.0),
        rotation = rotation,
        debug = Config.Debug,
        options = options
    })

    if zoneResult then
        activeZones[zoneId] = zoneResult
        return true
    else
        print("[ox_target] Failed to create garage open zone:", zoneId)
        return false
    end
end

function CreateGarageRemoveInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)

    local coords = vector3(location.x, location.y, location.z)
    local rotation = tonumber(location.w) or location.heading or 0.0
    local cleanedText = cleanText(text)
    local displayText = cleanedText

    activeZones[zoneId] = lib.zones.box({
        name = zoneId,
        coords = coords,
        size = vector3(4.0, 4.0, 3.0),
        rotation = rotation,
        debug = Config.Debug,
        onEnter = function()
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle ~= 0 then
                lib.showTextUI(displayText, {
                    position = Config.TextPosition,
                    icon = 'fa-solid fa-warehouse',
                    style = {
                        borderRadius = 5,
                        backgroundColor = 'rgba(0, 0, 0, 0.8)',
                        color = 'white'
                    }
                })
            end
        end,
        onExit = function()
            lib.hideTextUI()
        end,
        inside = function()
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)

            if vehicle ~= 0 then
                DrawMarker(2, location.x, location.y, location.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 0, 0, 150, false, true, 2, false, nil, nil, false)

                if IsControlJustReleased(0, 38) then
                    callback()
                end
            end
        end
    })

    return true
end

function CreateWardrobeInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)

    local cleanedText = cleanText(text)

    local options = {
        {
            name = zoneId,
            icon = 'fa-solid fa-shirt',
            label = cleanedText,
            onSelect = callback
        }
    }

    local zoneResult = exports.ox_target:addBoxZone({
        coords = vector3(location.x, location.y, location.z),
        size = vector3(2.0, 2.0, 2.5),
        rotation = location.w or 0,
        debug = Config.Debug,
        options = options
    })

    if zoneResult then
        activeZones[zoneId] = zoneResult
        return true
    else
        print("[ox_target] Failed to create wardrobe zone:", zoneId)
        return false
    end
end

function RemoveInteract(zoneId)
    if activeZones[zoneId] then
        if type(activeZones[zoneId]) == 'table' and activeZones[zoneId].remove then
            activeZones[zoneId]:remove()
        elseif type(activeZones[zoneId]) == 'number' then
            exports.ox_target:removeZone(activeZones[zoneId])
        end
        activeZones[zoneId] = nil
    end
end

function CleanupAllInteracts()
    for zoneId, zone in pairs(activeZones) do
        if type(zone) == 'table' and zone.remove then
            zone:remove()
        elseif type(zone) == 'number' then
            exports.ox_target:removeZone(zone)
        end
    end
    activeZones = {}
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        CleanupAllInteracts()
    end
end)

