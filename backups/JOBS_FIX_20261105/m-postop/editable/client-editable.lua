RegisterNetEvent("m-postop-client:DetachHotwire")
AddEventHandler("m-postop-client:DetachHotwire", function(plate, vehicle)
    -- instead your hotwire export
    if CDM.Config.Vehiclekey then
        if CDM.Config.VehicleSystem == 'cd_garage' then
            TriggerEvent('cd_garage:AddKeys', exports['cd_garage']:GetPlate(vehicle))
        elseif CDM.Config.VehicleSystem == 'qs-vehiclekeys' then
            exports['qs-vehiclekeys']:GiveKeysAuto()
        elseif CDM.Config.VehicleSystem == 'wasabi-carlock' then
            exports.wasabi_carlock:GiveKey(plate)
        elseif CDM.Config.VehicleSystem == 'qb-vehiclekeys' then
            TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
        end
    end

    if CDM.Config.EnableFuel then
        if CDM.Config.FuelSystem == 'LegacyFuel' then
            return exports["LegacyFuel"]:SetFuel(vehicle, 100)
        elseif CDM.Config.FuelSystem == 'ox-fuel' then
            return SetVehicleFuelLevel(vehicle, 100)
        elseif CDM.Config.FuelSystem == 'nd-fuel' then
            return exports["nd-fuel"]:SetFuel(vehicle, 100)
        elseif CDM.Config.FuelSystem == 'frfuel' then
            return exports.frfuel:setFuel(vehicle, 100)
        elseif CDM.Config.FuelSystem == 'cdn-fuel' then
            return exports['cdn-fuel']:SetFuel(vehicle, 100)
        elseif CDM.Config.FuelSystem == 'hyon_gas_station' then
            return exports["hyon_gas_station"]:SetFuel(vehicle, 100)
        elseif CDM.Config.FuelSystem == 'ox-fuel' then
            return exports['x-fuel']:SetFuel(vehicle, 100)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        local wait = 1000
        if not CDM.Client.IsPackageClaimed and CDM.Client.IsJobStarted then
            if jobvehicle ~= 0 and jobvehicle ~= nil then
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)
                local vehpos = GetEntityCoords(jobvehicle)
                if #(pos - vehpos) < 4.0 and not IsPedInAnyVehicle(ped) then
                    wait = 5
                    text = "Package"
                    if #(pos - vehpos) < 3.0 and not IsPedInAnyVehicle(ped) then
                        text = "E - Package"
                        if IsControlJustPressed(0, 38) then
                            CDM.SetPackageAnim()
                        end
                    end
                    CDM.DrawText(vehpos.x, vehpos.y, vehpos.z, text)
                end
            end
        end
        Citizen.Wait(wait)
    end
end)
