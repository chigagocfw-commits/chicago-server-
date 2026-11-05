-- RegisterNetEvent handlers (TriggerServerEvent from client)

Mechanic.RegisterEvent('requestPlayerData', function(src)
    Mechanic.PushPlayerData(src)
end)

Mechanic.RegisterEvent('getMechanicShopsForceSync', function(src)
    Mechanic.SyncShopsToPlayer(src)
end)

Mechanic.RegisterEvent('saveConfig', function(src, section, data)
    if not Mechanic.HasAdminPermission(src) then return end
    if section and data then
        Mechanic.SaveConfigSection(section, data)
    end
end)

Mechanic.RegisterEvent('resetConfig', function(src, section)
    if not Mechanic.HasAdminPermission(src) then return end
    local defaults = Mechanic.DefaultConfigs()
    if defaults[section] then
        Mechanic.SaveConfigSection(section, defaults[section])
    end
end)

Mechanic.RegisterEvent('purchaseModifications', function(src, modifications, tuneshopData, shopId, vehicleInfo, modificationsWithPrices, totalPrice, paintExtras, paymentMethod)
    totalPrice = tonumber(totalPrice) or 0
    paymentMethod = paymentMethod or 'cash'
    local plate = vehicleInfo and vehicleInfo.plate
    if totalPrice > 0 and Config.ChargeOnOrder ~= false then
        if not Mechanic.RemoveMoney(src, totalPrice, paymentMethod) then
            TriggerClientEvent('qs-mechanic-creator:client:purchaseResult', src, false, modifications)
            return
        end
    end
    local orderId = MySQL.insert.await(
        'INSERT INTO mechanic_orders (shop_id, plate, customer_identifier, status, total, modifications, vehicle_data) VALUES (?, ?, ?, ?, ?, ?, ?)',
        {
            tostring(shopId or ''),
            plate and NormalizePlate(plate) or nil,
            Mechanic.GetPlayerLicense(src),
            'pending',
            totalPrice,
            json.encode(modifications or {}),
            json.encode({ vehicle = vehicleInfo, paint = paintExtras, prices = modificationsWithPrices }),
        }
    )
    orderId = tonumber(orderId)
    if orderId and orderId >= (Mechanic.NextOrderId or 1) then
        Mechanic.NextOrderId = orderId + 1
    end
    Mechanic.Orders[orderId] = {
        id = orderId,
        shop_id = tostring(shopId or ''),
        plate = plate,
        status = 'pending',
        total = totalPrice,
        modifications = json.encode(modifications or {}),
    }
    TriggerClientEvent('qs-mechanic-creator:client:purchaseResult', src, true, modifications)
    if shopId then
        TriggerClientEvent('qs-mechanic-creator:client:refreshTabletOrders', -1, shopId)
    end
end)

Mechanic.RegisterEvent('syncVehicleMods', function(src, netId, props)
    local veh = NetworkGetEntityFromNetworkId(netId)
    local plate = props and props.plate
    if not plate and veh and veh ~= 0 then
        plate = GetVehicleNumberPlateText(veh)
    end
    if plate and props then
        Mechanic.SaveVehicleMods(plate, props)
    end
    TriggerClientEvent('qs-mechanic-creator:client:applyVehicleMods', -1, netId, props)
end)

Mechanic.RegisterEvent('saveRadialRepair', function(src, plate, props)
    if plate and props then
        Mechanic.SaveVehicleMods(plate, props)
    end
end)

Mechanic.RegisterEvent('removeItem', function(src, item, count)
    Mechanic.RemoveItem(src, item, count or 1)
end)

Mechanic.RegisterEvent('buyShopItem', function(src, shopId, item, count, price)
    count = tonumber(count) or 1
    price = (tonumber(price) or 0) * count
    if price > 0 and not Mechanic.RemoveMoney(src, price, 'cash') then
        Mechanic.Notify(src, { type = 'error', description = 'Not enough money' })
        return
    end
    Mechanic.AddItem(src, item, count)
end)

