if not Config.VehicleKeys or Config.VehicleKeys ~= 't1ger_keys' then
    return
end

function giveVehicleKeys(vehicle, plate)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local plateText = plate or GetVehicleNumberPlateText(vehicle)

    local success = pcall(function()
        exports['t1ger_keys']:GiveTemporaryKeys(plateText, GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    end)

    if not success then
        TriggerEvent('t1ger_keys:updateKeys', plateText, true)
    end
end
