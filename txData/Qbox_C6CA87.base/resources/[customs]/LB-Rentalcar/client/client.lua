--[[
░▒▓████████▓▒░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░   ░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓███████▓▒░  
                                                                         
 This File Leaked By TC HUB Team, Join Our Server For More
 DISCORD: - https://discord.gg/tndFR89Sye - https://t.me/+RgDxwPX3L7w2ODBk - https://tchub.st/
--]]

local QBCore = exports['qb-core']:GetCoreObject()

local spawnedNPCs = {}
local spawnedBlips = {}
local rentedVehicle = nil
local rentalData = nil
local pendingReturn = nil
local promptShown = false
local menuOpen = false

local function SendCustomNotify(title, text, ntype)
    SendNUIMessage({
        type = 'notify',
        title = title,
        text = text,
        type = ntype
    })
end

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Citizen.Wait(1000)
        SendCustomNotify('LB Rental Loaded', 'Rental system is ready!', 'success')
    end
end)

local function SetPrompt(show)
    if promptShown == show then return end
    promptShown = show
    SendNUIMessage({
        type = 'interact',
        show = show,
        label = 'Open Rental Menu',
    })
end

local function CreateBlips()
    for i = 1, #Config.Locations do
        local loc = Config.Locations[i]
        local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(loc.name .. ' - ' .. Config.Blip.label)
        EndTextCommandSetBlipName(blip)
        spawnedBlips[i] = blip
    end
end

local function CreateNPCs()
    local model = GetHashKey(Config.NPC.model)
    if not HasModelLoaded(model) then
        RequestModel(model)
        local attempts = 0
        while not HasModelLoaded(model) and attempts < 300 do
            Wait(10)
            attempts = attempts + 1
        end
    end

    if not HasModelLoaded(model) then
        print(('^1[LB-Rental] Failed to load NPC model: %s^0'):format(Config.NPC.model))
        return
    end

    for i = 1, #Config.Locations do
        if not spawnedNPCs[i] or not DoesEntityExist(spawnedNPCs[i]) then
            local loc = Config.Locations[i]
            local npc = CreatePed(4, model, loc.coords.x, loc.coords.y, loc.coords.z - 1.0, loc.coords.w, false, true)
            if npc and npc ~= 0 then
                SetEntityHeading(npc, loc.coords.w)
                FreezeEntityPosition(npc, true)
                SetEntityInvincible(npc, true)
                SetBlockingOfNonTemporaryEvents(npc, true)
                SetEntityAsMissionEntity(npc, true, true)
                TaskStartScenarioInPlace(npc, Config.NPC.scenario, 0, true)
                spawnedNPCs[i] = npc
            end
        end
    end

    SetModelAsNoLongerNeeded(model)
end

local targetZones = {}

local function GetClosestRentalLocationDistance()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local closestDist = math.huge

    for i = 1, #Config.Locations do
        local loc = Config.Locations[i]
        local dist = #(playerCoords - vector3(loc.coords.x, loc.coords.y, loc.coords.z))
        if dist < closestDist then
            closestDist = dist
        end
    end

    return closestDist
end

local function CreateTargets()
    if not Config.UseTarget then return end
    local hasTarget = GetResourceState('qb-target') == 'started' or GetResourceState('ox_target') == 'started'
    if not hasTarget then
        print('^1[LB-Rental] Config.UseTarget is true but qb-target/ox_target not found^0')
        return
    end

    for i = 1, #Config.Locations do
        local loc = Config.Locations[i]
        local npcPos = vector3(loc.coords.x, loc.coords.y, loc.coords.z - 1.0)
        local options = {
            {
                type = 'client',
                event = 'lb-rental:client:openMenu',
                icon = 'fas fa-car',
                label = 'Open Rental Menu',
            },
        }

    if Config.UseTarget and GetResourceState('qb-target') == 'started' then
            local zone = exports['qb-target']:AddBoxZone('lb-rental-' .. i, npcPos, 2.0, 2.0, {
                name = 'lb-rental-' .. i,
                heading = loc.coords.w,
                debugPoly = false,
                minZ = loc.coords.z - 2.0,
                maxZ = loc.coords.z + 0.5,
            }, {
                options = options,
                distance = 2.5,
            })
            targetZones[i] = zone
        elseif GetResourceState('ox_target') == 'started' then
            exports['ox_target']:addBoxZone({
                coords = npcPos,
                size = vector3(2.0, 2.0, 2.0),
                rotation = loc.coords.w,
                debug = false,
                options = options,
            })
            targetZones[i] = true
        end
    end
end

