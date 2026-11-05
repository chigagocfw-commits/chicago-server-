FishingPed = nil
BoatRentPed = nil
AddEventHandler('onResourceStart', function(resourceName)
    if (resourceName == GetCurrentResourceName()) then
        Wait(3000)
        TriggerServerEvent('codem-fishingjob:LoadInfo')
        Wait(1000)
        CharacterLoaded = true
    end
end)
RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function()
    Wait(3000)
    TriggerServerEvent('codem-fishingjob:LoadInfo')
    Wait(1000)
    CharacterLoaded = true
end)

RegisterNetEvent("QBCore:Client:OnPlayerLoaded")
AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
    Wait(3000)
    TriggerServerEvent('codem-fishingjob:LoadInfo')
    Wait(1000)
    CharacterLoaded = true
end)

RegisterNetEvent("QBCore:Client:OnJobUpdate")
AddEventHandler("QBCore:Client:OnJobUpdate", function(data)
    Wait(1000)
end)

RegisterNetEvent("esx:setJob")
AddEventHandler("esx:setJob", function(job)
    Wait(1000)
end)


Citizen.CreateThread(function()
    while not NuiLoaded and Core == nil do
        Citizen.Wait(0)
    end
    RegisterKeyMapping('pressstopfishing', 'Fishing', 'keyboard', Config.RegisterKeyMapping['stopfishing'])

    RegisterCommand('pressstopfishing', function()
        StopFishing()
    end, false)

    RegisterKeyMapping('openbaitmenu', 'Fishing Bait Menu', 'keyboard', Config.RegisterKeyMapping['baitmenu'])

    RegisterCommand('openbaitmenu', function()
        OpenPressBaitMenu()
    end, false)
end)

GetClosestPlayers = function()
    local players = {}
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    for _, player in ipairs(GetActivePlayers()) do
        local target = GetPlayerPed(player)
        if target ~= ped then
            local targetCoords = GetEntityCoords(target)
            local distance = #(pedCoords - targetCoords)
            if distance < 3.5 then
                table.insert(players, GetPlayerServerId(player))
            end
        end
    end
    return players
end


AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() == resourceName) then
        FreezeEntityPosition(PlayerPedId(), false)
    end
end)

Citizen.CreateThread(function()
    SpawnFishingNPC(Config.FishingNPC.Model, Config.FishingNPC.Coords)
    SpawnBoatRentNPC(Config.BoatRentPed.Model, Config.BoatRentPed.Coords)
    InitMenu()

    for k, v in pairs(Config.DailyDelivery) do
        if v.npcCoords then
            SpawnDailyDeliveryPed(v.npcCoords.model, v.npcCoords.coords, v.npcCoords.heading)
        end
    end
end)

