Vehicles = Vehicles or {}
Vehicles.Server = Vehicles.Server or {}

local allVehiclesCache = {}

function Vehicles.Server.GetAll()
  local rows = MySQL.query.await([[
    SELECT vehicle.spawn_code,
    MAX(vehicle.brand) AS brand,
    MAX(vehicle.model) AS model,
    MAX(vehicle.category) AS category,
    MAX(vehicle.price) AS price,
    MAX(vehicle.price_limits_enabled) AS price_limits_enabled,
    MAX(vehicle.min_price) AS min_price,
    MAX(vehicle.max_price) AS max_price,
    MAX(vehicle.unlimited_stock) AS unlimited_stock,
    MAX(vehicle.global_stock_limit) AS global_stock_limit,
    MAX(vehicle.created_at) AS created_at,
    CASE 
      WHEN COUNT(location.id) > 0 THEN
        CONCAT('[', GROUP_CONCAT(
          JSON_OBJECT(
            'id', location.id,
            'name', location.name
          )
        ), ']')
      ELSE '[]'
    END AS locations,
    COALESCE((SELECT SUM(quantity) FROM dealership_orders WHERE dealership_orders.vehicle = vehicle.spawn_code), 0) AS global_stock_ordered
    FROM dealership_vehicles vehicle
    LEFT JOIN dealership_stock stock ON vehicle.spawn_code = stock.vehicle
    LEFT JOIN dealership_locations location ON location.id = stock.dealership
    GROUP BY vehicle.spawn_code
    ORDER BY MAX(vehicle.created_at) DESC
  ]])

  allVehiclesCache = {}

  for _, row in pairs(rows) do
    allVehiclesCache[#allVehiclesCache + 1] = {
      spawn_code = row.spawn_code,
      brand = row.brand,
      model = row.model,
      category = row.category,
      price = row.price,
      price_limits_enabled = row.price_limits_enabled,
      min_price = row.min_price,
      max_price = row.max_price,
      unlimited_stock = row.unlimited_stock,
      global_stock_limit = row.global_stock_limit,
      global_stock_ordered = row.global_stock_ordered,
      locations = json.decode(row.locations),
      created_at = row.created_at,
    }
  end

  return allVehiclesCache
end

function Vehicles.Server.Create(vehicleData)
  local spawnCode = Trim(vehicleData.spawn_code)
  if vehicleData.price < 0 then
    return false
  end

  MySQL.insert.await([[
    INSERT INTO dealership_vehicles
    (spawn_code, hashkey, brand, model, category, price, price_limits_enabled, min_price, max_price, unlimited_stock, global_stock_limit)
    VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ]], {
    spawnCode,
    joaat(spawnCode),
    vehicleData.brand,
    vehicleData.model,
    vehicleData.category,
    vehicleData.price,
    vehicleData.price_limits_enabled and 1 or 0,
    vehicleData.min_price,
    vehicleData.max_price,
    vehicleData.unlimited_stock == false and 0 or 1,
    vehicleData.global_stock_limit or 0,
  })

  for _, location in ipairs(vehicleData.locations) do
    MySQL.insert.await([[
      INSERT IGNORE INTO dealership_stock
      (vehicle, dealership, price)
      VALUES (?, ?, ?)
    ]], { spawnCode, location.id, vehicleData.price })

    Showroom.Server.UpdateVehicleCache(spawnCode, location.id)
  end

  return true
end

