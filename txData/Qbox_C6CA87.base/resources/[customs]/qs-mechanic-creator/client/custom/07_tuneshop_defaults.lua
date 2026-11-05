-- Default tuneshop category flags (NUI reads shopData.categorys.* === true)

local DEFAULT_CATEGORYS = {
    performance = true,
    cosmetics = true,
    wheels = true,
    respray = true,
    repairs = true,
}

local function mergeCategorys(cat)
    local out = {}
    if type(cat) == 'table' then
        for k, v in pairs(cat) do
            if v == true or v == 1 or v == 'true' or v == '1' then
                out[k] = true
            elseif v == false or v == 0 or v == 'false' or v == '0' then
                out[k] = false
            end
        end
    end
    for k in pairs(DEFAULT_CATEGORYS) do
        if out[k] == nil then
            out[k] = true
        end
    end
    return out
end

function QsMechanicEnsureTuneshopCategorys(shop)
    if type(shop) ~= 'table' then return shop end
    shop.shopConfig = shop.shopConfig or {}
    local sc = shop.shopConfig
    sc.categorys = mergeCategorys(sc.categorys)
    shop.categorys = mergeCategorys(shop.categorys)
    if type(shop.tuneshopLocations) == 'table' then
        for i = 1, #shop.tuneshopLocations do
            local loc = shop.tuneshopLocations[i]
            if type(loc) == 'table' then
                loc.categorys = mergeCategorys(loc.categorys)
            end
        end
    end
    if type(sc.tuneshopLocations) == 'table' then
        for i = 1, #sc.tuneshopLocations do
            local loc = sc.tuneshopLocations[i]
            if type(loc) == 'table' then
                loc.categorys = mergeCategorys(loc.categorys)
            end
        end
    end
    return shop
end

local function normalizeHeading(h)
    local n = tonumber(h)
    if n then return n + 0.0 end
    return nil
end

function QsMechanicSetTuneshopTargetHeading(heading)
    local n = normalizeHeading(heading)
    if n then
        _G.tuneshopTargetHeading = n
    else
        _G.tuneshopTargetHeading = nil
    end
end

RegisterNetEvent('qs-mechanic-creator:client:syncShops', function(shops)
    if type(shops) ~= 'table' then return end
    for id, shop in pairs(shops) do
        shops[id] = QsMechanicEnsureTuneshopCategorys(shop)
    end
end)

CreateThread(function()
    while not createLocationSpecificShop do
        Wait(200)
    end
    local _create = createLocationSpecificShop
    createLocationSpecificShop = function(shop, locIndex)
        if type(shop) == 'table' then
            shop = QsMechanicEnsureTuneshopCategorys(shop)
        end
        return _create(shop, locIndex)
    end
end)

CreateThread(function()
    while not OpenTuneShop do
        Wait(200)
    end
    local _open = OpenTuneShop
    OpenTuneShop = function(vehicle, shop, shopId, zoneId)
        if type(shop) == 'table' then
            shop = QsMechanicEnsureTuneshopCategorys(shop)
        end
        if _G.tuneshopTargetHeading ~= nil then
            QsMechanicSetTuneshopTargetHeading(_G.tuneshopTargetHeading)
        end
        return _open(vehicle, shop, shopId, zoneId)
    end
end)
