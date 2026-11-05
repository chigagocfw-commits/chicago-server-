-- Collision prima InitializeTuneshop (evita edit client.lua decompilato)

CreateThread(function()
    while not OpenTuneShop do
        Wait(500)
    end

    local _open = OpenTuneShop
    OpenTuneShop = function(vehicle, shop, shopId, zoneId)
        local veh = _G.tuneshopTargetVehicle
        if veh and veh ~= 0 and DoesEntityExist(veh) then
            local c = GetEntityCoords(veh)
            if c then
                local x, y, z = tonumber(c.x), tonumber(c.y), tonumber(c.z)
                if x and y and z then
                    RequestCollisionAtCoord(x, y, z)
                    local n = 0
                    while n < 60 and not HasCollisionLoadedAroundEntity(veh) do
                        n = n + 1
                        Wait(25)
                    end
                end
            end
        end
        return _open(vehicle, shop, shopId, zoneId)
    end
end)
