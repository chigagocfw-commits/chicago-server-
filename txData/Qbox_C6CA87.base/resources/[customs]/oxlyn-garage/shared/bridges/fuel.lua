

-- Client only
if IsDuplicityVersion() then
    return
end

Fuel = Fuel or {}

---------------------------------------------------------------------
-- Supported fuel resources
---------------------------------------------------------------------

-- Most fuel scripts expose exports:GetFuel(vehicle) / exports:SetFuel(vehicle, level)
local function exportProvider(resource, getName, setName)
    return {
        id = resource,
        resource = resource,
        get = function(vehicle)
            local resourceExports = exports[resource]
            return resourceExports[getName or "GetFuel"](resourceExports, vehicle)
        end,
        set = function(vehicle, level)
            local resourceExports = exports[resource]
            resourceExports[setName or "SetFuel"](resourceExports, vehicle, level)
        end,
    }
end

local providers = {
    -- ox_fuel stores fuel in the vehicle's state bag
    {
        id = "ox_fuel",
        resource = "ox_fuel",
        get = function(vehicle)
            return Entity(vehicle).state.fuel
        end,
        set = function(vehicle, level)
            Entity(vehicle).state:set("fuel", level, true)
        end,
    },
    exportProvider("LegacyFuel"),
    exportProvider("cdn-fuel"),
    exportProvider("ps-fuel"),
    exportProvider("lc_fuel"),
    exportProvider("okokGasStation"),
    exportProvider("x-fuel"),
    exportProvider("ti_fuel", "getfuel", "setfuel"),
    exportProvider("nd_fuel"),
    exportProvider("rcore_fuel"),
}

---------------------------------------------------------------------
-- Provider resolution (cached)
---------------------------------------------------------------------

local cachedProvider = nil
local cachedSystem = nil

local providerResources = {}
for _, provider in ipairs(providers) do
    providerResources[provider.resource] = true
end

-- Invalidate the cache whenever a known fuel resource starts or stops
local function onResourceChange(resourceName)
    if providerResources[resourceName] then
        cachedProvider = nil
    end
end

AddEventHandler("onClientResourceStart", onResourceChange)
AddEventHandler("onClientResourceStop", onResourceChange)

-- Returns the active provider, or nil to fall back to native fuel.
-- Config.Fuel.system can be "auto" (default), "native", or a provider id.
local function getProvider()
    local system = (Config and Config.Fuel and Config.Fuel.system) or "auto"

    if cachedSystem ~= system then
        cachedSystem = system
        cachedProvider = nil
    end

    if system == "native" then
        return nil
    end

    if cachedProvider and GetResourceState(cachedProvider.resource) == "started" then
        return cachedProvider
    end
    cachedProvider = nil

    for _, provider in ipairs(providers) do
        if system == "auto" or system == provider.id then
            if GetResourceState(provider.resource) == "started" then
                cachedProvider = provider
                return provider
            end
        end
    end

    return nil
end

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

-- Converts a value to a float in 0-100, or nil if it isn't a usable number.
local function normaliseFuel(value)
    local number = tonumber(value)
    if not number or number ~= number or number == math.huge or number == -math.huge then
        return nil
    end
    return Utils.Clamp(number, 0, 100) + 0.0
end

---------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------

-- Reads fuel from the active provider, then the state bag, then the native level.
-- Returns 100.0 if the vehicle is invalid or nothing yields a value.
function Fuel.Get(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then
        return 100.0
    end

    local provider = getProvider()
    if provider then
        local ok, value = pcall(provider.get, vehicle)
        local level = ok and normaliseFuel(value)
        if level then
            return level
        end
    end

    local ok, value = pcall(function()
        return Entity(vehicle).state.fuel
    end)
    local level = ok and normaliseFuel(value)
    if level then
        return level
    end

    return normaliseFuel(GetVehicleFuelLevel(vehicle)) or 100.0
end

-- Writes fuel to the native level, the state bag, and the active provider.
-- An invalid level falls back to the vehicle's current fuel.
function Fuel.Set(vehicle, level)
    if not vehicle or not DoesEntityExist(vehicle) then
        return
    end

    level = normaliseFuel(level) or Fuel.Get(vehicle)

    SetVehicleFuelLevel(vehicle, level)

    pcall(function()
        Entity(vehicle).state:set("fuel", level, true)
    end)

    local provider = getProvider()
    if provider then
        pcall(provider.set, vehicle, level)
    end
end