function Vehicles.Server.Update(spawnCode, vehicleData, updateLocationPrices)
  spawnCode = Trim(spawnCode)
  if vehicleData.price < 0 then
    return false
  end

  MySQL.query.await([[
    UPDATE dealership_vehicles
    SET brand = ?, model = ?, category = ?, price = ?,
        price_limits_enabled = ?, min_price = ?, max_price = ?,
        unlimited_stock = ?, global_stock_limit = ?
    WHERE spawn_code = ?
  ]], {
    vehicleData.brand,
    vehicleData.model,
    vehicleData.category,
    vehicleData.price,
    vehicleData.price_limits_enabled,
    vehicleData.min_price,
    vehicleData.max_price,
    vehicleData.unlimited_stock,
    vehicleData.global_stock_limit,
    spawnCode,
  })

  local allowedLocationIds = {}
  for _, location in pairs(vehicleData.locations) do
    allowedLocationIds[#allowedLocationIds + 1] = location.id
  end

  if #vehicleData.locations > 0 then
    MySQL.query.await([[
      DELETE FROM dealership_stock
      WHERE vehicle = ? AND dealership NOT IN (?)
    ]], { spawnCode, allowedLocationIds })
  else
    MySQL.query.await([[
      DELETE FROM dealership_stock
      WHERE vehicle = ?
    ]], { spawnCode })
  end

  for _, location in ipairs(vehicleData.locations) do
    MySQL.query.await([[
      INSERT IGNORE INTO dealership_stock
      (vehicle, dealership, price)
      VALUES (?, ?, ?)
    ]], { spawnCode, location.id, vehicleData.price })
  end

  if updateLocationPrices then
    MySQL.query.await([[
      UPDATE dealership_stock
      SET price = ?
      WHERE vehicle = ?
    ]], { vehicleData.price, spawnCode })
  end

  for _, location in ipairs(vehicleData.locations) do
    Showroom.Server.UpdateVehicleCache(spawnCode, location.id)
  end

  return true
end

function Vehicles.Server.Delete(spawnCode)
  spawnCode = Trim(spawnCode)

  MySQL.query.await("DELETE FROM dealership_stock WHERE vehicle = ?", { spawnCode })
  MySQL.query.await("DELETE FROM dealership_sales WHERE vehicle = ?", { spawnCode })
  MySQL.query.await("DELETE FROM dealership_orders WHERE vehicle = ?", { spawnCode })
  MySQL.query.await("DELETE FROM dealership_dispveh WHERE vehicle = ?", { spawnCode })
  MySQL.query.await("DELETE FROM dealership_vehicles WHERE spawn_code = ?", { spawnCode })

  Showroom.Server.UpdateVehicleCache(spawnCode)
  return true
end

exports("incrementStock", function(dealershipId, spawnCode, amount)
  amount = amount or 1

  if type(dealershipId) ~= "string" or type(spawnCode) ~= "string" then
    return false, "dealership and spawnCode must be strings"
  end

  if type(amount) ~= "number" or amount < 1 then
    return false, "amount must be a positive number"
  end

  local affectedRows = MySQL.update.await(
    "UPDATE dealership_stock SET stock = stock + ? WHERE dealership = ? AND vehicle = ?",
    { amount, dealershipId, spawnCode }
  )

  if affectedRows == 0 then
    return false, "no stock row found for this dealership/vehicle combination"
  end

  Showroom.Server.UpdateVehicleCache(spawnCode, dealershipId)
  return true
end)

exports("decrementStock", function(dealershipId, spawnCode, amount)
  amount = amount or 1

  if type(dealershipId) ~= "string" or type(spawnCode) ~= "string" then
    return false, "dealership and spawnCode must be strings"
  end

  if type(amount) ~= "number" or amount < 1 then
    return false, "amount must be a positive number"
  end

  local affectedRows = MySQL.update.await(
    "UPDATE dealership_stock SET stock = stock - ? WHERE dealership = ? AND vehicle = ? AND stock >= ?",
    { amount, dealershipId, spawnCode, amount }
  )

  if affectedRows == 0 then
    return false, "no matching row found or insufficient stock"
  end

  Showroom.Server.UpdateVehicleCache(spawnCode, dealershipId)
  return true
end)

exports("setStock", function(dealershipId, spawnCode, stock)
  if type(dealershipId) ~= "string" or type(spawnCode) ~= "string" then
    return false, "dealership and spawnCode must be strings"
  end

  if type(stock) ~= "number" or stock < 0 then
    return false, "stock must be a non-negative number"
  end

  local affectedRows = MySQL.update.await(
    "UPDATE dealership_stock SET stock = ? WHERE dealership = ? AND vehicle = ?",
    { stock, dealershipId, spawnCode }
  )

  if affectedRows == 0 then
    return false, "no stock row found for this dealership/vehicle combination"
  end

  Showroom.Server.UpdateVehicleCache(spawnCode, dealershipId)
  return true
end)

exports("getVehiclePrice", function(spawnCode, dealershipId)
  if type(spawnCode) ~= "string" then
    return false, "spawnCode must be a string"
  end

  if dealershipId then
    if type(dealershipId) ~= "string" then
      return false, "dealershipId must be a string"
    end

    local price = MySQL.scalar.await(
      "SELECT price FROM dealership_stock WHERE vehicle = ? AND dealership = ?",
      { spawnCode, dealershipId }
    )

    if not price then
      return false, "no stock row found for this dealership/vehicle combination"
    end

    return price
  end

  local price = MySQL.scalar.await("SELECT price FROM dealership_vehicles WHERE spawn_code = ?", { spawnCode })
  if not price then
    return false, "vehicle not found"
  end

  return price
end)

exports("getVehicleStock", function(spawnCode, dealershipId)
  if type(spawnCode) ~= "string" or type(dealershipId) ~= "string" then
    return false, "spawnCode and dealershipId must be strings"
  end

  local stock = MySQL.scalar.await(
    "SELECT stock FROM dealership_stock WHERE vehicle = ? AND dealership = ?",
    { spawnCode, dealershipId }
  )

  if not stock then
    return false, "no stock row found for this dealership/vehicle combination"
  end

  return stock
end)
