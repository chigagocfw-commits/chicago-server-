if not Config.VehicleKeys or Config.VehicleKeys ~= 'wasabi_carlock' then
    return
end

function giveVehicleKeys(vehicle, plate)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local plateText = plate or GetVehicleNumberPlateText(vehicle)

    local success = pcall(function()
        exports.wasabi_carlock:GiveKey(plateText)
    end)

    if not success then
        TriggerServerEvent('wasabi_carlock:giveKey', plateText)
    end
end
