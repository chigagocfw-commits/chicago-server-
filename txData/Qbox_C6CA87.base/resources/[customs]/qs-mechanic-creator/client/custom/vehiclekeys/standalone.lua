if Config.VehicleKeys and Config.VehicleKeys ~= 'standalone' then
    return
end

function giveVehicleKeys(vehicle, plate)
    if not vehicle or not DoesEntityExist(vehicle) then return end
end