local function OpenMenu()
    menuOpen = true
    SetPrompt(false)
    SetNuiFocus(true, true)

    local hasRental = rentalData ~= nil

    local vehicleData = {}
    for i = 1, #Config.Vehicles do
        local v = Config.Vehicles[i]
        vehicleData[i] = {
            label = v.label,
            model = v.model,
            price = v.price,
            category = v.category,
            image = v.image or '',
            stats = v.stats or nil,
        }
    end

    SendNUIMessage({
        type = 'openTablet',
        hasRental = hasRental,
        logo = Config.ServerLogo or '',
        brandName = Config.BrandName or 'LB Rental',
        brandSub = Config.BrandSub or 'Premium Vehicles',
        labels = Config.Labels or {},
        vehicles = vehicleData,
        imageBaseUrl = Config.ImageBaseUrl or '',
    })

    if hasRental then
        local plate = rentalData.plate or (rentedVehicle and DoesEntityExist(rentedVehicle) and GetVehicleNumberPlateText(rentedVehicle)) or 'UNKNOWN'
        SendNUIMessage({
            type = 'setRentalInfo',
            hasRental = true,
            info = {
                model = rentalData.model,
                plate = plate,
            },
        })
    end
end

local function CloseMenu()
    menuOpen = false
    SetNuiFocus(false, false)
end

RegisterNUICallback('getVehicles', function(_, cb)
    local vehicleData = {}
    for i = 1, #Config.Vehicles do
        vehicleData[i] = {
            label = Config.Vehicles[i].label,
            model = Config.Vehicles[i].model,
            price = Config.Vehicles[i].price,
            category = Config.Vehicles[i].category,
            image = Config.Vehicles[i].image or '',
            stats = Config.Vehicles[i].stats or nil,
        }
    end
    cb(vehicleData)
end)

RegisterNUICallback('rentVehicle', function(data, cb)
    local index = data.index + 1
    local vehicleInfo = Config.Vehicles[index]
    if not vehicleInfo then cb({}) return end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closestIdx = 1
    local closestDist = 100.0
    for i = 1, #Config.Locations do
        local loc = Config.Locations[i]
        local dist = #(coords - vector3(loc.coords.x, loc.coords.y, loc.coords.z))
        if dist < closestDist then
            closestDist = dist
            closestIdx = i
        end
    end

    TriggerServerEvent('lb-rental:server:rentVehicle', index, closestIdx)
    cb({})
end)

RegisterNetEvent('lb-rental:client:spawnVehicle')
AddEventHandler('lb-rental:client:spawnVehicle', function(index, locationIdx, plate)
    local vehicleInfo = Config.Vehicles[index]
    local location = Config.Locations[locationIdx]
    if not vehicleInfo or not location then
        SendCustomNotify('Spawn Failed', 'Spawn failed: invalid data', 'error')
        return
    end

    Wait(100)

    local headingRad = math.rad(location.coords.w)
    local spawnX = location.coords.x + math.sin(headingRad + math.rad(90)) * 4.0
    local spawnY = location.coords.y + math.cos(headingRad + math.rad(90)) * 4.0
    local spawnZ = location.coords.z

    local model = GetHashKey(vehicleInfo.model)
    RequestModel(model)
    local attempts = 0
    while not HasModelLoaded(model) and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end

    if not HasModelLoaded(model) then
        SendCustomNotify('Spawn Failed', 'Failed to load vehicle model', 'error')
        return
    end

    local vehicle = CreateVehicle(model, spawnX, spawnY, spawnZ, location.coords.w - 180.0, true, false)
    if not vehicle or vehicle == 0 then
        SendCustomNotify('Spawn Failed', 'Failed to create vehicle', 'error')
        return
    end

    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleNumberPlateText(vehicle, plate)
    SetModelAsNoLongerNeeded(model)

    SetVehicleDoorsLocked(vehicle, 0)

    pcall(function() exports['qb-vehiclekeys']:GiveKeys(plate) end)
    pcall(function() exports['qb-vehiclekeys']:GiveKeys(plate, vehicleInfo.model) end)
    pcall(function() TriggerEvent('vehiclekeys:client:SetOwner', plate) end)
    pcall(function() TriggerEvent('vehiclekeys:client:GiveKeys', plate) end)
    pcall(function() exports['qb-core']:AddKey(plate) end)

    rentedVehicle = vehicle
    rentalData = {
        model = vehicleInfo.model,
        price = vehicleInfo.price,
        deposit = math.floor(vehicleInfo.price * Config.DepositPercent),
        index = index,
        plate = plate,
    }
    
    SendCustomNotify('Vehicle Ready', ('Your %s has been spawned!'):format(vehicleInfo.label), 'success')
end)