Mechanic.RegisterEvent('requestTabletData', function(src, shopId)
    local data = Mechanic.BuildTabletData(shopId, src)
    if data then
        TriggerClientEvent('qs-mechanic-creator:client:updateTabletData', src, data)
    end
end)

Mechanic.RegisterEvent('hireEmployee', function(src, shopId, targetId, grade)
    if not Mechanic.IsShopEmployee(src, shopId) and not Mechanic.HasAdminPermission(src) then return end
    local target = tonumber(targetId)
    if not target then return end
    local license = Mechanic.GetPlayerLicense(target)
    if not license then return end
    Mechanic.Employees[shopId] = Mechanic.Employees[shopId] or {}
    Mechanic.Employees[shopId][license] = {
        identifier = license,
        name = GetPlayerName(target),
        grade = grade or 0,
    }
    MySQL.insert.await(
        'INSERT INTO mechanic_employees (shop_id, identifier, name, grade) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE name = VALUES(name), grade = VALUES(grade)',
        { shopId, license, GetPlayerName(target), grade or 0 }
    )
    TriggerClientEvent('qs-mechanic-creator:client:updateTabletData', src, Mechanic.BuildTabletData(shopId, src))
end)

Mechanic.RegisterEvent('hireConfirmationResponse', function() end)

Mechanic.RegisterEvent('fireEmployee', function(src, shopId, identifier)
    if not Mechanic.IsShopEmployee(src, shopId) and not Mechanic.HasAdminPermission(src) then return end
    if Mechanic.Employees[shopId] then
        Mechanic.Employees[shopId][identifier] = nil
    end
    MySQL.query.await('DELETE FROM mechanic_employees WHERE shop_id = ? AND identifier = ?', { shopId, identifier })
    TriggerClientEvent('qs-mechanic-creator:client:updateTabletData', src, Mechanic.BuildTabletData(shopId, src))
end)

Mechanic.RegisterEvent('editEmployee', function(src, shopId, identifier, data)
    if not Mechanic.IsShopEmployee(src, shopId) and not Mechanic.HasAdminPermission(src) then return end
    if Mechanic.Employees[shopId] and Mechanic.Employees[shopId][identifier] then
        for k, v in pairs(data or {}) do
            Mechanic.Employees[shopId][identifier][k] = v
        end
        MySQL.update.await(
            'UPDATE mechanic_employees SET name = ?, grade = ?, permissions = ? WHERE shop_id = ? AND identifier = ?',
            {
                Mechanic.Employees[shopId][identifier].name,
                Mechanic.Employees[shopId][identifier].grade or 0,
                json.encode(Mechanic.Employees[shopId][identifier].permissions),
                shopId,
                identifier,
            }
        )
    end
    TriggerClientEvent('qs-mechanic-creator:client:updateTabletData', src, Mechanic.BuildTabletData(shopId, src))
end)

Mechanic.RegisterEvent('saveTabletSettings', function(src, shopId, settings)
    local shop = Mechanic.Shops[shopId]
    if not shop then return end
    shop.tabletSettings = settings
    Mechanic.SaveShop(shopId, shop)
end)

Mechanic.RegisterEvent('updateShopName', function(src, shopId, name)
    local shop = Mechanic.Shops[shopId]
    if not shop then return end
    shop.shopConfig = shop.shopConfig or {}
    shop.shopConfig.name = name
    Mechanic.SaveShop(shopId, shop)
    Mechanic.SyncShopsToAll()
end)

Mechanic.RegisterEvent('sendOrderInvoice', function(src, shopId, orderId, targetId, amount)
    local order = Mechanic.Orders[tonumber(orderId)]
    if not order then return end
    amount = tonumber(amount) or order.total
    local target = tonumber(targetId)
    if not target then return end
    TriggerClientEvent('qs-mechanic-creator:client:receiveBill', target, {
        id = order.id,
        amount = amount,
        shopId = shopId,
        reason = 'Mechanic order',
    })
end)

