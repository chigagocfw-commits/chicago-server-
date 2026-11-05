-- MLO tuneshop: non usare SetVehicleOnGroundProperly (snap al terreno esterno = sotto mappa)

local _SetVehicleOnGroundProperly = SetVehicleOnGroundProperly

function SetVehicleOnGroundProperly(vehicle)
    if _G.QsTuneshopSuppressFocusPos then
        return false
    end
    return _SetVehicleOnGroundProperly(vehicle)
end
