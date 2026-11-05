-- Carlift stream in stream/ — non sostituire modelli a startup (ytyp non ancora registrato)

Config.CarliftModels = Config.CarliftModels or {}

local DEFAULTS = {
    detectionRadius = 2.0,
    interactionRadius = 5.0,
    liftHeight = 2.5,
    vehicleZOffset = 0.40,
    armOffset = { x = -0.3, y = 0.3, z = -0.08 },
}

for key, value in pairs(DEFAULTS) do
    if Config.CarliftModels[key] == nil then
        Config.CarliftModels[key] = value
    end
end

-- Dopo che il client ha caricato gli asset stream
CreateThread(function()
    Wait(3000)
    local models = Config.CarliftModels
    local pole = models.pole or 'qs-carlift'
    local arm = models.arm or 'qs-carlift-platform'
    if IsModelValid(joaat(pole)) and IsModelValid(joaat(arm)) then
        return
    end
    print('^1[qs-mechanic-creator]^0 Modelli qs-carlift non validi dopo 3s — verifica stream/qs-carlift.ytyp nel manifest e restart resource.')
end)

-- Re-normalize shops on client after sync (creator JSON variants)
local function copyCoords(c)
    if type(c) ~= 'table' then return nil end
    if c.coords then
        return copyCoords(c.coords)
    end
    if c.position then
        return copyCoords(c.position)
    end
    local x = tonumber(c.x)
    local y = tonumber(c.y)
    local z = tonumber(c.z)
    if x and y and z then
        return {
            x = x + 0.0,
            y = y + 0.0,
            z = z + 0.0,
            w = tonumber(c.w or c.heading) or 0.0,
        }
    end
    if c[1] and c[2] and c[3] then
        return {
            x = tonumber(c[1]) + 0.0,
            y = tonumber(c[2]) + 0.0,
            z = tonumber(c[3]) + 0.0,
            w = tonumber(c[4]) or 0.0,
        }
    end
    return nil
end

local function normalizeLocationList(list)
    if type(list) ~= 'table' then return nil end
    local out = {}
    local n = #list
    if n > 0 then
        for i = 1, n do
            local c = copyCoords(list[i])
            if c then out[#out + 1] = c end
        end
    else
        for _, loc in pairs(list) do
            local c = copyCoords(loc)
            if c then out[#out + 1] = c end
        end
    end
    return #out > 0 and out or nil
end

local function normalizeShop(shop)
    if type(shop) ~= 'table' then return shop end
    shop.shopConfig = shop.shopConfig or {}
    local sc = shop.shopConfig

    if shop.coords and not sc.coords then
        sc.coords = copyCoords(shop.coords)
    end
    if sc.coords then
        local c = copyCoords(sc.coords)
        if c then
            sc.coords = c
            shop.coords = c
        end
    end

    if sc.tuneshopLocations and not shop.tuneshopLocations then
        shop.tuneshopLocations = sc.tuneshopLocations
    end
    if shop.tuneshopLocations and not sc.tuneshopLocations then
        sc.tuneshopLocations = shop.tuneshopLocations
    end

    local ts = shop.tuneshop or sc.tuneshop
    if ts then
        local locs = normalizeLocationList(ts.locations)
            or (copyCoords(ts.coords) and { copyCoords(ts.coords) })
        if locs then
            shop.tuneshopLocations = shop.tuneshopLocations or locs
            sc.tuneshopLocations = sc.tuneshopLocations or locs
        end
    end

    if sc.tuneshopLocations then
        local locs = normalizeLocationList(sc.tuneshopLocations)
        if locs then
            shop.tuneshopLocations = locs
            sc.tuneshopLocations = locs
        end
    end
    if shop.tuneshopLocations then
        local locs = normalizeLocationList(shop.tuneshopLocations)
        if locs then
            shop.tuneshopLocations = locs
            sc.tuneshopLocations = locs
        end
    end

    if not sc.carlift and shop.carlift then
        sc.carlift = shop.carlift
    end
    local cl = sc.carlift
    if cl then
        if cl.enabled == nil then cl.enabled = true end
        local clLocs = normalizeLocationList(cl.locations)
            or (copyCoords(cl.coords) and { copyCoords(cl.coords) })
            or (copyCoords(cl.location) and { copyCoords(cl.location) })
        if clLocs then
            cl.locations = clLocs
        end
        sc.carlift = cl
        shop.carlift = cl
    end
    return shop
end

RegisterNetEvent('qs-mechanic-creator:client:syncShops', function(shops)
    if type(shops) ~= 'table' then return end
    for id, shop in pairs(shops) do
        shops[id] = normalizeShop(shop)
        if QsMechanicNormalizeShopCoords then
            shops[id] = QsMechanicNormalizeShopCoords(shops[id])
        end
    end
end)
