--[[
    Auto NPC: se il server dice "no engine" per errore, non bloccare W/Acceleratore.
    Fix principale: server callback vehicleHasEngine (vedi server/modules/02_callbacks.lua).
]]

local plateCache = {}

RegisterNetEvent('qs-mechanic-creator:client:updateEngineStatus', function(plate, hasEngine)
    if plate then
        plateCache[plate] = hasEngine
    end
end)

CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
            goto continue
        end

        local plate = GetVehicleNumberPlateText(vehicle)
        local hasEngine = plateCache[plate]

        if hasEngine == false then
            goto continue
        end

        -- Benzina a 0 su auto mondo: ripristino minimo (non tocca veicoli con fuel script attivo se già > 0)
        local fuel = GetVehicleFuelLevel(vehicle)
        if fuel ~= nil and fuel < 1.0 then
            SetVehicleFuelLevel(vehicle, 65.0)
        end

        if not GetIsVehicleEngineRunning(vehicle) then
            SetVehicleUndriveable(vehicle, false)
            SetVehicleEngineOn(vehicle, true, true, false)
        end

        ::continue::
    end
end)
