if Config.Interact and Config.Interact ~= 'standalone' then return end

local activeZones = {}
local activeThreads = {}

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
    local displayText = '[E] - ' .. cleanedText
    
    if lib and lib.zones and lib.zones.box then
        activeZones[zoneId] = lib.zones.box({
            coords = coords,
            size = size,
            rotation = rotation,
            debug = Config.Debug,
            onEnter = function()
                lib.showTextUI(displayText, {
                    position = Config.TextPosition,
                    icon = 'car',
                    style = {
                        borderRadius = 5,
                        backgroundColor = 'rgba(0, 0, 0, 0.8)',
                        color = 'white'
                    }
                })
            end,
            onExit = function()
                lib.hideTextUI()
            end,
            inside = function()
                if IsControlJustReleased(0, 38) then
                    callback()
                end
            end
        })
        return true
    else
        activeThreads[zoneId] = true
        CreateThread(function()
            while activeThreads[zoneId] do
                local ped = PlayerPedId()
                local pedCoords = GetEntityCoords(ped)
                local distance = #(pedCoords - coords)
                local sleep = 500
                
                if distance < 3.0 then
                    DefaultText3D(coords.x, coords.y, coords.z, displayText)
                    if IsControlJustReleased(0, 38) then
                        callback()
                    end
                    sleep = 0
                elseif distance < 15.0 then
                    sleep = 150
                end

                Wait(sleep)
            end
        end)
        return true
    end
end

function CreateShopInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)
    
    local coords = vector3(location.x, location.y, location.z)
    local cleanedText = cleanText(text)
    local displayText = '[E] - ' .. cleanedText
    
    if lib and lib.zones and lib.zones.box then
        activeZones[zoneId] = lib.zones.box({
            name = zoneId,
            coords = coords,
            size = vector3(2.5, 2.5, 3.0),
            rotation = location.w or 0,
            debug = Config.Debug,
            onEnter = function()
                lib.showTextUI(displayText, {
                    position = Config.TextPosition,
                    icon = 'fa-solid fa-shopping-cart',
                    style = {
                        borderRadius = 5,
                        backgroundColor = 'rgba(0, 0, 0, 0.8)',
                        color = 'white'
                    }
                })
            end,
            onExit = function()
                lib.hideTextUI()
            end,
            inside = function()
                DrawMarker(2, location.x, location.y, location.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 150, 255, 150, false, true, 2, false, nil, nil, false)
                
                if IsControlJustReleased(0, 38) then
                    callback()
                end
            end
        })
        return true
    else
        activeThreads[zoneId] = true
        CreateThread(function()
            while activeThreads[zoneId] do
                local ped = PlayerPedId()
                local pedCoords = GetEntityCoords(ped)
                local distance = #(pedCoords - coords)
                local sleep = 500
                
                if distance < 2.5 then
                    DefaultText3D(location.x, location.y, location.z + 1.0, displayText)
                    if IsControlJustReleased(0, 38) then
                        callback()
                    end
                    sleep = 0
                elseif distance < 15.0 then
                    sleep = 150
                end

                Wait(sleep)
            end
        end)
        return true
    end
end

function CreateEngineSwapInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)
    
    local coords = vector3(location.x, location.y, location.z)
    local cleanedText = cleanText(text)
    local displayText = '[E] - ' .. cleanedText
    
    if lib and lib.zones and lib.zones.box then
        activeZones[zoneId] = lib.zones.box({
            name = zoneId,
            coords = coords,
            size = vector3(1.5, 1.5, 2.0),
            rotation = location.w or 0,
            debug = Config.Debug,
            onEnter = function()
                lib.showTextUI(displayText, {
                    position = Config.TextPosition,
                    icon = 'fa-solid fa-laptop',
                    style = {
                        borderRadius = 5,
                        backgroundColor = 'rgba(0, 0, 0, 0.8)',
                        color = 'white'
                    }
                })
            end,
            onExit = function()
                lib.hideTextUI()
            end,
            inside = function()
                DrawMarker(2, location.x, location.y, location.z + 0.8, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25, 0, 200, 255, 150, false, true, 2, false, nil, nil, false)
                if IsControlJustReleased(0, 38) then
                    callback()
                end
            end
        })
        return true
    else
        activeThreads[zoneId] = true
        CreateThread(function()
            while activeThreads[zoneId] do
                local ped = PlayerPedId()
                local pedCoords = GetEntityCoords(ped)
                local distance = #(pedCoords - coords)
                local sleep = 500
                
                if distance < 2.0 then
                    DefaultText3D(location.x, location.y, location.z + 0.9, displayText)
                    if IsControlJustReleased(0, 38) then
                        callback()
                    end
                    sleep = 0
                elseif distance < 15.0 then
                    sleep = 150
                end

                Wait(sleep)
            end
        end)
        return true
    end
