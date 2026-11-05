local function getDealershipName(dealershipId)
  local location = Locations.Server.GetById(dealershipId)
  return location and location.name or dealershipId
end

local function rejectEmployeeAction(source)
  Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
  return { error = true }
end

local function fulfillOrder(order)
  MySQL.update.await("UPDATE dealership_orders SET fulfilled = ? WHERE id = ?", { 1, order.id })
  MySQL.update.await(
    "UPDATE dealership_stock SET stock = stock + ? WHERE dealership = ? AND vehicle = ?",
    { order.quantity, order.dealership, order.vehicle }
  )
  Showroom.Server.UpdateVehicleCache(order.vehicle, order.dealership)
  DebugPrint("Order fulfilled: " .. order.id, "debug", order)
end

lib.callback.register("jg-dealerships:server:get-dealership-balance", function(source, dealershipId)
  if not Employees.Server.IsEmployee(source, dealershipId, "MANAGE_FINANCES") then
    return rejectEmployeeAction(source)
  end

  local balance = DealershipBalance.Server.GetBalance(dealershipId)
  if balance == nil then
    return { error = true }
  end

  return { balance = balance }
end)

lib.callback.register("jg-dealerships:server:get-dealership-vehicles", function(source, data)
  local dealershipId = data.dealershipId
  if not Employees.Server.IsEmployee(source, dealershipId, "MANAGE_INVENTORY") then
    return rejectEmployeeAction(source)
  end

  return MySQL.rawExecute.await([[
    SELECT vehicle.*,
           stock.stock as stock,
           stock.price as list_price,
           COALESCE((SELECT SUM(quantity) FROM dealership_orders WHERE dealership_orders.vehicle = vehicle.spawn_code), 0) AS global_stock_ordered
    FROM dealership_vehicles vehicle
    INNER JOIN dealership_stock stock ON vehicle.spawn_code = stock.vehicle
    WHERE stock.dealership = ?
    ORDER BY vehicle.spawn_code ASC
  ]], { dealershipId })
end)

lib.callback.register("jg-dealerships:server:get-dealership-display-vehicles", function(source, data)
  local dealershipId = data.dealershipId
  if not Employees.Server.IsEmployee(source, dealershipId, "MANAGE_INVENTORY") then
    return rejectEmployeeAction(source)
  end

  local displayVehicles = MySQL.query.await(
    "SELECT dispveh.*, vehicle.brand, vehicle.model FROM dealership_dispveh dispveh INNER JOIN dealership_vehicles vehicle ON vehicle.spawn_code = dispveh.vehicle WHERE dispveh.dealership = ?;",
    { dealershipId }
  )

  for _, displayVehicle in ipairs(displayVehicles) do
    displayVehicle.color = json.decode(displayVehicle.color)
  end

  return displayVehicles
end)

