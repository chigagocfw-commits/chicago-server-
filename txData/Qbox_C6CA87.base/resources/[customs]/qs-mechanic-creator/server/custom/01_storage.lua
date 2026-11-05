Mechanic.Shops = Mechanic.Shops or {}
Mechanic.Configs = Mechanic.Configs or {}
Mechanic.VehicleMods = Mechanic.VehicleMods or {}
Mechanic.VehicleEngines = Mechanic.VehicleEngines or {}
Mechanic.Orders = Mechanic.Orders or {}
Mechanic.Employees = Mechanic.Employees or {}
Mechanic.Stashes = Mechanic.Stashes or {}
Mechanic.EngineStock = Mechanic.EngineStock or {}
Mechanic.PalletEngines = Mechanic.PalletEngines or {}
Mechanic.Bills = Mechanic.Bills or {}
Mechanic.PendingRestores = Mechanic.PendingRestores or {}
Mechanic.TuneshopOccupied = Mechanic.TuneshopOccupied or {}
Mechanic.NextOrderId = Mechanic.NextOrderId or 1
Mechanic.NextBillId = Mechanic.NextBillId or 1

local DEFAULT_CONFIGS = {
    wheeldamage = {
        enabled = true,
        blacklistedVehicles = {},
    },
    offroadsystem = {
        enabled = true,
        excludedZones = {},
        blacklistedVehicles = { 'rcbandito', 'monster', 'rhino', 'scarab', 'khanjali' },
    },
    heatedbrakes = {
        enabled = true,
        temperatureRate = 1.0,
        coolingRate = 1.0,
        performanceLoss = 1.0,
        blacklistedVehicles = {},
        visual = { glow = { enabled = true, strength = 1 } },
        temperatureIncrease = { classes = {}, brakeUpgrade = { [-1] = 1.0, [0] = 1.0, [1] = 1.0, [2] = 1.0 } },
        temperatureDecrease = { classes = {}, brakeUpgrade = { [-1] = 1.0, [0] = 1.0, [1] = 1.0, [2] = 1.0 } },
        vehicleOverrides = {},
    },
}

function Mechanic.DefaultConfigs()
    return json.decode(json.encode(DEFAULT_CONFIGS))
end