end

function CreateEngineHoistInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)
    
    local coords = vector3(location.x, location.y, location.z)
    local cleanedText = cleanText(text)
    local displayText = '[E] - ' .. cleanedText
    
    if lib and lib.zones and lib.zones.box then
        activeZones[zoneId] = lib.zones.box({
            name = zoneId,
            coords = coords,
            size = vector3(2.0, 2.0, 2.5),
            rotation = location.w or 0,
            debug = Config.Debug,
            onEnter = function()
                lib.showTextUI(displayText, {
                    position = Config.TextPosition,
                    icon = 'fa-solid fa-dolly',
                    style = {
                        borderRadius = 5,
                        backgroundColor = 'rgba(0, 0, 0, 0.8)',
                        color = 'white'
                    }
                })
            end,
            onExit = function()
                lib.hideTextUI()
            end,
            inside = function()
                DrawMarker(2, location.x, location.y, location.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 200, 0, 150, false, true, 2, false, nil, nil, false)
                if IsControlJustReleased(0, 38) then
                    callback()
                end
            end
        })
        return true
    else
        activeThreads[zoneId] = true
        CreateThread(function()
            while activeThreads[zoneId] do
                local ped = PlayerPedId()
                local pedCoords = GetEntityCoords(ped)
                local distance = #(pedCoords - coords)
                local sleep = 500
                
                if distance < 2.5 then
                    DefaultText3D(location.x, location.y, location.z + 1.0, displayText)
                    if IsControlJustReleased(0, 38) then
                        callback()
                    end
                    sleep = 0
                elseif distance < 15.0 then
                    sleep = 150
                end

                Wait(sleep)
            end
        end)
        return true
    end
end

function CreateStashInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)
    
    local coords = vector3(location.x, location.y, location.z)
    local cleanedText = cleanText(text)
    local displayText = '[E] - ' .. cleanedText
    
    if lib and lib.zones and lib.zones.box then
        activeZones[zoneId] = lib.zones.box({
            name = zoneId,
            coords = coords,
            size = vector3(2.5, 2.5, 3.0),
            rotation = location.w or 0,
            debug = Config.Debug,
            onEnter = function()
                lib.showTextUI(displayText, {
                    position = Config.TextPosition,
                    icon = 'fa-solid fa-box-archive',
                    style = {
                        borderRadius = 5,
                        backgroundColor = 'rgba(0, 0, 0, 0.8)',
                        color = 'white'
                    }
                })
            end,
            onExit = function()
                lib.hideTextUI()
            end,
            inside = function()
                DrawMarker(2, location.x, location.y, location.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 165, 0, 150, false, true, 2, false, nil, nil, false)
                
                if IsControlJustReleased(0, 38) then
                    callback()
                end
            end
        })
        return true
    else
        activeThreads[zoneId] = true
        CreateThread(function()
            while activeThreads[zoneId] do
                local ped = PlayerPedId()
                local pedCoords = GetEntityCoords(ped)
                local distance = #(pedCoords - coords)
                local sleep = 500
                
                if distance < 2.5 then
                    DefaultText3D(location.x, location.y, location.z + 1.0, displayText)
                    if IsControlJustReleased(0, 38) then
                        callback()
                    end
                    sleep = 0
                elseif distance < 15.0 then
                    sleep = 150
                end

                Wait(sleep)
            end
        end)
        return true
    end
end

function CreateGarageOpenInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)
    
    local coords = vector3(location.x, location.y, location.z)
    local rotation = tonumber(location.w) or location.heading or 0.0
    local cleanedText = cleanText(text)
    local displayText = '[E] - ' .. cleanedText
    
    if lib and lib.zones and lib.zones.box then
        activeZones[zoneId] = lib.zones.box({
            name = zoneId,
            coords = coords,
            size = vector3(3.0, 3.0, 3.0),
            rotation = rotation,
            debug = Config.Debug,
            onEnter = function()
                lib.showTextUI(displayText, {
                    position = Config.TextPosition,
                    icon = 'fa-solid fa-car',
                    style = {
                        borderRadius = 5,
                        backgroundColor = 'rgba(0, 0, 0, 0.8)',
                        color = 'white'
                    }
                })
            end,
            onExit = function()
                lib.hideTextUI()
            end,
            inside = function()
                DrawMarker(2, location.x, location.y, location.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 255, 0, 150, false, true, 2, false, nil, nil, false)
                
                if IsControlJustReleased(0, 38) then
                    callback()
                end
            end
        })
        return true
    else
        activeThreads[zoneId] = true
        CreateThread(function()
            while activeThreads[zoneId] do
                local ped = PlayerPedId()
                local pedCoords = GetEntityCoords(ped)
                local distance = #(pedCoords - coords)
                local sleep = 500
                
                if distance < 3.0 then
                    DefaultText3D(location.x, location.y, location.z + 1.0, displayText)
                    if IsControlJustReleased(0, 38) then
                        callback()
                    end
                    sleep = 0
                elseif distance < 15.0 then
                    sleep = 150
                end

                Wait(sleep)
            end
        end)
        return true
    end
end

function CreateGarageRemoveInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)
    
    local coords = vector3(location.x, location.y, location.z)
    local rotation = tonumber(location.w) or location.heading or 0.0
    local cleanedText = cleanText(text)
    local displayText = '[E] - ' .. cleanedText
    
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
                end
                
                if IsControlJustReleased(0, 38) then
                    if vehicle ~= 0 then
                        callback()
                    end
                end
            end
        })
        return true
    else
        activeThreads[zoneId] = true
        CreateThread(function()
            while activeThreads[zoneId] do
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
        return true
    end
end

function CreateWardrobeInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)

    local coords = vector3(location.x, location.y, location.z)
    local cleanedText = cleanText(text)
    local displayText = '[E] - ' .. cleanedText

    if lib and lib.zones and lib.zones.box then
        activeZones[zoneId] = lib.zones.box({
            name = zoneId,
            coords = coords,
            size = vector3(2.0, 2.0, 2.5),
            rotation = location.w or 0,
            debug = Config.Debug,
            onEnter = function()
                lib.showTextUI(displayText, {
                    position = Config.TextPosition,
                    icon = 'fa-solid fa-shirt',
                    style = {
                        borderRadius = 5,
                        backgroundColor = 'rgba(0, 0, 0, 0.8)',
                        color = 'white'
                    }
                })
            end,
            onExit = function()
                lib.hideTextUI()
            end,
            inside = function()
                DrawMarker(2, location.x, location.y, location.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 138, 43, 226, 150, false, true, 2, false, nil, nil, false)

                if IsControlJustReleased(0, 38) then
                    callback()
                end
            end
        })
        return true
    else
        activeThreads[zoneId] = true
        CreateThread(function()
            while activeThreads[zoneId] do
                local ped = PlayerPedId()
                local pedCoords = GetEntityCoords(ped)
                local distance = #(pedCoords - coords)
                local sleep = 500

                if distance < 2.5 then
                    DefaultText3D(location.x, location.y, location.z + 1.0, displayText)
                    if IsControlJustReleased(0, 38) then
                        callback()
                    end
                    sleep = 0
                elseif distance < 15.0 then
                    sleep = 150
                end

                Wait(sleep)
            end
        end)
        return true
    end
end

function RemoveInteract(zoneId)
    if activeZones[zoneId] then
        if activeZones[zoneId].remove then
            activeZones[zoneId]:remove()
        end
        activeZones[zoneId] = nil
    end

    if activeThreads[zoneId] then
        activeThreads[zoneId] = nil
    end
end

function CleanupAllInteracts()
    for zoneId, zone in pairs(activeZones) do
        if zone and zone.remove then
            zone:remove()
        end
    end
    activeZones = {}
    activeThreads = {}
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        CleanupAllInteracts()
    end
end)

