QBX = {}

---@diagnostic disable-next-line: missing-fields
QBX.PlayerData = {}
QBX.Shared = require 'shared.main'
QBX.IsLoggedIn = false

---@return table<string, Vehicle>
---@overload fun(key: string): Vehicle
function GetVehiclesByName(key)
    local vehicles = QBX.Shared.Vehicles
    return vehicles[key] or vehicles
end

exports('GetVehiclesByName', GetVehiclesByName)

---@return table<number, Vehicle>
---@overload fun(key: number): Vehicle
function GetVehiclesByHash(key)
    local vehicles = QBX.Shared.VehicleHashes
    return vehicles[key] or vehicles
end

exports('GetVehiclesByHash', GetVehiclesByHash)

---@return table<string, Vehicle[]>
function GetVehiclesByCategory()
    return qbx.table.mapBySubfield(QBX.Shared.Vehicles, 'category')
end

exports('GetVehiclesByCategory', GetVehiclesByCategory)

---@return table<number, Weapon>
---@overload fun(key: number): Weapon
function GetWeapons(key)
    local weapons = QBX.Shared.Weapons
    return weapons[key] or weapons
end

exports('GetWeapons', GetWeapons)

---@deprecated
---@return table<string, vector4>
function GetLocations()
    return QBX.Shared.Locations
end

---@diagnostic disable-next-line: deprecated
exports('GetLocations', GetLocations)

AddStateBagChangeHandler('isLoggedIn', ('player:%s'):format(cache.serverId), function(_, _, value)
    QBX.IsLoggedIn = value
end)

lib.callback.register('qbx_core:client:setHealth', function(health)
    SetEntityHealth(cache.ped, health)
end)

local function formatMoney(amount)
    amount = tonumber(amount) or 0
    local isNeg = amount < 0
    local absVal = math.abs(math.floor(amount))
    local formatted = (lib.math and lib.math.groupdigits) and lib.math.groupdigits(absVal) or tostring(absVal)
    if isNeg then
        return '-' .. formatted .. '$'
    end
    return formatted .. '$'
end

function UpdatePauseMenuHeader()
    local cash = 0
    if GetResourceState('ox_inventory') == 'started' then
        local oxCash = exports.ox_inventory:Search('count', 'money')
        if oxCash ~= nil then
            cash = oxCash
        end
    elseif QBX and QBX.PlayerData and QBX.PlayerData.money then
        cash = QBX.PlayerData.money.cash or 0
    end

    local bank = 0
    if QBX and QBX.PlayerData and QBX.PlayerData.money then
        bank = QBX.PlayerData.money.bank or 0
    end

    local serverId = cache.serverId or GetPlayerServerId(PlayerId())
    local bankColor = bank < 0 and '~r~' or '~b~'
    local header = ('CHICAGO RP ~s~| ~g~Cash: %s ~s~| %sBanque: %s ~s~| ~c~[ID: %s]'):format(
        formatMoney(cash),
        bankColor,
        formatMoney(bank),
        serverId
    )
    AddTextEntry('FE_THDR_GTAO', header)

    pcall(function()
        StatSetInt(`MP0_WALLET_BALANCE`, math.floor(cash), true)
        StatSetInt(`MP1_WALLET_BALANCE`, math.floor(cash), true)
        StatSetInt(`BANK_BALANCE`, math.floor(bank), true)
    end)
end

CreateThread(function()
    AddTextEntry('PM_SCR_MAP', 'Carte de la Ville')
    AddTextEntry('PM_PANE_LEAVE', 'Se deconnecter')
    AddTextEntry('PM_PANE_QUIT', 'Quitter vers le Bureau')

    local wasPaused = false
    while true do
        local isPaused = IsPauseMenuActive()
        if isPaused and not wasPaused then
            UpdatePauseMenuHeader()
        end
        wasPaused = isPaused
        Wait(isPaused and 250 or 500)
    end
end)

CreateThread(function()
    for _, v in pairs(GetVehiclesByName()) do
        if v.model and v.name then
            local gameName = GetDisplayNameFromVehicleModel(v.model)
            if gameName and gameName ~= 'CARNOTFOUND' then
                AddTextEntryByHash(joaat(gameName), v.name)
            else
                lib.print.warn(('Could not find gameName value in vehicles.meta for vehicle model %s'):format(v.model))
            end
        end
    end
end)

lib.callback.register('qbx_core:client:getVehicleClasses', function()
    local models = GetAllVehicleModels()
    local classes = {}
    for i = 1, #models do
        local model = models[i]
        local class = GetVehicleClassFromName(model)
        classes[joaat(model)] = class
    end
    return classes
end)