lib.callback.register("jg-dealerships:server:get-dealership-orders", function(source, data)
  local dealershipId = data.dealershipId
  local pageIndex = data.pageIndex
  local pageSize = data.pageSize
  local searchQuery = data.searchQuery

  if not Employees.Server.IsEmployee(source, dealershipId, { "VIEW_RECORDS", "DELIVER" }) then
    return rejectEmployeeAction(source)
  end

  local searchConditions = ""
  local searchValues = {}

  if searchQuery and searchQuery ~= "" then
    searchConditions, searchValues = SearchHelpers.BuildSearchConditions(
      searchQuery,
      { "orders.vehicle", "vehicle.brand", "vehicle.model" },
      "orders.order_created",
      { { "vehicle.brand", "vehicle.model" } }
    )
  end

  local ordersQuery = "SELECT orders.*, vehicle.brand, vehicle.model FROM dealership_orders orders INNER JOIN dealership_vehicles vehicle ON orders.vehicle = vehicle.spawn_code WHERE orders.dealership = ?"
  local totalQuery = "SELECT COUNT(*) FROM dealership_orders orders INNER JOIN dealership_vehicles vehicle ON orders.vehicle = vehicle.spawn_code WHERE orders.dealership = ?"
  local ordersValues = { dealershipId }
  local totalValues = { dealershipId }

  if searchConditions ~= "" then
    ordersQuery = ordersQuery .. " AND " .. searchConditions
    totalQuery = totalQuery .. " AND " .. searchConditions

    for _, value in ipairs(searchValues) do
      ordersValues[#ordersValues + 1] = value
      totalValues[#totalValues + 1] = value
    end
  end

  ordersQuery = ordersQuery .. " ORDER BY orders.order_created DESC LIMIT ? OFFSET ?"
  ordersValues[#ordersValues + 1] = pageSize
  ordersValues[#ordersValues + 1] = pageIndex * pageSize

  local orders = MySQL.query.await(ordersQuery, ordersValues) or {}

  for _, order in ipairs(orders) do
    order.time_remaining = order.delivery_time - os.time()
    order.hasActiveDelivery = false
    order.inTransitQuantity = 0

    if TruckingMission and TruckingMission.Server and TruckingMission.Server.IsOrderBeingDelivered then
      local hasActiveDelivery, inTransitQuantity = TruckingMission.Server.IsOrderBeingDelivered(order.id)
      order.hasActiveDelivery = hasActiveDelivery
      order.inTransitQuantity = inTransitQuantity or 0

      if order.hasActiveDelivery and TruckingMission.Server.GetActiveDeliveryInfo then
        local activeDelivery = TruckingMission.Server.GetActiveDeliveryInfo(order.id)
        if activeDelivery then
          order.active_delivery_started_at = activeDelivery.startedAt
          order.active_delivery_started_by = activeDelivery.startedByName
          order.delivery_pickup_location = activeDelivery.pickupLocation
        end
      end
    end

    if order.fulfilled and order.delivered_by then
      local deliveredBy = Framework.Server.GetPlayerInfoFromIdentifier(order.delivered_by)
      order.delivered_by_name = deliveredBy and deliveredBy.name or order.delivered_by
    end

    if order.ordered_by then
      local orderedBy = Framework.Server.GetPlayerInfoFromIdentifier(order.ordered_by)
      order.ordered_by_name = orderedBy and orderedBy.name or order.ordered_by
    end
  end

  return {
    orders = orders,
    total = MySQL.scalar.await(totalQuery, totalValues),
  }
end)

lib.callback.register("jg-dealerships:server:get-dealership-sales", function(source, data)
  local dealershipId = data.dealershipId
  local pageIndex = data.pageIndex
  local pageSize = data.pageSize
  local searchQuery = data.searchQuery
  local purchaseTypeFilter = data.purchaseTypeFilter

  if not Employees.Server.IsEmployee(source, dealershipId, "VIEW_RECORDS") then
    return rejectEmployeeAction(source)
  end

  local searchConditions = ""
  local searchValues = {}

  if searchQuery and searchQuery ~= "" then
    local playerNameExpression = Framework.Server.GetPlayerNameSearchExpression("sales.player")
    local sellerNameExpression = Framework.Server.GetPlayerNameSearchExpression("sales.seller")
    searchConditions, searchValues = SearchHelpers.BuildSearchConditions(
      searchQuery,
      { "sales.vehicle", "vehicle.brand", "vehicle.model", playerNameExpression, sellerNameExpression },
      "sales.created_at",
      { { "vehicle.brand", "vehicle.model" } }
    )
  end

  local salesQuery = "SELECT sales.*, vehicle.brand, vehicle.model FROM dealership_sales sales INNER JOIN dealership_vehicles vehicle ON sales.vehicle = vehicle.spawn_code WHERE sales.dealership = ?"
  local totalQuery = "SELECT COUNT(*) FROM dealership_sales sales INNER JOIN dealership_vehicles vehicle ON sales.vehicle = vehicle.spawn_code WHERE sales.dealership = ?"
  local salesValues = { dealershipId }
  local totalValues = { dealershipId }

  if purchaseTypeFilter and purchaseTypeFilter ~= "all" then
    salesQuery = salesQuery .. " AND sales.purchase_type = ?"
    totalQuery = totalQuery .. " AND sales.purchase_type = ?"
    salesValues[#salesValues + 1] = purchaseTypeFilter
    totalValues[#totalValues + 1] = purchaseTypeFilter
  end

  if searchConditions ~= "" then
    salesQuery = salesQuery .. " AND " .. searchConditions
    totalQuery = totalQuery .. " AND " .. searchConditions

    for _, value in ipairs(searchValues) do
      salesValues[#salesValues + 1] = value
      totalValues[#totalValues + 1] = value
    end
  end

  salesQuery = salesQuery .. " ORDER BY sales.created_at DESC LIMIT ? OFFSET ?"
  salesValues[#salesValues + 1] = pageSize
  salesValues[#salesValues + 1] = pageIndex * pageSize

  local sales = MySQL.query.await(salesQuery, salesValues) or {}

  for _, sale in ipairs(sales) do
    local player = Framework.Server.GetPlayerInfoFromIdentifier(sale.player)
    local seller = Framework.Server.GetPlayerInfoFromIdentifier(sale.seller)
    sale.player_name = player and player.name or "-"
    sale.seller_name = seller and seller.name or "-"
  end

  return {
    sales = sales,
    total = MySQL.scalar.await(totalQuery, totalValues),
  }
end)

lib.callback.register("jg-dealerships:server:get-dealership-homepage-stats", function(source, data)
  local dealershipId = data.dealershipId
  if not Employees.Server.IsEmployee(source, dealershipId, "VIEW_RECORDS") then
    return rejectEmployeeAction(source)
  end

  local stats = MySQL.single.await([[
    SELECT
      COALESCE(SUM(CASE WHEN DATE(created_at) = CURDATE() THEN paid ELSE 0 END), 0) as today_total,
      COUNT(CASE WHEN DATE(created_at) = CURDATE() THEN 1 END) as today_count,
      COALESCE(SUM(CASE WHEN DATE(created_at) = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN paid ELSE 0 END), 0) as yesterday_total,
      COUNT(CASE WHEN DATE(created_at) = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN 1 END) as yesterday_count,
      COALESCE(SUM(CASE WHEN YEAR(created_at) = YEAR(CURDATE()) AND MONTH(created_at) = MONTH(CURDATE()) THEN paid ELSE 0 END), 0) as this_month_total,
      COUNT(CASE WHEN YEAR(created_at) = YEAR(CURDATE()) AND MONTH(created_at) = MONTH(CURDATE()) THEN 1 END) as this_month_count,
      COALESCE(SUM(CASE WHEN YEAR(created_at) = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) AND MONTH(created_at) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) THEN paid ELSE 0 END), 0) as last_month_total,
      COUNT(CASE WHEN YEAR(created_at) = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) AND MONTH(created_at) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) THEN 1 END) as last_month_count,
      COALESCE(SUM(paid), 0) as all_time_total,
      COUNT(*) as all_time_count
    FROM dealership_sales
    WHERE dealership = ?
  ]], { dealershipId }) or {
    today_total = 0,
    today_count = 0,
    yesterday_total = 0,
    yesterday_count = 0,
    this_month_total = 0,
    this_month_count = 0,
    last_month_total = 0,
    last_month_count = 0,
    all_time_total = 0,
    all_time_count = 0,
  }

  local recentSales = MySQL.query.await([[
    SELECT
      sales.vehicle as model,
      sales.paid as price,
      sales.purchase_type as purchase_type,
      vehicle.brand,
      vehicle.model as vehicle_name
    FROM dealership_sales sales
    INNER JOIN dealership_vehicles vehicle ON sales.vehicle = vehicle.spawn_code
    WHERE sales.dealership = ?
    ORDER BY sales.created_at DESC
    LIMIT 5
  ]], { dealershipId })

  local yesterdayComparison = 0
  if stats.yesterday_count > 0 then
    yesterdayComparison = ((stats.today_count - stats.yesterday_count) / stats.yesterday_count) * 100
  elseif stats.today_count > 0 then
    yesterdayComparison = 100
  end

  local lastMonthComparison = 0
  if stats.last_month_count > 0 then
    lastMonthComparison = ((stats.this_month_count - stats.last_month_count) / stats.last_month_count) * 100
  elseif stats.this_month_count > 0 then
    lastMonthComparison = 100
  end

  return {
    today = {
      amount = stats.today_total,
      count = stats.today_count,
    },
    yesterdayComparison = yesterdayComparison,
    thisMonth = {
      amount = stats.this_month_total,
      count = stats.this_month_count,
    },
    lastMonthComparison = lastMonthComparison,
    allTime = {
      amount = stats.all_time_total,
      count = stats.all_time_count,
    },
    recentSales = recentSales,
  }
end)

lib.callback.register("jg-dealerships:server:get-dealership-graph-data", function(source, data)
  local dealershipId = data.dealershipId
  local dateRange = data.dateRange
  local metric = data.metric

  if not Employees.Server.IsEmployee(source, dealershipId, "VIEW_RECORDS") then
    return rejectEmployeeAction(source)
  end

  local aggregateExpression = metric == "volume" and "SUM(sales.paid)" or "COUNT(sales.id)"
  local graphData

  if dateRange == "7days" then
    graphData = MySQL.query.await(([[
      WITH RECURSIVE dates AS (
        SELECT DATE_SUB(CURDATE(), INTERVAL 6 DAY) as date
        UNION ALL
        SELECT DATE_ADD(date, INTERVAL 1 DAY)
        FROM dates
        WHERE date < CURDATE()
      )
      SELECT
        CAST(DATE_FORMAT(dates.date, '%%Y-%%m-%%d') AS CHAR) as date,
        COALESCE(%s, 0) as value
      FROM dates
      LEFT JOIN dealership_sales sales
        ON DATE(sales.created_at) = dates.date
        AND sales.dealership = ?
      GROUP BY dates.date
      ORDER BY dates.date ASC
    ]]):format(aggregateExpression), { dealershipId })
  elseif dateRange == "month" then
    graphData = MySQL.query.await(([[
      WITH RECURSIVE dates AS (
        SELECT DATE_SUB(CURDATE(), INTERVAL 29 DAY) as date
        UNION ALL
        SELECT DATE_ADD(date, INTERVAL 1 DAY)
        FROM dates
        WHERE date < CURDATE()
      )
      SELECT
        CAST(DATE_FORMAT(dates.date, '%%Y-%%m-%%d') AS CHAR) as date,
        COALESCE(%s, 0) as value
      FROM dates
      LEFT JOIN dealership_sales sales
        ON DATE(sales.created_at) = dates.date
        AND sales.dealership = ?
      GROUP BY dates.date
      ORDER BY dates.date ASC
    ]]):format(aggregateExpression), { dealershipId })
  elseif dateRange == "6months" then
    graphData = MySQL.query.await(([[
      WITH RECURSIVE months AS (
        SELECT 0 as n, DATE_SUB(DATE_FORMAT(CURDATE(), '%%Y-%%m-01'), INTERVAL 5 MONTH) as month_start
        UNION ALL
        SELECT n + 1, DATE_ADD(month_start, INTERVAL 1 MONTH)
        FROM months
        WHERE n < 5
      )
      SELECT
        CAST(DATE_FORMAT(months.month_start, '%%Y-%%m') AS CHAR) as date,
        COALESCE(%s, 0) as value
      FROM months
      LEFT JOIN dealership_sales sales
        ON DATE_FORMAT(sales.created_at, '%%Y-%%m') = DATE_FORMAT(months.month_start, '%%Y-%%m')
        AND sales.dealership = ?
      GROUP BY DATE_FORMAT(months.month_start, '%%Y-%%m'), months.n
      ORDER BY months.n ASC
    ]]):format(aggregateExpression), { dealershipId })
  elseif dateRange == "year" then
    graphData = MySQL.query.await(([[
      WITH RECURSIVE months AS (
        SELECT 0 as n, DATE_SUB(DATE_FORMAT(CURDATE(), '%%Y-%%m-01'), INTERVAL 11 MONTH) as month_start
        UNION ALL
        SELECT n + 1, DATE_ADD(month_start, INTERVAL 1 MONTH)
        FROM months
        WHERE n < 11
      )
      SELECT
        CAST(DATE_FORMAT(months.month_start, '%%Y-%%m') AS CHAR) as date,
        COALESCE(%s, 0) as value
      FROM months
      LEFT JOIN dealership_sales sales
        ON DATE_FORMAT(sales.created_at, '%%Y-%%m') = DATE_FORMAT(months.month_start, '%%Y-%%m')
        AND sales.dealership = ?
      GROUP BY DATE_FORMAT(months.month_start, '%%Y-%%m'), months.n
      ORDER BY months.n ASC
    ]]):format(aggregateExpression), { dealershipId })
  else
    return {
      error = true,
      message = "Invalid date range",
    }
  end

  return {
    data = graphData or {},
    dateRange = dateRange,
    metric = metric,
  }
end)

lib.callback.register("jg-dealerships:server:order-vehicle", function(source, dealershipId, vehicle, quantity, sizeCategory)
  if not Employees.Server.IsEmployee(source, dealershipId, "MANAGE_INVENTORY") then
    return rejectEmployeeAction(source)
  end

  local vehicleData = MySQL.single.await(
    "SELECT price, unlimited_stock, global_stock_limit FROM dealership_vehicles WHERE spawn_code = ?",
    { vehicle }
  )
  if not vehicleData then
    return { error = true }
  end

  if sizeCategory ~= "small" and sizeCategory ~= "medium" and sizeCategory ~= "large" then
    sizeCategory = "medium"
  end

  if not vehicleData.unlimited_stock or vehicleData.unlimited_stock == 0 then
    local orderedQuantity = MySQL.scalar.await(
      "SELECT COALESCE(SUM(quantity), 0) FROM dealership_orders WHERE vehicle = ?",
      { vehicle }
    )
    local remainingStock = (vehicleData.global_stock_limit or 0) - orderedQuantity

    if remainingStock <= 0 then
      Framework.Server.Notify(source, Locale.globalStockLimitReached, "error")
      return {
        error = true,
        stockLimitReached = true,
      }
    end

    if quantity > remainingStock then
      Framework.Server.Notify(source, string.gsub(Locale.globalStockLimitExceeded, "%%{value}", remainingStock), "error")
      return {
        error = true,
        stockLimitReached = true,
        remainingStock = remainingStock,
      }
    end
  end

  local totalCost = vehicleData.price * Config.DealerPurchasePrice * quantity
  local deliveryTime = os.time() + (Config.VehicleOrderTime * 60)

  if not DealershipBalance.Server.HasFunds(dealershipId, totalCost) then
    Framework.Server.Notify(source, Locale.dealershipNotEnoughFunds, "error")
    return { error = true }
  end

  local orderedBy = Framework.Server.GetPlayerIdentifier(source)
  local orderId = MySQL.insert.await(
    "INSERT INTO dealership_orders (vehicle, dealership, quantity, cost, delivery_time, ordered_by, size_category) VALUES(?, ?, ?, ?, ?, ?, ?)",
    { vehicle, dealershipId, quantity, totalCost, deliveryTime, orderedBy, sizeCategory }
  )

  DealershipBalance.Server.Remove(dealershipId, totalCost)
  Framework.Server.Notify(source, Locale.dealershipVehiclesOrdered, "success")
  SendWebhook(source, Webhooks.Dealership, "Dealership: Vehicle(s) Ordered", "success", {
    { key = "Dealership", value = getDealershipName(dealershipId) },
    { key = "Vehicle", value = vehicle },
    { key = "Quantity", value = quantity },
    { key = "Total Price", value = totalCost },
  })

  if Config.VehicleOrderTime == 0 then
    fulfillOrder({
      id = orderId,
      quantity = quantity,
      dealership = dealershipId,
      vehicle = vehicle,
    })
  end

  return MySQL.single.await(
    "SELECT orders.*, vehicle.brand, vehicle.model FROM dealership_orders orders INNER JOIN dealership_vehicles vehicle ON orders.vehicle = vehicle.spawn_code WHERE orders.dealership = ? ORDER BY id DESC LIMIT 1",
    { dealershipId }
  )
end)

lib.callback.register("jg-dealerships:server:cancel-vehicle-order", function(source, orderId)
  local order = MySQL.single.await("SELECT * FROM dealership_orders WHERE id = ?", { orderId })
  if not order then
    return { error = true }
  end

  if not Employees.Server.IsEmployee(source, order.dealership, "MANAGE_INVENTORY") then
    return rejectEmployeeAction(source)
  end

  MySQL.query.await("DELETE FROM dealership_orders WHERE id = ?", { orderId })
  DealershipBalance.Server.Add(order.dealership, order.cost)
  Framework.Server.Notify(source, Locale.dealershipOrderCancelled, "success")
  SendWebhook(source, Webhooks.Dealership, "Dealership: Order Cancelled", "danger", {
    { key = "Dealership", value = getDealershipName(order.dealership) },
    { key = "Vehicle", value = order.vehicle },
    { key = "Quantity", value = order.quantity },
    { key = "Amount Refunded", value = order.cost },
  })

  return true
end)

lib.callback.register("jg-dealerships:server:get-delivery-info", function(source, orderId, dealershipId)
  if not Employees.Server.IsEmployee(source, dealershipId, "DELIVER") then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end

  local success, errorMessage, pickupLocation = TruckingMission.Server.PrepareDelivery(source, orderId, dealershipId)
  if not success or not pickupLocation then
    Framework.Server.Notify(source, errorMessage or Locale.failedToPrepareDelivery, "error")
    return false
  end

  return {
    pickupLocation = pickupLocation.name,
    pickupCoords = pickupLocation.coords,
  }
end)

lib.callback.register("jg-dealerships:server:deliver-vehicle", function(source, orderId, dealershipId)
  if not Employees.Server.IsEmployee(source, dealershipId, "DELIVER") then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end

  local order = MySQL.single.await(
    "SELECT * FROM dealership_orders WHERE id = ? AND dealership = ? AND fulfilled = 0",
    { orderId, dealershipId }
  )
  if not order then
    Framework.Server.Notify(source, Locale.orderNotFoundOrFulfilled, "error")
    return false
  end

  local remainingQuantity = order.quantity - (order.delivered or 0)
  local cargoType = order.size_category == "large" and "container" or "car"
  local success, errorMessage, config = TruckingMission.Server.GenerateDeliveryConfiguration(
    source,
    dealershipId,
    cargoType,
    { orderId },
    { [orderId] = remainingQuantity }
  )

  if not success or not config then
    Framework.Server.Notify(source, errorMessage or Locale.failedToPrepareDelivery, "error")
    return false
  end

  if not TruckingMission.Server.StartMultiDelivery(source, dealershipId, config.configHash) then
    return false
  end

  SendWebhook(source, Webhooks.Dealership, "Dealership: Delivery Started", "info", {
    { key = "Dealership", value = getDealershipName(dealershipId) },
    { key = "Order ID", value = orderId },
    { key = "Vehicle", value = order.vehicle },
    { key = "Quantity", value = remainingQuantity },
  })

  return true
end)

lib.callback.register("jg-dealerships:server:generate-delivery-config", function(source, dealershipId, cargoType, orderIds, orderQuantities)
  if not Employees.Server.IsEmployee(source, dealershipId, "DELIVER") then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false, "Permission denied", nil
  end

  return TruckingMission.Server.GenerateDeliveryConfiguration(source, dealershipId, cargoType, orderIds, orderQuantities)
end)

lib.callback.register("jg-dealerships:server:start-multi-delivery", function(source, dealershipId, configHash)
  if not Employees.Server.IsEmployee(source, dealershipId, "DELIVER") then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end

  local started = TruckingMission.Server.StartMultiDelivery(source, dealershipId, configHash)
  if started then
    SendWebhook(source, Webhooks.Dealership, "Dealership: Multi-Order Delivery Started", "info", {
      { key = "Dealership", value = getDealershipName(dealershipId) },
    })
  end

  return started
end)

lib.callback.register("jg-dealerships:server:dealership-deposit", function(source, dealershipId, account, amount)
  if not Employees.Server.IsEmployee(source, dealershipId, "MANAGE_FINANCES") then
    return rejectEmployeeAction(source)
  end

  if amount < 0 then
    Framework.Server.Notify(source, Locale.exploitAttemptDetected, "error")
    return false
  end

  if amount > Framework.Server.GetPlayerBalance(source, account) then
    Framework.Server.Notify(source, Locale.errorNotEnoughMoney, "error")
    return { error = true }
  end

  Framework.Server.PlayerRemoveMoney(source, amount, account)
  local success, errorMessage = DealershipBalance.Server.Add(dealershipId, amount)

  if not success then
    Framework.Server.PlayerAddMoney(source, amount, account)
    Framework.Server.Notify(source, errorMessage or Locale.failedToPrepareDelivery, "error")
    return { error = true }
  end

  Framework.Server.Notify(source, Locale.depositSuccess, "success")
  SendWebhook(source, Webhooks.Dealership, "Dealership: Money Deposited", nil, {
    { key = "Dealership", value = getDealershipName(dealershipId) },
    { key = "Amount", value = amount },
  })

  return true
end)

lib.callback.register("jg-dealerships:server:dealership-withdraw", function(source, dealershipId, amount)
  if not Employees.Server.IsEmployee(source, dealershipId, "MANAGE_FINANCES") then
    return rejectEmployeeAction(source)
  end

  if amount < 0 then
    Framework.Server.Notify(source, Locale.exploitAttemptDetected, "error")
    return false
  end

  local hasFunds, balance = DealershipBalance.Server.HasFunds(dealershipId, amount)
  if balance == nil then
    Framework.Server.Notify(source, Locale.dealershipNoJobConfigured, "error")
    return { error = true }
  end

  if not hasFunds then
    Framework.Server.Notify(source, Locale.dealershipNotEnoughFunds, "error")
    return { error = true }
  end

  Framework.Server.PlayerAddMoney(source, amount, "bank")
  DealershipBalance.Server.Remove(dealershipId, amount)
  Framework.Server.Notify(source, Locale.withdrawSuccess, "success")
  SendWebhook(source, Webhooks.Dealership, "Dealership: Money Withdraw", nil, {
    { key = "Dealership", value = getDealershipName(dealershipId) },
    { key = "Amount", value = amount },
  })

  return true
end)

lib.callback.register("jg-dealerships:server:update-vehicle-price", function(source, data)
  local dealershipId = data.dealership
  local vehicle = data.vehicle
  local newPrice = data.newPrice

  if newPrice < 0 then
    return { error = true }
  end

  if not Employees.Server.IsEmployee(source, dealershipId, "MANAGE_INVENTORY") then
    return rejectEmployeeAction(source)
  end

  local vehicleData = MySQL.single.await(
    "SELECT price_limits_enabled, min_price, max_price FROM dealership_vehicles WHERE spawn_code = ?",
    { vehicle }
  )

  if vehicleData and vehicleData.price_limits_enabled == 1 then
    if vehicleData.min_price and newPrice < vehicleData.min_price then
      Framework.Server.Notify(source, string.gsub(Locale.priceBelowMinimum, "%%{value}", vehicleData.min_price), "error")
      return { error = true }
    end

    if vehicleData.max_price and newPrice > vehicleData.max_price then
      Framework.Server.Notify(source, string.gsub(Locale.priceAboveMaximum, "%%{value}", vehicleData.max_price), "error")
      return { error = true }
    end
  end

  MySQL.update.await("UPDATE dealership_stock SET price = ? WHERE vehicle = ? AND dealership = ?", {
    newPrice,
    vehicle,
    dealershipId,
  })
  Showroom.Server.UpdateVehicleCache(vehicle, dealershipId)
  SendWebhook(source, Webhooks.Dealership, "Dealership: Vehicle Price Updated", nil, {
    { key = "Dealership", value = getDealershipName(dealershipId) },
    { key = "Vehicle", value = vehicle },
    { key = "New Price", value = newPrice },
  })

  return true
end)

lib.callback.register("jg-dealerships:server:admin-set-stock", function(source, data)
  local dealershipId = data.dealership
  local vehicle = data.spawnCode
  local stock = data.stock

  if not Framework.Server.IsAdmin(source) then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return { error = true }
  end

  if type(stock) ~= "number" or stock < 0 then
    return {
      error = true,
      message = "Invalid stock value",
    }
  end

  MySQL.update.await("UPDATE dealership_stock SET stock = ? WHERE vehicle = ? AND dealership = ?", {
    stock,
    vehicle,
    dealershipId,
  })
  Showroom.Server.UpdateVehicleCache(vehicle, dealershipId)
  Framework.Server.Notify(source, Locale.stockUpdated, "success")
  SendWebhook(source, Webhooks.Dealership, "Admin: Stock Quantity Set", nil, {
    { key = "Dealership", value = getDealershipName(dealershipId) },
    { key = "Vehicle", value = vehicle },
    { key = "New Stock", value = stock },
  })

  return { success = true }
end)

lib.callback.register("jg-dealerships:server:update-dealership-settings", function(source, data)
  local dealershipId = data.dealership
  if not Employees.Server.IsEmployee(source, dealershipId, "MANAGE_FINANCES") then
    return rejectEmployeeAction(source)
  end

  MySQL.update.await("UPDATE dealership_locations SET name = ?, employee_commission = ? WHERE id = ?", {
    data.name,
    data.commission,
    dealershipId,
  })
  Locations.Server.RefreshLocation(dealershipId)
  Framework.Server.Notify(source, Locale.changesSaved, "success")
  SendWebhook(source, Webhooks.Dealership, "Dealership: Settings Updated", nil, {
    { key = "Dealership", value = getDealershipName(dealershipId) },
    { key = "New name", value = data.name },
  })

  return true
end)

if not Config.TruckingMissionForOrderDeliveries then
  lib.cron.new("* * * * *", function()
    local orders = MySQL.query.await("SELECT * FROM dealership_orders WHERE delivery_time < UNIX_TIMESTAMP() AND fulfilled = 0")
    for _, order in ipairs(orders) do
      fulfillOrder(order)
      Wait(250)
    end
  end)
end