Mechanic.RegisterEvent('refundOrder', function(src, shopId, orderId)
    local order = Mechanic.Orders[tonumber(orderId)]
    if not order then return end
    order.status = 'refunded'
    MySQL.update.await('UPDATE mechanic_orders SET status = ? WHERE id = ?', { 'refunded', order.id })
    TriggerClientEvent('qs-mechanic-creator:client:refreshTabletOrders', -1, shopId)
end)

Mechanic.RegisterEvent('societyTransaction', function() end)

Mechanic.RegisterEvent('installNitrous', function() end)

Mechanic.RegisterEvent('setTuneshopOccupied', function(src, shopKey, occupied, plate)
    Mechanic.TuneshopOccupied[shopKey] = occupied and { src = src, plate = plate } or nil
end)

Mechanic.RegisterEvent('registerVehicleInTuneshop', function(src, netIdOrPlate, shopKey)
    local netId = tonumber(netIdOrPlate)
    if not netId and type(netIdOrPlate) == 'string' then
        local ped = GetPlayerPed(src)
        if ped and ped ~= 0 then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh and veh ~= 0 then
                netId = NetworkGetNetworkIdFromEntity(veh)
            end
        end
    end
    Mechanic.TuneshopOccupied[shopKey] = { src = src, netId = netId, plate = type(netIdOrPlate) == 'string' and netIdOrPlate or nil }
end)

Mechanic.RegisterEvent('unregisterVehicleInTuneshop', function(_, shopKey)
    Mechanic.TuneshopOccupied[shopKey] = nil
end)

Mechanic.RegisterEvent('syncTuneshopVehicle', function(_, netId, x, y, z, heading)
    netId = tonumber(netId)
    if not netId then return end
    TriggerClientEvent('qs-mechanic-creator:client:syncTuneshopVehicle', -1, netId, x, y, z, heading)
end)

Mechanic.RegisterEvent('forceRestoreVehicle', function(src, plate, props)
    if plate and props then
        Mechanic.PendingRestores[NormalizePlate(plate)] = props
        Mechanic.SaveVehicleMods(plate, props)
    end
end)

Mechanic.RegisterEvent('markVehicleRestored', function(_, plate)
    if plate then
        Mechanic.PendingRestores[NormalizePlate(plate)] = nil
    end
end)

Mechanic.RegisterEvent('refreshPaintForPlate', function(src, plate)
    if not plate or plate == '' then return end
    local props = Mechanic.GetVehicleMods(plate)
    if props then
        TriggerClientEvent('qs-mechanic-creator:client:refreshPaintForPlate', src, plate, props)
    end
end)

function Mechanic.CreateBill(src, targetId, amount, reason, shopId)
    local target = tonumber(targetId)
    local toLicense = target and Mechanic.GetPlayerLicense(target)
    if not toLicense then return end
    local billId = MySQL.insert.await(
        'INSERT INTO mechanic_bills (shop_id, from_identifier, to_identifier, amount, reason, status) VALUES (?, ?, ?, ?, ?, ?)',
        { shopId, Mechanic.GetPlayerLicense(src), toLicense, amount, reason, 'pending' }
    )
    billId = tonumber(billId)
    if billId and billId >= (Mechanic.NextBillId or 1) then
        Mechanic.NextBillId = billId + 1
    end
    Mechanic.Bills[billId] = {
        id = billId,
        shop_id = shopId,
        from_identifier = Mechanic.GetPlayerLicense(src),
        to_identifier = toLicense,
        amount = amount,
        reason = reason,
        status = 'pending',
    }
    TriggerClientEvent('qs-mechanic-creator:client:receiveBill', target, Mechanic.Bills[billId])
end

Mechanic.RegisterEvent('createBill', function(src, targetId, amount, reason, shopId)
    Mechanic.CreateBill(src, targetId, amount, reason, shopId)
end)

Mechanic.RegisterEvent('payBill', function(src, billId)
    local bill = Mechanic.Bills[tonumber(billId)]
    if not bill or bill.status ~= 'pending' then return end
    if not Mechanic.RemoveMoney(src, bill.amount, 'bank') then
        Mechanic.Notify(src, { type = 'error', description = 'Not enough money' })
        return
    end
    bill.status = 'paid'
    MySQL.update.await('UPDATE mechanic_bills SET status = ? WHERE id = ?', { 'paid', bill.id })
    TriggerClientEvent('qs-mechanic-creator:client:billPaid', src, bill.id, bill.amount)
end)

