-- Police vehicle confiscation/impound system - Server side

-- Exit if confiscate system is disabled
if not Config.Confiscate then
    return
end

-- Callback: Get player's confiscated vehicles
FW_CreateCallback("origen_police:server:GetPlayerConfiscatedVehicles", function(source, cb)
    local player = FW_GetPlayer(source)
    local citizenId = false
    
    if player and player.PlayerData and player.PlayerData.citizenid then
        citizenId = player.PlayerData.citizenid
    end
    
    cb(GetConfiscatedVehiclesByOwner(citizenId))
end)

-- Callback: Take out confiscated vehicle (pay and retrieve)
FW_CreateCallback("origen_police:server:TakeOutConfiscatedVehicle", function(source, cb, vehiclePlate)
    local player = FW_GetPlayer(source)
    local citizenId = player and player.PlayerData and player.PlayerData.citizenid
    
    -- Get vehicle bill price
    local vehicleData = GetConfiscatedVehicleByPlate(vehiclePlate)
    local billPrice = vehicleData.billPrice
    
    -- Process payment and release vehicle
    cb(PayConfiscatedVehicle(citizenId, vehiclePlate, billPrice))
end)

-- Server event: Impound/confiscate vehicle
RegisterNetEvent("origen_police:server:Impound", function(vehiclePlate, billPrice)
    local src = source
    
    -- Default bill price to 0 if not provided
    if not billPrice then
        billPrice = 0
    end
    
    -- Confiscate the vehicle
    ConfiscateVehicle(
        2,                              -- Type: 2 = confiscated
        vehiclePlate,                   -- Vehicle plate
        Config.ConfiscateParkName,      -- Impound location name
        billPrice,                      -- Bill amount
        src                             -- Source player
    )
end)