RegisterNUICallback('returnVehicle', function(_, cb)
    SendCustomNotify('Returning Vehicle', 'Processing your return...', 'primary')
    
    if not rentalData then
        SendCustomNotify('Cannot Return', "You don't have a rented vehicle", 'error')
        cb({ success = false })
        return
    end

    SendCustomNotify('Rental Found', 'Located your active rental', 'success')

    local playerCoords = GetEntityCoords(PlayerPedId())
    local closestIdx = nil
    local closestDist = 100.0

    for i = 1, #Config.Locations do
        local loc = Config.Locations[i]
        local dist = #(playerCoords - vector3(loc.coords.x, loc.coords.y, loc.coords.z))
        if dist < closestDist then
            closestDist = dist
            closestIdx = i
        end
    end

    if not closestIdx or closestDist > 50.0 then
        SendCustomNotify('Too Far', 'You must be near a rental location to return', 'error')
        cb({ success = false })
        return
    end

    SendCustomNotify('Location Verified', 'You are near a rental spot', 'success')

    local plate = rentalData.plate or (rentedVehicle and DoesEntityExist(rentedVehicle) and GetVehicleNumberPlateText(rentedVehicle))

    pendingReturn = { vehicle = rentedVehicle, data = rentalData }

    TriggerServerEvent('lb-rental:server:returnVehicle', plate or '')
    cb({ success = true })
end)

RegisterNetEvent('lb-rental:client:returnProcessed')
AddEventHandler('lb-rental:client:returnProcessed', function(success, msg)
    if success and pendingReturn then
        if pendingReturn.vehicle and DoesEntityExist(pendingReturn.vehicle) then
            DeleteEntity(pendingReturn.vehicle)
        end
        rentedVehicle = nil
        rentalData = nil
        pendingReturn = nil
        SendCustomNotify('Return Complete', msg or 'Vehicle returned successfully', 'success')
        
        SendNUIMessage({
            type = 'setRentalInfo',
            hasRental = false,
            info = nil
        })
    else
        pendingReturn = nil
        SendCustomNotify('Return Failed', msg or 'Could not process return', 'error')
    end
end)

RegisterNetEvent('lb-rental:client:notify')
AddEventHandler('lb-rental:client:notify', function(title, text, ntype)
    SendCustomNotify(title, text, ntype)
end)

RegisterNUICallback('closeTablet', function(_, cb)
    CloseMenu()
    cb({})
end)

RegisterNetEvent('lb-rental:client:openMenu', function()
    local maxOpenDistance = Config.UseTarget and 3.0 or 2.5
    if GetClosestRentalLocationDistance() > maxOpenDistance then
        SendCustomNotify('Too Far', 'You must be near the rental NPC', 'error')
        return
    end
    OpenMenu()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    CreateThread(function()
        while not NetworkIsPlayerActive(PlayerId()) do
            Wait(500)
        end
        Citizen.Wait(1000)
        CreateBlips()
        CreateNPCs()
        CreateTargets()
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for _, blip in pairs(spawnedBlips) do
        RemoveBlip(blip)
    end

    for _, npc in pairs(spawnedNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end

    if rentedVehicle and DoesEntityExist(rentedVehicle) then
        DeleteEntity(rentedVehicle)
    end

    if GetResourceState('qb-target') == 'started' then
        for i = 1, #Config.Locations do
            exports['qb-target']:RemoveZone('lb-rental-' .. i)
        end
    end

    CloseMenu()
end)

CreateThread(function()
    while true do
        Wait(10000)
        CreateNPCs()
    end
end)

CreateThread(function()
    local t = 0.0
    while true do
        t = t + 0.05
        local pulse = (math.sin(t) + 1.0) / 2.0
        local currentScale = Config.Blip.scale + (Config.Blip.scale * 0.45) * pulse
        local alpha = 255 - math.floor(75 * pulse)
        for i = 1, #spawnedBlips do
            local b = spawnedBlips[i]
            if b and DoesBlipExist(b) then
                SetBlipScale(b, currentScale)
                SetBlipAlpha(b, alpha)
            end
        end
        Wait(30)
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())
        local nearAny = false

        for i = 1, #Config.Locations do
            local loc = Config.Locations[i]
            local dist = #(playerCoords - vector3(loc.coords.x, loc.coords.y, loc.coords.z))

            if dist < 20.0 then
                if not Config.UseTarget then
                    sleep = 0
                    if dist < 2.0 then
                        nearAny = true
                        if IsControlJustReleased(0, 38) then
                            TriggerEvent('lb-rental:client:openMenu')
                        end
                    end
                end
            end
        end

        SetPrompt(nearAny and not menuOpen)
        Wait(sleep)
    end
end)

