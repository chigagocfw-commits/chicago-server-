if not Config.Framework or Config.Framework ~= 'qbox' then
    return
end

local QBCore = exports['qb-core']:GetCoreObject()
local cachedDutyStatus = nil
local dutyInitialized = false

function showClientNotification(data)
    if type(data) == "string" then
        data = {description = data, type = 'info'}
    end

    lib.notify({
        title = data.title or 'Notification',
        description = data.description or data.message or '',
        type = data.type or 'info',
        duration = data.duration or 5000
    })
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

local function syncDutyStatus()
    local newStatus = isPlayerOnDuty()
    if cachedDutyStatus ~= newStatus then
        cachedDutyStatus = newStatus
        TriggerEvent('qs-mechanic-creator:client:dutyChanged', newStatus)
    end
    return newStatus
end

local function initializeDuty()
    if dutyInitialized then return end
    dutyInitialized = true
    Wait(500)
    syncDutyStatus()
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    dutyInitialized = false
    cachedDutyStatus = nil
    TriggerEvent('qs-mechanic-creator:client:forceInitialize')
    CreateThread(function()
        initializeDuty()
    end)
end)

function hasDutySystem()
    return true
end

function isPlayerOnDuty()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData and PlayerData.job then
        return PlayerData.job.onduty or false
    end
    return true
end

function toggleDuty()
    TriggerServerEvent("QBCore:ToggleDuty")
    Wait(200)
    syncDutyStatus()
    return true
end

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    cachedDutyStatus = duty
    TriggerEvent('qs-mechanic-creator:client:dutyChanged', duty)
end)

CreateThread(function()
    Wait(2000)
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData and PlayerData.citizenid then
        TriggerEvent('qs-mechanic-creator:client:forceInitialize')
        initializeDuty()
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        if dutyInitialized then
            local currentStatus = isPlayerOnDuty()
            if cachedDutyStatus ~= currentStatus then
                cachedDutyStatus = currentStatus
                TriggerEvent('qs-mechanic-creator:client:dutyChanged', currentStatus)
            end
        end
    end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    if not JobInfo then return end

    if JobInfo.onduty ~= nil then
        cachedDutyStatus = JobInfo.onduty
        TriggerEvent('qs-mechanic-creator:client:dutyChanged', JobInfo.onduty)
    else
        CreateThread(function()
            Wait(200)
            syncDutyStatus()
        end)
    end

    lib.callback('qs-mechanic-creator:server:getPlayerLicense', false, function(license)
        if license then
            local jobData = {
                name = JobInfo.name,
                grade = JobInfo.grade.level or JobInfo.grade
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