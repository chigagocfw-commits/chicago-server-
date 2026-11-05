if not Config.Interact or Config.Interact ~= 'qb-target' then return end

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
            type = "client",
            icon = "fas fa-car",
            label = cleanedText,
            action = callback
        }
    }
    
    exports['qb-target']:AddBoxZone(zoneId, coords, size.x, size.y, {
        name = zoneId,
        heading = rotation,
        debugPoly = Config.Debug,
        minZ = coords.z - (size.z / 2),
        maxZ = coords.z + (size.z / 2)
    }, {
        options = options,
        distance = 2.5
    })
    
    activeZones[zoneId] = true
    return true
end

function CreateShopInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)
    
    local cleanedText = cleanText(text)
    
    local options = {
        {
            type = "client",
            icon = "fas fa-shopping-cart",
            label = cleanedText,
            action = callback
        }
    }
    
    exports['qb-target']:AddBoxZone(zoneId, vector3(location.x, location.y, location.z), 2.5, 2.5, {
        name = zoneId,
        heading = location.w or 0,
        debugPoly = Config.Debug,
        minZ = location.z - 1.0,
        maxZ = location.z + 2.0
    }, {
        options = options,
        distance = 2.5
    })
    
    activeZones[zoneId] = true
    return true
end

function CreateEngineSwapInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)
    
    local cleanedText = cleanText(text)
    
    local options = {
        {
            type = "client",
            icon = "fas fa-laptop",
            label = cleanedText,
            action = callback
        }
    }
    
    exports['qb-target']:AddBoxZone(zoneId, vector3(location.x, location.y, location.z), 1.5, 1.5, {
        name = zoneId,
        heading = location.w or 0,
        debugPoly = Config.Debug,
        minZ = location.z - 0.8,
        maxZ = location.z + 1.5
    }, {
        options = options,
        distance = 2.0
    })
    
    activeZones[zoneId] = true
    return true
end

function CreateEngineHoistInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)
    
    local cleanedText = cleanText(text)
    
    local options = {
        {
            type = "client",
            icon = "fas fa-dolly",
            label = cleanedText,
            action = callback
        }
    }
    
    exports['qb-target']:AddBoxZone(zoneId, vector3(location.x, location.y, location.z), 2.0, 2.0, {
        name = zoneId,
        heading = location.w or 0,
        debugPoly = Config.Debug,
        minZ = location.z - 1.0,
        maxZ = location.z + 1.5
    }, {
        options = options,
        distance = 2.5
    })
    
    activeZones[zoneId] = true
    return true
end

function CreateStashInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)
    
    local cleanedText = cleanText(text)
    
    local options = {
        {
            type = "client",
            icon = "fas fa-box-archive",
            label = cleanedText,
            action = callback
        }
    }
    
    exports['qb-target']:AddBoxZone(zoneId, vector3(location.x, location.y, location.z), 2.5, 2.5, {
        name = zoneId,
        heading = location.w or 0,
        debugPoly = Config.Debug,
        minZ = location.z - 1.0,
        maxZ = location.z + 2.0
    }, {
        options = options,
        distance = 2.5
    })
    
    activeZones[zoneId] = true
    return true
end

function CreateGarageOpenInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)
    
    local cleanedText = cleanText(text)
    
    local options = {
        {
            type = "client",
            icon = "fas fa-car",
            label = cleanedText,
            action = callback
        }
    }
    
    local rotation = tonumber(location.w) or location.heading or 0.0
    
    exports['qb-target']:AddBoxZone(zoneId, vector3(location.x, location.y, location.z), 3.0, 3.0, {
        name = zoneId,
        heading = rotation,
        debugPoly = Config.Debug,
        minZ = location.z - 1.0,
        maxZ = location.z + 2.0
    }, {
        options = options,
        distance = 3.0
    })
    
    activeZones[zoneId] = true
    return true
end

function CreateGarageRemoveInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)

    local coords = vector3(location.x, location.y, location.z)
    local rotation = tonumber(location.w) or location.heading or 0.0
    local cleanedText = cleanText(text)
    local displayText = cleanedText

    if lib and lib.zones and lib.zones.box then
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
    else
        activeZones[zoneId] = 'thread_' .. zoneId
        CreateThread(function()
            while activeZones[zoneId] do
                local ped = PlayerPedId()
                local pedCoords = GetEntityCoords(ped)
                local vehicle = GetVehiclePedIsIn(ped, false)
                local distance = #(pedCoords - coords)
                local sleep = 500

                if distance < 4.0 and vehicle ~= 0 then
                    DefaultText3D(location.x, location.y, location.z + 1.0, displayText)
                    if IsControlJustReleased(0, 38) then
                        callback()
                    end
                    sleep = 0
                elseif distance < 20.0 then
                    sleep = 150
                end

                Wait(sleep)
            end
        end)
    end

    return true
end

function CreateWardrobeInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)

    local cleanedText = cleanText(text)

    local options = {
        {
            type = "client",
            icon = "fas fa-shirt",
            label = cleanedText,
            action = callback
        }
    }

    exports['qb-target']:AddBoxZone(zoneId, vector3(location.x, location.y, location.z), 2.0, 2.0, {
        name = zoneId,
        heading = location.w or 0,
        debugPoly = Config.Debug,
        minZ = location.z - 1.0,
        maxZ = location.z + 1.5
    }, {
        options = options,
        distance = 2.5
    })

    activeZones[zoneId] = true
    return true
end

function RemoveInteract(zoneId)
    if activeZones[zoneId] then
        if type(activeZones[zoneId]) == 'table' and activeZones[zoneId].remove then
            activeZones[zoneId]:remove()
        elseif type(activeZones[zoneId]) == 'boolean' or type(activeZones[zoneId]) == 'string' then
            pcall(function()
                exports['qb-target']:RemoveZone(zoneId)
            end)
        end
        activeZones[zoneId] = nil
    end
end

function CleanupAllInteracts()
    for zoneId, zone in pairs(activeZones) do
        if type(zone) == 'table' and zone.remove then
            zone:remove()
        elseif type(zone) == 'boolean' or type(zone) == 'string' then
            pcall(function()
                exports['qb-target']:RemoveZone(zoneId)
            end)
        end
    end
    activeZones = {}
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        CleanupAllInteracts()
    end
end)