function Mechanic.EnsureSchema()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mechanic_shops` (
            `shop_id` VARCHAR(64) NOT NULL,
            `data` LONGTEXT NOT NULL,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`shop_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mechanic_configs` (
            `config_key` VARCHAR(64) NOT NULL,
            `data` LONGTEXT NOT NULL,
            PRIMARY KEY (`config_key`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mechanic_vehicle_mods` (
            `plate` VARCHAR(16) NOT NULL,
            `data` LONGTEXT NOT NULL,
            PRIMARY KEY (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mechanic_vehicle_engines` (
            `plate` VARCHAR(16) NOT NULL,
            `data` LONGTEXT NOT NULL,
            PRIMARY KEY (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mechanic_employees` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `shop_id` VARCHAR(64) NOT NULL,
            `identifier` VARCHAR(80) NOT NULL,
            `name` VARCHAR(128) DEFAULT NULL,
            `grade` INT NOT NULL DEFAULT 0,
            `permissions` LONGTEXT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `shop_employee` (`shop_id`, `identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mechanic_orders` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `shop_id` VARCHAR(64) NOT NULL,
            `plate` VARCHAR(16) DEFAULT NULL,
            `customer_identifier` VARCHAR(80) DEFAULT NULL,
            `status` VARCHAR(32) NOT NULL DEFAULT 'pending',
            `total` INT NOT NULL DEFAULT 0,
            `modifications` LONGTEXT NULL,
            `vehicle_data` LONGTEXT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mechanic_stashes` (
            `stash_key` VARCHAR(128) NOT NULL,
            `items` LONGTEXT NOT NULL,
            PRIMARY KEY (`stash_key`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mechanic_engine_stock` (
            `shop_id` VARCHAR(64) NOT NULL,
            `data` LONGTEXT NOT NULL,
            PRIMARY KEY (`shop_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mechanic_bills` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `shop_id` VARCHAR(64) DEFAULT NULL,
            `from_identifier` VARCHAR(80) DEFAULT NULL,
            `to_identifier` VARCHAR(80) NOT NULL,
            `amount` INT NOT NULL,
            `reason` VARCHAR(255) DEFAULT NULL,
            `status` VARCHAR(32) NOT NULL DEFAULT 'pending',
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

function Mechanic.LoadAll()
    Mechanic.Shops = {}
    local rows = MySQL.query.await('SELECT shop_id, data FROM mechanic_shops') or {}
    for _, row in ipairs(rows) do
        local ok, data = pcall(json.decode, row.data)
        if ok and data then
            Mechanic.Shops[row.shop_id] = data
        end
    end

    Mechanic.Configs = Mechanic.DefaultConfigs()
    local cfgRows = MySQL.query.await('SELECT config_key, data FROM mechanic_configs') or {}
    for _, row in ipairs(cfgRows) do
        local ok, data = pcall(json.decode, row.data)
        if ok and data then
            Mechanic.Configs[row.config_key] = data
        end
    end

    Mechanic.Employees = {}
    local empRows = MySQL.query.await('SELECT shop_id, identifier, name, grade, permissions FROM mechanic_employees') or {}
    for _, row in ipairs(empRows) do
        Mechanic.Employees[row.shop_id] = Mechanic.Employees[row.shop_id] or {}
        local perms = nil
        if row.permissions then
            local ok, decoded = pcall(json.decode, row.permissions)
            if ok then perms = decoded end
        end
        Mechanic.Employees[row.shop_id][row.identifier] = {
            identifier = row.identifier,
            name = row.name,
            grade = row.grade,
            permissions = perms,
        }
    end

    Mechanic.Orders = {}
    local orderRows = MySQL.query.await('SELECT * FROM mechanic_orders ORDER BY id ASC') or {}
    for _, row in ipairs(orderRows) do
        Mechanic.Orders[row.id] = row
        if row.id >= (Mechanic.NextOrderId or 1) then
            Mechanic.NextOrderId = row.id + 1
        end
    end

    Mechanic.Stashes = {}
    local stashRows = MySQL.query.await('SELECT stash_key, items FROM mechanic_stashes') or {}
    for _, row in ipairs(stashRows) do
        local ok, items = pcall(json.decode, row.items)
        Mechanic.Stashes[row.stash_key] = ok and items or {}
    end

    Mechanic.EngineStock = {}
    local stockRows = MySQL.query.await('SELECT shop_id, data FROM mechanic_engine_stock') or {}
    for _, row in ipairs(stockRows) do
        local ok, data = pcall(json.decode, row.data)
        Mechanic.EngineStock[row.shop_id] = ok and data or {}
    end

    Mechanic.Bills = {}
    local billRows = MySQL.query.await('SELECT * FROM mechanic_bills ORDER BY id ASC') or {}
    for _, row in ipairs(billRows) do
        Mechanic.Bills[row.id] = row
        if row.id >= (Mechanic.NextBillId or 1) then
            Mechanic.NextBillId = row.id + 1
        end
    end
end

function Mechanic.SaveShop(shopId, data)
    Mechanic.Shops[shopId] = data
    MySQL.insert.await(
        'INSERT INTO mechanic_shops (shop_id, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)',
        { shopId, json.encode(data) }
    )
end

function Mechanic.DeleteShop(shopId)
    Mechanic.Shops[shopId] = nil
    MySQL.query.await('DELETE FROM mechanic_shops WHERE shop_id = ?', { shopId })
    MySQL.query.await('DELETE FROM mechanic_employees WHERE shop_id = ?', { shopId })
    MySQL.query.await('DELETE FROM mechanic_engine_stock WHERE shop_id = ?', { shopId })
    Mechanic.Employees[shopId] = nil
    Mechanic.EngineStock[shopId] = nil
end

function Mechanic.GetAllShops()
    return Mechanic.Shops
end

function Mechanic.BuildCarliftsMap()
    local lifts = {}
    for shopId, shop in pairs(Mechanic.Shops) do
        if shop and (shop.shopConfig or shop.carlift or shop.carlifts) then
            lifts[shopId] = shop
        end
    end
    return lifts
end

-- SyncShopsToPlayer / SyncShopsToAll extended in server/custom/02_shop_normalize.lua (carlifts + normalize)

function Mechanic.SaveConfigSection(section, data)
    Mechanic.Configs[section] = data
    MySQL.insert.await(
        'INSERT INTO mechanic_configs (config_key, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)',
        { section, json.encode(data) }
    )
end

function Mechanic.GetConfigsPayload()
    local defaults = Mechanic.DefaultConfigs()
    return {
        wheeldamage = Mechanic.Configs.wheeldamage or defaults.wheeldamage,
        offroadsystem = Mechanic.Configs.offroadsystem or defaults.offroadsystem,
        heatedbrakes = Mechanic.Configs.heatedbrakes or defaults.heatedbrakes,
    }
end

function Mechanic.IsShopEmployee(src, shopId)
    local license = Mechanic.GetPlayerLicense(src)
    if not license or not shopId then return false end
    local shop = Mechanic.Shops[shopId]
    if not shop or not shop.shopConfig then return false end
    local job = Mechanic.GetJob(src)
    if job and shop.shopConfig.job and job.name == shop.shopConfig.job then
        return true
    end
    local employees = Mechanic.Employees[shopId]
    return employees and employees[license] ~= nil
end

function Mechanic.GetShopJob(shopId)
    local shop = Mechanic.Shops[shopId]
    return shop and shop.shopConfig and shop.shopConfig.job or nil
end

function Mechanic.SaveVehicleMods(plate, props)
    if not plate or not props then return end
    plate = NormalizePlate(plate)
    Mechanic.VehicleMods[plate] = props
    MySQL.insert.await(
        'INSERT INTO mechanic_vehicle_mods (plate, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)',
        { plate, json.encode(props) }
    )
    if Mechanic.SaveOwnedVehicleMods then
        Mechanic.SaveOwnedVehicleMods(plate, props)
    end
end

function Mechanic.GetVehicleMods(plate)
    plate = NormalizePlate(plate)
    if Mechanic.VehicleMods[plate] then
        return Mechanic.VehicleMods[plate]
    end
    local row = MySQL.single.await('SELECT data FROM mechanic_vehicle_mods WHERE plate = ?', { plate })
    if row and row.data then
        local ok, data = pcall(json.decode, row.data)
        if ok then
            Mechanic.VehicleMods[plate] = data
            return data
        end
    end
    return nil
end

function Mechanic.SaveEngineConfig(plate, config)
    if not plate then return end
    plate = NormalizePlate(plate)
    Mechanic.VehicleEngines[plate] = config
    MySQL.insert.await(
        'INSERT INTO mechanic_vehicle_engines (plate, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)',
        { plate, json.encode(config or {}) }
    )
end

function Mechanic.GetEngineConfig(plate)
    plate = NormalizePlate(plate)
    if Mechanic.VehicleEngines[plate] then
        return Mechanic.VehicleEngines[plate]
    end
    local row = MySQL.single.await('SELECT data FROM mechanic_vehicle_engines WHERE plate = ?', { plate })
    if row and row.data then
        local ok, data = pcall(json.decode, row.data)
        if ok then
            Mechanic.VehicleEngines[plate] = data
            return data
        end
    end
    return nil
end

function Mechanic.PushPlayerData(src)
    TriggerClientEvent('qs-mechanic-creator:client:updatePlayerData', src, {
        job = Mechanic.GetJob(src),
        license = Mechanic.GetPlayerLicense(src),
    })
end

function Mechanic.BuildTabletData(shopId, src)
    local shop = Mechanic.Shops[shopId]
    if not shop then return nil end
    local employees = {}
    local empMap = Mechanic.Employees[shopId] or {}
    for _, emp in pairs(empMap) do
        employees[#employees + 1] = emp
    end
    local orders = {}
    for id, order in pairs(Mechanic.Orders) do
        if order.shop_id == shopId then
            orders[#orders + 1] = {
                id = id,
                shopId = shopId,
                plate = order.plate,
                status = order.status,
                total = order.total,
                modifications = order.modifications and json.decode(order.modifications) or {},
            }
        end
    end
    return {
        shopId = shopId,
        shop = shop,
        shopConfig = shop.shopConfig,
        employees = employees,
        orders = orders,
        societyBalance = 0,
    }
end

function Mechanic.CanPerformActionHook(src, action, data)
    if type(Config.CanPerformMechanicAction) == 'function' then
        return Config.CanPerformMechanicAction(src, action, data)
    end
    return true
end

function Mechanic.RegisterCallback(name, fn)
    lib.callback.register('qs-mechanic-creator:server:' .. name, fn)
end

function Mechanic.RegisterEvent(name, fn)
    RegisterNetEvent('qs-mechanic-creator:server:' .. name, function(...)
        if source == 0 then return end
        fn(source, ...)
    end)
end

function Mechanic.BroadcastClient(eventName, ...)
    TriggerClientEvent('qs-mechanic-creator:client:' .. eventName, -1, ...)
end
