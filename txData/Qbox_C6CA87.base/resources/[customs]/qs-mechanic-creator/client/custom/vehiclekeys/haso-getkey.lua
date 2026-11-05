if not Config.VehicleKeys or Config.VehicleKeys ~= 'haso-getkey' then
    return
end

function giveVehicleKeys(vehicle, plate)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local plateText = plate or GetVehicleNumberPlateText(vehicle)
    local key = exports["haso-getkey"]:GetKey()
    TriggerEvent("vehiclekeys:client:SetOwner", plateText, key)
end
