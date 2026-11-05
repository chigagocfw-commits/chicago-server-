local playerReadyStatus = {}
CentralSuscribeds = {}
Cops = {}
VehicleTrackeds = {}

-- Update player ready status
RegisterServerEvent("origen_police:server:PlayerReady", function(playerId, ready)
    playerId = playerId or source
    local jobCategory = CanOpenTablet(playerId)[2]
    
    if jobCategory == nil then
        return
    end
    
    playerReadyStatus[playerId] = ready
    
    if Cops[jobCategory] and Cops[jobCategory][playerId] then
        Cops[jobCategory][playerId].ready = ready
    end
end)

-- Export to get central subscribers
exports("GetCentralSuscribeds", function()
    return CentralSuscribeds
end)

-- Track a vehicle
function trackVehicle(jobCategory, vehicleNetId, model)
    Wait(1000)
    
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    
    if VehicleTrackeds[jobCategory] == nil then
        VehicleTrackeds[jobCategory] = {}
    end
    
    VehicleTrackeds[jobCategory][vehicleNetId] = {
        model = model,
        plate = GetVehicleNumberPlateText(vehicle),
        coords = GetEntityCoords(vehicle),
        entity = vehicle
    }
end

RegisterServerEvent("origen_police:server:TrackVehicle", function(vehicleNetId, model)
    local jobCategory = CanOpenTablet(source)[2]
    trackVehicle(jobCategory, vehicleNetId, model)
end)

-- Untrack a vehicle
function unTrackVehicle(jobCategory, vehicleNetId)
    VehicleTrackeds[jobCategory][vehicleNetId] = nil
    
    -- Notify all subscribed clients
    for playerId, _ in pairs(CentralSuscribeds) do
        TriggerClientEvent("origen_police:client:RemoveCentralMark", playerId, "car-" .. vehicleNetId)
    end
end

-- Get all tracked vehicles
function GetVehiclesTrackeds()
    return VehicleTrackeds
end

exports("trackVehicle", trackVehicle)
exports("unTrackVehicle", unTrackVehicle)
exports("GetVehicleTrackeds", GetVehiclesTrackeds)

RegisterServerEvent("origen_police:server:UnTrackVehicle", function(vehicleNetId, jobCategory)
    jobCategory = jobCategory or CanOpenTablet(source)[2]
    unTrackVehicle(jobCategory, vehicleNetId)
end)

-- Get tracked vehicles for a player
FW_CreateCallback("origen_police:server:GetVehiclesTracked", function(source, callback)
    local jobCategory = CanOpenTablet(source)[2]
    callback(VehicleTrackeds[jobCategory])
end)

-- Update vehicle positions and cop data thread
Citizen.CreateThread(function()
    playerReadyStatus = exports.origen_police:GetPlayersReady(Config.PoliceJobName)
    
    while true do
        Citizen.Wait(2500)
        
        -- Update tracked vehicle positions
        if VehicleTrackeds ~= nil then
            for jobCategory, vehicles in pairs(VehicleTrackeds) do
                for vehicleNetId, vehicleData in pairs(vehicles) do
                    if DoesEntityExist(vehicleData.entity) then
                        vehicleData.coords = GetEntityCoords(vehicleData.entity)
                    else
                        TriggerEvent("origen_police:server:UnTrackVehicle", vehicleNetId, jobCategory)
                    end
                end
            end
        end
        
        -- Update cop data with references
        for jobCategory, _ in pairs(Config.JobCategory) do
            if Cops[jobCategory] ~= nil then
                for playerId, copData in pairs(Cops[jobCategory]) do
                    if GetPlayerPed(playerId) > 0 then
                        -- Update unit from references
                        if References and References[jobCategory] and References[jobCategory][playerId] then
                            copData.unit = References[jobCategory][playerId].unit or ""
                            
                            copData.ref = {
                                coords = References[jobCategory][playerId].coords or vector3(0, 0, 0),
                                sprite = References[jobCategory][playerId].sprite or 1,
                                color = References[jobCategory][playerId].color or 0
                            }
                            
                            copData.ready = playerReadyStatus[playerId] or false
                        end
                    else
                        Cops[jobCategory][playerId] = nil
                    end
                end
                
                -- Send updates to subscribed clients
                if CentralSuscribeds ~= nil then
                    for playerId, _ in pairs(CentralSuscribeds) do
                        local playerJobCategory = CanOpenTablet(playerId)[2]
                        TriggerClientEvent(
                            "origen_police:client:UpdateCentralPositions",
                            playerId,
                            VehicleTrackeds[playerJobCategory],
                            Cops[playerJobCategory]
                        )
                    end
                end
            end
        end
    end
end)

