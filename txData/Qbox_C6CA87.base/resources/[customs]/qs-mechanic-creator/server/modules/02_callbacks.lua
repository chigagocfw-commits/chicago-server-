-- ox_lib callbacks required by decompiled client

Mechanic.RegisterCallback('hasAdminPermission', function(src)
    return Mechanic.HasAdminPermission(src)
end)

Mechanic.RegisterCallback('getPlayerLicense', function(src)
    return Mechanic.GetPlayerLicense(src)
end)

Mechanic.RegisterCallback('getConfigs', function()
    return Mechanic.GetConfigsPayload()
end)

Mechanic.RegisterCallback('getConfig', function(_, section)
    local payload = Mechanic.GetConfigsPayload()
    return payload[section]
end)

Mechanic.RegisterCallback('initializePlayer', function(src)
    Mechanic.PushPlayerData(src)
    Mechanic.SyncShopsToPlayer(src)
    return true
end)

Mechanic.RegisterCallback('getMechanicShops', function()
    return Mechanic.GetAllShops()
end)

Mechanic.RegisterCallback('getMechanicShopsForceSync', function(src)
    Mechanic.SyncShopsToPlayer(src)
    return Mechanic.GetAllShops()
end)

Mechanic.RegisterCallback('createMechanic', function(src, shopData)
    if not Mechanic.HasAdminPermission(src) then
        return false
    end
    if type(shopData) ~= 'table' then
        return false
    end
    local shopId = shopData.id or shopData.shopId or ('shop_%s_%s'):format(os.time(), src)
    shopData.id = shopId
    if not shopData.shopConfig then
        shopData.shopConfig = {}
    end
    shopData = Mechanic.NormalizeShopData(shopData)
    Mechanic.EnsureShopOwnerEmployee(src, shopId, shopData)
    Mechanic.SaveShop(shopId, shopData)
    Mechanic.SyncShopsToAll()
    return true, shopId, Mechanic.GetAllShops(), Mechanic.BuildCarliftsMap()
end)

Mechanic.RegisterCallback('updateMechanic', function(src, shopId, shopData)
    if not Mechanic.HasAdminPermission(src) and not Mechanic.IsShopEmployee(src, shopId) then
        return false
    end
    if not shopId or type(shopData) ~= 'table' then
        return false
    end
    shopData.id = shopId
    Mechanic.SaveShop(shopId, shopData)
    Mechanic.SyncShopsToAll()
    return true, Mechanic.GetAllShops(), Mechanic.BuildCarliftsMap()
end)

Mechanic.RegisterCallback('deleteMechanic', function(src, shopId)
    if not Mechanic.HasAdminPermission(src) then
        return false
    end
    if not shopId or not Mechanic.Shops[shopId] then
        return false
    end
    Mechanic.DeleteShop(shopId)
    Mechanic.SyncShopsToAll()
    TriggerClientEvent('qs-mechanic-creator:client:deleteMechanicCleanup', -1, shopId)
    return true
end)

Mechanic.RegisterCallback('canPerformAction', function(src, action, data)
    local allowed = Mechanic.CanPerformActionHook(src, action, data or {})
    if allowed == true then return true end
    return false
end)

Mechanic.RegisterCallback('hasItem', function(src, item, count)
    return Mechanic.HasItem(src, item, count or 1)
end)

Mechanic.RegisterCallback('checkRadialAccess', function(src, shopId)
    if Mechanic.HasAdminPermission(src) then return true end
    local job = Mechanic.GetJob(src)
    if shopId then
        if Mechanic.IsShopEmployee(src, shopId) then return true end
        local shopJob = Mechanic.GetShopJob(shopId)
        if job and shopJob and job.name == shopJob then return true end
        return false
    end
    if job and job.name == 'mechanic' then
        return true
    end
    for id, _ in pairs(Mechanic.Shops or {}) do
        if Mechanic.IsShopEmployee(src, id) then
            return true
        end
        local shopJob = Mechanic.GetShopJob(id)
        if job and shopJob and job.name == shopJob then
            return true
        end
    end
    return false
end)

Mechanic.RegisterCallback('getPlayerShopData', function(src, shopId)
    local job = Mechanic.GetJob(src)
    if shopId then
        local shopJob = Mechanic.GetShopJob(shopId) or (job and job.name) or 'mechanic'
        return shopJob, shopId
    end
    for id, _ in pairs(Mechanic.Shops or {}) do
        if Mechanic.IsShopEmployee(src, id) then
            local shopJob = Mechanic.GetShopJob(id) or (job and job.name) or 'mechanic'
            return shopJob, id
        end
        local shopJob = Mechanic.GetShopJob(id)
        if job and shopJob and job.name == shopJob then
            return shopJob, id
        end
    end
    if job and job.name == 'mechanic' then
        local firstShopId = next(Mechanic.Shops or {})
        return 'mechanic', firstShopId
    end
    return nil, nil
end)

Mechanic.RegisterCallback('getShopItems', function(_, shopId)
    local shop = Mechanic.Shops[shopId]
    if not shop or not shop.shops or not shop.shops.items then
        return {}
    end
    return shop.shops.items
end)

