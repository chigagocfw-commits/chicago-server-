-- Normalizza coordinate tuneshop (formati creator/JSON) + wrap zone loader

local function copyCoords(c)
    if type(c) == 'string' then
        local ok, decoded = pcall(json.decode, c)
        if ok and type(decoded) == 'table' then
            c = decoded
        else
            return nil
        end
    end
    if type(c) ~= 'table' then return nil end
    if c.coords then return copyCoords(c.coords) end
    if c.position then return copyCoords(c.position) end
    if c.location then return copyCoords(c.location) end
    local x = tonumber(c.x or c.X)
    local y = tonumber(c.y or c.Y)
    local z = tonumber(c.z or c.Z)
    if x and y and z then
        return {
            x = x + 0.0,
            y = y + 0.0,
            z = z + 0.0,
            w = tonumber(c.w or c.heading or c.h or c[4]) or 0.0,
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

function QsMechanicNormalizeShopCoords(shop)
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

    local ts = shop.tuneshop or sc.tuneshop
    if ts then
        if ts.enabled == nil then ts.enabled = true end
        local locs = normalizeLocationList(ts.locations)
            or normalizeLocationList(ts.points)
            or (copyCoords(ts.coords) and { copyCoords(ts.coords) })
            or (copyCoords(ts.location) and { copyCoords(ts.location) })
        if locs then
            shop.tuneshopLocations = locs
            sc.tuneshopLocations = locs
        end
        sc.tuneshop = ts
        shop.tuneshop = ts
    end

    for _, key in ipairs({ 'tuneshopLocations', 'tuneshop_locations' }) do
        local src = shop[key] or sc[key]
        if src then
            local locs = normalizeLocationList(src)
            if locs then
                shop.tuneshopLocations = locs
                sc.tuneshopLocations = locs
            end
        end
    end

    if not shop.tuneshopLocations and not sc.tuneshopLocations and sc.coords then
        local c = copyCoords(sc.coords)
        if c then
            shop.tuneshopLocations = { c }
            sc.tuneshopLocations = { c }
        end
    end

    if type(QsMechanicEnsureTuneshopCategorys) == 'function' then
        shop = QsMechanicEnsureTuneshopCategorys(shop)
    end

    return shop
end

function QsMechanicNormalizeCoordTable(c)
    return copyCoords(c)
end

RegisterNetEvent('qs-mechanic-creator:client:syncShops', function(shops)
    if type(shops) ~= 'table' then return end
    for id, shop in pairs(shops) do
        shops[id] = QsMechanicNormalizeShopCoords(shop)
        if type(QsMechanicEnsureTuneshopCategorys) == 'function' then
            shops[id] = QsMechanicEnsureTuneshopCategorys(shops[id])
        end
    end
end)

CreateThread(function()
    while not loadTuneshopZones or not createTuneshopZone do
        Wait(200)
    end

    local _createZone = createTuneshopZone
    createTuneshopZone = function(zoneId, shop, coords, locIndex)
        coords = copyCoords(coords)
        if not coords and type(shop) == 'table' then
            shop = QsMechanicNormalizeShopCoords(shop)
            local locs = shop.tuneshopLocations or (shop.shopConfig and shop.shopConfig.tuneshopLocations)
            if locs and locs[(locIndex or 0) + 1] then
                coords = copyCoords(locs[(locIndex or 0) + 1])
            end
            if not coords then
                coords = copyCoords(shop.shopConfig and shop.shopConfig.coords)
            end
        end
        if not coords then return nil end
        return _createZone(zoneId, shop, coords, locIndex)
    end

    local _loadZones = loadTuneshopZones
    loadTuneshopZones = function(force)
        for id, shop in pairs(Config.Tuneshops or {}) do
            Config.Tuneshops[id] = QsMechanicNormalizeShopCoords(shop)
        end
        return _loadZones(force)
    end
end)
