if not Config.VehicleKeys or Config.VehicleKeys ~= 'mri_Qcarkeys' then
    return
end

function giveVehicleKeys(vehicle, plate)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local plateText = plate or GetVehicleNumberPlateText(vehicle)

    local success = pcall(function()
        exports.mri_Qcarkeys:GiveKeyItem(plateText, vehicle)
    end)

    if not success and Config.Debug then
        print('[qs-mechanic-creator] Failed to give keys via mri_Qcarkeys')
    end
end

function removeVehicleKeys(vehicle, plate)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local plateText = plate or GetVehicleNumberPlateText(vehicle)

    local success = pcall(function()
        exports.mri_Qcarkeys:RemoveKeyItem(plateText, vehicle)
    end)

    if not success and Config.Debug then
        print('[qs-mechanic-creator] Failed to remove keys via mri_Qcarkeys')
    end
end