Mechanic.RegisterCallback('getPlayerInventory', function(src)
    return Mechanic.GetInventory(src)
end)

Mechanic.RegisterCallback('getStashInventory', function(_, shopId, stashId)
    local key = ('%s:%s'):format(shopId or '', stashId or '')
    return Mechanic.Stashes[key] or {}
end)

Mechanic.RegisterCallback('withdrawFromStash', function(src, shopId, stashId, item, count)
    if not Mechanic.IsShopEmployee(src, shopId) and not Mechanic.HasAdminPermission(src) then
        return false
    end
    local key = ('%s:%s'):format(shopId, stashId)
    local stash = Mechanic.Stashes[key] or {}
    stash[item] = (stash[item] or 0) - (count or 1)
    if stash[item] <= 0 then stash[item] = nil end
    Mechanic.Stashes[key] = stash
    MySQL.insert.await(
        'INSERT INTO mechanic_stashes (stash_key, items) VALUES (?, ?) ON DUPLICATE KEY UPDATE items = VALUES(items)',
        { key, json.encode(stash) }
    )
    Mechanic.AddItem(src, item, count or 1)
    return true
end)

Mechanic.RegisterCallback('depositToStash', function(src, shopId, stashId, item, count)
    if not Mechanic.IsShopEmployee(src, shopId) and not Mechanic.HasAdminPermission(src) then
        return false
    end
    if not Mechanic.HasItem(src, item, count or 1) then
        return false
    end
    Mechanic.RemoveItem(src, item, count or 1)
    local key = ('%s:%s'):format(shopId, stashId)
    local stash = Mechanic.Stashes[key] or {}
    stash[item] = (stash[item] or 0) + (count or 1)
    Mechanic.Stashes[key] = stash
    MySQL.insert.await(
        'INSERT INTO mechanic_stashes (stash_key, items) VALUES (?, ?) ON DUPLICATE KEY UPDATE items = VALUES(items)',
        { key, json.encode(stash) }
    )
    return true
end)

Mechanic.RegisterCallback('getVehicleEngineConfig', function(_, plate)
    return Mechanic.GetEngineConfig(plate)
end)

Mechanic.RegisterCallback('setEngineConfig', function(_, plate, config)
    Mechanic.SaveEngineConfig(plate, config)
    return true
end)

Mechanic.RegisterCallback('vehicleHasEngine', function(_, plate)
    local cfg = Mechanic.GetEngineConfig(plate)
    -- Nessun record = motore stock GTA (auto NPC, traffico, veicoli normali)
    if not cfg then
        return true
    end
    if cfg.removed == true or cfg.hasEngine == false then
        return false
    end
    if cfg.sound then
        return true
    end
    -- {} salvato dopo removeVehicleEngine al meccanico
    if type(cfg) == 'table' and next(cfg) == nil then
        return false
    end
    return true
end)

Mechanic.RegisterCallback('getEngineStock', function(_, shopId)
    return Mechanic.EngineStock[shopId] or {}
end)

Mechanic.RegisterCallback('getPalletEngine', function(_, shopId, palletId)
    local stock = Mechanic.EngineStock[shopId] or {}
    if palletId then
        return stock[palletId]
    end
    return stock
end)

Mechanic.RegisterCallback('purchaseEngine', function(src, shopId, engineData, price)
    if not Mechanic.IsShopEmployee(src, shopId) then
        return false
    end
    price = tonumber(price) or 0
    if price > 0 and not Mechanic.RemoveMoney(src, price, 'bank') then
        return false
    end
    Mechanic.EngineStock[shopId] = Mechanic.EngineStock[shopId] or {}
    local id = engineData and (engineData.id or engineData.engineId) or ('eng_%s'):format(os.time())
    Mechanic.EngineStock[shopId][id] = engineData
    MySQL.insert.await(
        'INSERT INTO mechanic_engine_stock (shop_id, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)',
        { shopId, json.encode(Mechanic.EngineStock[shopId]) }
    )
    return true, id
end)

Mechanic.RegisterCallback('placeEngineOnPallet', function(src, shopId, palletId, engineId)
    if not Mechanic.IsShopEmployee(src, shopId) then return false end
    Mechanic.PalletEngines[('%s:%s'):format(shopId, palletId)] = engineId
    return true
end)

Mechanic.RegisterCallback('pickupEngineFromPallet', function(src, shopId, palletId)
    if not Mechanic.IsShopEmployee(src, shopId) then return false end
    local key = ('%s:%s'):format(shopId, palletId)
    local engineId = Mechanic.PalletEngines[key]
    Mechanic.PalletEngines[key] = nil
    return engineId
end)

Mechanic.RegisterCallback('returnEngineToStock', function(src, shopId, engineData)
    if not Mechanic.IsShopEmployee(src, shopId) then return false end
    Mechanic.EngineStock[shopId] = Mechanic.EngineStock[shopId] or {}
    local id = engineData and (engineData.id or ('eng_%s'):format(os.time())) or ('eng_%s'):format(os.time())
    Mechanic.EngineStock[shopId][id] = engineData
    MySQL.insert.await(
        'INSERT INTO mechanic_engine_stock (shop_id, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)',
        { shopId, json.encode(Mechanic.EngineStock[shopId]) }
    )
    return true
end)