function SpawnBoatRentNPC(model, coords)
    if DoesEntityExist(BoatRentPed) then
        DeleteEntity(BoatRentPed)
    end
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    BoatRentPed = CreatePed(0, model, coords, false, false)
    FreezeEntityPosition(BoatRentPed, true)
    SetEntityInvincible(BoatRentPed, true)
    SetEntityHeading(BoatRentPed, Config.BoatRentPed.Heading)
    SetBlockingOfNonTemporaryEvents(BoatRentPed, true)
    if Config.BoatRentPed.Blip.Show then
        local BlipSettings = Config.BoatRentPed.Blip
        local blip = AddBlipForCoord(coords)
        SetBlipSprite(blip, BlipSettings.Sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, BlipSettings.Scale)
        SetBlipColour(blip, BlipSettings.Color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(BlipSettings.Name)
        EndTextCommandSetBlipName(blip)
    end
end

function SpawnDailyDeliveryPed(model, coords, heading)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    local DeliverPed = CreatePed(0, model, coords, false, false)
    FreezeEntityPosition(DeliverPed, true)
    SetEntityInvincible(DeliverPed, true)
    SetEntityHeading(DeliverPed, heading)
    SetBlockingOfNonTemporaryEvents(DeliverPed, true)
end

function SpawnFishingNPC(model, coords)
    if DoesEntityExist(FishingPed) then
        DeleteEntity(FishingPed)
    end
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    FishingPed = CreatePed(0, model, coords, false, false)
    FreezeEntityPosition(FishingPed, true)
    SetEntityInvincible(FishingPed, true)
    SetEntityHeading(FishingPed, Config.FishingNPC.Heading)
    SetBlockingOfNonTemporaryEvents(FishingPed, true)
    if Config.FishingNPC.Blip.Show then
        local BlipSettings = Config.FishingNPC.Blip
        local blip = AddBlipForCoord(coords)
        SetBlipSprite(blip, BlipSettings.Sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, BlipSettings.Scale)
        SetBlipColour(blip, BlipSettings.Color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(BlipSettings.Name)
        EndTextCommandSetBlipName(blip)
    end
end

CreateCamera = function()
    local invehicle = IsPedInAnyVehicle(PlayerPedId(), false)
    if invehicle then return end
    if not FishingPed then return end
    local coords = GetOffsetFromEntityInWorldCoords(FishingPed, -0.38, 1.7, 0)
    RenderScriptCams(true, true, 500, true, true)
    DestroyCam(Cam, false)

    if (not DoesCamExist(Cam)) then
        Cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamActive(Cam, true)
        RenderScriptCams(true, true, 500, true, true)

        SetCamCoord(Cam, coords.x, coords.y, coords.z + 0.2)
        PointCamAtEntity(Cam, FishingPed, 0.0, -1.5, 0.0)
        SetCamRot(Cam, 0.0, 0.0, GetEntityHeading(FishingPed))
        SetCamNearClip(Cam, 0.1)
        SetCamFarClip(Cam, 1000.0)
        SetCamFov(Cam, 68.0)
        SetCamDofFnumberOfLens(Cam, 24.0)
        SetCamDofFocalLengthMultiplier(Cam, 10.0)
    end
end


function DestroyCamera()
    RenderScriptCams(false, true, 500, true, true)
    DestroyCam(Cam, false)
end

function SpawnVehicle(model, coords)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, true, true)
    SetEntityHeading(veh, coords.w)
    Config.GiveVehicleKey(GetVehicleNumberPlateText(veh), model, veh)
    Config.SetVehicleFuel(veh, 100.0)
    PlayerData.VehiclePlate = GetVehicleNumberPlateText(veh)
    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    return veh
end

function CodemGetVehicles()
    return GetGamePool('CVehicle')
end

function CodemGetVehiclesInArea(coords, maxDistance)
    return CodemEnumerateEntitiesWithinDistance(CodemGetVehicles(), false, coords, maxDistance)
end

function CodemEnumerateEntitiesWithinDistance(entities, isPlayerEntities, coords, maxDistance)
    local nearbyEntities = {}

    if coords then
        coords = vector3(coords.x, coords.y, coords.z)
    else
        local playerPed = PlayerPedId()
        coords = GetEntityCoords(playerPed)
    end
    for k, entity in pairs(entities) do
        local distance = #(coords - GetEntityCoords(entity))

        if distance <= maxDistance then
            nearbyEntities[#nearbyEntities + 1] = isPlayerEntities and k or entity
        end
    end
    return nearbyEntities
end

function TriggerCallback(name, data)
    local incomingData = false
    local status = 'UNKOWN'
    local counter = 0
    while Core == nil do
        Wait(0)
    end
    if Config.Framework == 'esx' then
        Core.TriggerServerCallback(name, function(payload)
            status = 'SUCCESS'
            incomingData = payload
        end, data)
    else
        Core.Functions.TriggerCallback(name, function(payload)
            status = 'SUCCESS'
            incomingData = payload
        end, data)
    end
    CreateThread(function()
        while incomingData == 'UNKOWN' do
            Wait(1000)
            if counter == 4 then
                status = 'FAILED'
                incomingData = false
                break
            end
            counter = counter + 1
        end
    end)

    while status == 'UNKOWN' do
        Wait(0)
    end
    return incomingData
end

function DrawMarkers(type, x, y, z, dirX, dirY, dirZ, rotX, rotY, rotZ, scaleX, scaleY, scaleZ, r, g, b, alpha,
                     bobUpAndDown, faceCamera, p19, rotate, textureDict, textureName, drawOnEnts)
    DrawMarker(type, x, y, z, dirX, dirY, dirZ, rotX, rotY, rotZ, scaleX, scaleY, scaleZ, r, g, b, alpha, bobUpAndDown,
        faceCamera, p19, rotate, textureDict, textureName, drawOnEnts)
end

function DrawText3D(x, y, z, text)
    if not text then
        text = 'Missing Text'
    end
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    SetTextScale(0.3, 0.3)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 90)
end
