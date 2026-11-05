-- Police siren system - Client side

-- Exit if siren system is disabled
if not Config.SirensSystem then
    return
end

local vehicleSirens = {}

-- Command: Toggle lights/sirens
RegisterCommand(Config.Commands.LightsSirens.cmd, function()
    if IsNuiFocused() then
        return
    end
    
    -- Don't toggle if holding E key
    if IsDisabledControlPressed(0, 86) then
        return
    end
    
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle ~= 0 and ValidVehicles[vehicle] == true then
        -- Toggle siren state
        local currentState = IsVehicleSirenOn(vehicle)
        SetVehicleSiren(vehicle, not currentState)
        SetVehicleHasMutedSirens(vehicle, true)
        
        -- Sync with server
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        TriggerServerEvent("origen_police:server:PoliceSirenState", netId, 0)
    end
end)

RegisterKeyMapping(
    Config.Commands.LightsSirens.cmd,
    Config.Commands.LightsSirens.description,
    "keyboard",
    Config.Commands.LightsSirens.key
)

-- Command: Cycle through siren tones
RegisterCommand(Config.Commands.SirensKey.cmd, function()
    if IsNuiFocused() then
        return
    end
    
    -- Don't toggle if holding E key
    if IsDisabledControlPressed(0, 86) then
        return
    end
    
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle ~= 0 and IsVehicleSirenOn(vehicle) and ValidVehicles[vehicle] == true then
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        
        -- Determine next siren tone
        local currentSiren = vehicleSirens[netId] and vehicleSirens[netId].siren or 0
        local nextSiren = (currentSiren == 0) and 1 or 0
        
        TriggerServerEvent("origen_police:server:PoliceSirenState", netId, nextSiren)
    end
end)

RegisterKeyMapping(
    Config.Commands.SirensKey.cmd,
    Config.Commands.SirensKey.description,
    "keyboard",
    Config.Commands.SirensKey.key
)

-- Network event: Update horn state
RegisterNetEvent("origen_police:client:PoliceHornState", function(netId, hornState)
    if not vehicleSirens[netId] then
        vehicleSirens[netId] = {
            horn = hornState
        }
    else
        vehicleSirens[netId].horn = hornState
    end
    
    vehicleSirens[netId].sync = true
end)

-- Network event: Update siren state
RegisterNetEvent("origen_police:client:PoliceSirenState", function(netId, sirenTone)
    if not NetworkDoesNetworkIdExist(netId) then
        return
    end
    
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    SetVehicleHasMutedSirens(vehicle, true)
    
    if not vehicleSirens[netId] then
        vehicleSirens[netId] = {
            siren = sirenTone or 1
        }
    else
        local currentSiren = sirenTone or (vehicleSirens[netId].siren or 0) + 1
        vehicleSirens[netId].siren = currentSiren
        
        -- Wrap around to first siren if exceeded max
        if vehicleSirens[netId].siren > #Config.Sirens then
            vehicleSirens[netId].siren = 1
        end
    end
    
    vehicleSirens[netId].sync = true
end)

-- Network event: Clear vehicle siren cache
RegisterNetEvent("origen_police:client:clearcache", function(netId)
    if vehicleSirens[netId] then
        -- Release horn sound
        if vehicleSirens[netId].hornid then
            ReleaseSoundId(vehicleSirens[netId].hornid)
        end
        
        -- Release siren sound
        if vehicleSirens[netId].sirenid then
            ReleaseSoundId(vehicleSirens[netId].sirenid)
        end
        
        vehicleSirens[netId] = nil
    end
end)

-- Main siren sync thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        for netId, sirenData in pairs(vehicleSirens) do
            if sirenData.sync then
                if NetworkDoesNetworkIdExist(netId) then
                    local vehicle = NetworkGetEntityFromNetworkId(netId)
                    
                    if DoesEntityExist(vehicle) then
                        -- Handle horn
                        StopSound(sirenData.hornid)
                        ReleaseSoundId(sirenData.hornid)
                        
                        if sirenData.horn then
                            sirenData.hornid = GetSoundId()
                            PlaySoundFromEntity(sirenData.hornid, "SIRENS_AIRHORN", vehicle, 0, 0, 0)
                        else
                            if sirenData.hornid then
                                sirenData.hornid = false
                            end
                        end
                        
                        -- Handle siren
                        if sirenData.siren then
                            -- Stop current siren
                            if sirenData.sirenid then
                                StopSound(sirenData.sirenid)
                                ReleaseSoundId(sirenData.sirenid)
                                sirenData.sirenid = false
                            end
                            
                            -- Play new siren
                            local sirenSound = Config.Sirens[sirenData.siren]
                            if sirenSound then
                                sirenData.sirenid = GetSoundId()
                                PlaySoundFromEntity(sirenData.sirenid, sirenSound, vehicle, 0, 0, 0)
                            end
                        end
                    else
                        -- Vehicle doesn't exist, cleanup sounds
                        if sirenData.sirenid then
                            StopSound(sirenData.sirenid)
                            ReleaseSoundId(sirenData.sirenid)
                            sirenData.sirenid = false
                        end
                        
                        if sirenData.hornid then
                            StopSound(sirenData.hornid)
                            ReleaseSoundId(sirenData.hornid)
                            sirenData.hornid = false
                        end
                    end
                end
                
                sirenData.sync = false
            end
        end
    end
end)

-- Horn control thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        
        if vehicle > 0 and ValidVehicles[vehicle] == true then
            -- Check if horn button pressed (R/MOUSE_MIDDLE)
            if IsControlJustPressed(0, 80) then
                DisableControlAction(0, 80, true)
                
                local netId = NetworkGetNetworkIdFromEntity(vehicle)
                local sirenOn = IsVehicleSirenOn(vehicle)
                
                -- If sirens are on and have a siren tone active
                if sirenOn and vehicleSirens[netId] and vehicleSirens[netId].siren ~= 0 then
                    -- Not holding E key
                    if not IsDisabledControlPressed(0, 86) then
                        -- Turn siren off temporarily
                        TriggerServerEvent("origen_police:server:PoliceSirenState", netId)
                        
                        -- Wait while horn is held
                        while IsDisabledControlPressed(0, 80) do
                            DisableControlAction(0, 80, true)
                            Citizen.Wait(0)
                        end
                    end
                -- If sirens off or not holding E
                elseif not IsDisabledControlPressed(0, 86) then
                    -- Turn on first siren tone
                    TriggerServerEvent("origen_police:server:PoliceSirenState", netId, 1)
                    
                    -- Wait while horn is held
                    while IsDisabledControlPressed(0, 80) do
                        DisableControlAction(0, 80, true)
                        Citizen.Wait(0)
                    end
                    
                    -- Turn siren off when released
                    TriggerServerEvent("origen_police:server:PoliceSirenState", netId, 0)
                end
            end
        else
            Citizen.Wait(1000)
        end
    end
end)