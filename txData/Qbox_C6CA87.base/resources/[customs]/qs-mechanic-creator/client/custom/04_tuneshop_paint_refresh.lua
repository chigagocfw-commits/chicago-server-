-- Paint refresh + tuneshop visual helpers (leak rebuild)

local function normalizePlate(plate)
    if not plate or plate == '' then return nil end
    return (string.gsub(plate, '^%s*(.-)%s*$', '%1'))
end

local function platesMatch(a, b)
    if not a or not b then return false end
    return normalizePlate(a) == normalizePlate(b)
end

RegisterNetEvent('qs-mechanic-creator:client:refreshPaintForPlate', function(plate, props)
    if not plate or not props then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or not DoesEntityExist(veh) then return end
    if not platesMatch(GetVehicleNumberPlateText(veh), plate) then return end
    pcall(lib.setVehicleProperties, veh, props)
    local tint = props.windowTint
    if tint == nil or tint == -1 then tint = 0 end
    pcall(SetVehicleWindowTint, veh, tint)
end)
