if not Config.VehicleKeys or Config.VehicleKeys ~= 'cd_garage' then
    return
end

function giveVehicleKeys(vehicle, plate)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    TriggerEvent('cd_garage:AddKeys', vehicle)
end
