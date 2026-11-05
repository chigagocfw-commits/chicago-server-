-- Registra subito refreshPaintForPlate (ox_lib) — evita spam client se il poll decompilato chiama ancora lib.callback

local REFRESH_CB = 'qs-mechanic-creator:server:refreshPaintForPlate'

local function getModsForPlate(plate)
    if not plate or plate == '' then return nil end
    if Mechanic and Mechanic.GetVehicleMods then
        return Mechanic.GetVehicleMods(plate)
    end
    return nil
end

lib.callback.register(REFRESH_CB, function(_, plate)
    return getModsForPlate(plate)
end)
