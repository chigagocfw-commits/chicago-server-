DealershipManagement = DealershipManagement or {}
DealershipManagement.Client = DealershipManagement.Client or {}

function DealershipManagement.Client.Open(dealershipId, defaultPage, fromAdmin)
  local dealership = Locations.Client.GetLocationById(dealershipId)
  if not dealership then return false end

  local employeeData = lib.callback.await(
    "jg-dealerships:server:is-employee",
    false,
    dealershipId,
    fromAdmin == true
  )

  if not employeeData or not employeeData.isEmployee then
    Framework.Client.Notify(Locale.notAnEmployee, "error")
    return false
  end

  local balance = lib.callback.await("jg-dealerships:server:dealership-balance:get", false, dealershipId)

  SetNuiFocus(true, true)
  SendNUIMessage({
    type = "showDealershipManagement",
    defaultPage = defaultPage,
    shopType = dealership.type,
    dealershipId = dealershipId,
    name = dealership.name or dealershipId,
    balance = balance or 0,
    employeeName = employeeData.employeeName,
    employeeRole = employeeData.employeeRole,
    permissions = employeeData.permissions,
    commission = dealership.employee_commission or 10,
    fromAdmin = fromAdmin or false,
    nearbyPlayers = {},
    playerBalance = {
      bank = Framework.Client.GetBalance("bank"),
      cash = Framework.Client.GetBalance("cash"),
    },
    roles = { "CEO", "Owner", "Employee" },
    colourSelectionType = dealership.colour_selection_type or "RGB",
    colourOptions = dealership.colour_options or {},
    locale = Locale,
    config = Config,
  })
end

local function getDeliveryInfo(orderId, dealershipId)
  local deliveryInfo = lib.callback.await("jg-dealerships:server:get-delivery-info", false, orderId, dealershipId)
  if not deliveryInfo or not deliveryInfo.pickupCoords then return false end

  local playerCoords = GetEntityCoords(cache.ped)
  local pickupCoords = deliveryInfo.pickupCoords
  local travelDistance = CalculateTravelDistanceBetweenPoints(
    playerCoords.x, playerCoords.y, playerCoords.z,
    pickupCoords.x, pickupCoords.y, pickupCoords.z
  )

  local directDistance = #(playerCoords - vector3(pickupCoords.x, pickupCoords.y, pickupCoords.z))
  local routeFactor = travelDistance / math.max(directDistance, 1)
  local speed = 22.22 - (math.min(routeFactor - 1.0, 1.0) * 13.89)
  local estimatedTime = math.ceil((travelDistance / speed) * 1.3)

  return {
    pickupLocation = deliveryInfo.pickupLocation,
    distance = travelDistance,
    estimatedTime = estimatedTime,
  }
end

RegisterNUICallback("management-return-to-admin", function(_, callback)
  Admin.Client.Open()
  callback(true)
end)

RegisterNUICallback("get-dealership-balance", function(data, callback)
  callback(lib.callback.await("jg-dealerships:server:get-dealership-balance", false, data.dealership))
end)

local passthroughCallbacks = {
  ["get-dealership-vehicles"] = "jg-dealerships:server:get-dealership-vehicles",
  ["get-dealership-display-vehicles"] = "jg-dealerships:server:get-dealership-display-vehicles",
  ["get-dealership-orders"] = "jg-dealerships:server:get-dealership-orders",
  ["get-dealership-sales"] = "jg-dealerships:server:get-dealership-sales",
  ["get-dealership-employees"] = "jg-dealerships:server:get-dealership-employees",
  ["get-dealership-homepage-stats"] = "jg-dealerships:server:get-dealership-homepage-stats",
  ["get-dealership-graph-data"] = "jg-dealerships:server:get-dealership-graph-data",
  ["update-vehicle-price"] = "jg-dealerships:server:update-vehicle-price",
  ["admin-set-stock"] = "jg-dealerships:server:admin-set-stock",
  ["update-dealership-settings"] = "jg-dealerships:server:update-dealership-settings",
}

for nuiCallback, serverCallback in pairs(passthroughCallbacks) do
  RegisterNUICallback(nuiCallback, function(data, callback)
    callback(lib.callback.await(serverCallback, false, data))
  end)
end

RegisterNUICallback("order-vehicle", function(data, callback)
  local sizeCategory = TrailerAttachment
    and TrailerAttachment.Client
    and TrailerAttachment.Client.GetVehicleSizeCategory
    and TrailerAttachment.Client.GetVehicleSizeCategory(data.spawnCode)

  callback(lib.callback.await(
    "jg-dealerships:server:order-vehicle",
    false,
    data.dealership,
    data.spawnCode,
    data.quantity,
    sizeCategory
  ))
end)

RegisterNUICallback("cancel-vehicle-order", function(data, callback)
  callback(lib.callback.await("jg-dealerships:server:cancel-vehicle-order", false, data.orderId))
end)

RegisterNUICallback("get-delivery-info", function(data, callback)
  callback(getDeliveryInfo(data.orderId, data.dealershipId))
end)

RegisterNUICallback("deliver-vehicle", function(data, callback)
  callback(lib.callback.await(
    "jg-dealerships:server:deliver-vehicle",
    false,
    data.orderId,
    data.dealershipId
  ))
end)

RegisterNUICallback("generate-delivery-config", function(data, callback)
  local success, errorMsg, config = lib.callback.await(
    "jg-dealerships:server:generate-delivery-config",
    false,
    data.dealershipId,
    data.trailerType,
    data.orderIds,
    data.quantities
  )

  callback({
    success = success,
    errorMsg = errorMsg,
    config = config,
  })
end)

RegisterNUICallback("start-multi-delivery", function(data, callback)
  callback(lib.callback.await(
    "jg-dealerships:server:start-multi-delivery",
    false,
    data.dealershipId,
    data.configHash
  ))
end)

RegisterNUICallback("update-dealership-balance", function(data, callback)
  if data.action == "deposit" then
    return callback(lib.callback.await(
      "jg-dealerships:server:dealership-deposit",
      false,
      data.dealership,
      data.source,
      data.amount
    ))
  end

  if data.action == "withdraw" then
    return callback(lib.callback.await(
      "jg-dealerships:server:dealership-withdraw",
      false,
      data.dealership,
      data.amount
    ))
  end

  callback({ error = true })
end)
