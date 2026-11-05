if not Config.VehicleKeys or Config.VehicleKeys ~= 'qs-vehiclekeys' then
    return
end

function giveVehicleKeys(vehicle, plate)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local plateText = plate or GetVehicleNumberPlateText(vehicle)

    local success = pcall(function()
        exports['qs-vehiclekeys']:GiveKeys(plateText, GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    end)

    if not success then
        TriggerServerEvent('qs-vehiclekeys:server:GiveVehicleKeys', plateText)
    end
end
