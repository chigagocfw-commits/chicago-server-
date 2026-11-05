if not Config.Interact or Config.Interact ~= 'qs-textui' then return end

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
    
    activeThreads[zoneId] = true
    CreateThread(function()
        while activeThreads[zoneId] do
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            local distance = #(pedCoords - coords)
            local sleep = 500

            if distance < 3.0 then
                DrawText3D(coords.x, coords.y, coords.z, cleanedText, zoneId, 'E')
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
    
    activeZones[zoneId] = true
    return true
end

function CreateShopInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)
    
    local cleanedText = cleanText(text)
    
    activeThreads[zoneId] = true
    CreateThread(function()
        while activeThreads[zoneId] do
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            local distance = #(pedCoords - vector3(location.x, location.y, location.z))
            local sleep = 500

            if distance < 2.5 then
                DrawText3D(location.x, location.y, location.z + 1.0, cleanedText, zoneId, 'E')
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
    
    activeZones[zoneId] = true
    return true
end

function CreateEngineSwapInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)
    
    local cleanedText = cleanText(text)
    
    activeThreads[zoneId] = true
    CreateThread(function()
        while activeThreads[zoneId] do
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            local distance = #(pedCoords - vector3(location.x, location.y, location.z))
            local sleep = 500

            if distance < 2.0 then
                DrawText3D(location.x, location.y, location.z + 0.9, cleanedText, zoneId, 'E')
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
    
    activeZones[zoneId] = true
    return true
end

function CreateEngineHoistInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)
    
    local cleanedText = cleanText(text)
    
    activeThreads[zoneId] = true
    CreateThread(function()
        while activeThreads[zoneId] do
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            local distance = #(pedCoords - vector3(location.x, location.y, location.z))
            local sleep = 500

            if distance < 2.5 then
                DrawText3D(location.x, location.y, location.z + 1.0, cleanedText, zoneId, 'E')
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
    
    activeZones[zoneId] = true
    return true
end

function CreateStashInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)
    
    local cleanedText = cleanText(text)
    
    activeThreads[zoneId] = true
    CreateThread(function()
        while activeThreads[zoneId] do
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            local distance = #(pedCoords - vector3(location.x, location.y, location.z))
            local sleep = 500

            if distance < 2.5 then
                DrawText3D(location.x, location.y, location.z + 1.0, cleanedText, zoneId, 'E')
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
    
    activeZones[zoneId] = true
    return true
end

function CreateGarageOpenInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)
    
    local cleanedText = cleanText(text)
    
    activeThreads[zoneId] = true
    CreateThread(function()
        while activeThreads[zoneId] do
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            local distance = #(pedCoords - vector3(location.x, location.y, location.z))
            local sleep = 500

            if distance < 3.0 then
                DrawText3D(location.x, location.y, location.z + 1.0, cleanedText, zoneId, 'E')
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
    
    activeZones[zoneId] = true
    return true
end

function CreateGarageRemoveInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)
    
    local cleanedText = cleanText(text)
    
    activeThreads[zoneId] = true
    CreateThread(function()
        while activeThreads[zoneId] do
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            local vehicle = GetVehiclePedIsIn(ped, false)
            local distance = #(pedCoords - vector3(location.x, location.y, location.z))
            local sleep = 500

            if distance < 4.0 and vehicle ~= 0 then
                DrawText3D(location.x, location.y, location.z + 1.0, cleanedText, zoneId, 'E')
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
    
    activeZones[zoneId] = true
    return true
end

function CreateWardrobeInteract(zoneId, location, text, callback)
    RemoveInteract(zoneId)

    local cleanedText = cleanText(text)

    activeThreads[zoneId] = true
    CreateThread(function()
        while activeThreads[zoneId] do
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            local distance = #(pedCoords - vector3(location.x, location.y, location.z))
            local sleep = 500

            if distance < 2.5 then
                DrawText3D(location.x, location.y, location.z + 1.0, cleanedText, zoneId, 'E')
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

    activeZones[zoneId] = true
    return true
end

function RemoveInteract(zoneId)
    if activeThreads[zoneId] then
        activeThreads[zoneId] = nil
    end

    if activeZones[zoneId] then
        activeZones[zoneId] = nil
    end
end

function CleanupAllInteracts()
    activeZones = {}
    activeThreads = {}
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        CleanupAllInteracts()
    end
end)

