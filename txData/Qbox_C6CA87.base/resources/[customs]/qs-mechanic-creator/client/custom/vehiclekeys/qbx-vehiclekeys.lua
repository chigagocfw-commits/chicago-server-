if not Config.VehicleKeys or Config.VehicleKeys ~= 'qbx-vehiclekeys' then
    return
end

function giveVehicleKeys(vehicle, plate)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local plateText = plate or GetVehicleNumberPlateText(vehicle)

    -- GiveKeys is a server-side export; from the client we must use the
    -- qb-vehiclekeys bridge server event which handles proximity checks.
    TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plateText)
end