Mechanic.RegisterCallback('returnEngineToPallet', function(src, shopId, palletId, engineData)
    Mechanic.PalletEngines[('%s:%s'):format(shopId, palletId)] = engineData
    return true
end)

Mechanic.RegisterCallback('installVehicleEngine', function(src, plate, config)
    Mechanic.SaveEngineConfig(plate, config)
    Mechanic.BroadcastClient('syncEngineStatus', plate, config)
    return true
end)

Mechanic.RegisterCallback('installCustomVehicleEngine', function(src, plate, config)
    Mechanic.SaveEngineConfig(plate, config)
    Mechanic.BroadcastClient('syncEngineStatus', plate, config)
    return true
end)

Mechanic.RegisterCallback('removeVehicleEngine', function(_, plate)
    Mechanic.SaveEngineConfig(plate, nil)
    return true
end)

Mechanic.RegisterCallback('clearVehicleEngineConfig', function(_, plate)
    Mechanic.SaveEngineConfig(plate, nil)
    return true
end)

Mechanic.RegisterCallback('getOrderModifications', function(_, orderId)
    local order = Mechanic.Orders[tonumber(orderId)]
    if not order then return nil end
    local mods = order.modifications
    if type(mods) == 'string' then
        local ok, decoded = pcall(json.decode, mods)
        mods = ok and decoded or {}
    end
    return {
        success = true,
        orderId = order.id,
        modifications = mods,
        plate = order.plate,
        total = order.total,
    }
end)

Mechanic.RegisterCallback('startInstallation', function(src, orderId, vehicleNetId)
    local order = Mechanic.Orders[tonumber(orderId)]
    if not order then
        return { success = false, message = 'Order not found' }
    end
    order.status = 'installing'
    MySQL.update.await('UPDATE mechanic_orders SET status = ? WHERE id = ?', { 'installing', order.id })
    local mods = order.modifications
    if type(mods) == 'string' then
        local ok, decoded = pcall(json.decode, mods)
        mods = ok and decoded or {}
    end
    return {
        success = true,
        order = {
            id = order.id,
            shopId = order.shop_id,
            plate = order.plate,
            vehicleNetId = vehicleNetId,
            modifications = mods,
            total = order.total,
        },
    }
end)

Mechanic.RegisterCallback('completeInstallation', function(src, orderId)
    local order = Mechanic.Orders[tonumber(orderId)]
    if not order then return false end
    order.status = 'completed'
    MySQL.update.await('UPDATE mechanic_orders SET status = ? WHERE id = ?', { 'completed', order.id })
    TriggerClientEvent('qs-mechanic-creator:client:orderPlaced', src, order.shop_id)
    return true
end)

Mechanic.RegisterCallback('getNearbyPlayers', function(src)
    local list = {}
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    for _, playerId in ipairs(GetPlayers()) do
        local pid = tonumber(playerId)
        if pid and pid ~= src then
            local tp = GetPlayerPed(pid)
            if #(coords - GetEntityCoords(tp)) < 15.0 then
                list[#list + 1] = {
                    id = pid,
                    name = GetPlayerName(pid),
                }
            end
        end
    end
    return list
end)

Mechanic.RegisterCallback('getPendingBills', function(src)
    local license = Mechanic.GetPlayerLicense(src)
    local bills = {}
    for id, bill in pairs(Mechanic.Bills) do
        if bill.status == 'pending' and bill.to_identifier == license then
            bills[#bills + 1] = {
                id = id,
                amount = bill.amount,
                reason = bill.reason,
                shopId = bill.shop_id,
            }
        end
    end
    return bills
end)

Mechanic.RegisterCallback('getBillingHistory', function(src)
    local license = Mechanic.GetPlayerLicense(src)
    local history = {}
    for id, bill in pairs(Mechanic.Bills) do
        if bill.to_identifier == license or bill.from_identifier == license then
            history[#history + 1] = {
                id = id,
                amount = bill.amount,
                reason = bill.reason,
                status = bill.status,
                shopId = bill.shop_id,
            }
        end
    end
    return history
end)

Mechanic.RegisterCallback('getPendingVehicleRestores', function()
    return Mechanic.PendingRestores
end)

Mechanic.RegisterCallback('confirmItemUse', function(src, item)
    if Mechanic.HasItem(src, item, 1) then
        Mechanic.RemoveItem(src, item, 1)
        return true
    end
    return false
end)

Mechanic.RegisterEvent('confirmItemUse', function(src, item)
    if Mechanic.HasItem(src, item, 1) then
        Mechanic.RemoveItem(src, item, 1)
    end
end)

Mechanic.RegisterCallback('checkCarliftAccess', function(src, liftKey)
    return Mechanic.CanUseCarlift(src, liftKey)
end)

lib.callback.register('qs-mechanic-creator:getVehiclesPrices', function()
    return {}
end)
