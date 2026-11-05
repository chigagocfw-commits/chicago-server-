-- Normalize creator shop JSON + carlift/tuneshop sync fixes (leak rebuild)

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

function Mechanic.NormalizeShopData(shop)
    if type(shop) ~= 'table' then return shop end

    shop.shopConfig = shop.shopConfig or {}
    local sc = shop.shopConfig

    if shop.coords and not sc.coords then
        sc.coords = copyCoords(shop.coords)
    end

    local tuneshop = shop.tuneshop or sc.tuneshop
    if tuneshop then
        if tuneshop.enabled == nil then tuneshop.enabled = true end
        local locs = normalizeLocationList(tuneshop.locations)
            or (tuneshop.coords and { copyCoords(tuneshop.coords) })
        if locs then
            shop.tuneshopLocations = shop.tuneshopLocations or locs
            sc.tuneshopLocations = sc.tuneshopLocations or locs
        end
        sc.tuneshop = tuneshop
    end

    if sc.tuneshopLocations and not shop.tuneshopLocations then
        shop.tuneshopLocations = sc.tuneshopLocations
    end
    if shop.tuneshopLocations and not sc.tuneshopLocations then
        sc.tuneshopLocations = shop.tuneshopLocations
    end
    if shop.tuneshopLocations then
        local locs = normalizeLocationList(shop.tuneshopLocations)
        if locs then
            shop.tuneshopLocations = locs
            sc.tuneshopLocations = locs
        end
    end

    if not shop.tuneshopLocations and not sc.tuneshopLocations then
        if type(shop.points) == 'table' then
            local locs = {}
            for _, pt in ipairs(shop.points) do
                if type(pt) == 'table' then
                    local t = pt.type or pt.pointType or pt.kind
                    if t == 'tuneshop' or t == 'tuner' or pt.tuneshop then
                        local c = copyCoords(pt) or copyCoords(pt.coords)
                        if c then locs[#locs + 1] = c end
                    end
                end
            end
            if #locs > 0 then
                shop.tuneshopLocations = locs
                sc.tuneshopLocations = locs
            end
        end
    end

    if not sc.carlift then
        if shop.carlift then
            sc.carlift = shop.carlift
        elseif type(shop.carlifts) == 'table' and shop.carlifts[1] then
            sc.carlift = shop.carlifts[1]
        end
    end

    local cl = sc.carlift
    if cl then
        if cl.enabled == nil then cl.enabled = true end
        if cl.location and not cl.coords and not cl.locations then
            cl.coords = copyCoords(cl.location)
        end
        if cl.coords and not cl.locations then
            cl.locations = { copyCoords(cl.coords) }
        end
        local clLocs = normalizeLocationList(cl.locations)
        if clLocs then cl.locations = clLocs end
        sc.carlift = cl
        shop.carlift = cl
    end

    if shop.created_by and not shop.ownerLicense then
        shop.ownerLicense = shop.created_by
    end

    sc.categorys = sc.categorys or shop.categorys
    if type(sc.categorys) ~= 'table' or next(sc.categorys) == nil then
        sc.categorys = {
            performance = true,
            cosmetics = true,
            wheels = true,
            respray = true,
            repairs = true,
        }
    else
        for _, key in ipairs({ 'performance', 'cosmetics', 'wheels', 'respray', 'repairs' }) do
            if sc.categorys[key] == nil then
                sc.categorys[key] = true
            end
        end
    end
    shop.categorys = sc.categorys

    return shop
end

function Mechanic.ResolveShopId(key)
    if not key or key == '' then return nil end
    if Mechanic.Shops[key] then return key end
    local base = tostring(key):match('^(.+)_%d+$')
    if base and Mechanic.Shops[base] then return base end
    return key
end

function Mechanic.IsShopOwner(src, shopId)
    local license = Mechanic.GetPlayerLicense(src)
    if not license or not shopId then return false end
    local shop = Mechanic.Shops[shopId]
    if not shop then return false end
    local owner = shop.created_by or shop.ownerLicense
        or (shop.shopConfig and (shop.shopConfig.owner or shop.shopConfig.ownerLicense))
    return owner ~= nil and owner ~= '' and owner == license
end

function Mechanic.CanUseCarlift(src, liftKey)
    local shopId = Mechanic.ResolveShopId(liftKey)
    local shop = shopId and Mechanic.Shops[shopId]
    local cl = shop and shop.shopConfig and shop.shopConfig.carlift

    if cl and cl.public == true then
        return true
    end

    return Mechanic.HasAdminPermission(src)
        or Mechanic.IsShopOwner(src, shopId)
        or Mechanic.IsShopEmployee(src, shopId)
end

function Mechanic.EnsureShopOwnerEmployee(src, shopId, shopData)
    local license = Mechanic.GetPlayerLicense(src)
    if not license or not shopId then return end

    shopData.created_by = shopData.created_by or license
    shopData.ownerLicense = shopData.ownerLicense or license

    Mechanic.Employees[shopId] = Mechanic.Employees[shopId] or {}
    if not Mechanic.Employees[shopId][license] then
        Mechanic.Employees[shopId][license] = {
            identifier = license,
            name = GetPlayerName(src) or 'Owner',
            grade = 99,
            permissions = nil,
        }
        MySQL.insert.await(
            'INSERT INTO mechanic_employees (shop_id, identifier, name, grade) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE name = VALUES(name), grade = VALUES(grade)',
            { shopId, license, GetPlayerName(src) or 'Owner', 99 }
        )
    end
end

local _IsShopEmployee = Mechanic.IsShopEmployee
function Mechanic.IsShopEmployee(src, shopId)
    if Mechanic.IsShopOwner(src, shopId) then return true end
    return _IsShopEmployee(src, shopId)
end

local _SaveShop = Mechanic.SaveShop
function Mechanic.SaveShop(shopId, data)
    data = Mechanic.NormalizeShopData(data)
    _SaveShop(shopId, data)
end

local _LoadAll = Mechanic.LoadAll
function Mechanic.LoadAll()
    _LoadAll()
    for id, shop in pairs(Mechanic.Shops) do
        Mechanic.Shops[id] = Mechanic.NormalizeShopData(shop)
    end
end

function Mechanic.SyncCarliftsToPlayer(src)
    TriggerClientEvent('qs-mechanic-creator:client:syncCarlifts', src, Mechanic.BuildCarliftsMap())
end

function Mechanic.SyncShopsToPlayer(src)
    TriggerClientEvent('qs-mechanic-creator:client:syncShops', src, Mechanic.GetAllShops())
    Mechanic.SyncCarliftsToPlayer(src)
end

function Mechanic.SyncShopsToAll()
    TriggerClientEvent('qs-mechanic-creator:client:syncShops', -1, Mechanic.GetAllShops())
    TriggerClientEvent('qs-mechanic-creator:client:syncCarlifts', -1, Mechanic.BuildCarliftsMap())
end

Mechanic.RegisterEvent('checkCarliftAccess', function(src, liftKey)
    if not liftKey then return end
    if Mechanic.CanUseCarlift(src, liftKey) then
        TriggerClientEvent('qs-mechanic-creator:client:openCarlift', src, liftKey)
        return
    end
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Carlift',
        description = 'Non hai accesso a questo carlift',
        type = 'error',
    })
end)
