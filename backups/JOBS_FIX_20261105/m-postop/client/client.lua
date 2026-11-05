CDM.Client = {}
CDM.Client.JobData = {}
CDM.Client.IsPackageClaimed = false
CDM.Client.JobRoute = {}
CDM.Client.IsJobStarted = false
CDM.Client.JOBID = 0

frameworkObject = nil
cam = 0
startable = true
car = nil
jobvehicle = nil
packageProp = 0
blipsList = {}
savedVehicleData = {}
deliveryInProgress = false

Citizen.CreateThread(function()
    frameworkObject = GetFrameworkObject()
    CreatePeds()
end)

function CreatePeds()
    for jobIndex, jobData in pairs(CDM.Config.Job) do
        if jobData.show.ped.enable then
            RequestModel(jobData.show.ped.hash)
            while not HasModelLoaded(jobData.show.ped.hash) do
                Citizen.Wait(1)
            end
            local ped = CreatePed(1, jobData.show.ped.hash, jobData.coord.x, jobData.coord.y, jobData.coord.z - 0.98, jobData.coord.w, false, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetPedDiesWhenInjured(ped, false)
            SetPedCanPlayAmbientAnims(ped, true)
            SetPedCanRagdollFromPlayerImpact(ped, false)
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)
        end
        if jobData.show.blip.enable then
            Blip = AddBlipForCoord(jobData.coord.x, jobData.coord.y, jobData.coord.z)
            SetBlipSprite(Blip, jobData.show.blip.id)
            SetBlipScale(Blip, jobData.show.blip.scale)
            SetBlipColour(Blip, jobData.show.blip.color)
            SetBlipDisplay(Blip, 4)
            SetBlipAsShortRange(Blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(jobData.show.blip.label)
            EndTextCommandSetBlipName(Blip)
        end
    end
end

Citizen.CreateThread(function()
    local targetActive = false
    while true do
        local isNearJob = false
        local waitTime = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        for jobIndex, jobData in pairs(CDM.Config.Job) do
            local jobCoords = vector3(jobData.coord.x, jobData.coord.y, jobData.coord.z)
            local distance = #(vector3(playerCoords) - jobCoords)
            if distance <= 2.0 then
                waitTime = 3
                if jobData.show.target then
                    if not targetActive then
                        CDM.Target(jobData, jobIndex)
                    end
                else
                    if jobData.show.marker and jobData.show.marker.enable then
                        CDM.DrawMarker(jobData.coord.x, jobData.coord.y, jobData.coord.z, jobData.show.marker.type, jobData.show.marker.r, jobData.show.marker.g, jobData.show.marker.b, jobData.show.marker.rotX, jobData.show.marker.rotY, jobData.show.marker.rotZ)
                    end
                    if jobData.show.text and jobData.show.text.enable then
                        CDM.DrawText(jobData.coord.x, jobData.coord.y, jobData.coord.z + jobData.show.text.zoffset, jobData.show.text.message)
                    end
                    if IsControlJustPressed(0, jobData.show.openKey) then
                        TriggerServerEvent("m-postop-server:Job", jobIndex)
                    end
                end
                isNearJob = true
                targetActive = true
            end
        end
        if not isNearJob and targetActive then
            if CDM.Config.Job.start.target then
                if CDM.Config.Job.start.InteractionHandler == "ox-target" then
                    exports.ox_target:removeZone("postopstart")
                end
            end
            if CDM.Config.Job.gardrop.target then
                if CDM.Config.Job.gardrop.InteractionHandler == "ox-target" then
                    exports.ox_target:removeZone("postopgardrop")
                end
            end
            targetActive = false
        end
        Citizen.Wait(waitTime)
    end
end)

RegisterNetEvent("m-postop-client-target")
AddEventHandler("m-postop-client-target", function(data)
    TriggerServerEvent("m-postop-server:Job", data.index)
end)

RegisterNUICallback("jobindex", function(data, callback)
    if data.index then
        if data.index == "uniform" then
            CDM.CloseUI()
            SetNewWaypoint(CDM.Config.Job.gardrop.coord.x, CDM.Config.Job.gardrop.coord.y)
            CDM.SendMessage(CDM.Messages.client.waypointsetforgardrop, false)
        elseif data.index == "job" then
            TriggerServerEvent("m-postop-server:StartJob")
        end
    end
end)

RegisterNUICallback("UpdateJobData", function(data, callback)
    TriggerServerEvent("m-postop-server:UpdateJobData", data.rtype, data.route)
end)

RegisterNUICallback("SetVehicleCam", function(data, callback)
    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", 1)
    SetCamCoord(cam, CDM.Config.VehicleCam.Cam.x, CDM.Config.VehicleCam.Cam.y, CDM.Config.VehicleCam.Cam.z)
    SetCamRot(cam, 0.0, 0.0, CDM.Config.VehicleCam.Cam.w)
    RenderScriptCams(1, 0, 0, 1, 1)
    if data.vehicle == "yourtruck" then
        if savedVehicleData.vehicleprops ~= nil then
            RequestModel(savedVehicleData.vehicleprops.model)
            while not HasModelLoaded(savedVehicleData.vehicleprops.model) do
                Wait(0)
            end
            if car ~= 0 then
                DeleteVehicle(car)
                car = nil
            end
            car = CreateVehicle(savedVehicleData.vehicleprops.model, CDM.Config.VehicleCam.VehicleSpawnCoordinates.x, CDM.Config.VehicleCam.VehicleSpawnCoordinates.y, CDM.Config.VehicleCam.VehicleSpawnCoordinates.z, CDM.Config.VehicleCam.VehicleSpawnCoordinates.w, false, true)
            CDM.SetVehicleProperties(car)
        else
            if car ~= 0 then
                DeleteVehicle(car)
                car = nil
            end
            CDM.SendMessage(CDM.Messages.client.vehiclenotfound, true)
        end
    else
        RequestModel(CDM.Vehicles[data.vehicle].hash)
        while not HasModelLoaded(CDM.Vehicles[data.vehicle].hash) do
            Wait(0)
        end
        if car ~= 0 then
            DeleteVehicle(car)
            car = nil
        end
        car = CreateVehicle(CDM.Vehicles[data.vehicle].hash, CDM.Config.VehicleCam.VehicleSpawnCoordinates.x, CDM.Config.VehicleCam.VehicleSpawnCoordinates.y, CDM.Config.VehicleCam.VehicleSpawnCoordinates.z, CDM.Config.VehicleCam.VehicleSpawnCoordinates.w, false, true)
    end
end)

RegisterNetEvent("m-postop-client:SetVehicleItem")
AddEventHandler("m-postop-client:SetVehicleItem", function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle ~= 0 then
        savedVehicleData.vehicleprops = CDM.GetVehicleProperties(vehicle)
        savedVehicleData.vehicle = vehicle
        CDM.SendMessage(CDM.Messages.client.vehicleset, false)
    end
end)

RegisterNetEvent("m-postop-client:DeleteJobVehicle")
AddEventHandler("m-postop-client:DeleteJobVehicle", function()
    if CDM.Client.JobData then
        if CDM.Client.JobData.vehicle ~= "yourtruck" then
            CDM.RemoveVehicleKeys(GetVehicleNumberPlateText(jobvehicle), jobvehicle)
            car = nil
            jobvehicle = nil
            DeleteVehicle(jobvehicle)
        end
    end
end)

CDM.GetVehicleProperties = function(vehicle)
    while frameworkObject == nil do
        Citizen.Wait(100)
    end
    if CDM.Config.Framework == "new-qb" or CDM.Config.Framework == "old-qb" then
        if DoesEntityExist(vehicle) then
            return frameworkObject.Functions.GetVehicleProperties(vehicle)
        end
    end
end

CDM.SetVehicleProperties = function(vehicle)
    if vehicle == 0 then
        return
    end
    while frameworkObject == nil do
        Citizen.Wait(100)
    end
    if CDM.Config.Framework == "new-qb" or CDM.Config.Framework == "old-qb" then
        if DoesEntityExist(vehicle) then
            frameworkObject.Functions.SetVehicleProperties(vehicle, savedVehicleData.vehicleprops)
            return true
        end
    end
end

RegisterNUICallback("DestroyCam", function(data, callback)
    DestroyCam(cam)
    RenderScriptCams(0, 0, 1, 1, 1)
    if car ~= 0 then
        DeleteVehicle(car)
        car = nil
    end
end)

RegisterNUICallback("SetVehicle", function(data, callback)
    if data.vehicle == "yourtruck" then
        if savedVehicleData.vehicle == nil then
            return
        end
    end
    TriggerServerEvent("m-postop-server:SetVehicleData", data.vehicle)
end)

RegisterNUICallback("CloseUi", function(data, callback)
    SendNUIMessage({message = "close"})
    SetNuiFocus(false, false)
    DestroyCam(cam)
    RenderScriptCams(0, 0, 1, 1, 1)
    if car ~= 0 then
        DeleteVehicle(car)
        car = nil
    end
end)

CDM.CloseUI = function()
    SendNUIMessage({message = "close"})
    SetNuiFocus(false, false)
    DestroyCam(cam)
    RenderScriptCams(0, 0, 1, 1, 1)
    if car ~= 0 then
        DeleteVehicle(car)
        car = nil
    end
end

function LoadPropDict(model)
    while not HasModelLoaded(GetHashKey(model)) do
        RequestModel(GetHashKey(model))
        Wait(10)
    end
end

function DeleteBoxProp()
    if packageProp ~= 0 then
        DeleteEntity(packageProp)
    end
    ClearPedTasks(PlayerPedId())
end

CDM.CreateBlip = function(x, y, z)
    for blipIndex, blip in pairs(blipsList) do
        RemoveBlip(blip)
        table.remove(blipsList, blipIndex)
    end
    DeliveryBlip = AddBlipForCoord(x, y, z)
    SetBlipSprite(DeliveryBlip, CDM.Config.DeliveryBlip.id)
    SetBlipScale(DeliveryBlip, CDM.Config.DeliveryBlip.scale)
    SetBlipColour(DeliveryBlip, CDM.Config.DeliveryBlip.color)
    SetBlipDisplay(DeliveryBlip, 4)
    SetBlipAsShortRange(DeliveryBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(CDM.Config.DeliveryBlip.label)
    EndTextCommandSetBlipName(DeliveryBlip)
    table.insert(blipsList, DeliveryBlip)
end

CDM.SetPackageAnim = function()
    local propModel = "hei_prop_heist_box"
    local boneIndex = 60309
    local placement = {0.025, 0.08, 0.255, -145.0, 290.0, 0.0}
    local playerPed = PlayerPedId()
    local x, y, z = table.unpack(GetEntityCoords(playerPed))
    if not HasModelLoaded(propModel) then
        LoadPropDict(propModel)
    end
    prop = CreateObject(GetHashKey(propModel), x, y, z + 0.2, true, true, true)
    AttachEntityToEntity(prop, playerPed, GetPedBoneIndex(playerPed, boneIndex), placement[1], placement[2], placement[3], placement[4], placement[5], placement[6], true, true, false, true, 1, true)
    packageProp = prop
    SetModelAsNoLongerNeeded(propModel)
    while not HasAnimDictLoaded("anim@heists@box_carry@") do
        RequestAnimDict("anim@heists@box_carry@")
        Citizen.Wait(100)
    end
    TaskPlayAnim(playerPed, "anim@heists@box_carry@", "idle", 4.0, 4.0, -1, 51, 0, false, false, false)
    CDM.Client.IsPackageClaimed = true
end

RegisterNetEvent("m-postop-client:Gardrop")
AddEventHandler("m-postop-client:Gardrop", function()
end)

RegisterNetEvent("m-postop-client:ContinueJob")
AddEventHandler("m-postop-client:ContinueJob", function()
    DeleteBoxProp()
    deliveryInProgress = false
    randomdeliveries = math.random(1, #CDM.Client.JobData.route.locations)
    local routeData = CDM.Client.JobData.route.locations[randomdeliveries]
    CDM.Client.JobRoute = routeData
    Wait(500)
    SetNewWaypoint(routeData.x, routeData.y)
    CDM.CreateBlip(routeData.x, routeData.y, routeData.z)
    CDM.Client.IsPackageClaimed = false
end)

RegisterNetEvent("m-postop-client:StartJob")
AddEventHandler("m-postop-client:StartJob", function(jobData, jobID)
    if jobData then
        CDM.Client.JobData = jobData
        if jobData.route then
            CDM.CloseUI()
            if jobData.jobtype == "cargo" then
                if jobData.vehicle == "yourtruck" then
                    randomdeliveries = math.random(1, #jobData.route.locations)
                    local routeData = jobData.route.locations[randomdeliveries]
                    CDM.Client.JobRoute = routeData
                    Wait(500)
                    SetNewWaypoint(routeData.x, routeData.y)
                    CDM.CreateBlip(routeData.x, routeData.y, routeData.z)
                    CDM.Client.IsJobStarted = true
                    CDM.Client.IsPackageClaimed = false
                    jobvehicle = CDM.FindVehicle()
                    TriggerServerEvent("m-postop-server:UpdateRemainingPackage")
                else
                    randomdeliveries = math.random(1, #jobData.route.locations)
                    local routeData = jobData.route.locations[randomdeliveries]
                    CDM.Client.JobRoute = routeData
                    Wait(500)
                    SetNewWaypoint(routeData.x, routeData.y)
                    CDM.CreateBlip(routeData.x, routeData.y, routeData.z)
                    CDM.Client.IsJobStarted = true
                    CDM.Client.IsPackageClaimed = false
                    jobvehicle = CreateVehicle(CDM.Vehicles[jobData.vehicle].hash, CDM.Config.JobVehSpawnCoord.x, CDM.Config.JobVehSpawnCoord.y, CDM.Config.JobVehSpawnCoord.z, CDM.Config.JobVehSpawnCoord.w, true, true)
                    TaskWarpPedIntoVehicle(PlayerPedId(), jobvehicle, -1)
                    TriggerServerEvent("m-postop-server:UpdateRemainingPackage")
                end
            elseif jobData.jobtype == "transport" then
                if jobData.vehicle == "yourtruck" then
                    randomdeliveries = math.random(1, #jobData.route.location)
                    local routeData = jobData.route.location[randomdeliveries]
                    CDM.CreateBlip(routeData.x, routeData.y, routeData.z)
                    CDM.Client.JobRoute = routeData
                    CDM.Client.IsJobStarted = true
                    CDM.Client.IsPackageClaimed = false
                    jobvehicle = CDM.FindVehicle()
                    SetNewWaypoint(routeData.x, routeData.y)
                    TriggerServerEvent("m-postop-server:UpdateRemainingPackage")
                else
                    randomdeliveries = math.random(1, #jobData.route.location)
                    local routeData = jobData.route.location[randomdeliveries]
                    CDM.CreateBlip(routeData.x, routeData.y, routeData.z)
                    CDM.Client.JobRoute = routeData
                    CDM.Client.IsJobStarted = true
                    CDM.Client.IsPackageClaimed = false
                    SetNewWaypoint(routeData.x, routeData.y)
                    jobvehicle = CreateVehicle(CDM.Vehicles[jobData.vehicle].hash, CDM.Config.JobVehSpawnCoord.x, CDM.Config.JobVehSpawnCoord.y, CDM.Config.JobVehSpawnCoord.z, CDM.Config.JobVehSpawnCoord.w, true, true)
                    TaskWarpPedIntoVehicle(PlayerPedId(), jobvehicle, -1)
                    TriggerServerEvent("m-postop-server:UpdateRemainingPackage")
                end
            end
            TriggerEvent("m-postop-client:DetachHotwire", GetVehicleNumberPlateText(jobvehicle), jobvehicle)
        end
        CDM.Client.JOBID = jobID
    end
end)

RegisterNetEvent("m-postop-client:UpdatePackages")
AddEventHandler("m-postop-client:UpdatePackages", function(deliver, totalDeliver, vehicleMaxCapacity, vehiclepackages)
    SendNUIMessage({
        message = "OpenJobDescription",
        deliver = deliver,
        totalDeliver = totalDeliver,
        vehicleMaxCapacity = vehicleMaxCapacity,
        vehiclepackages = vehiclepackages
    })
end)

Citizen.CreateThread(function()
    while true do
        local waitTime = 600
        if CDM.Client.IsPackageClaimed then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local deliveryCoords = vector3(CDM.Client.JobRoute.x, CDM.Client.JobRoute.y, CDM.Client.JobRoute.z)
            local distance = #(playerCoords - deliveryCoords)
            if distance < 4.0 then
                if CDM.Config.Deliver.marker.enable then
                    CDM.DrawMarker(deliveryCoords.x, deliveryCoords.y, deliveryCoords.z, CDM.Config.Deliver.marker.type, CDM.Config.Deliver.marker.r, CDM.Config.Deliver.marker.g, CDM.Config.Deliver.marker.b, CDM.Config.Deliver.marker.rotX, CDM.Config.Deliver.marker.rotY, CDM.Config.Deliver.marker.rotZ)
                end
                waitTime = 5
                if distance < 3.0 then
                    if not IsPedInAnyVehicle(playerPed) then
                        if CDM.Config.Deliver.text.enable then
                            local message = CDM.Config.Deliver.text.message
                            CDM.DrawText(deliveryCoords.x, deliveryCoords.y, deliveryCoords.z, message)
                        end
                        if IsControlJustPressed(0, 38) then
                            if not deliveryInProgress then
                                TriggerServerEvent("m-postop-server:DeliverPackage", CDM.Client.JOBID)
                                deliveryInProgress = true
                            end
                        end
                    end
                end
            end
        end
        Citizen.Wait(waitTime)
    end
end)

Citizen.CreateThread(function()
    while true do
        local waitTime = 500
        local playerCoords = GetEntityCoords(PlayerPedId())
        local fillCoords = vector3(CDM.Config.VehicleCapacityFill.coord.x, CDM.Config.VehicleCapacityFill.coord.y, CDM.Config.VehicleCapacityFill.coord.z)
        local distance = #(playerCoords - fillCoords)
        if distance < 7.0 then
            waitTime = 5
            text = "Load Packages"
            if distance < 3.0 then
                if not IsPedInAnyVehicle(ped) then
                    text = "E - Load Packages"
                    if IsControlJustPressed(0, 38) then
                        if IsPedInAnyVehicle(PlayerPedId()) then
                            local vehicle = GetVehiclePedIsIn(PlayerPedId())
                            if jobvehicle ~= 0 then
                                if vehicle == jobvehicle then
                                    TriggerServerEvent("m-postop-server:fillvehicle")
                                end
                            end
                        end
                    end
                    CDM.DrawMarker(fillCoords.x, fillCoords.y, fillCoords.z, CDM.Config.VehicleCapacityFill.markerType, CDM.Config.VehicleCapacityFill.r, CDM.Config.VehicleCapacityFill.g, CDM.Config.VehicleCapacityFill.b, nil, nil, nil, "fill")
                end
            end
            CDM.DrawText(fillCoords.x, fillCoords.y, fillCoords.z + 0.9, text)
        end
        Citizen.Wait(waitTime)
    end
end)

Citizen.CreateThread(function()
    while true do
        wait = 600
        local deleteCoords = vector3(CDM.Config.DeleteTruck.coord.x, CDM.Config.DeleteTruck.coord.y, CDM.Config.DeleteTruck.coord.z)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distance = #(playerCoords - deleteCoords)
        if distance < 7.0 then
            wait = 2
            CDM.DrawMarker(CDM.Config.DeleteTruck.coord.x, CDM.Config.DeleteTruck.coord.y, CDM.Config.DeleteTruck.coord.z, CDM.Config.DeleteTruck.marker.markerType, CDM.Config.DeleteTruck.marker.r, CDM.Config.DeleteTruck.marker.g, CDM.Config.DeleteTruck.marker.b, nil, nil, nil, "fill")
            if distance < 2.0 then
                if IsControlJustPressed(0, 38) then
                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    CDM.RemoveVehicleKeys(GetVehicleNumberPlateText(jobvehicle), jobvehicle)
                    DeleteVehicle(vehicle)
                    TriggerServerEvent("m-postop-server:FinishJobWithCommand")
                    car = nil
                    jobvehicle = nil
                end
                if CDM.Config.DeleteTruck.text.enable then
                    CDM.DrawText(deleteCoords.x, deleteCoords.y, deleteCoords.z + 0.9, CDM.Config.DeleteTruck.text.message)
                end
            end
        end
        Citizen.Wait(wait)
    end
end)

RegisterNetEvent("m-postop-client:OpenNui")
AddEventHandler("m-postop-client:OpenNui", function(postopData, remainingtime, LeaderBoardData, photo)
    if car or jobvehicle then
        CDM.SendMessage(CDM.Messages.client.returncar, false)
        return
    end
    table.sort(LeaderBoardData, function(a, b)
        return tonumber(a.level) > tonumber(b.level)
    end)
    local topFive = {}
    for i = 1, 5, 1 do
        if LeaderBoardData[i] then
            table.insert(topFive, LeaderBoardData[i])
        end
    end
    SendNUIMessage({
        message = "open",
        postopData = postopData,
        routeslist = CDM.Routes,
        vehiclelist = CDM.Vehicles,
        DailyMissions = CDM.Config.DailyMissions,
        remainingtime = remainingtime,
        xptable = CDM.Config.RequiredXP,
        classlist = CDM.Class,
        LeaderBoard = topFive,
        photo = photo,
        innermessages = CDM.Messages.html
    })
    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", 1)
    SetCamCoord(cam, CDM.Config.PostOpCam.x, CDM.Config.PostOpCam.y, CDM.Config.PostOpCam.z)
    SetCamRot(cam, 0.0, 0.0, CDM.Config.PostOpCam.heading)
    RenderScriptCams(1, 0, 0, 1, 1)
    SetNuiFocus(true, true)
end)

RegisterNetEvent("m-postop-client:FinishJob")
AddEventHandler("m-postop-client:FinishJob", function()
    CDM.Client.IsJobStarted = false
    CDM.Client.IsPackageClaimed = false
    DeleteBoxProp()
    SendNUIMessage({message = "closejob"})
    CDM.Client.IsPackageClaimed = false
    CDM.Client.JobRoute = {}
    CDM.Client.IsJobStarted = false
    CDM.Client.JOBID = 0
    packageProp = 0
    savedVehicleData = {}
    deliveryInProgress = false
    for blipIndex, blip in pairs(blipsList) do
        RemoveBlip(blip)
        table.remove(blipsList, blipIndex)
    end
    if CDM.Client.JobData.vehicle == "yourtruck" then
        CDM.SendMessage(CDM.Messages.client.finishjobyourtruck, false)
        car = nil
        jobvehicle = nil
    else
        CDM.SendMessage(CDM.Messages.client.finishjob, false)
        SetNewWaypoint(CDM.Config.DeleteTruck.coord.x, CDM.Config.DeleteTruck.coord.y)
    end
    CDM.Client.JobData = {}
end)

CDM.FindVehicle = function()
    local vehicles = GetGamePool("CVehicle")
    for _, vehicle in pairs(vehicles) do
        if GetVehicleNumberPlateText(vehicle) == GetVehicleNumberPlateText(savedVehicleData.vehicle) then
            return vehicle
        end
    end
end