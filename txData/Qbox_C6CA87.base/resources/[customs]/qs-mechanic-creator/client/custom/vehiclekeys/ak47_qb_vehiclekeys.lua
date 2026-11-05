if not Config.VehicleKeys or Config.VehicleKeys ~= 'ak47_qb_vehiclekeys' then
    return
end

function giveVehicleKeys(vehicle, plate)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local plateText = plate or GetVehicleNumberPlateText(vehicle)

    -- ak47_qb_vehiclekeys uses exports for key management
    -- Client-side export: GiveKey(plate, localvehicle)
    -- localvehicle = false for owned vehicles, true for temporary/unowned
    exports['ak47_qb_vehiclekeys']:GiveKey(plateText, false)
end

function removeVehicleKeys(vehicle, plate)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local plateText = plate or GetVehicleNumberPlateText(vehicle)

    exports['ak47_qb_vehiclekeys']:RemoveKey(plateText, false)
end

function hasVehicleKeys(vehicle, plate)
    if not vehicle or not DoesEntityExist(vehicle) then return false end

    local plateText = plate or GetVehicleNumberPlateText(vehicle)

    return exports['ak47_qb_vehiclekeys']:HasKey(plateText)
end

-- Give virtual/temporary key access
function giveVirtualVehicleKeys(vehicle, plate)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local plateText = plate or GetVehicleNumberPlateText(vehicle)

    exports['ak47_qb_vehiclekeys']:GiveVirtualKey(plateText)
end

-- Remove virtual/temporary key access
function removeVirtualVehicleKeys(vehicle, plate)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local plateText = plate or GetVehicleNumberPlateText(vehicle)

    exports['ak47_qb_vehiclekeys']:RemoveVirtualKey(plateText)
end
