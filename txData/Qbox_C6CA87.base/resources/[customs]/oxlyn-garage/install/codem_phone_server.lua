

-- Install INSIDE your CodeM phone resource, after its exports/garage/server.lua.
-- Config.Valet.GarageScript = 'oxlyn-garage'
-- Config.Valet.OxlynResource = 'oxlyn-garage' -- actual OXLYN resource folder name
-- See CODEM_PHONE.md. Do not load this file in the OXLYN resource itself.
local Garage = assert(rawget(_G, 'Garage'), 'Load OXLYN adapter after CodeM exports/garage/server.lua')
local RES = (Config.Valet and Config.Valet.OxlynResource) or 'oxlyn-garage'
local PHONE = GetCurrentResourceName()
local reservations = {}
local function plateKey(plate) return tostring(plate or ''):upper():gsub('%s+', '') end
local function selected()
    return Garage.activeSystem == 'oxlyn-garage' or Garage.activeSystem == RES
end
local function call(method, ...)
    if GetResourceState(RES) ~= 'started' then return nil end
    local args = table.pack(...)
    local ok, result = pcall(function() return exports[RES][method](exports[RES], table.unpack(args, 1, args.n)) end)
    if not ok then
        print(('[%s] OXLYN %s failed: %s'):format(PHONE, method, tostring(result)))
        return nil
    end
    return result
end

local oldDetect = Garage.DetectSystem
function Garage.DetectSystem(...)
    local configured = Config.Valet and Config.Valet.GarageScript or 'auto'
    if configured == 'oxlyn-garage' or configured == RES
        or (configured == 'auto' and GetResourceState(RES) == 'started') then
        Garage.activeSystem = 'oxlyn-garage'
        return Garage.activeSystem
    end
    return oldDetect(...)
end

local oldList = Garage.GetPlayerVehicles
function Garage.GetPlayerVehicles(src, ...)
    if not selected() then return oldList(src, ...) end
    return call('GetPhoneVehicles', src, 'codem') or {}
end

local oldGet = Garage.GetVehicleData
function Garage.GetVehicleData(src, plate, ...)
    if not selected() then return oldGet(src, plate, ...) end
    -- The phone already charges its configured fee. No second OXLYN fee.
    -- CodeM chooses its node later; the trusted export derives a reference
    -- position from the player and validates the eventual entity separately.
    local data = call('PreparePhoneVehicle', src, plate, nil, nil, { charge = false })
    if type(data) ~= 'table' or data.ok ~= true or type(data.props) ~= 'table' then return nil end
    local key = plateKey(data.plate)
    local reservation = { src = tonumber(src), data = data }
    reservations[key] = reservation
    -- Native NPC delivery can run for 180 seconds before SetVehicleOutside.
    -- The OXLYN client confirms immediately after applying saved properties.
    SetTimeout(240000, function() if reservations[key] == reservation then reservations[key] = nil end end)

    local mods = {}
    for k, v in pairs(data.props) do mods[k] = v end
    -- CodeM versions may reconstruct vehicleData. Keep our reservation marker
    -- in the existing mods field, which the native adapter already forwards.
    mods.__oxlynPhone = { ok = true, oxlyn = true, plate = data.plate, key = data.key, model = data.model, spot = data.spot }
    return {
        plate = data.plate, inGarage = true, garage = data.garage,
        spawncode = data.model or data.props.model, mods = json.encode(mods),
        fuel = data.props.fuelLevel,
        statistics = { engine = (tonumber(data.props.engineHealth) or 1000) / 10,
            body = (tonumber(data.props.bodyHealth) or 1000) / 10, fuel = tonumber(data.props.fuelLevel) or 100 },
        oxlyn = true, props = data.props, spot = data.spot, key = data.key, model = data.model,
    }
end

local oldOutside = Garage.SetVehicleOutside
function Garage.SetVehicleOutside(plate, netId, ...)
    if not selected() then return oldOutside(plate, netId, ...) end
    local reservation = reservations[plateKey(plate)]
    if not reservation then return false end
    return call('ConfirmPhoneVehicle', reservation.src, plate, netId) == true
end

-- Only the requesting player can cancel its own prepared spawn. This does
-- not change arbitrary vehicle ownership/state or accept an identifier.
RegisterNetEvent(PHONE .. ':oxlynGarage:cancel', function(plate)
    local src, key = source, plateKey(plate)
    local reservation = reservations[key]
    if not reservation or reservation.src ~= src then return end
    if call('CancelPhoneVehicle', src, plate) == true then reservations[key] = nil end
end)

AddEventHandler('playerDropped', function()
    local src = source
    for key, reservation in pairs(reservations) do
        if reservation.src == src then reservations[key] = nil end
    end
end)

Garage.DetectSystem()

