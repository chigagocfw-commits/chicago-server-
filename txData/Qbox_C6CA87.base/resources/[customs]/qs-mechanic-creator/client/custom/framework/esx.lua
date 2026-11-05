if not Config.Framework or Config.Framework ~= 'esx' then 
    return 
end

local ESX = exports['es_extended']:getSharedObject()

function showClientNotification(data)
    if type(data) == "string" then
        data = {description = data}
    end
    
    if ESX.ShowNotification then
        ESX.ShowNotification(data.description or data.message or 'Notification', data.type or 'info', data.duration or 5000)
    elseif ESX.showNotification then
        ESX.showNotification(data.description or data.message or 'Notification', data.type or 'info', data.duration or 5000)
    else
        lib.notify({
            title = data.title or 'Notification',
            description = data.description or data.message or 'Notification',
            type = data.type or 'info',
            duration = data.duration or 5000
        })
    end
end

function fixVehicleDeformation(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    -- Save vehicle properties (mods, colors, etc.) before SetVehicleFixed strips them
    local success, props = pcall(lib.getVehicleProperties, vehicle)
    if not success then props = nil end

    SetVehicleDeformationFixed(vehicle)
    SetVehicleFixed(vehicle)

    -- Restore vehicle properties to preserve mods that SetVehicleFixed removed
    if props then
        -- Override health to repaired state since we just fixed the vehicle
        if props.bodyHealth then props.bodyHealth = 1000.0 end
        if props.engineHealth then props.engineHealth = 1000.0 end
        if props.tankHealth then props.tankHealth = 1000.0 end
        if props.petrolTankHealth then props.petrolTankHealth = 1000.0 end

        -- Clear door and window damage so they aren't re-applied from saved props
        props.doors = nil
        props.windows = nil
        props.tyres = nil

        Wait(0)
        pcall(lib.setVehicleProperties, vehicle, props)
    end

    -- Explicitly fix all doors (0=front-left, 1=front-right, 2=back-left, 3=back-right, 4=hood, 5=trunk)
    for i = 0, 5 do
        SetVehicleDoorShut(vehicle, i, false)
    end

    -- Fix all windows
    for i = 0, 7 do
        FixVehicleWindow(vehicle, i)
    end

    if GetResourceState('VehicleDeformation') == 'started' then
        TriggerServerEvent('VehicleDeformation:fix_sv', NetworkGetNetworkIdFromEntity(vehicle))
    end
end

function refuelVehicle(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    local fuelResource = 'LegacyFuel'
    if GetResourceState('ox_fuel') == 'started' then
        fuelResource = 'ox_fuel'
    elseif GetResourceState('ps-fuel') == 'started' then
        fuelResource = 'ps-fuel'
    elseif GetResourceState('cdn-fuel') == 'started' then
        fuelResource = 'cdn-fuel'
    elseif GetResourceState('qs-fuelstations') == 'started' then
        fuelResource = 'qs-fuelstations'
    elseif GetResourceState('frfuel') == 'started' then
        fuelResource = 'frfuel'
    elseif GetResourceState('ti_fuel') == 'started' then
        fuelResource = 'ti_fuel'
    end
    local success = pcall(function()
        exports[fuelResource]:SetFuel(vehicle, 100)
    end)
    if not success then
        SetVehicleFuelLevel(vehicle, 100.0)
    end
end

RegisterNetEvent('qs-mechanic-creator:client:showNotification', function(data)
    showClientNotification(data)
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    TriggerEvent('qs-mechanic-creator:client:forceInitialize')
    
    CreateThread(function()
        Wait(1000)
        
        local playerData = ESX.GetPlayerData()
        if playerData and playerData.job then
            local jobData = {
                name = playerData.job.name,
                grade = playerData.job.grade
            }
            local license = playerData.identifier
            
            if jobData.name and license then
                setPlayerData(jobData, license)
                
                TriggerEvent('qs-mechanic-creator:client:updatePlayerData', {
                    job = jobData,
                    license = license
                })
            end
        end
        
        TriggerServerEvent('qs-mechanic-creator:server:requestPlayerData')
    end)
end)

RegisterNetEvent('esx:setJob', function(job)
    if not job then return end

    lib.callback('qs-mechanic-creator:server:getPlayerLicense', false, function(license)
        if license then
            local jobData = {
                name = job.name,
                grade = job.grade
            }

            setPlayerData(jobData, license)

            TriggerEvent('qs-mechanic-creator:client:updatePlayerData', {
                job = jobData,
                license = license
            })

            TriggerEvent('qs-mechanic-creator:client:jobChanged')
        end
    end)
end)

function hasDutySystem()
    return false
end

function isPlayerOnDuty()
    return true
end

function toggleDuty()
    return false
end

RegisterNetEvent('qs-mechanic-creator:client:fixEverything', function()
    lib.callback('qs-mechanic-creator:server:hasAdminPermission', false, function(hasPermission)
        if not hasPermission then return end
        local vehicle = GetVehiclePedIsUsing(PlayerPedId())
        if vehicle == 0 then
            vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        end
        if vehicle == 0 then return end
        SetVehicleUndriveable(vehicle, false)
        WashDecalsFromVehicle(vehicle, 1.0)
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehiclePetrolTankHealth(vehicle, 1000.0)
        SetVehicleDirtLevel(vehicle, 0.0)
        fixVehicleDeformation(vehicle)
        for i = 0, 5 do
            SetVehicleTyreFixed(vehicle, i)
        end
        for i = 0, 7 do
            FixVehicleWindow(vehicle, i)
        end
        refuelVehicle(vehicle)
        showClientNotification({
            title = 'Vehicle Repaired',
            description = 'Your vehicle has been fully repaired',
            type = 'success'
        })
    end)
end)