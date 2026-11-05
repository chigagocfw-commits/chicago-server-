-- Automatic License Plate Reader (ALPR) System
local radarActive = false
local radarLocked = false
local frontLockedPlate = ""
local rearLockedPlate = ""
local frontVehicleData = false
local rearVehicleData = false
local radarVisible = false

-- Cache for job validation
local jobCache = {
    time = GetGameTimer(),
    name = nil,
    duty = nil
}

-- Check if vehicle is valid for radar use
function IsVehicleValid(vehicleType, vehicle)
    -- Update job cache every 7 seconds
    if jobCache.name == nil or jobCache.time <= GetGameTimer() + 7000 then
        local playerData = FW_GetPlayerData(false)
        jobCache.name = playerData.job.name
        jobCache.duty = playerData.job.onduty
        jobCache.time = GetGameTimer()
    end
    
    local canOpen = CanOpenTablet(jobCache.name)
    
    if canOpen[1] == false or not jobCache.duty then
        return nil
    end
    
    -- Check if vehicle type is "any"
    if vehicleType == "any" then
        if not Config.Vehicles then
            return
        end
        
        local isValid = false
        for _, vehicleConfig in pairs(Config.Vehicles) do
            if Config.Vehicles[_][jobCache.name][GetEntityModel(vehicle)] then
                isValid = true
            end
        end
        return isValid
    end
    
    -- Check specific vehicle type
    if not Config.Vehicles[vehicleType][jobCache.name] then
        return false
    end
    
    return Config.Vehicles[vehicleType][jobCache.name][GetEntityModel(vehicle)] ~= nil
end

-- Toggle radar display
RegisterCommand(Config.Commands.VehicleRadar.cmd, function()
    if IsNuiFocused() then
        return
    end
    
    local currentVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local speedMultiplier = Config.SpeedType == "kmh" and 3.6 or 2.23694
    
    if currentVehicle ~= 0 and IsVehicleValid("car", currentVehicle, true) then
        radarActive = not radarActive
        radarVisible = true
        
        if radarActive then
            Citizen.CreateThread(function()
                SendNUIMessage({
                    action = "showalpr",
                    metric = Config.SpeedType
                })
                
                while radarActive do
                    Citizen.Wait(100)
                    
                    currentVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    
                    if currentVehicle ~= 0 then
                        if not radarVisible and IsVehicleValid("car", currentVehicle) then
                            radarVisible = true
                            SendNUIMessage({action = "showalpr"})
                        end
                        
                        -- Calculate detection zones
                        local vehPos = GetOffsetFromEntityInWorldCoords(currentVehicle, 0.0, 1.0, 1.0)
                        local frontPos = GetOffsetFromEntityInWorldCoords(currentVehicle, 0.0, 105.0, 0.0)
                        local rearPos = GetOffsetFromEntityInWorldCoords(currentVehicle, 0.0, -105.0, 0.0)
                        
                        -- Raycast for vehicles in front
                        local _, _, _, _, frontVehicle = GetShapeTestResult(
                            StartShapeTestCapsule(vehPos, frontPos, 3.0, 10, currentVehicle, 7)
                        )
                        
                        -- Raycast for vehicles behind
                        local _, _, _, _, rearVehicle = GetShapeTestResult(
                            StartShapeTestCapsule(vehPos, rearPos, 3.0, 10, currentVehicle, 7)
                        )
                        
                        -- Process front vehicle
                        if IsEntityAVehicle(frontVehicle) then
                            local model = GetEntityModel(frontVehicle)
                            local vehicleName = Config.CustomCarLabels[model] or 
                                              GetLabelText(GetDisplayNameFromVehicleModel(model))
                            
                            frontVehicleData = {
                                name = vehicleName,
                                plate = GetVehiclePlate(frontVehicle),
                                kmh = math.floor(GetEntitySpeed(frontVehicle) * speedMultiplier)
                            }
                        else
                            frontVehicleData = false
                        end
                        
                        -- Process rear vehicle
                        if IsEntityAVehicle(rearVehicle) then
                            local model = GetEntityModel(rearVehicle)
                            local vehicleName = Config.CustomCarLabels[model] or 
                                              GetLabelText(GetDisplayNameFromVehicleModel(model))
                            
                            rearVehicleData = {
                                name = vehicleName,
                                plate = GetVehiclePlate(rearVehicle),
                                kmh = math.floor(GetEntitySpeed(rearVehicle) * speedMultiplier)
                            }
                        else
                            rearVehicleData = false
                        end
                        
                        -- Update UI with vehicle data
                        if not radarLocked then
                            SendNUIMessage({
                                action = "alpr",
                                finfo = frontVehicleData,
                                rinfo = rearVehicleData
                            })
                        else
                            -- Only update if plate matches locked plate
                            if frontVehicleData and frontVehicleData.plate == frontLockedPlate then
                                SendNUIMessage({action = "alpr", finfo = frontVehicleData})
                            elseif rearVehicleData and rearVehicleData.plate == rearLockedPlate then
                                SendNUIMessage({action = "alpr", finfo = rearVehicleData})
                            end
                        end
                    else
                        if radarVisible then
                            radarVisible = false
                            SendNUIMessage({action = "hidealpr"})
                        end
                        break
                    end
                end
                
                SendNUIMessage({action = "hidealpr"})
            end)
        end
    end
end)

-- Lock radar to current reading
RegisterCommand(Config.Commands.LockRadar.cmd, function()
    if IsNuiFocused() then
        return
    end
    
    local currentVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    if currentVehicle ~= 0 and radarActive then
        radarLocked = not radarLocked
        SendNUIMessage({
            action = "balpr",
            block = radarLocked
        })
        
        frontLockedPlate = (frontVehicleData and frontVehicleData.plate) or ""
        rearLockedPlate = (rearVehicleData and rearVehicleData.plate) or ""
    end
end)

-- Move radar position
RegisterCommand(Config.Commands.MoveRadar.cmd, function()
    if not radarActive then
        return
    end
    
    SetNuiFocus(true, true)
end)

-- Register key mappings
RegisterKeyMapping(Config.Commands.VehicleRadar.cmd, 
    Config.Commands.VehicleRadar.description, 
    "keyboard", 
    Config.Commands.VehicleRadar.key)

RegisterKeyMapping(Config.Commands.LockRadar.cmd, 
    Config.Commands.LockRadar.description, 
    "keyboard", 
    Config.Commands.LockRadar.key)

RegisterKeyMapping(Config.Commands.MoveRadar.cmd, 
    Config.Commands.MoveRadar.description, 
    "keyboard", 
    Config.Commands.MoveRadar.key)