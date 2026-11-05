if not Config.VehicleKeys or Config.VehicleKeys ~= 'VehicleKeyChain' then
    return
end

function giveVehicleKeys(vehicle, plate)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local plateText = plate or GetVehicleNumberPlateText(vehicle)

    TriggerEvent('VehicleKeyChain:AddKey', plateText)
end