-- Build cops list thread (runs every minute)
Citizen.CreateThread(function()
    if Config.Framework ~= "qbcore" and Config.Framework ~= "esx" then
        print("Can't find supported framework: ", Config.Framework)
        return
    end
    
    while true do
        Cops = {}
        
        for jobCategory, jobs in pairs(Config.JobCategory) do
            Cops[jobCategory] = {}
            local copsList = {}
            
            for _, job in pairs(jobs) do
                local color = job.color
                local jobName = job.name
                
                -- Get on-duty players
                local onDutyPlayers
                if Config.Framework == "qbcore" then
                    onDutyPlayers = Framework.Functions.GetPlayersOnDuty(jobName)
                else
                    onDutyPlayers = GetPlayersInDuty(jobName)
                end
                
                for i = 1, #onDutyPlayers do
                    local player = FW_GetPlayer(onDutyPlayers[i])
                    
                    if player and player.PlayerData then
                        local playerJob = player.PlayerData.job.name
                        local jobGrade = Framework.Shared.Jobs[playerJob]
                        
                        -- Get department type
                        local dept = "lspd"
                        if jobGrade and jobGrade.grades then
                            local gradeLevel = tostring(player.PlayerData.job.grade.level)
                            if jobGrade.grades[gradeLevel] and jobGrade.grades[gradeLevel].type then
                                dept = jobGrade.grades[gradeLevel].type
                            end
                        end
                        
                        -- Find color from job config
                        for category, categoryJobs in pairs(Config.JobCategory) do
                            for _, configJob in pairs(categoryJobs) do
                                if configJob.name == player.PlayerData.job.name then
                                    color = configJob.color
                                    break
                                end
                            end
                        end
                        
                        copsList[onDutyPlayers[i]] = {
                            name = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname,
                            badge = player.PlayerData.metadata.police_badge or "0000",
                            dept = dept:upper(),
                            grade = player.PlayerData.job.grade.name,
                            deptColor = color,
                            unit = References[onDutyPlayers[i]] and References[onDutyPlayers[i]].unit or "",
                            ref = {
                                coords = References[onDutyPlayers[i]] and References[onDutyPlayers[i]].coords or vector3(0, 0, 0),
                                sprite = References[onDutyPlayers[i]] and References[onDutyPlayers[i]].sprite or 1,
                                color = References[onDutyPlayers[i]] and References[onDutyPlayers[i]].color or 0
                            },
                            ready = playerReadyStatus[onDutyPlayers[i]] or false,
                            source = onDutyPlayers[i],
                            hideGPS = HiddenGpsCops[onDutyPlayers[i]] or nil
                        }
                    else
                        if HiddenGpsCops[onDutyPlayers[i]] then
                            HiddenGpsCops[onDutyPlayers[i]] = nil
                        end
                    end
                end
            end
            
            Cops[jobCategory] = copsList
        end
        
        Citizen.Wait(60000)
    end
end)

-- Open central callback
FW_CreateCallback("origen_police:server:OpenCentral", function(source, callback)
    local playerId = source
    local player = FW_GetPlayer(playerId)
    
    if not player then
        callback(false)
        return
    end
    
    local canOpen, jobCategory = CanOpenTablet(player.PlayerData.job.name)[1], CanOpenTablet(player.PlayerData.job.name)[2]
    
    -- Check if player can open tablet and has a valid job category
    if not canOpen or not jobCategory then
        callback(false)
        return
    end
    
    -- Additional permission check for dispatch access
    local hasDispatchPermission = GetMinimunGrade(player.PlayerData.job.name, "Dispatch")
    if hasDispatchPermission and player.PlayerData.job.grade.level < hasDispatchPermission then
        callback(false)
        return
    end
    
    CentralSuscribeds[playerId] = true
    
    callback(json.decode(json.encode({
        VehicleTrackeds = VehicleTrackeds[jobCategory],
        Cops = Cops[jobCategory],
        Radars = Public.Radars,
        TrafficZones = Public.TrafficZones
    })))
end)

-- Close central callback
FW_CreateCallback("origen_police:server:CloseCentral", function(source, callback)
    CentralSuscribeds[source] = nil
    callback(true)
end)

-- Handle player disconnect
AddEventHandler("playerDropped", function()
    local playerId = source
    if not playerId then return end
    
    if CentralSuscribeds[playerId] then
        CentralSuscribeds[playerId] = nil
    end
end)