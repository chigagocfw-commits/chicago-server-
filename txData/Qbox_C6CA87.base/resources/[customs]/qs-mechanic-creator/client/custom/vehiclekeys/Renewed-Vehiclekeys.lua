if not Config.VehicleKeys or Config.VehicleKeys ~= 'Renewed-Vehiclekeys' then
    return
end

function giveVehicleKeys(vehicle, plate)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local plateText = plate or GetVehicleNumberPlateText(vehicle)

    local success = pcall(function()
        exports['Renewed-Vehiclekeys']:addKey(plateText)
    end)

    if not success then
        TriggerEvent('Renewed-Vehiclekeys:client:addKey', plateText)
    end
end
