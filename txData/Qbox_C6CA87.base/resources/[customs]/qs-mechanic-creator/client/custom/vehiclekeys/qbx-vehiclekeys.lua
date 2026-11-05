if not Config.VehicleKeys or Config.VehicleKeys ~= 'qbx-vehiclekeys' then
    return
end

function giveVehicleKeys(vehicle, plate)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local plateText = plate or GetVehicleNumberPlateText(vehicle)

    local success = pcall(function()
        exports.qbx_vehiclekeys:GiveKeys(plateText)
    end)

    if not success then
        TriggerEvent('qbx_vehiclekeys:client:AddKeys', plateText)
    end
end
