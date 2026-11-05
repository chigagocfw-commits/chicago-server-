if not Config.VehicleKeys or Config.VehicleKeys ~= 'lunar_keys' then
    return
end

function giveVehicleKeys(vehicle, plate)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local plateText = plate or GetVehicleNumberPlateText(vehicle)

    TriggerServerEvent('lunar_keys:giveKey', plateText)
end