Mechanic.RegisterEvent('declineBill', function(src, billId)
    local bill = Mechanic.Bills[tonumber(billId)]
    if bill then
        bill.status = 'declined'
        MySQL.update.await('UPDATE mechanic_bills SET status = ? WHERE id = ?', { 'declined', bill.id })
        TriggerClientEvent('qs-mechanic-creator:client:billDeclined', src, bill.id)
    end
end)

Mechanic.RegisterEvent('cancelBill', function(src, billId)
    local bill = Mechanic.Bills[tonumber(billId)]
    if bill then
        bill.status = 'cancelled'
        MySQL.update.await('UPDATE mechanic_bills SET status = ? WHERE id = ?', { 'cancelled', bill.id })
        TriggerClientEvent('qs-mechanic-creator:client:billCancelled', -1, bill.id)
    end
end)

local billingEvents = {
    'sendESXBill', 'sendQBBill', 'sendQSBill', 'sendOkokBill',
    'sendRenewedBill', 'sendWasabiBill', 'send17movBill',
}
for _, name in ipairs(billingEvents) do
    Mechanic.RegisterEvent(name, function(src, targetId, amount, reason, _shopJob, shopId)
        Mechanic.CreateBill(src, targetId, amount, reason, shopId)
    end)
end

-- Inventory bridges
Mechanic.RegisterEvent('openQBInventoryShop', function() end)
Mechanic.RegisterEvent('openQBInventoryStash', function() end)
Mechanic.RegisterEvent('openAK47InventoryShop', function() end)
Mechanic.RegisterEvent('openAK47QBInventoryShop', function() end)

-- Sync / multiplayer visuals
local syncMap = {
    syncHoistAttach = true,
    syncHoistPlace = true,
    syncEngineAttach = true,
    syncEngineLift = true,
    syncEngineLower = true,
    syncEngineDelete = true,
    syncEngineStatus = true,
    hoistPickedUp = true,
    attachVehicleToFlatbed = true,
    detachVehicleFromFlatbed = true,
    toggleCarliftVehicle = true,
    updateCarliftPosition = true,
}

for eventName, _ in pairs(syncMap) do
    Mechanic.RegisterEvent(eventName, function(_, ...)
        Mechanic.BroadcastClient(eventName, ...)
    end)
end

Mechanic.RegisterEvent('setEngineConfig', function(_, plate, config)
    Mechanic.SaveEngineConfig(plate, config)
    Mechanic.BroadcastClient('syncEngineStatus', plate, config)
end)

Mechanic.RegisterEvent('createStatebag:heatedbrakes', function(src, netId, data)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh and veh ~= 0 then
        local ent = Entity(veh)
        if ent and ent.state then
            ent.state:set('heatedbrakes', data, true)
        end
    end
end)

-- Logging events (no-op persistence)
local logs = {
    'logFullRepair', 'logBodyRepair', 'logEngineRepair', 'logVehicleWashed',
    'logVehicleFlipped', 'logVehicleRefueled', 'logVehicleSpawned', 'logVehicleStored',
    'logTowingStarted', 'logTowingCancelled', 'logRopeDetached', 'logRopeBroken',
}
for _, name in ipairs(logs) do
    Mechanic.RegisterEvent(name, function() end)
end

AddEventHandler('qs-mechanic-creator:internal:playerReady', function(src)
    if not src or src <= 0 then return end
    Mechanic.PushPlayerData(src)
    Mechanic.SyncShopsToPlayer(src)
end)

AddEventHandler('playerJoining', function()
    local src = source
    SetTimeout(4000, function()
        if GetPlayerPing(src) > 0 then
            Mechanic.PushPlayerData(src)
            Mechanic.SyncShopsToPlayer(src)
        end
    end)
end)
