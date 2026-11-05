-- Police siren system - Server side

-- Exit if siren system is disabled
if not Config.SirensSystem then
    return
end

local activeVehicles = {}

-- Server event: Update horn state
RegisterServerEvent("origen_police:server:PoliceHornState", function(netId, hornState)
    -- Broadcast horn state to all clients
    TriggerClientEvent("origen_police:client:PoliceHornState", -1, netId, hornState)
    
    -- Track active vehicle
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    activeVehicles[netId] = vehicle
end)

-- Server event: Update siren state
RegisterServerEvent("origen_police:server:PoliceSirenState", function(netId, sirenTone)
    -- Broadcast siren state to all clients
    TriggerClientEvent("origen_police:client:PoliceSirenState", -1, netId, sirenTone)
    
    -- Track active vehicle
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    activeVehicles[netId] = vehicle
end)

-- Cleanup thread: Remove deleted vehicles from cache
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(20000) -- Check every 20 seconds
        
        if activeVehicles ~= nil then
            for netId, vehicle in pairs(activeVehicles) do
                if not DoesEntityExist(vehicle) then
                    -- Remove from tracking
                    activeVehicles[netId] = nil
                    
                    -- Tell clients to clear cache
                    TriggerClientEvent("origen_police:client:clearcache", -1, netId)
                end
            end
        end
    end
end)